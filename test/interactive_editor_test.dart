import 'dart:ffi' show DynamicLibrary;
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/open.dart';
import 'package:zslice/app/desktop_frame.dart';
import 'package:zslice/app/theme/app_theme.dart';
import 'package:zslice/core/persistence/database.dart';
import 'package:zslice/features/editor/crop_dialog.dart';
import 'package:zslice/features/editor/artwork_geometry.dart';
import 'package:zslice/features/editor/editor_screen.dart';
import 'package:zslice/features/editor/interactive_poster.dart';
import 'package:zslice/features/projects/project.dart';
import 'package:zslice/features/projects/project_repository.dart';
import 'package:zslice/features/slicing/print_config.dart';
import 'package:zslice/features/slicing/slicing_plan.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  if (Platform.isWindows) {
    open.overrideFor(
      OperatingSystem.windows,
      () => DynamicLibrary.open('winsqlite3.dll'),
    );
  }
  late ui.Image image;
  setUpAll(() async {
    final font = FontLoader('Inter')
      ..addFont(rootBundle.load('assets/fonts/Inter.ttf'));
    await font.load();
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, 200, 100),
      Paint()..color = Colors.blue,
    );
    final picture = recorder.endRecording();
    image = await picture.toImage(200, 100);
    picture.dispose();
  });
  tearDownAll(() => image.dispose());
  const config = PrintConfig(
    rows: 1,
    columns: 1,
    paper: 'Custom',
    customWidth: 100,
    customHeight: 100,
    margins: false,
    snap: false,
    lines: false,
    scissors: false,
    numbering: false,
  );
  for (final zoom in [1.0, 2.0]) {
    testWidgets('click selects actual image and handles resize at zoom $zoom', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1920, 1440);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var current = config;
      String? selection;
      var commits = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: StatefulBuilder(
                builder: (context, change) => Transform.scale(
                  scale: zoom,
                  child: SizedBox(
                    width: 400,
                    height: 400,
                    child: InteractivePoster(
                      plan: SlicingPlan.create(current),
                      image: image,
                      pixelsPerMm: 4,
                      viewportScale: () => zoom,
                      selection: selection,
                      onSelection: (id) => change(() => selection = id),
                      onCommit: (v) => change(() {
                        current = current.change(v);
                        commits++;
                      }),
                      onPanCanvas: (_) {},
                      onEdit: () {},
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tapAt(tester.getCenter(find.byType(InteractivePoster)));
      await tester.pumpAndSettle();
      expect(selection, 'image');
      final handle = find.byKey(const ValueKey('resize-bottom-right'));
      expect(handle, findsOneWidget);
      await tester.drag(handle, Offset(40 * zoom, 20 * zoom));
      await tester.pumpAndSettle();
      expect(current.scale, closeTo(1.1, 0.015));
      expect(commits, 1);
      final before = current.offsetX;
      await tester.dragFrom(
        tester.getCenter(find.byType(InteractivePoster)),
        Offset(20 * zoom, 0),
      );
      await tester.pumpAndSettle();
      expect(current.offsetX, closeTo(before + 5, 0.1));
      expect(commits, 2);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets(
    'crop corner resizes non-destructively and Apply returns normalized crop',
    (tester) async {
      tester.view.physicalSize = const Size(1000, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      Map<String, dynamic>? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  result = await cropImage(context, image, config);
                },
                child: const Text('Open crop'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open crop'));
      await tester.pumpAndSettle();
      final surface = find.byKey(const ValueKey('crop-surface'));
      final rect = tester.getRect(surface);
      await tester.dragFrom(
        rect.bottomRight - const Offset(8, 8),
        Offset(-rect.width * 0.25, -rect.height * 0.25),
      );
      await tester.pump();
      await tester.tap(find.text('Apply crop'));
      await tester.pumpAndSettle();
      expect(result!['cropLeft'], 0);
      expect(result!['cropTop'], 0);
      expect(result!['cropRight'], inInclusiveRange(0.7, 0.8));
      expect(result!['cropBottom'], inInclusiveRange(0.7, 0.8));
    },
  );
  for (final zoom in [1.0, 2.0]) {
    for (final edge in ['left', 'right', 'top', 'bottom']) {
      testWidgets('image $edge handle resizes one axis at zoom $zoom', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(1920, 1440);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        var current = config.change({'scale': 0.5});
        final original = ArtworkGeometry.bounds(
          SlicingPlan.create(current),
          image.width,
          image.height,
        );
        var commits = 0;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: StatefulBuilder(
                  builder: (context, change) => Transform.scale(
                    scale: zoom,
                    child: SizedBox(
                      width: 400,
                      height: 400,
                      child: InteractivePoster(
                        plan: SlicingPlan.create(current),
                        image: image,
                        pixelsPerMm: 4,
                        viewportScale: () => zoom,
                        selection: 'image',
                        onSelection: (_) {},
                        onCommit: (v) => change(() {
                          current = current.change(v);
                          commits++;
                        }),
                        onPanCanvas: (_) {},
                        onEdit: () {},
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final horizontal = edge == 'left' || edge == 'right';
        final leading = edge == 'left' || edge == 'top';
        await tester.drag(
          find.byKey(ValueKey('resize-$edge')),
          horizontal
              ? Offset((leading ? -40 : 40) * zoom, 0)
              : Offset(0, (leading ? -40 : 40) * zoom),
        );
        await tester.pumpAndSettle();
        final actual = ArtworkGeometry.bounds(
          SlicingPlan.create(current),
          image.width,
          image.height,
        );
        expect(
          actual.width,
          closeTo(original.width + (horizontal ? 10 : 0), 0.1),
        );
        expect(
          actual.height,
          closeTo(original.height + (horizontal ? 0 : 10), 0.1),
        );
        expect(
          leading && horizontal ? actual.right : actual.x,
          closeTo(leading && horizontal ? original.right : original.x, 0.1),
        );
        expect(
          leading && !horizontal ? actual.bottom : actual.y,
          closeTo(leading && !horizontal ? original.bottom : original.y, 0.1),
        );
        expect(commits, 1);
        expect(tester.takeException(), isNull);
      });
    }
  }
  testWidgets('two-finger pinch zoom remains available over selected artwork', (
    tester,
  ) async {
    final viewport = TransformationController();
    addTearDown(viewport.dispose);
    var commits = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: InteractiveViewer(
            transformationController: viewport,
            minScale: 0.2,
            maxScale: 8,
            boundaryMargin: const EdgeInsets.all(500),
            child: Center(
              child: SizedBox(
                width: 400,
                height: 400,
                child: InteractivePoster(
                  plan: SlicingPlan.create(config),
                  image: image,
                  pixelsPerMm: 4,
                  viewportScale: () => viewport.value.getMaxScaleOnAxis(),
                  selection: 'image',
                  onSelection: (_) {},
                  onCommit: (_) => commits++,
                  onPanCanvas: (_) {},
                  onEdit: () {},
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final center = tester.getCenter(find.byType(InteractivePoster));
    final left = await tester.startGesture(
      center - const Offset(40, 0),
      pointer: 1,
    );
    final right = await tester.startGesture(
      center + const Offset(40, 0),
      pointer: 2,
    );
    await tester.pump();
    await left.moveBy(const Offset(-40, 0));
    await right.moveBy(const Offset(40, 0));
    await tester.pump();
    await left.up();
    await right.up();
    await tester.pumpAndSettle();
    expect(viewport.value.getMaxScaleOnAxis(), greaterThan(1.2));
    expect(commits, 0);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  for (final size in [
    const Size(1440, 940),
    const Size(390, 844),
    const Size(844, 390),
    const Size(320, 568),
  ]) {
    testWidgets(
      'add text to blank poster, duplicate, delete, and undo at ${size.width}',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final db = AppDatabase.memory();
        final repo = ProjectRepository(db, Directory.systemTemp);
        addTearDown(db.close);
        await tester.pumpWidget(
          MaterialApp(
            theme: appTheme(Brightness.light),
            home: EditorWorkspace(
              project: SliceProject(
                id: 'text-test',
                name: 'Text poster',
                modified: DateTime(2026),
                config: config,
              ),
              repository: repo,
              preferences: const {'autosave': false},
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Add text'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const ValueKey('text-content')),
          'Classroom poster',
        );
        await tester.tap(find.text('Apply text'));
        await tester.pumpAndSettle();
        final dynamic state = tester.state(find.byType(EditorWorkspace));
        expect(
          state.editor.project.config.texts.single.text,
          'Classroom poster',
        );
        expect(state.editor.hasContent, isTrue);
        await tester.ensureVisible(find.byTooltip('Duplicate text'));
        await tester.tap(find.byTooltip('Duplicate text'));
        await tester.pumpAndSettle();
        expect(state.editor.project.config.texts.length, 2);
        await tester.ensureVisible(find.byTooltip('Delete selected object'));
        await tester.tap(find.byTooltip('Delete selected object'));
        await tester.pumpAndSettle();
        expect(state.editor.project.config.texts.length, 1);
        state.editor.undo();
        await tester.pumpAndSettle();
        expect(state.editor.project.config.texts.length, 2);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'custom desktop controls offer minimize and close without maximize',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      final calls = <String>[];
      const channel = MethodChannel('window_manager');
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        calls.add(call.method);
        return null;
      });
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          null,
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: DesktopFrame(child: const Scaffold(body: Text('Workspace'))),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Minimize window'));
      await tester.pumpAndSettle();
      expect(calls, contains('minimize'));
      expect(find.byTooltip('Maximize window'), findsNothing);
      expect(find.byTooltip('Restore window'), findsNothing);
      await tester.tap(find.byTooltip('Close window'));
      await tester.pumpAndSettle();
      expect(calls, contains('close'));
      await tester.pumpWidget(const SizedBox.shrink());
      debugDefaultTargetPlatformOverride = null;
    },
  );
  testWidgets('desktop startup maximizes before showing the window', (
    tester,
  ) async {
    final calls = <String>[];
    const channel = MethodChannel('window_manager');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      call,
    ) async {
      calls.add(call.method);
      if (call.method == 'isFullScreen' ||
          call.method == 'isMaximized' ||
          call.method == 'isMinimized') {
        return false;
      }
      return null;
    });
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        null,
      ),
    );
    await prepareDesktopWindow();
    expect(calls.indexOf('maximize'), greaterThanOrEqualTo(0));
    expect(calls.indexOf('show'), greaterThan(calls.indexOf('maximize')));
    expect(calls.last, 'focus');
  });
}
