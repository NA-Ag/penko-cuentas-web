// course.dart — the whole course as units on a path: what each unit is called (its sign: places.dart), its colour,
// and its lessons in order with the screen that opens each one. The path screen draws it; nothing here is locked.
import 'package:flutter/material.dart';

import '../abacus/abacus_lessons.dart';
import '../audio/voice_keys.dart' show lessonTitleKey;
import '../art/palette.dart';
import '../glossary/terms.dart' show Pic;
import '../math/column.dart' show Op;
import '../math/fraction_lessons.dart';
import '../math/lessons.dart';
import '../math/times_lessons.dart';
import '../money/money_lessons.dart';
import '../wayfinding/wayfinding.dart';
import 'abacus_lesson_screen.dart';
import 'lesson_screen.dart';
import 'work_lesson_screen.dart';

class PathLesson {
  final String id;
  final String title;
  final IconData icon;
  final Widget Function() open;
  const PathLesson(this.id, this.title, this.icon, this.open);

  /// Its pictogram (places.dart)
  Pic get picture => lessonPictures[id]!;
}

class Unit {
  final String key; // the Spanish title, never translated: saved scores and the challenges are keyed by it
  final String title;
  final String about; // one line under the title
  final Color color; // like a Metro line's: its banner, its lessons and their screens
  final IconData icon;
  final List<PathLesson> lessons;
  const Unit(this.key, this.title, this.about, this.color, this.icon, this.lessons);

  /// Its sign (places.dart): pictogram, and the name and line Penko says
  Place get place => unitPlaces[key]!;
  Pic get picture => place.picture;
}

/// A unit with its name and line from its sign (places.dart)
Unit _unit(String key, Color color, IconData icon, List<PathLesson> lessons) {
  final p = unitPlaces[key]!;
  return Unit(key, p.name, p.about, color, icon, lessons);
}

/// The unit a lesson belongs to, by the lesson's id
Unit? unitOfLesson(String id) {
  for (final u in course) {
    if (u.lessons.any((l) => l.id == id)) return u;
  }
  return null;
}

/// A getter: the titles come in the current language
List<Unit> get course => [
  _unit('Ábaco', Pk.plum, Icons.blur_on, [
    for (final l in abacusUnit())
      PathLesson(l.id, l.title, Icons.blur_on, () => AbacusLessonScreen(lesson: abacusUnit().firstWhere((a) => a.id == l.id))),
  ]),
  _unit('Sumas y restas', Pk.sea, Icons.add, [
    for (final l in unit1) PathLesson(l.id, l.title, l.spec.op == Op.add ? Icons.add : Icons.remove, () => LessonScreen(lesson: l)),
  ]),
  _unit('Multiplicar', Pk.grassDark, Icons.close, [
    PathLesson(tablesLesson.id, tablesLesson.title, Icons.grid_view, () => WorkLessonScreen(lesson: tablesLesson)),
    for (final l in unit2Columns) PathLesson(l.id, l.title, Icons.close, () => LessonScreen(lesson: l)),
    PathLesson(timesTwoLesson.id, timesTwoLesson.title, Icons.close, () => WorkLessonScreen(lesson: timesTwoLesson)),
  ]),
  _unit('Dividir', Pk.coral, Icons.home_outlined, [
    for (final l in unit3Division)
      // The casita (long division) lessons get a little house
      PathLesson(l.id, l.title, const {'u3-l3', 'u3-l4', 'u3-l5'}.contains(l.id) ? Icons.home_outlined : Icons.pie_chart_outline, () => WorkLessonScreen(lesson: l)),
  ]),
  _unit('Fracciones y porcentajes', Pk.sun, Icons.percent, [
    for (final l in fractionUnit)
      PathLesson(l.id, l.title, l.pesos ? Icons.percent : Icons.pie_chart_outline, () => WorkLessonScreen(lesson: l)),
  ]),
  _unit('Dinero', Pk.orange, Icons.payments_outlined, [
    for (final l in moneyUnit) PathLesson(l.id, l.title, Icons.payments_outlined, () => WorkLessonScreen(lesson: l)),
  ]),
];

/// The top of a lesson's screen: its picture framed in its unit's colour (held down, Penko says its name)
class LessonSign extends StatelessWidget {
  final String id;
  final String title;
  final Color colour;
  const LessonSign({super.key, required this.id, required this.title, required this.colour});

  @override
  Widget build(BuildContext context) => Hear(
    lines: [title],
    keys: [lessonTitleKey(id)],
    child: Padding(
      padding: const EdgeInsets.only(right: 8),
      child: PictogramTile(lessonPictures[id] ?? unitOfLesson(id)!.picture, size: 44, frame: colour),
    ),
  );
}
