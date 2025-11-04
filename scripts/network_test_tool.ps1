# ============================================================
# Network Test Tool - Professional Edition
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
# This tool provides comprehensive network testing capabilities
# for troubleshooting connectivity and performance issues.
# 
# Features: Ping Test | Traceroute | DNS Lookup | Latency Test
#           Connection Monitor | Export Results
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
$Host.UI.RawUI.WindowTitle = "NETWORK TEST TOOL"

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

$Script:TestResults = @()
$Script:OutputFolder = Join-Path $env:USERPROFILE "Desktop"

# ============================================================
# HELPER FUNCTIONS
# ============================================================



function Show-Header {
    param([string]$Title = "NETWORK TEST TOOL", [ConsoleColor]$Color = 'Cyan')
    
    Clear-Host
    Show-SouliTEKBanner
    Write-Host "============================================================" -ForegroundColor $Color
    Write-Host ""
    Write-Host "  $Title" -ForegroundColor $Color
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor $Color
    Write-Host ""
}

function Write-SouliTEKResult { param([string]$Message, [string]$Level = "INFO") Write-SouliTEKResult -Message $Message -Level $Level }

function Add-TestResult {
    param(
        [string]$TestType,
        [string]$Target,
        [string]$Result,
        [string]$Details,
        [string]$Status
    )
    
    $Script:TestResults += [PSCustomObject]@{
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        TestType = $TestType
        Target = $Target
        Result = $Result
        Details = $Details
        Status = $Status
    }
}

# ============================================================
# NETWORK TEST FUNCTIONS
# ============================================================

