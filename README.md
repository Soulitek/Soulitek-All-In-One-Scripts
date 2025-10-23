# Soulitek-AIO - All-in-One IT Solutions Toolkit

<div align="center">

![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue?style=for-the-badge&logo=powershell)
![Windows](https://img.shields.io/badge/Windows-8.1%2B-0078D6?style=for-the-badge&logo=windows)
![License](https://img.shields.io/badge/License-Proprietary-red?style=for-the-badge)
![Status](https://img.shields.io/badge/Status-Active-success?style=for-the-badge)

**Professional PowerShell Tools for IT Technicians & Helpdesk Engineers**

*Coded by [SouliTEK](https://soulitek.co.il) - IT Solutions for Your Business*

</div>

---

## 📋 Overview

Soulitek-AIO is a comprehensive collection of professional PowerShell scripts designed specifically for IT technicians, system administrators, and helpdesk engineers. Each tool is built with safety, logging, and enterprise-grade error handling in mind.

### 🎯 Key Features

- ✅ **Administrator Privilege Checks** - All scripts verify elevated permissions before execution
- ✅ **Comprehensive Logging** - Detailed logs saved to `$env:TEMP\SouliTEK-Scripts\`
- ✅ **WhatIf Support** - Safe testing mode for all destructive operations
- ✅ **Interactive Menus** - User-friendly interfaces with clear options
- ✅ **Export Capabilities** - Results exported to CSV, JSON, HTML, and TXT formats
- ✅ **Error Handling** - Robust try/catch blocks with helpful remediation messages
- ✅ **Windows Compatibility** - Supports Windows 8.1, 10, 11, Server 2016+

---

## 🛠️ Available Tools

### 1. 🔋 Battery Report Generator
**File:** `battery_report_generator.ps1`

Generate comprehensive battery health reports for laptops and portable devices.

**Features:**
- Quick Battery Report (7 days)
- Detailed Battery Report (28 days)
- Real-time Battery Health Check
- Sleep Study Report (Modern Standby)
- Energy Efficiency Report
- All Reports Package

**Usage:**
```powershell
# Run as Administrator
.\battery_report_generator.ps1
```

**Outputs:**
- HTML reports on Desktop
- Battery health percentage
- Design vs. current capacity
- Sleep drain analysis
- Power efficiency recommendations

---

### 2. 📧 PST Finder
**File:** `FindPST.ps1`

Locate and analyze Outlook PST files across the system.

**Features:**
- Quick Scan (common locations)
- Deep Scan (all fixed drives)
- Summary reports with file sizes
- HTML/CSV/XLSX export options
- Per-user statistics
- Custom path scanning
- Scheduled daily scans

**Usage:**
```powershell
# Interactive mode
.\FindPST.ps1

# Automated scan for scheduled tasks
.\FindPST.ps1 -AutoScan
```

**Outputs:**
- CSV reports with PST locations and sizes
- HTML formatted reports
- Excel spreadsheets (if Excel installed)
- Summary statistics

---

### 3. 🖨️ Printer Spooler Fix
**File:** `printer_spooler_fix.ps1`

Comprehensive printer spooler management and troubleshooting tool.

**Features:**
- Basic Fix (quick one-time fix)
- Advanced Monitor (continuous monitoring)
- Status Check (detailed diagnostics)
- PowerShell Mode (advanced logging)
- Scheduled Tasks (automatic daily fixes)
- Recent error logs

**Usage:**
```powershell
# Interactive mode
.\printer_spooler_fix.ps1

# Silent automated fix
.\printer_spooler_fix.ps1 -AutoFixSilent
```

**What it does:**
1. Stops Print Spooler service
2. Clears stuck print jobs
3. Cleans spool directory
4. Restarts Print Spooler
5. Verifies service status

---

### 4. 📶 WiFi Password Viewer
**File:** `wifi_password_viewer.ps1`

View and export saved WiFi passwords from Windows.

**Features:**
- View all saved WiFi networks
- Display current network password
- Search specific network by name
- Export to TXT file
- Export to CSV/Excel format
- Quick copy to clipboard
- Security type information

**Usage:**
```powershell
# Run as Administrator
.\wifi_password_viewer.ps1
```

**Outputs:**
- All WiFi networks with passwords
- Desktop exports (TXT/CSV)
- Clipboard copy for quick sharing

**⚠️ Security Warning:**
- Only use on authorized systems
- Delete exported files after use
- Handle password files securely

---

### 5. 📊 Event Log Analyzer *(NEW)*
**File:** `EventLogAnalyzer.ps1`

Advanced Windows Event Log analysis tool with statistical summaries.

**Features:**
- Multi-log analysis (Application, System, Security)
- Configurable time ranges
- Error, Warning, and Information filtering
- Top 10 Event IDs by occurrence
- Top 10 Sources/Providers
- JSON and CSV export
- Detailed event message capture

**Usage:**
```powershell
# Analyze last 24 hours (default)
.\EventLogAnalyzer.ps1

# Analyze specific logs for 48 hours
.\EventLogAnalyzer.ps1 -LogNames "Application","System" -Hours 48

# Custom time range with all event types
.\EventLogAnalyzer.ps1 -StartTime "2025-01-01 00:00" -EndTime "2025-01-02 00:00" -IncludeInformation $true

# Export only JSON format
.\EventLogAnalyzer.ps1 -ExportFormat JSON -Force
```

**Outputs:**
- Comprehensive JSON summary
- CSV summary table
- Detailed events CSV
- Statistical analysis
- Top event patterns

---

## 📥 Installation

### Prerequisites
- **Operating System:** Windows 8.1, 10, 11, Server 2016+
- **PowerShell:** Version 5.1 or higher
- **Privileges:** Administrator rights required
- **Execution Policy:** RemoteSigned or Unrestricted

### Setup

1. **Download or Clone Repository**
```powershell
git clone https://github.com/YourUsername/Soulitek-AIO.git
cd Soulitek-AIO
```

2. **Set Execution Policy** (if needed)
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

3. **Run Scripts as Administrator**
- Right-click PowerShell → "Run as Administrator"
- Navigate to script location
- Execute desired script

---

## 🚀 Quick Start Guide

### First Time Users

1. **Verify PowerShell Version:**
```powershell
$PSVersionTable.PSVersion
# Should be 5.1 or higher
```

2. **Check Administrator Privileges:**
```powershell
([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
# Should return True
```

3. **Run Your First Script:**
```powershell
# Example: Battery Report Generator
.\battery_report_generator.ps1
```

---

## 📂 Project Structure

```
Soulitek-AIO/
├── battery_report_generator.ps1   # Battery health analysis tool
├── FindPST.ps1                     # Outlook PST file finder
├── printer_spooler_fix.ps1         # Printer spooler troubleshooting
├── wifi_password_viewer.ps1        # WiFi password recovery
├── EventLogAnalyzer.ps1            # Event log analysis tool
├── README.md                       # This file
├── TODO.md                         # Task tracking and roadmap
├── LICENSE                         # License information
└── .gitignore                      # Git ignore rules
```

---

## 📝 Logging & Output

All scripts create detailed logs in:
```
%TEMP%\SouliTEK-Scripts\<ScriptName>\
```

### Log Types:
- **Verbose Logs:** Detailed execution steps with timestamps
- **JSON Summaries:** Structured data for automation
- **Error Logs:** Specific error messages with remediation steps

### Export Locations:
- **Desktop:** Default location for user-facing reports
- **Temp Folder:** Working directory for automated processes

---

## 🔒 Security & Privacy

### Our Commitment:
- ✅ **No External Connections** - Scripts do not send data to external servers
- ✅ **No Credential Storage** - Passwords are not stored or logged in plaintext
- ✅ **Local Processing Only** - All operations performed locally
- ✅ **Transparent Code** - Open source for security review
- ✅ **Administrator Checks** - Prevents unauthorized execution
- ✅ **Confirmation Prompts** - Destructive actions require explicit consent

### Best Practices:
1. Review scripts before first use
2. Run in test environment when possible
3. Back up important data before system changes
4. Delete exported password files after use
5. Keep scripts updated to latest version

---

## 🤝 Contributing

We welcome contributions from the IT community!

### How to Contribute:
1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

### Coding Standards:
- Follow existing PowerShell best practices
- Include comment-based help for all functions
- Add error handling with try/catch blocks
- Test on Windows 10/11 before submitting
- Update README with new features

---

## 🐛 Troubleshooting

### Common Issues:

**"Script cannot be loaded because running scripts is disabled"**
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

**"Administrator privileges required"**
- Right-click PowerShell → "Run as Administrator"
- Or use: `Start-Process powershell -Verb RunAs`

**"Access Denied" errors**
- Verify you're running as Administrator
- Check antivirus/security software isn't blocking

**Scripts not finding files/services**
- Ensure target system is Windows 8.1+
- Some features require specific Windows versions

---

## 📋 Roadmap

See [TODO.md](TODO.md) for detailed task tracking and upcoming features.

### Planned Features:
- [ ] Network diagnostics tool
- [ ] Disk health analyzer
- [ ] System cleanup utility
- [ ] Remote support toolkit
- [ ] Unified GUI launcher

---

## 📄 License

**Proprietary Software**  
© 2025 SouliTEK - All Rights Reserved

This software is provided "AS IS" without warranty of any kind. Use at your own risk. The user is solely responsible for any outcomes, damages, or issues that may arise from using these scripts.

### Usage Terms:
- ✅ Free for personal and commercial use
- ✅ Modification allowed for personal use
- ❌ Redistribution prohibited without permission
- ❌ Commercial resale prohibited

For licensing inquiries, contact SouliTEK.

---

## 👨‍💻 About SouliTEK

**Professional IT Solutions for Your Business**

SouliTEK provides comprehensive IT services including:
- 🔧 Computer Repair & Maintenance
- 🌐 Network Setup & Support
- 💻 Software Solutions
- 🏢 Business IT Consulting
- 🛡️ Security & Data Protection

### Contact:
- **Website:** [https://soulitek.co.il](https://soulitek.co.il)
- **Email:** contact@soulitek.co.il
- **Support:** Available for Israeli businesses
- **Language:** Hebrew & English support

---

## 🌟 Acknowledgments

- Built for IT professionals by IT professionals
- Inspired by real-world helpdesk challenges
- Community feedback and feature requests welcome
- Special thanks to the PowerShell community

---

## 📞 Support

### Getting Help:
1. Check script's built-in Help menu
2. Review verbose logs in `%TEMP%\SouliTEK-Scripts\`
3. Search [Issues](https://github.com/YourUsername/Soulitek-AIO/issues) for similar problems
4. Open a new issue with:
   - Script name and version
   - Windows version
   - Error messages
   - Steps to reproduce

### Professional Support:
For enterprise support and custom script development, contact SouliTEK directly.

---

<div align="center">

**Made with ❤️ in Israel**

*Empowering IT professionals with better tools*

[![Website](https://img.shields.io/badge/Website-soulitek.co.il-blue?style=for-the-badge)](https://soulitek.co.il)
[![PowerShell](https://img.shields.io/badge/PowerShell-Powered-blue?style=for-the-badge&logo=powershell)](https://docs.microsoft.com/powershell/)

</div>

