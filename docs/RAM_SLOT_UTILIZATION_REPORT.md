# RAM Slot Utilization Report

## Overview

The RAM Slot Utilization Report provides comprehensive analysis of your system's memory slots, showing which slots are used vs empty, memory type (DDR3/DDR4/DDR5), speed (MHz), and capacity per slot. This tool is essential for hardware inventory, upgrade planning, and troubleshooting memory-related issues.

## Features

### Core Functionality
- **Slot Analysis**: Total slots available vs used slots, empty slot identification
- **Memory Type Detection**: Automatically detects DDR, DDR2, DDR3, DDR4, DDR5, LPDDR4, LPDDR5
- **Speed Information**: Shows memory speed in MHz for each module
- **Capacity Tracking**: Displays capacity per slot in GB
- **Form Factor**: Identifies DIMM, SODIMM, and other form factors
- **Hardware Details**: Manufacturer, part numbers, serial numbers

### Reporting Formats
- **Console Display**: Color-coded real-time view in PowerShell
- **TXT Export**: Human-readable text report for documentation
- **CSV Export**: Spreadsheet-compatible data for analysis
- **HTML Export**: Professional web report with modern styling
- **All Formats**: Generate all report formats at once

## Usage

### Via GUI Launcher
1. Launch `SouliTEK-Launcher-WPF.ps1`
2. Select **Hardware** category
3. Click **Launch** on "RAM Slot Utilization Report"

### Direct Execution
```powershell
.\scripts\ram_slot_utilization_report.ps1
```

## Menu Options

1. **Display RAM Report** - View slot utilization in console
2. **Export to TXT** - Save as text file to Desktop
3. **Export to CSV** - Save as CSV file to Desktop
4. **Export to HTML** - Save as HTML report to Desktop
5. **Export All Formats** - Generate all report formats at once
6. **Help** - Comprehensive usage guide
0. **Exit** - Close the tool

## Information Displayed

### Summary Section
- Computer Name
- Total Slots Available
- Slots Used vs Total
- Empty Slots Count
- Total Capacity (GB)
- Memory Type(s) (DDR3/DDR4/DDR5)
- Speed(s) (MHz)

### Slot Details (Per Slot)
- Slot Number
- Device Location
- Status (In Use / Empty)
- Capacity (GB)
- Memory Type (DDR3/DDR4/DDR5)
- Speed (MHz)
- Form Factor (DIMM/SODIMM)
- Manufacturer
- Part Number
- Serial Number

## Example Output

### Console Display
```
========================================
   RAM SLOT UTILIZATION REPORT
========================================

SUMMARY
========================================
Computer Name:      DESKTOP-ABC123
Total Slots:        4
Slots Used:         2 / 4
Slots Empty:        2
Total Capacity:     16.00 GB
Memory Type(s):     DDR4
Speed(s):           3200 MHz

SLOT DETAILS
========================================

Slot 1 - DIMM_A1
  Capacity:   8.00 GB
  Type:       DDR4
  Speed:      3200 MHz
  Form Factor: DIMM
  Manufacturer: Kingston
  Part Number: KVR32N22D8/16

Slot 2 - DIMM_B1
  Capacity:   8.00 GB
  Type:       DDR4
  Speed:      3200 MHz
  Form Factor: DIMM
  Manufacturer: Kingston
  Part Number: KVR32N22D8/16

Slot 3 - DIMM_A2
  Status: Empty

Slot 4 - DIMM_B2
  Status: Empty
```

## Use Cases

### Hardware Inventory
- Document current RAM configuration
- Track serial numbers for warranty purposes
- Maintain hardware asset database

### Upgrade Planning
- Identify available slots for expansion
- Check compatibility (type and speed)
- Plan memory upgrades efficiently

### Troubleshooting
- Detect mismatched memory modules
- Identify faulty RAM slots
- Verify memory configuration

### IT Asset Management
- Generate reports for inventory systems
- Track RAM upgrades across fleet
- Compliance and audit documentation

## Requirements

- **Windows PowerShell 5.1** or later
- **Administrator privileges** (recommended for full hardware access)
- **WMI/CIM access** enabled
- **Windows 10/11** (tested on these platforms)

## Technical Details

### Memory Type Detection
The tool uses SMBIOS memory type codes to identify memory types:
- Type 20: DDR
- Type 21: DDR2
- Type 22: DDR2 FB-DIMM
- Type 24: DDR3
- Type 26: DDR4
- Type 30: LPDDR4
- Type 34: DDR5
- Type 35: LPDDR5

### Data Collection Methods
- **Win32_PhysicalMemoryArray**: Total slot count
- **Win32_PhysicalMemory**: Installed modules details
- **SMBIOS Memory Type**: Memory technology identification
- **Device Locator**: Physical slot location

### Export Formats

#### TXT Format
- Plain text report
- Easy to read and share
- Suitable for documentation

#### CSV Format
- Two files generated:
  - `RAM_Slot_Report_*.csv`: Detailed slot information
  - `RAM_Slot_Summary_*.csv`: Summary statistics
- Compatible with Excel, Google Sheets
- Ideal for data analysis

#### HTML Format
- Modern, professional styling
- Summary cards with visual indicators
- Responsive table design
- Color-coded status (In Use / Empty)
- Percentage utilization display

## File Locations

All exports are saved to the Desktop:
- `RAM_Slot_Report_YYYYMMDD_HHMMSS.txt`
- `RAM_Slot_Report_YYYYMMDD_HHMMSS.csv`
- `RAM_Slot_Summary_YYYYMMDD_HHMMSS.csv`
- `RAM_Slot_Report_YYYYMMDD_HHMMSS.html`

## Troubleshooting

### No Slots Detected
- **Issue**: Tool shows 0 slots or incorrect slot count
- **Solution**: 
  - Run as Administrator
  - Check WMI service is running
  - Verify BIOS/UEFI reports slot information

### Missing Memory Type Information
- **Issue**: Memory type shows "Unknown"
- **Solution**:
  - Update system BIOS/UEFI
  - Check SMBIOS version compatibility
  - Some older systems may not report type correctly

### Incomplete Module Information
- **Issue**: Manufacturer, part number, or serial number missing
- **Solution**:
  - This is normal for some memory modules
  - Not all manufacturers provide complete SMBIOS data
  - Physical inspection may be required

### Export Errors
- **Issue**: Cannot save reports to Desktop
- **Solution**:
  - Check Desktop folder permissions
  - Ensure sufficient disk space
  - Run as Administrator if needed

## Best Practices

1. **Run as Administrator**: Ensures complete hardware access
2. **Regular Inventory**: Generate reports periodically for asset tracking
3. **Before Upgrades**: Always check slot utilization before purchasing RAM
4. **Documentation**: Export reports for hardware inventory systems
5. **Compare Reports**: Track changes over time for troubleshooting

## Integration

This tool is integrated into the SouliTEK All-In-One Scripts launcher under the **Hardware** category with the icon **[RAM]**.

## Support

- **Website**: www.soulitek.co.il
- **Email**: letstalk@soulitek.co.il
- **GitHub**: https://github.com/Soulitek/Soulitek-All-In-One-Scripts

## Version History

- **v1.0** (2025-01-15): Initial release
  - Console display with color coding
  - TXT, CSV, HTML export formats
  - DDR type detection (DDR3/DDR4/DDR5)
  - Slot-by-slot detailed breakdown
  - Manufacturer and serial number tracking

## License

(C) 2025 Soulitek - All Rights Reserved

This tool is provided "AS IS" without warranty of any kind. Use at your own risk.

