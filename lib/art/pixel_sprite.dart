// pixel_sprite.dart — draws pixel art from number grids, with every pixel a sharp square at any size.
// All characters, items and tiles in the app are grids like this (see penko_frames.dart).
import 'dart:async';
import 'dart:collection';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

typedef PixelGrid = List<List<int>>;

/// Mirror a grid left↔right (Penko walking left = walking right, mirrored)
PixelGrid mirror(PixelGrid g) => [for (final row in g) row.reversed.toList()];

/// Each grid is drawn once into a tiny image (one image pixel per grid cell) and then scaled up with sharp edges:
/// one image draw per sprite instead of a rectangle per pixel, every frame. Grids and palettes are kept for the
/// app's lifetime (sprite() and penkoFrames() return the same objects every time), so the cache stays small.
final _images = Expando<Map<Map<int, Color>, ui.Image>>('pixel images');

ui.Image pixelImage(PixelGrid grid, Map<int, Color> palette) {
  final byPalette = _images[grid] ??= HashMap.identity();
  return byPalette[palette] ??= () {
    final rows = grid.length, cols = grid.first.length;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()..isAntiAlias = false;
    for (var y = 0; y < rows; y++) {
      for (var x = 0; x < cols; x++) {
        final v = grid[y][x];
        if (v == 0) continue;
        paint.color = palette[v] ?? const Color(0xFFFF00FF);
        canvas.drawRect(Rect.fromLTWH(x.toDouble(), y.toDouble(), 1, 1), paint);
      }
    }
    final picture = recorder.endRecording();
    final image = picture.toImageSync(cols, rows);
    picture.dispose();
    return image;
  }();
}

/// Sharp (nearest-pixel) scaling for pixel art
final pixelPaint = Paint()
  ..filterQuality = FilterQuality.none
  ..isAntiAlias = false;

/// A map's still picture, drawn once per [key] at its pixel size and kept as images (one per wave position): each
/// frame then draws one image instead of thousands of rectangles. The previous key's images are freed.
class LayerCache {
  String? _key;
  final _images = <int, ui.Image>{};

  ui.Image get(String key, int variant, int width, int height, void Function(Canvas canvas, int variant) draw) {
    if (key != _key) {
      for (final i in _images.values) {
        i.dispose();
      }
      _images.clear();
      _key = key;
    }
    return _images[variant] ??= () {
      final recorder = ui.PictureRecorder();
      draw(Canvas(recorder), variant);
      final picture = recorder.endRecording();
      final image = picture.toImageSync(width, height);
      picture.dispose();
      return image;
    }();
  }
}

/// Paints one grid. [palette] maps pixel values to colours; value 0 is always transparent.
class PixelPainter extends CustomPainter {
  final PixelGrid grid;
  final Map<int, Color> palette;
  PixelPainter(this.grid, this.palette);

  @override
  void paint(Canvas canvas, Size size) {
    if (grid.isEmpty || grid.first.isEmpty) return;
    final image = pixelImage(grid, palette);
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Offset.zero & size,
      pixelPaint,
    );
  }

  @override
  bool shouldRepaint(PixelPainter old) => old.grid != grid || old.palette != palette;
}

/// A still pixel image, [size] logical pixels wide (height follows the grid's shape)
class PixelSprite extends StatelessWidget {
  final PixelGrid grid;
  final Map<int, Color> palette;
  final double size;
  const PixelSprite(this.grid, {super.key, required this.palette, this.size = 64});

  @override
  Widget build(BuildContext context) {
    final aspect = grid.isEmpty ? 1.0 : grid.length / grid.first.length;
    return RepaintBoundary(
      child: CustomPaint(size: Size(size, size * aspect), painter: PixelPainter(grid, palette)),
    );
  }
}

/// Plays a list of frames on a loop at [fps]
class PixelAnimation extends StatefulWidget {
  final List<PixelGrid> frames;
  final Map<int, Color> palette;
  final double size;
  final double fps;
  const PixelAnimation(this.frames, {super.key, required this.palette, this.size = 64, this.fps = 4});

  @override
  State<PixelAnimation> createState() => _PixelAnimationState();
}

class _PixelAnimationState extends State<PixelAnimation> {
  // A timer that wakes only when the frame changes (idle Penko: twice a second), not a ticker that wakes the screen 60
  // times a second: it saves battery on cheap phones. It also stands still on screens that aren't showing.
  Timer? _timer;
  int _frame = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _timer?.cancel();
    if (widget.frames.length > 1 && TickerMode.valuesOf(context).enabled) {
      _timer = Timer.periodic(Duration(milliseconds: (1000 / widget.fps).round()), (_) {
        if (mounted) setState(() => _frame = (_frame + 1) % widget.frames.length);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      PixelSprite(widget.frames[_frame % widget.frames.length], palette: widget.palette, size: widget.size);
}
