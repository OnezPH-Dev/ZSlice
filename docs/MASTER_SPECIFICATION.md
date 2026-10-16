# ZSLICE — MASTER FLUTTER DEVELOPMENT PROMPT

**Project:** ZSlice — Document & Poster Slicer  
**Developer/Brand:** OnezPH  
**Application Identifier:** `com.onezph.zslice`  
**Flutter Project:** `zslice`  
**Tagline:** Create. Slice. Print.  
**Target Platforms:** Android, iOS, Windows, macOS  
**Development Approach:** Production-ready, scalable, offline-first, cross-platform application

---

# 1. YOUR ROLE

Act as a team of expert software engineers consisting of:

- Senior Flutter and Dart Architect
- Senior Flutter UI/UX Engineer
- Cross-Platform Desktop and Mobile Developer
- Document Rendering and PDF Processing Engineer
- Printing and Image Processing Specialist
- Software Quality Assurance Engineer
- Accessibility and Performance Optimization Specialist

Your task is to **design, architect, implement, test, and refine the complete ZSlice application** inside the existing Flutter project.

Do not create another Flutter project unless the existing project is invalid and cannot be repaired.

Use the existing `zslice` directory.

The implementation must contain functional application features, proper state management, reusable components, maintainable architecture, and platform-specific integrations.

Avoid placeholder functionality, decorative-only controls, mock exports, or incomplete workflows being presented as functional.

If a feature requires an unavailable third-party conversion engine, create a clean interface, implement supported adapters, and explicitly document the limitation instead of silently pretending it works.

---

# 2. PROJECT DESCRIPTION

ZSlice is an offline-first document and poster slicing application that allows users to import images and documents, arrange them on a customizable canvas, divide them into printable paper sections, preview every sliced page, and export print-ready documents.

The application is inspired by tools such as DocuSlice but must have an original, modern, responsive, and professional user interface.

The primary purpose is to make large-format printing accessible using ordinary printers and bond paper.

Example use cases:

1. A teacher imports a classroom poster and slices it across nine short bond papers.
2. A student imports a PDF and creates a multi-page educational tarpapel.
3. A business owner creates a promotional poster with a custom physical width and height.
4. A user imports a picture and prints it as a large wall decoration.
5. A user selects a 4-column × 3-row layout, previews all 12 sheets, and exports the result as PDF.
6. A user enables scissors indicators, dashed cutting lines, page numbers, and overlap guides before exporting.
7. A user changes the output DPI and paper margins and sees the calculated printable layout update.

The app must be intuitive for beginners while providing precise controls for advanced users.

---

# 3. FIRST TASK — ANALYZE THE EXISTING PROJECT

Before writing or modifying code:

1. Inspect the complete existing Flutter project.
2. Read `pubspec.yaml`.
3. Inspect the current `lib/` structure.
4. Identify existing dependencies.
5. Inspect Android, iOS, Windows, and macOS configurations.
6. Identify existing assets, logos, and fonts.
7. Check Flutter and Dart SDK versions.
8. Inspect existing themes and navigation.
9. Identify incomplete or duplicated implementations.
10. Run Flutter analysis and document existing issues.

Do not delete existing code without understanding its purpose.

Create these planning documents:

```text
docs/
├── PROJECT_OVERVIEW.md
├── ARCHITECTURE.md
├── PROJECT_STRUCTURE.md
├── DESIGN_SYSTEM.md
├── FUNCTIONAL_REQUIREMENTS.md
├── SLICING_ENGINE.md
├── EXPORT_SPECIFICATION.md
├── PLATFORM_SUPPORT.md
├── IMPLEMENTATION_PLAN.md
└── DEVELOPMENT_PROGRESS.md
```

These documents become the source of truth for all future implementation.

After completing initial analysis, proceed with the implementation in dependency order.

---

# 4. TECHNOLOGY STACK

Use:

**Framework**
- Flutter
- Dart
- Material Design 3

**Architecture**
- Feature-first architecture
- Clean Architecture principles
- Repository pattern
- Dependency injection through Riverpod

**State management**
- Flutter Riverpod

**Navigation**
- GoRouter

