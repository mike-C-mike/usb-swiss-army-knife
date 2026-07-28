# USB Swiss Army Knife v0.2.3 - Transparency Source-of-Truth Sprint

This release tightens the download transparency model and makes `ToolList_SOURCE_OF_TRUTH.csv` the clearly labeled editable source of truth.

## Added

- `TOOLLIST_SOURCE_OF_TRUTH_EDITING_GUIDE.txt` generated in the planning folder.
- `CustomToolRow_TEMPLATE.csv` for user-added tools.
- `DownloadTransparencyPlan.csv` showing the official review page, exact direct download URL, target folder, local filename, completed download path, and hash fields.
- Download Manager options to open the editing guide, create/open the custom row template, export the transparency plan, and preview exact sources before download.

## Changed

- The download preview now shows the official source page and the exact direct download URL separately.
- Validation now checks custom-row safety issues such as blank target folders, missing official source pages, non-HTTPS source/download URLs, blank local filenames for enabled downloads, and unsupported hash algorithms.
- The guided build workflow now emphasizes that `ToolList_SOURCE_OF_TRUTH.csv` is the file users should edit.

## Boundary

The tool still does not install software, execute installers, format drives, erase drives, or redistribute third-party software.
