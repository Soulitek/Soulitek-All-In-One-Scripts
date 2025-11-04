# Network Configuration Tool - Documentation

## Overview

The **Network Configuration Tool** is a comprehensive PowerShell-based utility for viewing and modifying network adapter configurations on Windows systems. It provides professional-grade network management capabilities with an easy-to-use menu interface.

## Features

### 1. View IP Configuration
- **Purpose**: Display current network adapter configuration details
- **Capabilities**:
  - View IP address (IPv4 and IPv6)
  - Display subnet mask and prefix length
  - Show default gateway
  - List DNS servers
  - Check DHCP vs Static IP assignment
  - Display adapter status and MAC address
  - Show link speed and interface description
  
**When to use**: 
- Troubleshoot network connectivity issues
- Verify current network settings
- Document network configuration
- Check DHCP assignment status

**Example use cases**: 
- Verify IP address is correctly assigned
- Check if DNS servers are configured
- Confirm gateway connectivity
- Review network adapter status

### 2. Set Static IP Address
- **Purpose**: Configure static IP address settings for network adapters
- **Capabilities**:
  - Set static IP address
  - Configure subnet mask (prefix length or subnet mask format)
  - Set default gateway
  - Configure primary and secondary DNS servers
  - Disable DHCP automatically
  - Validate IP address format before applying
  
**When to use**:
- Set up static IP for servers
- Configure network devices with fixed IPs
- Troubleshoot DHCP issues by using static IP
- Network configuration for specific VLANs
  
**Important Notes**:
- **Requires Administrator privileges**
- **WARNING**: Incorrect settings may cause loss of connectivity
- Always have correct network information before making changes
- Keep a record of original configuration for rollback

**Configuration Options**:
- IP Address: Enter in standard format (e.g., 192.168.1.100)
- Subnet Mask: 
  - Option 1: Prefix length (e.g., 24 for 255.255.255.0)
  - Option 2: Subnet mask (e.g., 255.255.255.0)
- Default Gateway: Optional, but recommended
- DNS Servers: Primary and secondary (optional)

### 3. Flush DNS Cache
- **Purpose**: Clear the DNS resolver cache
- **Capabilities**:
  - Clears all cached DNS entries
  - Forces fresh DNS lookups
  - Helps resolve DNS-related issues
  
**When to use**:
- DNS resolution problems
- After changing DNS server settings
- Resolving stale DNS entries
- Troubleshooting website access issues
  
**Important Notes**:
- **Requires Administrator privileges**
- May temporarily slow down DNS resolution (first lookup after flush)
- All cached DNS entries are cleared immediately

**Example scenarios**:
- Website not resolving after DNS server change
- Stale DNS records causing connection issues
- Testing DNS server configuration

### 4. Reset Network Adapter
- **Purpose**: Disable and re-enable network adapter to reset connectivity
- **Capabilities**:
  - Disables network adapter
  - Re-enables network adapter after short delay
  - Restores network connectivity
  - Resolves adapter-related issues
  
**When to use**:
- Network adapter not responding
- Connection issues not resolved by other methods
- IP configuration problems
- Adapter stuck in bad state
  
**Important Notes**:
- **Requires Administrator privileges**
- **WARNING**: You will temporarily lose network connectivity
- Network connection restored automatically after reset
- Wait a few seconds for connection to be restored

**What it does**:
1. Disables the selected network adapter
2. Waits 3 seconds
3. Re-enables the network adapter
4. Network connection restored automatically

### 5. Export Configuration Report
- **Purpose**: Save network configuration history to file
- **Supported formats**:
  - **Text (.txt)**: Simple, readable format
  - **CSV (.csv)**: For Excel/spreadsheet analysis
  - **HTML (.html)**: Professional-looking report with styling
  
**When to use**:
- Document network changes
- Keep records for compliance
- Share configuration with IT support
- Track network configuration history

**Report Contents**:
- Timestamp of each operation
- Operation type (View, Set Static IP, Flush DNS, Reset Adapter)
- Adapter name
- IP configuration details
- DNS settings
- DHCP status

## Installation

### Prerequisites
- Windows 10/11 or Windows Server 2016+
- PowerShell 5.1 or later
- Network adapter installed
- Administrator privileges (for modifications)

### Setup
1. Place `network_configuration_tool.ps1` in the `scripts` folder
2. Run from PowerShell or use the SouliTEK Launcher
3. Some operations require Administrator privileges

