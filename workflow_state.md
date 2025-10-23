# Workflow State

## Current Status: ✅ Completed

---

## Completed Workflows

### ✅ Created: URL-Based Quick Installer (2025-10-23)

**Objective:** Enable one-line installation from URL for quick deployment on new PCs.

**Features Implemented:**

1. **One-Line Installation**
   - Run from URL: `iwr -useb [URL] | iex`
   - No manual download required
   - Perfect for new PC setup
   - Works from any PowerShell window

2. **Automatic Installation Process**
   - Downloads latest version from GitHub
   - Extracts to C:\SouliTEK
   - Creates desktop shortcut
   - Offers immediate launch option
   - Cleans up temporary files

3. **Installation Features**
   - TLS 1.2 secure download
   - Progress indicators for each step
   - Error handling with helpful messages
   - Admin detection and warnings
   - Old version auto-removal (updates)

4. **Desktop Integration**
   - Automatic shortcut creation
   - Icon support (if available)
   - Proper PowerShell execution arguments
   - Working directory configuration

5. **Comprehensive Documentation**
   - Created QUICK_INSTALL.md (full guide)
   - Multiple installation methods
   - Troubleshooting section
   - Usage scenarios
   - Security considerations
   - Update & uninstall instructions

6. **URL Options**
   - Primary GitHub raw URL
   - Support for short URLs (bit.ly, tinyurl)
   - Custom domain capability
   - Easy to memorize for technicians

**Files Created:**
1. `Install-SouliTEK.ps1` - Quick installer script (250+ lines)
2. `docs/QUICK_INSTALL.md` - Complete installation guide (500+ lines)

**Updated Files:**
1. `README.md` - Added one-line install to Quick Start section
2. `workflow_state.md` - Updated with completed workflow

**Installation Command:**
```powershell
iwr -useb https://raw.githubusercontent.com/Soulitek/Soulitek-AIO/main/Install-SouliTEK.ps1 | iex
```

**Use Cases:**
- New PC setup (0 to ready in 30 seconds)
- Remote support sessions (instant tool deployment)
- Customer site visits (no USB drive needed)
- Quick updates (rerun to get latest version)
- Training sessions (everyone installs quickly)

**Benefits:**
- No manual downloads
- No ZIP extraction
- No file copying
- Always latest version
- Professional deployment

**Result:** Complete URL-based installation system ready for production use.

---

### ✅ Added: Custom Domain Hosting Support (2025-10-23)

**Objective:** Enable hosting the installer on custom domain (soulitek.co.il) for easier branding and access.

**Features Implemented:**

1. **Multiple Hosting Methods**
   - Simple redirect (.htaccess)
   - PHP proxy with logging
   - Direct hosting
   - Cloudflare Workers support

2. **Ready-to-Use Files**
   - `hosting/install-proxy.php` - PHP proxy with download logging
   - `hosting/.htaccess-redirect` - Simple Apache redirect
   - `hosting/landing-page.html` - Beautiful landing page with copy button
   - `hosting/README.md` - Hosting setup instructions

3. **Custom Domain Configuration**
   - Subdomain setup (get.soulitek.co.il)
   - Path-based (soulitek.co.il/install)
   - DNS configuration guide
   - SSL/HTTPS setup

4. **Landing Page Features**
   - One-click command copy
   - Step-by-step instructions
   - Tool showcase with icons
   - Mobile responsive design
   - Professional branding

5. **Download Analytics**
   - PHP proxy logs downloads
   - IP address tracking
   - User-agent detection
   - Timestamp logging
   - Easy stats viewing

6. **Comprehensive Documentation**
   - `docs/CUSTOM_DOMAIN_SETUP.md` - Complete setup guide
   - `CUSTOM_DOMAIN_QUICK_SETUP.md` - Quick reference
   - `hosting/README.md` - File explanations
   - Testing procedures
   - Troubleshooting guide

