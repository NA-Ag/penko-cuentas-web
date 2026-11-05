// settings.dart — the student's choices: Penko's voice on or off, and bigger text. Kept on the phone only.
import 'package:flutter/foundation.dart';

import 'store.dart';

class Settings {
  static final voice = ValueNotifier(true);
  static final bigText = ValueNotifier(false);

  static Future<void> load() async {
    voice.value = await Store.get<bool>('voice') ?? true;
    bigText.value = await Store.get<bool>('big_text') ?? false;
  }

  static Future<void> setVoice(bool on) async {
    voice.value = on;
    await Store.set('voice', on);
  }

  static Future<void> setBigText(bool on) async {
    bigText.value = on;
    await Store.set('big_text', on);
  }
}
