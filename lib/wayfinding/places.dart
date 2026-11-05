// places.dart — every place in the app as a sign, the way the Mexico City Metro gives each station a picture and each
// line a colour so people who don't read can find their way: the four tabs, the units on the path and their lessons,
// the simulators and the groups of resources. Each place has a picture, its name and one short line about what's
// inside; Penko says them when a place is held down (wayfinding.dart), and each line has a voice key so it can be
// recorded (voice_keys.dart). The colours live with the widgets (wayfinding.dart, course.dart, calculators.dart).
//
// Plain Dart (no Flutter): tool/voice_keys.dart and the tests read it.
import '../glossary/pictograms.dart';
import '../i18n/tr.dart';

class Place {
  final String id; // stable, plain ASCII: used in voice keys (place.<id>.name) — never rename one
  final String name;
  final String about; // one short line about what's inside
  final Pic picture;
  const Place(this.id, this.name, this.about, this.picture);

  String get nameKey => 'place.$id.name';
  String get aboutKey => 'place.$id.about';

  /// What Penko says when the place is held down: its name, then what's inside
  List<String> get lines => [name, about];
  List<String> get keys => [nameKey, aboutKey];
}

/// The four tabs at the bottom, in order
List<Place> get tabPlaces => [
  Place('tab.learn', tr('Aprender', 'Learn'), tr('El camino de las lecciones, paso a paso.', 'The path of lessons, step by step.'), picPath),
  Place('tab.sims', tr('Simuladores', 'Simulators'),
      tr('Mueve los números de un préstamo, un ahorro o tu presupuesto y mira qué pasa.', 'Move the numbers of a loan, your savings or your budget and see what happens.'),
      picSliders),
  Place('tab.resources', tr('Recursos', 'Resources'),
      tr('Qué quiere decir cada palabra, y páginas oficiales para revisar las cosas de verdad.', 'What each word means, and official sites to check things for real.'),
      picSignpost),
  Place('tab.settings', tr('Ajustes', 'Settings'), tr('El idioma, la voz de Penko y el tamaño de la letra.', "The language, Penko's voice and the text size."), picGear),
];

/// The units on the path, by their key (Unit.key, the Spanish title): their names, lines and pictures
Map<String, Place> get unitPlaces => {
  'Ábaco': Place('unit.abacus', tr('Ábaco', 'Abacus'), tr('Para empezar sin leer', 'To start without reading'), picAbacus),
  'Sumas y restas': Place('unit.sums', tr('Sumas y restas', 'Adding and subtracting'), tr('Llevar y pedir prestado', 'Carrying and borrowing'), picPlusMinus),
  'Multiplicar': Place('unit.multiply', tr('Multiplicar', 'Multiplying'), tr('Las tablas y en columna', 'Times tables and columns'), picMultiply),
  'Dividir': Place('unit.divide', tr('Dividir', 'Dividing'), tr('Repartir y la casita', 'Sharing and long division'), picDivide),
  'Fracciones y porcentajes': Place('unit.fractions', tr('Fracciones y porcentajes', 'Fractions and percentages'),
      tr('Partes, centavos y el %', 'Parts, centavos and %'), picFraction),
  'Dinero': Place('unit.money', tr('Dinero', 'Money'), tr('Las cuentas de todos los días', 'Everyday money math'), picMoneyUnit),
};

/// Each lesson's picture, by its id; a lesson not listed here shows its unit's picture
final Map<String, Pic> lessonPictures = {
  'ab-1': picAbacus,
  'ab-2': picTens,
  'ab-3': picAbacusAdd,
  'ab-4': picFriends5,
  'ab-5': picFriends10,
  'u1-l1': picAdd,
  'u1-l2': picCarry,
  'u1-l3': picAddHundreds,
  'u1-l4': picSubtract,
  'u1-l5': picBorrow,
  'u1-l6': picSubtractHundreds,
  'u2-l1': picTables,
  'u2-l2': picMultiply,
  'u2-l3': picMultiplyCarry,
  'u2-l4': picMultiplyHundreds,
  'u2-l5': picTwoDigits,
  'u3-l1': picDivide,
  'u3-l2': picRemainder,
  'u3-l3': picCasita,
  'u3-l4': picCasitaHundreds,
  'u3-l5': picDivisor,
  'u4-l1': picHalf,
  'u4-l2': picFraction,
  'u4-l3': picCentavo,
  'u4-l4': picPercent,
  'mo-1': picDiscount,
  'mo-2': picInterest,
  'mo-3': picInterestFree,
  'mo-4': picTanda,
  'mo-5': picBudget,
  'mo-6': picCreditCard,
  'mo-7': picCompound,
  'mo-8': picCat,
};

