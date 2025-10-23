# 🚀 GUI Launcher - User Guide

## Welcome to SouliTEK All-In-One Scripts Launcher!

The **GUI Launcher** provides a beautiful, modern graphical interface to access all your PowerShell tools with just one click - no command-line knowledge required!

---

## ✨ Features at a Glance

### 🔍 **Search-First UX (NEW!)**
- **Real-time Search Box** - Type to instantly filter tools
- **Smart Matching** - Searches name, description, category, and tags
- **Live Results** - Tools filter as you type
- **No Results Message** - Clear feedback when nothing matches
- **Example Searches:** "printer", "network", "outlook", "backup"

### 🏷️ **Category Filtering (NEW!)**
- **7 Category Buttons** - All, Network, Security, Support, Software, M365, Hardware
- **Color-Coded** - Each category has a distinct color
- **Visual Icons** - Quick recognition (⚡ Network, 🛡 Security, etc.)
- **Toggle Selection** - Click to filter, click again to show all
- **Combo Filtering** - Combine search + category for powerful filtering

### 🎨 **Modern Design**
- Beautiful gradient header with SouliTEK branding
- Clean, professional Windows Forms interface
- Color-coded tool categories for easy identification
- Smooth, intuitive user experience
- Enhanced filter panel with modern design

### 🖱️ **One-Click Launching**
- Launch any tool with a single click
- No need to remember script names
- No PowerShell commands to type
- Instant access to all 10 professional tools

### 📊 **Visual Tool Cards**
Each tool is displayed in an attractive card showing:
- 🎯 **Icon** - Visual identification
- 📝 **Name** - Tool name in color
- 📄 **Description** - What the tool does
- 🏷️ **Category** - Tool type (Hardware, Network, M365, etc.)
- 🚀 **Launch Button** - Start the tool

### ✅ **Smart Features**
- **Administrator Indicator** - Shows if running with admin privileges
- **Status Bar** - Real-time feedback on launched tools and filter results
- **Built-in Help** - Complete usage guide
- **About Dialog** - Version and contact information
- **Quick Links** - Direct access to GitHub and website

---

## 🚀 How to Use

### Quick Start (4 Steps!)

1. **Run the Launcher**
   ```powershell
   .\SouliTEK-Launcher.ps1
   ```
   Or simply **double-click** the file in Windows Explorer!

2. **Find Your Tool** (NEW!)
   - **Option A:** Type in the search box (e.g., "printer", "network")
   - **Option B:** Click a category button (Network, Security, etc.)
   - **Option C:** Scroll through all tool cards
   - Use search + category together for precise filtering!

3. **Browse Filtered Results**
   - View tools matching your search/category
   - Read descriptions to confirm it's what you need
   - Status bar shows how many tools match

4. **Launch a Tool**
   - Click the **"Launch"** button on any tool card
   - The tool opens in a new PowerShell window
   - Follow the on-screen instructions in the tool

**That's it!** No command-line expertise needed! 🎉

### 🔍 Search Examples

| Search Term | Results |
|------------|---------|
| `printer` | Printer Spooler Fix |
| `network` | WiFi Password Viewer, Network Test Tool |
| `outlook` | PST Finder (via tags) |
| `security` | BitLocker Status Report, USB Device Log |
| `encryption` | BitLocker Status Report |
| `backup` | PST Finder (via tags) |

### 🏷️ Category Quick Reference

| Category | Tools | Description |
|----------|-------|-------------|
| **All** | 10 tools | Show everything |
| **Network** | 2 tools | WiFi, network diagnostics |
| **Security** | 2 tools | BitLocker, USB forensics |
| **Support** | 3 tools | Troubleshooting, diagnostics |
| **Software** | 1 tool | Chocolatey installer |
| **M365** | 1 tool | Outlook/Office 365 tools |
| **Hardware** | 1 tool | Battery health |

---

## 🎨 Understanding the Interface

### Header Section
```
┌─────────────────────────────────────────────┐
│  🚀 SouliTEK All-In-One Scripts            │
│  Professional PowerShell Tools for IT       │
└─────────────────────────────────────────────┘
```
- Indigo gradient background
- Clear branding and title
- Professional appearance

