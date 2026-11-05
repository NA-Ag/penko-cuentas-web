// glossary_screen.dart — "Palabras": every glossary word as a picture with its name, in groups. Tapping one opens its
// card, where Penko says what it means. Opened from Recursos and from the book button in the lessons.
import 'package:flutter/material.dart';

import '../art/palette.dart';
import '../i18n/lang.dart';
import '../wayfinding/wayfinding.dart' show Hear, ReadScreenButton;
import 'term_card.dart';
import 'terms.dart';

String kindName(TermKind kind) => switch (kind) {
  TermKind.maths => tr('Números y operaciones', 'Numbers and operations'),
  TermKind.money => tr('El dinero de todos los días', 'Everyday money'),
  TermKind.credit => tr('Préstamos, tarjetas y deudas', 'Loans, cards and debts'),
  TermKind.saving => tr('Ahorrar', 'Saving'),
  TermKind.help => tr('Dónde pedir ayuda', 'Where to get help'),
};

/// Opens the glossary
void openGlossary(BuildContext context) => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const GlossaryScreen()));

class GlossaryScreen extends StatelessWidget {
  const GlossaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final all = terms;
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('Palabras', 'Words')),
        // Penko reads the groups and their words
        actions: [
          ReadScreenButton(
            lines: () => [
              tr('Palabras', 'Words'),
              for (final kind in TermKind.values) ...[kindName(kind), for (final t in all.where((t) => t.kind == kind)) t.word],
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          Text(tr('Toca un dibujo para saber qué quiere decir la palabra. Penko te lo dice en voz alta.',
                  'Tap a picture to find out what the word means. Penko says it out loud.'),
              style: const TextStyle(color: Pk.textSoft, fontSize: 16, height: 1.35)),
          for (final kind in TermKind.values) ...[
            Padding(
              padding: const EdgeInsets.only(top: 20, bottom: 10),
              child: Semantics(
                header: true,
                child: Text(kindName(kind), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: kindColour(kind))),
              ),
            ),
            Wrap(
              spacing: 10,
              runSpacing: 12,
              children: [for (final t in all.where((t) => t.kind == kind)) _Tile(t)],
            ),
          ],
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final Term term;
  const _Tile(this.term);

  @override
  Widget build(BuildContext context) => Hear(
    lines: [term.word],
    keys: [term.wordKey],
    child: Semantics(
    button: true,
    label: term.word,
    excludeSemantics: true,
    child: InkWell(
      key: ValueKey('term-${term.id}'),
      borderRadius: BorderRadius.circular(16),
      onTap: () => showTermCard(context, term),
      child: SizedBox(
        width: 100,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              TermPicture(term, size: 76),
              const SizedBox(height: 6),
              Text(term.word, textAlign: TextAlign.center, maxLines: 3,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, height: 1.2)),
            ],
          ),
        ),
      ),
    ),
    ),
  );
}
