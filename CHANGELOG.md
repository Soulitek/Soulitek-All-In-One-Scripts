# Changelog

All notable changes to SouliTEK All-In-One Scripts will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

### Planned
- Code signing implementation for enhanced security
- Multi-language support (Hebrew/English)
- Automatic update checker
- Pester unit tests across modules + scripts (per audit C7)
- Dark/Light theme toggle for launcher
- Rate limiting for installer proxy

---

## [2.2.0] - 2026-05-16

### Added
- **Full modernization audit** under `docs/audits/` — 39 files (README index + cross-cutting findings + module audit + installer audit + 36 per-script audits) covering legacy-API debt, error-handling discipline, destructive-script safety, structural decomposition opportunities, test coverage gap, and an actionable 7-phase roadmap. See `docs/audits/README.md`.
- **WinGet manifests** scaffolded under `winget-manifests/` so the package can be submitted to `microsoft/winget-pkgs` (portable PowerShell installer).

### Changed
- **`scripts/bitlocker_status_report.ps1`**: recovery keys are now masked by default (`XXXXXX-...` shape preserved). Plaintext reveal requires the operator to type uppercase `YES` at a confirmation prompt. Detailed Volume Report masks unconditionally; use the dedicated Recovery Keys menu option to reveal.
- **`scripts/win11_debloat.ps1`**: before executing the remote payload from `https://debloat.raphi.re/`, the script now prints size + SHA256 + first 8 lines and requires the operator to type uppercase `YES` to proceed.
- **`scripts/mcafee_removal_tool.ps1`**: invocation of vendored `tools/MCPR.exe` now verifies its SHA256 against a pinned constant and fails closed on mismatch.
- **`hosting/.htaccess-redirect`**: rewrite targets fixed (`Soulitek-AIO` → `Soulitek-All-In-One-Scripts`). The non-existent repo name would have 404'd at minimum or, if squatted on GitHub, enabled a supply-chain attack on installs through the proxy.
- **`launcher/SouliTEK-Launcher-WPF.ps1`**: nav buttons (Help / About / GitHub / Discord / Uninstall) are no longer silently rebuilt by `Set-CategoryActive`. Build-once guard added; previously every category click recreated the WPF objects and detached their event handlers, leaving the visible buttons inert.
- **README.md**: tool count updated 33 → 32 following removal of the Domain & DNS Analyzer.

### Removed
- **`scripts/domain_dns_analyzer.ps1`** + **`tools/whois.exe`** + **`docs/domain_dns_analyzer.md`**. The script's runtime hash check for the vendored `whois.exe` binary was gated by a literal `"PASTE_SHA256_HERE"` placeholder, so every run silently skipped integrity verification. Rather than fix the placeholder, the tool was removed entirely along with its supporting docs and launcher entry.

### Security
- **Five P0 supply-chain / data-exposure fixes** landed in commits `afd50c1`, `37080c5`, `e3677d8`, `2501fd5`, `9d3ce45`. See `docs/audits/README.md` "High-impact discoveries beyond the cross-cutting list" for full enumeration with severity tags and per-fix commit references.
- **Pinned vendored-binary hash**: `tools/MCPR.exe` SHA256 = `D4D2266A19876BECCC95A97E1E5821EF42D98D503818C1E3F19BE75E9358B100`. Refreshing the binary requires updating this constant in `scripts/mcafee_removal_tool.ps1` atomically in the same commit.

### Documentation
- Modernization design spec at `docs/superpowers/specs/2026-05-15-modernize-roadmap-design.md` (the 7-phase roadmap that drove this release).
- Modernization implementation plan at `docs/superpowers/plans/2026-05-15-modernization-audit.md` (the 40-task plan that produced the audit deliverables).

---

## [2.1.0] - 2025-11-24

### Added

#### New Tool - Software Updater (22nd Tool)
- 🔄 **Software Updater** - Streamlined software update management using WinGet
  - Check for available software updates
  - List all packages with pending updates
  - Automatic update mode (silent, non-interactive)
  - Interactive update mode (review each package)
  - Update history tracking (last 50 sessions)
  - Export detailed update reports to Desktop
  - Duration tracking for each update session
  - Success/failure status recording
  - Category: Software
  - WinGet integration with automation flags
  - Easy-to-use 5-option menu system

#### Features
- **Update Checking**: Lists all available software updates via WinGet
- **Automatic Updates**: Silent, non-interactive updates for all software
- **Interactive Updates**: Review and approve each update individually
- **History Tracking**: Maintains record of last 50 update sessions
- **Report Generation**: Export detailed reports to Desktop with timestamps

#### WinGet Integration
- Automatic software update detection
- Silent, non-interactive update mode with flags:
  - `--silent` - No UI or prompts
  - `--accept-package-agreements` - Auto-accept licenses
  - `--accept-source-agreements` - Auto-accept source terms
  - `--disable-interactivity` - Prevent user prompts
