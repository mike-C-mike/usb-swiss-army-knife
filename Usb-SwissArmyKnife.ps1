#Requires -Version 5.1
<#
.SYNOPSIS
    Builds and maintains a local USB Swiss Army Knife software repository.

.DESCRIPTION
    Interactive menu:
      Run without parameters to open the guided menu.

    Modes:
      Menu       - Guided decision tree.
      Initialize - Creates the repository and downloads/imports catalog items.
      Update     - Refreshes changed or missing items.
      Audit      - Checks expected files, hashes, and metadata without downloading.
      Provision  - Copies a selected module profile to a confirmed USB drive.

    Source types:
      Direct            - Stable HTTPS download.
      GitHubLatest      - Current official GitHub release asset.
      InteractiveImport - Opens the official vendor page, waits for the user to
                          complete required interaction, then imports the resulting
                          package from the Downloads folder.

    Nothing is silently installed or executed.
#>

[CmdletBinding()]
param(
    [ValidateSet('Menu', 'Initialize', 'Update', 'Audit', 'Provision')]
    [string]$Mode = 'Menu',

    [string]$RootPath = (Join-Path $HOME 'usb-swiss-army-knife'),

    [string]$CatalogPath = (Join-Path $PSScriptRoot 'config\catalog.json'),

    [string]$ProfilesPath = (Join-Path $PSScriptRoot 'config\profiles.json'),

    [string]$BookmarksPath = (Join-Path $PSScriptRoot 'config\bookmarks.json'),

    [string]$DownloadsPath = (Join-Path $HOME 'Downloads'),

    [int]$InteractiveTimeoutMinutes = 30,

    [string]$ProfileId,

    [string]$TargetDrive,

    [switch]$Mirror,

    [switch]$Force,

    [switch]$NoExtract
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$ScriptVersion = '0.5.0'

function Write-Section {
    param([Parameter(Mandatory)][string]$Text)
    Write-Host ''
    Write-Host ('=' * 76) -ForegroundColor DarkGray
    Write-Host $Text -ForegroundColor Cyan
    Write-Host ('=' * 76) -ForegroundColor DarkGray
}

function New-RepositoryStructure {
    param([Parameter(Mandatory)][string]$Path)

    $folders = @(
        '00-ADMIN',
        '00-ADMIN\inventory',
        '00-ADMIN\logs',
        '00-ADMIN\manifests',
        '00-ADMIN\manual-imports',
        '01-BOOT\Ventoy',
        '01-BOOT\Rufus',
        '01-BOOT\ISO\Windows',
        '01-BOOT\ISO\Linux',
        '01-BOOT\ISO\Recovery',
        '01-BOOT\ISO\Security',
        '02-HELPDESK\Sysinternals',
        '02-HELPDESK\Diagnostics',
        '02-HELPDESK\Networking',
        '02-HELPDESK\Storage',
        '02-HELPDESK\Remote-Support',
        '03-FORENSICS\Acquisition\Memory\Windows',
        '03-FORENSICS\Acquisition\Memory\Linux',
        '03-FORENSICS\Acquisition\Disk\Windows',
        '03-FORENSICS\Acquisition\Disk\Linux',
        '03-FORENSICS\Analysis\Memory',
        '03-FORENSICS\Analysis\Disk',
        '03-FORENSICS\Analysis\Network',
        '04-INSTALLERS\Archivers',
        '04-INSTALLERS\Browsers',
        '04-INSTALLERS\Development',
        '04-INSTALLERS\Virtualization',
        '04-INSTALLERS\Drivers',
        '05-DRIVERS\Network',
        '05-DRIVERS\Storage',
        '05-DRIVERS\Serial',
        '06-PENTEST\Network',
        '06-PENTEST\Web',
        '06-PENTEST\Password-Recovery\Hashcat',
        '06-PENTEST\Documentation',
        '07-RECOVERY\Windows',
        '07-RECOVERY\Linux',
        '08-VMS\Kali',
        '08-VMS\Linux',
        '08-VMS\Windows-Evaluation',
        '09-SCRIPTS\PowerShell',
        '09-SCRIPTS\Python',
        '10-USB-PROFILES',
        '11-RESOURCES',
        '11-RESOURCES\Offline-Apps\CyberChef',
        '11-RESOURCES\Wordlists\SecLists',
        '11-RESOURCES\Living-Off-The-Land\GTFOBins',
        '11-RESOURCES\Living-Off-The-Land\LOLBAS',
        '11-RESOURCES\Cheat-Sheets\OWASP',
        '11-RESOURCES\Pentest-References\PayloadsAllTheThings',
        '11-RESOURCES\Pentest-References\HackTricks',
        '11-RESOURCES\OSINT\OSINT-Framework',
        '11-RESOURCES\OSINT\Bellingcat-Toolkit',
        '11-RESOURCES\Online-Bookmarks',
        '99-STAGING',
        '99-TRANSFER'
    )

    New-Item -ItemType Directory -Path $Path -Force | Out-Null
    foreach ($folder in $folders) {
        New-Item -ItemType Directory -Path (Join-Path $Path $folder) -Force | Out-Null
    }

    $readmePath = Join-Path $Path 'README.txt'
    if (-not (Test-Path $readmePath)) {
        @"
USB SWISS ARMY KNIFE
====================

Created: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Builder version: $ScriptVersion

The repository is the source of truth used to provision segmented USB drives.

Interactive imports:
  Some vendors require a form, account, email link, or EULA. The builder opens
  the official page, waits for the expected package to appear in Downloads,
  verifies what it can, hashes it, and moves it into the correct repository folder.

Rules:
  - Nothing is silently installed.
  - Nothing is silently executed.
  - Security tools are for authorized work and controlled labs.
  - General-purpose media must remain separate from forensic evidence media.
"@ | Set-Content -Path $readmePath -Encoding UTF8
    }
}

function Get-Catalog {
    param([Parameter(Mandatory)][string]$Path)
    if (-not (Test-Path $Path)) { throw "Catalog not found: $Path" }
    $catalog = Get-Content -Path $Path -Raw | ConvertFrom-Json
    if (-not $catalog.items) { throw 'Catalog contains no items.' }
    return $catalog
}

function Test-AllowedHost {
    param(
        [Parameter(Mandatory)][uri]$Uri,
        [Parameter(Mandatory)][string[]]$AllowedHosts
    )

    $hostName = $Uri.DnsSafeHost.ToLowerInvariant()
    foreach ($allowed in $AllowedHosts) {
        $allowedLower = $allowed.ToLowerInvariant()
        if ($hostName -eq $allowedLower -or $hostName.EndsWith(".$allowedLower")) {
            return $true
        }
    }
    return $false
}

function Get-GitHubLatestAsset {
    param([Parameter(Mandatory)]$Item)

    $apiUri = "https://api.github.com/repos/$($Item.repository)/releases/latest"
    $headers = @{
        'User-Agent' = 'UsbSwissArmyKnifeBuilder'
        'Accept'     = 'application/vnd.github+json'
    }

    $release = Invoke-RestMethod -Uri $apiUri -Headers $headers
    $matching = @($release.assets | Where-Object { $_.name -match $Item.assetRegex })

    if ($Item.excludeRegex) {
        $matching = @($matching | Where-Object { $_.name -notmatch $Item.excludeRegex })
    }

    if ($matching.Count -eq 0) {
        throw "No matching asset found for $($Item.name)"
    }
    if ($matching.Count -gt 1) {
        throw "Multiple assets matched for $($Item.name): $($matching.name -join ', ')"
    }

    [pscustomobject]@{
        Version  = [string]$release.tag_name
        FileName = [string]$matching[0].name
        Url      = [string]$matching[0].browser_download_url
    }
}

function Resolve-CatalogItem {
    param([Parameter(Mandatory)]$Item)

    switch ($Item.sourceType) {
        'Direct' {
            [pscustomobject]@{
                Version  = if ($Item.version) { [string]$Item.version } else { 'rolling' }
                FileName = [string]$Item.fileName
                Url      = [string]$Item.url
            }
        }
        'GitHubLatest' {
            Get-GitHubLatestAsset -Item $Item
        }
        'GitHubBranchArchive' {
            $branch = if ($Item.branch) { [string]$Item.branch } else { 'master' }
            $headers = @{
                'User-Agent' = 'UsbSwissArmyKnifeBuilder'
                'Accept'     = 'application/vnd.github+json'
            }
            $commitApi = "https://api.github.com/repos/$($Item.repository)/commits/$branch"
            $commit = Invoke-RestMethod -Uri $commitApi -Headers $headers
            $safeRepo = ([string]$Item.repository).Replace('/', '-')
            [pscustomobject]@{
                Version  = ([string]$commit.sha).Substring(0, 12)
                FileName = "$safeRepo-$branch.zip"
                Url      = "https://codeload.github.com/$($Item.repository)/zip/refs/heads/$branch"
            }
        }
        'InteractiveImport' {
            [pscustomobject]@{
                Version  = 'user-imported'
                FileName = $null
                Url      = [string]$Item.officialDownloadPage
            }
        }
        default {
            throw "Unsupported sourceType '$($Item.sourceType)' for $($Item.name)"
        }
    }
}

function Invoke-SafeDownload {
    param(
        [Parameter(Mandatory)][string]$Url,
        [Parameter(Mandatory)][string]$Destination,
        [Parameter(Mandatory)][string[]]$AllowedHosts
    )

    $uri = [uri]$Url
    if ($uri.Scheme -ne 'https') { throw "Refusing non-HTTPS download: $Url" }
    if (-not (Test-AllowedHost -Uri $uri -AllowedHosts $AllowedHosts)) {
        throw "Download host is not approved: $($uri.DnsSafeHost)"
    }

    $tempFile = "$Destination.partial"
    Remove-Item -Path $tempFile -Force -ErrorAction SilentlyContinue
    Invoke-WebRequest -Uri $uri -OutFile $tempFile -UseBasicParsing
    Move-Item -Path $tempFile -Destination $Destination -Force
}

function Get-NewInteractiveDownload {
    param(
        [Parameter(Mandatory)]$Item,
        [Parameter(Mandatory)][string]$DownloadFolder,
        [Parameter(Mandatory)][datetime]$StartedAfter,
        [Parameter(Mandatory)][int]$TimeoutMinutes
    )

    if (-not (Test-Path $DownloadFolder)) {
        throw "Downloads folder not found: $DownloadFolder"
    }

    $regex = [string]$Item.expectedFileRegex
    $deadline = (Get-Date).AddMinutes($TimeoutMinutes)

    Write-Host ''
    Write-Host "MANUAL STEP REQUIRED: $($Item.name)" -ForegroundColor Magenta
    Write-Host "Official page: $($Item.officialDownloadPage)" -ForegroundColor Cyan

    if ($Item.interactionInstructions) {
        Write-Host ''
        Write-Host 'Complete the following:' -ForegroundColor Yellow
        foreach ($instruction in @($Item.interactionInstructions)) {
            Write-Host "  - $instruction"
        }
    }

    Write-Host ''
    Write-Host "Waiting for a completed download matching: $regex"
    Write-Host "Watching: $DownloadFolder"
    Write-Host "Timeout: $TimeoutMinutes minute(s)"
    Write-Host ''

    Start-Process ([string]$Item.officialDownloadPage)

    while ((Get-Date) -lt $deadline) {
        $candidates = @(
            Get-ChildItem -Path $DownloadFolder -File -ErrorAction SilentlyContinue |
            Where-Object {
                $_.Name -match $regex -and
                $_.LastWriteTime -ge $StartedAfter -and
                $_.Extension -notin '.crdownload', '.partial', '.tmp'
            } |
            Sort-Object LastWriteTime -Descending
        )

        if ($candidates.Count -gt 0) {
            $candidate = $candidates[0]

            # Wait until file size stops changing before accepting it.
            $firstSize = $candidate.Length
            Start-Sleep -Seconds 3
            $candidate.Refresh()
            if ($candidate.Length -eq $firstSize -and $candidate.Length -gt 0) {
                return $candidate
            }
        }

        Start-Sleep -Seconds 2
    }

    throw "Timed out waiting for $($Item.name)."
}

function Test-AuthenticodePolicy {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)]$Item
    )

    $result = [pscustomobject]@{
        Checked = $false
        Status = 'NotChecked'
        Signer = ''
        Passed = $true
    }

    if (-not $Item.signaturePolicy -or $Item.signaturePolicy -eq 'None') {
        return $result
    }

    if ([IO.Path]::GetExtension($Path).ToLowerInvariant() -notin '.exe', '.msi', '.dll', '.sys') {
        if ($Item.signaturePolicy -eq 'Required') {
            $result.Checked = $true
            $result.Status = 'UnsupportedFileType'
            $result.Passed = $false
        }
        return $result
    }

    $signature = Get-AuthenticodeSignature -FilePath $Path
    $result.Checked = $true
    $result.Status = [string]$signature.Status
    if ($signature.SignerCertificate) {
        $result.Signer = [string]$signature.SignerCertificate.Subject
    }

    if ($Item.signaturePolicy -eq 'Required' -and $signature.Status -ne 'Valid') {
        $result.Passed = $false
    }

    if ($Item.expectedSignerRegex -and
        $result.Signer -notmatch [string]$Item.expectedSignerRegex) {
        $result.Passed = $false
        $result.Status = 'UnexpectedSigner'
    }

    return $result
}

