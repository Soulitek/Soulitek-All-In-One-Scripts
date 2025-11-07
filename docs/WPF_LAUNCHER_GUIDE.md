# 🎨 WPF Launcher Guide - SouliTEK All-In-One Scripts

## Overview

The SouliTEK launcher has been upgraded from Windows Forms to **Windows Presentation Foundation (WPF)** - Microsoft's modern UI framework. This provides a significantly improved user experience with Material Design aesthetics, smooth animations, and professional styling.

---

## ✨ What's New in WPF Version 2.0

### **Visual Improvements**
- ✅ SouliTEK logo displayed in header
- ✅ Modern gradient backgrounds
- ✅ Rounded corners throughout the interface
- ✅ Drop shadow effects for depth
- ✅ Smooth hover animations
- ✅ Custom borderless window with draggable title bar
- ✅ Color-coded category buttons
- ✅ Professional card-based tool layout
- ✅ Material Design color palette

### **Technical Improvements**
- ✅ Hardware-accelerated rendering
- ✅ Better high-DPI display support
- ✅ Smoother animations and transitions
- ✅ Cleaner code separation (XAML for UI, PowerShell for logic)
- ✅ More maintainable and extensible architecture

### **Functional Improvements**
- ✅ Same powerful search and category filtering
- ✅ All 11 tools fully supported
- ✅ Same tool launching mechanism
- ✅ Same keyboard shortcuts and workflows
- ✅ Backward compatible with existing scripts

---

## 📁 Project Structure

```
Soulitek-AIO/
├── launcher/
│   ├── SouliTEK-Launcher-WPF.ps1    # Main WPF launcher (PowerShell)
│   ├── MainWindow.xaml               # UI design (XAML)
│   └── SouliTEK-Launcher.ps1         # Old Forms launcher (deprecated)
├── scripts/                          # PowerShell tool scripts (unchanged)
├── assets/                           # Images and icons (unchanged)
├── (no EXE build script)
└── docs/
    └── WPF_LAUNCHER_GUIDE.md         # This file
```

---

## 🚀 How to Run the WPF Launcher

### **Method 1: Run Directly (Development)**

```powershell
# From the project root
.\launcher\SouliTEK-Launcher-WPF.ps1
```

### **Method 2: Portable Run (No Installation)**

```powershell
# From the project root after extracting the repo
.\launcher\SouliTEK-Launcher-WPF.ps1
```

### **Method 3: Run with Admin Privileges**

```powershell
# Right-click and select "Run as Administrator"
# Or run from elevated PowerShell:
Start-Process powershell -Verb RunAs -ArgumentList "-ExecutionPolicy Bypass -File .\launcher\SouliTEK-Launcher-WPF.ps1"
```

---

## 🛠️ Distribution (Scripts Only)

We no longer ship or document EXE builds. Distribute the repository (or a ZIP of it) and run the launcher script directly.

---

## 🎨 UI Architecture

### **XAML (MainWindow.xaml)**

The UI is defined using XAML (eXtensible Application Markup Language) - similar to HTML for desktop applications.

**Key Features:**
- **Styles:** Reusable button and card styles
- **Resources:** Color definitions, templates
- **Layout:** Grid-based responsive layout
- **Controls:** TextBox, Button, ScrollViewer, etc.

**Example XAML Structure:**
```xml
<Window>
    <Window.Resources>
        <!-- Styles defined here -->
        <Style x:Key="ModernButton" TargetType="Button">
            <!-- Button styling -->
        </Style>
    </Window.Resources>
    
    <Grid>
        <!-- UI elements here -->
        <Button Name="LaunchButton" Style="{StaticResource ModernButton}"/>
    </Grid>
</Window>
```

### **PowerShell (SouliTEK-Launcher-WPF.ps1)**

The logic is in PowerShell, which loads the XAML and adds event handlers.

**Key Components:**
1. **XAML Loading:** Reads `MainWindow.xaml` and creates window
2. **Control Access:** Gets references to UI elements by name
3. **Event Handlers:** Attaches click events, search logic, etc.
4. **Business Logic:** Tool filtering, launching, admin checks

**Example PowerShell Logic:**
```powershell
# Load XAML
[xml]$xaml = Get-Content "MainWindow.xaml"
$window = [Windows.Markup.XamlReader]::Load($reader)

# Get control reference
$launchButton = $window.FindName("LaunchButton")

# Add event handler
$launchButton.Add_Click({
    # Handle button click
    Start-Tool -ScriptName "battery_report_generator.ps1"
})

# Show window
$window.ShowDialog()
```

