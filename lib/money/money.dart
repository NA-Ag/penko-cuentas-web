// money.dart — the money engine: the everyday maths of percentages, interest, payments and the real yearly cost of a
// loan (CAT), worked in pesos. Ideas from the old Fini/Libre app, rewritten and tested; nothing here needs the
// internet. Like the column engine, code decides the numbers: Penko only explains them.
import 'dart:math';

import '../i18n/tr.dart';

/// [percent]% of [amount]
double percentOf(double amount, double percent) => amount * percent / 100;

/// One month of a loan with a fixed payment
class MonthRow {
  final int month;
  final double interest;
  final double principal;
  final double balance; // after this payment
  const MonthRow(this.month, this.interest, this.principal, this.balance);
}

/// A loan of [amount] at [monthlyRate]% a month, paid with [payment] each month (the last payment may be smaller).
/// Null if the payment doesn't even cover the interest: the debt would never end.
List<MonthRow>? schedule(double amount, double monthlyRate, double payment, {int maxMonths = 600}) {
  final r = monthlyRate / 100;
  if (payment <= amount * r) return null;
  final rows = <MonthRow>[];
  var balance = amount;
  for (var m = 1; balance > 0.005 && m <= maxMonths; m++) {
    final interest = balance * r;
    final principal = min(payment - interest, balance);
    balance -= principal;
    rows.add(MonthRow(m, interest, principal, max(balance, 0)));
  }
  return rows;
}

/// The fixed monthly payment that pays [amount] off in [months] at [monthlyRate]% a month
double paymentFor(double amount, double monthlyRate, int months) {
  final r = monthlyRate / 100;
  if (r == 0) return amount / months;
  return amount * r / (1 - pow(1 + r, -months));
}

/// What a loan really costs per year, as a percentage, counting the fees: the CAT ("costo anual total") the way
/// Banxico defines it — the yearly rate at which what you receive equals what you pay back. [received] is what
/// reaches your hand (after an opening fee), [payments] what you pay each month.
double cat(double received, List<double> payments) {
  // The monthly rate i where received = Σ payment_k / (1+i)^k, found by halving the interval
  double value(double i) {
    var total = 0.0;
    for (var k = 0; k < payments.length; k++) {
      total += payments[k] / pow(1 + i, k + 1);
    }
    return total;
  }

  var lo = 0.0, hi = 1.0;
  if (value(0) <= received) return 0;
  for (var n = 0; n < 200; n++) {
    final mid = (lo + hi) / 2;
    if (value(mid) > received) {
      lo = mid;
    } else {
      hi = mid;
    }
  }
  return (pow(1 + lo, 12) - 1) * 100;
}

/// A CAT as Banxico requires it to be shown (Circular 21/2009, 7): one decimal and "sin IVA", e.g. "41.3% sin IVA"
String catText(double cat) => tr('${cat.toStringAsFixed(1)}% sin IVA', '${cat.toStringAsFixed(1)}% excluding IVA');

/// Pesos as people write them: $1,234 or $1,234.50 (the same in English: a comma for thousands, a point for cents)
String pesos(double v) {
  final cents = (v * 100).round();
  final whole = cents ~/ 100, rest = cents % 100;
  final digits = '$whole'.replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},');
  return rest == 0 ? '\$$digits' : '\$$digits.${rest.toString().padLeft(2, '0')}';
}

/// Savings that grow: [start] now, [monthly] added at the end of each month, at [annualRate]% a year paid monthly.
/// The balance after each month, for [months] months.
List<double> savingsGrowth(double start, double monthly, double annualRate, int months) {
  final r = annualRate / 100 / 12;
  final out = <double>[];
  var balance = start;
  for (var m = 0; m < months; m++) {
    balance = balance * (1 + r) + monthly;
    out.add(balance);
  }
  return out;
}

/// One debt in a payoff plan
class DebtLine {
  final String name;
  final double balance;
  final double annualRate; // %
  final double minimum; // the least that must be paid each month
  const DebtLine(this.name, this.balance, this.annualRate, this.minimum);
}

/// Which debt gets the extra money first
enum PayoffOrder {
  avalanche, // the highest rate first: the least interest overall
  snowball, // the smallest debt first: quick wins
}

