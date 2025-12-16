# ============================================================
# WiFi Monitor - Professional Tool - by Soulitek.co.il
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
# This tool monitors WiFi connection status, signal strength,
# frequency band, and disconnection history.
# 
# Features: Signal Strength | Frequency Band | SSID | Disconnection History
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

# Import SouliTEK Common Functions
$CommonPath = Join-Path (Split-Path -Parent $PSScriptRoot) "modules\SouliTEK-Common.ps1"
if (Test-Path $CommonPath) {
    . $CommonPath
} else {
    Write-Warning "SouliTEK Common Functions not found at: $CommonPath"
    Write-Warning "Some functions may not work properly."
}

# Set window title
$Host.UI.RawUI.WindowTitle = "WiFi Monitor - SouliTEK"

# Global variables
$Script:WiFiData = @()
$Script:DisconnectionHistory = @()

# Function to display header - uses centralized module function
function Show-Header {
    Show-SouliTEKHeader -Title "WIFI MONITOR" -ClearHost -ShowBanner
    Write-Host "      Coded by: Soulitek.co.il" -ForegroundColor Yellow
    Write-Host "      IT Solutions for your business" -ForegroundColor Yellow
    Write-Host "      www.soulitek.co.il" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "      (C) 2025 Soulitek - All Rights Reserved" -ForegroundColor Gray
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
}

# Function to convert RSSI to percentage
function Convert-RSSIToPercentage {
    param([int]$RSSI)
    
    # RSSI typically ranges from -100 dBm (worst) to -30 dBm (best)
    # Convert to percentage: 0% at -100 dBm, 100% at -30 dBm
    if ($RSSI -ge -30) {
        return 100
    }
    elseif ($RSSI -le -100) {
        return 0
    }
    else {
        # Linear conversion: percentage = ((RSSI + 100) / 70) * 100
        $percentage = [math]::Round((($RSSI + 100) / 70) * 100, 1)
        return [math]::Max(0, [math]::Min(100, $percentage))
    }
}

# Function to determine frequency band from channel
function Get-FrequencyBand {
    param([int]$Channel)
    
    # Channels 1-14 are 2.4 GHz
    # Channels 36+ are 5 GHz
    if ($Channel -ge 1 -and $Channel -le 14) {
        return "2.4 GHz"
    }
    elseif ($Channel -ge 36) {
        return "5 GHz"
    }
    else {
        return "Unknown"
    }
}

