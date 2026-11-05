// progress.dart — what the app keeps about learning, on the phone only: which lessons are finished, how they went at
// the first try (the share of steps answered right without a slip or a hint, last 5 times), and the end-of-unit
// challenge scores. No times, no history beyond that, nothing that leaves the phone.
import 'store.dart';

class Progress {
  static const _key = 'done_lessons';
  static const _firstTry = 'first_try'; // {lessonId: [0.8, 1.0, …]}
  static const _checks = 'unit_checks'; // {unitTitle: [7, 9, …]} (out of unitCheckSize)
  static const unitCheckSize = 8;

  static Future<Set<String>> done() async => {...?(await Store.get<List>(_key))?.cast<String>()};

  /// A lesson finished, with the share of first-try right answers (0–1), if it was measured
  static Future<void> finish(String id, {double? firstTry}) async {
    await Store.set(_key, {...await done(), id}.toList());
    await Store.set('last_practice', DateTime.now().toIso8601String().substring(0, 10)); // no reminder today
    if (firstTry != null) {
      final all = {...?(await Store.get<Map>(_firstTry))?.cast<String, dynamic>()};
      all[id] = [...?(all[id] as List?)?.cast<num>(), double.parse(firstTry.toStringAsFixed(2))].reversed.take(5).toList().reversed.toList();
      await Store.set(_firstTry, all);
    }
  }

  /// The latest first-try share of each lesson that has one
  static Future<Map<String, double>> firstTry() async => {
    for (final e in ((await Store.get<Map>(_firstTry)) ?? const {}).entries)
      if ((e.value as List).isNotEmpty) e.key as String: ((e.value as List).last as num).toDouble(),
  };

  /// Lessons worth reviewing: finished, but under 60% right at the first try last time
  static bool needsReview(double? share) => share != null && share < 0.6;

  static Future<void> saveCheck(String unit, int right) async {
    final all = {...?(await Store.get<Map>(_checks))?.cast<String, dynamic>()};
    all[unit] = [...?(all[unit] as List?)?.cast<num>(), right];
    await Store.set(_checks, all);
  }

  /// The best end-of-unit challenge score per unit
  static Future<Map<String, int>> checks() async => {
    for (final e in ((await Store.get<Map>(_checks)) ?? const {}).entries)
      if ((e.value as List).isNotEmpty) e.key as String: (e.value as List).cast<num>().reduce((a, b) => a > b ? a : b).toInt(),
  };

  static Future<void> reset() async {
    await Store.set(_key, null);
    await Store.set(_firstTry, null);
    await Store.set(_checks, null);
  }
}
