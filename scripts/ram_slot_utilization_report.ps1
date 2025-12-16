# ============================================================
# RAM Slot Utilization Report - Professional Edition
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
# This tool provides comprehensive RAM slot analysis
# showing utilized vs total slots, memory type, speed, and capacity.
# 
# Features: Console Display | TXT Export | CSV Export | HTML Report
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
$Host.UI.RawUI.WindowTitle = "RAM SLOT UTILIZATION REPORT"

# Import SouliTEK Common Functions
$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$CommonPath = Join-Path (Split-Path -Parent $ScriptRoot) "modules\SouliTEK-Common.ps1"
if (Test-Path $CommonPath) {
    . $CommonPath
} else {
    Write-Warning "SouliTEK Common Functions not found at: $CommonPath"
    Write-Warning "Some functions may not work properly."
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
    Write-Host "  [1] Display RAM Report       - View slot utilization in console"
    Write-Host "  [2] Export to TXT            - Save as text file"
    Write-Host "  [3] Export to CSV            - Save as CSV file"
    Write-Host "  [4] Export to HTML           - Save as HTML report"
    Write-Host "  [5] Export All Formats       - Generate all report formats"
    Write-Host "  [6] Help                     - Usage guide"
    Write-Host "  [0] Exit"
    Write-Host ""
    Write-Host "========================================"
    Set-SouliTEKConsoleColor "White"
    $choice = Read-Host "Enter your choice (0-6)"
    return $choice
}

# Function to detect DDR type from SMBIOS memory type
function Get-DDRType {
    param([int]$MemoryType)
    
    switch ($MemoryType) {
        20 { return "DDR" }
        21 { return "DDR2" }
        22 { return "DDR2 FB-DIMM" }
        24 { return "DDR3" }
        26 { return "DDR4" }
        30 { return "LPDDR4" }
        34 { return "DDR5" }
        35 { return "LPDDR5" }
        default { return "Unknown" }
    }
}

# Function to get RAM slot information
function Get-RAMSlotInformation {
    try {
        $memoryModules = Get-CimInstance Win32_PhysicalMemoryArray
        $memoryDevices = Get-CimInstance Win32_PhysicalMemory
        
        # Get total slots
        $totalSlots = 0
        foreach ($array in $memoryModules) {
            $totalSlots += $array.MemoryDevices
        }
        
        # If no arrays found, try alternative method
        if ($totalSlots -eq 0) {
            # Try to get from motherboard or estimate from installed modules
            $totalSlots = [math]::Max($memoryDevices.Count, 2)  # Default to 2 if uncertain
        }
        
        $usedSlots = $memoryDevices.Count
        $emptySlots = $totalSlots - $usedSlots
        
        # Calculate totals
        $totalCapacity = ($memoryDevices | Measure-Object -Property Capacity -Sum).Sum
        $totalCapacityGB = [math]::Round($totalCapacity / 1GB, 2)
        
        # Get speed information
        $speeds = $memoryDevices | Select-Object -ExpandProperty Speed -Unique | Sort-Object
        
        # Get type information
        $types = $memoryDevices | Select-Object -ExpandProperty SMBIOSMemoryType | ForEach-Object { Get-DDRType $_ } | Sort-Object -Unique
        
        # Create detailed slot information
        $slotDetails = @()
        $slotNumber = 1
        
        foreach ($device in $memoryDevices | Sort-Object DeviceLocator) {
            $capacityGB = [math]::Round($device.Capacity / 1GB, 2)
            $speed = $device.Speed
            $ddrType = Get-DDRType $device.SMBIOSMemoryType
            $manufacturer = if ($device.Manufacturer) { $device.Manufacturer.Trim() } else { "Unknown" }
            $partNumber = if ($device.PartNumber) { $device.PartNumber.Trim() } else { "Unknown" }
            $serialNumber = if ($device.SerialNumber) { $device.SerialNumber.Trim() } else { "Unknown" }
            $formFactor = switch ($device.FormFactor) {
                0 { "Unknown" }
                1 { "Other" }
                2 { "SIP" }
                3 { "DIP" }
                4 { "ZIP" }
                5 { "SOJ" }
                6 { "Proprietary" }
                7 { "SIMM" }
                8 { "DIMM" }
                9 { "TSOP" }
                10 { "PGA" }
                11 { "RIMM" }
                12 { "SODIMM" }
                13 { "SRIMM" }
                14 { "SMD" }
                15 { "SSMP" }
                16 { "QFP" }
                17 { "TQFP" }
                18 { "SOIC" }
                19 { "LCC" }
                20 { "PLCC" }
                21 { "BGA" }
                22 { "FPBGA" }
                23 { "LGA" }
                default { "Unknown" }
            }
            
            $slotDetails += [PSCustomObject]@{
                Slot = $slotNumber++
                DeviceLocator = $device.DeviceLocator
                CapacityGB = $capacityGB
                SpeedMHz = $speed
                Type = $ddrType
                Manufacturer = $manufacturer
                PartNumber = $partNumber
                SerialNumber = $serialNumber
                FormFactor = $formFactor
                Status = "In Use"
            }
        }
        
        # Add empty slots
        for ($i = $usedSlots; $i -lt $totalSlots; $i++) {
            $slotDetails += [PSCustomObject]@{
                Slot = $slotNumber++
                DeviceLocator = "Empty Slot"
                CapacityGB = 0
                SpeedMHz = 0
                Type = "N/A"
                Manufacturer = "N/A"
                PartNumber = "N/A"
                SerialNumber = "N/A"
                FormFactor = "N/A"
                Status = "Empty"
            }
        }
        
        $ramInfo = [PSCustomObject]@{
            TotalSlots = $totalSlots
            UsedSlots = $usedSlots
            EmptySlots = $emptySlots
            TotalCapacityGB = $totalCapacityGB
            SpeedsMHz = $speeds -join ", "
            Types = $types -join ", "
            SlotDetails = $slotDetails
            CollectionTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            ComputerName = $env:COMPUTERNAME
        }
        
        return $ramInfo
    }
    catch {
        Write-Host "Error collecting RAM information: $_" -ForegroundColor Red
        return $null
    }
}

