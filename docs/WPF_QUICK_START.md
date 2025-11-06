# 🚀 WPF Launcher - Quick Start Guide

## ⚡ TL;DR - Get Started in 30 Seconds

```powershell
# Run the WPF launcher
.\launcher\SouliTEK-Launcher-WPF.ps1
```

---

## 🎨 What is the WPF Launcher?

The **WPF (Windows Presentation Foundation) Launcher** is a modern, beautiful GUI for accessing all SouliTEK PowerShell tools. It replaces the old Windows Forms launcher with:

- ✨ Modern Material Design UI
- 🎨 Gradient backgrounds & shadows
- 🔍 Real-time search filtering
- 📂 Category-based organization
- 🚀 Smooth animations
- 💪 All 11 tools in one place

---

## 📋 Prerequisites

- **Windows 8.1+** (10/11 recommended)
- **PowerShell 5.1+** (built into Windows)
- **Administrator privileges** (for some tools)

**Note:** EXE builds are no longer supported or documented.

---

## 🏃 Running the Launcher

### **Method 1: Direct Run (Fastest)**

```powershell
# From project root
.\launcher\SouliTEK-Launcher-WPF.ps1
```

**Or double-click the file in File Explorer**

### **Method 2: As Administrator**

```powershell
# Right-click > Run as Administrator
# Or:
Start-Process powershell -Verb RunAs -ArgumentList "-ExecutionPolicy Bypass -File .\launcher\SouliTEK-Launcher-WPF.ps1"
```

### **Method 3: From Existing Wrapper**

```powershell
# The root launcher will auto-detect WPF version
.\SouliTEK-Launcher.ps1
```

---

## 🔨 Building to EXE

EXE packaging has been removed. Distribute and run the PowerShell launcher directly.

---

## 📦 Distribution

Distribute the repository (or a ZIP of it). Users run `launcher/SouliTEK-Launcher-WPF.ps1`.

### **Distribution Options**

**Option 1: ZIP Archive** (Simplest)
```powershell
# Compress the build folder
Compress-Archive -Path ".\build\*" -DestinationPath "SouliTEK-AIO-v2.0.zip"
```

**Option 2: Create Installer** (Professional)
- Use NSIS, Inno Setup, or Advanced Installer
- See `docs/WPF_LAUNCHER_GUIDE.md` for details

**Option 3: Self-Extracting EXE**
- Use IExpress (built into Windows)
- Run `iexpress` and follow the wizard

---

## 🎯 Using the Launcher

### **Interface Overview**

```
┌─────────────────────────────────────────┐
│ 🎨 Header (Gradient)                    │
├─────────────────────────────────────────┤
│ 🔍 Search: [Type to filter...]         │
│ 📂 Categories: [All] [Network] [...]   │
├─────────────────────────────────────────┤
│                                          │
│  [Tool Card 1]  ← Click to launch       │
│  [Tool Card 2]                           │
│  [Tool Card 3]                           │
│                                          │
├─────────────────────────────────────────┤
│ Status: Ready │ Admin Status ✓          │
├─────────────────────────────────────────┤
│ [Help] [About] [GitHub] [Website] [Exit]│
└─────────────────────────────────────────┘
```

### **Key Features**

1. **Search Box** - Type to filter tools by name, description, or keywords
2. **Category Buttons** - Click to show only specific category (Network, Security, etc.)
3. **Tool Cards** - Click "Launch" button to open any tool
4. **Status Bar** - Shows current filter and admin status

### **Keyboard Shortcuts**

- **Click & Drag** title bar to move window
- **Type in search** to filter tools
- **Click category** to filter by type
- **Click tool's Launch** button to start

---

## 🔧 Troubleshooting

### **"MainWindow.xaml not found"**

**Solution:** Ensure XAML file is in the launcher folder:
```powershell
# Check structure:
launcher/
├── SouliTEK-Launcher-WPF.ps1
└── MainWindow.xaml  ← Must exist!
```

### **"Cannot load assembly PresentationFramework"**

**Solution:** Update PowerShell or check .NET Framework:
```powershell
# Check PowerShell version
$PSVersionTable

# Should be 5.1 or higher
```

### **Execution Policy Error**

**Solution:** Allow script execution:
```powershell
# For current session only
powershell -ExecutionPolicy Bypass -File .\launcher\SouliTEK-Launcher-WPF.ps1

# Or set permanently (requires admin)
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### **Window Not Appearing**

**Cause:** XAML syntax error

**Solution:**
1. Check for error messages in PowerShell
2. Validate XAML syntax
3. See `docs/WPF_LAUNCHER_GUIDE.md` for detailed troubleshooting

### **Tools Not Launching**

**Cause:** Scripts folder not found

**Solution:** Verify folder structure:
```powershell
# Check paths
Test-Path ".\scripts"
Test-Path ".\launcher\SouliTEK-Launcher-WPF.ps1"
Test-Path ".\launcher\MainWindow.xaml"
```

---

## 🎨 Customization

### **Change Colors**

Edit `MainWindow.xaml`:

```xml
<!-- Line ~164: Header gradient -->
<GradientStop Color="#667eea" Offset="0"/>  ← Change this
<GradientStop Color="#764ba2" Offset="1"/>  ← And this
```

### **Add New Tool**

Edit `SouliTEK-Launcher-WPF.ps1`:

```powershell
# Add to $Script:Tools array (around line 44)
@{
    Name = "My New Tool"
    Icon = "🛠️"
    Description = "What my tool does"
    Script = "my_tool.ps1"
    Category = "Support"
    Tags = @("keyword1", "keyword2")
    Color = "#10b981"
}
```

### **Modify Window Size**

Edit `MainWindow.xaml` (line 4-5):

```xml
Height="800"   ← Change height
Width="1000"   ← Change width
```

---

## 📚 Additional Resources

- **Full Guide:** `docs/WPF_LAUNCHER_GUIDE.md`
- **Main README:** `README.md`
- **Support:** letstalk@soulitek.co.il
- **GitHub:** https://github.com/Soulitek/Soulitek-All-In-One-Scripts

---

## ✅ Quick Checklist

Before distributing:

- [ ] Test the launcher runs without errors
- [ ] All 11 tools are visible and launch correctly
- [ ] Search and category filtering work
- [ ] Scripts and assets folders are present
- [ ] Tested on target Windows version
- [ ] Admin privileges prompt works (if enabled)

---

## 🎉 Success!

You now have a modern, professional launcher for your PowerShell tools. Enjoy! 🚀

**Made with ❤️ in Soulitek by SouliTEK**

---

**Version:** 2.0.0  
**Last Updated:** October 2025

