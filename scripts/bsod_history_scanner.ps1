# ============================================================
# SouliTEK All-In-One Scripts - BSOD History Scanner
# ============================================================
# 
# Coded by: Soulitek.co.il
# IT Solutions for your business
# 
# (C) 2025 SouliTEK - All Rights Reserved
# Website: www.soulitek.co.il
# 
# This tool scans Minidump files and System event logs
# to report BSOD history including BugCheck codes and timestamps.
# 
# ============================================================

#Requires -Version 5.1

$Script:Version = "1.0.0"
$Script:ToolName = "BSOD History Scanner"

# ============================================================
# IMPORT COMMON MODULE
# ============================================================

$Script:ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$Script:RootPath = Split-Path -Parent $Script:ScriptPath
$CommonPath = Join-Path $Script:RootPath "modules\SouliTEK-Common.ps1"

if (Test-Path $CommonPath) {
    . $CommonPath
} else {
    Write-Warning "SouliTEK Common Functions not found at: $CommonPath"
}

# ============================================================
# CONFIGURATION
# ============================================================

$Script:BSODResults = @()
$Script:MinidumpPath = "$env:SystemRoot\Minidump"
$Script:BugCheckCodeMap = @{
    "0x0000000A" = "IRQL_NOT_LESS_OR_EQUAL"
    "0x0000001E" = "KMODE_EXCEPTION_NOT_HANDLED"
    "0x0000003B" = "SYSTEM_SERVICE_EXCEPTION"
    "0x00000050" = "PAGE_FAULT_IN_NONPAGED_AREA"
    "0x0000007E" = "SYSTEM_THREAD_EXCEPTION_NOT_HANDLED"
    "0x0000007F" = "UNEXPECTED_KERNEL_MODE_TRAP"
    "0x000000D1" = "DRIVER_IRQL_NOT_LESS_OR_EQUAL"
    "0x000000F4" = "CRITICAL_OBJECT_TERMINATED"
    "0x00000109" = "CRITICAL_STRUCTURE_CORRUPTION"
    "0x0000010E" = "VIDEO_MEMORY_MANAGEMENT_INTERNAL"
    "0x00000124" = "WHEA_UNCORRECTABLE_ERROR"
    "0x00000133" = "DPC_WATCHDOG_VIOLATION"
    "0x00000139" = "KERNEL_SECURITY_CHECK_FAILURE"
    "0x00000141" = "BUGCHECK_USB_DRIVER"
    "0x0000014C" = "VIDEO_TDR_TIMEOUT_DETECTED"
    "0x0000014E" = "BAD_POOL_CALLER"
    "0x00000157" = "KERNEL_AUTO_BOOST_INVALID_LOCK_RELEASE"
    "0x00000159" = "SYSTEM_PTE_MISUSE"
    "0x00000161" = "SYSTEM_SERVICE_EXCEPTION"
    "0x0000017E" = "SYSTEM_THREAD_EXCEPTION_NOT_HANDLED"
    "0x000001A5" = "WORKER_THREAD_RETURNED_WHILE_ATTACHED_TO_SILO"
    "0x000001B8" = "WIN32K_CRITICAL_FAILURE"
    "0x000001C5" = "SYSTEM_THREAD_EXCEPTION_NOT_HANDLED"
    "0x000001D1" = "DRIVER_IRQL_NOT_LESS_OR_EQUAL"
    "0x000001E3" = "RESOURCE_NOT_OWNED"
    "0x000001EA" = "THREAD_STUCK_IN_DEVICE_DRIVER"
    "0x000001F4" = "CRITICAL_OBJECT_TERMINATED"
    "0x000001F7" = "FATAL_UNHANDLED_HARD_ERROR"
}

# ============================================================
# HELPER FUNCTIONS
# ============================================================

# Show-Header function - wrapper using Show-SouliTEKHeader from common module
function Show-Header {
    param([string]$Title = "BSOD HISTORY SCANNER", [ConsoleColor]$Color = 'Cyan')
    
    Show-SouliTEKHeader -Title $Title -Color $Color -ClearHost -ShowBanner
}

function Get-BugCheckDescription {
    <#
    .SYNOPSIS
        Gets a human-readable description for a BugCheck code.
    #>
    param(
        [string]$BugCheckCode
    )
    
    if ($Script:BugCheckCodeMap.ContainsKey($BugCheckCode)) {
        return $Script:BugCheckCodeMap[$BugCheckCode]
    }
    
    return "UNKNOWN_ERROR"
}

