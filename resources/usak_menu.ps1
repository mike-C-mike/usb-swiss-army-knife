<#
USB Swiss Army Knife console menu v0.2.3

Bundled PowerShell menu launched by the USB Swiss Army Knife EXE.

Boundary:
- Creates toolkit folder structures, editable build lists, source records, and templates.
- Does not redistribute third-party binaries, installers, ISOs,
  archives, wordlists, VM images, vendor tools, or downloaded content.
- Downloads only user-enabled rows from publisher-controlled URLs recorded in
  ToolList_SOURCE_OF_TRUTH.csv.
- Does not format, erase, partition, or modify boot sectors. It writes folders
  and documentation templates only to the selected root.
#>

$ErrorActionPreference = "Stop"
$Script:AppVersion = "0.2.4"
$Script:SessionDir = Join-Path $env:USERPROFILE "UsbSwissArmyKnife"
$Script:SessionPath = Join-Path $Script:SessionDir "guided_session.json"
$Script:PlanningDir = Join-Path $Script:SessionDir "planning"
$Script:InteractionLevel = "Full Guided"
$Script:Purpose = "DFIR"
$Script:PackageLevel = "Solid"
$Script:OutputFormat = "CSV"
$Script:BuildTarget = "USB Toolkit"
$Script:ExcludedDrives = @("C")
$Script:BuildPlan = @()
$Script:FolderListCsv = Join-Path $Script:PlanningDir "FolderStructure.csv"
$Script:ToolListCsv = Join-Path $Script:PlanningDir "ToolList_SOURCE_OF_TRUTH.csv"
$Script:BuildWorkbookXlsx = Join-Path $Script:PlanningDir "UsbToolkitBuildPlan.xlsx"
$Script:DownloadQueueCsv = Join-Path $Script:PlanningDir "DownloadInstallQueue_INFRASTRUCTURE.csv"
$Script:DownloadRoot = Join-Path $Script:SessionDir "downloads"
$Script:DownloadStagingDir = Join-Path $Script:DownloadRoot "staging"
$Script:DownloadCompletedDir = Join-Path $Script:DownloadRoot "completed"
$Script:DownloadManifestCsv = Join-Path $Script:DownloadRoot "DownloadManifest_SUCCESS_FAILURE_HASHES.csv"

function Write-Header {
    Clear-Host
    Write-Host "USB Swiss Army Knife v$Script:AppVersion" -ForegroundColor Green
    Write-Host "Forensics Byte / guided USB toolkit builder" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "Creates USB or local toolkit structures, editable build lists, and source records only." -ForegroundColor Yellow
    Write-Host "Downloads only items explicitly enabled in the source-of-truth list; does not install, bundle, format, erase, or redistribute third-party tools." -ForegroundColor Yellow
    Write-Host ""
}

function Pause-Menu { Write-Host ""; Read-Host "Press Enter to continue" | Out-Null }

function Ensure-SessionDir {
    New-Item -ItemType Directory -Force -Path $Script:SessionDir | Out-Null
    New-Item -ItemType Directory -Force -Path $Script:PlanningDir | Out-Null
    New-Item -ItemType Directory -Force -Path $Script:DownloadRoot | Out-Null
    New-Item -ItemType Directory -Force -Path $Script:DownloadStagingDir | Out-Null
    New-Item -ItemType Directory -Force -Path $Script:DownloadCompletedDir | Out-Null
}

function Save-Session {
    Ensure-SessionDir
    $session = [ordered]@{
        app_version = $Script:AppVersion
        saved_at = (Get-Date).ToString("o")
        interaction_level = $Script:InteractionLevel
        purpose = $Script:Purpose
        package_level = $Script:PackageLevel
        output_format = $Script:OutputFormat
        build_target = $Script:BuildTarget
        download_queue_csv = $Script:DownloadQueueCsv
        download_root = $Script:DownloadRoot
        download_manifest_csv = $Script:DownloadManifestCsv
        excluded_drives = $Script:ExcludedDrives
        build_plan = $Script:BuildPlan
        planning_dir = $Script:PlanningDir
        folder_list_csv = $Script:FolderListCsv
        tool_list_csv = $Script:ToolListCsv
        build_workbook_xlsx = $Script:BuildWorkbookXlsx
    }
    $session | ConvertTo-Json -Depth 10 | Set-Content -Path $Script:SessionPath -Encoding UTF8
}

function Load-Session {
    if (-not (Test-Path $Script:SessionPath)) { return $false }
    try {
        $raw = Get-Content -Path $Script:SessionPath -Raw -Encoding UTF8 | ConvertFrom-Json
        if ($null -eq $raw) { return $false }
        $Script:InteractionLevel = [string]$raw.interaction_level
        $Script:Purpose = [string]$raw.purpose
        $Script:PackageLevel = [string]$raw.package_level
        if ($raw.output_format) { $Script:OutputFormat = [string]$raw.output_format }
        if ($raw.build_target) { $Script:BuildTarget = [string]$raw.build_target }
        $Script:ExcludedDrives = @($raw.excluded_drives)
        $Script:BuildPlan = @($raw.build_plan)
        return $true
    }
    catch { return $false }
}

function Clear-Session {
    if (Test-Path $Script:SessionPath) { Remove-Item -Force -Path $Script:SessionPath }
}

function Read-MenuChoice {
    param([string]$Prompt, [int]$Min, [int]$Max)
    while ($true) {
        $choice = Read-Host $Prompt
        $num = 0
        if ([int]::TryParse($choice, [ref]$num) -and $num -ge $Min -and $num -le $Max) { return $num }
        Write-Host "Choose a number from $Min to $Max." -ForegroundColor Yellow
    }
}

function Get-PurposeList {
    param([string]$Purpose)
    if ($Purpose -eq "Everything") { return @("IT Support", "DFIR", "OSINT") }
    return @($Purpose)
}

function Select-InteractionLevel {
    Write-Header
    Write-Host "How much guidance do you want?" -ForegroundColor Cyan
    Write-Host " 1. Full guided    - asks questions and explains the build path"
    Write-Host " 2. Intermediate   - asks only the key decisions"
    Write-Host " 3. Custom build   - minimal guardrails; you choose the pieces"
    Write-Host ""
    $choice = Read-MenuChoice -Prompt "Interaction level" -Min 1 -Max 3
    switch ($choice) {
        1 { $Script:InteractionLevel = "Full Guided" }
        2 { $Script:InteractionLevel = "Intermediate" }
        3 { $Script:InteractionLevel = "Custom" }
    }
    Save-Session
}

function Select-Purpose {
    Write-Header
    Write-Host "What is this toolkit for?" -ForegroundColor Cyan
    Write-Host " 1. IT Support - help desk, repair, drivers, diagnostics, recovery"
    Write-Host " 2. DFIR       - acquisition support, triage, memory, validation, viewers"
    Write-Host " 3. OSINT      - source capture, citations, media review, link analysis"
    Write-Host " 4. Everything - IT Support + DFIR + OSINT in one broad build plan"
    Write-Host ""
    $choice = Read-MenuChoice -Prompt "Toolkit purpose" -Min 1 -Max 4
    switch ($choice) {
        1 { $Script:Purpose = "IT Support" }
        2 { $Script:Purpose = "DFIR" }
        3 { $Script:Purpose = "OSINT" }
        4 { $Script:Purpose = "Everything" }
    }
    Save-Session
}

function Select-PackageLevel {
    Write-Header
    Write-Host "How large should the toolkit build be?" -ForegroundColor Cyan
    Write-Host " 1. Minimal  - essential items only"
    Write-Host " 2. Solid    - practical field-ready build"
    Write-Host " 3. Overkill - broad master toolkit structure"
    Write-Host ""
    $choice = Read-MenuChoice -Prompt "Package level" -Min 1 -Max 3
    switch ($choice) {
        1 { $Script:PackageLevel = "Minimal" }
        2 { $Script:PackageLevel = "Solid" }
        3 { $Script:PackageLevel = "Overkill" }
    }
    Save-Session
}

function Select-OutputFormat {
    Write-Header
    Write-Host "Editable build-list output" -ForegroundColor Cyan
    Write-Host "The tool creates editable FolderStructure and ToolList files before writing a USB."
    Write-Host "Change Include to No in ToolList_SOURCE_OF_TRUTH.csv to remove items from the build. No row deletion is needed."
    Write-Host ""
    Write-Host " 1. CSV only"
    Write-Host " 2. CSV plus XLSX workbook"
    Write-Host ""
    $choice = Read-MenuChoice -Prompt "Output option" -Min 1 -Max 2
    if ($choice -eq 1) { $Script:OutputFormat = "CSV" } else { $Script:OutputFormat = "CSV+XLSX" }
    Save-Session
}


function Select-BuildTarget {
    Write-Header
    Write-Host "Where should this build be written?" -ForegroundColor Cyan
    Write-Host " 1. USB / removable toolkit - safest default for field drives"
    Write-Host " 2. Local machine install   - build the same structure on C: or another local drive"
    Write-Host ""
    Write-Host "Local install mode is useful for a storage SSD or workstation toolkit folder." -ForegroundColor Gray
    Write-Host "It creates folders, templates, source records, and optional user-enabled downloads. It does not install software." -ForegroundColor Yellow
    Write-Host ""
    $choice = Read-MenuChoice -Prompt "Build target" -Min 1 -Max 2
    if ($choice -eq 1) { $Script:BuildTarget = "USB Toolkit" } else { $Script:BuildTarget = "Local Install" }
    Save-Session
}

function Get-LevelRank {
    param([string]$Level)
    switch ($Level) {
        "Minimal" { return 1 }
        "Solid" { return 2 }
        "Overkill" { return 3 }
        default { return 2 }
    }
}

function Test-LevelIncluded {
    param([string]$RequiredLevel, [string]$SelectedLevel)
    return ((Get-LevelRank -Level $RequiredLevel) -le (Get-LevelRank -Level $SelectedLevel))
}

function New-FolderRow {
    param([string]$Purpose, [string]$RequiredLevel, [string]$DriveRole, [string]$RelativePath, [string]$Notes)
    [pscustomobject]@{
        Include = "Yes"
        Purpose = $Purpose
        PackageLevel = $RequiredLevel
        DriveRole = $DriveRole
        RelativePath = $RelativePath
        Notes = $Notes
    }
}


function Get-SourceHost {
    param([string]$Url)
    try {
        if ([string]::IsNullOrWhiteSpace($Url)) { return "" }
        return ([System.Uri]$Url).Host.ToLowerInvariant()
    }
    catch { return "" }
}

function Get-SourceVettingStatus {
    param([string]$ToolName, [string]$OfficialSourceURL)
    $sourceHost = Get-SourceHost -Url $OfficialSourceURL
    if ($sourceHost -in @(
        "learn.microsoft.com", "download.sysinternals.com", "www.7-zip.org", "7-zip.org",
        "www.wireshark.org", "ericzimmerman.github.io", "github.com", "www.nirsoft.net",
        "www.voidtools.com", "notepad-plus-plus.org", "winscp.net", "rufus.ie",
        "www.ventoy.net", "sqlitebrowser.org", "exiftool.org", "www.torproject.org"
    )) {
        return "Publisher-controlled source page reviewed"
    }
    return "Needs manual review before enabling downloads"
}

function Get-SourceVettingNotes {
    param([string]$ToolName, [string]$OfficialSourceURL)
    $sourceHost = Get-SourceHost -Url $OfficialSourceURL
    if ($ToolName -eq "Microsoft Sysinternals Suite") {
        return "Official Microsoft Learn page and Microsoft download CDN are used for source reference. Direct download can be enabled by the user."
    }
    if ($sourceHost -eq "www.7-zip.org" -or $sourceHost -eq "7-zip.org") {
        return "Official 7-Zip project site. Versioned direct URLs change over time; source page is recorded for user review."
    }
    if ($sourceHost -eq "www.wireshark.org") {
        return "Official Wireshark download page. Installer versions change; source page is recorded for user review."
    }
    if ($sourceHost -eq "ericzimmerman.github.io") {
        return "Official Eric Zimmerman tools site. Download method should follow publisher guidance."
    }
    if ($sourceHost -eq "github.com") {
        return "Official upstream GitHub project page recorded. Release asset selection still needs per-tool review."
    }
    if ([string]::IsNullOrWhiteSpace($sourceHost)) { return "No official source URL recorded." }
    return "Source page recorded. Confirm publisher control, license, and direct download behavior before enabling automatic download."
}

function Get-DefaultDirectDownloadUrl {
    param([string]$ToolName)
    switch ($ToolName) {
        "Microsoft Sysinternals Suite" { return "https://download.sysinternals.com/files/SysinternalsSuite.zip" }
        default { return "" }
    }
}

function Get-DefaultDownloadEnabled {
    param([string]$ToolName)
    if ($ToolName -eq "Microsoft Sysinternals Suite") { return "Yes" }
    return "No"
}

function Get-DefaultLocalFileName {
    param([string]$ToolName, [string]$DirectDownloadURL)
    if ($ToolName -eq "Microsoft Sysinternals Suite") { return "SysinternalsSuite.zip" }
    try {
        if (-not [string]::IsNullOrWhiteSpace($DirectDownloadURL)) { return [System.IO.Path]::GetFileName(([System.Uri]$DirectDownloadURL).AbsolutePath) }
    }
    catch {}
    return ""
}

function New-ToolRow {
    param(
        [string]$Purpose, [string]$RequiredLevel, [string]$Category, [string]$ToolName,
        [string]$TargetFolder, [string]$OfficialSourceURL, [string]$LicenseNotes,
        [string]$SourceNotes, [string]$Notes
    )
    [pscustomobject]@{
        Include = "Yes"
        Purpose = $Purpose
        PackageLevel = $RequiredLevel
        Category = $Category
        ToolName = $ToolName
        Version = ""
        TargetFolder = $TargetFolder
        OfficialSourceURL = $OfficialSourceURL
        SourceNotes = $SourceNotes
        LicenseNotes = $LicenseNotes
        SourceVettingStatus = (Get-SourceVettingStatus -ToolName $ToolName -OfficialSourceURL $OfficialSourceURL)
        SourceVettingNotes = (Get-SourceVettingNotes -ToolName $ToolName -OfficialSourceURL $OfficialSourceURL)
        SourceVettedOn = "2026-07-28"
        DownloadStatus = "Not downloaded"
        AcquisitionMode = "Official source page / optional direct download"
        DownloadEnabled = (Get-DefaultDownloadEnabled -ToolName $ToolName)
        InstallEnabled = "No"
        DirectDownloadURL = (Get-DefaultDirectDownloadUrl -ToolName $ToolName)
        LocalFileName = (Get-DefaultLocalFileName -ToolName $ToolName -DirectDownloadURL (Get-DefaultDirectDownloadUrl -ToolName $ToolName))
        DownloadPathMode = "UserProfileStagingThenCompleted"
        DownloadManifest = $Script:DownloadManifestCsv
        CopyDownloadedFileToBuild = "No"
        InstallerType = "ManualOrPortable"
        SilentInstallArgs = ""
        InstallCommand = ""
        InstallScope = "Portable or user-selected"
        Notes = $Notes
    }
}

function Get-BaseFolderCatalog {
    $rows = @()
    foreach ($role in @("All", "Primary field USB", "Master toolkit drive", "Large tools / ISO companion", "ISO / VM / media companion")) {
        $rows += New-FolderRow "Common" "Minimal" $role "_toolkit_admin" "Administrative files created by the builder."
        $rows += New-FolderRow "Common" "Minimal" $role "_toolkit_admin\manifests" "Editable manifests and tool lists."
        $rows += New-FolderRow "Common" "Minimal" $role "_toolkit_admin\planning" "Build plan CSV/XLSX outputs copied to the drive."
        $rows += New-FolderRow "Common" "Minimal" $role "_toolkit_admin\source_verification" "Source URL and source-published hash tracking."
        $rows += New-FolderRow "Common" "Minimal" $role "docs\attribution" "Source attribution records."
        $rows += New-FolderRow "Common" "Minimal" $role "docs\checklists" "Build and maintenance checklists."
        $rows += New-FolderRow "Common" "Solid" $role "scripts\powershell" "Local helper scripts written by the user."
        $rows += New-FolderRow "Common" "Solid" $role "scripts\batch" "Local helper batch files written by the user."
        $rows += New-FolderRow "Common" "Overkill" $role "docs\offline-reference" "Offline notes or references sourced by the user."
    }
    return $rows
}

