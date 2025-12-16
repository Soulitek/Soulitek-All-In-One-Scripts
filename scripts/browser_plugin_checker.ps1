# ============================================================
# SouliTEK All-In-One Scripts - Browser Plugin Checker
# ============================================================
# 
# Coded by: Soulitek.co.il
# IT Solutions for your business
# 
# (C) 2025 SouliTEK - All Rights Reserved
# Website: www.soulitek.co.il
# 
# This tool scans installed browser extensions/plugins
# and identifies potential security risks.
# 
# ============================================================

#Requires -Version 5.1

$Script:Version = "1.0.0"
$Script:ToolName = "Browser Plugin Checker"

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

$Script:ScanResults = @()
$Script:BrowsersFound = @()

# Known suspicious/malicious extension patterns
$Script:SuspiciousPatterns = @(
    # Adware/Spyware patterns
    "coupon", "deal", "discount", "shop", "price", "save",
    # Crypto miners
    "miner", "crypto", "bitcoin", "coin",
    # Potentially unwanted
    "toolbar", "search helper", "download helper",
    # Generic suspicious
    "free vpn", "proxy", "unblocker"
)

# Risky permissions that warrant attention
$Script:RiskyPermissions = @(
    "all_urls", "<all_urls>",
    "webRequest", "webRequestBlocking",
    "cookies", "history", "tabs",
    "clipboardRead", "clipboardWrite",
    "nativeMessaging", "proxy",
    "privacy", "management"
)

# ============================================================
# BROWSER DETECTION FUNCTIONS
# ============================================================

function Get-InstalledBrowsers {
    <#
    .SYNOPSIS
        Detects installed browsers on the system.
    #>
    
    $browsers = @()
    
    # Google Chrome
    $chromePaths = @(
        "$env:LOCALAPPDATA\Google\Chrome\User Data",
        "$env:ProgramFiles\Google\Chrome\Application",
        "${env:ProgramFiles(x86)}\Google\Chrome\Application"
    )
    foreach ($path in $chromePaths) {
        if (Test-Path "$env:LOCALAPPDATA\Google\Chrome\User Data") {
            $browsers += [PSCustomObject]@{
                Name = "Google Chrome"
                Type = "Chrome"
                ProfilePath = "$env:LOCALAPPDATA\Google\Chrome\User Data"
                ExtensionPath = "Extensions"
            }
            break
        }
    }
    
    # Microsoft Edge
    if (Test-Path "$env:LOCALAPPDATA\Microsoft\Edge\User Data") {
        $browsers += [PSCustomObject]@{
            Name = "Microsoft Edge"
            Type = "Edge"
            ProfilePath = "$env:LOCALAPPDATA\Microsoft\Edge\User Data"
            ExtensionPath = "Extensions"
        }
    }
    
    # Mozilla Firefox
    if (Test-Path "$env:APPDATA\Mozilla\Firefox\Profiles") {
        $browsers += [PSCustomObject]@{
            Name = "Mozilla Firefox"
            Type = "Firefox"
            ProfilePath = "$env:APPDATA\Mozilla\Firefox\Profiles"
            ExtensionPath = "extensions"
        }
    }
    
    # Brave Browser
    if (Test-Path "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data") {
        $browsers += [PSCustomObject]@{
            Name = "Brave Browser"
            Type = "Brave"
            ProfilePath = "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data"
            ExtensionPath = "Extensions"
        }
    }
    
    # Opera
    if (Test-Path "$env:APPDATA\Opera Software\Opera Stable") {
        $browsers += [PSCustomObject]@{
            Name = "Opera"
            Type = "Opera"
            ProfilePath = "$env:APPDATA\Opera Software\Opera Stable"
            ExtensionPath = "Extensions"
        }
    }
    
    # Vivaldi
    if (Test-Path "$env:LOCALAPPDATA\Vivaldi\User Data") {
        $browsers += [PSCustomObject]@{
            Name = "Vivaldi"
            Type = "Vivaldi"
            ProfilePath = "$env:LOCALAPPDATA\Vivaldi\User Data"
            ExtensionPath = "Extensions"
        }
    }
    
    return $browsers
}

