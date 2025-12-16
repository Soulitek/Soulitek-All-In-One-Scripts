# ============================================================
# McAfee Removal Tool - MCPR Integration
# ============================================================
# 
# Coded by: Soulitek.co.il
# IT Solutions for your business
# 
# (C) 2025 Soulitek - All Rights Reserved
# Website: www.soulitek.co.il
# 
# Professional IT Solutions:
# - Computer Repair & Maintenance
# - Network Setup & Support
# - Software Solutions
# - Business IT Consulting
# 
# This tool uses McAfee Consumer Product Removal (MCPR) tool
# to completely remove McAfee products from the system.
# 
# Features: Complete McAfee Removal | Safe Cleanup | Logging
# 
# ============================================================
# 
# IMPORTANT DISCLAIMER:
# This tool is provided "AS IS" without warranty of any kind.
# Use of this tool is at your own risk. The user is solely
# responsible for any outcomes, damages, or issues that may
# arise from using this script. By running this tool, you
# acknowledge and accept full responsibility for its use.
# 
# WARNING: This will completely remove all McAfee products
# from your system. Make sure you have a backup and understand
# the consequences before proceeding.
# 
# ============================================================

#Requires -Version 5.1

# Set window title
$Host.UI.RawUI.WindowTitle = "MCAFEE REMOVAL TOOL"

# Import SouliTEK Common Functions
$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$CommonPath = Join-Path (Split-Path -Parent $ScriptRoot) "modules\SouliTEK-Common.ps1"
if (Test-Path $CommonPath) {
    . $CommonPath
} else {
    Write-Warning "SouliTEK Common Functions not found at: $CommonPath"
    Write-Warning "Some functions may not work properly."
}

# ============================================================
# CONFIGURATION
# ============================================================

# Path to MCPR.exe (relative to project root)
$ProjectRoot = Split-Path -Parent $ScriptRoot
$MCPRPath = Join-Path $ProjectRoot "tools\MCPR.exe"

# ============================================================
# FUNCTIONS
# ============================================================

function Show-AdminError {
    $Host.UI.RawUI.BackgroundColor = "Black"
    $Host.UI.RawUI.ForegroundColor = "Red"
    Clear-Host
    Write-Host ""
    Write-Host "========================================"
    Write-Host "  ERROR: Administrator Required"
    Write-Host "========================================"
    Write-Host ""
    Write-Host "This script must run as Administrator."
    Write-Host ""
    Write-Host "HOW TO FIX:"
    Write-Host "1. Right-click this file"
    Write-Host "2. Select 'Run with PowerShell as administrator'"
    Write-Host "3. Click 'Yes' on the prompt"
    Write-Host ""
    Write-Host "========================================"
    Read-Host "Press Enter to exit"
    exit 1
}

function Test-MCPRToolExists {
    if (Test-Path $MCPRPath) {
        return $true
    } else {
        return $false
    }
}

function Show-MCPRNotFound {
    Clear-Host
    Show-SouliTEKBanner
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Red
    Write-Host "  ERROR: MCPR Tool Not Found"
    Write-Host "========================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "The MCPR.exe file was not found at:" -ForegroundColor Yellow
    Write-Host "  $MCPRPath" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Please ensure:" -ForegroundColor Yellow
    Write-Host "  1. MCPR.exe is placed in the 'tools' folder"
    Write-Host "  2. The file is named exactly 'MCPR.exe'"
    Write-Host "  3. The project structure is intact"
    Write-Host ""
    Write-Host "Expected structure:" -ForegroundColor Cyan
    Write-Host "  Soulitek-AIO/" -ForegroundColor Gray
    Write-Host "    tools/" -ForegroundColor Gray
    Write-Host "      MCPR.exe" -ForegroundColor Gray
    Write-Host "    scripts/" -ForegroundColor Gray
    Write-Host "      mcafee_removal_tool.ps1" -ForegroundColor Gray
    Write-Host ""
    Write-Host "========================================"
    Read-Host "Press Enter to exit"
    exit 1
}

