# Product Key Retriever

## Overview

The Product Key Retriever tool retrieves product keys for Windows and Office installations from the system registry and WMI. This tool is useful for backup purposes, system documentation, and recovery scenarios.

**Version:** 1.0.0  
**Category:** Support  
**Requirements:** Windows 10/11 (No admin privileges required for most operations)

## Features

### Windows Product Key Retrieval
- **WMI Methods**: Attempts to retrieve keys via SoftwareLicensingProduct and SoftwareLicensingService
- **Registry Method**: Decodes DigitalProductId from registry to product key
- **Version Detection**: Identifies Windows version, edition, and build
- **Multiple Fallbacks**: Tries multiple methods to maximize success rate

### Office Product Key Retrieval
- **Multi-Version Support**: Detects Office 2010, 2013, 2016, 2019, 2021, and 365
- **32-bit and 64-bit**: Checks both native and WOW6432Node registry paths
- **Product Identification**: Shows product name, version, and Product ID
- **Key Decoding**: Decodes DigitalProductId values when available

### Export Options
- Text file (.txt)
- CSV file (.csv)
- HTML report (.html) with SouliTEK branding

## Menu Options

| Option | Description |
|--------|-------------|
| 1. Full Scan | Scan for Windows and Office product keys |
| 2. View Results | Display all retrieved product keys |
| 3. Export Results | Export product keys to file |
| 4. Help | Show usage instructions |
| 0. Exit | Exit the tool |

## Retrieval Methods

### Windows Keys

The tool attempts multiple methods to retrieve Windows product keys:

1. **WMI - SoftwareLicensingProduct**
   - Queries `OA3xOriginalProductKey` property
   - Works for OEM and retail installations
   - May not work for digitally activated Windows

2. **WMI - SoftwareLicensingService**
   - Queries `OA3xOriginalProductKey` from licensing service
   - Alternative method for some installations

3. **Registry - DigitalProductId**
   - Reads `HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\DigitalProductId`
   - Decodes binary value to readable product key
   - Works for most installations but may show generic keys for some OEM systems

### Office Keys

The tool checks multiple registry locations:

- `HKLM:\SOFTWARE\Microsoft\Office\16.0\Registration` (Office 2016/2019/2021/365)
- `HKLM:\SOFTWARE\Microsoft\Office\15.0\Registration` (Office 2013)
- `HKLM:\SOFTWARE\Microsoft\Office\14.0\Registration` (Office 2010)
- `HKLM:\SOFTWARE\WOW6432Node\Microsoft\Office\*\Registration` (32-bit versions)

For each Office installation found:
- Attempts to decode `DigitalProductId` if present
- Falls back to direct `ProductKey` registry value
- Shows Product ID and product name

## Limitations

### When Keys May Not Be Available

1. **Digitally Activated Windows**
   - Windows 10/11 activated with Microsoft account
   - Keys stored in Microsoft account, not locally
   - May show "Not Available" message

2. **BIOS/UEFI Embedded Keys**
   - OEM systems with keys embedded in firmware
   - Keys may not be accessible via standard methods
   - System may show generic or placeholder keys

3. **Office 365/Microsoft 365**
   - Subscription-based licenses don't use traditional product keys
   - May show "Not Available" or subscription information
   - Keys are managed through Microsoft account

4. **Volume License Keys**
   - Enterprise/volume licenses may not expose individual keys
   - Keys managed through Volume Licensing Service Center

5. **Upgraded Systems**
   - Systems upgraded from older Windows versions
   - Original key may not be retrievable
   - Digital entitlement may replace original key

## Usage Examples

### Retrieve All Product Keys
1. Run the tool
2. Select option `1` (Full Scan)
3. Wait for scan to complete
4. Review all found product keys

### Export Keys for Backup
1. Run a full scan first
2. Select option `3` (Export Results)
3. Choose format (TXT, CSV, or HTML)
4. File saves to Desktop with timestamp
5. Store securely for backup/recovery

### View Results Only
1. After running a scan
2. Select option `2` (View Results)
3. Review all retrieved keys
4. Note which keys were found vs. not available

## Security Considerations

### Important Notes

- **Sensitive Information**: Product keys are sensitive and should be protected
- **Secure Storage**: Store exported files in secure locations
- **Access Control**: Limit access to exported key files
- **Do Not Share**: Never share product keys publicly or in unsecured channels
- **Backup Purpose**: Use keys only for legitimate backup/recovery purposes

### Best Practices

1. **Export and Encrypt**: Export keys and store in encrypted location
2. **Document with System**: Keep keys with system documentation
3. **Regular Backups**: Export keys after new installations
4. **Secure Deletion**: Securely delete exported files when no longer needed
5. **Access Logging**: Track who accesses product key files

## Technical Details

### Key Decoding Algorithm

The tool uses a proprietary algorithm to decode `DigitalProductId` binary values:
- Reads 15 bytes starting at offset 52
- Applies base-24 decoding with character set: `BCDFGHJKMPQRTVWXY2346789`
- Formats result as `XXXXX-XXXXX-XXXXX-XXXXX-XXXXX`

### Registry Paths

**Windows:**
- `HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion`
  - `DigitalProductId` (binary)
  - `ProductName` (string)
  - `DisplayVersion` (string)
  - `EditionID` (string)

**Office:**
- `HKLM:\SOFTWARE\Microsoft\Office\{version}\Registration\{GUID}`
  - `DigitalProductId` (binary)
  - `ProductKey` (string, if available)
  - `ProductName` (string)
  - `ProductID` (string)

### WMI Classes

- `SoftwareLicensingProduct`: Contains licensing information
- `SoftwareLicensingService`: Contains service-level licensing data

## Troubleshooting

### No Keys Found

**Possible Causes:**
- Windows/Office is digitally activated
- Keys stored in BIOS/UEFI
- System uses volume licensing
- Registry access restrictions

**Solutions:**
- Check if system is digitally activated
- Try running as administrator (though usually not required)
- Check Windows activation status in Settings
- For Office, verify installation and check Microsoft account

### Invalid or Generic Keys

**Possible Causes:**
- OEM system with embedded key
- Upgraded system with digital entitlement
- Volume license installation

**Solutions:**
- Check system manufacturer documentation
- Verify activation status in Windows Settings
- Contact IT administrator for volume license keys
- Check Microsoft account for linked devices

### Office Keys Not Found

**Possible Causes:**
- Office 365 subscription (no traditional key)
- Office not installed
- Registry paths not accessible
- 32-bit vs 64-bit path mismatch

**Solutions:**
- Verify Office installation
- Check Office version and architecture
- For Office 365, check Microsoft account
- Try running as administrator

## Related Tools

- **License Expiration Checker**: Monitor Microsoft 365 license subscriptions
- **M365 User List**: List Microsoft 365 users and licenses
- **System Restore Point**: Create restore points before system changes

## Version History

### v1.0.0 (2025-11-26)
- Initial release
- Windows product key retrieval (WMI and registry)
- Office product key retrieval (2010, 2013, 2016, 2019, 2021, 365)
- Key decoding algorithm
- Export to TXT, CSV, HTML formats
- Multi-method fallback system

## Support

For issues or questions:
- **Website:** www.soulitek.co.il
- **Email:** letstalk@soulitek.co.il

---

**Note:** This tool is for legitimate backup and recovery purposes only. Product keys are sensitive information and should be handled securely.




