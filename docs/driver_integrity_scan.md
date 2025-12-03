# Driver Integrity Scan

## Overview

The **Driver Integrity Scan** tool scans for driver issues, exports driver information, and helps identify problematic devices. It's designed for IT professionals troubleshooting hardware issues and maintaining driver health.

## Purpose

Provides comprehensive driver analysis:
- Driver integrity scanning
- Problem device detection
- Driver list export
- Error code interpretation
- Device status reporting

## Features

### 🔍 **Driver Scanning**
- Scan all installed drivers
- Identify problem devices
- Check driver status
- Error code analysis

### 📋 **Driver Information**
- Export complete driver list
- Driver version information
- Device details
- Driver file locations

### ⚠️ **Problem Detection**
- Identify devices with errors
- Error code descriptions
- Device status reporting
- Troubleshooting recommendations

### 📊 **Reports**
- Detailed scan results
- Problem device summary
- Driver inventory export
- CSV and TXT formats

## Requirements

### System Requirements
- **OS:** Windows 10 or Windows 11
- **PowerShell:** Version 5.1 or higher
- **Privileges:** Administrator rights (required)
- **WinGet:** Optional (for driver updates)

## Usage

### Running the Script

1. **Launch from SouliTEK Launcher** (recommended)
   - Open the SouliTEK Launcher
   - Find "Driver Integrity Scan" in the Hardware category
   - Click the tool card to launch

2. **Run directly via PowerShell** (as Administrator):
   ```powershell
   .\scripts\driver_integrity_scan.ps1
   ```

### Menu Options

#### Option 1: Scan for Driver Issues
Comprehensive driver integrity scan.
- Scans all devices
- Identifies problem devices
- Error code analysis
- Status reporting

#### Option 2: Export Driver List
Exports complete driver inventory.
- All installed drivers
- Driver versions
- Device information
- Export to CSV/TXT

#### Option 3: View Problem Devices
Lists devices with issues.
- Error codes and descriptions
- Device names and IDs
- Status information
- Troubleshooting hints

#### Option 4: Check Specific Device
Analyzes specific device.
- Enter device name or ID
- Detailed device information
- Driver status
- Error details

## Error Codes

### Common Error Codes
- **0:** Device is working properly
- **1:** Device is not configured correctly
- **3:** Driver is corrupted
- **10:** Device cannot start
- **12:** Device cannot find enough free resources
- **18:** Device drivers must be reinstalled
- **22:** Device is disabled
- **28:** Device drivers are not installed
- **31:** Device is not working properly
- **32:** Windows cannot load the device driver

### Error Code Interpretation
The tool provides detailed descriptions for each error code to help identify the specific issue and recommended actions.

## Output Files

### Report Locations
- **Desktop:** Reports saved to `%USERPROFILE%\Desktop`
- **Formats:** TXT and CSV
- **Filename:** `DriverScanReport_YYYYMMDD_HHMMSS.txt`

### Report Contents
- Scan timestamp
- Total devices scanned
- Problem devices count
- Detailed device list
- Error codes and descriptions

## Troubleshooting

### Driver Issues Detected
**Problem:** Tool reports driver problems

**Solutions:**
1. Update drivers via Device Manager
2. Download drivers from manufacturer
3. Use Windows Update for driver updates
4. Reinstall problematic drivers
5. Check manufacturer support site

### Device Not Working
**Problem:** Device shows error code

**Actions:**
- Note the error code
- Check error code description in tool
- Update or reinstall driver
- Check Device Manager for details
- Visit manufacturer support

### Cannot Export Driver List
**Problem:** Export fails

**Solutions:**
1. Ensure running as Administrator
2. Check disk space on Desktop
3. Verify write permissions
4. Close file if already open

### Scan Takes Too Long
**Problem:** Scan is slow

**Causes:**
- Many devices installed
- Network device scanning
- Slow system performance

**Solutions:**
- Normal for systems with many devices
- Close other applications
- Scan specific devices if needed

## Best Practices

### Regular Scanning
- Scan monthly for maintenance
- Check after driver updates
- Scan after hardware changes
- Monitor for new issues

### Driver Management
- Keep drivers up to date
- Use manufacturer drivers when possible
- Create restore point before driver updates
- Document driver versions

### Problem Resolution
- Address error codes promptly
- Update drivers from trusted sources
- Test after driver changes
- Keep driver backups

## Technical Details

### Scan Process
- Queries Windows Device Manager
- Checks device status codes
- Analyzes driver information
- Compiles problem device list

### Data Sources
- Windows Management Instrumentation (WMI)
- Device Manager registry
- Driver file system
- Device status codes

### WinGet Integration
- Optional driver update capability
- Uses Windows Package Manager
- Automated driver installation
- Update tracking

## Support

For assistance or to report issues:
- **Website:** www.soulitek.co.il
- **Email:** letstalk@soulitek.co.il

---

**Coded by:** SouliTEK  
*IT Solutions for your business*

(C) 2025 SouliTEK - All Rights Reserved











