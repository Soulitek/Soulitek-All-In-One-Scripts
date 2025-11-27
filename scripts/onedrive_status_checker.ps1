# ============================================================
# SouliTEK All-In-One Scripts - OneDrive Status Checker
# ============================================================
# 
# Coded by: Soulitek.co.il
# IT Solutions for your business
# 
# (C) 2025 SouliTEK - All Rights Reserved
# Website: www.soulitek.co.il
# 
# This tool checks OneDrive sync status by examining Registry,
# process status, and logs to identify sync issues and errors.
# 
# ============================================================

#Requires -Version 5.1

$Script:Version = "1.0.0"
$Script:ToolName = "OneDrive Status Checker"

# ============================================================
# IMPORT COMMON MODULE
# ============================================================

$Script:ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$Script:RootPath = Split-Path -Parent $Script:ScriptPath
$CommonPath = Join-Path $Script:RootPath "modules\SouliTEK-Common.ps1"

if (Test-Path $CommonPath) {
    . $CommonPath
} else {
    Write-Warning "SouliTEK Common Functions not found at: $CommonPath"
}

# ============================================================
# CONFIGURATION
# ============================================================

$Script:OneDriveResults = @()
$Script:OneDriveAccounts = @()
$Script:SyncErrors = @()
$Script:OneDriveLogsPath = "$env:LOCALAPPDATA\Microsoft\OneDrive\logs"
$Script:OneDriveBusinessLogsPath = "$env:LOCALAPPDATA\Microsoft\OneDrive\logs\Business1"
$Script:OneDrivePersonalLogsPath = "$env:LOCALAPPDATA\Microsoft\OneDrive\logs\Personal"

# Status code mappings
$Script:StatusCodeMap = @{
    0 = @{ Status = "Not Installed"; Color = "Red"; Description = "OneDrive is not installed on this system" }
    1 = @{ Status = "Not Configured"; Color = "Yellow"; Description = "OneDrive is installed but not configured" }
    2 = @{ Status = "Not Running"; Color = "Yellow"; Description = "OneDrive process is not running" }
    3 = @{ Status = "Syncing"; Color = "Cyan"; Description = "OneDrive is currently syncing files" }
    4 = @{ Status = "Up To Date"; Color = "Green"; Description = "OneDrive is fully synced - all files are up to date" }
    5 = @{ Status = "Paused"; Color = "Yellow"; Description = "OneDrive sync is paused" }
    6 = @{ Status = "Error"; Color = "Red"; Description = "OneDrive has sync errors" }
    7 = @{ Status = "Quota Exceeded"; Color = "Red"; Description = "OneDrive storage quota has been exceeded" }
}

# Common sync error patterns
$Script:ErrorPatterns = @(
    @{ Pattern = "Error\s*0x"; Description = "Sync Error Code" }
    @{ Pattern = "Upload blocked"; Description = "File upload is blocked" }
    @{ Pattern = "Download blocked"; Description = "File download is blocked" }
    @{ Pattern = "quota exceeded"; Description = "Storage quota exceeded" }
    @{ Pattern = "couldn't be synced"; Description = "File sync failure" }
    @{ Pattern = "sync conflict"; Description = "File sync conflict detected" }
    @{ Pattern = "access denied"; Description = "Access denied to file or folder" }
    @{ Pattern = "file is locked"; Description = "File is locked by another process" }
    @{ Pattern = "invalid characters"; Description = "File name contains invalid characters" }
    @{ Pattern = "path too long"; Description = "File path exceeds maximum length" }
    @{ Pattern = "authentication"; Description = "Authentication issue" }
    @{ Pattern = "sign.?in"; Description = "Sign-in required" }
    @{ Pattern = "connection"; Description = "Connection issue" }
    @{ Pattern = "network"; Description = "Network connectivity problem" }
)

# ============================================================
# HELPER FUNCTIONS
# ============================================================

# Show-Header function - wrapper using Show-SouliTEKHeader from common module
function Show-Header {
    param([string]$Title = "ONEDRIVE STATUS CHECKER", [ConsoleColor]$Color = 'Cyan')
    
    Show-SouliTEKHeader -Title $Title -Color $Color -ClearHost -ShowBanner
}

