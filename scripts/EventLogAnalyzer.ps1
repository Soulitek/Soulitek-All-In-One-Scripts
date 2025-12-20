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
    [ValidateSet('JSON', 'CSV', 'HTML', 'CLIXML', 'Both', 'All')]
    [string]$ExportFormat = 'Both',
    
    [Parameter(Mandatory = $false)]
    [switch]$Force,
    
    [Parameter(Mandatory = $false)]
    [switch]$RunExamples,
    
    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 365)]
    [int]$LogRetentionDays = 14,
    
    [Parameter(Mandatory = $false)]
    [switch]$ExportClixml,
    
    [Parameter(Mandatory = $false)]
    [string]$ClixmlArchivePath,
    
    [Parameter(Mandatory = $false)]
    [switch]$RegisterScheduledTask,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet('Daily', 'Weekly', 'Hourly')]
    [string]$TaskSchedule = 'Daily',
    
    [Parameter(Mandatory = $false)]
    [string]$TaskTime = '03:00',
    
    [Parameter(Mandatory = $false)]
    [switch]$AutoRun,
    
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
$script:TranscriptPath = $null
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
    Removes old log files, transcripts, and archives based on retention period.
    
.DESCRIPTION
    Deletes files older than the specified retention period from the log folder.
    Optionally zips files before deletion if they exceed a size threshold.
    
.PARAMETER RetentionDays
    Number of days to retain files. Default: 14
#>
function Remove-OldLogs {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [int]$RetentionDays = 14
    )
    
    try {
        if (-not (Test-Path $script:LogFolder)) {
            return
        }
        
        $cutoffDate = (Get-Date).AddDays(-$RetentionDays)
        $filesDeleted = 0
        
        Write-Verbose "Cleaning up files older than $cutoffDate in $script:LogFolder"
        
        $oldFiles = Get-ChildItem -Path $script:LogFolder -File -ErrorAction SilentlyContinue | 
            Where-Object { $_.LastWriteTime -lt $cutoffDate }
        
        foreach ($file in $oldFiles) {
            try {
                Remove-Item -Path $file.FullName -Force -ErrorAction Stop
                $filesDeleted++
                Write-Verbose "Deleted old file: $($file.Name)"
            }
            catch {
                Write-Warning "Failed to delete $($file.Name): $_"
            }
        }
        
        if ($filesDeleted -gt 0) {
            Write-Verbose "Cleaned up $filesDeleted old file(s)"
        }
    }
    catch {
        Write-Warning "Error during log cleanup: $_"
    }
}

<#
.SYNOPSIS
    Initializes PowerShell transcript logging.
    
.DESCRIPTION
    Creates log directory and starts PowerShell transcript for session logging.
