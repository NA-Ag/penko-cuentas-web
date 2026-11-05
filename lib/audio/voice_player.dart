// voice_player.dart — plays one recorded line (a voice-pack file, see voice_pack.dart). On the web the browser's own
// <audio> plays it (voice_player_web.dart); on the phone there's no player yet (voice_player_stub.dart), so Penko keeps
// speaking with text-to-speech there. docs/VOICE_PACKS.md says how to add one.
export 'voice_player_stub.dart' if (dart.library.js_interop) 'voice_player_web.dart';
