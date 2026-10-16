# ZSlice 1.1.5 — Windows startup maximize correction

Version 1.1.5+7, 2026-10-16.

Fixed the native Windows runner's first-frame show. Its previous SW_SHOWNORMAL call could restore the window after Dart had requested maximization. It now uses SW_SHOWMAXIMIZED, so both startup paths request the same maximized state. The custom title bar still offers Minimize and Close.

The 1.1.4 startup test checked Flutter method-call ordering and did not cover the native first-frame callback. This update includes verification of the launched Windows application.

Verified the actual 1.1.5 Windows release after launch: its system menu reports Restore enabled and Maximize, Move and Size disabled, confirming the native maximized state. All 19 startup/editor regression tests pass. Windows release build passed (55.5 s).

Close the old application, extract the complete Windows ZIP and run zslice.exe. Keep the executable, DLLs and data folder together.
