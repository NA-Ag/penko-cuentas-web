import 'package:flutter_test/flutter_test.dart';
import 'dart:math';

import 'package:penko_math/money/money.dart';
import 'package:penko_math/money/money_lessons.dart';

void main() {
  test('percentages', () {
    expect(percentOf(350, 10), 35);
    expect(percentOf(1200, 25), 300);
  });

  test('a loan schedule pays the loan off exactly', () {
    final rows = schedule(10000, 3, 1000)!;
    final principal = rows.fold(0.0, (t, r) => t + r.principal);
    expect(principal, closeTo(10000, 0.01));
    expect(rows.last.balance, 0);
    expect(schedule(10000, 10, 1000), isNull); // pays only interest: never ends
  });

  test('payment for n months matches the schedule', () {
    final p = paymentFor(12000, 2, 12);
    expect(schedule(12000, 2, p)!.length, 12);
  });

  test('CAT: no interest and no fees is 0%; fees push it up', () {
    expect(cat(12000, List.filled(12, 1000)), closeTo(0, 0.01));
    // 2% a month, no fee → (1.02^12 − 1) = 26.82%
    final p = paymentFor(10000, 2, 12);
    expect(cat(10000, List.filled(12, p)), closeTo(26.82, 0.05));
    // Same loan, $500 opening fee: you receive less, so the real cost is higher
    expect(cat(9500, List.filled(12, p)), greaterThan(36));
  });

  test('pesos are written the Mexican way', () {
    expect(pesos(1234), r'$1,234');
    expect(pesos(1234.5), r'$1,234.50');
    expect(pesos(35), r'$35');
  });

  test('money lessons: whole answers, no stray decimals, positive amounts', () {
    final rng = Random(5);
    for (final l in moneyUnit) {
      for (var i = 0; i < 300; i++) {
        final p = l.make(rng);
        final texts = [p.story, p.lesson, for (final s in p.steps) ...[s.ask, s.done, ...s.hints]];
        for (final t in texts) {
          // (a CAT keeps its one decimal, as Banxico requires: "28.0% sin IVA")
          expect(RegExp(r'\d\.0\b(?!% sin IVA)').hasMatch(t), isFalse, reason: '${l.id}: $t');
        }
        for (final s in p.steps) {
          expect(s.answer, greaterThan(0), reason: '${l.id}: ${s.ask}');
          expect(s.hints.last.contains('${s.answer}') || s.hints.last.contains(pesos(s.answer.toDouble())), isTrue,
              reason: '${l.id}: last hint must give the answer: ${s.hints.last}');
        }
      }
    }
  });

  test('savings: 1,000 a month at 12% a year for 12 months', () {
    final g = savingsGrowth(0, 1000, 12, 12); // 1% a month
    expect(g.length, 12);
    // Future value of an annuity: 1000 × ((1.01^12 − 1) / 0.01)
    expect(g.last, closeTo(1000 * (pow(1.01, 12) - 1) / 0.01, 0.01));
    expect(savingsGrowth(5000, 0, 0, 24).last, 5000);
  });

  test('debt plans: everything gets paid, avalanche pays the least interest', () {
    const debts = [
      DebtLine('Tarjeta', 20000, 60, 800),
      DebtLine('Préstamo', 8000, 30, 400),
      DebtLine('Tienda', 3000, 45, 200),
    ];
    final a = payoffPlan(debts, 3000, PayoffOrder.avalanche);
    final s = payoffPlan(debts, 3000, PayoffOrder.snowball);
    expect(a.neverEnds, isFalse);
    expect(s.neverEnds, isFalse);
    expect(a.interest, lessThanOrEqualTo(s.interest));
    expect(s.paidOff[2], lessThan(s.paidOff[0])); // snowball clears the small one first
    expect(a.paidOff.reduce(max), a.months);
    expect(payoffPlan(debts, 1000, PayoffOrder.avalanche).neverEnds, isTrue); // less than the minimums
  });

  test('cash-flow calendar: the rent before payday leaves you short for a while', () {
    const events = [
      MoneyEvent('Quincena', 5000, [15, 30]),
      MoneyEvent('Renta', -4000, [1]),
      MoneyEvent('Despensa', -700, [1, 8, 15, 22, 29]),
    ];
    final days = cashFlow(2000, events);
    expect(days.length, 30);
    expect(days[0], 2000 - 4000 - 700); // day 1
    expect(days[14], 2000 - 4000 - 700 * 3 + 5000); // day 15
    expect(days.last, 2000 + 10000 - 4000 - 3500);
  });

  test("minimum payment (Banxico's rule): the larger of 1.5% + interest + IVA, or 1.25% of the limit", () {
    // $10,000 owed at 60% a year (5% a month), limit $20,000: 150 + 500 + 80 = 730 vs 250 → 730
    final p = minimumPaymentPlan(10000, 60, 20000);
    expect(p.firstMinimum, closeTo(730, 0.01));
    expect(p.neverEnds, isFalse);
    expect(p.months, greaterThan(60)); // years of paying
    expect(p.interest, greaterThan(10000)); // more interest than the debt itself
  });

  test("CAT matches Banxico's formula (Circular 21/2009, 4.1), checked with an independent solver", () {
    // Values from solving Σ A/(1+i)^t = Σ B/(1+i)^s with s = k/12 years, by bisection, in Python
    expect(cat(10000, List.filled(12, 1000)), closeTo(41.2999, 0.001));
    expect(cat(10000, List.filled(12, 950)), closeTo(27.9589, 0.001));
    expect(cat(10000, List.filled(18, 700)), closeTo(35.3551, 0.001));
    // An opening fee paid at signing is a payment at time 0, the same as receiving that much less
    expect(cat(20000 - 400, List.filled(12, 1820)), closeTo(22.4979, 0.001));
  });
}
