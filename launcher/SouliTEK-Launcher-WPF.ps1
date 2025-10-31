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
# HELPER FUNCTIONS
# ============================================================

function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
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

$Script:LauncherPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$Script:RootPath = Split-Path -Parent $Script:LauncherPath
$Script:ScriptPath = Join-Path $Script:RootPath "scripts"
$Script:CurrentVersion = "2.0.0"
$Script:CurrentCategory = "All"

# Tool definitions
$Script:Tools = @(
    @{
        Name = "Battery Report Generator"
        Icon = "[B]"
        Description = "Generate comprehensive battery health reports for laptops"
        Script = "battery_report_generator.ps1"
        Category = "Hardware"
        Tags = @("battery", "laptop", "health", "report", "power")
        Color = "#3498db"
    },
    @{
        Name = "BitLocker Status Report"
        Icon = "[S]"
        Description = "Check BitLocker encryption status and recovery keys for all volumes"
        Script = "bitlocker_status_report.ps1"
        Category = "Security"
        Tags = @("bitlocker", "encryption", "security", "recovery", "volume")
        Color = "#dc2626"
    },
    @{
        Name = "PST Finder"
        Icon = "[M]"
        Description = "Locate and analyze Outlook PST files across the system"
        Script = "FindPST.ps1"
        Category = "M365"
        Tags = @("outlook", "pst", "email", "microsoft", "office", "365", "backup")
        Color = "#d97706"
    },
    @{
        Name = "License Expiration Checker"
        Icon = "[L]"
        Description = "Monitor Microsoft 365 license subscriptions and get alerts for capacity issues"
        Script = "license_expiration_checker.ps1"
        Category = "M365"
        Tags = @("license", "microsoft", "365", "m365", "subscription", "expiration", "monitoring", "alerts")
        Color = "#f59e0b"
    },
    @{
        Name = "M365 MFA Audit"
        Icon = "[A]"
        Description = "Audit Microsoft 365 MFA status across all users with detailed reports and optional weekly email"
        Script = "m365_mfa_audit.ps1"
        Category = "M365"
        Tags = @("mfa", "multifactor", "authentication", "microsoft", "365", "m365", "audit", "security", "report", "compliance")
        Color = "#f59e0b"
    },
    @{
        Name = "Printer Spooler Fix"
        Icon = "[P]"
        Description = "Comprehensive printer spooler troubleshooting and repair"
        Script = "printer_spooler_fix.ps1"
        Category = "Support"
        Tags = @("printer", "spooler", "print", "troubleshoot", "fix", "repair")
        Color = "#e74c3c"
    },
    @{
        Name = "WiFi Password Viewer"
        Icon = "[W]"
        Description = "View and export saved WiFi passwords from Windows"
        Script = "wifi_password_viewer.ps1"
        Category = "Network"
        Tags = @("wifi", "password", "network", "wireless", "credentials")
        Color = "#1abc9c"
    },
    @{
        Name = "Event Log Analyzer"
        Icon = "[E]"
        Description = "Analyze Windows Event Logs with statistical summaries"
        Script = "EventLogAnalyzer.ps1"
        Category = "Support"
        Tags = @("event", "log", "analyzer", "diagnostics", "windows", "troubleshoot")
        Color = "#f39c12"
    },
    @{
        Name = "Remote Support Toolkit"
        Icon = "[R]"
        Description = "Comprehensive system diagnostics for remote IT support"
        Script = "remote_support_toolkit.ps1"
        Category = "Support"
        Tags = @("remote", "support", "diagnostics", "system", "troubleshoot")
        Color = "#2ecc71"
    },
    @{
        Name = "Network Test Tool"
        Icon = "[N]"
        Description = "Ping, tracert, DNS lookup, and latency testing for network diagnostics"
        Script = "network_test_tool.ps1"
        Category = "Network"
        Tags = @("network", "ping", "tracert", "dns", "latency", "diagnostics")
        Color = "#3b82f6"
    },
    @{
        Name = "USB Device Log"
        Icon = "[U]"
        Description = "Forensic USB device history analysis for security audits"
        Script = "usb_device_log.ps1"
        Category = "Security"
        Tags = @("usb", "forensics", "security", "audit", "device", "history")
        Color = "#8b5cf6"
    },
    @{
        Name = "Chocolatey Installer"
        Icon = "[C]"
        Description = "Interactive package installer with Ninite-like UX - Install apps via Chocolatey"
        Script = "SouliTEK-Choco-Installer.ps1"
        Category = "Software"
        Tags = @("chocolatey", "installer", "software", "packages", "apps", "install")
        Color = "#10b981"
    },
    @{
        Name = "Storage Health Monitor"
        Icon = "[SH]"
        Description = "Monitor storage health with SMART data, detect reallocated sectors and read errors"
        Script = "storage_health_monitor.ps1"
        Category = "Hardware"
        Tags = @("storage", "smart", "disk", "health", "monitor", "hdd", "ssd", "sectors", "errors")
        Color = "#06b6d4"
    },
    @{
        Name = "Hardware Inventory Report"
        Icon = "[H]"
        Description = "Full hardware inventory: CPU, GPU, RAM, disk, motherboard, BIOS, and serial numbers. Exports JSON/CSV for warranty tracking"
        Script = "hardware_inventory_report.ps1"
        Category = "Hardware"
        Tags = @("hardware", "inventory", "warranty", "cpu", "gpu", "ram", "disk", "motherboard", "bios", "serial", "json", "csv")
        Color = "#ef4444"
    },
    @{
        Name = "System Restore Point"
        Icon = "[T]"
        Description = "Create Windows System Restore Points for system recovery and rollback"
        Script = "create_system_restore_point.ps1"
        Category = "Support"
        Tags = @("restore", "system", "recovery", "backup", "rollback", "protection")
        Color = "#f59e0b"
    },
    @{
        Name = "RAM Slot Utilization Report"
        Icon = "[RAM]"
        Description = "Shows RAM slots used vs total, type (DDR3/DDR4/DDR5), speed, and capacity"
        Script = "ram_slot_utilization_report.ps1"
        Category = "Hardware"
        Tags = @("ram", "memory", "hardware", "ddr", "slots", "capacity", "speed")
        Color = "#3498db"
    },
    @{
        Name = "Disk Usage Analyzer"
        Icon = "[D]"
        Description = "Find folders larger than 1 GB and export results sorted by size with HTML visualization"
        Script = "disk_usage_analyzer.ps1"
        Category = "Hardware"
        Tags = @("disk", "usage", "storage", "folders", "size", "cleanup", "analysis")
        Color = "#06b6d4"
    }
)

