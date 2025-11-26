# PST Finder

## Overview

The **PST Finder** tool locates Outlook PST (Personal Storage Table) files across the system, summarizes their sizes, and exports clean reports. It's designed for IT professionals managing Outlook data files and storage optimization.

## Purpose

Helps locate and manage Outlook PST files:
- Find all PST files on system
- Calculate total PST file sizes
- Export location reports
- Storage optimization
- Data migration planning

## Features

### 🔍 **PST File Detection**
- Quick scan (common locations)
- Deep scan (entire system)
- Network drive scanning
- Hidden file detection

### 📊 **Size Analysis**
- Individual file sizes
- Total PST storage used
- Size by location
- Summary statistics

### 📋 **Reporting**
- Export to CSV format
- Export to TXT format
- Summary reports
- Detailed file listings

### ⚙️ **Advanced Options**
- Scheduled scanning
- Automated reports
- Custom scan paths
- Filter by size

## Requirements

### System Requirements
- **OS:** Windows 10 or Windows 11
- **PowerShell:** Version 5.1 or higher
- **Privileges:** Standard user (admin for system folders)
- **Outlook:** Not required (finds PST files regardless)

## Usage

### Running the Script

1. **Launch from SouliTEK Launcher** (recommended)
   - Open the SouliTEK Launcher
   - Find "PST Finder" in the System category
   - Click the tool card to launch

2. **Run directly via PowerShell:**
   ```powershell
   .\scripts\FindPST.ps1
   ```

3. **Automated Scan** (for scheduled tasks):
   ```powershell
   .\scripts\FindPST.ps1 -AutoScan
   ```

### Menu Options

#### Option 1: Quick Scan
Fast scan of common PST locations.
- User profile folders
- Outlook default locations
- Documents folder
- Desktop locations
- Fast results

#### Option 2: Deep Scan
Comprehensive system-wide scan.
- All drives
- All user profiles
- Network locations (if accessible)
- Hidden folders
- Complete coverage

#### Option 3: Scan Custom Path
Scan specific folder or drive.
- Enter custom path
- Recursive scanning
- Network paths supported
- Focused search

#### Option 4: View Summary
Displays PST file summary.
- Total files found
- Total size
- Largest files
- Location breakdown

#### Option 5: Export Results
Exports scan results to files.
- CSV format (spreadsheet)
- TXT format (text report)
- Saved to Desktop
- Timestamped filename

## Output Files

### Report Locations
- **Desktop:** Reports saved to `%USERPROFILE%\Desktop`
- **Formats:** CSV and TXT
- **Filename:** `PSTScanReport_YYYYMMDD_HHMMSS.[ext]`

### Report Contents
- File locations (full paths)
- File sizes
- Last modified dates
- Total count and size
- Summary statistics

## Common PST Locations

### Default Locations
- `%USERPROFILE%\Documents\Outlook Files\`
- `%USERPROFILE%\AppData\Local\Microsoft\Outlook\`
- `%USERPROFILE%\AppData\Roaming\Microsoft\Outlook\`
- `C:\Users\[Username]\Documents\`

### Archive Locations
- User-defined archive folders
- Backup locations
- Network shares
- External drives

## Use Cases

### Storage Management
- Identify large PST files
- Plan storage optimization
- Locate archived data
- Calculate total Outlook data size

### Migration Planning
- Find all PST files before migration
- Document file locations
- Estimate migration time
- Plan data consolidation

### Troubleshooting
- Locate missing PST files
- Find corrupted PST files
- Identify duplicate files
- Verify PST file locations

### Compliance
- Document PST file locations
- Calculate data retention
- Audit Outlook data storage
- Compliance reporting

## Best Practices

### Regular Scanning
- Scan monthly for maintenance
- Before Outlook migrations
- After major Outlook changes
- When troubleshooting issues

### Before Migration
- Run deep scan
- Export results
- Verify all files found
- Document locations

### Storage Optimization
- Identify large PST files
- Consider archiving old data
- Consolidate multiple PST files
- Move to network storage if needed

## Troubleshooting

### No PST Files Found
**Problem:** Scan finds no PST files

**Possible Reasons:**
- No PST files on system
- PST files in non-standard locations
- Insufficient permissions
- Files on network drives not accessible

**Solutions:**
- Run deep scan
- Check user profile folders manually
- Verify Outlook is installed
- Check network drive accessibility

### Scan Takes Too Long
**Problem:** Deep scan is very slow

**Causes:**
- Large number of files
- Network drive scanning
- Slow disk (HDD)
- System performance

**Solutions:**
- Use quick scan for common locations
- Scan specific paths instead of entire system
- Avoid scanning network drives if slow
- Run during off-peak hours

### Access Denied
**Problem:** Cannot access some folders

**Solutions:**
1. Run as Administrator
2. Some system folders require admin
3. Tool skips inaccessible folders gracefully
4. Check folder permissions

### Large PST Files
**Problem:** Found very large PST files

**Recommendations:**
- Consider splitting large files
- Archive old data
- Move to network storage
- Use Outlook's archive feature
- Monitor file size (Outlook has limits)

## Technical Details

### File Detection
- Searches for `.pst` file extension
- Case-insensitive search
- Includes hidden files
- Handles long file paths

### Size Calculation
- Accurate file sizes
- Handles large files (>2GB)
- Total size aggregation
- Size formatting (KB, MB, GB)

### Performance
- Optimized file system access
- Progress indicators
- Efficient directory traversal
- Memory-efficient processing

## PST File Limits

### Outlook Limits
- **Outlook 2002 and earlier:** 2GB limit
- **Outlook 2003-2010:** 20GB limit (with large file support)
- **Outlook 2013 and later:** 50GB limit

### Best Practices
- Keep PST files under 10GB
- Split large files
- Regular archiving
- Monitor file sizes

## Support

For assistance or to report issues:
- **Website:** www.soulitek.co.il
- **Email:** letstalk@soulitek.co.il

---

**Coded by:** SouliTEK  
*IT Solutions for your business*

(C) 2025 SouliTEK - All Rights Reserved





