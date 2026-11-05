// money_lessons.dart — the Dinero unit: maths people use every day in Mexico (discounts, interest, "meses sin
// intereses", tandas, a monthly budget). Each problem is a short story worked in steps; every step's answer comes
// from the money engine and every line Penko says is written here, so nothing she says can be wrong. Numbers are
// picked fresh each time so the answers come out in whole pesos.
import 'dart:math';

import '../i18n/tr.dart';
import '../lessons/work.dart';
import 'money.dart';

export '../lessons/work.dart';

T _pick<T>(Random r, List<T> xs) => xs[r.nextInt(xs.length)];

WorkProblem _discount(Random r) {
  final price = (4 + r.nextInt(16)) * 100; // $400–$1,900
  final pct = _pick<int>(r, [10, 20, 25, 50]);
  final off = percentOf(price.toDouble(), pct.toDouble()).round();
  // The item and its verb, so they agree: "unos tenis cuestan", "una mochila cuesta"
  final (item, cost) = _pick(r, trOf([('unos tenis', 'cuestan'), ('una mochila', 'cuesta'), ('una chamarra', 'cuesta'),
      ('unos audífonos', 'cuestan')], [('a pair of sneakers', 'costs'), ('a backpack', 'costs'), ('a jacket', 'costs'),
      ('a pair of headphones', 'costs')]));
  final first = switch (pct) {
    10 => WorkStep(tr('¿Cuánto es el 10% de ${pesos(price.toDouble())}?', 'What is 10% of ${pesos(price.toDouble())}?'), off,
        [tr('El 10% es dividir entre 10.', '10% is dividing by 10.'), '$price ÷ 10 = $off.'], tr('10% de ${pesos(price.toDouble())} = ${pesos(off.toDouble())}', '10% of ${pesos(price.toDouble())} = ${pesos(off.toDouble())}')),
    20 => WorkStep(tr('¿Cuánto es el 20% de ${pesos(price.toDouble())}?', 'What is 20% of ${pesos(price.toDouble())}?'), off,
        [tr('El 20% es dos veces el 10%. Primero divide entre 10.', '20% is twice 10%. First divide by 10.'), tr('10% = ${price ~/ 10}. Dos veces: ${price ~/ 10} × 2 = $off.', '10% = ${price ~/ 10}. Twice that: ${price ~/ 10} × 2 = $off.')],
        tr('20% de ${pesos(price.toDouble())} = ${pesos(off.toDouble())}', '20% of ${pesos(price.toDouble())} = ${pesos(off.toDouble())}')),
    25 => WorkStep(tr('¿Cuánto es el 25% de ${pesos(price.toDouble())}?', 'What is 25% of ${pesos(price.toDouble())}?'), off,
        [tr('El 25% es la cuarta parte: divide entre 4.', '25% is a quarter: divide by 4.'), '$price ÷ 4 = $off.'], tr('25% de ${pesos(price.toDouble())} = ${pesos(off.toDouble())}', '25% of ${pesos(price.toDouble())} = ${pesos(off.toDouble())}')),
    _ => WorkStep(tr('¿Cuánto es el 50% de ${pesos(price.toDouble())}?', 'What is 50% of ${pesos(price.toDouble())}?'), off,
        [tr('El 50% es la mitad: divide entre 2.', '50% is half: divide by 2.'), '$price ÷ 2 = $off.'], tr('50% de ${pesos(price.toDouble())} = ${pesos(off.toDouble())}', '50% of ${pesos(price.toDouble())} = ${pesos(off.toDouble())}')),
  };
  return WorkProblem(
    tr('En la tienda, $item $cost ${pesos(price.toDouble())} y tienen $pct% de descuento.', 'At the store, $item $cost ${pesos(price.toDouble())} and there is $pct% off.'),
    [
      first,
      WorkStep(tr('Entonces, ¿cuánto pagas?', 'So, how much do you pay?'), price - off,
          [tr('Al precio le quitas el descuento.', 'Take the discount off the price.'), '$price − $off = ${price - off}.'], tr('Pagas ${pesos((price - off).toDouble())}', 'You pay ${pesos((price - off).toDouble())}')),
    ],
    tr('Un descuento del $pct% te ahorra ${pesos(off.toDouble())}. ¡Siempre vale la pena sacar la cuenta!', 'A $pct% discount saves you ${pesos(off.toDouble())}. It always pays to do the math!'),
  );
}

