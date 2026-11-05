// lang.dart — the app's language: Spanish (Mexico, the original) or English. Every visible or spoken line is written
// in both, side by side, with tr('español', 'English'), so a translation can't drift away from its original.
// The first start follows the device/browser language (Spanish if it's any Spanish, otherwise English); the
// student can change it in Ajustes / Settings (and on the welcome screen). Saved with the other settings.
// tr() itself lives in tr.dart (plain Dart, for the engines); it's exported from here.
import 'package:flutter/widgets.dart';

import '../data/store.dart';
import 'tr.dart';

export 'tr.dart';

class Lang {
  static final ValueNotifier<String> current = ValueNotifier<String>('es')..addListener(() => Tr.english = current.value == 'en');

  static bool get en => current.value == 'en';

  /// Runs [build] with tr() giving Spanish (see Tr.spanish)
  static T spanish<T>(T Function() build) => Tr.spanish(build);

  static Future<void> load() async {
    final saved = await Store.get<String>('lang');
    current.value = saved ?? (WidgetsBinding.instance.platformDispatcher.locale.languageCode == 'es' ? 'es' : 'en');
  }

  static Future<void> set(String lang) async {
    current.value = lang;
    await Store.set('lang', lang);
  }
}
