# ============================================================
# USB Device Log - Professional Forensic Tool
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
# This tool provides comprehensive USB device history analysis
# for forensic investigation and security auditing.
# 
# Features: Device History | Registry Analysis | Event Log Review
#           Forensic Details | Export Results
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
# This tool reads system registry and event logs which may
# contain sensitive information. Handle results appropriately.
# 
# ============================================================

#Requires -Version 5.1

# Set window title
$Host.UI.RawUI.WindowTitle = "USB DEVICE LOG"

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

$Script:USBDevices = @()
$Script:OutputFolder = Join-Path $env:USERPROFILE "Desktop"
$Script:ComputerName = $env:COMPUTERNAME
$Script:AnalysisDate = Get-Date

# Registry paths for USB device information
$Script:UsbStorRegPath = "HKLM:\SYSTEM\CurrentControlSet\Enum\USBSTOR"
$Script:UsbRegPath = "HKLM:\SYSTEM\CurrentControlSet\Enum\USB"
$Script:MountedDevicesPath = "HKLM:\SYSTEM\MountedDevices"

# ============================================================
# HELPER FUNCTIONS
# ============================================================



# Show-Header function - wrapper using Show-SouliTEKHeader from common module
function Show-Header {
    param([string]$Title = "USB DEVICE LOG - FORENSIC TOOL", [ConsoleColor]$Color = 'Cyan')
    
    Show-SouliTEKHeader -Title $Title -Color $Color -ClearHost -ShowBanner
}

# ============================================================
# USB DEVICE ANALYSIS FUNCTIONS
# ============================================================

