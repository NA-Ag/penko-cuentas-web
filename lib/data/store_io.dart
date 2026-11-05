// store.dart — everything the app saves, in one small JSON file in the app's private folder on the phone.
import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

class Store {
  static Map<String, dynamic>? _data;
  static File? _file;

  static Future<Map<String, dynamic>> _load() async {
    if (_data != null) return _data!;
    try {
      _file = File('${(await getApplicationSupportDirectory()).path}/penko_math.json');
      _data = _file!.existsSync() ? jsonDecode(await _file!.readAsString()) as Map<String, dynamic> : {};
    } catch (_) {
      _data = {}; // unreadable: start fresh rather than not start
    }
    return _data!;
  }

  static Future<T?> get<T>(String key) async => (await _load())[key] as T?;

  static Future<void> set(String key, Object? value) async {
    final d = await _load();
    value == null ? d.remove(key) : d[key] = value;
    try {
      await _file?.writeAsString(jsonEncode(d));
    } catch (_) {}
  }
}
