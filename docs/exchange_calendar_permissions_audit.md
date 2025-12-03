# Exchange Online Calendar Permissions Audit

## Overview

The **Exchange Online Calendar Permissions Audit** tool provides a comprehensive way to audit calendar permissions for Exchange Online mailboxes. It dynamically detects the calendar folder name (supporting different languages like Hebrew "לוח שנה") and displays all calendar permissions in a formatted table.

## Purpose

Audit calendar permissions for Exchange Online mailboxes:
- Dynamically find calendar folder (handles different languages)
- Retrieve all calendar folder permissions
- Display formatted results showing User, AccessRights, and SharingPermissionFlags
- Error handling for common issues (user not found, permissions, etc.)

## Features

### 🔍 **Dynamic Calendar Folder Detection**
- Automatically finds the calendar folder using `Get-MailboxFolderStatistics`
- Supports mailboxes in any language (e.g., Hebrew "לוח שנה", English "Calendar")
- Uses `FolderType` property to identify calendar folders
- No hardcoded folder names

### 📋 **Permission Retrieval**
- Retrieves all calendar folder permissions using `Get-MailboxFolderPermission`
- Uses dynamically detected calendar folder name
- Handles all permission types and sharing flags

### 📊 **Formatted Output**
- Displays results in a formatted table
- Shows three key columns:
  - **User:** Identity of the user with permissions
  - **AccessRights:** Comma-separated list of access rights
  - **SharingPermissionFlags:** Comma-separated list of sharing flags
- Total permission count display

### 🛡️ **Error Handling**
- Module availability check with helpful warnings
- User not found error handling
- Mailbox access error handling
- Calendar folder not found error handling
- Clear error messages with troubleshooting suggestions

## Requirements

### System Requirements
- **OS:** Windows 10 or Windows 11
- **PowerShell:** Version 5.1 or higher
- **Privileges:** Standard user (Exchange Online permissions required)
- **Exchange Online:** ExchangeOnlineManagement PowerShell module

### Required Permissions
- **Exchange Online Roles:** Exchange Administrator or Global Administrator
- **Required Permissions:**
  - `Mailbox.Read` - Read mailbox information
  - `Folder.Read` - Read folder information
  - `MailboxFolder.Read` - Read folder permissions
- **Authentication:** Microsoft 365 account with appropriate permissions

## Usage

### Running the Script

1. **Launch from SouliTEK Launcher** (recommended)
   - Open the SouliTEK Launcher
   - Find "Exchange Calendar Permissions Audit" in the Microsoft 365 category
   - Click the tool card to launch

2. **Run directly via PowerShell:**
   ```powershell
   .\scripts\exchange_calendar_permissions_audit.ps1
   ```

### First-Time Setup

#### Step 1: Install ExchangeOnlineManagement Module
If the module is not installed, you'll see a warning with instructions:
```powershell
Install-Module -Name ExchangeOnlineManagement -Scope CurrentUser
```

#### Step 2: Connect to Exchange Online
Connect to Exchange Online (this will auto-import the module):
```powershell
Connect-ExchangeOnline
```

#### Step 3: Run the Script
Run the script and enter the target email address when prompted.

### Workflow

1. **Module Check**
   - Script checks if ExchangeOnlineManagement module is loaded
   - If not loaded, displays warning with installation instructions

2. **Target Email Input**
   - Script prompts for target email address via console
   - Validates input is not empty

3. **Calendar Folder Detection**
   - Uses `Get-MailboxFolderStatistics` to find calendar folder
   - Searches for folder where `FolderType` equals 'Calendar'
   - Extracts the actual folder name (supports any language)

4. **Permission Retrieval**
   - Uses `Get-MailboxFolderPermission` with dynamic folder name
   - Retrieves all permissions for the calendar folder

5. **Formatted Output**
   - Displays results in formatted table
   - Shows User, AccessRights, and SharingPermissionFlags
   - Displays total permission count

## Output Format

### Table Columns

#### User
- Identity of the user with calendar permissions
- Can be:
  - Email address
  - Display name
  - "Default" for default permissions
  - "Anonymous" for anonymous access

#### AccessRights
- Comma-separated list of access rights
- Common values:
  - `None` - No access
  - `Owner` - Full control
  - `Editor` - Can edit items
  - `Author` - Can create and edit own items
  - `Reviewer` - Read-only access
  - `Contributor` - Can create items
  - `FreeBusyTimeOnly` - Can only see free/busy time
  - `FreeBusyTimeAndSubjectAndLocation` - Can see free/busy, subject, and location

