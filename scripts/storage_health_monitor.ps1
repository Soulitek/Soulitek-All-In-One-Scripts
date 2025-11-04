# ============================================================
# Storage Health Monitor - Professional Edition
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
# This tool monitors storage health by reading SMART data
# and warning about increasing reallocated sectors or read errors.
# 
# Features: SMART Data Reading | Reallocated Sectors Monitor
#           Read Error Detection | Health Status Reports | Export Results
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

# Requires elevation (Administrator)
#Requires -RunAsAdministrator

# Set window title
$Host.UI.RawUI.WindowTitle = "STORAGE HEALTH MONITOR"

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

$Script:ReportData = @()
$Script:Warnings = @()
$Script:OutputDir = "$env:USERPROFILE\Desktop"
$Script:BaselinePath = Join-Path $env:LOCALAPPDATA "SouliTEK\StorageHealthBaseline.json"

# ============================================================
# HELPER FUNCTIONS
# ============================================================

function Get-BaselineData {
    <#
    .SYNOPSIS
        Loads baseline SMART data from previous scan
    #>
    try {
        $baselineDir = Split-Path -Parent $Script:BaselinePath
        if (-not (Test-Path $baselineDir)) {
            New-Item -Path $baselineDir -ItemType Directory -Force | Out-Null
        }
        
        if (Test-Path $Script:BaselinePath) {
            $baselineJson = Get-Content -Path $Script:BaselinePath -Raw -ErrorAction SilentlyContinue
            if ($baselineJson) {
                $baseline = $baselineJson | ConvertFrom-Json
                return $baseline
            }
        }
    }
    catch {
        Write-Verbose "Could not load baseline: $_"
    }
    
    return @{}
}

function Save-BaselineData {
    <#
    .SYNOPSIS
        Saves current SMART data as baseline for future comparison
    #>
    param(
        [array]$CurrentData
    )
    
    try {
        $baselineDir = Split-Path -Parent $Script:BaselinePath
        if (-not (Test-Path $baselineDir)) {
            New-Item -Path $baselineDir -ItemType Directory -Force | Out-Null
        }
        
        $baseline = @{}
        foreach ($disk in $CurrentData) {
            $baseline[$disk.DiskNumber] = @{
                FriendlyName = $disk.FriendlyName
                ReallocatedSectors = $disk.ReallocatedSectors
                ReadErrors = $disk.ReadErrors
                Timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
            }
        }
        
        $baselineJson = $baseline | ConvertTo-Json -Depth 10
        $baselineJson | Out-File -FilePath $Script:BaselinePath -Encoding UTF8 -Force
    }
    catch {
        Write-Verbose "Could not save baseline: $_"
    }
}

