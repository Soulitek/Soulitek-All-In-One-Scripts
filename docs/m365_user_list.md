# Microsoft 365 User List

## Overview

The **Microsoft 365 User List** tool provides full tenant visibility by extracting comprehensive Microsoft 365 user information including roles, groups, MFA status, mailbox configuration, and security posture. It's designed for IT administrators managing Microsoft 365 tenants and security audits.

## Purpose

Provides complete Microsoft 365 tenant visibility:
- Full user inventory with all details
- Permissions & access (roles and groups)
- Security posture (MFA status and methods)
- Mailbox configuration (forwarding, size, litigation hold)
- Export to multiple formats including JSON

## Features

### 👥 **User Inventory**
- Complete list of all users in tenant
- Primary email address (UserPrincipalName and Mail)
- Display name
- User status (Enabled / Disabled / Blocked sign-in)
- Department, job title, office location
- Phone numbers (Business and Mobile)
- Account creation date

### 🔐 **Permissions & Access**
- **Directory Roles:** List of roles assigned to each user
  - Global Administrator
  - Exchange Administrator
  - SharePoint Administrator
  - And all other directory roles
- **Group Memberships:** List of groups each user is a member of
  - Security groups
  - Microsoft 365 groups
  - Distribution groups

### 🛡️ **Security Posture**
- **MFA Status:**
  - Whether user has any MFA method configured
  - Which methods are configured:
    - Authenticator App
    - SMS (Phone)
    - Email MFA
    - FIDO Key
  - Whether MFA is enforced via Conditional Access
  - Last sign-in date

### 📧 **Mailbox Configuration** (Optional)
- Forwarding rules detection
- External forwarding detection
- Mailbox size & quota
- Litigation Hold status
- Retention status

### 📋 **License Details**
- Assigned licenses per user (with SKU names)
- License count
- License status

### 📊 **Export Options**
- **TXT:** Human-readable text format
- **CSV:** Spreadsheet format for Excel/Google Sheets
- **HTML:** Professional web report with styling
- **JSON:** Clean JSON format for automation and integrations

## Requirements

### System Requirements
- **OS:** Windows 10 or Windows 11
- **PowerShell:** Version 5.1 or higher
- **Privileges:** Standard user (Microsoft Graph permissions required)
- **Microsoft Graph:** Microsoft Graph PowerShell SDK modules

### Required Permissions
- **Microsoft Graph Scopes:**
  - `User.Read.All` - Read all users
  - `UserAuthenticationMethod.Read.All` - Read MFA status
  - `Organization.Read.All` - Read organization info
  - `Directory.Read.All` - Read roles and directory data
  - `Group.Read.All` - Read group memberships
  - `Mail.Read` - Read mailbox settings
  - `MailboxSettings.Read` - Read mailbox configuration
- **Azure AD Roles:** Global Reader, User Administrator, or Global Administrator
- **Authentication:** Microsoft 365 account with appropriate permissions

## Usage

### Running the Script

1. **Launch from SouliTEK Launcher** (recommended)
   - Open the SouliTEK Launcher
   - Find "Microsoft 365 User List" in the Microsoft 365 category
   - Click the tool card to launch

2. **Run directly via PowerShell:**
   ```powershell
   .\scripts\m365_user_list.ps1
   ```

3. **With custom output folder:**
   ```powershell
   .\scripts\m365_user_list.ps1 -OutputFolder "C:\Reports"
   ```

### First-Time Setup

#### Step 1: Connect to Microsoft Graph
- Tool will prompt for Microsoft 365 authentication
- Sign in with admin account
- Grant required permissions
- Connection saved for future use

#### Step 2: Install Modules (Automatic)
- Tool automatically installs required modules:
  - Microsoft.Graph.Authentication
  - Microsoft.Graph.Users
  - Microsoft.Graph.Identity.SignIns
  - Microsoft.Graph.Identity.DirectoryManagement
  - Microsoft.Graph.Groups
  - Microsoft.Graph.Mail
- First run may take longer for module installation

### Menu Options

#### Option 1: Connect to Microsoft Graph
- First-time users will need to authenticate via browser
- Grant permissions when prompted
- If already connected, you can keep or switch tenants

