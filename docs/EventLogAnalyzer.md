# Event Log Analyzer

## Overview

The **Event Log Analyzer** is an advanced tool for analyzing Windows Event Logs (Application, System, Security) to identify errors, warnings, and critical events. It's designed for IT professionals troubleshooting system issues and monitoring system health.

## Purpose

Provides comprehensive event log analysis:
- Error and warning detection
- Event filtering and searching
- Statistical summaries
- Trend analysis
- Export capabilities

## Features

### 📊 **Log Analysis**
- Analyze Application, System, and Security logs
- Filter by event level (Error, Warning, Critical)
- Search by event ID, source, or message
- Time range filtering

### 📈 **Statistics**
- Event count summaries
- Top event IDs
- Most common sources
- Time-based trends

### 🔍 **Advanced Filtering**
- Filter by specific Event IDs
- Filter by event source/provider
- Message content search
- Time range selection

### 📋 **Export Options**
- Export to CSV format
- Export to JSON format
- Combined or individual log exports
- Timestamped filenames

## Requirements

### System Requirements
- **OS:** Windows 8.1, Windows 10, Windows 11, or Windows Server 2016+
- **PowerShell:** Version 5.1 or higher
- **Privileges:** Administrator rights (required for Security log)
- **Event Logs:** Standard Windows event logs

## Usage

### Running the Script

1. **Launch from SouliTEK Launcher** (recommended)
   - Open the SouliTEK Launcher
   - Find "Event Log Analyzer" in the System category
   - Click the tool card to launch

2. **Run directly via PowerShell** (as Administrator):
   ```powershell
   .\scripts\EventLogAnalyzer.ps1
   ```

### Command Line Parameters

#### Basic Usage
```powershell
# Analyze last 24 hours (default)
.\EventLogAnalyzer.ps1

# Analyze last 48 hours
.\EventLogAnalyzer.ps1 -Hours 48

# Analyze specific time range
.\EventLogAnalyzer.ps1 -StartTime "2025-01-01 00:00:00" -EndTime "2025-01-02 00:00:00"

# Analyze only Application and System logs
.\EventLogAnalyzer.ps1 -LogNames "Application","System"

# Filter by specific Event IDs
.\EventLogAnalyzer.ps1 -EventIDs @(1000,1001,1002)

# Search by message content
.\EventLogAnalyzer.ps1 -MessageFilter "error"
```

#### Advanced Options
```powershell
# Include Information level events
.\EventLogAnalyzer.ps1 -IncludeInformation

# Include Audit Success events (Security log)
.\EventLogAnalyzer.ps1 -IncludeAuditSuccess

# Export individual logs to separate files
.\EventLogAnalyzer.ps1 -ExportIndividualLogs

# Compare with previous analysis
.\EventLogAnalyzer.ps1 -CompareWithBaseline "C:\path\to\previous.json"
```

### Menu Options (Interactive Mode)

#### Option 1: Quick Analysis
Analyzes last 24 hours for errors and warnings.
- Application, System, Security logs
- Error and Warning levels
- Summary statistics
- Quick overview

#### Option 2: Custom Time Range
Analyze specific time period.
- Enter start and end times
- Flexible date/time selection
- All log types
- Detailed results

#### Option 3: Filter by Event ID
Analyze specific event IDs.
- Enter event ID(s)
- Supports ranges (e.g., 1000-1005)
- Multiple IDs supported
- Focused analysis

#### Option 4: Search by Source
Filter by event source/provider.
- Enter source name(s)
- Multiple sources supported
- Case-insensitive search
- Source-specific analysis

#### Option 5: Export Results
Export analysis to files.
- CSV format (spreadsheet)
- JSON format (structured data)
- Both formats
- Desktop location

## Output Files

### Report Locations
- **Desktop:** Reports saved to `%USERPROFILE%\Desktop`
- **Formats:** CSV and JSON
- **Filename:** `EventLogAnalysis_YYYYMMDD_HHMMSS.[ext]`

### Report Contents
- Event summary statistics
- Detailed event list
- Top event IDs
- Most common sources
- Time range analyzed

## Common Event IDs

### Application Log
- **1000:** Application Error
- **1001:** Application Hang
- **1002:** Application Crash

### System Log
- **6008:** Unexpected shutdown
- **1074:** System shutdown initiated
- **6005:** Event log service started
- **6006:** Event log service stopped
- **41:** System reboot without clean shutdown

### Security Log
- **4624:** Successful logon
- **4625:** Failed logon attempt
- **4648:** Logon with explicit credentials
- **4672:** Special privileges assigned

## Troubleshooting

### Cannot Access Security Log
**Problem:** "Access denied" for Security log

**Solutions:**
1. Run as Administrator (required)
2. Check Group Policy settings
3. Verify Security log permissions
4. Check audit policy configuration

### Too Many Events
**Problem:** Analysis returns too many events

**Solutions:**
- Narrow time range
- Use specific Event ID filters
- Filter by source
- Use message content filter
- Increase minimum event level

### Export Fails
**Problem:** Cannot export results

**Solutions:**
1. Check disk space
2. Verify write permissions
3. Close file if already open
4. Check antivirus isn't blocking

### Performance Issues
**Problem:** Analysis is slow

**Causes:**
- Large time ranges
- Many events to process
- System performance

**Solutions:**
- Reduce time range
- Use filters to limit events
- Run during off-peak hours
- Close other applications

## Best Practices

### Regular Analysis
- Analyze logs weekly
- Monitor for critical events
- Track error trends
- Document recurring issues

### Filtering Strategy
- Start with broad analysis
- Narrow down with filters
- Use Event IDs for known issues
- Search messages for keywords

### Export and Archive
- Export important analyses
- Keep historical comparisons
- Document findings
- Create baseline comparisons

## Technical Details

### Log Sources
- **Application Log:** Application-level events
- **System Log:** System-level events
- **Security Log:** Security and audit events

### Event Levels
- **Critical:** Critical system events
- **Error:** Error conditions
- **Warning:** Warning conditions
- **Information:** Informational events
- **Verbose:** Detailed diagnostic events

### Performance
- Optimized for large log files
- Efficient event filtering
- Progress indicators
- Memory-efficient processing

## Support

For assistance or to report issues:
- **Website:** www.soulitek.co.il
- **Email:** letstalk@soulitek.co.il

---

**Coded by:** SouliTEK  
*IT Solutions for your business*

(C) 2025 SouliTEK - All Rights Reserved













