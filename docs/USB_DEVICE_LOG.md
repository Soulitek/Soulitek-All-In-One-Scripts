# USB Device Log - Forensic Tool

## Overview

The **USB Device Log** is a professional forensic tool designed for IT professionals, security analysts, and system administrators to investigate USB device connection history on Windows systems. This tool provides comprehensive analysis of USB storage devices that have been connected to a computer, making it invaluable for security audits, incident response, and compliance verification.

## Features

### 🔍 Comprehensive Analysis
- **Registry Analysis**: Scans USBSTOR and USB registry keys for device history
- **Event Log Review**: Analyzes USB-related events from the past 30 days
- **SetupAPI Log**: Checks Windows SetupAPI device installation logs
- **Forensic Details**: Extracts VID, PID, serial numbers, and connection timestamps

### 📊 Device Information Collected
- Device Name & Friendly Name
- Vendor Information
- Product Information
- Serial Number (Unique Identifier)
- VID (Vendor ID) & PID (Product ID)
- Device Type & Revision
- Installation Date
- Last Connected Date (when available)
- Device Status
- Registry Path

### 📤 Export Capabilities
- **Text Report (.txt)**: Human-readable forensic report
- **CSV File (.csv)**: Spreadsheet format for analysis
- **HTML Report (.html)**: Professional web-based report with styling
- **All Formats**: Export to all three formats simultaneously

### 🎨 Professional Interface
- Color-coded console output for easy interpretation
- Menu-driven interface for ease of use
- Real-time progress indicators
- Professional Soulitek branding
- Detailed help guide included

## System Requirements

- **Operating System**: Windows 8.1, 10, 11, Server 2016+
- **PowerShell**: Version 5.1 or higher
- **Privileges**: Administrator rights recommended (tool works with limited access but may have incomplete data)
- **Permissions**: Read access to registry and event logs

## Installation

1. Download the script to your desired location:
   ```
   C:\Tools\usb_device_log.ps1
   ```

2. No additional installation required - this is a standalone PowerShell script.

## Usage

### Running the Tool

#### Option 1: Right-click Method (Recommended)
1. Right-click on `usb_device_log.ps1`
2. Select "Run with PowerShell"
3. Accept the disclaimer
4. Follow the menu prompts

#### Option 2: PowerShell Console
1. Open PowerShell as Administrator
2. Navigate to the script directory:
   ```powershell
   cd C:\Path\To\Scripts
   ```
3. Run the script:
   ```powershell
   .\usb_device_log.ps1
   ```

#### Option 3: From Anywhere
```powershell
powershell.exe -ExecutionPolicy Bypass -File "C:\Path\To\usb_device_log.ps1"
```

### Menu Options

The tool provides a simple menu interface:

```
[1] USB Device Analysis  - Scan device history
[2] Export Report        - Save results to file
[3] Help                 - Usage guide
[0] Exit
```

## Workflow

### 1. USB Device Analysis

This comprehensive scan performs three stages:

#### Stage 1: Registry Analysis
- Scans `HKLM:\SYSTEM\CurrentControlSet\Enum\USBSTOR`
- Parses device type, vendor, product information
- Extracts serial numbers (unique identifiers)
- Retrieves installation dates and device status
- Attempts to correlate VID/PID from USB registry

#### Stage 2: Event Log Analysis
- Queries `Microsoft-Windows-DriverFrameworks-UserMode/Operational` log
- Searches for Event IDs: 2003, 2100, 2101, 2102, 2105, 2106
- Queries `System` log for USB-related events
- Collects events from the past 30 days
- Provides connection/disconnection timestamps

#### Stage 3: SetupAPI Device Log
- Checks `C:\Windows\inf\setupapi.dev.log`
- Counts USB-related installation entries
- Provides log availability status

#### Results Display
After analysis, the tool displays:
- Computer name and analysis timestamp
- Total USB devices found
- USB events count (30 days)
- SetupAPI entries count
- Detailed device information for each device

### 2. Export Report

After running an analysis, you can export results in multiple formats:

#### Text Report (.txt)
- Formatted text document
- Human-readable layout
- Includes all device details
- Opens automatically in Notepad after export

#### CSV File (.csv)
- Spreadsheet-compatible format
- Columns: DeviceName, Vendor, Product, SerialNumber, VID, PID, etc.
- Ideal for data analysis and filtering
- Opens automatically in default spreadsheet application

#### HTML Report (.html)
- Professional web-based report
- Modern, responsive design
- Color-coded device status
- Summary statistics
- Opens automatically in default web browser

#### All Formats
- Exports to all three formats simultaneously
- All files share the same timestamp
- Saved to Desktop by default

### 3. Help Guide

Comprehensive help documentation including:
- Feature explanations
- Forensic use cases
- Data interpretation guide
- Administrator privilege information
- Troubleshooting tips

## Forensic Use Cases

### 1. Security Incident Response
- **Identify Unauthorized Devices**: Discover USB devices that shouldn't be connected
- **Data Exfiltration Investigation**: Track potential data theft via USB
- **Audit Device Access**: Review complete history of USB connections
- **Timeline Reconstruction**: Establish when devices were connected

