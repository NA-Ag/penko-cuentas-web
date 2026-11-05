import 'package:flutter_test/flutter_test.dart';
import 'package:penko_math/abacus/abacus.dart';
import 'package:penko_math/abacus/tracker.dart';

void main() {
  test('planned moves always land on the right number', () {
    for (var a = 0; a < 200; a++) {
      for (var b = 1; b < 200; b += 3) {
        final start = fromNumber(a, 4);
        var board = start;
        for (final s in planOperation(board, true, b)) {
          expect(sameBoard(applyMoves(s.before, s.moves), s.after), isTrue);
          board = s.after;
        }
        expect(toNumber(board), a + b);
        if (a >= b) {
          board = start;
          for (final s in planOperation(board, false, b)) {
            board = s.after;
          }
          expect(toNumber(board), a - b);
        }
      }
    }
  });

  test('techniques are the ones taught', () {
    expect(addDigit(fromNumber(1, 2), 1, 4).technique, Technique.five); // +4 on 1: +5 −1
    expect(addDigit(fromNumber(3, 2), 1, 9).technique, Technique.ten); // +9 on 3: −1, +10
    expect(addDigit(fromNumber(5, 2), 1, 6).technique, Technique.tenFive);
  });

  test('the tracker accepts any order and suggests the next move', () {
    final start = fromNumber(3, 2);
    final step = addDigit(start, 1, 9); // −1 here, +1 on the left
    final t = Tracker(start, step.moves);
    expect(t.track(start).status, TrackStatus.onTrack);
    // carry first, then the units: still on track
    final carried = applyMove(start, const Move(0, Bead.earth, 1));
    expect(t.track(carried).status, TrackStatus.onTrack);
    expect(t.track(applyMove(carried, const Move(1, Bead.earth, -1))).status, TrackStatus.done);
    expect(t.track(applyMove(start, const Move(1, Bead.heaven, 1))).status, TrackStatus.offTrack);
  });
}