function Get-PurposeFolderCatalog {
    $rows = @()
    $roles = @("All", "Field utility", "Primary field USB", "Master toolkit drive", "Large tools / ISO companion", "ISO / VM / media companion")

    foreach ($role in $roles) {
        $rows += New-FolderRow "IT Support" "Minimal" $role "it-support\portable-tools" "Portable IT support utilities."
        $rows += New-FolderRow "IT Support" "Minimal" $role "it-support\docs" "IT support documentation and checklists."
        $rows += New-FolderRow "IT Support" "Solid" $role "it-support\diagnostics" "Hardware and OS diagnostic tooling."
        $rows += New-FolderRow "IT Support" "Solid" $role "it-support\networking" "Network diagnostics and configuration notes."
        $rows += New-FolderRow "IT Support" "Solid" $role "it-support\drivers" "Drivers obtained by the user from official sources."
        $rows += New-FolderRow "IT Support" "Overkill" $role "it-support\installers-not-included" "Installer staging area populated by the user."
        $rows += New-FolderRow "IT Support" "Overkill" $role "it-support\firmware-bios-not-included" "Firmware/BIOS files populated by the user."

        $rows += New-FolderRow "DFIR" "Minimal" $role "dfir\docs" "DFIR checklists and notes."
        $rows += New-FolderRow "DFIR" "Minimal" $role "dfir\viewers" "Viewer or triage utility placeholders."
        $rows += New-FolderRow "DFIR" "Solid" $role "dfir\acquisition" "Acquisition-support tooling placeholders."
        $rows += New-FolderRow "DFIR" "Solid" $role "dfir\hashing-reference" "Hash/integrity reference notes, not a hash utility."
        $rows += New-FolderRow "DFIR" "Solid" $role "dfir\memory" "Memory/RAM tooling placeholders."
        $rows += New-FolderRow "DFIR" "Solid" $role "dfir\triage" "Triage tooling placeholders."
        $rows += New-FolderRow "DFIR" "Overkill" $role "dfir\mobile" "Mobile support tooling placeholders."
        $rows += New-FolderRow "DFIR" "Overkill" $role "dfir\timeline" "Timeline tooling placeholders."
        $rows += New-FolderRow "DFIR" "Overkill" $role "dfir\validation" "Tool-validation reference placeholders."

        $rows += New-FolderRow "OSINT" "Minimal" $role "osint\capture-notes" "Source capture notes and logs."
        $rows += New-FolderRow "OSINT" "Minimal" $role "osint\collection-templates" "Source collection templates."
        $rows += New-FolderRow "OSINT" "Solid" $role "osint\browser-tools" "Browser-related OSINT tooling placeholders."
        $rows += New-FolderRow "OSINT" "Solid" $role "osint\media-review" "Image/video/media review placeholders."
        $rows += New-FolderRow "OSINT" "Solid" $role "osint\network-dns" "Network/DNS/WHOIS reference placeholders."
        $rows += New-FolderRow "OSINT" "Overkill" $role "osint\link-analysis" "Link-analysis tooling placeholders."
        $rows += New-FolderRow "OSINT" "Overkill" $role "osint\maps-geolocation" "Map/geolocation reference placeholders."
    }

    $rows += New-FolderRow "Common" "Solid" "Large tools / ISO companion" "large-files-not-included" "Large files are not provided by this project."
    $rows += New-FolderRow "Common" "Solid" "Large tools / ISO companion" "large-files-not-included\download-notes" "Notes about user-sourced downloads."
    $rows += New-FolderRow "Common" "Overkill" "ISO / VM / media companion" "iso-not-included" "ISO files populated by the user."
    $rows += New-FolderRow "Common" "Overkill" "ISO / VM / media companion" "vm-notes" "VM import notes; no VM images included."
    return $rows
}

function Get-ToolCatalog {
    $rows = @()

    # IT Support - essential daily support, diagnostics, networking, recovery, and remote assistance records.
    $rows += New-ToolRow "IT Support" "Minimal" "Archive / File Utility" "7-Zip" "it-support\portable-tools\archive-viewers\7zip" "https://www.7-zip.org/" "Open source; confirm license from publisher." "Download manually from official project site." "Common archive utility for ZIP/7z/tar content."
    $rows += New-ToolRow "IT Support" "Minimal" "Text / Notes" "Notepad++" "it-support\portable-tools\text-viewers\notepad-plus-plus" "https://notepad-plus-plus.org/" "Open source; confirm license from publisher." "Download manually from official project site." "General text, config, and log review."
    $rows += New-ToolRow "IT Support" "Minimal" "File Search" "Everything" "it-support\portable-tools\file-search\everything" "https://www.voidtools.com/" "Confirm license from publisher." "Download manually from publisher site." "Fast file name search utility."
    $rows += New-ToolRow "IT Support" "Minimal" "Remote Shell" "PuTTY" "it-support\networking\putty" "https://www.chiark.greenend.org.uk/~sgtatham/putty/" "Confirm license from publisher." "Download manually from official publisher page." "SSH/Telnet client for support workflows."
    $rows += New-ToolRow "IT Support" "Minimal" "File Transfer" "WinSCP" "it-support\networking\winscp" "https://winscp.net/eng/download.php" "Confirm license from publisher." "Download manually from official project site." "SFTP/SCP/FTP file transfer utility."
    $rows += New-ToolRow "IT Support" "Minimal" "USB Boot Media" "Rufus" "it-support\boot-media\rufus" "https://rufus.ie/" "Confirm license from publisher." "Download manually from official project site." "Bootable USB creation utility."
    $rows += New-ToolRow "IT Support" "Solid" "Sysinternals" "Microsoft Sysinternals Suite" "it-support\diagnostics\sysinternals" "https://learn.microsoft.com/sysinternals/downloads/sysinternals-suite" "Microsoft license/terms apply." "Download manually from Microsoft Learn." "Common Windows diagnostic toolkit."
    $rows += New-ToolRow "IT Support" "Solid" "Hardware" "HWiNFO" "it-support\diagnostics\hwinfo" "https://www.hwinfo.com/download/" "Confirm license from publisher." "Download manually from official project site." "Hardware information utility."
    $rows += New-ToolRow "IT Support" "Solid" "Storage Health" "CrystalDiskInfo" "it-support\diagnostics\crystaldiskinfo" "https://crystalmark.info/en/software/crystaldiskinfo/" "Confirm license from publisher." "Download manually from official publisher site." "Drive health/S.M.A.R.T. review utility."
    $rows += New-ToolRow "IT Support" "Solid" "Storage Benchmark" "CrystalDiskMark" "it-support\diagnostics\crystaldiskmark" "https://crystalmark.info/en/software/crystaldiskmark/" "Confirm license from publisher." "Download manually from official publisher site." "Drive benchmark utility for support testing."
    $rows += New-ToolRow "IT Support" "Solid" "Network" "Wireshark" "it-support\networking\wireshark" "https://www.wireshark.org/download.html" "Confirm license from publisher." "Download manually from official project site." "Network protocol analyzer."
    $rows += New-ToolRow "IT Support" "Solid" "Network" "Nmap" "it-support\networking\nmap" "https://nmap.org/download.html" "Confirm license and commercial-use terms from publisher." "Download manually from official project site." "Network discovery/security auditing tool; use only where authorized."
    $rows += New-ToolRow "IT Support" "Solid" "Network" "Advanced IP Scanner" "it-support\networking\advanced-ip-scanner" "https://www.advanced-ip-scanner.com/" "Confirm license from publisher." "Download manually from publisher site." "Local network discovery utility."
    $rows += New-ToolRow "IT Support" "Solid" "Boot Media" "Ventoy" "it-support\boot-media\ventoy" "https://www.ventoy.net/en/download.html" "Confirm license from publisher." "Download manually from official project site." "Multi-ISO boot USB utility."
    $rows += New-ToolRow "IT Support" "Solid" "Driver / Device" "DriverStore Explorer" "it-support\drivers\driverstore-explorer" "https://github.com/lostindark/DriverStoreExplorer" "Confirm license from upstream project." "Download manually from official GitHub project." "Driver store review and cleanup utility."
    $rows += New-ToolRow "IT Support" "Solid" "Display / GPU" "GPU-Z" "it-support\diagnostics\gpu-z" "https://www.techpowerup.com/gpuz/" "Confirm license from publisher." "Download manually from publisher site." "Graphics hardware information utility."
    $rows += New-ToolRow "IT Support" "Solid" "CPU / Hardware" "CPU-Z" "it-support\diagnostics\cpu-z" "https://www.cpuid.com/softwares/cpu-z.html" "Confirm license from publisher." "Download manually from publisher site." "CPU/mainboard/memory information utility."
    $rows += New-ToolRow "IT Support" "Overkill" "Remote Support" "RustDesk" "it-support\portable-tools\remote-support\rustdesk" "https://rustdesk.com/" "Confirm license and deployment terms." "Download manually from official project site." "Remote support option; use only where policy allows."
    $rows += New-ToolRow "IT Support" "Overkill" "Password / Credential Admin" "KeePassXC" "it-support\admin-tools\keepassxc" "https://keepassxc.org/download/" "Confirm license from publisher." "Download manually from official project site." "Password database utility for the user's own admin vaults; do not store secrets on shared USBs without policy approval."
    $rows += New-ToolRow "IT Support" "Overkill" "File Recovery" "PhotoRec / TestDisk" "it-support\recovery\testdisk-photorec" "https://www.cgsecurity.org/wiki/TestDisk_Download" "Confirm license from publisher." "Download manually from official project site." "File/partition recovery utilities for authorized support work."
    $rows += New-ToolRow "IT Support" "Overkill" "Windows Deployment" "Microsoft Windows ADK" "it-support\deployment\windows-adk" "https://learn.microsoft.com/windows-hardware/get-started/adk-install" "Microsoft license/terms apply." "Download manually from Microsoft Learn." "Deployment and assessment tools reference record."
    $rows += New-ToolRow "IT Support" "Overkill" "Endpoint Cleanup" "Microsoft Safety Scanner" "it-support\security\microsoft-safety-scanner" "https://learn.microsoft.com/defender-endpoint/safety-scanner-download" "Microsoft license/terms apply." "Download manually from Microsoft Learn." "On-demand malware scan utility; use under policy."

    # DFIR - acquisition support, triage, review, memory, event logs, and validation/support records.
    $rows += New-ToolRow "DFIR" "Minimal" "Imaging / Acquisition" "FTK Imager" "dfir\acquisition\ftk-imager" "https://www.exterro.com/ftk-product-downloads/ftk-imager-version-4-7-3" "Vendor terms apply." "Download manually from vendor site." "Common imaging/acquisition-support utility."
    $rows += New-ToolRow "DFIR" "Minimal" "Hash / Integrity" "HashMyFiles" "dfir\hashing-reference\hashmyfiles" "https://www.nirsoft.net/utils/hash_my_files.html" "Confirm license from publisher." "Download manually from publisher site." "Hash calculation utility; verify publisher terms."
    $rows += New-ToolRow "DFIR" "Minimal" "Archive / File Utility" "7-Zip" "dfir\review-support\archive-viewers\7zip" "https://www.7-zip.org/" "Open source; confirm license from publisher." "Download manually from official project site." "Archive extraction/review support."
    $rows += New-ToolRow "DFIR" "Minimal" "Text / Log Review" "Notepad++" "dfir\review-support\text-viewers\notepad-plus-plus" "https://notepad-plus-plus.org/" "Open source; confirm license from publisher." "Download manually from official project site." "Text/log/config review support."
    $rows += New-ToolRow "DFIR" "Solid" "Artifact Tools" "Eric Zimmerman Tools" "dfir\triage\eric-zimmerman-tools" "https://ericzimmerman.github.io/#!index.md" "Confirm tool-specific licenses and terms." "Download manually from official project page." "Common Windows artifact tools."
    $rows += New-ToolRow "DFIR" "Solid" "Triage" "KAPE" "dfir\triage\kape" "https://www.kroll.com/en/services/cyber-risk/incident-response-litigation-support/kroll-artifact-parser-extractor-kape" "Vendor terms apply." "Download manually from official vendor page." "Artifact collection/processing framework."
    $rows += New-ToolRow "DFIR" "Solid" "Memory" "Volatility 3" "dfir\memory\volatility3" "https://github.com/volatilityfoundation/volatility3" "Confirm license from upstream project." "Download manually from official GitHub project." "Memory analysis framework."
    $rows += New-ToolRow "DFIR" "Solid" "Memory" "MemProcFS" "dfir\memory\memprocfs" "https://github.com/ufrisk/MemProcFS" "Confirm license from upstream project." "Download manually from official GitHub project." "Memory analysis and virtual file system framework."
    $rows += New-ToolRow "DFIR" "Solid" "Viewer" "Autopsy" "dfir\viewers\autopsy" "https://www.autopsy.com/download/" "Confirm license from publisher." "Download manually from official project site." "Digital forensics platform/viewer."
    $rows += New-ToolRow "DFIR" "Solid" "Event Logs" "Hayabusa" "dfir\event-logs\hayabusa" "https://github.com/Yamato-Security/hayabusa" "Confirm license from upstream project." "Download manually from official GitHub project." "Windows event log triage/threat hunting tool."
    $rows += New-ToolRow "DFIR" "Solid" "Event Logs" "Chainsaw" "dfir\event-logs\chainsaw" "https://github.com/WithSecureLabs/chainsaw" "Confirm license from upstream project." "Download manually from official GitHub project." "Windows event log search and hunting utility."
    $rows += New-ToolRow "DFIR" "Solid" "Windows Analysis" "Velociraptor" "dfir\triage\velociraptor" "https://docs.velociraptor.app/downloads/" "Confirm license and deployment terms from publisher." "Download manually from official project site." "Endpoint visibility/collection framework; use only where authorized."
    $rows += New-ToolRow "DFIR" "Solid" "Network" "Wireshark" "dfir\network\wireshark" "https://www.wireshark.org/download.html" "Confirm license from publisher." "Download manually from official project site." "Packet capture and protocol analysis utility."
    $rows += New-ToolRow "DFIR" "Solid" "Hex / Binary Viewer" "HxD" "dfir\review-support\hex-viewers\hxd" "https://mh-nexus.de/en/hxd/" "Confirm license from publisher." "Download manually from publisher site." "Hex editor/viewer for authorized analysis."
    $rows += New-ToolRow "DFIR" "Solid" "SQLite Review" "DB Browser for SQLite" "dfir\review-support\sqlite\db-browser-for-sqlite" "https://sqlitebrowser.org/dl/" "Confirm license from publisher." "Download manually from official project site." "SQLite database viewing utility."
    $rows += New-ToolRow "DFIR" "Overkill" "Disk / Mounting" "Arsenal Image Mounter" "dfir\acquisition\arsenal-image-mounter" "https://arsenalrecon.com/products/arsenal-image-mounter" "Vendor terms apply." "Download manually from vendor site." "Image mounting utility."
    $rows += New-ToolRow "DFIR" "Overkill" "Disk / Mounting" "OSFMount" "dfir\acquisition\osfmount" "https://www.osforensics.com/tools/mount-disk-images.html" "Vendor terms apply." "Download manually from vendor site." "Disk image mounting utility."
    $rows += New-ToolRow "DFIR" "Overkill" "DFIR Suite" "OSForensics" "dfir\viewers\osforensics" "https://www.osforensics.com/download.html" "Vendor terms apply." "Download manually from vendor site." "Forensic review platform; confirm licensing before use."
    $rows += New-ToolRow "DFIR" "Overkill" "Timeline" "Plaso / log2timeline" "dfir\timeline\plaso-log2timeline" "https://github.com/log2timeline/plaso" "Confirm license from upstream project." "Download manually from official GitHub project." "Timeline generation framework."
    $rows += New-ToolRow "DFIR" "Overkill" "Timeline" "Timesketch" "dfir\timeline\timesketch" "https://github.com/google/timesketch" "Confirm license and deployment requirements from upstream project." "Download manually from official GitHub project." "Collaborative timeline analysis platform."
    $rows += New-ToolRow "DFIR" "Overkill" "Malware / File Review" "YARA" "dfir\file-review\yara" "https://github.com/VirusTotal/yara" "Confirm license from upstream project." "Download manually from official GitHub project." "Pattern matching tool; use rules from trusted sources and validate locally."
    $rows += New-ToolRow "DFIR" "Overkill" "Malware / File Review" "Detect It Easy" "dfir\file-review\detect-it-easy" "https://github.com/horsicq/Detect-It-Easy" "Confirm license from upstream project." "Download manually from official GitHub project." "File type/packer identification utility."
    $rows += New-ToolRow "DFIR" "Overkill" "Parsing / Utility" "CyberChef" "dfir\review-support\cyberchef" "https://github.com/gchq/CyberChef" "Confirm license from upstream project." "Download manually from official GitHub project or official project page." "Encoding/decoding and data transformation utility."

    # OSINT - capture, citation, domain/network research, media metadata, and analysis workspace records.
    $rows += New-ToolRow "OSINT" "Minimal" "Capture / Notes" "Hunchly" "osint\capture-notes\hunchly" "https://www.hunch.ly/" "Commercial/vendor terms apply." "Download manually from vendor site if licensed." "Web capture/case note tool; optional and policy-dependent."
    $rows += New-ToolRow "OSINT" "Minimal" "Archive / File Utility" "7-Zip" "osint\media-review\archive-viewers\7zip" "https://www.7-zip.org/" "Open source; confirm license from publisher." "Download manually from official project site." "Archive extraction/review support."
    $rows += New-ToolRow "OSINT" "Minimal" "Notes / Workspace" "Obsidian" "osint\notes-workspace\obsidian" "https://obsidian.md/download" "Commercial/personal-use terms may apply; confirm from publisher." "Download manually from official site." "Markdown note workspace."
    $rows += New-ToolRow "OSINT" "Minimal" "Notes / Workspace" "Joplin" "osint\notes-workspace\joplin" "https://joplinapp.org/help/install/" "Confirm license from publisher." "Download manually from official project site." "Open-source note workspace."
    $rows += New-ToolRow "OSINT" "Solid" "Media Metadata" "ExifTool" "osint\media-review\exiftool" "https://exiftool.org/" "Confirm license from publisher." "Download manually from official project site." "Metadata inspection utility."
    $rows += New-ToolRow "OSINT" "Solid" "Screenshots / Capture" "ShareX" "osint\capture-notes\sharex" "https://getsharex.com/downloads" "Confirm license from publisher." "Download manually from official project site." "Screenshot and screen capture utility."
    $rows += New-ToolRow "OSINT" "Solid" "Screenshots / Capture" "Greenshot" "osint\capture-notes\greenshot" "https://getgreenshot.org/downloads/" "Confirm license from publisher." "Download manually from official project site." "Screenshot capture utility."
    $rows += New-ToolRow "OSINT" "Solid" "Network / Domains" "Amass" "osint\network-dns\amass" "https://github.com/owasp-amass/amass" "Confirm license from upstream project." "Download manually from official GitHub project." "External asset discovery tool; use only where authorized."
    $rows += New-ToolRow "OSINT" "Solid" "Network / Domains" "theHarvester" "osint\network-dns\theharvester" "https://github.com/laramies/theHarvester" "Confirm license from upstream project." "Download manually from official GitHub project." "Email/domain OSINT collection tool; use only where authorized."
    $rows += New-ToolRow "OSINT" "Solid" "Transform / Decode" "CyberChef" "osint\review-support\cyberchef" "https://github.com/gchq/CyberChef" "Confirm license from upstream project." "Download manually from official GitHub project or official project page." "Encoding/decoding and data transformation utility."
    $rows += New-ToolRow "OSINT" "Solid" "Link / Graph Notes" "yEd Graph Editor" "osint\link-analysis\yed" "https://www.yworks.com/products/yed/download" "Vendor terms apply." "Download manually from publisher site." "Graphing/link-diagram utility."
    $rows += New-ToolRow "OSINT" "Overkill" "Link Analysis" "Maltego" "osint\link-analysis\maltego" "https://www.maltego.com/downloads/" "Commercial/vendor terms apply." "Download manually from vendor site if licensed." "Link analysis platform."
    $rows += New-ToolRow "OSINT" "Overkill" "Automation / Collection" "SpiderFoot" "osint\automation\spiderfoot" "https://github.com/smicallef/spiderfoot" "Confirm license and use terms from upstream project." "Download manually from official GitHub project." "OSINT automation platform; use only where authorized and policy allows."
    $rows += New-ToolRow "OSINT" "Overkill" "Media / Geolocation" "GeoSetter" "osint\maps-geolocation\geosetter" "https://geosetter.de/en/download/" "Confirm license from publisher." "Download manually from publisher site." "Photo geotag/location metadata review utility."
    $rows += New-ToolRow "OSINT" "Overkill" "Mapping / Geospatial" "QGIS" "osint\maps-geolocation\qgis" "https://qgis.org/download/" "Confirm license from publisher." "Download manually from official project site." "Geospatial analysis/mapping platform."
    $rows += New-ToolRow "OSINT" "Overkill" "Browser / Research" "Tor Browser" "osint\browsers\tor-browser" "https://www.torproject.org/download/" "Confirm license and policy/agency approval before use." "Download manually from official project site." "Privacy-focused browser; use only where lawful and policy-approved."

    return $rows
}