**Local persistence**
- Drift with SQLite
- JSON serialization for project metadata

**File handling**
- `file_picker`
- `path_provider`
- `path`

**PDF handling**
- `pdfrx` for PDF viewing/rendering
- `pdf` for PDF generation
- `printing` for print integration

**Image processing**
- `image` package
- Flutter CustomPainter
- Flutter canvas and transformation APIs

**Code generation**
- `freezed`
- `json_serializable`
- `build_runner`

**Desktop**
- `window_manager`
- Native OS file dialogs
- Drag-and-drop integration

Use current stable, mutually compatible package versions. Verify package APIs and platform support before implementation.

Avoid adding dependencies without a clear purpose.

---

# 5. APPLICATION DESIGN PRINCIPLES

The design must be:

- Modern
- Clean
- Minimal
- Professional
- Responsive
- Consistent
- Accessible
- Easy to navigate
- Optimized for productivity
- Visually balanced

Use a design direction inspired by modern creative applications such as Figma, Canva, and professional document editors.

Do not copy these applications directly.

## 5.1 Color Palette

Primary: `#4F46E5`  
Primary Hover: `#4338CA`  
Primary Light: `#EEF2FF`

Accent: `#06B6D4`  
Accent Hover: `#0891B2`

Text Primary: `#0F172A`  
Text Secondary: `#64748B`

Background: `#F8FAFC`  
Surface: `#FFFFFF`

Border: `#E2E8F0`  
Divider: `#E5E7EB`

Success: `#16A34A`  
Warning: `#F59E0B`  
Error: `#DC2626`

Provide a complete matching dark theme.

Do not hardcode arbitrary colors inside screens and components.

## 5.2 Typography

Use Inter or Plus Jakarta Sans.

Define centralized typography tokens for:

- Display
- Page title
- Section heading
- Subheading
- Body
- Label
- Caption
- Button
- Numeric input

Maintain consistent weights, letter spacing, and line heights.

## 5.3 Spacing

Use a four-pixel base system.

Supported spacing tokens:

```text
4
8
12
16
20
24
32
40
48
64
```

Centralize padding, margin, gaps, and border radii.

## 5.4 Reusable Components

Build reusable components for:

- Primary buttons
- Secondary buttons
- Icon buttons
- Outlined buttons
- Toggle switches
- Checkboxes
- Segmented controls
- Dropdown selectors
- Numeric fields
- Measurement input fields
- Sliders
- Inspector sections
- Tooltips
- Confirmation dialogs
- Bottom sheets
- File picker panels
- Settings panels
- Progress indicators
- Empty states
- Error messages
- Toast notifications
- Context menus
- Sidebar navigation
- Document thumbnails
- Paper preview cards

All interactive elements must have appropriate hover, focus, selected, disabled, loading, and error states.

---

# 6. RESPONSIVE APPLICATION LAYOUT

ZSlice must support both desktop and mobile interaction patterns.

## 6.1 Desktop Layout

For Windows and macOS, create a professional document editor layout.

### Top Application Bar

Include:

- ZSlice app icon
- Project name
- Save status
- Undo
- Redo
- Import
- Preview
- Export
- Application menu

### Left Toolbar

Include tools for:

- Select
- Pan
- Import
- Crop
- Fit image
- Grid
- Ruler
- Layers, when supported

### Center Canvas

The main workspace must support:

- Imported document rendering
- Poster preview
- Grid overlays
- Ruler overlays
- Zooming
- Panning
- Dragging
- Resizing
- Cropping
- Selection handles
- Paper boundaries
- Cutting guides
- Page numbers

### Right Inspector

Create categorized settings sections:

1. Document
2. Layout
3. Paper
4. Margins
5. Overlap
6. Cutting Indicators
7. Cutting Lines
8. Page Numbering
9. DPI
10. Export

Allow sections to expand and collapse.

### Bottom Status Bar

Show:

- Zoom percentage
- Grid dimensions
- Total pages
- Selected paper
- Poster dimensions
- Current page or tile
- Export warnings

## 6.2 Mobile Layout

For Android and iOS:

