# ============================================================
# 1-Click PC Install - Complete PC Setup Automation
# ============================================================
# 
# Coded by: Soulitek.co.il
# IT Solutions for your business
# 
# (C) 2025 Soulitek - All Rights Reserved
# Website: www.soulitek.co.il
# 
# Professional IT Solutions:
# - Computer Repair & Maintenance
# - Network Setup & Support
# - Software Solutions
# - Business IT Consulting
# 
# This tool automates the complete PC setup process including:
# - Time zone and regional settings
# - Windows updates
# - Power plan optimization
# - Bloatware removal
# - Software installation
# - System restore point creation
# 
# Features: One-Click Setup | Complete Automation | Detailed Summary
# 
# ============================================================
# 
# IMPORTANT DISCLAIMER:
# This tool is provided "AS IS" without warranty of any kind.
# Use of this tool is at your own risk. The user is solely
# responsible for any outcomes, damages, or issues that may
# arise from using this script. By running this tool, you
# acknowledge and accept full responsibility for its use.
# 
# ============================================================

#Requires -Version 5.1

# Set window title
$Host.UI.RawUI.WindowTitle = "1-CLICK PC INSTALL"

# Import SouliTEK Common Functions
$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$CommonPath = Join-Path (Split-Path -Parent $ScriptRoot) "modules\SouliTEK-Common.ps1"
if (Test-Path $CommonPath) {
    . $CommonPath
} else {
    Write-Warning "SouliTEK Common Functions not found at: $CommonPath"
    Write-Warning "Some functions may not work properly."
}

# ============================================================
# GLOBAL VARIABLES
# ============================================================

$Script:InstallLog = @()
$Script:StartTime = Get-Date
$Script:ErrorCount = 0
$Script:SuccessCount = 0
$Script:WarningCount = 0

# ============================================================
# HELPER FUNCTIONS
# ============================================================

function Show-Header {
    param([string]$Title = "1-CLICK PC INSTALL", [ConsoleColor]$Color = 'Cyan')
    
    Clear-Host
    Show-SouliTEKBanner
    Write-Host "============================================================" -ForegroundColor $Color
    Write-Host ""
    Write-Host "  $Title" -ForegroundColor $Color
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor $Color
    Write-Host ""
}

function Add-LogEntry {
    param(
        [string]$Task,
        [string]$Status,
        [string]$Details = ""
    )
    
    $Script:InstallLog += [PSCustomObject]@{
        Task = $Task
        Status = $Status
        Details = $Details
        Time = Get-Date -Format "HH:mm:ss"
    }
    
    switch ($Status) {
        "SUCCESS" { $Script:SuccessCount++ }
        "ERROR" { $Script:ErrorCount++ }
        "WARNING" { $Script:WarningCount++ }
    }
}

function Show-TaskList {
    <#
    .SYNOPSIS
        Displays all tasks that will be performed during the 1-click install.
    #>
    
    Show-Header "1-CLICK PC INSTALL - TASK OVERVIEW"
    
    Write-Host "  The following tasks will be performed:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  [1]  Set Time Zone" -ForegroundColor Cyan
    Write-Host "       └─ Configure time zone to Jerusalem (Israel Standard Time)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  [2]  Configure Regional Settings" -ForegroundColor Cyan
    Write-Host "       └─ Set regional format, location, and language to Israel/Hebrew" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  [3]  Create System Restore Point" -ForegroundColor Cyan
    Write-Host "       └─ Create a backup point before making system changes" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  [4]  Check and Install Windows Updates" -ForegroundColor Cyan
    Write-Host "       └─ Download and install all available Windows updates" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  [5]  Configure Power Plan" -ForegroundColor Cyan
    Write-Host "       └─ Set power plan to High Performance for best performance" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  [6]  Remove Bloatware" -ForegroundColor Cyan
    Write-Host "       └─ Remove unnecessary pre-installed Windows applications" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  [7]  Install Google Chrome" -ForegroundColor Cyan
    Write-Host "       └─ Install Google Chrome web browser via WinGet" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  [8]  Install AnyDesk" -ForegroundColor Cyan
    Write-Host "       └─ Install AnyDesk remote desktop software via WinGet" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  [9]  Install Microsoft Office" -ForegroundColor Cyan
    Write-Host "       └─ Install Microsoft Office suite (if available)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  [10] Generate Installation Summary" -ForegroundColor Cyan
    Write-Host "       └─ Create detailed report of all actions performed" -ForegroundColor Gray
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  IMPORTANT NOTES:" -ForegroundColor Red
    Write-Host "  • This process may take 30-60 minutes to complete" -ForegroundColor Yellow
    Write-Host "  • Your computer may restart during Windows updates" -ForegroundColor Yellow
    Write-Host "  • Administrator privileges are required" -ForegroundColor Yellow
    Write-Host "  • Active internet connection is required" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Yellow
    Write-Host ""
}

