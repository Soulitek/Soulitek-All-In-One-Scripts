# Temp Removal & Disk Cleanup

## Overview

The **Temp Removal & Disk Cleanup** tool removes temporary files and cleans disk space for improved system performance and storage optimization. It's designed for IT professionals performing system maintenance and cleanup.

## Purpose

Automates disk cleanup operations:
- Temporary file removal
- Browser cache cleanup
- Windows Update cleanup
- Recycle Bin cleanup
- Disk space recovery

## Features

### 🗑️ **Temporary File Removal**
- User temporary files
- System temporary files
- Windows temp folders
- Application temp files

### 🌐 **Browser Cache Cleanup**
- Chrome cache
- Firefox cache
- Edge cache
- Browser temp files

### 💾 **Windows Update Cleanup**
- Windows Update files
- Update cache
- Old update files
- Update temp data

### 🗂️ **Recycle Bin Cleanup**
- Empty Recycle Bin
- All drives
- Permanent deletion
- Space recovery

### 📊 **Disk Cleanup Integration**
- Windows Disk Cleanup
- System file cleanup
- Advanced cleanup options
- Comprehensive cleanup

## Requirements

### System Requirements
- **OS:** Windows 10 or Windows 11
- **PowerShell:** Version 5.1 or higher
- **Privileges:** Administrator rights (required for system cleanup)
- **Disk Space:** Sufficient space for operation

## Usage

### Running the Script

1. **Launch from SouliTEK Launcher** (recommended)
   - Open the SouliTEK Launcher
   - Find "Temp Removal & Disk Cleanup" in the System category
   - Click the tool card to launch

2. **Run directly via PowerShell** (as Administrator):
   ```powershell
   .\scripts\temp_removal_disk_cleanup.ps1
   ```

### Menu Options

#### Option 1: Quick Cleanup
Fast cleanup of common temp locations.
- User temp files
- System temp files
- Recycle Bin
- Quick operation

#### Option 2: Full Cleanup
Comprehensive cleanup of all locations.
- All temp files
- Browser caches
- Windows Update files
- Disk Cleanup integration
- Complete cleanup

#### Option 3: Custom Cleanup
Select specific cleanup options.
- Choose what to clean
- Selective cleanup
- Custom configuration
- Targeted cleanup

#### Option 4: View Disk Space
Shows disk space before and after cleanup.
- Current disk usage
- Estimated space recovery
- Drive information
- Space analysis

#### Option 5: Export Cleanup Report
Exports cleanup results to file.
- Cleanup summary
- Space recovered
- Files removed
- CSV format export

## Cleanup Locations

### Temporary Files
- `%TEMP%` (User temp)
- `%WINDIR%\Temp` (System temp)
- `%LOCALAPPDATA%\Temp`
- Application temp folders

### Browser Caches
- Chrome: `%LOCALAPPDATA%\Google\Chrome\User Data\Default\Cache`
- Firefox: `%LOCALAPPDATA%\Mozilla\Firefox\Profiles\*\cache2`
- Edge: `%LOCALAPPDATA%\Microsoft\Edge\User Data\Default\Cache`

### Windows Update
- `%WINDIR%\SoftwareDistribution\Download`
- Windows Update cache
- Old update files

### Recycle Bin
- All drive Recycle Bins
- User and system bins

## Safety Features

### File Protection
- Only removes temporary files
- Safe cleanup locations
- No user data deletion
- System file protection

### Confirmation
- Shows what will be cleaned
- User confirmation required
- Space recovery estimate
- Safety warnings

## Troubleshooting

### Cleanup Fails
**Problem:** Cannot clean some locations

**Solutions:**
1. Run as Administrator
2. Close applications using temp files
3. Check file permissions
4. Some files may be in use
5. Restart and try again

### Insufficient Space Recovered
**Problem:** Not much space recovered

**Causes:**
- Recent cleanup performed
- Small temp files
- Already cleaned recently

**Solutions:**
- Run Windows Disk Cleanup for more options
- Check for large files manually
- Use Disk Usage Analyzer tool
- Consider uninstalling unused programs

### Files Still Present
**Problem:** Some files not removed

**Causes:**
- Files in use by applications
- Locked files
- Permission issues

**Solutions:**
- Close applications
- Restart computer
- Run as Administrator
- Some files may require manual removal

## Best Practices

### Regular Cleanup
- Run cleanup monthly
- Before system maintenance
- After software installations
- When disk space is low

### Before Cleanup
- Close applications
- Save open work
- Create restore point (optional)
- Review what will be cleaned

### After Cleanup
- Verify disk space recovered
- Check system performance
- Review cleanup report
- Document cleanup results

## Technical Details

### Cleanup Methods
- File system deletion
- Windows Disk Cleanup integration
- PowerShell cleanup commands
- Safe file removal

### Space Calculation
- Accurate size calculation
- Before/after comparison
- Space recovery reporting
- Detailed statistics

## Output Files

### Report Locations
- **Desktop:** Reports saved to `%USERPROFILE%\Desktop`
- **Format:** CSV
- **Filename:** `DiskCleanupReport_YYYYMMDD_HHMMSS.csv`

### Report Contents
- Cleanup locations
- Files removed count
- Space recovered
- Cleanup duration
- Status per location

## Support

For assistance or to report issues:
- **Website:** www.soulitek.co.il
- **Email:** letstalk@soulitek.co.il

---

**Coded by:** SouliTEK  
*IT Solutions for your business*

(C) 2025 SouliTEK - All Rights Reserved













