// unit_check_screen.dart — "Reto de la unidad": a few questions from the whole unit, with no hints and no "¿por qué?",
// to see what has stuck. Each answer is marked straight away (a wrong one shows the right answer, gently); the score
// is kept on the phone so the student, a tutor or a pilot can see progress. Questions come from the engines.
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../art/palette.dart';
import '../art/penko.dart';
import '../audio/speech.dart';
import '../data/progress.dart';
import '../data/settings.dart';
import '../i18n/lang.dart';
import '../math/column.dart';
import '../math/explain.dart' show spoken;
import '../math/fraction_lessons.dart';
import '../math/lessons.dart';
import '../math/problems.dart';
import '../money/money.dart';
import '../money/money_lessons.dart';
import '../ui/pixel_ui.dart';
import '../wayfinding/wayfinding.dart';
import 'course.dart';

/// One question of a challenge
class CheckItem {
  final String question; // read aloud too
  final String? big; // the problem in big type ("47 + 28")
  final int answer;
  final bool pesos;
  const CheckItem(this.question, this.answer, {this.big, this.pesos = false});
}

CheckItem _column(ColumnProblem p) =>
    CheckItem(tr('¿Cuánto es ${p.a} ${p.symbol} ${p.b}?', 'What is ${p.a} ${p.symbol} ${p.b}?'), p.answer, big: '${p.a} ${p.symbol} ${p.b}');

/// A step's question without its "Entonces," ("So,"), to stand on its own. [money]: "¿cuánto" becomes "¿Cuánto"
String _alone(String ask, {bool money = false}) => (money
        ? ask.replaceFirst('Entonces, ¿cuánto', '¿Cuánto')
        : ask.replaceFirst('Entonces, ¿', '¿'))
    .replaceFirstMapped(RegExp(r'^So, (\w)'), (m) => m[1]!.toUpperCase());

/// The challenge questions for each unit, by its key (the Spanish title, Unit.key; null: the unit has none)
List<CheckItem> Function(Random)? checkFor(String unit) => switch (unit) {
  'Sumas y restas' => (r) => [
    for (final l in unit1) _column(makeProblem(l.spec, r)),
    _column(makeProblem(unit1[1].spec, r)),
    _column(makeProblem(unit1[4].spec, r)),
  ],
  'Multiplicar' => (r) => [
    for (var i = 0; i < 3; i++)
      (() {
        final a = 2 + r.nextInt(8), b = 2 + r.nextInt(8);
        return CheckItem(tr('¿Cuánto es $a × $b?', 'What is $a × $b?'), a * b, big: '$a × $b');
      })(),
    for (final l in unit2Columns) _column(makeProblem(l.spec, r)),
    _column(makeProblem(unit2Columns[1].spec, r)),
    _column(makeProblem(unit2Columns[2].spec, r)),
  ],
  'Dividir' => (r) => [
    for (var i = 0; i < 3; i++)
      (() {
        final d = 2 + r.nextInt(8), q = 2 + r.nextInt(8);
        return CheckItem(tr('¿Cuánto es ${d * q} ÷ $d?', 'What is ${d * q} ÷ $d?'), q, big: '${d * q} ÷ $d');
      })(),
    for (var i = 0; i < 2; i++)
      (() {
        final d = 3 + r.nextInt(6), q = 2 + r.nextInt(8), left = 1 + r.nextInt(d - 1);
        return CheckItem(tr('Repartes ${d * q + left} entre $d por igual. ¿Cuánto sobra?',
            'You share ${d * q + left} equally among $d. How many are left over?'), left);
      })(),
    for (final digits in [2, 3, 3])
      (() {
        final lo = pow(10, digits - 1).toInt();
        late LongDivision ld;
        do {
          ld = LongDivision(lo + r.nextInt(9 * lo), 2 + r.nextInt(8));
        } while (ld.remainder != 0);
        return CheckItem(tr('¿Cuánto es ${ld.dividend} ÷ ${ld.divisor}?', 'What is ${ld.dividend} ÷ ${ld.divisor}?'), ld.quotient,
            big: '${ld.dividend} ÷ ${ld.divisor}');
      })(),
  ],
  'Fracciones y porcentajes' => (r) => [
    for (final l in fractionUnit)
      for (var i = 0; i < 2; i++)
        (() {
          final m = l.make(r);
          final s = m.steps[r.nextInt(m.steps.length)];
          final before = [for (final x in m.steps.takeWhile((x) => x != s)) x.done];
          return CheckItem([m.story, ...before, _alone(s.ask)].join(' '), s.answer, pesos: l.pesos);
        })(),
  ],
  'Dinero' => (r) => [
    for (final l in ([...moneyUnit]..shuffle(r)).take(Progress.unitCheckSize))
      (() {
        final m = l.make(r);
        final last = _alone(m.steps.last.ask, money: true);
        return CheckItem('${m.story} $last', m.steps.last.answer, pesos: true);
      })(),
  ],
  _ => null,
};

