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

# Use shared banner from common module

# Utility: wait for key press before returning to menu
function Wait-SouliTEKReturnToMenu {
    Set-SouliTEKConsoleColor "White"
    Write-Host ""
    Write-Host "Press any key to return to main menu..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# Utility: ensure administrator privileges only when necessary
function Assert-SouliTEKAdministrator {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FeatureName,

        [switch]$Silent
    )

    if (Test-SouliTEKAdministrator) {
        return $true
    }

    Show-SouliTEKHeader "ADMINISTRATOR REQUIRED" "$FeatureName requires elevated privileges."
    Write-SouliTEKWarning "Open PowerShell as Administrator and retry."

    if (-not $Silent) {
        Wait-SouliTEKReturnToMenu
    }

    return $false
}

# Utility: invoke powercfg with consistent error handling
function Invoke-SouliTEKPowerCfg {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Arguments,

        [Parameter(Mandatory = $true)]
        [string]$OperationDescription,

        [Parameter(Mandatory = $false)]
        [string]$ExpectedOutputPath
    )

    $output = & powercfg @Arguments 2>&1
    $exitCode = $LASTEXITCODE

    if ($exitCode -ne 0) {
        $details = ($output -join [Environment]::NewLine).Trim()
        if (-not $details) {
            $details = "powercfg exited with code $exitCode"
        }
        throw [System.InvalidOperationException]::new("Failed to ${OperationDescription}: $details")
    }

    if ($ExpectedOutputPath -and -not (Test-Path -LiteralPath $ExpectedOutputPath)) {
        throw [System.IO.FileNotFoundException]::new("Expected output '$ExpectedOutputPath' was not generated.")
    }

    return $output
}

# Utility: generate battery report files with shared UX
function New-SouliTEKBatteryReport {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Title,

        [Parameter(Mandatory = $true)]
        [string]$Subtitle,

        [Parameter(Mandatory = $true)]
        [ValidateSet("Cyan", "Magenta", "Blue", "Yellow")]
        [string]$Color,

        [Parameter(Mandatory = $true)]
        [string]$ReportFile,

        [Parameter(Mandatory = $true)]
        [int]$DurationDays
    )

    Clear-Host
    Show-Section $Title

    Write-Ui -Message "Generating battery report" -Level "INFO"

    try {
        Invoke-SouliTEKPowerCfg -Arguments @("/batteryreport", "/output", $ReportFile, "/duration", $DurationDays) -OperationDescription "$Title (duration: $DurationDays days)" -ExpectedOutputPath $ReportFile | Out-Null
        Write-Ui -Message "Report saved to $ReportFile" -Level "OK"
        Write-Ui -Message "Opening report in your browser" -Level "INFO"
        Start-Sleep -Seconds 2
        Start-Process $ReportFile
    }
    catch {
        Write-Ui -Message $_.Exception.Message -Level "ERROR"
    }

    Wait-SouliTEKReturnToMenu
}

# Show-Disclaimer function - using Show-SouliTEKDisclaimer from common module
function Show-Disclaimer {
    Show-SouliTEKDisclaimer
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
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $reportFile = "$env:USERPROFILE\Desktop\BatteryReport_$timestamp.html"
    New-SouliTEKBatteryReport -Title "QUICK BATTERY REPORT" -Subtitle "7-day battery history overview" -Color "Yellow" -ReportFile $reportFile -DurationDays 7
}

# Function to generate detailed battery report
function New-DetailedReport {
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $reportFile = "$env:USERPROFILE\Desktop\BatteryReport_Detailed_$timestamp.html"
    New-SouliTEKBatteryReport -Title "DETAILED BATTERY REPORT" -Subtitle "28-day comprehensive analysis" -Color "Magenta" -ReportFile $reportFile -DurationDays 28
}

