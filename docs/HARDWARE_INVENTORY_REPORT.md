# Hardware Inventory Report

## Overview

The Hardware Inventory Report tool provides comprehensive hardware information collection including CPU, GPU, RAM, storage devices, motherboard, BIOS, and serial numbers. The tool exports data in both JSON and CSV formats, making it ideal for warranty tracking, asset management, and IT documentation.

## Quick Start

```powershell
# Basic usage (exports both JSON and CSV to script directory)
.\scripts\hardware_inventory_report.ps1

# Custom output directory
.\scripts\hardware_inventory_report.ps1 -OutputPath "C:\HardwareReports"

# JSON format only
.\scripts\hardware_inventory_report.ps1 -Format "JSON"

# CSV format only
.\scripts\hardware_inventory_report.ps1 -Format "CSV"
```

## Launch from GUI

1. Open the SouliTEK Launcher: `.\launcher\SouliTEK-Launcher-WPF.ps1`
2. Navigate to the **Hardware** category or search for "Hardware Inventory"
3. Click the **Hardware Inventory Report** tool
4. The script will collect hardware information and generate reports

## Parameters

### `-OutputPath`
Specifies the directory where output files will be saved.

- **Type:** String
- **Default:** Script directory (`$PSScriptRoot`)
- **Example:** `-OutputPath "C:\Reports"`

The directory will be created automatically if it doesn't exist.

### `-Format`
Specifies the output format.

- **Type:** String (Enum: 'Both', 'JSON', 'CSV')
- **Default:** 'Both'
- **Options:**
  - `Both`: Exports both JSON and CSV files (default)
  - `JSON`: Exports only JSON format
  - `CSV`: Exports only CSV format

## Collected Information

### Computer Information
- Computer name and domain
- Manufacturer and model
- Total physical memory
- Operating system version and architecture
- System directory path

### CPU Information
- Processor name and manufacturer
- Number of cores and logical processors
- Clock speeds (max and current)
- Cache sizes (L2, L3)
- Serial number or processor ID
- Family, model, and stepping information

### GPU Information
- Graphics card name and manufacturer
- Driver version and date
- Current resolution
- Adapter RAM size
- Video mode description
- Status information

### RAM Information (Per Module)
- Capacity (GB)
- Speed (MHz)
- Manufacturer and part number
- Serial number
- Form factor (DIMM/SODIMM)
- Memory type (DDR, DDR2, DDR3, DDR4, DDR5)
- Bank label and device locator

### Storage Information (Per Device)
- Disk model and manufacturer
- Interface type (SATA, NVMe, etc.)
- Media type
- Total size
- Serial number
- Firmware revision
- Partition details:
  - Drive letter
  - Volume name
  - File system
  - Total size, free space, used space
  - Percentage free

### Motherboard Information
- Manufacturer
- Product name
- Version
- Serial number
- Tag identifier

### BIOS Information
- Manufacturer
- BIOS name
- Version
- Serial number
- Release date
- SMBIOS version information

### Network Adapters
- Adapter name and manufacturer
- Description
- MAC address
- Speed
- Status

### Serial Numbers Summary
Centralized collection of all serial numbers for warranty tracking:
- Computer system serial
- Motherboard serial
- BIOS serial
- CPU serial numbers/processor IDs
- RAM module serial numbers
- Storage device serial numbers

## Output Formats

### JSON Format
Complete nested structure with all hardware details preserved. Ideal for:
- Programmatic processing
- Integration with other systems
- Complete data preservation
- API consumption

**File naming:** `HardwareInventory_YYYYMMDD_HHMMSS.json`

**Structure:**
```json
{
  "ComputerInfo": { ... },
  "CPU": [ ... ],
  "GPU": [ ... ],
  "RAM": [ ... ],
  "Storage": [ ... ],
  "Motherboard": { ... },
  "BIOS": { ... },
  "NetworkAdapters": [ ... ],
  "SerialNumbers": { ... },
  "Timestamp": "2025-10-30 14:30:00"
}
```

### CSV Format
Flattened structure optimized for spreadsheet analysis and warranty tracking.

**File naming:** `HardwareInventory_YYYYMMDD_HHMMSS.csv`

**Columns:**
- `Category`: Component type (Computer, CPU, GPU, RAM, Storage, etc.)
- `Item`: Component name/model
- `Manufacturer`: Manufacturer name
- `Model`: Model or version information
- `SerialNumber`: Serial number or unique identifier
- `Details`: Additional details (specifications, status, etc.)
- `Timestamp`: Report generation timestamp

