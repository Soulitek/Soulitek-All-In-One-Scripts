# SouliTEK All-In-One Scripts - Project Structure

This document outlines the organized folder structure of the SouliTEK All-In-One Scripts project.

## 📁 Folder Structure

```
Soulitek-All-In-One-Scripts/
│
├── 📁 scripts/                          # PowerShell tool scripts
│   ├── battery_report_generator.ps1     # Battery health analysis tool
│   ├── EventLogAnalyzer.ps1             # Windows Event Log analyzer
│   ├── FindPST.ps1                      # Outlook PST file finder
│   ├── printer_spooler_fix.ps1          # Printer troubleshooting tool
│   ├── wifi_password_viewer.ps1         # WiFi password viewer
│   └── remote_support_toolkit.ps1       # Comprehensive diagnostic tool
│
├── 📁 launcher/                         # GUI Launcher application
│   └── SouliTEK-Launcher.ps1            # Main GUI launcher
│
├── 📁 docs/                             # Documentation files
│   ├── CONTRIBUTING.md                  # Contribution guidelines
│   ├── GITHUB_SETUP.md                  # GitHub setup instructions
│   ├── GUI_LAUNCHER_GUIDE.md            # Launcher usage guide
│   ├── LAUNCHER_SUCCESS.md              # Launcher development notes
│   ├── NEW_TOOL_ADDED.md                # New tool documentation
│   ├── QUICK_START.md                   # Quick start guide
│   ├── SUCCESS.md                       # Project success notes
│   ├── TODO.md                          # Project TODO list
│   └── UPLOAD_NOW.txt                   # Upload instructions
│
├── 📁 assets/                           # Media and resource files
│   ├── 📁 images/                       # General images and logos
│   │   ├── -Final_Logo-.pdf             # SouliTEK logo
│   │   └── Favicon.png                  # Favicon
│   ├── 📁 icons/                        # Icon files for GUI
│   ├── 📁 screenshots/                  # Application screenshots
│   └── README.md                        # Assets documentation
│
├── 📁 config/                           # Configuration files (future use)
│
├── 📄 SouliTEK-Launcher.ps1             # Launcher wrapper (root)
├── 📄 README.md                         # Main project README
├── 📄 LICENSE                           # Project license
├── 📄 PROJECT_STRUCTURE.md              # This file
└── 📄 .gitignore                        # Git ignore rules

```

## 🎯 Purpose of Each Folder

### `/scripts`
Contains all standalone PowerShell tool scripts. Each script can be run independently or launched through the GUI launcher.

**Scripts:**
- **Battery Report Generator** - Generates detailed battery health reports for laptops
- **Event Log Analyzer** - Analyzes Windows Event Logs with statistical summaries
- **PST Finder** - Locates and analyzes Outlook PST files across the system
- **Printer Spooler Fix** - Comprehensive printer troubleshooting and repair tool
- **WiFi Password Viewer** - Views and exports saved WiFi passwords
- **Remote Support Toolkit** - All-in-one diagnostic tool for remote IT support

### `/launcher`
Contains the GUI launcher application that provides a unified interface to access all tools.

### `/docs`
All project documentation, guides, and reference materials.

### `/assets`
Media files including images, icons, screenshots, and other resources.

### `/config`
Configuration files and settings (reserved for future use).

### Root Files
- **SouliTEK-Launcher.ps1** - Convenience wrapper to launch the GUI from project root
- **README.md** - Main project documentation
- **LICENSE** - Project license information
- **PROJECT_STRUCTURE.md** - This document

## 🚀 Running the Project

### From Root Directory:
```powershell
# Double-click or run:
.\SouliTEK-Launcher.ps1
```

### Running Individual Tools:
```powershell
# Navigate to scripts folder and run any tool:
cd scripts
.\battery_report_generator.ps1
```

## 📝 Adding New Tools

When adding a new PowerShell tool:

1. Place the script in the `/scripts` folder
2. Update `/launcher/SouliTEK-Launcher.ps1` to include the new tool
3. Add documentation to `/docs` if needed
4. Update this PROJECT_STRUCTURE.md file

## 🔧 Development Notes

- All PowerShell scripts should be self-contained
- The launcher dynamically locates scripts in the `/scripts` folder
- Documentation should be kept up-to-date in `/docs`
- Assets (images, icons) go in `/assets`

## 📦 Distribution

For distribution, ensure all folders maintain their structure. Users should:
1. Extract the entire folder structure
2. Run `SouliTEK-Launcher.ps1` from the root directory

---

**Last Updated:** October 2025  
**Version:** 1.0.0  
**Project:** SouliTEK All-In-One Scripts  
**Website:** https://soulitek.co.il

