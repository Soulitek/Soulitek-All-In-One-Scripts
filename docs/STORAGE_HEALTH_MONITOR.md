# Storage Health Monitor - Documentation

## Overview

The Storage Health Monitor is a professional PowerShell tool that monitors storage device health by reading SMART (Self-Monitoring, Analysis and Reporting Technology) data. It detects reallocated sectors and read errors, providing early warning signs of potential disk failure.

## Features

### SMART Data Reading
- Reads SMART attributes via `Get-PhysicalDisk` and `Get-StorageReliabilityCounter`
- Attempts to access SMART data through Windows Management Instrumentation (WMI)
- Displays comprehensive storage health information

### Health Monitoring
- **Reallocated Sectors**: Monitors bad sectors that have been replaced by spare sectors
- **Read Errors**: Tracks data read failures
- **Temperature**: Displays drive temperature (if available)
- **Power-On Hours**: Shows total operating time
- **Power Cycles**: Displays number of power-on/power-off cycles
- **Wear Level**: For SSDs, shows wear percentage (if available)

### Warning System
- **CRITICAL**: Immediate attention required
  - Reallocated sectors > 100
  - Read errors > 100
  - Health status: Unhealthy
- **WARNING**: Monitor closely
  - Reallocated sectors > 10
  - Read errors > 10
  - Health status: Warning
- **OK**: No issues detected
  - Reallocated sectors ≤ 10
  - Read errors ≤ 10
  - Health status: Healthy

### Export Functionality
- **TXT Format**: Human-readable text report
- **CSV Format**: Spreadsheet-compatible data export
- **HTML Format**: Professional web report with modern styling

## Usage

### Launching the Tool

1. **From GUI Launcher:**
   - Open SouliTEK Launcher
   - Click on "Storage Health Monitor"
   - Click "Launch"

2. **From PowerShell:**
   ```powershell
   cd C:\SouliTEK\scripts
   .\storage_health_monitor.ps1
   ```

3. **Direct Execution:**
   ```powershell
   .\scripts\storage_health_monitor.ps1
   ```

### Main Menu Options

1. **View Storage Health Report**
   - Scans all physical disks
   - Displays SMART data for each disk
   - Shows warnings and alerts
   - Color-coded health status

2. **Export Report - TXT Format**
   - Creates a text file on Desktop
   - Filename: `StorageHealthReport_YYYYMMDD_HHMMSS.txt`
   - Human-readable format

3. **Export Report - CSV Format**
   - Creates a CSV file on Desktop
   - Filename: `StorageHealthReport_YYYYMMDD_HHMMSS.csv`
   - Suitable for spreadsheet analysis

4. **Export Report - HTML Format**
   - Creates an HTML file on Desktop
   - Filename: `StorageHealthReport_YYYYMMDD_HHMMSS.html`
   - Professional web report with styling

5. **Export Report - All Formats**
   - Exports reports in all three formats simultaneously

6. **Help & Information**
   - Displays comprehensive help and documentation

7. **Exit**
   - Closes the tool

## Requirements

### System Requirements
- Windows PowerShell 5.1 or later
- Windows 10/11 or Windows Server 2016+
- Administrator privileges (recommended for full functionality)

### Storage Requirements
- Physical storage devices (HDD/SSD)
- SMART-enabled drives (most modern drives support SMART)
- Internal drives (USB/external drives may have limited SMART data)

## Understanding SMART Data

### What is SMART?

SMART (Self-Monitoring, Analysis and Reporting Technology) is a monitoring system built into hard drives and solid-state drives. It tracks various parameters that can indicate potential drive failure.

### Key Metrics

1. **Reallocated Sectors**
   - When a sector becomes unreliable, the drive marks it as bad and uses a spare sector instead
   - A small number is normal due to manufacturing variations
   - Increasing numbers indicate deteriorating drive health
   - Critical threshold: > 100 sectors

2. **Read Errors**
   - Counts the number of times data could not be read correctly
   - Occasional errors may be normal (especially with bad cables)
   - Increasing errors indicate hardware problems
   - Critical threshold: > 100 errors

3. **Health Status**
   - **Healthy**: Drive is functioning normally
   - **Warning**: Some issues detected, monitor closely
   - **Unhealthy**: Drive is failing, backup data immediately

### Interpreting Results

#### Good Health
- Health Status: Healthy
- Reallocated Sectors: 0-10
- Read Errors: 0-10
- Operational Status: OK

#### Warning Signs
- Health Status: Warning
- Reallocated Sectors: 11-100
- Read Errors: 11-100
- Operational Status: Degraded

