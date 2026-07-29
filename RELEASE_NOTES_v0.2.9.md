# USB Swiss Army Knife v0.2.9 - Online Resources Dashboard

This release adds an automatically generated `OnlineResources.html` page to the planning workflow.

## Changes

- Generates `OnlineResources.html` from `ToolList_SOURCE_OF_TRUTH.csv`.
- Adds an Advanced menu option to open the online resources page.
- Adds a Download Manager option to open the online resources page.
- Keeps `ToolList_SOURCE_OF_TRUTH.csv` as the only software source of truth.
- Keeps the HTML page informational only: it does not download, install, validate, endorse, or redistribute tools.
- Copies `OnlineResources.html` into `_toolkit_admin\planning\` during toolkit writes when available.

## Boundary

The builder continues to create structures, editable lists, source records, controlled downloads, local hashes, and manifests only. It does not install tools, run installers, format drives, erase drives, or ship third-party binaries in the project repository.
