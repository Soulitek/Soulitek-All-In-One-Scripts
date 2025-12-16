# ============================================================
# Software Updater - Professional Edition
# ============================================================
# 
# Coded by: Soulitek.co.il
# IT Solutions for your business
# 
# (C) 2025 SouliTEK - All Rights Reserved
# Website: www.soulitek.co.il
# 
# Professional IT Solutions:
# - Computer Repair & Maintenance
# - Network Setup & Support
# - Software Solutions
# - Business IT Consulting
# 
# This tool manages software updates using Windows Package Manager (WinGet).
# Keep your system software up to date with automated or interactive updates.
# 
# Features: Software Update Management | WinGet Integration | Auto-Update Mode
#           Interactive Updates | Update History
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

#Requires -RunAsAdministrator
#Requires -Version 5.1

# Set window title
$Host.UI.RawUI.WindowTitle = "SOFTWARE UPDATER"

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

$Script:OutputDir = "$env:USERPROFILE\Desktop"
$Script:UpdateHistoryFile = Join-Path $env:LOCALAPPDATA "SouliTEK\UpdateHistory.json"
$Script:WinGetAvailable = $false

# ============================================================
# HELPER FUNCTIONS
# ============================================================

function Get-WinGetAvailability {
    <#
    .SYNOPSIS
        Checks if WinGet is available on the system
    #>
    try {
        $wingetPath = Get-Command winget.exe -ErrorAction SilentlyContinue
        if ($wingetPath) {
            Write-SouliTEKSuccess "WinGet is available on this system"
            
            # Get WinGet version
            try {
                $versionOutput = winget --version 2>&1
                if ($versionOutput) {
                    Write-Host "  [*] WinGet Version: $versionOutput" -ForegroundColor Gray
                }
            } catch {
                Write-Verbose "Could not retrieve WinGet version"
            }
            
            return $true
        } else {
            Write-SouliTEKWarning "WinGet is not available on this system"
            Write-Host ""
            Write-Host "  [!] WinGet comes pre-installed on:" -ForegroundColor Yellow
            Write-Host "      - Windows 11 (all versions)" -ForegroundColor Gray
            Write-Host "      - Windows 10 version 1809 and later" -ForegroundColor Gray
            Write-Host ""
            Write-Host "  [!] To install WinGet:" -ForegroundColor Yellow
            Write-Host "      1. Open Microsoft Store" -ForegroundColor Gray
            Write-Host "      2. Search for 'App Installer'" -ForegroundColor Gray
            Write-Host "      3. Install or update 'App Installer'" -ForegroundColor Gray
            Write-Host ""
            Write-Host "  [!] Or download from: https://aka.ms/getwinget" -ForegroundColor Yellow
            Write-Host ""
            return $false
        }
    }
    catch {
        Write-SouliTEKError "Error checking WinGet availability: $($_.Exception.Message)"
        return $false
    }
}

function Get-AvailableUpdates {
    <#
    .SYNOPSIS
        Lists all available software updates
    #>
    if (-not $Script:WinGetAvailable) {
        Write-SouliTEKError "WinGet is not available on this system"
        return $null
    }
    
    Write-SouliTEKInfo "Checking for available software updates..."
    Write-Host ""
    
    try {
        Write-Host "  [*] Querying WinGet for updates..." -ForegroundColor Cyan
        Write-Host "  [*] This may take a moment..." -ForegroundColor Gray
        Write-Host ""
        
        $upgradeList = winget upgrade 2>&1 | Out-String
        
        if ($upgradeList -like "*No installed package found*" -or 
            $upgradeList -like "*No applicable update found*" -or
            $upgradeList -like "*No upgrades available*") {
            Write-SouliTEKSuccess "All installed software is up to date!"
            Write-Host ""
            return $null
        }
        
        # Display the update list
        Write-Host "  " -NoNewline
        Write-Host "AVAILABLE UPDATES:" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "============================================================" -ForegroundColor Gray
        $upgradeList -split "`n" | ForEach-Object { 
            if ($_ -match "^\s*$") { return }
            Write-Host "  $_" -ForegroundColor Gray 
        }
        Write-Host "============================================================" -ForegroundColor Gray
        Write-Host ""
        
        return $upgradeList
    }
    catch {
        Write-SouliTEKError "Failed to check for updates: $($_.Exception.Message)"
        return $null
    }
}

