# Microsoft 365 Exchange Online

## Overview

The **Microsoft 365 Exchange Online** tool provides comprehensive mailbox information from Exchange Online, including display names, aliases, license status, mailbox types, protocol settings, activity tracking, mailbox sizes, and permissions. It's designed for IT administrators managing Exchange Online mailboxes and conducting mailbox audits.

## Purpose

Provides complete Exchange Online mailbox visibility:
- Full mailbox inventory with all details
- License status tracking
- Protocol configuration (IMAP, POP, EWS, ActiveSync, SMTP AUTH, MAPI)
- Activity monitoring (last activity, logon, access)
- Mailbox size and item count
- SendOnBehalf permissions
- Export to multiple formats

## Features

### 📧 **Mailbox Inventory**
- Complete list of all mailboxes in tenant
- Display name
- Primary email address (PrimarySmtpAddress)
- Email aliases (all secondary email addresses)
- Mailbox type (User / Shared / Resource)
- Recipient type details

### 📋 **License Information**
- License status (Licensed / Unlicensed)
- License assignment tracking
- Unlicensed mailbox identification

### 🔌 **Protocol Configuration**
- **IMAP:** IMAP protocol status (Enabled/Disabled)
- **POP:** POP3 protocol status (Enabled/Disabled)
- **EWS:** Exchange Web Services status (Enabled/Disabled)
- **ActiveSync:** ActiveSync protocol status (Enabled/Disabled)
- **SMTP AUTH:** SMTP authentication status (Enabled/Disabled)
- **MAPI:** MAPI protocol status (Enabled/Disabled)

### 📊 **Activity Tracking**
- **Last Activity Time:** Most recent mailbox activity
- **Last Mailbox Logon:** Last time user logged into mailbox
- **Last Mailbox Access:** Last time mailbox was accessed

### 💾 **Mailbox Statistics**
- **Mailbox Size:** Total mailbox size in GB
- **Item Count:** Total number of items in mailbox
- Size and item count per mailbox

### 🔐 **Permissions**
- **SendOnBehalf:** List of users with SendOnBehalf permissions
- Delegate tracking
- Permission count

### 📊 **Export Options**
- **TXT:** Human-readable text format
- **CSV:** Spreadsheet format for Excel/Google Sheets
- **HTML:** Professional web report with styling

## Requirements

### System Requirements
- **OS:** Windows 10 or Windows 11
- **PowerShell:** Version 5.1 or higher
- **Privileges:** Standard user (Exchange Online permissions required)
- **Exchange Online:** Exchange Online Management PowerShell module

### Required Permissions
- **Exchange Online Roles:** Exchange Administrator or Global Administrator
- **Required Permissions:**
  - `Mailbox.Read` - Read mailbox information
  - `Organization.Read` - Read organization information
- **Authentication:** Microsoft 365 account with appropriate permissions

## Usage

### Running the Script

1. **Launch from SouliTEK Launcher** (recommended)
   - Open the SouliTEK Launcher
   - Find "Exchange Online" in the Microsoft 365 category
   - Click the tool card to launch

2. **Run directly via PowerShell:**
   ```powershell
   .\scripts\m365_exchange_online.ps1
   ```

3. **With custom output folder:**
   ```powershell
   .\scripts\m365_exchange_online.ps1 -OutputFolder "C:\Reports"
   ```

### First-Time Setup

#### Step 1: Connect to Exchange Online
- Tool will prompt for Microsoft 365 authentication
- Sign in with admin account
- Grant required permissions
- Connection saved for future use

#### Step 2: Install Modules (Automatic)
- Tool automatically installs required modules:
  - ExchangeOnlineManagement
- First run may take longer for module installation

### Menu Options

#### Option 1: Connect to Exchange Online
- First-time users will need to authenticate via browser
- Grant permissions when prompted
- If already connected, you can keep or switch tenants

#### Option 2: Disconnect from Current Tenant
- Disconnects from the current Exchange Online tenant
- Clears all cached mailbox data
- Use this to switch to a different tenant

#### Option 3: Retrieve All Mailboxes
- Fetches all mailboxes from your Exchange Online tenant
- Collects comprehensive data:
  - Display name and email addresses
  - Aliases
  - License status
  - Mailbox type
  - Protocol settings
  - Activity information
  - Mailbox size and item count
  - SendOnBehalf permissions
- May take a few moments for large tenants

#### Option 4: View Mailbox Summary
- Displays summary statistics
- Total mailbox count
- User vs. Shared vs. Resource mailboxes
- Licensed vs. Unlicensed mailboxes
- Total mailbox size
- Top 10 mailboxes preview

#### Options 5-7: Export Reports
- **Option 5:** TXT Format - Human-readable text format
- **Option 6:** CSV Format - Spreadsheet format for Excel/Google Sheets
- **Option 7:** HTML Format - Professional web report with styling

#### Option 8: Help & Information
- Displays detailed help and usage information

## Output Files

### Report Locations
- **Default:** Desktop (`%USERPROFILE%\Desktop`)
- **Custom:** Specified output folder
- **Formats:** TXT, CSV, and HTML
- **Filename:** `Exchange_Online_Mailboxes_YYYYMMDD_HHMMSS.[ext]`

### Report Contents

#### Mailbox Information
- **Display Name:** Mailbox display name
- **Primary Email:** Primary SMTP address
- **Aliases:** All secondary email addresses (semicolon-separated)
- **Aliases Count:** Number of aliases

#### License Information
- **License Status:** Licensed or Unlicensed
- **Is Licensed:** Boolean flag

