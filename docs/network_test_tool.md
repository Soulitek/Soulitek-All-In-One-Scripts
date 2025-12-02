# Network Test Tool

## Overview

The **Network Test Tool** provides comprehensive network testing capabilities for troubleshooting connectivity and performance issues. It's designed for IT professionals diagnosing network problems and verifying connectivity.

## Purpose

Provides network diagnostic capabilities:
- Ping testing
- Traceroute analysis
- DNS lookup
- Latency testing
- Connection monitoring
- Export test results

## Features

### 🏓 **Ping Testing**
- Ping specific hosts
- Continuous ping monitoring
- Latency statistics
- Packet loss detection
- Multiple host testing

### 🗺️ **Traceroute**
- Network path analysis
- Hop-by-hop routing
- Latency per hop
- Route identification
- Network path visualization

### 🔍 **DNS Lookup**
- Domain name resolution
- Reverse DNS lookup
- DNS server testing
- Multiple record types
- DNS query analysis

### ⏱️ **Latency Testing**
- Response time measurement
- Multiple test targets
- Statistical analysis
- Performance benchmarking

### 📊 **Connection Monitor**
- Continuous connectivity monitoring
- Real-time status updates
- Connection quality metrics
- Alert on failures

## Requirements

### System Requirements
- **OS:** Windows 10 or Windows 11
- **PowerShell:** Version 5.1 or higher
- **Privileges:** Standard user (admin for some advanced features)
- **Network:** Active network connection

## Usage

### Running the Script

1. **Launch from SouliTEK Launcher** (recommended)
   - Open the SouliTEK Launcher
   - Find "Network Test Tool" in the Network category
   - Click the tool card to launch

2. **Run directly via PowerShell:**
   ```powershell
   .\scripts\network_test_tool.ps1
   ```

### Menu Options

#### Option 1: Ping Test
Tests connectivity to a host.
- Enter hostname or IP
- Configurable packet count
- Shows response times
- Packet loss statistics
- Round-trip time (RTT)

#### Option 2: Continuous Ping
Continuous ping monitoring.
- Real-time ping updates
- Shows live statistics
- Press Ctrl+C to stop
- Useful for monitoring

#### Option 3: Traceroute
Traces network path to destination.
- Shows all network hops
- Latency per hop
- Identifies routing path
- Network topology analysis

#### Option 4: DNS Lookup
Resolves domain names to IPs.
- Forward DNS lookup
- Reverse DNS lookup
- Multiple record types (A, AAAA, MX, etc.)
- DNS server testing

#### Option 5: Test Multiple Hosts
Tests connectivity to multiple targets.
- Enter multiple hosts
- Parallel testing
- Summary results
- Quick status check

#### Option 6: Export Test Results
Exports test results to file.
- CSV format (spreadsheet)
- TXT format (text report)
- All test results
- Timestamped filename

## Test Types

### Ping Test
- **Purpose:** Verify host is reachable
- **Measures:** Response time, packet loss
- **Use Cases:** Basic connectivity check, latency measurement

### Traceroute
- **Purpose:** Identify network path
- **Measures:** Hops, latency per hop
- **Use Cases:** Routing issues, network path analysis

### DNS Lookup
- **Purpose:** Verify DNS resolution
- **Measures:** DNS response time, record types
- **Use Cases:** DNS issues, domain verification

## Common Test Targets

### Internet Connectivity
- **Google DNS:** 8.8.8.8
- **Cloudflare DNS:** 1.1.1.1
- **Google:** google.com
- **Cloudflare:** cloudflare.com

### Local Network
- **Gateway:** Usually 192.168.1.1 or 192.168.0.1
- **Local devices:** Other computers on network
- **Router:** Network gateway

## Troubleshooting

### Ping Fails
**Problem:** Cannot ping host

**Possible Causes:**
- Host is down or unreachable
- Firewall blocking ICMP
- Network connectivity issue
- Incorrect hostname/IP

**Solutions:**
1. Verify host is online
2. Check firewall settings
3. Test with different host
4. Verify network connection
5. Try IP instead of hostname

### High Latency
**Problem:** High ping times

**Causes:**
- Network congestion
- Distance to server
- Slow internet connection
- Network issues

**Solutions:**
- Test multiple hosts
- Check internet speed
- Test at different times
- Contact ISP if persistent

### DNS Resolution Fails
**Problem:** Cannot resolve domain names

**Solutions:**
1. Check DNS server settings
2. Try different DNS server (8.8.8.8)
3. Flush DNS cache
4. Verify internet connectivity
5. Check firewall isn't blocking DNS

### Traceroute Timeouts
**Problem:** Traceroute shows timeouts

**Causes:**
- Firewalls blocking ICMP
- Network routing issues
- Some hops don't respond

**Solutions:**
- Normal for some networks
- Check if destination is reachable
- Try different destination
- Some routers don't respond to traceroute

## Best Practices

### Network Testing
- Test multiple hosts for comparison
- Test at different times
- Document test results
- Use consistent test parameters

### Troubleshooting Workflow
1. Test local connectivity (gateway)
2. Test internet connectivity (8.8.8.8)
3. Test DNS resolution (google.com)
4. Use traceroute for path analysis
5. Document findings

### Performance Monitoring
- Regular latency testing
- Monitor connection quality
- Track performance trends
- Identify degradation

## Technical Details

### Ping
- Uses ICMP protocol
- Measures round-trip time
- Shows packet loss
- Standard network diagnostic

### Traceroute
- Uses ICMP or UDP
- Shows network path
- Identifies routing hops
- Latency per hop

### DNS Lookup
- Queries DNS servers
- Resolves domain names
- Multiple record types
- DNS server performance

## Output Files

### Report Locations
- **Desktop:** Reports saved to `%USERPROFILE%\Desktop`
- **Formats:** CSV and TXT
- **Filename:** `NetworkTestReport_YYYYMMDD_HHMMSS.[ext]`

### Report Contents
- Test type and target
- Test results
- Timestamps
- Statistics
- Success/failure status

## Support

For assistance or to report issues:
- **Website:** www.soulitek.co.il
- **Email:** letstalk@soulitek.co.il

---

**Coded by:** SouliTEK  
*IT Solutions for your business*

(C) 2025 SouliTEK - All Rights Reserved










