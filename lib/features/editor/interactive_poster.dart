import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../slicing/print_config.dart';
import '../slicing/slicing_plan.dart';
import 'artwork_geometry.dart';
import 'poster_renderer.dart';

class InteractivePoster extends StatefulWidget {
  const InteractivePoster({
    super.key,
    required this.plan,
    required this.image,
    required this.pixelsPerMm,
    required this.viewportScale,
    required this.selection,
    required this.onSelection,
    required this.onCommit,
    required this.onPanCanvas,
    required this.onEdit,
    this.panMode = false,
    this.tile,
  });
  final SlicingPlan plan;
  final ui.Image? image;
  final double pixelsPerMm;
  final double Function() viewportScale;
  final String? selection;
  final ValueChanged<String?> onSelection;
  final ValueChanged<Map<String, dynamic>> onCommit;
  final ValueChanged<Offset> onPanCanvas;
  final VoidCallback onEdit;
  final bool panMode;
  final Tile? tile;
  @override
  State<InteractivePoster> createState() => _InteractivePosterState();
}

class _InteractivePosterState extends State<InteractivePoster> {
  PrintConfig? draft;
  final pointers = <int>{};
  void release(PointerEvent e) {
    final wasMulti = pointers.length > 1;
    pointers.remove(e.pointer);
    if (wasMulti && mounted) setState(() {});
  }

  String? target;
  Offset start = Offset.zero, previous = Offset.zero;
  PhysicalRect? original;
  SlicingPlan get plan =>
      draft == null ? widget.plan : SlicingPlan.create(draft!);
  Rect? bounds(SlicingPlan p, String? id) {
    if (id == 'image' && widget.image != null) {
      return PosterRenderer.rect(
        ArtworkGeometry.bounds(p, widget.image!.width, widget.image!.height),
      );
    }
    for (final t in p.config.texts) {
      if (t.id == id) return PosterRenderer.textBounds(t);
    }
    return null;
  }

  String? hit(Offset point) {
    for (final t in widget.plan.config.texts.reversed) {
      if (PosterRenderer.textBounds(t).contains(point)) return t.id;
    }
    return bounds(widget.plan, 'image')?.contains(point) == true
        ? 'image'
        : null;
  }

  PhysicalRect physical(Rect r) =>
      PhysicalRect(r.left, r.top, r.width, r.height);
  void begin(DragStartDetails d, {bool handle = false}) {
    start = previous = d.globalPosition;
    target = handle
        ? widget.selection
        : hit(d.localPosition / widget.pixelsPerMm);
    if (!handle && widget.panMode) target = null;
    widget.onSelection(target);
    final rect = bounds(widget.plan, target);
    original = rect == null ? null : physical(rect);
  }

  void drag(DragUpdateDetails d, {String? corner}) {
    if (original == null || target == null) {
      widget.onPanCanvas(d.globalPosition - previous);
      previous = d.globalPosition;
      return;
    }
    final delta =
        (d.globalPosition - start) /
        (widget.pixelsPerMm * widget.viewportScale());
    final threshold = 8 / (widget.pixelsPerMm * widget.viewportScale());
    final p = widget.plan;
    final box = corner == null
        ? ArtworkGeometry.move(p, original!, delta.dx, delta.dy, threshold)
        : ArtworkGeometry.resize(
            p,
            original!,
            corner,
            delta.dx,
            delta.dy,
            threshold,
          );
    if (target == 'image') {
      setState(
        () => draft = ArtworkGeometry.place(
          p,
          box,
          widget.image!.width,
          widget.image!.height,
          independent: corner != null && !corner.contains('-'),
        ),
      );
    } else {
      final texts = p.config.texts
          .map(
            (t) => t.id != target
                ? t
                : t.change({
                    'x': box.x,
                    'y': box.y,
                    'width': box.width,
                    if (corner != null)
                      'fontSize': (t.fontSize * box.width / original!.width)
                          .clamp(4.0, 1000.0),
                  }),
          )
          .toList();
      setState(
        () => draft = p.config.change({
          'texts': texts.map((t) => t.toJson()).toList(),
        }),
      );
    }
  }

  void cancelGesture() {
    if (draft == null && original == null) return;
    draft = null;
    original = null;
    // A recognizer may cancel while Flutter replaces it during a rebuild.
    Future<void>.microtask(() {
      if (mounted) setState(() {});
    });
  }

  void finish() {
    final next = draft;
    setState(() {
      draft = null;
      original = null;
    });
    if (next != null) widget.onCommit(next.toJson());
  }

