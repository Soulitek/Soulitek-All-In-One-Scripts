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
    Write-Ui -Message "This tool will make SIGNIFICANT CHANGES to your" -Level "ERROR"
    Write-Ui -Message "Windows installation, including:" -Level "WARN"
    Write-Host ""
    Write-Ui -Message "  - Remove pre-installed bloatware apps" -Level "INFO"
    Write-Ui -Message "  - Disable Windows telemetry" -Level "INFO"
    Write-Ui -Message "  - Modify system registry settings" -Level "INFO"
    Write-Ui -Message "  - Change Windows features and services" -Level "INFO"
    Write-Ui -Message "  - Customize UI elements" -Level "INFO"
    Write-Host ""
    Write-Ui -Message "STRONGLY RECOMMENDED:" -Level "ERROR"
    Write-Ui -Message "  - Create a system restore point" -Level "WARN"
    Write-Ui -Message "  - Backup important data" -Level "WARN"
    Write-Ui -Message "  - Understand the changes being made" -Level "WARN"
    Write-Host ""
    Write-Ui -Message "This tool works for both Windows 10 and Windows 11." -Level "INFO"
    Write-Host ""
    Write-Ui -Message "After running, you will be presented with an" -Level "INFO"
    Write-Ui -Message "interactive menu to select which changes to apply." -Level "INFO"
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
    Write-Ui -Message "[*] Checking internet connection..." -Level "INFO"
    if (-not (Test-InternetConnection)) {
        Write-Ui -Message "    [ERROR] No internet connection detected" -Level "ERROR"
        Write-Host ""
        Write-Ui -Message "This tool requires an active internet connection" -Level "WARN"
        Write-Ui -Message "to download and run the Win11Debloat script." -Level "WARN"
        Write-Host ""
        Write-Ui -Message "Please check your network connection and try again." -Level "INFO"
        Write-Host ""
        return $false
    }
    Write-Ui -Message "    [OK] Internet connection verified" -Level "OK"
    Write-Host ""
    
    # Display information
    Write-Ui -Message "[*] About Win11Debloat:" -Level "INFO"
    Write-Ui -Message "    Tool: Win11Debloat by Raphire" -Level "INFO"
    Write-Host "    Source: https://github.com/Raphire/Win11Debloat" -ForegroundColor Gray
    Write-Ui -Message "    Download URL: $Win11DebloatURL" -Level "INFO"
    Write-Host ""
    
    Write-Ui -Message "[*] Downloading and executing Win11Debloat..." -Level "INFO"
    Write-Ui -Message "    This will open an interactive menu." -Level "WARN"
    Write-Ui -Message "    Please follow the on-screen instructions." -Level "WARN"
    Write-Host ""
    
    try {
        # Download and execute the Win11Debloat script
        Write-Ui -Message "[*] Fetching script from remote server..." -Level "INFO"
        $scriptContent = Invoke-RestMethod -Uri $Win11DebloatURL -ErrorAction Stop
        
        Write-Ui -Message "    [OK] Script downloaded successfully" -Level "OK"
        Write-Host ""
        
        Write-Ui -Message "[*] Launching Win11Debloat..." -Level "INFO"
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host ""
        
        # Execute the downloaded script
        & ([scriptblock]::Create($scriptContent))
        
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Ui -Message "  WIN11DEBLOAT EXECUTION COMPLETED" -Level "OK"
        Write-Host "========================================" -ForegroundColor Green
        Write-Host ""
        Write-Ui -Message "The Win11Debloat tool has finished." -Level "OK"
        Write-Host ""
        Write-Ui -Message "IMPORTANT NOTES:" -Level "WARN"
        Write-Ui -Message "  - Some changes may require a system restart" -Level "INFO"
        Write-Ui -Message "  - Review any warnings or messages displayed above" -Level "INFO"
        Write-Ui -Message "  - If you encounter issues, you can restore from" -Level "INFO"
        Write-Ui -Message "    your system restore point" -Level "INFO"
        Write-Host ""
        
        return $true
    }
    catch {
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Red
        Write-Ui -Message "  ERROR: Failed to execute Win11Debloat" -Level "ERROR"
        Write-Host "========================================" -ForegroundColor Red
        Write-Host ""
        Write-Ui -Message "Error details:" -Level "WARN"
        Write-Ui -Message "  $($_.Exception.Message)" -Level "ERROR"
        Write-Host ""
        Write-Ui -Message "Possible causes:" -Level "WARN"
        Write-Ui -Message "  - Network connectivity issues" -Level "INFO"
        Write-Ui -Message "  - Firewall or antivirus blocking the download" -Level "INFO"
        Write-Ui -Message "  - PowerShell execution policy restrictions" -Level "INFO"
        Write-Ui -Message "  - Remote server unavailable" -Level "INFO"
        Write-Host ""
        Write-Ui -Message "Troubleshooting steps:" -Level "INFO"
        Write-Ui -Message "  1. Check your internet connection" -Level "INFO"
        Write-Ui -Message "  2. Temporarily disable antivirus/firewall" -Level "INFO"
        Write-Ui -Message "  3. Verify PowerShell execution policy:" -Level "INFO"
        Write-Ui -Message "     Get-ExecutionPolicy" -Level "INFO"
        Write-Ui -Message "  4. Try running directly from GitHub:" -Level "INFO"
        Write-Host "     https://github.com/Raphire/Win11Debloat" -ForegroundColor DarkGray
        Write-Host ""
        
        return $false
    }
}

# ============================================================
# MAIN EXECUTION
# ============================================================

# Show banner
Clear-Host
Show-ScriptBanner -ScriptName "Windows 11 Debloat Tool" -Purpose "Remove bloatware and optimize Windows 11/10 installation"

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
    Write-Ui -Message "Process completed successfully." -Level "OK"
    Write-Host ""
    Write-Ui -Message "Thank you for using SouliTEK tools!" -Level "INFO"
} else {
    Write-Ui -Message "Process encountered errors." -Level "ERROR"
    Write-Host ""
    Write-Ui -Message "Please review the error messages above." -Level "WARN"
}
Write-Host "========================================"
Write-Host ""

Read-Host "Press Enter to exit"

