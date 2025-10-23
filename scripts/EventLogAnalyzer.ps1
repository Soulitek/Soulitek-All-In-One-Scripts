<#
.SYNOPSIS
    EventLogAnalyzer - Advanced Windows Event Log Analysis Tool for IT Professionals

.DESCRIPTION
    Analyzes Windows Event Logs (Application, System, Security) for Errors and Warnings
    within a specified timeframe. Provides statistical summaries, top event IDs, and
    exports results to CSV/JSON formats for further analysis.
    
    Designed for IT technicians and helpdesk engineers working with Windows 8.1/10/11
    and Windows Server 2016+.

.PARAMETER LogNames
    Array of event log names to analyze. Default: Application, System, Security

.PARAMETER Hours
    Number of hours to look back. Default: 24

.PARAMETER StartTime
    Explicit start time for analysis. Overrides -Hours parameter.

.PARAMETER EndTime
    Explicit end time for analysis. Default: Now

.PARAMETER IncludeWarnings
    Include Warning level events in addition to Errors. Default: True

.PARAMETER IncludeInformation
    Include Information level events. Default: False (can generate very large datasets)

.PARAMETER MaxEvents
    Maximum number of events to retrieve per log. Default: 10000

.PARAMETER ExportPath
    Path to export results. Default: Desktop

.PARAMETER ExportFormat
    Export format: JSON, CSV, or Both. Default: Both

.PARAMETER Force
    Skip confirmation prompts for large queries.

.PARAMETER RunExamples
    Run built-in test examples to demonstrate functionality.

.EXAMPLE
    .\EventLogAnalyzer.ps1
    
    Analyzes Application, System, and Security logs for the past 24 hours.
    Exports summary to Desktop in both JSON and CSV formats.

.EXAMPLE
    .\EventLogAnalyzer.ps1 -LogNames "Application","System" -Hours 48 -Force
    
    Analyzes Application and System logs for the past 48 hours without confirmation.

.EXAMPLE
    .\EventLogAnalyzer.ps1 -StartTime (Get-Date).AddDays(-7) -IncludeInformation -MaxEvents 50000
    
    Analyzes last 7 days including Information events, retrieving up to 50,000 events per log.

.NOTES
    File Name      : EventLogAnalyzer.ps1
    Author         : SouliTEK - Eitan
    Contact        : https://soulitek.co.il
    Prerequisite   : PowerShell 5.1+, Administrator privileges
    Copyright      : (C) 2025 SouliTEK - All Rights Reserved
    
    Target Systems : Windows 8.1 / 10 / 11 / Server 2016+
    
    SECURITY NOTE  : This script reads Windows Event Logs which may contain sensitive
                     system information. Ensure exported files are handled securely.
                     
    Hebrew: כלי מתקדם לניתוח יומני אירועים של Windows עבור טכנאי IT
            מספק סיכומים סטטיסטיים ויצוא ל-CSV/JSON
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
param(
    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string[]]$LogNames = @('Application', 'System', 'Security'),
    
    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 720)]
    [int]$Hours = 24,
    
    [Parameter(Mandatory = $false)]
    [DateTime]$StartTime,
    
    [Parameter(Mandatory = $false)]
    [DateTime]$EndTime = (Get-Date),
    
    [Parameter(Mandatory = $false)]
    [bool]$IncludeWarnings = $true,
    
    [Parameter(Mandatory = $false)]
    [bool]$IncludeInformation = $false,
    
    [Parameter(Mandatory = $false)]
    [ValidateRange(100, 100000)]
    [int]$MaxEvents = 10000,
    
    [Parameter(Mandatory = $false)]
    [ValidateScript({
        if (-not (Test-Path $_ -IsValid)) {
            throw "Path '$_' is not valid."
        }
        $true
    })]
    [string]$ExportPath = [Environment]::GetFolderPath('Desktop'),
    
    [Parameter(Mandatory = $false)]
    [ValidateSet('JSON', 'CSV', 'Both')]
    [string]$ExportFormat = 'Both',
    
    [Parameter(Mandatory = $false)]
    [switch]$Force,
    
    [Parameter(Mandatory = $false)]
    [switch]$RunExamples
)

#Requires -Version 5.1

# Set window title
$Host.UI.RawUI.WindowTitle = "EventLogAnalyzer - Professional Tool - by Soulitek.co.il"

# ============================================================
# GLOBAL CONFIGURATION
# ============================================================

