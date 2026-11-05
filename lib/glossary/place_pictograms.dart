// place_pictograms.dart — the pictures of the app's places, like the Mexico City Metro's station signs: the four tabs,
// each unit and lesson on the path, each simulator and each group of resources. Same 16 × 16 grid, colours and shapes
// as the glossary's pictograms (pictograms.dart), so a place and the word it's about look alike: the credit card
// simulator and the word "tarjeta de crédito" share a picture, like a Metro transfer station.
part of 'pictograms.dart';

// ---------------------------------------------------------------- small badges

/// A picture with a round badge in its lower right corner: [colour] with a white [symbol] (+, −, ×) on it
Pic _badged(Pic base, String colour, String symbol) => _draw([
  _Stamp(base, 0, 0),
  _Fill(_circle(12, 12, 4), colour),
  switch (symbol) {
    '+' => _Fill(_or([_rect(11, 9, 12, 14), _rect(9, 11, 14, 12)]), 'w', outline: false),
    '-' => _Fill(_rect(9, 11, 14, 12), 'w', outline: false),
    _ => _Fill(_or([_line(9.8, 9.8, 14.2, 14.2, 1.6), _line(14.2, 9.8, 9.8, 14.2, 1.6)]), 'w', outline: false),
  },
]);

/// A small abacus (frame, rods and a few beads) in rows [top] to [bottom]
List<_Op> _miniAbacus(int top, int bottom) => [
  _Fill(_rect(0, top, 15, bottom), 'n'),
  _Fill(_rect(2, top + 2, 13, bottom - 2), 's', outline: false),
  for (final x in const [4, 8, 11]) _Fill(_rect(x, top + 2, x, bottom - 2), 'd', outline: false),
];

// ---------------------------------------------------------------- the tabs

/// "Aprender": a winding path of stones, the first one done (gold)
final Pic picPath = _draw([
  _Fill(_or([_line(4, 13, 11.5, 8.5, 2), _line(11.5, 8.5, 4.5, 3.5, 2)]), 's', outline: false),
  _Fill(_circle(4, 12.6, 3.2), 'y'),
  _Fill(_circle(11.6, 8.2, 3.2), 'b'),
  _Fill(_circle(4.6, 3.6, 3.2), 'e'),
  _Fill(_rect(11, 0, 11, 4), 'k', outline: false),
  _Fill(_poly([(12, 0), (16, 1.5), (12, 3)]), 'r', outline: false),
]);

/// "Simuladores": three sliders, like the ones that move the numbers
final Pic picSliders = _draw([
  for (final y in const [2, 7, 12]) _Fill(_rect(1, y, 14, y + 1), 'k', outline: false),
  _Fill(_circle(5, 3, 2.6), 'y'),
  _Fill(_circle(11, 8, 2.6), 'b'),
  _Fill(_circle(7.5, 13, 2.6), 'c'),
]);

/// "Recursos": a signpost, the places to go and check things for real
final Pic picSignpost = _draw([
  _Fill(_rect(7, 2, 8, 15), 'n'),
  _Fill(_poly([(1, 2), (12, 2), (15.5, 4.5), (12, 7), (1, 7)]), 'y'),
  _Fill(_poly([(15, 8), (4, 8), (0.5, 10.5), (4, 13), (15, 13)]), 'b'),
]);

/// "Ajustes": a gear
final Pic picGear = _draw([
  _Fill(_or([
    _circle(8, 8, 5.4),
    for (var i = 0; i < 8; i++) _line(8, 8, 8 + 7.4 * math.cos(i * math.pi / 4), 8 + 7.4 * math.sin(i * math.pi / 4), 3.2),
  ]), 'e'),
  _Cut(_circle(8, 8, 2.2)),
]);

// ---------------------------------------------------------------- the units

/// "Sumas y restas": a plus and a minus
final Pic picPlusMinus = _draw([
  _Fill(_or([_rect(3, 0, 6, 9), _rect(0, 3, 9, 6)]), 'g'),
  _Fill(_rect(6, 11, 15, 14), 'c'),
]);

/// "Dinero": a bill behind a coin
final Pic picMoneyUnit = _draw([
  _Fill(_rect(0, 1, 13, 9), 'l'),
  _Fill(_ellipse(7, 5.4, 2.4, 2.2), 'G'),
  ..._coin(11, 11, 4.8),
  _Stamp(_tint(_dollar, {'k': 'o'}), 9, 8),
]);

// ---------------------------------------------------------------- the lessons that need their own picture

/// Adding on the abacus
final Pic picAbacusAdd = _badged(picAbacus, 'g', '+');

