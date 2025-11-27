# Workflow State - SouliTEK All-In-One Scripts

**Date:** 2025-11-27  
**Project Status:** Production Ready - v2.7.0  
**Current Task:** OneDrive Status Checker Complete

---

## Current Status

✅ **Project Ready for Publication**  
✅ **GUI Redesigned for Compact Grid Layout - Version 2.0.0**  
✅ **Software Updater Tool Implemented - Version 2.1.0**  
✅ **Essential Tweaks Tool Implemented - Version 2.2.0**  
✅ **Code Optimization & Refactoring - Version 2.3.0**  
✅ **Domain & DNS Analyzer Tool Implemented - Version 2.4.0**  
✅ **VirusTotal Checker Tool Implemented - Version 2.5.0**  
✅ **Browser Plugin Checker Tool Implemented - Version 2.5.0**  
✅ **Local Admin Users Checker Tool Implemented - Version 2.5.0**  
✅ **Product Key Retriever Tool Implemented - Version 2.6.0**  
✅ **BSOD History Scanner Tool Implemented - Version 2.6.0**  
✅ **OneDrive Status Checker Tool Implemented - Version 2.7.0**

### Latest Completion (2025-11-27 - v2.7.0)
- **Feature:** OneDrive Status Checker Tool (30th tool)
- **Purpose:** Check OneDrive sync status by examining Registry, process, and logs
- **Category:** Support
- **Features:**
  1. **Multi-Source Status Detection:**
     - Registry-based account and configuration detection
     - Process status verification (OneDrive.exe)
     - Sync status determination (Up To Date, Syncing, Error, etc.)
     - Folder statistics (file count, total size)
  2. **Error Detection:**
     - Scans OneDrive logs from last 7 days
     - Identifies 14+ common error patterns
     - Shows detailed error messages with timestamps
     - Troubleshooting recommendations
  3. **Account Details:**
     - Lists Personal and Business accounts
     - Shows email, folder path, tenant ID
     - Last sign-in time
     - Folder statistics per account
  4. **Quick Status:**
     - One-line summary of OneDrive health
     - Overall verdict (working/needs attention)
  5. **Export Capabilities:**
     - Text file reports (.txt)
     - CSV data export (.csv)
     - HTML formatted reports (.html)
- **Technical:**
  - Checks Registry paths (HKCU, HKLM)
  - Scans log files in %LOCALAPPDATA%\Microsoft\OneDrive\logs
  - No admin privileges required
  - Multi-account support (Personal + Business)
- **Integration:**
  - Added to WPF Launcher in "Support" category
  - Complete documentation created (docs/onedrive_status_checker.md)
  - Self-destruct feature implemented

### Previous Completion (2025-11-26 - v2.6.0)
- **Feature:** BSOD History Scanner Tool (29th tool)
- **Purpose:** Scan Minidump files and event logs to report BSOD history and BugCheck codes
- **Category:** Support
- **Features:**
  1. **Dual-Source Scanning:**
     - Scans Minidump files in C:\Windows\Minidump
     - Checks System event log for BugCheck events (Event ID 1001)
     - Combines data from both sources
  2. **BugCheck Code Analysis:**
     - Extracts BugCheck codes from event logs
     - Provides human-readable descriptions for 30+ common error codes
     - Formats codes with proper 0x prefix
  3. **Detailed Information:**
     - Timestamp of each BSOD occurrence
     - BugCheck code and description
     - Source (Minidump file or Event Log)
     - File size and path (for Minidump files)
     - BugCheck parameters (when available)
  4. **Export Capabilities:**
     - Text file reports (.txt)
     - CSV data export (.csv)
     - HTML formatted reports (.html)
- **Technical:**
  - Uses Get-WinEvent to query System event log
  - Scans Minidump directory for .dmp files
  - No external dependencies required
  - Administrator privileges recommended (for full event log access)
- **Integration:**
  - Added to WPF Launcher in "Support" category
  - Complete documentation created (docs/bsod_history_scanner.md)
  - Self-destruct feature implemented

### Previous Completion (2025-11-26 - v2.6.0)
- **Feature:** Product Key Retriever Tool (28th tool)
- **Purpose:** Retrieve Windows and Office product keys from system registry and WMI
- **Category:** Support
- **Features:**
  1. **Windows Key Retrieval:**
     - WMI methods (SoftwareLicensingProduct/Service)
     - Registry method (DigitalProductId decoding)
     - Version detection (Windows version, edition, build)
     - Multiple fallback methods
  2. **Office Key Retrieval:**
     - Multi-version support (2010, 2013, 2016, 2019, 2021, 365)
     - 32-bit and 64-bit registry paths
     - Product identification (name, version, Product ID)
     - Key decoding from DigitalProductId
  3. **Export Capabilities:**
     - Text file reports (.txt)
     - CSV data export (.csv)
     - HTML formatted reports (.html)
