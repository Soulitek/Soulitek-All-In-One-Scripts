# ============================================================
# SouliTEK All-In-One Scripts - WPF Launcher
# ============================================================
# 
# Coded by: Soulitek.co.il
# IT Solutions for your business
# 
# (C) 2025 Soulitek - All Rights Reserved
# Website: www.soulitek.co.il
# 
# Modern WPF GUI with Material Design aesthetics
# 
# ============================================================

#Requires -Version 5.1

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase

# ============================================================
# SET SCRIPT PATHS
# ============================================================

$Script:LauncherPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$Script:RootPath = Split-Path -Parent $Script:LauncherPath

# ============================================================
# MATERIALDESIGN DEPENDENCIES
# ============================================================


# ============================================================
# IMPORT COMMON MODULE
# ============================================================

$Script:LauncherPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$Script:RootPath = Split-Path -Parent $Script:LauncherPath
$CommonPath = Join-Path $Script:RootPath "modules\SouliTEK-Common.ps1"
if (Test-Path $CommonPath) {
    . $CommonPath
} else {
    Write-Warning "SouliTEK Common Functions not found at: $CommonPath"
    Write-Warning "Some functions may not work properly."
}

# ============================================================
# HELPER FUNCTIONS
# ============================================================

# Use Test-SouliTEKAdministrator from common module
function Test-Administrator {
    return Test-SouliTEKAdministrator
}

# ============================================================
# ICON SYSTEMS - LUCIDE & SIMPLE ICONS
# ============================================================

function Get-SimpleIconPath {
    <#
    .SYNOPSIS
        Returns SVG path data for Simple Icons (brand logos).
    #>
    param([string]$IconName)
    
    # Simple Icons - Brand logos (from https://github.com/simple-icons/simple-icons)
    $simpleIcons = @{
        "GitHub" = "M12 .297c-6.63 0-12 5.373-12 12 0 5.303 3.438 9.8 8.205 11.385.6.113.82-.258.82-.577 0-.285-.01-1.04-.015-2.04-3.338.724-4.042-1.61-4.042-1.61C4.422 18.07 3.633 17.7 3.633 17.7c-1.087-.744.084-.729.084-.729 1.205.084 1.838 1.236 1.838 1.236 1.07 1.835 2.809 1.305 3.495.998.108-.776.417-1.305.76-1.605-2.665-.3-5.466-1.332-5.466-5.93 0-1.31.465-2.38 1.235-3.22-.135-.303-.54-1.523.105-3.176 0 0 1.005-.322 3.3 1.23.96-.267 1.98-.399 3-.405 1.02.006 2.04.138 3 .405 2.28-1.552 3.285-1.23 3.285-1.23.645 1.653.24 2.873.12 3.176.765.84 1.23 1.91 1.23 3.22 0 4.61-2.805 5.625-5.475 5.92.42.36.81 1.096.81 2.22 0 1.606-.015 2.896-.015 3.286 0 .315.21.69.825.57C20.565 22.092 24 17.592 24 12.297c0-6.627-5.373-12-12-12"
        "Discord" = "M20.317 4.3698a19.7913 19.7913 0 00-4.8851-1.5152.0741.0741 0 00-.0785.0371c-.211.3753-.4447.8648-.6083 1.2495-1.8447-.2762-3.68-.2762-5.4868 0-.1636-.3933-.4058-.8742-.6177-1.2495a.077.077 0 00-.0785-.037 19.7363 19.7363 0 00-4.8852 1.515.0699.0699 0 00-.0321.0277C.5334 9.0458-.319 13.5799.0992 18.0578a.0824.0824 0 00.0312.0561c2.0528 1.5076 4.0413 2.4228 5.9929 3.0294a.0777.0777 0 00.0842-.0276c.4616-.6304.8731-1.2952 1.226-1.9942a.076.076 0 00-.0416-.1057c-.6528-.2476-1.2743-.5495-1.8722-.8923a.077.077 0 01-.0076-.1277c.1258-.0943.2517-.1923.3718-.2914a.0743.0743 0 01.0776-.0105c3.9278 1.7933 8.18 1.7933 12.0614 0a.0739.0739 0 01.0785.0095c.1202.099.246.1981.3728.2924a.077.077 0 01-.0066.1276 12.2986 12.2986 0 01-1.873.8914.0766.0766 0 00-.0407.1067c.3604.698.7719 1.3628 1.225 1.9932a.076.076 0 00.0842.0286c1.961-.6067 3.9495-1.5219 6.0023-3.0294a.077.077 0 00.0313-.0552c.5004-5.177-.8382-9.6739-3.5485-13.6604a.061.061 0 00-.0312-.0286zM8.02 15.3312c-1.1825 0-2.1569-1.0857-2.1569-2.419 0-1.3332.9555-2.4189 2.157-2.4189 1.2108 0 2.1757 1.0952 2.1568 2.419 0 1.3332-.9555 2.4189-2.1569 2.4189zm7.9748 0c-1.1825 0-2.1569-1.0857-2.1569-2.419 0-1.3332.9554-2.4189 2.1569-2.4189 1.2108 0 2.1757 1.0952 2.1568 2.419 0 1.3332-.946 2.4189-2.1568 2.4189Z"
        "VirusTotal" = "M10.87 12L0 22.68h24V1.32H0zm10.73 8.52H5.28l8.637-8.448L5.28 3.48H21.6z"
        "McAfee" = "M12 4.8233L1.5793 0v19.1767L12 24l10.4207-4.8233V0zm6.172 11.626l-6.143 2.8428-6.1438-2.8429V6.6894l6.1439 2.8418 6.1429-2.8418z"
        "Firefox" = "M20.452 3.445a11.002 11.002 0 00-2.482-1.908C16.944.997 15.098.093 12.477.032c-.734-.017-1.457.03-2.174.144-.72.114-1.398.292-2.118.56-1.017.377-1.996.975-2.574 1.554.583-.349 1.476-.733 2.55-.992a10.083 10.083 0 013.729-.167c2.341.34 4.178 1.381 5.48 2.625a8.066 8.066 0 011.298 1.587c1.468 2.382 1.33 5.376.184 7.142-.85 1.312-2.67 2.544-4.37 2.53-.583-.023-1.438-.152-2.25-.566-2.629-1.343-3.021-4.688-1.118-6.306-.632-.136-1.82.13-2.646 1.363-.742 1.107-.7 2.816-.242 4.028a6.473 6.473 0 01-.59-1.895 7.695 7.695 0 01.416-3.845A8.212 8.212 0 019.45 5.399c.896-1.069 1.908-1.72 2.75-2.005-.54-.471-1.411-.738-2.421-.767C8.31 2.583 6.327 3.061 4.7 4.41a8.148 8.148 0 00-1.976 2.414c-.455.836-.691 1.659-.697 1.678.122-1.445.704-2.994 1.248-4.055-.79.413-1.827 1.668-2.41 3.042C.095 9.37-.2 11.608.14 13.989c.966 5.668 5.9 9.982 11.843 9.982C18.62 23.971 24 18.591 24 11.956a11.93 11.93 0 00-3.548-8.511z"
    }
    
    if ($simpleIcons.ContainsKey($IconName)) {
        return $simpleIcons[$IconName]
    }
    
    return $null
}