function Get-UserApproval {
    <#
    .SYNOPSIS
        Prompts user for approval before proceeding with installation.
    #>
    
    Write-Host "  Do you want to proceed with the 1-Click PC Install?" -ForegroundColor White
    Write-Host ""
    Write-Host "  [Y] Yes - Start the installation" -ForegroundColor Green
    Write-Host "  [N] No  - Cancel and exit" -ForegroundColor Red
    Write-Host ""
    Write-Host -NoNewline "  Enter your choice: " -ForegroundColor Cyan
    
    $choice = Read-Host
    
    if ($choice -eq 'Y' -or $choice -eq 'y') {
        return $true
    } else {
        Write-Host ""
        Write-Host "  Installation cancelled by user." -ForegroundColor Yellow
        Write-Host ""
        return $false
    }
}

function Set-TimeZoneToJerusalem {
    <#
    .SYNOPSIS
        Sets the system time zone to Jerusalem (Israel Standard Time).
    #>
    
    Show-Header "SETTING TIME ZONE"
    Write-SouliTEKInfo "Configuring time zone to Jerusalem..."
    
    try {
        $currentTimeZone = Get-TimeZone
        Write-Host "  Current Time Zone: $($currentTimeZone.DisplayName)" -ForegroundColor Gray
        
        # Set to Israel Standard Time
        Set-TimeZone -Id "Israel Standard Time" -ErrorAction Stop
        
        $newTimeZone = Get-TimeZone
        Write-SouliTEKSuccess "Time zone set to: $($newTimeZone.DisplayName)"
        Add-LogEntry -Task "Set Time Zone" -Status "SUCCESS" -Details "Changed to $($newTimeZone.DisplayName)"
        
        Start-Sleep -Seconds 2
        return $true
    }
    catch {
        Write-SouliTEKError "Failed to set time zone: $($_.Exception.Message)"
        Add-LogEntry -Task "Set Time Zone" -Status "ERROR" -Details $_.Exception.Message
        Start-Sleep -Seconds 3
        return $false
    }
}

function Set-RegionalSettingsToIsrael {
    <#
    .SYNOPSIS
        Configures regional settings for Israel including format, location, and language.
    #>
    
    Show-Header "CONFIGURING REGIONAL SETTINGS"
    Write-SouliTEKInfo "Setting regional format to Israel..."
    
    try {
        # Set regional format to Hebrew (Israel)
        Write-Host "  [*] Setting regional format..." -ForegroundColor Cyan
        Set-Culture -CultureInfo "he-IL" -ErrorAction Stop
        
        # Set GeoLocation to Israel
        Write-Host "  [*] Setting geographic location..." -ForegroundColor Cyan
        Set-WinHomeLocation -GeoId 117 -ErrorAction Stop  # 117 is Israel
        
        # Set system locale to Hebrew
        Write-Host "  [*] Configuring system locale..." -ForegroundColor Cyan
        Set-WinSystemLocale -SystemLocale "he-IL" -ErrorAction Stop
        
        # Set user language list
        Write-Host "  [*] Setting user language preferences..." -ForegroundColor Cyan
        $languageList = Get-WinUserLanguageList
        if (-not ($languageList | Where-Object { $_.LanguageTag -eq "he-IL" })) {
            $languageList.Add("he-IL")
            Set-WinUserLanguageList $languageList -Force -ErrorAction Stop
        }
        
        Write-SouliTEKSuccess "Regional settings configured for Israel"
        Add-LogEntry -Task "Regional Settings" -Status "SUCCESS" -Details "Configured for Israel (Hebrew)"
        
        Write-Host ""
        Write-Host "  NOTE: Some changes may require a system restart to take full effect." -ForegroundColor Yellow
        
        Start-Sleep -Seconds 3
        return $true
    }
    catch {
        Write-SouliTEKError "Failed to set regional settings: $($_.Exception.Message)"
        Add-LogEntry -Task "Regional Settings" -Status "ERROR" -Details $_.Exception.Message
        Start-Sleep -Seconds 3
        return $false
    }
}

