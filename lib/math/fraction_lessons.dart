// fraction_lessons.dart — the bridge from whole numbers to money: halves and quarters, a fraction of an amount, pesos
// and centavos, and percentages, each worked with division and multiplication the student already knows (4.º–6.º de
// primaria). The money lessons build on these. Every answer is worked out here; numbers are picked to come out whole.
import 'dart:math';

import '../i18n/tr.dart';
import '../lessons/work.dart';
import '../money/money.dart';

T _pick<T>(Random r, List<T> xs) => xs[r.nextInt(xs.length)];

WorkProblem _halves(Random r) {
  final n = (2 + r.nextInt(9)) * 4; // 8–40, so a half and a quarter come out whole
  final thing = _pick(r, trOf(['galletas', 'canicas', 'estampas', 'fresas'], ['cookies', 'marbles', 'stickers', 'strawberries']));
  return WorkProblem(
    tr('Tienes $n $thing.', 'You have $n $thing.'),
    [
      WorkStep(tr('¿Cuánto es la mitad de $n?', 'What is half of $n?'), n ~/ 2, [tr('La mitad es partir en 2 partes iguales: divide entre 2.', 'Half means splitting into 2 equal parts: divide by 2.'), '$n ÷ 2 = ${n ~/ 2}.'],
          tr('La mitad de $n es ${n ~/ 2}', 'Half of $n is ${n ~/ 2}')),
      WorkStep(tr('¿Y la cuarta parte de $n?', 'And a quarter of $n?'), n ~/ 4,
          [tr('La cuarta parte es partir en 4 partes iguales: divide entre 4.', 'A quarter means splitting into 4 equal parts: divide by 4.'), tr('$n ÷ 4 = ${n ~/ 4}. También es la mitad de la mitad.', "$n ÷ 4 = ${n ~/ 4}. It's also half of a half.")],
          tr('La cuarta parte de $n es ${n ~/ 4}', 'A quarter of $n is ${n ~/ 4}')),
    ],
    tr('Un medio es dividir entre 2 y un cuarto es dividir entre 4. Un cuarto es la mitad de la mitad.', 'A half is dividing by 2 and a quarter is dividing by 4. A quarter is half of a half.'),
  );
}

WorkProblem _fractionOf(Random r) {
  final den = _pick<int>(r, [3, 4, 5]);
  final num = 2 + r.nextInt(den - 1 > 2 ? den - 2 : 1); // 2/3, 2/4–3/4, 2/5–4/5
  final part = 2 + r.nextInt(9);
  final total = den * part;
  final word = trOf({3: 'tercios', 4: 'cuartos', 5: 'quintos'}, {3: 'thirds', 4: 'quarters', 5: 'fifths'})[den]!;
  return WorkProblem(
    tr('Una pizza de $total pedacitos se reparte en $den partes iguales. Te tocan $num de esas partes: $num/$den de la pizza.', 'A pizza with $total slices is split into $den equal parts. You get $num of those parts: $num/$den of the pizza.'),
    [
      WorkStep(tr('¿Cuántos pedacitos tiene cada parte?', 'How many slices are in each part?'), part, [tr('Divide los $total pedacitos en $den partes iguales.', 'Divide the $total slices into $den equal parts.'), '$total ÷ $den = $part.'],
          tr('Una parte: $total ÷ $den = $part', 'One part: $total ÷ $den = $part')),
      WorkStep(tr('Entonces, ¿cuántos pedacitos te tocan con $num partes?', 'So, how many slices do you get with $num parts?'), num * part,
          [tr('Son $num partes de $part pedacitos cada una.', "That's $num parts of $part slices each."), '$part × $num = ${num * part}.'], tr('$num/$den de $total = ${num * part}', '$num/$den of $total = ${num * part}')),
    ],
    tr('Para sacar $num $word de algo: divide entre $den y multiplica por $num.', 'To find $num $word of something: divide by $den and multiply by $num.'),
  );
}

