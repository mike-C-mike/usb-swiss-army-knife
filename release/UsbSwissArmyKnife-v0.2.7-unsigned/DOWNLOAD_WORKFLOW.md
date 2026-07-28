# Download Workflow

USB Swiss Army Knife uses one editable source-of-truth file:

`%USERPROFILE%\UsbSwissArmyKnife\planning\ToolList_SOURCE_OF_TRUTH.csv`

A row is eligible for download only when all of these are true:

- `Include` is `Yes`
- `DownloadEnabled` is `Yes`
- `DirectDownloadURL` is populated

Downloads are not sent to the normal Windows Downloads folder. The builder uses controlled project folders:

- Staging: `%USERPROFILE%\UsbSwissArmyKnife\downloads\staging\`
- Completed: `%USERPROFILE%\UsbSwissArmyKnife\downloads\completed\`
- Manifest: `%USERPROFILE%\UsbSwissArmyKnife\downloads\DownloadManifest_SUCCESS_FAILURE_HASHES.csv`

The download flow is:

1. Download to staging.
2. Hash staged file with SHA-256.
3. Move successful download to completed downloads.
4. Write success/failure, path, byte count, URL, and SHA-256 to the manifest.

The local SHA-256 helps the user compare the file against a publisher-provided hash when one is available. If the publisher does not provide a hash, the local hash only records what was downloaded.

Installer execution is intentionally disabled in this release.
