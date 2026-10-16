import 'dart:ffi' show DynamicLibrary;
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/open.dart';
import 'package:zslice/app/theme/app_theme.dart';
import 'package:zslice/core/persistence/database.dart';
import 'package:zslice/features/editor/editor_screen.dart';
import 'package:zslice/features/editor/interactive_poster.dart';
import 'package:zslice/features/editor/configuration_inspector.dart';
import 'package:zslice/features/editor/crop_dialog.dart';
import 'package:zslice/features/editor/artwork_geometry.dart';
import 'package:zslice/features/projects/project.dart';
import 'package:zslice/features/projects/project_repository.dart';
import 'package:zslice/features/slicing/print_config.dart';
import 'package:zslice/features/slicing/text_layer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  if (Platform.isWindows) {
    open.overrideFor(
      OperatingSystem.windows,
      () => DynamicLibrary.open('winsqlite3.dll'),
    );
  }
  late AppDatabase db;
  late ProjectRepository repository;
  setUpAll(() async {
    await (FontLoader(
      'Inter',
    )..addFont(rootBundle.load('assets/fonts/Inter.ttf'))).load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  setUp(() {
    db = AppDatabase.memory();
    repository = ProjectRepository(db, Directory.systemTemp);
  });
  tearDown(() => db.close());

  Future<dynamic> workspace(
    WidgetTester tester,
    Size size, {
    PrintConfig config = const PrintConfig(),
    String unit = 'in',
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: appTheme(Brightness.light),
        builder: (context, child) => RepaintBoundary(
          key: const ValueKey('workflow-capture'),
          child: child!,
        ),
        home: EditorWorkspace(
          project: SliceProject(
            id: 'regression',
            name: 'Poster',
            modified: DateTime(2026),
            config: config,
          ),
          repository: repository,
          preferences: {'autosave': false, 'unit': unit},
        ),
      ),
    );
    await tester.pumpAndSettle();
    return tester.state(find.byType(EditorWorkspace));
  }

  for (final size in [const Size(1440, 940), const Size(390, 844)]) {
    testWidgets('image stays selected after a full canvas click at $size', (
      tester,
    ) async {
      final dynamic state = await workspace(tester, size);
      final recorder = ui.PictureRecorder();
      Canvas(recorder).drawRect(
        const Rect.fromLTWH(0, 0, 200, 100),
        Paint()..color = Colors.blue,
      );
      final picture = recorder.endRecording();
      state.editor.image = await picture.toImage(200, 100);
      picture.dispose();
      state.editor.update({'snap': false});
      await tester.pumpAndSettle();
      final poster = find.byType(InteractivePoster);
      final before = tester.getRect(poster);
      await tester.tapAt(before.center);
      await tester.pumpAndSettle();
      expect(state.selectedLayer, 'image');
      expect(find.byKey(const ValueKey('resize-bottom-right')), findsOneWidget);
      expect(
        tester.getRect(poster),
        before,
        reason: 'Selecting an object must not shift the canvas',
      );
      await tester.tapAt(tester.getRect(poster).center);
      await tester.pumpAndSettle();
      expect(state.selectedLayer, 'image');
      expect(find.byType(AlertDialog), findsNothing);
      final handle = find.byKey(const ValueKey('resize-right'));
      await tester.drag(
        handle,
        Offset(size.width > 1000 ? 24 : 48, 0),
        kind: size.width > 1000
            ? ui.PointerDeviceKind.mouse
            : ui.PointerDeviceKind.touch,
      );
      await tester.pumpAndSettle();
      final stretch = state.editor.project.config.stretchX as double;
      expect(stretch, greaterThan(1));
      expect(state.editor.project.config.stretchY, closeTo(1, 1e-10));
      state.editor.undo();
      await tester.pumpAndSettle();
      expect(state.editor.project.config.stretchX, 1);
      state.editor.redo();
      await tester.pumpAndSettle();
      expect(state.editor.project.config.stretchX, stretch);
      await tester.tapAt(tester.getTopLeft(poster) + const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(state.selectedLayer, isNull);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('invalid margins stay inline and do not change the print plan', (
    tester,
  ) async {
    final dynamic state = await workspace(tester, const Size(1440, 940));
    await tester.ensureVisible(find.text('Margins'));
    await tester.tap(find.text('Margins'));
    await tester.pumpAndSettle();
    final field = find.widgetWithText(TextField, 'All margins (in)');
    await tester.ensureVisible(field);
    await tester.enterText(field, '9');
    await tester.pumpAndSettle();
    expect(state.editor.project.config.top, 6.35);
    expect(find.text('Margins must leave a printable area.'), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
    await tester.enterText(field, '0.5');
    await tester.pumpAndSettle();
    expect(state.editor.project.config.top, closeTo(12.7, 0.0001));
    expect(find.text('Margins must leave a printable area.'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  for (final size in [const Size(1440, 940), const Size(390, 844)]) {
    testWidgets(
      'Fit to grid fills entered 5 by 5 layout and supports undo at $size',
      (tester) async {
        final dynamic state = await workspace(tester, size);
        final recorder = ui.PictureRecorder();
        Canvas(recorder).drawRect(
          const Rect.fromLTWH(0, 0, 200, 100),
          Paint()..color = Colors.blue,
        );
        final picture = recorder.endRecording();
        state.editor.image = await picture.toImage(200, 100);
        picture.dispose();
        state.editor.update({'scale': 0.5, 'offsetX': 30.0, 'offsetY': 20.0});
        state.chooseLayer('image');
        await tester.pumpAndSettle();
        if (size.width < 1000) {
          await tester.tap(find.byTooltip('Print setup'));
          await tester.pumpAndSettle();
        }
        await tester.enterText(find.widgetWithText(TextField, 'Columns'), '5');
        await tester.pumpAndSettle();
        await tester.enterText(find.widgetWithText(TextField, 'Rows'), '5');
        await tester.pumpAndSettle();
        if (size.width < 1000) {
          await tester.tap(find.text('Done'));
          await tester.pumpAndSettle();
        }
        final button = find.text('Fit to grid');
        await tester.ensureVisible(button);
        await tester.tap(button);
        await tester.pumpAndSettle();
        void expectFilled() {
          final actual = ArtworkGeometry.bounds(state.editor.plan, 200, 100);
          expect(actual.x, closeTo(0, 1e-8));
          expect(actual.y, closeTo(0, 1e-8));
          expect(actual.width, closeTo(state.editor.plan.width, 1e-8));
          expect(actual.height, closeTo(state.editor.plan.height, 1e-8));
        }

        expectFilled();
        expect(state.editor.plan.tiles.length, 25);
        state.editor.undo();
        await tester.pumpAndSettle();
        expect(state.editor.project.config.scale, 0.5);
        expect(state.editor.project.config.offsetX, 30);
        state.editor.redo();
        await tester.pumpAndSettle();
        expectFilled();
        state.editor.update({'rows': 4});
        await tester.pumpAndSettle();
        await tester.tap(button);
        await tester.pumpAndSettle();
        expect(state.editor.plan.tiles.length, 20);
        expectFilled();
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('layout mode preserves the displayed poster dimensions', (
    tester,
  ) async {
    final dynamic state = await workspace(tester, const Size(1440, 940));
    final width = state.editor.plan.width as double;
    final height = state.editor.plan.height as double;
    await tester.tap(find.text('Physical size'));
    await tester.pumpAndSettle();
    expect(state.editor.plan.width, closeTo(width, 0.0001));
    expect(state.editor.plan.height, closeTo(height, 0.0001));
    await tester.tap(find.text('Grid'));
    await tester.pumpAndSettle();
    expect(state.editor.plan.tiles.length, 9);
    expect(tester.takeException(), isNull);
  });

  testWidgets('undo updates a focused print field to its restored value', (
    tester,
  ) async {
    final dynamic state = await workspace(tester, const Size(1440, 940));
    final columns = find.widgetWithText(TextField, 'Columns');
    await tester.enterText(columns, '4');
    await tester.pumpAndSettle();
    state.editor.undo();
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(columns).controller!.text, '3');
    expect(state.editor.plan.columns, 3);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'mobile print setup updates and keeps fields reachable with keyboard',
    (tester) async {
      final dynamic state = await workspace(tester, const Size(390, 844));
      await tester.tap(find.byTooltip('Print setup'));
      await tester.pumpAndSettle();
      final columns = find.widgetWithText(TextField, 'Columns');
      await tester.enterText(columns, '5');
      await tester.pumpAndSettle();
      expect(state.editor.plan.tiles.length, 15);
      expect(find.textContaining('15 printable sheets'), findsOneWidget);
      final capture = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(const ValueKey('workflow-capture')),
      );
      await tester.runAsync(() async {
        final image = await capture.toImage();
        final bytes = (await image.toByteData(
          format: ui.ImageByteFormat.png,
        ))!.buffer.asUint8List();
        image.dispose();
        await Directory('docs/previews').create(recursive: true);
        await File('docs/previews/print-setup-mobile.png').writeAsBytes(bytes);
      });
      tester.view.viewInsets = const FakeViewPadding(bottom: 320);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Paper'));
      await tester.tap(find.text('Landscape'));
      await tester.pumpAndSettle();
      expect(state.editor.project.config.landscape, isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  for (final size in [
    const Size(320, 568),
    const Size(390, 844),
    const Size(844, 390),
    const Size(1440, 940),
  ]) {
    for (final brightness in Brightness.values) {
      testWidgets('all print sections expand and reopen at $size $brightness', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        var config = const PrintConfig(overlapEnabled: true, autoDpi: false);
        await tester.pumpWidget(
          MaterialApp(
            theme: appTheme(brightness),
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 340,
                  child: StatefulBuilder(
                    builder: (context, change) {
                      return SingleChildScrollView(
                        child: ConfigurationInspector(
                          config: config,
                          onChange: (values) =>
                              change(() => config = config.change(values)),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        for (final title in [
          'Margins',
          'Overlap',
          'Cutting guides',
          'Page numbering',
          'Resolution',
          'Artwork',
          'View options',
        ]) {
          final header = find.text(title);
          await tester.ensureVisible(header);
          await tester.tap(header);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: 'Opening $title');
          await tester.ensureVisible(header);
          await tester.tap(header);
          await tester.pumpAndSettle();
          await tester.tap(header);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: 'Reopening $title');
        }
      });
    }
  }

  testWidgets('a margin preset clears an invalid draft of the same value', (
    tester,
  ) async {
    await workspace(tester, const Size(1440, 940));
    await tester.ensureVisible(find.text('Margins'));
    await tester.tap(find.text('Margins'));
    await tester.pumpAndSettle();
    final margins = find.widgetWithText(TextField, 'All margins (in)');
    await tester.ensureVisible(margins);
    await tester.enterText(margins, '9');
    await tester.pumpAndSettle();
    final preset = find.widgetWithText(ActionChip, '0.25 in');
    await tester.ensureVisible(preset);
    await tester.tap(preset);
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(margins).controller!.text, '0.25');
    expect(find.text('Margins must leave a printable area.'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('typing in print fields does not nudge or delete selected text', (
    tester,
  ) async {
    final dynamic state = await workspace(tester, const Size(1440, 940));
    state.editor.putText(const TextLayer(id: 'caption', text: 'Hello', x: 10));
    state.chooseLayer('caption');
    await tester.pumpAndSettle();
    final columns = find.widgetWithText(TextField, 'Columns');
    await tester.enterText(columns, '4');
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyEvent(LogicalKeyboardKey.delete);
    await tester.pumpAndSettle();
    expect(state.editor.project.config.texts.single.x, 10);
    expect(state.editor.project.config.texts.single.text, 'Hello');
    expect(tester.takeException(), isNull);
  });

  for (final unit in ['mm', 'cm']) {
    testWidgets('print margins use $unit consistently', (tester) async {
      final dynamic state = await workspace(
        tester,
        const Size(1440, 940),
        unit: unit,
      );
      await tester.ensureVisible(find.text('Margins'));
      await tester.tap(find.text('Margins'));
      await tester.pumpAndSettle();
      final field = find.widgetWithText(TextField, 'All margins ($unit)');
      await tester.ensureVisible(field);
      await tester.enterText(field, '2');
      await tester.pumpAndSettle();
      expect(state.editor.project.config.top, unit == 'mm' ? 2 : 20);
      expect(find.textContaining(' in'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('mobile object selection updates the open setup panel', (
    tester,
  ) async {
    final dynamic state = await workspace(tester, const Size(390, 844));
    state.editor.putText(const TextLayer(id: 'caption', text: 'Hello'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Print setup'));
    await tester.pumpAndSettle();
    final object = find.widgetWithText(ListTile, 'Hello');
    await tester.ensureVisible(object);
    await tester.tap(object);
    await tester.pumpAndSettle();
    expect(tester.widget<ListTile>(object).selected, isTrue);
    expect(state.selectedLayer, 'caption');
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Delete selected object'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('rejected paper choice restores the actual selected paper', (
    tester,
  ) async {
    final dynamic state = await workspace(
      tester,
      const Size(1440, 940),
      config: const PrintConfig(top: 80, right: 80, bottom: 80, left: 80),
    );
    final paper = find.ancestor(
      of: find.text('Paper size'),
      matching: find.byType(DropdownButtonFormField<String>),
    );
    await tester.ensureVisible(paper);
    await tester.tap(paper);
    await tester.pumpAndSettle();
    await tester.tap(find.text('A5').last);
    await tester.pumpAndSettle();
    expect(state.editor.project.config.paper, 'Short Bond');
    expect(tester.state<FormFieldState<String>>(paper).value, 'Short Bond');
    expect(find.text('Margins must leave a printable area.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final size in [const Size(320, 568), const Size(844, 390)]) {
    testWidgets('crop dialog fits small and landscape screens at $size', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final recorder = ui.PictureRecorder();
      Canvas(recorder).drawRect(
        const Rect.fromLTWH(0, 0, 100, 200),
        Paint()..color = Colors.blue,
      );
      final picture = recorder.endRecording();
      final image = await picture.toImage(100, 200);
      picture.dispose();
      addTearDown(image.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: appTheme(Brightness.light),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return TextButton(
                  onPressed: () =>
                      cropImage(context, image, const PrintConfig()),
                  child: const Text('Open crop'),
                );
              },
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open crop'));
      await tester.pumpAndSettle();
      expect(find.text('Apply crop'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
