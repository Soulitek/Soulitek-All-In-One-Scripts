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

function Show-Header {
    param([string]$Title = "NETWORK CONFIGURATION TOOL", [ConsoleColor]$Color = 'Cyan')
    
    Clear-Host
    Show-SouliTEKBanner
    Write-Host "============================================================" -ForegroundColor $Color
    Write-Host ""
    Write-Host "  $Title" -ForegroundColor $Color
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor $Color
    Write-Host ""
}

function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Get-NetworkAdapters {
    return Get-NetAdapter | Where-Object { $_.Status -eq 'Up' -or $_.Status -eq 'Disabled' } | Sort-Object Name
}

function Select-NetworkAdapter {
    Show-Header "SELECT NETWORK ADAPTER" -Color Yellow
    
    $adapters = Get-NetworkAdapters
    
    if ($adapters.Count -eq 0) {
        Write-Host "No network adapters found!" -ForegroundColor Red
        Write-Host ""
        Read-Host "Press Enter to return to main menu"
        return $null
    }
    
    Write-Host "Available Network Adapters:" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Gray
    Write-Host ""
    
    $index = 1
    $adapterList = @()
    
    foreach ($adapter in $adapters) {
        $statusColor = if ($adapter.Status -eq 'Up') { 'Green' } else { 'Yellow' }
        Write-Host "[$index] $($adapter.Name)" -ForegroundColor White
        Write-Host "    Status: $($adapter.Status)" -ForegroundColor $statusColor
        Write-Host "    Interface: $($adapter.InterfaceDescription)" -ForegroundColor Gray
        Write-Host "    Link Speed: $($adapter.LinkSpeed)" -ForegroundColor Gray
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
            Write-Host "Invalid selection!" -ForegroundColor Red
            Start-Sleep -Seconds 2
            return $null
        }
    }
    catch {
        Write-Host "Invalid input!" -ForegroundColor Red
        Start-Sleep -Seconds 2
        return $null
    }
}

# ============================================================
# NETWORK CONFIGURATION FUNCTIONS
# ============================================================

