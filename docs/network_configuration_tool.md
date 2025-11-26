# Network Configuration Tool

## Overview

The **Network Configuration Tool** provides comprehensive network configuration management for viewing and modifying network adapter settings. It's designed for IT professionals managing network configurations and troubleshooting connectivity issues.

## Purpose

Simplifies network configuration management:
- View IP configuration
- Set static IP addresses
- Configure DNS settings
- Flush DNS cache
- Reset network adapters

## Features

### 🌐 **IP Configuration**
- View current IP settings
- Display all network adapters
- Show IP, subnet, gateway
- DNS server information

### ⚙️ **Static IP Configuration**
- Set static IP address
- Configure subnet mask
- Set default gateway
- Configure DNS servers

### 🔄 **Network Reset**
- Flush DNS cache
- Reset network adapter
- Release and renew IP
- Restart network services

### 📋 **Export Configuration**
- Export current settings
- Save configuration to file
- Network adapter details
- Configuration history

## Requirements

### System Requirements
- **OS:** Windows 10 or Windows 11
- **PowerShell:** Version 5.1 or higher
- **Privileges:** Administrator rights (required for configuration changes)
- **Network:** Active network adapters

## Usage

### Running the Script

1. **Launch from SouliTEK Launcher** (recommended)
   - Open the SouliTEK Launcher
   - Find "Network Configuration Tool" in the Network category
   - Click the tool card to launch

2. **Run directly via PowerShell** (as Administrator):
   ```powershell
   .\scripts\network_configuration_tool.ps1
   ```

### Important Warnings

⚠️ **WARNING:** Modifying network settings can cause loss of connectivity.

**Before Making Changes:**
- Document current settings
- Have correct network information ready
- Ensure you know the correct IP, gateway, and DNS
- Have a backup plan to restore settings

### Menu Options

#### Option 1: View IP Configuration
Displays current network configuration.
- All network adapters
- IP addresses (IPv4 and IPv6)
- Subnet masks
- Default gateways
- DNS servers
- MAC addresses

#### Option 2: Set Static IP Address
Configures static IP address for adapter.
- Select network adapter
- Enter IP address
- Enter subnet mask
- Enter default gateway
- Configure DNS servers

#### Option 3: Set DHCP (Automatic)
Configures adapter to use DHCP.
- Select network adapter
- Enables automatic IP assignment
- Automatic DNS configuration
- Restores dynamic addressing

#### Option 4: Flush DNS Cache
Clears DNS resolver cache.
- Removes cached DNS entries
- Forces fresh DNS lookups
- Resolves DNS issues
- Quick operation

#### Option 5: Reset Network Adapter
Resets network adapter configuration.
- Releases current IP
- Renews IP address
- Restarts adapter
- Refreshes configuration

#### Option 6: Export Configuration
Exports current network settings.
- All adapter configurations
- Saved to Desktop
- TXT format
- Timestamped filename

## Network Configuration

### Static IP Setup
When setting static IP, you'll need:
- **IP Address:** Desired static IP (e.g., 192.168.1.100)
- **Subnet Mask:** Usually 255.255.255.0 for home networks
- **Default Gateway:** Router IP (e.g., 192.168.1.1)
- **DNS Servers:** Primary and secondary DNS (e.g., 8.8.8.8, 8.8.4.4)

### DHCP vs. Static
- **DHCP (Automatic):** IP assigned by router, easier to manage
- **Static IP:** Fixed IP address, required for some servers/services

## Troubleshooting

### Cannot Change Settings
**Problem:** "Access denied" when changing settings

**Solutions:**
1. Run as Administrator (required)
2. Check adapter is not disabled
3. Verify adapter permissions
4. Close other network tools

### Loss of Connectivity
**Problem:** Lost internet after changing settings

**Solutions:**
1. Verify IP settings are correct
2. Check gateway is reachable
3. Verify DNS servers are correct
4. Use Option 2 to set DHCP (automatic)
5. Restore previous settings if documented

### Wrong IP Configuration
**Problem:** Entered incorrect IP settings

**Solutions:**
1. Use Option 3 to set DHCP (automatic)
2. Restore from exported configuration
3. Manually correct settings
4. Contact network administrator

### DNS Issues
**Problem:** Cannot resolve domain names

**Solutions:**
1. Use Option 4 to flush DNS cache
2. Verify DNS servers are correct
3. Try public DNS (8.8.8.8, 1.1.1.1)
4. Reset network adapter (Option 5)

## Best Practices

### Before Making Changes
- **Document current settings:** Export configuration first
- **Verify network information:** Get correct IP, gateway, DNS
- **Test connectivity:** Ensure current connection works
- **Have backup plan:** Know how to restore settings

### Network Management
- Use DHCP when possible (easier management)
- Use static IP for servers and printers
- Document all static IP assignments
- Regular network audits

### Troubleshooting Steps
1. View current configuration
2. Verify settings are correct
3. Flush DNS cache
4. Reset adapter if needed
5. Export configuration for records

## Technical Details

### Network Adapters
- Physical adapters (Ethernet, Wi-Fi)
- Virtual adapters (VPN, Hyper-V)
- Disabled adapters shown but not configurable

### IP Configuration Methods
- **netsh:** Windows network shell commands
- **PowerShell:** NetTCPIP module
- **WMI:** Windows Management Instrumentation

### DNS Cache
- Windows DNS resolver cache
- Stores recent DNS lookups
- Flushing forces fresh queries
- Helps resolve DNS issues

## Common Network Settings

### Home Network
- **IP Range:** 192.168.1.x or 192.168.0.x
- **Subnet:** 255.255.255.0
- **Gateway:** Usually .1 (192.168.1.1)
- **DNS:** Router or public DNS (8.8.8.8)

### Office Network
- **IP Range:** Varies by organization
- **Subnet:** Usually 255.255.255.0
- **Gateway:** Provided by IT
- **DNS:** Corporate DNS servers

### Public DNS Servers
- **Google:** 8.8.8.8, 8.8.4.4
- **Cloudflare:** 1.1.1.1, 1.0.0.1
- **OpenDNS:** 208.67.222.222, 208.67.220.220

## Support

For assistance or to report issues:
- **Website:** www.soulitek.co.il
- **Email:** letstalk@soulitek.co.il

---

**Coded by:** SouliTEK  
*IT Solutions for your business*

(C) 2025 SouliTEK - All Rights Reserved



