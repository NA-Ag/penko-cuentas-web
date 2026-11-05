// penko.dart — Penko, animated: plain Penko, the teacher.
import 'package:flutter/widgets.dart';

import 'palette.dart';
import 'penko_frames.dart';
import 'pixel_sprite.dart';

enum PenkoPose { idle, walk, walkLeft, walkRight, jump, talk, hurt }

final _frames = <PenkoPose, List<PixelGrid>>{};

/// Penko's frames for a pose: made once and kept (so their drawn images can be cached)
List<PixelGrid> penkoFrames(PenkoPose pose) => _frames[pose] ??= switch (pose) {
  PenkoPose.idle => penkoIdle,
  PenkoPose.walk => penkoWalk,
  PenkoPose.jump => penkoJump,
  PenkoPose.talk => penkoTalk,
  PenkoPose.hurt => penkoHurt,
  PenkoPose.walkRight => penkoWalkRight,
  PenkoPose.walkLeft => [for (final g in penkoWalkRight) mirror(g)],
};

class Penko extends StatelessWidget {
  final PenkoPose pose;
  final double size;
  const Penko({super.key, this.pose = PenkoPose.idle, this.size = 96});

  static const _fps = {
    PenkoPose.idle: 2.0,
    PenkoPose.talk: 6.0,
    PenkoPose.walk: 6.0,
    PenkoPose.walkLeft: 8.0,
    PenkoPose.walkRight: 8.0,
    PenkoPose.jump: 6.0,
    PenkoPose.hurt: 6.0,
  };

  @override
  Widget build(BuildContext context) => PixelAnimation(
    penkoFrames(pose),
    palette: penkoPalette,
    key: ValueKey(pose),
    size: size,
    fps: _fps[pose]!,
  );
}
