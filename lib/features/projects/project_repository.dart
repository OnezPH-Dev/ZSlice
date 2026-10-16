import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import '../../core/persistence/database.dart';
import '../slicing/slicing_plan.dart';
import 'project.dart';

class ProjectRepository {
  ProjectRepository(this.db, this.root);
  final AppDatabase db;
  final Directory root;

  Stream<List<SliceProject>> watch() =>
      (db.select(
        db.projects,
      )..orderBy([(t) => OrderingTerm.desc(t.modified)])).watch().map(
        (rows) => rows.map((r) => _decode(r.payload, r.backup)).toList(),
      );

  SliceProject _decode(String payload, String? backup) {
    try {
      final project = SliceProject.fromJson(
        jsonDecode(payload) as Map<String, dynamic>,
      );
      SlicingPlan.create(project.config);
      return project;
    } catch (_) {
      if (backup == null) rethrow;
      final project = SliceProject.fromJson(
        jsonDecode(backup) as Map<String, dynamic>,
      );
      SlicingPlan.create(project.config);
      return project;
    }
  }

  Future<SliceProject?> get(String id) async {
    final row = await (db.select(
      db.projects,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : _decode(row.payload, row.backup);
  }

  Future<void> save(SliceProject project) async {
    SlicingPlan.create(project.config);
    await db.transaction(() async {
      final old = await (db.select(
        db.projects,
      )..where((t) => t.id.equals(project.id))).getSingleOrNull();
      String? backup;
      if (old != null) {
        try {
          backup = jsonEncode(_decode(old.payload, old.backup).toJson());
        } catch (_) {
          backup = null;
        } // Never preserve corrupt data as a recovery snapshot.
      }
      await db
          .into(db.projects)
          .insertOnConflictUpdate(
            ProjectsCompanion.insert(
              id: project.id,
              payload: jsonEncode(project.toJson()),
              modified: project.modified,
              backup: Value(backup),
            ),
          );
    });
  }

  Future<void> delete(String id) async {
    // Managed source files may be shared by duplicated projects. Keep them until
    // reference-aware garbage collection; never delete a shared source here.
    await (db.delete(db.projects)..where((t) => t.id.equals(id))).go();
  }

  Future<Map<String, dynamic>> preference(String key) async {
    final row = await (db.select(
      db.preferences,
    )..where((t) => t.key.equals(key))).getSingleOrNull();
    return row == null ? {} : jsonDecode(row.value) as Map<String, dynamic>;
  }

  Future<void> setPreference(String key, Map<String, dynamic> value) => db
      .into(db.preferences)
      .insertOnConflictUpdate(
        PreferencesCompanion.insert(key: key, value: jsonEncode(value)),
      );

  Future<File> assetFile(String extension) async {
    final dir = await Directory(
      p.join(root.path, 'sources'),
    ).create(recursive: true);
    return File(
      p.join(dir.path, '${DateTime.now().microsecondsSinceEpoch}$extension'),
    );
  }
}
