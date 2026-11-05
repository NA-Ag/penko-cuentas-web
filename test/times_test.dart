import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:penko_math/math/column.dart';
import 'package:penko_math/math/explain.dart';
import 'package:penko_math/math/lessons.dart';
import 'package:penko_math/math/problems.dart';
import 'package:penko_math/math/times_lessons.dart';
import 'package:penko_math/money/money_lessons.dart';

int fromDigits(ColumnProblem p) {
  var n = 0;
  for (final s in p.writable.reversed) {
    n = n * 10 + s.digit;
  }
  return n;
}

void main() {
  test('multiplying by one digit: the written digits make the answer', () {
    for (var a = 1; a < 2000; a += 13) {
      for (var b = 2; b <= 9; b++) {
        final p = ColumnProblem(a, b, Op.mul);
        expect(fromDigits(p), a * b, reason: '$p');
        for (final s in p.writable) {
          expect(s.value % 10, s.digit);
          expect(hints(p, s), isNotEmpty);
          askStep(p, s);
          doneStep(p, s);
        }
      }
    }
  });

  test('multiplication slips: a forgotten carry and an addition are named', () {
    final p = ColumnProblem(47, 6, Op.mul); // 7×6 = 42 → 2, carry 4; 4×6+4 = 28
    final tens = p.writable[1];
    expect(p.diagnose(tens, 4), Slip.forgotCarry); // 24 → 4
    expect(p.diagnose(tens, 2), Slip.wroteTens); // 28 → 2
    expect(slipLine(p, tens, Slip.forgotCarry), contains('4 que llevamos'));
  });

  test('multiplication lessons get problems with and without carrying', () {
    final r = Random(3);
    for (final l in unit2Columns) {
      for (var i = 0; i < 50; i++) {
        final p = makeProblem(l.spec, r);
        expect(p.hasCarry, l.spec.carry);
        expect(p.b, inInclusiveRange(2, 9));
      }
    }
  });

  test('la casita: every stage adds up, for every division up to 999 by 2–25', () {
    for (var n = 10; n < 1000; n++) {
      for (var d = 2; d <= 25; d++) {
        if (n < d) continue;
        final div = LongDivision(n, d);
        final q = div.stages.map((s) => s.quotient).join();
        expect(int.parse(q), n ~/ d, reason: '$n ÷ $d');
        expect(div.stages.last.rest, n % d);
        for (final s in div.stages) {
          expect(s.quotient, inInclusiveRange(0, 9));
          expect(s.rest, lessThan(d));
          expect(s.quotient * d + s.rest, s.number);
        }
      }
    }
  });

  test('84 ÷ 4 and 435 ÷ 5 in the casita', () {
    expect([for (final s in LongDivision(84, 4).stages) (s.number, s.quotient, s.rest)], [(8, 2, 0), (4, 1, 0)]);
    expect([for (final s in LongDivision(435, 5).stages) (s.number, s.quotient, s.rest)], [(43, 8, 3), (35, 7, 0)]);
  });

  test('every step lesson makes problems whose steps have answers and hints', () {
    final r = Random(5);
    for (final l in [tablesLesson, timesTwoLesson, ...unit3Division, ...moneyUnit]) {
      for (var i = 0; i < 40; i++) {
        final p = l.make(r);
        expect(p.steps, isNotEmpty, reason: l.id);
        for (final s in p.steps) {
          expect(s.answer, greaterThanOrEqualTo(0), reason: '${l.id}: ${s.ask}');
          expect(s.hints, isNotEmpty);
        }
        if (p.division != null) expect(p.steps.length, p.division!.stages.length * 2);
      }
    }
  });
}