## Usage

### Running the Tool

**Option 1: Direct Execution**
```powershell
cd C:\Users\Eitan\Soulitek-AIO\scripts
.\network_configuration_tool.ps1
```

**Option 2: Via SouliTEK Launcher**
```powershell
# From project root
.\launcher\SouliTEK-Launcher-WPF.ps1
# Select "Network Configuration Tool" from the Network category
```

### Basic Workflow

1. **Launch Tool**: Run script or select from launcher
2. **Select Operation**: Choose from main menu (1-6)
3. **Select Adapter** (if needed): Choose network adapter from list
4. **Enter Parameters** (if needed): Provide IP settings, DNS servers, etc.
5. **Confirm Changes**: Review configuration before applying
6. **View Results**: See confirmation of successful operations
7. **Export Report** (optional): Save configuration history

### Menu Options

1. **View IP Configuration** - Display current adapter settings
2. **Set Static IP Address** - Configure static IP settings
3. **Flush DNS Cache** - Clear DNS resolver cache
4. **Reset Network Adapter** - Disable and re-enable adapter
5. **Export Configuration Report** - Save history to file
6. **Help & Information** - Display comprehensive help
0. **Exit** - Close the tool

## Understanding Network Configuration

### IP Address Types

**Static IP Address**:
- Manually configured IP address
- Does not change unless manually modified
- Required for servers and network devices
- Requires configuration of subnet mask and gateway

**DHCP (Dynamic Host Configuration Protocol)**:
- Automatically assigned IP address
- Obtained from DHCP server (usually router)
- May change on network reconnection
- Includes automatic DNS server assignment

### Subnet Mask / Prefix Length

**Subnet Mask Format** (e.g., 255.255.255.0):
- Traditional format
- 32-bit mask defining network portion
- Common masks:
  - 255.255.255.0 = /24 (most home networks)
  - 255.255.0.0 = /16 (large networks)
  - 255.0.0.0 = /8 (very large networks)

**Prefix Length Format** (e.g., /24):
- CIDR notation
- Number of bits in network portion
- More concise representation
- Standard in modern networking

**Common Values**:
- /24 = 255.255.255.0 (254 hosts)
- /16 = 255.255.0.0 (65,534 hosts)
- /8 = 255.0.0.0 (16,777,214 hosts)

### Default Gateway

- Router or network device that forwards traffic to other networks
- Usually the first IP in the subnet (e.g., 192.168.1.1)
- Required for internet connectivity
- Must be in the same subnet as the IP address

### DNS Servers

**Primary DNS Server**:
- First server used for DNS resolution
- Usually your ISP's DNS or public DNS (8.8.8.8, 1.1.1.1)
- Required for domain name resolution

**Secondary DNS Server**:
- Backup DNS server if primary fails
- Optional but recommended
- Provides redundancy

**Popular Public DNS Servers**:
- Google DNS: 8.8.8.8, 8.8.4.4
- Cloudflare DNS: 1.1.1.1, 1.0.0.1
- OpenDNS: 208.67.222.222, 208.67.220.220

## Examples

### Example 1: View Current Configuration

```
1. Launch tool
2. Select option 1 (View IP Configuration)
3. Select network adapter from list
4. Review displayed configuration:
   - IP Address: 192.168.1.100
   - Subnet Mask: 255.255.255.0 (/24)
   - Gateway: 192.168.1.1
   - DNS: 8.8.8.8, 8.8.4.4
   - DHCP: Enabled
```

### Example 2: Set Static IP for Server

```
1. Launch tool as Administrator
2. Select option 2 (Set Static IP Address)
3. Select network adapter (e.g., Ethernet)
4. Enter IP Address: 192.168.1.50
5. Enter Prefix Length: 24
6. Enter Gateway: 192.168.1.1
7. Enter Primary DNS: 8.8.8.8
8. Enter Secondary DNS: 8.8.4.4
9. Confirm configuration
10. Verify new settings with option 1
```

### Example 3: Troubleshoot DNS Issues

```
1. Launch tool as Administrator
2. Select option 3 (Flush DNS Cache)
3. Confirm operation
4. DNS cache cleared
5. Test DNS resolution (ping google.com)
```

### Example 4: Reset Network Adapter

```
1. Launch tool as Administrator
2. Select option 4 (Reset Network Adapter)
3. Select problematic adapter
4. Confirm reset
5. Wait for adapter to re-enable
6. Test connectivity
```

