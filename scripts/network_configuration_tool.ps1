# ============================================================
# Network Configuration Tool - Professional Edition
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
# This tool provides comprehensive network configuration management
# for viewing and modifying network adapter settings.
# 
# Features: View IP Configuration | Set Static IP | Flush DNS Cache
#           Reset Network Adapter | Export Configuration
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
# WARNING:
# Modifying network settings can cause loss of connectivity.
# Always ensure you have the correct network information
# before making changes. Have a backup plan to restore settings.
# 
# ============================================================

# Set window title
$Host.UI.RawUI.WindowTitle = "NETWORK CONFIGURATION TOOL"

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

$Script:ConfigResults = @()
$Script:OutputFolder = Join-Path $env:USERPROFILE "Desktop"

# ============================================================
# HELPER FUNCTIONS
# ============================================================

# Show-Header function removed - using Show-SouliTEKHeader from common module

# Use Test-SouliTEKAdministrator from common module
function Test-Administrator {
    return Test-SouliTEKAdministrator
}

function Get-NetworkAdapters {
    return Get-NetAdapter | Where-Object { $_.Status -eq 'Up' -or $_.Status -eq 'Disabled' } | Sort-Object Name
}

function Select-NetworkAdapter {
    Show-SouliTEKHeader -Title "SELECT NETWORK ADAPTER" -Color Yellow -ClearHost -ShowBanner
    
    $adapters = Get-NetworkAdapters
    
    if ($adapters.Count -eq 0) {
        Write-Ui -Message "No network adapters found!" -Level "ERROR"
        Write-Host ""
        Read-Host "Press Enter to return to main menu"
        return $null
    }
    
    Write-Ui -Message "Available Network Adapters:" -Level "INFO"
    Write-Host "============================================================" -ForegroundColor Gray
    Write-Host ""
    
    $index = 1
    $adapterList = @()
    
    foreach ($adapter in $adapters) {
        $statusColor = if ($adapter.Status -eq 'Up') { 'Green' } else { 'Yellow' }
        Write-Ui -Message "[$index] $($adapter.Name)" -Level "STEP"
        Write-Host "    Status: $($adapter.Status)" -ForegroundColor $statusColor
        Write-Ui -Message "    Interface: $($adapter.InterfaceDescription)" -Level "INFO"
        Write-Ui -Message "    Link Speed: $($adapter.LinkSpeed)" -Level "INFO"
        Write-Host ""
        
        $adapterList += $adapter
        $index++
    }
    
    Write-Host "============================================================" -ForegroundColor Gray
    Write-Host ""
    
    $selection = Read-Host "Select adapter number (1-$($adapters.Count))"
    
    try {
        $selectedIndex = [int]$selection - 1
        if ($selectedIndex -ge 0 -and $selectedIndex -lt $adapterList.Count) {
            return $adapterList[$selectedIndex]
        } else {
            Write-Ui -Message "Invalid selection!" -Level "ERROR"
            Start-Sleep -Seconds 2
            return $null
        }
    }
    catch {
        Write-Ui -Message "Invalid input!" -Level "ERROR"
        Start-Sleep -Seconds 2
        return $null
    }
}

# ============================================================
# NETWORK CONFIGURATION FUNCTIONS
# ============================================================

