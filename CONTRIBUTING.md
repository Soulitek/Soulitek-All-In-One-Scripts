# Contributing to SouliTEK All-In-One Scripts

Thank you for your interest in contributing to SouliTEK All-In-One Scripts! We welcome contributions from the community.

---

## 🎯 How to Contribute

There are several ways you can contribute to this project:

### Report Bugs
- Use the GitHub issue tracker
- Describe the bug clearly
- Include steps to reproduce
- Specify your environment (Windows version, PowerShell version)
- Add screenshots if applicable

### Suggest Features
- Open a feature request issue
- Describe the feature and its benefits
- Explain which tool it would enhance or if it's a new tool
- Discuss implementation approaches

### Submit Code
- Fork the repository
- Create a feature branch
- Make your changes following our code style
- Test thoroughly
- Submit a pull request with clear description

---

## 📝 Code Style Guide

**Important:** All scripts must follow the unified output standard defined in [STYLE_GUIDE.md](STYLE_GUIDE.md). This ensures consistent visual output across all tools.

### PowerShell Standards

**Function Naming:**
- Use PascalCase for function names: `Get-WiFiPassword`, `Show-Header`
- Use verb-noun format following PowerShell conventions
- Prefix custom functions with `SouliTEK` when in common module

**Variables:**
- Use PascalCase for script-level variables: `$Script:CurrentVersion`
- Use camelCase for local variables: `$profileName`, `$fileCount`
- Use descriptive names, avoid single letters except in loops

**Indentation:**
- Use 4 spaces for indentation (no tabs)
- Indent consistently within blocks
- Align braces with control structures

**Comments:**
- Include comment-based help for all functions
- Use `#` for inline comments
- Document complex logic
- Explain the "why" not just the "what"

### Required Elements

**All Scripts Must Include:**
1. **Script Banner** - Use `Show-ScriptBanner` from common module (unified output standard)
2. **Disclaimer** - Include standard disclaimer at top of script
3. **Error Handling** - Comprehensive try-catch blocks
4. **Administrator Checks** - When system modifications are made
5. **Common Module** - Import and use `SouliTEK-Common.ps1` functions
6. **Comment-Based Help** - Full `.SYNOPSIS`, `.DESCRIPTION`, `.EXAMPLE`
7. **Unified Output** - Use `Write-Ui` for all user-facing messages
8. **End Summary** - Use `Show-Summary` at script completion

**Example Script Structure:**
```powershell
# ============================================================
# Script Name - by SouliTEK
# ============================================================
# 
# Description of what the script does
# 
# (C) 2025 SouliTEK - All Rights Reserved
# Website: www.soulitek.co.il
# ============================================================

#Requires -Version 5.1

# Import SouliTEK Common Functions
$CommonPath = Join-Path (Split-Path -Parent $PSScriptRoot) "modules\SouliTEK-Common.ps1"
if (Test-Path $CommonPath) {
    . $CommonPath
}

# Display script banner
Show-ScriptBanner -ScriptName "Example Script" -Purpose "Example purpose"

# Your code here using unified output functions
Write-Ui -Message "Starting process" -Level "INFO"
Show-Section "Configuration"
Show-Step -StepNumber 1 -TotalSteps 3 -Description "Configuring settings"

# End with summary
Show-Summary -Status "Completed" -Steps 3 -Warnings 0 -Errors 0
```

### Unified Output Standard

All user-facing output must follow the unified format: `[DD-MM-YYYY HH:mm:ss] [LEVEL] Message`

**Output Functions (from common module):**
- `Write-Ui` or `Write-Status` - Main unified output function with levels: INFO, STEP, OK, WARN, ERROR
- `Show-ScriptBanner` - Display standardized script banner
- `Show-Section` - Display section header separator
- `Show-Step` - Display step progress (STEP X/Y: Description)
- `Show-Summary` - Display end summary with status, steps, warnings, errors