**Files Created:**
1. `hosting/install-proxy.php` - PHP proxy (150+ lines)
2. `hosting/.htaccess-redirect` - Apache redirect config
3. `hosting/landing-page.html` - Landing page (300+ lines)
4. `hosting/README.md` - Hosting documentation
5. `docs/CUSTOM_DOMAIN_SETUP.md` - Setup guide (600+ lines)
6. `CUSTOM_DOMAIN_QUICK_SETUP.md` - Quick setup (200+ lines)

**Updated Files:**
1. `URL_INSTALL_SUMMARY.md` - Added custom domain option

**Installation Commands:**

**GitHub (default):**
```powershell
iwr -useb https://raw.githubusercontent.com/Soulitek/Soulitek-AIO/main/Install-SouliTEK.ps1 | iex
```

**Custom Domain (branded):**
```powershell
iwr -useb get.soulitek.co.il | iex
```

**Benefits:**
- Easier to remember and share
- Professional branding
- Custom URL control
- Download analytics
- Faster with CDN (optional)
- Better marketing presence

**Result:** Complete custom domain hosting solution with multiple methods and beautiful landing page.

---

## Completed Workflows

### ✅ Created: License Expiration Checker (2025-10-23)

**Objective:** Created a PowerShell script to monitor Microsoft 365 tenant license subscriptions and alert administrators about capacity issues.

**Features Implemented:**

1. **Microsoft Graph Integration**
   - Uses Get-MgSubscribedSku to retrieve all tenant licenses
   - Secure OAuth 2.0 authentication via browser
   - Connection status monitoring
   - Requires Organization.Read.All permission
   - Automatic disconnect on exit

2. **License Monitoring**
   - Displays all Microsoft 365 license subscriptions
   - Shows total seats, used seats, available seats
   - Calculates usage percentages
   - Friendly SKU name translation (40+ licenses mapped)
   - Real-time capacity warnings

3. **Color-Coded Alert System**
   - RED (Critical): No available seats - immediate action required
   - YELLOW (Warning): 5 or fewer seats remaining - plan to purchase
   - GREEN (OK): Sufficient seat availability
   - Visual usage bars in HTML reports

4. **Alert Delivery Methods**
   - Email alerts with HTML formatting and SMTP configuration
   - Microsoft Teams webhook notifications
   - Standalone HTML alert reports
   - Automatic identification of licenses needing attention

5. **Detailed Reporting**
   - Comprehensive service plan breakdowns
   - Shows all included services per license
   - Provisioning status for each service
   - Complete license property analysis

6. **Usage Statistics**
   - Overall tenant statistics (total, used, available)
   - Top 5 license consumers with visual bars
   - Licenses requiring attention list
   - Allocation recommendations
   - Usage trend indicators

7. **Export Functionality**
   - Text format (.txt) - Human-readable reports
   - CSV format (.csv) - Spreadsheet analysis
   - HTML format (.html) - Professional web reports with styling
   - All formats option for complete documentation

8. **Professional Interface**
   - Menu-based navigation with 7 options
   - Real-time connection status display
   - Color-coded output for easy interpretation
   - Comprehensive help guide built-in
   - Soulitek branding throughout

9. **Security Features**
   - Read-only permissions (Organization.Read.All)
   - No access to user personal data
   - Secure browser-based authentication
   - Automatic session cleanup

**Files Created:**
1. `scripts/license_expiration_checker.ps1` - Main PowerShell script (1200+ lines)
2. `docs/LICENSE_EXPIRATION_CHECKER.md` - Comprehensive documentation (800+ lines)

**Key Functions:**
- Connect-ToMicrosoftGraph: Secure authentication
- Get-LicenseStatus: Display all subscriptions
- Get-DetailedLicenseReport: Service plan breakdown
- Get-LicenseUsageStatistics: Allocation analysis
- Send-ExpirationAlert: Multi-method alerting
- Export-LicenseReport: Multiple format exports
- Get-FriendlySkuName: SKU translation (40+ licenses)

