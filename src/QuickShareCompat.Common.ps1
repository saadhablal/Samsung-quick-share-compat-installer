Set-StrictMode -Version Latest

function Write-Status {
    param(
        [string]$Message,
        [ValidateSet('Info', 'Success', 'Warning', 'Error')]
        [string]$Level = 'Info'
    )

    $prefix = switch ($Level) {
        'Success' { '[+]' }
        'Warning' { '[!]' }
        'Error' { '[x]' }
        default { '[i]' }
    }

    $color = switch ($Level) {
        'Success' { 'Green' }
        'Warning' { 'Yellow' }
        'Error' { 'Red' }
        default { 'Cyan' }
    }

    Write-Host "$prefix $Message" -ForegroundColor $color
}

function Write-Section {
    param([string]$Title)

    Write-Host ''
    Write-Host $Title -ForegroundColor White
    Write-Host ('-' * $Title.Length) -ForegroundColor DarkGray
}

function Pause-IfRequested {
    param([bool]$PauseWhenFinished)

    if ($PauseWhenFinished) {
        Write-Host ''
        Read-Host 'Press Enter to close'
    }
}

function Test-IsAdministrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Restart-ElevatedScript {
    param(
        [string]$ScriptPath,
        [string[]]$OriginalArguments
    )

    $psExe = Join-Path $PSHOME 'powershell.exe'
    $argumentList = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $ScriptPath) + $OriginalArguments
    $process = Start-Process -FilePath $psExe -ArgumentList $argumentList -Verb RunAs -Wait -PassThru
    exit $process.ExitCode
}

function Get-ReinvocationArgumentList {
    param([hashtable]$BoundParameters)

    $argumentList = @()
    if (-not $BoundParameters) {
        return $argumentList
    }

    foreach ($key in $BoundParameters.Keys) {
        $value = $BoundParameters[$key]
        if ($value -is [System.Management.Automation.SwitchParameter]) {
            if ($value.IsPresent) {
                $argumentList += "-$key"
            }
            continue
        }

        if ($null -eq $value) {
            continue
        }

        if ($value -is [array]) {
            $argumentList += "-$key"
            $argumentList += @($value | ForEach-Object { [string]$_ })
            continue
        }

        $argumentList += "-$key"
        $argumentList += [string]$value
    }

    return $argumentList
}

function Get-StatePaths {
    $root = Join-Path $env:ProgramData 'SamsungQuickShareCompatInstaller'
    return @{
        RootPath = $root
        BackupPath = Join-Path $root 'registry-backup.json'
        ApplyScriptPath = Join-Path $root 'Apply-QuickShareCompat.ps1'
        RestoreScriptPath = Join-Path $root 'Restore-QuickShareCompat.ps1'
        MetadataPath = Join-Path $root 'install-metadata.json'
    }
}

function Get-QuickSharePackageName {
    return 'SAMSUNGELECTRONICSCoLtd.SamsungQuickShare'
}

function Get-QuickShareStoreId {
    return '9PCTGDFXVZLJ'
}

function Get-StartupTaskName {
    return 'SamsungQuickShareCompatInstaller'
}

