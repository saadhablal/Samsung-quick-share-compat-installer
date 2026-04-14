[CmdletBinding()]
param(
    [switch]$SkipQuickShareInstall,
    [switch]$SkipLaunch,
    [switch]$PauseWhenFinished,
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'QuickShareCompat.Common.ps1')

try {
    Write-Section 'Samsung Quick Share Compat Installer'

    if (-not $DryRun -and -not (Test-IsAdministrator)) {
        Write-Status 'Administrator rights are required. Requesting elevation...' -Level Warning
        Restart-ElevatedScript -ScriptPath $PSCommandPath -OriginalArguments $args
    }

    $profile = Get-CompatibilityProfile
    $state = Get-StatePaths

    Write-Section 'Hardware Check'
    $compatibility = Get-WirelessCompatibility
    Show-WirelessCompatibility -Compatibility $compatibility

    Write-Section 'Quick Share'
    if ($SkipQuickShareInstall) {
        Write-Status 'Skipping Quick Share installation because -SkipQuickShareInstall was used.' -Level Warning
    }
    elseif ($DryRun) {
        Write-Status 'Dry run: Quick Share would be installed from the Microsoft Store if missing.' -Level Info
    }
    else {
        Install-QuickShareFromStore | Out-Null
    }

    Write-Section 'Compatibility Setup'
    if ($DryRun) {
        Write-Status ("Dry run: would back up the current registry values for profile {0} ({1})." -f $profile.Name, $profile.ModelCode) -Level Info
        Write-Status 'Dry run: would apply the Samsung compatibility registry profile.' -Level Info
        Write-Status 'Dry run: would install a startup task so the fix reapplies after reboot.' -Level Info
    }
    else {
        Export-CompatibilityBackup -RegistryEntries $profile.RegistryEntries -BackupPath $state.BackupPath
        Write-GeneratedApplyScript -ApplyScriptPath $state.ApplyScriptPath -RegistryEntries $profile.RegistryEntries
        Write-GeneratedRestoreScript -RestoreScriptPath $state.RestoreScriptPath -BackupPath $state.BackupPath
        Apply-CompatibilityProfile -RegistryEntries $profile.RegistryEntries
        Install-StartupTask -ApplyScriptPath $state.ApplyScriptPath
        Write-InstallMetadata -MetadataPath $state.MetadataPath -ProfileName $profile.Name -ModelCode $profile.ModelCode
        Write-Status ("Applied profile {0} ({1})." -f $profile.Name, $profile.ModelCode) -Level Success
    }

    Write-Section 'Finishing Up'
    if ($DryRun) {
        Write-Status 'Dry run complete.' -Level Success
    }
    else {
        Stop-QuickShareProcesses
        if (-not $SkipLaunch) {
            Start-QuickShareApp
        }
        else {
            Write-Status 'Skipped launching Quick Share because -SkipLaunch was used.' -Level Warning
        }

        Write-Status "Install complete. Uninstall later with uninstall.bat." -Level Success
    }
}
catch {
    Write-Status $_.Exception.Message -Level Error
    exit 1
}
finally {
    Pause-IfRequested -PauseWhenFinished $PauseWhenFinished.IsPresent
}