WorkProblem _centavos(Random r) {
  // Two prices with 50 centavos, so the total is whole pesos
  final a = 5 + r.nextInt(20), b = 5 + r.nextInt(20);
  final total = a + b + 1; // $a.50 + $b.50
  final paid = total <= 40 ? 50 : 100;
  final (x, y) = _pick(r, trOf([('un pan dulce', 'un jugo'), ('un lápiz', 'una goma'), ('unas papas', 'un refresco')],
      [('a sweet bread', 'a juice'), ('a pencil', 'an eraser'), ('a bag of chips', 'a soda')]));
  return WorkProblem(
    tr('Compras $x de ${pesos(a + 0.5)} y $y de ${pesos(b + 0.5)}. Pagas con un billete de ${pesos(paid.toDouble())}.', 'You buy $x for ${pesos(a + 0.5)} and $y for ${pesos(b + 0.5)}. You pay with a ${pesos(paid.toDouble())} bill.'),
    [
      WorkStep(tr('¿Cuánto pagas por las dos cosas?', 'How much do you pay for the two things?'), total,
          [tr('Suma los pesos y luego los centavos: 50 centavos + 50 centavos = 1 peso.',
               'Add the pesos, then the centavos: 50 centavos + 50 centavos = 1 peso.'),
           tr('$a + $b = ${a + b}, más el peso de los centavos: ${a + b} + 1 = $total.',
               '$a + $b = ${a + b}, plus the peso from the centavos: ${a + b} + 1 = $total.')],
          '${pesos(a + 0.5)} + ${pesos(b + 0.5)} = ${pesos(total.toDouble())}'),
      WorkStep(tr('¿Cuánto te dan de cambio?', 'How much change do you get?'), paid - total,
          [tr('Al billete réstale lo que cuesta.', 'Take away what it costs from the bill.'), '$paid − $total = ${paid - total}.'], tr('Cambio: ${pesos((paid - total).toDouble())}', 'Change: ${pesos((paid - total).toDouble())}')),
    ],
    tr('Los centavos se suman aparte: 100 centavos hacen 1 peso. Siempre revisa tu cambio.', 'Centavos are added separately: 100 centavos make 1 peso. Always check your change.'),
  );
}

WorkProblem _percent(Random r) {
  final n = (2 + r.nextInt(18)) * 100; // $200–$1,900
  return WorkProblem(
    tr('Algo cuesta ${pesos(n.toDouble())}. Vamos a sacar algunos porcentajes.', "Something costs ${pesos(n.toDouble())}. Let's work out some percentages."),
    [
      WorkStep(tr('¿Cuánto es el 10%?', 'What is 10%?'), n ~/ 10, [tr('Porcentaje quiere decir "de cada 100". El 10% es dividir entre 10.', 'Percent means "out of every 100". 10% is dividing by 10.'), '$n ÷ 10 = ${n ~/ 10}.'],
          tr('10% de ${pesos(n.toDouble())} = ${pesos(n / 10)}', '10% of ${pesos(n.toDouble())} = ${pesos(n / 10)}')),
      WorkStep(tr('¿Cuánto es el 50%?', 'What is 50%?'), n ~/ 2, [tr('El 50% es la mitad: divide entre 2.', '50% is half: divide by 2.'), '$n ÷ 2 = ${n ~/ 2}.'],
          tr('50% de ${pesos(n.toDouble())} = ${pesos(n / 2)}', '50% of ${pesos(n.toDouble())} = ${pesos(n / 2)}')),
      WorkStep(tr('¿Y el 25%?', 'And 25%?'), n ~/ 4, [tr('El 25% es la cuarta parte: divide entre 4. También es la mitad del 50%.', "25% is a quarter: divide by 4. It's also half of 50%."), '$n ÷ 4 = ${n ~/ 4}.'],
          tr('25% de ${pesos(n.toDouble())} = ${pesos(n / 4)}', '25% of ${pesos(n.toDouble())} = ${pesos(n / 4)}')),
    ],
    tr('El 10% es dividir entre 10, el 50% es la mitad y el 25% es la cuarta parte. Con eso sacas casi todos los descuentos.', '10% is dividing by 10, 50% is half and 25% is a quarter. With that you can work out almost any discount.'),
  );
}

List<WorkLesson> get fractionUnit => [
  WorkLesson('u4-l1', tr('Mitades y cuartos', 'Halves and quarters'), [
    tr('Una fracción es una parte de algo que se reparte en partes iguales.', 'A fraction is a part of something that is split into equal parts.'),
    tr('La mitad es 1 de 2 partes iguales. La cuarta parte es 1 de 4.', 'A half is 1 of 2 equal parts. A quarter is 1 of 4.'),
  ], _halves, count: 4),
  WorkLesson('u4-l2', tr('Fracciones de una cantidad', 'Fractions of an amount'), [
    tr('Para sacar 3/4 de algo, primero divides entre 4 para saber cuánto es un cuarto, y luego multiplicas por 3.', 'To find 3/4 of something, first divide by 4 to know how much a quarter is, then multiply by 3.'),
  ], _fractionOf, count: 4),
  WorkLesson('u4-l3', tr('Pesos y centavos', 'Pesos and centavos'), [
    tr('Los precios a veces tienen centavos: \$7.50 son 7 pesos con 50 centavos.',
        'Prices sometimes have centavos: \$7.50 is 7 pesos and 50 centavos. (The peso is Mexico\'s money; 100 centavos make 1 peso, like cents in a dollar.)'),
    tr('Cien centavos hacen un peso.', 'A hundred centavos make one peso.'),
  ], _centavos, count: 4, pesos: true),
  WorkLesson('u4-l4', tr('Porcentajes', 'Percentages'), [
    tr('Porcentaje quiere decir "de cada 100". El 10% de 300 son 30, porque de cada 100 tomas 10.', 'Percent means "out of every 100". 10% of 300 is 30, because out of every 100 you take 10.'),
  ], _percent, count: 3, pesos: true),
];
