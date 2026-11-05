// voice_pack.dart — recorded voices, ready for when people record them (none yet). A voice pack is a folder of short
// audio files, one per line, named by the line's key (voice_keys.dart): assets/voice/<language>/<key>.mp3 (or .ogg,
// .m4a, .wav, .opus). An optional assets/voice/<language>/manifest.json can map keys to other file names:
// {"term.iva.word": "iva_palabra.mp3"}. When a line has a recording, Penko plays it instead of her synthetic voice;
// otherwise text-to-speech, as always. Full guide for translators and recordists: docs/VOICE_PACKS.md.
import 'dart:convert';

import 'package:flutter/services.dart';

import '../i18n/lang.dart';
import '../math/explain.dart' show spoken;
import 'stitch.dart';
import 'voice_keys.dart';
import 'voice_player.dart';

class VoicePack {
  VoicePack._();

  static const _formats = ['mp3', 'ogg', 'm4a', 'wav', 'opus'];

  /// The pack's language: the app's language for now (a future voice-only language, like nah, would set it here)
  static String get language => Lang.current.value;

  static final _files = <String, Map<String, String>>{}; // language → key → asset path
  static final _keysByLine = <String, Map<String, String>>{}; // language → line (as written and as spoken) → key

  /// The recording for [key] (or, with no key, for the fixed line [line]) in the current language, or null
  static Future<String?> find(String? key, {String? line}) async {
    if (!VoicePlayer.supported) return null;
    final files = await _load(language);
    if (files.isEmpty) return null;
    key ??= line == null ? null : keyForLine(line);
    return key == null ? null : files[key];
  }

  /// The clips of a line built from pieces (stitch.dart), or null if one is missing
  static Future<List<String>?> stitched(String line) async {
    if (!VoicePlayer.supported) return null;
    final files = await _load(language);
    if (files.isEmpty) return null;
    final clips = clipsOf(line, language == 'es');
    if (clips == null || clips.isEmpty) return null;
    final out = <String>[];
    for (final c in clips) {
      final file = files[c.id];
      if (file == null) return null;
      out.add(file);
    }
    return out;
  }

  /// True when this language has a voice of its own, whatever the device has
  static Future<bool> present() async => VoicePlayer.supported && (await _load(language)).isNotEmpty;

  /// The key of a fixed line, from its text (as written or as spoken()), in the current language
  static String? keyForLine(String line) {
    final byLine = _keysByLine[language] ??= {
      for (final e in voiceLines().entries) ...{e.value: e.key, spoken(e.value): e.key},
    };
    return byLine[line];
  }

  static Future<Map<String, String>> _load(String lang) async {
    if (_files[lang] != null) return _files[lang]!;
    final found = <String, String>{};
    try {
      final folder = 'assets/voice/$lang/';
      final assets = (await AssetManifest.loadFromAssetBundle(rootBundle)).listAssets().where((a) => a.startsWith(folder));
      for (final a in assets) {
        final name = a.substring(folder.length);
        final dot = name.lastIndexOf('.');
        if (dot > 0 && _formats.contains(name.substring(dot + 1).toLowerCase())) found[name.substring(0, dot)] = a;
      }
      if (assets.contains('${folder}manifest.json')) {
        final map = jsonDecode(await rootBundle.loadString('${folder}manifest.json')) as Map<String, dynamic>;
        for (final e in map.entries) {
          found[e.key] = '$folder${e.value}';
        }
      }
    } catch (_) {
      // No pack, or an unreadable manifest: Penko keeps her usual voice
    }
    return _files[lang] = found;
  }
}