function Get-USBStorDevices {
    <#
    .SYNOPSIS
        Retrieves USB storage devices from the Windows Registry.
    #>
    
    Write-SouliTEKResult "Scanning USBSTOR registry..." -Level INFO
    
    $devices = @()
    
    try {
        if (Test-Path $Script:UsbStorRegPath) {
            $deviceKeys = Get-ChildItem -Path $Script:UsbStorRegPath -ErrorAction SilentlyContinue
            
            foreach ($deviceKey in $deviceKeys) {
                $deviceType = $deviceKey.PSChildName
                
                # Parse device type (e.g., "Disk&Ven_Kingston&Prod_DataTraveler_3.0&Rev_PMAP")
                $deviceInfo = @{
                    DeviceType = ""
                    Vendor = ""
                    Product = ""
                    Revision = ""
                }
                
                if ($deviceType -match "Disk&Ven_([^&]+)&Prod_([^&]+)&Rev_(.+)") {
                    $deviceInfo.DeviceType = "Disk"
                    $deviceInfo.Vendor = $matches[1] -replace "_", " "
                    $deviceInfo.Product = $matches[2] -replace "_", " "
                    $deviceInfo.Revision = $matches[3]
                }
                
                # Get instance keys (serial numbers)
                $instanceKeys = Get-ChildItem -Path $deviceKey.PSPath -ErrorAction SilentlyContinue
                
                foreach ($instance in $instanceKeys) {
                    $serialNumber = $instance.PSChildName
                    
                    try {
                        $properties = Get-ItemProperty -Path $instance.PSPath -ErrorAction SilentlyContinue
                        
                        # Get friendly name
                        $friendlyName = if ($properties.FriendlyName) { 
                            $properties.FriendlyName 
                        } else { 
                            "$($deviceInfo.Vendor) $($deviceInfo.Product)".Trim()
                        }
                        
                        # Get install date from registry timestamp
                        $installDate = $null
                        if ($properties.PSObject.Properties.Name -contains "InstallDate") {
                            try {
                                $installDate = [DateTime]::ParseExact($properties.InstallDate, "yyyyMMdd", $null)
                            }
                            catch {
                                $installDate = $null
                            }
                        }
                        
                        # Try to get last write time from registry key
                        $lastConnected = $null
                        try {
                            $regKey = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey($instance.PSPath -replace "HKEY_LOCAL_MACHINE\\", "" -replace "HKLM:\\", "")
                            if ($regKey) {
                                $lastConnected = $regKey.GetValue("LastArrivalDate", $null)
                                if (-not $lastConnected) {
                                    # Use the registry key's last write time as approximation
                                    $keyPath = $instance.PSPath -replace "Microsoft.PowerShell.Core\\Registry::", ""
                                    $key = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey($keyPath -replace "HKLM:\\", "")
                                    if ($key) {
                                        # Registry keys don't directly expose last write time in PowerShell
                                        # We'll use install date or mark as unknown
                                        $lastConnected = $installDate
                                    }
                                }
                                $regKey.Close()
                            }
                        }
                        catch {
                            $lastConnected = $installDate
                        }
                        
                        # Get device status
                        $deviceStatus = "Unknown"
                        if ($properties.ConfigFlags) {
                            $configFlags = $properties.ConfigFlags
                            if ($configFlags -eq 0) {
                                $deviceStatus = "Working Properly"
                            }
                            elseif ($configFlags -band 0x1) {
                                $deviceStatus = "Disabled"
                            }
                            else {
                                $deviceStatus = "Problem (ConfigFlags: 0x{0:X})" -f $configFlags
                            }
                        }
                        
                        # Parse VID and PID from device ID if available
                        $vid = "N/A"
                        $productId = "N/A"
                        if ($properties.ParentIdPrefix) {
                            # Try to get VID/PID from parent device
                            $parentPath = "HKLM:\SYSTEM\CurrentControlSet\Enum\USB"
                            if (Test-Path $parentPath) {
                                $usbDevices = Get-ChildItem -Path $parentPath -Recurse -ErrorAction SilentlyContinue | 
                                    Where-Object { $_.PSChildName -like "*$($properties.ParentIdPrefix)*" }
                                
                                foreach ($usbDev in $usbDevices) {
                                    if ($usbDev.PSParentPath -match "VID_([0-9A-F]{4})&PID_([0-9A-F]{4})") {
                                        $vid = $matches[1]
                                        $productId = $matches[2]
                                        break
                                    }
                                }
                            }
                        }
                        
                        $device = [PSCustomObject]@{
                            DeviceName = $friendlyName
                            Vendor = $deviceInfo.Vendor
                            Product = $deviceInfo.Product
                            SerialNumber = $serialNumber
                            VID = $vid
                            PID = $productId
                            DeviceType = $deviceInfo.DeviceType
                            Revision = $deviceInfo.Revision
                            Status = $deviceStatus
                            InstallDate = if ($installDate) { $installDate.ToString("yyyy-MM-dd HH:mm:ss") } else { "Unknown" }
                            LastConnected = if ($lastConnected) { 
                                if ($lastConnected -is [DateTime]) {
                                    $lastConnected.ToString("yyyy-MM-dd HH:mm:ss")
                                } else {
                                    $lastConnected.ToString()
                                }
                            } else { "Unknown" }
                            RegistryPath = $instance.PSPath
                        }
                        
                        $devices += $device
                    }
                    catch {
                        Write-Verbose "Error processing instance $serialNumber : $_"
                    }
                }
            }
        }
        else {
            Write-SouliTEKResult "USBSTOR registry path not found" -Level WARNING
        }
        
        Write-SouliTEKResult "Found $($devices.Count) USB storage devices in registry" -Level SUCCESS
        return $devices
    }
    catch {
        Write-SouliTEKResult "Error scanning USBSTOR: $_" -Level ERROR
        return @()
    }
}