WorkProblem _interest(Random r) {
  final amount = (1 + r.nextInt(5)) * 1000; // $1,000–$5,000
  final rate = _pick<int>(r, [5, 10, 20]);
  final months = 2 + r.nextInt(3);
  final perMonth = percentOf(amount.toDouble(), rate.toDouble()).round();
  return WorkProblem(
    (() {
      final who = _pick(r, trOf(['Alguien', 'Un prestamista de la colonia', 'Una casa de empeño', 'Un compañero del trabajo'],
          ['Someone', 'A moneylender in your neighborhood', 'A pawnshop', 'A coworker']));
      return tr('$who te presta ${pesos(amount.toDouble())} y te cobra $rate% de interés cada mes. Lo pagas todo en $months meses.',
          '$who lends you ${pesos(amount.toDouble())} and charges $rate% interest every month. You pay it all back in $months months.');
    })(),
    [
      WorkStep(tr('¿Cuánto es el interés de un mes?', "What is one month's interest?"), perMonth,
          [tr('El interés de un mes es el $rate% de ${pesos(amount.toDouble())}.', "One month's interest is $rate% of ${pesos(amount.toDouble())}."),
           rate == 10
               ? '$amount ÷ 10 = $perMonth.'
               : tr('Saca el 10%: ${amount ~/ 10}. El $rate% es ${rate == 5 ? 'la mitad' : 'el doble'}: $perMonth.',
                   'Work out 10%: ${amount ~/ 10}. $rate% is ${rate == 5 ? 'half of that' : 'twice that'}: $perMonth.')],
          tr('Interés de un mes: ${pesos(perMonth.toDouble())}', "One month's interest: ${pesos(perMonth.toDouble())}")),
      WorkStep(tr('¿Cuánto pagas de interés en $months meses?', 'How much interest do you pay in $months months?'), perMonth * months,
          [tr('Son $months meses de ${pesos(perMonth.toDouble())}.', "That's $months months of ${pesos(perMonth.toDouble())}."), '$perMonth × $months = ${perMonth * months}.'],
          tr('Interés en $months meses: ${pesos((perMonth * months).toDouble())}', 'Interest over $months months: ${pesos((perMonth * months).toDouble())}')),
      WorkStep(tr('Entonces, ¿cuánto pagas en total?', 'So, how much do you pay in total?'), amount + perMonth * months,
          [tr('Lo que te prestaron más los intereses.', 'What you borrowed plus the interest.'), '$amount + ${perMonth * months} = ${amount + perMonth * months}.'],
          'Total: ${pesos((amount + perMonth * months).toDouble())}'),
    ],
    tr('Pediste ${pesos(amount.toDouble())} y pagas ${pesos((amount + perMonth * months).toDouble())}. Antes de pedir prestado, '
        'saca la cuenta de los intereses. Ojo: los bancos además cobran 16% de IVA sobre los intereses.',
        'You borrowed ${pesos(amount.toDouble())} and pay back ${pesos((amount + perMonth * months).toDouble())}. Before you '
            'borrow, work out the interest. Note: in Mexico, banks also charge 16% IVA (value-added tax) on the interest.'),
  );
}