function Get-MinidumpFiles {
    <#
    .SYNOPSIS
        Scans for Minidump files and extracts BSOD information.
    #>
    
    Write-Ui -Message "Scanning Minidump directory" -Level "INFO"
    
    $minidumps = @()
    
    if (-not (Test-Path $Script:MinidumpPath)) {
        Write-Ui -Message "Minidump directory not found: $Script:MinidumpPath" -Level "WARN"
        return $minidumps
    }
    
    try {
        $dumpFiles = Get-ChildItem -Path $Script:MinidumpPath -Filter "*.dmp" -ErrorAction Stop | Sort-Object LastWriteTime -Descending
        
        if ($dumpFiles.Count -eq 0) {
            Write-Ui -Message "No Minidump files found in $Script:MinidumpPath" -Level "INFO"
            return $minidumps
        }
        
        Write-Ui -Message "Found $($dumpFiles.Count) Minidump file(s)" -Level "OK"
        
        foreach ($dumpFile in $dumpFiles) {
            $minidumps += [PSCustomObject]@{
                Source = "Minidump"
                FileName = $dumpFile.Name
                FilePath = $dumpFile.FullName
                Timestamp = $dumpFile.LastWriteTime
                FileSize = Format-SouliTEKFileSize $dumpFile.Length
                BugCheckCode = "N/A (requires analysis)"
                BugCheckDescription = "N/A"
                RawSize = $dumpFile.Length
            }
        }
    }
    catch {
        Write-Ui -Message "Failed to scan Minidump directory: $($_.Exception.Message)" -Level "ERROR"
    }
    
    return $minidumps
}

function Get-BugCheckEvents {
    <#
    .SYNOPSIS
        Retrieves BugCheck events from System event log.
    #>
    
    Write-Ui -Message "Scanning System event log for BugCheck events" -Level "INFO"
    
    $bugCheckEvents = @()
    
    try {
        # Event ID 1001 contains BugCheck information
        $events = Get-WinEvent -FilterHashtable @{
            LogName = 'System'
            ID = 1001
        } -ErrorAction Stop | Sort-Object TimeCreated -Descending
        
        if ($events.Count -eq 0) {
            Write-SouliTEKInfo "No BugCheck events found in System event log"
            return $bugCheckEvents
        }
        
        Write-Ui -Message "Found $($events.Count) BugCheck event(s)" -Level "OK"
        
        foreach ($event in $events) {
            $eventXml = [xml]$event.ToXml()
            $eventData = $eventXml.Event.EventData.Data
            
            # Extract BugCheckCode from event data
            $bugCheckCode = "Unknown"
            $bugCheckParams = @()
            
            foreach ($data in $eventData) {
                if ($data.Name -eq "param1") {
                    $bugCheckCode = $data.'#text'
                }
                elseif ($data.Name -match "^param[2-5]$") {
                    $bugCheckParams += $data.'#text'
                }
            }
            
            # Format BugCheck code
            if ($bugCheckCode -ne "Unknown" -and -not $bugCheckCode.StartsWith("0x")) {
                $bugCheckCode = "0x" + ("{0:X8}" -f [int]$bugCheckCode)
            }
            
            $bugCheckDescription = Get-BugCheckDescription $bugCheckCode
            
            $bugCheckEvents += [PSCustomObject]@{
                Source = "Event Log"
                FileName = "Event ID 1001"
                FilePath = "System Event Log"
                Timestamp = $event.TimeCreated
                FileSize = "N/A"
                BugCheckCode = $bugCheckCode
                BugCheckDescription = $bugCheckDescription
                BugCheckParams = ($bugCheckParams -join ", ")
                RawSize = 0
            }
        }
    }
    catch {
        if ($_.Exception.Message -like "*No events were found*") {
            Write-SouliTEKInfo "No BugCheck events found in System event log"
        } else {
            Write-Ui -Message "Failed to retrieve BugCheck events: $($_.Exception.Message)" -Level "ERROR"
        }
    }
    
    return $bugCheckEvents
}

