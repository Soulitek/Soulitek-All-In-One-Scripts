# SharePoint Site Collection Inventory

## Overview

The **SharePoint Site Collection Inventory** tool builds a full map of your SharePoint environment by extracting comprehensive information about all SharePoint sites in your Microsoft 365 tenant. It's designed for IT administrators managing SharePoint environments and conducting site audits.

## Purpose

Provides complete SharePoint environment visibility:
- Full site collection inventory with all details
- Site template identification (Team site / Communication site)
- M365 Group connection status
- Storage usage per site
- Site ownership information
- Last activity tracking

## Features

### 📊 **Site Inventory**
- Complete list of all SharePoint sites in tenant
- Site URL (web address)
- Display name
- Site template (Team Site, Communication Site, etc.)
- Site type (Connected to M365 Group or Standalone)
- Site creation date

### 🔗 **Group Connection**
- Detects if site is connected to Microsoft 365 Group
- Shows Group ID when connected
- Identifies standalone sites (not connected to groups)

### 💾 **Storage Information**
- Storage used per site
- Aggregated from all document libraries
- Human-readable format (MB, GB, TB)

### 👥 **Ownership**
- Lists all site owners
- Retrieves owners from M365 Groups (when connected)
- Shows owner count per site

### 📅 **Activity Tracking**
- Last activity date per site
- Based on site and drive modifications
- Helps identify inactive sites

### 📋 **Export Options**
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
  - `Sites.Read.All` - Read all SharePoint sites
  - `Group.Read.All` - Read group information
  - `Organization.Read.All` - Read organization info
- **Azure AD Roles:** Global Reader, SharePoint Administrator, or Global Administrator
- **Authentication:** Microsoft 365 account with appropriate permissions

## Usage

### Running the Script

1. **Launch from SouliTEK Launcher** (recommended)
   - Open the SouliTEK Launcher
   - Find "SharePoint Site Collection Inventory" in the Microsoft 365 category
   - Click the tool card to launch

2. **Run directly via PowerShell:**
   ```powershell
   .\scripts\sharepoint_site_inventory.ps1
   ```

3. **With custom output folder:**
   ```powershell
   .\scripts\sharepoint_site_inventory.ps1 -OutputFolder "C:\Reports"
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
  - Microsoft.Graph.Sites
  - Microsoft.Graph.Groups
  - Microsoft.Graph.Identity.DirectoryManagement
- First run may take longer for module installation

### Menu Options

#### Option 1: Connect to Microsoft Graph
- First-time users will need to authenticate via browser
- Grant permissions when prompted
- If already connected, you can keep or switch tenants

#### Option 2: Disconnect from Current Tenant
- Disconnects from the current Microsoft 365 tenant
- Clears all cached site data
- Use this to switch to a different tenant

#### Option 3: Retrieve All Sites
- Fetches all SharePoint sites from your Microsoft 365 tenant
- Collects comprehensive data:
  - Site information
  - Template and type
  - Storage usage
  - Ownership
  - Activity dates
- May take a few moments for large tenants

#### Option 4: View Site Summary
- Displays summary statistics
- Total site count
- Team sites vs. Communication sites
- Group-connected vs. standalone sites
- Top 10 sites preview

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
- **Filename:** `SharePoint_Site_Inventory_YYYYMMDD_HHMMSS.[ext]`

### Report Contents

#### Site Information
- **Site URL:** Full web address of the site
- **Display Name:** Site display name
- **Template:** Site template (Team Site, Communication Site, etc.)
- **Site Type:** Connected to M365 Group or Standalone
- **Created Date:** When the site was created

#### Group Connection
- **Connected to Group:** Boolean indicating M365 Group connection
- **Group ID:** Microsoft 365 Group ID (when connected)

#### Storage Information
- **Storage Used:** Total storage used across all document libraries
- Formatted in human-readable units (MB, GB, TB)

#### Ownership
- **Owners:** List of site owners (email addresses or display names)
- **Owner Count:** Number of owners

#### Activity
- **Last Activity Date:** Most recent activity on the site
- Based on site and drive modifications

## JSON Output Format

The JSON export produces a clean, structured format perfect for automation and integrations:

```json
{
  "Generated": "2025-12-02 14:30:00",
  "Organization": "Contoso Corporation",
  "Domain": "contoso.com",
  "TotalSites": 45,
  "Sites": [
    {
      "SiteURL": "https://contoso.sharepoint.com/sites/TeamSite",
      "DisplayName": "Marketing Team Site",
      "Template": "Team Site",
      "SiteType": "Connected to M365 Group",
      "ConnectedToGroup": true,
      "GroupId": "12345678-1234-1234-1234-123456789012",
      "StorageUsed": "2.5 GB",
      "Owners": [
        "admin@contoso.com",
        "manager@contoso.com"
      ],
      "LastActivityDate": "2025-12-01",
      "CreatedDate": "2024-01-15"
    }
  ]
}
```

## Data Fields

### Site Information
- **Site URL:** Full web address (e.g., https://tenant.sharepoint.com/sites/sitename)
- **Display Name:** Site display name
- **Template:** Site template type
  - "Team Site" - Standard team collaboration site
  - "Communication Site" - Public-facing communication site
  - Other templates as detected
- **Site Type:** 
  - "Connected to M365 Group" - Site has associated M365 Group
  - "Standalone Site" - Site without M365 Group connection
- **Created Date:** Site creation date

### Group Connection
- **Connected to Group:** Boolean (true/false)
- **Group ID:** Microsoft 365 Group ID (when connected)

### Storage Information
- **Storage Used:** Total storage across all document libraries
- Formatted as human-readable string (e.g., "2.5 GB", "150 MB")

### Ownership
- **Owners:** Array of owner email addresses or display names
- Retrieved from M365 Group owners (when connected)
- May show "Not Available" for standalone sites without accessible permissions

### Activity
- **Last Activity Date:** Most recent activity date
- Based on site and drive last modified dates
- Shows "Never" if no activity detected

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
   Install-Module Microsoft.Graph.Sites -Force
   Install-Module Microsoft.Graph.Groups -Force
   ```

