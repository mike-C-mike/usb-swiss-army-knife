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
%USERPROFILE%\UsbSwissArmyKnife\planning\
```

Core files:

```text
FolderStructure.csv
ToolList_SOURCE_OF_TRUTH.csv
UsbToolkitBuildPlan.xlsx  optional
```

The CSV files are the authoritative current lists used by the builder. Users can remove rows, change `Include` to `No`, edit target folders, or replace source URLs before writing a USB build.

The XLSX workbook is provided for easier review/editing in Excel when selected. The current v0.2.1 builder reads the CSV files when writing the USB.

## Boundary

This project does not redistribute third-party binaries, installers, ISOs, VM images, wordlists, vendor tools, or downloaded content.

The tool does not download, install, format, erase, or modify boot sectors. It creates local structures and source/download records so each user can populate the toolkit from official publisher-controlled sources.

## Build

```powershell
Unblock-File .\build_release.ps1
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\build_release.ps1 -Version 0.1.7
```

Release output is created under `release\`.


## Visible output location

Generated planning files and saved sessions are written to:

```text
%USERPROFILE%\UsbSwissArmyKnife\
%USERPROFILE%\UsbSwissArmyKnife\planning\
```

This avoids using the PyInstaller temporary extraction folder and makes the CSV/XLSX planning files easy for the user to find and edit.


## Editable software source of truth

The guided builder creates planning files under:

```text
%USERPROFILE%\UsbSwissArmyKnife\planning\
```

The file below is the source of truth for which software records are included when writing a USB structure:

```text
ToolList_SOURCE_OF_TRUTH.csv
```

Edit the `Include` column to `Yes` or `No`. Deleting rows is not required. The folder CSV and XLSX workbook are planning/reference outputs; the software include/exclude decision comes from `ToolList_SOURCE_OF_TRUTH.csv`.

The tool still does not download tools. It writes folder structures, templates, and source cards so the user can populate tools locally from official publisher-controlled sources.


## v0.2.1 local install and download/install infrastructure

The guided builder now asks whether the build target is a USB/removable toolkit or a local install. Local install mode is intended for users who want the same organized toolkit structure on C: or another local/storage SSD.

The software source of truth remains:

```text
%USERPROFILE%\UsbSwissArmyKnife\planning\ToolList_SOURCE_OF_TRUTH.csv
```

Set `Include` to `No` to remove a tool from the build. The builder reads this file when writing software source records.

The new infrastructure file is informational/planning only:

```text
%USERPROFILE%\UsbSwissArmyKnife\planning\DownloadInstallQueue_INFRASTRUCTURE.csv
```

It prepares for a future download/install engine but does not download or install anything in this release.


## Download manager foundation

v0.2.1 adds an explicit download manager. It uses `ToolList_SOURCE_OF_TRUTH.csv` as the source of truth. A row must have `Include=Yes`, `DownloadEnabled=Yes`, and a populated `DirectDownloadURL` before the tool attempts a download.

Downloads are staged under the user profile, hashed with SHA-256, then moved to completed downloads. A manifest is written to:

`%USERPROFILE%\UsbSwissArmyKnife\downloads\DownloadManifest_SUCCESS_FAILURE_HASHES.csv`

The manifest records success/failure, file path, byte count, direct URL, official source page, and local SHA-256. Users should compare that local hash to a publisher/source-published hash when the publisher provides one.


## v0.2.3 Transparency and editable source-of-truth workflow

The main planning file is `ToolList_SOURCE_OF_TRUTH.csv`. Users can edit this file directly to include/exclude tools, change target folders, edit official source pages, add exact direct download URLs, and add their own tool rows. The builder treats this CSV as the source of truth when writing toolkit source records and running enabled downloads.

Additional outputs are informational: `FolderStructure.csv`, `DownloadTransparencyPlan.csv`, `DownloadInstallQueue_INFRASTRUCTURE.csv`, `DownloadReadinessReport.csv`, and `UsbToolkitBuildPlan.xlsx`.

The Download Manager shows the official review page and exact direct download URL before download. Downloads run only for rows with `Include=Yes`, `DownloadEnabled=Yes`, and a populated HTTPS `DirectDownloadURL`. The app downloads to a user-profile staging folder, hashes the completed file with SHA-256, and writes the result to `DownloadManifest_SUCCESS_FAILURE_HASHES.csv`. It does not install or execute downloaded files.


## v0.2.6 CI compatibility

This build restores the root convenience launchers and `Usb-SwissArmyKnife.ps1` entry point used by the repository validation workflow. The root script delegates to `resources/usak_menu.ps1`, which remains the active guided menu used by the EXE.
