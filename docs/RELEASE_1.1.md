# ZSlice 1.1 — desktop controls and object editing

## Using the update

- Restart the desktop app to load the hidden native title bar. The custom bar supports drag-to-move, double-click maximize/restore, and minimize/maximize/restore/close buttons. Closing still saves the active project first and refuses to interrupt an active import/export.
- Click an image to select its actual bounds. Drag it to move it; drag any corner to resize proportionally. Double-click the image or choose **Crop image** to edit a non-destructive crop. Crop supports moving the crop, resizing its corners, drawing a replacement rectangle, reset, apply and cancel.
- **Snap to grid** aligns edges/centers with paper boundaries and poster center lines within eight screen pixels. Alignment guides appear while dragging. **Fit to cell** fits the image proportionally inside the closest sheet region. The alignment menu provides six edge/center actions.
- **Add text** creates an editable text layer. Set its content, size, width, color, bold/italic and alignment. Drag and resize it on the poster. The Objects inspector selects obscured objects. Duplicate/delete text and undo/redo changes. Arrow keys nudge by 1 mm; Shift+arrow moves 10 mm. Delete removes the selected object; text input fields retain their normal editing behavior.
- A blank project can contain only text. Text uses the same physical millimetre coordinates and shared renderer for poster, sheet preview, PDF, DOCX and image ZIP. Word output continues to contain page images; the ZSlice project stores editable text layers.
- The supplied `assets/ZSlice Logo.png` now appears in app branding, the empty editor, desktop chrome and native launcher icons. Solar Bold Duotone remains the icon system.

## Responsive UI

Context controls occupy a stable row so selecting an object does not shift the canvas mid-gesture. Phone Print setup remains fixed while tools scroll. Narrow branding and sheet navigation avoid overflow. Short windows switch to the compact inspector pattern; empty canvas content scrolls and preview thumbnails shrink in landscape. Two-finger pinch zoom works over selected artwork, and dragging outside the poster pans the workspace.

## Audit fixes

| Issue | Result |
| --- | --- |
| Selection handles outlined the entire poster | Handles follow the actual cropped/rotated source bounds. |
| Zoom-dependent drag delta and gesture threshold lag | Document movement uses global pointer distance, viewport scale and pointer-down origin; tested at 100% and 200%. |
| Resize handles at poster edges were hard to hit | Handles stay inside the hit-testable canvas region. |
| Gesture cancellation could run setState during a rebuild | Cancellation safely defers its visual refresh. |
| Source import could replace edits made while loading | Commit uses the latest project configuration; busy undo/redo is blocked. |
| Repeated input submission added empty undo steps | Identical configurations do not create undo entries. |
| Save indicator could show idle with writes still queued | Pending saves are counted until the queue drains. |
| Applying a layout preset could replace artwork/text | Presets preserve current source transforms and text layers. |
| Recovered data could be overwritten with a corrupt backup | Subsequent saves retain a validated recovery snapshot. |
| Missing image plus text could export an incomplete poster | Export stays disabled until the source is loaded or explicitly removed. |
| Vertical rulers counted upward from the bottom | Rulers now share the poster's top-left origin. |
| Small phones/landscape overflowed | Compact header, flexible sheet label, height-aware layout and scrolling empty state. |
| Custom hexadecimal color applied only after Enter | Valid six-digit colors update immediately. |

## Verification

Final analysis, regression count and native build results are recorded in DEVELOPMENT_PROGRESS.md. Coverage includes physical geometry/snapping, zoomed drag/resize, crop editing, text CRUD/undo, text-only export, recovery persistence, native window method calls, responsive light/dark layouts and the existing 400-page export stress test. Native window API calls are tested through a mocked platform channel; OS interactions, physical printers and Apple builds still need target-platform acceptance testing.
