// times_lessons.dart — the times tables and division (3.º–4.º de primaria), as short everyday stories worked in steps,
// plus "la casita" for long division. Multiplication is shown as equal groups and division as sharing equally, the
// way the SEP books introduce them. Every answer is worked out here in code.
import 'dart:math';

import '../i18n/tr.dart';
import '../lessons/work.dart';

T _pick<T>(Random r, List<T> xs) => xs[r.nextInt(xs.length)];

/// Things that come in equal groups: the group (plural, "un/una" + singular) and the things, with "cuántos/cuántas"
const _groupsEs = [
  ('bolsas', 'una bolsa', 'cada una', 'dulces', 'Cuántos'),
  ('cajas', 'una caja', 'cada una', 'lápices', 'Cuántos'),
  ('mesas', 'una mesa', 'cada una', 'sillas', 'Cuántas'),
  ('paquetes', 'un paquete', 'cada uno', 'galletas', 'Cuántas'),
  ('filas', 'una fila', 'cada una', 'macetas', 'Cuántas'),
];

/// The same groups in English, in the same order: the group, "one more …", the things ("each" and "how many" need no
/// agreement)
const _groupsEn = [
  ('bags', 'one more bag', 'in each', 'candies', 'How many'),
  ('boxes', 'one more box', 'in each', 'pencils', 'How many'),
  ('tables', 'one more table', 'at each', 'chairs', 'How many'),
  ('packets', 'one more packet', 'in each', 'cookies', 'How many'),
  ('rows', 'one more row', 'in each', 'flowerpots', 'How many'),
];

WorkProblem _tables(Random r) {
  final groups = 2 + r.nextInt(8), each = 2 + r.nextInt(8);
  final k = r.nextInt(_groupsEs.length);
  final (group, one, eachOne, thing, howMany) = trOf(_groupsEs, _groupsEn)[k];
  final total = groups * each;
  final adds = List.filled(groups, '$each').join(' + ');
  return WorkProblem(
    tr('Hay $groups $group con $each $thing $eachOne.', 'There are $groups $group with $each $thing $eachOne.'),
    [
      WorkStep(tr('¿$howMany $thing hay en total?', '$howMany $thing are there in total?'), total,
          [tr('Son $groups grupos de $each. Multiplica: $groups × $each.', 'There are $groups groups of $each. Multiply: $groups × $each.'), groups <= 5 ? '$adds = $total.' : '$groups × $each = $total.'],
          '$groups × $each = $total $thing'),
      WorkStep(tr('Si llega $one más, ¿${howMany.toLowerCase()} $thing hay?', 'If $one arrives, how many $thing are there?'), total + each,
          [tr('Es un grupo más de $each: a $total súmale $each.', "It's one more group of $each: add $each to $total."), '$total + $each = ${total + each}.'],
          '${groups + 1} × $each = ${total + each} $thing'),
    ],
    tr('Multiplicar es sumar grupos iguales. Por eso $groups × $each es lo mismo que sumar $each, $groups veces.', "Multiplying is adding equal groups. That's why $groups × $each is the same as adding $each, $groups times."),
  );
}

WorkProblem _share(Random r) {
  final people = 2 + r.nextInt(8), each = 2 + r.nextInt(8);
  final total = people * each;
  final thing = _pick(r, trOf(['galletas', 'canicas', 'estampas', 'dulces'], ['cookies', 'marbles', 'stickers', 'candies']));
  return WorkProblem(
    tr('Tienes $total $thing y las repartes entre $people amigos, a todos por igual.', 'You have $total $thing and share them equally among $people friends.'),
    [
      WorkStep(tr('¿Cuántas le tocan a cada uno?', 'How many does each one get?'), each,
          [tr('Busca en la tabla del $people: ¿qué número por $people da $total?', 'Look in the $people times table: what number times $people makes $total?'), '$people × $each = $total.'],
          '$total ÷ $people = $each'),
    ],
    tr('Dividir es repartir en partes iguales. Para comprobar, multiplica: $each × $people = $total.', 'Dividing is sharing into equal parts. To check, multiply: $each × $people = $total.'),
  );
}

WorkProblem _shareLeft(Random r) {
  final people = 3 + r.nextInt(6), each = 2 + r.nextInt(8), left = 1 + r.nextInt(people - 1);
  final total = people * each + left;
  return WorkProblem(
    tr('Hay $total canicas para repartir entre $people niños, a todos por igual.', 'There are $total marbles to share equally among $people children.'),
    [
      WorkStep(tr('¿Cuántas le tocan a cada uno?', 'How many does each one get?'), each,
          [tr('Busca el número más grande que, por $people, no se pase de $total.',
                  'Find the biggest number that, times $people, does not go over $total.'),
           '$people × $each = ${people * each}. ${tr('Con una más ya te pasas:', 'One more and you go over:')} '
               '$people × ${each + 1} = ${people * (each + 1)}.'],
          tr('A cada uno le tocan $each', 'Each one gets $each')),
      WorkStep(tr('¿Cuántas sobran?', 'How many are left over?'), left,
          [tr('Ya repartiste $people × $each = ${people * each}. ¿Cuánto falta para $total?', 'You have shared out $people × $each = ${people * each}. How many more to reach $total?'), '$total − ${people * each} = $left.'],
          tr('Sobran $left', 'Left over: $left')),
    ],
    tr('Lo que sobra se llama residuo, y siempre es menor que el número entre el que divides.', 'What is left over is called the remainder, and it is always smaller than the number you divide by.'),
  );
}