function Test-OneDriveInstalled {
    <#
    .SYNOPSIS
        Checks if OneDrive is installed on the system.
    #>
    
    $oneDrivePaths = @(
        "$env:LOCALAPPDATA\Microsoft\OneDrive\OneDrive.exe",
        "$env:ProgramFiles\Microsoft OneDrive\OneDrive.exe",
        "${env:ProgramFiles(x86)}\Microsoft OneDrive\OneDrive.exe"
    )
    
    foreach ($path in $oneDrivePaths) {
        if (Test-Path $path) {
            return @{
                Installed = $true
                Path = $path
                Version = (Get-Item $path).VersionInfo.ProductVersion
            }
        }
    }
    
    # Check registry for installation
    $regPaths = @(
        "HKCU:\Software\Microsoft\OneDrive",
        "HKLM:\SOFTWARE\Microsoft\OneDrive"
    )
    
    foreach ($regPath in $regPaths) {
        if (Test-Path $regPath) {
            try {
                $oneDrivePath = (Get-ItemProperty $regPath -ErrorAction SilentlyContinue).OneDriveTrigger
                if ($oneDrivePath -and (Test-Path $oneDrivePath)) {
                    return @{
                        Installed = $true
                        Path = $oneDrivePath
                        Version = (Get-Item $oneDrivePath -ErrorAction SilentlyContinue).VersionInfo.ProductVersion
                    }
                }
            }
            catch {}
        }
    }
    
    return @{ Installed = $false; Path = $null; Version = $null }
}

function Get-OneDriveProcess {
    <#
    .SYNOPSIS
        Gets the OneDrive process information.
    #>
    
    $processes = Get-Process -Name "OneDrive" -ErrorAction SilentlyContinue
    
    if ($processes) {
        return @{
            Running = $true
            Processes = $processes
            Count = $processes.Count
            Memory = ($processes | Measure-Object -Property WorkingSet64 -Sum).Sum
            CPU = ($processes | Measure-Object -Property CPU -Sum).Sum
        }
    }
    
    return @{
        Running = $false
        Processes = @()
        Count = 0
        Memory = 0
        CPU = 0
    }
}

function Get-OneDriveAccounts {
    <#
    .SYNOPSIS
        Retrieves all configured OneDrive accounts from registry.
    #>
    
    $accounts = @()
    
    # Personal and Business accounts path
    $accountsPath = "HKCU:\Software\Microsoft\OneDrive\Accounts"
    
    if (Test-Path $accountsPath) {
        $accountFolders = Get-ChildItem $accountsPath -ErrorAction SilentlyContinue
        
        foreach ($folder in $accountFolders) {
            try {
                $props = Get-ItemProperty $folder.PSPath -ErrorAction SilentlyContinue
                
                $accountType = switch ($folder.PSChildName) {
                    "Personal" { "Personal" }
                    "Business1" { "Business" }
                    "Business2" { "Business" }
                    default { 
                        if ($folder.PSChildName -match "^Business") { "Business" }
                        else { "Unknown" }
                    }
                }
                
                $account = [PSCustomObject]@{
                    AccountType = $accountType
                    AccountName = $folder.PSChildName
                    UserEmail = $props.UserEmail
                    UserFolder = $props.UserFolder
                    UserSID = $props.UserSID
                    ServiceEndpointUri = $props.ServiceEndpointUri
                    TenantId = $props.SPOResourceId
                    LastSignInTime = $null
                    SyncEnabled = $null
                }
                
                # Try to get additional info
                if ($props.LastSignInTime) {
                    try {
                        $account.LastSignInTime = [DateTime]::FromFileTime($props.LastSignInTime)
                    }
                    catch {}
                }
                
                $accounts += $account
            }
            catch {
                Write-SouliTEKWarning "Failed to read account info for $($folder.PSChildName)"
            }
        }
    }
    
    return $accounts
}

