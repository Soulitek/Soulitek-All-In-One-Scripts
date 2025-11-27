# Local Admin Users Checker

## Overview

The Local Admin Users Checker identifies users with local administrator privileges and flags potentially unnecessary or suspicious admin accounts. This is a critical security tool as admin accounts are a common attack vector.

**Version:** 1.0.0  
**Category:** Security  
**Requirements:** Windows 10/11, Administrator privileges

## Features

### Account Analysis
- **Full Admin List**: Lists all members of the local Administrators group
- **Risk Assessment**: High, Medium, Low risk levels
- **Pattern Detection**: Identifies suspicious account names
- **Account Status**: Checks if accounts are enabled/disabled
- **Password Policy**: Flags accounts with password never expires

### Account Types Detected
- Local user accounts
- Domain accounts
- Built-in system accounts
- Service accounts

### Export Options
- Text file (.txt)
- CSV file (.csv)
- HTML report (.html) with SouliTEK branding

## Menu Options

| Option | Description |
|--------|-------------|
| 1. Full Scan | Scan and analyze all local administrator accounts |
| 2. View Suspicious Admins | Show only suspicious/unnecessary admin accounts |
| 3. Export Results | Export scan results to file |
| 4. Help | Show usage instructions |
| 0. Exit | Exit the tool |

## Risk Levels

### High Risk (Red)
- **Disabled accounts** still in Administrators group
- **Generic account names**: test, temp, demo, guest, backup
- **Service accounts** with admin privileges (unless documented)

### Medium Risk (Yellow)
- Accounts with **suspicious patterns** in username
- Accounts with **password never expires** enabled
- Accounts with **no description** (lack of documentation)

### Low Risk (Green)
- Standard system accounts (Administrator, Domain Admins)
- Properly documented and configured accounts
- Domain accounts (usually expected)

## Red Flags

The tool flags these security concerns:

| Issue | Risk | Description |
|-------|------|-------------|
| Disabled admin account | High | Account disabled but still has admin rights |
| Generic names | High | test, temp, demo, guest, backup, service |
| Password never expires | Medium | Security risk - passwords should expire |
| No description | Medium | Lack of documentation |
| Suspicious patterns | Medium | Names containing test, temp, demo, etc. |

## Standard Accounts

These accounts are considered standard and marked as Low Risk:

- `Administrator` (built-in local admin)
- `Administrators` (group)
- `Domain Admins` (domain group)
- `Enterprise Admins` (enterprise group)
- `BUILTIN\Administrators` (system group)

## Usage Examples

### Full Security Audit
1. Run the tool (requires admin privileges)
2. Select option `1` (Full Scan)
3. Review all admin accounts and their risk levels
4. Check warnings for each account

### Find Suspicious Accounts
1. Run a full scan first
2. Select option `2` (View Suspicious Admins)
3. Review only flagged accounts
4. Remove or document unnecessary accounts

### Export for Documentation
1. Run a full scan
2. Select option `3` (Export Results)
3. Choose HTML for a formatted report
4. Report saves to Desktop with all account details

## Security Best Practices

### Account Management
1. **Remove unnecessary admin accounts** - Fewer admins = smaller attack surface
2. **Use domain accounts** - Centralized management and auditing
3. **Document all admin accounts** - Add descriptions explaining why they need admin rights
4. **Enable password expiration** - Don't use "password never expires" for admin accounts
5. **Regular audits** - Review admin group membership regularly

### What to Look For
- **Disabled accounts** - Remove from admin group if not needed
- **Test/temp accounts** - Should not have admin privileges
- **Service accounts** - Use least privilege principle
- **Unused accounts** - Check last logon dates
- **Generic names** - May indicate lack of proper account management

## Technical Details

### How It Works
- Uses `Get-LocalGroupMember` to enumerate Administrators group
- Retrieves account details using `Get-LocalUser` for local accounts
- Analyzes account properties (enabled, password policy, description)
- Compares against known patterns and standard accounts

### Account Information Collected
- Username and full name
- Domain/computer name
- Account type (User, Group)
- Enabled/disabled status
- Password expiration policy
- Last logon date
- Description
- Security Identifier (SID)

### Privacy Note
This tool only reads local account information. No data is sent externally.

## Troubleshooting

### "Access Denied" or "Insufficient Privileges"
- **Solution**: Run PowerShell as Administrator
- This tool requires admin privileges to read group membership

### "No administrator accounts found"
- May indicate the system is properly secured
- Or the Administrators group is empty (unusual)

### Domain accounts not showing details
- Domain account details require domain controller access
- Local account details are always available

## Attack Vector Context

### Why This Matters
Local administrator accounts are a **primary attack vector** because:

1. **Lateral Movement**: Attackers use compromised admin accounts to move between systems
2. **Privilege Escalation**: Admin accounts provide full system access
3. **Persistence**: Attackers create or use existing admin accounts to maintain access
4. **Credential Theft**: Admin accounts are high-value targets for credential harvesting

### Common Scenarios
- **Compromised admin account** used to install malware
- **Unnecessary admin account** left enabled after project completion
- **Service account** with admin rights used for privilege escalation
- **Test account** forgotten and left with admin privileges

## Changelog

### v1.0.0 (2025-11-26)
- Initial release
- Full admin account enumeration
- Risk level assessment
- Pattern detection
- Account status analysis
- Export to TXT, CSV, HTML
- Self-destruct feature

---

*Developed by SouliTEK - www.soulitek.co.il*