function Get-CompatibilityProfile {
    $biosPath = 'HKLM:\HARDWARE\DESCRIPTION\System\BIOS'
    $hardwareConfigPath = 'HKLM:\SYSTEM\HardwareConfig\Current'
    $systemInfoPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\SystemInformation'

    return [ordered]@{
        Name = 'Galaxy Book4 Ultra'
        ModelCode = '960XGL'
        RegistryEntries = @(
            @{ Path = $biosPath; Name = 'BIOSVendor'; Type = 'String'; Value = 'American Megatrends International, LLC.' }
            @{ Path = $biosPath; Name = 'BIOSVersion'; Type = 'String'; Value = 'P08ALX.400.250306.05' }
            @{ Path = $biosPath; Name = 'BiosMajorRelease'; Type = 'DWord'; Value = 5 }
            @{ Path = $biosPath; Name = 'BiosMinorRelease'; Type = 'DWord'; Value = 32 }
            @{ Path = $biosPath; Name = 'BIOSReleaseDate'; Type = 'String'; Value = '03/06/2025' }
            @{ Path = $biosPath; Name = 'SystemManufacturer'; Type = 'String'; Value = 'SAMSUNG ELECTRONICS CO., LTD.' }
            @{ Path = $biosPath; Name = 'SystemFamily'; Type = 'String'; Value = 'Galaxy Book4 Ultra' }
            @{ Path = $biosPath; Name = 'SystemProductName'; Type = 'String'; Value = '960XGL' }
            @{ Path = $biosPath; Name = 'SystemSKU'; Type = 'String'; Value = 'SCAI-PROT-A5A5-MTLH-PALX' }
            @{ Path = $biosPath; Name = 'SystemVersion'; Type = 'String'; Value = 'P08ALX' }
            @{ Path = $biosPath; Name = 'EnclosureType'; Type = 'DWord'; Value = 10 }
            @{ Path = $biosPath; Name = 'BaseBoardManufacturer'; Type = 'String'; Value = 'SAMSUNG ELECTRONICS CO., LTD.' }
            @{ Path = $biosPath; Name = 'BaseBoardProduct'; Type = 'String'; Value = 'NP960XGL-XG2BR' }
            @{ Path = $hardwareConfigPath; Name = 'Id'; Type = 'DWord'; Value = 0 }
            @{ Path = $hardwareConfigPath; Name = 'BootDriverFlags'; Type = 'DWord'; Value = 0 }
            @{ Path = $hardwareConfigPath; Name = 'EnclosureType'; Type = 'DWord'; Value = 10 }
            @{ Path = $hardwareConfigPath; Name = 'SystemManufacturer'; Type = 'String'; Value = 'SAMSUNG ELECTRONICS CO., LTD.' }
            @{ Path = $hardwareConfigPath; Name = 'SystemFamily'; Type = 'String'; Value = 'Galaxy Book4 Ultra' }
            @{ Path = $hardwareConfigPath; Name = 'SystemProductName'; Type = 'String'; Value = '960XGL' }
            @{ Path = $hardwareConfigPath; Name = 'SystemSKU'; Type = 'String'; Value = 'SCAI-PROT-A5A5-MTLH-PALX' }
            @{ Path = $hardwareConfigPath; Name = 'SystemVersion'; Type = 'String'; Value = 'P08ALX' }
            @{ Path = $hardwareConfigPath; Name = 'BIOSVendor'; Type = 'String'; Value = 'American Megatrends International, LLC.' }
            @{ Path = $hardwareConfigPath; Name = 'BIOSVersion'; Type = 'String'; Value = 'P08ALX.400.250306.05' }
            @{ Path = $hardwareConfigPath; Name = 'BIOSReleaseDate'; Type = 'String'; Value = '03/06/2025' }
            @{ Path = $hardwareConfigPath; Name = 'BaseBoardManufacturer'; Type = 'String'; Value = 'SAMSUNG ELECTRONICS CO., LTD.' }
            @{ Path = $hardwareConfigPath; Name = 'BaseBoardProduct'; Type = 'String'; Value = 'NP960XGL-XG2BR' }
            @{ Path = $systemInfoPath; Name = 'BIOSVersion'; Type = 'String'; Value = 'P08ALX.400.250306.05' }
            @{ Path = $systemInfoPath; Name = 'BIOSReleaseDate'; Type = 'String'; Value = '03/06/2025' }
            @{ Path = $systemInfoPath; Name = 'SystemManufacturer'; Type = 'String'; Value = 'SAMSUNG ELECTRONICS CO., LTD.' }
            @{ Path = $systemInfoPath; Name = 'SystemProductName'; Type = 'String'; Value = '960XGL' }
        )
    }
}

function Get-RegistryEntrySnapshot {
    param(
        [string]$Path,
        [string]$Name
    )

    $result = [ordered]@{
        Path = $Path
        Name = $Name
        Exists = $false
        Kind = $null
        Value = $null
    }

    try {
        $key = Get-Item -LiteralPath $Path -ErrorAction Stop
        $kind = $key.GetValueKind($Name)
        $value = $key.GetValue($Name, $null)
        $result.Exists = $true
        $result.Kind = $kind.ToString()
        $result.Value = $value
    }
    catch {
    }

    return [pscustomobject]$result
}

