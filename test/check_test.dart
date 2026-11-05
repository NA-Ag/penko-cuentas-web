import 'package:flutter_test/flutter_test.dart';
import 'package:penko_math/ai/check.dart';
import 'package:penko_math/i18n/tr.dart';

void main() {
  const facts = 'Operación: 47 + 28 = 75\nunidades: 7 + 8 = 15. Escribimos el 5 y llevamos 1.\ndecenas: 4 + 2 + 1 = 7.';

  test('a right explanation passes', () {
    expect(checked('Porque 7 + 8 = 15: escribimos el 5 y llevamos 1 a las decenas.', facts: facts, question: '¿Por qué?'),
        isNotNull);
  });

  test('an invented number or a false sum is stopped', () {
    expect(checked('Porque 7 + 8 = 16, y llevamos 1 a las decenas, así de fácil.', facts: facts, question: '¿Por qué?'), isNull);
    expect(checked('Porque 7 + 8 = 15 y 4 + 2 = 7, y luego sumamos todo junto.', facts: facts, question: '¿Por qué?'),
        isNull); // 4 + 2 is 6
  });

  test('money sums with × and ÷, and a forbidden answer', () {
    const money = '20% de \$1,900 = \$380\nPagas \$1,520';
    // 190 isn't in the facts, but it comes out of a true sum of verified numbers, and × 2 leads to a verified 380
    expect(checked('El 10% es 1,900 ÷ 10 = 190, y el 20% es el doble: 190 × 2 = 380.', facts: money,
        question: '¿Por qué?'), isNotNull);
    expect(checked('El 10% es 1,900 ÷ 10 = 190, y luego 190 × 3 = 570, y eso pagas de menos.', facts: money,
        question: '¿Por qué?'), isNull); // 570 isn't verified, nor is the 3 that leads to it
    expect(checked('Casi. Al precio le quitas el descuento y pagas \$1,520 en total.', facts: money, question: 'Me salió 1500',
        forbidden: {1520}), isNull);
  });

  test('order of operations', () {
    expect(sumsAreTrue('2 + 3 × 4 = 14'), isTrue);
    expect(sumsAreTrue('2 + 3 × 4 = 20'), isFalse);
  });

  test('cut off, maths code and numbered steps are stopped', () {
    expect(checked('Porque 7 + 8 = 15: escribimos el 5 y llevamos', facts: facts, question: '¿Por qué?'), isNull);
    expect(checked(r'Primero \$7 \times 8\$ y luego llevamos 1 a las decenas.', facts: facts, question: '¿Por qué?'), isNull);
    expect(checked('Paso 1: 7 + 8 = 15.\nPaso 2: llevamos 1.', facts: facts, question: '¿Por qué?'), isNull);
    expect(checked(r'Sumamos \$7 + 8 = 15\$, escribimos el 5 y llevamos 1 a las decenas.', facts: facts,
        question: '¿Por qué?'), isNull);
  });

  test("Penko's voice: no greeting, nothing patronising", () {
    expect(checked('¡Hola! Porque 7 + 8 = 15 y llevamos 1 a las decenas.', facts: facts, question: '¿Por qué?'), isNull);
    expect(checked('Tranquilo: 7 + 8 = 15, así que llevamos 1 a las decenas.', facts: facts, question: '¿Por qué?'), isNull);
    expect(checked('Porque 7 + 8 = 15: el 5 se queda y llevamos 1 a las decenas. ¡Vas muy bien!', facts: facts,
        question: '¿Por qué?'), isNotNull);
  });

  test('numbers written in words are checked too', () {
    // 47 + 28: there's no 3 anywhere in this problem
    expect(checked('En las unidades sumamos uno más uno y da tres, así que escribimos el tres.', facts: facts,
        question: '¿Por qué?'), isNull);
    expect(checked('En las unidades, siete más ocho son quince: escribimos el 5 y llevamos 1 a las decenas.',
        facts: facts, question: '¿Por qué?'), isNotNull);
  });

  test('words must match what happens', () {
    // 47 + 28 is a sum with a carry, in units and tens only
    expect(checked('En las unidades, 7 + 8 = 15: pedimos prestado 1 a las decenas.', facts: facts, question: '¿Por qué?'),
        isNull);
    expect(checked('En las centenas, 4 + 2 + 1 = 7, así que escribimos el 7.', facts: facts, question: '¿Por qué?'),
        isNull);
    const noCarry = 'Operación: 23 + 14 = 37\nunidades: 3 + 4 = 7.\ndecenas: 2 + 1 = 3.';
    expect(checked('En las unidades 3 + 4 = 7, y llevamos 1 a las decenas.', facts: noCarry, question: '¿Por qué?'),
        isNull);
    const sub = 'Operación: 52 − 27 = 25\nunidades: Pedimos prestado: 12 − 7 = 5.\ndecenas: 4 − 2 = 2.';
    expect(checked('En las unidades 12 − 7 = 5 y llevamos 1 a las decenas.', facts: sub, question: '¿Por qué?'), isNull);
    expect(checked('En las unidades al 2 no le alcanza: pedimos prestado y 12 − 7 = 5.', facts: sub, question: '¿Por qué?'),
        isNotNull);
  });

  test('whole spoken numbers, and "más de 9" is fine', () {
    expect(numbersIn('pagas mil novecientos sesenta pesos'), {1960.0});
    expect(numbersIn('veinte por ciento de mil doscientos'), {20.0, 1200.0});
    expect(checked('Como 7 + 8 = 15 y 15 es más de 9, escribimos el 5 y llevamos 1 a las decenas.', facts: facts,
        question: '¿Por qué?'), isNotNull);
  });

  group('in English', () {
    setUp(() => Tr.english = true);
    tearDown(() => Tr.english = false);
    const money = 'A \$1,900 fridge has a 20% discount, so you save \$380.';

    test('a true reply passes, and "once" is not the Spanish eleven', () {
      expect(checked('Once you find 10%, double it: 1,900 ÷ 10 = 190, and 190 × 2 = 380.', facts: money, question: 'Why?'), isNotNull);
    });
    test('a wrong number spelled out is caught', () {
      expect(checked('The discount here is seventy-five pesos, so you pay less.', facts: money, question: 'Why?'), isNull);
    });
    test('the answer spelled out is caught', () {
      expect(checked('You take off three hundred and eighty from the price.', facts: money, question: 'Why?', forbidden: {380}), isNull);
    });
    test('no borrowing in a sum', () {
      expect(checked('Here we borrow from the next column to finish.', facts: 'Operación: 25 + 17', question: 'Why?'), isNull);
    });
  });
}