function Get-LucideIconPath {
    <#
    .SYNOPSIS
        Returns SVG path data for Lucide icons.
    #>
    param([string]$IconName)
    
    $iconPaths = @{
        # Category Icons - Official Lucide Paths
        "Settings2" = "M14 17H5 M19 7h-9"
        "Network" = "M5 16v-3a1 1 0 0 1 1-1h12a1 1 0 0 1 1 1v3 M12 12V8"
        "Globe" = "M12 2a14.5 14.5 0 0 0 0 20 14.5 14.5 0 0 0 0-20 M2 12h20"
        "ShieldCheck" = "M20 13c0 5-3.5 7.5-7.66 8.95a1 1 0 0 1-.67-.01C7.5 20.5 4 18 4 13V6a1 1 0 0 1 1-1c2 0 4.5-1.2 6.24-2.72a1.17 1.17 0 0 1 1.52 0C14.51 3.81 17 5 19 5a1 1 0 0 1 1 1z m9 12 2 2 4-4"
        "LifeBuoy" = "m4.93 4.93 4.24 4.24 m14.83 9.17 4.24-4.24 m14.83 14.83 4.24 4.24 m9.17 14.83-4.24 4.24"
        "Cloud" = "M17.5 19H9a7 7 0 1 1 6.71-9h1.79a4.5 4.5 0 1 1 0 9Z"
        "Cpu" = "M12 20v2 M12 2v2 M17 20v2 M17 2v2 M2 12h2 M2 17h2 M2 7h2 M20 12h2 M20 17h2 M20 7h2 M7 20v2 M7 2v2"
        
        # Tool Icons - Official Lucide Paths
        "DownloadCloud" = "M4 14.899A7 7 0 1 1 15.71 8h1.79a4.5 4.5 0 0 1 2.5 8.242M12 12v9M8 17l4 4 4-4"
        "BatteryMedium" = "M10 14v-4 M22 14v-4 M6 14v-4"
        "Lock" = "M7 11V7a5 5 0 0 1 10 0v4"
        "FileSearch" = "M6 22a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h8a2.4 2.4 0 0 1 1.704.706l3.588 3.588A2.4 2.4 0 0 1 20 8v12a2 2 0 0 1-2 2z M14 2v5a1 1 0 0 0 1 1h5 M13.3 16.3 15 18"
        "Wifi" = "M12 20h.01 M2 8.82a15 15 0 0 1 20 0 M5 12.859a10 10 0 0 1 14 0 M8.5 16.429a5 5 0 0 1 7 0"
        "Printer" = "M6 18H4a2 2 0 0 1-2-2v-5a2 2 0 0 1 2-2h16a2 2 0 0 1 2 2v5a2 2 0 0 1-2 2h-2 M6 9V3a1 1 0 0 1 1-1h10a1 1 0 0 1 1 1v6"
        "FileText" = "M6 22a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h8a2.4 2.4 0 0 1 1.704.706l3.588 3.588A2.4 2.4 0 0 1 20 8v12a2 2 0 0 1-2 2z M14 2v5a1 1 0 0 0 1 1h5 M10 9H8 M16 13H8 M16 17H8"
        "AlertTriangle" = "M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0zM12 9v4M12 17h.01"
        "Wrench" = "M14.7 6.3a1 1 0 0 0 0 1.4l1.6 1.6a1 1 0 0 0 1.4 0l3.106-3.105c.32-.322.863-.22.983.218a6 6 0 0 1-8.259 7.057l-7.91 7.91a1 1 0 0 1-2.999-3l7.91-7.91a6 6 0 0 1 7.057-8.259c.438.12.54.662.219.984z"
        "Mail" = "m22 7-8.991 5.727a2 2 0 0 1-2.009 0L2 7"
        "HelpCircle" = "M9.09 9a3 3 0 0 1 5.83 1c0 2-3 3-3 3M12 17h.01M22 12a10 10 0 1 1-20 0 10 10 0 0 1 20 0z"
        "Monitor" = "M20 3H4a2 2 0 0 0-2 2v11a2 2 0 0 0 2 2h3l-1 5v1h12v-1l-1-5h3a2 2 0 0 0 2-2V5a2 2 0 0 0-2-2z"
        "Users" = "M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2 M16 3.128a4 4 0 0 1 0 7.744 M22 21v-2a4 4 0 0 0-3-3.87"
        "License" = "m15.477 12.89 1.515 8.526a.5.5 0 0 1-.81.47l-3.58-2.687a1 1 0 0 0-1.197 0l-3.586 2.686a.5.5 0 0 1-.81-.469l1.514-8.526"
        "Share2" = "M18 8a3 3 0 1 0 0-6 3 3 0 0 0 0 6zM6 15a3 3 0 1 0 0-6 3 3 0 0 0 0 6zM13 8a3 3 0 1 1-6 0 3 3 0 0 1 6 0zM6 15a3 3 0 1 1 6 0 3 3 0 0 1-6 0z"
        "HardDrive" = "M5.45 5.11 2 12v6a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2v-6l-3.45-6.89A2 2 0 0 0 16.76 4H7.24a2 2 0 0 0-1.79 1.11z"
        "Activity" = "M22 12h-2.48a2 2 0 0 0-1.93 1.46l-2.35 8.36a.25.25 0 0 1-.48 0L9.24 2.18a.25.25 0 0 0-.48 0l-2.35 8.36A2 2 0 0 1 4.49 12H2"
        "Key" = "m15.5 7.5 2.3 2.3a1 1 0 0 0 1.4 0l2.1-2.1a1 1 0 0 0 0-1.4L19 4 m21 2-9.6 9.6"
        "RefreshCw" = "M3 12a9 9 0 0 1 9-9 9.75 9.75 0 0 1 6.74 2.74L21 8 M21 3v5h-5 M21 12a9 9 0 0 1-9 9 9.75 9.75 0 0 1-6.74-2.74L3 16 M8 16H3v5"
        "Zap" = "M4 14a1 1 0 0 1-.78-1.63l9.9-10.2a.5.5 0 0 1 .86.46l-1.92 6.02A1 1 0 0 0 13 10h7a1 1 0 0 1 .78 1.63l-9.9 10.2a.5.5 0 0 1-.86-.46l1.92-6.02A1 1 0 0 0 11 14z"
        "Trash2" = "M10 11v6 M14 11v6 M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6 M3 6h18 M8 6V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"
        "XCircle" = "M22 12a10 10 0 1 1-20 0 10 10 0 0 1 20 0zM12 8v4M12 16h.01"
        "Update" = "m21 16-4 4-4-4 M17 20V4 m3 8 4-4 4 4 M7 4v16"
        "Dns" = "M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zM7.07 18.28c.43-.9 3.05-1.78 4.93-1.78s4.51.88 4.93 1.78C15.57 19.36 13.86 20 12 20s-3.57-.64-4.93-1.72zm11.29-1.45c-1.43-1.74-4.9-2.33-6.36-2.33s-4.93.59-6.36 2.33C4.62 15.49 4 13.82 4 12c0-4.41 3.59-8 8-8s8 3.59 8 8c0 1.82-.62 3.49-1.64 4.83zM12 6c-1.94 0-3.5 1.56-3.5 3.5S10.06 13 12 13s3.5-1.56 3.5-3.5S13.94 6 12 6zm0 5c-.83 0-1.5-.67-1.5-1.5S11.17 8 12 8s1.5.67 1.5 1.5S12.83 11 12 11z"
        "Shield" = "M20 13c0 5-3.5 7.5-7.66 8.95a1 1 0 0 1-.67-.01C7.5 20.5 4 18 4 13V6a1 1 0 0 1 1-1c2 0 4.5-1.2 6.24-2.72a1.17 1.17 0 0 1 1.52 0C14.51 3.81 17 5 19 5a1 1 0 0 1 1 1z"
        "Search" = "m21 21-4.34-4.34"
        "CloudCheck" = "m17 15-5.5 5.5L9 18 M5 17.743A7 7 0 1 1 15.71 10h1.79a4.5 4.5 0 0 1 1.5 8.742"
        "Package" = "M11 21.73a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16V8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73z M12 22V12 m7.5 4.27 9 5.15"
        "Gauge" = "m12 14 4-4 M3.34 19a10 10 0 1 1 17.32 0"
        "HardDriveIcon" = "M5.45 5.11 2 12v6a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2v-6l-3.45-6.89A2 2 0 0 0 16.76 4H7.24a2 2 0 0 0-1.79 1.11z"
        "Database" = "M3 5V19A9 3 0 0 0 21 19V5 M3 12A9 3 0 0 0 21 12"
        "Calendar" = "M8 2v4 M16 2v4 M3 10h18"
        "CheckCircle2" = "M22 12a10 10 0 1 1-20 0 10 10 0 0 1 20 0zM12 8v4M12 16h.01"
        "Info" = "M12 16v-4 M12 8h.01"
        "Code" = "m16 18 6-6-6-6 m8 6-6 6 6 6"
        "MessageCircle" = "M2.992 16.342a2 2 0 0 1 .094 1.167l-1.065 3.29a1 1 0 0 0 1.236 1.168l3.413-.998a2 2 0 0 1 1.099.092 10 10 0 1 0-4.777-4.719"
    }
    
    if ($iconPaths.ContainsKey($IconName)) {
        return $iconPaths[$IconName]
    }
    
    # Default fallback icon (circle)
    return "M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm0 18c-4.41 0-8-3.59-8-8s3.59-8 8-8 8 3.59 8 8-3.59 8-8 8z"
}

