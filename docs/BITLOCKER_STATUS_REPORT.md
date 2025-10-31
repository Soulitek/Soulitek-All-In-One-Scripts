# BitLocker Status Report Tool

## Overview

The **BitLocker Status Report** is a professional PowerShell tool designed to check BitLocker encryption status, manage recovery keys, and generate comprehensive security reports for all volumes on a Windows system.

## Features

### 1. **BitLocker Status Check**
- Scans all volumes on the system
- Displays protection status (On/Off)
- Shows encryption percentage
- Lists encryption methods
- Displays key protectors
- Shows lock status
- Volume type identification

### 2. **Recovery Key Management**
- Display recovery passwords for all protected volumes
- Shows recovery key IDs
- Secure handling with user confirmation
- Easy backup of recovery information

### 3. **Detailed Volume Report**
- Comprehensive analysis of each volume
- All BitLocker properties
- Auto-unlock configuration
- Metadata version information
- Security recommendations

### 4. **Health Check**
- OS drive protection verification
- Data drive encryption audit
- Recovery key configuration check
- Encryption completion status
- Lock status verification
- Overall health score calculation

### 5. **Export Functionality**
- **Text Format (.txt)** - Easy-to-read plain text report
- **CSV Format (.csv)** - Spreadsheet-compatible data
- **HTML Format (.html)** - Professional web-based report with styling
- All formats include Soulitek branding

## Requirements

### System Requirements
- **Windows Edition**: Pro, Enterprise, or Education
  - BitLocker is NOT available on Windows Home edition
- **Administrator Rights**: Must run as Administrator
- **TPM**: Trusted Platform Module 1.2 or higher (recommended)
- **PowerShell**: Version 5.1 or later

### Hardware Requirements
- TPM chip (recommended but not required)
- UEFI firmware
- Sufficient disk space for encryption

## Installation

1. Copy `bitlocker_status_report.ps1` to your desired location
2. Right-click the file
3. Select **"Run with PowerShell"**
4. Or run from PowerShell as Administrator:
   ```powershell
   .\bitlocker_status_report.ps1
   ```

## Usage Guide

### Main Menu Options

#### [1] BitLocker Status
Checks and displays the encryption status of all volumes:
- Protection status
- Encryption percentage
- Volume information
- Key protectors
- Lock status

**When to use:**
- Quick overview of all encrypted drives
- Verify encryption is active
- Check encryption progress

#### [2] Recovery Keys
Displays BitLocker recovery passwords:
- Shows 48-digit recovery keys
- Displays key IDs
- Requires confirmation before displaying

**When to use:**
- Before hardware upgrades (motherboard, TPM changes)
- Backing up recovery keys
- Lost password recovery
- System troubleshooting

⚠️ **WARNING**: Recovery keys are sensitive! Keep them secure.

#### [3] Detailed Report
Comprehensive analysis of all volumes:
- All BitLocker properties
- Auto-unlock settings
- Metadata information
- Security recommendations
- Configuration issues

**When to use:**
- In-depth security audit
- Troubleshooting BitLocker issues
- Compliance documentation
- Configuration review

#### [4] Health Check
Quick security audit with health scoring:
- OS drive protection check
- Data drive encryption verification
- Recovery key configuration
- Encryption completion status
- Overall health score

**When to use:**
- Regular security audits
- Compliance verification
- Quick system check
- Identify security gaps

#### [5] Export Report
Save BitLocker status to file:
- Choose format: TXT, CSV, HTML, or All
- Saves to Desktop
- Professional formatting
- Includes all volume information

**When to use:**
- Documentation requirements
- Compliance reporting
- Record keeping
- Sharing with IT support

#### [6] Help
Displays detailed usage guide and documentation

## Understanding BitLocker

### Protection Status
- **On** - BitLocker is active and protecting the drive ✅
- **Off** - Drive is not protected by BitLocker ❌

### Encryption Percentage
- **100%** - Fully encrypted (secure) ✅
- **0-99%** - Encryption in progress ⏳
- **0%** - Not encrypted ❌

### Key Protector Types

| Type | Description |
|------|-------------|
| **TPM** | Trusted Platform Module (hardware-based) |
| **RecoveryPassword** | 48-digit recovery key (recommended) |
| **Password** | User password protection |
| **TpmPin** | TPM + PIN combination |
| **TpmStartupKey** | TPM + USB key |
| **ExternalKey** | USB key required at startup |