WorkProblem _installments(Random r) {
  final price = (3 + r.nextInt(10)) * 1200; // $3,600–$14,400, divisible by 6 and 12
  final months = _pick<int>(r, [6, 12]);
  final msi = price ~/ months;
  final small = msi + _pick<int>(r, [100, 150, 200, 250]); // "pagos chiquitos" with interest
  final (item, it) = _pick(r, trOf([('una tele', 'la'), ('un celular', 'lo'), ('un refri', 'lo'), ('una lavadora', 'la')],
      [('a TV', 'it'), ('a cell phone', 'it'), ('a fridge', 'it'), ('a washing machine', 'it')]));
  return WorkProblem(
    tr('${item[0].toUpperCase()}${item.substring(1)} cuesta ${pesos(price.toDouble())}. Puedes pagar$it a $months meses sin intereses, o en "pagos chiquitos" de '
        '${pesos(small.toDouble())} al mes durante $months meses.',
        '${item[0].toUpperCase()}${item.substring(1)} costs ${pesos(price.toDouble())}. You can pay for $it over $months months '
            'with no interest, or in "small payments" of ${pesos(small.toDouble())} a month for $months months.'),
    [
      WorkStep(tr('A $months meses sin intereses, ¿cuánto pagas cada mes?', 'Over $months months with no interest, how much do you pay each month?'), msi,
          [tr('Sin intereses: el precio se reparte en $months pagos iguales.', 'With no interest, the price is split into $months equal payments.'), '$price ÷ $months = $msi.'],
          tr('Sin intereses: ${pesos(msi.toDouble())} al mes', 'No interest: ${pesos(msi.toDouble())} a month')),
      WorkStep(tr('Con los pagos chiquitos, ¿cuánto pagas en total?', 'With the small payments, how much do you pay in total?'), small * months,
          [tr('Son $months pagos de ${pesos(small.toDouble())}.', "That's $months payments of ${pesos(small.toDouble())}."), '$small × $months = ${small * months}.'],
          tr('Pagos chiquitos: ${pesos((small * months).toDouble())} en total', 'Small payments: ${pesos((small * months).toDouble())} in total')),
      WorkStep(tr('¿Cuánto pagas de más con los pagos chiquitos?', 'How much extra do you pay with the small payments?'), small * months - price,
          [tr('Al total de los pagos chiquitos réstale el precio.', 'Take the price away from the total of the small payments.'), '${small * months} − $price = ${small * months - price}.'],
          tr('Pagas ${pesos((small * months - price).toDouble())} de más', 'You pay ${pesos((small * months - price).toDouble())} extra')),
    ],
    tr('Los pagos chiquitos se ven fáciles, pero salen ${pesos((small * months - price).toDouble())} más caros. '
        'Siempre multiplica el pago por el número de meses.',
        'The small payments look easy, but they cost ${pesos((small * months - price).toDouble())} more. '
            'Always multiply the payment by the number of months.'),
  );
}

WorkProblem _tanda(Random r) {
  final weekly = _pick<int>(r, [100, 150, 200, 250, 300, 500]);
  final people = 5 + r.nextInt(6);
  // A tanda among neighbours, workmates or family, paid every week or every quincena
  final (who, every, turns) = _pick(r, trOf([('vecinas', 'Cada semana', 'semanas'), ('compañeros del trabajo', 'Cada quincena', 'quincenas'),
      ('primos y tías', 'Cada semana', 'semanas')], [('neighbors', 'Every week', 'weeks'),
      ('coworkers', 'Every payday (twice a month)', 'paydays'), ('cousins and aunts', 'Every week', 'weeks')]));
  return WorkProblem(
    tr('Entras a una tanda de $people personas con tus $who. $every todos ponen ${pesos(weekly.toDouble())}, y cada vez a una '
        'persona le toca todo.',
        'You join a tanda of $people people with your $who. $every everyone puts in ${pesos(weekly.toDouble())}, and each '
            'time one person gets it all.'),
    [
      WorkStep(tr('¿Cuánto te toca cuando es tu turno?', "How much do you get when it's your turn?"), weekly * people,
          [tr('Todos ponen ${pesos(weekly.toDouble())}, y son $people.', 'Everyone puts in ${pesos(weekly.toDouble())}, and there are $people of you.'), '$weekly × $people = ${weekly * people}.'],
          tr('Te toca ${pesos((weekly * people).toDouble())}', 'You get ${pesos((weekly * people).toDouble())}')),
      WorkStep(tr('¿Cuánto pusiste tú en total al terminar la tanda?', 'How much did you put in, in total, by the end of the tanda?'), weekly * people,
          [tr('Pones ${pesos(weekly.toDouble())} cada vez, durante $people $turns.', 'You put in ${pesos(weekly.toDouble())} each time, for $people $turns.'), '$weekly × $people = ${weekly * people}.'],
          tr('Pusiste ${pesos((weekly * people).toDouble())}', 'You put in ${pesos((weekly * people).toDouble())}')),
    ],
    tr('En una tanda recibes lo mismo que pones: no ganas intereses, pero te ayuda a juntar dinero. '
        'Ojo: solo entra con gente de confianza.',
        'In a tanda you get back the same as you put in: you earn no interest, but it helps you save up. '
            'Careful: only join with people you trust.'),
  );
}

