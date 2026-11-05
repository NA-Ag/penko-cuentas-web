// pictograms.dart — the glossary's pictures: one small pixel pictogram per word, like the Mexico City Metro's station
// signs, so a word can be recognised without reading it. Each is a 32×32 grid of letters (one letter per colour, '.'
// is clear; see glossary_widgets.dart for the colours), drawn in code from a few shapes (coins, tags, calendars,
// people…) so they share one style: bold shapes with a dark outline. Plain Dart (no Flutter), so tool/voice_keys.dart
// and the tests can read the term list.
//
// Colours: k outline · w white · e silver · t grey · d dark grey · y gold · o dark gold · s sand · g green ·
// l light green · G dark green · b blue · B deep blue · r coral · c orange · p plum · m pink · n wood
import 'dart:math' as math;

// The app's places (tabs, units, lessons, simulators, resources) are drawn in the same style: place_pictograms.dart
part 'place_pictograms.dart';

typedef Pic = List<String>;

const _s = 2; // drawn in a 16 × 16 space (all coordinates below), rendered at twice that
const _n = 16 * _s; // every pictogram is 32 × 32

// ---------------------------------------------------------------- drawing

/// A shape, tested at each pixel's centre
typedef _Mask = bool Function(double x, double y);

abstract class _Op {
  void apply(List<List<String>> g);
}

/// A filled shape with a dark outline (the pixels on its edge), or without one
class _Fill extends _Op {
  final _Mask mask;
  final String fill;
  final bool outline;
  _Fill(this.mask, this.fill, {this.outline = true});

  bool _in(int x, int y) => x >= 0 && y >= 0 && x < _n && y < _n && mask((x + 0.5) / _s, (y + 0.5) / _s);

  @override
  void apply(List<List<String>> g) {
    for (var y = 0; y < _n; y++) {
      for (var x = 0; x < _n; x++) {
        if (!_in(x, y)) continue;
        final edge = !_in(x - _s, y) || !_in(x + _s, y) || !_in(x, y - _s) || !_in(x, y + _s);
        g[y][x] = outline && edge ? 'k' : fill;
      }
    }
  }
}

/// Cuts a shape out (clear), outlining what's left around the cut
class _Cut extends _Op {
  final _Mask mask;
  _Cut(this.mask);

  @override
  void apply(List<List<String>> g) {
    final cut = <(int, int)>{};
    for (var y = 0; y < _n; y++) {
      for (var x = 0; x < _n; x++) {
        if (mask((x + 0.5) / _s, (y + 0.5) / _s) && g[y][x] != '.') {
          g[y][x] = '.';
          cut.add((x, y));
        }
      }
    }
    for (final (x, y) in cut) {
      for (final (dx, dy) in const [(1, 0), (-1, 0), (0, 1), (0, -1), (2, 0), (-2, 0), (0, 2), (0, -2)]) {
        final nx = x + dx, ny = y + dy;
        if (nx >= 0 && ny >= 0 && nx < _n && ny < _n && g[ny][nx] != '.' && !cut.contains((nx, ny))) g[ny][nx] = 'k';
      }
    }
  }
}

/// A small hand-drawn picture placed at [x], [y] ('.' leaves what's under it)
class _Stamp extends _Op {
  final Pic pic;
  final int x, y;
  _Stamp(this.pic, this.x, this.y);

  @override
  void apply(List<List<String>> g) {
    // A finished pictogram is already at full size; a small hand-drawn part is doubled
    final s = pic.first.length == _n ? 1 : _s;
    for (var r = 0; r < pic.length; r++) {
      for (var c = 0; c < pic[r].length; c++) {
        final ch = pic[r][c];
        if (ch == '.') continue;
        for (var i = 0; i < s * s; i++) {
          final gx = x * _s + c * s + i % s, gy = y * _s + r * s + i ~/ s;
          if (gx >= 0 && gy >= 0 && gx < _n && gy < _n) g[gy][gx] = ch;
        }
      }
    }
  }
}

Pic _draw(List<_Op> ops) {
  final g = List.generate(_n, (_) => List.filled(_n, '.'));
  for (final op in ops) {
    op.apply(g);
  }
  _shade(g);
  return [for (final row in g) row.join()];
}

/// A darker edge along the bottom and right of each colour, so shapes look solid
const _darker = {'y': 'o', 'g': 'G', 'l': 'g', 'b': 'B', 'w': 'e', 'e': 't', 's': 'y', 'r': 'p', 'm': 'r', 'c': 'n'};

