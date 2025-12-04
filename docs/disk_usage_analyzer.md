# Disk Usage Analyzer

## Overview

The **Disk Usage Analyzer** is a comprehensive tool for analyzing disk space usage and identifying large folders and files. It helps IT professionals and users understand storage consumption and find opportunities for disk cleanup.

## Purpose

Provides detailed disk space analysis:
- Large folder identification
- Size analysis by directory
- Storage recommendations
- Visual reports (HTML)
- Export capabilities

## Features

### 📊 **Disk Analysis**
- Scan entire drives or specific folders
- Identify largest folders and files
- Size breakdown by directory
- Top N folders by size

### 📈 **Visual Reports**
- HTML visualization with charts
- Color-coded size indicators
- Interactive folder tree
- Size distribution graphs

### 📁 **Folder Scanning**
- Recursive folder size calculation
- Configurable minimum size threshold
- Multiple scan paths
- Fast scanning algorithm

### 💾 **Export Options**
- Export to TXT format
- Export to CSV format
- Export to HTML (visual report)
- Desktop location by default

## Requirements

### System Requirements
- **OS:** Windows 10 or Windows 11
- **PowerShell:** Version 5.1 or higher
- **Privileges:** Standard user (admin may be needed for system folders)
- **Disk Space:** Sufficient space for report files

## Usage

### Running the Script

1. **Launch from SouliTEK Launcher** (recommended)
   - Open the SouliTEK Launcher
   - Find "Disk Usage Analyzer" in the System category
   - Click the tool card to launch

2. **Run directly via PowerShell:**
   ```powershell
   .\scripts\disk_usage_analyzer.ps1
   ```

### Menu Options

#### Option 1: Scan Drive
Analyzes entire drive for large folders.
- Select drive to scan
- Configurable minimum size (default: 1GB)
- Shows top folders by size
- Displays total size per folder

#### Option 2: Scan Custom Folder
Analyzes specific folder path.
- Enter custom folder path
- Recursive scanning
- Size analysis
- Large subfolder identification

#### Option 3: Find Large Files
Identifies largest individual files.
- Scans for files above threshold
- Lists files by size
- Shows file locations
- Total size calculation

#### Option 4: Export Results
Exports analysis to file formats.
- TXT format (text report)
- CSV format (spreadsheet compatible)
- HTML format (visual report with charts)
- Saved to Desktop

#### Option 5: View Last Scan Results
Displays results from previous scan.
- Loads last scan data
- Quick review without rescanning
- Export previous results

## Output Files

### Report Locations
- **Desktop:** Reports saved to `%USERPROFILE%\Desktop`
- **Formats:** TXT, CSV, HTML
- **Filename:** `DiskUsageReport_YYYYMMDD_HHMMSS.[ext]`

### HTML Report Features
- Interactive folder tree
- Color-coded size indicators
- Pie charts for size distribution
- Clickable folder navigation
- Professional formatting

## Common Use Cases

### Disk Cleanup
- Identify large folders for cleanup
- Find duplicate files
- Locate temporary file locations
- Identify unused applications

### Storage Planning
- Understand disk space usage
- Plan for storage expansion
- Identify growth trends
- Capacity planning

### Troubleshooting
- Find what's consuming disk space
- Identify unexpected large files
- Locate log file accumulation
- Find backup file locations

## Best Practices

### Regular Scanning
- Scan monthly for maintenance
- Check before disk cleanup
- Monitor disk space trends
- Identify storage growth

### Before Cleanup
- Create restore point
- Backup important data
- Review scan results carefully
- Verify file importance before deletion

### Performance Tips
- Scan specific folders for faster results
- Use minimum size threshold to filter small items
- Run during off-peak hours for large scans
- Close other applications during scan

## Troubleshooting

### Scan Takes Too Long
**Problem:** Scan is very slow

**Causes:**
- Scanning large drives
- Many small files
- Network drives
- Slow disk (HDD vs SSD)

**Solutions:**
- Scan specific folders instead of entire drive
- Increase minimum size threshold
- Run during off-peak hours
- Avoid scanning network locations

### Access Denied Errors
**Problem:** "Access denied" during scan

**Solutions:**
1. Run as Administrator
2. Some system folders require admin
3. Skip inaccessible folders (tool handles gracefully)
4. Check folder permissions

### Out of Memory
**Problem:** Script runs out of memory

**Causes:**
- Very large directory structures
- Millions of files
- Insufficient RAM

**Solutions:**
- Scan smaller folders
- Increase minimum size threshold
- Close other applications
- Scan drives separately

### Report Not Generated
**Problem:** Export fails or incomplete

**Solutions:**
1. Check disk space on Desktop
2. Verify write permissions
3. Close file if already open
4. Check for antivirus blocking

## Technical Details

### Scanning Algorithm
- Recursive directory traversal
- Size calculation per folder
- Efficient file system access
- Progress indicators for long scans

### Size Calculation
- Includes all subfolders
- Accounts for file system overhead
- Shows actual disk usage
- Handles junction points and symlinks

### Performance
- Optimized for large directory trees
- Progress updates during scan
- Memory-efficient processing
- Fast size aggregation

## Support

For assistance or to report issues:
- **Website:** www.soulitek.co.il
- **Email:** letstalk@soulitek.co.il

---

**Coded by:** SouliTEK  
*IT Solutions for your business*

(C) 2025 SouliTEK - All Rights Reserved













