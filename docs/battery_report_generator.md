# Battery Report Generator

## Overview

The **Battery Report Generator** is a comprehensive tool for analyzing battery health and performance on laptops and portable devices. It generates detailed reports about battery capacity, usage history, and energy consumption patterns.

## Purpose

Provides IT professionals and users with detailed battery diagnostics including:
- Battery capacity and health status
- Usage history and charge cycles
- Energy consumption reports
- Sleep study analysis
- Historical battery data

## Features

### 🔋 **Battery Health Analysis**
- Current battery capacity vs. design capacity
- Battery wear level and health percentage
- Charge cycle count
- Battery status (charging, discharging, critical)

### 📊 **Usage Reports**
- **Basic Report**: Quick overview of battery status
- **Detailed Analysis**: Comprehensive battery information
- **Health Check**: Battery wear and capacity analysis
- **Sleep Study**: System sleep/wake behavior analysis
- **Energy Report**: Power consumption patterns

### 📈 **Historical Data**
- Tracks battery capacity over time
- Monitors degradation trends
- Identifies performance issues

## Requirements

### System Requirements
- **OS:** Windows 10 or Windows 11
- **PowerShell:** Version 5.1 or higher
- **Device:** Laptop or portable device with battery
- **Privileges:** Standard user (no admin required for most features)

## Usage

### Running the Script

1. **Launch from SouliTEK Launcher** (recommended)
   - Open the SouliTEK Launcher
   - Find "Battery Report Generator" in the Hardware category
   - Click the tool card to launch

2. **Run directly via PowerShell:**
   ```powershell
   .\scripts\battery_report_generator.ps1
   ```

### Menu Options

#### Option 1: Generate Basic Report
Creates a quick battery status overview.
- Current charge level
- Battery capacity
- Power state
- Estimated runtime

#### Option 2: Generate Detailed Analysis
Comprehensive battery information report.
- Full battery specifications
- Design vs. full charge capacity
- Charge cycle count
- Battery wear percentage
- Power usage statistics

#### Option 3: Battery Health Check
Analyzes battery health and wear.
- Capacity degradation
- Health percentage
- Charge cycle analysis
- Recommendations

#### Option 4: Sleep Study Report
Analyzes system sleep/wake behavior.
- Sleep duration statistics
- Wake source analysis
- Power consumption during sleep
- Battery drain patterns

#### Option 5: Energy Report
Detailed energy consumption analysis.
- Power usage by component
- Energy efficiency metrics
- Battery drain sources
- Optimization recommendations

## Output Files

### Report Locations
- **Desktop:** Reports saved to `%USERPROFILE%\Desktop`
- **Format:** HTML and TXT formats
- **Filename:** `BatteryReport_YYYYMMDD_HHMMSS.html`

### Report Contents
- Battery specifications
- Capacity information
- Usage statistics
- Health metrics
- Recommendations

## Technical Details

### Data Sources
- Windows `powercfg` utility
- Battery hardware information
- System power management data
- Event logs (for sleep study)

### Report Generation
Uses Windows built-in `powercfg /batteryreport` command to generate comprehensive battery analysis reports.

## Troubleshooting

### No Battery Detected
**Problem:** Tool reports "No battery found"

**Solutions:**
- Ensure device has a battery (desktop PCs won't have one)
- Check battery is properly connected
- Verify battery drivers are installed

### Report Generation Fails
**Problem:** Cannot generate battery report

**Solutions:**
1. Run PowerShell as Administrator
2. Check `powercfg` is available: `powercfg /?`
3. Verify battery drivers are up to date
4. Check Windows Event Viewer for power-related errors

### Inaccurate Capacity Readings
**Problem:** Battery capacity seems incorrect

**Causes:**
- Battery calibration needed
- Old battery with degraded cells
- Driver issues

**Solutions:**
- Run Windows battery calibration
- Update battery drivers
- Check manufacturer's battery health tool

## Best Practices

### Regular Monitoring
- Run health check monthly
- Monitor capacity trends
- Track charge cycle count

### Battery Maintenance
- Keep battery between 20-80% charge when possible
- Avoid complete discharge
- Don't leave laptop plugged in constantly
- Store at 50% charge if not using for extended periods

### When to Replace
- Health below 50%
- Significant capacity loss
- Frequent unexpected shutdowns
- Battery swelling or physical damage

## Support

For assistance or to report issues:
- **Website:** www.soulitek.co.il
- **Email:** letstalk@soulitek.co.il

---

**Coded by:** SouliTEK  
*IT Solutions for your business*

(C) 2025 SouliTEK - All Rights Reserved













