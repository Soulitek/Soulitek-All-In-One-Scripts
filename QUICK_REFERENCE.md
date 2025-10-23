# 🚀 SouliTEK All-In-One Scripts - Quick Reference

**Last Updated:** October 2025

---

## 🎯 Quick Start

```powershell
# Launch the GUI (easiest way!)
.\SouliTEK-Launcher.ps1
```

That's it! Click a tool and go! 🎉

---

## 📂 Where Everything Is

| What You Need | Location |
|---------------|----------|
| **Launcher (GUI)** | `.\SouliTEK-Launcher.ps1` (root) |
| **All Scripts** | `.\scripts\*.ps1` |
| **Documentation** | `.\docs\` |
| **Images/Icons** | `.\assets\` |
| **Project Info** | `.\README.md` |

---

## 🛠️ Available Tools

| # | Tool | File | Purpose |
|---|------|------|---------|
| 1 | ⚡ **Battery Report** | `scripts/battery_report_generator.ps1` | Battery health analysis |
| 2 | ✉ **PST Finder** | `scripts/FindPST.ps1` | Find Outlook files |
| 3 | ⊞ **Printer Fix** | `scripts/printer_spooler_fix.ps1` | Fix printer issues |
| 4 | ≈ **WiFi Passwords** | `scripts/wifi_password_viewer.ps1` | View saved WiFi passwords |
| 5 | ▤ **Event Log Analyzer** | `scripts/EventLogAnalyzer.ps1` | Analyze Windows logs |
| 6 | ⚙ **Support Toolkit** | `scripts/remote_support_toolkit.ps1` | System diagnostics |

---

## 💡 Common Tasks

### Run a Specific Tool
```powershell
# Option 1: Use the GUI (recommended)
.\SouliTEK-Launcher.ps1

# Option 2: Run directly
.\scripts\battery_report_generator.ps1
```

### Run as Administrator
```powershell
# Right-click launcher and select "Run as Administrator"
# Or from PowerShell:
Start-Process powershell -Verb RunAs -ArgumentList "-File .\SouliTEK-Launcher.ps1"
```

### Get Help for a Tool
```powershell
Get-Help .\scripts\battery_report_generator.ps1 -Full
```

---

## 📖 Documentation Quick Links

| Document | Purpose |
|----------|---------|
| [README.md](README.md) | Main documentation |
| [PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md) | Folder organization |
| [RESTRUCTURE_SUMMARY.md](RESTRUCTURE_SUMMARY.md) | Restructuring details |
| [docs/QUICK_START.md](docs/QUICK_START.md) | Getting started guide |
| [docs/README.md](docs/README.md) | Documentation index |

---

## 🔧 Troubleshooting

### Launcher won't start
```powershell
# Check execution policy
Get-ExecutionPolicy

# Set if needed (as Admin)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Try again
.\SouliTEK-Launcher.ps1
```

### Script not found error
- Make sure you're in the project root folder
- Verify folder structure is intact
- Check that scripts exist in `.\scripts\` folder

### Permission denied
- Run PowerShell as Administrator
- Right-click launcher → "Run as Administrator"

---

## 📞 Support

- **Website:** https://soulitek.co.il
- **Email:** letstalk@soulitek.co.il
- **GitHub:** https://github.com/Soulitek/Soulitek-All-In-One-Scripts

---

## 🎓 Pro Tips

1. **Always use the GUI launcher** - It's the easiest way!
2. **Run as Administrator** - Most tools need elevated permissions
3. **Check the logs** - Logs are saved in `$env:TEMP\SouliTEK-Scripts\`
4. **Read the docs** - Check `/docs` folder for detailed guides
5. **Keep structure intact** - Don't move files between folders

---

**That's all you need to know to get started! 🚀**

*For more detailed information, see [README.md](README.md)*