function Get-OneDriveSyncStatus {
    <#
    .SYNOPSIS
        Determines the current sync status of OneDrive.
    #>
    param(
        [string]$AccountName = ""
    )
    
    $statusInfo = @{
        StatusCode = 0
        Status = "Unknown"
        Details = @()
        LastSync = $null
        FilesInSync = 0
        PendingFiles = 0
    }
    
    # Check if OneDrive is installed
    $installInfo = Test-OneDriveInstalled
    if (-not $installInfo.Installed) {
        $statusInfo.StatusCode = 0
        $statusInfo.Status = "Not Installed"
        return $statusInfo
    }
    
    # Check if OneDrive process is running
    $processInfo = Get-OneDriveProcess
    if (-not $processInfo.Running) {
        $statusInfo.StatusCode = 2
        $statusInfo.Status = "Not Running"
        return $statusInfo
    }
    
    # Try to get status from registry
    $statusRegPaths = @(
        "HKCU:\Software\Microsoft\OneDrive",
        "HKCU:\Software\Microsoft\OneDrive\Accounts\$AccountName"
    )
    
    foreach ($regPath in $statusRegPaths) {
        if (Test-Path $regPath) {
            try {
                $props = Get-ItemProperty $regPath -ErrorAction SilentlyContinue
                
                # Check for sync status indicators
                if ($props.EnabledForUser -eq 0) {
                    $statusInfo.StatusCode = 5
                    $statusInfo.Status = "Paused"
                    $statusInfo.Details += "Sync is disabled by user"
                }
                
                if ($props.SilentBusinessConfigCompleted) {
                    $statusInfo.Details += "Business configuration completed"
                }
            }
            catch {}
        }
    }
    
    # Check sync status files
    $syncStatusFiles = @(
        "$env:LOCALAPPDATA\Microsoft\OneDrive\settings\Personal\global.ini",
        "$env:LOCALAPPDATA\Microsoft\OneDrive\settings\Business1\global.ini"
    )
    
    foreach ($statusFile in $syncStatusFiles) {
        if (Test-Path $statusFile) {
            try {
                $content = Get-Content $statusFile -Raw -ErrorAction SilentlyContinue
                if ($content -match "syncEngineState\s*=\s*(\d+)") {
                    $syncState = [int]$Matches[1]
                    switch ($syncState) {
                        0 { $statusInfo.Details += "Sync engine idle" }
                        1 { 
                            $statusInfo.StatusCode = 3
                            $statusInfo.Status = "Syncing"
                            $statusInfo.Details += "Sync in progress"
                        }
                        2 { 
                            $statusInfo.StatusCode = 4
                            $statusInfo.Status = "Up To Date"
                            $statusInfo.Details += "All files synced"
                        }
                    }
                }
            }
            catch {}
        }
    }
    
    # If still unknown, assume running = syncing/up to date
    if ($statusInfo.StatusCode -eq 0 -and $processInfo.Running) {
        $statusInfo.StatusCode = 4
        $statusInfo.Status = "Up To Date"
        $statusInfo.Details += "OneDrive is running (assumed synced)"
    }
    
    return $statusInfo
}

function Get-OneDriveSyncErrors {
    <#
    .SYNOPSIS
        Scans OneDrive logs for sync errors.
    #>
    
    $errors = @()
    $logPaths = @($Script:OneDriveLogsPath, $Script:OneDriveBusinessLogsPath, $Script:OneDrivePersonalLogsPath)
    
    foreach ($logPath in $logPaths) {
        if (Test-Path $logPath) {
            try {
                # Get recent log files (last 7 days)
                $logFiles = Get-ChildItem -Path $logPath -Filter "*.txt" -ErrorAction SilentlyContinue | 
                            Where-Object { $_.LastWriteTime -gt (Get-Date).AddDays(-7) } |
                            Sort-Object LastWriteTime -Descending |
                            Select-Object -First 10
                
                foreach ($logFile in $logFiles) {
                    try {
                        # Read last 1000 lines of each log file
                        $content = Get-Content $logFile.FullName -Tail 1000 -ErrorAction SilentlyContinue
                        
                        foreach ($line in $content) {
                            foreach ($errorPattern in $Script:ErrorPatterns) {
                                if ($line -match $errorPattern.Pattern) {
                                    $errors += [PSCustomObject]@{
                                        Timestamp = $logFile.LastWriteTime
                                        Source = $logFile.Name
                                        ErrorType = $errorPattern.Description
                                        Message = $line.Trim().Substring(0, [Math]::Min(200, $line.Length))
                                        FullPath = $logFile.FullName
                                    }
                                    break  # One match per line is enough
                                }
                            }
                        }
                    }
                    catch {}
                }
            }
            catch {}
        }
    }
    
    # Remove duplicates and sort by timestamp
    $errors = $errors | Sort-Object Timestamp -Descending | Select-Object -First 50
    
    return $errors
}

