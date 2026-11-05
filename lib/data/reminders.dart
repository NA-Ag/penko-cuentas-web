// reminders.dart — daily practice reminders are phone notifications (reminders_native.dart); the web has none.
export 'reminders_native.dart' if (dart.library.js_interop) 'reminders_web.dart';
