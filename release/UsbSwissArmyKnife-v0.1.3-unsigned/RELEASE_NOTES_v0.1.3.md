# Release Notes - v0.1.3

## Guided Build Paths Sprint

This release reworks USB Swiss Army Knife around the intended guided path workflow.

### Added

- Saved session detection and resume option on startup.
- Full Guided, Intermediate, and Custom interaction levels.
- IT Support, DFIR, and OSINT toolkit purposes.
- Minimal, Solid, and Overkill package levels.
- Generated USB build paths with suggested drive sizes and roles.
- Drive exclusion list before choosing a target drive.
- Detected drive picker with manual path fallback.
- Multi-drive flow that asks whether to continue to the next sized/role drive.
- Session persistence under `%LOCALAPPDATA%\ForensicsByte\UsbSwissArmyKnife\guided_session.json`.

### Preserved boundary

The tool does not format, erase, partition, download, redistribute, or bundle third-party payloads. It writes folders, templates, and records only.
