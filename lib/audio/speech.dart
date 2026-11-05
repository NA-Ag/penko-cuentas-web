// speech.dart — Penko reads lines aloud with the phone's own text-to-speech (no download, works offline when the
// phone has an offline voice). In Spanish it prefers Mexican and Latin American voices; in English, US then British
// English. Offline voices over network ones. When the app's language changes, the voice is picked again.
import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_tts/flutter_tts.dart';

import '../i18n/lang.dart';
import 'voice_pack.dart';
import 'voice_player.dart';

class Speech {
  Speech._() {
    // A new language: pick a voice that speaks it, the next time a line is said
    Lang.current.addListener(() {
      _ready = false;
      _main = null;
      _current = null;
      voiceName = null;
      language = null;
      offline = false;
    });
  }
  static final instance = Speech._();

  final _tts = FlutterTts();
  bool _ready = false;
  String? voiceName;
  String? language;
  bool offline = false;
  Map<String, String>? _main; // the voice picked above
  String? _current; // the voice set on the engine now
  List<Map<String, String>> _variety = []; // offline voices of the language, for hearing many speakers

  /// Language tags to try, best first
  static List<String> get _preferred =>
      Lang.en ? const ['en-US', 'en-GB', 'en'] : const ['es-MX', 'es-US', 'es-419', 'es-ES', 'es'];
  static String get _course => Lang.en ? 'en' : 'es';

  /// The phone's voices that can speak now: a voice listed as "not installed" (its data not downloaded yet) is silent
  Future<List<Map<String, String>>> voices() async {
    final raw = await _tts.getVoices as List? ?? const [];
    return [
      for (final v in raw)
        if (!'${(v as Map)['features']}'.contains('notInstalled')) v.map((k, val) => MapEntry('$k', '$val')),
    ];
  }

  bool _waited = false; // the browser has had its chance to list its voices

  /// [voices], but a browser lists its voices a moment after the page opens, so give it that moment once
  Future<List<Map<String, String>>> _voicesSoon() async {
    var all = await voices();
    if (kIsWeb && !_waited) {
      for (var i = 0; i < 20 && all.isEmpty; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        all = await voices();
      }
      _waited = true;
    }
    return all;
  }

  /// False when this phone or browser has no voice for the app's language, so Penko can't be heard
  Future<bool> hasVoice() async => await VoicePack.present() || (await _voicesSoon()).any((v) => (v['locale'] ?? '').toLowerCase().startsWith(_course));

  Future<void> _init() async {
    if (_ready) return;
    _ready = true;
    await _tts.awaitSpeakCompletion(true);
    final all = await _voicesSoon();
    if (kIsWeb && all.isEmpty) _ready = false; // try again next line: some browsers list their voices late
    Map<String, String>? pick;
    for (final tag in _preferred) {
      final matching = all.where(
        (v) => (v['locale'] ?? '').replaceAll('_', '-').toLowerCase().startsWith(tag.toLowerCase()),
      );
      // Offline first: some engines only have some languages as a network voice
      pick = matching.where((v) => v['network_required'] != 'true' && v['network_required'] != '1').firstOrNull ?? pick;
      if (pick != null && pick['network_required'] != 'true') break;
      pick ??= matching.firstOrNull;
    }
    bool isOffline(Map<String, String> v) => v['network_required'] != 'true' && v['network_required'] != '1';
    String tag(Map<String, String> v) => (v['locale'] ?? '').replaceAll('_', '-').toLowerCase();
    // Many voices: for Spanish, Latin American ones when there are at least two (Mexican pronunciation), else any of
    // the language
    final ofCourse = all.where((v) => tag(v).startsWith(_course) && isOffline(v)).toList();
    final latin = ofCourse.where((v) => !tag(v).startsWith('es-es')).toList();
    _variety = _course == 'es' && latin.length >= 2 ? latin : ofCourse;
    if (pick != null) {
      await _tts.setVoice({'name': pick['name']!, 'locale': pick['locale']!});
      _main = pick;
      _current = pick['name'];
      voiceName = pick['name'];
      language = pick['locale'];
      offline = pick['network_required'] != 'true' && pick['network_required'] != '1';
    } else {
      final fallback = Lang.en ? 'en-US' : 'es-MX';
      await _tts.setLanguage(fallback);
      language = fallback;
    }
  }