function Get-ChromiumProfiles {
    <#
    .SYNOPSIS
        Gets all profiles for a Chromium-based browser.
    #>
    param(
        [string]$UserDataPath
    )
    
    $profiles = @()
    
    # Default profile
    if (Test-Path "$UserDataPath\Default") {
        $profiles += "Default"
    }
    
    # Additional profiles (Profile 1, Profile 2, etc.)
    $profileDirs = Get-ChildItem -Path $UserDataPath -Directory -Filter "Profile *" -ErrorAction SilentlyContinue
    foreach ($dir in $profileDirs) {
        $profiles += $dir.Name
    }
    
    return $profiles
}

function Get-ChromiumExtensions {
    <#
    .SYNOPSIS
        Gets extensions from a Chromium-based browser profile.
    #>
    param(
        [string]$ProfilePath,
        [string]$BrowserName,
        [string]$ProfileName
    )
    
    $extensions = @()
    $extensionsPath = Join-Path $ProfilePath "Extensions"
    
    if (-not (Test-Path $extensionsPath)) {
        return $extensions
    }
    
    $extDirs = Get-ChildItem -Path $extensionsPath -Directory -ErrorAction SilentlyContinue
    
    foreach ($extDir in $extDirs) {
        $extId = $extDir.Name
        
        # Get the latest version folder
        $versionDirs = Get-ChildItem -Path $extDir.FullName -Directory -ErrorAction SilentlyContinue | 
                       Sort-Object Name -Descending | 
                       Select-Object -First 1
        
        if ($versionDirs) {
            $manifestPath = Join-Path $versionDirs.FullName "manifest.json"
            
            if (Test-Path $manifestPath) {
                try {
                    $manifest = Get-Content $manifestPath -Raw -ErrorAction Stop | ConvertFrom-Json
                    
                    # Extract extension name
                    $extName = $extId  # Default to ID
                    if ($manifest.name) {
                        if ($manifest.name -match "^__MSG_(.+?)__$") {
                            # Try to get localized name from _locales
                            $msgKey = $matches[1]
                            $localesPath = Join-Path $versionDirs.FullName "_locales"
                            
                            if (Test-Path $localesPath) {
                                # Try common locales in order
                                $locales = @("en", "en_US", "en_GB", "default")
                                foreach ($locale in $locales) {
                                    $messagesPath = Join-Path $localesPath "$locale\messages.json"
                                    if (Test-Path $messagesPath) {
                                        try {
                                            $messages = Get-Content $messagesPath -Raw -ErrorAction Stop | ConvertFrom-Json
                                            if ($messages.$msgKey -and $messages.$msgKey.message) {
                                                $extName = $messages.$msgKey.message
                                                break
                                            }
                                        } catch {
                                            # Continue to next locale
                                        }
                                    }
                                }
                                
                                # If still not found, try any locale
                                if ($extName -eq $extId) {
                                    $allLocales = Get-ChildItem -Path $localesPath -Directory -ErrorAction SilentlyContinue
                                    foreach ($localeDir in $allLocales) {
                                        $messagesPath = Join-Path $localeDir.FullName "messages.json"
                                        if (Test-Path $messagesPath) {
                                            try {
                                                $messages = Get-Content $messagesPath -Raw -ErrorAction Stop | ConvertFrom-Json
                                                if ($messages.$msgKey -and $messages.$msgKey.message) {
                                                    $extName = $messages.$msgKey.message
                                                    break
                                                }
                                            } catch {
                                                # Continue
                                            }
                                        }
                                    }
                                }
                            }
                        } else {
                            $extName = $manifest.name
                        }
                    }
                    
                    $permissions = @()
                    if ($manifest.permissions) {
                        $permissions += $manifest.permissions
                    }
                    if ($manifest.host_permissions) {
                        $permissions += $manifest.host_permissions
                    }
                    
                    $extensions += [PSCustomObject]@{
                        Browser = $BrowserName
                        Profile = $ProfileName
                        ExtensionId = $extId
                        Name = $extName
                        Version = $manifest.version
                        Description = if ($manifest.description) { 
                            $manifest.description.Substring(0, [Math]::Min(100, $manifest.description.Length)) 
                        } else { "" }
                        Permissions = ($permissions -join ", ")
                        PermissionCount = $permissions.Count
                        ManifestVersion = $manifest.manifest_version
                        Path = $versionDirs.FullName
                    }
                }
                catch {
                    # Skip extensions with invalid manifests
                }
            }
        }
    }
    
    return $extensions
}