#### Mailbox Type
- **Mailbox Type:** User, Shared, or Resource
- **Recipient Type Details:** Detailed recipient type

#### Protocol Settings
- **IMAP Enabled:** IMAP protocol status
- **POP Enabled:** POP3 protocol status
- **EWS Enabled:** Exchange Web Services status
- **ActiveSync Enabled:** ActiveSync protocol status
- **SMTP Auth Enabled:** SMTP authentication status
- **MAPI Enabled:** MAPI protocol status

#### Activity Information
- **Last Activity Time:** Most recent mailbox activity timestamp
- **Last Mailbox Logon:** Last logon timestamp
- **Last Mailbox Access:** Last access timestamp

#### Mailbox Statistics
- **Mailbox Size (GB):** Total mailbox size in gigabytes
- **Item Count:** Total number of items in mailbox

#### Permissions
- **SendOnBehalf:** List of users with SendOnBehalf permissions (semicolon-separated)
- **SendOnBehalf Count:** Number of delegates

## Data Fields

### Mailbox Information
- **Display Name:** Mailbox display name
- **Primary Email:** Primary SMTP address
- **Aliases:** Secondary email addresses
- **Aliases Count:** Number of aliases

### License Status
- **License Status:** String (Licensed/Unlicensed)
- **Is Licensed:** Boolean

### Mailbox Type
- **Mailbox Type:** String (User/Shared/Resource)
- **Recipient Type Details:** Detailed recipient type from Exchange

### Protocol Configuration
- **IMAP Enabled:** String (Enabled/Disabled)
- **POP Enabled:** String (Enabled/Disabled)
- **EWS Enabled:** String (Enabled/Disabled)
- **ActiveSync Enabled:** String (Enabled/Disabled)
- **SMTP Auth Enabled:** String (Enabled/Disabled)
- **MAPI Enabled:** String (Enabled/Disabled)

### Activity Tracking
- **Last Activity Time:** Timestamp (yyyy-MM-dd HH:mm:ss) or "Never"
- **Last Mailbox Logon:** Timestamp (yyyy-MM-dd HH:mm:ss) or "Never"
- **Last Mailbox Access:** Timestamp (yyyy-MM-dd HH:mm:ss) or "Never"

### Mailbox Statistics
- **Mailbox Size (GB):** Decimal number (e.g., 2.45)
- **Item Count:** Integer number of items

### Permissions
- **SendOnBehalf:** Semicolon-separated list of delegate email addresses
- **SendOnBehalf Count:** Number of delegates

## Troubleshooting

### Authentication Fails
**Problem:** Cannot connect to Exchange Online

**Solutions:**
1. Verify Microsoft 365 account credentials
2. Check account has Exchange Administrator or Global Administrator role
3. Verify internet connectivity
4. Check if MFA is required
5. Try disconnecting and reconnecting

### Module Installation Fails
**Problem:** Cannot install ExchangeOnlineManagement module

**Solutions:**
1. Run PowerShell as Administrator
2. Check internet connectivity
3. Verify PowerShell execution policy
4. Install module manually:
   ```powershell
   Install-Module ExchangeOnlineManagement -Force
   ```

### No Mailboxes Found
**Problem:** Tool shows no mailboxes

**Possible Reasons:**
- Account doesn't have mailbox read permissions
- No mailboxes in tenant
- Incorrect tenant connection

**Solutions:**
- Verify account permissions (Exchange Administrator or Global Administrator)
- Check Exchange admin center
- Verify correct tenant connection

### Export Fails
**Problem:** Cannot export mailbox list

**Solutions:**
1. Check disk space in output folder
2. Verify write permissions
3. Close file if already open
4. Check antivirus isn't blocking

### Large Tenant Performance
**Problem:** Export is slow for large tenants

**Causes:**
- Many mailboxes (thousands)
- Network latency
- API rate limiting

**Solutions:**
- Normal for large tenants
- Be patient during export
- Export runs in background
- Consider filtering mailboxes

### Mailbox Statistics Not Available
**Problem:** Some mailboxes show "Never" for activity or 0 for size

**Possible Reasons:**
- Mailbox has never been accessed
- Mailbox is new
- Statistics not yet calculated
- Permissions issue

**Solutions:**
- This is normal for unused mailboxes
- Statistics are calculated by Exchange Online
- Wait for statistics to be updated
- Verify mailbox permissions

## Best Practices

### Regular Audits
- Export mailbox list monthly
- Keep historical records
- Track mailbox growth
- Monitor license usage

### Data Privacy
- Handle mailbox data securely
- Store exports in secure location
- Follow data protection regulations
- Limit access to exported files

### License Management
- Regular license audits
- Track license assignments
- Identify unlicensed mailboxes
- Optimize license usage

### Protocol Security
- Review protocol settings regularly
- Disable unused protocols
- Monitor SMTP AUTH usage
- Secure ActiveSync access

### Activity Monitoring
- Track inactive mailboxes
- Identify unused mailboxes
- Monitor last access times
- Clean up inactive mailboxes

## Exchange Online Permissions

### Required Permissions
- **Mailbox.Read:** Read mailbox information
- **Organization.Read:** Read organization information

### Role Requirements
- **Exchange Administrator:** Full Exchange management access
- **Global Administrator:** Full tenant access

## Support

For assistance or to report issues:
- **Website:** www.soulitek.co.il
- **Email:** letstalk@soulitek.co.il

---

**Coded by:** SouliTEK  
*IT Solutions for your business*

(C) 2025 SouliTEK - All Rights Reserved

