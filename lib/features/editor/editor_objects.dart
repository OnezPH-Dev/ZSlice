part of 'editor_screen.dart';

mixin _EditorObjects on State<EditorWorkspace> {
  EditorController get editor;
  String? get selectedLayer;
  set selectedLayer(String? id);
  bool get select;
  set select(bool value);
  void update(Map<String, dynamic> values);
  void chooseLayer(String? id) => setState(() {
    selectedLayer = id;
    select = id != null;
  });
  TextLayer? get selectedText {
    for (final text in editor.project.config.texts) {
      if (text.id == selectedLayer) return text;
    }
    return null;
  }

  Future<void> addText() async {
    try {
      final p = editor.plan;
      final layer = await editTextLayer(
        context,
        TextLayer(
          id: 'text-${DateTime.now().microsecondsSinceEpoch}',
          x: p.width / 4,
          y: p.height / 3,
          width: p.width / 2,
        ),
      );
      if (layer != null && mounted) {
        editor.putText(layer);
        chooseLayer(layer.id);
      }
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  Future<void> editSelected() async {
    if (selectedLayer == 'image' && editor.image != null) {
      final crop = await cropImage(
        context,
        editor.image!,
        editor.project.config,
      );
      if (crop != null && mounted) update(crop);
    } else if (selectedText case final text?) {
      final layer = await editTextLayer(context, text);
      if (layer != null && mounted) editor.putText(layer);
    }
  }

  void deleteSelection() {
    if (selectedLayer == 'image') {
      editor.removeImage();
    } else if (selectedLayer != null) {
      editor.deleteText(selectedLayer!);
    }
    chooseLayer(null);
  }

  void duplicateSelection() {
    final text = selectedText;
    if (text == null) return;
    final copy = text.change({
      'id': 'text-${DateTime.now().microsecondsSinceEpoch}',
      'x': text.x + 10,
      'y': text.y + 10,
    });
    editor.putText(copy);
    chooseLayer(copy.id);
  }

  void alignSelection(String alignment) {
    final p = editor.plan;
    PhysicalRect? box;
    if (selectedLayer == 'image' && editor.image != null) {
      box = ArtworkGeometry.bounds(
        p,
        editor.image!.width,
        editor.image!.height,
      );
    } else if (selectedText case final text?) {
      final r = PosterRenderer.textBounds(text);
      box = PhysicalRect(r.left, r.top, r.width, r.height);
    }
    if (box == null) return;
    final x = switch (alignment) {
      'left' => 0.0,
      'right' => p.width - box.width,
      'centerX' => (p.width - box.width) / 2,
      _ => box.x,
    };
    final y = switch (alignment) {
      'top' => 0.0,
      'bottom' => p.height - box.height,
      'centerY' => (p.height - box.height) / 2,
      _ => box.y,
    };
    if (selectedLayer == 'image') {
      update(
        ArtworkGeometry.place(
          p,
          PhysicalRect(x, y, box.width, box.height),
          editor.image!.width,
          editor.image!.height,
        ).toJson(),
      );
    } else {
      editor.putText(selectedText!.change({'x': x, 'y': y}));
    }
  }

  void fitToCell() {
    final image = editor.image;
    if (image == null) return;
    final p = editor.plan;
    final box = ArtworkGeometry.bounds(p, image.width, image.height);
    final cx = box.x + box.width / 2, cy = box.y + box.height / 2;
    final tiles = p.tiles.toList()
      ..sort((a, b) {
        double distance(Tile t) =>
            math
                .pow(t.posterRect.x + t.posterRect.width / 2 - cx, 2)
                .toDouble() +
            math
                .pow(t.posterRect.y + t.posterRect.height / 2 - cy, 2)
                .toDouble();
        return distance(a).compareTo(distance(b));
      });
    final tile = tiles.first.posterRect;
    final w = math.min(tile.width, p.width - tile.x),
        h = math.min(tile.height, p.height - tile.y);
    final factor = math.min(w / box.width, h / box.height);
    update(
      ArtworkGeometry.place(
        p,
        PhysicalRect(
          tile.x + (w - box.width * factor) / 2,
          tile.y + (h - box.height * factor) / 2,
          box.width * factor,
          box.height * factor,
        ),
        image.width,
        image.height,
      ).toJson(),
    );
  }

  void fitToGrid() {
    final image = editor.image;
    if (image == null || editor.busy) return;
    try {
      update(
        ArtworkGeometry.fitToGrid(
          editor.plan,
          image.width,
          image.height,
        ).toJson(),
      );
    } catch (e) {
      showError(context, e);
    }
  }

  void nudge(double dx, double dy) {
    if (selectedLayer == 'image') {
      update({
        'offsetX': editor.project.config.offsetX + dx,
        'offsetY': editor.project.config.offsetY + dy,
      });
    } else if (selectedText case final text?) {
      editor.putText(text.change({'x': text.x + dx, 'y': text.y + dy}));
    }
  }

  Widget objectToolbar() {
    if (selectedLayer == null) {
      return SizedBox(
        height: 52,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Click an image or text to edit it',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ),
      );
    }
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Text(
                selectedLayer == 'image' ? 'Image' : 'Text',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(width: 12),
              TextButton.icon(
                onPressed:
                    editor.busy ||
                        (selectedLayer == 'image' && editor.image == null)
                    ? null
                    : editSelected,
                icon: selectedLayer == 'image' ? AppIcons.crop : AppIcons.edit,
                label: Text(
                  selectedLayer == 'image' ? 'Crop image' : 'Edit text',
                ),
              ),
              if (selectedLayer == 'image') ...[
                Tooltip(
                  message:
                      'Fill all ${editor.plan.columns} columns × ${editor.plan.rows} rows',
                  child: TextButton.icon(
                    onPressed: editor.image == null || editor.busy
                        ? null
                        : fitToGrid,
                    icon: AppIcons.grid,
                    label: const Text('Fit to grid'),
                  ),
                ),
                TextButton(
                  onPressed: editor.image == null ? null : fitToCell,
                  child: const Text('Fit to cell'),
                ),
              ],
              PopupMenuButton<String>(
                tooltip: 'Align selection',
                icon: AppIcons.align,
                onSelected: alignSelection,
                itemBuilder: (_) => [
                  for (final item in {
                    'left': 'Align left',
                    'centerX': 'Center horizontally',
                    'right': 'Align right',
                    'top': 'Align top',
                    'centerY': 'Center vertically',
                    'bottom': 'Align bottom',
                  }.entries)
                    PopupMenuItem(value: item.key, child: Text(item.value)),
                ],
              ),
              FilterChip(
                label: const Text('Snap to grid'),
                selected: editor.project.config.snap,
                showCheckmark: false,
                onSelected: (v) => update({'snap': v}),
              ),
              if (selectedText != null)
                ToolButton(
                  label: 'Duplicate text',
                  icon: AppIcons.copy,
                  onPressed: duplicateSelection,
                ),
              ToolButton(
                label: 'Delete selected object',
                icon: AppIcons.delete,
                onPressed: deleteSelection,
              ),
              ToolButton(
                label: 'Deselect / pan',
                icon: AppIcons.close,
                onPressed: () => chooseLayer(null),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
