# ZSlice 1.1.1 — editor and print setup fixes

Released 2026-10-15. Version 1.1.1+3.

- Clicking an image or text keeps its selection. Poster taps no longer trigger the workspace background's deselect handler. The contextual toolbar stays 52 pixels high so selection does not move the canvas.
- Expanding or reopening print setup sections no longer crashes. Numeric and hexadecimal inputs have independent scroll controllers, preventing Flutter from treating the section's saved expansion flag as a scroll offset.
- Invalid margins, overlap, crops and other measurements display validation beside the field and preserve the last valid print plan. Valid presets also clear invalid drafts when reapplying the current setting.
- Rejected paper choices restore the actual configured paper in the dropdown.
- Undo, redo and external changes update focused numeric fields. Typing a valid number retains its caret and precision.
- Switching from Grid to Physical size starts with the displayed poster dimensions. Switching back uses the current calculated rows and columns.
- Margins, overlap presets, paper dimensions and the editor footer follow the selected measurement unit.
- Mobile Print setup moves above the keyboard and has a persistent Done button. Object selection updates immediately inside the open panel.
- The crop dialog scrolls on small and landscape screens. Expansion arrows reflect section state.
- Desktop has a direct Print button. Printing always uses a PDF filename, including when the remembered export format is PNG, JPEG or Word. Print guidance now refers to the printer dialog.
- Repeated export requests are guarded. Text-only projects support export on opening from the project menu. Selection is cleared when its object is removed through undo, and keyboard object actions are ignored in sheet preview and modal workflows.
- Export rejects paper that would rasterize to zero pixels with a helpful error. Page numbering tolerates paper narrower than its usual inset.

## Verification

All 120 automated tests pass. Static analysis reports no issues. Tests include full-workspace image clicks on desktop and mobile, zoomed move/resize, two-finger pinch, text editing and keyboard isolation, crop interactions, undo/redo, persistence, import validation, portable projects, PDF/PNG/JPEG/Word export, cancellation and a 400-sheet PDF stress case.

Print setup sections are opened and reopened in both themes at 320×568, 390×844, 844×390 and 1440×940. Additional responsive tests cover 800×600 and 1100×600. The native printing test simulates the platform channel and verifies PDF bytes, filename, physical page size and completion. Physical printer output, Apple builds and successful external Word conversion still require their respective devices or software.

Updated Windows and Android artifacts are stored in `releases`. Extract the complete Windows ZIP and run `zslice.exe`; keep its DLLs and data folder together. Close the old application and launch the new build to use this update. The Android APK is a development/debug build.
