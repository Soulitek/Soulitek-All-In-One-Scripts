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

# Show-Header function removed - using Show-SouliTEKHeader from common module

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
    Show-SouliTEKHeader -Title "1-CLICK PC INSTALL - TASK OVERVIEW" -ClearHost -ShowBanner
    
    Write-Host "  The following tasks will be performed:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  [1]  Set Time Zone" -ForegroundColor Cyan
    Write-Host "       -> Configure time zone to Jerusalem (Israel Standard Time)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  [2]  Configure Regional Settings" -ForegroundColor Cyan
    Write-Host "       -> Set regional format, location, and language to Israel/Hebrew" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  [3]  Create System Restore Point" -ForegroundColor Cyan
    Write-Host "       -> Create a backup point before making system changes" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  [4]  Configure Power Plan" -ForegroundColor Cyan
    Write-Host "       -> Set power plan to High Performance for best performance" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  [5]  Remove Bloatware" -ForegroundColor Cyan
    Write-Host "       -> Remove unnecessary pre-installed Windows applications" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  [6]  Install Google Chrome" -ForegroundColor Cyan
    Write-Host "       -> Install Google Chrome web browser via WinGet" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  [7]  Install AnyDesk" -ForegroundColor Cyan
    Write-Host "       -> Install AnyDesk remote desktop software via WinGet" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  [8]  Install Microsoft Office" -ForegroundColor Cyan
    Write-Host "       -> Install Microsoft Office suite (if available)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  [9]  Create Desktop Shortcuts" -ForegroundColor Cyan
    Write-Host "       -> Create shortcuts for This PC and Documents folder on desktop" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  [10] Generate Installation Summary" -ForegroundColor Cyan
    Write-Host "       -> Create detailed report of all actions performed" -ForegroundColor Gray
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  IMPORTANT NOTES:" -ForegroundColor Red
    Write-Host "  * This process may take 20-40 minutes to complete" -ForegroundColor Yellow
    Write-Host "  * Administrator privileges are required" -ForegroundColor Yellow
    Write-Host "  * Active internet connection is required" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Yellow
    Write-Host ""
}

function Get-UserApproval {
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
    Show-SouliTEKHeader -Title "SETTING TIME ZONE" -ClearHost -ShowBanner
    Write-SouliTEKInfo "Configuring time zone to Jerusalem..."
    
    try {
        $currentTimeZone = Get-TimeZone
        Write-Host "  Current Time Zone: $($currentTimeZone.DisplayName)" -ForegroundColor Gray
        
        Set-TimeZone -Id "Israel Standard Time" -ErrorAction Stop
        
        $newTimeZone = Get-TimeZone
        Write-SouliTEKSuccess "Time zone set to: $($newTimeZone.DisplayName)"
        Add-LogEntry -Task "Set Time Zone" -Status "SUCCESS" -Details "Changed to $($newTimeZone.DisplayName)"
        
        Start-Sleep -Seconds 2
        return $true
    } catch {
        Write-SouliTEKError "Failed to set time zone: $($_.Exception.Message)"
        Add-LogEntry -Task "Set Time Zone" -Status "ERROR" -Details $_.Exception.Message
        Start-Sleep -Seconds 3
        return $false
    }
}

function Set-RegionalSettingsToIsrael {
    Show-SouliTEKHeader -Title "CONFIGURING REGIONAL SETTINGS" -ClearHost -ShowBanner
    Write-SouliTEKInfo "Setting regional format to Israel..."
    
    try {
        Write-Host "  [*] Setting regional format..." -ForegroundColor Cyan
        Set-Culture -CultureInfo "he-IL" -ErrorAction Stop
        
        Write-Host "  [*] Setting geographic location..." -ForegroundColor Cyan
        Set-WinHomeLocation -GeoId 117 -ErrorAction Stop
        
        Write-Host "  [*] Configuring system locale..." -ForegroundColor Cyan
        Set-WinSystemLocale -SystemLocale "he-IL" -ErrorAction Stop
        
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
    } catch {
        Write-SouliTEKError "Failed to set regional settings: $($_.Exception.Message)"
        Add-LogEntry -Task "Regional Settings" -Status "ERROR" -Details $_.Exception.Message
        Start-Sleep -Seconds 3
        return $false
    }
}