function Get-OneDriveFolderInfo {
    <#
    .SYNOPSIS
        Gets information about OneDrive folders.
    #>
    
    $folderInfo = @()
    
    # Get OneDrive folder paths from registry
    $accountsPath = "HKCU:\Software\Microsoft\OneDrive\Accounts"
    
    if (Test-Path $accountsPath) {
        $accountFolders = Get-ChildItem $accountsPath -ErrorAction SilentlyContinue
        
        foreach ($folder in $accountFolders) {
            try {
                $props = Get-ItemProperty $folder.PSPath -ErrorAction SilentlyContinue
                
                if ($props.UserFolder -and (Test-Path $props.UserFolder)) {
                    $folderPath = $props.UserFolder
                    
                    # Get folder statistics
                    $stats = Get-ChildItem -Path $folderPath -Recurse -File -ErrorAction SilentlyContinue | 
                             Measure-Object -Property Length -Sum
                    
                    $folderInfo += [PSCustomObject]@{
                        AccountType = $folder.PSChildName
                        FolderPath = $folderPath
                        FileCount = $stats.Count
                        TotalSize = $stats.Sum
                        TotalSizeFormatted = Format-SouliTEKFileSize ($stats.Sum)
                        LastModified = (Get-Item $folderPath).LastWriteTime
                    }
                }
            }
            catch {}
        }
    }
    
    # Also check common OneDrive paths
    $commonPaths = @(
        "$env:USERPROFILE\OneDrive",
        "$env:USERPROFILE\OneDrive - Personal",
        "$env:OneDrive",
        "$env:OneDriveConsumer",
        "$env:OneDriveCommercial"
    )
    
    foreach ($path in $commonPaths) {
        if ($path -and (Test-Path $path)) {
            # Check if already in list
            if ($folderInfo.FolderPath -notcontains $path) {
                try {
                    $stats = Get-ChildItem -Path $path -Recurse -File -ErrorAction SilentlyContinue | 
                             Measure-Object -Property Length -Sum
                    
                    $folderInfo += [PSCustomObject]@{
                        AccountType = "Detected"
                        FolderPath = $path
                        FileCount = $stats.Count
                        TotalSize = $stats.Sum
                        TotalSizeFormatted = Format-SouliTEKFileSize ($stats.Sum)
                        LastModified = (Get-Item $path).LastWriteTime
                    }
                }
                catch {}
            }
        }
    }
    
    return $folderInfo
}

