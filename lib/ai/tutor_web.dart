// tutor_web.dart — the web version has no tutor model (it runs on the phone only): same interface as tutor_native.dart,
// always "not available", so screens show Penko's written lines and hide "¿Por qué?" and the receipt camera.
import 'dart:async';

import '../i18n/tr.dart';

class Tutor {
  Tutor._();
  static final instance = Tutor._();

  String? lastRaw;
  Duration? lastTime;
  Duration? loadTime;

  Future<String> status() async => tr(
    'En la versión web Penko no usa su modelo de IA (vive en el teléfono, sin internet). Las lecciones y los '
        'simuladores funcionan igual.',
    "In the web version Penko doesn't use her AI model (it lives on the phone, with no internet). The lessons and "
        'simulators work just the same.',
  );

  Future<bool> available() async => false;
  Future<void> warmUp() async {}
  Future<String?> explain({required String facts, required String question, Set<double> forbidden = const {}}) async =>
      null;
  Future<String?> look(String imagePath, String instruction) async => null;
  void cancel() {}
}
