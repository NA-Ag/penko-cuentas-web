// calculators.dart — "Simuladores": the money lessons as things to play with. Every value is moved along a line
// (nothing is typed, nothing is saved), every number comes from the tested money engine, and each simulator links back
// to the lesson that explains it. Ideas from the old Fini app: the loan and card tables, paying a bit more, and the
// avalanche and snowball ways out of debt.
import 'dart:math';

import 'package:flutter/material.dart';

import '../../art/palette.dart';
import '../../i18n/lang.dart';
import '../../glossary/term_text.dart';
import '../../money/money.dart';
import '../../ui/pixel_ui.dart';
import '../../wayfinding/wayfinding.dart';
import '../../ai/tutor.dart';
import '../../money/receipt.dart';
import '../course.dart';
import '../receipt_screen.dart';
import '../wellbeing_screen.dart';
import 'calc_widgets.dart';
import 'month_sims.dart';

class Simulator {
  final Place place; // its sign (places.dart): pictogram, name and one line
  final IconData icon;
  final Color color;
  final String lesson; // the lesson that explains it
  final Widget Function() open;
  const Simulator(this.place, this.icon, this.color, this.lesson, this.open);

  String get title => place.name;
  String get about => place.about;
}

/// A simulator with its name and line from its sign
Simulator _sim(String id, IconData icon, Color color, String lesson, Widget Function() open) => Simulator(simPlaces[id]!, icon, color, lesson, open);

List<Simulator> get simulators => [
  _sim('loan', Icons.request_quote_outlined, Pk.sea, 'mo-8', () => const LoanSim()),
  _sim('card', Icons.credit_card, Pk.coral, 'mo-6', () => const CardSim()),
  _sim('debts', Icons.landslide_outlined, Pk.plum, 'mo-6', () => const DebtsSim()),
  _sim('savings', Icons.savings_outlined, Pk.grassDark, 'mo-7', () => const SavingsSim()),
  _sim('budget', Icons.pie_chart_outline, Pk.orange, 'mo-5', () => const BudgetSim()),
  _sim('calendar', Icons.calendar_month_outlined, Pk.sun, 'mo-5', () => const CalendarSim()),
  _sim('debt_list', Icons.format_list_bulleted, Pk.coral, 'mo-6', () => const DebtListSim()),
];

/// The tab: one card per simulator
class CalculatorsScreen extends StatelessWidget {
  const CalculatorsScreen({super.key});

  /// What the "read this screen" button reads on this tab
  static List<String> readLines() => [tabPlaces[1].name, _intro, for (final p in simPlaces.values) ...p.lines];

  static String get _intro => tr(
    'Mueve los números y mira qué pasa. Son ejemplos: no escribas tus datos reales.',
    "Move the numbers and see what happens. They're examples: don't enter your real details.",
  );

  @override
  Widget build(BuildContext context) {
    final wellbeing = simPlaces['wellbeing']!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        PlaceHeading(tabPlaces[1], colour: placeColour('tab.sims')),
        const SizedBox(height: 4),
        Text(_intro, style: const TextStyle(color: Pk.textSoft, fontSize: 15)),
        const SizedBox(height: 16),
        // The well-being check, for adults: before and after learning
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Hear.place(
            wellbeing,
            child: Semantics(
              button: true,
              label: tr('¿Cómo estoy con mi dinero? Siete preguntas para adultos.', 'How am I doing with money? Seven questions for adults.'),
              excludeSemantics: true,
              child: GestureDetector(
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WellbeingScreen())),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [Pk.gold, Color.lerp(Pk.gold, Pk.orange, 0.45)!]),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      PictogramTile(wellbeing.picture, size: 56, frame: Pk.onGold),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              wellbeing.name,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Pk.onGold),
                            ),
                            Text(wellbeing.about, style: const TextStyle(fontSize: 14, color: Pk.onGold)),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: Pk.onGold),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        for (final s in simulators)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Hear.place(
              s.place,
              child: Semantics(
                button: true,
                label: '${s.title}. ${s.about}',
                excludeSemantics: true,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => s.open())),
                  child: PkPanel(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        PictogramTile(s.place.picture, size: 60, frame: s.color),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                              Text(s.about, style: const TextStyle(color: Pk.textSoft, fontSize: 14)),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Pk.textSoft),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// A link from a simulator to the lesson that explains it
