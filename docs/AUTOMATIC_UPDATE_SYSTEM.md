# 🔄 Automatic Update System

## Overview

The SouliTEK All-In-One Scripts Launcher includes a comprehensive automatic update system that checks for new versions, notifies users, and provides one-click updates. Enterprise deployments can also enable silent auto-updates.

---

## ✨ Features

### 1. **Background Update Checker**
- Automatically checks for updates when the launcher starts
- Runs in the background without blocking the UI
- Checks at configurable intervals (default: every 24 hours)
- Respects last check time to avoid excessive API calls

### 2. **Update Notifications**
- Visual indicator in status bar when updates are available
- Orange "Update Available!" button appears in the launcher
- Status message shows latest version information
- Non-intrusive - doesn't interrupt workflow

### 3. **One-Click Update**
- Click "Update Available!" button to see update dialog
- View release notes and version information
- One-click installation directly from the launcher
- Automatically downloads and launches installer
- Launcher closes gracefully after update starts

### 4. **Silent Auto-Updates (Enterprise)**
- Optional silent auto-update mode for enterprise deployments
- Updates install automatically in the background
- No user interaction required
- Configured via updater config file

---

## 🚀 How It Works

### Update Check Process

1. **On Launcher Startup:**
   - Launcher loads the update module (`SouliTEK-Updater.psm1`)
   - Checks configuration for update check interval
   - If interval has passed, starts background update check
   - Update check runs asynchronously in PowerShell job

2. **Version Checking:**
   - First attempts to fetch from `version.json` manifest (faster)
   - Falls back to GitHub Releases API if manifest unavailable
   - Compares current version with latest version
   - Determines if update is available

3. **Update Notification:**
   - If update available, updates UI elements:
     - Shows "Update Available!" button
     - Updates status bar message
     - Changes status color to orange

4. **Update Installation:**
   - User clicks "Update Available!" button
   - Dialog shows version info and release notes
   - User confirms installation
   - Launcher downloads installer script
   - Launches installer with admin privileges
   - Launcher closes to allow update to complete

---

## ⚙️ Configuration

### Config File Location

```
%LOCALAPPDATA%\SouliTEK\updater-config.json
```

### Configuration Options

```json
{
  "SilentAutoUpdate": false,
  "CheckOnStartup": true,
  "CheckInterval": 24,
  "LastCheck": "2025-01-15T10:30:00Z"
}
```

**Options:**
- `SilentAutoUpdate`: Enable silent auto-updates (default: `false`)
- `CheckOnStartup`: Check for updates when launcher starts (default: `true`)
- `CheckInterval`: Hours between update checks (default: `24`)
- `LastCheck`: Timestamp of last update check (automatically updated)

### Enterprise Configuration

For enterprise deployments requiring silent auto-updates:

1. **Create Configuration File:**
   ```powershell
   $configPath = "$env:LOCALAPPDATA\SouliTEK\updater-config.json"
   $configDir = Split-Path $configPath -Parent
   if (-not (Test-Path $configDir)) {
       New-Item -ItemType Directory -Path $configDir -Force | Out-Null
   }
   
   $config = @{
       SilentAutoUpdate = $true
       CheckOnStartup = $true
       CheckInterval = 24
       LastCheck = $null
   }
   
   $config | ConvertTo-Json | Set-Content $configPath
   ```

2. **Deploy via Group Policy:**
   - Create GPO that copies config file to `%LOCALAPPDATA%\SouliTEK\`
   - Or use startup script to create config file
   - Ensure `SilentAutoUpdate = true` for automatic updates

3. **Verify Configuration:**
   ```powershell
   Import-Module ".\modules\SouliTEK-Updater.psm1"
   $config = Get-UpdaterConfig
   Write-Host "Silent Auto-Update: $($config.SilentAutoUpdate)"
   ```

---

## 📋 Version Sources

### Primary: Version Manifest

The system first checks `version.json` in the repository root:

```json
{
  "version": "2.0.0",
  "releaseDate": "2025-01-15",
  "releaseNotes": "Update description...",
  "downloadUrl": "https://github.com/.../releases/latest",
  "changelog": ["Feature 1", "Feature 2"]
}
```

**Benefits:**
- Faster than GitHub API
- Can be cached by CDN
- Simple JSON format
- No API rate limits

### Fallback: GitHub Releases API

If manifest is unavailable, falls back to GitHub Releases API:

```
https://api.github.com/repos/Soulitek/Soulitek-All-In-One-Scripts/releases/latest
```

**Benefits:**
- Always up-to-date
- Includes full release notes
- Automatic from GitHub releases

---

## 🔧 Manual Update Check

You can manually check for updates using PowerShell:

```powershell
# Import update module
Import-Module ".\modules\SouliTEK-Updater.psm1"

# Check for updates
$updateInfo = Test-UpdateAvailable -CurrentVersion "2.0.0" -UseManifest