# Function to check battery health
function Get-BatteryHealthCheck {
    Clear-Host
    Show-Section "Battery Health Check"
    Write-Ui -Message "Analyzing current battery status" -Level "INFO"

    try {
        $battery = Get-CimInstance -ClassName Win32_Battery -ErrorAction Stop
    }
    catch {
        Write-Ui -Message "Unable to query battery information: $($_.Exception.Message)" -Level "ERROR"
        Wait-SouliTEKReturnToMenu
        return
    }

    if (-not $battery) {
        Write-Ui -Message "No battery detected. This is likely a desktop PC without a battery" -Level "WARN"
        Wait-SouliTEKReturnToMenu
        return
    }

    Write-Ui -Message "Status: $($battery.Status)" -Level "INFO"
    Write-Ui -Message "Battery Status Code: $($battery.BatteryStatus)" -Level "INFO"
    if ($null -ne $battery.EstimatedChargeRemaining) {
        Write-Ui -Message "Charge Remaining: $($battery.EstimatedChargeRemaining)%" -Level "INFO"
    }
    if ($null -ne $battery.EstimatedRunTime -and $battery.EstimatedRunTime -gt 0) {
        Write-Ui -Message "Estimated Run Time: $($battery.EstimatedRunTime) minutes" -Level "INFO"
    }

    $tempFile = Join-Path $env:TEMP "battery_temp.xml"

    try {
        Invoke-SouliTEKPowerCfg -Arguments @("/batteryreport", "/xml", "/duration", 1, "/output", $tempFile) -OperationDescription "generate temporary battery XML" -ExpectedOutputPath $tempFile | Out-Null
        try {
            [xml]$xml = Get-Content -LiteralPath $tempFile -ErrorAction Stop
            $designCapacity = [double]$xml.BatteryReport.Batteries.Battery.DesignCapacity
            $fullChargeCapacity = [double]$xml.BatteryReport.Batteries.Battery.FullChargeCapacity

            if ($designCapacity -gt 0 -and $fullChargeCapacity -gt 0) {
                $healthPercent = [math]::Round(($fullChargeCapacity / $designCapacity) * 100, 2)
        Write-Ui -Message "Design Capacity: $designCapacity mWh" -Level "INFO"
        Write-Ui -Message "Full Charge Capacity: $fullChargeCapacity mWh" -Level "INFO"

                $healthColor = if ($healthPercent -ge 80) { "Green" } elseif ($healthPercent -ge 60) { "Yellow" } elseif ($healthPercent -ge 40) { "Yellow" } else { "Red" }
                Write-Host "Battery Health: $healthPercent%" -ForegroundColor $healthColor

                Write-Ui -Message "Health Assessment: $(
                    if ($healthPercent -ge 80) { "EXCELLENT - Battery is in great condition" }
                    elseif ($healthPercent -ge 60) { "GOOD - Normal wear, still functioning well" }
                    elseif ($healthPercent -ge 40) { "FAIR - Consider replacement soon" }
                    else { "POOR - Battery replacement recommended" }
                )"
            }
            else {
                Write-Ui -Message "Unable to retrieve capacity information from powercfg output" -Level "WARN"
            }
        }
        catch {
            Write-Ui -Message "Error parsing battery report: $($_.Exception.Message)" -Level "ERROR"
        }
    }
    catch {
        Write-Ui -Message $_.Exception.Message -Level "WARN"
    }
    finally {
        if (Test-Path -LiteralPath $tempFile) {
            Remove-Item -LiteralPath $tempFile -Force -ErrorAction SilentlyContinue
        }
    }

    Wait-SouliTEKReturnToMenu
}

# Function to generate sleep study report
function New-SleepStudyReport {
    Clear-Host
    Show-Section "Sleep Study Report"
    Write-Ui -Message "Generating 7-day sleep study report" -Level "INFO"

    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $reportFile = "$env:USERPROFILE\Desktop\SleepStudy_$timestamp.html"

    try {
        Invoke-SouliTEKPowerCfg -Arguments @("/sleepstudy", "/output", $reportFile, "/duration", 7) -OperationDescription "generate sleep study report" -ExpectedOutputPath $reportFile | Out-Null
        Write-Ui -Message "Report saved to $reportFile" -Level "OK"
        Write-Ui -Message "Opening report in your browser" -Level "INFO"
        Start-Sleep -Seconds 2
        Start-Process $reportFile
    }
    catch {
        Write-Ui -Message "Sleep Study report not available: $($_.Exception.Message)" -Level "WARN"
        Write-Ui -Message "This feature requires Modern Standby support" -Level "INFO"
    }

    Wait-SouliTEKReturnToMenu
}

# Function to generate energy report
function New-EnergyReport {
    if (-not (Assert-SouliTEKAdministrator -FeatureName "run the Energy Efficiency Report" -Silent)) {
        return
    }

    Clear-Host
    Show-Section "Energy Efficiency Report"
    Write-Ui -Message "Keep your computer active during the analysis" -Level "INFO"
    Write-Ui -Message "Press any key to start or Ctrl+C to cancel" -Level "INFO"
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

    Write-Ui -Message "Running power analysis (60 seconds)" -Level "INFO"

    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $reportFile = "$env:USERPROFILE\Desktop\EnergyReport_$timestamp.html"

    try {
        Invoke-SouliTEKPowerCfg -Arguments @("/energy", "/output", $reportFile, "/duration", 60) -OperationDescription "generate energy efficiency report" -ExpectedOutputPath $reportFile | Out-Null
        Write-Ui -Message "Report saved to $reportFile" -Level "OK"
        Write-Ui -Message "Opening report in your browser" -Level "INFO"
        Start-Sleep -Seconds 2
        Start-Process $reportFile
    }
    catch {
        Write-Ui -Message $_.Exception.Message -Level "ERROR"
    }

    Wait-SouliTEKReturnToMenu
}

