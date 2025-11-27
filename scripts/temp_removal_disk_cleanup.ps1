# ============================================================
# Temp Removal & Disk Cleanup - Professional Edition
# ============================================================
# 
# Coded by: Soulitek.co.il
# IT Solutions for your business
# 
# (C) 2025 Soulitek - All Rights Reserved
# Website: www.soulitek.co.il
# 
# Professional IT Solutions:
# - Computer Repair & Maintenance
# - Network Setup & Support
# - Software Solutions
# - Business IT Consulting
# 
# This tool removes temporary files and cleans disk space
# for improved system performance and storage optimization.
# 
# Features: Temp File Removal | Disk Cleanup | Browser Cache
#           Recycle Bin Cleanup | Space Recovery Reports
# 
# ============================================================
# 
# IMPORTANT DISCLAIMER:
# This tool is provided "AS IS" without warranty of any kind.
# Use of this tool is at your own risk. The user is solely
# responsible for any outcomes, damages, or issues that may
# arise from using this script. By running this tool, you
# acknowledge and accept full responsibility for its use.
# 
# ============================================================

#Requires -Version 5.1

# Set window title
$Host.UI.RawUI.WindowTitle = "TEMP REMOVAL & DISK CLEANUP"

# Import SouliTEK Common Functions
$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$CommonPath = Join-Path (Split-Path -Parent $ScriptRoot) "modules\SouliTEK-Common.ps1"
if (Test-Path $CommonPath) {
    . $CommonPath
} else {
    Write-Warning "SouliTEK Common Functions not found at: $CommonPath"
    Write-Warning "Some functions may not work properly."
}

# ============================================================
# GLOBAL VARIABLES
# ============================================================

$Script:CleanupResults = @{
    UserTemp = @{ Size = 0; Files = 0; Status = "" }
    SystemTemp = @{ Size = 0; Files = 0; Status = "" }
    RecycleBin = @{ Size = 0; Files = 0; Status = "" }
    BrowserCache = @{ Size = 0; Files = 0; Status = "" }
    WindowsUpdate = @{ Size = 0; Files = 0; Status = "" }
    DiskCleanup = @{ Size = 0; Files = 0; Status = "" }
    TotalSize = 0
    TotalFiles = 0
    StartTime = Get-Date
    EndTime = $null
}

# ============================================================
# HELPER FUNCTIONS
# ============================================================

# Show-Header function removed - using Show-SouliTEKHeader from common module

function Get-FolderSize {
    param(
        [string]$Path,
        [ref]$FileCount
    )
    
    if (-not (Test-Path $Path)) {
        return 0
    }
    
    $size = 0
    $count = 0
    
    try {
        $items = Get-ChildItem -Path $Path -Recurse -File -ErrorAction SilentlyContinue
        foreach ($item in $items) {
            try {
                $size += $item.Length
                $count++
            }
            catch {
                # Skip files that can't be accessed
            }
        }
    }
    catch {
        # Skip folders that can't be accessed
    }
    
    $FileCount.Value = $count
    return $size
}

function Format-FileSize {
    param([long]$Size)
    
    if ($Size -ge 1GB) {
        return "{0:N2} GB" -f ($Size / 1GB)
    }
    elseif ($Size -ge 1MB) {
        return "{0:N2} MB" -f ($Size / 1MB)
    }
    elseif ($Size -ge 1KB) {
        return "{0:N2} KB" -f ($Size / 1KB)
    }
    else {
        return "$Size bytes"
    }
}

function Clear-UserTemp {
    <#
    .SYNOPSIS
        Cleans user temporary files from %TEMP% and %TMP% directories.
    #>
    
    Write-Host "Cleaning User Temp Files..." -ForegroundColor Yellow
    Write-Host "  Scanning user temp directories..." -ForegroundColor Gray
    
    $userTempPaths = @(
        $env:TEMP,
        $env:TMP,
        "$env:USERPROFILE\AppData\Local\Temp"
    )
    
    $totalSize = 0
    $totalFiles = 0
    
    foreach ($tempPath in $userTempPaths) {
        if (Test-Path $tempPath) {
            Write-Host "  Checking: $tempPath" -ForegroundColor Gray
            $fileCount = 0
            $size = Get-FolderSize -Path $tempPath -FileCount ([ref]$fileCount)
            $totalSize += $size
            $totalFiles += $fileCount
            
            if ($size -gt 0) {
                try {
                    Get-ChildItem -Path $tempPath -Recurse -File -ErrorAction SilentlyContinue | 
                        Remove-Item -Force -ErrorAction Stop
                    Write-Host "  [OK] Cleaned: $(Format-FileSize $size)" -ForegroundColor Green
                }
                catch {
                    Write-Host "  [WARNING] Some files could not be deleted: $($_.Exception.Message)" -ForegroundColor Yellow
                }
            }
        }
    }
    
    $Script:CleanupResults.UserTemp.Size = $totalSize
    $Script:CleanupResults.UserTemp.Files = $totalFiles
    $Script:CleanupResults.UserTemp.Status = "Completed"
    
    Write-Host "  User Temp Cleanup: $(Format-FileSize $totalSize) from $totalFiles files" -ForegroundColor Green
    Write-Host ""
}

