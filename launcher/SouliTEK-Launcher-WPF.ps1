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
# ICON SYSTEM - SEGOE MDL2 ASSETS
# ============================================================

# Maps logical icon names to Segoe MDL2 Assets Unicode codepoints.
# Segoe MDL2 Assets ships with every Windows 10/11 install — no external files needed.
$Script:MdlGlyphs = @{
    # Category icons
    "Settings2"     = [char]0xE713  # Settings (gear)
    "Network"       = [char]0xE968  # Network
    "Globe"         = [char]0xE774  # Globe / World
    "ShieldCheck"   = [char]0xEA18  # Shield (security check)
    "LifeBuoy"      = [char]0xE897  # Help
    "Cloud"         = [char]0xE753  # Cloud
    "Cpu"           = [char]0xE950  # Processing

    # Tool icons
    "Activity"      = [char]0xE9F5  # Trackers / activity
    "AlertTriangle" = [char]0xE7BA  # Warning
    "BatteryMedium" = [char]0xE859  # Battery
    "Calendar"      = [char]0xE787  # Calendar
    "CheckCircle2"  = [char]0xE73E  # Checkmark
    "Code"          = [char]0xE8FB  # Code
    "CloudCheck"    = [char]0xE753  # Cloud
    "Database"      = [char]0xF133  # Database
    "Dns"           = [char]0xE968  # Network
    "DownloadCloud" = [char]0xE896  # Download
    "FileSearch"    = [char]0xE721  # Search
    "FileText"      = [char]0xE8A5  # Document
    "Gauge"         = [char]0xEB4D  # Gauge / meter
    "HardDrive"     = [char]0xEDA2  # Hard drive
    "HardDriveIcon" = [char]0xEDA2  # Hard drive
    "HelpCircle"    = [char]0xE897  # Help
    "Info"          = [char]0xE946  # Info
    "Key"           = [char]0xE8D0  # Permissions / key
    "License"       = [char]0xE8A5  # Document
    "Lock"          = [char]0xE72E  # Lock
    "Mail"          = [char]0xE715  # Mail
    "MessageCircle" = [char]0xE8BD  # Message / chat
    "Monitor"       = [char]0xE7F4  # Desktop / PC
    "Package"       = [char]0xE8A5  # Document (no package glyph in MDL2)
    "Printer"       = [char]0xE749  # Print
    "RefreshCw"     = [char]0xE72C  # Sync / refresh
    "Search"        = [char]0xE721  # Search
    "Share2"        = [char]0xE72D  # Share
    "Shield"        = [char]0xEA18  # Shield / security
    "Trash2"        = [char]0xE74D  # Delete
    "Update"        = [char]0xE72C  # Sync / refresh
    "Users"         = [char]0xE716  # People
    "Wifi"          = [char]0xE701  # Wi-Fi
    "Wrench"        = [char]0xE8B8  # Repair / wrench
    "XCircle"       = [char]0xE711  # Cancel
    "Zap"           = [char]0xE945  # Power / lightning

    # Brand icons — closest MDL2 approximations (MDL2 has no brand glyphs)
    "Discord"       = [char]0xE8BD  # Chat
    "Firefox"       = [char]0xE774  # Globe / browser
    "GitHub"        = [char]0xE8FB  # Code
    "McAfee"        = [char]0xEA18  # Security
    "VirusTotal"    = [char]0xEA18  # Security
}

function New-IconPath {
    param(
        [Parameter(Mandatory=$true)]
        [string]$IconName,
        [Parameter(Mandatory=$false)]
        [double]$Size = 24,
        [Parameter(Mandatory=$false)]
        [string]$Color = "#E5E7EB",
        [Parameter(Mandatory=$false)]
        [double]$StrokeWidth = 1.5   # kept for call-site compatibility; ignored
    )

    $glyph = if ($Script:MdlGlyphs.ContainsKey($IconName)) {
        $Script:MdlGlyphs[$IconName]
    } else {
        [char]0xE946  # Info circle as default fallback
    }

    $tb = New-Object System.Windows.Controls.TextBlock
    $tb.Text           = $glyph
    $tb.FontFamily     = "Segoe MDL2 Assets"
    $tb.FontSize       = $Size
    $tb.Foreground     = [System.Windows.Media.BrushConverter]::new().ConvertFromString($Color)
    $tb.VerticalAlignment   = "Center"
    $tb.HorizontalAlignment = "Center"
    $tb.IsHitTestVisible    = $false
    return $tb
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
        Write-Ui -Message "Execution policy temporarily set to RemoteSigned for this session." -Level "OK"
    }
    catch {
        Write-Ui -Message "Warning: Could not modify execution policy. Some features may not work properly." -Level "WARN"
        Write-Ui -Message "Error: $_" -Level "ERROR"
    }
}

