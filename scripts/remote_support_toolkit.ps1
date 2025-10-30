# ============================================================
# Remote Support Toolkit - Professional Edition
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
# This tool collects comprehensive system information for
# remote support and troubleshooting purposes.
# 
# Features: System Info | Software List | Process Monitor
#           Network Config | Error Reports | Support Package
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
$Host.UI.RawUI.WindowTitle = "REMOTE SUPPORT TOOLKIT"

# Import SouliTEK Common Functions
$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$CommonPath = Join-Path (Split-Path -Parent $ScriptRoot) "modules\SouliTEK-Common.ps1"
if (Test-Path $CommonPath) {
    Import-Module $CommonPath -Force
} else {
    Write-Warning "SouliTEK Common Functions not found at: $CommonPath"
    Write-Warning "Some functions may not work properly."
}

# ============================================================
# GLOBAL VARIABLES
# ============================================================

$Script:OutputFolder = Join-Path $env:USERPROFILE "Desktop\SupportPackage_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
$Script:LogFile = $null

# ============================================================
# HELPER FUNCTIONS
# ============================================================



function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    if ($Script:LogFile) {
        Add-Content -Path $Script:LogFile -Value $logEntry -Encoding UTF8
    }
    
    switch ($Level) {
        "ERROR" { Write-Host $logEntry -ForegroundColor Red }
        "WARNING" { Write-Host $logEntry -ForegroundColor Yellow }
        "SUCCESS" { Write-Host $logEntry -ForegroundColor Green }
        default { Write-Host $logEntry -ForegroundColor Gray }
    }
}



function Show-Header {
    param([string]$Title, [ConsoleColor]$Color = 'Cyan')
    
    Clear-Host
    Show-SouliTEKBanner
    Write-Host "============================================================" -ForegroundColor $Color
    Write-Host ""
    Write-Host "  $Title" -ForegroundColor $Color
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor $Color
    Write-Host ""
}

# ============================================================
# DATA COLLECTION FUNCTIONS
# ============================================================

function Get-SystemInformation {
    Write-Log "Collecting system information..." -Level INFO
    
    try {
        $os = Get-CimInstance Win32_OperatingSystem
        $cs = Get-CimInstance Win32_ComputerSystem
        $bios = Get-CimInstance Win32_BIOS
        $cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
        
        $uptime = (Get-Date) - $os.LastBootUpTime
        
        $systemInfo = [PSCustomObject]@{
            ComputerName = $env:COMPUTERNAME
            UserName = $env:USERNAME
            Manufacturer = $cs.Manufacturer
            Model = $cs.Model
            SerialNumber = $bios.SerialNumber
            OSName = $os.Caption
            OSVersion = $os.Version
            OSBuild = $os.BuildNumber
            OSArchitecture = $os.OSArchitecture
            InstallDate = $os.InstallDate
            LastBootTime = $os.LastBootUpTime
            Uptime = "$($uptime.Days) days, $($uptime.Hours) hours, $($uptime.Minutes) minutes"
            TotalMemoryGB = [math]::Round($cs.TotalPhysicalMemory / 1GB, 2)
            CPUName = $cpu.Name
            CPUCores = $cpu.NumberOfCores
            CPULogicalProcessors = $cpu.NumberOfLogicalProcessors
            Domain = $cs.Domain
            Workgroup = $cs.Workgroup
            TimeZone = (Get-TimeZone).DisplayName
            CollectionTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }
        
        Write-Log "System information collected successfully" -Level SUCCESS
        return $systemInfo
    }
    catch {
        Write-Log "Failed to collect system information: $_" -Level ERROR
        return $null
    }
}

function Get-DiskInformation {
    Write-Log "Collecting disk information..." -Level INFO
    
    try {
        $disks = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" | ForEach-Object {
            [PSCustomObject]@{
                Drive = $_.DeviceID
                Label = $_.VolumeName
                FileSystem = $_.FileSystem
                SizeGB = [math]::Round($_.Size / 1GB, 2)
                FreeGB = [math]::Round($_.FreeSpace / 1GB, 2)
                UsedGB = [math]::Round(($_.Size - $_.FreeSpace) / 1GB, 2)
                PercentFree = [math]::Round(($_.FreeSpace / $_.Size) * 100, 2)
            }
        }
        
        Write-Log "Disk information collected successfully" -Level SUCCESS
        return $disks
    }
    catch {
        Write-Log "Failed to collect disk information: $_" -Level ERROR
        return $null
    }
}

