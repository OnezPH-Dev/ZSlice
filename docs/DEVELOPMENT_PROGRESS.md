# Development progress

Implementation dates: 2026-10-13 to 2026-10-14 (Asia/Manila).

## Phase 1: foundation — implemented

Inspected the original counter template, platform configurations, assets, SDK and baseline analysis (passed). Preserved the project and supplied logos. Added feature-first modules, Material 3 light/dark themes, offline Inter, GoRouter, Riverpod dependency injection, real static Solar Bold Duotone SVGs, attribution and generated launcher icons. Added all ten planning/specification documents and preserved the master request.

## Phase 2: dashboard and storage — implemented and tested

SQLite through Drift; versioned JSON metadata; previous-snapshot recovery; serialized autosaves; create/open/rename/duplicate/delete; search and recent project cards; portable .zslice archives containing the original managed source; settings and reusable layout presets. Source copies are deliberately retained on deletion because duplicate projects share them.

## Phases 3–5: document editor and print configuration — implemented

Validated image and PDF imports, source thumbnails, PDF page selection, desktop drop target, non-destructive fit/drag/resize/quarter-turn rotation/crop/reset, viewport zoom/pan/fit/96-ppi view, undo/redo, grid, rulers, sheet boundaries, desktop inspector and mobile settings sheet. Grid/physical-size layouts; eight paper choices plus custom; orientation; zero/linked/independent margins; overlap presets/custom values; scissors placement/size/color; per-interior-edge cutting; five line styles; separate preview/export guide switches; four numbering formats, five placements, font size/color and two page orders; automatic/custom DPI. Colors accept a custom hexadecimal value. Defaults, units, theme, autosave and export-format preferences persist.

## Phase 6: slicing engine — implemented and tested

Pure millimetre-based geometry; exact usable-area and overlap calculations; deterministic tile rectangles; custom-size partial sheets; 1..20 dimensions; validation of nonfinite values, crop bounds, DPI, enums and invalid measurements. All paper/orientation combinations, 400-sheet plans, adjacent overlaps, numbering and ordering have automated tests.

## Phases 7–8: preview/export — implemented and tested

One shared artwork/guide renderer feeds full poster and individual sheet previews plus export. Sheet thumbnails are lazy. PDF page objects/JPEG streams are written incrementally to disk; PNG/JPEG ZIP and OOXML DOCX pages are added one at a time; progress and cancellation remove partial output. Desktop saves finalize a sibling staging file; mobile uses native save dialogs with a size bound. Native printing receives exact selected physical page dimensions. Independent pypdf parsing verified a four-page export and its MediaBoxes/image objects. Word exports contain raster page images, not editable text.

## Phase 9: advanced documents — partial

Installed-LibreOffice adapter implemented with signature validation and isolated temporary conversion profile. Missing converters and unsupported mobile Word conversion report explicit errors. No LibreOffice is installed on this host, so successful conversion is not verified. Batch workflows, source-PDF vector retention, multi-source layering and arbitrary-angle rotation remain unimplemented enhancements.

## Phase 10: refinement — local verification, platform acceptance pending

Bounded source/bitmap memory, maximum output validation, serialized writes, persistent load/save errors, desktop save-before-close and lifecycle autosave, disabled export until a source loads, drop-target suspension during modals, responsive UI checks and visual captures. Apple configuration included, but no Apple build claim. Physical printing and native dialogs still need acceptance testing on target devices. No release signing/distribution certification claim.

## Verification log

- Baseline and final flutter analyze: passed, no issues. Formatting check passed.
- Freezed, JSON and Drift generation: passed.
- Final full automated suite: 71 tests passed, including a complete 400-sheet streamed PDF export and cancellation cleanup.
- UI checks at 1440×940, 800×600 and 390×844: passed, including editing and undo validation. Light/dark screenshots saved in docs/previews.
- Independent pypdf parsing: four-page output with one image per page and 100 mm MediaBoxes; 400-sheet stress output also parsed successfully with all 400 pages. python-docx parsed the DOCX with four anchored drawings and 99.995 mm square pages (OOXML twip rounding). Actual Word pagination/printing remains an acceptance test.
- Final Windows release build: passed (107.9 s). An earlier debug install collided with an already-running debug executable; release output was verified independently.
- Final Android debug APK build: passed (38.6 s), including native logo and final renderer changes.
- iOS/macOS: source configurations only, require macOS/Xcode build and device verification.

