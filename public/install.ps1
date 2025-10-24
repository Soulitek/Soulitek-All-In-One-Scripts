# ============================================================
# SouliTEK All-In-One Scripts - Quick Installer
# ============================================================
# 
# Run this script directly from URL:
# iwr -useb https://raw.githubusercontent.com/Soulitek/Soulitek-All-In-One-Scripts/main/Install-SouliTEK.ps1 | iex
# 
# Or with short URL (if configured):
# iwr -useb bit.ly/soulitek-install | iex
#
# This script will:
# 1. Download the latest version from GitHub
# 2. Extract to C:\SouliTEK
# 3. Launch the GUI
# 
# ============================================================

#Requires -Version 5.1

# Add error handling and keep window open
$ErrorActionPreference = "Continue"
trap {
    Write-Host "Error occurred: $_" -ForegroundColor Red
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

# Banner
Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  ____              _ _ _____ _____ _  __" -ForegroundColor Cyan
Write-Host " / ___|  ___  _   _| (_)_   _| ____| |/ /" -ForegroundColor Cyan
Write-Host " \___ \ / _ \| | | | | | | | |  _| | ' / " -ForegroundColor Cyan
Write-Host "  ___) | (_) | |_| | | | | | | |___| . \ " -ForegroundColor Cyan
Write-Host " |____/ \___/ \__,_|_|_| |_| |_____|_|\_\" -ForegroundColor Cyan
Write-Host "" -ForegroundColor Cyan
Write-Host "     All-In-One Scripts - Quick Installer" -ForegroundColor White
Write-Host "     https://soulitek.co.il" -ForegroundColor Gray
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

# Configuration
$InstallPath = "C:\SouliTEK"
$TempDir = Join-Path $env:TEMP "SouliTEK-Install"

Write-Host "Debug: Install Path: $InstallPath" -ForegroundColor Yellow
Write-Host "Debug: Temp Directory: $TempDir" -ForegroundColor Yellow

# Check admin privileges
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "[!] " -ForegroundColor Yellow -NoNewline
    Write-Host "Not running as Administrator - some features may be limited"
    Write-Host "[i] " -ForegroundColor Cyan -NoNewline
    Write-Host "For full functionality, run PowerShell as Administrator and try again"
    Write-Host ""
}

# Step 1: Create installation files
Write-Host "[1/4] Preparing installation files..." -ForegroundColor Cyan

try {
    # Create temp directory
    if (Test-Path $TempDir) {
        Remove-Item -Path $TempDir -Recurse -Force
    }
    New-Item -ItemType Directory -Path $TempDir -Force | Out-Null
    
    # Create the directory structure
    $dirs = @(
        "launcher",
        "scripts", 
        "assets\images",
        "docs"
    )
    
    foreach ($dir in $dirs) {
        $fullPath = Join-Path $TempDir $dir
        New-Item -ItemType Directory -Path $fullPath -Force | Out-Null
    }
    
    Write-Host "      [+] Directory structure created" -ForegroundColor Green
}
catch {
    Write-Host "      [!] Failed to create directories: $_" -ForegroundColor Red
    exit 1
}

# Step 2: Copy files from current directory
Write-Host "[2/4] Copying files..." -ForegroundColor Cyan
try {
    # Get the directory where this script is running from
    $ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    
    # Copy launcher
    $launcherSource = Join-Path $ScriptDir "launcher\SouliTEK-Launcher.ps1"
    $launcherDest = Join-Path $TempDir "launcher\SouliTEK-Launcher.ps1"
    if (Test-Path $launcherSource) {
        Copy-Item -Path $launcherSource -Destination $launcherDest -Force
    }
    
    # Copy scripts
    $scriptsSource = Join-Path $ScriptDir "scripts"
    $scriptsDest = Join-Path $TempDir "scripts"
    if (Test-Path $scriptsSource) {
        Copy-Item -Path "$scriptsSource\*" -Destination $scriptsDest -Recurse -Force
    }
    
    # Copy assets
    $assetsSource = Join-Path $ScriptDir "assets"
    $assetsDest = Join-Path $TempDir "assets"
    if (Test-Path $assetsSource) {
        Copy-Item -Path "$assetsSource\*" -Destination $assetsDest -Recurse -Force
    }
    
    # Copy docs
    $docsSource = Join-Path $ScriptDir "docs"
    $docsDest = Join-Path $TempDir "docs"
    if (Test-Path $docsSource) {
        Copy-Item -Path "$docsSource\*" -Destination $docsDest -Recurse -Force
    }
    
    # Copy main launcher wrapper
    $mainLauncherSource = Join-Path $ScriptDir "SouliTEK-Launcher.ps1"
    $mainLauncherDest = Join-Path $TempDir "SouliTEK-Launcher.ps1"
    if (Test-Path $mainLauncherSource) {
        Copy-Item -Path $mainLauncherSource -Destination $mainLauncherDest -Force
    }
    
    Write-Host "      [+] Files copied successfully" -ForegroundColor Green
}
catch {
    Write-Host "      [!] File copy failed: $_" -ForegroundColor Red
    exit 1
}