function Invoke-FullScan {
    <#
    .SYNOPSIS
        Performs a full OneDrive status scan.
    #>
    
    Show-Header "ONEDRIVE STATUS CHECKER - FULL SCAN"
    
    Write-SouliTEKResult "Starting OneDrive status scan..." -Level INFO
    Write-Host ""
    
    $Script:OneDriveResults = @()
    $Script:OneDriveAccounts = @()
    $Script:SyncErrors = @()
    
    # Step 1: Check installation
    Write-SouliTEKResult "Checking OneDrive installation..." -Level INFO
    $installInfo = Test-OneDriveInstalled
    
    if ($installInfo.Installed) {
        Write-SouliTEKSuccess "OneDrive is installed"
        Write-Host "  Path: $($installInfo.Path)" -ForegroundColor Gray
        Write-Host "  Version: $($installInfo.Version)" -ForegroundColor Gray
        
        $Script:OneDriveResults += [PSCustomObject]@{
            Category = "Installation"
            Item = "OneDrive"
            Status = "Installed"
            Details = "Version: $($installInfo.Version)"
            Path = $installInfo.Path
        }
    } else {
        Write-SouliTEKError "OneDrive is NOT installed"
        $Script:OneDriveResults += [PSCustomObject]@{
            Category = "Installation"
            Item = "OneDrive"
            Status = "Not Installed"
            Details = "OneDrive executable not found"
            Path = ""
        }
        Write-Host ""
        Wait-SouliTEKKeyPress
        return
    }
    
    Write-Host ""
    
    # Step 2: Check process
    Write-SouliTEKResult "Checking OneDrive process..." -Level INFO
    $processInfo = Get-OneDriveProcess
    
    if ($processInfo.Running) {
        Write-SouliTEKSuccess "OneDrive is running"
        Write-Host "  Processes: $($processInfo.Count)" -ForegroundColor Gray
        Write-Host "  Memory: $(Format-SouliTEKFileSize $processInfo.Memory)" -ForegroundColor Gray
        
        $Script:OneDriveResults += [PSCustomObject]@{
            Category = "Process"
            Item = "OneDrive.exe"
            Status = "Running"
            Details = "Memory: $(Format-SouliTEKFileSize $processInfo.Memory), Processes: $($processInfo.Count)"
            Path = ""
        }
    } else {
        Write-SouliTEKWarning "OneDrive is NOT running"
        $Script:OneDriveResults += [PSCustomObject]@{
            Category = "Process"
            Item = "OneDrive.exe"
            Status = "Not Running"
            Details = "OneDrive process not found"
            Path = ""
        }
    }
    
    Write-Host ""
    
    # Step 3: Get accounts
    Write-SouliTEKResult "Scanning configured accounts..." -Level INFO
    $Script:OneDriveAccounts = Get-OneDriveAccounts
    
    if ($Script:OneDriveAccounts.Count -gt 0) {
        Write-SouliTEKSuccess "Found $($Script:OneDriveAccounts.Count) configured account(s)"
        foreach ($account in $Script:OneDriveAccounts) {
            Write-Host "  [$($account.AccountType)] $($account.UserEmail)" -ForegroundColor Gray
            
            $Script:OneDriveResults += [PSCustomObject]@{
                Category = "Account"
                Item = $account.AccountType
                Status = "Configured"
                Details = "Email: $($account.UserEmail)"
                Path = $account.UserFolder
            }
        }
    } else {
        Write-SouliTEKWarning "No OneDrive accounts configured"
        $Script:OneDriveResults += [PSCustomObject]@{
            Category = "Account"
            Item = "None"
            Status = "Not Configured"
            Details = "No OneDrive accounts found in registry"
            Path = ""
        }
    }
    
    Write-Host ""
    
    # Step 4: Check sync status
    Write-SouliTEKResult "Checking sync status..." -Level INFO
    $syncStatus = Get-OneDriveSyncStatus
    
    $statusColor = switch ($syncStatus.StatusCode) {
        4 { "Green" }
        3 { "Cyan" }
        5 { "Yellow" }
        6 { "Red" }
        default { "Yellow" }
    }
    
    Write-Host "  Status: " -NoNewline
    Write-Host "$($syncStatus.Status)" -ForegroundColor $statusColor
    foreach ($detail in $syncStatus.Details) {
        Write-Host "  - $detail" -ForegroundColor Gray
    }
    
    $Script:OneDriveResults += [PSCustomObject]@{
        Category = "Sync Status"
        Item = "Overall"
        Status = $syncStatus.Status
        Details = ($syncStatus.Details -join "; ")
        Path = ""
    }
    
    Write-Host ""
    
    # Step 5: Get folder info
    Write-SouliTEKResult "Analyzing OneDrive folders..." -Level INFO
    $folderInfo = Get-OneDriveFolderInfo
    
    if ($folderInfo.Count -gt 0) {
        foreach ($folder in $folderInfo) {
            Write-Host "  [$($folder.AccountType)] $($folder.FileCount) files ($($folder.TotalSizeFormatted))" -ForegroundColor Gray
            
            $Script:OneDriveResults += [PSCustomObject]@{
                Category = "Folder"
                Item = $folder.AccountType
                Status = "Active"
                Details = "$($folder.FileCount) files, $($folder.TotalSizeFormatted)"
                Path = $folder.FolderPath
            }
        }
    }
    
    Write-Host ""
    
    # Step 6: Scan for errors
    Write-SouliTEKResult "Scanning logs for sync errors..." -Level INFO
    $Script:SyncErrors = Get-OneDriveSyncErrors
    
    if ($Script:SyncErrors.Count -gt 0) {
        Write-SouliTEKWarning "Found $($Script:SyncErrors.Count) error(s) in logs"
        
        # Show first 5 errors
        $Script:SyncErrors | Select-Object -First 5 | ForEach-Object {
            Write-Host "  [$($_.Timestamp.ToString('MM/dd HH:mm'))] $($_.ErrorType)" -ForegroundColor Yellow
        }
        
        $Script:OneDriveResults += [PSCustomObject]@{
            Category = "Errors"
            Item = "Sync Errors"
            Status = "Errors Found"
            Details = "$($Script:SyncErrors.Count) error(s) in last 7 days"
            Path = ""
        }
    } else {
        Write-SouliTEKSuccess "No sync errors found in recent logs"
        
        $Script:OneDriveResults += [PSCustomObject]@{
            Category = "Errors"
            Item = "Sync Errors"
            Status = "None"
            Details = "No errors in last 7 days"
            Path = ""
        }
    }
    
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    
    # Summary
    if ($syncStatus.StatusCode -eq 4 -and $Script:SyncErrors.Count -eq 0) {
        Write-Host "  RESULT: " -NoNewline -ForegroundColor White
        Write-Host "OneDrive is Up To Date!" -ForegroundColor Green
        Write-Host "  All files are synced and no errors detected." -ForegroundColor Gray
    } elseif ($syncStatus.StatusCode -eq 3) {
        Write-Host "  RESULT: " -NoNewline -ForegroundColor White
        Write-Host "OneDrive is Syncing" -ForegroundColor Cyan
        Write-Host "  Sync is in progress. Please wait for completion." -ForegroundColor Gray
    } elseif ($Script:SyncErrors.Count -gt 0) {
        Write-Host "  RESULT: " -NoNewline -ForegroundColor White
        Write-Host "Sync Errors Detected" -ForegroundColor Red
        Write-Host "  Review errors in 'View Sync Errors' menu option." -ForegroundColor Gray
    } else {
        Write-Host "  RESULT: " -NoNewline -ForegroundColor White
        Write-Host "$($syncStatus.Status)" -ForegroundColor Yellow
    }
    
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    
    Wait-SouliTEKKeyPress
}

