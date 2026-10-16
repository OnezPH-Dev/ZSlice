import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import '../projects/project.dart';
import '../projects/project_repository.dart';
import '../slicing/slicing_plan.dart';
import '../document_import/import_service.dart';
import '../document_import/source_loader.dart';
import '../slicing/text_layer.dart';

class EditorController extends ChangeNotifier {
  EditorController(this.project, this.repository, {this.autoSave = true}) {
    if (project.source != null) unawaited(loadImage());
  }
  SliceProject project;
  final ProjectRepository repository;
  final bool autoSave;
  final _undo = <SliceProject>[];
  final _redo = <SliceProject>[];
  Timer? _timer;
  Future<void> _saveQueue = Future.value();
  int _pendingSaves = 0;
  ui.Image? image;
  bool busy = false, dirty = false, saving = false, _disposed = false;
  Object? loadError, saveError;
  Object? get error => saveError ?? loadError;
  String? savedAt;
  bool get canUndo => _undo.isNotEmpty;
  bool get canRedo => _redo.isNotEmpty;
  SlicingPlan get plan => SlicingPlan.create(project.config);
  bool get hasContent => image != null || project.config.texts.isNotEmpty;
  bool get canExport =>
      hasContent && !busy && (project.source == null || image != null);
  void setTexts(List<TextLayer> texts) =>
      update({'texts': texts.map((t) => t.toJson()).toList()});
  void putText(TextLayer text) {
    final exists = project.config.texts.any((t) => t.id == text.id);
    setTexts([
      for (final t in project.config.texts)
        if (t.id == text.id) text else t,
      if (!exists) text,
    ]);
  }

  void deleteText(String id) =>
      setTexts(project.config.texts.where((t) => t.id != id).toList());
  void removeImage() {
    if (busy) return;
    _loadGeneration++;
    image?.dispose();
    image = null;
    loadError = null;
    _commit(project.copy(removeSource: true));
  }

  void update(Map<String, dynamic> changes) {
    final next = project.config.change(changes);
    SlicingPlan.create(next);
    if (jsonEncode(next.toJson()) == jsonEncode(project.config.toJson())) {
      return;
    }
    _commit(project.copy(config: next));
  }

  void rename(String name) => _commit(project.copy(name: name));

  void _commit(SliceProject next) {
    _undo.add(project);
    if (_undo.length > 100) _undo.removeAt(0);
    _redo.clear();
    project = next;
    _changed();
  }

  void _changed() {
    dirty = true;
    saveError = null;
    _timer?.cancel();
    if (autoSave) {
      _timer = Timer(
        const Duration(milliseconds: 600),
        () => unawaited(save()),
      );
    }
    _notify();
  }

  void undo() {
    if (!canUndo || busy) return;
    final oldSource = project.source;
    _redo.add(project);
    project = _undo.removeLast();
    _changed();
    if (oldSource != project.source) unawaited(loadImage());
  }

  void redo() {
    if (!canRedo || busy) return;
    final oldSource = project.source;
    _undo.add(project);
    project = _redo.removeLast();
    _changed();
    if (oldSource != project.source) unawaited(loadImage());
  }

  Future<void> save() {
    _timer?.cancel();
    final snapshot = project;
    _pendingSaves++;
    saving = true;
    _notify();
    _saveQueue = _saveQueue.then((_) async {
      try {
        await repository.save(snapshot);
        if (identical(project, snapshot)) dirty = false;
        savedAt = DateTime.now().toIso8601String();
        saveError = null;
      } catch (e) {
        saveError = e;
      } finally {
        _pendingSaves--;
        saving = _pendingSaves > 0;
        _notify();
      }
    });
    return _saveQueue;
  }

  Future<void> import(String path) async {
    if (busy) return;
    busy = true;
    loadError = null;
    _notify();
    try {
      final asset = await ImportService(repository).importFile(path);
      final loaded = await SourceLoader.load(asset);
      if (_disposed) {
        loaded.dispose();
        return;
      }
      image?.dispose();
      image = loaded;
      final next = project.copy(
        source: asset,
        config: project.config.change({
          'scale': 1.0,
          'stretchX': 1.0,
          'stretchY': 1.0,
          'offsetX': 0.0,
          'offsetY': 0.0,
          'rotation': 0,
          'cropLeft': 0.0,
          'cropTop': 0.0,
          'cropRight': 1.0,
          'cropBottom': 1.0,
        }),
      );
      _commit(next);
    } catch (e) {
      loadError = e;
      rethrow;
    } finally {
      busy = false;
      _notify();
    }
  }

  Future<void> sourcePage(int page) async {
    if (busy) return;
    final source = project.source;
    if (source == null || source.kind != 'pdf') return;
    if (source.page == page) return;
    busy = true;
    _notify();
    try {
      final asset = await ImportService(
        repository,
      ).pdfSource(source.path, source.name, page);
      final loaded = await SourceLoader.load(asset);
      if (_disposed) {
        loaded.dispose();
        return;
      }
      image?.dispose();
      image = loaded;
      loadError = null;
      _commit(project.copy(source: asset));
    } finally {
      busy = false;
      _notify();
    }
  }

  int _loadGeneration = 0;
  Future<void> loadImage() async {
    final generation = ++_loadGeneration;
    final source = project.source;
    if (source == null) {
      busy = false;
      loadError = null;
      image?.dispose();
      image = null;
      _notify();
      return;
    }
    busy = true;
    _notify();
    try {
      final loaded = await SourceLoader.load(source);
      if (_disposed || generation != _loadGeneration) {
        loaded.dispose();
        return;
      }
      image?.dispose();
      image = loaded;
      loadError = null;
    } catch (e) {
      loadError = e;
    } finally {
      if (generation == _loadGeneration) {
        busy = false;
        _notify();
      }
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    image?.dispose();
    super.dispose();
  }
}
