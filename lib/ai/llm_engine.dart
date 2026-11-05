// llm_engine.dart — the on-device model, running on its own isolate so the UI never waits on it.
// Talks to native/penko_llm.c (libpenko_llm.so), which wraps llama.cpp.
import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:isolate';

import 'package:ffi/ffi.dart';
import 'package:flutter/services.dart';

/// Gemma's user turn: everything before the last one is the shared system block
const userTurnMarker = '<|turn>user';

typedef _InitC = Void Function(Pointer<Utf8>);
typedef _InitDart = void Function(Pointer<Utf8>);
typedef _LoadC = Pointer<Void> Function(Pointer<Utf8>, Int32, Int32, Int32);
typedef _LoadDart = Pointer<Void> Function(Pointer<Utf8>, int, int, int);
typedef _GenC = Int32 Function(
  Pointer<Void>,
  Pointer<Utf8>,
  Pointer<Utf8>,
  Int32,
  Float,
  Float,
  Uint32,
  Pointer<Utf8>,
  Pointer<Utf8>,
  Int32,
);
typedef _GenDart = int Function(
  Pointer<Void>,
  Pointer<Utf8>,
  Pointer<Utf8>,
  int,
  double,
  double,
  int,
  Pointer<Utf8>,
  Pointer<Utf8>,
  int,
);
typedef _AudioC = Int32 Function(Pointer<Void>, Pointer<Utf8>, Int32);
typedef _AudioDart = int Function(Pointer<Void>, Pointer<Utf8>, int);
typedef _TranscribeC = Int32 Function(Pointer<Void>, Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>, Int32);
typedef _TranscribeDart = int Function(Pointer<Void>, Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>, int);
typedef _LookC = Int32 Function(Pointer<Void>, Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>, Int32, Int32);
typedef _LookDart = int Function(Pointer<Void>, Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>, int, int);
typedef _HandleC = Void Function(Pointer<Void>);
typedef _HandleDart = void Function(Pointer<Void>);

/// One generation request (sent to the model isolate)
class GenRequest {
  final String prompt;
  final int maxTokens;
  final double temperature;
  final double topP;
  final int seed;
  final List<String> stops;
  const GenRequest(
    this.prompt, {
    this.maxTokens = 60,
    this.temperature = 0.7,
    this.topP = 0.9,
    this.seed = 1,
    this.stops = const ['<turn|>', '\n'],
  });
}

class GenResult {
  final String text;
  final Duration time;
  final String? error;
  const GenResult(this.text, this.time, {this.error});
}

class LlmEngine {
  static const _channel = MethodChannel('penko/native');

  SendPort? _toModel;
  int _handleAddress = 0;
  final _pending = <int, Completer<GenResult>>{};
  int _nextId = 0;

  bool get isLoaded => _toModel != null;

  /// The phone's total memory in bytes (0 if unknown)
  static Future<int> totalMemory() async =>
      int.tryParse(((await _channel.invokeMapMethod<String, String>('paths'))!)['totalMemory'] ?? '') ?? 0;

  /// Google Play's delivery of the helper (see MainActivity.kt): state none / notInstalled / downloading /
  /// waitingForWifi / failed / ready, with downloaded / total bytes, or the model and audio paths when ready
  static Future<Map<String, String>> aiPacks() async =>
      (await _channel.invokeMapMethod<String, String>('aiPacks')) ?? const {'state': 'none'};

  /// Asks Google Play to (re)start delivering the helper
  static Future<bool> fetchAiPacks() async => (await _channel.invokeMethod<bool>('fetchAiPacks')) ?? false;

  /// Folder the model file lives in (the app's own storage)
  static Future<String> modelDir() async => ((await _channel.invokeMapMethod<String, String>('paths'))!)['modelDir']!;

  /// Loads the model on a background isolate. Returns how long loading took.
  Future<Duration> load(String modelPath, {int nCtx = 1536, int threads = 2, int threadsBatch = 8}) async {
    final paths = (await _channel.invokeMapMethod<String, String>('paths'))!;
    final fromModel = ReceivePort();
    final started = DateTime.now();
    await Isolate.spawn(_modelMain, [
      fromModel.sendPort,
      paths['nativeLibDir'],
      modelPath,
      nCtx,
      threads,
      threadsBatch,
    ]);
    final ready = Completer<void>();
    fromModel.listen((msg) {
      final m = msg as List;
      switch (m[0]) {
        case 'ready':
          _toModel = m[1] as SendPort;
          _handleAddress = m[2] as int;
          ready.complete();
        case 'failed':
          ready.completeError(StateError(m[1] as String));
        case 'result':
          _pending
              .remove(m[1])
              ?.complete(GenResult(m[2] as String, Duration(milliseconds: m[3] as int), error: m[4] as String?));
      }
    });
    await ready.future;
    return DateTime.now().difference(started);
  }

  Future<GenResult> generate(GenRequest r) {
    final id = _nextId++;
    final c = Completer<GenResult>();
    _pending[id] = c;
    _toModel!.send(['gen', id, r.prompt, r.maxTokens, r.temperature, r.topP, r.seed, r.stops.join('\x1f')]);
    return c.future;
  }

  /// Frees the model and its memory (~3 GB). Load again to use it.
  Future<void> unload() async {
    final to = _toModel;
    if (to == null) return;
    final id = _nextId++;
    final c = Completer<GenResult>();
    _pending[id] = c;
    to.send(['free', id]);
    await c.future;
    _toModel = null;
    _handleAddress = 0;
  }