function New-IconPath {
    <#
    .SYNOPSIS
        Creates a WPF Path element from an icon name (supports both Lucide and Simple Icons).
    .PARAMETER IconName
        Name of the icon (e.g., "Settings2", "Network", "GitHub", "Discord")
    .PARAMETER Size
        Size of the icon in pixels (default: 24)
    .PARAMETER Color
        Color of the icon (hex format, e.g., "#E5E7EB")
    .PARAMETER StrokeWidth
        Stroke width (default: 1.5, ignored for Simple Icons which use fill)
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$IconName,
        [Parameter(Mandatory=$false)]
        [double]$Size = 24,
        [Parameter(Mandatory=$false)]
        [string]$Color = "#E5E7EB",
        [Parameter(Mandatory=$false)]
        [double]$StrokeWidth = 1.5
    )
    
    # Try Simple Icons first (for brand logos)
    $pathData = Get-SimpleIconPath -IconName $IconName
    $isSimpleIcon = $null -ne $pathData
    
    # If not found, try Lucide icons
    if (-not $isSimpleIcon) {
        $pathData = Get-LucideIconPath -IconName $IconName
    }
    
    # Create Path element
    $path = New-Object System.Windows.Shapes.Path
    $path.Width = $Size
    $path.Height = $Size
    $path.ClipToBounds = $true
    $path.Stretch = "Uniform"
    
    if ($isSimpleIcon) {
        # Simple Icons use fill (brand logos are solid shapes)
        $path.Fill = [System.Windows.Media.BrushConverter]::new().ConvertFromString($Color)
        $path.Stroke = [System.Windows.Media.Brushes]::Transparent
        $path.StrokeThickness = 0
    }
    else {
        # Lucide icons use stroke (outline icons)
        $path.Stroke = [System.Windows.Media.BrushConverter]::new().ConvertFromString($Color)
        $path.Fill = [System.Windows.Media.Brushes]::Transparent
        $path.StrokeThickness = $StrokeWidth
    }
    
    # Convert SVG path string to WPF Geometry
    try {
        $geometry = [System.Windows.Media.Geometry]::Parse($pathData)
        $path.Data = $geometry
    }
    catch {
        Write-Warning "Failed to parse path data for icon '$IconName': $_"
        # Use a simple circle as fallback
        $path.Data = [System.Windows.Media.Geometry]::Parse("M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2z")
    }
    
    return $path
}

# Alias for backward compatibility
function New-LucideIconPath {
    param(
        [Parameter(Mandatory=$true)]
        [string]$IconName,
        [Parameter(Mandatory=$false)]
        [double]$Size = 24,
        [Parameter(Mandatory=$false)]
        [string]$Color = "#E5E7EB",
        [Parameter(Mandatory=$false)]
        [double]$StrokeWidth = 1.5
    )
    return New-IconPath -IconName $IconName -Size $Size -Color $Color -StrokeWidth $StrokeWidth
}

# ============================================================
# EXECUTION POLICY CHECK
# ============================================================

# Check and set execution policy for current session
$currentPolicy = Get-ExecutionPolicy
if ($currentPolicy -eq "Restricted" -or $currentPolicy -eq "AllSigned") {
    try {
        Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process -Force
        Write-Host "Execution policy temporarily set to RemoteSigned for this session." -ForegroundColor Green
    }
    catch {
        Write-Host "Warning: Could not modify execution policy. Some features may not work properly." -ForegroundColor Yellow
        Write-Host "Error: $_" -ForegroundColor Red
    }
}

