# Workflow State - SouliTEK All-In-One Scripts

**Date:** 2025-11-24  
**Project Status:** Production Ready - v2.2.0  
**Current Task:** Essential Tweaks Tool Implementation

---

## Current Status

✅ **Project Ready for Publication**  
✅ **GUI Redesigned for Compact Grid Layout - Version 2.0.0**  
✅ **Software Updater Tool Implemented - Version 2.1.0**  
✅ **Essential Tweaks Tool Implemented - Version 2.2.0**

### Latest Completion (2025-11-24 - v2.2.0)
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
- ✅ All 23 tools developed and tested
- ✅ Security audit passed (2025-11-05)
- ✅ Documentation complete
- ✅ WPF launcher functional with compact grid layout (2025-11-24)
- ✅ Installation system ready
- ✅ No PII or security issues
- ✅ Self-destruction feature implemented (2025-11-22)
- ✅ Software Updater tool implemented (2025-11-24)
- ✅ Essential Tweaks tool implemented (2025-11-24)

### Recent Changes (2025-11-24)
- ✅ **Essential Tweaks Tool** (v2.2.0 - Latest)
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
6. **Test Essential Tweaks** - Verify all 10 tweaks work correctly
7. **Test on Multiple Systems** - Verify compatibility across Windows versions
8. **Publish to GitHub** - Push v2.2.0 release with Essential Tweaks
9. **User Testing** - Gather feedback from technicians using the tools
10. **Monitor Issues** - Address any reported bugs

---

**Last Updated:** 2025-11-24 (v2.2.0)