WorkProblem _budget(Random r) {
  final income = (6 + r.nextInt(7)) * 1000; // $6,000–$12,000 a month
  final rent = (income * 0.35 / 100).round() * 100;
  final food = (income * 0.3 / 100).round() * 100;
  final transport = _pick<int>(r, [600, 800, 1000]);
  final left = income - rent - food - transport;
  final save = left ~/ 2; // whole pesos: every amount above is in hundreds
  // Who it is, with the verbs agreeing ("Una familia gana… Paga", "Doña Rosa y su hijo ganan… Pagan")
  final (who, pays) = _pick(r, trOf([('Una familia gana', 'Paga'), ('Doña Rosa y su hijo ganan', 'Pagan'),
      ('Una pareja joven gana', 'Paga'), ('Don Beto y su esposa ganan', 'Pagan')], [('A family earns', 'They pay'),
      ('Doña Rosa and her son earn', 'They pay'), ('A young couple earns', 'They pay'), ('Don Beto and his wife earn', 'They pay')]));
  return WorkProblem(
    tr('$who ${pesos(income.toDouble())} al mes. $pays ${pesos(rent.toDouble())} de renta, '
        '${pesos(food.toDouble())} de comida y ${pesos(transport.toDouble())} de transporte.',
        '$who ${pesos(income.toDouble())} a month. $pays ${pesos(rent.toDouble())} in rent, '
            '${pesos(food.toDouble())} for food and ${pesos(transport.toDouble())} for transportation.'),
    [
      WorkStep(tr('¿Cuánto gastan entre las tres cosas?', 'How much do they spend on the three things together?'), rent + food + transport,
          [tr('Suma los tres gastos.', 'Add up the three expenses.'), '$rent + $food + $transport = ${rent + food + transport}.'],
          tr('Gastos: ${pesos((rent + food + transport).toDouble())}', 'Expenses: ${pesos((rent + food + transport).toDouble())}')),
      WorkStep(tr('¿Cuánto les queda?', 'How much do they have left?'), left,
          [tr('A lo que ganan réstale los gastos.', 'Take the expenses away from what they earn.'), '$income − ${rent + food + transport} = $left.'],
          tr('Les queda ${pesos(left.toDouble())}', 'They have ${pesos(left.toDouble())} left')),
      WorkStep(tr('Si guardan la mitad de lo que les queda, ¿cuánto ahorran al mes?', 'If they put away half of what is left, how much do they save a month?'), save,
          [tr('La mitad es dividir entre 2.', 'Half is dividing by 2.'), '$left ÷ 2 = $save.'],
          tr('Ahorran ${pesos(save.toDouble())} al mes', 'They save ${pesos(save.toDouble())} a month')),
    ],
    tr('Apuntar lo que entra y lo que sale es el primer paso para ahorrar. ${pesos(save.toDouble())} al mes son '
        '${pesos(save * 12.0)} en un año.',
        'Writing down what comes in and what goes out is the first step to saving. ${pesos(save.toDouble())} a month is '
            '${pesos(save * 12.0)} in a year.'),
  );
}

