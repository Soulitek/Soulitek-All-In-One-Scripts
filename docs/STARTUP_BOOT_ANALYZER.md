# Startup Programs & Boot Time Analyzer

## Overview

The **Startup Programs & Boot Time Analyzer** is a comprehensive diagnostic tool that scans all startup locations on your Windows system and analyzes boot performance to help identify optimization opportunities.

This read-only tool provides detailed insights and actionable recommendations without modifying your system.

## Features

### Comprehensive Startup Scanning
- **Startup Folders** - Checks both All Users and Current User startup folders
- **Task Scheduler** - Finds tasks that run at logon or startup
- **Auto-Start Services** - Lists third-party services with automatic startup

### Boot Performance Analysis
- **Event Log Integration** - Retrieves boot time data from Windows Event Logs
- **Historical Trend Tracking** - Maintains last 30 boot records
- **Performance Rating** - Categorizes boot speed (Excellent/Good/Moderate/Slow)
- **Trend Analysis** - Identifies if boot time is improving or degrading

### Performance Impact Rating
- **Known Programs Database** - Pre-configured ratings for 30+ common applications
- **Pattern Matching** - Intelligent heuristics to identify updaters and background apps
- **Automated Rating** - No manual input required, fully automated analysis

### Optimization Recommendations
- **High Impact Programs** - Identifies programs significantly slowing boot
- **Background Updaters** - Flags unnecessary update services
- **Multiple Cloud Storage** - Detects redundant cloud sync applications
- **Gaming Launchers** - Highlights gaming platforms that can be manually launched

### Professional HTML Reports
- **Modern Design** - Beautiful gradient headers and card layouts
- **Color-Coded Impact** - Visual badges for High/Medium/Low impact items
- **Complete Data** - All startup items organized by category
- **Detailed Recommendations** - Step-by-step disable instructions
- **Embedd

ed CSS** - No external dependencies, works offline

## Requirements

- **Operating System:** Windows 10 or Windows 11
- **PowerShell:** Version 5.1 or higher
- **Privileges:** Administrator rights required
- **Optional:** Boot Performance Event Log enabled for boot time tracking

## What This Tool Scans

✅ **Startup Folders**
  - All Users: `C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup`
  - Current User: `%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup`

✅ **Task Scheduler**
  - Tasks with AtLogon trigger
  - Tasks with AtStartup trigger

✅ **Windows Services**
  - Automatic startup services
  - Delayed auto-start services
  - Non-Microsoft services highlighted

❌ **Not Scanned** (by design for simplicity)
  - Registry Run/RunOnce keys

## Installation

The script is included in the SouliTEK All-In-One Scripts package.

No separate installation needed - simply run from the scripts directory.

## Usage

### Launch the Tool

```powershell
# From the scripts directory
.\startup_boot_analyzer.ps1

# Or from launcher
.\SouliTEK-Launcher.ps1
# Then select "Startup & Boot Time Analyzer"
```

### Main Menu Options

#### Option 1: Analyze All Startup Items (Full Scan)
Performs a comprehensive scan of all startup locations:
- Startup folders (All Users and Current User)
- Task Scheduler (logon/startup triggers)
- Auto-start services (non-Microsoft)

**Output:**
- Performance summary with boot statistics
- Categorized list of all startup items
- Impact ratings for each program
- Optimization potential assessment

**Tip:** Run this first to build your analysis data.
**Scan Time:** Approximately 15-30 seconds depending on system configuration

---

#### Option 2: View Boot Time History & Trends
Displays historical boot performance data:
- Last 30 boot records with dates and durations
- Statistical analysis (average, best, worst)
- Trend indicators (improving/degrading/stable)
- Warnings for sudden increases in boot time

**Data Source:** 
- Windows Event Log (Event ID 100)
- Custom tracking file maintained by the tool

**Enable Boot Performance Tracking:**
```powershell
wevtutil sl Microsoft-Windows-Diagnostics-Performance/Operational /e:true
```

