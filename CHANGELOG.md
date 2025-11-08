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
- Integrity verification system with SHA256 checksums
- Pester unit tests for core functionality
- Dark/Light theme toggle for launcher
- Rate limiting for installer proxy

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

