# System Restore Point Creator

## Overview

The **System Restore Point Creator** is a utility for creating and managing Windows System Restore Points. It provides an easy way to create restore points before making system changes, ensuring you can roll back if issues occur.

## Purpose

Simplifies System Restore Point management:
- Quick restore point creation
- Custom descriptions
- Restore point history viewing
- Enable/disable system protection
- Status checking

## Features

### 💾 **Restore Point Creation**
- Quick creation with default description
- Custom description support
- Automatic timestamping
- Pre-change backup creation

### 📋 **Restore Point Management**
- View all restore points
- Check restore point status
- Enable/disable system protection
- Restore point history

### 🔍 **Status Checking**
- System Restore status
- Protection status per drive
- Available restore points
- Disk space usage

## Requirements

### System Requirements
- **OS:** Windows 10 or Windows 11
- **PowerShell:** Version 5.1 or higher
- **Privileges:** Administrator rights (required)
- **System Restore:** Must be enabled (tool can enable it)

## Usage

### Running the Script

1. **Launch from SouliTEK Launcher** (recommended)
   - Open the SouliTEK Launcher
   - Find "System Restore Point Creator" in the System category
   - Click the tool card to launch

2. **Run directly via PowerShell** (as Administrator):
   ```powershell
   .\scripts\create_system_restore_point.ps1
   ```

### Menu Options

#### Option 1: Create Quick Restore Point
Creates a restore point with default description.
- Automatic timestamp
- Default description format
- Fast creation
- Confirmation message

#### Option 2: Create Custom Restore Point
Create restore point with custom description.
- Enter custom description
- Timestamp automatically added
- Useful for documenting changes
- Example: "Before installing new software"

#### Option 3: View Restore Points
Lists all available restore points.
- Creation date and time
- Description
- Restore point type
- Sequence numbers

#### Option 4: Check System Restore Status
Displays System Restore configuration.
- Protection status per drive
- Disk space allocated
- System Restore enabled/disabled
- Current status

#### Option 5: Enable/Disable System Protection
Manages System Restore protection.
- Enable protection on drives
- Disable protection (frees disk space)
- Configure disk space allocation
- Protection status per drive

## When to Create Restore Points

### Recommended Times
- **Before software installation:** Especially system-level software
- **Before Windows updates:** Major updates or feature updates
- **Before registry changes:** Manual registry edits
- **Before driver updates:** New hardware drivers
- **Before system configuration changes:** Major settings changes
- **Regular maintenance:** Weekly or monthly automatic points

### Best Practices
- Create restore point before any major change
- Use descriptive names
- Don't rely solely on restore points (backup important data)
- Monitor disk space usage
- Keep recent restore points

## Technical Details

### Restore Point Types
- **MODIFY_SETTINGS:** Before configuration changes
- **INSTALL_SOFTWARE:** Before software installation
- **DEVICE_DRIVER_INSTALL:** Before driver installation
- **APPLICATION_UNINSTALL:** Before uninstalling applications

### Disk Space
- Default allocation: ~3-5% of drive space
- Minimum recommended: 1GB
- Maximum: Up to configured limit
- Old restore points auto-deleted when space needed

### Storage Location
- Stored in `System Volume Information` folder
- Hidden and protected system folder
- Not accessible via normal file browsing
- Managed by Windows automatically

## Troubleshooting

### Cannot Create Restore Point
**Problem:** "Failed to create restore point"

**Solutions:**
1. Ensure running as Administrator
2. Check System Restore is enabled
3. Verify sufficient disk space (at least 300MB)
4. Check System Restore service is running
5. Disable antivirus temporarily (may block creation)

### System Restore Disabled
**Problem:** "System Restore is not enabled"

**Solutions:**
1. Use Option 5 to enable protection
2. Enable via System Properties manually
3. Check Group Policy (may be disabled by policy)
4. Verify disk is not excluded

### No Restore Points Found
**Problem:** "No restore points available"

**Causes:**
- System Restore disabled
- Disk space full
- Restore points deleted
- New system without points created

**Solutions:**
- Enable System Restore
- Free up disk space
- Create new restore point
- Check disk for errors

### Insufficient Disk Space
**Problem:** "Not enough disk space for restore point"

**Solutions:**
1. Free up disk space (at least 300MB needed)
2. Reduce restore point allocation
3. Delete old restore points
4. Clean up temporary files

## Restoring from Restore Point

### Using Windows GUI
1. Press `Win + R`, type `rstrui.exe`
2. Select restore point
3. Follow wizard to restore

### Using PowerShell
```powershell
# List restore points
Get-ComputerRestorePoint

# Restore to specific point
Restore-Computer -RestorePoint <SequenceNumber>
```

## Support

For assistance or to report issues:
- **Website:** www.soulitek.co.il
- **Email:** letstalk@soulitek.co.il

---

**Coded by:** SouliTEK  
*IT Solutions for your business*

(C) 2025 SouliTEK - All Rights Reserved









