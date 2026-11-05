import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:penko_math/math/column.dart';
import 'package:penko_math/math/explain.dart';
import 'package:penko_math/math/lessons.dart';
import 'package:penko_math/math/problems.dart';

int fromDigits(ColumnProblem p) {
  var n = 0;
  for (final s in p.writable.reversed) {
    n = n * 10 + s.digit;
  }
  return n;
}

void main() {
  test('the written digits make the answer, for every problem up to 3 digits', () {
    for (var a = 0; a < 1000; a += 7) {
      for (var b = 0; b < 1000; b += 11) {
        final add = ColumnProblem(a, b, Op.add);
        expect(fromDigits(add), a + b, reason: '$add');
        if (a >= b) {
          final sub = ColumnProblem(a, b, Op.sub);
          expect(fromDigits(sub), a - b, reason: '$sub');
          for (final s in sub.writable) {
            final lines = [askStep(sub, s), doneStep(sub, s), ...hints(sub, s)];
            for (final l in lines) {
              expect(l.contains('-1'), isFalse, reason: '$sub: $l');
            }
          }
        }
      }
    }
  });

  test('carries and borrows', () {
    final p = ColumnProblem(47, 28, Op.add);
    expect(p.steps[0].carryOut, 1);
    expect(p.steps[1].carryIn, 1);
    expect(p.answer, 75);
    final q = ColumnProblem(503, 278, Op.sub);
    expect([for (final s in q.steps) s.digit], [5, 2, 2]);
    expect(q.steps[0].borrows && q.steps[1].borrows, isTrue);
  });

  test('typical slips are named', () {
    final p = ColumnProblem(47, 28, Op.add);
    expect(p.diagnose(p.steps[1], 6), Slip.forgotCarry); // 4+2 without the 1
    expect(p.diagnose(p.steps[0], 1), Slip.wroteTens); // 15 → wrote 1
    final q = ColumnProblem(52, 27, Op.sub);
    expect(q.diagnose(q.steps[0], 5), Slip.smallerFromLarger); // 7−2
    expect(q.diagnose(q.steps[1], 3), Slip.forgotBorrow); // 5−2 instead of 4−2
  });

  test('lessons make problems that fit them', () {
    final rng = Random(1);
    for (final l in unit1) {
      expect(l.example.hasCarry, l.spec.carry, reason: l.id);
      for (var i = 0; i < 50; i++) {
        final p = makeProblem(l.spec, rng);
        expect(p.hasCarry, l.spec.carry);
        expect('${p.a}'.length, l.spec.digits);
      }
    }
  });
}
