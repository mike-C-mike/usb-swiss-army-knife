# USB Swiss Army Knife v0.2.6 - CI Validation Alignment

This release focuses on repository validation reliability.

## Fixed

- Adds a robust `tests/Repository.Tests.ps1` file to the release kit.
- Fixes `Run-ProjectTests.cmd` path handling by resolving the repository root as `%~dp0.`.
- Fixes `tools/Invoke-ProjectTests.ps1` so it sanitizes quoted paths and resolves defaults inside the script body.
- Preserves root convenience launchers, the root PowerShell launcher, strict-mode-safe size helpers, active repository helpers, and removable-drive repository mapping expected by CI.

## Boundary

The project still does not ship third-party binaries, installers, ISOs, VM images, archives, or downloaded tools.
