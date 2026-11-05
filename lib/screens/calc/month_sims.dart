// month_sims.dart — two simulators built on the ideas of the CFPB's "Your Money, Your Goals" worksheets: the
// cash-flow calendar (when money comes in and goes out across the month, so you can see the days it runs short) and
// the debt list (all the debts in one place: what's owed, the minimums, the interest each month). Made-up values moved
// along lines; nothing is saved.
import 'dart:math';

import 'package:flutter/material.dart';

import '../../art/palette.dart';
import '../../glossary/term_text.dart';
import '../../i18n/lang.dart';
import '../../money/money.dart';
import 'calc_widgets.dart';
import 'calculators.dart' show learnLink;

// ---------------------------------------------------------------- the cash-flow calendar

class CalendarSim extends StatefulWidget {
  const CalendarSim({super.key});
  @override
  State<CalendarSim> createState() => _CalendarSimState();
}

class _CalendarSimState extends State<CalendarSim> {
  double _start = 5000, _pay = 5500, _rent = 3500, _rentDay = 1, _light = 400, _lightDay = 10, _phone = 300,
      _phoneDay = 20, _food = 900, _bus = 250;

  @override
  Widget build(BuildContext context) {
    final events = [
      MoneyEvent(tr('Quincena', 'Payday'), _pay, const [15, 30]),
      MoneyEvent(tr('Renta', 'Rent'), -_rent, [_rentDay.round()]),
      MoneyEvent(tr('Luz y agua', 'Power and water'), -_light, [_lightDay.round()]),
      MoneyEvent(tr('Celular', 'Cell phone'), -_phone, [_phoneDay.round()]),
      MoneyEvent(tr('Despensa', 'Groceries'), -_food, const [1, 8, 15, 22, 29]),
      MoneyEvent(tr('Transporte', 'Transportation'), -_bus, const [1, 8, 15, 22, 29]),
    ];
    final days = cashFlow(_start, events);
    final short = [for (var d = 0; d < 30; d++) if (days[d] < 0) d + 1];
    final lowest = days.reduce(min);
    String day(double v) => tr('día ${v.round()}', 'day ${v.round()}');
    return CalcPage(
      say: short.isEmpty
          ? tr('Todos los días tienes con qué pagar. Al final del mes te quedan ${money(days.last)}.',
              'Every day you have enough to pay. At the end of the month you have ${money(days.last)} left.')
          : tr('Te faltaría dinero del día ${short.first} al ${short.last}. Al final del mes ${days.last >= 0 ? 'te quedan ${money(days.last)}' : 'te faltan ${money(-days.last)}'}.',
              "You'd be short of money from day ${short.first} to day ${short.last}. At the end of the month ${days.last >= 0 ? 'you have ${money(days.last)} left' : "you're ${money(-days.last)} short"}."),
      title: tr('El calendario del mes', "The month's calendar"),
      intro: tr('No solo importa cuánto entra y sale, sino cuándo. Mueve los días de los pagos y mira si algún día te '
          'quedas sin dinero.', "It's not just how much comes in and goes out, but when. Move the payment days and see if "
          'you run out of money on any day.'),
      controls: [
        ValueSlider(label: tr('Tienes al empezar el mes', 'You have at the start of the month'), value: _start, min: 0, max: 10000, step: 100, show: money,
            onChanged: (v) => setState(() => _start = v)),
        ValueSlider(label: tr('Cada quincena (días 15 y 30)', 'Each payday (days 15 and 30)'), value: _pay, min: 1000, max: 20000, step: 100, show: money,
            onChanged: (v) => setState(() => _pay = v)),
        const Divider(height: 20),
        ValueSlider(label: tr('Renta', 'Rent'), value: _rent, min: 0, max: 10000, step: 100, show: money,
            onChanged: (v) => setState(() => _rent = v)),
        ValueSlider(label: tr('La renta se paga el', 'Rent is paid on'), value: _rentDay, min: 1, max: 30, step: 1, show: day,
            onChanged: (v) => setState(() => _rentDay = v)),
        ValueSlider(label: tr('Luz y agua', 'Power and water'), value: _light, min: 0, max: 2000, step: 50, show: money,
            onChanged: (v) => setState(() => _light = v)),
        ValueSlider(label: tr('Se pagan el', 'They are paid on'), value: _lightDay, min: 1, max: 30, step: 1, show: day,
            onChanged: (v) => setState(() => _lightDay = v)),
        ValueSlider(label: tr('Celular', 'Cell phone'), value: _phone, min: 0, max: 1000, step: 50, show: money,
            onChanged: (v) => setState(() => _phone = v)),
        ValueSlider(label: tr('Se paga el', 'It is paid on'), value: _phoneDay, min: 1, max: 30, step: 1, show: day,
            onChanged: (v) => setState(() => _phoneDay = v)),
        const Divider(height: 20),
        ValueSlider(label: tr('Despensa cada semana', 'Groceries each week'), value: _food, min: 0, max: 4000, step: 50, show: money,
            onChanged: (v) => setState(() => _food = v)),
        ValueSlider(label: tr('Transporte cada semana', 'Transportation each week'), value: _bus, min: 0, max: 1500, step: 50, show: money,
            onChanged: (v) => setState(() => _bus = v)),
      ],
      results: [
        _MonthGrid(days: days, events: events),
        const SizedBox(height: 12),
        tiles(ResultTile(tr('Al final del mes', 'At the end of the month'), money(days.last), color: days.last >= 0 ? Pk.rightText : Pk.wrongText),
            ResultTile(tr('El día más justo', 'The tightest day'), money(lowest), color: lowest >= 0 ? Pk.text : Pk.wrongText)),
        if (short.isNotEmpty)
          Heads(tr('Te faltaría dinero ${short.length == 1 ? 'el día ${short.first}' : 'del día ${short.first} al ${short.last}'}. '
              '${days.last >= 0 ? 'Al final del mes sí alcanza: el problema es cuándo pagas. Prueba mover un pago a después de la quincena.' : 'En el mes sale más de lo que entra: hay que bajar algún gasto.'}',
              "You'd be short of money ${short.length == 1 ? 'on day ${short.first}' : 'from day ${short.first} to day ${short.last}'}. "
              '${days.last >= 0 ? 'By the end of the month there is enough: the problem is when you pay. Try moving a payment to after payday.' : 'Over the month more goes out than comes in: some expense has to come down.'}'))
        else
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Pk.rightSoft, borderRadius: BorderRadius.circular(18)),
            child: TermText(
              tr('Todos los días tienes con qué pagar. ${days.last > 0 ? 'Y te quedan ${money(days.last)} para ahorrar.' : ''}',
                  'Every day you have enough to pay. ${days.last > 0 ? 'And you have ${money(days.last)} left to save.' : ''}'),
              style: const TextStyle(color: Pk.rightText, fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        learnLink(context, 'mo-5'),
      ],
    );
  }
}

/// The month as a grid of 30 days: each shows what's left that day, amber when it's below zero, with a dot on the
/// days something is paid and a "+" on paydays
class _MonthGrid extends StatelessWidget {
  final List<double> days;
  final List<MoneyEvent> events;
  const _MonthGrid({required this.days, required this.events});

  String _short(double v) {
    final a = v.abs();
    final s = a >= 1000 ? '${(a / 1000).toStringAsFixed(a >= 10000 ? 0 : 1)}k' : '${a.round()}';
    return v < 0 ? '−$s' : s;
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: [for (var d = 0; d < 30; d++) if (days[d] < 0) d + 1].isEmpty
        ? tr('Calendario: todos los días alcanza', 'Calendar: there is enough every day')
        : tr('Calendario: algunos días falta dinero', 'Calendar: some days money runs short'),
    child: GridView.count(
      crossAxisCount: 6,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 6,
      crossAxisSpacing: 6,
      childAspectRatio: 0.95,
      children: [
        for (var d = 1; d <= 30; d++)
          (() {
            final inToday = events.where((e) => e.amount > 0 && e.days.contains(d)).isNotEmpty;
            final outToday = events.where((e) => e.amount < 0 && e.amount != 0 && e.days.contains(d)).isNotEmpty;
            final low = days[d - 1] < 0;
            return Container(
              decoration: BoxDecoration(
                color: low ? Pk.wrongSoft : Pk.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: inToday ? Pk.right : (low ? Pk.wrong : Colors.transparent), width: 2),
              ),
              padding: const EdgeInsets.all(4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('$d', style: const TextStyle(fontSize: 12, color: Pk.textSoft, fontWeight: FontWeight.w700)),
                      if (inToday)
                        const Icon(Icons.add_circle, size: 12, color: Pk.right)
                      else if (outToday)
                        const Icon(Icons.circle, size: 8, color: Pk.orange),
                    ],
                  ),
                  FittedBox(
                    child: Text(_short(days[d - 1]),
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: low ? Pk.wrongText : Pk.text)),
                  ),
                ],
              ),
            );
          })(),
      ],
    ),
  );
}