function Show-IPConfiguration {
    Show-SouliTEKHeader -Title "VIEW IP CONFIGURATION" -Color Green -ClearHost -ShowBanner
    
    $adapter = Select-NetworkAdapter
    if (-not $adapter) { return }
    
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Ui -Message "  IP CONFIGURATION FOR: $($adapter.Name)" -Level "INFO"
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    
    try {
        # Get IP configuration
        $ipConfig = Get-NetIPConfiguration -InterfaceAlias $adapter.Name -ErrorAction Stop
        
        Write-Ui -Message "Adapter Information:" -Level "WARN"
        Write-Host "----------------------------------------" -ForegroundColor Gray
        Write-Ui -Message "  Name: $($adapter.Name)" -Level "STEP"
        Write-Ui -Message "  Interface: $($adapter.InterfaceDescription)" -Level "STEP"
        Write-Host "  Status: $($adapter.Status)" -ForegroundColor $(if ($adapter.Status -eq 'Up') { 'Green' } else { 'Yellow' })
        Write-Ui -Message "  Link Speed: $($adapter.LinkSpeed)" -Level "STEP"
        Write-Ui -Message "  MAC Address: $($adapter.MacAddress)" -Level "STEP"
        Write-Host ""
        
        if ($ipConfig.IPv4Address) {
            Write-Ui -Message "IPv4 Configuration:" -Level "WARN"
            Write-Host "----------------------------------------" -ForegroundColor Gray
            Write-Ui -Message "  IP Address: $($ipConfig.IPv4Address.IPAddress)" -Level "OK"
            Write-Ui -Message "  Subnet Mask: $($ipConfig.IPv4Address.PrefixLength) bits" -Level "STEP"
            
            # Calculate subnet mask
            $prefixLength = $ipConfig.IPv4Address.PrefixLength
            $subnetMask = ([System.Net.IPAddress]::Parse(([System.Net.IPAddress]::HostToNetworkOrder(-1) -shl (32 - $prefixLength)) -band [System.Net.IPAddress]::HostToNetworkOrder(-1))).ToString()
            Write-Ui -Message "  Subnet Mask: $subnetMask" -Level "STEP"
            
            if ($ipConfig.IPv4DefaultGateway) {
                Write-Ui -Message "  Default Gateway: $($ipConfig.IPv4DefaultGateway.NextHop)" -Level "OK"
            } else {
                Write-Ui -Message "  Default Gateway: [Not configured]" -Level "WARN"
            }
            Write-Host ""
        } else {
            Write-Ui -Message "IPv4 Configuration: [Not configured]" -Level "WARN"
            Write-Host ""
        }
        
        if ($ipConfig.IPv6Address) {
            Write-Ui -Message "IPv6 Configuration:" -Level "WARN"
            Write-Host "----------------------------------------" -ForegroundColor Gray
            Write-Ui -Message "  IP Address: $($ipConfig.IPv6Address.IPAddress)" -Level "OK"
            Write-Ui -Message "  Prefix Length: $($ipConfig.IPv6Address.PrefixLength) bits" -Level "STEP"
            Write-Host ""
        }
        
        # Get DNS configuration
        $dnsConfig = Get-DnsClientServerAddress -InterfaceAlias $adapter.Name -AddressFamily IPv4 -ErrorAction SilentlyContinue
        
        Write-Ui -Message "DNS Configuration:" -Level "WARN"
        Write-Host "----------------------------------------" -ForegroundColor Gray
        
        if ($dnsConfig -and $dnsConfig.ServerAddresses.Count -gt 0) {
            Write-Ui -Message "  DNS Servers:" -Level "STEP"
            $dnsIndex = 1
            foreach ($dnsServer in $dnsConfig.ServerAddresses) {
                Write-Ui -Message "    [$dnsIndex] $dnsServer" -Level "OK"
                $dnsIndex++
            }
        } else {
            Write-Ui -Message "  DNS Servers: [Not configured]" -Level "WARN"
        }
        
        # Check if DHCP is enabled
        $dhcpEnabled = (Get-NetIPInterface -InterfaceAlias $adapter.Name -AddressFamily IPv4).Dhcp
        
        Write-Host ""
        Write-Ui -Message "IP Assignment:" -Level "WARN"
        Write-Host "----------------------------------------" -ForegroundColor Gray
        if ($dhcpEnabled -eq 'Enabled') {
            Write-Ui -Message "  Method: DHCP (Automatic)" -Level "OK"
        } else {
            Write-Ui -Message "  Method: Static (Manual)" -Level "INFO"
        }
        Write-Host ""
        
        # Store configuration for export
        $Script:ConfigResults += [PSCustomObject]@{
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            Operation = "View IP Configuration"
            Adapter = $adapter.Name
            IPv4Address = if ($ipConfig.IPv4Address) { $ipConfig.IPv4Address.IPAddress } else { "Not configured" }
            SubnetMask = if ($ipConfig.IPv4Address) { $subnetMask } else { "Not configured" }
            Gateway = if ($ipConfig.IPv4DefaultGateway) { $ipConfig.IPv4DefaultGateway.NextHop } else { "Not configured" }
            DNSServers = if ($dnsConfig -and $dnsConfig.ServerAddresses) { ($dnsConfig.ServerAddresses -join ', ') } else { "Not configured" }
            DHCP = if ($dhcpEnabled -eq 'Enabled') { "Enabled" } else { "Disabled" }
        }
        
        Write-Host "============================================================" -ForegroundColor Cyan
    }
    catch {
        Write-Ui -Message "Error retrieving IP configuration: $_" -Level "ERROR"
        Write-Host ""
    }
    
    Write-Host ""
    Read-Host "Press Enter to return to main menu"
}

