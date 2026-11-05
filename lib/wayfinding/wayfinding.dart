// wayfinding.dart — finding your way by pictures and voice, like the Mexico City Metro: every place has a pixel
// pictogram (PictogramTile, pictures in places.dart), and holding a finger on any tile, lesson, tab or main button
// makes Penko say its name and what's inside (Hear; a normal tap still opens it). Every main screen and lesson has
// the same "read this screen" button at the top right (ReadScreenButton): Penko reads its title, her line, the
// question and the choices, in order.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../art/palette.dart';
import '../art/pixel_sprite.dart';
import '../audio/speech.dart';
import '../data/settings.dart';
import '../glossary/term_card.dart' show pictogramGrid, pictogramPalette;
import '../glossary/pictograms.dart' show picFrames;
import '../glossary/terms.dart' show Pic;
import '../i18n/lang.dart';
import '../math/explain.dart' show spoken;
import 'places.dart';

export 'places.dart';

/// Each tab's and resource group's colour (the units' colours are in course.dart, the simulators' in calculators.dart)
Color placeColour(String id) => switch (id) {
  'tab.learn' => Pk.gold,
  'tab.sims' => Pk.sea,
  'tab.resources' => Pk.grassDark,
  'tab.settings' => Pk.plum,
  'sim.wellbeing' => Pk.coral,
  'res.words' => Pk.gold,
  'res.before_loan' => Pk.sea,
  'res.history' => Pk.coral,
  'res.saving' => Pk.grassDark,
  'res.help' => Pk.plum,
  _ => Pk.sea,
};

/// A pictogram on a light tile framed in [frame], [size] wide (the glossary's TermPicture looks the same)
class PictogramTile extends StatelessWidget {
  final Pic picture;
  final double size;
  final Color frame;
  final bool moves; // plays its frames, if the picture has any (picFrames) and the student hasn't turned motion off
  const PictogramTile(this.picture, {super.key, this.size = 56, this.frame = Pk.gold, this.moves = false});

  @override
  Widget build(BuildContext context) {
    final big = size >= 40;
    final pad = big ? size * 0.1 : 1.0;
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(pad),
      decoration: BoxDecoration(
        color: Pk.dialog,
        borderRadius: BorderRadius.circular(size * 0.18),
        border: Border.all(color: frame, width: big ? 3 : 1),
      ),
      child: ExcludeSemantics(
        child: moves && !MediaQuery.of(context).disableAnimations
            ? PixelAnimation([for (final f in picFrames(picture)) pictogramGrid(f)], palette: pictogramPalette, size: size - pad * 2 - (big ? 6 : 2), fps: 2)
            : PixelSprite(pictogramGrid(picture), palette: pictogramPalette, size: size - pad * 2 - (big ? 6 : 2)),
      ),
    );
  }
}

/// A tab's or group's heading: its pictogram and its name (held down, Penko says them)
class PlaceHeading extends StatelessWidget {
  final Place place;
  final Color colour;
  final double size; // the text's size; the picture is a little bigger than two lines of it
  final Color? textColour;
  final String? text; // shown instead of the place's name (a group's own heading)
  const PlaceHeading(this.place, {super.key, required this.colour, this.size = 26, this.textColour, this.text});

  @override
  Widget build(BuildContext context) => Hear.place(
    place,
    child: Row(
      children: [
        PictogramTile(place.picture, size: size >= 24 ? 48 : 40, frame: colour),
        const SizedBox(width: 12),
        Expanded(
          child: Semantics(
            header: true,
            child: Text(text ?? place.name, style: TextStyle(fontSize: size, fontWeight: FontWeight.w800, color: textColour)),
          ),
        ),
      ],
    ),
  );
}

/// How Penko speaks the wayfinding lines (tests swap it to listen)
@visibleForTesting
Future<void> Function(List<String> lines, List<String?>? keys) wayfindingVoice =
    (lines, keys) => Speech.instance.sayAll([for (final l in lines) spoken(l)], keys: keys);

/// Penko says [lines] (a place's name, then what's inside), if her voice is on
void hear(List<String> lines, {List<String?>? keys}) {
  if (!Settings.voice.value || lines.isEmpty) return;
  HapticFeedback.selectionClick();
  wayfindingVoice(lines, keys);
}

/// Holding a finger on [child] makes Penko say [lines]; a normal tap still goes to [child]
class Hear extends StatelessWidget {
  final List<String> lines;
  final List<String?>? keys;
  final Widget child;
  const Hear({super.key, required this.lines, this.keys, required this.child});

  /// For a place: its name and what's inside, with their voice keys
  Hear.place(Place place, {Key? key, required Widget child}) : this(key: key, lines: place.lines, keys: place.keys, child: child);

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.deferToChild,
    onLongPress: () => hear(lines, keys: keys),
    child: child,
  );
}

/// Where a screen puts the lines its "read this screen" button reads (when the button lives outside the screen, like
/// the home screen's button for the tab being shown)
class ReadSlot {
  List<String> Function() lines = () => const [];
}

/// The "read this screen" button: Penko reads [lines] in order (title, her line, the question, the choices). Tapped
/// again while reading, she stops. It's a button the learner presses on purpose, so it speaks even with the voice off,
/// like the other speaker buttons.
class ReadScreenButton extends StatefulWidget {
  final List<String> Function() lines;
  const ReadScreenButton({super.key, required this.lines});

  @override
  State<ReadScreenButton> createState() => _ReadScreenButtonState();
}

class _ReadScreenButtonState extends State<ReadScreenButton> {
  bool _reading = false;

  Future<void> _press() async {
    if (_reading) {
      setState(() => _reading = false);
      await Speech.instance.stop();
      return;
    }
    final lines = [for (final l in widget.lines()) if (l.trim().isNotEmpty) l];
    if (lines.isEmpty) return;
    setState(() => _reading = true);
    try {
      await wayfindingVoice(lines, null);
    } finally {
      if (mounted) setState(() => _reading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4),
    child: IconButton(
      key: const ValueKey('read-screen'),
      tooltip: _reading ? tr('Dejar de leer', 'Stop reading') : tr('Leer esta pantalla', 'Read this screen'),
      style: IconButton.styleFrom(
        backgroundColor: _reading ? Pk.gold : Pk.note,
        side: const BorderSide(color: Pk.gold, width: 2),
        minimumSize: const Size(48, 48),
      ),
      icon: Icon(_reading ? Icons.stop_rounded : Icons.record_voice_over, color: _reading ? Pk.onGold : Pk.gold, size: 26),
      onPressed: _press,
    ),
  );
}