# Check if running as administrator, relaunch if not
if (-not (Test-Administrator)) {
    Write-Host "Relaunching as Administrator..." -ForegroundColor Yellow

    try {
        # Get the current script path
        $scriptPath = $MyInvocation.MyCommand.Path

        # Relaunch with admin privileges
        Start-Process -FilePath "powershell.exe" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`"" -Verb RunAs

        # Exit the current non-admin instance
        exit
    }
    catch {
        Write-Host "Failed to relaunch as Administrator. Error: $_" -ForegroundColor Red
        Write-Host "Please run this script as Administrator manually." -ForegroundColor Yellow
        Read-Host "Press Enter to exit"
        exit 1
    }
}

Write-Host "Running as Administrator." -ForegroundColor Green

# ============================================================
# GLOBAL VARIABLES
# ============================================================
$Script:ScriptPath = Join-Path $Script:RootPath "scripts"
$Script:AssetsPath = Join-Path $Script:RootPath "assets"
$Script:CurrentVersion = "2.8.0"
$Script:CurrentCategory = "All"

# Tool definitions
$Script:Tools = @(
    @{
        Name = "1-Click PC Install"
        Icon = "Settings2"
        Description = "Automated PC setup - timezone, updates, software install"
        Script = "1-click_pc_install.ps1"
        Category = "Setup"
        Tags = @("setup", "install", "automation", "configure", "timezone", "regional", "updates", "power", "bloatware", "chrome", "anydesk", "office", "winget", "restore point")
        Color = "#10b981"
    },
    @{
        Name = "Essential Tweaks"
        Icon = "Wrench"
        Description = "Windows tweaks - default apps, keyboard, language, taskbar"
        Script = "essential_tweaks.ps1"
        Category = "Setup"
        Tags = @("tweaks", "settings", "default", "browser", "keyboard", "language", "taskbar", "chrome", "hebrew", "copilot", "acrobat", "pdf")
        Color = "#10b981"
    },
    @{
        Name = "Battery Report Generator"
        Icon = "BatteryMedium"
        Description = "Generate battery health reports for laptops"
        Script = "battery_report_generator.ps1"
        Category = "Hardware"
        Tags = @("battery", "laptop", "health", "report", "power")
        Color = "#3498db"
    },
    @{
        Name = "BitLocker Status Report"
        Icon = "Lock"
        Description = "Check BitLocker encryption status and recovery keys"
        Script = "bitlocker_status_report.ps1"
        Category = "Security"
        Tags = @("bitlocker", "encryption", "security", "recovery", "volume")
        Color = "#dc2626"
    },
    @{
        Name = "PST Finder"
        Icon = "FileSearch"
        Description = "Locate and analyze Outlook PST files across the system"
        Script = "FindPST.ps1"
        Category = "M365"
        Tags = @("outlook", "pst", "email", "microsoft", "office", "365", "backup")
        Color = "#d97706"
    },
    @{
        Name = "License Expiration Checker"
        Icon = "License"
        Description = "Monitor M365 license subscriptions and expiration alerts"
        Script = "license_expiration_checker.ps1"
        Category = "M365"
        Tags = @("license", "microsoft", "365", "m365", "subscription", "expiration", "monitoring", "alerts")
        Color = "#f59e0b"
    },
    @{
        Name = "M365 User List"
        Icon = "Users"
        Description = "List M365 users - email, phone, MFA status, user info"
        Script = "m365_user_list.ps1"
        Category = "M365"
        Tags = @("users", "microsoft", "365", "m365", "email", "phone", "mfa", "directory", "audit", "inventory")
        Color = "#3b82f6"
    },
    @{
        Name = "SharePoint Site Inventory"
        Icon = "Database"
        Description = "Map SharePoint sites - URLs, storage, owners, activity"
        Script = "sharepoint_site_inventory.ps1"
        Category = "M365"
        Tags = @("sharepoint", "sites", "microsoft", "365", "m365", "inventory", "audit", "storage", "owners", "groups", "template")
        Color = "#8b5cf6"
    },
    @{
        Name = "Exchange Online"
        Icon = "Mail"
        Description = "Collect Exchange mailbox info - aliases, protocols, activity"
        Script = "m365_exchange_online.ps1"
        Category = "M365"
        Tags = @("exchange", "online", "mailbox", "microsoft", "365", "m365", "email", "protocols", "imap", "pop", "ews", "activesync", "smtp", "mapi", "aliases", "license", "activity", "logon", "access", "size", "sendonbehalf")
        Color = "#8b5cf6"
    },
    @{
        Name = "Printer Spooler Fix"
        Icon = "Printer"
        Description = "Comprehensive printer spooler troubleshooting and repair"
        Script = "printer_spooler_fix.ps1"
        Category = "Support"
        Tags = @("printer", "spooler", "print", "troubleshoot", "fix", "repair")
        Color = "#e74c3c"
    },
    @{
        Name = "WiFi Password Viewer"
        Icon = "Key"
        Description = "View and export saved WiFi passwords from Windows"
        Script = "wifi_password_viewer.ps1"
        Category = "Network"
        Tags = @("wifi", "password", "network", "wireless", "credentials")
        Color = "#1abc9c"
    },
    @{
        Name = "WiFi Monitor"
        Icon = "Wifi"
        Description = "Monitor WiFi signal strength, frequency bands, disconnections"
        Script = "wifi_monitor.ps1"
        Category = "Network"
        Tags = @("wifi", "monitor", "signal", "strength", "rssi", "2.4ghz", "5ghz", "frequency", "band", "ssid", "disconnection", "history", "network", "wireless", "troubleshoot")
        Color = "#1abc9c"
    },
    @{
        Name = "Event Log Analyzer"
        Icon = "FileText"
        Description = "Analyze Windows Event Logs with statistical summaries"
        Script = "EventLogAnalyzer.ps1"
        Category = "Support"
        Tags = @("event", "log", "analyzer", "diagnostics", "windows", "troubleshoot")
        Color = "#f39c12"
    },
    @{
        Name = "BSOD History Scanner"
        Icon = "AlertTriangle"
        Description = "Scan minidump files and logs for BSOD history and codes"
        Script = "bsod_history_scanner.ps1"
        Category = "Support"
        Tags = @("bsod", "blue screen", "minidump", "bugcheck", "crash", "diagnostics", "troubleshoot", "error")
        Color = "#f39c12"
    },
    @{
        Name = "Network Test Tool"
        Icon = "Wifi"
        Description = "Network diagnostics - ping, tracert, DNS lookup, latency"
        Script = "network_test_tool.ps1"
        Category = "Network"
        Tags = @("network", "ping", "tracert", "dns", "latency", "diagnostics")
        Color = "#3b82f6"
    },
    @{
        Name = "Network Configuration Tool"
        Icon = "Network"
        Description = "Configure IP settings, flush DNS, reset network adapters"
        Script = "network_configuration_tool.ps1"
        Category = "Network"
        Tags = @("network", "ip", "configuration", "static", "dns", "adapter", "reset", "dhcp")
        Color = "#5B2EFF"
    },
    @{
        Name = "USB Device Log"
        Icon = "Database"
        Description = "Forensic USB device history analysis for security audits"
        Script = "usb_device_log.ps1"
        Category = "Security"
        Tags = @("usb", "forensics", "security", "audit", "device", "history")
        Color = "#ef4444"
    },
    @{
        Name = "Local Admin Users Checker"
        Icon = "Shield"
        Description = "Identify unnecessary admin accounts and security risks"
        Script = "local_admin_checker.ps1"
        Category = "Security"
        Tags = @("admin", "administrator", "security", "privileges", "users", "attack vector", "audit", "permissions")
        Color = "#ef4444"
    },
    @{
        Name = "Product Key Retriever"
        Icon = "Key"
        Description = "Retrieve Windows and Office product keys from system"
        Script = "product_key_retriever.ps1"
        Category = "Support"
        Tags = @("product key", "windows", "office", "license", "activation", "registry", "wmi", "backup", "recovery")
        Color = "#10b981"
    },
    @{
        Name = "Softwares Installer"
        Icon = "Package"
        Description = "Install essential business apps via WinGet"
        Script = "SouliTEK-Softwares-Installer.ps1"
        Category = "Setup"
        Tags = @("winget", "installer", "software", "packages", "apps", "install", "microsoft", "package manager")
        Color = "#10b981"
    },
    @{
        Name = "Storage Health Monitor"
        Icon = "HardDrive"
        Description = "Monitor storage health with SMART data and error detection"
        Script = "storage_health_monitor.ps1"
        Category = "Hardware"
        Tags = @("storage", "smart", "disk", "health", "monitor", "hdd", "ssd", "sectors", "errors")
        Color = "#06b6d4"
    },
    @{
        Name = "System Restore Point"
        Icon = "RefreshCw"
        Description = "Create Windows System Restore Points for recovery"
        Script = "create_system_restore_point.ps1"
        Category = "Support"
        Tags = @("restore", "system", "recovery", "backup", "rollback", "protection")
        Color = "#f59e0b"
    },
    @{
        Name = "RAM Slot Utilization Report"
        Icon = "Cpu"
        Description = "Show RAM slots, type (DDR3/4/5), speed, and capacity"
        Script = "ram_slot_utilization_report.ps1"
        Category = "Hardware"
        Tags = @("ram", "memory", "hardware", "ddr", "slots", "capacity", "speed")
        Color = "#3498db"
    },
    @{
        Name = "Disk Usage Analyzer"
        Icon = "HardDrive"
        Description = "Find large folders and export size reports with HTML"
        Script = "disk_usage_analyzer.ps1"
        Category = "Hardware"
        Tags = @("disk", "usage", "storage", "folders", "size", "cleanup", "analysis")
        Color = "#06b6d4"
    },
    @{
        Name = "Startup & Boot Time Analyzer"
        Icon = "Gauge"
        Description = "Analyze startup programs and boot performance with reports"
        Script = "startup_boot_analyzer.ps1"
        Category = "Performance"
        Tags = @("startup", "boot", "performance", "optimization", "services", "task scheduler", "analysis", "speed")
        Color = "#f59e0b"
    },
    @{
        Name = "Temp Removal & Disk Cleanup"
        Icon = "Trash2"
        Description = "Remove temp files, clean cache, empty Recycle Bin"
        Script = "temp_removal_disk_cleanup.ps1"
        Category = "Support"
        Tags = @("temp", "cleanup", "disk", "space", "browser", "cache", "recycle", "bin", "maintenance")
        Color = "#10b981"
    },
    @{
        Name = "McAfee Removal Tool"
        Icon = "McAfee"
        Description = "Complete removal of McAfee products using MCPR tool"
        Script = "mcafee_removal_tool.ps1"
        Category = "Support"
        Tags = @("mcafee", "removal", "mcpr", "antivirus", "uninstall", "cleanup", "security", "removal tool")
        Color = "#ef4444"
    },
    @{
        Name = "Win11Debloat"
        Icon = "Settings2"
        Description = "Remove bloatware, disable telemetry, optimize Windows 10/11"
        Script = "win11_debloat.ps1"
        Category = "Setup"
        Tags = @("debloat", "bloatware", "telemetry", "optimization", "windows", "privacy", "cleanup", "registry", "win11", "win10")
        Color = "#8b5cf6"
    },
    @{
        Name = "Software Updater"
        Icon = "Update"
        Description = "Manage software updates via WinGet - check, auto-update"
        Script = "software_updater.ps1"
        Category = "Setup"
        Tags = @("winget", "update", "software", "upgrade", "maintenance", "packages", "automatic", "interactive")
        Color = "#10b981"
    },
    @{
        Name = "Domain & DNS Analyzer"
        Icon = "Dns"
        Description = "WHOIS lookup, DNS analysis, email security (SPF/DKIM/DMARC)"
        Script = "domain_dns_analyzer.ps1"
        Category = "Internet"
        Tags = @("dns", "whois", "domain", "spf", "dkim", "dmarc", "email", "security", "mx", "records", "rdap")
        Color = "#0ea5e9"
    },
    @{
        Name = "VirusTotal Checker"
        Icon = "VirusTotal"
        Description = "Check files and URLs against VirusTotal for malware"
        Script = "virustotal_checker.ps1"
        Category = "Security"
        Tags = @("virustotal", "malware", "virus", "scan", "hash", "url", "security", "threat", "detection", "file check")
        Color = "#ef4444"
    },
    @{
        Name = "Browser Plugin Checker"
        Icon = "Firefox"
        Description = "Scan browser extensions for security risks"
        Script = "browser_plugin_checker.ps1"
        Category = "Security"
        Tags = @("browser", "extension", "plugin", "addon", "chrome", "firefox", "edge", "security", "permissions", "malware")
        Color = "#ef4444"
    },
    @{
        Name = "OneDrive Status Checker"
        Icon = "CloudCheck"
        Description = "Check OneDrive sync status and detect errors"
        Script = "onedrive_status_checker.ps1"
        Category = "Support"
        Tags = @("onedrive", "sync", "cloud", "backup", "microsoft", "status", "error", "troubleshoot", "files", "upload", "download")
        Color = "#0078d4"
    }
)

# ============================================================
# HELPER FUNCTIONS
# ============================================================


function Get-ThemePreference {
    <#
    .SYNOPSIS
        Gets the user's theme preference from config file.
    #>
    
    $configPath = Join-Path $env:APPDATA "SouliTEK\theme-config.json"
    
    if (-not (Test-Path $configPath)) {
        return "Light"
    }
    
    try {
        $config = Get-Content $configPath -Raw | ConvertFrom-Json
        if ($config.theme -in @("Light", "Dark")) {
            return $config.theme
        }
    }
    catch {
        Write-Warning "Failed to read theme preference: $_"
    }
    
    return "Light"
}

function Set-ThemePreference {
    <#
    .SYNOPSIS
        Saves the user's theme preference to config file.
    #>
    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet('Light','Dark')]
        [string]$Theme
    )
    
    $configDir = Join-Path $env:APPDATA "SouliTEK"
    $configPath = Join-Path $configDir "theme-config.json"
    
    if (-not (Test-Path $configDir)) {
        New-Item -ItemType Directory -Path $configDir -Force | Out-Null
    }
    
    $config = @{
        theme = $Theme
        lastUpdated = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    }
    
    try {
        $config | ConvertTo-Json | Set-Content $configPath -Force
    }
    catch {
        Write-Warning "Failed to save theme preference: $_"
    }
}

function Apply-Theme {
    <#
    .SYNOPSIS
        Applies the specified theme to the window (basic WPF theme switching).
    #>
    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet('Light','Dark')]
        [string]$Theme,
        
        [Parameter(Mandatory=$false)]
        [switch]$Silent
    )
    
    if ($null -eq $Script:Window) {
        Write-Warning "Window not initialized"
        return
    }
    
    try {
        # Update window background based on theme
        if ($Theme -eq "Dark") {
            # Dark Navy / Near-Black: #0B0F1A
            $darkBrush = [System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.Color]::FromRgb(11, 15, 26))
            $Script:Window.Background = $darkBrush
        }
        else {
            $lightBrush = [System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.Color]::FromRgb(248, 250, 252))
            $Script:Window.Background = $lightBrush
        }
        
        # Update theme icon if available (using TextBlock with Segoe MDL2 Assets)
        if ($null -ne $Script:ThemeIcon) {
            try {
                # Use Segoe MDL2 Assets Unicode characters
                # U+E706 = Sun icon, U+E708 = Moon icon
                $moonChar = [char]0xE708
                $sunChar = [char]0xE706
                $Script:ThemeIcon.Text = if ($Theme -eq "Dark") { 
                    $sunChar  # Sun icon for dark theme (click to switch to light)
                } else { 
                    $moonChar  # Moon icon for light theme (click to switch to dark)
                }
            }
            catch {
                Write-Warning "Failed to update theme icon: $_"
            }
        }
        
        # Save preference
        Set-ThemePreference -Theme $Theme
        
        # Refresh tool display to update icon colors
        if ($null -ne $Script:ToolsPanel) {
            Update-ToolsDisplay
        }
        
        # Refresh category buttons to update icon colors
        if ($null -ne $Script:CurrentCategory) {
            Set-CategoryActive -CategoryName $Script:CurrentCategory
        }
        
        if (-not $Silent) {
            Write-Host "Theme switched to $Theme" -ForegroundColor Green
        }
    }
    catch {
        Write-Warning "Failed to apply theme: $_"
    }
}

function Start-Tool {
    param(
        [string]$ScriptName,
        [string]$ToolName
    )
    
    $scriptPath = Join-Path $Script:ScriptPath $ScriptName
    
    if (-not (Test-Path $scriptPath)) {
        Write-Warning "Script not found: $ScriptName"
        return
    }
    
    try {
        $psPath = "powershell.exe"
        $arguments = "-NoExit -NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""
        Start-Process -FilePath $psPath -ArgumentList $arguments
        
        $Script:StatusLabel.Text = "Launched: $ToolName"
        $Script:StatusLabel.Foreground = "#5B2EFF"
        Write-Host "Launched: $ToolName" -ForegroundColor Green
    }
    catch {
        Write-Warning "Failed to launch $ToolName`: $_"
        $Script:StatusLabel.Text = "Error launching tool"
        $Script:StatusLabel.Foreground = "#DC2626"
    }
}

