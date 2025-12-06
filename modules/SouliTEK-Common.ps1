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
$Script:ModuleVersion = "1.1.0"

# ============================================================
# CONFIGURATION CONSTANTS
# ============================================================

$Script:SouliTEKConfig = @{
    BrandColor = "#667eea"
    BrandColorSecondary = "#764ba2"
    Website = "www.soulitek.co.il"
    Email = "letstalk@soulitek.co.il"
    CompanyName = "SouliTEK"
    Copyright = "(C) 2025 SouliTEK - All Rights Reserved"
    DefaultTimeout = 420  # 7 minutes in seconds
    MaxHistoryEntries = 50
    ProjectRoot = $null  # Set dynamically
}

# Set project root dynamically
$Script:SouliTEKConfig.ProjectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)

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
        with customizable titles and color coding. Can optionally clear
        the host and show the SouliTEK banner for full-screen headers.
    
    .PARAMETER Title
        The main title to display.
    
    .PARAMETER Subtitle
        Optional subtitle or description.
    
    .PARAMETER Color
        The color for the header (default: Cyan).
    
    .PARAMETER ClearHost
        If specified, clears the console before displaying the header.
    
    .PARAMETER ShowBanner
        If specified, shows the SouliTEK banner before the header.
    
    .EXAMPLE
        Show-SouliTEKHeader "SYSTEM ANALYSIS" "Gathering system information..."
        Displays a formatted header with title and subtitle.
    
    .EXAMPLE
        Show-SouliTEKHeader -Title "NETWORK TEST TOOL" -ClearHost -ShowBanner
        Clears screen, shows banner, then displays header (replaces Show-Header pattern).
    #>
    
    param(
        [Parameter(Mandatory = $true)]
        [string]$Title,
        
        [Parameter(Mandatory = $false)]
        [string]$Subtitle = "",
        
        [Parameter(Mandatory = $false)]
        [ConsoleColor]$Color = 'Cyan',
        
        [Parameter(Mandatory = $false)]
        [switch]$ClearHost,
        
        [Parameter(Mandatory = $false)]
        [switch]$ShowBanner
    )
    
    if ($ClearHost) {
        Clear-Host
    }
    
    if ($ShowBanner) {
        Show-SouliTEKBanner
    }
    
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
# UI/DISPLAY FUNCTIONS
# ============================================================

function Format-SouliTEKFileSize {
    <#
    .SYNOPSIS
        Formats a file size in bytes to a human-readable string.
    
    .DESCRIPTION
        Converts bytes to the most appropriate unit (Bytes, KB, MB, GB, TB)
        with two decimal places for readability.
    
    .PARAMETER SizeInBytes
        The size in bytes to format.
    
    .OUTPUTS
        [string] Formatted size string (e.g., "1.25 GB").
    
    .EXAMPLE
        Format-SouliTEKFileSize 1073741824
        Returns: "1.00 GB"
    #>
    
    param(
        [Parameter(Mandatory = $true)]
        [long]$SizeInBytes
    )
    
    if ($SizeInBytes -ge 1TB) {
        return "{0:N2} TB" -f ($SizeInBytes / 1TB)
    }
    elseif ($SizeInBytes -ge 1GB) {
        return "{0:N2} GB" -f ($SizeInBytes / 1GB)
    }
    elseif ($SizeInBytes -ge 1MB) {
        return "{0:N2} MB" -f ($SizeInBytes / 1MB)
    }
    elseif ($SizeInBytes -ge 1KB) {
        return "{0:N2} KB" -f ($SizeInBytes / 1KB)
    }
    else {
        return "$SizeInBytes Bytes"
    }
}

