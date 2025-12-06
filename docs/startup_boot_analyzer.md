# Startup Boot Analyzer

## Overview

The **Startup Programs & Boot Time Analyzer** analyzes startup programs and boot performance to help identify optimization opportunities. It provides comprehensive analysis of what runs at startup and how it affects boot time.

## Purpose

Analyzes system startup and boot performance:
- Startup program detection
- Boot time analysis
- Performance impact rating
- Trend tracking
- Optimization recommendations

## Features

### 🚀 **Startup Analysis**
- Startup folder scanning
- Task Scheduler startup items
- Registry startup entries
- Auto-start services
- Boot impact assessment

### ⏱️ **Boot Time Analysis**
- Boot time measurement
- Historical boot time tracking
- Boot time trends
- Performance comparison

### 📊 **Performance Impact**
- Impact rating per program
- High/Medium/Low impact classification
- Known program database
- Category classification

### 📈 **Trend Tracking**
- Boot time history
- Performance trends
- Improvement tracking
- Historical comparison

### 📋 **Export Options**
- Export to HTML report
- Export to CSV format
- Detailed analysis reports
- Visual charts and graphs

## Requirements

### System Requirements
- **OS:** Windows 10 or Windows 11
- **PowerShell:** Version 5.1 or higher
- **Privileges:** Administrator rights (recommended for full analysis)
- **Event Logs:** Windows Event Log access

## Usage

### Running the Script

1. **Launch from SouliTEK Launcher** (recommended)
   - Open the SouliTEK Launcher
   - Find "Startup Boot Analyzer" in the System category
   - Click the tool card to launch

2. **Run directly via PowerShell** (as Administrator):
   ```powershell
   .\scripts\startup_boot_analyzer.ps1
   ```

### Menu Options

#### Option 1: Analyze Startup Programs
Scans all startup programs and services.
- Startup folder items
- Task Scheduler entries
- Registry startup items
- Auto-start services
- Impact ratings

#### Option 2: Measure Boot Time
Measures and tracks boot time.
- Current boot time
- Historical boot times
- Boot time trends
- Performance comparison

#### Option 3: View Boot History
Displays boot time history.
- Historical boot times
- Trend analysis
- Performance changes
- Improvement tracking

#### Option 4: Generate Report
Exports comprehensive analysis report.
- HTML format with charts
- CSV format for analysis
- Detailed program information
- Boot time statistics

## Startup Locations

### Startup Folders
- User startup folder
- All users startup folder
- Current user startup
- Common startup locations

### Task Scheduler
- Startup tasks
- Scheduled tasks at logon
- Trigger-based startups
- Task details

### Registry
- Run registry keys
- RunOnce registry keys
- User and system hives
- Startup entries

### Services
- Auto-start services
- Delayed auto-start services
- Service dependencies
- Service impact

## Performance Impact

### Impact Ratings
- **High Impact:** Significantly slows boot
- **Medium Impact:** Moderate boot delay
- **Low Impact:** Minimal boot impact
- **Unknown:** Impact not determined

### Known Programs Database
Tool includes database of common programs with known impact levels:
- OneDrive, Spotify, Teams
- Adobe products, Creative Cloud
- Communication apps
- Cloud storage services

## Boot Time Analysis

### Measurement Method
- Uses Windows Event Log
- Boot time calculation
- Historical tracking
- Trend analysis

### Boot Time Factors
- Hardware (SSD vs HDD)
- Number of startup programs
- Program impact levels
- System configuration

## Troubleshooting

### Boot Time Not Measured
**Problem:** Cannot measure boot time

**Solutions:**
1. Run as Administrator
2. Check Event Log access
3. Verify boot events are logged
4. Check system time is accurate

### Too Many Startup Programs
**Problem:** Many programs at startup

**Recommendations:**
- Disable unnecessary programs
- Use delayed startup for non-critical apps
- Remove unused startup items
- Optimize startup configuration

### Slow Boot Time
**Problem:** Boot time is very slow

**Solutions:**
1. Review startup programs
2. Disable high-impact programs
3. Check for malware
4. Upgrade to SSD if using HDD
5. Check system resources

## Best Practices

### Startup Optimization
- Disable unnecessary startup programs
- Use delayed startup for non-critical apps
- Keep essential services enabled
- Regular startup audits

### Boot Time Monitoring
- Monitor boot time regularly
- Track performance trends
- Identify degradation
- Document improvements

### Program Management
- Review startup programs monthly
- Remove unused programs
- Update programs regularly
- Monitor program impact

## Technical Details

### Data Sources
- Windows Event Log (boot events)
- Startup folder scanning
- Task Scheduler queries
- Registry queries
- Service enumeration

### Boot Time Calculation
- Event ID 6005 (Event log service started)
- Event ID 6006 (Event log service stopped)
- Boot duration calculation
- Historical tracking

## Output Files

### Report Locations
- **Desktop:** Reports saved to `%USERPROFILE%\Desktop`
- **Formats:** HTML and CSV
- **Filename:** `StartupAnalysis_YYYYMMDD_HHMMSS.[ext]`

### Report Contents
- Startup program list
- Impact ratings
- Boot time statistics
- Historical trends
- Optimization recommendations

## Support

For assistance or to report issues:
- **Website:** www.soulitek.co.il
- **Email:** letstalk@soulitek.co.il

---

**Coded by:** SouliTEK  
*IT Solutions for your business*

(C) 2025 SouliTEK - All Rights Reserved
















