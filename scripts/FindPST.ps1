<#
.SYNOPSIS
    PST Finder - All-in-One Tool
    
.DESCRIPTION
    This tool finds Outlook PST files across the system, summarizes their sizes,
    and exports clean reports with multiple scanning options.
    
    Features: Quick Scan | Deep Scan | Summary | Advanced Reports | Scheduled Scan
    
.NOTES
    Coded by: Soulitek.co.il
    IT Solutions for your business
    Website: www.soulitek.co.il
    
    (C) 2025 Soulitek - All Rights Reserved
    
    Professional IT Solutions:
    - Computer Repair & Maintenance
    - Network Setup & Support
    - Software Solutions
    - Business IT Consulting
    
    IMPORTANT DISCLAIMER:
    This tool is provided "AS IS" without warranty of any kind.
    Use of this tool is at your own risk. The user is solely
    responsible for any outcomes, damages, or issues that may
    arise from using this script. By running this tool, you
    acknowledge and accept full responsibility for its use.
    
.PARAMETER AutoScan
    Runs an automated deep scan and saves results to Desktop (for scheduled tasks)
    
.EXAMPLE
    .\FindPST.ps1
    Launches the interactive menu
    
.EXAMPLE
    .\FindPST.ps1 -AutoScan
    Runs automated scan for scheduled tasks
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [switch]$AutoScan
)

# ============================================================
# GLOBAL VARIABLES
# ============================================================

$Script:WorkDir = Join-Path $env:TEMP "PSTFinder"
$Script:LastReport = Join-Path $Script:WorkDir "LastScan.csv"
$Script:LastSummary = Join-Path $Script:WorkDir "LastSummary.txt"

# Ensure working directory exists
if (-not (Test-Path $Script:WorkDir)) {
    New-Item -ItemType Directory -Path $Script:WorkDir -Force | Out-Null
}

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
# HELPER FUNCTIONS
# ============================================================

# Use shared banner from common module

# Function to check admin privileges
function Test-Administrator { Test-SouliTEKAdministrator }





# Show-Header function - wrapper using Show-SouliTEKHeader from common module
function Show-Header {
    param([string]$Title, [ConsoleColor]$Color = 'Cyan')
    
    Show-SouliTEKHeader -Title $Title -Color $Color -ClearHost -ShowBanner
}

function Get-PSTFiles {
    param(
        [Parameter(Mandatory=$true)]
        [string[]]$Paths,
        
        [Parameter(Mandatory=$false)]
        [switch]$Recurse
    )
    
    $ErrorActionPreference = 'SilentlyContinue'
    $allFiles = @()
    
    foreach ($path in $Paths) {
        if ($Recurse) {
            $allFiles += Get-ChildItem -Path $path -Filter "*.pst" -File -Recurse -ErrorAction SilentlyContinue
        } else {
            $allFiles += Get-ChildItem -Path $path -Filter "*.pst" -File -ErrorAction SilentlyContinue
        }
    }
    
    return $allFiles
}

function Export-PSTReport {
    param(
        [Parameter(Mandatory=$true)]
        $Files,
        
        [Parameter(Mandatory=$true)]
        [string]$OutputPath
    )
    
    if ($Files.Count -eq 0) {
        return $false
    }
    
    $Files | Select-Object @{n='FullName';e={$_.FullName}},
                           @{n='SizeBytes';e={$_.Length}},
                           @{n='SizeMB';e={[Math]::Round($_.Length/1MB,2)}},
                           @{n='SizeGB';e={[Math]::Round($_.Length/1GB,2)}},
                           LastWriteTime |
        Sort-Object SizeBytes -Descending |
        Export-Csv -NoTypeInformation -Encoding UTF8 -Path $OutputPath
    
    return $true
}

function Save-Summary {
    param(
        [Parameter(Mandatory=$true)]
        $Files
    )
    
    $count = $Files.Count
    $totalGB = [Math]::Round(($Files | Measure-Object -Property Length -Sum).Sum / 1GB, 2)
    $summary = "Found: $count PSTs | Total Size: $totalGB GB"
    
    Set-Content -Path $Script:LastSummary -Value $summary -Force
    return $summary
}

