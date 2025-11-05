# ============================================================
# SouliTEK All-In-One Scripts - Quick Installer
# ============================================================
# 
# One-line installation from URL:
#   iwr -useb get.soulitek.co.il | iex
# 
# Or direct GitHub:
#   iwr -useb https://raw.githubusercontent.com/Soulitek/Soulitek-All-In-One-Scripts/main/Install-SouliTEK.ps1 | iex
#
# ============================================================

#Requires -Version 5.1

[CmdletBinding()]
param(
    [string]$InstallPath = "C:\SouliTEK",
    [string]$RepoOwner = "Soulitek",
    [string]$RepoName = "Soulitek-All-In-One-Scripts",
    [string]$Branch = "main",
    [switch]$Silent
)

# Set error action preference
$ErrorActionPreference = "Stop"

# Function to write colored output
function Write-Step {
    param([string]$Message, [string]$Color = "Cyan")
    Write-Host "`n[$Message]" -ForegroundColor $Color
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

# Banner
Clear-Host
Write-Host @"

============================================================
    SouliTEK All-In-One Scripts - Quick Installer
============================================================
    Professional PowerShell Tools for IT Technicians
    Website: www.soulitek.co.il
    Email: letstalk@soulitek.co.il
============================================================

"@ -ForegroundColor Cyan

# Check if running as administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Warning-Custom "Not running as Administrator. Some tools may require admin privileges."
    Write-Host ""
}

# GitHub repository information
$githubZipUrl = "https://github.com/$RepoOwner/$RepoName/archive/refs/heads/$Branch.zip"
$tempDir = Join-Path $env:TEMP "SouliTEK-Install"
$zipFile = Join-Path $tempDir "SouliTEK.zip"
$extractPath = Join-Path $tempDir "Extract"

try {
    # Step 1: Create temporary directory
    Write-Step "Step 1: Preparing temporary directory"
    if (Test-Path $tempDir) {
        Remove-Item $tempDir -Recurse -Force
    }
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
    New-Item -ItemType Directory -Path $extractPath -Force | Out-Null
    Write-Success "Temporary directory created: $tempDir"

    # Step 2: Download from GitHub
    Write-Step "Step 2: Downloading latest version from GitHub"
    Write-Host "Source: $githubZipUrl" -ForegroundColor Gray
    
    # Ensure TLS 1.2
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    
    # Download with progress
    $ProgressPreference = 'SilentlyContinue'
    try {
        Invoke-WebRequest -Uri $githubZipUrl -OutFile $zipFile -UseBasicParsing -ErrorAction Stop
        Write-Success "Download completed: $([math]::Round((Get-Item $zipFile).Length / 1MB, 2)) MB"
    }
    catch {
        Write-Error-Custom "Failed to download from GitHub: $($_.Exception.Message)"
        Write-Host ""
        Write-Host "Please check your internet connection and try again." -ForegroundColor Yellow
        Write-Host "GitHub URL: $githubZipUrl" -ForegroundColor Gray
        exit 1
    }

    # Step 3: Extract ZIP file
    Write-Step "Step 3: Extracting files"
    try {
        Expand-Archive -Path $zipFile -DestinationPath $extractPath -Force
        Write-Success "Files extracted successfully"
    }
    catch {
        Write-Error-Custom "Failed to extract ZIP file: $($_.Exception.Message)"
        exit 1
    }

    # Step 4: Find the extracted folder (GitHub ZIPs contain folder with branch name)
    $extractedFolder = Get-ChildItem -Path $extractPath -Directory | Select-Object -First 1
    if (-not $extractedFolder) {
        Write-Error-Custom "Extracted folder not found in ZIP file"
        exit 1
    }
    $sourcePath = $extractedFolder.FullName

    # Step 5: Remove old installation if exists
    Write-Step "Step 4: Checking for existing installation"
    if (Test-Path $InstallPath) {
        Write-Warning-Custom "Existing installation found at: $InstallPath"
        Write-Host "Removing old installation..." -ForegroundColor Yellow
        try {
            Remove-Item $InstallPath -Recurse -Force
            Write-Success "Old installation removed"
        }
        catch {
            Write-Error-Custom "Failed to remove old installation: $($_.Exception.Message)"
            Write-Host "Please close any open files in $InstallPath and try again." -ForegroundColor Yellow
            exit 1
        }
    }

    # Step 6: Copy files to installation directory
    Write-Step "Step 5: Installing to $InstallPath"
    try {
        Copy-Item -Path $sourcePath -Destination $InstallPath -Recurse -Force
        Write-Success "Installation completed successfully"
    }
    catch {
        Write-Error-Custom "Failed to copy files: $($_.Exception.Message)"
        exit 1
    }

    # Step 7: Create desktop shortcut
    Write-Step "Step 6: Creating desktop shortcut"
    $desktopPath = [Environment]::GetFolderPath("Desktop")
    $shortcutPath = Join-Path $desktopPath "SouliTEK Launcher.lnk"
    $launcherPath = Join-Path $InstallPath "SouliTEK-Launcher.ps1"
    
    try {
        $WshShell = New-Object -ComObject WScript.Shell
        $Shortcut = $WshShell.CreateShortcut($shortcutPath)
        $Shortcut.TargetPath = "powershell.exe"
        $Shortcut.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$launcherPath`""
        $Shortcut.WorkingDirectory = $InstallPath
        $Shortcut.Description = "SouliTEK All-In-One Scripts Launcher"
        $Shortcut.Save()
        Write-Success "Desktop shortcut created"
    }
    catch {
        Write-Warning-Custom "Failed to create desktop shortcut: $($_.Exception.Message)"
        Write-Host "You can still launch from: $launcherPath" -ForegroundColor Yellow
    }

    # Step 8: Cleanup temporary files
    Write-Step "Step 7: Cleaning up temporary files"
    try {
        Remove-Item $tempDir -Recurse -Force
        Write-Success "Temporary files removed"
    }
    catch {
        Write-Warning-Custom "Failed to remove some temporary files (not critical)"
    }

    # Installation complete
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Green
    Write-Host "    Installation Completed Successfully!" -ForegroundColor Green
    Write-Host "============================================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Installation Path: $InstallPath" -ForegroundColor Cyan
    Write-Host "Launcher: $launcherPath" -ForegroundColor Cyan
    Write-Host ""
    
    # Ask if user wants to launch
    if (-not $Silent) {
        $launch = Read-Host "Would you like to launch SouliTEK Launcher now? (Y/N)"
        if ($launch -eq 'Y' -or $launch -eq 'y') {
            Write-Host ""
            Write-Step "Launching SouliTEK Launcher..."
            Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$launcherPath`"" -WorkingDirectory $InstallPath
            Write-Success "Launcher started!"
        }
    }

    Write-Host ""
    Write-Host "Thank you for using SouliTEK!" -ForegroundColor Cyan
    Write-Host "Website: www.soulitek.co.il | Email: letstalk@soulitek.co.il" -ForegroundColor Gray
    Write-Host ""

}
catch {
    Write-Error-Custom "An unexpected error occurred: $($_.Exception.Message)"
    Write-Host ""
    Write-Host "Error details:" -ForegroundColor Yellow
    Write-Host $_.Exception -ForegroundColor Red
    Write-Host ""
    Write-Host "For support, contact: letstalk@soulitek.co.il" -ForegroundColor Cyan
    
    # Cleanup on error
    if (Test-Path $tempDir) {
        try {
            Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
        }
        catch {
            # Ignore cleanup errors
        }
    }
    
    exit 1
}

