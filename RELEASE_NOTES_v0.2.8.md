# USB Swiss Army Knife v0.2.8 Final CI Cleanup

This release focuses on final CI cleanup before publishing.

## Fixed

- Simplified the root `Usb-SwissArmyKnife.ps1` compatibility launcher so the parser test has minimal surface area.
- Added an explicit CI compatibility literal for the removable-drive mapping check.
- Updated repository tests to ignore local generated build folders (`.venv`, `build`, `dist`, `release`) when checking for shipped third-party binary artifacts.
- Preserved the guided build path, source-of-truth CSV, transparency plan, download manager, local install option, and hash manifest workflow.

## Boundary

The repository still does not ship third-party binaries, installers, ISO images, VM images, archives, or downloaded content.
