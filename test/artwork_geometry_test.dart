import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:zslice/features/editor/artwork_geometry.dart';
import 'package:zslice/features/slicing/print_config.dart';
import 'package:zslice/features/slicing/slicing_plan.dart';
import 'package:zslice/features/slicing/text_layer.dart';

void main() {
  const config = PrintConfig(
    rows: 2,
    columns: 2,
    paper: 'Custom',
    customWidth: 100,
    customHeight: 100,
    margins: false,
  );
  test(
    'selection bounds follow actual aspect-fit artwork, crop and rotation',
    () {
      final p = SlicingPlan.create(config);
      final r = ArtworkGeometry.bounds(p, 400, 200);
      expect((r.x, r.y, r.width, r.height), (0.0, 50.0, 200.0, 100.0));
      final rotated = ArtworkGeometry.bounds(
        SlicingPlan.create(config.change({'rotation': 1})),
        400,
        200,
      );
      expect(
        (rotated.x, rotated.y, rotated.width, rotated.height),
        (50.0, 0.0, 100.0, 200.0),
      );
      final cropped = ArtworkGeometry.bounds(
        SlicingPlan.create(config.change({'cropRight': 0.5})),
        400,
        200,
      );
      expect(cropped.width, 200);
      expect(cropped.height, 200);
    },
  );
  test('move snaps object edges and centers to tile guides', () {
    final p = SlicingPlan.create(config);
    final rect = ArtworkGeometry.move(
      p,
      const PhysicalRect(20, 20, 40, 40),
      38,
      78,
      3,
    );
    expect(rect.x, 60);
    expect(rect.y, 100);
    final noSnap = ArtworkGeometry.move(
      SlicingPlan.create(config.change({'snap': false})),
      const PhysicalRect(20, 20, 40, 40),
      38,
      78,
      3,
    );
    expect(noSnap.x, 58);
    expect(noSnap.y, 98);
  });
  test('corner resize preserves aspect ratio and opposite anchor', () {
    final p = SlicingPlan.create(config.change({'snap': false}));
    final r = ArtworkGeometry.resize(
      p,
      const PhysicalRect(10, 20, 100, 50),
      'bottom-right',
      20,
      10,
      0,
    );
    expect(r.x, 10);
    expect(r.y, 20);
    expect(r.width, closeTo(120, 1e-8));
    expect(r.height, closeTo(60, 1e-8));
    final topLeft = ArtworkGeometry.resize(
      p,
      const PhysicalRect(10, 20, 100, 50),
      'top-left',
      -20,
      -10,
      0,
    );
    expect(topLeft.right, closeTo(110, 1e-8));
    expect(topLeft.bottom, closeTo(70, 1e-8));
  });
  test('resizing snaps its moving edge to a sheet boundary', () {
    final p = SlicingPlan.create(config);
    final r = ArtworkGeometry.resize(
      p,
      const PhysicalRect(0, 0, 80, 40),
      'bottom-right',
      18,
      9,
      3,
    );
    expect(r.right, closeTo(100, 1e-8));
    expect(r.height, closeTo(50, 1e-8));
  });
  test('physical placement round trips without viewport dependence', () {
    final p = SlicingPlan.create(config);
    final next = ArtworkGeometry.place(
      p,
      const PhysicalRect(20, 30, 80, 40),
      400,
      200,
    );
    final actual = ArtworkGeometry.bounds(SlicingPlan.create(next), 400, 200);
    expect(
      (actual.x, actual.y, actual.width, actual.height),
      (20.0, 30.0, 80.0, 40.0),
    );
  });
  for (final rotation in [0, 1]) {
    test('fit to 5 by 5 grid fills all sheets at rotation $rotation', () {
      final p = SlicingPlan.create(
        config.change({
          'columns': 5,
          'rows': 5,
          'margins': true,
          'overlapEnabled': true,
          'rotation': rotation,
          'cropLeft': 0.1,
          'cropBottom': 0.8,
          'scale': 0.05,
          'stretchX': 0.2,
          'stretchY': 0.7,
          'offsetX': 33.0,
          'offsetY': -20.0,
        }),
      );
      final fitted = ArtworkGeometry.fitToGrid(p, 400, 200);
      final actual = ArtworkGeometry.bounds(
        SlicingPlan.create(fitted),
        400,
        200,
      );
      expect(actual.x, closeTo(0, 1e-8));
      expect(actual.y, closeTo(0, 1e-8));
      expect(actual.width, closeTo(p.width, 1e-8));
      expect(actual.height, closeTo(p.height, 1e-8));
      expect(SlicingPlan.create(fitted).tiles.length, 25);
      expect(fitted.rotation, rotation);
      expect(fitted.cropLeft, 0.1);
      expect(fitted.cropBottom, 0.8);
    });
  }
  test('fit to grid handles wide artwork without clamping it short', () {
    final p = SlicingPlan.create(config.change({'columns': 5, 'rows': 5}));
    final fitted = ArtworkGeometry.fitToGrid(p, 2000, 100);
    final actual = ArtworkGeometry.bounds(
      SlicingPlan.create(fitted),
      2000,
      100,
    );
    expect(actual.width, closeTo(p.width, 1e-8));
    expect(actual.height, closeTo(p.height, 1e-8));
    expect(fitted.scale, greaterThan(1));
  });
  test('text and snapping survive JSON; older projects receive defaults', () {
    final c = config.change({
      'texts': [
        const TextLayer(
          id: 'title',
          text: 'Hello',
          bold: true,
          align: 'center',
        ).toJson(),
      ],
      'snap': false,
    });
    final restored = PrintConfig.fromJson(jsonDecode(jsonEncode(c.toJson())));
    expect(restored.texts.single.text, 'Hello');
    expect(restored.texts.single.bold, isTrue);
    expect(restored.snap, isFalse);
    expect(PrintConfig.fromJson({}).texts, isEmpty);
    expect(PrintConfig.fromJson({}).snap, isTrue);
    expect(PrintConfig.fromJson({}).stretchX, 1);
    expect(PrintConfig.fromJson({}).stretchY, 1);
  });
  for (final rotation in [0, 1]) {
    for (final edge in ['left', 'right', 'top', 'bottom']) {
      test(
        '$edge resize changes one axis and preserves its anchor at rotation $rotation',
        () {
          final p = SlicingPlan.create(
            config.change({
              'rotation': rotation,
              'scale': 0.5,
              'snap': false,
              'stretchX': 1.2,
              'stretchY': 0.8,
            }),
          );
          final original = ArtworkGeometry.bounds(p, 400, 200);
          final horizontal = edge == 'left' || edge == 'right';
          final leading = edge == 'left' || edge == 'top';
          final next = ArtworkGeometry.resize(
            p,
            original,
            edge,
            horizontal ? (leading ? -10 : 10) : 0,
            horizontal ? 0 : (leading ? -10 : 10),
            0,
          );
          final placed = ArtworkGeometry.place(
            p,
            next,
            400,
            200,
            independent: true,
          );
          final restored = PrintConfig.fromJson(
            jsonDecode(jsonEncode(placed.toJson())),
          );
          final actual = ArtworkGeometry.bounds(
            SlicingPlan.create(restored),
            400,
            200,
          );
          expect(
            actual.width,
            closeTo(original.width + (horizontal ? 10 : 0), 1e-8),
          );
          expect(
            actual.height,
            closeTo(original.height + (horizontal ? 0 : 10), 1e-8),
          );
          expect(
            leading && horizontal ? actual.right : actual.x,
            closeTo(leading && horizontal ? original.right : original.x, 1e-8),
          );
          expect(
            leading && !horizontal ? actual.bottom : actual.y,
            closeTo(
              leading && !horizontal ? original.bottom : original.y,
              1e-8,
            ),
          );
          expect(restored.scale, p.config.scale);
        },
      );
    }
  }
  test('edge resize snaps and stops before crossing the opposite edge', () {
    final p = SlicingPlan.create(config);
    final original = ArtworkGeometry.bounds(p, 400, 200);
    final snapped = ArtworkGeometry.resize(p, original, 'left', 98, 0, 3);
    expect(snapped.x, closeTo(100, 1e-8));
    expect(snapped.right, original.right);
    final collapsed = ArtworkGeometry.resize(p, original, 'left', 10000, 0, 0);
    expect(collapsed.width, greaterThan(0));
    expect(collapsed.right, original.right);
    final placed = ArtworkGeometry.place(
      p,
      collapsed,
      400,
      200,
      independent: true,
    );
    final actual = ArtworkGeometry.bounds(SlicingPlan.create(placed), 400, 200);
    expect(actual.right, closeTo(original.right, 1e-8));
  });
  for (final bad in [
    {'width': 0.0},
    {'fontSize': double.nan},
    {'align': 'invalid'},
  ]) {
    test('invalid text is rejected: $bad', () {
      expect(
        () => SlicingPlan.create(
          config.change({
            'texts': [const TextLayer(id: 'bad').change(bad).toJson()],
          }),
        ),
        throwsFormatException,
      );
    });
  }
}