void _shade(List<List<String>> g) {
  final before = [for (final row in g) [...row]];
  for (var y = 0; y < _n; y++) {
    for (var x = 0; x < _n; x++) {
      final dark = _darker[before[y][x]];
      if (dark == null) continue;
      final below = y + 1 < _n ? before[y + 1][x] : '.', right = x + 1 < _n ? before[y][x + 1] : '.';
      if (below == 'k' || right == 'k') g[y][x] = dark;
    }
  }
}

// Shapes (pixel coordinates: 0–16 across and down)
_Mask _rect(int x0, int y0, int x1, int y1) => (x, y) => x >= x0 && x <= x1 + 1 && y >= y0 && y <= y1 + 1;
_Mask _circle(double cx, double cy, double r) => (x, y) => (x - cx) * (x - cx) + (y - cy) * (y - cy) <= r * r;
_Mask _ellipse(double cx, double cy, double rx, double ry) =>
    (x, y) => ((x - cx) / rx) * ((x - cx) / rx) + ((y - cy) / ry) * ((y - cy) / ry) <= 1;
_Mask _line(double x0, double y0, double x1, double y1, double width) => (x, y) {
  final dx = x1 - x0, dy = y1 - y0;
  final t = (((x - x0) * dx + (y - y0) * dy) / (dx * dx + dy * dy)).clamp(0.0, 1.0);
  final px = x0 + t * dx - x, py = y0 + t * dy - y;
  return math.sqrt(px * px + py * py) <= width / 2;
};
_Mask _poly(List<(double, double)> p) => (x, y) {
  var inside = false;
  for (var i = 0, j = p.length - 1; i < p.length; j = i++) {
    final (xi, yi) = p[i];
    final (xj, yj) = p[j];
    if ((yi > y) != (yj > y) && x < (xj - xi) * (y - yi) / (yj - yi) + xi) inside = !inside;
  }
  return inside;
};
_Mask _or(List<_Mask> ms) => (x, y) => ms.any((m) => m(x, y));
_Mask _and(_Mask a, _Mask b) => (x, y) => a(x, y) && b(x, y);

/// Swaps colours in a small picture
Pic _tint(Pic p, Map<String, String> swap) => [for (final row in p) row.split('').map((c) => swap[c] ?? c).join()];

Pic _flip(Pic p) => [for (final row in p) row.split('').reversed.join()];

/// Each pixel becomes [s] × [s]
Pic _scale(Pic p, int s) => [
  for (final row in p)
    for (var i = 0; i < s; i++) row.split('').map((c) => c * s).join(),
];

// ---------------------------------------------------------------- small parts

/// A 3×5 pixel font for the few numbers and letters drawn in pictures
const _glyphs = <String, Pic>{
  '0': ['kkk', 'k.k', 'k.k', 'k.k', 'kkk'],
  '1': ['.k.', 'kk.', '.k.', '.k.', 'kkk'],
  '2': ['kk.', '..k', '.k.', 'k..', 'kkk'],
  '3': ['kk.', '..k', '.k.', '..k', 'kk.'],
  '4': ['k.k', 'k.k', 'kkk', '..k', '..k'],
  '5': ['kkk', 'k..', 'kk.', '..k', 'kk.'],
  '8': ['kkk', 'k.k', 'kkk', 'k.k', 'kkk'],
  'A': ['.k.', 'k.k', 'kkk', 'k.k', 'k.k'],
  'C': ['.kk', 'k..', 'k..', 'k..', '.kk'],
  'I': ['kkk', '.k.', '.k.', '.k.', 'kkk'],
  'T': ['kkk', '.k.', '.k.', '.k.', '.k.'],
  'V': ['k.k', 'k.k', 'k.k', 'k.k', '.k.'],
  '%': ['k.k', '..k', '.k.', 'k..', 'k.k'],
};

/// [s] in the small font, in colour [ink]
Pic _text(String s, {String ink = 'k'}) {
  final rows = List.generate(5, (_) => StringBuffer());
  for (var i = 0; i < s.length; i++) {
    final g = _glyphs[s[i]]!;
    for (var r = 0; r < 5; r++) {
      if (i > 0) rows[r].write('.');
      rows[r].write(g[r]);
    }
  }
  return [for (final r in rows) _tint([r.toString()], {'k': ink}).first];
}

const Pic _dollar = [
  '..k..',
  '.kkkk',
  'k.k..',
  '.kkk.',
  '..k.k',
  'kkkk.',
  '..k..',
];

