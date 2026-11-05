// store_web.dart — the web version saves the same JSON in the browser's local storage (this browser, this site only).
import 'dart:convert';

import 'package:web/web.dart' as web;

class Store {
  static const _key = 'penko_math';
  static Map<String, dynamic>? _data;

  static Map<String, dynamic> _load() {
    if (_data != null) return _data!;
    try {
      final raw = web.window.localStorage.getItem(_key);
      _data = raw == null ? {} : jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      _data = {}; // unreadable or storage blocked (private window): start fresh rather than not start
    }
    return _data!;
  }

  static Future<T?> get<T>(String key) async => _load()[key] as T?;

  static Future<void> set(String key, Object? value) async {
    final d = _load();
    value == null ? d.remove(key) : d[key] = value;
    try {
      web.window.localStorage.setItem(_key, jsonEncode(d));
    } catch (_) {}
  }
}