function Clear-SystemTemp {
    <#
    .SYNOPSIS
        Cleans system temporary files from C:\Windows\Temp.
    #>
    
    Write-Host "Cleaning System Temp Files..." -ForegroundColor Yellow
    Write-Host "  Scanning C:\Windows\Temp..." -ForegroundColor Gray
    
    $systemTempPath = "C:\Windows\Temp"
    $totalSize = 0
    $totalFiles = 0
    
    if (Test-Path $systemTempPath) {
        $fileCount = 0
        $size = Get-FolderSize -Path $systemTempPath -FileCount ([ref]$fileCount)
        $totalSize = $size
        $totalFiles = $fileCount
        
        if ($size -gt 0) {
            try {
                Get-ChildItem -Path $systemTempPath -Recurse -File -ErrorAction SilentlyContinue | 
                    Remove-Item -Force -ErrorAction Stop
                Write-Host "  [OK] Cleaned: $(Format-FileSize $size)" -ForegroundColor Green
            }
            catch {
                Write-Host "  [WARNING] Some files could not be deleted: $($_.Exception.Message)" -ForegroundColor Yellow
            }
        }
    }
    
    $Script:CleanupResults.SystemTemp.Size = $totalSize
    $Script:CleanupResults.SystemTemp.Files = $totalFiles
    $Script:CleanupResults.SystemTemp.Status = "Completed"
    
    Write-Host "  System Temp Cleanup: $(Format-FileSize $totalSize) from $totalFiles files" -ForegroundColor Green
    Write-Host ""
}

function Clear-RecycleBin {
    <#
    .SYNOPSIS
        Cleans the Recycle Bin on all drives.
    #>
    
    Write-Host "Cleaning Recycle Bin..." -ForegroundColor Yellow
    
    $totalSize = 0
    $totalFiles = 0
    
    try {
        $drives = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Used -gt 0 }
        
        foreach ($drive in $drives) {
            $recyclePath = "$($drive.Root)`$Recycle.Bin"
            
            if (Test-Path $recyclePath) {
                $fileCount = 0
                $size = Get-FolderSize -Path $recyclePath -FileCount ([ref]$fileCount)
                
                if ($size -gt 0) {
                    try {
                        Clear-RecycleBin -DriveLetter $drive.Name -Force -ErrorAction SilentlyContinue
                        $totalSize += $size
                        $totalFiles += $fileCount
                        Write-Host "  [OK] Cleaned drive $($drive.Name): $(Format-FileSize $size)" -ForegroundColor Green
                    }
                    catch {
                        # Use alternative method
                        if (Test-Path $recyclePath) {
                            try {
                                Get-ChildItem -Path $recyclePath -Recurse -Force -ErrorAction SilentlyContinue | 
                                    Remove-Item -Force -Recurse -ErrorAction Stop
                                $totalSize += $size
                                $totalFiles += $fileCount
                            } catch {
                                Write-Host "  [WARNING] Could not delete all files: $($_.Exception.Message)" -ForegroundColor Yellow
                            }
                        }
                    }
                }
            }
        }
    }
    catch {
        # Alternative: Use COM object
        try {
            $shell = New-Object -ComObject Shell.Application
            $recycleBin = $shell.NameSpace(0xA)
            $items = $recycleBin.Items()
            
            foreach ($item in $items) {
                $totalSize += $item.Size
                $totalFiles++
            }
            
            if ($totalFiles -gt 0) {
                $recycleBin.InvokeVerb("delete")
            }
        }
        catch {
            Write-Host "  [WARNING] Could not access Recycle Bin" -ForegroundColor Yellow
        }
    }
    
    $Script:CleanupResults.RecycleBin.Size = $totalSize
    $Script:CleanupResults.RecycleBin.Files = $totalFiles
    $Script:CleanupResults.RecycleBin.Status = "Completed"
    
    Write-Host "  Recycle Bin Cleanup: $(Format-FileSize $totalSize) from $totalFiles items" -ForegroundColor Green
    Write-Host ""
}

