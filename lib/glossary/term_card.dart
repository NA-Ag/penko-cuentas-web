// term_card.dart — how a glossary word looks: its pictogram on a light tile (TermPicture), and its card (showTermCard):
// the big picture, the word, Penko saying what it means (on her own if the voice is on, again with the speaker
// button), the plain sentence and an example. Big, simple and high-contrast, for people who read little.
import 'package:flutter/material.dart';

import '../art/palette.dart';
import '../art/penko.dart';
import '../art/pixel_sprite.dart';
import '../audio/speech.dart';
import '../data/settings.dart';
import '../i18n/lang.dart';
import '../math/explain.dart' show spoken;
import '../ui/pixel_ui.dart';
import '../wayfinding/wayfinding.dart' show PictogramTile;
import 'term_text.dart';
import 'terms.dart';

/// The pictograms' colours (letters in pictograms.dart)
const _colours = <String, Color>{
  'k': Color(0xFF1B2440), // outline
  'w': Color(0xFFFFFFFF),
  'e': Color(0xFFD7DCE8), // silver
  't': Color(0xFF9AA6C8), // grey
  'd': Color(0xFF64748B), // dark grey
  'y': Pk.gold,
  'o': Color(0xFFC9952C), // dark gold
  's': Pk.sand,
  'g': Pk.grassDark,
  'l': Pk.grass,
  'G': Pk.leaf,
  'b': Pk.sea,
  'B': Pk.seaDeep,
  'r': Pk.coral,
  'c': Pk.orange,
  'p': Pk.plum,
  'm': Color(0xFFF9A8D4), // pink
  'n': Pk.wood,
};

final Map<int, Color> pictogramPalette = {for (final e in _colours.entries) e.key.codeUnitAt(0): e.value};

final _grids = Expando<PixelGrid>('pictogram grids');

/// A pictogram as a pixel grid (made once per picture, so its image is drawn once)
PixelGrid pictogramGrid(Pic pic) => _grids[pic] ??= [
  for (final row in pic) [for (final c in row.codeUnits) c == 0x2E ? 0 : c],
];

/// Each group's colour: the frame around its pictures
Color kindColour(TermKind kind) => switch (kind) {
  TermKind.maths => Pk.sea,
  TermKind.money => Pk.gold,
  TermKind.credit => Pk.coral,
  TermKind.saving => Pk.grassDark,
  TermKind.help => Pk.plum,
};

/// A term's pictogram on a light tile framed in its group's colour, [size] wide
class TermPicture extends StatelessWidget {
  final Term term;
  final double size;
  final bool moves;
  const TermPicture(this.term, {super.key, this.size = 64, this.moves = false});

  @override
  Widget build(BuildContext context) => PictogramTile(term.picture, size: size, frame: kindColour(term.kind), moves: moves);
}

/// Opens [term]'s card; Penko stops talking when it closes
Future<void> showTermCard(BuildContext context, Term term) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  backgroundColor: Pk.card,
  builder: (_) => _TermCard(term: term),
).whenComplete(() => Speech.instance.stop().catchError((Object _) {}));

class _TermCard extends StatefulWidget {
  final Term term;
  const _TermCard({required this.term});

  @override
  State<_TermCard> createState() => _TermCardState();
}

class _TermCardState extends State<_TermCard> {
  Term get _t => widget.term;

  @override
  void initState() {
    super.initState();
    if (Settings.voice.value) _explain();
  }

  void _explain() => Speech.instance.sayAll([_t.word, spoken(_t.explain)], keys: [_t.wordKey, _t.explainKey]);

  @override
  Widget build(BuildContext context) => SafeArea(
    child: ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.9),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: TermPicture(_t, size: 132, moves: true)),
            const SizedBox(height: 12),
            Semantics(
              header: true,
              child: Text(_t.word, textAlign: TextAlign.center, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: Pk.text)),
            ),
            const SizedBox(height: 14),
            // Penko says what it means
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Penko(pose: PenkoPose.talk, size: 56),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
                    decoration: BoxDecoration(color: Pk.dialog, borderRadius: BorderRadius.circular(18)),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TermText(_t.explain, exclude: {_t.id},
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, height: 1.35, color: Pk.onDialog)),
                        ),
                        IconButton(
                          tooltip: tr('Escuchar otra vez', 'Listen again'),
                          icon: const Icon(Icons.volume_up, size: 30, color: Pk.onDialog),
                          onPressed: _explain,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            PkPanel(
              color: Pk.note,
              padding: const EdgeInsets.fromLTRB(16, 12, 6, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(tr('Por ejemplo', 'For example'), style: const TextStyle(color: Pk.gold, fontSize: 16, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        TermText(_t.example, exclude: {_t.id}, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600, height: 1.35, color: Pk.text)),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: tr('Escuchar el ejemplo', 'Listen to the example'),
                    icon: const Icon(Icons.volume_up, size: 28, color: Pk.gold),
                    onPressed: () => Speech.instance.say(spoken(_t.example), key: _t.exampleKey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            PkButton(tr('Entendido', 'Got it'), leading: const Icon(Icons.check, color: Pk.onGold), onPressed: () => Navigator.of(context).pop()),
          ],
        ),
      ),
    ),
  );
}