WorkProblem _card(Random r) {
  // Debts in steps of $2,500 so the interest is a multiple of 25 and its 16% IVA comes out in whole pesos
  final debt = (2 + r.nextInt(5)) * 2500; // $5,000–$15,000
  final rate = _pick<int>(r, [3, 4]); // a month
  final interest = debt * rate ~/ 100;
  final iva = interest * 16 ~/ 100;
  final pay = interest + iva + _pick<int>(r, [100, 150, 200]);
  final rows = schedule(debt.toDouble(), rate * (1 + ivaOnInterest), pay.toDouble())!;
  final paid = rows.fold<double>(0, (t, m) => t + m.interest);
  final years = rows.length ~/ 12;
  return WorkProblem(
    tr('Debes ${pesos(debt.toDouble())} en la tarjeta de crédito, que te cobra $rate% de interés al mes, más el IVA de ese '
        'interés. Cada mes pagas ${pesos(pay.toDouble())}.',
        'You owe ${pesos(debt.toDouble())} on a credit card that charges $rate% interest a month, plus IVA (Mexico\'s 16% '
            'value-added tax) on that interest. Each month you pay ${pesos(pay.toDouble())}.'),
    [
      WorkStep(tr('¿Cuánto es el interés de un mes?', "What is one month's interest?"), interest,
          [tr('El $rate% de ${pesos(debt.toDouble())}. Primero el 1%: divide entre 100.', '$rate% of ${pesos(debt.toDouble())}. First 1%: divide by 100.'), '$debt ÷ 100 = ${debt ~/ 100}. ${debt ~/ 100} × $rate = $interest.'],
          tr('Interés del mes: ${pesos(interest.toDouble())}', "This month's interest: ${pesos(interest.toDouble())}")),
      WorkStep(tr('Al interés le cobran 16% de IVA. ¿Cuánto es el IVA?', 'They charge 16% IVA on the interest. How much is the IVA?'), iva,
          [tr('El 16% es 16 de cada 100: divide el interés entre 100 y multiplica por 16.', '16% is 16 out of every 100: divide the interest by 100 and multiply by 16.'), '$interest ÷ 100 × 16 = $iva.'],
          tr('IVA del interés: ${pesos(iva.toDouble())}', 'IVA on the interest: ${pesos(iva.toDouble())}')),
      WorkStep(tr('De tu pago de ${pesos(pay.toDouble())}, ¿cuánto baja de verdad tu deuda?', 'Of your ${pesos(pay.toDouble())} payment, how much really comes off your debt?'), pay - interest - iva,
          [tr('Primero se pagan el interés y su IVA. Lo que queda es lo que baja la deuda.', 'The interest and its IVA are paid first. What is left is what comes off the debt.'), '$pay − $interest − $iva = ${pay - interest - iva}.'],
          tr('Tu deuda baja solo ${pesos((pay - interest - iva).toDouble())}', 'Your debt goes down by only ${pesos((pay - interest - iva).toDouble())}')),
    ],
    tr('Pagando así tardarías ${rows.length} meses${years > 0 ? ' (más de $years ${years == 1 ? 'año' : 'años'})' : ''} y '
        'pagarías ${pesos(paid.roundToDouble())} de intereses con IVA. Pagar más cada mes te ahorra mucho dinero.',
        'Paying like this, it would take you ${rows.length} months${years > 0 ? ' (more than $years ${years == 1 ? 'year' : 'years'})' : ''} '
            'and you would pay ${pesos(paid.roundToDouble())} in interest with IVA. Paying more each month saves you a lot of money.'),
  );
}