function Update-AllSoftware {
    <#
    .SYNOPSIS
        Updates all software automatically using WinGet
    #>
    param(
        [switch]$Silent
    )
    
    if (-not $Script:WinGetAvailable) {
        Write-SouliTEKError "WinGet is not available on this system"
        return $false
    }
    
    Write-Host ""
    Write-Host "  [!] Starting automatic software update..." -ForegroundColor Yellow
    Write-Host "  [!] This may take several minutes depending on the number of updates..." -ForegroundColor Yellow
    Write-Host ""
    
    try {
        # Build WinGet arguments
        $wingetArgs = @(
            "upgrade"
            "--all"
            "--silent"
            "--accept-package-agreements"
            "--accept-source-agreements"
            "--disable-interactivity"
        )
        
        Write-Host "  [*] Command: winget $($wingetArgs -join ' ')" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "  [*] Processing updates..." -ForegroundColor Cyan
        Write-Host ""
        
        # Create temp files for output
        $outputFile = "$env:TEMP\soulitek_winget_output_$(Get-Date -Format 'yyyyMMddHHmmss').txt"
        $errorFile = "$env:TEMP\soulitek_winget_error_$(Get-Date -Format 'yyyyMMddHHmmss').txt"
        
        # Start the update process
        $startTime = Get-Date
        $upgradeProcess = Start-Process -FilePath "winget.exe" `
            -ArgumentList $wingetArgs `
            -NoNewWindow `
            -Wait `
            -PassThru `
            -RedirectStandardOutput $outputFile `
            -RedirectStandardError $errorFile
        
        $endTime = Get-Date
        $duration = $endTime - $startTime
        
        # Read output
        $output = Get-Content $outputFile -Raw -ErrorAction SilentlyContinue
        $errors = Get-Content $errorFile -Raw -ErrorAction SilentlyContinue
        
        Write-Host ""
        
        if ($upgradeProcess.ExitCode -eq 0) {
            Write-SouliTEKSuccess "Software updates completed successfully!"
            Write-Host "  [*] Duration: $($duration.Minutes) minutes, $($duration.Seconds) seconds" -ForegroundColor Gray
        } elseif ($upgradeProcess.ExitCode -eq -1978335189) {
            Write-SouliTEKSuccess "Updates completed (some packages may have been skipped)"
            Write-Host "  [*] Duration: $($duration.Minutes) minutes, $($duration.Seconds) seconds" -ForegroundColor Gray
            Write-Host "  [!] Note: Exit code -1978335189 often indicates no updates or partial success" -ForegroundColor Yellow
        } else {
            Write-SouliTEKWarning "Software update completed with warnings (Exit Code: $($upgradeProcess.ExitCode))"
            Write-Host "  [*] Duration: $($duration.Minutes) minutes, $($duration.Seconds) seconds" -ForegroundColor Gray
        }
        
        # Display output
        if ($output -and $output.Trim() -ne "") {
            Write-Host ""
            Write-Host "  " -NoNewline
            Write-Host "UPDATE OUTPUT:" -ForegroundColor Cyan
            Write-Host ""
            $output -split "`n" | ForEach-Object { 
                if ($_ -match "^\s*$") { return }
                Write-Host "  $_" -ForegroundColor Gray 
            }
        }
        
        # Display errors if any
        if ($errors -and $errors.Trim() -ne "" -and $upgradeProcess.ExitCode -ne 0 -and $upgradeProcess.ExitCode -ne -1978335189) {
            Write-Host ""
            Write-Host "  " -NoNewline
            Write-Host "MESSAGES:" -ForegroundColor Yellow
            Write-Host ""
            $errors -split "`n" | ForEach-Object { 
                if ($_ -match "^\s*$") { return }
                Write-Host "  $_" -ForegroundColor Yellow 
            }
        }
        
        # Save update history
        Save-UpdateHistory -Duration $duration -ExitCode $upgradeProcess.ExitCode
        
        # Cleanup temp files
        Remove-Item $outputFile -ErrorAction SilentlyContinue
        Remove-Item $errorFile -ErrorAction SilentlyContinue
        
        Write-Host ""
        return $true
    }
    catch {
        Write-SouliTEKError "Failed to update software: $($_.Exception.Message)"
        return $false
    }
}