  /// How many voices [say] rotates through with `voice:`
  Future<int> varietyCount() async {
    await _init();
    return _variety.length;
  }

  /// Speaks [text]; [slow] for the "listen again, slowly" button. [voice] picks one of the other voices of the language
  /// (any number: it wraps around), so the ear learns the word from many speakers. [key]: the line's voice-pack key
  /// (voice_keys.dart), if it has one; fixed lines are also found by their text.
  Future<void> say(String text, {bool slow = false, int? voice, String? key}) {
    _run++;
    return spoken = _speak(text, slow: slow, voice: voice, key: key);
  }

  /// Finishes when the latest line has been said (the app's demo waits on it)
  Future<void> spoken = Future.value();

  Future<void> _speak(String text, {bool slow = false, int? voice, String? key}) async {
    // A person's recording, when the voice pack has one: at normal speed, in Penko's own voice
    if (voice == null && VoicePlayer.supported) {
      final run = _run;
      final asset = await VoicePack.find(key, line: text);
      final clips = asset != null ? [asset] : await VoicePack.stitched(text);
      if (run != _run) return; // something newer was said meanwhile
      if (clips != null && await _play(clips, slow ? 0.7 : 1)) return;
      if (run != _run) return; // cut off by a newer line: it mustn't come back in another voice
    }
    return _start(text, () async {
      await _init();
      await _use(voice != null && _variety.isNotEmpty ? _variety[voice % _variety.length] : _main);
      // The same speed on both: a browser's normal is 1.0, the phone's is 0.5
      await _tts.setSpeechRate(kIsWeb ? (slow ? 0.6 : 0.9) : (slow ? 0.3 : 0.45));
    });
  }

  /// Plays recordings, cutting off whatever was being said. False if they couldn't be played.
  Future<bool> _play(List<String> assets, double rate) async {
    _cutOff();
    final ticket = _ticket, cut = _cut.future;
    await _tts.stop();
    if (ticket != _ticket) return true; // a newer line took over
    return VoicePlayer.playAll(assets, until: cut, rate: rate);
  }

  Future<void> _use(Map<String, String>? v) async {
    if (v == null || v['name'] == _current) return;
    await _tts.setVoice({'name': v['name']!, 'locale': v['locale']!});
    _current = v['name'];
  }

  int _ticket = 0; // bumped by every new line and by stop: a line waiting its turn is dropped when a newer one comes
  Future<void> _turn = Future.value();
  var _cut = Completer<void>(); // completed when the line being said is cut off (the engine never reports that)

  void _cutOff() {
    _ticket++;
    if (!_cut.isCompleted) _cut.complete();
    _cut = Completer<void>();
  }

  /// Starting a line (stop, voice, speed, speak) takes several calls to the engine. Two lines starting at once
  /// would interleave, and the engine drops a line asked for while it thinks it's still speaking — so lines start
  /// one at a time and the newest wins. Returns when the line has been said (or cut off).
  Future<void> _start(String text, Future<void> Function() setUp) async {
    _cutOff();
    final ticket = _ticket;
    final cut = _cut.future;
    final before = _turn;
    final mine = Completer<void>();
    _turn = mine.future;
    Future<dynamic>? saying;
    try {
      await before;
      if (ticket != _ticket) return;
      await _tts.stop();
      await setUp();
      if (ticket == _ticket) saying = _tts.speak(text);
    } finally {
      mine.complete();
    }
    if (saying != null) await Future.any([saying, cut]);
  }

  int _run = 0; // bumped by every new say / stop, so a scene being played stops when something else speaks

  /// Plays a scene line by line. [voices]: one per line (null = the main voice). [onLine] is called as each line
  /// starts (to show it). Stops if anything else speaks; true if every line was said.
  /// [keys]: each line's voice-pack key (or null).
  Future<bool> sayAll(List<String> lines, {bool slow = false, List<int?>? voices, List<String?>? keys, void Function(int)? onLine}) async {
    final run = ++_run;
    for (var i = 0; i < lines.length; i++) {
      if (run != _run) return false;
      onLine?.call(i);
      await (spoken = _speak(lines[i], slow: slow, voice: voices?[i], key: keys?[i]));
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
    return run == _run;
  }

  Future<void> stop() {
    _run++;
    _cutOff();
    VoicePlayer.stop();
    return _tts.stop();
  }
}
