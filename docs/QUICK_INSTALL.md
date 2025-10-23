# SouliTEK Quick Install - One-Line Setup

This guide explains how to install and run SouliTEK All-In-One Scripts directly from a URL on any Windows PC.

---

## 🚀 Quick Start

### One-Line Installation

Open PowerShell and run:

```powershell
iwr -useb https://raw.githubusercontent.com/Soulitek/Soulitek-AIO/main/Install-SouliTEK.ps1 | iex
```

That's it! The script will:
1. ✅ Download the latest version from GitHub
2. ✅ Extract to `C:\SouliTEK`
3. ✅ Create a desktop shortcut
4. ✅ Ask if you want to launch immediately

---

## 📋 What Happens During Installation

### Automatic Steps

1. **Download** - Latest version pulled from GitHub
2. **Extract** - Files extracted to temporary location
3. **Install** - Copied to `C:\SouliTEK`
4. **Shortcuts** - Desktop shortcut created
5. **Cleanup** - Temporary files removed
6. **Launch** - Optional immediate launch

### Installation Location

```
C:\SouliTEK\
├── launcher\
│   └── SouliTEK-Launcher.ps1    (Main GUI)
├── scripts\
│   ├── battery_report_generator.ps1
│   ├── bitlocker_status_report.ps1
│   ├── license_expiration_checker.ps1
│   ├── network_test_tool.ps1
│   └── ... (and more)
├── assets\
├── docs\
└── SouliTEK-Launcher.ps1        (Wrapper script)
```

---

## 🔧 Installation Methods

### Method 1: Direct URL Execution (Recommended)

**PowerShell:**
```powershell
iwr -useb https://raw.githubusercontent.com/Soulitek/Soulitek-AIO/main/Install-SouliTEK.ps1 | iex
```

**Breakdown:**
- `iwr` = Invoke-WebRequest (downloads the script)
- `-useb` = UseBasicParsing (no IE dependencies)
- `| iex` = Pipe to Invoke-Expression (executes the script)

### Method 2: Download and Run

If you prefer to review the script first:

```powershell
# Download
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/Soulitek/Soulitek-AIO/main/Install-SouliTEK.ps1" -OutFile "$env:TEMP\Install-SouliTEK.ps1"

# Review (optional)
notepad "$env:TEMP\Install-SouliTEK.ps1"

# Run
& "$env:TEMP\Install-SouliTEK.ps1"
```

### Method 3: Manual Installation

1. Download ZIP from GitHub: https://github.com/Soulitek/Soulitek-AIO/archive/refs/heads/main.zip
2. Extract to `C:\SouliTEK`
3. Run `C:\SouliTEK\SouliTEK-Launcher.ps1`

---

## 💡 Usage Scenarios

### Scenario 1: New PC Setup

```powershell
# Just got a new PC? One command and you're ready!
iwr -useb https://raw.githubusercontent.com/Soulitek/Soulitek-AIO/main/Install-SouliTEK.ps1 | iex
```

### Scenario 2: Remote Support Session

```powershell
# Customer needs help? Install instantly during remote session
iwr -useb https://raw.githubusercontent.com/Soulitek/Soulitek-AIO/main/Install-SouliTEK.ps1 | iex
```

### Scenario 3: Update to Latest Version

```powershell
# Run the installer again - it will remove old version and install latest
iwr -useb https://raw.githubusercontent.com/Soulitek/Soulitek-AIO/main/Install-SouliTEK.ps1 | iex
```

---

## 🛡️ Security Considerations

### Execution Policy

The installer handles execution policy automatically:
- Uses `-ExecutionPolicy Bypass` for installation only
- Does not modify system-wide execution policy
- Safe for enterprise environments

### Administrator Privileges

**Not Required for Installation:**
- Installation to `C:\SouliTEK` works without admin rights
- Desktop shortcut creation works for current user

**Required for Some Tools:**
- BitLocker Status Report
- USB Device Log
- Some system diagnostics

**Recommendation:** Run PowerShell as Administrator for full functionality

### How to Run as Administrator

1. **Start Menu Method:**
   - Search "PowerShell"
   - Right-click → "Run as administrator"
   - Paste the install command

2. **Keyboard Shortcut:**
   - `Win + X` → Choose "Windows PowerShell (Admin)"
   - Paste the install command

---

## 🌐 Alternative URLs

### GitHub Raw URL (Primary)

```
https://raw.githubusercontent.com/Soulitek/Soulitek-AIO/main/Install-SouliTEK.ps1
```

### Short URL Option

You can create a short URL using:
- **bit.ly** - https://bit.ly/soulitek-install
- **tinyurl** - https://tinyurl.com/soulitek-install
- **Custom domain** - https://get.soulitek.co.il/install

Then use:
```powershell
iwr -useb bit.ly/soulitek-install | iex
```

