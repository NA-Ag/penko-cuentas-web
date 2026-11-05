// column.dart — the maths engine for column addition, subtraction and multiplication by one digit, worked the way
// it's taught in Mexican primaria: right to left, "llevamos 1" for a carry and "pedimos prestado" for a borrow. It plans every step,
// checks each digit the student writes, and names the usual mistake behind a wrong digit. Code decides what is
// right; nothing here depends on the model.
import '../i18n/tr.dart';

enum Op { add, sub, mul }

/// Place names, from the right
const placeNames = ['unidades', 'decenas', 'centenas', 'unidades de millar', 'decenas de millar'];
const placeNamesEn = ['ones', 'tens', 'hundreds', 'thousands', 'ten thousands'];

/// What went wrong with a digit (a known slip, so Penko can say something useful)
enum Slip {
  forgotCarry, // didn't add what was carried from the column before
  wroteTens, // wrote the tens of a two-digit sum instead of the units
  smallerFromLarger, // took the smaller digit from the larger one instead of borrowing
  forgotBorrow, // forgot this column lent 1 to the column before
  addedInstead, // added instead of subtracting or multiplying
  offByOne, // close: one more or one less
  other,
}

/// One column of the worked problem
class ColumnStep {
  final int place; // 0 = unidades
  final int top; // the top digit as written (0 when the number is shorter)
  final int bottom; // multiplication: the one-digit multiplier, in every column
  final int carryIn; // addition/multiplication: carried in; subtraction: 1 lent to the column before
  final bool borrows; // subtraction: this column asks the next one for 1
  final int value; // addition: top + bottom + carryIn; subtraction: (top - carryIn, +10 if it borrows) - bottom;
  // multiplication: top × bottom + carryIn
  final int digit; // the digit the student writes
  final bool written; // false for a leading zero (nothing to write)
  const ColumnStep({
    required this.place,
    required this.top,
    required this.bottom,
    required this.carryIn,
    required this.borrows,
    required this.value,
    required this.digit,
    required this.written,
  });

  /// What this column carries to the next one (multiplication can carry more than 1)
  int get carryOut => value ~/ 10;
  String get placeName => place < placeNames.length
      ? tr(placeNames[place], placeNamesEn[place])
      : tr('columna ${place + 1}', 'column ${place + 1}');
}

class ColumnProblem {
  final int a;
  final int b;
  final Op op;
  late final List<ColumnStep> steps = _plan();

  ColumnProblem(this.a, this.b, this.op) {
    if (a < 0 || b < 0 || (op == Op.sub && b > a) || (op == Op.mul && b > 9)) throw ArgumentError('$a $symbol $b');
  }

  int get answer => switch (op) { Op.add => a + b, Op.sub => a - b, Op.mul => a * b };
  String get symbol => switch (op) { Op.add => '+', Op.sub => '−', Op.mul => '×' };
  int get columns => steps.length;

  /// Steps the student writes a digit for, right to left
  List<ColumnStep> get writable => [for (final s in steps) if (s.written) s];

  static int _digit(int n, int place) => (n ~/ _pow10(place)) % 10;
  static int _pow10(int p) => [1, 10, 100, 1000, 10000, 100000][p];

  List<ColumnStep> _plan() {
    final width = [a, b, answer].map((n) => '$n'.length).reduce((x, y) => x > y ? x : y);
    final answerWidth = '$answer'.length;
    final out = <ColumnStep>[];
    var carry = 0;
    for (var p = 0; p < width; p++) {
      final t = _digit(a, p), d = _digit(b, p);
      if (op == Op.mul) {
        // Every digit of the top number times the one-digit multiplier, plus what was carried
        final v = t * b + carry;
        out.add(ColumnStep(
          place: p, top: t, bottom: b, carryIn: carry, borrows: false, value: v, digit: v % 10, written: p < answerWidth,
        ));
        carry = v ~/ 10;
      } else if (op == Op.add) {
        final v = t + d + carry;
        out.add(ColumnStep(
          place: p, top: t, bottom: d, carryIn: carry, borrows: false, value: v, digit: v % 10, written: p < answerWidth,
        ));
        carry = v ~/ 10;
      } else {
        final have = t - carry;
        final borrows = have < d;
        final v = (borrows ? have + 10 : have) - d;
        out.add(ColumnStep(
          place: p, top: t, bottom: d, carryIn: carry, borrows: borrows, value: v, digit: v, written: p < answerWidth,
        ));
        carry = borrows ? 1 : 0;
      }
    }
    return out;
  }

  bool get hasCarry => op == Op.sub ? steps.any((s) => s.borrows) : steps.any((s) => s.carryOut > 0);

  /// Why [digit] isn't right for [s] (call only when it's wrong)
  Slip diagnose(ColumnStep s, int digit) {
    if (op == Op.mul) {
      if (s.carryIn > 0 && digit == (s.top * s.bottom) % 10) return Slip.forgotCarry;
      if (s.value >= 10 && digit == (s.value ~/ 10) % 10 && s.digit != digit) return Slip.wroteTens;
      if (digit == (s.top + s.bottom + s.carryIn) % 10) return Slip.addedInstead;
    } else if (op == Op.add) {
      if (s.carryIn > 0 && digit == (s.top + s.bottom) % 10) return Slip.forgotCarry;
      if (s.value >= 10 && digit == s.value ~/ 10 && s.digit != digit) return Slip.wroteTens;
    } else {
      if (s.borrows && digit == (s.bottom - (s.top - s.carryIn)).abs()) return Slip.smallerFromLarger;
      if (s.carryIn > 0) {
        final noLend = s.top < s.bottom ? s.top + 10 - s.bottom : s.top - s.bottom;
        if (digit == noLend) return Slip.forgotBorrow;
      }
      if (digit == (s.top + s.bottom) % 10) return Slip.addedInstead;
    }
    if ((digit - s.digit).abs() == 1) return Slip.offByOne;
    return Slip.other;
  }

  @override
  String toString() => '$a $symbol $b';
}
