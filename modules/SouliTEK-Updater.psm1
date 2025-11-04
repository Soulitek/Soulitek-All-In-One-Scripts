# ============================================================
# SouliTEK All-In-One Scripts - Update Module
# ============================================================
# 
# Automatic update checker and installer module
# 
# (C) 2025 Soulitek - All Rights Reserved
# Website: www.soulitek.co.il
# 
# ============================================================

#Requires -Version 5.1

# Module variables
$Script:UpdateCheckUrl = "https://api.github.com/repos/Soulitek/Soulitek-All-In-One-Scripts/releases/latest"
$Script:VersionManifestUrl = "https://raw.githubusercontent.com/Soulitek/Soulitek-All-In-One-Scripts/main/version.json"
$Script:InstallScriptUrl = "https://raw.githubusercontent.com/Soulitek/Soulitek-All-In-One-Scripts/main/Install-SouliTEK.ps1"
$Script:ConfigPath = Join-Path $env:LOCALAPPDATA "SouliTEK\updater-config.json"

function Get-CurrentVersion {
    <#
    .SYNOPSIS
        Gets the current launcher version from the script.
    #>
    param(
        [string]$LauncherPath
    )
    
    if (-not $LauncherPath) {
        return $null
    }
    
    try {
        $content = Get-Content $LauncherPath -Raw -ErrorAction Stop
        if ($content -match '\$Script:CurrentVersion\s*=\s*["'']([\d\.]+)["'']') {
            return $matches[1]
        }
    }
    catch {
        Write-Warning "Failed to read current version: $_"
    }
    
    return $null
}

function Get-LatestVersion {
    <#
    .SYNOPSIS
        Checks for the latest version from GitHub releases or version manifest.
    #>
    param(
        [switch]$UseManifest
    )
    
    $latestVersion = $null
    $releaseNotes = $null
    $downloadUrl = $null
    
    try {
        # Enable TLS 1.2
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        
        if ($UseManifest) {
            # Try version manifest first (faster, simpler)
            try {
                $response = Invoke-RestMethod -Uri $Script:VersionManifestUrl -Method Get -TimeoutSec 10 -ErrorAction Stop
                if ($response.version) {
                    $latestVersion = $response.version
                    $releaseNotes = $response.releaseNotes
                    $downloadUrl = $response.downloadUrl
                }
            }
            catch {
                Write-Warning "Failed to fetch version manifest: $_"
            }
        }
        
        # Fallback to GitHub Releases API
        if (-not $latestVersion) {
            try {
                $headers = @{
                    'Accept' = 'application/vnd.github.v3+json'
                    'User-Agent' = 'SouliTEK-Launcher'
                }
                $response = Invoke-RestMethod -Uri $Script:UpdateCheckUrl -Method Get -Headers $headers -TimeoutSec 10 -ErrorAction Stop
                
                if ($response.tag_name) {
                    # Remove 'v' prefix if present
                    $latestVersion = $response.tag_name -replace '^v', ''
                    $releaseNotes = $response.body
                    $downloadUrl = $response.html_url
                }
            }
            catch {
                Write-Warning "Failed to fetch from GitHub API: $_"
            }
        }
    }
    catch {
        Write-Warning "Update check failed: $_"
    }
    
    return @{
        Version = $latestVersion
        ReleaseNotes = $releaseNotes
        DownloadUrl = $downloadUrl
        Success = ($null -ne $latestVersion)
    }
}

function Compare-Versions {
    <#
    .SYNOPSIS
        Compares two version strings.
    
    .DESCRIPTION
        Returns: 1 if version1 > version2, -1 if version1 < version2, 0 if equal
    #>
    param(
        [string]$Version1,
        [string]$Version2
    )
    
    if ([string]::IsNullOrWhiteSpace($Version1) -or [string]::IsNullOrWhiteSpace($Version2)) {
        return $null
    }
    
    try {
        $v1 = [Version]$Version1
        $v2 = [Version]$Version2
        
        if ($v1 -gt $v2) { return 1 }
        if ($v1 -lt $v2) { return -1 }
        return 0
    }
    catch {
        Write-Warning "Version comparison failed: $_"
        return $null
    }
}

function Test-UpdateAvailable {
    <#
    .SYNOPSIS
        Checks if an update is available.
    #>
    param(
        [string]$CurrentVersion,
        [switch]$UseManifest
    )
    
    $updateInfo = Get-LatestVersion -UseManifest:$UseManifest
    
    if (-not $updateInfo.Success) {
        return @{
            Available = $false
            Error = "Failed to check for updates"
        }
    }
    
    $comparison = Compare-Versions -Version1 $updateInfo.Version -Version2 $CurrentVersion
    
    return @{
        Available = ($comparison -eq 1)
        CurrentVersion = $CurrentVersion
        LatestVersion = $updateInfo.Version
        ReleaseNotes = $updateInfo.ReleaseNotes
        DownloadUrl = $updateInfo.DownloadUrl
        Error = $null
    }
}

