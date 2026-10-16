# ZSlice by OnezPH

Offline-first Flutter poster slicer. Create. Slice. Print.

## Initial inspection (2026-10-13)
The existing project contains only the Flutter counter template and its test. Flutter 3.38.7 / Dart 3.10.7. Initial flutter analyze: no issues. Android namespace and application ID are com.onezph.zslice; iOS and Windows runners exist; macOS runner is absent. Two supplied logo PNGs are preserved. No existing fonts, architecture, navigation or functional document workflows.

## Implementation direction
Preserve the project and platform runners. Solar Bold Duotone SVG widgets are the application icon system (https://solar-icons.vercel.app/docs/v2/packages/flutter). Use offline assets, Riverpod state and dependency injection, GoRouter navigation, Drift/SQLite persistence and one canonical millimetre-based slicing plan for preview/export. Supported imports must validate actual data. Word import needs an installed conversion engine and cannot be promised on mobile.