### Encryption Methods

| Method | Description | Security Level |
|--------|-------------|----------------|
| **AES-CBC 128** | Advanced Encryption Standard 128-bit | Good |
| **AES-CBC 256** | Advanced Encryption Standard 256-bit | Excellent |
| **XTS-AES 128** | XTS-AES 128-bit (Windows 10+) | Very Good |
| **XTS-AES 256** | XTS-AES 256-bit (Windows 10+) | Excellent |

## Common Scenarios

### Scenario 1: Check if OS Drive is Encrypted
1. Run the tool
2. Select **[1] BitLocker Status**
3. Look for the OS drive (usually C:)
4. Check "Protection Status" - should be "On"
5. Check "Encryption Percentage" - should be 100%

### Scenario 2: Save Recovery Keys Before Hardware Upgrade
1. Run the tool
2. Select **[2] Recovery Keys**
3. Confirm when prompted
4. **Write down or save the recovery keys**
5. Store them in a secure location (NOT on the encrypted drive!)

### Scenario 3: Generate Compliance Report
1. Run the tool
2. Select **[5] Export Report**
3. Choose **[3] HTML Report**
4. Report saved to Desktop
5. Open in browser and print/save as PDF

### Scenario 4: Security Audit
1. Run the tool
2. Select **[4] Health Check**
3. Review health score
4. Address any warnings or issues
5. Export report for documentation

### Scenario 5: Verify Encryption Progress
1. Run the tool
2. Select **[1] BitLocker Status**
3. Check "Encryption Percentage" for each volume
4. Wait if encryption is in progress
5. Re-check until 100%

## Report Formats

### Text Report (.txt)
- Simple, readable format
- Opens in Notepad
- Easy to email or share
- Good for quick reference

### CSV Report (.csv)
- Spreadsheet compatible
- Opens in Excel
- Good for data analysis
- Can be imported into databases

### HTML Report (.html)
- Professional web format
- Color-coded status indicators
- Best for presentations
- Can be printed or saved as PDF

## Troubleshooting

### "Administrator Privileges Required" Error
**Solution:**
1. Right-click PowerShell
2. Select "Run as Administrator"
3. Navigate to script location
4. Run the script

### "No Volumes Found" Error
**Possible Causes:**
- BitLocker not available (Windows Home edition)
- System error
- No drives detected

**Solution:**
- Verify Windows edition (Pro/Enterprise/Education required)
- Check if drives are visible in Disk Management
- Restart the computer and try again

### BitLocker Not Available on Windows Home
**Solution:**
- Upgrade to Windows Pro or Enterprise
- Windows Home does not support BitLocker

### "Access Denied" Error
**Possible Causes:**
- Not running as Administrator
- Insufficient permissions

**Solution:**
- Run PowerShell as Administrator
- Check user account permissions

### Recovery Key Not Showing
**Possible Causes:**
- No recovery key configured
- Key stored in Active Directory
- Different key protector type used

**Solution:**
- Check detailed report for key protector types
- Contact domain administrator if domain-joined
- Add recovery key using Windows BitLocker settings

## Security Best Practices

### ✅ DO:
- **Always save recovery keys** in a secure location
- Back up keys to multiple secure locations
- Test recovery keys after creating them
- Keep recovery keys separate from the encrypted device
- Update recovery keys after hardware changes
- Run regular health checks
- Document BitLocker configuration
- Use TPM + PIN for maximum security
- Encrypt all drives containing sensitive data

### ❌ DON'T:
- Store recovery keys on the encrypted drive
- Share recovery keys via unencrypted email
- Forget to back up recovery keys
- Ignore health check warnings
- Disable BitLocker without backing up data
- Use weak passwords for password-based protection
- Neglect to encrypt removable drives
- Skip regular audits

## Recovery Key Storage Recommendations

1. **Print and Store Physically**
   - Print recovery keys
   - Store in secure location (safe, locked drawer)
   - Keep separate from the computer

2. **Microsoft Account**
   - Save to Microsoft account online
   - Access from any device with internet

3. **Active Directory** (Enterprise)
   - Store in company Active Directory
   - Centrally managed by IT

4. **Password Manager**
   - Use encrypted password manager
   - Ensure password manager is backed up