### No Sites Found
**Problem:** Tool shows no sites

**Possible Reasons:**
- Account doesn't have site read permissions
- No sites in tenant
- Incorrect tenant connection

**Solutions:**
- Verify account permissions (Global Reader or SharePoint Administrator)
- Check SharePoint admin center
- Verify correct tenant connection

### Storage Information Not Available
**Problem:** Storage shows "0 MB" for all sites

**Possible Reasons:**
- Insufficient permissions to read drive quotas
- Sites have no document libraries
- API limitations

**Solutions:**
- Verify Sites.Read.All permission is granted
- Check if sites have document libraries
- Some storage information may require additional permissions

### Owners Not Available
**Problem:** Owners show "Not Available"

**Possible Reasons:**
- Site is standalone (not connected to M365 Group)
- Insufficient permissions to read site permissions
- Site permissions not accessible via Graph API

**Solutions:**
- For group-connected sites, owners should be available
- Standalone sites may require additional permissions
- Check SharePoint admin center for manual verification

### Export Fails
**Problem:** Cannot export site list

**Solutions:**
1. Check disk space in output folder
2. Verify write permissions
3. Close file if already open
4. Check antivirus isn't blocking

### Large Tenant Performance
**Problem:** Export is slow for large tenants

**Causes:**
- Many sites (hundreds or thousands)
- Network latency
- API rate limiting
- Storage calculation for each site

**Solutions:**
- Normal for large tenants
- Be patient during export
- Export runs in background
- Consider filtering sites in future versions

## Best Practices

### Regular Audits
- Export site inventory monthly
- Keep historical records
- Track site growth over time
- Document site ownership changes

### Storage Management
- Identify sites with high storage usage
- Plan for storage optimization
- Track storage growth trends
- Identify unused or abandoned sites

### Site Governance
- Review site ownership regularly
- Identify sites without owners
- Track inactive sites
- Plan for site lifecycle management

### Data Privacy
- Handle site data securely
- Store exports in secure location
- Follow data protection regulations
- Limit access to exported files

## Microsoft Graph Permissions

### Required Permissions
- **Sites.Read.All:** Read all SharePoint sites
- **Group.Read.All:** Read group information (for group-connected sites)
- **Organization.Read.All:** Read organization information

### Role Requirements
- **Global Reader:** Read-only access
- **SharePoint Administrator:** SharePoint management access
- **Global Administrator:** Full access

## Support

For assistance or to report issues:
- **Website:** www.soulitek.co.il
- **Email:** letstalk@soulitek.co.il

---

**Coded by:** SouliTEK  
*IT Solutions for your business*

(C) 2025 SouliTEK - All Rights Reserved