- Use a compact top application bar.
- Maximize available canvas space.
- Use a bottom toolbar or floating action controls.
- Open inspector settings through bottom sheets.
- Support pinch-to-zoom.
- Support two-finger panning.
- Provide large touch targets.
- Respect platform safe areas.
- Use modal dialogs for export settings.
- Allow landscape orientation.
- Prevent the keyboard from unnecessarily covering settings.

Do not simply shrink the desktop application.

Create proper mobile layouts using the same shared state and feature logic.

---

# 7. HOME SCREEN

Design a clean project dashboard.

Include:

### Header

- ZSlice branding
- Settings
- Theme control

### Primary Actions

- New Project
- Import Document
- Open Existing Project

### Recent Projects

Display project cards with:

- Thumbnail
- Project name
- Last modified date
- Paper size
- Grid size
- Number of printable pages

### Project Actions

- Open
- Rename
- Duplicate
- Delete
- Export

### Empty State

For new installations, show a welcoming illustration or app icon with an obvious Create Project action.

All project actions must work with real persistent data.

---

# 8. DOCUMENT IMPORT SYSTEM

Users must be able to import:

- JPG
- JPEG
- PNG
- WebP
- PDF
- DOC
- DOCX

Support file selection and desktop drag-and-drop where available.

## Import Behavior

1. User selects a document.
2. Validate file format and signature.
3. Inspect the file.
4. Load document metadata.
5. Generate a thumbnail.
6. Create or update the active project.
7. Show the document in the editor.
8. Automatically calculate an initial fit.

For multiple-page PDFs, provide source-page selection.

For DOC/DOCX, implement a document conversion abstraction. Accurately converting Word files requires a compatible document layout engine.

On Windows/macOS, evaluate an appropriate installed or bundled converter such as LibreOffice, subject to platform distribution requirements.

On Android/iOS, investigate verified native/offline conversion support. Do not advertise Word import as fully supported until the chosen conversion strategy actually works.

Never change the user's original document.

---

# 9. DOCUMENT CANVAS

Implement a high-performance interactive editor canvas.

## Canvas Features

- Zoom in
- Zoom out
- Fit to screen
- Actual size view
- Pan
- Center document
- Drag document
- Scale document
- Rotate document
- Crop document
- Reset transformation
- Show/hide grid
- Show/hide rulers
- Show/hide paper boundaries

Use appropriate transformation matrices.

Keep canvas transformations independent from document source data.

Changes must update the rendered preview without modifying imported file bytes.

## Canvas Rendering

Use separate layers:

```text
Workspace Background
    ↓
Poster Background
    ↓
Imported Document
    ↓
Document Transformation
    ↓
Paper Tile Boundaries
    ↓
Overlap Guides
    ↓
Cutting Lines
    ↓
Scissors Indicators
    ↓
Page Numbers
    ↓
Rulers
    ↓
Selection Handles
```

Not all editor overlays should be automatically included in exported files.

Provide separate controls for preview visibility and export visibility where appropriate.

---

# 10. LAYOUT SYSTEM

Implement three layout modes.

## 10.1 Grid Mode

Users define:

- Rows: minimum 1, maximum 20
- Columns: minimum 1, maximum 20

The system must calculate the resulting page count.

Example:

```text
Rows: 4
Columns: 3

Total Printable Pages: 12
```

Update the preview immediately.

## 10.2 Custom Size Mode

Allow the user to enter:

- Poster width
- Poster height
- Measurement unit

Supported units:

- Inches
- Centimeters
- Millimeters

The system calculates how many printable sheets are required.

Take margins and overlap into account.

If the layout requires more than 20 rows or 20 columns, display a clear validation message.

## 10.3 Custom Layout Presets

Users can save and reuse settings such as:

- Layout name
- Poster dimensions
- Grid configuration
- Paper size
- Orientation
- Margins
- Overlap
- Cutting guides

Allow presets to be edited and deleted.

---

# 11. PAPER CONFIGURATION

Include the following:

| Paper | Dimensions |
|---|---|
| Short Bond | 8.5 × 11 inches |
| Long Bond | 8.5 × 13 inches |
| Legal | 8.5 × 14 inches |
| A4 | 210 × 297 mm |
| A3 | 297 × 420 mm |
| A5 | 148 × 210 mm |
| Tabloid | 11 × 17 inches |
| Custom | User-defined |

