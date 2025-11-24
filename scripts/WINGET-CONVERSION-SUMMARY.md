# WinGet Conversion Summary

## Script: SouliTEK-Softwares-Installer.ps1 (formerly SouliTEK-WinGet-Installer.ps1, originally SouliTEK-Choco-Installer.ps1)

### Changes Made

#### 1. Package Manager Switch
- **From:** Chocolatey (`choco.exe`)
- **To:** WinGet (`winget.exe`)

#### 2. Updated Application Catalog
Replaced 40+ applications with 15 essential business apps:

| Application | WinGet ID | Category | Notes |
|------------|-----------|----------|-------|
| NAPS2 | `NAPS2.NAPS2` | Utilities | Document scanning |
| HP Smart | `9WZDNCRFHWLH` | Utilities | HP printer management (Microsoft Store) |
| Adobe Reader | `Adobe.Acrobat.Reader.64-bit` | Utilities | PDF reader |
| Forticlient VPN | `Fortinet.FortiClientVPN` | Security | Enterprise VPN |
| Dropbox | `Dropbox.Dropbox` | Productivity | Cloud storage |
| Zoom | `Zoom.Zoom` | Communications | Video conferencing |
| Microsoft Office 2024 | `OFFICE2024` | Productivity | Office suite (special download) |
| Discord | `Discord.Discord` | Communications | Voice, video, and text chat |
| Google Chrome | `Google.Chrome` | Browsers | Fast, secure browser |
| Google Drive | `Google.Drive` | Productivity | Cloud storage by Google |
| AnyDesk | `AnyDeskSoftwareGmbH.AnyDesk` | Remote Access | Fast remote desktop |
| WinRAR | `RARLab.WinRAR` | Utilities | File compression tool |
| WhatsApp | `WhatsApp.WhatsApp` | Communications | Messaging and calls |
| qBittorrent | `qBittorrent.qBittorrent` | Utilities | BitTorrent client |
| Telegram | `Telegram.TelegramDesktop` | Communications | Secure messaging |

#### 3. Simplified Interface
- Removed category filtering
- Removed text filtering
- Removed preset save functionality (kept load for backwards compatibility)
- Simplified controls to: Navigate, Toggle, Select All/None, Install, Quit
- Shows all 15 apps in grid layout (2 columns)

#### 4. WinGet Installation Logic
Standard apps install using:
```powershell
winget install -e --id <PackageId> --silent --accept-package-agreements --accept-source-agreements
```

#### 5. Special Office 2024 Handling
- Downloads from: `https://c2rsetup.officeapps.live.com/c2r/download.aspx?ProductreleaseID=ProPlus2024Retail&platform=x64&language=he-il&version=O16GA`
- Automatically executes installer
- Tracks installation progress
- Handles reboot requirements

#### 6. Updated Functions
- `Ensure-Choco` → `Ensure-WinGet`
  - Checks for winget.exe
  - Falls back to installing Microsoft.WinGet.Client module if missing
- `Test-PackageInstalled` → Updated for WinGet package detection
- `Install-Office2024` → New function for Office installation
- `Install-Packages` → Rewritten to use WinGet commands

#### 7. Removed Parameters
- `-Category` - No longer needed with 7 apps
- `-Force` - WinGet handles this differently
- `-Source` - Using default WinGet sources
- `-Pre` - Not applicable
- `-WhatIf` - Removed for simplicity

#### 8. Updated Paths and Branding
- Log folder: `$env:ProgramData\SouliTEK\WinGetInstaller\Logs`
- Summary file: `SouliTEK-Softwares-Installer-Result.json`
- Window title: "SOULITEK SOFTWARES INSTALLER"
- Banner: "Softwares Installer"

### Testing Requirements

To test the script:
1. Run PowerShell as Administrator
2. Execute: `.\SouliTEK-Softwares-Installer.ps1`
3. Verify WinGet is detected or installed
4. Test interactive menu navigation with 15 apps in 2-column grid
5. Select packages and install
6. Verify Office 2024 special handling works
7. Check verbose installation progress indicators
8. Verify summary JSON output on desktop

### Recent Updates
- **File renamed** from `SouliTEK-Choco-Installer.ps1` to `SouliTEK-WinGet-Installer.ps1` (later renamed to `SouliTEK-Softwares-Installer.ps1`)
- **Transcript logging removed** - No longer creates log files in ProgramData
- **Banner simplified** - Removed "Ninite-like UX" tagline
- **Verbose installation progress** - Shows percentage progress (0%, 25%, 50%, 75%, 90%, 100%) during app installations
- **Office installation progress** - Detailed progress indicators for Office 2024 download and installation
- **Expanded app catalog** - Added 8 more applications (Discord, Chrome, Google Drive, AnyDesk, WinRAR, WhatsApp, qBittorrent, Telegram) bringing total to 15 apps

### Notes
- WinGet requires Windows 10 1709+ or manual installation via Microsoft Store
- Office installation downloads ~3GB and takes 10-15 minutes
- All standard apps install silently without user interaction
- Progress indicators provide better user feedback during installations
- Summary JSON still saved to desktop for installation tracking

