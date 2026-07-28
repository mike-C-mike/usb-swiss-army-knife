# Download Transparency Workflow

USB Swiss Army Knife is designed so users can see and control where downloads come from before anything is fetched.

## Source of truth

The main editable file is:

```text
%USERPROFILE%\UsbSwissArmyKnife\planning\ToolList_SOURCE_OF_TRUTH.csv
```

This file controls:

- Whether a tool is included.
- Where the source record is written.
- The official source page users can review.
- The exact direct download URL used by the Download Manager.
- The local filename for the completed download.
- Optional source-published hash comparison fields.

## Informational files

The following files help users understand the plan, but they are not the source of truth for software inclusion:

- `FolderStructure.csv`
- `DownloadTransparencyPlan.csv`
- `DownloadInstallQueue_INFRASTRUCTURE.csv`
- `DownloadReadinessReport.csv`
- `UsbToolkitBuildPlan.xlsx`

## Adding tools

Users can add tools by adding rows to `ToolList_SOURCE_OF_TRUTH.csv` with matching columns. Use `CustomToolRow_TEMPLATE.csv` as a starter row.

Keep `DownloadEnabled=No` until the official source page, direct download URL, license terms, and hash verification approach have been reviewed.

## Download behavior

Downloads run only when:

```text
Include=Yes
DownloadEnabled=Yes
DirectDownloadURL is populated and HTTPS
```

The tool downloads to staging, hashes the completed file, moves it to completed downloads, and records success/failure and SHA-256 in the manifest. It does not install or execute downloaded files.
