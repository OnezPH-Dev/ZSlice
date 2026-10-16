part of 'editor_screen.dart';

mixin _EditorCanvas on State<EditorWorkspace> {
  EditorController get editor;
  TransformationController get viewport;
  bool get select;
  bool get preview;
  bool get exporting;
  int get page;
  Future<void> importFile([String? path]);
  void update(Map<String, dynamic> values);
  String? get selectedLayer;
  void chooseLayer(String? id);
  Future<void> editSelected();
  bool dragging = false;
  double fitScale = 1;
  PrintConfig? gestureConfig;
  Offset gestureDelta = Offset.zero;
  Widget canvas(SlicingPlan plan) => DropTarget(
    enable:
        !editor.busy &&
        !exporting &&
        (ModalRoute.of(context)?.isCurrent ?? true),
    onDragEntered: (_) => setState(() => dragging = true),
    onDragExited: (_) => setState(() => dragging = false),
    onDragDone: (d) {
      setState(() => dragging = false);
      if (d.files.isNotEmpty) importFile(d.files.first.path);
    },
    child: ColoredBox(
      color: Theme.of(context).brightness == Brightness.dark
          ? Tokens.canvasDark
          : Tokens.canvasLight,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: WorkspaceDots(
                Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
          ),
          if (!editor.hasContent && !editor.busy)
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        'assets/ZSlice Logo.png',
                        width: 104,
                        height: 104,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Make room for your big idea.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Import an image or PDF, or add text to a blank poster.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: importFile,
                      icon: AppIcons.importFile,
                      label: const Text('Choose document'),
                    ),
                  ],
                ),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, box) {
                final w = preview ? plan.config.paperSize.$1 : plan.width;
                final h = preview ? plan.config.paperSize.$2 : plan.height;
                fitScale = math.min(
                  math.max(20, box.maxWidth - 112) / w,
                  math.max(20, box.maxHeight - 112) / h,
                );
                final vw = w * fitScale, vh = h * fitScale;
                final unit = widget.preferences['unit'] as String? ?? 'in';
                return InteractiveViewer(
                  transformationController: viewport,
                  minScale: 0.2,
                  maxScale: 8,
                  panEnabled: true,
                  scaleEnabled: true,
                  boundaryMargin: const EdgeInsets.all(1000),
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () => chooseLayer(null),
                    child: SizedBox(
                      width: box.maxWidth,
                      height: box.maxHeight,
                      child: Center(
                        child: SizedBox(
                          width: vw + 28,
                          height: vh + 28,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              if (plan.config.rulers) ...[
                                Positioned(
                                  left: 28,
                                  top: 0,
                                  width: vw,
                                  height: 24,
                                  child: CustomPaint(
                                    painter: RulerPainter(w, unit),
                                  ),
                                ),
                                Positioned(
                                  left: 0,
                                  top: 28,
                                  width: 24,
                                  height: vh,
                                  child: CustomPaint(
                                    painter: RulerPainter(
                                      h,
                                      unit,
                                      vertical: true,
                                    ),
                                  ),
                                ),
                              ],
                              Positioned(
                                left: 28,
                                top: 28,
                                width: vw,
                                height: vh,
                                child: DecoratedBox(
                                  decoration: const BoxDecoration(
                                    boxShadow: [
                                      BoxShadow(
                                        color: Color(0x260f172a),
                                        blurRadius: 24,
                                        offset: Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: InteractivePoster(
                                    plan: plan,
                                    image: editor.image,
                                    pixelsPerMm: fitScale,
                                    viewportScale: () =>
                                        viewport.value.getMaxScaleOnAxis(),
                                    selection: selectedLayer,
                                    onSelection: chooseLayer,
                                    onCommit: update,
                                    onEdit: editSelected,
                                    panMode: !select,
                                    tile: preview ? plan.tiles[page] : null,
                                    onPanCanvas: (delta) {
                                      final m = viewport.value.clone();
                                      m.storage[12] += delta.dx;
                                      m.storage[13] += delta.dy;
                                      viewport.value = m;
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          if (dragging)
            Positioned.fill(
              child: IgnorePointer(
                child: ColoredBox(
                  color: Theme.of(
                    context,
                  ).colorScheme.primaryContainer.withValues(alpha: 0.8),
                  child: const Center(
                    child: Text('Drop your document to import'),
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

class WorkspaceDots extends CustomPainter {
  WorkspaceDots(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color.withValues(alpha: 0.45);
    for (var x = 12.0; x < size.width; x += 20) {
      for (var y = 12.0; y < size.height; y += 20) {
        canvas.drawCircle(Offset(x, y), 0.75, paint);
      }
    }
  }

  @override
  bool shouldRepaint(WorkspaceDots old) => old.color != color;
}

class RulerPainter extends CustomPainter {
  RulerPainter(this.length, this.unit, {this.vertical = false});
  final double length;
  final String unit;
  final bool vertical;
  @override
  void paint(Canvas canvas, Size size) {
    final extent = vertical ? size.height : size.width;
    final factor = unit == 'in'
        ? 25.4
        : unit == 'cm'
        ? 10.0
        : 1.0;
    final step = math.max(1, (length / factor / (extent / 60)).ceil());
    for (var i = 0; i * factor <= length; i += step) {
      final x = i * factor / length * extent;
      canvas.drawLine(
        vertical ? Offset(17, x) : Offset(x, 17),
        vertical ? Offset(24, x) : Offset(x, 24),
        Paint()..color = const Color(0xff94a3b8),
      );
      final text = TextPainter(
        text: TextSpan(
          text: '$i',
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 9,
            color: Color(0xff64748b),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      text.paint(canvas, vertical ? Offset(0, x + 2) : Offset(x + 3, 1));
    }
  }

  @override
  bool shouldRepaint(RulerPainter old) =>
      old.length != length || old.unit != unit || old.vertical != vertical;
}