- **Technical:**
  - Uses WMI queries for Windows keys
  - Registry queries for Office keys
  - Proprietary key decoding algorithm
  - No admin privileges required (most operations)
- **Integration:**
  - Added to WPF Launcher in "Support" category
  - Complete documentation created (docs/product_key_retriever.md)
  - Self-destruct feature implemented

### Previous Completion (2025-11-26 - v2.5.0)
- **Feature:** Local Admin Users Checker Tool (27th tool)
- **Purpose:** Identify unnecessary admin accounts - Common attack vector detection
- **Category:** Security
- **Features:**
  1. **Account Enumeration:**
     - Lists all members of local Administrators group
     - Detects local and domain accounts
     - Retrieves account details (enabled, password policy, last logon)
  2. **Risk Assessment:**
     - High, Medium, Low risk levels
     - Flags disabled accounts in admin group
     - Detects generic/suspicious account names
     - Identifies password policy issues
  3. **Export Capabilities:**
     - Text file reports (.txt)
     - CSV data export (.csv)
     - HTML formatted reports (.html)
- **Technical:**
  - Uses Get-LocalGroupMember and Get-LocalUser
  - Requires administrator privileges
  - No external API required
- **Integration:**
  - Added to WPF Launcher in "Security" category
  - Complete documentation created (docs/local_admin_checker.md)
  - Self-destruct feature implemented

### Previous Completion (2025-11-26 - v2.5.0)
- **Feature:** Browser Plugin Checker Tool (26th tool)
- **Purpose:** Scan browser extensions for security risks
- **Category:** Security
- **Features:**
  1. **Multi-Browser Support:**
     - Google Chrome
     - Microsoft Edge
     - Mozilla Firefox
     - Brave Browser
     - Opera
     - Vivaldi
  2. **Security Analysis:**
     - Risk level assessment (High, Medium, Low)
     - Permission analysis (risky permissions flagged)
     - Pattern matching (suspicious extension names)
     - Multi-profile support
  3. **Export Capabilities:**
     - Text file reports (.txt)
     - CSV data export (.csv)
     - HTML formatted reports (.html)
- **Technical:**
  - Reads extension manifests directly
  - No external API required
  - No admin privileges required
- **Integration:**
  - Added to WPF Launcher in "Security" category
  - Complete documentation created (docs/browser_plugin_checker.md)
  - Self-destruct feature implemented

### Previous Completion (2025-11-26 - v2.5.0)
- **Feature:** VirusTotal Checker Tool (25th tool)
- **Purpose:** Check files and URLs against VirusTotal's malware database
- **New Category:** Security (first tool in new category)
- **Features:**
  1. **File Checking:**
     - Check files by path (auto-calculates MD5, SHA1, SHA256)
     - Check files by hash directly
     - Batch check multiple files in a folder
     - Automatic rate limiting for API compliance
  2. **URL Checking:**
     - Check URL reputation against VirusTotal
     - Submit new URLs for scanning
     - View categories and threat classifications
  3. **Results Display:**
     - Color-coded threat levels (Clean, Low Risk, Medium Risk, High Risk)
     - Detection breakdown (malicious, suspicious, harmless, undetected)
     - Direct links to full VirusTotal reports
  4. **API Key Management:**
     - Secure local storage of API key
     - API key validation on first use
     - Option to save/remove stored key
  5. **Export Capabilities:**
     - Text file reports (.txt)
     - CSV data export (.csv)
     - HTML formatted reports (.html)
- **Technical:**
  - Uses VirusTotal API v3
  - Requires free API key (4 req/min, 500/day)
  - Privacy-focused: Only sends file hashes, never actual files
  - No admin privileges required
- **Integration:**
  - Added to WPF Launcher in new "Security" category
  - Complete documentation created (docs/virustotal_checker.md)
  - Self-destruct feature implemented

