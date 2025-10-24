# ============================================================
# SouliTEK WPF Launcher - Build Script
# ============================================================
# 
# This script builds the WPF launcher into a standalone EXE
# using PS2EXE module
# 
# Prerequisites:
# - PS2EXE module (Install-Module ps2exe -Scope CurrentUser)
# - Icon file converted to .ico format
# 
# ============================================================

#Requires -Version 5.1

param(
    [switch]$SkipModuleCheck,
    [switch]$NoConsole,
    [switch]$RequireAdmin
)

# ============================================================
# CONFIGURATION
# ============================================================

$ScriptRoot = $PSScriptRoot
$LauncherPath = Join-Path $ScriptRoot "launcher\SouliTEK-Launcher-WPF.ps1"
$BuildDir = Join-Path $ScriptRoot "build"
$OutputExe = Join-Path $BuildDir "SouliTEK-Launcher.exe"
$IconPath = Join-Path $ScriptRoot "assets\images\Favicon.ico"

# Build info
$AppTitle = "SouliTEK All-In-One Scripts"
$AppCompany = "SouliTEK"
$AppVersion = "2.0.0"
$AppCopyright = "(C) 2025 SouliTEK - All Rights Reserved"

# ============================================================
# FUNCTIONS
# ============================================================

function Write-Info {
    param([string]$Message)
    Write-Host "[*] $Message" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "[+] $Message" -ForegroundColor Green
}

function Write-Error-Custom {
    param([string]$Message)
    Write-Host "[-] $Message" -ForegroundColor Red
}

function Write-Warning-Custom {
    param([string]$Message)
    Write-Host "[!] $Message" -ForegroundColor Yellow
}

function Test-Prerequisites {
    Write-Info "Checking prerequisites..."
    
    # Check if launcher script exists
    if (-not (Test-Path $LauncherPath)) {
        Write-Error-Custom "Launcher script not found: $LauncherPath"
        return $false
    }
    Write-Success "Launcher script found"
    
    # Check if PS2EXE module is installed
    if (-not $SkipModuleCheck) {
        $ps2exe = Get-Module -ListAvailable -Name ps2exe
        if (-not $ps2exe) {
            Write-Warning-Custom "PS2EXE module not installed"
            Write-Info "Installing PS2EXE module..."
            
            try {
                Install-Module -Name ps2exe -Scope CurrentUser -Force -AllowClobber
                Write-Success "PS2EXE module installed successfully"
            }
            catch {
                Write-Error-Custom "Failed to install PS2EXE module: $_"
                Write-Info "Try running: Install-Module ps2exe -Scope CurrentUser"
                return $false
            }
        }
        else {
            Write-Success "PS2EXE module is installed"
        }
    }
    
    # Check for icon file
    if (Test-Path $IconPath) {
        Write-Success "Icon file found"
    }
    else {
        Write-Warning-Custom "Icon file not found: $IconPath"
        Write-Info "Building without custom icon..."
    }
    
    return $true
}

function New-BuildDirectory {
    if (-not (Test-Path $BuildDir)) {
        Write-Info "Creating build directory..."
        New-Item -ItemType Directory -Path $BuildDir -Force | Out-Null
        Write-Success "Build directory created"
    }
}

function Build-Executable {
    Write-Info "Building executable..."
    Write-Info "Source: $LauncherPath"
    Write-Info "Output: $OutputExe"
    
    try {
        Import-Module ps2exe
        
        $params = @{
            inputFile = $LauncherPath
            outputFile = $OutputExe
            title = $AppTitle
            company = $AppCompany
            version = $AppVersion
            copyright = $AppCopyright
            noError = $true
        }
        
        # Add icon if available
        if (Test-Path $IconPath) {
            $params.iconFile = $IconPath
        }
        
        # Add NoConsole flag if specified
        if ($NoConsole) {
            $params.noConsole = $true
        }
        
        # Add RequireAdmin flag if specified
        if ($RequireAdmin) {
            $params.requireAdmin = $true
        }
        
        Invoke-ps2exe @params
        
        if (Test-Path $OutputExe) {
            Write-Success "Executable built successfully!"
            Write-Info "Location: $OutputExe"
            
            $fileInfo = Get-Item $OutputExe
            Write-Info "Size: $([math]::Round($fileInfo.Length / 1MB, 2)) MB"
            
            return $true
        }
        else {
            Write-Error-Custom "Build failed - output file not created"
            return $false
        }
    }
    catch {
        Write-Error-Custom "Build failed: $_"
        return $false
    }
}

