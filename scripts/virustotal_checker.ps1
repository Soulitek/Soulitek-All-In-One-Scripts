# ============================================================
# SouliTEK All-In-One Scripts - VirusTotal Checker
# ============================================================
# 
# Coded by: Soulitek.co.il
# IT Solutions for your business
# 
# (C) 2025 SouliTEK - All Rights Reserved
# Website: www.soulitek.co.il
# 
# This tool checks files and URLs against VirusTotal's database
# using the VirusTotal API v3.
# 
# ============================================================

#Requires -Version 5.1

$Script:Version = "1.0.0"
$Script:ToolName = "VirusTotal Checker"

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

$Script:VTApiUrl = "https://www.virustotal.com/api/v3"
$Script:ApiKey = $null
$Script:ApiKeyPath = Join-Path $env:LOCALAPPDATA "SouliTEK\VTApiKey.txt"
$Script:ScanResults = @()

# ============================================================
# HELPER FUNCTIONS
# ============================================================

function Get-VTApiKey {
    <#
    .SYNOPSIS
        Gets or prompts for VirusTotal API key.
    #>
    
    # Check if API key is already loaded in session
    if ($Script:ApiKey) {
        return $Script:ApiKey
    }
    
    # Check if saved API key exists
    if (Test-Path $Script:ApiKeyPath) {
        try {
            $Script:ApiKey = Get-Content $Script:ApiKeyPath -ErrorAction Stop
            if ($Script:ApiKey.Length -eq 64) {
                return $Script:ApiKey
            }
        }
        catch {
            # Continue to prompt
        }
    }
    
    # Prompt for API key
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Yellow
    Write-Host "  VIRUSTOTAL API KEY REQUIRED" -ForegroundColor Yellow
    Write-Host "============================================================" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "To use this tool, you need a free VirusTotal API key." -ForegroundColor White
    Write-Host ""
    Write-Host "How to get your API key:" -ForegroundColor Cyan
    Write-Host "  1. Go to https://www.virustotal.com" -ForegroundColor Gray
    Write-Host "  2. Create a free account or sign in" -ForegroundColor Gray
    Write-Host "  3. Go to your profile settings" -ForegroundColor Gray
    Write-Host "  4. Find and copy your API key" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Note: Free API allows 4 requests per minute." -ForegroundColor Yellow
    Write-Host ""
    
    $key = Read-Host "Enter your VirusTotal API key (64 characters)"
    
    if ($key.Length -ne 64) {
        Write-Host "Invalid API key format. API key must be 64 characters." -ForegroundColor Red
        return $null
    }
    
    # Test the API key
    Write-Host ""
    Write-Host "Testing API key..." -ForegroundColor Cyan
    
    try {
        $headers = @{
            "x-apikey" = $key
        }
        $testUrl = "$Script:VTApiUrl/files/275a021bbfb6489e54d471899f7db9d1663fc695ec2fe2a2c4538aabf651fd0f"
        $response = Invoke-RestMethod -Uri $testUrl -Headers $headers -Method Get -ErrorAction Stop
        
        Write-Host "API key validated successfully!" -ForegroundColor Green
        
        # Save the API key
        $saveChoice = Read-Host "Save API key for future use? (Y/N)"
        if ($saveChoice -eq "Y" -or $saveChoice -eq "y") {
            $keyDir = Split-Path -Parent $Script:ApiKeyPath
            if (-not (Test-Path $keyDir)) {
                New-Item -ItemType Directory -Path $keyDir -Force | Out-Null
            }
            $key | Out-File -FilePath $Script:ApiKeyPath -Encoding UTF8
            Write-Host "API key saved to: $Script:ApiKeyPath" -ForegroundColor Green
        }
        
        $Script:ApiKey = $key
        return $key
    }
    catch {
        Write-Host "API key validation failed: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

function Get-FileHashInfo {
    <#
    .SYNOPSIS
        Calculates MD5, SHA1, and SHA256 hashes for a file.
    #>
    param(
        [string]$FilePath
    )
    
    if (-not (Test-Path $FilePath)) {
        return $null
    }
    
    try {
        $md5 = (Get-FileHash -Path $FilePath -Algorithm MD5).Hash
        $sha1 = (Get-FileHash -Path $FilePath -Algorithm SHA1).Hash
        $sha256 = (Get-FileHash -Path $FilePath -Algorithm SHA256).Hash
        
        return @{
            MD5 = $md5
            SHA1 = $sha1
            SHA256 = $sha256
            FileName = (Get-Item $FilePath).Name
            FileSize = (Get-Item $FilePath).Length
        }
    }
    catch {
        return $null
    }
}

function Invoke-VTFileCheck {
    <#
    .SYNOPSIS
        Checks a file hash against VirusTotal.
    #>
    param(
        [string]$Hash
    )
    
    $apiKey = Get-VTApiKey
    if (-not $apiKey) {
        return $null
    }
    
    try {
        $headers = @{
            "x-apikey" = $apiKey
        }
        $url = "$Script:VTApiUrl/files/$Hash"
        $response = Invoke-RestMethod -Uri $url -Headers $headers -Method Get -ErrorAction Stop
        return $response.data
    }
    catch {
        if ($_.Exception.Response.StatusCode -eq 404) {
            return @{ NotFound = $true }
        }
        Write-Host "Error checking file: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

function Invoke-VTUrlCheck {
    <#
    .SYNOPSIS
        Checks a URL against VirusTotal.
    #>
    param(
        [string]$Url
    )
    
    $apiKey = Get-VTApiKey
    if (-not $apiKey) {
        return $null
    }
    
    try {
        $headers = @{
            "x-apikey" = $apiKey
        }
        
        # URL identifier is base64 encoded URL without padding
        $urlBytes = [System.Text.Encoding]::UTF8.GetBytes($Url)
        $urlId = [Convert]::ToBase64String($urlBytes).TrimEnd('=').Replace('+', '-').Replace('/', '_')
        
        $vtUrl = "$Script:VTApiUrl/urls/$urlId"
        $response = Invoke-RestMethod -Uri $vtUrl -Headers $headers -Method Get -ErrorAction Stop
        return $response.data
    }
    catch {
        if ($_.Exception.Response.StatusCode -eq 404) {
            # URL not in database, need to submit for scanning
            return @{ NotFound = $true }
        }
        Write-Host "Error checking URL: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

function Invoke-VTUrlScan {
    <#
    .SYNOPSIS
        Submits a URL to VirusTotal for scanning.
    #>
    param(
        [string]$Url
    )
    
    $apiKey = Get-VTApiKey
    if (-not $apiKey) {
        return $null
    }
    
    try {
        $headers = @{
            "x-apikey" = $apiKey
            "Content-Type" = "application/x-www-form-urlencoded"
        }
        
        $body = "url=$([System.Web.HttpUtility]::UrlEncode($Url))"
        
        $vtUrl = "$Script:VTApiUrl/urls"
        $response = Invoke-RestMethod -Uri $vtUrl -Headers $headers -Method Post -Body $body -ErrorAction Stop
        return $response.data
    }
    catch {
        Write-Host "Error submitting URL for scan: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

function Show-VTFileResult {
    <#
    .SYNOPSIS
        Displays VirusTotal file scan results.
    #>
    param(
        $Result,
        [string]$FileName = "Unknown"
    )
    
    if ($Result.NotFound) {
        Write-Host ""
        Write-Host "============================================================" -ForegroundColor Yellow
        Write-Host "  FILE NOT FOUND IN VIRUSTOTAL DATABASE" -ForegroundColor Yellow
        Write-Host "============================================================" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "This file has not been analyzed by VirusTotal yet." -ForegroundColor White
        Write-Host "This could mean:" -ForegroundColor Gray
        Write-Host "  - The file is unique/custom" -ForegroundColor Gray
        Write-Host "  - The file has never been submitted for scanning" -ForegroundColor Gray
        Write-Host ""
        Write-Host "Note: To upload files for scanning, use the VirusTotal website." -ForegroundColor Yellow
        return
    }
    
    if (-not $Result) {
        return
    }
    
    $attrs = $Result.attributes
    $stats = $attrs.last_analysis_stats
    
    $malicious = $stats.malicious
    $suspicious = $stats.suspicious
    $harmless = $stats.harmless
    $undetected = $stats.undetected
    $total = $malicious + $suspicious + $harmless + $undetected
    
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "  VIRUSTOTAL SCAN RESULTS" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    
    # Determine threat level
    $threatColor = "Green"
    $threatLevel = "CLEAN"
    if ($malicious -gt 0 -or $suspicious -gt 0) {
        if ($malicious -ge 10) {
            $threatColor = "Red"
            $threatLevel = "HIGH RISK - MALWARE DETECTED"
        } elseif ($malicious -ge 3) {
            $threatColor = "Red"
            $threatLevel = "MEDIUM RISK - POTENTIALLY MALICIOUS"
        } elseif ($malicious -ge 1 -or $suspicious -ge 1) {
            $threatColor = "Yellow"
            $threatLevel = "LOW RISK - SUSPICIOUS"
        }
    }
    
    Write-Host "  Status: " -NoNewline -ForegroundColor White
    Write-Host $threatLevel -ForegroundColor $threatColor
    Write-Host ""
    
    Write-Host "  Detection Results:" -ForegroundColor White
    Write-Host "  |- Malicious:  " -NoNewline -ForegroundColor Gray
    Write-Host "$malicious" -ForegroundColor $(if ($malicious -gt 0) { "Red" } else { "Green" })
    Write-Host "  |- Suspicious: " -NoNewline -ForegroundColor Gray
    Write-Host "$suspicious" -ForegroundColor $(if ($suspicious -gt 0) { "Yellow" } else { "Green" })
    Write-Host "  |- Harmless:   " -NoNewline -ForegroundColor Gray
    Write-Host "$harmless" -ForegroundColor Green
    Write-Host "  \- Undetected: " -NoNewline -ForegroundColor Gray
    Write-Host "$undetected" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "  File Information:" -ForegroundColor White
    if ($attrs.meaningful_name) {
        Write-Host "  |- Name: $($attrs.meaningful_name)" -ForegroundColor Gray
    }
    if ($attrs.type_description) {
        Write-Host "  |- Type: $($attrs.type_description)" -ForegroundColor Gray
    }
    if ($attrs.size) {
        $sizeFormatted = Format-SouliTEKFileSize -SizeInBytes $attrs.size
        Write-Host "  |- Size: $sizeFormatted" -ForegroundColor Gray
    }
    if ($attrs.sha256) {
        Write-Host "  \- SHA256: $($attrs.sha256)" -ForegroundColor Gray
    }
    Write-Host ""
    
    if ($attrs.last_analysis_date) {
        $scanDate = [DateTimeOffset]::FromUnixTimeSeconds($attrs.last_analysis_date).DateTime.ToString("yyyy-MM-dd HH:mm:ss")
        Write-Host "  Last Scan: $scanDate" -ForegroundColor Gray
    }
    
    # Show popular threat names if malicious
    if ($malicious -gt 0 -and $attrs.popular_threat_classification) {
        Write-Host ""
        Write-Host "  Detected Threats:" -ForegroundColor Red
        if ($attrs.popular_threat_classification.suggested_threat_label) {
            Write-Host "  \- $($attrs.popular_threat_classification.suggested_threat_label)" -ForegroundColor Red
        }
    }
    
    Write-Host ""
    Write-Host "  Full Report: https://www.virustotal.com/gui/file/$($attrs.sha256)" -ForegroundColor Cyan
    Write-Host ""
    
    # Store result
    $Script:ScanResults += [PSCustomObject]@{
        Type = "File"
        Target = $FileName
        Hash = $attrs.sha256
        Malicious = $malicious
        Suspicious = $suspicious
        Harmless = $harmless
        Undetected = $undetected
        Status = $threatLevel
        ScanDate = $scanDate
        ReportUrl = "https://www.virustotal.com/gui/file/$($attrs.sha256)"
    }
}

function Show-VTUrlResult {
    <#
    .SYNOPSIS
        Displays VirusTotal URL scan results.
    #>
    param(
        $Result,
        [string]$Url
    )
    
    if ($Result.NotFound) {
        Write-Host ""
        Write-Host "============================================================" -ForegroundColor Yellow
        Write-Host "  URL NOT FOUND IN VIRUSTOTAL DATABASE" -ForegroundColor Yellow
        Write-Host "============================================================" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "This URL has not been analyzed by VirusTotal recently." -ForegroundColor White
        Write-Host ""
        
        $submitChoice = Read-Host "Submit URL for scanning? (Y/N)"
        if ($submitChoice -eq "Y" -or $submitChoice -eq "y") {
            Write-Host "Submitting URL for scanning..." -ForegroundColor Cyan
            $scanResult = Invoke-VTUrlScan -Url $Url
            if ($scanResult) {
                Write-Host "URL submitted successfully!" -ForegroundColor Green
                Write-Host "Analysis ID: $($scanResult.id)" -ForegroundColor Gray
                Write-Host ""
                Write-Host "Please wait 30-60 seconds and check again for results." -ForegroundColor Yellow
            }
        }
        return
    }
    
    if (-not $Result) {
        return
    }
    
    $attrs = $Result.attributes
    $stats = $attrs.last_analysis_stats
    
    $malicious = $stats.malicious
    $suspicious = $stats.suspicious
    $harmless = $stats.harmless
    $undetected = $stats.undetected
    
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "  VIRUSTOTAL URL SCAN RESULTS" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    
    # Determine threat level
    $threatColor = "Green"
    $threatLevel = "CLEAN"
    if ($malicious -gt 0 -or $suspicious -gt 0) {
        if ($malicious -ge 5) {
            $threatColor = "Red"
            $threatLevel = "HIGH RISK - MALICIOUS URL"
        } elseif ($malicious -ge 2) {
            $threatColor = "Red"
            $threatLevel = "MEDIUM RISK - POTENTIALLY MALICIOUS"
        } elseif ($malicious -ge 1 -or $suspicious -ge 1) {
            $threatColor = "Yellow"
            $threatLevel = "LOW RISK - SUSPICIOUS"
        }
    }
    
    Write-Host "  URL: $Url" -ForegroundColor White
    Write-Host ""
    Write-Host "  Status: " -NoNewline -ForegroundColor White
    Write-Host $threatLevel -ForegroundColor $threatColor
    Write-Host ""
    
    Write-Host "  Detection Results:" -ForegroundColor White
    Write-Host "  |- Malicious:  " -NoNewline -ForegroundColor Gray
    Write-Host "$malicious" -ForegroundColor $(if ($malicious -gt 0) { "Red" } else { "Green" })
    Write-Host "  |- Suspicious: " -NoNewline -ForegroundColor Gray
    Write-Host "$suspicious" -ForegroundColor $(if ($suspicious -gt 0) { "Yellow" } else { "Green" })
    Write-Host "  |- Harmless:   " -NoNewline -ForegroundColor Gray
    Write-Host "$harmless" -ForegroundColor Green
    Write-Host "  \- Undetected: " -NoNewline -ForegroundColor Gray
    Write-Host "$undetected" -ForegroundColor Cyan
    Write-Host ""
    
    if ($attrs.last_final_url -and $attrs.last_final_url -ne $Url) {
        Write-Host "  Final URL (redirects): $($attrs.last_final_url)" -ForegroundColor Yellow
    }
    
    if ($attrs.last_analysis_date) {
        $scanDate = [DateTimeOffset]::FromUnixTimeSeconds($attrs.last_analysis_date).DateTime.ToString("yyyy-MM-dd HH:mm:ss")
        Write-Host "  Last Scan: $scanDate" -ForegroundColor Gray
    }
    
    # Categories
    if ($attrs.categories -and $attrs.categories.Count -gt 0) {
        Write-Host ""
        Write-Host "  Categories:" -ForegroundColor White
        foreach ($vendor in $attrs.categories.PSObject.Properties) {
            Write-Host "  \- [$($vendor.Name)] $($vendor.Value)" -ForegroundColor Gray
        }
    }
    
    Write-Host ""
    
    # Generate URL-safe base64 ID for link
    $urlBytes = [System.Text.Encoding]::UTF8.GetBytes($Url)
    $urlId = [Convert]::ToBase64String($urlBytes).TrimEnd('=').Replace('+', '-').Replace('/', '_')
    Write-Host "  Full Report: https://www.virustotal.com/gui/url/$urlId" -ForegroundColor Cyan
    Write-Host ""
    
    # Store result
    $scanDateStr = if ($attrs.last_analysis_date) { 
        [DateTimeOffset]::FromUnixTimeSeconds($attrs.last_analysis_date).DateTime.ToString("yyyy-MM-dd HH:mm:ss") 
    } else { 
        "Unknown" 
    }
    
    $Script:ScanResults += [PSCustomObject]@{
        Type = "URL"
        Target = $Url
        Hash = "N/A"
        Malicious = $malicious
        Suspicious = $suspicious
        Harmless = $harmless
        Undetected = $undetected
        Status = $threatLevel
        ScanDate = $scanDateStr
        ReportUrl = "https://www.virustotal.com/gui/url/$urlId"
    }
}

function Show-Menu {
    <#
    .SYNOPSIS
        Displays the main menu.
    #>
    
    Clear-Host
    Show-SouliTEKBanner
    
    Write-Host "============================================================" -ForegroundColor Green
    Write-Host "  VIRUSTOTAL CHECKER v$Script:Version" -ForegroundColor Green
    Write-Host "  Check files and URLs against VirusTotal" -ForegroundColor Gray
    Write-Host "============================================================" -ForegroundColor Green
    Write-Host ""
    
    # Show API key status
    if ($Script:ApiKey) {
        Write-Host "  API Key: " -NoNewline -ForegroundColor Gray
        Write-Host "Configured" -ForegroundColor Green
    } else {
        Write-Host "  API Key: " -NoNewline -ForegroundColor Gray
        Write-Host "Not configured" -ForegroundColor Yellow
    }
    
    if ($Script:ScanResults.Count -gt 0) {
        Write-Host "  Results in session: $($Script:ScanResults.Count)" -ForegroundColor Cyan
    }
    
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  [1] Check File by Path" -ForegroundColor Yellow
    Write-Host "      Calculate hash and check against VirusTotal" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  [2] Check File by Hash" -ForegroundColor Yellow
    Write-Host "      Enter MD5, SHA1, or SHA256 hash directly" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  [3] Check URL" -ForegroundColor Yellow
    Write-Host "      Check if a URL is malicious" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  [4] Batch Check Files" -ForegroundColor Yellow
    Write-Host "      Check multiple files in a folder" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  [5] View Scan Results" -ForegroundColor Yellow
    Write-Host "      View results from this session" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  [6] Export Results" -ForegroundColor Yellow
    Write-Host "      Export scan results to file" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  [7] Configure API Key" -ForegroundColor Yellow
    Write-Host "      Set or change VirusTotal API key" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  [8] Help" -ForegroundColor Yellow
    Write-Host "      Show usage instructions" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  [0] Exit" -ForegroundColor Red
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
}

function Show-Help {
    <#
    .SYNOPSIS
        Displays help information.
    #>
    
    Clear-Host
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "  VIRUSTOTAL CHECKER - HELP" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  ABOUT:" -ForegroundColor Yellow
    Write-Host "  This tool checks files and URLs against VirusTotal's" -ForegroundColor Gray
    Write-Host "  extensive malware database using their API." -ForegroundColor Gray
    Write-Host ""
    Write-Host "  FEATURES:" -ForegroundColor Yellow
    Write-Host "  - Check local files (calculates hash automatically)" -ForegroundColor Gray
    Write-Host "  - Check files by hash (MD5, SHA1, SHA256)" -ForegroundColor Gray
    Write-Host "  - Check URLs for malicious content" -ForegroundColor Gray
    Write-Host "  - Batch check multiple files" -ForegroundColor Gray
    Write-Host "  - Export results to TXT, CSV, or HTML" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  API KEY:" -ForegroundColor Yellow
    Write-Host "  A free VirusTotal API key is required." -ForegroundColor Gray
    Write-Host "  Get yours at: https://www.virustotal.com" -ForegroundColor Cyan
    Write-Host "  Free tier: 4 requests per minute, 500 per day" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  UNDERSTANDING RESULTS:" -ForegroundColor Yellow
    Write-Host "  - Malicious: Detected as malware by engines" -ForegroundColor Red
    Write-Host "  - Suspicious: Potentially harmful behavior detected" -ForegroundColor Yellow
    Write-Host "  - Harmless: Known safe file/URL" -ForegroundColor Green
    Write-Host "  - Undetected: No threat detected" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  PRIVACY NOTE:" -ForegroundColor Yellow
    Write-Host "  This tool only sends file HASHES to VirusTotal," -ForegroundColor Gray
    Write-Host "  NOT the actual files. Your files stay on your system." -ForegroundColor Gray
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    
    Wait-SouliTEKKeyPress
}

function Invoke-CheckFileByPath {
    <#
    .SYNOPSIS
        Checks a file by calculating its hash and querying VirusTotal.
    #>
    
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "  CHECK FILE BY PATH" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Enter the full path to the file to check." -ForegroundColor Gray
    Write-Host "Example: C:\Downloads\setup.exe" -ForegroundColor Gray
    Write-Host ""
    
    $filePath = Read-Host "File path"
    
    if ([string]::IsNullOrWhiteSpace($filePath)) {
        Write-Host "No file path provided." -ForegroundColor Yellow
        Wait-SouliTEKKeyPress
        return
    }
    
    # Remove quotes if present
    $filePath = $filePath.Trim('"').Trim("'")
    
    if (-not (Test-Path $filePath)) {
        Write-Host "File not found: $filePath" -ForegroundColor Red
        Wait-SouliTEKKeyPress
        return
    }
    
    Write-Host ""
    Write-Host "Calculating file hashes..." -ForegroundColor Cyan
    
    $hashInfo = Get-FileHashInfo -FilePath $filePath
    if (-not $hashInfo) {
        Write-Host "Failed to calculate file hash." -ForegroundColor Red
        Wait-SouliTEKKeyPress
        return
    }
    
    Write-Host ""
    Write-Host "  File: $($hashInfo.FileName)" -ForegroundColor White
    Write-Host "  Size: $(Format-SouliTEKFileSize -SizeInBytes $hashInfo.FileSize)" -ForegroundColor Gray
    Write-Host "  MD5:    $($hashInfo.MD5)" -ForegroundColor Gray
    Write-Host "  SHA1:   $($hashInfo.SHA1)" -ForegroundColor Gray
    Write-Host "  SHA256: $($hashInfo.SHA256)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Checking against VirusTotal..." -ForegroundColor Cyan
    
    $result = Invoke-VTFileCheck -Hash $hashInfo.SHA256
    Show-VTFileResult -Result $result -FileName $hashInfo.FileName
    
    Wait-SouliTEKKeyPress
}

function Invoke-CheckFileByHash {
    <#
    .SYNOPSIS
        Checks a file by its hash.
    #>
    
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "  CHECK FILE BY HASH" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Enter the file hash (MD5, SHA1, or SHA256)." -ForegroundColor Gray
    Write-Host ""
    
    $hash = Read-Host "File hash"
    
    if ([string]::IsNullOrWhiteSpace($hash)) {
        Write-Host "No hash provided." -ForegroundColor Yellow
        Wait-SouliTEKKeyPress
        return
    }
    
    $hash = $hash.Trim()
    
    # Validate hash format
    $validLengths = @(32, 40, 64)  # MD5, SHA1, SHA256
    if ($hash.Length -notin $validLengths) {
        Write-Host "Invalid hash format. Expected MD5 (32), SHA1 (40), or SHA256 (64) characters." -ForegroundColor Red
        Wait-SouliTEKKeyPress
        return
    }
    
    if ($hash -notmatch '^[a-fA-F0-9]+$') {
        Write-Host "Invalid hash format. Hash must contain only hexadecimal characters." -ForegroundColor Red
        Wait-SouliTEKKeyPress
        return
    }
    
    Write-Host ""
    Write-Host "Checking hash against VirusTotal..." -ForegroundColor Cyan
    
    $result = Invoke-VTFileCheck -Hash $hash
    Show-VTFileResult -Result $result -FileName "Hash: $hash"
    
    Wait-SouliTEKKeyPress
}

function Invoke-CheckUrl {
    <#
    .SYNOPSIS
        Checks a URL against VirusTotal.
    #>
    
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "  CHECK URL" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Enter the URL to check (including http:// or https://)." -ForegroundColor Gray
    Write-Host "Example: https://example.com/download.exe" -ForegroundColor Gray
    Write-Host ""
    
    $url = Read-Host "URL"
    
    if ([string]::IsNullOrWhiteSpace($url)) {
        Write-Host "No URL provided." -ForegroundColor Yellow
        Wait-SouliTEKKeyPress
        return
    }
    
    $url = $url.Trim()
    
    # Basic URL validation
    if ($url -notmatch '^https?://') {
        Write-Host "Adding https:// prefix..." -ForegroundColor Yellow
        $url = "https://$url"
    }
    
    Write-Host ""
    Write-Host "Checking URL against VirusTotal..." -ForegroundColor Cyan
    
    $result = Invoke-VTUrlCheck -Url $url
    Show-VTUrlResult -Result $result -Url $url
    
    Wait-SouliTEKKeyPress
}

function Invoke-BatchCheckFiles {
    <#
    .SYNOPSIS
        Checks multiple files in a folder.
    #>
    
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "  BATCH CHECK FILES" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Enter the folder path containing files to check." -ForegroundColor Gray
    Write-Host "Example: C:\Downloads" -ForegroundColor Gray
    Write-Host ""
    
    $folderPath = Read-Host "Folder path"
    
    if ([string]::IsNullOrWhiteSpace($folderPath)) {
        Write-Host "No folder path provided." -ForegroundColor Yellow
        Wait-SouliTEKKeyPress
        return
    }
    
    $folderPath = $folderPath.Trim('"').Trim("'")
    
    if (-not (Test-Path $folderPath -PathType Container)) {
        Write-Host "Folder not found: $folderPath" -ForegroundColor Red
        Wait-SouliTEKKeyPress
        return
    }
    
    Write-Host ""
    Write-Host "File extensions to check (e.g., exe,dll,msi) or * for all:" -ForegroundColor Gray
    $extensions = Read-Host "Extensions"
    
    if ([string]::IsNullOrWhiteSpace($extensions)) {
        $extensions = "*"
    }
    
    # Get files
    $files = @()
    if ($extensions -eq "*") {
        $files = Get-ChildItem -Path $folderPath -File -ErrorAction SilentlyContinue
    } else {
        $extArray = $extensions -split ',' | ForEach-Object { "*.$($_.Trim())" }
        foreach ($ext in $extArray) {
            $files += Get-ChildItem -Path $folderPath -Filter $ext -File -ErrorAction SilentlyContinue
        }
    }
    
    if ($files.Count -eq 0) {
        Write-Host "No files found matching criteria." -ForegroundColor Yellow
        Wait-SouliTEKKeyPress
        return
    }
    
    # Limit to prevent API rate limiting
    $maxFiles = 10
    if ($files.Count -gt $maxFiles) {
        Write-Host ""
        Write-Host "Found $($files.Count) files. Due to API rate limits, only first $maxFiles will be checked." -ForegroundColor Yellow
        Write-Host "Free API allows 4 requests per minute." -ForegroundColor Gray
        $files = $files | Select-Object -First $maxFiles
    }
    
    Write-Host ""
    Write-Host "Checking $($files.Count) file(s)..." -ForegroundColor Cyan
    Write-Host ""
    
    $index = 1
    foreach ($file in $files) {
        Write-Host "[$index/$($files.Count)] $($file.Name)" -ForegroundColor White
        
        $hashInfo = Get-FileHashInfo -FilePath $file.FullName
        if ($hashInfo) {
            $result = Invoke-VTFileCheck -Hash $hashInfo.SHA256
            if ($result) {
                if ($result.NotFound) {
                    Write-Host "  Status: Not in database" -ForegroundColor Yellow
                } else {
                    $stats = $result.attributes.last_analysis_stats
                    $mal = $stats.malicious
                    $sus = $stats.suspicious
                    
                    if ($mal -gt 0) {
                        Write-Host "  Status: $mal malicious detections" -ForegroundColor Red
                    } elseif ($sus -gt 0) {
                        Write-Host "  Status: $sus suspicious detections" -ForegroundColor Yellow
                    } else {
                        Write-Host "  Status: Clean" -ForegroundColor Green
                    }
                }
            }
        } else {
            Write-Host "  Status: Failed to hash" -ForegroundColor Red
        }
        
        Write-Host ""
        $index++
        
        # Rate limiting delay (free API: 4 req/min)
        if ($index -le $files.Count) {
            Start-Sleep -Seconds 15
        }
    }
    
    Write-Host "Batch check complete!" -ForegroundColor Green
    Wait-SouliTEKKeyPress
}

function Show-ScanResults {
    <#
    .SYNOPSIS
        Displays scan results from the current session.
    #>
    
    Clear-Host
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "  SCAN RESULTS - THIS SESSION" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    
    if ($Script:ScanResults.Count -eq 0) {
        Write-Host "No scan results yet." -ForegroundColor Yellow
        Write-Host "Use options 1-4 to scan files or URLs." -ForegroundColor Gray
        Wait-SouliTEKKeyPress
        return
    }
    
    $index = 1
    foreach ($result in $Script:ScanResults) {
        $statusColor = "Green"
        if ($result.Malicious -gt 0) {
            $statusColor = "Red"
        } elseif ($result.Suspicious -gt 0) {
            $statusColor = "Yellow"
        }
        
        Write-Host "[$index] $($result.Type): " -NoNewline -ForegroundColor White
        Write-Host $result.Target -ForegroundColor Cyan
        Write-Host "    Status: " -NoNewline -ForegroundColor Gray
        Write-Host $result.Status -ForegroundColor $statusColor
        Write-Host "    Detections: Mal=$($result.Malicious), Sus=$($result.Suspicious)" -ForegroundColor Gray
        Write-Host ""
        $index++
    }
    
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "Total: $($Script:ScanResults.Count) scan(s)" -ForegroundColor White
    
    Wait-SouliTEKKeyPress
}

function Export-ScanResults {
    <#
    .SYNOPSIS
        Exports scan results to a file.
    #>
    
    if ($Script:ScanResults.Count -eq 0) {
        Write-Host ""
        Write-Host "No scan results to export." -ForegroundColor Yellow
        Wait-SouliTEKKeyPress
        return
    }
    
    $format = Show-SouliTEKExportMenu -Title "EXPORT SCAN RESULTS"
    
    if ($format -eq "CANCEL") {
        return
    }
    
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $desktopPath = [Environment]::GetFolderPath("Desktop")
    
    if ($format -eq "ALL") {
        $formats = @("TXT", "CSV", "HTML")
    } else {
        $formats = @($format)
    }
    
    foreach ($fmt in $formats) {
        $extension = $fmt.ToLower()
        $outputPath = Join-Path $desktopPath "VirusTotal_Scan_Results_$timestamp.$extension"
        
        $extraInfo = @{
            "Total Scans" = $Script:ScanResults.Count
            "Malicious Found" = ($Script:ScanResults | Where-Object { $_.Malicious -gt 0 }).Count
        }
        
        Export-SouliTEKReport -Data $Script:ScanResults -Title "VirusTotal Scan Results" `
                             -Format $fmt -OutputPath $outputPath -ExtraInfo $extraInfo `
                             -OpenAfterExport:($formats.Count -eq 1)
    }
    
    Wait-SouliTEKKeyPress
}

function Set-ApiKey {
    <#
    .SYNOPSIS
        Configures the VirusTotal API key.
    #>
    
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "  CONFIGURE API KEY" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    
    if ($Script:ApiKey) {
        $masked = $Script:ApiKey.Substring(0, 8) + "..." + $Script:ApiKey.Substring(56)
        Write-Host "Current API key: $masked" -ForegroundColor Gray
        Write-Host ""
    }
    
    Write-Host "[1] Enter new API key" -ForegroundColor Yellow
    Write-Host "[2] Remove saved API key" -ForegroundColor Yellow
    Write-Host "[0] Cancel" -ForegroundColor Gray
    Write-Host ""
    
    $choice = Read-Host "Select option"
    
    switch ($choice) {
        "1" {
            $Script:ApiKey = $null
            $null = Get-VTApiKey
        }
        "2" {
            if (Test-Path $Script:ApiKeyPath) {
                Remove-Item $Script:ApiKeyPath -Force
                Write-Host "Saved API key removed." -ForegroundColor Green
            }
            $Script:ApiKey = $null
        }
    }
    
    Wait-SouliTEKKeyPress
}

# ============================================================
# MAIN EXECUTION
# ============================================================

# Show banner
Clear-Host
Show-ScriptBanner -ScriptName "VirusTotal Checker" -Purpose "Check files and URLs against VirusTotal database for malware detection"

# Load System.Web for URL encoding
Add-Type -AssemblyName System.Web

# Main loop
do {
    Show-Menu
    $choice = Read-Host "Select option (0-8)"
    
    switch ($choice) {
        "1" { Invoke-CheckFileByPath }
        "2" { Invoke-CheckFileByHash }
        "3" { Invoke-CheckUrl }
        "4" { Invoke-BatchCheckFiles }
        "5" { Show-ScanResults }
        "6" { Export-ScanResults }
        "7" { Set-ApiKey }
        "8" { Show-Help }
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

