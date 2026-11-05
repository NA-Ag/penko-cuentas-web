// store.dart — everything the app saves: a small JSON file on the phone (store_io.dart), the browser's local storage
// on the web (store_web.dart). Same interface.
export 'store_io.dart' if (dart.library.js_interop) 'store_web.dart';
