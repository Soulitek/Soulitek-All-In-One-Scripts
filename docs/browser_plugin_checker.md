# Browser Plugin Checker

## Overview

The Browser Plugin Checker scans installed browser extensions across all major browsers and analyzes them for potential security risks based on permissions and known suspicious patterns.

**Version:** 1.0.0  
**Category:** Security  
**Requirements:** Windows 10/11 (No admin required)

## Features

### Multi-Browser Support
- Google Chrome
- Microsoft Edge
- Mozilla Firefox
- Brave Browser
- Opera
- Vivaldi

### Security Analysis
- **Risk Level Assessment**: High, Medium, Low
- **Permission Analysis**: Identifies risky permissions
- **Pattern Matching**: Detects suspicious extension names
- **Multi-Profile Support**: Scans all browser profiles

### Export Options
- Text file (.txt)
- CSV file (.csv)
- HTML report (.html) with SouliTEK branding

## Menu Options

| Option | Description |
|--------|-------------|
| 1. Full Scan | Scan all browsers for extensions |
| 2. View All Extensions | List all detected extensions |
| 3. View Risky Extensions | Show only medium/high risk extensions |
| 4. Export Results | Export scan results to file |
| 5. Help | Show usage instructions |
| 0. Exit | Exit the tool |

## Risk Levels

### High Risk (Red)
- Extensions with access to ALL websites (`<all_urls>`)
- Multiple risky permissions combined
- Known malicious patterns

### Medium Risk (Yellow)
- Extensions with some risky permissions
- Suspicious keywords in name (coupon, toolbar, etc.)
- Excessive permissions (10+)

### Low Risk (Green)
- Normal extensions with limited permissions
- No suspicious patterns detected

## Risky Permissions

The tool flags these potentially dangerous permissions:

| Permission | Risk |
|------------|------|
| `<all_urls>` | Can read/modify ANY website |
| `webRequest`, `webRequestBlocking` | Can intercept all network traffic |
| `cookies` | Can access your login sessions |
| `history` | Can read your browsing history |
| `clipboardRead`, `clipboardWrite` | Can access clipboard data |
| `tabs` | Can see all open tabs |
| `nativeMessaging` | Can communicate with local programs |
| `privacy` | Can modify privacy settings |

## Suspicious Patterns

Extensions with these keywords in their names are flagged:

- **Adware**: coupon, deal, discount, shop, price, save
- **Crypto Miners**: miner, crypto, bitcoin, coin
- **PUPs**: toolbar, search helper, download helper
- **Questionable**: free vpn, proxy, unblocker

## Usage Examples

### Full Security Scan
1. Run the tool
2. Select option `1` (Full Scan)
3. Wait for all browsers to be scanned
4. Review the summary and risky extensions

### Export for Documentation
1. Run a full scan first
2. Select option `4` (Export Results)
3. Choose HTML for a formatted report
4. Report saves to Desktop

### Quick Risk Check
1. Run a full scan
2. Select option `3` (View Risky Extensions)
3. Review only the flagged extensions

## Extension Locations

The tool scans these locations:

| Browser | Path |
|---------|------|
| Chrome | `%LOCALAPPDATA%\Google\Chrome\User Data\*\Extensions` |
| Edge | `%LOCALAPPDATA%\Microsoft\Edge\User Data\*\Extensions` |
| Firefox | `%APPDATA%\Mozilla\Firefox\Profiles\*\extensions.json` |
| Brave | `%LOCALAPPDATA%\BraveSoftware\Brave-Browser\User Data\*\Extensions` |
| Opera | `%APPDATA%\Opera Software\Opera Stable\Extensions` |
| Vivaldi | `%LOCALAPPDATA%\Vivaldi\User Data\*\Extensions` |

## Best Practices

### Extension Hygiene
1. **Remove unused extensions** - Fewer extensions = smaller attack surface
2. **Review permissions** - Before installing, check what access is requested
3. **Use official stores only** - Avoid sideloading extensions
4. **Keep extensions updated** - Updates often include security fixes

### Red Flags to Watch For
- Extensions requesting access to "all websites"
- Free VPN/proxy extensions (often collect data)
- Coupon/shopping extensions (adware)
- Extensions with very few reviews
- Extensions not from verified publishers

## Technical Details

### Chromium Extension Analysis
- Reads `manifest.json` from each extension
- Parses permissions and host_permissions arrays
- Identifies manifest version (v2 vs v3)

### Firefox Extension Analysis
- Reads `extensions.json` from profile directory
- Parses userPermissions for each addon
- Filters out system/default extensions

### Privacy Note
This tool only reads local extension data. No information is sent externally.

## Troubleshooting

### "No browsers detected"
- Ensure browsers are installed in default locations
- Portable browser installations are not supported

### "No extensions found"
- Make sure the browser has been launched at least once
- Check if extensions are installed in a different profile

### Extensions missing from scan
- Some built-in/system extensions are filtered out
- Disabled extensions may not appear in all browsers

## Changelog

### v1.0.0 (2025-11-26)
- Initial release
- Support for Chrome, Edge, Firefox, Brave, Opera, Vivaldi
- Risk level assessment
- Permission analysis
- Export to TXT, CSV, HTML

---

*Developed by SouliTEK - www.soulitek.co.il*

