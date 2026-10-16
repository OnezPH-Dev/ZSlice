# ZSlice 1.1.3 — fit image to columns and rows

Version 1.1.3+5, 2026-10-15.

Set Columns and Rows in Print setup, select the image, then click **Fit to grid** in its toolbar. For example, 5 columns and 5 rows stretches the image to fill all 25 sheets. The tooltip shows the current column and row counts.

The action fills both dimensions of the poster and centers the image at the grid origin. It keeps the current crop and rotation, accounts for printable margins and overlap, and replaces earlier scale, stretch and offset adjustments. Undo/redo and project saving retain the result. After changing the grid again, click Fit to grid to fit the new dimensions. Fit to cell remains available for fitting inside one sheet.

Verification: all 147 tests pass, static analysis reports no issues, and formatting passes. New coverage checks 5 × 5 layouts, margins/overlap, cropped and rotated images, wide artwork, desktop/mobile button interactions, undo/redo and fitting again after changing rows.

Close the old application and launch the updated build. Extract the complete Windows ZIP and keep its executable, DLLs and data folder together. The Android APK is a development/debug build.
