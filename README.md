# SouliTEK All-In-One Scripts

<div align="center">

![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue?style=for-the-badge&logo=powershell)
![Windows](https://img.shields.io/badge/Windows-10%2B-0078D6?style=for-the-badge&logo=windows)
![License](https://img.shields.io/badge/License-Proprietary-red?style=for-the-badge)

**Professional PowerShell Tools for IT Technicians**

*By [SouliTEK](https://www.soulitek.co.il)*

</div>

---

## 🚀 Quick Start

### Install
```powershell
iwr -useb https://get.soulitek.co.il | iex
```

### Launch GUI Launcher
```powershell
.\SouliTEK-Launcher.ps1
```

### Run Individual Tools
```powershell
# Run 1-Click PC Install (requires admin)
.\scripts\1-click_pc_install.ps1

# Or launch via WPF GUI for easier access
```

**Note:** Most tools require Administrator privileges. Right-click and select "Run with PowerShell as administrator" if needed.

---

## 🛠️ Tools (33 Scripts)

### 🚀 Setup
- **1-Click PC Install** - Complete PC setup automation: Configure time zone (Jerusalem), regional settings (Israel), Windows updates, power plan, bloatware removal, and install essential software (Chrome, AnyDesk, Office) via WinGet. Includes system restore point creation and detailed installation summary.
- **Essential Tweaks** - Essential Windows tweaks - Default apps, keyboards, language, taskbar settings
- **Softwares Installer** - Interactive package installer - Install essential business apps via WinGet
- **Software Updater** - Manage software updates via WinGet - Check, auto-update, or interactive mode
- **Win11Debloat** - Remove bloatware, disable telemetry, and optimize Windows 10/11 systems

### ⚡ Performance
- **Startup & Boot Time Analyzer** - Analyze startup programs, boot performance, and get optimization recommendations with HTML reports
- **Battery Report Generator** - Generate comprehensive battery health reports for laptops
- **Storage Health Monitor** - Monitor storage health with SMART data, detect reallocated sectors and read errors
- **RAM Slot Utilization Report** - Shows RAM slots used vs total, type (DDR3/DDR4/DDR5), speed, and capacity
- **Disk Usage Analyzer** - Find folders larger than 1 GB and export results sorted by size with HTML visualization

### 🔒 Security
- **BitLocker Status Report** - Check BitLocker encryption status and recovery keys for all volumes
- **VirusTotal Checker** - Check files and URLs against VirusTotal - Malware detection, hash lookup, batch scanning
- **Browser Plugin Checker** - Scan browser extensions for security risks - Chrome, Edge, Firefox, Brave, Opera, Vivaldi
- **USB Device Log** - Forensic USB device history analysis for security audits
- **Local Admin Users Checker** - Identify unnecessary admin accounts - Common attack vector detection

### ☁️ M365
- **PST Finder** - Locate and analyze Outlook PST files across the system
- **License Expiration Checker** - Monitor Microsoft 365 license subscriptions and get alerts for capacity issues
- **M365 User List** - List all Microsoft 365 users with email, phone, MFA status, and comprehensive user information
- **SharePoint Site Inventory** - Build a full map of SharePoint environment - Site URL, template, type, storage, owners, activity
- **Exchange Online** - Collect Exchange Online mailbox information - DisplayName, aliases, license status, mailbox type, protocols, activity

### 🌐 Network
- **WiFi Password Viewer** - View and export saved WiFi passwords from Windows
- **WiFi Monitor** - Monitor WiFi signal strength, frequency band (2.4/5GHz), SSID, and disconnection history
- **Network Test Tool** - Ping, tracert, DNS lookup, and latency testing for network diagnostics
- **Network Configuration Tool** - View IP configuration, set static IP addresses, flush DNS cache, and reset network adapters

### 🌍 Internet
- **Domain & DNS Analyzer** - WHOIS lookup, DNS records analysis, and email security check (SPF, DKIM, DMARC)

### 🛠️ Support
- **Product Key Retriever** - Retrieve Windows and Office product keys from system registry and WMI
- **Printer Spooler Fix** - Comprehensive printer spooler troubleshooting and repair
- **Event Log Analyzer** - Analyze Windows Event Logs with statistical summaries
- **BSOD History Scanner** - Scan Minidump files and event logs to report BSOD history and BugCheck codes
- **OneDrive Status Checker** - Check OneDrive sync status - Detect sync errors, account issues, and verify files are up-to-date
- **System Restore Point** - Create Windows System Restore Points for system recovery and rollback
- **Temp Removal & Disk Cleanup** - Remove temporary files, clean browser cache, empty Recycle Bin, and free up disk space
- **McAfee Removal Tool** - Complete removal of McAfee products using MCPR (McAfee Consumer Product Removal) tool

All scripts in `./scripts/` folder.

---

## 💡 Features

- ✨ **Modern WPF GUI Launcher** - Beautiful Material Design interface with category filtering
- 🔍 **Search-First Interface** - Find tools instantly with real-time search
- 🚀 **1-Click PC Setup** - Automate complete PC configuration for new installations
- 📊 **Export Capabilities** - Export results to CSV/HTML/JSON/TXT formats
- 🛡️ **System Protection** - Built-in restore point creation for safe operations
- ⚡ **Performance Tools** - Comprehensive system analysis and optimization
- ☁️ **M365 Management** - Full Microsoft 365 user and license management
- ✅ **Windows 10, 11 Compatible** - Works on all modern Windows versions

---

## 📋 Requirements

- Windows 10 or higher
- PowerShell 5.1 or higher
- Administrator privileges (for most tools)

---

## 📖 Documentation

See [docs/](docs/) folder for complete documentation.

---

## 📞 Support

- **Website:** www.soulitek.co.il
- **Email:** letstalk@soulitek.co.il
- **Discord:** [Join our Discord server](https://discord.gg/eVqu269QBB)

---

## 📄 License

Proprietary - © 2025 SouliTEK. All Rights Reserved.

---

<div align="center">

**Made with ❤️ in Soulitek**

*Professional IT Solutions for Your Business*

</div>
