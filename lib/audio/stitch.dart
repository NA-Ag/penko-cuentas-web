// stitch.dart — lines with numbers that change can't each be recorded, so they're built from pieces, like a station
// announcement: each sentence part once ("En las decenas:", "¿Cuánto da?") and each number from its parts ("mil",
// "doscientos", "34"). A line turns into a list of clips; if one is missing, Penko says the whole line with the
// device's voice instead. Plain Dart: tool/voice_fragments_test.dart uses it to list every clip to make.

class Clip {
  final String id; // the file's name
  final String text; // what it says
  const Clip(this.id, this.text);
}

/// A short name for a text. It must come out the same in the tool (the Dart VM) and on the website (JavaScript, whose
/// numbers lose digits past 2^53), so every step stays well under that.
String _name(String text) {
  var h = 7;
  for (final c in text.codeUnits) {
    h = (h * 131 + c) % 2147483629;
  }
  return 'x${h.toRadixString(16)}';
}

/// The same words with or without a final full stop are one clip: "Una niña" in a list and "Una niña." in a sentence
Clip _words(String text) => Clip(_name(text.replaceFirst(RegExp(r'[.,;:]+$'), '')), text);

const _hundredsEs = ['ciento', 'doscientos', 'trescientos', 'cuatrocientos', 'quinientos', 'seiscientos', 'setecientos', 'ochocientos', 'novecientos'];

/// [n] as clips, or null past a million (none of the lessons get there)
List<Clip>? _number(int n, bool es) {
  if (n >= 1000000) return null;
  final out = <Clip>[];
  if (n >= 1000) {
    final k = n ~/ 1000;
    if (k > 1 || !es) out.addAll(_number(k, es)!);
    out.add(_words(es ? 'mil' : 'thousand'));
    n %= 1000;
    if (n == 0) return out;
  }
  if (n >= 100) {
    final h = n ~/ 100;
    if (es) {
      out.add(n == 100 ? _words('cien') : _words(_hundredsEs[h - 1]));
    } else {
      out.addAll([Clip('n$h', '$h'), _words('hundred')]);
    }
    n %= 100;
    if (n == 0) return out;
  }
  return out..add(Clip('n$n', '$n'));
}

/// Every number clip there is
List<Clip> numberClips(bool es) => [
  for (var n = 0; n < 100; n++) Clip('n$n', '$n'),
  for (final w in es ? [..._hundredsEs, 'cien', 'mil', 'con', 'centavos', 'pesos', 'por ciento', 'pesos con'] : ['hundred', 'thousand', 'point', 'percent', 'pesos'])
    _words(w),
];

final _token = RegExp(r'\$?(\d{1,3}(?:,\d{3})+|\d+)(?:\.(\d+))?( ?%)?');
final _sentence = RegExp(r'(?<=[.!?:…])\s+(?=[^\s])');

/// The clips of a line as Penko says it (spoken()), or null if it can't be built
List<Clip>? clipsOf(String line, bool es) {
  final out = <Clip>[];
  void text(String t) {
    for (var part in t.split(_sentence)) {
      part = part.replaceFirst(RegExp(r'^[\s,;:.]+'), '').trim();
      if (part.replaceAll(RegExp(r'[^\p{L}]', unicode: true), '').isNotEmpty) out.add(_words(part));
    }
  }

  var at = 0;
  for (final m in _token.allMatches(line)) {
    text(line.substring(at, m.start));
    at = m.end;
    final whole = _number(int.parse(m[1]!.replaceAll(',', '')), es);
    if (whole == null) return null;
    out.addAll(whole);
    final cents = m[2], amount = m[0]!.startsWith(r'$');
    if (cents != null) {
      if (es && amount) out.add(_words('pesos con'));
      if (es && !amount) out.add(_words('con'));
      if (!es) out.add(_words('point'));
      out.addAll(_number(int.parse(cents), es)!);
      if (es && amount) out.add(_words('centavos'));
    } else if (amount) {
      out.add(_words('pesos'));
    }
    if (m[3] != null) out.add(_words(es ? 'por ciento' : 'percent'));
  }
  text(line.substring(at));
  return out;
}
