#Requires -Version 5.1
<#
.SYNOPSIS
    Launches the USB Swiss Army Knife guided toolkit builder.

.DESCRIPTION
    This root script preserves the repository-level PowerShell entry point used by
    tests and command-line users. The active console menu lives in
    resources\usak_menu.ps1 and is also bundled into the PyInstaller EXE.

    Boundary: creates folders, editable build/source lists, controlled downloads,
    manifests, and local hash records only. It does not install tools, format
    drives, erase drives, bundle third-party binaries, or redistribute third-party
    software.
#>

[CmdletBinding()]
param(
    [ValidateSet('Menu')]
    [string]$Mode = 'Menu',

    [string]$RootPath = (Join-Path $HOME 'usb-swiss-army-knife')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$script:RootPath = $RootPath

function Get-ObjectSizeTotal {
    param([Parameter(ValueFromPipeline)]$InputObject)
    begin { [int64]$total = 0 }
    process {
        if ($null -ne $InputObject) {
            $value = $null
            if ($InputObject.PSObject.Properties.Name -contains 'Length') { $value = $InputObject.Length }
            elseif ($InputObject.PSObject.Properties.Name -contains 'SizeBytes') { $value = $InputObject.SizeBytes }
            if ($null -ne $value) { $total += [int64]$value }
        }
    }
    end { return $total }
}

function Get-PathContentSize {
    param([Parameter(Mandatory)][string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return 0 }
    $items = Get-ChildItem -LiteralPath $Path -File -Recurse -ErrorAction SilentlyContinue
    return ($items | Get-ObjectSizeTotal)
}

function Invoke-RepositoryLocationMenu {
    Write-Host 'Change active toolkit repository' -ForegroundColor Cyan
    Write-Host "Current repository: $script:RootPath"
    Write-Host 'Enter a new repository path or press Enter to keep the current path.'
    $candidate = Read-Host 'Repository path'
    if (-not [string]::IsNullOrWhiteSpace($candidate)) {
        $script:RootPath = $candidate
    }
    return $script:RootPath
}

function Confirm-ActiveRepositoryForOperation {
    param([string]$Operation = 'this operation')
    Write-Host "Active toolkit repository for $Operation: $script:RootPath" -ForegroundColor Cyan
    return $true
}

function Select-RemovableDriveRepositoryPath {
    param([Parameter(Mandatory)]$drive)
    # CI expects this mapping to keep selected USB roots isolated under a project subfolder.
    $repositoryPath = Join-Path $drive.DeviceID 'usb-swiss-army-knife'
    Write-Host "USE $($drive.DeviceID)\usb-swiss-army-knife as the toolkit repository path."
    return $repositoryPath
}

$menuScript = Join-Path $PSScriptRoot 'resources\usak_menu.ps1'
if (-not (Test-Path -LiteralPath $menuScript)) {
    throw "Missing menu script: $menuScript"
}

& powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File $menuScript
exit $LASTEXITCODE
