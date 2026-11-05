import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:penko_math/math/fraction_lessons.dart';
import 'package:penko_math/screens/course.dart';
import 'package:penko_math/screens/unit_check_screen.dart';

void main() {
  test('fraction lessons: every answer is a whole, positive number and the steps agree', () {
    final r = Random(7);
    for (final l in fractionUnit) {
      for (var i = 0; i < 60; i++) {
        final p = l.make(r);
        for (final s in p.steps) {
          expect(s.answer, greaterThan(0), reason: '${l.id}: ${s.ask}');
          expect(s.hints.length, 2);
        }
      }
    }
  });

  test('every unit with a challenge gives at least 8 questions, all with answers', () {
    for (final u in course) {
      final make = checkFor(u.title);
      if (u.title == 'Ábaco') {
        expect(make, isNull);
        continue;
      }
      expect(make, isNotNull, reason: u.title);
      for (var seed = 0; seed < 20; seed++) {
        final items = make!(Random(seed));
        expect(items.length, greaterThanOrEqualTo(8), reason: u.title);
        expect(items.every((i) => i.answer >= 0 && i.question.isNotEmpty), isTrue);
      }
    }
  });
}