5. **USB Drive**
   - Save to encrypted USB drive
   - Store USB drive securely

⚠️ **NEVER** store recovery keys on the encrypted drive itself!

## Health Check Scoring

| Score | Rating | Meaning |
|-------|--------|---------|
| **80-100%** | Excellent ✅ | All security measures in place |
| **60-79%** | Good ⚠️ | Minor issues, mostly secure |
| **40-59%** | Fair ⚠️ | Several security gaps |
| **0-39%** | Poor ❌ | Critical security issues |

## Export Report Contents

All export formats include:
- Computer name
- Username
- Generation timestamp
- Volume information:
  - Mount point
  - Protection status
  - Encryption percentage
  - Volume status
  - Lock status
  - Encryption method
  - Key protectors
  - Recovery keys (if available)
- Summary statistics

## Professional Features

- **Color-coded output** for easy status identification
- **Real-time status checking** with live data
- **Comprehensive error handling** with helpful messages
- **Multiple export formats** for different needs
- **Security recommendations** based on configuration
- **Health scoring system** for quick assessment
- **Professional branding** throughout
- **User-friendly menus** with clear options

## Technical Details

### PowerShell Cmdlets Used
- `Get-BitLockerVolume` - Retrieves BitLocker configuration
- `Get-PSDrive` - Gets drive information
- `Export-Csv` - Exports data to CSV
- `Out-File` - Creates text files
- `Set-Content` - Creates HTML files

### Data Retrieved
- Volume mount point and label
- Protection status
- Encryption percentage
- Volume status
- Lock status
- Encryption method
- Key protector types and IDs
- Recovery passwords
- Auto-unlock settings
- Metadata version

## Compliance & Audit

This tool is useful for compliance with:
- **HIPAA** - Healthcare data encryption requirements
- **PCI DSS** - Payment card data protection
- **GDPR** - Personal data protection
- **SOX** - Financial data security
- **ISO 27001** - Information security management
- **Company policies** - Internal security requirements

## License & Support

**Coded by:** Soulitek.co.il  
**Website:** https://www.soulitek.co.il  
**(C) 2025 Soulitek - All Rights Reserved**

### Professional IT Solutions:
- Computer Repair & Maintenance
- Network Setup & Support
- Software Solutions
- Business IT Consulting
- Security & Encryption Services

### Disclaimer
This tool is provided "AS IS" without warranty of any kind. Use of this tool is at your own risk. The user is solely responsible for any outcomes, damages, or issues that may arise from using this script.

## Frequently Asked Questions (FAQ)

### Q: Can I use this on Windows Home?
**A:** No, BitLocker is only available on Windows Pro, Enterprise, and Education editions.

### Q: Do I need a TPM chip?
**A:** TPM is recommended but not required. You can use BitLocker with password or USB key protection.

### Q: Will this tool modify my BitLocker settings?
**A:** No, this is a **read-only** tool. It only displays information and does not change any settings.

### Q: Can I run this on remote computers?
**A:** Not directly. You need to run the script locally on each computer with Administrator privileges.

### Q: How often should I run a health check?
**A:** Recommended: Monthly for critical systems, quarterly for standard systems.

### Q: Where are exported reports saved?
**A:** All reports are saved to your Desktop by default.

### Q: Is it safe to display recovery keys?
**A:** Yes, but ensure no one is looking over your shoulder, and don't share screenshots publicly.

### Q: Can this decrypt my drives?
**A:** No, this tool only reads status information. It cannot decrypt, encrypt, or modify BitLocker settings.

### Q: What if encryption is stuck at 0%?
**A:** Check for errors in Windows Event Viewer, ensure sufficient free space, and try resuming encryption from BitLocker settings.

### Q: Can I export reports for multiple computers?
**A:** Yes, run the tool on each computer and compile the reports. Each report includes the computer name.

## Version History

### Version 1.0 (2025)
- Initial release
- BitLocker status checking
- Recovery key display
- Detailed volume reports
- Health check with scoring
- Export to TXT, CSV, HTML
- Professional branding
- Comprehensive documentation

## Changelog

### 2025-10-23
- Created BitLocker Status Report tool
- Implemented all core features
- Added comprehensive documentation
- Added security best practices
- Added health check scoring
- Multiple export formats

---

**For technical support or custom IT solutions, contact Soulitek.co.il**

*Professional IT Services for Your Business*

