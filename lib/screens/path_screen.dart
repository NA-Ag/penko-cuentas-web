// path_screen.dart — "Aprender": one unit at a time, swiped sideways, each a winding path of round lessons like a
// board game. Finished lessons turn gold with a tick; Penko stands by the next one. Tap a lesson to see its name and
// start it. Nothing is locked: any lesson can be opened. Like the Mexico City Metro, each unit is a line with its own
// colour and picture, and each lesson a station with its own picture; held down, Penko says its name. A big yellow
// button at the bottom always leads to the lesson that comes next.
import 'package:flutter/material.dart';

import '../art/palette.dart';
import '../art/penko.dart';
import '../art/pixel_sprite.dart';
import '../audio/speech.dart';
import '../audio/voice_keys.dart' show lessonTitleKey;
import '../data/settings.dart';
import '../glossary/term_card.dart' show pictogramGrid, pictogramPalette;
import '../glossary/pictograms.dart' show picTrophy;
import '../data/progress.dart';
import '../data/store.dart';
import '../i18n/lang.dart';
import '../ui/pixel_ui.dart';
import '../wayfinding/wayfinding.dart';
import 'course.dart';
import 'unit_check_screen.dart';

class PathScreen extends StatefulWidget {
  final ReadSlot? reader; // where the "read this screen" button finds what the path shows
  const PathScreen({super.key, this.reader});

  /// Penko says where to tap once per run, the first time the path opens
  static bool toldWhereToTap = false;

  @override
  State<PathScreen> createState() => _PathScreenState();
}

