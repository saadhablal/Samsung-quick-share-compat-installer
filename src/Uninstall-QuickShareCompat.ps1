[CmdletBinding()]
param(
    [switch]$RemoveQuickShare,
    [switch]$PauseWhenFinished,
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'QuickShareCompat.Common.ps1')

try {
    Write-Section 'Samsung Quick Share Compat Uninstall'

    if (-not $DryRun -and -not (Test-IsAdministrator)) {
        Write-Status 'Administrator rights are required. Requesting elevation...' -Level Warning
        Restart-ElevatedScript -ScriptPath (Get-ScriptInvocationPath -ScriptPath $PSCommandPath -InvocationInfo $MyInvocation) -OriginalArguments (Get-ReinvocationArgumentList -BoundParameters $PSBoundParameters)
    }

    $state = Get-StatePaths

    if ($DryRun) {
        Write-Status 'Dry run: would remove the startup task.' -Level Info
        Write-Status 'Dry run: would restore the original registry values from backup.' -Level Info
        Write-Status 'Dry run: would remove local installer state from ProgramData.' -Level Info
        if ($RemoveQuickShare) {
            Write-Status 'Dry run: would remove the Quick Share app too.' -Level Info
        }
    }
    else {
        Stop-QuickShareProcesses
        Restore-CompatibilityBackup -BackupPath $state.BackupPath
        Remove-StartupTask

        if ($RemoveQuickShare) {
            Remove-QuickShareApp
        }

        if (Test-Path -LiteralPath $state.RootPath) {
            Remove-Item -LiteralPath $state.RootPath -Recurse -Force
        }

        Write-Status 'Uninstall complete.' -Level Success
    }
}
catch {
    Write-Status $_.Exception.Message -Level Error
    exit 1
}
finally {
    Pause-IfRequested -PauseWhenFinished $PauseWhenFinished.IsPresent
}
