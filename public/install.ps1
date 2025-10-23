# ============================================================
# SouliTEK All-In-One Scripts - Quick Installer
# ============================================================
# 
# Run this script directly from URL:
# iwr -useb https://raw.githubusercontent.com/Soulitek/Soulitek-AIO/main/Install-SouliTEK.ps1 | iex
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
$RepoOwner = "Soulitek"
$RepoName = "Soulitek-All-In-One-Scripts"  # Correct repository name
$Branch = "main"
$InstallPath = "C:\SouliTEK"
$ZipUrl = "https://github.com/$RepoOwner/$RepoName/archive/refs/heads/$Branch.zip"
$TempZip = Join-Path $env:TEMP "SouliTEK-AIO.zip"
$TempExtract = Join-Path $env:TEMP "SouliTEK-AIO-Extract"

Write-Host "Debug: Repository: $RepoOwner/$RepoName" -ForegroundColor Yellow
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

# Step 1: Download
Write-Host "[1/4] Downloading latest version from Vercel..." -ForegroundColor Cyan
Write-Host "Debug: Download URL will be: $ZipUrl" -ForegroundColor Yellow
try {
    # Enable TLS 1.2
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    
    # Download with progress
    $ProgressPreference = 'SilentlyContinue'
    Invoke-WebRequest -Uri $ZipUrl -OutFile $TempZip -UseBasicParsing
    $ProgressPreference = 'Continue'
    
    Write-Host "      [+] Downloaded successfully" -ForegroundColor Green
}
catch {
    Write-Host "      [!] Download failed: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please check your internet connection and try again." -ForegroundColor Yellow
    Write-Host "Or download manually from: https://github.com/$RepoOwner/$RepoName" -ForegroundColor Yellow
    exit 1
}

# Step 2: Extract
Write-Host "[2/4] Extracting files..." -ForegroundColor Cyan
try {
    # Clean up temp extract folder if it exists
    if (Test-Path $TempExtract) {
        Remove-Item -Path $TempExtract -Recurse -Force
    }
    
    # Extract ZIP
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::ExtractToDirectory($TempZip, $TempExtract)
    
    Write-Host "      [+] Extracted successfully" -ForegroundColor Green
}
catch {
    Write-Host "      [!] Extraction failed: $_" -ForegroundColor Red
    exit 1
}

# Step 3: Install to destination
Write-Host "[3/4] Installing to $InstallPath..." -ForegroundColor Cyan
try {
    # Find the extracted folder (GitHub creates a folder like RepoName-Branch)
    $ExtractedFolder = Get-ChildItem -Path $TempExtract -Directory | Select-Object -First 1
    
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
    Copy-Item -Path $ExtractedFolder.FullName -Destination $InstallPath -Recurse -Force
    
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
Remove-Item -Path $TempZip -Force -ErrorAction SilentlyContinue
Remove-Item -Path $TempExtract -Recurse -Force -ErrorAction SilentlyContinue

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

