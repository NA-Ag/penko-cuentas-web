// abacus_view.dart — the abacus on screen (from Penko Soroban's Abacus.tsx): tap a bead to move it like on a real
// one. A hinted move makes its beads glow with an arrow showing which way to push. Each rod reads out its value to
// screen readers, so the abacus works without seeing the numbers too.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../art/palette.dart';
import 'abacus.dart';

// Geometry in drawing units; the whole abacus scales to fit
const _rodGap = 60.0;
const _side = 22.0;
const _frame = 14.0;
const _beadW = 52.0;
const _beadH = 26.0;
const _beamY = _frame + 2 * _beadH + 8;
const _beamH = 10.0;
const _earthTop = _beamY + _beamH;
const _earthBottom = _earthTop + 5 * _beadH + 8;
const _height = _earthBottom + _frame;

double _heavenY(bool active) => active ? _beamY - _beadH : _frame + 2;
// Earth beads numbered from the beam outwards: active ones rest against the beam, the others at the bottom
double _earthY(int index, int active) => index < active ? _earthTop + index * _beadH : _earthBottom - (4 - index) * _beadH;

class AbacusView extends StatelessWidget {
  final Board board;
  final void Function(Board next, Move move)? onChange;
  final Move? hint;
  final Bead? glow; // point out a part while Penko explains it
  const AbacusView({super.key, required this.board, this.onChange, this.hint, this.glow});

  double get _width => _side * 2 + board.length * _rodGap;

  void _tap(Offset local, double scale) {
    if (onChange == null) return;
    final x = local.dx / scale, y = local.dy / scale;
    final rod = ((x - _side) / _rodGap).floor();
    if (rod < 0 || rod >= board.length) return;
    final value = board[rod];
    Move move;
    if (y < _beamY) {
      move = tapBead(board, rod, Bead.heaven);
    } else if (y > _earthTop) {
      // Which earth bead was touched, by where each one sits now
      var index = -1;
      for (var i = 0; i < 4; i++) {
        final top = _earthY(i, earthOf(value));
        if (y >= top && y < top + _beadH) index = i;
      }
      if (index < 0) return;
      move = tapBead(board, rod, Bead.earth, index);
    } else {
      return;
    }
    try {
      onChange!(applyMove(board, move), move);
      HapticFeedback.selectionClick();
    } on AbacusError {
      // not a move a real abacus can make
    }
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final scale = [box.maxWidth / _width, box.maxHeight.isFinite ? box.maxHeight / _height : 99.0, 2.2]
          .reduce((a, b) => a < b ? a : b);
      return Center(
        child: Semantics(
          label: 'Ábaco: ${board.join(' ')}',
          child: GestureDetector(
            onTapDown: (d) => _tap(d.localPosition, scale),
            child: CustomPaint(
              size: Size(_width * scale, _height * scale),
              painter: _AbacusPainter(board, hint, glow, scale),
            ),
          ),
        ),
      );
    },
  );
}

class _AbacusPainter extends CustomPainter {
  final Board board;
  final Move? hint;
  final Bead? glow;
  final double scale;
  _AbacusPainter(this.board, this.hint, this.glow, this.scale);

  static const _wood = Color(0xFF8B5A2B);
  static const _woodDark = Color(0xFF5E3A1A);
  static const _window = Color(0xFF0F1628);
  static const _bead = Color(0xFFE0A458);
  static const _beadLight = Color(0xFFF6D19A);
  static const _glowColor = Pk.gold;

  Path _beadPath(double cx, double y) {
    final l = cx - _beadW / 2, r = cx + _beadW / 2;
    return Path()
      ..moveTo(l, y + _beadH / 2)
      ..lineTo(l + 11, y + 1.5)
      ..lineTo(r - 11, y + 1.5)
      ..lineTo(r, y + _beadH / 2)
      ..lineTo(r - 11, y + _beadH - 1.5)
      ..lineTo(l + 11, y + _beadH - 1.5)
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(scale);
    final width = _side * 2 + board.length * _rodGap;
    final rrect = RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, width, _height), const Radius.circular(10));
    canvas.drawRRect(
      rrect,
      Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [_wood, _woodDark]).createShader(rrect.outerRect),
    );
    canvas.drawRect(Rect.fromLTWH(_frame, _frame, width - 2 * _frame, _height - 2 * _frame), Paint()..color = _window);

    for (var rod = 0; rod < board.length; rod++) {
      final cx = _side + rod * _rodGap + _rodGap / 2;
      canvas.drawLine(Offset(cx, _frame), Offset(cx, _height - _frame),
          Paint()..color = Pk.gold.withValues(alpha: 0.55)..strokeWidth = 3);
    }
    // Beam, with a dot on the ones rod and every third rod from it
    canvas.drawRect(Rect.fromLTWH(_frame - 4, _beamY, width - 2 * _frame + 8, _beamH),
        Paint()..color = _wood);
    for (var rod = 0; rod < board.length; rod++) {
      if ((board.length - 1 - rod) % 3 == 0) {
        canvas.drawCircle(Offset(_side + rod * _rodGap + _rodGap / 2, _beamY + _beamH / 2), 2.6,
            Paint()..color = Pk.dialog);
      }
    }

    for (var rod = 0; rod < board.length; rod++) {
      final cx = _side + rod * _rodGap + _rodGap / 2;
      final value = board[rod];
      final active = earthOf(value);
      // Which beads the hint moves on this rod
      var hintHeaven = false;
      final hintEarth = <int>{};
      if (hint != null && hint!.rod == rod) {
        if (hint!.bead == Bead.heaven) {
          hintHeaven = true;
        } else {
          final from = hint!.delta > 0 ? active : active + hint!.delta;
          for (var i = 0; i < hint!.delta.abs(); i++) {
            hintEarth.add(from + i);
          }
        }
      }
      void bead(double y, bool lit) {
        final path = _beadPath(cx, y);
        canvas.drawPath(
          path,
          Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [_beadLight, _bead]).createShader(path.getBounds()),
        );
        canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = lit ? 3.5 : 1
            ..color = lit ? _glowColor : Colors.black.withValues(alpha: 0.35),
        );
      }

      bead(_heavenY(heavenOf(value) == 1), hintHeaven || glow == Bead.heaven);
      for (var i = 0; i < 4; i++) {
        bead(_earthY(i, active), hintEarth.contains(i) || glow == Bead.earth);
      }
      // Arrow for a hinted move: towards the beam adds, away from it takes away
      if (hint != null && hint!.rod == rod) {
        final towardBeam = hint!.delta > 0;
        final y = hint!.bead == Bead.heaven
            ? _heavenY(heavenOf(value) == 1) + _beadH / 2
            : _earthY(hintEarth.first, active) + _beadH * hintEarth.length / 2;
        final down = hint!.bead == Bead.heaven ? towardBeam : !towardBeam;
        final x = cx + _beadW / 2 + 3;
        final p = Paint()
          ..color = _glowColor
          ..strokeWidth = 3.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;
        final s = down ? 1.0 : -1.0;
        canvas.drawLine(Offset(x, y - 9 * s), Offset(x, y + 9 * s), p);
        canvas.drawLine(Offset(x - 5, y + 3 * s), Offset(x, y + 9 * s), p);
        canvas.drawLine(Offset(x + 5, y + 3 * s), Offset(x, y + 9 * s), p);
      }
    }
  }

  @override
  bool shouldRepaint(_AbacusPainter old) =>
      old.board != board || old.hint != hint || old.glow != glow || old.scale != scale;
}