---

## 🎯 Customization Guide

### **Changing Colors**

Edit `MainWindow.xaml` to change the color scheme:

```xml
<!-- Header Gradient -->
<LinearGradientBrush StartPoint="0,0" EndPoint="1,1">
    <GradientStop Color="#667eea" Offset="0"/>  <!-- Change this -->
    <GradientStop Color="#764ba2" Offset="1"/>  <!-- And this -->
</LinearGradientBrush>

<!-- Category Button Colors in PowerShell -->
$categories = @{
    "All" = @{ Color = "#6366f1" }  <!-- Change these -->
    "Network" = @{ Color = "#3b82f6" }
    # ...
}
```

### **Adding New Tools**

Add to the `$Script:Tools` array in `SouliTEK-Launcher-WPF.ps1`:

```powershell
@{
    Name = "My New Tool"
    Icon = "🛠️"
    Description = "Description of my new tool"
    Script = "my_new_tool.ps1"
    Category = "Support"  # or Network, Security, etc.
    Tags = @("keyword1", "keyword2")
    Color = "#10b981"
}
```

### **Modifying Layout**

Edit `MainWindow.xaml` grid definitions:

```xml
<Grid.RowDefinitions>
    <RowDefinition Height="40"/>   <!-- Title bar height -->
    <RowDefinition Height="120"/>  <!-- Header height -->
    <!-- Adjust these values to resize sections -->
</Grid.RowDefinitions>
```

---

## 🔧 Troubleshooting

### **Issue: "MainWindow.xaml not found"**

**Cause:** XAML file is not in the same directory as the launcher script.

**Solution:**
```powershell
# Ensure this structure:
launcher/
├── SouliTEK-Launcher-WPF.ps1
└── MainWindow.xaml
```

### **Issue: "Could not load type PresentationFramework"**

**Cause:** .NET Framework assemblies not loaded.

**Solution:** Ensure script has these lines at the top:
```powershell
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase
```

### **Issue: Window doesn't appear or crashes**

**Cause:** XAML syntax error or control name mismatch.

**Solution:**
1. Validate XAML syntax
2. Ensure control names match between XAML and PowerShell:
   ```xml
   <!-- In XAML -->
   <Button Name="LaunchButton"/>
   ```
   ```powershell
   # In PowerShell
   $launchButton = $window.FindName("LaunchButton")
   ```

### **Issue: Tools not launching**

**Cause:** Scripts folder path incorrect.

**Solution:** Check path configuration:
```powershell
$Script:ScriptPath = Join-Path $Script:RootPath "scripts"
# Verify: Test-Path $Script:ScriptPath
```

### **Issue: "Access denied" or tools don't work properly**

**Cause:** Script is not running with administrator privileges.

**Solution:** The WPF launcher automatically handles this! The script now automatically relaunches itself with administrator privileges if it's not already running as admin. You should see messages like:

```
Relaunching as Administrator...
Running as Administrator.
```

The script will show a UAC elevation prompt, and then continue running with full administrator privileges. All your tools will now work properly without any manual intervention.

If elevation fails, you'll see an error message and instructions to run manually as administrator.

### **Issue: "ExecutionPolicy" errors or script won't run**

**Cause:** PowerShell execution policy is set to Restricted or AllSigned.

**Solution:** The WPF launcher automatically handles this! The script now checks your execution policy at startup and temporarily sets it to RemoteSigned for the current session only. You should see a green message like:

```
Execution policy temporarily set to RemoteSigned for this session.
```

If you see an error message instead, you may need to manually set the execution policy:

```powershell
# Temporarily for this session (recommended)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process

# Or permanently (use with caution)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

**Note:** The launcher uses `-Scope Process` so changes only apply to the current PowerShell session and don't affect your system permanently.

### **Issue: Emoji icons not displaying**

**Cause:** Font doesn't support emoji.

**Solution:** Change `FontFamily` in XAML:
```xml
<TextBlock Text="🔋" FontFamily="Segoe UI Emoji"/>
```

---

## 📦 Distribution Options

### **Option 1: Portable ZIP Package**

Create a ZIP file containing:
```
SouliTEK-AIO-Portable.zip
├── SouliTEK-Launcher.exe
├── MainWindow.xaml
├── scripts/
└── assets/
```

**Pros:**
- ✅ True portability
- ✅ No installation required
- ✅ Easy to update

**Cons:**
- ⚠️ Users must extract before running
- ⚠️ Multiple files to manage

### **Option 2: NSIS Installer**

Create a professional Windows installer:

```nsis
!include "MUI2.nsh"

