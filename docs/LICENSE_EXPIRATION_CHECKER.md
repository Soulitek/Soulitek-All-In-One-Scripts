# License Expiration Checker - Professional Tool

**Created:** October 23, 2025  
**Author:** Soulitek.co.il  
**Version:** 1.0  

---

## Overview

The **License Expiration Checker** is a professional PowerShell tool designed for Microsoft 365 administrators to monitor license subscriptions, track seat usage, and receive alerts for licenses nearing capacity or expiration. This tool provides comprehensive visibility into license allocation and helps prevent service disruptions due to license shortages.

## Features

### 1. **Microsoft Graph Integration**
- Connects securely to Microsoft 365 tenant via Microsoft Graph API
- Uses modern authentication with OAuth 2.0
- Requires Organization.Read.All permissions
- Secure browser-based authentication

### 2. **License Status Monitoring**
- Real-time license subscription data
- Total, used, and available seat counts
- Usage percentage calculations
- Color-coded status indicators
- Friendly license names for easy identification

### 3. **Alert System**
- **CRITICAL**: Licenses with no available seats (Red)
- **WARNING**: Licenses with 5 or fewer seats remaining (Yellow)
- **OK**: Licenses with sufficient availability (Green)
- Multiple alert delivery methods

### 4. **Alert Delivery Methods**
- **Email Alerts**: HTML-formatted email notifications
- **Teams Webhooks**: Direct notifications to Microsoft Teams channels
- **Alert Reports**: Standalone HTML reports for documentation

### 5. **Detailed Reporting**
- Comprehensive service plan breakdowns
- Usage statistics and trends
- Top license consumers
- Visual usage bars and percentages
- Export capabilities (TXT, CSV, HTML)

### 6. **Professional Interface**
- Menu-based navigation
- Real-time connection status
- Color-coded output for easy interpretation
- Soulitek branding throughout
- Comprehensive help guide

---

## Requirements

### Software Requirements
1. **Windows PowerShell 5.1+** or **PowerShell 7+**
2. **Microsoft Graph PowerShell SDK**
   ```powershell
   Install-Module Microsoft.Graph -Scope CurrentUser
   ```

### Permissions Required
- **Azure AD Role**: Global Administrator or Global Reader
- **Microsoft Graph Permission**: `Organization.Read.All`

### Network Requirements
- Internet connectivity for Microsoft Graph API access
- HTTPS (443) access to `graph.microsoft.com`

---

## Installation

### Step 1: Install Microsoft Graph PowerShell SDK

Open PowerShell as Administrator and run:

```powershell
# Install for current user
Install-Module Microsoft.Graph -Scope CurrentUser

# Or install for all users (requires admin)
Install-Module Microsoft.Graph -Scope AllUsers
```

### Step 2: Download the Script

Place `license_expiration_checker.ps1` in your scripts folder:
```
C:\Users\<YourName>\Soulitek-AIO\scripts\
```

### Step 3: Run the Script

```powershell
.\license_expiration_checker.ps1
```

---

## Usage Guide

### Main Menu Options

#### [1] Connect to Microsoft Graph
- **Purpose**: Authenticate to your Microsoft 365 tenant
- **Process**: Opens browser for secure sign-in
- **Required First**: Must connect before using other features
- **Shows**: Tenant ID, account, and granted permissions

#### [2] License Status Check
- **Purpose**: Display all Microsoft 365 licenses
- **Shows**:
  - License friendly name and SKU
  - Total seats allocated
  - Used seats (assigned to users)
  - Available seats remaining
  - Usage percentage
  - Alert status (Critical/Warning/OK)
- **Color Coding**:
  - 🔴 Red: No seats available
  - 🟡 Yellow: 5 or fewer seats remaining
  - 🟢 Green: Sufficient seats available

#### [3] Detailed License Report
- **Purpose**: Comprehensive analysis with service plans
- **Shows**:
  - All license properties
  - Prepaid units (enabled, warning, suspended)
  - Complete service plan list
  - Provisioning status for each service
  - Useful for understanding what's included in each license

#### [4] Usage Statistics
- **Purpose**: Analyze license allocation patterns
- **Shows**:
  - Overall tenant statistics
  - Total licenses vs. used vs. available
  - Top 5 license consumers
  - Visual usage bars
  - Licenses requiring attention
  - Allocation recommendations

#### [5] Send Alerts
- **Purpose**: Configure notifications for critical licenses
- **Options**:
  1. **Email Alert**: HTML-formatted email (requires SMTP config)
  2. **Teams Webhook**: Post to Microsoft Teams channel
  3. **Generate Alert Report**: Standalone HTML report
- **Triggers**: Automatically identifies critical and warning licenses
- **Threshold**: Configurable (default: 14 days for alerts, 30 days for warnings)

