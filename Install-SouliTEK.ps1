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

# ============================================================
# FILE FILTERING FUNCTIONS
# ============================================================

function Get-EssentialFilesFilter {
    <#
    .SYNOPSIS
    Returns array of file patterns that should be included in the minimal download.
    #>
    return @(
        "SouliTEK-Launcher.ps1",
        "LICENSE",
        "launcher\*",
        "modules\*.ps1",
        "scripts\*.ps1",
        "assets\images\Favicon.png",
        "assets\images\Logo.png",
        "tools\MCPR.exe",
        "tools\whois.exe"
    )
}

function Test-FileIsEssential {
    <#
    .SYNOPSIS
    Checks if a file path matches any of the essential file patterns.
    
    .PARAMETER FilePath
    The relative file path from the repository root (e.g., "scripts\test.ps1")
    
    .PARAMETER Whitelist
    Array of file patterns to match against
    
    .EXAMPLE
    Test-FileIsEssential -FilePath "scripts\test.ps1" -Whitelist $whitelist
    #>
    param(
        [string]$FilePath,
        [string[]]$Whitelist
    )
    
    # Normalize path separators (handle both \ and /)
    $normalizedPath = $FilePath -replace '/', '\'
    
    foreach ($pattern in $Whitelist) {
        $normalizedPattern = $pattern -replace '/', '\'
        
        # Exact match
        if ($normalizedPath -eq $normalizedPattern) {
            return $true
        }
        
        # Directory wildcard pattern (e.g., "launcher\*" matches "launcher\file.xaml")
        if ($normalizedPattern.EndsWith('\*')) {
            $dirPattern = $normalizedPattern.TrimEnd('\*')
            if ($normalizedPath.StartsWith($dirPattern + '\')) {
                return $true
            }
        }
        
        # File extension wildcard pattern (e.g., "modules\*.ps1" matches "modules\file.ps1")
        if ($normalizedPattern -like '*\*.*') {
            # Split pattern into directory and file pattern
            $patternParts = $normalizedPattern -split '\\', 2
            if ($patternParts.Count -eq 2) {
                $patternDir = $patternParts[0]
                $patternFile = $patternParts[1]
                
                # Check if directory matches (with backslash)
                $dirPrefix = $patternDir + '\'
                if ($normalizedPath.StartsWith($dirPrefix)) {
                    # Get the filename part (everything after directory\)
                    $filePart = $normalizedPath.Substring($dirPrefix.Length)
                    # Use -like for wildcard matching
                    if ($filePart -like $patternFile) {
                        return $true
                    }
                }
                # Also check exact directory match (file is directly in the directory)
                if ($normalizedPath -eq ($patternDir + '\' + $patternFile.Replace('*', ''))) {
                    return $true
                }
            }
        }
        
        # Additional check: if pattern is just a directory with wildcard, match any file in that directory
        # This handles cases where the pattern might not match due to path separator issues
        if ($normalizedPattern -like '*\*' -and -not $normalizedPattern.Contains('.')) {
            $dirPattern = $normalizedPattern.TrimEnd('\*')
            if ($normalizedPath.StartsWith($dirPattern + '\')) {
                return $true
            }
        }
    }
    
    return $false
}

function Copy-EssentialFiles {
    <#
    .SYNOPSIS
    Copies only essential files from source to destination, maintaining folder structure.
    
    .PARAMETER SourcePath
    Source directory containing extracted files
    
    .PARAMETER DestinationPath
    Destination directory for installation
    
    .PARAMETER Whitelist
    Array of file patterns to include
    #>
    param(
        [string]$SourcePath,
        [string]$DestinationPath,
        [string[]]$Whitelist
    )
    
    # Normalize source path (remove trailing backslash if present)
    $SourcePath = $SourcePath.TrimEnd('\', '/')
    
    # Get all files recursively
    $allFiles = Get-ChildItem -Path $SourcePath -Recurse -File
    
    $copiedCount = 0
    $skippedCount = 0
    
    foreach ($file in $allFiles) {
        # Get relative path from source using Resolve-Path for accurate calculation
        $relativePath = $file.FullName.Substring($SourcePath.Length + 1)
        
        # Normalize path separators
        $relativePath = $relativePath -replace '/', '\'
        
        # Check if file is essential
        $isEssential = $false
        
        # Primary check: pattern matching
        if (Test-FileIsEssential -FilePath $relativePath -Whitelist $Whitelist) {
            $isEssential = $true
        }
        # Fallback: explicitly include all .ps1 files in scripts folder
        elseif ($relativePath -like 'scripts\*.ps1' -or $relativePath -like 'scripts/*.ps1') {
            $isEssential = $true
        }
        # Fallback: explicitly include all .ps1 files in modules folder
        elseif ($relativePath -like 'modules\*.ps1' -or $relativePath -like 'modules/*.ps1') {
            $isEssential = $true
        }
        # Fallback: explicitly include all files in launcher folder
        elseif ($relativePath.StartsWith('launcher\') -or $relativePath.StartsWith('launcher/')) {
            $isEssential = $true
        }
        
        if ($isEssential) {
            $destinationFile = Join-Path $DestinationPath $relativePath
            $destinationDir = Split-Path $destinationFile -Parent
            
            # Create destination directory if it doesn't exist
            if (-not (Test-Path $destinationDir)) {
                New-Item -ItemType Directory -Path $destinationDir -Force | Out-Null
            }
            
            # Copy file
            Copy-Item -Path $file.FullName -Destination $destinationFile -Force
            $copiedCount++
        } else {
            $skippedCount++
        }
    }
    
    # Ensure essential folders exist even if empty
    $essentialFolders = @(
        "launcher",
        "modules",
        "scripts",
        "assets\images",
        "tools"
    )
    
    foreach ($folder in $essentialFolders) {
        $folderPath = Join-Path $DestinationPath $folder
        if (-not (Test-Path $folderPath)) {
            New-Item -ItemType Directory -Path $folderPath -Force | Out-Null
        }
    }
    
    return @{
        Copied = $copiedCount
        Skipped = $skippedCount
    }
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

    # Step 6: Copy only essential files to installation directory
    Write-Step "Step 5: Installing essential files to $InstallPath"
    try {
        # Get whitelist of essential files
        $whitelist = Get-EssentialFilesFilter
        
        # Create installation directory
        if (-not (Test-Path $InstallPath)) {
            New-Item -ItemType Directory -Path $InstallPath -Force | Out-Null
        }
        
        # Copy only essential files
        $copyResult = Copy-EssentialFiles -SourcePath $sourcePath -DestinationPath $InstallPath -Whitelist $whitelist
        
        Write-Success "Installation completed successfully"
        Write-Host "  Files copied: $($copyResult.Copied)" -ForegroundColor Gray
        Write-Host "  Files skipped: $($copyResult.Skipped)" -ForegroundColor Gray
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

