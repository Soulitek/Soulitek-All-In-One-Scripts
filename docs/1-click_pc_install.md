# 1-Click PC Install Tool

## Overview

The **1-Click PC Install Tool** is a comprehensive PC setup automation script that performs all essential configuration tasks for new Windows installations. This tool is designed for IT professionals and technicians who need to quickly set up new computers with standardized settings and software.

## Purpose

Automate the complete PC setup process including:
- System configuration (time zone, regional settings)
- System protection (restore point creation)
- System updates (Windows updates)
- Performance optimization (power plan)
- System cleanup (bloatware removal)
- Essential software installation (Chrome, AnyDesk, Office)
- Detailed installation reporting

## Features

### 🌍 **Regional Configuration**
- **Time Zone:** Automatically sets to Jerusalem (Israel Standard Time)
- **Regional Format:** Configures for Hebrew (Israel)
- **Geographic Location:** Sets to Israel
- **System Locale:** Hebrew (Israel)
- **Language Preferences:** Adds Hebrew to user language list

### 🔄 **System Updates**
- Installs PSWindowsUpdate module if needed
- Scans for all available Windows updates
- Installs updates automatically
- Reports update count and status
- No automatic restart (user control)

### ⚡ **Performance Optimization**
- Sets power plan to **High Performance**
- Creates High Performance plan if not available
- Supports Ultimate Performance plan (if available)
- Displays active power plan after configuration

### 🗑️ **Bloatware Removal**
Removes unnecessary pre-installed Windows applications:
- 3D Builder, 3D Viewer
- Bing News, Bing Weather
- Get Help, Get Started
- Microsoft Office Hub (pre-installed advertising)
- Solitaire Collection
- Mixed Reality Portal
- Xbox apps and services
- Your Phone
- Zune Music & Video
- And more...

### 📦 **Software Installation**
Installs essential applications via WinGet:
1. **Google Chrome** - Web browser
2. **AnyDesk** - Remote desktop software
3. **Microsoft Office** - Office suite (checks for existing installation)

### 🛡️ **System Protection**
- Creates system restore point before making changes
- Enables System Restore if disabled
- Timestamp in restore point description

### 📊 **Detailed Summary**
- Real-time progress display
- Success/Warning/Error tracking
- Detailed task log with timestamps
- Summary saved to desktop as text file
- Duration tracking

## Requirements

### System Requirements
- **OS:** Windows 10 version 1709 or later, Windows 11
- **PowerShell:** Version 5.1 or higher
- **Privileges:** Administrator rights (mandatory)
- **Internet:** Active connection required for updates and software

### Prerequisites
- Administrator account access
- Active internet connection
- At least 5GB free disk space (for updates and software)
- Enabled System Restore (script will attempt to enable if disabled)

## Usage

### Running the Script

#### Method 1: Right-Click Execution (Recommended)
1. Right-click on `1-click_pc_install.ps1`
2. Select **"Run with PowerShell as administrator"**
3. Review the task list displayed
4. Type `Y` and press Enter to approve and start

#### Method 2: PowerShell Command Line
```powershell
# Navigate to scripts directory
cd C:\Path\To\Soulitek-AIO\scripts

# Run the script
.\1-click_pc_install.ps1
```

### Interactive Process

#### Step 1: Task Overview
The script displays all tasks that will be performed:
```
[1]  Set Time Zone
     └─ Configure time zone to Jerusalem (Israel Standard Time)

[2]  Configure Regional Settings
     └─ Set regional format, location, and language to Israel/Hebrew

[3]  Create System Restore Point
     └─ Create a backup point before making system changes

... (and more)
```

#### Step 2: User Approval
```
Do you want to proceed with the 1-Click PC Install?

[Y] Yes - Start the installation
[N] No  - Cancel and exit

Enter your choice: _
```

#### Step 3: Automated Execution
The script executes all tasks automatically with real-time progress display:
```
[12:34:56] [*] Configuring time zone to Jerusalem...
[12:34:57] [+] Time zone set to: Israel Standard Time

[12:34:59] [*] Setting regional format to Israel...
[12:35:02] [+] Regional settings configured for Israel
```

#### Step 4: Installation Summary
At the end, a detailed summary is displayed and saved to desktop:
```
============================================================
INSTALLATION SUMMARY
============================================================

Installation completed at: 2025-11-22 13:45:30
Total duration: 45.67 minutes

RESULTS SUMMARY
  Successful: 8 task(s)
  Warnings: 1 task(s)
  Errors: 0 task(s)

DETAILED TASK LOG
[12:34:56] [+] Set Time Zone
      └─ Changed to Israel Standard Time

... (complete log)
```