function New-SystemRestorePoint {
    Show-SouliTEKHeader -Title "CREATING SYSTEM RESTORE POINT" -ClearHost -ShowBanner
    Write-SouliTEKInfo "Creating system restore point..."
    
    try {
        $systemDrive = $env:SystemDrive
        $restoreEnabled = Get-ComputerRestorePoint -ErrorAction SilentlyContinue
        
        if (-not $restoreEnabled) {
            Write-SouliTEKWarning "System Restore may not be enabled"
            Write-Host "  Attempting to enable System Restore..." -ForegroundColor Yellow
            
            $enableResult = Enable-ComputerRestore -Drive "$systemDrive\" -ErrorAction SilentlyContinue
            if (-not $?) {
                Write-SouliTEKWarning "Could not enable System Restore automatically"
            } else {
                Start-Sleep -Seconds 2
            }
        }
        
        $description = "1-Click PC Install - Before Setup ($(Get-Date -Format 'yyyy-MM-dd HH:mm'))"
        Write-Host "  Creating restore point: $description" -ForegroundColor Cyan
        
        Checkpoint-Computer -Description $description -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop
        
        Write-SouliTEKSuccess "System restore point created successfully"
        Add-LogEntry -Task "System Restore Point" -Status "SUCCESS" -Details $description
        
        Start-Sleep -Seconds 2
        return $true
    } catch {
        Write-SouliTEKWarning "Could not create system restore point: $($_.Exception.Message)"
        Add-LogEntry -Task "System Restore Point" -Status "WARNING" -Details $_.Exception.Message
        
        Write-Host ""
        Write-Host "  Continuing anyway... (This is not critical)" -ForegroundColor Yellow
        
        Start-Sleep -Seconds 3
        return $false
    }
}