#### [6] Export Report
- **Purpose**: Save license data for documentation
- **Formats**:
  - **Text (.txt)**: Human-readable report for viewing
  - **CSV (.csv)**: Spreadsheet format for analysis
  - **HTML (.html)**: Professional web report with styling
  - **All Formats**: Export all three at once
- **Location**: Saved to Desktop by default

#### [7] Help
- **Purpose**: In-app usage guide
- **Content**:
  - Feature explanations
  - Understanding license status
  - Requirements and permissions
  - Tips and best practices

---

## Setting Up Alerts

### Email Alerts

#### Configuration Required:
- SMTP server address (e.g., `smtp.office365.com`)
- SMTP port (typically `587` for TLS)
- From email address
- To email address
- SMTP authentication credentials

#### Example Configuration:
```
SMTP Server: smtp.office365.com
SMTP Port: 587
From: alerts@yourdomain.com
To: admin@yourdomain.com
```

**Note**: The script prepares the email template but requires manual SMTP credential configuration for actual sending.

### Teams Webhook Alerts

#### Setup Steps:
1. Open Microsoft Teams
2. Navigate to target channel
3. Click **⋯ (More options)** > **Connectors**
4. Search for **Incoming Webhook**
5. Click **Configure**
6. Give it a name (e.g., "License Alerts")
7. Copy the webhook URL
8. Use this URL in the script when prompted

#### Webhook Format:
```
https://outlook.office.com/webhook/[unique-id]/IncomingWebhook/[channel-id]
```

#### Message Format:
Teams alerts include:
- Alert severity (color-coded)
- License name
- Seat usage details
- Timestamp
- Actionable information

---

## Understanding License Status

### Alert Levels

| Status | Condition | Color | Action Required |
|--------|-----------|-------|-----------------|
| **CRITICAL** | 0 available seats | 🔴 Red | Immediate - Purchase licenses |
| **WARNING** | ≤5 available seats | 🟡 Yellow | Soon - Plan to purchase |
| **OK** | >5 available seats | 🟢 Green | None - Monitor regularly |

### Usage Percentage Indicators

| Usage % | Status | Recommendation |
|---------|--------|----------------|
| 0-79% | Healthy | Normal monitoring |
| 80-99% | Approaching Capacity | Plan for expansion |
| 100% | At Maximum | Immediate action needed |

### Seat Types

- **Enabled**: Active, billable seats
- **Warning**: Seats in grace period (approaching expiration)
- **Suspended**: Seats that are suspended (overdue payment)
- **Consumed**: Seats currently assigned to users

---

## Common License SKU Names

The tool automatically translates SKU part numbers to friendly names:

| SKU Part Number | Friendly Name |
|----------------|---------------|
| SPE_E3 | Microsoft 365 E3 |
| SPE_E5 | Microsoft 365 E5 |
| ENTERPRISEPACK | Office 365 E3 |
| ENTERPRISEPREMIUM | Office 365 E5 |
| SPB | Microsoft 365 Business Premium |
| O365_BUSINESS_ESSENTIALS | Microsoft 365 Business Basic |
| O365_BUSINESS_PREMIUM | Microsoft 365 Business Standard |
| POWER_BI_PRO | Power BI Pro |
| EMSPREMIUM | Enterprise Mobility + Security E5 |
| EMS | Enterprise Mobility + Security E3 |

*...and many more in the script*

---

## Export Formats

### Text Report (.txt)
- Clean, readable format
- Perfect for quick review
- Opens automatically in Notepad
- Includes all license details

### CSV Report (.csv)
- Structured data format
- Import into Excel for analysis
- Supports pivot tables and charts
- Great for tracking over time

### HTML Report (.html)
- Professional web-based report
- Color-coded status indicators
- Visual usage bars
- Responsive design
- Print-friendly
- Includes Soulitek branding

---

## Best Practices

### 1. **Regular Monitoring**
- Run weekly license checks
- Export reports monthly for records
- Track usage trends over time
- Document seasonal patterns

### 2. **Alert Configuration**
- Set up Teams webhooks for automatic notifications
- Configure alerts to notify IT team immediately
- Test alert delivery before relying on it
- Document alert thresholds in your runbook

### 3. **License Optimization**
- Review unused licenses monthly
- Identify over-provisioned licenses
- Consider moving users to lower-tier plans when appropriate
- Remove licenses from inactive users

### 4. **Documentation**
- Export reports for compliance audits
- Keep historical data for trend analysis
- Document license allocation decisions
- Maintain changelog of license purchases

### 5. **Capacity Planning**
- Monitor usage trends to predict future needs
- Budget for license purchases 1-2 quarters ahead
- Consider seasonal hiring patterns
- Plan for growth with 10-15% buffer

### 6. **Security**
- Use Global Reader role when possible (read-only)
- Limit access to the tool
- Secure exported reports (contain sensitive data)
- Log all license checks for audit trail

---

## Troubleshooting

