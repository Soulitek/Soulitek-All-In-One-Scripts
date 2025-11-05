# Icon Assignment Summary

## Overview
This document summarizes the icon assignments for all tools in the SouliTEK Launcher and lists tools that still need icons.

## Icons Successfully Assigned

The following tools now have PNG icons assigned:

| Tool Name | Icon File | Category |
|-----------|-----------|----------|
| **WiFi Password Viewer** | `lan.png` | Network |
| **Network Test Tool** | `lan.png` | Network |
| **Network Configuration Tool** | `lan.png` | Network |
| **Remote Support Toolkit** | `computer-monitor.png` | Support |
| **Storage Health Monitor** | `ssd.png` | Hardware |
| **Hardware Inventory Report** | `pc-tower.png` | Hardware |
| **RAM Slot Utilization Report** | `ram.png` | Hardware |
| **Disk Usage Analyzer** | `ssd.png` | Hardware |

**Total: 8 tools with icons assigned**

## Tools Still Needing Icons

The following tools are currently using text-based icons (letters in brackets) and need PNG icons:

### Hardware Category
1. **Battery Report Generator** - Currently: `[B]`
   - *Suggested icon type:* Battery icon, laptop icon, or power icon
   - *Purpose:* Generate comprehensive battery health reports for laptops

### Security Category
2. **BitLocker Status Report** - Currently: `[S]`
   - *Suggested icon type:* Lock icon, security shield, encryption icon
   - *Purpose:* Check BitLocker encryption status and recovery keys

3. **USB Device Log** - Currently: `[U]`
   - *Suggested icon type:* USB device icon, flash drive icon
   - *Purpose:* Forensic USB device history analysis

### M365 Category
4. **PST Finder** - Currently: `[M]`
   - *Suggested icon type:* Email icon, Outlook icon, file/folder icon
   - *Purpose:* Locate and analyze Outlook PST files

5. **License Expiration Checker** - Currently: `[L]`
   - *Suggested icon type:* License/document icon, calendar icon, alert/bell icon
   - *Purpose:* Monitor Microsoft 365 license subscriptions

6. **M365 MFA Audit** - Currently: `[A]`
   - *Suggested icon type:* Security shield, authentication icon, key icon
   - *Purpose:* Audit Microsoft 365 MFA status across users

7. **M365 User List** - Currently: `[U]`
   - *Suggested icon type:* Users/people icon, directory icon, list icon
   - *Purpose:* List all Microsoft 365 users with details

### Support Category
8. **Printer Spooler Fix** - Currently: `[P]`
   - *Suggested icon type:* Printer icon, print icon
   - *Purpose:* Comprehensive printer spooler troubleshooting

9. **Event Log Analyzer** - Currently: `[E]`
   - *Suggested icon type:* Log file icon, document icon, chart/graph icon
   - *Purpose:* Analyze Windows Event Logs with statistical summaries

10. **System Restore Point** - Currently: `[T]`
    - *Suggested icon type:* Restore/backup icon, clock icon, recovery icon
    - *Purpose:* Create Windows System Restore Points

11. **Temp Removal & Disk Cleanup** - Currently: `[CL]`
    - *Suggested icon type:* Trash/cleanup icon, broom icon, disk icon
    - *Purpose:* Remove temporary files and clean up disk space

### Software Category
12. **Chocolatey Installer** - Currently: `[C]`
    - *Suggested icon type:* Package/box icon, installer icon, download icon
    - *Purpose:* Interactive package installer with Ninite-like UX

**Total: 12 tools still need icons**

## Available Icons Not Yet Used

The following icons are available in `assets/icons/` but not yet assigned:

- `cpu.png` - Could be used for CPU-related tools
- `gpu.png` - Could be used for GPU-related tools  
- `wasd.png` - Keyboard icon (could be used for input/configuration tools)

## Implementation Notes

- Icons are loaded from `assets/icons/` folder
- Icon files should be PNG format
- Icons are displayed at 50x50 pixels in the launcher
- If an icon file is missing or fails to load, the launcher falls back to the text icon (letter in brackets)
- To assign an icon to a tool, add `IconPath = "filename.png"` to the tool definition in `launcher/SouliTEK-Launcher-WPF.ps1`

## How to Add Icons

1. Place the PNG icon file in `assets/icons/` folder
2. Open `launcher/SouliTEK-Launcher-WPF.ps1`
3. Find the tool definition in the `$Script:Tools` array
4. Add `IconPath = "filename.png"` to the tool's hashtable
5. Save and test the launcher

Example:
```powershell
@{
    Name = "Battery Report Generator"
    Icon = "[B]"
    IconPath = "battery.png"  # Add this line
    Description = "Generate comprehensive battery health reports for laptops"
    Script = "battery_report_generator.ps1"
    Category = "Hardware"
    Tags = @("battery", "laptop", "health", "report", "power")
    Color = "#3498db"
}
```

---

**Last Updated:** 2025-01-15  
**Total Tools:** 20  
**Tools with Icons:** 8  
**Tools Needing Icons:** 12