const Pic _percent = [
  'kk...k.',
  'kk..k..',
  '...k...',
  '..k....',
  '.k..kk.',
  'k...kk.',
];

const Pic _arrowRight = [
  '...k...',
  '...kk..',
  'kkkkkk.',
  'kkkkkkk',
  'kkkkkk.',
  '...kk..',
  '...k...',
];

const Pic _arrowSmall = [
  '..k..',
  'kkkk.',
  'kkkkk',
  'kkkk.',
  '..k..',
];

Pic _rotateLeft(Pic p) => [
  for (var c = p.first.length - 1; c >= 0; c--) [for (final row in p) row[c]].join(),
];

final Pic _arrowLeft = _flip(_arrowRight);
final Pic _arrowUp = _rotateLeft(_arrowRight);
final Pic _arrowDown = [..._arrowUp.reversed];

const Pic _sprout = [
  'GG...GG',
  'GlG.GlG',
  '.GlGlG.',
  '..GGG..',
  '...G...',
  '...G...',
];

const Pic _person = [
  '.kkk.',
  'kssk.',
  'ksssk',
  '.kkk.',
  'kbbbk',
  'kbbbk',
  'kbbbk',
  '.k.k.',
];

const Pic _miniPerson = [
  '.kk.',
  'kssk',
  '.kk.',
  'kbbk',
  'kbbk',
];

const Pic _chain = [
  '.ddd..ddd..ddd.',
  'd...dd...dd...d',
  'd...dd...dd...d',
  '.ddd..ddd..ddd.',
];

const Pic _elder = [
  '..kkk...',
  '.ktttk..',
  '.ksssk..',
  '..kkk...',
  '.kkkkk..',
  'kpppppk.',
  'kpppppkn',
  'kpppppkn',
  'kpppppkn',
  '.kpppk.n',
  '.kk.kk.n',
  '.kk.kk.n',
  'kkk.kkkn',
  '.......n',
];

// Parts drawn as shapes
List<_Op> _coin(double cx, double cy, double r, {String fill = 'y'}) => [
  _Fill(_circle(cx, cy, r), fill),
  if (r >= 3) _Fill(_circle(cx - r * 0.4, cy - r * 0.4, r * 0.22 + 0.3), 'w', outline: false),
];

/// A price tag, its point and hole on the left, between rows [top] and [bottom]
List<_Op> _tag(int top, int bottom, {int right = 15, String fill = 'y'}) {
  final mid = (top + bottom + 1) / 2;
  return [
    _Fill(_poly([(0, mid), (4, top.toDouble()), (right + 1.0, top.toDouble()), (right + 1.0, bottom + 1.0), (4, bottom + 1.0)]), fill),
    _Fill(_circle(4, mid, 1.1), 'k', outline: false),
  ];
}

/// A wallet, rows [top] to 15
List<_Op> _wallet(int top, {List<String>? parts}) => [
  _Fill(_rect(0, top, 15, 15), 'n'),
  if (parts != null)
    for (final (i, c) in parts.indexed) _Fill(_rect(1 + i * 5, top + 1, 4 + i * 5, 14), c, outline: false),
  if (parts != null)
    for (var i = 1; i < parts.length; i++) _Fill(_rect(i * 5, top + 1, i * 5, 14), 'k', outline: false),
  if (parts == null) ...[
    _Fill(_rect(8, top + 3, 15, top + 7), 'y'),
    _Fill(_rect(10, top + 5, 10, top + 5), 'w', outline: false),
  ],
];

/// A wall calendar, rows [top] to [bottom], with some days in gold
List<_Op> _calendar(int top, int bottom, {Set<(int, int)> gold = const {}}) => [
  _Fill(_rect(0, top + 1, 15, bottom), 'w'),
  _Fill(_rect(0, top + 1, 15, top + 4), 'r'),
  for (final x in const [4, 11]) _Fill(_rect(x, top, x, top + 2), 'k', outline: false),
  // the days: a grid of little squares
  for (var row = 0; top + 6 + row * 3 + 1 <= bottom - 1; row++)
    for (var col = 0; col < 4; col++)
      _Fill(_rect(2 + col * 3 + (col > 1 ? 1 : 0), top + 6 + row * 3, 3 + col * 3 + (col > 1 ? 1 : 0), top + 7 + row * 3),
          gold.contains((col, row)) ? 'g' : 'e', outline: false),
];

