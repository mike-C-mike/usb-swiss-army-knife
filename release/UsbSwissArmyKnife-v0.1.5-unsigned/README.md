# USB Swiss Army Knife

USB Swiss Army Knife is a console EXE for building local USB toolkit folder structures and editable planning records without asking users to run a PowerShell script manually.

## What it does

On launch, the tool checks for a saved guided-build session. It can resume the prior session or start over.

The guided workflow asks:

1. Interaction level: Full Guided, Intermediate, or Custom
2. Toolkit purpose: IT Support, DFIR, OSINT, or Everything
3. Package level: Minimal, Solid, or Overkill
4. Editable output option: CSV or CSV plus XLSX
5. Drive exclusion list
6. Target drive/path for each recommended drive role

The tool then writes folders, templates, source records, and planning files to the selected target.

## Editable build lists

Before writing to a target drive, the tool generates editable files under:

```text
%LOCALAPPDATA%\ForensicsByte\UsbSwissArmyKnife\planning\
```

Core files:

```text
FolderStructure.csv
ToolList.csv
UsbToolkitBuildPlan.xlsx  optional
```

The CSV files are the authoritative current lists used by the builder. Users can remove rows, change `Include` to `No`, edit target folders, or replace source URLs before writing a USB build.

The XLSX workbook is provided for easier review/editing in Excel when selected. The current v0.1.5 builder reads the CSV files when writing the USB.

## Boundary

This project does not redistribute third-party binaries, installers, ISOs, VM images, wordlists, vendor tools, or downloaded content.

The tool does not download, install, format, erase, or modify boot sectors. It creates local structures and source/download records so each user can populate the toolkit from official publisher-controlled sources.

## Build

```powershell
Unblock-File .\build_release.ps1
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\build_release.ps1 -Version 0.1.5
```

Release output is created under `release\`.