# Check if running as administrator, relaunch if not
if (-not (Test-Administrator)) {
    Write-Ui -Message "Relaunching as Administrator..." -Level "WARN"

    try {
        # Get the current script path
        $scriptPath = $MyInvocation.MyCommand.Path

        # Relaunch with admin privileges
        Start-Process -FilePath "powershell.exe" -ArgumentList "-NoProfile -ExecutionPolicy RemoteSigned -File `"$scriptPath`"" -Verb RunAs

        # Exit the current non-admin instance
        exit
    }
    catch {
        Write-Ui -Message "Failed to relaunch as Administrator. Error: $_" -Level "ERROR"
        Write-Ui -Message "Please run this script as Administrator manually." -Level "WARN"
        Read-Host "Press Enter to exit"
        exit 1
    }
}

Write-Ui -Message "Running as Administrator." -Level "OK"

# ============================================================
# GLOBAL VARIABLES
# ============================================================
$Script:ScriptPath = Join-Path $Script:RootPath "scripts"
$Script:AssetsPath = Join-Path $Script:RootPath "assets"
$Script:CurrentVersion = "2.8.0"
$Script:CurrentCategory = "All"
$Script:CurrentTheme = "Dark"   # Will be updated when theme is loaded
$Script:ToastTimer = $null
$Script:SidebarCollapsed = $false
$Script:RecentSearches = @()

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
        Icon = "ShieldCheck"
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
        Icon = "Calendar"
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
        return "Dark"
    }

    try {
        $config = Get-Content $configPath -Raw | ConvertFrom-Json
        if ($config.theme -in @("Light", "Dark")) {
            # Load sidebar and recent searches state
            if ($null -ne $config.sidebar_collapsed) {
                $Script:SidebarCollapsed = [bool]$config.sidebar_collapsed
            }
            if ($null -ne $config.recent_searches) {
                $Script:RecentSearches = @($config.recent_searches)
            }
            return $config.theme
        }
    }
    catch {
        Write-Warning "Failed to read theme preference: $_"
    }

    return "Dark"
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
        theme            = $Theme
        lastUpdated      = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        sidebar_collapsed = $Script:SidebarCollapsed
        recent_searches  = $Script:RecentSearches
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
        Applies the specified theme to the window (comprehensive WPF theme switching).
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
        # Color definitions
        $darkBg            = [System.Windows.Media.Color]::FromRgb(15, 20, 25)      # #0F1419
        $lightBg           = [System.Windows.Media.Color]::FromRgb(248, 250, 252)   # #F8FAFC
        $sidebarBg         = [System.Windows.Media.Color]::FromRgb(19, 25, 32)      # #131920
        $darkCard          = [System.Windows.Media.Color]::FromRgb(26, 31, 46)      # #1A1F2E
        $lightCard         = [System.Windows.Media.Color]::FromRgb(255, 255, 255)
        $darkText          = [System.Windows.Media.Color]::FromRgb(241, 245, 249)   # #F1F5F9
        $lightText         = [System.Windows.Media.Color]::FromRgb(15, 23, 42)      # #0F172A
        $darkTextSecondary  = [System.Windows.Media.Color]::FromRgb(160, 169, 184)  # #A0A9B8
        $lightTextSecondary = [System.Windows.Media.Color]::FromRgb(100, 116, 139)  # #64748B
        $darkSearchBg      = [System.Windows.Media.Color]::FromRgb(26, 31, 46)      # #1A1F2E
        $lightSearchBg     = [System.Windows.Media.Color]::FromRgb(244, 244, 245)   # #F4F4F5
        $darkFooter        = [System.Windows.Media.Color]::FromRgb(15, 20, 25)      # #0F1419
        $lightFooter       = [System.Windows.Media.Color]::FromRgb(100, 116, 139)   # #64748B
        
        if ($Theme -eq "Dark") {
            $Script:Window.Background = [System.Windows.Media.SolidColorBrush]::new($darkBg)

            $scrollViewer = $Script:Window.FindName("MainScrollViewer")
            if ($null -ne $scrollViewer) {
                $scrollViewer.Background = [System.Windows.Media.SolidColorBrush]::new($darkBg)
            }

            $titleBar = $Script:Window.FindName("TitleBarGrid")
            if ($null -ne $titleBar) {
                $titleBar.Background = [System.Windows.Media.SolidColorBrush]::new($sidebarBg)
            }

            $sidebarGrid = $Script:Window.FindName("SidebarGrid")
            if ($null -ne $sidebarGrid) {
                $sidebarGrid.Background = [System.Windows.Media.SolidColorBrush]::new($sidebarBg)
            }

            if ($null -ne $Script:SearchBox) {
                $Script:SearchBox.Background = [System.Windows.Media.SolidColorBrush]::new($darkSearchBg)
                $Script:SearchBox.Foreground = [System.Windows.Media.SolidColorBrush]::new($darkText)
                $Script:SearchBox.BorderBrush = [System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.Color]::FromRgb(37, 43, 59))
            }

            if ($null -ne $Script:SearchPlaceholder) {
                $Script:SearchPlaceholder.Foreground = [System.Windows.Media.SolidColorBrush]::new($darkTextSecondary)
            }

            $footerGrid = $Script:Window.FindName("FooterGrid")
            if ($null -ne $footerGrid) {
                $footerGrid.Background = [System.Windows.Media.SolidColorBrush]::new($darkFooter)
            }

            if ($null -ne $Script:StatusLabel) {
                $Script:StatusLabel.Foreground = [System.Windows.Media.SolidColorBrush]::new($darkTextSecondary)
            }

            $categoryLabel = $Script:Window.FindName("CategoriesLabel")
            if ($null -ne $categoryLabel) {
                $categoryLabel.Foreground = [System.Windows.Media.SolidColorBrush]::new($darkTextSecondary)
            }
        }
        else {
            # Light theme
            $Script:Window.Background = [System.Windows.Media.SolidColorBrush]::new($lightBg)

            $scrollViewer = $Script:Window.FindName("MainScrollViewer")
            if ($null -ne $scrollViewer) {
                $scrollViewer.Background = [System.Windows.Media.SolidColorBrush]::new($lightBg)
            }
            
            $titleBar = $Script:Window.FindName("TitleBarGrid")
            if ($null -ne $titleBar) {
                $titleBar.Background = [System.Windows.Media.SolidColorBrush]::new($lightCard)
            }

            $sidebarGrid = $Script:Window.FindName("SidebarGrid")
            if ($null -ne $sidebarGrid) {
                $sidebarGrid.Background = [System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.Color]::FromRgb(241, 245, 249))
            }

            if ($null -ne $Script:SearchBox) {
                $Script:SearchBox.Background = [System.Windows.Media.SolidColorBrush]::new($lightSearchBg)
                $Script:SearchBox.Foreground = [System.Windows.Media.SolidColorBrush]::new($lightText)
                $Script:SearchBox.BorderBrush = [System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.Color]::FromRgb(203, 213, 225))
            }

            if ($null -ne $Script:SearchPlaceholder) {
                $Script:SearchPlaceholder.Foreground = [System.Windows.Media.SolidColorBrush]::new($lightTextSecondary)
            }

            $footerGrid = $Script:Window.FindName("FooterGrid")
            if ($null -ne $footerGrid) {
                $footerGrid.Background = [System.Windows.Media.SolidColorBrush]::new($lightBg)
            }

            if ($null -ne $Script:StatusLabel) {
                $Script:StatusLabel.Foreground = [System.Windows.Media.SolidColorBrush]::new($lightTextSecondary)
            }

            $categoryLabel = $Script:Window.FindName("CategoriesLabel")
            if ($null -ne $categoryLabel) {
                $categoryLabel.Foreground = [System.Windows.Media.SolidColorBrush]::new($lightTextSecondary)
            }
        }
        
        # Store theme for card updates
        $Script:CurrentTheme = $Theme
        
        # Update theme icon if available
        if ($null -ne $Script:ThemeIcon) {
            try {
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
        
        # Rebuild sidebar + tool cards for new theme
        if ($null -ne $Script:CurrentCategory) {
            Set-CategoryActive -CategoryName $Script:CurrentCategory
        }
        
        if (-not $Silent) {
            Write-Ui -Message "Theme switched to $Theme" -Level "OK"
        }
    }
    catch {
        Write-Warning "Failed to apply theme: $_"
        Write-Warning $_.Exception.Message
        Write-Warning $_.ScriptStackTrace
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
        $arguments = "-NoExit -NoProfile -ExecutionPolicy RemoteSigned -File `"$scriptPath`""
        Start-Process -FilePath $psPath -ArgumentList $arguments
        
        Show-Toast -Message "Launched: $ToolName" -Type Success
        $Script:StatusLabel.Text = "Launched: $ToolName"
        Write-Ui -Message "Launched: $ToolName" -Level "OK"
    }
    catch {
        Write-Warning "Failed to launch $ToolName`: $_"
        Show-Toast -Message "Error launching: $ToolName" -Type Error
        $Script:StatusLabel.Text = "Error launching tool"
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
    
    # Get current theme
    $currentTheme = if ($null -ne $Script:CurrentTheme) { $Script:CurrentTheme } else { Get-ThemePreference }
    
    # Theme-aware colors
    $cardBgColor        = if ($currentTheme -eq "Dark") { "#1A1F2E" } else { "#FFFFFF" }
    $textColor          = if ($currentTheme -eq "Dark") { "#F1F5F9" } else { "#0F172A" }
    $textSecondaryColor = if ($currentTheme -eq "Dark") { "#A0A9B8" } else { "#64748B" }
    $iconColor          = if ($currentTheme -eq "Dark") { "#F1F5F9" } else { "#1E293B" }
    
    foreach ($tool in $filteredTools) {
        # 320x180 card with DockPanel layout
        $card = New-Object System.Windows.Controls.Border
        $card.Style = $Script:Window.FindResource("ToolCard")
        $card.Width = 320
        $card.Height = 180
        $card.Margin = "0,0,12,12"
        $card.Background = [System.Windows.Media.SolidColorBrush]::new(
            [System.Windows.Media.ColorConverter]::ConvertFromString($cardBgColor))

        $dock = New-Object System.Windows.Controls.DockPanel
        $dock.LastChildFill = $true

        # Category badge (docked top)
        $badgeBorder = New-Object System.Windows.Controls.Border
        $badgeBorder.CornerRadius = [System.Windows.CornerRadius]::new(4)
        $badgeBorder.Background = [System.Windows.Media.SolidColorBrush]::new(
            [System.Windows.Media.ColorConverter]::ConvertFromString($tool.Color))
        $badgeBorder.Padding = [System.Windows.Thickness]::new(8, 3, 8, 3)
        $badgeBorder.HorizontalAlignment = "Left"
        $badgeBorder.Margin = [System.Windows.Thickness]::new(0, 0, 0, 10)
        [System.Windows.Controls.DockPanel]::SetDock($badgeBorder, [System.Windows.Controls.Dock]::Top)
        $badgeLabel = New-Object System.Windows.Controls.TextBlock
        $badgeLabel.Text = $tool.Category
        $badgeLabel.FontSize = 10
        $badgeLabel.FontFamily = "Segoe UI"
        $badgeLabel.FontWeight = "SemiBold"
        $badgeLabel.Foreground = [System.Windows.Media.Brushes]::White
        $badgeBorder.Child = $badgeLabel
        $null = $dock.Children.Add($badgeBorder)

        # Name row with icon (docked top)
        $headerStack = New-Object System.Windows.Controls.StackPanel
        $headerStack.Orientation = "Horizontal"
        $headerStack.Margin = [System.Windows.Thickness]::new(0, 0, 0, 8)
        [System.Windows.Controls.DockPanel]::SetDock($headerStack, [System.Windows.Controls.Dock]::Top)

        if ($tool.Icon -and $tool.Icon -notmatch "^\[.*\]$") {
            try {
                $icon = New-IconPath -IconName $tool.Icon -Size 20 -Color $iconColor -StrokeWidth 1.5
                $icon.Margin = [System.Windows.Thickness]::new(0, 0, 8, 0)
                $icon.VerticalAlignment = "Center"
                $null = $headerStack.Children.Add($icon)
            }
            catch { }
        }

        $nameText = New-Object System.Windows.Controls.TextBlock
        $nameText.Text = $tool.Name
        $nameText.FontSize = 15
        $nameText.FontWeight = "SemiBold"
        $nameText.FontFamily = "Segoe UI"
        $nameText.Foreground = [System.Windows.Media.SolidColorBrush]::new(
            [System.Windows.Media.ColorConverter]::ConvertFromString($textColor))
        $nameText.VerticalAlignment = "Center"
        $nameText.TextWrapping = "Wrap"
        $nameText.MaxWidth = 240
        $null = $headerStack.Children.Add($nameText)
        $null = $dock.Children.Add($headerStack)

        # Description (fills remaining space)
        $descText = New-Object System.Windows.Controls.TextBlock
        $descText.Text = $tool.Description
        $descText.FontSize = 12
        $descText.FontFamily = "Segoe UI"
        $descText.Foreground = [System.Windows.Media.SolidColorBrush]::new(
            [System.Windows.Media.ColorConverter]::ConvertFromString($textSecondaryColor))
        $descText.TextWrapping = "Wrap"
        $descText.TextTrimming = "CharacterEllipsis"
        $descText.MaxHeight = 48
        $null = $dock.Children.Add($descText)

        $card.Child = $dock

        $card.Tag = @{ Script = $tool.Script; Name = $tool.Name }
        $null = $card.Add_MouseLeftButtonUp({
            $toolInfo = $this.Tag
            Start-Tool -ScriptName $toolInfo.Script -ToolName $toolInfo.Name
        })

        # Fade-in animation
        $card.Opacity = 0
        $null = $Script:ToolsPanel.Children.Add($card)
        $anim = New-Object System.Windows.Media.Animation.DoubleAnimation
        $anim.From = 0.0; $anim.To = 1.0
        $anim.Duration = [System.Windows.Duration]::new([TimeSpan]::FromMilliseconds(200))
        $card.BeginAnimation([System.Windows.UIElement]::OpacityProperty, $anim)
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

    # Rebuild sidebar to reflect new active state
    $catPanel = $Script:Window.FindName("SidebarCategoriesPanel")
    if ($null -ne $catPanel) {
        Initialize-Sidebar
    }

    Update-ToolsDisplay
}

function Initialize-Sidebar {
    $catPanel = $Script:Window.FindName("SidebarCategoriesPanel")
    $navPanel = $Script:Window.FindName("SidebarNavPanel")
    if ($null -eq $catPanel) { return }

    $catPanel.Children.Clear()

    $catDefs = @(
        @{ Name = "All";         Icon = "";           Label = "All Tools" }
        @{ Name = "Setup";       Icon = "Settings2";  Label = "Setup" }
        @{ Name = "Network";     Icon = "Network";    Label = "Network" }
        @{ Name = "Internet";    Icon = "Globe";      Label = "Internet" }
        @{ Name = "Security";    Icon = "ShieldCheck"; Label = "Security" }
        @{ Name = "Support";     Icon = "LifeBuoy";   Label = "Support" }
        @{ Name = "M365";        Icon = "Cloud";      Label = "M365" }
        @{ Name = "Hardware";    Icon = "Cpu";        Label = "Hardware" }
        @{ Name = "Performance"; Icon = "Gauge";      Label = "Performance" }
    )

    $indigoColor = [System.Windows.Media.ColorConverter]::ConvertFromString("#6366F1")
    $cardColor   = [System.Windows.Media.ColorConverter]::ConvertFromString("#1A1F2E")
    $badgeDark   = [System.Windows.Media.ColorConverter]::ConvertFromString("#252B3B")
    $activeText  = "#F1F5F9"
    $mutedText   = "#A0A9B8"

    foreach ($catDef in $catDefs) {
        $isActive  = $catDef.Name -eq $Script:CurrentCategory
        $toolCount = if ($catDef.Name -eq "All") {
            $Script:Tools.Count
        } else {
            ($Script:Tools | Where-Object { $_.Category -eq $catDef.Name }).Count
        }

        # Row container
        $row = New-Object System.Windows.Controls.Border
        $row.Height  = 40
        $row.Padding = [System.Windows.Thickness]::new(0)
        $row.Cursor  = "Hand"
        $row.Tag     = $catDef.Name
        if ($isActive) {
            $row.Background = [System.Windows.Media.SolidColorBrush]::new($cardColor)
        }

        # Inner grid: indicator(4) | icon(32) | label(*) | badge(auto)
        $g = New-Object System.Windows.Controls.Grid
        $c0 = New-Object System.Windows.Controls.ColumnDefinition; $c0.Width = [System.Windows.GridLength]::new(4)
        $c1 = New-Object System.Windows.Controls.ColumnDefinition; $c1.Width = [System.Windows.GridLength]::new(32)
        $c2 = New-Object System.Windows.Controls.ColumnDefinition; $c2.Width = [System.Windows.GridLength]::new(1, [System.Windows.GridUnitType]::Star)
        $c3 = New-Object System.Windows.Controls.ColumnDefinition; $c3.Width = [System.Windows.GridLength]::Auto
        $g.ColumnDefinitions.Add($c0); $g.ColumnDefinitions.Add($c1)
        $g.ColumnDefinitions.Add($c2); $g.ColumnDefinitions.Add($c3)

        # Active indicator strip
        $strip = New-Object System.Windows.Controls.Border
        $strip.CornerRadius = [System.Windows.CornerRadius]::new(0, 3, 3, 0)
        $strip.VerticalAlignment = "Stretch"
        $strip.Background = if ($isActive) {
            [System.Windows.Media.SolidColorBrush]::new($indigoColor)
        } else {
            [System.Windows.Media.Brushes]::Transparent
        }
        [System.Windows.Controls.Grid]::SetColumn($strip, 0)

        # Icon
        $iconGrid = New-Object System.Windows.Controls.Grid
        $iconGrid.VerticalAlignment   = "Center"
        $iconGrid.HorizontalAlignment = "Center"
        [System.Windows.Controls.Grid]::SetColumn($iconGrid, 1)
        if ($catDef.Icon) {
            try {
                $ic = New-IconPath -IconName $catDef.Icon -Size 16 `
                    -Color (if ($isActive) { $activeText } else { $mutedText }) -StrokeWidth 1.5
                $null = $iconGrid.Children.Add($ic)
            } catch { }
        }

        # Label
        $lbl = New-Object System.Windows.Controls.TextBlock
        $lbl.Text       = $catDef.Label
        $lbl.FontSize   = 13
        $lbl.FontFamily = "Segoe UI"
        $lbl.FontWeight = if ($isActive) { "SemiBold" } else { "Normal" }
        $lbl.Foreground = if ($isActive) { $activeText } else { $mutedText }
        $lbl.VerticalAlignment = "Center"
        $lbl.Margin = [System.Windows.Thickness]::new(4, 0, 0, 0)
        [System.Windows.Controls.Grid]::SetColumn($lbl, 2)

        # Count badge
        $badge = New-Object System.Windows.Controls.Border
        $badge.CornerRadius = [System.Windows.CornerRadius]::new(8)
        $badge.Background   = if ($isActive) {
            [System.Windows.Media.SolidColorBrush]::new($indigoColor)
        } else {
            [System.Windows.Media.SolidColorBrush]::new($badgeDark)
        }
        $badge.Padding          = [System.Windows.Thickness]::new(6, 2, 6, 2)
        $badge.VerticalAlignment = "Center"
        $badge.Margin           = [System.Windows.Thickness]::new(0, 0, 12, 0)
        $badgeNum = New-Object System.Windows.Controls.TextBlock
        $badgeNum.Text       = "$toolCount"
        $badgeNum.FontSize   = 11
        $badgeNum.FontFamily = "Segoe UI"
        $badgeNum.Foreground = if ($isActive) { [System.Windows.Media.Brushes]::White } else { $mutedText }
        $badge.Child = $badgeNum
        [System.Windows.Controls.Grid]::SetColumn($badge, 3)

        $null = $g.Children.Add($strip)
        $null = $g.Children.Add($iconGrid)
        $null = $g.Children.Add($lbl)
        $null = $g.Children.Add($badge)
        $row.Child = $g

        # Hover effects
        $null = $row.Add_MouseEnter({
            if ($this.Tag -ne $Script:CurrentCategory) {
                $this.Background = [System.Windows.Media.SolidColorBrush]::new(
                    [System.Windows.Media.ColorConverter]::ConvertFromString("#1A1F2E"))
            }
        })
        $null = $row.Add_MouseLeave({
            if ($this.Tag -ne $Script:CurrentCategory) {
                $this.Background = [System.Windows.Media.Brushes]::Transparent
            }
        })
        $null = $row.Add_MouseLeftButtonUp({
            param($sender, $e)
            Set-CategoryActive $sender.Tag
            $e.Handled = $true
        })

        $null = $catPanel.Children.Add($row)
    }

    # Nav buttons at sidebar bottom — build ONCE on first call.
    # Skipping rebuilds preserves the Add_MouseLeftButtonUp handlers wired
    # up later in the script; rebuilding would create new WPF objects whose
    # handlers were never attached, silently breaking Help/About/GitHub/
    # Discord/Uninstall buttons after any category change.
    if ($null -ne $navPanel -and $navPanel.Children.Count -eq 0) {
        # Separator
        $sep = New-Object System.Windows.Controls.Border
        $sep.Height     = 1
        $sep.Background = [System.Windows.Media.SolidColorBrush]::new(
            [System.Windows.Media.ColorConverter]::ConvertFromString("#1A1F2E"))
        $sep.Margin = [System.Windows.Thickness]::new(12, 8, 12, 8)
        $null = $navPanel.Children.Add($sep)

        $navDefs = @(
            @{ Name = "HelpButton";         Label = "Help";      Icon = "HelpCircle"; Color = "#A0A9B8" }
            @{ Name = "AboutButton";        Label = "About";     Icon = "Info";       Color = "#A0A9B8" }
            @{ Name = "GitHubButton";       Label = "GitHub";    Icon = "GitHub";     Color = "#A0A9B8" }
            @{ Name = "DiscordButton";      Label = "Discord";   Icon = "Discord";    Color = "#A0A9B8" }
            @{ Name = "SelfDestructButton"; Label = "Uninstall"; Icon = "Trash2";     Color = "#EF4444" }
        )

        foreach ($nd in $navDefs) {
            $navRow = New-Object System.Windows.Controls.Border
            $navRow.Height = 36
            $navRow.Cursor = "Hand"
            $navRow.Padding = [System.Windows.Thickness]::new(0)

            $ng = New-Object System.Windows.Controls.Grid
            $nc0 = New-Object System.Windows.Controls.ColumnDefinition; $nc0.Width = [System.Windows.GridLength]::new(36)
            $nc1 = New-Object System.Windows.Controls.ColumnDefinition; $nc1.Width = [System.Windows.GridLength]::new(1, [System.Windows.GridUnitType]::Star)
            $ng.ColumnDefinitions.Add($nc0); $ng.ColumnDefinitions.Add($nc1)

            $icGrid = New-Object System.Windows.Controls.Grid
            $icGrid.VerticalAlignment = "Center"; $icGrid.HorizontalAlignment = "Center"
            [System.Windows.Controls.Grid]::SetColumn($icGrid, 0)
            try {
                $navIc = New-IconPath -IconName $nd.Icon -Size 14 -Color $nd.Color -StrokeWidth 1.5
                $null = $icGrid.Children.Add($navIc)
            } catch { }

            $navLbl = New-Object System.Windows.Controls.TextBlock
            $navLbl.Text       = $nd.Label
            $navLbl.FontSize   = 12
            $navLbl.FontFamily = "Segoe UI"
            $navLbl.Foreground = $nd.Color
            $navLbl.VerticalAlignment = "Center"
            [System.Windows.Controls.Grid]::SetColumn($navLbl, 1)

            $null = $ng.Children.Add($icGrid); $null = $ng.Children.Add($navLbl)
            $navRow.Child = $ng

            $null = $navRow.Add_MouseEnter({
                $this.Background = [System.Windows.Media.SolidColorBrush]::new(
                    [System.Windows.Media.ColorConverter]::ConvertFromString("#1A1F2E"))
            })
            $null = $navRow.Add_MouseLeave({ $this.Background = [System.Windows.Media.Brushes]::Transparent })

            Set-Variable -Name $nd.Name -Value $navRow -Scope Script
            $null = $navPanel.Children.Add($navRow)
        }
    }
}

function Show-Toast {
    param(
        [string]$Message,
        [ValidateSet('Success', 'Error', 'Info')]
        [string]$Type = 'Info',
        [int]$DurationMs = 3000
    )

    $toastBorder = $Script:Window.FindName("ToastBorder")
    $toastIcon   = $Script:Window.FindName("ToastIcon")
    $toastText   = $Script:Window.FindName("ToastText")
    if ($null -eq $toastBorder) { return }

    if ($null -ne $Script:ToastTimer) {
        $Script:ToastTimer.Stop()
        $Script:ToastTimer = $null
    }

    switch ($Type) {
        'Success' {
            $toastIcon.Text = [char]0xE73E
            $toastIcon.Foreground = [System.Windows.Media.SolidColorBrush]::new(
                [System.Windows.Media.ColorConverter]::ConvertFromString("#10B981"))
        }
        'Error' {
            $toastIcon.Text = [char]0xE711
            $toastIcon.Foreground = [System.Windows.Media.SolidColorBrush]::new(
                [System.Windows.Media.ColorConverter]::ConvertFromString("#EF4444"))
        }
        default {
            $toastIcon.Text = [char]0xE946
            $toastIcon.Foreground = [System.Windows.Media.SolidColorBrush]::new(
                [System.Windows.Media.ColorConverter]::ConvertFromString("#6366F1"))
        }
    }

    $toastText.Text = $Message
    $toastBorder.Visibility = [System.Windows.Visibility]::Visible

    $Script:ToastTimer = New-Object System.Windows.Threading.DispatcherTimer
    $Script:ToastTimer.Interval = [TimeSpan]::FromMilliseconds($DurationMs)
    $null = $Script:ToastTimer.Add_Tick({
        $Script:Window.FindName("ToastBorder").Visibility = [System.Windows.Visibility]::Collapsed
        $Script:ToastTimer.Stop()
    })
    $Script:ToastTimer.Start()
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
                    Write-Ui -Message $createResult.Message -Level "OK"
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
                Write-Ui -Message "Desktop shortcut removed: $shortcutPath" -Level "OK"
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
                Write-Ui -Message "Installation directory removed: $Script:RootPath" -Level "OK"
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
    Write-Ui -Message "ERROR: MainWindow.xaml not found at: $xamlPath" -Level "ERROR"
    Write-Ui -Message "Please ensure MainWindow.xaml is in the launcher folder." -Level "WARN"
    Read-Host "Press Enter to exit"
    exit 1
}

try {
    [xml]$xaml = Get-Content $xamlPath
    $reader = New-Object System.Xml.XmlNodeReader $xaml
    $Script:Window = [Windows.Markup.XamlReader]::Load($reader)
}
catch {
    Write-Ui -Message "ERROR: Failed to load XAML. Error: $_" -Level "ERROR"
    Write-Ui -Message "XAML file may be corrupted or contain invalid syntax." -Level "WARN"
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

# Category pill buttons no longer exist in the new XAML (replaced by sidebar).
# FindName returns $null — guard all calls.
$Script:BtnCatAll      = $Window.FindName("BtnCatAll")
$Script:BtnCatSetup    = $Window.FindName("BtnCatSetup")
$Script:BtnCatNetwork  = $Window.FindName("BtnCatNetwork")
$Script:BtnCatInternet = $Window.FindName("BtnCatInternet")
$Script:BtnCatSecurity = $Window.FindName("BtnCatSecurity")
$Script:BtnCatSupport  = $Window.FindName("BtnCatSupport")
$Script:BtnCatM365     = $Window.FindName("BtnCatM365")
$Script:BtnCatHardware = $Window.FindName("BtnCatHardware")
if ($null -ne $Script:BtnCatSetup)    { Set-CategoryButtonIcon -Button $Script:BtnCatSetup    -IconName "Settings2"  -IsActive $false }
if ($null -ne $Script:BtnCatNetwork)  { Set-CategoryButtonIcon -Button $Script:BtnCatNetwork  -IconName "Network"    -IsActive $false }
if ($null -ne $Script:BtnCatInternet) { Set-CategoryButtonIcon -Button $Script:BtnCatInternet -IconName "Globe"      -IsActive $false }
if ($null -ne $Script:BtnCatSecurity) { Set-CategoryButtonIcon -Button $Script:BtnCatSecurity -IconName "ShieldCheck" -IsActive $false }
if ($null -ne $Script:BtnCatSupport)  { Set-CategoryButtonIcon -Button $Script:BtnCatSupport  -IconName "LifeBuoy"   -IsActive $false }
if ($null -ne $Script:BtnCatM365)     { Set-CategoryButtonIcon -Button $Script:BtnCatM365     -IconName "Cloud"      -IsActive $false }
if ($null -ne $Script:BtnCatHardware) { Set-CategoryButtonIcon -Button $Script:BtnCatHardware -IconName "Cpu"        -IsActive $false }

$MinimizeButton    = $Window.FindName("MinimizeButton")
$CloseButton       = $Window.FindName("CloseButton")
$ThemeToggleButton = $Window.FindName("ThemeToggleButton")
$Script:ThemeIcon  = $Window.FindName("ThemeIcon")
# Footer nav buttons are now created dynamically in Initialize-Sidebar.
# FindName returns $null here — Initialize-Sidebar sets the Script-scope vars below.
$HelpButton         = $Window.FindName("HelpButton")
$AboutButton        = $Window.FindName("AboutButton")
$GitHubButton       = $Window.FindName("GitHubButton")
$DiscordButton      = $Window.FindName("DiscordButton")
$SelfDestructButton = $Window.FindName("SelfDestructButton")
# Guard old Set-FooterButtonIcon calls (buttons no longer in XAML)
if ($null -ne $HelpButton)         { Set-FooterButtonIcon -Button $HelpButton         -IconName "HelpCircle" -TextColor "White" }
if ($null -ne $AboutButton)        { Set-FooterButtonIcon -Button $AboutButton        -IconName "Info"       -TextColor "White" }
if ($null -ne $GitHubButton)       { Set-FooterButtonIcon -Button $GitHubButton       -IconName "GitHub"     -TextColor "White" }
if ($null -ne $DiscordButton)      { Set-FooterButtonIcon -Button $DiscordButton      -IconName "Discord"    -TextColor "White" }
if ($null -ne $SelfDestructButton) { Set-FooterButtonIcon -Button $SelfDestructButton -IconName "Trash2"     -TextColor "#EF4444" }

# Build the sidebar (sets $Script:HelpButton etc. so event bindings below work)
Initialize-Sidebar

# Set logo image and make it clickable
$LogoButton = $Window.FindName("LogoButton")
if ($null -ne $LogoImage) {
    $logoPath = Join-Path $Script:AssetsPath "images\Logo.png"
    if (Test-Path $logoPath) {
        try {
            $bitmap = New-Object System.Windows.Media.Imaging.BitmapImage
            $bitmap.BeginInit()
            $bitmap.UriSource = [System.Uri]::new($logoPath)
            $bitmap.EndInit()
            $LogoImage.Source = $bitmap
        }
        catch {
            Write-Warning "Failed to load logo image: $_"
        }
    }
    else {
        Write-Warning "Logo image not found at: $logoPath"
    }
}

    # Make logo button clickable to navigate to website
    if ($null -ne $LogoButton) {
        # Disable button hover effects
        $LogoButton.Focusable = $false
        
        $null = $LogoButton.Add_Click({
            try {
                $websiteUrl = "https://www.soulitek.co.il"
                Start-Process $websiteUrl
                Write-Ui -Message "Opening website: $websiteUrl" -Level "INFO"
            }
            catch {
                Write-Warning "Failed to open website: $_"
                [System.Windows.MessageBox]::Show(
                    "Failed to open website. Please visit: https://www.soulitek.co.il",
                    "Error",
                    [System.Windows.MessageBoxButton]::OK,
                    [System.Windows.MessageBoxImage]::Warning
                )
            }
        })
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
            Write-Ui -Message "Toggling theme from $currentTheme to $newTheme" -Level "INFO"
            Apply-Theme -Theme $newTheme
        }
        catch {
            Write-Warning "Failed to toggle theme: $_"
        }
    })
}

# Search
$null = $SearchBox.Add_TextChanged({
    if ($null -ne $Script:SearchPlaceholder) {
        if ([string]::IsNullOrWhiteSpace($Script:SearchBox.Text)) {
            $Script:SearchPlaceholder.Visibility = "Visible"
        } else {
            $Script:SearchPlaceholder.Visibility = "Collapsed"
        }
    }
    # Persist searches of 3+ characters
    $q = $Script:SearchBox.Text
    if ($q.Length -ge 3) {
        $Script:RecentSearches = @($q) + ($Script:RecentSearches | Where-Object { $_ -ne $q }) | Select-Object -First 10
        Set-ThemePreference -Theme $Script:CurrentTheme
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

# Ctrl+K to focus search; Escape to clear it
$null = $Script:Window.Add_KeyDown({
    param($sender, $e)
    if ($e.Key -eq [System.Windows.Input.Key]::K -and
        [System.Windows.Input.Keyboard]::Modifiers -eq [System.Windows.Input.ModifierKeys]::Control) {
        $Script:SearchBox.Focus()
        $Script:SearchBox.SelectAll()
        $e.Handled = $true
    }
    if ($e.Key -eq [System.Windows.Input.Key]::Escape -and
        -not [string]::IsNullOrWhiteSpace($Script:SearchBox.Text)) {
        $Script:SearchBox.Text = ""
        $e.Handled = $true
    }
})

# Category pill buttons — guarded (no longer in XAML; sidebar handles category switching)
if ($null -ne $Script:BtnCatAll)      { $null = $Script:BtnCatAll.Add_Click({      Set-CategoryActive "All" }) }
if ($null -ne $Script:BtnCatSetup)    { $null = $Script:BtnCatSetup.Add_Click({    Set-CategoryActive "Setup" }) }
if ($null -ne $Script:BtnCatNetwork)  { $null = $Script:BtnCatNetwork.Add_Click({  Set-CategoryActive "Network" }) }
if ($null -ne $Script:BtnCatInternet) { $null = $Script:BtnCatInternet.Add_Click({ Set-CategoryActive "Internet" }) }
if ($null -ne $Script:BtnCatSecurity) { $null = $Script:BtnCatSecurity.Add_Click({ Set-CategoryActive "Security" }) }
if ($null -ne $Script:BtnCatSupport)  { $null = $Script:BtnCatSupport.Add_Click({  Set-CategoryActive "Support" }) }
if ($null -ne $Script:BtnCatM365)     { $null = $Script:BtnCatM365.Add_Click({     Set-CategoryActive "M365" }) }
if ($null -ne $Script:BtnCatHardware) { $null = $Script:BtnCatHardware.Add_Click({ Set-CategoryActive "Hardware" }) }

# Help button
$null = $HelpButton.Add_MouseLeftButtonUp({
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
$null = $AboutButton.Add_MouseLeftButtonUp({
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
$null = $GitHubButton.Add_MouseLeftButtonUp({
    Start-Process "https://github.com/Soulitek/Soulitek-All-In-One-Scripts"
})

# Discord button
$null = $DiscordButton.Add_MouseLeftButtonUp({
    Start-Process "https://discord.gg/eVqu269QBB"
})

# Self-Destruct button
$null = $SelfDestructButton.Add_MouseLeftButtonUp({
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
    $Script:CurrentTheme = $savedTheme  # Initialize theme variable
    
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