**Alert Thresholds:**
- Critical: 0 available seats (red alert)
- Warning: ≤5 available seats (yellow alert)
- OK: >5 available seats (green status)

**Use Cases:**
- Prevent service disruptions from license shortages
- Capacity planning and budget forecasting
- License optimization and cost reduction
- Compliance documentation and auditing
- Proactive license management

**Requirements:**
- Microsoft Graph PowerShell SDK
- Global Administrator or Global Reader role
- Organization.Read.All permission
- Internet connectivity to graph.microsoft.com

**Result:** Complete, production-ready license monitoring tool ready for Microsoft 365 tenant management.

---

### ✅ Fixed: GUI Launcher Icons and Favicon (2025-10-23)

**Objective:** Replace emoji icons with ASCII-safe alternatives and add favicon to GUI launcher window.

**Changes Made:**
1. Removed all emoji category icons - categories now show clean text labels only:
   - All, Network, Security, Support, Software, M365, Hardware

2. Removed search icon - changed from 🔍 to plain "Search:" label

3. Added window icon/favicon support:
   - Automatically loads Favicon.png from assets/images
   - Graceful fallback if icon file not found
   - Sets form icon for professional branding

**Result:** GUI launcher now uses ASCII-safe icons throughout, preventing encoding errors while maintaining visual clarity. Window icon enhances professional appearance.

---

## Completed Workflows

### ✅ Optimized: Main Menu with Search & Category Filtering (2025-10-23)

**Objective:** Enhanced the launcher GUI with search-first UX and intelligent category filtering system.

**Features Implemented:**

1. **Search-First UX**
   - Prominent search box at the top of the interface
   - Real-time filtering as you type
   - Searches across tool name, description, category, and tags
   - Case-insensitive matching
   - "No results" message when filters don't match any tools
   - Status bar updates to show filtered tool count

2. **Category Filtering System**
   - 7 category buttons: All, Network, Security, Support, Software, M365, Hardware
   - Color-coded category buttons matching tool themes
   - Toggle selection with visual feedback (filled when selected)
   - Icon indicators for each category (⚡ Network, 🛡 Security, etc.)
   - Combines with search filter for powerful multi-criteria filtering

3. **Enhanced Tool Organization**
   - Added M365 category for Microsoft 365/Office tools
   - Reorganized tool categories for better logical grouping
   - Added comprehensive tags to each tool for better searchability
   - Tags include: "printer", "outlook", "backup", "network", "encryption", etc.

4. **UI Improvements**
   - Clean filter panel with modern design
   - Category buttons with hover effects
   - Search box with subtle background color
   - Responsive layout that maintains tool card aesthetics
   - Smooth transitions between filtered views
   - Dynamic status updates

5. **Filtering Logic**
   - `Test-ToolMatchesFilter` function checks both category and search criteria
   - `Update-ToolsDisplay` function rebuilds tool list dynamically
   - Efficient filtering without page reload
   - Maintains scroll position and performance

**Tool Categories:**
- **Network** (2 tools): WiFi Password Viewer, Network Test Tool
- **Security** (2 tools): BitLocker Status Report, USB Device Log
- **Support** (3 tools): Printer Spooler Fix, Event Log Analyzer, Remote Support Toolkit
- **Software** (1 tool): Chocolatey Installer
- **M365** (1 tool): PST Finder
- **Hardware** (1 tool): Battery Report Generator

**Search Examples:**
- Type "printer" → Shows Printer Spooler Fix
- Type "network" → Shows WiFi Password Viewer, Network Test Tool
- Type "outlook" → Shows PST Finder (via tags)
- Type "encryption" → Shows BitLocker Status Report

**Result:** Professional, user-friendly launcher with powerful search and filtering capabilities that make finding tools quick and intuitive.

---

### ✅ Created: SouliTEK Chocolatey Package Installer (2025-10-23)