Widget learnLink(BuildContext context, String lessonId) {
  final lesson = course.expand((u) => u.lessons).firstWhere((l) => l.id == lessonId);
  return Padding(
    padding: const EdgeInsets.only(top: 6),
    child: PkButton(
      tr('Aprende: ', 'Learn: ') + lesson.title,
      color: Pk.note,
      textColor: Pk.gold,
      leading: const Icon(Icons.school_outlined, color: Pk.gold),
      onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => lesson.open())),
    ),
  );
}

// ---------------------------------------------------------------- a loan

class LoanSim extends StatefulWidget {
  const LoanSim({super.key});
  @override
  State<LoanSim> createState() => _LoanSimState();
}

class _LoanSimState extends State<LoanSim> {
  double _amount = 20000, _rate = 45, _months = 12, _fee = 2;

  @override
  Widget build(BuildContext context) {
    // What you pay includes the IVA on each month's interest; the CAT, as Banxico defines it, doesn't
    final pay = paymentFor(_amount, _rate / 12 * (1 + ivaOnInterest), _months.round());
    final total = pay * _months.round();
    final interest = total - _amount;
    final feeCost = _amount * _fee / 100;
    final yearly = cat(_amount - feeCost, List.filled(_months.round(), paymentFor(_amount, _rate / 12, _months.round())));
    return CalcPage(
      title: tr('Un préstamo', 'A loan'),
      intro: tr(
        'Mueve el monto, la tasa y los meses. Mira cuánto pagas al mes y cuánto te cuesta en total.',
        'Move the amount, the rate and the months. See how much you pay each month and what it costs you in total.',
      ),
      controls: [
        ValueSlider(
          label: tr('Te prestan', 'You borrow'),
          value: _amount,
          min: 1000,
          max: 100000,
          step: 1000,
          show: money,
          onChanged: (v) => setState(() => _amount = v),
        ),
        ValueSlider(
          label: tr('Tasa de interés al año', 'Interest rate per year'),
          value: _rate,
          min: 5,
          max: 120,
          step: 1,
          show: pct,
          onChanged: (v) => setState(() => _rate = v),
        ),
        ValueSlider(
          label: tr('Plazo', 'Term'),
          value: _months,
          min: 3,
          max: 60,
          step: 1,
          show: (v) => monthsText(v.round()),
          onChanged: (v) => setState(() => _months = v),
        ),
        ValueSlider(
          label: tr('Comisión por apertura', 'Opening fee'),
          value: _fee,
          min: 0,
          max: 5,
          step: 0.5,
          show: pct,
          onChanged: (v) => setState(() => _fee = v),
        ),
      ],
      results: [
        // As Banxico requires: one decimal and "sin IVA"
        tiles(
          ResultTile(tr('Pagas al mes', 'You pay each month'), money(pay), color: Pk.gold),
          ResultTile(tr('CAT estimado', 'Estimated CAT'), catText(yearly)),
        ),
        tiles(
          ResultTile(tr('Pagas en total', 'You pay in total'), money(total + feeCost)),
          ResultTile(tr('Intereses, IVA y comisión', 'Interest, IVA and fee'), money(interest + feeCost), color: Pk.orange),
        ),
        moneyResult(tr('Lo que pagas cada mes, en billetes y monedas', 'What you pay each month, in bills and coins'), pay),
        SplitBar(
          firstLabel: tr('Lo prestado', 'Borrowed'),
          first: _amount,
          secondLabel: tr('Lo que cuesta', 'What it costs'),
          second: interest + feeCost,
        ),
        learnLink(context, 'mo-8'),
      ],
      say: tr(
        'Pagas ${money(pay)} al mes, ${money(total + feeCost)} en total. De eso, ${money(interest + feeCost)} son '
            'intereses, IVA y comisión. El CAT estimado es de ${catText(yearly)}.',
        'You pay ${money(pay)} a month, ${money(total + feeCost)} in total. Of that, ${money(interest + feeCost)} is '
            'interest, IVA and the fee. The estimated CAT is ${catText(yearly)}.',
      ),
      note: tr(
        'El pago al mes incluye el 16% de IVA sobre los intereses. CAT estimado con fines educativos, calculado con '
            'la metodología de Banco de México, sin IVA. No es una oferta ni sustituye el CAT que te informe la institución.',
        "The monthly payment includes 16% IVA (Mexico's value-added tax) on the interest. Estimated CAT (total annual "
            "cost, Mexico's version of APR) for learning purposes, worked out with Banco de México's method, excluding IVA. "
            'It is not an offer and does not replace the CAT the lender gives you.',
      ),
    );
  }
}

