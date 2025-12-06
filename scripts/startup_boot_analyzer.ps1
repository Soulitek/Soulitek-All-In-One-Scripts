# ============================================================
# Startup Programs & Boot Time Analyzer - Professional Edition
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
# This tool analyzes startup programs and boot performance
# to help identify optimization opportunities.
# 
# Features: Startup Folders & Task Scheduler Scanning | Boot Time Analysis
#           Auto-Start Services Detection | Performance Impact Rating
#           Trend Tracking | HTML Reports
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

# Requires elevation (Administrator)
#Requires -RunAsAdministrator
#Requires -Version 5.1

# Set window title
$Host.UI.RawUI.WindowTitle = "STARTUP PROGRAMS & BOOT TIME ANALYZER"

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
# CONFIGURATION & CONSTANTS
# ============================================================

# Storage paths for user data
$UserDataPath = Join-Path $env:APPDATA "SouliTEK"
$BootTimeLogPath = Join-Path $UserDataPath "BootTimeHistory.json"

# Ensure directory exists
if (-not (Test-Path $UserDataPath)) {
    New-Item -ItemType Directory -Path $UserDataPath -Force | Out-Null
}

# Known Programs Database (Performance Impact)
$Global:KnownPrograms = @{
    "OneDrive.exe" = @{ Impact = "Medium"; Category = "Cloud Storage" }
    "Spotify.exe" = @{ Impact = "High"; Category = "Media" }
    "Teams.exe" = @{ Impact = "High"; Category = "Communication" }
    "Slack.exe" = @{ Impact = "Medium"; Category = "Communication" }
    "Dropbox.exe" = @{ Impact = "Medium"; Category = "Cloud Storage" }
    "GoogleDrive.exe" = @{ Impact = "Medium"; Category = "Cloud Storage" }
    "GoogleDriveFS.exe" = @{ Impact = "Medium"; Category = "Cloud Storage" }
    "AdobeAAMUpdater.exe" = @{ Impact = "High"; Category = "Updater" }
    "AdobeARM.exe" = @{ Impact = "Low"; Category = "Updater" }
    "Creative Cloud.exe" = @{ Impact = "High"; Category = "Creative" }
    "iTunesHelper.exe" = @{ Impact = "Medium"; Category = "Media" }
    "Discord.exe" = @{ Impact = "Medium"; Category = "Communication" }
    "Zoom.exe" = @{ Impact = "Medium"; Category = "Communication" }
    "Steam.exe" = @{ Impact = "High"; Category = "Gaming" }
    "steamwebhelper.exe" = @{ Impact = "High"; Category = "Gaming" }
    "EpicGamesLauncher.exe" = @{ Impact = "High"; Category = "Gaming" }
    "Origin.exe" = @{ Impact = "High"; Category = "Gaming" }
    "Uplay.exe" = @{ Impact = "High"; Category = "Gaming" }
    "Battle.net.exe" = @{ Impact = "High"; Category = "Gaming" }
    "GalaxyClient.exe" = @{ Impact = "Medium"; Category = "Gaming" }
    "XboxApp.exe" = @{ Impact = "Medium"; Category = "Gaming" }
    "msedge.exe" = @{ Impact = "Medium"; Category = "Browser" }
    "chrome.exe" = @{ Impact = "Medium"; Category = "Browser" }
    "firefox.exe" = @{ Impact = "Medium"; Category = "Browser" }
    "CCXProcess.exe" = @{ Impact = "High"; Category = "Creative" }
    "CCleanerBrowser.exe" = @{ Impact = "Medium"; Category = "Utility" }
    "BitTorrent.exe" = @{ Impact = "Low"; Category = "Download" }
    "uTorrent.exe" = @{ Impact = "Low"; Category = "Download" }
    "Skype.exe" = @{ Impact = "Medium"; Category = "Communication" }
    "VBoxTray.exe" = @{ Impact = "Low"; Category = "Virtualization" }
    "vmware-tray.exe" = @{ Impact = "Low"; Category = "Virtualization" }
    "Backup.exe" = @{ Impact = "Medium"; Category = "Backup" }
    "Acronis.exe" = @{ Impact = "Medium"; Category = "Backup" }
    "javaws.exe" = @{ Impact = "Low"; Category = "Runtime" }
    "jusched.exe" = @{ Impact = "Low"; Category = "Updater" }
}

# Global variable to store scanned items
$Global:AllStartupItems = @()
$Global:LastBootData = $null

# ============================================================
# DATA COLLECTION FUNCTIONS
# ============================================================


