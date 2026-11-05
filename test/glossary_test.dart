import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:penko_math/audio/voice_keys.dart';
import 'package:penko_math/data/settings.dart';
import 'package:penko_math/glossary/term_card.dart';
import 'package:penko_math/glossary/term_text.dart';
import 'package:penko_math/glossary/terms.dart';
import 'package:penko_math/i18n/lang.dart';

/// The ids of the terms found in [text]
List<String> ids(String text) => [for (final m in findTerms(text)) m.term.id];

void main() {
  tearDown(() => Lang.current.value = 'es');

  test('every term has a word, an explanation and an example in Spanish and English, and a picture', () {
    Lang.current.value = 'es';
    final es = terms;
    Lang.current.value = 'en';
    final en = terms;
    expect(es.length, en.length);
    expect(es.length, greaterThanOrEqualTo(40));
    expect({for (final t in es) t.id}.length, es.length, reason: 'ids are unique');
    const colours = 'kwetdyosglGbBrcpmn.';
    for (var i = 0; i < es.length; i++) {
      final s = es[i], e = en[i];
      expect(e.id, s.id);
      for (final t in [s, e]) {
        expect(t.word.trim(), isNotEmpty, reason: t.id);
        expect(t.explain.trim(), isNotEmpty, reason: t.id);
        expect(t.example.trim(), isNotEmpty, reason: t.id);
      }
      expect(e.explain, isNot(s.explain), reason: '${s.id}: the English explanation is a translation');
      expect(e.example, isNot(s.example), reason: '${s.id}: the English example is a translation');
      expect(RegExp(r'[¿¡ñ]').hasMatch('${e.explain} ${e.example}'), isFalse, reason: '${s.id}: Spanish left in English');
      // A 32 × 32 picture, in the pictogram colours, not empty
      expect(s.picture.length, 32, reason: s.id);
      for (final row in s.picture) {
        expect(row.length, 32, reason: s.id);
        expect(row.split('').every(colours.contains), isTrue, reason: '${s.id}: $row');
      }
      expect(s.picture.join().replaceAll('.', '').length, greaterThan(20), reason: s.id);
    }
  });

  test('the matcher finds IVA and other terms as whole words, longest first, accents and case aside', () {
    Lang.current.value = 'es';
    final line = 'Al interés le cobran 16% de IVA. ¿Cuánto es el IVA?';
    final found = findTerms(line);
    final iva = found.firstWhere((m) => m.term.id == 'iva');
    expect(line.substring(iva.start, iva.end), 'IVA');
    expect(found.where((m) => m.term.id == 'iva').length, 1, reason: 'each term once');
    expect(ids(line), ['interest', 'iva']);
    expect(ids('Pagas 16% de iva'), ['iva']);
    expect(ids('Con la tarjeta de crédito pagas después'), ['card']);
    expect(ids('Pide un credito'), ['credit']);
    expect(ids('El interés compuesto crece'), ['compound']);
    expect(ids('A 6 meses sin intereses'), ['msi']);
    expect(ids('Puedes contestarlo otra vez para ver si cambió.'), isEmpty);
    expect(ids('Tu cambio es \$5'), ['change']);
    expect(ids('Los ivas y la divisa'), isEmpty);
    Lang.current.value = 'en';
    expect(ids('From each payment, the interest and its IVA are covered first.'), ['interest', 'iva']);
    expect(ids('Turn on the ones you want.'), isEmpty);
    expect(ids('In the ones column: 7 plus 8.'), ['ones', 'column']);
  });

  test('voice keys are unique, plain, and cover every term', () {
    final lines = voiceLines();
    for (final t in terms) {
      expect(lines[t.wordKey], t.word);
      expect(lines[t.explainKey], t.explain);
      expect(lines[t.exampleKey], t.example);
    }
    expect(lines.keys.every(RegExp(r'^[a-z0-9_.-]+$').hasMatch), isTrue);
    expect(lines.values.every((v) => v.trim().isNotEmpty), isTrue);
    expect(lines.keys.where((k) => k.startsWith('lesson.')), isNotEmpty);
  });

  testWidgets('a tappable term opens its card', (tester) async {
    Settings.voice.value = false; // no text-to-speech in tests
    Lang.current.value = 'es';
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: TermText('Al interés le cobran IVA.'))));
    expect(find.byType(TermPicture), findsNWidgets(2));
    expect(find.textContaining('le cobran IVA'), findsOneWidget);
    await tester.tap(find.byType(TermPicture).last);
    await tester.pumpAndSettle();
    expect(find.text('Entendido'), findsOneWidget);
    expect(find.textContaining('Por lo general es el 16%'), findsOneWidget);
    await tester.ensureVisible(find.text('Entendido'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Entendido'));
    await tester.pumpAndSettle();
    expect(find.text('Entendido'), findsNothing);
  });
}