function Get-FirefoxExtensions {
    <#
    .SYNOPSIS
        Gets extensions from Firefox profiles.
    #>
    param(
        [string]$ProfilesPath
    )
    
    $extensions = @()
    
    $profiles = Get-ChildItem -Path $ProfilesPath -Directory -ErrorAction SilentlyContinue
    
    foreach ($profile in $profiles) {
        $extensionsJson = Join-Path $profile.FullName "extensions.json"
        
        if (Test-Path $extensionsJson) {
            try {
                $data = Get-Content $extensionsJson -Raw -ErrorAction Stop | ConvertFrom-Json
                
                if ($data.addons) {
                    foreach ($addon in $data.addons) {
                        if ($addon.type -eq "extension" -and $addon.location -ne "app-system-defaults") {
                            $extensions += [PSCustomObject]@{
                                Browser = "Mozilla Firefox"
                                Profile = $profile.Name
                                ExtensionId = $addon.id
                                Name = $addon.name
                                Version = $addon.version
                                Description = if ($addon.description) {
                                    $addon.description.Substring(0, [Math]::Min(100, $addon.description.Length))
                                } else { "" }
                                Permissions = if ($addon.userPermissions.permissions) {
                                    ($addon.userPermissions.permissions -join ", ")
                                } else { "" }
                                PermissionCount = if ($addon.userPermissions.permissions) {
                                    $addon.userPermissions.permissions.Count
                                } else { 0 }
                                ManifestVersion = "N/A"
                                Path = $profile.FullName
                            }
                        }
                    }
                }
            }
            catch {
                # Skip profiles with invalid extensions.json
            }
        }
    }
    
    return $extensions
}

# ============================================================
# ANALYSIS FUNCTIONS
# ============================================================

function Test-SuspiciousExtension {
    <#
    .SYNOPSIS
        Checks if an extension has suspicious characteristics.
    #>
    param(
        [PSCustomObject]$Extension
    )
    
    $warnings = @()
    $riskLevel = "Low"
    
    # Check name against suspicious patterns
    foreach ($pattern in $Script:SuspiciousPatterns) {
        if ($Extension.Name -like "*$pattern*") {
            $warnings += "Name contains suspicious keyword: '$pattern'"
            $riskLevel = "Medium"
        }
    }
    
    # Check for risky permissions
    $riskyFound = @()
    foreach ($perm in $Script:RiskyPermissions) {
        if ($Extension.Permissions -like "*$perm*") {
            $riskyFound += $perm
        }
    }
    
    if ($riskyFound.Count -gt 0) {
        $warnings += "Has risky permissions: $($riskyFound -join ', ')"
        if ($riskyFound.Count -ge 3) {
            $riskLevel = "High"
        } elseif ($riskLevel -ne "High") {
            $riskLevel = "Medium"
        }
    }
    
    # Check for <all_urls> permission (very broad access)
    if ($Extension.Permissions -match "<all_urls>" -or $Extension.Permissions -match "\*://\*/\*") {
        $warnings += "Has access to ALL websites"
        $riskLevel = "High"
    }
    
    # Check permission count
    if ($Extension.PermissionCount -gt 10) {
        $warnings += "Excessive permissions ($($Extension.PermissionCount) total)"
        if ($riskLevel -eq "Low") {
            $riskLevel = "Medium"
        }
    }
    
    return [PSCustomObject]@{
        RiskLevel = $riskLevel
        Warnings = $warnings
    }
}

