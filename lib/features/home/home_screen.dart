import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/widgets/app_icons.dart';
import '../../core/widgets/dialogs.dart';
import '../document_import/import_service.dart';
import '../projects/project.dart';
import '../projects/providers.dart';
import '../projects/project_archive.dart';
import '../slicing/print_config.dart';
import '../slicing/slicing_plan.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool busy = false;
  String query = '';
  Future<void> create({bool import = false}) async {
    final name = import
        ? 'Untitled poster'
        : await askName(
            context,
            'Create a project',
            initial: 'Untitled poster',
          );
    if (name == null || !mounted) return;
    setState(() => busy = true);
    try {
      final repository = ref.read(repositoryProvider);
      final prefs = ref.read(preferencesProvider).value ?? {};
      var project = SliceProject(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: name,
        modified: DateTime.now(),
        config: PrintConfig.fromJson(
          (prefs['defaults'] as Map?)?.cast<String, dynamic>() ?? {},
        ),
      );
      if (import) {
        final file = await FilePicker.pickFile(
          type: FileType.custom,
          allowedExtensions: [
            'jpg',
            'jpeg',
            'png',
            'webp',
            'pdf',
            'doc',
            'docx',
          ],
        );
        if (file?.path == null) return;
        final source = await ImportService(repository).importFile(file!.path!);
        project = project.copy(
          source: source,
          name: file.name.replaceFirst(RegExp(r'\.[^.]+$'), ''),
        );
      }
      await repository.save(project);
      if (mounted) context.go('/editor/${project.id}');
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> open() async {
    setState(() => busy = true);
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['zslice'],
      );
      if (file?.path == null) return;
      final project = await ProjectArchive.open(
        file!.path!,
        ref.read(repositoryProvider),
      );
      if (mounted) context.go('/editor/${project.id}');
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> action(String action, SliceProject project) async {
    try {
      final repository = ref.read(repositoryProvider);
      switch (action) {
        case 'rename':
          final name = await askName(
            context,
            'Rename project',
            initial: project.name,
          );
          if (name != null) await repository.save(project.copy(name: name));
        case 'duplicate':
          await repository.save(
            project.copy(
              id: DateTime.now().microsecondsSinceEpoch.toString(),
              name: '${project.name} copy',
            ),
          );
        case 'delete':
          if (await confirmDelete(context, project.name)) {
            await repository.delete(project.id);
          }
        case 'save':
          await ProjectArchive.save(project);
        case 'export':
          if (mounted) context.go('/editor/${project.id}?export=1');
      }
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Brand(compact: MediaQuery.sizeOf(context).width < 360),
        actions: [
          ToolButton(
            label: 'Switch theme',
            icon: theme.brightness == Brightness.dark
                ? AppIcons.sun
                : AppIcons.moon,
            onPressed: () async {
              try {
                await ref.read(preferencesProvider.notifier).setValues({
                  'theme': theme.brightness == Brightness.dark
                      ? 'light'
                      : 'dark',
                });
              } catch (e) {
                if (context.mounted) showError(context, e);
              }
            },
          ),
          ToolButton(
            label: 'Settings',
            icon: AppIcons.settings,
            onPressed: () => context.push('/settings'),
          ),
          const SizedBox(width: 20),
        ],
      ),
      body: Stack(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final wide =
                  constraints.maxWidth > 900 && constraints.maxHeight >= 600;
              return Row(
                children: [
                  if (wide)
                    SizedBox(
                      width: 224,
                      child: ColoredBox(
                        color: theme.colorScheme.surface,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(height: 24),
                              Text(
                                'WORKSPACE',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  letterSpacing: 1.6,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ListTile(
                                leading: AppIcons.grid,
                                title: const Text('My projects'),
                                selected: true,
                                selectedTileColor: theme
                                    .colorScheme
                                    .primaryContainer
                                    .withValues(alpha: 0.5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                onTap: () => setState(() => query = ''),
                              ),
                              ListTile(
                                leading: AppIcons.open,
                                title: const Text('Open project'),
                                onTap: busy ? null : open,
                              ),
                              ListTile(
                                leading: AppIcons.settings,
                                title: const Text('Settings'),
                                onTap: () => context.push('/settings'),
                              ),
                              const Spacer(),
                              const Divider(),
                              const SizedBox(height: 20),
                              const Text(
                                'Made for your big ideas.',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Offline. Private. Ready to print.',
                                style: theme.textTheme.bodySmall,
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                'ZSlice by OnezPH',
                                style: TextStyle(fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(wide ? 40 : 20),
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1200),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'YOUR CREATIVE WORKSPACE',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                  letterSpacing: 2,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Big ideas. Any printer.',
                                style: theme.textTheme.headlineLarge,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Turn a document into a wall-worthy poster, one sheet at a time.',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 32),
                              Container(
                                padding: EdgeInsets.all(wide ? 32 : 24),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xff3431a1),
                                      Color(0xff4f46e5),
                                      Color(0xff187bac),
                                    ],
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Create. Slice. Print.',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 28,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: -0.8,
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          const Text(
                                            'Your next great poster starts here.\nChoose your paper. Set your grid. Make it yours.',
                                            style: TextStyle(
                                              color: Color(0xffe0e7ff),
                                              height: 1.6,
                                            ),
                                          ),
                                          const SizedBox(height: 24),
                                          Wrap(
                                            spacing: 12,
                                            runSpacing: 12,
                                            children: [
                                              FilledButton.icon(
                                                style: FilledButton.styleFrom(
                                                  backgroundColor: Colors.white,
                                                  foregroundColor: const Color(
                                                    0xff4338ca,
                                                  ),
                                                ),
                                                onPressed: busy ? null : create,
                                                icon: AppIcons.add,
                                                label: const Text(
                                                  'New project',
                                                ),
                                              ),
                                              OutlinedButton.icon(
                                                style: OutlinedButton.styleFrom(
                                                  foregroundColor: Colors.white,
                                                  side: const BorderSide(
                                                    color: Color(0xffa5b4fc),
                                                  ),
                                                ),
                                                onPressed: busy
                                                    ? null
                                                    : () =>
                                                          create(import: true),
                                                icon: AppIcons.importFile,
                                                label: const Text(
                                                  'Import document',
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (constraints.maxWidth > 1100)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          left: 24,
                                        ),
                                        child: Image.asset(
                                          'assets/ZSlice Logo.png',
                                          width: 180,
                                          height: 180,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 36),
                              Wrap(
                                alignment: WrapAlignment.spaceBetween,
                                spacing: 24,
                                runSpacing: 16,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    'Recent projects',
                                    style: theme.textTheme.headlineSmall,
                                  ),
                                  SizedBox(
                                    width: 240,
                                    child: TextField(
                                      onChanged: (value) =>
                                          setState(() => query = value),
                                      decoration: const InputDecoration(
                                        hintText: 'Search your projects',
                                      ),
                                    ),
                                  ),
                                  TextButton.icon(
                                    onPressed: busy ? null : open,
                                    icon: AppIcons.open,
                                    label: const Text('Open .zslice'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              ref
                                  .watch(projectsProvider)
                                  .when(
                                    loading: () => const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                    error: (error, _) => Card(
                                      child: Padding(
                                        padding: const EdgeInsets.all(24),
                                        child: Text(
                                          'Projects could not be loaded: $error',
                                        ),
                                      ),
                                    ),
                                    data: (projects) {
                                      final filtered = projects
                                          .where(
                                            (p) => p.name
                                                .toLowerCase()
                                                .contains(query.toLowerCase()),
                                          )
                                          .toList();
                                      if (filtered.isEmpty) {
                                        return Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(40),
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: theme
                                                  .colorScheme
                                                  .outlineVariant,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                          ),
                                          child: Column(
                                            children: [
                                              IconTheme(
                                                data: IconThemeData(
                                                  size: 48,
                                                  color:
                                                      theme.colorScheme.primary,
                                                ),
                                                child: AppIcons.document,
                                              ),
                                              const SizedBox(height: 16),
                                              Text(
                                                query.isEmpty
                                                    ? 'A blank page. Endless possibilities.'
                                                    : 'No matching projects',
                                                style:
                                                    theme.textTheme.titleMedium,
                                              ),
                                              const SizedBox(height: 8),
                                              const Text(
                                                'Your saved projects will appear here.',
                                              ),
                                              const SizedBox(height: 20),
                                              FilledButton(
                                                onPressed: busy ? null : create,
                                                child: const Text(
                                                  'Create a project',
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }
                                      return LayoutBuilder(
                                        builder: (context, grid) => GridView.builder(
                                          shrinkWrap: true,
                                          physics:
                                              const NeverScrollableScrollPhysics(),
                                          itemCount: filtered.length,
                                          gridDelegate:
                                              SliverGridDelegateWithFixedCrossAxisCount(
                                                crossAxisCount:
                                                    (grid.maxWidth / 270)
                                                        .floor()
                                                        .clamp(1, 4),
                                                mainAxisExtent: 284,
                                                crossAxisSpacing: 20,
                                                mainAxisSpacing: 20,
                                              ),
                                          itemBuilder: (context, i) =>
                                              ProjectCard(
                                                project: filtered[i],
                                                onOpen: () => context.go(
                                                  '/editor/${filtered[i].id}',
                                                ),
                                                onAction: (a) =>
                                                    action(a, filtered[i]),
                                              ),
                                        ),
                                      );
                                    },
                                  ),
                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          if (busy)
            const Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: LinearProgressIndicator(),
            ),
        ],
      ),
    );
  }
}

class Brand extends StatelessWidget {
  const Brand({super.key, this.compact = false});
  final bool compact;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.asset('assets/ZSlice Logo.png', width: 42, height: 42),
      ),
      const SizedBox(width: 8),
      const Text(
        'ZSlice',
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 23,
          letterSpacing: -0.8,
        ),
      ),
      if (!compact) ...[
        const SizedBox(width: 10),
        Text('by OnezPH', style: Theme.of(context).textTheme.labelSmall),
      ],
    ],
  );
}

class ProjectCard extends StatelessWidget {
  const ProjectCard({
    super.key,
    required this.project,
    required this.onOpen,
    required this.onAction,
  });
  final SliceProject project;
  final VoidCallback onOpen;
  final ValueChanged<String> onAction;
  @override
  Widget build(BuildContext context) {
    final plan = SlicingPlan.create(project.config);
    final date = project.modified.toLocal();
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onOpen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                color: Theme.of(
                  context,
                ).colorScheme.primaryContainer.withValues(alpha: 0.25),
                padding: const EdgeInsets.all(20),
                child: project.source == null
                    ? const Center(child: AppIcons.document)
                    : Image.file(
                        File(project.source!.thumbnail),
                        fit: BoxFit.contain,
                        cacheWidth: 480,
                        errorBuilder: (_, _, _) =>
                            const Center(child: AppIcons.document),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      project.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  PopupMenuButton<String>(
                    tooltip: 'Project actions',
                    icon: AppIcons.layers,
                    onSelected: onAction,
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'rename',
                        child: Text('Rename'),
                      ),
                      const PopupMenuItem(
                        value: 'duplicate',
                        child: Text('Duplicate'),
                      ),
                      const PopupMenuItem(
                        value: 'save',
                        child: Text('Save portable project'),
                      ),
                      const PopupMenuItem(
                        value: 'export',
                        child: Text('Export poster'),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${project.config.paper}  ·  ${plan.columns} × ${plan.rows}  ·  ${plan.tiles.length} sheets',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Edited ${date.month}/${date.day}/${date.year}',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