function Get-USBEventLogs {
    <#
    .SYNOPSIS
        Retrieves USB-related events from Windows Event Logs.
    #>
    
    Write-SouliTEKResult "Scanning Event Logs for USB activity..." -Level INFO
    
    $events = @()
    
    try {
        # Query multiple event logs for USB-related events
        $logQueries = @(
            @{
                LogName = "Microsoft-Windows-DriverFrameworks-UserMode/Operational"
                EventIDs = @(2003, 2100, 2101, 2102, 2105, 2106)
            },
            @{
                LogName = "System"
                EventIDs = @(20001, 20003, 10000, 10100)
            }
        )
        
        foreach ($query in $logQueries) {
            try {
                $logName = $query.LogName
                
                # Check if log exists
                $logExists = Get-WinEvent -ListLog $logName -ErrorAction SilentlyContinue
                if (-not $logExists) {
                    Write-Verbose "Event log '$logName' not available"
                    continue
                }
                
                $filterHash = @{
                    LogName = $logName
                    ID = $query.EventIDs
                    StartTime = (Get-Date).AddDays(-30)
                }
                
                $logEvents = Get-WinEvent -FilterHashtable $filterHash -MaxEvents 500 -ErrorAction SilentlyContinue
                
                if ($logEvents) {
                    foreach ($logEvent in $logEvents) {
                        $eventDetails = [PSCustomObject]@{
                            TimeCreated = $logEvent.TimeCreated
                            EventID = $logEvent.Id
                            LogName = $logEvent.LogName
                            Message = $logEvent.Message
                            ProviderName = $logEvent.ProviderName
                        }
                        $events += $eventDetails
                    }
                }
            }
            catch {
                Write-Verbose "Error querying $($query.LogName): $_"
            }
        }
        
        Write-SouliTEKResult "Found $($events.Count) USB-related events (last 30 days)" -Level SUCCESS
        return $events
    }
    catch {
        Write-SouliTEKResult "Error scanning event logs: $_" -Level ERROR
        return @()
    }
}

function Get-SetupAPIDeviceLog {
    <#
    .SYNOPSIS
        Parses the SetupAPI.dev.log file for USB device installation history.
    #>
    
    Write-SouliTEKResult "Checking SetupAPI device log..." -Level INFO
    
    $setupApiLog = Join-Path $env:SystemRoot "inf\setupapi.dev.log"
    
    try {
        if (Test-Path $setupApiLog) {
            $content = Get-Content $setupApiLog -ErrorAction Stop
            
            $usbLines = $content | Select-String -Pattern "USB" -Context 0, 3
            
            Write-SouliTEKResult "Found $($usbLines.Count) USB-related entries in SetupAPI log" -Level SUCCESS
            
            # Return count and sample
            return [PSCustomObject]@{
                LogPath = $setupApiLog
                TotalEntries = $usbLines.Count
                Available = $true
            }
        }
        else {
            Write-SouliTEKResult "SetupAPI log not found at $setupApiLog" -Level WARNING
            return [PSCustomObject]@{
                LogPath = $setupApiLog
                TotalEntries = 0
                Available = $false
            }
        }
    }
    catch {
        Write-SouliTEKResult "Error reading SetupAPI log: $_" -Level ERROR
        return [PSCustomObject]@{
            LogPath = $setupApiLog
            TotalEntries = 0
            Available = $false
        }
    }
}

# ============================================================
# MAIN ANALYSIS FUNCTION
# ============================================================

