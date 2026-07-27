# Changelog

## [0.5.0-alpha] - 2026-07-26

### Added

- Session-wide active repository selection.
- Repository destination chooser for the default user folder, attached USB or external drives, and arbitrary custom folders.
- Active repository status and free-space display in major menus.
- `R` shortcut in the main, resource, maintenance, and environment menus.
- Destination confirmation before guided builds, complete builds, updates, audits, and resource operations.
- Initial startup prompt allowing immediate redirection to removable storage.

### Changed

- Builds, updates, audits, resources, inventories, logs, dashboards, and support bundles now follow the active repository.
- Selecting a removable drive creates or uses `<drive>:\usb-swiss-army-knife`.
- Individual USB provisioning still uses a separate target-drive selection so the source repository and deployable USB remain distinct.

### Safety

- The root of the Windows system drive remains prohibited as a repository location.
- Repository changes require explicit confirmation.
- The active destination is shown before operations that write or update content.

## [0.4.1-alpha] - 2026-07-26

### Fixed

- Replaced strict-mode-unsafe `Measure-Object ... -Sum` property access in USB profile size calculations.
- Empty profile folders and missing optional folders now contribute zero bytes instead of terminating provisioning.
- Dry-run item sizing now uses the same safe recursive byte counter.
- Dry-run total sizing now safely sums plan item properties without assuming a `Sum` property exists.

### Added

- `Get-PathContentSize` for predictable file and directory size calculation.
- `Get-ObjectSizeTotal` for strict-mode-safe numeric aggregation.
- Regression tests preventing the unsafe size-measurement pattern from returning.

## [0.4.0-alpha] - 2026-07-25

### Added

- Guided toolkit build presets for recommended, help desk, network, DFIR, OSINT, authorized pentest lab, and full builds.
- `config/build-presets.json` as a reviewed, testable catalog-selection layer.
- Installed-items-only update workflow.
- Installed-inventory audit workflow.
- Maintenance and support submenu.
- Catalog-selection reports recording exactly what a guided build requested.
- Support-bundle export containing configuration, environment metadata, inventory, and recent logs only.
- Standalone `tools/Export-SupportBundle.ps1`.
- Build-preset validation in the CI metadata validator and Pester suite.

### Changed

- The main menu now prioritizes guided builds, maintenance, and USB provisioning.
- Complete-catalog updates are no longer the default update path.
- Users can avoid unexpected vendor forms by choosing a preset without interactive downloads.

### Safety

- Support bundles exclude third-party software, downloaded repositories, wordlists, ISOs, VMs, and credentials.
- Guided builds require typed confirmation naming the selected preset.
- Presets fail validation if they reference an unknown catalog item.

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
