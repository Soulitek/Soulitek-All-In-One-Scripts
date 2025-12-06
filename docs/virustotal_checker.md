# VirusTotal Checker

## Overview

The VirusTotal Checker tool allows IT technicians to quickly check files and URLs against VirusTotal's extensive malware database. Using the VirusTotal API v3, this tool provides instant threat assessment without uploading your actual files.

**Version:** 1.0.0  
**Category:** Security  
**Requirements:** Windows 10/11, Internet connection, VirusTotal API key (free)

## Features

### File Checking
- **Check by File Path**: Automatically calculates file hashes (MD5, SHA1, SHA256) and queries VirusTotal
- **Check by Hash**: Directly query VirusTotal using a known hash
- **Batch Check**: Scan multiple files in a folder with automatic rate limiting

### URL Checking
- Check URLs against VirusTotal's URL database
- Automatic URL submission for scanning if not in database
- View detection results and categories

### Scan Results
- View all scans from the current session
- Color-coded threat level indicators
- Detection breakdown (malicious, suspicious, harmless, undetected)

### Export Options
- Text file (.txt)
- CSV file (.csv)
- HTML report (.html) with SouliTEK branding

## Getting a VirusTotal API Key

1. Go to [https://www.virustotal.com](https://www.virustotal.com)
2. Create a free account or sign in
3. Go to your profile settings (click your avatar → API Key)
4. Copy your 64-character API key

**Free Tier Limits:**
- 4 requests per minute
- 500 requests per day
- 15.5K requests per month

## Menu Options

| Option | Description |
|--------|-------------|
| 1. Check File by Path | Calculate hash and check against VirusTotal |
| 2. Check File by Hash | Enter MD5, SHA1, or SHA256 hash directly |
| 3. Check URL | Check if a URL is malicious |
| 4. Batch Check Files | Check multiple files in a folder |
| 5. View Scan Results | View results from this session |
| 6. Export Results | Export scan results to file |
| 7. Configure API Key | Set or change VirusTotal API key |
| 8. Help | Show usage instructions |
| 0. Exit | Exit the tool |

## Understanding Results

### Threat Levels

| Status | Description | Color |
|--------|-------------|-------|
| CLEAN | No threats detected | Green |
| LOW RISK - SUSPICIOUS | 1+ suspicious or malicious detection | Yellow |
| MEDIUM RISK - POTENTIALLY MALICIOUS | 3-9 malicious detections | Red |
| HIGH RISK - MALWARE DETECTED | 10+ malicious detections | Red |

### Detection Categories

- **Malicious**: Detected as malware by antivirus engines
- **Suspicious**: Potentially harmful behavior detected
- **Harmless**: Known safe file/URL
- **Undetected**: No threat detected by the engine

## Privacy & Security

**Important:** This tool only sends file **hashes** to VirusTotal, NOT the actual files. Your files remain on your local system and are never uploaded.

The API key is stored locally at:
```
%LOCALAPPDATA%\SouliTEK\VTApiKey.txt
```

## Usage Examples

### Check a Downloaded File
1. Select option `1` (Check File by Path)
2. Enter the full path: `C:\Users\Admin\Downloads\setup.exe`
3. Review the scan results

### Check a Known Malware Hash
1. Select option `2` (Check File by Hash)
2. Enter the SHA256 hash
3. Review the detection results

### Verify a Suspicious URL
1. Select option `3` (Check URL)
2. Enter the URL: `https://suspicious-site.com/download`
3. Review URL reputation and categories

### Batch Scan Downloads Folder
1. Select option `4` (Batch Check Files)
2. Enter folder path: `C:\Users\Admin\Downloads`
3. Specify extensions: `exe,dll,msi` or `*` for all
4. Wait for results (15 seconds between checks for rate limiting)

## Technical Details

### API Endpoints Used
- `GET /api/v3/files/{hash}` - File report lookup
- `GET /api/v3/urls/{url_id}` - URL report lookup
- `POST /api/v3/urls` - Submit URL for scanning

### Hash Formats Supported
- MD5 (32 characters)
- SHA1 (40 characters)
- SHA256 (64 characters)

### Rate Limiting
The tool automatically enforces a 15-second delay between batch requests to avoid exceeding the free API limits.

## Troubleshooting

### "API key validation failed"
- Ensure your API key is exactly 64 characters
- Verify your VirusTotal account is active
- Check your internet connection

### "File not found in database"
- The file has never been submitted to VirusTotal
- Consider uploading manually at virustotal.com
- The file may be custom/unique software

### "Request limit exceeded"
- Wait 1 minute and try again
- Free API allows only 4 requests per minute
- Consider upgrading to a premium API key

## References

- [VirusTotal API Documentation](https://docs.virustotal.com/reference/overview)
- [Get a Free API Key](https://www.virustotal.com/gui/join-us)
- [VirusTotal File Report API](https://docs.virustotal.com/reference/file-info)
- [VirusTotal URL Report API](https://docs.virustotal.com/reference/url-info)

## Changelog

### v1.0.0 (2025-11-26)
- Initial release
- File hash checking (MD5, SHA1, SHA256)
- URL checking and submission
- Batch file scanning
- Export to TXT, CSV, HTML
- API key management

---

*Developed by SouliTEK - www.soulitek.co.il*

