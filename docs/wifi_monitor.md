# WiFi Monitor

## Overview

The **WiFi Monitor** allows you to monitor your WiFi connection status, signal strength, frequency band, and disconnection history. It's designed for IT professionals and users who need to troubleshoot WiFi connectivity issues and monitor network stability.

## Purpose

Monitor WiFi connection status:
- View current signal strength (RSSI) in percentages
- Determine if connected to 2.4GHz or 5GHz band
- Display SSID and connection details
- Track disconnection history from event logs
- Export comprehensive WiFi reports

## Features

### 📶 **Signal Strength Monitoring**
- Real-time signal strength percentage (0-100%)
- RSSI value in dBm
- Color-coded signal quality indicators
- Signal strength interpretation guide

### 📡 **Frequency Band Detection**
- Automatic detection of 2.4GHz or 5GHz band
- Channel number display
- Band characteristics explanation
- Performance comparison information

### 🔍 **Connection Information**
- Current SSID (Network name)
- Connection state
- Authentication type
- Cipher/encryption method
- Radio type (802.11n, 802.11ac, etc.)
- Connection mode

### 📊 **Disconnection History**
- Scans Windows event logs for disconnection events
- Last 30 days of connection/disconnection history
- Disconnection statistics by network
- Event timestamps and details
- Reason codes for disconnections

### 💾 **Export Capabilities**
- Export to text file (.txt)
- Export to CSV format (.csv)
- Export to HTML formatted report (.html)
- Comprehensive WiFi status reports
- Disconnection history included

## Requirements

### System Requirements
- **OS:** Windows 10 or Windows 11
- **PowerShell:** Version 5.1 or higher
- **Privileges:** Standard user (no admin required)
- **WiFi:** WiFi adapter and active connection

## Usage

### Running the Script

1. **Launch from SouliTEK Launcher** (recommended)
   - Open the SouliTEK Launcher
   - Find "WiFi Monitor" in the Network category
   - Click the tool card to launch

2. **Run directly via PowerShell:**
   ```powershell
   .\scripts\wifi_monitor.ps1
   ```

### Menu Options

#### Option 1: Current WiFi Status
Displays current WiFi connection information.
- SSID (Network name)
- Signal strength percentage
- RSSI value in dBm
- Frequency band (2.4GHz or 5GHz)
- Channel number
- Connection state
- Authentication and security details

**Use when:** Need quick overview of current connection status.

#### Option 2: Disconnection History
Shows WiFi disconnection events from event logs.
- All disconnections in last 30 days
- Connection/disconnection events
- Event timestamps
- Network SSID for each event
- Disconnection statistics by network
- Total disconnection count

**Use when:** Troubleshooting WiFi stability issues or connection problems.

#### Option 3: Detailed Information
Shows complete technical WiFi details.
- All connection parameters
- Frequency band characteristics
- Performance comparison (2.4GHz vs 5GHz)
- Radio type and connection mode
- Complete authentication details

**Use when:** Need complete technical details for troubleshooting or documentation.

#### Option 4: Export Report
Exports comprehensive WiFi report to Desktop.
- Current WiFi status
- Disconnection history
- All connection details
- Multiple formats (TXT, CSV, HTML)
- Timestamped filename

**Use when:** Need to document or share WiFi status with others.

#### Option 5: Help
Displays usage guide and information.
- Menu option descriptions
- Signal strength interpretation
- Frequency band guide
- Troubleshooting tips

## Signal Strength Guide

### Signal Quality Levels
- **70-100%:** Excellent signal (Green)
  - Strong connection
  - Optimal performance
  - No connectivity issues expected

- **40-69%:** Good signal (Yellow)
  - Acceptable connection
  - Minor performance impact possible
  - Generally stable

- **0-39%:** Weak signal (Red)
  - Poor connection quality
  - Performance issues likely
  - Disconnections may occur

### RSSI Values
- **RSSI Range:** -100 dBm (worst) to -30 dBm (best)
- **Excellent:** -30 to -50 dBm
- **Good:** -50 to -70 dBm
- **Fair:** -70 to -85 dBm
- **Poor:** -85 to -100 dBm

## Frequency Band Guide

### 2.4 GHz Band
**Characteristics:**
- Slower speeds (up to ~150 Mbps)
- Better range and wall penetration
- More crowded (many devices use this band)
- Channels: 1-14
- Better for: Long range, older devices

**When to use:**
- Need better range
- Connecting older devices
- Thick walls or obstacles
- Less speed-critical applications

