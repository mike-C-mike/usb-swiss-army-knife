# USB Swiss Army Knife v0.2.4 - CI Compatibility Sprint

This release restores the repository-level convenience launchers and PowerShell entry point expected by the existing GitHub Actions validation suite. It keeps the v0.2.3 transparency/source-of-truth workflow intact.

## Fixed

- Added `Start-UsbSwissArmyKnife.cmd`.
- Added `Run-ProjectTests.cmd`.
- Added root `Usb-SwissArmyKnife.ps1` launcher that parses cleanly and delegates to `resources/usak_menu.ps1`.
- Added strict-mode-safe helper functions `Get-PathContentSize` and `Get-ObjectSizeTotal`.
- Added active repository helper functions expected by tests.
- Added removable-drive repository mapping under a `usb-swiss-army-knife` subfolder.

## Boundary

The project still does not install, bundle, format, erase, or redistribute third-party tools.