# ============================================================
# HELPER FUNCTIONS
# ============================================================

function Start-Tool {
    param(
        [string]$ScriptName,
        [string]$ToolName
    )
    
    $scriptPath = Join-Path $Script:ScriptPath $ScriptName
    
    if (-not (Test-Path $scriptPath)) {
        [System.Windows.MessageBox]::Show(
            "Script not found: $ScriptName`n`nPlease ensure all scripts are in the scripts folder.",
            "Script Not Found",
            [System.Windows.MessageBoxButton]::OK,
            [System.Windows.MessageBoxImage]::Error
        )
        return
    }
    
    try {
        $psPath = "powershell.exe"
        $arguments = "-NoExit -NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""
        Start-Process -FilePath $psPath -ArgumentList $arguments
        
        $Script:StatusLabel.Text = "Launched: $ToolName"
        $Script:StatusLabel.Foreground = "#10B981"
    }
    catch {
        [System.Windows.MessageBox]::Show(
            "Failed to launch $ToolName`n`nError: $_",
            "Launch Error",
            [System.Windows.MessageBoxButton]::OK,
            [System.Windows.MessageBoxImage]::Error
        )
        
        $Script:StatusLabel.Text = "Error launching tool"
        $Script:StatusLabel.Foreground = "#EF4444"
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
    Write-Host "DEBUG: Update-ToolsDisplay called" -ForegroundColor Yellow
    $null = $Script:ToolsPanel.Children.Clear()
    
    $filteredTools = $Script:Tools | Where-Object { Test-ToolMatchesFilter $_ }
    
    if ($filteredTools.Count -eq 0) {
        $noResults = New-Object System.Windows.Controls.TextBlock
        $noResults.Text = "No tools match your search criteria"
        $noResults.FontSize = 16
        $noResults.Foreground = "#94A3B8"
        $noResults.Margin = "20,50,20,20"
        $noResults.TextAlignment = "Center"
        $null = $Script:ToolsPanel.Children.Add($noResults)
        
        $Script:StatusLabel.Text = "No tools found - try a different search or category"
        $Script:StatusLabel.Foreground = "#94A3B8"
        return
    }
    
    $Script:StatusLabel.Text = "Showing $($filteredTools.Count) tool(s) in '$Script:CurrentCategory' category"
    $Script:StatusLabel.Foreground = "#64748B"
    
    foreach ($tool in $filteredTools) {
        # Create tool card
        $card = New-Object System.Windows.Controls.Border
        $card.Style = $Script:Window.FindResource("ToolCard")
        $card.Height = 110
        
        $grid = New-Object System.Windows.Controls.Grid
        $col1 = New-Object System.Windows.Controls.ColumnDefinition
        $col1.Width = "80"
        $col2 = New-Object System.Windows.Controls.ColumnDefinition
        $col2.Width = "*"
        $col3 = New-Object System.Windows.Controls.ColumnDefinition
        $col3.Width = "150"
        $null = $grid.ColumnDefinitions.Add($col1)
        $null = $grid.ColumnDefinitions.Add($col2)
        $null = $grid.ColumnDefinitions.Add($col3)
        
        # Icon
        $iconBorder = New-Object System.Windows.Controls.Border
        $iconBorder.Width = 70
        $iconBorder.Height = 70
        $iconBorder.CornerRadius = 35
        $iconBorder.Background = $tool.Color
        $iconBorder.VerticalAlignment = "Center"
        $null = [System.Windows.Controls.Grid]::SetColumn($iconBorder, 0)
        
        $iconText = New-Object System.Windows.Controls.TextBlock
        $iconText.Text = $tool.Icon
        $iconText.FontSize = 32
        $iconText.HorizontalAlignment = "Center"
        $iconText.VerticalAlignment = "Center"
        $iconBorder.Child = $iconText
        
        # Info stack
        $infoStack = New-Object System.Windows.Controls.StackPanel
        $infoStack.Margin = "15,0,0,0"
        $infoStack.VerticalAlignment = "Center"
        $null = [System.Windows.Controls.Grid]::SetColumn($infoStack, 1)
        
        $nameText = New-Object System.Windows.Controls.TextBlock
        $nameText.Text = $tool.Name
        $nameText.FontSize = 16
        $nameText.FontWeight = "Bold"
        $nameText.Foreground = "#1E293B"
        
        $descText = New-Object System.Windows.Controls.TextBlock
        $descText.Text = $tool.Description
        $descText.FontSize = 12
        $descText.Foreground = "#64748B"
        $descText.TextWrapping = "Wrap"
        $descText.Margin = "0,5,0,0"
        
        $null = $infoStack.Children.Add($nameText)
        $null = $infoStack.Children.Add($descText)
        
        # Launch button
        $launchBtn = New-Object System.Windows.Controls.Button
        $launchBtn.Content = "Launch"
        $launchBtn.Style = $Script:Window.FindResource("ModernButton")
        $launchBtn.Width = 130
        $launchBtn.Height = 45
        $launchBtn.Background = $tool.Color
        $launchBtn.VerticalAlignment = "Center"
        $null = [System.Windows.Controls.Grid]::SetColumn($launchBtn, 2)
        
        $launchBtn.Tag = @{
            Script = $tool.Script
            Name = $tool.Name
        }
        
        $null = $launchBtn.Add_Click({
            $toolInfo = $this.Tag
            Start-Tool -ScriptName $toolInfo.Script -ToolName $toolInfo.Name
        })
        
        $null = $grid.Children.Add($iconBorder)
        $null = $grid.Children.Add($infoStack)
        $null = $grid.Children.Add($launchBtn)
        
        $card.Child = $grid
        $null = $Script:ToolsPanel.Children.Add($card)
    }
}

function Set-CategoryActive {
    param([string]$CategoryName)
    
    $Script:CurrentCategory = $CategoryName
    
    # Update button styles
    $categories = @{
        "All" = @{ Button = $Script:BtnCatAll; Color = "#6366f1" }
        "Network" = @{ Button = $Script:BtnCatNetwork; Color = "#3b82f6" }
        "Security" = @{ Button = $Script:BtnCatSecurity; Color = "#dc2626" }
        "Support" = @{ Button = $Script:BtnCatSupport; Color = "#10b981" }
        "Software" = @{ Button = $Script:BtnCatSoftware; Color = "#8b5cf6" }
        "M365" = @{ Button = $Script:BtnCatM365; Color = "#d97706" }
        "Hardware" = @{ Button = $Script:BtnCatHardware; Color = "#3498db" }
    }
    
    foreach ($cat in $categories.GetEnumerator()) {
        if ($cat.Key -eq $CategoryName) {
            $cat.Value.Button.Background = $cat.Value.Color
            $cat.Value.Button.Foreground = "White"
        } else {
            $cat.Value.Button.Background = "White"
            $cat.Value.Button.Foreground = $cat.Value.Color
        }
    }
    
    Update-ToolsDisplay
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

[xml]$xaml = Get-Content $xamlPath

$reader = New-Object System.Xml.XmlNodeReader $xaml
$Script:Window = [Windows.Markup.XamlReader]::Load($reader)

# ============================================================
# GET CONTROLS
# ============================================================

$Script:SearchBox = $Window.FindName("SearchBox")
$Script:ToolsPanel = $Window.FindName("ToolsPanel")
$Script:StatusLabel = $Window.FindName("StatusLabel")
$Script:AdminLabel = $Window.FindName("AdminLabel")

$Script:BtnCatAll = $Window.FindName("BtnCatAll")
$Script:BtnCatNetwork = $Window.FindName("BtnCatNetwork")
$Script:BtnCatSecurity = $Window.FindName("BtnCatSecurity")
$Script:BtnCatSupport = $Window.FindName("BtnCatSupport")
$Script:BtnCatSoftware = $Window.FindName("BtnCatSoftware")
$Script:BtnCatM365 = $Window.FindName("BtnCatM365")
$Script:BtnCatHardware = $Window.FindName("BtnCatHardware")

$MinimizeButton = $Window.FindName("MinimizeButton")
$CloseButton = $Window.FindName("CloseButton")
$HelpButton = $Window.FindName("HelpButton")
$AboutButton = $Window.FindName("AboutButton")
$GitHubButton = $Window.FindName("GitHubButton")
$WebsiteButton = $Window.FindName("WebsiteButton")
$ExitButton = $Window.FindName("ExitButton")

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
$null = $ExitButton.Add_Click({ $null = $Window.Close() })

# Search
$null = $SearchBox.Add_TextChanged({
    Update-ToolsDisplay
})

# Category buttons
$null = $BtnCatAll.Add_Click({ Set-CategoryActive "All" })
$null = $BtnCatNetwork.Add_Click({ Set-CategoryActive "Network" })
$null = $BtnCatSecurity.Add_Click({ Set-CategoryActive "Security" })
$null = $BtnCatSupport.Add_Click({ Set-CategoryActive "Support" })
$null = $BtnCatSoftware.Add_Click({ Set-CategoryActive "Software" })
$null = $BtnCatM365.Add_Click({ Set-CategoryActive "M365" })
$null = $BtnCatHardware.Add_Click({ Set-CategoryActive "Hardware" })

# Help button
$null = $HelpButton.Add_Click({
    $helpText = @"
SOULITEK ALL-IN-ONE SCRIPTS LAUNCHER

USAGE:
------
1. Click on any tool button to launch it
2. Each tool will open in a new PowerShell window
3. Use the search box to filter tools
4. Click category buttons to filter by category

TOOLS AVAILABLE: $($Script:Tools.Count)

TIPS:
-----
- Run as Administrator for full functionality
- All tools can run independently
- Some tools require Administrator privileges
- Check each tool's help menu for detailed instructions

SUPPORT:
--------
Website: www.soulitek.co.il
Email: letstalk@soulitek.co.il
GitHub: https://github.com/Soulitek/Soulitek-All-In-One-Scripts

====================================
"@
    
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

Made with love in Israel
"@
    
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

# Website button
$null = $WebsiteButton.Add_Click({
    Start-Process "www.soulitek.co.il"
})

# Admin status
if (Test-Administrator) {
    $AdminLabel.Text = "[+] Administrator"
    $AdminLabel.Foreground = "#10B981"
} else {
    $AdminLabel.Text = "[!] Not Administrator"
    $AdminLabel.Foreground = "#F59E0B"
}

# ============================================================
# INITIALIZE
# ============================================================

# Check if scripts directory exists
if (-not (Test-Path $Script:ScriptPath)) {
    [System.Windows.MessageBox]::Show(
        "Scripts directory not found!`n`nExpected location: $Script:ScriptPath`n`nPlease ensure the 'scripts' folder exists in the project root.",
        "Script Location Error",
        [System.Windows.MessageBoxButton]::OK,
        [System.Windows.MessageBoxImage]::Warning
    )
    exit
}

# Set initial category
Set-CategoryActive "All"

# Show welcome message
$null = $Window.Add_Loaded({
    if (-not (Test-Administrator)) {
        [System.Windows.MessageBox]::Show(
            "For best results, run this launcher as Administrator.`n`nSome tools require elevated privileges to function properly.",
            "Administrator Recommended",
            [System.Windows.MessageBoxButton]::OK,
            [System.Windows.MessageBoxImage]::Information
        )
    }
})

# Show window (suppress return value to prevent random numbers in console)
Write-Host "DEBUG: About to show window" -ForegroundColor Green
$null = $Window.ShowDialog()
Write-Host "DEBUG: Window closed" -ForegroundColor Green