### 5 GHz Band
**Characteristics:**
- Faster speeds (up to ~1300+ Mbps)
- Less range and wall penetration
- Less crowded (fewer devices)
- Channels: 36+
- Better for: High-speed applications

**When to use:**
- Need maximum speed
- Streaming HD/4K content
- Gaming or video conferencing
- Close to router

## Troubleshooting

### No WiFi Connection Detected
**Problem:** Tool shows "Not connected to any WiFi network"

**Possible Reasons:**
- WiFi adapter disabled
- Not connected to any network
- WiFi driver issues
- Network adapter problems

**Solutions:**
- Enable WiFi adapter
- Connect to a WiFi network
- Check network adapter status
- Update WiFi drivers
- Restart network adapter

### Signal Strength Issues
**Problem:** Weak signal strength (< 40%)

**Solutions:**
- Move closer to router
- Remove obstacles between device and router
- Switch to 2.4GHz band for better range
- Check router antenna position
- Consider WiFi range extender
- Check for interference sources

### Frequent Disconnections
**Problem:** Many disconnection events in history

**Possible Causes:**
- Weak signal strength
- Router issues
- Driver problems
- Interference
- Network congestion

**Solutions:**
- Check signal strength (should be > 40%)
- Restart router
- Update WiFi drivers
- Change WiFi channel
- Switch frequency band
- Check for interference sources

### Cannot Read Disconnection History
**Problem:** No disconnection events found

**Possible Reasons:**
- Event logs not available
- Logs cleared or rotated
- Insufficient permissions
- No disconnections occurred

**Solutions:**
- Check event log permissions
- Verify event logs are enabled
- Check if logs were cleared
- May indicate stable connection (good sign)

## Use Cases

### WiFi Troubleshooting
- Diagnose connection issues
- Check signal strength
- Identify disconnection patterns
- Determine optimal frequency band
- Document connection problems

### Network Optimization
- Find best WiFi channel
- Choose optimal frequency band
- Monitor signal quality
- Identify interference issues
- Optimize router placement

### IT Support
- Document WiFi issues for clients
- Generate connection reports
- Track disconnection history
- Verify connection stability
- Troubleshoot connectivity problems

### Performance Monitoring
- Monitor signal strength over time
- Track disconnection frequency
- Identify problematic networks
- Optimize connection settings
- Document network performance

## Technical Details

### Signal Strength Calculation
- RSSI converted to percentage (0-100%)
- Formula: `((RSSI + 100) / 70) * 100`
- Range: -100 dBm (0%) to -30 dBm (100%)
- Linear conversion algorithm

### Frequency Band Detection
- Determined from channel number
- Channels 1-14: 2.4 GHz
- Channels 36+: 5 GHz
- Fallback to radio type if channel unavailable

### Disconnection History
- Reads from Windows event logs
- Primary source: `Microsoft-Windows-WLAN-AutoConfig/Operational`
- Fallback: System log
- Event IDs: 8001 (Disconnected), 8003 (Connected)
- Scans last 30 days by default

### Data Sources
- `netsh wlan show interfaces` - Current connection info
- Windows Event Logs - Disconnection history
- WLAN AutoConfig service - Connection events

## Output Files

### Report Locations
- **Desktop:** Reports saved to `%USERPROFILE%\Desktop`
- **Formats:** TXT, CSV, and HTML
- **Filename:** `WiFi_Monitor_Report_YYYYMMDD_HHMMSS.[ext]`

### Report Contents
- Current WiFi connection status
- Signal strength and RSSI
- Frequency band and channel
- Connection details
- Disconnection history (last 30 days)
- Statistics and analysis

## Best Practices

### Signal Strength
- Maintain signal strength above 40% for stable connection
- Use 5GHz band when close to router for better speed
- Use 2.4GHz band when far from router for better range
- Monitor signal strength regularly

### Disconnection Monitoring
- Check disconnection history weekly
- Investigate frequent disconnections
- Document disconnection patterns
- Use reports for troubleshooting

### Network Optimization
- Choose optimal frequency band based on needs
- Monitor channel congestion
- Update WiFi drivers regularly
- Position router optimally

## Support

For assistance or to report issues:
- **Website:** www.soulitek.co.il
- **Email:** letstalk@soulitek.co.il

---

**Coded by:** SouliTEK  
*IT Solutions for your business*

(C) 2025 SouliTEK - All Rights Reserved