#### Option 2: Disconnect from Current Tenant
- Disconnects from the current Microsoft 365 tenant
- Clears all cached user data
- Use this to switch to a different tenant

#### Option 3: Retrieve All Users
- Fetches all users from your Microsoft 365 tenant
- Collects comprehensive data:
  - User information
  - Roles and groups
  - MFA status and methods
  - Mailbox configuration
- May take a few moments for large tenants

#### Option 4: View User Summary
- Displays summary statistics
- Total user count
- Enabled vs. disabled accounts
- MFA enabled vs. disabled
- Top 10 users preview

#### Options 5-8: Export Reports
- **Option 5:** TXT Format - Human-readable text format
- **Option 6:** CSV Format - Spreadsheet format for Excel/Google Sheets
- **Option 7:** HTML Format - Professional web report with styling
- **Option 8:** JSON Format - Clean JSON format for automation and integrations

#### Option 9: Help & Information
- Displays detailed help and usage information

## Output Files

### Report Locations
- **Default:** Desktop (`%USERPROFILE%\Desktop`)
- **Custom:** Specified output folder
- **Formats:** TXT, CSV, HTML, and JSON
- **Filename:** `M365_User_List_YYYYMMDD_HHMMSS.[ext]`

### Report Contents

#### User Information
- User Principal Name (UPN)
- Display Name
- Primary Email Address
- Phone Number
- Department
- Job Title
- Office Location
- Company Name
- Account Status (Enabled/Disabled/Blocked sign-in)
- Account Creation Date

#### Permissions & Access
- **Roles:** Array of directory roles (Global Admin, Exchange Admin, etc.)
- **Groups:** Array of group memberships (Security groups + M365 groups)

#### Security Posture
- **MFA Configured:** Boolean
- **MFA Methods:** Array of methods (Authenticator App, Phone, Email, FIDO Key)
- **MFA Method Count:** Number of configured methods
- **MFA Last Sign-In:** Last sign-in date
- **MFA Enforced via CA:** Conditional Access enforcement status

#### Mailbox Configuration
- **Has Mailbox:** Boolean
- **Forwarding Enabled:** Boolean
- **External Forwarding:** Boolean
- **Forwarding Address:** Email address if forwarding is enabled
- **Mailbox Size:** Current mailbox size
- **Mailbox Quota:** Quota limit
- **Litigation Hold:** Boolean
- **Retention Enabled:** Boolean

#### License Information
- **Licenses:** Array of license SKU names (e.g., "M365 Business Premium")
- **License Count:** Number of assigned licenses

#### Sign-In Information
- **Last Sign-In:** Most recent sign-in date and time
- Password Last Changed

## JSON Output Format

The JSON export produces a clean, structured format perfect for automation and integrations:

```json
{
  "Generated": "2025-12-02 14:30:00",
  "Organization": "Contoso Corporation",
  "Domain": "contoso.com",
  "TotalUsers": 150,
  "Users": [
    {
      "UserPrincipalName": "user@tenant.com",
      "DisplayName": "John Doe",
      "AccountEnabled": true,
      "AccountStatus": "Enabled",
      "Licenses": ["M365 Business Premium"],
      "Roles": ["Global Administrator", "SharePoint Administrator"],
      "Groups": ["Marketing", "All Employees"],
      "MFA": {
        "Configured": true,
        "Methods": ["Authenticator App", "Phone"],
        "LastSignIn": "2025-12-02"
      },
      "Mailbox": {
        "ForwardingEnabled": false,
        "ExternalForwarding": false,
        "ForwardingAddress": "None",
        "Size": "2.5 GB",
        "Quota": "50 GB",
        "LitigationHold": false,
        "RetentionEnabled": true
      },
      "LastSignIn": "2025-12-02 10:15:00",
      "CreatedDate": "2024-01-15"
    }
  ]
}
```

## Data Fields

### User Information
- **User Principal Name:** Login email (UPN)
- **Display Name:** Full name
- **Primary Email:** Primary email address (Mail property)
- **Phone Number:** Business or mobile phone
- **Department:** Department name
- **Job Title:** Position title
- **Office Location:** Office location
- **Company Name:** Company name

