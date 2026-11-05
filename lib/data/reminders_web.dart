// reminders_web.dart — no notifications on the web: same interface as reminders_native.dart, always off.
import 'package:flutter/material.dart';

class Reminders {
  Reminders._();
  static final instance = Reminders._();

  Future<TimeOfDay?> time() async => null;
  Future<bool> set(TimeOfDay? t) async => false;
  Future<void> reschedule() async {}
}