class UnitCheckScreen extends StatefulWidget {
  final String unit; // the unit's key (Unit.key)
  final int? seed;
  const UnitCheckScreen({super.key, required this.unit, this.seed});

  @override
  State<UnitCheckScreen> createState() => _UnitCheckScreenState();
}

class _UnitCheckScreenState extends State<UnitCheckScreen> {
  late final List<CheckItem> _items = (checkFor(widget.unit)!(Random(widget.seed))..shuffle(Random(widget.seed)))
      .take(Progress.unitCheckSize)
      .toList();
  int _i = 0;
  int _right = 0;
  String _typed = '';
  bool? _wasRight; // after answering: shown until "Siguiente"
  bool _done = false;

  CheckItem get _item => _items[_i];

  @override
  void initState() {
    super.initState();
    _read();
  }

  @override
  void dispose() {
    Speech.instance.stop();
    super.dispose();
  }

  void _read() {
    if (Settings.voice.value) Speech.instance.say(spoken(_item.question));
  }

  void _key(String k) {
    if (_wasRight != null) return;
    setState(() {
      if (k == '⌫') {
        if (_typed.isNotEmpty) _typed = _typed.substring(0, _typed.length - 1);
      } else if (_typed.length < 7) {
        _typed = _typed == '0' ? k : _typed + k;
      }
    });
  }

  void _answer() {
    final ok = int.parse(_typed) == _item.answer;
    HapticFeedback.selectionClick();
    setState(() {
      _wasRight = ok;
      if (ok) _right++;
    });
    if (Settings.voice.value) {
      Speech.instance.say(ok ? tr('¡Bien!', 'Good!') : tr('Casi. Era ${_show(_item.answer)}.', 'Almost. It was ${_show(_item.answer)}.'));
    }
  }

  void _next() {
    if (_i + 1 < _items.length) {
      setState(() {
        _i++;
        _typed = '';
        _wasRight = null;
      });
      _read();
    } else {
      Progress.saveCheck(widget.unit, _right);
      setState(() => _done = true);
      if (Settings.voice.value) {
        Speech.instance.say(tr('Sacaste $_right de ${_items.length}.', 'You got $_right out of ${_items.length}.'));
      }
    }
  }