// ---------------------------------------------------------------- a credit card

class CardSim extends StatefulWidget {
  const CardSim({super.key});
  @override
  State<CardSim> createState() => _CardSimState();
}

class _CardSimState extends State<CardSim> {
  double _debt = 15000, _rate = 60, _pay = 1200, _extra = 500, _limit = 30000;

  /// Paying a fixed amount each month; interest carries 16% IVA
  ({int months, double interest})? _payoff(double payment) {
    final rows = schedule(_debt, _rate / 12 * (1 + ivaOnInterest), payment);
    if (rows == null || rows.length >= 600) return null;
    return (months: rows.length, interest: rows.fold<double>(0, (t, r) => t + r.interest));
  }

  @override
  Widget build(BuildContext context) {
    final interest = _debt * _rate / 100 / 12, iva = interest * ivaOnInterest, monthly = interest + iva;
    final now = _payoff(_pay), more = _payoff(_pay + _extra);
    final minimum = minimumPaymentPlan(_debt, _rate, _limit);
    return CalcPage(
      title: tr('Tarjeta de crédito', 'Credit card'),
      intro: tr(
        'De cada pago, primero se cubren los intereses. Mira qué pasa si pagas un poco más cada mes.',
        'From each payment, the interest is covered first. See what happens if you pay a bit more each month.',
      ),
      controls: [
        ValueSlider(
          label: tr('Lo que debes', 'What you owe'),
          value: _debt,
          min: 1000,
          max: 80000,
          step: 500,
          show: money,
          onChanged: (v) => setState(() => _debt = v),
        ),
        ValueSlider(
          label: tr('Tasa de interés al año', 'Interest rate per year'),
          value: _rate,
          min: 20,
          max: 120,
          step: 1,
          show: pct,
          onChanged: (v) => setState(() => _rate = v),
        ),
        ValueSlider(
          label: tr('Pagas al mes', 'You pay each month'),
          value: _pay,
          min: 100,
          max: 10000,
          step: 50,
          show: money,
          onChanged: (v) => setState(() => _pay = v),
        ),
        ValueSlider(
          label: tr('Y si pagas además', 'And if you also pay'),
          value: _extra,
          min: 0,
          max: 5000,
          step: 50,
          show: money,
          onChanged: (v) => setState(() => _extra = v),
        ),
        ValueSlider(
          label: tr('Límite de crédito de la tarjeta', "The card's credit limit"),
          value: _limit,
          min: 5000,
          max: 150000,
          step: 1000,
          show: money,
          onChanged: (v) => setState(() => _limit = v),
        ),
      ],
      results: [
        tiles(
          ResultTile(tr('Interés + IVA del primer mes', "First month's interest + IVA"), money(monthly), color: Pk.orange),
          ResultTile(tr('Baja tu deuda', 'Comes off your debt'), money(max(0, _pay - monthly))),
        ),
        // What paying only the minimum costs (Banxico's rule for the minimum)
        Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Pk.wrongSoft, borderRadius: BorderRadius.circular(18)),
          child: TermText(
            minimum.neverEnds
                ? tr(
                    'Si pagas solo el mínimo (${money(minimum.firstMinimum)} el primer mes), esta deuda no se termina en 50 años.',
                    'If you pay only the minimum (${money(minimum.firstMinimum)} the first month), this debt is not paid off in 50 years.',
                  )
                : tr(
                    'Si pagas solo el mínimo (${money(minimum.firstMinimum)} el primer mes, y cada vez menos), tardas '
                        '${monthsText(minimum.months)} y pagas ${money(minimum.interest)} de intereses con IVA.',
                    'If you pay only the minimum (${money(minimum.firstMinimum)} the first month, and less each time), it '
                        'takes you ${monthsText(minimum.months)} and you pay ${money(minimum.interest)} in interest with IVA.',
                  ),
            style: const TextStyle(color: Pk.wrongText, fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ),
        if (now == null)
          Heads(
            tr(
              'Con ${money(_pay)} al mes casi no bajas la deuda: los intereses se comen el pago. Prueba con un pago más alto.',
              'With ${money(_pay)} a month your debt hardly goes down: the interest eats up the payment. Try a higher payment.',
            ),
          )
        else ...[
          tiles(
            ResultTile(tr('Terminas de pagar en', "You're paid off in"), monthsText(now.months)),
            ResultTile(tr('Pagas de intereses', 'You pay in interest'), money(now.interest), color: Pk.orange),
          ),
          if (more != null && _extra > 0)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Pk.rightSoft, borderRadius: BorderRadius.circular(18)),
              child: TermText(
                tr(
                  'Pagando ${money(_extra)} más al mes terminas en ${monthsText(more.months)} y te ahorras '
                      '${money(now.interest - more.interest)} de intereses.',
                  'Paying ${money(_extra)} more a month, you finish in ${monthsText(more.months)} and save '
                      '${money(now.interest - more.interest)} in interest.',
                ),
                style: const TextStyle(color: Pk.rightText, fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          SplitBar(
            firstLabel: tr('Lo que debías', 'What you owed'),
            first: _debt,
            secondLabel: tr('Intereses con IVA', 'Interest with IVA'),
            second: now.interest,
          ),
        ],
        learnLink(context, 'mo-6'),
      ],
      say: tr(
        'El primer mes, ${money(monthly)} de tu pago se van en intereses con IVA. '
            '${now == null ? 'Con ese pago la deuda casi no baja.' : 'Terminas de pagar en ${monthsText(now.months)} y pagas ${money(now.interest)} de intereses.'} '
            '${minimum.neverEnds ? '' : 'Pagando solo el mínimo tardarías ${monthsText(minimum.months)}.'}',
        'The first month, ${money(monthly)} of your payment goes on interest with IVA. '
            '${now == null ? 'With that payment the debt hardly goes down.' : "You're paid off in ${monthsText(now.months)} and pay ${money(now.interest)} in interest."} '
            '${minimum.neverEnds ? '' : 'Paying only the minimum, it would take you ${monthsText(minimum.months)}.'}',
      ),
      note: tr(
        'Los intereses llevan 16% de IVA. El pago mínimo se calcula como lo indica Banco de México: lo mayor entre '
            '1.5% de lo que debes más intereses e IVA, o 1.25% de tu límite de crédito (cálculo aproximado).',
        "Interest carries 16% IVA (Mexico's value-added tax). The minimum payment is worked out the way Banco de México "
            '(Banxico) sets it: the larger of 1.5% of what you owe plus interest and IVA, or 1.25% of your credit limit (an '
            'approximate calculation).',
      ),
    );
  }
}

// ---------------------------------------------------------------- several debts

class DebtsSim extends StatefulWidget {
  const DebtsSim({super.key});
  @override
  State<DebtsSim> createState() => _DebtsSimState();
}

class _DebtsSimState extends State<DebtsSim> {
  // Three made-up debts: the balance and the yearly rate of each
  List<String> get _names => trOf(const ['Tarjeta', 'Préstamo', 'Tienda'], const ['Card', 'Loan', 'Store']);
  final _balance = [18000.0, 9000.0, 3000.0];
  final _rate = [65.0, 35.0, 50.0];
  double _budget = 3000;