function Start-USBAnalysis {
    Show-Header "USB DEVICE ANALYSIS" -Color Cyan
    
    Write-Host "      Forensic USB Device History Scan" -ForegroundColor Gray
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    
    Write-SouliTEKResult "Starting comprehensive USB device analysis..." -Level INFO
    Write-Host ""
    
    # Check administrator privileges
    if (-not (Test-SouliTEKAdministrator)) {
        Write-Host ""
        Write-SouliTEKResult "WARNING: Running without administrator privileges" -Level WARNING
        Write-Host "  Some information may be limited. Run as Administrator for full access." -ForegroundColor Yellow
        Write-Host ""
        Start-Sleep -Seconds 2
    }
    
    # Stage 1: Registry Analysis
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "  STAGE 1: Registry Analysis" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    
    $Script:USBDevices = Get-USBStorDevices
    
    Write-Host ""
    
    # Stage 2: Event Log Analysis
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "  STAGE 2: Event Log Analysis" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    
    $usbEvents = Get-USBEventLogs
    
    Write-Host ""
    
    # Stage 3: SetupAPI Log
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "  STAGE 3: SetupAPI Device Log" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    
    $setupApiInfo = Get-SetupAPIDeviceLog
    
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "  ANALYSIS SUMMARY" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Computer Name: $Script:ComputerName" -ForegroundColor White
    Write-Host "Analysis Date: $($Script:AnalysisDate.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor White
    Write-Host ""
    Write-Host "Total USB Devices Found: $($Script:USBDevices.Count)" -ForegroundColor Green
    Write-Host "USB Events (30 days): $($usbEvents.Count)" -ForegroundColor Cyan
    Write-Host "SetupAPI Entries: $($setupApiInfo.TotalEntries)" -ForegroundColor Cyan
    Write-Host ""
    
    if ($Script:USBDevices.Count -eq 0) {
        Write-Host "No USB storage devices found in registry." -ForegroundColor Yellow
        Write-Host "This could mean:" -ForegroundColor Gray
        Write-Host "  - No USB devices have been connected to this system" -ForegroundColor Gray
        Write-Host "  - Registry entries have been cleaned" -ForegroundColor Gray
        Write-Host "  - Insufficient permissions to read registry" -ForegroundColor Gray
        Write-Host ""
    }
    else {
        Write-Host "============================================================" -ForegroundColor Cyan
        Write-Host "  USB DEVICE DETAILS" -ForegroundColor Cyan
        Write-Host "============================================================" -ForegroundColor Cyan
        Write-Host ""
        
        $deviceNum = 0
        foreach ($device in $Script:USBDevices) {
            $deviceNum++
            Write-Host "[$deviceNum] " -NoNewline -ForegroundColor Yellow
            Write-Host "$($device.DeviceName)" -ForegroundColor White
            Write-Host "    Vendor: $($device.Vendor)" -ForegroundColor Gray
            Write-Host "    Product: $($device.Product)" -ForegroundColor Gray
            Write-Host "    Serial Number: $($device.SerialNumber)" -ForegroundColor Cyan
            Write-Host "    VID/PID: $($device.VID) / $($device.PID)" -ForegroundColor Gray
            Write-Host "    Type: $($device.DeviceType)" -ForegroundColor Gray
            Write-Host "    Status: $($device.Status)" -ForegroundColor Gray
            Write-Host "    Install Date: $($device.InstallDate)" -ForegroundColor Gray
            Write-Host "    Last Connected: $($device.LastConnected)" -ForegroundColor $(
                if ($device.LastConnected -ne "Unknown") { 'Green' } else { 'Yellow' }
            )
            Write-Host ""
        }
    }
    
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    
    # Store events for export
    $Script:USBEvents = $usbEvents
    $Script:SetupAPIInfo = $setupApiInfo
    
    Read-Host "Press Enter to return to main menu"
}

# ============================================================
# EXPORT FUNCTIONS
# ============================================================

function Export-USBReport {
    Show-Header "EXPORT USB DEVICE REPORT" -Color Yellow
    
    Write-Host "      Save USB device history to file" -ForegroundColor Gray
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    
    if ($Script:USBDevices.Count -eq 0) {
        Write-SouliTEKResult "No USB devices to export" -Level WARNING
        Write-Host ""
        Write-Host "Run 'USB Device Analysis' first to scan for devices." -ForegroundColor Yellow
        Write-Host ""
        Start-Sleep -Seconds 3
        return
    }
    
    Write-Host "Total devices found: $($Script:USBDevices.Count)" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Select export format:" -ForegroundColor White
    Write-Host ""
    Write-Host "  [1] Text Report (.txt)" -ForegroundColor Yellow
    Write-Host "  [2] CSV File (.csv)" -ForegroundColor Yellow
    Write-Host "  [3] HTML Report (.html)" -ForegroundColor Yellow
    Write-Host "  [4] All Formats" -ForegroundColor Green
    Write-Host "  [0] Cancel" -ForegroundColor Red
    Write-Host ""
    
    $choice = Read-Host "Enter your choice (0-4)"
    
    try {
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        
        switch ($choice) {
            "1" { Export-TextReport -Timestamp $timestamp }
            "2" { Export-CSVReport -Timestamp $timestamp }
            "3" { Export-HTMLReport -Timestamp $timestamp }
            "4" {
                Export-TextReport -Timestamp $timestamp
                Export-CSVReport -Timestamp $timestamp
                Export-HTMLReport -Timestamp $timestamp
            }
            "0" { return }
            default {
                Write-SouliTEKResult "Invalid choice" -Level ERROR
                Start-Sleep -Seconds 2
                return
            }
        }
    }
    catch {
        Write-SouliTEKResult "Export failed: $_" -Level ERROR
    }
    
    Write-Host ""
    Read-Host "Press Enter to return to main menu"
}