# Function to get current WiFi connection info
function Get-CurrentWiFiInfo {
    try {
        $output = netsh wlan show interfaces 2>&1
        
        if ($LASTEXITCODE -ne 0) {
            return $null
        }
        
        $wifiInfo = @{
            SSID = $null
            Signal = $null
            RSSI = $null
            SignalPercentage = $null
            Channel = $null
            FrequencyBand = $null
            State = $null
            RadioType = $null
            Authentication = $null
            Cipher = $null
            ConnectionMode = $null
        }
        
        foreach ($line in $output) {
            if ($line -match "^\s+SSID\s+:\s+(.+)$") {
                $wifiInfo.SSID = $matches[1].Trim()
            }
            elseif ($line -match "^\s+Signal\s+:\s+(\d+)%") {
                $wifiInfo.Signal = [int]$matches[1]
            }
            elseif ($line -match "^\s+Signal\s+:\s+(\d+)\s+%") {
                $wifiInfo.Signal = [int]$matches[1]
            }
            elseif ($line -match "^\s+Radio type\s+:\s+(.+)$") {
                $wifiInfo.RadioType = $matches[1].Trim()
            }
            elseif ($line -match "^\s+Channel\s+:\s+(\d+)") {
                $wifiInfo.Channel = [int]$matches[1]
            }
            elseif ($line -match "^\s+State\s+:\s+(.+)$") {
                $wifiInfo.State = $matches[1].Trim()
            }
            elseif ($line -match "^\s+Authentication\s+:\s+(.+)$") {
                $wifiInfo.Authentication = $matches[1].Trim()
            }
            elseif ($line -match "^\s+Cipher\s+:\s+(.+)$") {
                $wifiInfo.Cipher = $matches[1].Trim()
            }
            elseif ($line -match "^\s+Connection mode\s+:\s+(.+)$") {
                $wifiInfo.ConnectionMode = $matches[1].Trim()
            }
        }
        
        # Try to get RSSI from signal percentage if available
        if ($wifiInfo.Signal -and -not $wifiInfo.RSSI) {
            # Approximate RSSI from signal percentage
            # Signal 100% ≈ -30 dBm, Signal 0% ≈ -100 dBm
            $wifiInfo.RSSI = [math]::Round(-30 - ((100 - $wifiInfo.Signal) * 0.7), 0)
            $wifiInfo.SignalPercentage = $wifiInfo.Signal
        }
        elseif ($wifiInfo.RSSI) {
            $wifiInfo.SignalPercentage = Convert-RSSIToPercentage -RSSI $wifiInfo.RSSI
        }
        
        # Determine frequency band from channel
        if ($wifiInfo.Channel) {
            $wifiInfo.FrequencyBand = Get-FrequencyBand -Channel $wifiInfo.Channel
        }
        elseif ($wifiInfo.RadioType) {
            # Try to extract from Radio type (e.g., "802.11n 2.4GHz")
            if ($wifiInfo.RadioType -match "2\.4") {
                $wifiInfo.FrequencyBand = "2.4 GHz"
            }
            elseif ($wifiInfo.RadioType -match "5") {
                $wifiInfo.FrequencyBand = "5 GHz"
            }
        }
        
        return $wifiInfo
    }
    catch {
        Write-Ui -Message "Error getting WiFi info: $_" -Level "ERROR"
        return $null
    }
}

# Function to get WiFi disconnection history
function Get-WiFiDisconnectionHistory {
    param([int]$Days = 30)
    
    $disconnections = @()
    $startTime = (Get-Date).AddDays(-$Days)
    
    try {
        # Try Microsoft-Windows-WLAN-AutoConfig/Operational log first
        $logName = "Microsoft-Windows-WLAN-AutoConfig/Operational"
        $logExists = Get-WinEvent -ListLog $logName -ErrorAction SilentlyContinue
        
        if ($logExists) {
            # Event ID 8001 = Disconnected, 8003 = Connected
            $filterHash = @{
                LogName = $logName
                ID = @(8001, 8003)
                StartTime = $startTime
            }
            
            $events = Get-WinEvent -FilterHashtable $filterHash -MaxEvents 1000 -ErrorAction SilentlyContinue
            
            if ($events) {
                foreach ($event in $events) {
                    $xml = [xml]$event.ToXml()
                    $eventData = @{}
                    
                    foreach ($data in $xml.Event.EventData.Data) {
                        $eventData[$data.Name] = $data.'#text'
                    }
                    
                    $disconnections += [PSCustomObject]@{
                        Time = $event.TimeCreated
                        EventID = $event.Id
                        Type = if ($event.Id -eq 8001) { "Disconnected" } else { "Connected" }
                        SSID = $eventData.SSID
                        InterfaceGUID = $eventData.InterfaceGuid
                        Reason = if ($eventData.ReasonCode) { $eventData.ReasonCode } else { "N/A" }
                    }
                }
            }
        }
        
        # Fallback to System log for WiFi adapter events
        if ($disconnections.Count -eq 0) {
            $systemLogFilter = @{
                LogName = "System"
                ProviderName = @("Microsoft-Windows-WLAN-AutoConfig", "e1cexpress")
                StartTime = $startTime
            }
            
            $systemEvents = Get-WinEvent -FilterHashtable $systemLogFilter -MaxEvents 500 -ErrorAction SilentlyContinue
            
            if ($systemEvents) {
                foreach ($event in $systemEvents) {
                    $message = $event.Message
                    if ($message -match "disconnect|disconnected|connection.*lost" -or $event.Id -eq 20001) {
                        $disconnections += [PSCustomObject]@{
                            Time = $event.TimeCreated
                            EventID = $event.Id
                            Type = "Disconnected"
                            SSID = "Unknown"
                            InterfaceGUID = "N/A"
                            Reason = $event.Message
                        }
                    }
                }
            }
        }
        
        # Sort by time (newest first)
        $disconnections = $disconnections | Sort-Object -Property Time -Descending
        
        return $disconnections
    }
    catch {
        Write-Ui -Message "Error getting disconnection history: $_" -Level "WARN"
        return @()
    }
}

