[CmdletBinding()]
param(
    [switch]$ReinstallQuickShare,
    [switch]$SkipLaunch
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $repoRoot 'src\QuickShareCompat.Common.ps1')

Write-Section 'Live Quick Share App Lifecycle'

if ($ReinstallQuickShare) {
    Write-Status 'Removing existing Quick Share package...' -Level Info
    Stop-QuickShareProcesses
    Remove-QuickShareApp

    Start-Sleep -Seconds 5
    if (Get-QuickSharePackage) {
        throw 'Quick Share is still installed after Remove-QuickShareApp.'
    }

    Write-Status 'Reinstalling Quick Share from the Microsoft Store...' -Level Info
    Install-QuickShareFromStore | Out-Null
}

$package = Get-QuickSharePackage
if (-not $package) {
    throw 'Quick Share is not installed.'
}

Write-Status "Quick Share package present: $($package.PackageFullName)" -Level Success

if (-not $SkipLaunch) {
    Start-QuickShareApp
}

Write-Status 'Live app lifecycle passed.' -Level Success

