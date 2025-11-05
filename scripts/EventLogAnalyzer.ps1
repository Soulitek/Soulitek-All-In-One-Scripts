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

.PARAMETER EventIDs
    Filter by specific Event IDs (e.g., @(1000,1001) or "1000-1005"). Supports ranges and comma-separated values.

.PARAMETER Sources
    Filter by event source/provider names (e.g., @("Microsoft-Windows-Kernel-General","Application Error")).

.PARAMETER MessageFilter
    Filter events by message content (searches for keywords in event messages). Case-insensitive.

.PARAMETER IncludeAuditSuccess
    Include Audit Success events in Security log analysis. Default: False

.PARAMETER IncludeAuditFailure
    Include Audit Failure events in Security log analysis. Default: False

.PARAMETER IncludeCritical
    Include Critical level events. Default: True (included with Errors)

.PARAMETER CompareWithBaseline
    Path to a previous analysis JSON file to compare against for trend analysis.

.PARAMETER ExportIndividualLogs
    Export each log to separate files instead of combined export. Default: False

.PARAMETER MachineName
    Target machine name for remote analysis (requires admin access to remote machine). Default: Local machine

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

.EXAMPLE
    .\EventLogAnalyzer.ps1 -EventIDs @(4624,4625) -IncludeAuditSuccess -IncludeAuditFailure
    
    Analyzes Security log for successful and failed login events (Event IDs 4624, 4625).

.EXAMPLE
    .\EventLogAnalyzer.ps1 -Sources @("Microsoft-Windows-Kernel-General") -MessageFilter "blue screen"
    
    Filters events from specific source containing "blue screen" in the message.

.EXAMPLE
    .\EventLogAnalyzer.ps1 -ExportFormat "HTML" -ExportIndividualLogs
    
    Exports results as HTML with separate files for each log analyzed.

.NOTES
    File Name      : EventLogAnalyzer.ps1
    Author         : SouliTEK
    Contact        : www.soulitek.co.il
    Prerequisite   : PowerShell 5.1+, Administrator privileges
    Copyright      : (C) 2025 SouliTEK - All Rights Reserved
    
    Target Systems : Windows 8.1 / 10 / 11 / Server 2016+
    
    SECURITY NOTE  : This script reads Windows Event Logs which may contain sensitive
                     system information. Ensure exported files are handled securely.
                     
    For IT Technicians: Advanced Windows Event Log analysis tool
                        Provides statistical summaries and CSV/JSON export
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
    [ValidateSet('JSON', 'CSV', 'HTML', 'Both', 'All')]
    [string]$ExportFormat = 'Both',
    
    [Parameter(Mandatory = $false)]
    [switch]$Force,
    
    [Parameter(Mandatory = $false)]
    [switch]$RunExamples,
    
    [Parameter(Mandatory = $false)]
    [string[]]$EventIDs,
    
    [Parameter(Mandatory = $false)]
    [string[]]$Sources,
    
    [Parameter(Mandatory = $false)]
    [string]$MessageFilter,
    
    [Parameter(Mandatory = $false)]
    [switch]$IncludeAuditSuccess,
    
    [Parameter(Mandatory = $false)]
    [switch]$IncludeAuditFailure,
    
    [Parameter(Mandatory = $false)]
    [bool]$IncludeCritical = $true,
    
    [Parameter(Mandatory = $false)]
    [string]$CompareWithBaseline,
    
    [Parameter(Mandatory = $false)]
    [switch]$ExportIndividualLogs,
    
    [Parameter(Mandatory = $false)]
    [string]$MachineName = $env:COMPUTERNAME
)

#Requires -Version 5.1