# ============================================================
# CHECK ADMINISTRATOR
# ============================================================

function Confirm-Administrator {
    if (-not (Test-SouliTEKAdministrator)) {
        Show-Header "ERROR: Administrator Required" -Color Red
        Write-Ui -Message "  This script must run as Administrator." -Level "WARN"
        Write-Host ""
        Write-Ui -Message "  HOW TO FIX:" -Level "STEP"
        Write-Ui -Message "  1. Right-click this file" -Level "INFO"
        Write-Ui -Message "  2. Select 'Run with PowerShell'" -Level "INFO"
        Write-Ui -Message "  3. Choose 'Run as Administrator'" -Level "INFO"
        Write-Host ""
        Write-Host "============================================================" -ForegroundColor Red
        Write-Host ""
        Write-Ui -Message "Press any key to exit..." -Level "WARN"
        $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
        exit 1
    }
}

# ============================================================
# DISCLAIMER
# ============================================================

# Show-Disclaimer function - using Show-SouliTEKDisclaimer from common module
function Show-Disclaimer {
    Show-SouliTEKDisclaimer
}

# ============================================================
# MAIN MENU
# ============================================================

function Show-MainMenu {
    do {
        Show-Header "PST FINDER TOOL - All-in-One" -Color Cyan
        
        Write-Ui -Message "      Coded by: Soulitek.co.il" -Level "OK"
        Write-Ui -Message "      IT Solutions for your business" -Level "OK"
        Write-Ui -Message "      www.soulitek.co.il" -Level "OK"
        Write-Host ""
        Write-Ui -Message "      (C) 2025 Soulitek - All Rights Reserved" -Level "INFO"
        Write-Host ""
        Write-Host "============================================================" -ForegroundColor Cyan
        Write-Host ""
        Write-Ui -Message "Select an option:" -Level "STEP"
        Write-Host ""
        Write-Ui -Message "  [1] Quick Scan         - Common PST locations" -Level "WARN"
        Write-Ui -Message "  [2] Deep Scan          - All fixed drives (full)" -Level "WARN"
        Write-Ui -Message "  [3] Summary            - View last scan summary" -Level "WARN"
        Write-Ui -Message "  [4] PowerShell Mode    - Advanced report options" -Level "WARN"
        Write-Ui -Message "  [5] Scheduled Scan     - Setup daily CSV report" -Level "WARN"
        Write-Ui -Message "  [6] Help               - Usage guide" -Level "WARN"
        Write-Ui -Message "  [0] Exit" -Level "ERROR"
        Write-Host ""
        Write-Host "========================================" -ForegroundColor DarkGray
        
        $choice = Read-Host "Enter your choice (0-6)"
        
        switch ($choice) {
            '1' { Invoke-QuickScan }
            '2' { Invoke-DeepScan }
            '3' { Show-Summary }
            '4' { Show-PowerShellMode }
            '5' { Set-ScheduledTask }
            '6' { Show-Help }
            '0' { Show-Exit; return }
            default {
                Write-Ui -Message "Invalid choice. Please try again." -Level "ERROR"
                Start-Sleep -Seconds 2
            }
        }
    } while ($true)
}

# ============================================================
# QUICK SCAN
# ============================================================