### 2. Compliance & Policy Enforcement
- **Approved Device Verification**: Confirm only authorized USB devices are used
- **Policy Violation Detection**: Identify non-compliant device usage
- **Audit Report Generation**: Create compliance documentation
- **Regular Security Audits**: Schedule periodic USB device reviews

### 3. IT Troubleshooting
- **Device Installation History**: Review when and how devices were installed
- **Driver Issue Identification**: Find problematic device drivers
- **Configuration Problems**: Diagnose USB-related system issues
- **User Support**: Verify device connection claims

### 4. Legal/HR Investigations
- **Evidence Collection**: Document USB device usage
- **Policy Violation Documentation**: Provide proof of unauthorized access
- **Employee Activity Tracking**: Investigate suspicious behavior
- **Court-Admissible Reports**: Generate professional forensic reports

## Data Interpretation

### Serial Number
- **Unique Identifier**: Each physical USB device has a unique serial number
- **Device Tracking**: Same device will always show the same serial number
- **Multiple Computers**: Track if a device has been used on multiple systems
- **Note**: Some cheap/generic devices may share serial numbers

### VID/PID (Vendor ID / Product ID)
- **VID**: 4-digit hexadecimal code identifying the manufacturer
- **PID**: 4-digit hexadecimal code identifying the specific product model
- **Lookup**: Can be searched in online databases (e.g., devicehunt.com, the-sz.com/products/usbid)
- **Example**: VID_0781 & PID_5567 = SanDisk Cruzer Blade

### Device Status
- **Working Properly**: Device is configured correctly
- **Disabled**: Device has been manually disabled
- **Problem (ConfigFlags: 0xXX)**: Device has configuration issues
- **Unknown**: Status could not be determined

### Last Connected
- **Date/Time**: When the device was last connected (if available)
- **Unknown**: Registry doesn't always store disconnection time
- **Limitation**: Windows doesn't reliably track last connection for all devices
- **Workaround**: Use Event Log analysis for more accurate timestamps

### Install Date
- **First Connection**: Date when device was first installed on the system
- **Driver Installation**: When Windows first configured the device
- **Note**: May differ from first actual use

## Output File Naming

All exported files use the following naming convention:
```
USB_Device_Report_YYYYMMDD_HHMMSS.[ext]
```

Example:
```
USB_Device_Report_20251023_143025.txt
USB_Device_Report_20251023_143025.csv
USB_Device_Report_20251023_143025.html
```

## Administrator Privileges

### Why Administrator Rights?

The tool requires elevated privileges to:
- Read protected registry keys (HKLM:\SYSTEM)
- Query security-sensitive event logs
- Access SetupAPI device logs
- Retrieve complete device information

### Running Without Admin Rights

The tool will still function with limited access, but:
- Some registry keys may be inaccessible
- Event log queries may fail
- Device information may be incomplete
- A warning will be displayed

### How to Run as Administrator

**Method 1**: Right-click PowerShell
1. Search for "PowerShell" in Start Menu
2. Right-click "Windows PowerShell"
3. Select "Run as Administrator"
4. Navigate to script and run

**Method 2**: Command Line
```powershell
Start-Process powershell -Verb RunAs -ArgumentList "-File 'C:\Path\To\usb_device_log.ps1'"
```

## Sample Output

### Console Output Example
```
============================================================
  USB DEVICE LOG - FORENSIC TOOL
============================================================

[14:25:10] [*] Starting comprehensive USB device analysis...

============================================================
  STAGE 1: Registry Analysis
============================================================

[14:25:11] [*] Scanning USBSTOR registry...
[14:25:13] [+] Found 5 USB storage devices in registry

============================================================
  STAGE 2: Event Log Analysis
============================================================

[14:25:13] [*] Scanning Event Logs for USB activity...
[14:25:15] [+] Found 23 USB-related events (last 30 days)

============================================================
  STAGE 3: SetupAPI Device Log
============================================================

[14:25:15] [*] Checking SetupAPI device log...
[14:25:15] [+] Found 47 USB-related entries in SetupAPI log

============================================================
  ANALYSIS SUMMARY
============================================================

Computer Name: DESKTOP-IT-01
Analysis Date: 2025-10-23 14:25:15

Total USB Devices Found: 5
USB Events (30 days): 23
SetupAPI Entries: 47

============================================================
  USB DEVICE DETAILS
============================================================

[1] SanDisk Cruzer Blade USB Device
    Vendor: SanDisk
    Product: Cruzer Blade
    Serial Number: 4C531001234567890123
    VID/PID: 0781 / 5567
    Type: Disk
    Status: Working Properly
    Install Date: 2025-09-15 10:32:00
    Last Connected: 2025-10-20 15:45:00

[2] Kingston DataTraveler 3.0 USB Device
    Vendor: Kingston
    Product: DataTraveler 3.0
    Serial Number: 60A44C4136DCF4D11234567
    VID/PID: 0951 / 1666
    Type: Disk
    Status: Working Properly
    Install Date: 2025-08-22 09:15:30
    Last Connected: Unknown
```