function Clear-BrowserCache {
    <#
    .SYNOPSIS
        Cleans browser cache files from common browser locations.
    #>
    
    Write-Host "Cleaning Browser Cache..." -ForegroundColor Yellow
    
    $browserPaths = @(
        @{ Name = "Chrome"; Path = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache" },
        @{ Name = "Edge"; Path = "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache" },
        @{ Name = "Firefox"; Path = "$env:LOCALAPPDATA\Mozilla\Firefox\Profiles\*\cache2" },
        @{ Name = "Internet Explorer"; Path = "$env:LOCALAPPDATA\Microsoft\Windows\INetCache" }
    )
    
    $totalSize = 0
    $totalFiles = 0
    
    foreach ($browser in $browserPaths) {
        if ($browser.Path -like "*`*") {
            # Handle wildcard paths
            $paths = Get-ChildItem -Path (Split-Path $browser.Path -Parent) -Directory -ErrorAction SilentlyContinue
            foreach ($path in $paths) {
                $fullPath = Join-Path $path (Split-Path $browser.Path -Leaf)
                if (Test-Path $fullPath) {
                    $fileCount = 0
                    $size = Get-FolderSize -Path $fullPath -FileCount ([ref]$fileCount)
                    
                    if ($size -gt 0) {
                        if (Test-Path $fullPath) {
                            try {
                                Get-ChildItem -Path $fullPath -Recurse -File -ErrorAction SilentlyContinue | 
                                    Remove-Item -Force -ErrorAction Stop
                                $totalSize += $size
                                $totalFiles += $fileCount
                                Write-Host "  [OK] $($browser.Name): $(Format-FileSize $size)" -ForegroundColor Green
                            }
                            catch {
                                Write-Host "  [SKIP] $($browser.Name): Files in use or access denied: $($_.Exception.Message)" -ForegroundColor Yellow
                            }
                        }
                    }
                }
            }
        }
        else {
            if (Test-Path $browser.Path) {
                $fileCount = 0
                $size = Get-FolderSize -Path $browser.Path -FileCount ([ref]$fileCount)
                
                if ($size -gt 0) {
                    try {
                        Get-ChildItem -Path $browser.Path -Recurse -File -ErrorAction SilentlyContinue | 
                            Remove-Item -Force -ErrorAction Stop
                        $totalSize += $size
                        $totalFiles += $fileCount
                        Write-Host "  [OK] $($browser.Name): $(Format-FileSize $size)" -ForegroundColor Green
                    }
                    catch {
                        Write-Host "  [SKIP] $($browser.Name): Files in use or access denied: $($_.Exception.Message)" -ForegroundColor Yellow
                    }
                }
            }
        }
    }
    
    $Script:CleanupResults.BrowserCache.Size = $totalSize
    $Script:CleanupResults.BrowserCache.Files = $totalFiles
    $Script:CleanupResults.BrowserCache.Status = "Completed"
    
    Write-Host "  Browser Cache Cleanup: $(Format-FileSize $totalSize) from $totalFiles files" -ForegroundColor Green
    Write-Host ""
}

function Clear-WindowsUpdate {
    <#
    .SYNOPSIS
        Cleans Windows Update cache and old update files.
    #>
    
    Write-Host "Cleaning Windows Update Cache..." -ForegroundColor Yellow
    Write-Host "  Note: This may take several minutes..." -ForegroundColor Gray
    
    $updatePaths = @(
        "C:\Windows\SoftwareDistribution\Download",
        "C:\Windows\Temp"
    )
    
    $totalSize = 0
    $totalFiles = 0
    
    try {
        # Stop Windows Update service temporarily (graceful shutdown)
        $wuService = Get-Service -Name wuauserv -ErrorAction SilentlyContinue
        if ($wuService -and $wuService.Status -eq 'Running') {
            Write-Host "  Stopping Windows Update service..." -ForegroundColor Gray
            try {
                Stop-Service -Name wuauserv -ErrorAction Stop
                $serviceStopped = $true
                Write-Host "  [OK] Service stopped gracefully" -ForegroundColor Green
            } catch {
                Write-Host "  [WARNING] Graceful stop failed, forcing..." -ForegroundColor Yellow
                Stop-Service -Name wuauserv -Force -ErrorAction Stop
                $serviceStopped = $true
            }
        }
        
        foreach ($path in $updatePaths) {
            if (Test-Path $path) {
                $fileCount = 0
                $size = Get-FolderSize -Path $path -FileCount ([ref]$fileCount)
                
                if ($size -gt 0) {
                    try {
                        Get-ChildItem -Path $path -Recurse -File -ErrorAction SilentlyContinue | 
                            Remove-Item -Force -ErrorAction Stop
                        $totalSize += $size
                        $totalFiles += $fileCount
                    }
                    catch {
                        Write-Host "  [WARNING] Some update files could not be deleted: $($_.Exception.Message)" -ForegroundColor Yellow
                    }
                }
            }
        }
        
        # Restart Windows Update service
        if ($serviceStopped) {
            Write-Host "  Restarting Windows Update service..." -ForegroundColor Gray
            Start-Service -Name wuauserv -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Host "  [WARNING] Windows Update cleanup failed: $_" -ForegroundColor Yellow
    }
    
    $Script:CleanupResults.WindowsUpdate.Size = $totalSize
    $Script:CleanupResults.WindowsUpdate.Files = $totalFiles
    $Script:CleanupResults.WindowsUpdate.Status = "Completed"
    
    Write-Host "  Windows Update Cleanup: $(Format-FileSize $totalSize) from $totalFiles files" -ForegroundColor Green
    Write-Host ""
}

function Invoke-DiskCleanup {
    <#
    .SYNOPSIS
        Runs Windows Disk Cleanup utility.
    #>
    
    Write-Host "Running Windows Disk Cleanup..." -ForegroundColor Yellow
    Write-Host "  Launching cleanmgr.exe..." -ForegroundColor Gray
    
    try {
        # Run Disk Cleanup with automatic cleanup
        $cleanupArgs = "/VERYLOWDISK /D C:"
        Start-Process -FilePath "cleanmgr.exe" -ArgumentList $cleanupArgs -Wait -NoNewWindow -ErrorAction SilentlyContinue
        
        # Alternative: Use Dism for more control
        Write-Host "  Running DISM cleanup..." -ForegroundColor Gray
        Start-Process -FilePath "dism.exe" -ArgumentList "/online /cleanup-image /startcomponentcleanup /resetbase" -Wait -NoNewWindow -ErrorAction SilentlyContinue
        
        $Script:CleanupResults.DiskCleanup.Status = "Completed"
        Write-Host "  [OK] Disk Cleanup completed" -ForegroundColor Green
    }
    catch {
        Write-Host "  [WARNING] Disk Cleanup encountered errors" -ForegroundColor Yellow
        $Script:CleanupResults.DiskCleanup.Status = "Failed"
    }
    
    Write-Host ""
}

function Start-CompleteCleanup {
    <#
    .SYNOPSIS
        Performs a complete cleanup of all temporary files and disk space.
    #>
    
    Show-SouliTEKHeader -Title "COMPLETE CLEANUP IN PROGRESS" -ClearHost -ShowBanner
    
    Write-Host "Starting comprehensive disk cleanup..." -ForegroundColor Cyan
    Write-Host "This may take several minutes depending on system size." -ForegroundColor Gray
    Write-Host ""
    
    $startTime = Get-Date
    
    # Perform all cleanup operations
    Clear-UserTemp
    Clear-SystemTemp
    Clear-RecycleBin
    Clear-BrowserCache
    Clear-WindowsUpdate
    Invoke-DiskCleanup
    
    # Calculate totals
    $Script:CleanupResults.TotalSize = 
        $Script:CleanupResults.UserTemp.Size +
        $Script:CleanupResults.SystemTemp.Size +
        $Script:CleanupResults.RecycleBin.Size +
        $Script:CleanupResults.BrowserCache.Size +
        $Script:CleanupResults.WindowsUpdate.Size
    
    $Script:CleanupResults.TotalFiles = 
        $Script:CleanupResults.UserTemp.Files +
        $Script:CleanupResults.SystemTemp.Files +
        $Script:CleanupResults.RecycleBin.Files +
        $Script:CleanupResults.BrowserCache.Files +
        $Script:CleanupResults.WindowsUpdate.Files
    
    $Script:CleanupResults.EndTime = Get-Date
    $duration = $Script:CleanupResults.EndTime - $startTime
    
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "CLEANUP SUMMARY" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Total Space Recovered: " -NoNewline -ForegroundColor White
    Write-Host "$(Format-FileSize $Script:CleanupResults.TotalSize)" -ForegroundColor Green
    Write-Host "  Total Files Removed: " -NoNewline -ForegroundColor White
    Write-Host "$($Script:CleanupResults.TotalFiles)" -ForegroundColor Green
    Write-Host "  Duration: " -NoNewline -ForegroundColor White
    Write-Host "$([math]::Round($duration.TotalMinutes, 2)) minutes" -ForegroundColor Green
    Write-Host ""
    Write-Host "Breakdown:" -ForegroundColor Cyan
    Write-Host "  - User Temp: $(Format-FileSize $Script:CleanupResults.UserTemp.Size)" -ForegroundColor Gray
    Write-Host "  - System Temp: $(Format-FileSize $Script:CleanupResults.SystemTemp.Size)" -ForegroundColor Gray
    Write-Host "  - Recycle Bin: $(Format-FileSize $Script:CleanupResults.RecycleBin.Size)" -ForegroundColor Gray
    Write-Host "  - Browser Cache: $(Format-FileSize $Script:CleanupResults.BrowserCache.Size)" -ForegroundColor Gray
    Write-Host "  - Windows Update: $(Format-FileSize $Script:CleanupResults.WindowsUpdate.Size)" -ForegroundColor Gray
    Write-Host ""
    
    Write-Host "Press any key to continue..." -ForegroundColor Yellow
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Show-CleanupSummary {
    <#
    .SYNOPSIS
        Displays a summary of the last cleanup operation.
    #>
    
    Show-SouliTEKHeader -Title "CLEANUP SUMMARY" -ClearHost -ShowBanner
    
    if ($Script:CleanupResults.TotalSize -eq 0) {
        Write-Host "No cleanup has been performed yet." -ForegroundColor Yellow
        Write-Host "Please run a cleanup operation first." -ForegroundColor Gray
        Write-Host ""
        Write-Host "Press any key to continue..." -ForegroundColor Yellow
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        return
    }
    
    Write-Host "Last Cleanup Results:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Total Space Recovered: " -NoNewline -ForegroundColor White
    Write-Host "$(Format-FileSize $Script:CleanupResults.TotalSize)" -ForegroundColor Green
    Write-Host "  Total Files Removed: " -NoNewline -ForegroundColor White
    Write-Host "$($Script:CleanupResults.TotalFiles)" -ForegroundColor Green
    
    if ($Script:CleanupResults.StartTime) {
        Write-Host "  Cleanup Date: " -NoNewline -ForegroundColor White
        Write-Host "$($Script:CleanupResults.StartTime.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Green
    }
    
    Write-Host ""
    Write-Host "Breakdown by Category:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  User Temp Files:" -ForegroundColor Yellow
    Write-Host "    Size: $(Format-FileSize $Script:CleanupResults.UserTemp.Size)" -ForegroundColor Gray
    Write-Host "    Files: $($Script:CleanupResults.UserTemp.Files)" -ForegroundColor Gray
    Write-Host "    Status: $($Script:CleanupResults.UserTemp.Status)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  System Temp Files:" -ForegroundColor Yellow
    Write-Host "    Size: $(Format-FileSize $Script:CleanupResults.SystemTemp.Size)" -ForegroundColor Gray
    Write-Host "    Files: $($Script:CleanupResults.SystemTemp.Files)" -ForegroundColor Gray
    Write-Host "    Status: $($Script:CleanupResults.SystemTemp.Status)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  Recycle Bin:" -ForegroundColor Yellow
    Write-Host "    Size: $(Format-FileSize $Script:CleanupResults.RecycleBin.Size)" -ForegroundColor Gray
    Write-Host "    Files: $($Script:CleanupResults.RecycleBin.Files)" -ForegroundColor Gray
    Write-Host "    Status: $($Script:CleanupResults.RecycleBin.Status)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  Browser Cache:" -ForegroundColor Yellow
    Write-Host "    Size: $(Format-FileSize $Script:CleanupResults.BrowserCache.Size)" -ForegroundColor Gray
    Write-Host "    Files: $($Script:CleanupResults.BrowserCache.Files)" -ForegroundColor Gray
    Write-Host "    Status: $($Script:CleanupResults.BrowserCache.Status)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  Windows Update Cache:" -ForegroundColor Yellow
    Write-Host "    Size: $(Format-FileSize $Script:CleanupResults.WindowsUpdate.Size)" -ForegroundColor Gray
    Write-Host "    Files: $($Script:CleanupResults.WindowsUpdate.Files)" -ForegroundColor Gray
    Write-Host "    Status: $($Script:CleanupResults.WindowsUpdate.Status)" -ForegroundColor Gray
    Write-Host ""
    
    Write-Host "Press any key to continue..." -ForegroundColor Yellow
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Export-CleanupReport {
    <#
    .SYNOPSIS
        Exports cleanup results to a report file.
    #>
    
    Show-SouliTEKHeader -Title "EXPORT CLEANUP REPORT" -ClearHost -ShowBanner
    
    if ($Script:CleanupResults.TotalSize -eq 0) {
        Write-Host "No cleanup data to export." -ForegroundColor Yellow
        Write-Host "Please run a cleanup operation first." -ForegroundColor Gray
        Write-Host ""
        Write-Host "Press any key to continue..." -ForegroundColor Yellow
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        return
    }
    
    $desktopPath = [Environment]::GetFolderPath("Desktop")
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $baseFileName = "Disk_Cleanup_Report_$timestamp"
    
    Write-Host "Exporting cleanup report..." -ForegroundColor Yellow
    Write-Host ""
    
    # TXT Export
    $txtPath = Join-Path $desktopPath "$baseFileName.txt"
    $txtContent = @"
============================================================
TEMP REMOVAL & DISK CLEANUP REPORT
============================================================

Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
Tool: SouliTEK Temp Removal & Disk Cleanup
Website: www.soulitek.co.il

============================================================
SUMMARY
============================================================

Total Space Recovered: $(Format-FileSize $Script:CleanupResults.TotalSize)
Total Files Removed: $($Script:CleanupResults.TotalFiles)
Cleanup Duration: $(if ($Script:CleanupResults.EndTime) { "$([math]::Round(($Script:CleanupResults.EndTime - $Script:CleanupResults.StartTime).TotalMinutes, 2)) minutes" } else { "N/A" })

============================================================
DETAILED BREAKDOWN
============================================================

User Temp Files:
  Size: $(Format-FileSize $Script:CleanupResults.UserTemp.Size)
  Files: $($Script:CleanupResults.UserTemp.Files)
  Status: $($Script:CleanupResults.UserTemp.Status)

System Temp Files:
  Size: $(Format-FileSize $Script:CleanupResults.SystemTemp.Size)
  Files: $($Script:CleanupResults.SystemTemp.Files)
  Status: $($Script:CleanupResults.SystemTemp.Status)

Recycle Bin:
  Size: $(Format-FileSize $Script:CleanupResults.RecycleBin.Size)
  Files: $($Script:CleanupResults.RecycleBin.Files)
  Status: $($Script:CleanupResults.RecycleBin.Status)

Browser Cache:
  Size: $(Format-FileSize $Script:CleanupResults.BrowserCache.Size)
  Files: $($Script:CleanupResults.BrowserCache.Files)
  Status: $($Script:CleanupResults.BrowserCache.Status)

Windows Update Cache:
  Size: $(Format-FileSize $Script:CleanupResults.WindowsUpdate.Size)
  Files: $($Script:CleanupResults.WindowsUpdate.Files)
  Status: $($Script:CleanupResults.WindowsUpdate.Status)

Disk Cleanup:
  Status: $($Script:CleanupResults.DiskCleanup.Status)

============================================================
END OF REPORT
============================================================
"@
    
    $txtContent | Out-File -FilePath $txtPath -Encoding UTF8
    Write-Host "  [OK] Text report saved: $txtPath" -ForegroundColor Green
    
    # CSV Export
    $csvPath = Join-Path $desktopPath "$baseFileName.csv"
    $csvData = @(
        [PSCustomObject]@{
            Category = "User Temp Files"
            Size_Bytes = $Script:CleanupResults.UserTemp.Size
            Size_Formatted = Format-FileSize $Script:CleanupResults.UserTemp.Size
            Files_Count = $Script:CleanupResults.UserTemp.Files
            Status = $Script:CleanupResults.UserTemp.Status
        },
        [PSCustomObject]@{
            Category = "System Temp Files"
            Size_Bytes = $Script:CleanupResults.SystemTemp.Size
            Size_Formatted = Format-FileSize $Script:CleanupResults.SystemTemp.Size
            Files_Count = $Script:CleanupResults.SystemTemp.Files
            Status = $Script:CleanupResults.SystemTemp.Status
        },
        [PSCustomObject]@{
            Category = "Recycle Bin"
            Size_Bytes = $Script:CleanupResults.RecycleBin.Size
            Size_Formatted = Format-FileSize $Script:CleanupResults.RecycleBin.Size
            Files_Count = $Script:CleanupResults.RecycleBin.Files
            Status = $Script:CleanupResults.RecycleBin.Status
        },
        [PSCustomObject]@{
            Category = "Browser Cache"
            Size_Bytes = $Script:CleanupResults.BrowserCache.Size
            Size_Formatted = Format-FileSize $Script:CleanupResults.BrowserCache.Size
            Files_Count = $Script:CleanupResults.BrowserCache.Files
            Status = $Script:CleanupResults.BrowserCache.Status
        },
        [PSCustomObject]@{
            Category = "Windows Update Cache"
            Size_Bytes = $Script:CleanupResults.WindowsUpdate.Size
            Size_Formatted = Format-FileSize $Script:CleanupResults.WindowsUpdate.Size
            Files_Count = $Script:CleanupResults.WindowsUpdate.Files
            Status = $Script:CleanupResults.WindowsUpdate.Status
        },
        [PSCustomObject]@{
            Category = "TOTAL"
            Size_Bytes = $Script:CleanupResults.TotalSize
            Size_Formatted = Format-FileSize $Script:CleanupResults.TotalSize
            Files_Count = $Script:CleanupResults.TotalFiles
            Status = "Completed"
        }
    )
    
    $csvData | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
    Write-Host "  [OK] CSV report saved: $csvPath" -ForegroundColor Green
    
    # HTML Export
    $htmlPath = Join-Path $desktopPath "$baseFileName.html"
    $htmlContent = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Disk Cleanup Report - SouliTEK</title>
    <style>
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin: 20px; background: #f5f5f5; }
        .container { max-width: 1200px; margin: 0 auto; background: white; padding: 30px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        h1 { color: #667eea; border-bottom: 3px solid #667eea; padding-bottom: 10px; }
        h2 { color: #764ba2; margin-top: 30px; }
        .summary { background: #f8f9fa; padding: 20px; border-radius: 5px; margin: 20px 0; }
        .summary-item { display: flex; justify-content: space-between; padding: 10px 0; border-bottom: 1px solid #dee2e6; }
        .summary-item:last-child { border-bottom: none; }
        .summary-label { font-weight: bold; color: #495057; }
        .summary-value { color: #28a745; font-weight: bold; }
        table { width: 100%; border-collapse: collapse; margin: 20px 0; }
        th { background: #667eea; color: white; padding: 12px; text-align: left; }
        td { padding: 10px; border-bottom: 1px solid #dee2e6; }
        tr:hover { background: #f8f9fa; }
        .status-ok { color: #28a745; font-weight: bold; }
        .footer { margin-top: 30px; padding-top: 20px; border-top: 1px solid #dee2e6; color: #6c757d; text-align: center; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Disk Cleanup Report</h1>
        <p><strong>Generated:</strong> $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>
        <p><strong>Tool:</strong> SouliTEK Temp Removal & Disk Cleanup</p>
        <p><strong>Website:</strong> <a href="https://www.soulitek.co.il">www.soulitek.co.il</a></p>
        
        <div class="summary">
            <h2>Summary</h2>
            <div class="summary-item">
                <span class="summary-label">Total Space Recovered:</span>
                <span class="summary-value">$(Format-FileSize $Script:CleanupResults.TotalSize)</span>
            </div>
            <div class="summary-item">
                <span class="summary-label">Total Files Removed:</span>
                <span class="summary-value">$($Script:CleanupResults.TotalFiles)</span>
            </div>
            <div class="summary-item">
                <span class="summary-label">Cleanup Duration:</span>
                <span class="summary-value">$(if ($Script:CleanupResults.EndTime) { "$([math]::Round(($Script:CleanupResults.EndTime - $Script:CleanupResults.StartTime).TotalMinutes, 2)) minutes" } else { "N/A" })</span>
            </div>
        </div>
        
        <h2>Detailed Breakdown</h2>
        <table>
            <thead>
                <tr>
                    <th>Category</th>
                    <th>Size</th>
                    <th>Files Removed</th>
                    <th>Status</th>
                </tr>
            </thead>
            <tbody>
                <tr>
                    <td>User Temp Files</td>
                    <td>$(Format-FileSize $Script:CleanupResults.UserTemp.Size)</td>
                    <td>$($Script:CleanupResults.UserTemp.Files)</td>
                    <td class="status-ok">$($Script:CleanupResults.UserTemp.Status)</td>
                </tr>
                <tr>
                    <td>System Temp Files</td>
                    <td>$(Format-FileSize $Script:CleanupResults.SystemTemp.Size)</td>
                    <td>$($Script:CleanupResults.SystemTemp.Files)</td>
                    <td class="status-ok">$($Script:CleanupResults.SystemTemp.Status)</td>
                </tr>
                <tr>
                    <td>Recycle Bin</td>
                    <td>$(Format-FileSize $Script:CleanupResults.RecycleBin.Size)</td>
                    <td>$($Script:CleanupResults.RecycleBin.Files)</td>
                    <td class="status-ok">$($Script:CleanupResults.RecycleBin.Status)</td>
                </tr>
                <tr>
                    <td>Browser Cache</td>
                    <td>$(Format-FileSize $Script:CleanupResults.BrowserCache.Size)</td>
                    <td>$($Script:CleanupResults.BrowserCache.Files)</td>
                    <td class="status-ok">$($Script:CleanupResults.BrowserCache.Status)</td>
                </tr>
                <tr>
                    <td>Windows Update Cache</td>
                    <td>$(Format-FileSize $Script:CleanupResults.WindowsUpdate.Size)</td>
                    <td>$($Script:CleanupResults.WindowsUpdate.Files)</td>
                    <td class="status-ok">$($Script:CleanupResults.WindowsUpdate.Status)</td>
                </tr>
            </tbody>
        </table>
        
        <div class="footer">
            <p>(C) 2025 SouliTEK - All Rights Reserved</p>
            <p>Professional IT Solutions: www.soulitek.co.il</p>
        </div>
    </div>
</body>
</html>
"@
    
    $htmlContent | Out-File -FilePath $htmlPath -Encoding UTF8
    Write-Host "  [OK] HTML report saved: $htmlPath" -ForegroundColor Green
    
    Write-Host ""
    Write-Host "All reports exported successfully!" -ForegroundColor Green
    Write-Host ""
    
    # Open reports
    try {
        Start-Process $txtPath
        Start-Process $csvPath
        Start-Process $htmlPath
    }
    catch {
        Write-Host "Reports saved to Desktop. Open them manually if needed." -ForegroundColor Yellow
    }
    
    Write-Host "Press any key to continue..." -ForegroundColor Yellow
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Show-Help {
    <#
    .SYNOPSIS
        Displays help information for the tool.
    #>
    
    Show-SouliTEKHeader -Title "HELP & INFORMATION" -ClearHost -ShowBanner
    
    $helpText = @"
TEMP REMOVAL & DISK CLEANUP TOOL
============================================================

This tool helps you free up disk space by removing temporary
files, cleaning browser caches, emptying the Recycle Bin, and
running Windows Disk Cleanup.

FEATURES:
---------
1. Complete Cleanup - Performs all cleanup operations
2. User Temp Files - Cleans %TEMP% and %TMP% directories
3. System Temp Files - Cleans C:\Windows\Temp
4. Recycle Bin - Empties Recycle Bin on all drives
5. Browser Cache - Cleans Chrome, Edge, Firefox, IE cache
6. Windows Update - Cleans Windows Update cache
7. Disk Cleanup - Runs Windows Disk Cleanup utility

CLEANUP OPERATIONS:
-------------------
- User Temp Files: Removes temporary files from user profile
- System Temp Files: Removes system-wide temporary files
- Recycle Bin: Empties all Recycle Bins on all drives
- Browser Cache: Cleans cache from installed browsers
- Windows Update: Removes old update files and cache
- Disk Cleanup: Runs Windows built-in cleanup utility

REPORTING:
----------
- View Summary: Shows cleanup results and statistics
- Export Report: Saves reports in TXT, CSV, and HTML formats
- Reports are saved to Desktop with timestamp

IMPORTANT NOTES:
---------------
- Administrator privileges recommended for full functionality
- Some files may be in use and cannot be deleted
- Browser cache cleanup requires browsers to be closed
- Windows Update cleanup may take several minutes
- Always backup important data before cleanup

REQUIREMENTS:
-------------
- Windows 10/11
- PowerShell 5.1 or later
- Administrator privileges (recommended)

SUPPORT:
--------
Website: www.soulitek.co.il
Email: letstalk@soulitek.co.il

(C) 2025 SouliTEK - All Rights Reserved
"@
    
    Write-Host $helpText
    Write-Host ""
    Write-Host "Press any key to continue..." -ForegroundColor Yellow
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# ============================================================
# EXIT MESSAGE
# ============================================================

# Show-ExitMessage function - using Show-SouliTEKExitMessage from common module
function Show-ExitMessage {
    Show-SouliTEKExitMessage -ScriptPath $PSCommandPath -ToolName "SouliTEK Temp Removal & Disk Cleanup"
}

function Show-MainMenu {
    <#
    .SYNOPSIS
        Displays the main menu and handles user input.
    #>
    
    do {
        Show-SouliTEKHeader -Title "MAIN MENU" -ClearHost -ShowBanner
        
        Write-Host "Please select an option:" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "  1. Complete Cleanup (All Operations)" -ForegroundColor White
        Write-Host "  2. Clean User Temp Files Only" -ForegroundColor White
        Write-Host "  3. Clean System Temp Files Only" -ForegroundColor White
        Write-Host "  4. Empty Recycle Bin" -ForegroundColor White
        Write-Host "  5. Clean Browser Cache" -ForegroundColor White
        Write-Host "  6. Clean Windows Update Cache" -ForegroundColor White
        Write-Host "  7. Run Windows Disk Cleanup" -ForegroundColor White
        Write-Host "  8. View Cleanup Summary" -ForegroundColor White
        Write-Host "  9. Export Cleanup Report" -ForegroundColor White
        Write-Host "  10. Help & Information" -ForegroundColor White
        Write-Host "  0. Exit" -ForegroundColor White
        Write-Host ""
        Write-Host "============================================================" -ForegroundColor Cyan
        Write-Host ""
        
        $choice = Read-Host "Enter your choice (0-10)"
        Write-Host ""
        
        switch ($choice) {
            "1" {
                Start-CompleteCleanup
            }
            "2" {
                Show-SouliTEKHeader -Title "CLEAN USER TEMP FILES" -ClearHost -ShowBanner
                Clear-UserTemp
                Write-Host "Press any key to continue..." -ForegroundColor Yellow
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
            "3" {
                Show-SouliTEKHeader -Title "CLEAN SYSTEM TEMP FILES" -ClearHost -ShowBanner
                Clear-SystemTemp
                Write-Host "Press any key to continue..." -ForegroundColor Yellow
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
            "4" {
                Show-SouliTEKHeader -Title "EMPTY RECYCLE BIN" -ClearHost -ShowBanner
                Clear-RecycleBin
                Write-Host "Press any key to continue..." -ForegroundColor Yellow
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
            "5" {
                Show-SouliTEKHeader -Title "CLEAN BROWSER CACHE" -ClearHost -ShowBanner
                Clear-BrowserCache
                Write-Host "Press any key to continue..." -ForegroundColor Yellow
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
            "6" {
                Show-SouliTEKHeader -Title "CLEAN WINDOWS UPDATE CACHE" -ClearHost -ShowBanner
                Clear-WindowsUpdate
                Write-Host "Press any key to continue..." -ForegroundColor Yellow
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
            "7" {
                Show-SouliTEKHeader -Title "WINDOWS DISK CLEANUP" -ClearHost -ShowBanner
                Invoke-DiskCleanup
                Write-Host "Press any key to continue..." -ForegroundColor Yellow
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
            "8" {
                Show-CleanupSummary
            }
            "9" {
                Export-CleanupReport
            }
            "10" {
                Show-Help
            }
            "0" {
                Show-ExitMessage
                return
            }
            default {
                Write-Host "Invalid choice. Please enter a number between 0 and 10." -ForegroundColor Red
                Start-Sleep -Seconds 2
            }
        }
    } while ($true)
}

# ============================================================
# MAIN EXECUTION
# ============================================================

# Check for administrator privileges
if (-not (Test-Administrator)) {
    Write-Host "Warning: Administrator privileges recommended for full functionality." -ForegroundColor Yellow
    Write-Host "Some cleanup operations may not work without admin rights." -ForegroundColor Yellow
    Write-Host ""
    Start-Sleep -Seconds 2
}

# Start the main menu
Show-MainMenu