  @override
  void didUpdateWidget(InteractivePoster old) {
    super.didUpdateWidget(old);
    if (old.plan.config != widget.plan.config) {
      draft = null;
      original = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = plan;
    final canEdit = widget.tile == null && pointers.length < 2;
    final selected = widget.tile == null ? bounds(p, widget.selection) : null;
    final screenRect = selected == null
        ? null
        : Rect.fromLTRB(
            selected.left * widget.pixelsPerMm,
            selected.top * widget.pixelsPerMm,
            selected.right * widget.pixelsPerMm,
            selected.bottom * widget.pixelsPerMm,
          );
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: Listener(
            onPointerDown: widget.tile != null
                ? null
                : (e) {
                    pointers.add(e.pointer);
                    if (pointers.length > 1) {
                      setState(() {
                        draft = null;
                        original = null;
                      });
                    } else {
                      widget.onSelection(
                        hit(e.localPosition / widget.pixelsPerMm),
                      );
                    }
                  },
            onPointerUp: release,
            onPointerCancel: release,
            child: GestureDetector(
              dragStartBehavior: DragStartBehavior.down,
              behavior: HitTestBehavior.opaque,
              // Claim taps on the poster so the workspace background does not
              // clear the selection made on pointer-down.
              onTap: canEdit ? () {} : null,
              onDoubleTap: canEdit ? widget.onEdit : null,
              onDoubleTapDown: canEdit
                  ? (d) => widget.onSelection(
                      hit(d.localPosition / widget.pixelsPerMm),
                    )
                  : null,
              onPanStart: canEdit ? (d) => begin(d) : null,
              onPanUpdate: canEdit ? drag : null,
              onPanEnd: canEdit ? (_) => finish() : null,
              onPanCancel: canEdit ? cancelGesture : null,
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: PosterPainter(p, widget.image, tile: widget.tile),
                ),
              ),
            ),
          ),
        ),
        if (screenRect != null) ...[
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _SelectionPainter(
                  screenRect,
                  p,
                  widget.pixelsPerMm,
                  draft != null,
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
          for (final corner in [
            'top-left',
            'top-right',
            'bottom-left',
            'bottom-right',
            if (widget.selection == 'image') ...[
              'left',
              'right',
              'top',
              'bottom',
            ],
          ])
            Positioned(
              left:
                  (switch (corner) {
                    'top' || 'bottom' => screenRect.center.dx,
                    _ =>
                      corner.endsWith('left')
                          ? screenRect.left
                          : screenRect.right,
                  }).clamp(
                    8.0,
                    math.max(8.0, p.width * widget.pixelsPerMm - 8),
                  ) -
                  12,
              top:
                  (switch (corner) {
                    'left' || 'right' => screenRect.center.dy,
                    _ =>
                      corner.startsWith('top')
                          ? screenRect.top
                          : screenRect.bottom,
                  }).clamp(
                    8.0,
                    math.max(8.0, p.height * widget.pixelsPerMm - 8),
                  ) -
                  12,
              child: Semantics(
                label: 'Resize $corner',
                child: MouseRegion(
                  cursor: switch (corner) {
                    'left' || 'right' => SystemMouseCursors.resizeLeftRight,
                    'top' || 'bottom' => SystemMouseCursors.resizeUpDown,
                    'top-left' ||
                    'bottom-right' => SystemMouseCursors.resizeUpLeftDownRight,
                    _ => SystemMouseCursors.resizeUpRightDownLeft,
                  },
                  child: GestureDetector(
                    dragStartBehavior: DragStartBehavior.down,
                    key: ValueKey('resize-$corner'),
                    behavior: HitTestBehavior.opaque,
                    onPanStart: (d) => begin(d, handle: true),
                    onPanUpdate: (d) => drag(d, corner: corner),
                    onPanEnd: (_) => finish(),
                    onPanCancel: cancelGesture,
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: Center(
                        child: Container(
                          width: corner == 'top' || corner == 'bottom'
                              ? 18
                              : 10,
                          height: corner == 'left' || corner == 'right'
                              ? 18
                              : 10,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            border: Border.all(
                              color: Theme.of(context).colorScheme.primary,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ],
    );
  }
}

class _SelectionPainter extends CustomPainter {
  _SelectionPainter(
    this.bounds,
    this.plan,
    this.scale,
    this.snapping,
    this.color,
  );
  final Rect bounds;
  final SlicingPlan plan;
  final double scale;
  final bool snapping;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawRect(bounds, paint);
    if (snapping && plan.config.snap) {
      paint
        ..color = color.withValues(alpha: 0.6)
        ..strokeWidth = 1;
      for (final g in ArtworkGeometry.guides(plan, true)) {
        if ([
          bounds.left,
          bounds.center.dx,
          bounds.right,
        ].any((x) => (x - g * scale).abs() < 0.5)) {
          canvas.drawLine(
            Offset(g * scale, 0),
            Offset(g * scale, size.height),
            paint,
          );
        }
      }
      for (final g in ArtworkGeometry.guides(plan, false)) {
        if ([
          bounds.top,
          bounds.center.dy,
          bounds.bottom,
        ].any((y) => (y - g * scale).abs() < 0.5)) {
          canvas.drawLine(
            Offset(0, g * scale),
            Offset(size.width, g * scale),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(_SelectionPainter old) =>
      old.bounds != bounds ||
      old.plan != plan ||
      old.snapping != snapping ||
      old.color != color;
}