function Invoke-FullScan {
    <#
    .SYNOPSIS
        Performs a full scan of both Minidump files and event logs.
    #>
    
    Show-Header "BSOD HISTORY SCANNER - FULL SCAN"
    
    Write-Ui -Message "Starting full BSOD history scan" -Level "INFO"
    Write-Host ""
    
    $Script:BSODResults = @()
    
    # Scan Minidump files
    $minidumps = Get-MinidumpFiles
    $Script:BSODResults += $minidumps
    
    Write-Host ""
    
    # Scan event log
    $bugCheckEvents = Get-BugCheckEvents
    $Script:BSODResults += $bugCheckEvents
    
    Write-Host ""
    
    if ($Script:BSODResults.Count -eq 0) {
        Write-SouliTEKSuccess "No BSOD history found on this system"
        Write-Host ""
        Write-Host "This could mean:" -ForegroundColor Yellow
        Write-Host "  - System has never experienced a blue screen" -ForegroundColor Gray
        Write-Host "  - Minidump files have been cleaned up" -ForegroundColor Gray
        Write-Host "  - Event log entries have been cleared" -ForegroundColor Gray
        Write-Host ""
    } else {
        Write-Ui -Message "Scan complete! Found $($Script:BSODResults.Count) BSOD record(s)" -Level "OK"
        Write-Host ""
        Show-BSODResults
    }
    
    Wait-SouliTEKKeyPress
}

function Show-BSODResults {
    <#
    .SYNOPSIS
        Displays the BSOD scan results in a formatted table.
    #>
    
    if ($Script:BSODResults.Count -eq 0) {
        Write-Ui -Message "No results to display" -Level "WARN"
        return
    }
    
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "  BSOD HISTORY RESULTS" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    
    # Find the most recent BSOD
    $mostRecent = $Script:BSODResults | Sort-Object Timestamp -Descending | Select-Object -First 1
    
    Write-Host "Last BSOD Occurrence:" -ForegroundColor Yellow
    Write-Host "  Date/Time: $($mostRecent.Timestamp)" -ForegroundColor White
    Write-Host "  BugCheck Code: $($mostRecent.BugCheckCode)" -ForegroundColor White
    Write-Host "  Description: $($mostRecent.BugCheckDescription)" -ForegroundColor White
    Write-Host "  Source: $($mostRecent.Source)" -ForegroundColor White
    Write-Host ""
    
    Write-Host "All BSOD Records ($($Script:BSODResults.Count) total):" -ForegroundColor Yellow
    Write-Host ""
    
    $index = 1
    foreach ($result in ($Script:BSODResults | Sort-Object Timestamp -Descending)) {
        Write-Host "[$index] $($result.Timestamp.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Cyan
        Write-Host "     Code: $($result.BugCheckCode)" -ForegroundColor White
        Write-Host "     Description: $($result.BugCheckDescription)" -ForegroundColor Gray
        Write-Host "     Source: $($result.Source)" -ForegroundColor Gray
        if ($result.FileName -ne "Event ID 1001") {
            Write-Host "     File: $($result.FileName) ($($result.FileSize))" -ForegroundColor Gray
        }
        if ($result.BugCheckParams) {
            Write-Host "     Parameters: $($result.BugCheckParams)" -ForegroundColor Gray
        }
        Write-Host ""
        $index++
    }
}