Support:

- Portrait
- Landscape

Orientation changes must immediately recalculate the printable layout.

Internally use a consistent physical measurement system, preferably millimeters.

---

# 12. MARGIN SETTINGS — REQUIRED

Implement a configurable margin feature.

## Interface

Section title: **Margins**

Provide:

```text
Margins

[ Off / 0" ] [ Custom ]

Top       [ 0.00 ] in
Right     [ 0.00 ] in
Bottom    [ 0.00 ] in
Left      [ 0.00 ] in

[✓] Link all sides
```

### Margin OFF

When disabled:

- Set all logical page margins to exactly zero.
- Use the entire physical sheet as the target printable canvas.
- Update the preview immediately.

Important: Explain that many physical printers cannot print to the edge of the sheet. A zero-margin PDF does not guarantee borderless printing.

### Margin ON

Allow either linked or independent margins.

Provide inch presets:

```text
0"
0.125"
0.25"
0.375"
0.5"
0.75"
1.0"
Custom
```

Allow decimal values.

Convert inches to millimeters:

```text
1 inch = 25.4 mm
```

Support input validation.

Margins must never result in zero or negative printable dimensions.

### Margin Rendering

When margin guides are visible:

- Display the paper boundary.
- Display the printable content boundary.
- Shade or distinguish margin areas.
- Ensure the crop geometry accounts for margins.

Margin preview and export must use exactly the same measurements.

---

# 13. SCISSORS CUTTING INDICATORS — REQUIRED

Implement an optional scissors icon feature.

## Interface

```text
Cutting Indicators

Scissors Icon       [ ON / OFF ]

Placement:
( ) All Cuttable Edges
( ) Selected Edges
( ) Corners Only

Icon Size:
[ Small ] [ Medium ] [ Large ]

Icon Color:
[ Black ] [ Gray ] [ Custom ]
```

### When OFF

- Do not display scissors symbols.
- Do not include scissors in exported documents.

### When ON

- Draw scissors symbols at applicable cutting locations.
- Position symbols consistently.
- Avoid obscuring important document content.
- Keep symbols inside permitted guide or margin regions where possible.

### Cut-Side Selection

Provide a per-edge configuration:

```text
Top      [ ON / OFF ]
Right    [ ON / OFF ]
Bottom   [ ON / OFF ]
Left     [ ON / OFF ]
```

Determine which edges are interior seams and which are outer poster boundaries.

Do not automatically place a scissors icon on every outer page boundary.

For tiled printing, scissors should normally indicate the selected trimming edges involved in assembly.

### Canvas Interaction

The user must be able to toggle this feature without regenerating the original document.

Icons should update immediately in preview.

---

# 14. CUTTING LINES — REQUIRED

Implement independent cutting-line settings.

## Interface

```text
Cutting Lines

Enable Lines        [ ON / OFF ]

Line Style:
( ) Solid
( ) Dashed
( ) Dotted
( ) Dash-Dot
( ) Corner Marks

Thickness:
[ 0.25 ] pt

Color:
[ Black ]

Show in Preview     [ ON / OFF ]
Include in Export   [ ON / OFF ]
```

### Line Styles

Support:

1. Solid
2. Dashed
3. Dotted
4. Dash-dot
5. Corner crop marks

Use vector paths where supported.

### Line Rules

- Line placement must align with calculated cut boundaries.
- Cutting lines must remain independent from editor grid lines.
- Turning grid visibility off must not automatically turn cutting lines off.
- Cutting lines should not be part of the imported document itself.
- Prevent inappropriate lines from obscuring essential content.
- Apply consistent line thickness in physical export units.

Provide preview and export switches independently.

### Edge Configuration

Allow:

- All interior cut edges
- Top only
- Right only
- Bottom only
- Left only
- Custom combination

Coordinate these settings with scissors indicators.

For example:

```text
Cut Right Edge: ON
Scissors Icon: ON
Cutting Line: Dashed
```

The right edge should display the selected trim guide and optional scissors symbol.

---

# 15. PAGE NUMBERING — REQUIRED

Provide configurable page numbering.

