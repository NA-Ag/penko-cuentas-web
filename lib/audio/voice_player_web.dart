// voice_player_web.dart — the web version: a recorded line is played by the browser's own <audio> element, so the
// voice packs need no extra package.
import 'dart:async';
import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:web/web.dart' as web;

class VoicePlayer {
  static const bool supported = true;
  static web.HTMLAudioElement? _audio;

  /// Plays [assets] one after another until they end or [until] completes, at [rate] (the pitch stays). False if one
  /// couldn't be played (Penko then uses her TTS voice). All are loaded before the first starts, so the clips of a
  /// stitched line follow each other without waiting.
  static Future<bool> playAll(List<String> assets, {required Future<void> until, double rate = 1}) async {
    stop();
    final clips = [
      for (final asset in assets)
        web.HTMLAudioElement()
          ..preload = 'auto'
          ..src = ui_web.assetManager.getAssetUrl(asset),
    ];
    try {
      return await _playClips(clips, until, rate);
    } finally {
      // A page can only hold about 75 of these: each one is emptied as soon as it's done, or after that many clips
      // the rest fail (and Penko would slip back into the browser's voice)
      for (final audio in clips) {
        audio
          ..pause()
          ..removeAttribute('src')
          ..load();
      }
    }
  }

  static Future<bool> _playClips(List<web.HTMLAudioElement> clips, Future<void> until, double rate) async {
    var cut = false;
    final stopped = until.then((_) => cut = true);
    for (final audio in clips) {
      if (cut) return true;
      _audio = audio;
      audio.playbackRate = rate;
      final ended = Completer<bool>();
      audio.addEventListener('ended', ((web.Event _) {
        if (!ended.isCompleted) ended.complete(true);
      }).toJS);
      audio.addEventListener('error', ((web.Event _) {
        if (!ended.isCompleted) ended.complete(false);
      }).toJS);
      try {
        await audio.play().toDart;
      } catch (_) {
        // Stopped by a newer line while starting: that's not a failure, and the browser's voice must not take over
        if (cut || !identical(_audio, audio)) return true;
        _audio = null;
        return false; // blocked or unreadable
      }
      final ok = await Future.any([ended.future, stopped.then((_) => true)]);
      if (!ok) return false;
    }
    return true;
  }

  static void stop() {
    _audio?.pause();
    _audio = null;
  }
}
