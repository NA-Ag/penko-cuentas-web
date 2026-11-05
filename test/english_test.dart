import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:penko_math/abacus/abacus_lessons.dart';
import 'package:penko_math/ai/facts.dart';
import 'package:penko_math/i18n/lang.dart';
import 'package:penko_math/math/column.dart';
import 'package:penko_math/math/explain.dart';
import 'package:penko_math/math/fraction_lessons.dart';
import 'package:penko_math/math/lessons.dart';
import 'package:penko_math/math/times_lessons.dart';
import 'package:penko_math/money/money.dart';
import 'package:penko_math/money/money_lessons.dart';
import 'package:penko_math/money/wellbeing.dart';
import 'package:penko_math/screens/course.dart';
import 'package:penko_math/screens/unit_check_screen.dart';

/// Spanish left in an English line: accents, ¿ ¡, or common Spanish words (Mexican names and terms kept on purpose
/// are taken out first)
final _spanish = RegExp(r'[¿¡áéíóúñ]|\b(el|los|las|de|del|que|por|cuánto|entre|pagas|tienes)\b', caseSensitive: false);
String _withoutKept(String s) => s
    .replaceAll(RegExp(r'Doña|México|meses sin intereses|la casita|pan dulce'), '')
    .replaceAll('"', '');

void main() {
  setUp(() => Lang.current.value = 'en');
  tearDown(() => Lang.current.value = 'es');

  test('column lines in English, with the same numbers', () {
    final p = ColumnProblem(47, 28, Op.add);
    final units = p.writable[0], tens = p.writable[1];
    expect(askStep(p, units), 'In the ones column: 7 plus 8. What does it make?');
    expect(doneStep(p, units), "That's it! 7 + 8 = 15. We write the 5 and carry the 1.");
    expect(askStep(p, tens), 'In the tens column: 4 plus 2 plus the 1 we carried. What does it make?');
    expect(slipLine(p, tens, Slip.forgotCarry), 'Almost. Did you remember the 1 we carried?');
    expect(spoken('7 + 8 = 15'), '7 plus 8 equals 15');
    expect(spoken(r'You pay $1,350'), 'You pay 1,350 pesos');
    final sub = ColumnProblem(52, 27, Op.sub);
    expect(askStep(sub, sub.writable[0]),
        'In the ones column: 2 is not enough to take away 7: we borrow 1 and it becomes 12. What is 12 minus 7?');
  });

  test("the tutor's facts stay in Spanish, the language it was trained on", () {
    final p = ColumnProblem(47, 28, Op.add);
    expect(columnFacts(p), startsWith('Operación: 47 + 28 = 75\nunidades: 7 + 8 = 15. Escribimos el 5 y llevamos 1.'));
    expect(Lang.spanish(() => whyQuestion(p, p.writable[1])), contains('decenas'));
    expect(whyQuestion(p, p.writable[1]), 'Why do I add what we carried in the tens column of 47 + 28?');
  });

  test('every lesson, made in English, has no Spanish left and keeps its answers', () {
    final r = Random(1);
    final lines = <String>[
      for (final l in [...unit1, ...unit2Columns]) ...[l.title, ...l.intro],
      for (final l in abacusUnit(r)) l.title,
      for (final u in course) ...[u.title, u.about],
      for (final i in wellbeingItems) ...[i.question, ...i.answers],
    ];
    for (final l in [tablesLesson, ...unit3Division, timesTwoLesson, ...fractionUnit, ...moneyUnit]) {
      lines.addAll([l.title, ...l.intro]);
      for (var n = 0; n < 30; n++) {
        final m = l.make(r);
        lines.addAll([m.story, m.lesson]);
        for (final s in m.steps) {
          lines.addAll([s.ask, s.done, ...s.hints]);
          if (l.pesos) {
            expect(s.hints.last.contains('${s.answer}') || s.hints.last.contains(pesos(s.answer.toDouble())), isTrue,
                reason: '${l.id}: the last hint gives the answer: ${s.hints.last}');
          }
        }
      }
    }
    for (final u in course) {
      for (final item in checkFor(u.key)?.call(r) ?? const <CheckItem>[]) {
        lines.add(item.question);
      }
    }
    for (final line in lines) {
      expect(_spanish.hasMatch(_withoutKept(line)), isFalse, reason: line);
    }
  });
}
