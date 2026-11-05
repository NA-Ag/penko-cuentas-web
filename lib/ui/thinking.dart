// thinking.dart — what the screen shows while the tutor model works, so it's clear something is happening: dots that
// bounce in Penko's speech bubble while she thinks, and for longer jobs (reading a receipt) Penko bobbing over a bar
// that fills towards the usual time, with the seconds counting.
import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../art/palette.dart';
import '../i18n/lang.dart';
import '../art/penko.dart';

/// Three dots bouncing one after another
class ThinkingDots extends StatefulWidget {
  final Color color;
  const ThinkingDots({super.key, this.color = Pk.onDialog});

  @override
  State<ThinkingDots> createState() => _ThinkingDotsState();
}

class _ThinkingDotsState extends State<ThinkingDots> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (_, _) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 3; i++)
          Transform.translate(
            offset: Offset(0, -5 * max(0, sin((_c.value - i * 0.18) * 2 * pi))),
            child: Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
            ),
          ),
      ],
    ),
  );
}

/// Penko's bubble text while she thinks: "Pensando" ("Thinking") and the dots
class ThinkingLine extends StatelessWidget {
  final String? label; // null: "Pensando" / "Thinking"
  final Color color;
  const ThinkingLine({super.key, this.label, this.color = Pk.onDialog});

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    label: '${label ?? tr('Pensando', 'Thinking')}…',
    child: Row(
      children: [
        Text(label ?? tr('Pensando', 'Thinking'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: color)),
        const SizedBox(width: 8),
        Padding(padding: const EdgeInsets.only(top: 6), child: ThinkingDots(color: color)),
      ],
    ),
  );
}

/// For longer jobs: Penko bobbing, what she's doing, a bar that fills towards the usual time, and the seconds
class PenkoWorking extends StatefulWidget {
  final String label;
  final Duration usual; // how long it usually takes on a phone, so the bar means something
  const PenkoWorking({super.key, required this.label, this.usual = const Duration(seconds: 45)});

  @override
  State<PenkoWorking> createState() => _PenkoWorkingState();
}

class _PenkoWorkingState extends State<PenkoWorking> with SingleTickerProviderStateMixin {
  late final _bob = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
  final _start = DateTime.now();
  late final Timer _tick = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));

  @override
  void initState() {
    super.initState();
    _tick; // start counting
  }

  @override
  void dispose() {
    _tick.cancel();
    _bob.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final secs = DateTime.now().difference(_start).inSeconds;
    // Fills to 90% at the usual time, then creeps on: it never claims to be done before it is
    final t = secs / widget.usual.inSeconds;
    final progress = t < 1 ? 0.9 * t : 0.9 + 0.09 * (1 - 1 / (1 + (t - 1)));
    return Semantics(
      liveRegion: true,
      label: '${widget.label}. ${tr('$secs segundos.', '$secs seconds.')}',
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _bob,
            builder: (_, child) => Transform.translate(offset: Offset(0, -6 * _bob.value), child: child),
            child: const Penko(pose: PenkoPose.talk, size: 88),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.label, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
              const SizedBox(width: 8),
              const Padding(padding: EdgeInsets.only(top: 6), child: ThinkingDots(color: Pk.gold)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(value: progress, minHeight: 8),
          ),
          const SizedBox(height: 6),
          Text('$secs s', style: const TextStyle(color: Pk.textSoft, fontSize: 13)),
        ],
      ),
    );
  }
}

/// A picture with a gold line sweeping down it, while Penko reads it
class ScanningImage extends StatefulWidget {
  final ImageProvider image;
  const ScanningImage({super.key, required this.image});

  @override
  State<ScanningImage> createState() => _ScanningImageState();
}

class _ScanningImageState extends State<ScanningImage> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(16),
    child: LayoutBuilder(
      builder: (context, box) => Stack(
        children: [
          Container(color: Pk.card, width: box.maxWidth, height: box.maxHeight),
          Image(image: widget.image, fit: BoxFit.contain, width: box.maxWidth, height: box.maxHeight),
          Container(color: Pk.paper.withValues(alpha: 0.25)),
          AnimatedBuilder(
            animation: _c,
            builder: (_, _) => Positioned(
              top: _c.value * (box.maxHeight - 4),
              left: 0,
              right: 0,
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  color: Pk.gold,
                  boxShadow: [BoxShadow(color: Pk.gold.withValues(alpha: 0.7), blurRadius: 14, spreadRadius: 2)],
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