#### Critical Issues
- Health Status: Unhealthy
- Reallocated Sectors: > 100
- Read Errors: > 100
- Operational Status: Failed or Degraded

**Action Required**: Immediately backup all data and replace the drive

## Limitations

### Windows API Limitations
- Not all storage devices expose full SMART data via Windows APIs
- Some metrics may show "Not available" for certain disk types
- USB and external drives may have limited or no SMART data
- RAID controllers may not expose individual drive SMART data

### Vendor-Specific Tools
- Some vendors (Seagate, Western Digital, Samsung) provide proprietary tools with more detailed SMART data
- For maximum detail, consider using vendor-specific diagnostic tools in addition to this tool

### Drive Support
- Older drives may not support SMART
- Some USB enclosures don't pass through SMART data
- Virtual drives don't have SMART data

## Troubleshooting

### "No physical disks found"
- Ensure you're running with Administrator privileges
- Check if you have physical disks installed
- USB drives may be filtered (by design)

### "Not available" for SMART attributes
- The drive may not support that specific attribute
- Windows may not have access to that attribute
- Try running with Administrator privileges
- Some attributes are only available on SSDs (e.g., Wear Level)

### Limited data for external drives
- USB and external drives often have limited SMART data exposure
- Consider using the drive internally for full SMART access
- Some USB-to-SATA adapters don't pass through SMART commands

### False positives
- Small numbers of reallocated sectors (1-10) are often normal
- Manufacturing variations can cause initial sector reallocation
- Monitor trends rather than absolute numbers
- Compare with known-good drives of the same model

## Best Practices

### Regular Monitoring
- Check storage health monthly
- Monitor trends over time (increasing values are concerning)
- Compare results between drives

### Action Thresholds
- **1-10 reallocated sectors**: Normal, continue monitoring
- **11-100 reallocated sectors**: Warning, backup data, plan replacement
- **> 100 reallocated sectors**: Critical, backup immediately, replace drive

### Data Backup
- Always maintain backups of important data
- When warnings appear, increase backup frequency
- When critical issues appear, backup immediately

### Drive Replacement
- Replace drives showing consistent warnings
- Don't wait for complete failure
- Keep spare drives for critical systems

## Examples

### Example 1: Healthy Drive
```
Disk: Samsung SSD 970 EVO 500GB
Device ID: 0
Media Type: SSD
Size: 500.1 GB
Health Status: Healthy
Operational Status: OK
Reallocated Sectors: 0
Read Errors: 0
Temperature: 45C
Power-On Hours: 8760 (365 days)
Power Cycles: 120
Wear Level: 2%
Warning Level: OK
```

### Example 2: Warning Drive
```
Disk: WD Blue 1TB
Device ID: 1
Media Type: HDD
Size: 1000.2 GB
Health Status: Warning
Operational Status: OK
Reallocated Sectors: 45
Read Errors: 8
Temperature: 38C
Power-On Hours: 17520 (730 days)
Power Cycles: 250
Warning Level: WARNING
```

### Example 3: Critical Drive
```
Disk: Seagate Barracuda 2TB
Device ID: 2
Media Type: HDD
Size: 2000.4 GB
Health Status: Unhealthy
Operational Status: Degraded
Reallocated Sectors: 234
Read Errors: 156
Temperature: 42C
Power-On Hours: 26280 (1095 days)
Power Cycles: 380
Warning Level: CRITICAL
```

## Support

### Website
- www.soulitek.co.il

### Email
- letstalk@soulitek.co.il

### GitHub
- https://github.com/Soulitek/Soulitek-All-In-One-Scripts

## Technical Details

### PowerShell Cmdlets Used
- `Get-PhysicalDisk`: Retrieves physical disk information
- `Get-StorageReliabilityCounter`: Accesses SMART reliability counters
- `Get-WmiObject`: Attempts to read WMI SMART status

### Data Sources
1. **Get-PhysicalDisk**: Basic disk information, health status
2. **Get-StorageReliabilityCounter**: Detailed SMART attributes
3. **WMI MSStorageDriver_FailurePredictStatus**: Failure prediction status

### Warning Logic
- Combines multiple data sources for comprehensive monitoring
- Sets warning levels based on thresholds
- Aggregates warnings from all drives

## Version History

- **v1.0.0** (2025-10-30): Initial release
  - SMART data reading via Get-PhysicalDisk and StorageReliabilityCounter
  - Reallocated sectors and read errors monitoring
  - Multiple export formats (TXT, CSV, HTML)
  - Warning system with thresholds

## License

(C) 2025 Soulitek - All Rights Reserved

This tool is provided "AS IS" without warranty of any kind. Use at your own risk.

