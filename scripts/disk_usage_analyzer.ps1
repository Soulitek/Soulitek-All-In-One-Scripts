# ============================================================
# Disk Usage Analyzer - Professional Edition
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
# This tool analyzes disk usage and finds large folders
# for storage optimization and cleanup.
# 
# Features: Large Folder Detection | Size Analysis | Export Results
#           HTML Visualization | Storage Recommendations
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
$Host.UI.RawUI.WindowTitle = "DISK USAGE ANALYZER"

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

$Script:FolderData = @()
$Script:OutputFolder = Join-Path $env:USERPROFILE "Desktop"
$Script:MinSizeGB = 1.0
$Script:ScanPath = ""
$Script:TopFoldersCount = 10

# ============================================================
# HELPER FUNCTIONS
# ============================================================

function Show-Header {
    param([string]$Title = "DISK USAGE ANALYZER", [ConsoleColor]$Color = 'Cyan')
    
    Clear-Host
    Show-SouliTEKBanner
    Write-Host "============================================================" -ForegroundColor $Color
    Write-Host ""
    Write-Host "  $Title" -ForegroundColor $Color
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor $Color
    Write-Host ""
}

function Format-FileSize {
    param([long]$SizeInBytes)
    
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

function Get-FolderSize {
    param([string]$FolderPath)
    
    try {
        $size = (Get-ChildItem -Path $FolderPath -Recurse -ErrorAction SilentlyContinue -Force | 
                 Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
        
        if ($null -eq $size) {
            return 0
        }
        return $size
    }
    catch {
        return 0
    }
}

function Get-LargeFolders {
    param(
        [string]$Path,
        [double]$MinSizeGB
    )
    
    Show-Header "SCANNING FOR LARGE FOLDERS" -Color Yellow
    
    Write-Host "Scanning path: " -NoNewline -ForegroundColor Cyan
    Write-Host $Path -ForegroundColor White
    Write-Host "Minimum size threshold: " -NoNewline -ForegroundColor Cyan
    Write-Host "$MinSizeGB GB" -ForegroundColor White
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    
    Write-SouliTEKResult "Scanning folders (this may take a while)..." -Level INFO
    Write-Host ""
    
    $minSizeBytes = $MinSizeGB * 1GB
    $largeFolders = @()
    $scannedCount = 0
    $foundCount = 0
    
    try {
        if (-not (Test-Path $Path)) {
            Write-SouliTEKResult "Path not found: $Path" -Level ERROR
            Read-Host "Press Enter to return to main menu"
            return @()
        }
        
        Write-Host "Enumerating directories..." -ForegroundColor Yellow
        $allFolders = Get-ChildItem -Path $Path -Directory -ErrorAction SilentlyContinue -Force -Recurse
        
        Write-Host "Found $($allFolders.Count) directories to scan" -ForegroundColor Gray
        Write-Host ""
        
        $progressCount = 0
        foreach ($folder in $allFolders) {
            $progressCount++
            if ($progressCount % 50 -eq 0) {
                Write-Host "Progress: $progressCount / $($allFolders.Count) directories scanned... (Found: $foundCount)" -ForegroundColor Gray
            }
            
            try {
                $folderSize = Get-FolderSize -FolderPath $folder.FullName
                
                if ($folderSize -ge $minSizeBytes) {
                    $sizeGB = [math]::Round($folderSize / 1GB, 2)
                    $largeFolders += [PSCustomObject]@{
                        Path = $folder.FullName
                        Name = $folder.Name
                        SizeBytes = $folderSize
                        SizeGB = $sizeGB
                        ParentPath = $folder.Parent.FullName
                        LastModified = $folder.LastWriteTime
                        ItemCount = (Get-ChildItem -Path $folder.FullName -Recurse -ErrorAction SilentlyContinue -Force | Measure-Object).Count
                    }
                    $foundCount++
                    
                    Write-Host "  [FOUND] " -NoNewline -ForegroundColor Green
                    Write-Host "$(Format-FileSize $folderSize) " -NoNewline -ForegroundColor Yellow
                    Write-Host "- $($folder.FullName)" -ForegroundColor White
                }
                
                $scannedCount++
            }
            catch {
                # Skip folders that cannot be accessed
                continue
            }
        }
        
        Write-Host ""
        Write-Host "============================================================" -ForegroundColor Cyan
        Write-Host "  SCAN COMPLETE" -ForegroundColor Cyan
        Write-Host "============================================================" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Directories scanned: $scannedCount" -ForegroundColor White
        Write-Host "Large folders found: $foundCount" -ForegroundColor $(if ($foundCount -gt 0) { "Green" } else { "Yellow" })
        Write-Host ""
        
        if ($largeFolders.Count -gt 0) {
            $largeFolders = $largeFolders | Sort-Object -Property SizeBytes -Descending
            Write-Host "Top 10 largest folders:" -ForegroundColor Cyan
            Write-Host ""
            $top10 = $largeFolders | Select-Object -First 10
            foreach ($folder in $top10) {
                Write-Host "  [$($top10.IndexOf($folder) + 1)] " -NoNewline -ForegroundColor Yellow
                Write-Host "$(Format-FileSize $folder.SizeBytes) " -NoNewline -ForegroundColor Green
                Write-Host "- $($folder.Path)" -ForegroundColor White
            }
        }
        
        Write-Host ""
    }
    catch {
        Write-SouliTEKResult "Error during scan: $_" -Level ERROR
    }
    
    Write-Host ""
    Read-Host "Press Enter to continue"
    
    return $largeFolders
}

function Show-LargeFolders {
    Show-Header "LARGE FOLDERS ANALYSIS" -Color Green
    
    if ($Script:FolderData.Count -eq 0) {
        Write-SouliTEKResult "No data available. Please run a scan first." -Level WARNING
        Write-Host ""
        Read-Host "Press Enter to return to main menu"
        return
    }
    
    Write-Host "Found $($Script:FolderData.Count) folder(s) larger than $($Script:MinSizeGB) GB" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    
    $sortedFolders = $Script:FolderData | Sort-Object -Property SizeBytes -Descending
    
    $index = 1
    foreach ($folder in $sortedFolders) {
        Write-Host "[$index] $($folder.Path)" -ForegroundColor Yellow
        Write-Host "     Size: $(Format-FileSize $folder.SizeBytes) ($($folder.SizeGB) GB)" -ForegroundColor White
        Write-Host "     Items: $($folder.ItemCount)" -ForegroundColor Gray
        Write-Host "     Modified: $($folder.LastModified)" -ForegroundColor Gray
        Write-Host ""
        $index++
    }
    
    $totalSize = ($Script:FolderData | Measure-Object -Property SizeBytes -Sum).Sum
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "  SUMMARY" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Total folders found: $($Script:FolderData.Count)" -ForegroundColor White
    Write-Host "Total size: $(Format-FileSize $totalSize)" -ForegroundColor Green
    Write-Host ""
    
    Read-Host "Press Enter to return to main menu"
}

function Export-DiskUsageReport {
    Show-Header "EXPORT DISK USAGE REPORT" -Color Yellow
    
    if ($Script:FolderData.Count -eq 0) {
        Write-SouliTEKResult "No data available. Please run a scan first." -Level WARNING
        Read-Host "Press Enter to return to main menu"
        return
    }
    
    Write-Host "Select export format:" -ForegroundColor White
    Write-Host ""
    Write-Host "  [1] Text File (.txt)" -ForegroundColor Yellow
    Write-Host "  [2] CSV File (.csv)" -ForegroundColor Yellow
    Write-Host "  [3] HTML Report (.html) with Top 10 Visualization" -ForegroundColor Yellow
    Write-Host "  [4] All Formats" -ForegroundColor Cyan
    Write-Host "  [0] Cancel" -ForegroundColor Red
    Write-Host ""
    
    $choice = Read-Host "Enter your choice (0-4)"
    
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    
    switch ($choice) {
        "1" {
            Export-TextReport -Folders $Script:FolderData -Timestamp $timestamp
        }
        "2" {
            Export-CSVReport -Folders $Script:FolderData -Timestamp $timestamp
        }
        "3" {
            Export-HTMLReport -Folders $Script:FolderData -Timestamp $timestamp
        }
        "4" {
            Export-TextReport -Folders $Script:FolderData -Timestamp $timestamp
            Export-CSVReport -Folders $Script:FolderData -Timestamp $timestamp
            Export-HTMLReport -Folders $Script:FolderData -Timestamp $timestamp
        }
        "0" {
            return
        }
        default {
            Write-SouliTEKResult "Invalid choice" -Level ERROR
            Start-Sleep -Seconds 2
            return
        }
    }
    
    Write-Host ""
    Read-Host "Press Enter to return to main menu"
}

function Export-TextReport {
    param($Folders, $Timestamp)
    
    $fileName = "DiskUsage_Report_$Timestamp.txt"
    $filePath = Join-Path $Script:OutputFolder $fileName
    
    $sortedFolders = $Folders | Sort-Object -Property SizeBytes -Descending
    
    $content = @()
    $content += "============================================================"
    $content += "    DISK USAGE ANALYZER REPORT - by Soulitek.co.il"
    $content += "============================================================"
    $content += ""
    $content += "Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    $content += "Computer: $env:COMPUTERNAME"
    $content += "User: $env:USERNAME"
    $content += "Scan Path: $Script:ScanPath"
    $content += "Minimum Size Threshold: $($Script:MinSizeGB) GB"
    $content += ""
    $content += "Total Folders Found: $($Folders.Count)"
    $totalSize = ($Folders | Measure-Object -Property SizeBytes -Sum).Sum
    $content += "Total Size: $(Format-FileSize $totalSize)"
    $content += ""
    $content += "============================================================"
    $content += ""
    $content += "FOLDERS SORTED BY SIZE (Largest First):"
    $content += ""
    $content += "============================================================"
    $content += ""
    
    $index = 1
    foreach ($folder in $sortedFolders) {
        $content += "[$index] $($folder.Path)"
        $content += "    Size: $(Format-FileSize $folder.SizeBytes) ($($folder.SizeGB) GB)"
        $content += "    Items: $($folder.ItemCount)"
        $content += "    Last Modified: $($folder.LastModified)"
        $content += ""
        $index++
    }
    
    $content += ""
    $content += "============================================================"
    $content += "END OF REPORT"
    $content += "Generated by Disk Usage Analyzer Tool"
    $content += "Coded by: Soulitek.co.il"
    $content += "www.soulitek.co.il"
    
    $content | Out-File -FilePath $filePath -Encoding UTF8
    
    Write-Host ""
    Write-SouliTEKResult "Text report exported to: $filePath" -Level SUCCESS
    Start-Sleep -Seconds 1
    Start-Process notepad.exe -ArgumentList $filePath
}

function Export-CSVReport {
    param($Folders, $Timestamp)
    
    $fileName = "DiskUsage_Report_$Timestamp.csv"
    $filePath = Join-Path $Script:OutputFolder $fileName
    
    $sortedFolders = $Folders | Sort-Object -Property SizeBytes -Descending
    
    $data = @()
    foreach ($folder in $sortedFolders) {
        $data += [PSCustomObject]@{
            Path = $folder.Path
            Name = $folder.Name
            SizeBytes = $folder.SizeBytes
            SizeGB = $folder.SizeGB
            SizeFormatted = Format-FileSize $folder.SizeBytes
            ParentPath = $folder.ParentPath
            LastModified = $folder.LastModified
            ItemCount = $folder.ItemCount
        }
    }
    
    $data | Export-Csv -Path $filePath -NoTypeInformation -Encoding UTF8
    
    Write-Host ""
    Write-SouliTEKResult "CSV report exported to: $filePath" -Level SUCCESS
    Start-Sleep -Seconds 1
    Start-Process $filePath
}

function Export-HTMLReport {
    param($Folders, $Timestamp)
    
    $fileName = "DiskUsage_Report_$Timestamp.html"
    $filePath = Join-Path $Script:OutputFolder $fileName
    
    $sortedFolders = $Folders | Sort-Object -Property SizeBytes -Descending
    $top10Folders = $sortedFolders | Select-Object -First 10
    $totalSize = ($Folders | Measure-Object -Property SizeBytes -Sum).Sum
    
    $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Disk Usage Analysis - $env:COMPUTERNAME</title>
    <meta charset="utf-8">
    <style>
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin: 20px; background-color: #f5f5f5; }
        h1 { color: #2c3e50; border-bottom: 3px solid #3498db; padding-bottom: 10px; }
        .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; border-radius: 10px; margin-bottom: 30px; }
        .summary { background-color: #3498db; color: white; padding: 20px; border-radius: 8px; margin-bottom: 20px; }
        .folder { background-color: white; padding: 15px; margin-bottom: 15px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); border-left: 4px solid #3498db; }
        .folder-header { font-size: 18px; font-weight: bold; color: #34495e; margin-bottom: 10px; }
        .folder-info { display: grid; grid-template-columns: 150px 1fr; gap: 8px; margin-top: 10px; }
        .info-label { font-weight: bold; color: #7f8c8d; }
        .size-large { color: #e74c3c; font-weight: bold; font-size: 16px; }
        .size-medium { color: #f39c12; font-weight: bold; }
        .size-small { color: #27ae60; font-weight: bold; }
        .chart-container { background-color: white; padding: 20px; border-radius: 8px; margin-bottom: 20px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .chart-bar { background: linear-gradient(90deg, #667eea 0%, #764ba2 100%); color: white; padding: 10px; margin: 5px 0; border-radius: 5px; text-align: right; transition: transform 0.2s; }
        .chart-bar:hover { transform: scale(1.02); }
        .chart-label { margin-bottom: 5px; font-weight: bold; color: #34495e; }
        .footer { text-align: center; margin-top: 30px; color: #7f8c8d; font-size: 12px; }
        table { width: 100%; border-collapse: collapse; background-color: white; border-radius: 8px; overflow: hidden; }
        th { background-color: #34495e; color: white; padding: 12px; text-align: left; }
        td { padding: 10px; border-bottom: 1px solid #ecf0f1; }
        tr:hover { background-color: #f8f9fa; }
        .rank { font-weight: bold; color: #3498db; }
    </style>
</head>
<body>
    <div class="header">
        <h1>[DISK USAGE] Analysis Report</h1>
        <p><strong>Computer:</strong> $env:COMPUTERNAME | <strong>User:</strong> $env:USERNAME</p>
        <p><strong>Generated:</strong> $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</p>
        <p><strong>Scan Path:</strong> $Script:ScanPath</p>
        <p><strong>Minimum Size Threshold:</strong> $($Script:MinSizeGB) GB</p>
    </div>
    
    <div class="summary">
        <h2 style="margin-top:0;">Summary</h2>
        <p><strong>Total Folders Found:</strong> $($Folders.Count)</p>
        <p><strong>Total Size:</strong> $(Format-FileSize $totalSize)</p>
        <p><strong>Average Folder Size:</strong> $(Format-FileSize ($totalSize / $Folders.Count))</p>
    </div>
"@

    # Top 10 Visualization Chart
    if ($top10Folders.Count -gt 0) {
        $maxSize = ($top10Folders | Measure-Object -Property SizeBytes -Maximum).Maximum
        
        $html += @"
    <div class="chart-container">
        <h2>Top 10 Largest Folders (Visualization)</h2>
"@
        
        foreach ($folder in $top10Folders) {
            $percentage = [math]::Round(($folder.SizeBytes / $maxSize) * 100, 1)
            $sizeDisplay = Format-FileSize $folder.SizeBytes
            $folderName = Split-Path $folder.Path -Leaf
            if ([string]::IsNullOrWhiteSpace($folderName)) {
                $folderName = $folder.Path
            }
            
            $html += @"
        <div class="chart-label">$folderName</div>
        <div class="chart-bar" style="width: $percentage%">$sizeDisplay</div>
"@
        }
        
        $html += "    </div>`n"
    }
    
    # All folders table
    $html += @"
    <div class="chart-container">
        <h2>All Folders (Sorted by Size)</h2>
        <table>
            <thead>
                <tr>
                    <th>Rank</th>
                    <th>Path</th>
                    <th>Size</th>
                    <th>Size (GB)</th>
                    <th>Items</th>
                    <th>Last Modified</th>
                </tr>
            </thead>
            <tbody>
"@

    $rank = 1
    foreach ($folder in $sortedFolders) {
        $sizeClass = if ($folder.SizeGB -ge 10) { "size-large" } 
                    elseif ($folder.SizeGB -ge 5) { "size-medium" } 
                    else { "size-small" }
        
        $html += @"
                <tr>
                    <td class="rank">#$rank</td>
                    <td>$($folder.Path)</td>
                    <td class="$sizeClass">$(Format-FileSize $folder.SizeBytes)</td>
                    <td>$($folder.SizeGB) GB</td>
                    <td>$($folder.ItemCount)</td>
                    <td>$($folder.LastModified)</td>
                </tr>
"@
        $rank++
    }
    
    $html += @"
            </tbody>
        </table>
    </div>
    
    <div class="footer">
        <p>Generated by Disk Usage Analyzer Tool | Coded by Soulitek.co.il</p>
        <p>www.soulitek.co.il | (C) 2025 Soulitek - All Rights Reserved</p>
    </div>
</body>
</html>
"@
    
    Set-Content -Path $filePath -Value $html -Encoding UTF8
    
    Write-Host ""
    Write-SouliTEKResult "HTML report exported to: $filePath" -Level SUCCESS
    Start-Sleep -Seconds 1
    Start-Process $filePath
}

function Select-ScanPath {
    Show-Header "SELECT SCAN PATH" -Color Cyan
    
    Write-Host "Select drive/path to scan:" -ForegroundColor White
    Write-Host ""
    
    # Get available drives
    $drives = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Used -gt 0 }
    
    Write-Host "Available drives:" -ForegroundColor Cyan
    Write-Host ""
    $index = 1
    $driveOptions = @()
    foreach ($drive in $drives) {
        $freeGB = [math]::Round($drive.Free / 1GB, 2)
        $usedGB = [math]::Round($drive.Used / 1GB, 2)
        $totalGB = [math]::Round(($drive.Free + $drive.Used) / 1GB, 2)
        
        Write-Host "  [$index] $($drive.Name):\" -NoNewline -ForegroundColor Yellow
        Write-Host " (Used: $usedGB GB, Free: $freeGB GB, Total: $totalGB GB)" -ForegroundColor Gray
        $driveOptions += $drive.Root
        $index++
    }
    
    Write-Host ""
    Write-Host "  [$index] Enter custom path" -ForegroundColor Yellow
    Write-Host "  [0] Cancel" -ForegroundColor Red
    Write-Host ""
    
    $choice = Read-Host "Enter your choice (0-$index)"
    
    if ($choice -eq "0") {
        return $null
    }
    elseif ([int]$choice -ge 1 -and [int]$choice -le ($driveOptions.Count)) {
        $selectedPath = $driveOptions[[int]$choice - 1]
        Write-Host ""
        Write-SouliTEKResult "Selected path: $selectedPath" -Level SUCCESS
        Start-Sleep -Seconds 1
        return $selectedPath
    }
    elseif ([int]$choice -eq ($driveOptions.Count + 1)) {
        Write-Host ""
        $customPath = Read-Host "Enter custom path (e.g., C:\Users, D:\Data)"
        
        if (Test-Path $customPath) {
            Write-Host ""
            Write-SouliTEKResult "Selected path: $customPath" -Level SUCCESS
            Start-Sleep -Seconds 1
            return $customPath
        }
        else {
            Write-SouliTEKResult "Path not found: $customPath" -Level ERROR
            Start-Sleep -Seconds 2
            return $null
        }
    }
    else {
        Write-SouliTEKResult "Invalid choice" -Level ERROR
        Start-Sleep -Seconds 2
        return $null
    }
}

function Set-MinimumSize {
    Show-Header "SET MINIMUM SIZE THRESHOLD" -Color Cyan
    
    Write-Host "Current minimum size threshold: $($Script:MinSizeGB) GB" -ForegroundColor White
    Write-Host ""
    Write-Host "Enter new minimum size in GB (folders larger than this will be included):" -ForegroundColor Yellow
    Write-Host "  (Press Enter to keep current: $($Script:MinSizeGB) GB)" -ForegroundColor Gray
    Write-Host ""
    
    $input = Read-Host "Minimum size (GB)"
    
    if (-not [string]::IsNullOrWhiteSpace($input)) {
        try {
            $newSize = [double]$input
            if ($newSize -gt 0) {
                $Script:MinSizeGB = $newSize
                Write-Host ""
                Write-SouliTEKResult "Minimum size threshold set to: $($Script:MinSizeGB) GB" -Level SUCCESS
            }
            else {
                Write-Host ""
                Write-SouliTEKResult "Size must be greater than 0" -Level ERROR
            }
        }
        catch {
            Write-Host ""
            Write-SouliTEKResult "Invalid input. Using current value: $($Script:MinSizeGB) GB" -Level WARNING
        }
    }
    
    Start-Sleep -Seconds 2
}

# ============================================================
# MAIN MENU
# ============================================================

function Show-MainMenu {
    Show-Header "DISK USAGE ANALYZER - Professional Tool" -Color Cyan
    
    Write-Host "      Coded by: Soulitek.co.il" -ForegroundColor Green
    Write-Host "      IT Solutions for your business" -ForegroundColor Green
    Write-Host "      www.soulitek.co.il" -ForegroundColor Green
    Write-Host ""
    Write-Host "      (C) 2025 Soulitek - All Rights Reserved" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Current Settings:" -ForegroundColor White
    Write-Host "  Scan Path: " -NoNewline -ForegroundColor Gray
    if ([string]::IsNullOrWhiteSpace($Script:ScanPath)) {
        Write-Host "Not set" -ForegroundColor Yellow
    } else {
        Write-Host $Script:ScanPath -ForegroundColor Green
    }
    Write-Host "  Minimum Size: " -NoNewline -ForegroundColor Gray
    Write-Host "$($Script:MinSizeGB) GB" -ForegroundColor Green
    Write-Host "  Folders Found: " -NoNewline -ForegroundColor Gray
    Write-Host "$($Script:FolderData.Count)" -ForegroundColor $(if ($Script:FolderData.Count -gt 0) { "Green" } else { "Yellow" })
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Select an option:" -ForegroundColor White
    Write-Host ""
    Write-Host "  [1] Select Scan Path       - Choose drive/folder to analyze" -ForegroundColor Yellow
    Write-Host "  [2] Set Minimum Size       - Change size threshold (default: 1 GB)" -ForegroundColor Yellow
    Write-Host "  [3] Scan for Large Folders - Find folders > $($Script:MinSizeGB) GB" -ForegroundColor Yellow
    Write-Host "  [4] View Results           - Display found folders" -ForegroundColor Yellow
    Write-Host "  [5] Export Report           - Save to file (TXT/CSV/HTML)" -ForegroundColor Cyan
    Write-Host "  [6] Help                   - Usage guide" -ForegroundColor White
    Write-Host "  [0] Exit" -ForegroundColor Red
    Write-Host ""
    Write-Host "========================================" -ForegroundColor DarkGray
    
    $choice = Read-Host "Enter your choice (0-6)"
    return $choice
}

function Show-Help {
    Show-Header "HELP GUIDE" -Color Cyan
    
    Write-Host "DISK USAGE ANALYZER - USAGE GUIDE" -ForegroundColor Yellow
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "[1] SELECT SCAN PATH" -ForegroundColor White
    Write-Host "    Choose which drive or folder to analyze" -ForegroundColor Gray
    Write-Host "    Options: Available drives or custom path" -ForegroundColor Gray
    Write-Host "    Use: Start by selecting where to scan" -ForegroundColor Gray
    Write-Host ""
    Write-Host "[2] SET MINIMUM SIZE" -ForegroundColor White
    Write-Host "    Change the size threshold for large folders" -ForegroundColor Gray
    Write-Host "    Default: 1 GB (folders larger than 1 GB are included)" -ForegroundColor Gray
    Write-Host "    Use: Adjust threshold based on your needs" -ForegroundColor Gray
    Write-Host ""
    Write-Host "[3] SCAN FOR LARGE FOLDERS" -ForegroundColor White
    Write-Host "    Analyzes selected path and finds large folders" -ForegroundColor Gray
    Write-Host "    Shows: Size, item count, last modified date" -ForegroundColor Gray
    Write-Host "    Use: Identify folders consuming disk space" -ForegroundColor Gray
    Write-Host ""
    Write-Host "[4] VIEW RESULTS" -ForegroundColor White
    Write-Host "    Displays all found folders sorted by size" -ForegroundColor Gray
    Write-Host "    Includes: Full path, size, item count, summary" -ForegroundColor Gray
    Write-Host "    Use: Review findings before export" -ForegroundColor Gray
    Write-Host ""
    Write-Host "[5] EXPORT REPORT" -ForegroundColor White
    Write-Host "    Save analysis results to file" -ForegroundColor Gray
    Write-Host "    Formats: Text (.txt), CSV (.csv), HTML (.html)" -ForegroundColor Gray
    Write-Host "    HTML includes: Top 10 visualization chart" -ForegroundColor Gray
    Write-Host "    Use: Documentation, reporting, sharing" -ForegroundColor Gray
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "TIPS FOR EFFECTIVE ANALYSIS:" -ForegroundColor Yellow
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "- Start with C:\ drive for full system analysis" -ForegroundColor White
    Write-Host "- Use custom paths for specific directories (e.g., C:\Users)" -ForegroundColor White
    Write-Host "- Adjust minimum size threshold based on your disk size" -ForegroundColor White
    Write-Host "- Large scans may take several minutes - be patient" -ForegroundColor White
    Write-Host "- Export HTML report for best visualization" -ForegroundColor White
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "COMMON SCENARIOS:" -ForegroundColor Yellow
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Scenario 1: Running out of disk space" -ForegroundColor White
    Write-Host "  - Select C:\ drive, scan, review top folders, clean up large files" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Scenario 2: Analyzing specific user folder" -ForegroundColor White
    Write-Host "  - Select custom path (e.g., C:\Users\Username), scan, review results" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Scenario 3: Storage cleanup planning" -ForegroundColor White
    Write-Host "  - Scan multiple drives, export reports, plan cleanup strategy" -ForegroundColor Gray
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Read-Host "Press Enter to return to main menu"
}

function Show-ExitMessage {
    Clear-Host
    Write-Host ""
    Write-Host "Thank you for using SouliTEK Disk Usage Analyzer!" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Website: www.soulitek.co.il" -ForegroundColor Yellow
    Write-Host ""
}

# ============================================================
# MAIN EXECUTION
# ============================================================

# Check for administrator privileges (helpful but not always required)
if (-not (Test-SouliTEKAdministrator)) {
    Write-Host ""
    Write-Host "Note: Running without administrator privileges." -ForegroundColor Yellow
    Write-Host "Some folders may be inaccessible. For best results, run as Administrator." -ForegroundColor Yellow
    Write-Host ""
    Start-Sleep -Seconds 2
}

# Main menu loop
do {
    $choice = Show-MainMenu
    
    switch ($choice) {
        "1" {
            $Script:ScanPath = Select-ScanPath
            if ($null -ne $Script:ScanPath) {
                $Script:FolderData = @()  # Clear previous results
            }
        }
        "2" {
            Set-MinimumSize
        }
        "3" {
            if ([string]::IsNullOrWhiteSpace($Script:ScanPath)) {
                Show-Header "ERROR" -Color Red
                Write-SouliTEKResult "Please select a scan path first (option 1)" -Level ERROR
                Write-Host ""
                Read-Host "Press Enter to return to main menu"
            }
            else {
                $Script:FolderData = Get-LargeFolders -Path $Script:ScanPath -MinSizeGB $Script:MinSizeGB
            }
        }
        "4" {
            Show-LargeFolders
        }
        "5" {
            Export-DiskUsageReport
        }
        "6" {
            Show-Help
        }
        "0" {
            Show-ExitMessage
            break
        }
        default {
            Write-Host "Invalid choice. Please try again." -ForegroundColor Red
            Start-Sleep -Seconds 2
        }
    }
} while ($choice -ne "0")