Name "SouliTEK All-In-One Scripts"
OutFile "SouliTEK-Setup.exe"
InstallDir "$PROGRAMFILES\SouliTEK"

Section "Install"
    SetOutPath "$INSTDIR"
    File "build\SouliTEK-Launcher.exe"
    File "build\MainWindow.xaml"
    File /r "build\scripts"
    File /r "build\assets"
    
    CreateShortcut "$DESKTOP\SouliTEK Launcher.lnk" "$INSTDIR\SouliTEK-Launcher.exe"
SectionEnd
```

**Pros:**
- ✅ Professional installation experience
- ✅ Add/Remove Programs integration
- ✅ Desktop shortcuts
- ✅ Uninstaller included

**Cons:**
- ⚠️ Requires NSIS to build
- ⚠️ More complex setup

### **Option 3: Self-Extracting Archive**

Use IExpress (built into Windows):

1. Run `iexpress` from Run dialog
2. Create self-extracting package
3. Include all files from `build/` folder
4. Set command: `SouliTEK-Launcher.exe`

**Pros:**
- ✅ Single EXE installer
- ✅ No additional tools needed
- ✅ Windows built-in tool

**Cons:**
- ⚠️ Manual GUI process
- ⚠️ Extracts to temp folder

---

## 🔄 Migration from Windows Forms

### **For Users**

**No changes required!** The WPF launcher is a drop-in replacement:
- Same functionality
- Same tools
- Same keyboard shortcuts
- Just prettier UI

### **For Developers**

**Key Differences:**

| Aspect | Windows Forms | WPF |
|--------|--------------|-----|
| **UI Definition** | Code-based | XAML-based |
| **Styling** | Per-control properties | Reusable styles |
| **Layout** | Absolute positioning | Flexible grid/stack |
| **Rendering** | GDI+ | DirectX (hardware) |
| **Animations** | Manual timers | Built-in storyboards |
| **Data Binding** | Manual updates | Automatic binding |

**Code Comparison:**

```powershell
# Windows Forms
$button = New-Object System.Windows.Forms.Button
$button.Text = "Launch"
$button.Location = New-Object System.Drawing.Point(100, 100)
$button.Size = New-Object System.Drawing.Size(120, 40)
$button.BackColor = [System.Drawing.Color]::Blue
$form.Controls.Add($button)

# WPF
# In XAML:
<Button Name="LaunchButton" Content="Launch" 
        Width="120" Height="40" 
        Background="Blue" 
        Margin="100,100,0,0"/>

# In PowerShell:
$launchButton = $window.FindName("LaunchButton")
# Button is already styled via XAML
```

---

## 🎓 Learning Resources

### **XAML Basics**
- Microsoft Docs: [XAML Overview](https://docs.microsoft.com/en-us/dotnet/desktop/wpf/xaml/)
- XAML Playground: [XAMLTest.com](https://xamltest.com)

### **WPF with PowerShell**
- [PowerShell WPF Tutorial](https://foxdeploy.com/series/learning-gui-toolmaking-series/)
- [WPF Control Gallery](https://docs.microsoft.com/en-us/windows/apps/design/controls/)

### **PS2EXE Documentation**
- GitHub: [MScholtes/PS2EXE](https://github.com/MScholtes/PS2EXE)
- PS Gallery: [PS2EXE Module](https://www.powershellgallery.com/packages/ps2exe)

---

## 📝 Version History

### **Version 2.0.0** (Current)
- ✅ Complete WPF rewrite
- ✅ Modern Material Design UI
- ✅ Gradient backgrounds and shadows
- ✅ Smooth animations
- ✅ Custom borderless window
- ✅ All 11 tools supported

### **Version 1.0.0** (Legacy)
- Windows Forms-based launcher
- Basic button grid layout
- Functional but dated appearance

---

## 🆘 Support

### **Issues & Questions**

- **Website:** [www.soulitek.co.il](www.soulitek.co.il)
- **Email:** letstalk@soulitek.co.il
- **GitHub:** [Soulitek/Soulitek-All-In-One-Scripts](https://github.com/Soulitek/Soulitek-All-In-One-Scripts)

### **Bug Reports**

When reporting bugs, please include:
1. Windows version
2. PowerShell version (`$PSVersionTable`)
3. Error message (if any)
4. Steps to reproduce
5. Screenshot (if UI-related)

---

## 📄 License

© 2025 SouliTEK - All Rights Reserved

Proprietary software for internal use and authorized distribution only.

---

**Made with ❤️ in Soulitek by SouliTEK**

