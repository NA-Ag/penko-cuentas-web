// abacus.dart — the soroban (ábaco), as data and rules, ported from Penko Soroban (core/abacus.ts, GPL-3.0).
// A board is a list of rod values, leftmost rod first. Each rod shows 0–9: one heaven bead above the beam, worth 5
// when pushed down to it, and four earth beads below, worth 1 each when pushed up to it.
// Adding and subtracting follow the Japanese method, one digit at a time, highest place first:
//   direct    the beads you need are free: just move them
//   five      "amigos del 5": +4 on 1 is +5 then −1
//   ten       "amigos del 10": +9 on 3 is −1 here, then +1 on the rod to the left
//   tenFive   a 10-friend whose own step needs a 5-friend
typedef Board = List<int>;

enum Bead { heaven, earth }

enum Technique { direct, five, ten, tenFive }

/// One physical action: push beads on one rod. Heaven delta is ±1 (adds or removes 5); earth delta is the number
/// of earth beads pushed up (+) or down (−).
class Move {
  final int rod;
  final Bead bead;
  final int delta;
  const Move(this.rod, this.bead, this.delta);

  @override
  bool operator ==(Object other) => other is Move && other.rod == rod && other.bead == bead && other.delta == delta;
  @override
  int get hashCode => Object.hash(rod, bead, delta);
  @override
  String toString() => 'Move($rod, ${bead.name}, $delta)';
}

/// Adding or subtracting one digit on one rod, including any carry or borrow it causes
class DigitStep {
  final int rod;
  final bool add;
  final int digit;
  final Technique technique;
  final List<Move> moves; // on this rod and, for carries and borrows, on rods to the left, in teaching order
  final Board before;
  final Board after;
  const DigitStep(this.rod, this.add, this.digit, this.technique, this.moves, this.before, this.after);
}

class AbacusError implements Exception {
  final String message;
  AbacusError(this.message);
  @override
  String toString() => message;
}

int heavenOf(int value) => value >= 5 ? 1 : 0;
int earthOf(int value) => value % 5;

Board emptyBoard(int rods) => List.filled(rods, 0);

/// A whole number on the board, its ones digit on the rightmost rod
Board fromNumber(int value, int rods) {
  if (value < 0) throw AbacusError("Can't show $value on an abacus");
  final board = List.filled(rods, 0);
  var rest = value;
  for (var rod = rods - 1; rod >= 0 && rest > 0; rod--) {
    board[rod] = rest % 10;
    rest ~/= 10;
  }
  if (rest > 0) throw AbacusError("$value doesn't fit on $rods rods");
  return board;
}

int toNumber(Board board) => board.fold(0, (total, d) => total * 10 + d);