function Show-QuickStatus {
    <#
    .SYNOPSIS
        Shows a quick one-line status summary.
    #>
    
    Show-Header "ONEDRIVE STATUS CHECKER - QUICK STATUS"
    
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    
    # Quick checks
    $installed = Test-OneDriveInstalled
    $process = Get-OneDriveProcess
    $syncStatus = Get-OneDriveSyncStatus
    $accounts = Get-OneDriveAccounts
    
    # Installation
    Write-Host "  Installation: " -NoNewline -ForegroundColor White
    if ($installed.Installed) {
        Write-Host "Installed (v$($installed.Version))" -ForegroundColor Green
    } else {
        Write-Host "NOT INSTALLED" -ForegroundColor Red
    }
    
    # Process
    Write-Host "  Process:      " -NoNewline -ForegroundColor White
    if ($process.Running) {
        Write-Host "Running ($($process.Count) process(es))" -ForegroundColor Green
    } else {
        Write-Host "NOT RUNNING" -ForegroundColor Red
    }
    
    # Accounts
    Write-Host "  Accounts:     " -NoNewline -ForegroundColor White
    if ($accounts.Count -gt 0) {
        Write-Host "$($accounts.Count) configured" -ForegroundColor Green
        foreach ($acc in $accounts) {
            Write-Host "                - $($acc.UserEmail) [$($acc.AccountType)]" -ForegroundColor Gray
        }
    } else {
        Write-Host "None configured" -ForegroundColor Yellow
    }
    
    # Sync Status
    Write-Host "  Sync Status:  " -NoNewline -ForegroundColor White
    $statusColor = switch ($syncStatus.StatusCode) {
        4 { "Green" }
        3 { "Cyan" }
        5 { "Yellow" }
        6 { "Red" }
        default { "Yellow" }
    }
    Write-Host "$($syncStatus.Status)" -ForegroundColor $statusColor
    
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    
    # Overall verdict
    if ($installed.Installed -and $process.Running -and $syncStatus.StatusCode -in @(3, 4)) {
        Write-Host "  VERDICT: " -NoNewline -ForegroundColor White
        Write-Host "OneDrive is working properly" -ForegroundColor Green
    } elseif (-not $installed.Installed) {
        Write-Host "  VERDICT: " -NoNewline -ForegroundColor White
        Write-Host "OneDrive needs to be installed" -ForegroundColor Red
    } elseif (-not $process.Running) {
        Write-Host "  VERDICT: " -NoNewline -ForegroundColor White
        Write-Host "OneDrive needs to be started" -ForegroundColor Yellow
    } else {
        Write-Host "  VERDICT: " -NoNewline -ForegroundColor White
        Write-Host "OneDrive may have issues - run Full Scan" -ForegroundColor Yellow
    }
    
    Write-Host ""
    
    Wait-SouliTEKKeyPress
}

function Show-SyncErrors {
    <#
    .SYNOPSIS
        Displays detailed sync error information.
    #>
    
    Show-Header "ONEDRIVE STATUS CHECKER - SYNC ERRORS"
    
    if ($Script:SyncErrors.Count -eq 0) {
        # Scan for errors if not already done
        Write-SouliTEKResult "Scanning for sync errors..." -Level INFO
        $Script:SyncErrors = Get-OneDriveSyncErrors
    }
    
    if ($Script:SyncErrors.Count -eq 0) {
        Write-SouliTEKSuccess "No sync errors found in the last 7 days!"
        Write-Host ""
        Write-Host "OneDrive appears to be syncing without issues." -ForegroundColor Gray
        Write-Host ""
        Wait-SouliTEKKeyPress
        return
    }
    
    Write-Host "============================================================" -ForegroundColor Yellow
    Write-Host "  SYNC ERRORS FOUND: $($Script:SyncErrors.Count)" -ForegroundColor Yellow
    Write-Host "============================================================" -ForegroundColor Yellow
    Write-Host ""
    
    $index = 1
    foreach ($error in $Script:SyncErrors) {
        Write-Host "[$index] $($error.Timestamp.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Cyan
        Write-Host "    Type: $($error.ErrorType)" -ForegroundColor Red
        Write-Host "    Source: $($error.Source)" -ForegroundColor Gray
        Write-Host "    Message: $($error.Message)" -ForegroundColor White
        Write-Host ""
        $index++
        
        if ($index -gt 20) {
            Write-Host "... and $($Script:SyncErrors.Count - 20) more errors" -ForegroundColor Yellow
            break
        }
    }
    
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "RECOMMENDATIONS:" -ForegroundColor Cyan
    Write-Host "  1. Check your internet connection" -ForegroundColor Gray
    Write-Host "  2. Sign out and sign back into OneDrive" -ForegroundColor Gray
    Write-Host "  3. Reset OneDrive: onedrive.exe /reset" -ForegroundColor Gray
    Write-Host "  4. Check for file conflicts in OneDrive folder" -ForegroundColor Gray
    Write-Host "  5. Verify storage quota isn't exceeded" -ForegroundColor Gray
    Write-Host ""
    
    Wait-SouliTEKKeyPress
}