function Show-IPConfiguration {
    Show-Header "VIEW IP CONFIGURATION" -Color Green
    
    $adapter = Select-NetworkAdapter
    if (-not $adapter) { return }
    
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "  IP CONFIGURATION FOR: $($adapter.Name)" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    
    try {
        # Get IP configuration
        $ipConfig = Get-NetIPConfiguration -InterfaceAlias $adapter.Name -ErrorAction Stop
        
        Write-Host "Adapter Information:" -ForegroundColor Yellow
        Write-Host "----------------------------------------" -ForegroundColor Gray
        Write-Host "  Name: $($adapter.Name)" -ForegroundColor White
        Write-Host "  Interface: $($adapter.InterfaceDescription)" -ForegroundColor White
        Write-Host "  Status: $($adapter.Status)" -ForegroundColor $(if ($adapter.Status -eq 'Up') { 'Green' } else { 'Yellow' })
        Write-Host "  Link Speed: $($adapter.LinkSpeed)" -ForegroundColor White
        Write-Host "  MAC Address: $($adapter.MacAddress)" -ForegroundColor White
        Write-Host ""
        
        if ($ipConfig.IPv4Address) {
            Write-Host "IPv4 Configuration:" -ForegroundColor Yellow
            Write-Host "----------------------------------------" -ForegroundColor Gray
            Write-Host "  IP Address: $($ipConfig.IPv4Address.IPAddress)" -ForegroundColor Green
            Write-Host "  Subnet Mask: $($ipConfig.IPv4Address.PrefixLength) bits" -ForegroundColor White
            
            # Calculate subnet mask
            $prefixLength = $ipConfig.IPv4Address.PrefixLength
            $subnetMask = ([System.Net.IPAddress]::Parse(([System.Net.IPAddress]::HostToNetworkOrder(-1) -shl (32 - $prefixLength)) -band [System.Net.IPAddress]::HostToNetworkOrder(-1))).ToString()
            Write-Host "  Subnet Mask: $subnetMask" -ForegroundColor White
            
            if ($ipConfig.IPv4DefaultGateway) {
                Write-Host "  Default Gateway: $($ipConfig.IPv4DefaultGateway.NextHop)" -ForegroundColor Green
            } else {
                Write-Host "  Default Gateway: [Not configured]" -ForegroundColor Yellow
            }
            Write-Host ""
        } else {
            Write-Host "IPv4 Configuration: [Not configured]" -ForegroundColor Yellow
            Write-Host ""
        }
        
        if ($ipConfig.IPv6Address) {
            Write-Host "IPv6 Configuration:" -ForegroundColor Yellow
            Write-Host "----------------------------------------" -ForegroundColor Gray
            Write-Host "  IP Address: $($ipConfig.IPv6Address.IPAddress)" -ForegroundColor Green
            Write-Host "  Prefix Length: $($ipConfig.IPv6Address.PrefixLength) bits" -ForegroundColor White
            Write-Host ""
        }
        
        # Get DNS configuration
        $dnsConfig = Get-DnsClientServerAddress -InterfaceAlias $adapter.Name -AddressFamily IPv4 -ErrorAction SilentlyContinue
        
        Write-Host "DNS Configuration:" -ForegroundColor Yellow
        Write-Host "----------------------------------------" -ForegroundColor Gray
        
        if ($dnsConfig -and $dnsConfig.ServerAddresses.Count -gt 0) {
            Write-Host "  DNS Servers:" -ForegroundColor White
            $dnsIndex = 1
            foreach ($dnsServer in $dnsConfig.ServerAddresses) {
                Write-Host "    [$dnsIndex] $dnsServer" -ForegroundColor Green
                $dnsIndex++
            }
        } else {
            Write-Host "  DNS Servers: [Not configured]" -ForegroundColor Yellow
        }
        
        # Check if DHCP is enabled
        $dhcpEnabled = (Get-NetIPInterface -InterfaceAlias $adapter.Name -AddressFamily IPv4).Dhcp
        
        Write-Host ""
        Write-Host "IP Assignment:" -ForegroundColor Yellow
        Write-Host "----------------------------------------" -ForegroundColor Gray
        if ($dhcpEnabled -eq 'Enabled') {
            Write-Host "  Method: DHCP (Automatic)" -ForegroundColor Green
        } else {
            Write-Host "  Method: Static (Manual)" -ForegroundColor Cyan
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
        Write-Host "Error retrieving IP configuration: $_" -ForegroundColor Red
        Write-Host ""
    }
    
    Write-Host ""
    Read-Host "Press Enter to return to main menu"
}

function Set-StaticIP {
    Show-Header "SET STATIC IP ADDRESS" -Color Magenta
    
    if (-not (Test-Administrator)) {
        Write-Host "WARNING: Administrator privileges required!" -ForegroundColor Red
        Write-Host ""
        Write-Host "This operation requires administrator rights." -ForegroundColor Yellow
        Write-Host "Please run this script as Administrator." -ForegroundColor Yellow
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
    Write-Host "  CONFIGURE STATIC IP ADDRESS" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    
    if ($currentConfig.IPv4Address) {
        Write-Host "Current Configuration:" -ForegroundColor Yellow
        Write-Host "  IP Address: $($currentConfig.IPv4Address.IPAddress)" -ForegroundColor Gray
        Write-Host "  Prefix Length: $($currentConfig.IPv4Address.PrefixLength)" -ForegroundColor Gray
        if ($currentConfig.IPv4DefaultGateway) {
            Write-Host "  Gateway: $($currentConfig.IPv4DefaultGateway.NextHop)" -ForegroundColor Gray
        }
        Write-Host ""
    }
    
    Write-Host "Enter new static IP configuration:" -ForegroundColor White
    Write-Host ""
    
    # Get IP address
    $ipAddress = Read-Host "IP Address (e.g., 192.168.1.100)"
    if ([string]::IsNullOrWhiteSpace($ipAddress)) {
        Write-Host "IP address is required!" -ForegroundColor Red
        Start-Sleep -Seconds 2
        return
    }
    
    # Validate IP address
    try {
        $null = [System.Net.IPAddress]::Parse($ipAddress)
    }
    catch {
        Write-Host "Invalid IP address format!" -ForegroundColor Red
        Start-Sleep -Seconds 2
        return
    }
    
    # Get subnet mask / prefix length
    Write-Host ""
    Write-Host "Enter subnet mask:" -ForegroundColor White
    Write-Host "  1. Use prefix length (e.g., 24 for 255.255.255.0)" -ForegroundColor Gray
    Write-Host "  2. Use subnet mask (e.g., 255.255.255.0)" -ForegroundColor Gray
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
                    Write-Host "Prefix length must be between 0 and 32!" -ForegroundColor Red
                    Start-Sleep -Seconds 2
                    return
                }
            }
            catch {
                Write-Host "Invalid prefix length!" -ForegroundColor Red
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
            Write-Host "Invalid subnet mask format!" -ForegroundColor Red
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
            Write-Host "Invalid gateway IP address format!" -ForegroundColor Red
            Start-Sleep -Seconds 2
            return
        }
    }
    
    # Get DNS servers (optional)
    Write-Host ""
    Write-Host "DNS Servers (optional):" -ForegroundColor White
    $dns1 = Read-Host "  Primary DNS (press Enter to skip)"
    $dns2 = Read-Host "  Secondary DNS (press Enter to skip)"
    
    # Confirm configuration
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "  CONFIGURATION SUMMARY" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Adapter: $($adapter.Name)" -ForegroundColor White
    Write-Host "  IP Address: $ipAddress/$prefixLength" -ForegroundColor White
    if ($gateway) {
        Write-Host "  Gateway: $gateway" -ForegroundColor White
    }
    if ($dns1) {
        Write-Host "  Primary DNS: $dns1" -ForegroundColor White
    }
    if ($dns2) {
        Write-Host "  Secondary DNS: $dns2" -ForegroundColor White
    }
    Write-Host ""
    Write-Host "WARNING: This will change your network configuration!" -ForegroundColor Red
    Write-Host "         You may lose connectivity if settings are incorrect." -ForegroundColor Red
    Write-Host ""
    
    $confirm = Read-Host "Apply this configuration? (yes/no)"
    
    if ($confirm -ne "yes" -and $confirm -ne "y") {
        Write-Host "Configuration cancelled." -ForegroundColor Yellow
        Start-Sleep -Seconds 2
        return
    }
    
    Write-Host ""
    Write-Host "Applying configuration..." -ForegroundColor Yellow
    
    try {
        # Remove existing IP configuration
        Remove-NetIPAddress -InterfaceAlias $adapter.Name -Confirm:$false -ErrorAction SilentlyContinue
        
        # Remove existing gateway
        if ($currentConfig.IPv4DefaultGateway) {
            Remove-NetRoute -InterfaceAlias $adapter.Name -DestinationPrefix "0.0.0.0/0" -Confirm:$false -ErrorAction SilentlyContinue
        }
        
        # Set new IP address
        $newIP = New-NetIPAddress -InterfaceAlias $adapter.Name -IPAddress $ipAddress -PrefixLength $prefixLength -ErrorAction Stop
        
        Write-Host "  [OK] IP address configured" -ForegroundColor Green
        
        # Set gateway if provided
        if ($gateway) {
            New-NetRoute -InterfaceAlias $adapter.Name -DestinationPrefix "0.0.0.0/0" -NextHop $gateway -ErrorAction Stop | Out-Null
            Write-Host "  [OK] Gateway configured" -ForegroundColor Green
        }
        
        # Set DNS servers if provided
        if ($dns1 -or $dns2) {
            $dnsServers = @()
            if ($dns1) { $dnsServers += $dns1 }
            if ($dns2) { $dnsServers += $dns2 }
            
            Set-DnsClientServerAddress -InterfaceAlias $adapter.Name -ServerAddresses $dnsServers -ErrorAction Stop
            Write-Host "  [OK] DNS servers configured" -ForegroundColor Green
        }
        
        # Disable DHCP
        Set-NetIPInterface -InterfaceAlias $adapter.Name -Dhcp Disabled -ErrorAction Stop
        Write-Host "  [OK] DHCP disabled" -ForegroundColor Green
        
        Write-Host ""
        Write-Host "============================================================" -ForegroundColor Green
        Write-Host "  CONFIGURATION APPLIED SUCCESSFULLY" -ForegroundColor Green
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
        Write-Host "  ERROR APPLYING CONFIGURATION" -ForegroundColor Red
        Write-Host "============================================================" -ForegroundColor Red
        Write-Host ""
        Write-Host "Error: $_" -ForegroundColor Red
        Write-Host ""
        Write-Host "You may need to restore your network settings manually." -ForegroundColor Yellow
    }
    
    Write-Host ""
    Read-Host "Press Enter to return to main menu"
}