function Test-PingAdvanced {
    Show-Header "PING TEST - ADVANCED" -Color Green
    
    Write-Host "      Test network connectivity with ICMP echo requests" -ForegroundColor Gray
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    
    $target = Read-Host "Enter hostname or IP address (e.g., google.com, 8.8.8.8)"
    
    if ([string]::IsNullOrWhiteSpace($target)) {
        Write-SouliTEKResult "No target specified" -Level ERROR
        Start-Sleep -Seconds 2
        return
    }
    
    Write-Host ""
    $count = Read-Host "Number of ping requests (default: 4, max: 100)"
    if ([string]::IsNullOrWhiteSpace($count)) { $count = 4 }
    else { $count = [Math]::Min([int]$count, 100) }
    
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-SouliTEKResult "Starting ping test to $target..." -Level INFO
    Write-Host ""
    
    try {
        $sent = 0
        $received = 0
        $failed = 0
        $times = @()
        
        for ($i = 1; $i -le $count; $i++) {
            Write-Host "[$i/$count] " -NoNewline -ForegroundColor Gray
            
            $ping = Test-Connection -ComputerName $target -Count 1 -ErrorAction SilentlyContinue
            
            if ($ping) {
                $sent++
                $received++
                $responseTime = $ping.ResponseTime
                $times += $responseTime
                $ipAddress = $ping.Address
                
                $color = if ($responseTime -lt 50) { 'Green' } 
                         elseif ($responseTime -lt 100) { 'Yellow' } 
                         else { 'Red' }
                
                Write-Host "Reply from $ipAddress - Time: ${responseTime}ms - TTL: $($ping.TimeToLive)" -ForegroundColor $color
            }
            else {
                $sent++
                $failed++
                Write-Host "Request timed out" -ForegroundColor Red
            }
            
            if ($i -lt $count) { Start-Sleep -Milliseconds 1000 }
        }
        
        Write-Host ""
        Write-Host "============================================================" -ForegroundColor Cyan
        Write-Host "  PING STATISTICS FOR $target" -ForegroundColor Cyan
        Write-Host "============================================================" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Packets: Sent = $sent, Received = $received, Lost = $failed " -NoNewline
        
        $lossPercent = if ($sent -gt 0) { [math]::Round(($failed / $sent) * 100, 2) } else { 0 }
        Write-Host "($lossPercent% loss)" -ForegroundColor $(if ($lossPercent -eq 0) { 'Green' } else { 'Red' })
        
        if ($times.Count -gt 0) {
            $min = ($times | Measure-Object -Minimum).Minimum
            $max = ($times | Measure-Object -Maximum).Maximum
            $avg = [math]::Round(($times | Measure-Object -Average).Average, 2)
            
            Write-Host ""
            Write-Host "Approximate round trip times in milliseconds:" -ForegroundColor White
            Write-Host "    Minimum = ${min}ms, Maximum = ${max}ms, Average = ${avg}ms" -ForegroundColor Yellow
            
            $status = if ($lossPercent -eq 0 -and $avg -lt 100) { "Excellent" }
                     elseif ($lossPercent -lt 10 -and $avg -lt 200) { "Good" }
                     elseif ($lossPercent -lt 25) { "Fair" }
                     else { "Poor" }
            
            Write-Host ""
            Write-Host "Connection Quality: " -NoNewline
            $qualityColor = switch ($status) {
                "Excellent" { 'Green' }
                "Good" { 'Cyan' }
                "Fair" { 'Yellow' }
                default { 'Red' }
            }
            Write-Host $status -ForegroundColor $qualityColor
            
            Add-TestResult -TestType "Ping Test" -Target $target -Result "Sent: $sent, Received: $received, Lost: $failed" `
                          -Details "Min: ${min}ms, Max: ${max}ms, Avg: ${avg}ms, Loss: $lossPercent%" -Status $status
        }
        
        Write-Host ""
        Write-Host "============================================================" -ForegroundColor Cyan
    }
    catch {
        Write-SouliTEKResult "Ping test failed: $_" -Level ERROR
        Add-TestResult -TestType "Ping Test" -Target $target -Result "Failed" -Details $_.Exception.Message -Status "Error"
    }
    
    Write-Host ""
    Read-Host "Press Enter to return to main menu"
}

function Test-TraceRoute {
    Show-Header "TRACE ROUTE TEST" -Color Magenta
    
    Write-Host "      Trace network path to destination" -ForegroundColor Gray
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    
    $target = Read-Host "Enter hostname or IP address (e.g., google.com, 8.8.8.8)"
    
    if ([string]::IsNullOrWhiteSpace($target)) {
        Write-SouliTEKResult "No target specified" -Level ERROR
        Start-Sleep -Seconds 2
        return
    }
    
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-SouliTEKResult "Starting trace route to $target..." -Level INFO
    Write-Host ""
    Write-Host "This may take 30-60 seconds..." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    
    try {
        $traceOutput = tracert -d -h 30 $target
        
        $hopCount = 0
        $traceDetails = ""
        
        foreach ($line in $traceOutput) {
            if ($line -match '^\s+\d+\s+') {
                $hopCount++
                Write-Host $line -ForegroundColor Gray
                $traceDetails += "$line`n"
            }
            elseif ($line -match 'Trace complete' -or $line -match 'Tracing route') {
                Write-Host $line -ForegroundColor Cyan
                $traceDetails += "$line`n"
            }
            else {
                Write-Host $line -ForegroundColor Gray
                $traceDetails += "$line`n"
            }
        }
        
        Write-Host ""
        Write-Host "============================================================" -ForegroundColor Cyan
        Write-Host "  TRACE ROUTE SUMMARY" -ForegroundColor Cyan
        Write-Host "============================================================" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Target: $target" -ForegroundColor White
        Write-Host "Total Hops: $hopCount" -ForegroundColor Yellow
        Write-Host ""
        
        $status = if ($hopCount -gt 0 -and $hopCount -lt 30) { "Complete" } else { "Incomplete/Timeout" }
        Write-Host "Status: $status" -ForegroundColor $(if ($status -eq "Complete") { 'Green' } else { 'Yellow' })
        
        Add-TestResult -TestType "Trace Route" -Target $target -Result "Hops: $hopCount" `
                      -Details $traceDetails.Substring(0, [Math]::Min(500, $traceDetails.Length)) -Status $status
        
        Write-Host ""
        Write-Host "============================================================" -ForegroundColor Cyan
    }
    catch {
        Write-SouliTEKResult "Trace route failed: $_" -Level ERROR
        Add-TestResult -TestType "Trace Route" -Target $target -Result "Failed" -Details $_.Exception.Message -Status "Error"
    }
    
    Write-Host ""
    Read-Host "Press Enter to return to main menu"
}

function Test-DNSLookup {
    Show-Header "DNS LOOKUP TEST" -Color Yellow
    
    Write-Host "      Resolve domain names to IP addresses" -ForegroundColor Gray
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    
    $domain = Read-Host "Enter domain name (e.g., google.com, microsoft.com)"
    
    if ([string]::IsNullOrWhiteSpace($domain)) {
        Write-SouliTEKResult "No domain specified" -Level ERROR
        Start-Sleep -Seconds 2
        return
    }
    
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-SouliTEKResult "Performing DNS lookup for $domain..." -Level INFO
    Write-Host ""
    
    try {
        # Get DNS records
        $dnsResult = Resolve-DnsName -Name $domain -ErrorAction Stop
        
        Write-Host "DNS RESOLUTION RESULTS:" -ForegroundColor Green
        Write-Host "============================================================" -ForegroundColor Cyan
        Write-Host ""
        
        $ipAddresses = @()
        $details = ""
        
        foreach ($record in $dnsResult) {
            switch ($record.Type) {
                "A" {
                    Write-Host "[IPv4 Address (A)]" -ForegroundColor Cyan
                    Write-Host "  IP: $($record.IPAddress)" -ForegroundColor White
                    Write-Host "  Name: $($record.Name)" -ForegroundColor Gray
                    Write-Host "  TTL: $($record.TTL) seconds" -ForegroundColor Gray
                    Write-Host ""
                    $ipAddresses += $record.IPAddress
                    $details += "A: $($record.IPAddress)`n"
                }
                "AAAA" {
                    Write-Host "[IPv6 Address (AAAA)]" -ForegroundColor Cyan
                    Write-Host "  IP: $($record.IPAddress)" -ForegroundColor White
                    Write-Host "  Name: $($record.Name)" -ForegroundColor Gray
                    Write-Host "  TTL: $($record.TTL) seconds" -ForegroundColor Gray
                    Write-Host ""
                    $ipAddresses += $record.IPAddress
                    $details += "AAAA: $($record.IPAddress)`n"
                }
                "CNAME" {
                    Write-Host "[Canonical Name (CNAME)]" -ForegroundColor Yellow
                    Write-Host "  Alias: $($record.Name)" -ForegroundColor White
                    Write-Host "  Points to: $($record.NameHost)" -ForegroundColor Gray
                    Write-Host ""
                    $details += "CNAME: $($record.NameHost)`n"
                }
            }
        }
        
        Write-Host "============================================================" -ForegroundColor Cyan
        Write-Host "  DNS LOOKUP SUMMARY" -ForegroundColor Cyan
        Write-Host "============================================================" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Domain: $domain" -ForegroundColor White
        Write-Host "Resolved IPs: $($ipAddresses.Count)" -ForegroundColor Yellow
        
        if ($ipAddresses.Count -gt 0) {
            Write-Host ""
            Write-Host "IP Addresses:" -ForegroundColor Cyan
            foreach ($ip in $ipAddresses) {
                Write-Host "  - $ip" -ForegroundColor Green
            }
        }
        
        # Get DNS server being used
        Write-Host ""
        $dnsServers = Get-DnsClientServerAddress -AddressFamily IPv4 | Where-Object { $_.ServerAddresses.Count -gt 0 } | Select-Object -First 1
        if ($dnsServers) {
            Write-Host "DNS Server Used: $($dnsServers.ServerAddresses[0])" -ForegroundColor Gray
        }
        
        Add-TestResult -TestType "DNS Lookup" -Target $domain -Result "Resolved: $($ipAddresses.Count) IPs" `
                      -Details $details -Status "Success"
        
        Write-Host ""
        Write-Host "============================================================" -ForegroundColor Cyan
    }
    catch {
        Write-SouliTEKResult "DNS lookup failed: $_" -Level ERROR
        Write-Host ""
        Write-Host "Possible reasons:" -ForegroundColor Yellow
        Write-Host "  - Domain does not exist" -ForegroundColor Gray
        Write-Host "  - DNS server not responding" -ForegroundColor Gray
        Write-Host "  - Network connectivity issue" -ForegroundColor Gray
        Write-Host "  - DNS query blocked by firewall" -ForegroundColor Gray
        
        Add-TestResult -TestType "DNS Lookup" -Target $domain -Result "Failed" -Details $_.Exception.Message -Status "Error"
    }
    
    Write-Host ""
    Read-Host "Press Enter to return to main menu"
}

function Test-Latency {
    Show-Header "LATENCY TEST - CONTINUOUS" -Color Red
    
    Write-Host "      Monitor network latency in real-time" -ForegroundColor Gray
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    
    $target = Read-Host "Enter hostname or IP address (e.g., 8.8.8.8)"
    
    if ([string]::IsNullOrWhiteSpace($target)) {
        Write-SouliTEKResult "No target specified" -Level ERROR
        Start-Sleep -Seconds 2
        return
    }
    
    Write-Host ""
    $duration = Read-Host "Test duration in seconds (default: 30, max: 300)"
    if ([string]::IsNullOrWhiteSpace($duration)) { $duration = 30 }
    else { $duration = [Math]::Min([int]$duration, 300) }
    
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-SouliTEKResult "Starting latency test to $target for $duration seconds..." -Level INFO
    Write-Host ""
    Write-Host "Press Ctrl+C to stop early" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Time      | Latency | Status | Jitter" -ForegroundColor Cyan
    Write-Host "----------|---------|--------|--------" -ForegroundColor Cyan
    
    try {
        $startTime = Get-Date
        $endTime = $startTime.AddSeconds($duration)
        $measurements = @()
        $packetsSent = 0
        $packetsReceived = 0
        $previousLatency = 0
        
        while ((Get-Date) -lt $endTime) {
            $timestamp = Get-Date -Format "HH:mm:ss"
            $packetsSent++
            
            $ping = Test-Connection -ComputerName $target -Count 1 -ErrorAction SilentlyContinue
            
            if ($ping) {
                $packetsReceived++
                $latency = $ping.ResponseTime
                $measurements += $latency
                
                # Calculate jitter
                $jitter = if ($previousLatency -gt 0) { 
                    [Math]::Abs($latency - $previousLatency) 
                } else { 
                    0 
                }
                $previousLatency = $latency
                
                $color = if ($latency -lt 50) { 'Green' } 
                         elseif ($latency -lt 100) { 'Yellow' } 
                         else { 'Red' }
                
                $status = if ($latency -lt 50) { "Excellent" } 
                         elseif ($latency -lt 100) { "Good" } 
                         elseif ($latency -lt 200) { "Fair" } 
                         else { "Poor" }
                
                $jitterColor = if ($jitter -lt 10) { 'Green' } 
                              elseif ($jitter -lt 30) { 'Yellow' } 
                              else { 'Red' }
                
                Write-Host "$timestamp | " -NoNewline -ForegroundColor Gray
                Write-Host "$($latency.ToString().PadLeft(6))ms" -NoNewline -ForegroundColor $color
                Write-Host " | " -NoNewline -ForegroundColor Gray
                Write-Host "$($status.PadRight(7))" -NoNewline -ForegroundColor $color
                Write-Host " | " -NoNewline -ForegroundColor Gray
                Write-Host "${jitter}ms" -ForegroundColor $jitterColor
            }
            else {
                Write-Host "$timestamp | " -NoNewline -ForegroundColor Gray
                Write-Host "TIMEOUT" -NoNewline -ForegroundColor Red
                Write-Host " | " -NoNewline -ForegroundColor Gray
                Write-Host "Failed " -NoNewline -ForegroundColor Red
                Write-Host " | " -NoNewline -ForegroundColor Gray
                Write-Host "N/A" -ForegroundColor Gray
            }
            
            Start-Sleep -Seconds 1
        }
        
        Write-Host ""
        Write-Host "============================================================" -ForegroundColor Cyan
        Write-Host "  LATENCY TEST SUMMARY" -ForegroundColor Cyan
        Write-Host "============================================================" -ForegroundColor Cyan
        Write-Host ""
        
        if ($measurements.Count -gt 0) {
            $min = ($measurements | Measure-Object -Minimum).Minimum
            $max = ($measurements | Measure-Object -Maximum).Maximum
            $avg = [math]::Round(($measurements | Measure-Object -Average).Average, 2)
            $lossPercent = [math]::Round((($packetsSent - $packetsReceived) / $packetsSent) * 100, 2)
            
            Write-Host "Target: $target" -ForegroundColor White
            Write-Host "Duration: $duration seconds" -ForegroundColor White
            Write-Host ""
            Write-Host "Packets: Sent = $packetsSent, Received = $packetsReceived, Lost = $($packetsSent - $packetsReceived) ($lossPercent% loss)" -ForegroundColor Yellow
            Write-Host ""
            Write-Host "Latency Statistics:" -ForegroundColor Cyan
            Write-Host "  Minimum: ${min}ms" -ForegroundColor Green
            Write-Host "  Maximum: ${max}ms" -ForegroundColor Red
            Write-Host "  Average: ${avg}ms" -ForegroundColor Yellow
            
            # Calculate standard deviation
            $variance = 0
            foreach ($m in $measurements) {
                $variance += [Math]::Pow($m - $avg, 2)
            }
            $stdDev = [math]::Round([Math]::Sqrt($variance / $measurements.Count), 2)
            Write-Host "  Std Dev: ${stdDev}ms" -ForegroundColor Cyan
            
            Write-Host ""
            $overallQuality = if ($avg -lt 50 -and $lossPercent -eq 0) { "Excellent" }
                            elseif ($avg -lt 100 -and $lossPercent -lt 1) { "Good" }
                            elseif ($avg -lt 200 -and $lossPercent -lt 5) { "Fair" }
                            else { "Poor" }
            
            Write-Host "Overall Quality: " -NoNewline
            $qualityColor = switch ($overallQuality) {
                "Excellent" { 'Green' }
                "Good" { 'Cyan' }
                "Fair" { 'Yellow' }
                default { 'Red' }
            }
            Write-Host $overallQuality -ForegroundColor $qualityColor
            
            Add-TestResult -TestType "Latency Test" -Target $target `
                          -Result "Duration: ${duration}s, Packets: $packetsReceived/$packetsSent" `
                          -Details "Min: ${min}ms, Max: ${max}ms, Avg: ${avg}ms, StdDev: ${stdDev}ms, Loss: $lossPercent%" `
                          -Status $overallQuality
        }
        else {
            Write-Host "No successful packets received" -ForegroundColor Red
            Add-TestResult -TestType "Latency Test" -Target $target -Result "No packets received" `
                          -Details "All packets lost" -Status "Failed"
        }
        
        Write-Host ""
        Write-Host "============================================================" -ForegroundColor Cyan
    }
    catch {
        Write-SouliTEKResult "Latency test failed: $_" -Level ERROR
        Add-TestResult -TestType "Latency Test" -Target $target -Result "Failed" -Details $_.Exception.Message -Status "Error"
    }
    
    Write-Host ""
    Read-Host "Press Enter to return to main menu"
}

function Test-QuickDiagnostics {
    Show-Header "QUICK NETWORK DIAGNOSTICS" -Color Cyan
    
    Write-Host "      Run comprehensive network tests" -ForegroundColor Gray
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    
    Write-SouliTEKResult "Starting quick diagnostics..." -Level INFO
    Write-Host ""
    
    # Test 1: Local connectivity
    Write-Host "[1/5] Testing local network connectivity..." -ForegroundColor Yellow
    $gateway = (Get-NetRoute -DestinationPrefix 0.0.0.0/0 | Select-Object -First 1).NextHop
    if ($gateway) {
        Write-Host "  Default Gateway: $gateway" -ForegroundColor Gray
        $gwPing = Test-Connection -ComputerName $gateway -Count 2 -Quiet
        if ($gwPing) {
            Write-SouliTEKResult "Local network: OK" -Level SUCCESS
        }
        else {
            Write-SouliTEKResult "Local network: FAILED" -Level ERROR
        }
    }
    else {
        Write-SouliTEKResult "No default gateway found" -Level WARNING
    }
    
    Write-Host ""
    
    # Test 2: Internet connectivity
    Write-Host "[2/5] Testing internet connectivity..." -ForegroundColor Yellow
    $internetTest = Test-Connection -ComputerName 8.8.8.8 -Count 2 -Quiet
    if ($internetTest) {
        Write-SouliTEKResult "Internet connectivity: OK" -Level SUCCESS
    }
    else {
        Write-SouliTEKResult "Internet connectivity: FAILED" -Level ERROR
    }
    
    Write-Host ""
    
    # Test 3: DNS resolution
    Write-Host "[3/5] Testing DNS resolution..." -ForegroundColor Yellow
    try {
        $null = Resolve-DnsName -Name "google.com" -ErrorAction Stop
        Write-SouliTEKResult "DNS resolution: OK" -Level SUCCESS
    }
    catch {
        Write-SouliTEKResult "DNS resolution: FAILED" -Level ERROR
    }
    
    Write-Host ""
    
    # Test 4: Network adapters
    Write-Host "[4/5] Checking network adapters..." -ForegroundColor Yellow
    $adapters = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' }
    Write-Host "  Active adapters: $($adapters.Count)" -ForegroundColor Gray
    foreach ($adapter in $adapters) {
        Write-Host "  - $($adapter.Name): $($adapter.LinkSpeed)" -ForegroundColor Green
    }
    
    Write-Host ""
    
    # Test 5: DNS servers
    Write-Host "[5/5] Checking DNS servers..." -ForegroundColor Yellow
    $dnsServers = Get-DnsClientServerAddress -AddressFamily IPv4 | Where-Object { $_.ServerAddresses.Count -gt 0 }
    foreach ($dns in $dnsServers) {
        Write-Host "  $($dns.InterfaceAlias):" -ForegroundColor Gray
        foreach ($server in $dns.ServerAddresses) {
            Write-Host "    - $server" -ForegroundColor Green
        }
    }
    
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "  DIAGNOSTICS COMPLETE" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
    
    $gwStatus = if ($gwPing) { 'OK' } else { 'FAIL' }
    $internetStatus = if ($internetTest) { 'OK' } else { 'FAIL' }
    
    Add-TestResult -TestType "Quick Diagnostics" -Target "Local Network" `
                  -Result "Gateway: $gwStatus, Internet: $internetStatus" `
                  -Details "Adapters: $($adapters.Count)" -Status "Complete"
    
    Write-Host ""
    Read-Host "Press Enter to return to main menu"
}

function Export-TestResults {
    Show-Header "EXPORT TEST RESULTS" -Color Yellow
    
    Write-Host "      Save test results to file" -ForegroundColor Gray
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    
    if ($Script:TestResults.Count -eq 0) {
        Write-SouliTEKResult "No test results to export" -Level WARNING
        Write-Host ""
        Write-Host "Run some network tests first, then export the results." -ForegroundColor Yellow
        Write-Host ""
        Start-Sleep -Seconds 3
        return
    }
    
    Write-Host "Total tests performed: $($Script:TestResults.Count)" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Select export format:" -ForegroundColor White
    Write-Host ""
    Write-Host "  [1] Text File (.txt)" -ForegroundColor Yellow
    Write-Host "  [2] CSV File (.csv)" -ForegroundColor Yellow
    Write-Host "  [3] HTML Report (.html)" -ForegroundColor Yellow
    Write-Host "  [0] Cancel" -ForegroundColor Red
    Write-Host ""
    
    $choice = Read-Host "Enter your choice (0-3)"
    
    try {
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        
        switch ($choice) {
            "1" {
                $fileName = "NetworkTest_Results_$timestamp.txt"
                $filePath = Join-Path $Script:OutputFolder $fileName
                
                $content = @()
                $content += "============================================================"
                $content += "    NETWORK TEST RESULTS - by Soulitek.co.il"
                $content += "============================================================"
                $content += ""
                $content += "Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
                $content += "Computer: $env:COMPUTERNAME"
                $content += "User: $env:USERNAME"
                $content += ""
                $content += "Total Tests: $($Script:TestResults.Count)"
                $content += ""
                $content += "============================================================"
                $content += ""
                
                foreach ($result in $Script:TestResults) {
                    $content += "[$($result.Timestamp)] $($result.TestType)"
                    $content += "Target: $($result.Target)"
                    $content += "Result: $($result.Result)"
                    $content += "Status: $($result.Status)"
                    $content += "Details: $($result.Details)"
                    $content += "------------------------------------------------------------"
                    $content += ""
                }
                
                $content += "============================================================"
                $content += "          END OF REPORT"
                $content += "============================================================"
                $content += ""
                $content += "Generated by Network Test Tool"
                $content += "Coded by: Soulitek.co.il"
                $content += "www.soulitek.co.il"
                
                $content | Out-File -FilePath $filePath -Encoding UTF8
                
                Write-Host ""
                Write-SouliTEKResult "Results exported to: $filePath" -Level SUCCESS
                Start-Sleep -Seconds 1
                Start-Process notepad.exe -ArgumentList $filePath
            }
            "2" {
                $fileName = "NetworkTest_Results_$timestamp.csv"
                $filePath = Join-Path $Script:OutputFolder $fileName
                
                $Script:TestResults | Export-Csv -Path $filePath -NoTypeInformation -Encoding UTF8
                
                Write-Host ""
                Write-SouliTEKResult "Results exported to: $filePath" -Level SUCCESS
                Start-Sleep -Seconds 1
                Start-Process $filePath
            }
            "3" {
                $fileName = "NetworkTest_Results_$timestamp.html"
                $filePath = Join-Path $Script:OutputFolder $fileName
                
                $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Network Test Results - $env:COMPUTERNAME</title>
    <style>
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin: 20px; background-color: #f5f5f5; }
        h1 { color: #2c3e50; border-bottom: 3px solid #3498db; padding-bottom: 10px; }
        .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; border-radius: 10px; margin-bottom: 30px; }
        .test-result { background-color: white; padding: 20px; margin-bottom: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .test-header { font-size: 18px; font-weight: bold; color: #34495e; margin-bottom: 10px; }
        .test-info { display: grid; grid-template-columns: 150px 1fr; gap: 10px; margin-top: 10px; }
        .test-label { font-weight: bold; color: #7f8c8d; }
        .status-excellent { color: #27ae60; font-weight: bold; }
        .status-good { color: #3498db; font-weight: bold; }
        .status-fair { color: #f39c12; font-weight: bold; }
        .status-poor { color: #e74c3c; font-weight: bold; }
        .status-error { color: #c0392b; font-weight: bold; }
        .footer { text-align: center; margin-top: 30px; color: #7f8c8d; font-size: 12px; }
    </style>
</head>
<body>
    <div class="header">
        <h1>[NETWORK] Test Results</h1>
        <p><strong>Computer:</strong> $env:COMPUTERNAME | <strong>User:</strong> $env:USERNAME</p>
        <p><strong>Generated:</strong> $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</p>
        <p><strong>Total Tests:</strong> $($Script:TestResults.Count)</p>
    </div>
"@
                
                foreach ($result in $Script:TestResults) {
                    $statusClass = switch ($result.Status) {
                        "Excellent" { "status-excellent" }
                        "Good" { "status-good" }
                        "Fair" { "status-fair" }
                        "Poor" { "status-poor" }
                        default { "status-error" }
                    }
                    
                    $html += @"
    <div class="test-result">
        <div class="test-header">$($result.TestType)</div>
        <div class="test-info">
            <div class="test-label">Timestamp:</div><div>$($result.Timestamp)</div>
            <div class="test-label">Target:</div><div>$($result.Target)</div>
            <div class="test-label">Result:</div><div>$($result.Result)</div>
            <div class="test-label">Status:</div><div class="$statusClass">$($result.Status)</div>
            <div class="test-label">Details:</div><div><pre style="margin:0;font-family:monospace;font-size:12px;">$($result.Details)</pre></div>
        </div>
    </div>
"@
                }
                
                $html += @"
    <div class="footer">
        <p>Generated by Network Test Tool | Coded by Soulitek.co.il</p>
        <p>www.soulitek.co.il | (C) 2025 Soulitek - All Rights Reserved</p>
    </div>
</body>
</html>
"@
                
                Set-Content -Path $filePath -Value $html -Encoding UTF8
                
                Write-Host ""
                Write-SouliTEKResult "Results exported to: $filePath" -Level SUCCESS
                Start-Sleep -Seconds 1
                Start-Process $filePath
            }
            "0" {
                return
            }
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

function Clear-TestResults {
    Write-Host ""
    $confirm = Read-Host "Clear all test results? (Y/N)"
    if ($confirm -eq 'Y' -or $confirm -eq 'y') {
        $Script:TestResults = @()
        Write-SouliTEKResult "Test results cleared" -Level SUCCESS
        Start-Sleep -Seconds 2
    }
}

# ============================================================
# MAIN MENU
# ============================================================

function Show-MainMenu {
    Show-Header "NETWORK TEST TOOL - Professional Edition" -Color Cyan
    
    Write-Host "      Coded by: Soulitek.co.il" -ForegroundColor Green
    Write-Host "      IT Solutions for your business" -ForegroundColor Green
    Write-Host "      www.soulitek.co.il" -ForegroundColor Green
    Write-Host ""
    Write-Host "      (C) 2025 Soulitek - All Rights Reserved" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    
    if ($Script:TestResults.Count -gt 0) {
        Write-Host "  Tests performed: $($Script:TestResults.Count)" -ForegroundColor Yellow
        Write-Host ""
    }
    
    Write-Host "Select an option:" -ForegroundColor White
    Write-Host ""
    Write-Host "  [1] Ping Test            - Test connectivity to target" -ForegroundColor Yellow
    Write-Host "  [2] Trace Route          - Trace network path" -ForegroundColor Yellow
    Write-Host "  [3] DNS Lookup           - Resolve domain to IP" -ForegroundColor Yellow
    Write-Host "  [4] Latency Test         - Monitor latency in real-time" -ForegroundColor Yellow
    Write-Host "  [5] Quick Diagnostics    - Run all basic tests" -ForegroundColor Yellow
    Write-Host "  [6] Export Results       - Save test results to file" -ForegroundColor Cyan
    Write-Host "  [7] Clear Results        - Clear test history" -ForegroundColor Magenta
    Write-Host "  [8] Help                 - Usage guide" -ForegroundColor White
    Write-Host "  [0] Exit" -ForegroundColor Red
    Write-Host ""
    Write-Host "========================================" -ForegroundColor DarkGray
    
    $choice = Read-Host "Enter your choice (0-8)"
    return $choice
}

function Show-Help {
    Show-Header "HELP GUIDE" -Color Cyan
    
    Write-Host "NETWORK TEST TOOL - USAGE GUIDE" -ForegroundColor Yellow
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "[1] PING TEST" -ForegroundColor White
    Write-Host "    Test basic connectivity to a host" -ForegroundColor Gray
    Write-Host "    Use: Check if a server/website is reachable" -ForegroundColor Gray
    Write-Host "    Example targets: google.com, 8.8.8.8, 192.168.1.1" -ForegroundColor Gray
    Write-Host ""
    Write-Host "[2] TRACE ROUTE" -ForegroundColor White
    Write-Host "    Show the path packets take to reach destination" -ForegroundColor Gray
    Write-Host "    Use: Identify where network issues occur" -ForegroundColor Gray
    Write-Host "    Note: Can take 30-60 seconds to complete" -ForegroundColor Gray
    Write-Host ""
    Write-Host "[3] DNS LOOKUP" -ForegroundColor White
    Write-Host "    Resolve domain names to IP addresses" -ForegroundColor Gray
    Write-Host "    Use: Check DNS resolution and find server IPs" -ForegroundColor Gray
    Write-Host "    Shows: A records, AAAA records, CNAME records" -ForegroundColor Gray
    Write-Host ""
    Write-Host "[4] LATENCY TEST" -ForegroundColor White
    Write-Host "    Monitor network latency continuously" -ForegroundColor Gray
    Write-Host "    Use: Check connection stability and jitter" -ForegroundColor Gray
    Write-Host "    Shows: Real-time latency, jitter, packet loss" -ForegroundColor Gray
    Write-Host ""
    Write-Host "[5] QUICK DIAGNOSTICS" -ForegroundColor White
    Write-Host "    Run all basic network tests automatically" -ForegroundColor Gray
    Write-Host "    Use: Quick check of overall network health" -ForegroundColor Gray
    Write-Host "    Tests: Local network, Internet, DNS, Adapters" -ForegroundColor Gray
    Write-Host ""
    Write-Host "[6] EXPORT RESULTS" -ForegroundColor White
    Write-Host "    Save test results to file" -ForegroundColor Gray
    Write-Host "    Formats: Text (.txt), CSV (.csv), HTML (.html)" -ForegroundColor Gray
    Write-Host "    Use: Share results with IT support or for records" -ForegroundColor Gray
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "INTERPRETING RESULTS:" -ForegroundColor Yellow
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Latency (Ping Time):" -ForegroundColor White
    Write-Host "  < 50ms   = Excellent (Green)" -ForegroundColor Green
    Write-Host "  50-100ms = Good (Yellow)" -ForegroundColor Yellow
    Write-Host "  > 100ms  = Fair/Poor (Red)" -ForegroundColor Red
    Write-Host ""
    Write-Host "Packet Loss:" -ForegroundColor White
    Write-Host "  0%       = Perfect" -ForegroundColor Green
    Write-Host "  < 1%     = Acceptable" -ForegroundColor Yellow
    Write-Host "  > 5%     = Problematic" -ForegroundColor Red
    Write-Host ""
    Write-Host "Jitter (Latency variation):" -ForegroundColor White
    Write-Host "  < 10ms   = Stable" -ForegroundColor Green
    Write-Host "  10-30ms  = Moderate" -ForegroundColor Yellow
    Write-Host "  > 30ms   = Unstable" -ForegroundColor Red
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "COMMON ISSUES:" -ForegroundColor Yellow
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Timeout/Request failed:" -ForegroundColor Red
    Write-Host "  - Target is offline or unreachable" -ForegroundColor Gray
    Write-Host "  - Firewall blocking ICMP packets" -ForegroundColor Gray
    Write-Host "  - Network cable unplugged" -ForegroundColor Gray
    Write-Host "  - Wrong IP address/hostname" -ForegroundColor Gray
    Write-Host ""
    Write-Host "High latency:" -ForegroundColor Red
    Write-Host "  - Network congestion" -ForegroundColor Gray
    Write-Host "  - Distance to server" -ForegroundColor Gray
    Write-Host "  - WiFi interference" -ForegroundColor Gray
    Write-Host "  - ISP throttling" -ForegroundColor Gray
    Write-Host ""
    Write-Host "DNS lookup failed:" -ForegroundColor Red
    Write-Host "  - Domain doesn't exist" -ForegroundColor Gray
    Write-Host "  - DNS server not responding" -ForegroundColor Gray
    Write-Host "  - DNS cache issues" -ForegroundColor Gray
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "TIPS:" -ForegroundColor Yellow
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "- Test to multiple targets to isolate issues" -ForegroundColor Gray
    Write-Host "- Export results before closing the tool" -ForegroundColor Gray
    Write-Host "- Run latency test during peak hours" -ForegroundColor Gray
    Write-Host "- Use trace route to find where delays occur" -ForegroundColor Gray
    Write-Host "- Compare WiFi vs Ethernet results" -ForegroundColor Gray
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
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
    Write-Host "  - You will use this tool responsibly" -ForegroundColor Gray
    Write-Host "  - You accept full responsibility for its use" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  This tool performs network tests and may generate" -ForegroundColor Yellow
    Write-Host "  network traffic. Do not use for malicious purposes." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Press any key to continue or Ctrl+C to cancel..." -ForegroundColor Cyan
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
}

function Show-ExitMessage {
    Clear-Host
    Write-Host ""
    Write-Host "Thank you for using SouliTEK Network Test Tool!" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Website: www.soulitek.co.il" -ForegroundColor Yellow
    Write-Host ""
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
        "1" { Test-PingAdvanced }
        "2" { Test-TraceRoute }
        "3" { Test-DNSLookup }
        "4" { Test-Latency }
        "5" { Test-QuickDiagnostics }
        "6" { Export-TestResults }
        "7" { Clear-TestResults }
        "8" { Show-Help }
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