$script:ScriptName = 'EventLogAnalyzer'
$script:ScriptVersion = '1.0.0'
$script:LogFolder = Join-Path $env:TEMP "SouliTEK-Scripts\$script:ScriptName"
$script:VerboseLogFile = $null
$script:JsonSummaryFile = $null

# ============================================================
# HELPER FUNCTIONS
# ============================================================

<#
.SYNOPSIS
    Tests if the current PowerShell session has Administrator privileges.
#>
function Test-AdministratorPrivilege {
    [CmdletBinding()]
    [OutputType([bool])]
    param()
    
    try {
        $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
        return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    }
    catch {
        Write-Error "Failed to determine administrator status: $_"
        return $false
    }
}

<#
.SYNOPSIS
    Initializes the logging infrastructure for the script.
    
.DESCRIPTION
    Creates log directories and initializes log files with timestamps.
    
.OUTPUTS
    System.Management.Automation.PSCustomObject with LogFolder, VerboseLog, and JsonSummary paths.
#>
function Initialize-Logging {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param()
    
    try {
        # Create log folder if it doesn't exist
        if (-not (Test-Path $script:LogFolder)) {
            $null = New-Item -ItemType Directory -Path $script:LogFolder -Force -ErrorAction Stop
            Write-Verbose "Created log folder: $script:LogFolder"
        }
        
        $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
        $script:VerboseLogFile = Join-Path $script:LogFolder "EventLogAnalyzer_Verbose_$timestamp.log"
        $script:JsonSummaryFile = Join-Path $script:LogFolder "EventLogAnalyzer_Summary_$timestamp.json"
        
        # Initialize verbose log
        $header = @"
============================================================
EventLogAnalyzer - Verbose Log
Started: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Version: $script:ScriptVersion
============================================================

"@
        Set-Content -Path $script:VerboseLogFile -Value $header -Encoding UTF8
        
        Write-Verbose "Logging initialized: $script:VerboseLogFile"
        
        return [PSCustomObject]@{
            LogFolder    = $script:LogFolder
            VerboseLog   = $script:VerboseLogFile
            JsonSummary  = $script:JsonSummaryFile
        }
    }
    catch {
        Write-Error "Failed to initialize logging: $_"
        throw
    }
}

<#
.SYNOPSIS
    Writes a message to the verbose log file.
#>
function Write-Log {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet('INFO', 'WARNING', 'ERROR', 'SUCCESS')]
        [string]$Level = 'INFO'
    )
    
    if ($script:VerboseLogFile -and (Test-Path $script:VerboseLogFile)) {
        $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        $logEntry = "[$timestamp] [$Level] $Message"
        Add-Content -Path $script:VerboseLogFile -Value $logEntry -Encoding UTF8
    }
    
    Write-Verbose $Message
}

<#
.SYNOPSIS
    Retrieves and analyzes events from a specified Windows Event Log.
    
.PARAMETER LogName
    Name of the event log to analyze (e.g., 'Application', 'System').
    
.PARAMETER StartTime
    Start time for event retrieval.
    
.PARAMETER EndTime
    End time for event retrieval.
    
.PARAMETER EntryTypes
    Array of event entry types to include (Error, Warning, Information).
    
.PARAMETER MaxEvents
    Maximum number of events to retrieve.
    
.OUTPUTS
    PSCustomObject containing event statistics and details.