function Set-StaticIP {
    Show-SouliTEKHeader -Title "SET STATIC IP ADDRESS" -Color Magenta -ClearHost -ShowBanner
    
    if (-not (Test-Administrator)) {
        Write-Ui -Message "WARNING: Administrator privileges required!" -Level "ERROR"
        Write-Host ""
        Write-Ui -Message "This operation requires administrator rights." -Level "WARN"
        Write-Ui -Message "Please run this script as Administrator." -Level "WARN"
        Write-Host ""
        Read-Host "Press Enter to return to main menu"
        return
    }
    
    $adapter = Select-NetworkAdapter
    if (-not $adapter) { return }
    
    # Get current configuration
    $currentConfig = Get-NetIPConfiguration -InterfaceAlias $adapter.Name -ErrorAction SilentlyContinue
    
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Ui -Message "  CONFIGURE STATIC IP ADDRESS" -Level "INFO"
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    
    if ($currentConfig.IPv4Address) {
        Write-Ui -Message "Current Configuration:" -Level "WARN"
        Write-Ui -Message "  IP Address: $($currentConfig.IPv4Address.IPAddress)" -Level "INFO"
        Write-Ui -Message "  Prefix Length: $($currentConfig.IPv4Address.PrefixLength)" -Level "INFO"
        if ($currentConfig.IPv4DefaultGateway) {
            Write-Ui -Message "  Gateway: $($currentConfig.IPv4DefaultGateway.NextHop)" -Level "INFO"
        }
        Write-Host ""
    }
    
    Write-Ui -Message "Enter new static IP configuration:" -Level "STEP"
    Write-Host ""
    
    # Get IP address
    $ipAddress = Read-Host "IP Address (e.g., 192.168.1.100)"
    if ([string]::IsNullOrWhiteSpace($ipAddress)) {
        Write-Ui -Message "IP address is required!" -Level "ERROR"
        Start-Sleep -Seconds 2
        return
    }
    
    # Validate IP address
    try {
        $null = [System.Net.IPAddress]::Parse($ipAddress)
    }
    catch {
        Write-Ui -Message "Invalid IP address format!" -Level "ERROR"
        Start-Sleep -Seconds 2
        return
    }
    
    # Get subnet mask / prefix length
    Write-Host ""
    Write-Ui -Message "Enter subnet mask:" -Level "STEP"
    Write-Ui -Message "  1. Use prefix length (e.g., 24 for 255.255.255.0)" -Level "INFO"
    Write-Ui -Message "  2. Use subnet mask (e.g., 255.255.255.0)" -Level "INFO"
    $subnetChoice = Read-Host "Choice (1 or 2, default: 1)"
    
    $prefixLength = $null
    if ([string]::IsNullOrWhiteSpace($subnetChoice) -or $subnetChoice -eq "1") {
        $prefixInput = Read-Host "Prefix Length (default: 24)"
        if ([string]::IsNullOrWhiteSpace($prefixInput)) {
            $prefixLength = 24
        } else {
            try {
                $prefixLength = [int]$prefixInput
                if ($prefixLength -lt 0 -or $prefixLength -gt 32) {
                    Write-Ui -Message "Prefix length must be between 0 and 32!" -Level "ERROR"
                    Start-Sleep -Seconds 2
                    return
                }
            }
            catch {
                Write-Ui -Message "Invalid prefix length!" -Level "ERROR"
                Start-Sleep -Seconds 2
                return
            }
        }
    } else {
        $subnetMask = Read-Host "Subnet Mask (e.g., 255.255.255.0)"
        try {
            $subnetIP = [System.Net.IPAddress]::Parse($subnetMask)
            $bytes = $subnetIP.GetAddressBytes()
            $prefixLength = 0
            foreach ($byte in $bytes) {
                $prefixLength += [Convert]::ToString($byte, 2).PadLeft(8, '0').Replace('0', '').Length
            }
        }
        catch {
            Write-Ui -Message "Invalid subnet mask format!" -Level "ERROR"
            Start-Sleep -Seconds 2
            return
        }
    }
    
    # Get default gateway (optional)
    Write-Host ""
    $gateway = Read-Host "Default Gateway (optional, press Enter to skip)"
    
    if (-not [string]::IsNullOrWhiteSpace($gateway)) {
        try {
            $null = [System.Net.IPAddress]::Parse($gateway)
        }
        catch {
            Write-Ui -Message "Invalid gateway IP address format!" -Level "ERROR"
            Start-Sleep -Seconds 2
            return
        }
    }
    
    # Get DNS servers (optional)
    Write-Host ""
    Write-Ui -Message "DNS Servers (optional):" -Level "STEP"
    $dns1 = Read-Host "  Primary DNS (press Enter to skip)"
    $dns2 = Read-Host "  Secondary DNS (press Enter to skip)"
    
    # Confirm configuration
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Ui -Message "  CONFIGURATION SUMMARY" -Level "INFO"
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Ui -Message "  Adapter: $($adapter.Name)" -Level "STEP"
    Write-Ui -Message "  IP Address: $ipAddress/$prefixLength" -Level "STEP"
    if ($gateway) {
        Write-Ui -Message "  Gateway: $gateway" -Level "STEP"
    }
    if ($dns1) {
        Write-Ui -Message "  Primary DNS: $dns1" -Level "STEP"
    }
    if ($dns2) {
        Write-Ui -Message "  Secondary DNS: $dns2" -Level "STEP"
    }
    Write-Host ""
    Write-Ui -Message "WARNING: This will change your network configuration!" -Level "ERROR"
    Write-Ui -Message "         You may lose connectivity if settings are incorrect." -Level "ERROR"
    Write-Host ""
    
    $confirm = Read-Host "Apply this configuration? (yes/no)"
    
    if ($confirm -ne "yes" -and $confirm -ne "y") {
        Write-Ui -Message "Configuration cancelled." -Level "WARN"
        Start-Sleep -Seconds 2
        return
    }
    
    Write-Host ""
    Write-Ui -Message "Applying configuration..." -Level "WARN"
    
    try {
        # Remove existing IP configuration
        Remove-NetIPAddress -InterfaceAlias $adapter.Name -Confirm:$false -ErrorAction SilentlyContinue
        
        # Remove existing gateway
        if ($currentConfig.IPv4DefaultGateway) {
            Remove-NetRoute -InterfaceAlias $adapter.Name -DestinationPrefix "0.0.0.0/0" -Confirm:$false -ErrorAction SilentlyContinue
        }
        
        # Set new IP address
        $newIP = New-NetIPAddress -InterfaceAlias $adapter.Name -IPAddress $ipAddress -PrefixLength $prefixLength -ErrorAction Stop
        
        Write-Ui -Message "  [OK] IP address configured" -Level "OK"
        
        # Set gateway if provided
        if ($gateway) {
            New-NetRoute -InterfaceAlias $adapter.Name -DestinationPrefix "0.0.0.0/0" -NextHop $gateway -ErrorAction Stop | Out-Null
            Write-Ui -Message "  [OK] Gateway configured" -Level "OK"
        }
        
        # Set DNS servers if provided
        if ($dns1 -or $dns2) {
            $dnsServers = @()
            if ($dns1) { $dnsServers += $dns1 }
            if ($dns2) { $dnsServers += $dns2 }
            
            Set-DnsClientServerAddress -InterfaceAlias $adapter.Name -ServerAddresses $dnsServers -ErrorAction Stop
            Write-Ui -Message "  [OK] DNS servers configured" -Level "OK"
        }
        
        # Disable DHCP
        Set-NetIPInterface -InterfaceAlias $adapter.Name -Dhcp Disabled -ErrorAction Stop
        Write-Ui -Message "  [OK] DHCP disabled" -Level "OK"
        
        Write-Host ""
        Write-Host "============================================================" -ForegroundColor Green
        Write-Ui -Message "  CONFIGURATION APPLIED SUCCESSFULLY" -Level "OK"
        Write-Host "============================================================" -ForegroundColor Green
        Write-Host ""
        
        # Store configuration for export
        $Script:ConfigResults += [PSCustomObject]@{
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            Operation = "Set Static IP"
            Adapter = $adapter.Name
            IPv4Address = $ipAddress
            SubnetMask = "$prefixLength bits"
            Gateway = if ($gateway) { $gateway } else { "Not configured" }
            DNSServers = if ($dns1 -or $dns2) { (@($dns1, $dns2) | Where-Object { $_ }) -join ', ' } else { "Not configured" }
            DHCP = "Disabled"
        }
    }
    catch {
        Write-Host ""
        Write-Host "============================================================" -ForegroundColor Red
        Write-Ui -Message "  ERROR APPLYING CONFIGURATION" -Level "ERROR"
        Write-Host "============================================================" -ForegroundColor Red
        Write-Host ""
        Write-Ui -Message "Error: $_" -Level "ERROR"
        Write-Host ""
        Write-Ui -Message "You may need to restore your network settings manually." -Level "WARN"
    }
    
    Write-Host ""
    Read-Host "Press Enter to return to main menu"
}