/// Long division in "la casita": two steps per stage (how many times it goes in, what's left)
WorkProblem _casita(Random r, int digits) {
  final lo = pow(10, digits - 1).toInt();
  late LongDivision d;
  do {
    d = LongDivision(lo + r.nextInt(9 * lo), 2 + r.nextInt(8));
  } while (d.stages.length < digits - 1 || d.quotient < 10);
  return casitaProblem(d);
}

WorkProblem casitaProblem(LongDivision d) {
  final steps = <WorkStep>[];
  for (final (i, s) in d.stages.indexed) {
    final intro = i > 0
        ? tr('Bajamos el ${d.digits[s.position]}: ahora tenemos ${s.number}. ',
            'We bring down the ${d.digits[s.position]}: now we have ${s.number}. ')
        : s.position > 0
            ? tr('Empezamos con ${s.number}, porque el ${d.digits.substring(0, s.position)} no alcanza para ${d.divisor}. ',
                'We start with ${s.number}, because ${d.digits.substring(0, s.position)} is too small for ${d.divisor}. ')
            : tr('Empezamos con el ${s.number}. ', 'We start with ${s.number}. ');
    steps.add(WorkStep(tr('$intro¿Cuántas veces cabe el ${d.divisor} en ${s.number}?',
            '${intro}How many times does ${d.divisor} go into ${s.number}?'), s.quotient,
        [d.divisor < 10
             ? tr('Busca en la tabla del ${d.divisor} el número más grande que no se pase de ${s.number}.',
                 'In the ${d.divisor} times table, find the biggest number that does not go over ${s.number}.')
             : tr('Prueba: ¿${d.divisor} por cuánto se acerca a ${s.number} sin pasarse? Fíjate en las decenas: '
                 '${s.number ~/ 10} entre ${d.divisor ~/ 10} da una idea.',
                 'Try it: ${d.divisor} times what gets close to ${s.number} without going over? Look at the tens: '
                 '${s.number ~/ 10} divided by ${d.divisor ~/ 10} gives you an idea.'),
         '${d.divisor} × ${s.quotient} = ${d.divisor * s.quotient}${s.quotient < 9 ? tr(', y ${d.divisor} × ${s.quotient + 1} = ${d.divisor * (s.quotient + 1)} ya se pasa', ', and ${d.divisor} × ${s.quotient + 1} = ${d.divisor * (s.quotient + 1)} is already too much') : ''}.'],
        tr('${s.number} ÷ ${d.divisor}: cabe ${s.quotient}', '${s.number} ÷ ${d.divisor}: goes in ${s.quotient} times')));
    steps.add(WorkStep('${d.divisor} × ${s.quotient} = ${d.divisor * s.quotient}. '
            '${tr('¿Cuánto sobra de ${s.number}?', 'How much is left over from ${s.number}?')}', s.rest,
        ['${tr('Resta:', 'Subtract:')} ${s.number} − ${d.divisor * s.quotient}.', '${s.number} − ${d.divisor * s.quotient} = ${s.rest}.'],
        tr('Sobra ${s.rest}', 'Left over: ${s.rest}')));
  }
  final rest = d.remainder == 0 ? tr('No sobra nada.', 'Nothing is left over.') : tr('Sobra ${d.remainder}.', '${d.remainder} is left over.');
  return WorkProblem(
    tr('Vamos a dividir ${d.dividend} ÷ ${d.divisor} en la casita.', "Let's divide ${d.dividend} ÷ ${d.divisor} with long division."),
    steps,
    '${d.dividend} ÷ ${d.divisor} = ${d.quotient}. $rest ${tr('Para comprobar:', 'To check:')} ${d.quotient} × ${d.divisor}'
        '${d.remainder > 0 ? ' + ${d.remainder}' : ''} = ${d.dividend}.',
    division: d,
  );
}

/// Long division by a two-digit number (3.º–4.º de secundaria starts here; 5.º–6.º de primaria in the SEP plan)
WorkProblem _casitaTwo(Random r) {
  late LongDivision d;
  do {
    d = LongDivision(100 + r.nextInt(900), 11 + r.nextInt(15)); // ÷ 11–25
  } while (d.quotient < 10);
  return casitaProblem(d);
}

