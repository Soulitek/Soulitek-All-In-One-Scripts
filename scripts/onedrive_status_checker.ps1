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
                Write-Ui -Message "Failed to read account info for $($folder.PSChildName)" -Level "WARN"
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
    
    Write-Ui -Message "Starting OneDrive status scan" -Level "INFO"
    Write-Host ""
    
    $Script:OneDriveResults = @()
    $Script:OneDriveAccounts = @()
    $Script:SyncErrors = @()
    
    # Step 1: Check installation
    Write-Ui -Message "Checking OneDrive installation" -Level "INFO"
    $installInfo = Test-OneDriveInstalled
    
    if ($installInfo.Installed) {
        Write-Ui -Message "OneDrive is installed" -Level "OK"
        Write-Ui -Message "Path: $($installInfo.Path)" -Level "INFO"
        Write-Ui -Message "Version: $($installInfo.Version)" -Level "INFO"
        
        $Script:OneDriveResults += [PSCustomObject]@{
            Category = "Installation"
            Item = "OneDrive"
            Status = "Installed"
            Details = "Version: $($installInfo.Version)"
            Path = $installInfo.Path
        }
    } else {
        Write-Ui -Message "OneDrive is NOT installed" -Level "ERROR"
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
    Write-Ui -Message "Checking OneDrive process" -Level "INFO"
    $processInfo = Get-OneDriveProcess
    
    if ($processInfo.Running) {
        Write-Ui -Message "OneDrive is running" -Level "OK"
        Write-Ui -Message "Processes: $($processInfo.Count)" -Level "INFO"
        Write-Ui -Message "Memory: $(Format-SouliTEKFileSize $processInfo.Memory)" -Level "INFO"
        
        $Script:OneDriveResults += [PSCustomObject]@{
            Category = "Process"
            Item = "OneDrive.exe"
            Status = "Running"
            Details = "Memory: $(Format-SouliTEKFileSize $processInfo.Memory), Processes: $($processInfo.Count)"
            Path = ""
        }
    } else {
        Write-Ui -Message "OneDrive is NOT running" -Level "WARN"
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
    Write-Ui -Message "Scanning configured accounts" -Level "INFO"
    $Script:OneDriveAccounts = Get-OneDriveAccounts
    
    if ($Script:OneDriveAccounts.Count -gt 0) {
        Write-Ui -Message "Found $($Script:OneDriveAccounts.Count) configured account(s)" -Level "OK"
        foreach ($account in $Script:OneDriveAccounts) {
            Write-Ui -Message "  [$($account.AccountType)] $($account.UserEmail)" -Level "INFO"
            
            $Script:OneDriveResults += [PSCustomObject]@{
                Category = "Account"
                Item = $account.AccountType
                Status = "Configured"
                Details = "Email: $($account.UserEmail)"
                Path = $account.UserFolder
            }
        }
    } else {
        Write-Ui -Message "No OneDrive accounts configured" -Level "WARN"
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
    Write-Ui -Message "Checking sync status" -Level "INFO"
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
        Write-Ui -Message "  - $detail" -Level "INFO"
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
    Write-Ui -Message "Analyzing OneDrive folders" -Level "INFO"
    $folderInfo = Get-OneDriveFolderInfo
    
    if ($folderInfo.Count -gt 0) {
        foreach ($folder in $folderInfo) {
            Write-Ui -Message "  [$($folder.AccountType)] $($folder.FileCount) files ($($folder.TotalSizeFormatted))" -Level "INFO"
            
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
    Write-Ui -Message "Scanning logs for sync errors" -Level "INFO"
    $Script:SyncErrors = Get-OneDriveSyncErrors
    
    if ($Script:SyncErrors.Count -gt 0) {
        Write-Ui -Message "Found $($Script:SyncErrors.Count) error(s) in logs" -Level "WARN"
        
        # Show first 5 errors
        $Script:SyncErrors | Select-Object -First 5 | ForEach-Object {
            Write-Ui -Message "  [$($_.Timestamp.ToString('MM/dd HH:mm'))] $($_.ErrorType)" -Level "WARN"
        }
        
        $Script:OneDriveResults += [PSCustomObject]@{
            Category = "Errors"
            Item = "Sync Errors"
            Status = "Errors Found"
            Details = "$($Script:SyncErrors.Count) error(s) in last 7 days"
            Path = ""
        }
    } else {
        Write-Ui -Message "No sync errors found in recent logs" -Level "OK"
        
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
        Write-Ui -Message "OneDrive is Up To Date!" -Level "OK"
        Write-Ui -Message "  All files are synced and no errors detected." -Level "INFO"
    } elseif ($syncStatus.StatusCode -eq 3) {
        Write-Host "  RESULT: " -NoNewline -ForegroundColor White
        Write-Ui -Message "OneDrive is Syncing" -Level "INFO"
        Write-Ui -Message "  Sync is in progress. Please wait for completion." -Level "INFO"
    } elseif ($Script:SyncErrors.Count -gt 0) {
        Write-Host "  RESULT: " -NoNewline -ForegroundColor White
        Write-Ui -Message "Sync Errors Detected" -Level "ERROR"
        Write-Ui -Message "  Review errors in 'View Sync Errors' menu option." -Level "INFO"
    } else {
        Write-Host "  RESULT: " -NoNewline -ForegroundColor White
        Write-Ui -Message "$($syncStatus.Status)" -Level "WARN"
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
        Write-Ui -Message "Installed (v$($installed.Version))" -Level "OK"
    } else {
        Write-Ui -Message "NOT INSTALLED" -Level "ERROR"
    }
    
    # Process
    Write-Host "  Process:      " -NoNewline -ForegroundColor White
    if ($process.Running) {
        Write-Ui -Message "Running ($($process.Count) process(es))" -Level "OK"
    } else {
        Write-Ui -Message "NOT RUNNING" -Level "ERROR"
    }
    
    # Accounts
    Write-Host "  Accounts:     " -NoNewline -ForegroundColor White
    if ($accounts.Count -gt 0) {
        Write-Ui -Message "$($accounts.Count) configured" -Level "OK"
        foreach ($acc in $accounts) {
            Write-Ui -Message "                - $($acc.UserEmail) [$($acc.AccountType)]" -Level "INFO"
        }
    } else {
        Write-Ui -Message "None configured" -Level "WARN"
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
        Write-Ui -Message "OneDrive is working properly" -Level "OK"
    } elseif (-not $installed.Installed) {
        Write-Host "  VERDICT: " -NoNewline -ForegroundColor White
        Write-Ui -Message "OneDrive needs to be installed" -Level "ERROR"
    } elseif (-not $process.Running) {
        Write-Host "  VERDICT: " -NoNewline -ForegroundColor White
        Write-Ui -Message "OneDrive needs to be started" -Level "WARN"
    } else {
        Write-Host "  VERDICT: " -NoNewline -ForegroundColor White
        Write-Ui -Message "OneDrive may have issues - run Full Scan" -Level "WARN"
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
        Write-Ui -Message "OneDrive appears to be syncing without issues." -Level "INFO"
        Write-Host ""
        Wait-SouliTEKKeyPress
        return
    }
    
    Write-Host "============================================================" -ForegroundColor Yellow
    Write-Ui -Message "  SYNC ERRORS FOUND: $($Script:SyncErrors.Count)" -Level "WARN"
    Write-Host "============================================================" -ForegroundColor Yellow
    Write-Host ""
    
    $index = 1
    foreach ($error in $Script:SyncErrors) {
        Write-Ui -Message "[$index] $($error.Timestamp.ToString('yyyy-MM-dd HH:mm:ss'))" -Level "INFO"
        Write-Ui -Message "    Type: $($error.ErrorType)" -Level "ERROR"
        Write-Ui -Message "    Source: $($error.Source)" -Level "INFO"
        Write-Ui -Message "    Message: $($error.Message)" -Level "STEP"
        Write-Host ""
        $index++
        
        if ($index -gt 20) {
            Write-Ui -Message "... and $($Script:SyncErrors.Count - 20) more errors" -Level "WARN"
            break
        }
    }
    
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Yellow
    Write-Host ""
    Write-Ui -Message "RECOMMENDATIONS:" -Level "INFO"
    Write-Ui -Message "  1. Check your internet connection" -Level "INFO"
    Write-Ui -Message "  2. Sign out and sign back into OneDrive" -Level "INFO"
    Write-Ui -Message "  3. Reset OneDrive: onedrive.exe /reset" -Level "INFO"
    Write-Ui -Message "  4. Check for file conflicts in OneDrive folder" -Level "INFO"
    Write-Ui -Message "  5. Verify storage quota isn't exceeded" -Level "INFO"
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
        Write-Ui -Message "To configure OneDrive:" -Level "WARN"
        Write-Ui -Message "  1. Open OneDrive from Start Menu" -Level "INFO"
        Write-Ui -Message "  2. Sign in with your Microsoft account" -Level "INFO"
        Write-Ui -Message "  3. Choose folders to sync" -Level "INFO"
        Write-Host ""
        Wait-SouliTEKKeyPress
        return
    }
    
    $folderInfo = Get-OneDriveFolderInfo
    
    foreach ($account in $accounts) {
        Write-Host "============================================================" -ForegroundColor Cyan
        Write-Ui -Message "  ACCOUNT: $($account.AccountType)" -Level "INFO"
        Write-Host "============================================================" -ForegroundColor Cyan
        Write-Host ""
        
        Write-Host "  Email:        " -NoNewline -ForegroundColor Yellow
        Write-Ui -Message "$($account.UserEmail)" -Level "STEP"
        
        Write-Host "  Account Name: " -NoNewline -ForegroundColor Yellow
        Write-Ui -Message "$($account.AccountName)" -Level "STEP"
        
        Write-Host "  Folder:       " -NoNewline -ForegroundColor Yellow
        Write-Ui -Message "$($account.UserFolder)" -Level "STEP"
        
        if ($account.TenantId) {
            Write-Host "  Tenant ID:    " -NoNewline -ForegroundColor Yellow
            Write-Ui -Message "$($account.TenantId)" -Level "INFO"
        }
        
        if ($account.LastSignInTime) {
            Write-Host "  Last Sign-In: " -NoNewline -ForegroundColor Yellow
            Write-Ui -Message "$($account.LastSignInTime)" -Level "STEP"
        }
        
        # Find folder info for this account
        $folder = $folderInfo | Where-Object { $_.AccountType -eq $account.AccountName } | Select-Object -First 1
        if ($folder) {
            Write-Host ""
            Write-Ui -Message "  Folder Statistics:" -Level "WARN"
            Write-Ui -Message "    Files:      $($folder.FileCount)" -Level "STEP"
            Write-Ui -Message "    Total Size: $($folder.TotalSizeFormatted)" -Level "STEP"
            Write-Ui -Message "    Modified:   $($folder.LastModified)" -Level "STEP"
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
    Write-Ui -Message "Export complete" -Level "OK"
    Wait-SouliTEKKeyPress
}

function Show-Help {
    <#
    .SYNOPSIS
        Displays help information.
    #>
    
    Show-Header "ONEDRIVE STATUS CHECKER - HELP"
    
    Write-Ui -Message "This tool checks OneDrive sync status by examining:" -Level "STEP"
    Write-Host ""
    Write-Ui -Message "  1. Registry settings and account configurations" -Level "INFO"
    Write-Ui -Message "  2. OneDrive process status" -Level "INFO"
    Write-Ui -Message "  3. Sync logs for errors (last 7 days)" -Level "INFO"
    Write-Ui -Message "  4. OneDrive folder statistics" -Level "INFO"
    Write-Host ""
    Write-Ui -Message "Status Indicators:" -Level "WARN"
    Write-Host "  " -NoNewline
    Write-Host "Up To Date" -ForegroundColor Green -NoNewline
    Write-Ui -Message " - All files are synced" -Level "INFO"
    Write-Host "  " -NoNewline
    Write-Host "Syncing" -ForegroundColor Cyan -NoNewline
    Write-Ui -Message "    - Sync in progress" -Level "INFO"
    Write-Host "  " -NoNewline
    Write-Host "Paused" -ForegroundColor Yellow -NoNewline
    Write-Ui -Message "     - Sync is paused" -Level "INFO"
    Write-Host "  " -NoNewline
    Write-Host "Error" -ForegroundColor Red -NoNewline
    Write-Ui -Message "      - Sync errors detected" -Level "INFO"
    Write-Host ""
    Write-Ui -Message "Common Issues:" -Level "WARN"
    Write-Ui -Message "  - File is locked: Close the file and retry sync" -Level "INFO"
    Write-Ui -Message "  - Path too long: Shorten folder/file names" -Level "INFO"
    Write-Ui -Message "  - Quota exceeded: Free up OneDrive space" -Level "INFO"
    Write-Ui -Message "  - Sign-in required: Re-authenticate with OneDrive" -Level "INFO"
    Write-Host ""
    Write-Ui -Message "Troubleshooting Commands:" -Level "WARN"
    Write-Ui -Message "  Reset OneDrive:  %localappdata%\Microsoft\OneDrive\onedrive.exe /reset" -Level "INFO"
    Write-Ui -Message "  Restart OneDrive: taskkill /f /im OneDrive.exe && start OneDrive.exe" -Level "INFO"
    Write-Host ""
    Write-Ui -Message "Log Locations:" -Level "WARN"
    Write-Ui -Message "  Personal: $Script:OneDriveLogsPath\Personal" -Level "INFO"
    Write-Ui -Message "  Business: $Script:OneDriveLogsPath\Business1" -Level "INFO"
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
        
        Write-Ui -Message "Select an option:" -Level "STEP"
        Write-Host ""
        Write-Ui -Message "  [1] Full Scan              - Complete OneDrive status check" -Level "WARN"
        Write-Ui -Message "  [2] Quick Status           - One-line status summary" -Level "WARN"
        Write-Ui -Message "  [3] View Sync Errors       - Show sync error details" -Level "WARN"
        Write-Ui -Message "  [4] Account Details        - View configured accounts" -Level "WARN"
        Write-Ui -Message "  [5] Export Results         - Export to TXT, CSV, or HTML" -Level "WARN"
        Write-Ui -Message "  [6] Help                   - Usage guide and troubleshooting" -Level "WARN"
        Write-Ui -Message "  [0] Exit" -Level "ERROR"
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
                Write-Ui -Message "Invalid choice. Please select 0-6" -Level "WARN"
                Start-Sleep -Seconds 1
            }
        }
    } while ($true)
}

# ============================================================
# MAIN EXECUTION
# ============================================================

try {
    Clear-Host
    Show-ScriptBanner -ScriptName "OneDrive Status Checker" -Purpose "Check OneDrive sync status by examining Registry, process status, and logs"
    
    Show-SouliTEKDisclaimer -ToolName $Script:ToolName
    
    Show-MainMenu
}
catch {
    Write-Ui -Message "An error occurred: $($_.Exception.Message)" -Level "ERROR"
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit 1
}