function Update-SoftwareInteractive {
    <#
    .SYNOPSIS
        Opens interactive WinGet upgrade interface
    #>
    if (-not $Script:WinGetAvailable) {
        Write-SouliTEKError "WinGet is not available on this system"
        return $false
    }
    
    Write-Host ""
    Write-Host "  [!] Opening interactive WinGet upgrade interface..." -ForegroundColor Yellow
    Write-Host "  [!] You will be able to review and approve each update..." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  [*] Press Enter to continue..." -ForegroundColor Cyan
    Read-Host
    
    try {
        Clear-Host
        Write-Host ""
        Write-Host "============================================================" -ForegroundColor Cyan
        Write-Host "  INTERACTIVE UPDATE MODE" -ForegroundColor Cyan
        Write-Host "============================================================" -ForegroundColor Cyan
        Write-Host ""
        
        # Run interactive update
        $startTime = Get-Date
        winget upgrade --all
        $endTime = Get-Date
        $duration = $endTime - $startTime
        
        Write-Host ""
        Write-Host "============================================================" -ForegroundColor Cyan
        Write-Host ""
        Write-SouliTEKSuccess "Interactive update session completed"
        Write-Host "  [*] Duration: $($duration.Minutes) minutes, $($duration.Seconds) seconds" -ForegroundColor Gray
        
        # Save update history
        Save-UpdateHistory -Duration $duration -ExitCode 0 -Interactive
        
        return $true
    }
    catch {
        Write-SouliTEKError "Failed to run interactive update: $($_.Exception.Message)"
        return $false
    }
}

function Save-UpdateHistory {
    <#
    .SYNOPSIS
        Saves update history to a JSON file
    #>
    param(
        [TimeSpan]$Duration,
        [int]$ExitCode,
        [switch]$Interactive
    )
    
    try {
        $historyDir = Split-Path -Parent $Script:UpdateHistoryFile
        if (-not (Test-Path $historyDir)) {
            New-Item -Path $historyDir -ItemType Directory -Force | Out-Null
        }
        
        # Load existing history
        $history = @()
        if (Test-Path $Script:UpdateHistoryFile) {
            $existingHistory = Get-Content -Path $Script:UpdateHistoryFile -Raw | ConvertFrom-Json
            $history = @($existingHistory)
        }
        
        # Add new entry
        $entry = [PSCustomObject]@{
            Timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
            Duration = "$($Duration.Minutes)m $($Duration.Seconds)s"
            Mode = if ($Interactive) { "Interactive" } else { "Automatic" }
            ExitCode = $ExitCode
            Success = ($ExitCode -eq 0 -or $ExitCode -eq -1978335189)
        }
        
        $history += $entry
        
        # Keep only last 50 entries
        if ($history.Count -gt 50) {
            $history = $history | Select-Object -Last 50
        }
        
        # Save to file
        $history | ConvertTo-Json -Depth 10 | Set-Content -Path $Script:UpdateHistoryFile -Force
    }
    catch {
        Write-Verbose "Could not save update history: $_"
    }
}

