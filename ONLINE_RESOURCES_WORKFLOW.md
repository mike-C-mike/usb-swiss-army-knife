# Online Resources Workflow

`OnlineResources.html` is generated from `ToolList_SOURCE_OF_TRUTH.csv` and gives users a clickable browser view of the tool catalog.

## Source of truth

The source of truth remains:

```text
%USERPROFILE%\UsbSwissArmyKnife\planning\ToolList_SOURCE_OF_TRUTH.csv
```

Users edit the CSV to control Include, TargetFolder, OfficialSourceURL, DirectDownloadURL, DownloadEnabled, hash fields, and custom tool rows.

## Informational outputs

These files are informational views generated from the source-of-truth CSV:

```text
OnlineResources.html
DownloadTransparencyPlan.csv
DownloadInstallQueue_INFRASTRUCTURE.csv
DownloadReadinessReport.csv
UsbToolkitBuildPlan.xlsx
FolderStructure.csv
```

## HTML page purpose

The HTML page helps users browse official source pages, exact direct download URLs, hash source links, target folders, and notes. It does not download, install, validate, endorse, or redistribute tools.

## Recommended use

1. Run a guided build.
2. Review/edit `ToolList_SOURCE_OF_TRUTH.csv`.
3. Open `OnlineResources.html` for clickable source review.
4. Validate the source-of-truth CSV.
5. Use Download Preview before running enabled downloads.
