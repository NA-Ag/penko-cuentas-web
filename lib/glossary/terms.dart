// terms.dart — the glossary: every money and maths word a learner meets in the app, each with a picture, one plain
// sentence and a small example, in Spanish and English (tr(), like the rest of the app). It's built for people who
// read little or are still learning Spanish: the picture and Penko's voice carry the meaning, the way the Mexico City
// Metro gives every station a picture. Recorded voices can replace Penko's synthetic one, word by word (voice keys
// below; see docs/VOICE_PACKS.md).
//
// Plain Dart (no Flutter): tool/voice_keys.dart and the tests read it. The matcher at the end finds these words in
// any sentence, so lessons, simulators and resources can make them tappable (lib/glossary/term_text.dart).
//
// The explanations are education, not legal or financial definitions: they say what a word means in everyday life and
// avoid rates and rules that change (the one number given is IVA's usual 16%).
import '../i18n/tr.dart';
import 'pictograms.dart';

export 'pictograms.dart' show Pic;

/// The groups the glossary screen shows, each with its own colour
enum TermKind { maths, money, credit, saving, help }

class Term {
  final String id; // stable, in plain ASCII: used in voice keys (term.<id>.word) — never rename one
  final TermKind kind;
  final String word; // as a heading
  final List<String> forms; // other ways it's written in sentences (plurals, verbs), matched as whole words
  final String explain; // one plain sentence
  final String example; // a concrete case with small round numbers
  final Pic picture;
  final List<String> avoid; // phrases where one of its forms means something else ("the ones you want")
  const Term(this.id, this.kind, this.word, this.forms, this.explain, this.example, this.picture, {this.avoid = const []});

  String get wordKey => 'term.$id.word';
  String get explainKey => 'term.$id.explain';
  String get exampleKey => 'term.$id.example';

  /// Everything the matcher looks for: the word itself and its other forms
  Iterable<String> get allForms => {word, ...forms};
}