## Task Details

### 1. Set Time Zone
- **Duration:** ~2 seconds
- **Action:** Sets time zone to "Israel Standard Time"
- **Impact:** System clock adjusts to Jerusalem time
- **Restart Required:** No

### 2. Configure Regional Settings
- **Duration:** ~5 seconds
- **Actions:**
  - Sets culture to Hebrew (he-IL)
  - Sets geographic location to Israel (GeoId: 117)
  - Sets system locale to Hebrew
  - Adds Hebrew to language preferences
- **Impact:** Date/time formats, currency, number formatting
- **Restart Required:** Recommended for full effect

### 3. Create System Restore Point
- **Duration:** ~5-10 seconds
- **Action:** Creates restore point with timestamp
- **Description:** "1-Click PC Install - Before Setup (yyyy-MM-dd HH:mm)"
- **Impact:** Allows rollback if issues occur
- **Note:** May fail if System Restore is disabled

### 4. Check and Install Windows Updates
- **Duration:** 10-30 minutes (varies by update count)
- **Actions:**
  - Installs PSWindowsUpdate module if needed
  - Scans for all available updates
  - Installs updates automatically
- **Impact:** System security and stability improvements
- **Restart Required:** Possibly (script does not auto-restart)

### 5. Configure Power Plan
- **Duration:** ~2 seconds
- **Action:** Sets to High Performance power plan
- **Impact:** Maximum system performance (higher power usage)
- **Options:** Supports High Performance or Ultimate Performance

### 6. Remove Bloatware
- **Duration:** ~2-5 minutes
- **Action:** Removes 25+ pre-installed Windows apps
- **Impact:** Frees disk space, reduces clutter
- **Safety:** Only removes non-essential apps

### 7-9. Install Applications
- **Duration:** 5-15 minutes per app
- **Applications:**
  - **Google Chrome:** Latest stable version
  - **AnyDesk:** Latest stable version
  - **Microsoft Office:** Checks for existing installation
- **Method:** WinGet package manager
- **Note:** Office may require manual installation

## Configuration

### Customizing Time Zone
To change the time zone, edit the function `Set-TimeZoneToJerusalem`:

```powershell
# Change from:
Set-TimeZone -Id "Israel Standard Time" -ErrorAction Stop

# To your preferred time zone, e.g.:
Set-TimeZone -Id "Eastern Standard Time" -ErrorAction Stop
```

### Customizing Regional Settings
To change regional settings, edit the function `Set-RegionalSettingsToIsrael`:

```powershell
# Change culture from:
Set-Culture -CultureInfo "he-IL" -ErrorAction Stop

# To your preferred culture, e.g.:
Set-Culture -CultureInfo "en-US" -ErrorAction Stop

# Change GeoId from:
Set-WinHomeLocation -GeoId 117 -ErrorAction Stop  # 117 = Israel

# To your preferred location, e.g.:
Set-WinHomeLocation -GeoId 244 -ErrorAction Stop  # 244 = United States
```

### Customizing Applications
To add or remove applications, edit the function `Install-Applications`:

```powershell
# Add new application:
$yourAppResult = Install-WinGetApplication -AppName "Your App" -WinGetId "Publisher.AppId"
Add-LogEntry -Task "Install Your App" -Status $yourAppResult -Details "WinGet ID: Publisher.AppId"

# Find WinGet IDs:
winget search "application name"
```

### Customizing Bloatware List
To modify which apps are removed, edit the `$bloatwareApps` array in `Remove-Bloatware`:

```powershell
$bloatwareApps = @(
    "Microsoft.3DBuilder",
    "Microsoft.BingNews",
    # Add or remove app IDs as needed
)
```

## Troubleshooting

### Administrator Rights Required
**Error:** "This script requires administrator privileges to run."

**Solution:**
1. Right-click the script
2. Select "Run with PowerShell as administrator"
3. Click "Yes" on the UAC prompt

### WinGet Not Available
**Error:** "WinGet is not available. Cannot install applications."

**Solution:**
1. Script attempts auto-installation
2. If that fails, manually install from: https://aka.ms/getwinget
3. Or use Microsoft Store to update "App Installer"

### Windows Updates Fail
**Error:** "Could not install Windows updates"

