// check.dart — the engine's say over what the model writes. A reply from the model reaches the student only if every
// number in it is one the engine gave it (or 0, 1, 10, 100, as in "llevamos 1", or comes out of / goes into a true
// sum with verified numbers), every written sum is true, and it
// doesn't give away an answer the student should find, and its words match what happens (no "prestado" in a sum, only
// the places the problem has). Otherwise Penko says her own written line instead.
// The same rules filter the training data (eval/distill/check.py), so the model learns what passes.

import '../i18n/tr.dart';

final _number = RegExp(r'\d{1,3}(?:,\d{3})+(?:\.\d+)?|\d+(?:\.\d+)?');
const _term = r'\$?\s?(?:\d{1,3}(?:,\d{3})+|\d+)(?:\.\d+)?\s?%?';
final _sum = RegExp('($_term(?:\\s*[+−\\-×x*÷/]\\s*$_term)+)\\s*=\\s*($_term)');

/// Numbers written in words, whole phrases included ("mil novecientos sesenta" = 1960), so the guards see them too.
/// "Un"/"una" are left out: they're mostly articles ("una columna").
const _units = {
  'cero': 0, 'uno': 1, 'dos': 2, 'tres': 3, 'cuatro': 4, 'cinco': 5, 'seis': 6, 'siete': 7, 'ocho': 8, 'nueve': 9,
  'diez': 10, 'once': 11, 'doce': 12, 'trece': 13, 'catorce': 14, 'quince': 15, 'dieciséis': 16, 'dieciseis': 16,
  'diecisiete': 17, 'dieciocho': 18, 'diecinueve': 19, 'veinte': 20, 'veintiuno': 21, 'veintidós': 22, 'veintidos': 22,
  'veintitrés': 23, 'veintitres': 23, 'veinticuatro': 24, 'veinticinco': 25, 'veintiséis': 26, 'veintiseis': 26,
  'veintisiete': 27, 'veintiocho': 28, 'veintinueve': 29, 'treinta': 30, 'cuarenta': 40, 'cincuenta': 50,
  'sesenta': 60, 'setenta': 70, 'ochenta': 80, 'noventa': 90, 'cien': 100, 'ciento': 100, 'doscientos': 200,
  'doscientas': 200, 'trescientos': 300, 'trescientas': 300, 'cuatrocientos': 400, 'cuatrocientas': 400,
  'quinientos': 500, 'quinientas': 500, 'seiscientos': 600, 'seiscientas': 600, 'setecientos': 700,
  'setecientas': 700, 'ochocientos': 800, 'ochocientas': 800, 'novecientos': 900, 'novecientas': 900,
};
// Longest words first, each a whole word, so "doscientos" isn't read as "dos"
final _words = ([..._units.keys, 'mil']..sort((a, b) => b.length - a.length)).join('|');
final _phrase = RegExp('\\b(?:$_words)\\b(?:(?:\\s+y\\s+|\\s+)(?:$_words)\\b)*', caseSensitive: false);

/// The value of a phrase like "mil novecientos sesenta y dos"
double _phraseValue(String phrase) {
  var total = 0, current = 0;
  for (final w in phrase.toLowerCase().split(RegExp(r'\s+'))) {
    if (w == 'y' || w.isEmpty) continue;
    if (w == 'mil') {
      total += (current == 0 ? 1 : current) * 1000;
      current = 0;
    } else {
      current += _units[w] ?? 0;
    }
  }
  return (total + current).toDouble();
}

/// The same in English, for students using the app in English. "One" is left out like "un": it's mostly a pronoun.
const _unitsEn = {
  'zero': 0, 'two': 2, 'three': 3, 'four': 4, 'five': 5, 'six': 6, 'seven': 7, 'eight': 8, 'nine': 9, 'ten': 10,
  'eleven': 11, 'twelve': 12, 'thirteen': 13, 'fourteen': 14, 'fifteen': 15, 'sixteen': 16, 'seventeen': 17,
  'eighteen': 18, 'nineteen': 19, 'twenty': 20, 'thirty': 30, 'forty': 40, 'fifty': 50, 'sixty': 60, 'seventy': 70,
  'eighty': 80, 'ninety': 90,
};
final _wordsEn = ([..._unitsEn.keys, 'hundred', 'thousand']..sort((a, b) => b.length - a.length)).join('|');
final _phraseEn = RegExp('\\b(?:$_wordsEn)\\b(?:(?:\\s+and\\s+|[\\s-]+)(?:$_wordsEn)\\b)*', caseSensitive: false);

/// The value of a phrase like "two hundred and forty-five"
double _phraseValueEn(String phrase) {
  var total = 0, current = 0;
  for (final w in phrase.toLowerCase().split(RegExp(r'[\s-]+'))) {
    if (w == 'hundred') {
      current = (current == 0 ? 1 : current) * 100;
    } else if (w == 'thousand') {
      total += (current == 0 ? 1 : current) * 1000;
      current = 0;
    } else {
      current += _unitsEn[w] ?? 0;
    }
  }
  return (total + current).toDouble();
}

/// Every number written in [text], in digits or in words of the language the app is in
Set<double> numbersIn(String text) => {
  for (final m in _number.allMatches(text)) double.parse(m[0]!.replaceAll(',', '')),
  if (Tr.english)
    for (final m in _phraseEn.allMatches(text)) _phraseValueEn(m[0]!)
  else
    // "por ciento" is the % sign, not a hundred
    for (final m in _phrase.allMatches(text.replaceAll(RegExp(r'por\s+ciento', caseSensitive: false), '%')))
      _phraseValue(m[0]!),
};

