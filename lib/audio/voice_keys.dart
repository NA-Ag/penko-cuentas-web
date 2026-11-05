// voice_keys.dart — every line Penko says that is always the same, each with a stable key, so a person can record it
// (voice packs: voice_pack.dart, docs/VOICE_PACKS.md). The glossary's words, explanations and examples; each lesson's
// opening lines; her fixed short lines; and the app's places and each lesson's name (wayfinding/places.dart). Lines
// with numbers that change each time (the problems) aren't here: those stay with text-to-speech.
//
// Plain Dart: tool/voice_keys.dart prints this list for recordists.
import 'dart:math';

import '../abacus/abacus_lessons.dart';
import '../glossary/terms.dart';
import '../i18n/tr.dart';
import '../math/fraction_lessons.dart';
import '../math/lessons.dart';
import '../math/times_lessons.dart';
import '../money/money_lessons.dart';
import '../wayfinding/places.dart';

/// Penko's short lines that never change (said in the lesson screens), by key
Map<String, String> get penkoLines => {
  'penko.your_turn': tr('¡Ahora tú!', 'Your turn!'),
  'penko.lesson_done': tr('¡Terminaste la lección! Muy buen trabajo.', 'You finished the lesson! Great work.'),
  'penko.lesson_done_work': tr('¡Terminaste la lección! Ahora ya sabes sacar estas cuentas.', 'You finished the lesson! Now you know how to work these out.'),
  'penko.think': tr('Déjame pensar.', 'Let me think.'),
  'penko.try_first_digit': tr('Primero inténtalo tú. Si no sale, te digo qué número va.', "Try it yourself first. If it doesn't work out, I'll tell you the number."),
  'penko.try_first_sum': tr('Primero inténtalo tú. Si no sale, te ayudo con la cuenta.', "Try it yourself first. If it doesn't work out, I'll help you with the sum."),
  'penko.almost': tr('Casi. Revísalo otra vez.', 'Almost. Check it once more.'),
  'penko.almost_zeros': tr('Casi: revisa los ceros.', 'Almost: check the zeros.'),
  'penko.well_done': tr('¡Muy bien!', 'Well done!'),
};

/// The voice key of a lesson's name
String lessonTitleKey(String id) => 'lesson.$id.title';

/// Every recordable line in the current language: key → text, in a stable order
Map<String, String> voiceLines() {
  final out = <String, String>{};
  for (final t in terms) {
    out[t.wordKey] = t.word;
    out[t.explainKey] = t.explain;
    out[t.exampleKey] = t.example;
  }
  final intros = <(String, List<String>)>[
    for (final l in [...unit1, ...unit2Columns]) (l.id, l.intro),
    for (final l in [tablesLesson, timesTwoLesson, ...unit3Division, ...fractionUnit, ...moneyUnit]) (l.id, l.intro),
  ];
  for (final (id, lines) in intros) {
    for (final (i, line) in lines.indexed) {
      out['lesson.$id.intro.$i'] = line;
    }
  }
  // The abacus lessons' explanations (the numbers to show change each time; these don't)
  for (final l in abacusUnit(Random(0))) {
    for (final (i, say) in l.activities.whereType<Say>().indexed) {
      out['lesson.${l.id}.say.$i'] = say.line;
    }
  }
  out.addAll(penkoLines);
  // The app's places (tabs, units, simulators, resources), each lesson's name, and the lines that say where to tap
  for (final p in allPlaces) {
    out[p.nameKey] = p.name;
    out[p.aboutKey] = p.about;
  }
  for (final (id, title) in [
    for (final l in abacusUnit(Random(0))) (l.id, l.title),
    for (final l in [...unit1, ...unit2Columns]) (l.id, l.title),
    for (final l in [tablesLesson, timesTwoLesson, ...unit3Division, ...fractionUnit, ...moneyUnit]) (l.id, l.title),
  ]) {
    out[lessonTitleKey(id)] = title;
  }
  out.addAll(navLines);
  return out;
}