function Get-StartupFolderItems {
    <#
    .SYNOPSIS
        Scans Startup folders for shortcuts and executables
    #>
    $items = @()
    $startupFolders = @(
        @{ Path = "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Startup"; Scope = "All Users" }
        @{ Path = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"; Scope = "Current User" }
    )
    
    foreach ($folder in $startupFolders) {
        try {
            if (Test-Path $folder.Path) {
                $files = Get-ChildItem -Path $folder.Path -File -ErrorAction SilentlyContinue
                foreach ($file in $files) {
                    $target = $file.FullName
                    
                    # Parse shortcut target if .lnk file
                    if ($file.Extension -eq ".lnk") {
                        try {
                            $shell = New-Object -ComObject WScript.Shell
                            $shortcut = $shell.CreateShortcut($file.FullName)
                            $target = $shortcut.TargetPath
                            if ($shortcut.Arguments) {
                                $target = "$target $($shortcut.Arguments)"
                            }
                        } catch {
                            # If parsing fails, use file path
                            $target = $file.FullName
                        }
                    }
                    
                    $items += [PSCustomObject]@{
                        Name = $file.BaseName
                        Command = $target
                        Source = "Startup Folder"
                        Location = $file.FullName
                        Scope = $folder.Scope
                        Type = "File"
                        Impact = "Unknown"
                        Category = "Unknown"
                    }
                }
            }
        } catch {
            Write-Warning "Failed to scan startup folder $($folder.Path): $_"
        }
    }
    
    return $items
}

function Get-TaskSchedulerStartupItems {
    <#
    .SYNOPSIS
        Find Task Scheduler tasks that run at logon/startup
    #>
    $items = @()
    
    try {
        $tasks = Get-ScheduledTask -ErrorAction SilentlyContinue | Where-Object { 
            $_.State -eq "Ready" -and 
            $_.Triggers.CimClass.CimClassName -match "MSFT_TaskLogonTrigger|MSFT_TaskBootTrigger"
        }
        
        foreach ($task in $tasks) {
            try {
                $action = ($task.Actions | Select-Object -First 1).Execute
                $arguments = ($task.Actions | Select-Object -First 1).Arguments
                $command = if ($arguments) { "$action $arguments" } else { $action }
                
                $triggerType = ($task.Triggers | Select-Object -First 1).CimClass.CimClassName
                $triggerTypeName = if ($triggerType -like "*Logon*") { "AtLogon" } else { "AtStartup" }
                
                $items += [PSCustomObject]@{
                    Name = $task.TaskName
                    Command = $command
                    Source = "Task Scheduler"
                    Location = $task.TaskPath
                    Scope = if ($task.Principal.UserId -eq "SYSTEM" -or $task.Principal.UserId -like "S-1-5-18") { "System" } else { "User" }
                    Type = $triggerTypeName
                    Enabled = ($task.State -eq "Ready")
                    Impact = "Unknown"
                    Category = "Unknown"
                }
            } catch {
                # Skip tasks that fail to parse
                continue
            }
        }
    } catch {
        Write-Warning "Failed to query Task Scheduler: $_"
    }
    
    return $items
}

function Get-AutoStartServices {
    <#
    .SYNOPSIS
        List services with Automatic startup type
    #>
    param([switch]$ExcludeMicrosoft)
    
    $items = @()
    
    try {
        $services = Get-Service -ErrorAction SilentlyContinue | Where-Object { 
            $_.StartType -match "Automatic" 
        }
        
        foreach ($service in $services) {
            try {
                $serviceDetails = Get-CimInstance Win32_Service -Filter "Name='$($service.Name)'" -ErrorAction SilentlyContinue
                
                if ($serviceDetails) {
                    # Skip Microsoft services if requested
                    if ($ExcludeMicrosoft -and $serviceDetails.PathName -match "Windows|Microsoft") {
                        continue
                    }
                    
                    $items += [PSCustomObject]@{
                        Name = $service.DisplayName
                        Command = $serviceDetails.PathName
                        Source = "Windows Service"
                        Location = "services.msc"
                        Scope = "System"
                        Type = $service.StartType
                        Status = $service.Status
                        Impact = "Unknown"
                        Category = "Service"
                    }
                }
            } catch {
                # Skip services that fail to query
                continue
            }
        }
    } catch {
        Write-Warning "Failed to query Windows Services: $_"
    }
    
    return $items
}

function Get-BootPerformanceFromEventLog {
    <#
    .SYNOPSIS
        Parse Windows Event Logs for boot performance data
    #>
    param([int]$MaxEvents = 10)
    
    $bootEvents = @()
    
    try {
        # Check if event log exists and is enabled
        $logExists = Get-WinEvent -ListLog "Microsoft-Windows-Diagnostics-Performance/Operational" -ErrorAction SilentlyContinue
        
        if (-not $logExists -or -not $logExists.IsEnabled) {
            Write-Verbose "Boot performance event log not available or not enabled"
            return $null
        }
        
        $events = Get-WinEvent -LogName "Microsoft-Windows-Diagnostics-Performance/Operational" -MaxEvents 100 -ErrorAction SilentlyContinue |
            Where-Object { $_.Id -eq 100 }
        
        if ($events) {
            $eventsToProcess = $events | Select-Object -First $MaxEvents
            
            foreach ($bootEvent in $eventsToProcess) {
                try {
                    # Parse XML content
                    $xml = [xml]$bootEvent.ToXml()
                    $bootTimeNode = $xml.Event.EventData.Data | Where-Object { $_.Name -eq "BootTime" }
                    
                    if ($bootTimeNode) {
                        $bootTimeMS = [int]$bootTimeNode.'#text'
                        
                        $bootEvents += [PSCustomObject]@{
                            TimeGenerated = $bootEvent.TimeCreated
                            BootDurationMS = $bootTimeMS
                            BootDurationSeconds = [math]::Round($bootTimeMS / 1000, 1)
                        }
                    }
                } catch {
                    # Skip events that fail to parse
                    continue
                }
            }
        }
    } catch {
        Write-Verbose "Could not read boot performance events: $_"
        return $null
    }
    
    return $bootEvents
}

function Get-BootTimeHistory {
    <#
    .SYNOPSIS
        Load boot time history from JSON file
    #>
    if (Test-Path $BootTimeLogPath) {
        try {
            $history = Get-Content $BootTimeLogPath -Raw | ConvertFrom-Json
            return $history
        } catch {
            Write-Warning "Failed to load boot time history: $_"
            return @()
        }
    }
    return @()
}

function Save-BootTimeToHistory {
    <#
    .SYNOPSIS
        Save boot time record to history JSON file
    #>
    param(
        [Parameter(Mandatory=$true)]
        [DateTime]$BootTime,
        [Parameter(Mandatory=$true)]
        [int]$DurationSeconds,
        [string]$Source = "EventLog"
    )
    
    try {
        $history = @(Get-BootTimeHistory)
        
        # Check if this boot time already recorded
        $bootTimeStr = $BootTime.ToString("yyyy-MM-ddTHH:mm:ss")
        if ($history | Where-Object { $_.BootTime -eq $bootTimeStr }) {
            return
        }
        
        $newRecord = [PSCustomObject]@{
            BootTime = $bootTimeStr
            DurationSeconds = $DurationSeconds
            Source = $Source
        }
        
        $history += $newRecord
        
        # Keep only last 30 boots
        if ($history.Count -gt 30) {
            $history = $history | Select-Object -Last 30
        }
        
        $history | ConvertTo-Json | Set-Content $BootTimeLogPath
    } catch {
        Write-Warning "Failed to save boot time history: $_"
    }
}

function Get-ProcessCPUUsage {
    <#
    .SYNOPSIS
        Optional: Measure process CPU usage (not implemented in read-only version)
    #>
    param([string]$ProcessName)
    
    # This is a placeholder for optional CPU measurement
    # In read-only mode, we rely on known database and user ratings
    return $null
}

function Get-PerformanceImpactRating {
    <#
    .SYNOPSIS
        Determine performance impact based on known programs database
    #>
    param(
        [string]$ProgramName,
        [string]$CommandPath
    )
    
    # Extract executable name from command path
    $exeName = ""
    if ($CommandPath -match '([^\\\/]+\.exe)') {
        $exeName = $matches[1]
    } elseif ($CommandPath -match '([^\\\/]+)$') {
        $exeName = $matches[1]
    } else {
        $exeName = $ProgramName
    }
    
    # 1. Check known programs database
    if ($Global:KnownPrograms.ContainsKey($exeName)) {
        return @{
            Impact = $Global:KnownPrograms[$exeName].Impact
            Category = $Global:KnownPrograms[$exeName].Category
            Source = "Database"
        }
    }
    
    # 2. Heuristics based on name patterns
    if ($ProgramName -match "Update|Updater" -and $ProgramName -notmatch "Windows") {
        return @{
            Impact = "Medium"
            Category = "Updater"
            Source = "Pattern Match"
        }
    }
    
    if ($ProgramName -match "Helper|Agent|Tray") {
        return @{
            Impact = "Low"
            Category = "Background"
            Source = "Pattern Match"
        }
    }
    
    # Default
    return @{
        Impact = "Unknown"
        Category = "Unrated"
        Source = "Not Rated"
    }
}


function Get-OptimizationRecommendations {
    <#
    .SYNOPSIS
        Generate actionable recommendations for optimization
    #>
    param([array]$AllStartupItems)
    
    $recommendations = @()
    
    # Filter out services for recommendations (focus on user-controllable items)
    $userItems = $AllStartupItems | Where-Object { $_.Source -ne "Windows Service" }
    
    # Group items by impact
    $highImpact = $userItems | Where-Object { $_.Impact -eq "High" }
    
    # Identify updaters
    $updaters = $userItems | Where-Object { 
        ($_.Name -match "Update|Updater" -and $_.Name -notmatch "Windows") -or
        $_.Category -eq "Updater"
    }
    
    # Cloud storage apps
    $cloudStorage = $userItems | Where-Object {
        $_.Name -match "OneDrive|Dropbox|Google Drive|iCloud|Box|Sync" -or
        $_.Category -eq "Cloud Storage"
    }
    
    # Gaming launchers
    $gamingApps = $userItems | Where-Object {
        $_.Name -match "Steam|Epic|Origin|Uplay|Battle\.net|GOG|Xbox" -or
        $_.Category -eq "Gaming"
    }
    
    # Build recommendations
    if ($highImpact.Count -gt 0) {
        $recommendations += [PSCustomObject]@{
            Priority = "HIGH"
            Category = "High Impact Programs"
            Count = $highImpact.Count
            Description = "These programs significantly slow down boot time"
            Items = $highImpact.Name
            Guidance = "Consider disabling these if not needed immediately at startup. You can launch them manually when needed."
            HowToDisable = @(
                "Method 1 - Task Manager:",
                "  1. Press Ctrl+Shift+Esc to open Task Manager",
                "  2. Go to 'Startup' tab",
                "  3. Right-click the program and select 'Disable'",
                "",
                "Method 2 - Application Settings:",
                "  1. Open each application",
                "  2. Go to Settings/Preferences",
                "  3. Look for 'Start with Windows' or 'Auto-start'",
                "  4. Disable the option"
            )
        }
    }
    
    if ($updaters.Count -gt 0) {
        $recommendations += [PSCustomObject]@{
            Priority = "MEDIUM"
            Category = "Background Updaters"
            Count = $updaters.Count
            Description = "These updaters run in background unnecessarily"
            Items = $updaters.Name
            Guidance = "Most applications can check for updates when you launch them, rather than at startup."
            HowToDisable = @(
                "Method 1 - Registry (Advanced):",
                "  1. Press Win+R, type 'regedit', press Enter",
                "  2. Navigate to HKCU\Software\Microsoft\Windows\CurrentVersion\Run",
                "  3. Find and delete the updater entry",
                "  4. Also check HKLM\Software\Microsoft\...\Run (requires admin)",
                "",
                "Method 2 - Task Scheduler:",
                "  1. Press Win+R, type 'taskschd.msc', press Enter",
                "  2. Find the updater task",
                "  3. Right-click and select 'Disable'"
            )
        }
    }
    
    if ($cloudStorage.Count -gt 2) {
        $recommendations += [PSCustomObject]@{
            Priority = "MEDIUM"
            Category = "Multiple Cloud Storage Apps"
            Count = $cloudStorage.Count
            Description = "Multiple cloud sync apps increase boot time and resource usage"
            Items = $cloudStorage.Name
            Guidance = "Consider using only the cloud storage services you actively need at startup. Others can be launched manually when needed."
            HowToDisable = @(
                "Check each application's settings:",
                "  1. Open the cloud storage app (from system tray)",
                "  2. Go to Settings/Preferences",
                "  3. Look for 'Start automatically' or 'Launch on startup'",
                "  4. Disable the option for services you don't need immediately"
            )
        }
    }
    
    if ($gamingApps.Count -gt 0) {
        $recommendations += [PSCustomObject]@{
            Priority = "LOW"
            Category = "Gaming Launchers"
            Count = $gamingApps.Count
            Description = "Gaming platforms can be launched manually when needed"
            Items = $gamingApps.Name
            Guidance = "Unless you game immediately after boot, disable these to save boot time and system resources."
            HowToDisable = @(
                "Open each launcher's settings:",
                "  1. Launch the gaming platform",
                "  2. Open Settings/Preferences",
                "  3. Find 'Run on startup' or 'Start with Windows'",
                "  4. Disable the option"
            )
        }
    }
    
    return $recommendations
}

# ============================================================
# DISPLAY FUNCTIONS
# ============================================================

function Show-PerformanceSummary {
    <#
    .SYNOPSIS
        Display performance dashboard at top of results
    #>
    param(
        [array]$BootData,
        [array]$StartupItems
    )
    
    Clear-Host
    Write-Host ""
    Write-Host "====================================================================" -ForegroundColor Cyan
    Write-Host "           BOOT PERFORMANCE SUMMARY" -ForegroundColor Cyan
    Write-Host "====================================================================" -ForegroundColor Cyan
    Write-Host ""
    
    # Get last boot info
    $lastBoot = Get-CimInstance Win32_OperatingSystem | Select-Object -ExpandProperty LastBootUpTime
    Write-Host "Last Boot: " -NoNewline
    Write-Host "$($lastBoot.ToString('MMMM dd, yyyy hh:mm:ss tt'))" -ForegroundColor Green
    
    # Boot duration from event log if available
    if ($BootData -and $BootData.Count -gt 0) {
        $latestBoot = $BootData[0]
        Write-Host "Boot Duration: " -NoNewline
        
        $duration = $latestBoot.BootDurationSeconds
        $color = if ($duration -lt 30) { "Green" } elseif ($duration -lt 60) { "Yellow" } else { "Red" }
        Write-Host "$duration seconds" -ForegroundColor $color
        
        # Performance rating
        Write-Host "Performance Rating: " -NoNewline
        if ($duration -lt 30) {
            Write-Host "EXCELLENT (Very fast)" -ForegroundColor Green
        } elseif ($duration -lt 45) {
            Write-Host "GOOD (Fast)" -ForegroundColor Green
        } elseif ($duration -lt 60) {
            Write-Host "MODERATE (Could be improved)" -ForegroundColor Yellow
        } else {
            Write-Host "SLOW (Needs optimization)" -ForegroundColor Red
        }
    } else {
        Write-Host "Boot Duration: " -NoNewline
        Write-Host "Not available (Event log disabled)" -ForegroundColor Gray
        Write-Host ""
        Write-Host "To enable boot performance tracking:" -ForegroundColor Yellow
        Write-Host "  Run: wevtutil sl Microsoft-Windows-Diagnostics-Performance/Operational /e:true" -ForegroundColor Gray
    }
    
    Write-Host ""
    
    # Historical trend
    $history = Get-BootTimeHistory
    if ($history.Count -gt 1) {
        Write-Host "Historical Trend (Last $($history.Count) Boots):" -ForegroundColor Cyan
        
        $durations = $history | Select-Object -ExpandProperty DurationSeconds
        $avgDuration = [math]::Round(($durations | Measure-Object -Average).Average, 1)
        $minDuration = ($durations | Measure-Object -Minimum).Minimum
        $maxDuration = ($durations | Measure-Object -Maximum).Maximum
        
        Write-Host "  Average: " -NoNewline
        Write-Host "$avgDuration seconds" -ForegroundColor White
        Write-Host "  Best: " -NoNewline
        Write-Host "$minDuration seconds" -ForegroundColor Green
        Write-Host "  Worst: " -NoNewline
        Write-Host "$maxDuration seconds" -ForegroundColor Red
        
        # Trend analysis (compare last 3 to previous 3)
        if ($history.Count -ge 6) {
            $recent = ($history | Select-Object -Last 3 | Select-Object -ExpandProperty DurationSeconds | Measure-Object -Average).Average
            $previous = ($history | Select-Object -Last 6 | Select-Object -First 3 | Select-Object -ExpandProperty DurationSeconds | Measure-Object -Average).Average
            $diff = [math]::Round($recent - $previous, 1)
            
            Write-Host "  Trend: " -NoNewline
            if ($diff -lt -2) {
                $absDiff = [math]::Abs($diff)
                Write-Host "Improving - $absDiff seconds faster" -ForegroundColor Green
            } elseif ($diff -gt 2) {
                Write-Host "Degrading - $diff seconds slower" -ForegroundColor Red
            } else {
                Write-Host "Stable" -ForegroundColor White
            }
        }
    } elseif ($history.Count -eq 1) {
        Write-Host "Historical Trend: First analysis (no trend data yet)" -ForegroundColor Gray
    }
    
    Write-Host ""
    
    # Startup items summary
    Write-Host "Startup Items Summary:" -ForegroundColor Cyan
    
    $highImpactCount = ($StartupItems | Where-Object { $_.Impact -eq "High" }).Count
    $mediumImpactCount = ($StartupItems | Where-Object { $_.Impact -eq "Medium" }).Count
    $lowImpactCount = ($StartupItems | Where-Object { $_.Impact -eq "Low" }).Count
    $unknownCount = ($StartupItems | Where-Object { $_.Impact -eq "Unknown" }).Count
    
    Write-Host "  Total Items: " -NoNewline
    Write-Host $StartupItems.Count -ForegroundColor White
    
    if ($highImpactCount -gt 0) {
        Write-Host "  High Impact: " -NoNewline
        Write-Host "$highImpactCount items" -ForegroundColor Red
    }
    
    if ($mediumImpactCount -gt 0) {
        Write-Host "  Medium Impact: " -NoNewline
        Write-Host $mediumImpactCount -ForegroundColor Yellow
    }
    
    if ($lowImpactCount -gt 0) {
        Write-Host "  Low Impact: " -NoNewline
        Write-Host $lowImpactCount -ForegroundColor Green
    }
    
    if ($unknownCount -gt 0) {
        Write-Host "  Unknown: " -NoNewline
        Write-Host $unknownCount -ForegroundColor Gray
    }
    
    Write-Host ""
    
    # Optimization potential
    Write-Host "Optimization Potential: " -NoNewline
    if ($highImpactCount -ge 5) {
        Write-Host "HIGH" -ForegroundColor Red
        Write-Host "  -> Disabling $highImpactCount high-impact items could save significant boot time" -ForegroundColor Yellow
    } elseif ($highImpactCount -ge 2) {
        Write-Host "MEDIUM" -ForegroundColor Yellow
        Write-Host "  -> Some optimization opportunities available" -ForegroundColor Gray
    } else {
        Write-Host "LOW" -ForegroundColor Green
        Write-Host "  -> System is already well optimized" -ForegroundColor Gray
    }
    
    Write-Host ""
}

function Show-StartupItemsByCategory {
    <#
    .SYNOPSIS
        Display all startup items grouped by source
    #>
    param([array]$AllItems)
    
    # Group by source
    $folderItems = $AllItems | Where-Object { $_.Source -eq "Startup Folder" }
    $taskItems = $AllItems | Where-Object { $_.Source -eq "Task Scheduler" }
    $serviceItems = $AllItems | Where-Object { $_.Source -eq "Windows Service" }
    
    $itemNumber = 1
    
    # Startup Folder Items
    if ($folderItems.Count -gt 0) {
        Write-Host "====================================================================" -ForegroundColor Cyan
        Write-Host "STARTUP FOLDER ITEMS (" -NoNewline -ForegroundColor Cyan
        Write-Host $folderItems.Count -NoNewline -ForegroundColor White
        Write-Host " found)" -ForegroundColor Cyan
        Write-Host "====================================================================" -ForegroundColor Cyan
        Write-Host ""
        
        foreach ($item in $folderItems) {
            $impactColor = switch ($item.Impact) {
                "High" { "Red" }
                "Medium" { "Yellow" }
                "Low" { "Green" }
                default { "Gray" }
            }
            
            $impactIcon = switch ($item.Impact) {
                "High" { "(HIGH)" }
                "Medium" { "(MED)" }
                "Low" { "(LOW)" }
                default { "(?)" }
            }
            
            Write-Host "[$itemNumber] " -NoNewline -ForegroundColor White
            Write-Host "$($item.Name)" -ForegroundColor White
            Write-Host "    Impact: $impactIcon " -NoNewline
            Write-Host "$($item.Impact)" -NoNewline -ForegroundColor $impactColor
            Write-Host " | Category: $($item.Category) | Scope: $($item.Scope)" -ForegroundColor Gray
            Write-Host "    Target: " -NoNewline -ForegroundColor Gray
            Write-Host "$($item.Command)" -ForegroundColor DarkGray
            Write-Host "    Location: " -NoNewline -ForegroundColor Gray
            Write-Host "$($item.Location)" -ForegroundColor DarkGray
            Write-Host ""
            
            $itemNumber++
        }
    }
    
    # Task Scheduler Items
    if ($taskItems.Count -gt 0) {
        Write-Host "====================================================================" -ForegroundColor Cyan
        Write-Host "TASK SCHEDULER STARTUP ITEMS (" -NoNewline -ForegroundColor Cyan
        Write-Host $taskItems.Count -NoNewline -ForegroundColor White
        Write-Host " found)" -ForegroundColor Cyan
        Write-Host "====================================================================" -ForegroundColor Cyan
        Write-Host ""
        
        foreach ($item in $taskItems) {
            $impactColor = switch ($item.Impact) {
                "High" { "Red" }
                "Medium" { "Yellow" }
                "Low" { "Green" }
                default { "Gray" }
            }
            
            $impactIcon = switch ($item.Impact) {
                "High" { "(HIGH)" }
                "Medium" { "(MED)" }
                "Low" { "(LOW)" }
                default { "(?)" }
            }
            
            Write-Host "[$itemNumber] " -NoNewline -ForegroundColor White
            Write-Host "$($item.Name)" -ForegroundColor White
            Write-Host "    Impact: $impactIcon " -NoNewline
            Write-Host "$($item.Impact)" -NoNewline -ForegroundColor $impactColor
            Write-Host " | Category: $($item.Category) | Trigger: $($item.Type)" -ForegroundColor Gray
            Write-Host "    Command: " -NoNewline -ForegroundColor Gray
            Write-Host "$($item.Command)" -ForegroundColor DarkGray
            Write-Host "    Location: " -NoNewline -ForegroundColor Gray
            Write-Host "$($item.Location)" -ForegroundColor DarkGray
            Write-Host ""
            
            $itemNumber++
        }
    }
    
    # Auto-Start Services (show summary, not all)
    if ($serviceItems.Count -gt 0) {
        # Filter to show only non-Microsoft services
        $nonMSServices = $serviceItems | Where-Object { 
            $_.Command -notmatch "Windows|Microsoft|svchost" -and 
            $_.Name -notmatch "Windows|Microsoft"
        }
        
        Write-Host "====================================================================" -ForegroundColor Cyan
        Write-Host "AUTO-START SERVICES (" -NoNewline -ForegroundColor Cyan
        Write-Host $serviceItems.Count -NoNewline -ForegroundColor White
        Write-Host " total, showing " -NoNewline -ForegroundColor Cyan
        Write-Host $nonMSServices.Count -NoNewline -ForegroundColor White
        Write-Host " non-Microsoft)" -ForegroundColor Cyan
        Write-Host "====================================================================" -ForegroundColor Cyan
        Write-Host ""
        
        if ($nonMSServices.Count -eq 0) {
            Write-Host "  No third-party auto-start services detected" -ForegroundColor Gray
            Write-Host "  (Hiding Windows system services for clarity)" -ForegroundColor DarkGray
            Write-Host ""
        } else {
            foreach ($item in $nonMSServices) {
                $impactIcon = switch ($item.Impact) {
                    "High" { "(HIGH)" }
                    "Medium" { "(MED)" }
                    "Low" { "(LOW)" }
                    default { "(?)" }
                }
                
                Write-Host "[$itemNumber] " -NoNewline -ForegroundColor White
                Write-Host "$($item.Name)" -ForegroundColor White
                Write-Host "    Impact: $impactIcon " -NoNewline
                Write-Host "$($item.Impact)" -NoNewline -ForegroundColor Gray
                Write-Host " | Type: $($item.Type) | Status: $($item.Status)" -ForegroundColor Gray
                Write-Host "    Path: " -NoNewline -ForegroundColor Gray
                Write-Host "$($item.Command)" -ForegroundColor DarkGray
                Write-Host ""
                
                $itemNumber++
            }
        }
    }
}

function Show-OptimizationGuidance {
    <#
    .SYNOPSIS
        Display recommendations with how-to instructions
    #>
    param([array]$Recommendations)
    
    if ($Recommendations.Count -eq 0) {
        Write-Host ""
        Write-Host "====================================================================" -ForegroundColor Green
        Write-Host "           OPTIMIZATION RECOMMENDATIONS" -ForegroundColor Green
        Write-Host "====================================================================" -ForegroundColor Green
        Write-Host ""
        Write-Host "(OK) " -NoNewline -ForegroundColor Green
        Write-Host "Your system is well optimized!" -ForegroundColor White
        Write-Host "  No major optimization opportunities detected." -ForegroundColor Gray
        Write-Host ""
        return
    }
    
    Write-Host ""
    Write-Host "====================================================================" -ForegroundColor Yellow
    Write-Host "           OPTIMIZATION RECOMMENDATIONS" -ForegroundColor Yellow
    Write-Host "====================================================================" -ForegroundColor Yellow
    Write-Host ""
    
    $recNumber = 1
    foreach ($rec in $Recommendations) {
        $priorityColor = switch ($rec.Priority) {
            "HIGH" { "Red" }
            "MEDIUM" { "Yellow" }
            "LOW" { "Green" }
            default { "White" }
        }
        
        Write-Host "[$recNumber] " -NoNewline -ForegroundColor White
        Write-Host "$($rec.Priority) PRIORITY: " -NoNewline -ForegroundColor $priorityColor
        Write-Host "$($rec.Category) ($($rec.Count) items)" -ForegroundColor White
        Write-Host "    (!) " -NoNewline -ForegroundColor Yellow
        Write-Host "$($rec.Description)" -ForegroundColor Gray
        Write-Host ""
        
        Write-Host "    Programs:" -ForegroundColor Cyan
        foreach ($itemName in $rec.Items) {
            Write-Host "      • $itemName" -ForegroundColor White
        }
        Write-Host ""
        
        Write-Host "    (*) Recommendation:" -ForegroundColor Cyan
        Write-Host "    $($rec.Guidance)" -ForegroundColor White
        Write-Host ""
        
        Write-Host "    How to Disable:" -ForegroundColor Cyan
        foreach ($line in $rec.HowToDisable) {
            Write-Host "    $line" -ForegroundColor Gray
        }
        
        Write-Host ""
        Write-Host "====================================================================" -ForegroundColor DarkGray
        Write-Host ""
        
        $recNumber++
    }
}

# ============================================================
# EXPORT FUNCTION
# ============================================================

function Export-ToHTML {
    <#
    .SYNOPSIS
        Generate comprehensive HTML report with embedded CSS
    #>
    param(
        [array]$StartupItems,
        [array]$BootData,
        [array]$Recommendations
    )
    
    $computerName = $env:COMPUTERNAME
    $reportDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    
    # Determine output path
    $documentsPath = [Environment]::GetFolderPath("MyDocuments")
    $fileName = "StartupAnalysis_${computerName}_${timestamp}.html"
    $outputPath = Join-Path $documentsPath $fileName
    
    # Get statistics
    $totalItems = $StartupItems.Count
    $highImpactCount = ($StartupItems | Where-Object { $_.Impact -eq "High" }).Count
    $mediumImpactCount = ($StartupItems | Where-Object { $_.Impact -eq "Medium" }).Count
    $lowImpactCount = ($StartupItems | Where-Object { $_.Impact -eq "Low" }).Count
    
    # Boot performance data
    $lastBoot = Get-CimInstance Win32_OperatingSystem | Select-Object -ExpandProperty LastBootUpTime
    $bootDuration = if ($BootData -and $BootData.Count -gt 0) { $BootData[0].BootDurationSeconds } else { "N/A" }
    
    # Build HTML
    $html = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Startup & Boot Performance Report - $computerName</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            line-height: 1.6;
            color: #333;
            background: #f5f5f5;
            padding: 20px;
        }
        
        .container {
            max-width: 1200px;
            margin: 0 auto;
            background: white;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            border-radius: 8px;
            overflow: hidden;
        }
        
        .header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 40px;
            text-align: center;
        }
        
        .header h1 {
            font-size: 32px;
            margin-bottom: 10px;
        }
        
        .header p {
            font-size: 16px;
            opacity: 0.9;
        }
        
        .content {
            padding: 40px;
        }
        
        .summary-card {
            background: #f8f9fa;
            padding: 30px;
            margin: 20px 0;
            border-left: 4px solid #667eea;
            border-radius: 4px;
        }
        
        .summary-card h2 {
            color: #667eea;
            margin-bottom: 20px;
            font-size: 24px;
        }
        
        .stat-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 20px;
            margin-top: 20px;
        }
        
        .stat-box {
            background: white;
            padding: 20px;
            border-radius: 4px;
            text-align: center;
            box-shadow: 0 1px 3px rgba(0,0,0,0.1);
        }
        
        .stat-box .number {
            font-size: 36px;
            font-weight: bold;
            color: #667eea;
        }
        
        .stat-box .label {
            font-size: 14px;
            color: #666;
            margin-top: 5px;
        }
        
        .stat-box.high-impact .number { color: #f44336; }
        .stat-box.medium-impact .number { color: #ff9800; }
        .stat-box.low-impact .number { color: #4caf50; }
        
        table {
            width: 100%;
            border-collapse: collapse;
            margin: 20px 0;
            background: white;
            box-shadow: 0 1px 3px rgba(0,0,0,0.1);
        }
        
        th {
            background: #667eea;
            color: white;
            padding: 15px;
            text-align: left;
            font-weight: 600;
        }
        
        td {
            padding: 12px 15px;
            border-bottom: 1px solid #e0e0e0;
        }
        
        tr:hover {
            background: #f5f5f5;
        }
        
        .impact-badge {
            display: inline-block;
            padding: 4px 12px;
            border-radius: 12px;
            font-size: 12px;
            font-weight: 600;
            text-transform: uppercase;
        }
        
        .impact-high {
            background: #ffebee;
            color: #c62828;
        }
        
        .impact-medium {
            background: #fff3e0;
            color: #ef6c00;
        }
        
        .impact-low {
            background: #e8f5e9;
            color: #2e7d32;
        }
        
        .impact-unknown {
            background: #f5f5f5;
            color: #757575;
        }
        
        .recommendation {
            background: white;
            padding: 25px;
            margin: 20px 0;
            border-left: 4px solid #ff9800;
            border-radius: 4px;
            box-shadow: 0 1px 3px rgba(0,0,0,0.1);
        }
        
        .recommendation.priority-high {
            border-left-color: #f44336;
        }
        
        .recommendation.priority-medium {
            border-left-color: #ff9800;
        }
        
        .recommendation.priority-low {
            border-left-color: #4caf50;
        }
        
        .recommendation h3 {
            color: #333;
            margin-bottom: 10px;
        }
        
        .recommendation .priority {
            display: inline-block;
            padding: 4px 12px;
            border-radius: 4px;
            font-size: 12px;
            font-weight: 600;
            margin-bottom: 15px;
        }
        
        .priority-high { background: #f44336; color: white; }
        .priority-medium { background: #ff9800; color: white; }
        .priority-low { background: #4caf50; color: white; }
        
        .recommendation ul {
            margin: 15px 0;
            padding-left: 20px;
        }
        
        .recommendation li {
            margin: 8px 0;
        }
        
        .how-to {
            background: #f5f5f5;
            padding: 15px;
            margin-top: 15px;
            border-radius: 4px;
            font-family: 'Courier New', monospace;
            font-size: 13px;
            white-space: pre-line;
        }
        
        .section-title {
            color: #667eea;
            font-size: 28px;
            margin: 40px 0 20px 0;
            padding-bottom: 10px;
            border-bottom: 3px solid #667eea;
        }
        
        .footer {
            background: #333;
            color: white;
            text-align: center;
            padding: 30px;
            margin-top: 40px;
        }
        
        .footer a {
            color: #667eea;
            text-decoration: none;
        }
        
        .footer a:hover {
            text-decoration: underline;
        }
        
        .command-path {
            font-family: 'Courier New', monospace;
            font-size: 12px;
            color: #666;
            word-break: break-all;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>Startup Programs & Boot Performance Analysis</h1>
            <p>Computer: <strong>$computerName</strong> | Report Generated: <strong>$reportDate</strong></p>
        </div>
        
        <div class="content">
            <div class="summary-card">
                <h2>Performance Summary</h2>
                <p><strong>Last Boot:</strong> $($lastBoot.ToString('MMMM dd, yyyy hh:mm:ss tt'))</p>
                <p><strong>Boot Duration:</strong> $bootDuration seconds</p>
                
                <div class="stat-grid">
                    <div class="stat-box">
                        <div class="number">$totalItems</div>
                        <div class="label">Total Startup Items</div>
                    </div>
                    <div class="stat-box high-impact">
                        <div class="number">$highImpactCount</div>
                        <div class="label">High Impact</div>
                    </div>
                    <div class="stat-box medium-impact">
                        <div class="number">$mediumImpactCount</div>
                        <div class="label">Medium Impact</div>
                    </div>
                    <div class="stat-box low-impact">
                        <div class="number">$lowImpactCount</div>
                        <div class="label">Low Impact</div>
                    </div>
                </div>
            </div>
"@

    # Add Startup Folder Items
    $folderItems = $StartupItems | Where-Object { $_.Source -eq "Startup Folder" }
    if ($folderItems.Count -gt 0) {
        $html += @"
            
            <h2 class="section-title">Startup Folder Items ($($folderItems.Count))</h2>
            <table>
                <thead>
                    <tr>
                        <th>Program Name</th>
                        <th>Impact</th>
                        <th>Category</th>
                        <th>Scope</th>
                        <th>Target</th>
                    </tr>
                </thead>
                <tbody>
"@
        foreach ($item in $folderItems) {
            $impactClass = $item.Impact.ToLower()
            $html += @"
                    <tr>
                        <td><strong>$($item.Name)</strong></td>
                        <td><span class="impact-badge impact-$impactClass">$($item.Impact)</span></td>
                        <td>$($item.Category)</td>
                        <td>$($item.Scope)</td>
                        <td class="command-path">$($item.Command)</td>
                    </tr>
"@
        }
        $html += @"
                </tbody>
            </table>
"@
    }

    # Add Task Scheduler Items
    $taskItems = $StartupItems | Where-Object { $_.Source -eq "Task Scheduler" }
    if ($taskItems.Count -gt 0) {
        $html += @"
            
            <h2 class="section-title">Task Scheduler Startup Items ($($taskItems.Count))</h2>
            <table>
                <thead>
                    <tr>
                        <th>Task Name</th>
                        <th>Impact</th>
                        <th>Category</th>
                        <th>Trigger Type</th>
                        <th>Command</th>
                    </tr>
                </thead>
                <tbody>
"@
        foreach ($item in $taskItems) {
            $impactClass = $item.Impact.ToLower()
            $html += @"
                    <tr>
                        <td><strong>$($item.Name)</strong></td>
                        <td><span class="impact-badge impact-$impactClass">$($item.Impact)</span></td>
                        <td>$($item.Category)</td>
                        <td>$($item.Type)</td>
                        <td class="command-path">$($item.Command)</td>
                    </tr>
"@
        }
        $html += @"
                </tbody>
            </table>
"@
    }

    # Add Recommendations
    if ($Recommendations.Count -gt 0) {
        $html += @"
            
            <h2 class="section-title">Optimization Recommendations</h2>
"@
        foreach ($rec in $Recommendations) {
            $priorityClass = $rec.Priority.ToLower()
            $html += @"
            
            <div class="recommendation priority-$priorityClass">
                <span class="priority priority-$priorityClass">$($rec.Priority) PRIORITY</span>
                <h3>$($rec.Category) ($($rec.Count) items)</h3>
                <p><strong>Description:</strong> $($rec.Description)</p>
                
                <p><strong>Affected Programs:</strong></p>
                <ul>
"@
            foreach ($itemName in $rec.Items) {
                $html += "                    <li>$itemName</li>`n"
            }
            
            $html += @"
                </ul>
                
                <p><strong>Recommendation:</strong> $($rec.Guidance)</p>
                
                <div class="how-to">
                    <strong>How to Disable:</strong>
"@
            foreach ($line in $rec.HowToDisable) {
                $html += "$line`n"
            }
            
            $html += @"
                </div>
            </div>
"@
        }
    } else {
        $html += @"
            
            <h2 class="section-title">Optimization Recommendations</h2>
            <div class="summary-card">
                <p style="color: #4caf50; font-size: 18px;"><strong>Your system is well optimized!</strong></p>
                <p>No major optimization opportunities detected. Your startup configuration is already in good shape.</p>
            </div>
"@
    }

    # Close HTML
    $html += @"
        </div>
        
        <div class="footer">
            <p><strong>Generated by SouliTEK Startup & Boot Time Analyzer</strong></p>
            <p><a href="https://www.soulitek.co.il" target="_blank">www.soulitek.co.il</a></p>
            <p style="margin-top: 10px; font-size: 12px; opacity: 0.7;">© 2025 SouliTEK - All Rights Reserved</p>
        </div>
    </div>
</body>
</html>
"@

    # Save HTML file
    try {
        $html | Out-File -FilePath $outputPath -Encoding UTF8
        return $outputPath
    } catch {
        Write-Warning "Failed to save HTML report: $_"
        return $null
    }
}

# ============================================================
# MAIN MENU & EXECUTION
# ============================================================

function Show-MainMenu {
    <#
    .SYNOPSIS
        Display main menu
    #>
    Clear-Host
    Write-Host ""
    Write-Host "====================================================================" -ForegroundColor Cyan
    Write-Host "      STARTUP PROGRAMS & BOOT TIME ANALYZER" -ForegroundColor Cyan
    Write-Host "      Coded by: Soulitek.co.il" -ForegroundColor Cyan
    Write-Host "====================================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "[1] Analyze All Startup Items (Full Scan)" -ForegroundColor White
    Write-Host "[2] View Boot Time History & Trends" -ForegroundColor White
    Write-Host "[3] View Optimization Recommendations" -ForegroundColor White
    Write-Host "[4] Export Full Report to HTML" -ForegroundColor White
    Write-Host "[5] Exit" -ForegroundColor White
    Write-Host ""
    Write-Host "Select an option (1-5): " -NoNewline -ForegroundColor Yellow
}

function Invoke-FullAnalysis {
    <#
    .SYNOPSIS
        Option 1: Perform full startup analysis
    #>
    Clear-Host
    Write-Host ""
    Write-Host "====================================================================" -ForegroundColor Cyan
    Write-Host "      ANALYZING STARTUP ITEMS..." -ForegroundColor Cyan
    Write-Host "====================================================================" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "Scanning startup sources..." -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "  [*] Startup folders..." -NoNewline
    $folderItems = Get-StartupFolderItems
    Write-Host " Found $($folderItems.Count)" -ForegroundColor Green
    
    Write-Host "  [*] Task Scheduler..." -NoNewline
    $taskItems = Get-TaskSchedulerStartupItems
    Write-Host " Found $($taskItems.Count)" -ForegroundColor Green
    
    Write-Host "  [*] Auto-start services..." -NoNewline
    $serviceItems = Get-AutoStartServices -ExcludeMicrosoft
    Write-Host " Found $($serviceItems.Count) (non-Microsoft)" -ForegroundColor Green
    
    Write-Host ""
    Write-Host "Analyzing performance impact..." -ForegroundColor Cyan
    
    # Combine all items
    $Global:AllStartupItems = @()
    $Global:AllStartupItems += $folderItems
    $Global:AllStartupItems += $taskItems
    $Global:AllStartupItems += $serviceItems
    
    # Enrich with performance ratings
    $counter = 0
    foreach ($item in $Global:AllStartupItems) {
        $counter++
        Write-Progress -Activity "Analyzing startup items" -Status "Processing item $counter of $($Global:AllStartupItems.Count)" -PercentComplete (($counter / $Global:AllStartupItems.Count) * 100)
        
        $rating = Get-PerformanceImpactRating -ProgramName $item.Name -CommandPath $item.Command
        $item.Impact = $rating.Impact
        $item.Category = $rating.Category
    }
    Write-Progress -Activity "Analyzing startup items" -Completed
    
    Write-Host ""
    Write-Host "Checking boot performance..." -ForegroundColor Cyan
    
    # Get boot performance
    $Global:LastBootData = Get-BootPerformanceFromEventLog -MaxEvents 10
    if ($Global:LastBootData -and $Global:LastBootData.Count -gt 0) {
        Write-Host "  (OK) Boot performance data retrieved from Event Log" -ForegroundColor Green
        # Save to history
        Save-BootTimeToHistory -BootTime $Global:LastBootData[0].TimeGenerated -DurationSeconds $Global:LastBootData[0].BootDurationSeconds -Source "EventLog"
    } else {
        Write-Host "  (!) Boot performance data not available" -ForegroundColor Yellow
        Write-Host "      To enable: wevtutil sl Microsoft-Windows-Diagnostics-Performance/Operational /e:true" -ForegroundColor Gray
    }
    
    Write-Host ""
    Write-Host "Analysis complete!" -ForegroundColor Green
    Start-Sleep -Seconds 2
    
    # Display results
    Show-PerformanceSummary -BootData $Global:LastBootData -StartupItems $Global:AllStartupItems
    Show-StartupItemsByCategory -AllItems $Global:AllStartupItems
    
    Write-Host ""
    Write-Host "Press any key to return to menu..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Show-BootTimeHistory {
    <#
    .SYNOPSIS
        Option 2: Display boot time history and trends
    #>
    Clear-Host
    Write-Host ""
    Write-Host "====================================================================" -ForegroundColor Cyan
    Write-Host "           BOOT TIME HISTORY (Last 30 Boots)" -ForegroundColor Cyan
    Write-Host "====================================================================" -ForegroundColor Cyan
    Write-Host ""
    
    $history = Get-BootTimeHistory
    
    if ($history.Count -eq 0) {
        Write-Host "No boot time history available yet." -ForegroundColor Yellow
        Write-Host ""
        Write-Host "History will be built as you run analyses." -ForegroundColor Gray
        Write-Host "Boot time data is collected from Windows Event Logs." -ForegroundColor Gray
        Write-Host ""
        Write-Host "Press any key to return to menu..." -ForegroundColor Gray
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        return
    }
    
    # Sort by date (newest first)
    $history = $history | Sort-Object -Property { [DateTime]$_.BootTime } -Descending
    
    # Display table
    Write-Host "Date & Time              | Duration | Source" -ForegroundColor White
    Write-Host "-------------------------+----------+------------" -ForegroundColor DarkGray
    
    $previousDuration = $null
    foreach ($record in $history) {
        $bootDateTime = [DateTime]$record.BootTime
        $dateStr = $bootDateTime.ToString("yyyy-MM-dd HH:mm:ss")
        $duration = $record.DurationSeconds
        
        # Calculate trend
        $trendIndicator = ""
        if ($null -ne $previousDuration) {
            $diff = $duration - $previousDuration
            if ($diff -gt 3) {
                $absDiff = [math]::Abs($diff)
                $trendIndicator = "+" + $absDiff + "s"
            } elseif ($diff -lt -3) {
                $absDiff = [math]::Abs($diff)
                $trendIndicator = "-" + $absDiff + "s"
            } else {
                $trendIndicator = "stable"
            }
        }
        
        $durationColor = if ($duration -lt 30) { "Green" } elseif ($duration -lt 60) { "Yellow" } else { "Red" }
        
        Write-Host "$dateStr" -NoNewline -ForegroundColor White
        Write-Host " - " -NoNewline -ForegroundColor DarkGray
        Write-Host "$duration sec " -NoNewline -ForegroundColor $durationColor
        Write-Host " - " -NoNewline -ForegroundColor DarkGray
        Write-Host "$($record.Source)" -NoNewline -ForegroundColor Gray
        if ($trendIndicator) {
            Write-Host "  $trendIndicator" -ForegroundColor Gray
        } else {
            Write-Host ""
        }
        
        $previousDuration = $duration
    }
    
    Write-Host ""
    Write-Host "Statistics:" -ForegroundColor Cyan
    
    $durations = $history | Select-Object -ExpandProperty DurationSeconds
    $avgDuration = [math]::Round(($durations | Measure-Object -Average).Average, 1)
    $minDuration = ($durations | Measure-Object -Minimum).Minimum
    $maxDuration = ($durations | Measure-Object -Maximum).Maximum
    $currentDuration = $durations[0]
    
    Write-Host "  Average: " -NoNewline
    Write-Host "$avgDuration seconds" -ForegroundColor White
    Write-Host "  Best: " -NoNewline
    Write-Host "$minDuration seconds " -NoNewline -ForegroundColor Green
    $bestDate = ($history | Where-Object { $_.DurationSeconds -eq $minDuration } | Select-Object -First 1).BootTime
    Write-Host "($([DateTime]$bestDate | Get-Date -Format 'yyyy-MM-dd'))" -ForegroundColor Gray
    Write-Host "  Worst: " -NoNewline
    Write-Host "$maxDuration seconds " -NoNewline -ForegroundColor Red
    $worstDate = ($history | Where-Object { $_.DurationSeconds -eq $maxDuration } | Select-Object -First 1).BootTime
    Write-Host "($([DateTime]$worstDate | Get-Date -Format 'yyyy-MM-dd'))" -ForegroundColor Gray
    Write-Host "  Current: " -NoNewline
    $currentColor = if ($currentDuration -lt $avgDuration) { "Green" } else { "Yellow" }
    Write-Host "$currentDuration seconds " -NoNewline -ForegroundColor $currentColor
    $comparison = if ($currentDuration -lt $avgDuration) { "Better than average" } else { "Slower than average" }
    Write-Host "($comparison)" -ForegroundColor Gray
    
    Write-Host ""
    Write-Host "Trend Analysis:" -ForegroundColor Cyan
    
    # Compare last 7 days to overall average
    if ($history.Count -ge 7) {
        $last7 = $history | Select-Object -First 7
        $last7Avg = [math]::Round(($last7 | Select-Object -ExpandProperty DurationSeconds | Measure-Object -Average).Average, 1)
        $diff = [math]::Round($last7Avg - $avgDuration, 1)
        
        Write-Host "  Last 7 boots: " -NoNewline
        if ($diff -lt -5) {
            $absDiffTrend = [math]::Abs($diff)
            Write-Host "Improving - $absDiffTrend seconds faster than average" -ForegroundColor Green
        } elseif ($diff -gt 5) {
            Write-Host ("Degrading - " + $diff + " seconds slower than average") -ForegroundColor Red
        } else {
            Write-Host "Stable compared to average" -ForegroundColor White
        }
    }
    
    if ($history.Count -ge 30) {
        Write-Host "  Last 30 boots: full history available" -ForegroundColor White
    } else {
        Write-Host "  Total boots tracked: $($history.Count) (need 30 for full trend analysis)" -ForegroundColor Gray
    }
    
    # Warning if boot time suddenly increased
    if ($history.Count -ge 5) {
        $recentAvg = [math]::Round(($history | Select-Object -First 3 | Select-Object -ExpandProperty DurationSeconds | Measure-Object -Average).Average, 1)
        $olderAvg = [math]::Round(($history | Select-Object -Skip 3 -First 5 | Select-Object -ExpandProperty DurationSeconds | Measure-Object -Average).Average, 1)
        $increase = [math]::Round($recentAvg - $olderAvg, 1)
        
        if ($increase -gt 10) {
            Write-Host ""
            Write-Host "(!) Warning: " -NoNewline -ForegroundColor Red
            Write-Host "Boot time increased by $increase seconds recently" -ForegroundColor Yellow
            Write-Host "   Consider running optimization analysis (Option 1)" -ForegroundColor Gray
        }
    }
    
    Write-Host ""
    Write-Host "Press any key to return to menu..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}


function Show-OptimizationRecommendations {
    <#
    .SYNOPSIS
        Option 4: Display optimization recommendations
    #>
    Clear-Host
    
    # Check if analysis has been run
    if ($Global:AllStartupItems.Count -eq 0) {
        Write-Host ""
        Write-Host "====================================================================" -ForegroundColor Yellow
        Write-Host "           OPTIMIZATION RECOMMENDATIONS" -ForegroundColor Yellow
        Write-Host "====================================================================" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "No startup items loaded yet." -ForegroundColor Yellow
        Write-Host "Please run 'Analyze All Startup Items' (Option 1) first." -ForegroundColor Gray
        Write-Host ""
        Write-Host "Press any key to return to menu..." -ForegroundColor Gray
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        return
    }
    
    # Generate recommendations
    $recommendations = Get-OptimizationRecommendations -AllStartupItems $Global:AllStartupItems
    
    Show-OptimizationGuidance -Recommendations $recommendations
    
    Write-Host "Press any key to return to menu..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Invoke-ExportReport {
    <#
    .SYNOPSIS
        Option 5: Export HTML report
    #>
    Clear-Host
    Write-Host ""
    Write-Host "====================================================================" -ForegroundColor Cyan
    Write-Host "           EXPORT FULL REPORT TO HTML" -ForegroundColor Cyan
    Write-Host "====================================================================" -ForegroundColor Cyan
    Write-Host ""
    
    # Check if analysis has been run
    if ($Global:AllStartupItems.Count -eq 0) {
        Write-Host "No startup items loaded yet." -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Would you like to run analysis now? (Y/N): " -NoNewline -ForegroundColor Yellow
        $response = Read-Host
        
        if ($response -eq "Y" -or $response -eq "y") {
            Invoke-FullAnalysis
        } else {
            return
        }
    }
    
    Write-Host "Generating comprehensive HTML report..." -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "  (OK) Performance summary" -ForegroundColor Green
    Write-Host "  (OK) Boot time history" -ForegroundColor Green
    Write-Host "  (OK) Startup items ($($Global:AllStartupItems.Count) total)" -ForegroundColor Green
    
    # Generate recommendations
    $recommendations = Get-OptimizationRecommendations -AllStartupItems $Global:AllStartupItems
    Write-Host "  (OK) Optimization recommendations ($($recommendations.Count) found)" -ForegroundColor Green
    Write-Host "  (OK) Embedded styling" -ForegroundColor Green
    
    Write-Host ""
    Write-Host "Creating HTML file..." -ForegroundColor Cyan
    
    $outputPath = Export-ToHTML -StartupItems $Global:AllStartupItems -BootData $Global:LastBootData -Recommendations $recommendations
    
    if ($outputPath) {
        Write-Host ""
        Write-Host "Report saved successfully!" -ForegroundColor Green
        Write-Host ""
        Write-Host "Report saved to:" -ForegroundColor Cyan
        Write-Host "$outputPath" -ForegroundColor White
        Write-Host ""
        Write-Host "[O] Open in browser" -ForegroundColor White
        Write-Host "[C] Copy path to clipboard" -ForegroundColor White
        Write-Host "[Enter] Return to menu" -ForegroundColor Gray
        Write-Host ""
        Write-Host "Your choice: " -NoNewline -ForegroundColor Yellow
        
        $choice = Read-Host
        
        switch ($choice.ToUpper()) {
            "O" {
                try {
                    Start-Process $outputPath
                    Write-Host "Opening report in browser..." -ForegroundColor Green
                    Start-Sleep -Seconds 2
                } catch {
                    Write-Warning "Failed to open browser: $_"
                    Start-Sleep -Seconds 2
                }
            }
            "C" {
                try {
                    Set-Clipboard -Value $outputPath
                    Write-Host "Path copied to clipboard!" -ForegroundColor Green
                    Start-Sleep -Seconds 2
                } catch {
                    Write-Warning "Failed to copy to clipboard: $_"
                    Start-Sleep -Seconds 2
                }
            }
        }
    } else {
        Write-Host ""
        Write-Host "(X) Failed to create HTML report." -ForegroundColor Red
        Write-Host ""
        Write-Host "Press any key to return to menu..." -ForegroundColor Gray
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
}

# ============================================================
# MAIN EXECUTION LOOP
# ============================================================

# Display header
Clear-Host
Write-SouliTEKHeader
Write-Host ""
Write-Host "Welcome to the Startup Programs & Boot Time Analyzer!" -ForegroundColor Cyan
Write-Host ""
Write-Host "This tool will help you:" -ForegroundColor White
Write-Host "  • Scan Startup Folders, Task Scheduler, and Services" -ForegroundColor Gray
Write-Host "  • Analyze boot performance and track trends" -ForegroundColor Gray
Write-Host "  • Get optimization recommendations" -ForegroundColor Gray
Write-Host "  • Export detailed HTML reports" -ForegroundColor Gray
Write-Host ""
Write-Host "Press any key to continue..." -ForegroundColor Yellow
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

# Main menu loop
while ($true) {
    Show-MainMenu
    $choice = Read-Host
    
    switch ($choice) {
        "1" { Invoke-FullAnalysis }
        "2" { Show-BootTimeHistory }
        "3" { Show-OptimizationRecommendations }
        "4" { Invoke-ExportReport }
        "5" {
            Clear-Host
            Write-Host ""
            Write-Host "Thank you for using SouliTEK Startup & Boot Time Analyzer!" -ForegroundColor Cyan
            Write-Host "Visit www.soulitek.co.il for more professional IT solutions." -ForegroundColor Gray
            Write-Host ""
            
            exit
        }
        default {
            Write-Host ""
            Write-Host "Invalid option. Please select 1-5." -ForegroundColor Red
            Start-Sleep -Seconds 2
        }
    }
}

