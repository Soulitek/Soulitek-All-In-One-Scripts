<#
============================================================
Printer Spooler Fix - UNIFIED Edition
============================================================

Coded by: Soulitek.co.il
IT Solutions for your business

(C) 2025 Soulitek - All Rights Reserved
Website: https://soulitek.co.il

Professional IT Solutions:
- Computer Repair & Maintenance
- Network Setup & Support
- Software Solutions
- Business IT Consulting

This tool provides comprehensive printer spooler management
with multiple modes for all your printing needs.

Features: Basic Fix | Advanced Monitor | Status Check
          PowerShell Mode | Scheduled Tasks | Built-in Help

============================================================

IMPORTANT DISCLAIMER:
This tool is provided "AS IS" without warranty of any kind.
Use of this tool is at your own risk. The user is solely
responsible for any outcomes, damages, or issues that may
arise from using this script. By running this tool, you
acknowledge and accept full responsibility for its use.

============================================================
#>

param(
    [switch]$AutoFixSilent
)

# Set console title and colors
$Host.UI.RawUI.WindowTitle = "Printer Spooler Fix - All-in-One Tool - by Soulitek.co.il"

# Import SouliTEK Common Functions
$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$CommonPath = Join-Path (Split-Path -Parent $ScriptRoot) "modules\SouliTEK-Common.ps1"
if (Test-Path $CommonPath) {
    Import-Module $CommonPath -Force
} else {
    Write-Warning "SouliTEK Common Functions not found at: $CommonPath"
    Write-Warning "Some functions may not work properly."
}

# Function to show ASCII banner


# Function to check admin privileges


# Function to show admin error
function Show-AdminError {
    $Host.UI.RawUI.BackgroundColor = "Black"
    $Host.UI.RawUI.ForegroundColor = "Red"
    Clear-Host
    Write-Host ""
    Write-Host "========================================"
    Write-Host "  ERROR: Administrator Required"
    Write-Host "========================================"
    Write-Host ""
    Write-Host "This script must run as Administrator."
    Write-Host ""
    Write-Host "HOW TO FIX:"
    Write-Host "1. Right-click this file"
    Write-Host "2. Select 'Run with PowerShell as administrator'"
    Write-Host "3. Click 'Yes' on the prompt"
    Write-Host ""
    Write-Host "========================================"
    Read-Host "Press Enter to exit"
    exit 1
}

# Function to perform the basic fix
function Invoke-SpoolerFix {
    Write-Host "[1/5] Stopping Print Spooler..."
    try {
        Stop-Service -Name Spooler -Force -ErrorAction SilentlyContinue
        Write-Host "      [OK] Stopped" -ForegroundColor Green
    } catch {
        Write-Host "      [INFO] Already stopped" -ForegroundColor Yellow
    }
    Start-Sleep -Seconds 2
    
    Write-Host "[2/5] Clearing stuck jobs..."
    $spoolPath = "$env:SystemRoot\System32\spool\PRINTERS\*.*"
    Remove-Item -Path $spoolPath -Force -ErrorAction SilentlyContinue
    Write-Host "      [OK] Queue cleared" -ForegroundColor Green
    
    Write-Host "[3/5] Waiting for cleanup..."
    Start-Sleep -Seconds 2
    Write-Host "      [OK] Ready" -ForegroundColor Green
    
    Write-Host "[4/5] Starting Print Spooler..."
    try {
        Start-Service -Name Spooler -ErrorAction Stop
        Write-Host "      [OK] Started" -ForegroundColor Green
    } catch {
        $Host.UI.RawUI.ForegroundColor = "Red"
        Write-Host "      [ERROR] Failed to start" -ForegroundColor Red
        return $false
    }
    Start-Sleep -Seconds 2
    
    Write-Host "[5/5] Verifying..."
    $service = Get-Service -Name Spooler
    if ($service.Status -eq 'Running') {
        Write-Host "      [OK] Running properly" -ForegroundColor Green
        return $true
    } else {
        Write-Host "      [ERROR] Service not running properly" -ForegroundColor Red
        return $false
    }
}

