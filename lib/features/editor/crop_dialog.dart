import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../slicing/print_config.dart';

Future<Map<String, dynamic>?> cropImage(
  BuildContext context,
  ui.Image image,
  PrintConfig config,
) => showDialog<Map<String, dynamic>>(
  context: context,
  builder: (_) => _CropDialog(image: image, config: config),
);

class _CropDialog extends StatefulWidget {
  const _CropDialog({required this.image, required this.config});
  final ui.Image image;
  final PrintConfig config;
  @override
  State<_CropDialog> createState() => _CropDialogState();
}

class _CropDialogState extends State<_CropDialog> {
  late Rect crop = Rect.fromLTRB(
    widget.config.cropLeft,
    widget.config.cropTop,
    widget.config.cropRight,
    widget.config.cropBottom,
  );
  Rect original = Rect.zero;
  Offset start = Offset.zero;
  String handle = '';
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Crop image'),
    content: SizedBox(
      width: 560,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Drag inside the crop to move it, drag a corner to resize, or draw a new crop.',
            ),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.48,
              ),
              child: AspectRatio(
                aspectRatio: widget.image.width / widget.image.height,
                child: LayoutBuilder(
                  builder: (context, box) => GestureDetector(
                    key: const ValueKey('crop-surface'),
                    onPanStart: (d) {
                      start = Offset(
                        d.localPosition.dx / box.maxWidth,
                        d.localPosition.dy / box.maxHeight,
                      );
                      original = crop;
                      handle = '';
                      for (final entry in {
                        'tl': crop.topLeft,
                        'tr': crop.topRight,
                        'bl': crop.bottomLeft,
                        'br': crop.bottomRight,
                      }.entries) {
                        if (((entry.value - start).scale(
                              box.maxWidth,
                              box.maxHeight,
                            )).distance <
                            28) {
                          handle = entry.key;
                          break;
                        }
                      }
                      if (handle.isEmpty) {
                        handle = crop.contains(start) ? 'move' : 'new';
                      }
                    },
                    onPanUpdate: (d) {
                      final point = Offset(
                        (d.localPosition.dx / box.maxWidth).clamp(0.0, 1.0),
                        (d.localPosition.dy / box.maxHeight).clamp(0.0, 1.0),
                      );
                      final delta = point - start;
                      setState(() {
                        if (handle == 'move') {
                          final x = (original.left + delta.dx).clamp(
                            0.0,
                            1 - original.width,
                          );
                          final y = (original.top + delta.dy).clamp(
                            0.0,
                            1 - original.height,
                          );
                          crop = Rect.fromLTWH(
                            x,
                            y,
                            original.width,
                            original.height,
                          );
                        } else if (handle == 'new') {
                          final next = Rect.fromPoints(start, point);
                          if (next.width >= 0.01 && next.height >= 0.01) {
                            crop = next;
                          }
                        } else {
                          crop = Rect.fromLTRB(
                            handle.endsWith('l')
                                ? point.dx.clamp(0.0, original.right - 0.01)
                                : original.left,
                            handle.startsWith('t')
                                ? point.dy.clamp(0.0, original.bottom - 0.01)
                                : original.top,
                            handle.endsWith('r')
                                ? point.dx.clamp(original.left + 0.01, 1.0)
                                : original.right,
                            handle.startsWith('b')
                                ? point.dy.clamp(original.top + 0.01, 1.0)
                                : original.bottom,
                          );
                        }
                      });
                    },
                    child: CustomPaint(
                      painter: _CropPainter(
                        widget.image,
                        crop,
                        Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => setState(() => crop = const Rect.fromLTWH(0, 0, 1, 1)),
        child: const Text('Reset crop'),
      ),
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(context, {
          'cropLeft': crop.left,
          'cropTop': crop.top,
          'cropRight': crop.right,
          'cropBottom': crop.bottom,
        }),
        child: const Text('Apply crop'),
      ),
    ],
  );
}

class _CropPainter extends CustomPainter {
  _CropPainter(this.image, this.crop, this.color);
  final ui.Image image;
  final Rect crop;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Offset.zero & size,
      Paint(),
    );
    final rect = Rect.fromLTRB(
      crop.left * size.width,
      crop.top * size.height,
      crop.right * size.width,
      crop.bottom * size.height,
    );
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Offset.zero & size),
        Path()..addRect(rect),
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.5),
    );
    canvas.drawRect(
      rect,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    for (final point in [
      rect.topLeft,
      rect.topRight,
      rect.bottomLeft,
      rect.bottomRight,
    ]) {
      canvas.drawCircle(point, 6, Paint()..color = Colors.white);
      canvas.drawCircle(
        point,
        6,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(_CropPainter old) =>
      old.crop != crop || old.image != image || old.color != color;
}