**Use Cases:**
- Warranty registration
- Asset tracking spreadsheets
- Procurement documentation
- Compliance reporting

## Examples

### Example 1: Basic Inventory Collection
```powershell
.\scripts\hardware_inventory_report.ps1
```
Generates both JSON and CSV files in the scripts directory.

### Example 2: Warranty Tracking Export
```powershell
.\scripts\hardware_inventory_report.ps1 -OutputPath "C:\WarrantyTracking" -Format "CSV"
```
Generates only CSV format optimized for warranty registration in the specified directory.

### Example 3: Integration with Asset Management System
```powershell
.\scripts\hardware_inventory_report.ps1 -OutputPath "C:\AssetMgmt\Import" -Format "JSON"
```
Generates JSON format for automated import into asset management systems.

### Example 4: Scheduled Inventory Collection
```powershell
# Schedule daily inventory collection
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" `
    -Argument "-ExecutionPolicy Bypass -File C:\SouliTEK\scripts\hardware_inventory_report.ps1 -OutputPath C:\Inventory\Daily"

$trigger = New-ScheduledTaskTrigger -Daily -At "06:00"

Register-ScheduledTask -TaskName "Daily Hardware Inventory" `
    -Action $action -Trigger $trigger -RunLevel Highest
```

## Use Cases

### 1. Warranty Tracking
Export CSV format to register hardware components with manufacturers for warranty purposes. Serial numbers are clearly identified for each component.

### 2. Asset Management
Maintain comprehensive hardware inventory for IT asset management systems. JSON format can be imported into asset management platforms.

### 3. Procurement Planning
Analyze current hardware specifications to plan upgrades and replacements. Identify components approaching end-of-life.

### 4. Compliance Documentation
Generate hardware documentation for compliance audits, security reviews, and IT governance requirements.

### 5. Remote Support Preparation
Quick hardware overview for remote support sessions to understand system capabilities and limitations.

### 6. Migration Planning
Document hardware before system migrations or upgrades to ensure compatibility and planning.

## Requirements

- **PowerShell Version:** 5.1 or later
- **Windows Version:** Windows 10/11 or Windows Server 2016+
- **Permissions:** Some information requires administrator privileges (automatically handled if launched from GUI launcher)
- **Modules:** Uses native PowerShell CIM cmdlets (no additional modules required)

## Troubleshooting

### Missing Serial Numbers
Some hardware manufacturers may not provide serial numbers through standard WMI queries. This is hardware-dependent and cannot be resolved by the script.

### Incomplete GPU Information
The script filters out "Microsoft Basic Display Driver" entries. If GPU information appears incomplete, ensure proper GPU drivers are installed.

### Storage Partition Information
Partition details are collected for all logical drives. If some partitions are missing, they may be unmounted or inaccessible.

### Network Adapter Speed Shows "N/A"
Some network adapters don't report speed information via WMI. This is hardware-dependent.

### Permission Errors
If you see permission errors, ensure you're running the script with administrator privileges. The GUI launcher automatically handles this.

## Best Practices

1. **Regular Collection:** Schedule regular inventory collection to track hardware changes over time.

2. **Centralized Storage:** Store reports in a centralized location for easy access and tracking.

3. **Version Control:** Keep historical reports to track hardware changes and upgrades.

4. **Integration:** Use JSON format for integration with asset management systems and APIs.

5. **Warranty Registration:** Use CSV format for quick warranty registration with manufacturers.

6. **Backup:** Include inventory reports in your backup strategy for disaster recovery planning.

## Output Location

By default, reports are saved in the same directory as the script:
```
scripts\HardwareInventory_YYYYMMDD_HHMMSS.json
scripts\HardwareInventory_YYYYMMDD_HHMMSS.csv
```

Use the `-OutputPath` parameter to specify a custom location for better organization.

## File Naming Convention

Files are named with timestamp for easy sorting and identification:
- Format: `HardwareInventory_YYYYMMDD_HHMMSS.ext`
- Example: `HardwareInventory_20251030_143000.json`
- Sorting: Files sort chronologically when sorted by name

## Related Tools

- **Disk Usage Analyzer:** Analyze disk space usage and storage consumption
- **Battery Report Generator:** Generate battery health reports for laptops
- **Remote Support Toolkit:** Comprehensive system diagnostics

## Support

For issues, questions, or feature requests:
- **Website:** [www.soulitek.co.il](https://www.soulitek.co.il)
- **Email:** letstalk@soulitek.co.il

## Version History

- **v1.0.0** (2025-10-30): Initial release
  - Comprehensive hardware collection
  - JSON and CSV export formats
  - Serial number tracking
  - Network adapter enumeration