# Function to display RAM report in console
function Show-RAMReport {
    Clear-Host
    Show-SouliTEKBanner
    Set-SouliTEKConsoleColor "Blue"
    Write-Host ""
    Write-Host "========================================"
    Write-Host "   RAM SLOT UTILIZATION REPORT"
    Write-Host "========================================"
    Write-Host ""
    Write-Host "Collecting RAM information..."
    Write-Host ""
    
    $ramInfo = Get-RAMSlotInformation
    
    if (-not $ramInfo) {
        Set-SouliTEKConsoleColor "Red"
        Write-Host "Failed to collect RAM information." -ForegroundColor Red
        Write-Host ""
        Set-SouliTEKConsoleColor "White"
        Write-Host "Press any key to return to main menu..."
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        return
    }
    
    # Summary
    Write-Host "SUMMARY" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Computer Name:      " -NoNewline; Write-Host $ramInfo.ComputerName -ForegroundColor Green
    Write-Host "Total Slots:        " -NoNewline; Write-Host $ramInfo.TotalSlots -ForegroundColor Green
    Write-Host "Slots Used:         " -NoNewline; Write-Host "$($ramInfo.UsedSlots) / $($ramInfo.TotalSlots)" -ForegroundColor $(if ($ramInfo.UsedSlots -eq $ramInfo.TotalSlots) { "Yellow" } else { "Green" })
    Write-Host "Slots Empty:        " -NoNewline; Write-Host $ramInfo.EmptySlots -ForegroundColor $(if ($ramInfo.EmptySlots -gt 0) { "Yellow" } else { "Green" })
    Write-Host "Total Capacity:     " -NoNewline; Write-Host "$($ramInfo.TotalCapacityGB) GB" -ForegroundColor Green
    Write-Host "Memory Type(s):     " -NoNewline; Write-Host $ramInfo.Types -ForegroundColor Green
    Write-Host "Speed(s):           " -NoNewline; Write-Host "$($ramInfo.SpeedsMHz) MHz" -ForegroundColor Green
    Write-Host ""
    
    # Slot details
    Write-Host "SLOT DETAILS" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    
    foreach ($slot in $ramInfo.SlotDetails) {
        if ($slot.Status -eq "In Use") {
            Write-Host "Slot $($slot.Slot) - $($slot.DeviceLocator)" -ForegroundColor Green
            Write-Host "  Capacity:   " -NoNewline; Write-Host "$($slot.CapacityGB) GB" -ForegroundColor White
            Write-Host "  Type:       " -NoNewline; Write-Host $slot.Type -ForegroundColor White
            Write-Host "  Speed:      " -NoNewline; Write-Host "$($slot.SpeedMHz) MHz" -ForegroundColor White
            Write-Host "  Form Factor:" -NoNewline; Write-Host $slot.FormFactor -ForegroundColor White
            Write-Host "  Manufacturer:" -NoNewline; Write-Host $slot.Manufacturer -ForegroundColor White
            if ($slot.PartNumber -ne "Unknown") {
                Write-Host "  Part Number:" -NoNewline; Write-Host $slot.PartNumber -ForegroundColor White
            }
            Write-Host ""
        } else {
            Write-Host "Slot $($slot.Slot) - $($slot.DeviceLocator)" -ForegroundColor DarkGray
            Write-Host "  Status: Empty" -ForegroundColor DarkGray
            Write-Host ""
        }
    }
    
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Set-SouliTEKConsoleColor "White"
    Write-Host "Press any key to return to main menu..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# Function to export to TXT
function Export-RAMReportTXT {
    Clear-Host
    Show-SouliTEKBanner
    Set-SouliTEKConsoleColor "Blue"
    Write-Host ""
    Write-Host "========================================"
    Write-Host "   EXPORT RAM REPORT - TXT FORMAT"
    Write-Host "========================================"
    Write-Host ""
    
    $ramInfo = Get-RAMSlotInformation
    
    if (-not $ramInfo) {
        Write-Host "Failed to collect RAM information." -ForegroundColor Red
        Write-Host ""
        Set-SouliTEKConsoleColor "White"
        Write-Host "Press any key to return to main menu..."
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        return
    }
    
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $outputPath = "$env:USERPROFILE\Desktop\RAM_Slot_Report_$timestamp.txt"
    
    $report = @"
============================================================
RAM SLOT UTILIZATION REPORT
============================================================
Generated by: SouliTEK All-In-One Scripts
Website: www.soulitek.co.il
Email: letstalk@soulitek.co.il

(C) 2025 Soulitek - All Rights Reserved

============================================================
REPORT INFORMATION
============================================================
Computer Name: $($ramInfo.ComputerName)
Collection Time: $($ramInfo.CollectionTime)

============================================================
SUMMARY
============================================================
Total Slots:          $($ramInfo.TotalSlots)
Slots Used:           $($ramInfo.UsedSlots) / $($ramInfo.TotalSlots)
Slots Empty:          $($ramInfo.EmptySlots)
Total Capacity:       $($ramInfo.TotalCapacityGB) GB
Memory Type(s):       $($ramInfo.Types)
Speed(s):             $($ramInfo.SpeedsMHz) MHz

============================================================
SLOT DETAILS
============================================================

"@
    
    foreach ($slot in $ramInfo.SlotDetails) {
        if ($slot.Status -eq "In Use") {
            $report += @"
Slot $($slot.Slot) - $($slot.DeviceLocator)
  Status:           In Use
  Capacity:         $($slot.CapacityGB) GB
  Type:             $($slot.Type)
  Speed:            $($slot.SpeedMHz) MHz
  Form Factor:      $($slot.FormFactor)
  Manufacturer:     $($slot.Manufacturer)
  Part Number:      $($slot.PartNumber)
  Serial Number:    $($slot.SerialNumber)
  
"@
        } else {
            $report += @"
Slot $($slot.Slot) - $($slot.DeviceLocator)
  Status:           Empty
  
"@
        }
    }
    
    $report += @"
============================================================
END OF REPORT
============================================================
"@
    
    try {
        $report | Out-File -FilePath $outputPath -Encoding UTF8
        Set-SouliTEKConsoleColor "Green"
        Write-Host ""
        Write-Host "Report exported successfully!" -ForegroundColor Green
        Write-Host ""
        Write-Host "File saved to:"
        Write-Host $outputPath
        Write-Host ""
        
        $open = Read-Host "Open file? (Y/N)"
        if ($open -eq 'Y' -or $open -eq 'y') {
            Start-Process $outputPath
        }
    }
    catch {
        Write-Host "Failed to export report: $_" -ForegroundColor Red
    }
    
    Write-Host ""
    Set-SouliTEKConsoleColor "White"
    Write-Host "Press any key to return to main menu..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# Function to export to CSV
function Export-RAMReportCSV {
    Clear-Host
    Show-SouliTEKBanner
    Set-SouliTEKConsoleColor "Blue"
    Write-Host ""
    Write-Host "========================================"
    Write-Host "   EXPORT RAM REPORT - CSV FORMAT"
    Write-Host "========================================"
    Write-Host ""
    
    $ramInfo = Get-RAMSlotInformation
    
    if (-not $ramInfo) {
        Write-Host "Failed to collect RAM information." -ForegroundColor Red
        Write-Host ""
        Set-SouliTEKConsoleColor "White"
        Write-Host "Press any key to return to main menu..."
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        return
    }
    
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $outputPath = "$env:USERPROFILE\Desktop\RAM_Slot_Report_$timestamp.csv"
    
    try {
        $ramInfo.SlotDetails | Export-Csv -Path $outputPath -NoTypeInformation -Encoding UTF8
        Set-SouliTEKConsoleColor "Green"
        Write-Host ""
        Write-Host "Report exported successfully!" -ForegroundColor Green
        Write-Host ""
        Write-Host "File saved to:"
        Write-Host $outputPath
        Write-Host ""
        
        # Also create summary CSV
        $summaryPath = "$env:USERPROFILE\Desktop\RAM_Slot_Summary_$timestamp.csv"
        $summary = [PSCustomObject]@{
            ComputerName = $ramInfo.ComputerName
            CollectionTime = $ramInfo.CollectionTime
            TotalSlots = $ramInfo.TotalSlots
            UsedSlots = $ramInfo.UsedSlots
            EmptySlots = $ramInfo.EmptySlots
            TotalCapacityGB = $ramInfo.TotalCapacityGB
            MemoryTypes = $ramInfo.Types
            SpeedsMHz = $ramInfo.SpeedsMHz
        }
        $summary | Export-Csv -Path $summaryPath -NoTypeInformation -Encoding UTF8
        
        Write-Host "Summary saved to:"
        Write-Host $summaryPath
        Write-Host ""
        
        $open = Read-Host "Open files? (Y/N)"
        if ($open -eq 'Y' -or $open -eq 'y') {
            Start-Process $outputPath
            Start-Sleep -Seconds 1
            Start-Process $summaryPath
        }
    }
    catch {
        Write-Host "Failed to export report: $_" -ForegroundColor Red
    }
    
    Write-Host ""
    Set-SouliTEKConsoleColor "White"
    Write-Host "Press any key to return to main menu..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# Function to export to HTML
function Export-RAMReportHTML {
    Clear-Host
    Show-SouliTEKBanner
    Set-SouliTEKConsoleColor "Blue"
    Write-Host ""
    Write-Host "========================================"
    Write-Host "   EXPORT RAM REPORT - HTML FORMAT"
    Write-Host "========================================"
    Write-Host ""
    
    $ramInfo = Get-RAMSlotInformation
    
    if (-not $ramInfo) {
        Write-Host "Failed to collect RAM information." -ForegroundColor Red
        Write-Host ""
        Set-SouliTEKConsoleColor "White"
        Write-Host "Press any key to return to main menu..."
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        return
    }
    
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $outputPath = "$env:USERPROFILE\Desktop\RAM_Slot_Report_$timestamp.html"
    
    $usedSlotsPercent = [math]::Round(($ramInfo.UsedSlots / $ramInfo.TotalSlots) * 100, 1)
    $emptySlotsPercent = [math]::Round(($ramInfo.EmptySlots / $ramInfo.TotalSlots) * 100, 1)
    
    $slotRows = ""
    foreach ($slot in $ramInfo.SlotDetails) {
        if ($slot.Status -eq "In Use") {
            $slotRows += @"
            <tr>
                <td>$($slot.Slot)</td>
                <td>$($slot.DeviceLocator)</td>
                <td class="status-good">In Use</td>
                <td>$($slot.CapacityGB) GB</td>
                <td>$($slot.Type)</td>
                <td>$($slot.SpeedMHz) MHz</td>
                <td>$($slot.FormFactor)</td>
                <td>$($slot.Manufacturer)</td>
                <td>$($slot.PartNumber)</td>
            </tr>
"@
        } else {
            $slotRows += @"
            <tr>
                <td>$($slot.Slot)</td>
                <td>$($slot.DeviceLocator)</td>
                <td class="status-bad">Empty</td>
                <td>-</td>
                <td>-</td>
                <td>-</td>
                <td>-</td>
                <td>-</td>
                <td>-</td>
            </tr>
"@
        }
    }
    
    $html = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>RAM Slot Utilization Report</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            padding: 20px;
            color: #333;
        }
        .container {
            max-width: 1400px;
            margin: 0 auto;
            background: white;
            border-radius: 10px;
            box-shadow: 0 10px 40px rgba(0,0,0,0.2);
            overflow: hidden;
        }
        .header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 30px;
            text-align: center;
        }
        .header h1 {
            font-size: 28px;
            margin-bottom: 10px;
        }
        .header p {
            font-size: 14px;
            opacity: 0.9;
        }
        .content {
            padding: 30px;
        }
        .summary-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 20px;
            margin-bottom: 30px;
        }
        .summary-card {
            background: #f8f9fa;
            border-left: 4px solid #667eea;
            padding: 20px;
            border-radius: 5px;
        }
        .summary-card h3 {
            color: #667eea;
            font-size: 14px;
            margin-bottom: 10px;
            text-transform: uppercase;
        }
        .summary-card .value {
            font-size: 24px;
            font-weight: bold;
            color: #333;
        }
        .summary-card .label {
            font-size: 12px;
            color: #666;
            margin-top: 5px;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 20px;
            background: white;
        }
        th {
            background: #667eea;
            color: white;
            padding: 12px;
            text-align: left;
            font-weight: 600;
            font-size: 13px;
        }
        td {
            padding: 10px 12px;
            border-bottom: 1px solid #e0e0e0;
            font-size: 13px;
        }
        tr:hover {
            background: #f8f9fa;
        }
        .status-good {
            color: #10b981;
            font-weight: bold;
        }
        .status-bad {
            color: #ef4444;
            font-weight: bold;
        }
        .footer {
            background: #f8f9fa;
            padding: 20px;
            text-align: center;
            color: #666;
            font-size: 12px;
            border-top: 1px solid #e0e0e0;
        }
        .footer a {
            color: #667eea;
            text-decoration: none;
        }
        .footer a:hover {
            text-decoration: underline;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>[RAM] Slot Utilization Report</h1>
            <p><strong>Computer:</strong> $($ramInfo.ComputerName) | <strong>Generated:</strong> $($ramInfo.CollectionTime)</p>
        </div>
        <div class="content">
            <div class="summary-grid">
                <div class="summary-card">
                    <h3>Total Slots</h3>
                    <div class="value">$($ramInfo.TotalSlots)</div>
                </div>
                <div class="summary-card">
                    <h3>Slots Used</h3>
                    <div class="value">$($ramInfo.UsedSlots)</div>
                    <div class="label">$usedSlotsPercent% utilization</div>
                </div>
                <div class="summary-card">
                    <h3>Slots Empty</h3>
                    <div class="value">$($ramInfo.EmptySlots)</div>
                    <div class="label">$emptySlotsPercent% available</div>
                </div>
                <div class="summary-card">
                    <h3>Total Capacity</h3>
                    <div class="value">$($ramInfo.TotalCapacityGB) GB</div>
                </div>
                <div class="summary-card">
                    <h3>Memory Type</h3>
                    <div class="value">$($ramInfo.Types)</div>
                </div>
                <div class="summary-card">
                    <h3>Speed</h3>
                    <div class="value">$($ramInfo.SpeedsMHz) MHz</div>
                </div>
            </div>
            
            <h2 style="margin-top: 30px; margin-bottom: 15px; color: #333;">Slot Details</h2>
            <table>
                <thead>
                    <tr>
                        <th>Slot</th>
                        <th>Location</th>
                        <th>Status</th>
                        <th>Capacity</th>
                        <th>Type</th>
                        <th>Speed</th>
                        <th>Form Factor</th>
                        <th>Manufacturer</th>
                        <th>Part Number</th>
                    </tr>
                </thead>
                <tbody>
$slotRows
                </tbody>
            </table>
        </div>
        <div class="footer">
            Generated by <a href="https://www.soulitek.co.il" target="_blank">SouliTEK All-In-One Scripts</a> | 
            Email: <a href="mailto:letstalk@soulitek.co.il">letstalk@soulitek.co.il</a> | 
            (C) 2025 Soulitek - All Rights Reserved
        </div>
    </div>
</body>
</html>
"@
    
    try {
        $html | Out-File -FilePath $outputPath -Encoding UTF8
        Set-SouliTEKConsoleColor "Green"
        Write-Host ""
        Write-Host "Report exported successfully!" -ForegroundColor Green
        Write-Host ""
        Write-Host "File saved to:"
        Write-Host $outputPath
        Write-Host ""
        
        $open = Read-Host "Open report in browser? (Y/N)"
        if ($open -eq 'Y' -or $open -eq 'y') {
            Start-Process $outputPath
        }
    }
    catch {
        Write-Host "Failed to export report: $_" -ForegroundColor Red
    }
    
    Write-Host ""
    Set-SouliTEKConsoleColor "White"
    Write-Host "Press any key to return to main menu..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# Function to export all formats
function Export-RAMReportAll {
    Clear-Host
    Show-SouliTEKBanner
    Set-SouliTEKConsoleColor "Magenta"
    Write-Host ""
    Write-Host "========================================"
    Write-Host "   EXPORT RAM REPORT - ALL FORMATS"
    Write-Host "========================================"
    Write-Host ""
    Write-Host "Generating reports in all formats..."
    Write-Host ""
    
    $ramInfo = Get-RAMSlotInformation
    
    if (-not $ramInfo) {
        Write-Host "Failed to collect RAM information." -ForegroundColor Red
        Write-Host ""
        Set-SouliTEKConsoleColor "White"
        Write-Host "Press any key to return to main menu..."
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        return
    }
    
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $basePath = "$env:USERPROFILE\Desktop"
    $filesCreated = @()
    
    # Export TXT
    Write-Host "Exporting TXT format..." -ForegroundColor Yellow
    try {
        $txtPath = "$basePath\RAM_Slot_Report_$timestamp.txt"
        $report = @"
============================================================
RAM SLOT UTILIZATION REPORT
============================================================
Generated by: SouliTEK All-In-One Scripts
Website: www.soulitek.co.il
Email: letstalk@soulitek.co.il

(C) 2025 Soulitek - All Rights Reserved

============================================================
REPORT INFORMATION
============================================================
Computer Name: $($ramInfo.ComputerName)
Collection Time: $($ramInfo.CollectionTime)

============================================================
SUMMARY
============================================================
Total Slots:          $($ramInfo.TotalSlots)
Slots Used:           $($ramInfo.UsedSlots) / $($ramInfo.TotalSlots)
Slots Empty:          $($ramInfo.EmptySlots)
Total Capacity:       $($ramInfo.TotalCapacityGB) GB
Memory Type(s):       $($ramInfo.Types)
Speed(s):             $($ramInfo.SpeedsMHz) MHz

============================================================
SLOT DETAILS
============================================================

"@
        foreach ($slot in $ramInfo.SlotDetails) {
            if ($slot.Status -eq "In Use") {
                $report += @"
Slot $($slot.Slot) - $($slot.DeviceLocator)
  Status:           In Use
  Capacity:         $($slot.CapacityGB) GB
  Type:             $($slot.Type)
  Speed:            $($slot.SpeedMHz) MHz
  Form Factor:      $($slot.FormFactor)
  Manufacturer:     $($slot.Manufacturer)
  Part Number:      $($slot.PartNumber)
  Serial Number:    $($slot.SerialNumber)
  
"@
            } else {
                $report += @"
Slot $($slot.Slot) - $($slot.DeviceLocator)
  Status:           Empty
  
"@
            }
        }
        $report += @"
============================================================
END OF REPORT
============================================================
"@
        $report | Out-File -FilePath $txtPath -Encoding UTF8
        $filesCreated += "RAM_Slot_Report_$timestamp.txt"
        Write-Host "  [OK] TXT exported" -ForegroundColor Green
    } catch {
        Write-Host "  [ERROR] TXT export failed: $_" -ForegroundColor Red
    }
    
    # Export CSV
    Write-Host "Exporting CSV format..." -ForegroundColor Yellow
    try {
        $csvPath = "$basePath\RAM_Slot_Report_$timestamp.csv"
        $ramInfo.SlotDetails | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
        $filesCreated += "RAM_Slot_Report_$timestamp.csv"
        
        $summaryPath = "$basePath\RAM_Slot_Summary_$timestamp.csv"
        $summary = [PSCustomObject]@{
            ComputerName = $ramInfo.ComputerName
            CollectionTime = $ramInfo.CollectionTime
            TotalSlots = $ramInfo.TotalSlots
            UsedSlots = $ramInfo.UsedSlots
            EmptySlots = $ramInfo.EmptySlots
            TotalCapacityGB = $ramInfo.TotalCapacityGB
            MemoryTypes = $ramInfo.Types
            SpeedsMHz = $ramInfo.SpeedsMHz
        }
        $summary | Export-Csv -Path $summaryPath -NoTypeInformation -Encoding UTF8
        $filesCreated += "RAM_Slot_Summary_$timestamp.csv"
        Write-Host "  [OK] CSV exported" -ForegroundColor Green
    } catch {
        Write-Host "  [ERROR] CSV export failed: $_" -ForegroundColor Red
    }
    
    # Export HTML
    Write-Host "Exporting HTML format..." -ForegroundColor Yellow
    try {
        $htmlPath = "$basePath\RAM_Slot_Report_$timestamp.html"
        $usedSlotsPercent = [math]::Round(($ramInfo.UsedSlots / $ramInfo.TotalSlots) * 100, 1)
        $emptySlotsPercent = [math]::Round(($ramInfo.EmptySlots / $ramInfo.TotalSlots) * 100, 1)
        
        $slotRows = ""
        foreach ($slot in $ramInfo.SlotDetails) {
            if ($slot.Status -eq "In Use") {
                $slotRows += @"
            <tr>
                <td>$($slot.Slot)</td>
                <td>$($slot.DeviceLocator)</td>
                <td class="status-good">In Use</td>
                <td>$($slot.CapacityGB) GB</td>
                <td>$($slot.Type)</td>
                <td>$($slot.SpeedMHz) MHz</td>
                <td>$($slot.FormFactor)</td>
                <td>$($slot.Manufacturer)</td>
                <td>$($slot.PartNumber)</td>
            </tr>
"@
            } else {
                $slotRows += @"
            <tr>
                <td>$($slot.Slot)</td>
                <td>$($slot.DeviceLocator)</td>
                <td class="status-bad">Empty</td>
                <td>-</td>
                <td>-</td>
                <td>-</td>
                <td>-</td>
                <td>-</td>
                <td>-</td>
            </tr>
"@
            }
        }
        
        $html = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>RAM Slot Utilization Report</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            padding: 20px;
            color: #333;
        }
        .container {
            max-width: 1400px;
            margin: 0 auto;
            background: white;
            border-radius: 10px;
            box-shadow: 0 10px 40px rgba(0,0,0,0.2);
            overflow: hidden;
        }
        .header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 30px;
            text-align: center;
        }
        .header h1 {
            font-size: 28px;
            margin-bottom: 10px;
        }
        .header p {
            font-size: 14px;
            opacity: 0.9;
        }
        .content {
            padding: 30px;
        }
        .summary-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 20px;
            margin-bottom: 30px;
        }
        .summary-card {
            background: #f8f9fa;
            border-left: 4px solid #667eea;
            padding: 20px;
            border-radius: 5px;
        }
        .summary-card h3 {
            color: #667eea;
            font-size: 14px;
            margin-bottom: 10px;
            text-transform: uppercase;
        }
        .summary-card .value {
            font-size: 24px;
            font-weight: bold;
            color: #333;
        }
        .summary-card .label {
            font-size: 12px;
            color: #666;
            margin-top: 5px;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 20px;
            background: white;
        }
        th {
            background: #667eea;
            color: white;
            padding: 12px;
            text-align: left;
            font-weight: 600;
            font-size: 13px;
        }
        td {
            padding: 10px 12px;
            border-bottom: 1px solid #e0e0e0;
            font-size: 13px;
        }
        tr:hover {
            background: #f8f9fa;
        }
        .status-good {
            color: #10b981;
            font-weight: bold;
        }
        .status-bad {
            color: #ef4444;
            font-weight: bold;
        }
        .footer {
            background: #f8f9fa;
            padding: 20px;
            text-align: center;
            color: #666;
            font-size: 12px;
            border-top: 1px solid #e0e0e0;
        }
        .footer a {
            color: #667eea;
            text-decoration: none;
        }
        .footer a:hover {
            text-decoration: underline;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>[RAM] Slot Utilization Report</h1>
            <p><strong>Computer:</strong> $($ramInfo.ComputerName) | <strong>Generated:</strong> $($ramInfo.CollectionTime)</p>
        </div>
        <div class="content">
            <div class="summary-grid">
                <div class="summary-card">
                    <h3>Total Slots</h3>
                    <div class="value">$($ramInfo.TotalSlots)</div>
                </div>
                <div class="summary-card">
                    <h3>Slots Used</h3>
                    <div class="value">$($ramInfo.UsedSlots)</div>
                    <div class="label">$usedSlotsPercent% utilization</div>
                </div>
                <div class="summary-card">
                    <h3>Slots Empty</h3>
                    <div class="value">$($ramInfo.EmptySlots)</div>
                    <div class="label">$emptySlotsPercent% available</div>
                </div>
                <div class="summary-card">
                    <h3>Total Capacity</h3>
                    <div class="value">$($ramInfo.TotalCapacityGB) GB</div>
                </div>
                <div class="summary-card">
                    <h3>Memory Type</h3>
                    <div class="value">$($ramInfo.Types)</div>
                </div>
                <div class="summary-card">
                    <h3>Speed</h3>
                    <div class="value">$($ramInfo.SpeedsMHz) MHz</div>
                </div>
            </div>
            
            <h2 style="margin-top: 30px; margin-bottom: 15px; color: #333;">Slot Details</h2>
            <table>
                <thead>
                    <tr>
                        <th>Slot</th>
                        <th>Location</th>
                        <th>Status</th>
                        <th>Capacity</th>
                        <th>Type</th>
                        <th>Speed</th>
                        <th>Form Factor</th>
                        <th>Manufacturer</th>
                        <th>Part Number</th>
                    </tr>
                </thead>
                <tbody>
$slotRows
                </tbody>
            </table>
        </div>
        <div class="footer">
            Generated by <a href="https://www.soulitek.co.il" target="_blank">SouliTEK All-In-One Scripts</a> | 
            Email: <a href="mailto:letstalk@soulitek.co.il">letstalk@soulitek.co.il</a> | 
            (C) 2025 Soulitek - All Rights Reserved
        </div>
    </div>
</body>
</html>
"@
        $html | Out-File -FilePath $htmlPath -Encoding UTF8
        $filesCreated += "RAM_Slot_Report_$timestamp.html"
        Write-Host "  [OK] HTML exported" -ForegroundColor Green
    } catch {
        Write-Host "  [ERROR] HTML export failed: $_" -ForegroundColor Red
    }
    
    Write-Host ""
    Set-SouliTEKConsoleColor "Green"
    Write-Host "========================================"
    Write-Host "   ALL REPORTS GENERATED"
    Write-Host "========================================"
    Write-Host ""
    Write-Host "All reports saved to Desktop:"
    foreach ($file in $filesCreated) {
        Write-Host "  - $file"
    }
    Write-Host ""
    
    $open = Read-Host "Open folder? (Y/N)"
    if ($open -eq 'Y' -or $open -eq 'y') {
        Start-Process $basePath
    }
    
    Write-Host ""
    Set-SouliTEKConsoleColor "White"
    Write-Host "Press any key to return to main menu..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# Function to show help
function Show-Help {
    Clear-Host
    Show-SouliTEKBanner
    Set-SouliTEKConsoleColor "Blue"
    Write-Host ""
    Write-Host "========================================"
    Write-Host "   RAM SLOT UTILIZATION REPORT - HELP"
    Write-Host "========================================"
    Write-Host ""
    Set-SouliTEKConsoleColor "White"
    Write-Host "OVERVIEW:"
    Write-Host "--------"
    Write-Host "This tool provides comprehensive analysis of your system's RAM slot"
    Write-Host "utilization, showing which slots are used vs empty, memory type"
    Write-Host "(DDR3/DDR4/DDR5), speed (MHz), and capacity per slot."
    Write-Host ""
    Write-Host "FEATURES:"
    Write-Host "--------"
    Write-Host "  [1] Display Report - View RAM slot information in console"
    Write-Host "  [2] Export to TXT  - Save detailed text report"
    Write-Host "  [3] Export to CSV  - Save data for spreadsheet analysis"
    Write-Host "  [4] Export to HTML - Generate professional web report"
    Write-Host "  [5] Export All     - Create all report formats at once"
    Write-Host ""
    Write-Host "INFORMATION DISPLAYED:"
    Write-Host "--------------------"
    Write-Host "  - Total slots available"
    Write-Host "  - Slots used vs empty"
    Write-Host "  - Memory type (DDR3/DDR4/DDR5)"
    Write-Host "  - Memory speed (MHz)"
    Write-Host "  - Capacity per slot (GB)"
    Write-Host "  - Form factor (DIMM, SODIMM, etc.)"
    Write-Host "  - Manufacturer and part numbers"
    Write-Host ""
    Write-Host "USE CASES:"
    Write-Host "---------"
    Write-Host "  - Hardware inventory and documentation"
    Write-Host "  - RAM upgrade planning"
    Write-Host "  - Troubleshooting memory issues"
    Write-Host "  - System compatibility checking"
    Write-Host "  - IT asset management"
    Write-Host ""
    Write-Host "REQUIREMENTS:"
    Write-Host "------------"
    Write-Host "  - Windows PowerShell 5.1 or later"
    Write-Host "  - Administrator privileges (recommended)"
    Write-Host "  - WMI access enabled"
    Write-Host ""
    Write-Host "SUPPORT:"
    Write-Host "-------"
    Write-Host "  Website: www.soulitek.co.il"
    Write-Host "  Email: letstalk@soulitek.co.il"
    Write-Host ""
    Write-Host "========================================"
    Write-Host ""
    Set-SouliTEKConsoleColor "White"
    Write-Host "Press any key to return to main menu..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# Function to show exit message
# Show-ExitMessage function - using Show-SouliTEKExitMessage from common module
function Show-ExitMessage {
    Show-SouliTEKExitMessage -ScriptPath $PSCommandPath -ToolName "SouliTEK RAM Slot Utilization Report"
}

# ============================================================
# MAIN EXECUTION
# ============================================================

# Show banner
Clear-Host
Show-ScriptBanner -ScriptName "RAM Slot Utilization Report" -Purpose "Analyze RAM slot usage and generate detailed reports"

Show-Disclaimer

# Main menu loop
do {
    $choice = Show-MainMenu
    
    switch ($choice) {
        "1" { Show-RAMReport }
        "2" { Export-RAMReportTXT }
        "3" { Export-RAMReportCSV }
        "4" { Export-RAMReportHTML }
        "5" { Export-RAMReportAll }
        "6" { Show-Help }
        "0" { 
            Show-ExitMessage
            break
        }
        default {
            Write-Ui -Message "Invalid choice. Please try again" -Level "ERROR"
            Start-Sleep -Seconds 2
        }
    }
} while ($choice -ne "0")

