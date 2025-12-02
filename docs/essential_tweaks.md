# Essential Tweaks

## Overview

The **Essential Tweaks** tool provides a collection of common Windows configuration tasks in a single, easy-to-use interface. Designed for IT technicians setting up new PCs or optimizing existing systems, this tool streamlines repetitive configuration tasks.

## Purpose

Automates essential Windows tweaks and configurations:
- Default application settings
- Keyboard layout management
- Display language configuration
- Taskbar customization
- Start Menu optimization
- System protection

## Features

### Default Applications
- **Set Google Chrome as default browser** - Opens Windows Settings for easy default browser configuration
- **Set Adobe Acrobat Reader as default PDF app** - Opens Windows Settings for PDF association

### Keyboard & Language
- **Add Hebrew keyboard** - Adds Hebrew (he-IL) keyboard layout
- **Add English (US) keyboard** - Adds English (en-US) keyboard layout
- **Set Hebrew as main display language** - Configures Hebrew as primary display language

### Taskbar Customization
- **Pin Google Chrome to Taskbar** - Adds Chrome shortcut to taskbar
- **Enable "End Task" option in Taskbar** - Enables right-click End Task feature (Windows 11)
- **Disable Microsoft Copilot in Taskbar** - Removes Copilot button from taskbar

### Start Menu & Ads
- **Disable Start Menu ads & suggestions** - Removes promotional content from Start Menu

### System Protection
- **Create a System Restore Point** - Creates a restore point before making changes

## Requirements

### System Requirements
- **OS:** Windows 10/11
- **PowerShell:** Version 5.1 or higher
- **Privileges:** Administrator rights (required)

### Software Requirements (for some features)
- Google Chrome (for default browser and taskbar pin)
- Adobe Acrobat Reader (for default PDF app)

## Usage

### Running the Script

1. **Launch from SouliTEK Launcher** (recommended)
   - Open the SouliTEK Launcher
   - Find "Essential Tweaks" in the Setup category
   - Click the tool card to launch

2. **Run directly via PowerShell** (as Administrator):
   ```powershell
   .\scripts\essential_tweaks.ps1
   ```

### Menu Options

| Option | Action |
|--------|--------|
| 1 | Set Google Chrome as default browser |
| 2 | Set Adobe Acrobat Reader as default PDF app |
| 3 | Add Hebrew keyboard |
| 4 | Add English (US) keyboard |
| 5 | Set Hebrew as main display language |
| 6 | Disable Start Menu ads & suggestions |
| 7 | Pin Google Chrome to Taskbar |
| 8 | Enable "End Task" option in Taskbar |
| 9 | Disable Microsoft Copilot in Taskbar |
| 10 | Create a System Restore Point |
| 11 | Apply All Tweaks |
| 0 | Exit |

### Apply All Tweaks

Option 11 applies all tweaks in sequence with a confirmation prompt. A summary is displayed at the end showing successful and failed operations.

## Technical Details

### Registry Keys Modified

**Start Menu Ads (ContentDeliveryManager):**
- `HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager`
  - `SystemPaneSuggestionsEnabled` = 0
  - `SubscribedContent-338393Enabled` = 0
  - `SubscribedContent-353694Enabled` = 0
  - `SubscribedContent-353696Enabled` = 0
  - `SubscribedContent-338388Enabled` = 0
  - `SubscribedContentEnabled` = 0

**Taskbar Settings:**
- `HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced`
  - `TaskbarEndTask` = 1 (Enable End Task)
  - `ShowCopilotButton` = 0 (Hide Copilot)

**Copilot Policy:**
- `HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot`
  - `TurnOffWindowsCopilot` = 1
- `HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot`
  - `TurnOffWindowsCopilot` = 1

### PowerShell Cmdlets Used

- `Get-WinUserLanguageList` / `Set-WinUserLanguageList` - Language management
- `New-WinUserLanguageList` - Create language list
- `Checkpoint-Computer` - System restore points
- `Set-ItemProperty` / `New-Item` - Registry modifications
- `Start-Process` - Launch Windows Settings

## Notes

- Some changes require logging out or restarting to take effect
- Default browser/PDF app changes open Windows Settings for manual confirmation (Windows security requirement)
- "End Task" in taskbar is a Windows 11 feature
- Hebrew language pack may need to download from Windows Update
- System Restore must be enabled for restore point creation

## Troubleshooting

### Chrome/Acrobat not found
- Ensure the application is installed before running the tweak
- The script checks common installation paths

### Language changes not taking effect
- Sign out and back in after changing display language
- Windows may need to download language packs

### Copilot still visible
- Restart Explorer: `Stop-Process -Name explorer -Force`
- Or log out and back in

### Restore point fails
- Enable System Restore in System Properties
- Ensure sufficient disk space

## Version History

- **v1.0.0** (2025-11-24) - Initial release with 10 essential tweaks

## Related Tools

- **1-Click PC Install** - Complete PC setup automation
- **Win11Debloat** - Advanced Windows optimization
- **System Restore Point** - Dedicated restore point management