function Show-LastBSOD {
    <#
    .SYNOPSIS
        Shows only the most recent BSOD information.
    #>
    
    Show-Header "BSOD HISTORY SCANNER - LAST BSOD"
    
    if ($Script:BSODResults.Count -eq 0) {
        Write-SouliTEKWarning "No scan results available. Please run a full scan first."
        Write-Host ""
        Wait-SouliTEKKeyPress
        return
    }
    
    $lastBSOD = $Script:BSODResults | Sort-Object Timestamp -Descending | Select-Object -First 1
    
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "  LAST BLUE SCREEN OF DEATH (BSOD)" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Date/Time: " -NoNewline -ForegroundColor Yellow
    Write-Host "$($lastBSOD.Timestamp)" -ForegroundColor White
    Write-Host ""
    Write-Host "BugCheck Code: " -NoNewline -ForegroundColor Yellow
    Write-Host "$($lastBSOD.BugCheckCode)" -ForegroundColor Red
    Write-Host ""
    Write-Host "Description: " -NoNewline -ForegroundColor Yellow
    Write-Host "$($lastBSOD.BugCheckDescription)" -ForegroundColor White
    Write-Host ""
    Write-Host "Source: " -NoNewline -ForegroundColor Yellow
    Write-Host "$($lastBSOD.Source)" -ForegroundColor White
    Write-Host ""
    
    if ($lastBSOD.FileName -ne "Event ID 1001") {
        Write-Host "Minidump File: " -NoNewline -ForegroundColor Yellow
        Write-Host "$($lastBSOD.FileName)" -ForegroundColor White
        Write-Host ""
        Write-Host "File Size: " -NoNewline -ForegroundColor Yellow
        Write-Host "$($lastBSOD.FileSize)" -ForegroundColor White
        Write-Host ""
        Write-Host "File Path: " -NoNewline -ForegroundColor Yellow
        Write-Host "$($lastBSOD.FilePath)" -ForegroundColor Gray
        Write-Host ""
    }
    
    if ($lastBSOD.BugCheckParams) {
        Write-Host "BugCheck Parameters: " -NoNewline -ForegroundColor Yellow
        Write-Host "$($lastBSOD.BugCheckParams)" -ForegroundColor Gray
        Write-Host ""
    }
    
    # Calculate time since last BSOD
    $timeSince = (Get-Date) - $lastBSOD.Timestamp
    Write-Host "Time Since Last BSOD: " -NoNewline -ForegroundColor Yellow
    if ($timeSince.Days -gt 0) {
        Write-Host "$($timeSince.Days) day(s), $($timeSince.Hours) hour(s) ago" -ForegroundColor White
    } elseif ($timeSince.Hours -gt 0) {
        Write-Host "$($timeSince.Hours) hour(s), $($timeSince.Minutes) minute(s) ago" -ForegroundColor White
    } else {
        Write-Host "$($timeSince.Minutes) minute(s) ago" -ForegroundColor White
    }
    Write-Host ""
    
    Wait-SouliTEKKeyPress
}

function Export-BSODResults {
    <#
    .SYNOPSIS
        Exports BSOD scan results to file.
    #>
    
    if ($Script:BSODResults.Count -eq 0) {
        Write-SouliTEKWarning "No results to export. Please run a scan first."
        Write-Host ""
        Wait-SouliTEKKeyPress
        return
    }
    
    $format = Show-SouliTEKExportMenu -Title "EXPORT BSOD HISTORY"
    
    if ($format -eq "CANCEL") {
        return
    }
    
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $desktopPath = [Environment]::GetFolderPath("Desktop")
    
    $exportData = $Script:BSODResults | Sort-Object Timestamp -Descending | ForEach-Object {
        [PSCustomObject]@{
            Timestamp = $_.Timestamp.ToString("yyyy-MM-dd HH:mm:ss")
            BugCheckCode = $_.BugCheckCode
            BugCheckDescription = $_.BugCheckDescription
            Source = $_.Source
            FileName = $_.FileName
            FilePath = $_.FilePath
            FileSize = $_.FileSize
            BugCheckParams = $_.BugCheckParams
        }
    }
    
    $extraInfo = @{
        "Total BSOD Records" = $Script:BSODResults.Count
        "Last BSOD" = ($Script:BSODResults | Sort-Object Timestamp -Descending | Select-Object -First 1).Timestamp.ToString("yyyy-MM-dd HH:mm:ss")
    }
    
    if ($format -eq "ALL") {
        $formats = @("TXT", "CSV", "HTML")
    } else {
        $formats = @($format)
    }
    
    foreach ($fmt in $formats) {
        $extension = switch ($fmt) {
            "TXT" { "txt" }
            "CSV" { "csv" }
            "HTML" { "html" }
        }
        
        $outputPath = Join-Path $desktopPath "BSOD_History_$timestamp.$extension"
        
        $columns = @("Timestamp", "BugCheckCode", "BugCheckDescription", "Source", "FileName", "FileSize")
        
        Export-SouliTEKReport -Data $exportData -Title "BSOD History Report" -Format $fmt -OutputPath $outputPath -ExtraInfo $extraInfo -Columns $columns -OpenAfterExport $false
    }
    
    Write-Host ""
    Write-SouliTEKSuccess "Export complete!"
    Wait-SouliTEKKeyPress
}