## Interface

```text
Page Numbers

Enable Numbering       [ ON / OFF ]

Number Format:
( ) 1, 2, 3...
( ) Page 1 of 12
( ) R1-C1
( ) Row 1 / Column 1

Position:
( ) Top Left
( ) Top Right
( ) Bottom Left
( ) Bottom Right
( ) Bottom Center

Font Size:
[ 10 ] pt

Color:
[ Black ]
```

### Behavior

When disabled:

- No numbering should appear in exports.
- Hide page labels in the printable preview, while allowing separate editor-only tile identifiers.

When enabled:

- Number every printable sheet.
- Keep the numbering stable.
- Follow the selected page ordering.
- Update numbering when rows or columns change.

For example, a 3×3 grid:

```text
R1-C1   R1-C2   R1-C3
R2-C1   R2-C2   R2-C3
R3-C1   R3-C2   R3-C3
```

Support row-major and column-major order.

Keep printed labels clear of the actual poster artwork whenever possible.

---

# 16. DPI SETTINGS — REQUIRED

Create an optional DPI control for raster export rendering.

## Interface

```text
Export Resolution

DPI Mode     [ Auto / Custom ]

Presets:
[ 72 ] [ 96 ] [ 150 ] [ 300 ] [ 600 ]

Custom DPI:
[ 300 ]

Estimated Output Size:
...

Image Quality:
...
```

### Auto Mode

When automatic:

- Choose an appropriate resolution using output purpose and available source resolution.
- Use reasonable defaults for print output.
- Avoid unnecessarily allocating very large bitmaps.
- Display the effective selected DPI before export.

### Custom Mode

Allow users to select:

- 72 DPI
- 96 DPI
- 150 DPI
- 300 DPI
- 600 DPI
- Custom DPI

Validate custom values.

### Technical Rules

DPI applies to rasterization and image output.

For vector-preserving PDF content, avoid unnecessarily rasterizing the entire source.

Calculate raster dimensions as:

```text
Pixel Width = Physical Width in Inches × DPI
Pixel Height = Physical Height in Inches × DPI
```

Example:

```text
8.5 × 11 inches at 300 DPI

2550 × 3300 pixels
```

Warn users if a selected DPI causes:

- Very high memory consumption
- Extremely large output files
- Slow export operations
- Potential device limitations

Render tiles incrementally rather than keeping every exported page in memory.

---

# 17. OVERLAP SETTINGS — REQUIRED

Implement configurable paper overlap for assembling large posters.

## Interface

```text
Paper Overlap

Enable Overlap     [ ON / OFF ]

Overlap Amount:
[ 0.00 ] inches

Presets:
0"
0.125"
0.25"
0.375"
0.5"
0.75"
1.0"
Custom

Show Overlap Guide      [ ON / OFF ]
Highlight Overlap Area  [ ON / OFF ]
```

### Overlap OFF

When disabled:

- Set overlap to zero.
- Do not duplicate adjacent document regions.
- Disable overlap-specific export marks.

### Overlap ON

Allow a configurable amount measured in inches.

Support decimal input.

Convert to millimeters internally.

### Overlap Behavior

Adjacent sheets should contain duplicate artwork within the designated overlap band to help users align and glue or tape the sheets.

For example:

```text
Sheet 1        Sheet 2
|----------|   |----------|
| Artwork  |   | Artwork  |
|------XXXX|   |XXXX------|
       ↑
  Overlap region
```

The overlap geometry must be physically accurate.

### Important Geometry Rules

Define whether overlap is applied on:

- Right/bottom continuation edges
- Left/top continuation edges
- A selectable seam strategy

Choose a consistent default seam strategy.

When overlap is active, the effective poster coverage must account for duplicated regions.

For example, with a simple symmetric tiling model:

```text
Sheet Printable Width = 10 inches
Overlap = 0.5 inches

First Column Coverage = 10 inches
Each Additional Column Advances = 9.5 inches
```

Do not assume a 3-column poster covers 30 inches when overlap reduces the net advance.

### Overlap Preview

Show:

- Semi-transparent overlap bands
- Correct page boundaries
- Optional highlighted seam regions
- Corresponding adjacent tile sections

