import 'dart:convert';
import 'dart:ffi' show DynamicLibrary;
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:sqlite3/open.dart';
import 'package:zslice/core/persistence/database.dart';
import 'package:zslice/features/document_import/import_service.dart';
import 'package:zslice/features/editor/editor_controller.dart';
import 'package:zslice/features/projects/project.dart';
import 'package:zslice/features/projects/project_archive.dart';
import 'package:zslice/features/projects/project_repository.dart';
import 'package:zslice/features/slicing/text_layer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  if (Platform.isWindows) {
    open.overrideFor(
      OperatingSystem.windows,
      () => DynamicLibrary.open('winsqlite3.dll'),
    );
  }
  late Directory root;
  late AppDatabase db;
  late ProjectRepository repository;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('zslice-test-');
    db = AppDatabase.memory();
    repository = ProjectRepository(db, root);
  });
  tearDown(() async {
    await db.close();
    await root.delete(recursive: true);
  });
  Future<File> original() async {
    final file = File('${root.path}/original.png');
    final image = img.Image(width: 200, height: 300);
    img.fill(image, color: img.ColorRgb8(20, 100, 200));
    return file.writeAsBytes(img.encodePng(image));
  }

  test(
    'image import validates, copies, and creates thumbnail without altering original',
    () async {
      final file = await original();
      final bytes = await file.readAsBytes();
      final asset = await ImportService(repository).importFile(file.path);
      expect(asset.width, 200);
      expect(asset.height, 300);
      expect(asset.path, isNot(file.path));
      expect(await File(asset.path).readAsBytes(), bytes);
      expect(await file.readAsBytes(), bytes);
      expect(
        img.decodePng(await File(asset.thumbnail).readAsBytes()),
        isNotNull,
      );
    },
  );
  test('damaged images and unsupported files fail explicitly', () async {
    final broken = await File(
      '${root.path}/broken.png',
    ).writeAsString('not an image');
    await expectLater(
      ImportService(repository).importFile(broken.path),
      throwsFormatException,
    );
    final text = await File('${root.path}/notes.txt').writeAsString('hello');
    await expectLater(
      ImportService(repository).importFile(text.path),
      throwsFormatException,
    );
  });
  test(
    'invalid Word signatures are rejected before converter lookup',
    () async {
      final broken = await File(
        '${root.path}/broken.doc',
      ).writeAsString('not Word');
      await expectLater(
        ImportService(repository).importFile(broken.path),
        throwsFormatException,
      );
    },
  );
  test(
    'portable project restores managed source and settings under a new ID',
    () async {
      final file = await original();
      final source = await ImportService(repository).importFile(file.path);
      final project = SliceProject(
        id: 'original',
        name: 'Portable',
        modified: DateTime(2026),
        source: source.copyWith(path: 'source.png', thumbnail: ''),
      );
      final archive = Archive()
        ..addFile(
          ArchiveFile.string('project.json', jsonEncode(project.toJson())),
        )
        ..addFile(ArchiveFile.bytes('source.png', await file.readAsBytes()));
      final packed = await File(
        '${root.path}/project.zslice',
      ).writeAsBytes(ZipEncoder().encode(archive));
      final restored = await ProjectArchive.open(packed.path, repository);
      expect(restored.id, isNot('original'));
      expect(restored.config.toJson(), project.config.toJson());
      expect(restored.source!.name, source.name);
      expect(await File(restored.source!.path).exists(), isTrue);
      expect((await repository.get(restored.id))!.name, 'Portable');
    },
  );
  test(
    'editor snapshots undo, redo, serialize writes and validate before committing',
    () async {
      final project = SliceProject(
        id: 'editing',
        name: 'Original',
        modified: DateTime(2026),
      );
      final editor = EditorController(project, repository, autoSave: false);
      addTearDown(editor.dispose);
      editor.update({'columns': 4});
      editor.update({'rows': 5});
      expect(editor.plan.tiles.length, 20);
      editor.update({
        'rows': 5,
      }); // Submitting the same value must not add an undo step.
      expect(() => editor.update({'columns': 99}), throwsFormatException);
      expect(editor.plan.tiles.length, 20);
      editor.undo();
      expect(editor.plan.tiles.length, 12);
      editor.redo();
      expect(editor.plan.tiles.length, 20);
      final first = editor.save();
      editor.rename('Latest');
      final second = editor.save();
      await Future.wait([first, second]);
      expect((await repository.get('editing'))!.name, 'Latest');
      expect(editor.dirty, isFalse);
      expect(editor.error, isNull);
    },
  );
  test('missing source errors remain visible after saving settings', () async {
    final project = SliceProject(
      id: 'missing',
      name: 'Missing source',
      modified: DateTime(2026),
      source: const SourceAsset(
        path: 'does-not-exist.png',
        name: 'missing.png',
        kind: 'image',
        width: 10,
        height: 10,
        thumbnail: 'missing.png',
      ),
    );
    final editor = EditorController(project, repository, autoSave: false);
    addTearDown(editor.dispose);
    await editor.loadImage();
    expect(editor.loadError, isNotNull);
    editor.update({'rows': 2});
    await editor.save();
    expect(editor.loadError, isNotNull);
    expect(editor.saveError, isNull);
    editor.putText(const TextLayer(id: 'safe-text', text: 'A caption'));
    expect(editor.canExport, isFalse);
    editor.removeImage();
    expect(editor.project.source, isNull);
    expect(editor.canExport, isTrue);
    await editor.save();
    expect(
      (await repository.get('missing'))!.config.texts.single.text,
      'A caption',
    );
  });
}