WorkProblem _savings(Random r) {
  final amount = (1 + r.nextInt(10)) * 1000; // $1,000–$10,000, at 10% a year
  final first = amount ~/ 10, after1 = amount + first, second = after1 ~/ 10, after2 = after1 + second;
  return WorkProblem(
    tr('Ahorras ${pesos(amount.toDouble())} en una cuenta que te paga 10% de interés al año, y no sacas nada.', 'You save ${pesos(amount.toDouble())} in an account that pays you 10% interest a year, and you take nothing out.'),
    [
      WorkStep(tr('¿Cuánto ganas de interés el primer año?', 'How much interest do you earn in the first year?'), first,
          [tr('El 10% es dividir entre 10.', '10% is dividing by 10.'), '$amount ÷ 10 = $first.'], tr('Primer año: ganas ${pesos(first.toDouble())}', 'First year: you earn ${pesos(first.toDouble())}')),
      WorkStep(tr('¿Cuánto tienes al terminar el primer año?', 'How much do you have at the end of the first year?'), after1,
          [tr('Lo que ahorraste más los intereses.', 'What you saved plus the interest.'), '$amount + $first = $after1.'], tr('Tienes ${pesos(after1.toDouble())}', 'You have ${pesos(after1.toDouble())}')),
      WorkStep(tr('El segundo año el 10% es sobre ${pesos(after1.toDouble())}. ¿Cuánto ganas?', 'In the second year, the 10% is on ${pesos(after1.toDouble())}. How much do you earn?'), second,
          [tr('Ahora divide $after1 entre 10.', 'Now divide $after1 by 10.'), '$after1 ÷ 10 = $second.'], tr('Segundo año: ganas ${pesos(second.toDouble())}', 'Second year: you earn ${pesos(second.toDouble())}')),
      WorkStep(tr('¿Cuánto tienes al terminar el segundo año?', 'How much do you have at the end of the second year?'), after2,
          [tr('Súmale los intereses del segundo año.', "Add the second year's interest."), '$after1 + $second = $after2.'], tr('Tienes ${pesos(after2.toDouble())}', 'You have ${pesos(after2.toDouble())}')),
    ],
    tr('El segundo año ganaste más que el primero, porque tus intereses también ganaron intereses. Eso es el interés '
        'compuesto. Los CETES del gobierno funcionan parecido: le prestas tu dinero y te paga intereses.',
        'In the second year you earned more than in the first, because your interest earned interest too. That is compound '
            'interest. CETES (Mexican government bonds) work in a similar way: you lend the government your money and it pays you interest.'),
  );
}

WorkProblem _compareLoans(Random r) {
  const amount = 10000;
  while (true) {
    final a = _pick<int>(r, [950, 1000, 1050]), b = _pick<int>(r, [700, 750, 800]);
    final totalA = a * 12, totalB = b * 18;
    final catA = cat(amount.toDouble(), List.filled(12, a.toDouble()));
    final catB = cat(amount.toDouble(), List.filled(18, b.toDouble()));
    if (totalB <= totalA || catB <= catA) continue; // the small payments must cost more both ways
    return WorkProblem(
      tr('Necesitas ${pesos(amount.toDouble())}. Un crédito te pide 12 pagos de ${pesos(a.toDouble())}. Otro te pide 18 '
          'pagos de ${pesos(b.toDouble())}.',
          'You need ${pesos(amount.toDouble())}. One loan asks for 12 payments of ${pesos(a.toDouble())}. Another asks for 18 '
              'payments of ${pesos(b.toDouble())}.'),
      [
        WorkStep(tr('Con el primero, ¿cuánto pagas en total?', 'With the first one, how much do you pay in total?'), totalA,
            [tr('Son 12 pagos de ${pesos(a.toDouble())}.', "That's 12 payments of ${pesos(a.toDouble())}."), '$a × 12 = $totalA.'], tr('Primero: ${pesos(totalA.toDouble())}', 'First: ${pesos(totalA.toDouble())}')),
        WorkStep(tr('Con el segundo, ¿cuánto pagas en total?', 'With the second one, how much do you pay in total?'), totalB,
            [tr('Son 18 pagos de ${pesos(b.toDouble())}.', "That's 18 payments of ${pesos(b.toDouble())}."), '$b × 18 = $totalB.'], tr('Segundo: ${pesos(totalB.toDouble())}', 'Second: ${pesos(totalB.toDouble())}')),
        WorkStep(tr('¿Cuánto pagas de más con el segundo?', 'How much more do you pay with the second one?'), totalB - totalA,
            [tr('Resta los dos totales.', 'Subtract the two totals.'), '$totalB − $totalA = ${totalB - totalA}.'],
            tr('El segundo cuesta ${pesos((totalB - totalA).toDouble())} más', 'The second one costs ${pesos((totalB - totalA).toDouble())} more')),
      ],
      tr('El CAT del primero es de ${catText(catA)} y el del segundo de ${catText(catB)}. El CAT te dice cuánto cuesta un crédito al año: '
          'compara siempre el CAT, no solo el pago de cada mes.',
          'The CAT (total annual cost, Mexico\'s version of APR) of the first is ${catText(catA)} and of the second '
              '${catText(catB)}. The CAT tells you what a loan costs per year: always compare the CAT, not just the monthly payment.'),
    );
  }
}