function Import-InteractiveItem {
    param(
        [Parameter(Mandatory)]$Item,
        [Parameter(Mandatory)][string]$DestinationFolder,
        [Parameter(Mandatory)][string]$DownloadFolder,
        [Parameter(Mandatory)][int]$TimeoutMinutes
    )

    $started = Get-Date
    $downloaded = Get-NewInteractiveDownload `
        -Item $Item `
        -DownloadFolder $DownloadFolder `
        -StartedAfter $started `
        -TimeoutMinutes $TimeoutMinutes

    $signature = Test-AuthenticodePolicy -Path $downloaded.FullName -Item $Item
    if (-not $signature.Passed) {
        throw "Signature policy failed for $($downloaded.Name): $($signature.Status) $($signature.Signer)"
    }

    $destination = Join-Path $DestinationFolder $downloaded.Name
    Copy-Item -Path $downloaded.FullName -Destination $destination -Force

    [pscustomobject]@{
        Version = 'user-imported'
        FileName = $downloaded.Name
        Url = [string]$Item.officialDownloadPage
        Destination = $destination
        SignatureStatus = $signature.Status
        Signer = $signature.Signer
    }
}

function Expand-DownloadedItem {
    param(
        [Parameter(Mandatory)][string]$ArchivePath,
        [Parameter(Mandatory)][string]$DestinationFolder
    )

    if ([IO.Path]::GetExtension($ArchivePath).ToLowerInvariant() -ne '.zip') {
        Write-Warning "Automatic extraction currently supports ZIP only: $ArchivePath"
        return
    }

    $extractPath = Join-Path $DestinationFolder 'extracted'
    if (Test-Path $extractPath) {
        Remove-Item -Path $extractPath -Recurse -Force
    }
    New-Item -ItemType Directory -Path $extractPath -Force | Out-Null
    Expand-Archive -Path $ArchivePath -DestinationPath $extractPath -Force
}