# Function to perform fix with logging
function Invoke-SpoolerFixWithLog {
    param([string]$LogFile)
    
    $timestamp = Get-Date -Format "HH:mm:ss"
    
    Add-Content -Path $LogFile -Value "[$timestamp] Stopping Print Spooler..."
    try {
        Stop-Service -Name Spooler -Force -ErrorAction SilentlyContinue
        Add-Content -Path $LogFile -Value "[$timestamp] Service stopped successfully"
    } catch {
        Add-Content -Path $LogFile -Value "[$timestamp] Error stopping service: $_"
    }
    
    Add-Content -Path $LogFile -Value "[$timestamp] Clearing stuck jobs..."
    $spoolPath = "$env:SystemRoot\System32\spool\PRINTERS\*.*"
    try {
        Remove-Item -Path $spoolPath -Force -ErrorAction SilentlyContinue
        Add-Content -Path $LogFile -Value "[$timestamp] Queue cleared successfully"
    } catch {
        Add-Content -Path $LogFile -Value "[$timestamp] Error clearing queue: $_"
    }
    
    Add-Content -Path $LogFile -Value "[$timestamp] Starting Print Spooler..."
    try {
        Start-Service -Name Spooler -ErrorAction Stop
        Add-Content -Path $LogFile -Value "[$timestamp] Service started successfully"
    } catch {
        Add-Content -Path $LogFile -Value "[$timestamp] Error starting service: $_"
    }
    
    Add-Content -Path $LogFile -Value "[$timestamp] Verifying status..."
    $service = Get-Service -Name Spooler
    Add-Content -Path $LogFile -Value "[$timestamp] Service status: $($service.Status)"
    Add-Content -Path $LogFile -Value "[$timestamp] Fix completed`n"
}

