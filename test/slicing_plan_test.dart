import 'package:flutter_test/flutter_test.dart';
import 'package:zslice/features/slicing/print_config.dart';
import 'package:zslice/features/slicing/slicing_plan.dart';

void main() {
  for (final count in [1, 3, 20]) {
    test('$count × $count grid has exact coverage and page count', () {
      final plan = SlicingPlan.create(
        PrintConfig(rows: count, columns: count, margins: false),
      );
      expect(plan.tiles.length, count * count);
      expect(plan.width, closeTo(215.9 * count, 1e-8));
      expect(plan.height, closeTo(279.4 * count, 1e-8));
      expect(plan.tiles.last.posterRect.right, closeTo(plan.width, 1e-8));
    });
  }
  for (final paper in paperSizes.keys) {
    for (final landscape in [false, true]) {
      test('$paper orientation $landscape', () {
        final config = PrintConfig(
          paper: paper,
          landscape: landscape,
          rows: 1,
          columns: 1,
          margins: false,
        );
        final plan = SlicingPlan.create(config);
        expect(
          plan.width,
          landscape ? paperSizes[paper]!.$2 : paperSizes[paper]!.$1,
        );
        expect(
          plan.height,
          landscape ? paperSizes[paper]!.$1 : paperSizes[paper]!.$2,
        );
      });
    }
  }
  test('independent margins change usable area in millimetres', () {
    final p = SlicingPlan.create(
      const PrintConfig(
        rows: 1,
        columns: 1,
        left: 25.4,
        right: 12.7,
        top: 6.35,
        bottom: 0,
      ),
    );
    expect(p.printable.x, 25.4);
    expect(p.printable.y, 6.35);
    expect(p.width, closeTo(177.8, 1e-8));
    expect(p.height, closeTo(273.05, 1e-8));
  });
  for (final overlap in [0.0, 6.35, 12.7]) {
    test('adjacent tiles repeat $overlap mm of artwork', () {
      final p = SlicingPlan.create(
        PrintConfig(margins: false, overlapEnabled: true, overlap: overlap),
      );
      expect(p.width, closeTo(215.9 * 3 - overlap * 2, 1e-8));
      expect(
        p.tiles[0].posterRect.right - p.tiles[1].posterRect.x,
        closeTo(overlap, 1e-8),
      );
      expect(
        p.tiles[0].posterRect.bottom - p.tiles[3].posterRect.y,
        closeTo(overlap, 1e-8),
      );
    });
  }
  test('disabled overlap ignores saved overlap amount', () {
    final p = SlicingPlan.create(
      const PrintConfig(margins: false, overlap: 50),
    );
    expect(p.width, closeTo(647.7, 1e-8));
  });
  test('custom dimensions, overlap, and final partial sheet', () {
    final p = SlicingPlan.create(
      const PrintConfig(
        layout: 'size',
        posterWidth: 600,
        posterHeight: 800,
        margins: false,
        overlapEnabled: true,
        overlap: 12.7,
      ),
    );
    expect(p.columns, 3);
    expect(p.rows, 3);
    expect(p.width, 600);
    expect(p.height, 800);
    expect(p.tiles.last.posterRect.right, greaterThanOrEqualTo(600));
  });
  test(
    'custom dimensions at exact sheet boundary do not create blank sheet',
    () {
      final p = SlicingPlan.create(
        const PrintConfig(
          layout: 'size',
          posterWidth: 419.1,
          posterHeight: 279.4,
          margins: false,
          overlapEnabled: true,
          overlap: 12.7,
        ),
      );
      expect(p.columns, 2);
      expect(p.rows, 1);
    },
  );
  test('column major ordering numbers by column without moving geometry', () {
    final p = SlicingPlan.create(
      const PrintConfig(
        rows: 2,
        columns: 3,
        order: 'column',
        numberStyle: 'coordinates',
      ),
    );
    expect(p.tiles.map((t) => t.label(p.config, 6)).toList(), [
      'R1-C1',
      'R2-C1',
      'R1-C2',
      'R2-C2',
      'R1-C3',
      'R2-C3',
    ]);
    expect(p.tiles[2].posterRect.y, 0);
  });
  test('interior cutting edges exclude outer poster boundary', () {
    final p = SlicingPlan.create(
      const PrintConfig(cutTop: true, cutLeft: true),
    );
    expect(p.edges(p.tiles.first), ['right', 'bottom']);
    expect(p.edges(p.tiles[4]), ['top', 'right', 'bottom', 'left']);
    expect(p.edges(p.tiles.last), ['top', 'left']);
  });
  test('DPI auto respects source and caps print resolution', () {
    final p = SlicingPlan.create(
      const PrintConfig(rows: 1, columns: 1, margins: false),
    );
    expect(p.effectiveDpi(2550, 3300), 300);
    expect(
      SlicingPlan.create(
        p.config.change({'scale': 2.0}),
      ).effectiveDpi(2550, 3300),
      150,
    );
    expect(p.effectiveDpi(100, 100), 72);
    expect(
      SlicingPlan.create(
        p.config.change({'autoDpi': false, 'dpi': 600}),
      ).effectiveDpi(100, 100),
      600,
    );
  });
  for (final bad in <Map<String, dynamic>>[
    {'rows': 0},
    {'columns': 21},
    {'top': 500},
    {'left': -1.0},
    {'overlapEnabled': true, 'overlap': 500.0},
    {'posterWidth': double.nan},
    {'layout': 'size', 'posterWidth': 999999.0},
    {'dpi': 0},
    {'scale': 0.0},
    {'stretchX': 0.0},
    {'stretchY': double.infinity},
    {'cropLeft': 1.0},
    {'cropRight': 0.0},
    {'numberSize': 1000.0},
  ]) {
    test(
      'reject invalid settings $bad',
      () => expect(
        () => SlicingPlan.create(const PrintConfig().change(bad)),
        throwsFormatException,
      ),
    );
  }
}
