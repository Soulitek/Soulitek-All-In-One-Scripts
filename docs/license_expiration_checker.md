# License Expiration Checker

## Overview

The **License Expiration Checker** monitors Microsoft 365 license expiration dates and sends alerts for licenses nearing expiration. It's designed for IT administrators managing Microsoft 365 subscriptions and ensuring license compliance.

## Purpose

Automates Microsoft 365 license monitoring:
- License expiration tracking
- Alert system for expiring licenses
- Usage statistics
- Compliance reporting
- Export capabilities

## Features

### 📅 **Expiration Monitoring**
- Check all Microsoft 365 licenses
- Expiration date tracking
- Days until expiration calculation
- Alert thresholds (14 and 30 days)

### ⚠️ **Alert System**
- Alerts for licenses expiring soon
- Configurable warning thresholds
- Critical alerts for immediate attention
- Visual status indicators

### 📊 **Usage Statistics**
- License usage by type
- Assigned vs. available licenses
- User assignment details
- License consumption trends

### 📋 **Reporting**
- Export license status to CSV
- Export to TXT format
- Detailed license information
- Compliance reports

## Requirements

### System Requirements
- **OS:** Windows 10 or Windows 11
- **PowerShell:** Version 5.1 or higher
- **Privileges:** Standard user (Microsoft Graph permissions required)
- **Microsoft Graph:** Microsoft Graph PowerShell SDK modules

### Required Permissions
- **Microsoft Graph:** Directory.Read.All, Organization.Read.All
- **Azure AD:** Global Reader or License Administrator role
- **Authentication:** Microsoft 365 account with appropriate permissions

## Usage

### Running the Script

1. **Launch from SouliTEK Launcher** (recommended)
   - Open the SouliTEK Launcher
   - Find "License Expiration Checker" in the Microsoft 365 category
   - Click the tool card to launch

2. **Run directly via PowerShell:**
   ```powershell
   .\scripts\license_expiration_checker.ps1
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
  - Microsoft.Graph.Identity.DirectoryManagement
- First run may take longer for module installation

### Menu Options

#### Option 1: Check License Status
Displays all Microsoft 365 licenses and expiration dates.
- License names and SKUs
- Expiration dates
- Days until expiration
- Status indicators

#### Option 2: View Expiring Licenses
Shows licenses expiring within threshold periods.
- Licenses expiring in 14 days (critical)
- Licenses expiring in 30 days (warning)
- Sorted by expiration date
- Alert indicators

#### Option 3: License Usage Statistics
Shows license usage and assignment details.
- Total licenses by type
- Assigned licenses count
- Available licenses
- Usage percentage

#### Option 4: Export License Report
Exports comprehensive license report.
- CSV format (spreadsheet)
- TXT format (text report)
- All license details
- Expiration information

## Alert Thresholds

### Critical Alert (14 days)
- Licenses expiring within 14 days
- Requires immediate attention
- Red status indicator
- Priority action needed

### Warning Alert (30 days)
- Licenses expiring within 30 days
- Planning recommended
- Yellow status indicator
- Proactive renewal

## Output Files

### Report Locations
- **Desktop:** Reports saved to `%USERPROFILE%\Desktop`
- **Formats:** CSV and TXT
- **Filename:** `LicenseReport_YYYYMMDD_HHMMSS.[ext]`

### Report Contents
- All license SKUs
- Expiration dates
- Days until expiration
- License status
- Usage statistics

## Troubleshooting

### Authentication Fails
**Problem:** Cannot connect to Microsoft Graph

**Solutions:**
1. Verify Microsoft 365 account credentials
2. Check account has required permissions
3. Verify internet connectivity
4. Check if MFA is required (may need device code flow)
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
   Install-Module Microsoft.Graph.Identity.DirectoryManagement -Force
   ```

### No Licenses Found
**Problem:** Tool shows no licenses

**Possible Reasons:**
- Account doesn't have license read permissions
- No Microsoft 365 licenses in tenant
- Incorrect tenant connection

**Solutions:**
- Verify account permissions (Global Reader or License Administrator)
- Check Microsoft 365 admin center for licenses
- Verify correct tenant connection

### Expiration Dates Incorrect
**Problem:** Expiration dates seem wrong

**Solutions:**
1. Licenses may be on auto-renewal
2. Check Microsoft 365 admin center
3. Verify subscription status
4. Some licenses don't expire (perpetual)

## Best Practices

### Regular Monitoring
- Check licenses monthly
- Set up calendar reminders
- Monitor expiring licenses
- Plan renewals in advance

### License Management
- Keep license inventory updated
- Document license assignments
- Track license usage trends
- Plan for license changes

### Compliance
- Regular license audits
- Document license status
- Track expiration dates
- Maintain license reports

## Microsoft Graph Permissions

### Required Permissions
- **Directory.Read.All:** Read directory data
- **Organization.Read.All:** Read organization information
- **User.Read.All:** Read user information (for license assignments)

### Role Requirements
- **Global Reader:** Read-only access to all admin features
- **License Administrator:** Manage license assignments
- **Global Administrator:** Full access (not required)

## Support

For assistance or to report issues:
- **Website:** www.soulitek.co.il
- **Email:** letstalk@soulitek.co.il

---

**Coded by:** SouliTEK  
*IT Solutions for your business*

(C) 2025 SouliTEK - All Rights Reserved













