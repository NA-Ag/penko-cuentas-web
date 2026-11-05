// money_art.dart — Mexican-style coins and bills in Penko's own pixel style: plain round coins and plain notes, each
// value in its own colour, with the number written big on top (money_pile.dart draws it). They're our own drawings, not
// copies of the real designs: only the values and roughly the colours people know. And the breakdown of an amount into
// the fewest coins and bills, so an amount like $1,700 can be shown as money: one $1000, one $500 and one $200.
//
// Plain Dart (no Flutter), so the tests can check the breakdown. Grids use letters for colours, like the pictograms;
// money_pile.dart has the colours.
import 'dart:math' as math;

class Denomination {
  final int value; // in pesos
  final bool coin;
  final List<String> grid; // the picture, '.' clear
  const Denomination(this.value, this.coin, this.grid);

  /// How much of its 16 × 16 grid a coin fills across (bills fill all of theirs)
  double get fill => coin ? grid[8].replaceAll('.', '').length / grid[8].length : 1;

  /// "$20 coin" vs "$20 bill" when both exist
  String get id => '${coin ? 'coin' : 'bill'}$value';
}

// ---------------------------------------------------------------- drawing

/// A round coin on a 16 × 16 grid: an outlined disc of [radius] in [ring], with a centre in [centre]
List<String> _coin(double radius, String ring, String centre) {
  const n = 16, c = 8.0;
  final inner = radius * 0.7;
  return [
    for (var y = 0; y < n; y++)
      [
        for (var x = 0; x < n; x++)
          () {
            final dx = x + 0.5 - c, dy = y + 0.5 - c, d = math.sqrt(dx * dx + dy * dy);
            if (d > radius) return '.';
            if (d > radius - 1) return 'k';
            // a little shine on the upper left of the rim
            if (d > radius - 2 && dx < -radius * 0.45 && dy < -radius * 0.45) return 'w';
            return d > inner ? ring : centre;
          }(),
      ].join(),
  ];
}

/// A note on a 28 × 14 grid: a light [body] with a thin frame and a round mark on the left in its darker [band]
/// colour; the number goes on the right
List<String> _bill(String body, String band) {
  const w = 28, h = 14;
  return [
    for (var y = 0; y < h; y++)
      [
        for (var x = 0; x < w; x++)
          () {
            final corner = (x == 0 || x == w - 1) && (y == 0 || y == h - 1);
            if (corner) return '.';
            if (x == 0 || y == 0 || x == w - 1 || y == h - 1) return 'k';
            // the frame printed a little inside the edge
            final frame = (x == 2 || x == w - 3) && y >= 2 && y <= h - 3 || (y == 2 || y == h - 3) && x >= 2 && x <= w - 3;
            if (frame) return band;
            // the round mark, a ring with a light middle
            final dx = x + 0.5 - 6.5, dy = y + 0.5 - 7, d = math.sqrt(dx * dx + dy * dy);
            if (d <= 1.4) return 'w';
            if (d <= 3.1) return band;
            return body;
          }(),
      ].join(),
  ];
}

// ---------------------------------------------------------------- the money

/// Coins, smallest first: silver $1, copper $2, gold $5, silver-and-gold $10, gold-and-silver $20 (bigger as they're
/// worth more)
final List<Denomination> coins = [
  Denomination(1, true, _coin(5.6, 'a', 'a')),
  Denomination(2, true, _coin(6.2, 'q', 'q')),
  Denomination(5, true, _coin(6.7, 'u', 'u')),
  Denomination(10, true, _coin(7.3, 'a', 'u')),
  Denomination(20, true, _coin(7.9, 'u', 'a')),
];

/// Bills: blue $20, pink $50, red $100, green $200, brown $500, purple $1000
final List<Denomination> bills = [
  Denomination(20, false, _bill('b', 'B')),
  Denomination(50, false, _bill('m', 'M')),
  Denomination(100, false, _bill('r', 'R')),
  Denomination(200, false, _bill('g', 'G')),
  Denomination(500, false, _bill('n', 'N')),
  Denomination(1000, false, _bill('p', 'P')),
];

/// What an amount is paid with, biggest first: bills from $1000 to $20, then coins from $10 to $1 (the $20 coin isn't
/// used: the $20 bill is the one people usually have)
final List<Denomination> _paying = [
  ...bills.reversed,
  for (final c in coins.reversed)
    if (c.value < 20) c,
];

/// [pesos] as the fewest coins and bills, biggest first: (denomination, how many). Whole pesos only (centavos are
/// dropped); nothing for 0 or less.
List<(Denomination, int)> breakdown(int pesos) {
  final out = <(Denomination, int)>[];
  var left = pesos;
  for (final d in _paying) {
    if (left <= 0) break;
    final n = left ~/ d.value;
    if (n > 0) {
      out.add((d, n));
      left -= n * d.value;
    }
  }
  return out;
}