function Invoke-QuickScan {
    Show-Header "QUICK SCAN - Common PST Locations" -Color Yellow
    
    Write-Ui -Message "Scanning:" -Level "STEP"
    Write-Ui -Message "  - C:\Users\*\Documents\Outlook Files" -Level "INFO"
    Write-Ui -Message "  - C:\Users\*\AppData\Local\Microsoft\Outlook" -Level "INFO"
    Write-Ui -Message "  - Root of each profile" -Level "INFO"
    Write-Host ""
    Write-Ui -Message "Please wait..." -Level "INFO"
    Write-Host ""
    
    $searchPaths = @(
        "C:\Users\*\Documents\Outlook Files",
        "C:\Users\*\AppData\Local\Microsoft\Outlook",
        "C:\Users\*"
    )
    
    $files = Get-PSTFiles -Paths $searchPaths -Recurse
    
    if ($files.Count -gt 0) {
        [void](Export-PSTReport -Files $files -OutputPath $Script:LastReport)
        $summary = Save-Summary -Files $files
        
        Write-Host "========================================" -ForegroundColor Green
        Write-Ui -Message "  SUCCESS!" -Level "OK"
        Write-Host "========================================" -ForegroundColor Green
        Write-Host ""
        Write-Ui -Message "  $summary" -Level "STEP"
        Write-Host ""
        Write-Ui -Message "Report saved to:" -Level "INFO"
        Write-Ui -Message "  $Script:LastReport" -Level "WARN"
    } else {
        Write-Ui -Message "No PST files found in common locations." -Level "ERROR"
    }
    
    Write-Host ""
    Write-Ui -Message "Press any key to return to main menu..." -Level "INFO"
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
}

# ============================================================
# DEEP SCAN
# ============================================================

function Invoke-DeepScan {
    Show-Header "DEEP SCAN - All Fixed Drives" -Color Magenta
    
    Write-Ui -Message "This may take time depending on disk size." -Level "WARN"
    Write-Ui -Message "Press any key to start, or Ctrl+C to cancel..." -Level "INFO"
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
    Write-Host ""
    Write-Ui -Message "Scanning all fixed drives..." -Level "INFO"
    Write-Host ""
    
    # Get all fixed drives
    $drives = Get-Volume | Where-Object { $_.DriveLetter -and $_.DriveType -eq 'Fixed' } | 
              Select-Object -ExpandProperty DriveLetter
    
    $allFiles = @()
    foreach ($drive in $drives) {
        $drivePath = "$($drive):\"
        Write-Ui -Message "  Scanning drive $drivePath..." -Level "INFO"
        $allFiles += Get-PSTFiles -Paths @($drivePath) -Recurse
    }
    
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $deepReport = Join-Path $Script:WorkDir "DeepScan_$timestamp.csv"
    
    if ($allFiles.Count -gt 0) {
        [void](Export-PSTReport -Files $allFiles -OutputPath $deepReport)
        Copy-Item $deepReport $Script:LastReport -Force
        $summary = Save-Summary -Files $allFiles
        
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Green
        Write-Ui -Message "  SUCCESS!" -Level "OK"
        Write-Host "========================================" -ForegroundColor Green
        Write-Host ""
        Write-Ui -Message "  $summary" -Level "STEP"
        Write-Host ""
        Write-Ui -Message "Deep report saved to:" -Level "INFO"
        Write-Ui -Message "  $deepReport" -Level "WARN"
    } else {
        Write-Host ""
        Write-Ui -Message "No PST files found on fixed drives." -Level "ERROR"
    }
    
    Write-Host ""
    Write-Ui -Message "Press any key to return to main menu..." -Level "INFO"
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
}

# ============================================================
# SUMMARY
# ============================================================

function Show-Summary {
    Show-Header "PST FINDER - LAST SCAN SUMMARY" -Color Cyan
    
    if (-not (Test-Path $Script:LastSummary)) {
        Write-Ui -Message "No scan has been performed yet." -Level "WARN"
        Write-Ui -Message "Please run a Quick or Deep Scan first." -Level "WARN"
    } else {
        $summary = Get-Content $Script:LastSummary
        Write-Ui -Message "  $summary" -Level "STEP"
        Write-Host ""
        
        if (Test-Path $Script:LastReport) {
            Write-Ui -Message "Top 10 Largest PST Files:" -Level "INFO"
            Write-Host "----------------------------------------" -ForegroundColor DarkGray
            Write-Host ""
            
            $data = Import-Csv $Script:LastReport | Select-Object -First 10
            $data | Format-Table @{Label='Size (GB)';Expression={$_.SizeGB};Width=10},
                                 @{Label='Size (MB)';Expression={$_.SizeMB};Width=10},
                                 @{Label='Last Modified';Expression={$_.LastWriteTime};Width=20},
                                 @{Label='Path';Expression={$_.FullName}} -AutoSize
        }
    }
    
    Write-Host ""
    Write-Ui -Message "Press any key to return to main menu..." -Level "INFO"
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
}

