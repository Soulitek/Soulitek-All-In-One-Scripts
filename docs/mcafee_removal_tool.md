# McAfee Removal Tool

## Overview

The **McAfee Removal Tool** uses the official McAfee Consumer Product Removal (MCPR) tool to completely remove McAfee products from Windows systems. It provides a safe and automated way to uninstall McAfee antivirus and related products.

## Purpose

Completely removes McAfee products:
- McAfee antivirus software
- McAfee security products
- McAfee browser extensions
- Remaining registry entries
- Leftover files and folders

## Features

### 🗑️ **Complete Removal**
- Removes all McAfee products
- Cleans registry entries
- Removes leftover files
- Uninstalls browser extensions

### 🛡️ **Safe Removal**
- Uses official MCPR tool
- Safe removal process
- Backup recommendations
- Logging and reporting

### 📋 **Automated Process**
- Automated removal workflow
- Progress indicators
- Error handling
- Completion reporting

## Requirements

### System Requirements
- **OS:** Windows 10 or Windows 11
- **PowerShell:** Version 5.1 or higher
- **Privileges:** Administrator rights (required)
- **MCPR Tool:** Included in tools folder

### Prerequisites
- Administrator account access
- McAfee products installed
- Sufficient disk space for logs

## Usage

### Running the Script

1. **Launch from SouliTEK Launcher** (recommended)
   - Open the SouliTEK Launcher
   - Find "McAfee Removal Tool" in the Security category
   - Click the tool card to launch

2. **Run directly via PowerShell** (as Administrator):
   ```powershell
   .\scripts\mcafee_removal_tool.ps1
   ```

### Important Warnings

⚠️ **WARNING:** This tool will completely remove all McAfee products from your system.

**Before Running:**
- Create a system restore point
- Backup important data
- Close all McAfee applications
- Ensure you have another antivirus solution ready

### Removal Process

#### Step 1: Verification
- Checks for administrator privileges
- Verifies MCPR tool is available
- Checks if McAfee is installed

#### Step 2: Warning and Confirmation
- Displays warning message
- Requires user confirmation
- Explains what will be removed

#### Step 3: Removal Execution
- Runs MCPR tool
- Monitors removal progress
- Handles errors gracefully

#### Step 4: Completion
- Displays removal status
- Shows removal results
- Provides next steps

## What Gets Removed

### McAfee Products
- McAfee Total Protection
- McAfee Internet Security
- McAfee Antivirus Plus
- McAfee LiveSafe
- McAfee WebAdvisor
- McAfee Safe Connect VPN
- All McAfee browser extensions

### System Components
- McAfee services
- McAfee drivers
- Registry entries
- Program files
- Application data

## Safety Features

### Official Tool
- Uses McAfee's official MCPR tool
- Tested and verified removal process
- Safe for system use
- Recommended by McAfee

### Error Handling
- Graceful error handling
- Detailed error messages
- Logging of removal process
- Recovery recommendations

## Troubleshooting

### MCPR Tool Not Found
**Problem:** "MCPR.exe not found"

**Solutions:**
1. Verify tools folder exists
2. Check MCPR.exe is in tools folder
3. Re-download MCPR if missing
4. Check file permissions

### Removal Fails
**Problem:** Removal process fails

**Solutions:**
1. Ensure running as Administrator
2. Close all McAfee processes first
3. Disable McAfee real-time protection temporarily
4. Run MCPR tool manually if needed
5. Check MCPR logs for details

### McAfee Still Present
**Problem:** Some McAfee components remain

**Solutions:**
1. Run removal tool again
2. Manually remove remaining components
3. Use McAfee's manual removal guide
4. Check registry for leftover entries
5. Remove browser extensions manually

### System Restore Recommended
**Problem:** System issues after removal

**Solutions:**
1. Use System Restore to revert
2. Reinstall McAfee if needed
3. Contact McAfee support
4. Check Windows Event Viewer

## Best Practices

### Before Removal
- **Create restore point:** Essential for safety
- **Backup data:** Important files
- **Close applications:** All McAfee apps
- **Have replacement ready:** Another antivirus solution

### After Removal
- **Install replacement antivirus:** Don't leave system unprotected
- **Restart computer:** Required for complete removal
- **Verify removal:** Check for remaining components
- **Update Windows:** Ensure system is up to date

### Replacement Antivirus
Consider these alternatives:
- Windows Defender (built-in)
- Bitdefender
- Kaspersky
- Norton
- Avast (free option)

## Technical Details

### MCPR Tool
- **Location:** `tools\MCPR.exe`
- **Source:** Official McAfee tool
- **Version:** Latest available
- **Function:** Complete product removal

### Removal Process
- Stops McAfee services
- Uninstalls programs
- Removes registry entries
- Deletes files and folders
- Cleans browser extensions

### Logging
- Removal process logged
- Errors recorded
- Completion status saved
- Logs saved to system

## Legal and Support

### McAfee Support
- Official MCPR tool provided by McAfee
- McAfee support available for removal issues
- Official removal documentation available

### Disclaimer
This tool uses McAfee's official removal tool. SouliTEK is not responsible for:
- Data loss during removal
- System issues after removal
- McAfee product removal failures
- Any consequences of removal

## Support

For assistance or to report issues:
- **Website:** www.soulitek.co.il
- **Email:** letstalk@soulitek.co.il

---

**Coded by:** SouliTEK  
*IT Solutions for your business*

(C) 2025 SouliTEK - All Rights Reserved









