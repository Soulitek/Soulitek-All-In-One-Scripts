# Self-Destruction Feature

**Date:** 2025-11-22  
**Version:** 1.0  
**Status:** Implemented

---

## Overview

All SouliTEK scripts now include a **self-destruction feature** that automatically removes the script file from the client PC after execution. This ensures clean deployment and prevents script accumulation on end-user systems.

---

## How It Works

### 1. Function Implementation

The `Invoke-SouliTEKSelfDestruct` function has been added to the common module (`modules/SouliTEK-Common.ps1`):

```powershell
function Invoke-SouliTEKSelfDestruct {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath,
        
        [Parameter(Mandatory = $false)]
        [switch]$Silent
    )
    
    # Creates a hidden background process that deletes the script
    # after a 2-second delay to ensure clean termination
}
```

### 2. Execution Flow

1. **User runs the script** - Script performs its intended function
2. **User selects Exit** (option 0 or Exit menu item)
3. **Self-destruct triggers** - `Invoke-SouliTEKSelfDestruct` is called
4. **Background process created** - A hidden PowerShell process is spawned
5. **Script exits** - Main script terminates normally
6. **File deletion** - After 2-second delay, the background process removes the script file

### 3. Technical Details

- **Delay:** 2-second wait ensures the main script fully terminates before deletion
- **Process:** Runs in a hidden PowerShell window (`-WindowStyle Hidden`)
- **Encoding:** Uses Base64-encoded command to avoid execution policy issues
- **Error Handling:** Silently continues if deletion fails (file in use, permissions, etc.)

---

## Implementation

### All Scripts Updated

The following scripts now include self-destruction:

1. battery_report_generator.ps1
2. bitlocker_status_report.ps1
3. create_system_restore_point.ps1
4. disk_usage_analyzer.ps1
5. EventLogAnalyzer.ps1
6. FindPST.ps1
7. license_expiration_checker.ps1
8. m365_user_list.ps1
9. mcafee_removal_tool.ps1
10. network_configuration_tool.ps1
11. network_test_tool.ps1
12. printer_spooler_fix.ps1
13. ram_slot_utilization_report.ps1
14. SouliTEK-WinGet-Installer.ps1
15. startup_boot_analyzer.ps1
16. storage_health_monitor.ps1
17. temp_removal_disk_cleanup.ps1
18. usb_device_log.ps1
19. wifi_password_viewer.ps1
20. win11_debloat.ps1

### Integration Example

```powershell
function Show-ExitMessage {
    Clear-Host
    Write-Host ""
    Write-Host "Thank you for using SouliTEK Tool!" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Website: www.soulitek.co.il" -ForegroundColor Yellow
    Write-Host ""
    
    # Self-destruct: Remove script file after execution
    Invoke-SouliTEKSelfDestruct -ScriptPath $PSCommandPath -Silent
}
```

---

## Use Cases

### 1. Client PC Deployment

When deploying scripts to end-user PCs for one-time fixes or configurations:

- Script executes its task
- User sees results
- Script removes itself automatically
- No manual cleanup required

### 2. Remote Support

For remote IT support scenarios:

- Send script to client
- Client runs script
- Problem resolved
- Script disappears automatically
- Client's system stays clean

### 3. Mass Deployment

When deploying scripts across multiple PCs:

- No accumulation of script files
- Prevents confusion from multiple versions
- Reduces security concerns about leftover scripts

---

## Safety Features

### 1. Silent Operation

- No visible windows or prompts
- User-friendly exit experience
- Professional appearance

### 2. Graceful Failure

- If deletion fails (file locked, permissions), script exits normally
- No error messages to confuse end users
- System remains stable

### 3. Timing Control

- 2-second delay ensures:
  - All output is visible to user
  - Script has fully terminated
  - File handles are released
  - Clean deletion process

---

## Technical Considerations

### When Self-Destruct Executes

The self-destruct function is called **only** when:

- User explicitly selects "Exit" option
- Script completes normally (for non-menu scripts)
- Error scenarios with explicit exit (SouliTEK-WinGet-Installer)

### When Self-Destruct Does NOT Execute

- User closes window with X button (script terminates immediately)
- User presses Ctrl+C to abort
- Script crashes unexpectedly
- System shutdown/restart during execution

### Permissions

- Requires write permissions to script location
- Works in user profile directories
- May fail in protected system directories (by design)

---

## Future Considerations

### Potential Enhancements

1. **Optional Behavior**
   - Add parameter to disable self-destruct for testing
   - Environment variable to control behavior

2. **Logging**
   - Log deletion attempts for audit purposes
   - Track successful/failed deletions

3. **Backup Option**
   - Save script copy before deletion
   - Move to recycle bin instead of delete

---

## Troubleshooting

### Script Not Deleting

**Cause:** File is locked or in use  
**Solution:** This is expected behavior. File will remain if locked.

**Cause:** Insufficient permissions  
**Solution:** Run script with appropriate permissions or from writable location.

### Multiple Instances

**Cause:** Script run multiple times quickly  
**Solution:** Each instance will attempt to delete itself. Last one wins.

---

## Documentation

- **Function:** `Invoke-SouliTEKSelfDestruct` in `modules/SouliTEK-Common.ps1`
- **Parameter:** `$PSCommandPath` (automatic variable containing script path)
- **Flag:** `-Silent` (suppresses confirmation messages)

---

**Coded by:** Soulitek.co.il  
**Website:** www.soulitek.co.il  
**© 2025 SouliTEK - All Rights Reserved**