/// The friends of 5: one bead worth 5, and a big 5
final Pic picFriends5 = _draw([
  ..._miniAbacus(0, 5),
  _Fill(_rect(6, 1, 9, 4), 'c'),
  _Stamp(_scale(_text('5'), 2), 5, 6),
]);

/// The friends of 10: two beads worth 5, and a big 10
final Pic picFriends10 = _draw([
  ..._miniAbacus(0, 5),
  _Fill(_rect(2, 1, 5, 4), 'c'),
  _Fill(_rect(10, 1, 13, 4), 'c'),
  _Stamp(_scale(_text('10'), 2), 1, 6),
]);

final Pic picAddHundreds = _badged(picHundreds, 'g', '+');
final Pic picSubtractHundreds = _badged(picHundreds, 'c', '-');
final Pic picMultiplyCarry = _draw([
  _Fill(_or([_line(2, 2, 9.5, 9.5, 3.2), _line(9.5, 2, 2, 9.5, 3.2)]), 'b'),
  _Stamp(_scale(_text('1', ink: 'g'), 2), 10, 5),
]);
final Pic picMultiplyHundreds = _badged(picHundreds, 'b', '×');

/// Multiplying by two digits: × 12
final Pic picTwoDigits = _draw([
  _Fill(_or([_line(1.5, 1.5, 6.5, 6.5, 2.4), _line(6.5, 1.5, 1.5, 6.5, 2.4)]), 'b'),
  _Stamp(_scale(_text('12', ink: 'B'), 2), 2, 6),
]);
final Pic picCasitaHundreds = _badged(picCasita, 'p', '+');

// ---------------------------------------------------------------- simulators and resources

/// The month's calendar: some days with money (green), the last ones without (coral)
final Pic picMonthCalendar = _draw([
  ..._calendar(0, 15),
  for (final (col, row, c) in const [(0, 0, 'g'), (1, 0, 'g'), (2, 0, 'g'), (3, 0, 'g'), (0, 1, 'g'), (1, 1, 'g'), (2, 1, 'r'), (3, 1, 'r'), (0, 2, 'r'), (1, 2, 'r')])
    _Fill(_rect(2 + col * 3 + (col > 1 ? 1 : 0), 6 + row * 3, 3 + col * 3 + (col > 1 ? 1 : 0), 7 + row * 3), c, outline: false),
]);

/// My debts in one list: a sheet with three debts and their total, held by a chain
final Pic picDebtList = _draw([
  _Fill(_rect(2, 0, 13, 11), 'w'),
  for (final y in const [2, 5, 8]) ...[
    _Fill(_rect(4, y, 5, y + 1), 'r', outline: false),
    _Fill(_rect(7, y, 11, y), 't', outline: false),
  ],
  _Stamp(_chain, 0, 12),
]);

/// A unit's challenge: a trophy
final Pic picTrophy = _draw([
  _Fill(_or([_circle(2.6, 4.5, 2.4), _circle(13.4, 4.5, 2.4)]), 'y'),
  _Cut(_or([_circle(2.6, 4.5, 1.0), _circle(13.4, 4.5, 1.0)])),
  _Fill(_and(_or([_rect(3, 1, 12, 5), _ellipse(8, 5.5, 5, 5)]), (x, y) => y >= 1), 'y'),
  _Fill(_rect(5, 2, 5, 6), 'w', outline: false),
  _Fill(_rect(7, 10, 8, 12), 'o'),
  _Fill(_rect(3, 13, 12, 15), 'n'),
]);

/// Before taking out a loan: a magnifying glass over a peso, checking first
final Pic picCheckFirst = _draw([
  _Fill(_line(10, 10, 14.6, 14.6, 3.2), 'n'),
  _Fill(_circle(6.5, 6.5, 6.2), 'w'),
  _Fill(_circle(6.5, 6.5, 4.4), 'y', outline: false),
  _Stamp(_tint(_dollar, {'k': 'o'}), 4, 3),
]);

/// Places outside Mexico: a globe
final Pic picGlobe = _draw([
  _Fill(_circle(8, 8, 7.6), 'b'),
  _Fill(_and(_circle(8, 8, 6.6), _or([_ellipse(5, 5.5, 3, 3.4), _ellipse(11.5, 11, 3, 3.6)])), 'g', outline: false),
  _Fill(_and(_circle(8, 8, 6.6), (x, y) => (y - 8).abs() < 0.5), 'B', outline: false),
]);

