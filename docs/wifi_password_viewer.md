# WiFi Password Viewer

## Overview

The **WiFi Password Viewer** allows you to view and backup WiFi passwords that are saved on your Windows computer. It's designed for IT professionals and users who need to retrieve saved WiFi network passwords.

## Purpose

Retrieves saved WiFi passwords:
- View all saved WiFi networks
- Display WiFi passwords
- Export password list
- Backup WiFi credentials
- Current network password

## Features

### 📶 **WiFi Network List**
- All saved WiFi profiles
- Network names (SSIDs)
- Security types
- Connection status

### 🔑 **Password Retrieval**
- View WiFi passwords
- Decrypt saved passwords
- Display security keys
- Network authentication info

### 💾 **Export Options**
- Export to text file
- Export to CSV format
- Password backup
- Secure storage

### 🔍 **Search Functionality**
- Search specific network
- Filter networks
- Quick password lookup
- Network identification

## Requirements

### System Requirements
- **OS:** Windows 10 or Windows 11
- **PowerShell:** Version 5.1 or higher
- **Privileges:** Standard user (no admin required)
- **WiFi:** WiFi adapter and saved networks

## Usage

### Running the Script

1. **Launch from SouliTEK Launcher** (recommended)
   - Open the SouliTEK Launcher
   - Find "WiFi Password Viewer" in the Network category
   - Click the tool card to launch

2. **Run directly via PowerShell:**
   ```powershell
   .\scripts\wifi_password_viewer.ps1
   ```

### Important Legal Notice

⚠️ **LEGAL NOTICE:** This tool should only be used on your own computer or with explicit permission from the computer owner. Unauthorized access to WiFi passwords may be illegal in your jurisdiction.

### Menu Options

#### Option 1: View All Networks
Displays all saved WiFi networks.
- Network names (SSIDs)
- Security types
- Connection status
- Quick overview

#### Option 2: View Specific Network Password
Shows password for selected network.
- Select network from list
- Display password
- Security information
- Network details

#### Option 3: View Current Network Password
Shows password for currently connected network.
- Active connection password
- Current network info
- Quick access
- No selection needed

#### Option 4: Export All Passwords
Exports all WiFi passwords to file.
- All networks and passwords
- Text file format
- CSV format option
- Password backup

#### Option 5: Search Network
Searches for specific network.
- Enter network name
- Find matching networks
- Display password
- Quick lookup

## Security Considerations

### Password Protection
- Passwords are displayed in plain text
- Handle exported files securely
- Store backups in secure location
- Don't share passwords unnecessarily

### Legal Use
- Only use on your own devices
- Obtain permission for other devices
- Follow local laws and regulations
- Respect privacy and security

### Best Practices
- Store exported files securely
- Use encryption for password backups
- Limit access to password files
- Delete files when no longer needed

## Troubleshooting

### No Networks Found
**Problem:** No WiFi networks displayed

**Possible Reasons:**
- No WiFi networks saved
- WiFi adapter not available
- No saved profiles

**Solutions:**
- Connect to WiFi networks first
- Check WiFi adapter is enabled
- Verify networks are saved
- Some networks may not save passwords

### Cannot Retrieve Password
**Problem:** Password not available for network

**Causes:**
- Network password not saved
- Enterprise network (different authentication)
- Network uses certificate authentication
- Password stored differently

**Solutions:**
- Password may not be stored locally
- Enterprise networks use different authentication
- Some networks don't store passwords
- Check network authentication type

### Access Denied
**Problem:** Cannot access WiFi profiles

**Solutions:**
1. Some networks require admin access
2. Check user permissions
3. Verify WiFi adapter access
4. Run as Administrator if needed

## Use Cases

### Password Recovery
- Forgot WiFi password
- Need password for new device
- Share network with others
- Backup passwords

### IT Management
- Document network passwords
- Backup WiFi credentials
- Network inventory
- Troubleshooting

### Device Setup
- Configure new devices
- Share network access
- Setup instructions
- Network documentation

## Best Practices

### Password Management
- Store passwords securely
- Use password manager
- Encrypt password backups
- Limit password sharing

### Security
- Don't share passwords publicly
- Use strong passwords
- Change default passwords
- Regular password updates

### Backup
- Regular password backups
- Secure storage location
- Encrypted backups
- Access control

## Technical Details

### Password Storage
- Windows stores WiFi passwords encrypted
- Tool decrypts passwords for display
- Uses Windows netsh commands
- Accesses WiFi profile data

### Network Information
- SSID (Network name)
- Security type (WPA2, WPA3, etc.)
- Authentication method
- Encryption type

## Output Files

### Report Locations
- **Desktop:** Reports saved to `%USERPROFILE%\Desktop`
- **Formats:** TXT and CSV
- **Filename:** `WiFiPasswords_YYYYMMDD_HHMMSS.[ext]`

### Report Contents
- Network names (SSIDs)
- Passwords
- Security types
- Connection information

## Support

For assistance or to report issues:
- **Website:** www.soulitek.co.il
- **Email:** letstalk@soulitek.co.il

---

**Coded by:** SouliTEK  
*IT Solutions for your business*

(C) 2025 SouliTEK - All Rights Reserved