function Test-RegistryValueExists {
    param(
        [string]$Path,
        [string]$Name
    )

    try {
        $null = (Get-Item -LiteralPath $Path -ErrorAction Stop).GetValueKind($Name)
        return $true
    }
    catch {
        return $false
    }
}

function Set-RegistryValue {
    param(
        [string]$Path,
        [string]$Name,
        [string]$Type,
        [object]$Value
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        New-Item -Path $Path -Force | Out-Null
    }

    if (Test-RegistryValueExists -Path $Path -Name $Name) {
        Remove-ItemProperty -Path $Path -Name $Name -Force
    }

    New-ItemProperty -Path $Path -Name $Name -PropertyType $Type -Value $Value -Force | Out-Null
}

function Apply-CompatibilityProfile {
    param([object[]]$RegistryEntries)

    foreach ($entry in $RegistryEntries) {
        Set-RegistryValue -Path $entry.Path -Name $entry.Name -Type $entry.Type -Value $entry.Value
    }
}

function Export-CompatibilityBackup {
    param(
        [object[]]$RegistryEntries,
        [string]$BackupPath
    )

    if (Test-Path -LiteralPath $BackupPath) {
        Write-Status "Reusing existing backup: $BackupPath" -Level Info
        return
    }

    $backupRoot = Split-Path -Parent $BackupPath
    New-Item -ItemType Directory -Path $backupRoot -Force | Out-Null

    $backupEntries = foreach ($entry in $RegistryEntries) {
        Get-RegistryEntrySnapshot -Path $entry.Path -Name $entry.Name
    }

    $payload = [ordered]@{
        CreatedAt = (Get-Date).ToString('s')
        Entries = $backupEntries
    }

    $payload | ConvertTo-Json -Depth 6 | Set-Content -Path $BackupPath -Encoding UTF8
    Write-Status "Saved registry backup to $BackupPath" -Level Success
}

function Restore-CompatibilityBackup {
    param([string]$BackupPath)

    if (-not (Test-Path -LiteralPath $BackupPath)) {
        Write-Status "No backup file found. Skipping registry restore." -Level Warning
        return
    }

    $payload = Get-Content -Path $BackupPath -Raw | ConvertFrom-Json
    foreach ($entry in $payload.Entries) {
        if ($entry.Exists) {
            Set-RegistryValue -Path $entry.Path -Name $entry.Name -Type $entry.Kind -Value $entry.Value
        }
        elseif (Test-RegistryValueExists -Path $entry.Path -Name $entry.Name) {
            Remove-ItemProperty -Path $entry.Path -Name $entry.Name -Force
        }
    }

    Write-Status "Restored original registry values." -Level Success
}

