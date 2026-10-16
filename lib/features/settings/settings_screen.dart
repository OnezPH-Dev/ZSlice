import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/widgets/app_icons.dart';
import '../../core/widgets/dialogs.dart';
import '../editor/configuration_inspector.dart';
import '../projects/providers.dart';
import '../slicing/print_config.dart';
import '../slicing/slicing_plan.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(preferencesProvider);
    final prefs = async.value ?? {};
    final defaults = PrintConfig.fromJson(
      (prefs['defaults'] as Map?)?.cast<String, dynamic>() ?? {},
    );
    Future<void> update(Map<String, dynamic> values) async {
      try {
        await ref.read(preferencesProvider.notifier).setValues(values);
      } catch (e) {
        if (context.mounted) showError(context, e);
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: async.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Make yourself at home.',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      const Text('Preferences are saved on this device.'),
                      const SizedBox(height: 24),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              SelectField(
                                label: 'Appearance',
                                value: prefs['theme'] as String? ?? 'system',
                                options: {
                                  'system': 'System',
                                  'light': 'Light',
                                  'dark': 'Dark',
                                },
                                onChanged: (v) => update({'theme': v}),
                              ),
                              const SizedBox(height: 20),
                              SelectField(
                                label: 'Measurement units',
                                value: prefs['unit'] as String? ?? 'in',
                                options: {
                                  'in': 'Inches',
                                  'mm': 'Millimetres',
                                  'cm': 'Centimetres',
                                },
                                onChanged: (v) => update({'unit': v}),
                              ),
                              const SizedBox(height: 12),
                              SwitchListTile.adaptive(
                                contentPadding: EdgeInsets.zero,
                                title: const Text('Auto-save projects'),
                                subtitle: const Text(
                                  'Applies the next time you open an editor.',
                                ),
                                value: prefs['autosave'] != false,
                                onChanged: (v) => update({'autosave': v}),
                              ),
                              SwitchListTile.adaptive(
                                contentPadding: EdgeInsets.zero,
                                title: const Text('Remember export format'),
                                value: prefs['rememberExport'] != false,
                                onChanged: (v) => update({'rememberExport': v}),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Defaults for new projects',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      Card(
                        clipBehavior: Clip.antiAlias,
                        child: ConfigurationInspector(
                          config: defaults,
                          includeArtwork: false,
                          unit: prefs['unit'] as String? ?? 'in',
                          onChange: (values) {
                            try {
                              final next = defaults.change(values);
                              SlicingPlan.create(next);
                              update({'defaults': next.toJson()});
                            } catch (e) {
                              showError(context, e);
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ZSlice by OnezPH',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Version 1.1.0 · Create. Slice. Print.',
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Solar Bold Duotone icons by 480 Design · CC BY 4.0\nInter by Rasmus Andersson · SIL Open Font License',
                              ),
                              const SizedBox(height: 12),
                              TextButton.icon(
                                onPressed: () => showLicensePage(
                                  context: context,
                                  applicationName: 'ZSlice by OnezPH',
                                  applicationVersion: '1.1.0',
                                ),
                                icon: AppIcons.document,
                                label: const Text('Open-source licenses'),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Word import requires LibreOffice on desktop. Source PDF pages are rasterized for export. Apple platform builds require a Mac.',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
