// division.dart — the engine for "la casita": long division by a one- or two-digit number, worked the way it's taught in
// Mexican primaria. Take the first digits that fit, ask how many times the divisor goes in, write what's left, bring
// the next digit down, and so on. Code works out every stage; Penko only says it.

/// One stage of the casita: how many times the divisor goes into [number], and what's left
class Stage {
  final int number; // what we divide at this stage (a rest with the next digit brought down)
  final int quotient; // one digit of the answer
  final int rest; // number − quotient × divisor
  final int position; // the dividend digit this stage ends on, from the left (where its quotient digit is written)
  const Stage(this.number, this.quotient, this.rest, this.position);
}

class LongDivision {
  final int dividend;
  final int divisor;
  late final List<Stage> stages = _plan();

  LongDivision(this.dividend, this.divisor) {
    if (divisor < 2 || divisor > 99 || dividend < divisor) throw ArgumentError('$dividend ÷ $divisor');
  }

  int get quotient => dividend ~/ divisor;
  int get remainder => dividend % divisor;
  String get digits => '$dividend';

  List<Stage> _plan() {
    final out = <Stage>[];
    // Start with the first digits that hold the divisor at least once
    var pos = 0;
    var number = int.parse(digits[0]);
    while (number < divisor && pos + 1 < digits.length) {
      pos++;
      number = int.parse(digits.substring(0, pos + 1));
    }
    while (true) {
      final q = number ~/ divisor;
      final rest = number - q * divisor;
      out.add(Stage(number, q, rest, pos));
      if (pos + 1 >= digits.length) return out;
      pos++;
      number = rest * 10 + int.parse(digits[pos]);
    }
  }
}