The preview must accurately represent exported content.

---

# 18. LIVE SLICING PREVIEW

Build two preview modes.

## Full Poster View

Display the assembled poster with:

- Document artwork
- Grid boundaries
- Optional rulers
- Optional margins
- Optional overlap highlights
- Optional cutting lines
- Optional scissors icons
- Optional page numbers

Provide:

- Fit to canvas
- Zoom percentage
- Zoom in/out
- Reset view
- Pan

## Individual Sheet View

Display each resulting printable sheet.

For example:

```text
Page 1    Page 2    Page 3
Page 4    Page 5    Page 6
Page 7    Page 8    Page 9
```

Allow:

- Single-page preview
- Multiple-page thumbnails
- Page selection
- Zooming
- Navigation between pages
- Preview with and without export guides

All page previews must be generated using the actual tile geometry.

---

# 19. SLICING ENGINE

The slicing engine is one of the most important components.

Implement it as a separate, testable domain module.

## Required Models

Create strongly typed models for:

```text
SourceDocument
SourcePage
PosterDimensions
PaperSpecification
PaperOrientation
LayoutConfiguration
MarginConfiguration
OverlapConfiguration
CuttingConfiguration
ScissorsConfiguration
NumberingConfiguration
DpiConfiguration
TileGeometry
SlicingPlan
ExportConfiguration
ExportJob
```

Prefer immutable models.

## Geometry Requirements

Use double-precision physical measurements.

Calculate:

1. Paper size
2. Orientation
3. Margin dimensions
4. Usable printable area
5. Overlap dimensions
6. Effective tile advance
7. Grid dimensions
8. Poster dimensions
9. Source crop coordinates
10. Per-page transformations
11. Cutting boundaries
12. Page label positions

Ensure deterministic results.

### Essential Formula

For paper width:

```text
Usable Width =
Paper Width - Left Margin - Right Margin
```

For paper height:

```text
Usable Height =
Paper Height - Top Margin - Bottom Margin
```

For overlap-based tiling, where the overlap is applied between consecutive sheets:

```text
Total Poster Width =
Usable Width × Columns
- Overlap Width × (Columns - 1)
```

```text
Total Poster Height =
Usable Height × Rows
- Overlap Height × (Rows - 1)
```

These formulas apply to the chosen uniform-overlap model; explicitly adapt the geometry if using one-sided trimming, asymmetric margins, or other seam strategies.

The preview and export engines must share the same generated `SlicingPlan`.

Do not duplicate geometry formulas across widgets.

---

# 20. EXPORT SYSTEM

Support the following formats:

- PDF
- DOCX
- PNG/JPEG images packaged as ZIP

Implement PDF first.

Implement image ZIP next.

Implement DOCX export using valid Word document packaging and explicit page dimensions.

## PDF Export

Create a PDF where:

- Every sliced section becomes a separate page.
- Pages use the selected physical paper size.
- Orientation is respected.
- Margins are respected.
- Overlap is accurately included.
- Cutting indicators follow export settings.
- Cutting lines follow export settings.
- Numbering follows export settings.
- DPI affects rasterized output only.
- Page order follows user settings.

PDF must be suitable for printing at 100% scale.

## DOCX Export

Create print-oriented Word documents containing the tiled page images.

Do not claim that text in the exported document is independently editable unless actual editable text layout has been implemented.

## Image Export

Export numbered image files:

```text
ZSlice_Project/
├── Page_001.png
├── Page_002.png
├── Page_003.png
└── ...
```

Package them as a ZIP archive.

## Export UI

Create a clean export dialog with:

- File format
- Paper information
- Page count
- Margins
- Overlap
- Cutting indicators
- Cutting lines
- Page numbering
- DPI
- Output destination
- File name
- Export button

Provide progress reporting and cancellation.

Use temporary files and atomic finalization to avoid leaving incomplete output presented as successful.

---

# 21. PROJECT MANAGEMENT

Users must be able to:

- Create project
- Open project
- Rename project
- Duplicate project
- Delete project
- Save project
- Reopen project
- Export project

Implement autosaving.

Save the following:

