# Microsoft 365 User List - Documentation

## Overview

The Microsoft 365 User List tool is a comprehensive PowerShell script that retrieves and lists all users in your Microsoft 365 tenant with detailed information including email addresses, phone numbers, MFA status, and additional user attributes.

## Features

### User Information Collected

- **Email Addresses**: UserPrincipalName and Primary Mail address
- **Phone Numbers**: Business phone and mobile phone
- **MFA Status**: 
  - Enabled/Disabled status
  - Number of MFA methods registered
  - Default MFA method type
- **Account Status**: Enabled/Disabled
- **Organizational Information**:
  - Job Title
  - Department
  - Office Location
  - Company Name
- **License Information**: Number of assigned licenses
- **Activity Data**:
  - Last Sign-In date and time
  - Account creation date

### Reporting Capabilities

1. **Console Summary**: Real-time statistics and top 10 users preview
2. **TXT Export**: Human-readable text format for documentation
3. **CSV Export**: Spreadsheet format for Excel/Google Sheets analysis
4. **HTML Export**: Professional web report with styling and statistics

## Requirements

### Prerequisites

- **Windows PowerShell 5.1** or **PowerShell 7+**
- **Microsoft Graph PowerShell SDK** (automatically installed if missing)
- **Internet connectivity** to graph.microsoft.com
- **Administrative privileges** (recommended for module installation)

### Required Permissions

The script requires the following Microsoft Graph permissions:

- **User.Read.All**: Read all user profiles
- **UserAuthenticationMethod.Read.All**: Read user MFA authentication methods
- **Organization.Read.All**: Read organization information

### Required Roles

You must have one of the following roles in Microsoft 365:

- **Global Administrator** (recommended)
- **Global Reader** (read-only access)
- **User Administrator** (limited user management)

## Installation

The script is included in the SouliTEK All-In-One Scripts package. No separate installation is required.

### Module Auto-Installation

The script automatically installs required modules if they are missing:

1. **NuGet Package Provider**: Required for PowerShellGet
2. **PowerShellGet**: Module management
3. **Microsoft.Graph**: Main Graph PowerShell SDK
4. **Microsoft.Graph.Authentication**: Authentication module
5. **Microsoft.Graph.Users**: User management module
6. **Microsoft.Graph.Identity.SignIns**: Authentication methods module
7. **Microsoft.Graph.Identity.DirectoryManagement**: Directory management module

## Usage

### Launching the Tool

#### Method 1: Via GUI Launcher (Recommended)

1. Open the SouliTEK Launcher (`SouliTEK-Launcher-WPF.ps1`)
2. Navigate to the **M365** category
3. Click **"M365 User List"**

#### Method 2: Direct PowerShell Execution

```powershell
.\scripts\m365_user_list.ps1
```

### Menu Options

1. **Connect to Microsoft Graph**
   - Establishes connection to Microsoft 365 tenant
   - Opens browser for authentication (first-time only)
   - Verifies required permissions
   - Shows connection status and tenant information

2. **Retrieve All Users**
   - Fetches all users from your Microsoft 365 tenant
   - Processes user details including MFA status
   - Shows progress indicator for large tenants
   - Displays summary statistics upon completion

3. **View User Summary**
   - Displays overall statistics:
     - Total users count
     - Enabled/Disabled account breakdown
     - MFA enabled/disabled statistics with percentages
   - Shows top 10 users preview sorted by Display Name

4. **Export Report - TXT Format**
   - Exports to human-readable text file
   - Includes all user details in structured format
   - Saved to Desktop by default
   - Automatically opens file after export

5. **Export Report - CSV Format**
   - Exports to comma-separated values format
   - Compatible with Excel, Google Sheets, and other spreadsheet applications
   - All user attributes included as columns
   - Saved to Desktop by default

6. **Export Report - HTML Format**
   - Professional web report with modern styling
   - Includes statistics dashboard with visual boxes
   - Color-coded badges for account and MFA status
   - Sortable table with all user details
   - Saved to Desktop and opens in default browser

7. **Help & Information**
   - Comprehensive usage guide
   - Requirements and permissions documentation
   - Security notes and best practices
   - Support contact information

8. **Exit**
   - Disconnects from Microsoft Graph
   - Cleans up authentication tokens
   - Closes the tool

## Output Details

### User Data Fields

| Field | Description | Example |
|-------|-------------|---------|
| DisplayName | User's display name | John Doe |
| EmailAddress | UserPrincipalName | john.doe@contoso.com |
| PrimaryEmail | Primary mail address | john.doe@contoso.com |
| PhoneNumber | Business or mobile phone | +1-555-123-4567 |
| JobTitle | Job title | IT Administrator |
| Department | Department name | IT Services |
| OfficeLocation | Office location | Building A, Floor 3 |
| CompanyName | Company name | Contoso Inc. |
| AccountEnabled | Account status (boolean) | True/False |
| MfaEnabled | MFA enabled status (boolean) | True/False |
| MfaMethodCount | Number of MFA methods | 2 |
| MfaDefaultMethod | Default MFA method type | microsoft.graph.phoneAuthenticationMethod |
| Licenses | Assigned license count | 3 license(s) |
| LastSignIn | Last sign-in timestamp | 2025-01-15 14:30:00 |
| CreatedDate | Account creation date | 2024-06-01 |

### Export File Naming

All export files use the following naming convention:

