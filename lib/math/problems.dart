// problems.dart — makes column problems that need exactly what a lesson teaches (carrying or not, how many digits).
import 'dart:math';

import 'column.dart';

class ProblemSpec {
  final Op op;
  final int digits; // digits in the top number
  final bool carry; // true: at least one carry/borrow; false: none
  const ProblemSpec(this.op, this.digits, {required this.carry});
}

ColumnProblem makeProblem(ProblemSpec spec, Random rng) {
  final lo = spec.digits == 1 ? 1 : pow(10, spec.digits - 1).toInt();
  final hi = pow(10, spec.digits).toInt() - 1;
  for (var tries = 0; tries < 2000; tries++) {
    final a = lo + rng.nextInt(hi - lo + 1);
    final b = lo + rng.nextInt(hi - lo + 1);
    final p = switch (spec.op) {
      Op.add => ColumnProblem(a, b, Op.add),
      Op.sub => ColumnProblem(max(a, b), min(a, b), Op.sub),
      Op.mul => ColumnProblem(a, 2 + rng.nextInt(8), Op.mul), // times a one-digit number, 2 to 9
    };
    if (p.a == p.b) continue;
    if (p.hasCarry == spec.carry) return p;
  }
  throw StateError('no problem for $spec');
}