double _value(String term) => double.parse(term.replaceAll(RegExp(r'[\$%,\s]'), ''));

/// A written sum, worked left to right with × and ÷ first ("7 + 5 + 1", "1,200 × 6", "6000 ÷ 10")
double? _evaluate(String left) {
  final tokens = RegExp(r'(\d[\d,]*(?:\.\d+)?)|([+−\-×x*÷/])')
      .allMatches(left.replaceAll(RegExp(r'[\$%\s]'), ''))
      .map((m) => m[0]!)
      .toList();
  final terms = <double>[];
  final ops = <String>[];
  for (final t in tokens) {
    if (RegExp(r'^\d').hasMatch(t)) {
      var v = double.parse(t.replaceAll(',', ''));
      if (ops.isNotEmpty && (ops.last == '×' || ops.last == 'x' || ops.last == '*' || ops.last == '÷' || ops.last == '/')) {
        final op = ops.removeLast();
        final prev = terms.removeLast();
        v = op == '÷' || op == '/' ? (v == 0 ? double.nan : prev / v) : prev * v;
      }
      terms.add(v);
    } else {
      ops.add(t);
    }
  }
  if (terms.isEmpty || ops.length != terms.length - 1) return null;
  var total = terms.first;
  for (var i = 0; i < ops.length; i++) {
    total = ops[i] == '+' ? total + terms[i + 1] : total - terms[i + 1];
  }
  return total;
}

/// False if any sum written in [text] is wrong
bool sumsAreTrue(String text) {
  for (final m in _sum.allMatches(text)) {
    final got = _evaluate(m[1]!);
    if (got == null || got.isNaN || (got - _value(m[2]!)).abs() > 0.011) return false;
  }
  return true;
}

/// Words for the operation and the places must match what the engine says happens: "prestado" never in a sum or a
/// multiplication, "llevar" never in a subtraction, no carrying or borrowing the facts don't have, and only places
/// the problem has. Money facts (no "Operación:" line) skip this check.
bool meaningMatches(String text, String facts) {
  final op = RegExp(r'Operación: [\d,]+ ([+−×]) ').firstMatch(facts)?[1];
  if (op == null) return true;
  final t = text.toLowerCase(), f = facts.toLowerCase();
  final borrows = RegExp(r'prest|\bborrow').hasMatch(t), carries = RegExp(r'\bllev(a|o|amos|ar|aste|é)|\bcarr(y|ies|ied)').hasMatch(t);
  if (op != '−' && borrows) return false;
  if (op == '−' && carries) return false;
  if (carries && !f.contains('llevamos')) return false;
  if (borrows && !RegExp(r'prest').hasMatch(f)) return false;
  // "unidades de millar" first, so its "unidades" isn't counted twice
  for (final place in ['unidades de millar', 'decenas de millar', 'centenas', 'decenas', 'unidades']) {
    if (t.contains(place) && !f.contains(place)) return false;
  }
  return true;
}

/// The model's reply, cleaned up, if the engine can vouch for it; null if Penko should use her own line
String? checked(String reply, {required String facts, required String question, Set<double> forbidden = const {}}) {
  final text = reply.replaceAll('**', '').replaceAll(RegExp(r'<[^>]+>'), '').trim();
  final words = text.split(RegExp(r'\s+')).length;
  if (words < 4 || words > 90) return null;
  // Penko's voice: warm and respectful, never patronising, straight to the point (no greeting)
  if (RegExp(r"^\W*hola\b|\btranquil[oa]\b|no te preocupes|\bmi niñ[oa]\b|\bpequeñ[oa]\b|\bcampe[oó]n|^\W*(hi|hello)\b|don'?t worry|\bsweetie\b|\bchamp\b",
          caseSensitive: false)
      .hasMatch(text)) {
    return null;
  }
  // Cut off before it finished, or written for a computer screen (maths code, numbered steps, headings)
  if (!RegExp(r'[.!?…)"»]$').hasMatch(text)) return null;
  if (RegExp(r'\\[a-z]+|\$[^\s]*\\|^\s*(\d+\.|[-*•#]|Paso \d)', multiLine: true).hasMatch(text)) return null;
  if (RegExp(r'\$[^$\n]+?\$(?!\s?\d)').hasMatch(text)) return null; // a sum in maths dollars: "$16 - 9 = 7$"
  if (!sumsAreTrue(text)) return null;
  if (!meaningMatches(text, facts)) return null;
  // Always fine: 0, 1, 10, 100 ("llevamos 1", "divide entre 10") and 9 ("si da más de 9, llevamos")
  final allowed = {...numbersIn(facts), ...numbersIn(question), 0.0, 1.0, 9.0, 10.0, 100.0};
  // Every sum is true by now, so a sum built from verified numbers gives a verified number ("1,900 ÷ 10 = 190"), and a
  // sum that ends in a verified number may use its own small steps ("190 × 2 = 380")
  final sums = [for (final m in _sum.allMatches(text)) (numbersIn(m[1]!), _value(m[2]!))];
  for (var grew = true; grew;) {
    grew = false;
    for (final (operands, result) in sums) {
      if (allowed.containsAll(operands) && !allowed.contains(result)) {
        allowed.add(result);
        grew = true;
      } else if (allowed.contains(result) && !allowed.containsAll(operands)) {
        allowed.addAll(operands);
        grew = true;
      }
    }
  }
  if (!allowed.containsAll(numbersIn(text))) return null;
  if (numbersIn(text).any(forbidden.contains)) return null;
  return text;
}