#>
function Initialize-Transcript {
    [CmdletBinding()]
    param()
    
    try {
        # Create log folder if it doesn't exist
        if (-not (Test-Path $script:LogFolder)) {
            $null = New-Item -ItemType Directory -Path $script:LogFolder -Force -ErrorAction Stop
        }
        
        $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
        $script:TranscriptPath = Join-Path $script:LogFolder "EventLogAnalyzer_Transcript_$timestamp.log"
        $script:JsonSummaryFile = Join-Path $script:LogFolder "EventLogAnalyzer_Summary_$timestamp.json"
        
        # Start transcript
        Start-Transcript -Path $script:TranscriptPath -Append -ErrorAction Stop
        
        Write-Verbose "Transcript started: $script:TranscriptPath"
        
        return [PSCustomObject]@{
            LogFolder    = $script:LogFolder
            Transcript   = $script:TranscriptPath
            JsonSummary  = $script:JsonSummaryFile
        }
    }
    catch {
        Write-Error "Failed to initialize transcript: $_"
        throw
    }
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
    
    Write-Verbose "Analyzing log: $LogName from $StartTime to $EndTime"
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
            Write-Warning "No entry types specified for $LogName"
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
        Write-Verbose "Query filter: Start=$($StartTime.ToUniversalTime().ToString('o')), End=$($EndTime.ToUniversalTime().ToString('o')), Levels=$($levels -join ',')"
        
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
            Write-Verbose "Retrieved $($events.Count) events from $LogName"
            
            # Apply message filter if specified (post-filtering since Get-WinEvent doesn't support message filtering in XML)
            if ($MessageFilter -and $events.Count -gt 0) {
                $originalCount = $events.Count
                $events = $events | Where-Object { 
                    $_.Message -like "*$MessageFilter*" -or 
                    $_.Message -like "*$($MessageFilter.ToLower())*" -or
                    $_.Message -like "*$($MessageFilter.ToUpper())*"
                }
                Write-Verbose "Applied message filter '$MessageFilter': $originalCount -> $($events.Count) events"
            }
        }
        catch {
            if ($_.Exception.Message -match "No events were found") {
                Write-Verbose "No events found in $LogName for specified criteria"
                $events = @()
            }
            elseif ($_.Exception.Message -match "specified query is invalid") {
                Write-Error "Invalid query for $LogName. Filter: $levelFilter"
                Write-Error "Failed to analyze event log '$LogName': The specified query is invalid. This may be due to incorrect date format or log access permissions."
                return $null
            }
            else {
                Write-Error "Error querying $LogName : $($_.Exception.Message)"
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
        
        # Top Error Event IDs (errors only)
        $topErrorEventIDs = $errorEvents | 
            Group-Object -Property Id | 
            Sort-Object Count -Descending | 
            Select-Object -First 10 |
            ForEach-Object {
                [PSCustomObject]@{
                    EventID = $_.Name
                    Count   = $_.Count
                }
            }
        
        # Top Error Providers (errors only)
        $topErrorProviders = $errorEvents | 
            Group-Object -Property ProviderName | 
            Sort-Object Count -Descending | 
            Select-Object -First 10 |
            ForEach-Object {
                [PSCustomObject]@{
                    Provider = $_.Name
                    Count    = $_.Count
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
            TopErrorEventIDs  = $topErrorEventIDs
            TopErrorProviders  = $topErrorProviders
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
        Write-Error "Error analyzing $LogName : $_"
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
    [ValidateSet('JSON', 'CSV', 'HTML', 'CLIXML', 'Both', 'All')]
    [string]$Format,
    
    [Parameter(Mandatory = $false)]
    [string]$ClixmlArchivePath,
    
    [Parameter(Mandatory = $false)]
    [switch]$ExportIndividualLogs
    )
    
    try {
        $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
        $exportedFiles = @()
        
        # Ensure export path exists
        if (-not (Test-Path $ExportPath)) {
            try {
                $null = New-Item -ItemType Directory -Path $ExportPath -Force -ErrorAction Stop
            }
            catch {
                Write-Error "Failed to create export directory: $_"
                throw
            }
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
                        $logExport | ConvertTo-Json -Depth 10 -ErrorAction Stop | Set-Content -Path $jsonPath -Encoding UTF8 -ErrorAction Stop
                        $exportedFiles += $jsonPath
                        Write-Verbose "Exported JSON for $($log.LogName) to: $jsonPath"
                        Write-Host "  [EXPORTED] JSON ($($log.LogName)): $jsonPath" -ForegroundColor Green
                    }
                }
            }
            else {
                $jsonPath = Join-Path $ExportPath "EventLogAnalysis_$timestamp.json"
                
                if ($PSCmdlet.ShouldProcess($jsonPath, "Export JSON results")) {
                    $Results | ConvertTo-Json -Depth 10 -ErrorAction Stop | Set-Content -Path $jsonPath -Encoding UTF8 -ErrorAction Stop
                    $exportedFiles += $jsonPath
                    Write-Verbose "Exported JSON to: $jsonPath"
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
                        
                        @($csvData) | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8 -ErrorAction Stop
                        $exportedFiles += $csvPath
                        Write-Verbose "Exported CSV for $($log.LogName) to: $csvPath"
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
                    
                    $csvData | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8 -ErrorAction Stop
                    $exportedFiles += $csvPath
                    Write-Verbose "Exported CSV to: $csvPath"
                    Write-Host "  [EXPORTED] CSV: $csvPath" -ForegroundColor Green
                }
            }
            
            # Export detailed events CSV (flat format for C-suite)
            $csvEventsPath = Join-Path $ExportPath "EventLogAnalysis_Events_Flat_$timestamp.csv"
            
            if ($PSCmdlet.ShouldProcess($csvEventsPath, "Export detailed events CSV (flat)")) {
                $allEvents = $Results.LogAnalysis | ForEach-Object {
                    $logName = $_.LogName
                    $_.Events | ForEach-Object {
                        # Ensure completely flat structure - no nested objects
                        [PSCustomObject]@{
                            LogName     = $logName
                            TimeCreated = $_.TimeCreated
                            Level       = $_.Level
                            EventID     = $_.EventID
                            Source      = $_.Source
                            Message     = $_.Message
                        }
                    }
                }
                
                if ($allEvents) {
                    try {
                        $allEvents | Export-Csv -Path $csvEventsPath -NoTypeInformation -Encoding UTF8 -ErrorAction Stop
                        $exportedFiles += $csvEventsPath
                        Write-Verbose "Exported detailed events CSV (flat) to: $csvEventsPath"
                        Write-Host "  [EXPORTED] Events CSV (Flat): $csvEventsPath" -ForegroundColor Green
                    }
                    catch {
                        Write-Error "Failed to export events CSV: $_"
                    }
                }
            }
        }
        
        # Export CLIXML
        if ($Format -in @('CLIXML', 'All') -or $ExportClixml) {
            try {
                $clixmlPath = if ($ClixmlArchivePath) {
                    $ClixmlArchivePath
                } else {
                    Join-Path $ExportPath "Archives"
                }
                
                $clixmlFile = Export-EventLogClixml -Results $Results -ExportPath $clixmlPath
                if ($clixmlFile) {
                    $exportedFiles += $clixmlFile
                    Write-Host "  [EXPORTED] CLIXML Archive: $clixmlFile" -ForegroundColor Green
                }
            }
            catch {
                Write-Error "Failed to export CLIXML: $_"
            }
        }
        
        # Export HTML
        if ($Format -in @('HTML', 'Both', 'All')) {
            $htmlPath = Join-Path $ExportPath "EventLogAnalysis_$timestamp.html"
            
            if ($PSCmdlet.ShouldProcess($htmlPath, "Export HTML report")) {
                $html = New-HtmlReport -Results $Results
                $html | Set-Content -Path $htmlPath -Encoding UTF8 -ErrorAction Stop
                $exportedFiles += $htmlPath
                Write-Verbose "Exported HTML to: $htmlPath"
                Write-Host "  [EXPORTED] HTML: $htmlPath" -ForegroundColor Green
            }
        }
        
        return [PSCustomObject]@{
            ExportedFiles = $exportedFiles
            Success       = $true
        }
    }
    catch {
        Write-Error "Failed to export results: $_"
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
    Displays export format selection menu.
    
.DESCRIPTION
    Prompts user to select which format(s) to export analysis results.
    
.OUTPUTS
    Selected format: "JSON", "CSV", "HTML", "CLIXML", "Both", "All", or "CANCEL"
#>
function Show-ExportMenu {
    [CmdletBinding()]
    [OutputType([string])]
    param()
    
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "  EXPORT RESULTS" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Select export format:" -ForegroundColor White
    Write-Host ""
    Write-Host "  [1] JSON          - Structured data for programmatic use" -ForegroundColor Yellow
    Write-Host "  [2] CSV           - Spreadsheet format (flat, Excel-compatible)" -ForegroundColor Yellow
    Write-Host "  [3] HTML          - Professional web report with styling" -ForegroundColor Yellow
    Write-Host "  [4] CLIXML        - PowerShell native format for third-party analysis" -ForegroundColor Yellow
    Write-Host "  [5] Both (JSON + CSV)" -ForegroundColor Cyan
    Write-Host "  [6] All Formats   - Export everything" -ForegroundColor Cyan
    Write-Host "  [0] Skip Export   - Don't export, just view summary" -ForegroundColor Red
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    
    $choice = Read-Host "Enter your choice (0-6)"
    
    switch ($choice) {
        "1" { return "JSON" }
        "2" { return "CSV" }
        "3" { return "HTML" }
        "4" { return "CLIXML" }
        "5" { return "Both" }
        "6" { return "All" }
        "0" { return "CANCEL" }
        default {
            Write-Host "Invalid choice. Export cancelled." -ForegroundColor Red
            return "CANCEL"
        }
    }
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
    Calculates statistical metrics from analysis results.
    
.DESCRIPTION
    Computes error percentage, standard deviation, mean event counts,
    and identifies most common error Event IDs and Providers.
    
.PARAMETER Results
    Analysis results object.
    
.OUTPUTS
    PSCustomObject with statistical metrics.
#>
function Get-EventLogStatistics {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Results
    )
    
    try {
        $totalEvents = ($Results.LogAnalysis | Measure-Object -Property TotalEvents -Sum).Sum
        $totalErrors = ($Results.LogAnalysis | Measure-Object -Property ErrorCount -Sum).Sum
        
        # Calculate error percentage
        $errorPercentage = if ($totalEvents -gt 0) {
            [math]::Round(($totalErrors / $totalEvents) * 100, 2)
        } else {
            0
        }
        
        # Calculate mean and standard deviation of event counts
        $eventCounts = $Results.LogAnalysis | ForEach-Object { $_.TotalEvents }
        $meanEventCount = if ($eventCounts.Count -gt 0) {
            [math]::Round(($eventCounts | Measure-Object -Average).Average, 2)
        } else {
            0
        }
        
        $stdDevEventCount = 0
        if ($eventCounts.Count -gt 1) {
            $variance = ($eventCounts | ForEach-Object { [math]::Pow($_ - $meanEventCount, 2) } | Measure-Object -Sum).Sum / ($eventCounts.Count - 1)
            $stdDevEventCount = [math]::Round([math]::Sqrt($variance), 2)
        }
        
        # Find most common error Event ID and Provider
        $allErrorEvents = $Results.LogAnalysis | ForEach-Object {
            $logName = $_.LogName
            $_.Events | Where-Object { $_.Level -eq 'Error' } | ForEach-Object {
                [PSCustomObject]@{
                    EventID = $_.EventID
                    Provider = $_.Source
                }
            }
        }
        
        $mostCommonErrorEventID = $null
        $mostCommonErrorProvider = $null
        
        if ($allErrorEvents.Count -gt 0) {
            $errorEventIDGroups = $allErrorEvents | Group-Object -Property EventID | Sort-Object Count -Descending
            if ($errorEventIDGroups.Count -gt 0) {
                $mostCommonErrorEventID = [PSCustomObject]@{
                    EventID = $errorEventIDGroups[0].Name
                    Count = $errorEventIDGroups[0].Count
                }
            }
            
            $errorProviderGroups = $allErrorEvents | Group-Object -Property Provider | Sort-Object Count -Descending
            if ($errorProviderGroups.Count -gt 0) {
                $mostCommonErrorProvider = [PSCustomObject]@{
                    Provider = $errorProviderGroups[0].Name
                    Count = $errorProviderGroups[0].Count
                }
            }
        }
        
        return [PSCustomObject]@{
            ErrorPercentage = $errorPercentage
            MeanEventCount = $meanEventCount
            StdDevEventCount = $stdDevEventCount
            MostCommonErrorEventID = $mostCommonErrorEventID
            MostCommonErrorProvider = $mostCommonErrorProvider
        }
    }
    catch {
        Write-Error "Failed to calculate statistics: $_"
        return $null
    }
}

<#
.SYNOPSIS
    Exports event log data to CLIXML format for future analysis.
    
.DESCRIPTION
    Exports full event objects to PowerShell CLIXML format, preserving
    all event properties for third-party analysis.
    
.PARAMETER Results
    Analysis results object.
    
.PARAMETER ExportPath
    Directory path for CLIXML archive.
    
.OUTPUTS
    Path to exported CLIXML file.
#>
function Export-EventLogClixml {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Results,
        
        [Parameter(Mandatory = $true)]
        [string]$ExportPath
    )
    
    try {
        $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
        
        # Ensure export path exists
        if (-not (Test-Path $ExportPath)) {
            $null = New-Item -ItemType Directory -Path $ExportPath -Force -ErrorAction Stop
        }
        
        $clixmlPath = Join-Path $ExportPath "EventLogAnalysis_Archive_$timestamp.clixml"
        
        # Create archive object with metadata and all events
        $archiveData = [PSCustomObject]@{
            ScriptVersion = $Results.ScriptVersion
            AnalysisDate = $Results.AnalysisDate
            StartTime = $Results.StartTime
            EndTime = $Results.EndTime
            LogsAnalyzed = $Results.LogsAnalyzed
            EntryTypes = $Results.EntryTypes
            AllEvents = $Results.LogAnalysis | ForEach-Object {
                $logName = $_.LogName
                $_.Events | ForEach-Object {
                    $_ | Add-Member -NotePropertyName 'LogName' -NotePropertyValue $logName -PassThru
                }
            }
            LogAnalysis = $Results.LogAnalysis
        }
        
        # Export to CLIXML
        $archiveData | Export-Clixml -Path $clixmlPath -Depth 10 -ErrorAction Stop
        
        Write-Verbose "Exported CLIXML archive to: $clixmlPath"
        return $clixmlPath
    }
    catch {
        Write-Error "Failed to export CLIXML: $_"
        throw
    }
}