function Show-Warning {
    Clear-Host
    Show-SouliTEKBanner
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Yellow
    Write-Host "  WARNING: IMPORTANT NOTICE"
    Write-Host "========================================" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "This tool will COMPLETELY REMOVE all McAfee" -ForegroundColor Red
    Write-Host "products from your system, including:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  - McAfee Antivirus" -ForegroundColor Gray
    Write-Host "  - McAfee Total Protection" -ForegroundColor Gray
    Write-Host "  - McAfee LiveSafe" -ForegroundColor Gray
    Write-Host "  - All McAfee services and components" -ForegroundColor Gray
    Write-Host ""
    Write-Host "This action CANNOT be undone easily." -ForegroundColor Red
    Write-Host ""
    Write-Host "Before proceeding, ensure:" -ForegroundColor Yellow
    Write-Host "  - You have a system backup" -ForegroundColor Gray
    Write-Host "  - You understand the consequences" -ForegroundColor Gray
    Write-Host "  - You have administrator privileges" -ForegroundColor Gray
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Press 'Y' to continue or any other key to cancel..." -ForegroundColor Cyan
    $response = Read-Host
    if ($response -ne 'Y' -and $response -ne 'y') {
        Write-Host ""
        Write-Host "Operation cancelled by user." -ForegroundColor Yellow
        Start-Sleep -Seconds 2
        exit 0
    }
}

function Invoke-McAfeeRemoval {
    Clear-Host
    Show-SouliTEKBanner
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  MCAFEE REMOVAL PROCESS"
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "[*] Checking MCPR tool..." -ForegroundColor Cyan
    if (-not (Test-MCPRToolExists)) {
        Show-MCPRNotFound
        return $false
    }
    Write-Host "    [OK] MCPR.exe found" -ForegroundColor Green
    Write-Host ""
    
    Write-Host "[*] Preparing to run MCPR..." -ForegroundColor Cyan
    Write-Host "    Tool location: $MCPRPath" -ForegroundColor Gray
    Write-Host ""
    
    Write-Host "[*] Launching McAfee Consumer Product Removal tool..." -ForegroundColor Cyan
    Write-Host "    This may take several minutes. Please wait..." -ForegroundColor Yellow
    Write-Host ""
    
    try {
        # Run MCPR.exe and wait for it to complete
        $process = Start-Process -FilePath $MCPRPath -Wait -NoNewWindow -PassThru -ErrorAction Stop
        
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Cyan
        if ($process.ExitCode -eq 0) {
            Write-Host "  REMOVAL COMPLETED SUCCESSFULLY" -ForegroundColor Green
            Write-Host "========================================" -ForegroundColor Green
            Write-Host ""
            Write-Host "McAfee products have been removed from your system." -ForegroundColor Green
            Write-Host ""
            Write-Host "IMPORTANT: You may need to restart your computer" -ForegroundColor Yellow
            Write-Host "for all changes to take effect." -ForegroundColor Yellow
            Write-Host ""
            return $true
        } else {
            Write-Host "  REMOVAL COMPLETED WITH EXIT CODE: $($process.ExitCode)" -ForegroundColor Yellow
            Write-Host "========================================" -ForegroundColor Yellow
            Write-Host ""
            Write-Host "The removal process has finished." -ForegroundColor Yellow
            Write-Host "Please check the MCPR output for details." -ForegroundColor Yellow
            Write-Host ""
            Write-Host "Exit code: $($process.ExitCode)" -ForegroundColor Gray
            Write-Host ""
            return $true
        }
    }
    catch {
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Red
        Write-Host "  ERROR: Failed to run MCPR" -ForegroundColor Red
        Write-Host "========================================" -ForegroundColor Red
        Write-Host ""
        Write-Host "Error details:" -ForegroundColor Yellow
        Write-Host "  $($_.Exception.Message)" -ForegroundColor Red
        Write-Host ""
        Write-Host "Please ensure:" -ForegroundColor Yellow
        Write-Host "  - You have administrator privileges" -ForegroundColor Gray
        Write-Host "  - MCPR.exe is not corrupted" -ForegroundColor Gray
        Write-Host "  - No antivirus is blocking the execution" -ForegroundColor Gray
        Write-Host ""
        return $false
    }
}

# ============================================================
# MAIN EXECUTION
# ============================================================

# Show banner
Clear-Host
Show-ScriptBanner -ScriptName "McAfee Removal Tool" -Purpose "Completely remove all McAfee products from the system"

# Check for administrator privileges
if (-not (Test-SouliTEKAdministrator)) {
    Show-AdminError
}

# Check if MCPR tool exists
if (-not (Test-MCPRToolExists)) {
    Show-MCPRNotFound
}

# Show warning and get user confirmation
Show-Warning

# Perform the removal
$success = Invoke-McAfeeRemoval

# Final message
Write-Host ""
Write-Host "========================================"
if ($success) {
    Write-Host "Process completed." -ForegroundColor Green
} else {
    Write-Host "Process encountered errors." -ForegroundColor Red
}
Write-Host "========================================"
Write-Host ""

Read-Host "Press Enter to exit"