/// A government building (columns under a triangle roof), its left edge at [x0], [w] wide, rows [top] to 15
List<_Op> _building(int x0, int w, int top, {String columns = 'e'}) {
  final roofBottom = top + (w >= 12 ? 4 : 3);
  final count = w ~/ 3, start = x0 + (w - count * 3) ~/ 2;
  return [
    _Fill(_poly([(x0.toDouble(), roofBottom + 1.0), (x0 + w / 2, top.toDouble()), (x0 + w + 0.0, roofBottom + 1.0)]), 's'),
    _Fill(_rect(x0, roofBottom, x0 + w - 1, roofBottom), 'k', outline: false),
    for (var i = 0; i < count; i++) ...[
      _Fill(_rect(start + i * 3, roofBottom + 1, start + i * 3 + 2, 12), 'k', outline: false),
      _Fill(_rect(start + i * 3 + 1, roofBottom + 1, start + i * 3 + 1, 12), columns, outline: false),
    ],
    _Fill(_rect(x0, 13, x0 + w - 1, 15), 's'),
  ];
}

/// A round "pizza" cut in four, with some quarters coloured (0 top-right, then clockwise)
List<_Op> _pie(double cx, double cy, double r, Set<int> coloured) => [
  _Fill(_circle(cx, cy, r), 'w'),
  for (final q in coloured)
    _Fill(
      _and(_circle(cx, cy, r - 0.9), (x, y) => switch (q) {
        0 => x > cx && y < cy,
        1 => x > cx && y > cy,
        2 => x < cx && y > cy,
        _ => x < cx && y < cy,
      }),
      'y',
      outline: false,
    ),
  _Fill(_and(_circle(cx, cy, r), (x, y) => (x - cx).abs() < 0.6 || (y - cy).abs() < 0.6), 'k', outline: false),
];

/// A credit card, rows [top] to [bottom]
List<_Op> _card(int top, int bottom) => [
  _Fill(_rect(0, top, 15, bottom), 'b'),
  _Fill(_rect(1, top + 2, 14, top + 3), 'k', outline: false),
  _Fill(_rect(2, top + 5, 5, top + 7), 'y'),
  if (bottom - top >= 9) _Fill(_rect(8, bottom - 2, 13, bottom - 2), 'w', outline: false),
];

/// A shield (for the offices that protect you)
List<_Op> _shield(String fill) => [
  _Fill(_poly([(1, 1), (15, 1), (15, 8), (8, 15.5), (1, 8)]), fill),
];

/// The written casita (long division): 84 ÷ 4 = 21
List<_Op> _casita({String divisor = 'k', String others = 'k'}) => [
  _Stamp(_text('21', ink: others), 7, 0),
  _Fill(_rect(4, 6, 15, 6), 'k', outline: false),
  _Fill(_rect(4, 6, 4, 13), 'k', outline: false),
  _Fill(_rect(3, 13, 3, 14), 'k', outline: false),
  _Stamp(_text('4', ink: divisor), 0, 8),
  _Stamp(_text('84', ink: others), 7, 8),
];

// ---------------------------------------------------------------- the pictograms