function Test-ToolMatchesFilter {
    param($Tool)
    
    # Check category filter
    if ($Script:CurrentCategory -ne "All" -and $Tool.Category -ne $Script:CurrentCategory) {
        return $false
    }
    
    # Check search text filter
    $searchText = $Script:SearchBox.Text
    if (-not [string]::IsNullOrWhiteSpace($searchText)) {
        $searchLower = $searchText.ToLower()
        $nameMatch = $Tool.Name.ToLower().Contains($searchLower)
        $descMatch = $Tool.Description.ToLower().Contains($searchLower)
        $categoryMatch = $Tool.Category.ToLower().Contains($searchLower)
        $tagsMatch = ($Tool.Tags | Where-Object { $_.ToLower().Contains($searchLower) }).Count -gt 0
        
        if (-not ($nameMatch -or $descMatch -or $categoryMatch -or $tagsMatch)) {
            return $false
        }
    }
    
    return $true
}

function Update-ToolsDisplay {
    $null = $Script:ToolsPanel.Children.Clear()
    
    $filteredTools = $Script:Tools | Where-Object { Test-ToolMatchesFilter $_ }
    
    if ($filteredTools.Count -eq 0) {
        $noResults = New-Object System.Windows.Controls.TextBlock
        $noResults.Text = "No tools match your search criteria"
        $noResults.FontSize = 14
        $noResults.FontFamily = "Segoe UI"
        $noResults.Foreground = "#8A8F98"
        $noResults.Margin = "0,50,0,20"
        $noResults.TextAlignment = "Center"
        $noResults.HorizontalAlignment = "Center"
        $null = $Script:ToolsPanel.Children.Add($noResults)
        
        $Script:StatusLabel.Text = "No tools found - try a different search or category"
        return
    }
    
    $Script:StatusLabel.Text = "Showing $($filteredTools.Count) tool(s) in '$Script:CurrentCategory' category"
    
    foreach ($tool in $filteredTools) {
        # Create side-by-side tool card with fixed width (3 cards per row)
        $card = New-Object System.Windows.Controls.Border
        $card.Style = $Script:Window.FindResource("ToolCard")
        $card.Cursor = "Hand"
        $card.Width = 300
        $card.Margin = "0,0,12,12"
        
        # Info stack with title and description
        $infoStack = New-Object System.Windows.Controls.StackPanel
        $infoStack.Orientation = "Vertical"
        
        # Header with icon and name
        $headerStack = New-Object System.Windows.Controls.StackPanel
        $headerStack.Orientation = "Horizontal"
        $headerStack.Margin = "0,0,0,4"
        
        # Set icon color to black for tool cards
        $iconColor = "#000000"
        
        # Add icon if tool has one
        if ($tool.Icon -and $tool.Icon -notmatch "^\[.*\]$") {
            try {
                $icon = New-IconPath -IconName $tool.Icon -Size 24 -Color $iconColor -StrokeWidth 1.5
                $icon.Margin = "0,0,8,0"
                $icon.VerticalAlignment = "Center"
                $null = $headerStack.Children.Add($icon)
            }
            catch {
                Write-Warning "Failed to create icon for tool '$($tool.Name)': $_"
            }
        }
        
        $nameText = New-Object System.Windows.Controls.TextBlock
        $nameText.Text = $tool.Name
        $nameText.FontSize = 16
        $nameText.FontWeight = "SemiBold"
        $nameText.FontFamily = "Segoe UI"
        $nameText.Foreground = "#0B0F1A"
        $nameText.VerticalAlignment = "Center"
        $nameText.TextWrapping = "Wrap"
        
        $null = $headerStack.Children.Add($nameText)
        
        # Truncate description to ~60 characters for side-by-side layout
        $descText = New-Object System.Windows.Controls.TextBlock
        $truncatedDesc = if ($tool.Description.Length -gt 60) {
            $tool.Description.Substring(0, 57) + "..."
        } else {
            $tool.Description
        }
        $descText.Text = $truncatedDesc
        $descText.FontSize = 13
        $descText.FontFamily = "Segoe UI"
        $descText.Foreground = "#8A8F98"
        $descText.TextWrapping = "Wrap"
        
        $null = $infoStack.Children.Add($headerStack)
        $null = $infoStack.Children.Add($descText)
        
        $card.Child = $infoStack
        
        # Make entire card clickable
        $card.Tag = @{
            Script = $tool.Script
            Name = $tool.Name
        }
        
        $null = $card.Add_MouseLeftButtonUp({
            $toolInfo = $this.Tag
            Start-Tool -ScriptName $toolInfo.Script -ToolName $toolInfo.Name
        })
        
        $null = $Script:ToolsPanel.Children.Add($card)
    }
}