  /// The least each debt asks for: its interest plus 2% of what's owed
  double _minimum(int i) => (_balance[i] * (_rate[i] / 100 / 12 * (1 + ivaOnInterest) + 0.02)).ceilToDouble();

  @override
  Widget build(BuildContext context) {
    // The interest each debt charges carries 16% IVA
    final debts = [for (var i = 0; i < 3; i++) DebtLine(_names[i], _balance[i], _rate[i] * (1 + ivaOnInterest), _minimum(i))];
    final minimums = debts.fold<double>(0, (t, d) => t + d.minimum);
    final ava = payoffPlan(debts, _budget, PayoffOrder.avalanche);
    final snow = payoffPlan(debts, _budget, PayoffOrder.snowball);
    Widget plan(String name, String how, PayoffPlan p, Color c) => Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Pk.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: c.withValues(alpha: 0.6), width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: TextStyle(color: c, fontSize: 17, fontWeight: FontWeight.w800),
            ),
            Text(how, style: const TextStyle(color: Pk.textSoft, fontSize: 13)),
            const SizedBox(height: 10),
            Text(monthsText(p.months), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            Text(
              tr('${money(p.interest)} de intereses', '${money(p.interest)} in interest'),
              style: const TextStyle(color: Pk.orange, fontSize: 14, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            // The order the debts get paid off
            for (final i in List.generate(3, (i) => i)..sort((a, b) => p.paidOff[a].compareTo(p.paidOff[b])))
              Text(
                tr('Mes ${p.paidOff[i]}: ${_names[i]} pagada', 'Month ${p.paidOff[i]}: ${_names[i]} paid off'),
                style: const TextStyle(color: Pk.textSoft, fontSize: 13),
              ),
          ],
        ),
      ),
    );
    return CalcPage(
      say: ava.neverEnds || snow.neverEnds
          ? tr(
              'Con lo que puedes pagar, las deudas no terminan. Sube lo que puedes pagar.',
              'With what you can pay, the debts never end. Raise what you can pay.',
            )
          : tr(
              'Con la avalancha terminas en ${monthsText(ava.months)} y pagas ${money(ava.interest)} de intereses. Con la bola '
                  'de nieve, en ${monthsText(snow.months)} y ${money(snow.interest)}.',
              'With the avalanche you finish in ${monthsText(ava.months)} and pay ${money(ava.interest)} in interest. With the '
                  'snowball, in ${monthsText(snow.months)} and ${money(snow.interest)}.',
            ),
      title: tr('Salir de deudas', 'Getting out of debt'),
      intro: tr(
        'Cada mes pagas lo mínimo de cada deuda, y lo que sobra va a una sola. ¿A cuál primero?',
        'Each month you pay the minimum on each debt, and what is left over goes to just one. Which one first?',
      ),
      controls: [
        for (var i = 0; i < 3; i++) ...[
          if (i > 0) const Divider(height: 20),
          ValueSlider(
            label: tr('${_names[i]}: debes', '${_names[i]}: you owe'),
            value: _balance[i],
            min: 1000,
            max: 50000,
            step: 500,
            show: money,
            onChanged: (v) => setState(() => _balance[i] = v),
          ),
          ValueSlider(
            label: tr('${_names[i]}: tasa al año', '${_names[i]}: rate per year'),
            value: _rate[i],
            min: 10,
            max: 120,
            step: 1,
            show: pct,
            onChanged: (v) => setState(() => _rate[i] = v),
          ),
        ],
        const Divider(height: 20),
        ValueSlider(
          label: tr('Puedes pagar al mes', 'You can pay each month'),
          value: _budget,
          min: 500,
          max: 15000,
          step: 100,
          show: money,
          onChanged: (v) => setState(() => _budget = v),
        ),
      ],
      results: [
        if (ava.neverEnds || snow.neverEnds)
          Heads(
            _budget < minimums
                ? tr(
                    'Los pagos mínimos suman ${money(minimums)}: con ${money(_budget)} no alcanza. Sube lo que puedes pagar.',
                    'The minimum payments add up to ${money(minimums)}: ${money(_budget)} is not enough. Raise what you can pay.',
                  )
                : tr(
                    'Con este pago las deudas no terminan. Sube lo que puedes pagar.',
                    'With this payment the debts never end. Raise what you can pay.',
                  ),
          )
        else ...[
          Row(
            children: [
              plan(tr('Avalancha', 'Avalanche'), tr('Primero la tasa más alta', 'Highest rate first'), ava, Pk.sea),
              const SizedBox(width: 10),
              plan(tr('Bola de nieve', 'Snowball'), tr('Primero la deuda más chica', 'Smallest debt first'), snow, Pk.plum),
            ],
          ),
          const SizedBox(height: 10),
          TermText(
            snow.interest - ava.interest >= 1
                ? tr(
                    'La avalancha te ahorra ${money(snow.interest - ava.interest)}. La bola de nieve te da pequeñas victorias '
                        'antes, y eso a muchos les ayuda a no rendirse.',
                    'The avalanche saves you ${money(snow.interest - ava.interest)}. The snowball gives you small wins sooner, '
                        'and that helps many people not to give up.',
                  )
                : tr(
                    'Aquí las dos salen casi igual. Escoge la que te ayude a no rendirte.',
                    'Here the two come out almost the same. Pick the one that helps you not to give up.',
                  ),
            style: const TextStyle(fontSize: 15, height: 1.35),
          ),
        ],
        learnLink(context, 'mo-6'),
      ],
    );
  }
}

