# USB Swiss Army Knife v0.2.2 - Download Hardening Sprint

This release expands the controlled download workflow while keeping the project boundary intact.

## Added

- Download preview before running enabled downloads.
- Source-of-truth CSV validation for required columns, HTTPS download URLs, duplicate records, and unsupported hash algorithms.
- Download readiness report: `DownloadReadinessReport.csv`.
- Existing completed file behavior:
  - skip download and hash existing files,
  - overwrite existing files,
  - prompt per file.
- Download run IDs in the manifest.
- Source host and direct-download host fields in the manifest.
- Optional source-published hash fields in `ToolList_SOURCE_OF_TRUTH.csv`:
  - `SourcePublishedHash`
  - `HashAlgorithm`
  - `HashSourceURL`
- Hash match status in the download manifest when a source-published SHA-256 is supplied.
- Completed downloads checksum list: `CompletedDownloads_SHA256SUMS.txt`.
- Optional per-row copy of completed downloaded files into build folders when `CopyDownloadedFileToBuild=Yes`.

## Still intentionally disabled

This release does not run installers, silently install tools, format drives, erase drives, bundle third-party tools, or redistribute third-party binaries.

## Source of truth

The editable software list remains:

```text
%USERPROFILE%\UsbSwissArmyKnife\planning\ToolList_SOURCE_OF_TRUTH.csv
```

A row is eligible for download only when:

```text
Include = Yes
DownloadEnabled = Yes
DirectDownloadURL is populated with HTTPS
```

## Download output

Downloads are staged and completed under:

```text
%USERPROFILE%\UsbSwissArmyKnife\downloads\
```

The success/failure/hash manifest is:

```text
%USERPROFILE%\UsbSwissArmyKnife\downloads\DownloadManifest_SUCCESS_FAILURE_HASHES.csv
```