function Set-PowerPlanToBest {
    Show-SouliTEKHeader -Title "CONFIGURING POWER PLAN" -ClearHost -ShowBanner
    Write-SouliTEKInfo "Setting power plan to High Performance..."
    
    try {
        $highPerfPlan = powercfg /list | Select-String "High performance" -Context 0,0
        
        if (-not $highPerfPlan) {
            $ultimatePlan = powercfg /list | Select-String "Ultimate Performance" -Context 0,0
            
            if ($ultimatePlan) {
                $planGuid = $ultimatePlan -match '([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12})'
                $planGuid = $matches[1]
                powercfg /setactive $planGuid
                Write-SouliTEKSuccess "Power plan set to Ultimate Performance"
                Add-LogEntry -Task "Power Plan" -Status "SUCCESS" -Details "Set to Ultimate Performance"
            } else {
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
        
        $activePlan = powercfg /getactivescheme
        Write-Host "  Current Power Plan: " -NoNewline -ForegroundColor Gray
        Write-Host "$activePlan" -ForegroundColor Cyan
        
        Start-Sleep -Seconds 2
        return $true
    } catch {
        Write-SouliTEKError "Failed to set power plan: $($_.Exception.Message)"
        Add-LogEntry -Task "Power Plan" -Status "ERROR" -Details $_.Exception.Message
        Start-Sleep -Seconds 3
        return $false
    }
}

function Remove-Bloatware {
    Show-SouliTEKHeader -Title "REMOVING BLOATWARE" -ClearHost -ShowBanner
    Write-SouliTEKInfo "Removing unnecessary Windows applications..."
    
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
                $removeResult = Remove-AppxPackage -Package $package.PackageFullName -ErrorAction SilentlyContinue
                if ($?) {
                    Write-Host "      -> Removed" -ForegroundColor Green
                    $removedCount++
                } else {
                    Write-Host "      -> Failed to remove" -ForegroundColor Red
                    $failedCount++
                }
            } else {
                Write-Host "      -> Not installed" -ForegroundColor Gray
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
    } catch {
        Write-SouliTEKError "Error during bloatware removal: $($_.Exception.Message)"
        Add-LogEntry -Task "Remove Bloatware" -Status "ERROR" -Details $_.Exception.Message
        Start-Sleep -Seconds 3
        return $false
    }
}

function Install-WinGetApplication {
    param(
        [Parameter(Mandatory = $true)]
        [string]$AppName,
        
        [Parameter(Mandatory = $true)]
        [string]$WinGetId,
        
        [Parameter(Mandatory = $false)]
        [int]$TimeoutMinutes = 10
    )
    
    Write-Host "  [*] Installing $AppName..." -ForegroundColor Cyan
    Write-Host "      -> This may take up to $TimeoutMinutes minutes. Please be patient..." -ForegroundColor Gray
    
    try {
        # Create log file for this installation
        $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
        $logPath = "$env:TEMP\winget_install_${AppName}_${timestamp}.log"
        
        # Build winget command with all necessary flags
        $wingetArgs = @(
            "install",
            "--id", $WinGetId,
            "--silent",
            "--accept-package-agreements",
            "--accept-source-agreements",
            "--disable-interactivity",
            "--no-upgrade",
            "--log", $logPath
        )
        
        # Start the installation process with hidden window for better process tracking
        $processInfo = New-Object System.Diagnostics.ProcessStartInfo
        $processInfo.FileName = "winget.exe"
        $processInfo.Arguments = ($wingetArgs -join " ")
        $processInfo.UseShellExecute = $false
        $processInfo.RedirectStandardOutput = $true
        $processInfo.RedirectStandardError = $true
        $processInfo.CreateNoWindow = $true
        
        $process = New-Object System.Diagnostics.Process
        $process.StartInfo = $processInfo
        
        Write-Host "      -> Starting installation..." -ForegroundColor Gray
        $process.Start() | Out-Null
        
        # Wait for process with timeout using Wait-Process
        $timeoutSeconds = $TimeoutMinutes * 60
        $completed = $false
        $startTime = Get-Date
        $lastProgressTime = $startTime
        
        Write-Host "      -> Progress: " -NoNewline -ForegroundColor Gray
        
        # Use a job to monitor the process while showing progress
        while (-not $process.HasExited) {
            $elapsed = (Get-Date) - $startTime
            
            # Check for timeout
            if ($elapsed.TotalSeconds -ge $timeoutSeconds) {
                Write-Host ""
                Write-Host "      [!] INSTALLATION TIMEOUT NOTICE:" -ForegroundColor Yellow
                Write-Host "      -> The installation exceeded the $TimeoutMinutes minute limit" -ForegroundColor Yellow
                Write-Host "      -> This may be due to slow internet or large download size" -ForegroundColor Yellow
                Write-Host "      -> The process has been terminated to prevent indefinite waiting" -ForegroundColor Yellow
                Write-Host ""
                Write-Host "      RECOMMENDED ACTION:" -ForegroundColor Cyan
                Write-Host "      -> Install $AppName manually after setup completes" -ForegroundColor White
                Write-Host "      -> Command: winget install --id $WinGetId" -ForegroundColor Gray
                Write-Host ""
                
                try {
                    if (-not $process.HasExited) {
                        $process.Kill()
                        Start-Sleep -Seconds 1
                    }
                    # Also kill any child processes
                    Get-Process | Where-Object { $_.Parent.Id -eq $process.Id } | Stop-Process -Force -ErrorAction SilentlyContinue
                } catch {
                    # Process may have already exited
                }
                
                return "TIMEOUT"
            }
            
            # Show progress every 5 seconds
            if (($elapsed - $lastProgressTime).TotalSeconds -ge 5) {
                Write-Host "." -NoNewline -ForegroundColor Cyan
                $lastProgressTime = $elapsed
                
                # Show time remaining every 30 seconds
                $remaining = [math]::Max(0, [math]::Round(($timeoutSeconds - $elapsed.TotalSeconds) / 60, 1))
                if ($remaining -gt 0 -and ($elapsed.TotalSeconds % 30 -lt 5)) {
                    Write-Host " ($remaining min left) " -NoNewline -ForegroundColor Gray
                }
            }
            
            Start-Sleep -Milliseconds 500
        }
        
        Write-Host "" # New line after progress dots
        
        # Wait a moment for exit code to be available
        Start-Sleep -Milliseconds 500
        
        # Check exit code
        try {
            $exitCode = $process.ExitCode
        } catch {
            # If ExitCode is not available, try to get it from the process
            $process.Refresh()
            $exitCode = $process.ExitCode
        }
        
        # Close process handles
        $process.Close()
        
        if ($exitCode -eq 0) {
            Write-Host "      -> $AppName installed successfully" -ForegroundColor Green
            return "SUCCESS"
        } elseif ($exitCode -eq -1978335189 -or $exitCode -eq 0x8A15000B) {
            # No applicable update found (already installed)
            Write-Host "      -> $AppName is already installed and up to date" -ForegroundColor Yellow
            return "SUCCESS"
        } elseif ($exitCode -eq -1978335212 -or $exitCode -eq 0x8A150014) {
            # Install failed
            Write-Host "      -> Installation failed (Exit Code: $exitCode)" -ForegroundColor Red
            Show-InstallationLog -LogPath $logPath -AppName $AppName
            return "ERROR"
        } else {
            Write-Host "      -> Installation completed with exit code: $exitCode" -ForegroundColor Yellow
            # Check log to see if it was actually successful
            if (Test-Path $logPath) {
                $logContent = Get-Content $logPath -Tail 20 -ErrorAction SilentlyContinue
                if ($logContent -match "successfully installed" -or $logContent -match "already installed") {
                    Write-Host "      -> $AppName appears to be installed successfully" -ForegroundColor Green
                    return "SUCCESS"
                }
            }
            Show-InstallationLog -LogPath $logPath -AppName $AppName
            return "ERROR"
        }
    } catch {
        Write-Host "      -> Error installing $AppName : $($_.Exception.Message)" -ForegroundColor Red
        if ($process -and -not $process.HasExited) {
            try {
                $process.Kill()
            } catch {}
        }
        return "ERROR"
    }
}

function Show-InstallationLog {
    param(
        [string]$LogPath,
        [string]$AppName
    )
    
    if (Test-Path $LogPath) {
        Write-Host "      -> Installation log details:" -ForegroundColor Gray
        
        $logContent = Get-Content $LogPath -Tail 10 -ErrorAction SilentlyContinue
        if ($logContent) {
            $logContent | Select-Object -Last 5 | ForEach-Object {
                $line = $_.Trim()
                if ($line -and $line -notmatch "^[-=]+$") {
                    Write-Host "         $line" -ForegroundColor DarkGray
                }
            }
        }
        
        Write-Host "      -> Full log saved: $LogPath" -ForegroundColor DarkGray
    }
}

function Ensure-WinGet {
    Write-Host "  [*] Checking WinGet installation..." -ForegroundColor Cyan
    
    $wingetCmd = Get-Command winget.exe -ErrorAction SilentlyContinue
    if ($wingetCmd) {
        Write-Host "      -> WinGet is available" -ForegroundColor Green
        return $true
    }
    
    Write-Host "      -> WinGet not found" -ForegroundColor Yellow
    Write-Host "  [*] Attempting to install WinGet..." -ForegroundColor Cyan
    
    try {
        $nuget = Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue
        if (-not $nuget) {
            Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope CurrentUser | Out-Null
        }
        
        Install-Module -Name Microsoft.WinGet.Client -Force -Scope CurrentUser -ErrorAction Stop
        Import-Module -Name Microsoft.WinGet.Client -Force -ErrorAction Stop
        
        Repair-WinGetPackageManager -ErrorAction Stop
        
        Write-Host "      -> WinGet installed successfully" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "      -> Failed to install WinGet: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

function Install-Applications {
    Show-SouliTEKHeader -Title "INSTALLING APPLICATIONS" -ClearHost -ShowBanner
    
    try {
        if (-not (Ensure-WinGet)) {
            Write-SouliTEKError "WinGet is not available. Cannot install applications."
            Add-LogEntry -Task "Install Applications" -Status "ERROR" -Details "WinGet not available"
            Start-Sleep -Seconds 3
            return $false
        }
        
        Write-Host ""
        Write-SouliTEKInfo "Installing applications via WinGet..."
        Write-Host ""
        
        Write-Host "  [1/3] Google Chrome" -ForegroundColor Yellow
        $chromeResult = Install-WinGetApplication -AppName "Google Chrome" -WinGetId "Google.Chrome"
        Add-LogEntry -Task "Install Google Chrome" -Status $chromeResult -Details "WinGet ID: Google.Chrome"
        
        Write-Host ""
        
        Write-Host "  [2/3] AnyDesk" -ForegroundColor Yellow
        $anydeskResult = Install-WinGetApplication -AppName "AnyDesk" -WinGetId "AnyDeskSoftwareGmbH.AnyDesk"
        Add-LogEntry -Task "Install AnyDesk" -Status $anydeskResult -Details "WinGet ID: AnyDeskSoftwareGmbH.AnyDesk"
        
        Write-Host ""
        
    Write-Host "  [3/3] Microsoft Office" -ForegroundColor Yellow
    Write-Host "  [!] Note: Office installation via WinGet may require manual setup" -ForegroundColor Yellow
    
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
        
        Write-Host ""
        Write-SouliTEKSuccess "Application installation process complete"
        
        Start-Sleep -Seconds 3
        return $true
    } catch {
        Write-SouliTEKError "Error during application installation: $($_.Exception.Message)"
        Add-LogEntry -Task "Install Applications" -Status "ERROR" -Details $_.Exception.Message
        Start-Sleep -Seconds 3
        return $false
    }
}

function New-DesktopShortcuts {
    Show-SouliTEKHeader -Title "CREATING DESKTOP SHORTCUTS" -ClearHost -ShowBanner
    Write-SouliTEKInfo "Creating desktop shortcuts for This PC and Documents..."
    
    try {
        $desktopPath = [Environment]::GetFolderPath("Desktop")
        $shell = New-Object -ComObject WScript.Shell
        
        # Create This PC shortcut
        Write-Host "  [*] Creating This PC shortcut..." -ForegroundColor Cyan
        $thisPCShortcut = $shell.CreateShortcut("$desktopPath\This PC.lnk")
        $thisPCShortcut.TargetPath = "::{20D04FE0-3AEA-1069-A2D8-08002B30309D}"
        $thisPCShortcut.WindowStyle = 1
        $thisPCShortcut.Description = "This PC - Access your computer, drives, and network locations"
        $thisPCShortcut.Save()
        
        Write-Host "      -> This PC shortcut created successfully" -ForegroundColor Green
        
        # Create Documents folder shortcut
        Write-Host "  [*] Creating Documents folder shortcut..." -ForegroundColor Cyan
        $documentsPath = [Environment]::GetFolderPath("MyDocuments")
        $documentsShortcut = $shell.CreateShortcut("$desktopPath\Documents.lnk")
        $documentsShortcut.TargetPath = $documentsPath
        $documentsShortcut.WindowStyle = 1
        $documentsShortcut.Description = "Documents - Access your Documents folder"
        $documentsShortcut.Save()
        
        Write-Host "      -> Documents shortcut created successfully" -ForegroundColor Green
        
        Write-SouliTEKSuccess "Desktop shortcuts created successfully"
        Add-LogEntry -Task "Create Desktop Shortcuts" -Status "SUCCESS" -Details "Created This PC and Documents shortcuts"
        
        Start-Sleep -Seconds 2
        return $true
    } catch {
        Write-SouliTEKError "Failed to create desktop shortcuts: $($_.Exception.Message)"
        Add-LogEntry -Task "Create Desktop Shortcuts" -Status "ERROR" -Details $_.Exception.Message
        Start-Sleep -Seconds 3
        return $false
    }
}

function Show-InstallationSummary {
    Show-SouliTEKHeader -Title "INSTALLATION SUMMARY" -ClearHost -ShowBanner
    
    try {
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
                Write-Host "      -> $($entry.Details)" -ForegroundColor Gray
            }
        }
        
        Write-Host ""
        Write-Host "============================================================" -ForegroundColor Cyan
        Write-Host ""
        
        $summaryPath = "$env:USERPROFILE\Desktop\1-Click-PC-Install-Summary.txt"
        
        $summaryContent = "============================================================`r`n"
        $summaryContent += "1-CLICK PC INSTALL - INSTALLATION SUMMARY`r`n"
        $summaryContent += "============================================================`r`n"
        $summaryContent += "`r`n"
        $summaryContent += "Installation Date: $($endTime.ToString('yyyy-MM-dd HH:mm:ss'))`r`n"
        $summaryContent += "Duration: $([math]::Round($duration.TotalMinutes, 2)) minutes`r`n"
        $summaryContent += "`r`n"
        $summaryContent += "RESULTS:`r`n"
        $summaryContent += "- Successful: $Script:SuccessCount task(s)`r`n"
        $summaryContent += "- Warnings: $Script:WarningCount task(s)`r`n"
        $summaryContent += "- Errors: $Script:ErrorCount task(s)`r`n"
        $summaryContent += "`r`n"
        $summaryContent += "DETAILED LOG:`r`n"
        $summaryContent += "============================================================`r`n"
        $summaryContent += "`r`n"
        
        $Script:InstallLog | ForEach-Object {
            $summaryContent += "[$($_.Time)] [$($_.Status)] $($_.Task)`r`n"
            if ($_.Details) {
                $summaryContent += "  -> $($_.Details)`r`n"
            }
            $summaryContent += "`r`n"
        }
        
        $summaryContent += "============================================================`r`n"
        $summaryContent += "Generated by SouliTEK All-In-One Scripts`r`n"
        $summaryContent += "Website: www.soulitek.co.il`r`n"
        $summaryContent += "Email: letstalk@soulitek.co.il`r`n"
        $summaryContent += "(C) 2025 SouliTEK - All Rights Reserved`r`n"
        $summaryContent += "============================================================`r`n"
        
        $saveResult = $summaryContent | Out-File -FilePath $summaryPath -Encoding UTF8 -ErrorAction SilentlyContinue
        
        if ($?) {
            Write-Host "  Summary saved to: " -NoNewline -ForegroundColor Gray
            Write-Host "$summaryPath" -ForegroundColor Cyan
            Write-Host ""
        } else {
            Write-Host "  [!] Could not save summary to desktop" -ForegroundColor Yellow
        }
        
        Write-Host ""
        Write-Host "  RECOMMENDED NEXT STEPS:" -ForegroundColor Yellow
        Write-Host "  * Restart your computer to apply all changes" -ForegroundColor White
        Write-Host "  * Review the installation summary above" -ForegroundColor White
        Write-Host "  * Verify all installed applications work correctly" -ForegroundColor White
        Write-Host ""
        Write-Host "============================================================" -ForegroundColor Cyan
        Write-Host ""
    } catch {
        Write-SouliTEKWarning "Error displaying installation summary: $($_.Exception.Message)"
        Write-Host ""
        Write-Host "  Summary could not be displayed due to an error." -ForegroundColor Yellow
        Write-Host ""
    }
}

# ============================================================
# MAIN EXECUTION
# ============================================================

function Start-OneClickPCInstall {
    if (-not (Test-SouliTEKAdministrator)) {
        Show-SouliTEKHeader -Title "ERROR: ADMINISTRATOR REQUIRED" -ClearHost -ShowBanner
        Write-Host ""
        Write-Host "  This script requires administrator privileges to run." -ForegroundColor Red
        Write-Host ""
        Write-Host "  Please right-click this script and select:" -ForegroundColor Yellow
        Write-Host "  'Run with PowerShell as administrator'" -ForegroundColor Yellow
        Write-Host ""
        Read-Host "  Press Enter to exit"
        exit 1
    }
    
    Show-TaskList
    
    if (-not (Get-UserApproval)) {
        exit 0
    }
    
    Write-Host ""
    Write-Host "  Starting 1-Click PC Install..." -ForegroundColor Green
    Write-Host "  Please be patient, this may take a while..." -ForegroundColor Yellow
    Write-Host ""
    Start-Sleep -Seconds 2
    
    Set-TimeZoneToJerusalem
    Set-RegionalSettingsToIsrael
    New-SystemRestorePoint
    Set-PowerPlanToBest
    Remove-Bloatware
    Install-Applications
    New-DesktopShortcuts
    
    Show-InstallationSummary
    
    Write-Host -NoNewline "  Press Enter to exit..." -ForegroundColor Cyan
    Read-Host
}

Start-OneClickPCInstall
