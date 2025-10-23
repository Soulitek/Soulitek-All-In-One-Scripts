# SouliTEK Chocolatey Package Installer

## Overview

The **SouliTEK Chocolatey Package Installer** (`SouliTEK-Choco-Installer.ps1`) is a professional, interactive PowerShell script that provides a Ninite-like user experience for installing Windows applications via Chocolatey. It features a terminal-based UI (TUI), preset management, idempotent operations, and comprehensive logging.

## Features

### 🎯 Core Capabilities

- **Interactive TUI Menu**: Keyboard-driven checklist interface with 2-column grid layout
- **4-Way Arrow Navigation**: Navigate packages using Up/Down/Left/Right arrow keys
- **Auto-Bootstrap**: Automatically installs Chocolatey if not present
- **Idempotent**: Skips already-installed packages unless forced
- **Preset System**: Save and load package selections as JSON presets
- **Category Filtering**: Browse packages by category (Browsers, Development, Utilities, etc.)
- **Search/Filter**: Type-ahead search across package names, IDs, categories, and descriptions
- **Professional Logging**: Transcript logs and JSON summary reports
- **Reboot Detection**: Identifies packages requiring system restart

### 📦 Package Catalog

The script includes a curated catalog of 35+ popular applications across multiple categories:

#### Browsers
- Google Chrome, Mozilla Firefox, Microsoft Edge

#### Runtimes
- .NET Desktop Runtime, Visual C++ Redistributables

#### Utilities
- 7-Zip, Notepad++, Everything Search, CCleaner, Adobe Reader, WinRAR

#### Communications
- Zoom, Microsoft Teams, Slack, AnyDesk, Discord

#### Media
- VLC Media Player, Spotify, HandBrake

#### Development
- Git, Visual Studio Code, Node.js LTS, Python, Postman, Sublime Text, Docker Desktop, GitHub Desktop

#### Sysadmin
- Sysinternals Suite, HWiNFO, WireGuard, WinSCP, PuTTY, OpenVPN, PowerShell Core, RSAT, TeamViewer

#### Security
- KeePass, Bitwarden, VeraCrypt

## Usage

### Interactive Mode (Default)

Launch the script without parameters to open the interactive menu:

```powershell
.\SouliTEK-Choco-Installer.ps1
```

### Preset Mode

Install packages from a saved preset file:

```powershell
.\SouliTEK-Choco-Installer.ps1 -Preset "C:\Presets\my-apps.json"
```

### With Parameters

```powershell
# Force reinstall of already-installed packages
.\SouliTEK-Choco-Installer.ps1 -Preset .\preset.json -Force

# Start with filtered category
.\SouliTEK-Choco-Installer.ps1 -Category "Development"

# Use custom Chocolatey source
.\SouliTEK-Choco-Installer.ps1 -Source "https://custom-repo.local"

# Allow pre-release packages
.\SouliTEK-Choco-Installer.ps1 -Pre

# Simulate installation (no changes)
.\SouliTEK-Choco-Installer.ps1 -WhatIf
```

## Interactive Menu Controls

### Navigation
The menu displays packages in a **2-column grid layout** for easier browsing:
- **Arrow Keys**: Navigate in all directions (Up/Down/Left/Right)
  - **Up/Down**: Move between rows
  - **Left/Right**: Move between columns
- **Space**: Toggle package selection
- **A**: Select all packages (in current filter/category)
- **N**: Select none (deselect all)

### Filtering & Categorization
- **F**: Open filter input (search packages by name, ID, category, or notes)
- **C**: Change category view (All, Browsers, Utilities, Development, etc.)

### Presets
- **P**: Save current selection as a preset (JSON file saved to Desktop)
- **L**: Load a preset from Desktop

### Actions
- **I**: Install selected packages
- **Q**: Quit without installing

## Command-Line Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `-Preset` | String | Path to JSON preset file containing package IDs |
| `-Category` | String | Start menu filtered by specific category |
| `-Force` | Switch | Reinstall/upgrade packages even if already installed |
| `-Source` | String | Custom Chocolatey source URL |
| `-Pre` | Switch | Allow pre-release packages |
| `-WhatIf` | Switch | Simulate installs without making changes |

## Preset File Format

Preset files are JSON arrays containing Chocolatey package IDs:

```json
[
  "googlechrome",
  "7zip",
  "vscode",
  "git",
  "notepadplusplus"
]
```

### Creating Presets

1. **Via Interactive Menu**: Select packages and press **P**, enter a filename
2. **Manual Creation**: Create a JSON file with the format above

Presets are saved to: `%USERPROFILE%\Desktop\<preset-name>.json`

## Output & Logging

### Transcript Log

Full execution log saved to:
```
%ProgramData%\SouliTEK\ChocoInstaller\Logs\ChocoInstaller_YYYYMMDD_HHMMSS.log
```

### JSON Summary Report

Machine-readable summary saved to Desktop:
```
%USERPROFILE%\Desktop\SouliTEK-Choco-Installer-Result.json
```

**Summary Fields**:
```json
{
  "ComputerName": "WORKSTATION01",
  "User": "admin",
  "Timestamp": "2025-10-23 14:30:00",
  "ChocolateyVersion": "2.3.0",
  "Packages": [
    {
      "Id": "googlechrome",
      "Name": "Google Chrome",
      "Status": "Installed",
      "Message": "Success",
      "Elapsed": 12.34
    }
  ],
  "RebootRequired": false,
  "TotalPackages": 5,
  "Installed": 3,
  "Skipped": 2,
  "Failed": 0
}
```

### Console Summary Table

At completion, displays:
- Total packages processed
- Installed, skipped, and failed counts
- Detailed per-package results (status, elapsed time, message)
- Reboot requirement notification