/// Every term, in the current language (a getter, like the lessons)
List<Term> get terms => [
  // ---------------------------------------------------------------- numbers and operations
  Term('add', TermKind.maths, tr('Sumar', 'Add'), trOf(['suma', 'sumas', 'sumamos', 'sumar'], ['adding', 'addition', 'add']),
      tr('Sumar es juntar cantidades para saber cuántas hay en total.', 'Adding is putting amounts together to find how many there are in total.'),
      tr('Tienes 3 manzanas y te dan 2 más: 3 + 2 = 5.', 'You have 3 apples and get 2 more: 3 + 2 = 5.'), picAdd),
  Term('subtract', TermKind.maths, tr('Restar', 'Subtract'), trOf(['resta', 'restas', 'restamos', 'restar'], ['subtracting', 'subtraction', 'subtract']),
      tr('Restar es quitar una cantidad a otra para saber cuánto queda.', 'Subtracting is taking one amount away from another to find how much is left.'),
      tr('Tienes 5 dulces y te comes 2: 5 − 2 = 3.', 'You have 5 candies and eat 2: 5 − 2 = 3.'), picSubtract),
  Term('multiply', TermKind.maths, tr('Multiplicar', 'Multiply'),
      trOf(['multiplica', 'multiplicamos', 'multiplicas', 'multiplicación', 'multiplicaciones', 'multiplicando'], ['multiplying', 'multiplication', 'multiply']),
      tr('Multiplicar es una forma rápida de sumar grupos iguales.', 'Multiplying is a quick way to add equal groups.'),
      tr('3 bolsas con 4 dulces cada una: 3 × 4 = 12 dulces.', '3 bags with 4 candies each: 3 × 4 = 12 candies.'), picMultiply),
  Term('divide', TermKind.maths, tr('Dividir', 'Divide'),
      trOf(['divide', 'dividimos', 'divides', 'dividirlo', 'división', 'divisiones'], ['dividing', 'division', 'divide']),
      tr('Dividir es repartir en partes iguales.', 'Dividing is sharing into equal parts.'),
      tr('12 dulces entre 3 amigos: 12 ÷ 3 = 4 para cada uno.', '12 candies shared among 3 friends: 12 ÷ 3 = 4 each.'), picDivide),
  Term('tables', TermKind.maths, tr('Las tablas', 'Times tables'), trOf(['las tablas', 'la tabla'], ['times tables', 'times table']),
      tr('Las tablas son las multiplicaciones del 1 al 10 que conviene saber de memoria.', 'The times tables are the multiplications from 1 to 10 that are worth knowing by heart.'),
      tr('La tabla del 2: 2, 4, 6, 8, 10…', 'The 2 times table: 2, 4, 6, 8, 10…'), picTables),
  Term('remainder', TermKind.maths, tr('Residuo', 'Remainder'), trOf(['residuo'], ['remainder']),
      tr('El residuo es lo que sobra cuando no se puede repartir todo en partes iguales.', 'The remainder is what is left over when you can\'t share everything equally.'),
      tr('7 dulces entre 2 niños: 3 para cada uno y sobra 1. El residuo es 1.', '7 candies shared between 2 children: 3 each and 1 left over. The remainder is 1.'), picRemainder),
  Term('casita', TermKind.maths, tr('La casita', 'Long division'), trOf(['la casita', 'casita'], ['long division', 'la casita']),
      tr('La casita es la forma de escribir una división grande y hacerla paso a paso.', 'Long division is a way to write a big division and work it out step by step. In Mexico it is called "la casita", the little house.'),
      tr('84 ÷ 4: el 84 va adentro de la casita y el 4 afuera. Arriba sale el 21.', '84 ÷ 4: the 84 goes inside and the 4 outside. The answer, 21, goes on top.'), picCasita),
  Term('divisor', TermKind.maths, tr('Divisor', 'Divisor'), trOf(['divisor'], ['divisor']),
      tr('El divisor es el número entre el que repartes.', 'The divisor is the number you divide by.'),
      tr('En 12 ÷ 3, el divisor es 3: repartes entre 3.', 'In 12 ÷ 3, the divisor is 3: you share among 3.'), picDivisor),
  Term('ones', TermKind.maths, tr('Unidades', 'Ones'), trOf(['unidades', 'unidad'], ['ones']),
      tr('Las unidades son la columna de la derecha: cuentan de uno en uno.', 'The ones are the column on the right: they count one by one.'),
      tr('En 352, el 2 está en las unidades: vale 2.', 'In 352, the 2 is in the ones: it is worth 2.'), picOnes,
      avoid: trOf(const [], const ['the ones you', 'which ones', 'ones to'])),
  Term('tens', TermKind.maths, tr('Decenas', 'Tens'), trOf(['decenas', 'decena'], ['tens']),
      tr('Una decena es un grupo de 10.', 'A ten is a group of 10.'),
      tr('En 352, el 5 está en las decenas: vale 50.', 'In 352, the 5 is in the tens: it is worth 50.'), picTens),
  Term('hundreds', TermKind.maths, tr('Centenas', 'Hundreds'), trOf(['centenas', 'centena'], ['hundreds']),
      tr('Una centena es un grupo de 100.', 'A hundred is a group of 100.'),
      tr('En 352, el 3 está en las centenas: vale 300.', 'In 352, the 3 is in the hundreds: it is worth 300.'), picHundreds),
  Term('digit', TermKind.maths, tr('Cifra', 'Digit'), trOf(['cifras', 'cifra'], ['digits', 'digit']),
      tr('Una cifra es cada uno de los números del 0 al 9 con los que se escriben todos los números.', 'A digit is each of the numbers from 0 to 9 that all numbers are written with.'),
      tr('352 tiene tres cifras: 3, 5 y 2.', '352 has three digits: 3, 5 and 2.'), picDigit),
  Term('column', TermKind.maths, tr('Columna', 'Column'), trOf(['columnas', 'columna'], ['columns', 'column']),
      tr('En una cuenta en columnas, los números van uno debajo del otro: unidades con unidades, decenas con decenas.', 'In a column sum, the numbers go one under the other: ones under ones, tens under tens.'),
      tr('Para sumar 23 + 14, el 3 va arriba del 4, y el 2 arriba del 1.', 'To add 23 + 14, the 3 goes above the 4, and the 2 above the 1.'), picColumn),
  Term('carry', TermKind.maths, tr('Llevar', 'Carry'), trOf(['llevamos', 'llevando', 'llevas', 'llevar', 'se lleva'], ['carrying', 'carried', 'carries', 'carry']),
      tr('Cuando una columna da 10 o más, escribes las unidades y pasas las decenas a la columna de al lado.', 'When a column makes 10 or more, you write the ones and pass the tens to the next column.'),
      tr('7 + 8 = 15: escribes el 5 y llevas 1.', '7 + 8 = 15: you write the 5 and carry the 1.'), picCarry),
  Term('borrow', TermKind.maths, tr('Pedir prestado', 'Borrowing (in subtraction)'),
      trOf(['pidiendo prestado', 'pedimos prestado', 'pedimos 1 prestado', 'pide 1 prestado', 'prestó 1'], ['borrowing', 'we borrow 1', 'borrow 1', 'borrows 1', 'lent 1']),
      tr('Al restar, si arriba hay un número más chico, la columna de al lado le presta 1 decena, o sea 10.', 'When subtracting, if the top digit is smaller, the next column lends it 1 ten, that is 10.'),
      tr('52 − 27: al 2 no le alcanza para quitarle 7. Pide 1 prestado y se vuelve 12: 12 − 7 = 5.', '52 − 27: 2 is not enough to take away 7. It borrows 1 and becomes 12: 12 − 7 = 5.'), picBorrow,
      avoid: trOf(const ['antes de pedir prestado'], const [])), // that one is about loans
  Term('abacus', TermKind.maths, tr('Ábaco', 'Abacus'), trOf(['ábaco'], ['abacus']),
      tr('Un ábaco es un marco con cuentas que se mueven para contar y hacer operaciones.', 'An abacus is a frame with beads that you move to count and do sums.'),
      tr('La cuenta de arriba vale 5. Si la bajas y subes 2 de abajo, marcas 7.', 'The top bead is worth 5. Bring it down and push up 2 from the bottom, and it shows 7.'), picAbacus),
  Term('fraction', TermKind.maths, tr('Fracción', 'Fraction'), trOf(['fracciones', 'fracción'], ['fractions', 'fraction']),
      tr('Una fracción es una parte de algo que se partió en partes iguales.', 'A fraction is a part of something that was cut into equal parts.'),
      tr('Una pizza en 4 partes iguales: 1 parte es 1/4, un cuarto.', 'A pizza in 4 equal parts: 1 part is 1/4, a quarter.'), picFraction),
  Term('half', TermKind.maths, tr('Mitad', 'Half'), trOf(['mitades', 'mitad', 'un medio'], ['halves', 'half']),
      tr('La mitad es una de 2 partes iguales.', 'A half is one of 2 equal parts.'),
      tr('La mitad de 10 es 5.', 'Half of 10 is 5.'), picHalf),
  Term('quarter', TermKind.maths, tr('Cuarta parte', 'Quarter'), trOf(['cuarta parte', 'un cuarto', 'cuartos'], ['quarters', 'quarter']),
      tr('La cuarta parte es una de 4 partes iguales. También es la mitad de la mitad.', 'A quarter is one of 4 equal parts. It is also half of a half.'),
      tr('La cuarta parte de 20 es 5.', 'A quarter of 20 is 5.'), picQuarter),
  Term('percent', TermKind.maths, tr('Porcentaje', 'Percentage'), trOf(['porcentajes', 'porcentaje', 'por ciento'], ['percentages', 'percentage', 'percent']),
      tr('Un porcentaje dice cuántos de cada 100. Se escribe con el signo %.', 'A percentage says how many out of every 100. It is written with the % sign.'),
      tr('El 10% de \$200 son \$20.', '10% of \$200 is \$20.'), picPercent),
  Term('total', TermKind.maths, tr('Total', 'Total'), trOf(['en total', 'total'], ['in total', 'total']),
      tr('El total es todo junto: lo que da al final de sumar.', 'The total is everything together: what you get at the end of adding.'),
      tr('\$5 + \$3 = \$8 en total.', '\$5 + \$3 = \$8 in total.'), picTotal),

  // ---------------------------------------------------------------- everyday money
  Term('peso', TermKind.money, tr('Peso', 'Peso'), trOf(['pesos', 'peso'], ['pesos', 'peso']),
      tr('El peso es el dinero de México. Su signo es \$.', 'The peso is Mexico\'s money. Its sign is \$.'),
      tr('Un billete de \$20 son 20 pesos.', 'A \$20 bill is 20 pesos.'), picPeso),
  Term('centavo', TermKind.money, tr('Centavo', 'Centavo'), trOf(['centavos', 'centavo'], ['centavos', 'centavo']),
      tr('Un centavo es una parte muy chiquita del peso: 100 centavos hacen 1 peso.', 'A centavo is a very small part of a peso: 100 centavos make 1 peso.'),
      tr('\$7.50 son 7 pesos con 50 centavos.', '\$7.50 is 7 pesos and 50 centavos.'), picCentavo),
  Term('coin', TermKind.money, tr('Moneda', 'Coin'), trOf(['monedas', 'moneda'], ['coins', 'coin']),
      tr('Una moneda es dinero de metal, redondo.', 'A coin is round money made of metal.'),
      tr('Dos monedas de \$10 y una de \$5 son \$25.', 'Two \$10 coins and one \$5 coin make \$25.'), picCoins),
  Term('bill', TermKind.money, tr('Billete', 'Bill'), trOf(['billetes', 'billete'], ['bills', 'bill', 'banknote']),
      tr('Un billete es dinero de papel o de plástico.', 'A bill is money made of paper or plastic.'),
      tr('Con un billete de \$50 y uno de \$20 tienes \$70.', 'With a \$50 bill and a \$20 bill you have \$70.'), picBill),
  Term('change', TermKind.money, tr('Cambio', 'Change'), trOf(['cambio', 'vuelto'], ['change']),
      tr('El cambio es el dinero que te regresan cuando pagas con más de lo que cuesta algo.', 'Change is the money you get back when you pay more than something costs.'),
      tr('Algo cuesta \$15 y pagas con \$20: tu cambio es \$5.', 'Something costs \$15 and you pay with \$20: your change is \$5.'), picChange,
      avoid: trOf(const [], const ['rates change', 'change it', 'change the', 'to change'])),
  Term('price', TermKind.money, tr('Precio', 'Price'), trOf(['precios', 'precio'], ['prices', 'price']),
      tr('El precio es lo que cuesta algo.', 'The price is what something costs.'),
      tr('Si el pan cuesta \$5, su precio es \$5.', 'If bread costs \$5, its price is \$5.'), picPrice),
  Term('discount', TermKind.money, tr('Descuento', 'Discount'), trOf(['descuentos', 'descuento'], ['discounts', 'discount']),
      tr('Un descuento es una rebaja: lo que te quitan del precio.', 'A discount is a reduction: what is taken off the price.'),
      tr('Algo cuesta \$200 con 10% de descuento: te quitan \$20 y pagas \$180.', 'Something costs \$200 with a 10% discount: \$20 comes off and you pay \$180.'), picDiscount),
  Term('iva', TermKind.money, tr('IVA', 'IVA (value-added tax)'), trOf(['iva'], ['iva', 'value-added tax']),
      tr('El IVA es un impuesto que se suma al precio de muchas cosas y servicios en México. Por lo general es el 16%.', 'IVA is a tax added to the price of many things and services in Mexico. It is usually 16%.'),
      tr('Si algo cuesta \$100 sin IVA, con el 16% de IVA pagas \$116.', 'If something costs \$100 without IVA, with 16% IVA you pay \$116.'), picIva),
  Term('tax', TermKind.money, tr('Impuesto', 'Tax'), trOf(['impuestos', 'impuesto'], ['taxes', 'tax']),
      tr('Un impuesto es dinero que pagamos al gobierno para cosas de todos, como escuelas y calles.', 'A tax is money we pay to the government for things everyone uses, like schools and streets.'),
      tr('El IVA es un impuesto: de \$116, \$16 son el impuesto.', 'IVA is a tax: of \$116, \$16 is the tax.'), picTax),
  Term('income', TermKind.money, tr('Ingreso', 'Income'), trOf(['ingresos', 'ingreso', 'lo que entra', 'lo que ganan', 'lo que ganas'], ['income', 'what comes in']),
      tr('Un ingreso es el dinero que te llega: tu sueldo, tus ventas, lo que te pagan.', 'Income is the money that comes to you: your pay, your sales, what people pay you.'),
      tr('Si te pagan \$3,000 cada quincena, tu ingreso al mes es \$6,000.', 'If you are paid \$3,000 every two weeks, your income is \$6,000 a month.'), picIncome),
  Term('expense', TermKind.money, tr('Gasto', 'Expense'), trOf(['gastos', 'gasto', 'gastas', 'gastan', 'gastar', 'lo que sale'], ['expenses', 'expense', 'spending', 'what goes out']),
      tr('Un gasto es el dinero que sale: lo que pagas por comida, renta, transporte.', 'An expense is money that goes out: what you pay for food, rent, transport.'),
      tr('Si pagas \$500 de luz y \$300 de celular, tus gastos son \$800.', 'If you pay \$500 for power and \$300 for your phone, your expenses are \$800.'), picExpense),
  Term('budget', TermKind.money, tr('Presupuesto', 'Budget'), trOf(['presupuestos', 'presupuesto'], ['budgets', 'budget']),
      tr('Un presupuesto es un plan de lo que entra y lo que sale de dinero cada mes.', 'A budget is a plan of the money that comes in and goes out each month.'),
      tr('Entran \$1,000 y gastas \$800: te quedan \$200 para ahorrar.', '\$1,000 comes in and you spend \$800: you have \$200 left to save.'), picBudget),
  Term('payday', TermKind.money, tr('Quincena', 'Payday (quincena)'), trOf(['quincenas', 'quincena'], ['paydays', 'payday', 'quincena']),
      tr('La quincena es el pago que llega cada 15 días, casi siempre el día 15 y el último del mes.', 'The quincena is pay that arrives every 15 days, usually on the 15th and the last day of the month.'),
      tr('Si ganas \$6,000 al mes, cada quincena te llegan \$3,000.', 'If you earn \$6,000 a month, \$3,000 arrives each quincena.'), picPayday),
  Term('rent', TermKind.money, tr('Renta', 'Rent'), trOf(['renta'], ['rent']),
      tr('La renta es lo que pagas cada mes por vivir en una casa o un cuarto que no es tuyo.', 'Rent is what you pay each month to live in a home or room that isn\'t yours.'),
      tr('Si la renta es \$3,000 y ganas \$9,000, la renta es la tercera parte de lo que ganas.', 'If the rent is \$3,000 and you earn \$9,000, the rent is a third of what you earn.'), picRent),
  Term('receipt', TermKind.money, tr('Ticket', 'Receipt'), trOf(['tickets', 'ticket'], ['receipts', 'receipt']),
      tr('El ticket es el papel que te dan al pagar, con lo que compraste y cuánto costó.', 'A receipt is the paper you get when you pay, with what you bought and what it cost.'),
      tr('Un ticket dice: leche \$30, pan \$20, total \$50.', 'A receipt says: milk \$30, bread \$20, total \$50.'), picReceipt),

  // ---------------------------------------------------------------- loans, cards and debts
  Term('interest', TermKind.credit, tr('Interés', 'Interest'), trOf(['intereses', 'interés'], ['interest']),
      tr('El interés es lo que pagas por usar dinero prestado, o lo que te pagan por guardar tu dinero.', 'Interest is what you pay for using borrowed money, or what you are paid for keeping your money saved.'),
      tr('Te prestan \$100 y te cobran 10% de interés: pagas \$10 más.', 'You borrow \$100 at 10% interest: you pay \$10 extra.'), picInterest),
  Term('compound', TermKind.saving, tr('Interés compuesto', 'Compound interest'), trOf(['interés compuesto'], ['compound interest']),
      tr('Es cuando tus intereses también ganan intereses, y tu dinero crece cada vez más rápido.', 'It is when your interest also earns interest, so your money grows faster and faster.'),
      tr('\$100 al 10% al año: el primer año ganas \$10; el segundo, el 10% de \$110, o sea \$11.', '\$100 at 10% a year: the first year you earn \$10; the second, 10% of \$110, that is \$11.'), picCompound),
  Term('rate', TermKind.credit, tr('Tasa de interés', 'Interest rate'), trOf(['tasa de interés', 'tasas', 'tasa'], ['interest rate', 'rates', 'rate']),
      tr('La tasa es el porcentaje de interés que se cobra o se paga, al mes o al año.', 'The rate is the percentage of interest that is charged or paid, per month or per year.'),
      tr('Con una tasa del 10% al año, por \$1,000 se pagan \$100 de interés en un año.', 'At a rate of 10% a year, \$1,000 gives \$100 of interest in a year.'), picRate),
  Term('loan', TermKind.credit, tr('Préstamo', 'Loan'), trOf(['préstamos', 'préstamo'], ['loans', 'loan']),
      tr('Un préstamo es dinero que alguien te da y que tienes que devolver, casi siempre con intereses.', 'A loan is money someone gives you that you have to pay back, almost always with interest.'),
      tr('Te prestan \$1,000 y devuelves \$1,100: los \$100 de más son los intereses.', 'You borrow \$1,000 and pay back \$1,100: the extra \$100 is the interest.'), picLoan),
  Term('credit', TermKind.credit, tr('Crédito', 'Credit'), trOf(['créditos', 'crédito'], ['credit']),
      tr('Un crédito es dinero que te presta un banco o una tienda para que pagues después, poco a poco.', 'Credit is money a bank or a store lends you so you can pay later, little by little.'),
      tr('Compras una estufa de \$6,000 a crédito y la pagas en 12 meses.', 'You buy a \$6,000 stove on credit and pay it off over 12 months.'), picCredit),
  Term('card', TermKind.credit, tr('Tarjeta de crédito', 'Credit card'), trOf(['tarjetas de crédito', 'tarjeta de crédito'], ['credit cards', 'credit card']),
      tr('Es una tarjeta para comprar con dinero que te presta el banco. Si no pagas todo a tiempo, te cobra intereses.', 'It is a card for buying with money the bank lends you. If you don\'t pay it all on time, it charges you interest.'),
      tr('Compras \$1,000 con la tarjeta. Si pagas los \$1,000 antes de la fecha límite, normalmente no pagas intereses.', 'You buy \$1,000 with the card. If you pay the \$1,000 before the due date, you usually pay no interest.'), picCreditCard),
  Term('limit', TermKind.credit, tr('Límite de crédito', 'Credit limit'), trOf(['límite de crédito'], ['credit limit']),
      tr('Es lo más que puedes deber en una tarjeta de crédito.', 'It is the most you can owe on a credit card.'),
      tr('Con un límite de \$10,000, puedes deber hasta \$10,000 en la tarjeta.', 'With a \$10,000 limit, you can owe up to \$10,000 on the card.'), picCreditLimit),
  Term('minimum', TermKind.credit, tr('Pago mínimo', 'Minimum payment'), trOf(['pagos mínimos', 'pago mínimo', 'el mínimo', 'lo mínimo'], ['minimum payments', 'minimum payment', 'the minimum']),
      tr('Es lo menos que el banco te pide pagar cada mes. Si pagas solo eso, la deuda baja muy despacio.', 'It is the least the bank asks you to pay each month. If you pay only that, the debt goes down very slowly.'),
      tr('Debes \$1,000 y el mínimo es \$50: casi todo el pago se va en intereses y la deuda casi no baja.', 'You owe \$1,000 and the minimum is \$50: almost all of the payment goes on interest and the debt hardly goes down.'), picMinimum),
  Term('debt', TermKind.credit, tr('Deuda', 'Debt'), trOf(['deudas', 'deuda'], ['debts', 'debt']),
      tr('Una deuda es el dinero que debes y tienes que pagar.', 'A debt is money you owe and have to pay back.'),
      tr('Te prestaron \$500 y ya pagaste \$200: tu deuda es de \$300.', 'You borrowed \$500 and have paid \$200: your debt is \$300.'), picDebt),
  Term('partpayment', TermKind.credit, tr('Abono', 'Partial payment'), trOf(['abonos', 'abono', 'abonar'], ['partial payments', 'partial payment']),
      tr('Un abono es un pago de una parte de lo que debes.', 'A partial payment pays part of what you owe.'),
      tr('Debes \$600 y das un abono de \$100: ahora debes \$500.', 'You owe \$600 and make a \$100 partial payment: now you owe \$500.'), picPartPayment),
  Term('term', TermKind.credit, tr('Plazo', 'Term'), trOf(['plazos', 'plazo'], ['term']),
      tr('El plazo es el tiempo que tienes para pagar todo un préstamo.', 'The term is the time you have to pay back a whole loan.'),
      tr('Un préstamo a un plazo de 12 meses se paga en 12 pagos.', 'A loan with a 12-month term is paid in 12 payments.'), picTerm),
  Term('monthly', TermKind.credit, tr('Mensualidad', 'Monthly payment'), trOf(['mensualidades', 'mensualidad', 'pago al mes', 'pagos al mes'], ['monthly payments', 'monthly payment']),
      tr('La mensualidad es lo que pagas cada mes de una compra o un préstamo.', 'The monthly payment is what you pay each month for a purchase or a loan.'),
      tr('\$1,200 en 6 mensualidades iguales son \$200 al mes, si no hay intereses.', '\$1,200 in 6 equal monthly payments is \$200 a month, if there is no interest.'), picMonthly),
  Term('msi', TermKind.credit, tr('Meses sin intereses', 'Interest-free months'), trOf(['meses sin intereses', 'msi'], ['meses sin intereses', 'interest-free months', 'interest-free']),
      tr('Es pagar una compra en partes iguales cada mes sin pagar de más, si pagas cada mes a tiempo.', 'It is paying for a purchase in equal parts each month without paying extra, as long as you pay on time every month.'),
      tr('Una tele de \$6,000 a 6 meses sin intereses: \$1,000 cada mes.', 'A \$6,000 TV over 6 interest-free months: \$1,000 a month.'), picInterestFree),
  Term('fee', TermKind.credit, tr('Comisión', 'Fee'), trOf(['comisiones', 'comisión'], ['fees', 'fee']),
      tr('Una comisión es un cobro extra por un servicio, como abrir un crédito o sacar dinero de un cajero.', 'A fee is an extra charge for a service, like opening a loan or taking money out of a cash machine.'),
      tr('Una comisión del 2% por un préstamo de \$1,000 son \$20.', 'A 2% fee on a \$1,000 loan is \$20.'), picFee),
  Term('cat', TermKind.credit, tr('CAT', 'CAT (total annual cost)'), trOf(['cat', 'costo anual total'], ['cat', 'total annual cost']),
      tr('El CAT, Costo Anual Total, dice cuánto te cuesta de verdad un crédito al año, con intereses y comisiones. Sirve para comparar: mientras más bajo, más barato.',
          'The CAT, total annual cost, says what a loan really costs you per year, with interest and fees. It is for comparing: the lower, the cheaper. It is Mexico\'s version of the APR.'),
      tr('Un crédito con CAT de 30% cuesta menos que uno con CAT de 60%.', 'A loan with a 30% CAT costs less than one with a 60% CAT.'), picCat),
  Term('avalanche', TermKind.credit, tr('Avalancha', 'Avalanche'), trOf(['avalancha'], ['avalanche']),
      tr('Una forma de salir de deudas: pagas el mínimo de todas y lo que sobra va a la de tasa más alta.', 'A way out of debt: you pay the minimum on all of them and what is left goes to the one with the highest rate.'),
      tr('Si una deuda cobra 60% y otra 30%, primero acabas la del 60%.', 'If one debt charges 60% and another 30%, you finish the 60% one first.'), picAvalanche),
  Term('snowball', TermKind.credit, tr('Bola de nieve', 'Snowball'), trOf(['bola de nieve'], ['snowball']),
      tr('Una forma de salir de deudas: pagas el mínimo de todas y lo que sobra va a la deuda más chica.', 'A way out of debt: you pay the minimum on all of them and what is left goes to the smallest debt.'),
      tr('Si debes \$500 en una y \$5,000 en otra, primero acabas la de \$500.', 'If you owe \$500 on one and \$5,000 on another, you finish the \$500 one first.'), picSnowball),
  Term('history', TermKind.credit, tr('Historial de crédito', 'Credit history'), trOf(['historial de crédito', 'historial crediticio', 'buró de crédito', 'círculo de crédito'], ['credit history', 'credit bureau']),
      tr('Es el registro de cómo has pagado tus créditos. Lo guardan empresas como el Buró de Crédito.', 'It is the record of how you have paid your loans. Companies called credit bureaus keep it.'),
      tr('Si pagas tus créditos a tiempo, tu historial se ve bien y es más fácil que te presten.', 'If you pay your loans on time, your history looks good and it is easier to borrow.'), picCreditHistory),

  // ---------------------------------------------------------------- saving
  Term('saving', TermKind.saving, tr('Ahorro', 'Saving'),
      trOf(['ahorros', 'ahorro', 'ahorrar', 'ahorras', 'ahorran', 'ahorramos', 'ahorrando'], ['savings', 'saving', 'save']),
      tr('Ahorrar es guardar una parte de tu dinero para después.', 'Saving is keeping part of your money for later.'),
      tr('Si guardas \$50 cada semana, en 4 semanas tienes \$200.', 'If you put away \$50 each week, in 4 weeks you have \$200.'), picSaving),
  Term('tanda', TermKind.saving, tr('Tanda', 'Tanda'), trOf(['tandas', 'tanda'], ['tandas', 'tanda']),
      tr('En una tanda, varias personas ponen lo mismo cada semana o quincena, y cada vez a una le toca todo el dinero.', 'In a tanda, several people put in the same amount each week or fortnight, and each time one of them gets all the money.'),
      tr('5 personas ponen \$100: a quien le toca recibe \$500. Al final, cada quien recibió lo mismo que puso.', '5 people put in \$100: whoever\'s turn it is gets \$500. In the end, everyone got back what they put in.'), picTanda),
  Term('cetes', TermKind.saving, tr('CETES', 'CETES'), trOf(['cetes'], ['cetes']),
      tr('Los CETES son una forma de ahorrar prestándole dinero al gobierno de México, que te lo regresa con un poco más.', 'CETES are a way to save by lending money to the Mexican government, which pays it back with a little extra.'),
      tr('Pones \$100 y, al terminar el plazo, te regresan tus \$100 y un poco de interés.', 'You put in \$100 and, at the end of the term, you get your \$100 back plus a little interest.'), picCetes),
  Term('afore', TermKind.saving, tr('Afore', 'Afore'), trOf(['afores', 'afore'], ['afore']),
      tr('La Afore es la cuenta donde se junta dinero para tu retiro, para cuando ya no trabajes.', 'The Afore is the account where money builds up for your retirement, for when you no longer work.'),
      tr('Si tienes un trabajo con seguro social, cada cierto tiempo se deposita dinero en tu Afore. Tú también puedes ponerle, aunque sea poco.', 'If you have a job with social security, money is paid into your Afore regularly. You can add to it yourself too, even a little.'), picAfore),
  Term('wellbeing', TermKind.saving, tr('Bienestar financiero', 'Financial well-being'), trOf(['bienestar financiero'], ['financial well-being']),
      tr('Es sentir que tienes el control de tu dinero hoy y que vas a estar bien después.', 'It is feeling in control of your money today and that you will be all right later.'),
      tr('Tener un poco ahorrado para una emergencia ayuda a tu bienestar financiero.', 'Having a little saved for an emergency helps your financial well-being.'), picWellbeing),

  // ---------------------------------------------------------------- where to ask
  Term('banxico', TermKind.help, tr('Banco de México', 'Banco de México'), trOf(['banco de méxico', 'banxico'], ['banco de méxico', 'banxico']),
      tr('Es el banco central de México: cuida el valor del peso y pone reglas a los bancos. No le presta dinero a las personas.', 'It is Mexico\'s central bank: it looks after the value of the peso and sets rules for banks. It does not lend money to people.'),
      tr('Banco de México tiene una calculadora para conocer el CAT de un crédito.', 'Banco de México has a calculator to find a loan\'s CAT.'), picBanxico),
  Term('condusef', TermKind.help, tr('CONDUSEF', 'CONDUSEF'), trOf(['condusef'], ['condusef']),
      tr('Es la oficina del gobierno que te orienta y te ayuda si tienes un problema con un banco, una tarjeta, un seguro o un crédito.', 'It is the government office that advises and helps you if you have a problem with a bank, a card, insurance or a loan.'),
      tr('Si el banco te cobra algo que no reconoces, puedes pedir ayuda a la CONDUSEF.', 'If the bank charges you something you don\'t recognise, you can ask CONDUSEF for help.'), picCondusef),
  Term('profeco', TermKind.help, tr('PROFECO', 'PROFECO'), trOf(['profeco'], ['profeco']),
      tr('Es la oficina del gobierno que te ayuda si tienes un problema con una tienda o una compra.', 'It is the government office that helps you if you have a problem with a store or a purchase.'),
      tr('Si una tienda no respeta el precio que anunció, puedes quejarte con la PROFECO.', 'If a store doesn\'t honour the price it advertised, you can complain to PROFECO.'), picProfeco),
];