## Files created and modified

- lib/app/app.dart and lib/app/theme/app_theme.dart: router, themes and design tokens.
- lib/core/persistence/database.dart (+ generated .g.dart): database schema.
- lib/core/widgets/{app_icons,configuration_controls,dialogs}.dart: reusable controls, Solar icons and feedback.
- lib/features/projects/{project,project_repository,providers,project_archive}.dart (+ generated files): models, repositories, DI and portable archives.
- lib/features/slicing/{print_config,slicing_plan}.dart (+ generated configuration JSON): canonical settings and physical geometry.
- lib/features/document_import/{import_service,source_loader}.dart: signatures, thumbnails, converters and bounded rendering.
- lib/features/home/home_screen.dart: responsive persistent dashboard.
- lib/features/editor/{editor_controller,editor_screen,editor_canvas,editor_inspector,configuration_inspector,poster_renderer}.dart: application state and workspace.
- lib/features/export/{export_service,export_dialog,pdf_stream_writer,save_output}.dart: incremental writers, progress, cancellation, destination and print UI.
- lib/features/settings/settings_screen.dart and lib/main.dart: persistent preferences and startup.
- test/{slicing_plan,persistence,import_and_controller,export,ui}_test.dart: domain, repository, rendering and responsive regression tests.
- assets/fonts/{Inter.ttf,OFL.txt}, flutter_launcher_icons.yaml, pubspec.yaml/lock: offline typography, icon generation and compatible dependencies.
- Android/iOS/Windows metadata and native icons, new macOS runner with file entitlements, README.md and docs/*.md.


## Version 1.1.0 (2026-10-14)

Added custom desktop chrome, direct image selection and proportional corner resizing, interactive crop, physical snapping and alignment, fit-to-cell, editable text layers, text-only projects/exports, object selection panel, duplicate/delete and keyboard nudging. Switched branding and launcher generation to assets/ZSlice Logo.png. Audited gesture, save/undo, recovery, preset and responsive behavior; see RELEASE_1.1.md for concrete fixes and usage. Existing project files receive empty text layers and snapping enabled by default.

Final verification: flutter analyze passed with no issues; all 96 regression tests passed; formatting passed. Windows x64 release build passed (122.0 s); Android debug APK passed (39.9 s). Responsive checks cover 1440×940, 1100×600, 800×600, 844×390, 390×844 and 320×568. Native desktop button calls, pointer-down drag behavior, 100%/200% resizing, two-finger pinch, crop handles, text editing and text-only PDF/ZIP/DOCX exports are covered. Apple builds and real printer/native-dialog acceptance remain unverified on this Windows host.

## Version 1.1.1 (2026-10-15)

Fixed the reproduced image click/deselect conflict and a runtime print setup crash caused by expansion state colliding with input scroll offsets. Added inline configuration validation, consistent units, focused-field undo synchronization, layout mode dimension transfer, stable toolbar geometry, keyboard-aware mobile setup with Done, live object selection in the setup panel, responsive crop content, desktop Print and correct PDF print filenames. Added text-only export-on-open and export reentry guards, selection reconciliation and tiny-paper export validation. See RELEASE_1.1.1.md.

Verification: all 120 tests passed; flutter analyze reports no issues. New regression coverage reproduces both selection failures at the full workspace level, expands and reopens every setup section at four screen sizes in both themes, checks focused undo, presets, units, rejected paper selections, keyboard insets and input isolation, and simulates native printing with a remembered non-PDF export format. The original import, persistence, geometry, export and 400-sheet tests continue to pass. Captured and inspected light/dark desktop and mobile setup previews.

Final native builds: Windows x64 release passed (71.1 s); Android debug APK passed (40.9 s). Packaged version 1.1.1+3 in releases/ZSlice-1.1.1-Windows-x64.zip and releases/ZSlice-1.1.1-Android-debug.apk. Verified required Windows runtime/data entries, packaged version and APK copy; SHA256SUMS-1.1.1.txt records both checksums. The running development window must be restarted to load the updated application.

## Version 1.1.2 (2026-10-15)

Moved the desktop frame from MaterialApp.builder into a GoRouter ShellRoute so the title-bar tooltips have a Navigator overlay ancestor. The app-root regression first reproduced the reported red error, then verified successful hover tooltips on the dashboard, settings and editor after the fix.

Added image edge handles for independent width/height resizing, directional cursors, anchored opposite edges and snapping. Persisted stretchX/stretchY default to 1 for existing projects; regenerated configuration JSON. Updated image bounds, quarter-turn rendering, DPI estimation, import/reset, artwork controls and preset exclusions so dimensions remain consistent throughout the application.

Verification: all 142 automated tests pass; formatting passes. Coverage includes full-app tooltips, edge handles at 100%/200% zoom, full-editor mouse/touch resizing with undo/redo, rotated geometry and raster exports, saved dimensions, snapping and positive resize limits. Inspected app-root dark and light/dark editor previews with all eight image handles.

Final static analysis: no issues. Windows release build passed (103.2 s); Android debug build passed (51.0 s). Packaged 1.1.2+4 Windows ZIP and Android debug APK in releases, verified Windows runtime entries and executable version, checked APK identity/version and copy, and wrote SHA256SUMS-1.1.2.txt. The previous app window must be closed and the updated build launched.

## Version 1.1.3 (2026-10-15)

Added Fit to grid beside Crop image in the selected image toolbar. It fills the entire current poster width and height, using the configured rows, columns, printable margins and overlap. The operation resets previous positioning/scale/stretch while preserving crop and rotation; it is a single undoable document change. The tooltip identifies the current grid dimensions. Fit to cell remains available.

Verification: all 147 tests pass; flutter analyze reports no issues; formatting passes. Added geometry checks for 5 × 5 with crop, rotation, margins and overlap, a wide artwork case, and full desktop/mobile workflows that enter 5 columns and 5 rows, click the button, undo/redo, change rows and fit again. Visually inspected the updated image toolbar.

Windows release build passed (82.5 s); Android debug build passed (25.7 s). Packaged and verified 1.1.3+5 Windows ZIP and Android debug APK, including runtime entries, application versions and checksums in releases/SHA256SUMS-1.1.3.txt.

## Version 1.1.4 (2026-10-16)

Removed the maximize/restore button and its window-state listener from the custom title bar. DesktopFrame is now stateless, retaining Minimize, Close and the draggable title area. Desktop initialization is awaited in sequence: configure the hidden native title bar and minimum size, maximize, show and focus. Removed the fixed startup size and centering because the app starts maximized.

All 148 automated tests pass, including the updated desktop controls checks and a native-channel test ensuring maximize is called before show. Formatting passes. Full application tooltip/navigation, responsive editing and export regressions continue to pass.

Static analysis of lib and test reports no issues. Windows release build passed (186.7 s). Packaged version 1.1.4+6 as releases/ZSlice-1.1.4-Windows-x64.zip, verified executable version and runtime/data entries, and recorded its checksum in SHA256SUMS-1.1.4.txt.

## Version 1.1.5 (2026-10-16)

Corrected the Windows runner's first-frame callback: Win32Window::Show used SW_SHOWNORMAL, which could undo the Dart startup maximize request. Changed it to SW_SHOWMAXIMIZED. The prior mocked startup test did not exercise this native callback.

Windows release build passed (55.5 s). All 19 startup/editor regression tests pass. Launched the real Release executable through the computer-use skill and checked the native Windows system menu: Restore enabled; Maximize, Move and Size disabled. This confirms the OS reports maximized after Flutter renders. Closed only the release instance opened for verification and left the user's existing Debug instance untouched. Native runner changes require a full restart/rebuild; hot reload is insufficient.

