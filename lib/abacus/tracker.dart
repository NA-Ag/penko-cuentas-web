// tracker.dart — follows the student's bead moves towards a goal, ported from Penko Soroban (core/tracker.ts).
// The planned moves are taught in a set order, but real hands vary: heaven and earth beads in the other order, two
// earth beads in one flick or in two. Any order of the planned bead movements, in any size of flick, is on track.
import 'abacus.dart';

String _key(Board b) => b.join(',');

/// A planned move split into single-bead units (heaven moves are already one bead)
class _Unit {
  final int rod;
  final Bead bead;
  final int sign;
  final int from; // which planned move it came from
  const _Unit(this.rod, this.bead, this.sign, this.from);
}

enum TrackStatus { done, onTrack, offTrack }

class TrackState {
  final TrackStatus status;
  final Move? next; // the move to suggest when on track
  const TrackState(this.status, [this.next]);
}

class Tracker {
  final Board start;
  final Board goal;
  final Map<String, List<_Unit>> _reachable = {};

  Tracker(this.start, List<Move> moves) : goal = applyMoves(start, moves) {
    final units = [
      for (final (i, m) in moves.indexed)
        for (var k = 0; k < m.delta.abs(); k++) _Unit(m.rod, m.bead, m.delta.sign, i),
    ];
    _reachable[_key(start)] = units;
    final queue = <(Board, List<_Unit>)>[(start, units)];
    while (queue.isNotEmpty) {
      final (board, left) = queue.removeAt(0);
      final tried = <String>{};
      for (var i = 0; i < left.length; i++) {
        final u = left[i];
        if (!tried.add('${u.rod}:${u.bead}:${u.sign}')) continue;
        Board next;
        try {
          next = applyMove(board, Move(u.rod, u.bead, u.sign));
        } on AbacusError {
          continue;
        }
        if (_reachable.containsKey(_key(next))) continue;
        final rest = [...left]..removeAt(i);
        _reachable[_key(next)] = rest;
        queue.add((next, rest));
      }
    }
  }

  /// Where the board stands, and the next move to suggest
  TrackState track(Board board) {
    if (_key(board) == _key(goal)) return const TrackState(TrackStatus.done);
    final reached = _reachable[_key(board)];
    if (reached == null) return const TrackState(TrackStatus.offTrack);
    // A push and a pull of the same bead cancel out: suggest only the net movement
    final net = <String, int>{};
    for (final u in reached) {
      net.update('${u.rod}:${u.bead}', (n) => n + u.sign, ifAbsent: () => u.sign);
    }
    final left = <_Unit>[];
    for (final u in reached) {
      final k = '${u.rod}:${u.bead}';
      if (net[k]!.sign != u.sign) continue;
      net[k] = net[k]! - u.sign;
      left.add(u);
    }
    // The earliest planned move that can be made now, as one flick of all its remaining beads
    final byMove = <int, List<_Unit>>{};
    for (final u in left) {
      (byMove[u.from] ??= []).add(u);
    }
    for (final from in byMove.keys.toList()..sort()) {
      final g = byMove[from]!;
      final move = Move(g.first.rod, g.first.bead, g.first.sign * g.length);
      try {
        applyMove(board, move);
        return TrackState(TrackStatus.onTrack, move);
      } on AbacusError {
        continue;
      }
    }
    return const TrackState(TrackStatus.offTrack);
  }
}