// Numbers and operations
final Pic picAdd = _draw([_Fill(_or([_rect(6, 1, 9, 14), _rect(1, 6, 14, 9)]), 'g')]);
final Pic picSubtract = _draw([_Fill(_rect(1, 6, 14, 9), 'c')]);
final Pic picMultiply = _draw([_Fill(_or([_line(2.5, 2.5, 13.5, 13.5, 3.6), _line(13.5, 2.5, 2.5, 13.5, 3.6)]), 'b')]);
final Pic picDivide = _draw([_Fill(_or([_rect(1, 6, 14, 9), _circle(8, 2.6, 2.6), _circle(8, 13.4, 2.6)]), 'p')]);
final Pic picTables = _draw([
  for (final y in const [1, 6, 11])
    for (final x in const [1, 6, 11]) _Fill(_rect(x, y, x + 3, y + 3), 'b'),
]);
final Pic picRemainder = _draw([
  for (final x in const [2.5, 8.5])
    for (final y in const [3.5, 8.5, 13.5]) _Fill(_circle(x, y, 2.3), 'b'),
  _Fill(_circle(13.5, 13.5, 2.3), 'r'),
]);
final Pic picCasita = _draw(_casita());
final Pic picDivisor = _draw(_casita(divisor: 'c', others: 't'));
final Pic picOnes = _draw([_Fill(_rect(3, 3, 12, 12), 'b'), _Fill(_rect(5, 5, 7, 7), 'w', outline: false)]);
final Pic picPhone = _draw([
  _Fill(_rect(4, 0, 11, 15), 'd'),
  _Fill(_rect(5, 2, 10, 12), 'b', outline: false),
  _Fill(_ellipse(7.9, 7, 1.8, 1.8), 'y'),
  _Fill(_rect(7, 14, 8, 14), 'e', outline: false),
]);
final Pic picTens = _draw([
  _Fill(_rect(0, 4, 15, 10), 'b'),
  for (final x in const [3, 6, 9, 12]) _Fill(_rect(x, 5, x, 9), 'k', outline: false),
  _Fill(_rect(1, 7, 14, 7), 'k', outline: false),
]);
final Pic picHundreds = _draw([
  _Fill(_rect(2, 2, 13, 13), 'b'),
  _Fill(_and(_rect(3, 3, 12, 12), (x, y) => (x.floor() + y.floor()).isEven), 'B', outline: false),
]);
final Pic picDigit = _draw([
  _Fill(_rect(0, 3, 15, 11), 'w'),
  for (final (i, d) in const ['3', '5', '2'].indexed) ...[
    _Fill(_rect(1 + i * 5, 4, 4 + i * 5, 10), i == 1 ? 'y' : 'e', outline: false),
    _Stamp(_text(d), 1 + i * 5, 5),
  ],
  for (final x in const [5, 10]) _Fill(_rect(x, 4, x, 10), 'k', outline: false),
]);
final Pic picColumn = _draw([
  _Fill(_rect(8, 0, 12, 15), 'y', outline: false),
  _Stamp(_text('23'), 5, 1),
  _Stamp(_text('14'), 5, 7),
  _Fill(_rect(1, 13, 14, 13), 'k', outline: false),
  _Fill(_or([_rect(2, 7, 2, 11), _rect(1, 9, 3, 9)]), 'k', outline: false),
]);
final Pic picCarry = _draw([
  _Stamp(_scale(_text('1', ink: 'g'), 2), 2, 0),
  _Stamp(_tint(_arrowLeft, {'k': 'g'}), 8, 7),
  _Fill(_rect(1, 14, 14, 14), 'k', outline: false),
]);
final Pic picBorrow = _draw([
  _Stamp(_scale(_text('10', ink: 'c'), 2), 1, 0),
  _Stamp(_tint(_arrowRight, {'k': 'c'}), 5, 9),
]);
final Pic picAbacus = _draw([
  _Fill(_rect(0, 1, 15, 14), 'n'),
  _Fill(_rect(2, 3, 13, 12), 's', outline: false),
  for (final x in const [4, 8, 11]) _Fill(_rect(x, 3, x, 12), 'd', outline: false),
  _Fill(_rect(2, 5, 13, 5), 'n', outline: false),
  // beads: the top one counts 5, the bottom ones 1
  _Fill(_rect(3, 3, 5, 4), 'c', outline: false),
  _Fill(_rect(10, 6, 12, 7), 'c', outline: false),
  for (final (x, y) in const [(3, 6), (3, 8), (7, 6), (7, 10), (10, 9), (10, 11)]) _Fill(_rect(x, y, x + 2, y + 1), 'b', outline: false),
  _Fill(_rect(7, 3, 9, 4), 'b', outline: false),
]);
final Pic picFraction = _draw([
  ..._pie(5, 8, 5, {0}),
  _Stamp(_text('1'), 12, 1),
  _Fill(_rect(11, 7, 15, 8), 'k', outline: false),
  _Stamp(_text('4'), 12, 10),
]);
final Pic picHalf = _draw(_pie(8, 8, 7.5, {0, 1}));
final Pic picQuarter = _draw(_pie(8, 8, 7.5, {0}));
final Pic picPercent = _draw([
  _Fill(_or([_line(13, 1.5, 3, 14.5, 3), _circle(4, 4, 3.3), _circle(12, 12, 3.3)]), 'c'),
  _Fill(_or([_circle(4, 4, 1), _circle(12, 12, 1)]), 'w', outline: false),
]);
final Pic picTotal = _draw([
  ..._coin(3, 3, 2.6),
  ..._coin(8, 3, 2.6),
  ..._coin(13, 3, 2.6),
  _Fill(_rect(0, 7, 15, 7), 'k', outline: false),
  ..._coin(8, 12, 4),
]);

