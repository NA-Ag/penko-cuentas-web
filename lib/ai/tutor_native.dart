// tutor.dart — Penko's on-device tutor model (Gemma 4 E2B for now; our distilled version later, same file names).
// It explains ("¿por qué?") and reads pictures (receipts). It never decides what's right: every reply goes through
// check.dart, and when a reply doesn't pass, Penko says her own written line instead. It runs only on phones with
// enough memory (~6 GB); on others the lessons work exactly the same, without the "¿Por qué?" button.
import 'dart:async';
import 'dart:io';

import '../i18n/tr.dart';
import 'llm_engine.dart';
import 'check.dart';
import 'prompt.dart';

class Tutor {
  Tutor._();
  static final instance = Tutor._();

  static const fileName = 'gemma4-e2b.gguf'; // a whole model copied into the app's folder (test builds)
  static const mediaFileName = 'gemma4-e2b-media.gguf'; // its media part (pictures)
  static const minMemory = 5.3e9; // phones sold as "6 GB" report a little less

  final _engine = LlmEngine();
  String? _model;
  String? _media;
  bool? _available;
  bool _mediaLoaded = false;
  Timer? _idle;
  Future<void>? _loading;

  /// The last raw reply and how long it took (for measuring on phones; never shown unchecked)
  String? lastRaw;
  Duration? lastTime;
  Duration? loadTime;

  /// How the tutor stands on this phone, in words for Ajustes
  Future<String> status() async {
    try {
      final memory = await LlmEngine.totalMemory();
      if (memory < minMemory) {
        return tr(
            'Este teléfono tiene ${(memory / 1e9).toStringAsFixed(1)} GB de memoria y Penko necesita unos 6 GB para '
                'pensar sus respuestas. Las lecciones y los simuladores funcionan igual.',
            'This phone has ${(memory / 1e9).toStringAsFixed(1)} GB of memory and Penko needs about 6 GB to think through '
                'her answers. The lessons and simulators work just the same.');
      }
      if (await available()) return tr('Listo en este teléfono, sin internet (unos 3.4 GB).', 'Ready on this phone, with no internet (about 3.4 GB).');
      final packs = await LlmEngine.aiPacks();
      final done = int.tryParse(packs['downloaded'] ?? '') ?? 0, total = int.tryParse(packs['total'] ?? '') ?? 0;
      return switch (packs['state']) {
        'downloading' => tr('Llegando: ${total > 0 ? (done * 100 ~/ total) : 0}% de unos 3.4 GB.',
            'Arriving: ${total > 0 ? (done * 100 ~/ total) : 0}% of about 3.4 GB.'),
        'waitingForWifi' => tr('Esperando Wi-Fi para bajar unos 3.4 GB (para no gastar tus datos).',
            'Waiting for Wi-Fi to download about 3.4 GB (so it doesn\'t use your data).'),
        'failed' => tr('No se pudo bajar. Revisa tu conexión e inténtalo otra vez desde Google Play.',
            "Couldn't download it. Check your connection and try again from Google Play."),
        'notForThisPhone' => tr(
            'Este teléfono no tiene memoria suficiente, así que no se descargó (para no gastar tus datos '
                'ni espacio). Las lecciones y los simuladores funcionan igual.',
            "This phone doesn't have enough memory, so it wasn't downloaded (to save your data and space). The lessons "
                'and simulators work just the same.'),
        _ => tr('No está instalado en esta copia de la app.', "It isn't installed in this copy of the app."),
      };
    } catch (_) {
      return tr('No disponible en este dispositivo.', 'Not available on this device.');
    }
  }

  /// Whether this phone can use the tutor (enough memory, and the model has arrived)
  Future<bool> available() async {
    if (_available == true) return true;
    try {
      if (await LlmEngine.totalMemory() < minMemory) return _available = false;
      final packs = await LlmEngine.aiPacks();
      if (packs['state'] == 'ready') {
        _model = packs['model'];
        _media = packs['media'];
      } else {
        final dir = await LlmEngine.modelDir();
        if (File('$dir/$fileName').existsSync()) {
          _model = '$dir/$fileName';
          if (File('$dir/$mediaFileName').existsSync()) _media = '$dir/$mediaFileName';
        }
      }
      return _available = _model != null;
    } catch (_) {
      return _available = false; // not on a phone (tests on the computer), or the native side isn't there
    }
  }

  Future<void> _ready() async {
    _idle?.cancel();
    if (!_engine.isLoaded) {
      // Two threads keep it on the phone's fast cores (more threads add slow ones and get slower); reading the
      // prompt in batches can use all of them
      _loading ??= _engine.load(_model!, nCtx: 2048, threads: 2, threadsBatch: 8).then((t) => loadTime = t);
      await _loading;
      _loading = null;
    }
  }

  /// Loads the model and runs it once, quietly, when a lesson opens: the first real answer is much slower otherwise
  Future<void> warmUp() async {
    if (!await available() || _engine.isLoaded || _loading != null) return;
    try {
      await _ready();
      await _engine.generate(GenRequest(gemmaPrompt(penkoSystem, 'Hola'), maxTokens: 1, stops: const ['<turn|>']));
      _later();
    } catch (_) {}
  }

  /// Frees the ~3 GB the model uses once nobody has asked anything for a while
  void _later() {
    _idle?.cancel();
    _idle = Timer(const Duration(minutes: 2), () async {
      await _engine.unload();
      _mediaLoaded = false;
    });
  }

  /// Penko explains, using only the engine's [facts]. Null when the tutor isn't there or its reply didn't pass the
  /// engine's checks (the caller then shows Penko's written line). [forbidden]: numbers it mustn't say (an answer the
  /// student should find).
  Future<String?> explain({required String facts, required String question, Set<double> forbidden = const {}}) async {
    if (!await available()) return null;
    try {
      await _ready();
      final r = await _engine.generate(GenRequest(
        gemmaPrompt(Tr.english ? '${systemWithFacts(facts)}\n\n$englishReply' : systemWithFacts(facts), question),
        maxTokens: 120,
        temperature: 0.3,
        stops: const ['<turn|>'],
      ));
      _later();
      lastRaw = r.text;
      lastTime = r.time;
      if (r.error != null) return null;
      return checked(r.text, facts: facts, question: question, forbidden: forbidden);
    } catch (_) {
      return null;
    }
  }

  /// What a picture shows, answering [instruction]: the raw text, for the caller to check (e.g. a receipt's lines
  /// must add up to its total). Null when the tutor or its media part isn't there.
  Future<String?> look(String imagePath, String instruction) async {
    if (!await available() || _media == null) return null;
    try {
      await _ready();
      if (!_mediaLoaded) {
        final r = await _engine.loadAudio(_media!);
        if (r.error != null) return null;
        _mediaLoaded = true;
      }
      final r = await _engine.look(imagePath, instruction);
      _later();
      lastRaw = r.text;
      lastTime = r.time;
      return r.error == null ? r.text : null;
    } catch (_) {
      return null;
    }
  }

  /// Stops a reply being written (the student left the screen)
  void cancel() {
    if (_engine.isLoaded) _engine.cancel();
  }
}
