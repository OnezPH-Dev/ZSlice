import 'package:flutter/material.dart';
import '../../core/widgets/app_icons.dart';
import '../../core/widgets/configuration_controls.dart';
export '../../core/widgets/configuration_controls.dart';
import '../slicing/print_config.dart';
import '../slicing/slicing_plan.dart';

class ConfigurationInspector extends StatefulWidget {
  const ConfigurationInspector({
    super.key,
    required this.config,
    required this.onChange,
    this.unit = 'in',
    this.includeArtwork = true,
  });
  final PrintConfig config;
  final ValueChanged<Map<String, dynamic>> onChange;
  final String unit;
  final bool includeArtwork;
  @override
  State<ConfigurationInspector> createState() => _ConfigurationInspectorState();
}

class _ConfigurationInspectorState extends State<ConfigurationInspector> {
  String? error;
  int fieldRevision = 0;
  PrintConfig get config => widget.config;
  String get unit => widget.unit;
  bool get includeArtwork => widget.includeArtwork;
  double get factor => unit == 'in'
      ? 25.4
      : unit == 'cm'
      ? 10
      : 1;

  void commit(Map<String, dynamic> values) {
    // Validate here so numeric controls can show errors beside the input,
    // before the workspace's general error handler is involved.
    SlicingPlan.create(config.change(values));
    widget.onChange(values);
    if (error != null) setState(() => error = null);
  }

  void change(Map<String, dynamic> values) {
    try {
      commit(values);
      // A preset can reapply the current valid value after an invalid draft.
      // Reset numeric drafts even when the document value did not change.
      setState(() => fieldRevision++);
    } on FormatException catch (e) {
      setState(() {
        error = e.message;
        fieldRevision++;
      });
    }
  }

  String presetLabel(double inches) =>
      '${(inches * 25.4 / factor).toStringAsFixed(3).replaceFirst(RegExp(r'\.?0+$'), '')} $unit';

