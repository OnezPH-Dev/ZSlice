# ZSlice by OnezPH

**Create. Slice. Print.** An offline Flutter application for turning an image or a PDF page into a poster printed across ordinary sheets. Application ID: `com.onezph.zslice`.

## Run

Verified toolchain: Flutter 3.38.7, Dart 3.10.7.

```powershell
flutter pub get
flutter run -d windows
# Or select an Android device:
flutter run -d <device-id>
```

## Workflow

1. Create a project or import JPG/JPEG, PNG, WebP or PDF.
2. Choose a source page for a multipage PDF.
3. Set a grid (1–20 rows/columns) or physical poster dimensions.
4. Choose paper/orientation, margins and overlap. Measurements follow your preferred inches, centimetres or millimetres.
5. Configure trim edges, scissors, five line styles, numbering and raster DPI.
6. Preview the assembled poster or navigate individual sheets.
7. Export PDF, PNG/JPEG ZIP or an image-based Word document. Choose a destination after rendering. Print at **100% / actual size** using the matching paper.

Projects and settings persist locally in SQLite. Source files are copied into application support storage. Recent projects can be renamed, duplicated, deleted and exported. Save a portable `.zslice` archive to move a project to another device. Undo/redo covers document and configuration changes. Desktop supports file drops; mobile uses a settings bottom sheet. Dark/system themes and offline Inter fonts are included. App icons use real **Solar Bold Duotone** SVG widgets, with attribution in Settings → licenses.

## Verification

```powershell
dart run build_runner build --delete-conflicting-outputs
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build windows --release
flutter build apk --debug
```

Generated model/Drift files are included. Regenerate after changing model fields or database tables. Native launcher icons are generated from the supplied logo using `dart run flutter_launcher_icons`.

## Dependencies

The lockfile is part of the application. Drift 2.31.0, sqlite3 2.9.4 with native libraries, build_runner 2.10.4, json_serializable 6.11.2 and image 4.5.4 are deliberately pinned to a mutually compatible set for the installed Dart/Flutter SDK. Blindly upgrading only one can break generator or image/archive APIs. `file_selector` streams desktop saves through a staged sibling file; `file_picker` provides cross-platform imports and mobile saving. The PDF writer streams page objects to disk, using `pdf` physical-size constants and `printing` for native print integration.

## Current limits

- PDF source pages are rasterized, with a bounded resident source image. Vector-preserving PDF export is not implemented.
- Word import requires an installed LibreOffice at its standard desktop location. No converter is bundled; mobile users must convert to PDF first. This machine has no LibreOffice, so successful Word conversion is not verified here.
- Import file limit: 128 MB, image limit: 64 MP. Resident source decode: up to 24 MP. Export: up to 24 MP per sheet, processed sequentially. Mobile saving and native print jobs are limited to 128 MB.
- One source document/page per poster. Batch import/export, multi-source layering, arbitrary-angle rotation and source-PDF vector retention remain future enhancements. Rotation supports quarter turns; crop is non-destructive.
- Deleting a project removes its database record. Managed source copies are retained to protect shared references from duplicated projects; automatic garbage collection is not implemented.
- Apple builds need macOS/Xcode and signing. The macOS runner and file entitlements are included; iOS minimum deployment target is 14.0. Apple builds, external Word conversion and physical printer output still need platform acceptance testing.
- Android release signing remains a deployment step; the debug APK is for development testing. Windows release output must be distributed together with its DLLs and data directory.

See `docs/DEVELOPMENT_PROGRESS.md` for verified results and `docs/MASTER_SPECIFICATION.md` for the original request.

Version 1.1.1 fixes canvas deselection, print setup section crashes, measurement validation and focused-field undo. It also improves mobile setup and crop dialogs, preserves dimensions when switching layout modes, and adds a desktop Print button. See [release notes](docs/RELEASE_1.1.1.md).

Version 1.1.2 fixes the desktop title-bar tooltip overlay error and adds independent image resizing from all four sides. Drag the left/right handles to change width, top/bottom to change height, or corners to resize proportionally. These dimensions are saved and exported. See [release notes](docs/RELEASE_1.1.2.md).

Version 1.1.3 adds **Fit to grid** in the selected image toolbar. Set Columns and Rows in Print setup, select the image, then click Fit to grid to fill the whole layout. A 5 × 5 grid fills all 25 sheets. See [release notes](docs/RELEASE_1.1.3.md).

Version 1.1.4 opens the desktop application maximized automatically. The custom title bar now has Minimize and Close controls. See [release notes](docs/RELEASE_1.1.4.md).

Version 1.1.5 fixes a Windows runner override that restored the window to normal size after startup. The first-frame native show now explicitly opens maximized. See [release notes](docs/RELEASE_1.1.5.md).

## Object editing in 1.1

Click an image to reveal its selection handles and contextual crop/alignment tools. Snap to grid is enabled by default; drag/resize snaps to paper boundaries and center lines. Fit to cell fits proportionally inside the closest tile. Click Add text to create text with editable content, size, color, width, bold/italic and alignment. Text can be moved/resized directly, duplicated/deleted, undone/redone, saved and exported. A source image is optional for text-only posters. Arrow keys nudge selected objects by 1 mm, or 10 mm with Shift. See docs/RELEASE_1.1.md.

Desktop now uses a custom title bar. Fully restart the application after updating; hot reload alone does not rerun native window setup. The supplied assets/ZSlice Logo.png is used for app branding and native icons.
