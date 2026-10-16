import 'dart:async';
import 'dart:math' as math;
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_theme.dart';
import '../../core/widgets/app_icons.dart';
import '../../core/widgets/dialogs.dart';
import '../export/export_dialog.dart';
import '../home/home_screen.dart';
import '../projects/project.dart';
import '../projects/project_archive.dart';
import '../projects/project_repository.dart';
import '../projects/providers.dart';
import '../slicing/print_config.dart';
import '../slicing/slicing_plan.dart';
import 'configuration_inspector.dart';
import 'editor_controller.dart';
import 'poster_renderer.dart';
import 'artwork_geometry.dart';
import 'interactive_poster.dart';
import 'crop_dialog.dart';
import 'text_editor_dialog.dart';
import '../slicing/text_layer.dart';

part 'editor_canvas.dart';
part 'editor_inspector.dart';
part 'editor_objects.dart';

class EditorScreen extends ConsumerWidget {
  const EditorScreen({super.key, required this.id, this.exportOnLoad = false});
  final String id;
  final bool exportOnLoad;
  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(projectProvider(id))
      .when(
        loading: () =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (e, _) => Scaffold(
          appBar: AppBar(title: const Text('Project error')),
          body: Center(child: Text('$e')),
        ),
        data: (project) => project == null
            ? Scaffold(
                appBar: AppBar(title: const Text('Project not found')),
                body: Center(
                  child: TextButton(
                    onPressed: () => context.go('/'),
                    child: const Text('Back to projects'),
                  ),
                ),
              )
            : EditorWorkspace(
                key: ValueKey(project.id),
                project: project,
                repository: ref.watch(repositoryProvider),
                preferences: ref.watch(preferencesProvider).value ?? {},
                exportOnLoad: exportOnLoad,
              ),
      );
}

class EditorWorkspace extends StatefulWidget {
  const EditorWorkspace({
    super.key,
    required this.project,
    required this.repository,
    required this.preferences,
    this.exportOnLoad = false,
  });
  final SliceProject project;
  final ProjectRepository repository;
  final Map<String, dynamic> preferences;
  final bool exportOnLoad;
  @override
  State<EditorWorkspace> createState() => _EditorWorkspaceState();
}

