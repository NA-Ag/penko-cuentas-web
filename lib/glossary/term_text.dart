// term_text.dart — a sentence with its glossary words tappable: each known word (terms.dart's matcher) gets a dotted
// underline and its tiny pictogram after it; tapping either opens the word's card. With no known words it's a plain
// Text, so it can stand in for Text wherever learners read an explanation.
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../art/palette.dart';
import '../i18n/lang.dart';
import 'term_card.dart';
import 'terms.dart';

/// The words of a line as big pictures, for the lessons: someone who can't follow the sentence still sees what it's
/// about. Each moves if it can, and opens its card when tapped. Nothing is shown for a line with no glossary words.
class LinePictures extends StatelessWidget {
  final String line;
  const LinePictures(this.line, {super.key});

  @override
  Widget build(BuildContext context) {
    final seen = <String>{};
    final found = [for (final m in findTerms(line)) if (seen.add(m.term.id)) m.term].take(4).toList();
    if (found.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 10,
        runSpacing: 10,
        children: [
          for (final t in found)
            Semantics(
              button: true,
              label: tr('Qué es: ${t.word}', 'What it means: ${t.word}'),
              child: GestureDetector(
                onTap: () => showTermCard(context, t),
                child: ExcludeSemantics(child: TermPicture(t, size: 68, moves: true)),
              ),
            ),
        ],
      ),
    );
  }
}

class TermText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final Set<String> exclude; // term ids not to mark (a card doesn't link to itself)
  const TermText(this.text, {super.key, this.style, this.textAlign, this.exclude = const {}});

  @override
  State<TermText> createState() => _TermTextState();
}

class _TermTextState extends State<TermText> {
  var _taps = <TapGestureRecognizer>[];

  void _release() {
    final old = _taps;
    _taps = [];
    // after this frame: the old text may still be holding them until it's laid out again
    if (old.isNotEmpty) WidgetsBinding.instance.addPostFrameCallback((_) => [for (final r in old) r.dispose()]);
  }

  @override
  void dispose() {
    for (final r in _taps) {
      r.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _release();
    final text = widget.text;
    final found = findTerms(text, exclude: widget.exclude);
    if (found.isEmpty) return Text(text, style: widget.style, textAlign: widget.textAlign);
    final base = DefaultTextStyle.of(context).style.merge(widget.style);
    final colour = base.color ?? Pk.text;
    final picture = MediaQuery.textScalerOf(context).scale(base.fontSize ?? 14) * 1.05;
    final spans = <InlineSpan>[];
    var at = 0;
    for (final m in found) {
      if (m.start > at) spans.add(TextSpan(text: text.substring(at, m.start)));
      void open() => showTermCard(context, m.term);
      final tap = TapGestureRecognizer()..onTap = open;
      _taps.add(tap);
      spans.add(TextSpan(
        text: text.substring(m.start, m.end),
        recognizer: tap,
        style: TextStyle(
          decoration: TextDecoration.underline,
          decorationStyle: TextDecorationStyle.dotted,
          decorationColor: colour.withValues(alpha: 0.85),
          decorationThickness: 2,
        ),
      ));
      // The little picture follows the word, so the sentence still reads (and is found) as it's written
      spans.add(WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: Semantics(
          button: true,
          label: tr('Qué es: ${m.term.word}', 'What it means: ${m.term.word}'),
          child: GestureDetector(
            onTap: open,
            child: Padding(padding: const EdgeInsets.only(left: 2), child: TermPicture(m.term, size: picture)),
          ),
        ),
      ));
      at = m.end;
    }
    if (at < text.length) spans.add(TextSpan(text: text.substring(at)));
    return Text.rich(TextSpan(children: spans), style: widget.style, textAlign: widget.textAlign);
  }
}