function Show-Help {
    <#
    .SYNOPSIS
        Displays help information.
    #>
    
    Show-Header "BSOD HISTORY SCANNER - HELP"
    
    Write-Host "This tool scans for Blue Screen of Death (BSOD) history by:" -ForegroundColor White
    Write-Host ""
    Write-Host "  1. Scanning Minidump files in C:\Windows\Minidump" -ForegroundColor Gray
    Write-Host "  2. Checking System event log for BugCheck events (Event ID 1001)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Features:" -ForegroundColor Yellow
    Write-Host "  - Full scan of both Minidump files and event logs" -ForegroundColor Gray
    Write-Host "  - View last BSOD occurrence with detailed information" -ForegroundColor Gray
    Write-Host "  - Export results to TXT, CSV, or HTML formats" -ForegroundColor Gray
    Write-Host "  - BugCheck code descriptions for common error codes" -ForegroundColor Gray
    Write-Host ""
    Write-Host "BugCheck Codes:" -ForegroundColor Yellow
    Write-Host "  The tool identifies common BugCheck codes and provides" -ForegroundColor Gray
    Write-Host "  human-readable descriptions. Common codes include:" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  0x0000000A - IRQL_NOT_LESS_OR_EQUAL" -ForegroundColor Cyan
    Write-Host "  0x0000003B - SYSTEM_SERVICE_EXCEPTION" -ForegroundColor Cyan
    Write-Host "  0x00000050 - PAGE_FAULT_IN_NONPAGED_AREA" -ForegroundColor Cyan
    Write-Host "  0x000000D1 - DRIVER_IRQL_NOT_LESS_OR_EQUAL" -ForegroundColor Cyan
    Write-Host "  0x00000124 - WHEA_UNCORRECTABLE_ERROR (Hardware)" -ForegroundColor Cyan
    Write-Host "  0x00000133 - DPC_WATCHDOG_VIOLATION" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Requirements:" -ForegroundColor Yellow
    Write-Host "  - Windows 10/11" -ForegroundColor Gray
    Write-Host "  - Administrator privileges (recommended)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Note:" -ForegroundColor Yellow
    Write-Host "  Minidump files may require WinDbg or other debugging tools" -ForegroundColor Gray
    Write-Host "  for detailed analysis. This tool extracts basic information" -ForegroundColor Gray
    Write-Host "  from event logs and file timestamps." -ForegroundColor Gray
    Write-Host ""
    
    Wait-SouliTEKKeyPress
}

function Show-MainMenu {
    <#
    .SYNOPSIS
        Displays the main menu.
    #>
    
    do {
        Show-Header "BSOD HISTORY SCANNER"
        
        Write-Host "Select an option:" -ForegroundColor White
        Write-Host ""
        Write-Host "  [1] Full Scan              - Scan Minidump files and event logs" -ForegroundColor Yellow
        Write-Host "  [2] View Last BSOD         - Show most recent blue screen details" -ForegroundColor Yellow
        Write-Host "  [3] View All Results       - Display all BSOD records" -ForegroundColor Yellow
        Write-Host "  [4] Export Results        - Export to TXT, CSV, or HTML" -ForegroundColor Yellow
        Write-Host "  [5] Help                   - Usage guide and information" -ForegroundColor Yellow
        Write-Host "  [0] Exit" -ForegroundColor Red
        Write-Host ""
        Write-Host "============================================================" -ForegroundColor DarkGray
        
        $choice = Read-Host "Enter your choice (0-5)"
        
        switch ($choice) {
            '1' { Invoke-FullScan }
            '2' { Show-LastBSOD }
            '3' { 
                Show-Header "BSOD HISTORY SCANNER - ALL RESULTS"
                if ($Script:BSODResults.Count -eq 0) {
                    Write-SouliTEKWarning "No scan results available. Please run a full scan first."
                    Write-Host ""
                    Wait-SouliTEKKeyPress
                } else {
                    Show-BSODResults
                    Wait-SouliTEKKeyPress
                }
            }
            '4' { Export-BSODResults }
            '5' { Show-Help }
            '0' { 
                Show-SouliTEKExitMessage -ScriptPath $PSCommandPath -ToolName $Script:ToolName
                exit 0
            }
            default {
                Write-SouliTEKWarning "Invalid choice. Please select 0-5."
                Start-Sleep -Seconds 1
            }
        }
    } while ($true)
}

# ============================================================
# MAIN EXECUTION
# ============================================================

try {
    Clear-Host
    Show-ScriptBanner -ScriptName "BSOD History Scanner" -Purpose "Scan and analyze Blue Screen of Death history from system logs"
    
    # Check for administrator privileges (recommended but not required)
    $isAdmin = Invoke-SouliTEKAdminCheck -FeatureName "BSOD History Scanner"
    
    Show-SouliTEKDisclaimer -ToolName $Script:ToolName
    
    Show-MainMenu
}
catch {
    Write-Ui -Message "An error occurred: $($_.Exception.Message)" -Level "ERROR"
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit 1
}

