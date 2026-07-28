# USB Swiss Army Knife v0.1.9 - Local Install + Download Infrastructure

This unsigned pre-release adds a local install target and begins the download/install infrastructure without enabling automatic downloads or installer execution.

## Added

- Build target selection: USB Toolkit or Local Install.
- Local Install can target C: or another local/storage drive and creates a UsbSwissArmyKnife folder.
- DownloadInstallQueue_INFRASTRUCTURE.csv generated from ToolList_SOURCE_OF_TRUTH.csv.
- Expanded ToolList_SOURCE_OF_TRUTH.csv columns for future direct download URL, installer type, silent arguments, install command, and install scope.
- Drive/source records now include a download_install planning folder.

## Boundary

This release still does not download tools, install software, bundle third-party content, format drives, erase drives, or redistribute installers. The new queue is planning infrastructure only.