- Source file reference or managed copy
- Layout mode
- Rows and columns
- Custom poster size
- Paper settings
- Margin settings
- Overlap settings
- Scissors settings
- Cutting-line settings
- Numbering settings
- DPI settings
- Canvas transformations
- Preview preferences

Use versioned project data and robust recovery strategies.

---

# 22. APPLICATION SETTINGS

Create an application settings screen.

Include:

### Appearance

- Light mode
- Dark mode
- System theme

### Units

- Inches
- Millimeters
- Centimeters

### Defaults

- Default paper size
- Default orientation
- Default margin
- Default overlap
- Default DPI
- Default cutting guides

### Preferences

- Show rulers by default
- Show grid by default
- Auto-save
- Remember export configuration

### About

- Application name
- Version
- Developer OnezPH
- Licenses

Settings must persist across sessions.

---

# 23. PROJECT STRUCTURE

Use the following feature-first structure:

```text
lib/
├── main.dart
├── bootstrap.dart
│
├── app/
│   ├── app.dart
│   ├── router/
│   ├── theme/
│   └── responsive/
│
├── core/
│   ├── constants/
│   ├── extensions/
│   ├── errors/
│   ├── logging/
│   ├── services/
│   ├── persistence/
│   └── widgets/
│
├── features/
│   ├── home/
│   ├── projects/
│   ├── document_import/
│   ├── editor/
│   │   ├── data/
│   │   ├── domain/
│   │   ├── application/
│   │   └── presentation/
│   │       ├── screens/
│   │       ├── canvas/
│   │       ├── toolbar/
│   │       ├── inspector/
│   │       └── widgets/
│   │
│   ├── layout/
│   ├── paper/
│   ├── margins/
│   ├── overlap/
│   ├── cutting_guides/
│   ├── numbering/
│   ├── dpi/
│   ├── slicing/
│   ├── preview/
│   ├── export/
│   └── settings/
│
└── shared/
    ├── design_system/
    ├── models/
    └── utils/
```

Feature directories may be consolidated where doing so creates a clearer architecture, but maintain strict separation between domain calculations and UI.

Avoid unnecessary abstractions and giant files.

---

# 24. PERFORMANCE REQUIREMENTS

The application must handle up to 400 sliced sheets.

Implement:

- Lazy loading
- Thumbnail caching
- Memory-aware image decoding
- Incremental page rendering
- Background computation
- Export progress tracking
- Cancellation
- Proper disposal
- Bounded queues
- Responsive state updates

Do not render all 400 pages at export resolution simultaneously.

Prevent unnecessary widget rebuilds during zooming and panning.

---

# 25. TESTING REQUIREMENTS

Implement tests for:

### Layout

- 1×1 grid
- 3×3 grid
- 20×20 grid
- Custom poster dimensions
- Portrait/landscape
- Different paper sizes

### Margins

- Zero margins
- Linked margins
- Independent margins
- Custom inch values
- Invalid margins

### Cutting Indicators

- Scissors enabled
- Scissors disabled
- Individual cut-side selection
- Correct symbol positioning

### Lines

- Solid
- Dashed
- Dotted
- Dash-dot
- Corner marks
- Disabled state

### Numbering

- Enabled/disabled
- Sequential numbering
- Row-column numbering
- Correct page ordering

### DPI

- Automatic resolution
- Custom resolution
- Raster dimensions
- High-memory warning

### Overlap

- Zero overlap
- 0.25-inch overlap
- 0.5-inch overlap
- Custom overlap
- Correct adjacent tile alignment

### Export

- Correct page count
- Correct paper dimensions
- Valid PDF output
- Correct guides
- Correct image cropping
- No unexpected blank pages

Also test:

- Import failures
- Unsupported files
- Large documents
- Cancelled exports
- Project save and restore
- Platform-specific file access

---

# 26. IMPLEMENTATION PHASES

Implement the project in the following order.

## Phase 1 — Foundation

- Analyze existing project.
- Create documentation.
- Install verified dependencies.
- Establish architecture.
- Implement themes.
- Implement responsive design system.
- Configure navigation.

## Phase 2 — Dashboard

- Home screen
- New project
- Recent projects
- Persistent project storage

## Phase 3 — Document Editor