function Flush-DNSCache {
    Show-Header "FLUSH DNS CACHE" -Color Yellow
    
    if (-not (Test-Administrator)) {
        Write-Host "WARNING: Administrator privileges required!" -ForegroundColor Red
        Write-Host ""
        Write-Host "This operation requires administrator rights." -ForegroundColor Yellow
        Write-Host "Please run this script as Administrator." -ForegroundColor Yellow
        Write-Host ""
        Read-Host "Press Enter to return to main menu"
        return
    }
    
    Write-Host "This will flush the DNS resolver cache on your computer." -ForegroundColor White
    Write-Host ""
    Write-Host "DNS cache stores recently resolved domain names to speed up" -ForegroundColor Gray
    Write-Host "subsequent lookups. Flushing the cache can help resolve DNS" -ForegroundColor Gray
    Write-Host "issues but may temporarily slow down DNS resolution." -ForegroundColor Gray
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    
    $confirm = Read-Host "Flush DNS cache? (yes/no)"
    
    if ($confirm -ne "yes" -and $confirm -ne "y") {
        Write-Host "Operation cancelled." -ForegroundColor Yellow
        Start-Sleep -Seconds 2
        return
    }
    
    Write-Host ""
    Write-Host "Flushing DNS cache..." -ForegroundColor Yellow
    
    try {
        Clear-DnsClientCache -ErrorAction Stop
        
        Write-Host ""
        Write-Host "============================================================" -ForegroundColor Green
        Write-Host "  DNS CACHE FLUSHED SUCCESSFULLY" -ForegroundColor Green
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
        Write-Host "  ERROR FLUSHING DNS CACHE" -ForegroundColor Red
        Write-Host "============================================================" -ForegroundColor Red
        Write-Host ""
        Write-Host "Error: $_" -ForegroundColor Red
    }
    
    Write-Host ""
    Read-Host "Press Enter to return to main menu"
}