/// The term with this id, in the current language
Term? termById(String id) => terms.where((t) => t.id == id).firstOrNull;

// ---------------------------------------------------------------- finding terms in a sentence

/// A term found in a sentence: text[start, end) is how it's written there
class TermMatch {
  final int start;
  final int end;
  final Term term;
  const TermMatch(this.start, this.end, this.term);
}

const _plain = {'á': 'a', 'é': 'e', 'í': 'i', 'ó': 'o', 'ú': 'u', 'ü': 'u', 'à': 'a', 'è': 'e', 'ì': 'i', 'ò': 'o', 'ù': 'u'};

/// Lower case without accents, one character for one character (so positions stay the same)
String _fold(String s) => s.toLowerCase().split('').map((c) => _plain[c] ?? c).join();

final _wordChar = RegExp(r'[a-z0-9ñ]');

class _Index {
  final List<(String, String, Term)> forms; // (folded, lower case as written, term), longest first
  _Index(List<Term> all)
    : forms = [
        for (final t in all)
          for (final f in t.allForms) (_fold(f), f.toLowerCase(), t),
      ]..sort((a, b) => b.$1.length.compareTo(a.$1.length));
}

/// An accent in the text must be in the form too ("cambió" is not "cambio"); a missing one is fine ("credito")
bool _accentsAgree(String text, int at, String form) {
  for (var i = 0; i < form.length; i++) {
    final c = text[at + i].toLowerCase();
    if (_plain.containsKey(c) && form[i] != c) return false;
  }
  return true;
}

