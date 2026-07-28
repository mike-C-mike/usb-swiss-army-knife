# USB Swiss Army Knife v0.1.4

## Build Profiles + Editable Tool Lists

This release expands the guided build workflow and adds editable build-list output.

## Added

- Fourth toolkit purpose: **Everything**, combining IT Support, DFIR, and OSINT paths.
- Editable `FolderStructure.csv` output.
- Editable `ToolList.csv` output.
- Optional `UsbToolkitBuildPlan.xlsx` workbook output.
- Tool source list entries with official source URLs, license notes, source notes, target folders, and download status.
- Planning folder workflow before writing a USB build.
- Builder reads the current CSV lists before writing a drive, so users can delete rows or set `Include` to `No` before building.
- Source record text files are written for included tools, but no tools are downloaded.

## Changed

- The tool is now centered around a guided path:
  - interaction level
  - toolkit purpose
  - package level
  - editable planning output
  - drive exclusions
  - target drive per role
- The source list is now intentionally editable before writing to USB.

## Boundary

USB Swiss Army Knife does not download, install, bundle, redistribute, format, erase, or hash tools. It creates a folder structure and source-tracking records so users can build their own toolkit from official publisher-controlled sources.