# ============================================================
# DISPLAY FUNCTIONS
# ============================================================

function Show-BrowserSummary {
    <#
    .SYNOPSIS
        Shows summary of detected browsers.
    #>
    param(
        [array]$Browsers
    )
    
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "  DETECTED BROWSERS" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    
    if ($Browsers.Count -eq 0) {
        Write-Host "  No supported browsers detected." -ForegroundColor Yellow
        return
    }
    
    foreach ($browser in $Browsers) {
        Write-Host "  [+] $($browser.Name)" -ForegroundColor Green
        Write-Host "      Path: $($browser.ProfilePath)" -ForegroundColor Gray
    }
    
    Write-Host ""
}

function Show-ExtensionDetails {
    <#
    .SYNOPSIS
        Shows detailed extension information.
    #>
    param(
        [PSCustomObject]$Extension,
        [int]$Index
    )
    
    $analysis = Test-SuspiciousExtension -Extension $Extension
    
    $riskColor = switch ($analysis.RiskLevel) {
        "High" { "Red" }
        "Medium" { "Yellow" }
        default { "Green" }
    }
    
    Write-Host ""
    # Show name prominently - use ID if name is same as ID (fallback case)
    if ($Extension.Name -eq $Extension.ExtensionId) {
        Write-Host "  [$Index] Extension ID: $($Extension.ExtensionId)" -ForegroundColor Yellow
        Write-Host "      (Name not available - using ID)" -ForegroundColor Gray
    } else {
        Write-Host "  [$Index] $($Extension.Name)" -ForegroundColor White
        Write-Host "      ID: $($Extension.ExtensionId)" -ForegroundColor Gray
    }
    Write-Host "      Browser: $($Extension.Browser) ($($Extension.Profile))" -ForegroundColor Gray
    Write-Host "      Version: $($Extension.Version)" -ForegroundColor Gray
    Write-Host "      Risk Level: " -NoNewline -ForegroundColor Gray
    Write-Host $analysis.RiskLevel -ForegroundColor $riskColor
    
    if ($Extension.PermissionCount -gt 0) {
        Write-Host "      Permissions ($($Extension.PermissionCount)): $($Extension.Permissions.Substring(0, [Math]::Min(80, $Extension.Permissions.Length)))..." -ForegroundColor Gray
    }
    
    if ($analysis.Warnings.Count -gt 0) {
        Write-Host "      Warnings:" -ForegroundColor Yellow
        foreach ($warning in $analysis.Warnings) {
            Write-Host "        ! $warning" -ForegroundColor Yellow
        }
    }
}

function Show-ScanSummary {
    <#
    .SYNOPSIS
        Shows scan summary statistics.
    #>
    param(
        [array]$Extensions
    )
    
    $high = 0
    $medium = 0
    $low = 0
    
    foreach ($ext in $Extensions) {
        $analysis = Test-SuspiciousExtension -Extension $ext
        switch ($analysis.RiskLevel) {
            "High" { $high++ }
            "Medium" { $medium++ }
            "Low" { $low++ }
        }
    }
    
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "  SCAN SUMMARY" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Total Extensions: $($Extensions.Count)" -ForegroundColor White
    Write-Host ""
    Write-Host "  Risk Distribution:" -ForegroundColor White
    Write-Host "    - High Risk:   " -NoNewline -ForegroundColor Gray
    Write-Host $high -ForegroundColor $(if ($high -gt 0) { "Red" } else { "Green" })
    Write-Host "    - Medium Risk: " -NoNewline -ForegroundColor Gray
    Write-Host $medium -ForegroundColor $(if ($medium -gt 0) { "Yellow" } else { "Green" })
    Write-Host "    - Low Risk:    " -NoNewline -ForegroundColor Gray
    Write-Host $low -ForegroundColor Green
    Write-Host ""
    
    if ($high -gt 0) {
        Write-Host "  [!] WARNING: $high extension(s) with HIGH risk detected!" -ForegroundColor Red
        Write-Host "      Review these extensions and consider removing suspicious ones." -ForegroundColor Yellow
    } elseif ($medium -gt 0) {
        Write-Host "  [*] $medium extension(s) with elevated permissions detected." -ForegroundColor Yellow
        Write-Host "      Review to ensure they are from trusted sources." -ForegroundColor Gray
    } else {
        Write-Host "  [+] No high-risk extensions detected." -ForegroundColor Green
    }
    
    Write-Host ""
}

