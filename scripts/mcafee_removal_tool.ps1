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
    Write-Ui -Message "The MCPR.exe file was not found at:" -Level "WARN"
    Write-Ui -Message "  $MCPRPath" -Level "INFO"
    Write-Host ""
    Write-Ui -Message "Please ensure:" -Level "WARN"
    Write-Host "  1. MCPR.exe is placed in the 'tools' folder"
    Write-Host "  2. The file is named exactly 'MCPR.exe'"
    Write-Host "  3. The project structure is intact"
    Write-Host ""
    Write-Ui -Message "Expected structure:" -Level "INFO"
    Write-Ui -Message "  Soulitek-AIO/" -Level "INFO"
    Write-Ui -Message "    tools/" -Level "INFO"
    Write-Ui -Message "      MCPR.exe" -Level "INFO"
    Write-Ui -Message "    scripts/" -Level "INFO"
    Write-Ui -Message "      mcafee_removal_tool.ps1" -Level "INFO"
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
    Write-Ui -Message "This tool will COMPLETELY REMOVE all McAfee" -Level "ERROR"
    Write-Ui -Message "products from your system, including:" -Level "WARN"
    Write-Host ""
    Write-Ui -Message "  - McAfee Antivirus" -Level "INFO"
    Write-Ui -Message "  - McAfee Total Protection" -Level "INFO"
    Write-Ui -Message "  - McAfee LiveSafe" -Level "INFO"
    Write-Ui -Message "  - All McAfee services and components" -Level "INFO"
    Write-Host ""
    Write-Ui -Message "This action CANNOT be undone easily." -Level "ERROR"
    Write-Host ""
    Write-Ui -Message "Before proceeding, ensure:" -Level "WARN"
    Write-Ui -Message "  - You have a system backup" -Level "INFO"
    Write-Ui -Message "  - You understand the consequences" -Level "INFO"
    Write-Ui -Message "  - You have administrator privileges" -Level "INFO"
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Yellow
    Write-Host ""
    Write-Ui -Message "Press 'Y' to continue or any other key to cancel..." -Level "INFO"
    $response = Read-Host
    if ($response -ne 'Y' -and $response -ne 'y') {
        Write-Host ""
        Write-Ui -Message "Operation cancelled by user." -Level "WARN"
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
    
    Write-Ui -Message "[*] Checking MCPR tool..." -Level "INFO"
    if (-not (Test-MCPRToolExists)) {
        Show-MCPRNotFound
        return $false
    }
    Write-Ui -Message "    [OK] MCPR.exe found" -Level "OK"
    Write-Host ""
    
    Write-Ui -Message "[*] Preparing to run MCPR..." -Level "INFO"
    Write-Ui -Message "    Tool location: $MCPRPath" -Level "INFO"
    Write-Host ""
    
    Write-Ui -Message "[*] Launching McAfee Consumer Product Removal tool..." -Level "INFO"
    Write-Ui -Message "    This may take several minutes. Please wait..." -Level "WARN"
    Write-Host ""
    
    try {
        # Run MCPR.exe and wait for it to complete
        $process = Start-Process -FilePath $MCPRPath -Wait -NoNewWindow -PassThru -ErrorAction Stop
        
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Cyan
        if ($process.ExitCode -eq 0) {
            Write-Ui -Message "  REMOVAL COMPLETED SUCCESSFULLY" -Level "OK"
            Write-Host "========================================" -ForegroundColor Green
            Write-Host ""
            Write-Ui -Message "McAfee products have been removed from your system." -Level "OK"
            Write-Host ""
            Write-Ui -Message "IMPORTANT: You may need to restart your computer" -Level "WARN"
            Write-Ui -Message "for all changes to take effect." -Level "WARN"
            Write-Host ""
            return $true
        } else {
            Write-Ui -Message "  REMOVAL COMPLETED WITH EXIT CODE: $($process.ExitCode)" -Level "WARN"
            Write-Host "========================================" -ForegroundColor Yellow
            Write-Host ""
            Write-Ui -Message "The removal process has finished." -Level "WARN"
            Write-Ui -Message "Please check the MCPR output for details." -Level "WARN"
            Write-Host ""
            Write-Ui -Message "Exit code: $($process.ExitCode)" -Level "INFO"
            Write-Host ""
            return $true
        }
    }
    catch {
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Red
        Write-Ui -Message "  ERROR: Failed to run MCPR" -Level "ERROR"
        Write-Host "========================================" -ForegroundColor Red
        Write-Host ""
        Write-Ui -Message "Error details:" -Level "WARN"
        Write-Ui -Message "  $($_.Exception.Message)" -Level "ERROR"
        Write-Host ""
        Write-Ui -Message "Please ensure:" -Level "WARN"
        Write-Ui -Message "  - You have administrator privileges" -Level "INFO"
        Write-Ui -Message "  - MCPR.exe is not corrupted" -Level "INFO"
        Write-Ui -Message "  - No antivirus is blocking the execution" -Level "INFO"
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
    Write-Ui -Message "Process completed." -Level "OK"
} else {
    Write-Ui -Message "Process encountered errors." -Level "ERROR"
}
Write-Host "========================================"
Write-Host ""

Read-Host "Press Enter to exit"