// ---------------------------------------------------------------- savings

class SavingsSim extends StatefulWidget {
  const SavingsSim({super.key});
  @override
  State<SavingsSim> createState() => _SavingsSimState();
}

class _SavingsSimState extends State<SavingsSim> {
  double _start = 1000, _monthly = 500, _rate = 10, _years = 5;

  @override
  Widget build(BuildContext context) {
    final months = (_years * 12).round();
    final growth = savingsGrowth(_start, _monthly, _rate, months);
    final put = _start + _monthly * months;
    final end = growth.isEmpty ? _start : growth.last;
    return CalcPage(
      say: tr(
        'Al final tienes ${money(end)}. Pusiste ${money(put)} y ganaste ${money(end - put)} de intereses.',
        'In the end you have ${money(end)}. You put in ${money(put)} and earned ${money(end - put)} in interest.',
      ),
      title: tr('Ahorrar', 'Saving'),
      intro: tr(
        'Si ahorras un poco cada mes en una cuenta con intereses, tus intereses también ganan intereses.',
        'If you save a little each month in an account with interest, your interest earns interest too.',
      ),
      controls: [
        ValueSlider(
          label: tr('Empiezas con', 'You start with'),
          value: _start,
          min: 0,
          max: 50000,
          step: 500,
          show: money,
          onChanged: (v) => setState(() => _start = v),
        ),
        ValueSlider(
          label: tr('Ahorras cada mes', 'You save each month'),
          value: _monthly,
          min: 0,
          max: 5000,
          step: 100,
          show: money,
          onChanged: (v) => setState(() => _monthly = v),
        ),
        ValueSlider(
          label: tr('Interés al año (ejemplo)', 'Interest per year (example)'),
          value: _rate,
          min: 0,
          max: 15,
          step: 0.5,
          show: pct,
          onChanged: (v) => setState(() => _rate = v),
        ),
        ValueSlider(
          label: tr('Durante', 'For'),
          value: _years,
          min: 1,
          max: 20,
          step: 1,
          show: (v) => monthsText((v * 12).round()),
          onChanged: (v) => setState(() => _years = v),
        ),
      ],
      results: [
        tiles(
          ResultTile(tr('Al final tienes', 'In the end you have'), money(end), color: Pk.gold),
          ResultTile(tr('Ganaste de intereses', 'You earned in interest'), money(end - put), color: Pk.rightText),
        ),
        moneyResult(tr('Lo que tienes al final, en billetes y monedas', 'What you have in the end, in bills and coins'), end),
        SplitBar(
          firstLabel: tr('Lo que pusiste', 'What you put in'),
          first: put,
          secondLabel: tr('Intereses', 'Interest'),
          second: end - put,
          secondColor: Pk.right,
        ),
        learnLink(context, 'mo-7'),
      ],
      note: tr(
        'La tasa es un ejemplo, no la de ningún producto. Las tasas reales cambian; consúltalas en la fuente oficial.',
        'The rate is an example, not that of any product. Real rates change; check them at the official source.',
      ),
    );
  }
}