# Function to show disclaimer
function Show-Disclaimer {
    $Host.UI.RawUI.ForegroundColor = "Yellow"
    Clear-Host
    Write-Host ""
    Write-Host "============================================================"
    Write-Host ""
    Write-Host "                   IMPORTANT NOTICE"
    Write-Host ""
    Write-Host "============================================================"
    Write-Host ""
    Write-Host " This tool is provided 'AS IS' without warranty."
    Write-Host ""
    Write-Host " USE AT YOUR OWN RISK"
    Write-Host ""
    Write-Host " By continuing, you acknowledge that:"
    Write-Host " - You are solely responsible for any outcomes"
    Write-Host " - You understand the actions this tool will perform"
    Write-Host " - You accept full responsibility for its use"
    Write-Host ""
    Write-Host "============================================================"
    Write-Host ""
    Write-Host "Press any key to continue or Ctrl+C to cancel..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# Function to show main menu
function Show-MainMenu {
    $Host.UI.RawUI.ForegroundColor = "Cyan"
    Clear-Host
    Show-Banner
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Select an option:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host " [1] Basic Fix           - Quick one-time fix"
    Write-Host " [2] Advanced Monitor    - Continuous monitoring"
    Write-Host " [3] Status Check        - View detailed status"
    Write-Host " [4] PowerShell Mode     - Advanced features + logging"
    Write-Host " [5] Scheduled Task      - Setup automatic fixes"
    Write-Host " [6] Help               - Usage guide"
    Write-Host " [0] Exit"
    Write-Host ""
    Write-Host "========================================"
    
    $choice = Read-Host "Enter your choice (0-6)"
    return $choice
}

# Function for basic fix mode
function Invoke-BasicFixMode {
    $Host.UI.RawUI.ForegroundColor = "Yellow"
    Clear-Host
    Write-Host ""
    Write-Host "========================================"
    Write-Host "  BASIC FIX MODE"
    Write-Host "========================================"
    Write-Host ""
    Write-Host "This will:"
    Write-Host " - Stop the Print Spooler"
    Write-Host " - Clear all stuck jobs"
    Write-Host " - Restart the Print Spooler"
    Write-Host ""
    Write-Host "Press any key to start, or Ctrl+C to cancel..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    
    Clear-Host
    Write-Host ""
    Write-Host "========================================"
    Write-Host "  Running Basic Fix..."
    Write-Host "========================================"
    Write-Host ""
    
    Invoke-SpoolerFix
    
    $Host.UI.RawUI.ForegroundColor = "Green"
    Write-Host ""
    Write-Host "========================================"
    Write-Host "  BASIC FIX COMPLETED"
    Write-Host "========================================"
    Write-Host ""
    Write-Host "Your printer should now work normally."
    Write-Host "Try printing a test page."
    Write-Host ""
    Read-Host "Press Enter to return to main menu"
}

# Function for advanced monitor mode
function Invoke-AdvancedMonitorMode {
    $Host.UI.RawUI.ForegroundColor = "Magenta"
    Clear-Host
    Write-Host ""
    Write-Host "========================================"
    Write-Host "  ADVANCED MONITOR MODE"
    Write-Host "========================================"
    Write-Host ""
    Write-Host "This will continuously monitor your printer"
    Write-Host "spooler and automatically fix issues."
    Write-Host ""
    Write-Host "Monitoring interval: 30 seconds"
    Write-Host ""
    Write-Host "Press Ctrl+C to stop monitoring"
    Write-Host "Press any key to start..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    
    Clear-Host
    Write-Host ""
    Write-Host "========================================"
    Write-Host "  Monitoring Started"
    Write-Host "========================================"
    Write-Host ""
    
    $fixCount = 0
    $checkCount = 0
    
    while ($true) {
        $Host.UI.RawUI.ForegroundColor = "Cyan"
        $checkCount++
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Write-Host ""
        Write-Host "[$timestamp] Check #$checkCount"
        Write-Host "----------------------------------------"
        
        # Check if spooler is running
        $service = Get-Service -Name Spooler
        if ($service.Status -ne 'Running') {
            $Host.UI.RawUI.ForegroundColor = "Red"
            Write-Host "[WARNING] Print Spooler not running!"
            Write-Host "[ACTION]  Attempting automatic fix..."
            Invoke-SpoolerFix
            $fixCount++
            $Host.UI.RawUI.ForegroundColor = "Cyan"
        } else {
            # Check for stuck jobs
            $spoolPath = "$env:SystemRoot\System32\spool\PRINTERS"
            $jobCount = (Get-ChildItem -Path $spoolPath -File -ErrorAction SilentlyContinue | Measure-Object).Count
            
            if ($jobCount -gt 5) {
                $Host.UI.RawUI.ForegroundColor = "Yellow"
                Write-Host "[WARNING] $jobCount jobs detected in queue"
                Write-Host "[INFO]    Waiting 10 seconds to check if clearing..."
                Start-Sleep -Seconds 10
                
                # Check again
                $jobCountNew = (Get-ChildItem -Path $spoolPath -File -ErrorAction SilentlyContinue | Measure-Object).Count
                
                if ($jobCountNew -ge $jobCount) {
                    $Host.UI.RawUI.ForegroundColor = "Red"
                    Write-Host "[ACTION]  Jobs not clearing - performing fix..."
                    Invoke-SpoolerFix
                    $fixCount++
                    $Host.UI.RawUI.ForegroundColor = "Cyan"
                } else {
                    $Host.UI.RawUI.ForegroundColor = "Green"
                    Write-Host "[OK]      Jobs are processing normally"
                }
            } else {
                $Host.UI.RawUI.ForegroundColor = "Green"
                Write-Host "[OK] Spooler healthy - $jobCount jobs in queue"
            }
        }
        
        Write-Host ""
        Write-Host "========================================"
        Write-Host "Total fixes this session: $fixCount"
        Write-Host "Next check in 30 seconds..."
        Write-Host "========================================"
        Start-Sleep -Seconds 30
    }
}

# Function for status check mode
function Invoke-StatusCheckMode {
    $Host.UI.RawUI.ForegroundColor = "Cyan"
    Clear-Host
    Write-Host ""
    Write-Host "========================================"
    Write-Host "  PRINTER SPOOLER STATUS"
    Write-Host "========================================"
    Write-Host ""
    
    Write-Host "[Service Status]"
    Write-Host "----------------------------------------"
    $service = Get-Service -Name Spooler
    Write-Host "Service Name: $($service.Name)"
    Write-Host "Display Name: $($service.DisplayName)"
    Write-Host "Status: $($service.Status)"
    if ($service.Status -eq 'Running') {
        Write-Host "Status: RUNNING (OK)" -ForegroundColor Green
    } else {
        Write-Host "Status: NOT RUNNING (ERROR!)" -ForegroundColor Red
    }
    
    Write-Host ""
    Write-Host "[Print Queue]"
    Write-Host "----------------------------------------"
    $spoolPath = "$env:SystemRoot\System32\spool\PRINTERS"
    $jobCount = (Get-ChildItem -Path $spoolPath -File -ErrorAction SilentlyContinue | Measure-Object).Count
    Write-Host "Jobs in queue: $jobCount"
    
    if ($jobCount -eq 0) {
        Write-Host "Status: No stuck jobs (OK)" -ForegroundColor Green
    } elseif ($jobCount -lt 3) {
        Write-Host "Status: Normal activity" -ForegroundColor Yellow
    } else {
        Write-Host "Status: WARNING - Multiple jobs may be stuck" -ForegroundColor Red
    }
    
    Write-Host ""
    Write-Host "[Installed Printers]"
    Write-Host "----------------------------------------"
    try {
        Get-Printer | Select-Object Name, DriverName, PrinterStatus | Format-Table -AutoSize
    } catch {
        Write-Host "Unable to retrieve printer information" -ForegroundColor Yellow
    }
    
    Write-Host ""
    Write-Host "[Recent Errors - Last 5]"
    Write-Host "----------------------------------------"
    try {
        Get-EventLog -LogName System -Source 'Print' -Newest 5 -EntryType Error -ErrorAction SilentlyContinue | 
            Select-Object TimeGenerated, Message | Format-List
    } catch {
        Write-Host "No recent print errors found or unable to access event log" -ForegroundColor Yellow
    }
    
    Write-Host ""
    Write-Host "========================================"
    Read-Host "Press Enter to return to main menu"
}

# Function for PowerShell mode menu
function Show-PowerShellModeMenu {
    $Host.UI.RawUI.ForegroundColor = "Magenta"
    Clear-Host
    Write-Host ""
    Write-Host "========================================"
    Write-Host "  POWERSHELL MODE"
    Write-Host "========================================"
    Write-Host ""
    Write-Host "Advanced features with logging:"
    Write-Host ""
    Write-Host " [1] Quick Fix with Log"
    Write-Host " [2] Monitor with Logging"
    Write-Host " [3] View Recent Logs"
    Write-Host " [0] Back to Main Menu"
    Write-Host ""
    Write-Host "========================================"
    
    $choice = Read-Host "Enter your choice (0-3)"
    return $choice
}

# Function for PowerShell mode
function Invoke-PowerShellMode {
    while ($true) {
        $choice = Show-PowerShellModeMenu
        
        switch ($choice) {
            "1" { Invoke-PSFixWithLog; break }
            "2" { Invoke-PSMonitorLog; break }
            "3" { Invoke-PSViewLogs; break }
            "0" { return }
            default {
                Write-Host "Invalid choice. Please try again." -ForegroundColor Red
                Start-Sleep -Seconds 2
            }
        }
    }
}

# Function for PS fix with log
function Invoke-PSFixWithLog {
    Clear-Host
    Write-Host ""
    Write-Host "========================================"
    Write-Host "  Fix with Logging"
    Write-Host "========================================"
    Write-Host ""
    
    $date = Get-Date -Format "yyyyMMdd_HHmmss"
    $logFile = "$env:USERPROFILE\Desktop\PrinterSpooler_Fix_$date.txt"
    Write-Host "Performing fix with logging..."
    Write-Host "Log file: $logFile"
    Write-Host ""
    
    # Create log file
    @"
========================================
Printer Spooler Fix Log
Date: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
========================================

"@ | Out-File -FilePath $logFile -Encoding UTF8
    
    Invoke-SpoolerFixWithLog -LogFile $logFile
    
    Write-Host ""
    Write-Host "Fix completed! Log saved to:"
    Write-Host $logFile
    Write-Host ""
    Read-Host "Press Enter to continue"
}

# Function for PS monitor with log
function Invoke-PSMonitorLog {
    Clear-Host
    Write-Host ""
    Write-Host "========================================"
    Write-Host "  Monitor with Logging"
    Write-Host "========================================"
    Write-Host ""
    
    $date = Get-Date -Format "yyyyMMdd"
    $logFile = "$env:USERPROFILE\Desktop\PrinterSpooler_Monitor_$date.txt"
    Write-Host "Starting monitoring with logging..."
    Write-Host "Log file: $logFile"
    Write-Host ""
    Write-Host "Press Ctrl+C to stop"
    Read-Host "Press Enter to start"
    
    # Create log file
    @"
========================================
Printer Spooler Monitor Log
Started: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
========================================

"@ | Out-File -FilePath $logFile -Encoding UTF8
    
    $monitorFixes = 0
    while ($true) {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Add-Content -Path $logFile -Value "[$timestamp] Checking..."
        
        $service = Get-Service -Name Spooler
        if ($service.Status -ne 'Running') {
            Add-Content -Path $logFile -Value "[$timestamp] WARNING: Spooler not running - fixing"
            Invoke-SpoolerFixWithLog -LogFile $logFile
            $monitorFixes++
        } else {
            Add-Content -Path $logFile -Value "[$timestamp] OK: Spooler running normally"
        }
        
        Start-Sleep -Seconds 60
    }
}

# Function for PS view logs
function Invoke-PSViewLogs {
    Clear-Host
    Write-Host ""
    Write-Host "========================================"
    Write-Host "  Recent Logs"
    Write-Host "========================================"
    Write-Host ""
    Write-Host "Logs saved to: $env:USERPROFILE\Desktop\"
    Write-Host ""
    
    $logs = Get-ChildItem -Path "$env:USERPROFILE\Desktop\PrinterSpooler*.txt" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
    
    if ($logs) {
        $logs | Select-Object Name, LastWriteTime, @{Name="Size(KB)";Expression={[math]::Round($_.Length/1KB,2)}} | Format-Table -AutoSize
        Write-Host ""
        $viewLog = Read-Host "Enter filename to view (or press Enter to skip)"
        if ($viewLog) {
            $logPath = Join-Path "$env:USERPROFILE\Desktop" $viewLog
            if (Test-Path $logPath) {
                Clear-Host
                Get-Content -Path $logPath
                Write-Host ""
            } else {
                Write-Host "File not found" -ForegroundColor Red
            }
        }
    } else {
        Write-Host "No log files found."
    }
    
    Write-Host ""
    Read-Host "Press Enter to continue"
}

# Function for scheduled task setup
function Invoke-ScheduledTaskSetup {
    $Host.UI.RawUI.ForegroundColor = "Yellow"
    Clear-Host
    Write-Host ""
    Write-Host "========================================"
    Write-Host "  SETUP SCHEDULED TASK"
    Write-Host "========================================"
    Write-Host ""
    Write-Host "This will create an automatic task that fixes"
    Write-Host "the print spooler daily."
    Write-Host ""
    Write-Host "Task details:"
    Write-Host " - Runs: Daily at 3:00 AM"
    Write-Host " - Action: Fix print spooler"
    Write-Host " - Logging: Enabled"
    Write-Host ""
    
    $confirm = Read-Host "Do you want to create this task? (Y/N)"
    
    if ($confirm -ne 'Y' -and $confirm -ne 'y') {
        return
    }
    
    Write-Host ""
    Write-Host "Creating scheduled task..."
    
    try {
        $action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass -File `"$PSCommandPath`" -AutoFixSilent"
        $trigger = New-ScheduledTaskTrigger -Daily -At 3:00AM
        $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
        $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
        
        Register-ScheduledTask -TaskName "Auto Fix Printer Spooler" -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Force | Out-Null
        
        $Host.UI.RawUI.ForegroundColor = "Green"
        Write-Host ""
        Write-Host "========================================"
        Write-Host "  SUCCESS!"
        Write-Host "========================================"
        Write-Host ""
        Write-Host "Scheduled task created successfully."
        Write-Host ""
        Write-Host "The printer spooler will be automatically"
        Write-Host "fixed every day at 3:00 AM."
        Write-Host ""
        Write-Host "To remove this task:"
        Write-Host "1. Open Task Scheduler"
        Write-Host "2. Find 'Auto Fix Printer Spooler'"
        Write-Host "3. Right-click and delete"
    } catch {
        $Host.UI.RawUI.ForegroundColor = "Red"
        Write-Host ""
        Write-Host "========================================"
        Write-Host "  ERROR"
        Write-Host "========================================"
        Write-Host ""
        Write-Host "Failed to create scheduled task."
        Write-Host "Error: $_"
        Write-Host "Make sure you are running as Administrator."
    }
    
    Write-Host ""
    Write-Host "========================================"
    Read-Host "Press Enter to continue"
}

# Function to show help
function Show-Help {
    $Host.UI.RawUI.ForegroundColor = "Cyan"
    Clear-Host
    Write-Host ""
    Write-Host "========================================"
    Write-Host "  HELP GUIDE"
    Write-Host "========================================"
    Write-Host ""
    Write-Host "WHEN TO USE EACH MODE:"
    Write-Host "----------------------------------------"
    Write-Host ""
    Write-Host "[1] BASIC FIX"
    Write-Host "    Use when: Printer stopped working suddenly"
    Write-Host "    Does: Quick one-time fix"
    Write-Host "    Time: 10 seconds"
    Write-Host ""
    Write-Host "[2] ADVANCED MONITOR"
    Write-Host "    Use when: Problems happen frequently"
    Write-Host "    Does: Watches and auto-fixes every 30 sec"
    Write-Host "    Time: Runs continuously"
    Write-Host ""
    Write-Host "[3] STATUS CHECK"
    Write-Host "    Use when: Need to diagnose issues"
    Write-Host "    Does: Shows detailed printer status"
    Write-Host "    Time: 5 seconds"
    Write-Host ""
    Write-Host "[4] POWERSHELL MODE"
    Write-Host "    Use when: Need detailed logs/reports"
    Write-Host "    Does: Advanced diagnostics + logging"
    Write-Host "    Time: Varies"
    Write-Host ""
    Write-Host "[5] SCHEDULED TASK"
    Write-Host "    Use when: Want automatic daily fixes"
    Write-Host "    Does: Sets up nightly maintenance"
    Write-Host "    Time: 2 minutes to setup"
    Write-Host ""
    Write-Host "========================================"
    Write-Host "TROUBLESHOOTING:"
    Write-Host "----------------------------------------"
    Write-Host ""
    Write-Host "Q: Script won't run?"
    Write-Host "A: Right-click and 'Run with PowerShell as administrator'"
    Write-Host ""
    Write-Host "Q: Jobs still stuck after fix?"
    Write-Host "A: Try updating printer drivers or restart PC"
    Write-Host ""
    Write-Host "Q: Spooler won't start?"
    Write-Host "A: Restart computer and try again"
    Write-Host ""
    Write-Host "Q: Need to stop monitoring?"
    Write-Host "A: Press Ctrl+C"
    Write-Host ""
    Write-Host "========================================"
    Write-Host ""
    Read-Host "Press Enter to return to main menu"
}

# Function to show exit message
function Show-ExitMessage {
    $Host.UI.RawUI.ForegroundColor = "Gray"
    Clear-Host
    Write-Host ""
    Write-Host "============================================================"
    Write-Host ""
    Write-Host "           Thank you for using"
    Write-Host "       PRINTER SPOOLER FIX TOOL"
    Write-Host ""
    Write-Host "============================================================"
    Write-Host ""
    Write-Host "      Coded by: Soulitek.co.il"
    Write-Host "      IT Solutions for your business"
    Write-Host "      https://soulitek.co.il"
    Write-Host ""
    Write-Host "      (C) 2025 Soulitek - All Rights Reserved"
    Write-Host ""
    Write-Host "============================================================"
    Write-Host ""
    Write-Host "  Need IT support? Contact Soulitek for professional"
    Write-Host "  computer repair, network setup, and business IT solutions."
    Write-Host ""
    Write-Host "  Tip: Bookmark this tool for quick access when"
    Write-Host "  printer issues occur!"
    Write-Host ""
    Write-Host "============================================================"
    Write-Host ""
    Start-Sleep -Seconds 3
}

# Main script execution
# Handle AutoFixSilent parameter
if ($AutoFixSilent) {
    $date = Get-Date -Format "yyyyMMdd_HHmmss"
    $logFile = "$env:USERPROFILE\Desktop\PrinterSpooler_AutoFix_$date.txt"
    
    @"
========================================
Printer Spooler Auto Fix Log
Date: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
========================================

"@ | Out-File -FilePath $logFile -Encoding UTF8
    
    Invoke-SpoolerFixWithLog -LogFile $logFile
    exit 0
}

# Check for admin privileges
if (-not (Test-SouliTEKAdministrator)) {
    Show-AdminError
}

# Show disclaimer
Show-Disclaimer

# Main menu loop
while ($true) {
    $choice = Show-MainMenu
    
    switch ($choice) {
        "1" { Invoke-BasicFixMode }
        "2" { Invoke-AdvancedMonitorMode }
        "3" { Invoke-StatusCheckMode }
        "4" { Invoke-PowerShellMode }
        "5" { Invoke-ScheduledTaskSetup }
        "6" { Show-Help }
        "0" { 
            Show-ExitMessage
            exit 0
        }
        default {
            Write-Host "Invalid choice. Please try again." -ForegroundColor Red
            Start-Sleep -Seconds 2
        }
    }
}