## Behavior & Logic

### Idempotent Installation

The script checks if each package is already installed using:
```powershell
choco list --local-only --exact <package-id>
```

If installed and `-Force` is **not** set:
- Package is **skipped**
- Status marked as "Already installed"

If installed and `-Force` is set:
- Package is **reinstalled/upgraded**

### Chocolatey Bootstrap

If `choco.exe` is not found:
1. Downloads official Chocolatey install script via TLS 1.2+
2. Executes installation
3. Refreshes PATH environment variables
4. Verifies `choco.exe` availability
5. Fails gracefully with clear error message if blocked

### Elevation & Execution Policy

- **Admin Check**: Automatically relaunches with elevation if not running as Administrator
- **Execution Policy**: Sets policy to `Bypass` for process scope only (no machine-level changes)
- **Parameter Preservation**: All CLI parameters are preserved when relaunching

### Reboot Handling

- Monitors install output for reboot indicators
- Tracks exit code `3010` (reboot required)
- Sets `$Script:RebootRequired` flag
- Prompts user at end: "Reboot now? (Y/N)"
- If **Y**, executes: `shutdown /r /t 10`

## Error Handling

- **Try/Catch Blocks**: Every critical operation wrapped in error handling
- **Graceful Degradation**: Single package failure doesn't stop entire process
- **Detailed Logging**: Errors captured in transcript and summary JSON
- **Ctrl+C Handling**: Partial summary written before exit
- **Clear Messages**: Meaningful error descriptions for troubleshooting

## Extending the Catalog

To add new packages, edit the `$Script:PackageCatalog` array at the top of the script:

```powershell
$Script:PackageCatalog = @(
    @{ Id = "package-id"; Name = "Display Name"; Category = "Category"; Notes = "Description" }
    # Add more entries...
)
```

**Available Categories**:
- Browsers
- Runtimes
- Utilities
- Communications
- Media
- Development
- Sysadmin
- Security

## System Requirements

- **OS**: Windows 10/11
- **PowerShell**: 5.1 or later
- **Privileges**: Administrator rights required
- **Internet**: Required for Chocolatey bootstrap and package downloads
- **Dependencies**: None (self-contained script)

## Use Cases

### IT Deployment
- Standardize application installations across workstations
- Create department-specific presets (HR, Dev, Marketing)
- Mass deployment via scripts or RMM tools

### Developer Workstation Setup
- New machine setup with single command
- Version-controlled presets in Git
- Consistent development environment

### System Administration
- Post-image application provisioning
- Disaster recovery automation
- Remote support toolkit installation

### Personal Use
- Quick reinstallation after OS refresh
- Multi-machine synchronization
- Backup application list

## Troubleshooting

### Chocolatey Installation Fails

**Symptom**: Script cannot install Chocolatey automatically

**Solutions**:
1. Check internet connectivity
2. Verify TLS 1.2 is enabled:
   ```powershell
   [Net.ServicePointManager]::SecurityProtocol
   ```
3. Manually install Chocolatey: https://chocolatey.org/install
4. Check corporate firewall/proxy settings

### Package Installation Hangs

**Symptom**: Install process appears frozen

**Solutions**:
1. Some packages require user interaction - check if prompts are hidden
2. Check network connectivity for large downloads
3. Use `-WhatIf` to simulate without actual installation
4. Check `choco.log` for details:
   ```
   C:\ProgramData\chocolatey\logs\choco.log
   ```

### Permission Errors

**Symptom**: Access denied or permission errors

**Solutions**:
1. Ensure running as Administrator
2. Check execution policy: `Get-ExecutionPolicy`
3. Verify Chocolatey installation directory permissions
4. Disable antivirus temporarily (some may block Chocolatey)

### Preset Not Loading

**Symptom**: Preset file fails to load

**Solutions**:
1. Verify JSON syntax (use JSONLint or similar)
2. Ensure file encoding is UTF-8
3. Check package IDs match catalog exactly (case-sensitive)
4. Confirm file path is correct (absolute or relative)

## Security Considerations

### Execution Safety
- Script requests elevation only when necessary
- Execution policy changed for process scope only
- No machine-level registry modifications (except Chocolatey install)

### Package Verification
- Chocolatey performs checksum verification
- Packages sourced from official Chocolatey Community Repository
- Use `-Source` for private/enterprise repositories

### Logging
- Transcripts contain full command history
- Summary JSON includes user and computer information
- Logs stored in protected `%ProgramData%` folder

## Performance

- **Interactive Menu**: Instant response for catalogs up to 500 packages
- **Filter/Search**: Real-time filtering with no perceptible delay
- **Installation Speed**: Depends on package size and network speed
- **Parallel Installs**: Sequential by design (Chocolatey limitation)

## Future Enhancements

Potential features for future versions:
- Parallel package installation support
- Package dependency visualization
- Automatic preset generation from installed packages
- GUI mode option (Windows Forms)
- Package version pinning in presets
- Update checking for installed packages
- Offline package cache support
- PowerShell 7+ optimization

## Support & Contribution

For issues, feature requests, or contributions:
- **Project Repository**: [GitHub Link]
- **Documentation**: This file and inline script comments
- **License**: See LICENSE file

## Related Tools

- **SouliTEK Launcher**: GUI launcher for SouliTEK scripts
- **Remote Support Toolkit**: Remote administration utilities
- **Event Log Analyzer**: System log analysis
- **Network Test Tool**: Network diagnostics

---

**Created**: 2025-10-23  
**Version**: 1.0  
**Author**: SouliTEK  
**Tested**: Windows 10 (22H2), Windows 11 (23H2), PowerShell 5.1/7.4