- Interactive mode for selective updates
- Based on [Microsoft WinGet documentation](https://learn.microsoft.com/en-us/windows/package-manager/winget/upgrade)
- Exit code handling (0 and -1978335189 for success/partial success)

### Changed
- Updated SouliTEK Launcher to include Software Updater tool
- Positioned in Software category for easy access

### Documentation
- Created comprehensive documentation: `docs/software_updater.md`
- Includes usage examples, comparison tables, and troubleshooting guide
- Updated workflow_state.md with v2.1.0 release information

---

## [2.0.0] - 2025-11-24

### Changed

#### GUI Redesign - Compact Grid Layout
- Redesigned launcher with 3-column grid layout
- Shows 3x more tools without scrolling (6-8 vs 2-3)
- Compact tool cards: 300px × 90px (text-only, no icons)
- Removed launch buttons - entire card is clickable
- Hand cursor on hover indicates clickability
- Truncated descriptions for one-line display (~60 chars)
- Compact logo at top (50px height, 70px row)
- Combined search and categories (80px row)
- Reduced font sizes throughout (9-13px)
- Compact status bar (30px) and buttons (50px)
- Kept blue title bar (#667eea) and action button colors
- Clean, professional appearance with minimal distractions

---

## [1.0.0] - 2025-11-05

### Added

#### Core Infrastructure
- ✨ Initial public release of SouliTEK All-In-One Scripts
- 🎨 Modern WPF GUI launcher with Material Design aesthetics
- 🚀 One-line installer: `iwr -useb get.soulitek.co.il | iex`
- 📦 GitHub repository with comprehensive documentation
- 🌐 Vercel serverless function for installer distribution
- 🔧 PHP proxy option for custom domain hosting
- 📚 Extensive documentation in `docs/` folder (30+ guides)

#### Tools - Hardware (4 tools)
- 🔋 **Battery Report Generator** - Comprehensive battery health reports for laptops
  - Multiple report types (Quick, Detailed, Historical)
  - HTML visualization with graphs
  - Export to CSV/TXT formats
  - Battery wear level analysis
  
- 💾 **Storage Health Monitor** - Monitor storage health with SMART data
  - SMART attribute analysis
  - Reallocated sector detection
  - Read error monitoring
  - Health status reports
  
- 🎯 **RAM Slot Utilization Report** - RAM configuration analysis
  - Shows used vs total RAM slots
  - Memory type detection (DDR3/DDR4/DDR5)
  - Speed and capacity per slot
  - Upgrade recommendations
  
- 📊 **Disk Usage Analyzer** - Find large folders and analyze disk usage
  - Finds folders larger than 1 GB
  - HTML visualization with size charts
  - Export sorted by size
  - Space optimization suggestions

#### Tools - Security (2 tools)
- 🔒 **BitLocker Status Report** - BitLocker encryption status and recovery keys
  - Encryption status for all volumes
  - Recovery password display
  - Protection method analysis
  - Export recovery keys securely
  
- 💽 **USB Device Log** - Forensic USB device history analysis
  - Complete USB connection history
  - Device details and timestamps
  - Security audit capabilities
  - Export to multiple formats

#### Tools - M365 (3 tools)
- 📧 **PST Finder** - Locate and analyze Outlook PST files
  - Deep scan across all drives
  - PST file size analysis
  - Duplicate detection
  - Export comprehensive reports
  
- 📋 **License Expiration Checker** - Monitor Microsoft 365 licenses
  - License subscription tracking
  - Capacity utilization alerts
  - Expiration warnings
  - Automated monitoring support
  
- 👥 **M365 User List** - Complete Microsoft 365 user directory
  - Email, phone, and MFA status
  - Comprehensive user information
  - Department and role tracking
  - Export to CSV/HTML/JSON

#### Tools - Network (3 tools)
- 📡 **WiFi Password Viewer** - View and export saved WiFi passwords
  - Display all saved networks
  - Current network quick view
  - Export to file (TXT/CSV)
  - Quick copy to clipboard
  
- 🌐 **Network Test Tool** - Comprehensive network diagnostics
  - Ping testing with statistics
  - Traceroute with hop analysis
  - DNS lookup and validation
  - Latency testing
  
- ⚙️ **Network Configuration Tool** - Network adapter configuration
  - View IP configuration
  - Set static IP addresses
  - Flush DNS cache
  - Reset network adapters

#### Tools - Support (4 tools)
- 🖨️ **Printer Spooler Fix** - Comprehensive printer troubleshooting
  - Spooler service repair
  - Print queue clearing
  - Driver issue detection
  - Monitoring mode
  
- 📝 **Event Log Analyzer** - Windows Event Log analysis
  - Statistical summaries
  - Error pattern detection
  - Export to CSV/HTML/JSON
  - Custom time range filtering
  
- ⏮️ **System Restore Point** - Create Windows System Restore Points
  - Quick restore point creation
  - Custom descriptions
  - VSS integration
  - Verification support
  
- 🧹 **Temp Removal & Disk Cleanup** - System cleanup and space recovery
  - Temporary file removal
  - Browser cache cleaning
  - Recycle Bin emptying
  - Before/after size comparison

#### Tools - Software (1 tool)
- 📦 **Chocolatey Installer** - Interactive package installer
  - Ninite-like user experience
  - Popular software packages
  - Category-based browsing
  - Batch installation support

### Changed
- 🔧 Refactored battery reporting script for better reliability (2025-11-06)
- 🔍 Cleaned up WiFi viewer regex patterns for improved parsing (2025-11-06)
- 📖 Updated README and support documentation (2025-11-06)
- 🏗️ Improved script structure and error handling across all tools

### Fixed
- 🐛 Battery report generator permission handling
- 🐛 WiFi password viewer network parsing edge cases
- 🐛 Network configuration tool input validation
- 🐛 Event log analyzer memory optimization for large logs

### Removed
- 🗑️ Build artifacts directory (legacy files)
- 🗑️ Personal information from all files
- 🗑️ DEBUG statements from production code
- 🗑️ Unused configuration files

### Security
- 🔒 Implemented secure credential handling via OAuth2
- 🔐 Added administrator privilege checks where required
- ✅ Comprehensive security audit completed (2025-11-05)
- 🛡️ WiFi Password Viewer includes legal disclaimer
- 🔑 BitLocker recovery keys handled securely
- 🌐 Microsoft Graph authentication uses secure flows
- 📝 No sensitive data stored or logged

### Documentation
- 📚 Created comprehensive README.md with quick start
- 📖 Individual documentation for all 18 tools
- 🚀 Installation guides (Quick Install, Deployment Guide)
- 🌐 Vercel and custom domain setup documentation
- 🔧 WPF Launcher user guide
- 📋 Complete API documentation for M365 tools
- ⚙️ Network configuration and troubleshooting guides

---

## Project History

### Pre-Release Development (2024-2025)
- Initial development of core PowerShell tools
- Creation of common module for shared functionality
- Development of WPF GUI launcher
- Security audits and code reviews
- Beta testing with select IT professionals
- Documentation and deployment preparation

---

## Version Numbering

This project follows [Semantic Versioning](https://semver.org/):
- **MAJOR** version for incompatible API changes
- **MINOR** version for new functionality in a backwards compatible manner
- **PATCH** version for backwards compatible bug fixes

---

## Categories

### Added
New features and tools added to the project.

### Changed
Changes to existing functionality or improvements.

### Deprecated
Features that will be removed in upcoming releases.

### Removed
Features or files that have been removed.

### Fixed
Bug fixes and error corrections.

### Security
Security-related changes, vulnerability fixes, and improvements.

---

## Release Notes

### v1.0.0 - "Foundation" (2025-11-05)

**Highlights:**
- 🎉 **18 Professional IT Tools** - Complete toolkit for IT technicians
- 🖥️ **Modern GUI Launcher** - Beautiful WPF interface with search and filtering
- 📦 **One-Line Installation** - Simple deployment for end users
- 🔒 **Security First** - Comprehensive security audit passed
- 📚 **Extensive Documentation** - 30+ documentation files

**Statistics:**
- Total Scripts: 18
- Lines of Code: ~15,000+
- Documentation Files: 31
- Supported Windows: 8.1, 10, 11
- PowerShell: 5.1+

**Why v1.0.0?**
After extensive development, testing, and three comprehensive security audits, the project reached production-ready status. All critical features are implemented, documented, and tested. This release represents a stable foundation for future enhancements.

**Special Thanks:**
- SouliTEK team for development and testing
- Beta testers for valuable feedback
- IT professionals who provided feature suggestions

---

## Future Roadmap

### v1.1.0 (Planned: 2026)
- Code signing for all PowerShell scripts
- Integrity verification system
- Automatic update checker
- Enhanced M365 integration
- Performance optimizations

### v1.2.0 (Planned: 2026)
- Multi-language support (Hebrew/English)
- Dark/Light theme toggle
- Additional network diagnostic tools
- Enhanced reporting capabilities
- CI/CD pipeline integration

### v2.0.0 (Planned: Future)
- Cloud integration features
- Remote management capabilities
- Enterprise licensing options
- Advanced automation features
- API for third-party integration

---

## How to Update

### Automatic (Future Feature)
```powershell
# When update checker is implemented
Update-SouliTEK
```

### Manual
```powershell
# Re-run the installer
iwr -useb get.soulitek.co.il | iex
```

This will download and install the latest version, preserving your settings.

---

## Support

**Found a bug?** [Open an issue on GitHub](https://github.com/Soulitek/Soulitek-All-In-One-Scripts/issues)

**Have a question?** Email us at letstalk@soulitek.co.il

**Want to contribute?** See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines

---

*© 2025 SouliTEK - Professional IT Solutions*  
*Made with ❤️ in Israel*