# ============================================================
# MAIN FUNCTIONS
# ============================================================

function Invoke-FullScan {
    <#
    .SYNOPSIS
        Performs a full scan of all browsers.
    #>
    
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "  SCANNING BROWSER EXTENSIONS" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Detecting installed browsers..." -ForegroundColor Cyan
    
    $Script:BrowsersFound = Get-InstalledBrowsers
    Show-BrowserSummary -Browsers $Script:BrowsersFound
    
    if ($Script:BrowsersFound.Count -eq 0) {
        Write-Host "No supported browsers found to scan." -ForegroundColor Yellow
        Wait-SouliTEKKeyPress
        return
    }
    
    $Script:ScanResults = @()
    
    foreach ($browser in $Script:BrowsersFound) {
        Write-Host "Scanning $($browser.Name)..." -ForegroundColor Cyan
        
        if ($browser.Type -eq "Firefox") {
            $extensions = Get-FirefoxExtensions -ProfilesPath $browser.ProfilePath
        } else {
            # Chromium-based browsers
            $profiles = Get-ChromiumProfiles -UserDataPath $browser.ProfilePath
            $extensions = @()
            
            foreach ($profile in $profiles) {
                $profilePath = Join-Path $browser.ProfilePath $profile
                $exts = Get-ChromiumExtensions -ProfilePath $profilePath -BrowserName $browser.Name -ProfileName $profile
                $extensions += $exts
            }
        }
        
        Write-Host "  Found $($extensions.Count) extension(s)" -ForegroundColor Gray
        $Script:ScanResults += $extensions
    }
    
    # Show results
    Show-ScanSummary -Extensions $Script:ScanResults
    
    # Show high and medium risk extensions
    $riskyExtensions = @()
    foreach ($ext in $Script:ScanResults) {
        $analysis = Test-SuspiciousExtension -Extension $ext
        if ($analysis.RiskLevel -ne "Low") {
            $riskyExtensions += $ext
        }
    }
    
    if ($riskyExtensions.Count -gt 0) {
        Write-Host "============================================================" -ForegroundColor Yellow
        Write-Host "  EXTENSIONS REQUIRING ATTENTION" -ForegroundColor Yellow
        Write-Host "============================================================" -ForegroundColor Yellow
        
        $index = 1
        foreach ($ext in $riskyExtensions) {
            Show-ExtensionDetails -Extension $ext -Index $index
            $index++
        }
    }
    
    Write-Host ""
    Wait-SouliTEKKeyPress
}

function Show-AllExtensions {
    <#
    .SYNOPSIS
        Shows all detected extensions.
    #>
    
    if ($Script:ScanResults.Count -eq 0) {
        Write-Host ""
        Write-Host "No scan results. Please run a full scan first (Option 1)." -ForegroundColor Yellow
        Wait-SouliTEKKeyPress
        return
    }
    
    Clear-Host
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "  ALL DETECTED EXTENSIONS ($($Script:ScanResults.Count))" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
    
    $index = 1
    foreach ($ext in $Script:ScanResults) {
        Show-ExtensionDetails -Extension $ext -Index $index
        $index++
    }
    
    Write-Host ""
    Wait-SouliTEKKeyPress
}

