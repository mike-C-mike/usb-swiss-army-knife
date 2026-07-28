# USB Swiss Army Knife v0.2.5

## CI test-runner compatibility fix

This patch hardens the repository test launcher after a GitHub Actions failure and a local `Run-ProjectTests.cmd` path-resolution error.

### Fixed

- `tools\Invoke-ProjectTests.ps1` no longer uses `$PSScriptRoot` inside a parameter default.
- `Run-ProjectTests.cmd` now passes `-RepositoryRoot` and `-TestPath` explicitly.
- Convenience launchers remain at repository root:
  - `Start-UsbSwissArmyKnife.cmd`
  - `Run-ProjectTests.cmd`
- The root `Usb-SwissArmyKnife.ps1` launcher remains parse-safe and keeps the compatibility helper functions expected by the existing test suite.

### Notes

The expression below is part of the script and the CI test pattern. It should not be run by itself in PowerShell because `$drive` is only populated inside the removable-drive selection workflow:

```powershell
Join-Path $drive.DeviceID 'usb-swiss-army-knife'
```
