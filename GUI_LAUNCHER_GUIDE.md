# 🚀 GUI Launcher - User Guide

## Welcome to SouliTEK All-In-One Scripts Launcher!

The **GUI Launcher** provides a beautiful, modern graphical interface to access all your PowerShell tools with just one click - no command-line knowledge required!

---

## ✨ Features at a Glance

### 🎨 **Modern Design**
- Beautiful gradient header with SouliTEK branding
- Clean, professional Windows Forms interface
- Color-coded tool categories for easy identification
- Smooth, intuitive user experience

### 🖱️ **One-Click Launching**
- Launch any tool with a single click
- No need to remember script names
- No PowerShell commands to type
- Instant access to all 6 professional tools

### 📊 **Visual Tool Cards**
Each tool is displayed in an attractive card showing:
- 🎯 **Icon** - Visual identification
- 📝 **Name** - Tool name in color
- 📄 **Description** - What the tool does
- 🏷️ **Category Badge** - Tool type (Hardware, Network, etc.)
- 🚀 **Launch Button** - Start the tool

### ✅ **Smart Features**
- **Administrator Indicator** - Shows if running with admin privileges
- **Status Bar** - Real-time feedback on launched tools
- **Built-in Help** - Complete usage guide
- **About Dialog** - Version and contact information
- **Quick Links** - Direct access to GitHub and website

---

## 🚀 How to Use

### Quick Start (3 Steps!)

1. **Run the Launcher**
   ```powershell
   .\SouliTEK-Launcher.ps1
   ```
   Or simply **double-click** the file in Windows Explorer!

2. **Browse Available Tools**
   - Scroll through the colorful tool cards
   - Read descriptions to find what you need
   - Note the category badges

3. **Launch a Tool**
   - Click the **"Launch"** button on any tool card
   - The tool opens in a new PowerShell window
   - Follow the on-screen instructions in the tool

**That's it!** No command-line expertise needed! 🎉

---

## 🎨 Understanding the Interface

### Header Section
```
┌─────────────────────────────────────────────┐
│  🚀 SouliTEK All-In-One Scripts            │
│  Professional PowerShell Tools for IT       │
└─────────────────────────────────────────────┘
```
- Purple gradient background
- Clear branding and title
- Professional appearance

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
- 🟣 **Purple** (#9b59b6) - Data tools
- 🔴 **Red** (#e74c3c) - Troubleshooting tools
- 🟢 **Teal** (#1abc9c) - Network tools
- 🟠 **Orange** (#f39c12) - Diagnostics tools
- 🟢 **Green** (#2ecc71) - Support tools

### Status Bar
```
┌─────────────────────────────────────────────┐
│ Ready - Select a tool to launch  ✓ Admin   │
└─────────────────────────────────────────────┘
```
- **Left Side** - Current status and last action
- **Right Side** - Administrator privilege indicator
  - ✓ Administrator (Green) - Full privileges
  - ⚠ Not Administrator (Yellow) - Limited privileges

### Bottom Buttons
```
[❓ Help] [ℹ️ About] [💻 GitHub] [🌐 Website] [❌ Exit]
```

---

## 🛠️ Available Tools

### 1. 🔋 Battery Report Generator
**Category:** Hardware  
**Color:** Blue

Generate comprehensive battery health reports including:
- Battery capacity analysis
- Health percentage
- Charge cycles
- Detailed 28-day reports

**Best For:** Laptop maintenance, battery diagnostics

---

### 2. 📧 PST Finder
**Category:** Data  
**Color:** Purple

Locate and analyze Outlook PST files:
- Quick scan common locations
- Deep scan all drives
- Size analysis
- Export to CSV/HTML

**Best For:** Email management, disk cleanup, migrations

---

### 3. 🖨️ Printer Spooler Fix
**Category:** Troubleshooting  
**Color:** Red

Fix printer issues automatically:
- Stop/restart spooler service
- Clear stuck print jobs
- Monitor mode
- Status checking

**Best For:** Printer problems, stuck print queues

---

### 4. 📶 WiFi Password Viewer
**Category:** Network  
**Color:** Teal

View and export saved WiFi passwords:
- All saved networks
- Current network
- Export to file
- Quick copy to clipboard

**Best For:** Network setup, password recovery

---

### 5. 📊 Event Log Analyzer
**Category:** Diagnostics  
**Color:** Orange

Analyze Windows Event Logs:
- Application, System, Security logs
- Error and warning summaries
- Top event IDs
- Export to CSV/JSON

**Best For:** Troubleshooting, diagnostics, auditing

---

### 6. 🛠️ Remote Support Toolkit
**Category:** Support  
**Color:** Green

Comprehensive system diagnostics:
- Complete system information
- Hardware inventory
- Software list
- Network configuration
- HTML reports
- ZIP packaging

**Best For:** Remote support, documentation, diagnostics

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
1. Launch Battery Report Generator
2. Review battery health
3. Launch Event Log Analyzer
4. Check for errors
```

**Scenario 2: Printer Problems**
```
1. Launch Printer Spooler Fix
2. Run Basic Fix mode
3. If issues persist, use Monitor mode
```

**Scenario 3: Remote Support**
```
1. Launch Remote Support Toolkit
2. Create Full Support Package
3. Create ZIP file
4. Email to IT support
```

---

## 🔧 Troubleshooting

### Problem: "Script not found" error
**Solution:**
- Ensure launcher is in the same folder as all .ps1 scripts
- Check that script names haven't been changed
- Verify all 6 tools are present

### Problem: Tool won't launch
**Solution:**
- Run launcher as Administrator
- Check PowerShell execution policy: `Set-ExecutionPolicy RemoteSigned`
- Ensure no antivirus blocking

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
│                                                    │
│  ┌──────────────────────────────────────┐        │
│  │ 🔋 Battery Report Generator          │        │
│  │    Generate comprehensive battery    │        │ ← Tool Cards
│  │    health reports for laptops        │        │   (Scrollable)
│  │                        [Launch]      │        │
│  └──────────────────────────────────────┘        │
│                                                    │
│  ┌──────────────────────────────────────┐        │
│  │ 📧 PST Finder                        │        │
│  │    Locate and analyze Outlook PST    │        │
│  │                        [Launch]      │        │
│  └──────────────────────────────────────┘        │
│                                                    │
│  [... more tool cards ...]                       │
│                                                    │
├────────────────────────────────────────────────────┤
│ Ready - Select a tool to launch  ✓ Administrator │ ← Status Bar
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

### Version 1.0.0 (Current)
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

**Tools Included:**
1. Battery Report Generator
2. PST Finder
3. Printer Spooler Fix
4. WiFi Password Viewer
5. Event Log Analyzer
6. Remote Support Toolkit

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