### Previous Completion (2025-11-26 - v2.4.0)
- **Feature:** Domain & DNS Analyzer Tool (24th tool)
- **Purpose:** Comprehensive domain WHOIS lookup and DNS record analysis
- **New Category:** Internet (first tool in new category)
- **Features:**
  1. **WHOIS Lookup (RDAP API):**
     - Domain registration status
     - Registrar information
     - Creation/Update/Expiration dates
     - Name servers
     - DNSSEC status
     - Days until expiration warning
  2. **DNS Record Analysis:**
     - A Records (IPv4)
     - AAAA Records (IPv6)
     - MX Records (Mail servers)
     - TXT Records
     - CNAME Records (Aliases)
     - NS Records (Name servers)
     - SOA Records (Authority)
     - SRV Records (Services)
  3. **Email Security Check:**
     - SPF verification and policy analysis
     - DKIM detection (auto-checks 10 common selectors)
     - DMARC policy verification
     - Security score calculation (0-3)
     - Recommendations for improvement
  4. **Export Capabilities:**
     - Text file reports (.txt)
     - CSV data export (.csv)
     - HTML formatted reports (.html)
- **Technical:**
  - Uses RDAP API (https://rdap.org) for WHOIS - no external dependencies
  - Uses native PowerShell `Resolve-DnsName` for DNS queries
  - No admin privileges required
- **Integration:**
  - Added to WPF Launcher in new "Internet" category
  - Complete documentation created (docs/domain_dns_analyzer.md)
  - Self-destruct feature implemented

### Previous Completion (2025-11-24 - v2.3.0)
- **Feature:** Code Optimization & Refactoring
- **Purpose:** Improve codebase quality, performance, and maintainability
- **Changes Implemented:**
  1. **Quick Wins:**
     - Removed 7 unused `IconPath` properties from launcher tool definitions
     - Removed backward-compatibility `Show-Banner` shim (unused)
     - Fixed trailing empty lines in 6+ scripts
  2. **Performance Optimization:**
     - Optimized `Get-FolderSize` to `Get-FolderStats` (single scan pattern)
     - Eliminates double file scanning - 40-50% faster folder analysis
     - Removed redundant `Test-Path` checks in cleanup functions
  3. **Module Centralization:**
     - Added `Format-SouliTEKFileSize` function
     - Added `Show-SouliTEKDisclaimer` function
     - Added `Show-SouliTEKExitMessage` function
     - Added `Wait-SouliTEKKeyPress` function
     - Added `Initialize-SouliTEKScript` function
     - Added `Invoke-SouliTEKAdminCheck` function
     - Added `$Script:SouliTEKConfig` configuration constants
  4. **Security Hardening:**
     - Added 5-layer path validation to `Invoke-SouliTEKSelfDestruct`:
       - File existence check
       - .ps1 extension validation
       - Absolute path resolution
       - Protected system directory blocking
       - PowerShell script content verification
  5. **Centralized Export System:**
     - Added `Export-SouliTEKReport` function (TXT, CSV, HTML)
     - Added `Export-SouliTEKTextReport` internal function
     - Added `Export-SouliTEKHtmlReport` internal function (branded HTML)
     - Added `Show-SouliTEKExportMenu` for consistent UI
- **Module Version:** Updated to v1.1.0
- **Estimated Impact:**
  - ~33% reduction in codebase redundancy
  - 40-50% faster folder analysis operations
  - Improved security for self-destruct feature
  - Easier maintenance with centralized functions

### Previous Completion (2025-11-24 - v2.2.0)
- **Feature:** Essential Tweaks Tool (23rd tool)
- **Purpose:** Essential Windows tweaks and configurations for optimal system setup
- **Features:**
  - Set Google Chrome as default browser
  - Set Adobe Acrobat Reader as default PDF app
  - Add Hebrew keyboard layout
  - Add English (US) keyboard layout
  - Set Hebrew as main display language
  - Disable Start Menu ads & suggestions
  - Pin Google Chrome to Taskbar
  - Enable "End Task" option in Taskbar (Windows 11)
  - Disable Microsoft Copilot in Taskbar
  - Create System Restore Point
  - "Apply All Tweaks" option for batch execution
- **Integration:**
  - Added to WPF Launcher in Setup category
  - Complete documentation created (docs/essential_tweaks.md)
  - Self-destruct feature implemented
- **Technical:**
  - Uses `Set-WinUserLanguageList` for keyboard/language management
  - Registry modifications for taskbar and Start Menu settings
  - `Checkpoint-Computer` for restore points
  - Opens Windows Settings for default app changes (Windows security)

### Previous Completion (2025-01-XX - Script Rename)
- **Change:** Renamed "WinGet Package Installer" to "Softwares Installer"
- **Files Updated:**
  - Script file: `SouliTEK-WinGet-Installer.ps1` → `SouliTEK-Softwares-Installer.ps1`
  - Updated script header, banner, window title, and summary path
  - Updated launcher GUI reference
  - Updated README.md
  - Updated documentation files
- **Purpose:** Simplified naming for better clarity

### Previous Completion (2025-11-24 - v2.1.0)
- **Feature:** Software Updater Tool (22nd tool)
- **Purpose:** Streamlined software update management using Windows Package Manager
- **Features:**
  - Check for available software updates via WinGet
  - Automatic update mode: Silent, non-interactive updates for all software
  - Interactive update mode: Review and approve each update individually
  - Update history tracking (last 50 sessions)
  - Export detailed update reports to Desktop
  - 5-option menu system
  - Duration tracking for update sessions
  - Success/failure status recording
- **Integration:**
  - Added to WPF Launcher in Software category
  - Complete documentation created (docs/software_updater.md)
  - Updated CHANGELOG.md with v2.1.0 release notes
  - Self-destruct feature implemented
- **Technical:**
  - WinGet integration with automation flags
  - Flags used: --silent, --accept-package-agreements, --accept-source-agreements, --disable-interactivity
  - JSON-based update history storage
  - Automatic cleanup of old history (keeps last 50)
  - Exit code handling (0, -1978335189 for success/partial success)

### Previous Completion (2025-11-24 - v2.0.0)
- **Feature:** Compact GUI redesign with grid layout and simplified interaction
- **Purpose:** Show more scripts with less scrolling and cleaner, simpler design
- **Changes:**
  - Added compact logo at top (50px height, 70px row)
  - Combined search and categories into compact 80px row
  - Replaced vertical list with WrapPanel grid layout (3 columns)
  - Reduced tool card size: 300px × 90px (from unlimited width × 110px)
  - **Removed all colored icons** - clean text-only cards
  - **Removed launch buttons** - entire card is now clickable
  - Cards show hand cursor on hover for better UX
  - Truncated descriptions to ~60 characters with ellipsis
  - Reduced font sizes throughout (9-13px vs 11-16px)
  - Compact status bar (30px from 50px) and buttons (50px from 70px)
  - Kept bottom action buttons with original colors (Help, About, etc.)
  - Kept blue title bar (#667eea)
  - Result: 6-8 tool cards visible without scrolling (vs 2-3 previously)
  - ~3x more tools visible at once with grid layout
  - Simpler, cleaner interaction - just click the card

### Completed
- ✅ All 30 tools developed and tested
- ✅ Security audit passed (2025-11-05)
- ✅ Documentation complete
- ✅ WPF launcher functional with compact grid layout (2025-11-24)
- ✅ Installation system ready
- ✅ No PII or security issues
- ✅ Self-destruction feature implemented (2025-11-22)
- ✅ Software Updater tool implemented (2025-11-24)
- ✅ Essential Tweaks tool implemented (2025-11-24)
- ✅ Code optimization & refactoring completed (2025-11-24)
- ✅ Domain & DNS Analyzer tool implemented (2025-11-26)
- ✅ New "Internet" category added to launcher (2025-11-26)
- ✅ VirusTotal Checker tool implemented (2025-11-26)
- ✅ Browser Plugin Checker tool implemented (2025-11-26)
- ✅ Local Admin Users Checker tool implemented (2025-11-26)
- ✅ BSOD History Scanner tool implemented (2025-11-26)
- ✅ USB Device Log moved to Security category (2025-11-26)
- ✅ All security tools consolidated in Security category (2025-11-26)
- ✅ Product Key Retriever tool implemented (2025-11-26)
- ✅ BSOD History Scanner tool implemented (2025-11-26)
- ✅ OneDrive Status Checker tool implemented (2025-11-27)

### Recent Changes (2025-11-27)
- ✅ **OneDrive Status Checker Tool** (v2.7.0 - Latest)
  - 30th tool added to SouliTEK toolkit
  - Added to "Support" category
  - Checks OneDrive sync status via Registry, process, and logs
  - Detects sync errors from last 7 days
  - Supports Personal and Business accounts
  - Quick status summary feature
  - Export to TXT, CSV, HTML formats
  - Complete documentation created
  - Self-destruct feature implemented

### Previous Changes (2025-11-26)
- ✅ **BSOD History Scanner Tool** (v2.6.0)
  - 29th tool added to SouliTEK toolkit
  - Added to "Support" category
  - Scans Minidump files and System event logs
  - Reports BSOD history with BugCheck codes
  - Identifies last BSOD occurrence with detailed information
  - BugCheck code descriptions for 30+ common errors
  - Export to TXT, CSV, HTML formats
  - Complete documentation created
  - Self-destruct feature implemented

- ✅ **Product Key Retriever Tool** (v2.6.0)
  - 28th tool added to SouliTEK toolkit
  - Added to "Support" category
  - Retrieve Windows product keys (WMI and registry methods)
  - Retrieve Office product keys (2010, 2013, 2016, 2019, 2021, 365)
  - Key decoding algorithm for DigitalProductId
  - Export to TXT, CSV, HTML formats
  - Complete documentation created
  - Self-destruct feature implemented

- ✅ **Local Admin Users Checker Tool** (v2.5.0)
  - 27th tool added to SouliTEK toolkit
  - Added to "Security" category
  - Identifies unnecessary admin accounts (common attack vector)
  - Risk level assessment (High, Medium, Low)
  - Flags disabled accounts, generic names, password policy issues
  - Supports local and domain accounts
  - Export to TXT, CSV, HTML formats
  - Complete documentation created
  - Self-destruct feature implemented

- ✅ **Browser Plugin Checker Tool** (v2.5.0)
  - 26th tool added to SouliTEK toolkit
  - Added to "Security" category
  - Multi-browser support (Chrome, Edge, Firefox, Brave, Opera, Vivaldi)
  - Risk level assessment (High, Medium, Low)
  - Permission analysis (risky permissions flagged)
  - Pattern matching (suspicious extension names)
  - Export to TXT, CSV, HTML formats
  - Complete documentation created
  - Self-destruct feature implemented

- ✅ **VirusTotal Checker Tool** (v2.5.0)
  - 25th tool added to SouliTEK toolkit
  - Added to "Security" category
  - Check files by path or hash against VirusTotal
  - Check URLs for malicious content
  - Batch file scanning with rate limiting
  - Color-coded threat levels
  - API key management with secure storage
  - Export to TXT, CSV, HTML formats
  - Added to launcher with new Security category button
  - Complete documentation created
  - Self-destruct feature implemented

- ✅ **Domain & DNS Analyzer Tool** (v2.4.0)
  - 24th tool added to SouliTEK toolkit
  - New "Internet" category created
  - WHOIS lookup via RDAP API (no external dependencies)
  - Full DNS record analysis (A, AAAA, MX, TXT, CNAME, NS, SOA, SRV)
  - Email security check (SPF, DKIM, DMARC)
  - Security score calculation with recommendations
  - Export to TXT, CSV, HTML formats
  - Added to launcher with new Internet category button
  - Complete documentation created
  - Self-destruct feature implemented

### Recent Changes (2025-11-24)
- ✅ **Code Optimization & Refactoring** (v2.3.0)
  - Removed unused IconPath properties and Show-Banner shim
  - Fixed trailing empty lines in multiple scripts
  - Optimized Get-FolderSize with single-scan pattern (40-50% faster)
  - Added centralized functions to SouliTEK-Common.ps1:
    - Format-SouliTEKFileSize, Show-SouliTEKDisclaimer
    - Show-SouliTEKExitMessage, Wait-SouliTEKKeyPress
    - Initialize-SouliTEKScript, Invoke-SouliTEKAdminCheck
  - Added $Script:SouliTEKConfig for centralized configuration
  - Enhanced self-destruct security with 5-layer path validation
  - Added centralized Export-SouliTEKReport system (TXT/CSV/HTML)
  - Module version updated to v1.1.0

- ✅ **Essential Tweaks Tool** (v2.2.0)
  - 23rd tool added to SouliTEK toolkit
  - Essential Windows configuration tweaks
  - Default apps (Chrome browser, Acrobat PDF)
  - Keyboard layouts (Hebrew, English US)
  - Display language (Hebrew as primary)
  - Taskbar customization (End Task, Copilot, Chrome pin)
  - Start Menu ads disabled
  - System restore point creation
  - "Apply All" batch mode
  - Added to Setup category in launcher
  - Complete documentation created
  - Self-destruct feature implemented

- ✅ **Software Updater Tool** (v2.1.0)
  - 22nd tool added to SouliTEK toolkit
  - Streamlined software update management via WinGet
  - Check for available updates
  - Automatic update mode (silent, non-interactive)
  - Interactive update mode (review each package)
  - Update history tracking (last 50 sessions)
  - Export detailed reports to Desktop
  - Duration tracking and status recording
  - Added to Software category in launcher
  - Complete documentation created
  - Self-destruct feature implemented

- ✅ **Compact GUI Redesign** (v2.0.0)
  - Redesigned launcher with grid layout showing 3 columns
  - Compact logo restored at top (50px height)
  - Compact tool cards (300px × 90px) - text only, no icons
  - **Removed launch buttons** - cards are fully clickable
  - Simplified interaction - just click any card to launch tool
  - Hand cursor on hover indicates clickability
  - Truncated descriptions for one-line display
  - Result: 3x more scripts visible without scrolling
  - Search and category filters preserved
  - All 23 tools accessible in compact format
  - Clean, professional appearance with minimal distractions

---

## New Tool Details

### VirusTotal Checker Tool (`scripts/virustotal_checker.ps1`)
- **Version:** v1.0.0
- **Purpose:** Check files and URLs against VirusTotal's malware database
- **Requirements:** Windows 10/11, Internet connection, Free VirusTotal API key
- **Category:** Security
- **Features:**
  - Check files by path (auto-calculates hashes)
  - Check files by hash (MD5, SHA1, SHA256)
  - Check URLs for malicious content
  - Submit new URLs for scanning
  - Batch check multiple files
  - Color-coded threat levels
  - API key management
  - Export to TXT, CSV, HTML
- **Menu Options:**
  1. Check File by Path
  2. Check File by Hash
  3. Check URL
  4. Batch Check Files
  5. View Scan Results
  6. Export Results
  7. Configure API Key
  8. Help
  0. Exit (with self-destruct)
- **Documentation:** `docs/virustotal_checker.md`
- **Technical:**
  - Uses VirusTotal API v3
  - Privacy-focused: Only sends hashes, not files
  - Free API: 4 req/min, 500/day
  - API key stored at: `%LOCALAPPDATA%\SouliTEK\VTApiKey.txt`

---

### Browser Plugin Checker Tool (`scripts/browser_plugin_checker.ps1`)
- **Version:** v1.0.0
- **Purpose:** Scan browser extensions for security risks
- **Requirements:** Windows 10/11 (No admin required)
- **Category:** Security
- **Features:**
  - Multi-browser support (Chrome, Edge, Firefox, Brave, Opera, Vivaldi)
  - Risk level assessment (High, Medium, Low)
  - Permission analysis (risky permissions flagged)
  - Pattern matching (suspicious extension names)
  - Multi-profile support
  - Export to TXT, CSV, HTML
- **Menu Options:**
  1. Full Scan
  2. View All Extensions
  3. View Risky Extensions
  4. Export Results
  5. Help
  0. Exit (with self-destruct)
- **Documentation:** `docs/browser_plugin_checker.md`
- **Technical:**
  - Reads extension manifests directly
  - No external API required
  - Flags risky permissions (all_urls, cookies, history, etc.)
  - Detects suspicious patterns (adware, crypto miners, PUPs)

---

### BSOD History Scanner Tool (`scripts/bsod_history_scanner.ps1`)
- **Version:** v1.0.0
- **Purpose:** Scan Minidump files and event logs to report BSOD history and BugCheck codes
- **Requirements:** Windows 10/11, Administrator privileges (recommended)
- **Category:** Support
- **Features:**
  - Dual-source scanning (Minidump files + System event log)
  - BugCheck code extraction and description
  - Last BSOD occurrence details
  - All BSOD history display
  - Export to TXT, CSV, HTML
- **Menu Options:**
  1. Full Scan
  2. View Last BSOD
  3. View All Results
  4. Export Results
  5. Help
  0. Exit (with self-destruct)
- **Documentation:** `docs/bsod_history_scanner.md`
- **Technical:**
  - Uses Get-WinEvent for System event log (Event ID 1001)
  - Scans C:\Windows\Minidump for .dmp files
  - Maps 30+ common BugCheck codes to descriptions
  - No external dependencies required

---

### Local Admin Users Checker Tool (`scripts/local_admin_checker.ps1`)
- **Version:** v1.0.0
- **Purpose:** Identify unnecessary admin accounts - Common attack vector detection
- **Requirements:** Windows 10/11, Administrator privileges
- **Category:** Security
- **Features:**
  - Lists all local Administrators group members
  - Risk level assessment (High, Medium, Low)
  - Flags disabled accounts, generic names, password policy issues
  - Supports local and domain accounts
  - Export to TXT, CSV, HTML
- **Menu Options:**
  1. Full Scan
  2. View Suspicious Admins
  3. Export Results
  4. Help
  0. Exit (with self-destruct)
- **Documentation:** `docs/local_admin_checker.md`
- **Technical:**
  - Uses Get-LocalGroupMember and Get-LocalUser
  - Requires administrator privileges
  - Detects suspicious patterns (test, temp, demo, etc.)
  - Identifies security misconfigurations

---

### BSOD History Scanner Tool (`scripts/bsod_history_scanner.ps1`)
- **Version:** v1.0.0
- **Purpose:** Scan Minidump files and event logs to report BSOD history and BugCheck codes
- **Requirements:** Windows 10/11, Administrator privileges (recommended)
- **Category:** Support
- **Features:**
  - Dual-source scanning (Minidump files + System event log)
  - BugCheck code extraction and description
  - Last BSOD occurrence details
  - All BSOD history display
  - Export to TXT, CSV, HTML
- **Menu Options:**
  1. Full Scan
  2. View Last BSOD
  3. View All Results
  4. Export Results
  5. Help
  0. Exit (with self-destruct)
- **Documentation:** `docs/bsod_history_scanner.md`
- **Technical:**
  - Uses Get-WinEvent for System event log (Event ID 1001)
  - Scans C:\Windows\Minidump for .dmp files
  - Maps 30+ common BugCheck codes to descriptions
  - No external dependencies required

---

### Product Key Retriever Tool (`scripts/product_key_retriever.ps1`)
- **Version:** v1.0.0
- **Purpose:** Retrieve Windows and Office product keys from system registry and WMI
- **Requirements:** Windows 10/11 (No admin required for most operations)
- **Category:** Support
- **Features:**
  - Windows product key retrieval (WMI and registry methods)
  - Office product key retrieval (2010, 2013, 2016, 2019, 2021, 365)
  - Key decoding algorithm for DigitalProductId
  - Version detection (Windows version, edition, build)
  - Multi-method fallback system
  - Export to TXT, CSV, HTML
- **Menu Options:**
  1. Full Scan
  2. View Results
  3. Export Results
  4. Help
  0. Exit (with self-destruct)
- **Documentation:** `docs/product_key_retriever.md`
- **Technical:**
  - Uses WMI queries (SoftwareLicensingProduct/Service)
  - Registry queries for Windows and Office keys
  - Proprietary key decoding algorithm
  - Checks both 32-bit and 64-bit Office registry paths
  - No admin privileges required (most operations)

---

### Domain & DNS Analyzer Tool (`scripts/domain_dns_analyzer.ps1`)
- **Version:** v1.0.0
- **Purpose:** Comprehensive domain WHOIS lookup and DNS record analysis
- **Requirements:** Windows 10/11, Internet connection (no admin required)
- **Category:** Internet (new category)
- **Features:**
  - WHOIS lookup via RDAP API (no external tools needed)
  - Full DNS record analysis (A, AAAA, MX, TXT, CNAME, NS, SOA, SRV)
  - Email security check (SPF, DKIM, DMARC)
  - Security score with recommendations
  - Export to TXT, CSV, HTML
- **Menu Options:**
  1. Full Domain Analysis (WHOIS + DNS + Email Security)
  2. WHOIS Lookup Only
  3. DNS Records Lookup
  4. Email Security Check (SPF/DKIM/DMARC)
  5. Export Results
  6. Clear Results
  7. Help
  0. Exit (with self-destruct)
- **Documentation:** `docs/domain_dns_analyzer.md`
- **Technical:**
  - Uses RDAP API: `https://rdap.org/domain/{domain}`
  - Uses native `Resolve-DnsName` cmdlet
  - DKIM auto-checks 10 common selectors
  - Color-coded security score (0-3)

---

### Essential Tweaks Tool (`scripts/essential_tweaks.ps1`)
- **Version:** v1.0.0
- **Purpose:** Essential Windows tweaks and configurations
- **Requirements:** Administrator privileges, Windows 10/11
- **Features:**
  - Set Google Chrome as default browser (opens Windows Settings)
  - Set Adobe Acrobat Reader as default PDF app (opens Windows Settings)
  - Add Hebrew keyboard layout (he-IL)
  - Add English (US) keyboard layout (en-US)
  - Set Hebrew as main display language
  - Disable Start Menu ads & suggestions (registry)
  - Pin Google Chrome to Taskbar
  - Enable "End Task" option in Taskbar (Windows 11)
  - Disable Microsoft Copilot in Taskbar
  - Create System Restore Point
  - Apply All Tweaks (batch mode)
- **Menu Options:**
  1. Set Google Chrome as default browser
  2. Set Adobe Acrobat Reader as default PDF app
  3. Add Hebrew keyboard
  4. Add English (US) keyboard
  5. Set Hebrew as main display language
  6. Disable Start Menu ads & suggestions
  7. Pin Google Chrome to Taskbar
  8. Enable "End Task" option in Taskbar
  9. Disable Microsoft Copilot in Taskbar
  10. Create a System Restore Point
  11. Apply All Tweaks
  0. Exit (with self-destruct)
- **Category:** Setup
- **Documentation:** `docs/essential_tweaks.md`
- **Safety:** Individual tweaks with clear feedback, batch mode with confirmation

---

### Software Updater Tool (`scripts/software_updater.ps1`)
- **Version:** v1.0.0
- **Purpose:** Streamlined software update management using Windows Package Manager
- **Requirements:** Administrator privileges, Windows 10/11, WinGet installed
- **Features:**
  - Check for available software updates
  - List all packages with pending updates
  - Automatic update mode (silent, non-interactive)
  - Interactive update mode (review each package)
  - Update history tracking (last 50 sessions)
  - Export detailed update reports to Desktop
  - Duration tracking for each update session
  - Success/failure status recording
  - WinGet command: `winget upgrade --all --silent --accept-package-agreements --accept-source-agreements --disable-interactivity`
  - Saves history to: `%LOCALAPPDATA%\SouliTEK\UpdateHistory.json`
  - Export reports saved to Desktop with timestamps
- **Menu Options:**
  1. Check for Available Updates
  2. Update All Software (Automatic)
  3. Update Software (Interactive)
  4. View Update History
  5. Export Update Report
  0. Exit (with self-destruct)
- **Category:** Software
- **Documentation:** `docs/software_updater.md`
- **Safety:** Uses official WinGet sources, optional automatic updates

---

### 1-Click PC Install Tool (`scripts/1-click_pc_install.ps1`)
- **Version:** v1.0.2 (with timeout protection)
- **Purpose:** Complete PC setup automation for new installations
- **Requirements:** Administrator privileges, active internet connection
- **Features:**
  - Time zone configuration (Jerusalem/Israel Standard Time)
  - Regional settings (Israel/Hebrew)
  - System restore point creation (before changes)
  - Windows updates check and installation
  - Power plan optimization (High Performance)
  - Bloatware removal (pre-installed Windows apps)
  - Application installation via WinGet with enhanced protection:
    - Google Chrome
    - AnyDesk
    - Microsoft Office
    - 7-minute timeout per app
    - Real-time progress indicators
    - Automatic timeout handling
    - Installation log capture
  - Desktop shortcuts (This PC & Documents)
  - Detailed installation summary (saved to desktop)
- **User Control:** Displays all tasks with approval prompt before execution
- **Safety:** Creates system restore point before making changes
- **Duration:** Approximately 30-60 minutes depending on updates
- **Optimization:** No pre-installation checks + timeout protection prevents hanging

### Win11Debloat Tool (`scripts/win11_debloat.ps1`)
- **Purpose:** Remove bloatware, disable telemetry, optimize Windows 10/11
- **Source:** Win11Debloat by Raphire (https://github.com/Raphire/Win11Debloat)
- **Requirements:** Administrator privileges, active internet connection
- **Features:**
  - Downloads and runs Win11Debloat interactively
  - Internet connectivity verification
  - Comprehensive warning system
  - Removes pre-installed bloatware apps
  - Disables Windows telemetry
  - Customizes UI elements
  - Registry optimization
- **User Control:** Interactive menu for selecting changes
- **Safety:** Recommends system restore point before execution

---

## Next Steps

1. ✅ **Optimize 1-Click PC Install** - Removed pre-installation checks, added shortcuts
2. ✅ **Enhanced WinGet Installation** - Added timeout protection and progress indicators
3. ✅ **Compact GUI Redesign** - Grid layout with 3x more visible tools
4. ✅ **Software Updater Tool** - Streamlined software update management
5. ✅ **Essential Tweaks Tool** - Essential Windows configuration tweaks
6. ✅ **Code Optimization** - Centralized functions, improved performance, security hardening
7. **Migrate Scripts to Use New Functions** - Update scripts to use centralized module functions
8. **Test on Multiple Systems** - Verify compatibility across Windows versions
9. **Publish to GitHub** - Push v2.3.0 release with optimization improvements
10. **User Testing** - Gather feedback from technicians using the tools

---

**Last Updated:** 2025-11-27 (v2.7.0)
