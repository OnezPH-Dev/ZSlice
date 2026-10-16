import 'dart:ffi' show DynamicLibrary;
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:zslice/app/desktop_frame.dart';
import 'package:zslice/features/slicing/text_layer.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqlite3/open.dart';
import 'package:zslice/app/theme/app_theme.dart';
import 'package:zslice/core/persistence/database.dart';
import 'package:zslice/features/home/home_screen.dart';
import 'package:zslice/features/editor/editor_screen.dart';
import 'package:zslice/features/projects/project.dart';
import 'package:zslice/features/projects/project_repository.dart';
import 'package:zslice/features/projects/providers.dart';
import 'package:zslice/features/slicing/print_config.dart';

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
  setUp(() {
    db = AppDatabase.memory();
    repository = ProjectRepository(db, Directory.systemTemp);
  });
  tearDown(() => db.close());
  setUpAll(() async {
    final loader = FontLoader('Inter')
      ..addFont(rootBundle.load('assets/fonts/Inter.ttf'));
    await loader.load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  Future<void> capture(WidgetTester tester, String name) async {
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const ValueKey('capture')),
    );
    await tester.runAsync(() async {
      final image = await boundary.toImage();
      final bytes = (await image.toByteData(
        format: ui.ImageByteFormat.png,
      ))!.buffer.asUint8List();
      image.dispose();
      await Directory('docs/previews').create(recursive: true);
      await File('docs/previews/$name.png').writeAsBytes(bytes);
    });
  }

  for (final size in [
    const Size(1440, 940),
    const Size(390, 844),
    const Size(800, 600),
    const Size(844, 390),
    const Size(320, 568),
    const Size(1100, 600),
  ]) {
    testWidgets('dashboard fits ${size.width}', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            repositoryProvider.overrideWithValue(repository),
            projectsProvider.overrideWith((ref) => Stream.value([])),
          ],
          child: RepaintBoundary(
            key: const ValueKey('capture'),
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: appTheme(Brightness.light),
              home: const HomeScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Big ideas. Any printer.'), findsOneWidget);
      expect(tester.takeException(), isNull);
      if (size.width != 800) {
        await capture(tester, 'dashboard-${size.width.toInt()}');
      }
    });
    testWidgets('editor fits ${size.width} and opens preview', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final project = SliceProject(
        id: 'test',
        name: 'Classroom poster',
        modified: DateTime(2026),
        config: const PrintConfig(),
      );
      await tester.pumpWidget(
        RepaintBoundary(
          key: const ValueKey('capture'),
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: appTheme(Brightness.light),
            home: EditorWorkspace(
              project: project,
              repository: repository,
              preferences: const {'autosave': false},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Make room for your big idea.'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip('Preview sheets'));
      await tester.pumpAndSettle();
      expect(find.text('Sheet preview'), findsOneWidget);
      expect(tester.takeException(), isNull);
      if (size.width == 390) {
        await tester.tap(find.byTooltip('Print setup'));
        await tester.pumpAndSettle();
        expect(find.text('Columns'), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('live grid validates counts and undo restores settings', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 940);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final project = SliceProject(
      id: 'test',
      name: 'Layout test',
      modified: DateTime(2026),
    );
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: appTheme(Brightness.light),
        home: EditorWorkspace(
          project: project,
          repository: repository,
          preferences: const {'autosave': false},
        ),
      ),
    );
    await tester.pumpAndSettle();
    final columns = find.widgetWithText(TextField, 'Columns');
    await tester.enterText(columns, '4');
    await tester.pumpAndSettle();
    expect(find.textContaining('12 printable sheets'), findsOneWidget);
    await tester.enterText(columns, '99');
    await tester.pumpAndSettle();
    expect(find.textContaining('12 printable sheets'), findsOneWidget);
    expect(find.text('Outside allowed range'), findsOneWidget);
    await tester.tap(find.byTooltip('Undo'));
    await tester.pumpAndSettle();
    expect(find.textContaining('9 printable sheets'), findsOneWidget);
  });
  testWidgets('artwork editor renders with light and dark themes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 940);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    const windowChannel = MethodChannel('window_manager');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      windowChannel,
      (call) async => call.method == 'isMaximized' ? false : null,
    );
    addTearDown(() {
      debugDefaultTargetPlatformOverride = null;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        windowChannel,
        null,
      );
    });
    final logo = File('assets/ZSlice Logo.png').absolute.path;
    final project = SliceProject(
      id: 'visual',
      name: 'ZSlice · brand poster',
      modified: DateTime(2026),
      source: SourceAsset(
        path: logo,
        name: 'ZSlice.png',
        kind: 'image',
        width: 1280,
        height: 1280,
        thumbnail: logo,
      ),
    );
    for (final brightness in [Brightness.light, Brightness.dark]) {
      await tester.pumpWidget(
        RepaintBoundary(
          key: const ValueKey('capture'),
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: appTheme(brightness),
            home: DesktopFrame(
              child: EditorWorkspace(
                key: ValueKey(brightness),
                project: project,
                repository: repository,
                preferences: const {'autosave': false},
              ),
            ),
          ),
        ),
      );
      await tester.runAsync(() async {
        final dynamic state = tester.state(find.byType(EditorWorkspace));
        await state.editor.loadImage();
        state.editor.putText(
          const TextLayer(
            id: 'visual-title',
            text: 'Create. Slice. Print.',
            x: 24,
            y: 24,
            width: 540,
            fontSize: 72,
            bold: true,
          ),
        );
        state.chooseLayer('image');
      });
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Make room for your big idea.'), findsNothing);
      expect(tester.takeException(), isNull);
      await capture(tester, 'editor-${brightness.name}');
    }
    await tester.pumpWidget(const SizedBox.shrink());
    debugDefaultTargetPlatformOverride = null;
  });
}
