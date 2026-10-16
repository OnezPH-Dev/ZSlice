import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/open.dart';
import 'package:zslice/core/persistence/database.dart';
import 'package:zslice/features/projects/project.dart';
import 'package:zslice/features/projects/project_repository.dart';
import 'package:zslice/features/slicing/print_config.dart';

void main() {
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
  test('project saves, restores, renames, duplicates and deletes', () async {
    final project = SliceProject(
      id: 'one',
      name: 'Poster',
      modified: DateTime(2026),
      config: const PrintConfig(
        rows: 4,
        columns: 5,
        overlapEnabled: true,
        top: 12.7,
        grid: false,
        stretchX: 1.5,
        stretchY: 0.75,
      ),
      source: const SourceAsset(
        path: 'managed.png',
        name: 'source.png',
        kind: 'image',
        width: 200,
        height: 300,
        thumbnail: 'thumb.png',
      ),
    );
    await repository.save(project);
    final restored = (await repository.get('one'))!;
    expect(restored.config.toJson(), project.config.toJson());
    expect(restored.source, project.source);
    await repository.save(restored.copy(name: 'Renamed'));
    await repository.save(restored.copy(id: 'two', name: 'Copy'));
    expect((await repository.watch().first).length, 2);
    await repository.delete('one');
    expect(await repository.get('one'), isNull);
    expect((await repository.get('two'))!.source, project.source);
  });
  test('previous snapshot recovers corrupt JSON', () async {
    final project = SliceProject(
      id: 'one',
      name: 'Good',
      modified: DateTime(2026),
    );
    await repository.save(project);
    await repository.save(project.copy(name: 'New'));
    await db.customStatement(
      "UPDATE projects SET payload = 'invalid' WHERE id = 'one'",
    );
    expect((await repository.get('one'))!.name, 'Good');
    final recovered = (await repository.get('one'))!;
    await repository.save(recovered.copy(name: 'Repaired'));
    await db.customStatement(
      "UPDATE projects SET payload = 'invalid-again' WHERE id = 'one'",
    );
    expect((await repository.get('one'))!.name, 'Good');
  });
  test('settings and presets are persistent independent records', () async {
    await repository.setPreference('app', {'theme': 'dark', 'unit': 'mm'});
    await repository.setPreference('presets', {
      'My preset': const PrintConfig().toJson(),
    });
    expect((await repository.preference('app'))['theme'], 'dark');
    expect(
      (await repository.preference('presets')).keys,
      contains('My preset'),
    );
  });
  test('project version and all settings round trip', () {
    final project = SliceProject(
      id: 'one',
      name: 'Poster',
      modified: DateTime(2026),
    );
    expect(
      SliceProject.fromJson(
        jsonDecode(jsonEncode(project.toJson())),
      ).config.toJson(),
      project.config.toJson(),
    );
    expect(
      () => SliceProject.fromJson({...project.toJson(), 'version': 99}),
      throwsFormatException,
    );
  });
}