- Document import
- Canvas rendering
- Zoom and pan
- Toolbar
- Right inspector
- Grid
- Rulers

## Phase 4 — Layout and Paper

- Grid mode
- Custom size mode
- Custom presets
- Paper selection
- Orientation
- Physical dimensions

## Phase 5 — Print Configuration

Implement every feature:

- Margin ON/OFF
- Margin inch selection
- Linked/individual margins
- Overlap ON/OFF
- Overlap inch selection
- Scissors ON/OFF
- Cut-side selection
- Cutting lines ON/OFF
- Line style selection
- Page numbers ON/OFF
- Numbering style
- DPI automatic/custom

All settings must immediately affect applicable live previews.

## Phase 6 — Slicing Engine

- Canonical geometry models
- Tile planning
- Source cropping
- Seam calculations
- Page ordering
- Geometry tests

## Phase 7 — Preview

- Full poster preview
- Individual sheet preview
- Guide overlays
- Zoom controls
- Page navigation

## Phase 8 — Export

- PDF generation
- Image ZIP generation
- Progress
- Cancellation
- File saving
- Native printing
- DOCX export where fully supported

## Phase 9 — Advanced Document Support

- Word import conversion adapters
- Multi-page document workflows
- Batch processing
- Advanced transformations

## Phase 10 — Production Refinement

- Accessibility
- Error handling
- Performance optimization
- Platform verification
- Automated tests
- UI polish
- Release builds

---

# 27. NON-NEGOTIABLE RULES

1. Do not replace the existing project unnecessarily.
2. Do not implement features as static UI demonstrations.
3. Do not leave functional buttons without behavior.
4. Do not duplicate slicing geometry calculations.
5. Do not put business logic inside large widget files.
6. Do not hardcode design-system values.
7. Do not ignore platform-specific limitations.
8. Do not silently swallow errors.
9. Do not allow invalid layout dimensions.
10. Do not modify original imported files.
11. Do not use arbitrary pixel calculations for physical printing.
12. Do not export pages at incorrect physical dimensions.
13. Do not load hundreds of full-resolution sheets into memory.
14. Do not treat editor-only guides as printable elements unless enabled.
15. Do not mark a feature complete without testing it.
16. Maintain consistent mobile and desktop behavior.
17. Always run formatting, analysis, and relevant tests.
18. Keep `DEVELOPMENT_PROGRESS.md` updated after each phase.
19. Preserve maintainability and readability.
20. Implement functional vertical slices instead of scattering unfinished components across the entire project.

---

# 28. COMPLETION REQUIREMENTS

The implementation is successful when a user can:

1. Open ZSlice.
2. Create a project.
3. Import an image or supported PDF.
4. Configure poster rows and columns.
5. Select paper size and orientation.
6. Set margins to zero or a custom inch value.
7. Enable or disable scissors icons.
8. Select the edges where cutting is required.
9. Enable or disable cutting lines.
10. Choose solid, dashed, dotted, dash-dot, or corner cutting guides.
11. Enable or disable page numbering.
12. Choose numbering style and placement.
13. Select automatic or custom DPI.
14. Disable overlap or set a custom overlap in inches.
15. View the full poster with configurable overlays.
16. Preview every individual printable sheet.
17. Export an accurate multi-page PDF.
18. Save the project.
19. Reopen it without losing settings.
20. Perform the workflow on supported desktop and mobile platforms.

Additional DOC/DOCX capabilities must meet the same standard once their platform-specific implementations are available.

---

# 29. START IMPLEMENTATION NOW

Begin by inspecting the existing `zslice` Flutter project.

Produce the initial architecture and implementation documents.

Then implement the application phase by phase, beginning with the foundational design system, navigation, and project dashboard.

After each phase:

- Summarize implemented functionality.
- List created and modified files.
- Run appropriate verification commands.
- Report passing and failing tests.
- Document unresolved platform limitations.
- Update development progress.
- Proceed to the next dependent phase when safe.

Do not stop after producing a plan.

The final result must be a cohesive, usable, maintainable Flutter application named **ZSlice by OnezPH**, featuring a polished interface and an accurate document slicing and printing workflow.
