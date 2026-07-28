# USB Swiss Army Knife v0.2.1 - PowerShell Host Variable Fix

## Fixed

- Fixed a PowerShell runtime failure caused by assigning to `$host`, which conflicts with PowerShell's built-in read-only `$Host` variable.
- Renamed the internal source-host variable to `$sourceHost` in source-vetting helper functions.
- Preserved v0.2.0 Download Manager behavior, profile output paths, source-of-truth CSV handling, and console-hold debug behavior.

## Build

```powershell
Unblock-File .\build_release.ps1
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\build_release.ps1 -Version 0.2.1
```

## Test

```powershell
.\release\UsbSwissArmyKnife-v0.2.1-unsigned\UsbSwissArmyKnife.exe
```

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
