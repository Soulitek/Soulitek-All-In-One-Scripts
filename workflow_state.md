# Workflow State

## Status: Completed

### Task: Move Software Category Scripts to Setup Category

**Completed:** All scripts from Software category have been moved to Setup category, and the Software category has been removed.

#### Changes Made:

1. **README.md**
   - Moved 4 scripts from Software category to Setup category:
     - Softwares Installer
     - Software Updater
     - Win11Debloat
     - McAfee Removal Tool
   - Removed the Software category section

2. **launcher/SouliTEK-Launcher-WPF.ps1**
   - Changed Category from "Software" to "Setup" for 3 scripts:
     - Softwares Installer (line 271)
     - Win11Debloat (line 343)
     - Software Updater (line 352)
   - Removed `$Script:BtnCatSoftware` variable reference
   - Removed Software button click handler
   - Removed "Software" from categories hashtable in Set-CategoryActive function
   - Updated help text to reflect Software category removal

3. **launcher/MainWindow.xaml**
   - Removed Software category button (`BtnCatSoftware`) from the UI

#### Result:
- All Software category scripts are now in Setup category
- Software category has been completely removed from the launcher
- No linting errors detected
