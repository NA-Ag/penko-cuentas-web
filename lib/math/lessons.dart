// lessons.dart — Unit 1 (2.º–3.º de primaria): column addition and subtraction. Each lesson: Penko's intro lines,
// a worked example she does, then problems the student works (guided first, then on their own).
import '../i18n/tr.dart';
import 'column.dart';
import 'problems.dart';

class Lesson {
  final String id;
  final String title;
  final List<String> intro;
  final ColumnProblem example; // Penko works this one
  final ProblemSpec spec;
  final int guided; // the first problems say each sum to do
  final int count;
  const Lesson(this.id, this.title, this.intro, this.example, this.spec, {this.guided = 2, this.count = 5});
}

List<Lesson> get unit1 => [ // a getter: titles and lines in the current language
  Lesson('u1-l1', tr('Sumar sin llevar', 'Adding without carrying'), [
    tr('¡Hola! Soy Penko. Hoy vamos a sumar en columnas.', "Hi! I'm Penko. Today we're going to add in columns."),
    tr('Siempre empezamos por la derecha: primero las unidades, luego las decenas.', 'We always start on the right: first the ones, then the tens.'),
  ], ColumnProblem(23, 14, Op.add), const ProblemSpec(Op.add, 2, carry: false)),
  Lesson('u1-l2', tr('Sumar llevando', 'Adding with carrying'), [
    tr('A veces una columna da 10 o más.', 'Sometimes a column makes 10 or more.'),
    tr('Entonces escribimos las unidades y llevamos 1 a la columna de al lado.', 'Then we write the ones and carry 1 to the next column.'),
  ], ColumnProblem(47, 28, Op.add), const ProblemSpec(Op.add, 2, carry: true)),
  Lesson('u1-l3', tr('Sumas de tres cifras', 'Adding three-digit numbers'), [
    tr('Ahora con centenas. Es igual: de derecha a izquierda, y llevamos cuando hace falta.', "Now with hundreds. It's the same: right to left, and we carry when we need to."),
  ], ColumnProblem(368, 257, Op.add), const ProblemSpec(Op.add, 3, carry: true), guided: 1),
  Lesson('u1-l4', tr('Restar sin pedir prestado', 'Subtracting without borrowing'), [
    tr('Ahora vamos a restar. También empezamos por las unidades.', "Now let's subtract. We start with the ones here too."),
    tr('Al número de arriba le quitamos el de abajo.', 'From the top number, we take away the bottom one.'),
  ], ColumnProblem(58, 23, Op.sub), const ProblemSpec(Op.sub, 2, carry: false)),
  Lesson('u1-l5', tr('Restar pidiendo prestado', 'Subtracting with borrowing'), [
    tr('Si arriba hay un número más chico que abajo, no alcanza.', "If the top digit is smaller than the bottom one, it isn't enough."),
    tr('Entonces le pedimos 1 prestado a la columna de al lado: arriba se vuelve 10 más.', 'So we borrow 1 from the next column: the top digit becomes 10 more.'),
  ], ColumnProblem(52, 27, Op.sub), const ProblemSpec(Op.sub, 2, carry: true)),
  Lesson('u1-l6', tr('Restas de tres cifras', 'Subtracting three-digit numbers'), [
    tr('Restas con centenas. Ojo: a veces hay que pedir prestado dos veces.', 'Subtracting with hundreds. Careful: sometimes you need to borrow twice.'),
  ], ColumnProblem(503, 278, Op.sub), const ProblemSpec(Op.sub, 3, carry: true), guided: 1),
];

/// Unit 2 (3.º–4.º de primaria), in columns: multiplying by one digit. The tables come first, in times_lessons.dart.
List<Lesson> get unit2Columns => [
  Lesson('u2-l2', tr('Multiplicar sin llevar', 'Multiplying without carrying'), [
    tr('Para multiplicar en columna, multiplicamos cada número de arriba por el de abajo.', 'To multiply in a column, we multiply each top digit by the bottom number.'),
    tr('También empezamos por la derecha: primero las unidades.', 'We start on the right here too: first the ones.'),
  ], ColumnProblem(23, 3, Op.mul), const ProblemSpec(Op.mul, 2, carry: false)),
  Lesson('u2-l3', tr('Multiplicar llevando', 'Multiplying with carrying'), [
    tr('Si una multiplicación da 10 o más, escribimos las unidades y llevamos las decenas.', 'If a multiplication makes 10 or more, we write the ones and carry the tens.'),
    tr('Ojo: aquí a veces llevamos 2, 3 o más, no solo 1.', 'Careful: here we sometimes carry 2, 3 or more, not just 1.'),
  ], ColumnProblem(47, 6, Op.mul), const ProblemSpec(Op.mul, 2, carry: true)),
  Lesson('u2-l4', tr('Multiplicar tres cifras', 'Multiplying three-digit numbers'), [
    tr('Ahora con centenas. Igual: de derecha a izquierda, y sumamos lo que llevamos.', 'Now with hundreds. Same as before: right to left, and we add what we carried.'),
  ], ColumnProblem(358, 4, Op.mul), const ProblemSpec(Op.mul, 3, carry: true), guided: 1),
];