function Write-GeneratedApplyScript {
    param(
        [string]$ApplyScriptPath,
        [object[]]$RegistryEntries
    )

    $json = $RegistryEntries | ConvertTo-Json -Depth 5
    $content = @"
`$ErrorActionPreference = 'Stop'
`$entries = @'
$json
'@ | ConvertFrom-Json

function Set-RegistryValue {
    param(
        [string]`$Path,
        [string]`$Name,
        [string]`$Type,
        [object]`$Value
    )

    if (-not (Test-Path -LiteralPath `$Path)) {
        New-Item -Path `$Path -Force | Out-Null
    }

    try {
        Remove-ItemProperty -Path `$Path -Name `$Name -Force -ErrorAction Stop
    }
    catch {
    }

    New-ItemProperty -Path `$Path -Name `$Name -PropertyType `$Type -Value `$Value -Force | Out-Null
}

foreach (`$entry in `$entries) {
    Set-RegistryValue -Path `$entry.Path -Name `$entry.Name -Type `$entry.Type -Value `$entry.Value
}
"@

    New-Item -ItemType Directory -Path (Split-Path -Parent $ApplyScriptPath) -Force | Out-Null
    Set-Content -Path $ApplyScriptPath -Value $content -Encoding UTF8
}

function Write-GeneratedRestoreScript {
    param(
        [string]$RestoreScriptPath,
        [string]$BackupPath
    )

    $taskName = Get-StartupTaskName
    $content = @"
`$ErrorActionPreference = 'Stop'
`$backup = Get-Content -Path '$BackupPath' -Raw | ConvertFrom-Json

function Set-RegistryValue {
    param(
        [string]`$Path,
        [string]`$Name,
        [string]`$Type,
        [object]`$Value
    )

    if (-not (Test-Path -LiteralPath `$Path)) {
        New-Item -Path `$Path -Force | Out-Null
    }

    try {
        Remove-ItemProperty -Path `$Path -Name `$Name -Force -ErrorAction Stop
    }
    catch {
    }

    New-ItemProperty -Path `$Path -Name `$Name -PropertyType `$Type -Value `$Value -Force | Out-Null
}

function Test-RegistryValueExists {
    param(
        [string]`$Path,
        [string]`$Name
    )

    try {
        `$null = (Get-Item -LiteralPath `$Path -ErrorAction Stop).GetValueKind(`$Name)
        return `$true
    }
    catch {
        return `$false
    }
}

foreach (`$entry in `$backup.Entries) {
    if (`$entry.Exists) {
        Set-RegistryValue -Path `$entry.Path -Name `$entry.Name -Type `$entry.Kind -Value `$entry.Value
    }
    elseif (Test-RegistryValueExists -Path `$entry.Path -Name `$entry.Name) {
        Remove-ItemProperty -Path `$entry.Path -Name `$entry.Name -Force
    }
}

try {
    schtasks.exe /Delete /TN "$taskName" /F 2>`$null | Out-Null
}
catch {
}
"@

    New-Item -ItemType Directory -Path (Split-Path -Parent $RestoreScriptPath) -Force | Out-Null
    Set-Content -Path $RestoreScriptPath -Value $content -Encoding UTF8
}

function Write-InstallMetadata {
    param(
        [string]$MetadataPath,
        [string]$ProfileName,
        [string]$ModelCode
    )

    $payload = [ordered]@{
        InstalledAt = (Get-Date).ToString('s')
        ProfileName = $ProfileName
        ModelCode = $ModelCode
    }

    $payload | ConvertTo-Json -Depth 3 | Set-Content -Path $MetadataPath -Encoding UTF8
}

function Install-StartupTask {
    param([string]$ApplyScriptPath)

    $taskName = Get-StartupTaskName
    $powerShellPath = Join-Path $PSHOME 'powershell.exe'
    $taskCommand = ('"{0}" -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "{1}"' -f $powerShellPath, $ApplyScriptPath)

    & schtasks.exe /Create /TN $taskName /SC ONSTART /RU SYSTEM /RL HIGHEST /TR $taskCommand /F | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to create scheduled task '$taskName'."
    }

    & schtasks.exe /Run /TN $taskName | Out-Null
    Write-Status "Installed startup task '$taskName'." -Level Success
}

function Remove-StartupTask {
    $taskName = Get-StartupTaskName
    & schtasks.exe /Query /TN $taskName 2>$null | Out-Null
    if ($LASTEXITCODE -eq 0) {
        & schtasks.exe /Delete /TN $taskName /F 2>$null | Out-Null
    }
}

function Get-QuickSharePackage {
    return Get-AppxPackage -Name (Get-QuickSharePackageName) -ErrorAction SilentlyContinue | Select-Object -First 1
}

function Ensure-WingetAvailable {
    if (Get-Command winget.exe -ErrorAction SilentlyContinue) {
        return
    }

    throw "winget is required to install Quick Share automatically. Install Microsoft App Installer and try again."
}

function Install-QuickShareFromStore {
    param(
        [int]$InstallAttempts = 2,
        [int]$PollAttempts = 36,
        [int]$PollIntervalSeconds = 5
    )

    $existing = Get-QuickSharePackage
    if ($existing) {
        Write-Status "Quick Share is already installed." -Level Success
        return $existing
    }

    Ensure-WingetAvailable

    for ($installAttempt = 1; $installAttempt -le $InstallAttempts; $installAttempt++) {
        Write-Status "Installing Quick Share from the Microsoft Store (attempt $installAttempt of $InstallAttempts)..." -Level Info

        & winget.exe install --id (Get-QuickShareStoreId) --source msstore --accept-source-agreements --accept-package-agreements --silent --disable-interactivity
        if ($LASTEXITCODE -ne 0) {
            throw "winget could not install Quick Share."
        }

        $package = $null
        for ($pollAttempt = 0; $pollAttempt -lt $PollAttempts; $pollAttempt++) {
            Start-Sleep -Seconds $PollIntervalSeconds
            $package = Get-QuickSharePackage
            if ($package) {
                Write-Status "Quick Share installed successfully." -Level Success
                return $package
            }
        }

        if ($installAttempt -lt $InstallAttempts) {
            Write-Status 'Quick Share did not appear yet. Retrying the Store install once more...' -Level Warning
        }
    }

    throw "Quick Share did not appear after installation."
}

function Remove-QuickShareApp {
    $package = Get-QuickSharePackage
    if (-not $package) {
        Write-Status "Quick Share is not installed." -Level Warning
        return
    }

    Remove-AppxPackage -Package $package.PackageFullName
    Write-Status "Removed Quick Share." -Level Success
}

function Stop-QuickShareProcesses {
    $processNames = @('QuickShare', 'SamsungQuickShare')
    foreach ($processName in $processNames) {
        Get-Process -Name $processName -ErrorAction SilentlyContinue | Stop-Process -Force
    }
}

function Start-QuickShareApp {
    $package = Get-QuickSharePackage
    if (-not $package) {
        Write-Status "Quick Share is not installed, so it cannot be launched." -Level Warning
        return
    }

    $appId = "shell:AppsFolder\$($package.PackageFamilyName)!App"
    Start-Process explorer.exe $appId | Out-Null
    Write-Status "Launched Quick Share." -Level Success
}

function Get-WirelessCompatibility {
    $wifiAdapters = @()
    $bluetoothDevices = @()

    if (Get-Command Get-NetAdapter -ErrorAction SilentlyContinue) {
        $wifiAdapters = @(Get-NetAdapter -IncludeHidden -ErrorAction SilentlyContinue | Where-Object {
            $_.InterfaceDescription -match 'Intel' -and $_.InterfaceDescription -match 'Wi-?Fi|Wireless'
        })
    }

    if (Get-Command Get-PnpDevice -ErrorAction SilentlyContinue) {
        $bluetoothDevices = @(Get-PnpDevice -Class Bluetooth -ErrorAction SilentlyContinue | Where-Object {
            $_.FriendlyName -match 'Intel' -or $_.Manufacturer -match 'Intel'
        })
    }

    return [pscustomobject]@{
        HasIntelWiFi = $wifiAdapters.Count -gt 0
        WiFiAdapters = @($wifiAdapters | ForEach-Object { $_.InterfaceDescription })
        HasIntelBluetooth = $bluetoothDevices.Count -gt 0
        BluetoothDevices = @($bluetoothDevices | ForEach-Object { $_.FriendlyName })
    }
}

function Show-WirelessCompatibility {
    param([pscustomobject]$Compatibility)

    if ($Compatibility.HasIntelWiFi) {
        Write-Status ("Intel Wi-Fi detected: {0}" -f ($Compatibility.WiFiAdapters -join '; ')) -Level Success
    }
    else {
        Write-Status 'No Intel Wi-Fi adapter was detected. Quick Share may not work on this machine.' -Level Warning
    }

    if ($Compatibility.HasIntelBluetooth) {
        Write-Status ("Intel Bluetooth detected: {0}" -f ($Compatibility.BluetoothDevices -join '; ')) -Level Success
    }
    else {
        Write-Status 'No Intel Bluetooth adapter was detected. Quick Share may not work on this machine.' -Level Warning
    }
}
