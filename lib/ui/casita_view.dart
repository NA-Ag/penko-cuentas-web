// casita_view.dart — long division drawn the way it's written in a Mexican notebook: the divisor outside "la casita",
// the dividend inside, each digit of the answer on the roof above the digit it belongs to, and under the dividend
// what's left at each stage with the next digit brought down. It fills in as the student solves the steps.
import 'package:flutter/material.dart';

import '../art/palette.dart';
import '../i18n/lang.dart';
import '../math/division.dart';
import 'pixel_ui.dart';

class CasitaView extends StatelessWidget {
  final LongDivision division;
  final int solved; // steps solved so far: two per stage (how many times it goes in, what's left)
  const CasitaView({super.key, required this.division, required this.solved});

  static const _cell = 40.0;

  @override
  Widget build(BuildContext context) {
    final d = division;
    final n = d.digits.length;
    TextStyle style(Color c) => TextStyle(fontFamily: textFont, fontSize: 32, fontWeight: FontWeight.w700, color: c);

    // A row of n cells; [text] is right-aligned so that its last digit sits under dividend digit [end]
    Widget row(String text, int end, Color color) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < n; i++)
          SizedBox(
            width: _cell,
            height: _cell,
            child: Center(
              child: Text(
                i > end || i < end - text.length + 1 ? '' : text[text.length - 1 - (end - i)],
                style: style(color),
              ),
            ),
          ),
      ],
    );

    // The answer on the roof: a stage's digit shows once its first step is solved
    final roof = List<String>.filled(n, '');
    for (final (i, s) in d.stages.indexed) {
      if (solved > i * 2) roof[s.position] = '${s.quotient}';
    }
    // Under the dividend: after a stage's rest is found, the rest with the next digit brought down (or the last rest)
    final below = <Widget>[];
    for (final (i, s) in d.stages.indexed) {
      if (solved <= i * 2 + 1) break;
      final last = i + 1 == d.stages.length;
      below.add(last
          ? row('${s.rest}', s.position, Pk.gold)
          : row('${d.stages[i + 1].number}'.padLeft(2, '0'), s.position + 1, Pk.text));
    }

    return Semantics(
      label: tr('${d.dividend} entre ${d.divisor}${solved >= d.stages.length * 2 ? ' es igual a ${d.quotient}' : ''}',
          '${d.dividend} divided by ${d.divisor}${solved >= d.stages.length * 2 ? ' equals ${d.quotient}' : ''}'),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(mainAxisSize: MainAxisSize.min, children: [
              for (final q in roof)
                SizedBox(width: _cell, height: _cell, child: Center(child: Text(q, style: style(Pk.rightText)))),
            ]),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(padding: const EdgeInsets.only(right: 6), child: Text('${d.divisor}', style: style(Pk.gold))),
                Container(
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: Pk.text, width: 3), left: BorderSide(color: Pk.text, width: 3)),
                  ),
                  child: row(d.digits, n - 1, Pk.text),
                ),
              ],
            ),
            ...below,
          ],
        ),
      ),
    );
  }
}