function Export-TextReport {
    param([string]$Timestamp)
    
    $fileName = "USB_Device_Report_$Timestamp.txt"
    $filePath = Join-Path $Script:OutputFolder $fileName
    
    $content = @()
    $content += "============================================================"
    $content += "    USB DEVICE LOG - FORENSIC REPORT"
    $content += "    Coded by: Soulitek.co.il"
    $content += "============================================================"
    $content += ""
    $content += "Report Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    $content += "Computer Name: $Script:ComputerName"
    $content += "Analyzed By: $env:USERNAME"
    $content += ""
    $content += "Total USB Devices Found: $($Script:USBDevices.Count)"
    $content += ""
    $content += "============================================================"
    $content += "  DEVICE DETAILS"
    $content += "============================================================"
    $content += ""
    
    $deviceNum = 0
    foreach ($device in $Script:USBDevices) {
        $deviceNum++
        $content += "[$deviceNum] $($device.DeviceName)"
        $content += "------------------------------------------------------------"
        $content += "  Vendor:         $($device.Vendor)"
        $content += "  Product:        $($device.Product)"
        $content += "  Serial Number:  $($device.SerialNumber)"
        $content += "  VID:            $($device.VID)"
        $content += "  PID:            $($device.PID)"
        $content += "  Device Type:    $($device.DeviceType)"
        $content += "  Revision:       $($device.Revision)"
        $content += "  Status:         $($device.Status)"
        $content += "  Install Date:   $($device.InstallDate)"
        $content += "  Last Connected: $($device.LastConnected)"
        $content += "  Registry Path:  $($device.RegistryPath)"
        $content += ""
    }
    
    $content += "============================================================"
    $content += "  END OF REPORT"
    $content += "============================================================"
    $content += ""
    $content += "Generated by USB Device Log - Forensic Tool"
    $content += "Coded by: Soulitek.co.il"
    $content += "www.soulitek.co.il"
    $content += "(C) 2025 Soulitek - All Rights Reserved"
    
    $content | Out-File -FilePath $filePath -Encoding UTF8
    
    Write-Host ""
    Write-SouliTEKResult "Text report exported to: $filePath" -Level SUCCESS
    Start-Sleep -Seconds 1
    Start-Process $filePath
}

function Export-CSVReport {
    param([string]$Timestamp)
    
    $fileName = "USB_Device_Report_$Timestamp.csv"
    $filePath = Join-Path $Script:OutputFolder $fileName
    
    $Script:USBDevices | Export-Csv -Path $filePath -NoTypeInformation -Encoding UTF8
    
    Write-Host ""
    Write-SouliTEKResult "CSV report exported to: $filePath" -Level SUCCESS
    Start-Sleep -Seconds 1
    Start-Process $filePath
}