// ---------------------------------------------------------------- the debt list

class DebtListSim extends StatefulWidget {
  const DebtListSim({super.key});
  @override
  State<DebtListSim> createState() => _DebtListSimState();
}

class _DebtListSimState extends State<DebtListSim> {
  double _income = 12000;
  List<String> get _names => trOf(const ['Tarjeta de crédito', 'Préstamo personal', 'Crédito de tienda', 'Préstamo de un familiar'],
      const ['Credit card', 'Personal loan', 'Store credit', 'Loan from a relative']);
  final _icons = const [Icons.credit_card, Icons.request_quote_outlined, Icons.storefront_outlined, Icons.family_restroom];
  final _on = [true, true, true, false];
  final _owed = [15000.0, 8000.0, 4000.0, 2000.0];
  final _rate = [65.0, 35.0, 55.0, 0.0];
  final _min = [900.0, 600.0, 400.0, 200.0];

  @override
  Widget build(BuildContext context) {
    final open = [for (var i = 0; i < 4; i++) if (_on[i]) i];
    final owed = open.fold<double>(0, (t, i) => t + _owed[i]);
    final minimums = open.fold<double>(0, (t, i) => t + _min[i]);
    // Each month's interest, with its 16% IVA
    double monthly(int i) => _owed[i] * _rate[i] / 100 / 12 * (1 + ivaOnInterest);
    final interest = open.fold<double>(0, (t, i) => t + monthly(i));
    final share = _income > 0 ? minimums / _income * 100 : 0.0;
    return CalcPage(
      say: tr('Debes ${money(owed)} en total. Los pagos mínimos suman ${money(minimums)} al mes, y este mes se van '
          '${money(interest)} en intereses con IVA.', 'You owe ${money(owed)} in total. The minimum payments add up to '
          '${money(minimums)} a month, and this month ${money(interest)} goes on interest with IVA.'),
      title: tr('Mis deudas en una lista', 'My debts in one list'),
      intro: tr('Poner todas las deudas juntas ayuda a verlas de verdad: cuánto debes, cuánto pagas y cuánto se va en '
          'intereses. Enciende las que quieras y mueve los números.', 'Putting all your debts together helps you really '
          'see them: how much you owe, how much you pay and how much goes on interest. Turn on the ones you want and '
          'move the numbers.'),
      controls: [
        ValueSlider(label: tr('Entra al mes', 'Coming in each month'), value: _income, min: 2000, max: 50000, step: 500, show: money,
            onChanged: (v) => setState(() => _income = v)),
        for (var i = 0; i < 4; i++) ...[
          const Divider(height: 20),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: Icon(_icons[i], color: _on[i] ? Pk.gold : Pk.textSoft),
            title: Text(_names[i], style: const TextStyle(fontWeight: FontWeight.w700)),
            value: _on[i],
            onChanged: (v) => setState(() => _on[i] = v),
          ),
          if (_on[i]) ...[
            ValueSlider(label: tr('Debes', 'You owe'), value: _owed[i], min: 500, max: 60000, step: 500, show: money,
                onChanged: (v) => setState(() => _owed[i] = v)),
            ValueSlider(label: tr('Tasa de interés al año', 'Interest rate per year'), value: _rate[i], min: 0, max: 120, step: 1, show: pct,
                onChanged: (v) => setState(() => _rate[i] = v)),
            ValueSlider(label: tr('Pago mínimo al mes', 'Minimum payment per month'), value: _min[i], min: 0, max: 5000, step: 50, show: money,
                onChanged: (v) => setState(() => _min[i] = v)),
          ],
        ],
      ],
      results: [
        tiles(ResultTile(tr('Debes en total', 'You owe in total'), money(owed), color: Pk.orange), ResultTile(tr('Mínimos al mes', 'Minimums per month'), money(minimums))),
        tiles(ResultTile(tr('Intereses + IVA este mes', 'Interest + IVA this month'), money(interest), color: Pk.orange),
            ResultTile(tr('De cada \$100 que entran', 'Of every \$100 coming in'), tr('${money(share)} a deudas', '${money(share)} to debts'), color: share > 35 ? Pk.wrongText : Pk.text)),
        for (final i in open)
          if (_min[i] <= monthly(i))
            Heads(tr('${_names[i]}: el pago de ${money(_min[i])} no cubre ni los intereses con IVA '
                '(${money(monthly(i))} al mes). Así esa deuda crece.', "${_names[i]}: the ${money(_min[i])} payment doesn't "
                'even cover the interest with IVA (${money(monthly(i))} a month). So that debt grows.')),
        if (share > 35)
          Heads(tr('Más de una tercera parte de lo que entra se va en deudas. Eso deja poco para lo de todos los días.',
              'More than a third of what comes in goes on debts. That leaves little for everyday things.')),
        const SizedBox(height: 4),
        learnLink(context, 'mo-6'),
      ],
    );
  }
}