# ============================================================
# POWERSHELL MODE
# ============================================================

function Show-PowerShellMode {
    do {
        Show-Header "POWERSHELL MODE - Advanced Reports" -Color Green
        
        Write-Ui -Message "  [1] Export to HTML" -Level "WARN"
        Write-Ui -Message "  [2] Export to XLSX (requires Excel)" -Level "WARN"
        Write-Ui -Message "  [3] PSTs per User Profile" -Level "WARN"
        Write-Ui -Message "  [4] Custom Path Scan" -Level "WARN"
        Write-Ui -Message "  [0] Back to Main Menu" -Level "ERROR"
        Write-Host ""
        Write-Host "========================================" -ForegroundColor DarkGray
        
        $choice = Read-Host "Enter your choice (0-4)"
        
        switch ($choice) {
            '1' { Export-ToHTML }
            '2' { Export-ToXLSX }
            '3' { Show-PerUserStats }
            '4' { Invoke-CustomPathScan }
            '0' { return }
            default {
                Write-Ui -Message "Invalid choice. Please try again." -Level "ERROR"
                Start-Sleep -Seconds 2
            }
        }
    } while ($true)
}

function Export-ToHTML {
    Clear-Host
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Ui -Message "   Export to HTML" -Level "OK"
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    
    if (-not (Test-Path $Script:LastReport)) {
        Write-Ui -Message "No last scan found. Run Quick or Deep Scan first." -Level "ERROR"
        Write-Host ""
        Read-Host "Press Enter to continue"
        return
    }
    
    $timestamp = Get-Date -Format "yyyyMMdd"
    $htmlFile = Join-Path $env:USERPROFILE "Desktop\PST_Report_$timestamp.html"
    
    $data = Import-Csv $Script:LastReport
    $totalGB = [Math]::Round(($data | ForEach-Object { [double]$_.SizeBytes } | Measure-Object -Sum).Sum / 1GB, 2)
    
    $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>PST Finder Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; background-color: #f5f5f5; }
        h1 { color: #2c3e50; }
        .summary { background-color: #3498db; color: white; padding: 15px; border-radius: 5px; margin-bottom: 20px; }
        table { width: 100%; border-collapse: collapse; background-color: white; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        th { background-color: #2c3e50; color: white; padding: 12px; text-align: left; }
        td { padding: 10px; border-bottom: 1px solid #ddd; }
        tr:hover { background-color: #f5f5f5; }
        .footer { margin-top: 20px; text-align: center; color: #7f8c8d; font-size: 12px; }
    </style>
</head>
<body>
    <h1>PST Finder Report</h1>
    <div class="summary">
        <h2>Summary</h2>
        <p>Total PST Files: $($data.Count)</p>
        <p>Total Size: $totalGB GB</p>
        <p>Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</p>
    </div>
    <table>
        <tr>
            <th>Full Path</th>
            <th>Size (MB)</th>
            <th>Size (GB)</th>
            <th>Last Modified</th>
        </tr>
"@
    
    foreach ($row in $data) {
        $html += @"
        <tr>
            <td>$($row.FullName)</td>
            <td>$($row.SizeMB)</td>
            <td>$($row.SizeGB)</td>
            <td>$($row.LastWriteTime)</td>
        </tr>
"@
    }
    
    $html += @"
    </table>
    <div class="footer">
        <p>Generated by PST Finder Tool | Coded by Soulitek.co.il</p>
        <p>www.soulitek.co.il | (C) 2025 Soulitek - All Rights Reserved</p>
    </div>
</body>
</html>
"@
    
    Set-Content -Path $htmlFile -Value $html -Encoding UTF8
    
    Write-Ui -Message "Exported: $htmlFile" -Level "OK"
    Write-Host ""
    Read-Host "Press Enter to continue"
}

function Export-ToXLSX {
    Clear-Host
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Ui -Message "   Export to XLSX" -Level "OK"
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    
    if (-not (Test-Path $Script:LastReport)) {
        Write-Ui -Message "No last scan found. Run Quick or Deep Scan first." -Level "ERROR"
        Write-Host ""
        Read-Host "Press Enter to continue"
        return
    }
    
    try {
        $timestamp = Get-Date -Format "yyyyMMdd"
        $xlsxFile = Join-Path $env:USERPROFILE "Desktop\PST_Report_$timestamp.xlsx"
        
        $excel = New-Object -ComObject Excel.Application
        $excel.Visible = $false
        $workbook = $excel.Workbooks.Add()
        $worksheet = $workbook.Worksheets.Item(1)
        $worksheet.Name = "PST Report"
        
        $data = Import-Csv $Script:LastReport
        
        # Add headers
        $headers = @('Full Path', 'Size (Bytes)', 'Size (MB)', 'Size (GB)', 'Last Modified')
        for ($i = 0; $i -lt $headers.Count; $i++) {
            $worksheet.Cells.Item(1, $i + 1).Value2 = $headers[$i]
            $worksheet.Cells.Item(1, $i + 1).Font.Bold = $true
        }
        
        # Add data
        $row = 2
        foreach ($item in $data) {
            $worksheet.Cells.Item($row, 1).Value2 = $item.FullName
            $worksheet.Cells.Item($row, 2).Value2 = $item.SizeBytes
            $worksheet.Cells.Item($row, 3).Value2 = $item.SizeMB
            $worksheet.Cells.Item($row, 4).Value2 = $item.SizeGB
            $worksheet.Cells.Item($row, 5).Value2 = $item.LastWriteTime
            $row++
        }
        
        # Auto-fit columns
        $worksheet.UsedRange.EntireColumn.AutoFit() | Out-Null
        
        # Save and close
        $workbook.SaveAs($xlsxFile, 51)
        $workbook.Close($true)
        $excel.Quit()
        
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($excel) | Out-Null
        
        Write-Ui -Message "Exported: $xlsxFile" -Level "OK"
    }
    catch {
        Write-Ui -Message "Failed to export XLSX. Is Excel installed?" -Level "ERROR"
        Write-Ui -Message "Error: $($_.Exception.Message)" -Level "ERROR"
    }
    
    Write-Host ""
    Read-Host "Press Enter to continue"
}

function Show-PerUserStats {
    Clear-Host
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Ui -Message "   PSTs per User Profile" -Level "INFO"
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    
    if (-not (Test-Path $Script:LastReport)) {
        Write-Ui -Message "No last scan found. Run Quick or Deep Scan first." -Level "ERROR"
        Write-Host ""
        Read-Host "Press Enter to continue"
        return
    }
    
    $data = Import-Csv $Script:LastReport
    
    $userStats = $data | Group-Object {
        if ($_.FullName -match '^C:\\Users\\([^\\]+)') {
            $matches[1]
        } else {
            "Other"
        }
    } | Select-Object @{Name='User';Expression={$_.Name}},
                       @{Name='Count';Expression={$_.Count}},
                       @{Name='TotalMB';Expression={[Math]::Round(($_.Group | ForEach-Object { [double]$_.SizeMB } | Measure-Object -Sum).Sum, 2)}} |
        Sort-Object TotalMB -Descending
    
    $userStats | Format-Table -AutoSize
    
    Write-Host ""
    Read-Host "Press Enter to continue"
}

function Invoke-CustomPathScan {
    Clear-Host
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Ui -Message "   Custom Path Scan" -Level "INFO"
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    
    $customPath = Read-Host "Enter a folder or drive to scan (e.g. D:\Data)"
    
    if ([string]::IsNullOrWhiteSpace($customPath)) {
        return
    }
    
    if (-not (Test-Path $customPath)) {
        Write-Host ""
        Write-Ui -Message "Path does not exist: $customPath" -Level "ERROR"
        Write-Host ""
        Read-Host "Press Enter to continue"
        return
    }
    
    Write-Host ""
    Write-Ui -Message "Scanning $customPath..." -Level "INFO"
    Write-Host ""
    
    $files = Get-PSTFiles -Paths @($customPath) -Recurse
    
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $customReport = Join-Path $Script:WorkDir "CustomScan_$timestamp.csv"
    
    if ($files.Count -gt 0) {
        [void](Export-PSTReport -Files $files -OutputPath $customReport)
        Copy-Item $customReport $Script:LastReport -Force
        $summary = Save-Summary -Files $files
        
        Write-Host "========================================" -ForegroundColor Green
        Write-Ui -Message "  $summary" -Level "STEP"
        Write-Host "========================================" -ForegroundColor Green
        Write-Host ""
        Write-Ui -Message "Report saved to:" -Level "INFO"
        Write-Ui -Message "  $customReport" -Level "WARN"
    } else {
        Write-Ui -Message "No PST files found in the specified path." -Level "ERROR"
    }
    
    Write-Host ""
    Read-Host "Press Enter to continue"
}

# ============================================================
# SCHEDULED TASK
# ============================================================

function Set-ScheduledTask {
    Show-Header "SETUP SCHEDULED DAILY SCAN" -Color Yellow
    
    Write-Ui -Message "This creates a daily scan that exports a CSV" -Level "STEP"
    Write-Ui -Message "of all PSTs on fixed drives to your Desktop." -Level "STEP"
    Write-Host ""
    Write-Ui -Message "Task details:" -Level "INFO"
    Write-Ui -Message "  - Runs: Daily at 3:00 AM" -Level "INFO"
    Write-Ui -Message "  - Action: Deep scan, CSV to Desktop" -Level "INFO"
    Write-Host ""
    
    $confirm = Read-Host "Do you want to create this task? (Y/N)"
    
    if ($confirm -ne 'Y' -and $confirm -ne 'y') {
        return
    }
    
    Write-Host ""
    Write-Ui -Message "Creating scheduled task..." -Level "INFO"
    
    try {
        $scriptPath = $PSCommandPath
        $action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`" -AutoScan"
        $trigger = New-ScheduledTaskTrigger -Daily -At 3:00AM
        $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
        $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
        
        Register-ScheduledTask -TaskName "SouliTEK - PST Daily Scan" -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Force | Out-Null
        
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Green
        Write-Ui -Message "  SUCCESS!" -Level "OK"
        Write-Host "========================================" -ForegroundColor Green
        Write-Host ""
        Write-Ui -Message "Scheduled task created successfully." -Level "STEP"
        Write-Ui -Message "CSV reports will appear daily on your Desktop." -Level "STEP"
    }
    catch {
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Red
        Write-Ui -Message "  ERROR" -Level "ERROR"
        Write-Host "========================================" -ForegroundColor Red
        Write-Host ""
        Write-Ui -Message "Failed to create scheduled task." -Level "WARN"
        Write-Ui -Message "Error: $($_.Exception.Message)" -Level "ERROR"
    }
    
    Write-Host ""
    Write-Host "========================================" -ForegroundColor DarkGray
    Read-Host "Press Enter to continue"
}

# ============================================================
# HELP
# ============================================================

function Show-Help {
    Show-Header "HELP GUIDE" -Color Cyan
    
    Write-Ui -Message "WHEN TO USE EACH MODE:" -Level "STEP"
    Write-Host "----------------------------------------" -ForegroundColor DarkGray
    Write-Host ""
    Write-Ui -Message "[1] QUICK SCAN" -Level "WARN"
    Write-Ui -Message "    Scans typical PST locations inside user profiles." -Level "INFO"
    Write-Host ""
    Write-Ui -Message "[2] DEEP SCAN" -Level "WARN"
    Write-Ui -Message "    Scans every fixed drive thoroughly." -Level "INFO"
    Write-Host ""
    Write-Ui -Message "[3] SUMMARY" -Level "WARN"
    Write-Ui -Message "    Shows totals + top 10 largest PSTs from last scan." -Level "INFO"
    Write-Host ""
    Write-Ui -Message "[4] POWERSHELL MODE" -Level "WARN"
    Write-Ui -Message "    Export CSV/XLSX, per-user breakdown, custom path scan." -Level "INFO"
    Write-Host ""
    Write-Ui -Message "[5] SCHEDULED SCAN" -Level "WARN"
    Write-Ui -Message "    Sets a daily 03:00 scan that exports a CSV to Desktop." -Level "INFO"
    Write-Host ""
    Write-Ui -Message "NOTES:" -Level "STEP"
    Write-Ui -Message "  - PSTs are personal Outlook data files (mail/archives)." -Level "INFO"
    Write-Ui -Message "  - Large PSTs can slow Outlook and increase corruption risk." -Level "INFO"
    Write-Ui -Message "  - Consider archiving/splitting or moving to modern solutions." -Level "INFO"
    Write-Host ""
    Write-Host "========================================" -ForegroundColor DarkGray
    Write-Ui -Message "TROUBLESHOOTING:" -Level "STEP"
    Write-Host "----------------------------------------" -ForegroundColor DarkGray
    Write-Host ""
    Write-Ui -Message "Q: No PSTs found?" -Level "WARN"
    Write-Ui -Message "A: Ensure drives are connected and profiles exist." -Level "INFO"
    Write-Host ""
    Write-Ui -Message "Q: Access denied on some folders?" -Level "WARN"
    Write-Ui -Message "A: Run this tool as Administrator." -Level "INFO"
    Write-Host ""
    Write-Ui -Message "Q: Need to stop a running scan?" -Level "WARN"
    Write-Ui -Message "A: Press Ctrl+C to cancel." -Level "INFO"
    Write-Host ""
    Write-Host "========================================" -ForegroundColor DarkGray
    Write-Host ""
    Write-Ui -Message "Press any key to return to main menu..." -Level "INFO"
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
}

# ============================================================
# EXIT
# ============================================================

function Show-Exit {
    Clear-Host
    Write-Host ""
    Write-Ui -Message "Thank you for using SouliTEK PST Finder Tool!" -Level "INFO"
    Write-Host ""
    Write-Ui -Message "Website: www.soulitek.co.il" -Level "WARN"
    Write-Host ""
}

# ============================================================
# AUTO SCAN (for scheduled tasks)
# ============================================================

function Invoke-AutoScan {
    $timestamp = Get-Date -Format "yyyyMMdd"
    $outputFile = Join-Path $env:USERPROFILE "Desktop\PST_AutoScan_$timestamp.csv"
    
    $drives = Get-Volume | Where-Object { $_.DriveLetter -and $_.DriveType -eq 'Fixed' } | 
              Select-Object -ExpandProperty DriveLetter
    
    $allFiles = @()
    foreach ($drive in $drives) {
        $drivePath = "$($drive):\"
        $allFiles += Get-PSTFiles -Paths @($drivePath) -Recurse
    }
    
    if ($allFiles.Count -gt 0) {
        Export-PSTReport -Files $allFiles -OutputPath $outputFile | Out-Null
    }
    
    exit 0
}

# ============================================================
# MAIN EXECUTION
# ============================================================

# Handle AutoScan parameter for scheduled tasks
if ($AutoScan) {
    Invoke-AutoScan
    exit 0
}

# Show banner
Clear-Host
Show-ScriptBanner -ScriptName "FindPST" -Purpose "Locate and analyze Outlook PST files on the system"

# Check for administrator privileges
Confirm-Administrator

# Show disclaimer
Show-Disclaimer

# Show main menu
Show-MainMenu


