// abacus_lessons.dart — the Ábaco unit, built so a child (or adult) who can't read yet can follow it: Penko says
// every instruction aloud, numbers are shown as beads and dots as well as digits, and the abacus itself is the
// answer: no typing. Structure and checks ported from Penko Soroban's first units; Penko's words are new, in
// Mexican Spanish.
import 'dart:math';

import '../i18n/tr.dart';
import 'abacus.dart';

sealed class AbacusActivity {
  const AbacusActivity();
}

/// Penko explains, with an abacus showing a number (and maybe a part glowing)
class Say extends AbacusActivity {
  final String line;
  final int value;
  final int rods;
  final Bead? glow;
  const Say(this.line, {this.value = 0, this.rods = 1, this.glow});
}

/// Show these numbers on the abacus (Penko says each one)
class SetNumbers extends AbacusActivity {
  final List<int> values;
  final int rods;
  const SetNumbers(this.values, {this.rods = 1});
}

/// Start from [start], add [amount]: guided (glowing beads show each move) or on their own (hints on request)
class AddOn extends AbacusActivity {
  final List<(int start, int amount)> problems;
  final int rods;
  final bool guided;
  const AddOn(this.problems, {this.rods = 2, this.guided = false});
}

class AbacusLesson {
  final String id;
  final String title;
  final List<AbacusActivity> activities;
  const AbacusLesson(this.id, this.title, this.activities);
}

/// Single-digit additions that need exactly [technique] (made fresh each time the lesson opens)
List<(int, int)> _problems(Technique technique, int count, Random rng) {
  final out = <(int, int)>[];
  while (out.length < count) {
    final a = rng.nextInt(10), b = 1 + rng.nextInt(9);
    try {
      if (addDigit(fromNumber(a, 2), 1, b).technique == technique && !out.contains((a, b))) out.add((a, b));
    } on AbacusError {
      continue;
    }
  }
  return out;
}

List<AbacusLesson> abacusUnit([Random? rng]) {
  final r = rng ?? Random();
  return [
    AbacusLesson('ab-1', tr('Conoce el ábaco', 'Meet the abacus'), [
      Say(tr('Este es un ábaco. Con él podemos contar y hacer cuentas, ¡sin escribir nada!', 'This is an abacus. With it we can count and do sums, without writing anything!'), value: 0, rods: 3),
      Say(tr('La cuenta de arriba vale 5. Cuenta cuando baja y toca la barra.', 'The bead at the top is worth 5. It counts when it comes down and touches the bar.'), value: 5, glow: Bead.heaven),
      Say(tr('Las cuentas de abajo valen 1 cada una. Cuentan cuando suben y tocan la barra.', 'The beads at the bottom are worth 1 each. They count when they go up and touch the bar.'),
          value: 3, glow: Bead.earth),
      Say(tr('Aquí hay un 7: la de arriba vale 5, y dos de abajo valen 2. 5 y 2 son 7.', 'Here is a 7: the top bead is worth 5, and two bottom beads are worth 2. 5 and 2 make 7.'), value: 7),
      const SetNumbers([1, 3, 4, 2]),
      const SetNumbers([5, 7, 9, 6]),
      SetNumbers([for (var i = 0; i < 4; i++) r.nextInt(10)]),
    ]),
    AbacusLesson('ab-2', tr('Decenas y centenas', 'Tens and hundreds'), [
      Say(tr('Cada varilla es un lugar. A la derecha las unidades, luego las decenas, luego las centenas. '
          'Aquí hay un 352.', 'Each rod is a place. On the right the ones, then the tens, then the hundreds. Here is 352.'),
          value: 352, rods: 3),
      const SetNumbers([23, 40, 105], rods: 3),
      SetNumbers([for (var i = 0; i < 3; i++) 10 + r.nextInt(90)], rods: 3),
    ]),
    AbacusLesson('ab-3', tr('Sumar en el ábaco', 'Adding on the abacus'), [
      Say(tr('Para sumar, ponemos el primer número y luego le agregamos cuentas. ¡Las cuentas que brillan te '
          'dicen cuáles mover!', 'To add, we set the first number and then add beads. The glowing beads tell you which ones to move!'),
          value: 2, rods: 2),
      const AddOn([(2, 1), (1, 3), (2, 5)], guided: true),
      AddOn(_problems(Technique.direct, 4, r)),
    ]),
    AbacusLesson('ab-4', tr('Los amigos del 5', 'The friends of 5'), [
      Say(tr('A veces no hay cuentas suficientes abajo. Entonces usamos a los amigos del 5: 1 y 4, 2 y 3. '
          'Para sumar 4, bajamos el 5 y quitamos 1.', "Sometimes there aren't enough beads at the bottom. Then we use the friends "
          'of 5: 1 and 4, 2 and 3. To add 4, we bring down the 5 and take away 1.'), value: 3, rods: 2),
      const AddOn([(3, 4), (2, 3), (4, 1)], guided: true),
      AddOn(_problems(Technique.five, 4, r)),
    ]),
    AbacusLesson('ab-5', tr('Los amigos del 10', 'The friends of 10'), [
      Say(tr('Cuando la varilla se llena, usamos a los amigos del 10: 1 y 9, 2 y 8, 3 y 7, 4 y 6, 5 y 5. '
          'Para sumar 9, quitamos 1 aquí y subimos 1 en la varilla de al lado.', 'When the rod is full, we use the friends of 10: '
          '1 and 9, 2 and 8, 3 and 7, 4 and 6, 5 and 5. To add 9, we take away 1 here and push up 1 on the next rod.'),
          value: 3, rods: 2),
      const AddOn([(3, 9), (7, 5), (8, 4)], guided: true),
      AddOn(_problems(Technique.ten, 4, r)),
    ]),
  ];
}
