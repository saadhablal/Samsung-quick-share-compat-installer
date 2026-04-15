$repoRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $repoRoot 'src\QuickShareCompat.Common.ps1')

Describe 'QuickShareCompat.Common' {
    Context 'Get-ReinvocationArgumentList' {
        It 'preserves named switches, scalars, and arrays for elevation relaunch' {
            $boundParameters = [ordered]@{
                SkipLaunch = [System.Management.Automation.SwitchParameter]::Present
                PauseWhenFinished = [System.Management.Automation.SwitchParameter]::Present
                Mode = 'Install'
                Tags = @('alpha', 'beta')
            }

            $arguments = Get-ReinvocationArgumentList -BoundParameters $boundParameters

            $arguments | Should Be @(
                '-SkipLaunch',
                '-PauseWhenFinished',
                '-Mode',
                'Install',
                '-Tags',
                'alpha',
                'beta'
            )
        }
    }

    Context 'Get-CompatibilityProfile' {
        It 'returns the expected default Samsung profile' {
            $profile = Get-CompatibilityProfile

            $profile.Name | Should Be 'Galaxy Book4 Ultra'
            $profile.ModelCode | Should Be '960XGL'
            @($profile.RegistryEntries).Count | Should Be 30
            ($profile.RegistryEntries | Where-Object { $_.Name -eq 'SystemProductName' -and $_.Value -eq '960XGL' }).Count | Should BeGreaterThan 0
        }
    }

    Context 'registry backup and restore' {
        BeforeEach {
            $script:testKey = "HKCU:\Software\SamsungQuickShareCompatInstallerTests\$([guid]::NewGuid().Guid)"
            $script:testDir = Join-Path $env:TEMP ("QuickShareCompatTests-{0}" -f ([guid]::NewGuid().Guid))
            $script:backupPath = Join-Path $script:testDir 'backup.json'
            $script:applyScriptPath = Join-Path $script:testDir 'Apply-Generated.ps1'
            $script:restoreScriptPath = Join-Path $script:testDir 'Restore-Generated.ps1'

            New-Item -Path $script:testKey -Force | Out-Null
            New-Item -ItemType Directory -Path $script:testDir -Force | Out-Null

            Set-RegistryValue -Path $script:testKey -Name 'SystemProductName' -Type 'String' -Value 'LENOVO'
            Set-RegistryValue -Path $script:testKey -Name 'InstallCount' -Type 'DWord' -Value 7

            $script:testEntries = @(
                @{ Path = $script:testKey; Name = 'SystemProductName'; Type = 'String'; Value = '960XGL' }
                @{ Path = $script:testKey; Name = 'InstallCount'; Type = 'DWord'; Value = 99 }
                @{ Path = $script:testKey; Name = 'CreatedByInstaller'; Type = 'String'; Value = 'True' }
            )
        }

        AfterEach {
            if (Test-Path -LiteralPath $script:testKey) {
                Remove-Item -LiteralPath $script:testKey -Recurse -Force
            }

            if (Test-Path -LiteralPath $script:testDir) {
                Remove-Item -LiteralPath $script:testDir -Recurse -Force
            }
        }

        It 'backs up existing values and restores them after changes' {
            Export-CompatibilityBackup -RegistryEntries $script:testEntries -BackupPath $script:backupPath
            Apply-CompatibilityProfile -RegistryEntries $script:testEntries

            (Get-ItemProperty -Path $script:testKey -Name 'SystemProductName').SystemProductName | Should Be '960XGL'
            (Get-ItemProperty -Path $script:testKey -Name 'InstallCount').InstallCount | Should Be 99
            (Get-ItemProperty -Path $script:testKey -Name 'CreatedByInstaller').CreatedByInstaller | Should Be 'True'

            Restore-CompatibilityBackup -BackupPath $script:backupPath

            (Get-ItemProperty -Path $script:testKey -Name 'SystemProductName').SystemProductName | Should Be 'LENOVO'
            (Get-ItemProperty -Path $script:testKey -Name 'InstallCount').InstallCount | Should Be 7
            (Test-RegistryValueExists -Path $script:testKey -Name 'CreatedByInstaller') | Should Be $false
        }

        It 'generates apply and restore scripts that replay the same registry operations' {
            Export-CompatibilityBackup -RegistryEntries $script:testEntries -BackupPath $script:backupPath
            Write-GeneratedApplyScript -ApplyScriptPath $script:applyScriptPath -RegistryEntries $script:testEntries
            Write-GeneratedRestoreScript -RestoreScriptPath $script:restoreScriptPath -BackupPath $script:backupPath

            & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $script:applyScriptPath
            $LASTEXITCODE | Should Be 0

            (Get-ItemProperty -Path $script:testKey -Name 'SystemProductName').SystemProductName | Should Be '960XGL'
            (Get-ItemProperty -Path $script:testKey -Name 'InstallCount').InstallCount | Should Be 99
            (Get-ItemProperty -Path $script:testKey -Name 'CreatedByInstaller').CreatedByInstaller | Should Be 'True'

            & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $script:restoreScriptPath
            $LASTEXITCODE | Should Be 0

            (Get-ItemProperty -Path $script:testKey -Name 'SystemProductName').SystemProductName | Should Be 'LENOVO'
            (Get-ItemProperty -Path $script:testKey -Name 'InstallCount').InstallCount | Should Be 7
            (Test-RegistryValueExists -Path $script:testKey -Name 'CreatedByInstaller') | Should Be $false
        }
    }
}