function Show-RiskyExtensions {
    <#
    .SYNOPSIS
        Shows only risky extensions.
    #>
    
    if ($Script:ScanResults.Count -eq 0) {
        Write-Host ""
        Write-Host "No scan results. Please run a full scan first (Option 1)." -ForegroundColor Yellow
        Wait-SouliTEKKeyPress
        return
    }
    
    $riskyExtensions = @()
    foreach ($ext in $Script:ScanResults) {
        $analysis = Test-SuspiciousExtension -Extension $ext
        if ($analysis.RiskLevel -ne "Low") {
            $riskyExtensions += $ext
        }
    }
    
    Clear-Host
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Yellow
    Write-Host "  RISKY EXTENSIONS ($($riskyExtensions.Count))" -ForegroundColor Yellow
    Write-Host "============================================================" -ForegroundColor Yellow
    
    if ($riskyExtensions.Count -eq 0) {
        Write-Host ""
        Write-Host "  No risky extensions detected!" -ForegroundColor Green
        Write-Host ""
    } else {
        $index = 1
        foreach ($ext in $riskyExtensions) {
            Show-ExtensionDetails -Extension $ext -Index $index
            $index++
        }
    }
    
    Wait-SouliTEKKeyPress
}

function Export-ScanResults {
    <#
    .SYNOPSIS
        Exports scan results to a file.
    #>
    
    if ($Script:ScanResults.Count -eq 0) {
        Write-Host ""
        Write-Host "No scan results to export. Please run a full scan first." -ForegroundColor Yellow
        Wait-SouliTEKKeyPress
        return
    }
    
    $format = Show-SouliTEKExportMenu -Title "EXPORT BROWSER EXTENSION REPORT"
    
    if ($format -eq "CANCEL") {
        return
    }
    
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $desktopPath = [Environment]::GetFolderPath("Desktop")
    
    # Add risk level to export data
    $exportData = foreach ($ext in $Script:ScanResults) {
        $analysis = Test-SuspiciousExtension -Extension $ext
        [PSCustomObject]@{
            Browser = $ext.Browser
            Profile = $ext.Profile
            Name = $ext.Name
            ExtensionId = $ext.ExtensionId
            Version = $ext.Version
            RiskLevel = $analysis.RiskLevel
            PermissionCount = $ext.PermissionCount
            Warnings = ($analysis.Warnings -join "; ")
        }
    }
    
    if ($format -eq "ALL") {
        $formats = @("TXT", "CSV", "HTML")
    } else {
        $formats = @($format)
    }
    
    # Count risk levels
    $high = ($exportData | Where-Object { $_.RiskLevel -eq "High" }).Count
    $medium = ($exportData | Where-Object { $_.RiskLevel -eq "Medium" }).Count
    
    foreach ($fmt in $formats) {
        $extension = $fmt.ToLower()
        $outputPath = Join-Path $desktopPath "Browser_Extensions_$timestamp.$extension"
        
        $extraInfo = @{
            "Total Extensions" = $Script:ScanResults.Count
            "High Risk" = $high
            "Medium Risk" = $medium
            "Browsers Scanned" = $Script:BrowsersFound.Count
        }
        
        Export-SouliTEKReport -Data $exportData -Title "Browser Extension Security Report" `
                             -Format $fmt -OutputPath $outputPath -ExtraInfo $extraInfo `
                             -OpenAfterExport:($formats.Count -eq 1)
    }
    
    Wait-SouliTEKKeyPress
}