function Get-FilteredToolRows {
    param([string]$Purpose, [string]$Level)
    $purposes = @(Get-PurposeList -Purpose $Purpose)
    return @(Get-ToolCatalog | Where-Object { ($purposes -contains $_.Purpose) -and (Test-LevelIncluded -RequiredLevel $_.PackageLevel -SelectedLevel $Level) })
}

function Get-FilteredFolderRows {
    param([string]$Purpose, [string]$Level)
    $purposes = @(Get-PurposeList -Purpose $Purpose) + @("Common")
    return @((Get-BaseFolderCatalog) + (Get-PurposeFolderCatalog) | Where-Object { ($purposes -contains $_.Purpose) -and (Test-LevelIncluded -RequiredLevel $_.PackageLevel -SelectedLevel $Level) })
}

function Get-DriveBuildPlan {
    param([string]$Purpose, [string]$Level)
    $items = @()
    if ($Purpose -eq "Everything") {
        if ($Level -eq "Minimal") {
            $items += [pscustomobject]@{ Role="Combined field USB"; SuggestedSize="32GB"; MinGB=16; Include=@("common", "purpose-minimal"); Notes="Lean combined IT/DFIR/OSINT structure." }
            return $items
        }
        if ($Level -eq "Solid") {
            $items += [pscustomobject]@{ Role="Combined primary USB"; SuggestedSize="64GB or 128GB"; MinGB=64; Include=@("common", "purpose-solid"); Notes="Practical combined IT/DFIR/OSINT toolkit structure." }
            $items += [pscustomobject]@{ Role="Large tools / ISO companion"; SuggestedSize="128GB or 256GB"; MinGB=128; Include=@("large-placeholders"); Notes="Companion for larger user-sourced tools, ISOs, and installers." }
            return $items
        }
        $items += [pscustomobject]@{ Role="Combined primary USB"; SuggestedSize="128GB"; MinGB=64; Include=@("common", "purpose-solid"); Notes="Daily combined IT/DFIR/OSINT drive." }
        $items += [pscustomobject]@{ Role="Master everything drive"; SuggestedSize="256GB+"; MinGB=256; Include=@("common", "purpose-overkill", "large-placeholders"); Notes="Broad master toolkit populated locally by the user." }
        $items += [pscustomobject]@{ Role="ISO / VM / media companion"; SuggestedSize="256GB+"; MinGB=256; Include=@("large-placeholders", "media-placeholders"); Notes="Separate companion for large local files. No media is included." }
        return $items
    }
    if ($Level -eq "Minimal") {
        $items += [pscustomobject]@{ Role="Field utility"; SuggestedSize="8GB or 16GB"; MinGB=8; Include=@("common", "purpose-minimal"); Notes="Lean folder/template set for essential field organization." }
        return $items
    }
    if ($Level -eq "Solid") {
        $items += [pscustomobject]@{ Role="Primary field USB"; SuggestedSize="32GB"; MinGB=16; Include=@("common", "purpose-solid"); Notes="Practical daily-use toolkit structure." }
        $items += [pscustomobject]@{ Role="Large tools / ISO companion"; SuggestedSize="64GB or 128GB"; MinGB=64; Include=@("large-placeholders"); Notes="Optional companion for ISOs, larger installers, or bigger local tool sets you add yourself." }
        return $items
    }
    $items += [pscustomobject]@{ Role="Primary field USB"; SuggestedSize="32GB"; MinGB=16; Include=@("common", "purpose-solid"); Notes="Quick access daily-use drive." }
    $items += [pscustomobject]@{ Role="Master toolkit drive"; SuggestedSize="128GB or 256GB"; MinGB=128; Include=@("common", "purpose-overkill", "large-placeholders"); Notes="Full folder structure for broad local build-out." }
    $items += [pscustomobject]@{ Role="ISO / VM / media companion"; SuggestedSize="256GB+"; MinGB=256; Include=@("large-placeholders", "media-placeholders"); Notes="Separate companion for large files you source locally." }
    return $items
}

function Build-PlanFromAnswers {
    if ($Script:BuildTarget -eq "Local Install") {
        $suggested = "32GB+ free"
        $min = 32
        if ($Script:PackageLevel -eq "Minimal") { $suggested = "8GB+ free"; $min = 8 }
        elseif ($Script:PackageLevel -eq "Overkill") { $suggested = "128GB+ free"; $min = 128 }
        $Script:BuildPlan = @([pscustomobject]@{
            Role="Local toolkit install"
            SuggestedSize=$suggested
            MinGB=$min
            Include=@("common", "purpose-$($Script:PackageLevel.ToLowerInvariant())")
            Notes="Builds the selected toolkit structure under a local folder on C: or another selected drive."
        })
    }
    else {
        $Script:BuildPlan = @(Get-DriveBuildPlan -Purpose $Script:Purpose -Level $Script:PackageLevel)
    }
    Save-Session
}

function Show-BuildPlan {
    Write-Header
    Write-Host "Generated USB build path" -ForegroundColor Cyan
    Write-Host "Interaction: $Script:InteractionLevel"
    Write-Host "Purpose:     $Script:Purpose"
    Write-Host "Package:     $Script:PackageLevel"
    Write-Host "Target:      $Script:BuildTarget"
    Write-Host "Output:      $Script:OutputFormat"
    Write-Host ""
    $i = 1
    foreach ($drive in $Script:BuildPlan) {
        Write-Host "$i. $($drive.Role)" -ForegroundColor Green
        Write-Host "   Suggested size: $($drive.SuggestedSize)"
        Write-Host "   Minimum size:   $($drive.MinGB) GB"
        Write-Host "   Notes:          $($drive.Notes)"
        Write-Host ""
        $i++
    }
    Write-Host "This is a folder/template/source-list build path. Populate tools locally from official sources." -ForegroundColor Yellow
}

function Export-EditableBuildLists {
    Ensure-SessionDir
    $folders = @(Get-FilteredFolderRows -Purpose $Script:Purpose -Level $Script:PackageLevel)
    $tools = @(Get-FilteredToolRows -Purpose $Script:Purpose -Level $Script:PackageLevel)
    $folders | Export-Csv -Path $Script:FolderListCsv -NoTypeInformation -Encoding UTF8
    $tools | Export-Csv -Path $Script:ToolListCsv -NoTypeInformation -Encoding UTF8
    Export-DownloadInstallQueue -ToolRows $tools
    if ($Script:OutputFormat -eq "CSV+XLSX") { Export-BuildWorkbookXlsx -FolderRows $folders -ToolRows $tools }
}


function Export-DownloadInstallQueue {
    param([object[]]$ToolRows)
    Ensure-SessionDir
    $queue = @()
    foreach ($tool in $ToolRows) {
        $queue += [pscustomobject]@{
            Include = $tool.Include
            Purpose = $tool.Purpose
            PackageLevel = $tool.PackageLevel
            Category = $tool.Category
            ToolName = $tool.ToolName
            TargetFolder = $tool.TargetFolder
            OfficialSourceURL = $tool.OfficialSourceURL
            SourceVettingStatus = $tool.SourceVettingStatus
            SourceVettingNotes = $tool.SourceVettingNotes
            DirectDownloadURL = $tool.DirectDownloadURL
            DownloadEnabled = $tool.DownloadEnabled
            InstallEnabled = $tool.InstallEnabled
            AcquisitionMode = $tool.AcquisitionMode
            InstallerType = $tool.InstallerType
            LocalFileName = $tool.LocalFileName
            DownloadPathMode = $tool.DownloadPathMode
            CopyDownloadedFileToBuild = $tool.CopyDownloadedFileToBuild
            SilentInstallArgs = $tool.SilentInstallArgs
            InstallCommand = $tool.InstallCommand
            InstallScope = $tool.InstallScope
            InfrastructureStatus = "Automatic download available only when Include=Yes, DownloadEnabled=Yes, and DirectDownloadURL is populated. Install execution disabled."
            Boundary = "Use official publisher-controlled sources. Verify source-published hashes where available."
        }
    }
    $queue | Export-Csv -Path $Script:DownloadQueueCsv -NoTypeInformation -Encoding UTF8
}

function Normalize-YesNo {
    param([object]$Value)
    if ($null -eq $Value) { return $false }
    return ([string]$Value -match '^(?i:y|yes|true|1)$')
}

function Get-SafePathPart {
    param([string]$Value)
    if ([string]::IsNullOrWhiteSpace($Value)) { return "unknown" }
    $safe = $Value -replace '[\\/:*?"<>|]', '-'
    $safe = $safe.Trim()
    if ([string]::IsNullOrWhiteSpace($safe)) { return "unknown" }
    return $safe
}

function Get-DownloadFileName {
    param([object]$Tool)
    if ($Tool.LocalFileName -and -not [string]::IsNullOrWhiteSpace([string]$Tool.LocalFileName)) { return [string]$Tool.LocalFileName }
    try {
        if ($Tool.DirectDownloadURL) {
            $name = [System.IO.Path]::GetFileName(([System.Uri]([string]$Tool.DirectDownloadURL)).AbsolutePath)
            if (-not [string]::IsNullOrWhiteSpace($name)) { return $name }
        }
    }
    catch {}
    return ((Get-SafePathPart -Value ([string]$Tool.ToolName)) + ".download")
}

function New-DownloadManifestRow {
    param(
        [object]$Tool, [string]$Status, [string]$FilePath, [string]$Sha256, [string]$ErrorMessage,
        [long]$Bytes = 0
    )
    [pscustomobject]@{
        Timestamp = (Get-Date).ToString("o")
        Status = $Status
        ToolName = [string]$Tool.ToolName
        Purpose = [string]$Tool.Purpose
        Category = [string]$Tool.Category
        OfficialSourceURL = [string]$Tool.OfficialSourceURL
        DirectDownloadURL = [string]$Tool.DirectDownloadURL
        LocalFileName = (Get-DownloadFileName -Tool $Tool)
        DownloadedFilePath = $FilePath
        SHA256 = $Sha256
        Bytes = $Bytes
        SourceVettingStatus = [string]$Tool.SourceVettingStatus
        SourceVettingNotes = [string]$Tool.SourceVettingNotes
        HashVerificationReminder = "Compare this SHA-256 against a publisher/source-published hash when available. If no publisher hash is available, this hash only records what was downloaded locally."
        Error = $ErrorMessage
    }
}

function Export-DownloadManifest {
    param([object[]]$Rows)
    Ensure-SessionDir
    if ($Rows.Count -eq 0) { return }
    if (Test-Path $Script:DownloadManifestCsv) {
        $existing = @(Import-Csv -Path $Script:DownloadManifestCsv)
        $Rows = @($existing) + @($Rows)
    }
    $Rows | Export-Csv -Path $Script:DownloadManifestCsv -NoTypeInformation -Encoding UTF8
}