function Show-UpdateHistory {
    <#
    .SYNOPSIS
        Displays update history
    #>
    if (-not (Test-Path $Script:UpdateHistoryFile)) {
        Write-SouliTEKWarning "No update history found"
        Write-Host "  [!] Run an update first to create history" -ForegroundColor Yellow
        return
    }
    
    try {
        $history = Get-Content -Path $Script:UpdateHistoryFile -Raw | ConvertFrom-Json
        
        Show-SouliTEKHeader -Title "UPDATE HISTORY" -ClearHost -ShowBanner
        
        Write-Host "  Showing last $($history.Count) update(s):" -ForegroundColor Yellow
        Write-Host ""
        
        $count = 0
        foreach ($entry in ($history | Sort-Object Timestamp -Descending | Select-Object -First 20)) {
            $count++
            
            $statusColor = if ($entry.Success) { "Green" } else { "Red" }
            $statusText = if ($entry.Success) { "[OK] Success" } else { "[X] Failed" }
            
            Write-Host "  [$count] $($entry.Timestamp)" -ForegroundColor Cyan
            Write-Host "      Mode:     $($entry.Mode)" -ForegroundColor Gray
            Write-Host "      Duration: $($entry.Duration)" -ForegroundColor Gray
            Write-Host "      Status:   " -NoNewline -ForegroundColor Gray
            Write-Host "$statusText" -ForegroundColor $statusColor
            if ($entry.ExitCode -ne 0 -and $entry.ExitCode -ne -1978335189) {
                Write-Host "      Exit Code: $($entry.ExitCode)" -ForegroundColor Yellow
            }
            Write-Host ""
        }
        
        if ($history.Count -gt 20) {
            Write-Host "  [!] Showing last 20 of $($history.Count) total updates" -ForegroundColor Gray
            Write-Host ""
        }
    }
    catch {
        Write-SouliTEKError "Failed to load update history: $($_.Exception.Message)"
    }
}

function Export-UpdateReport {
    <#
    .SYNOPSIS
        Exports current update status to a report
    #>
    try {
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $computerName = $env:COMPUTERNAME
        $reportFile = Join-Path $Script:OutputDir "SoftwareUpdateReport_${computerName}_${timestamp}.txt"
        
        Write-SouliTEKInfo "Generating update report..."
        Write-Host ""
        
        # Get available updates
        $upgradeList = winget upgrade 2>&1 | Out-String
        
        # Create report content
        $reportContent = @"
============================================================
SOFTWARE UPDATE REPORT
============================================================

Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
Computer: $computerName
WinGet Version: $(winget --version 2>&1)

============================================================
AVAILABLE UPDATES
============================================================

$upgradeList

============================================================
UPDATE HISTORY (Last 10)
============================================================

"@
        
        # Add history if available
        if (Test-Path $Script:UpdateHistoryFile) {
            $history = Get-Content -Path $Script:UpdateHistoryFile -Raw | ConvertFrom-Json
            foreach ($entry in ($history | Sort-Object Timestamp -Descending | Select-Object -First 10)) {
                $statusText = if ($entry.Success) { "Success" } else { "Failed" }
                $reportContent += "`nDate: $($entry.Timestamp)`n"
                $reportContent += "  Mode: $($entry.Mode)`n"
                $reportContent += "  Duration: $($entry.Duration)`n"
                $reportContent += "  Status: $statusText`n"
                $reportContent += "  Exit Code: $($entry.ExitCode)`n`n"
            }
        } else {
            $reportContent += "`nNo update history available.`n"
        }
        
        $reportContent += "`n============================================================`n"
        $reportContent += "END OF REPORT`n"
        $reportContent += "============================================================`n"
        $reportContent += "`n"
        $reportContent += "Generated by SouliTEK Software Updater`n"
        $reportContent += "Website: www.soulitek.co.il`n"
        $reportContent += "(C) 2025 SouliTEK - All Rights Reserved`n"
        $reportContent += "`n"
        
        # Save report
        Set-Content -Path $reportFile -Value $reportContent -Encoding UTF8
        
        Write-SouliTEKSuccess "Report exported: $reportFile"
        Write-Host ""
        
        return $true
    }
    catch {
        Write-SouliTEKError "Failed to export report: $($_.Exception.Message)"
        return $false
    }
}

function Show-Menu {
    <#
    .SYNOPSIS
        Displays the main menu
    #>
    Show-SouliTEKHeader -Title "SOFTWARE UPDATER" -ClearHost -ShowBanner
    
    Write-Host "  Select an option:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  [1] Check for Available Updates" -ForegroundColor Cyan
    Write-Host "      -> List all software that has updates available" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  [2] Update All Software (Automatic)" -ForegroundColor Cyan
    Write-Host "      -> Silently update all software without prompts" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  [3] Update Software (Interactive)" -ForegroundColor Cyan
    Write-Host "      -> Review and approve each update individually" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  [4] View Update History" -ForegroundColor Cyan
    Write-Host "      -> Display history of previous updates" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  [5] Export Update Report" -ForegroundColor Cyan
    Write-Host "      -> Generate detailed report and save to Desktop" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  [0] Exit" -ForegroundColor Red
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
}