**Solution:**
1. Check internet connection
2. Try Windows Settings → Update & Security → Windows Update
3. Run Windows Update Troubleshooter
4. Re-run the script after manual updates

### Regional Settings Not Applied
**Error:** Some regional settings don't appear to change

**Solution:**
1. Restart your computer
2. Some regional changes require a full restart
3. Check Settings → Time & Language to verify

### System Restore Point Creation Failed
**Warning:** "Could not create system restore point"

**Solution:**
1. System Restore may be disabled
2. Enable via: System Properties → System Protection
3. Select drive → Configure → Turn on system protection
4. Script continues anyway (not critical)

### Office Installation Failed
**Warning:** "Automatic Office installation failed"

**Solution:**
1. Office installation via WinGet may not always work
2. Install manually from: https://www.office.com/setup
3. Or use your organization's Office deployment method

## Output Files

### Installation Summary
- **Location:** `%USERPROFILE%\Desktop\1-Click-PC-Install-Summary.txt`
- **Format:** Plain text file
- **Contents:**
  - Installation date and duration
  - Results summary (success/warning/error counts)
  - Detailed task log with timestamps
  - Status and details for each task

### Example Summary File
```
============================================================
1-CLICK PC INSTALL - INSTALLATION SUMMARY
============================================================

Installation Date: 2025-11-22 13:45:30
Duration: 45.67 minutes

RESULTS:
- Successful: 8 task(s)
- Warnings: 1 task(s)
- Errors: 0 task(s)

DETAILED LOG:
============================================================

[12:34:56] [SUCCESS] Set Time Zone
  └─ Changed to Israel Standard Time

[12:34:59] [SUCCESS] Regional Settings
  └─ Configured for Israel (Hebrew)

... (complete log)
```

## Best Practices

### Before Running
1. **Backup Important Data** - Though the script creates a restore point
2. **Ensure Stable Internet** - Updates and downloads require good connection
3. **Plug in Laptop** - Process may take an hour, don't run on battery
4. **Close Other Applications** - Reduce conflicts during installation

### After Running
1. **Review Summary** - Check desktop for summary file
2. **Restart Computer** - Recommended to apply all changes
3. **Verify Applications** - Open Chrome, AnyDesk, Office to verify
4. **Test Settings** - Check time zone, regional format, power plan
5. **Run Windows Update Again** - Some updates require multiple passes

### Production Deployment
For deploying to multiple PCs:
1. **Customize Settings** - Edit time zone, regional settings as needed
2. **Test Thoroughly** - Run on test machine first
3. **Document Changes** - Keep track of customizations
4. **Create USB Drive** - Copy entire Soulitek-AIO folder for portability
5. **Train Technicians** - Ensure staff know how to use the tool

## Security Considerations

### Administrator Privileges
- **Required:** Script needs admin rights to make system changes
- **Validation:** Script checks for admin rights before execution
- **UAC Prompt:** User must explicitly approve elevation

### WinGet Package Sources
- **Source:** Microsoft's official WinGet repository
- **Verification:** WinGet verifies package signatures
- **Safety:** All installed software is from official publishers

### System Modifications
- **Restore Point:** Created before any changes
- **Bloatware Only:** Only removes non-essential Windows apps
- **No Data Loss:** Script does not delete user files or documents

### Network Security
- **HTTPS Only:** All downloads use encrypted connections
- **Official Sources:** Updates from Microsoft, apps from official publishers
- **No Telemetry:** Script does not send data anywhere

## Support

### Getting Help
- **Website:** www.soulitek.co.il
- **Email:** letstalk@soulitek.co.il
- **Documentation:** Check `docs/` folder for other tools

### Reporting Issues
When reporting issues, include:
1. Windows version (run `winver`)
2. PowerShell version (run `$PSVersionTable.PSVersion`)
3. Error message (exact text)
4. Installation summary file (from desktop)
5. Steps to reproduce

## Version History

### v1.0.0 (2025-11-22)
- Initial release
- Complete PC setup automation
- 10 integrated tasks
- Detailed logging and summary
- User approval system

## License

Copyright (C) 2025 SouliTEK - All Rights Reserved

This tool is provided "AS IS" without warranty of any kind. Use of this tool is at your own risk. The user is solely responsible for any outcomes, damages, or issues that may arise from using this script.

## Credits

**Developed by:** SouliTEK (www.soulitek.co.il)  
**Category:** System Setup & Configuration  
**Part of:** SouliTEK All-In-One Scripts Collection

