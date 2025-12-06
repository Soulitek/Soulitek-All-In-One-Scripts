# BitLocker Status Report

## Overview

The **BitLocker Status Report** tool provides comprehensive analysis and management of BitLocker encryption status across all volumes on a Windows system. It's designed for IT professionals managing enterprise security and encryption compliance.

## Purpose

Automates BitLocker encryption status checking and recovery key management:
- Volume encryption status
- Recovery key extraction and backup
- Encryption method details
- Security audit reporting
- Compliance verification

## Features

### 🔒 **Encryption Status**
- Check encryption status for all volumes
- View encryption method (XTS-AES, AES, etc.)
- Monitor encryption progress
- Identify unprotected volumes

### 🔑 **Recovery Key Management**
- Extract BitLocker recovery keys
- Export keys to secure files
- Backup recovery keys
- Key identification numbers

### 📊 **Volume Reports**
- Detailed volume information
- Encryption status per volume
- Protection status (TPM, PIN, USB key)
- Encryption percentage

### 🔍 **Security Audit**
- Compliance checking
- Encryption coverage analysis
- Security recommendations
- Export audit reports

## Requirements

### System Requirements
- **OS:** Windows 10 Pro/Enterprise or Windows 11 Pro/Enterprise
- **PowerShell:** Version 5.1 or higher
- **Privileges:** Administrator rights (required)
- **BitLocker:** Must be available (Pro/Enterprise editions)

## Usage

### Running the Script

1. **Launch from SouliTEK Launcher** (recommended)
   - Open the SouliTEK Launcher
   - Find "BitLocker Status Report" in the Security category
   - Click the tool card to launch

2. **Run directly via PowerShell** (as Administrator):
   ```powershell
   .\scripts\bitlocker_status_report.ps1
   ```

### Menu Options

#### Option 1: Check BitLocker Status
Displays encryption status for all volumes.
- Volume letters and labels
- Encryption status (On/Off/Encrypting)
- Encryption percentage
- Protection method

#### Option 2: View Recovery Keys
Extracts and displays BitLocker recovery keys.
- Recovery key for each volume
- Key identification numbers
- Volume associations
- **Warning:** Keys are sensitive - handle securely

#### Option 3: Export Recovery Keys
Saves recovery keys to encrypted file.
- Saves to Desktop
- Includes volume information
- Timestamped filename
- Secure storage format

#### Option 4: Detailed Volume Report
Comprehensive information for each volume.
- Encryption algorithm
- Key protectors (TPM, PIN, etc.)
- Encryption status details
- Protection status

#### Option 5: Security Audit
Compliance and security analysis.
- Encryption coverage
- Unprotected volumes
- Security recommendations
- Export audit report

## Output Files

### Report Locations
- **Desktop:** Reports saved to `%USERPROFILE%\Desktop`
- **Format:** TXT and CSV formats
- **Filename:** `BitLockerReport_YYYYMMDD_HHMMSS.txt`

### Recovery Key Files
- **Location:** Desktop
- **Format:** TXT file
- **Security:** Contains sensitive recovery keys - protect appropriately

## Security Considerations

### Recovery Key Protection
- **Critical:** Recovery keys can unlock encrypted drives
- Store keys in secure location
- Never share keys via unsecured channels
- Consider encrypted storage for key backups

### Compliance
- BitLocker required for many compliance standards
- Regular audits recommended
- Document encryption status
- Maintain recovery key backups

### Best Practices
- Store recovery keys separately from encrypted devices
- Use multiple key protectors (TPM + PIN)
- Regular status checks
- Document encryption policies

## Troubleshooting

### BitLocker Not Available
**Problem:** "BitLocker is not available"

**Solutions:**
1. Verify Windows edition (Pro/Enterprise required)
2. Check BitLocker service is running
3. Verify TPM is available (if using TPM protection)
4. Check Group Policy settings

### Cannot Access Recovery Keys
**Problem:** Cannot extract recovery keys

**Solutions:**
1. Ensure running as Administrator
2. Check BitLocker Drive Encryption service
3. Verify volume is encrypted
4. Check permissions on volume

### Encryption Stuck
**Problem:** Encryption progress not advancing

**Solutions:**
1. Check disk space (needs free space)
2. Verify no disk errors
3. Check system resources
4. Restart BitLocker service if needed

## Technical Details

### Encryption Methods
- **XTS-AES 128-bit:** Standard encryption
- **XTS-AES 256-bit:** Enhanced security
- **AES-CBC:** Legacy method

### Key Protectors
- **TPM:** Trusted Platform Module
- **PIN:** Personal Identification Number
- **USB Key:** External USB device
- **Recovery Password:** 48-digit recovery key

## Support

For assistance or to report issues:
- **Website:** www.soulitek.co.il
- **Email:** letstalk@soulitek.co.il

---

**Coded by:** SouliTEK  
*IT Solutions for your business*

(C) 2025 SouliTEK - All Rights Reserved
















