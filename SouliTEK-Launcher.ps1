# ============================================================
# SouliTEK All-In-One Scripts - Launcher Wrapper
# ============================================================
# 
# This is a convenience wrapper that launches the main GUI
# from the project root directory.
# 
# The actual launcher is located in: ./launcher/SouliTEK-Launcher.ps1
# 
# ============================================================

#Requires -Version 5.1

# Get the script directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Path to the actual launcher
$LauncherPath = Join-Path $ScriptDir "launcher\SouliTEK-Launcher.ps1"

# Check if launcher exists
if (-not (Test-Path $LauncherPath)) {
    Write-Host "ERROR: Launcher not found at: $LauncherPath" -ForegroundColor Red
    Write-Host "Please ensure the project structure is intact." -ForegroundColor Yellow
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit 1
}

# Launch the main GUI
Write-Host "Starting SouliTEK All-In-One Scripts Launcher..." -ForegroundColor Cyan
& $LauncherPath
