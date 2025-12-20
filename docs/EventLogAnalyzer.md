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
- Error percentage calculation
- Standard deviation of event counts
- Most common error Event IDs
- Most common error providers

### 🔍 **Advanced Filtering**
- Filter by specific Event IDs
- Filter by event source/provider
- Message content search
- Time range selection

### 📋 **Export Options**
- Export to CSV format (flat format for Excel compatibility)
- Export to JSON format
- Export to HTML format
- Export to CLIXML format (PowerShell native format for third-party analysis)
- Combined or individual log exports
- Timestamped filenames
- Automatic log cleanup (14-day retention)

### 🔄 **Automation**
- Scheduled task support for automatic analysis
- Configurable schedule (Daily, Weekly, Hourly)
- Automatic log/transcript cleanup
- Auto-run mode for scheduled executions

### 📝 **Logging**
- PowerShell transcript logging (built-in)
- Automatic cleanup of old transcripts
- Full session capture
- Error tracking and diagnostics

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

# Export to CLIXML format for third-party analysis
.\EventLogAnalyzer.ps1 -ExportClixml -ClixmlArchivePath "C:\Archives"

# Register scheduled task for daily automatic analysis
.\EventLogAnalyzer.ps1 -RegisterScheduledTask -TaskSchedule Daily -TaskTime "03:00"

# Configure log retention (default: 14 days)
.\EventLogAnalyzer.ps1 -LogRetentionDays 30
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

#### Option 12: Scheduled Task Setup
Register automatic daily analysis.
- Create Windows scheduled task
- Configure schedule (Daily, Weekly, Hourly)
- Set execution time
- Run as SYSTEM with highest privileges
- Automatic report generation

#### Option 13: Help
View usage guide and examples.

## Output Files

### Report Locations
- **Desktop:** Reports saved to `%USERPROFILE%\Desktop` (default)
- **Formats:** CSV, JSON, HTML, CLIXML
- **Filename:** `EventLogAnalysis_YYYYMMDD_HHMMSS.[ext]`
- **Transcripts:** `%TEMP%\SouliTEK-Scripts\EventLogAnalyzer\EventLogAnalyzer_Transcript_YYYYMMDD_HHMMSS.log`

### Report Contents
- Event summary statistics
- Detailed event list (flat CSV format for Excel)
- Top event IDs
- Most common sources
- Top error Event IDs
- Top error providers
- Statistical analysis (error percentage, standard deviation)
- Time range analyzed

### CLIXML Archive Format
- Full event objects preserved
- PowerShell native format
- Import with `Import-Clixml` for third-party analysis
- Includes all event properties and metadata
- Stored in `Archives` subfolder by default

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
- Use scheduled tasks for automated daily analysis

### Filtering Strategy
- Start with broad analysis
- Narrow down with filters
- Use Event IDs for known issues
- Search messages for keywords

### Export and Archive
- Export important analyses to CLIXML for long-term storage
- Keep historical comparisons
- Document findings
- Create baseline comparisons
- Use flat CSV format for executive reports

### Log Management
- Configure appropriate retention period (default: 14 days)
- Monitor transcript folder size
- Archive important transcripts before cleanup
- Use CLIXML format for third-party analysis tools

### Scheduled Tasks
- Set up daily analysis for critical systems
- Configure appropriate time (default: 3:00 AM)
- Monitor scheduled task execution
- Review exported reports regularly

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
- Automatic cleanup of old logs/transcripts
- Error handling with proper exception management

### Logging and Diagnostics
- PowerShell transcript logging (built-in feature)
- Full session capture
- Automatic cleanup based on retention period
- Error tracking and diagnostics
- Transcript files stored in `%TEMP%\SouliTEK-Scripts\EventLogAnalyzer\`

### Statistical Analysis
- Error percentage: `(TotalErrors / TotalEvents) * 100`
- Mean event count per log
- Standard deviation of event counts across logs
- Most common error Event ID identification
- Most common error provider identification

## Support

For assistance or to report issues:
- **Website:** www.soulitek.co.il
- **Email:** letstalk@soulitek.co.il

---

**Coded by:** SouliTEK  
*IT Solutions for your business*

(C) 2025 SouliTEK - All Rights Reserved

















