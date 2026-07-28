# USB Swiss Army Knife

USB Swiss Army Knife is a console utility that creates and maintains a structured field-toolkit folder layout.

The release EXE opens a console menu so users do not need to manually run a PowerShell script.

## Important boundary

This project intentionally redistributes no third-party binaries, vendor installers, ISOs, archives, wordlists, VM images, or downloaded project content.

Users should populate their own toolkit locally from official publisher-controlled sources and maintain attribution, version, source URL, license, and hash records.

## What v0.1.0 does

- Opens a console menu from `UsbSwissArmyKnife.exe`
- Creates a field-toolkit folder layout
- Writes README and attribution/manifest templates
- Records SHA-256 hashes for selected files
- Avoids hiding third-party payloads inside the project

## Build

```powershell
Unblock-File .\build_release.ps1
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\build_release.ps1 -Version 0.1.0
```

The script creates a release ZIP and checksum files under `release\`.
