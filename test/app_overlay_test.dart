import 'dart:ffi' show DynamicLibrary;
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/open.dart';
import 'package:zslice/app/app.dart';
import 'package:zslice/core/persistence/database.dart';
import 'package:zslice/features/projects/project.dart';
import 'package:zslice/features/projects/project_repository.dart';
import 'package:zslice/features/projects/providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader(
      'Inter',
    )..addFont(rootBundle.load('assets/fonts/Inter.ttf'))).load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  if (Platform.isWindows) {
    open.overrideFor(
      OperatingSystem.windows,
      () => DynamicLibrary.open('winsqlite3.dll'),
    );
  }
  testWidgets('desktop chrome tooltips have an overlay across routed screens', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    tester.view.physicalSize = const Size(1440, 940);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const channel = MethodChannel('window_manager');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (call) async => call.method == 'isMaximized' ? false : null,
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        null,
      ),
    );
    final db = AppDatabase.memory();
    addTearDown(db.close);
    final repository = ProjectRepository(db, Directory.systemTemp);
    final container = ProviderContainer(
      overrides: [repositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    await tester.runAsync(() async {
      await repository.setPreference('app', {
        'theme': 'dark',
        'autosave': false,
      });
      await repository.save(
        SliceProject(
          id: 'overlay',
          name: 'Overlay test',
          modified: DateTime(2026),
        ),
      );
      await container.read(preferencesProvider.future);
    });
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const RepaintBoundary(
          key: ValueKey('app-capture'),
          child: ZSliceApp(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.runAsync(
      () => precacheImage(
        const AssetImage('assets/ZSlice Logo.png'),
        tester.element(find.byType(ZSliceApp)),
      ),
    );
    await tester.pumpAndSettle();
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const ValueKey('app-capture')),
    );
    await tester.runAsync(() async {
      final capture = await boundary.toImage();
      final bytes = (await capture.toByteData(
        format: ui.ImageByteFormat.png,
      ))!.buffer.asUint8List();
      capture.dispose();
      await Directory('docs/previews').create(recursive: true);
      await File('docs/previews/app-root-dark.png').writeAsBytes(bytes);
    });
    final pointer = await tester.createGesture(
      kind: ui.PointerDeviceKind.mouse,
    );
    await pointer.addPointer(location: Offset.zero);
    addTearDown(pointer.removePointer);
    for (final route in ['/', '/settings', '/editor/overlay', '/']) {
      container.read(routerProvider).go(route);
      await tester.pumpAndSettle();
      expect(find.text('ZSlice'), findsWidgets);
      for (final label in ['Minimize window', 'Close window']) {
        final control = find.byTooltip(label);
        expect(Overlay.maybeOf(tester.element(control)), isNotNull);
        await pointer.moveTo(tester.getCenter(control));
        await tester.pump(const Duration(seconds: 1));
        await tester.pumpAndSettle();
        expect(find.text(label), findsOneWidget);
        expect(tester.takeException(), isNull);
        await pointer.moveTo(Offset.zero);
        await tester.pump(const Duration(seconds: 1));
      }
    }
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    debugDefaultTargetPlatformOverride = null;
  });
}
