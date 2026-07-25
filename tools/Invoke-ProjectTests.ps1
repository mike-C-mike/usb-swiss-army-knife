#Requires -Version 5.1
[CmdletBinding()]
param(
    [string]$TestPath = (Join-Path (Split-Path -Parent $PSScriptRoot) 'tests')
)

$ErrorActionPreference = 'Stop'

$available = Get-Module -ListAvailable Pester |
    Where-Object Version -ge ([version]'5.5.0') |
    Sort-Object Version -Descending |
    Select-Object -First 1

if (-not $available) {
    Write-Host 'Pester 5.5.0 or newer is required.' -ForegroundColor Yellow
    Write-Host ''
    Write-Host 'Install it for your user account with:' -ForegroundColor Cyan
    Write-Host 'Install-Module Pester -MinimumVersion 5.5.0 -Scope CurrentUser -Force -SkipPublisherCheck'
    exit 2
}

Import-Module Pester -RequiredVersion $available.Version -Force

$config = New-PesterConfiguration
$config.Run.Path = $TestPath
$config.Run.PassThru = $true
$config.Output.Verbosity = 'Detailed'

$result = Invoke-Pester -Configuration $config

if ($result.FailedCount -gt 0) {
    exit 1
}