function Get-SMARTData {
    param(
        [Microsoft.Management.Infrastructure.CimInstance]$PhysicalDisk,
        [hashtable]$Baseline
    )
    
    $diskNumber = $PhysicalDisk.DeviceID
    $smartData = @{
        DiskNumber = $diskNumber
        FriendlyName = $PhysicalDisk.FriendlyName
        MediaType = $PhysicalDisk.MediaType
        Size = $PhysicalDisk.Size
        HealthStatus = $PhysicalDisk.HealthStatus
        OperationalStatus = $PhysicalDisk.OperationalStatus
        ReallocatedSectors = $null
        ReadErrors = $null
        Temperature = $null
        PowerOnHours = $null
        PowerCycles = $null
        Wear = $null
        Status = "Unknown"
        WarningLevel = "OK"
        ReallocatedSectorsTrend = "N/A"
        ReadErrorsTrend = "N/A"
        PreviousReallocatedSectors = $null
        PreviousReadErrors = $null
        BaselineDate = $null
    }
    
    # Load baseline data for this disk
    if ($Baseline -and $Baseline.ContainsKey($diskNumber)) {
        $baselineDisk = $Baseline[$diskNumber]
        $smartData.PreviousReallocatedSectors = $baselineDisk.ReallocatedSectors
        $smartData.PreviousReadErrors = $baselineDisk.ReadErrors
        $smartData.BaselineDate = $baselineDisk.Timestamp
    }
    
    # Try to get SMART attributes via WMI
    try {
        $smartInfo = Get-WmiObject -Namespace "root\wmi" -Class "MSStorageDriver_FailurePredictStatus" -ErrorAction SilentlyContinue |
            Where-Object { $_.InstanceName -like "*PHYSICALDRIVE$diskNumber*" }
        
        if ($smartInfo) {
            $smartData.Status = if ($smartInfo.PredictFailure -eq $false) { "OK" } else { "Failure Predicted" }
            if ($smartData.Status -eq "Failure Predicted") {
                $smartData.WarningLevel = "CRITICAL"
            }
        }
    }
    catch {
        Write-Verbose "Could not read SMART status via WMI: $_"
    }
    
    # Try to get SMART attributes via Get-StorageReliabilityCounter
    try {
        if ($PhysicalDisk.FriendlyName) {
            $reliabilityCounters = Get-StorageReliabilityCounter -PhysicalDisk (Get-PhysicalDisk -DeviceNumber $diskNumber -ErrorAction SilentlyContinue) -ErrorAction SilentlyContinue
            
            if ($reliabilityCounters) {
                # Reallocated sectors count
                if ($reliabilityCounters.ReallocateCount) {
                    $smartData.ReallocatedSectors = $reliabilityCounters.ReallocateCount
                }
                
                # Read errors
                if ($reliabilityCounters.ReadErrorsTotal) {
                    $smartData.ReadErrors = $reliabilityCounters.ReadErrorsTotal
                }
                
                # Temperature (if available)
                if ($reliabilityCounters.Temperature) {
                    $smartData.Temperature = $reliabilityCounters.Temperature
                }
                
                # Power-on hours (if available)
                if ($reliabilityCounters.PowerOnHours) {
                    $smartData.PowerOnHours = $reliabilityCounters.PowerOnHours
                }
                
                # Power cycles (if available)
                if ($reliabilityCounters.PowerCycles) {
                    $smartData.PowerCycles = $reliabilityCounters.PowerCycles
                }
                
                # Wear (for SSDs, if available)
                if ($reliabilityCounters.Wear) {
                    $smartData.Wear = $reliabilityCounters.Wear
                }
            }
        }
    }
    catch {
        Write-Verbose "Could not read StorageReliabilityCounter: $_"
    }
    
    # Check health status and determine warning level
    if ($PhysicalDisk.HealthStatus -eq "Unhealthy") {
        $smartData.WarningLevel = "CRITICAL"
    }
    elseif ($PhysicalDisk.HealthStatus -eq "Warning") {
        $smartData.WarningLevel = "WARNING"
    }
    
    # Analyze reallocated sectors trend
    if ($smartData.ReallocatedSectors -ne $null) {
        # Check for increasing reallocated sectors
        if ($smartData.PreviousReallocatedSectors -ne $null) {
            $increase = $smartData.ReallocatedSectors - $smartData.PreviousReallocatedSectors
            if ($increase -gt 0) {
                $smartData.ReallocatedSectorsTrend = "INCREASING (+$increase)"
                # Warn if increasing, even if still low
                if ($increase -ge 5) {
                    $smartData.WarningLevel = if ($smartData.WarningLevel -eq "CRITICAL") { "CRITICAL" } else { "WARNING" }
                    $Script:Warnings += "WARNING: Disk $diskNumber reallocated sectors INCREASING: $($smartData.PreviousReallocatedSectors) -> $($smartData.ReallocatedSectors) (+$increase sectors) - Monitor closely!"
                }
                elseif ($increase -gt 0) {
                    $Script:Warnings += "INFO: Disk $diskNumber reallocated sectors increased: $($smartData.PreviousReallocatedSectors) -> $($smartData.ReallocatedSectors) (+$increase sectors)"
                }
            }
            elseif ($increase -eq 0) {
                $smartData.ReallocatedSectorsTrend = "STABLE"
            }
            else {
                $smartData.ReallocatedSectorsTrend = "DECREASING ($increase)"
            }
        }
        
        # Check absolute thresholds
        if ($smartData.ReallocatedSectors -gt 100) {
            $smartData.WarningLevel = "CRITICAL"
            $Script:Warnings += "CRITICAL: Disk $diskNumber has $($smartData.ReallocatedSectors) reallocated sectors - Immediate attention required!"
        }
        elseif ($smartData.ReallocatedSectors -gt 10) {
            if ($smartData.WarningLevel -eq "OK") {
                $smartData.WarningLevel = "WARNING"
            }
            $Script:Warnings += "WARNING: Disk $diskNumber has $($smartData.ReallocatedSectors) reallocated sectors - Monitor closely"
        }
    }
    
    # Analyze read errors trend
    if ($smartData.ReadErrors -ne $null -and $smartData.ReadErrors -ge 0) {
        # Check for increasing read errors
        if ($smartData.PreviousReadErrors -ne $null) {
            $increase = $smartData.ReadErrors - $smartData.PreviousReadErrors
            if ($increase -gt 0) {
                $smartData.ReadErrorsTrend = "INCREASING (+$increase)"
                # Warn if increasing, even if still low
                if ($increase -ge 5) {
                    $smartData.WarningLevel = if ($smartData.WarningLevel -eq "CRITICAL") { "CRITICAL" } else { "WARNING" }
                    $Script:Warnings += "WARNING: Disk $diskNumber read errors INCREASING: $($smartData.PreviousReadErrors) -> $($smartData.ReadErrors) (+$increase errors) - Monitor closely!"
                }
                elseif ($increase -gt 0) {
                    $Script:Warnings += "INFO: Disk $diskNumber read errors increased: $($smartData.PreviousReadErrors) -> $($smartData.ReadErrors) (+$increase errors)"
                }
            }
            elseif ($increase -eq 0) {
                $smartData.ReadErrorsTrend = "STABLE"
            }
            else {
                $smartData.ReadErrorsTrend = "DECREASING ($increase)"
            }
        }
        
        # Check absolute thresholds
        if ($smartData.ReadErrors -gt 100) {
            $smartData.WarningLevel = "CRITICAL"
            $Script:Warnings += "CRITICAL: Disk $diskNumber has $($smartData.ReadErrors) read errors - Immediate attention required!"
        }
        elseif ($smartData.ReadErrors -gt 10) {
            if ($smartData.WarningLevel -eq "OK") {
                $smartData.WarningLevel = "WARNING"
            }
            $Script:Warnings += "WARNING: Disk $diskNumber has $($smartData.ReadErrors) read errors - Monitor closely"
        }
    }
    
    return $smartData
}

