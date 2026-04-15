# Samsung Quick Share Compat Installer

Unofficial community installer for getting Samsung Quick Share running on non-Samsung Windows PCs.

This project is designed for fresh machines too:

- installs Samsung Quick Share from the Microsoft Store if it is missing
- applies the Samsung Galaxy Book compatibility registry profile
- backs up the original registry values before changing anything
- installs a startup task so the compatibility fix survives reboots
- includes a clean uninstall path

## What This Is

Samsung Quick Share checks for Samsung Galaxy Book style system information before it runs. This installer applies a compatible Samsung profile so Quick Share can launch on supported Windows hardware.

The default profile used here is:

- `Galaxy Book4 Ultra`
- model code `960XGL`

## What This Is Not

- not an official Samsung tool
- not affiliated with Samsung or Google
- not a guaranteed fix for unsupported Wi-Fi or Bluetooth chipsets

## Requirements

- Windows 10 or Windows 11
- Administrator access
- Internet connection
- `winget` available on the system
- Intel Wi-Fi and Intel Bluetooth strongly recommended for the best results

## Quick Start

1. Download the latest release zip.
2. Extract it anywhere.
3. Double-click `install.bat`.
4. Approve the Administrator prompt.
5. Let the installer finish and launch Quick Share.

## Uninstall

1. Open the extracted folder again.
2. Double-click `uninstall.bat`.
3. Approve the Administrator prompt.

That removes:

- the compatibility registry override
- the startup task
- the local installer state under `C:\ProgramData\SamsungQuickShareCompatInstaller`

By default it keeps the Quick Share app installed. If you want to remove the app too, run:

```powershell
powershell -ExecutionPolicy Bypass -File .\src\Uninstall-QuickShareCompat.ps1 -RemoveQuickShare
```

## Files

- `install.bat`: easiest one-click install entrypoint
- `uninstall.bat`: easiest one-click uninstall entrypoint
- `src\Install-QuickShareCompat.ps1`: main installer
- `src\Uninstall-QuickShareCompat.ps1`: main uninstaller
- `build-release.ps1`: creates a portable release zip in `dist`

## Build A Release Zip

```powershell
powershell -ExecutionPolicy Bypass -File .\build-release.ps1 -Version 0.1.0
```

## Run Regression Tests

```powershell
powershell -ExecutionPolicy Bypass -File .\tests\Run-Regression.ps1
```

That covers:

- PowerShell syntax parsing
- Pester unit tests
- installer dry-run
- uninstaller dry-run
- release zip creation

## Optional Live App Test

This is not part of CI because it changes the local Quick Share app installation.

```powershell
powershell -ExecutionPolicy Bypass -File .\tests\Run-LiveAppLifecycle.ps1 -ReinstallQuickShare
```

That script:

- removes Quick Share
- reinstalls it from the Microsoft Store through the repo helper
- verifies the package is present again
- launches the app

## Notes

- if Quick Share is already installed, the installer keeps it and only applies the compatibility setup
- if the machine does not have Intel wireless hardware, Quick Share may still fail even after the compatibility fix
- the installer preserves the original registry values so uninstall can restore them later

## Disclaimer

Use this at your own risk. This project modifies system registry values that Samsung software uses for compatibility checks.
