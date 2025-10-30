# ============================================================
# Battery Report Generator - Professional Edition
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
# This tool provides comprehensive battery health analysis
# and reporting for laptops and portable devices.
# 
# Features: Basic Report | Detailed Analysis | Health Check
#           Sleep Study | Energy Report | Historical Data
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

# Set window title
$Host.UI.RawUI.WindowTitle = "BATTERY REPORT GENERATOR"

# Import SouliTEK Common Functions
$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$CommonPath = Join-Path (Split-Path -Parent $ScriptRoot) "modules\SouliTEK-Common.ps1"
if (Test-Path $CommonPath) {
    . $CommonPath
} else {
    Write-Warning "SouliTEK Common Functions not found at: $CommonPath"
    Write-Warning "Some functions may not work properly."
}

# Function to show tool-specific banner
function Show-SouliTEKBanner { 
    Show-SouliTEKBanner
    Write-Host "  Battery Report Generator - Professional Tool" -ForegroundColor White
    Write-Host "  =========================================================" -ForegroundColor DarkGray
    Write-Host ""
}

# Function to show disclaimer
function Show-Disclaimer {
    Clear-Host
    Show-SouliTEKBanner
    Set-SouliTEKConsoleColor "Yellow"
    Write-Host "============================================================"
    Write-Host ""
    Write-Host "                    IMPORTANT NOTICE"
    Write-Host ""
    Write-Host "============================================================"
    Write-Host ""
    Write-Host "  This tool is provided `"AS IS`" without warranty."
    Write-Host ""
    Write-Host "  USE AT YOUR OWN RISK"
    Write-Host ""
    Write-Host "  By continuing, you acknowledge that:"
    Write-Host "  - You are solely responsible for any outcomes"
    Write-Host "  - You understand the actions this tool will perform"
    Write-Host "  - You accept full responsibility for its use"
    Write-Host ""
    Write-Host "============================================================"
    Write-Host ""
    Write-Host "Press any key to continue or Ctrl+C to cancel..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# Function to show main menu
function Show-MainMenu {
    Clear-Host
    Show-SouliTEKBanner
    Set-SouliTEKConsoleColor "Blue"
    Write-Host "Select an option:"
    Write-Host ""
    Write-Host "  [1] Quick Battery Report    - Basic health overview"
    Write-Host "  [2] Detailed Battery Report - Comprehensive analysis"
    Write-Host "  [3] Battery Health Check    - Current status only"
    Write-Host "  [4] Sleep Study Report      - Sleep/standby analysis"
    Write-Host "  [5] Energy Report           - Power efficiency analysis"
    Write-Host "  [6] All Reports Package     - Generate all reports"
    Write-Host "  [7] View Recent Reports     - Browse saved reports"
    Write-Host "  [8] Help                    - Usage guide"
    Write-Host "  [0] Exit"
    Write-Host ""
    Write-Host "========================================"
    Set-SouliTEKConsoleColor "White"
    $choice = Read-Host "Enter your choice (0-8)"
    return $choice
}

# Function to generate quick battery report
function New-QuickReport {
    Clear-Host
    Set-SouliTEKConsoleColor "Yellow"
    Write-Host ""
    Write-Host "========================================"
    Write-Host "   QUICK BATTERY REPORT"
    Write-Host "========================================"
    Write-Host ""
    Write-Host "Generating basic battery report..."
    Write-Host "This will take 5-10 seconds."
    Write-Host ""
    
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $reportFile = "$env:USERPROFILE\Desktop\BatteryReport_$timestamp.html"
    
    [void](powercfg /batteryreport /output "$reportFile" /duration 7 2>&1)
    
    if ($LASTEXITCODE -eq 0) {
        Set-SouliTEKConsoleColor "Green"
        Write-Host ""
        Write-Host "========================================"
        Write-Host "   REPORT GENERATED SUCCESSFULLY"
        Write-Host "========================================"
        Write-Host ""
        Write-Host "Report saved to:"
        Write-Host $reportFile
        Write-Host ""
        Write-Host "Opening report in your browser..."
        Start-Sleep -Seconds 2
        Start-Process $reportFile
    }
    else {
        Set-SouliTEKConsoleColor "Red"
        Write-Host ""
        Write-Host "========================================"
        Write-Host "   ERROR"
        Write-Host "========================================"
        Write-Host ""
        Write-Host "Failed to generate report."
        Write-Host "This could be because:"
        Write-Host "  - No battery detected (desktop PC?)"
        Write-Host "  - Insufficient permissions"
        Write-Host "  - System error"
    }
    
    Write-Host ""
    Set-SouliTEKConsoleColor "White"
    Write-Host "Press any key to return to main menu..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# Function to generate detailed battery report
function New-DetailedReport {
    Clear-Host
    Set-SouliTEKConsoleColor "Magenta"
    Write-Host ""
    Write-Host "========================================"
    Write-Host "   DETAILED BATTERY REPORT"
    Write-Host "========================================"
    Write-Host ""
    Write-Host "This will generate a comprehensive report"
    Write-Host "with 28 days of battery history."
    Write-Host ""
    Write-Host "This may take 10-15 seconds..."
    Write-Host ""
    
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $reportFile = "$env:USERPROFILE\Desktop\BatteryReport_Detailed_$timestamp.html"
    
    Write-Host "Analyzing battery data..."
    [void](powercfg /batteryreport /output "$reportFile" /duration 28 2>&1)
    
    if ($LASTEXITCODE -eq 0) {
        Set-SouliTEKConsoleColor "Green"
        Write-Host ""
        Write-Host "========================================"
        Write-Host "   DETAILED REPORT COMPLETED"
        Write-Host "========================================"
        Write-Host ""
        Write-Host "Report includes:"
        Write-Host "  - 28-day battery usage history"
        Write-Host "  - Design capacity vs current capacity"
        Write-Host "  - Battery drain analysis"
        Write-Host "  - Usage patterns and trends"
        Write-Host ""
        Write-Host "Report saved to:"
        Write-Host $reportFile
        Write-Host ""
        Write-Host "Opening report in your browser..."
        Start-Sleep -Seconds 2
        Start-Process $reportFile
    }
    else {
        Set-SouliTEKConsoleColor "Red"
        Write-Host ""
        Write-Host "========================================"
        Write-Host "   ERROR"
        Write-Host "========================================"
        Write-Host ""
        Write-Host "Failed to generate detailed report."
    }
    
    Write-Host ""
    Set-SouliTEKConsoleColor "White"
    Write-Host "Press any key to return to main menu..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# Function to check battery health
function Get-BatteryHealthCheck {
    Clear-Host
    Set-SouliTEKConsoleColor "Blue"
    Write-Host ""
    Write-Host "========================================"
    Write-Host "   BATTERY HEALTH CHECK"
    Write-Host "========================================"
    Write-Host ""
    Write-Host "Analyzing current battery status..."
    Write-Host ""
    
    Write-Host "BATTERY INFORMATION" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    
    $battery = Get-CimInstance Win32_Battery -ErrorAction SilentlyContinue
    
    if ($battery) {
        Write-Host "Status: $($battery.Status)"
        Write-Host "Battery Status: $($battery.BatteryStatus)"
        Write-Host "Charge Remaining: $($battery.EstimatedChargeRemaining)%"
        Write-Host "Estimated Run Time: $($battery.EstimatedRunTime) minutes"
        Write-Host ""
        
        Write-Host "DETAILED CAPACITY ANALYSIS" -ForegroundColor Cyan
        Write-Host "========================================" -ForegroundColor Cyan
        
        $tempFile = "$env:TEMP\battery_temp.xml"
        $null = powercfg /batteryreport /xml /duration 1 /output $tempFile 2>&1
        
        if (Test-Path $tempFile) {
            try {
                [xml]$xml = Get-Content $tempFile -ErrorAction Stop
                $designCapacity = $xml.BatteryReport.Batteries.Battery.DesignCapacity
                $fullChargeCapacity = $xml.BatteryReport.Batteries.Battery.FullChargeCapacity
                
                if ($designCapacity -and $fullChargeCapacity) {
                    $healthPercent = [math]::Round(($fullChargeCapacity / $designCapacity) * 100, 2)
                    Write-Host "Design Capacity: $designCapacity mWh"
                    Write-Host "Full Charge Capacity: $fullChargeCapacity mWh"
                    Write-Host "Battery Health: $healthPercent%" -ForegroundColor $(
                        if ($healthPercent -ge 80) { "Green" }
                        elseif ($healthPercent -ge 60) { "Yellow" }
                        else { "Red" }
                    )
                    Write-Host ""
                    
                    Write-Host "HEALTH ASSESSMENT:" -ForegroundColor Cyan
                    if ($healthPercent -ge 80) {
                        Write-Host "  EXCELLENT - Battery is in great condition" -ForegroundColor Green
                    }
                    elseif ($healthPercent -ge 60) {
                        Write-Host "  GOOD - Normal wear, still functioning well" -ForegroundColor Yellow
                    }
                    elseif ($healthPercent -ge 40) {
                        Write-Host "  FAIR - Consider replacement soon" -ForegroundColor Yellow
                    }
                    else {
                        Write-Host "  POOR - Battery replacement recommended" -ForegroundColor Red
                    }
                }
                else {
                    Write-Host "Unable to retrieve capacity information." -ForegroundColor Red
                }
                
                Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
            }
            catch {
                Write-Host "Error parsing battery report: $_" -ForegroundColor Red
            }
        }
        else {
            Write-Host "Unable to generate temporary battery report." -ForegroundColor Red
        }
    }
    else {
        Set-SouliTEKConsoleColor "Red"
        Write-Host "No battery detected."
        Write-Host "This is likely a desktop PC without a battery."
    }
    
    Write-Host ""
    Set-SouliTEKConsoleColor "White"
    Write-Host "Press any key to return to main menu..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# Function to generate sleep study report
function New-SleepStudyReport {
    Clear-Host
    Set-SouliTEKConsoleColor "Blue"
    Write-Host ""
    Write-Host "========================================"
    Write-Host "   SLEEP STUDY REPORT"
    Write-Host "========================================"
    Write-Host ""
    Write-Host "This analyzes battery drain during sleep."
    Write-Host "Requires Modern Standby support."
    Write-Host ""
    Write-Host "Generating report (7 days)..."
    Write-Host ""
    
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $reportFile = "$env:USERPROFILE\Desktop\SleepStudy_$timestamp.html"
    
    [void](powercfg /sleepstudy /output "$reportFile" /duration 7 2>&1)
    
    if ($LASTEXITCODE -eq 0) {
        Set-SouliTEKConsoleColor "Green"
        Write-Host ""
        Write-Host "========================================"
        Write-Host "   SLEEP STUDY COMPLETED"
        Write-Host "========================================"
        Write-Host ""
        Write-Host "Report includes:"
        Write-Host "  - Sleep sessions over last 7 days"
        Write-Host "  - Battery drain during sleep"
        Write-Host "  - Active time vs sleep time"
        Write-Host "  - Top battery drainers in sleep"
        Write-Host ""
        Write-Host "Report saved to:"
        Write-Host $reportFile
        Write-Host ""
        Write-Host "Opening report in your browser..."
        Start-Sleep -Seconds 2
        Start-Process $reportFile
    }
    else {
        Set-SouliTEKConsoleColor "Yellow"
        Write-Host ""
        Write-Host "========================================"
        Write-Host "   SLEEP STUDY NOT AVAILABLE"
        Write-Host "========================================"
        Write-Host ""
        Write-Host "Your system does not support Modern Standby."
        Write-Host "This feature is only available on systems"
        Write-Host "with Modern Standby (Connected Standby)."
    }
    
    Write-Host ""
    Set-SouliTEKConsoleColor "White"
    Write-Host "Press any key to return to main menu..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# Function to generate energy report
function New-EnergyReport {
    Clear-Host
    Set-SouliTEKConsoleColor "Yellow"
    Write-Host ""
    Write-Host "========================================"
    Write-Host "   ENERGY EFFICIENCY REPORT"
    Write-Host "========================================"
    Write-Host ""
    Write-Host "This will analyze power usage for 60 seconds."
    Write-Host ""
    Write-Host "PLEASE NOTE:"
    Write-Host "  - Keep your computer active during analysis"
    Write-Host "  - Do not close this window"
    Write-Host "  - Analysis will take exactly 60 seconds"
    Write-Host ""
    Write-Host "Press any key to start or Ctrl+C to cancel..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    
    Write-Host ""
    Write-Host "Analyzing power usage (60 seconds)..."
    Write-Host "Please wait..."
    Write-Host ""
    
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $reportFile = "$env:USERPROFILE\Desktop\EnergyReport_$timestamp.html"
    
    powercfg /energy /output "$reportFile" /duration 60
    
    if ($LASTEXITCODE -eq 0) {
        Set-SouliTEKConsoleColor "Green"
        Write-Host ""
        Write-Host "========================================"
        Write-Host "   ENERGY REPORT COMPLETED"
        Write-Host "========================================"
        Write-Host ""
        Write-Host "Report includes:"
        Write-Host "  - Power efficiency issues"
        Write-Host "  - USB device power usage"
        Write-Host "  - CPU utilization"
        Write-Host "  - Battery discharge rate"
        Write-Host "  - Configuration warnings"
        Write-Host ""
        Write-Host "Report saved to:"
        Write-Host $reportFile
        Write-Host ""
        Write-Host "Opening report in your browser..."
        Start-Sleep -Seconds 2
        Start-Process $reportFile
    }
    else {
        Set-SouliTEKConsoleColor "Red"
        Write-Host ""
        Write-Host "========================================"
        Write-Host "   ERROR"
        Write-Host "========================================"
        Write-Host ""
        Write-Host "Failed to generate energy report."
    }
    
    Write-Host ""
    Set-SouliTEKConsoleColor "White"
    Write-Host "Press any key to return to main menu..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# Function to generate all reports
function New-AllReports {
    Clear-Host
    Set-SouliTEKConsoleColor "Magenta"
    Write-Host ""
    Write-Host "========================================"
    Write-Host "   GENERATE ALL REPORTS"
    Write-Host "========================================"
    Write-Host ""
    Write-Host "This will generate:"
    Write-Host "  1. Battery Report (7 days)"
    Write-Host "  2. Detailed Battery Report (28 days)"
    Write-Host "  3. Sleep Study (7 days)"
    Write-Host "  4. Energy Report (60 seconds)"
    Write-Host ""
    Write-Host "Total time: Approximately 2-3 minutes"
    Write-Host ""
    Write-Host "Press any key to start or Ctrl+C to cancel..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $folder = "$env:USERPROFILE\Desktop\BatteryReports_$timestamp"
    New-Item -ItemType Directory -Path $folder -Force | Out-Null
    
    Clear-Host
    Write-Host ""
    Write-Host "========================================"
    Write-Host "   GENERATING ALL REPORTS"
    Write-Host "========================================"
    Write-Host ""
    
    Write-Host "[1/4] Generating Quick Battery Report..."
    [void](powercfg /batteryreport /output "$folder\BatteryReport_Quick.html" /duration 7 2>&1)
    if ($LASTEXITCODE -eq 0) {
        Write-Host "      [OK] Quick report completed" -ForegroundColor Green
    } else {
        Write-Host "      [FAILED] Quick report" -ForegroundColor Red
    }
    
    Write-Host "[2/4] Generating Detailed Battery Report..."
    [void](powercfg /batteryreport /output "$folder\BatteryReport_Detailed.html" /duration 28 2>&1)
    if ($LASTEXITCODE -eq 0) {
        Write-Host "      [OK] Detailed report completed" -ForegroundColor Green
    } else {
        Write-Host "      [FAILED] Detailed report" -ForegroundColor Red
    }
    
    Write-Host "[3/4] Generating Sleep Study..."
    [void](powercfg /sleepstudy /output "$folder\SleepStudy.html" /duration 7 2>&1)
    if ($LASTEXITCODE -eq 0) {
        Write-Host "      [OK] Sleep study completed" -ForegroundColor Green
    } else {
        Write-Host "      [SKIP] Sleep study not available" -ForegroundColor Yellow
    }
    
    Write-Host "[4/4] Generating Energy Report (60 seconds)..."
    powercfg /energy /output "$folder\EnergyReport.html" /duration 60 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "      [OK] Energy report completed" -ForegroundColor Green
    } else {
        Write-Host "      [FAILED] Energy report" -ForegroundColor Red
    }
    
    Set-SouliTEKConsoleColor "Green"
    Write-Host ""
    Write-Host "========================================"
    Write-Host "   ALL REPORTS COMPLETED"
    Write-Host "========================================"
    Write-Host ""
    Write-Host "All reports saved to:"
    Write-Host $folder
    Write-Host ""
    Write-Host "Opening folder..."
    Start-Sleep -Seconds 2
    Start-Process explorer $folder
    
    Write-Host ""
    Set-SouliTEKConsoleColor "White"
    Write-Host "Press any key to return to main menu..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# Function to view recent reports
function Show-RecentReports {
    Clear-Host
    Set-SouliTEKConsoleColor "Blue"
    Write-Host ""
    Write-Host "========================================"
    Write-Host "   RECENT BATTERY REPORTS"
    Write-Host "========================================"
    Write-Host ""
    Write-Host "Reports on Desktop:"
    Write-Host ""
    
    $reports = Get-ChildItem "$env:USERPROFILE\Desktop" -Filter "Battery*.html" -ErrorAction SilentlyContinue |
               Sort-Object LastWriteTime -Descending
    $reports += Get-ChildItem "$env:USERPROFILE\Desktop" -Filter "Sleep*.html" -ErrorAction SilentlyContinue |
                Sort-Object LastWriteTime -Descending
    $reports += Get-ChildItem "$env:USERPROFILE\Desktop" -Filter "Energy*.html" -ErrorAction SilentlyContinue |
                Sort-Object LastWriteTime -Descending
    
    if ($reports) {
        $reports | Sort-Object LastWriteTime -Descending | Select-Object -First 10 | ForEach-Object {
            Write-Host $_.Name
        }
        Write-Host ""
        $openFile = Read-Host "Enter filename to open (or press Enter to skip)"
        if ($openFile) {
            $filePath = "$env:USERPROFILE\Desktop\$openFile"
            if (Test-Path $filePath) {
                Start-Process $filePath
            }
            else {
                Write-Host "File not found." -ForegroundColor Red
            }
        }
    }
    else {
        Write-Host "No report files found on Desktop."
    }
    
    Write-Host ""
    Write-Host "Report folders on Desktop:"
    Write-Host ""
    
    $folders = Get-ChildItem "$env:USERPROFILE\Desktop" -Directory -Filter "BatteryReports*" -ErrorAction SilentlyContinue |
               Sort-Object LastWriteTime -Descending
    
    if ($folders) {
        $folders | ForEach-Object {
            Write-Host $_.Name
        }
        Write-Host ""
        $openFolder = Read-Host "Enter folder name to open (or press Enter to skip)"
        if ($openFolder) {
            $folderPath = "$env:USERPROFILE\Desktop\$openFolder"
            if (Test-Path $folderPath) {
                Start-Process explorer $folderPath
            }
            else {
                Write-Host "Folder not found." -ForegroundColor Red
            }
        }
    }
    else {
        Write-Host "No report folders found."
    }
    
    Write-Host ""
    Set-SouliTEKConsoleColor "White"
    Write-Host "Press any key to return to main menu..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# Function to show help
function Show-Help {
    Clear-Host
    Set-SouliTEKConsoleColor "Blue"
    Write-Host ""
    Write-Host "========================================"
    Write-Host "   HELP GUIDE"
    Write-Host "========================================"
    Write-Host ""
    Write-Host "WHEN TO USE EACH REPORT:"
    Write-Host "----------------------------------------"
    Write-Host ""
    Write-Host "[1] QUICK BATTERY REPORT"
    Write-Host "    Use when: Need a fast health overview"
    Write-Host "    Shows: Last 7 days of battery usage"
    Write-Host "    Time: 5-10 seconds"
    Write-Host ""
    Write-Host "[2] DETAILED BATTERY REPORT"
    Write-Host "    Use when: Need comprehensive analysis"
    Write-Host "    Shows: 28 days of detailed battery data"
    Write-Host "    Time: 10-15 seconds"
    Write-Host ""
    Write-Host "[3] BATTERY HEALTH CHECK"
    Write-Host "    Use when: Want current status only"
    Write-Host "    Shows: Real-time battery health percentage"
    Write-Host "    Time: 5 seconds"
    Write-Host ""
    Write-Host "[4] SLEEP STUDY REPORT"
    Write-Host "    Use when: Battery drains during sleep"
    Write-Host "    Shows: Sleep sessions and drain rates"
    Write-Host "    Time: 5-10 seconds"
    Write-Host ""
    Write-Host "[5] ENERGY REPORT"
    Write-Host "    Use when: Battery drains too fast"
    Write-Host "    Shows: Power efficiency issues"
    Write-Host "    Time: 60 seconds (measures usage)"
    Write-Host ""
    Write-Host "[6] ALL REPORTS PACKAGE"
    Write-Host "    Use when: Need complete analysis"
    Write-Host "    Shows: Everything in one folder"
    Write-Host "    Time: 2-3 minutes"
    Write-Host ""
    Write-Host "========================================"
    Write-Host "UNDERSTANDING BATTERY HEALTH:"
    Write-Host "----------------------------------------"
    Write-Host ""
    Write-Host "Battery Health = Current Capacity / Design Capacity"
    Write-Host ""
    Write-Host "100-80%  : EXCELLENT - Battery like new"
    Write-Host "80-60%   : GOOD - Normal wear"
    Write-Host "60-40%   : FAIR - Consider replacement"
    Write-Host "Below 40%: POOR - Replace battery soon"
    Write-Host ""
    Write-Host "========================================"
    Write-Host "TROUBLESHOOTING:"
    Write-Host "----------------------------------------"
    Write-Host ""
    Write-Host "Q: `"No battery detected`" error?"
    Write-Host "A: This is likely a desktop PC without battery"
    Write-Host ""
    Write-Host "Q: Reports show unexpected drain?"
    Write-Host "A: Check Energy Report for power-hungry apps"
    Write-Host ""
    Write-Host "Q: Sleep Study not available?"
    Write-Host "A: Your PC may not support Modern Standby"
    Write-Host ""
    Write-Host "Q: Where are reports saved?"
    Write-Host "A: Desktop folder (individual or packaged)"
    Write-Host ""
    Write-Host "========================================"
    Write-Host ""
    Set-SouliTEKConsoleColor "White"
    Write-Host "Press any key to return to main menu..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# Function to show exit message
function Show-ExitMessage {
    Clear-Host
    Set-SouliTEKConsoleColor "Gray"
    Write-Host ""
    Write-Host "============================================================"
    Write-Host ""
    Write-Host "            Thank you for using"
    Write-Host "        BATTERY REPORT GENERATOR"
    Write-Host ""
    Write-Host "============================================================"
    Write-Host ""
    Write-Host "       Coded by: Soulitek.co.il"
    Write-Host "       IT Solutions for your business"
    Write-Host "       www.soulitek.co.il"
    Write-Host ""
    Write-Host "       (C) 2025 Soulitek - All Rights Reserved"
    Write-Host ""
    Write-Host "============================================================"
    Write-Host ""
    Write-Host "   Need IT support? Contact Soulitek for professional"
    Write-Host "   computer repair, network setup, and business IT solutions."
    Write-Host ""
    Write-Host "   Tip: Run this tool monthly to monitor battery health!"
    Write-Host ""
    Write-Host "============================================================"
    Write-Host ""
    Start-Sleep -Seconds 5
}

# ============================================================
# MAIN SCRIPT EXECUTION
# ============================================================

# Check for administrator privileges
if (-not (Test-SouliTEKAdministrator)) {
    Set-SouliTEKConsoleColor "Red"
    Clear-Host
    Write-Host ""
    Write-Host "========================================"
    Write-Host "   ERROR: Administrator Required"
    Write-Host "========================================"
    Write-Host ""
    Write-Host "This script must run as Administrator."
    Write-Host ""
    Write-Host "HOW TO FIX:"
    Write-Host "1. Right-click this file"
    Write-Host "2. Select `"Run with PowerShell`""
    Write-Host "3. Or open PowerShell as Admin and run:"
    Write-Host "   .\battery_report_generator.ps1"
    Write-Host ""
    Write-Host "========================================"
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit 1
}

# Show disclaimer
Show-Disclaimer

# Main menu loop
do {
    $choice = Show-MainMenu
    
    switch ($choice) {
        "1" { New-QuickReport }
        "2" { New-DetailedReport }
        "3" { Get-BatteryHealthCheck }
        "4" { New-SleepStudyReport }
        "5" { New-EnergyReport }
        "6" { New-AllReports }
        "7" { Show-RecentReports }
        "8" { Show-Help }
        "0" { 
            Show-ExitMessage
            break
        }
        default {
            Write-Host "Invalid choice. Please try again." -ForegroundColor Red
            Start-Sleep -Seconds 2
        }
    }
} while ($choice -ne "0")


