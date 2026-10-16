import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdfrx/pdfrx.dart';
import 'app/desktop_frame.dart';
import 'app/app.dart';
import 'core/persistence/database.dart';
import 'features/projects/project_repository.dart';
import 'features/projects/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  pdfrxFlutterInitialize();
  try {
    final root = await getApplicationSupportDirectory();
    await root.create(recursive: true);
    final db = AppDatabase(File(p.join(root.path, 'zslice.sqlite')));
    await db.customSelect('SELECT 1').get();
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      await prepareDesktopWindow();
    }
    LicenseRegistry.addLicense(() async* {
      yield LicenseEntryWithLineBreaks([
        'Inter',
      ], await rootBundle.loadString('assets/fonts/OFL.txt'));
      yield const LicenseEntryWithLineBreaks(
        ['Solar Icon Set'],
        'Solar Icon Set by 480 Design. Licensed under Creative Commons Attribution 4.0 International (CC BY 4.0). '
        'https://creativecommons.org/licenses/by/4.0/\nhttps://www.figma.com/community/file/1166831539721848736',
      );
    });
    runApp(
      ProviderScope(
        overrides: [
          repositoryProvider.overrideWithValue(ProjectRepository(db, root)),
        ],
        child: const ZSliceApp(),
      ),
    );
  } catch (error, stack) {
    debugPrintStack(stackTrace: stack, label: error.toString());
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: SelectableText(
                'ZSlice could not start.\n$error\n\nYour saved projects have not been deleted.',
              ),
            ),
          ),
        ),
      ),
    );
  }
}