// ---------------------------------------------------------------- a budget

class BudgetSim extends StatefulWidget {
  const BudgetSim({super.key});
  @override
  State<BudgetSim> createState() => _BudgetSimState();
}

class _BudgetSimState extends State<BudgetSim> {
  double _income = 12000;
  List<String> get _names => trOf(
    const ['Vivienda', 'Comida', 'Transporte', 'Luz, agua y teléfono', 'Otros gastos'],
    const ['Housing', 'Food', 'Transportation', 'Power, water and phone', 'Other expenses'],
  );
  final _icons = const [
    Icons.home_outlined,
    Icons.restaurant_outlined,
    Icons.directions_bus_outlined,
    Icons.lightbulb_outline,
    Icons.shopping_bag_outlined,
  ];
  final _spend = [3500.0, 3500.0, 1000.0, 800.0, 1500.0];
  static const _colors = [Pk.sea, Pk.orange, Pk.plum, Pk.sun, Pk.coral];
  bool _tutor = false; // reading receipts needs the tutor model
  String? _added; // what the last receipt added, said back to the person

  @override
  void initState() {
    super.initState();
    Tutor.instance.available().then((v) {
      if (mounted) setState(() => _tutor = v);
    });
  }

  /// A receipt's groups go onto the matching lines of the budget
  Future<void> _receipt() async {
    final groups = await Navigator.of(context).push<Map<Spend, double>>(MaterialPageRoute(builder: (_) => const ReceiptScreen()));
    if (groups == null || !mounted) return;
    const line = {Spend.food: 1, Spend.transport: 2, Spend.bills: 3, Spend.home: 4, Spend.other: 4};
    setState(() {
      for (final e in groups.entries) {
        _spend[line[e.key]!] = min(20000, _spend[line[e.key]!] + e.value);
      }
      _added = '${tr('Sumé tu ticket:', 'I added your receipt:')} ${groups.entries.map((e) => '${spendNames[e.key]} ${money(e.value)}').join(', ')}.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final spent = _spend.fold<double>(0, (t, v) => t + v);
    final left = _income - spent;
    return CalcPage(
      say: tr(
        'Gastas ${money(spent)} al mes. ${left >= 0 ? 'Te quedan ${money(left)}.' : 'Te faltan ${money(-left)}.'}',
        'You spend ${money(spent)} a month. ${left >= 0 ? 'You have ${money(left)} left.' : "You're ${money(-left)} short."}',
      ),
      title: tr('Mi presupuesto', 'My budget'),
      intro: tr(
        'Apunta lo que entra y lo que sale. Lo que queda es lo que puedes ahorrar.',
        'Write down what comes in and what goes out. What is left is what you can save.',
      ),
      controls: [
        if (_tutor) ...[
          PkButton(
            tr('Leer un ticket con la cámara', 'Read a receipt with the camera'),
            color: Pk.note,
            textColor: Pk.gold,
            leading: const Icon(Icons.receipt_long_outlined, color: Pk.gold),
            onPressed: _receipt,
          ),
          if (_added != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_added!, style: const TextStyle(color: Pk.rightText)),
            ),
          const Divider(height: 24),
        ],
        ValueSlider(
          label: tr('Entra al mes', 'Coming in each month'),
          value: _income,
          min: 2000,
          max: 50000,
          step: 500,
          show: money,
          onChanged: (v) => setState(() => _income = v),
        ),
        const Divider(height: 20),
        for (var i = 0; i < _names.length; i++)
          ValueSlider(
            label: _names[i],
            value: _spend[i],
            min: 0,
            max: 20000,
            step: 100,
            show: money,
            onChanged: (v) => setState(() => _spend[i] = v),
          ),
      ],
      results: [
        tiles(
          ResultTile(tr('Gastas', 'You spend'), money(spent), color: Pk.orange),
          ResultTile(
            left >= 0 ? tr('Te queda', 'You have left') : tr('Te falta', "You're short"),
            money(left.abs()),
            color: left >= 0 ? Pk.rightText : Pk.wrongText,
          ),
        ),
        if (left >= 0) moneyResult(tr('Lo que te queda, en billetes y monedas', 'What you have left, in bills and coins'), left),
        // Where the money goes, as one bar
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 22,
            child: Row(
              children: [
                for (var i = 0; i < _spend.length; i++)
                  if (_spend[i] > 0)
                    Expanded(
                      flex: _spend[i].round(),
                      child: Container(color: _colors[i]),
                    ),
                if (left > 0)
                  Expanded(
                    flex: left.round(),
                    child: Container(color: Pk.right),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 14,
          runSpacing: 6,
          children: [
            for (var i = 0; i < _names.length; i++)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_icons[i], size: 16, color: _colors[i]),
                  const SizedBox(width: 4),
                  Text('${_income > 0 ? (_spend[i] / _income * 100).round() : 0}%', style: const TextStyle(color: Pk.textSoft)),
                ],
              ),
          ],
        ),
        const SizedBox(height: 10),
        if (left < 0) Heads(tr('Sale más de lo que entra. ¿Qué gasto podrías bajar?', 'More goes out than comes in. Which expense could you lower?')),
        if (left > 0)
          TermText(
            tr(
              'Si guardas ${money(left)} cada mes, en un año son ${money(left * 12)}.',
              'If you put away ${money(left)} each month, in a year that is ${money(left * 12)}.',
            ),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Pk.rightText),
          ),
        learnLink(context, 'mo-5'),
      ],
    );
  }
}
