# Choco Installer

## Overview

The **Choco Installer** (SouliTEK-Choco-Installer) is an interactive tool for selecting and installing applications via Chocolatey package manager. It provides a Ninite-like user experience for installing essential business applications using Chocolatey.

## Purpose

Simplifies software installation via Chocolatey:
- Interactive application selection
- Batch installation via Chocolatey
- Preset configuration support
- Installation progress tracking
- Business application catalog

## Features

### 📦 **Application Catalog**
- Pre-configured business applications
- Categories: Utilities, Security, Productivity
- Application descriptions
- Chocolatey package IDs

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
- **OS:** Windows 10 or Windows 11
- **PowerShell:** Version 5.1 or higher
- **Privileges:** Administrator rights (required)
- **Chocolatey:** Auto-installed if missing

## Usage

### Running the Script

1. **Launch from SouliTEK Launcher** (recommended)
   - Open the SouliTEK Launcher
   - Find "Choco Installer" in the Software category
   - Click the tool card to launch

2. **Run directly via PowerShell** (as Administrator):
   ```powershell
   .\scripts\SouliTEK-Choco-Installer.ps1
   ```

3. **With preset file:**
   ```powershell
   .\scripts\SouliTEK-Choco-Installer.ps1 -Preset "C:\path\to\preset.json"
   ```

### First-Time Setup

#### Chocolatey Installation
- Tool automatically installs Chocolatey if missing
- Requires Administrator privileges
- One-time setup process
- Verifies installation

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

## Application Catalog

### Included Applications
- **NAPS2:** Document scanning
- **HP Smart:** Printer management
- **Adobe Reader:** PDF reader
- **Forticlient VPN:** Enterprise VPN
- **Dropbox:** Cloud storage
- **Zoom:** Video conferencing
- **Microsoft Office 2024:** Office suite

### Categories
- **Utilities:** System utilities and tools
- **Security:** Security and VPN software
- **Productivity:** Office and productivity apps

## Installation Process

### Step 1: Chocolatey Check
- Verifies Chocolatey is installed
- Auto-installs if missing
- Checks Chocolatey version
- Validates functionality

### Step 2: Application Selection
- Browse catalog
- Select applications
- Review selections
- Confirm installation

### Step 3: Installation
- Batch installation via Chocolatey
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
    "googlechrome",
    "anydesk",
    "adobereader"
  ],
  "created": "2025-01-01T00:00:00",
  "description": "Standard business applications"
}
```

## Troubleshooting

### Chocolatey Installation Fails
**Problem:** Cannot install Chocolatey

**Solutions:**
1. Check internet connectivity
2. Verify PowerShell execution policy
3. Run PowerShell as Administrator
4. Manual installation: https://chocolatey.org/install

### Installation Fails
**Problem:** Application installation fails

**Solutions:**
1. Check internet connectivity
2. Verify Chocolatey package name
3. Check application is available in Chocolatey
4. Run Chocolatey command manually
5. Check antivirus isn't blocking

## Best Practices

### Application Selection
- Select applications you need
- Review descriptions
- Check system requirements
- Consider disk space

### Installation
- Install during off-peak hours
- Ensure stable internet
- Close other applications
- Don't interrupt installation

## Technical Details

### Chocolatey Integration
- Uses Chocolatey package manager
- Community-maintained packages
- Automatic dependency resolution
- Silent installation support

## Support

For assistance or to report issues:
- **Website:** www.soulitek.co.il
- **Email:** letstalk@soulitek.co.il

---

**Coded by:** SouliTEK  
*IT Solutions for your business*

(C) 2025 SouliTEK - All Rights Reserved

