function Copy-Dependencies {
    Write-Info "Copying dependencies to build directory..."
    
    # Copy MainWindow.xaml
    $xamlSource = Join-Path $ScriptRoot "launcher\MainWindow.xaml"
    $xamlDest = Join-Path $BuildDir "MainWindow.xaml"
    
    if (Test-Path $xamlSource) {
        Copy-Item $xamlSource $xamlDest -Force
        Write-Success "MainWindow.xaml copied"
    }
    
    # Copy scripts folder
    $scriptsSource = Join-Path $ScriptRoot "scripts"
    $scriptsDest = Join-Path $BuildDir "scripts"
    
    if (Test-Path $scriptsSource) {
        if (Test-Path $scriptsDest) {
            Remove-Item $scriptsDest -Recurse -Force
        }
        Copy-Item $scriptsSource $scriptsDest -Recurse -Force
        Write-Success "Scripts folder copied"
    }
    
    # Copy assets folder
    $assetsSource = Join-Path $ScriptRoot "assets"
    $assetsDest = Join-Path $BuildDir "assets"
    
    if (Test-Path $assetsSource) {
        if (Test-Path $assetsDest) {
            Remove-Item $assetsDest -Recurse -Force
        }
        Copy-Item $assetsSource $assetsDest -Recurse -Force
        Write-Success "Assets folder copied"
    }
}

function Show-BuildSummary {
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "                    BUILD COMPLETE" -ForegroundColor Green
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Executable: " -NoNewline
    Write-Host "$OutputExe" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Build Directory Contents:" -ForegroundColor Cyan
    Write-Host "  - SouliTEK-Launcher.exe   (Main application)" -ForegroundColor Gray
    Write-Host "  - MainWindow.xaml         (UI definition)" -ForegroundColor Gray
    Write-Host "  - scripts/                (PowerShell tools)" -ForegroundColor Gray
    Write-Host "  - assets/                 (Images and icons)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  Next Steps:" -ForegroundColor Cyan
    Write-Host "  1. Test the executable: .\build\SouliTEK-Launcher.exe" -ForegroundColor Gray
    Write-Host "  2. Distribute the entire build folder" -ForegroundColor Gray
    Write-Host "  3. Or create installer with NSIS" -ForegroundColor Gray
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
}

# ============================================================
# MAIN EXECUTION
# ============================================================

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "   SouliTEK WPF Launcher - Build Script" -ForegroundColor White
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

# Check prerequisites
if (-not (Test-Prerequisites)) {
    Write-Host ""
    Write-Host "Build failed due to missing prerequisites." -ForegroundColor Red
    Write-Host "Press Enter to exit..."
    Read-Host
    exit 1
}

Write-Host ""

# Create build directory
New-BuildDirectory

Write-Host ""

# Build executable
$buildSuccess = Build-Executable

if (-not $buildSuccess) {
    Write-Host ""
    Write-Host "Build failed. Please check the errors above." -ForegroundColor Red
    Write-Host "Press Enter to exit..."
    Read-Host
    exit 1
}

Write-Host ""

# Copy dependencies
Copy-Dependencies

Write-Host ""

# Show summary
Show-BuildSummary

# Ask to open build folder
$openFolder = Read-Host "Would you like to open the build folder? (Y/N)"
if ($openFolder -eq "Y" -or $openFolder -eq "y") {
    Start-Process explorer.exe -ArgumentList $BuildDir
}

Write-Success "Build process completed successfully!"
Write-Host ""