---

#### Option 3: View Optimization Recommendations
Generates actionable recommendations based on analysis:
- **High Priority** - Programs with severe boot impact
- **Medium Priority** - Background updaters, multiple cloud apps
- **Low Priority** - Gaming launchers and optional services

**Each Recommendation Includes:**
- List of affected programs
- Explanation of impact
- Optimization guidance
- Step-by-step disable instructions

---

#### Option 4: Export Full Report to HTML
Creates a professional HTML report containing:
- Performance summary dashboard
- Complete startup item inventory
- Boot time trend statistics
- Optimization recommendations
- Color-coded impact ratings

**Output Location:** `Documents\StartupAnalysis_COMPUTERNAME_TIMESTAMP.html`

**Options After Export:**
- **[O]** Open in default browser
- **[C]** Copy file path to clipboard
- **[Enter]** Return to menu

---

#### Option 5: Exit
Closes the application.

---

## Understanding Performance Impact Ratings

### Impact Levels

| Level | Description | Typical Boot Delay | Examples |
|-------|-------------|-------------------|----------|
| **High** | Significant boot impact | > 5 seconds | Spotify, Steam, Adobe Creative Cloud |
| **Medium** | Noticeable delay | 2-5 seconds | OneDrive, Dropbox, Slack |
| **Low** | Minimal impact | < 2 seconds | Helper apps, system tray utilities |
| **Unknown** | Not yet rated | N/A | Custom or rare applications |

### Rating Sources

1. **Database** - Pre-configured ratings for 30+ common programs
2. **Pattern Match** - Heuristic analysis based on program name (updaters, helpers, agents)
3. **Not Rated** - No data available yet

## How to Disable Startup Items

### Method 1: Task Manager (Easiest)
1. Press `Ctrl + Shift + Esc` to open Task Manager
2. Click the **Startup** tab
3. Right-click the program
4. Select **Disable**

**Applies to:** Registry items, Startup folder items

---

### Method 2: Application Settings (Recommended)
1. Open the application
2. Go to **Settings** or **Preferences**
3. Look for options like:
   - "Start with Windows"
   - "Launch on startup"
   - "Auto-start"
4. Disable the option

**Applies to:** Most third-party applications

---

### Method 3: Task Scheduler (For Scheduled Tasks)
1. Press `Win + R`, type `taskschd.msc`, press Enter
2. Browse Task Scheduler Library
3. Find the startup task
4. Right-click and select **Disable**

**Applies to:** Programs using Task Scheduler triggers

---

### Method 4: Services (For Windows Services)
1. Press `Win + R`, type `services.msc`, press Enter
2. Find the service
3. Right-click and select **Properties**
4. Change **Startup type** to:
   - **Manual** (start on demand)
   - **Disabled** (never start)
5. Click **OK**

**Warning:** Disabling system services can cause issues. Only disable third-party services.

---

## Boot Time Optimization Tips

### Quick Wins (High Impact, Low Risk)
1. **Disable Gaming Launchers** (Steam, Epic, Origin)
   - Launch manually when gaming
   - Can save 10-15 seconds

2. **Remove Unnecessary Updaters** (Adobe ARM, Java Update)
   - Most apps can update when launched
   - Reduces background processes

3. **Limit Cloud Storage Apps** 
   - Choose one primary cloud service
   - Launch others manually when needed

### Moderate Changes
4. **Review Communication Apps** (Teams, Slack, Discord)
   - Keep only what you use immediately after boot
   - Launch others on demand

5. **Disable Trial Software**
   - Remove bloatware from new PCs
   - Often includes startup components

### Advanced Optimization
6. **Convert Services to Manual**
   - Some third-party services can be manual
   - Requires understanding of dependencies

7. **Clean Startup Folders**
   - Remove shortcuts you don't need
   - Check both All Users and Current User folders