**Objective:** Create a comprehensive PowerShell script that mimics Ninite's UX for installing applications via Chocolatey with interactive TUI menu, preset support, and professional logging.

**Features Implemented:**

1. **Interactive TUI Menu**
   - Keyboard-driven checklist interface
   - Up/Down navigation, Space to toggle
   - Real-time package selection tracking
   - Right-side panel with package descriptions
   - Visual cursor and selection indicators

2. **Search & Filtering**
   - Type-ahead search across Name/ID/Category/Notes
   - Category view switching (All, Browsers, Utilities, Dev, etc.)
   - Select all/none within filtered results
   - Live filter counts display

3. **Preset System**
   - Save selected packages as JSON presets to Desktop
   - Load presets from JSON files
   - CLI parameter for preset-based silent install
   - Preset format: JSON array of package IDs

4. **Chocolatey Bootstrap**
   - Auto-installs Chocolatey if missing
   - TLS 1.2+ secure download
   - PATH refresh after installation
   - Graceful failure with clear messaging

5. **Idempotent Installation**
   - Checks existing installations via `choco list --local-only`
   - Skips already-installed packages unless -Force
   - Tracks install/skip/fail status per package
   - Elapsed time tracking per package

6. **Package Catalog (40+ Apps)**
   - Browsers: Chrome, Firefox, Edge
   - Runtimes: .NET Desktop Runtime, VC++ Redistributables
   - Utilities: 7-Zip, Notepad++, Everything, CCleaner, Adobe Reader, WinRAR
   - Communications: Zoom, Teams, Slack, AnyDesk, Discord, Skype
   - Media: VLC, Spotify, Audacity, HandBrake
   - Development: Git, VS Code, Node.js, Python, Docker, Postman
   - Sysadmin: Sysinternals, WireGuard, PuTTY, WinSCP, TeamViewer
   - Security: KeePass, Bitwarden, VeraCrypt