function Get-InstalledSoftware {
    Write-Log "Collecting installed software..." -Level INFO
    
    try {
        $software = @()
        
        # 64-bit software
        $software += Get-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*" -ErrorAction SilentlyContinue |
            Where-Object { $_.DisplayName } |
            Select-Object DisplayName, DisplayVersion, Publisher, InstallDate
        
        # 32-bit software on 64-bit system
        if (Test-Path "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall") {
            $software += Get-ItemProperty "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" -ErrorAction SilentlyContinue |
                Where-Object { $_.DisplayName } |
                Select-Object DisplayName, DisplayVersion, Publisher, InstallDate
        }
        
        $software = $software | Sort-Object DisplayName -Unique
        
        Write-Log "Found $($software.Count) installed programs" -Level SUCCESS
        return $software
    }
    catch {
        Write-Log "Failed to collect software information: $_" -Level ERROR
        return $null
    }
}

function Get-RunningProcesses {
    Write-Log "Collecting running processes..." -Level INFO
    
    try {
        $processes = Get-Process | Where-Object { $_.MainWindowTitle -or $_.CPU -gt 0 } |
            Sort-Object CPU -Descending |
            Select-Object -First 50 |
            Select-Object @{N='ProcessName';E={$_.Name}},
                          @{N='PID';E={$_.Id}},
                          @{N='CPU(s)';E={[math]::Round($_.CPU, 2)}},
                          @{N='MemoryMB';E={[math]::Round($_.WorkingSet64 / 1MB, 2)}},
                          @{N='Threads';E={$_.Threads.Count}},
                          @{N='StartTime';E={$_.StartTime}},
                          @{N='Path';E={$_.Path}}
        
        Write-Log "Collected top 50 processes" -Level SUCCESS
        return $processes
    }
    catch {
        Write-Log "Failed to collect process information: $_" -Level ERROR
        return $null
    }
}

function Get-NetworkConfiguration {
    Write-Log "Collecting network configuration..." -Level INFO
    
    try {
        $adapters = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' } | ForEach-Object {
            $adapter = $_
            $ipConfig = Get-NetIPAddress -InterfaceIndex $adapter.ifIndex -ErrorAction SilentlyContinue
            $dns = Get-DnsClientServerAddress -InterfaceIndex $adapter.ifIndex -ErrorAction SilentlyContinue
            
            [PSCustomObject]@{
                Name = $adapter.Name
                Description = $adapter.InterfaceDescription
                Status = $adapter.Status
                MACAddress = $adapter.MacAddress
                IPv4Address = ($ipConfig | Where-Object { $_.AddressFamily -eq 'IPv4' }).IPAddress -join ', '
                IPv6Address = ($ipConfig | Where-Object { $_.AddressFamily -eq 'IPv6' }).IPAddress -join ', '
                DNSServers = ($dns | Where-Object { $_.AddressFamily -eq 2 }).ServerAddresses -join ', '
                Speed = $adapter.LinkSpeed
            }
        }
        
        Write-Log "Network configuration collected successfully" -Level SUCCESS
        return $adapters
    }
    catch {
        Write-Log "Failed to collect network information: $_" -Level ERROR
        return $null
    }
}

function Get-RecentErrors {
    Write-Log "Collecting recent errors..." -Level INFO
    
    try {
        $errors = @()
        
        # Application errors
        $errors += Get-WinEvent -FilterHashtable @{LogName='Application'; Level=2; StartTime=(Get-Date).AddHours(-24)} -MaxEvents 20 -ErrorAction SilentlyContinue |
            Select-Object @{N='Log';E={'Application'}}, TimeCreated, Id, ProviderName, Message
        
        # System errors
        $errors += Get-WinEvent -FilterHashtable @{LogName='System'; Level=2; StartTime=(Get-Date).AddHours(-24)} -MaxEvents 20 -ErrorAction SilentlyContinue |
            Select-Object @{N='Log';E={'System'}}, TimeCreated, Id, ProviderName, Message
        
        $errors = $errors | Sort-Object TimeCreated -Descending
        
        Write-Log "Collected $($errors.Count) recent errors" -Level SUCCESS
        return $errors
    }
    catch {
        Write-Log "Failed to collect error information: $_" -Level ERROR
        return $null
    }
}