# Function to show current WiFi status
function Show-CurrentWiFiStatus {
    Show-Header
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "   CURRENT WiFi CONNECTION STATUS" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    
    $wifiInfo = Get-CurrentWiFiInfo
    
    if (-not $wifiInfo -or -not $wifiInfo.SSID) {
        Write-Host "Not connected to any WiFi network!" -ForegroundColor Red
        Write-Host ""
        Write-Host "Please connect to a WiFi network first." -ForegroundColor Yellow
    }
    else {
        Write-Host "Network Information:" -ForegroundColor Cyan
        Write-Host "----------------------------------------" -ForegroundColor Gray
        Write-Host "SSID: " -NoNewline -ForegroundColor White
        Write-Host $wifiInfo.SSID -ForegroundColor Green
        Write-Host ""
        
        Write-Host "Signal Strength:" -ForegroundColor Cyan
        Write-Host "----------------------------------------" -ForegroundColor Gray
        if ($wifiInfo.SignalPercentage) {
            $signalColor = if ($wifiInfo.SignalPercentage -ge 70) { "Green" }
                          elseif ($wifiInfo.SignalPercentage -ge 40) { "Yellow" }
                          else { "Red" }
            Write-Host "Signal: " -NoNewline -ForegroundColor White
            Write-Host "$($wifiInfo.SignalPercentage)%" -ForegroundColor $signalColor
        }
        if ($wifiInfo.RSSI) {
            Write-Host "RSSI: " -NoNewline -ForegroundColor White
            Write-Host "$($wifiInfo.RSSI) dBm" -ForegroundColor Gray
        }
        Write-Host ""
        
        Write-Host "Frequency Band:" -ForegroundColor Cyan
        Write-Host "----------------------------------------" -ForegroundColor Gray
        if ($wifiInfo.FrequencyBand) {
            $bandColor = if ($wifiInfo.FrequencyBand -eq "5 GHz") { "Green" } else { "Yellow" }
            Write-Host "Band: " -NoNewline -ForegroundColor White
            Write-Host $wifiInfo.FrequencyBand -ForegroundColor $bandColor
            if ($wifiInfo.FrequencyBand -eq "2.4 GHz") {
                Write-Host "  Note: 2.4 GHz is slower and more crowded" -ForegroundColor Yellow
            }
            elseif ($wifiInfo.FrequencyBand -eq "5 GHz") {
                Write-Host "  Note: 5 GHz is faster and less crowded" -ForegroundColor Green
            }
        }
        if ($wifiInfo.Channel) {
            Write-Host "Channel: " -NoNewline -ForegroundColor White
            Write-Host $wifiInfo.Channel -ForegroundColor Gray
        }
        Write-Host ""
        
        Write-Host "Connection Details:" -ForegroundColor Cyan
        Write-Host "----------------------------------------" -ForegroundColor Gray
        if ($wifiInfo.State) {
            Write-Host "State: " -NoNewline -ForegroundColor White
            Write-Host $wifiInfo.State -ForegroundColor $(if ($wifiInfo.State -eq "connected") { "Green" } else { "Yellow" })
        }
        if ($wifiInfo.Authentication) {
            Write-Host "Authentication: " -NoNewline -ForegroundColor White
            Write-Host $wifiInfo.Authentication -ForegroundColor Gray
        }
        if ($wifiInfo.Cipher) {
            Write-Host "Cipher: " -NoNewline -ForegroundColor White
            Write-Host $wifiInfo.Cipher -ForegroundColor Gray
        }
        if ($wifiInfo.ConnectionMode) {
            Write-Host "Connection Mode: " -NoNewline -ForegroundColor White
            Write-Host $wifiInfo.ConnectionMode -ForegroundColor Gray
        }
        if ($wifiInfo.RadioType) {
            Write-Host "Radio Type: " -NoNewline -ForegroundColor White
            Write-Host $wifiInfo.RadioType -ForegroundColor Gray
        }
    }
    
    Write-Host ""
    Write-Host "Press any key to return to main menu..." -ForegroundColor Cyan
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# Function to show disconnection history
function Show-DisconnectionHistory {
    Show-Header
    Write-Host "========================================" -ForegroundColor Yellow
    Write-Host "   WiFi DISCONNECTION HISTORY" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Yellow
    Write-Host ""
    
    Write-Host "Scanning event logs for disconnection events..." -ForegroundColor Yellow
    Write-Host ""
    
    $history = Get-WiFiDisconnectionHistory -Days 30
    
    if ($history.Count -eq 0) {
        Write-Host "No disconnection events found in the last 30 days." -ForegroundColor Green
        Write-Host ""
        Write-Host "This could mean:" -ForegroundColor Yellow
        Write-Host "  - Stable WiFi connection" -ForegroundColor Gray
        Write-Host "  - Event logs not available" -ForegroundColor Gray
        Write-Host "  - No WiFi adapter present" -ForegroundColor Gray
    }
    else {
        Write-Host "Found $($history.Count) connection/disconnection events:" -ForegroundColor Cyan
        Write-Host ""
        
        $disconnectCount = ($history | Where-Object { $_.Type -eq "Disconnected" }).Count
        Write-Host "Total Disconnections: " -NoNewline -ForegroundColor White
        Write-Host $disconnectCount -ForegroundColor $(if ($disconnectCount -eq 0) { "Green" } elseif ($disconnectCount -lt 5) { "Yellow" } else { "Red" })
        Write-Host ""
        
        Write-Host "Recent Events (Last 20):" -ForegroundColor Cyan
        Write-Host "----------------------------------------" -ForegroundColor Gray
        
        $recentEvents = $history | Select-Object -First 20
        
        foreach ($event in $recentEvents) {
            $timeStr = $event.Time.ToString("yyyy-MM-dd HH:mm:ss")
            $typeColor = if ($event.Type -eq "Disconnected") { "Red" } else { "Green" }
            
            Write-Host "[$timeStr] " -NoNewline -ForegroundColor Gray
            Write-Host $event.Type -NoNewline -ForegroundColor $typeColor
            if ($event.SSID -and $event.SSID -ne "Unknown") {
                Write-Host " - SSID: $($event.SSID)" -ForegroundColor White
            }
            else {
                Write-Host "" -ForegroundColor White
            }
        }
        
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Yellow
        Write-Host "Disconnection Statistics:" -ForegroundColor Cyan
        Write-Host "----------------------------------------" -ForegroundColor Gray
        
        $disconnects = $history | Where-Object { $_.Type -eq "Disconnected" }
        if ($disconnects.Count -gt 0) {
            $bySSID = $disconnects | Group-Object -Property SSID | Sort-Object -Property Count -Descending
            
            Write-Host "Disconnections by Network:" -ForegroundColor White
            foreach ($group in $bySSID) {
                Write-Host "  $($group.Name): " -NoNewline -ForegroundColor Gray
                Write-Host "$($group.Count) times" -ForegroundColor Yellow
            }
        }
    }
    
    Write-Host ""
    Write-Host "Press any key to return to main menu..." -ForegroundColor Cyan
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# Function to show detailed WiFi information
function Show-DetailedWiFiInfo {
    Show-Header
    Write-Host "========================================" -ForegroundColor Magenta
    Write-Host "   DETAILED WiFi INFORMATION" -ForegroundColor Magenta
    Write-Host "========================================" -ForegroundColor Magenta
    Write-Host ""
    
    $wifiInfo = Get-CurrentWiFiInfo
    
    if (-not $wifiInfo -or -not $wifiInfo.SSID) {
        Write-Host "Not connected to any WiFi network!" -ForegroundColor Red
    }
    else {
        Write-Host "Full Network Details:" -ForegroundColor Cyan
        Write-Host "========================================" -ForegroundColor Gray
        Write-Host ""
        
        $details = @(
            @{Label = "SSID"; Value = $wifiInfo.SSID; Color = "Green"},
            @{Label = "Signal Strength"; Value = if ($wifiInfo.SignalPercentage) { "$($wifiInfo.SignalPercentage)%" } else { "N/A" }; Color = "White"},
            @{Label = "RSSI"; Value = if ($wifiInfo.RSSI) { "$($wifiInfo.RSSI) dBm" } else { "N/A" }; Color = "Gray"},
            @{Label = "Frequency Band"; Value = if ($wifiInfo.FrequencyBand) { $wifiInfo.FrequencyBand } else { "Unknown" }; Color = if ($wifiInfo.FrequencyBand -eq "5 GHz") { "Green" } else { "Yellow" }},
            @{Label = "Channel"; Value = if ($wifiInfo.Channel) { $wifiInfo.Channel } else { "N/A" }; Color = "Gray"},
            @{Label = "State"; Value = if ($wifiInfo.State) { $wifiInfo.State } else { "N/A" }; Color = "White"},
            @{Label = "Radio Type"; Value = if ($wifiInfo.RadioType) { $wifiInfo.RadioType } else { "N/A" }; Color = "Gray"},
            @{Label = "Authentication"; Value = if ($wifiInfo.Authentication) { $wifiInfo.Authentication } else { "N/A" }; Color = "Gray"},
            @{Label = "Cipher"; Value = if ($wifiInfo.Cipher) { $wifiInfo.Cipher } else { "N/A" }; Color = "Gray"},
            @{Label = "Connection Mode"; Value = if ($wifiInfo.ConnectionMode) { $wifiInfo.ConnectionMode } else { "N/A" }; Color = "Gray"}
        )
        
        foreach ($detail in $details) {
            Write-Host "$($detail.Label): " -NoNewline -ForegroundColor Cyan
            Write-Host $detail.Value -ForegroundColor $detail.Color
        }
        
        Write-Host ""
        Write-Host "Frequency Band Information:" -ForegroundColor Cyan
        Write-Host "----------------------------------------" -ForegroundColor Gray
        if ($wifiInfo.FrequencyBand -eq "2.4 GHz") {
            Write-Host "• 2.4 GHz Band Characteristics:" -ForegroundColor Yellow
            Write-Host "  - Slower speeds (up to ~150 Mbps)" -ForegroundColor Gray
            Write-Host "  - Better range and wall penetration" -ForegroundColor Gray
            Write-Host "  - More crowded (many devices use this band)" -ForegroundColor Gray
            Write-Host "  - Channels: 1-14" -ForegroundColor Gray
        }
        elseif ($wifiInfo.FrequencyBand -eq "5 GHz") {
            Write-Host "• 5 GHz Band Characteristics:" -ForegroundColor Green
            Write-Host "  - Faster speeds (up to ~1300+ Mbps)" -ForegroundColor Gray
            Write-Host "  - Less range and wall penetration" -ForegroundColor Gray
            Write-Host "  - Less crowded (fewer devices)" -ForegroundColor Gray
            Write-Host "  - Channels: 36+" -ForegroundColor Gray
        }
    }
    
    Write-Host ""
    Write-Host "Press any key to return to main menu..." -ForegroundColor Cyan
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# Function to export WiFi report
function Export-WiFiReport {
    Show-Header
    Write-Host "========================================" -ForegroundColor Yellow
    Write-Host "   EXPORT WiFi REPORT" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Yellow
    Write-Host ""
    
    $wifiInfo = Get-CurrentWiFiInfo
    $history = Get-WiFiDisconnectionHistory -Days 30
    
    Write-Host "Preparing export data..." -ForegroundColor Yellow
    Write-Host ""
    
    # Prepare export data as array of PSCustomObject
    $exportData = @()
    
    # Add current WiFi info
    if ($wifiInfo) {
        $exportData += [PSCustomObject]@{
            Type = "Current Connection"
            SSID = $wifiInfo.SSID
            SignalStrength = if ($wifiInfo.SignalPercentage) { "$($wifiInfo.SignalPercentage)%" } else { "N/A" }
            RSSI = if ($wifiInfo.RSSI) { "$($wifiInfo.RSSI) dBm" } else { "N/A" }
            FrequencyBand = if ($wifiInfo.FrequencyBand) { $wifiInfo.FrequencyBand } else { "Unknown" }
            Channel = if ($wifiInfo.Channel) { $wifiInfo.Channel.ToString() } else { "N/A" }
            State = if ($wifiInfo.State) { $wifiInfo.State } else { "N/A" }
            Authentication = if ($wifiInfo.Authentication) { $wifiInfo.Authentication } else { "N/A" }
            RadioType = if ($wifiInfo.RadioType) { $wifiInfo.RadioType } else { "N/A" }
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }
    }
    
    # Add disconnection history
    foreach ($event in $history) {
        $exportData += [PSCustomObject]@{
            Type = $event.Type
            SSID = if ($event.SSID) { $event.SSID } else { "Unknown" }
            SignalStrength = "N/A"
            RSSI = "N/A"
            FrequencyBand = "N/A"
            Channel = "N/A"
            State = "N/A"
            Authentication = "N/A"
            RadioType = "N/A"
            Timestamp = $event.Time.ToString("yyyy-MM-dd HH:mm:ss")
        }
    }
    
    if ($exportData.Count -eq 0) {
        Write-Host "No data to export!" -ForegroundColor Red
        Write-Host ""
        Write-Host "Please ensure you are connected to WiFi and try again." -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Press any key to return to main menu..." -ForegroundColor Cyan
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        return
    }
    
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $desktopPath = [Environment]::GetFolderPath("Desktop")
    
    $extraInfo = @{
        "Computer Name" = $env:COMPUTERNAME
        "User Name" = $env:USERNAME
        "Total Events" = $exportData.Count
        "Disconnections" = ($history | Where-Object { $_.Type -eq "Disconnected" }).Count
    }
    
    $columns = @("Type", "SSID", "SignalStrength", "RSSI", "FrequencyBand", "Channel", "State", "Authentication", "RadioType", "Timestamp")
    
    # Export to all formats
    $formats = @("TXT", "CSV", "HTML")
    foreach ($fmt in $formats) {
        $extension = switch ($fmt) {
            "TXT" { "txt" }
            "CSV" { "csv" }
            "HTML" { "html" }
        }
        
        $outputPath = Join-Path $desktopPath "WiFi_Monitor_Report_$timestamp.$extension"
        
        Export-SouliTEKReport -Data $exportData -Title "WiFi Monitor Report" -Format $fmt -OutputPath $outputPath -ExtraInfo $extraInfo -Columns $columns -OpenAfterExport:($formats.Count -eq 1)
    }
    
    Write-Host ""
    Write-Ui -Message "Export complete! Reports saved to Desktop" -Level "OK"
    Write-Host ""
    Write-Host "Press any key to return to main menu..." -ForegroundColor Cyan
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# Function to show help
function Show-Help {
    Show-Header
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "   HELP GUIDE" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "WHEN TO USE EACH OPTION:" -ForegroundColor Yellow
    Write-Host "----------------------------------------" -ForegroundColor Gray
    Write-Host ""
    Write-Host "[1] CURRENT WiFi STATUS" -ForegroundColor White
    Write-Host "    Use when: Need quick overview of current connection" -ForegroundColor Gray
    Write-Host "    Shows: SSID, Signal %, Frequency Band, Channel" -ForegroundColor Gray
    Write-Host ""
    Write-Host "[2] DISCONNECTION HISTORY" -ForegroundColor White
    Write-Host "    Use when: Troubleshooting WiFi stability issues" -ForegroundColor Gray
    Write-Host "    Shows: All disconnections in last 30 days" -ForegroundColor Gray
    Write-Host ""
    Write-Host "[3] DETAILED INFORMATION" -ForegroundColor White
    Write-Host "    Use when: Need complete technical details" -ForegroundColor Gray
    Write-Host "    Shows: All WiFi parameters and band characteristics" -ForegroundColor Gray
    Write-Host ""
    Write-Host "[4] EXPORT REPORT" -ForegroundColor White
    Write-Host "    Use when: Need to document or share WiFi status" -ForegroundColor Gray
    Write-Host "    Creates: TXT, CSV, and HTML reports on Desktop" -ForegroundColor Gray
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "SIGNAL STRENGTH GUIDE:" -ForegroundColor Yellow
    Write-Host "----------------------------------------" -ForegroundColor Gray
    Write-Host ""
    Write-Host "• 70-100%: Excellent signal (Green)" -ForegroundColor Green
    Write-Host "• 40-69%:  Good signal (Yellow)" -ForegroundColor Yellow
    Write-Host "• 0-39%:   Weak signal (Red)" -ForegroundColor Red
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "FREQUENCY BAND GUIDE:" -ForegroundColor Yellow
    Write-Host "----------------------------------------" -ForegroundColor Gray
    Write-Host ""
    Write-Host "• 2.4 GHz: Slower, better range, more crowded" -ForegroundColor Yellow
    Write-Host "• 5 GHz:   Faster, less range, less crowded" -ForegroundColor Green
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Press any key to return to main menu..." -ForegroundColor Cyan
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# Function to show main menu
function Show-MainMenu {
    Show-Header
    Write-Host "Select an option:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  [1] Current WiFi Status        - Show connection details" -ForegroundColor White
    Write-Host "  [2] Disconnection History      - View WiFi disconnection events" -ForegroundColor White
    Write-Host "  [3] Detailed Information       - Complete technical details" -ForegroundColor White
    Write-Host "  [4] Export Report              - Save report to Desktop" -ForegroundColor White
    Write-Host "  [5] Help                       - Usage guide" -ForegroundColor White
    Write-Host "  [0] Exit" -ForegroundColor White
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    $choice = Read-Host "Enter your choice (0-5)"
    
    return $choice
}

# Show banner
Clear-Host
Show-ScriptBanner -ScriptName "WiFi Monitor" -Purpose "Monitor WiFi connection status and disconnection history"

# Main script execution
# No admin required for this tool

# Main program loop
$running = $true
while ($running) {
    $choice = Show-MainMenu
    
    switch ($choice) {
        "1" { Show-CurrentWiFiStatus }
        "2" { Show-DisconnectionHistory }
        "3" { Show-DetailedWiFiInfo }
        "4" { Export-WiFiReport }
        "5" { Show-Help }
        "0" { 
            Show-SouliTEKExitMessage
            $running = $false
        }
        default {
            Write-Ui -Message "Invalid choice. Please try again" -Level "ERROR"
            Start-Sleep -Seconds 2
        }
    }
}

