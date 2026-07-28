# USB Swiss Army Knife v0.2.0 - Download Manager and Manifest Foundation

This release starts the controlled download structure for USB Swiss Army Knife.

## Added

- Download Manager menu.
- User-profile download staging and completed download folders.
- `DownloadManifest_SUCCESS_FAILURE_HASHES.csv` success/failure/hash manifest.
- Explicit source-of-truth handling through `ToolList_SOURCE_OF_TRUTH.csv`.
- Download queue regeneration from the current source-of-truth list.
- Source-vetting status and notes columns.
- Initial vetted direct download support for Microsoft Sysinternals Suite.

## Boundary

Downloads only run for rows where `Include=Yes`, `DownloadEnabled=Yes`, and `DirectDownloadURL` is populated. This release does not execute installers, silently install software, format drives, erase drives, redistribute third-party binaries, or claim publisher-hash verification.