class PayoffPlan {
  final int months; // until everything is paid (0 if it never ends)
  final double interest; // paid in total
  final List<int> paidOff; // for each debt, the month it was paid off
  final bool neverEnds; // the money doesn't cover the minimums or the interest
  const PayoffPlan(this.months, this.interest, this.paidOff, {this.neverEnds = false});
}

/// Pays several debts with [budget] a month: every debt gets its minimum, everything left goes to one debt chosen by
/// [order], and when a debt is paid off its money moves on to the next ("bola de nieve" / "avalancha")
PayoffPlan payoffPlan(List<DebtLine> debts, double budget, PayoffOrder order, {int maxMonths = 600}) {
  final balance = [for (final d in debts) d.balance];
  final paidOff = List.filled(debts.length, 0);
  final minimums = debts.fold<double>(0, (t, d) => t + d.minimum);
  if (budget < minimums) return PayoffPlan(0, 0, paidOff, neverEnds: true);
  var interest = 0.0;
  for (var m = 1; m <= maxMonths; m++) {
    for (var i = 0; i < debts.length; i++) {
      final charge = balance[i] * debts[i].annualRate / 100 / 12;
      balance[i] += charge;
      interest += charge;
    }
    var money = budget;
    for (var i = 0; i < debts.length; i++) {
      final pay = min(debts[i].minimum, balance[i]);
      balance[i] -= pay;
      money -= pay;
    }
    // The rest, in the chosen order
    final open = [for (var i = 0; i < debts.length; i++) if (balance[i] > 0.005) i]
      ..sort((a, b) => order == PayoffOrder.avalanche
          ? debts[b].annualRate.compareTo(debts[a].annualRate)
          : balance[a].compareTo(balance[b]));
    for (final i in open) {
      final pay = min(money, balance[i]);
      balance[i] -= pay;
      money -= pay;
    }
    for (var i = 0; i < debts.length; i++) {
      if (paidOff[i] == 0 && balance[i] <= 0.005) paidOff[i] = m;
    }
    if (balance.every((b) => b <= 0.005)) return PayoffPlan(m, interest, paidOff);
  }
  return PayoffPlan(0, interest, paidOff, neverEnds: true);
}

/// Money that comes in or goes out on certain days of the month (a quincena, the rent, groceries every week)
class MoneyEvent {
  final String name;
  final double amount; // + comes in, − goes out
  final List<int> days; // days of the month, 1–30
  const MoneyEvent(this.name, this.amount, this.days);
}

/// What's left at the end of each day of a 30-day month, starting with [start]: the cash-flow calendar
List<double> cashFlow(double start, List<MoneyEvent> events) {
  final out = <double>[];
  var balance = start;
  for (var day = 1; day <= 30; day++) {
    for (final e in events) {
      balance += e.amount * e.days.where((d) => d == day).length;
    }
    out.add(balance);
  }
  return out;
}

/// IVA on interest: in Mexico most consumer credit charges 16% IVA on the interest (not on what you borrowed)
const ivaOnInterest = 0.16;

/// Paying only the minimum on a credit card, the way Mexican banks work it out under Banxico's rule: each month the
/// larger of (1.5% of what's owed + that month's interest + its IVA) and (1.25% of the credit limit), or what's left.
/// The minimum shrinks as the debt does, which is why it takes so long.
({int months, double interest, double firstMinimum, bool neverEnds}) minimumPaymentPlan(
    double balance, double annualRate, double limit, {int maxMonths = 600}) {
  final r = annualRate / 100 / 12;
  var owed = balance, paid = 0.0, first = 0.0;
  for (var m = 1; m <= maxMonths; m++) {
    final interest = owed * r, iva = interest * ivaOnInterest;
    final minimum = max(0.015 * owed + interest + iva, 0.0125 * limit);
    final pay = min(minimum, owed + interest + iva);
    if (m == 1) first = pay;
    paid += interest + iva;
    owed = owed + interest + iva - pay;
    if (owed <= 0.005) return (months: m, interest: paid, firstMinimum: first, neverEnds: false);
  }
  return (months: maxMonths, interest: paid, firstMinimum: first, neverEnds: true);
}
