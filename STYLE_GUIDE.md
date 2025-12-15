# SouliTEK PowerShell Scripts - Output Style Guide

## Overview

This document defines the unified visual output and text formatting standard for all PowerShell scripts in the SouliTEK repository. All user-facing output must follow these guidelines to ensure consistency across all tools.

## Global Output Standard

### Message Format

All user-facing output must use the unified format:

```
[DD-MM-YYYY HH:mm:ss] [LEVEL] Message
```

**Example:**
```
[15-12-2025 21:43:08] [OK] Google Chrome installed successfully
```

### Message Levels & Colors

Use PowerShell `Write-Host -ForegroundColor` only. The following levels are available:

| Level | Purpose | Color |
|-------|---------|-------|
| INFO | General information | Cyan |
| STEP | Process step | White |
| OK | Successful action | Green |
| WARN | Non-blocking issue | Yellow |
| ERROR | Failure | Red |

### Output Function

All output must go through the unified function:

```powershell
Write-Ui -Message "Your message here" -Level "OK"
# or
Write-Status -Message "Your message here" -Level "INFO"
```

## Visual Structure Rules

### 1. Banner (Top of Script)

Every script must start with a standardized banner:

```
==================================================
 Script: <Script Name>
 Purpose: <Short description>
==================================================
```

**Implementation:**
```powershell
Show-ScriptBanner -ScriptName "1-Click PC Install" -Purpose "Complete PC setup automation"
```

### 2. Sections

Use section headers to separate major parts of the script:

```
----- SECTION NAME -----
```

**Implementation:**
```powershell
Show-Section "Installing Applications"
```

### 3. Steps

When showing progress through multiple steps:

```
STEP 1/5: Installing prerequisites
STEP 2/5: Configuring system settings
```

**Implementation:**
```powershell
Show-Step -StepNumber 1 -TotalSteps 5 -Description "Installing prerequisites"
```

### 4. End Summary (Always Present)

Every script must end with a summary:

```
================ SUMMARY =================
Status: Completed / Completed with warnings / Failed
Steps: 5
Warnings: X
Errors: Y
=========================================
```

**Implementation:**
```powershell
Show-Summary -Status "Completed" -Steps 5 -Warnings 1 -Errors 0
```

## Text Rules

1. **Sentence Case**: Use sentence case (not ALL CAPS) for messages
   - ✅ Good: "Google Chrome installed successfully"
   - ❌ Bad: "GOOGLE CHROME INSTALLED SUCCESSFULLY"

2. **No Emojis**: Do not use emojis unless already used — if used, apply consistently everywhere

3. **Short Messages**: Keep messages short, technical, and neutral

4. **No Marketing Language**: Avoid promotional or marketing language

## Replacement Rules

- Replace scattered `Write-Host`, `Write-Output`, `Write-Verbose` calls with `Write-Ui` or `Write-Status`
- Preserve original message meaning exactly
- Do not remove existing output — only reformat it
- Do NOT change script logic, flow, or behavior
- Do NOT add security, validation, or refactoring logic

## Examples

### Example 1: Simple Success Message

```powershell
Write-Ui -Message "Google Chrome installed successfully" -Level "OK"
```

**Output:**
```
[15-12-2025 21:43:08] [OK] Google Chrome installed successfully
```

### Example 2: Process Step

```powershell
Write-Ui -Message "Installing prerequisites" -Level "STEP"
```

**Output:**
```
[15-12-2025 21:43:08] [STEP] Installing prerequisites
```

### Example 3: Warning Message

```powershell
Write-Ui -Message "System Restore may not be enabled" -Level "WARN"
```

**Output:**
```
[15-12-2025 21:43:08] [WARN] System Restore may not be enabled
```

### Example 4: Error Message

```powershell
Write-Ui -Message "Failed to install application" -Level "ERROR"
```

**Output:**
```
[15-12-2025 21:43:08] [ERROR] Failed to install application
```

### Example 5: Complete Script Structure

```powershell
# Banner
Show-ScriptBanner -ScriptName "Example Script" -Purpose "Example purpose"

# Section
Show-Section "Configuration"

# Step
Show-Step -StepNumber 1 -TotalSteps 3 -Description "Configuring settings"

# Messages
Write-Ui -Message "Starting configuration" -Level "INFO"
Write-Ui -Message "Configuration completed" -Level "OK"

# Summary
Show-Summary -Status "Completed" -Steps 3 -Warnings 0 -Errors 0
```

## Date/Time Format

- **Format**: `DD-MM-YYYY HH:mm:ss`
- **Example**: `15-12-2025 21:43:08`

## Final Rule

If something is unclear, choose the most minimal visual change and document it in this guide.

## Functions Reference

All unified output functions are available in `modules/SouliTEK-Common.ps1`:

- `Write-Ui` - Main unified output function
- `Write-Status` - Alias for Write-Ui
- `Show-ScriptBanner` - Display script banner
- `Show-Section` - Display section header
- `Show-Step` - Display step information
- `Show-Summary` - Display end summary

