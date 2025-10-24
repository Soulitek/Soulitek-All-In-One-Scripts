# SouliTEK All-In-One Scripts

<div align="center">

![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue?style=for-the-badge&logo=powershell)
![Windows](https://img.shields.io/badge/Windows-8.1%2B-0078D6?style=for-the-badge&logo=windows)
![License](https://img.shields.io/badge/License-Proprietary-red?style=for-the-badge)

**Professional PowerShell Tools for IT Technicians**

*By [SouliTEK](https://soulitek.co.il)*

</div>

---

## 🚀 Quick Start

### ⚡ One-Line Install (New PC)

```powershell
# Recommended: Direct GitHub URL (no redirect issues)
iwr -useb https://raw.githubusercontent.com/Soulitek/Soulitek-All-In-One-Scripts/main/Install-SouliTEK.ps1 | iex
```

**Perfect for new PCs!** Just open PowerShell, paste the command, and start working. 🎉

<details>
<summary>Alternative: Custom Domain (if you prefer branded URL)</summary>

```powershell
# Custom domain with redirect handling
$response = iwr -useb get.soulitek.co.il -MaximumRedirection 0 -ErrorAction SilentlyContinue
if ($response.StatusCode -eq 308) {
    $redirectUri = $response.Headers['Location']
    iwr -useb $redirectUri | iex
} else {
    $response.Content | iex
}
```
</details>

### 💻 Already Installed?

```powershell
# Just double-click or run:
.\SouliTEK-Launcher.ps1
```

**That's it!** Modern GUI with all tools in one place.

---

## 🛠️ Available Tools (10 Scripts)

| Tool | Purpose |
|------|---------|
| ⚡ **Battery Report** | Analyze laptop battery health |
| 🔒 **BitLocker Status** | Check encryption & recovery keys |
| ✉ **PST Finder** | Find Outlook PST files |
| ⊞ **Printer Fix** | Fix printer spooler issues |
| ≈ **WiFi Passwords** | View saved WiFi passwords |
| ▤ **Event Log Analyzer** | Analyze Windows event logs |
| ⚙ **Support Toolkit** | Complete system diagnostics |
| 🌐 **Network Test Tool** | Ping, tracert, DNS, latency tests |
| 🔍 **USB Device Log** | Forensic USB device history analysis |
| 📦 **Chocolatey Installer** | Ninite-like package installer with TUI |

All scripts located in `./scripts/` folder.

---

## 📁 Project Structure

```
Soulitek-All-In-One-Scripts/
├── scripts/          # All PowerShell tools
├── launcher/         # GUI launcher
├── docs/             # Documentation
└── assets/           # Images & icons
```

---

## 💡 Features

### GUI Launcher
- 🔍 **Search-First UX** - Type to instantly filter tools
- 🏷️ **Category Filtering** - 7 color-coded categories (Network, Security, Support, etc.)
- ✅ Modern GUI with rounded buttons
- ✅ One-click tool launching
- ✅ Real-time filtering and smart search
- ✅ Administrator checks

### Tools
- ✅ Detailed logging and reporting
- ✅ Export to CSV/HTML/JSON/TXT
- ✅ Professional formatting
- ✅ Windows 8.1, 10, 11 compatible

---

## 📖 Documentation

- **[Quick Install Guide](docs/QUICK_INSTALL.md)** - One-line installation & URL setup
- **[Quick Reference](QUICK_REFERENCE.md)** - Fast lookup guide
- **[Project Structure](PROJECT_STRUCTURE.md)** - Detailed folder info
- **[Full Docs](docs/)** - All documentation

---

## 🔧 Usage

### GUI Launcher (Recommended)
```powershell
.\SouliTEK-Launcher.ps1
```

### Run Individual Tool
```powershell
.\scripts\battery_report_generator.ps1
```

### Run as Administrator
Right-click launcher → "Run as Administrator"

---

## 📋 Requirements

- Windows 8.1 or higher
- PowerShell 5.1 or higher
- Administrator privileges (for most tools)

---

## 📞 Support

- **Website:** https://soulitek.co.il
- **Email:** letstalk@soulitek.co.il
- **GitHub:** [Soulitek/Soulitek-All-In-One-Scripts](https://github.com/Soulitek/Soulitek-All-In-One-Scripts)

---

## 📄 License

Proprietary - © 2025 SouliTEK. All Rights Reserved.

See [LICENSE](LICENSE) for details.

---

<div align="center">

**Made with ❤️ in Israel**

*Professional IT Solutions for Your Business*

</div>