#>
function Get-EventLogAnalysis {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$LogName,
        
        [Parameter(Mandatory = $true)]
        [DateTime]$StartTime,
        
        [Parameter(Mandatory = $true)]
        [DateTime]$EndTime,
        
        [Parameter(Mandatory = $true)]
        [string[]]$EntryTypes,
        
        [Parameter(Mandatory = $true)]
        [int]$MaxEvents
    )
    
    Write-Log "Analyzing log: $LogName from $StartTime to $EndTime" -Level INFO
    Write-Progress -Activity "Event Log Analysis" -Status "Processing $LogName..." -PercentComplete 0
    
    try {
        # Map entry types to event level IDs
        # 1=Critical, 2=Error, 3=Warning, 4=Information
        $levels = @()
        if ($EntryTypes -contains 'Error') { $levels += 1, 2 }
        if ($EntryTypes -contains 'Warning') { $levels += 3 }
        if ($EntryTypes -contains 'Information') { $levels += 4 }
        
        if ($levels.Count -eq 0) {
            Write-Log "No entry types specified for $LogName" -Level WARNING
            return $null
        }
        
        # Retrieve events
        Write-Verbose "Retrieving events from $LogName (Max: $MaxEvents)..."
        
        $events = @()
        
        # Build Level filter part properly
        $levelFilter = ($levels | ForEach-Object { "Level=$_" }) -join ' or '
        
        $filterXml = @"
<QueryList>
  <Query Id="0" Path="$LogName">
    <Select Path="$LogName">
      *[System[TimeCreated[@SystemTime&gt;='$($StartTime.ToUniversalTime().ToString('o'))' and @SystemTime&lt;='$($EndTime.ToUniversalTime().ToString('o'))'] and ($levelFilter)]]
    </Select>
  </Query>
</QueryList>
"@
        
        # Log the filter for debugging
        Write-Verbose "FilterXml Query:`n$filterXml"
        Write-Log "Query filter: Start=$($StartTime.ToUniversalTime().ToString('o')), End=$($EndTime.ToUniversalTime().ToString('o')), Levels=$($levels -join ',')" -Level INFO
        
        try {
            $events = Get-WinEvent -FilterXml $filterXml -MaxEvents $MaxEvents -ErrorAction Stop
            Write-Log "Retrieved $($events.Count) events from $LogName" -Level SUCCESS
        }
        catch {
            if ($_.Exception.Message -match "No events were found") {
                Write-Log "No events found in $LogName for specified criteria" -Level INFO
                $events = @()
            }
            elseif ($_.Exception.Message -match "specified query is invalid") {
                Write-Log "Invalid query for $LogName. Filter: $levelFilter" -Level ERROR
                Write-Error "Failed to analyze event log '$LogName': The specified query is invalid. This may be due to incorrect date format or log access permissions."
                return $null
            }
            else {
                Write-Log "Error querying $LogName : $($_.Exception.Message)" -Level ERROR
                throw
            }
        }
        
        if ($events.Count -eq 0) {
            return [PSCustomObject]@{
                LogName           = $LogName
                TotalEvents       = 0
                ErrorCount        = 0
                WarningCount      = 0
                InformationCount  = 0
                TopEventIDs       = @()
                TopSources        = @()
                Events            = @()
                StartTime         = $StartTime
                EndTime           = $EndTime
            }
        }
        
        # Analyze events
        $errorEvents = @($events | Where-Object { $_.Level -in @(1, 2) })
        $warningEvents = @($events | Where-Object { $_.Level -eq 3 })
        $infoEvents = @($events | Where-Object { $_.Level -eq 4 })
        
        # Top 10 Event IDs by occurrence
        $topEventIDs = $events | 
            Group-Object -Property Id | 
            Sort-Object Count -Descending | 
            Select-Object -First 10 |
            ForEach-Object {
                [PSCustomObject]@{
                    EventID = $_.Name
                    Count   = $_.Count
                }
            }
        
        # Top 10 Sources
        $topSources = $events | 
            Group-Object -Property ProviderName | 
            Sort-Object Count -Descending | 
            Select-Object -First 10 |
            ForEach-Object {
                [PSCustomObject]@{
                    Source = $_.Name
                    Count  = $_.Count
                }
            }
        
        # Collect event details
        $eventDetails = $events | Select-Object -First 100 | ForEach-Object {
            [PSCustomObject]@{
                TimeCreated  = $_.TimeCreated
                Level        = switch ($_.Level) {
                    1 { 'Critical' }
                    2 { 'Error' }
                    3 { 'Warning' }
                    4 { 'Information' }
                    default { 'Unknown' }
                }
                EventID      = $_.Id
                Source       = $_.ProviderName
                Message      = $_.Message
            }
        }
        
        Write-Progress -Activity "Event Log Analysis" -Status "Completed $LogName" -PercentComplete 100
        
        return [PSCustomObject]@{
            LogName           = $LogName
            TotalEvents       = $events.Count
            ErrorCount        = $errorEvents.Count
            WarningCount      = $warningEvents.Count
            InformationCount  = $infoEvents.Count
            TopEventIDs       = $topEventIDs
            TopSources        = $topSources
            Events            = $eventDetails
            StartTime         = $StartTime
            EndTime           = $EndTime
        }
    }
    catch {
        Write-Log "Error analyzing $LogName : $_" -Level ERROR
        Write-Error "Failed to analyze event log '$LogName': $_"
        return $null
    }
}

<#
.SYNOPSIS
    Exports analysis results to specified formats.
    
.PARAMETER Results
    Analysis results object to export.
    