function Install-Update {
    <#
    .SYNOPSIS
        Downloads and installs the latest version.
    #>
    param(
        [string]$LauncherPath,
        [string]$DownloadUrl = $null,
        [switch]$Silent
    )
    
    try {
        # Enable TLS 1.2
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        
        # Get installer script
        $installerPath = Join-Path $env:TEMP "SouliTEK-Update-Installer.ps1"
        
        Write-Host "Downloading update installer..." -ForegroundColor Cyan
        
        if ($DownloadUrl) {
            # If provided, use specific download URL
            Invoke-WebRequest -Uri $DownloadUrl -OutFile $installerPath -UseBasicParsing -ErrorAction Stop
        }
        else {
            # Use default installer script
            Invoke-WebRequest -Uri $Script:InstallScriptUrl -OutFile $installerPath -UseBasicParsing -ErrorAction Stop
        }
        
        Write-Host "Update installer downloaded successfully." -ForegroundColor Green
        
        if ($Silent) {
            # Silent install - run in background
            Start-Process powershell.exe -ArgumentList @(
                "-NoProfile",
                "-ExecutionPolicy Bypass",
                "-File `"$installerPath`"",
                "-Silent"
            ) -Verb RunAs -WindowStyle Hidden
        }
        else {
            # Interactive install
            Start-Process powershell.exe -ArgumentList @(
                "-NoProfile",
                "-ExecutionPolicy Bypass",
                "-File `"$installerPath`""
            ) -Verb RunAs
        }
        
        return @{
            Success = $true
            Message = "Update installer launched successfully"
        }
    }
    catch {
        return @{
            Success = $false
            Message = "Failed to download update: $_"
        }
    }
}

function Get-UpdaterConfig {
    <#
    .SYNOPSIS
        Gets the updater configuration.
    #>
    $defaultConfig = @{
        SilentAutoUpdate = $false
        CheckOnStartup = $true
        CheckInterval = 24  # hours
        LastCheck = $null
    }
    
    if (Test-Path $Script:ConfigPath) {
        try {
            $savedConfig = Get-Content $Script:ConfigPath -Raw | ConvertFrom-Json
            # Merge with defaults
            foreach ($key in $defaultConfig.Keys) {
                if (-not $savedConfig.PSObject.Properties.Name -contains $key) {
                    $savedConfig | Add-Member -MemberType NoteProperty -Name $key -Value $defaultConfig[$key]
                }
            }
            return $savedConfig
        }
        catch {
            Write-Warning "Failed to read config, using defaults: $_"
        }
    }
    
    return $defaultConfig
}

function Set-UpdaterConfig {
    <#
    .SYNOPSIS
        Saves the updater configuration.
    #>
    param(
        [hashtable]$Config
    )
    
    try {
        $configDir = Split-Path $Script:ConfigPath -Parent
        if (-not (Test-Path $configDir)) {
            New-Item -ItemType Directory -Path $configDir -Force | Out-Null
        }
        
        $Config | ConvertTo-Json | Set-Content $Script:ConfigPath -Force
        return $true
    }
    catch {
        Write-Warning "Failed to save config: $_"
        return $false
    }
}

function Should-CheckForUpdates {
    <#
    .SYNOPSIS
        Determines if we should check for updates based on configuration and last check time.
    #>
    param(
        [hashtable]$Config
    )
    
    if (-not $Config.CheckOnStartup) {
        return $false
    }
    
    if ($null -eq $Config.LastCheck) {
        return $true
    }
    
    try {
        $lastCheck = [DateTime]::Parse($Config.LastCheck)
        $hoursSinceCheck = ((Get-Date) - $lastCheck).TotalHours
        return ($hoursSinceCheck -ge $Config.CheckInterval)
    }
    catch {
        return $true
    }
}

function Update-LastCheckTime {
    <#
    .SYNOPSIS
        Updates the last check time in the configuration.
    #>
    $config = Get-UpdaterConfig
    $config.LastCheck = (Get-Date).ToString("o")
    Set-UpdaterConfig -Config $config | Out-Null
}

Export-ModuleMember -Function @(
    'Get-CurrentVersion',
    'Get-LatestVersion',
    'Compare-Versions',
    'Test-UpdateAvailable',
    'Install-Update',
    'Get-UpdaterConfig',
    'Set-UpdaterConfig',
    'Should-CheckForUpdates',
    'Update-LastCheckTime'
)