function Get-ServiceStatus {
    Write-Log "Collecting critical services status..." -Level INFO
    
    try {
        $criticalServices = @(
            'Spooler',          # Print Spooler
            'wuauserv',         # Windows Update
            'BITS',             # Background Intelligent Transfer
            'Dhcp',             # DHCP Client
            'Dnscache',         # DNS Client
            'EventLog',         # Windows Event Log
            'LanmanServer',     # Server
            'LanmanWorkstation',# Workstation
            'RpcSs',            # Remote Procedure Call
            'SENS',             # System Event Notification
            'W32Time',          # Windows Time
            'Winmgmt'           # Windows Management Instrumentation
        )
        
        $services = Get-Service $criticalServices -ErrorAction SilentlyContinue |
            Select-Object Name, DisplayName, Status, StartType
        
        Write-Log "Collected status of $($services.Count) critical services" -Level SUCCESS
        return $services
    }
    catch {
        Write-Log "Failed to collect service information: $_" -Level ERROR
        return $null
    }
}

function Get-WindowsUpdates {
    Write-Log "Collecting Windows Update information..." -Level INFO
    
    try {
        $updateSession = New-Object -ComObject Microsoft.Update.Session
        $updateSearcher = $updateSession.CreateUpdateSearcher()
        
        # Get update history
        $historyCount = $updateSearcher.GetTotalHistoryCount()
        $history = $updateSearcher.QueryHistory(0, [Math]::Min(20, $historyCount)) | ForEach-Object {
            [PSCustomObject]@{
                Title = $_.Title
                Date = $_.Date
                Operation = switch ($_.Operation) {
                    1 { 'Installation' }
                    2 { 'Uninstallation' }
                    3 { 'Other' }
                }
                Result = switch ($_.ResultCode) {
                    0 { 'Not Started' }
                    1 { 'In Progress' }
                    2 { 'Succeeded' }
                    3 { 'Succeeded with errors' }
                    4 { 'Failed' }
                    5 { 'Aborted' }
                }
            }
        }
        
        Write-Log "Collected Windows Update history" -Level SUCCESS
        return $history
    }
    catch {
        Write-Log "Failed to collect Windows Update information: $_" -Level WARNING
        return $null
    }
}

# ============================================================
# EXPORT FUNCTIONS
# ============================================================

