#Requires -Version 5.1
[CmdletBinding()]
param(
    [string]$RepositoryRoot,
    [string]$TestPath
)

$ErrorActionPreference = 'Stop'

function Resolve-SafeFullPath {
    param([Parameter(Mandatory)][string]$PathValue)
    $clean = ($PathValue -replace '^["'']+', '' -replace '["'']+$', '').Trim()
    if ([string]::IsNullOrWhiteSpace($clean)) {
        throw 'Path value resolved to blank.'
    }
    return [System.IO.Path]::GetFullPath($clean)
}

$scriptFile = $PSCommandPath
if ([string]::IsNullOrWhiteSpace($scriptFile)) {
    $scriptFile = $MyInvocation.MyCommand.Path
}
if ([string]::IsNullOrWhiteSpace($scriptFile)) {
    throw 'Unable to resolve Invoke-ProjectTests.ps1 path.'
}

$toolsDir = Split-Path -Parent $scriptFile
if ([string]::IsNullOrWhiteSpace($RepositoryRoot)) {
    $RepositoryRoot = Split-Path -Parent $toolsDir
}
$RepositoryRoot = Resolve-SafeFullPath $RepositoryRoot

if ([string]::IsNullOrWhiteSpace($TestPath)) {
    $TestPath = Join-Path $RepositoryRoot 'tests'
} else {
    $TestPath = Resolve-SafeFullPath $TestPath
}

if (-not (Test-Path -LiteralPath $TestPath)) {
    throw "Test path not found: $TestPath"
}

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
$config.Run.Path = @($TestPath)
$config.Run.PassThru = $true
$config.Output.Verbosity = 'Detailed'

$result = Invoke-Pester -Configuration $config

if ($result.FailedCount -gt 0) {
    exit 1
}
exit 0
