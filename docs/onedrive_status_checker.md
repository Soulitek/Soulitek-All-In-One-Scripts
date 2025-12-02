# OneDrive Status Checker

## Overview

The OneDrive Status Checker is a diagnostic tool that examines OneDrive sync status by checking the Registry, process status, and log files. It helps IT technicians quickly identify sync issues without the typical "the file didn't update for me" back-and-forth conversation.

## Features

### 1. Full Scan
- **Installation Check**: Verifies OneDrive is installed and gets version info
- **Process Status**: Checks if OneDrive.exe is running
- **Account Detection**: Lists all configured OneDrive accounts (Personal & Business)
- **Sync Status**: Determines current sync state (Up To Date, Syncing, Paused, Error)
- **Folder Analysis**: Calculates file count and total size of OneDrive folders
- **Error Scanning**: Searches logs for sync errors from the last 7 days

### 2. Quick Status
One-line summary showing:
- Installation status and version
- Process running state
- Number of configured accounts
- Current sync status
- Overall verdict (working/needs attention)

### 3. Sync Error Detection
Scans OneDrive logs for common error patterns:
- Upload/Download blocked
- Quota exceeded
- Sync conflicts
- Access denied
- File locked
- Invalid characters in filename
- Path too long
- Authentication issues
- Network connectivity problems

### 4. Account Details
Detailed information for each OneDrive account:
- Email address
- Account type (Personal/Business)
- Folder location
- Tenant ID (for Business accounts)
- Last sign-in time
- Folder statistics (file count, total size)

### 5. Export Capabilities
Export results to:
- **TXT**: Plain text report
- **CSV**: Spreadsheet-compatible format
- **HTML**: Formatted web report with SouliTEK branding

## Status Indicators

| Status | Color | Description |
|--------|-------|-------------|
| Up To Date | Green | All files are synced |
| Syncing | Cyan | Sync in progress |
| Paused | Yellow | Sync is paused |
| Error | Red | Sync errors detected |
| Not Running | Yellow | OneDrive process not running |
| Not Installed | Red | OneDrive not found on system |

## Menu Options

```
[1] Full Scan              - Complete OneDrive status check
[2] Quick Status           - One-line status summary
[3] View Sync Errors       - Show sync error details
[4] Account Details        - View configured accounts
[5] Export Results         - Export to TXT, CSV, or HTML
[6] Help                   - Usage guide and troubleshooting
[0] Exit
```

## Technical Details

### Registry Paths Checked
- `HKCU:\Software\Microsoft\OneDrive`
- `HKCU:\Software\Microsoft\OneDrive\Accounts\*`
- `HKLM:\SOFTWARE\Microsoft\OneDrive`

### Log Locations
- Personal: `%LOCALAPPDATA%\Microsoft\OneDrive\logs\Personal`
- Business: `%LOCALAPPDATA%\Microsoft\OneDrive\logs\Business1`

### OneDrive Paths Checked
- `%LOCALAPPDATA%\Microsoft\OneDrive\OneDrive.exe`
- `%ProgramFiles%\Microsoft OneDrive\OneDrive.exe`
- `%ProgramFiles(x86)%\Microsoft OneDrive\OneDrive.exe`
- `%USERPROFILE%\OneDrive`
- `%OneDrive%` environment variable

## Common Issues & Solutions

### File Not Syncing
1. Check if OneDrive is running (Quick Status)
2. Look for sync errors (View Sync Errors)
3. Verify storage quota isn't exceeded
4. Check for file conflicts

### Authentication Issues
1. Sign out of OneDrive
2. Sign back in with correct credentials
3. For Business accounts, verify tenant access

### Path Too Long
- Maximum path length is 400 characters
- Shorten folder/file names
- Move files to a shorter path

### File Locked
- Close the application using the file
- Wait for the lock to release
- Restart OneDrive if needed

## Troubleshooting Commands

### Reset OneDrive
```powershell
%localappdata%\Microsoft\OneDrive\onedrive.exe /reset
```

### Restart OneDrive
```powershell
taskkill /f /im OneDrive.exe
start "" "%localappdata%\Microsoft\OneDrive\OneDrive.exe"
```

### Reinstall OneDrive
```powershell
# Uninstall
%localappdata%\Microsoft\OneDrive\onedrive.exe /uninstall

# Reinstall from Microsoft website
```

## Requirements

- **Operating System**: Windows 10/11
- **PowerShell**: Version 5.1 or later
- **Privileges**: No admin required (runs in user context)
- **OneDrive**: Any version (Personal or Business)

## Use Cases

1. **Help Desk Support**: Quickly verify if a user's OneDrive is syncing
2. **Remote Troubleshooting**: Export status report for analysis
3. **Pre-emptive Checks**: Identify issues before users report them
4. **Migration Verification**: Confirm files synced after OneDrive setup
5. **Audit Trail**: Document OneDrive status for compliance

## Version History

### v1.0.0 (2025-11-27)
- Initial release
- Registry-based status detection
- Log scanning for errors
- Multi-account support (Personal & Business)
- Export to TXT/CSV/HTML
- Self-destruct feature

## Author

**SouliTEK** - IT Solutions for your business

- Website: [www.soulitek.co.il](https://www.soulitek.co.il)
- Email: letstalk@soulitek.co.il

© 2025 SouliTEK - All Rights Reserved