# ============================================================
# MAIN EXECUTION
# ============================================================

function Main {
    # Show banner
    Clear-Host
    Show-ScriptBanner -ScriptName "Software Updater" -Purpose "Check for and install software updates using WinGet"
    
    # Check WinGet availability at startup
    $Script:WinGetAvailable = Get-WinGetAvailability
    Write-Host ""
    
    if (-not $Script:WinGetAvailable) {
        Write-Ui -Message "WinGet is required for this tool to function" -Level "ERROR"
        Write-Ui -Message "Please install WinGet and try again" -Level "WARN"
        Write-Host ""
        Read-Host "Press Enter to exit"
        exit 1
    }
    
    Read-Host "Press Enter to continue"
    
    do {
        Show-Menu
        $choice = Read-Host "Enter your choice"
        
        switch ($choice) {
            "1" {
                # Check for Available Updates
                Show-SouliTEKHeader -Title "CHECK FOR UPDATES" -ClearHost -ShowBanner
                
                $updates = Get-AvailableUpdates
                
                if ($null -ne $updates) {
                    Write-Host "  [*] Updates are available for installation" -ForegroundColor Cyan
                    Write-Host "  [*] Use Option 2 for automatic update or Option 3 for interactive" -ForegroundColor Cyan
                }
                
                Write-Host ""
                Read-Host "Press Enter to continue"
            }
            
            "2" {
                # Update All Software (Automatic)
                Show-SouliTEKHeader -Title "AUTOMATIC SOFTWARE UPDATE" -ClearHost -ShowBanner
                
                Write-Host "  [!] This will automatically update all software on your system" -ForegroundColor Yellow
                Write-Host "  [!] The process will run silently without prompts" -ForegroundColor Yellow
                Write-Host "  [!] This may take several minutes depending on the number of updates" -ForegroundColor Yellow
                Write-Host ""
                
                $confirm = Read-Host "Continue with automatic update? (Y/N)"
                
                if ($confirm -eq "Y" -or $confirm -eq "y") {
                    Update-AllSoftware
                } else {
                    Write-SouliTEKInfo "Update cancelled by user"
                }
                
                Write-Host ""
                Read-Host "Press Enter to continue"
            }
            
            "3" {
                # Update Software (Interactive)
                Show-SouliTEKHeader -Title "INTERACTIVE SOFTWARE UPDATE" -ClearHost -ShowBanner
                
                Write-Host "  [!] This will open an interactive update interface" -ForegroundColor Yellow
                Write-Host "  [!] You can review and approve each update individually" -ForegroundColor Yellow
                Write-Host "  [!] Press Enter to continue or type 'cancel' to go back..." -ForegroundColor Yellow
                Write-Host ""
                
                $confirm = Read-Host "Continue"
                
                if ($confirm -ne "cancel") {
                    Update-SoftwareInteractive
                } else {
                    Write-SouliTEKInfo "Update cancelled by user"
                }
                
                Write-Host ""
                Read-Host "Press Enter to continue"
            }
            
            "4" {
                # View Update History
                Show-UpdateHistory
                
                Write-Host ""
                Read-Host "Press Enter to continue"
            }
            
            "5" {
                # Export Update Report
                Show-SouliTEKHeader -Title "EXPORT UPDATE REPORT" -ClearHost -ShowBanner
                
                Export-UpdateReport
                
                Write-Host ""
                Read-Host "Press Enter to continue"
            }
            
            "0" {
                # Exit
                Write-Host ""
                Write-Host "  Exiting..." -ForegroundColor Yellow
                
                Start-Sleep -Seconds 1
                exit
            }
            
            default {
                Write-SouliTEKWarning "Invalid choice. Please select a valid option."
                Start-Sleep -Seconds 2
            }
        }
        
    } while ($true)
}

# Run the main function
Main