### Search & Filter Panel (NEW!)
```
┌─────────────────────────────────────────────┐
│  🔍 Search: [________________________]      │
│                                             │
│  Categories:                                │
│  [≡ All] [⚡ Network] [🛡 Security] [🔧 Support] │
│  [📦 Software] [📧 M365] [⚙ Hardware]       │
└─────────────────────────────────────────────┘
```
- Search box with real-time filtering
- Color-coded category buttons
- Active category is highlighted
- Visual feedback on selection

### Tool Cards
Each tool card contains:

```
┌─────────────────────────────────────────────┐
│ 🔋  Battery Report Generator    [Hardware] │
│     Generate comprehensive battery          │
│     health reports for laptops              │
│                            [Launch Button]  │
└─────────────────────────────────────────────┘
```

**Color Codes:**
- 🔵 **Blue** (#3498db) - Hardware tools
- 🟢 **Green** (#2ecc71) - Support tools
- 🟢 **Teal** (#1abc9c) - Network tools (WiFi)
- 🔵 **Blue** (#3b82f6) - Network tools (Testing)
- 🔴 **Red** (#dc2626) - Security tools (BitLocker)
- 🟣 **Purple** (#8b5cf6) - Security tools (USB) / Software
- 🟠 **Orange** (#d97706) - M365 tools
- 🟠 **Orange** (#f39c12) - Support tools (Event Log)
- 🔴 **Red** (#e74c3c) - Support tools (Printer)
- 🟢 **Green** (#10b981) - Software tools (Chocolatey)

### Status Bar
```
┌─────────────────────────────────────────────┐
│ Showing 10 tool(s) in 'All' category  [+] Administrator │
└─────────────────────────────────────────────┘
```
- **Left Side** - Current status, filter results, and tool count
- **Right Side** - Administrator privilege indicator
  - [+] Administrator (Green) - Full privileges
  - [!] Not Administrator (Orange) - Limited privileges
- **Filter Feedback** - Shows "No tools found" when nothing matches

### Bottom Buttons
```
[❓ Help] [ℹ️ About] [💻 GitHub] [🌐 Website] [❌ Exit]
```

---

## 🛠️ Available Tools (10 Total)

### 1. 🔋 Battery Report Generator
**Category:** Hardware | **Icon:** [B] | **Color:** Blue  
**Tags:** battery, laptop, health, report, power

Generate comprehensive battery health reports including:
- Battery capacity analysis
- Health percentage
- Charge cycles
- Detailed 28-day reports

**Best For:** Laptop maintenance, battery diagnostics  
**Search:** "battery", "laptop", "power", "health"

---

### 2. 📧 PST Finder
**Category:** M365 | **Icon:** [M] | **Color:** Orange  
**Tags:** outlook, pst, email, microsoft, office, 365, backup

Locate and analyze Outlook PST files:
- Quick scan common locations
- Deep scan all drives
- Size analysis
- Export to CSV/HTML

**Best For:** Email management, disk cleanup, migrations  
**Search:** "pst", "outlook", "email", "office", "365", "backup"

---

### 3. 🖨️ Printer Spooler Fix
**Category:** Support | **Icon:** [P] | **Color:** Red  
**Tags:** printer, spooler, print, troubleshoot, fix, repair

Fix printer issues automatically:
- Stop/restart spooler service
- Clear stuck print jobs
- Monitor mode
- Status checking

**Best For:** Printer problems, stuck print queues  
**Search:** "printer", "spooler", "print", "fix"

---

### 4. 📶 WiFi Password Viewer
**Category:** Network | **Icon:** [W] | **Color:** Teal  
**Tags:** wifi, password, network, wireless, credentials

View and export saved WiFi passwords:
- All saved networks
- Current network
- Export to file
- Quick copy to clipboard

**Best For:** Network setup, password recovery  
**Search:** "wifi", "password", "wireless", "network"

---

### 5. 📊 Event Log Analyzer
**Category:** Support | **Icon:** [E] | **Color:** Orange  
**Tags:** event, log, analyzer, diagnostics, windows, troubleshoot

Analyze Windows Event Logs:
- Application, System, Security logs
- Error and warning summaries
- Top event IDs
- Export to CSV/JSON

**Best For:** Troubleshooting, diagnostics, auditing  
**Search:** "event", "log", "analyzer", "diagnostics"

---

### 6. 🛠️ Remote Support Toolkit
**Category:** Support | **Icon:** [R] | **Color:** Green  
**Tags:** remote, support, diagnostics, system, troubleshoot

Comprehensive system diagnostics:
- Complete system information
- Hardware inventory
- Software list
- Network configuration
- HTML reports
- ZIP packaging

**Best For:** Remote support, documentation, diagnostics  
**Search:** "remote", "support", "diagnostics", "system"

---

### 7. 🌐 Network Test Tool
**Category:** Network | **Icon:** [N] | **Color:** Blue  
**Tags:** network, ping, tracert, dns, latency, diagnostics

Advanced network testing and diagnostics:
- Ping tests with statistics
- Traceroute analysis
- DNS lookup
- Latency monitoring
- Export to HTML/CSV

**Best For:** Network troubleshooting, connectivity issues  
**Search:** "network", "ping", "dns", "tracert", "latency"

---

### 8. 🔒 BitLocker Status Report
**Category:** Security | **Icon:** [S] | **Color:** Red  
**Tags:** bitlocker, encryption, security, recovery, volume

Check BitLocker encryption status:
- All drive encryption status
- Recovery key information
- Security health score
- Export to HTML/CSV/TXT

**Best For:** Security audits, encryption management  
**Search:** "bitlocker", "encryption", "security", "recovery"

---

### 9. 💾 USB Device Log
**Category:** Security | **Icon:** [U] | **Color:** Purple  
**Tags:** usb, forensics, security, audit, device, history

Forensic USB device history analysis:
- Registry scanning
- Event log analysis
- Device timestamps
- VID/PID information
- Export to HTML/CSV/TXT

**Best For:** Security audits, forensics, compliance  
**Search:** "usb", "forensics", "security", "device"

---

### 10. 📦 Chocolatey Installer
**Category:** Software | **Icon:** [C] | **Color:** Green  
**Tags:** chocolatey, installer, software, packages, apps, install

Interactive package installer with Ninite-like UX:
- 40+ curated packages
- Auto-install Chocolatey
- Preset support
- Idempotent installation
- Professional logging

**Best For:** Software deployment, system setup  
**Search:** "chocolatey", "installer", "software", "packages", "apps"

---

## 💡 Tips & Best Practices

### For Best Results:
1. ✅ **Run as Administrator** - Right-click and select "Run as Administrator"
2. ✅ **Keep All Scripts Together** - Launcher must be in same folder as tools
3. ✅ **One Tool at a Time** - Let each tool complete before launching another
4. ✅ **Read Tool Instructions** - Each tool has its own help menu

### Administrator Privileges:
- **Recommended** for all tools
- **Required** for:
  - Printer Spooler Fix
  - Event Log Analyzer
  - Some Remote Support Toolkit features

### Common Workflows:

**Scenario 1: Laptop Maintenance**
```
1. Type "battery" in search box
2. Launch Battery Report Generator
3. Review battery health
4. Type "event" in search box
5. Launch Event Log Analyzer
6. Check for errors
```

**Scenario 2: Printer Problems**
```
1. Type "printer" in search box (finds Printer Spooler Fix)
2. Launch Printer Spooler Fix
3. Run Basic Fix mode
4. If issues persist, use Monitor mode
```

**Scenario 3: Remote Support**
```
1. Click "Support" category button
2. Launch Remote Support Toolkit
3. Create Full Support Package
4. Create ZIP file
5. Email to IT support
```

**Scenario 4: Network Troubleshooting**
```
1. Click "Network" category (shows 2 tools)
2. Launch Network Test Tool for diagnostics
3. If needed, launch WiFi Password Viewer
```

**Scenario 5: Security Audit**
```
1. Click "Security" category (shows 2 tools)
2. Launch BitLocker Status Report for encryption
3. Launch USB Device Log for forensics
4. Export reports for compliance
```

---

## 🔧 Troubleshooting

### Problem: "Script not found" error
**Solution:**
- Ensure launcher is in the same folder as all .ps1 scripts
- Check that script names haven't been changed
- Verify all 6 tools are present

### Problem: Tool won't launch or terminal closes immediately
**Solution:**
- Run launcher as Administrator
- Check PowerShell execution policy: `Set-ExecutionPolicy RemoteSigned`
- Ensure no antivirus blocking
- The launcher now uses `-NoExit` flag to keep PowerShell windows open
- If terminal closes, check for error messages that appear briefly

### Problem: Launcher window is blank
**Solution:**
- Update Windows (requires .NET Framework)
- Run: `Add-Type -AssemblyName System.Windows.Forms`
- Check for PowerShell errors

### Problem: Administrator warning appears
**Solution:**
- Right-click `SouliTEK-Launcher.ps1`
- Select "Run with PowerShell"
- Choose "Run as Administrator"
- Or use: `Start-Process powershell -Verb RunAs -ArgumentList "-File '.\SouliTEK-Launcher.ps1'"`

---

## 🎯 Quick Actions

### Opening the Launcher

**Method 1: Double-Click**
```
1. Navigate to folder in Windows Explorer
2. Double-click SouliTEK-Launcher.ps1
3. GUI opens automatically
```

**Method 2: PowerShell**
```powershell
# Navigate to folder
cd C:\Path\To\Scripts

# Run launcher
.\SouliTEK-Launcher.ps1
```

**Method 3: Run as Administrator**
```powershell
# Right-click SouliTEK-Launcher.ps1
# Select "Run with PowerShell"
# Windows will prompt for admin rights
```

### Using the Buttons

**❓ Help Button**
- Click to see complete usage guide
- Shows all tools and descriptions
- Includes tips and support info

**ℹ️ About Button**
- Version information
- Contact details
- GitHub link
- Copyright information

**💻 GitHub Button**
- Opens repository in browser
- View source code
- Report issues
- Download updates

**🌐 Website Button**
- Visit soulitek.co.il
- Learn about IT services
- Contact information

**❌ Exit Button**
- Close the launcher
- Does not close launched tools

---

## 📊 Interface Layout

```
┌────────────────────────────────────────────────────┐
│          🚀 SouliTEK All-In-One Scripts           │ ← Header
│     Professional PowerShell Tools for IT          │
├────────────────────────────────────────────────────┤
│  🔍 Search: [___________________________]         │ ← Search Box
│                                                    │
│  Categories:                                       │ ← Category
│  [≡ All] [⚡ Network] [🛡 Security] [🔧 Support]   │   Filters
│  [📦 Software] [📧 M365] [⚙ Hardware]             │   (NEW!)
├────────────────────────────────────────────────────┤
│                                                    │
│  ┌──────────────────────────────────────┐        │
│  │ 🔋 Battery Report Generator          │        │
│  │    Generate comprehensive battery    │        │ ← Tool Cards
│  │    health reports for laptops        │        │   (Scrollable)
│  │                        [Launch]      │        │   (Filtered)
│  └──────────────────────────────────────┘        │
│                                                    │
│  ┌──────────────────────────────────────┐        │
│  │ 📧 PST Finder                        │        │
│  │    Locate and analyze Outlook PST    │        │
│  │                        [Launch]      │        │
│  └──────────────────────────────────────┘        │
│                                                    │
│  [... more filtered tool cards ...]              │
│                                                    │
├────────────────────────────────────────────────────┤
│ Showing 10 tool(s) in 'All' category  [+] Admin  │ ← Status Bar
├────────────────────────────────────────────────────┤
│ [Help] [About] [GitHub] [Website]        [Exit]  │ ← Bottom Buttons
└────────────────────────────────────────────────────┘
```

---

## 🌟 Advanced Features

### Keyboard Shortcuts
- **Alt + F4** - Close launcher
- **Tab** - Navigate between buttons
- **Enter** - Activate selected button
- **Scroll Wheel** - Scroll through tools

### Visual Feedback
- **Hover Effects** - Buttons highlight on mouse-over
- **Status Updates** - Real-time launch confirmation
- **Color Coding** - Easy tool identification
- **Icons** - Visual tool recognition

### Accessibility
- Clear, readable fonts (Segoe UI)
- High contrast colors
- Large clickable buttons
- Descriptive labels
- Status indicators

---

## 📝 Version History

### Version 2.0.0 (Current) - Enhanced with Search & Filtering
**Release Date:** October 23, 2025

**NEW Features:**
- 🔍 **Search-First UX** - Real-time search box with smart matching
- 🏷️ **Category Filtering** - 7 color-coded category buttons
- 🏷️ **Tag System** - Comprehensive tags for better searchability
- 📊 **Dynamic Filtering** - Combine search + category filters
- 💯 **10 Tools** - Added 4 new professional tools
- 📧 **M365 Category** - New category for Microsoft 365 tools
- 📈 **Enhanced Status Bar** - Shows filter results and tool count

**All Features:**
- Modern GUI design with enhanced filter panel
- One-click launching
- Built-in help system
- Administrator detection
- Real-time search and filtering
- Category-based organization
- Status bar with live feedback
- Quick link buttons

**Tools Included (10 Total):**
1. Battery Report Generator (Hardware)
2. PST Finder (M365)
3. Printer Spooler Fix (Support)
4. WiFi Password Viewer (Network)
5. Event Log Analyzer (Support)
6. Remote Support Toolkit (Support)
7. Network Test Tool (Network) - NEW!
8. BitLocker Status Report (Security) - NEW!
9. USB Device Log (Security) - NEW!
10. Chocolatey Installer (Software) - NEW!

---

### Version 1.0.0
**Release Date:** October 23, 2025

**Features:**
- Initial release
- 6 integrated tools
- Modern GUI design
- One-click launching
- Built-in help system
- Administrator detection
- Status bar feedback
- Quick link buttons

---

## 🆘 Getting Support

### Self-Help Resources
1. **Built-in Help** - Click ❓ Help button
2. **Tool-Specific Help** - Each tool has its own help menu
3. **README.md** - Project documentation
4. **GitHub Issues** - Community support

### Contact Information
- **Website:** https://soulitek.co.il
- **Email:** letstalk@soulitek.co.il
- **GitHub:** https://github.com/Soulitek/Soulitek-All-In-One-Scripts

### Reporting Issues
When reporting problems, include:
- Windows version
- PowerShell version (`$PSVersionTable.PSVersion`)
- Error messages (if any)
- Steps to reproduce
- Screenshot (if applicable)

---

## 🎓 Learning More

### For IT Professionals
- Explore each tool's advanced features
- Read tool-specific documentation
- Review PowerShell source code
- Customize for your environment

### For End Users
- Start with Quick Info features
- Progress to basic functions
- Use export features for sharing
- Consult IT support when needed

### Best Practices
- ✅ Regular battery health checks
- ✅ Monthly event log reviews
- ✅ PST file cleanup
- ✅ WiFi password backups
- ✅ System documentation

---

## 🎉 Why Use the GUI Launcher?

### Instead of Command Line:
- ❌ No typing complex commands
- ❌ No memorizing script names
- ❌ No PowerShell knowledge required
- ❌ No confusion about which tool to use

### With GUI Launcher:
- ✅ Visual, intuitive interface
- ✅ Clear descriptions
- ✅ One-click access
- ✅ Professional appearance
- ✅ Built-in help
- ✅ Easy for any skill level

---

## 📚 Additional Resources

### Documentation Files
- **README.md** - Main project documentation
- **TODO.md** - Roadmap and planned features
- **CONTRIBUTING.md** - How to contribute
- **SUCCESS.md** - Recent updates
- **NEW_TOOL_ADDED.md** - Remote Support Toolkit guide

### Online Resources
- **GitHub Repository** - Source code and updates
- **SouliTEK Website** - IT services and support
- **Tool-Specific Guides** - In each tool's help menu

---

## 💬 Feedback Welcome!

We'd love to hear from you:
- ⭐ Star the GitHub repository
- 🐛 Report bugs via GitHub Issues
- 💡 Suggest new features
- 📝 Share your experience
- 🤝 Contribute improvements

---

<div align="center">

**Made with ❤️ by SouliTEK**

*Empowering IT Professionals with Better Tools*

🌐 https://soulitek.co.il | 📧 letstalk@soulitek.co.il

**© 2025 SouliTEK - All Rights Reserved**

</div>