### Account Status
- **Account Enabled:** Boolean (Enabled/Disabled)
- **Account Status:** String (Enabled/Disabled/Blocked sign-in)
- **Account Created:** Creation date
- **Last Sign-In:** Most recent sign-in date and time

### Permissions & Access
- **Roles:** Array of directory role names (e.g., "Global Administrator")
- **Groups:** Array of group display names (Security + M365 groups)

### Security Posture (MFA)
- **MFA Configured:** Boolean
- **MFA Methods:** Array of method names
  - "Authenticator App"
  - "Phone" (SMS)
  - "Email"
  - "FIDO Key"
- **MFA Method Count:** Number of configured methods
- **MFA Last Sign-In:** Last sign-in date
- **MFA Enforced via CA:** Conditional Access enforcement (Boolean)

### Mailbox Configuration
- **Has Mailbox:** Boolean
- **Forwarding Enabled:** Boolean
- **External Forwarding:** Boolean (if forwarding to external address)
- **Forwarding Address:** Email address if forwarding enabled
- **Mailbox Size:** Current size (when available)
- **Mailbox Quota:** Quota limit (when available)
- **Litigation Hold:** Boolean (when available)
- **Retention Enabled:** Boolean (when available)

### License Information
- **Licenses:** Array of license SKU names (e.g., "M365 Business Premium", "Office 365 E3")
- **License Count:** Number of assigned licenses

## Troubleshooting

### Authentication Fails
**Problem:** Cannot connect to Microsoft Graph

**Solutions:**
1. Verify Microsoft 365 account credentials
2. Check account has required permissions
3. Verify internet connectivity
4. Check if MFA is required
5. Try disconnecting and reconnecting

### Module Installation Fails
**Problem:** Cannot install Microsoft Graph modules

**Solutions:**
1. Run PowerShell as Administrator
2. Check internet connectivity
3. Verify PowerShell execution policy
4. Install modules manually:
   ```powershell
   Install-Module Microsoft.Graph.Authentication -Force
   Install-Module Microsoft.Graph.Users -Force
   Install-Module Microsoft.Graph.Identity.SignIns -Force
   Install-Module Microsoft.Graph.Identity.DirectoryManagement -Force
   ```

### No Users Found
**Problem:** Tool shows no users

**Possible Reasons:**
- Account doesn't have user read permissions
- No users in tenant
- Incorrect tenant connection

**Solutions:**
- Verify account permissions (Global Reader or User Administrator)
- Check Microsoft 365 admin center
- Verify correct tenant connection

### Export Fails
**Problem:** Cannot export user list

**Solutions:**
1. Check disk space in output folder
2. Verify write permissions
3. Close file if already open
4. Check antivirus isn't blocking

### Large Tenant Performance
**Problem:** Export is slow for large tenants

**Causes:**
- Many users (thousands)
- Network latency
- API rate limiting

**Solutions:**
- Normal for large tenants
- Be patient during export
- Export runs in background
- Consider filtering users

## Best Practices

### Regular Exports
- Export user list monthly
- Keep historical records
- Track user changes
- Document license assignments

### Data Privacy
- Handle user data securely
- Store exports in secure location
- Follow data protection regulations
- Limit access to exported files

### License Management
- Regular license audits
- Track license assignments
- Identify unused licenses
- Optimize license usage

## Microsoft Graph Permissions

### Required Permissions
- **User.Read.All:** Read all users
- **UserAuthenticationMethod.Read.All:** Read MFA status and methods
- **Organization.Read.All:** Read organization information
- **Directory.Read.All:** Read directory data, roles, and groups
- **Group.Read.All:** Read group memberships
- **Mail.Read:** Read mailbox settings
- **MailboxSettings.Read:** Read mailbox configuration

### Role Requirements
- **Global Reader:** Read-only access
- **User Administrator:** User management access
- **Global Administrator:** Full access

## Support

For assistance or to report issues:
- **Website:** www.soulitek.co.il
- **Email:** letstalk@soulitek.co.il

---

**Coded by:** SouliTEK  
*IT Solutions for your business*

(C) 2025 SouliTEK - All Rights Reserved