function Flush-DNSCache {
    Show-SouliTEKHeader -Title "FLUSH DNS CACHE" -Color Yellow -ClearHost -ShowBanner
    
    if (-not (Test-Administrator)) {
        Write-Ui -Message "WARNING: Administrator privileges required!" -Level "ERROR"
        Write-Host ""
        Write-Ui -Message "This operation requires administrator rights." -Level "WARN"
        Write-Ui -Message "Please run this script as Administrator." -Level "WARN"
        Write-Host ""
        Read-Host "Press Enter to return to main menu"
        return
    }
    
    Write-Ui -Message "This will flush the DNS resolver cache on your computer." -Level "STEP"
    Write-Host ""
    Write-Ui -Message "DNS cache stores recently resolved domain names to speed up" -Level "INFO"
    Write-Ui -Message "subsequent lookups. Flushing the cache can help resolve DNS" -Level "INFO"
    Write-Ui -Message "issues but may temporarily slow down DNS resolution." -Level "INFO"
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    
    $confirm = Read-Host "Flush DNS cache? (yes/no)"
    
    if ($confirm -ne "yes" -and $confirm -ne "y") {
        Write-Ui -Message "Operation cancelled." -Level "WARN"
        Start-Sleep -Seconds 2
        return
    }
    
    Write-Host ""
    Write-Ui -Message "Flushing DNS cache..." -Level "WARN"
    
    try {
        Clear-DnsClientCache -ErrorAction Stop
        
        Write-Host ""
        Write-Host "============================================================" -ForegroundColor Green
        Write-Ui -Message "  DNS CACHE FLUSHED SUCCESSFULLY" -Level "OK"
        Write-Host "============================================================" -ForegroundColor Green
        Write-Host ""
        
        # Store result for export
        $Script:ConfigResults += [PSCustomObject]@{
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            Operation = "Flush DNS Cache"
            Adapter = "All adapters"
            IPv4Address = "N/A"
            SubnetMask = "N/A"
            Gateway = "N/A"
            DNSServers = "N/A"
            DHCP = "N/A"
        }
    }
    catch {
        Write-Host ""
        Write-Host "============================================================" -ForegroundColor Red
        Write-Ui -Message "  ERROR FLUSHING DNS CACHE" -Level "ERROR"
        Write-Host "============================================================" -ForegroundColor Red
        Write-Host ""
        Write-Ui -Message "Error: $_" -Level "ERROR"
    }
    
    Write-Host ""
    Read-Host "Press Enter to return to main menu"
}