### Issue: "Microsoft Graph Module Not Found"
**Solution**: Install the module
```powershell
Install-Module Microsoft.Graph -Scope CurrentUser
```

### Issue: "Insufficient Permissions"
**Cause**: Missing `Organization.Read.All` permission  
**Solution**: 
1. Ensure you're a Global Admin or Global Reader
2. Consent to permissions during first login
3. Contact your tenant admin to grant permissions

### Issue: "Connection Failed"
**Possible Causes**:
- Network connectivity issue
- Firewall blocking port 443
- Proxy configuration required
- Browser authentication cancelled

**Solution**: 
- Check internet connection
- Verify firewall allows HTTPS to graph.microsoft.com
- Complete authentication in browser

### Issue: "Teams Webhook Failed"
**Possible Causes**:
- Invalid webhook URL
- Webhook was deleted
- Channel was deleted
- Network issue

**Solution**:
- Verify webhook URL is correct
- Recreate webhook in Teams
- Test with simple message first

### Issue: "No Expiration Dates Shown"
**Note**: Microsoft 365 subscriptions retrieved via `Get-MgSubscribedSku` typically don't include explicit expiration dates. This information is in the Microsoft 365 Admin Center billing section or separate Graph API endpoints for subscriptions.

**Workaround**: The tool focuses on seat capacity alerts, which are equally important indicators of license issues.

---

## Security Considerations

### Data Handled
- License subscription names and SKUs
- Seat counts (total, used, available)
- Service plan names
- Tenant ID (non-sensitive identifier)
- No personal user data or PII

### Permissions
- **Organization.Read.All**: Read-only access to organization info
- Does NOT grant access to:
  - User personal data
  - Email content
  - Files or documents
  - Modify operations

### Best Practices
1. Use least-privilege accounts when possible
2. Run script only on trusted machines
3. Secure exported reports (contain business data)
4. Don't share webhook URLs publicly
5. Regularly review who has access to the tool

---

## Automation Ideas

### Scheduled Task Setup

Create a scheduled task to run the script weekly:

```powershell
# Example: Register scheduled task (requires admin)
$trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Monday -At 8am
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" `
    -Argument "-File C:\Scripts\license_expiration_checker.ps1"
$principal = New-ScheduledTaskPrincipal -UserId "DOMAIN\ServiceAccount" `
    -LogonType ServiceAccount
Register-ScheduledTask -TaskName "License Check" `
    -Trigger $trigger -Action $action -Principal $principal
```

### Integration with Monitoring Systems

Export CSV data for integration with:
- Power BI dashboards
- SIEM systems
- ITSM platforms
- Custom monitoring solutions

---

## Known Limitations

1. **Expiration Dates**: `Get-MgSubscribedSku` doesn't return explicit expiration dates for most subscriptions. Use Microsoft 365 Admin Center for subscription renewal dates.

2. **Trial Licenses**: Trial licenses may show as active but have hidden expiration dates.

3. **Add-on Licenses**: Some add-on licenses may not appear separately if bundled.

4. **Real-time Sync**: License data may have a small delay (typically < 5 minutes) from actual assignment changes.

---

## Version History

### Version 1.0 (October 23, 2025)
- Initial release
- Microsoft Graph integration
- License status monitoring
- Usage statistics
- Alert system (Email, Teams, Reports)
- Export functionality (TXT, CSV, HTML)
- Professional interface with help guide

---

## Support

### Getting Help

**Soulitek IT Solutions**  
- Website: [https://soulitek.co.il](https://soulitek.co.il)
- Email: letstalk@soulitek.co.il
- Phone: Contact via website

### Professional Services

Soulitek offers:
- Microsoft 365 license optimization consulting
- Automated monitoring setup
- Custom reporting solutions
- License management training
- IT infrastructure support

---

## License & Disclaimer

**Copyright (C) 2025 Soulitek - All Rights Reserved**

This tool is provided "AS IS" without warranty of any kind. Use at your own risk. The user is solely responsible for any outcomes, damages, or issues that may arise from using this script. By running this tool, you acknowledge and accept full responsibility for its use.

---

## Related Documentation

- [Microsoft Graph API Documentation](https://docs.microsoft.com/en-us/graph/)
- [Get-MgSubscribedSku Reference](https://docs.microsoft.com/en-us/powershell/module/microsoft.graph.identity.directorymanagement/get-mgsubscribedsku)
- [Microsoft 365 License Names](https://docs.microsoft.com/en-us/azure/active-directory/enterprise-users/licensing-service-plan-reference)
- [Teams Incoming Webhooks](https://docs.microsoft.com/en-us/microsoftteams/platform/webhooks-and-connectors/how-to/add-incoming-webhook)

---

**Generated by:** License Expiration Checker Tool  
**Coded by:** Soulitek.co.il  
**Last Updated:** October 23, 2025


