# ============================================================
# Domain & DNS Analyzer - Professional Edition
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
# This tool provides comprehensive domain WHOIS and DNS
# analysis for troubleshooting and security verification.
# 
# Features: WHOIS Lookup | DNS Records | Email Security Check
#           SPF/DKIM/DMARC Analysis | Export Results
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

# Set window title
$Host.UI.RawUI.WindowTitle = "DOMAIN & DNS ANALYZER"

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

$Script:AnalysisResults = [System.Collections.ArrayList]::new()
$Script:OutputFolder = Join-Path $env:USERPROFILE "Desktop"
$Script:LastDomain = ""

# Common DKIM selectors to check
$Script:DKIMSelectors = @(
    "google",
    "default",
    "selector1",
    "selector2",
    "s1",
    "s2",
    "k1",
    "dkim",
    "mail",
    "email"
)

# ============================================================
# HELPER FUNCTIONS
# ============================================================

function Get-ValidDomain {
    param([string]$Prompt = "Enter domain name (e.g., example.com)")
    
    $domain = Read-Host $Prompt
    
    if ([string]::IsNullOrWhiteSpace($domain)) {
        return $null
    }
    
    # Remove protocol if present
    $domain = $domain -replace '^https?://', ''
    # Remove www. prefix
    $domain = $domain -replace '^www\.', ''
    # Remove trailing slash and path
    $domain = $domain -replace '/.*$', ''
    # Trim whitespace
    $domain = $domain.Trim()
    
    # Basic domain validation
    if ($domain -notmatch '^[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?)+$') {
        Write-SouliTEKResult "Invalid domain format: $domain" -Level ERROR
        return $null
    }
    
    $Script:LastDomain = $domain
    return $domain
}

function Add-AnalysisResult {
    param(
        [string]$Domain,
        [string]$RecordType,
        [string]$Value,
        [string]$Status,
        [string]$Details = ""
    )
    
    $null = $Script:AnalysisResults.Add([PSCustomObject]@{
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Domain = $Domain
        RecordType = $RecordType
        Value = $Value
        Status = $Status
        Details = $Details
    })
}

# ============================================================
# WHOIS FUNCTIONS (Using Microsoft Sysinternals Whois)
# ============================================================

$Script:WhoisToolChecked = $false
$Script:WhoisToolPath = $null

function Initialize-WhoisTool {
    <#
    .SYNOPSIS
        Ensures Microsoft Sysinternals Whois tool is available.
    #>
    
    if ($Script:WhoisToolChecked -and $Script:WhoisToolPath -and (Test-Path $Script:WhoisToolPath)) {
        return $true
    }
    
    # Set path to whois.exe in tools directory
    # Use $PSScriptRoot (automatic PowerShell variable) for reliable path resolution
    if (-not $PSScriptRoot) {
        Write-Ui -Message "  [-] Cannot determine script path" -Level "ERROR"
        return $false
    }
    
    $ScriptRoot = $PSScriptRoot
    $ProjectRoot = Split-Path -Parent $ScriptRoot
    $WhoisPath = Join-Path $ProjectRoot "tools\whois.exe"
    
    # Check if whois.exe already exists
    if (Test-Path $WhoisPath) {
        $Script:WhoisToolPath = $WhoisPath
        $Script:WhoisToolChecked = $true
        return $true
    }
    
    # Download whois.exe from Sysinternals
    try {
        Write-Host ""
        Write-Ui -Message "  [*] Downloading Microsoft Sysinternals Whois tool..." -Level "WARN"
        Write-Ui -Message "      This is required for WHOIS lookups." -Level "INFO"
        Write-Host ""
        
        # Ensure tools directory exists
        $toolsDir = Split-Path -Parent $WhoisPath
        if (-not (Test-Path $toolsDir)) {
            New-Item -ItemType Directory -Path $toolsDir -Force | Out-Null
        }
        
        # Download from Sysinternals Live
        $whoisUrl = "https://live.sysinternals.com/whois.exe"
        # MAINTENANCE NOTE: Update hash after each Sysinternals whois.exe release.
        # Compute with: (Get-FileHash "$env:TEMP\whois_v.exe" -Algorithm SHA256).Hash
        # Last verified: 2026-04-17
        $whoisExpectedHash = "PASTE_SHA256_HERE"

        Write-Ui -Message "  [*] Downloading from: $whoisUrl" -Level "INFO"

        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest -Uri $whoisUrl -OutFile $WhoisPath -UseBasicParsing -ErrorAction Stop

        if (Test-Path $WhoisPath) {
            # Verify hash
            if ($whoisExpectedHash -ne "PASTE_SHA256_HERE") {
                if (-not (Confirm-SouliTEKFileHash -FilePath $WhoisPath -ExpectedHash $whoisExpectedHash)) {
                    Write-Ui -Message "whois.exe hash verification failed. Binary removed for safety." -Level "ERROR"
                    return $false
                }
            }
            # Verify Authenticode signature
            $sig = Get-AuthenticodeSignature -FilePath $WhoisPath
            if ($sig.Status -ne "Valid") {
                Write-Ui -Message "whois.exe signature invalid ($($sig.Status)). Removing." -Level "ERROR"
                Remove-Item -Path $WhoisPath -Force -ErrorAction SilentlyContinue
                return $false
            }
            Write-Ui -Message "  [+] Whois tool downloaded successfully" -Level "OK"
            $Script:WhoisToolPath = $WhoisPath
            $Script:WhoisToolChecked = $true
            return $true
        } else {
            Write-Ui -Message "  [-] Download failed - file not found" -Level "ERROR"
            return $false
        }
    }
    catch {
        Write-Ui -Message "  [-] Failed to download Whois tool: $($_.Exception.Message)" -Level "ERROR"
        Write-Ui -Message "  [!] Please ensure you have internet connectivity" -Level "WARN"
        Write-Ui -Message "  [!] You can manually download from:" -Level "WARN"
        Write-Host "      https://learn.microsoft.com/en-us/sysinternals/downloads/whois" -ForegroundColor Cyan
        Write-Ui -Message "      And place whois.exe in: $toolsDir" -Level "INFO"
        return $false
    }
}

