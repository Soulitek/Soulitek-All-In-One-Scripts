# BSOD History Scanner - Documentation

## Overview

The BSOD History Scanner is a diagnostic tool that scans for Blue Screen of Death (BSOD) history by analyzing Minidump files and System event logs. It provides detailed information about when blue screens occurred and what error codes (BugCheck codes) were generated.

**Version:** 1.0.0  
**Category:** Support  
**Requires Admin:** Recommended (for full event log access)

---

## Features

### 1. **Dual-Source Scanning**
   - **Minidump Files:** Scans `C:\Windows\Minidump` for `.dmp` files
   - **Event Logs:** Checks System event log for BugCheck events (Event ID 1001)
   - Combines data from both sources for comprehensive history

### 2. **BugCheck Code Identification**
   - Extracts BugCheck codes from event logs
   - Provides human-readable descriptions for common error codes
   - Supports 30+ common BugCheck codes including:
     - `0x0000000A` - IRQL_NOT_LESS_OR_EQUAL
     - `0x0000003B` - SYSTEM_SERVICE_EXCEPTION
     - `0x00000050` - PAGE_FAULT_IN_NONPAGED_AREA
     - `0x000000D1` - DRIVER_IRQL_NOT_LESS_OR_EQUAL
     - `0x00000124` - WHEA_UNCORRECTABLE_ERROR (Hardware)
     - `0x00000133` - DPC_WATCHDOG_VIOLATION
     - And more...

### 3. **Detailed BSOD Information**
   - Timestamp of each BSOD occurrence
   - BugCheck code and description
   - Source (Minidump file or Event Log)
   - File size and path (for Minidump files)
   - BugCheck parameters (when available)

### 4. **Export Capabilities**
   - Export to **TXT** format (text report)
   - Export to **CSV** format (spreadsheet)
   - Export to **HTML** format (formatted report)
   - All formats include timestamps, codes, descriptions, and file information

---

## Usage

### Main Menu Options

1. **Full Scan** - Scans both Minidump files and event logs
2. **View Last BSOD** - Shows the most recent blue screen with detailed information
3. **View All Results** - Displays all BSOD records found
4. **Export Results** - Export scan results to file
5. **Help** - Usage guide and information
0. **Exit** - Exit the tool (with self-destruct)

### Running a Scan

1. Launch the tool from the SouliTEK Launcher
2. Select option **1** for Full Scan
3. Wait for the scan to complete
4. Review the results displayed on screen
5. Use option **2** to view the last BSOD in detail
6. Use option **4** to export results if needed

---

## Technical Details

### Minidump Files

- **Location:** `C:\Windows\Minidump`
- **File Extension:** `.dmp`
- **Information Extracted:**
  - File name and path
  - Last write time (BSOD timestamp)
  - File size
  - Note: Detailed BugCheck code extraction from dump files requires WinDbg

### Event Log Analysis

- **Log Name:** System
- **Event ID:** 1001 (BugCheck)
- **Information Extracted:**
  - BugCheck code (from param1)
  - BugCheck parameters (param2-param5)
  - Event timestamp
  - Full event details

### BugCheck Code Format

BugCheck codes are displayed in hexadecimal format (e.g., `0x0000000A`). The tool automatically:
- Formats codes with proper `0x` prefix
- Converts decimal codes to hexadecimal
- Maps codes to human-readable descriptions

---

## Common BugCheck Codes

| Code | Description | Common Causes |
|------|-------------|---------------|
| `0x0000000A` | IRQL_NOT_LESS_OR_EQUAL | Driver or hardware issue |
| `0x0000003B` | SYSTEM_SERVICE_EXCEPTION | Driver or system service error |
| `0x00000050` | PAGE_FAULT_IN_NONPAGED_AREA | Memory corruption, bad RAM |
| `0x000000D1` | DRIVER_IRQL_NOT_LESS_OR_EQUAL | Faulty driver |
| `0x00000124` | WHEA_UNCORRECTABLE_ERROR | Hardware failure (CPU, RAM, etc.) |
| `0x00000133` | DPC_WATCHDOG_VIOLATION | Driver timeout, hardware issue |
| `0x00000139` | KERNEL_SECURITY_CHECK_FAILURE | Memory corruption, driver issue |

---

## Requirements

- **Operating System:** Windows 10/11
- **PowerShell Version:** 5.1 or higher
- **Privileges:** Administrator (recommended for full event log access)
- **Disk Space:** Minimal (only reads existing files)

---

## Limitations

1. **Minidump Analysis:** The tool identifies Minidump files and their timestamps but does not perform deep analysis of dump file contents. For detailed analysis, use WinDbg or other debugging tools.

2. **Event Log History:** Results depend on event log retention settings. Older events may have been overwritten.

3. **Cleaned Files:** If Minidump files have been deleted or cleaned up, only event log entries will be available.

4. **Unknown Codes:** BugCheck codes not in the mapping will show as "UNKNOWN_ERROR". You can look up these codes online for more information.

---

## Export Formats

### TXT Format
- Plain text report
- Includes header with scan information
- Lists all BSOD records with timestamps and codes
- Suitable for quick reference

### CSV Format
- Spreadsheet-compatible format
- Columns: Timestamp, BugCheckCode, BugCheckDescription, Source, FileName, FileSize, BugCheckParams
- Can be opened in Excel, Google Sheets, etc.
- Suitable for data analysis

### HTML Format
- Formatted report with SouliTEK branding
- Color-coded information
- Professional appearance
- Suitable for documentation and reports

---

## Troubleshooting

### No BSOD History Found

If the scan finds no results, it could mean:
- The system has never experienced a blue screen
- Minidump files have been cleaned up
- Event log entries have been cleared
- Minidump directory doesn't exist (normal if no BSODs occurred)

### Cannot Access Event Log

If you get an error accessing the System event log:
- Run the tool as Administrator
- Check that the System event log exists and is accessible
- Verify Windows Event Log service is running

### Minidump Directory Not Found

If the Minidump directory doesn't exist:
- This is normal if no BSODs have occurred
- Windows creates the directory automatically when a BSOD happens
- The tool will still check event logs for BugCheck events

---

## Integration

- **Launcher Category:** Support
- **Script Path:** `scripts/bsod_history_scanner.ps1`
- **Self-Destruct:** Enabled (script removes itself after execution)

---

## Best Practices

1. **Run as Administrator:** For full access to event logs
2. **Regular Scans:** Check BSOD history periodically to identify recurring issues
3. **Export Results:** Save reports for documentation and troubleshooting
4. **Compare History:** Track BSOD frequency to identify patterns
5. **Use with Event Log Analyzer:** Combine with EventLogAnalyzer for comprehensive system diagnostics

---

## Related Tools

- **Event Log Analyzer:** Comprehensive Windows event log analysis
- **Storage Health Monitor:** Check for hardware issues that might cause BSODs
- **Driver Integrity Scan:** Identify driver problems that could lead to BSODs

---

## Support

For issues, questions, or feature requests:
- **Website:** www.soulitek.co.il
- **Email:** letstalk@soulitek.co.il

---

**Copyright:** (C) 2025 SouliTEK - All Rights Reserved




