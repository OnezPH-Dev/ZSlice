import 'dart:convert';
import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;
import '../document_import/import_service.dart';
import '../export/save_output.dart';
import '../slicing/slicing_plan.dart';
import 'project.dart';
import 'project_repository.dart';

class ProjectArchive {
  static Future<bool> save(SliceProject project) async {
    final temp = await Directory.systemTemp.createTemp('zslice-project-');
    try {
      final output = File(p.join(temp.path, 'project.zslice'));
      final zip = ZipFileEncoder()..create(output.path);
      final json = project.toJson();
      if (project.source case final source?) {
        final filename = 'source${p.extension(source.path)}';
        await zip.addFile(File(source.path), filename);
        json['source'] = source
            .copyWith(path: filename, thumbnail: '')
            .toJson();
      }
      zip.addArchiveFile(ArchiveFile.string('project.json', jsonEncode(json)));
      await zip.close();
      return await saveOutput(
        output,
        '${safeName(project.name)}.zslice',
        'application/zip',
      );
    } finally {
      await temp.delete(recursive: true);
    }
  }

  static Future<SliceProject> open(
    String path,
    ProjectRepository repository,
  ) async {
    final file = File(path);
    if (await file.length() > 128 * 1024 * 1024) {
      throw const FormatException('Project file exceeds 128 MB.');
    }
    final archive = ZipDecoder().decodeBytes(
      await file.readAsBytes(),
      verify: true,
    );
    if (archive.files.fold<int>(0, (sum, f) => sum + f.size) >
        256 * 1024 * 1024) {
      throw const FormatException('Expanded project exceeds the memory limit.');
    }
    final metadata = archive.findFile('project.json');
    if (metadata == null || metadata.size > 1024 * 1024) {
      throw const FormatException('Invalid ZSlice project.');
    }
    var project = SliceProject.fromJson(
      jsonDecode(utf8.decode(metadata.content)) as Map<String, dynamic>,
    );
    SlicingPlan.create(project.config);
    if (project.source case final source?) {
      final data = archive.findFile(source.path);
      if (data == null) {
        throw const FormatException('Project source is missing.');
      }
      final temp = await Directory.systemTemp.createTemp('zslice-open-');
      try {
        // Never extract arbitrary archive paths. Only write a fixed basename.
        final input = File(
          p.join(temp.path, 'source${p.extension(source.path)}'),
        );
        await input.writeAsBytes(data.content);
        final asset = await ImportService(
          repository,
        ).importFile(input.path, page: source.page);
        project = project.copy(source: asset.copyWith(name: source.name));
      } finally {
        await temp.delete(recursive: true);
      }
    }
    project = project.copy(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
    );
    await repository.save(project);
    return project;
  }
}

String safeName(String name) => name.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