function Reset-NetworkAdapter {
    Show-SouliTEKHeader -Title "RESET NETWORK ADAPTER" -Color Red -ClearHost -ShowBanner
    
    if (-not (Test-Administrator)) {
        Write-Ui -Message "WARNING: Administrator privileges required!" -Level "ERROR"
        Write-Host ""
        Write-Ui -Message "This operation requires administrator rights." -Level "WARN"
        Write-Ui -Message "Please run this script as Administrator." -Level "WARN"
        Write-Host ""
        Read-Host "Press Enter to return to main menu"
        return
    }
    
    $adapter = Select-NetworkAdapter
    if (-not $adapter) { return }
    
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Ui -Message "  RESET NETWORK ADAPTER" -Level "INFO"
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Ui -Message "Adapter: $($adapter.Name)" -Level "STEP"
    Write-Ui -Message "Interface: $($adapter.InterfaceDescription)" -Level "INFO"
    Write-Host ""
    Write-Ui -Message "WARNING: This will disable and re-enable the network adapter." -Level "ERROR"
    Write-Ui -Message "         You will temporarily lose network connectivity." -Level "ERROR"
    Write-Host ""
    Write-Ui -Message "This operation can help resolve:" -Level "WARN"
    Write-Ui -Message "  - Network adapter not responding" -Level "INFO"
    Write-Ui -Message "  - Connection issues" -Level "INFO"
    Write-Ui -Message "  - IP configuration problems" -Level "INFO"
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    
    $confirm = Read-Host "Reset network adapter? (yes/no)"
    
    if ($confirm -ne "yes" -and $confirm -ne "y") {
        Write-Ui -Message "Operation cancelled." -Level "WARN"
        Start-Sleep -Seconds 2
        return
    }
    
    Write-Host ""
    Write-Ui -Message "Resetting network adapter..." -Level "WARN"
    
    try {
        Write-Ui -Message "  [1/2] Disabling adapter..." -Level "INFO"
        Disable-NetAdapter -Name $adapter.Name -Confirm:$false -ErrorAction Stop
        
        Write-Ui -Message "  [OK] Adapter disabled" -Level "OK"
        Write-Ui -Message "  [2/2] Waiting 3 seconds..." -Level "INFO"
        Start-Sleep -Seconds 3
        
        Write-Ui -Message "  [2/2] Enabling adapter..." -Level "INFO"
        Enable-NetAdapter -Name $adapter.Name -Confirm:$false -ErrorAction Stop
        
        Write-Ui -Message "  [OK] Adapter enabled" -Level "OK"
        
        Write-Host ""
        Write-Host "============================================================" -ForegroundColor Green
        Write-Ui -Message "  NETWORK ADAPTER RESET SUCCESSFULLY" -Level "OK"
        Write-Host "============================================================" -ForegroundColor Green
        Write-Host ""
        Write-Ui -Message "The adapter has been reset. Please wait a few seconds" -Level "WARN"
        Write-Ui -Message "for the network connection to be restored." -Level "WARN"
        Write-Host ""
        
        # Store result for export
        $Script:ConfigResults += [PSCustomObject]@{
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            Operation = "Reset Network Adapter"
            Adapter = $adapter.Name
            IPv4Address = "N/A"
            SubnetMask = "N/A"
            Gateway = "N/A"
            DNSServers = "N/A"
            DHCP = "N/A"
        }
    }
    catch {
        Write-Host ""
        Write-Host "============================================================" -ForegroundColor Red
        Write-Ui -Message "  ERROR RESETTING NETWORK ADAPTER" -Level "ERROR"
        Write-Host "============================================================" -ForegroundColor Red
        Write-Host ""
        Write-Ui -Message "Error: $_" -Level "ERROR"
        Write-Host ""
        Write-Ui -Message "You may need to manually enable the adapter from" -Level "WARN"
        Write-Ui -Message "Network and Sharing Center or Device Manager." -Level "WARN"
    }
    
    Write-Host ""
    Read-Host "Press Enter to return to main menu"
}

