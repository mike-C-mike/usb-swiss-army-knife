#Requires -Version 5.1
[CmdletBinding()]
param(
    [string]$ToolkitRoot = (Join-Path $HOME 'usb-swiss-army-knife'),
    [string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = 'Stop'
$exportsRoot = Join-Path $ToolkitRoot '00-ADMIN\support-bundles'
New-Item -ItemType Directory -Path $exportsRoot -Force | Out-Null

$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$staging = Join-Path $exportsRoot "support-$timestamp"
$zipPath = Join-Path $exportsRoot "usb-swiss-army-knife-support-$timestamp.zip"

New-Item -ItemType Directory -Path (Join-Path $staging 'config') -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $staging 'logs') -Force | Out-Null

foreach ($name in @('catalog.json','profiles.json','bookmarks.json','build-presets.json')) {
    $source = Join-Path $ProjectRoot "config\$name"
    if (Test-Path $source) {
        Copy-Item $source (Join-Path $staging "config\$name") -Force
    }
}

$logRoot = Join-Path $ToolkitRoot '00-ADMIN\logs'
if (Test-Path $logRoot) {
    Get-ChildItem $logRoot -File -Filter '*.log' |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 3 |
        Copy-Item -Destination (Join-Path $staging 'logs') -Force
}

$inventory = Join-Path $ToolkitRoot '00-ADMIN\inventory\inventory.json'
if (Test-Path $inventory) {
    Copy-Item $inventory (Join-Path $staging 'inventory.json') -Force
}

[pscustomobject]@{
    GeneratedUtc = (Get-Date).ToUniversalTime().ToString('o')
    PowerShellVersion = $PSVersionTable.PSVersion.ToString()
    PowerShellEdition = if ($PSVersionTable.PSEdition) { $PSVersionTable.PSEdition } else { 'Desktop' }
    ExecutionPolicyProcess = [string](Get-ExecutionPolicy -Scope Process)
    ExecutionPolicyCurrentUser = [string](Get-ExecutionPolicy -Scope CurrentUser)
    ExecutionPolicyLocalMachine = [string](Get-ExecutionPolicy -Scope LocalMachine)
    ComputerName = $env:COMPUTERNAME
    UserProfile = $HOME
} | ConvertTo-Json |
    Set-Content (Join-Path $staging 'environment.json') -Encoding UTF8

@"
This support bundle contains configuration, environment metadata, inventory,
and recent logs only. It excludes downloaded software and third-party content.

Review the files before sharing. Logs may contain local paths.
"@ | Set-Content (Join-Path $staging 'README.txt') -Encoding UTF8

Compress-Archive -Path (Join-Path $staging '*') -DestinationPath $zipPath -Force
Remove-Item $staging -Recurse -Force

Write-Host "Support bundle created: $zipPath" -ForegroundColor Green
