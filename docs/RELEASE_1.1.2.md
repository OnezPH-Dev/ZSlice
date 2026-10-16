# ZSlice 1.1.2 — tooltip overlay and image edge resizing

Version 1.1.2+4, 2026-10-15.

The desktop frame now lives inside the router's navigation overlay. Minimize, maximize/restore and close tooltips can display normally on the dashboard, settings and editor, fixing the red “No Overlay widget found” error.

Select an image to reveal eight handles:

- Drag left/right to change width independently.
- Drag top/bottom to change height independently.
- Drag a corner to resize proportionally using the image's current proportions.

Side resizing keeps the opposite edge fixed and supports snapping. Directional mouse cursors indicate the available action. Width and height stretch can also be entered numerically under Print setup → Artwork. Fit artwork and Reset artwork restore the original proportions.

Independent dimensions survive saving, undo/redo and portable projects and use the same geometry for preview and export, including rotated and cropped images. Layout presets preserve the current image dimensions; importing a replacement resets its stretch. Existing projects default to their original proportions. Automatic DPI accounts for the most enlarged axis.

Verification: all 142 tests pass; formatting passes; static analysis reports no issues. New coverage reproduces the original overlay failure through the real app router and checks window-control tooltips across routed screens. Geometry, 100%/200% pointer interactions, mouse/touch editor interactions, fixed opposite edges, snapping, resize limits, persistence and rotated raster exports are covered.

Close the old app, extract the complete Windows ZIP and run zslice.exe. Keep the DLLs and data folder together. The Android APK is a development/debug build.