- **TXT**: `M365_User_List_YYYYMMDD_HHMMSS.txt`
- **CSV**: `M365_User_List_YYYYMMDD_HHMMSS.csv`
- **HTML**: `M365_User_List_YYYYMMDD_HHMMSS.html`

Files are saved to the Desktop by default (`%USERPROFILE%\Desktop`).

## Authentication

### First-Time Connection

1. Run the tool and select option **1. Connect to Microsoft Graph**
2. A browser window will open automatically
3. Sign in with your Microsoft 365 administrator account
4. Review and accept the required permissions:
   - User.Read.All
   - UserAuthenticationMethod.Read.All
   - Organization.Read.All
5. The connection is established and cached for future sessions

### Subsequent Connections

- If already authenticated, the script will detect and use existing connection
- No browser prompt required for cached sessions
- Connection status is displayed in the main menu

### Disconnecting

- Select option **8. Exit** to properly disconnect
- Alternatively, run `Disconnect-MgGraph` in PowerShell
- Cached credentials remain for faster reconnection

## Troubleshooting

### Common Issues

#### 1. Module Installation Fails

**Problem**: PowerShellGet or Microsoft Graph modules fail to install

**Solutions**:
- Run PowerShell as Administrator
- Check internet connectivity
- Temporarily disable antivirus/firewall
- Install manually: `Install-Module Microsoft.Graph -Scope CurrentUser -Force`

#### 2. Authentication Fails

**Problem**: Cannot connect to Microsoft Graph

**Solutions**:
- Verify you have Global Administrator or Global Reader role
- Check internet connectivity to graph.microsoft.com
- Clear cached credentials: `Disconnect-MgGraph`
- Ensure required permissions are granted in Azure AD

#### 3. Insufficient Permissions

**Problem**: Error message about missing permissions

**Solutions**:
- Verify role assignment in Microsoft 365 Admin Center
- Global Administrator or Global Reader role required
- Check Azure AD app permissions if using service principal

#### 4. No Users Retrieved

**Problem**: Script reports "No users found"

**Solutions**:
- Verify connection is established (check menu status)
- Ensure tenant has users
- Check if filtering is applied (script retrieves all users)
- Verify User.Read.All permission is granted

#### 5. MFA Status Shows as Unknown

**Problem**: MFA status appears as "Unknown" or "Disabled" for all users

**Solutions**:
- Verify UserAuthenticationMethod.Read.All permission
- Some tenants may have MFA enforced at tenant level (Security Defaults)
- Check if MFA is configured in Azure AD
- Re-run authentication to refresh permissions

#### 6. Export Files Not Opening

**Problem**: Files are created but don't open automatically

**Solutions**:
- Check if file exists in Desktop folder
- Verify default application associations
- Manually open file from Desktop
- Check Windows file associations

### Performance Considerations

#### Large Tenants (>1000 users)

- Retrieving all users may take several minutes
- Progress indicator shows real-time status
- Consider exporting to CSV for large datasets
- Processing includes MFA status checks which may slow down retrieval

#### Network Issues

- Ensure stable internet connection
- Graph API has rate limiting (throttling)
- Script includes error handling for network interruptions
- Retry connection if timeout occurs

## Security Notes

### Data Privacy

- **Read-Only Operations**: This tool only reads user information, no modifications are made
- **Local Storage**: All data is stored locally on your computer
- **No Data Transmission**: User data is not transmitted to third parties
- **Authentication**: Uses Microsoft's secure OAuth 2.0 authentication

### Best Practices

1. **Least Privilege**: Use Global Reader role instead of Global Administrator when possible
2. **Secure Storage**: Protect exported reports containing sensitive user information
3. **Access Control**: Limit access to exported reports
4. **Data Retention**: Delete exported reports when no longer needed
5. **Audit Logs**: Review Azure AD audit logs for compliance

### Compliance Considerations

- Ensure compliance with GDPR, CCPA, and other data protection regulations
- User consent may be required in some jurisdictions
- Export files may contain PII (Personally Identifiable Information)
- Implement appropriate access controls and encryption for exported data

## Examples

### Example 1: Quick User Overview

```powershell
# Launch tool
.\scripts\m365_user_list.ps1

# 1. Connect to Microsoft Graph (option 1)
# 2. Retrieve All Users (option 2)
# 3. View User Summary (option 3)
```

### Example 2: Export CSV for Analysis

```powershell
# After retrieving users:
# 1. Connect to Microsoft Graph
# 2. Retrieve All Users
# 5. Export Report - CSV Format
```

### Example 3: Generate HTML Report

```powershell
# Complete workflow:
# 1. Connect to Microsoft Graph
# 2. Retrieve All Users
# 6. Export Report - HTML Format
```

## Integration with Other Tools

### License Expiration Checker

- User list shows license assignments per user
- License Expiration Checker shows overall license capacity
- Combine for complete license management overview

## Support

For technical support or feature requests:

- **Website**: www.soulitek.co.il
- **Email**: letstalk@soulitek.co.il
- **Company**: SouliTEK - IT Solutions for your business

## Version History

### Version 1.0.0 (2025-01-15)

- Initial release
- Microsoft Graph integration
- User information retrieval with MFA status
- TXT, CSV, and HTML export formats
- Menu-based interface with SouliTEK branding

## License

(C) 2025 SouliTEK - All Rights Reserved

This script is provided as part of the SouliTEK All-In-One Scripts package.

---

**Last Updated**: 2025-01-15  
**Script Version**: 1.0.0  
**Author**: SouliTEK (Soulitek.co.il)