.PARAMETER ExportPath
    Directory path for export files.
    
.PARAMETER Format
    Export format (JSON, CSV, or Both).
    
.OUTPUTS
    PSCustomObject with paths to exported files.
#>
function Export-AnalysisResults {
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Results,
        
        [Parameter(Mandatory = $true)]
        [string]$ExportPath,
        
        [Parameter(Mandatory = $true)]
        [ValidateSet('JSON', 'CSV', 'Both')]
        [string]$Format
    )
    
    try {
        $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
        $exportedFiles = @()
        
        # Ensure export path exists
        if (-not (Test-Path $ExportPath)) {
            $null = New-Item -ItemType Directory -Path $ExportPath -Force
        }
        
        # Export JSON
        if ($Format -in @('JSON', 'Both')) {
            $jsonPath = Join-Path $ExportPath "EventLogAnalysis_$timestamp.json"
            
            if ($PSCmdlet.ShouldProcess($jsonPath, "Export JSON results")) {
                $Results | ConvertTo-Json -Depth 10 | Set-Content -Path $jsonPath -Encoding UTF8
                $exportedFiles += $jsonPath
                Write-Log "Exported JSON to: $jsonPath" -Level SUCCESS
                Write-Host "  [EXPORTED] JSON: $jsonPath" -ForegroundColor Green
            }
        }
        
        # Export CSV (summary)
        if ($Format -in @('CSV', 'Both')) {
            $csvPath = Join-Path $ExportPath "EventLogAnalysis_Summary_$timestamp.csv"
            
            if ($PSCmdlet.ShouldProcess($csvPath, "Export CSV summary")) {
                $csvData = $Results.LogAnalysis | ForEach-Object {
                    [PSCustomObject]@{
                        LogName          = $_.LogName
                        TotalEvents      = $_.TotalEvents
                        ErrorCount       = $_.ErrorCount
                        WarningCount     = $_.WarningCount
                        InformationCount = $_.InformationCount
                        StartTime        = $_.StartTime
                        EndTime          = $_.EndTime
                    }
                }
                
                $csvData | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
                $exportedFiles += $csvPath
                Write-Log "Exported CSV to: $csvPath" -Level SUCCESS
                Write-Host "  [EXPORTED] CSV: $csvPath" -ForegroundColor Green
            }
            
            # Export detailed events CSV
            $csvEventsPath = Join-Path $ExportPath "EventLogAnalysis_Events_$timestamp.csv"
            
            if ($PSCmdlet.ShouldProcess($csvEventsPath, "Export detailed events CSV")) {
                $allEvents = $Results.LogAnalysis | ForEach-Object {
                    $logName = $_.LogName
                    $_.Events | ForEach-Object {
                        $_ | Add-Member -NotePropertyName 'LogName' -NotePropertyValue $logName -PassThru
                    }
                }
                
                if ($allEvents) {
                    $allEvents | Export-Csv -Path $csvEventsPath -NoTypeInformation -Encoding UTF8
                    $exportedFiles += $csvEventsPath
                    Write-Log "Exported detailed events CSV to: $csvEventsPath" -Level SUCCESS
                    Write-Host "  [EXPORTED] Events CSV: $csvEventsPath" -ForegroundColor Green
                }
            }
        }
        
        return [PSCustomObject]@{
            ExportedFiles = $exportedFiles
            Success       = $true
        }
    }
    catch {
        Write-Log "Failed to export results: $_" -Level ERROR
        Write-Error "Export failed: $_"
        return [PSCustomObject]@{
            ExportedFiles = @()
            Success       = $false
            Error         = $_.Exception.Message
        }
    }
}

<#
.SYNOPSIS
    Displays a summary of analysis results to the console.
