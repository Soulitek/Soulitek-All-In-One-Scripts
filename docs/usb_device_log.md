# USB Device Log

## Overview

The **USB Device Log** is a professional forensic tool that provides comprehensive USB device history analysis for forensic investigation and security auditing. It reads system registry and event logs to identify USB devices that have been connected to the system.

## Purpose

Provides USB device forensic analysis:
- USB device history
- Registry analysis
- Event log review
- Device connection timeline
- Export capabilities

## Features

### 🔍 **Device History**
- All USB devices ever connected
- Connection timestamps
- Device removal times
- Connection frequency

### 📋 **Device Information**
- Device manufacturer
- Device model
- Serial numbers
- Vendor and Product IDs
- Device descriptions

### 📊 **Registry Analysis**
- USB registry entries
- Mounted devices
- Device storage information
- Registry timestamps

### 🔐 **Event Log Review**
- USB connection events
- Device insertion/removal logs
- System event correlation
- Timeline reconstruction

### 📁 **Export Options**
- Export to CSV format
- Export to TXT format
- Forensic report generation
- Detailed device logs

## Requirements

### System Requirements
- **OS:** Windows 10 or Windows 11
- **PowerShell:** Version 5.1 or higher
- **Privileges:** Administrator rights (recommended for full access)
- **Registry Access:** Registry read access

## Usage

### Running the Script

1. **Launch from SouliTEK Launcher** (recommended)
   - Open the SouliTEK Launcher
   - Find "USB Device Log" in the Security category
   - Click the tool card to launch

2. **Run directly via PowerShell** (as Administrator):
   ```powershell
   .\scripts\usb_device_log.ps1
   ```

### Important Notes

⚠️ **Forensic Tool:** This tool reads system registry and event logs which may contain sensitive information. Handle results appropriately and in accordance with privacy regulations.

### Menu Options

#### Option 1: Scan USB History
Scans registry for USB device history.
- All USB devices
- Connection information
- Device details
- Timestamps

#### Option 2: View Event Logs
Reviews Windows Event Logs for USB events.
- USB connection events
- Device insertion/removal
- System events
- Timeline analysis

#### Option 3: Export Device List
Exports USB device list to file.
- CSV format (spreadsheet)
- TXT format (text report)
- All device information
- Timestamped filename

#### Option 4: Detailed Device Analysis
Analyzes specific device in detail.
- Select device to analyze
- Detailed information
- Connection history
- Registry entries

## Data Sources

### Registry Locations
- `HKLM:\SYSTEM\CurrentControlSet\Enum\USBSTOR`
- `HKLM:\SYSTEM\CurrentControlSet\Enum\USB`
- `HKLM:\SYSTEM\MountedDevices`
- USB device registry keys

### Event Logs
- System Event Log
- USB-related events
- Device connection events
- Timeline information

## Device Information

### Collected Data
- **Manufacturer:** Device manufacturer name
- **Model:** Device model information
- **Serial Number:** Unique device identifier
- **Vendor ID:** USB vendor identifier
- **Product ID:** USB product identifier
- **Description:** Device description
- **First Seen:** First connection timestamp
- **Last Seen:** Last connection timestamp

## Use Cases

### Security Auditing
- Identify unauthorized USB devices
- Track device usage
- Security compliance
- Policy enforcement

### Forensic Investigation
- Device connection timeline
- Evidence collection
- Incident investigation
- Legal documentation

### IT Management
- Device inventory
- Usage tracking
- Policy compliance
- Asset management

## Troubleshooting

### No Devices Found
**Problem:** No USB devices detected

**Possible Reasons:**
- No USB devices ever connected
- Registry cleared
- System reset
- Limited registry access

**Solutions:**
- Verify registry access
- Check Event Logs
- Run as Administrator
- Some devices may not leave registry traces

### Limited Information
**Problem:** Some devices show limited information

**Causes:**
- Older Windows versions
- Registry limitations
- Device type differences
- Some devices don't store detailed info

**Solutions:**
- Information may be limited
- Check Event Logs for more details
- Some devices provide minimal registry data

### Access Denied
**Problem:** Cannot access registry or event logs

**Solutions:**
1. Run as Administrator
2. Check registry permissions
3. Verify Event Log access
4. Some system locations require admin

## Best Practices

### Forensic Use
- Document analysis process
- Preserve original data
- Maintain chain of custody
- Follow legal requirements

### Security Auditing
- Regular USB audits
- Track device usage
- Enforce policies
- Document findings

### Data Privacy
- Handle sensitive information appropriately
- Follow privacy regulations
- Secure exported data
- Limit access to reports

## Technical Details

### Registry Analysis
- Reads USB registry keys
- Parses device information
- Extracts timestamps
- Identifies device types

### Event Log Analysis
- Queries System Event Log
- Filters USB-related events
- Correlates with registry data
- Timeline reconstruction

## Output Files

### Report Locations
- **Desktop:** Reports saved to `%USERPROFILE%\Desktop`
- **Formats:** CSV and TXT
- **Filename:** `USBDeviceLog_YYYYMMDD_HHMMSS.[ext]`

### Report Contents
- Device list
- Connection information
- Timestamps
- Device details
- Forensic data

## Legal Considerations

### Privacy
- USB device logs may contain sensitive information
- Handle data in accordance with privacy laws
- Obtain proper authorization before analysis
- Follow data protection regulations

### Forensic Use
- Maintain chain of custody
- Document analysis process
- Preserve original evidence
- Follow legal procedures

## Support

For assistance or to report issues:
- **Website:** www.soulitek.co.il
- **Email:** letstalk@soulitek.co.il

---

**Coded by:** SouliTEK  
*IT Solutions for your business*

(C) 2025 SouliTEK - All Rights Reserved










