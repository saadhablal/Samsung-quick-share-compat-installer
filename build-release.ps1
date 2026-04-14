[CmdletBinding()]
param(
    [string]$Version = '0.1.0'
)

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$distDir = Join-Path $repoRoot 'dist'
$archiveName = "Samsung-quick-share-compat-installer-$Version.zip"
$archivePath = Join-Path $distDir $archiveName
$stagingDir = Join-Path $distDir "staging-$Version"

if (Test-Path $stagingDir) {
    Remove-Item -LiteralPath $stagingDir -Recurse -Force
}

New-Item -ItemType Directory -Path $stagingDir -Force | Out-Null
New-Item -ItemType Directory -Path $distDir -Force | Out-Null

$itemsToCopy = @(
    'install.bat',
    'uninstall.bat',
    'README.md',
    'LICENSE',
    'src'
)

foreach ($item in $itemsToCopy) {
    Copy-Item -LiteralPath (Join-Path $repoRoot $item) -Destination $stagingDir -Recurse -Force
}

if (Test-Path $archivePath) {
    Remove-Item -LiteralPath $archivePath -Force
}

Compress-Archive -Path (Join-Path $stagingDir '*') -DestinationPath $archivePath -CompressionLevel Optimal
Remove-Item -LiteralPath $stagingDir -Recurse -Force

Write-Host "Created $archivePath"