function Export-HTMLReport {
    param([string]$Timestamp)
    
    $fileName = "USB_Device_Report_$Timestamp.html"
    $filePath = Join-Path $Script:OutputFolder $fileName
    
    $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>USB Device Log - Forensic Report - $Script:ComputerName</title>
    <meta charset="UTF-8">
    <style>
        body { 
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; 
            margin: 20px; 
            background-color: #f5f5f5; 
        }
        .header { 
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); 
            color: white; 
            padding: 30px; 
            border-radius: 10px; 
            margin-bottom: 30px; 
            box-shadow: 0 4px 6px rgba(0,0,0,0.1);
        }
        h1 { 
            margin: 0; 
            padding: 0; 
            font-size: 28px;
        }
        .meta { 
            margin-top: 15px; 
            font-size: 14px; 
            opacity: 0.9;
        }
        .summary { 
            background: white; 
            padding: 20px; 
            border-radius: 8px; 
            margin-bottom: 20px; 
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        .summary-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 15px;
            margin-top: 15px;
        }
        .summary-item {
            background: #f8f9fa;
            padding: 15px;
            border-radius: 6px;
            border-left: 4px solid #667eea;
        }
        .summary-label {
            font-size: 12px;
            color: #6c757d;
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }
        .summary-value {
            font-size: 24px;
            font-weight: bold;
            color: #2c3e50;
            margin-top: 5px;
        }
        .device { 
            background-color: white; 
            padding: 20px; 
            margin-bottom: 20px; 
            border-radius: 8px; 
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
            border-left: 5px solid #667eea;
        }
        .device-header { 
            font-size: 20px; 
            font-weight: bold; 
            color: #2c3e50; 
            margin-bottom: 15px;
            display: flex;
            align-items: center;
        }
        .device-number {
            background: #667eea;
            color: white;
            width: 32px;
            height: 32px;
            border-radius: 50%;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            margin-right: 12px;
            font-size: 16px;
        }
        .device-info { 
            display: grid; 
            grid-template-columns: 180px 1fr; 
            gap: 12px; 
            margin-top: 12px;
            font-size: 14px;
        }
        .info-label { 
            font-weight: bold; 
            color: #495057;
            display: flex;
            align-items: center;
        }
        .info-label::before {
            content: '▪';
            color: #667eea;
            margin-right: 8px;
            font-size: 18px;
        }
        .info-value { 
            color: #212529;
            word-break: break-all;
        }
        .status-working { color: #28a745; font-weight: bold; }
        .status-problem { color: #dc3545; font-weight: bold; }
        .status-unknown { color: #6c757d; font-weight: bold; }
        .serial-number {
            background: #e9ecef;
            padding: 4px 8px;
            border-radius: 4px;
            font-family: 'Courier New', monospace;
            font-size: 13px;
        }
        .footer { 
            text-align: center; 
            margin-top: 40px; 
            padding: 20px;
            color: #6c757d; 
            font-size: 12px;
            border-top: 2px solid #dee2e6;
        }
        .footer-brand {
            font-weight: bold;
            color: #667eea;
            font-size: 14px;
        }
    </style>
</head>
<body>
    <div class="header">
        <h1>🔍 USB Device Log - Forensic Report</h1>
        <div class="meta">
            <strong>Computer:</strong> $Script:ComputerName | 
            <strong>Generated:</strong> $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') | 
            <strong>Analyzed By:</strong> $env:USERNAME
        </div>
    </div>
    
    <div class="summary">
        <h2 style="margin-top: 0; color: #2c3e50;">📊 Analysis Summary</h2>
        <div class="summary-grid">
            <div class="summary-item">
                <div class="summary-label">Total Devices</div>
                <div class="summary-value">$($Script:USBDevices.Count)</div>
            </div>
            <div class="summary-item">
                <div class="summary-label">Computer Name</div>
                <div class="summary-value" style="font-size: 18px;">$Script:ComputerName</div>
            </div>
            <div class="summary-item">
                <div class="summary-label">Analysis Date</div>
                <div class="summary-value" style="font-size: 16px;">$($Script:AnalysisDate.ToString('yyyy-MM-dd'))</div>
            </div>
        </div>
    </div>
    
    <h2 style="color: #2c3e50; margin-top: 30px;">💾 Device Details</h2>
"@
    
    $deviceNum = 0
    foreach ($device in $Script:USBDevices) {
        $deviceNum++
        
        $statusClass = switch -Regex ($device.Status) {
            "Working" { "status-working" }
            "Problem|Disabled" { "status-problem" }
            default { "status-unknown" }
        }
        
        $html += @"
    <div class="device">
        <div class="device-header">
            <span class="device-number">$deviceNum</span>
            <span>$($device.DeviceName)</span>
        </div>
        <div class="device-info">
            <div class="info-label">Vendor</div>
            <div class="info-value">$($device.Vendor)</div>
            
            <div class="info-label">Product</div>
            <div class="info-value">$($device.Product)</div>
            
            <div class="info-label">Serial Number</div>
            <div class="info-value"><span class="serial-number">$($device.SerialNumber)</span></div>
            
            <div class="info-label">VID / PID</div>
            <div class="info-value">$($device.VID) / $($device.PID)</div>
            
            <div class="info-label">Device Type</div>
            <div class="info-value">$($device.DeviceType)</div>
            
            <div class="info-label">Revision</div>
            <div class="info-value">$($device.Revision)</div>
            
            <div class="info-label">Status</div>
            <div class="info-value"><span class="$statusClass">$($device.Status)</span></div>
            
            <div class="info-label">Install Date</div>
            <div class="info-value">$($device.InstallDate)</div>
            
            <div class="info-label">Last Connected</div>
            <div class="info-value"><strong>$($device.LastConnected)</strong></div>
        </div>
    </div>
"@
    }
    
    $html += @"
    <div class="footer">
        <div class="footer-brand">USB Device Log - Forensic Tool</div>
        <div style="margin-top: 8px;">
            Coded by <strong>Soulitek.co.il</strong> | www.soulitek.co.il<br>
            (C) 2025 Soulitek - All Rights Reserved
        </div>
        <div style="margin-top: 12px; font-size: 11px;">
            This report contains forensic information about USB devices connected to this system.<br>
            Handle this information securely and in accordance with your organization's policies.
        </div>
    </div>
</body>
</html>
"@
    
    Set-Content -Path $filePath -Value $html -Encoding UTF8
    
    Write-Host ""
    Write-SouliTEKResult "HTML report exported to: $filePath" -Level SUCCESS
    Start-Sleep -Seconds 1
    Start-Process $filePath
}

# ============================================================
# HELP FUNCTION
# ============================================================

function Show-Help {
    Show-Header "HELP GUIDE" -Color Cyan
    
    Write-Host "USB DEVICE LOG - FORENSIC TOOL - USAGE GUIDE" -ForegroundColor Yellow
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "[1] USB DEVICE ANALYSIS" -ForegroundColor White
    Write-Host "    Comprehensive scan of USB device history" -ForegroundColor Gray
    Write-Host "    - Registry analysis (USBSTOR)" -ForegroundColor Gray
    Write-Host "    - Event log review (30 days)" -ForegroundColor Gray
    Write-Host "    - SetupAPI device log check" -ForegroundColor Gray
    Write-Host "    Use: Forensic investigation, security audit" -ForegroundColor Gray
    Write-Host ""
    Write-Host "[2] EXPORT REPORT" -ForegroundColor White
    Write-Host "    Save device history to file" -ForegroundColor Gray
    Write-Host "    - Text format (.txt) - Human-readable report" -ForegroundColor Gray
    Write-Host "    - CSV format (.csv) - Spreadsheet analysis" -ForegroundColor Gray
    Write-Host "    - HTML format (.html) - Professional web report" -ForegroundColor Gray
    Write-Host "    Use: Documentation, evidence collection" -ForegroundColor Gray
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "INFORMATION COLLECTED:" -ForegroundColor Yellow
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Device Details:" -ForegroundColor White
    Write-Host "  - Device Name & Friendly Name" -ForegroundColor Gray
    Write-Host "  - Vendor & Product Information" -ForegroundColor Gray
    Write-Host "  - Serial Number (Unique Identifier)" -ForegroundColor Gray
    Write-Host "  - VID (Vendor ID) & PID (Product ID)" -ForegroundColor Gray
    Write-Host "  - Device Type & Revision" -ForegroundColor Gray
    Write-Host "  - Installation Date" -ForegroundColor Gray
    Write-Host "  - Last Connected Date (if available)" -ForegroundColor Gray
    Write-Host "  - Device Status" -ForegroundColor Gray
    Write-Host "  - Registry Path" -ForegroundColor Gray
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "FORENSIC USE CASES:" -ForegroundColor Yellow
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "1. Security Incident Response" -ForegroundColor White
    Write-Host "   - Identify unauthorized USB devices" -ForegroundColor Gray
    Write-Host "   - Track data exfiltration attempts" -ForegroundColor Gray
    Write-Host "   - Audit device access history" -ForegroundColor Gray
    Write-Host ""
    Write-Host "2. Compliance & Policy Enforcement" -ForegroundColor White
    Write-Host "   - Verify approved device usage" -ForegroundColor Gray
    Write-Host "   - Document device connections" -ForegroundColor Gray
    Write-Host "   - Generate audit reports" -ForegroundColor Gray
    Write-Host ""
    Write-Host "3. IT Troubleshooting" -ForegroundColor White
    Write-Host "   - Review device installation history" -ForegroundColor Gray
    Write-Host "   - Identify driver issues" -ForegroundColor Gray
    Write-Host "   - Track device problems" -ForegroundColor Gray
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "ADMINISTRATOR PRIVILEGES:" -ForegroundColor Yellow
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "This tool works best with Administrator privileges." -ForegroundColor White
    Write-Host "Running without admin rights may limit:" -ForegroundColor Yellow
    Write-Host "  - Registry access" -ForegroundColor Gray
    Write-Host "  - Event log queries" -ForegroundColor Gray
    Write-Host "  - SetupAPI log reading" -ForegroundColor Gray
    Write-Host ""
    Write-Host "To run as Administrator:" -ForegroundColor White
    Write-Host "  Right-click PowerShell > Run as Administrator" -ForegroundColor Gray
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "DATA INTERPRETATION:" -ForegroundColor Yellow
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Serial Number:" -ForegroundColor White
    Write-Host "  - Unique identifier for each device" -ForegroundColor Gray
    Write-Host "  - Same device = same serial number" -ForegroundColor Gray
    Write-Host ""
    Write-Host "VID/PID:" -ForegroundColor White
    Write-Host "  - Vendor ID identifies manufacturer" -ForegroundColor Gray
    Write-Host "  - Product ID identifies device model" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Last Connected:" -ForegroundColor White
    Write-Host "  - May show 'Unknown' if not available" -ForegroundColor Gray
    Write-Host "  - Registry doesn't always track disconnect time" -ForegroundColor Gray
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Read-Host "Press Enter to return to main menu"
}

# ============================================================
# MAIN MENU
# ============================================================

function Show-MainMenu {
    Show-Header "USB DEVICE LOG - FORENSIC TOOL" -Color Cyan
    
    Write-Host "      Coded by: Soulitek.co.il" -ForegroundColor Green
    Write-Host "      IT Solutions for your business" -ForegroundColor Green
    Write-Host "      www.soulitek.co.il" -ForegroundColor Green
    Write-Host ""
    Write-Host "      (C) 2025 Soulitek - All Rights Reserved" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    
    if ($Script:USBDevices.Count -gt 0) {
        Write-Host "  Devices Found: $($Script:USBDevices.Count)" -ForegroundColor Green
        Write-Host ""
    }
    
    Write-Host "Select an option:" -ForegroundColor White
    Write-Host ""
    Write-Host "  [1] USB Device Analysis  - Scan device history" -ForegroundColor Yellow
    Write-Host "  [2] Export Report        - Save results to file" -ForegroundColor Yellow
    Write-Host "  [3] Help                 - Usage guide" -ForegroundColor White
    Write-Host "  [0] Exit" -ForegroundColor Red
    Write-Host ""
    Write-Host "========================================" -ForegroundColor DarkGray
    
    $choice = Read-Host "Enter your choice (0-3)"
    return $choice
}

# Show-Disclaimer function - using Show-SouliTEKDisclaimer from common module
function Show-Disclaimer {
    Show-SouliTEKDisclaimer
}

# Show-ExitMessage function - using Show-SouliTEKExitMessage from common module
function Show-ExitMessage {
    Show-SouliTEKExitMessage -ScriptPath $PSCommandPath -ToolName "SouliTEK USB Device Log"
}

# ============================================================
# MAIN EXECUTION
# ============================================================

# Show disclaimer
Show-Disclaimer

# Main menu loop
do {
    $choice = Show-MainMenu
    
    switch ($choice) {
        "1" { Start-USBAnalysis }
        "2" { Export-USBReport }
        "3" { Show-Help }
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