class _EditorWorkspaceState extends State<EditorWorkspace>
    with
        _EditorCanvas,
        _EditorInspector,
        _EditorObjects,
        WidgetsBindingObserver,
        WindowListener {
  @override
  late final EditorController editor;
  @override
  final viewport = TransformationController();
  @override
  bool select = false;
  @override
  bool preview = false;
  @override
  String? get selectedLayer => layerSelection.value;
  @override
  set selectedLayer(String? value) => layerSelection.value = value;
  final layerSelection = ValueNotifier<String?>(null);
  @override
  Listenable get selectionChanges => layerSelection;
  bool openedExport = false;
  @override
  bool exporting = false;
  bool get desktop => {
    TargetPlatform.windows,
    TargetPlatform.macOS,
    TargetPlatform.linux,
  }.contains(defaultTargetPlatform);
  @override
  int page = 0;
  @override
  void initState() {
    super.initState();
    editor = EditorController(
      widget.project,
      widget.repository,
      autoSave: widget.preferences['autosave'] != false,
    );
    editor.addListener(maybeExport);
    WidgetsBinding.instance.addObserver(this);
    if (desktop) {
      windowManager.addListener(this);
      unawaited(windowManager.setPreventClose(true));
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (editor.autoSave &&
        editor.dirty &&
        (state == AppLifecycleState.inactive ||
            state == AppLifecycleState.paused)) {
      unawaited(editor.save());
    }
  }

  @override
  void onWindowClose() async {
    if (editor.busy || exporting) {
      showError(
        context,
        const FormatException(
          'Finish importing, or finish/cancel the export before closing.',
        ),
      );
      return;
    }
    await editor.save();
    if (!mounted) return;
    if (editor.saveError != null) {
      showError(context, editor.saveError!);
      return;
    }
    await windowManager.destroy();
  }

  void maybeExport() {
    if (widget.exportOnLoad &&
        !openedExport &&
        editor.canExport &&
        !editor.busy) {
      openedExport = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) export();
      });
    }
  }

  @override
  void update(Map<String, dynamic> values) {
    try {
      editor.update(values);
      page = page.clamp(0, editor.plan.tiles.length - 1);
    } catch (e) {
      showError(context, e);
    }
  }

  @override
  Future<void> importFile([String? path]) async {
    try {
      path ??= (await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'pdf', 'doc', 'docx'],
      ))?.path;
      if (path != null) await editor.import(path);
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  Future<void> export({bool print = false}) async {
    if (!editor.canExport || exporting) return;
    setState(() => exporting = true);
    try {
      await showExportDialog(
        context,
        editor.project,
        editor.image,
        print: print,
      );
    } finally {
      if (mounted) setState(() => exporting = false);
    }
  }

  Future<void> leave() async {
    if (editor.busy || exporting) {
      showError(
        context,
        const FormatException(
          'Finish the current import or export before leaving.',
        ),
      );
      return;
    }
    await editor.save();
    if (!mounted) return;
    if (editor.saveError != null) {
      showError(context, editor.saveError!);
      return;
    }
    context.go('/');
  }

  void zoom(double factor) {
    final matrix = viewport.value.clone();
    final current = matrix.getMaxScaleOnAxis();
    final target = (current * factor).clamp(0.2, 8.0);
    matrix.scaleByDouble(target / current, target / current, 1, 1);
    viewport.value = matrix;
  }

  void resetView() => viewport.value = Matrix4.identity();
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: editor,
    builder: (context, _) {
      final c = editor.project.config;
      final plan = editor.plan;
      final unit = widget.preferences['unit'] as String? ?? 'in';
      final unitFactor = unit == 'in'
          ? 25.4
          : unit == 'cm'
          ? 10.0
          : 1.0;
      if (selectedLayer != null &&
          (selectedLayer == 'image'
              ? editor.project.source == null && editor.image == null
              : !c.texts.any((t) => t.id == selectedLayer))) {
        selectedLayer = null;
        select = false;
      }
      page = page.clamp(0, plan.tiles.length - 1);
      final wide =
          MediaQuery.sizeOf(context).width >= 1024 &&
          MediaQuery.sizeOf(context).height - (desktop ? 44 : 0) >= 620;
      final compact = MediaQuery.sizeOf(context).width < 900;
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) unawaited(leave());
        },
        child: CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.keyS, control: true): () =>
                unawaited(editor.save()),
            const SingleActivator(LogicalKeyboardKey.keyZ, control: true):
                editor.undo,
            const SingleActivator(
              LogicalKeyboardKey.keyZ,
              control: true,
              shift: true,
            ): editor.redo,
          },
          child: Focus(
            autofocus: true,
            onKeyEvent: (node, event) {
              if (event is! KeyDownEvent ||
                  editor.busy ||
                  exporting ||
                  preview ||
                  !(ModalRoute.of(context)?.isCurrent ?? true) ||
                  selectedLayer == null ||
                  FocusManager.instance.primaryFocus?.context
                          ?.findAncestorStateOfType<EditableTextState>() !=
                      null) {
                return KeyEventResult.ignored;
              }
              final step = HardwareKeyboard.instance.isShiftPressed
                  ? 10.0
                  : 1.0;
              if (event.logicalKey == LogicalKeyboardKey.delete) {
                deleteSelection();
              } else if (event.logicalKey == LogicalKeyboardKey.escape) {
                chooseLayer(null);
              } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                nudge(-step, 0);
              } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
                nudge(step, 0);
              } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                nudge(0, -step);
              } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                nudge(0, step);
              } else {
                return KeyEventResult.ignored;
              }
              return KeyEventResult.handled;
            },
            child: Scaffold(
              appBar: AppBar(
                automaticallyImplyLeading: false,
                leading: ToolButton(
                  label: 'Back to projects',
                  icon: AppIcons.back,
                  onPressed: editor.busy ? null : leave,
                ),
                titleSpacing: 0,
                title: Row(
                  children: [
                    if (!compact && !desktop) ...[
                      const Brand(compact: true),
                      const SizedBox(width: 24),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: () async {
                              final name = await askName(
                                context,
                                'Rename project',
                                initial: editor.project.name,
                              );
                              if (name != null) editor.rename(name);
                            },
                            child: Text(
                              editor.project.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ),
                          Text(
                            editor.error != null
                                ? 'Needs attention'
                                : editor.saving
                                ? 'Saving…'
                                : editor.dirty
                                ? 'Unsaved changes'
                                : 'All changes saved',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: editor.error != null
                                      ? Theme.of(context).colorScheme.error
                                      : Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                actions: [
                  if (!compact) ...[
                    ToolButton(
                      label: 'Undo',
                      icon: AppIcons.undo,
                      onPressed: editor.canUndo && !editor.busy
                          ? editor.undo
                          : null,
                    ),
                    ToolButton(
                      label: 'Redo',
                      icon: AppIcons.redo,
                      onPressed: editor.canRedo && !editor.busy
                          ? editor.redo
                          : null,
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: editor.busy ? null : importFile,
                      icon: AppIcons.importFile,
                      label: const Text('Import'),
                    ),
                    const SizedBox(width: 8),
                  ],
                  ToolButton(
                    label: preview ? 'Poster view' : 'Preview sheets',
                    icon: AppIcons.preview,
                    selected: preview,
                    onPressed: () {
                      setState(() {
                        preview = !preview;
                        select = !preview && selectedLayer != null;
                      });
                      resetView();
                    },
                  ),
                  if (!compact)
                    OutlinedButton.icon(
                      onPressed: editor.canExport && !exporting
                          ? () => export(print: true)
                          : null,
                      icon: AppIcons.print,
                      label: const Text('Print'),
                    ),
                  if (compact)
                    ToolButton(
                      label: 'Export',
                      icon: AppIcons.export,
                      onPressed: !editor.canExport || exporting ? null : export,
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: FilledButton.icon(
                        onPressed: !editor.canExport || exporting
                            ? null
                            : export,
                        icon: AppIcons.export,
                        label: const Text('Export'),
                      ),
                    ),
                  PopupMenuButton<String>(
                    icon: AppIcons.layers,
                    tooltip: 'Project menu',
                    onSelected: (action) async {
                      try {
                        switch (action) {
                          case 'save':
                            await editor.save();
                          case 'portable':
                            await ProjectArchive.save(editor.project);
                          case 'print':
                            await export(print: true);
                          case 'settings':
                            if (mounted) await context.push('/settings');
                          case 'undo':
                            editor.undo();
                          case 'redo':
                            editor.redo();
                        }
                      } catch (e) {
                        if (context.mounted) showError(context, e);
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'save',
                        child: Text('Save project'),
                      ),
                      const PopupMenuItem(
                        value: 'portable',
                        child: Text('Save portable .zslice'),
                      ),
                      PopupMenuItem(
                        value: 'print',
                        enabled: editor.canExport,
                        child: const Text('Print poster'),
                      ),
                      if (compact) ...[
                        const PopupMenuItem(value: 'undo', child: Text('Undo')),
                        const PopupMenuItem(value: 'redo', child: Text('Redo')),
                      ],
                      const PopupMenuItem(
                        value: 'settings',
                        child: Text('Settings'),
                      ),
                    ],
                  ),
                ],
              ),
              body: Column(
                children: [
                  const Divider(),
                  if (!preview) objectToolbar(),
                  if (editor.busy) const LinearProgressIndicator(),
                  if (editor.error != null)
                    MaterialBanner(
                      content: Text('${editor.error}'),
                      actions: [
                        TextButton(
                          onPressed: editor.loadImage,
                          child: const Text('Reload source'),
                        ),
                        TextButton(
                          onPressed: editor.save,
                          child: const Text('Retry save'),
                        ),
                      ],
                    ),
                  Expanded(
                    child: Row(
                      children: [
                        if (wide)
                          Container(
                            width: 68,
                            color: Theme.of(context).colorScheme.surface,
                            child: Column(
                              children: [
                                const SizedBox(height: 16),
                                ...toolbar(),
                                const Spacer(),
                                ToolButton(
                                  label: 'Save project',
                                  icon: AppIcons.save,
                                  onPressed: editor.save,
                                ),
                                const SizedBox(height: 16),
                              ],
                            ),
                          ),
                        Expanded(
                          child: Column(
                            children: [
                              if (preview)
                                Container(
                                  color: Theme.of(context).colorScheme.surface,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  child: Row(
                                    children: [
                                      const Expanded(
                                        child: Text(
                                          'Sheet preview',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      ToolButton(
                                        label: 'Previous sheet',
                                        icon: AppIcons.back,
                                        onPressed: page == 0
                                            ? null
                                            : () => setState(() => page--),
                                      ),
                                      SizedBox(
                                        width: 130,
                                        child: SelectField(
                                          label: 'Sheet',
                                          value: '$page',
                                          options: {
                                            for (final t in plan.tiles)
                                              '${t.index}':
                                                  '${t.index + 1} / ${plan.tiles.length}',
                                          },
                                          onChanged: (v) => setState(
                                            () => page = int.parse(v),
                                          ),
                                        ),
                                      ),
                                      ToolButton(
                                        label: 'Next sheet',
                                        icon: AppIcons.next,
                                        onPressed: page == plan.tiles.length - 1
                                            ? null
                                            : () => setState(() => page++),
                                      ),
                                    ],
                                  ),
                                ),
                              Expanded(child: canvas(plan)),
                              if (preview && editor.hasContent)
                                Container(
                                  height:
                                      MediaQuery.sizeOf(context).height < 560
                                      ? 72
                                      : 112,
                                  color: Theme.of(context).colorScheme.surface,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: plan.tiles.length,
                                    itemBuilder: (_, i) => InkWell(
                                      onTap: () => setState(() => page = i),
                                      child: Container(
                                        width: 80,
                                        margin: const EdgeInsets.all(10),
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: i == page
                                                ? Theme.of(
                                                    context,
                                                  ).colorScheme.primary
                                                : Theme.of(
                                                    context,
                                                  ).colorScheme.outlineVariant,
                                            width: i == page ? 2 : 1,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Column(
                                          children: [
                                            Expanded(
                                              child: AspectRatio(
                                                aspectRatio:
                                                    c.paperSize.$1 /
                                                    c.paperSize.$2,
                                                child: CustomPaint(
                                                  painter: PosterPainter(
                                                    plan,
                                                    editor.image,
                                                    tile: plan.tiles[i],
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Text(
                                              '${i + 1}',
                                              style: Theme.of(
                                                context,
                                              ).textTheme.labelSmall,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (wide)
                          SizedBox(
                            width: 340,
                            child: ColoredBox(
                              color: Theme.of(context).colorScheme.surface,
                              child: SingleChildScrollView(
                                child: AbsorbPointer(
                                  absorbing: editor.busy,
                                  child: inspector(),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    color: Theme.of(context).colorScheme.surface,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    child: Row(
                      children: [
                        if (!compact)
                          Expanded(
                            child: Text(
                              '${plan.columns} × ${plan.rows}  ·  ${plan.tiles.length} sheets  ·  ${c.paper}  ·  ${(plan.width / unitFactor).toStringAsFixed(2)} × ${(plan.height / unitFactor).toStringAsFixed(2)} $unit',
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ),
                        if (compact) const Spacer(),
                        ToolButton(
                          label: 'Zoom out',
                          icon: AppIcons.minus,
                          onPressed: () => zoom(1 / 1.2),
                        ),
                        ValueListenableBuilder<Matrix4>(
                          valueListenable: viewport,
                          builder: (_, matrix, _) => SizedBox(
                            width: 48,
                            child: Text(
                              '${(matrix.getMaxScaleOnAxis() * 100).round()}%',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ),
                        ),
                        ToolButton(
                          label: 'Zoom in',
                          icon: AppIcons.add,
                          onPressed: () => zoom(1.2),
                        ),
                        ToolButton(
                          label: 'Fit to screen',
                          icon: AppIcons.fit,
                          onPressed: resetView,
                        ),
                        if (!compact)
                          TextButton(
                            onPressed: () {
                              final scale = (96 / 25.4 / fitScale).clamp(
                                0.2,
                                8.0,
                              );
                              viewport.value = Matrix4.diagonal3Values(
                                scale,
                                scale,
                                1,
                              );
                            },
                            child: const Text('Actual size'),
                          ),
                      ],
                    ),
                  ),
                  if (!wide)
                    SafeArea(
                      top: false,
                      child: Row(
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(children: toolbar()),
                            ),
                          ),
                          ToolButton(
                            label: 'Print setup',
                            icon: AppIcons.settings,
                            onPressed: openInspector,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );

  List<Widget> toolbar() => [
    ToolButton(
      label: 'Add text',
      icon: AppIcons.text,
      onPressed: editor.busy || preview ? null : addText,
    ),
    ToolButton(
      label: 'Select / drag artwork',
      icon: AppIcons.select,
      selected: select,
      onPressed: preview
          ? null
          : () {
              if (select) {
                chooseLayer(null);
              } else {
                chooseLayer(editor.image != null ? 'image' : null);
              }
            },
    ),
    ToolButton(
      label: 'Import document',
      icon: AppIcons.importFile,
      onPressed: editor.busy ? null : importFile,
    ),
    ToolButton(
      label: 'Crop and transform',
      icon: AppIcons.crop,
      onPressed: editor.image == null
          ? null
          : () {
              chooseLayer('image');
              editSelected();
            },
    ),
    ToolButton(
      label: 'Fit artwork',
      icon: AppIcons.fit,
      onPressed: () => update({
        'scale': 1.0,
        'stretchX': 1.0,
        'stretchY': 1.0,
        'offsetX': 0.0,
        'offsetY': 0.0,
      }),
    ),
    ToolButton(
      label: 'Rotate artwork',
      icon: AppIcons.rotate,
      onPressed: () =>
          update({'rotation': (editor.project.config.rotation + 1) % 4}),
    ),
    ToolButton(
      label: 'Toggle grid',
      icon: AppIcons.grid,
      selected: editor.project.config.grid,
      onPressed: () => update({'grid': !editor.project.config.grid}),
    ),
    ToolButton(
      label: 'Toggle rulers',
      icon: AppIcons.ruler,
      selected: editor.project.config.rulers,
      onPressed: () => update({'rulers': !editor.project.config.rulers}),
    ),
  ];

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (desktop) {
      windowManager.removeListener(this);
      unawaited(windowManager.setPreventClose(false));
    }
    editor.removeListener(maybeExport);
    editor.dispose();
    layerSelection.dispose();
    viewport.dispose();
    super.dispose();
  }
}
