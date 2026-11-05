// money_pile.dart — an amount shown as money: a small pile of Penko's coins and bills (money_art.dart), the fewest
// that make it, so "te queda $1,700" can also be seen as one $1000, one $500 and one $200. Many of the same note show
// as a short stack with "× 3", so big amounts stay small on screen.
import 'package:flutter/material.dart';

import '../art/palette.dart';
import '../art/pixel_sprite.dart';
import '../money/money.dart' show pesos;
import '../money/money_art.dart';
import 'pixel_ui.dart';

export '../money/money_art.dart' show Denomination, breakdown, coins, bills;

/// The coins' and bills' colours (letters in money_art.dart)
final Map<int, Color> moneyPalette = {
  for (final e in const <String, Color>{
    'k': Color(0xFF1B2440), // outline
    'w': Color(0xFFFFFFFF),
    'a': Color(0xFFD7DCE8), // silver
    'q': Color(0xFFE0915A), // copper
    'u': Color(0xFFF2C94C), // gold
    'b': Color(0xFF8FD3FA), // the $20 bill: blue
    'B': Color(0xFF1E88C8),
    'm': Color(0xFFF9A8D4), // $50: pink
    'M': Color(0xFFD9468F),
    'r': Color(0xFFFF9A9A), // $100: red
    'R': Color(0xFFD9443A),
    'g': Color(0xFF9BE07A), // $200: green
    'G': Color(0xFF2F8F46),
    'n': Color(0xFFE8BC86), // $500: brown
    'N': Color(0xFF9A6532),
    'p': Color(0xFFC9B8FD), // $1000: purple
    'P': Color(0xFF6D3FD9),
  }.entries)
    e.key.codeUnitAt(0): e.value,
};

final _grids = <String, PixelGrid>{};

PixelGrid _grid(Denomination d) => _grids[d.id] ??= [
  for (final row in d.grid) [for (final c in row.codeUnits) c == 0x2E ? 0 : c],
];

/// One coin or bill, [height] tall (a bill is twice as wide), with its value written big
class MoneyPicture extends StatelessWidget {
  final Denomination money;
  final double height;
  const MoneyPicture(this.money, {super.key, this.height = 36});

  @override
  Widget build(BuildContext context) {
    final width = money.coin ? height : height * 2;
    // Where the number goes: the coin's centre, or the bill's right side
    final number = money.coin
        ? Center(child: SizedBox(width: height * money.fill * 0.62, height: height * money.fill * 0.42, child: _value()))
        : Align(
            alignment: const Alignment(0.4, 0),
            child: SizedBox(width: width * 0.44, height: height * 0.5, child: _value()),
          );
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        children: [
          PixelSprite(_grid(money), palette: moneyPalette, size: width),
          Positioned.fill(child: number),
        ],
      ),
    );
  }

  Widget _value() => FittedBox(
    child: Text(
      '${money.value}',
      style: const TextStyle(fontFamily: textFont, fontWeight: FontWeight.w700, color: Color(0xFF1B2440), height: 1),
    ),
  );
}

/// [amount] in pesos as a pile of coins and bills (whole pesos; nothing for 0 or less). [caption] goes above it.
class MoneyPile extends StatelessWidget {
  final double amount;
  final String? caption;
  final double height;
  const MoneyPile(this.amount, {super.key, this.caption, this.height = 34});

  /// At most this many of one coin or bill are drawn; more show as "× n"
  static const stack = 3;

  @override
  Widget build(BuildContext context) {
    final parts = breakdown(amount.floor());
    if (parts.isEmpty) return const SizedBox.shrink();
    return Semantics(
      label: '${caption ?? ''} ${pesos(amount.floorToDouble())}'.trim(),
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (caption != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(caption!, style: const TextStyle(color: Pk.textSoft, fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [for (final (d, n) in parts) _group(d, n)],
          ),
        ],
      ),
    );
  }

  /// One kind of coin or bill: up to [stack] of them, each a little lower and to the right, and "× n" when there are more
  /// than one
  Widget _group(Denomination d, int n) {
    final shown = n.clamp(1, stack);
    const step = 5.0;
    final h = d.coin ? height * 1.2 : height; // coins drawn a little bigger, so even $1 reads
    final width = (d.coin ? h : h * 2) + (shown - 1) * step;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: width,
          height: h + (shown - 1) * step,
          child: Stack(
            children: [
              for (var i = 0; i < shown; i++) Positioned(left: i * step, top: i * step, child: MoneyPicture(d, height: h)),
            ],
          ),
        ),
        if (n > 1)
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text('× $n', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Pk.text)),
          ),
      ],
    );
  }
}
