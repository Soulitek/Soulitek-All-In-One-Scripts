# ============================================================
# Win11Debloat Tool - Windows Debloating and Optimization
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
# This tool uses Win11Debloat by Raphire to remove bloatware,
# disable telemetry, and optimize Windows 10/11 systems.
# 
# Source: https://github.com/Raphire/Win11Debloat
# 
# Features: Bloatware Removal | Telemetry Disabling | System Optimization
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
# WARNING: This will make significant changes to your Windows
# installation including:
# - Removing pre-installed apps
# - Disabling telemetry and data collection
# - Modifying registry settings
# - Changing Windows features
# 
# ALWAYS create a system restore point before proceeding!
# 
# ============================================================

#Requires -Version 5.1

# Set window title
$Host.UI.RawUI.WindowTitle = "WIN11DEBLOAT TOOL"

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

# Win11Debloat script URL
$Win11DebloatURL = "https://debloat.raphi.re/"

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

function Show-Warning {
    Clear-Host
    Show-SouliTEKBanner
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Yellow
    Write-Host "  WARNING: IMPORTANT NOTICE"
    Write-Host "========================================" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "This tool will make SIGNIFICANT CHANGES to your" -ForegroundColor Red
    Write-Host "Windows installation, including:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  - Remove pre-installed bloatware apps" -ForegroundColor Gray
    Write-Host "  - Disable Windows telemetry" -ForegroundColor Gray
    Write-Host "  - Modify system registry settings" -ForegroundColor Gray
    Write-Host "  - Change Windows features and services" -ForegroundColor Gray
    Write-Host "  - Customize UI elements" -ForegroundColor Gray
    Write-Host ""
    Write-Host "STRONGLY RECOMMENDED:" -ForegroundColor Red
    Write-Host "  - Create a system restore point" -ForegroundColor Yellow
    Write-Host "  - Backup important data" -ForegroundColor Yellow
    Write-Host "  - Understand the changes being made" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "This tool works for both Windows 10 and Windows 11." -ForegroundColor Cyan
    Write-Host ""
    Write-Host "After running, you will be presented with an" -ForegroundColor Gray
    Write-Host "interactive menu to select which changes to apply." -ForegroundColor Gray
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

function Test-InternetConnection {
    <#
    .SYNOPSIS
        Tests if internet connection is available.
    
    .DESCRIPTION
        Attempts to reach a reliable endpoint to verify internet connectivity.
    
    .OUTPUTS
        [bool] True if internet is available, False otherwise.
    #>
    
    try {
        $null = Test-Connection -ComputerName "8.8.8.8" -Count 1 -ErrorAction Stop
        return $true
    }
    catch {
        try {
            $null = Test-Connection -ComputerName "1.1.1.1" -Count 1 -ErrorAction Stop
            return $true
        }
        catch {
            return $false
        }
    }
}

function Invoke-Win11Debloat {
    Clear-Host
    Show-SouliTEKBanner
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  WIN11DEBLOAT EXECUTION"
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    
    # Check internet connection
    Write-Host "[*] Checking internet connection..." -ForegroundColor Cyan
    if (-not (Test-InternetConnection)) {
        Write-Host "    [ERROR] No internet connection detected" -ForegroundColor Red
        Write-Host ""
        Write-Host "This tool requires an active internet connection" -ForegroundColor Yellow
        Write-Host "to download and run the Win11Debloat script." -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Please check your network connection and try again." -ForegroundColor Gray
        Write-Host ""
        return $false
    }
    Write-Host "    [OK] Internet connection verified" -ForegroundColor Green
    Write-Host ""
    
    # Display information
    Write-Host "[*] About Win11Debloat:" -ForegroundColor Cyan
    Write-Host "    Tool: Win11Debloat by Raphire" -ForegroundColor Gray
    Write-Host "    Source: https://github.com/Raphire/Win11Debloat" -ForegroundColor Gray
    Write-Host "    Download URL: $Win11DebloatURL" -ForegroundColor Gray
    Write-Host ""
    
    Write-Host "[*] Downloading and executing Win11Debloat..." -ForegroundColor Cyan
    Write-Host "    This will open an interactive menu." -ForegroundColor Yellow
    Write-Host "    Please follow the on-screen instructions." -ForegroundColor Yellow
    Write-Host ""
    
    try {
        # Download and execute the Win11Debloat script
        Write-Host "[*] Fetching script from remote server..." -ForegroundColor Cyan
        $scriptContent = Invoke-RestMethod -Uri $Win11DebloatURL -ErrorAction Stop
        
        Write-Host "    [OK] Script downloaded successfully" -ForegroundColor Green
        Write-Host ""
        
        Write-Host "[*] Launching Win11Debloat..." -ForegroundColor Cyan
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host ""
        
        # Execute the downloaded script
        & ([scriptblock]::Create($scriptContent))
        
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host "  WIN11DEBLOAT EXECUTION COMPLETED" -ForegroundColor Green
        Write-Host "========================================" -ForegroundColor Green
        Write-Host ""
        Write-Host "The Win11Debloat tool has finished." -ForegroundColor Green
        Write-Host ""
        Write-Host "IMPORTANT NOTES:" -ForegroundColor Yellow
        Write-Host "  - Some changes may require a system restart" -ForegroundColor Gray
        Write-Host "  - Review any warnings or messages displayed above" -ForegroundColor Gray
        Write-Host "  - If you encounter issues, you can restore from" -ForegroundColor Gray
        Write-Host "    your system restore point" -ForegroundColor Gray
        Write-Host ""
        
        return $true
    }
    catch {
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Red
        Write-Host "  ERROR: Failed to execute Win11Debloat" -ForegroundColor Red
        Write-Host "========================================" -ForegroundColor Red
        Write-Host ""
        Write-Host "Error details:" -ForegroundColor Yellow
        Write-Host "  $($_.Exception.Message)" -ForegroundColor Red
        Write-Host ""
        Write-Host "Possible causes:" -ForegroundColor Yellow
        Write-Host "  - Network connectivity issues" -ForegroundColor Gray
        Write-Host "  - Firewall or antivirus blocking the download" -ForegroundColor Gray
        Write-Host "  - PowerShell execution policy restrictions" -ForegroundColor Gray
        Write-Host "  - Remote server unavailable" -ForegroundColor Gray
        Write-Host ""
        Write-Host "Troubleshooting steps:" -ForegroundColor Cyan
        Write-Host "  1. Check your internet connection" -ForegroundColor Gray
        Write-Host "  2. Temporarily disable antivirus/firewall" -ForegroundColor Gray
        Write-Host "  3. Verify PowerShell execution policy:" -ForegroundColor Gray
        Write-Host "     Get-ExecutionPolicy" -ForegroundColor DarkGray
        Write-Host "  4. Try running directly from GitHub:" -ForegroundColor Gray
        Write-Host "     https://github.com/Raphire/Win11Debloat" -ForegroundColor DarkGray
        Write-Host ""
        
        return $false
    }
}

# ============================================================
# MAIN EXECUTION
# ============================================================

# Check for administrator privileges
if (-not (Test-SouliTEKAdministrator)) {
    Show-AdminError
}

# Show warning and get user confirmation
Show-Warning

# Execute Win11Debloat
$success = Invoke-Win11Debloat

# Final message
Write-Host ""
Write-Host "========================================"
if ($success) {
    Write-Host "Process completed successfully." -ForegroundColor Green
    Write-Host ""
    Write-Host "Thank you for using SouliTEK tools!" -ForegroundColor Cyan
} else {
    Write-Host "Process encountered errors." -ForegroundColor Red
    Write-Host ""
    Write-Host "Please review the error messages above." -ForegroundColor Yellow
}
Write-Host "========================================"
Write-Host ""

# Self-destruct: Remove script file after execution
Invoke-SouliTEKSelfDestruct -ScriptPath $PSCommandPath -Silent

Read-Host "Press Enter to exit"

