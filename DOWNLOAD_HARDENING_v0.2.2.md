# Download Hardening Notes

USB Swiss Army Knife uses a controlled staging workflow. It does not use the normal Windows Downloads folder.

## Flow

1. Read `ToolList_SOURCE_OF_TRUTH.csv`.
2. Validate the source-of-truth list.
3. Preview eligible downloads.
4. Download eligible rows to a staging folder.
5. Hash each staged file with SHA-256.
6. Move successful downloads to the completed downloads folder.
7. Record status, path, hash, byte count, source URLs, and hash comparison status in the manifest.

## Source-of-truth fields

The current source-of-truth list supports these download fields:

- `Include`
- `DownloadEnabled`
- `DirectDownloadURL`
- `LocalFileName`
- `SourcePublishedHash`
- `HashAlgorithm`
- `HashSourceURL`
- `CopyDownloadedFileToBuild`

## Integrity boundary

The local SHA-256 in the manifest records what was downloaded locally. It is not the same as publisher verification unless the user supplies a source-published SHA-256 and the tool reports a match.

## Safety boundary

This release still does not execute downloaded files. Install execution remains disabled.
