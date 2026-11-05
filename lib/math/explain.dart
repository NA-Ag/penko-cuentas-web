// explain.dart — what Penko says while working a column problem: written lines in Mexican Spanish (and in English),
// built from the engine's plan. These are always right; the model may later say them in other words, never instead of
// them.
import '../i18n/tr.dart';
import 'column.dart';

/// Penko's line for working out a column, before the student writes its digit. [guided]: says the whole sum to do;
/// otherwise only which column is next (the student works it out)
String askStep(ColumnProblem p, ColumnStep s, {bool guided = true}) {
  final where = tr('En las ${s.placeName}', 'In the ${s.placeName} column');
  if (!guided) return tr('$where, ¿qué número va?', '$where, what number goes there?');
  if (p.op == Op.mul) {
    if (_pastTop(p, s)) {
      return tr('$where: ya no hay más números arriba. Bajamos el ${s.carryIn} que llevamos. ¿Qué número escribes?',
          '$where: there are no more digits on top. We bring down the ${s.carryIn} we carried. What number do you write?');
    }
    final carry = s.carryIn > 0 ? tr(' y le sumamos el ${s.carryIn} que llevamos', ', and we add the ${s.carryIn} we carried') : '';
    return tr('$where: ${s.top} por ${s.bottom}$carry. ¿Cuánto da?', '$where: ${s.top} times ${s.bottom}$carry. What does it make?');
  }
  if (p.op == Op.add) {
    final carry = s.carryIn > 0 ? tr(' más el 1 que llevamos', ' plus the 1 we carried') : '';
    return tr('$where: ${s.top} más ${s.bottom}$carry. ¿Cuánto da?', '$where: ${s.top} plus ${s.bottom}$carry. What does it make?');
  }
  if (s.top == 0 && s.carryIn > 0) {
    return tr('$where. ${zeroLends(s)} ¿Cuánto es 9 menos ${s.bottom}?', '$where. ${zeroLends(s)} What is 9 minus ${s.bottom}?');
  }
  final have = s.top - s.carryIn;
  final lent = s.carryIn > 0 ? tr('el ${s.top} prestó 1, ahora es $have. ', 'the ${s.top} lent 1, so now it is $have. ') : '';
  if (s.borrows) {
    final a = lent.isEmpty ? 'a' : 'A';
    return tr(
      '$where: $lent$a $have no le alcanza para quitarle ${s.bottom}: pedimos 1 prestado y se vuelve '
          '${have + 10}. ¿Cuánto es ${have + 10} menos ${s.bottom}?',
      '$where: $lent$have is not enough to take away ${s.bottom}: we borrow 1 and it becomes ${have + 10}. '
          'What is ${have + 10} minus ${s.bottom}?',
    );
  }
  return tr('$where: $lent$have menos ${s.bottom}. ¿Cuánto da?', '$where: $lent$have minus ${s.bottom}. What does it make?');
}

/// Penko's line after a right digit
String doneStep(ColumnProblem p, ColumnStep s) {
  final cheer = tr('¡Eso!', "That's it!");
  if (p.op == Op.mul) {
    if (_pastTop(p, s)) return tr('¡Eso! Bajamos el ${s.value}.', "That's it! We bring down the ${s.value}.");
    final sum = s.carryIn > 0
        ? tr('${s.top} × ${s.bottom} = ${s.top * s.bottom}, más ${s.carryIn} = ${s.value}',
            '${s.top} × ${s.bottom} = ${s.top * s.bottom}, plus ${s.carryIn} = ${s.value}')
        : '${s.top} × ${s.bottom} = ${s.value}';
    if (s.carryOut > 0 && _hasNext(p, s)) {
      return tr('¡Eso! $sum. Escribimos el ${s.digit} y llevamos ${s.carryOut}.',
          "That's it! $sum. We write the ${s.digit} and carry the ${s.carryOut}.");
    }
    return '$cheer $sum.';
  }
  if (p.op == Op.add) {
    final sum = s.carryIn > 0 ? '${s.top} + ${s.bottom} + 1 = ${s.value}' : '${s.top} + ${s.bottom} = ${s.value}';
    if (s.carryOut > 0 && _hasNext(p, s)) {
      return tr('¡Eso! $sum. Escribimos el ${s.digit} y llevamos 1.', "That's it! $sum. We write the ${s.digit} and carry the 1.");
    }
    return '$cheer $sum.';
  }
  final have = s.top - s.carryIn;
  final good = tr('¡Muy bien!', 'Well done!');
  if (s.top == 0 && s.carryIn > 0) return '$good 9 − ${s.bottom} = ${s.value}.';
  if (s.borrows) {
    return '${tr('¡Muy bien! Pedimos prestado:', 'Well done! We borrowed:')} ${have + 10} − ${s.bottom} = ${s.value}.';
  }
  return '$good $have − ${s.bottom} = ${s.value}.';
}

bool _hasNext(ColumnProblem p, ColumnStep s) => s.place + 1 < p.columns;

/// Multiplication: a column past the top number's digits, where only the carry comes down
bool _pastTop(ColumnProblem p, ColumnStep s) => s.place >= '${p.a}'.length;