/// The simulators, by id, in the order of the Simuladores tab (the well-being check first)
Map<String, Place> get simPlaces => {
  'wellbeing': Place('sim.wellbeing', tr('¿Cómo estoy con mi dinero?', 'How am I doing with money?'),
      tr('7 preguntas para adultos. Contéstalo hoy y otra vez en unas semanas.', '7 questions for adults. Answer today and again in a few weeks.'), picWellbeing),
  'loan': Place('sim.loan', tr('¿Cuánto cuesta un préstamo?', 'How much does a loan cost?'), tr('Pago al mes, intereses y CAT', 'Monthly payment, interest and CAT'), picLoan),
  'card': Place('sim.card', tr('Tarjeta de crédito', 'Credit card'), tr('Pagar poco contra pagar un poco más', 'Paying little versus paying a bit more'), picCreditCard),
  'debts': Place('sim.debts', tr('Salir de deudas', 'Getting out of debt'), tr('Avalancha o bola de nieve', 'Avalanche or snowball'), picAvalanche),
  'savings': Place('sim.savings', tr('Ahorrar', 'Saving'), tr('Cómo crece tu dinero con intereses', 'How your money grows with interest'), picSaving),
  'budget': Place('sim.budget', tr('Mi presupuesto', 'My budget'), tr('Lo que entra y lo que sale', 'What comes in and what goes out'), picBudget),
  'calendar': Place('sim.calendar', tr('El calendario del mes', "The month's calendar"), tr('¿Qué días te quedas sin dinero?', 'Which days do you run out of money?'),
      picMonthCalendar),
  'debt_list': Place('sim.debt_list', tr('Mis deudas en una lista', 'My debts in one list'),
      tr('Cuánto debes y cuánto se va en intereses', 'How much you owe and how much goes on interest'), picDebtList),
};

/// The groups on the Recursos tab, by id ('elsewhere' is shown in English only)
Map<String, Place> get resourcePlaces => {
  'words': Place('res.words', tr('Palabras', 'Words'), tr('Qué quiere decir cada palabra, con dibujo y voz.', 'What each word means, with a picture and a voice.'), picBook),
  'before_loan': Place('res.before_loan', tr('Antes de pedir un crédito', 'Before taking out a loan (Mexico, in Spanish)'),
      tr('Revisa el costo de un crédito y a quien te lo ofrece.', 'Check what a loan costs and who is offering it.'), picCheckFirst),
  'history': Place('res.history', tr('Tu historial de crédito', 'Your credit history (Mexico, in Spanish)'),
      tr('Pide tu reporte gratis una vez al año.', 'Ask for your free report once a year.'), picCreditHistory),
  'saving': Place('res.saving', tr('Ahorrar', 'Saving (Mexico, in Spanish)'), tr('Ahorro con el gobierno y tu Afore.', 'Saving with the government, and your Afore.'), picCetes),
  'help': Place('res.help', tr('Si algo sale mal', 'If something goes wrong (Mexico, in Spanish)'),
      tr('Dónde quejarte de un banco o de una tienda.', 'Where to complain about a bank or a store.'), picCondusef),
  'elsewhere': Place('res.elsewhere', 'Elsewhere (in English)', 'Well-known public sites for people outside Mexico.', picGlobe),
};

/// Every place, for the voice keys and the tests
List<Place> get allPlaces => [...tabPlaces, ...unitPlaces.values, ...simPlaces.values, ...resourcePlaces.values];

/// Penko's fixed lines that show people where to tap, by key
Map<String, String> get navLines => {
  'nav.hold_to_hear': tr('Si mantienes el dedo sobre un dibujo, te digo qué es.', "If you hold your finger on a picture, I'll tell you what it is."),
  'nav.welcome_next': tr('Toca el botón amarillo de abajo para seguir.', 'Tap the yellow button at the bottom to go on.'),
  'nav.path_next': tr('Toca el botón amarillo de abajo para empezar tu lección:', 'Tap the yellow button at the bottom to start your lesson:'),
  'nav.lesson_start': tr('Toca el botón amarillo para empezar.', 'Tap the yellow button to start.'),
  'nav.who': tr('Toca el dibujo de quien va a usar Penko.', 'Tap the picture of who is going to use Penko.'),
};