function Export-ConfigurationReport {
    Show-SouliTEKHeader -Title "EXPORT CONFIGURATION REPORT" -Color Cyan -ClearHost -ShowBanner
    
    if ($Script:ConfigResults.Count -eq 0) {
        Write-Ui -Message "No configuration data to export!" -Level "WARN"
        Write-Host ""
        Write-Ui -Message "Please perform at least one configuration operation first." -Level "INFO"
        Write-Host ""
        Read-Host "Press Enter to return to main menu"
        return
    }
    
    Write-Ui -Message "Select export format:" -Level "STEP"
    Write-Host ""
    Write-Ui -Message "  1. Text Format (.txt)" -Level "INFO"
    Write-Ui -Message "  2. CSV Format (.csv)" -Level "INFO"
    Write-Ui -Message "  3. HTML Format (.html)" -Level "INFO"
    Write-Ui -Message "  4. All Formats" -Level "INFO"
    Write-Ui -Message "  0. Cancel" -Level "INFO"
    Write-Host ""
    
    $choice = Read-Host "Enter your choice"
    
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $baseFileName = "NetworkConfiguration_$timestamp"
    
    switch ($choice) {
        "1" { Export-TextReport -FileName "$baseFileName.txt" }
        "2" { Export-CSVReport -FileName "$baseFileName.csv" }
        "3" { Export-HTMLReport -FileName "$baseFileName.html" }
        "4" {
            Export-TextReport -FileName "$baseFileName.txt"
            Export-CSVReport -FileName "$baseFileName.csv"
            Export-HTMLReport -FileName "$baseFileName.html"
        }
        default {
            Write-Ui -Message "Export cancelled." -Level "WARN"
            Start-Sleep -Seconds 2
            return
        }
    }
}

