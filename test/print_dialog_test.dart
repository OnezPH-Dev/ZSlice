import 'dart:async';
import 'dart:convert';
import 'dart:ffi' show DynamicLibrary;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/open.dart';
import 'package:zslice/app/theme/app_theme.dart';
import 'package:zslice/core/persistence/database.dart';
import 'package:zslice/features/export/export_dialog.dart';
import 'package:zslice/features/projects/project.dart';
import 'package:zslice/features/projects/project_repository.dart';
import 'package:zslice/features/projects/providers.dart';
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
  testWidgets(
    'native print receives PDF despite remembered image export format',
    (tester) async {
      final db = AppDatabase.memory();
      addTearDown(db.close);
      final repository = ProjectRepository(db, Directory.systemTemp);
      final container = ProviderContainer(
        overrides: [repositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      await tester.runAsync(() async {
        await repository.setPreference('app', {'exportFormat': 'png'});
        await container.read(preferencesProvider.future);
      });
      const channel = MethodChannel('net.nfet.printing');
      final messenger = tester.binding.defaultBinaryMessenger;
      Future<dynamic> fromNative(
        String method,
        Map<String, dynamic> args,
      ) async {
        final response = Completer<ByteData?>();
        tester.binding.channelBuffers.push(
          channel.name,
          channel.codec.encodeMethodCall(MethodCall(method, args)),
          response.complete,
        );
        return channel.codec.decodeEnvelope((await response.future)!);
      }

      Map<dynamic, dynamic>? sent;
      List<int>? printed;
      messenger.setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'printPdf') {
          sent = call.arguments as Map;
          printed =
              (await fromNative('onLayout', Map<String, dynamic>.from(sent!)))
                  as List<int>;
          await fromNative('onCompleted', {
            'job': sent!['job'],
            'completed': true,
          });
          return 1;
        }
        return null;
      });
      addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
      final project = SliceProject(
        id: 'print-dialog',
        name: 'Small poster',
        modified: DateTime(2026),
        config: const PrintConfig(
          rows: 1,
          columns: 1,
          paper: 'Custom',
          customWidth: 25.4,
          customHeight: 25.4,
          margins: false,
          autoDpi: false,
          dpi: 36,
          texts: [TextLayer(id: 'hello', text: 'Hello', width: 20)],
        ),
      );
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: appTheme(Brightness.light),
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () =>
                      showExportDialog(context, project, null, print: true),
                  child: const Text('Open print'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open print'));
      await tester.pumpAndSettle();
      expect(find.text('Print your poster'), findsOneWidget);
      final dynamic dialog = tester.state(find.byType(ExportDialog));
      expect(dialog.format, 'png');
      await tester.runAsync(() async => await dialog.run());
      await tester.pumpAndSettle();
      expect(sent!['name'], 'Small poster.pdf');
      expect(sent!['width'], closeTo(72, 0.001));
      expect(sent!['height'], closeTo(72, 0.001));
      expect(sent!['dynamic'], isFalse);
      expect(latin1.decode(printed!.take(8).toList()), startsWith('%PDF-1.4'));
      expect(find.byType(ExportDialog), findsNothing);
      expect(find.text('Print job sent.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
