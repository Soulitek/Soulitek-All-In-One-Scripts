# ============================================================
# SouliTEK All-In-One Scripts - Common Functions
# ============================================================
# 
# This file contains shared functions used across all
# SouliTEK PowerShell tools to eliminate code duplication.
# 
# Coded by: Soulitek.co.il
# IT Solutions for your business
# 
# (C) 2025 SouliTEK - All Rights Reserved
# Website: https://soulitek.co.il
# 
# ============================================================

# Version
$Script:ModuleVersion = "1.0.0"

# ============================================================
# CORE FUNCTIONS
# ============================================================

function Show-SouliTEKBanner {
    <#
    .SYNOPSIS
        Displays the standard SouliTEK ASCII banner and branding.
    
    .DESCRIPTION
        Shows the consistent SouliTEK banner used across all tools with
        company branding, contact information, and copyright notice.
    
    .EXAMPLE
        Show-SouliTEKBanner
        Displays the standard banner with current branding.
    #>
    
    Write-Host ""
    Write-Host "  =========================================================" -ForegroundColor Cyan
    Write-Host "   _____ ____  _    _ _      _____ _______ ______ _  __  " -ForegroundColor Cyan
    Write-Host "  / ____/ __ \| |  | | |    |_   _|__   __|  ____| |/ /  " -ForegroundColor Cyan
    Write-Host " | (___| |  | | |  | | |      | |    | |  | |__  | ' /   " -ForegroundColor Cyan
    Write-Host "  \___ \ |  | | |  | | |      | |    | |  |  __| |  <    " -ForegroundColor Cyan
    Write-Host "  ____) | |__| | |__| | |____ _| |_   | |  | |____| . \   " -ForegroundColor Cyan
    Write-Host " |_____/ \____/ \____/|______|_____|  |_|  |______|_|\_\  " -ForegroundColor Cyan
    Write-Host "  =========================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Website: " -NoNewline -ForegroundColor Gray
    Write-Host "https://soulitek.co.il" -ForegroundColor Cyan
    Write-Host "  Email: " -NoNewline -ForegroundColor Gray
    Write-Host "letstalk@soulitek.co.il" -ForegroundColor Cyan
    Write-Host "  (C) 2025 SouliTEK - All Rights Reserved" -ForegroundColor Gray
    Write-Host ""
}

function Test-SouliTEKAdministrator {
    <#
    .SYNOPSIS
        Checks if the current PowerShell session is running with administrator privileges.
    
    .DESCRIPTION
        Determines whether the current user has administrator privileges by checking
        the Windows security principal and built-in administrator role.
    
    .OUTPUTS
        [bool] True if running as administrator, False otherwise.
    
    .EXAMPLE
        if (Test-SouliTEKAdministrator) {
            Write-Host "Running with administrator privileges"
        }
    #>
    
    try {
        $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
        return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    }
    catch {
        return $false
    }
}

function Write-SouliTEKResult {
    <#
    .SYNOPSIS
        Writes formatted log messages with timestamps and color coding.
    
    .DESCRIPTION
        Provides consistent logging format across all SouliTEK tools with
        timestamps, level indicators, and color-coded output.
    
    .PARAMETER Message
        The message to display.
    
    .PARAMETER Level
        The log level: SUCCESS, ERROR, WARNING, INFO, or default.
    
    .EXAMPLE
        Write-SouliTEKResult "Operation completed successfully" "SUCCESS"
        Displays: [12:34:56] [+] Operation completed successfully
    
    .EXAMPLE
        Write-SouliTEKResult "An error occurred" "ERROR"
        Displays: [12:34:56] [-] An error occurred
    #>
    
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("SUCCESS", "ERROR", "WARNING", "INFO")]
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "HH:mm:ss"
    
    switch ($Level) {
        "SUCCESS" { Write-Host "[$timestamp] [+] $Message" -ForegroundColor Green }
        "ERROR" { Write-Host "[$timestamp] [-] $Message" -ForegroundColor Red }
        "WARNING" { Write-Host "[$timestamp] [!] $Message" -ForegroundColor Yellow }
        "INFO" { Write-Host "[$timestamp] [*] $Message" -ForegroundColor Cyan }
        default { Write-Host "[$timestamp] $Message" -ForegroundColor Gray }
    }
}

