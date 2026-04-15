[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$testVersion = '0.0.0-test'
$releaseZip = Join-Path $repoRoot "dist\Samsung-quick-share-compat-installer-$testVersion.zip"

Write-Host 'Parsing PowerShell files...' -ForegroundColor Cyan
$parseErrors = @()
$scriptFiles = Get-ChildItem -Path $repoRoot -Recurse -File -Filter '*.ps1' | Where-Object {
    $_.FullName -notmatch '\\dist\\' -and $_.FullName -notmatch '\\.git\\'
}

foreach ($file in $scriptFiles) {
    $null = $tokens = $null
    $null = $errors = $null
    [System.Management.Automation.Language.Parser]::ParseFile($file.FullName, [ref]$tokens, [ref]$errors) | Out-Null
    if ($errors.Count -gt 0) {
        $parseErrors += $errors
    }
}

if ($parseErrors.Count -gt 0) {
    $parseErrors | ForEach-Object { Write-Host $_.Message -ForegroundColor Red }
    throw 'PowerShell parser validation failed.'
}

Write-Host 'Running Pester tests...' -ForegroundColor Cyan
$pesterResult = Invoke-Pester -Path (Join-Path $PSScriptRoot 'QuickShareCompat.Tests.ps1') -PassThru
if ($pesterResult.FailedCount -gt 0) {
    throw "Pester reported $($pesterResult.FailedCount) failing test(s)."
}

Write-Host 'Running installer dry-run...' -ForegroundColor Cyan
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $repoRoot 'src\Install-QuickShareCompat.ps1') -DryRun
if ($LASTEXITCODE -ne 0) {
    throw 'Installer dry-run failed.'
}

Write-Host 'Running uninstaller dry-run...' -ForegroundColor Cyan
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $repoRoot 'src\Uninstall-QuickShareCompat.ps1') -DryRun
if ($LASTEXITCODE -ne 0) {
    throw 'Uninstaller dry-run failed.'
}

Write-Host 'Building release zip...' -ForegroundColor Cyan
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $repoRoot 'build-release.ps1') -Version $testVersion
if ($LASTEXITCODE -ne 0) {
    throw 'Release build failed.'
}

if (-not (Test-Path -LiteralPath $releaseZip)) {
    throw "Expected release zip was not created: $releaseZip"
}

Write-Host 'Regression suite passed.' -ForegroundColor Green

