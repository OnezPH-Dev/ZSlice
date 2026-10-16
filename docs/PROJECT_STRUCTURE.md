# Project structure

lib/main.dart: startup; lib/app: navigation and themes; lib/core/persistence: Drift storage; lib/core/widgets: shared Solar icons and controls; lib/features/projects: models/repository/controller; lib/features/slicing: physical geometry; lib/features/document_import: validated imports and conversion; lib/features/editor: canvas and inspector; lib/features/export: rendering and writers; lib/features/settings: persistent defaults; lib/features/home: project dashboard. test/: domain, persistence, rendering and UI regression tests. docs/: specifications and actual progress.

Version 1.1 additions: app/desktop_frame.dart; features/slicing/text_layer.dart (+ generated JSON); features/editor/artwork_geometry.dart, interactive_poster.dart, crop_dialog.dart, text_editor_dialog.dart and editor_objects.dart. New regression files: test/artwork_geometry_test.dart and test/interactive_editor_test.dart.
