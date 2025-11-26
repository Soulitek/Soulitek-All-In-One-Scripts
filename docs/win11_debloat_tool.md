# Win11Debloat Tool Documentation

## Overview

The Win11Debloat Tool is a PowerShell script that integrates the popular Win11Debloat utility by Raphire into the SouliTEK All-In-One toolkit. It provides a safe and user-friendly way to remove Windows bloatware, disable telemetry, and optimize Windows 10/11 systems.

## Features

### Core Functionality
- **Bloatware Removal**: Removes pre-installed unnecessary apps
- **Telemetry Disabling**: Disables Windows data collection and tracking
- **Registry Optimization**: Applies performance-enhancing registry tweaks
- **UI Customization**: Removes intrusive interface elements
- **Interactive Menu**: User-controlled selection of changes to apply

### Safety Features
- Administrator privilege verification
- Internet connectivity checks
- Comprehensive warning system
- Recommends system restore point creation
- User confirmation before execution
- Clear error handling and reporting

## Requirements

### System Requirements
- Windows 10 or Windows 11
- PowerShell 5.1 or higher
- Administrator privileges
- Active internet connection

### Dependencies
- SouliTEK Common Functions module
- Network connectivity to download Win11Debloat script

## Usage

### Running the Script

1. **Right-click** on `win11_debloat.ps1`
2. Select **"Run with PowerShell as administrator"**
3. Click **"Yes"** on the UAC prompt
4. Read the warning message carefully
5. Press **'Y'** to continue or any other key to cancel
6. Follow the interactive menu prompts

### Interactive Menu Options

The Win11Debloat tool will present you with several options:

1. **Remove bloatware apps** - Select which pre-installed apps to remove
2. **Disable telemetry** - Choose telemetry settings to disable
3. **Apply registry tweaks** - Select performance optimizations
4. **Customize UI** - Choose which UI elements to modify
5. **Custom configuration** - Advanced user settings

## What Gets Changed

### Bloatware Apps Removed (Optional)
- Microsoft.BingWeather
- Microsoft.GetHelp
- Microsoft.Getstarted
- Microsoft.Microsoft3DViewer
- Microsoft.MicrosoftOfficeHub
- Microsoft.MicrosoftSolitaireCollection
- Microsoft.MicrosoftStickyNotes
- Microsoft.WindowsFeedbackHub
- Microsoft.WindowsMaps
- Microsoft.XboxApp
- And many more (user-selectable)

### Telemetry Settings Modified
- Disables diagnostic data collection
- Disables advertising ID
- Disables app suggestions
- Disables activity history
- Disables location tracking
- Disables feedback requests

### Registry Optimizations
- Disables unnecessary services
- Optimizes system performance
- Removes UI clutter
- Enhances privacy settings

## Safety & Backup

### Before Running
**STRONGLY RECOMMENDED:**
1. Create a **System Restore Point**
   - Open: Control Panel → System → System Protection
   - Click: "Create" and name it (e.g., "Before Win11Debloat")
2. **Backup important data**
3. **Review the changes** you're about to make
4. **Understand the implications** of each modification

### System Restore Point Creation

To manually create a restore point:

```powershell
# Run in PowerShell as Administrator
Checkpoint-Computer -Description "Before Win11Debloat" -RestorePointType "MODIFY_SETTINGS"
```

Or use the SouliTEK Restore Point Creator tool included in the toolkit.

### Restoring Changes

If you encounter issues after running Win11Debloat:

1. **Boot into Safe Mode** (if needed)
2. Open **System Restore**:
   - Press `Win + R`
   - Type: `rstrui.exe`
   - Press Enter
3. Select your restore point
4. Follow the wizard to restore

## Technical Details

### Script Architecture

```
win11_debloat.ps1
├── Administrator Check
├── Internet Connectivity Verification
├── Warning & User Confirmation
├── Download Win11Debloat Script
├── Execute Interactive Menu
└── Display Results
```

### Script URL
- **Remote Script:** https://debloat.raphi.re/
- **GitHub Source:** https://github.com/Raphire/Win11Debloat
- **License:** MIT License

### Error Handling

The script includes comprehensive error handling for:
- Missing administrator privileges
- No internet connection
- Download failures
- Execution errors
- Network timeouts

## Troubleshooting

### Common Issues

#### 1. Script Won't Run
**Error:** "Administrator Required"
- **Solution:** Right-click → "Run with PowerShell as administrator"

#### 2. No Internet Connection
**Error:** "No internet connection detected"
- **Solution:** Check your network connection
- Verify firewall isn't blocking PowerShell
- Test connection: `Test-Connection 8.8.8.8`

#### 3. Download Fails
**Error:** "Failed to execute Win11Debloat"
- **Causes:**
  - Firewall blocking download
  - Antivirus quarantining script
  - Network proxy issues
  - Remote server unavailable
- **Solutions:**
  - Temporarily disable antivirus
  - Check firewall settings
  - Configure proxy settings
  - Try again later

#### 4. Execution Policy Error
**Error:** "... cannot be loaded because running scripts is disabled..."
- **Solution:**
  ```powershell
  Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
  ```

### Manual Execution

If the script fails, you can run Win11Debloat manually:

```powershell
# Run in PowerShell as Administrator
& ([scriptblock]::Create((irm "https://debloat.raphi.re/")))
```

Or download from GitHub:
```powershell
# Alternative method
irm https://github.com/Raphire/Win11Debloat/raw/master/Get.ps1 | iex
```

## Security Considerations

### Script Validation
- The script downloads from the official Win11Debloat repository
- Uses secure HTTPS connections
- Validates internet connectivity before download
- Requires explicit user confirmation

### What to Watch For
- Always download from official sources
- Review changes before applying
- Keep system backups
- Monitor system behavior after changes

### Privacy Benefits
Running Win11Debloat can significantly improve your privacy by:
- Disabling telemetry data collection
- Removing advertising IDs
- Blocking activity tracking
- Disabling location services (optional)
- Removing unnecessary Microsoft accounts integrations

## Version Information

- **Script Version:** 1.0.0
- **Win11Debloat Source:** Raphire's Win11Debloat (latest)
- **Compatible Windows Versions:** Windows 10, Windows 11
- **PowerShell Requirement:** 5.1 or higher
- **Last Updated:** 2025-11-22

## Credits & Attribution

### Win11Debloat
- **Author:** Raphire
- **Repository:** https://github.com/Raphire/Win11Debloat
- **License:** MIT License
- **Description:** A simple, lightweight PowerShell script to remove pre-installed apps, disable telemetry, and customize Windows 10/11

### SouliTEK Integration
- **Developer:** Soulitek.co.il
- **Website:** www.soulitek.co.il
- **Email:** letstalk@soulitek.co.il
- **Integration Date:** 2025-11-22

## Legal & Disclaimer

**IMPORTANT DISCLAIMER:**

This tool is provided "AS IS" without warranty of any kind. Use of this tool is at your own risk. The user is solely responsible for any outcomes, damages, or issues that may arise from using this script. By running this tool, you acknowledge and accept full responsibility for its use.

**WARNING:** This will make significant changes to your Windows installation. Always create a system restore point before proceeding.

**License:** This integration script is provided under the same MIT License as Win11Debloat.

---

## Support

For issues related to:
- **SouliTEK Integration:** Contact letstalk@soulitek.co.il
- **Win11Debloat Functionality:** Visit https://github.com/Raphire/Win11Debloat/issues

---

**© 2025 SouliTEK - All Rights Reserved**






