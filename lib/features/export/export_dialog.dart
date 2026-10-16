import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import '../../core/widgets/app_icons.dart';
import '../editor/configuration_inspector.dart';
import '../projects/project.dart';
import '../projects/providers.dart';
import '../projects/project_archive.dart';
import '../slicing/slicing_plan.dart';
import 'export_service.dart';
import 'save_output.dart';

Future<void> showExportDialog(
  BuildContext context,
  SliceProject project,
  ui.Image? image, {
  bool print = false,
}) => showDialog<void>(
  context: context,
  barrierDismissible: false,
  builder: (_) => ExportDialog(project: project, image: image, print: print),
);

class ExportDialog extends ConsumerStatefulWidget {
  const ExportDialog({
    super.key,
    required this.project,
    required this.image,
    this.print = false,
  });
  final SliceProject project;
  final ui.Image? image;
  final bool print;
  @override
  ConsumerState<ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends ConsumerState<ExportDialog> {
  String format = 'pdf';
  late final TextEditingController filename;
  final cancellation = ExportCancellation();
  bool running = false;
  String get outputFormat => widget.print ? 'pdf' : format;
  int done = 0, total = 0;
  String? error;
  @override
  void initState() {
    super.initState();
    filename = TextEditingController(text: safeName(widget.project.name));
    final prefs = ref.read(preferencesProvider).value ?? {};
    final saved = prefs['exportFormat'];
    if (prefs['rememberExport'] != false &&
        {'pdf', 'png', 'jpeg', 'docx'}.contains(saved)) {
      format = saved as String;
    }
  }

  Future<void> run() async {
    if (filename.text.trim().isEmpty) {
      setState(() => error = 'Enter a file name.');
      return;
    }
    setState(() {
      running = true;
      error = null;
      done = 0;
    });
    Directory? temp;
    try {
      if (!widget.print &&
          ref.read(preferencesProvider).value?['rememberExport'] != false) {
        await ref.read(preferencesProvider.notifier).setValues({
          'exportFormat': format,
        });
      }
      final plan = SlicingPlan.create(widget.project.config);
      final dpi = (widget.image == null
          ? (plan.config.autoDpi ? 300 : plan.config.dpi)
          : plan.effectiveDpi(widget.image!.width, widget.image!.height));
      temp = await Directory.systemTemp.createTemp('zslice-export-');
      final file = await ExportService().export(
        plan: plan,
        image: widget.image,
        format: outputFormat,
        dpi: dpi,
        directory: temp,
        cancellation: cancellation,
        progress: (d, t) {
          if (mounted) {
            setState(() {
              done = d;
              total = t;
            });
          }
        },
      );
      cancellation.check();
      final extension = outputFormat == 'pdf'
          ? 'pdf'
          : outputFormat == 'docx'
          ? 'docx'
          : 'zip';
      final name = '${safeName(filename.text.trim())}.$extension';
      bool saved;
      if (widget.print) {
        if (await file.length() > 128 * 1024 * 1024) {
          throw const FormatException(
            'Print job exceeds 128 MB. Export PDF on desktop instead.',
          );
        }
        final bytes = await file.readAsBytes();
        saved = await Printing.layoutPdf(
          format: PdfPageFormat(
            plan.config.paperSize.$1 * PdfPageFormat.mm,
            plan.config.paperSize.$2 * PdfPageFormat.mm,
          ),
          name: name,
          onLayout: (_) async => bytes,
          dynamicLayout: false,
          usePrinterSettings: false,
        );
      } else {
        saved = await saveOutput(
          file,
          name,
          format == 'pdf'
              ? 'application/pdf'
              : format == 'docx'
              ? 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
              : 'application/zip',
        );
      }
      if (mounted) {
        Navigator.pop(context);
        if (saved) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.print
                    ? 'Print job sent.'
                    : 'Export saved. Print at 100% scale.',
              ),
            ),
          );
        }
      }
    } on ExportCancelled {
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => error = e is FormatException ? e.message : e.toString());
      }
    } finally {
      if (temp != null) await temp.delete(recursive: true);
      if (mounted) setState(() => running = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final plan = SlicingPlan.create(widget.project.config);
    final c = plan.config;
    final dpi = (widget.image == null
        ? (plan.config.autoDpi ? 300 : plan.config.dpi)
        : plan.effectiveDpi(widget.image!.width, widget.image!.height));
    final w = (c.paperSize.$1 / 25.4 * dpi).round(),
        h = (c.paperSize.$2 / 25.4 * dpi).round();
    return PopScope(
      canPop: !running,
      child: AlertDialog(
        title: Text(
          widget.print ? 'Print your poster' : 'Ready for the real world.',
        ),
        content: SizedBox(
          width: 460,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '${plan.tiles.length} sheets  ·  ${c.paper}  ·  ${c.landscape ? 'Landscape' : 'Portrait'}',
                ),
                const SizedBox(height: 20),
                if (!widget.print)
                  SelectField(
                    label: 'Export format',
                    value: format,
                    options: {
                      'pdf': 'PDF · print-ready document',
                      'png': 'PNG images · ZIP archive',
                      'jpeg': 'JPEG images · ZIP archive',
                      'docx': 'Word document · page images',
                    },
                    onChanged: (v) {
                      if (!running) setState(() => format = v);
                    },
                  ),
                const SizedBox(height: 16),
                TextField(
                  controller: filename,
                  enabled: !running,
                  decoration: const InputDecoration(labelText: 'File name'),
                ),
                const SizedBox(height: 20),
                Text(
                  'Output: $w × $h px per sheet at $dpi DPI\n'
                  'Margins: ${c.margins ? '${(c.left / 25.4).toStringAsFixed(3)}″ left / ${(c.top / 25.4).toStringAsFixed(3)}″ top / ${(c.right / 25.4).toStringAsFixed(3)}″ right / ${(c.bottom / 25.4).toStringAsFixed(3)}″ bottom' : 'off'}\n'
                  'Overlap: ${c.overlapEnabled ? '${(c.overlap / 25.4).toStringAsFixed(3)}″' : 'off'}\n'
                  'Cutting lines: ${c.exportGuides && c.lines ? c.lineStyle : 'off'} · Scissors: ${c.exportGuides && c.scissors ? 'on' : 'off'}\n'
                  'Page numbers: ${c.numbering ? 'on' : 'off'}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                if (plan.sourceDpi(
                      widget.image?.width ?? 999999,
                      widget.image?.height ?? 999999,
                    ) <
                    dpi * 0.9) ...[
                  Text(
                    'Available artwork detail is approximately ${plan.sourceDpi(widget.image?.width ?? 999999, widget.image?.height ?? 999999).round()} DPI. A higher export DPI cannot add source detail.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                ],
                Text(
                  widget.print
                      ? 'Choose your printer and matching paper. Print at actual size / 100% scale.'
                      : 'Choose a destination after rendering. Print at actual size / 100% scale.',
                ),
                if (widget.project.source?.kind == 'pdf') ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Source PDF is rasterized. Vector preservation is not supported.',
                  ),
                ],
                if (outputFormat == 'docx') ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Word pages contain images. Text is not independently editable.',
                  ),
                ],
                if (w * h > 12000000) ...[
                  const SizedBox(height: 12),
                  Text(
                    'High memory use: approximately ${(w * h * 12 / 1048576).round()} MB of working buffers per sheet.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                if (running) ...[
                  const SizedBox(height: 24),
                  LinearProgressIndicator(
                    value: total == 0 ? null : done / total,
                  ),
                  const SizedBox(height: 12),
                  Text('Rendering sheet $done of ${plan.tiles.length}…'),
                ],
                if (error != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (running) {
                setState(() => cancellation.cancelled = true);
              } else {
                Navigator.pop(context);
              }
            },
            child: Text(running ? 'Cancel export' : 'Cancel'),
          ),
          FilledButton.icon(
            onPressed: running || cancellation.cancelled ? null : run,
            icon: widget.print ? AppIcons.print : AppIcons.export,
            label: Text(widget.print ? 'Print' : 'Export'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    filename.dispose();
    super.dispose();
  }
}
