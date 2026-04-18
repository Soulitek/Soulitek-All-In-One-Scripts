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
        Write-Ui -Message "This could mean:" -Level "WARN"
        Write-Ui -Message "  - System has never experienced a blue screen" -Level "INFO"
        Write-Ui -Message "  - Minidump files have been cleaned up" -Level "INFO"
        Write-Ui -Message "  - Event log entries have been cleared" -Level "INFO"
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
    Write-Ui -Message "  BSOD HISTORY RESULTS" -Level "INFO"
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    
    # Find the most recent BSOD
    $mostRecent = $Script:BSODResults | Sort-Object Timestamp -Descending | Select-Object -First 1
    
    Write-Ui -Message "Last BSOD Occurrence:" -Level "WARN"
    Write-Ui -Message "  Date/Time: $($mostRecent.Timestamp)" -Level "STEP"
    Write-Ui -Message "  BugCheck Code: $($mostRecent.BugCheckCode)" -Level "STEP"
    Write-Ui -Message "  Description: $($mostRecent.BugCheckDescription)" -Level "STEP"
    Write-Ui -Message "  Source: $($mostRecent.Source)" -Level "STEP"
    Write-Host ""
    
    Write-Ui -Message "All BSOD Records ($($Script:BSODResults.Count) total):" -Level "WARN"
    Write-Host ""
    
    $index = 1
    foreach ($result in ($Script:BSODResults | Sort-Object Timestamp -Descending)) {
        Write-Ui -Message "[$index] $($result.Timestamp.ToString('yyyy-MM-dd HH:mm:ss'))" -Level "INFO"
        Write-Ui -Message "     Code: $($result.BugCheckCode)" -Level "STEP"
        Write-Ui -Message "     Description: $($result.BugCheckDescription)" -Level "INFO"
        Write-Ui -Message "     Source: $($result.Source)" -Level "INFO"
        if ($result.FileName -ne "Event ID 1001") {
            Write-Ui -Message "     File: $($result.FileName) ($($result.FileSize))" -Level "INFO"
        }
        if ($result.BugCheckParams) {
            Write-Ui -Message "     Parameters: $($result.BugCheckParams)" -Level "INFO"
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
    Write-Ui -Message "  LAST BLUE SCREEN OF DEATH (BSOD)" -Level "INFO"
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Date/Time: " -NoNewline -ForegroundColor Yellow
    Write-Ui -Message "$($lastBSOD.Timestamp)" -Level "STEP"
    Write-Host ""
    Write-Host "BugCheck Code: " -NoNewline -ForegroundColor Yellow
    Write-Ui -Message "$($lastBSOD.BugCheckCode)" -Level "ERROR"
    Write-Host ""
    Write-Host "Description: " -NoNewline -ForegroundColor Yellow
    Write-Ui -Message "$($lastBSOD.BugCheckDescription)" -Level "STEP"
    Write-Host ""
    Write-Host "Source: " -NoNewline -ForegroundColor Yellow
    Write-Ui -Message "$($lastBSOD.Source)" -Level "STEP"
    Write-Host ""
    
    if ($lastBSOD.FileName -ne "Event ID 1001") {
        Write-Host "Minidump File: " -NoNewline -ForegroundColor Yellow
        Write-Ui -Message "$($lastBSOD.FileName)" -Level "STEP"
        Write-Host ""
        Write-Host "File Size: " -NoNewline -ForegroundColor Yellow
        Write-Ui -Message "$($lastBSOD.FileSize)" -Level "STEP"
        Write-Host ""
        Write-Host "File Path: " -NoNewline -ForegroundColor Yellow
        Write-Ui -Message "$($lastBSOD.FilePath)" -Level "INFO"
        Write-Host ""
    }
    
    if ($lastBSOD.BugCheckParams) {
        Write-Host "BugCheck Parameters: " -NoNewline -ForegroundColor Yellow
        Write-Ui -Message "$($lastBSOD.BugCheckParams)" -Level "INFO"
        Write-Host ""
    }
    
    # Calculate time since last BSOD
    $timeSince = (Get-Date) - $lastBSOD.Timestamp
    Write-Host "Time Since Last BSOD: " -NoNewline -ForegroundColor Yellow
    if ($timeSince.Days -gt 0) {
        Write-Ui -Message "$($timeSince.Days) day(s), $($timeSince.Hours) hour(s) ago" -Level "STEP"
    } elseif ($timeSince.Hours -gt 0) {
        Write-Ui -Message "$($timeSince.Hours) hour(s), $($timeSince.Minutes) minute(s) ago" -Level "STEP"
    } else {
        Write-Ui -Message "$($timeSince.Minutes) minute(s) ago" -Level "STEP"
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
    
    Write-Ui -Message "This tool scans for Blue Screen of Death (BSOD) history by:" -Level "STEP"
    Write-Host ""
    Write-Ui -Message "  1. Scanning Minidump files in C:\Windows\Minidump" -Level "INFO"
    Write-Ui -Message "  2. Checking System event log for BugCheck events (Event ID 1001)" -Level "INFO"
    Write-Host ""
    Write-Ui -Message "Features:" -Level "WARN"
    Write-Ui -Message "  - Full scan of both Minidump files and event logs" -Level "INFO"
    Write-Ui -Message "  - View last BSOD occurrence with detailed information" -Level "INFO"
    Write-Ui -Message "  - Export results to TXT, CSV, or HTML formats" -Level "INFO"
    Write-Ui -Message "  - BugCheck code descriptions for common error codes" -Level "INFO"
    Write-Host ""
    Write-Ui -Message "BugCheck Codes:" -Level "WARN"
    Write-Ui -Message "  The tool identifies common BugCheck codes and provides" -Level "INFO"
    Write-Ui -Message "  human-readable descriptions. Common codes include:" -Level "INFO"
    Write-Host ""
    Write-Ui -Message "  0x0000000A - IRQL_NOT_LESS_OR_EQUAL" -Level "INFO"
    Write-Ui -Message "  0x0000003B - SYSTEM_SERVICE_EXCEPTION" -Level "INFO"
    Write-Ui -Message "  0x00000050 - PAGE_FAULT_IN_NONPAGED_AREA" -Level "INFO"
    Write-Ui -Message "  0x000000D1 - DRIVER_IRQL_NOT_LESS_OR_EQUAL" -Level "INFO"
    Write-Ui -Message "  0x00000124 - WHEA_UNCORRECTABLE_ERROR (Hardware)" -Level "INFO"
    Write-Ui -Message "  0x00000133 - DPC_WATCHDOG_VIOLATION" -Level "INFO"
    Write-Host ""
    Write-Ui -Message "Requirements:" -Level "WARN"
    Write-Ui -Message "  - Windows 10/11" -Level "INFO"
    Write-Ui -Message "  - Administrator privileges (recommended)" -Level "INFO"
    Write-Host ""
    Write-Ui -Message "Note:" -Level "WARN"
    Write-Ui -Message "  Minidump files may require WinDbg or other debugging tools" -Level "INFO"
    Write-Ui -Message "  for detailed analysis. This tool extracts basic information" -Level "INFO"
    Write-Ui -Message "  from event logs and file timestamps." -Level "INFO"
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
        
        Write-Ui -Message "Select an option:" -Level "STEP"
        Write-Host ""
        Write-Ui -Message "  [1] Full Scan              - Scan Minidump files and event logs" -Level "WARN"
        Write-Ui -Message "  [2] View Last BSOD         - Show most recent blue screen details" -Level "WARN"
        Write-Ui -Message "  [3] View All Results       - Display all BSOD records" -Level "WARN"
        Write-Ui -Message "  [4] Export Results        - Export to TXT, CSV, or HTML" -Level "WARN"
        Write-Ui -Message "  [5] Help                   - Usage guide and information" -Level "WARN"
        Write-Ui -Message "  [0] Exit" -Level "ERROR"
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