function Reset-NetworkAdapter {
    Show-Header "RESET NETWORK ADAPTER" -Color Red
    
    if (-not (Test-Administrator)) {
        Write-Host "WARNING: Administrator privileges required!" -ForegroundColor Red
        Write-Host ""
        Write-Host "This operation requires administrator rights." -ForegroundColor Yellow
        Write-Host "Please run this script as Administrator." -ForegroundColor Yellow
        Write-Host ""
        Read-Host "Press Enter to return to main menu"
        return
    }
    
    $adapter = Select-NetworkAdapter
    if (-not $adapter) { return }
    
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "  RESET NETWORK ADAPTER" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Adapter: $($adapter.Name)" -ForegroundColor White
    Write-Host "Interface: $($adapter.InterfaceDescription)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "WARNING: This will disable and re-enable the network adapter." -ForegroundColor Red
    Write-Host "         You will temporarily lose network connectivity." -ForegroundColor Red
    Write-Host ""
    Write-Host "This operation can help resolve:" -ForegroundColor Yellow
    Write-Host "  - Network adapter not responding" -ForegroundColor Gray
    Write-Host "  - Connection issues" -ForegroundColor Gray
    Write-Host "  - IP configuration problems" -ForegroundColor Gray
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    
    $confirm = Read-Host "Reset network adapter? (yes/no)"
    
    if ($confirm -ne "yes" -and $confirm -ne "y") {
        Write-Host "Operation cancelled." -ForegroundColor Yellow
        Start-Sleep -Seconds 2
        return
    }
    
    Write-Host ""
    Write-Host "Resetting network adapter..." -ForegroundColor Yellow
    
    try {
        Write-Host "  [1/2] Disabling adapter..." -ForegroundColor Gray
        Disable-NetAdapter -Name $adapter.Name -Confirm:$false -ErrorAction Stop
        
        Write-Host "  [OK] Adapter disabled" -ForegroundColor Green
        Write-Host "  [2/2] Waiting 3 seconds..." -ForegroundColor Gray
        Start-Sleep -Seconds 3
        
        Write-Host "  [2/2] Enabling adapter..." -ForegroundColor Gray
        Enable-NetAdapter -Name $adapter.Name -Confirm:$false -ErrorAction Stop
        
        Write-Host "  [OK] Adapter enabled" -ForegroundColor Green
        
        Write-Host ""
        Write-Host "============================================================" -ForegroundColor Green
        Write-Host "  NETWORK ADAPTER RESET SUCCESSFULLY" -ForegroundColor Green
        Write-Host "============================================================" -ForegroundColor Green
        Write-Host ""
        Write-Host "The adapter has been reset. Please wait a few seconds" -ForegroundColor Yellow
        Write-Host "for the network connection to be restored." -ForegroundColor Yellow
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
        Write-Host "  ERROR RESETTING NETWORK ADAPTER" -ForegroundColor Red
        Write-Host "============================================================" -ForegroundColor Red
        Write-Host ""
        Write-Host "Error: $_" -ForegroundColor Red
        Write-Host ""
        Write-Host "You may need to manually enable the adapter from" -ForegroundColor Yellow
        Write-Host "Network and Sharing Center or Device Manager." -ForegroundColor Yellow
    }
    
    Write-Host ""
    Read-Host "Press Enter to return to main menu"
}