function Export-TextReport {
    param([string]$FileName)
    
    $filePath = Join-Path $Script:OutputFolder $FileName
    
    try {
        $content = @"
============================================================
NETWORK CONFIGURATION REPORT
Generated by: SouliTEK Network Configuration Tool
Website: www.soulitek.co.il
============================================================

Report Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
Total Operations: $($Script:ConfigResults.Count)

============================================================

"@
        
        foreach ($result in $Script:ConfigResults) {
            $content += @"

Operation: $($result.Operation)
Timestamp: $($result.Timestamp)
Adapter: $($result.Adapter)
IPv4 Address: $($result.IPv4Address)
Subnet Mask: $($result.SubnetMask)
Gateway: $($result.Gateway)
DNS Servers: $($result.DNSServers)
DHCP: $($result.DHCP)
----------------------------------------

"@
        }
        
        $content | Out-File -FilePath $filePath -Encoding UTF8
        
        Write-Host ""
        Write-Ui -Message "Report exported to: $filePath" -Level "OK"
        Write-Host ""
        
        # Open file
        Start-Process $filePath -ErrorAction SilentlyContinue
    }
    catch {
        Write-Ui -Message "Error exporting report: $_" -Level "ERROR"
    }
}

function Export-CSVReport {
    param([string]$FileName)
    
    $filePath = Join-Path $Script:OutputFolder $FileName
    
    try {
        $Script:ConfigResults | Export-Csv -Path $filePath -NoTypeInformation -Encoding UTF8
        
        Write-Host ""
        Write-Ui -Message "Report exported to: $filePath" -Level "OK"
        Write-Host ""
        
        # Open file
        Start-Process $filePath -ErrorAction SilentlyContinue
    }
    catch {
        Write-Ui -Message "Error exporting report: $_" -Level "ERROR"
    }
}

