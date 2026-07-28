# USB Swiss Army Knife v0.1.7

## Profile Output and XLSX Fix

This release fixes two pre-release issues found during local EXE testing.

### Fixed

- Fixed XLSX generation on Windows by explicitly loading both `System.IO.Compression` and `System.IO.Compression.FileSystem` before creating the workbook ZIP container.
- Moved visible planning/session output from `%LOCALAPPDATA%\ForensicsByte\UsbSwissArmyKnife` to `%USERPROFILE%\UsbSwissArmyKnife` so users can easily find generated CSV/XLSX planning files.
- Planning files now land under `%USERPROFILE%\UsbSwissArmyKnife\planning`.

### Still intentionally out of scope

The tool still does not download, install, bundle, format, erase, or redistribute third-party tools. It creates folder structures, editable planning lists, source records, and templates only.