function Set-CategoryButtonIcon {
    <#
    .SYNOPSIS
        Sets or updates the icon for a category button.
    #>
    param(
        [System.Windows.Controls.Button]$Button,
        [string]$IconName,
        [bool]$IsActive
    )
    
    # Remove existing icon if present
    if ($Button.Content -is [System.Windows.Controls.StackPanel]) {
        $Button.Content = $Button.Content.Children[1].Text
    }
    
    # Get icon color based on active state (always white for category buttons)
    $iconColor = "White"
    
    # Create icon
    $icon = New-IconPath -IconName $IconName -Size 18 -Color $iconColor -StrokeWidth 2
    
    # Create stack panel with icon and text
    $stackPanel = New-Object System.Windows.Controls.StackPanel
    $stackPanel.Orientation = "Horizontal"
    $stackPanel.HorizontalAlignment = "Center"
    $stackPanel.VerticalAlignment = "Center"
    
    # Add icon with margin
    $icon.Margin = "0,0,6,0"
    $null = $stackPanel.Children.Add($icon)
    
    # Get text from button
    $textBlock = New-Object System.Windows.Controls.TextBlock
    $textBlock.Text = $Button.Content
    $textBlock.FontSize = 14
    $textBlock.FontFamily = "Segoe UI"
    $textBlock.FontWeight = if ($IsActive) { "SemiBold" } else { "Medium" }
    $textBlock.Foreground = "White"
    $textBlock.VerticalAlignment = "Center"
    
    $null = $stackPanel.Children.Add($textBlock)
    
    # Set button content
    $Button.Content = $stackPanel
}

function Set-FooterButtonIcon {
    <#
    .SYNOPSIS
        Sets or updates the icon for a footer button.
    #>
    param(
        [System.Windows.Controls.Button]$Button,
        [string]$IconName,
        [string]$TextColor = "White"
    )
    
    # Extract text from button content (could be string or TextBlock)
    $buttonText = ""
    if ($Button.Content -is [string]) {
        $buttonText = $Button.Content
    }
    elseif ($Button.Content -is [System.Windows.Controls.TextBlock]) {
        $buttonText = $Button.Content.Text
    }
    elseif ($Button.Content -is [System.Windows.Controls.StackPanel]) {
        $textBlock = $Button.Content.Children | Where-Object { $_ -is [System.Windows.Controls.TextBlock] } | Select-Object -First 1
        if ($textBlock) {
            $buttonText = $textBlock.Text
        }
    }
    
    # Create icon - larger size for footer buttons (14px for better visibility)
    $icon = New-IconPath -IconName $IconName -Size 14 -Color $TextColor -StrokeWidth 1.5
    
    # Wrap icon in a container with proper constraints
    $iconContainer = New-Object System.Windows.Controls.Grid
    $iconContainer.Width = 16
    $iconContainer.Height = 16
    $iconContainer.HorizontalAlignment = "Center"
    $iconContainer.VerticalAlignment = "Center"
    $icon.HorizontalAlignment = "Center"
    $icon.VerticalAlignment = "Center"
    $null = $iconContainer.Children.Add($icon)
    
    # Create stack panel with icon and text
    $stackPanel = New-Object System.Windows.Controls.StackPanel
    $stackPanel.Orientation = "Horizontal"
    $stackPanel.HorizontalAlignment = "Center"
    $stackPanel.VerticalAlignment = "Center"
    
    # Add icon container with margin
    $iconContainer.Margin = "0,0,4,0"
    $null = $stackPanel.Children.Add($iconContainer)
    
    # Create text block
    $textBlock = New-Object System.Windows.Controls.TextBlock
    $textBlock.Text = $buttonText
    $textBlock.FontSize = 11
    $textBlock.FontFamily = "Segoe UI"
    $textBlock.Foreground = $TextColor
    $textBlock.VerticalAlignment = "Center"
    
    $null = $stackPanel.Children.Add($textBlock)
    
    # Set button content
    $Button.Content = $stackPanel
}

function Set-CategoryActive {
    param([string]$CategoryName)
    
    $Script:CurrentCategory = $CategoryName
    
    # Category icon mapping
    $categoryIcons = @{
        "All" = $null  # No icon for "All"
        "Setup" = "Settings2"
        "Network" = "Network"
        "Internet" = "Globe"
        "Security" = "ShieldCheck"
        "Support" = "LifeBuoy"
        "M365" = "Cloud"
        "Hardware" = "Cpu"
    }
    
    # Update button styles - use pill button styles
    $categories = @{
        "All" = $Script:BtnCatAll
        "Setup" = $Script:BtnCatSetup
        "Network" = $Script:BtnCatNetwork
        "Internet" = $Script:BtnCatInternet
        "Security" = $Script:BtnCatSecurity
        "Support" = $Script:BtnCatSupport
        "M365" = $Script:BtnCatM365
        "Hardware" = $Script:BtnCatHardware
    }
    
    foreach ($cat in $categories.GetEnumerator()) {
        $isActive = $cat.Key -eq $CategoryName
        
        if ($isActive) {
            # Set active style
            $cat.Value.Style = $Script:Window.FindResource("CategoryButtonActive")
            $cat.Value.Background = "#5B2EFF"
            $cat.Value.Foreground = "White"
        } else {
            # Set inactive style
            $cat.Value.Style = $Script:Window.FindResource("CategoryButtonInactive")
            $cat.Value.Background = "#8A8F98"
            $cat.Value.Foreground = "White"
        }
        
        # Update icon if category has one
        if ($categoryIcons.ContainsKey($cat.Key) -and $null -ne $categoryIcons[$cat.Key]) {
            Set-CategoryButtonIcon -Button $cat.Value -IconName $categoryIcons[$cat.Key] -IsActive $isActive
        }
    }
    
    Update-ToolsDisplay
}

function New-QuickRestorePoint {
    <#
    .SYNOPSIS
        Creates a system restore point quickly from the launcher.
    #>
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $description = "SouliTEK Launcher - $timestamp"
    
    try {
        # Create restore point using Checkpoint-Computer
        # Note: Checkpoint-Computer doesn't return a value, it either succeeds or throws
        Checkpoint-Computer -Description $description -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop
        
        # If we get here, the restore point was created successfully
        return @{
            Success = $true
            Message = "System Restore Point created successfully! Description: $description"
        }
    }
    catch {
        # Try alternative method using vssadmin
        try {
            $vssResult = Start-Process -FilePath "vssadmin" -ArgumentList "create", "shadow", "/For=$env:SystemDrive" -Wait -NoNewWindow -PassThru -ErrorAction Stop
            
            if ($vssResult.ExitCode -eq 0) {
                return @{
                    Success = $true
                    Message = "System Restore Point created successfully via alternative method!`n`nDescription: $description"
                }
            } else {
                return @{
                    Success = $false
                    Message = "Failed to create restore point. Exit Code: $($vssResult.ExitCode)`n`nError: $($_.Exception.Message)"
                }
            }
        }
        catch {
            return @{
                Success = $false
                Message = "Failed to create restore point.`n`nError: $($_.Exception.Message)"
            }
        }
    }
    
    return @{
        Success = $false
        Message = "Unknown error occurred while creating restore point."
    }
}