// Money
final Pic picPeso = _draw([..._coin(8, 8, 7.5), _Stamp(_tint(_dollar, {'k': 'o'}), 6, 5)]);
final Pic picCentavo = _draw([..._coin(8, 5.5, 5, fill: 'e'), _Stamp(_text('50'), 5, 11)]);
final Pic picCoins = _draw([..._coin(8, 5, 4.6), ..._coin(4.8, 11, 4.6), ..._coin(11.2, 11, 4.6)]);
final Pic picBill = _draw([
  _Fill(_rect(0, 3, 15, 12), 'l'),
  _Fill(_ellipse(8, 8, 3, 2.6), 'G'),
  for (final (x, y) in const [(2, 5), (13, 5), (2, 10), (13, 10)]) _Fill(_rect(x, y, x, y), 'G', outline: false),
]);
final Pic picChange = _draw([
  _Fill(_rect(3, 0, 13, 6), 'l'),
  _Fill(_ellipse(8, 3.5, 1.8, 1.6), 'G'),
  _Stamp(_tint(_arrowLeft, {'k': 'g'}), 0, 9),
  ..._coin(12, 12, 3.6),
]);
final Pic picPrice = _draw([..._tag(3, 12), _Stamp(_tint(_dollar, {'k': 'o'}), 8, 4)]);
final Pic picDiscount = _draw([
  ..._tag(3, 12),
  _Stamp(_tint(_percent, {'k': 'c'}), 5, 5),
  _Cut(_line(11.5, 0, 13.5, 16, 1.4)),
]);
final Pic picIva = _draw([
  ..._tag(0, 7, right: 15),
  ..._coin(3.6, 12, 3.2),
  _Stamp(_tint(_arrowSmall, {'k': 'c'}), 7, 10),
  ..._building(11, 5, 9),
]);
final Pic picTax = _draw([
  ..._coin(3.4, 6, 3.2),
  _Stamp(_tint(_arrowSmall, {'k': 'g'}), 2, 11),
  ..._building(7, 9, 5),
]);
final Pic picInterest = _draw([_Stamp(_sprout, 4, 0), ..._coin(8, 11, 4.8)]);
final Pic picCompound = _draw([
  _Fill(_or([_rect(7, 3, 8, 8), _line(8, 6, 4, 3, 1.2), _line(8, 6, 12, 3, 1.2)]), 'G', outline: false),
  ..._coin(3.4, 3, 2.6),
  ..._coin(12.6, 3, 2.6),
  ..._coin(8, 11.6, 4.4),
]);
final Pic picRate = _draw([..._coin(8, 8, 7.5), _Stamp(_tint(_percent, {'k': 'o'}), 5, 5)]);
final Pic picLoan = _draw([
  _Stamp(_person, 0, 5),
  _Stamp(_tint(_person, {'b': 'p'}), 11, 5),
  _Stamp(_tint(_arrowSmall, {'k': 'g'}), 5, 1),
  ..._coin(8, 9, 2.6),
  _Stamp(_tint(_flip(_arrowSmall), {'k': 'c'}), 6, 12),
]);
final Pic picCredit = _draw([
  ..._coin(5, 10.5, 4.6),
  _Fill(_circle(11.5, 5, 4.4), 'w'),
  _Fill(_or([_rect(11, 2, 11, 5), _rect(11, 5, 13, 5)]), 'k', outline: false),
]);
final Pic picCreditCard = _draw(_card(2, 13));
final Pic picCreditLimit = _draw([
  ..._card(0, 8),
  _Fill(_rect(0, 11, 13, 15), 'w'),
  _Fill(_rect(1, 12, 10, 14), 'r', outline: false),
  _Fill(_rect(14, 10, 15, 15), 'k', outline: false),
]);
final Pic picMinimum = _draw([
  _Fill(_rect(8, 1, 15, 15), 'r'),
  for (final y in const [4, 8, 12]) _Fill(_rect(9, y, 14, y), 'k', outline: false),
  ..._coin(2.6, 12.5, 2.4),
  _Stamp(_tint(_arrowSmall, {'k': 'g'}), 3, 6),
]);
final Pic picDebt = _draw([..._coin(8, 5.5, 5.4), _Stamp(_chain, 0, 11)]);
final Pic picPartPayment = _draw([
  ..._coin(3, 2.4, 2.4),
  _Stamp(_tint(_arrowSmall, {'k': 'g'}), 6, 0),
  _Fill(_rect(0, 6, 15, 12), 'r'),
  _Fill(_rect(1, 7, 5, 11), 'y', outline: false),
  for (final x in const [6, 9, 12]) _Fill(_rect(x, 7, x, 11), 'k', outline: false),
]);
final Pic picTerm = _draw([
  ..._calendar(0, 10),
  _Fill(_rect(1, 13, 11, 14), 'k', outline: false),
  _Fill(_poly([(11, 10.5), (16, 13.9), (11, 17.5)]), 'k', outline: false),
]);
final Pic picMonthly = _draw([..._calendar(0, 10), ..._coin(8, 13, 2.9)]);
final Pic picPayday = _draw(_calendar(0, 15, gold: {(2, 1), (3, 2)}));
final Pic picInterestFree = _draw([
  ..._calendar(0, 10),
  for (final x in const [2.8, 8.0, 13.2]) ..._coin(x, 13.4, 2.5),
]);
final Pic picFee = _draw([
  ..._coin(7, 9.5, 6.4),
  _Cut(_circle(12.5, 4, 2.6)),
  ..._coin(13.4, 2.6, 2.3, fill: 'r'),
]);
final Pic picCat = _draw([
  ..._card(0, 7),
  _Fill(_rect(2, 12, 4, 15), 'g'),
  _Fill(_rect(6, 10, 8, 15), 'y'),
  _Fill(_rect(10, 9, 12, 15), 'c'),
  _Fill(_poly([(13, 7), (16, 7), (16, 15), (14, 15)]), 'r'),
]);
final Pic picTanda = _draw([
  _Stamp(_miniPerson, 6, 0),
  _Stamp(_tint(_miniPerson, {'b': 'p'}), 12, 6),
  _Stamp(_tint(_miniPerson, {'b': 'g'}), 6, 11),
  _Stamp(_tint(_miniPerson, {'b': 'c'}), 0, 6),
  ..._coin(8, 8.4, 2.6),
]);
final Pic picSaving = _draw([
  _Fill(_ellipse(7.5, 10, 6.5, 4.6), 'm'),
  _Fill(_rect(13, 8, 15, 11), 'm'),
  _Fill(_poly([(3, 7), (4.5, 3.5), (7, 6)]), 'm'),
  _Fill(_or([_rect(3, 13, 4, 15), _rect(10, 13, 11, 15)]), 'm'),
  _Fill(_rect(5, 6, 9, 6), 'k', outline: false),
  _Fill(_rect(10, 8, 10, 8), 'k', outline: false),
  ..._coin(7.5, 2.6, 2.6),
]);
final Pic picBudget = _draw(_wallet(3, parts: ['b', 'g', 'c']));
final Pic picIncome = _draw([..._wallet(7), _Stamp(_tint(_arrowDown, {'k': 'g'}), 2, 0)]);
final Pic picExpense = _draw([..._wallet(7), _Stamp(_tint(_arrowUp, {'k': 'c'}), 2, 0)]);
final Pic picRent = _draw([
  _Fill(_poly([(0, 7), (6.5, 0.5), (13, 7)]), 'r'),
  _Fill(_rect(1, 7, 11, 15), 's'),
  _Fill(_rect(5, 10, 7, 15), 'n'),
  ..._coin(13, 12.5, 3),
]);
final Pic picCetes = _draw([..._building(0, 9, 5), _Stamp(_sprout, 9, 0), ..._coin(12.5, 11, 3.4)]);
final Pic picAfore = _draw([_Stamp(_elder, 0, 1), ..._coin(12.5, 11.5, 3.3)]);
final Pic picCreditHistory = _draw([
  _Fill(_rect(2, 0, 13, 15), 'w'),
  for (final (i, c) in const ['g', 'g', 'r', 'g'].indexed) ...[
    _Fill(_rect(4, 2 + i * 3, 5, 3 + i * 3), c, outline: false),
    _Fill(_rect(7, 2 + i * 3, 11, 2 + i * 3), 't', outline: false),
  ],
]);
final Pic picCondusef = _draw([..._shield('b'), _Stamp(_tint(_dollar, {'k': 'w'}), 6, 4)]);
final Pic picProfeco = _draw([
  ..._shield('c'),
  _Fill(_rect(5, 6, 10, 11), 'w'),
  _Fill(_or([_rect(6, 3, 6, 6), _rect(9, 3, 9, 6), _rect(6, 3, 9, 3)]), 'k', outline: false),
]);
final Pic picBanxico = _draw([
  _Fill(_rect(3, 0, 12, 3), 'l'),
  _Fill(_rect(7, 1, 8, 2), 'G', outline: false),
  ..._building(0, 16, 4, columns: 'y'),
]);
final Pic picAvalanche = _draw([
  _Fill(_poly([(0, 16), (7, 1), (14, 16)]), 'd'),
  _Fill(_poly([(4.6, 6.2), (7, 1), (9.4, 6.2)]), 'w', outline: false),
  ..._coin(13, 9, 1.8, fill: 'w'),
  ..._coin(14.3, 13.2, 1.6, fill: 'w'),
]);
final Pic picSnowball = _draw([
  _Fill(_rect(0, 15, 15, 15), 't', outline: false),
  _Fill(_circle(2, 13, 1.6), 'w'),
  _Fill(_circle(6.2, 11.8, 2.8), 'w'),
  _Fill(_circle(12, 9.6, 5), 'w'),
  _Fill(_circle(10.4, 7.8, 1), 'e', outline: false),
]);
final Pic picReceipt = _draw([
  _Fill(_and(_rect(3, 0, 12, 15), (x, y) => y < 14 || (x.floor() + y.floor()).isEven), 'w'),
  for (final y in const [3, 5, 7]) _Fill(_rect(5, y, 10, y), 't', outline: false),
  _Fill(_rect(5, 10, 10, 10), 'k', outline: false),
]);
final Pic picWellbeing = _draw([
  _Fill(_or([_circle(5, 5.5, 4), _circle(11, 5.5, 4), _poly([(1.3, 7), (14.7, 7), (8, 14.5)])]), 'r'),
  _Fill(_rect(3, 3, 4, 4), 'w', outline: false),
  ..._coin(12.6, 12.6, 3.2),
]);

