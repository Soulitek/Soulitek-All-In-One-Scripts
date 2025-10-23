# Network Test Tool - Documentation

## Overview

The **Network Test Tool** is a comprehensive PowerShell-based utility for testing and diagnosing network connectivity issues. It provides professional-grade network testing capabilities with an easy-to-use menu interface.

## Features

### 1. Ping Test (Advanced)
- **Purpose**: Test basic network connectivity to any host
- **Capabilities**:
  - Configurable number of ping requests (up to 100)
  - Real-time latency display with color coding
  - Statistics: Min/Max/Average latency
  - Packet loss percentage calculation
  - Connection quality assessment
  
**When to use**: 
- Check if a server/website is reachable
- Measure basic network latency
- Verify internet connectivity

**Example targets**: `google.com`, `8.8.8.8`, `192.168.1.1`

### 2. Trace Route
- **Purpose**: Display the network path to a destination
- **Capabilities**:
  - Shows every hop along the route
  - Displays response time for each hop
  - Identifies where delays or failures occur
  - Maximum 30 hops
  
**When to use**:
- Identify where network issues occur
- Troubleshoot routing problems
- Check ISP path to destination

**Note**: Can take 30-60 seconds to complete

### 3. DNS Lookup
- **Purpose**: Resolve domain names to IP addresses
- **Capabilities**:
  - IPv4 (A) record resolution
  - IPv6 (AAAA) record resolution
  - CNAME record detection
  - TTL (Time To Live) display
  - Shows which DNS server is being used
  
**When to use**:
- Find IP address of a website
- Troubleshoot DNS issues
- Verify DNS configuration
- Check if domain exists

### 4. Latency Test (Continuous)
- **Purpose**: Monitor network latency in real-time
- **Capabilities**:
  - Continuous monitoring for specified duration (up to 5 minutes)
  - Real-time jitter calculation
  - Packet loss tracking
  - Statistical analysis (Min/Max/Avg/StdDev)
  - Connection quality assessment
  
**When to use**:
- Check connection stability
- Measure jitter for VoIP/gaming
- Monitor network performance over time
- Detect intermittent issues

### 5. Quick Diagnostics
- **Purpose**: Run all basic network tests automatically
- **Tests performed**:
  - Local network connectivity (gateway)
  - Internet connectivity (8.8.8.8)
  - DNS resolution (google.com)
  - Network adapter status
  - DNS server configuration
  
**When to use**:
- Quick overall network health check
- Initial troubleshooting step
- Before calling IT support

### 6. Export Results
- **Purpose**: Save test results to file
- **Supported formats**:
  - **Text (.txt)**: Simple, readable format
  - **CSV (.csv)**: For Excel/spreadsheet analysis
  - **HTML (.html)**: Professional-looking report with color coding
  
**When to use**:
- Share results with IT support
- Keep records of network performance
- Document recurring issues

## Installation

### Prerequisites
- Windows 10/11 or Windows Server 2016+
- PowerShell 5.1 or later
- Network adapter

### Setup
1. Place `network_test_tool.ps1` in the `scripts` folder
2. Run from PowerShell or use the SouliTEK Launcher
3. No administrator privileges required (but recommended)

## Usage

### Running the Tool

**Option 1: Direct Execution**
```powershell
cd C:\Users\Eitan\Soulitek-AIO\scripts
.\network_test_tool.ps1
```

**Option 2: Via SouliTEK Launcher**
```powershell
# From project root
.\SouliTEK-Launcher.ps1
# Select "Network Test Tool" from the menu
```

### Basic Workflow

1. **Accept Disclaimer**: Read and accept the disclaimer
2. **Select Test**: Choose from the main menu (1-8)
3. **Enter Parameters**: Provide target hostname/IP and other parameters
4. **View Results**: Real-time results with color coding
5. **Export (Optional)**: Save results for later review
6. **Repeat or Exit**: Run more tests or exit

## Interpreting Results

### Latency (Ping Time)
| Latency | Quality | Color | Meaning |
|---------|---------|-------|---------|
| < 50ms | Excellent | Green | Perfect for all applications |
| 50-100ms | Good | Yellow | Suitable for most uses |
| 100-200ms | Fair | Yellow | Noticeable for real-time apps |
| > 200ms | Poor | Red | Problematic for gaming/VoIP |

### Packet Loss
| Loss % | Status | Impact |
|--------|--------|--------|
| 0% | Perfect | No issues |
| < 1% | Acceptable | Minor impact |
| 1-5% | Moderate | Noticeable in real-time apps |
| > 5% | Severe | Significant problems |

### Jitter (Latency Variation)
| Jitter | Stability | Color |
|--------|-----------|-------|
| < 10ms | Stable | Green |
| 10-30ms | Moderate | Yellow |
| > 30ms | Unstable | Red |

**Note**: Low jitter is critical for VoIP, video conferencing, and gaming.

## Troubleshooting Common Issues

### Issue: "Request timed out" or "Timeout"

**Possible causes**:
- Target host is offline or unreachable
- Firewall blocking ICMP packets
- Network cable unplugged
- Incorrect IP address or hostname
- Target configured to not respond to ping