function Show-SouliTEKDisclaimer {
    <#
    .SYNOPSIS
        Displays the standard SouliTEK disclaimer notice.
    
    .DESCRIPTION
        Shows a consistent disclaimer across all tools with
        legal notice and user acknowledgment prompt.
    
    .PARAMETER ToolName
        Optional name of the tool to include in disclaimer.
    
    .EXAMPLE
        Show-SouliTEKDisclaimer
        Displays standard disclaimer and waits for key press.
    #>
    
    param(
        [Parameter(Mandatory = $false)]
        [string]$ToolName = ""
    )
    
    Clear-Host
    Show-SouliTEKBanner
    Write-Host "============================================================" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "                    IMPORTANT NOTICE" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  This tool is provided `"AS IS`" without warranty." -ForegroundColor White
    Write-Host ""
    Write-Host "  USE AT YOUR OWN RISK" -ForegroundColor Red
    Write-Host ""
    Write-Host "  By continuing, you acknowledge that:" -ForegroundColor White
    Write-Host "  - You are solely responsible for any outcomes" -ForegroundColor Gray
    Write-Host "  - You understand the actions this tool will perform" -ForegroundColor Gray
    Write-Host "  - You accept full responsibility for its use" -ForegroundColor Gray
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Press any key to continue or Ctrl+C to cancel..." -ForegroundColor Cyan
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Show-SouliTEKExitMessage {
    <#
    .SYNOPSIS
        Displays the standard exit message.
    
    .DESCRIPTION
        Shows a consistent exit message with company branding.
    
    .PARAMETER ScriptPath
        Optional path to the script (deprecated, kept for compatibility).
    
    .PARAMETER ToolName
        Optional name of the tool for personalized message.
    
    .EXAMPLE
        Show-SouliTEKExitMessage
        Shows exit message.
    #>
    
    param(
        [Parameter(Mandatory = $false)]
        [string]$ScriptPath = "",
        
        [Parameter(Mandatory = $false)]
        [string]$ToolName = "SouliTEK Tool"
    )
    
    Clear-Host
    Write-Host ""
    Write-Host "Thank you for using $ToolName!" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Website: $($Script:SouliTEKConfig.Website)" -ForegroundColor Yellow
    Write-Host ""
}

function Wait-SouliTEKKeyPress {
    <#
    .SYNOPSIS
        Waits for user to press any key with optional custom message.
    
    .PARAMETER Message
        The message to display before waiting.
    
    .EXAMPLE
        Wait-SouliTEKKeyPress
        Wait-SouliTEKKeyPress -Message "Press any key to continue..."
    #>
    
    param(
        [Parameter(Mandatory = $false)]
        [string]$Message = "Press any key to return to main menu..."
    )
    
    Write-Host ""
    Write-Host $Message -ForegroundColor Cyan
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Initialize-SouliTEKScript {
    <#
    .SYNOPSIS
        Initializes a SouliTEK script with standard setup.
    
    .DESCRIPTION
        Sets window title, displays banner, and performs
        common initialization tasks for SouliTEK scripts.
    
    .PARAMETER WindowTitle
        The title to display in the console window.
    
    .PARAMETER ShowBanner
        Whether to show the SouliTEK banner (default: true).
    
    .EXAMPLE
        Initialize-SouliTEKScript -WindowTitle "NETWORK TEST TOOL"
    #>
    
    param(
        [Parameter(Mandatory = $true)]
        [string]$WindowTitle,
        
        [Parameter(Mandatory = $false)]
        [switch]$ShowBanner = $true
    )
    
    $Host.UI.RawUI.WindowTitle = $WindowTitle
    
    if ($ShowBanner) {
        Show-SouliTEKBanner
    }
}

function Invoke-SouliTEKAdminCheck {
    <#
    .SYNOPSIS
        Checks for administrator privileges with standardized messaging.
    
    .DESCRIPTION
        Checks if running as admin and displays appropriate messages.
        Can either warn or exit based on requirement level.
    
    .PARAMETER Required
        If true, exits the script if not admin. If false, shows warning.
    
    .PARAMETER FeatureName
        Name of the feature requiring admin (for messaging).
    
    .OUTPUTS
        [bool] True if admin, False otherwise.
    
    .EXAMPLE
        Invoke-SouliTEKAdminCheck -Required
        Exits if not admin.
    
    .EXAMPLE
        Invoke-SouliTEKAdminCheck -FeatureName "System Cleanup"
        Shows warning if not admin but continues.
    #>
    
    param(
        [Parameter(Mandatory = $false)]
        [switch]$Required,
        
        [Parameter(Mandatory = $false)]
        [string]$FeatureName = "This tool"
    )
    
    $isAdmin = Test-SouliTEKAdministrator
    
    if (-not $isAdmin) {
        if ($Required) {
            Write-Host ""
            Write-Host "========================================" -ForegroundColor Red
            Write-Host "   ERROR: Administrator Required" -ForegroundColor Red
            Write-Host "========================================" -ForegroundColor Red
            Write-Host ""
            Write-Host "$FeatureName requires administrator privileges." -ForegroundColor Yellow
            Write-Host ""
            Write-Host "HOW TO FIX:" -ForegroundColor White
            Write-Host "1. Right-click PowerShell" -ForegroundColor Gray
            Write-Host "2. Select `"Run as administrator`"" -ForegroundColor Gray
            Write-Host "3. Navigate to script location and run it" -ForegroundColor Gray
            Write-Host ""
            Write-Host "========================================" -ForegroundColor Red
            Write-Host ""
            Read-Host "Press Enter to exit"
            exit 1
        }
        else {
            Write-Host ""
            Write-Host "Warning: $FeatureName works best with administrator privileges." -ForegroundColor Yellow
            Write-Host "Some features may not work without admin rights." -ForegroundColor Yellow
            Write-Host ""
            Start-Sleep -Seconds 2
        }
    }
    
    return $isAdmin
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

# ============================================================
# EXPORT/REPORT FUNCTIONS
# ============================================================

function Export-SouliTEKReport {
    <#
    .SYNOPSIS
        Centralized report export function supporting TXT, CSV, and HTML formats.
    
    .DESCRIPTION
        Provides a consistent, branded export function for all SouliTEK tools.
        Supports multiple formats with SouliTEK branding and styling.
    
    .PARAMETER Data
        Array of PSCustomObject data to export.
    
    .PARAMETER Title
        Report title (e.g., "Disk Usage Analysis").
    
    .PARAMETER Format
        Export format: TXT, CSV, or HTML.
    
    .PARAMETER OutputPath
        Full path to the output file.
    
    .PARAMETER OpenAfterExport
        Whether to open the file after export.
    
    .PARAMETER ExtraInfo
        Optional hashtable of additional info to include in header.
    
    .PARAMETER Columns
        Optional array of column names to include (for TXT/HTML formatting).
    
    .EXAMPLE
        Export-SouliTEKReport -Data $results -Title "Network Test" -Format "HTML" -OutputPath "C:\report.html"
    
    .OUTPUTS
        [bool] True if export succeeded.
    #>
    
    param(
        [Parameter(Mandatory = $true)]
        [PSObject[]]$Data,
        
        [Parameter(Mandatory = $true)]
        [string]$Title,
        
        [Parameter(Mandatory = $true)]
        [ValidateSet("TXT", "CSV", "HTML")]
        [string]$Format,
        
        [Parameter(Mandatory = $true)]
        [string]$OutputPath,
        
        [Parameter(Mandatory = $false)]
        [switch]$OpenAfterExport = $true,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$ExtraInfo = @{},
        
        [Parameter(Mandatory = $false)]
        [string[]]$Columns = @()
    )
    
    try {
        # Ensure output directory exists
        $outputDir = Split-Path -Parent $OutputPath
        if (-not (Test-Path $outputDir)) {
            New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
        }
        
        switch ($Format.ToUpper()) {
            "TXT" {
                Export-SouliTEKTextReport -Data $Data -Title $Title -OutputPath $OutputPath -ExtraInfo $ExtraInfo
            }
            "CSV" {
                $Data | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
            }
            "HTML" {
                Export-SouliTEKHtmlReport -Data $Data -Title $Title -OutputPath $OutputPath -ExtraInfo $ExtraInfo -Columns $Columns
            }
        }
        
        Write-SouliTEKSuccess "Report exported to: $OutputPath"
        
        if ($OpenAfterExport) {
            Start-Sleep -Seconds 1
            Start-Process $OutputPath
        }
        
        return $true
    }
    catch {
        Write-SouliTEKError "Failed to export report: $($_.Exception.Message)"
        return $false
    }
}

function Export-SouliTEKTextReport {
    <#
    .SYNOPSIS
        Internal function to export TXT reports with SouliTEK branding.
    #>
    
    param(
        [PSObject[]]$Data,
        [string]$Title,
        [string]$OutputPath,
        [hashtable]$ExtraInfo
    )
    
    $content = @()
    $content += "============================================================"
    $content += "    $Title - by $($Script:SouliTEKConfig.CompanyName)"
    $content += "============================================================"
    $content += ""
    $content += "Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    $content += "Computer: $env:COMPUTERNAME"
    $content += "User: $env:USERNAME"
    
    # Add extra info
    foreach ($key in $ExtraInfo.Keys) {
        $content += "$key`: $($ExtraInfo[$key])"
    }
    
    $content += ""
    $content += "============================================================"
    $content += "RESULTS:"
    $content += "============================================================"
    $content += ""
    
    # Get properties from first item
    if ($Data.Count -gt 0) {
        $properties = $Data[0].PSObject.Properties.Name
        
        $index = 1
        foreach ($item in $Data) {
            $content += "[$index]"
            foreach ($prop in $properties) {
                $content += "    $prop`: $($item.$prop)"
            }
            $content += ""
            $index++
        }
    }
    
    $content += ""
    $content += "============================================================"
    $content += "END OF REPORT"
    $content += "Generated by $($Script:SouliTEKConfig.CompanyName)"
    $content += "$($Script:SouliTEKConfig.Website)"
    $content += "============================================================"
    
    $content | Out-File -FilePath $OutputPath -Encoding UTF8
}

function Export-SouliTEKHtmlReport {
    <#
    .SYNOPSIS
        Internal function to export HTML reports with SouliTEK branding.
    #>
    
    param(
        [PSObject[]]$Data,
        [string]$Title,
        [string]$OutputPath,
        [hashtable]$ExtraInfo,
        [string[]]$Columns
    )
    
    # Get columns from data if not specified
    if ($Columns.Count -eq 0 -and $Data.Count -gt 0) {
        $Columns = $Data[0].PSObject.Properties.Name
    }
    
    $brandColor = $Script:SouliTEKConfig.BrandColor
    $brandColorSecondary = $Script:SouliTEKConfig.BrandColorSecondary
    $website = $Script:SouliTEKConfig.Website
    $email = $Script:SouliTEKConfig.Email
    
    $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>$Title - $env:COMPUTERNAME</title>
    <meta charset="utf-8">
    <style>
        * { box-sizing: border-box; }
        body { 
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; 
            margin: 0; 
            padding: 20px; 
            background-color: #f5f5f5; 
            color: #333;
        }
        .container { max-width: 1200px; margin: 0 auto; }
        .header { 
            background: linear-gradient(135deg, $brandColor 0%, $brandColorSecondary 100%); 
            color: white; 
            padding: 30px; 
            border-radius: 10px; 
            margin-bottom: 30px;
            box-shadow: 0 4px 6px rgba(0,0,0,0.1);
        }
        .header h1 { margin: 0 0 15px 0; font-size: 28px; }
        .header p { margin: 5px 0; opacity: 0.9; }
        .info-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 15px;
            margin-bottom: 30px;
        }
        .info-card {
            background: white;
            padding: 20px;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        .info-card h3 { margin: 0 0 10px 0; color: $brandColor; font-size: 14px; }
        .info-card .value { font-size: 24px; font-weight: bold; color: #333; }
        table { 
            width: 100%; 
            border-collapse: collapse; 
            background-color: white; 
            border-radius: 8px; 
            overflow: hidden;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        th { 
            background-color: #34495e; 
            color: white; 
            padding: 15px 12px; 
            text-align: left;
            font-weight: 600;
        }
        td { 
            padding: 12px; 
            border-bottom: 1px solid #ecf0f1; 
        }
        tr:hover { background-color: #f8f9fa; }
        tr:last-child td { border-bottom: none; }
        .footer { 
            text-align: center; 
            margin-top: 30px; 
            padding: 20px;
            color: #7f8c8d; 
            font-size: 12px; 
        }
        .footer a { color: $brandColor; text-decoration: none; }
        .footer a:hover { text-decoration: underline; }
        .badge {
            display: inline-block;
            padding: 4px 8px;
            border-radius: 4px;
            font-size: 12px;
            font-weight: bold;
        }
        .badge-success { background: #d4edda; color: #155724; }
        .badge-warning { background: #fff3cd; color: #856404; }
        .badge-error { background: #f8d7da; color: #721c24; }
        .badge-info { background: #d1ecf1; color: #0c5460; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>$Title</h1>
            <p><strong>Computer:</strong> $env:COMPUTERNAME | <strong>User:</strong> $env:USERNAME</p>
            <p><strong>Generated:</strong> $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</p>
"@
    
    # Add extra info to header
    foreach ($key in $ExtraInfo.Keys) {
        $html += "            <p><strong>$key`:</strong> $($ExtraInfo[$key])</p>`n"
    }
    
    $html += @"
        </div>
        
        <div class="info-grid">
            <div class="info-card">
                <h3>Total Records</h3>
                <div class="value">$($Data.Count)</div>
            </div>
        </div>
        
        <table>
            <thead>
                <tr>
"@
    
    # Add column headers
    foreach ($col in $Columns) {
        $html += "                    <th>$col</th>`n"
    }
    
    $html += @"
                </tr>
            </thead>
            <tbody>
"@
    
    # Add data rows
    foreach ($item in $Data) {
        $html += "                <tr>`n"
        foreach ($col in $Columns) {
            $value = $item.$col
            if ($null -eq $value) { $value = "" }
            $html += "                    <td>$value</td>`n"
        }
        $html += "                </tr>`n"
    }
    
    $html += @"
            </tbody>
        </table>
        
        <div class="footer">
            <p>Generated by SouliTEK Tools</p>
            <p><a href="https://$website">$website</a> | <a href="mailto:$email">$email</a></p>
            <p>$($Script:SouliTEKConfig.Copyright)</p>
        </div>
    </div>
</body>
</html>
"@
    
    $html | Out-File -FilePath $OutputPath -Encoding UTF8
}

function Show-SouliTEKExportMenu {
    <#
    .SYNOPSIS
        Displays a standard export format selection menu.
    
    .DESCRIPTION
        Provides a consistent export format selection UI for all tools.
    
    .PARAMETER Title
        Title for the export menu.
    
    .OUTPUTS
        [string] Selected format: "TXT", "CSV", "HTML", "ALL", or "CANCEL"
    
    .EXAMPLE
        $format = Show-SouliTEKExportMenu -Title "Export Network Results"
    #>
    
    param(
        [Parameter(Mandatory = $false)]
        [string]$Title = "EXPORT REPORT"
    )
    
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "  $Title" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Select export format:" -ForegroundColor White
    Write-Host ""
    Write-Host "  [1] Text File (.txt)" -ForegroundColor Yellow
    Write-Host "  [2] CSV File (.csv)" -ForegroundColor Yellow
    Write-Host "  [3] HTML Report (.html)" -ForegroundColor Yellow
    Write-Host "  [4] All Formats" -ForegroundColor Cyan
    Write-Host "  [0] Cancel" -ForegroundColor Red
    Write-Host ""
    
    $choice = Read-Host "Enter your choice (0-4)"
    
    switch ($choice) {
        "1" { return "TXT" }
        "2" { return "CSV" }
        "3" { return "HTML" }
        "4" { return "ALL" }
        "0" { return "CANCEL" }
        default { 
            Write-Host "Invalid choice" -ForegroundColor Red
            return "CANCEL" 
        }
    }
}
