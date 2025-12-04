# Software Updater Tool

## Overview

The Software Updater is a streamlined utility for managing software updates on Windows systems using the official Windows Package Manager (WinGet). Keep your installed applications up to date with automatic or interactive update modes, track update history, and generate comprehensive reports.

## Version

**Current Version:** 1.0.0  
**Release Date:** 2025-11-24  
**Category:** Software / Maintenance

## Features

### 1. Update Checking
- Lists all available software updates
- Shows current vs. available versions
- Displays update sources
- Quick overview of pending updates

### 2. Automatic Updates
- **Silent, non-interactive updates** for all software
- No user prompts or confirmations required
- Uses Microsoft-recommended automation flags:
  - `--silent` - No UI or prompts
  - `--accept-package-agreements` - Auto-accept licenses
  - `--accept-source-agreements` - Auto-accept source terms
  - `--disable-interactivity` - Prevent user prompts
- Progress tracking and duration reporting
- Automatic error handling

### 3. Interactive Updates
- Review each available update
- See detailed package information
- Choose which updates to install
- Full control over the update process
- Approve or skip individual packages

### 4. Update History
- Tracks all update sessions
- Records timestamp, duration, and status
- Shows success/failure for each update
- Maintains last 50 update records
- Display mode (Automatic vs. Interactive)

### 5. Report Generation
- Exports detailed update reports to Desktop
- Includes:
  - Available updates list
  - Update history (last 10 sessions)
  - System information
  - WinGet version
  - Timestamped filename for tracking

## Requirements

### System Requirements
- **Windows Version:** Windows 10 (1809+) or Windows 11
- **PowerShell:** Version 5.1 or higher
- **Administrator Privileges:** Required for software installation

### Required Components
- **WinGet:** Windows Package Manager (required)
  - Pre-installed on Windows 11
  - Pre-installed on Windows 10 version 1809 and later
  - Download from: https://aka.ms/getwinget
  - Or install from Microsoft Store: "App Installer"

## Usage

### Running the Tool

1. **Launch from SouliTEK Launcher** (recommended)
   - Open the SouliTEK Launcher
   - Find "Software Updater" in the Software category
   - Click the tool card to launch

2. **Run directly via PowerShell** (as Administrator):
   ```powershell
   .\scripts\software_updater.ps1
   ```

### Menu Options

#### Option 1: Check for Available Updates
Lists all software that has updates available.
- Shows package names
- Displays current version vs. available version
- Shows update source
- No changes are made to the system

**Use Case:** Regular maintenance checks, review before updating

#### Option 2: Update All Software (Automatic)
Automatically updates all software without user interaction.
- Silent installation (no UI)
- No prompts or confirmations
- Updates all packages with available updates
- Shows progress and duration
- Records results to history

**Use Case:** Automated maintenance, scheduled updates, batch processing

**Command executed:**
```powershell
winget upgrade --all --silent --accept-package-agreements --accept-source-agreements --disable-interactivity
```

#### Option 3: Update Software (Interactive)
Opens WinGet's interactive update interface.
- Shows available updates
- Prompts for confirmation on each package
- Allows selective updates
- Full user control
- Shows detailed information

**Use Case:** Selective updates, testing new versions, careful maintenance

#### Option 4: View Update History
Displays history of previous update sessions.
- Last 20 updates shown
- Timestamp for each session
- Mode (Automatic or Interactive)
- Duration of update process
- Success/failure status
- Exit codes for diagnostics

**Use Case:** Tracking update activity, troubleshooting, reporting

#### Option 5: Export Update Report
Generates a detailed report and saves to Desktop.
- Current available updates
- Update history (last 10 sessions)
- System information
- WinGet version
- Timestamped TXT file

**Filename format:** `SoftwareUpdateReport_COMPUTERNAME_YYYYMMDD_HHMMSS.txt`

**Use Case:** Documentation, compliance reporting, historical tracking

## WinGet Integration

### About WinGet
Windows Package Manager (WinGet) is Microsoft's official command-line package manager for Windows. It provides a standardized way to discover, install, upgrade, remove, and configure applications.

