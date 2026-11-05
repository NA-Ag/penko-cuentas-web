// column_view.dart — a column sum (or a multiplication by one digit) on screen, written the way it's done in a Mexican notebook: the carried 1 small
// above the next column, a borrowed 1 small beside the digit and the lending digit crossed out with its new value.
import 'package:flutter/material.dart';

import '../art/palette.dart';
import '../math/column.dart';
import 'pixel_ui.dart';

class ColumnView extends StatelessWidget {
  final ColumnProblem problem;
  final List<int?> written; // per step (place), the digit written so far (null = not yet)
  final int? active; // the place being worked now (highlighted)
  final Set<int> marked; // places whose carry/borrow marks are shown
  final bool flash; // soft amber on the active cell (a digit that wasn't right)
  const ColumnView({
    super.key,
    required this.problem,
    required this.written,
    this.active,
    this.marked = const {},
    this.flash = false,
  });

  static const _cell = 52.0;

  @override
  Widget build(BuildContext context) {
    final n = problem.columns;
    final steps = problem.steps;
    // Marks above each place (left to right on screen = highest place first)
    String? above(int place) {
      if (problem.op != Op.sub) {
        // What was carried (multiplication can carry more than 1)
        final carry = place > 0 && marked.contains(place - 1) ? steps[place - 1].carryOut : 0;
        return carry > 0 ? '$carry' : null;
      }
      // Subtraction: a place that lent 1 shows its new value (a 0 that lent shows 9)
      if (place > 0 && marked.contains(place - 1) && steps[place - 1].borrows) {
        final s = steps[place];
        return '${s.top == 0 ? 9 : s.top - 1}';
      }
      return null;
    }

    bool crossed(int place) =>
        problem.op == Op.sub && place > 0 && marked.contains(place - 1) && steps[place - 1].borrows;
    bool borrowed(int place) => problem.op == Op.sub && marked.contains(place) && steps[place].borrows;

    TextStyle big(Color c) => TextStyle(fontFamily: textFont, fontSize: 40, fontWeight: FontWeight.w700, color: c);
    const small = TextStyle(fontFamily: textFont, fontSize: 18, fontWeight: FontWeight.w700, color: Pk.gold);

    Widget digitCell(int place, String? text, {Color color = Pk.text, bool strike = false, bool lent = false}) =>
        SizedBox(
          width: _cell,
          height: _cell,
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (lent) const Padding(padding: EdgeInsets.only(top: 4), child: Text('1', style: small)),
                Text(
                  text ?? '',
                  style: big(color).copyWith(
                    decoration: strike ? TextDecoration.lineThrough : null,
                    decorationColor: Pk.gold,
                    decorationThickness: 3,
                  ),
                ),
              ],
            ),
          ),
        );

    String digitOf(int number, int place) {
      final s = '$number';
      final i = s.length - 1 - place;
      return i >= 0 ? s[i] : '';
    }

    final places = [for (var p = n - 1; p >= 0; p--) p];
    Widget row(List<Widget> cells, {Widget? lead}) =>
        Row(mainAxisSize: MainAxisSize.min, children: [SizedBox(width: _cell, child: lead), ...cells]);

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          row([
            for (final p in places) SizedBox(width: _cell, height: 24, child: Center(child: Text(above(p) ?? '', style: small))),
          ]),
          row([
            for (final p in places)
              digitCell(p, digitOf(problem.a, p), strike: crossed(p), lent: borrowed(p)),
          ]),
          row(
            [for (final p in places) digitCell(p, digitOf(problem.b, p))],
            lead: Center(child: Text(problem.symbol, style: big(Pk.gold))),
          ),
          Container(width: _cell * (n + 1), height: 4, color: Pk.text, margin: const EdgeInsets.symmetric(vertical: 4)),
          row([
            for (final p in places)
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: _cell,
                height: _cell + 8,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                  color: p == active ? (flash ? Pk.wrongSoft : Pk.cardHi) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: p == active ? (flash ? Pk.wrong : Pk.gold) : Colors.transparent,
                    width: 2.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    written[p] == null ? '' : '${written[p]}',
                    style: big(Pk.rightText),
                  ),
                ),
              ),
          ]),
        ],
      ),
    );
  }
}
