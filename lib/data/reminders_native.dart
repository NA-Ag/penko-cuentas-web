// reminders.dart — an optional daily reminder, all on the phone (no server, no account, nothing sent anywhere). Off
// until the person turns it on in Ajustes and picks the time. Gentle by design: never on a day already practised, and
// planned only a week ahead each time the app opens, so it stops by itself when someone stops using the app.
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../i18n/lang.dart';
import 'store.dart';

List<String> get _lines => [
  tr('¿Una lección cortita hoy? Penko te espera.', 'A short lesson today? Penko is waiting for you.'),
  tr('Cinco minutos de matemáticas y listo.', "Five minutes of math and you're done."),
  tr('Hoy toca practicar un poco con Penko.', "Today's a good day to practice a little with Penko."),
  tr('¿Repasamos lo que te costó la última vez?', 'Shall we review what was hard last time?'),
];

class Reminders {
  Reminders._();
  static final instance = Reminders._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  Future<void> _init() async {
    if (_ready) return;
    tzdata.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation((await FlutterTimezone.getLocalTimezone()).identifier));
    } catch (_) {}
    await _plugin.initialize(settings: const InitializationSettings(android: AndroidInitializationSettings('ic_stat_penko')));
    _ready = true;
  }

  /// The reminder time, or null when they're off
  Future<TimeOfDay?> time() async {
    final t = await Store.get<String>('reminder');
    final p = t?.split(':');
    return p == null ? null : TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
  }

  /// Turns the reminder on at [t] (asking Android's permission the first time) or off (null). False if refused.
  Future<bool> set(TimeOfDay? t) async {
    await _init();
    if (t != null) {
      final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (!(await android?.requestNotificationsPermission() ?? true)) return false;
    }
    await Store.set('reminder', t == null ? null : '${t.hour}:${t.minute}');
    await reschedule();
    return true;
  }

  /// Plans the next week again (when the app opens and after each lesson)
  Future<void> reschedule() async {
    try {
      final t = await time();
      await _init();
      await _plugin.cancelAll();
      if (t == null) return;
      final now = DateTime.now();
      final today = now.toIso8601String().substring(0, 10);
      final practised = await Store.get<String>('last_practice') == today;
      for (var day = 0; day < 7; day++) {
        final at = DateTime(now.year, now.month, now.day + day, t.hour, t.minute);
        if (!at.isAfter(now) || (day == 0 && practised)) continue;
        await _plugin.zonedSchedule(
          id: day,
          scheduledDate: tz.TZDateTime.from(at, tz.local),
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails('daily_reminder', tr('Recordatorio diario', 'Daily reminder'),
                icon: 'ic_stat_penko', color: const Color(0xFFF2C94C)),
          ),
          // Inexact: Android may move it a few minutes to save battery; no special alarm permission needed
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          title: 'Penko Cuentas Claras',
          body: _lines[day % _lines.length],
        );
      }
    } catch (e) {
      debugPrint('Reminders: $e'); // a nicety: never let it break the app
    }
  }
}