  String _show(int v) => _item.pesos ? pesos(v.toDouble()) : '$v';

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(tr('Reto: ', 'Challenge: ') + course.firstWhere((u) => u.key == widget.unit, orElse: () => course.first).title),
      actions: [
        if (!_done)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Center(child: Text('${_i + 1} / ${_items.length}', style: const TextStyle(color: Pk.textSoft))),
          ),
        // Penko reads the question, its number and what's typed so far (or the score at the end)
        ReadScreenButton(
          lines: () => [
            tr('Reto: ', 'Challenge: ') + course.firstWhere((u) => u.key == widget.unit, orElse: () => course.first).title,
            if (_done) tr('Sacaste $_right de ${_items.length}.', 'You got $_right out of ${_items.length}.') else ...[
              _item.question,
              ?_item.big,
              if (_typed.isNotEmpty) _show(int.parse(_typed)),
            ],
          ],
        ),
      ],
    ),
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        child: _done ? _summary() : _question(),
      ),
    ),
  );

  Widget _question() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: LinearProgressIndicator(value: _i / _items.length, minHeight: 8),
      ),
      const SizedBox(height: 16),
      Expanded(
        child: ListView(
          children: [
            GestureDetector(
              onTap: _read,
              child: Text(_item.question, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700, height: 1.35)),
            ),
            if (_item.big != null)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Center(child: Text(_item.big!, style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w800, color: Pk.gold))),
              ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                _typed.isEmpty ? (_item.pesos ? '\$ …' : '…') : (_item.pesos ? pesos(double.parse(_typed)) : _typed),
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  color: _wasRight == null ? Pk.text : (_wasRight! ? Pk.rightText : Pk.wrongText),
                ),
              ),
            ),
            if (_wasRight != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: _wasRight! ? Pk.rightSoft : Pk.wrongSoft, borderRadius: BorderRadius.circular(18)),
                  child: Text(
                    _wasRight! ? tr('¡Bien!', 'Good!') : tr('Casi. Era ${_show(_item.answer)}.', 'Almost. It was ${_show(_item.answer)}.'),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _wasRight! ? Pk.rightText : Pk.wrongText),
                  ),
                ),
              ),
          ],
        ),
      ),
      if (_wasRight == null) ...[
        _Pad(onKey: _key),
        const SizedBox(height: 8),
        PkButton(tr('Listo', 'Done'), leading: const Icon(Icons.check, color: Pk.onGold), onPressed: _typed.isEmpty ? null : _answer),
      ] else
        PkButton(_i + 1 < _items.length ? tr('Siguiente', 'Next') : tr('Ver mi resultado', 'See my score'),
            leading: const Icon(Icons.arrow_forward, color: Pk.onGold), onPressed: _next),
    ],
  );

  Widget _summary() => ListView(
    children: [
      const SizedBox(height: 16),
      Center(child: Penko(pose: _right >= _items.length * 0.75 ? PenkoPose.jump : PenkoPose.talk, size: 110)),
      const SizedBox(height: 16),
      Center(child: Text(tr('$_right de ${_items.length}', '$_right of ${_items.length}'), style: const TextStyle(fontSize: 56, fontWeight: FontWeight.w800, color: Pk.gold))),
      const SizedBox(height: 12),
      Text(
        _right == _items.length
            ? tr('¡Todas bien! Esta unidad ya es tuya.', 'All right! This unit is yours now.')
            : _right >= _items.length * 0.75
            ? tr('Muy bien. Las que fallaron se repasan con calma, y listo.', 'Very good. Go over the ones that slipped, calmly, and you are there.')
            : tr('Vas aprendiendo. Repasa las lecciones marcadas en el camino y vuelve a intentarlo cuando quieras.',
                "You're learning. Review the lessons marked on the path and try again whenever you like."),
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 18, height: 1.4, fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 24),
      PkButton(tr('Volver', 'Back'), leading: const Icon(Icons.home, color: Pk.onGold), onPressed: () => Navigator.of(context).pop()),
    ],
  );
}

class _Pad extends StatelessWidget {
  final void Function(String) onKey;
  const _Pad({required this.onKey});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (final row in const [
        ['1', '2', '3', '4', '5', '6'],
        ['7', '8', '9', '0', '00', '⌫'],
      ])
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              for (final k in row)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Material(
                      color: Pk.cardHi,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(color: Pk.rim.withValues(alpha: 0.6)),
                      ),
                      child: InkWell(
                        key: ValueKey('check-$k'),
                        borderRadius: BorderRadius.circular(14),
                        onTap: () {
                          for (final c in k == '00' ? ['0', '0'] : [k]) {
                            onKey(c);
                          }
                        },
                        child: SizedBox(
                          height: 52,
                          child: Center(
                            child: k == '⌫'
                                ? Icon(Icons.backspace_outlined, color: Pk.text, semanticLabel: tr('Borrar', 'Delete'))
                                : Text(k, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Pk.text)),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
    ],
  );
}
