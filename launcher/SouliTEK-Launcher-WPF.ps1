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
        Icon = "[1C]"
        Description = "Automated PC setup - timezone, updates, software install"
        Script = "1-click_pc_install.ps1"
        Category = "Setup"
        Tags = @("setup", "install", "automation", "configure", "timezone", "regional", "updates", "power", "bloatware", "chrome", "anydesk", "office", "winget", "restore point")
        Color = "#10b981"
    },
    @{
        Name = "Essential Tweaks"
        Icon = "[ET]"
        Description = "Windows tweaks - default apps, keyboard, language, taskbar"
        Script = "essential_tweaks.ps1"
        Category = "Setup"
        Tags = @("tweaks", "settings", "default", "browser", "keyboard", "language", "taskbar", "chrome", "hebrew", "copilot", "acrobat", "pdf")
        Color = "#10b981"
    },
    @{
        Name = "Battery Report Generator"
        Icon = "[B]"
        Description = "Generate battery health reports for laptops"
        Script = "battery_report_generator.ps1"
        Category = "Hardware"
        Tags = @("battery", "laptop", "health", "report", "power")
        Color = "#3498db"
    },
    @{
        Name = "BitLocker Status Report"
        Icon = "[S]"
        Description = "Check BitLocker encryption status and recovery keys"
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
        Description = "Monitor M365 license subscriptions and expiration alerts"
        Script = "license_expiration_checker.ps1"
        Category = "M365"
        Tags = @("license", "microsoft", "365", "m365", "subscription", "expiration", "monitoring", "alerts")
        Color = "#f59e0b"
    },
    @{
        Name = "M365 User List"
        Icon = "[U]"
        Description = "List M365 users - email, phone, MFA status, user info"
        Script = "m365_user_list.ps1"
        Category = "M365"
        Tags = @("users", "microsoft", "365", "m365", "email", "phone", "mfa", "directory", "audit", "inventory")
        Color = "#3b82f6"
    },
    @{
        Name = "SharePoint Site Inventory"
        Icon = "[SP]"
        Description = "Map SharePoint sites - URLs, storage, owners, activity"
        Script = "sharepoint_site_inventory.ps1"
        Category = "M365"
        Tags = @("sharepoint", "sites", "microsoft", "365", "m365", "inventory", "audit", "storage", "owners", "groups", "template")
        Color = "#8b5cf6"
    },
    @{
        Name = "Exchange Online"
        Icon = "[EXO]"
        Description = "Collect Exchange mailbox info - aliases, protocols, activity"
        Script = "m365_exchange_online.ps1"
        Category = "M365"
        Tags = @("exchange", "online", "mailbox", "microsoft", "365", "m365", "email", "protocols", "imap", "pop", "ews", "activesync", "smtp", "mapi", "aliases", "license", "activity", "logon", "access", "size", "sendonbehalf")
        Color = "#8b5cf6"
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
        Name = "WiFi Monitor"
        Icon = "[WM]"
        Description = "Monitor WiFi signal strength, frequency bands, disconnections"
        Script = "wifi_monitor.ps1"
        Category = "Network"
        Tags = @("wifi", "monitor", "signal", "strength", "rssi", "2.4ghz", "5ghz", "frequency", "band", "ssid", "disconnection", "history", "network", "wireless", "troubleshoot")
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
        Name = "BSOD History Scanner"
        Icon = "[BSOD]"
        Description = "Scan minidump files and logs for BSOD history and codes"
        Script = "bsod_history_scanner.ps1"
        Category = "Support"
        Tags = @("bsod", "blue screen", "minidump", "bugcheck", "crash", "diagnostics", "troubleshoot", "error")
        Color = "#f39c12"
    },
    @{
        Name = "Network Test Tool"
        Icon = "[N]"
        Description = "Network diagnostics - ping, tracert, DNS lookup, latency"
        Script = "network_test_tool.ps1"
        Category = "Network"
        Tags = @("network", "ping", "tracert", "dns", "latency", "diagnostics")
        Color = "#3b82f6"
    },
    @{
        Name = "Network Configuration Tool"
        Icon = "[NC]"
        Description = "Configure IP settings, flush DNS, reset network adapters"
        Script = "network_configuration_tool.ps1"
        Category = "Network"
        Tags = @("network", "ip", "configuration", "static", "dns", "adapter", "reset", "dhcp")
        Color = "#6366f1"
    },
    @{
        Name = "USB Device Log"
        Icon = "[U]"
        Description = "Forensic USB device history analysis for security audits"
        Script = "usb_device_log.ps1"
        Category = "Security"
        Tags = @("usb", "forensics", "security", "audit", "device", "history")
        Color = "#ef4444"
    },
    @{
        Name = "Local Admin Users Checker"
        Icon = "[LA]"
        Description = "Identify unnecessary admin accounts and security risks"
        Script = "local_admin_checker.ps1"
        Category = "Security"
        Tags = @("admin", "administrator", "security", "privileges", "users", "attack vector", "audit", "permissions")
        Color = "#ef4444"
    },
    @{
        Name = "Product Key Retriever"
        Icon = "[PK]"
        Description = "Retrieve Windows and Office product keys from system"
        Script = "product_key_retriever.ps1"
        Category = "Support"
        Tags = @("product key", "windows", "office", "license", "activation", "registry", "wmi", "backup", "recovery")
        Color = "#10b981"
    },
    @{
        Name = "Softwares Installer"
        Icon = "[W]"
        Description = "Install essential business apps via WinGet"
        Script = "SouliTEK-Softwares-Installer.ps1"
        Category = "Setup"
        Tags = @("winget", "installer", "software", "packages", "apps", "install", "microsoft", "package manager")
        Color = "#10b981"
    },
    @{
        Name = "Storage Health Monitor"
        Icon = "[SH]"
        Description = "Monitor storage health with SMART data and error detection"
        Script = "storage_health_monitor.ps1"
        Category = "Hardware"
        Tags = @("storage", "smart", "disk", "health", "monitor", "hdd", "ssd", "sectors", "errors")
        Color = "#06b6d4"
    },
    @{
        Name = "System Restore Point"
        Icon = "[T]"
        Description = "Create Windows System Restore Points for recovery"
        Script = "create_system_restore_point.ps1"
        Category = "Support"
        Tags = @("restore", "system", "recovery", "backup", "rollback", "protection")
        Color = "#f59e0b"
    },
    @{
        Name = "RAM Slot Utilization Report"
        Icon = "[RAM]"
        Description = "Show RAM slots, type (DDR3/4/5), speed, and capacity"
        Script = "ram_slot_utilization_report.ps1"
        Category = "Hardware"
        Tags = @("ram", "memory", "hardware", "ddr", "slots", "capacity", "speed")
        Color = "#3498db"
    },
    @{
        Name = "Disk Usage Analyzer"
        Icon = "[D]"
        Description = "Find large folders and export size reports with HTML"
        Script = "disk_usage_analyzer.ps1"
        Category = "Hardware"
        Tags = @("disk", "usage", "storage", "folders", "size", "cleanup", "analysis")
        Color = "#06b6d4"
    },
    @{
        Name = "Startup & Boot Time Analyzer"
        Icon = "[⚡]"
        Description = "Analyze startup programs and boot performance with reports"
        Script = "startup_boot_analyzer.ps1"
        Category = "Performance"
        Tags = @("startup", "boot", "performance", "optimization", "services", "task scheduler", "analysis", "speed")
        Color = "#f59e0b"
    },
    @{
        Name = "Temp Removal & Disk Cleanup"
        Icon = "[CL]"
        Description = "Remove temp files, clean cache, empty Recycle Bin"
        Script = "temp_removal_disk_cleanup.ps1"
        Category = "Support"
        Tags = @("temp", "cleanup", "disk", "space", "browser", "cache", "recycle", "bin", "maintenance")
        Color = "#10b981"
    },
    @{
        Name = "McAfee Removal Tool"
        Icon = "[MCPR]"
        Description = "Complete removal of McAfee products using MCPR tool"
        Script = "mcafee_removal_tool.ps1"
        Category = "Support"
        Tags = @("mcafee", "removal", "mcpr", "antivirus", "uninstall", "cleanup", "security", "removal tool")
        Color = "#ef4444"
    },
    @{
        Name = "Win11Debloat"
        Icon = "[W11]"
        Description = "Remove bloatware, disable telemetry, optimize Windows 10/11"
        Script = "win11_debloat.ps1"
        Category = "Setup"
        Tags = @("debloat", "bloatware", "telemetry", "optimization", "windows", "privacy", "cleanup", "registry", "win11", "win10")
        Color = "#8b5cf6"
    },
    @{
        Name = "Software Updater"
        Icon = "[UPD]"
        Description = "Manage software updates via WinGet - check, auto-update"
        Script = "software_updater.ps1"
        Category = "Setup"
        Tags = @("winget", "update", "software", "upgrade", "maintenance", "packages", "automatic", "interactive")
        Color = "#10b981"
    },
    @{
        Name = "Domain & DNS Analyzer"
        Icon = "[DNS]"
        Description = "WHOIS lookup, DNS analysis, email security (SPF/DKIM/DMARC)"
        Script = "domain_dns_analyzer.ps1"
        Category = "Internet"
        Tags = @("dns", "whois", "domain", "spf", "dkim", "dmarc", "email", "security", "mx", "records", "rdap")
        Color = "#0ea5e9"
    },
    @{
        Name = "VirusTotal Checker"
        Icon = "[VT]"
        Description = "Check files and URLs against VirusTotal for malware"
        Script = "virustotal_checker.ps1"
        Category = "Security"
        Tags = @("virustotal", "malware", "virus", "scan", "hash", "url", "security", "threat", "detection", "file check")
        Color = "#ef4444"
    },
    @{
        Name = "Browser Plugin Checker"
        Icon = "[BP]"
        Description = "Scan browser extensions for security risks"
        Script = "browser_plugin_checker.ps1"
        Category = "Security"
        Tags = @("browser", "extension", "plugin", "addon", "chrome", "firefox", "edge", "security", "permissions", "malware")
        Color = "#ef4444"
    },
    @{
        Name = "OneDrive Status Checker"
        Icon = "[OD]"
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
        $Script:StatusLabel.Foreground = "#6366F1"
    }
    catch {
        [System.Windows.MessageBox]::Show(
            "Failed to launch $ToolName`n`nError: $_",
            "Launch Error",
            [System.Windows.MessageBoxButton]::OK,
            [System.Windows.MessageBoxImage]::Error
        )
        
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
        $noResults.Foreground = "#A1A1AA"
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
        
        $nameText = New-Object System.Windows.Controls.TextBlock
        $nameText.Text = $tool.Name
        $nameText.FontSize = 16
        $nameText.FontWeight = "SemiBold"
        $nameText.FontFamily = "Segoe UI"
        $nameText.Foreground = "#27272A"
        $nameText.Margin = "0,0,0,4"
        $nameText.TextWrapping = "Wrap"
        
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
        $descText.Foreground = "#71717A"
        $descText.TextWrapping = "Wrap"
        
        $null = $infoStack.Children.Add($nameText)
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

function Set-CategoryActive {
    param([string]$CategoryName)
    
    $Script:CurrentCategory = $CategoryName
    
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
        if ($cat.Key -eq $CategoryName) {
            # Set active style
            $cat.Value.Style = $Script:Window.FindResource("CategoryButtonActive")
            $cat.Value.Background = "#4F46E5"
            $cat.Value.Foreground = "White"
        } else {
            # Set inactive style
            $cat.Value.Style = $Script:Window.FindResource("CategoryButtonInactive")
            $cat.Value.Background = "#71717A"
            $cat.Value.Foreground = "White"
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
            Message = "System Restore Point created successfully!`n`nDescription: $description"
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
                [System.Windows.MessageBox]::Show(
                    $createResult.Message,
                    "Restore Point Created",
                    [System.Windows.MessageBoxButton]::OK,
                    [System.Windows.MessageBoxImage]::Information
                )
            } else {
                [System.Windows.MessageBox]::Show(
                    $createResult.Message,
                    "Restore Point Creation Failed",
                    [System.Windows.MessageBoxButton]::OK,
                    [System.Windows.MessageBoxImage]::Warning
                )
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
                
                # Show error message
                [System.Windows.MessageBox]::Show(
                    "Uninstallation completed with errors:`n`n$($errors -join "`n")`n`nSome files may still be in use. Please close any PowerShell windows running SouliTEK scripts and try again.",
                    "Uninstallation Warning",
                    [System.Windows.MessageBoxButton]::OK,
                    [System.Windows.MessageBoxImage]::Warning
                )
                return
            }
        }
        
        # Success message
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

[xml]$xaml = Get-Content $xamlPath

$reader = New-Object System.Xml.XmlNodeReader $xaml
$Script:Window = [Windows.Markup.XamlReader]::Load($reader)

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

$MinimizeButton = $Window.FindName("MinimizeButton")
$CloseButton = $Window.FindName("CloseButton")
$HelpButton = $Window.FindName("HelpButton")
$AboutButton = $Window.FindName("AboutButton")
$GitHubButton = $Window.FindName("GitHubButton")
$DiscordButton = $Window.FindName("DiscordButton")
$SelfDestructButton = $Window.FindName("SelfDestructButton")

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

# Show welcome message and restore point warning
$null = $Window.Add_Loaded({
    # Show restore point warning first
    Show-RestorePointWarning
    
    # Then show admin warning if not running as admin
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
$null = $Window.ShowDialog()