## Troubleshooting

### Common Issues

**Issue: "Administrator privileges required"**
- **Solution**: Run PowerShell as Administrator
- Right-click PowerShell → "Run as Administrator"
- Or use SouliTEK Launcher (auto-elevates)

**Issue: "Cannot connect after setting static IP"**
- **Solution**: Verify IP settings are correct:
  - IP address is in correct subnet
  - Gateway is reachable
  - DNS servers are correct
- Try reverting to DHCP first
- Check network cable/connection

**Issue: "Invalid IP address format"**
- **Solution**: Use correct format:
  - Valid: 192.168.1.100
  - Invalid: 192.168.1 (missing octet)
  - Invalid: 192.168.1.256 (octet > 255)

**Issue: "Network adapter not found"**
- **Solution**: 
  - Check adapter is installed and enabled
  - Verify adapter appears in Device Manager
  - Try enabling adapter manually first

**Issue: "DNS flush didn't resolve issue"**
- **Solution**:
  - Check DNS server settings are correct
  - Verify DNS servers are reachable (ping 8.8.8.8)
  - Try different DNS servers
  - Check firewall settings

**Issue: "Cannot reset adapter"**
- **Solution**:
  - Close applications using network
  - Try disabling/enabling manually from Network Settings
  - Check adapter is not disabled in Device Manager
  - Restart computer if needed

### Best Practices

1. **Always Backup Configuration**:
   - View and export current configuration before making changes
   - Take screenshot or note down original settings
   - Keep configuration reports for reference

2. **Verify Settings Before Applying**:
   - Double-check IP address, subnet mask, and gateway
   - Ensure DNS servers are correct and reachable
   - Confirm adapter selection is correct

3. **Test After Changes**:
   - Test connectivity after setting static IP
   - Verify DNS resolution after flushing cache
   - Check internet connectivity after adapter reset

4. **Use Static IP Wisely**:
   - Only use static IP when necessary
   - DHCP is usually sufficient for most devices
   - Static IP is required for servers and network devices

5. **Document Changes**:
   - Export configuration reports after changes
   - Keep records for troubleshooting
   - Note date and reason for changes

## Security Considerations

### Administrator Privileges
- Some operations require elevated privileges
- Tool automatically detects and warns if not running as admin
- Always run from trusted source

### Network Security
- Be cautious when modifying network settings
- Incorrect settings can expose system to network
- Verify settings match your network security policy

### DNS Security
- Use trusted DNS servers (Google, Cloudflare)
- Avoid public/untrusted DNS servers
- Consider DNS-over-HTTPS for enhanced security

## Technical Details

### PowerShell Cmdlets Used
- `Get-NetAdapter` - Retrieve network adapters
- `Get-NetIPConfiguration` - Get IP configuration
- `Get-DnsClientServerAddress` - Get DNS settings
- `New-NetIPAddress` - Set static IP address
- `Set-DnsClientServerAddress` - Configure DNS servers
- `Clear-DnsClientCache` - Flush DNS cache
- `Disable-NetAdapter` / `Enable-NetAdapter` - Reset adapter

### Supported Network Adapters
- Ethernet adapters
- Wireless adapters
- Virtual network adapters
- VPN adapters (limited functionality)

### Operating System Compatibility
- Windows 10 (all versions)
- Windows 11 (all versions)
- Windows Server 2016+
- Requires Windows PowerShell 5.1 or PowerShell 7+

## Export Formats

### Text Format (.txt)
- Human-readable plain text
- Simple format for quick reference
- Includes all configuration details
- Opens in Notepad automatically

### CSV Format (.csv)
- Spreadsheet-compatible format
- Suitable for Excel/Google Sheets
- Includes all columns for analysis
- Opens in default CSV application

### HTML Format (.html)
- Professional web report
- Styled with modern CSS
- Includes SouliTEK branding
- Opens in default web browser
- Suitable for sharing and printing

## Support

For additional support or questions:
- **Website**: www.soulitek.co.il
- **Email**: letstalk@soulitek.co.il
- **Documentation**: See project README.md

## License

(C) 2025 Soulitek - All Rights Reserved

This tool is provided "AS IS" without warranty of any kind. Use at your own risk.

## Version History

- **v1.0.0** (2025-01-15): Initial release
  - View IP configuration
  - Set static IP addresses
  - Flush DNS cache
  - Reset network adapter
  - Export configuration reports