7. **Professional Logging**
   - Transcript log in `%ProgramData%\SouliTEK\ChocoInstaller\Logs\`
   - JSON summary on Desktop with machine details
   - Console summary table with color-coded statuses
   - Per-package status tracking (Installed/Skipped/Failed)

8. **CLI Parameters**
   - `-Preset <path>`: Install from preset file, no UI
   - `-Category <name>`: Start filtered by category
   - `-Force`: Reinstall/upgrade existing packages
   - `-Source <url>`: Custom Chocolatey source
   - `-Pre`: Allow pre-release packages
   - `-WhatIf`: Simulate installs without changes

9. **Elevation & Safety**
   - Auto-elevation with parameter preservation
   - Process-scope execution policy (no machine changes)
   - Admin privilege detection and relaunch
   - Graceful Ctrl+C handling with partial summary

10. **Reboot Handling**
    - Detects packages requiring reboot (exit code 3010)
    - Tracks global reboot requirement flag
    - Prompts user at end: "Reboot now? (Y/N)"
    - Executes `shutdown /r /t 10` if confirmed

**Files Created:**
1. `scripts/SouliTEK-Choco-Installer.ps1` - Main installer script (1000+ lines)
2. `docs/CHOCO_INSTALLER.md` - Comprehensive documentation (400+ lines)

**Quality Features:**
- SouliTEK ASCII banner with branding
- Color-coded output (Green=Success, Yellow=Skip, Red=Fail, Magenta=WhatIf)
- Real-time progress indicators during installation
- Comprehensive error handling (try/catch blocks)
- Defensive coding with meaningful error messages
- Helper functions: Ensure-Admin, Ensure-Choco, Show-Menu, Install-Packages, etc.

**Acceptance Criteria Met:**
✅ Interactive menu opens and installs selected apps via Chocolatey  
✅ `-Preset` parameter installs packages silently without menu  
✅ Auto-installs Chocolatey when missing and proceeds  
✅ Idempotent: skips installed packages unless -Force  
✅ Generates console summary, JSON summary, and transcript log  
✅ Works on Windows 10/11 PowerShell 5.1+ with no external dependencies  

**Result:** Complete, production-ready Chocolatey installer with Ninite-like UX.

### ✅ Created: USB Device Log - Forensic Tool (2025-10-23)

**Objective:** Created a professional PowerShell script to list last connected USB devices for forensic review.

**Features Implemented:**
1. **Registry Analysis**
   - USBSTOR registry scanning
   - USB device enumeration
   - Device type, vendor, product parsing
   - Serial number extraction
   - VID/PID correlation
   - Install date & last connected timestamps
   - Device status reporting

2. **Event Log Analysis**
   - Microsoft-Windows-DriverFrameworks-UserMode/Operational log queries
   - System log USB event tracking
   - Event IDs: 2003, 2100, 2101, 2102, 2105, 2106, 20001, 20003, 10000, 10100
   - 30-day event history

3. **SetupAPI Log Review**
   - Windows inf\setupapi.dev.log parsing
   - USB installation entry counting
   - Log availability checking

4. **Device Information Collected**
   - Device Name & Friendly Name
   - Vendor & Product Information
   - Serial Number (Unique Identifier)
   - VID (Vendor ID) & PID (Product ID)
   - Device Type & Revision
   - Installation Date & Last Connected
   - Device Status & Registry Path

5. **Export Functionality**
   - Text format (.txt) - Human-readable forensic report
   - CSV format (.csv) - Spreadsheet analysis
   - HTML format (.html) - Professional web report with modern styling
   - All formats option

6. **Professional Interface**
   - Menu-based navigation
   - Color-coded output
   - Three-stage analysis display
   - Real-time progress indicators
   - Comprehensive help guide
   - Soulitek branding

**Files Created:**
1. `scripts/usb_device_log.ps1` - Main PowerShell script (1200+ lines)
2. `docs/USB_DEVICE_LOG.md` - Comprehensive documentation

**Forensic Use Cases:**
- Security incident response
- Unauthorized device identification
- Data exfiltration investigation
- Compliance & policy enforcement
- IT troubleshooting
- Legal/HR investigations

**Result:** Complete, production-ready USB forensic tool ready for security audits and incident response.

---

### ✅ Created: Network Test Tool PowerShell Script (2025-10-23)

**Objective:** Created a professional network testing tool with comprehensive diagnostics capabilities.

**Features Implemented:**
1. **Ping Test (Advanced)**
   - Configurable ping count (up to 100)
   - Real-time latency display with color coding
   - Min/Max/Average statistics
   - Packet loss calculation
   - Connection quality assessment

2. **Trace Route**
   - Full path tracing to destination
   - Hop-by-hop latency display
   - Up to 30 hops
   - Completion status tracking

3. **DNS Lookup**
   - A record (IPv4) resolution
   - AAAA record (IPv6) resolution
   - CNAME record detection
   - TTL display
   - DNS server identification

4. **Latency Test (Continuous)**
   - Real-time monitoring (up to 5 minutes)
   - Jitter calculation
   - Packet loss tracking
   - Statistical analysis (Min/Max/Avg/StdDev)
   - Quality assessment

5. **Quick Diagnostics**
   - Local network test (gateway)
   - Internet connectivity test
   - DNS resolution test
   - Network adapter status
   - DNS server configuration

6. **Export Functionality**
   - Text format (.txt)
   - CSV format (.csv)
   - HTML report (.html)
   - Professional formatting with Soulitek branding

**Files Created:**
1. `scripts/network_test_tool.ps1` - Main PowerShell script (1100+ lines)
2. `docs/NETWORK_TEST_TOOL.md` - Comprehensive documentation

**Features:**
- Professional menu-based interface
- Color-coded results for easy interpretation
- Real-time monitoring capabilities
- Comprehensive error handling
- Test result history tracking
- Multiple export formats
- Soulitek branding throughout
- Disclaimer and legal notices
- Professional exit messages

**Quality Indicators:**
- Excellent connection: < 50ms latency, 0% loss (Green)
- Good connection: 50-100ms latency, < 1% loss (Yellow)
- Fair connection: 100-200ms latency, < 5% loss (Yellow)
- Poor connection: > 200ms latency or > 5% loss (Red)

**Result:** Complete, production-ready network testing tool ready for use.

---

### ✅ Fixed: Event Log Analyzer Invalid Query Error (2025-10-23)

**Problem:** Event Log Analyzer was failing with "The specified query is invalid" error for all Windows Event Logs (Application, System, Security).

**Root Cause:** The XML query construction had a complex nested string interpolation inside the here-string, causing the Level filter portion `($($levels | ForEach-Object { "Level=$_" }) -join ' or ')` to fail during XML parsing.

**Solution Implemented:**
- Separated Level filter construction from XML here-string
- Built $levelFilter variable before XML construction
- Added enhanced error handling with specific catch for "invalid query" errors
- Added verbose logging of actual XML query for debugging
- Removed unused variables ($filterHash, $logInfo)

**Changes Made:**
1. `scripts/EventLogAnalyzer.ps1` - Fixed XML query construction (lines 301-336)
2. `docs/EVENT_ANALYZER_FIX.md` - Created comprehensive fix documentation
3. `workflow_state.md` - Updated with fix progress

**Result:**
- XML query now constructs properly with cleaner code
- Better error messages for troubleshooting
- Verbose mode shows actual query for debugging
- All linter warnings resolved

---

### ✅ Fixed: Remote Support Toolkit Terminal Closing Issue (2025-10-23)

**Problem:** 
1. When clicking "Launch" on Remote Support Toolkit from the GUI launcher, the terminal window immediately closed
2. Encoding errors with special characters (checkmarks and bullets) causing parser errors

**Root Cause:** 
1. The launcher was starting PowerShell scripts without the `-NoExit` flag, causing the window to close immediately
2. Unicode characters (✓ and •) were causing encoding issues and parser errors on some systems

**Solution Implemented:**
- Modified the `Start-Tool` function in `launcher/SouliTEK-Launcher.ps1` to add `-NoExit` flag
- Replaced Unicode checkmarks (✓) with ASCII-safe `[+]` in `scripts/remote_support_toolkit.ps1`
- Replaced bullet points (•) with ASCII hyphens (-) in the same file
- Fixed unused variable warning in the script
- Updated documentation in `docs/GUI_LAUNCHER_GUIDE.md`

**Changes Made:**
1. `launcher/SouliTEK-Launcher.ps1` - Added `-NoExit` flag, removed unused variable
2. `scripts/remote_support_toolkit.ps1` - Fixed encoding issues with special characters, cleaned up unused variables
3. `docs/GUI_LAUNCHER_GUIDE.md` - Updated troubleshooting section with new information

**Result:** 
- PowerShell windows now remain open when launching tools
- No more parser errors from special characters
- Script runs cleanly without encoding issues

---

## Log
- 2025-10-23: Created custom domain hosting solution for soulitek.co.il
- 2025-10-23: Added hosting/install-proxy.php with download logging and analytics
- 2025-10-23: Created hosting/landing-page.html with beautiful UI and one-click copy
- 2025-10-23: Added hosting/.htaccess-redirect for simple Apache redirects
- 2025-10-23: Created docs/CUSTOM_DOMAIN_SETUP.md (comprehensive guide, 600+ lines)
- 2025-10-23: Created CUSTOM_DOMAIN_QUICK_SETUP.md for rapid deployment
- 2025-10-23: Added hosting/README.md with file explanations and setup instructions
- 2025-10-23: Documented multiple hosting methods (redirect, PHP proxy, Cloudflare Workers)
- 2025-10-23: Created URL-based quick installer for one-line deployment (Install-SouliTEK.ps1)
- 2025-10-23: Added comprehensive QUICK_INSTALL.md documentation (500+ lines)
- 2025-10-23: Created DEPLOYMENT_CHECKLIST.md for repository deployment
- 2025-10-23: Created QUICK_INSTALL_CHEATSHEET.md for quick reference
- 2025-10-23: Updated README.md with one-line install command in Quick Start
- 2025-10-23: Added automatic download, extraction, installation, and shortcut creation
- 2025-10-23: Implemented TLS 1.2 secure downloads from GitHub
- 2025-10-23: Added admin detection and proper error handling
- 2025-10-23: Added License Expiration Checker to GUI launcher menu (11 tools total)
- 2025-10-23: Fixed linter warnings in License Expiration Checker (removed unused variables)
- 2025-10-23: Created License Expiration Checker for Microsoft 365 license monitoring
- 2025-10-23: Implemented Microsoft Graph integration with Get-MgSubscribedSku
- 2025-10-23: Added color-coded alert system (Critical/Warning/OK) based on seat availability
- 2025-10-23: Created alert delivery methods (Email, Teams webhook, HTML reports)
- 2025-10-23: Added detailed license reporting with service plan breakdowns
- 2025-10-23: Implemented usage statistics with visual bars and top consumers
- 2025-10-23: Added export functionality (TXT, CSV, HTML formats)
- 2025-10-23: Created friendly SKU name mapping for 40+ Microsoft 365 licenses
- 2025-10-23: Added comprehensive documentation (LICENSE_EXPIRATION_CHECKER.md)
- 2025-10-23: Included setup guides for Teams webhooks and email alerts
- 2025-10-23: Fixed favicon path resolution error - using $Script:RootPath instead of $MyInvocation which was null in function context
- 2025-10-23: Removed all category icons - categories now display clean text labels only (All, Network, Security, Support, Software, M365, Hardware)
- 2025-10-23: Removed search icon - changed from emoji 🔍 to plain "Search:" label (no icon)
- 2025-10-23: Added window favicon support - loads Favicon.png from assets/images for professional branding
- 2025-10-23: Redesigned Chocolatey Installer menu with 2-column grid layout and 4-way arrow navigation (Up/Down/Left/Right)
- 2025-10-23: Updated documentation to reflect new grid layout and navigation controls
- 2025-10-23: Removed 3 apps from Chocolatey Installer: Skype, K-Lite Codec Pack, Audacity (39 packages total)
- 2025-10-23: Fixed Unicode encoding errors in ALL 10 PowerShell scripts - systematically replaced box-drawing characters and emojis with ASCII-safe alternatives
- 2025-10-23: Fixed printer_spooler_fix.ps1, wifi_password_viewer.ps1, EventLogAnalyzer.ps1, remote_support_toolkit.ps1, network_test_tool.ps1, usb_device_log.ps1, SouliTEK-Choco-Installer.ps1
- 2025-10-23: Replaced Hebrew text in EventLogAnalyzer.ps1 with English equivalent
- 2025-10-23: Fixed emojis in HTML reports (BitLocker, Remote Support, Network Test)
- 2025-10-23: Fixed FindPST.ps1 - removed switch parameter default value and cleaned up unused variables
- 2025-10-23: Fixed Unicode encoding error in bitlocker_status_report.ps1 - replaced emoji and box-drawing characters with ASCII-safe alternatives
- 2025-10-23: Fixed Unicode encoding error in battery_report_generator.ps1 - replaced box-drawing characters with ASCII-safe alternatives
- 2025-10-23: Cleaned up unused variables in battery_report_generator.ps1 - replaced with [void] to suppress output
- 2025-10-23: Fixed StatusLabel initialization order in GUI launcher - moved Update-ToolsDisplay call to after GUI components are created
- 2025-10-23: Optimized GUI launcher with search-first UX and category filtering system
- 2025-10-23: Added real-time search box that filters tools by name, description, category, and tags
- 2025-10-23: Implemented 7 category filter buttons (All, Network, Security, Support, Software, M365, Hardware)
- 2025-10-23: Added comprehensive tags to all 10 tools for better searchability
- 2025-10-23: Reorganized tool categories - created M365 category for Office 365 tools
- 2025-10-23: Enhanced filtering logic with Test-ToolMatchesFilter and Update-ToolsDisplay functions
- 2025-10-23: Added visual feedback for active category selection with color-coded buttons
- 2025-10-23: Added SouliTEK ASCII banner and contact details to all 9 PowerShell scripts
- 2025-10-23: Contact info displayed: https://soulitek.co.il | letstalk@soulitek.co.il
- 2025-10-23: Updated scripts: battery_report, bitlocker, event_analyzer, findpst, network_test, printer_spooler, remote_support, usb_device_log, wifi_password
- 2025-10-23: Updated Chocolatey Installer package catalog (removed 7 packages, added AnyDesk)
- 2025-10-23: Streamlined package list: 3 browsers, 2 runtimes, 6 utilities, 6 communications apps
- 2025-10-23: Fixed smart quote encoding issue in Chocolatey Installer (line 533)
- 2025-10-23: Added Chocolatey Installer to GUI launcher menu (10 tools total)
- 2025-10-23: Updated README to reflect 10 available tools
- 2025-10-23: Created SouliTEK Chocolatey Package Installer with Ninite-like TUI, preset support, and auto-bootstrap
- 2025-10-23: Added comprehensive documentation for Chocolatey Installer in docs/CHOCO_INSTALLER.md
- 2025-10-23: Implemented interactive menu with keyboard navigation (40+ packages across 8 categories)
- 2025-10-23: Added preset save/load functionality with JSON format
- 2025-10-23: Implemented idempotent installation with skip logic and force reinstall option
- 2025-10-23: Added professional logging system with transcript and JSON summary reports
- 2025-10-23: Fixed encoding errors in GUI launcher by replacing Unicode emojis with ASCII-safe alternatives
- 2025-10-23: Added USB Device Log tool to GUI launcher (9 tools total)
- 2025-10-23: Replaced problematic Unicode characters: emojis, bullet points, special symbols
- 2025-10-23: Created USB Device Log - Forensic Tool for USB device history analysis
- 2025-10-23: Added comprehensive documentation for USB Device Log in docs/USB_DEVICE_LOG.md
- 2025-10-23: Implemented three-stage analysis: Registry, Event Logs, SetupAPI
- 2025-10-23: Added forensic-level details: VID/PID, serial numbers, timestamps, device status
- 2025-10-23: Implemented multiple export formats (TXT, CSV, HTML) with professional styling
- 2025-10-23: Created BitLocker Status Report tool with comprehensive encryption checking and recovery key management
- 2025-10-23: Added detailed documentation for BitLocker Status Report in docs/BITLOCKER_STATUS_REPORT.md
- 2025-10-23: Implemented health check system with security scoring (0-100%)
- 2025-10-23: Added multiple export formats (TXT, CSV, HTML) with professional styling
- 2025-10-23: Added BitLocker Status Report to GUI launcher menu
- 2025-10-23: Updated project README to reflect 8 available tools
- 2025-10-23: Created Network Test Tool with ping, tracert, DNS lookup, latency testing, quick diagnostics, and export features
- 2025-10-23: Added comprehensive documentation for Network Test Tool in docs/NETWORK_TEST_TOOL.md
- 2025-10-23: Updated GUI launcher to include Network Test Tool with professional branding
- 2025-10-23: Updated project README to reflect 7 available tools (before BitLocker)
- 2025-10-23: Fixed terminal closing issue in GUI launcher by adding -NoExit flag
- 2025-10-23: Fixed encoding/parser errors in Remote Support Toolkit by replacing Unicode characters with ASCII equivalents
- 2025-10-23: Fixed Event Log Analyzer "invalid query" error by improving XML query construction