# Set window title
$Host.UI.RawUI.WindowTitle = "EVENT LOG ANALYZER"

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
        [int]$MaxEvents,
        
        [Parameter(Mandatory = $false)]
        [string[]]$EventIDs,
        
        [Parameter(Mandatory = $false)]
        [string[]]$Sources,
        
        [Parameter(Mandatory = $false)]
        [string]$MessageFilter,
        
        [Parameter(Mandatory = $false)]
        [bool]$IncludeAuditSuccess = $false,
        
        [Parameter(Mandatory = $false)]
        [bool]$IncludeAuditFailure = $false,
        
        [Parameter(Mandatory = $false)]
        [bool]$IncludeCritical = $true,
        
        [Parameter(Mandatory = $false)]
        [string]$MachineName = $env:COMPUTERNAME
    )
    
    Write-Log "Analyzing log: $LogName from $StartTime to $EndTime" -Level INFO
    Write-Progress -Activity "Event Log Analysis" -Status "Processing $LogName..." -PercentComplete 0
    
    try {
        # Map entry types to event level IDs
        # 1=Critical, 2=Error, 3=Warning, 4=Information, 8=AuditSuccess, 9=AuditFailure
        $levels = @()
        if ($EntryTypes -contains 'Error') { 
            if ($IncludeCritical) { $levels += 1 }  # Critical
            $levels += 2  # Error
        }
        if ($EntryTypes -contains 'Warning') { $levels += 3 }
        if ($EntryTypes -contains 'Information') { $levels += 4 }
        if ($IncludeAuditSuccess) { $levels += 8 }  # Audit Success
        if ($IncludeAuditFailure) { $levels += 9 }  # Audit Failure
        
        if ($levels.Count -eq 0) {
            Write-Log "No entry types specified for $LogName" -Level WARNING
            return $null
        }
        
        # Parse Event ID ranges (e.g., "1000-1005" or "1000,1001,1002")
        $eventIdList = @()
        if ($EventIDs) {
            foreach ($id in $EventIDs) {
                if ($id -match '^(\d+)-(\d+)$') {
                    # Range format: 1000-1005
                    $start = [int]$matches[1]
                    $end = [int]$matches[2]
                    for ($i = $start; $i -le $end; $i++) {
                        $eventIdList += $i
                    }
                }
                elseif ($id -match '^\d+$') {
                    # Single ID
                    $eventIdList += [int]$id
                }
                else {
                    # Comma-separated list
                    $id -split ',' | ForEach-Object {
                        if ($_ -match '^\d+$') {
                            $eventIdList += [int]$_
                        }
                    }
                }
            }
        }
        
        # Retrieve events
        Write-Verbose "Retrieving events from $LogName (Max: $MaxEvents)..."
        
        $events = @()
        
        # Build Level filter part properly
        $levelFilter = ($levels | ForEach-Object { "Level=$_" }) -join ' or '
        
        # Build Event ID filter if specified
        $eventIdFilter = ""
        if ($eventIdList.Count -gt 0) {
            $eventIdConditions = $eventIdList | ForEach-Object { "EventID=$_" }
            $eventIdFilter = " and (" + ($eventIdConditions -join ' or ') + ")"
        }
        
        # Build Provider filter if specified
        $providerFilter = ""
        if ($Sources -and $Sources.Count -gt 0) {
            $providerConditions = $Sources | ForEach-Object { "Provider[@Name='$_']" }
            $providerFilter = " and (" + ($providerConditions -join ' or ') + ")"
        }
        
        $filterXml = @"
<QueryList>
  <Query Id="0" Path="$LogName">
    <Select Path="$LogName">
      *[System[TimeCreated[@SystemTime&gt;='$($StartTime.ToUniversalTime().ToString('o'))' and @SystemTime&lt;='$($EndTime.ToUniversalTime().ToString('o'))'] and ($levelFilter)$eventIdFilter$providerFilter]]
    </Select>
  </Query>
</QueryList>
"@
        
        # Log the filter for debugging
        Write-Verbose "FilterXml Query:`n$filterXml"
        Write-Log "Query filter: Start=$($StartTime.ToUniversalTime().ToString('o')), End=$($EndTime.ToUniversalTime().ToString('o')), Levels=$($levels -join ',')" -Level INFO
        
        try {
            # Use -ComputerName if remote machine specified
            $getWinEventParams = @{
                FilterXml = $filterXml
                MaxEvents = $MaxEvents
                ErrorAction = 'Stop'
            }
            if ($MachineName -ne $env:COMPUTERNAME) {
                $getWinEventParams['ComputerName'] = $MachineName
            }
            
            $events = Get-WinEvent @getWinEventParams
            Write-Log "Retrieved $($events.Count) events from $LogName" -Level SUCCESS
            
            # Apply message filter if specified (post-filtering since Get-WinEvent doesn't support message filtering in XML)
            if ($MessageFilter -and $events.Count -gt 0) {
                $originalCount = $events.Count
                $events = $events | Where-Object { 
                    $_.Message -like "*$MessageFilter*" -or 
                    $_.Message -like "*$($MessageFilter.ToLower())*" -or
                    $_.Message -like "*$($MessageFilter.ToUpper())*"
                }
                Write-Log "Applied message filter '$MessageFilter': $originalCount -> $($events.Count) events" -Level INFO
            }
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
                CriticalCount     = 0
                ErrorCount        = 0
                WarningCount      = 0
                InformationCount = 0
                AuditSuccessCount = 0
                AuditFailureCount = 0
                TopEventIDs       = @()
                TopSources        = @()
                Events            = @()
                StartTime         = $StartTime
                EndTime           = $EndTime
                Filters           = [PSCustomObject]@{
                    EventIDs = $eventIdList
                    Sources = $Sources
                    MessageFilter = $MessageFilter
                    IncludeAuditSuccess = $IncludeAuditSuccess
                    IncludeAuditFailure = $IncludeAuditFailure
                }
            }
        }
        
        # Analyze events
        $criticalEvents = @($events | Where-Object { $_.Level -eq 1 })
        $errorEvents = @($events | Where-Object { $_.Level -eq 2 })
        $warningEvents = @($events | Where-Object { $_.Level -eq 3 })
        $infoEvents = @($events | Where-Object { $_.Level -eq 4 })
        $auditSuccessEvents = @($events | Where-Object { $_.Level -eq 8 })
        $auditFailureEvents = @($events | Where-Object { $_.Level -eq 9 })
        
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
            CriticalCount     = $criticalEvents.Count
            ErrorCount        = $errorEvents.Count
            WarningCount      = $warningEvents.Count
            InformationCount  = $infoEvents.Count
            AuditSuccessCount = $auditSuccessEvents.Count
            AuditFailureCount = $auditFailureEvents.Count
            TopEventIDs       = $topEventIDs
            TopSources        = $topSources
            Events            = $eventDetails
            StartTime         = $StartTime
            EndTime           = $EndTime
            Filters           = [PSCustomObject]@{
                EventIDs = $eventIdList
                Sources = $Sources
                MessageFilter = $MessageFilter
                IncludeAuditSuccess = $IncludeAuditSuccess
                IncludeAuditFailure = $IncludeAuditFailure
            }
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
    [ValidateSet('JSON', 'CSV', 'HTML', 'Both', 'All')]
    [string]$Format,
    
    [Parameter(Mandatory = $false)]
    [switch]$ExportIndividualLogs
    )
    
    try {
        $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
        $exportedFiles = @()
        
        # Ensure export path exists
        if (-not (Test-Path $ExportPath)) {
            $null = New-Item -ItemType Directory -Path $ExportPath -Force
        }
        
        # Export JSON
        if ($Format -in @('JSON', 'Both', 'All')) {
            if ($ExportIndividualLogs) {
                # Export each log separately
                foreach ($log in $Results.LogAnalysis) {
                    $safeLogName = $log.LogName -replace '[^\w\s-]', '_'
                    $jsonPath = Join-Path $ExportPath "EventLogAnalysis_${safeLogName}_$timestamp.json"
                    
                    if ($PSCmdlet.ShouldProcess($jsonPath, "Export JSON for $($log.LogName)")) {
                        $logExport = [PSCustomObject]@{
                            ScriptVersion = $Results.ScriptVersion
                            AnalysisDate = $Results.AnalysisDate
                            StartTime = $Results.StartTime
                            EndTime = $Results.EndTime
                            LogAnalysis = @($log)
                        }
                        $logExport | ConvertTo-Json -Depth 10 | Set-Content -Path $jsonPath -Encoding UTF8
                        $exportedFiles += $jsonPath
                        Write-Log "Exported JSON for $($log.LogName) to: $jsonPath" -Level SUCCESS
                        Write-Host "  [EXPORTED] JSON ($($log.LogName)): $jsonPath" -ForegroundColor Green
                    }
                }
            }
            else {
                $jsonPath = Join-Path $ExportPath "EventLogAnalysis_$timestamp.json"
                
                if ($PSCmdlet.ShouldProcess($jsonPath, "Export JSON results")) {
                    $Results | ConvertTo-Json -Depth 10 | Set-Content -Path $jsonPath -Encoding UTF8
                    $exportedFiles += $jsonPath
                    Write-Log "Exported JSON to: $jsonPath" -Level SUCCESS
                    Write-Host "  [EXPORTED] JSON: $jsonPath" -ForegroundColor Green
                }
            }
        }
        
        # Export CSV (summary)
        if ($Format -in @('CSV', 'Both', 'All')) {
            if ($ExportIndividualLogs) {
                # Export each log separately
                foreach ($log in $Results.LogAnalysis) {
                    $safeLogName = $log.LogName -replace '[^\w\s-]', '_'
                    $csvPath = Join-Path $ExportPath "EventLogAnalysis_${safeLogName}_$timestamp.csv"
                    
                    if ($PSCmdlet.ShouldProcess($csvPath, "Export CSV for $($log.LogName)")) {
                        $csvData = [PSCustomObject]@{
                            LogName           = $log.LogName
                            TotalEvents       = $log.TotalEvents
                            CriticalCount     = $log.CriticalCount
                            ErrorCount        = $log.ErrorCount
                            WarningCount      = $log.WarningCount
                            InformationCount  = $log.InformationCount
                            AuditSuccessCount = $log.AuditSuccessCount
                            AuditFailureCount = $log.AuditFailureCount
                            StartTime         = $log.StartTime
                            EndTime           = $log.EndTime
                        }
                        
                        @($csvData) | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
                        $exportedFiles += $csvPath
                        Write-Log "Exported CSV for $($log.LogName) to: $csvPath" -Level SUCCESS
                        Write-Host "  [EXPORTED] CSV ($($log.LogName)): $csvPath" -ForegroundColor Green
                    }
                }
            }
            else {
                $csvPath = Join-Path $ExportPath "EventLogAnalysis_Summary_$timestamp.csv"
                
                if ($PSCmdlet.ShouldProcess($csvPath, "Export CSV summary")) {
                    $csvData = $Results.LogAnalysis | ForEach-Object {
                        [PSCustomObject]@{
                            LogName           = $_.LogName
                            TotalEvents       = $_.TotalEvents
                            CriticalCount     = $_.CriticalCount
                            ErrorCount        = $_.ErrorCount
                            WarningCount      = $_.WarningCount
                            InformationCount  = $_.InformationCount
                            AuditSuccessCount = $_.AuditSuccessCount
                            AuditFailureCount = $_.AuditFailureCount
                            StartTime         = $_.StartTime
                            EndTime           = $_.EndTime
                        }
                    }
                    
                    $csvData | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
                    $exportedFiles += $csvPath
                    Write-Log "Exported CSV to: $csvPath" -Level SUCCESS
                    Write-Host "  [EXPORTED] CSV: $csvPath" -ForegroundColor Green
                }
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
        
        # Export HTML
        if ($Format -in @('HTML', 'Both', 'All')) {
            $htmlPath = Join-Path $ExportPath "EventLogAnalysis_$timestamp.html"
            
            if ($PSCmdlet.ShouldProcess($htmlPath, "Export HTML report")) {
                $html = New-HtmlReport -Results $Results
                $html | Set-Content -Path $htmlPath -Encoding UTF8
                $exportedFiles += $htmlPath
                Write-Log "Exported HTML to: $htmlPath" -Level SUCCESS
                Write-Host "  [EXPORTED] HTML: $htmlPath" -ForegroundColor Green
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
    Generates an HTML report from analysis results.
#>
function New-HtmlReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Results
    )
    
    $html = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Event Log Analysis Report - SouliTEK</title>
    <style>
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin: 0; padding: 20px; background: #f5f5f5; }
        .container { max-width: 1400px; margin: 0 auto; background: white; padding: 30px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        h1 { color: #667eea; margin-top: 0; border-bottom: 3px solid #667eea; padding-bottom: 10px; }
        h2 { color: #764ba2; margin-top: 30px; }
        .summary { background: #f8f9fa; padding: 20px; border-radius: 5px; margin: 20px 0; }
        .log-section { margin: 30px 0; border: 1px solid #ddd; border-radius: 5px; overflow: hidden; }
        .log-header { background: #667eea; color: white; padding: 15px; font-weight: bold; font-size: 18px; }
        .log-content { padding: 20px; }
        .stats-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 15px; margin: 20px 0; }
        .stat-box { background: #f8f9fa; padding: 15px; border-radius: 5px; border-left: 4px solid #667eea; }
        .stat-label { font-size: 12px; color: #666; text-transform: uppercase; margin-bottom: 5px; }
        .stat-value { font-size: 24px; font-weight: bold; color: #333; }
        .critical { color: #dc3545; }
        .error { color: #dc3545; }
        .warning { color: #ffc107; }
        .info { color: #17a2b8; }
        .success { color: #28a745; }
        .failure { color: #dc3545; }
        table { width: 100%; border-collapse: collapse; margin: 20px 0; }
        th { background: #667eea; color: white; padding: 12px; text-align: left; }
        td { padding: 10px; border-bottom: 1px solid #ddd; }
        tr:hover { background: #f8f9fa; }
        .top-events { margin: 20px 0; }
        .event-item { padding: 10px; background: #f8f9fa; margin: 5px 0; border-radius: 3px; border-left: 3px solid #667eea; }
        .footer { margin-top: 40px; padding-top: 20px; border-top: 2px solid #ddd; text-align: center; color: #666; font-size: 12px; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Event Log Analysis Report</h1>
        <div class="summary">
            <p><strong>Analysis Date:</strong> $($Results.AnalysisDate.ToString('yyyy-MM-dd HH:mm:ss'))</p>
            <p><strong>Analysis Period:</strong> $($Results.StartTime.ToString('yyyy-MM-dd HH:mm:ss')) to $($Results.EndTime.ToString('yyyy-MM-dd HH:mm:ss'))</p>
            <p><strong>Logs Analyzed:</strong> $($Results.LogsAnalyzed -join ', ')</p>
            <p><strong>Entry Types:</strong> $($Results.EntryTypes -join ', ')</p>
        </div>
"@
    
    $totalCritical = 0
    $totalErrors = 0
    $totalWarnings = 0
    $totalInfo = 0
    $totalAuditSuccess = 0
    $totalAuditFailure = 0
    
    foreach ($log in $Results.LogAnalysis) {
        $totalCritical += $log.CriticalCount
        $totalErrors += $log.ErrorCount
        $totalWarnings += $log.WarningCount
        $totalInfo += $log.InformationCount
        $totalAuditSuccess += $log.AuditSuccessCount
        $totalAuditFailure += $log.AuditFailureCount
        
        $html += @"
        <div class="log-section">
            <div class="log-header">$($log.LogName)</div>
            <div class="log-content">
                <div class="stats-grid">
                    <div class="stat-box">
                        <div class="stat-label">Total Events</div>
                        <div class="stat-value">$($log.TotalEvents)</div>
                    </div>
                    <div class="stat-box">
                        <div class="stat-label">Critical</div>
                        <div class="stat-value critical">$($log.CriticalCount)</div>
                    </div>
                    <div class="stat-box">
                        <div class="stat-label">Errors</div>
                        <div class="stat-value error">$($log.ErrorCount)</div>
                    </div>
                    <div class="stat-box">
                        <div class="stat-label">Warnings</div>
                        <div class="stat-value warning">$($log.WarningCount)</div>
                    </div>
                    <div class="stat-box">
                        <div class="stat-label">Information</div>
                        <div class="stat-value info">$($log.InformationCount)</div>
                    </div>
"@
        if ($log.AuditSuccessCount -gt 0 -or $log.AuditFailureCount -gt 0) {
            $html += @"
                    <div class="stat-box">
                        <div class="stat-label">Audit Success</div>
                        <div class="stat-value success">$($log.AuditSuccessCount)</div>
                    </div>
                    <div class="stat-box">
                        <div class="stat-label">Audit Failure</div>
                        <div class="stat-value failure">$($log.AuditFailureCount)</div>
                    </div>
"@
        }
        
        $html += @"
                </div>
"@
        
        if ($log.TopEventIDs -and $log.TopEventIDs.Count -gt 0) {
            $html += @"
                <h3>Top Event IDs</h3>
                <div class="top-events">
"@
            foreach ($eventItem in $log.TopEventIDs) {
                $html += @"
                    <div class="event-item">Event ID $($eventItem.EventID): $($eventItem.Count) occurrences</div>
"@
            }
            $html += @"
                </div>
"@
        }
        
        $html += @"
            </div>
        </div>
"@
    }
    
    $html += @"
        <h2>Summary Totals</h2>
        <div class="stats-grid">
            <div class="stat-box">
                <div class="stat-label">Total Critical</div>
                <div class="stat-value critical">$totalCritical</div>
            </div>
            <div class="stat-box">
                <div class="stat-label">Total Errors</div>
                <div class="stat-value error">$totalErrors</div>
            </div>
            <div class="stat-box">
                <div class="stat-label">Total Warnings</div>
                <div class="stat-value warning">$totalWarnings</div>
            </div>
            <div class="stat-box">
                <div class="stat-label">Total Information</div>
                <div class="stat-value info">$totalInfo</div>
            </div>
"@
    
    if ($totalAuditSuccess -gt 0 -or $totalAuditFailure -gt 0) {
        $html += @"
            <div class="stat-box">
                <div class="stat-label">Total Audit Success</div>
                <div class="stat-value success">$totalAuditSuccess</div>
            </div>
            <div class="stat-box">
                <div class="stat-label">Total Audit Failure</div>
                <div class="stat-value failure">$totalAuditFailure</div>
            </div>
"@
    }
    
    $html += @"
        </div>
        <div class="footer">
            <p>Generated by SouliTEK EventLogAnalyzer v$($Results.ScriptVersion)</p>
            <p>www.soulitek.co.il</p>
        </div>
    </div>
</body>
</html>
"@
    
    return $html
}

<#
.SYNOPSIS
    Compares current analysis results with a baseline.
#>
function Compare-AnalysisResults {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Current,
        
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Baseline
    )
    
    $comparison = @{
        CurrentDate = $Current.AnalysisDate
        BaselineDate = $Baseline.AnalysisDate
        Changes = @()
    }
    
    foreach ($currentLog in $Current.LogAnalysis) {
        $baselineLog = $Baseline.LogAnalysis | Where-Object { $_.LogName -eq $currentLog.LogName }
        
        if ($baselineLog) {
            $change = [PSCustomObject]@{
                LogName = $currentLog.LogName
                ErrorCountChange = $currentLog.ErrorCount - $baselineLog.ErrorCount
                WarningCountChange = $currentLog.WarningCount - $baselineLog.WarningCount
                CriticalCountChange = $currentLog.CriticalCount - $baselineLog.CriticalCount
                TotalEventsChange = $currentLog.TotalEvents - $baselineLog.TotalEvents
                AuditSuccessChange = $currentLog.AuditSuccessCount - $baselineLog.AuditSuccessCount
                AuditFailureChange = $currentLog.AuditFailureCount - $baselineLog.AuditFailureCount
            }
            $comparison.Changes += $change
        }
    }
    
    return [PSCustomObject]$comparison
}

<#
.SYNOPSIS
    Displays comparison results.
#>
function Show-ComparisonResults {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Comparison
    )
    
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "  BASELINE COMPARISON" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "  Current Analysis: $($Comparison.CurrentDate)" -ForegroundColor White
    Write-Host "  Baseline Analysis: $($Comparison.BaselineDate)" -ForegroundColor White
    Write-Host ""
    
    foreach ($change in $Comparison.Changes) {
        Write-Host "  [$($change.LogName)]" -ForegroundColor Yellow
        
        if ($change.ErrorCountChange -ne 0) {
            $color = if ($change.ErrorCountChange -gt 0) { 'Red' } else { 'Green' }
            $sign = if ($change.ErrorCountChange -gt 0) { '+' } else { '' }
            Write-Host "    Errors: $sign$($change.ErrorCountChange)" -ForegroundColor $color
        }
        
        if ($change.WarningCountChange -ne 0) {
            $color = if ($change.WarningCountChange -gt 0) { 'Yellow' } else { 'Green' }
            $sign = if ($change.WarningCountChange -gt 0) { '+' } else { '' }
            Write-Host "    Warnings: $sign$($change.WarningCountChange)" -ForegroundColor $color
        }
        
        if ($change.CriticalCountChange -ne 0) {
            $color = if ($change.CriticalCountChange -gt 0) { 'Magenta' } else { 'Green' }
            $sign = if ($change.CriticalCountChange -gt 0) { '+' } else { '' }
            Write-Host "    Critical: $sign$($change.CriticalCountChange)" -ForegroundColor $color
        }
        
        if ($change.TotalEventsChange -ne 0) {
            $sign = if ($change.TotalEventsChange -gt 0) { '+' } else { '' }
            Write-Host "    Total Events: $sign$($change.TotalEventsChange)" -ForegroundColor Gray
        }
        
        Write-Host ""
    }
    
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
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
    
    Show-SouliTEKBanner
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
        
        if ($log.CriticalCount -gt 0) {
            Write-Host "    Critical: $($log.CriticalCount)" -ForegroundColor Magenta
        }
        
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
        
        if ($log.AuditSuccessCount -gt 0) {
            Write-Host "    Audit Success: $($log.AuditSuccessCount)" -ForegroundColor Green
        }
        
        if ($log.AuditFailureCount -gt 0) {
            Write-Host "    Audit Failure: $($log.AuditFailureCount)" -ForegroundColor Red
        }
        
        if ($log.TopEventIDs -and $log.TopEventIDs.Count -gt 0) {
            Write-Host "    Top Event IDs:" -ForegroundColor Gray
            $log.TopEventIDs | Select-Object -First 5 | ForEach-Object {
                Write-Host "      - Event $($_.EventID): $($_.Count) occurrences" -ForegroundColor DarkGray
            }
        }
        
        Write-Host ""
    }
    
    $totalCritical = ($Results.LogAnalysis | Measure-Object -Property CriticalCount -Sum).Sum
    $totalErrors = ($Results.LogAnalysis | Measure-Object -Property ErrorCount -Sum).Sum
    $totalWarnings = ($Results.LogAnalysis | Measure-Object -Property WarningCount -Sum).Sum
    $totalAuditSuccess = ($Results.LogAnalysis | Measure-Object -Property AuditSuccessCount -Sum).Sum
    $totalAuditFailure = ($Results.LogAnalysis | Measure-Object -Property AuditFailureCount -Sum).Sum
    
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "  TOTALS ACROSS ALL LOGS" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
    if ($totalCritical -gt 0) {
        Write-Host "  Total Critical: $totalCritical" -ForegroundColor Magenta
    }
    Write-Host "  Total Errors: $totalErrors" -ForegroundColor $(if ($totalErrors -gt 0) { 'Red' } else { 'Green' })
    Write-Host "  Total Warnings: $totalWarnings" -ForegroundColor $(if ($totalWarnings -gt 0) { 'Yellow' } else { 'Green' })
    if ($totalAuditSuccess -gt 0) {
        Write-Host "  Total Audit Success: $totalAuditSuccess" -ForegroundColor Green
    }
    if ($totalAuditFailure -gt 0) {
        Write-Host "  Total Audit Failure: $totalAuditFailure" -ForegroundColor Red
    }
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
            
            $analysis = Get-EventLogAnalysis -LogName $logName -StartTime $StartTime -EndTime $EndTime -EntryTypes $entryTypes -MaxEvents $MaxEvents -EventIDs $EventIDs -Sources $Sources -MessageFilter $MessageFilter -IncludeAuditSuccess $IncludeAuditSuccess.IsPresent -IncludeAuditFailure $IncludeAuditFailure.IsPresent -IncludeCritical $IncludeCritical -MachineName $MachineName
            
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
        
        # Comparison with baseline if specified
        if ($CompareWithBaseline -and (Test-Path $CompareWithBaseline)) {
            Write-Host "  [Comparing] With baseline: $CompareWithBaseline" -ForegroundColor Cyan
            try {
                $baseline = Get-Content $CompareWithBaseline -Raw | ConvertFrom-Json
                $comparison = Compare-AnalysisResults -Current $finalResults -Baseline $baseline
                Show-ComparisonResults -Comparison $comparison
            }
            catch {
                Write-Warning "Failed to compare with baseline: $_"
            }
        }
        
        # Export results
        Write-Host "  [Exporting] Results to $ExportPath..." -ForegroundColor Cyan
        $exportResult = Export-AnalysisResults -Results $finalResults -ExportPath $ExportPath -Format $ExportFormat -ExportIndividualLogs:$ExportIndividualLogs.IsPresent
        
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

if (-not (Test-SouliTEKAdministrator)) {
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
# MENU INTERFACE
# ============================================================

function Show-ReportMenu {
    [CmdletBinding()]
    param()
    
    Clear-Host
    Show-SouliTEKBanner
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "  EVENT LOG ANALYZER - REPORT OPTIONS" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Select a predefined report:" -ForegroundColor White
    Write-Host ""
    Write-Host "  [1] PC Crash Events (Last 7 Days)     - System crashes, blue screens, critical errors" -ForegroundColor Yellow
    Write-Host "  [2] Memory Issues (Last 3 Days)        - Memory leaks, out of memory errors" -ForegroundColor Yellow
    Write-Host "  [3] Security Audit (Last 24 Hours)     - Failed logins, audit failures" -ForegroundColor Yellow
    Write-Host "  [4] Application Errors (Last 7 Days)    - Application crashes and errors" -ForegroundColor Yellow
    Write-Host "  [5] System Warnings (Last 3 Days)      - System warnings and issues" -ForegroundColor Yellow
    Write-Host "  [6] Login Events (Last 7 Days)         - Successful and failed login attempts" -ForegroundColor Yellow
    Write-Host "  [7] Disk Issues (Last 7 Days)          - Disk errors, I/O failures" -ForegroundColor Yellow
    Write-Host "  [8] Network Problems (Last 3 Days)     - Network adapter errors, connectivity issues" -ForegroundColor Yellow
    Write-Host "  [9] Driver Failures (Last 7 Days)      - Driver crashes and load failures" -ForegroundColor Yellow
    Write-Host "  [10] Windows Update Issues (Last 14 Days) - Update failures and errors" -ForegroundColor Yellow
    Write-Host "  [11] Custom Analysis                   - Configure your own analysis" -ForegroundColor Cyan
    Write-Host "  [12] Help                              - Usage guide and examples" -ForegroundColor White
    Write-Host "  [0] Exit" -ForegroundColor Red
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    
    $choice = Read-Host "Enter your choice (0-12)"
    return $choice
}

function Invoke-CrashEventsReport {
    Write-Host ""
    Write-Host "Generating PC Crash Events Report (Last 7 Days)..." -ForegroundColor Cyan
    Write-Host ""
    
    $StartTime = (Get-Date).AddDays(-7)
    $EndTime = Get-Date
    $LogNames = @('System', 'Application')
    $IncludeWarnings = $false
    $IncludeInformation = $false
    $IncludeCritical = $true
    
    # Event IDs for crashes and critical errors
    $EventIDs = @('41', '6008', '1001', '1074', '1076', '6005', '6006', '6009', '6013')
    # Sources for crash-related events
    $Sources = @('Microsoft-Windows-Kernel-General', 'Microsoft-Windows-Kernel-Power', 'BugCheck')
    
    Write-Host "Searching for:" -ForegroundColor White
    Write-Host "  - System crashes (Event ID 41)" -ForegroundColor Gray
    Write-Host "  - Unexpected shutdowns (Event ID 6008)" -ForegroundColor Gray
    Write-Host "  - Blue screen crashes (Event ID 1001)" -ForegroundColor Gray
    Write-Host "  - Critical system errors" -ForegroundColor Gray
    Write-Host ""
    
    & $PSCommandPath -LogNames $LogNames -StartTime $StartTime -EndTime $EndTime -IncludeWarnings:$IncludeWarnings -IncludeInformation:$IncludeInformation -IncludeCritical:$IncludeCritical -EventIDs $EventIDs -Sources $Sources -ExportFormat 'All' -Force
}

function Invoke-MemoryIssuesReport {
    Write-Host ""
    Write-Host "Generating Memory Issues Report (Last 3 Days)..." -ForegroundColor Cyan
    Write-Host ""
    
    $StartTime = (Get-Date).AddDays(-3)
    $EndTime = Get-Date
    $LogNames = @('System', 'Application')
    $IncludeWarnings = $true
    $IncludeInformation = $false
    
    # Message filter for memory-related events
    $MessageFilter = "memory"
    $EventIDs = @('2004', '2005', '2019', '2020')
    
    Write-Host "Searching for:" -ForegroundColor White
    Write-Host "  - Out of memory errors" -ForegroundColor Gray
    Write-Host "  - Memory allocation failures" -ForegroundColor Gray
    Write-Host "  - Low memory warnings" -ForegroundColor Gray
    Write-Host "  - Memory-related application errors" -ForegroundColor Gray
    Write-Host ""
    
    & $PSCommandPath -LogNames $LogNames -StartTime $StartTime -EndTime $EndTime -IncludeWarnings:$IncludeWarnings -IncludeInformation:$IncludeInformation -MessageFilter $MessageFilter -EventIDs $EventIDs -ExportFormat 'All' -Force
}

function Invoke-SecurityAuditReport {
    Write-Host ""
    Write-Host "Generating Security Audit Report (Last 24 Hours)..." -ForegroundColor Cyan
    Write-Host ""
    
    $StartTime = (Get-Date).AddHours(-24)
    $EndTime = Get-Date
    $LogNames = @('Security')
    $IncludeWarnings = $false
    $IncludeAuditSuccess = $true
    $IncludeAuditFailure = $true
    
    # Security audit event IDs
    $EventIDs = @('4624', '4625', '4648', '4672', '4776', '4777', '4778', '4779', '4780', '4800', '4801', '4802', '4803', '4768', '4769', '4770', '4771')
    
    Write-Host "Searching for:" -ForegroundColor White
    Write-Host "  - Failed login attempts (Event ID 4625)" -ForegroundColor Gray
    Write-Host "  - Successful logins (Event ID 4624)" -ForegroundColor Gray
    Write-Host "  - Privilege escalation (Event ID 4672)" -ForegroundColor Gray
    Write-Host "  - Authentication failures" -ForegroundColor Gray
    Write-Host ""
    
    & $PSCommandPath -LogNames $LogNames -StartTime $StartTime -EndTime $EndTime -IncludeWarnings:$IncludeWarnings -IncludeAuditSuccess:$IncludeAuditSuccess -IncludeAuditFailure:$IncludeAuditFailure -EventIDs $EventIDs -ExportFormat 'All' -Force
}

function Invoke-ApplicationErrorsReport {
    Write-Host ""
    Write-Host "Generating Application Errors Report (Last 7 Days)..." -ForegroundColor Cyan
    Write-Host ""
    
    $StartTime = (Get-Date).AddDays(-7)
    $EndTime = Get-Date
    $LogNames = @('Application')
    $IncludeWarnings = $true
    $IncludeInformation = $false
    
    Write-Host "Searching for:" -ForegroundColor White
    Write-Host "  - Application crashes" -ForegroundColor Gray
    Write-Host "  - Application errors" -ForegroundColor Gray
    Write-Host "  - Application warnings" -ForegroundColor Gray
    Write-Host ""
    
    & $PSCommandPath -LogNames $LogNames -StartTime $StartTime -EndTime $EndTime -IncludeWarnings:$IncludeWarnings -IncludeInformation:$IncludeInformation -ExportFormat 'All' -Force
}

function Invoke-SystemWarningsReport {
    Write-Host ""
    Write-Host "Generating System Warnings Report (Last 3 Days)..." -ForegroundColor Cyan
    Write-Host ""
    
    $StartTime = (Get-Date).AddDays(-3)
    $EndTime = Get-Date
    $LogNames = @('System')
    $IncludeWarnings = $true
    $IncludeInformation = $false
    
    Write-Host "Searching for:" -ForegroundColor White
    Write-Host "  - System warnings" -ForegroundColor Gray
    Write-Host "  - System errors" -ForegroundColor Gray
    Write-Host "  - Service issues" -ForegroundColor Gray
    Write-Host ""
    
    & $PSCommandPath -LogNames $LogNames -StartTime $StartTime -EndTime $EndTime -IncludeWarnings:$IncludeWarnings -IncludeInformation:$IncludeInformation -ExportFormat 'All' -Force
}

function Invoke-LoginEventsReport {
    Write-Host ""
    Write-Host "Generating Login Events Report (Last 7 Days)..." -ForegroundColor Cyan
    Write-Host ""
    
    $StartTime = (Get-Date).AddDays(-7)
    $EndTime = Get-Date
    $LogNames = @('Security')
    $IncludeWarnings = $false
    $IncludeAuditSuccess = $true
    $IncludeAuditFailure = $true
    
    # Login-related event IDs
    $EventIDs = @('4624', '4625', '4634', '4647', '4648', '4675', '4776', '4777', '4778', '4779', '4800', '4801', '4802', '4803')
    
    Write-Host "Searching for:" -ForegroundColor White
    Write-Host "  - Successful logins (Event ID 4624)" -ForegroundColor Gray
    Write-Host "  - Failed logins (Event ID 4625)" -ForegroundColor Gray
    Write-Host "  - Logoffs (Event ID 4634)" -ForegroundColor Gray
    Write-Host "  - Lock/unlock events" -ForegroundColor Gray
    Write-Host ""
    
    & $PSCommandPath -LogNames $LogNames -StartTime $StartTime -EndTime $EndTime -IncludeWarnings:$IncludeWarnings -IncludeAuditSuccess:$IncludeAuditSuccess -IncludeAuditFailure:$IncludeAuditFailure -EventIDs $EventIDs -ExportFormat 'All' -Force
}

function Invoke-DiskIssuesReport {
    Write-Host ""
    Write-Host "Generating Disk Issues Report (Last 7 Days)..." -ForegroundColor Cyan
    Write-Host ""
    
    $StartTime = (Get-Date).AddDays(-7)
    $EndTime = Get-Date
    $LogNames = @('System', 'Application')
    $IncludeWarnings = $true
    $IncludeInformation = $false
    
    # Disk-related event IDs and sources
    $EventIDs = @('7', '15', '51', '52', '55', '57')
    $Sources = @('Disk', 'ntfs', 'Microsoft-Windows-Storage-Disk')
    $MessageFilter = "disk"
    
    Write-Host "Searching for:" -ForegroundColor White
    Write-Host "  - Disk I/O errors" -ForegroundColor Gray
    Write-Host "  - Disk corruption" -ForegroundColor Gray
    Write-Host "  - Disk timeout errors" -ForegroundColor Gray
    Write-Host "  - Storage device failures" -ForegroundColor Gray
    Write-Host ""
    
    & $PSCommandPath -LogNames $LogNames -StartTime $StartTime -EndTime $EndTime -IncludeWarnings:$IncludeWarnings -IncludeInformation:$IncludeInformation -EventIDs $EventIDs -Sources $Sources -MessageFilter $MessageFilter -ExportFormat 'All' -Force
}

function Invoke-NetworkProblemsReport {
    Write-Host ""
    Write-Host "Generating Network Problems Report (Last 3 Days)..." -ForegroundColor Cyan
    Write-Host ""
    
    $StartTime = (Get-Date).AddDays(-3)
    $EndTime = Get-Date
    $LogNames = @('System')
    $IncludeWarnings = $true
    $IncludeInformation = $false
    
    # Network-related sources
    $Sources = @('Microsoft-Windows-NetworkProfile', 'Microsoft-Windows-TCPIP', 'Microsoft-Windows-NCSI', 'e1rexpress', 'e2express')
    $MessageFilter = "network"
    
    Write-Host "Searching for:" -ForegroundColor White
    Write-Host "  - Network adapter errors" -ForegroundColor Gray
    Write-Host "  - TCP/IP issues" -ForegroundColor Gray
    Write-Host "  - Network connectivity problems" -ForegroundColor Gray
    Write-Host "  - DNS resolution failures" -ForegroundColor Gray
    Write-Host ""
    
    & $PSCommandPath -LogNames $LogNames -StartTime $StartTime -EndTime $EndTime -IncludeWarnings:$IncludeWarnings -IncludeInformation:$IncludeInformation -Sources $Sources -MessageFilter $MessageFilter -ExportFormat 'All' -Force
}

function Invoke-DriverFailuresReport {
    Write-Host ""
    Write-Host "Generating Driver Failures Report (Last 7 Days)..." -ForegroundColor Cyan
    Write-Host ""
    
    $StartTime = (Get-Date).AddDays(-7)
    $EndTime = Get-Date
    $LogNames = @('System')
    $IncludeWarnings = $true
    $IncludeInformation = $false
    
    # Driver-related event IDs
    $EventIDs = @('219', '1001')
    $Sources = @('Microsoft-Windows-Kernel-PnP', 'Microsoft-Windows-DriverFrameworks-UserMode')
    $MessageFilter = "driver"
    
    Write-Host "Searching for:" -ForegroundColor White
    Write-Host "  - Driver crashes" -ForegroundColor Gray
    Write-Host "  - Driver load failures" -ForegroundColor Gray
    Write-Host "  - Driver timeout errors" -ForegroundColor Gray
    Write-Host "  - Plug and Play errors" -ForegroundColor Gray
    Write-Host ""
    
    & $PSCommandPath -LogNames $LogNames -StartTime $StartTime -EndTime $EndTime -IncludeWarnings:$IncludeWarnings -IncludeInformation:$IncludeInformation -EventIDs $EventIDs -Sources $Sources -MessageFilter $MessageFilter -ExportFormat 'All' -Force
}

function Invoke-WindowsUpdateIssuesReport {
    Write-Host ""
    Write-Host "Generating Windows Update Issues Report (Last 14 Days)..." -ForegroundColor Cyan
    Write-Host ""
    
    $StartTime = (Get-Date).AddDays(-14)
    $EndTime = Get-Date
    $LogNames = @('System', 'Application')
    $IncludeWarnings = $true
    $IncludeInformation = $false
    
    # Windows Update sources
    $Sources = @('Microsoft-Windows-WindowsUpdateClient', 'Microsoft-Windows-UpdateOrchestrator', 'Microsoft-Windows-Servicing')
    $MessageFilter = "update"
    
    Write-Host "Searching for:" -ForegroundColor White
    Write-Host "  - Update installation failures" -ForegroundColor Gray
    Write-Host "  - Update download errors" -ForegroundColor Gray
    Write-Host "  - Update service issues" -ForegroundColor Gray
    Write-Host "  - Update rollback events" -ForegroundColor Gray
    Write-Host ""
    
    & $PSCommandPath -LogNames $LogNames -StartTime $StartTime -EndTime $EndTime -IncludeWarnings:$IncludeWarnings -IncludeInformation:$IncludeInformation -Sources $Sources -MessageFilter $MessageFilter -ExportFormat 'All' -Force
}

function Show-CustomAnalysisMenu {
    Clear-Host
    Show-SouliTEKBanner
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "  CUSTOM ANALYSIS CONFIGURATION" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "This will open the script with default parameters." -ForegroundColor White
    Write-Host "You can then use command-line parameters for advanced configuration." -ForegroundColor White
    Write-Host ""
    Write-Host "Examples:" -ForegroundColor Yellow
    Write-Host "  .\EventLogAnalyzer.ps1 -Hours 48 -LogNames System,Application" -ForegroundColor Gray
    Write-Host "  .\EventLogAnalyzer.ps1 -EventIDs @(1000,1001) -IncludeWarnings" -ForegroundColor Gray
    Write-Host "  .\EventLogAnalyzer.ps1 -ExportFormat HTML -ExportIndividualLogs" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Press any key to continue with default analysis..." -ForegroundColor Cyan
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
    
    # Run with default parameters
    & $PSCommandPath
}

function Show-HelpMenu {
    Clear-Host
    Show-SouliTEKBanner
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "  EVENT LOG ANALYZER - HELP & EXAMPLES" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "REPORT OPTIONS:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  1. PC Crash Events (Last 7 Days)" -ForegroundColor White
    Write-Host "     - System crashes, blue screens, unexpected shutdowns" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  2. Memory Issues (Last 3 Days)" -ForegroundColor White
    Write-Host "     - Out of memory errors, memory allocation failures" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  3. Security Audit (Last 24 Hours)" -ForegroundColor White
    Write-Host "     - Failed logins, authentication failures, privilege escalation" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  4. Application Errors (Last 7 Days)" -ForegroundColor White
    Write-Host "     - Application crashes and errors from Application log" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  5. System Warnings (Last 3 Days)" -ForegroundColor White
    Write-Host "     - System warnings and errors from System log" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  6. Login Events (Last 7 Days)" -ForegroundColor White
    Write-Host "     - Successful and failed login attempts, lock/unlock events" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  7. Disk Issues (Last 7 Days)" -ForegroundColor White
    Write-Host "     - Disk I/O errors, corruption, timeout errors" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  8. Network Problems (Last 3 Days)" -ForegroundColor White
    Write-Host "     - Network adapter errors, TCP/IP issues, connectivity problems" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  9. Driver Failures (Last 7 Days)" -ForegroundColor White
    Write-Host "     - Driver crashes, load failures, Plug and Play errors" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  10. Windows Update Issues (Last 14 Days)" -ForegroundColor White
    Write-Host "      - Update installation failures, download errors, service issues" -ForegroundColor Gray
    Write-Host ""
    Write-Host "EXPORT FORMATS:" -ForegroundColor Yellow
    Write-Host "  - JSON: Structured data for programmatic use" -ForegroundColor Gray
    Write-Host "  - CSV: Spreadsheet-compatible format" -ForegroundColor Gray
    Write-Host "  - HTML: Professional web report with styling" -ForegroundColor Gray
    Write-Host ""
    Write-Host "For more information, visit: www.soulitek.co.il" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Press any key to return to main menu..." -ForegroundColor Yellow
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
}

# ============================================================
# MAIN MENU LOOP
# ============================================================

function Invoke-MainMenu {
    do {
        $choice = Show-ReportMenu
        
        switch ($choice) {
            '1' { Invoke-CrashEventsReport }
            '2' { Invoke-MemoryIssuesReport }
            '3' { Invoke-SecurityAuditReport }
            '4' { Invoke-ApplicationErrorsReport }
            '5' { Invoke-SystemWarningsReport }
            '6' { Invoke-LoginEventsReport }
            '7' { Invoke-DiskIssuesReport }
            '8' { Invoke-NetworkProblemsReport }
            '9' { Invoke-DriverFailuresReport }
            '10' { Invoke-WindowsUpdateIssuesReport }
            '11' { Show-CustomAnalysisMenu }
            '12' { Show-HelpMenu }
            '0' { 
                Write-Host ""
                Write-Host "Thank you for using SouliTEK EventLogAnalyzer!" -ForegroundColor Green
                Write-Host "Website: www.soulitek.co.il" -ForegroundColor Cyan
                Write-Host ""
                exit 0
            }
            default {
                Write-Host ""
                Write-Host "Invalid choice. Please select a number between 0-12." -ForegroundColor Red
                Write-Host "Press any key to continue..." -ForegroundColor Yellow
                $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
            }
        }
        
        if ($choice -ne '0' -and $choice -ne '12') {
            Write-Host ""
            Write-Host "Press any key to return to main menu..." -ForegroundColor Yellow
            $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
        }
    } while ($true)
}

# ============================================================
# RUN MAIN ANALYSIS OR MENU
# ============================================================

# Check if script was called with explicit parameters (excluding common parameters like Verbose, Debug, etc.)
$explicitParams = @('LogNames', 'Hours', 'StartTime', 'EndTime', 'IncludeWarnings', 'IncludeInformation', 
                     'MaxEvents', 'ExportPath', 'ExportFormat', 'Force', 'RunExamples', 'EventIDs', 
                     'Sources', 'MessageFilter', 'IncludeAuditSuccess', 'IncludeAuditFailure', 
                     'IncludeCritical', 'CompareWithBaseline', 'ExportIndividualLogs', 'MachineName')
$hasExplicitParams = $false

foreach ($param in $explicitParams) {
    if ($PSBoundParameters.ContainsKey($param)) {
        $hasExplicitParams = $true
        break
    }
}

# If no explicit parameters provided, show menu; otherwise run analysis directly
if (-not $hasExplicitParams) {
    Invoke-MainMenu
}
else {
    $result = Invoke-MainAnalysis
    
    if ($result) {
        exit 0
    }
    else {
        exit 1
    }
}




