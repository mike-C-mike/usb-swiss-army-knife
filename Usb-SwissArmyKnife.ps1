#Requires -Version 5.1
<#
.SYNOPSIS
    Root launcher for USB Swiss Army Knife.

.DESCRIPTION
    Preserves the repository-level PowerShell entry point used by CI tests and
    command-line users. The active guided menu lives in resources\usak_menu.ps1
    and is bundled into the PyInstaller EXE.

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
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline)]
        [object]$InputObject
    )

    begin {
        [Int64]$total = 0
    }

    process {
        if ($null -eq $InputObject) { return }

        $propertyNames = @($InputObject.PSObject.Properties.Name)
        $value = $null

        if ($propertyNames -contains 'Length') {
            $value = $InputObject.Length
        }
        elseif ($propertyNames -contains 'SizeBytes') {
            $value = $InputObject.SizeBytes
        }

        if ($null -ne $value) {
            $total += [Int64]$value
        }
    }

    end {
        return $total
    }
}

function Get-PathContentSize {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        return 0
    }

    $files = Get-ChildItem -LiteralPath $Path -File -Recurse -ErrorAction SilentlyContinue
    return ($files | Get-ObjectSizeTotal)
}

function Invoke-RepositoryLocationMenu {
    [CmdletBinding()]
    param()

    Write-Host 'Change active toolkit repository' -ForegroundColor Cyan
    Write-Host ('Current repository: {0}' -f $script:RootPath)
    Write-Host 'Enter a new repository path or press Enter to keep the current path.'

    $candidate = Read-Host 'Repository path'
    if (-not [string]::IsNullOrWhiteSpace($candidate)) {
        $script:RootPath = $candidate
    }

    return $script:RootPath
}

function Confirm-ActiveRepositoryForOperation {
    [CmdletBinding()]
    param(
        [string]$Operation = 'this operation'
    )

    Write-Host ('Active toolkit repository for {0}: {1}' -f $Operation, $script:RootPath) -ForegroundColor Cyan
    return $true
}

function Select-RemovableDriveRepositoryPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$drive
    )

    if ($null -eq $drive -or [string]::IsNullOrWhiteSpace([string]$drive.DeviceID)) {
        throw 'Selected drive is missing a DeviceID.'
    }

    # Keep selected removable-drive builds isolated under the project repository folder.
    $repositoryPath = Join-Path $drive.DeviceID 'usb-swiss-army-knife'
    Write-Host ('USE $($drive.DeviceID)\usb-swiss-army-knife as the toolkit repository path.')
    Write-Host ('Resolved target: {0}' -f $repositoryPath)
    return $repositoryPath
}

$menuScript = Join-Path $PSScriptRoot 'resources\usak_menu.ps1'
if (-not (Test-Path -LiteralPath $menuScript)) {
    throw ('Missing menu script: {0}' -f $menuScript)
}

& powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File $menuScript
exit $LASTEXITCODE