function Read-Inventory {
    param([Parameter(Mandatory)][string]$Path)

    if (-not (Test-Path $Path)) { return @{} }

    $raw = Get-Content -Path $Path -Raw | ConvertFrom-Json
    $map = @{}
    foreach ($record in @($raw)) {
        $map[[string]$record.Id] = $record
    }
    return $map
}

function Save-Inventory {
    param(
        [Parameter(Mandatory)][System.Collections.IEnumerable]$Records,
        [Parameter(Mandatory)][string]$JsonPath,
        [Parameter(Mandatory)][string]$CsvPath
    )

    $array = @($Records | Sort-Object Name)
    $array | ConvertTo-Json -Depth 8 | Set-Content -Path $JsonPath -Encoding UTF8
    $array | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8
}

function Invoke-CatalogProcessing {
    param(
        [Parameter(Mandatory)]$Catalog,
        [Parameter(Mandatory)][string]$RepositoryRoot,
        [Parameter(Mandatory)][ValidateSet('Initialize', 'Update', 'Audit')]
        [string]$Operation
    )

    $inventoryDir = Join-Path $RepositoryRoot '00-ADMIN\inventory'
    $inventoryJson = Join-Path $inventoryDir 'inventory.json'
    $inventoryCsv = Join-Path $inventoryDir 'inventory.csv'
    $currentInventory = Read-Inventory -Path $inventoryJson
    $newRecords = [System.Collections.Generic.List[object]]::new()
    $auditFailures = 0

    foreach ($item in $Catalog.items) {
        Write-Host "[$Operation] $($item.name)" -ForegroundColor Yellow

        try {
            $resolved = Resolve-CatalogItem -Item $item
            $destinationFolder = Join-Path $RepositoryRoot $item.destination
            New-Item -ItemType Directory -Path $destinationFolder -Force | Out-Null

            $existingRecord = $currentInventory[[string]$item.id]
            $destinationFile = $null
            $signatureStatus = 'NotChecked'
            $signer = ''

            if ($item.sourceType -eq 'InteractiveImport') {
                if ($existingRecord) {
                    $destinationFile = Join-Path $RepositoryRoot $existingRecord.RelativePath
                }

                if ($Operation -eq 'Audit') {
                    if (-not $destinationFile -or -not (Test-Path $destinationFile)) {
                        Write-Host '  MISSING INTERACTIVE IMPORT' -ForegroundColor Red
                        Write-Host "  Official page: $($item.officialDownloadPage)" -ForegroundColor Cyan
                        $auditFailures++
                        continue
                    }
                }
                elseif ($Force.IsPresent -or -not $destinationFile -or -not (Test-Path $destinationFile)) {
                    $import = Import-InteractiveItem `
                        -Item $item `
                        -DestinationFolder $destinationFolder `
                        -DownloadFolder $DownloadsPath `
                        -TimeoutMinutes $InteractiveTimeoutMinutes

                    $resolved.Version = $import.Version
                    $resolved.FileName = $import.FileName
                    $destinationFile = $import.Destination
                    $signatureStatus = $import.SignatureStatus
                    $signer = $import.Signer

                    if ($item.extract -and -not $NoExtract.IsPresent) {
                        Expand-DownloadedItem `
                            -ArchivePath $destinationFile `
                            -DestinationFolder $destinationFolder
                    }
                }
                else {
                    Write-Host '  Present; interactive download skipped.' -ForegroundColor Green
                }
            }
            else {
                $destinationFile = Join-Path $destinationFolder $resolved.FileName
                $needsDownload = $Force.IsPresent -or -not (Test-Path $destinationFile)

                if (-not $needsDownload -and $existingRecord) {
                    if ([string]$existingRecord.Version -ne [string]$resolved.Version -or
                        [string]$existingRecord.FileName -ne [string]$resolved.FileName) {
                        $needsDownload = $true
                    }
                }

                if ($Operation -eq 'Audit') {
                    if (-not (Test-Path $destinationFile)) {
                        Write-Host "  MISSING: $destinationFile" -ForegroundColor Red
                        $auditFailures++
                        continue
                    }
                }
                elseif ($needsDownload) {
                    Write-Host "  Downloading $($resolved.FileName)"
                    Invoke-SafeDownload `
                        -Url $resolved.Url `
                        -Destination $destinationFile `
                        -AllowedHosts @($item.allowedHosts)

                    $signature = Test-AuthenticodePolicy -Path $destinationFile -Item $item
                    $signatureStatus = $signature.Status
                    $signer = $signature.Signer
                    if (-not $signature.Passed) {
                        throw "Signature policy failed: $signatureStatus $signer"
                    }

                    if ($item.extract -and -not $NoExtract.IsPresent) {
                        Write-Host '  Extracting'
                        Expand-DownloadedItem `
                            -ArchivePath $destinationFile `
                            -DestinationFolder $destinationFolder
                    }
                }
                else {
                    Write-Host '  Current; no download needed.' -ForegroundColor Green
                }
            }

            if (-not $destinationFile -or -not (Test-Path $destinationFile)) {
                throw "Expected file is unavailable for $($item.name)"
            }

            $fileInfo = Get-Item -Path $destinationFile
            $actualHash = (Get-FileHash -Path $destinationFile -Algorithm SHA256).Hash

            if ($Operation -eq 'Audit') {
                if ($existingRecord -and $existingRecord.SHA256 -and
                    $actualHash -ne [string]$existingRecord.SHA256) {
                    Write-Host '  HASH MISMATCH' -ForegroundColor Red
                    $auditFailures++
                }
                else {
                    Write-Host '  OK' -ForegroundColor Green
                }
                continue
            }

            $newRecords.Add([pscustomobject]@{
                Id              = [string]$item.id
                Name            = [string]$item.name
                Category        = [string]$item.category
                SourceType      = [string]$item.sourceType
                Version         = [string]$resolved.Version
                FileName        = [string]$fileInfo.Name
                RelativePath    = [string](Join-Path $item.destination $fileInfo.Name)
                SourceUrl       = [string]$resolved.Url
                SHA256          = [string]$actualHash
                SizeBytes       = [long]$fileInfo.Length
                SignatureStatus = [string]$signatureStatus
                Signer          = [string]$signer
                RetrievedUtc    = (Get-Date).ToUniversalTime().ToString('o')
                BuilderVersion  = $ScriptVersion
            })
        }
        catch {
            Write-Host "  ERROR: $($_.Exception.Message)" -ForegroundColor Red
            if ($Operation -eq 'Audit') { $auditFailures++ }
        }
    }

    if ($Operation -ne 'Audit') {
        Save-Inventory -Records $newRecords -JsonPath $inventoryJson -CsvPath $inventoryCsv
        Write-Host ''
        Write-Host "Inventory written to $inventoryDir" -ForegroundColor Cyan
    }
    elseif ($auditFailures -gt 0) {
        throw "Audit completed with $auditFailures failure(s)."
    }
    else {
        Write-Host ''
        Write-Host 'Audit passed.' -ForegroundColor Green
    }
}


function Get-Profiles {
    param([Parameter(Mandatory)][string]$Path)

    if (-not (Test-Path $Path)) {
        throw "Profiles file not found: $Path"
    }

    $profilesDocument = Get-Content -Path $Path -Raw | ConvertFrom-Json
    if (-not $profilesDocument.profiles) {
        throw 'Profiles file contains no profiles.'
    }

    return @($profilesDocument.profiles)
}

function Get-FriendlySize {
    param([Parameter(Mandatory)][long]$Bytes)

    if ($Bytes -ge 1TB) { return ('{0:N2} TB' -f ($Bytes / 1TB)) }
    if ($Bytes -ge 1GB) { return ('{0:N2} GB' -f ($Bytes / 1GB)) }
    if ($Bytes -ge 1MB) { return ('{0:N2} MB' -f ($Bytes / 1MB)) }
    return "$Bytes bytes"
}

function Get-RepositoryContentSize {
    param(
        [Parameter(Mandatory)][string]$RepositoryRoot,
        [Parameter(Mandatory)]$Profile
    )

    [long]$total = 0
    foreach ($relativePath in @($Profile.includePaths)) {
        $source = Join-Path $RepositoryRoot $relativePath
        if (Test-Path $source) {
            $item = Get-Item -Path $source
            if ($item.PSIsContainer) {
                $measure = Get-ChildItem -Path $source -File -Recurse -ErrorAction SilentlyContinue |
                    Measure-Object -Property Length -Sum
                if ($measure.Sum) { $total += [long]$measure.Sum }
            }
            else {
                $total += [long]$item.Length
            }
        }
    }
    return $total
}

function Show-Profiles {
    param(
        [Parameter(Mandatory)]$Profiles,
        [string]$RepositoryRoot
    )

    Write-Section 'Available USB Profiles'
    for ($index = 0; $index -lt $Profiles.Count; $index++) {
        $profile = $Profiles[$index]
        $recommended = "$($profile.minimumSizeGB) GB minimum"
        $currentSize = ''
        if ($RepositoryRoot -and (Test-Path $RepositoryRoot)) {
            $bytes = Get-RepositoryContentSize `
                -RepositoryRoot $RepositoryRoot `
                -Profile $profile
            $currentSize = " | Current content: $(Get-FriendlySize -Bytes $bytes)"
        }

        Write-Host ("[{0}] {1}" -f ($index + 1), $profile.name) -ForegroundColor Yellow
        Write-Host "    $($profile.description)"
        Write-Host "    Recommended media: $recommended$currentSize" -ForegroundColor DarkGray
    }
}

function Select-ProfileInteractive {
    param(
        [Parameter(Mandatory)]$Profiles,
        [Parameter(Mandatory)][string]$RepositoryRoot
    )

    while ($true) {
        Show-Profiles -Profiles $Profiles -RepositoryRoot $RepositoryRoot
        Write-Host ''
        $selection = Read-Host 'Select a profile number, or Q to cancel'
        if ($selection -match '^(q|quit|cancel)$') { return $null }

        [int]$number = 0
        if ([int]::TryParse($selection, [ref]$number) -and
            $number -ge 1 -and $number -le $Profiles.Count) {
            return $Profiles[$number - 1]
        }

        Write-Host 'Invalid profile selection.' -ForegroundColor Red
    }
}

function Get-CandidateTargetDrives {
    $systemDrive = $env:SystemDrive.TrimEnd('\')
    $volumes = @(
        Get-CimInstance Win32_LogicalDisk |
        Where-Object {
            $_.DeviceID -ne $systemDrive -and
            $_.DriveType -in 2, 3 -and
            $_.Size -gt 0
        } |
        Sort-Object DeviceID
    )

    return $volumes
}

function Select-TargetDriveInteractive {
    $drives = Get-CandidateTargetDrives
    if ($drives.Count -eq 0) {
        throw 'No eligible removable or local target drives were found.'
    }

    Write-Section 'Select Target USB'
    for ($index = 0; $index -lt $drives.Count; $index++) {
        $drive = $drives[$index]
        $label = if ($drive.VolumeName) { $drive.VolumeName } else { '(no label)' }
        Write-Host ("[{0}] {1}  {2}  {3} free of {4}" -f `
            ($index + 1),
            $drive.DeviceID,
            $label,
            (Get-FriendlySize -Bytes ([long]$drive.FreeSpace)),
            (Get-FriendlySize -Bytes ([long]$drive.Size)))
    }

    while ($true) {
        Write-Host ''
        $selection = Read-Host 'Select a drive number, or Q to cancel'
        if ($selection -match '^(q|quit|cancel)$') { return $null }

        [int]$number = 0
        if ([int]::TryParse($selection, [ref]$number) -and
            $number -ge 1 -and $number -le $drives.Count) {
            return $drives[$number - 1]
        }

        Write-Host 'Invalid drive selection.' -ForegroundColor Red
    }
}

function Resolve-TargetDrive {
    param([Parameter(Mandatory)][string]$Drive)

    $normalized = $Drive.TrimEnd('\')
    if ($normalized -notmatch '^[A-Za-z]:$') {
        throw "Target drive must look like E: or F:. Received: $Drive"
    }

    if ($normalized -ieq $env:SystemDrive.TrimEnd('\')) {
        throw 'Refusing to provision the Windows system drive.'
    }

    $candidate = Get-CimInstance Win32_LogicalDisk |
        Where-Object DeviceID -eq $normalized

    if (-not $candidate) {
        throw "Target drive not found: $normalized"
    }

    if ($candidate.DriveType -notin 2, 3) {
        throw 'Target is not an eligible removable or local drive.'
    }

    return $candidate
}

function Confirm-Provisioning {
    param(
        [Parameter(Mandatory)]$Profile,
        [Parameter(Mandatory)]$Drive,
        [Parameter(Mandatory)][long]$RequiredBytes,
        [Parameter(Mandatory)][bool]$MirrorMode
    )

    Write-Section 'Confirm USB Provisioning'
    Write-Host "Profile:        $($Profile.name)"
    Write-Host "Target drive:   $($Drive.DeviceID)"
    Write-Host "Volume label:   $(if ($Drive.VolumeName) { $Drive.VolumeName } else { '(no label)' })"
    Write-Host "Drive capacity: $(Get-FriendlySize -Bytes ([long]$Drive.Size))"
    Write-Host "Free space:     $(Get-FriendlySize -Bytes ([long]$Drive.FreeSpace))"
    Write-Host "Content size:   $(Get-FriendlySize -Bytes $RequiredBytes)"
    Write-Host "Mode:           $(if ($MirrorMode) { 'MIRROR — obsolete destination files may be removed' } else { 'UPDATE — existing unrelated files are preserved' })"

    if ($MirrorMode) {
        Write-Host ''
        Write-Host 'WARNING: Mirror mode may delete destination files inside managed profile folders.' `
            -ForegroundColor Red
    }

    Write-Host ''
    $expected = "PROVISION $($Drive.DeviceID)".ToUpperInvariant()
    $confirmation = Read-Host "Type '$expected' to continue"
    return ($confirmation.ToUpperInvariant() -ceq $expected)
}

function Copy-ProfileContent {
    param(
        [Parameter(Mandatory)][string]$RepositoryRoot,
        [Parameter(Mandatory)]$Profile,
        [Parameter(Mandatory)][string]$DestinationRoot,
        [Parameter(Mandatory)][bool]$MirrorMode
    )

    $logRoot = Join-Path $RepositoryRoot '00-ADMIN\logs'
    New-Item -ItemType Directory -Path $logRoot -Force | Out-Null
    $copyLog = Join-Path $logRoot ('provision-{0}-{1}.log' -f `
        $Profile.id, (Get-Date -Format 'yyyyMMdd-HHmmss'))

    foreach ($relativePath in @($Profile.includePaths)) {
        $source = Join-Path $RepositoryRoot $relativePath
        if (-not (Test-Path $source)) {
            Write-Warning "Profile source is missing and will be skipped: $relativePath"
            continue
        }

        $destination = Join-Path $DestinationRoot $relativePath
        $sourceItem = Get-Item -Path $source

        if ($sourceItem.PSIsContainer) {
            New-Item -ItemType Directory -Path $destination -Force | Out-Null

            $arguments = @(
                $source,
                $destination,
                if ($MirrorMode) { '/MIR' } else { '/E' },
                '/COPY:DAT',
                '/DCOPY:DAT',
                '/R:2',
                '/W:2',
                '/XJ',
                '/FFT',
                '/NP',
                "/LOG+:$copyLog"
            )

            & robocopy @arguments | Out-Null
            $exitCode = $LASTEXITCODE
            if ($exitCode -ge 8) {
                throw "Robocopy failed for $relativePath with exit code $exitCode."
            }
        }
        else {
            $parent = Split-Path -Parent $destination
            New-Item -ItemType Directory -Path $parent -Force | Out-Null
            Copy-Item -Path $source -Destination $destination -Force
        }
    }

    $profileManifest = [pscustomobject]@{
        ProfileId        = [string]$Profile.id
        ProfileName      = [string]$Profile.name
        ProvisionedUtc   = (Get-Date).ToUniversalTime().ToString('o')
        BuilderVersion   = $ScriptVersion
        SourceRepository = $RepositoryRoot
        Computer         = $env:COMPUTERNAME
        CopyMode         = if ($MirrorMode) { 'Mirror' } else { 'Update' }
        IncludedPaths    = @($Profile.includePaths)
    }

    $manifestPath = Join-Path $DestinationRoot 'USB-PROFILE.json'
    $profileManifest | ConvertTo-Json -Depth 6 |
        Set-Content -Path $manifestPath -Encoding UTF8

    $readmePath = Join-Path $DestinationRoot 'USB-README.txt'
    @"
USB SWISS ARMY KNIFE PROFILE
============================

Profile: $($Profile.name)
Description: $($Profile.description)
Provisioned: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Builder version: $ScriptVersion

This media contains general IT, recovery, training, or authorized security tools.
It is not forensic evidence media and does not provide hardware write blocking.
"@ | Set-Content -Path $readmePath -Encoding UTF8

    return $copyLog
}

function Invoke-ProvisionProfile {
    param(
        [Parameter(Mandatory)][string]$RepositoryRoot,
        [Parameter(Mandatory)]$Profile,
        [Parameter(Mandatory)]$Drive,
        [Parameter(Mandatory)][bool]$MirrorMode
    )

    $requiredBytes = Get-RepositoryContentSize `
        -RepositoryRoot $RepositoryRoot `
        -Profile $Profile

    $minimumCapacityBytes = [long]$Profile.minimumSizeGB * 1GB
    if ([long]$Drive.Size -lt $minimumCapacityBytes) {
        throw "The selected drive is smaller than the profile minimum of $($Profile.minimumSizeGB) GB."
    }

    if ([long]$Drive.FreeSpace -lt $requiredBytes) {
        throw "The selected drive does not have enough free space. Required: $(Get-FriendlySize $requiredBytes)"
    }

    if (-not (Confirm-Provisioning `
        -Profile $Profile `
        -Drive $Drive `
        -RequiredBytes $requiredBytes `
        -MirrorMode $MirrorMode)) {
        Write-Host 'Provisioning cancelled.' -ForegroundColor Yellow
        return
    }

    $destinationRoot = "$($Drive.DeviceID)\"
    Write-Host ''
    Write-Host "Provisioning $($Profile.name) to $destinationRoot ..." -ForegroundColor Cyan

    $copyLog = Copy-ProfileContent `
        -RepositoryRoot $RepositoryRoot `
        -Profile $Profile `
        -DestinationRoot $destinationRoot `
        -MirrorMode $MirrorMode

    Write-Host ''
    Write-Host 'Provisioning completed successfully.' -ForegroundColor Green
    Write-Host "Copy log: $copyLog" -ForegroundColor DarkGray
}

function Invoke-RepositoryOperation {
    param(
        [Parameter(Mandatory)][ValidateSet('Initialize', 'Update', 'Audit')]
        [string]$Operation
    )

    New-RepositoryStructure -Path $RootPath
    $catalog = Get-Catalog -Path $CatalogPath

    Copy-Item `
        -Path $CatalogPath `
        -Destination (Join-Path $RootPath '00-ADMIN\manifests\catalog.json') `
        -Force

    Copy-Item `
        -Path $ProfilesPath `
        -Destination (Join-Path $RootPath '00-ADMIN\manifests\profiles.json') `
        -Force

    $logPath = Join-Path $RootPath ('00-ADMIN\logs\{0}-{1}.log' -f `
        (Get-Date -Format 'yyyyMMdd-HHmmss'), $Operation.ToLowerInvariant())

    Start-Transcript -Path $logPath -Force | Out-Null
    try {
        Invoke-CatalogProcessing `
            -Catalog $catalog `
            -RepositoryRoot $RootPath `
            -Operation $Operation
    }
    finally {
        Stop-Transcript | Out-Null
    }

    Write-Host ''
    Write-Host "Repository: $RootPath" -ForegroundColor Cyan
    Write-Host "Log:        $logPath" -ForegroundColor Cyan
}

function Invoke-ProvisionSelection {
    $profiles = Get-Profiles -Path $ProfilesPath

    $selectedProfile = $null
    if ($ProfileId) {
        $selectedProfile = $profiles | Where-Object id -eq $ProfileId | Select-Object -First 1
        if (-not $selectedProfile) {
            throw "Unknown profile id: $ProfileId"
        }
    }
    else {
        $selectedProfile = Select-ProfileInteractive `
            -Profiles $profiles `
            -RepositoryRoot $RootPath
        if (-not $selectedProfile) { return }
    }

    $selectedDrive = if ($TargetDrive) {
        Resolve-TargetDrive -Drive $TargetDrive
    }
    else {
        Select-TargetDriveInteractive
    }

    if (-not $selectedDrive) { return }

    Invoke-ProvisionProfile `
        -RepositoryRoot $RootPath `
        -Profile $selectedProfile `
        -Drive $selectedDrive `
        -MirrorMode $Mirror.IsPresent
}


function Get-ResourceCatalog {
    param(
        [Parameter(Mandatory)]$Catalog,
        [Parameter(Mandatory)][string[]]$BundleIds
    )

    $selectedItems = @(
        $Catalog.items | Where-Object {
            $_.resourceBundles -and
            (@($_.resourceBundles) | Where-Object { $_ -in $BundleIds }).Count -gt 0
        }
    )

    [pscustomobject]@{
        schemaVersion = $Catalog.schemaVersion
        notes = "Filtered resource catalog: $($BundleIds -join ', ')"
        items = $selectedItems
    }
}

function Get-Bookmarks {
    param([Parameter(Mandatory)][string]$Path)

    if (-not (Test-Path $Path)) {
        throw "Bookmarks file not found: $Path"
    }

    return Get-Content -Path $Path -Raw | ConvertFrom-Json
}

function Convert-ToFileUri {
    param([Parameter(Mandatory)][string]$Path)

    $resolved = [IO.Path]::GetFullPath($Path)
    return ([uri]$resolved).AbsoluteUri
}

function Find-LocalResourceEntry {
    param(
        [Parameter(Mandatory)][string]$RepositoryRoot,
        [Parameter(Mandatory)]$Resource
    )

    $base = Join-Path $RepositoryRoot $Resource.path
    if (-not (Test-Path $base)) { return $null }

    foreach ($pattern in @($Resource.entryPatterns)) {
        $candidate = Get-ChildItem -Path $base -File -Recurse -ErrorAction SilentlyContinue |
            Where-Object Name -Like $pattern |
            Select-Object -First 1
        if ($candidate) {
            return $candidate.FullName
        }
    }

    return $base
}

function Build-StartHereDashboard {
    param(
        [Parameter(Mandatory)][string]$RepositoryRoot,
        [Parameter(Mandatory)][string]$BookmarksFile
    )

    $bookmarks = Get-Bookmarks -Path $BookmarksFile
    $resourceRoot = Join-Path $RepositoryRoot '11-RESOURCES'
    New-Item -ItemType Directory -Path $resourceRoot -Force | Out-Null

    $cards = [System.Collections.Generic.List[string]]::new()

    foreach ($resource in @($bookmarks.offlineResources)) {
        $entry = Find-LocalResourceEntry `
            -RepositoryRoot $RepositoryRoot `
            -Resource $resource

        $status = if ($entry) { 'Available' } else { 'Not installed' }
        $statusClass = if ($entry) { 'available' } else { 'missing' }

        $action = if ($entry) {
            $uri = Convert-ToFileUri -Path $entry
            "<a class=`"button`" href=`"$uri`">Open offline</a>"
        }
        else {
            "<span class=`"button disabled`">Install from Resources menu</span>"
        }

        $cards.Add(@"
<article class="card">
  <div class="card-top">
    <h3>$([System.Net.WebUtility]::HtmlEncode([string]$resource.name))</h3>
    <span class="status $statusClass">$status</span>
  </div>
  <p>$([System.Net.WebUtility]::HtmlEncode([string]$resource.description))</p>
  <div class="actions">
    $action
    <a class="secondary" href="$([System.Net.WebUtility]::HtmlEncode([string]$resource.onlineUrl))">Official site</a>
  </div>
</article>
"@)
    }

    $onlineSections = [System.Collections.Generic.List[string]]::new()
    foreach ($category in @($bookmarks.onlineCategories)) {
        $links = [System.Collections.Generic.List[string]]::new()
        foreach ($link in @($category.links)) {
            $links.Add(@"
<li>
  <a href="$([System.Net.WebUtility]::HtmlEncode([string]$link.url))">
    $([System.Net.WebUtility]::HtmlEncode([string]$link.name))
  </a>
  <span>$([System.Net.WebUtility]::HtmlEncode([string]$link.description))</span>
</li>
"@)
        }

        $onlineSections.Add(@"
<section class="link-section">
  <h2>$([System.Net.WebUtility]::HtmlEncode([string]$category.name))</h2>
  <ul>
    $($links -join "`n")
  </ul>
</section>
"@)
    }

    $warning = [System.Net.WebUtility]::HtmlEncode([string]$bookmarks.securityNotice)
    $generated = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'

    $document = @"
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>USB Swiss Army Knife</title>
<style>
:root {
  color-scheme: dark;
  --bg: #101418;
  --panel: #182026;
  --border: #33414b;
  --text: #e8eef2;
  --muted: #aab8c2;
  --accent: #51d18a;
  --warning: #f0c36b;
  --danger: #ef8585;
}
* { box-sizing: border-box; }
body {
  margin: 0;
  font-family: Segoe UI, Arial, sans-serif;
  background: var(--bg);
  color: var(--text);
}
header, main, footer { max-width: 1180px; margin: auto; padding: 24px; }
header h1 { margin-bottom: 8px; }
header p, footer { color: var(--muted); }
.notice {
  border: 1px solid var(--warning);
  padding: 14px;
  border-radius: 10px;
  margin: 18px 0 28px;
  background: #2a2417;
}
.grid {
  display: grid;
  grid-template-columns: repeat(auto-fit,minmax(260px,1fr));
  gap: 16px;
}
.card, .link-section {
  background: var(--panel);
  border: 1px solid var(--border);
  border-radius: 12px;
  padding: 18px;
}
.card-top {
  display: flex;
  justify-content: space-between;
  gap: 12px;
  align-items: start;
}
.card h3, .link-section h2 { margin-top: 0; }
.status {
  font-size: .8rem;
  border-radius: 999px;
  padding: 4px 9px;
  white-space: nowrap;
}
.status.available { background: #153c29; color: #8de4b4; }
.status.missing { background: #432326; color: #ffb1b7; }
.actions { display: flex; gap: 10px; flex-wrap: wrap; margin-top: 18px; }
.button, .secondary {
  display: inline-block;
  padding: 9px 12px;
  border-radius: 8px;
  text-decoration: none;
}
.button { background: var(--accent); color: #07150e; font-weight: 600; }
.button.disabled { background: #3b464d; color: #bac3c8; }
.secondary { border: 1px solid var(--border); color: var(--text); }
.link-section { margin-top: 18px; }
.link-section li { margin: 10px 0; }
.link-section li span { display: block; color: var(--muted); margin-top: 3px; }
a { color: #8fc8ff; }
</style>
</head>
<body>
<header>
  <h1>USB Swiss Army Knife</h1>
  <p>Portable tools, offline references, and trusted online resources.</p>
  <div class="notice">$warning</div>
</header>
<main>
  <h2>Offline resources</h2>
  <div class="grid">
    $($cards -join "`n")
  </div>
  <h2 style="margin-top:32px">Online references</h2>
  $($onlineSections -join "`n")
</main>
<footer>
  Generated $generated by USB Swiss Army Knife v$ScriptVersion.
</footer>
</body>
</html>
"@

    $dashboardPath = Join-Path $resourceRoot 'START-HERE.html'
    Set-Content -Path $dashboardPath -Value $document -Encoding UTF8

    $bookmarkCopy = Join-Path $resourceRoot 'Online-Bookmarks\bookmarks.json'
    New-Item -ItemType Directory -Path (Split-Path -Parent $bookmarkCopy) -Force | Out-Null
    Copy-Item -Path $BookmarksFile -Destination $bookmarkCopy -Force

    Write-Host "Dashboard built: $dashboardPath" -ForegroundColor Green
    return $dashboardPath
}

function Invoke-ResourceOperation {
    param(
        [Parameter(Mandatory)][string[]]$BundleIds,
        [Parameter(Mandatory)][ValidateSet('Initialize', 'Update', 'Audit')]
        [string]$Operation
    )

    New-RepositoryStructure -Path $RootPath
    $catalog = Get-Catalog -Path $CatalogPath
    $resourceCatalog = Get-ResourceCatalog `
        -Catalog $catalog `
        -BundleIds $BundleIds

    if (@($resourceCatalog.items).Count -eq 0) {
        throw "No catalog resources matched bundle(s): $($BundleIds -join ', ')"
    }

    $logPath = Join-Path $RootPath ('00-ADMIN\logs\{0}-resources-{1}.log' -f `
        (Get-Date -Format 'yyyyMMdd-HHmmss'), $Operation.ToLowerInvariant())

    Start-Transcript -Path $logPath -Force | Out-Null
    try {
        Invoke-CatalogProcessing `
            -Catalog $resourceCatalog `
            -RepositoryRoot $RootPath `
            -Operation $Operation

        if ($Operation -ne 'Audit') {
            Build-StartHereDashboard `
                -RepositoryRoot $RootPath `
                -BookmarksFile $BookmarksPath | Out-Null
        }
    }
    finally {
        Stop-Transcript | Out-Null
    }

    Write-Host "Resource log: $logPath" -ForegroundColor DarkGray
}

function Show-ResourceMenu {
    Write-Section 'Resources and References'
    Write-Host '[1] Install recommended offline resources'
    Write-Host '[2] Install or update CyberChef only'
    Write-Host '[3] Install living-off-the-land references'
    Write-Host '[4] Install OSINT reference bundle'
    Write-Host '[5] Install SecLists'
    Write-Host '[6] Install full pentest reference bundle'
    Write-Host '[7] Update all installed resource bundles'
    Write-Host '[8] Audit resource files'
    Write-Host '[9] Build or refresh START-HERE dashboard'
    Write-Host '[10] Open START-HERE dashboard'
    Write-Host '[0] Back'
    Write-Host ''
}

function Invoke-ResourceMenu {
    while ($true) {
        Show-ResourceMenu
        $choice = Read-Host 'Choose a resource action'

        try {
            switch ($choice) {
                '1' {
                    Invoke-ResourceOperation `
                        -BundleIds @('recommended') `
                        -Operation Initialize
                }
                '2' {
                    Invoke-ResourceOperation `
                        -BundleIds @('cyberchef') `
                        -Operation Update
                }
                '3' {
                    Invoke-ResourceOperation `
                        -BundleIds @('living-off-land') `
                        -Operation Update
                }
                '4' {
                    Invoke-ResourceOperation `
                        -BundleIds @('osint') `
                        -Operation Update
                }
                '5' {
                    Write-Host ''
                    Write-Host 'SecLists can trigger antivirus detections and consumes significant space.' `
                        -ForegroundColor Yellow
                    $confirm = Read-Host 'Type SECLISTS to continue'
                    if ($confirm -ceq 'SECLISTS') {
                        Invoke-ResourceOperation `
                            -BundleIds @('seclists') `
                            -Operation Update
                    }
                }
                '6' {
                    Write-Host ''
                    Write-Host 'The full bundle contains payload examples and wordlists.' `
                        -ForegroundColor Yellow
                    $confirm = Read-Host 'Type FULL RESOURCES to continue'
                    if ($confirm -ceq 'FULL RESOURCES') {
                        Invoke-ResourceOperation `
                            -BundleIds @('full-pentest') `
                            -Operation Update
                    }
                }
                '7' {
                    Invoke-ResourceOperation `
                        -BundleIds @('all-resources') `
                        -Operation Update
                }
                '8' {
                    Invoke-ResourceOperation `
                        -BundleIds @('all-resources') `
                        -Operation Audit
                }
                '9' {
                    Build-StartHereDashboard `
                        -RepositoryRoot $RootPath `
                        -BookmarksFile $BookmarksPath | Out-Null
                }
                '10' {
                    $dashboard = Join-Path $RootPath '11-RESOURCES\START-HERE.html'
                    if (-not (Test-Path $dashboard)) {
                        $dashboard = Build-StartHereDashboard `
                            -RepositoryRoot $RootPath `
                            -BookmarksFile $BookmarksPath
                    }
                    Start-Process $dashboard
                }
                '0' { return }
                default {
                    Write-Host 'Invalid resource-menu choice.' -ForegroundColor Red
                }
            }
        }
        catch {
            Write-Host ''
            Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
        }

        Write-Host ''
        Read-Host 'Press Enter to continue' | Out-Null
    }
}

function Show-MainMenu {
    Write-Section "USB Swiss Army Knife v$ScriptVersion"
    Write-Host '[1] Initial repository build'
    Write-Host '[2] Update software repository'
    Write-Host '[3] Audit for missing or changed items'
    Write-Host '[4] Provision an individual USB'
    Write-Host '[5] Show USB module profiles'
    Write-Host '[6] Resources and references'
    Write-Host '[7] Open the local repository folder'
    Write-Host '[8] Open START-HERE dashboard'
    Write-Host '[0] Exit'
    Write-Host ''
}

function Invoke-InteractiveMenu {
    New-RepositoryStructure -Path $RootPath

    while ($true) {
        Show-MainMenu
        $choice = Read-Host 'Choose an action'

        try {
            switch ($choice) {
                '1' { Invoke-RepositoryOperation -Operation Initialize }
                '2' { Invoke-RepositoryOperation -Operation Update }
                '3' { Invoke-RepositoryOperation -Operation Audit }
                '4' { Invoke-ProvisionSelection }
                '5' {
                    $profiles = Get-Profiles -Path $ProfilesPath
                    Show-Profiles -Profiles $profiles -RepositoryRoot $RootPath
                }
                '6' { Invoke-ResourceMenu }
                '7' { Start-Process explorer.exe -ArgumentList $RootPath }
                '8' {
                    $dashboard = Join-Path $RootPath '11-RESOURCES\START-HERE.html'
                    if (-not (Test-Path $dashboard)) {
                        $dashboard = Build-StartHereDashboard `
                            -RepositoryRoot $RootPath `
                            -BookmarksFile $BookmarksPath
                    }
                    Start-Process $dashboard
                }
                '0' {
                    Write-Host 'Goodbye.' -ForegroundColor Cyan
                    return
                }
                default {
                    Write-Host 'Invalid menu choice.' -ForegroundColor Red
                }
            }
        }
        catch {
            Write-Host ''
            Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
        }

        Write-Host ''
        Read-Host 'Press Enter to return to the main menu' | Out-Null
    }
}

Write-Section "USB Swiss Army Knife Builder v$ScriptVersion - $Mode"

switch ($Mode) {
    'Menu' { Invoke-InteractiveMenu }
    'Initialize' { Invoke-RepositoryOperation -Operation Initialize }
    'Update' { Invoke-RepositoryOperation -Operation Update }
    'Audit' { Invoke-RepositoryOperation -Operation Audit }
    'Provision' {
        New-RepositoryStructure -Path $RootPath
        Invoke-ProvisionSelection
    }
    default { throw "Unsupported mode: $Mode" }
}
