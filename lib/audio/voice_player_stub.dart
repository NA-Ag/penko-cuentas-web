// voice_player_stub.dart — phones and desktop: no audio player in the app yet, so a recording can't be played and
// speech.dart falls back to text-to-speech. To play recordings here, add a player package (audioplayers or just_audio)
// and implement these two methods with it; nothing else changes (docs/VOICE_PACKS.md).
class VoicePlayer {
  /// Whether this platform can play recordings at all (if not, the voice pack isn't even looked up)
  static const bool supported = false;

  /// Plays [asset] until it ends or [until] completes. False if it couldn't be played (Penko then uses her TTS voice).
  static Future<bool> playAll(List<String> assets, {required Future<void> until, double rate = 1}) async => false;

  static void stop() {}
}