function Get-DomainWhois {
    param([string]$Domain)
    
    Show-SouliTEKHeader -Title "WHOIS LOOKUP" -Color Yellow -ClearHost -ShowBanner
    
    Write-Ui -Message "      Query domain registration information" -Level "INFO"
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    
    if ([string]::IsNullOrWhiteSpace($Domain)) {
        $Domain = Get-ValidDomain
        if (-not $Domain) {
            Start-Sleep -Seconds 2
            return $null
        }
    }
    
    # Initialize WHOIS tool
    if (-not (Initialize-WhoisTool)) {
        Write-Host ""
        Write-SouliTEKResult "Whois tool not available. Cannot perform lookup." -Level ERROR
        Write-Host ""
        Read-Host "Press Enter to return to main menu"
        return $null
    }
    
    Write-Host ""
    Write-SouliTEKResult "Querying WHOIS data for $Domain..." -Level INFO
    Write-Host ""
    
    $whoisData = $null
    
    try {
        Write-Ui -Message "  [*] Querying WHOIS servers..." -Level "INFO"
        
        # Use Sysinternals Whois tool
        $whoisProcess = Start-Process -FilePath $Script:WhoisToolPath -ArgumentList $Domain -NoNewWindow -Wait -PassThru -RedirectStandardOutput "$env:TEMP\whois_output.txt" -RedirectStandardError "$env:TEMP\whois_error.txt"
        
        if (Test-Path "$env:TEMP\whois_output.txt") {
            $whoisText = Get-Content "$env:TEMP\whois_output.txt" -Raw -ErrorAction SilentlyContinue
            Remove-Item "$env:TEMP\whois_output.txt" -ErrorAction SilentlyContinue
        } else {
            $whoisText = ""
        }
        
        if ($whoisProcess.ExitCode -eq 0 -and $whoisText -and $whoisText.Trim().Length -gt 0) {
            Write-SouliTEKResult "WHOIS query successful" -Level SUCCESS
            
            # Parse the WHOIS result
            $whoisData = [PSCustomObject]@{
                Domain = $Domain
                RawData = $whoisText
                Registrar = ""
                Created = ""
                Updated = ""
                Expires = ""
                NameServers = @()
                Status = ""
                DnsSec = $false
            }
            
            # Extract Registrar
            if ($whoisText -match "Registrar:\s*(.+)") {
                $whoisData.Registrar = $Matches[1].Trim()
            } elseif ($whoisText -match "Registrar Name:\s*(.+)") {
                $whoisData.Registrar = $Matches[1].Trim()
            } elseif ($whoisText -match "registrar:\s*(.+)") {
                $whoisData.Registrar = $Matches[1].Trim()
            }
            
            # Extract Creation Date
            if ($whoisText -match "Creation Date:\s*(.+)") {
                $whoisData.Created = $Matches[1].Trim()
            } elseif ($whoisText -match "Created Date:\s*(.+)") {
                $whoisData.Created = $Matches[1].Trim()
            } elseif ($whoisText -match "created:\s*(.+)") {
                $whoisData.Created = $Matches[1].Trim()
            } elseif ($whoisText -match "Registration Date:\s*(.+)") {
                $whoisData.Created = $Matches[1].Trim()
            }
            
            # Extract Updated Date
            if ($whoisText -match "Updated Date:\s*(.+)") {
                $whoisData.Updated = $Matches[1].Trim()
            } elseif ($whoisText -match "Last Updated:\s*(.+)") {
                $whoisData.Updated = $Matches[1].Trim()
            } elseif ($whoisText -match "changed:\s*(.+)") {
                $whoisData.Updated = $Matches[1].Trim()
            }
            
            # Extract Expiration Date
            if ($whoisText -match "Registry Expiry Date:\s*(.+)") {
                $whoisData.Expires = $Matches[1].Trim()
            } elseif ($whoisText -match "Expiration Date:\s*(.+)") {
                $whoisData.Expires = $Matches[1].Trim()
            } elseif ($whoisText -match "Registrar Registration Expiration Date:\s*(.+)") {
                $whoisData.Expires = $Matches[1].Trim()
            } elseif ($whoisText -match "validity:\s*(.+)") {
                $whoisData.Expires = $Matches[1].Trim()
            } elseif ($whoisText -match "paid-till:\s*(.+)") {
                $whoisData.Expires = $Matches[1].Trim()
            }
            
            # Extract Name Servers
            $nsMatches = [regex]::Matches($whoisText, "Name Server:\s*(.+)", [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
            if ($nsMatches.Count -gt 0) {
                $whoisData.NameServers = $nsMatches | ForEach-Object { $_.Groups[1].Value.Trim().ToLower() } | Select-Object -Unique
            } else {
                $nsMatches = [regex]::Matches($whoisText, "nserver:\s*(.+)", [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
                if ($nsMatches.Count -gt 0) {
                    $whoisData.NameServers = $nsMatches | ForEach-Object { $_.Groups[1].Value.Trim().ToLower() } | Select-Object -Unique
                }
            }
            
            # Extract Status
            $statusMatches = [regex]::Matches($whoisText, "Domain Status:\s*(.+)", [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
            if ($statusMatches.Count -gt 0) {
                $whoisData.Status = ($statusMatches | ForEach-Object { $_.Groups[1].Value.Trim().Split(' ')[0] } | Select-Object -Unique) -join ", "
            } elseif ($whoisText -match "status:\s*(.+)") {
                $whoisData.Status = $Matches[1].Trim()
            }
            
            # Check DNSSEC
            if ($whoisText -match "DNSSEC:\s*(signedDelegation|yes|true)" -or $whoisText -match "dnssec:\s*(yes|active)") {
                $whoisData.DnsSec = $true
            }
            
            # Display results
            Write-Host ""
            Write-Host "============================================================" -ForegroundColor Green
            Write-Ui -Message "  WHOIS INFORMATION FOR $($Domain.ToUpper())" -Level "OK"
            Write-Host "============================================================" -ForegroundColor Green
            Write-Host ""
            
            Write-Host "  Domain:      " -NoNewline -ForegroundColor White
            Write-Ui -Message $whoisData.Domain -Level "INFO"
            
            Write-Host "  Status:      " -NoNewline -ForegroundColor White
            if ($whoisData.Status) {
                $statusColor = if ($whoisData.Status -match "active|ok|clientTransferProhibited") { 'Green' } else { 'Yellow' }
                Write-Host $whoisData.Status -ForegroundColor $statusColor
            } else {
                Write-Ui -Message "N/A" -Level "INFO"
            }
            
            Write-Host "  Registrar:   " -NoNewline -ForegroundColor White
            Write-Ui -Message $(if ($whoisData.Registrar) { $whoisData.Registrar } else { "N/A" }) -Level "INFO"
            
            Write-Host ""
            Write-Ui -Message "  DATES:" -Level "WARN"
            
            # Created Date
            if ($whoisData.Created) {
                Write-Host "  Created:     " -NoNewline -ForegroundColor White
                try {
                    $createdDate = [DateTime]::Parse($whoisData.Created)
                    Write-Ui -Message $createdDate.ToString("yyyy-MM-dd") -Level "INFO"
                } catch {
                    Write-Ui -Message $whoisData.Created -Level "INFO"
                }
            } else {
                Write-Ui -Message "  Created:     N/A" -Level "INFO"
            }
            
            # Updated Date
            if ($whoisData.Updated) {
                Write-Host "  Updated:     " -NoNewline -ForegroundColor White
                try {
                    $updatedDate = [DateTime]::Parse($whoisData.Updated)
                    Write-Ui -Message $updatedDate.ToString("yyyy-MM-dd") -Level "INFO"
                } catch {
                    Write-Ui -Message $whoisData.Updated -Level "INFO"
                }
            } else {
                Write-Ui -Message "  Updated:     N/A" -Level "INFO"
            }
            
            # Expiration Date
            if ($whoisData.Expires) {
                Write-Host "  Expires:     " -NoNewline -ForegroundColor White
                try {
                    $expiresDate = [DateTime]::Parse($whoisData.Expires)
                    $daysUntilExpiry = ($expiresDate - (Get-Date)).Days
                    
                    $expiryColor = if ($daysUntilExpiry -lt 30) { 'Red' } 
                                  elseif ($daysUntilExpiry -lt 90) { 'Yellow' } 
                                  else { 'Green' }
                    Write-Host "$($expiresDate.ToString('yyyy-MM-dd')) " -NoNewline -ForegroundColor $expiryColor
                    Write-Host "($daysUntilExpiry days remaining)" -ForegroundColor $expiryColor
                } catch {
                    Write-Ui -Message $whoisData.Expires -Level "INFO"
                }
            } else {
                Write-Ui -Message "  Expires:     N/A" -Level "INFO"
            }
            
            Write-Host ""
            Write-Ui -Message "  NAME SERVERS:" -Level "WARN"
            if ($whoisData.NameServers -and $whoisData.NameServers.Count -gt 0) {
                foreach ($ns in $whoisData.NameServers) {
                    Write-Ui -Message "    - $ns" -Level "INFO"
                }
            } else {
                # Try to get NS from DNS as fallback
                try {
                    $nsRecords = Resolve-DnsName -Name $Domain -Type NS -ErrorAction SilentlyContinue -DnsOnly
                    if ($nsRecords) {
                        $whoisData.NameServers = ($nsRecords | Where-Object { $_.Type -eq "NS" }).NameHost
                        foreach ($ns in $whoisData.NameServers) {
                            Write-Ui -Message "    - $ns (from DNS)" -Level "INFO"
                        }
                    } else {
                        Write-Ui -Message "    No nameservers found" -Level "INFO"
                    }
                } catch {
                    Write-Ui -Message "    No nameservers found" -Level "INFO"
                }
            }
            
            Write-Host ""
            Write-Host "  DNSSEC:      " -NoNewline -ForegroundColor White
            if ($whoisData.DnsSec) {
                Write-Ui -Message "Enabled" -Level "OK"
            } else {
                Write-Ui -Message "Not Enabled / Unknown" -Level "WARN"
            }
            
            # Add to results
            Add-AnalysisResult -Domain $Domain -RecordType "WHOIS" `
                -Value "Registrar: $($whoisData.Registrar)" `
                -Status $(if ($whoisData.Status -match "active|ok|clientTransferProhibited") { "Active" } else { if ($whoisData.Status) { $whoisData.Status } else { "Unknown" } }) `
                -Details "Expires: $($whoisData.Expires), NS: $($whoisData.NameServers -join ', ')"
            
            Write-Host ""
            Write-Host "============================================================" -ForegroundColor Cyan
            
            # Always show raw WHOIS data
            Write-Host ""
            Write-Host "============================================================" -ForegroundColor Gray
            Write-Ui -Message "  RAW WHOIS DATA" -Level "INFO"
            Write-Host "============================================================" -ForegroundColor Gray
            Write-Ui -Message $whoisText -Level "INFO"
            Write-Host "============================================================" -ForegroundColor Gray
        }
        else {
            $errorText = ""
            if (Test-Path "$env:TEMP\whois_error.txt") {
                $errorText = Get-Content "$env:TEMP\whois_error.txt" -Raw -ErrorAction SilentlyContinue
                Remove-Item "$env:TEMP\whois_error.txt" -ErrorAction SilentlyContinue
            }
            
            if (-not $whoisText -or $whoisText.Trim().Length -eq 0) {
                Write-SouliTEKResult "No WHOIS data returned" -Level WARNING
                if ($errorText) {
                    Write-Ui -Message "  Error: $errorText" -Level "WARN"
                }
                Add-AnalysisResult -Domain $Domain -RecordType "WHOIS" -Value "No data" -Status "Unknown"
            }
        }
    }
    catch {
        Write-Host ""
        Write-SouliTEKResult "WHOIS lookup failed: $($_.Exception.Message)" -Level ERROR
        Write-Host ""
        Write-Ui -Message "Possible reasons:" -Level "WARN"
        Write-Ui -Message "  - Domain does not exist" -Level "INFO"
        Write-Ui -Message "  - WHOIS server unavailable" -Level "INFO"
        Write-Ui -Message "  - Network connectivity issue" -Level "INFO"
        Write-Ui -Message "  - Rate limiting from WHOIS server" -Level "INFO"
        Write-Host ""
        Write-Ui -Message "Try using an online WHOIS service:" -Level "WARN"
        Write-Host "  https://who.is/whois/$Domain" -ForegroundColor Cyan
        
        Add-AnalysisResult -Domain $Domain -RecordType "WHOIS" -Value "Failed" -Status "Error" -Details $_.Exception.Message
    }
    
    Write-Host ""
    Read-Host "Press Enter to return to main menu"
    
    return $whoisData
}

# ============================================================
# DNS LOOKUP FUNCTIONS
# ============================================================

function Get-DNSRecords {
    param([string]$Domain)
    
    Show-SouliTEKHeader -Title "DNS RECORDS LOOKUP" -Color Green -ClearHost -ShowBanner
    
    Write-Ui -Message "      Query all DNS record types for a domain" -Level "INFO"
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    
    if ([string]::IsNullOrWhiteSpace($Domain)) {
        $Domain = Get-ValidDomain
        if (-not $Domain) {
            Start-Sleep -Seconds 2
            return
        }
    }
    
    Write-Host ""
    Write-SouliTEKResult "Querying DNS records for $Domain..." -Level INFO
    Write-Host ""
    
    $recordTypes = @("A", "AAAA", "MX", "TXT", "CNAME", "NS", "SOA", "SRV")
    
    Write-Host "============================================================" -ForegroundColor Green
    Write-Ui -Message "  DNS RECORDS FOR $($Domain.ToUpper())" -Level "OK"
    Write-Host "============================================================" -ForegroundColor Green
    Write-Host ""
    
    foreach ($type in $recordTypes) {
        Write-Ui -Message "  [$type RECORDS]" -Level "WARN"
        
        try {
            $records = Resolve-DnsName -Name $Domain -Type $type -ErrorAction Stop -DnsOnly
            
            if ($records) {
                foreach ($record in $records) {
                    switch ($type) {
                        "A" {
                            if ($record.Type -eq "A") {
                                Write-Ui -Message "    $($record.IPAddress)" -Level "INFO"
                                Add-AnalysisResult -Domain $Domain -RecordType "A" -Value $record.IPAddress -Status "Found"
                            }
                        }
                        "AAAA" {
                            if ($record.Type -eq "AAAA") {
                                Write-Ui -Message "    $($record.IPAddress)" -Level "INFO"
                                Add-AnalysisResult -Domain $Domain -RecordType "AAAA" -Value $record.IPAddress -Status "Found"
                            }
                        }
                        "MX" {
                            if ($record.Type -eq "MX") {
                                Write-Ui -Message "    Priority: $($record.Preference) -> $($record.NameExchange)" -Level "INFO"
                                Add-AnalysisResult -Domain $Domain -RecordType "MX" -Value "$($record.Preference) $($record.NameExchange)" -Status "Found"
                            }
                        }
                        "TXT" {
                            if ($record.Type -eq "TXT") {
                                $txtValue = $record.Strings -join ""
                                # Truncate long TXT records for display
                                $displayValue = if ($txtValue.Length -gt 80) { $txtValue.Substring(0, 77) + "..." } else { $txtValue }
                                Write-Ui -Message "    $displayValue" -Level "INFO"
                                Add-AnalysisResult -Domain $Domain -RecordType "TXT" -Value $txtValue -Status "Found"
                            }
                        }
                        "CNAME" {
                            if ($record.Type -eq "CNAME") {
                                Write-Ui -Message "    $($record.Name) -> $($record.NameHost)" -Level "INFO"
                                Add-AnalysisResult -Domain $Domain -RecordType "CNAME" -Value $record.NameHost -Status "Found"
                            }
                        }
                        "NS" {
                            if ($record.Type -eq "NS") {
                                Write-Ui -Message "    $($record.NameHost)" -Level "INFO"
                                Add-AnalysisResult -Domain $Domain -RecordType "NS" -Value $record.NameHost -Status "Found"
                            }
                        }
                        "SOA" {
                            if ($record.Type -eq "SOA") {
                                Write-Ui -Message "    Primary NS: $($record.PrimaryServer)" -Level "INFO"
                                Write-Ui -Message "    Admin: $($record.NameAdministrator)" -Level "INFO"
                                Write-Ui -Message "    Serial: $($record.SerialNumber)" -Level "INFO"
                                Add-AnalysisResult -Domain $Domain -RecordType "SOA" -Value $record.PrimaryServer -Status "Found" -Details "Serial: $($record.SerialNumber)"
                            }
                        }
                        "SRV" {
                            if ($record.Type -eq "SRV") {
                                Write-Ui -Message "    $($record.Name) -> $($record.NameTarget):$($record.Port) (Priority: $($record.Priority))" -Level "INFO"
                                Add-AnalysisResult -Domain $Domain -RecordType "SRV" -Value "$($record.NameTarget):$($record.Port)" -Status "Found"
                            }
                        }
                    }
                }
            }
        }
        catch {
            Write-Ui -Message "    No $type records found" -Level "INFO"
        }
        
        Write-Host ""
    }
    
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Read-Host "Press Enter to return to main menu"
}

# ============================================================
# EMAIL SECURITY FUNCTIONS
# ============================================================

function Get-EmailSecurityRecords {
    param([string]$Domain)
    
    Show-SouliTEKHeader -Title "EMAIL SECURITY CHECK" -Color Magenta -ClearHost -ShowBanner
    
    Write-Ui -Message "      Analyze SPF, DKIM, and DMARC records" -Level "INFO"
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    
    if ([string]::IsNullOrWhiteSpace($Domain)) {
        $Domain = Get-ValidDomain
        if (-not $Domain) {
            Start-Sleep -Seconds 2
            return
        }
    }
    
    Write-Host ""
    Write-SouliTEKResult "Checking email security records for $Domain..." -Level INFO
    Write-Host ""
    
    $securityScore = 0
    $maxScore = 3
    
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Ui -Message "  EMAIL SECURITY ANALYSIS FOR $($Domain.ToUpper())" -Level "INFO"
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host ""
    
    # ========== SPF CHECK ==========
    Write-Ui -Message "  [SPF - Sender Policy Framework]" -Level "WARN"
    Write-Ui -Message "  Purpose: Specifies which mail servers can send email for your domain" -Level "INFO"
    Write-Host ""
    
    try {
        $txtRecords = Resolve-DnsName -Name $Domain -Type TXT -ErrorAction Stop -DnsOnly
        $spfRecord = $txtRecords | Where-Object { $_.Type -eq "TXT" -and ($_.Strings -join "") -match "^v=spf1" }
        
        if ($spfRecord) {
            $spfValue = $spfRecord.Strings -join ""
            Write-Host "  Status: " -NoNewline -ForegroundColor White
            Write-Ui -Message "FOUND" -Level "OK"
            Write-Ui -Message "  Record: " -Level "STEP"
            Write-Ui -Message "    $spfValue" -Level "INFO"
            
            # Analyze SPF record
            $spfAnalysis = @()
            if ($spfValue -match "-all") {
                $spfAnalysis += "Hard fail (-all) - Strict policy"
                Write-Host "  Policy: " -NoNewline -ForegroundColor White
                Write-Ui -Message "STRICT (Hard Fail)" -Level "OK"
            } elseif ($spfValue -match "~all") {
                $spfAnalysis += "Soft fail (~all) - Moderate policy"
                Write-Host "  Policy: " -NoNewline -ForegroundColor White
                Write-Ui -Message "MODERATE (Soft Fail)" -Level "WARN"
            } elseif ($spfValue -match "\+all") {
                $spfAnalysis += "Pass all (+all) - INSECURE!"
                Write-Host "  Policy: " -NoNewline -ForegroundColor White
                Write-Ui -Message "INSECURE (Pass All)" -Level "ERROR"
            } elseif ($spfValue -match "\?all") {
                $spfAnalysis += "Neutral (?all) - No policy"
                Write-Host "  Policy: " -NoNewline -ForegroundColor White
                Write-Ui -Message "NEUTRAL (No Policy)" -Level "WARN"
            }
            
            $securityScore++
            Add-AnalysisResult -Domain $Domain -RecordType "SPF" -Value $spfValue -Status "Found" -Details ($spfAnalysis -join "; ")
        } else {
            Write-Host "  Status: " -NoNewline -ForegroundColor White
            Write-Ui -Message "NOT FOUND" -Level "ERROR"
            Write-Ui -Message "  Warning: No SPF record found - email spoofing possible!" -Level "ERROR"
            Add-AnalysisResult -Domain $Domain -RecordType "SPF" -Value "Not configured" -Status "Missing"
        }
    }
    catch {
        Write-Host "  Status: " -NoNewline -ForegroundColor White
        Write-Ui -Message "ERROR" -Level "ERROR"
        Write-Ui -Message "  $($_.Exception.Message)" -Level "INFO"
    }
    
    Write-Host ""
    Write-Host "------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host ""
    
    # ========== DKIM CHECK ==========
    Write-Ui -Message "  [DKIM - DomainKeys Identified Mail]" -Level "WARN"
    Write-Ui -Message "  Purpose: Cryptographically signs emails to verify sender authenticity" -Level "INFO"
    Write-Host ""
    
    $dkimFound = $false
    $foundSelectors = @()
    
    foreach ($selector in $Script:DKIMSelectors) {
        $dkimDomain = "$selector._domainkey.$Domain"
        
        try {
            $dkimRecord = Resolve-DnsName -Name $dkimDomain -Type TXT -ErrorAction Stop -DnsOnly
            
            if ($dkimRecord -and ($dkimRecord.Strings -join "") -match "v=DKIM1") {
                $dkimValue = $dkimRecord.Strings -join ""
                $foundSelectors += @{
                    Selector = $selector
                    Record = $dkimValue
                }
                $dkimFound = $true
            }
        }
        catch {
            # Selector not found, continue to next
        }
    }
    
    if ($dkimFound) {
        Write-Host "  Status: " -NoNewline -ForegroundColor White
        Write-Ui -Message "FOUND" -Level "OK"
        Write-Ui -Message "  Selectors found:" -Level "STEP"
        
        foreach ($found in $foundSelectors) {
            Write-Ui -Message "    - $($found.Selector)._domainkey.$Domain" -Level "INFO"
            $truncatedRecord = if ($found.Record.Length -gt 60) { $found.Record.Substring(0, 57) + "..." } else { $found.Record }
            Write-Ui -Message "      $truncatedRecord" -Level "INFO"
            Add-AnalysisResult -Domain $Domain -RecordType "DKIM" -Value "$($found.Selector)._domainkey" -Status "Found" -Details $found.Record
        }
        
        $securityScore++
    } else {
        Write-Host "  Status: " -NoNewline -ForegroundColor White
        Write-Ui -Message "NOT FOUND" -Level "WARN"
        Write-Ui -Message "  Note: Checked selectors: $($Script:DKIMSelectors -join ', ')" -Level "INFO"
        Write-Ui -Message "  Tip: DKIM may exist with a different selector" -Level "INFO"
        
        # Prompt for custom selector
        Write-Host ""
        $customSelector = Read-Host "  Enter custom DKIM selector to check (or press Enter to skip)"
        
        if (-not [string]::IsNullOrWhiteSpace($customSelector)) {
            $customDkimDomain = "$customSelector._domainkey.$Domain"
            try {
                $customDkimRecord = Resolve-DnsName -Name $customDkimDomain -Type TXT -ErrorAction Stop -DnsOnly
                if ($customDkimRecord -and ($customDkimRecord.Strings -join "") -match "v=DKIM1") {
                    $dkimValue = $customDkimRecord.Strings -join ""
                    Write-Host ""
                    Write-Ui -Message "  DKIM found with selector '$customSelector'!" -Level "OK"
                    Write-Ui -Message "  Record: $dkimValue" -Level "INFO"
                    $dkimFound = $true
                    $securityScore++
                    Add-AnalysisResult -Domain $Domain -RecordType "DKIM" -Value "$customSelector._domainkey" -Status "Found" -Details $dkimValue
                } else {
                    Write-Ui -Message "  No DKIM record found for selector '$customSelector'" -Level "WARN"
                }
            }
            catch {
                Write-Ui -Message "  No DKIM record found for selector '$customSelector'" -Level "WARN"
            }
        }
        
        if (-not $dkimFound) {
            Add-AnalysisResult -Domain $Domain -RecordType "DKIM" -Value "Not found" -Status "Missing"
        }
    }
    
    Write-Host ""
    Write-Host "------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host ""
    
    # ========== DMARC CHECK ==========
    Write-Ui -Message "  [DMARC - Domain-based Message Authentication]" -Level "WARN"
    Write-Ui -Message "  Purpose: Defines policy for handling emails that fail SPF/DKIM" -Level "INFO"
    Write-Host ""
    
    $dmarcDomain = "_dmarc.$Domain"
    
    try {
        $dmarcRecord = Resolve-DnsName -Name $dmarcDomain -Type TXT -ErrorAction Stop -DnsOnly
        $dmarcValue = ($dmarcRecord | Where-Object { $_.Type -eq "TXT" }).Strings -join ""
        
        if ($dmarcValue -match "v=DMARC1") {
            Write-Host "  Status: " -NoNewline -ForegroundColor White
            Write-Ui -Message "FOUND" -Level "OK"
            Write-Ui -Message "  Record: " -Level "STEP"
            Write-Ui -Message "    $dmarcValue" -Level "INFO"
            
            # Parse DMARC policy
            if ($dmarcValue -match "p=reject") {
                Write-Host "  Policy: " -NoNewline -ForegroundColor White
                Write-Ui -Message "REJECT - Strict protection" -Level "OK"
            } elseif ($dmarcValue -match "p=quarantine") {
                Write-Host "  Policy: " -NoNewline -ForegroundColor White
                Write-Ui -Message "QUARANTINE - Moderate protection" -Level "WARN"
            } elseif ($dmarcValue -match "p=none") {
                Write-Host "  Policy: " -NoNewline -ForegroundColor White
                Write-Ui -Message "NONE - Monitoring only" -Level "WARN"
            }
            
            # Check for reporting
            if ($dmarcValue -match "rua=") {
                Write-Host "  Aggregate Reports: " -NoNewline -ForegroundColor White
                Write-Ui -Message "Configured" -Level "OK"
            }
            if ($dmarcValue -match "ruf=") {
                Write-Host "  Forensic Reports: " -NoNewline -ForegroundColor White
                Write-Ui -Message "Configured" -Level "OK"
            }
            
            $securityScore++
            Add-AnalysisResult -Domain $Domain -RecordType "DMARC" -Value $dmarcValue -Status "Found"
        } else {
            Write-Host "  Status: " -NoNewline -ForegroundColor White
            Write-Ui -Message "INVALID" -Level "ERROR"
            Write-Ui -Message "  Record exists but is not valid DMARC" -Level "WARN"
            Add-AnalysisResult -Domain $Domain -RecordType "DMARC" -Value "Invalid" -Status "Error"
        }
    }
    catch {
        Write-Host "  Status: " -NoNewline -ForegroundColor White
        Write-Ui -Message "NOT FOUND" -Level "ERROR"
        Write-Ui -Message "  Warning: No DMARC record - no policy for failed authentication!" -Level "ERROR"
        Add-AnalysisResult -Domain $Domain -RecordType "DMARC" -Value "Not configured" -Status "Missing"
    }
    
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host ""
    
    # Security Score Summary
    Write-Ui -Message "  EMAIL SECURITY SCORE" -Level "STEP"
    Write-Host ""
    
    $scorePercent = [math]::Round(($securityScore / $maxScore) * 100)
    $scoreColor = if ($scorePercent -ge 100) { 'Green' } 
                  elseif ($scorePercent -ge 66) { 'Yellow' } 
                  else { 'Red' }
    
    Write-Host "  Score: " -NoNewline -ForegroundColor White
    Write-Host "$securityScore / $maxScore ($scorePercent%)" -ForegroundColor $scoreColor
    Write-Host ""
    
    # Visual bar (using ASCII characters for compatibility)
    $barLength = 30
    $filledLength = [math]::Round(($securityScore / $maxScore) * $barLength)
    $emptyLength = $barLength - $filledLength
    $filledBar = "#" * $filledLength
    $emptyBar = "-" * $emptyLength
    Write-Host "  [" -NoNewline -ForegroundColor White
    Write-Host $filledBar -NoNewline -ForegroundColor $scoreColor
    Write-Host $emptyBar -NoNewline -ForegroundColor DarkGray
    Write-Ui -Message "]" -Level "STEP"
    Write-Host ""
    
    # Recommendations
    if ($securityScore -lt $maxScore) {
        Write-Ui -Message "  RECOMMENDATIONS:" -Level "WARN"
        if (-not ($Script:AnalysisResults | Where-Object { $_.RecordType -eq "SPF" -and $_.Status -eq "Found" })) {
            Write-Ui -Message "    - Add SPF record to prevent email spoofing" -Level "INFO"
        }
        if (-not $dkimFound) {
            Write-Ui -Message "    - Configure DKIM for email authentication" -Level "INFO"
        }
        if (-not ($Script:AnalysisResults | Where-Object { $_.RecordType -eq "DMARC" -and $_.Status -eq "Found" })) {
            Write-Ui -Message "    - Add DMARC record to define authentication policy" -Level "INFO"
        }
    } else {
        Write-Ui -Message "  All email security records are configured!" -Level "OK"
    }
    
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Read-Host "Press Enter to return to main menu"
}

# ============================================================
# FULL ANALYSIS FUNCTION
# ============================================================

function Get-FullDomainAnalysis {
    param([string]$Domain)
    
    Show-SouliTEKHeader -Title "FULL DOMAIN ANALYSIS" -Color Cyan -ClearHost -ShowBanner
    
    Write-Ui -Message "      Complete WHOIS and DNS analysis" -Level "INFO"
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    
    if ([string]::IsNullOrWhiteSpace($Domain)) {
        $Domain = Get-ValidDomain
        if (-not $Domain) {
            Start-Sleep -Seconds 2
            return
        }
    }
    
    Write-Host ""
    Write-SouliTEKResult "Starting full analysis for $Domain..." -Level INFO
    Write-Host ""
    Write-Ui -Message "This will check:" -Level "WARN"
    Write-Ui -Message "  - WHOIS registration data" -Level "INFO"
    Write-Ui -Message "  - All DNS record types" -Level "INFO"
    Write-Ui -Message "  - Email security (SPF, DKIM, DMARC)" -Level "INFO"
    Write-Host ""
    
    $confirm = Read-Host "Continue? [Y/n]"
    if ($confirm -ne '' -and $confirm -ne 'Y' -and $confirm -ne 'y') {
        return
    }
    
    # Clear previous results for this domain
    $itemsToRemove = $Script:AnalysisResults | Where-Object { $_.Domain -eq $Domain }
    foreach ($item in $itemsToRemove) {
        $null = $Script:AnalysisResults.Remove($item)
    }
    
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Ui -Message "  PART 1: WHOIS INFORMATION" -Level "WARN"
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    
    # Initialize WHOIS tool
    if (-not (Initialize-WhoisTool)) {
        Write-SouliTEKResult "Whois tool not available - skipping WHOIS lookup" -Level WARNING
    }
    else {
        try {
            Write-Ui -Message "  [*] Querying WHOIS..." -Level "INFO"
            
            # Use Sysinternals Whois tool
            $whoisProcess = Start-Process -FilePath $Script:WhoisToolPath -ArgumentList $Domain -NoNewWindow -Wait -PassThru -RedirectStandardOutput "$env:TEMP\whois_output.txt" -RedirectStandardError "$env:TEMP\whois_error.txt"
            
            if (Test-Path "$env:TEMP\whois_output.txt") {
                $whoisText = Get-Content "$env:TEMP\whois_output.txt" -Raw -ErrorAction SilentlyContinue
                Remove-Item "$env:TEMP\whois_output.txt" -ErrorAction SilentlyContinue
            } else {
                $whoisText = ""
            }
            
            if ($whoisProcess.ExitCode -eq 0 -and $whoisText -and $whoisText.Trim().Length -gt 0) {
                
                # Parse registrar
                $registrar = ""
                if ($whoisText -match "Registrar:\s*(.+)") {
                    $registrar = $Matches[1].Trim()
                } elseif ($whoisText -match "registrar:\s*(.+)") {
                    $registrar = $Matches[1].Trim()
                }
                
                # Parse dates
                $created = ""
                $expires = ""
                
                if ($whoisText -match "Creation Date:\s*(.+)") {
                    $created = $Matches[1].Trim()
                } elseif ($whoisText -match "created:\s*(.+)") {
                    $created = $Matches[1].Trim()
                }
                
                if ($whoisText -match "Registry Expiry Date:\s*(.+)") {
                    $expires = $Matches[1].Trim()
                } elseif ($whoisText -match "Expiration Date:\s*(.+)") {
                    $expires = $Matches[1].Trim()
                } elseif ($whoisText -match "paid-till:\s*(.+)") {
                    $expires = $Matches[1].Trim()
                }
                
                # Display
                Write-Ui -Message "  Registrar: $registrar" -Level "INFO"
                
                if ($created) {
                    try {
                        Write-Ui -Message "  Created:   $([DateTime]::Parse($created).ToString('yyyy-MM-dd'))" -Level "INFO"
                    } catch {
                        Write-Ui -Message "  Created:   $created" -Level "INFO"
                    }
                }
                
                if ($expires) {
                    try {
                        $expiresDate = [DateTime]::Parse($expires)
                        $daysUntilExpiry = ($expiresDate - (Get-Date)).Days
                        $expiryColor = if ($daysUntilExpiry -lt 30) { 'Red' } elseif ($daysUntilExpiry -lt 90) { 'Yellow' } else { 'Green' }
                        Write-Host "  Expires:   $($expiresDate.ToString('yyyy-MM-dd')) ($daysUntilExpiry days)" -ForegroundColor $expiryColor
                    } catch {
                        Write-Ui -Message "  Expires:   $expires" -Level "INFO"
                    }
                }
                
                Add-AnalysisResult -Domain $Domain -RecordType "WHOIS" -Value "Registrar: $registrar" -Status "Active" `
                    -Details "Expires: $expires"
                
                Write-SouliTEKResult "WHOIS lookup complete" -Level SUCCESS
            }
        }
        catch {
            Write-SouliTEKResult "WHOIS lookup failed: $($_.Exception.Message)" -Level WARNING
            
            # Fallback to DNS for basic info
            try {
                $nsRecords = Resolve-DnsName -Name $Domain -Type NS -ErrorAction SilentlyContinue -DnsOnly
                if ($nsRecords) {
                    $nsList = ($nsRecords | Where-Object { $_.Type -eq "NS" }).NameHost -join ", "
                    Write-Ui -Message "  Name Servers (from DNS): $nsList" -Level "INFO"
                    Add-AnalysisResult -Domain $Domain -RecordType "WHOIS" -Value "NS: $nsList" -Status "DNS Only"
                }
            }
            catch { }
        }
    }
    
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Ui -Message "  PART 2: DNS RECORDS" -Level "WARN"
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    
    # DNS Records
    $recordTypes = @("A", "AAAA", "MX", "NS", "CNAME")
    
    foreach ($type in $recordTypes) {
        try {
            $records = Resolve-DnsName -Name $Domain -Type $type -ErrorAction Stop -DnsOnly
            $recordCount = ($records | Where-Object { $_.Type -eq $type }).Count
            
            if ($recordCount -gt 0) {
                Write-Host "  [$type] " -NoNewline -ForegroundColor Yellow
                
                switch ($type) {
                    "A" { 
                        $values = ($records | Where-Object { $_.Type -eq "A" }).IPAddress -join ", "
                        Write-Ui -Message $values -Level "INFO"
                        Add-AnalysisResult -Domain $Domain -RecordType "A" -Value $values -Status "Found"
                    }
                    "AAAA" { 
                        $values = ($records | Where-Object { $_.Type -eq "AAAA" }).IPAddress -join ", "
                        Write-Ui -Message $values -Level "INFO"
                        Add-AnalysisResult -Domain $Domain -RecordType "AAAA" -Value $values -Status "Found"
                    }
                    "MX" { 
                        $mxRecords = $records | Where-Object { $_.Type -eq "MX" }
                        $values = ($mxRecords | ForEach-Object { "$($_.Preference) $($_.NameExchange)" }) -join ", "
                        Write-Ui -Message $values -Level "INFO"
                        Add-AnalysisResult -Domain $Domain -RecordType "MX" -Value $values -Status "Found"
                    }
                    "NS" {
                        $values = ($records | Where-Object { $_.Type -eq "NS" }).NameHost -join ", "
                        Write-Ui -Message $values -Level "INFO"
                        Add-AnalysisResult -Domain $Domain -RecordType "NS" -Value $values -Status "Found"
                    }
                    "CNAME" {
                        $values = ($records | Where-Object { $_.Type -eq "CNAME" }).NameHost -join ", "
                        Write-Ui -Message $values -Level "INFO"
                        Add-AnalysisResult -Domain $Domain -RecordType "CNAME" -Value $values -Status "Found"
                    }
                }
            }
        }
        catch {
            Write-Host "  [$type] " -NoNewline -ForegroundColor Yellow
            Write-Ui -Message "Not found" -Level "INFO"
        }
    }
    
    Write-SouliTEKResult "DNS lookup complete" -Level SUCCESS
    
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Ui -Message "  PART 3: EMAIL SECURITY" -Level "WARN"
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    
    # SPF
    try {
        $txtRecords = Resolve-DnsName -Name $Domain -Type TXT -ErrorAction Stop -DnsOnly
        $spfRecord = $txtRecords | Where-Object { $_.Type -eq "TXT" -and ($_.Strings -join "") -match "^v=spf1" }
        
        Write-Host "  [SPF] " -NoNewline -ForegroundColor Yellow
        if ($spfRecord) {
            Write-Ui -Message "Configured" -Level "OK"
            Add-AnalysisResult -Domain $Domain -RecordType "SPF" -Value ($spfRecord.Strings -join "") -Status "Found"
        } else {
            Write-Ui -Message "Missing" -Level "ERROR"
            Add-AnalysisResult -Domain $Domain -RecordType "SPF" -Value "Not configured" -Status "Missing"
        }
    }
    catch {
        Write-Host "  [SPF] " -NoNewline -ForegroundColor Yellow
        Write-Ui -Message "Error" -Level "ERROR"
    }
    
    # DKIM (check common selectors)
    Write-Host "  [DKIM] " -NoNewline -ForegroundColor Yellow
    $dkimFound = $false
    foreach ($selector in @("google", "default", "selector1", "selector2")) {
        try {
            $dkimRecord = Resolve-DnsName -Name "$selector._domainkey.$Domain" -Type TXT -ErrorAction Stop -DnsOnly
            if ($dkimRecord -and ($dkimRecord.Strings -join "") -match "v=DKIM1") {
                Write-Ui -Message "Found (selector: $selector)" -Level "OK"
                Add-AnalysisResult -Domain $Domain -RecordType "DKIM" -Value "$selector._domainkey" -Status "Found"
                $dkimFound = $true
                break
            }
        }
        catch { }
    }
    if (-not $dkimFound) {
        Write-Ui -Message "Not found (checked common selectors)" -Level "WARN"
        Add-AnalysisResult -Domain $Domain -RecordType "DKIM" -Value "Not found" -Status "Missing"
    }
    
    # DMARC
    try {
        $dmarcRecord = Resolve-DnsName -Name "_dmarc.$Domain" -Type TXT -ErrorAction Stop -DnsOnly
        $dmarcValue = ($dmarcRecord | Where-Object { $_.Type -eq "TXT" }).Strings -join ""
        
        Write-Host "  [DMARC] " -NoNewline -ForegroundColor Yellow
        if ($dmarcValue -match "v=DMARC1") {
            $policy = if ($dmarcValue -match "p=reject") { "reject" } 
                     elseif ($dmarcValue -match "p=quarantine") { "quarantine" }
                     else { "none" }
            Write-Ui -Message "Configured (policy: $policy)" -Level "OK"
            Add-AnalysisResult -Domain $Domain -RecordType "DMARC" -Value $dmarcValue -Status "Found"
        } else {
            Write-Ui -Message "Invalid" -Level "ERROR"
        }
    }
    catch {
        Write-Host "  [DMARC] " -NoNewline -ForegroundColor Yellow
        Write-Ui -Message "Missing" -Level "ERROR"
        Add-AnalysisResult -Domain $Domain -RecordType "DMARC" -Value "Not configured" -Status "Missing"
    }
    
    Write-SouliTEKResult "Email security check complete" -Level SUCCESS
    
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Ui -Message "  ANALYSIS COMPLETE" -Level "OK"
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Ui -Message "  Total records found: $($Script:AnalysisResults.Count)" -Level "WARN"
    Write-Ui -Message "  Use option [5] to export results" -Level "INFO"
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Read-Host "Press Enter to return to main menu"
}

# ============================================================
# EXPORT FUNCTIONS
# ============================================================

function Export-AnalysisResults {
    Show-SouliTEKHeader -Title "EXPORT RESULTS" -Color Yellow -ClearHost -ShowBanner
    
    Write-Ui -Message "      Save analysis results to file" -Level "INFO"
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    
    if ($Script:AnalysisResults.Count -eq 0) {
        Write-SouliTEKResult "No results to export" -Level WARNING
        Write-Host ""
        Write-Ui -Message "Run some analysis first, then export the results." -Level "WARN"
        Write-Host ""
        Start-Sleep -Seconds 3
        return
    }
    
    Write-Ui -Message "Total records: $($Script:AnalysisResults.Count)" -Level "INFO"
    Write-Host ""
    Write-Ui -Message "Select export format:" -Level "STEP"
    Write-Host ""
    Write-Ui -Message "  [1] Text File (.txt)" -Level "WARN"
    Write-Ui -Message "  [2] CSV File (.csv)" -Level "WARN"
    Write-Ui -Message "  [3] HTML Report (.html)" -Level "WARN"
    Write-Ui -Message "  [0] Cancel" -Level "ERROR"
    Write-Host ""
    
    $choice = Read-Host "Enter your choice (0-3)"
    
    try {
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $domainSafe = $Script:LastDomain -replace '[^a-zA-Z0-9]', '_'
        
        switch ($choice) {
            "1" {
                $fileName = "DomainAnalysis_${domainSafe}_$timestamp.txt"
                $filePath = Join-Path $Script:OutputFolder $fileName
                
                $content = @()
                $content += "============================================================"
                $content += "    DOMAIN & DNS ANALYSIS REPORT - by Soulitek.co.il"
                $content += "============================================================"
                $content += ""
                $content += "Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
                $content += "Computer: $env:COMPUTERNAME"
                $content += "Analyzed Domain: $($Script:LastDomain)"
                $content += ""
                $content += "============================================================"
                $content += ""
                
                $groupedResults = $Script:AnalysisResults | Group-Object RecordType
                
                foreach ($group in $groupedResults) {
                    $content += "[$($group.Name)]"
                    foreach ($result in $group.Group) {
                        $content += "  Value: $($result.Value)"
                        $content += "  Status: $($result.Status)"
                        if ($result.Details) {
                            $content += "  Details: $($result.Details)"
                        }
                        $content += ""
                    }
                    $content += "------------------------------------------------------------"
                    $content += ""
                }
                
                $content += "============================================================"
                $content += "          END OF REPORT"
                $content += "============================================================"
                $content += ""
                $content += "Generated by Domain & DNS Analyzer"
                $content += "Coded by: Soulitek.co.il"
                $content += "www.soulitek.co.il"
                
                $content | Out-File -FilePath $filePath -Encoding UTF8
                
                Write-Host ""
                Write-SouliTEKResult "Results exported to: $filePath" -Level SUCCESS
                Start-Sleep -Seconds 1
                Start-Process $filePath
            }
            "2" {
                $fileName = "DomainAnalysis_${domainSafe}_$timestamp.csv"
                $filePath = Join-Path $Script:OutputFolder $fileName
                
                $Script:AnalysisResults | Export-Csv -Path $filePath -NoTypeInformation -Encoding UTF8
                
                Write-Host ""
                Write-SouliTEKResult "Results exported to: $filePath" -Level SUCCESS
                Start-Sleep -Seconds 1
                Start-Process $filePath
            }
            "3" {
                $fileName = "DomainAnalysis_${domainSafe}_$timestamp.html"
                $filePath = Join-Path $Script:OutputFolder $fileName
                
                $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Domain Analysis - $($Script:LastDomain)</title>
    <style>
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin: 20px; background-color: #f5f5f5; }
        h1 { color: #2c3e50; border-bottom: 3px solid #3498db; padding-bottom: 10px; }
        .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; border-radius: 10px; margin-bottom: 30px; }
        .record-group { background-color: white; padding: 20px; margin-bottom: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .record-type { font-size: 18px; font-weight: bold; color: #34495e; margin-bottom: 15px; padding-bottom: 10px; border-bottom: 2px solid #3498db; }
        .record-item { margin: 10px 0; padding: 10px; background: #f8f9fa; border-radius: 4px; }
        .status-found { color: #27ae60; font-weight: bold; }
        .status-missing { color: #e74c3c; font-weight: bold; }
        .status-active { color: #27ae60; font-weight: bold; }
        .footer { text-align: center; margin-top: 30px; color: #7f8c8d; font-size: 12px; }
    </style>
</head>
<body>
    <div class="header">
        <h1>Domain & DNS Analysis Report</h1>
        <p><strong>Domain:</strong> $($Script:LastDomain)</p>
        <p><strong>Generated:</strong> $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</p>
        <p><strong>Computer:</strong> $env:COMPUTERNAME</p>
    </div>
"@
                
                $groupedResults = $Script:AnalysisResults | Group-Object RecordType
                
                foreach ($group in $groupedResults) {
                    $html += @"
    <div class="record-group">
        <div class="record-type">$($group.Name) Records</div>
"@
                    foreach ($result in $group.Group) {
                        $statusClass = switch ($result.Status) {
                            "Found" { "status-found" }
                            "Active" { "status-active" }
                            "Missing" { "status-missing" }
                            default { "" }
                        }
                        
                        $html += @"
        <div class="record-item">
            <strong>Value:</strong> $($result.Value)<br>
            <strong>Status:</strong> <span class="$statusClass">$($result.Status)</span>
"@
                        if ($result.Details) {
                            $html += "<br><strong>Details:</strong> $($result.Details)"
                        }
                        $html += "</div>`n"
                    }
                    $html += "    </div>`n"
                }
                
                $html += @"
    <div class="footer">
        <p>Generated by Domain & DNS Analyzer | Coded by Soulitek.co.il</p>
        <p>www.soulitek.co.il | (C) 2025 Soulitek - All Rights Reserved</p>
    </div>
</body>
</html>
"@
                
                Set-Content -Path $filePath -Value $html -Encoding UTF8
                
                Write-Host ""
                Write-SouliTEKResult "Results exported to: $filePath" -Level SUCCESS
                Start-Sleep -Seconds 1
                Start-Process $filePath
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
    }
    catch {
        Write-SouliTEKResult "Export failed: $_" -Level ERROR
    }
    
    Write-Host ""
    Read-Host "Press Enter to return to main menu"
}

# ============================================================
# HELP FUNCTION
# ============================================================

function Show-Help {
    Show-SouliTEKHeader -Title "HELP GUIDE" -Color Cyan -ClearHost -ShowBanner
    
    Write-Ui -Message "DOMAIN & DNS ANALYZER - USAGE GUIDE" -Level "WARN"
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Ui -Message "DOMAIN ANALYSIS TOOLS:" -Level "WARN"
    Write-Host ""
    Write-Ui -Message "[1] FULL DOMAIN ANALYSIS" -Level "STEP"
    Write-Ui -Message "    Comprehensive analysis including:" -Level "INFO"
    Write-Ui -Message "    - WHOIS data (registrar, dates, nameservers)" -Level "INFO"
    Write-Ui -Message "    - All DNS records (A, AAAA, MX, NS, CNAME, TXT)" -Level "INFO"
    Write-Ui -Message "    - Email security (SPF, DKIM, DMARC)" -Level "INFO"
    Write-Host ""
    Write-Ui -Message "[2] WHOIS LOOKUP" -Level "STEP"
    Write-Ui -Message "    Query domain registration information:" -Level "INFO"
    Write-Ui -Message "    - Domain status, registrar, expiration dates" -Level "INFO"
    Write-Ui -Message "    - Name servers and DNSSEC status" -Level "INFO"
    Write-Host ""
    Write-Ui -Message "[3] DNS RECORDS" -Level "STEP"
    Write-Ui -Message "    Query all DNS record types:" -Level "INFO"
    Write-Ui -Message "    - A, AAAA, MX, TXT, CNAME, NS, SOA, SRV" -Level "INFO"
    Write-Host ""
    Write-Ui -Message "[4] EMAIL SECURITY CHECK" -Level "STEP"
    Write-Ui -Message "    Analyze email authentication records:" -Level "INFO"
    Write-Ui -Message "    - SPF, DKIM, DMARC with security scoring" -Level "INFO"
    Write-Host ""
    Write-Ui -Message "[5] SSL CERTIFICATE CHECK" -Level "STEP"
    Write-Ui -Message "    Analyze SSL/TLS certificate:" -Level "INFO"
    Write-Ui -Message "    - Validity dates and expiration warning" -Level "INFO"
    Write-Ui -Message "    - Issuer information (CA)" -Level "INFO"
    Write-Ui -Message "    - Encryption algorithm and key size" -Level "INFO"
    Write-Ui -Message "    - Subject Alternative Names (SAN)" -Level "INFO"
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Ui -Message "DNS RECORD TYPES:" -Level "WARN"
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Ui -Message "A      - IPv4 address (e.g., 93.184.216.34)" -Level "INFO"
    Write-Ui -Message "AAAA   - IPv6 address" -Level "INFO"
    Write-Ui -Message "MX     - Mail servers (with priority)" -Level "INFO"
    Write-Ui -Message "TXT    - Text records (SPF, DKIM, verification)" -Level "INFO"
    Write-Ui -Message "CNAME  - Alias to another domain" -Level "INFO"
    Write-Ui -Message "NS     - Authoritative name servers" -Level "INFO"
    Write-Ui -Message "SOA    - Start of Authority (zone info)" -Level "INFO"
    Write-Ui -Message "SRV    - Service location records" -Level "INFO"
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Ui -Message "EMAIL SECURITY:" -Level "WARN"
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Ui -Message "SPF    - Sender Policy Framework" -Level "INFO"
    Write-Ui -Message "         Specifies allowed mail servers" -Level "INFO"
    Write-Ui -Message "DKIM   - DomainKeys Identified Mail" -Level "INFO"
    Write-Ui -Message "         Cryptographic email signing" -Level "INFO"
    Write-Ui -Message "DMARC  - Domain Message Authentication" -Level "INFO"
    Write-Ui -Message "         Policy: none, quarantine, reject" -Level "INFO"
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Ui -Message "SSL CERTIFICATE FIELDS:" -Level "WARN"
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Ui -Message "Validity   - Certificate expiration date" -Level "INFO"
    Write-Ui -Message "Issuer     - Certificate Authority (CA)" -Level "INFO"
    Write-Ui -Message "SAN        - Subject Alternative Names (domains covered)" -Level "INFO"
    Write-Ui -Message "Algorithm  - Encryption algorithm (RSA, ECDSA)" -Level "INFO"
    Write-Ui -Message "Key Size   - Encryption strength (2048+ bits recommended)" -Level "INFO"
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Read-Host "Press Enter to return to main menu"
}


# ============================================================
# SSL CERTIFICATE CHECK FUNCTION
# ============================================================

function Get-SSLCertificate {
    param([string]$Domain)
    
    Show-SouliTEKHeader -Title "SSL CERTIFICATE CHECK" -Color DarkYellow -ClearHost -ShowBanner
    
    Write-Ui -Message "      Analyze SSL/TLS certificate for a domain" -Level "INFO"
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    
    if ([string]::IsNullOrWhiteSpace($Domain)) {
        $Domain = Get-ValidDomain -Prompt "Enter domain name (e.g., google.com)"
        if (-not $Domain) {
            Start-Sleep -Seconds 2
            return
        }
    }
    
    Write-Host ""
    Write-SouliTEKResult "Checking SSL certificate for $Domain..." -Level INFO
    Write-Host ""
    
    try {
        # Create TCP connection to get certificate
        $port = 443
        Write-Ui -Message "  [*] Connecting to ${Domain}:$port..." -Level "INFO"
        
        $tcpClient = New-Object System.Net.Sockets.TcpClient
        $tcpClient.Connect($Domain, $port)
        
        $sslStream = New-Object System.Net.Security.SslStream($tcpClient.GetStream(), $false, { $true })
        $sslStream.AuthenticateAsClient($Domain)
        
        $cert = $sslStream.RemoteCertificate
        $cert2 = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($cert)
        
        # Close connections
        $sslStream.Close()
        $tcpClient.Close()
        
        Write-SouliTEKResult "Certificate retrieved successfully" -Level SUCCESS
        
        Write-Host ""
        Write-Host "============================================================" -ForegroundColor DarkYellow
        Write-Host "  SSL CERTIFICATE DETAILS FOR $($Domain.ToUpper())" -ForegroundColor DarkYellow
        Write-Host "============================================================" -ForegroundColor DarkYellow
        Write-Host ""
        
        # Certificate validity
        Write-Ui -Message "  VALIDITY:" -Level "WARN"
        
        $notBefore = $cert2.NotBefore
        $notAfter = $cert2.NotAfter
        $daysRemaining = ($notAfter - (Get-Date)).Days
        
        Write-Host "  Valid From:    " -NoNewline -ForegroundColor White
        Write-Ui -Message $notBefore.ToString("yyyy-MM-dd HH:mm:ss") -Level "INFO"
        
        Write-Host "  Valid Until:   " -NoNewline -ForegroundColor White
        $expiryColor = if ($daysRemaining -lt 30) { 'Red' } elseif ($daysRemaining -lt 90) { 'Yellow' } else { 'Green' }
        Write-Host "$($notAfter.ToString('yyyy-MM-dd HH:mm:ss')) " -NoNewline -ForegroundColor $expiryColor
        Write-Host "($daysRemaining days remaining)" -ForegroundColor $expiryColor
        
        Write-Host "  Status:        " -NoNewline -ForegroundColor White
        if ($daysRemaining -gt 0) {
            Write-Ui -Message "VALID" -Level "OK"
        } else {
            Write-Ui -Message "EXPIRED" -Level "ERROR"
        }
        
        Write-Host ""
        Write-Ui -Message "  ISSUER:" -Level "WARN"
        
        # Parse issuer
        $issuerParts = $cert2.Issuer -split ', '
        $issuerCN = ($issuerParts | Where-Object { $_ -match '^CN=' }) -replace '^CN=', ''
        $issuerO = ($issuerParts | Where-Object { $_ -match '^O=' }) -replace '^O=', ''
        $issuerC = ($issuerParts | Where-Object { $_ -match '^C=' }) -replace '^C=', ''
        
        Write-Host "  Common Name:   " -NoNewline -ForegroundColor White
        Write-Ui -Message $issuerCN -Level "INFO"
        
        Write-Host "  Organization:  " -NoNewline -ForegroundColor White
        Write-Ui -Message $issuerO -Level "INFO"
        
        Write-Host "  Country:       " -NoNewline -ForegroundColor White
        Write-Ui -Message $issuerC -Level "INFO"
        
        Write-Host ""
        Write-Ui -Message "  SUBJECT:" -Level "WARN"
        
        # Parse subject
        $subjectParts = $cert2.Subject -split ', '
        $subjectCN = ($subjectParts | Where-Object { $_ -match '^CN=' }) -replace '^CN=', ''
        
        Write-Host "  Common Name:   " -NoNewline -ForegroundColor White
        Write-Ui -Message $subjectCN -Level "INFO"
        
        Write-Host ""
        Write-Ui -Message "  ENCRYPTION:" -Level "WARN"
        
        Write-Host "  Algorithm:     " -NoNewline -ForegroundColor White
        Write-Ui -Message $cert2.SignatureAlgorithm.FriendlyName -Level "INFO"
        
        Write-Host "  Key Size:      " -NoNewline -ForegroundColor White
        $keySize = $cert2.PublicKey.Key.KeySize
        $keySizeColor = if ($keySize -ge 2048) { 'Green' } else { 'Yellow' }
        Write-Host "$keySize bits" -ForegroundColor $keySizeColor
        
        Write-Host "  Thumbprint:    " -NoNewline -ForegroundColor White
        Write-Ui -Message $cert2.Thumbprint -Level "INFO"
        
        Write-Host "  Serial Number: " -NoNewline -ForegroundColor White
        Write-Ui -Message $cert2.SerialNumber -Level "INFO"
        
        # Get SAN (Subject Alternative Names)
        Write-Host ""
        Write-Ui -Message "  SUBJECT ALTERNATIVE NAMES (SAN):" -Level "WARN"
        
        $sanExtension = $cert2.Extensions | Where-Object { $_.Oid.FriendlyName -eq "Subject Alternative Name" }
        if ($sanExtension) {
            $sanString = $sanExtension.Format($true)
            $sanNames = $sanString -split "`n" | ForEach-Object { $_.Trim() } | Where-Object { $_ -match '^DNS Name=' }
            
            if ($sanNames.Count -gt 0) {
                foreach ($san in $sanNames) {
                    $sanValue = $san -replace '^DNS Name=', ''
                    Write-Ui -Message "    - $sanValue" -Level "INFO"
                }
            } else {
                Write-Ui -Message "    No SAN entries found" -Level "INFO"
            }
        } else {
            Write-Ui -Message "    No SAN extension present" -Level "INFO"
        }
        
        # TLS version check
        Write-Host ""
        Write-Ui -Message "  TLS PROTOCOL:" -Level "WARN"
        Write-Host "  Protocol:      " -NoNewline -ForegroundColor White
        Write-Ui -Message $sslStream.SslProtocol -Level "INFO"
        
        # Certificate chain
        Write-Host ""
        Write-Host "============================================================" -ForegroundColor Cyan
        
        # Summary assessment
        Write-Host ""
        Write-Ui -Message "  CERTIFICATE ASSESSMENT:" -Level "WARN"
        
        $issues = @()
        if ($daysRemaining -lt 30) { $issues += "Expires soon (less than 30 days)" }
        if ($daysRemaining -lt 0) { $issues += "EXPIRED" }
        if ($keySize -lt 2048) { $issues += "Weak key size (less than 2048 bits)" }
        
        if ($issues.Count -eq 0) {
            Write-Host "  Status:        " -NoNewline -ForegroundColor White
            Write-Ui -Message "GOOD - No issues detected" -Level "OK"
        } else {
            Write-Host "  Status:        " -NoNewline -ForegroundColor White
            Write-Ui -Message "ISSUES DETECTED" -Level "ERROR"
            foreach ($issue in $issues) {
                Write-Ui -Message "    - $issue" -Level "WARN"
            }
        }
        
        Write-Host ""
        Write-Host "============================================================" -ForegroundColor Cyan
        
        Add-AnalysisResult -Domain $Domain -RecordType "SSL Certificate" `
            -Value "Valid until: $($notAfter.ToString('yyyy-MM-dd'))" `
            -Status $(if ($daysRemaining -gt 30) { "Valid" } elseif ($daysRemaining -gt 0) { "Expiring Soon" } else { "Expired" }) `
            -Details "Issuer: $issuerCN, Algorithm: $($cert2.SignatureAlgorithm.FriendlyName), Key: $keySize bits"
    }
    catch {
        Write-Host ""
        Write-SouliTEKResult "SSL certificate check failed: $($_.Exception.Message)" -Level ERROR
        Write-Host ""
        Write-Ui -Message "Possible reasons:" -Level "WARN"
        Write-Ui -Message "  - Domain does not have HTTPS enabled" -Level "INFO"
        Write-Ui -Message "  - Connection blocked by firewall" -Level "INFO"
        Write-Ui -Message "  - Invalid domain name" -Level "INFO"
        Write-Ui -Message "  - Server not responding on port 443" -Level "INFO"
        
        Add-AnalysisResult -Domain $Domain -RecordType "SSL Certificate" -Value "Failed" -Status "Error" -Details $_.Exception.Message
    }
    
    Write-Host ""
    Read-Host "Press Enter to return to main menu"
}

# ============================================================
# MAIN MENU
# ============================================================

function Show-MainMenu {
    Show-SouliTEKHeader -Title "DOMAIN & DNS ANALYZER - Professional Edition" -Color Cyan -ClearHost -ShowBanner
    
    Write-Ui -Message "      Coded by: Soulitek.co.il" -Level "OK"
    Write-Ui -Message "      IT Solutions for your business" -Level "OK"
    Write-Ui -Message "      www.soulitek.co.il" -Level "OK"
    Write-Host ""
    Write-Ui -Message "      (C) 2025 Soulitek - All Rights Reserved" -Level "INFO"
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    
    if ($Script:AnalysisResults.Count -gt 0) {
        Write-Ui -Message "  Records analyzed: $($Script:AnalysisResults.Count)" -Level "WARN"
        if ($Script:LastDomain) {
            Write-Ui -Message "  Last domain: $($Script:LastDomain)" -Level "INFO"
        }
        Write-Host ""
    }
    
    Write-Ui -Message "Select an option:" -Level "STEP"
    Write-Host ""
    Write-Ui -Message "  DOMAIN ANALYSIS:" -Level "INFO"
    Write-Ui -Message "  [1] Full Domain Analysis     - WHOIS + DNS + Email Security" -Level "WARN"
    Write-Ui -Message "  [2] WHOIS Lookup             - Domain registration info" -Level "WARN"
    Write-Ui -Message "  [3] DNS Records              - All DNS record types" -Level "WARN"
    Write-Ui -Message "  [4] Email Security Check     - SPF, DKIM, DMARC" -Level "WARN"
    Write-Ui -Message "  [5] SSL Certificate Check    - Validity, issuer, encryption" -Level "WARN"
    Write-Host ""
    Write-Ui -Message "  OTHER:" -Level "INFO"
    Write-Ui -Message "  [9] Export Results           - Save to file" -Level "INFO"
    Write-Ui -Message "  [C] Clear Results            - Clear analysis history" -Level "INFO"
    Write-Ui -Message "  [H] Help                     - Usage guide" -Level "STEP"
    Write-Ui -Message "  [0] Exit" -Level "ERROR"
    Write-Host ""
    Write-Host "========================================" -ForegroundColor DarkGray
    
    $choice = Read-Host "Enter your choice"
    return $choice
}

function Clear-AnalysisResults {
    Write-Host ""
    $confirm = Read-Host "Clear all analysis results? [Y/n]"
    if ($confirm -eq '' -or $confirm -eq 'Y' -or $confirm -eq 'y') {
        $Script:AnalysisResults.Clear()
        $Script:LastDomain = ""
        Write-SouliTEKResult "Analysis results cleared" -Level SUCCESS
        Start-Sleep -Seconds 2
    }
}

# Show-Disclaimer function - using Show-SouliTEKDisclaimer from common module
function Show-Disclaimer {
    Show-SouliTEKDisclaimer
}

# Show-ExitMessage function - using Show-SouliTEKExitMessage from common module
function Show-ExitMessage {
    Show-SouliTEKExitMessage -ScriptPath $PSCommandPath -ToolName "SouliTEK Domain & DNS Analyzer"
}

# ============================================================
# MAIN EXECUTION
# ============================================================

# Show banner
Clear-Host
Show-ScriptBanner -ScriptName "Domain & DNS Analyzer" -Purpose "Comprehensive domain WHOIS and DNS analysis tool"

# Show disclaimer
Show-Disclaimer

# Main menu loop
do {
    $choice = Show-MainMenu
    
    switch ($choice.ToUpper()) {
        "1" { Get-FullDomainAnalysis }
        "2" { Get-DomainWhois }
        "3" { Get-DNSRecords }
        "4" { Get-EmailSecurityRecords }
        "5" { Get-SSLCertificate }
        "9" { Export-AnalysisResults }
        "C" { Clear-AnalysisResults }
        "H" { Show-Help }
        "0" {
            Show-ExitMessage
            break
        }
        default {
            Write-Ui -Message "Invalid choice. Please try again" -Level "ERROR"
            Start-Sleep -Seconds 2
        }
    }
} while ($choice -ne "0")