class _PathScreenState extends State<PathScreen> {
  final _pages = PageController();
  Set<String> _done = {};
  Map<String, double> _firstTry = {}; // lesson → share right at the first try, last time
  Map<String, int> _checks = {}; // unit → best challenge score
  int _unit = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final unit = (await Store.get<int>('unit') ?? 0).clamp(0, course.length - 1);
    await _refresh();
    if (!mounted) return;
    setState(() => _unit = unit);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pages.hasClients) _pages.jumpToPage(unit);
    });
    _tellWhereToTap();
  }

  /// The first time in a run, for new players: Penko says to tap the yellow button for the next lesson, and that holding a picture
  /// down makes her say what it is
  void _tellWhereToTap() {
    // Only while someone is new (fewer than 3 lessons done): after that they know the way, and it would just repeat
    if (PathScreen.toldWhereToTap || !Settings.voice.value || _done.length >= 3) return;
    PathScreen.toldWhereToTap = true;
    final next = _next(course[_unit]);
    final lines = navLines;
    hear([
      if (next != null) ...[lines['nav.path_next']!, next.title],
      lines['nav.hold_to_hear']!,
    ], keys: [
      if (next != null) ...['nav.path_next', lessonTitleKey(next.id)],
      'nav.hold_to_hear',
    ]);
  }

  /// The lesson that comes next in [unit], or null when it's finished
  PathLesson? _next(Unit unit) => unit.lessons.where((l) => !_done.contains(l.id)).firstOrNull;

  /// What the "read this screen" button reads: the unit, how far along, what comes next, and each lesson
  List<String> _readLines() {
    final unit = course[_unit];
    final finished = unit.lessons.where((l) => _done.contains(l.id)).length;
    final next = _next(unit);
    return [
      tabPlaces[0].name,
      unit.title,
      unit.about,
      tr('$finished de ${unit.lessons.length}', '$finished of ${unit.lessons.length}'),
      if (next != null) '${tr('¡Sigue esta!', 'Up next!')} ${next.title}',
      for (final (i, l) in unit.lessons.indexed)
        '${i + 1}. ${l.title}${_done.contains(l.id) ? tr(', terminada', ', finished') : ''}',
    ];
  }

  void _go(int unit) {
    if (unit < 0 || unit >= course.length) return;
    _pages.animateToPage(unit, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  }

  Future<void> _refresh() async {
    final done = await Progress.done(), firstTry = await Progress.firstTry(), checks = await Progress.checks();
    if (!mounted) return;
    setState(() {
      _done = done;
      _firstTry = firstTry;
      _checks = checks;
    });
  }

  Future<void> _open(Widget Function() screen) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen()));
    await _refresh();
  }

  void _askCheck(Unit unit) => showModalBottomSheet<void>(
    context: context,
    backgroundColor: Pk.card,
    builder: (sheet) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                PictogramTile(picTrophy, size: 72, frame: unit.color),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tr('Reto de la unidad', 'Unit challenge'), style: TextStyle(color: unit.color, fontSize: 15)),
                      const SizedBox(height: 4),
                      Text(unit.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              tr('${Progress.unitCheckSize} preguntas de toda la unidad, sin pistas. Sirve para ver lo que ya aprendiste.',
                      '${Progress.unitCheckSize} questions from the whole unit, with no hints. It shows you what you have already learned.') +
                  (_checks[unit.key] != null
                      ? tr(' Tu mejor resultado: ${_checks[unit.key]} de ${Progress.unitCheckSize}.',
                          ' Your best score: ${_checks[unit.key]} out of ${Progress.unitCheckSize}.')
                      : ''),
              style: const TextStyle(color: Pk.textSoft, fontSize: 15, height: 1.35),
            ),
            const SizedBox(height: 16),
            PkButton(tr('¡Empezar!', 'Start!'), leading: const Icon(Icons.emoji_events_outlined, color: Pk.onGold), onPressed: () {
              Navigator.of(sheet).pop();
              _open(() => UnitCheckScreen(unit: unit.key));
            }),
          ],
        ),
      ),
    ),
  );

  void _ask(Unit unit, PathLesson lesson, int number) {
    // Penko says which lesson it is and what to tap
    hear([lesson.title, navLines['nav.lesson_start']!], keys: [lessonTitleKey(lesson.id), 'nav.lesson_start']);
    showModalBottomSheet<void>(
    context: context,
    backgroundColor: Pk.card,
    builder: (sheet) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                PictogramTile(lesson.picture, size: 72, frame: unit.color),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tr('Lección $number de ${unit.lessons.length}', 'Lesson $number of ${unit.lessons.length}'), style: TextStyle(color: unit.color, fontSize: 15)),
                      const SizedBox(height: 4),
                      Text(lesson.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ],
            ),
            if (_done.contains(lesson.id))
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  Progress.needsReview(_firstTry[lesson.id])
                      ? tr('La última vez te costó un poco (${(_firstTry[lesson.id]! * 100).round()}% al primer intento). '
                            'Vale la pena repasarla.',
                          'Last time it was a bit hard (${(_firstTry[lesson.id]! * 100).round()}% right at the first try). '
                            "It's worth reviewing.")
                      : _firstTry[lesson.id] != null
                      ? tr('Ya la terminaste: ${(_firstTry[lesson.id]! * 100).round()}% al primer intento.',
                          'You finished it: ${(_firstTry[lesson.id]! * 100).round()}% right at the first try.')
                      : tr('Ya la terminaste. Puedes repetirla cuando quieras.', 'You finished it. You can do it again whenever you like.'),
                  style: const TextStyle(color: Pk.textSoft),
                ),
              ),
            const SizedBox(height: 16),
            PkButton(
              _done.contains(lesson.id) ? tr('Repetir', 'Do it again') : tr('¡Empezar!', 'Start!'),
              leading: const Icon(Icons.play_arrow, color: Pk.onGold),
              onPressed: () {
                Navigator.of(sheet).pop();
                _open(lesson.open);
              },
            ),
          ],
        ),
      ),
    ),
  ).whenComplete(() => Speech.instance.stop().catchError((Object _) {}));
  }

  @override
  Widget build(BuildContext context) {
    final unit = course[_unit];
    final finished = unit.lessons.where((l) => _done.contains(l.id)).length;
    final next = _next(unit);
    widget.reader?.lines = _readLines;
    return Column(
      children: [
        // The unit's banner: its picture, name, how far along, and arrows to the other units. Held down, Penko says
        // its name and what's in it.
        Hear.place(
          unit.place,
          child: Container(
          margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          padding: const EdgeInsets.fromLTRB(4, 10, 4, 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [unit.color, Color.lerp(unit.color, Colors.white, 0.25)!]),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [BoxShadow(color: Color.lerp(unit.color, Colors.black, 0.4)!, offset: const Offset(0, 5))],
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: _unit > 0 ? () => _go(_unit - 1) : null,
                icon: const Icon(Icons.chevron_left, size: 32),
                color: Pk.onGold,
                disabledColor: Colors.transparent,
                tooltip: tr('Unidad anterior', 'Previous unit'),
              ),
              PictogramTile(unit.picture, size: 52, frame: Color.lerp(unit.color, Pk.ink, 0.35)!),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  children: [
                    Text(unit.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Pk.onGold)),
                    Text('${unit.about} · ${tr('$finished de ${unit.lessons.length}', '$finished of ${unit.lessons.length}')}',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Pk.onGold.withValues(alpha: 0.8))),
                  ],
                ),
              ),
              IconButton(
                onPressed: _unit + 1 < course.length ? () => _go(_unit + 1) : null,
                icon: const Icon(Icons.chevron_right, size: 32),
                color: Pk.onGold,
                disabledColor: Colors.transparent,
                tooltip: tr('Unidad siguiente', 'Next unit'),
              ),
            ],
          ),
        ),
        ),
        // Where we are among the units, as dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (final (i, u) in course.indexed)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: i == _unit ? 18 : 8,
                height: 8,
                margin: const EdgeInsets.all(3),
                decoration: BoxDecoration(color: i == _unit ? u.color : Pk.cardHi, borderRadius: BorderRadius.circular(4)),
              ),
          ],
        ),
        Expanded(
          child: PageView(
            controller: _pages,
            onPageChanged: (i) {
              setState(() => _unit = i);
              Store.set('unit', i);
            },
            children: [
              for (final u in course)
                _UnitPath(unit: u, done: _done, firstTry: _firstTry, check: _checks[u.key], onTap: _ask, onCheck: _askCheck),
            ],
          ),
        ),
        // The one thing to do next, unmistakable: a big yellow button with the lesson's picture
        if (next != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: PkButton(
              '${tr('¡Sigue esta!', 'Up next!')} ${next.title}',
              key: const ValueKey('path-next'),
              leading: PictogramTile(next.picture, size: 40, frame: unit.color),
              onPressed: () => _ask(unit, next, unit.lessons.indexOf(next) + 1),
            ),
          ),
      ],
    );
  }
}

