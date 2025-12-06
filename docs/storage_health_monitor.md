# Storage Health Monitor

## Overview

The **Storage Health Monitor** monitors storage health by reading SMART data and warning about increasing reallocated sectors or read errors. It's designed for IT professionals monitoring disk health and preventing data loss.

## Purpose

Monitors storage device health:
- SMART data reading
- Reallocated sectors monitoring
- Read error detection
- Health status reporting
- Baseline comparison

## Features

### 💾 **SMART Data Reading**
- Reads SMART attributes
- Disk health indicators
- Temperature monitoring
- Power-on hours
- Error counts

### ⚠️ **Health Warnings**
- Reallocated sectors alerts
- Read error warnings
- Health degradation alerts
- Critical health status

### 📊 **Health Status**
- Overall health assessment
- Individual attribute status
- Trend analysis
- Baseline comparison

### 📈 **Trend Tracking**
- Historical SMART data
- Health degradation tracking
- Baseline establishment
- Performance trends

### 📋 **Export Options**
- Export health reports
- CSV format export
- Detailed SMART data
- Health recommendations

## Requirements

### System Requirements
- **OS:** Windows 10 or Windows 11
- **PowerShell:** Version 5.1 or higher
- **Privileges:** Administrator rights (required)
- **SMART Support:** Storage devices with SMART support

## Usage

### Running the Script

1. **Launch from SouliTEK Launcher** (recommended)
   - Open the SouliTEK Launcher
   - Find "Storage Health Monitor" in the Hardware category
   - Click the tool card to launch

2. **Run directly via PowerShell** (as Administrator):
   ```powershell
   .\scripts\storage_health_monitor.ps1
   ```

### Menu Options

#### Option 1: Scan All Drives
Scans all storage devices for health status.
- All connected drives
- SMART data reading
- Health assessment
- Warning detection

#### Option 2: Scan Specific Drive
Scans selected drive for detailed analysis.
- Select drive to scan
- Detailed SMART data
- Individual attributes
- Health status

#### Option 3: View Baseline
Compares current health to baseline.
- Baseline comparison
- Health changes
- Trend analysis
- Degradation detection

#### Option 4: Set Baseline
Establishes health baseline for comparison.
- Current health snapshot
- Baseline creation
- Future comparison reference
- Health tracking

#### Option 5: Export Health Report
Exports comprehensive health report.
- All drive health data
- SMART attributes
- Health recommendations
- CSV format export

## SMART Attributes

### Critical Attributes
- **Reallocated Sectors:** Bad sectors moved to spare area
- **Read Errors:** Unrecoverable read errors
- **Seek Errors:** Drive head positioning errors
- **Power-On Hours:** Total drive usage time

### Health Indicators
- **Temperature:** Drive operating temperature
- **Spin Retry Count:** Drive spin-up attempts
- **Power Cycle Count:** Power on/off cycles
- **Load Cycle Count:** Head load/unload cycles

## Health Status

### Status Levels
- **Healthy:** All attributes within normal range
- **Warning:** Some attributes showing degradation
- **Critical:** Significant health issues detected
- **Failed:** Drive failure imminent or occurred

### Warning Thresholds
- **Reallocated Sectors:** Increasing count indicates problems
- **Read Errors:** Any errors are concerning
- **Temperature:** High temperature reduces lifespan
- **Power-On Hours:** High hours indicate aging

## Troubleshooting

### Cannot Read SMART Data
**Problem:** Cannot read SMART attributes

**Solutions:**
1. Ensure running as Administrator
2. Check drive supports SMART
3. Verify drive is accessible
4. Some external drives don't support SMART
5. Check drive connection

### High Reallocated Sectors
**Problem:** Reallocated sectors increasing

**Actions:**
- **Immediate:** Backup data immediately
- **Monitor:** Track sector count increase
- **Replace:** Plan drive replacement
- **Critical:** Replace drive if count rising rapidly

### Read Errors Detected
**Problem:** Read errors in SMART data

**Actions:**
- **Backup:** Backup data immediately
- **Check:** Verify data integrity
- **Replace:** Plan drive replacement
- **Monitor:** Track error count

### High Temperature
**Problem:** Drive temperature too high

**Solutions:**
1. Improve ventilation
2. Check cooling system
3. Reduce drive load
4. Monitor temperature trends
5. Consider drive replacement if persistent

## Best Practices

### Regular Monitoring
- Scan drives monthly
- Monitor health trends
- Track attribute changes
- Document health status

### Baseline Management
- Set baseline after new drive installation
- Update baseline after significant changes
- Compare regularly to baseline
- Track degradation over time

### Data Protection
- Backup data regularly
- Replace drives showing degradation
- Monitor critical attributes
- Act on warnings promptly

### Drive Replacement
- Replace drives before failure
- Monitor reallocated sectors
- Track error rates
- Plan replacements proactively

## Technical Details

### SMART Data Access
- Uses WMI (Windows Management Instrumentation)
- Win32_DiskDrive class
- SMART attribute queries
- Drive health assessment

### Storage Locations
- **Baseline Data:** `%LOCALAPPDATA%\SouliTEK\StorageHealthBaseline.json`
- **Reports:** Desktop
- **Format:** JSON for baseline, CSV for reports

## Output Files

### Report Locations
- **Desktop:** Reports saved to `%USERPROFILE%\Desktop`
- **Format:** CSV
- **Filename:** `StorageHealthReport_YYYYMMDD_HHMMSS.csv`

### Report Contents
- Drive information
- SMART attributes
- Health status
- Recommendations
- Baseline comparison

## Support

For assistance or to report issues:
- **Website:** www.soulitek.co.il
- **Email:** letstalk@soulitek.co.il

---

**Coded by:** SouliTEK  
*IT Solutions for your business*

(C) 2025 SouliTEK - All Rights Reserved
