function Show-Help {
    <#
    .SYNOPSIS
        Displays help information.
    #>
    
    Clear-Host
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "  BROWSER PLUGIN CHECKER - HELP" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  ABOUT:" -ForegroundColor Yellow
    Write-Host "  This tool scans installed browser extensions and analyzes" -ForegroundColor Gray
    Write-Host "  them for potential security risks based on permissions" -ForegroundColor Gray
    Write-Host "  and known suspicious patterns." -ForegroundColor Gray
    Write-Host ""
    Write-Host "  SUPPORTED BROWSERS:" -ForegroundColor Yellow
    Write-Host "  - Google Chrome" -ForegroundColor Gray
    Write-Host "  - Microsoft Edge" -ForegroundColor Gray
    Write-Host "  - Mozilla Firefox" -ForegroundColor Gray
    Write-Host "  - Brave Browser" -ForegroundColor Gray
    Write-Host "  - Opera" -ForegroundColor Gray
    Write-Host "  - Vivaldi" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  RISK LEVELS:" -ForegroundColor Yellow
    Write-Host "  - High:   " -NoNewline -ForegroundColor Red
    Write-Host "Access to all websites or multiple risky permissions" -ForegroundColor Gray
    Write-Host "  - Medium: " -NoNewline -ForegroundColor Yellow
    Write-Host "Some risky permissions or suspicious keywords" -ForegroundColor Gray
    Write-Host "  - Low:    " -NoNewline -ForegroundColor Green
    Write-Host "Normal extension with limited permissions" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  RISKY PERMISSIONS:" -ForegroundColor Yellow
    Write-Host "  - <all_urls>: Can read/modify any website" -ForegroundColor Gray
    Write-Host "  - cookies: Can access your cookies" -ForegroundColor Gray
    Write-Host "  - history: Can read browsing history" -ForegroundColor Gray
    Write-Host "  - webRequest: Can intercept network requests" -ForegroundColor Gray
    Write-Host "  - clipboardRead/Write: Can access clipboard" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  RECOMMENDATIONS:" -ForegroundColor Yellow
    Write-Host "  - Remove extensions you don't use" -ForegroundColor Gray
    Write-Host "  - Only install from official stores" -ForegroundColor Gray
    Write-Host "  - Review permissions before installing" -ForegroundColor Gray
    Write-Host "  - Be cautious of free VPN/proxy extensions" -ForegroundColor Gray
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    
    Wait-SouliTEKKeyPress
}

function Show-Menu {
    <#
    .SYNOPSIS
        Displays the main menu.
    #>
    
    Clear-Host
    Show-SouliTEKBanner
    
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host "  BROWSER PLUGIN CHECKER v$Script:Version" -ForegroundColor Magenta
    Write-Host "  Scan browser extensions for security risks" -ForegroundColor Gray
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host ""
    
    if ($Script:ScanResults.Count -gt 0) {
        Write-Host "  Last Scan: $($Script:ScanResults.Count) extension(s) found" -ForegroundColor Cyan
    }
    if ($Script:BrowsersFound.Count -gt 0) {
        Write-Host "  Browsers: $($Script:BrowsersFound.Name -join ', ')" -ForegroundColor Gray
    }
    
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  [1] Full Scan" -ForegroundColor Yellow
    Write-Host "      Scan all browsers for extensions" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  [2] View All Extensions" -ForegroundColor Yellow
    Write-Host "      List all detected extensions" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  [3] View Risky Extensions" -ForegroundColor Yellow
    Write-Host "      Show only medium/high risk extensions" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  [4] Export Results" -ForegroundColor Yellow
    Write-Host "      Export scan results to file" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  [5] Help" -ForegroundColor Yellow
    Write-Host "      Show usage instructions" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  [0] Exit" -ForegroundColor Red
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
}

# ============================================================
# MAIN EXECUTION
# ============================================================

# Show banner
Clear-Host
Show-ScriptBanner -ScriptName "Browser Plugin Checker" -Purpose "Check browser extensions and plugins for security risks"

# Main loop
do {
    Show-Menu
    $choice = Read-Host "Select option (0-5)"
    
    switch ($choice) {
        "1" { Invoke-FullScan }
        "2" { Show-AllExtensions }
        "3" { Show-RiskyExtensions }
        "4" { Export-ScanResults }
        "5" { Show-Help }
        "0" {
            Show-SouliTEKExitMessage -ScriptPath $PSCommandPath -ToolName $Script:ToolName
            exit 0
        }
        default {
            Write-Ui -Message "Invalid option. Please try again" -Level "ERROR"
            Start-Sleep -Seconds 1
        }
    }
} while ($true)

