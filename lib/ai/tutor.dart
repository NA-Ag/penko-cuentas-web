// tutor.dart — Penko's tutor model on phones (tutor_native.dart); on the web there is no model (tutor_web.dart), and
// the lessons work the same with Penko's written lines.
export 'tutor_native.dart' if (dart.library.js_interop) 'tutor_web.dart';