function Show-StorageHealthReport {
    Clear-Host
    
    Write-Host ""
    Show-SouliTEKBanner
    Write-Host ""
    
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host "  STORAGE HEALTH MONITOR REPORT" -ForegroundColor Cyan
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host ""
    
    # Get all physical disks
    try {
        $physicalDisks = Get-PhysicalDisk | Where-Object { $_.BusType -ne "USB" -or $_.BusType -ne "Unknown" }
    }
    catch {
        Write-Host "Error accessing physical disks: $_" -ForegroundColor Red
        Write-Host "Press Enter to return to menu..."
        Read-Host
        return
    }
    
    if (-not $physicalDisks) {
        Write-Host "No physical disks found." -ForegroundColor Yellow
        Write-Host "Press Enter to return to menu..."
        Read-Host
        return
    }
    
    $Script:ReportData = @()
    $Script:Warnings = @()
    
    # Load baseline for comparison
    $baseline = Get-BaselineData
    if ($baseline.Count -gt 0) {
        Write-Host "Baseline data loaded from previous scan" -ForegroundColor Green
        Write-Host "Comparing current values with baseline to detect trends..." -ForegroundColor Gray
        Write-Host ""
    }
    else {
        Write-Host "No baseline data found. This scan will establish baseline." -ForegroundColor Yellow
        Write-Host ""
    }
    
    Write-Host "Scanning storage devices..." -ForegroundColor Yellow
    Write-Host ""
    
    foreach ($disk in $physicalDisks) {
        Write-Host "Analyzing disk: $($disk.FriendlyName)..." -ForegroundColor Cyan
        
        $smartData = Get-SMARTData -PhysicalDisk $disk -Baseline $baseline
        $Script:ReportData += $smartData
        
        # Display disk information
        Write-Host "  Device ID: $($smartData.DiskNumber)" -ForegroundColor White
        Write-Host "  Media Type: $($smartData.MediaType)" -ForegroundColor White
        Write-Host "  Size: $([math]::Round($smartData.Size / 1GB, 2)) GB" -ForegroundColor White
        Write-Host "  Health Status: " -NoNewline
        
        switch ($smartData.WarningLevel) {
            "CRITICAL" {
                Write-Host $smartData.HealthStatus -ForegroundColor Red
            }
            "WARNING" {
                Write-Host $smartData.HealthStatus -ForegroundColor Yellow
            }
            default {
                Write-Host $smartData.HealthStatus -ForegroundColor Green
            }
        }
        
        Write-Host "  Operational Status: $($smartData.OperationalStatus)" -ForegroundColor White
        
        if ($smartData.ReallocatedSectors -ne $null) {
            $color = if ($smartData.ReallocatedSectors -gt 100) { "Red" } elseif ($smartData.ReallocatedSectors -gt 10) { "Yellow" } else { "Green" }
            Write-Host "  Reallocated Sectors: " -NoNewline -ForegroundColor White
            Write-Host "$($smartData.ReallocatedSectors)" -ForegroundColor $color -NoNewline
            if ($smartData.ReallocatedSectorsTrend -ne "N/A") {
                $trendColor = if ($smartData.ReallocatedSectorsTrend -like "INCREASING*") { "Red" } elseif ($smartData.ReallocatedSectorsTrend -eq "STABLE") { "Green" } else { "Yellow" }
                Write-Host " [$($smartData.ReallocatedSectorsTrend)]" -ForegroundColor $trendColor
            } else {
                Write-Host ""
            }
            if ($smartData.PreviousReallocatedSectors -ne $null) {
                Write-Host "    Previous: $($smartData.PreviousReallocatedSectors) (Baseline: $($smartData.BaselineDate))" -ForegroundColor Gray
            }
        } else {
            Write-Host "  Reallocated Sectors: Not available" -ForegroundColor Gray
        }
        
        if ($smartData.ReadErrors -ne $null) {
            $color = if ($smartData.ReadErrors -gt 100) { "Red" } elseif ($smartData.ReadErrors -gt 10) { "Yellow" } else { "Green" }
            Write-Host "  Read Errors: " -NoNewline -ForegroundColor White
            Write-Host "$($smartData.ReadErrors)" -ForegroundColor $color -NoNewline
            if ($smartData.ReadErrorsTrend -ne "N/A") {
                $trendColor = if ($smartData.ReadErrorsTrend -like "INCREASING*") { "Red" } elseif ($smartData.ReadErrorsTrend -eq "STABLE") { "Green" } else { "Yellow" }
                Write-Host " [$($smartData.ReadErrorsTrend)]" -ForegroundColor $trendColor
            } else {
                Write-Host ""
            }
            if ($smartData.PreviousReadErrors -ne $null) {
                Write-Host "    Previous: $($smartData.PreviousReadErrors) (Baseline: $($smartData.BaselineDate))" -ForegroundColor Gray
            }
        } else {
            Write-Host "  Read Errors: Not available" -ForegroundColor Gray
        }
        
        if ($smartData.Temperature -ne $null) {
            Write-Host "  Temperature: $($smartData.Temperature)C" -ForegroundColor White
        }
        
        if ($smartData.PowerOnHours -ne $null) {
            $hours = [math]::Round($smartData.PowerOnHours / 24, 1)
            Write-Host "  Power-On Hours: $($smartData.PowerOnHours) ($hours days)" -ForegroundColor White
        }
        
        if ($smartData.PowerCycles -ne $null) {
            Write-Host "  Power Cycles: $($smartData.PowerCycles)" -ForegroundColor White
        }
        
        if ($smartData.Wear -ne $null) {
            Write-Host "  Wear Level: $($smartData.Wear)%" -ForegroundColor White
        }
        
        Write-Host ""
    }
    
    # Display warnings
    if ($Script:Warnings.Count -gt 0) {
        Write-Host "==========================================" -ForegroundColor Red
        Write-Host "  WARNINGS AND ALERTS" -ForegroundColor Red
        Write-Host "==========================================" -ForegroundColor Red
        Write-Host ""
        
        foreach ($warning in $Script:Warnings) {
            if ($warning -like "CRITICAL:*") {
                Write-Host $warning -ForegroundColor Red
            } else {
                Write-Host $warning -ForegroundColor Yellow
            }
        }
        Write-Host ""
    } else {
        Write-Host "==========================================" -ForegroundColor Green
        Write-Host "  NO ISSUES DETECTED" -ForegroundColor Green
        Write-Host "==========================================" -ForegroundColor Green
        Write-Host ""
    }
    
    # Save current scan as new baseline
    if ($Script:ReportData.Count -gt 0) {
        Save-BaselineData -CurrentData $Script:ReportData
        Write-Host "Baseline data updated for future comparisons" -ForegroundColor Green
        Write-Host ""
    }
    
    Write-Host "Press Enter to continue..."
    Read-Host
}

