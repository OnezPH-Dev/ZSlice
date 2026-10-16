import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../slicing/slicing_plan.dart';
import '../slicing/text_layer.dart';
import 'artwork_geometry.dart';

/// All artwork and printable guide placement lives here, shared by canvas,
/// individual-sheet preview and raster exports. Coordinates are millimetres.
class PosterRenderer {
  static Rect rect(PhysicalRect r) =>
      Rect.fromLTWH(r.x, r.y, r.width, r.height);

  static void artwork(Canvas canvas, SlicingPlan plan, ui.Image image) {
    final c = plan.config;
    final src = Rect.fromLTRB(
      c.cropLeft * image.width,
      c.cropTop * image.height,
      c.cropRight * image.width,
      c.cropBottom * image.height,
    );
    final quarter = c.rotation % 2 != 0;
    final iw = quarter ? src.height : src.width;
    final bounds = ArtworkGeometry.bounds(plan, image.width, image.height);
    final fitX = bounds.width / iw;
    final fitY = bounds.height / (quarter ? src.width : src.height);
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, plan.width, plan.height));
    canvas.translate(plan.width / 2 + c.offsetX, plan.height / 2 + c.offsetY);
    canvas.rotate(c.rotation * math.pi / 2);
    canvas.drawImageRect(
      image,
      src,
      Rect.fromCenter(
        center: Offset.zero,
        width: src.width * (quarter ? fitY : fitX),
        height: src.height * (quarter ? fitX : fitY),
      ),
      Paint()..filterQuality = FilterQuality.high,
    );
    canvas.restore();
  }

  static TextPainter textPainter(TextLayer t) => TextPainter(
    text: TextSpan(
      text: t.text,
      style: TextStyle(
        fontFamily: 'Inter',
        fontSize: t.fontSize * 25.4 / 72,
        color: Color(t.color),
        fontWeight: t.bold ? FontWeight.w700 : FontWeight.w400,
        fontStyle: t.italic ? FontStyle.italic : FontStyle.normal,
      ),
    ),
    textAlign: switch (t.align) {
      'center' => TextAlign.center,
      'right' => TextAlign.right,
      _ => TextAlign.left,
    },
    textDirection: TextDirection.ltr,
  )..layout(minWidth: t.width, maxWidth: t.width);

  static Rect textBounds(TextLayer t) {
    final p = textPainter(t);
    return Rect.fromLTWH(t.x, t.y, t.width, p.height);
  }

  static void texts(Canvas canvas, SlicingPlan plan) {
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, plan.width, plan.height));
    for (final t in plan.config.texts) {
      textPainter(t).paint(canvas, Offset(t.x, t.y));
    }
    canvas.restore();
  }

  static void sheet(
    Canvas canvas,
    SlicingPlan plan,
    Tile tile,
    ui.Image? image, {
    required bool exporting,
  }) {
    final (pw, ph) = plan.config.paperSize;
    canvas.drawRect(Rect.fromLTWH(0, 0, pw, ph), Paint()..color = Colors.white);
    canvas.save();
    canvas.clipRect(rect(plan.printable));
    canvas.translate(
      plan.printable.x - tile.posterRect.x,
      plan.printable.y - tile.posterRect.y,
    );
    if (image != null) artwork(canvas, plan, image);
    texts(canvas, plan);
    canvas.restore();
    final visible = exporting
        ? plan.config.exportGuides
        : plan.config.previewGuides;
    if (visible) guides(canvas, plan, tile);
    if (plan.config.numbering) number(canvas, plan, tile);
  }

  static Map<String, (Offset, Offset)> cutSegments(SlicingPlan p, Tile t) {
    final r = rect(p.printable);
    final o = p.config.overlapEnabled ? p.config.overlap / 2 : 0.0;
    return {
      'top': (Offset(r.left, r.top + o), Offset(r.right, r.top + o)),
      'right': (Offset(r.right - o, r.top), Offset(r.right - o, r.bottom)),
      'bottom': (Offset(r.left, r.bottom - o), Offset(r.right, r.bottom - o)),
      'left': (Offset(r.left + o, r.top), Offset(r.left + o, r.bottom)),
    };
  }

  static void guides(Canvas canvas, SlicingPlan plan, Tile tile) {
    final c = plan.config;
    final paint = Paint()
      ..color = Color(c.guideColor)
      ..strokeWidth = c.lineWidth * 25.4 / 72
      ..style = PaintingStyle.stroke;
    final segments = cutSegments(plan, tile);
    for (final edge in plan.edges(tile)) {
      final (start, end) = segments[edge]!;
      if (c.lines) line(canvas, start, end, paint, c.lineStyle);
    }
    if (c.scissors) {
      final edges = c.scissorsPlacement == 'all'
          ? [
              if (tile.row > 0) 'top',
              if (tile.column < plan.columns - 1) 'right',
              if (tile.row < plan.rows - 1) 'bottom',
              if (tile.column > 0) 'left',
            ]
          : plan.edges(tile);
      final scissorsPaint = Paint()
        ..color = Color(c.scissorsColor)
        ..strokeWidth = 0.2
        ..style = PaintingStyle.stroke;
      for (final edge in edges) {
        final (start, end) = segments[edge]!;
        final delta = end - start;
        final centers = c.scissorsPlacement == 'corners'
            ? [
                start + delta / delta.distance * 6,
                end - delta / delta.distance * 6,
              ]
            : [(start + end) / 2];
        for (final center in centers) {
          final (pw, ph) = c.paperSize;
          final inset = math.min(c.scissorsSize * 2, math.min(pw, ph) / 4);
          canvas.save();
          canvas.translate(
            center.dx.clamp(inset, pw - inset),
            center.dy.clamp(inset, ph - inset),
          );
          canvas.scale(c.scissorsSize);
          scissors(canvas, Offset.zero, delta.direction, scissorsPaint);
          canvas.restore();
        }
      }
    }
  }

  static void line(Canvas canvas, Offset a, Offset b, Paint p, String style) {
    final length = (b - a).distance;
    if (length == 0) return;
    final unit = (b - a) / length;
    if (style == 'solid') {
      canvas.drawLine(a, b, p);
      return;
    }
    if (style == 'corners') {
      canvas.drawLine(a, a + unit * math.min(5, length / 2), p);
      canvas.drawLine(b - unit * math.min(5, length / 2), b, p);
      return;
    }
    final pattern = switch (style) {
      'dotted' => [0.3, 1.2],
      'dashDot' => [3.0, 1.2, 0.3, 1.2],
      _ => [3.0, 1.5],
    };
    var position = 0.0;
    var i = 0;
    while (position < length) {
      final next = math.min(length, position + pattern[i % pattern.length]);
      if (i.isEven) canvas.drawLine(a + unit * position, a + unit * next, p);
      position = next;
      i++;
    }
  }

  // Printable scissors are vector paths rather than a font glyph, so every
  // platform and export has the same symbol without font fallback.
  static void scissors(
    Canvas canvas,
    Offset center,
    double angle,
    Paint paint,
  ) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);
    canvas.drawCircle(const Offset(-1.8, -1.3), 0.9, paint);
    canvas.drawCircle(const Offset(-1.8, 1.3), 0.9, paint);
    canvas.drawLine(const Offset(-1.1, -0.8), const Offset(2.8, 1.7), paint);
    canvas.drawLine(const Offset(-1.1, 0.8), const Offset(2.8, -1.7), paint);
    canvas.restore();
  }

  static void number(Canvas canvas, SlicingPlan plan, Tile tile) {
    final c = plan.config;
    final (pw, ph) = c.paperSize;
    final text = TextPainter(
      text: TextSpan(
        text: tile.label(c, plan.tiles.length),
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: c.numberSize * 25.4 / 72,
          color: Color(c.numberColor),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: math.max(0, pw - 4));
    final position = c.numberPosition;
    final x = position.endsWith('Left')
        ? 2.0
        : position.endsWith('Right')
        ? pw - text.width - 2
        : (pw - text.width) / 2;
    final y = position.startsWith('top') ? 1.0 : ph - text.height - 1;
    text.paint(canvas, Offset(x, y));
  }
}