### HTML Report Preview
The HTML report features:
- Professional gradient header
- Summary statistics cards
- Color-coded device status
- Grid layout for device information
- Modern, responsive design
- Soulitek branding footer

## Troubleshooting

### No Devices Found

**Possible Reasons**:
- No USB devices have been connected
- Registry has been cleaned by maintenance tools
- Insufficient permissions
- Running without administrator rights

**Solutions**:
1. Run as Administrator
2. Check if USB ports are enabled in BIOS
3. Verify registry keys exist manually
4. Check Group Policy restrictions

### Event Log Errors

**Issue**: "Event log not available" or "No events found"

**Solutions**:
1. Ensure Windows Event Log service is running
2. Run as Administrator
3. Check Event Log size limits
4. Verify event logs haven't been cleared

### Access Denied Errors

**Issue**: "Access denied" or "Permission denied"

**Solutions**:
1. Run PowerShell as Administrator
2. Check user account permissions
3. Verify UAC settings
4. Ensure Windows Event Log service is accessible

### Export Failures

**Issue**: Files not saving or opening errors

**Solutions**:
1. Check disk space on Desktop
2. Ensure Desktop folder is accessible
3. Verify file permissions
4. Close any open reports with same filename
5. Try exporting to a different location (modify script variable)

## Security Considerations

### Data Sensitivity
- USB device logs contain forensic evidence
- Serial numbers can identify physical devices
- Connection timestamps reveal user activity
- Handle exported reports securely

### Best Practices
1. **Secure Storage**: Store reports in encrypted locations
2. **Access Control**: Limit access to forensic data
3. **Data Retention**: Follow organizational retention policies
4. **Authorization**: Only run on systems you're authorized to investigate
5. **Chain of Custody**: Document who accessed forensic data and when

### Privacy Notice
This tool collects system information including:
- USB device identifiers
- Connection timestamps
- Device serial numbers
- Registry metadata

Use only with proper authorization and in compliance with applicable laws and organizational policies.

## Technical Details

### Registry Keys Analyzed
- `HKLM:\SYSTEM\CurrentControlSet\Enum\USBSTOR`
  - Contains USB storage device information
  - Organized by device type, vendor, product
  - Includes serial numbers as instance keys

- `HKLM:\SYSTEM\CurrentControlSet\Enum\USB`
  - Contains USB device VID/PID information
  - Links to USBSTOR entries via ParentIdPrefix

### Event Logs Queried
- `Microsoft-Windows-DriverFrameworks-UserMode/Operational`
  - Event IDs: 2003, 2100, 2101, 2102, 2105, 2106
  - USB device connection/disconnection events

- `System`
  - Event IDs: 20001, 20003, 10000, 10100
  - USB-related system events

### File Locations
- **SetupAPI Log**: `C:\Windows\inf\setupapi.dev.log`
- **Export Location**: `%USERPROFILE%\Desktop` (Desktop)
- **Script Location**: User-defined

## Limitations

1. **Last Connected Timestamp**: Not always available in registry
2. **Event Log Retention**: Events older than 30 days may be unavailable
3. **Non-Storage Devices**: Focuses primarily on USB storage devices
4. **Registry Cleaning**: Third-party tools may remove USB history
5. **Device Removal**: Physical device removal doesn't delete registry entries

## Advanced Usage

### Changing Export Location

Edit the script variable:
```powershell
$Script:OutputFolder = "C:\Forensics\Reports"
```

### Automated Scanning

Create a scheduled task to run the tool automatically:
```powershell
$action = New-ScheduledTaskAction -Execute 'PowerShell.exe' `
  -Argument '-File "C:\Tools\usb_device_log.ps1"'
$trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Monday -At 9am
Register-ScheduledTask -Action $action -Trigger $trigger `
  -TaskName "USB Device Audit" -Description "Weekly USB device scan"
```

### Integration with SIEM

Export CSV files can be imported into SIEM systems for:
- Centralized logging
- Automated alerting
- Trend analysis
- Correlation with other security events

## Support

For support, questions, or feedback:

- **Website**: https://www.soulitek.co.il
- **Company**: Soulitek - IT Solutions
- **Services**: Computer Repair, Network Setup, IT Consulting, Security Audits

## License

(C) 2025 Soulitek - All Rights Reserved

This tool is provided "AS IS" without warranty of any kind. Use at your own risk.

## Version History

### Version 1.0.0 (2025-10-23)
- Initial release
- Registry analysis (USBSTOR)
- Event log review
- SetupAPI log checking
- Export to TXT, CSV, HTML
- Professional menu interface
- Comprehensive help documentation

## Contributing

This tool is part of the SouliTEK-AIO toolkit. For feature requests or bug reports, please contact Soulitek.

---

**Coded by**: Soulitek.co.il  
**Category**: Forensics & Security  
**Tool Type**: USB Device Analysis  
**Platform**: Windows PowerShell  
**Language**: PowerShell 5.1+