  /// Loads the model's audio part (speech recognition) on top of the loaded model. The result's error is set if it
  /// couldn't.
  Future<GenResult> loadAudio(String mmprojPath, {int threads = 8}) {
    final id = _nextId++;
    final c = Completer<GenResult>();
    _pending[id] = c;
    _toModel!.send(['audio', id, mmprojPath, threads]);
    return c.future;
  }

  /// What was said in a recording (a WAV file), as text
  Future<GenResult> transcribe(String wavPath, String instruction) {
    final id = _nextId++;
    final c = Completer<GenResult>();
    _pending[id] = c;
    _toModel!.send(['transcribe', id, wavPath, instruction]);
    return c.future;
  }

  /// What a picture shows (e.g. a receipt read line by line), answering [instruction] about it. Needs the media
  /// part loaded (loadAudio: the same file holds pictures and sound).
  Future<GenResult> look(String imagePath, String instruction, {int maxTokens = 400}) {
    final id = _nextId++;
    final c = Completer<GenResult>();
    _pending[id] = c;
    _toModel!.send(['look', id, imagePath, instruction, maxTokens]);
    return c.future;
  }

  /// Stops the reply being written right now (e.g. the learner left the screen)
  void cancel() {
    if (_handleAddress == 0) return;
    DynamicLibrary.open('libpenko_llm.so')
        .lookupFunction<_HandleC, _HandleDart>('pk_cancel')(Pointer.fromAddress(_handleAddress));
  }
}

/// Runs on the model isolate: loads the model once, then answers requests one at a time.
void _modelMain(List args) {
  final toMain = args[0] as SendPort;
  final lib = DynamicLibrary.open('libpenko_llm.so');
  final init = lib.lookupFunction<_InitC, _InitDart>('pk_init');
  final load = lib.lookupFunction<_LoadC, _LoadDart>('pk_load');
  final gen = lib.lookupFunction<_GenC, _GenDart>('pk_generate');
  final loadAudio = lib.lookupFunction<_AudioC, _AudioDart>('pk_load_audio');
  final transcribe = lib.lookupFunction<_TranscribeC, _TranscribeDart>('pk_transcribe');
  final look = lib.lookupFunction<_LookC, _LookDart>('pk_look');
  final free = lib.lookupFunction<_HandleC, _HandleDart>('pk_free');

  final libDir = (args[1] as String).toNativeUtf8();
  init(libDir);
  final modelPath = (args[2] as String).toNativeUtf8();
  final handle = load(modelPath, args[3] as int, args[4] as int, args[5] as int);
  if (handle == nullptr) {
    toMain.send(['failed', 'Could not load the model at ${args[2]}']);
    return;
  }

  const outCap = 4096;
  final out = calloc<Uint8>(outCap).cast<Utf8>();
  final inbox = ReceivePort();
  toMain.send(['ready', inbox.sendPort, handle.address]);
  inbox.listen((msg) {
    final m = msg as List;
    final t0 = DateTime.now();
    int ms() => DateTime.now().difference(t0).inMilliseconds;
    switch (m[0]) {
      case 'free':
        free(handle);
        calloc.free(out);
        inbox.close();
        toMain.send(['result', m[1], '', ms(), null]);
        Isolate.exit();
      case 'audio':
        final path = (m[2] as String).toNativeUtf8();
        final r = loadAudio(handle, path, m[3] as int);
        calloc.free(path);
        toMain.send(['result', m[1], '', ms(), r == 0 ? null : 'audio part not loaded ($r)']);
      case 'transcribe':
        final wav = (m[2] as String).toNativeUtf8();
        final instruction = (m[3] as String).toNativeUtf8();
        final n = transcribe(handle, wav, instruction, out, outCap);
        final text = n > 0 ? utf8.decode(out.cast<Uint8>().asTypedList(n), allowMalformed: true) : '';
        toMain.send(['result', m[1], text, ms(), n < 0 ? 'transcribe error $n' : null]);
        calloc.free(wav);
        calloc.free(instruction);
      case 'look':
        final image = (m[2] as String).toNativeUtf8();
        final instruction = (m[3] as String).toNativeUtf8();
        final n = look(handle, image, instruction, out, outCap, m[4] as int);
        final text = n > 0 ? utf8.decode(out.cast<Uint8>().asTypedList(n), allowMalformed: true) : '';
        toMain.send(['result', m[1], text, ms(), n < 0 ? 'look error $n' : null]);
        calloc.free(image);
        calloc.free(instruction);
      default: // 'gen'
        // Everything before the last user turn is the shared system block: the native side keeps a snapshot of it
        final full = m[2] as String;
        final split = full.lastIndexOf(userTurnMarker);
        final prefix = (split > 0 ? full.substring(0, split) : '').toNativeUtf8();
        final prompt = (split > 0 ? full.substring(split) : full).toNativeUtf8();
        final stops = (m[7] as String).toNativeUtf8();
        final n = gen(
          handle,
          prefix,
          prompt,
          m[3] as int,
          m[4] as double,
          m[5] as double,
          m[6] as int,
          stops,
          out,
          outCap,
        );
        // The reply is UTF-8 bytes; a token can end mid-character, so decode leniently
        final text = n > 0 ? utf8.decode(out.cast<Uint8>().asTypedList(n), allowMalformed: true) : '';
        toMain.send(['result', m[1], text, ms(), n < 0 ? 'native error $n' : null]);
        calloc.free(prefix);
        calloc.free(prompt);
        calloc.free(stops);
    }
  });
}
