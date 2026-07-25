# Changelog

## [0.3.0-alpha] - 2026-07-25

### Added

- One-click `Start-UsbSwissArmyKnife.cmd` launcher using process-scoped execution-policy bypass.
- One-click `Run-ProjectTests.cmd` launcher.
- Guided environment and developer-tools submenu.
- NuGet, PSGallery, and Pester setup workflow with explicit user confirmation.
- Environment diagnostics for PowerShell, execution policy, NuGet, Pester, PSGallery, Robocopy, and Git.
- Local JSON provisioning-plan reports for dry runs.
- PowerShell parser validation in the Pester suite.
- Standalone development-environment setup script.

### Changed

- Dry-run confirmation now uses `PREVIEW <drive>`.
- Provision confirmation clearly displays dry-run, update, or mirror behavior.
- Dry-run output reports the generated local plan rather than a nonexistent copy log.

### Safety

- Convenience launchers use `-ExecutionPolicy Bypass` only for their child PowerShell process.
- No machine-wide execution-policy change is made.
- Development setup requires typed confirmation before installing user-scoped prerequisites.

## [0.2.1-alpha] - 2026-07-25

### Fixed

- Corrected a PowerShell parser error in the Robocopy argument construction.
- Added the missing `DryRunMode` parameter to profile-copy and provisioning functions.
- Passed dry-run state into the final confirmation screen.
- Prevented mirror-mode deletion warnings during a dry run.
- Added a Pester 5-compatible test runner to avoid ambiguous parameters from older Pester versions.

### Added

- `tools/Invoke-ProjectTests.ps1` detects and imports Pester 5.5 or newer explicitly.

## [0.2.0-alpha] - 2026-07-25

### Added
- Official standalone 7-Zip extraction helper
- Automatic `.7z` extraction for Hashcat
- Interactive project health check
- Dry-run USB provisioning
- Pester tests and Windows GitHub Actions validation
- Standalone metadata validator

## [0.1.0-alpha] - 2026-07-25
- Initial public source-only release