function Export-HealthReport {
    param(
        [string]$Format = "TXT"
    )
    
    if ($Script:ReportData.Count -eq 0) {
        Write-Host "No data to export. Please run 'View Storage Health Report' first." -ForegroundColor Yellow
        Write-Host "Press Enter to continue..."
        Read-Host
        return
    }
    
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $outputPath = ""
    
    switch ($Format.ToUpper()) {
        "TXT" {
            $outputPath = Join-Path $Script:OutputDir "StorageHealthReport_$timestamp.txt"
            
            $report = @"
==========================================
STORAGE HEALTH MONITOR REPORT
Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
==========================================

"@
            
            foreach ($disk in $Script:ReportData) {
                $report += @"

Disk: $($disk.FriendlyName)
Device ID: $($disk.DiskNumber)
Media Type: $($disk.MediaType)
Size: $([math]::Round($disk.Size / 1GB, 2)) GB
Health Status: $($disk.HealthStatus)
Operational Status: $($disk.OperationalStatus)
Warning Level: $($disk.WarningLevel)
"@
                
                if ($disk.ReallocatedSectors -ne $null) {
                    $report += "Reallocated Sectors: $($disk.ReallocatedSectors)`n"
                }
                
                if ($disk.ReadErrors -ne $null) {
                    $report += "Read Errors: $($disk.ReadErrors)`n"
                }
                
                if ($disk.Temperature -ne $null) {
                    $report += "Temperature: $($disk.Temperature)C`n"
                }
                
                if ($disk.PowerOnHours -ne $null) {
                    $hours = [math]::Round($disk.PowerOnHours / 24, 1)
                    $report += "Power-On Hours: $($disk.PowerOnHours) ($hours days)`n"
                }
                
                if ($disk.PowerCycles -ne $null) {
                    $report += "Power Cycles: $($disk.PowerCycles)`n"
                }
                
                if ($disk.Wear -ne $null) {
                    $report += "Wear Level: $($disk.Wear)%`n"
                }
                
                $report += "`n"
            }
            
            if ($Script:Warnings.Count -gt 0) {
                $report += @"

==========================================
WARNINGS AND ALERTS
==========================================

"@
                foreach ($warning in $Script:Warnings) {
                    $report += "$warning`n"
                }
            }
            
            $report | Out-File -FilePath $outputPath -Encoding UTF8
        }
        
        "CSV" {
            $outputPath = Join-Path $Script:OutputDir "StorageHealthReport_$timestamp.csv"
            
            $csvData = $Script:ReportData | ForEach-Object {
                [PSCustomObject]@{
                    DeviceID = $_.DiskNumber
                    FriendlyName = $_.FriendlyName
                    MediaType = $_.MediaType
                    SizeGB = [math]::Round($_.Size / 1GB, 2)
                    HealthStatus = $_.HealthStatus
                    OperationalStatus = $_.OperationalStatus
                    WarningLevel = $_.WarningLevel
                    ReallocatedSectors = $_.ReallocatedSectors
                    ReadErrors = $_.ReadErrors
                    Temperature = $_.Temperature
                    PowerOnHours = $_.PowerOnHours
                    PowerCycles = $_.PowerCycles
                    Wear = $_.Wear
                }
            }
            
            $csvData | Export-Csv -Path $outputPath -NoTypeInformation -Encoding UTF8
        }
        
        "HTML" {
            $outputPath = Join-Path $Script:OutputDir "StorageHealthReport_$timestamp.html"
            
            $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Storage Health Monitor Report</title>
    <style>
        body { font-family: 'Segoe UI', Arial, sans-serif; margin: 20px; background: #f5f5f5; }
        .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; border-radius: 10px; margin-bottom: 20px; }
        .header h1 { margin: 0; font-size: 28px; }
        .header p { margin: 5px 0 0 0; opacity: 0.9; }
        .disk-card { background: white; padding: 20px; margin-bottom: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .disk-card h2 { margin-top: 0; color: #333; }
        .info-grid { display: grid; grid-template-columns: repeat(2, 1fr); gap: 15px; margin-top: 15px; }
        .info-item { padding: 10px; background: #f8f9fa; border-radius: 5px; }
        .info-label { font-weight: bold; color: #666; font-size: 12px; text-transform: uppercase; }
        .info-value { font-size: 16px; color: #333; margin-top: 5px; }
        .status-ok { color: #10b981; font-weight: bold; }
        .status-warning { color: #f59e0b; font-weight: bold; }
        .status-critical { color: #dc2626; font-weight: bold; }
        .warnings { background: #fee; border-left: 4px solid #dc2626; padding: 20px; margin-top: 20px; border-radius: 5px; }
        .warning-item { padding: 10px; margin: 5px 0; background: white; border-radius: 5px; }
        .warning-critical { border-left: 4px solid #dc2626; }
        .warning-normal { border-left: 4px solid #f59e0b; }
        .footer { text-align: center; margin-top: 30px; color: #666; font-size: 12px; }
    </style>
</head>
<body>
    <div class="header">
        <h1>Storage Health Monitor Report</h1>
        <p>Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>
    </div>
"@
            
            foreach ($disk in $Script:ReportData) {
                $statusClass = switch ($disk.WarningLevel) {
                    "CRITICAL" { "status-critical" }
                    "WARNING" { "status-warning" }
                    default { "status-ok" }
                }
                
                $html += @"
    <div class="disk-card">
        <h2>$($disk.FriendlyName)</h2>
        <div class="info-grid">
            <div class="info-item">
                <div class="info-label">Device ID</div>
                <div class="info-value">$($disk.DiskNumber)</div>
            </div>
            <div class="info-item">
                <div class="info-label">Media Type</div>
                <div class="info-value">$($disk.MediaType)</div>
            </div>
            <div class="info-item">
                <div class="info-label">Size</div>
                <div class="info-value">$([math]::Round($disk.Size / 1GB, 2)) GB</div>
            </div>
            <div class="info-item">
                <div class="info-label">Health Status</div>
                <div class="info-value $statusClass">$($disk.HealthStatus)</div>
            </div>
            <div class="info-item">
                <div class="info-label">Operational Status</div>
                <div class="info-value">$($disk.OperationalStatus)</div>
            </div>
            <div class="info-item">
                <div class="info-label">Warning Level</div>
                <div class="info-value $statusClass">$($disk.WarningLevel)</div>
            </div>
"@
                
                if ($disk.ReallocatedSectors -ne $null) {
                    $html += @"
            <div class="info-item">
                <div class="info-label">Reallocated Sectors</div>
                <div class="info-value">$($disk.ReallocatedSectors)</div>
            </div>
"@
                }
                
                if ($disk.ReadErrors -ne $null) {
                    $html += @"
            <div class="info-item">
                <div class="info-label">Read Errors</div>
                <div class="info-value">$($disk.ReadErrors)</div>
            </div>
"@
                }
                
                if ($disk.Temperature -ne $null) {
                    $html += @"
            <div class="info-item">
                <div class="info-label">Temperature</div>
                <div class="info-value">$($disk.Temperature)C</div>
            </div>
"@
                }
                
                if ($disk.PowerOnHours -ne $null) {
                    $hours = [math]::Round($disk.PowerOnHours / 24, 1)
                    $html += @"
            <div class="info-item">
                <div class="info-label">Power-On Hours</div>
                <div class="info-value">$($disk.PowerOnHours) ($hours days)</div>
            </div>
"@
                }
                
                if ($disk.PowerCycles -ne $null) {
                    $html += @"
            <div class="info-item">
                <div class="info-label">Power Cycles</div>
                <div class="info-value">$($disk.PowerCycles)</div>
            </div>
"@
                }
                
                if ($disk.Wear -ne $null) {
                    $html += @"
            <div class="info-item">
                <div class="info-label">Wear Level</div>
                <div class="info-value">$($disk.Wear)%</div>
            </div>
"@
                }
                
                $html += @"
        </div>
    </div>
"@
            }
            
            if ($Script:Warnings.Count -gt 0) {
                $html += @"
    <div class="warnings">
        <h2 style="color: #dc2626; margin-top: 0;">Warnings and Alerts</h2>
"@
                foreach ($warning in $Script:Warnings) {
                    $warningClass = if ($warning -like "CRITICAL:*") { "warning-critical" } else { "warning-normal" }
                    $html += @"
        <div class="warning-item $warningClass">
            $($warning -replace "CRITICAL:", "<strong>CRITICAL:</strong>" -replace "WARNING:", "<strong>WARNING:</strong>")
        </div>
"@
                }
                $html += @"
    </div>
"@
            }
            
            $html += @"
    <div class="footer">
        <p>Report generated by SouliTEK Storage Health Monitor</p>
        <p>www.soulitek.co.il | letstalk@soulitek.co.il</p>
    </div>
</body>
</html>
"@
            
            $html | Out-File -FilePath $outputPath -Encoding UTF8
        }
    }
    
    if ($outputPath) {
        Write-Host ""
        Write-Host "Report exported successfully!" -ForegroundColor Green
        Write-Host "Location: $outputPath" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Press Enter to continue..."
        Read-Host
    }
}

function Show-MainMenu {
    Clear-Host
    
    Write-Host ""
    Show-SouliTEKBanner
    Write-Host ""
    
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host "  STORAGE HEALTH MONITOR" -ForegroundColor Cyan
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Monitor storage device health by reading SMART data" -ForegroundColor White
    Write-Host "and detecting reallocated sectors or read errors." -ForegroundColor White
    Write-Host ""
    Write-Host "Main Menu:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  1. View Storage Health Report" -ForegroundColor Cyan
    Write-Host "  2. Export Report - TXT Format" -ForegroundColor Cyan
    Write-Host "  3. Export Report - CSV Format" -ForegroundColor Cyan
    Write-Host "  4. Export Report - HTML Format" -ForegroundColor Cyan
    Write-Host "  5. Export Report - All Formats" -ForegroundColor Cyan
    Write-Host "  6. Help & Information" -ForegroundColor Cyan
    Write-Host "  7. Exit" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Select an option (1-7): " -NoNewline -ForegroundColor Yellow
}

# ============================================================
# EXIT MESSAGE
# ============================================================

function Show-ExitMessage {
    Clear-Host
    Write-Host ""
    Write-Host "Thank you for using SouliTEK Storage Health Monitor!" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Website: www.soulitek.co.il" -ForegroundColor Yellow
    Write-Host ""
}

function Show-Help {
    Clear-Host
    
    Write-Host ""
    Show-SouliTEKBanner
    Write-Host ""
    
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host "  HELP & INFORMATION" -ForegroundColor Cyan
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "STORAGE HEALTH MONITOR" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "This tool monitors the health of your storage devices by:" -ForegroundColor White
    Write-Host "  - Reading SMART (Self-Monitoring, Analysis and Reporting Technology) data" -ForegroundColor Gray
    Write-Host "  - Detecting reallocated sectors (bad sectors that have been replaced)" -ForegroundColor Gray
    Write-Host "  - Monitoring read errors (data read failures)" -ForegroundColor Gray
    Write-Host "  - Warning when these metrics indicate potential disk failure" -ForegroundColor Gray
    Write-Host ""
    Write-Host "WARNING THRESHOLDS:" -ForegroundColor Yellow
    Write-Host "  - Reallocated Sectors:" -ForegroundColor White
    Write-Host "    * > 100 sectors: CRITICAL - Immediate attention required" -ForegroundColor Red
    Write-Host "    * > 10 sectors: WARNING - Monitor closely" -ForegroundColor Yellow
    Write-Host "    * Increasing by 5+ sectors: WARNING - Values increasing!" -ForegroundColor Yellow
    Write-Host "    * <= 10 sectors: OK" -ForegroundColor Green
    Write-Host ""
    Write-Host "  - Read Errors:" -ForegroundColor White
    Write-Host "    * > 100 errors: CRITICAL - Immediate attention required" -ForegroundColor Red
    Write-Host "    * > 10 errors: WARNING - Monitor closely" -ForegroundColor Yellow
    Write-Host "    * Increasing by 5+ errors: WARNING - Values increasing!" -ForegroundColor Yellow
    Write-Host "    * <= 10 errors: OK" -ForegroundColor Green
    Write-Host ""
    Write-Host "TREND MONITORING:" -ForegroundColor Yellow
    Write-Host "  - The tool compares current values with previous baseline" -ForegroundColor White
    Write-Host "  - Warns if reallocated sectors or read errors are INCREASING" -ForegroundColor White
    Write-Host "  - Baseline is automatically updated after each scan" -ForegroundColor White
    Write-Host "  - First scan establishes baseline, subsequent scans compare trends" -ForegroundColor White
    Write-Host ""
    Write-Host "FEATURES:" -ForegroundColor Yellow
    Write-Host "  - SMART data reading via Get-PhysicalDisk and StorageReliabilityCounter" -ForegroundColor White
    Write-Host "  - Automatic health status detection" -ForegroundColor White
    Write-Host "  - Detailed disk information (temperature, power-on hours, wear level)" -ForegroundColor White
    Write-Host "  - Multiple export formats (TXT, CSV, HTML)" -ForegroundColor White
    Write-Host ""
    Write-Host "REQUIREMENTS:" -ForegroundColor Yellow
    Write-Host "  - Windows PowerShell 5.1 or later" -ForegroundColor White
    Write-Host "  - Administrator privileges (recommended)" -ForegroundColor White
    Write-Host "  - Storage devices that support SMART" -ForegroundColor White
    Write-Host ""
    Write-Host "NOTES:" -ForegroundColor Yellow
    Write-Host "  - Not all storage devices expose SMART data via Windows APIs" -ForegroundColor White
    Write-Host "  - Some metrics may show 'Not available' for certain disk types" -ForegroundColor White
    Write-Host "  - USB and external drives may have limited SMART data" -ForegroundColor White
    Write-Host ""
    Write-Host "SUPPORT:" -ForegroundColor Yellow
    Write-Host "  Website: www.soulitek.co.il" -ForegroundColor Cyan
    Write-Host "  Email: letstalk@soulitek.co.il" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Press Enter to return to main menu..." -ForegroundColor Yellow
    Read-Host
}

# ============================================================
# MAIN EXECUTION
# ============================================================

# Check for administrator privileges
if (-not (Test-SouliTEKAdministrator)) {
    Write-Host "WARNING: This tool requires Administrator privileges for full functionality." -ForegroundColor Yellow
    Write-Host "Some SMART data may not be accessible without elevation." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Press Enter to continue anyway, or Ctrl+C to exit..." -ForegroundColor Yellow
    Read-Host
}

# Main loop
do {
    Show-MainMenu
    $choice = Read-Host
    
    switch ($choice) {
        "1" {
            Show-StorageHealthReport
        }
        "2" {
            Export-HealthReport -Format "TXT"
        }
        "3" {
            Export-HealthReport -Format "CSV"
        }
        "4" {
            Export-HealthReport -Format "HTML"
        }
        "5" {
            Export-HealthReport -Format "TXT"
            Export-HealthReport -Format "CSV"
            Export-HealthReport -Format "HTML"
        }
        "6" {
            Show-Help
        }
        "7" {
            Show-ExitMessage
            break
        }
        default {
            Write-Host ""
            Write-Host "Invalid option. Please select 1-7." -ForegroundColor Red
            Start-Sleep -Seconds 2
        }
    }
} while ($true)