#### SharingPermissionFlags
- Comma-separated list of sharing permission flags
- Common values:
  - `None` - No special sharing flags
  - `CanViewPrivateItems` - Can view private calendar items
  - `Delegate` - Has delegate access
  - `Reviewer` - Reviewer access level

### Example Output

```
============================================================
  Calendar Permissions for: user@example.com
============================================================

User                    AccessRights                              SharingPermissionFlags
----                    ------------                              ---------------------
Default                 Owner                                      None
john.doe@example.com    Editor, CanViewPrivateItems               CanViewPrivateItems
jane.smith@example.com  Reviewer                                  None

Total permissions found: 3
```

## Troubleshooting

### Module Not Loaded
**Problem:** Script shows warning that ExchangeOnlineManagement module is not loaded

**Solutions:**
1. Install the module:
   ```powershell
   Install-Module -Name ExchangeOnlineManagement -Scope CurrentUser
   ```
2. Import the module:
   ```powershell
   Import-Module ExchangeOnlineManagement
   ```
3. Or connect to Exchange Online (auto-imports module):
   ```powershell
   Connect-ExchangeOnline
   ```

### User Not Found
**Problem:** Script shows error "Could not find calendar folder"

**Possible Reasons:**
- Mailbox does not exist
- Mailbox does not have a calendar folder
- Insufficient permissions to access the mailbox
- Not connected to Exchange Online

**Solutions:**
1. Verify the email address is correct
2. Check if mailbox exists in Exchange admin center
3. Verify you have Exchange Administrator or Global Administrator role
4. Ensure you're connected to Exchange Online:
   ```powershell
   Connect-ExchangeOnline
   ```

### Calendar Folder Not Found
**Problem:** Script cannot find calendar folder

**Possible Reasons:**
- Mailbox calendar has been deleted
- Mailbox is a shared mailbox without calendar
- Mailbox is a resource mailbox

**Solutions:**
1. Verify mailbox has a calendar in Outlook
2. Check mailbox type in Exchange admin center
3. Try a different mailbox

### Permission Denied
**Problem:** Script shows permission error when accessing mailbox

**Solutions:**
1. Verify you have Exchange Administrator or Global Administrator role
2. Check if you have `Mailbox.Read` and `MailboxFolder.Read` permissions
3. Try reconnecting to Exchange Online:
   ```powershell
   Disconnect-ExchangeOnline
   Connect-ExchangeOnline
   ```

### Connection Issues
**Problem:** Cannot connect to Exchange Online

**Solutions:**
1. Check internet connectivity
2. Verify Microsoft 365 account credentials
3. Check if MFA is required
4. Try disconnecting and reconnecting:
   ```powershell
   Disconnect-ExchangeOnline -Confirm:$false
   Connect-ExchangeOnline
   ```

## Best Practices

### Regular Audits
- Audit calendar permissions monthly
- Keep records of permission changes
- Document who has access to sensitive calendars

### Security
- Review permissions for shared mailboxes
- Remove unnecessary permissions
- Monitor delegate access
- Audit external sharing permissions

### Documentation
- Export permission reports for compliance
- Document permission changes
- Keep audit trail of access changes

## Exchange Online Permissions

### Required Permissions
- **Mailbox.Read:** Read mailbox information
- **MailboxFolder.Read:** Read folder information and permissions
- **Organization.Read:** Read organization information (for connection)

### Role Requirements
- **Exchange Administrator:** Full Exchange management access
- **Global Administrator:** Full tenant access

## Technical Details

### Dynamic Folder Detection
The script uses `Get-MailboxFolderStatistics` to find the calendar folder:
```powershell
$folders = Get-MailboxFolderStatistics -Identity $MailboxIdentity
$calendarFolder = $folders | Where-Object { $_.FolderType -eq 'Calendar' }
```

This approach:
- Works with any language (Hebrew, English, etc.)
- Doesn't assume folder name is "Calendar"
- Uses folder type instead of name

### Permission Retrieval
The script uses `Get-MailboxFolderPermission` with the dynamic folder name:
```powershell
$permissions = Get-MailboxFolderPermission -Identity "$MailboxIdentity`:\$CalendarFolderName"
```

### Error Handling
All operations are wrapped in try/catch blocks:
- Module check errors
- Mailbox access errors
- Folder detection errors
- Permission retrieval errors

## Support

For assistance or to report issues:
- **Website:** www.soulitek.co.il
- **Email:** letstalk@soulitek.co.il

---

**Coded by:** SouliTEK  
*IT Solutions for your business*

(C) 2025 SouliTEK - All Rights Reserved