function Invoke-EnabledDownloads {
    Ensure-SessionDir
    if (-not (Test-Path $Script:ToolListCsv)) { Export-EditableBuildLists }
    $tools = @(Import-Csv -Path $Script:ToolListCsv | Where-Object {
        (Normalize-YesNo $_.Include) -and (Normalize-YesNo $_.DownloadEnabled) -and -not [string]::IsNullOrWhiteSpace([string]$_.DirectDownloadURL)
    })
    Write-Header
    Write-Host "Download enabled source-of-truth items" -ForegroundColor Cyan
    Write-Host "Source of truth: $Script:ToolListCsv"
    Write-Host "Download root:    $Script:DownloadRoot"
    Write-Host "Manifest:         $Script:DownloadManifestCsv"
    Write-Host "Items to attempt: $($tools.Count)"
    Write-Host ""
    Write-Host "Files are downloaded to a user-profile staging folder, hashed, then moved to completed downloads." -ForegroundColor Gray
    Write-Host "The tool does not install software or claim the publisher hash was verified." -ForegroundColor Yellow
    Write-Host ""
    if ($tools.Count -eq 0) {
        Write-Host "No rows are enabled for download. Set Include=Yes, DownloadEnabled=Yes, and DirectDownloadURL in ToolList_SOURCE_OF_TRUTH.csv." -ForegroundColor Yellow
        Pause-Menu
        return
    }
    $confirm = Read-Host "Type DOWNLOAD to start"
    if ($confirm -ne "DOWNLOAD") { Write-Host "Download cancelled." -ForegroundColor Yellow; Pause-Menu; return }

    $manifestRows = @()
    foreach ($tool in $tools) {
        $toolNameSafe = Get-SafePathPart -Value ([string]$tool.ToolName)
        $purposeSafe = Get-SafePathPart -Value ([string]$tool.Purpose)
        $destDir = Join-Path (Join-Path $Script:DownloadCompletedDir $purposeSafe) $toolNameSafe
        New-Item -ItemType Directory -Force -Path $destDir | Out-Null
        $fileName = Get-DownloadFileName -Tool $tool
        $stagingPath = Join-Path $Script:DownloadStagingDir ("{0}-{1}" -f ([guid]::NewGuid().ToString("N")), $fileName)
        $completedPath = Join-Path $destDir $fileName
        Write-Host "Downloading: $($tool.ToolName)" -ForegroundColor Cyan
        Write-Host "  From: $($tool.DirectDownloadURL)" -ForegroundColor DarkGray
        try {
            Invoke-WebRequest -Uri ([string]$tool.DirectDownloadURL) -OutFile $stagingPath -UseBasicParsing
            $hash = Get-FileHash -Algorithm SHA256 -Path $stagingPath
            $bytes = (Get-Item $stagingPath).Length
            if (Test-Path $completedPath) { Remove-Item -Force $completedPath }
            Move-Item -Force -Path $stagingPath -Destination $completedPath
            $manifestRows += New-DownloadManifestRow -Tool $tool -Status "Success" -FilePath $completedPath -Sha256 $hash.Hash -ErrorMessage "" -Bytes $bytes
            Write-Host "  Success. SHA-256: $($hash.Hash)" -ForegroundColor Green
        }
        catch {
            $err = $_.Exception.Message
            if (Test-Path $stagingPath) { Remove-Item -Force $stagingPath -ErrorAction SilentlyContinue }
            $manifestRows += New-DownloadManifestRow -Tool $tool -Status "Failed" -FilePath "" -Sha256 "" -ErrorMessage $err -Bytes 0
            Write-Host "  Failed: $err" -ForegroundColor Yellow
        }
    }
    Export-DownloadManifest -Rows $manifestRows
    Write-Host ""
    Write-Host "Download manifest updated: $Script:DownloadManifestCsv" -ForegroundColor Green
    Pause-Menu
}

function Show-DownloadInstallInfrastructure {
    Ensure-SessionDir
    if (-not (Test-Path $Script:DownloadQueueCsv)) { Export-EditableBuildLists }
    while ($true) {
        Write-Header
        Write-Host "Download manager" -ForegroundColor Cyan
        Write-Host "Source of truth: $Script:ToolListCsv"
        Write-Host "Queue/info file:  $Script:DownloadQueueCsv"
        Write-Host "Manifest:         $Script:DownloadManifestCsv"
        Write-Host "Download root:    $Script:DownloadRoot"
        Write-Host ""
        Write-Host "Downloads only run for rows with Include=Yes, DownloadEnabled=Yes, and DirectDownloadURL populated." -ForegroundColor Yellow
        Write-Host "Downloaded files are staged under your profile, hashed with SHA-256, then moved to completed downloads."
        Write-Host ""
        Write-Host " 1. Open planning folder"
        Write-Host " 2. Regenerate queue from current source-of-truth list"
        Write-Host " 3. Run enabled downloads"
        Write-Host " 4. Open downloads folder"
        Write-Host " 5. Open download manifest"
        Write-Host " 6. Back"
        Write-Host ""
        $choice = Read-MenuChoice -Prompt "Choice" -Min 1 -Max 6
        if ($choice -eq 1) { Start-Process explorer.exe $Script:PlanningDir; Pause-Menu }
        elseif ($choice -eq 2) {
            $tools = @(Import-CurrentToolRows)
            Export-DownloadInstallQueue -ToolRows $tools
            Write-Host "Queue regenerated: $Script:DownloadQueueCsv" -ForegroundColor Green
            Pause-Menu
        }
        elseif ($choice -eq 3) { Invoke-EnabledDownloads }
        elseif ($choice -eq 4) { Start-Process explorer.exe $Script:DownloadRoot; Pause-Menu }
        elseif ($choice -eq 5) {
            if (Test-Path $Script:DownloadManifestCsv) { Invoke-Item $Script:DownloadManifestCsv }
            else { Write-Host "No download manifest exists yet." -ForegroundColor Yellow }
            Pause-Menu
        }
        elseif ($choice -eq 6) { return }
    }
}

function Xml-Escape {
    param([object]$Value)
    if ($null -eq $Value) { return "" }
    return [System.Security.SecurityElement]::Escape([string]$Value)
}

function Add-ZipTextEntry {
    param([System.IO.Compression.ZipArchive]$Zip, [string]$Name, [string]$Content)
    $entry = $Zip.CreateEntry($Name)
    $stream = $entry.Open()
    $writer = New-Object System.IO.StreamWriter($stream, [System.Text.UTF8Encoding]::new($false))
    $writer.Write($Content)
    $writer.Dispose()
    $stream.Dispose()
}


function Get-ExcelColumnName {
    param([int]$Index)
    $name = ""
    while ($Index -gt 0) {
        $Index--
        $name = [char](65 + ($Index % 26)) + $name
        $Index = [math]::Floor($Index / 26)
    }
    return $name
}

function Convert-TableToWorksheetXml {
    param([object[]]$Rows, [string[]]$Headers)
    $sb = New-Object System.Text.StringBuilder
    [void]$sb.Append('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>')
    [void]$sb.Append('<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"><sheetData>')
    $r = 1
    [void]$sb.Append(('<row r="{0}">' -f $r))
    $c = 1
    foreach ($h in $Headers) {
        $cellRef = (Get-ExcelColumnName -Index $c) + $r
        [void]$sb.Append(('<c r="{0}" t="inlineStr"><is><t>{1}</t></is></c>' -f $cellRef, (Xml-Escape $h)))
        $c++
    }
    [void]$sb.Append('</row>')
    foreach ($row in $Rows) {
        $r++
        [void]$sb.Append(('<row r="{0}">' -f $r))
        $c = 1
        foreach ($h in $Headers) {
            $value = $row.$h
            $cellRef = (Get-ExcelColumnName -Index $c) + $r
            [void]$sb.Append(('<c r="{0}" t="inlineStr"><is><t>{1}</t></is></c>' -f $cellRef, (Xml-Escape $value)))
            $c++
        }
        [void]$sb.Append('</row>')
    }
    [void]$sb.Append('</sheetData></worksheet>')
    return $sb.ToString()
}

function Export-BuildWorkbookXlsx {
    param([object[]]$FolderRows, [object[]]$ToolRows)
    Ensure-SessionDir
    if (Test-Path $Script:BuildWorkbookXlsx) { Remove-Item -Force $Script:BuildWorkbookXlsx }
    Add-Type -AssemblyName System.IO.Compression
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $zipMode = [System.IO.Compression.ZipArchiveMode]::Create
    $zip = [System.IO.Compression.ZipFile]::Open($Script:BuildWorkbookXlsx, $zipMode)
    try {
        $buildHeaders = @("Field", "Value")
        $buildRows = @(
            [pscustomobject]@{ Field="AppVersion"; Value=$Script:AppVersion },
            [pscustomobject]@{ Field="InteractionLevel"; Value=$Script:InteractionLevel },
            [pscustomobject]@{ Field="Purpose"; Value=$Script:Purpose },
            [pscustomobject]@{ Field="PackageLevel"; Value=$Script:PackageLevel },
            [pscustomobject]@{ Field="Generated"; Value=(Get-Date).ToString("o") },
            [pscustomobject]@{ Field="Boundary"; Value="This builder does not download, bundle, format, erase, or redistribute third-party tools." }
        )
        Add-ZipTextEntry $zip "[Content_Types].xml" '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="xml" ContentType="application/xml"/><Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/><Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/><Override PartName="/xl/worksheets/sheet2.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/><Override PartName="/xl/worksheets/sheet3.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/><Override PartName="/xl/worksheets/sheet4.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/></Types>'
        Add-ZipTextEntry $zip "_rels/.rels" '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/></Relationships>'
        Add-ZipTextEntry $zip "xl/workbook.xml" '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"><sheets><sheet name="BuildPlan" sheetId="1" r:id="rId1"/><sheet name="FolderStructure" sheetId="2" r:id="rId2"/><sheet name="ToolList" sheetId="3" r:id="rId3"/><sheet name="DownloadQueue" sheetId="4" r:id="rId4"/></sheets></workbook>'
        Add-ZipTextEntry $zip "xl/_rels/workbook.xml.rels" '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/><Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet2.xml"/><Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet3.xml"/><Relationship Id="rId4" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet4.xml"/></Relationships>'
        Add-ZipTextEntry $zip "xl/worksheets/sheet1.xml" (Convert-TableToWorksheetXml -Rows $buildRows -Headers $buildHeaders)
        Add-ZipTextEntry $zip "xl/worksheets/sheet2.xml" (Convert-TableToWorksheetXml -Rows $FolderRows -Headers @("Include","Purpose","PackageLevel","DriveRole","RelativePath","Notes"))
        Add-ZipTextEntry $zip "xl/worksheets/sheet3.xml" (Convert-TableToWorksheetXml -Rows $ToolRows -Headers @("Include","Purpose","PackageLevel","Category","ToolName","Version","TargetFolder","OfficialSourceURL","SourceNotes","LicenseNotes","SourceVettingStatus","SourceVettingNotes","SourceVettedOn","DownloadStatus","AcquisitionMode","DownloadEnabled","InstallEnabled","DirectDownloadURL","LocalFileName","DownloadPathMode","DownloadManifest","CopyDownloadedFileToBuild","InstallerType","SilentInstallArgs","InstallCommand","InstallScope","Notes"))
        $queueRows = @()
        foreach ($tool in $ToolRows) {
            $queueRows += [pscustomobject]@{ Include=$tool.Include; ToolName=$tool.ToolName; OfficialSourceURL=$tool.OfficialSourceURL; SourceVettingStatus=$tool.SourceVettingStatus; DirectDownloadURL=$tool.DirectDownloadURL; DownloadEnabled=$tool.DownloadEnabled; InstallEnabled=$tool.InstallEnabled; InstallerType=$tool.InstallerType; InstallCommand=$tool.InstallCommand; InfrastructureStatus="Queue only; download requires explicit enablement" }
        }
        Add-ZipTextEntry $zip "xl/worksheets/sheet4.xml" (Convert-TableToWorksheetXml -Rows $queueRows -Headers @("Include","ToolName","OfficialSourceURL","SourceVettingStatus","DirectDownloadURL","DownloadEnabled","InstallEnabled","InstallerType","InstallCommand","InfrastructureStatus"))
    }
    finally {
        $zip.Dispose()
    }
}

function Confirm-EditableLists {
    Export-EditableBuildLists
    Write-Header
    Write-Host "Editable build lists created" -ForegroundColor Cyan
    Write-Host "Planning folder: $Script:PlanningDir"
    Write-Host "Folder plan/info:        $Script:FolderListCsv"
    Write-Host "Software source of truth: $Script:ToolListCsv" -ForegroundColor Green
    if ($Script:OutputFormat -eq "CSV+XLSX") { Write-Host "XLSX workbook:   $Script:BuildWorkbookXlsx" }
    Write-Host ""
    Write-Host "Edit these files before writing the USB build." -ForegroundColor Yellow
    Write-Host "- ToolList_SOURCE_OF_TRUTH.csv is the software source of truth. Set Include to No to exclude tools; no deletion is needed."
    Write-Host "- FolderStructure.csv, DownloadInstallQueue_INFRASTRUCTURE.csv, and the XLSX workbook are informational/planning aids."
    Write-Host "- The builder reads ToolList_SOURCE_OF_TRUTH.csv when deciding which software source records to write and which downloads are enabled."
    Write-Host ""
    Write-Host " 1. Open planning folder"
    Write-Host " 2. Continue using current lists"
    Write-Host " 3. Stop and resume later"
    Write-Host ""
    $choice = Read-MenuChoice -Prompt "Choice" -Min 1 -Max 3
    if ($choice -eq 1) { Start-Process explorer.exe $Script:PlanningDir; Pause-Menu }
    elseif ($choice -eq 3) { Save-Session; throw "Stopped for list editing." }
}

function Import-CurrentFolderRows {
    if (-not (Test-Path $Script:FolderListCsv)) { Export-EditableBuildLists }
    return @(Import-Csv -Path $Script:FolderListCsv | Where-Object { $_.Include -match '^(?i:y|yes|true|1)$' })
}

function Import-CurrentToolRows {
    if (-not (Test-Path $Script:ToolListCsv)) { Export-EditableBuildLists }
    return @(Import-Csv -Path $Script:ToolListCsv | Where-Object { $_.Include -match '^(?i:y|yes|true|1)$' })
}

function Set-DriveExclusions {
    Write-Header
    Write-Host "Drive exclusion list" -ForegroundColor Cyan
    Write-Host "Enter drive letters to exclude from selection, separated by commas." -ForegroundColor Gray
    Write-Host "C is excluded by default to protect the system drive." -ForegroundColor Yellow
    Write-Host "Example: C,D,Z"
    Write-Host ""
    $input = Read-Host "Excluded drive letters"
    if ([string]::IsNullOrWhiteSpace($input)) { $Script:ExcludedDrives = @("C") }
    else {
        $letters = $input -split "," | ForEach-Object { $_.Trim().TrimEnd(":").ToUpperInvariant() } | Where-Object { $_ -match '^[A-Z]$' }
        if ($letters -notcontains "C") { $letters = @("C") + $letters }
        $Script:ExcludedDrives = @($letters | Select-Object -Unique)
    }
    Save-Session
    Write-Host "Excluded drives: $($Script:ExcludedDrives -join ', ')" -ForegroundColor Green
}

function Get-AvailableDrives {
    $drives = @()
    try {
        $logical = Get-CimInstance Win32_LogicalDisk | Where-Object { $_.DriveType -in @(2,3) }
        foreach ($d in $logical) {
            $letter = ($d.DeviceID -replace ':','').ToUpperInvariant()
            if ($Script:ExcludedDrives -contains $letter) { continue }
            $sizeGB = if ($d.Size) { [math]::Round(($d.Size / 1GB), 1) } else { 0 }
            $freeGB = if ($d.FreeSpace) { [math]::Round(($d.FreeSpace / 1GB), 1) } else { 0 }
            $type = if ($d.DriveType -eq 2) { "Removable" } else { "Fixed" }
            $drives += [pscustomobject]@{ Letter=$letter; Root="$letter`:"; Type=$type; SizeGB=$sizeGB; FreeGB=$freeGB; Label=$d.VolumeName }
        }
    }
    catch {
        Get-PSDrive -PSProvider FileSystem | ForEach-Object {
            $letter = $_.Name.ToUpperInvariant()
            if ($Script:ExcludedDrives -notcontains $letter) {
                $drives += [pscustomobject]@{ Letter=$letter; Root="$letter`:"; Type="Unknown"; SizeGB=0; FreeGB=0; Label="" }
            }
        }
    }
    return @($drives | Sort-Object Letter)
}