// ---------------------------------------------------------------- pictures that move

/// The pictures showing something that happens, frame by frame, ending on the picture itself. Only what really moves:
/// change coming back, money growing, a tanda going round. A word that doesn't move stays still.
final Map<Pic, List<Pic>> _moving = Map.identity()
  ..addAll({
    picChange: [
      for (final x in [15.0, 12.0, 9.0, 6.0])
        _draw([_Fill(_rect(3, 0, 13, 6), 'l'), _Fill(_ellipse(8, 3.5, 1.8, 1.6), 'G'), ..._coin(x, 12, 3.6)]),
      picChange,
    ],
    picInterest: [
      _draw(_coin(8, 12, 3.6)),
      _draw([_Stamp(_sprout, 4, 2), ..._coin(8, 12, 3.6)]),
      _draw([_Stamp(_sprout, 4, 1), ..._coin(8, 11.5, 4.2)]),
      picInterest,
    ],
    picCompound: [
      _draw(_coin(8, 11.6, 4.4)),
      _draw([_Fill(_rect(7, 5, 8, 8), 'G', outline: false), ..._coin(8, 11.6, 4.4)]),
      _draw([
        _Fill(_or([_rect(7, 3, 8, 8), _line(8, 6, 4, 3, 1.2), _line(8, 6, 12, 3, 1.2)]), 'G', outline: false),
        ..._coin(3.4, 3, 1.4),
        ..._coin(12.6, 3, 1.4),
        ..._coin(8, 11.6, 4.4),
      ]),
      picCompound,
    ],
    picTanda: [
      for (final (x, y) in const [(8.0, 5.4), (10.8, 8.4), (8.0, 10.6), (5.2, 8.4)])
        _draw([
          _Stamp(_miniPerson, 6, 0),
          _Stamp(_tint(_miniPerson, {'b': 'p'}), 12, 6),
          _Stamp(_tint(_miniPerson, {'b': 'g'}), 6, 11),
          _Stamp(_tint(_miniPerson, {'b': 'c'}), 0, 6),
          ..._coin(x, y, 2.2),
        ]),
    ],
    picSaving: [
      for (final y in [0.0, 1.5, 2.6])
        _draw([
          ..._coin(7.5, y + 1, 2.6),
          _Fill(_ellipse(7.5, 10, 6.5, 4.6), 'm'),
          _Fill(_rect(13, 8, 15, 11), 'm'),
          _Fill(_poly([(3, 7), (4.5, 3.5), (7, 6)]), 'm'),
          _Fill(_or([_rect(3, 13, 4, 15), _rect(10, 13, 11, 15)]), 'm'),
          _Fill(_rect(5, 6, 9, 6), 'k', outline: false),
          _Fill(_rect(10, 8, 10, 8), 'k', outline: false),
        ]),
      picSaving,
    ],
    picIncome: [
      for (final y in [0, 1, 2]) _draw([..._wallet(7), _Stamp(_tint(_arrowDown, {'k': 'g'}), 2, y)]),
    ],
  });

/// The frames of a picture that moves, or just the picture
List<Pic> picFrames(Pic pic) => _moving[pic] ?? [pic];