final _indexes = <bool, _Index>{};

/// [phrase] appears in [text] around [start, end)
bool _covers(String text, String phrase, int start, int end) {
  for (var at = text.indexOf(phrase); at >= 0; at = text.indexOf(phrase, at + 1)) {
    if (at <= start && at + phrase.length >= end) return true;
  }
  return false;
}

/// The glossary terms in [text], in order, without overlaps: longest forms first, accents and case ignored, whole
/// words only, each term once (its first appearance). [exclude]: term ids not to mark (e.g. the card's own term).
List<TermMatch> findTerms(String text, {Set<String> exclude = const {}}) {
  if (text.isEmpty) return const [];
  final index = _indexes[Tr.english] ??= _Index(terms);
  final folded = _fold(text);
  final taken = List<bool>.filled(text.length, false);
  final found = <String>{};
  final out = <TermMatch>[];
  for (final (form, written, term) in index.forms) {
    if (exclude.contains(term.id) || found.contains(term.id) || form.isEmpty) continue;
    for (var at = folded.indexOf(form); at >= 0; at = folded.indexOf(form, at + 1)) {
      final end = at + form.length;
      final before = at == 0 ? '' : folded[at - 1], after = end >= folded.length ? '' : folded[end];
      if (_wordChar.hasMatch(before) || _wordChar.hasMatch(after)) continue;
      if (written.length == form.length && !_accentsAgree(text, at, written)) continue;
      if (term.avoid.any((p) => _covers(folded, _fold(p), at, end))) continue;
      if (Iterable.generate(form.length, (i) => taken[at + i]).any((t) => t)) continue;
      for (var i = at; i < end; i++) {
        taken[i] = true;
      }
      out.add(TermMatch(at, end, term));
      found.add(term.id);
      break;
    }
  }
  return out..sort((a, b) => a.start.compareTo(b.start));
}
