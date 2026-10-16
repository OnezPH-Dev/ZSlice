import 'dart:math' as math;
import 'print_config.dart';

class PhysicalRect {
  const PhysicalRect(this.x, this.y, this.width, this.height);
  final double x, y, width, height;
  double get right => x + width;
  double get bottom => y + height;
}

class Tile {
  const Tile(this.index, this.row, this.column, this.posterRect);
  final int index, row, column;
  final PhysicalRect posterRect;

  String label(PrintConfig c, int total) => switch (c.numberStyle) {
    'sequential' => '${index + 1}',
    'coordinates' => 'R${row + 1}-C${column + 1}',
    'verbose' => 'Row ${row + 1} / Column ${column + 1}',
    _ => 'Page ${index + 1} of $total',
  };
}

class SlicingPlan {
  SlicingPlan._(
    this.config,
    this.rows,
    this.columns,
    this.width,
    this.height,
    this.printable,
    this.tiles,
  );
  final PrintConfig config;
  final int rows, columns;
  final double width, height;
  final PhysicalRect printable;
  final List<Tile> tiles;

  factory SlicingPlan.create(PrintConfig c) {
    if (c.texts.length > 50) {
      throw const FormatException('Use up to 50 text layers per poster.');
    }
    final ids = <String>{};
    for (final t in c.texts) {
      if (!ids.add(t.id) ||
          t.id.isEmpty ||
          t.text.length > 10000 ||
          ![t.x, t.y, t.width, t.fontSize].every((v) => v.isFinite) ||
          t.width < 1 ||
          t.width > 24000 ||
          t.fontSize < 4 ||
          t.fontSize > 1000 ||
          t.color < 0 ||
          t.color > 0xffffffff ||
          !{'left', 'center', 'right'}.contains(t.align)) {
        throw const FormatException(
          'Invalid text layer dimensions, style or identifier.',
        );
      }
    }
    final validOptions = <String, (String, Set<String>)>{
      'Scissors placement': (
        c.scissorsPlacement,
        {'all', 'selected', 'corners'},
      ),
      'Layout': (c.layout, {'grid', 'size'}),
      'Paper': (c.paper, {...paperSizes.keys, 'Custom'}),
      'Line style': (
        c.lineStyle,
        {'solid', 'dashed', 'dotted', 'dashDot', 'corners'},
      ),
      'Number format': (
        c.numberStyle,
        {'sequential', 'page', 'coordinates', 'verbose'},
      ),
      'Number position': (
        c.numberPosition,
        {'topLeft', 'topRight', 'bottomLeft', 'bottomRight', 'bottomCenter'},
      ),
      'Page order': (c.order, {'row', 'column'}),
    };
    for (final entry in validOptions.entries) {
      if (!entry.value.$2.contains(entry.value.$1)) {
        throw FormatException('Unsupported ${entry.key.toLowerCase()}.');
      }
    }
    if (c.rotation < 0 || c.rotation > 3) {
      throw const FormatException(
        'Rotation must be 0, 90, 180 or 270 degrees.',
      );
    }
    if (!c.scissorsSize.isFinite ||
        c.scissorsSize < 0.5 ||
        c.scissorsSize > 3 ||
        [
          c.guideColor,
          c.scissorsColor,
          c.numberColor,
        ].any((color) => color < 0 || color > 0xffffffff)) {
      throw const FormatException('Invalid guide size or color.');
    }
    final (pw, ph) = c.paperSize;
    final nums = [
      pw,
      ph,
      c.top,
      c.right,
      c.bottom,
      c.left,
      c.overlap,
      c.posterWidth,
      c.posterHeight,
      c.scale,
      c.stretchX,
      c.stretchY,
      c.offsetX,
      c.offsetY,
      c.cropLeft,
      c.cropTop,
      c.cropRight,
      c.cropBottom,
      c.lineWidth,
      c.numberSize,
    ];
    if (nums.any((v) => !v.isFinite)) {
      throw const FormatException('Measurements must be finite numbers.');
    }
    if (pw <= 0 || ph <= 0 || pw > 1200 || ph > 1200) {
      throw const FormatException(
        'Paper dimensions must be between 0 and 1200 mm.',
      );
    }
    if ([c.top, c.right, c.bottom, c.left, c.overlap].any((v) => v < 0)) {
      throw const FormatException('Margins and overlap cannot be negative.');
    }
    final l = c.margins ? c.left : 0.0;
    final t = c.margins ? c.top : 0.0;
    final uw = pw - l - (c.margins ? c.right : 0);
    final uh = ph - t - (c.margins ? c.bottom : 0);
    if (uw <= 0 || uh <= 0) {
      throw const FormatException('Margins must leave a printable area.');
    }
    final o = c.overlapEnabled ? c.overlap : 0.0;
    if (o >= uw || o >= uh) {
      throw const FormatException(
        'Overlap must be smaller than the printable area.',
      );
    }
    if (c.posterWidth <= 0 || c.posterHeight <= 0) {
      throw const FormatException('Poster dimensions must be positive.');
    }
    final cols = c.layout == 'size'
        ? math.max(1, ((c.posterWidth - o) / (uw - o) - 1e-10).ceil())
        : c.columns;
    final rows = c.layout == 'size'
        ? math.max(1, ((c.posterHeight - o) / (uh - o) - 1e-10).ceil())
        : c.rows;
    if (cols < 1 || rows < 1 || cols > 20 || rows > 20) {
      throw const FormatException(
        'Use 1–20 rows and columns (up to 400 sheets).',
      );
    }
    if (c.dpi < 36 || c.dpi > 1200 || c.scale < 0.05 || c.scale > 10) {
      throw const FormatException(
        'DPI must be 36–1200 and artwork scale 5–1000%.',
      );
    }
    if (c.stretchX < 0.05 ||
        c.stretchX > 10 ||
        c.stretchY < 0.05 ||
        c.stretchY > 10) {
      throw const FormatException(
        'Image width and height stretch must be 5–1000%.',
      );
    }
    if (c.cropLeft < 0 ||
        c.cropTop < 0 ||
        c.cropRight > 1 ||
        c.cropBottom > 1 ||
        c.cropRight <= c.cropLeft ||
        c.cropBottom <= c.cropTop) {
      throw const FormatException(
        'Crop must leave a nonempty area within the image.',
      );
    }
    if (c.lineWidth <= 0 ||
        c.lineWidth > 10 ||
        c.numberSize < 4 ||
        c.numberSize > 72) {
      throw const FormatException(
        'Guide thickness: 0–10 pt. Number size: 4–72 pt.',
      );
    }
    final w = c.layout == 'size' ? c.posterWidth : uw * cols - o * (cols - 1);
    final h = c.layout == 'size' ? c.posterHeight : uh * rows - o * (rows - 1);
    final tiles = <Tile>[];
    for (var i = 0; i < rows * cols; i++) {
      final r = c.order == 'column' ? i % rows : i ~/ cols;
      final col = c.order == 'column' ? i ~/ rows : i % cols;
      tiles.add(
        Tile(i, r, col, PhysicalRect(col * (uw - o), r * (uh - o), uw, uh)),
      );
    }
    return SlicingPlan._(
      c,
      rows,
      cols,
      w,
      h,
      PhysicalRect(l, t, uw, uh),
      List.unmodifiable(tiles),
    );
  }

  int effectiveDpi(int sourceWidth, int sourceHeight) {
    if (!config.autoDpi) return config.dpi;
    if (config.texts.isNotEmpty) return 300;
    return sourceDpi(sourceWidth, sourceHeight).round().clamp(72, 300);
  }

  double sourceDpi(int sourceWidth, int sourceHeight) {
    final croppedW = sourceWidth * (config.cropRight - config.cropLeft);
    final croppedH = sourceHeight * (config.cropBottom - config.cropTop);
    final rotated = config.rotation.isOdd;
    final mmPerPixel =
        math.min(
          width / (rotated ? croppedH : croppedW),
          height / (rotated ? croppedW : croppedH),
        ) *
        config.scale *
        math.max(config.stretchX, config.stretchY);
    return 25.4 / mmPerPixel;
  }

  List<String> edges(Tile tile) => [
    if (config.cutTop && tile.row > 0) 'top',
    if (config.cutRight && tile.column < columns - 1) 'right',
    if (config.cutBottom && tile.row < rows - 1) 'bottom',
    if (config.cutLeft && tile.column > 0) 'left',
  ];
}
