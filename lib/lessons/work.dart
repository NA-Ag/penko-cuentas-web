// work.dart — a lesson worked as a short story in steps: Penko asks, the student types a number, solved steps stay on
// a card. Used for everyday money, the times tables and division. Every answer comes from code and every line Penko
// says is written beside it, so nothing she says can be wrong.
import 'dart:math';

import '../math/division.dart';

export '../math/division.dart' show LongDivision;

class WorkStep {
  final String ask; // Penko's question for this step
  final int answer; // a whole number (pesos in the money lessons)
  final List<String> hints;
  final String done; // what the step shows once solved, e.g. "10% de $350 = $35"
  const WorkStep(this.ask, this.answer, this.hints, this.done);
}

class WorkProblem {
  final String story;
  final List<WorkStep> steps;
  final String lesson; // Penko's closing line: why it matters
  final LongDivision? division; // drawn as "la casita" while it's worked
  const WorkProblem(this.story, this.steps, this.lesson, {this.division});
}

class WorkLesson {
  final String id;
  final String title;
  final List<String> intro;
  final WorkProblem Function(Random) make;
  final int count;
  final bool pesos; // answers are amounts of money ($1,234) rather than plain numbers
  const WorkLesson(this.id, this.title, this.intro, this.make, {this.count = 3, this.pesos = false});
}