function Set-SouliTEKConsoleColor {
    <#
    .SYNOPSIS
        Sets the console foreground color for consistent theming.
    
    .DESCRIPTION
        Provides a standardized way to set console colors across
        all SouliTEK tools with predefined color schemes.
    
    .PARAMETER Color
        The color name to set: Blue, Green, Red, Yellow, Magenta, White, Gray.
    
    .EXAMPLE
        Set-SouliTEKConsoleColor "Green"
        Sets console to green color.
    #>
    
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("Blue", "Green", "Red", "Yellow", "Magenta", "White", "Gray")]
        [string]$Color
    )
    
    switch ($Color) {
        "Blue" { $Host.UI.RawUI.ForegroundColor = "Cyan" }
        "Green" { $Host.UI.RawUI.ForegroundColor = "Green" }
        "Red" { $Host.UI.RawUI.ForegroundColor = "Red" }
        "Yellow" { $Host.UI.RawUI.ForegroundColor = "Yellow" }
        "Magenta" { $Host.UI.RawUI.ForegroundColor = "Magenta" }
        "White" { $Host.UI.RawUI.ForegroundColor = "White" }
        "Gray" { $Host.UI.RawUI.ForegroundColor = "Gray" }
    }
}

function Get-SouliTEKVersion {
    <#
    .SYNOPSIS
        Returns the current version of the SouliTEK Common functions.
    
    .DESCRIPTION
        Provides version information for the shared functions and can be
        used to check compatibility across tools.
    
    .OUTPUTS
        [string] The version number.
    
    .EXAMPLE
        $version = Get-SouliTEKVersion
        Write-Host "Using SouliTEK Common v$version"
    #>
    
    return $Script:ModuleVersion
}

function Show-SouliTEKHeader {
    <#
    .SYNOPSIS
        Displays a formatted header with title and optional subtitle.
    
    .DESCRIPTION
        Creates consistent section headers across all SouliTEK tools
        with customizable titles and color coding.
    
    .PARAMETER Title
        The main title to display.
    
    .PARAMETER Subtitle
        Optional subtitle or description.
    
    .PARAMETER Color
        The color for the header (default: Cyan).
    
    .EXAMPLE
        Show-SouliTEKHeader "SYSTEM ANALYSIS" "Gathering system information..."
        Displays a formatted header with title and subtitle.
    #>
    
    param(
        [Parameter(Mandatory = $true)]
        [string]$Title,
        
        [Parameter(Mandatory = $false)]
        [string]$Subtitle = "",
        
        [Parameter(Mandatory = $false)]
        [ConsoleColor]$Color = 'Cyan'
    )
    
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor $Color
    Write-Host ""
    Write-Host "  $Title" -ForegroundColor $Color
    if ($Subtitle) {
        Write-Host "  $Subtitle" -ForegroundColor Gray
    }
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor $Color
    Write-Host ""
}

# ============================================================
# CONVENIENCE FUNCTIONS
# ============================================================

function Write-SouliTEKInfo {
    <#
    .SYNOPSIS
        Writes an informational message with INFO level.
    
    .PARAMETER Message
        The informational message to display.
    #>
    
    param([string]$Message)
    Write-SouliTEKResult -Message $Message -Level "INFO"
}

function Write-SouliTEKSuccess {
    <#
    .SYNOPSIS
        Writes a success message with SUCCESS level.
    
    .PARAMETER Message
        The success message to display.
    #>
    
    param([string]$Message)
    Write-SouliTEKResult -Message $Message -Level "SUCCESS"
}

function Write-SouliTEKWarning {
    <#
    .SYNOPSIS
        Writes a warning message with WARNING level.
    
    .PARAMETER Message
        The warning message to display.
    #>
    
    param([string]$Message)
    Write-SouliTEKResult -Message $Message -Level "WARNING"
}

function Write-SouliTEKError {
    <#
    .SYNOPSIS
        Writes an error message with ERROR level.
    
    .PARAMETER Message
        The error message to display.
    #>
    
    param([string]$Message)
    Write-SouliTEKResult -Message $Message -Level "ERROR"
}
