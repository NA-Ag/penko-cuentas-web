// facts.dart — the engine's verified facts about a problem, written the way the tutor model was trained to read them
// (the "DATOS VERIFICADOS" in its prompt). tool/make_data.dart writes its training data with these same functions.
import '../i18n/tr.dart';
import '../math/column.dart';
import '../math/explain.dart';

/// Penko's line after a right digit, without the cheer ("¡Eso!")
String doneWithoutCheer(ColumnProblem p, ColumnStep s) => doneStep(p, s).replaceFirst(RegExp(r'^¡[^!]*! '), '');

/// The whole column problem: the operation and what happens in each column. Always in Spanish, the language the model
/// was trained on, whatever language the student sees.
String columnFacts(ColumnProblem p) => Tr.spanish(() => [
  'Operación: ${p.a} ${p.symbol} ${p.b} = ${p.answer}',
  for (final s in p.writable) '${s.placeName}: ${doneWithoutCheer(p, s)}',
].join('\n'));

/// What a student asks about the column they're on, in their words (shown in the app's language; the model is asked
/// the Spanish one, through Tr.spanish)
String whyQuestion(ColumnProblem p, ColumnStep s) {
  final q = '${p.a} ${p.symbol} ${p.b}';
  if (p.op == Op.sub && s.borrows) {
    return tr('¿Por qué hay que pedir prestado en las ${s.placeName} de $q?', 'Why do we need to borrow in the ${s.placeName} column of $q?');
  }
  if (p.op == Op.sub && s.carryIn > 0) {
    return tr('¿Por qué cambia el número de arriba en las ${s.placeName} de $q?',
        'Why does the top digit change in the ${s.placeName} column of $q?');
  }
  if (p.op != Op.sub && s.carryIn > 0) {
    return tr('¿Por qué le sumo lo que llevamos en las ${s.placeName} de $q?',
        'Why do I add what we carried in the ${s.placeName} column of $q?');
  }
  return tr('No entiendo qué hacer en las ${s.placeName} de $q. ¿Por qué?',
      "I don't understand what to do in the ${s.placeName} column of $q. Why?");
}