### Official Documentation
- **Microsoft Docs:** [WinGet Upgrade Command](https://learn.microsoft.com/en-us/windows/package-manager/winget/upgrade)
- **WinGet GitHub:** https://github.com/microsoft/winget-cli

### Update Process
When you run automatic updates, the tool executes:

```powershell
winget upgrade --all --silent --accept-package-agreements --accept-source-agreements --disable-interactivity
```

**Flags explained:**
- `--all` : Update all packages with available upgrades
- `--silent` : Run installers in silent mode (no UI)
- `--accept-package-agreements` : Automatically accept package license agreements
- `--accept-source-agreements` : Automatically accept source license agreements
- `--disable-interactivity` : Disable all interactive prompts

### Exit Codes
- **0** : Success - All updates completed
- **-1978335189** : Partial success - Some packages updated, some skipped (often indicates no updates or partial success)
- **Other codes** : Errors or warnings occurred

## Safety Notes

### Automatic Updates
- **Generally Safe:** WinGet uses official package sources
- **Silent Installation:** May skip optional features or customization
- **Restart Requirements:** Some updates may require system restart
- **Network Required:** Active internet connection needed

### Best Practices

1. **Before Running Updates:**
   - Check available updates first (Option 1)
   - Ensure stable internet connection
   - Save all open work
   - Create system restore point if desired
   - Close critical applications

2. **During Updates:**
   - Allow process to complete uninterrupted
   - Don't force close the window
   - Monitor for any restart prompts
   - Note any errors for troubleshooting

3. **After Updates:**
   - Review update history (Option 4)
   - Check that applications work correctly
   - Restart system if prompted
   - Export report for records (Option 5)

4. **Regular Maintenance:**
   - Check for updates weekly
   - Run automatic updates monthly
   - Review update history regularly
   - Export reports for documentation

### Recommendations
- **Test first:** Try interactive mode before using automatic mode
- **Schedule wisely:** Run updates during low-activity periods
- **Stay informed:** Review what will be updated before proceeding
- **Keep records:** Export reports periodically for tracking

## Troubleshooting

### WinGet Not Available
**Problem:** Tool reports "WinGet is not available on this system"

**Solutions:**
1. Check Windows version (requires Windows 10 1809+ or Windows 11)
2. Open Microsoft Store → Search for "App Installer" → Install/Update
3. Download from: https://aka.ms/getwinget
4. Run Windows Update to get latest version
5. Restart computer after installation

### No Updates Found
**Problem:** "No applicable update found" message

**Possible Reasons:**
- All software is already up to date ✓
- Software not managed by WinGet
- Software installed via different methods
- WinGet sources need updating

**Solutions:**
- This is normal if software is current
- Run `winget source update` to refresh sources
- Some apps don't support WinGet updates

### Updates Fail
**Problem:** Updates fail or show errors

**Solutions:**
1. Check internet connection
2. Run as Administrator
3. Close the application being updated
4. Try interactive mode to see detailed errors
5. Update WinGet itself: `winget upgrade --id Microsoft.WinGet`
6. Clear WinGet cache and retry

### Permission Denied
**Problem:** "Access denied" or permission errors

**Solutions:**
1. Ensure running as Administrator
2. Right-click → "Run as Administrator"
3. Close applications before updating
4. Check antivirus isn't blocking

### Slow Updates
**Problem:** Updates taking very long

**Reasons:**
- Many packages to update
- Large downloads (office suites, development tools)
- Slow internet connection
- Package servers may be slow

**Solutions:**
- Be patient - this is normal for many updates
- Check network speed
- Try updating fewer packages at a time (interactive mode)
- Run during off-peak hours

## Technical Details

### Storage Locations
- **Update History:** `%LOCALAPPDATA%\SouliTEK\UpdateHistory.json`
- **Exported Reports:** `%USERPROFILE%\Desktop\SoftwareUpdateReport_*.txt`
- **WinGet Temp Files:** `%TEMP%\soulitek_winget_*.txt` (automatically cleaned)

### History Management
- Stores last 50 update sessions
- JSON format for easy parsing
- Automatic cleanup of old entries
- Includes timestamp, duration, mode, exit code, success status

### Self-Destruct Feature
Like all SouliTEK tools, this script includes automatic self-destruct functionality:
- Activates when user exits (Option 0)
- Deletes script file after 2-second delay
- Designed for deployment scenarios
- Silent operation

## Supported Software

WinGet supports thousands of applications from various sources:
- **Microsoft Store** apps
- **Official repositories** (msstore, winget)
- **Third-party** applications in WinGet repository

### Common Applications
- Web Browsers (Chrome, Firefox, Edge)
- Development Tools (VS Code, Git, Python)
- Productivity (Office apps, Adobe Reader)
- Media (VLC, Spotify)
- Utilities (7-Zip, Notepad++)
- And thousands more...

### Check Your Software
To see what WinGet can manage on your system:
```powershell
winget list
```

To see available updates:
```powershell
winget upgrade
```

## Comparison: Automatic vs. Interactive

| Feature | Automatic Mode | Interactive Mode |
|---------|---------------|------------------|
| **User Interaction** | None | Review each package |
| **Speed** | Fast | Slower (manual review) |
| **Control** | Minimal | Full control |
| **Best For** | Routine maintenance | Selective updates |
| **Prompts** | None | Confirmation needed |
| **Selective Updates** | No | Yes |
| **Recommendation** | Trusted environments | Testing/Critical systems |

## Support

For assistance or to report issues:
- **Website:** www.soulitek.co.il
- **Email:** letstalk@soulitek.co.il

---

**Coded by:** SouliTEK  
*IT Solutions for your business*

(C) 2025 SouliTEK - All Rights Reserved














