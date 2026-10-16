part of 'editor_screen.dart';

mixin _EditorInspector on State<EditorWorkspace> {
  EditorController get editor;
  bool get exporting;
  Listenable get selectionChanges;
  int get page;
  set page(int value);
  void update(Map<String, dynamic> values);
  String? get selectedLayer;
  void chooseLayer(String? id);
  Future<void> editSelected();
  Future<void> presets() async {
    try {
      var stored = await widget.repository.preference('presets');
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, change) => AlertDialog(
            title: const Text('Layout presets'),
            content: SizedBox(
              width: 380,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (stored.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(20),
                        child: Text('Save this layout to use it again.'),
                      ),
                    for (final name in stored.keys.toList())
                      ListTile(
                        title: Text(name),
                        onTap: () {
                          try {
                            final config = PrintConfig.fromJson(
                              (stored[name] as Map).cast<String, dynamic>(),
                            );
                            SlicingPlan.create(config);
                            final settings = config.toJson()
                              ..removeWhere(
                                (key, _) => {
                                  'texts',
                                  'scale',
                                  'stretchX',
                                  'stretchY',
                                  'offsetX',
                                  'offsetY',
                                  'rotation',
                                  'cropLeft',
                                  'cropTop',
                                  'cropRight',
                                  'cropBottom',
                                }.contains(key),
                              );
                            editor.update(settings);
                            Navigator.pop(context);
                          } catch (e) {
                            showError(context, e);
                          }
                        },
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ToolButton(
                              label: 'Replace with current layout',
                              icon: AppIcons.save,
                              onPressed: () async {
                                try {
                                  stored[name] = editor.project.config.toJson();
                                  await widget.repository.setPreference(
                                    'presets',
                                    stored,
                                  );
                                  change(() {});
                                } catch (e) {
                                  if (context.mounted) showError(context, e);
                                }
                              },
                            ),
                            ToolButton(
                              label: 'Delete preset',
                              icon: AppIcons.delete,
                              onPressed: () async {
                                try {
                                  stored.remove(name);
                                  await widget.repository.setPreference(
                                    'presets',
                                    stored,
                                  );
                                  change(() {});
                                } catch (e) {
                                  if (context.mounted) showError(context, e);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
              FilledButton(
                onPressed: () async {
                  final name = await askName(
                    context,
                    'Save preset',
                    initial: 'My layout',
                  );
                  if (name == null) return;
                  try {
                    stored = {...stored, name: editor.project.config.toJson()};
                    await widget.repository.setPreference('presets', stored);
                    change(() {});
                  } catch (e) {
                    if (context.mounted) showError(context, e);
                  }
                },
                child: const Text('Save current'),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  Widget inspector() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Print setup',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                TextButton(onPressed: presets, child: const Text('Presets')),
              ],
            ),
            Text(
              'Choose your layout and paper. Preview sheets before printing.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      const Divider(),
      if (editor.project.source case final source?)
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                source.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 6),
              Text(
                '${source.width} × ${source.height} px${source.kind == 'pdf' ? ' · nominal 300 DPI' : ''}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (source.pageCount > 1) ...[
                const SizedBox(height: 16),
                SelectField(
                  label: 'Source PDF page',
                  value: '${source.page}',
                  options: {
                    for (var i = 1; i <= source.pageCount; i++)
                      '$i': 'Page $i of ${source.pageCount}',
                  },
                  onChanged: (v) async {
                    try {
                      await editor.sourcePage(int.parse(v));
                    } catch (e) {
                      if (mounted) showError(context, e);
                    }
                  },
                ),
              ],
            ],
          ),
        ),
      if (editor.hasContent || editor.project.source != null)
        InspectorSection(
          title: 'Objects',
          icon: AppIcons.layers,
          initiallyExpanded: true,
          children: [
            if (editor.project.source != null)
              ListTile(
                dense: true,
                leading: AppIcons.document,
                title: Text(
                  editor.image == null ? 'Image (unavailable)' : 'Image',
                ),
                selected: selectedLayer == 'image',
                onTap: () => chooseLayer('image'),
              ),
            for (final text in editor.project.config.texts.reversed)
              ListTile(
                dense: true,
                leading: AppIcons.text,
                title: Text(
                  text.text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                selected: selectedLayer == text.id,
                onTap: () => chooseLayer(text.id),
                trailing: ToolButton(
                  label: 'Edit text layer',
                  icon: AppIcons.edit,
                  onPressed: () {
                    chooseLayer(text.id);
                    editSelected();
                  },
                ),
              ),
          ],
        ),
      ConfigurationInspector(
        config: editor.project.config,
        unit: widget.preferences['unit'] as String? ?? 'in',
        onChange: (v) {
          update(v);
          page = page.clamp(0, editor.plan.tiles.length - 1);
        },
      ),
      const SizedBox(height: 20),
    ],
  );
  Future<void> openInspector() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (sheetContext) => AnimatedPadding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        child: SizedBox(
          height: MediaQuery.sizeOf(sheetContext).height * 0.85,
          child: Column(
            children: [
              Expanded(
                child: AnimatedBuilder(
                  animation: Listenable.merge([editor, selectionChanges]),
                  builder: (_, _) => SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.only(bottom: 24),
                    child: AbsorbPointer(
                      absorbing: editor.busy || exporting,
                      child: inspector(),
                    ),
                  ),
                ),
              ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    child: const Text('Done'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (mounted) setState(() {});
  }
}
