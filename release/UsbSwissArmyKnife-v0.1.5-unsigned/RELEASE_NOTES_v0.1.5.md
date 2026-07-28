# USB Swiss Army Knife v0.1.5 - Launcher Debug and Console Hold

This release hardens the console launcher for early testers.

## Fixed / Improved

- The EXE now pauses before closing so double-click launches do not disappear immediately.
- The launcher writes a runtime log to `%LOCALAPPDATA%\ForensicsByte\UsbSwissArmyKnife\logs\launcher.log`.
- The launcher shows the exit code and log path before closing.
- Added `RUN_DEBUG_FROM_POWERSHELL.md` with simple troubleshooting steps.
- Clarified that the build script should be run from the folder containing `build_release.ps1`; no nested `cd` is required when the build kit is extracted directly into the repo root.

## Boundary

USB Swiss Army Knife still does not download tools, redistribute binaries, format drives, erase drives, partition media, or act as a hash generator.