function Export-HTMLReport {
    param([string]$FileName)
    
    $filePath = Join-Path $Script:OutputFolder $FileName
    
    try {
        $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Network Configuration Report</title>
    <style>
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin: 20px; background: #f5f5f5; }
        .container { max-width: 1200px; margin: 0 auto; background: white; padding: 30px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        h1 { color: #667eea; border-bottom: 3px solid #667eea; padding-bottom: 10px; }
        h2 { color: #333; margin-top: 30px; }
        .header-info { background: #f8f9fa; padding: 15px; border-radius: 5px; margin: 20px 0; }
        table { width: 100%; border-collapse: collapse; margin: 20px 0; }
        th { background: #667eea; color: white; padding: 12px; text-align: left; }
        td { padding: 10px; border-bottom: 1px solid #ddd; }
        tr:hover { background: #f8f9fa; }
        .footer { margin-top: 30px; padding-top: 20px; border-top: 2px solid #eee; color: #666; text-align: center; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Network Configuration Report</h1>
        <div class="header-info">
            <strong>Generated by:</strong> SouliTEK Network Configuration Tool<br>
            <strong>Website:</strong> <a href="https://www.soulitek.co.il">www.soulitek.co.il</a><br>
            <strong>Report Generated:</strong> $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")<br>
            <strong>Total Operations:</strong> $($Script:ConfigResults.Count)
        </div>
        
        <h2>Configuration History</h2>
        <table>
            <tr>
                <th>Timestamp</th>
                <th>Operation</th>
                <th>Adapter</th>
                <th>IP Address</th>
                <th>Subnet Mask</th>
                <th>Gateway</th>
                <th>DNS Servers</th>
                <th>DHCP</th>
            </tr>
"@
        
        foreach ($result in $Script:ConfigResults) {
            $html += @"
            <tr>
                <td>$($result.Timestamp)</td>
                <td>$($result.Operation)</td>
                <td>$($result.Adapter)</td>
                <td>$($result.IPv4Address)</td>
                <td>$($result.SubnetMask)</td>
                <td>$($result.Gateway)</td>
                <td>$($result.DNSServers)</td>
                <td>$($result.DHCP)</td>
            </tr>
"@
        }
        
        $html += @"
        </table>
        
        <div class="footer">
            <p>(C) 2025 Soulitek - All Rights Reserved</p>
            <p>Professional IT Solutions for your business</p>
        </div>
    </div>
</body>
</html>
"@
        
        $html | Out-File -FilePath $filePath -Encoding UTF8
        
        Write-Host ""
        Write-Ui -Message "Report exported to: $filePath" -Level "OK"
        Write-Host ""
        
        # Open file
        Start-Process $filePath -ErrorAction SilentlyContinue
    }
    catch {
        Write-Ui -Message "Error exporting report: $_" -Level "ERROR"
    }
}

function Show-Help {
    Show-SouliTEKHeader -Title "HELP & INFORMATION" -Color Cyan -ClearHost -ShowBanner
    
    $helpText = @"

============================================================
NETWORK CONFIGURATION TOOL - HELP
============================================================

OVERVIEW:
---------
This tool allows you to view and modify network adapter
configurations on your Windows computer.

FEATURES:
---------
1. View IP Configuration
   - Display current IP address, subnet mask, gateway, and DNS
   - View all network adapters and their status
   - See DHCP vs Static IP configuration

2. Set Static IP Address
   - Configure static IP address, subnet mask, and gateway
   - Set custom DNS servers
   - Requires Administrator privileges

3. Flush DNS Cache
   - Clear the DNS resolver cache
   - Helps resolve DNS-related issues
   - Requires Administrator privileges

4. Reset Network Adapter
   - Disable and re-enable network adapter
   - Resolves adapter connectivity issues
   - Requires Administrator privileges

5. Export Configuration Report
   - Export configuration history to TXT, CSV, or HTML
   - Keep records of network changes
   - Professional formatted reports

REQUIREMENTS:
-------------
- Windows 10/11 or Windows Server 2016+
- PowerShell 5.1 or later
- Administrator privileges (for modifications)

IMPORTANT NOTES:
----------------
- Always have correct network information before making changes
- Incorrect settings may cause loss of connectivity
- Keep a record of your original configuration
- Some operations require Administrator privileges

SUPPORT:
--------
Website: www.soulitek.co.il
Email: letstalk@soulitek.co.il

(C) 2025 Soulitek - All Rights Reserved

============================================================

"@
    
    Write-Host $helpText
    
    Read-Host "Press Enter to return to main menu"
}

# ============================================================
# EXIT MESSAGE
# ============================================================

# Show-ExitMessage function - using Show-SouliTEKExitMessage from common module
function Show-ExitMessage {
    Show-SouliTEKExitMessage -ScriptPath $PSCommandPath -ToolName "SouliTEK Network Configuration Tool"
}

# ============================================================
# MAIN MENU
# ============================================================

function Show-MainMenu {
    Show-SouliTEKHeader -Title "NETWORK CONFIGURATION TOOL" -ClearHost -ShowBanner
    
    Write-Ui -Message "Main Menu:" -Level "INFO"
    Write-Host ""
    Write-Ui -Message "  1. View IP Configuration" -Level "STEP"
    Write-Ui -Message "  2. Set Static IP Address" -Level "STEP"
    Write-Ui -Message "  3. Flush DNS Cache" -Level "STEP"
    Write-Ui -Message "  4. Reset Network Adapter" -Level "STEP"
    Write-Ui -Message "  5. Export Configuration Report" -Level "STEP"
    Write-Ui -Message "  6. Help & Information" -Level "STEP"
    Write-Ui -Message "  0. Exit" -Level "STEP"
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    
    if (-not (Test-Administrator)) {
        Write-Ui -Message "NOTE: Administrator privileges required for some operations." -Level "WARN"
        Write-Host ""
    }
}

function Main {
    # Show banner
    Clear-Host
    Show-ScriptBanner -ScriptName "Network Configuration Tool" -Purpose "Configure network settings, IP addresses, and network adapters"
    
    # Check for administrator privileges
    if (-not (Test-Administrator)) {
        Write-Ui -Message "WARNING: Not running as Administrator" -Level "WARN"
        Write-Ui -Message "Some features may not be available" -Level "INFO"
        Write-Host ""
        Start-Sleep -Seconds 2
    }
    
    while ($true) {
        Show-MainMenu
        
        $choice = Read-Host "Enter your choice"
        
        switch ($choice) {
            "1" { Show-IPConfiguration }
            "2" { Set-StaticIP }
            "3" { Flush-DNSCache }
            "4" { Reset-NetworkAdapter }
            "5" { Export-ConfigurationReport }
            "6" { Show-Help }
            "0" {
                Show-ExitMessage
                exit
            }
            default {
                Write-Ui -Message "Invalid choice! Please select 0-6." -Level "ERROR"
                Start-Sleep -Seconds 2
            }
        }
    }
}

# ============================================================
# ENTRY POINT
# ============================================================

Main

