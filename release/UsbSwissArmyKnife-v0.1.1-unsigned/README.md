# USB Swiss Army Knife

USB Swiss Army Knife is a console EXE utility that creates and maintains a structured field-toolkit folder layout.

The release EXE opens a console menu so users do not need to manually run a PowerShell script.

## Important boundary

This project intentionally redistributes no third-party binaries, vendor installers, ISOs, archives, wordlists, VM images, or downloaded project content.

Users should populate their own toolkit locally from official publisher-controlled sources and maintain attribution, version, source URL, license, and hash records.

## What v0.1.1 does

- Opens a console menu from `UsbSwissArmyKnife.exe`.
- Creates a broader field-toolkit folder structure.
- Writes README, checklist, attribution, manifest, hash, and change-log templates.
- Opens Explorer, Command Prompt, or PowerShell at the toolkit root.
- Adds tool manifest entries.
- Adds source attribution entries.
- Records maintenance/change notes.
- Records SHA-256 hashes for one file.
- Creates recursive hash reports for folders.
- Builds file inventory CSV reports.
- Writes toolkit status reports.

## Build

```powershell
Unblock-File .uild_release.ps1
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.uild_release.ps1 -Version 0.1.1
```

The script creates a release ZIP and checksum files under `release\`.
