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
    Show-Section "Ping Test - Advanced"
    Write-Ui -Message "Test network connectivity with ICMP echo requests" -Level "INFO"
    Write-Host ""
    
    $target = Read-Host "Enter hostname or IP address (e.g., google.com, 8.8.8.8)"
    
    if ([string]::IsNullOrWhiteSpace($target)) {
        Write-Ui -Message "No target specified" -Level "ERROR"
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
                Write-Ui -Message "Request timed out" -Level "ERROR"
            }
            
            if ($i -lt $count) { Start-Sleep -Milliseconds 1000 }
        }
        
        Write-Host ""
        Write-Host "============================================================" -ForegroundColor Cyan
        Write-Ui -Message "  PING STATISTICS FOR $target" -Level "INFO"
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
            Write-Ui -Message "Approximate round trip times in milliseconds:" -Level "STEP"
            Write-Ui -Message "    Minimum = ${min}ms, Maximum = ${max}ms, Average = ${avg}ms" -Level "WARN"
            
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
    Show-SouliTEKHeader -Title "TRACE ROUTE TEST" -Color Magenta -ClearHost -ShowBanner
    
    Write-Ui -Message "      Trace network path to destination" -Level "INFO"
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
    Write-Ui -Message "This may take 30-60 seconds..." -Level "WARN"
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
                Write-Ui -Message $line -Level "INFO"
                $traceDetails += "$line`n"
            }
            elseif ($line -match 'Trace complete' -or $line -match 'Tracing route') {
                Write-Ui -Message $line -Level "INFO"
                $traceDetails += "$line`n"
            }
            else {
                Write-Ui -Message $line -Level "INFO"
                $traceDetails += "$line`n"
            }
        }
        
        Write-Host ""
        Write-Host "============================================================" -ForegroundColor Cyan
        Write-Ui -Message "  TRACE ROUTE SUMMARY" -Level "INFO"
        Write-Host "============================================================" -ForegroundColor Cyan
        Write-Host ""
        Write-Ui -Message "Target: $target" -Level "STEP"
        Write-Ui -Message "Total Hops: $hopCount" -Level "WARN"
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
    Show-SouliTEKHeader -Title "DNS LOOKUP TEST" -Color Yellow -ClearHost -ShowBanner
    
    Write-Ui -Message "      Resolve domain names to IP addresses" -Level "INFO"
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
        
        Write-Ui -Message "DNS RESOLUTION RESULTS:" -Level "OK"
        Write-Host "============================================================" -ForegroundColor Cyan
        Write-Host ""
        
        $ipAddresses = @()
        $details = ""
        
        foreach ($record in $dnsResult) {
            switch ($record.Type) {
                "A" {
                    Write-Ui -Message "[IPv4 Address (A)]" -Level "INFO"
                    Write-Ui -Message "  IP: $($record.IPAddress)" -Level "STEP"
                    Write-Ui -Message "  Name: $($record.Name)" -Level "INFO"
                    Write-Ui -Message "  TTL: $($record.TTL) seconds" -Level "INFO"
                    Write-Host ""
                    $ipAddresses += $record.IPAddress
                    $details += "A: $($record.IPAddress)`n"
                }
                "AAAA" {
                    Write-Ui -Message "[IPv6 Address (AAAA)]" -Level "INFO"
                    Write-Ui -Message "  IP: $($record.IPAddress)" -Level "STEP"
                    Write-Ui -Message "  Name: $($record.Name)" -Level "INFO"
                    Write-Ui -Message "  TTL: $($record.TTL) seconds" -Level "INFO"
                    Write-Host ""
                    $ipAddresses += $record.IPAddress
                    $details += "AAAA: $($record.IPAddress)`n"
                }
                "CNAME" {
                    Write-Ui -Message "[Canonical Name (CNAME)]" -Level "WARN"
                    Write-Ui -Message "  Alias: $($record.Name)" -Level "STEP"
                    Write-Ui -Message "  Points to: $($record.NameHost)" -Level "INFO"
                    Write-Host ""
                    $details += "CNAME: $($record.NameHost)`n"
                }
            }
        }
        
        Write-Host "============================================================" -ForegroundColor Cyan
        Write-Ui -Message "  DNS LOOKUP SUMMARY" -Level "INFO"
        Write-Host "============================================================" -ForegroundColor Cyan
        Write-Host ""
        Write-Ui -Message "Domain: $domain" -Level "STEP"
        Write-Ui -Message "Resolved IPs: $($ipAddresses.Count)" -Level "WARN"
        
        if ($ipAddresses.Count -gt 0) {
            Write-Host ""
            Write-Ui -Message "IP Addresses:" -Level "INFO"
            foreach ($ip in $ipAddresses) {
                Write-Ui -Message "  - $ip" -Level "OK"
            }
        }
        
        # Get DNS server being used
        Write-Host ""
        $dnsServers = Get-DnsClientServerAddress -AddressFamily IPv4 | Where-Object { $_.ServerAddresses.Count -gt 0 } | Select-Object -First 1
        if ($dnsServers) {
            Write-Ui -Message "DNS Server Used: $($dnsServers.ServerAddresses[0])" -Level "INFO"
        }
        
        Add-TestResult -TestType "DNS Lookup" -Target $domain -Result "Resolved: $($ipAddresses.Count) IPs" `
                      -Details $details -Status "Success"
        
        Write-Host ""
        Write-Host "============================================================" -ForegroundColor Cyan
    }
    catch {
        Write-SouliTEKResult "DNS lookup failed: $_" -Level ERROR
        Write-Host ""
        Write-Ui -Message "Possible reasons:" -Level "WARN"
        Write-Ui -Message "  - Domain does not exist" -Level "INFO"
        Write-Ui -Message "  - DNS server not responding" -Level "INFO"
        Write-Ui -Message "  - Network connectivity issue" -Level "INFO"
        Write-Ui -Message "  - DNS query blocked by firewall" -Level "INFO"
        
        Add-TestResult -TestType "DNS Lookup" -Target $domain -Result "Failed" -Details $_.Exception.Message -Status "Error"
    }
    
    Write-Host ""
    Read-Host "Press Enter to return to main menu"
}

function Test-Latency {
    Show-SouliTEKHeader -Title "LATENCY TEST - CONTINUOUS" -Color Red -ClearHost -ShowBanner
    
    Write-Ui -Message "      Monitor network latency in real-time" -Level "INFO"
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
    Write-Ui -Message "Press Ctrl+C to stop early" -Level "WARN"
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Ui -Message "Time      | Latency | Status | Jitter" -Level "INFO"
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
                Write-Ui -Message "N/A" -Level "INFO"
            }
            
            Start-Sleep -Seconds 1
        }
        
        Write-Host ""
        Write-Host "============================================================" -ForegroundColor Cyan
        Write-Ui -Message "  LATENCY TEST SUMMARY" -Level "INFO"
        Write-Host "============================================================" -ForegroundColor Cyan
        Write-Host ""
        
        if ($measurements.Count -gt 0) {
            $min = ($measurements | Measure-Object -Minimum).Minimum
            $max = ($measurements | Measure-Object -Maximum).Maximum
            $avg = [math]::Round(($measurements | Measure-Object -Average).Average, 2)
            $lossPercent = [math]::Round((($packetsSent - $packetsReceived) / $packetsSent) * 100, 2)
            
            Write-Ui -Message "Target: $target" -Level "STEP"
            Write-Ui -Message "Duration: $duration seconds" -Level "STEP"
            Write-Host ""
            Write-Ui -Message "Packets: Sent = $packetsSent, Received = $packetsReceived, Lost = $($packetsSent - $packetsReceived) ($lossPercent% loss)" -Level "WARN"
            Write-Host ""
            Write-Ui -Message "Latency Statistics:" -Level "INFO"
            Write-Ui -Message "  Minimum: ${min}ms" -Level "OK"
            Write-Ui -Message "  Maximum: ${max}ms" -Level "ERROR"
            Write-Ui -Message "  Average: ${avg}ms" -Level "WARN"
            
            # Calculate standard deviation
            $variance = 0
            foreach ($m in $measurements) {
                $variance += [Math]::Pow($m - $avg, 2)
            }
            $stdDev = [math]::Round([Math]::Sqrt($variance / $measurements.Count), 2)
            Write-Ui -Message "  Std Dev: ${stdDev}ms" -Level "INFO"
            
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
            Write-Ui -Message "No successful packets received" -Level "ERROR"
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
    Show-SouliTEKHeader -Title "QUICK NETWORK DIAGNOSTICS" -Color Cyan -ClearHost -ShowBanner
    
    Write-Ui -Message "      Run comprehensive network tests" -Level "INFO"
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    
    Write-SouliTEKResult "Starting quick diagnostics..." -Level INFO
    Write-Host ""
    
    # Test 1: Local connectivity
    Write-Ui -Message "[1/5] Testing local network connectivity..." -Level "WARN"
    $gateway = (Get-NetRoute -DestinationPrefix 0.0.0.0/0 | Select-Object -First 1).NextHop
    if ($gateway) {
        Write-Ui -Message "  Default Gateway: $gateway" -Level "INFO"
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
    Write-Ui -Message "[2/5] Testing internet connectivity..." -Level "WARN"
    $internetTest = Test-Connection -ComputerName 8.8.8.8 -Count 2 -Quiet
    if ($internetTest) {
        Write-SouliTEKResult "Internet connectivity: OK" -Level SUCCESS
    }
    else {
        Write-SouliTEKResult "Internet connectivity: FAILED" -Level ERROR
    }
    
    Write-Host ""
    
    # Test 3: DNS resolution
    Write-Ui -Message "[3/5] Testing DNS resolution..." -Level "WARN"
    try {
        $null = Resolve-DnsName -Name "google.com" -ErrorAction Stop
        Write-SouliTEKResult "DNS resolution: OK" -Level SUCCESS
    }
    catch {
        Write-SouliTEKResult "DNS resolution: FAILED" -Level ERROR
    }
    
    Write-Host ""
    
    # Test 4: Network adapters
    Write-Ui -Message "[4/5] Checking network adapters..." -Level "WARN"
    $adapters = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' }
    Write-Ui -Message "  Active adapters: $($adapters.Count)" -Level "INFO"
    foreach ($adapter in $adapters) {
        Write-Ui -Message "  - $($adapter.Name): $($adapter.LinkSpeed)" -Level "OK"
    }
    
    Write-Host ""
    
    # Test 5: DNS servers
    Write-Ui -Message "[5/5] Checking DNS servers..." -Level "WARN"
    $dnsServers = Get-DnsClientServerAddress -AddressFamily IPv4 | Where-Object { $_.ServerAddresses.Count -gt 0 }
    foreach ($dns in $dnsServers) {
        Write-Ui -Message "  $($dns.InterfaceAlias):" -Level "INFO"
        foreach ($server in $dns.ServerAddresses) {
            Write-Ui -Message "    - $server" -Level "OK"
        }
    }
    
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Ui -Message "  DIAGNOSTICS COMPLETE" -Level "INFO"
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
    Show-SouliTEKHeader -Title "EXPORT TEST RESULTS" -Color Yellow -ClearHost -ShowBanner
    
    Write-Ui -Message "      Save test results to file" -Level "INFO"
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    
    if ($Script:TestResults.Count -eq 0) {
        Write-SouliTEKResult "No test results to export" -Level WARNING
        Write-Host ""
        Write-Ui -Message "Run some network tests first, then export the results." -Level "WARN"
        Write-Host ""
        Start-Sleep -Seconds 3
        return
    }
    
    Write-Ui -Message "Total tests performed: $($Script:TestResults.Count)" -Level "INFO"
    Write-Host ""
    Write-Ui -Message "Select export format:" -Level "STEP"
    Write-Host ""
    Write-Ui -Message "  [1] Text File (.txt)" -Level "WARN"
    Write-Ui -Message "  [2] CSV File (.csv)" -Level "WARN"
    Write-Ui -Message "  [3] HTML Report (.html)" -Level "WARN"
    Write-Ui -Message "  [0] Cancel" -Level "ERROR"
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
                Start-Process $filePath
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
    Show-SouliTEKHeader -Title "NETWORK TEST TOOL - Professional Edition" -Color Cyan -ClearHost -ShowBanner
    
    Write-Ui -Message "      Coded by: Soulitek.co.il" -Level "OK"
    Write-Ui -Message "      IT Solutions for your business" -Level "OK"
    Write-Ui -Message "      www.soulitek.co.il" -Level "OK"
    Write-Host ""
    Write-Ui -Message "      (C) 2025 Soulitek - All Rights Reserved" -Level "INFO"
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    
    if ($Script:TestResults.Count -gt 0) {
        Write-Ui -Message "  Tests performed: $($Script:TestResults.Count)" -Level "WARN"
        Write-Host ""
    }
    
    Write-Ui -Message "Select an option:" -Level "STEP"
    Write-Host ""
    Write-Ui -Message "  [1] Ping Test            - Test connectivity to target" -Level "WARN"
    Write-Ui -Message "  [2] Trace Route          - Trace network path" -Level "WARN"
    Write-Ui -Message "  [3] DNS Lookup           - Resolve domain to IP" -Level "WARN"
    Write-Ui -Message "  [4] Latency Test         - Monitor latency in real-time" -Level "WARN"
    Write-Ui -Message "  [5] Quick Diagnostics    - Run all basic tests" -Level "WARN"
    Write-Ui -Message "  [6] Export Results       - Save test results to file" -Level "INFO"
    Write-Ui -Message "  [7] Clear Results        - Clear test history" -Level "INFO"
    Write-Ui -Message "  [8] Help                 - Usage guide" -Level "STEP"
    Write-Ui -Message "  [0] Exit" -Level "ERROR"
    Write-Host ""
    Write-Host "========================================" -ForegroundColor DarkGray
    
    $choice = Read-Host "Enter your choice (0-8)"
    return $choice
}

function Show-Help {
    Show-SouliTEKHeader -Title "HELP GUIDE" -Color Cyan -ClearHost -ShowBanner
    
    Write-Ui -Message "NETWORK TEST TOOL - USAGE GUIDE" -Level "WARN"
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Ui -Message "[1] PING TEST" -Level "STEP"
    Write-Ui -Message "    Test basic connectivity to a host" -Level "INFO"
    Write-Ui -Message "    Use: Check if a server/website is reachable" -Level "INFO"
    Write-Ui -Message "    Example targets: google.com, 8.8.8.8, 192.168.1.1" -Level "INFO"
    Write-Host ""
    Write-Ui -Message "[2] TRACE ROUTE" -Level "STEP"
    Write-Ui -Message "    Show the path packets take to reach destination" -Level "INFO"
    Write-Ui -Message "    Use: Identify where network issues occur" -Level "INFO"
    Write-Ui -Message "    Note: Can take 30-60 seconds to complete" -Level "INFO"
    Write-Host ""
    Write-Ui -Message "[3] DNS LOOKUP" -Level "STEP"
    Write-Ui -Message "    Resolve domain names to IP addresses" -Level "INFO"
    Write-Ui -Message "    Use: Check DNS resolution and find server IPs" -Level "INFO"
    Write-Ui -Message "    Shows: A records, AAAA records, CNAME records" -Level "INFO"
    Write-Host ""
    Write-Ui -Message "[4] LATENCY TEST" -Level "STEP"
    Write-Ui -Message "    Monitor network latency continuously" -Level "INFO"
    Write-Ui -Message "    Use: Check connection stability and jitter" -Level "INFO"
    Write-Ui -Message "    Shows: Real-time latency, jitter, packet loss" -Level "INFO"
    Write-Host ""
    Write-Ui -Message "[5] QUICK DIAGNOSTICS" -Level "STEP"
    Write-Ui -Message "    Run all basic network tests automatically" -Level "INFO"
    Write-Ui -Message "    Use: Quick check of overall network health" -Level "INFO"
    Write-Ui -Message "    Tests: Local network, Internet, DNS, Adapters" -Level "INFO"
    Write-Host ""
    Write-Ui -Message "[6] EXPORT RESULTS" -Level "STEP"
    Write-Ui -Message "    Save test results to file" -Level "INFO"
    Write-Ui -Message "    Formats: Text (.txt), CSV (.csv), HTML (.html)" -Level "INFO"
    Write-Ui -Message "    Use: Share results with IT support or for records" -Level "INFO"
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Ui -Message "INTERPRETING RESULTS:" -Level "WARN"
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Ui -Message "Latency (Ping Time):" -Level "STEP"
    Write-Ui -Message "  < 50ms   = Excellent (Green)" -Level "OK"
    Write-Ui -Message "  50-100ms = Good (Yellow)" -Level "WARN"
    Write-Ui -Message "  > 100ms  = Fair/Poor (Red)" -Level "ERROR"
    Write-Host ""
    Write-Ui -Message "Packet Loss:" -Level "STEP"
    Write-Ui -Message "  0%       = Perfect" -Level "OK"
    Write-Ui -Message "  < 1%     = Acceptable" -Level "WARN"
    Write-Ui -Message "  > 5%     = Problematic" -Level "ERROR"
    Write-Host ""
    Write-Ui -Message "Jitter (Latency variation):" -Level "STEP"
    Write-Ui -Message "  < 10ms   = Stable" -Level "OK"
    Write-Ui -Message "  10-30ms  = Moderate" -Level "WARN"
    Write-Ui -Message "  > 30ms   = Unstable" -Level "ERROR"
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Ui -Message "COMMON ISSUES:" -Level "WARN"
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Ui -Message "Timeout/Request failed:" -Level "ERROR"
    Write-Ui -Message "  - Target is offline or unreachable" -Level "INFO"
    Write-Ui -Message "  - Firewall blocking ICMP packets" -Level "INFO"
    Write-Ui -Message "  - Network cable unplugged" -Level "INFO"
    Write-Ui -Message "  - Wrong IP address/hostname" -Level "INFO"
    Write-Host ""
    Write-Ui -Message "High latency:" -Level "ERROR"
    Write-Ui -Message "  - Network congestion" -Level "INFO"
    Write-Ui -Message "  - Distance to server" -Level "INFO"
    Write-Ui -Message "  - WiFi interference" -Level "INFO"
    Write-Ui -Message "  - ISP throttling" -Level "INFO"
    Write-Host ""
    Write-Ui -Message "DNS lookup failed:" -Level "ERROR"
    Write-Ui -Message "  - Domain doesn't exist" -Level "INFO"
    Write-Ui -Message "  - DNS server not responding" -Level "INFO"
    Write-Ui -Message "  - DNS cache issues" -Level "INFO"
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Ui -Message "TIPS:" -Level "WARN"
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Ui -Message "- Test to multiple targets to isolate issues" -Level "INFO"
    Write-Ui -Message "- Export results before closing the tool" -Level "INFO"
    Write-Ui -Message "- Run latency test during peak hours" -Level "INFO"
    Write-Ui -Message "- Use trace route to find where delays occur" -Level "INFO"
    Write-Ui -Message "- Compare WiFi vs Ethernet results" -Level "INFO"
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Read-Host "Press Enter to return to main menu"
}

# Show-Disclaimer function - using Show-SouliTEKDisclaimer from common module
function Show-Disclaimer {
    Show-SouliTEKDisclaimer
}

# Show-ExitMessage function - using Show-SouliTEKExitMessage from common module
function Show-ExitMessage {
    Show-SouliTEKExitMessage -ScriptPath $PSCommandPath -ToolName "SouliTEK Network Test Tool"
}

# ============================================================
# MAIN EXECUTION
# ============================================================

# Show banner
Clear-Host
Show-ScriptBanner -ScriptName "Network Test Tool" -Purpose "Comprehensive network testing capabilities for troubleshooting connectivity and performance issues"

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
            Write-Ui -Message "Invalid choice. Please try again" -Level "ERROR"
            Start-Sleep -Seconds 2
        }
    }
} while ($choice -ne "0")