# Step 3: Install to destination
Write-Host "[3/4] Installing to $InstallPath..." -ForegroundColor Cyan
try {
    # Remove old installation if exists
    if (Test-Path $InstallPath) {
        Write-Host "      [i] Removing old installation..." -ForegroundColor Yellow
        Remove-Item -Path $InstallPath -Recurse -Force
    }
    
    # Create parent directory if needed
    $ParentPath = Split-Path -Parent $InstallPath
    if (-not (Test-Path $ParentPath)) {
        New-Item -ItemType Directory -Path $ParentPath -Force | Out-Null
    }
    
    # Copy files to installation directory
    Copy-Item -Path $TempDir -Destination $InstallPath -Recurse -Force
    
    Write-Host "      [+] Installed successfully" -ForegroundColor Green
}
catch {
    Write-Host "      [!] Installation failed: $_" -ForegroundColor Red
    exit 1
}

# Step 4: Create shortcuts
Write-Host "[4/4] Creating shortcuts..." -ForegroundColor Cyan
try {
    $WScriptShell = New-Object -ComObject WScript.Shell
    
    # Desktop shortcut
    $DesktopPath = [Environment]::GetFolderPath("Desktop")
    $ShortcutPath = Join-Path $DesktopPath "SouliTEK Launcher.lnk"
    $Shortcut = $WScriptShell.CreateShortcut($ShortcutPath)
    $Shortcut.TargetPath = "powershell.exe"
    $Shortcut.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$InstallPath\SouliTEK-Launcher.ps1`""
    $Shortcut.WorkingDirectory = $InstallPath
    $Shortcut.Description = "SouliTEK All-In-One Scripts Launcher"
    
    # Set icon if available
    $IconPath = Join-Path $InstallPath "assets\images\Favicon.png"
    if (Test-Path $IconPath) {
        $Shortcut.IconLocation = $IconPath
    }
    
    $Shortcut.Save()
    
    Write-Host "      [+] Desktop shortcut created" -ForegroundColor Green
}
catch {
    Write-Host "      [!] Shortcut creation failed: $_" -ForegroundColor Yellow
    Write-Host "      You can still run the launcher from: $InstallPath\SouliTEK-Launcher.ps1" -ForegroundColor Yellow
}

# Clean up
Write-Host ""
Write-Host "[i] Cleaning up temporary files..." -ForegroundColor Cyan
Remove-Item -Path $TempDir -Recurse -Force -ErrorAction SilentlyContinue

# Success message
Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host " Installation Complete!" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Installation Directory: " -NoNewline
Write-Host $InstallPath -ForegroundColor Cyan
Write-Host ""
Write-Host "You can now:" -ForegroundColor White
Write-Host "  1. Use the desktop shortcut: 'SouliTEK Launcher'" -ForegroundColor Gray
Write-Host "  2. Run from: $InstallPath\SouliTEK-Launcher.ps1" -ForegroundColor Gray
Write-Host ""

# Automatically launch the GUI
Write-Host ""
Write-Host "[*] Launching SouliTEK GUI..." -ForegroundColor Cyan
Start-Sleep -Seconds 1

# Launch the GUI
$LauncherScript = Join-Path $InstallPath "SouliTEK-Launcher.ps1"

if ($isAdmin) {
    # Run directly if already admin
    & $LauncherScript
}
else {
    # Run without elevation (user can elevate from GUI if needed)
    Start-Process -FilePath "powershell.exe" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$LauncherScript`""
}

Write-Host ""
Write-Host "Thank you for using SouliTEK!" -ForegroundColor Green
Write-Host "Visit: https://soulitek.co.il | letstalk@soulitek.co.il" -ForegroundColor Gray
Write-Host ""

# Keep window open if there were any errors
if ($Error.Count -gt 0) {
    Write-Host ""
    Write-Host "Errors occurred during installation. Press any key to exit..." -ForegroundColor Red
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