function Show-AccountDetails {
    <#
    .SYNOPSIS
        Shows detailed information about OneDrive accounts.
    #>
    
    Show-Header "ONEDRIVE STATUS CHECKER - ACCOUNT DETAILS"
    
    $accounts = Get-OneDriveAccounts
    
    if ($accounts.Count -eq 0) {
        Write-SouliTEKWarning "No OneDrive accounts configured on this system"
        Write-Host ""
        Write-Host "To configure OneDrive:" -ForegroundColor Yellow
        Write-Host "  1. Open OneDrive from Start Menu" -ForegroundColor Gray
        Write-Host "  2. Sign in with your Microsoft account" -ForegroundColor Gray
        Write-Host "  3. Choose folders to sync" -ForegroundColor Gray
        Write-Host ""
        Wait-SouliTEKKeyPress
        return
    }
    
    $folderInfo = Get-OneDriveFolderInfo
    
    foreach ($account in $accounts) {
        Write-Host "============================================================" -ForegroundColor Cyan
        Write-Host "  ACCOUNT: $($account.AccountType)" -ForegroundColor Cyan
        Write-Host "============================================================" -ForegroundColor Cyan
        Write-Host ""
        
        Write-Host "  Email:        " -NoNewline -ForegroundColor Yellow
        Write-Host "$($account.UserEmail)" -ForegroundColor White
        
        Write-Host "  Account Name: " -NoNewline -ForegroundColor Yellow
        Write-Host "$($account.AccountName)" -ForegroundColor White
        
        Write-Host "  Folder:       " -NoNewline -ForegroundColor Yellow
        Write-Host "$($account.UserFolder)" -ForegroundColor White
        
        if ($account.TenantId) {
            Write-Host "  Tenant ID:    " -NoNewline -ForegroundColor Yellow
            Write-Host "$($account.TenantId)" -ForegroundColor Gray
        }
        
        if ($account.LastSignInTime) {
            Write-Host "  Last Sign-In: " -NoNewline -ForegroundColor Yellow
            Write-Host "$($account.LastSignInTime)" -ForegroundColor White
        }
        
        # Find folder info for this account
        $folder = $folderInfo | Where-Object { $_.AccountType -eq $account.AccountName } | Select-Object -First 1
        if ($folder) {
            Write-Host ""
            Write-Host "  Folder Statistics:" -ForegroundColor Yellow
            Write-Host "    Files:      $($folder.FileCount)" -ForegroundColor White
            Write-Host "    Total Size: $($folder.TotalSizeFormatted)" -ForegroundColor White
            Write-Host "    Modified:   $($folder.LastModified)" -ForegroundColor White
        }
        
        Write-Host ""
    }
    
    Wait-SouliTEKKeyPress
}

function Export-OneDriveResults {
    <#
    .SYNOPSIS
        Exports OneDrive scan results to file.
    #>
    
    if ($Script:OneDriveResults.Count -eq 0) {
        Write-SouliTEKWarning "No results to export. Please run a scan first."
        Write-Host ""
        Wait-SouliTEKKeyPress
        return
    }
    
    $format = Show-SouliTEKExportMenu -Title "EXPORT ONEDRIVE STATUS"
    
    if ($format -eq "CANCEL") {
        return
    }
    
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $desktopPath = [Environment]::GetFolderPath("Desktop")
    
    $exportData = $Script:OneDriveResults | ForEach-Object {
        [PSCustomObject]@{
            Category = $_.Category
            Item = $_.Item
            Status = $_.Status
            Details = $_.Details
            Path = $_.Path
        }
    }
    
    $extraInfo = @{
        "Total Items" = $Script:OneDriveResults.Count
        "Accounts" = $Script:OneDriveAccounts.Count
        "Errors Found" = $Script:SyncErrors.Count
    }
    
    if ($format -eq "ALL") {
        $formats = @("TXT", "CSV", "HTML")
    } else {
        $formats = @($format)
    }
    
    foreach ($fmt in $formats) {
        $extension = switch ($fmt) {
            "TXT" { "txt" }
            "CSV" { "csv" }
            "HTML" { "html" }
        }
        
        $outputPath = Join-Path $desktopPath "OneDrive_Status_$timestamp.$extension"
        
        $columns = @("Category", "Item", "Status", "Details", "Path")
        
        Export-SouliTEKReport -Data $exportData -Title "OneDrive Status Report" -Format $fmt -OutputPath $outputPath -ExtraInfo $extraInfo -Columns $columns -OpenAfterExport $false
    }
    
    Write-Host ""
    Write-SouliTEKSuccess "Export complete!"
    Wait-SouliTEKKeyPress
}