function Show-RestorePointWarning {
    <#
    .SYNOPSIS
        Shows a warning dialog recommending system restore point creation.
    #>
    
    $warningMessage = @"
IMPORTANT RECOMMENDATION

It is highly recommended to create a System Restore Point before running system modification tools.

This will allow you to restore your system to its current state if anything goes wrong.

Would you like to create a restore point now?
"@
    
    $result = [System.Windows.MessageBox]::Show(
        $warningMessage,
        "System Restore Point Recommended",
        [System.Windows.MessageBoxButton]::YesNoCancel,
        [System.Windows.MessageBoxImage]::Warning
    )
    
    switch ($result) {
        ([System.Windows.MessageBoxResult]::Yes) {
            # Create restore point
            $createResult = New-QuickRestorePoint
            
                if ($createResult.Success) {
                    Write-Host $createResult.Message -ForegroundColor Green
                } else {
                    Write-Warning $createResult.Message
                }
        }
        ([System.Windows.MessageBoxResult]::No) {
            # User chose to skip, continue normally
            return
        }
        ([System.Windows.MessageBoxResult]::Cancel) {
            # User chose to cancel, exit the launcher
            $Script:Window.Close()
            exit 0
        }
    }
}

function Invoke-SelfDestruct {
    <#
    .SYNOPSIS
        Uninstalls SouliTEK by removing installation directory and desktop shortcut.
    #>
    
    $warningMessage = @"
SELF-DESTRUCTION / UNINSTALL

This will permanently remove SouliTEK from this system:

• Remove installation directory: $Script:RootPath
• Remove desktop shortcut: SouliTEK Launcher.lnk
• Close the launcher

This action cannot be undone!

Are you sure you want to uninstall SouliTEK?
"@
    
    $result = [System.Windows.MessageBox]::Show(
        $warningMessage,
        "Uninstall SouliTEK",
        [System.Windows.MessageBoxButton]::YesNo,
        [System.Windows.MessageBoxImage]::Warning
    )
    
    if ($result -ne [System.Windows.MessageBoxResult]::Yes) {
        return
    }
    
    # Confirm again with a second warning
    $confirmMessage = @"
FINAL CONFIRMATION

You are about to permanently delete SouliTEK.

This will remove:
• All scripts and tools
• Installation directory
• Desktop shortcut

Click YES to proceed with uninstallation.
"@
    
    $finalResult = [System.Windows.MessageBox]::Show(
        $confirmMessage,
        "Final Confirmation - Uninstall SouliTEK",
        [System.Windows.MessageBoxButton]::YesNo,
        [System.Windows.MessageBoxImage]::Stop
    )
    
    if ($finalResult -ne [System.Windows.MessageBoxResult]::Yes) {
        return
    }
    
    try {
        $Script:StatusLabel.Text = "Uninstalling SouliTEK..."
        $Script:StatusLabel.Foreground = "#EF4444"
        $Script:Window.UpdateLayout()
        
        $errors = @()
        
        # Remove desktop shortcut
        $desktopPath = [Environment]::GetFolderPath("Desktop")
        $shortcutPath = Join-Path $desktopPath "SouliTEK Launcher.lnk"
        
        if (Test-Path $shortcutPath) {
            try {
                Remove-Item $shortcutPath -Force -ErrorAction Stop
                Write-Host "Desktop shortcut removed: $shortcutPath" -ForegroundColor Green
            }
            catch {
                $errors += "Failed to remove desktop shortcut: $_"
                Write-Warning "Failed to remove desktop shortcut: $_"
            }
        }
        
        # Close the window first to release file locks
        $Script:Window.Close()
        
        # Wait a moment for the window to close
        Start-Sleep -Milliseconds 500
        
        # Remove installation directory
        if (Test-Path $Script:RootPath) {
            try {
                Remove-Item $Script:RootPath -Recurse -Force -ErrorAction Stop
                Write-Host "Installation directory removed: $Script:RootPath" -ForegroundColor Green
            }
            catch {
                $errors += "Failed to remove installation directory: $_"
                Write-Warning "Failed to remove installation directory: $_"
                
                # Show error message (critical - keep MessageBox)
                [System.Windows.MessageBox]::Show(
                    "Uninstallation completed with errors:`n`n$($errors -join "`n")`n`nSome files may still be in use. Please close any PowerShell windows running SouliTEK scripts and try again.",
                    "Uninstallation Warning",
                    [System.Windows.MessageBoxButton]::OK,
                    [System.Windows.MessageBoxImage]::Warning
                )
                return
            }
        }
        
        # Success message (critical - keep MessageBox as window closes)
        [System.Windows.MessageBox]::Show(
            "SouliTEK has been successfully uninstalled from your system.`n`nAll files and shortcuts have been removed.",
            "Uninstallation Complete",
            [System.Windows.MessageBoxButton]::OK,
            [System.Windows.MessageBoxImage]::Information
        )
        
        # Exit PowerShell
        exit 0
    }
    catch {
        $errorMessage = "An error occurred during uninstallation:`n`n$_"
        # Critical error - keep MessageBox
        [System.Windows.MessageBox]::Show(
            $errorMessage,
            "Uninstallation Error",
            [System.Windows.MessageBoxButton]::OK,
            [System.Windows.MessageBoxImage]::Error
        )
        
        $Script:StatusLabel.Text = "Uninstallation failed - see error message"
        $Script:StatusLabel.Foreground = "#DC2626"
    }
}

# ============================================================
# LOAD XAML
# ============================================================

$xamlPath = Join-Path $Script:LauncherPath "MainWindow.xaml"

if (-not (Test-Path $xamlPath)) {
    Write-Host "ERROR: MainWindow.xaml not found at: $xamlPath" -ForegroundColor Red
    Write-Host "Please ensure MainWindow.xaml is in the launcher folder." -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

try {
    [xml]$xaml = Get-Content $xamlPath
    $reader = New-Object System.Xml.XmlNodeReader $xaml
    $Script:Window = [Windows.Markup.XamlReader]::Load($reader)
}
catch {
    Write-Host "ERROR: Failed to load XAML. Error: $_" -ForegroundColor Red
    Write-Host "XAML file may be corrupted or contain invalid syntax." -ForegroundColor Yellow
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit 1
}

# ============================================================
# GET CONTROLS
# ============================================================

$Script:SearchBox = $Window.FindName("SearchBox")
$Script:SearchPlaceholder = $Window.FindName("SearchPlaceholder")
$Script:ToolsPanel = $Window.FindName("ToolsPanel")
$Script:StatusLabel = $Window.FindName("StatusLabel")
$LogoImage = $Window.FindName("LogoImage")

$Script:BtnCatAll = $Window.FindName("BtnCatAll")
$Script:BtnCatSetup = $Window.FindName("BtnCatSetup")
$Script:BtnCatNetwork = $Window.FindName("BtnCatNetwork")
$Script:BtnCatInternet = $Window.FindName("BtnCatInternet")
$Script:BtnCatSecurity = $Window.FindName("BtnCatSecurity")
$Script:BtnCatSupport = $Window.FindName("BtnCatSupport")
$Script:BtnCatM365 = $Window.FindName("BtnCatM365")
$Script:BtnCatHardware = $Window.FindName("BtnCatHardware")

# Initialize category button icons
Set-CategoryButtonIcon -Button $Script:BtnCatSetup -IconName "Settings2" -IsActive $false
Set-CategoryButtonIcon -Button $Script:BtnCatNetwork -IconName "Network" -IsActive $false
Set-CategoryButtonIcon -Button $Script:BtnCatInternet -IconName "Globe" -IsActive $false
Set-CategoryButtonIcon -Button $Script:BtnCatSecurity -IconName "ShieldCheck" -IsActive $false
Set-CategoryButtonIcon -Button $Script:BtnCatSupport -IconName "LifeBuoy" -IsActive $false
Set-CategoryButtonIcon -Button $Script:BtnCatM365 -IconName "Cloud" -IsActive $false
Set-CategoryButtonIcon -Button $Script:BtnCatHardware -IconName "Cpu" -IsActive $false

$MinimizeButton = $Window.FindName("MinimizeButton")
$CloseButton = $Window.FindName("CloseButton")
$ThemeToggleButton = $Window.FindName("ThemeToggleButton")
$Script:ThemeIcon = $Window.FindName("ThemeIcon")
$HelpButton = $Window.FindName("HelpButton")
$AboutButton = $Window.FindName("AboutButton")
$GitHubButton = $Window.FindName("GitHubButton")
$DiscordButton = $Window.FindName("DiscordButton")
$SelfDestructButton = $Window.FindName("SelfDestructButton")

# Initialize footer button icons
Set-FooterButtonIcon -Button $HelpButton -IconName "HelpCircle" -TextColor "White"
Set-FooterButtonIcon -Button $AboutButton -IconName "Info" -TextColor "White"
Set-FooterButtonIcon -Button $GitHubButton -IconName "GitHub" -TextColor "White"  # Simple Icon brand logo
Set-FooterButtonIcon -Button $DiscordButton -IconName "Discord" -TextColor "White"  # Simple Icon brand logo
Set-FooterButtonIcon -Button $SelfDestructButton -IconName "Trash2" -TextColor "#EF4444"

# Set logo image
if ($null -ne $LogoImage) {
    $faviconPath = Join-Path $Script:AssetsPath "images\Favicon.png"
    if (Test-Path $faviconPath) {
        $LogoImage.Source = New-Object System.Windows.Media.Imaging.BitmapImage([System.Uri]::new($faviconPath))
    }
}

# ============================================================
# EVENT HANDLERS
# ============================================================

# Get title bar grid for dragging
$titleBarGrid = $Window.FindName("TitleBarGrid")

# Window dragging
$null = $titleBarGrid.Add_MouseLeftButtonDown({
    $null = $Window.DragMove()
})

# Window controls
$null = $MinimizeButton.Add_Click({ $Window.WindowState = "Minimized" })
$null = $CloseButton.Add_Click({ $null = $Window.Close() })

# Theme toggle button
if ($null -ne $ThemeToggleButton) {
    $null = $ThemeToggleButton.Add_Click({
        try {
            $currentTheme = Get-ThemePreference
            $newTheme = if ($currentTheme -eq "Light") { "Dark" } else { "Light" }
            Write-Host "Toggling theme from $currentTheme to $newTheme" -ForegroundColor Cyan
            Apply-Theme -Theme $newTheme
        }
        catch {
            Write-Warning "Failed to toggle theme: $_"
        }
    })
}

# Search
$null = $SearchBox.Add_TextChanged({
    # Show/hide placeholder based on text content
    if ($null -ne $Script:SearchPlaceholder) {
        if ([string]::IsNullOrWhiteSpace($Script:SearchBox.Text)) {
            $Script:SearchPlaceholder.Visibility = "Visible"
        } else {
            $Script:SearchPlaceholder.Visibility = "Collapsed"
        }
    }
    Update-ToolsDisplay
})

# Handle placeholder visibility on focus
$null = $SearchBox.Add_GotFocus({
    if ($null -ne $Script:SearchPlaceholder -and [string]::IsNullOrWhiteSpace($Script:SearchBox.Text)) {
        $Script:SearchPlaceholder.Visibility = "Collapsed"
    }
})

$null = $SearchBox.Add_LostFocus({
    if ($null -ne $Script:SearchPlaceholder -and [string]::IsNullOrWhiteSpace($Script:SearchBox.Text)) {
        $Script:SearchPlaceholder.Visibility = "Visible"
    }
})

# Category buttons
$null = $BtnCatAll.Add_Click({ Set-CategoryActive "All" })
$null = $BtnCatSetup.Add_Click({ Set-CategoryActive "Setup" })
$null = $BtnCatNetwork.Add_Click({ Set-CategoryActive "Network" })
$null = $BtnCatInternet.Add_Click({ Set-CategoryActive "Internet" })
$null = $BtnCatSecurity.Add_Click({ Set-CategoryActive "Security" })
$null = $BtnCatSupport.Add_Click({ Set-CategoryActive "Support" })
$null = $BtnCatM365.Add_Click({ Set-CategoryActive "M365" })
$null = $BtnCatHardware.Add_Click({ Set-CategoryActive "Hardware" })

# Help button
$null = $HelpButton.Add_Click({
    $helpText = @"
SOULITEK ALL-IN-ONE SCRIPTS LAUNCHER

USAGE:
------
1. Click on any tool card to launch it
2. Each tool opens in a new PowerShell window
3. Use the search box to find tools by name or keyword
4. Click category buttons to filter by category

TOOLS AVAILABLE: $($Script:Tools.Count)

CATEGORIES:
-----------
- Setup: PC configuration, initial setup, software installation and updates
- Network: Network diagnostics and configuration
- Internet: Domain and DNS analysis
- Security: Security audits, malware scanning, admin checks
- Support: System maintenance, troubleshooting, OneDrive status
- M365: Microsoft 365 management
- Hardware: Hardware health and performance

TIPS:
-----
- Run as Administrator for full functionality
- All tools can run independently
- Most tools include export to TXT/CSV/HTML
- Scripts self-delete after execution (security)

SUPPORT:
--------
Website: www.soulitek.co.il
Email: letstalk@soulitek.co.il
GitHub: https://github.com/Soulitek/Soulitek-All-In-One-Scripts

(C) 2025 SouliTEK - All Rights Reserved
"@
    
    # Show help in MessageBox (too long for snackbar)
    [System.Windows.MessageBox]::Show(
        $helpText,
        "Help - SouliTEK Launcher",
        [System.Windows.MessageBoxButton]::OK,
        [System.Windows.MessageBoxImage]::Information
    )
})

# About button
$null = $AboutButton.Add_Click({
    $aboutText = @"
SouliTEK All-In-One Scripts
Version: $Script:CurrentVersion

Professional PowerShell Tools for IT Technicians

Total Tools: $($Script:Tools.Count)

Coded by: SouliTEK
Website: www.soulitek.co.il
Email: letstalk@soulitek.co.il

(C) 2025 SouliTEK - All Rights Reserved

Made with love in Soulitek
"@
    
    # Show about in MessageBox (informational dialog)
    [System.Windows.MessageBox]::Show(
        $aboutText,
        "About - SouliTEK Launcher",
        [System.Windows.MessageBoxButton]::OK,
        [System.Windows.MessageBoxImage]::Information
    )
})

# GitHub button
$null = $GitHubButton.Add_Click({
    Start-Process "https://github.com/Soulitek/Soulitek-All-In-One-Scripts"
})

# Discord button
$null = $DiscordButton.Add_Click({
    Start-Process "https://discord.gg/eVqu269QBB"
})

# Self-Destruct button
$null = $SelfDestructButton.Add_Click({
    Invoke-SelfDestruct
})

# Note: Website button and logo button removed in new design
# Version and admin status removed from footer in new design

# ============================================================
# INITIALIZE
# ============================================================

# Check if scripts directory exists
if (-not (Test-Path $Script:ScriptPath)) {
    Write-Warning "Scripts directory not found at: $Script:ScriptPath"
    Start-Sleep -Seconds 3
    exit
}

# Set initial category
Set-CategoryActive "All"

# Show welcome message and restore point warning
$null = $Window.Add_Loaded({
    # Load and apply theme preference
    $savedTheme = Get-ThemePreference
    
    # Set initial icon
    if ($null -ne $Script:ThemeIcon) {
        try {
            $moonChar = [char]0xE708
            $sunChar = [char]0xE706
            $Script:ThemeIcon.Text = if ($savedTheme -eq "Dark") { $sunChar } else { $moonChar }
        }
        catch {
            Write-Warning "Failed to set initial theme icon: $_"
        }
    }
    
    Apply-Theme -Theme $savedTheme -Silent
    
    # Show restore point warning first
    Show-RestorePointWarning
    
    # Then show admin warning if not running as admin
    if (-not (Test-Administrator)) {
        Write-Warning "For best results, run this launcher as Administrator. Some tools require elevated privileges."
    }
})

# Show window (suppress return value to prevent random numbers in console)
$null = $Window.ShowDialog()