  @override
  Widget build(BuildContext context) {
    final c = config;
    final plan = SlicingPlan.create(c);
    Widget numeric(
      String label,
      String key,
      double value, {
      double multiplier = 1,
      bool integer = false,
      double? min,
      double? max,
    }) => NumberField(
      key: ValueKey('$unit-$key-$fieldRevision'),
      label: label,
      value: value / multiplier,
      integer: integer,
      min: min,
      max: max,
      onCommit: (v) => commit({key: integer ? v.toInt() : v * multiplier}),
    );
    Widget toggle(String title, String key, bool value) =>
        SwitchListTile.adaptive(
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: Text(title, style: Theme.of(context).textTheme.bodyMedium),
          value: value,
          onChanged: (v) => change({key: v}),
        );
    Widget dropdown(
      String title,
      String key,
      String value,
      Map<String, String> options,
    ) => SelectField(
      key: ValueKey('$key-$fieldRevision'),
      label: title,
      value: value,
      options: options,
      onChanged: (v) => change({key: v}),
    );
    // Color fields use integer persistence, while dropdowns carry string IDs.
    Widget colorField(String title, String key, int value) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SelectField(
          label: title,
          value: value.toString(),
          options: {
            '${0xff0f172a}': 'Ink',
            '4278190080': 'Black',
            '${0xff64748b}': 'Slate',
            '${0xff4f46e5}': 'Indigo',
            '${0xffdc2626}': 'Red',
            if (![
              0xff0f172a,
              0xff000000,
              0xff64748b,
              0xff4f46e5,
              0xffdc2626,
            ].contains(value))
              '$value': 'Custom',
          },
          onChanged: (v) => change({key: int.parse(v)}),
        ),
        const SizedBox(height: 12),
        HexColorField(
          label: 'Custom color (#RRGGBB)',
          value: value,
          onCommit: (v) => commit({key: v}),
        ),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (error != null)
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        InspectorSection(
          title: 'Layout',
          icon: AppIcons.grid,
          initiallyExpanded: true,
          children: [
            SegmentedButton<String>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: 'grid', label: Text('Grid')),
                ButtonSegment(value: 'size', label: Text('Physical size')),
              ],
              selected: {c.layout},
              onSelectionChanged: (v) => change({
                'layout': v.first,
                if (v.first == 'size') ...{
                  'posterWidth': plan.width,
                  'posterHeight': plan.height,
                } else ...{
                  'columns': plan.columns,
                  'rows': plan.rows,
                },
              }),
            ),
            const SizedBox(height: 16),
            if (c.layout == 'grid')
              Row(
                children: [
                  Expanded(
                    child: numeric(
                      'Columns',
                      'columns',
                      c.columns.toDouble(),
                      integer: true,
                      min: 1,
                      max: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: numeric(
                      'Rows',
                      'rows',
                      c.rows.toDouble(),
                      integer: true,
                      min: 1,
                      max: 20,
                    ),
                  ),
                ],
              )
            else
              Row(
                children: [
                  Expanded(
                    child: numeric(
                      'Width ($unit)',
                      'posterWidth',
                      c.posterWidth,
                      multiplier: factor,
                      min: 0.01,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: numeric(
                      'Height ($unit)',
                      'posterHeight',
                      c.posterHeight,
                      multiplier: factor,
                      min: 0.01,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primaryContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  AppIcons.document,
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${plan.tiles.length} printable sheets\n${(plan.width / factor).toStringAsFixed(2)} × ${(plan.height / factor).toStringAsFixed(2)} $unit',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            dropdown('Page order', 'order', c.order, {
              'row': 'Left to right, then down',
              'column': 'Top to bottom, then across',
            }),
          ],
        ),
        InspectorSection(
          title: 'Paper',
          icon: AppIcons.document,
          initiallyExpanded: true,
          children: [
            dropdown('Paper size', 'paper', c.paper, {
              for (final paper in paperSizes.keys) paper: paper,
              'Custom': 'Custom',
            }),
            if (c.paper == 'Custom') ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: numeric(
                      'Width ($unit)',
                      'customWidth',
                      c.customWidth,
                      multiplier: factor,
                      min: 0.1,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: numeric(
                      'Height ($unit)',
                      'customHeight',
                      c.customHeight,
                      multiplier: factor,
                      min: 0.1,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            SegmentedButton<bool>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: false, label: Text('Portrait')),
                ButtonSegment(value: true, label: Text('Landscape')),
              ],
              selected: {c.landscape},
              onSelectionChanged: (v) => change({'landscape': v.first}),
            ),
            const SizedBox(height: 12),
            Text(
              '${(c.paperSize.$1 / factor).toStringAsFixed(2)} × ${(c.paperSize.$2 / factor).toStringAsFixed(2)} $unit',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        InspectorSection(
          title: 'Margins',
          icon: AppIcons.crop,
          children: [
            toggle('Enable margins', 'margins', c.margins),
            if (c.margins) ...[
              SwitchListTile.adaptive(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: const Text('Link all sides'),
                value: c.linkMargins,
                onChanged: (v) => change({
                  'linkMargins': v,
                  if (v) ...{'right': c.top, 'bottom': c.top, 'left': c.top},
                }),
              ),
              if (c.linkMargins)
                NumberField(
                  key: ValueKey('$unit-allMargins-$fieldRevision'),
                  label: 'All margins ($unit)',
                  value: c.top / factor,
                  min: 0,
                  onCommit: (v) => commit({
                    'top': v * factor,
                    'right': v * factor,
                    'bottom': v * factor,
                    'left': v * factor,
                  }),
                )
              else ...[
                Row(
                  children: [
                    Expanded(
                      child: numeric(
                        'Top ($unit)',
                        'top',
                        c.top,
                        multiplier: factor,
                        min: 0,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: numeric(
                        'Right ($unit)',
                        'right',
                        c.right,
                        multiplier: factor,
                        min: 0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: numeric(
                        'Bottom ($unit)',
                        'bottom',
                        c.bottom,
                        multiplier: factor,
                        min: 0,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: numeric(
                        'Left ($unit)',
                        'left',
                        c.left,
                        multiplier: factor,
                        min: 0,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                children: [
                  for (final value in [0.0, 0.125, 0.25, 0.5])
                    ActionChip(
                      label: Text(presetLabel(value)),
                      onPressed: () => change({
                        'top': value * 25.4,
                        'right': value * 25.4,
                        'bottom': value * 25.4,
                        'left': value * 25.4,
                      }),
                    ),
                ],
              ),
            ],
          ],
        ),
        InspectorSection(
          title: 'Overlap',
          icon: AppIcons.layers,
          children: [
            toggle('Enable overlap', 'overlapEnabled', c.overlapEnabled),
            if (c.overlapEnabled) ...[
              numeric(
                'Overlap ($unit)',
                'overlap',
                c.overlap,
                multiplier: factor,
                min: 0,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                children: [
                  for (final value in [0.0, 0.125, 0.25, 0.375, 0.5, 0.75, 1.0])
                    ActionChip(
                      label: Text(presetLabel(value)),
                      onPressed: () => change({'overlap': value * 25.4}),
                    ),
                ],
              ),
              toggle('Highlight overlap', 'showOverlap', c.showOverlap),
              Text(
                'Adjacent sheets repeat this amount of artwork. Trim marks sit at the overlap midpoint.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
        InspectorSection(
          title: 'Cutting guides',
          icon: AppIcons.scissors,
          children: [
            toggle('Scissors indicators', 'scissors', c.scissors),
            if (c.scissors) ...[
              dropdown(
                'Scissors placement',
                'scissorsPlacement',
                c.scissorsPlacement,
                {
                  'all': 'All interior edges',
                  'selected': 'Selected edges',
                  'corners': 'Corners of selected edges',
                },
              ),
              const SizedBox(height: 12),
              SelectField(
                label: 'Scissors size',
                value: c.scissorsSize.toString(),
                options: {
                  '0.75': 'Small',
                  '1.0': 'Medium',
                  '1.5': 'Large',
                  if (![0.75, 1.0, 1.5].contains(c.scissorsSize))
                    c.scissorsSize.toString(): 'Custom',
                },
                onChanged: (v) => change({'scissorsSize': double.parse(v)}),
              ),
              const SizedBox(height: 12),
              colorField('Scissors color', 'scissorsColor', c.scissorsColor),
              const SizedBox(height: 12),
            ],
            toggle('Cutting lines', 'lines', c.lines),
            if (c.lines) ...[
              dropdown('Line style', 'lineStyle', c.lineStyle, {
                'solid': 'Solid',
                'dashed': 'Dashed',
                'dotted': 'Dotted',
                'dashDot': 'Dash-dot',
                'corners': 'Corner marks',
              }),
              const SizedBox(height: 12),
              numeric(
                'Thickness (pt)',
                'lineWidth',
                c.lineWidth,
                min: 0.05,
                max: 10,
              ),
              const SizedBox(height: 12),
              colorField('Guide color', 'guideColor', c.guideColor),
            ],
            const SizedBox(height: 12),
            const Text('Interior cut edges'),
            Wrap(
              spacing: 6,
              children: [
                for (final item in [
                  ('Top', 'cutTop', c.cutTop),
                  ('Right', 'cutRight', c.cutRight),
                  ('Bottom', 'cutBottom', c.cutBottom),
                  ('Left', 'cutLeft', c.cutLeft),
                ])
                  FilterChip(
                    showCheckmark: false,
                    label: Text(item.$1),
                    selected: item.$3,
                    onSelected: (v) => change({item.$2: v}),
                  ),
              ],
            ),
            toggle('Show guides in preview', 'previewGuides', c.previewGuides),
            toggle('Include guides in export', 'exportGuides', c.exportGuides),
          ],
        ),
        InspectorSection(
          title: 'Page numbering',
          icon: AppIcons.document,
          children: [
            toggle('Enable numbering', 'numbering', c.numbering),
            if (c.numbering) ...[
              dropdown('Format', 'numberStyle', c.numberStyle, {
                'sequential': '1, 2, 3…',
                'page': 'Page 1 of 12',
                'coordinates': 'R1-C1',
                'verbose': 'Row 1 / Column 1',
              }),
              const SizedBox(height: 12),
              dropdown('Position', 'numberPosition', c.numberPosition, {
                'topLeft': 'Top left',
                'topRight': 'Top right',
                'bottomLeft': 'Bottom left',
                'bottomRight': 'Bottom right',
                'bottomCenter': 'Bottom center',
              }),
              const SizedBox(height: 12),
              numeric(
                'Font size (pt)',
                'numberSize',
                c.numberSize,
                min: 4,
                max: 72,
              ),
              const SizedBox(height: 12),
              colorField('Number color', 'numberColor', c.numberColor),
              const SizedBox(height: 12),
              Text(
                'With zero margins, labels may cover artwork at the paper edge.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
        InspectorSection(
          title: 'Resolution',
          icon: AppIcons.export,
          children: [
            toggle('Automatic DPI', 'autoDpi', c.autoDpi),
            if (!c.autoDpi) ...[
              numeric(
                'Custom DPI',
                'dpi',
                c.dpi.toDouble(),
                integer: true,
                min: 36,
                max: 1200,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                children: [
                  for (final dpi in [72, 96, 150, 300, 600])
                    ActionChip(
                      label: Text('$dpi'),
                      onPressed: () => change({'dpi': dpi}),
                    ),
                ],
              ),
            ] else
              const Text(
                'Chooses 72–300 DPI based on available source pixels.',
              ),
          ],
        ),
        if (includeArtwork)
          InspectorSection(
            title: 'Artwork',
            icon: AppIcons.select,
            children: [
              numeric(
                'Scale (%)',
                'scale',
                c.scale,
                multiplier: 0.01,
                min: 5,
                max: 1000,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: numeric(
                      'X offset ($unit)',
                      'offsetX',
                      c.offsetX,
                      multiplier: factor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: numeric(
                      'Y offset ($unit)',
                      'offsetY',
                      c.offsetY,
                      multiplier: factor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: numeric(
                      'Width stretch (%)',
                      'stretchX',
                      c.stretchX,
                      multiplier: 0.01,
                      min: 5,
                      max: 1000,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: numeric(
                      'Height stretch (%)',
                      'stretchY',
                      c.stretchY,
                      multiplier: 0.01,
                      min: 5,
                      max: 1000,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => change({'rotation': (c.rotation + 1) % 4}),
                icon: AppIcons.rotate,
                label: Text('Rotate 90° (${c.rotation * 90}°)'),
              ),
              const SizedBox(height: 16),
              const Text('Crop source (%)'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: numeric(
                      'Left',
                      'cropLeft',
                      c.cropLeft,
                      multiplier: 0.01,
                      min: 0,
                      max: 99,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: numeric(
                      'Top',
                      'cropTop',
                      c.cropTop,
                      multiplier: 0.01,
                      min: 0,
                      max: 99,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: numeric(
                      'Right',
                      'cropRight',
                      c.cropRight,
                      multiplier: 0.01,
                      min: 1,
                      max: 100,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: numeric(
                      'Bottom',
                      'cropBottom',
                      c.cropBottom,
                      multiplier: 0.01,
                      min: 1,
                      max: 100,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => change({
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
                child: const Text('Reset artwork'),
              ),
            ],
          ),
        InspectorSection(
          title: 'View options',
          icon: AppIcons.preview,
          children: [
            toggle('Editor grid', 'grid', c.grid),
            toggle('Rulers', 'rulers', c.rulers),
            toggle('Paper boundaries', 'boundaries', c.boundaries),
          ],
        ),
      ],
    );
  }
}