bool sameBoard(Board a, Board b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

Board applyMove(Board board, Move m) {
  if (m.rod < 0 || m.rod >= board.length) throw AbacusError('There is no rod ${m.rod}');
  final value = board[m.rod];
  int next;
  if (m.bead == Bead.heaven) {
    if (m.delta == 1 && heavenOf(value) == 0) {
      next = value + 5;
    } else if (m.delta == -1 && heavenOf(value) == 1) {
      next = value - 5;
    } else {
      throw AbacusError("Can't move the heaven bead on rod ${m.rod} by ${m.delta}");
    }
  } else {
    final beads = earthOf(value) + m.delta;
    if (m.delta == 0 || beads < 0 || beads > 4) throw AbacusError("Can't move ${m.delta} earth beads on rod ${m.rod}");
    next = value + m.delta;
  }
  return [...board]..[m.rod] = next;
}

Board applyMoves(Board board, List<Move> moves) => moves.fold(board, applyMove);

/// What tapping a bead does, like on a real abacus: tapping a resting earth bead pushes it and the ones between it
/// and the beam up; tapping an active one lets it and the ones below it fall back. Earth beads are numbered from the
/// beam outwards (0 = nearest the beam).
Move tapBead(Board board, int rod, Bead bead, [int index = 0]) {
  final value = board[rod];
  if (bead == Bead.heaven) return Move(rod, bead, heavenOf(value) == 1 ? -1 : 1);
  final active = earthOf(value);
  final target = index < active ? index : index + 1;
  return Move(rod, bead, target - active);
}

List<Move> _direct(int rod, int amount, int sign) => [
  if (amount >= 5) Move(rod, Bead.heaven, sign),
  if (amount % 5 != 0) Move(rod, Bead.earth, sign * (amount % 5)),
];

bool _canAddDirect(int v, int n) => n < 5 ? earthOf(v) + n <= 4 : heavenOf(v) == 0 && earthOf(v) + (n - 5) <= 4;
bool _canSubDirect(int v, int n) => n < 5 ? earthOf(v) >= n : heavenOf(v) == 1 && earthOf(v) >= n - 5;

(Technique, List<Move>)? _addOnRod(int value, int rod, int n) {
  if (_canAddDirect(value, n)) return (Technique.direct, _direct(rod, n, 1));
  // Amigo del 5: +n = +5 − (5 − n)
  if (n < 5 && heavenOf(value) == 0 && earthOf(value) >= 5 - n) {
    return (Technique.five, [Move(rod, Bead.heaven, 1), Move(rod, Bead.earth, -(5 - n))]);
  }
  return null;
}

(Technique, List<Move>)? _subOnRod(int value, int rod, int n) {
  if (_canSubDirect(value, n)) return (Technique.direct, _direct(rod, n, -1));
  // Amigo del 5: −n = +(5 − n) − 5
  if (n < 5 && heavenOf(value) == 1 && earthOf(value) + (5 - n) <= 4) {
    return (Technique.five, [Move(rod, Bead.earth, 5 - n), Move(rod, Bead.heaven, -1)]);
  }
  return null;
}

/// Adds a digit (1–9) on [rod], the way it is taught. Carries go to the rod on the left.
DigitStep addDigit(Board board, int rod, int digit) {
  final value = board[rod];
  final onRod = value + digit <= 9 ? _addOnRod(value, rod, digit) : null;
  if (onRod != null) {
    return DigitStep(rod, true, digit, onRod.$1, onRod.$2, board, applyMoves(board, onRod.$2));
  }
  // Amigo del 10: +n = −(10 − n) here, then +1 on the left
  if (rod == 0) throw AbacusError('The answer is too big for this abacus');
  final take = _subOnRod(value, rod, 10 - digit)!;
  final carry = addDigit(applyMoves(board, take.$2), rod - 1, 1);
  return DigitStep(rod, true, digit, take.$1 == Technique.five ? Technique.tenFive : Technique.ten,
      [...take.$2, ...carry.moves], board, carry.after);
}

/// Subtracts a digit (1–9) on [rod]. Borrows come from the rod on the left.
DigitStep subtractDigit(Board board, int rod, int digit) {
  final value = board[rod];
  final onRod = value >= digit ? _subOnRod(value, rod, digit) : null;
  if (onRod != null) {
    return DigitStep(rod, false, digit, onRod.$1, onRod.$2, board, applyMoves(board, onRod.$2));
  }
  // Amigo del 10: −n = −1 on the left, then +(10 − n) here
  if (rod == 0 || board.sublist(0, rod).every((v) => v == 0)) throw AbacusError('The answer would be below zero');
  final borrow = subtractDigit(board, rod - 1, 1);
  final give = _addOnRod(borrow.after[rod], rod, 10 - digit)!;
  return DigitStep(rod, false, digit, give.$1 == Technique.five ? Technique.tenFive : Technique.ten,
      [...borrow.moves, ...give.$2], board, applyMoves(borrow.after, give.$2));
}

/// Adds or subtracts a whole number, highest place first as on a real abacus: one step per non-zero digit
List<DigitStep> planOperation(Board board, bool add, int amount) {
  final digits = '$amount'.split('').map(int.parse).toList();
  final steps = <DigitStep>[];
  var current = board;
  for (var i = 0; i < digits.length; i++) {
    if (digits[i] == 0) continue;
    final rod = board.length - 1 - (digits.length - 1 - i);
    if (rod < 0) throw AbacusError("$amount doesn't fit on this abacus");
    final step = add ? addDigit(current, rod, digits[i]) : subtractDigit(current, rod, digits[i]);
    steps.add(step);
    current = step.after;
  }
  return steps;
}

/// The plain moves to change one board into another, rod by rod (for "show this number": the method doesn't matter)
List<Move> movesToSet(Board from, Board to) => [
  for (var rod = 0; rod < from.length; rod++) ...[
    if ((from[rod] >= 5) != (to[rod] >= 5)) Move(rod, Bead.heaven, to[rod] >= 5 ? 1 : -1),
    if (earthOf(to[rod]) != earthOf(from[rod])) Move(rod, Bead.earth, earthOf(to[rod]) - earthOf(from[rod])),
  ],
];
