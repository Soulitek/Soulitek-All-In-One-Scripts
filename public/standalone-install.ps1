# ============================================================
# SouliTEK All-In-One Scripts - Standalone Installer
# ============================================================
# 
# This is a self-contained installer that doesn't require
# downloading additional files from GitHub.
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
Write-Host "     All-In-One Scripts - Standalone Installer" -ForegroundColor White
Write-Host "     https://soulitek.co.il" -ForegroundColor Gray
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

# Configuration
$InstallPath = "C:\SouliTEK"

Write-Host "Debug: Install Path: $InstallPath" -ForegroundColor Yellow

# Check admin privileges
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "[!] " -ForegroundColor Yellow -NoNewline
    Write-Host "Not running as Administrator - some features may be limited"
    Write-Host "[i] " -ForegroundColor Cyan -NoNewline
    Write-Host "For full functionality, run PowerShell as Administrator and try again"
    Write-Host ""
}

# Step 1: Create installation directory
Write-Host "[1/3] Creating installation directory..." -ForegroundColor Cyan
try {
    # Remove old installation if exists
    if (Test-Path $InstallPath) {
        Write-Host "      [i] Removing old installation..." -ForegroundColor Yellow
        Remove-Item -Path $InstallPath -Recurse -Force
    }
    
    # Create directory structure
    $dirs = @(
        $InstallPath,
        "$InstallPath\launcher",
        "$InstallPath\scripts", 
        "$InstallPath\assets\images",
        "$InstallPath\docs"
    )
    
    foreach ($dir in $dirs) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
    
    Write-Host "      [+] Directory structure created" -ForegroundColor Green
}
catch {
    Write-Host "      [!] Failed to create directories: $_" -ForegroundColor Red
    exit 1
}

# Step 2: Create basic launcher
Write-Host "[2/3] Creating launcher..." -ForegroundColor Cyan
try {
    # Create a simple launcher that downloads the full version
    $launcherContent = @'
# ============================================================
# SouliTEK All-In-One Scripts - Launcher
# ============================================================

Write-Host "SouliTEK All-In-One Scripts" -ForegroundColor Cyan
Write-Host "Downloading full version..." -ForegroundColor Yellow

# Download and run the full installer
try {
    Invoke-WebRequest -Uri "https://get.soulitek.co.il" -UseBasicParsing | Invoke-Expression
}
catch {
    Write-Host "Failed to download installer: $_" -ForegroundColor Red
    Write-Host "Please check your internet connection and try again." -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
}
'@
    
    $launcherPath = Join-Path $InstallPath "SouliTEK-Launcher.ps1"
    $launcherContent | Out-File -FilePath $launcherPath -Encoding UTF8
    
    Write-Host "      [+] Launcher created" -ForegroundColor Green
}
catch {
    Write-Host "      [!] Failed to create launcher: $_" -ForegroundColor Red
    exit 1
}

# Step 3: Create shortcuts
Write-Host "[3/3] Creating shortcuts..." -ForegroundColor Cyan
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
    $Shortcut.Save()
    
    Write-Host "      [+] Desktop shortcut created" -ForegroundColor Green
}
catch {
    Write-Host "      [!] Shortcut creation failed: $_" -ForegroundColor Yellow
    Write-Host "      You can still run the launcher from: $InstallPath\SouliTEK-Launcher.ps1" -ForegroundColor Yellow
}

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
