# ZSlice 1.1.4 — open maximized

Version 1.1.4+6, 2026-10-16.

The desktop application opens maximized automatically. Startup waits for window setup, maximizes the window, then shows and focuses it. The maximize/restore button has been removed from the custom title bar; Minimize and Close remain available.

Verification: all 148 automated tests pass. Coverage checks startup ordering, absence of maximize/restore controls, working Minimize/Close controls and title-bar tooltips across routed screens. Formatting passes.

Static analysis reports no issues. Windows release build passed and the complete ZIP was verified, including version 1.1.4+6 and required runtime/data files.

Close the old application, extract the complete Windows ZIP and run zslice.exe. Keep the executable, DLLs and data folder together.