/// One unit's lessons as round stepping stones that wind left and right
class _UnitPath extends StatelessWidget {
  final Unit unit;
  final Set<String> done;
  final Map<String, double> firstTry;
  final int? check; // best challenge score
  final void Function(Unit, PathLesson, int) onTap;
  final void Function(Unit) onCheck;
  const _UnitPath({
    required this.unit,
    required this.done,
    required this.firstTry,
    required this.check,
    required this.onTap,
    required this.onCheck,
  });

  // How far each stone sits from the middle, as a share of half the width: a gentle S
  static const _swing = [0.0, 0.42, 0.62, 0.42, 0.0, -0.42, -0.62, -0.42];
  static const _node = 76.0;

  @override
  Widget build(BuildContext context) {
    final next = unit.lessons.indexWhere((l) => !done.contains(l.id));
    return LayoutBuilder(
      builder: (context, box) => ListView(
        padding: const EdgeInsets.only(top: 20, bottom: 40),
        children: [
          for (final (i, l) in unit.lessons.indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: 22),
              child: Transform.translate(
                offset: Offset(_swing[i % _swing.length] * (box.maxWidth / 2 - _node), 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Penko on one side and an empty space as wide on the other, so the stone stays in its place
                    if (i == next)
                      _swing[i % _swing.length] >= 0
                          ? const Padding(padding: EdgeInsets.only(right: 12), child: Penko(pose: PenkoPose.idle, size: 56))
                          : const SizedBox(width: 68),
                    _Stone(
                      lesson: l,
                      color: unit.color,
                      done: done.contains(l.id),
                      review: done.contains(l.id) && Progress.needsReview(firstTry[l.id]),
                      current: i == next,
                      size: _node,
                      onTap: () => onTap(unit, l, i + 1),
                    ),
                    if (i == next)
                      _swing[i % _swing.length] < 0
                          ? const Padding(padding: EdgeInsets.only(left: 12), child: Penko(pose: PenkoPose.idle, size: 56))
                          : const SizedBox(width: 68),
                  ],
                ),
              ),
            ),
          // The unit's challenge, last on the path
          if (checkFor(unit.key) != null)
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 22),
              child: Center(
                child: Hear(
                  lines: [tr('Reto de la unidad', 'Unit challenge'), unit.title],
                  child: Semantics(
                  button: true,
                  label: tr('Reto de la unidad${check != null ? ', mejor resultado $check de ${Progress.unitCheckSize}' : ''}',
                      'Unit challenge${check != null ? ', best score $check out of ${Progress.unitCheckSize}' : ''}'),
                  excludeSemantics: true,
                  child: GestureDetector(
                    onTap: () => onCheck(unit),
                    child: Column(
                      children: [
                        Container(
                          width: _node,
                          height: _node,
                          decoration: BoxDecoration(
                            color: check != null ? Pk.gold : Pk.cardHi,
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [BoxShadow(color: Color.lerp(check != null ? Pk.gold : Pk.cardHi, Pk.ink, 0.45)!, offset: const Offset(0, 6))],
                          ),
                          alignment: Alignment.center,
                          child: Container(
                            width: _node * 0.74,
                            height: _node * 0.74,
                            padding: EdgeInsets.all(_node * 0.1),
                            decoration: BoxDecoration(color: Pk.dialog, borderRadius: BorderRadius.circular(16)),
                            child: ExcludeSemantics(child: PixelSprite(pictogramGrid(picTrophy), palette: pictogramPalette, size: _node * 0.54)),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(check != null
                                ? tr('Reto: $check de ${Progress.unitCheckSize}', 'Challenge: $check of ${Progress.unitCheckSize}')
                                : tr('Reto de la unidad', 'Unit challenge'),
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Pk.gold)),
                      ],
                    ),
                  ),
                ),
                ),
              ),
            ),
          if (next < 0)
            Padding(
              padding: EdgeInsets.only(top: 8),
              child: Column(
                children: [
                  Penko(pose: PenkoPose.jump, size: 72),
                  SizedBox(height: 8),
                  Text(tr('¡Terminaste la unidad!', 'You finished the unit!'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Pk.gold)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Stone extends StatelessWidget {
  final PathLesson lesson;
  final Color color;
  final bool done;
  final bool review; // finished, but worth repeating
  final bool current;
  final double size;
  final VoidCallback onTap;
  const _Stone({
    required this.lesson,
    required this.color,
    required this.done,
    required this.review,
    required this.current,
    required this.size,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Every stone wears its unit's colour, like a Metro line (paler until it's reached); gold once finished
    final face = done ? Pk.gold : (current ? color : Color.lerp(color, Pk.cardHi, 0.55)!);
    final edge = Color.lerp(face, Pk.ink, 0.45)!;
    return Hear(
      lines: [lesson.title],
      keys: [lessonTitleKey(lesson.id)],
      child: Semantics(
      button: true,
      label: '${lesson.title}${done ? (review ? tr(', terminada, para repasar', ', finished, worth reviewing') : tr(', terminada', ', finished')) : (current ? tr(', la que sigue', ', up next') : '')}',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // A little tag over the lesson that comes next
            if (current)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(color: Pk.dialog, borderRadius: BorderRadius.circular(12)),
                child: Text(tr('¡Sigue esta!', 'Up next!'), style: TextStyle(color: Color.lerp(color, Colors.black, 0.35), fontSize: 13, fontWeight: FontWeight.w800)),
              ),
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                gradient: RadialGradient(center: const Alignment(-0.3, -0.4), colors: [Color.lerp(face, Colors.white, 0.18)!, face]),
                shape: BoxShape.circle,
                // A thick lower edge makes it look like a button you can press
                boxShadow: [BoxShadow(color: edge, offset: const Offset(0, 6))],
                border: current ? Border.all(color: Pk.text, width: 3) : null,
              ),
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  // The lesson's picture on a light disc, so it reads the same on every colour
                  Container(
                    width: size * 0.74,
                    height: size * 0.74,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(color: Pk.dialog, shape: BoxShape.circle),
                    child: ExcludeSemantics(
                      child: PixelSprite(pictogramGrid(lesson.picture), palette: pictogramPalette, size: size * 0.54),
                    ),
                  ),
                  // A green tick once it's finished
                  if (done)
                    Positioned(
                      left: -4,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(color: Pk.right, shape: BoxShape.circle, border: Border.all(color: Pk.paper, width: 2)),
                        child: const Icon(Icons.check_rounded, size: 18, color: Pk.onGold),
                      ),
                    ),
                  // An amber "repeat" badge: finished, but it went hard at the first try
                  if (review)
                    Positioned(
                      right: -4,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(color: Pk.wrong, shape: BoxShape.circle, border: Border.all(color: Pk.paper, width: 2)),
                        child: const Icon(Icons.replay, size: 16, color: Pk.onGold),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: size * 1.9,
              child: Text(lesson.title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: TextStyle(fontSize: 14, color: done || current ? Pk.text : Pk.textSoft, fontWeight: FontWeight.w600)),
            ),
            if (review)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(tr('Repasa', 'Review'), style: const TextStyle(fontSize: 13, color: Pk.wrongText, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
      ),
    );
  }
}
