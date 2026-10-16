import 'package:flutter/material.dart';
import '../../core/widgets/configuration_controls.dart';
import '../slicing/text_layer.dart';

Future<TextLayer?> editTextLayer(BuildContext context, TextLayer layer) =>
    showDialog<TextLayer>(
      context: context,
      builder: (_) => _TextEditorDialog(layer: layer),
    );

class _TextEditorDialog extends StatefulWidget {
  const _TextEditorDialog({required this.layer});
  final TextLayer layer;
  @override
  State<_TextEditorDialog> createState() => _TextEditorDialogState();
}

class _TextEditorDialogState extends State<_TextEditorDialog> {
  late TextLayer layer = widget.layer;
  late final content = TextEditingController(text: layer.text);
  void change(Map<String, dynamic> values) =>
      setState(() => layer = layer.change(values));
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Edit text'),
    content: SizedBox(
      width: 480,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              key: const ValueKey('text-content'),
              controller: content,
              autofocus: true,
              minLines: 2,
              maxLines: 5,
              maxLength: 10000,
              decoration: const InputDecoration(labelText: 'Text'),
              onChanged: (v) => change({'text': v}),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: NumberField(
                    label: 'Font size (pt)',
                    value: layer.fontSize,
                    min: 4,
                    max: 1000,
                    onCommit: (v) => change({'fontSize': v}),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: NumberField(
                    label: 'Width (mm)',
                    value: layer.width,
                    min: 1,
                    max: 24000,
                    onCommit: (v) => change({'width': v}),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              children: [
                FilterChip(
                  label: const Text('Bold'),
                  selected: layer.bold,
                  showCheckmark: false,
                  onSelected: (v) => change({'bold': v}),
                ),
                FilterChip(
                  label: const Text('Italic'),
                  selected: layer.italic,
                  showCheckmark: false,
                  onSelected: (v) => change({'italic': v}),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SelectField(
              label: 'Alignment',
              value: layer.align,
              options: {'left': 'Left', 'center': 'Center', 'right': 'Right'},
              onChanged: (v) => change({'align': v}),
            ),
            const SizedBox(height: 16),
            HexColorField(
              label: 'Color (#RRGGBB)',
              value: layer.color,
              onCommit: (v) => change({'color': v}),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: NumberField(
                    label: 'X position (mm)',
                    value: layer.x,
                    onCommit: (v) => change({'x': v}),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: NumberField(
                    label: 'Y position (mm)',
                    value: layer.y,
                    onCommit: (v) => change({'y': v}),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Drag the text on your poster to position it. Corner handles resize proportionally.',
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: layer.text.trim().isEmpty
            ? null
            : () => Navigator.pop(context, layer),
        child: const Text('Apply text'),
      ),
    ],
  );
  @override
  void dispose() {
    content.dispose();
    super.dispose();
  }
}