List<WorkLesson> get moneyUnit => [
  WorkLesson('mo-1', tr('Descuentos', 'Discounts'), [
    tr('Ahora vamos a usar las matemáticas con dinero de verdad.', "Now let's use math with real money. The examples are in Mexican pesos (\$)."),
    tr('El porcentaje dice cuántos de cada 100. El 10% de algo es dividirlo entre 10.', 'A percentage says how many out of every 100. 10% of something is dividing it by 10.'),
  ], _discount, pesos: true),
  WorkLesson('mo-2', tr('Intereses', 'Interest'), [
    tr('Cuando alguien te presta dinero, casi siempre te cobra intereses: un porcentaje extra cada mes.', 'When someone lends you money, they almost always charge interest: an extra percentage every month.'),
    tr('En este ejemplo el interés se cobra siempre sobre lo que te prestaron, como en muchos préstamos entre personas.', 'In this example the interest is always charged on what you borrowed, as in many loans between people.'),
  ], _interest, pesos: true),
  WorkLesson('mo-3', tr('Meses sin intereses', 'Interest-free months'), [
    tr('En las tiendas te ofrecen pagar en meses. Vamos a ver cuánto pagas de verdad.', 'Stores in Mexico often offer "meses sin intereses": paying over several months with no interest. Let\'s see how much you really pay.'),
  ], _installments, pesos: true),
  WorkLesson('mo-4', tr('La tanda', 'The tanda'), [
    tr('La tanda es una forma de juntar dinero entre varias personas. ¿Cómo funciona?', 'A tanda is a way for a group of people to save money together (a rotating savings group, common in Mexico). How does it work?'),
  ], _tanda, pesos: true),
  WorkLesson('mo-5', tr('El presupuesto', 'The budget'), [
    tr('Un presupuesto es apuntar cuánto entra y cuánto sale. Así sabes cuánto puedes ahorrar.', 'A budget means writing down how much comes in and how much goes out. That way you know how much you can save.'),
  ], _budget, pesos: true),
  WorkLesson('mo-6', tr('La tarjeta de crédito', 'The credit card'), [
    tr('Con la tarjeta de crédito pagas después, pero lo que debes cobra intereses cada mes.', 'With a credit card you pay later, but what you owe is charged interest every month.'),
    tr('De cada pago, primero se cubren los intereses y su IVA. Solo lo que sobra baja tu deuda.', "From each payment, the interest and its IVA (Mexico's value-added tax) are covered first. Only what is left lowers your debt."),
  ], _card, pesos: true),
  WorkLesson('mo-7', tr('Ahorrar con intereses', 'Saving with interest'), [
    tr('Cuando ahorras en una cuenta con intereses, tu dinero crece solo.', 'When you save in an account that pays interest, your money grows by itself.'),
  ], _savings, pesos: true),
  WorkLesson('mo-8', tr('Comparar créditos: el CAT', 'Comparing loans: the CAT'), [
    tr('Un pago chiquito al mes se ve barato. Vamos a ver cuánto cuesta en total.', "A small monthly payment looks cheap. Let's see what it costs in total."),
  ], _compareLoans, pesos: true),
];