**Message Levels:**
- `INFO` (Cyan) - General information
- `STEP` (White) - Process step
- `OK` (Green) - Successful action
- `WARN` (Yellow) - Non-blocking issue
- `ERROR` (Red) - Failure

See [STYLE_GUIDE.md](STYLE_GUIDE.md) for complete details and examples.

---

## 🔄 Pull Request Process

### Before Submitting

1. **Test Your Changes**
   - Test on Windows 10 and Windows 11
   - Test with PowerShell 5.1 and PowerShell 7.x
   - Test both as administrator and regular user
   - Verify all export formats work (CSV, HTML, JSON, TXT)

2. **Update Documentation**
   - Update relevant documentation in `docs/` folder
   - Add examples if introducing new features
   - Update README.md if tool list changes
   - Add entry to CHANGELOG.md

3. **Check Code Quality**
   - Run PSScriptAnalyzer if available
   - Fix any linting errors
   - Ensure consistent formatting
   - Remove debug statements
   - Verify unified output standard compliance (see STYLE_GUIDE.md)
   - Use `Write-Ui` instead of `Write-Host` for all user-facing messages

### Submitting Pull Request

1. **Fork the Repository**
   ```bash
   git clone https://github.com/Soulitek/Soulitek-All-In-One-Scripts.git
   cd Soulitek-All-In-One-Scripts
   ```

2. **Create Feature Branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Make Your Changes**
   - Follow code style guidelines
   - Add tests if applicable
   - Update documentation

4. **Commit Your Changes**
   ```bash
   git add .
   git commit -m "Add feature: description of your changes"
   ```

5. **Push to Your Fork**
   ```bash
   git push origin feature/your-feature-name
   ```

6. **Open Pull Request**
   - Go to GitHub and open a pull request
   - Provide clear title and description
   - Reference any related issues
   - Wait for review and address feedback

### Pull Request Guidelines

**Good PR Description Includes:**
- What changes were made
- Why the changes are needed
- How to test the changes
- Screenshots (if UI changes)
- Related issue numbers

**Example:**
```
## Description
Added WiFi signal strength display to WiFi Password Viewer

## Motivation
Users requested ability to see signal strength when viewing networks

## Changes Made
- Added signal strength detection using netsh
- Updated display to show signal bars
- Added signal strength to CSV export

## Testing
- Tested on Windows 10 (21H2) and Windows 11
- Tested with multiple WiFi networks
- Verified CSV export includes new field

## Related Issues
Closes #123
```

---

## ✅ Testing Requirements

### Minimum Testing Standards

**All contributions must be tested on:**
- ✅ Windows 10 (minimum: 21H2)
- ✅ Windows 11 (latest version)
- ✅ PowerShell 5.1
- ✅ PowerShell 7.x (latest)

**Test Scenarios:**
- ✅ Run as Administrator
- ✅ Run as regular user
- ✅ Test all menu options
- ✅ Test error handling (invalid input)
- ✅ Test export functionality
- ✅ Verify output accuracy

**For System-Modifying Tools:**
- ✅ Test on non-production system
- ✅ Create system restore point before testing
- ✅ Verify changes are reversible
- ✅ Test rollback procedures

---

## 🎨 Branding Requirements

### SouliTEK Identity

**All contributions must maintain:**
- ✅ SouliTEK branding and banner
- ✅ Copyright notice: © 2025 SouliTEK
- ✅ Contact information: www.soulitek.co.il
- ✅ Consistent visual style in GUI elements

**Use Common Module Functions:**
- `Show-ScriptBanner` - Display standardized script banner (unified output)
- `Write-Ui` or `Write-Status` - Unified output with message levels (INFO, STEP, OK, WARN, ERROR)
- `Show-Section` - Section header separator
- `Show-Step` - Step progress indicator
- `Show-Summary` - End summary display
- `Test-SouliTEKAdministrator` - Check admin privileges
- `Show-SouliTEKBanner` - Legacy branding banner (use `Show-ScriptBanner` for new scripts)

