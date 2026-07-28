param(
    [string]$Version = "0.1.6"
)

$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ProjectRoot

Write-Host "USB Swiss Army Knife release build v$Version" -ForegroundColor Green

$venv = Join-Path $ProjectRoot ".venv"
if (-not (Test-Path $venv)) {
    python -m venv $venv
}

$python = Join-Path $venv "Scripts\python.exe"
& $python -m pip install --upgrade pip
& $python -m pip install -r requirements-build.txt

if (Test-Path ".\build") { Remove-Item -Recurse -Force ".\build" }
if (Test-Path ".\dist") { Remove-Item -Recurse -Force ".\dist" }

& $python -m PyInstaller .\usb-swiss-army-knife.spec --clean --noconfirm

$ReleaseRoot = Join-Path $ProjectRoot "release"
$ReleaseName = "UsbSwissArmyKnife-v$Version-unsigned"
$ReleaseDir = Join-Path $ReleaseRoot $ReleaseName
if (Test-Path $ReleaseDir) { Remove-Item -Recurse -Force $ReleaseDir }
New-Item -ItemType Directory -Force -Path $ReleaseDir | Out-Null

Copy-Item ".\dist\UsbSwissArmyKnife.exe" -Destination (Join-Path $ReleaseDir "UsbSwissArmyKnife.exe")
$docs = @(
    "README.md",
    "DEPENDENCIES.md",
    "LICENSE",
    "UNSIGNED_WINDOWS_NOTICE.md",
    "KNOWN_LIMITATIONS.md",
    "SIMPLE_WORKFLOW.md",
    "RELEASE_NOTES_v0.1.6.md",
    "GITHUB_RELEASE_DRAFT.md",
    "RELEASE_CHECKLIST.md",
    "RUN_DEBUG_FROM_POWERSHELL.md"
)
foreach ($doc in $docs) {
    if (Test-Path $doc) { Copy-Item $doc -Destination $ReleaseDir }
}

$ChecksumPath = Join-Path $ReleaseDir "$ReleaseName-SHA256SUMS.txt"
Get-ChildItem -Path $ReleaseDir -File | Where-Object { $_.Name -ne (Split-Path $ChecksumPath -Leaf) } | ForEach-Object {
    $hash = Get-FileHash -Algorithm SHA256 -Path $_.FullName
    "$($hash.Hash)  $($_.Name)"
} | Set-Content -Path $ChecksumPath -Encoding ASCII

$ZipPath = Join-Path $ReleaseRoot "$ReleaseName.zip"
if (Test-Path $ZipPath) { Remove-Item -Force $ZipPath }
Compress-Archive -Path (Join-Path $ReleaseDir "*") -DestinationPath $ZipPath
$ZipHash = Get-FileHash -Algorithm SHA256 -Path $ZipPath
"$($ZipHash.Hash)  $(Split-Path $ZipPath -Leaf)" | Set-Content -Path "$ZipPath.sha256.txt" -Encoding ASCII

Write-Host "Release folder: $ReleaseDir" -ForegroundColor Green
Write-Host "Release ZIP:    $ZipPath" -ForegroundColor Green
Write-Host "ZIP checksum:   $ZipPath.sha256.txt" -ForegroundColor Green