/// Multiplying by a two-digit number the way it's written: the units row, the tens row (with its 0), then the sum
WorkProblem _timesTwo(Random r) {
  final a = 12 + r.nextInt(88), b = 12 + r.nextInt(88);
  final units = b % 10, tens = b ~/ 10;
  if (units == 0) return _timesTwo(r);
  final first = a * units, second = a * tens * 10;
  return WorkProblem(
    tr('Vamos a multiplicar $a × $b. Se hace en dos renglones: primero por las unidades del $b, luego por sus decenas.', "Let's multiply $a × $b. It's done in two rows: first by the ones of $b, then by its tens."),
    [
      WorkStep(tr('Primer renglón: ¿cuánto es $a × $units?', 'First row: what is $a × $units?'), first,
          [tr('Multiplica $a por el $units, como en columna: unidades y luego decenas.', 'Multiply $a by $units, as in a column: ones first, then tens.'), '$a × $units = $first.'], '$a × $units = $first'),
      WorkStep(tr('Segundo renglón: el $tens del $b vale $tens decenas, o sea ${tens * 10}. ¿Cuánto es $a × ${tens * 10}?', 'Second row: the $tens in $b is worth $tens ${tens == 1 ? 'ten' : 'tens'}, that is ${tens * 10}. What is $a × ${tens * 10}?'), second,
          [tr('Multiplica $a × $tens y ponle un 0 al final (porque son decenas).',
              'Multiply $a × $tens and put a 0 on the end (because they are tens).'),
           tr('$a × $tens = ${a * tens}, con el 0: $second.', '$a × $tens = ${a * tens}, with the 0: $second.')],
          '$a × ${tens * 10} = $second'),
      WorkStep(tr('Ahora suma los dos renglones. ¿Cuánto es $a × $b?', 'Now add the two rows. What is $a × $b?'), first + second,
          [tr('Suma $first + $second.', 'Add $first + $second.'), '$first + $second = ${first + second}.'], '$first + $second = ${first + second}'),
    ],
    '$a × $b = ${first + second}. ${tr('Por eso en el segundo renglón dejamos un lugar vacío (o un 0): son decenas.', "That's why in the second row we leave an empty space (or a 0): they are tens.")}',
  );
}

/// Unit 2 starts with the tables; the column lessons (lessons.dart) follow
WorkLesson get tablesLesson => WorkLesson('u2-l1', tr('Las tablas', 'The times tables'), [
  tr('Multiplicar es una forma rápida de sumar grupos iguales.', 'Multiplying is a quick way to add equal groups.'),
  tr('Si hay 3 bolsas con 4 dulces cada una, son 4 + 4 + 4 = 12. Eso es 3 × 4 = 12.', "If there are 3 bags with 4 candies in each, that's 4 + 4 + 4 = 12. That is 3 × 4 = 12."),
], _tables, count: 5);

List<WorkLesson> get unit3Division => [
  WorkLesson('u3-l1', tr('Repartir', 'Sharing'), [
    tr('Dividir es repartir en partes iguales.', 'Dividing is sharing into equal parts.'),
    tr('Si repartes 12 dulces entre 3 amigos, a cada uno le tocan 4, porque 3 × 4 = 12.', 'If you share 12 candies among 3 friends, each one gets 4, because 3 × 4 = 12.'),
  ], _share, count: 5),
  WorkLesson('u3-l2', tr('Cuando sobra', 'When some are left over'), [
    tr('A veces no se puede repartir todo por igual: algo sobra.', "Sometimes you can't share everything equally: some are left over."),
    tr('Lo que sobra se llama residuo.', 'What is left over is called the remainder.'),
  ], _shareLeft, count: 4),
  WorkLesson('u3-l3', tr('La casita', 'Long division'), [
    tr('Para dividir números grandes usamos la casita.', 'To divide big numbers we use long division. In Mexico it\'s called "la casita" (the little house) because of its shape.'),
    tr('Vamos de izquierda a derecha: vemos cuántas veces cabe el divisor, apuntamos lo que sobra, y bajamos el '
        'siguiente número.',
        'We go from left to right: we see how many times the divisor goes in, write down what is left over, and bring '
        'down the next digit.'),
  ], (r) => _casita(r, 2)),
  WorkLesson('u3-l4', tr('La casita con centenas', 'Long division with hundreds'), [
    tr('Ahora con tres cifras. Es igual: cabe, sobra, bajamos.', 'Now with three digits. Same steps: how many times it goes in, what is left over, bring down.'),
  ], (r) => _casita(r, 3)),
  WorkLesson('u3-l5', tr('La casita con dos cifras', 'Long division by two digits'), [
    tr('Ahora dividimos entre un número de dos cifras. Es igual: cabe, sobra, bajamos.', 'Now we divide by a two-digit number. Same steps: how many times it goes in, what is left over, bring down.'),
    tr('Para saber cuántas veces cabe, ayuda fijarse en las decenas y luego comprobar multiplicando.', 'To find how many times it goes in, look at the tens first, then check by multiplying.'),
  ], _casitaTwo),
];

/// Multiplying by two digits comes after the column lessons (lessons.dart)
WorkLesson get timesTwoLesson => WorkLesson('u2-l5', tr('Multiplicar por dos cifras', 'Multiplying by two digits'), [
  tr('Para multiplicar por un número de dos cifras, hacemos dos multiplicaciones y las sumamos.', 'To multiply by a two-digit number, we do two multiplications and add them.'),
  tr('Primero por las unidades; luego por las decenas, que valen diez veces más.', 'First by the ones; then by the tens, which are worth ten times more.'),
], _timesTwo);
