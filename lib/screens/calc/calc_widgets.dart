// calc_widgets.dart — the parts every simulator shares: a value you move along a line, result tiles, a bar that splits
// what you pay into "what you borrowed" and "interest", and the short note that it's practice with made-up numbers.
import 'package:flutter/material.dart';

import '../../art/palette.dart';
import '../../art/penko.dart';
import '../../glossary/term_text.dart';
import '../../i18n/lang.dart';
import '../../money/money.dart';
import '../../ui/money_pile.dart';
import '../../ui/pixel_ui.dart';
import '../../wayfinding/wayfinding.dart';

/// The frame of a simulator: title, Penko's one-line explanation, the controls, the results and the note
class CalcPage extends StatelessWidget {
  final String title;
  final String intro;
  final List<Widget> controls;
  final List<Widget> results;
  final String? note; // an extra line under the usual note (e.g. about the CAT)
  final String? say; // the result in plain words, read aloud by the speaker button
  const CalcPage({
    super.key,
    required this.title,
    required this.intro,
    required this.controls,
    required this.results,
    this.note,
    this.say,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(title),
      // Penko reads the screen: its name, her explanation, each value as it's set now, and the result
      actions: [
        ReadScreenButton(
          lines: () => [
            title,
            intro,
            for (final c in controls.whereType<ValueSlider>()) '${c.label}: ${c.show(c.value)}',
            ?say,
          ],
        ),
      ],
    ),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Penko(pose: PenkoPose.talk, size: 48),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Pk.dialog, borderRadius: BorderRadius.circular(18)),
                child: TermText(intro, style: const TextStyle(color: Pk.onDialog, fontSize: 16, fontWeight: FontWeight.w600, height: 1.3)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Switches paint on the nearest Material, so give them one inside the card
        PkPanel(child: Material(type: MaterialType.transparency, child: Column(children: controls))),
        const SizedBox(height: 16),
        ...results,
        const SizedBox(height: 20),
        TermText(
          tr('Es una simulación con números de ejemplo: muévelos para ver qué pasa. Nada se guarda. '
                  'Contenido educativo; no es asesoría financiera.',
                  'This is a simulation with example numbers: move them to see what happens. Nothing is saved. '
                  'Educational content; not financial advice.') +
              (note == null ? '' : '\n$note'),
          style: const TextStyle(color: Pk.textSoft, fontSize: 13, height: 1.35),
        ),
      ],
    ),
  );
}

/// A value moved along a line, with its name and how it reads ("$12,000", "36%", "18 meses")
class ValueSlider extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final double step;
  final String Function(double) show;
  final ValueChanged<double> onChanged;
  const ValueSlider({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.step,
    required this.show,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: TermText(label, style: const TextStyle(color: Pk.textSoft, fontSize: 15, fontWeight: FontWeight.w600))),
            // Tap the value to type an exact number instead of sliding
            Semantics(
              button: true,
              label: '$label: ${show(value)}. ${tr('Toca para escribir otro número.', 'Tap to type another number.')}',
              excludeSemantics: true,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => _type(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: Pk.gold.withValues(alpha: 0.5), width: 2)),
                  ),
                  child: Text(show(value), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Pk.text)),
                ),
              ),
            ),
          ],
        ),
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          divisions: ((max - min) / step).round(),
          semanticFormatterCallback: show,
          onChanged: onChanged,
        ),
      ],
    ),
  );
}

extension on ValueSlider {
  /// Asks for an exact number, kept within the slider's range
  Future<void> _type(BuildContext context) async {
    final field = TextEditingController(text: value % 1 == 0 ? '${value.toInt()}' : '$value');
    final typed = await showDialog<double>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text(label),
        content: TextField(
          controller: field,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(helperText: tr('Entre ${show(min)} y ${show(max)}', 'Between ${show(min)} and ${show(max)}')),
          onSubmitted: (t) => Navigator.of(d).pop(double.tryParse(t.replaceAll(',', ''))),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(d).pop(), child: Text(tr('Cancelar', 'Cancel'))),
          TextButton(
            onPressed: () => Navigator.of(d).pop(double.tryParse(field.text.replaceAll(',', ''))),
            child: Text(tr('Listo', 'Done')),
          ),
        ],
      ),
    );
    if (typed != null) onChanged(typed.clamp(min, max).toDouble());
  }
}

/// A result: a big number with what it means
class ResultTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const ResultTile(this.label, this.value, {super.key, this.color = Pk.text});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Pk.card, borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TermText(label, style: const TextStyle(color: Pk.textSoft, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: color)),
          ),
        ],
      ),
    ),
  );
}

/// A key result shown as money too: [amount] as a small pile of coins and bills, under [caption]
Widget moneyResult(String caption, double amount) => amount < 1
    ? const SizedBox.shrink()
    : Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: PkPanel(padding: const EdgeInsets.all(14), shadow: 0, child: MoneyPile(amount, caption: caption)),
      );

/// Two result tiles side by side
Widget tiles(ResultTile a, ResultTile b) => Padding(
  padding: const EdgeInsets.only(bottom: 10),
  child: Row(children: [a, const SizedBox(width: 10), b]),
);

/// One bar split in two: [first] and [second], with their names, as shares of the whole
class SplitBar extends StatelessWidget {
  final String firstLabel;
  final double first;
  final String secondLabel;
  final double second;
  final Color firstColor;
  final Color secondColor;
  const SplitBar({
    super.key,
    required this.firstLabel,
    required this.first,
    required this.secondLabel,
    required this.second,
    this.firstColor = Pk.sea,
    this.secondColor = Pk.orange,
  });

  @override
  Widget build(BuildContext context) {
    final total = first + second;
    final share = total <= 0 ? 0.0 : first / total;
    Widget key(Color c, String label, double v) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 6),
        Text('$label ${pesos(v.roundToDouble())}', style: const TextStyle(fontSize: 14, color: Pk.textSoft)),
      ],
    );
    return Semantics(
      label: '$firstLabel ${pesos(first.roundToDouble())}, $secondLabel ${pesos(second.roundToDouble())}',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: 22,
                child: Row(
                  children: [
                    if (share > 0) Expanded(flex: (share * 1000).round(), child: Container(color: firstColor)),
                    if (share < 1) Expanded(flex: ((1 - share) * 1000).round(), child: Container(color: secondColor)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(spacing: 16, runSpacing: 4, children: [key(firstColor, firstLabel, first), key(secondColor, secondLabel, second)]),
          ],
        ),
      ),
    );
  }
}

/// A gentle warning card (amber, never red)
class Heads extends StatelessWidget {
  final String text;
  const Heads(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: Pk.wrongSoft, borderRadius: BorderRadius.circular(18)),
    child: Row(
      children: [
        const Icon(Icons.info_outline, color: Pk.wrongText),
        const SizedBox(width: 10),
        Expanded(child: TermText(text, style: const TextStyle(color: Pk.wrongText, fontSize: 15, fontWeight: FontWeight.w600))),
      ],
    ),
  );
}

/// How values read
String money(double v) => pesos(v.roundToDouble());
String pct(double v) => '${v % 1 == 0 ? v.toInt() : v.toStringAsFixed(1)}%';
String monthsText(int m) {
  String months(int n) => '$n ${n == 1 ? tr('mes', 'month') : tr('meses', 'months')}';
  if (m < 12) return months(m);
  final y = m ~/ 12, r = m % 12;
  return '$y ${y == 1 ? tr('año', 'year') : tr('años', 'years')}${r > 0 ? ' ${tr('y', 'and')} ${months(r)}' : ''}';
}