function Select-DriveRoot {
    param([pscustomobject]$DriveRole)
    Write-Header
    Write-Host "Select target drive for: $($DriveRole.Role)" -ForegroundColor Cyan
    Write-Host "Suggested size: $($DriveRole.SuggestedSize)"
    Write-Host "Excluded: $($Script:ExcludedDrives -join ', ')"
    Write-Host ""
    $drives = @(Get-AvailableDrives)
    $idx = 1
    foreach ($d in $drives) {
        $size = if ($d.SizeGB -gt 0) { "$($d.SizeGB) GB total / $($d.FreeGB) GB free" } else { "size unknown" }
        Write-Host (" {0}. {1}\  [{2}] {3} {4}" -f $idx, $d.Root, $d.Type, $size, $d.Label)
        $idx++
    }
    Write-Host " $idx. Enter a manual path"
    Write-Host ""
    $choice = Read-MenuChoice -Prompt "Target" -Min 1 -Max $idx
    if ($choice -eq $idx) {
        $path = Read-Host "Manual root path, for example E:\ or E:\USAK"
        if ([string]::IsNullOrWhiteSpace($path)) { throw "Target path cannot be blank." }
        return [System.IO.Path]::GetFullPath($path)
    }
    $selected = $drives[$choice - 1]
    if ($selected.Type -eq "Fixed") {
        Write-Host "You selected a fixed disk, not a removable USB." -ForegroundColor Yellow
        $confirm = Read-Host "Type YES to continue writing folders/templates there"
        if ($confirm -ne "YES") { throw "Cancelled fixed-disk selection." }
    }
    return ($selected.Root + "\")
}

function Test-DriveRoleMatchesRow {
    param([string]$RowRole, [string]$CurrentRole)
    if ([string]::IsNullOrWhiteSpace($RowRole)) { return $true }
    if ($RowRole -eq "All") { return $true }
    if ($RowRole -eq $CurrentRole) { return $true }
    return $false
}

function Write-ToolkitTemplates {
    param([string]$Root, [pscustomobject]$DriveRole, [object[]]$ToolsWritten)
    New-Item -ItemType Directory -Force -Path (Join-Path $Root "_toolkit_admin\manifests") | Out-Null
    New-Item -ItemType Directory -Force -Path (Join-Path $Root "_toolkit_admin\logs") | Out-Null
    New-Item -ItemType Directory -Force -Path (Join-Path $Root "_toolkit_admin\planning") | Out-Null
    New-Item -ItemType Directory -Force -Path (Join-Path $Root "_toolkit_admin\source_verification") | Out-Null
    New-Item -ItemType Directory -Force -Path (Join-Path $Root "_toolkit_admin\download_install") | Out-Null
    New-Item -ItemType Directory -Force -Path (Join-Path $Root "docs\attribution") | Out-Null
    New-Item -ItemType Directory -Force -Path (Join-Path $Root "docs\checklists") | Out-Null

    $readme = @"
USB Swiss Army Knife Toolkit
Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
Interaction level: $Script:InteractionLevel
Purpose: $Script:Purpose
Package level: $Script:PackageLevel
Drive role: $($DriveRole.Role)
Suggested size: $($DriveRole.SuggestedSize)

Purpose:
This drive structure is a local organization aid for a field utility toolkit.
It does not include third-party tools. Populate the drive locally from official
publisher-controlled sources and keep license, attribution, source URL, version,
and source-published hash records where available.

Editable build lists:
The planning files in _toolkit_admin\planning show the folder structure and tool
source list used for this build. Tools with Include set to No in ToolList_SOURCE_OF_TRUTH.csv or deleted from the
source CSV are not represented in this build output.

Boundary:
This project does not redistribute third-party binaries, installers, ISOs,
archives, wordlists, VM images, vendor tools, or downloaded project content.
This builder does not format or erase drives and does not download or install tools in this release.
"@
    Set-Content -Path (Join-Path $Root "README_USB_TOOLKIT.txt") -Value $readme -Encoding UTF8

    if (Test-Path $Script:FolderListCsv) { Copy-Item $Script:FolderListCsv -Destination (Join-Path $Root "_toolkit_admin\planning\FolderStructure.csv") -Force }
    if (Test-Path $Script:ToolListCsv) { Copy-Item $Script:ToolListCsv -Destination (Join-Path $Root "_toolkit_admin\planning\ToolList_SOURCE_OF_TRUTH.csv") -Force }
    if (Test-Path $Script:BuildWorkbookXlsx) { Copy-Item $Script:BuildWorkbookXlsx -Destination (Join-Path $Root "_toolkit_admin\planning\UsbToolkitBuildPlan.xlsx") -Force }
    if (Test-Path $Script:DownloadQueueCsv) { Copy-Item $Script:DownloadQueueCsv -Destination (Join-Path $Root "_toolkit_admin\download_install\DownloadInstallQueue_INFRASTRUCTURE.csv") -Force }

    $ToolsWritten | Export-Csv -Path (Join-Path $Root "_toolkit_admin\manifests\tool_source_list.csv") -NoTypeInformation -Encoding UTF8
    "DateTime,Action,ItemOrPath,Operator,Notes" | Set-Content -Path (Join-Path $Root "_toolkit_admin\logs\change_log_template.csv") -Encoding UTF8
    "ItemName,Version,OfficialSourceURL,SourcePublishedHash,HashAlgorithm,HashSourceURL,DateChecked,LocalPath,Notes" | Set-Content -Path (Join-Path $Root "_toolkit_admin\source_verification\source_verification_template.csv") -Encoding UTF8
    "ProjectOrTool,Publisher,OfficialURL,License,Version,DateObtained,LocalPath,Notes" | Set-Content -Path (Join-Path $Root "docs\attribution\source_attribution_template.csv") -Encoding UTF8

    $plan = [ordered]@{
        generated = (Get-Date).ToString("o")
        app_version = $Script:AppVersion
        interaction_level = $Script:InteractionLevel
        purpose = $Script:Purpose
        package_level = $Script:PackageLevel
        drive_role = $DriveRole.Role
        suggested_size = $DriveRole.SuggestedSize
        editable_folder_list = "_toolkit_admin/planning/FolderStructure.csv"
        editable_tool_list = "_toolkit_admin/planning/ToolList_SOURCE_OF_TRUTH.csv"
        download_install_queue = "_toolkit_admin/download_install/DownloadInstallQueue_INFRASTRUCTURE.csv"
        boundary = "No third-party binaries, installers, ISOs, archives, wordlists, VM images, vendor tools, or downloaded content are redistributed by this project."
    } | ConvertTo-Json -Depth 6
    Set-Content -Path (Join-Path $Root "_toolkit_admin\build_plan.json") -Value $plan -Encoding UTF8

    $checklist = @"
USB Toolkit Build Checklist

[ ] Confirm this drive is the intended target.
[ ] Confirm purpose and package level match the toolkit you are building.
[ ] Review _toolkit_admin\planning\ToolList_SOURCE_OF_TRUTH.csv before adding tools.
[ ] Populate or download tools only from official publisher-controlled sources.
[ ] Record source URL, license, version, and date obtained.
[ ] Record source-published hashes where available.
[ ] Do not store evidence, CJI, secrets, passwords, or personal files on this toolkit drive.
[ ] Review agency policy and third-party licenses before field use.
"@
    Set-Content -Path (Join-Path $Root "docs\checklists\build_checklist.txt") -Value $checklist -Encoding UTF8
}

function Write-ToolSourceCards {
    param([string]$Root, [object[]]$Tools)
    foreach ($tool in $Tools) {
        if ([string]::IsNullOrWhiteSpace($tool.TargetFolder)) { continue }
        $toolDir = Join-Path $Root $tool.TargetFolder
        New-Item -ItemType Directory -Force -Path $toolDir | Out-Null
        $safeName = ($tool.ToolName -replace '[^A-Za-z0-9_.-]', '_')
        $cardPath = Join-Path $toolDir ("SOURCE_" + $safeName + ".txt")
        $content = @"
Tool/source record: $($tool.ToolName)
Purpose: $($tool.Purpose)
Category: $($tool.Category)
Package level: $($tool.PackageLevel)
Official source URL: $($tool.OfficialSourceURL)
Source notes: $($tool.SourceNotes)
License notes: $($tool.LicenseNotes)
Download status: $($tool.DownloadStatus)

Boundary:
USB Swiss Army Knife did not download or install this tool in this release. Use official publisher-controlled sources, verify publisher terms, and record source-published hashes where available.
"@
        Set-Content -Path $cardPath -Value $content -Encoding UTF8
    }
}


function Select-LocalInstallRoot {
    param([pscustomobject]$DriveRole)
    Write-Header
    Write-Host "Select local install location" -ForegroundColor Cyan
    Write-Host "This can be C: or another internal/storage drive." -ForegroundColor Gray
    Write-Host "The builder will create a UsbSwissArmyKnife folder under the selected location unless you enter a manual path."
    Write-Host ""
    $drives = @()
    try {
        $logical = Get-CimInstance Win32_LogicalDisk | Where-Object { $_.DriveType -in @(2,3) }
        foreach ($d in $logical) {
            $letter = ($d.DeviceID -replace ':','').ToUpperInvariant()
            $sizeGB = if ($d.Size) { [math]::Round(($d.Size / 1GB), 1) } else { 0 }
            $freeGB = if ($d.FreeSpace) { [math]::Round(($d.FreeSpace / 1GB), 1) } else { 0 }
            $type = if ($d.DriveType -eq 2) { "Removable" } else { "Fixed" }
            $drives += [pscustomobject]@{ Letter=$letter; Root="$letter`:"; Type=$type; SizeGB=$sizeGB; FreeGB=$freeGB; Label=$d.VolumeName }
        }
    }
    catch {
        Get-PSDrive -PSProvider FileSystem | ForEach-Object {
            $letter = $_.Name.ToUpperInvariant()
            $drives += [pscustomobject]@{ Letter=$letter; Root="$letter`:"; Type="Unknown"; SizeGB=0; FreeGB=0; Label="" }
        }
    }
    $drives = @($drives | Sort-Object Letter)
    $idx = 1
    foreach ($d in $drives) {
        $size = if ($d.SizeGB -gt 0) { "$($d.SizeGB) GB total / $($d.FreeGB) GB free" } else { "size unknown" }
        Write-Host (" {0}. {1}\UsbSwissArmyKnife  [{2}] {3} {4}" -f $idx, $d.Root, $d.Type, $size, $d.Label)
        $idx++
    }
    Write-Host " $idx. Enter a manual local path"
    Write-Host ""
    $choice = Read-MenuChoice -Prompt "Local install target" -Min 1 -Max $idx
    if ($choice -eq $idx) {
        $path = Read-Host "Manual local folder path, for example D:\Toolkits\UsbSwissArmyKnife"
        if ([string]::IsNullOrWhiteSpace($path)) { throw "Target path cannot be blank." }
        return [System.IO.Path]::GetFullPath($path)
    }
    $selected = $drives[$choice - 1]
    $root = Join-Path ($selected.Root + "\") "UsbSwissArmyKnife"
    if ($selected.Letter -eq "C") {
        Write-Host "You selected the system drive. This writes folders/templates only under $root." -ForegroundColor Yellow
        $confirm = Read-Host "Type YES to continue with a local C: install path"
        if ($confirm -ne "YES") { throw "Cancelled local C: install path." }
    }
    return $root
}

function Write-DriveBuild {
    param([pscustomobject]$DriveRole)
    if ($Script:BuildTarget -eq "Local Install") { $root = Select-LocalInstallRoot -DriveRole $DriveRole } else { $root = Select-DriveRoot -DriveRole $DriveRole }
    Write-Host ""
    Write-Host "Ready to write toolkit folders/templates/source records to: $root" -ForegroundColor Cyan
    Write-Host "Drive role: $($DriveRole.Role)"
    Write-Host "This will not format, erase, download, or install anything." -ForegroundColor Yellow
    $confirm = Read-Host "Type YES to continue"
    if ($confirm -ne "YES") { throw "Cancelled." }

    if (-not (Test-Path $root)) { New-Item -ItemType Directory -Force -Path $root | Out-Null }
    $folderRows = @(Import-CurrentFolderRows | Where-Object { Test-DriveRoleMatchesRow -RowRole $_.DriveRole -CurrentRole $DriveRole.Role })
    foreach ($row in $folderRows) {
        if (-not [string]::IsNullOrWhiteSpace($row.RelativePath)) { New-Item -ItemType Directory -Force -Path (Join-Path $root $row.RelativePath) | Out-Null }
    }
    $toolRows = @(Import-CurrentToolRows)
    Write-ToolSourceCards -Root $root -Tools $toolRows
    Write-ToolkitTemplates -Root $root -DriveRole $DriveRole -ToolsWritten $toolRows
    Write-Host ""
    Write-Host "Completed: $($DriveRole.Role) -> $root" -ForegroundColor Green
    Write-Host "Tool source records written: $($toolRows.Count)" -ForegroundColor Green
}

function Run-GuidedBuild {
    try {
        Select-InteractionLevel
        Select-Purpose
        Select-PackageLevel
        Select-BuildTarget
        Select-OutputFormat
        Build-PlanFromAnswers
        Show-BuildPlan
        Pause-Menu
        Confirm-EditableLists
        if ($Script:BuildTarget -ne "Local Install") { Set-DriveExclusions }

        $index = 0
        while ($index -lt $Script:BuildPlan.Count) {
            $driveRole = $Script:BuildPlan[$index]
            Write-Header
            Write-Host "Next target: $($driveRole.Role)" -ForegroundColor Cyan
            Write-Host "Suggested size: $($driveRole.SuggestedSize)"
            Write-Host "Notes: $($driveRole.Notes)"
            Write-Host ""
            Write-Host " 1. Build this drive now"
            Write-Host " 2. Open/edit planning folder again"
            Write-Host " 3. Skip this drive"
            Write-Host " 4. Stop and resume later"
            Write-Host ""
            $choice = Read-MenuChoice -Prompt "Next step" -Min 1 -Max 4
            if ($choice -eq 1) { Write-DriveBuild -DriveRole $driveRole; Pause-Menu }
            elseif ($choice -eq 2) { Start-Process explorer.exe $Script:PlanningDir; Pause-Menu; continue }
            elseif ($choice -eq 4) { Save-Session; return }

            $index++
            if ($index -lt $Script:BuildPlan.Count) {
                $continue = Read-Host "Continue to another target/drive? (Y/N)"
                if ($continue -notin @("Y","y","Yes","yes")) { Save-Session; return }
            }
        }
        Save-Session
        Write-Header
        Write-Host "Guided build path complete." -ForegroundColor Green
        Write-Host "You can still resume or start a new guided build later."
        Pause-Menu
    }
    catch {
        Write-Host ""
        Write-Host $_.Exception.Message -ForegroundColor Yellow
        Save-Session
        Pause-Menu
    }
}

function Resume-SessionWorkflow {
    if (-not (Load-Session)) { Write-Host "No saved session found." -ForegroundColor Yellow; Pause-Menu; return }
    if ($Script:BuildPlan.Count -eq 0) { Build-PlanFromAnswers }
    if (-not (Test-Path $Script:ToolListCsv)) { Export-EditableBuildLists }
    Show-BuildPlan
    Pause-Menu
    if ($Script:BuildTarget -ne "Local Install" -and $Script:ExcludedDrives.Count -eq 0) { Set-DriveExclusions }
    foreach ($driveRole in $Script:BuildPlan) {
        Write-Header
        Write-Host "Resume build path" -ForegroundColor Cyan
        Write-Host "Drive role: $($driveRole.Role)"
        Write-Host "Suggested size: $($driveRole.SuggestedSize)"
        Write-Host ""
        Write-Host " 1. Build this drive"
        Write-Host " 2. Open/edit planning folder"
        Write-Host " 3. Skip"
        Write-Host " 4. Stop"
        $choice = Read-MenuChoice -Prompt "Choice" -Min 1 -Max 4
        if ($choice -eq 1) { Write-DriveBuild -DriveRole $driveRole; Pause-Menu }
        elseif ($choice -eq 2) { Start-Process explorer.exe $Script:PlanningDir; Pause-Menu; continue }
        elseif ($choice -eq 4) { Save-Session; return }
    }
    Save-Session
}

function Show-AdvancedMenu {
    while ($true) {
        Write-Header
        Write-Host "Advanced / utility menu" -ForegroundColor Cyan
        Write-Host " 1. Show saved build path"
        Write-Host " 2. Open planning folder"
        Write-Host " 3. Regenerate editable build lists"
        Write-Host " 4. Set drive exclusions"
        Write-Host " 5. Download manager"
        Write-Host " 6. Start new guided build"
        Write-Host " 7. Clear saved session"
        Write-Host " 8. Back"
        Write-Host ""
        $choice = Read-MenuChoice -Prompt "Choice" -Min 1 -Max 8
        switch ($choice) {
            1 { if (-not (Load-Session)) { Write-Host "No saved session." -ForegroundColor Yellow } else { if ($Script:BuildPlan.Count -eq 0) { Build-PlanFromAnswers }; Show-BuildPlan }; Pause-Menu }
            2 { Ensure-SessionDir; Start-Process explorer.exe $Script:PlanningDir; Pause-Menu }
            3 { if (-not (Load-Session)) { Write-Host "No saved session. Start a guided build first." -ForegroundColor Yellow } else { Export-EditableBuildLists; Write-Host "Planning files regenerated in $Script:PlanningDir" -ForegroundColor Green }; Pause-Menu }
            4 { Set-DriveExclusions; Pause-Menu }
            5 { Show-DownloadInstallInfrastructure }
            6 { Run-GuidedBuild }
            7 { Clear-Session; Write-Host "Saved session cleared." -ForegroundColor Green; Pause-Menu }
            8 { return }
        }
    }
}

function Start-Menu {
    while ($true) {
        $hasSession = Test-Path $Script:SessionPath
        Write-Header
        if ($hasSession) {
            Write-Host "Saved guided build session found." -ForegroundColor Green
            Write-Host ""
            Write-Host " 1. Resume saved session"
            Write-Host " 2. Start new guided build"
            Write-Host " 3. Advanced / utility menu"
            Write-Host " 4. Exit"
            Write-Host ""
            $choice = Read-MenuChoice -Prompt "Choice" -Min 1 -Max 4
            switch ($choice) {
                1 { Resume-SessionWorkflow }
                2 { Clear-Session; Run-GuidedBuild }
                3 { Show-AdvancedMenu }
                4 { return }
            }
        }
        else {
            Write-Host "No saved session found. Starting from the beginning is recommended." -ForegroundColor Cyan
            Write-Host ""
            Write-Host " 1. Start guided build"
            Write-Host " 2. Advanced / utility menu"
            Write-Host " 3. Exit"
            Write-Host ""
            $choice = Read-MenuChoice -Prompt "Choice" -Min 1 -Max 3
            switch ($choice) {
                1 { Run-GuidedBuild }
                2 { Show-AdvancedMenu }
                3 { return }
            }
        }
    }
}



# ---------------------------------------------------------------------------
# v0.2.3 download hardening overrides
# These function definitions intentionally appear near the end of the script so
# they replace earlier v0.2.1 implementations without changing the broader menu.
# ---------------------------------------------------------------------------

function Test-HttpsUrl {
    param([string]$Url)
    try {
        if ([string]::IsNullOrWhiteSpace($Url)) { return $false }
        $uri = [System.Uri]$Url
        return ($uri.Scheme -eq "https")
    }
    catch { return $false }
}

function New-ToolRow {
    param(
        [string]$Purpose, [string]$RequiredLevel, [string]$Category, [string]$ToolName,
        [string]$TargetFolder, [string]$OfficialSourceURL, [string]$LicenseNotes,
        [string]$SourceNotes, [string]$Notes
    )
    $directUrl = Get-DefaultDirectDownloadUrl -ToolName $ToolName
    $enabled = Get-DefaultDownloadEnabled -ToolName $ToolName
    $hostName = Get-SourceHost -Url $OfficialSourceURL
    $directHostName = Get-SourceHost -Url $directUrl
    $readiness = "Manual source review"
    if ($enabled -eq "Yes" -and -not [string]::IsNullOrWhiteSpace($directUrl)) { $readiness = "Direct download enabled" }
    elseif (-not [string]::IsNullOrWhiteSpace($directUrl)) { $readiness = "Direct URL recorded but disabled" }

    [pscustomobject]@{
        Include = "Yes"
        Purpose = $Purpose
        PackageLevel = $RequiredLevel
        Category = $Category
        ToolName = $ToolName
        Version = ""
        TargetFolder = $TargetFolder
        OfficialSourceURL = $OfficialSourceURL
        OfficialSourceHost = $hostName
        SourceNotes = $SourceNotes
        LicenseNotes = $LicenseNotes
        SourceVettingStatus = (Get-SourceVettingStatus -ToolName $ToolName -OfficialSourceURL $OfficialSourceURL)
        SourceVettingNotes = (Get-SourceVettingNotes -ToolName $ToolName -OfficialSourceURL $OfficialSourceURL)
        SourceVettedOn = "2026-07-28"
        DownloadStatus = "Not downloaded"
        AcquisitionMode = "Official source page / optional direct download"
        DownloadReadyStatus = $readiness
        DownloadEnabled = $enabled
        InstallEnabled = "No"
        DirectDownloadURL = $directUrl
        DirectDownloadHost = $directHostName
        LocalFileName = (Get-DefaultLocalFileName -ToolName $ToolName -DirectDownloadURL $directUrl)
        DownloadPathMode = "UserProfileStagingThenCompleted"
        DownloadManifest = $Script:DownloadManifestCsv
        CopyDownloadedFileToBuild = "No"
        SourcePublishedHash = ""
        HashAlgorithm = "SHA256"
        HashSourceURL = ""
        InstallerType = "ManualOrPortable"
        SilentInstallArgs = ""
        InstallCommand = ""
        InstallScope = "Portable or user-selected"
        Notes = $Notes
    }
}

function Get-RequiredToolListHeaders {
    return @(
        "Include", "Purpose", "PackageLevel", "Category", "ToolName", "TargetFolder",
        "OfficialSourceURL", "DownloadEnabled", "DirectDownloadURL", "LocalFileName",
        "CopyDownloadedFileToBuild", "SourcePublishedHash", "HashAlgorithm", "HashSourceURL"
    )
}

function Test-ToolListSchema {
    Ensure-SessionDir
    if (-not (Test-Path $Script:ToolListCsv)) { Export-EditableBuildLists }
    $rows = @(Import-Csv -Path $Script:ToolListCsv)
    $issues = @()
    if ($rows.Count -eq 0) {
        $issues += "ToolList_SOURCE_OF_TRUTH.csv contains no rows."
    }
    else {
        $headers = @($rows[0].PSObject.Properties.Name)
        foreach ($h in (Get-RequiredToolListHeaders)) {
            if ($headers -notcontains $h) { $issues += "Missing column: $h" }
        }
        $ids = @{}
        foreach ($row in $rows) {
            if ([string]::IsNullOrWhiteSpace([string]$row.ToolName)) { $issues += "A row is missing ToolName." }
            if ((Normalize-YesNo $row.DownloadEnabled) -and [string]::IsNullOrWhiteSpace([string]$row.DirectDownloadURL)) {
                $issues += "DownloadEnabled=Yes but DirectDownloadURL is blank for: $($row.ToolName)"
            }
            if (-not [string]::IsNullOrWhiteSpace([string]$row.DirectDownloadURL) -and -not (Test-HttpsUrl -Url ([string]$row.DirectDownloadURL))) {
                $issues += "DirectDownloadURL is not HTTPS for: $($row.ToolName)"
            }
            if (-not [string]::IsNullOrWhiteSpace([string]$row.HashAlgorithm) -and ([string]$row.HashAlgorithm).ToUpperInvariant() -ne "SHA256") {
                $issues += "Only SHA256 is supported in this build for source hash comparisons: $($row.ToolName)"
            }
            $key = "{0}|{1}" -f $row.Purpose, $row.ToolName
            if ($ids.ContainsKey($key)) { $issues += "Duplicate Purpose+ToolName row: $key" } else { $ids[$key] = $true }
        }
    }
    return $issues
}

function Show-ToolListValidation {
    Write-Header
    Write-Host "Source-of-truth validation" -ForegroundColor Cyan
    Write-Host "File: $Script:ToolListCsv"
    Write-Host ""
    $issues = @(Test-ToolListSchema)
    if ($issues.Count -eq 0) {
        Write-Host "No blocking source-of-truth list issues found." -ForegroundColor Green
    }
    else {
        Write-Host "Issues found:" -ForegroundColor Yellow
        foreach ($issue in $issues) { Write-Host " - $issue" -ForegroundColor Yellow }
    }
    Pause-Menu
}

function Export-DownloadReadinessReport {
    Ensure-SessionDir
    if (-not (Test-Path $Script:ToolListCsv)) { Export-EditableBuildLists }
    $tools = @(Import-Csv -Path $Script:ToolListCsv)
    $reportPath = Join-Path $Script:PlanningDir "DownloadReadinessReport.csv"
    $report = @()
    foreach ($tool in $tools) {
        $eligible = ((Normalize-YesNo $tool.Include) -and (Normalize-YesNo $tool.DownloadEnabled) -and -not [string]::IsNullOrWhiteSpace([string]$tool.DirectDownloadURL) -and (Test-HttpsUrl -Url ([string]$tool.DirectDownloadURL)))
        $reason = "Manual review or source page only"
        if ($eligible) { $reason = "Ready for controlled download" }
        elseif (-not (Normalize-YesNo $tool.Include)) { $reason = "Include is not Yes" }
        elseif (-not (Normalize-YesNo $tool.DownloadEnabled)) { $reason = "DownloadEnabled is not Yes" }
        elseif ([string]::IsNullOrWhiteSpace([string]$tool.DirectDownloadURL)) { $reason = "No direct download URL" }
        elseif (-not (Test-HttpsUrl -Url ([string]$tool.DirectDownloadURL))) { $reason = "Direct download URL is not HTTPS" }
        $report += [pscustomobject]@{
            ReadyForDownload = if ($eligible) { "Yes" } else { "No" }
            Reason = $reason
            Include = $tool.Include
            Purpose = $tool.Purpose
            Category = $tool.Category
            ToolName = $tool.ToolName
            OfficialSourceURL = $tool.OfficialSourceURL
            OfficialSourceHost = $tool.OfficialSourceHost
            SourceVettingStatus = $tool.SourceVettingStatus
            DownloadEnabled = $tool.DownloadEnabled
            DirectDownloadURL = $tool.DirectDownloadURL
            DirectDownloadHost = $tool.DirectDownloadHost
            LocalFileName = $tool.LocalFileName
            CopyDownloadedFileToBuild = $tool.CopyDownloadedFileToBuild
            SourcePublishedHash = $tool.SourcePublishedHash
            HashAlgorithm = $tool.HashAlgorithm
            HashSourceURL = $tool.HashSourceURL
        }
    }
    $report | Export-Csv -Path $reportPath -NoTypeInformation -Encoding UTF8
    return $reportPath
}

function Show-DownloadPreview {
    Ensure-SessionDir
    if (-not (Test-Path $Script:ToolListCsv)) { Export-EditableBuildLists }
    $tools = @(Import-Csv -Path $Script:ToolListCsv | Where-Object {
        (Normalize-YesNo $_.Include) -and (Normalize-YesNo $_.DownloadEnabled) -and -not [string]::IsNullOrWhiteSpace([string]$_.DirectDownloadURL)
    })
    Write-Header
    Write-Host "Download preview" -ForegroundColor Cyan
    Write-Host "Eligible rows from: $Script:ToolListCsv"
    Write-Host ""
    if ($tools.Count -eq 0) {
        Write-Host "No rows are currently eligible for download." -ForegroundColor Yellow
    }
    else {
        $i = 1
        foreach ($tool in $tools) {
            $valid = if (Test-HttpsUrl -Url ([string]$tool.DirectDownloadURL)) { "HTTPS" } else { "Blocked: non-HTTPS" }
            Write-Host "$i. $($tool.ToolName) [$($tool.Purpose) / $($tool.Category)]" -ForegroundColor Green
            Write-Host "   URL: $($tool.DirectDownloadURL)"
            Write-Host "   File: $(Get-DownloadFileName -Tool $tool)"
            Write-Host "   Status: $valid"
            Write-Host ""
            $i++
        }
    }
    Pause-Menu
}

function New-DownloadManifestRow {
    param(
        [object]$Tool, [string]$Status, [string]$FilePath, [string]$Sha256, [string]$ErrorMessage,
        [long]$Bytes = 0, [string]$RunId = "", [string]$HashMatch = "Not checked"
    )
    [pscustomobject]@{
        Timestamp = (Get-Date).ToString("o")
        DownloadRunId = $RunId
        Status = $Status
        ToolName = [string]$Tool.ToolName
        Purpose = [string]$Tool.Purpose
        Category = [string]$Tool.Category
        OfficialSourceURL = [string]$Tool.OfficialSourceURL
        OfficialSourceHost = (Get-SourceHost -Url ([string]$Tool.OfficialSourceURL))
        DirectDownloadURL = [string]$Tool.DirectDownloadURL
        DirectDownloadHost = (Get-SourceHost -Url ([string]$Tool.DirectDownloadURL))
        LocalFileName = (Get-DownloadFileName -Tool $Tool)
        DownloadedFilePath = $FilePath
        SHA256 = $Sha256
        Bytes = $Bytes
        SourcePublishedHash = [string]$Tool.SourcePublishedHash
        HashAlgorithm = if ($Tool.HashAlgorithm) { [string]$Tool.HashAlgorithm } else { "SHA256" }
        HashSourceURL = [string]$Tool.HashSourceURL
        HashMatch = $HashMatch
        SourceVettingStatus = [string]$Tool.SourceVettingStatus
        SourceVettingNotes = [string]$Tool.SourceVettingNotes
        HashVerificationReminder = "Compare this SHA-256 against a publisher/source-published hash when available. If no publisher hash is available, this hash only records what was downloaded locally."
        Error = $ErrorMessage
    }
}

function Compare-SourcePublishedHash {
    param([object]$Tool, [string]$Sha256)
    if ([string]::IsNullOrWhiteSpace([string]$Tool.SourcePublishedHash)) { return "No source hash provided" }
    $alg = if ($Tool.HashAlgorithm) { ([string]$Tool.HashAlgorithm).ToUpperInvariant() } else { "SHA256" }
    if ($alg -ne "SHA256") { return "Unsupported hash algorithm" }
    $expected = ([string]$Tool.SourcePublishedHash).Trim().ToUpperInvariant()
    $actual = ([string]$Sha256).Trim().ToUpperInvariant()
    if ($expected -eq $actual) { return "Match" }
    return "Mismatch"
}

function Get-CompletedDownloadPathForTool {
    param([object]$Tool)
    $toolNameSafe = Get-SafePathPart -Value ([string]$Tool.ToolName)
    $purposeSafe = Get-SafePathPart -Value ([string]$Tool.Purpose)
    $destDir = Join-Path (Join-Path $Script:DownloadCompletedDir $purposeSafe) $toolNameSafe
    return (Join-Path $destDir (Get-DownloadFileName -Tool $Tool))
}

function Get-LatestSuccessfulDownloadForTool {
    param([object]$Tool)
    if (-not (Test-Path $Script:DownloadManifestCsv)) { return $null }
    $rows = @(Import-Csv -Path $Script:DownloadManifestCsv | Where-Object {
        $_.Status -in @("Success", "ExistingFileHashed") -and $_.ToolName -eq $Tool.ToolName -and $_.Purpose -eq $Tool.Purpose -and (Test-Path ([string]$_.DownloadedFilePath))
    } | Sort-Object Timestamp -Descending)
    if ($rows.Count -gt 0) { return $rows[0] }
    return $null
}

function Invoke-EnabledDownloads {
    Ensure-SessionDir
    if (-not (Test-Path $Script:ToolListCsv)) { Export-EditableBuildLists }
    $issues = @(Test-ToolListSchema)
    if ($issues.Count -gt 0) {
        Write-Header
        Write-Host "Fix source-of-truth issues before downloading." -ForegroundColor Yellow
        foreach ($issue in $issues) { Write-Host " - $issue" -ForegroundColor Yellow }
        Pause-Menu
        return
    }
    $tools = @(Import-Csv -Path $Script:ToolListCsv | Where-Object {
        (Normalize-YesNo $_.Include) -and (Normalize-YesNo $_.DownloadEnabled) -and -not [string]::IsNullOrWhiteSpace([string]$_.DirectDownloadURL)
    })
    Write-Header
    Write-Host "Download enabled source-of-truth items" -ForegroundColor Cyan
    Write-Host "Source of truth: $Script:ToolListCsv"
    Write-Host "Download root:    $Script:DownloadRoot"
    Write-Host "Manifest:         $Script:DownloadManifestCsv"
    Write-Host "Items to attempt: $($tools.Count)"
    Write-Host ""
    Write-Host "Files are downloaded to a user-profile staging folder, hashed, then moved to completed downloads." -ForegroundColor Gray
    Write-Host "The tool does not install software or claim the publisher hash was verified unless SourcePublishedHash is provided and matches." -ForegroundColor Yellow
    Write-Host ""
    if ($tools.Count -eq 0) {
        Write-Host "No rows are enabled for download. Set Include=Yes, DownloadEnabled=Yes, and DirectDownloadURL in ToolList_SOURCE_OF_TRUTH.csv." -ForegroundColor Yellow
        Pause-Menu
        return
    }
    Write-Host "Existing completed file behavior:" -ForegroundColor Cyan
    Write-Host " 1. Skip download and hash existing files"
    Write-Host " 2. Overwrite existing files"
    Write-Host " 3. Prompt for each existing file"
    $existingChoice = Read-MenuChoice -Prompt "Existing file option" -Min 1 -Max 3
    $confirm = Read-Host "Type DOWNLOAD to start"
    if ($confirm -ne "DOWNLOAD") { Write-Host "Download cancelled." -ForegroundColor Yellow; Pause-Menu; return }

    $runId = [guid]::NewGuid().ToString("N")
    $manifestRows = @()
    foreach ($tool in $tools) {
        $fileName = Get-DownloadFileName -Tool $tool
        $completedPath = Get-CompletedDownloadPathForTool -Tool $tool
        $destDir = Split-Path -Parent $completedPath
        New-Item -ItemType Directory -Force -Path $destDir | Out-Null
        Write-Host "Downloading: $($tool.ToolName)" -ForegroundColor Cyan
        Write-Host "  From: $($tool.DirectDownloadURL)" -ForegroundColor DarkGray

        if (-not (Test-HttpsUrl -Url ([string]$tool.DirectDownloadURL)) ) {
            $manifestRows += New-DownloadManifestRow -Tool $tool -Status "BlockedNonHttps" -FilePath "" -Sha256 "" -ErrorMessage "Only HTTPS direct downloads are allowed." -Bytes 0 -RunId $runId
            Write-Host "  Blocked: only HTTPS direct downloads are allowed." -ForegroundColor Yellow
            continue
        }

        if (Test-Path $completedPath) {
            $useExisting = $false
            if ($existingChoice -eq 1) { $useExisting = $true }
            elseif ($existingChoice -eq 3) {
                $ans = Read-Host "Existing file found. Use existing instead of re-downloading? (Y/N)"
                if ($ans -in @("Y", "y", "Yes", "yes")) { $useExisting = $true }
            }
            if ($useExisting) {
                $hash = Get-FileHash -Algorithm SHA256 -Path $completedPath
                $bytes = (Get-Item $completedPath).Length
                $hashMatch = Compare-SourcePublishedHash -Tool $tool -Sha256 $hash.Hash
                $manifestRows += New-DownloadManifestRow -Tool $tool -Status "ExistingFileHashed" -FilePath $completedPath -Sha256 $hash.Hash -ErrorMessage "" -Bytes $bytes -RunId $runId -HashMatch $hashMatch
                Write-Host "  Existing file hashed. SHA-256: $($hash.Hash)" -ForegroundColor Green
                continue
            }
        }

        $stagingName = "{0}-{1}" -f ([guid]::NewGuid().ToString("N")), $fileName
        $stagingPath = Join-Path $Script:DownloadStagingDir $stagingName
        try {
            Invoke-WebRequest -Uri ([string]$tool.DirectDownloadURL) -OutFile $stagingPath -UseBasicParsing -MaximumRedirection 5
            $hash = Get-FileHash -Algorithm SHA256 -Path $stagingPath
            $bytes = (Get-Item $stagingPath).Length
            if (Test-Path $completedPath) { Remove-Item -Force $completedPath }
            Move-Item -Force -Path $stagingPath -Destination $completedPath
            $hashMatch = Compare-SourcePublishedHash -Tool $tool -Sha256 $hash.Hash
            $manifestRows += New-DownloadManifestRow -Tool $tool -Status "Success" -FilePath $completedPath -Sha256 $hash.Hash -ErrorMessage "" -Bytes $bytes -RunId $runId -HashMatch $hashMatch
            Write-Host "  Success. SHA-256: $($hash.Hash)" -ForegroundColor Green
            if ($hashMatch -eq "Mismatch") { Write-Host "  WARNING: Source-published hash mismatch." -ForegroundColor Yellow }
        }
        catch {
            $err = $_.Exception.Message
            if (Test-Path $stagingPath) { Remove-Item -Force $stagingPath -ErrorAction SilentlyContinue }
            $manifestRows += New-DownloadManifestRow -Tool $tool -Status "Failed" -FilePath "" -Sha256 "" -ErrorMessage $err -Bytes 0 -RunId $runId
            Write-Host "  Failed: $err" -ForegroundColor Yellow
        }
    }
    Export-DownloadManifest -Rows $manifestRows
    Write-Host ""
    Write-Host "Download manifest updated: $Script:DownloadManifestCsv" -ForegroundColor Green
    Pause-Menu
}

function Hash-CompletedDownloads {
    Ensure-SessionDir
    $files = @()
    if (Test-Path $Script:DownloadCompletedDir) { $files = @(Get-ChildItem -Path $Script:DownloadCompletedDir -File -Recurse) }
    Write-Header
    Write-Host "Hash completed downloads" -ForegroundColor Cyan
    Write-Host "Completed folder: $Script:DownloadCompletedDir"
    Write-Host "Files found: $($files.Count)"
    Write-Host ""
    if ($files.Count -eq 0) { Write-Host "No completed downloads found." -ForegroundColor Yellow; Pause-Menu; return }
    $outPath = Join-Path $Script:DownloadRoot "CompletedDownloads_SHA256SUMS.txt"
    $lines = @()
    foreach ($file in $files) {
        $hash = Get-FileHash -Algorithm SHA256 -Path $file.FullName
        $relative = $file.FullName.Substring($Script:DownloadCompletedDir.Length).TrimStart('\')
        $lines += "$($hash.Hash)  $relative"
    }
    $lines | Set-Content -Path $outPath -Encoding ASCII
    Write-Host "Wrote: $outPath" -ForegroundColor Green
    Pause-Menu
}

function Write-ToolSourceCards {
    param([string]$Root, [object[]]$Tools)
    foreach ($tool in $Tools) {
        if ([string]::IsNullOrWhiteSpace($tool.TargetFolder)) { continue }
        $toolDir = Join-Path $Root $tool.TargetFolder
        New-Item -ItemType Directory -Force -Path $toolDir | Out-Null
        $safeName = ($tool.ToolName -replace '[^A-Za-z0-9_.-]', '_')
        $cardPath = Join-Path $toolDir ("SOURCE_" + $safeName + ".txt")
        $content = @"
Tool/source record: $($tool.ToolName)
Purpose: $($tool.Purpose)
Category: $($tool.Category)
Package level: $($tool.PackageLevel)
Official source URL: $($tool.OfficialSourceURL)
Direct download URL: $($tool.DirectDownloadURL)
Source notes: $($tool.SourceNotes)
License notes: $($tool.LicenseNotes)
Download status: $($tool.DownloadStatus)

Boundary:
USB Swiss Army Knife records source information and may optionally download explicitly enabled direct-download rows. It does not install tools, run installers, format drives, erase drives, or redistribute third-party tools in the project repository.
"@
        Set-Content -Path $cardPath -Value $content -Encoding UTF8

        if (Normalize-YesNo $tool.CopyDownloadedFileToBuild) {
            $latest = Get-LatestSuccessfulDownloadForTool -Tool $tool
            if ($null -ne $latest) {
                $downloadCopyDir = Join-Path $toolDir "downloaded_source_files"
                New-Item -ItemType Directory -Force -Path $downloadCopyDir | Out-Null
                Copy-Item -Force -Path ([string]$latest.DownloadedFilePath) -Destination (Join-Path $downloadCopyDir ([System.IO.Path]::GetFileName([string]$latest.DownloadedFilePath)))
                $note = "Copied downloaded source file from completed downloads. No installer was executed. SHA256: $($latest.SHA256)"
                Set-Content -Path (Join-Path $downloadCopyDir "README_DOWNLOADED_FILE.txt") -Value $note -Encoding UTF8
            }
        }
    }
}

function Show-DownloadInstallInfrastructure {
    Ensure-SessionDir
    if (-not (Test-Path $Script:DownloadQueueCsv)) { Export-EditableBuildLists }
    while ($true) {
        Write-Header
        Write-Host "Download manager" -ForegroundColor Cyan
        Write-Host "Source of truth: $Script:ToolListCsv"
        Write-Host "Queue/info file:  $Script:DownloadQueueCsv"
        Write-Host "Manifest:         $Script:DownloadManifestCsv"
        Write-Host "Download root:    $Script:DownloadRoot"
        Write-Host ""
        Write-Host "Downloads only run for rows with Include=Yes, DownloadEnabled=Yes, and DirectDownloadURL populated." -ForegroundColor Yellow
        Write-Host "Downloaded files are staged under your profile, hashed with SHA-256, then moved to completed downloads. Installs remain disabled."
        Write-Host ""
        Write-Host " 1. Open planning folder"
        Write-Host " 2. Open ToolList_SOURCE_OF_TRUTH.csv"
        Write-Host " 3. Validate source-of-truth list"
        Write-Host " 4. Download preview"
        Write-Host " 5. Regenerate queue from current source-of-truth list"
        Write-Host " 6. Export download readiness report"
        Write-Host " 7. Run enabled downloads"
        Write-Host " 8. Hash completed downloads"
        Write-Host " 9. Open downloads folder"
        Write-Host "10. Open download manifest"
        Write-Host "11. Back"
        Write-Host ""
        $choice = Read-MenuChoice -Prompt "Choice" -Min 1 -Max 11
        if ($choice -eq 1) { Start-Process explorer.exe $Script:PlanningDir; Pause-Menu }
        elseif ($choice -eq 2) { if (-not (Test-Path $Script:ToolListCsv)) { Export-EditableBuildLists }; Invoke-Item $Script:ToolListCsv; Pause-Menu }
        elseif ($choice -eq 3) { Show-ToolListValidation }
        elseif ($choice -eq 4) { Show-DownloadPreview }
        elseif ($choice -eq 5) {
            $tools = @(Import-CurrentToolRows)
            Export-DownloadInstallQueue -ToolRows $tools
            Write-Host "Queue regenerated: $Script:DownloadQueueCsv" -ForegroundColor Green
            Pause-Menu
        }
        elseif ($choice -eq 6) {
            $path = Export-DownloadReadinessReport
            Write-Host "Readiness report exported: $path" -ForegroundColor Green
            Pause-Menu
        }
        elseif ($choice -eq 7) { Invoke-EnabledDownloads }
        elseif ($choice -eq 8) { Hash-CompletedDownloads }
        elseif ($choice -eq 9) { Start-Process explorer.exe $Script:DownloadRoot; Pause-Menu }
        elseif ($choice -eq 10) {
            if (Test-Path $Script:DownloadManifestCsv) { Invoke-Item $Script:DownloadManifestCsv }
            else { Write-Host "No download manifest exists yet." -ForegroundColor Yellow }
            Pause-Menu
        }
        elseif ($choice -eq 11) { return }
    }
}


# ---------------------------------------------------------------------------
# v0.2.3 transparency and editable source-of-truth overrides
# ---------------------------------------------------------------------------

function Get-ToolListEditingGuidePath { return (Join-Path $Script:PlanningDir "TOOLLIST_SOURCE_OF_TRUTH_EDITING_GUIDE.txt") }
function Get-CustomToolTemplatePath { return (Join-Path $Script:PlanningDir "CustomToolRow_TEMPLATE.csv") }
function Get-DownloadTransparencyPlanPath { return (Join-Path $Script:PlanningDir "DownloadTransparencyPlan.csv") }

function Get-RecommendedToolListHeaders {
    return @(
        "Include", "Purpose", "PackageLevel", "Category", "ToolName", "Version", "TargetFolder",
        "OfficialSourceURL", "OfficialSourceHost", "SourceNotes", "LicenseNotes",
        "SourceVettingStatus", "SourceVettingNotes", "SourceVettedOn",
        "DownloadStatus", "AcquisitionMode", "DownloadReadyStatus", "DownloadEnabled", "InstallEnabled",
        "DirectDownloadURL", "DirectDownloadHost", "LocalFileName", "DownloadPathMode", "DownloadManifest",
        "CopyDownloadedFileToBuild", "SourcePublishedHash", "HashAlgorithm", "HashSourceURL",
        "InstallerType", "SilentInstallArgs", "InstallCommand", "InstallScope",
        "UserEditableFields", "TransparencyNote", "EditWarning", "Notes"
    )
}

function Get-RequiredToolListHeaders {
    return @(
        "Include", "Purpose", "PackageLevel", "Category", "ToolName", "TargetFolder",
        "OfficialSourceURL", "DownloadEnabled", "DirectDownloadURL", "LocalFileName",
        "CopyDownloadedFileToBuild", "SourcePublishedHash", "HashAlgorithm", "HashSourceURL"
    )
}

function Get-SourceHost {
    param([string]$Url)
    if ([string]::IsNullOrWhiteSpace($Url)) { return "" }
    try { return ([System.Uri]$Url).Host.ToLowerInvariant() } catch { return "Unparseable URL" }
}

function New-ToolRow {
    param(
        [string]$Purpose, [string]$RequiredLevel, [string]$Category, [string]$ToolName,
        [string]$TargetFolder, [string]$OfficialSourceURL, [string]$LicenseNotes,
        [string]$SourceNotes, [string]$Notes
    )
    $directUrl = Get-DefaultDirectDownloadUrl -ToolName $ToolName
    $enabled = Get-DefaultDownloadEnabled -ToolName $ToolName
    $hostName = Get-SourceHost -Url $OfficialSourceURL
    $directHostName = Get-SourceHost -Url $directUrl
    $readiness = "Manual source review"
    if ($enabled -eq "Yes" -and -not [string]::IsNullOrWhiteSpace($directUrl)) { $readiness = "Direct download enabled" }
    elseif (-not [string]::IsNullOrWhiteSpace($directUrl)) { $readiness = "Direct URL recorded but disabled" }

    [pscustomobject]@{
        Include = "Yes"
        Purpose = $Purpose
        PackageLevel = $RequiredLevel
        Category = $Category
        ToolName = $ToolName
        Version = ""
        TargetFolder = $TargetFolder
        OfficialSourceURL = $OfficialSourceURL
        OfficialSourceHost = $hostName
        SourceNotes = $SourceNotes
        LicenseNotes = $LicenseNotes
        SourceVettingStatus = (Get-SourceVettingStatus -ToolName $ToolName -OfficialSourceURL $OfficialSourceURL)
        SourceVettingNotes = (Get-SourceVettingNotes -ToolName $ToolName -OfficialSourceURL $OfficialSourceURL)
        SourceVettedOn = "2026-07-28"
        DownloadStatus = "Not downloaded"
        AcquisitionMode = "Official source page / optional direct download"
        DownloadReadyStatus = $readiness
        DownloadEnabled = $enabled
        InstallEnabled = "No"
        DirectDownloadURL = $directUrl
        DirectDownloadHost = $directHostName
        LocalFileName = (Get-DefaultLocalFileName -ToolName $ToolName -DirectDownloadURL $directUrl)
        DownloadPathMode = "UserProfileStagingThenCompleted"
        DownloadManifest = $Script:DownloadManifestCsv
        CopyDownloadedFileToBuild = "No"
        SourcePublishedHash = ""
        HashAlgorithm = "SHA256"
        HashSourceURL = ""
        InstallerType = "ManualOrPortable"
        SilentInstallArgs = ""
        InstallCommand = ""
        InstallScope = "Portable or user-selected"
        UserEditableFields = "Include; TargetFolder; OfficialSourceURL; DirectDownloadURL; LocalFileName; DownloadEnabled; SourcePublishedHash; HashSourceURL; Notes"
        TransparencyNote = "OfficialSourceURL is the human review page. DirectDownloadURL is the exact address used by the download manager when DownloadEnabled=Yes."
        EditWarning = "Only enable direct downloads from sources you trust. Review license terms and compare local SHA-256 to source-published hashes when available."
        Notes = $Notes
    }
}

function Write-ToolListEditingGuide {
    Ensure-SessionDir
    $path = Get-ToolListEditingGuidePath
    $content = @"
USB Swiss Army Knife - ToolList_SOURCE_OF_TRUTH.csv Editing Guide

This CSV is the source of truth for software source records and downloads.
The builder reads this file directly when deciding which tools are included.

Most important columns:
- Include: Yes includes the row. No excludes it. Do not delete rows unless you want to.
- Purpose: IT Support, DFIR, OSINT, Everything, or your own label.
- PackageLevel: Minimal, Solid, Overkill, or your own label.
- Category: Grouping shown in source records.
- ToolName: Display name for the tool/source record.
- TargetFolder: Relative destination folder under the selected USB/local toolkit root.
- OfficialSourceURL: Human review page where the user can inspect the publisher/source.
- DirectDownloadURL: Exact URL the Download Manager will fetch when enabled.
- DownloadEnabled: Yes allows controlled download. No keeps the row informational only.
- LocalFileName: File name to use in the completed downloads folder.
- CopyDownloadedFileToBuild: Yes copies the downloaded file into downloaded_source_files under the target folder. No leaves it in completed downloads.
- SourcePublishedHash: Optional publisher/source SHA-256 hash.
- HashAlgorithm: SHA256 is the only comparison algorithm supported in this build.
- HashSourceURL: Page where the publisher/source hash was found.

Adding your own tools:
1. Copy a similar row or use CustomToolRow_TEMPLATE.csv.
2. Fill ToolName, Category, TargetFolder, OfficialSourceURL, and Notes.
3. Leave DownloadEnabled=No until you have reviewed the direct download URL and license/source terms.
4. Set DownloadEnabled=Yes only when DirectDownloadURL is the exact URL you want fetched.
5. Run Advanced / utility menu > Download manager > Validate source-of-truth list.
6. Run Download preview before downloading.

Transparency rule:
The user should be able to see both the official source page and the exact direct download URL before anything is downloaded.

Boundary:
This project creates structures, editable lists, source records, and controlled downloads only. It does not install tools, run installers, format drives, erase drives, or redistribute third-party software in the project repository.
"@
    Set-Content -Path $path -Value $content -Encoding UTF8
    return $path
}

function Export-CustomToolRowTemplate {
    Ensure-SessionDir
    $path = Get-CustomToolTemplatePath
    $row = [pscustomobject]@{
        Include = "Yes"
        Purpose = "Custom"
        PackageLevel = "Custom"
        Category = "Custom Tools"
        ToolName = "Example Tool Name"
        Version = ""
        TargetFolder = "tools/custom/example-tool"
        OfficialSourceURL = "https://example.com/tool"
        OfficialSourceHost = "example.com"
        SourceNotes = "Official human review page. Replace before use."
        LicenseNotes = "Review license before download/use."
        SourceVettingStatus = "User supplied"
        SourceVettingNotes = "Added by user in ToolList_SOURCE_OF_TRUTH.csv."
        SourceVettedOn = ""
        DownloadStatus = "Not downloaded"
        AcquisitionMode = "User supplied official source"
        DownloadReadyStatus = "User review required"
        DownloadEnabled = "No"
        InstallEnabled = "No"
        DirectDownloadURL = ""
        DirectDownloadHost = ""
        LocalFileName = "example-tool.zip"
        DownloadPathMode = "UserProfileStagingThenCompleted"
        DownloadManifest = $Script:DownloadManifestCsv
        CopyDownloadedFileToBuild = "No"
        SourcePublishedHash = ""
        HashAlgorithm = "SHA256"
        HashSourceURL = ""
        InstallerType = "ManualOrPortable"
        SilentInstallArgs = ""
        InstallCommand = ""
        InstallScope = "Portable or user-selected"
        UserEditableFields = "Include; TargetFolder; OfficialSourceURL; DirectDownloadURL; LocalFileName; DownloadEnabled; SourcePublishedHash; HashSourceURL; Notes"
        TransparencyNote = "OfficialSourceURL is the review page. DirectDownloadURL is the exact file address used only when DownloadEnabled=Yes."
        EditWarning = "Do not enable downloads until the source, license, and exact URL have been reviewed."
        Notes = "Replace this example row with your own tool details."
    }
    @($row) | Export-Csv -Path $path -NoTypeInformation -Encoding UTF8
    return $path
}

function Export-DownloadTransparencyPlan {
    Ensure-SessionDir
    if (-not (Test-Path $Script:ToolListCsv)) { Export-EditableBuildLists }
    $tools = @(Import-Csv -Path $Script:ToolListCsv)
    $outPath = Get-DownloadTransparencyPlanPath
    $rows = @()
    foreach ($tool in $tools) {
        $eligible = ((Normalize-YesNo $tool.Include) -and (Normalize-YesNo $tool.DownloadEnabled) -and -not [string]::IsNullOrWhiteSpace([string]$tool.DirectDownloadURL) -and (Test-HttpsUrl -Url ([string]$tool.DirectDownloadURL)))
        $completedPath = ""
        if ($eligible) { $completedPath = Get-CompletedDownloadPathForTool -Tool $tool }
        $rows += [pscustomobject]@{
            Include = $tool.Include
            DownloadEnabled = $tool.DownloadEnabled
            ReadyForDownload = if ($eligible) { "Yes" } else { "No" }
            ToolName = $tool.ToolName
            Purpose = $tool.Purpose
            PackageLevel = $tool.PackageLevel
            Category = $tool.Category
            TargetFolder = $tool.TargetFolder
            OfficialReviewPage = $tool.OfficialSourceURL
            OfficialReviewHost = (Get-SourceHost -Url ([string]$tool.OfficialSourceURL))
            ExactDirectDownloadURL = $tool.DirectDownloadURL
            ExactDirectDownloadHost = (Get-SourceHost -Url ([string]$tool.DirectDownloadURL))
            LocalFileName = (Get-DownloadFileName -Tool $tool)
            CompletedDownloadPath = $completedPath
            CopyDownloadedFileToBuild = $tool.CopyDownloadedFileToBuild
            SourcePublishedHash = $tool.SourcePublishedHash
            HashAlgorithm = $tool.HashAlgorithm
            HashSourceURL = $tool.HashSourceURL
            TransparencyNote = "Review OfficialReviewPage and ExactDirectDownloadURL before enabling downloads."
            UserEditable = "Edit ToolList_SOURCE_OF_TRUTH.csv, not this informational report."
        }
    }
    $rows | Export-Csv -Path $outPath -NoTypeInformation -Encoding UTF8
    return $outPath
}

function Export-EditableBuildLists {
    Ensure-SessionDir
    $folders = @(Get-FilteredFolderRows -Purpose $Script:Purpose -Level $Script:PackageLevel)
    $tools = @(Get-FilteredToolRows -Purpose $Script:Purpose -Level $Script:PackageLevel)
    $folders | Export-Csv -Path $Script:FolderListCsv -NoTypeInformation -Encoding UTF8
    $tools | Export-Csv -Path $Script:ToolListCsv -NoTypeInformation -Encoding UTF8
    Export-DownloadInstallQueue -ToolRows $tools
    Write-ToolListEditingGuide | Out-Null
    Export-CustomToolRowTemplate | Out-Null
    Export-DownloadTransparencyPlan | Out-Null
    if ($Script:OutputFormat -eq "CSV+XLSX") { Export-BuildWorkbookXlsx -FolderRows $folders -ToolRows $tools }
}

function Test-ToolListSchema {
    Ensure-SessionDir
    if (-not (Test-Path $Script:ToolListCsv)) { Export-EditableBuildLists }
    $rows = @(Import-Csv -Path $Script:ToolListCsv)
    $issues = @()
    if ($rows.Count -eq 0) {
        $issues += "ToolList_SOURCE_OF_TRUTH.csv contains no rows."
    }
    else {
        $headers = @($rows[0].PSObject.Properties.Name)
        foreach ($h in (Get-RequiredToolListHeaders)) {
            if ($headers -notcontains $h) { $issues += "Missing required column: $h" }
        }
        $ids = @{}
        foreach ($row in $rows) {
            if ([string]::IsNullOrWhiteSpace([string]$row.ToolName)) { $issues += "A row is missing ToolName." }
            if ([string]::IsNullOrWhiteSpace([string]$row.TargetFolder)) { $issues += "TargetFolder is blank for: $($row.ToolName)" }
            if ([string]::IsNullOrWhiteSpace([string]$row.OfficialSourceURL)) { $issues += "OfficialSourceURL is blank for: $($row.ToolName)" }
            if (-not [string]::IsNullOrWhiteSpace([string]$row.OfficialSourceURL) -and -not (Test-HttpsUrl -Url ([string]$row.OfficialSourceURL))) {
                $issues += "OfficialSourceURL is not HTTPS for: $($row.ToolName)"
            }
            if ((Normalize-YesNo $row.DownloadEnabled) -and [string]::IsNullOrWhiteSpace([string]$row.DirectDownloadURL)) {
                $issues += "DownloadEnabled=Yes but DirectDownloadURL is blank for: $($row.ToolName)"
            }
            if (-not [string]::IsNullOrWhiteSpace([string]$row.DirectDownloadURL) -and -not (Test-HttpsUrl -Url ([string]$row.DirectDownloadURL))) {
                $issues += "DirectDownloadURL is not HTTPS for: $($row.ToolName)"
            }
            if ((Normalize-YesNo $row.DownloadEnabled) -and [string]::IsNullOrWhiteSpace([string]$row.LocalFileName)) {
                $issues += "DownloadEnabled=Yes but LocalFileName is blank for: $($row.ToolName)"
            }
            if (-not [string]::IsNullOrWhiteSpace([string]$row.HashAlgorithm) -and ([string]$row.HashAlgorithm).ToUpperInvariant() -ne "SHA256") {
                $issues += "Only SHA256 is supported in this build for source hash comparisons: $($row.ToolName)"
            }
            $key = "{0}|{1}|{2}" -f $row.Purpose, $row.Category, $row.ToolName
            if ($ids.ContainsKey($key)) { $issues += "Duplicate Purpose+Category+ToolName row: $key" } else { $ids[$key] = $true }
        }
    }
    return $issues
}

function Show-ToolListValidation {
    Write-Header
    Write-Host "Source-of-truth validation" -ForegroundColor Cyan
    Write-Host "File: $Script:ToolListCsv"
    Write-Host "Custom tool rows are allowed when the required columns are present."
    Write-Host "The builder uses Include=Yes and TargetFolder from this file when writing tool source records."
    Write-Host "Downloads use DirectDownloadURL only when DownloadEnabled=Yes." -ForegroundColor Yellow
    Write-Host ""
    $issues = @(Test-ToolListSchema)
    if ($issues.Count -eq 0) {
        Write-Host "No blocking source-of-truth list issues found." -ForegroundColor Green
    }
    else {
        Write-Host "Issues found:" -ForegroundColor Yellow
        foreach ($issue in $issues) { Write-Host " - $issue" -ForegroundColor Yellow }
    }
    Pause-Menu
}

function Show-DownloadPreview {
    Ensure-SessionDir
    if (-not (Test-Path $Script:ToolListCsv)) { Export-EditableBuildLists }
    $tools = @(Import-Csv -Path $Script:ToolListCsv | Where-Object {
        (Normalize-YesNo $_.Include) -and (Normalize-YesNo $_.DownloadEnabled) -and -not [string]::IsNullOrWhiteSpace([string]$_.DirectDownloadURL)
    })
    Write-Header
    Write-Host "Download preview - exact sources" -ForegroundColor Cyan
    Write-Host "Source of truth: $Script:ToolListCsv"
    Write-Host "Only rows with Include=Yes and DownloadEnabled=Yes are listed here."
    Write-Host ""
    if ($tools.Count -eq 0) {
        Write-Host "No rows are currently eligible for download." -ForegroundColor Yellow
    }
    else {
        $i = 1
        foreach ($tool in $tools) {
            $valid = if (Test-HttpsUrl -Url ([string]$tool.DirectDownloadURL)) { "HTTPS allowed" } else { "Blocked: non-HTTPS" }
            $completedPath = Get-CompletedDownloadPathForTool -Tool $tool
            Write-Host "$i. $($tool.ToolName)" -ForegroundColor Green
            Write-Host "   Purpose/category: $($tool.Purpose) / $($tool.Category)"
            Write-Host "   Official review page: $($tool.OfficialSourceURL)"
            Write-Host "   Official host:        $(Get-SourceHost -Url ([string]$tool.OfficialSourceURL))"
            Write-Host "   Direct download URL:  $($tool.DirectDownloadURL)"
            Write-Host "   Direct host:          $(Get-SourceHost -Url ([string]$tool.DirectDownloadURL))"
            Write-Host "   Local file name:      $(Get-DownloadFileName -Tool $tool)"
            Write-Host "   Completed path:       $completedPath"
            Write-Host "   Target folder:        $($tool.TargetFolder)"
            Write-Host "   Source hash URL:      $($tool.HashSourceURL)"
            Write-Host "   Status:               $valid"
            Write-Host ""
            $i++
        }
    }
    Pause-Menu
}

function Confirm-EditableLists {
    Export-EditableBuildLists
    Write-Header
    Write-Host "Editable build lists created" -ForegroundColor Cyan
    Write-Host "Planning folder: $Script:PlanningDir"
    Write-Host "Software source of truth: $Script:ToolListCsv" -ForegroundColor Green
    Write-Host "Editing guide:            $(Get-ToolListEditingGuidePath)"
    Write-Host "Custom row template:      $(Get-CustomToolTemplatePath)"
    Write-Host "Transparency plan/info:   $(Get-DownloadTransparencyPlanPath)"
    Write-Host "Folder plan/info:         $Script:FolderListCsv"
    if ($Script:OutputFormat -eq "CSV+XLSX") { Write-Host "XLSX workbook/info:        $Script:BuildWorkbookXlsx" }
    Write-Host ""
    Write-Host "Edit ToolList_SOURCE_OF_TRUTH.csv before writing the build." -ForegroundColor Yellow
    Write-Host "- Include=Yes/No controls whether the tool source record is used."
    Write-Host "- TargetFolder controls where the tool source record/future downloaded files land."
    Write-Host "- DirectDownloadURL is the exact URL the download manager fetches when DownloadEnabled=Yes."
    Write-Host "- Add tools by adding rows with matching columns. Use CustomToolRow_TEMPLATE.csv as a starting point."
    Write-Host "- FolderStructure.csv, DownloadTransparencyPlan.csv, DownloadInstallQueue_INFRASTRUCTURE.csv, and XLSX are informational aids."
    Write-Host ""
    Write-Host " 1. Open planning folder"
    Write-Host " 2. Open source-of-truth CSV"
    Write-Host " 3. Continue using current lists"
    Write-Host " 4. Stop and resume later"
    Write-Host ""
    $choice = Read-MenuChoice -Prompt "Choice" -Min 1 -Max 4
    if ($choice -eq 1) { Start-Process explorer.exe $Script:PlanningDir; Pause-Menu }
    elseif ($choice -eq 2) { Invoke-Item $Script:ToolListCsv; Pause-Menu }
    elseif ($choice -eq 4) { Save-Session; throw "Stopped for list editing." }
}

function Show-DownloadInstallInfrastructure {
    Ensure-SessionDir
    if (-not (Test-Path $Script:DownloadQueueCsv)) { Export-EditableBuildLists }
    while ($true) {
        Write-Header
        Write-Host "Download manager" -ForegroundColor Cyan
        Write-Host "Source of truth: $Script:ToolListCsv" -ForegroundColor Green
        Write-Host "Manifest:        $Script:DownloadManifestCsv"
        Write-Host "Download root:   $Script:DownloadRoot"
        Write-Host ""
        Write-Host "Transparency model:" -ForegroundColor Yellow
        Write-Host "- Users can edit OfficialSourceURL, DirectDownloadURL, TargetFolder, and Include in the source-of-truth CSV."
        Write-Host "- DirectDownloadURL is the exact URL fetched. Downloads do not run unless DownloadEnabled=Yes."
        Write-Host "- Users can add tools by adding rows with matching columns."
        Write-Host "- This tool downloads and hashes only; it does not install or execute downloaded files."
        Write-Host ""
        Write-Host " 1. Open planning folder"
        Write-Host " 2. Open ToolList_SOURCE_OF_TRUTH.csv"
        Write-Host " 3. Open editing guide"
        Write-Host " 4. Create/open custom tool row template"
        Write-Host " 5. Validate source-of-truth list"
        Write-Host " 6. Download preview - exact sources"
        Write-Host " 7. Export transparency plan"
        Write-Host " 8. Regenerate queue from current source-of-truth list"
        Write-Host " 9. Export download readiness report"
        Write-Host "10. Run enabled downloads"
        Write-Host "11. Hash completed downloads"
        Write-Host "12. Open downloads folder"
        Write-Host "13. Open download manifest"
        Write-Host "14. Back"
        Write-Host ""
        $choice = Read-MenuChoice -Prompt "Choice" -Min 1 -Max 14
        if ($choice -eq 1) { Start-Process explorer.exe $Script:PlanningDir; Pause-Menu }
        elseif ($choice -eq 2) { if (-not (Test-Path $Script:ToolListCsv)) { Export-EditableBuildLists }; Invoke-Item $Script:ToolListCsv; Pause-Menu }
        elseif ($choice -eq 3) { $p = Write-ToolListEditingGuide; Invoke-Item $p; Pause-Menu }
        elseif ($choice -eq 4) { $p = Export-CustomToolRowTemplate; Invoke-Item $p; Pause-Menu }
        elseif ($choice -eq 5) { Show-ToolListValidation }
        elseif ($choice -eq 6) { Show-DownloadPreview }
        elseif ($choice -eq 7) { $p = Export-DownloadTransparencyPlan; Write-Host "Transparency plan exported: $p" -ForegroundColor Green; Pause-Menu }
        elseif ($choice -eq 8) {
            $tools = @(Import-CurrentToolRows)
            Export-DownloadInstallQueue -ToolRows $tools
            Write-Host "Queue regenerated: $Script:DownloadQueueCsv" -ForegroundColor Green
            Pause-Menu
        }
        elseif ($choice -eq 9) {
            $path = Export-DownloadReadinessReport
            Write-Host "Readiness report exported: $path" -ForegroundColor Green
            Pause-Menu
        }
        elseif ($choice -eq 10) { Invoke-EnabledDownloads }
        elseif ($choice -eq 11) { Hash-CompletedDownloads }
        elseif ($choice -eq 12) { Start-Process explorer.exe $Script:DownloadRoot; Pause-Menu }
        elseif ($choice -eq 13) {
            if (Test-Path $Script:DownloadManifestCsv) { Invoke-Item $Script:DownloadManifestCsv }
            else { Write-Host "No download manifest exists yet." -ForegroundColor Yellow }
            Pause-Menu
        }
        elseif ($choice -eq 14) { return }
    }
}

Start-Menu