**Color Scheme (for GUI):**
- Primary: #6366f1 (Indigo)
- Success: #10b981 (Green)
- Warning: #f59e0b (Amber)
- Error: #ef4444 (Red)
- Info: #3b82f6 (Blue)

---

## 📋 Adding a New Tool

### Checklist for New Tools

1. **Create Script File**
   - Place in `scripts/` directory
   - Follow naming convention: `tool_name.ps1` (lowercase with underscores)
   - Include all required elements (banner, disclaimer, error handling)
   - Follow unified output standard (see STYLE_GUIDE.md)
   - Use `Show-ScriptBanner`, `Write-Ui`, `Show-Section`, `Show-Step`, and `Show-Summary`

2. **Add to Launcher**
   - Edit `launcher/SouliTEK-Launcher-WPF.ps1`
   - Add tool definition to `$Script:Tools` array (around line 95)
   - Include: Name, Icon, Description, Script filename, Category, Tags, Color

3. **Create Documentation**
   - Create `docs/TOOL_NAME.md`
   - Include: Overview, Features, Usage Examples, Parameters, Output Formats
   - Add troubleshooting section

4. **Update Main README**
   - Add tool to tools list
   - Update tool count
   - Verify category counts are accurate

5. **Test Integration**
   - Verify tool launches from GUI
   - Test search finds the tool
   - Verify category filtering works
   - Check icon displays correctly

---

## 🤝 Code of Conduct

### Our Standards

**We are committed to providing a welcoming and inclusive environment.**

**Positive behaviors include:**
- ✅ Using welcoming and inclusive language
- ✅ Being respectful of differing viewpoints
- ✅ Gracefully accepting constructive criticism
- ✅ Focusing on what is best for the community
- ✅ Showing empathy towards others

**Unacceptable behaviors include:**
- ❌ Trolling, insulting, or derogatory comments
- ❌ Personal or political attacks
- ❌ Public or private harassment
- ❌ Publishing others' private information
- ❌ Other conduct which could reasonably be considered inappropriate

### Enforcement

Instances of unacceptable behavior may be reported to: letstalk@soulitek.co.il

All complaints will be reviewed and investigated promptly and fairly.

---

## 📖 Additional Resources

### Documentation
- **README.md** - Project overview and quick start
- **STYLE_GUIDE.md** - Unified output standard and formatting guidelines
- **docs/** - Individual tool documentation
- **LICENSE** - License terms and conditions
- **CHANGELOG.md** - Version history and changes

### Getting Help
- **GitHub Issues** - Ask questions or report problems
- **Email** - letstalk@soulitek.co.il
- **Website** - www.soulitek.co.il

### Code Examples
Look at existing scripts for reference:
- `scripts/wifi_password_viewer.ps1` - Good example of user interaction
- `scripts/battery_report_generator.ps1` - Good example of reporting
- `scripts/network_test_tool.ps1` - Good example of diagnostics
- `modules/SouliTEK-Common.ps1` - Shared functions reference

---

## 🏆 Recognition

Contributors will be recognized in:
- Project README.md (Contributors section)
- Release notes for their contributions
- Git commit history

Significant contributions may be featured on www.soulitek.co.il

---

## ❓ Questions?

**Not sure about something?**
- Open a discussion issue on GitHub
- Email us: letstalk@soulitek.co.il
- Check existing issues for similar questions

**Want to contribute but don't know where to start?**
- Look for issues labeled "good first issue"
- Check the TODO.md file for planned features
- Ask us - we're happy to suggest tasks!

---

## 📜 License

By contributing to SouliTEK All-In-One Scripts, you agree that your contributions will be licensed under the same license as the project (see LICENSE file).

---

**Thank you for contributing to SouliTEK All-In-One Scripts!**

Your contributions help IT professionals worldwide. We appreciate your time and effort in making this project better.

---

*© 2025 SouliTEK - Professional IT Solutions*  
*Made with ❤️ in Israel*