function Export-SystemReport {
    param([string]$OutputPath)
    
    Write-Log "Generating system report..." -Level INFO
    
    try {
        $reportPath = Join-Path $OutputPath "SystemReport.html"
        
        # Collect all data
        $systemInfo = Get-SystemInformation
        $diskInfo = Get-DiskInformation
        $networkInfo = Get-NetworkConfiguration
        $services = Get-ServiceStatus
        
        # Generate HTML report
        $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>System Report - $($systemInfo.ComputerName)</title>
    <style>
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin: 20px; background-color: #f5f5f5; }
        h1 { color: #2c3e50; border-bottom: 3px solid #3498db; padding-bottom: 10px; }
        h2 { color: #34495e; border-bottom: 2px solid #95a5a6; padding-bottom: 5px; margin-top: 30px; }
        .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; border-radius: 10px; margin-bottom: 30px; }
        .section { background-color: white; padding: 20px; margin-bottom: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        table { width: 100%; border-collapse: collapse; margin-top: 10px; }
        th { background-color: #3498db; color: white; padding: 12px; text-align: left; }
        td { padding: 10px; border-bottom: 1px solid #ddd; }
        tr:hover { background-color: #f5f5f5; }
        .info-grid { display: grid; grid-template-columns: 200px 1fr; gap: 10px; }
        .info-label { font-weight: bold; color: #7f8c8d; }
        .footer { text-align: center; margin-top: 30px; color: #7f8c8d; font-size: 12px; }
        .status-good { color: #27ae60; font-weight: bold; }
        .status-warning { color: #f39c12; font-weight: bold; }
        .status-bad { color: #e74c3c; font-weight: bold; }
    </style>
</head>
<body>
    <div class="header">
        <h1>[SYSTEM] Support Report</h1>
        <p><strong>Computer:</strong> $($systemInfo.ComputerName) | <strong>User:</strong> $($systemInfo.UserName)</p>
        <p><strong>Generated:</strong> $($systemInfo.CollectionTime)</p>
    </div>

    <div class="section">
        <h2>System Information</h2>
        <div class="info-grid">
            <div class="info-label">Manufacturer:</div><div>$($systemInfo.Manufacturer)</div>
            <div class="info-label">Model:</div><div>$($systemInfo.Model)</div>
            <div class="info-label">Serial Number:</div><div>$($systemInfo.SerialNumber)</div>
            <div class="info-label">Operating System:</div><div>$($systemInfo.OSName)</div>
            <div class="info-label">OS Version:</div><div>$($systemInfo.OSVersion) (Build $($systemInfo.OSBuild))</div>
            <div class="info-label">Architecture:</div><div>$($systemInfo.OSArchitecture)</div>
            <div class="info-label">Install Date:</div><div>$($systemInfo.InstallDate)</div>
            <div class="info-label">Last Boot:</div><div>$($systemInfo.LastBootTime)</div>
            <div class="info-label">Uptime:</div><div>$($systemInfo.Uptime)</div>
            <div class="info-label">Processor:</div><div>$($systemInfo.CPUName)</div>
            <div class="info-label">CPU Cores:</div><div>$($systemInfo.CPUCores) cores ($($systemInfo.CPULogicalProcessors) logical processors)</div>
            <div class="info-label">Total Memory:</div><div>$($systemInfo.TotalMemoryGB) GB</div>
            <div class="info-label">Domain/Workgroup:</div><div>$($systemInfo.Domain)</div>
            <div class="info-label">Time Zone:</div><div>$($systemInfo.TimeZone)</div>
        </div>
    </div>

    <div class="section">
        <h2>Disk Information</h2>
        <table>
            <tr>
                <th>Drive</th>
                <th>Label</th>
                <th>File System</th>
                <th>Total (GB)</th>
                <th>Used (GB)</th>
                <th>Free (GB)</th>
                <th>Free %</th>
            </tr>
"@
        
        foreach ($disk in $diskInfo) {
            $statusClass = if ($disk.PercentFree -lt 10) { 'status-bad' } elseif ($disk.PercentFree -lt 20) { 'status-warning' } else { 'status-good' }
            $html += @"
            <tr>
                <td>$($disk.Drive)</td>
                <td>$($disk.Label)</td>
                <td>$($disk.FileSystem)</td>
                <td>$($disk.SizeGB)</td>
                <td>$($disk.UsedGB)</td>
                <td>$($disk.FreeGB)</td>
                <td class="$statusClass">$($disk.PercentFree)%</td>
            </tr>
"@
        }
        
        $html += @"
        </table>
    </div>

    <div class="section">
        <h2>Network Adapters</h2>
        <table>
            <tr>
                <th>Name</th>
                <th>Description</th>
                <th>Status</th>
                <th>IPv4 Address</th>
                <th>MAC Address</th>
                <th>Speed</th>
            </tr>
"@
        
        foreach ($adapter in $networkInfo) {
            $html += @"
            <tr>
                <td>$($adapter.Name)</td>
                <td>$($adapter.Description)</td>
                <td class="status-good">$($adapter.Status)</td>
                <td>$($adapter.IPv4Address)</td>
                <td>$($adapter.MACAddress)</td>
                <td>$($adapter.Speed)</td>
            </tr>
"@
        }
        
        $html += @"
        </table>
    </div>

    <div class="section">
        <h2>Critical Services</h2>
        <table>
            <tr>
                <th>Service Name</th>
                <th>Display Name</th>
                <th>Status</th>
                <th>Start Type</th>
            </tr>
"@
        
        foreach ($service in $services) {
            $statusClass = if ($service.Status -eq 'Running') { 'status-good' } else { 'status-warning' }
            $html += @"
            <tr>
                <td>$($service.Name)</td>
                <td>$($service.DisplayName)</td>
                <td class="$statusClass">$($service.Status)</td>
                <td>$($service.StartType)</td>
            </tr>
"@
        }
        
        $html += @"
        </table>
    </div>

    <div class="footer">
        <p>Generated by Remote Support Toolkit | Coded by Soulitek.co.il</p>
        <p>www.soulitek.co.il | (C) 2025 Soulitek - All Rights Reserved</p>
    </div>
</body>
</html>
"@
        
        Set-Content -Path $reportPath -Value $html -Encoding UTF8
        Write-Log "System report saved to: $reportPath" -Level SUCCESS
        return $reportPath
    }
    catch {
        Write-Log "Failed to generate system report: $_" -Level ERROR
        return $null
    }
}

function Export-AllData {
    param([string]$OutputPath)
    
    Write-Log "Exporting all data to CSV files..." -Level INFO
    
    try {
        # System Information
        Get-SystemInformation | Export-Csv -Path (Join-Path $OutputPath "SystemInfo.csv") -NoTypeInformation -Encoding UTF8
        
        # Disk Information
        Get-DiskInformation | Export-Csv -Path (Join-Path $OutputPath "DiskInfo.csv") -NoTypeInformation -Encoding UTF8
        
        # Installed Software
        Get-InstalledSoftware | Export-Csv -Path (Join-Path $OutputPath "InstalledSoftware.csv") -NoTypeInformation -Encoding UTF8
        
        # Running Processes
        Get-RunningProcesses | Export-Csv -Path (Join-Path $OutputPath "RunningProcesses.csv") -NoTypeInformation -Encoding UTF8
        
        # Network Configuration
        Get-NetworkConfiguration | Export-Csv -Path (Join-Path $OutputPath "NetworkConfig.csv") -NoTypeInformation -Encoding UTF8
        
        # Recent Errors
        Get-RecentErrors | Export-Csv -Path (Join-Path $OutputPath "RecentErrors.csv") -NoTypeInformation -Encoding UTF8
        
        # Services
        Get-ServiceStatus | Export-Csv -Path (Join-Path $OutputPath "CriticalServices.csv") -NoTypeInformation -Encoding UTF8
        
        # Windows Updates
        $updates = Get-WindowsUpdates
        if ($updates) {
            $updates | Export-Csv -Path (Join-Path $OutputPath "WindowsUpdates.csv") -NoTypeInformation -Encoding UTF8
        }
        
        Write-Log "All data exported successfully" -Level SUCCESS
    }
    catch {
        Write-Log "Failed to export data: $_" -Level ERROR
    }
}

function New-SupportPackage {
    Write-Log "Creating support package..." -Level INFO
    
    try {
        # Create output folder
        if (-not (Test-Path $Script:OutputFolder)) {
            New-Item -ItemType Directory -Path $Script:OutputFolder -Force | Out-Null
        }
        
        # Initialize log file
        $Script:LogFile = Join-Path $Script:OutputFolder "collection_log.txt"
        
        Write-Host ""
        Write-Host "==========================================" -ForegroundColor Cyan
        Write-Host "  COLLECTING SYSTEM INFORMATION" -ForegroundColor Cyan
        Write-Host "==========================================" -ForegroundColor Cyan
        Write-Host ""
        
        # Generate HTML report
        Write-Host "[1/3] Generating HTML system report..." -ForegroundColor Yellow
        $null = Export-SystemReport -OutputPath $Script:OutputFolder
        
        # Export all data to CSV
        Write-Host "[2/3] Exporting detailed data to CSV..." -ForegroundColor Yellow
        Export-AllData -OutputPath $Script:OutputFolder
        
        # Create summary file
        Write-Host "[3/3] Creating summary file..." -ForegroundColor Yellow
        $systemInfo = Get-SystemInformation
        $summary = @"
============================================================
SUPPORT PACKAGE SUMMARY
============================================================

Computer Name: $($systemInfo.ComputerName)
User Name: $($systemInfo.UserName)
Collection Time: $($systemInfo.CollectionTime)

Operating System: $($systemInfo.OSName)
OS Version: $($systemInfo.OSVersion) (Build $($systemInfo.OSBuild))

Manufacturer: $($systemInfo.Manufacturer)
Model: $($systemInfo.Model)
Serial Number: $($systemInfo.SerialNumber)

CPU: $($systemInfo.CPUName)
Memory: $($systemInfo.TotalMemoryGB) GB
Uptime: $($systemInfo.Uptime)

============================================================
FILES INCLUDED
============================================================

- SystemReport.html         - Comprehensive HTML report
- SystemInfo.csv            - System information
- DiskInfo.csv              - Disk usage and capacity
- InstalledSoftware.csv     - List of installed programs
- RunningProcesses.csv      - Active processes
- NetworkConfig.csv         - Network adapter configuration
- RecentErrors.csv          - Recent system errors
- CriticalServices.csv      - Status of critical services
- WindowsUpdates.csv        - Windows Update history
- collection_log.txt        - Collection process log

============================================================
NEXT STEPS
============================================================

1. Review the HTML report (SystemReport.html)
2. Check CSV files for detailed information
3. Share this folder with your IT support team
4. Or create a ZIP file to email

============================================================
Generated by Remote Support Toolkit
Coded by: Soulitek.co.il
www.soulitek.co.il
(C) 2025 Soulitek - All Rights Reserved
============================================================
"@
        
        Set-Content -Path (Join-Path $Script:OutputFolder "README.txt") -Value $summary -Encoding UTF8
        
        Write-Host ""
        Write-Host "==========================================" -ForegroundColor Green
        Write-Host "  SUPPORT PACKAGE CREATED!" -ForegroundColor Green
        Write-Host "==========================================" -ForegroundColor Green
        Write-Host ""
        Write-Host "Package location:" -ForegroundColor Cyan
        Write-Host $Script:OutputFolder -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Files created:" -ForegroundColor Cyan
        Get-ChildItem $Script:OutputFolder | ForEach-Object {
            Write-Host "  - $($_.Name)" -ForegroundColor Gray
        }
        Write-Host ""
        
        # Ask to open folder
        $open = Read-Host "Open folder now? (Y/N)"
        if ($open -eq 'Y' -or $open -eq 'y') {
            Start-Process explorer $Script:OutputFolder
        }
        
        # Ask to create ZIP
        Write-Host ""
        $zip = Read-Host "Create ZIP file for easy sharing? (Y/N)"
        if ($zip -eq 'Y' -or $zip -eq 'y') {
            New-ZIPPackage
        }
        
        return $Script:OutputFolder
    }
    catch {
        Write-Log "Failed to create support package: $_" -Level ERROR
        Write-Host ""
        Write-Host "Error creating support package. Check the log for details." -ForegroundColor Red
        return $null
    }
}

function New-ZIPPackage {
    Write-Log "Creating ZIP package..." -Level INFO
    
    try {
        $zipPath = "$($Script:OutputFolder).zip"
        
        Write-Host ""
        Write-Host "Creating ZIP file..." -ForegroundColor Yellow
        
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        [System.IO.Compression.ZipFile]::CreateFromDirectory($Script:OutputFolder, $zipPath)
        
        Write-Host ""
        Write-Host "==========================================" -ForegroundColor Green
        Write-Host "  ZIP FILE CREATED!" -ForegroundColor Green
        Write-Host "==========================================" -ForegroundColor Green
        Write-Host ""
        Write-Host "ZIP file location:" -ForegroundColor Cyan
        Write-Host $zipPath -ForegroundColor Yellow
        Write-Host ""
        Write-Host "File size: " -NoNewline -ForegroundColor Cyan
        $size = (Get-Item $zipPath).Length / 1MB
        Write-Host "$([math]::Round($size, 2)) MB" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "You can now email this ZIP file to your support team." -ForegroundColor Green
        Write-Host ""
        
        Write-Log "ZIP package created: $zipPath" -Level SUCCESS
    }
    catch {
        Write-Log "Failed to create ZIP package: $_" -Level ERROR
        Write-Host "Failed to create ZIP file: $_" -ForegroundColor Red
    }
}

# ============================================================
# QUICK COLLECT FUNCTIONS
# ============================================================

function Show-QuickInfo {
    Show-Header "QUICK SYSTEM INFORMATION" -Color Green
    
    Write-Host "Collecting basic information..." -ForegroundColor Yellow
    Write-Host ""
    
    $systemInfo = Get-SystemInformation
    
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host "  COMPUTER INFORMATION" -ForegroundColor Cyan
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Computer Name:  " -NoNewline; Write-Host $systemInfo.ComputerName -ForegroundColor Yellow
    Write-Host "User Name:      " -NoNewline; Write-Host $systemInfo.UserName -ForegroundColor Yellow
    Write-Host "Manufacturer:   " -NoNewline; Write-Host $systemInfo.Manufacturer -ForegroundColor Yellow
    Write-Host "Model:          " -NoNewline; Write-Host $systemInfo.Model -ForegroundColor Yellow
    Write-Host "Serial Number:  " -NoNewline; Write-Host $systemInfo.SerialNumber -ForegroundColor Yellow
    Write-Host ""
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host "  OPERATING SYSTEM" -ForegroundColor Cyan
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "OS:             " -NoNewline; Write-Host $systemInfo.OSName -ForegroundColor Yellow
    Write-Host "Version:        " -NoNewline; Write-Host "$($systemInfo.OSVersion) (Build $($systemInfo.OSBuild))" -ForegroundColor Yellow
    Write-Host "Architecture:   " -NoNewline; Write-Host $systemInfo.OSArchitecture -ForegroundColor Yellow
    Write-Host "Uptime:         " -NoNewline; Write-Host $systemInfo.Uptime -ForegroundColor Yellow
    Write-Host ""
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host "  HARDWARE" -ForegroundColor Cyan
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "CPU:            " -NoNewline; Write-Host $systemInfo.CPUName -ForegroundColor Yellow
    Write-Host "Cores:          " -NoNewline; Write-Host "$($systemInfo.CPUCores) cores ($($systemInfo.CPULogicalProcessors) logical)" -ForegroundColor Yellow
    Write-Host "Memory:         " -NoNewline; Write-Host "$($systemInfo.TotalMemoryGB) GB" -ForegroundColor Yellow
    Write-Host ""
    
    # Disk info
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host "  DISK SPACE" -ForegroundColor Cyan
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host ""
    
    $disks = Get-DiskInformation
    foreach ($disk in $disks) {
        $color = if ($disk.PercentFree -lt 10) { 'Red' } elseif ($disk.PercentFree -lt 20) { 'Yellow' } else { 'Green' }
        Write-Host "Drive $($disk.Drive)  " -NoNewline
        Write-Host "$($disk.FreeGB) GB free of $($disk.SizeGB) GB ($($disk.PercentFree)% free)" -ForegroundColor $color
    }
    
    Write-Host ""
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host ""
    Read-Host "Press Enter to return to main menu"
}

# ============================================================
# MAIN MENU
# ============================================================

function Show-MainMenu {
    Show-Header "REMOTE SUPPORT TOOLKIT - All-in-One" -Color Cyan
    
    Write-Host "      Coded by: Soulitek.co.il" -ForegroundColor Green
    Write-Host "      IT Solutions for your business" -ForegroundColor Green
    Write-Host "      www.soulitek.co.il" -ForegroundColor Green
    Write-Host ""
    Write-Host "      (C) 2025 Soulitek - All Rights Reserved" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Select an option:" -ForegroundColor White
    Write-Host ""
    Write-Host "  [1] Quick Info          - View basic system information" -ForegroundColor Yellow
    Write-Host "  [2] Full Support Package - Collect all diagnostics" -ForegroundColor Yellow
    Write-Host "  [3] System Report Only   - Generate HTML report only" -ForegroundColor Yellow
    Write-Host "  [4] Export to CSV        - Export data to CSV files" -ForegroundColor Yellow
    Write-Host "  [5] Help                 - Usage guide" -ForegroundColor Yellow
    Write-Host "  [0] Exit" -ForegroundColor Red
    Write-Host ""
    Write-Host "========================================" -ForegroundColor DarkGray
    
    $choice = Read-Host "Enter your choice (0-5)"
    return $choice
}

function Show-Help {
    Show-Header "HELP GUIDE" -Color Cyan
    
    Write-Host "WHEN TO USE EACH MODE:" -ForegroundColor Yellow
    Write-Host "----------------------------------------" -ForegroundColor Gray
    Write-Host ""
    Write-Host "[1] QUICK INFO" -ForegroundColor White
    Write-Host "    Use when: Need to quickly check system specs" -ForegroundColor Gray
    Write-Host "    Shows: Basic system information on screen" -ForegroundColor Gray
    Write-Host "    Time: 5 seconds" -ForegroundColor Gray
    Write-Host ""
    Write-Host "[2] FULL SUPPORT PACKAGE" -ForegroundColor White
    Write-Host "    Use when: Need complete diagnostics for support" -ForegroundColor Gray
    Write-Host "    Creates: Folder with HTML report, CSV files, logs" -ForegroundColor Gray
    Write-Host "    Time: 30-60 seconds" -ForegroundColor Gray
    Write-Host ""
    Write-Host "[3] SYSTEM REPORT ONLY" -ForegroundColor White
    Write-Host "    Use when: Need a quick HTML report" -ForegroundColor Gray
    Write-Host "    Creates: Single HTML file with system overview" -ForegroundColor Gray
    Write-Host "    Time: 15 seconds" -ForegroundColor Gray
    Write-Host ""
    Write-Host "[4] EXPORT TO CSV" -ForegroundColor White
    Write-Host "    Use when: Need raw data for analysis" -ForegroundColor Gray
    Write-Host "    Creates: Multiple CSV files with detailed data" -ForegroundColor Gray
    Write-Host "    Time: 20 seconds" -ForegroundColor Gray
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "WHAT'S COLLECTED:" -ForegroundColor Yellow
    Write-Host "----------------------------------------" -ForegroundColor Gray
    Write-Host ""
    Write-Host "[+] System Information (OS, CPU, RAM, Serial)" -ForegroundColor Gray
    Write-Host "[+] Disk Usage (All drives with free space)" -ForegroundColor Gray
    Write-Host "[+] Installed Software (All programs)" -ForegroundColor Gray
    Write-Host "[+] Running Processes (Top 50 by CPU)" -ForegroundColor Gray
    Write-Host "[+] Network Configuration (All adapters)" -ForegroundColor Gray
    Write-Host "[+] Recent Errors (Last 24 hours)" -ForegroundColor Gray
    Write-Host "[+] Critical Services Status" -ForegroundColor Gray
    Write-Host "[+] Windows Update History" -ForegroundColor Gray
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "TIPS:" -ForegroundColor Yellow
    Write-Host "----------------------------------------" -ForegroundColor Gray
    Write-Host ""
    Write-Host "- Use 'Full Support Package' for remote support" -ForegroundColor Gray
    Write-Host "- Create ZIP file to email to support team" -ForegroundColor Gray
    Write-Host "- HTML report is easy to read and share" -ForegroundColor Gray
    Write-Host "- CSV files can be imported to Excel" -ForegroundColor Gray
    Write-Host "- Run as Administrator for full information" -ForegroundColor Gray
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Read-Host "Press Enter to return to main menu"
}

function Show-Disclaimer {
    Clear-Host
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "                    IMPORTANT NOTICE" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  This tool is provided `"AS IS`" without warranty." -ForegroundColor White
    Write-Host ""
    Write-Host "  USE AT YOUR OWN RISK" -ForegroundColor Red
    Write-Host ""
    Write-Host "  By continuing, you acknowledge that:" -ForegroundColor White
    Write-Host "  - You are solely responsible for any outcomes" -ForegroundColor Gray
    Write-Host "  - You understand the actions this tool will perform" -ForegroundColor Gray
    Write-Host "  - You accept full responsibility for its use" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  This tool collects system information and may include" -ForegroundColor Yellow
    Write-Host "  sensitive data. Ensure proper handling of exported files." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Press any key to continue or Ctrl+C to cancel..." -ForegroundColor Cyan
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
}

function Show-ExitMessage {
    Clear-Host
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "            Thank you for using" -ForegroundColor White
    Write-Host "        REMOTE SUPPORT TOOLKIT" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "       Coded by: Soulitek.co.il" -ForegroundColor Green
    Write-Host "       IT Solutions for your business" -ForegroundColor Green
    Write-Host "       www.soulitek.co.il" -ForegroundColor Green
    Write-Host ""
    Write-Host "       (C) 2025 Soulitek - All Rights Reserved" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "   Need IT support? Contact Soulitek for professional" -ForegroundColor White
    Write-Host "   computer repair, network setup, and business IT solutions." -ForegroundColor White
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Start-Sleep -Seconds 3
}

# ============================================================
# MAIN EXECUTION
# ============================================================

# Check administrator (not required but recommended)
if (-not (Test-SouliTEKAdministrator)) {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Yellow
    Write-Host "  NOTE: Not running as Administrator" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Some information may be incomplete without Administrator privileges." -ForegroundColor Yellow
    Write-Host "For best results, run as Administrator." -ForegroundColor Yellow
    Write-Host ""
    $continue = Read-Host "Continue anyway? (Y/N)"
    if ($continue -ne 'Y' -and $continue -ne 'y') {
        exit 0
    }
}

# Show disclaimer
Show-Disclaimer

# Main menu loop
do {
    $choice = Show-MainMenu
    
    switch ($choice) {
        "1" { Show-QuickInfo }
        "2" { New-SupportPackage }
        "3" {
            $folder = Join-Path $env:USERPROFILE "Desktop\SystemReport_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
            New-Item -ItemType Directory -Path $folder -Force | Out-Null
            $Script:LogFile = Join-Path $folder "log.txt"
            $report = Export-SystemReport -OutputPath $folder
            if ($report) {
                Write-Host ""
                Write-Host "Report created: $report" -ForegroundColor Green
                Write-Host ""
                $open = Read-Host "Open report? (Y/N)"
                if ($open -eq 'Y' -or $open -eq 'y') {
                    Start-Process $report
                }
            }
            Read-Host "Press Enter to continue"
        }
        "4" {
            $folder = Join-Path $env:USERPROFILE "Desktop\SystemData_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
            New-Item -ItemType Directory -Path $folder -Force | Out-Null
            $Script:LogFile = Join-Path $folder "log.txt"
            Export-AllData -OutputPath $folder
            Write-Host ""
            Write-Host "Data exported to: $folder" -ForegroundColor Green
            Write-Host ""
            $open = Read-Host "Open folder? (Y/N)"
            if ($open -eq 'Y' -or $open -eq 'y') {
                Start-Process explorer $folder
            }
            Read-Host "Press Enter to continue"
        }
        "5" { Show-Help }
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