if ($updateInfo.Available) {
    Write-Host "Update available: $($updateInfo.LatestVersion)" -ForegroundColor Green
    Write-Host "Release Notes: $($updateInfo.ReleaseNotes)" -ForegroundColor Cyan
    
    # Install update
    $result = Install-Update -LauncherPath ".\launcher\SouliTEK-Launcher-WPF.ps1"
    if ($result.Success) {
        Write-Host "Update installer launched!" -ForegroundColor Green
    }
}
else {
    Write-Host "No updates available. Current version is latest." -ForegroundColor Yellow
}
```

---

## 🛠️ Troubleshooting

### Update Check Not Working

**Problem:** Update check doesn't run or fails silently.

**Solutions:**
1. Check internet connectivity
2. Verify update module exists: `Test-Path ".\modules\SouliTEK-Updater.psm1"`
3. Check firewall/antivirus blocking GitHub API
4. Review PowerShell execution logs for errors
5. Manually test update check: `Test-UpdateAvailable -CurrentVersion "2.0.0"`

### Update Button Not Appearing

**Problem:** Update available but button doesn't show.

**Solutions:**
1. Check if update info was received: `$Script:UpdateInfo`
2. Verify UI update function is called: `Update-UIForUpdateAvailable`
3. Check XAML for UpdateButton element
4. Ensure background job completed successfully

### Silent Auto-Update Not Working

**Problem:** Silent auto-update enabled but not installing.

**Solutions:**
1. Verify config file exists and is readable
2. Check `SilentAutoUpdate` is set to `true` in JSON
3. Ensure admin privileges are available
4. Check Windows Event Log for installer errors
5. Verify installer script downloads successfully

### Update Installer Fails

**Problem:** Update installer fails to download or launch.

**Solutions:**
1. Check internet connectivity
2. Verify GitHub URLs are accessible
3. Check antivirus isn't blocking installer download
4. Ensure admin privileges are available
5. Check temp directory is writable: `Test-Path $env:TEMP`

---

## 📊 Update Flow Diagram

```
┌─────────────────┐
│ Launcher Starts │
└────────┬────────┘
         │
         ▼
┌─────────────────────┐
│ Load Update Module  │
└────────┬────────────┘
         │
         ▼
┌──────────────────────┐
│ Check Config Interval│
└────────┬─────────────┘
         │
         ▼
┌─────────────────────┐
│ Background Job:     │
│ Check for Updates   │
└────────┬────────────┘
         │
         ▼
┌─────────────────────┐
│ Fetch Version Info  │
│ (Manifest or GitHub)│
└────────┬────────────┘
         │
         ▼
┌─────────────────────┐
│ Compare Versions    │
└────────┬────────────┘
         │
    ┌────┴────┐
    │         │
    ▼         ▼
Update    No Update
Available  Available
    │         │
    │         └──► Continue Normal Operation
    │
    ▼
┌─────────────────────┐
│ Update UI Elements  │
│ Show Update Button  │
└────────┬────────────┘
         │
         ▼
┌─────────────────────┐
│ User Clicks Button  │
└────────┬────────────┘
         │
         ▼
┌─────────────────────┐
│ Show Update Dialog  │
└────────┬────────────┘
         │
         ▼
┌─────────────────────┐
│ Download Installer  │
└────────┬────────────┘
         │
         ▼
┌─────────────────────┐
│ Launch Installer    │
│ Close Launcher      │
└─────────────────────┘
```

---

## 🔒 Security Considerations

### Update Verification

- Updates are downloaded from official GitHub repository
- HTTPS connections ensure secure downloads
- Installer script is signed (if available)
- Version comparison prevents downgrade attacks

### Enterprise Deployment

- Silent auto-updates can be controlled via Group Policy
- Config file location: `%LOCALAPPDATA%` (user-specific)
- Admin privileges required for installation
- Update checks respect network policies

### Best Practices

1. **Test Updates First:**
   - Test updates in non-production environment
   - Verify compatibility with existing scripts
   - Review release notes before deploying

2. **Monitor Update Status:**
   - Check update logs regularly
   - Monitor failed update attempts
   - Track version adoption across organization

3. **Backup Before Updates:**
   - Create system restore point
   - Backup custom configurations
   - Document current version

---

## 📝 Version Management

### Updating Version Numbers

1. **Update Launcher Version:**
   ```powershell
   # In launcher/SouliTEK-Launcher-WPF.ps1
   $Script:CurrentVersion = "2.1.0"
   ```

2. **Update Version Manifest:**
   ```json
   // In version.json
   {
     "version": "2.1.0",
     "releaseDate": "2025-01-20",
     "releaseNotes": "New features and bug fixes"
   }
   ```

3. **Create GitHub Release:**
   - Tag release as `v2.1.0` or `2.1.0`
   - Add release notes
   - Attach installer or update package

### Version Format

Follow semantic versioning: `MAJOR.MINOR.PATCH`

- **MAJOR**: Breaking changes
- **MINOR**: New features (backward compatible)
- **PATCH**: Bug fixes

---

## 🎯 Use Cases

### Standard User

1. Launcher starts
2. Background update check runs
3. If update available, orange button appears
4. User clicks button, reviews release notes
5. User confirms update
6. Update installs automatically
7. User restarts launcher with new version

### Enterprise Deployment

1. IT admin configures silent auto-update
2. Deploys config file via Group Policy
3. Users launch launcher normally
4. Updates check and install automatically
5. No user interaction required
6. IT admin monitors update status

### Manual Update

1. User wants to update manually
2. Opens PowerShell in launcher directory
3. Runs update check command
4. Reviews update information
5. Manually triggers update installation
6. Or downloads from GitHub directly

---

## 📚 Related Documentation

- [WPF Launcher Guide](WPF_LAUNCHER_GUIDE.md) - Launcher usage
- [Quick Install Guide](QUICK_INSTALL.md) - Installation instructions
- [Deployment Guide](DEPLOYMENT_GUIDE.md) - Enterprise deployment

---

## 🆘 Support

For issues or questions about the update system:

- **Website:** www.soulitek.co.il
- **Email:** letstalk@soulitek.co.il
- **GitHub:** https://github.com/Soulitek/Soulitek-All-In-One-Scripts

---

**Last Updated:** 2025-01-15  
**Version:** 2.0.0