function New-SystemRestorePoint {
    <#
    .SYNOPSIS
        Creates a system restore point before making changes.
    #>
    
    Show-Header "CREATING SYSTEM RESTORE POINT"
    Write-SouliTEKInfo "Creating system restore point..."
    
    try {
        # Check if System Restore is enabled
        $systemDrive = $env:SystemDrive
        $restoreEnabled = Get-ComputerRestorePoint -ErrorAction SilentlyContinue
        
        if (-not $restoreEnabled) {
            Write-SouliTEKWarning "System Restore may not be enabled"
            Write-Host "  Attempting to enable System Restore..." -ForegroundColor Yellow
            
            try {
                Enable-ComputerRestore -Drive "$systemDrive\" -ErrorAction Stop
                Start-Sleep -Seconds 2
            }
            catch {
                Write-SouliTEKWarning "Could not enable System Restore automatically"
            }
        }
        
        # Create restore point
        $description = "1-Click PC Install - Before Setup ($(Get-Date -Format 'yyyy-MM-dd HH:mm'))"
        Write-Host "  Creating restore point: $description" -ForegroundColor Cyan
        
        Checkpoint-Computer -Description $description -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop
        
        Write-SouliTEKSuccess "System restore point created successfully"
        Add-LogEntry -Task "System Restore Point" -Status "SUCCESS" -Details $description
        
        Start-Sleep -Seconds 2
        return $true
    }
    catch {
        Write-SouliTEKWarning "Could not create system restore point: $($_.Exception.Message)"
        Add-LogEntry -Task "System Restore Point" -Status "WARNING" -Details $_.Exception.Message
        
        Write-Host ""
        Write-Host "  Continuing anyway... (This is not critical)" -ForegroundColor Yellow
        
        Start-Sleep -Seconds 3
        return $false
    }
}

function Install-WindowsUpdates {
    <#
    .SYNOPSIS
        Checks for and installs Windows updates.
    #>
    
    Show-Header "CHECKING WINDOWS UPDATES"
    Write-SouliTEKInfo "Checking for available Windows updates..."
    
    try {
        # Check if PSWindowsUpdate module is available
        $psWindowsUpdate = Get-Module -Name PSWindowsUpdate -ListAvailable
        
        if (-not $psWindowsUpdate) {
            Write-Host "  [*] Installing PSWindowsUpdate module..." -ForegroundColor Cyan
            
            # Ensure NuGet provider
            $nuget = Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue
            if (-not $nuget) {
                Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope CurrentUser | Out-Null
            }
            
            Install-Module -Name PSWindowsUpdate -Force -Scope CurrentUser -ErrorAction Stop
            Import-Module PSWindowsUpdate -Force
        } else {
            Import-Module PSWindowsUpdate -Force
        }
        
        Write-Host "  [*] Scanning for updates..." -ForegroundColor Cyan
        $updates = Get-WindowsUpdate -MicrosoftUpdate -ErrorAction Stop
        
        if ($updates.Count -eq 0) {
            Write-SouliTEKSuccess "Windows is up to date - no updates available"
            Add-LogEntry -Task "Windows Updates" -Status "SUCCESS" -Details "System is up to date"
        } else {
            Write-Host "  [*] Found $($updates.Count) update(s)" -ForegroundColor Yellow
            Write-Host "  [*] Installing updates (this may take a while)..." -ForegroundColor Cyan
            
            Install-WindowsUpdate -MicrosoftUpdate -AcceptAll -AutoReboot:$false -ErrorAction Stop
            
            Write-SouliTEKSuccess "Windows updates installed successfully"
            Add-LogEntry -Task "Windows Updates" -Status "SUCCESS" -Details "Installed $($updates.Count) update(s)"
            
            Write-Host ""
            Write-Host "  NOTE: You may need to restart your computer to complete update installation." -ForegroundColor Yellow
        }
        
        Start-Sleep -Seconds 3
        return $true
    }
    catch {
        Write-SouliTEKWarning "Could not install Windows updates: $($_.Exception.Message)"
        Add-LogEntry -Task "Windows Updates" -Status "WARNING" -Details $_.Exception.Message
        
        Write-Host ""
        Write-Host "  TIP: You can manually check for updates via Windows Settings" -ForegroundColor Yellow
        
        Start-Sleep -Seconds 3
        return $false
    }
}

