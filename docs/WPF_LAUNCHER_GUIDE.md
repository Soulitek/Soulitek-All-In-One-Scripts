# 🎨 WPF Launcher Guide - SouliTEK All-In-One Scripts

## Overview

The SouliTEK launcher has been upgraded from Windows Forms to **Windows Presentation Foundation (WPF)** - Microsoft's modern UI framework. This provides a significantly improved user experience with Material Design aesthetics, smooth animations, and professional styling.

---

## ✨ What's New in WPF Version 2.0

### **Visual Improvements**
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
├── Build-WPF-Launcher.ps1            # Build script for creating EXE
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

### **Method 2: Build to EXE (Distribution)**

```powershell
# Build the launcher into a standalone EXE
.\Build-WPF-Launcher.ps1

# Run the built executable
.\build\SouliTEK-Launcher.exe
```

### **Method 3: Run with Admin Privileges**

```powershell
# Right-click and select "Run as Administrator"
# Or run from elevated PowerShell:
Start-Process powershell -Verb RunAs -ArgumentList "-ExecutionPolicy Bypass -File .\launcher\SouliTEK-Launcher-WPF.ps1"
```

---

## 🛠️ Building as Standalone EXE

The WPF launcher can be compiled into a single executable file using PS2EXE.

### **Prerequisites**

1. **PS2EXE Module**
   ```powershell
   Install-Module ps2exe -Scope CurrentUser
   ```

2. **Icon File (Optional)**
   - Convert `assets/images/Favicon.png` to `.ico` format
   - Use online converter or tool like ImageMagick
   - Place as `assets/images/Favicon.ico`

### **Build Process**

#### **Automatic Build (Recommended)**

```powershell
# Run the build script
.\Build-WPF-Launcher.ps1

# With options
.\Build-WPF-Launcher.ps1 -NoConsole -RequireAdmin
```

**Build Script Features:**
- ✅ Automatic PS2EXE module installation
- ✅ Dependency copying (scripts, assets, XAML)
- ✅ Icon embedding (if available)
- ✅ Version information
- ✅ Build summary and file size

#### **Manual Build**

```powershell
# Import PS2EXE module
Import-Module ps2exe

# Build the EXE
Invoke-ps2exe `
    -inputFile ".\launcher\SouliTEK-Launcher-WPF.ps1" `
    -outputFile ".\build\SouliTEK-Launcher.exe" `
    -iconFile ".\assets\images\Favicon.ico" `
    -title "SouliTEK All-In-One Scripts" `
    -company "SouliTEK" `
    -version "2.0.0" `
    -noConsole `
    -requireAdmin
```

### **Build Output**

After building, the `build/` folder will contain:

```
build/
├── SouliTEK-Launcher.exe      # Standalone executable
├── MainWindow.xaml             # Required XAML file
├── scripts/                    # All PowerShell tools
└── assets/                     # Images and icons
```

**Important:** The entire `build/` folder must be distributed together, as the EXE requires `MainWindow.xaml`, `scripts/`, and `assets/` to function properly.

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

- **Website:** [https://soulitek.co.il](https://soulitek.co.il)
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

**Made with ❤️ in Israel by SouliTEK**