/// Gentle words after a wrong digit, naming the likely slip
String slipLine(ColumnProblem p, ColumnStep s, Slip slip) => switch (slip) {
  Slip.forgotCarry => tr('Casi. ¿Te acordaste del ${s.carryIn} que llevamos?', 'Almost. Did you remember the ${s.carryIn} we carried?'),
  Slip.wroteTens => tr('Casi. Da ${s.value}: aquí va el ${s.digit} y el ${s.carryOut} se lleva a la columna de al lado.',
      'Almost. It makes ${s.value}: the ${s.digit} goes here and the ${s.carryOut} is carried to the next column.'),
  // A 0 that lent first: checked before the plain cases, or they'd always win
  Slip.smallerFromLarger || Slip.forgotBorrow when s.top == 0 && s.carryIn > 0 => tr('Casi. ', 'Almost. ') + zeroLends(s),
  Slip.smallerFromLarger => tr(
      'Ojo: arriba está el ${s.top - s.carryIn}, y no le alcanza para quitarle ${s.bottom}. Hay que pedir prestado.',
      'Careful: the top digit is ${s.top - s.carryIn}, and that is not enough to take away ${s.bottom}. We need to borrow.'),
  Slip.forgotBorrow => tr('Casi. Este ${s.top} le prestó 1 a la columna de al lado, así que ahora es ${s.top - 1}.',
      'Almost. This ${s.top} lent 1 to the next column, so now it is ${s.top - 1}.'),
  Slip.addedInstead => p.op == Op.mul
      ? tr('Mmm, parece que sumaste. Aquí estamos multiplicando.', "Hmm, it looks like you added. Here we're multiplying.")
      : tr('Mmm, parece que sumaste. Aquí estamos restando.', "Hmm, it looks like you added. Here we're subtracting."),
  Slip.offByOne => tr('Muy cerca. Cuenta otra vez con calma.', 'Very close. Count again, nice and slowly.'),
  Slip.other => tr('Mmm, todavía no. Vamos a verlo juntos.', "Hmm, not yet. Let's look at it together."),
};

/// Hints, from a nudge to the digit itself
List<String> hints(ColumnProblem p, ColumnStep s) {
  final write = tr('Escribe el ${s.digit}.', 'Write the ${s.digit}.');
  if (p.op == Op.mul) {
    if (_pastTop(p, s)) {
      return [tr('Ya no hay números arriba: solo baja lo que llevamos.', 'There are no more digits on top: just bring down what we carried.'), write];
    }
    final times = '${s.top} × ${s.bottom}';
    return [
      s.carryIn > 0
          ? tr('Primero $times, y luego súmale el ${s.carryIn} que llevamos.', 'First $times, then add the ${s.carryIn} we carried.')
          : tr('Multiplica: $times.', 'Multiply: $times.'),
      s.carryIn > 0 ? '$times = ${s.top * s.bottom}. ${s.top * s.bottom} + ${s.carryIn} = ${s.value}.' : '$times = ${s.value}.',
      s.value >= 10 && _hasNext(p, s)
          ? tr('Escribe el ${s.digit} (y el ${s.carryOut} se lleva).', 'Write the ${s.digit} (and carry the ${s.carryOut}).')
          : write,
    ];
  }
  if (p.op == Op.add) {
    final parts = s.carryIn > 0 ? '${s.top} + ${s.bottom} + 1' : '${s.top} + ${s.bottom}';
    return [
      tr('Suma solo la columna de las ${s.placeName}: $parts.', 'Add just the ${s.placeName} column: $parts.'),
      '$parts = ${s.value}.',
      s.value >= 10 ? tr('Escribe el ${s.digit} (y el 1 se lleva).', 'Write the ${s.digit} (and carry the 1).') : write,
    ];
  }
  final have = s.top - s.carryIn;
  if (s.top == 0 && s.carryIn > 0) return [zeroLends(s), '9 − ${s.bottom} = ${s.value}.', write];
  if (s.borrows) {
    return [
      tr('A $have no le alcanza para quitarle ${s.bottom}: pedimos 1 prestado a la columna de al lado.',
          '$have is not enough to take away ${s.bottom}: we borrow 1 from the next column.'),
      '${tr('Con lo prestado, el $have se vuelve ${have + 10}.', 'With the borrowed 1, the $have becomes ${have + 10}.')} '
          '${have + 10} − ${s.bottom} = ${s.value}.',
      write,
    ];
  }
  return [
    if (s.carryIn > 0)
      tr('Este ${s.top} prestó 1: ahora es $have.', 'This ${s.top} lent 1: now it is $have.')
    else
      tr('Resta solo la columna de las ${s.placeName}.', 'Subtract just the ${s.placeName} column.'),
    '$have − ${s.bottom} = ${s.value}.',
    write,
  ];
}

/// The line read aloud: symbols said as words (and, in English, amounts as pesos)
String spoken(String line) => tr(
  line
      .replaceAll(' + ', ' más ')
      .replaceAll(' − ', ' menos ')
      .replaceAll(' × ', ' por ')
      .replaceAll(' ÷ ', ' entre ')
      .replaceAll(' = ', ' es igual a '),
  line
      // An English voice would read "$50" as dollars: the amounts here are pesos
      .replaceAllMapped(RegExp(r'\$(\d[\d,]*(?:\.\d+)?)'), (m) => '${m[1]} pesos')
      .replaceAll(' + ', ' plus ')
      .replaceAll(' − ', ' minus ')
      .replaceAll(' × ', ' times ')
      .replaceAll(' ÷ ', ' divided by ')
      .replaceAll(' = ', ' equals '),
);

/// A 0 can't lend until it borrows: it asks the next column for 1 (becomes 10), then lends 1 (stays 9)
String zeroLends(ColumnStep s) => tr(
  'El 0 no tiene qué prestar: le pide 1 a la columna de al lado y se vuelve 10. Como prestó 1, queda en 9.',
  'The 0 has nothing to lend: it borrows 1 from the next column and becomes 10. Since it then lends 1, it stays as 9.',
);