**Solutions**:
1. Verify the hostname/IP is correct
2. Try pinging another host (e.g., `8.8.8.8`)
3. Check network cable connection
4. Disable firewall temporarily (for testing)
5. Use Trace Route to see where connection fails

### Issue: High Latency

**Possible causes**:
- Network congestion
- Distance to target server
- WiFi interference
- ISP throttling or issues
- Too many devices on network
- Outdated router firmware

**Solutions**:
1. Test with Ethernet instead of WiFi
2. Run test during off-peak hours
3. Restart router/modem
4. Check for bandwidth-heavy applications
5. Contact ISP if persistent

### Issue: "DNS lookup failed"

**Possible causes**:
- Domain doesn't exist
- DNS server not responding
- DNS cache corruption
- Network connectivity issue
- Incorrect DNS configuration

**Solutions**:
1. Try pinging the IP directly (e.g., `8.8.8.8`)
2. Flush DNS cache: `ipconfig /flushdns`
3. Change DNS servers to Google DNS (8.8.8.8, 8.8.4.4)
4. Check DNS server settings
5. Run Quick Diagnostics

### Issue: High Jitter

**Possible causes**:
- WiFi interference
- Network congestion
- ISP issues
- Router overload
- Background downloads/uploads

**Solutions**:
1. Use wired connection
2. Close unnecessary applications
3. Check for background updates
4. Restart network equipment
5. Test at different times

## Best Practices

### When Testing

1. **Test Multiple Targets**
   - Don't rely on a single test
   - Test local gateway, ISP, and internet hosts
   - Compare results across different targets

2. **Test Over Time**
   - Run latency test for at least 30 seconds
   - Test during different times of day
   - Monitor for patterns

3. **Document Results**
   - Export results before closing
   - Keep records of baseline performance
   - Note any changes in environment

4. **Use Right Tool**
   - Quick issue? Use Quick Diagnostics
   - Connection drops? Use Latency Test
   - Slow speeds? Use Ping and Trace Route
   - DNS issues? Use DNS Lookup

### For Best Results

- **Wired vs Wireless**: Test both to isolate WiFi issues
- **Peak Hours**: Test during high-usage periods
- **Multiple Tests**: Run tests several times for accuracy
- **Baseline**: Establish normal performance levels
- **Export**: Save results for comparison

## Common Test Scenarios

### Scenario 1: Internet Not Working

**Tests to run**:
1. Quick Diagnostics → Identify overall issue
2. Ping Test to gateway (192.168.x.1) → Test local network
3. Ping Test to 8.8.8.8 → Test internet
4. DNS Lookup for google.com → Test DNS

### Scenario 2: Slow Website

**Tests to run**:
1. DNS Lookup → Find website IP
2. Ping Test → Check basic connectivity
3. Trace Route → Identify bottleneck
4. Latency Test → Monitor stability

### Scenario 3: Video Call Issues

**Tests to run**:
1. Latency Test (continuous) → Check jitter
2. Ping Test → Verify low latency (<100ms)
3. Quick Diagnostics → Overall health

### Scenario 4: Gaming Lag

**Tests to run**:
1. Latency Test to game server → Check stability
2. Ping Test → Verify latency (<50ms ideal)
3. Trace Route → Find routing issues

## Technical Details

### Network Commands Used

The tool uses these Windows network commands:
- `Test-Connection`: For ping functionality
- `tracert`: For trace route
- `Resolve-DnsName`: For DNS lookups
- `Get-NetAdapter`: For adapter information
- `Get-DnsClientServerAddress`: For DNS server info
- `Get-NetRoute`: For routing table

### Requirements

- **OS**: Windows 10/11 or Windows Server 2016+
- **PowerShell**: Version 5.1 or later
- **Network**: Active network adapter
- **Permissions**: User-level (Admin recommended for full info)

### Export Formats

**Text File (.txt)**
- Simple, human-readable format
- Good for email or printing
- Opens in Notepad

**CSV File (.csv)**
- Structured data format
- Opens in Excel/Spreadsheet apps
- Good for analysis and charts

**HTML Report (.html)**
- Professional-looking report
- Color-coded results
- Opens in web browser
- Best for sharing with non-technical users

## Support & Contact

### Need Help?

**Soulitek IT Solutions**
- Website: https://soulitek.co.il
- Services: Computer Repair, Network Setup, IT Consulting

### Services Offered

- Computer Repair & Maintenance
- Network Setup & Support
- Software Solutions
- Business IT Consulting

---

## Changelog

### Version 1.0 (2025-10-23)
- Initial release
- Ping Test with advanced statistics
- Trace Route functionality
- DNS Lookup with A/AAAA/CNAME support
- Real-time Latency Test with jitter calculation
- Quick Diagnostics suite
- Export to TXT/CSV/HTML formats
- Professional interface with color coding
- Soulitek branding integration

---

**Coded by**: Soulitek.co.il  
**Copyright**: (C) 2025 Soulitek - All Rights Reserved  
**License**: See LICENSE file in project root