---

## 📝 Customizing the Installer

### Change Installation Path

Edit `Install-SouliTEK.ps1` and modify:

```powershell
$InstallPath = "C:\SouliTEK"          # Change to your preferred path
# Example: $InstallPath = "D:\Tools\SouliTEK"
```

### Change Repository Source

If you fork the repository:

```powershell
$RepoOwner = "Soulitek"               # Your GitHub username
$RepoName = "Soulitek-AIO"            # Your repo name
$Branch = "main"                       # Branch to install from
```

### Silent Installation

Add these parameters at the beginning:

```powershell
# Silent mode - no prompts
$Silent = $true
$Launch = $false  # Don't auto-launch
```

---

## 🔄 Updating

### Check for Updates

```powershell
# Current version is shown in the GUI "About" dialog
# Or check: C:\SouliTEK\README.md
```

### Update to Latest

```powershell
# Simply run the installer again
iwr -useb https://raw.githubusercontent.com/Soulitek/Soulitek-AIO/main/Install-SouliTEK.ps1 | iex
```

The installer will:
1. Remove the old version from `C:\SouliTEK`
2. Download and install the latest version
3. Preserve your desktop shortcut

---

## 🗑️ Uninstallation

### Complete Removal

```powershell
# Remove installation directory
Remove-Item -Path "C:\SouliTEK" -Recurse -Force

# Remove desktop shortcut
Remove-Item -Path "$env:USERPROFILE\Desktop\SouliTEK Launcher.lnk" -Force
```

### Uninstall Script

Or create this as `Uninstall-SouliTEK.ps1`:

```powershell
Write-Host "Uninstalling SouliTEK..." -ForegroundColor Yellow

# Remove installation
if (Test-Path "C:\SouliTEK") {
    Remove-Item -Path "C:\SouliTEK" -Recurse -Force
    Write-Host "[+] Removed C:\SouliTEK" -ForegroundColor Green
}

# Remove shortcut
$Shortcut = "$env:USERPROFILE\Desktop\SouliTEK Launcher.lnk"
if (Test-Path $Shortcut) {
    Remove-Item -Path $Shortcut -Force
    Write-Host "[+] Removed desktop shortcut" -ForegroundColor Green
}

Write-Host ""
Write-Host "SouliTEK has been uninstalled." -ForegroundColor Green
```

---

## ❓ Troubleshooting

### Error: "Running scripts is disabled"

**Solution:** Run PowerShell as Administrator and execute:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

Then try the install command again.

### Error: "Cannot download from GitHub"

**Possible causes:**
1. No internet connection
2. Corporate firewall blocking GitHub
3. GitHub is temporarily down

**Solutions:**
- Check internet connection
- Use VPN if behind corporate firewall
- Try manual download from GitHub releases
- Contact IT to whitelist: `raw.githubusercontent.com`

### Error: "Access denied to C:\SouliTEK"

**Solution:** Run PowerShell as Administrator, or change install path to user directory:

```powershell
# Edit the script to use user directory
$InstallPath = "$env:USERPROFILE\SouliTEK"
```

### Desktop Shortcut Not Created

**Solution:** Manually create shortcut:

1. Right-click on Desktop → New → Shortcut
2. Location: `powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\SouliTEK\SouliTEK-Launcher.ps1"`
3. Name: `SouliTEK Launcher`
4. Click Finish

---

## 🌟 Best Practices

### For IT Technicians

1. **Bookmark the install command** - Add to your notes app
2. **Create a QR code** - Scan and run on customer PCs
3. **Add to RMM tool** - Deploy via ConnectWise, Kaseya, etc.
4. **Test in VM first** - Verify before deploying to clients
5. **Document custom paths** - If you change installation location

### For Enterprises

1. **Host internally** - Mirror the repo on internal git server
2. **Sign the script** - Add code signing certificate
3. **Use GPO** - Deploy via Group Policy if needed
4. **Test versions** - Use staging branch before rolling out
5. **Audit installations** - Track which PCs have SouliTEK installed

### For End Users

1. **Run as Administrator** - For full tool access
2. **Keep updated** - Rerun installer monthly
3. **Bookmark shortcut** - Pin to taskbar for quick access
4. **Read help guides** - Check docs folder for tool guides
5. **Report issues** - Contact letstalk@soulitek.co.il

---

## 📞 Support

**Need Help?**
- 🌐 Website: https://soulitek.co.il
- 📧 Email: letstalk@soulitek.co.il
- 💻 GitHub: https://github.com/Soulitek/Soulitek-AIO
- 📖 Documentation: https://github.com/Soulitek/Soulitek-AIO/tree/main/docs

---

## 📄 License

© 2025 SouliTEK - All Rights Reserved

See LICENSE file for full license text.

---

**Made with ❤️ in Israel**


