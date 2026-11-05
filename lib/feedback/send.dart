// send.dart — what only a browser can do: send a message to the gateway with a Turnstile check (send_web.dart). The
// phone app does neither (send_stub.dart): its screen opens the website's form instead.
export 'send_stub.dart' if (dart.library.js_interop) 'send_web.dart';