### What NOT to Disable
❌ **Windows Defender** - Critical security  
❌ **Windows Update** - System maintenance  
❌ **System Services** - Core Windows functionality  
❌ **Driver Software** - Hardware support (e.g., graphics, audio)

---

## Interpreting Boot Performance

### Boot Time Benchmarks

| Duration | Rating | Status |
|----------|--------|--------|
| < 30 seconds | ✓ Excellent | Very fast, well optimized |
| 30-45 seconds | ✓ Good | Fast, typical for modern systems |
| 45-60 seconds | ⚠ Moderate | Could be improved |
| > 60 seconds | ✗ Slow | Needs optimization |

### Factors Affecting Boot Time
- Number of startup programs
- Hard drive type (SSD vs HDD)
- RAM capacity
- CPU speed
- Windows Fast Startup setting
- BIOS/UEFI boot settings
- Disk health and fragmentation

### SSD vs HDD
- **SSD:** Target < 30 seconds
- **HDD:** Target < 60 seconds (mechanical drives are slower)

---

## Troubleshooting

### Event Log Not Available

**Issue:** "Boot performance event log not available"

**Solution:**
```powershell
# Enable the event log (run as Administrator)
wevtutil sl Microsoft-Windows-Diagnostics-Performance/Operational /e:true
```

**Note:** Boot time tracking will start from the next boot.

---

### No Startup Items Found

**Issue:** Analysis shows very few items

**Possible Causes:**
1. Clean system (expected)
2. Running as non-admin (some items hidden)
3. Third-party security software blocking access

**Solution:** Ensure running as Administrator

---

### Task Scheduler Access Denied

**Issue:** "Failed to query Task Scheduler"

**Solution:** Run PowerShell as Administrator

---

### HTML Report Won't Open

**Issue:** Browser doesn't open or shows errors

**Solutions:**
1. Manually navigate to Documents folder
2. Right-click the HTML file
3. Select "Open with" > Choose browser
4. Check browser security settings

---

### Rating Not Saving

**Issue:** User ratings don't persist

**Possible Causes:**
1. Corrupted JSON file
2. Permission issues with AppData folder

**Solution:**
```powershell
# Delete corrupted ratings file
Remove-Item "$env:APPDATA\SouliTEK\StartupItemRatings.json" -Force

# Re-add ratings
```

---

## Data Storage

### Boot Time History
**Location:** `%APPDATA%\SouliTEK\BootTimeHistory.json`  
**Format:** JSON array of boot records  
**Retention:** Last 30 boots  
**Privacy:** Stored locally, never transmitted

### Clear Boot History
```powershell
Remove-Item "$env:APPDATA\SouliTEK\BootTimeHistory.json" -Force
```

---

## FAQ

### Q: Will this tool modify my startup items?
**A:** No, this is a read-only analysis tool. It only provides recommendations. You must manually disable items using the methods described above.

---

### Q: How often should I run this analysis?
**A:** 
- **Monthly:** For regular maintenance
- **After software installation:** To see what was added
- **When boot time increases:** To identify new culprits

---

### Q: Can I run this on a client's computer?
**A:** Yes, this tool is designed for IT professionals. The HTML report is perfect for sharing with clients to explain optimization recommendations.

---

### Q: What if I disable something important?
**A:** 
1. Most startup items can be safely disabled
2. If issues occur, re-enable the item using Task Manager
3. Create a System Restore Point before making changes
4. The tool flags system-critical items as "System" scope

---

### Q: Why is my boot time still slow after optimizations?
**A:** Boot time depends on many factors:
- **Hardware:** Upgrade to SSD for biggest improvement
- **RAM:** Low memory causes disk swapping
- **Disk health:** Failing drives slow everything
- **Windows updates:** Pending updates can delay boot
- **Malware:** Run a security scan

---

### Q: Can I export the list of startup items for documentation?
**A:** Yes, use Option 4 to generate an HTML report. You can then:
- Print to PDF
- Save as reference documentation
- Share with management or clients

