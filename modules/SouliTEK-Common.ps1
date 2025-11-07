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
# Website: www.soulitek.co.il
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
    Write-Host "   _____ ____  _    _ _      _____ _______ ______ _  __" -ForegroundColor Cyan
    Write-Host "  / ____/ __ \| |  | | |    |_   _|__   __|  ____| |/ /" -ForegroundColor Cyan
    Write-Host " | (___| |  | | |  | | |      | |    | |  | |__  | ' /" -ForegroundColor Cyan
    Write-Host "  \___ \ |  | | |  | | |      | |    | |  |  __| |  <" -ForegroundColor Cyan
    Write-Host "  ____) | |__| | |__| | |____ _| |_   | |  | |____| . \" -ForegroundColor Cyan
    Write-Host " |_____/ \____/ \____/|______|_____|  |_|  |______|_|\_\" -ForegroundColor Cyan
    Write-Host "  =========================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Website: " -NoNewline -ForegroundColor Gray
    Write-Host "www.soulitek.co.il" -ForegroundColor Cyan
    Write-Host "  Email: " -NoNewline -ForegroundColor Gray
    Write-Host "letstalk@soulitek.co.il" -ForegroundColor Cyan
    Write-Host "  (C) 2025 SouliTEK - All Rights Reserved" -ForegroundColor Gray
    Write-Host ""
}

# Backward-compatibility shim: legacy function name used by older scripts
function Show-Banner {
    Show-SouliTEKBanner
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

# ============================================================
# MODULE MANAGEMENT FUNCTIONS
# ============================================================

function Install-SouliTEKModule {
    <#
    .SYNOPSIS
        Centralized module installation with error handling.
    
    .DESCRIPTION
        Installs or updates PowerShell modules with proper error handling,
        NuGet provider management, and PowerShellGet verification.
        Reduces code duplication across M365 and other scripts.
    
    .PARAMETER ModuleName
        The name of the module to install (e.g., "Microsoft.Graph.Users").
    
    .PARAMETER MinimumVersion
        Optional minimum version required for the module.
    
    .PARAMETER Force
        Force reinstallation even if module exists.
    
    .PARAMETER Scope
        Installation scope - CurrentUser (default) or AllUsers.
    
    .OUTPUTS
        [bool] True if successful, False if failed.
    
    .EXAMPLE
        Install-SouliTEKModule -ModuleName "Microsoft.Graph.Users"
        Installs Microsoft Graph Users module for current user.
    
    .EXAMPLE
        Install-SouliTEKModule -ModuleName "Microsoft.Graph.Authentication" -MinimumVersion "2.0.0"
        Installs specific minimum version of the module.
    #>
    
    param(
        [Parameter(Mandatory = $true)]
        [string]$ModuleName,
        
        [Parameter(Mandatory = $false)]
        [string]$MinimumVersion = "",
        
        [Parameter(Mandatory = $false)]
        [switch]$Force,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("CurrentUser", "AllUsers")]
        [string]$Scope = "CurrentUser"
    )
    
    try {
        # Step 1: Ensure NuGet provider is installed
        Write-Host "  [*] Checking NuGet provider..." -ForegroundColor Cyan
        $nuGetProvider = Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue
        
        if (-not $nuGetProvider -or ($nuGetProvider.Version -lt [version]"2.8.5.201")) {
            Write-Host "  [*] Installing NuGet provider..." -ForegroundColor Yellow
            try {
                Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope $Scope -ErrorAction Stop | Out-Null
                Write-Host "  [+] NuGet provider installed successfully" -ForegroundColor Green
            }
            catch {
                Write-Host "  [-] Failed to install NuGet provider: $($_.Exception.Message)" -ForegroundColor Red
                return $false
            }
        }
        
        # Step 2: Ensure PowerShellGet is available
        $psGet = Get-Module -Name PowerShellGet -ListAvailable | Sort-Object Version -Descending | Select-Object -First 1
        if (-not $psGet) {
            Write-Host "  [-] PowerShellGet module not found" -ForegroundColor Red
            Write-Host "  [!] Please install PowerShellGet manually" -ForegroundColor Yellow
            return $false
        }
        
        # Step 3: Check if module is already installed
        Write-Host "  [*] Checking for $ModuleName..." -ForegroundColor Cyan
        $installedModule = Get-Module -Name $ModuleName -ListAvailable | Sort-Object Version -Descending | Select-Object -First 1
        
        $needsInstall = $false
        
        if ($installedModule) {
            if ($MinimumVersion) {
                if ($installedModule.Version -lt [version]$MinimumVersion) {
                    Write-Host "  [!] Installed version $($installedModule.Version) is older than required $MinimumVersion" -ForegroundColor Yellow
                    $needsInstall = $true
                }
                elseif ($Force) {
                    Write-Host "  [!] Force flag specified, reinstalling..." -ForegroundColor Yellow
                    $needsInstall = $true
                }
                else {
                    Write-Host "  [+] $ModuleName version $($installedModule.Version) is already installed" -ForegroundColor Green
                }
            }
            elseif ($Force) {
                Write-Host "  [!] Force flag specified, reinstalling..." -ForegroundColor Yellow
                $needsInstall = $true
            }
            else {
                Write-Host "  [+] $ModuleName is already installed (version $($installedModule.Version))" -ForegroundColor Green
            }
        }
        else {
            Write-Host "  [!] $ModuleName not found, installing..." -ForegroundColor Yellow
            $needsInstall = $true
        }
        
        # Step 4: Install or update module if needed
        if ($needsInstall) {
            Write-Host "  [*] Installing $ModuleName..." -ForegroundColor Cyan
            
            try {
                $installParams = @{
                    Name = $ModuleName
                    Scope = $Scope
                    Force = $true
                    ErrorAction = 'Stop'
                }
                
                if ($MinimumVersion) {
                    $installParams.MinimumVersion = $MinimumVersion
                }
                
                Install-Module @installParams | Out-Null
                Write-Host "  [+] $ModuleName installed successfully" -ForegroundColor Green
            }
            catch {
                Write-Host "  [-] Failed to install $ModuleName" -ForegroundColor Red
                Write-Host "  [-] Error: $($_.Exception.Message)" -ForegroundColor Red
                Write-Host ""
                Write-Host "  [!] Try manual installation:" -ForegroundColor Yellow
                Write-Host "      Install-Module -Name $ModuleName -Scope CurrentUser -Force" -ForegroundColor Gray
                return $false
            }
        }
        
        # Step 5: Import the module
        Write-Host "  [*] Importing $ModuleName..." -ForegroundColor Cyan
        try {
            Import-Module -Name $ModuleName -Force -ErrorAction Stop
            Write-Host "  [+] $ModuleName imported successfully" -ForegroundColor Green
            return $true
        }
        catch {
            Write-Host "  [-] Failed to import ${ModuleName}: $($_.Exception.Message)" -ForegroundColor Red
            return $false
        }
    }
    catch {
        Write-Host "  [-] Unexpected error in Install-SouliTEKModule: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}
