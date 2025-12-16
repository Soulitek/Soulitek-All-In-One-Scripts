# Workflow State

## Status: Completed

### Task: Fixed Missing SharePoint Site Inventory Script

**Completed:** Recreated the missing `sharepoint_site_inventory.ps1` script that was referenced in the launcher but missing from the scripts directory.

#### Issue
- Script `sharepoint_site_inventory.ps1` was missing from `scripts/` directory
- Launcher referenced the script at line 348
- Documentation existed in `docs/sharepoint_site_inventory.md`
- Warning: "Script not found: sharepoint_site_inventory.ps1"

#### Solution
- Created complete `scripts/sharepoint_site_inventory.ps1` script
- Followed same pattern as other M365 scripts (`m365_user_list.ps1`, `m365_exchange_online.ps1`)
- Implemented all features documented in the documentation:
  - Microsoft Graph connection with required permissions
  - SharePoint site retrieval
  - Site information collection (URL, name, template, type, storage, owners, activity)
  - Export to TXT, CSV, HTML, and JSON formats
  - Menu-driven interface
- Script is now functional and ready to use

---

## Status: In Progress

### Task: Unified Output Style Standardization

**In Progress:** Implementing unified visual output and text formatting across all PowerShell scripts in the repository.

#### Objective
Unify the visual output and text formatting across all scripts without changing script logic, flow, or behavior. Design and presentation only.

#### Changes Made:

1. **modules/SouliTEK-Common.ps1**
   - Added unified output functions:
     - `Write-Ui` - Main unified output function with format: `[DD-MM-YYYY HH:mm:ss] [LEVEL] Message`
     - `Write-Status` - Alias for Write-Ui
     - `Show-ScriptBanner` - Standardized script banner
     - `Show-Section` - Section header separator
     - `Show-Step` - Step progress indicator (STEP X/Y: Description)
     - `Show-Summary` - End summary with status, steps, warnings, errors
   - Message levels: INFO (Cyan), STEP (White), OK (Green), WARN (Yellow), ERROR (Red)

2. **STYLE_GUIDE.md**
   - Created comprehensive style guide documenting:
     - Global output standard format
     - Message levels and colors
     - Visual structure rules (banner, sections, steps, summary)
     - Text rules (sentence case, no emojis, short messages)
     - Replacement rules
     - Examples and function reference

3. **Scripts Updated:**
   - `scripts/1-click_pc_install.ps1` - Updated main execution, key functions, and output calls
   - `scripts/essential_tweaks.ps1` - Partially updated (in progress)

#### Remaining Work:

- Complete updates to `scripts/essential_tweaks.ps1`
- Update remaining 33 scripts to use unified output format:
  - Replace `Write-Host` calls with `Write-Ui`
  - Replace `Write-SouliTEKResult`, `Write-SouliTEKInfo`, `Write-SouliTEKSuccess`, `Write-SouliTEKWarning`, `Write-SouliTEKError` with `Write-Ui`
  - Add `Show-ScriptBanner` at script start
  - Add `Show-Section` for major sections
  - Add `Show-Step` for multi-step processes
  - Add `Show-Summary` at script end
  - Remove `Show-SouliTEKHeader` calls where appropriate

#### Standards Applied:

- Date/time format: `DD-MM-YYYY HH:mm:ss`
- Message format: `[DD-MM-YYYY HH:mm:ss] [LEVEL] Message`
- Banner format: `==================================================` with script name and purpose
- Section format: `----- SECTION NAME -----`
- Step format: `STEP X/Y: Description`
- Summary format: Always present with status, steps, warnings, errors

#### Notes:

- No script logic, flow, or behavior changes
- Only visual output and formatting changes
- Preserving original message meaning exactly
- Not removing existing output, only reformatting