/// A plain heart: nobody grades you here
final Pic picHeart = _draw([
  _Fill(_or([_circle(5, 6, 4), _circle(11, 6, 4), _poly([(1.3, 7.5), (14.7, 7.5), (8, 15)])]), 'r'),
  _Fill(_rect(3, 4, 4, 5), 'w', outline: false),
]);

/// "Palabras": an open book
final Pic picBook = _draw([
  _Fill(_poly([(0, 4), (8, 5.5), (16, 4), (16, 15), (8, 16), (0, 15)]), 'b'),
  _Fill(_poly([(1, 2), (7.5, 3.5), (7.5, 14), (1, 12.5)]), 'w'),
  _Fill(_poly([(15, 2), (8.5, 3.5), (8.5, 14), (15, 12.5)]), 'w'),
  for (final y in const [6, 8, 10]) ...[
    _Fill(_rect(3, y, 5, y), 't', outline: false),
    _Fill(_rect(10, y, 12, y), 't', outline: false),
  ],
]);

// ---------------------------------------------------------------- who's going to use Penko

/// A person [height] pixels tall, standing on the tile's floor: child, young person and adult differ by height alone
Pic _personOf(int height) {
  final top = 16 - height, neck = top + 5, hips = 16 - (height / 3).ceil();
  return _draw([
    _Fill(_rect(5, hips, 7, 15), 'B'),
    _Fill(_rect(8, hips, 10, 15), 'B'),
    _Fill(_rect(4, neck, 11, hips), 'b'),
    _Fill(_circle(8, top + 2.5, 2.8), 's'),
  ]);
}

/// A child with a backpack, drawn big: a small figure in a big frame reads as nothing
final Pic picChild = _draw([
  _Fill(_rect(2, 8, 5, 13), 'y'),
  _Fill(_rect(6, 13, 7, 15), 'B'),
  _Fill(_rect(9, 13, 10, 15), 'B'),
  _Fill(_rect(5, 8, 12, 13), 'r'),
  _Fill(_circle(8.5, 4.6, 4.2), 's'),
  _Fill(_or([_rect(5, 1, 12, 2), _rect(5, 2, 5, 3)]), 'n', outline: false),
]);

/// A teenager carrying a book
final Pic picTeen = _draw([
  _Fill(_rect(5, 11, 6, 15), 'B'),
  _Fill(_rect(8, 11, 9, 15), 'B'),
  _Fill(_rect(4, 5, 10, 11), 'g'),
  _Fill(_rect(9, 6, 14, 11), 'y'),
  _Fill(_rect(11, 7, 12, 10), 'w', outline: false),
  _Fill(_circle(7.5, 3.1, 2.9), 's'),
]);

/// How a visit went, for the feedback form: faces and things anyone can tell apart
List<_Op> _face(String skin) => [_Fill(_circle(8, 8, 7.6), skin), _Fill(_or([_rect(5, 5, 5, 6), _rect(10, 5, 10, 6)]), 'k', outline: false)];

final Pic picSmile = _draw([
  ..._face('y'),
  _Fill(_or([_line(4.5, 9.5, 6.5, 12, 1.4), _line(6.5, 12, 9.5, 12, 1.4), _line(9.5, 12, 11.5, 9.5, 1.4)]), 'k', outline: false),
]);

final Pic picConfused = _draw([
  ..._face('s'),
  _Fill(_or([_line(5, 12, 7, 11, 1.3), _line(7, 11, 9, 12, 1.3), _line(9, 12, 11, 11, 1.3)]), 'k', outline: false),
]);

final Pic picSad = _draw([
  ..._face('e'),
  _Fill(_or([_line(4.5, 12.5, 6.5, 10.5, 1.4), _line(6.5, 10.5, 9.5, 10.5, 1.4), _line(9.5, 10.5, 11.5, 12.5, 1.4)]), 'k', outline: false),
]);

final Pic picBroken = _badged(picPhone, 'r', '×');

final Pic picIdea = _draw([
  _Fill(_or([_rect(6, 12, 9, 13), _rect(7, 14, 8, 14)]), 'e'),
  _Fill(_or([_circle(8, 6.5, 5.6), _rect(6, 10, 9, 11)]), 'y'),
  _Fill(_or([_rect(6, 4, 6, 5), _rect(5, 5, 5, 6)]), 'w', outline: false),
]);

final Pic picComplaint = _draw([
  _Fill(_or([_rect(1, 2, 14, 10), _line(4.5, 10, 3.5, 14.5, 2.4), _line(4.5, 11, 7, 11, 1.5)]), 'w'),
  _Fill(_or([_rect(7, 3, 8, 7), _rect(7, 9, 8, 9)]), 'r', outline: false),
]);
final Pic picAdult = _personOf(16);