function Show-Help {
    <#
    .SYNOPSIS
        Displays help information.
    #>
    
    Show-Header "ONEDRIVE STATUS CHECKER - HELP"
    
    Write-Host "This tool checks OneDrive sync status by examining:" -ForegroundColor White
    Write-Host ""
    Write-Host "  1. Registry settings and account configurations" -ForegroundColor Gray
    Write-Host "  2. OneDrive process status" -ForegroundColor Gray
    Write-Host "  3. Sync logs for errors (last 7 days)" -ForegroundColor Gray
    Write-Host "  4. OneDrive folder statistics" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Status Indicators:" -ForegroundColor Yellow
    Write-Host "  " -NoNewline
    Write-Host "Up To Date" -ForegroundColor Green -NoNewline
    Write-Host " - All files are synced" -ForegroundColor Gray
    Write-Host "  " -NoNewline
    Write-Host "Syncing" -ForegroundColor Cyan -NoNewline
    Write-Host "    - Sync in progress" -ForegroundColor Gray
    Write-Host "  " -NoNewline
    Write-Host "Paused" -ForegroundColor Yellow -NoNewline
    Write-Host "     - Sync is paused" -ForegroundColor Gray
    Write-Host "  " -NoNewline
    Write-Host "Error" -ForegroundColor Red -NoNewline
    Write-Host "      - Sync errors detected" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Common Issues:" -ForegroundColor Yellow
    Write-Host "  - File is locked: Close the file and retry sync" -ForegroundColor Gray
    Write-Host "  - Path too long: Shorten folder/file names" -ForegroundColor Gray
    Write-Host "  - Quota exceeded: Free up OneDrive space" -ForegroundColor Gray
    Write-Host "  - Sign-in required: Re-authenticate with OneDrive" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Troubleshooting Commands:" -ForegroundColor Yellow
    Write-Host "  Reset OneDrive:  %localappdata%\Microsoft\OneDrive\onedrive.exe /reset" -ForegroundColor Cyan
    Write-Host "  Restart OneDrive: taskkill /f /im OneDrive.exe && start OneDrive.exe" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Log Locations:" -ForegroundColor Yellow
    Write-Host "  Personal: $Script:OneDriveLogsPath\Personal" -ForegroundColor Gray
    Write-Host "  Business: $Script:OneDriveLogsPath\Business1" -ForegroundColor Gray
    Write-Host ""
    
    Wait-SouliTEKKeyPress
}

function Show-MainMenu {
    <#
    .SYNOPSIS
        Displays the main menu.
    #>
    
    do {
        Show-Header "ONEDRIVE STATUS CHECKER"
        
        Write-Host "Select an option:" -ForegroundColor White
        Write-Host ""
        Write-Host "  [1] Full Scan              - Complete OneDrive status check" -ForegroundColor Yellow
        Write-Host "  [2] Quick Status           - One-line status summary" -ForegroundColor Yellow
        Write-Host "  [3] View Sync Errors       - Show sync error details" -ForegroundColor Yellow
        Write-Host "  [4] Account Details        - View configured accounts" -ForegroundColor Yellow
        Write-Host "  [5] Export Results         - Export to TXT, CSV, or HTML" -ForegroundColor Yellow
        Write-Host "  [6] Help                   - Usage guide and troubleshooting" -ForegroundColor Yellow
        Write-Host "  [0] Exit" -ForegroundColor Red
        Write-Host ""
        Write-Host "============================================================" -ForegroundColor DarkGray
        
        $choice = Read-Host "Enter your choice (0-6)"
        
        switch ($choice) {
            '1' { Invoke-FullScan }
            '2' { Show-QuickStatus }
            '3' { Show-SyncErrors }
            '4' { Show-AccountDetails }
            '5' { Export-OneDriveResults }
            '6' { Show-Help }
            '0' { 
                Show-SouliTEKExitMessage -ScriptPath $PSCommandPath -ToolName $Script:ToolName
                exit 0
            }
            default {
                Write-SouliTEKWarning "Invalid choice. Please select 0-6."
                Start-Sleep -Seconds 1
            }
        }
    } while ($true)
}

# ============================================================
# MAIN EXECUTION
# ============================================================

try {
    Initialize-SouliTEKScript -WindowTitle "ONEDRIVE STATUS CHECKER"
    
    Show-SouliTEKDisclaimer -ToolName $Script:ToolName
    
    Show-MainMenu
}
catch {
    Write-SouliTEKError "An error occurred: $($_.Exception.Message)"
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit 1
}