function Set-PowerPlanToBest {
    <#
    .SYNOPSIS
        Configures the power plan to High Performance for best performance.
    #>
    
    Show-Header "CONFIGURING POWER PLAN"
    Write-SouliTEKInfo "Setting power plan to High Performance..."
    
    try {
        # Get High Performance power plan GUID
        $highPerfPlan = powercfg /list | Select-String "High performance" -Context 0,0
        
        if (-not $highPerfPlan) {
            # Try to get Ultimate Performance if available
            $ultimatePlan = powercfg /list | Select-String "Ultimate Performance" -Context 0,0
            
            if ($ultimatePlan) {
                $planGuid = $ultimatePlan -match '([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12})'
                $planGuid = $matches[1]
                powercfg /setactive $planGuid
                Write-SouliTEKSuccess "Power plan set to Ultimate Performance"
                Add-LogEntry -Task "Power Plan" -Status "SUCCESS" -Details "Set to Ultimate Performance"
            } else {
                # Create High Performance plan if it doesn't exist
                Write-Host "  [*] High Performance plan not found, creating it..." -ForegroundColor Yellow
                powercfg /duplicatescheme 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
                
                $highPerfPlan = powercfg /list | Select-String "High performance" -Context 0,0
                if ($highPerfPlan -match '([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12})') {
                    $planGuid = $matches[1]
                    powercfg /setactive $planGuid
                    Write-SouliTEKSuccess "Power plan set to High Performance"
                    Add-LogEntry -Task "Power Plan" -Status "SUCCESS" -Details "Set to High Performance"
                }
            }
        } else {
            if ($highPerfPlan -match '([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12})') {
                $planGuid = $matches[1]
                powercfg /setactive $planGuid
                Write-SouliTEKSuccess "Power plan set to High Performance"
                Add-LogEntry -Task "Power Plan" -Status "SUCCESS" -Details "Set to High Performance"
            }
        }
        
        # Display current power plan
        $activePlan = powercfg /getactivescheme
        Write-Host "  Current Power Plan: " -NoNewline -ForegroundColor Gray
        Write-Host "$activePlan" -ForegroundColor Cyan
        
        Start-Sleep -Seconds 2
        return $true
    }
    catch {
        Write-SouliTEKError "Failed to set power plan: $($_.Exception.Message)"
        Add-LogEntry -Task "Power Plan" -Status "ERROR" -Details $_.Exception.Message
        Start-Sleep -Seconds 3
        return $false
    }
}

function Remove-Bloatware {
    <#
    .SYNOPSIS
        Removes unnecessary pre-installed Windows applications (bloatware).
    #>
    
    Show-Header "REMOVING BLOATWARE"
    Write-SouliTEKInfo "Removing unnecessary Windows applications..."
    
    # List of common bloatware apps to remove
    $bloatwareApps = @(
        "Microsoft.3DBuilder",
        "Microsoft.BingNews",
        "Microsoft.BingWeather",
        "Microsoft.GetHelp",
        "Microsoft.Getstarted",
        "Microsoft.Messaging",
        "Microsoft.Microsoft3DViewer",
        "Microsoft.MicrosoftOfficeHub",
        "Microsoft.MicrosoftSolitaireCollection",
        "Microsoft.MixedReality.Portal",
        "Microsoft.OneConnect",
        "Microsoft.People",
        "Microsoft.Print3D",
        "Microsoft.SkypeApp",
        "Microsoft.Wallet",
        "Microsoft.WindowsAlarms",
        "Microsoft.WindowsFeedbackHub",
        "Microsoft.WindowsMaps",
        "Microsoft.Xbox.TCUI",
        "Microsoft.XboxApp",
        "Microsoft.XboxGameOverlay",
        "Microsoft.XboxGamingOverlay",
        "Microsoft.XboxIdentityProvider",
        "Microsoft.XboxSpeechToTextOverlay",
        "Microsoft.YourPhone",
        "Microsoft.ZuneMusic",
        "Microsoft.ZuneVideo"
    )
    
    $removedCount = 0
    $failedCount = 0
    
    try {
        foreach ($app in $bloatwareApps) {
            Write-Host "  [*] Checking $app..." -ForegroundColor Cyan
            
            $package = Get-AppxPackage -Name $app -ErrorAction SilentlyContinue
            
            if ($package) {
                try {
                    Remove-AppxPackage -Package $package.PackageFullName -ErrorAction Stop
                    Write-Host "      └─ Removed" -ForegroundColor Green
                    $removedCount++
                }
                catch {
                    Write-Host "      └─ Failed to remove" -ForegroundColor Red
                    $failedCount++
                }
            } else {
                Write-Host "      └─ Not installed" -ForegroundColor Gray
            }
        }
        
        Write-Host ""
        Write-SouliTEKSuccess "Bloatware removal complete"
        Write-Host "  Removed: $removedCount app(s)" -ForegroundColor Green
        
        if ($failedCount -gt 0) {
            Write-Host "  Failed: $failedCount app(s)" -ForegroundColor Yellow
        }
        
        Add-LogEntry -Task "Remove Bloatware" -Status "SUCCESS" -Details "Removed $removedCount app(s), Failed: $failedCount"
        
        Start-Sleep -Seconds 3
        return $true
    }
    catch {
        Write-SouliTEKError "Error during bloatware removal: $($_.Exception.Message)"
        Add-LogEntry -Task "Remove Bloatware" -Status "ERROR" -Details $_.Exception.Message
        Start-Sleep -Seconds 3
        return $false
    }
}

