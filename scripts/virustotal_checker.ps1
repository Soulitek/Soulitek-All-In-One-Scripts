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
            $decrypted = Unprotect-SouliTEKSecret -FilePath $Script:ApiKeyPath
            if ($decrypted -and $decrypted.Length -eq 64) {
                $Script:ApiKey = $decrypted
                return $Script:ApiKey
            }
            # Falls through to prompt — handles legacy plaintext files gracefully
        }
        catch {
            # Continue to prompt
        }
    }
    
    # Prompt for API key
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Yellow
    Write-Ui -Message "  VIRUSTOTAL API KEY REQUIRED" -Level "WARN"
    Write-Host "============================================================" -ForegroundColor Yellow
    Write-Host ""
    Write-Ui -Message "To use this tool, you need a free VirusTotal API key." -Level "STEP"
    Write-Host ""
    Write-Ui -Message "How to get your API key:" -Level "INFO"
    Write-Host "  1. Go to https://www.virustotal.com" -ForegroundColor Gray
    Write-Ui -Message "  2. Create a free account or sign in" -Level "INFO"
    Write-Ui -Message "  3. Go to your profile settings" -Level "INFO"
    Write-Ui -Message "  4. Find and copy your API key" -Level "INFO"
    Write-Host ""
    Write-Ui -Message "Note: Free API allows 4 requests per minute." -Level "WARN"
    Write-Host ""
    
    $secureKey = Read-Host -AsSecureString "Enter your VirusTotal API key (64 characters)"
    $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureKey)
    $key = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
    [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
    
    if ($key.Length -ne 64) {
        Write-Ui -Message "Invalid API key format. API key must be 64 characters." -Level "ERROR"
        return $null
    }
    
    # Test the API key
    Write-Host ""
    Write-Ui -Message "Testing API key..." -Level "INFO"
    
    try {
        $headers = @{
            "x-apikey" = $key
        }
        $testUrl = "$Script:VTApiUrl/files/275a021bbfb6489e54d471899f7db9d1663fc695ec2fe2a2c4538aabf651fd0f"
        $response = Invoke-RestMethod -Uri $testUrl -Headers $headers -Method Get -ErrorAction Stop
        
        Write-Ui -Message "API key validated successfully!" -Level "OK"
        
        # Save the API key
        $saveChoice = Read-Host "Save API key for future use? (Y/N)"
        if ($saveChoice -eq "Y" -or $saveChoice -eq "y") {
            $keyDir = Split-Path -Parent $Script:ApiKeyPath
            if (-not (Test-Path $keyDir)) {
                New-Item -ItemType Directory -Path $keyDir -Force | Out-Null
            }
            $secureForStorage = ConvertTo-SecureString -String $key -AsPlainText -Force
            if (Protect-SouliTEKSecret -SecureValue $secureForStorage -FilePath $Script:ApiKeyPath) {
                Write-Ui -Message "API key saved securely (DPAPI-encrypted)." -Level "OK"
            } else {
                Write-Ui -Message "Could not save API key securely. It will be used for this session only." -Level "WARN"
            }
        }
        
        $Script:ApiKey = $key
        return $key
    }
    catch {
        Write-Ui -Message "API key validation failed: $($_.Exception.Message)" -Level "ERROR"
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
        Write-Ui -Message "Error checking file: $($_.Exception.Message)" -Level "ERROR"
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
        Write-Ui -Message "Error checking URL: $($_.Exception.Message)" -Level "ERROR"
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
        Write-Ui -Message "Error submitting URL for scan: $($_.Exception.Message)" -Level "ERROR"
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
        Write-Ui -Message "  FILE NOT FOUND IN VIRUSTOTAL DATABASE" -Level "WARN"
        Write-Host "============================================================" -ForegroundColor Yellow
        Write-Host ""
        Write-Ui -Message "This file has not been analyzed by VirusTotal yet." -Level "STEP"
        Write-Ui -Message "This could mean:" -Level "INFO"
        Write-Ui -Message "  - The file is unique/custom" -Level "INFO"
        Write-Ui -Message "  - The file has never been submitted for scanning" -Level "INFO"
        Write-Host ""
        Write-Ui -Message "Note: To upload files for scanning, use the VirusTotal website." -Level "WARN"
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
    Write-Ui -Message "  VIRUSTOTAL SCAN RESULTS" -Level "INFO"
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
    
    Write-Ui -Message "  Detection Results:" -Level "STEP"
    Write-Host "  |- Malicious:  " -NoNewline -ForegroundColor Gray
    Write-Host "$malicious" -ForegroundColor $(if ($malicious -gt 0) { "Red" } else { "Green" })
    Write-Host "  |- Suspicious: " -NoNewline -ForegroundColor Gray
    Write-Host "$suspicious" -ForegroundColor $(if ($suspicious -gt 0) { "Yellow" } else { "Green" })
    Write-Host "  |- Harmless:   " -NoNewline -ForegroundColor Gray
    Write-Ui -Message "$harmless" -Level "OK"
    Write-Host "  \- Undetected: " -NoNewline -ForegroundColor Gray
    Write-Ui -Message "$undetected" -Level "INFO"
    Write-Host ""
    
    Write-Ui -Message "  File Information:" -Level "STEP"
    if ($attrs.meaningful_name) {
        Write-Ui -Message "  |- Name: $($attrs.meaningful_name)" -Level "INFO"
    }
    if ($attrs.type_description) {
        Write-Ui -Message "  |- Type: $($attrs.type_description)" -Level "INFO"
    }
    if ($attrs.size) {
        $sizeFormatted = Format-SouliTEKFileSize -SizeInBytes $attrs.size
        Write-Ui -Message "  |- Size: $sizeFormatted" -Level "INFO"
    }
    if ($attrs.sha256) {
        Write-Ui -Message "  \- SHA256: $($attrs.sha256)" -Level "INFO"
    }
    Write-Host ""
    
    if ($attrs.last_analysis_date) {
        $scanDate = [DateTimeOffset]::FromUnixTimeSeconds($attrs.last_analysis_date).DateTime.ToString("yyyy-MM-dd HH:mm:ss")
        Write-Ui -Message "  Last Scan: $scanDate" -Level "INFO"
    }
    
    # Show popular threat names if malicious
    if ($malicious -gt 0 -and $attrs.popular_threat_classification) {
        Write-Host ""
        Write-Ui -Message "  Detected Threats:" -Level "ERROR"
        if ($attrs.popular_threat_classification.suggested_threat_label) {
            Write-Ui -Message "  \- $($attrs.popular_threat_classification.suggested_threat_label)" -Level "ERROR"
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
        Write-Ui -Message "  URL NOT FOUND IN VIRUSTOTAL DATABASE" -Level "WARN"
        Write-Host "============================================================" -ForegroundColor Yellow
        Write-Host ""
        Write-Ui -Message "This URL has not been analyzed by VirusTotal recently." -Level "STEP"
        Write-Host ""
        
        $submitChoice = Read-Host "Submit URL for scanning? (Y/N)"
        if ($submitChoice -eq "Y" -or $submitChoice -eq "y") {
            Write-Ui -Message "Submitting URL for scanning..." -Level "INFO"
            $scanResult = Invoke-VTUrlScan -Url $Url
            if ($scanResult) {
                Write-Ui -Message "URL submitted successfully!" -Level "OK"
                Write-Ui -Message "Analysis ID: $($scanResult.id)" -Level "INFO"
                Write-Host ""
                Write-Ui -Message "Please wait 30-60 seconds and check again for results." -Level "WARN"
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
    Write-Ui -Message "  VIRUSTOTAL URL SCAN RESULTS" -Level "INFO"
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
    
    Write-Ui -Message "  URL: $Url" -Level "STEP"
    Write-Host ""
    Write-Host "  Status: " -NoNewline -ForegroundColor White
    Write-Host $threatLevel -ForegroundColor $threatColor
    Write-Host ""
    
    Write-Ui -Message "  Detection Results:" -Level "STEP"
    Write-Host "  |- Malicious:  " -NoNewline -ForegroundColor Gray
    Write-Host "$malicious" -ForegroundColor $(if ($malicious -gt 0) { "Red" } else { "Green" })
    Write-Host "  |- Suspicious: " -NoNewline -ForegroundColor Gray
    Write-Host "$suspicious" -ForegroundColor $(if ($suspicious -gt 0) { "Yellow" } else { "Green" })
    Write-Host "  |- Harmless:   " -NoNewline -ForegroundColor Gray
    Write-Ui -Message "$harmless" -Level "OK"
    Write-Host "  \- Undetected: " -NoNewline -ForegroundColor Gray
    Write-Ui -Message "$undetected" -Level "INFO"
    Write-Host ""
    
    if ($attrs.last_final_url -and $attrs.last_final_url -ne $Url) {
        Write-Ui -Message "  Final URL (redirects): $($attrs.last_final_url)" -Level "WARN"
    }
    
    if ($attrs.last_analysis_date) {
        $scanDate = [DateTimeOffset]::FromUnixTimeSeconds($attrs.last_analysis_date).DateTime.ToString("yyyy-MM-dd HH:mm:ss")
        Write-Ui -Message "  Last Scan: $scanDate" -Level "INFO"
    }
    
    # Categories
    if ($attrs.categories -and $attrs.categories.Count -gt 0) {
        Write-Host ""
        Write-Ui -Message "  Categories:" -Level "STEP"
        foreach ($vendor in $attrs.categories.PSObject.Properties) {
            Write-Ui -Message "  \- [$($vendor.Name)] $($vendor.Value)" -Level "INFO"
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
    Write-Ui -Message "  VIRUSTOTAL CHECKER v$Script:Version" -Level "OK"
    Write-Ui -Message "  Check files and URLs against VirusTotal" -Level "INFO"
    Write-Host "============================================================" -ForegroundColor Green
    Write-Host ""
    
    # Show API key status
    if ($Script:ApiKey) {
        Write-Host "  API Key: " -NoNewline -ForegroundColor Gray
        Write-Ui -Message "Configured" -Level "OK"
    } else {
        Write-Host "  API Key: " -NoNewline -ForegroundColor Gray
        Write-Ui -Message "Not configured" -Level "WARN"
    }
    
    if ($Script:ScanResults.Count -gt 0) {
        Write-Ui -Message "  Results in session: $($Script:ScanResults.Count)" -Level "INFO"
    }
    
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Ui -Message "  [1] Check File by Path" -Level "WARN"
    Write-Ui -Message "      Calculate hash and check against VirusTotal" -Level "INFO"
    Write-Host ""
    Write-Ui -Message "  [2] Check File by Hash" -Level "WARN"
    Write-Ui -Message "      Enter MD5, SHA1, or SHA256 hash directly" -Level "INFO"
    Write-Host ""
    Write-Ui -Message "  [3] Check URL" -Level "WARN"
    Write-Ui -Message "      Check if a URL is malicious" -Level "INFO"
    Write-Host ""
    Write-Ui -Message "  [4] Batch Check Files" -Level "WARN"
    Write-Ui -Message "      Check multiple files in a folder" -Level "INFO"
    Write-Host ""
    Write-Ui -Message "  [5] View Scan Results" -Level "WARN"
    Write-Ui -Message "      View results from this session" -Level "INFO"
    Write-Host ""
    Write-Ui -Message "  [6] Export Results" -Level "WARN"
    Write-Ui -Message "      Export scan results to file" -Level "INFO"
    Write-Host ""
    Write-Ui -Message "  [7] Configure API Key" -Level "WARN"
    Write-Ui -Message "      Set or change VirusTotal API key" -Level "INFO"
    Write-Host ""
    Write-Ui -Message "  [8] Help" -Level "WARN"
    Write-Ui -Message "      Show usage instructions" -Level "INFO"
    Write-Host ""
    Write-Ui -Message "  [0] Exit" -Level "ERROR"
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
    Write-Ui -Message "  VIRUSTOTAL CHECKER - HELP" -Level "INFO"
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Ui -Message "  ABOUT:" -Level "WARN"
    Write-Ui -Message "  This tool checks files and URLs against VirusTotal's" -Level "INFO"
    Write-Ui -Message "  extensive malware database using their API." -Level "INFO"
    Write-Host ""
    Write-Ui -Message "  FEATURES:" -Level "WARN"
    Write-Ui -Message "  - Check local files (calculates hash automatically)" -Level "INFO"
    Write-Ui -Message "  - Check files by hash (MD5, SHA1, SHA256)" -Level "INFO"
    Write-Ui -Message "  - Check URLs for malicious content" -Level "INFO"
    Write-Ui -Message "  - Batch check multiple files" -Level "INFO"
    Write-Ui -Message "  - Export results to TXT, CSV, or HTML" -Level "INFO"
    Write-Host ""
    Write-Ui -Message "  API KEY:" -Level "WARN"
    Write-Ui -Message "  A free VirusTotal API key is required." -Level "INFO"
    Write-Host "  Get yours at: https://www.virustotal.com" -ForegroundColor Cyan
    Write-Ui -Message "  Free tier: 4 requests per minute, 500 per day" -Level "INFO"
    Write-Host ""
    Write-Ui -Message "  UNDERSTANDING RESULTS:" -Level "WARN"
    Write-Ui -Message "  - Malicious: Detected as malware by engines" -Level "ERROR"
    Write-Ui -Message "  - Suspicious: Potentially harmful behavior detected" -Level "WARN"
    Write-Ui -Message "  - Harmless: Known safe file/URL" -Level "OK"
    Write-Ui -Message "  - Undetected: No threat detected" -Level "INFO"
    Write-Host ""
    Write-Ui -Message "  PRIVACY NOTE:" -Level "WARN"
    Write-Ui -Message "  This tool only sends file HASHES to VirusTotal," -Level "INFO"
    Write-Ui -Message "  NOT the actual files. Your files stay on your system." -Level "INFO"
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
    Write-Ui -Message "  CHECK FILE BY PATH" -Level "INFO"
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Ui -Message "Enter the full path to the file to check." -Level "INFO"
    Write-Ui -Message "Example: C:\Downloads\setup.exe" -Level "INFO"
    Write-Host ""
    
    $filePath = Read-Host "File path"
    
    if ([string]::IsNullOrWhiteSpace($filePath)) {
        Write-Ui -Message "No file path provided." -Level "WARN"
        Wait-SouliTEKKeyPress
        return
    }
    
    # Remove quotes if present
    $filePath = $filePath.Trim('"').Trim("'")
    
    if (-not (Test-Path $filePath)) {
        Write-Ui -Message "File not found: $filePath" -Level "ERROR"
        Wait-SouliTEKKeyPress
        return
    }
    
    Write-Host ""
    Write-Ui -Message "Calculating file hashes..." -Level "INFO"
    
    $hashInfo = Get-FileHashInfo -FilePath $filePath
    if (-not $hashInfo) {
        Write-Ui -Message "Failed to calculate file hash." -Level "ERROR"
        Wait-SouliTEKKeyPress
        return
    }
    
    Write-Host ""
    Write-Ui -Message "  File: $($hashInfo.FileName)" -Level "STEP"
    Write-Ui -Message "  Size: $(Format-SouliTEKFileSize -SizeInBytes $hashInfo.FileSize)" -Level "INFO"
    Write-Ui -Message "  MD5:    $($hashInfo.MD5)" -Level "INFO"
    Write-Ui -Message "  SHA1:   $($hashInfo.SHA1)" -Level "INFO"
    Write-Ui -Message "  SHA256: $($hashInfo.SHA256)" -Level "INFO"
    Write-Host ""
    Write-Ui -Message "Checking against VirusTotal..." -Level "INFO"
    
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
    Write-Ui -Message "  CHECK FILE BY HASH" -Level "INFO"
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Ui -Message "Enter the file hash (MD5, SHA1, or SHA256)." -Level "INFO"
    Write-Host ""
    
    $hash = Read-Host "File hash"
    
    if ([string]::IsNullOrWhiteSpace($hash)) {
        Write-Ui -Message "No hash provided." -Level "WARN"
        Wait-SouliTEKKeyPress
        return
    }
    
    $hash = $hash.Trim()
    
    # Validate hash format
    $validLengths = @(32, 40, 64)  # MD5, SHA1, SHA256
    if ($hash.Length -notin $validLengths) {
        Write-Ui -Message "Invalid hash format. Expected MD5 (32), SHA1 (40), or SHA256 (64) characters." -Level "ERROR"
        Wait-SouliTEKKeyPress
        return
    }
    
    if ($hash -notmatch '^[a-fA-F0-9]+$') {
        Write-Ui -Message "Invalid hash format. Hash must contain only hexadecimal characters." -Level "ERROR"
        Wait-SouliTEKKeyPress
        return
    }
    
    Write-Host ""
    Write-Ui -Message "Checking hash against VirusTotal..." -Level "INFO"
    
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
    Write-Ui -Message "  CHECK URL" -Level "INFO"
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Enter the URL to check (including http:// or https://)." -ForegroundColor Gray
    Write-Host "Example: https://example.com/download.exe" -ForegroundColor Gray
    Write-Host ""
    
    $url = Read-Host "URL"
    
    if ([string]::IsNullOrWhiteSpace($url)) {
        Write-Ui -Message "No URL provided." -Level "WARN"
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
    Write-Ui -Message "Checking URL against VirusTotal..." -Level "INFO"
    
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
    Write-Ui -Message "  BATCH CHECK FILES" -Level "INFO"
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Ui -Message "Enter the folder path containing files to check." -Level "INFO"
    Write-Ui -Message "Example: C:\Downloads" -Level "INFO"
    Write-Host ""
    
    $folderPath = Read-Host "Folder path"
    
    if ([string]::IsNullOrWhiteSpace($folderPath)) {
        Write-Ui -Message "No folder path provided." -Level "WARN"
        Wait-SouliTEKKeyPress
        return
    }
    
    $folderPath = $folderPath.Trim('"').Trim("'")
    
    if (-not (Test-Path $folderPath -PathType Container)) {
        Write-Ui -Message "Folder not found: $folderPath" -Level "ERROR"
        Wait-SouliTEKKeyPress
        return
    }
    
    Write-Host ""
    Write-Ui -Message "File extensions to check (e.g., exe,dll,msi) or * for all:" -Level "INFO"
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
        Write-Ui -Message "No files found matching criteria." -Level "WARN"
        Wait-SouliTEKKeyPress
        return
    }
    
    # Limit to prevent API rate limiting
    $maxFiles = 10
    if ($files.Count -gt $maxFiles) {
        Write-Host ""
        Write-Ui -Message "Found $($files.Count) files. Due to API rate limits, only first $maxFiles will be checked." -Level "WARN"
        Write-Ui -Message "Free API allows 4 requests per minute." -Level "INFO"
        $files = $files | Select-Object -First $maxFiles
    }
    
    Write-Host ""
    Write-Ui -Message "Checking $($files.Count) file(s)..." -Level "INFO"
    Write-Host ""
    
    $index = 1
    foreach ($file in $files) {
        Write-Ui -Message "[$index/$($files.Count)] $($file.Name)" -Level "STEP"
        
        $hashInfo = Get-FileHashInfo -FilePath $file.FullName
        if ($hashInfo) {
            $result = Invoke-VTFileCheck -Hash $hashInfo.SHA256
            if ($result) {
                if ($result.NotFound) {
                    Write-Ui -Message "  Status: Not in database" -Level "WARN"
                } else {
                    $stats = $result.attributes.last_analysis_stats
                    $mal = $stats.malicious
                    $sus = $stats.suspicious
                    
                    if ($mal -gt 0) {
                        Write-Ui -Message "  Status: $mal malicious detections" -Level "ERROR"
                    } elseif ($sus -gt 0) {
                        Write-Ui -Message "  Status: $sus suspicious detections" -Level "WARN"
                    } else {
                        Write-Ui -Message "  Status: Clean" -Level "OK"
                    }
                }
            }
        } else {
            Write-Ui -Message "  Status: Failed to hash" -Level "ERROR"
        }
        
        Write-Host ""
        $index++
        
        # Rate limiting delay (free API: 4 req/min)
        if ($index -le $files.Count) {
            Start-Sleep -Seconds 15
        }
    }
    
    Write-Ui -Message "Batch check complete!" -Level "OK"
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
    Write-Ui -Message "  SCAN RESULTS - THIS SESSION" -Level "INFO"
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    
    if ($Script:ScanResults.Count -eq 0) {
        Write-Ui -Message "No scan results yet." -Level "WARN"
        Write-Ui -Message "Use options 1-4 to scan files or URLs." -Level "INFO"
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
        Write-Ui -Message $result.Target -Level "INFO"
        Write-Host "    Status: " -NoNewline -ForegroundColor Gray
        Write-Host $result.Status -ForegroundColor $statusColor
        Write-Ui -Message "    Detections: Mal=$($result.Malicious), Sus=$($result.Suspicious)" -Level "INFO"
        Write-Host ""
        $index++
    }
    
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Ui -Message "Total: $($Script:ScanResults.Count) scan(s)" -Level "STEP"
    
    Wait-SouliTEKKeyPress
}

function Export-ScanResults {
    <#
    .SYNOPSIS
        Exports scan results to a file.
    #>
    
    if ($Script:ScanResults.Count -eq 0) {
        Write-Host ""
        Write-Ui -Message "No scan results to export." -Level "WARN"
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
    Write-Ui -Message "  CONFIGURE API KEY" -Level "INFO"
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    
    if ($Script:ApiKey) {
        $masked = $Script:ApiKey.Substring(0, 8) + "..." + $Script:ApiKey.Substring(56)
        Write-Ui -Message "Current API key: $masked" -Level "INFO"
        Write-Host ""
    }
    
    Write-Ui -Message "[1] Enter new API key" -Level "WARN"
    Write-Ui -Message "[2] Remove saved API key" -Level "WARN"
    Write-Ui -Message "[0] Cancel" -Level "INFO"
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
                Write-Ui -Message "Saved API key removed." -Level "OK"
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