#>
function Show-AnalysisSummary {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Results
    )
    
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "  EVENT LOG ANALYSIS SUMMARY" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Analysis Period: $($Results.StartTime) to $($Results.EndTime)" -ForegroundColor White
    Write-Host "  Total Logs Analyzed: $($Results.LogAnalysis.Count)" -ForegroundColor White
    Write-Host ""
    
    foreach ($log in $Results.LogAnalysis) {
        Write-Host "  [$($log.LogName)]" -ForegroundColor Yellow
        Write-Host "    Total Events: $($log.TotalEvents)" -ForegroundColor Gray
        
        if ($log.ErrorCount -gt 0) {
            Write-Host "    Errors: $($log.ErrorCount)" -ForegroundColor Red
        }
        else {
            Write-Host "    Errors: 0" -ForegroundColor Green
        }
        
        if ($log.WarningCount -gt 0) {
            Write-Host "    Warnings: $($log.WarningCount)" -ForegroundColor Yellow
        }
        else {
            Write-Host "    Warnings: 0" -ForegroundColor Green
        }
        
        if ($log.InformationCount -gt 0) {
            Write-Host "    Information: $($log.InformationCount)" -ForegroundColor Cyan
        }
        
        if ($log.TopEventIDs -and $log.TopEventIDs.Count -gt 0) {
            Write-Host "    Top Event IDs:" -ForegroundColor Gray
            $log.TopEventIDs | Select-Object -First 5 | ForEach-Object {
                Write-Host "      - Event $($_.EventID): $($_.Count) occurrences" -ForegroundColor DarkGray
            }
        }
        
        Write-Host ""
    }
    
    $totalErrors = ($Results.LogAnalysis | Measure-Object -Property ErrorCount -Sum).Sum
    $totalWarnings = ($Results.LogAnalysis | Measure-Object -Property WarningCount -Sum).Sum
    
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "  TOTALS ACROSS ALL LOGS" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "  Total Errors: $totalErrors" -ForegroundColor $(if ($totalErrors -gt 0) { 'Red' } else { 'Green' })
    Write-Host "  Total Warnings: $totalWarnings" -ForegroundColor $(if ($totalWarnings -gt 0) { 'Yellow' } else { 'Green' })
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
}

# ============================================================
# MAIN EXECUTION
# ============================================================

function Invoke-MainAnalysis {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param()
    
    try {
        # Initialize logging
        $null = Initialize-Logging
        Write-Log "EventLogAnalyzer v$script:ScriptVersion started" -Level INFO
        Write-Log "Parameters: LogNames=$($LogNames -join ','), Hours=$Hours" -Level INFO
        
        # Determine time range
        if (-not $StartTime) {
            $StartTime = (Get-Date).AddHours(-$Hours)
        }
        
        Write-Log "Analysis period: $StartTime to $EndTime" -Level INFO
        
        # Build entry types array
        $entryTypes = @('Error')
        if ($IncludeWarnings) { $entryTypes += 'Warning' }
        if ($IncludeInformation) { $entryTypes += 'Information' }
        
        Write-Log "Entry types: $($entryTypes -join ', ')" -Level INFO
        
        # Confirmation for large queries
        $estimatedLoad = $LogNames.Count * $MaxEvents
        if ($estimatedLoad -gt 30000 -and -not $Force) {
            Write-Host ""
            Write-Host "WARNING: This query may retrieve up to $estimatedLoad events." -ForegroundColor Yellow
            Write-Host "This could take several minutes and consume significant memory." -ForegroundColor Yellow
            Write-Host ""
            $confirm = Read-Host "Continue? (Y/N)"
            
            if ($confirm -ne 'Y' -and $confirm -ne 'y') {
                Write-Host "Analysis cancelled by user." -ForegroundColor Yellow
                Write-Log "Analysis cancelled by user (large query confirmation)" -Level INFO
                return
            }
        }
        
        # Display header
        Write-Host ""
        Write-Host "============================================================" -ForegroundColor Cyan
        Write-Host "  EventLogAnalyzer v$script:ScriptVersion - SouliTEK" -ForegroundColor Cyan
        Write-Host "============================================================" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "  Analyzing logs: $($LogNames -join ', ')" -ForegroundColor White
        Write-Host "  Time range: Last $Hours hours" -ForegroundColor White
        Write-Host "  Include: $($entryTypes -join ', ')" -ForegroundColor White
        Write-Host ""
        
        # Analyze each log
        $logResults = @()
        $logCount = 0
        
        foreach ($logName in $LogNames) {
            $logCount++
            $percentComplete = [math]::Round(($logCount / $LogNames.Count) * 100)
            
            Write-Progress -Activity "Event Log Analysis" -Status "Processing $logName ($logCount of $($LogNames.Count))" -PercentComplete $percentComplete
            Write-Host "  [Processing] $logName..." -ForegroundColor Cyan
            
            $analysis = Get-EventLogAnalysis -LogName $logName -StartTime $StartTime -EndTime $EndTime -EntryTypes $entryTypes -MaxEvents $MaxEvents
            
            if ($analysis) {
                $logResults += $analysis
                Write-Host "    [OK] Found $($analysis.TotalEvents) events" -ForegroundColor Green
            }
            else {
                Write-Host "    [SKIP] No events or error occurred" -ForegroundColor Yellow
            }
        }
        
        Write-Progress -Activity "Event Log Analysis" -Completed
        
        # Build final results object
        $finalResults = [PSCustomObject]@{
            ScriptVersion  = $script:ScriptVersion
            AnalysisDate   = Get-Date
            StartTime      = $StartTime
            EndTime        = $EndTime
            LogsAnalyzed   = $LogNames
            EntryTypes     = $entryTypes
            LogAnalysis    = $logResults
        }
        
        # Save JSON summary
        if ($PSCmdlet.ShouldProcess($script:JsonSummaryFile, "Save JSON summary")) {
            $finalResults | ConvertTo-Json -Depth 10 | Set-Content -Path $script:JsonSummaryFile -Encoding UTF8
            Write-Log "Saved JSON summary to: $script:JsonSummaryFile" -Level SUCCESS
        }
        
        # Display summary
        Show-AnalysisSummary -Results $finalResults
        
        # Export results
        Write-Host "  [Exporting] Results to $ExportPath..." -ForegroundColor Cyan
        $exportResult = Export-AnalysisResults -Results $finalResults -ExportPath $ExportPath -Format $ExportFormat
        
        if ($exportResult.Success) {
            Write-Host ""
            Write-Host "  [SUCCESS] Analysis complete!" -ForegroundColor Green
            Write-Host "  Logs: $script:LogFolder" -ForegroundColor Gray
            Write-Host ""
        }
        
        Write-Log "Analysis completed successfully" -Level SUCCESS
        
        # Return results object for programmatic use
        return $finalResults
    }
    catch {
        Write-Log "Fatal error in main analysis: $_" -Level ERROR
        Write-Error "Analysis failed: $_"
        Write-Host ""
        Write-Host "TROUBLESHOOTING:" -ForegroundColor Yellow
        Write-Host "  - Ensure you have Administrator privileges" -ForegroundColor Gray
        Write-Host "  - Verify event log names are correct" -ForegroundColor Gray
        Write-Host "  - Check available disk space in $env:TEMP" -ForegroundColor Gray
        Write-Host "  - Review verbose log: $script:VerboseLogFile" -ForegroundColor Gray
        Write-Host ""
        return $null
    }
}