class PosterPainter extends CustomPainter {
  PosterPainter(this.plan, this.image, {this.tile, this.selected = false});
  final SlicingPlan plan;
  final ui.Image? image;
  final Tile? tile;
  final bool selected;
  @override
  void paint(Canvas canvas, Size size) {
    final (pw, ph) = plan.config.paperSize;
    final width = tile == null ? plan.width : pw;
    final height = tile == null ? plan.height : ph;
    canvas.scale(size.width / width, size.height / height);
    if (tile != null) {
      PosterRenderer.sheet(canvas, plan, tile!, image, exporting: false);
      return;
    }
    canvas.drawRect(
      Rect.fromLTWH(0, 0, width, height),
      Paint()..color = Colors.white,
    );
    if (image != null) PosterRenderer.artwork(canvas, plan, image!);
    PosterRenderer.texts(canvas, plan);
    final c = plan.config;
    for (final t in plan.tiles) {
      canvas.save();
      canvas.clipRect(Rect.fromLTWH(0, 0, width, height));
      canvas.translate(t.posterRect.x, t.posterRect.y);
      if (c.showOverlap && c.overlapEnabled) {
        final paint = Paint()..color = const Color(0x2206B6D4);
        if (t.column < plan.columns - 1) {
          canvas.drawRect(
            Rect.fromLTWH(
              t.posterRect.width - c.overlap,
              0,
              c.overlap,
              t.posterRect.height,
            ),
            paint,
          );
        }
        if (t.row < plan.rows - 1) {
          canvas.drawRect(
            Rect.fromLTWH(
              0,
              t.posterRect.height - c.overlap,
              t.posterRect.width,
              c.overlap,
            ),
            paint,
          );
        }
      }
      if (c.grid || c.boundaries) {
        canvas.drawRect(
          Rect.fromLTWH(0, 0, t.posterRect.width, t.posterRect.height),
          Paint()
            ..color = const Color(0x994F46E5)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.5,
        );
      }
      if (c.previewGuides) {
        canvas.translate(-plan.printable.x, -plan.printable.y);
        PosterRenderer.guides(canvas, plan, t);
        canvas.translate(plan.printable.x, plan.printable.y);
      }
      if (c.numbering) {
        final painter = TextPainter(
          text: TextSpan(
            text: t.label(c, plan.tiles.length),
            style: const TextStyle(
              fontFamily: 'Inter',
              color: Color(0xff4f46e5),
              fontSize: 5,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        painter.paint(canvas, const Offset(3, 3));
      }
      canvas.restore();
    }
    if (selected) {
      final paint = Paint()
        ..color = const Color(0xff4f46e5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      canvas.drawRect(Rect.fromLTWH(0, 0, width, height), paint);
      for (final point in [
        Offset.zero,
        Offset(width, 0),
        Offset(0, height),
        Offset(width, height),
      ]) {
        canvas.drawRect(
          Rect.fromCenter(center: point, width: 4, height: 4),
          Paint()..color = Colors.white,
        );
        canvas.drawRect(
          Rect.fromCenter(center: point, width: 4, height: 4),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant PosterPainter old) =>
      old.plan != plan ||
      old.image != image ||
      old.tile != tile ||
      old.selected != selected;
}
