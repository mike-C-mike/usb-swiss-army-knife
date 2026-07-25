#Requires -Version 5.1
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

Write-Host 'USB Swiss Army Knife - Development Environment Setup' -ForegroundColor Cyan
Write-Host ''
Write-Host 'This script prepares NuGet, PSGallery, and Pester for local testing.'
Write-Host 'It does not change LocalMachine execution policy.'
Write-Host ''

$confirmation = Read-Host 'Type SETUP DEV to continue'
if ($confirmation -cne 'SETUP DEV') {
    Write-Host 'Setup cancelled.' -ForegroundColor Yellow
    exit 0
}

[Net.ServicePointManager]::SecurityProtocol = `
    [Net.ServicePointManager]::SecurityProtocol -bor `
    [Net.SecurityProtocolType]::Tls12

$nuget = Get-PackageProvider -Name NuGet -ListAvailable -ErrorAction SilentlyContinue |
    Sort-Object Version -Descending |
    Select-Object -First 1

if (-not $nuget -or $nuget.Version -lt [version]'2.8.5.201') {
    Install-PackageProvider `
        -Name NuGet `
        -MinimumVersion 2.8.5.201 `
        -Scope CurrentUser `
        -Force | Out-Null
}

$gallery = Get-PSRepository -Name PSGallery -ErrorAction SilentlyContinue
if (-not $gallery) {
    Register-PSRepository -Default
    $gallery = Get-PSRepository -Name PSGallery -ErrorAction Stop
}

if ($gallery.InstallationPolicy -ne 'Trusted') {
    Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
}

$pester = Get-Module -ListAvailable Pester |
    Where-Object Version -ge [version]'5.5.0' |
    Sort-Object Version -Descending |
    Select-Object -First 1

if (-not $pester) {
    Install-Module `
        -Name Pester `
        -MinimumVersion 5.5.0 `
        -Repository PSGallery `
        -Scope CurrentUser `
        -Force `
        -SkipPublisherCheck
}

Write-Host ''
Write-Host 'Development prerequisites are ready.' -ForegroundColor Green
Get-Module -ListAvailable Pester |
    Sort-Object Version -Descending |
    Select-Object -First 3 Name, Version, Path