# ============================================================
# ADMINISTRATOR CHECK
# ============================================================

if (-not (Test-AdministratorPrivilege)) {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Red
    Write-Host "  ERROR: Administrator Privileges Required" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "This script requires Administrator privileges to access Windows Event Logs." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "To run this script as Administrator:" -ForegroundColor White
    Write-Host "  1. Right-click PowerShell and select 'Run as Administrator'" -ForegroundColor Gray
    Write-Host "  2. Navigate to the script directory" -ForegroundColor Gray
    Write-Host "  3. Run: .\EventLogAnalyzer.ps1" -ForegroundColor Gray
    Write-Host ""
    Write-Host "OR run this command:" -ForegroundColor White
    Write-Host "  Start-Process powershell -Verb RunAs -ArgumentList `"-File '$PSCommandPath'`"" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Red
    Write-Host ""
    
    exit 1
}

# ============================================================
# EXAMPLE/TEST MODE
# ============================================================

if ($RunExamples) {
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Green
    Write-Host "  RUNNING EXAMPLES" -ForegroundColor Green
    Write-Host "============================================================" -ForegroundColor Green
    Write-Host ""
    
    Write-Host "Example 1: Analyze Application log for last 1 hour (Errors only)" -ForegroundColor Cyan
    & $PSCommandPath -LogNames "Application" -Hours 1 -IncludeWarnings $false -ExportFormat JSON -Force -Verbose
    
    Write-Host ""
    Write-Host "Example 2: Analyze System log for last 6 hours (Errors + Warnings)" -ForegroundColor Cyan
    & $PSCommandPath -LogNames "System" -Hours 6 -IncludeWarnings $true -ExportFormat CSV -Force -Verbose
    
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Green
    Write-Host "  EXAMPLES COMPLETED" -ForegroundColor Green
    Write-Host "============================================================" -ForegroundColor Green
    Write-Host ""
    
    exit 0
}

# ============================================================
# RUN MAIN ANALYSIS
# ============================================================

$result = Invoke-MainAnalysis

if ($result) {
    exit 0
}
else {
    exit 1
}