<#
.SYNOPSIS
    Registers a scheduled task for automatic event log analysis.
    
.DESCRIPTION
    Creates a Windows scheduled task to run event log analysis automatically.
    
.PARAMETER TaskSchedule
    Schedule frequency: Daily, Weekly, or Hourly.
    
.PARAMETER TaskTime
    Time to run the task (HH:mm format).
#>
function Register-EventLogScheduledTask {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $false)]
        [ValidateSet('Daily', 'Weekly', 'Hourly')]
        [string]$TaskSchedule = 'Daily',
        
        [Parameter(Mandatory = $false)]
        [string]$TaskTime = '03:00'
    )
    
    try {
        $scriptPath = $PSCommandPath
        
        # Build argument string
        $arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`" -AutoRun -Hours 24 -ExportFormat All -Force"
        
        # Create scheduled task action
        $action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument $arguments -ErrorAction Stop
        
        # Create trigger based on schedule
        switch ($TaskSchedule) {
            'Daily' {
                $trigger = New-ScheduledTaskTrigger -Daily -At $TaskTime -ErrorAction Stop
            }
            'Weekly' {
                $trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Sunday -At $TaskTime -ErrorAction Stop
            }
            'Hourly' {
                $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Hours 1) -RepetitionDuration (New-TimeSpan -Days 365) -ErrorAction Stop
            }
        }
        
        # Create principal (run as SYSTEM with highest privileges)
        $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest -ErrorAction Stop
        
        # Create settings
        $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ErrorAction Stop
        
        # Register the task
        $taskName = "SouliTEK - Event Log Analyzer"
        
        if ($PSCmdlet.ShouldProcess($taskName, "Register scheduled task")) {
            Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Force -ErrorAction Stop | Out-Null
            
            Write-Host ""
            Write-Host "========================================" -ForegroundColor Green
            Write-Host "  SUCCESS!" -ForegroundColor Green
            Write-Host "========================================" -ForegroundColor Green
            Write-Host ""
            Write-Host "Scheduled task created successfully." -ForegroundColor White
            Write-Host "Task Name: $taskName" -ForegroundColor Gray
            Write-Host "Schedule: $TaskSchedule at $TaskTime" -ForegroundColor Gray
            Write-Host ""
            Write-Host "The event log analyzer will run automatically." -ForegroundColor White
            Write-Host "Reports will be saved to: $ExportPath" -ForegroundColor Gray
            Write-Host ""
            return $true
        }
        
        return $false
    }
    catch {
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Red
        Write-Host "  ERROR" -ForegroundColor Red
        Write-Host "========================================" -ForegroundColor Red
        Write-Host ""
        Write-Host "Failed to create scheduled task." -ForegroundColor Yellow
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host ""
        Write-Error "Failed to register scheduled task: $_"
        return $false
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
    
    # Display statistics if available
    if ($Results.Statistics) {
        $stats = $Results.Statistics
        Write-Host ""
        Write-Host "============================================================" -ForegroundColor Cyan
        Write-Host "  STATISTICAL ANALYSIS" -ForegroundColor Cyan
        Write-Host "============================================================" -ForegroundColor Cyan
        Write-Host "  Error Percentage: $($stats.ErrorPercentage)%" -ForegroundColor $(if ($stats.ErrorPercentage -gt 10) { 'Red' } elseif ($stats.ErrorPercentage -gt 5) { 'Yellow' } else { 'Green' })
        Write-Host "  Mean Event Count: $($stats.MeanEventCount)" -ForegroundColor White
        Write-Host "  Std Dev Event Count: $($stats.StdDevEventCount)" -ForegroundColor White
        
        if ($stats.MostCommonErrorEventID) {
            Write-Host "  Most Common Error Event ID: $($stats.MostCommonErrorEventID.EventID) ($($stats.MostCommonErrorEventID.Count) occurrences)" -ForegroundColor Yellow
        }
        
        if ($stats.MostCommonErrorProvider) {
            Write-Host "  Most Common Error Provider: $($stats.MostCommonErrorProvider.Provider) ($($stats.MostCommonErrorProvider.Count) occurrences)" -ForegroundColor Yellow
        }
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
        # Clean up old logs first (before starting transcript)
        Remove-OldLogs -RetentionDays $LogRetentionDays
        
        # Initialize transcript logging
        $null = Initialize-Transcript
        Write-Verbose "EventLogAnalyzer v$script:ScriptVersion started"
        Write-Verbose "Parameters: LogNames=$($LogNames -join ','), Hours=$Hours"
        
        # Determine time range
        if (-not $StartTime) {
            $StartTime = (Get-Date).AddHours(-$Hours)
        }
        
        Write-Verbose "Analysis period: $StartTime to $EndTime"
        
        # Build entry types array
        $entryTypes = @('Error')
        if ($IncludeWarnings) { $entryTypes += 'Warning' }
        if ($IncludeInformation) { $entryTypes += 'Information' }
        
        Write-Verbose "Entry types: $($entryTypes -join ', ')"
        
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
                Write-Verbose "Analysis cancelled by user (large query confirmation)"
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
        
        # Calculate statistics
        $statistics = Get-EventLogStatistics -Results $finalResults
        if ($statistics) {
            $finalResults | Add-Member -NotePropertyName 'Statistics' -NotePropertyValue $statistics -Force
        }
        
        # Save JSON summary
        if ($PSCmdlet.ShouldProcess($script:JsonSummaryFile, "Save JSON summary")) {
            try {
                $finalResults | ConvertTo-Json -Depth 10 -ErrorAction Stop | Set-Content -Path $script:JsonSummaryFile -Encoding UTF8 -ErrorAction Stop
                Write-Verbose "Saved JSON summary to: $script:JsonSummaryFile"
            }
            catch {
                Write-Error "Failed to save JSON summary: $_"
            }
        }
        
        # Display summary
        Show-AnalysisSummary -Results $finalResults
        
        # Comparison with baseline if specified
        if ($CompareWithBaseline -and (Test-Path $CompareWithBaseline)) {
            Write-Host "  [Comparing] With baseline: $CompareWithBaseline" -ForegroundColor Cyan
            try {
                $baseline = Get-Content $CompareWithBaseline -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
                $comparison = Compare-AnalysisResults -Current $finalResults -Baseline $baseline
                Show-ComparisonResults -Comparison $comparison
            }
            catch {
                Write-Warning "Failed to compare with baseline: $_"
            }
        }
        
        # Export results - prompt user unless AutoRun mode or ExportFormat explicitly provided
        if ($AutoRun -or $PSBoundParameters.ContainsKey('ExportFormat')) {
            # Automatic export for scheduled tasks or when format is explicitly specified
            Write-Host "  [Exporting] Results to $ExportPath..." -ForegroundColor Cyan
            $clixmlPath = if ($ClixmlArchivePath) { $ClixmlArchivePath } else { Join-Path $ExportPath "Archives" }
            $exportResult = Export-AnalysisResults -Results $finalResults -ExportPath $ExportPath -Format $ExportFormat -ExportIndividualLogs:$ExportIndividualLogs.IsPresent -ClixmlArchivePath $clixmlPath
            
            if ($exportResult.Success) {
                Write-Host ""
                Write-Host "  [SUCCESS] Analysis complete!" -ForegroundColor Green
                Write-Host "  Transcript: $script:TranscriptPath" -ForegroundColor Gray
                Write-Host ""
            }
        }
        else {
            # Interactive export menu - ask user which format to export
            $exportChoice = Show-ExportMenu
            if ($exportChoice -ne 'CANCEL') {
                Write-Host "  [Exporting] Results to $ExportPath..." -ForegroundColor Cyan
                $clixmlPath = if ($ClixmlArchivePath) { $ClixmlArchivePath } else { Join-Path $ExportPath "Archives" }
                $exportResult = Export-AnalysisResults -Results $finalResults -ExportPath $ExportPath -Format $exportChoice -ExportIndividualLogs:$ExportIndividualLogs.IsPresent -ClixmlArchivePath $clixmlPath
                
                if ($exportResult.Success) {
                    Write-Host ""
                    Write-Host "  [SUCCESS] Export complete!" -ForegroundColor Green
                    Write-Host "  Transcript: $script:TranscriptPath" -ForegroundColor Gray
                    Write-Host ""
                }
            }
            else {
                Write-Host ""
                Write-Host "  Export cancelled." -ForegroundColor Yellow
                Write-Host ""
            }
        }
        
        Write-Verbose "Analysis completed successfully"
        
        # Stop transcript
        try {
            Stop-Transcript -ErrorAction SilentlyContinue
        }
        catch {
            # Transcript may already be stopped, ignore
        }
        
        # Return results object for programmatic use
        return $finalResults
    }
    catch {
        Write-Error "Fatal error in main analysis: $_"
        Write-Host ""
        Write-Host "TROUBLESHOOTING:" -ForegroundColor Yellow
        Write-Host "  - Ensure you have Administrator privileges" -ForegroundColor Gray
        Write-Host "  - Verify event log names are correct" -ForegroundColor Gray
        Write-Host "  - Check available disk space in $env:TEMP" -ForegroundColor Gray
        if ($script:TranscriptPath) {
            Write-Host "  - Review transcript: $script:TranscriptPath" -ForegroundColor Gray
        }
        Write-Host ""
        
        # Stop transcript on error
        try {
            Stop-Transcript -ErrorAction SilentlyContinue
        }
        catch {
            # Ignore
        }
        
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
    Write-Host "  [12] Scheduled Task Setup              - Register automatic daily analysis" -ForegroundColor Cyan
    Write-Host "  [13] Help                              - Usage guide and examples" -ForegroundColor White
    Write-Host "  [0] Exit" -ForegroundColor Red
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    
    $choice = Read-Host "Enter your choice (0-13)"
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
    Clear-Host
    Show-ScriptBanner -ScriptName "Event Log Analyzer" -Purpose "Advanced Windows Event Log analysis tool for IT professionals"
    
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
            '12' { 
                Clear-Host
                Show-SouliTEKBanner
                Register-EventLogScheduledTask -TaskSchedule $TaskSchedule -TaskTime $TaskTime
            }
            '13' { Show-HelpMenu }
            '0' { 
                Write-Host ""
                Write-Host "Thank you for using SouliTEK EventLogAnalyzer!" -ForegroundColor Green
                Write-Host "Website: www.soulitek.co.il" -ForegroundColor Cyan
                Write-Host ""
                
                exit 0
            }
            default {
                Write-Host ""
                Write-Ui -Message "Invalid choice. Please select a number between 0-13" -Level "ERROR"
                Write-Host "Press any key to continue..." -ForegroundColor Yellow
                $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
            }
        }
        
        if ($choice -ne '0' -and $choice -ne '13') {
            Write-Host ""
            Write-Host "Press any key to return to main menu..." -ForegroundColor Yellow
            $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
        }
    } while ($true)
}

# ============================================================
# RUN MAIN ANALYSIS OR MENU
# ============================================================

# Handle scheduled task registration
if ($RegisterScheduledTask) {
    try {
        Register-EventLogScheduledTask -TaskSchedule $TaskSchedule -TaskTime $TaskTime
        exit 0
    }
    catch {
        Write-Error "Failed to register scheduled task: $_"
        exit 1
    }
}

# Check if script was called with explicit parameters (excluding common parameters like Verbose, Debug, etc.)
$explicitParams = @('LogNames', 'Hours', 'StartTime', 'EndTime', 'IncludeWarnings', 'IncludeInformation', 
                     'MaxEvents', 'ExportPath', 'ExportFormat', 'Force', 'RunExamples', 'EventIDs', 
                     'Sources', 'MessageFilter', 'IncludeAuditSuccess', 'IncludeAuditFailure', 
                     'IncludeCritical', 'CompareWithBaseline', 'ExportIndividualLogs', 'MachineName',
                     'AutoRun', 'ExportClixml', 'ClixmlArchivePath', 'LogRetentionDays')
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