function Install-WinGetApplication {
    <#
    .SYNOPSIS
        Installs an application using WinGet.
    #>
    
    param(
        [Parameter(Mandatory = $true)]
        [string]$AppName,
        
        [Parameter(Mandatory = $true)]
        [string]$WinGetId
    )
    
    Write-Host "  [*] Checking if $AppName is already installed..." -ForegroundColor Cyan
    
    # Check if app is already installed
    $installedApps = winget list --id $WinGetId 2>&1
    
    if ($installedApps -match $WinGetId) {
        Write-Host "      └─ $AppName is already installed" -ForegroundColor Yellow
        return "ALREADY_INSTALLED"
    }
    
    Write-Host "  [*] Installing $AppName..." -ForegroundColor Cyan
    
    try {
        $result = winget install --id $WinGetId --silent --accept-package-agreements --accept-source-agreements 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "      └─ $AppName installed successfully" -ForegroundColor Green
            return "SUCCESS"
        } else {
            Write-Host "      └─ Failed to install $AppName" -ForegroundColor Red
            return "ERROR"
        }
    }
    catch {
        Write-Host "      └─ Error installing $AppName : $($_.Exception.Message)" -ForegroundColor Red
        return "ERROR"
    }
}

function Ensure-WinGet {
    <#
    .SYNOPSIS
        Ensures WinGet is installed and available.
    #>
    
    Write-Host "  [*] Checking WinGet installation..." -ForegroundColor Cyan
    
    $wingetCmd = Get-Command winget.exe -ErrorAction SilentlyContinue
    if ($wingetCmd) {
        Write-Host "      └─ WinGet is available" -ForegroundColor Green
        return $true
    }
    
    Write-Host "      └─ WinGet not found" -ForegroundColor Yellow
    Write-Host "  [*] Attempting to install WinGet..." -ForegroundColor Cyan
    
    try {
        # Install Microsoft.WinGet.Client module
        $nuget = Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue
        if (-not $nuget) {
            Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope CurrentUser | Out-Null
        }
        
        Install-Module -Name Microsoft.WinGet.Client -Force -Scope CurrentUser -ErrorAction Stop
        Import-Module -Name Microsoft.WinGet.Client -Force -ErrorAction Stop
        
        # Repair WinGet
        Repair-WinGetPackageManager -ErrorAction Stop
        
        Write-Host "      └─ WinGet installed successfully" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "      └─ Failed to install WinGet: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

function Install-Applications {
    <#
    .SYNOPSIS
        Installs Google Chrome, AnyDesk, and Office using WinGet.
    #>
    
    Show-Header "INSTALLING APPLICATIONS"
    
    # Ensure WinGet is available
    if (-not (Ensure-WinGet)) {
        Write-SouliTEKError "WinGet is not available. Cannot install applications."
        Add-LogEntry -Task "Install Applications" -Status "ERROR" -Details "WinGet not available"
        Start-Sleep -Seconds 3
        return $false
    }
    
    Write-Host ""
    Write-SouliTEKInfo "Installing applications via WinGet..."
    Write-Host ""
    
    # Install Google Chrome
    Write-Host "  [1/3] Google Chrome" -ForegroundColor Yellow
    $chromeResult = Install-WinGetApplication -AppName "Google Chrome" -WinGetId "Google.Chrome"
    Add-LogEntry -Task "Install Google Chrome" -Status $chromeResult -Details "WinGet ID: Google.Chrome"
    
    Write-Host ""
    
    # Install AnyDesk
    Write-Host "  [2/3] AnyDesk" -ForegroundColor Yellow
    $anydeskResult = Install-WinGetApplication -AppName "AnyDesk" -WinGetId "AnyDeskSoftwareGmbH.AnyDesk"
    Add-LogEntry -Task "Install AnyDesk" -Status $anydeskResult -Details "WinGet ID: AnyDeskSoftwareGmbH.AnyDesk"
    
    Write-Host ""
    
    # Install Office
    Write-Host "  [3/3] Microsoft Office" -ForegroundColor Yellow
    Write-Host "  [*] Checking for Office installation..." -ForegroundColor Cyan
    
    # Check if Office is already installed
    $officeInstalled = $false
    $officePaths = @(
        "C:\Program Files\Microsoft Office",
        "C:\Program Files (x86)\Microsoft Office",
        "${env:ProgramFiles}\Microsoft Office\root\Office16",
        "${env:ProgramFiles(x86)}\Microsoft Office\root\Office16"
    )
    
    foreach ($path in $officePaths) {
        if (Test-Path $path) {
            Write-Host "      └─ Microsoft Office is already installed" -ForegroundColor Yellow
            $officeInstalled = $true
            Add-LogEntry -Task "Install Microsoft Office" -Status "ALREADY_INSTALLED" -Details "Office found at: $path"
            break
        }
    }
    
    if (-not $officeInstalled) {
        Write-Host "  [*] Office not found. Attempting installation..." -ForegroundColor Cyan
        Write-Host "  [!] Note: Office installation via WinGet may require manual setup" -ForegroundColor Yellow
        
        # Try to install Office via WinGet (this may not always work)
        $officeResult = Install-WinGetApplication -AppName "Microsoft Office" -WinGetId "Microsoft.Office"
        
        if ($officeResult -eq "ERROR") {
            Write-Host ""
            Write-Host "  [!] Automatic Office installation failed" -ForegroundColor Yellow
            Write-Host "  [!] Please install Office manually from:" -ForegroundColor Yellow
            Write-Host "      https://www.office.com/setup" -ForegroundColor Cyan
            Add-LogEntry -Task "Install Microsoft Office" -Status "WARNING" -Details "Manual installation required"
        } else {
            Add-LogEntry -Task "Install Microsoft Office" -Status $officeResult -Details "WinGet ID: Microsoft.Office"
        }
    }
    
    Write-Host ""
    Write-SouliTEKSuccess "Application installation process complete"
    
    Start-Sleep -Seconds 3
    return $true
}

function Show-InstallationSummary {
    <#
    .SYNOPSIS
        Generates and displays a detailed installation summary.
    #>
    
    Show-Header "INSTALLATION SUMMARY"
    
    $endTime = Get-Date
    $duration = $endTime - $Script:StartTime
    
    Write-Host "  Installation completed at: " -NoNewline -ForegroundColor Gray
    Write-Host "$($endTime.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Cyan
    
    Write-Host "  Total duration: " -NoNewline -ForegroundColor Gray
    Write-Host "$([math]::Round($duration.TotalMinutes, 2)) minutes" -ForegroundColor Cyan
    
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  RESULTS SUMMARY" -ForegroundColor White
    Write-Host ""
    Write-Host "  Successful: " -NoNewline -ForegroundColor Gray
    Write-Host "$Script:SuccessCount task(s)" -ForegroundColor Green
    
    Write-Host "  Warnings: " -NoNewline -ForegroundColor Gray
    Write-Host "$Script:WarningCount task(s)" -ForegroundColor Yellow
    
    Write-Host "  Errors: " -NoNewline -ForegroundColor Gray
    Write-Host "$Script:ErrorCount task(s)" -ForegroundColor Red
    
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  DETAILED TASK LOG" -ForegroundColor White
    Write-Host ""
    
    foreach ($entry in $Script:InstallLog) {
        $statusColor = switch ($entry.Status) {
            "SUCCESS" { "Green" }
            "ALREADY_INSTALLED" { "Yellow" }
            "WARNING" { "Yellow" }
            "ERROR" { "Red" }
            default { "Gray" }
        }
        
        $statusSymbol = switch ($entry.Status) {
            "SUCCESS" { "[+]" }
            "ALREADY_INSTALLED" { "[~]" }
            "WARNING" { "[!]" }
            "ERROR" { "[-]" }
            default { "[*]" }
        }
        
        Write-Host "  [$($entry.Time)] " -NoNewline -ForegroundColor Gray
        Write-Host "$statusSymbol " -NoNewline -ForegroundColor $statusColor
        Write-Host "$($entry.Task)" -ForegroundColor White
        
        if ($entry.Details) {
            Write-Host "      └─ $($entry.Details)" -ForegroundColor Gray
        }
    }
    
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    
    # Save summary to desktop
    $summaryPath = "$env:USERPROFILE\Desktop\1-Click-PC-Install-Summary.txt"
    
    try {
        $summaryContent = @"
============================================================
1-CLICK PC INSTALL - INSTALLATION SUMMARY
============================================================

Installation Date: $($endTime.ToString('yyyy-MM-dd HH:mm:ss'))
Duration: $([math]::Round($duration.TotalMinutes, 2)) minutes

RESULTS:
- Successful: $Script:SuccessCount task(s)
- Warnings: $Script:WarningCount task(s)
- Errors: $Script:ErrorCount task(s)

DETAILED LOG:
============================================================

"@
        
        foreach ($entry in $Script:InstallLog) {
            $summaryContent += "[$($entry.Time)] [$($entry.Status)] $($entry.Task)`r`n"
            if ($entry.Details) {
                $summaryContent += "  └─ $($entry.Details)`r`n"
            }
            $summaryContent += "`r`n"
        }
        
        $summaryContent += @"
============================================================
Generated by SouliTEK All-In-One Scripts
Website: www.soulitek.co.il
Email: letstalk@soulitek.co.il
(C) 2025 SouliTEK - All Rights Reserved
============================================================
"@
        
        $summaryContent | Out-File -FilePath $summaryPath -Encoding UTF8
        
        Write-Host "  Summary saved to: " -NoNewline -ForegroundColor Gray
        Write-Host "$summaryPath" -ForegroundColor Cyan
        Write-Host ""
    }
    catch {
        Write-Host "  [!] Could not save summary to desktop" -ForegroundColor Yellow
    }
    
    Write-Host ""
    Write-Host "  RECOMMENDED NEXT STEPS:" -ForegroundColor Yellow
    Write-Host "  • Restart your computer to apply all changes" -ForegroundColor White
    Write-Host "  • Review the installation summary above" -ForegroundColor White
    Write-Host "  • Verify all installed applications work correctly" -ForegroundColor White
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
}

# ============================================================
# MAIN EXECUTION
# ============================================================

function Start-OneClickPCInstall {
    <#
    .SYNOPSIS
        Main function that orchestrates the 1-click PC installation process.
    #>
    
    # Check for administrator privileges
    if (-not (Test-SouliTEKAdministrator)) {
        Show-Header "ERROR: ADMINISTRATOR REQUIRED"
        Write-Host ""
        Write-Host "  This script requires administrator privileges to run." -ForegroundColor Red
        Write-Host ""
        Write-Host "  Please right-click this script and select:" -ForegroundColor Yellow
        Write-Host "  'Run with PowerShell as administrator'" -ForegroundColor Yellow
        Write-Host ""
        Read-Host "  Press Enter to exit"
        exit 1
    }
    
    # Show task list and get user approval
    Show-TaskList
    
    if (-not (Get-UserApproval)) {
        exit 0
    }
    
    # Start installation process
    Write-Host ""
    Write-Host "  Starting 1-Click PC Install..." -ForegroundColor Green
    Write-Host "  Please be patient, this may take a while..." -ForegroundColor Yellow
    Write-Host ""
    Start-Sleep -Seconds 2
    
    # Execute all tasks in sequence
    Set-TimeZoneToJerusalem
    Set-RegionalSettingsToIsrael
    New-SystemRestorePoint
    Install-WindowsUpdates
    Set-PowerPlanToBest
    Remove-Bloatware
    Install-Applications
    
    # Show final summary
    Show-InstallationSummary
    
    # Final prompt
    Write-Host -NoNewline "  Press Enter to exit..." -ForegroundColor Cyan
    Read-Host
}

# Run the installer
Start-OneClickPCInstall