function Export-ConfigurationReport {
    Show-Header "EXPORT CONFIGURATION REPORT" -Color Cyan
    
    if ($Script:ConfigResults.Count -eq 0) {
        Write-Host "No configuration data to export!" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Please perform at least one configuration operation first." -ForegroundColor Gray
        Write-Host ""
        Read-Host "Press Enter to return to main menu"
        return
    }
    
    Write-Host "Select export format:" -ForegroundColor White
    Write-Host ""
    Write-Host "  1. Text Format (.txt)" -ForegroundColor Gray
    Write-Host "  2. CSV Format (.csv)" -ForegroundColor Gray
    Write-Host "  3. HTML Format (.html)" -ForegroundColor Gray
    Write-Host "  4. All Formats" -ForegroundColor Gray
    Write-Host "  0. Cancel" -ForegroundColor Gray
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
            Write-Host "Export cancelled." -ForegroundColor Yellow
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
        Write-Host "Report exported to: $filePath" -ForegroundColor Green
        Write-Host ""
        
        # Open file
        Start-Process notepad.exe -ArgumentList $filePath -ErrorAction SilentlyContinue
    }
    catch {
        Write-Host "Error exporting report: $_" -ForegroundColor Red
    }
}

function Export-CSVReport {
    param([string]$FileName)
    
    $filePath = Join-Path $Script:OutputFolder $FileName
    
    try {
        $Script:ConfigResults | Export-Csv -Path $filePath -NoTypeInformation -Encoding UTF8
        
        Write-Host ""
        Write-Host "Report exported to: $filePath" -ForegroundColor Green
        Write-Host ""
        
        # Open file
        Start-Process $filePath -ErrorAction SilentlyContinue
    }
    catch {
        Write-Host "Error exporting report: $_" -ForegroundColor Red
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
        Write-Host "Report exported to: $filePath" -ForegroundColor Green
        Write-Host ""
        
        # Open file
        Start-Process $filePath -ErrorAction SilentlyContinue
    }
    catch {
        Write-Host "Error exporting report: $_" -ForegroundColor Red
    }
}

function Show-Help {
    Show-Header "HELP & INFORMATION" -Color Cyan
    
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

function Show-ExitMessage {
    Clear-Host
    Write-Host ""
    Write-Host "Thank you for using SouliTEK Network Configuration Tool!" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Website: www.soulitek.co.il" -ForegroundColor Yellow
    Write-Host ""
}

# ============================================================
# MAIN MENU
# ============================================================

function Show-MainMenu {
    Show-Header
    
    Write-Host "Main Menu:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  1. View IP Configuration" -ForegroundColor White
    Write-Host "  2. Set Static IP Address" -ForegroundColor White
    Write-Host "  3. Flush DNS Cache" -ForegroundColor White
    Write-Host "  4. Reset Network Adapter" -ForegroundColor White
    Write-Host "  5. Export Configuration Report" -ForegroundColor White
    Write-Host "  6. Help & Information" -ForegroundColor White
    Write-Host "  0. Exit" -ForegroundColor White
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    
    if (-not (Test-Administrator)) {
        Write-Host "NOTE: Administrator privileges required for some operations." -ForegroundColor Yellow
        Write-Host ""
    }
}

function Main {
    # Check for administrator privileges
    if (-not (Test-Administrator)) {
        Write-Host "WARNING: Not running as Administrator!" -ForegroundColor Yellow
        Write-Host "Some features may not be available." -ForegroundColor Yellow
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
                Write-Host "Invalid choice! Please select 0-6." -ForegroundColor Red
                Start-Sleep -Seconds 2
            }
        }
    }
}

# ============================================================
# ENTRY POINT
# ============================================================

Main

