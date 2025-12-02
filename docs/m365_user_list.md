# Microsoft 365 User List

## Overview

The **Microsoft 365 User List** tool exports comprehensive lists of Microsoft 365 users with detailed information including licenses, sign-in status, and account details. It's designed for IT administrators managing Microsoft 365 tenants.

## Purpose

Provides detailed Microsoft 365 user information:
- Complete user list export
- License assignment details
- Sign-in status and last sign-in
- Account status information
- Export to multiple formats

## Features

### 👥 **User Information**
- All Microsoft 365 users
- User display names and emails
- Account status (enabled/disabled)
- Department and job title
- Office location

### 📋 **License Details**
- Assigned licenses per user
- License SKU information
- License status
- License assignment date

### 🔐 **Sign-In Information**
- Last sign-in date and time
- Sign-in status
- Account creation date
- Password last changed

### 📊 **Export Options**
- Export to CSV format
- Export to TXT format
- Comprehensive user data
- Customizable output

## Requirements

### System Requirements
- **OS:** Windows 10 or Windows 11
- **PowerShell:** Version 5.1 or higher
- **Privileges:** Standard user (Microsoft Graph permissions required)
- **Microsoft Graph:** Microsoft Graph PowerShell SDK modules

### Required Permissions
- **Microsoft Graph:** User.Read.All, Directory.Read.All
- **Azure AD:** Global Reader, User Administrator, or Global Administrator
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
- First run may take longer for module installation

### Menu Options

#### Option 1: Export All Users
Exports complete user list with all details.
- All users in tenant
- Complete information
- License assignments
- Sign-in data

#### Option 2: Export Enabled Users Only
Exports only active (enabled) users.
- Filters out disabled accounts
- Active users only
- Useful for active user reports

#### Option 3: Export Users with Licenses
Exports users who have licenses assigned.
- Licensed users only
- License details included
- License SKU information

#### Option 4: View User Summary
Displays summary statistics.
- Total user count
- Enabled vs. disabled
- Licensed vs. unlicensed
- Last sign-in statistics

#### Option 5: Export Custom Report
Customizable export with selected fields.
- Choose fields to include
- Custom filtering options
- Flexible output format

## Output Files

### Report Locations
- **Default:** Desktop (`%USERPROFILE%\Desktop`)
- **Custom:** Specified output folder
- **Formats:** CSV and TXT
- **Filename:** `M365UserList_YYYYMMDD_HHMMSS.[ext]`

### Report Contents
- User Principal Name (UPN)
- Display Name
- Email Address
- Account Status (Enabled/Disabled)
- Department
- Job Title
- Office Location
- Assigned Licenses
- Last Sign-In Date
- Account Creation Date
- Password Last Changed

## Data Fields

### User Information
- **User Principal Name:** Login email
- **Display Name:** Full name
- **Email:** Primary email address
- **Department:** Department name
- **Job Title:** Position title
- **Office:** Office location

### Account Status
- **Account Enabled:** Yes/No
- **Account Created:** Creation date
- **Last Sign-In:** Most recent sign-in
- **Password Last Changed:** Password update date

### License Information
- **Licenses Assigned:** License SKU names
- **License Count:** Number of licenses
- **License Status:** Active/Inactive

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
- **Directory.Read.All:** Read directory data
- **AuditLog.Read.All:** Read sign-in logs (optional)

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









