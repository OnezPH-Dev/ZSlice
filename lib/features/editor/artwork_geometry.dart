import 'dart:math' as math;
import '../slicing/print_config.dart';
import '../slicing/slicing_plan.dart';

/// Shared physical artwork bounds, selection hit testing, and proportional
/// resizing. Viewport zoom never enters document coordinates.
class ArtworkGeometry {
  static PrintConfig fitToGrid(
    SlicingPlan plan,
    int sourceWidth,
    int sourceHeight,
  ) {
    final normalized = plan.config.change({
      'scale': 1.0,
      'stretchX': 1.0,
      'stretchY': 1.0,
      'offsetX': 0.0,
      'offsetY': 0.0,
    });
    final base = bounds(
      SlicingPlan.create(normalized),
      sourceWidth,
      sourceHeight,
    );
    final widthScale = plan.width / base.width;
    final heightScale = plan.height / base.height;
    final scale = math
        .max(1.0, math.max(widthScale, heightScale) / 10)
        .clamp(1.0, 10.0);
    final next = normalized.change({
      'scale': scale,
      'stretchX': widthScale / scale,
      'stretchY': heightScale / scale,
    });
    SlicingPlan.create(next);
    return next;
  }

  static PhysicalRect bounds(
    SlicingPlan plan,
    int sourceWidth,
    int sourceHeight,
  ) {
    final c = plan.config;
    var w = sourceWidth * (c.cropRight - c.cropLeft);
    var h = sourceHeight * (c.cropBottom - c.cropTop);
    if (c.rotation.isOdd) {
      final old = w;
      w = h;
      h = old;
    }
    final fit = math.min(plan.width / w, plan.height / h) * c.scale;
    final width = w * fit * c.stretchX;
    final height = h * fit * c.stretchY;
    return PhysicalRect(
      (plan.width - width) / 2 + c.offsetX,
      (plan.height - height) / 2 + c.offsetY,
      width,
      height,
    );
  }

  static List<double> guides(SlicingPlan plan, bool horizontal) => {
    0.0,
    horizontal ? plan.width / 2 : plan.height / 2,
    horizontal ? plan.width : plan.height,
    for (final tile in plan.tiles) ...[
      horizontal ? tile.posterRect.x : tile.posterRect.y,
      horizontal
          ? math.min(plan.width, tile.posterRect.right)
          : math.min(plan.height, tile.posterRect.bottom),
    ],
  }.toList()..sort();

  static double snapDelta(
    List<double> edges,
    List<double> guides,
    double threshold,
  ) {
    var result = 0.0, distance = threshold;
    for (final edge in edges) {
      for (final guide in guides) {
        if ((guide - edge).abs() < distance) {
          distance = (guide - edge).abs();
          result = guide - edge;
        }
      }
    }
    return result;
  }

  static PhysicalRect move(
    SlicingPlan plan,
    PhysicalRect rect,
    double dx,
    double dy,
    double threshold,
  ) {
    var x = rect.x + dx, y = rect.y + dy;
    if (plan.config.snap) {
      x += snapDelta(
        [x, x + rect.width / 2, x + rect.width],
        guides(plan, true),
        threshold,
      );
      y += snapDelta(
        [y, y + rect.height / 2, y + rect.height],
        guides(plan, false),
        threshold,
      );
    }
    return PhysicalRect(x, y, rect.width, rect.height);
  }

  static PrintConfig place(
    SlicingPlan plan,
    PhysicalRect rect,
    int sourceWidth,
    int sourceHeight, {
    bool independent = false,
  }) {
    final base = bounds(
      SlicingPlan.create(
        plan.config.change({
          'scale': 1.0,
          'stretchX': 1.0,
          'stretchY': 1.0,
          'offsetX': 0.0,
          'offsetY': 0.0,
        }),
      ),
      sourceWidth,
      sourceHeight,
    );
    return plan.config.change({
      if (independent) ...{
        'stretchX': (rect.width / (base.width * plan.config.scale)).clamp(
          0.05,
          10.0,
        ),
        'stretchY': (rect.height / (base.height * plan.config.scale)).clamp(
          0.05,
          10.0,
        ),
      } else
        'scale': (rect.width / (base.width * plan.config.stretchX)).clamp(
          0.05,
          10.0,
        ),
      'offsetX': rect.x + rect.width / 2 - plan.width / 2,
      'offsetY': rect.y + rect.height / 2 - plan.height / 2,
    });
  }

  static PhysicalRect resize(
    SlicingPlan plan,
    PhysicalRect rect,
    String corner,
    double dx,
    double dy,
    double threshold,
  ) {
    if (!corner.contains('-')) {
      final horizontal = corner == 'left' || corner == 'right';
      final leading = corner == 'left' || corner == 'top';
      final oldSize = horizontal ? rect.width : rect.height;
      final stretch = horizontal ? plan.config.stretchX : plan.config.stretchY;
      final axisBase = oldSize / stretch;
      var size = oldSize + (horizontal ? dx : dy) * (leading ? -1 : 1);
      final anchor = horizontal
          ? (leading ? rect.right : rect.x)
          : (leading ? rect.bottom : rect.y);
      if (plan.config.snap) {
        final edge = anchor + (leading ? -size : size);
        size +=
            snapDelta([edge], guides(plan, horizontal), threshold) *
            (leading ? -1 : 1);
      }
      size = size.clamp(axisBase * 0.05, axisBase * 10);
      return PhysicalRect(
        horizontal && leading ? anchor - size : rect.x,
        !horizontal && leading ? anchor - size : rect.y,
        horizontal ? size : rect.width,
        horizontal ? rect.height : size,
      );
    }
    final left = corner.contains('left'), top = corner.contains('top');
    final sx = left ? -1.0 : 1.0, sy = top ? -1.0 : 1.0;
    final anchorX = left ? rect.right : rect.x;
    final anchorY = top ? rect.bottom : rect.y;
    final ratio = rect.width / rect.height;
    var w = math.max(
      1.0,
      (rect.width + dx * sx + (rect.height + dy * sy) / ratio) /
          (1 + 1 / (ratio * ratio)),
    );
    if (plan.config.snap) {
      final deltaX = snapDelta(
        [anchorX + sx * w],
        guides(plan, true),
        threshold,
      );
      final deltaY = snapDelta(
        [anchorY + sy * w / ratio],
        guides(plan, false),
        threshold,
      );
      if (deltaX != 0 &&
          (deltaY == 0 || deltaX.abs() <= deltaY.abs() * ratio)) {
        w += deltaX * sx;
      } else if (deltaY != 0) {
        w += deltaY * sy * ratio;
      }
    }
    w = math.max(1, w);
    final h = w / ratio;
    return PhysicalRect(
      left ? anchorX - w : anchorX,
      top ? anchorY - h : anchorY,
      w,
      h,
    );
  }
}