# Function to generate all reports
function New-AllReports {
    Clear-Host
    Show-Section "Generate All Reports"
    Write-Ui -Message "Press any key to start or Ctrl+C to cancel" -Level "INFO"
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $folder = "$env:USERPROFILE\Desktop\BatteryReports_$timestamp"
    New-Item -ItemType Directory -Path $folder -Force | Out-Null

    $reportDefinitions = @(
        @{ Index = 1; Total = 4; Label = "Quick Battery Report"; Operation = "generate quick battery report"; Arguments = @("/batteryreport", "/output", "$folder\BatteryReport_Quick.html", "/duration", 7); ExpectedPath = "$folder\BatteryReport_Quick.html"; RequiresAdmin = $false },
        @{ Index = 2; Total = 4; Label = "Detailed Battery Report"; Operation = "generate detailed battery report"; Arguments = @("/batteryreport", "/output", "$folder\BatteryReport_Detailed.html", "/duration", 28); ExpectedPath = "$folder\BatteryReport_Detailed.html"; RequiresAdmin = $false },
        @{ Index = 3; Total = 4; Label = "Sleep Study"; Operation = "generate sleep study report"; Arguments = @("/sleepstudy", "/output", "$folder\SleepStudy.html", "/duration", 7); ExpectedPath = "$folder\SleepStudy.html"; RequiresAdmin = $false },
        @{ Index = 4; Total = 4; Label = "Energy Report"; Operation = "generate energy efficiency report"; Arguments = @("/energy", "/output", "$folder\EnergyReport.html", "/duration", 60); ExpectedPath = "$folder\EnergyReport.html"; RequiresAdmin = $true }
    )

    $successfulReports = 0

    foreach ($definition in $reportDefinitions) {
        Show-Step -StepNumber $definition.Index -TotalSteps $definition.Total -Description "Generating $($definition.Label)"
        Write-Ui -Message "Generating $($definition.Label)" -Level "INFO"

        if ($definition.RequiresAdmin -and -not (Test-SouliTEKAdministrator)) {
            Write-Ui -Message "$($definition.Label) skipped: administrator privileges required" -Level "WARN"
            continue
        }

        try {
            Invoke-SouliTEKPowerCfg -Arguments $definition.Arguments -OperationDescription $definition.Operation -ExpectedOutputPath $definition.ExpectedPath | Out-Null
            Write-Ui -Message "$($definition.Label) completed" -Level "OK"
            $successfulReports++
        }
        catch {
            $message = $_.Exception.Message
            if ($definition.Label -eq "Sleep Study") {
                Write-Ui -Message "Sleep Study unavailable: $message" -Level "WARN"
                Write-Ui -Message "This feature requires Modern Standby support" -Level "INFO"
            }
            else {
                Write-Ui -Message "$($definition.Label) failed: $message" -Level "ERROR"
            }
        }
    }

    if ($successfulReports -gt 0) {
        Write-Ui -Message "All available reports saved to $folder" -Level "OK"
        Write-Ui -Message "Opening folder" -Level "INFO"
        Start-Sleep -Seconds 2
        Start-Process explorer $folder
    }
    else {
        Write-Ui -Message "No reports were generated" -Level "WARN"
    }

    Wait-SouliTEKReturnToMenu
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
    Wait-SouliTEKReturnToMenu
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
    Wait-SouliTEKReturnToMenu
}

# Function to show exit message
# Show-ExitMessage function - using Show-SouliTEKExitMessage from common module
function Show-ExitMessage {
    Show-SouliTEKExitMessage -ScriptPath $PSCommandPath -ToolName "SouliTEK Battery Report Generator"
}

# ============================================================
# MAIN SCRIPT EXECUTION
# ============================================================

# Show disclaimer
Show-Disclaimer

# Show banner
Clear-Host
Show-ScriptBanner -ScriptName "Battery Report Generator" -Purpose "Comprehensive battery health analysis and reporting"

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