---

### Q: What's the difference between impact levels?
**A:** 
- **High:** Delays boot by 5+ seconds, resource-intensive
- **Medium:** 2-5 second delay, moderate resources
- **Low:** < 2 second delay, minimal resources
- **Unknown:** Not yet rated or uncommon program

---

### Q: Does disabling startup items break the programs?
**A:** No, disabling startup only prevents automatic launch. You can still:
- Launch programs manually anytime
- Use them normally
- Re-enable startup if needed

---

## Best Practices

### For IT Professionals

1. **Document Before Changes**
   - Export HTML report before optimization
   - Keep records for client documentation
   - Note which items were disabled

2. **Explain to Users**
   - Show the HTML report
   - Explain impact ratings
   - Set expectations for improvements

3. **Test After Changes**
   - Reboot and verify startup
   - Ensure critical apps still work
   - Measure actual time savings

4. **Follow-Up**
   - Run analysis again after 1 week
   - Confirm optimizations held
   - Check for new startup additions

### For End Users

1. **Start Conservative**
   - Disable only High impact items first
   - Test for a few days
   - Gradually disable more if needed

2. **Keep a List**
   - Write down what you disable
   - Makes it easy to re-enable if issues
   - Track which changes helped most

3. **Regular Maintenance**
   - Run monthly analysis
   - Software updates often add startup items
   - Prevents gradual slowdown

---

## Known Limitations

1. **Read-Only Analysis**
   - Tool does not make changes automatically
   - User must manually disable items
   - By design for safety

2. **Event Log Dependency**
   - Boot time tracking requires Event Log enabled
   - May not work on all systems
   - Custom tracking fills in gaps

3. **Service Analysis**
   - Shows all auto-start services
   - Many are system-critical
   - Requires user judgment to disable

4. **Impact Rating Accuracy**
   - Based on known programs database (30+ apps)
   - Pattern matching for common types (updaters, helpers)
   - Custom/uncommon software may show as "Unknown"

---

## Technical Details

### Startup Locations Scanned

**File System:**
- `C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup`
- `%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup`

**Task Scheduler:**
- Triggers: `AtLogon`, `AtStartup`
- Status: Ready/Enabled only

**Services:**
- Startup Type: Automatic, Automatic (Delayed)
- Filtered: Non-Microsoft services highlighted

### Performance Data Sources

**Event Log:**
- Log: `Microsoft-Windows-Diagnostics-Performance/Operational`
- Event ID: 100 (Boot Performance Monitoring)
- Data: Boot duration in milliseconds

**Custom Tracking:**
- Last boot time from WMI
- Historical records in JSON
- Trend calculations

---

## Support

For assistance with the Startup & Boot Time Analyzer:

- **Documentation:** This file
- **Website:** [www.soulitek.co.il](https://www.soulitek.co.il)
- **Email:** letstalk@soulitek.co.il

---

## Changelog

### Version 1.1.0 (2025-11-08)
- Removed registry scanning for simplicity (focus on programs and services)
- Removed user rating system (fully automated analysis)
- Performance improvements (~15% faster scanning)
- Updated menu structure (5 options instead of 6)
- Streamlined user experience

### Version 1.0.0 (2025-11-08)
- Initial release
- Comprehensive startup scanning (Folders, Tasks, Services)
- Boot performance tracking with Event Log integration
- Performance impact rating system (Database + Pattern matching)
- Optimization recommendations engine
- Professional HTML report export
- Boot time history (30 records)
- Read-only analysis (safe, non-destructive)

---

## License

© 2025 SouliTEK - All Rights Reserved

This tool is part of the SouliTEK All-In-One Scripts package and is proprietary software.

---

<div align="center">

**Startup Programs & Boot Time Analyzer**  
*Professional Boot Performance Analysis*

Part of **SouliTEK All-In-One Scripts**  
[www.soulitek.co.il](https://www.soulitek.co.il)

</div>

