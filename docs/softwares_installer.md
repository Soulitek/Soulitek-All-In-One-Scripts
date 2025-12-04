# Softwares Installer

## Overview

The **Softwares Installer** (formerly WinGet Package Installer) is an interactive tool for selecting and installing applications via Windows Package Manager (WinGet). It provides a Ninite-like user experience for installing essential business applications.

## Purpose

Simplifies software installation:
- Interactive application selection
- Batch installation via WinGet
- Preset configuration support
- Installation progress tracking
- Business application catalog

## Features

### 📦 **Application Catalog**
- Pre-configured business applications
- Categories: Utilities, Security, Productivity, Communications
- Application descriptions
- WinGet package IDs

### 🎯 **Interactive Selection**
- Checkbox-based selection
- Category filtering
- Search functionality
- Installation preview

### ⚡ **Batch Installation**
- Install multiple applications at once
- Progress tracking
- Error handling
- Installation summary

### 💾 **Preset Support**
- Save installation presets
- Load preset configurations
- JSON preset files
- Reusable configurations

## Requirements

### System Requirements
- **OS:** Windows 10 (1709+) or Windows 11
- **PowerShell:** Version 5.1 or higher
- **Privileges:** Administrator rights (required)
- **WinGet:** Auto-installed if missing

## Usage

### Running the Script

1. **Launch from SouliTEK Launcher** (recommended)
   - Open the SouliTEK Launcher
   - Find "Softwares Installer" in the Software category
   - Click the tool card to launch

2. **Run directly via PowerShell** (as Administrator):
   ```powershell
   .\scripts\SouliTEK-Softwares-Installer.ps1
   ```

3. **With preset file:**
   ```powershell
   .\scripts\SouliTEK-Softwares-Installer.ps1 -Preset "C:\path\to\preset.json"
   ```

### Menu Options

#### Option 1: Select Applications
Interactive application selection.
- Browse application catalog
- Select applications to install
- Category filtering
- Search applications

#### Option 2: Install Selected
Installs selected applications.
- Batch installation
- Progress tracking
- Error handling
- Installation summary

#### Option 3: Load Preset
Load installation preset.
- Select preset file
- Load application list
- Apply preset configuration

#### Option 4: Save Preset
Save current selection as preset.
- Create preset file
- Save to Desktop
- JSON format
- Reusable configuration

#### Option 5: View Catalog
Browse available applications.
- View all applications
- Application details
- Category information
- WinGet package IDs

## Application Catalog

### Included Applications
- **NAPS2:** Document scanning
- **HP Smart:** Printer management
- **Adobe Reader:** PDF reader
- **Forticlient VPN:** Enterprise VPN
- **Dropbox:** Cloud storage
- **Zoom:** Video conferencing
- **Microsoft Office 2024:** Office suite
- **Discord:** Communication
- **Google Chrome:** Web browser
- **Google Drive:** Cloud storage
- **AnyDesk:** Remote desktop
- **WinRAR:** File compression
- **WhatsApp:** Messaging
- **qBittorrent:** BitTorrent client
- **Telegram:** Secure messaging

### Categories
- **Utilities:** System utilities and tools
- **Security:** Security and VPN software
- **Productivity:** Office and productivity apps
- **Communications:** Communication platforms
- **Browsers:** Web browsers
- **Remote Access:** Remote desktop tools

## Installation Process

### Step 1: WinGet Check
- Verifies WinGet is installed
- Auto-installs if missing
- Checks WinGet version
- Validates functionality

### Step 2: Application Selection
- Browse catalog
- Select applications
- Review selections
- Confirm installation

### Step 3: Installation
- Batch installation via WinGet
- Progress indicators
- Error handling
- Installation logs

### Step 4: Summary
- Installation results
- Success/failure status
- Summary report
- Export to Desktop

## Preset Files

### Preset Format (JSON)
```json
{
  "packages": [
    "Google.Chrome",
    "AnyDeskSoftwareGmbH.AnyDesk",
    "Adobe.Acrobat.Reader.64-bit"
  ],
  "created": "2025-01-01T00:00:00",
  "description": "Standard business applications"
}
```

### Creating Presets
1. Select applications in tool
2. Choose "Save Preset" option
3. Enter preset name
4. Preset saved to Desktop

### Using Presets
1. Choose "Load Preset" option
2. Select preset file
3. Applications loaded
4. Proceed with installation

## Output Files

### Installation Summary
- **Location:** Desktop
- **Format:** JSON
- **Filename:** `SouliTEK-Softwares-Installer-Result.json`
- **Contents:** Installation results, success/failure, timestamps

## Troubleshooting

### WinGet Not Available
**Problem:** WinGet installation fails

**Solutions:**
1. Manual WinGet installation: https://aka.ms/getwinget
2. Update App Installer from Microsoft Store
3. Check Windows version (requires 1709+)
4. Restart computer after installation

### Installation Fails
**Problem:** Application installation fails

**Solutions:**
1. Check internet connectivity
2. Verify WinGet package ID is correct
3. Check application is available in WinGet
4. Run WinGet command manually to see error
5. Check antivirus isn't blocking

### Installation Hanging
**Problem:** Installation hangs and never completes

**Solutions:**
1. The installer now includes automatic timeout protection (30 minutes per package)
2. Silent mode is enabled by default to prevent hanging on user prompts
3. If installation hangs, it will automatically timeout after 30 minutes
4. Check log files in `%TEMP%\winget_*.log` for error details
5. Ensure WinGet is up to date: `winget upgrade --all`
6. Check for antivirus interference
7. Verify internet connection is stable

**Technical Details:**
- Installations use `--silent` flag to prevent interactive prompts
- Timeout protection: 30 minutes maximum per package
- Progress updates every 30 seconds during installation
- Automatic process termination on timeout

### Preset Not Loading
**Problem:** Cannot load preset file

**Solutions:**
1. Verify preset file format (valid JSON)
2. Check file path is correct
3. Verify file permissions
4. Check JSON syntax

## Best Practices

### Application Selection
- Select applications you actually need
- Review application descriptions
- Check system requirements
- Consider disk space

### Installation
- Install during off-peak hours
- Ensure stable internet connection
- Close other applications
- Don't interrupt installation

### Preset Management
- Create presets for common configurations
- Document preset purposes
- Keep presets updated
- Share presets with team

## Technical Details

### WinGet Integration
- Uses Windows Package Manager
- Official Microsoft package manager
- Secure package sources
- Automatic dependency resolution

### Installation Method
- Silent installation by default (`--silent` flag)
- No user interaction required
- Automatic timeout protection (30 minutes per package)
- Progress tracking with periodic updates
- Error reporting with detailed logs
- Async output handling to prevent buffer blocking
- Graceful timeout handling with process termination

## Support

For assistance or to report issues:
- **Website:** www.soulitek.co.il
- **Email:** letstalk@soulitek.co.il

---

**Coded by:** SouliTEK  
*IT Solutions for your business*

(C) 2025 SouliTEK - All Rights Reserved














