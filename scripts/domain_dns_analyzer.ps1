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
        Write-Host "  [-] Cannot determine script path" -ForegroundColor Red
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
        Write-Host "  [*] Downloading Microsoft Sysinternals Whois tool..." -ForegroundColor Yellow
        Write-Host "      This is required for WHOIS lookups." -ForegroundColor Gray
        Write-Host ""
        
        # Ensure tools directory exists
        $toolsDir = Split-Path -Parent $WhoisPath
        if (-not (Test-Path $toolsDir)) {
            New-Item -ItemType Directory -Path $toolsDir -Force | Out-Null
        }
        
        # Download from Sysinternals Live
        $whoisUrl = "https://live.sysinternals.com/whois.exe"
        
        Write-Host "  [*] Downloading from: $whoisUrl" -ForegroundColor Gray
        
        $webClient = New-Object System.Net.WebClient
        $webClient.DownloadFile($whoisUrl, $WhoisPath)
        
        if (Test-Path $WhoisPath) {
            Write-Host "  [+] Whois tool downloaded successfully" -ForegroundColor Green
            $Script:WhoisToolPath = $WhoisPath
            $Script:WhoisToolChecked = $true
            return $true
        } else {
            Write-Host "  [-] Download failed - file not found" -ForegroundColor Red
            return $false
        }
    }
    catch {
        Write-Host "  [-] Failed to download Whois tool: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "  [!] Please ensure you have internet connectivity" -ForegroundColor Yellow
        Write-Host "  [!] You can manually download from:" -ForegroundColor Yellow
        Write-Host "      https://learn.microsoft.com/en-us/sysinternals/downloads/whois" -ForegroundColor Cyan
        Write-Host "      And place whois.exe in: $toolsDir" -ForegroundColor Cyan
        return $false
    }
}

function Get-DomainWhois {
    param([string]$Domain)
    
    Show-SouliTEKHeader -Title "WHOIS LOOKUP" -Color Yellow -ClearHost -ShowBanner
    
    Write-Host "      Query domain registration information" -ForegroundColor Gray
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
        Write-Host "  [*] Querying WHOIS servers..." -ForegroundColor Gray
        
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
            Write-Host "  WHOIS INFORMATION FOR $($Domain.ToUpper())" -ForegroundColor Green
            Write-Host "============================================================" -ForegroundColor Green
            Write-Host ""
            
            Write-Host "  Domain:      " -NoNewline -ForegroundColor White
            Write-Host $whoisData.Domain -ForegroundColor Cyan
            
            Write-Host "  Status:      " -NoNewline -ForegroundColor White
            if ($whoisData.Status) {
                $statusColor = if ($whoisData.Status -match "active|ok|clientTransferProhibited") { 'Green' } else { 'Yellow' }
                Write-Host $whoisData.Status -ForegroundColor $statusColor
            } else {
                Write-Host "N/A" -ForegroundColor Gray
            }
            
            Write-Host "  Registrar:   " -NoNewline -ForegroundColor White
            Write-Host $(if ($whoisData.Registrar) { $whoisData.Registrar } else { "N/A" }) -ForegroundColor Gray
            
            Write-Host ""
            Write-Host "  DATES:" -ForegroundColor Yellow
            
            # Created Date
            if ($whoisData.Created) {
                Write-Host "  Created:     " -NoNewline -ForegroundColor White
                try {
                    $createdDate = [DateTime]::Parse($whoisData.Created)
                    Write-Host $createdDate.ToString("yyyy-MM-dd") -ForegroundColor Gray
                } catch {
                    Write-Host $whoisData.Created -ForegroundColor Gray
                }
            } else {
                Write-Host "  Created:     N/A" -ForegroundColor Gray
            }
            
            # Updated Date
            if ($whoisData.Updated) {
                Write-Host "  Updated:     " -NoNewline -ForegroundColor White
                try {
                    $updatedDate = [DateTime]::Parse($whoisData.Updated)
                    Write-Host $updatedDate.ToString("yyyy-MM-dd") -ForegroundColor Gray
                } catch {
                    Write-Host $whoisData.Updated -ForegroundColor Gray
                }
            } else {
                Write-Host "  Updated:     N/A" -ForegroundColor Gray
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
                    Write-Host $whoisData.Expires -ForegroundColor Gray
                }
            } else {
                Write-Host "  Expires:     N/A" -ForegroundColor Gray
            }
            
            Write-Host ""
            Write-Host "  NAME SERVERS:" -ForegroundColor Yellow
            if ($whoisData.NameServers -and $whoisData.NameServers.Count -gt 0) {
                foreach ($ns in $whoisData.NameServers) {
                    Write-Host "    - $ns" -ForegroundColor Cyan
                }
            } else {
                # Try to get NS from DNS as fallback
                try {
                    $nsRecords = Resolve-DnsName -Name $Domain -Type NS -ErrorAction SilentlyContinue -DnsOnly
                    if ($nsRecords) {
                        $whoisData.NameServers = ($nsRecords | Where-Object { $_.Type -eq "NS" }).NameHost
                        foreach ($ns in $whoisData.NameServers) {
                            Write-Host "    - $ns (from DNS)" -ForegroundColor Cyan
                        }
                    } else {
                        Write-Host "    No nameservers found" -ForegroundColor Gray
                    }
                } catch {
                    Write-Host "    No nameservers found" -ForegroundColor Gray
                }
            }
            
            Write-Host ""
            Write-Host "  DNSSEC:      " -NoNewline -ForegroundColor White
            if ($whoisData.DnsSec) {
                Write-Host "Enabled" -ForegroundColor Green
            } else {
                Write-Host "Not Enabled / Unknown" -ForegroundColor Yellow
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
            Write-Host "  RAW WHOIS DATA" -ForegroundColor Gray
            Write-Host "============================================================" -ForegroundColor Gray
            Write-Host $whoisText -ForegroundColor DarkGray
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
                    Write-Host "  Error: $errorText" -ForegroundColor Yellow
                }
                Add-AnalysisResult -Domain $Domain -RecordType "WHOIS" -Value "No data" -Status "Unknown"
            }
        }
    }
    catch {
        Write-Host ""
        Write-SouliTEKResult "WHOIS lookup failed: $($_.Exception.Message)" -Level ERROR
        Write-Host ""
        Write-Host "Possible reasons:" -ForegroundColor Yellow
        Write-Host "  - Domain does not exist" -ForegroundColor Gray
        Write-Host "  - WHOIS server unavailable" -ForegroundColor Gray
        Write-Host "  - Network connectivity issue" -ForegroundColor Gray
        Write-Host "  - Rate limiting from WHOIS server" -ForegroundColor Gray
        Write-Host ""
        Write-Host "Try using an online WHOIS service:" -ForegroundColor Yellow
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
    
    Write-Host "      Query all DNS record types for a domain" -ForegroundColor Gray
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
    Write-Host "  DNS RECORDS FOR $($Domain.ToUpper())" -ForegroundColor Green
    Write-Host "============================================================" -ForegroundColor Green
    Write-Host ""
    
    foreach ($type in $recordTypes) {
        Write-Host "  [$type RECORDS]" -ForegroundColor Yellow
        
        try {
            $records = Resolve-DnsName -Name $Domain -Type $type -ErrorAction Stop -DnsOnly
            
            if ($records) {
                foreach ($record in $records) {
                    switch ($type) {
                        "A" {
                            if ($record.Type -eq "A") {
                                Write-Host "    $($record.IPAddress)" -ForegroundColor Cyan
                                Add-AnalysisResult -Domain $Domain -RecordType "A" -Value $record.IPAddress -Status "Found"
                            }
                        }
                        "AAAA" {
                            if ($record.Type -eq "AAAA") {
                                Write-Host "    $($record.IPAddress)" -ForegroundColor Cyan
                                Add-AnalysisResult -Domain $Domain -RecordType "AAAA" -Value $record.IPAddress -Status "Found"
                            }
                        }
                        "MX" {
                            if ($record.Type -eq "MX") {
                                Write-Host "    Priority: $($record.Preference) -> $($record.NameExchange)" -ForegroundColor Cyan
                                Add-AnalysisResult -Domain $Domain -RecordType "MX" -Value "$($record.Preference) $($record.NameExchange)" -Status "Found"
                            }
                        }
                        "TXT" {
                            if ($record.Type -eq "TXT") {
                                $txtValue = $record.Strings -join ""
                                # Truncate long TXT records for display
                                $displayValue = if ($txtValue.Length -gt 80) { $txtValue.Substring(0, 77) + "..." } else { $txtValue }
                                Write-Host "    $displayValue" -ForegroundColor Cyan
                                Add-AnalysisResult -Domain $Domain -RecordType "TXT" -Value $txtValue -Status "Found"
                            }
                        }
                        "CNAME" {
                            if ($record.Type -eq "CNAME") {
                                Write-Host "    $($record.Name) -> $($record.NameHost)" -ForegroundColor Cyan
                                Add-AnalysisResult -Domain $Domain -RecordType "CNAME" -Value $record.NameHost -Status "Found"
                            }
                        }
                        "NS" {
                            if ($record.Type -eq "NS") {
                                Write-Host "    $($record.NameHost)" -ForegroundColor Cyan
                                Add-AnalysisResult -Domain $Domain -RecordType "NS" -Value $record.NameHost -Status "Found"
                            }
                        }
                        "SOA" {
                            if ($record.Type -eq "SOA") {
                                Write-Host "    Primary NS: $($record.PrimaryServer)" -ForegroundColor Cyan
                                Write-Host "    Admin: $($record.NameAdministrator)" -ForegroundColor Gray
                                Write-Host "    Serial: $($record.SerialNumber)" -ForegroundColor Gray
                                Add-AnalysisResult -Domain $Domain -RecordType "SOA" -Value $record.PrimaryServer -Status "Found" -Details "Serial: $($record.SerialNumber)"
                            }
                        }
                        "SRV" {
                            if ($record.Type -eq "SRV") {
                                Write-Host "    $($record.Name) -> $($record.NameTarget):$($record.Port) (Priority: $($record.Priority))" -ForegroundColor Cyan
                                Add-AnalysisResult -Domain $Domain -RecordType "SRV" -Value "$($record.NameTarget):$($record.Port)" -Status "Found"
                            }
                        }
                    }
                }
            }
        }
        catch {
            Write-Host "    No $type records found" -ForegroundColor Gray
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
    
    Write-Host "      Analyze SPF, DKIM, and DMARC records" -ForegroundColor Gray
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
    Write-Host "  EMAIL SECURITY ANALYSIS FOR $($Domain.ToUpper())" -ForegroundColor Magenta
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host ""
    
    # ========== SPF CHECK ==========
    Write-Host "  [SPF - Sender Policy Framework]" -ForegroundColor Yellow
    Write-Host "  Purpose: Specifies which mail servers can send email for your domain" -ForegroundColor Gray
    Write-Host ""
    
    try {
        $txtRecords = Resolve-DnsName -Name $Domain -Type TXT -ErrorAction Stop -DnsOnly
        $spfRecord = $txtRecords | Where-Object { $_.Type -eq "TXT" -and ($_.Strings -join "") -match "^v=spf1" }
        
        if ($spfRecord) {
            $spfValue = $spfRecord.Strings -join ""
            Write-Host "  Status: " -NoNewline -ForegroundColor White
            Write-Host "FOUND" -ForegroundColor Green
            Write-Host "  Record: " -ForegroundColor White
            Write-Host "    $spfValue" -ForegroundColor Cyan
            
            # Analyze SPF record
            $spfAnalysis = @()
            if ($spfValue -match "-all") {
                $spfAnalysis += "Hard fail (-all) - Strict policy"
                Write-Host "  Policy: " -NoNewline -ForegroundColor White
                Write-Host "STRICT (Hard Fail)" -ForegroundColor Green
            } elseif ($spfValue -match "~all") {
                $spfAnalysis += "Soft fail (~all) - Moderate policy"
                Write-Host "  Policy: " -NoNewline -ForegroundColor White
                Write-Host "MODERATE (Soft Fail)" -ForegroundColor Yellow
            } elseif ($spfValue -match "\+all") {
                $spfAnalysis += "Pass all (+all) - INSECURE!"
                Write-Host "  Policy: " -NoNewline -ForegroundColor White
                Write-Host "INSECURE (Pass All)" -ForegroundColor Red
            } elseif ($spfValue -match "\?all") {
                $spfAnalysis += "Neutral (?all) - No policy"
                Write-Host "  Policy: " -NoNewline -ForegroundColor White
                Write-Host "NEUTRAL (No Policy)" -ForegroundColor Yellow
            }
            
            $securityScore++
            Add-AnalysisResult -Domain $Domain -RecordType "SPF" -Value $spfValue -Status "Found" -Details ($spfAnalysis -join "; ")
        } else {
            Write-Host "  Status: " -NoNewline -ForegroundColor White
            Write-Host "NOT FOUND" -ForegroundColor Red
            Write-Host "  Warning: No SPF record found - email spoofing possible!" -ForegroundColor Red
            Add-AnalysisResult -Domain $Domain -RecordType "SPF" -Value "Not configured" -Status "Missing"
        }
    }
    catch {
        Write-Host "  Status: " -NoNewline -ForegroundColor White
        Write-Host "ERROR" -ForegroundColor Red
        Write-Host "  $($_.Exception.Message)" -ForegroundColor Gray
    }
    
    Write-Host ""
    Write-Host "------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host ""
    
    # ========== DKIM CHECK ==========
    Write-Host "  [DKIM - DomainKeys Identified Mail]" -ForegroundColor Yellow
    Write-Host "  Purpose: Cryptographically signs emails to verify sender authenticity" -ForegroundColor Gray
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
        Write-Host "FOUND" -ForegroundColor Green
        Write-Host "  Selectors found:" -ForegroundColor White
        
        foreach ($found in $foundSelectors) {
            Write-Host "    - $($found.Selector)._domainkey.$Domain" -ForegroundColor Cyan
            $truncatedRecord = if ($found.Record.Length -gt 60) { $found.Record.Substring(0, 57) + "..." } else { $found.Record }
            Write-Host "      $truncatedRecord" -ForegroundColor Gray
            Add-AnalysisResult -Domain $Domain -RecordType "DKIM" -Value "$($found.Selector)._domainkey" -Status "Found" -Details $found.Record
        }
        
        $securityScore++
    } else {
        Write-Host "  Status: " -NoNewline -ForegroundColor White
        Write-Host "NOT FOUND" -ForegroundColor Yellow
        Write-Host "  Note: Checked selectors: $($Script:DKIMSelectors -join ', ')" -ForegroundColor Gray
        Write-Host "  Tip: DKIM may exist with a different selector" -ForegroundColor Gray
        
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
                    Write-Host "  DKIM found with selector '$customSelector'!" -ForegroundColor Green
                    Write-Host "  Record: $dkimValue" -ForegroundColor Cyan
                    $dkimFound = $true
                    $securityScore++
                    Add-AnalysisResult -Domain $Domain -RecordType "DKIM" -Value "$customSelector._domainkey" -Status "Found" -Details $dkimValue
                } else {
                    Write-Host "  No DKIM record found for selector '$customSelector'" -ForegroundColor Yellow
                }
            }
            catch {
                Write-Host "  No DKIM record found for selector '$customSelector'" -ForegroundColor Yellow
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
    Write-Host "  [DMARC - Domain-based Message Authentication]" -ForegroundColor Yellow
    Write-Host "  Purpose: Defines policy for handling emails that fail SPF/DKIM" -ForegroundColor Gray
    Write-Host ""
    
    $dmarcDomain = "_dmarc.$Domain"
    
    try {
        $dmarcRecord = Resolve-DnsName -Name $dmarcDomain -Type TXT -ErrorAction Stop -DnsOnly
        $dmarcValue = ($dmarcRecord | Where-Object { $_.Type -eq "TXT" }).Strings -join ""
        
        if ($dmarcValue -match "v=DMARC1") {
            Write-Host "  Status: " -NoNewline -ForegroundColor White
            Write-Host "FOUND" -ForegroundColor Green
            Write-Host "  Record: " -ForegroundColor White
            Write-Host "    $dmarcValue" -ForegroundColor Cyan
            
            # Parse DMARC policy
            if ($dmarcValue -match "p=reject") {
                Write-Host "  Policy: " -NoNewline -ForegroundColor White
                Write-Host "REJECT - Strict protection" -ForegroundColor Green
            } elseif ($dmarcValue -match "p=quarantine") {
                Write-Host "  Policy: " -NoNewline -ForegroundColor White
                Write-Host "QUARANTINE - Moderate protection" -ForegroundColor Yellow
            } elseif ($dmarcValue -match "p=none") {
                Write-Host "  Policy: " -NoNewline -ForegroundColor White
                Write-Host "NONE - Monitoring only" -ForegroundColor Yellow
            }
            
            # Check for reporting
            if ($dmarcValue -match "rua=") {
                Write-Host "  Aggregate Reports: " -NoNewline -ForegroundColor White
                Write-Host "Configured" -ForegroundColor Green
            }
            if ($dmarcValue -match "ruf=") {
                Write-Host "  Forensic Reports: " -NoNewline -ForegroundColor White
                Write-Host "Configured" -ForegroundColor Green
            }
            
            $securityScore++
            Add-AnalysisResult -Domain $Domain -RecordType "DMARC" -Value $dmarcValue -Status "Found"
        } else {
            Write-Host "  Status: " -NoNewline -ForegroundColor White
            Write-Host "INVALID" -ForegroundColor Red
            Write-Host "  Record exists but is not valid DMARC" -ForegroundColor Yellow
            Add-AnalysisResult -Domain $Domain -RecordType "DMARC" -Value "Invalid" -Status "Error"
        }
    }
    catch {
        Write-Host "  Status: " -NoNewline -ForegroundColor White
        Write-Host "NOT FOUND" -ForegroundColor Red
        Write-Host "  Warning: No DMARC record - no policy for failed authentication!" -ForegroundColor Red
        Add-AnalysisResult -Domain $Domain -RecordType "DMARC" -Value "Not configured" -Status "Missing"
    }
    
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host ""
    
    # Security Score Summary
    Write-Host "  EMAIL SECURITY SCORE" -ForegroundColor White
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
    Write-Host "]" -ForegroundColor White
    Write-Host ""
    
    # Recommendations
    if ($securityScore -lt $maxScore) {
        Write-Host "  RECOMMENDATIONS:" -ForegroundColor Yellow
        if (-not ($Script:AnalysisResults | Where-Object { $_.RecordType -eq "SPF" -and $_.Status -eq "Found" })) {
            Write-Host "    - Add SPF record to prevent email spoofing" -ForegroundColor Gray
        }
        if (-not $dkimFound) {
            Write-Host "    - Configure DKIM for email authentication" -ForegroundColor Gray
        }
        if (-not ($Script:AnalysisResults | Where-Object { $_.RecordType -eq "DMARC" -and $_.Status -eq "Found" })) {
            Write-Host "    - Add DMARC record to define authentication policy" -ForegroundColor Gray
        }
    } else {
        Write-Host "  All email security records are configured!" -ForegroundColor Green
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
    
    Write-Host "      Complete WHOIS and DNS analysis" -ForegroundColor Gray
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
    Write-Host "This will check:" -ForegroundColor Yellow
    Write-Host "  - WHOIS registration data" -ForegroundColor Gray
    Write-Host "  - All DNS record types" -ForegroundColor Gray
    Write-Host "  - Email security (SPF, DKIM, DMARC)" -ForegroundColor Gray
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
    Write-Host "  PART 1: WHOIS INFORMATION" -ForegroundColor Yellow
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    
    # Initialize WHOIS tool
    if (-not (Initialize-WhoisTool)) {
        Write-SouliTEKResult "Whois tool not available - skipping WHOIS lookup" -Level WARNING
    }
    else {
        try {
            Write-Host "  [*] Querying WHOIS..." -ForegroundColor Gray
            
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
                Write-Host "  Registrar: $registrar" -ForegroundColor Cyan
                
                if ($created) {
                    try {
                        Write-Host "  Created:   $([DateTime]::Parse($created).ToString('yyyy-MM-dd'))" -ForegroundColor Gray
                    } catch {
                        Write-Host "  Created:   $created" -ForegroundColor Gray
                    }
                }
                
                if ($expires) {
                    try {
                        $expiresDate = [DateTime]::Parse($expires)
                        $daysUntilExpiry = ($expiresDate - (Get-Date)).Days
                        $expiryColor = if ($daysUntilExpiry -lt 30) { 'Red' } elseif ($daysUntilExpiry -lt 90) { 'Yellow' } else { 'Green' }
                        Write-Host "  Expires:   $($expiresDate.ToString('yyyy-MM-dd')) ($daysUntilExpiry days)" -ForegroundColor $expiryColor
                    } catch {
                        Write-Host "  Expires:   $expires" -ForegroundColor Gray
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
                    Write-Host "  Name Servers (from DNS): $nsList" -ForegroundColor Cyan
                    Add-AnalysisResult -Domain $Domain -RecordType "WHOIS" -Value "NS: $nsList" -Status "DNS Only"
                }
            }
            catch { }
        }
    }
    
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "  PART 2: DNS RECORDS" -ForegroundColor Yellow
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
                        Write-Host $values -ForegroundColor Cyan
                        Add-AnalysisResult -Domain $Domain -RecordType "A" -Value $values -Status "Found"
                    }
                    "AAAA" { 
                        $values = ($records | Where-Object { $_.Type -eq "AAAA" }).IPAddress -join ", "
                        Write-Host $values -ForegroundColor Cyan
                        Add-AnalysisResult -Domain $Domain -RecordType "AAAA" -Value $values -Status "Found"
                    }
                    "MX" { 
                        $mxRecords = $records | Where-Object { $_.Type -eq "MX" }
                        $values = ($mxRecords | ForEach-Object { "$($_.Preference) $($_.NameExchange)" }) -join ", "
                        Write-Host $values -ForegroundColor Cyan
                        Add-AnalysisResult -Domain $Domain -RecordType "MX" -Value $values -Status "Found"
                    }
                    "NS" {
                        $values = ($records | Where-Object { $_.Type -eq "NS" }).NameHost -join ", "
                        Write-Host $values -ForegroundColor Cyan
                        Add-AnalysisResult -Domain $Domain -RecordType "NS" -Value $values -Status "Found"
                    }
                    "CNAME" {
                        $values = ($records | Where-Object { $_.Type -eq "CNAME" }).NameHost -join ", "
                        Write-Host $values -ForegroundColor Cyan
                        Add-AnalysisResult -Domain $Domain -RecordType "CNAME" -Value $values -Status "Found"
                    }
                }
            }
        }
        catch {
            Write-Host "  [$type] " -NoNewline -ForegroundColor Yellow
            Write-Host "Not found" -ForegroundColor Gray
        }
    }
    
    Write-SouliTEKResult "DNS lookup complete" -Level SUCCESS
    
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "  PART 3: EMAIL SECURITY" -ForegroundColor Yellow
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    
    # SPF
    try {
        $txtRecords = Resolve-DnsName -Name $Domain -Type TXT -ErrorAction Stop -DnsOnly
        $spfRecord = $txtRecords | Where-Object { $_.Type -eq "TXT" -and ($_.Strings -join "") -match "^v=spf1" }
        
        Write-Host "  [SPF] " -NoNewline -ForegroundColor Yellow
        if ($spfRecord) {
            Write-Host "Configured" -ForegroundColor Green
            Add-AnalysisResult -Domain $Domain -RecordType "SPF" -Value ($spfRecord.Strings -join "") -Status "Found"
        } else {
            Write-Host "Missing" -ForegroundColor Red
            Add-AnalysisResult -Domain $Domain -RecordType "SPF" -Value "Not configured" -Status "Missing"
        }
    }
    catch {
        Write-Host "  [SPF] " -NoNewline -ForegroundColor Yellow
        Write-Host "Error" -ForegroundColor Red
    }
    
    # DKIM (check common selectors)
    Write-Host "  [DKIM] " -NoNewline -ForegroundColor Yellow
    $dkimFound = $false
    foreach ($selector in @("google", "default", "selector1", "selector2")) {
        try {
            $dkimRecord = Resolve-DnsName -Name "$selector._domainkey.$Domain" -Type TXT -ErrorAction Stop -DnsOnly
            if ($dkimRecord -and ($dkimRecord.Strings -join "") -match "v=DKIM1") {
                Write-Host "Found (selector: $selector)" -ForegroundColor Green
                Add-AnalysisResult -Domain $Domain -RecordType "DKIM" -Value "$selector._domainkey" -Status "Found"
                $dkimFound = $true
                break
            }
        }
        catch { }
    }
    if (-not $dkimFound) {
        Write-Host "Not found (checked common selectors)" -ForegroundColor Yellow
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
            Write-Host "Configured (policy: $policy)" -ForegroundColor Green
            Add-AnalysisResult -Domain $Domain -RecordType "DMARC" -Value $dmarcValue -Status "Found"
        } else {
            Write-Host "Invalid" -ForegroundColor Red
        }
    }
    catch {
        Write-Host "  [DMARC] " -NoNewline -ForegroundColor Yellow
        Write-Host "Missing" -ForegroundColor Red
        Add-AnalysisResult -Domain $Domain -RecordType "DMARC" -Value "Not configured" -Status "Missing"
    }
    
    Write-SouliTEKResult "Email security check complete" -Level SUCCESS
    
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "  ANALYSIS COMPLETE" -ForegroundColor Green
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Total records found: $($Script:AnalysisResults.Count)" -ForegroundColor Yellow
    Write-Host "  Use option [5] to export results" -ForegroundColor Gray
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
    
    Write-Host "      Save analysis results to file" -ForegroundColor Gray
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    
    if ($Script:AnalysisResults.Count -eq 0) {
        Write-SouliTEKResult "No results to export" -Level WARNING
        Write-Host ""
        Write-Host "Run some analysis first, then export the results." -ForegroundColor Yellow
        Write-Host ""
        Start-Sleep -Seconds 3
        return
    }
    
    Write-Host "Total records: $($Script:AnalysisResults.Count)" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Select export format:" -ForegroundColor White
    Write-Host ""
    Write-Host "  [1] Text File (.txt)" -ForegroundColor Yellow
    Write-Host "  [2] CSV File (.csv)" -ForegroundColor Yellow
    Write-Host "  [3] HTML Report (.html)" -ForegroundColor Yellow
    Write-Host "  [0] Cancel" -ForegroundColor Red
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
    
    Write-Host "DOMAIN & DNS ANALYZER - USAGE GUIDE" -ForegroundColor Yellow
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "DOMAIN ANALYSIS TOOLS:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "[1] FULL DOMAIN ANALYSIS" -ForegroundColor White
    Write-Host "    Comprehensive analysis including:" -ForegroundColor Gray
    Write-Host "    - WHOIS data (registrar, dates, nameservers)" -ForegroundColor Gray
    Write-Host "    - All DNS records (A, AAAA, MX, NS, CNAME, TXT)" -ForegroundColor Gray
    Write-Host "    - Email security (SPF, DKIM, DMARC)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "[2] WHOIS LOOKUP" -ForegroundColor White
    Write-Host "    Query domain registration information:" -ForegroundColor Gray
    Write-Host "    - Domain status, registrar, expiration dates" -ForegroundColor Gray
    Write-Host "    - Name servers and DNSSEC status" -ForegroundColor Gray
    Write-Host ""
    Write-Host "[3] DNS RECORDS" -ForegroundColor White
    Write-Host "    Query all DNS record types:" -ForegroundColor Gray
    Write-Host "    - A, AAAA, MX, TXT, CNAME, NS, SOA, SRV" -ForegroundColor Gray
    Write-Host ""
    Write-Host "[4] EMAIL SECURITY CHECK" -ForegroundColor White
    Write-Host "    Analyze email authentication records:" -ForegroundColor Gray
    Write-Host "    - SPF, DKIM, DMARC with security scoring" -ForegroundColor Gray
    Write-Host ""
    Write-Host "[5] SSL CERTIFICATE CHECK" -ForegroundColor White
    Write-Host "    Analyze SSL/TLS certificate:" -ForegroundColor Gray
    Write-Host "    - Validity dates and expiration warning" -ForegroundColor Gray
    Write-Host "    - Issuer information (CA)" -ForegroundColor Gray
    Write-Host "    - Encryption algorithm and key size" -ForegroundColor Gray
    Write-Host "    - Subject Alternative Names (SAN)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "DNS RECORD TYPES:" -ForegroundColor Yellow
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "A      - IPv4 address (e.g., 93.184.216.34)" -ForegroundColor Gray
    Write-Host "AAAA   - IPv6 address" -ForegroundColor Gray
    Write-Host "MX     - Mail servers (with priority)" -ForegroundColor Gray
    Write-Host "TXT    - Text records (SPF, DKIM, verification)" -ForegroundColor Gray
    Write-Host "CNAME  - Alias to another domain" -ForegroundColor Gray
    Write-Host "NS     - Authoritative name servers" -ForegroundColor Gray
    Write-Host "SOA    - Start of Authority (zone info)" -ForegroundColor Gray
    Write-Host "SRV    - Service location records" -ForegroundColor Gray
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "EMAIL SECURITY:" -ForegroundColor Yellow
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "SPF    - Sender Policy Framework" -ForegroundColor Gray
    Write-Host "         Specifies allowed mail servers" -ForegroundColor Gray
    Write-Host "DKIM   - DomainKeys Identified Mail" -ForegroundColor Gray
    Write-Host "         Cryptographic email signing" -ForegroundColor Gray
    Write-Host "DMARC  - Domain Message Authentication" -ForegroundColor Gray
    Write-Host "         Policy: none, quarantine, reject" -ForegroundColor Gray
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "SSL CERTIFICATE FIELDS:" -ForegroundColor Yellow
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Validity   - Certificate expiration date" -ForegroundColor Gray
    Write-Host "Issuer     - Certificate Authority (CA)" -ForegroundColor Gray
    Write-Host "SAN        - Subject Alternative Names (domains covered)" -ForegroundColor Gray
    Write-Host "Algorithm  - Encryption algorithm (RSA, ECDSA)" -ForegroundColor Gray
    Write-Host "Key Size   - Encryption strength (2048+ bits recommended)" -ForegroundColor Gray
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
    
    Write-Host "      Analyze SSL/TLS certificate for a domain" -ForegroundColor Gray
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
        Write-Host "  [*] Connecting to ${Domain}:$port..." -ForegroundColor Gray
        
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
        Write-Host "  VALIDITY:" -ForegroundColor Yellow
        
        $notBefore = $cert2.NotBefore
        $notAfter = $cert2.NotAfter
        $daysRemaining = ($notAfter - (Get-Date)).Days
        
        Write-Host "  Valid From:    " -NoNewline -ForegroundColor White
        Write-Host $notBefore.ToString("yyyy-MM-dd HH:mm:ss") -ForegroundColor Gray
        
        Write-Host "  Valid Until:   " -NoNewline -ForegroundColor White
        $expiryColor = if ($daysRemaining -lt 30) { 'Red' } elseif ($daysRemaining -lt 90) { 'Yellow' } else { 'Green' }
        Write-Host "$($notAfter.ToString('yyyy-MM-dd HH:mm:ss')) " -NoNewline -ForegroundColor $expiryColor
        Write-Host "($daysRemaining days remaining)" -ForegroundColor $expiryColor
        
        Write-Host "  Status:        " -NoNewline -ForegroundColor White
        if ($daysRemaining -gt 0) {
            Write-Host "VALID" -ForegroundColor Green
        } else {
            Write-Host "EXPIRED" -ForegroundColor Red
        }
        
        Write-Host ""
        Write-Host "  ISSUER:" -ForegroundColor Yellow
        
        # Parse issuer
        $issuerParts = $cert2.Issuer -split ', '
        $issuerCN = ($issuerParts | Where-Object { $_ -match '^CN=' }) -replace '^CN=', ''
        $issuerO = ($issuerParts | Where-Object { $_ -match '^O=' }) -replace '^O=', ''
        $issuerC = ($issuerParts | Where-Object { $_ -match '^C=' }) -replace '^C=', ''
        
        Write-Host "  Common Name:   " -NoNewline -ForegroundColor White
        Write-Host $issuerCN -ForegroundColor Cyan
        
        Write-Host "  Organization:  " -NoNewline -ForegroundColor White
        Write-Host $issuerO -ForegroundColor Gray
        
        Write-Host "  Country:       " -NoNewline -ForegroundColor White
        Write-Host $issuerC -ForegroundColor Gray
        
        Write-Host ""
        Write-Host "  SUBJECT:" -ForegroundColor Yellow
        
        # Parse subject
        $subjectParts = $cert2.Subject -split ', '
        $subjectCN = ($subjectParts | Where-Object { $_ -match '^CN=' }) -replace '^CN=', ''
        
        Write-Host "  Common Name:   " -NoNewline -ForegroundColor White
        Write-Host $subjectCN -ForegroundColor Cyan
        
        Write-Host ""
        Write-Host "  ENCRYPTION:" -ForegroundColor Yellow
        
        Write-Host "  Algorithm:     " -NoNewline -ForegroundColor White
        Write-Host $cert2.SignatureAlgorithm.FriendlyName -ForegroundColor Cyan
        
        Write-Host "  Key Size:      " -NoNewline -ForegroundColor White
        $keySize = $cert2.PublicKey.Key.KeySize
        $keySizeColor = if ($keySize -ge 2048) { 'Green' } else { 'Yellow' }
        Write-Host "$keySize bits" -ForegroundColor $keySizeColor
        
        Write-Host "  Thumbprint:    " -NoNewline -ForegroundColor White
        Write-Host $cert2.Thumbprint -ForegroundColor Gray
        
        Write-Host "  Serial Number: " -NoNewline -ForegroundColor White
        Write-Host $cert2.SerialNumber -ForegroundColor Gray
        
        # Get SAN (Subject Alternative Names)
        Write-Host ""
        Write-Host "  SUBJECT ALTERNATIVE NAMES (SAN):" -ForegroundColor Yellow
        
        $sanExtension = $cert2.Extensions | Where-Object { $_.Oid.FriendlyName -eq "Subject Alternative Name" }
        if ($sanExtension) {
            $sanString = $sanExtension.Format($true)
            $sanNames = $sanString -split "`n" | ForEach-Object { $_.Trim() } | Where-Object { $_ -match '^DNS Name=' }
            
            if ($sanNames.Count -gt 0) {
                foreach ($san in $sanNames) {
                    $sanValue = $san -replace '^DNS Name=', ''
                    Write-Host "    - $sanValue" -ForegroundColor Cyan
                }
            } else {
                Write-Host "    No SAN entries found" -ForegroundColor Gray
            }
        } else {
            Write-Host "    No SAN extension present" -ForegroundColor Gray
        }
        
        # TLS version check
        Write-Host ""
        Write-Host "  TLS PROTOCOL:" -ForegroundColor Yellow
        Write-Host "  Protocol:      " -NoNewline -ForegroundColor White
        Write-Host $sslStream.SslProtocol -ForegroundColor Cyan
        
        # Certificate chain
        Write-Host ""
        Write-Host "============================================================" -ForegroundColor Cyan
        
        # Summary assessment
        Write-Host ""
        Write-Host "  CERTIFICATE ASSESSMENT:" -ForegroundColor Yellow
        
        $issues = @()
        if ($daysRemaining -lt 30) { $issues += "Expires soon (less than 30 days)" }
        if ($daysRemaining -lt 0) { $issues += "EXPIRED" }
        if ($keySize -lt 2048) { $issues += "Weak key size (less than 2048 bits)" }
        
        if ($issues.Count -eq 0) {
            Write-Host "  Status:        " -NoNewline -ForegroundColor White
            Write-Host "GOOD - No issues detected" -ForegroundColor Green
        } else {
            Write-Host "  Status:        " -NoNewline -ForegroundColor White
            Write-Host "ISSUES DETECTED" -ForegroundColor Red
            foreach ($issue in $issues) {
                Write-Host "    - $issue" -ForegroundColor Yellow
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
        Write-Host "Possible reasons:" -ForegroundColor Yellow
        Write-Host "  - Domain does not have HTTPS enabled" -ForegroundColor Gray
        Write-Host "  - Connection blocked by firewall" -ForegroundColor Gray
        Write-Host "  - Invalid domain name" -ForegroundColor Gray
        Write-Host "  - Server not responding on port 443" -ForegroundColor Gray
        
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
    
    Write-Host "      Coded by: Soulitek.co.il" -ForegroundColor Green
    Write-Host "      IT Solutions for your business" -ForegroundColor Green
    Write-Host "      www.soulitek.co.il" -ForegroundColor Green
    Write-Host ""
    Write-Host "      (C) 2025 Soulitek - All Rights Reserved" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    
    if ($Script:AnalysisResults.Count -gt 0) {
        Write-Host "  Records analyzed: $($Script:AnalysisResults.Count)" -ForegroundColor Yellow
        if ($Script:LastDomain) {
            Write-Host "  Last domain: $($Script:LastDomain)" -ForegroundColor Gray
        }
        Write-Host ""
    }
    
    Write-Host "Select an option:" -ForegroundColor White
    Write-Host ""
    Write-Host "  DOMAIN ANALYSIS:" -ForegroundColor DarkCyan
    Write-Host "  [1] Full Domain Analysis     - WHOIS + DNS + Email Security" -ForegroundColor Yellow
    Write-Host "  [2] WHOIS Lookup             - Domain registration info" -ForegroundColor Yellow
    Write-Host "  [3] DNS Records              - All DNS record types" -ForegroundColor Yellow
    Write-Host "  [4] Email Security Check     - SPF, DKIM, DMARC" -ForegroundColor Yellow
    Write-Host "  [5] SSL Certificate Check    - Validity, issuer, encryption" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  OTHER:" -ForegroundColor DarkCyan
    Write-Host "  [9] Export Results           - Save to file" -ForegroundColor Cyan
    Write-Host "  [C] Clear Results            - Clear analysis history" -ForegroundColor Magenta
    Write-Host "  [H] Help                     - Usage guide" -ForegroundColor White
    Write-Host "  [0] Exit" -ForegroundColor Red
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
            Write-Host "Invalid choice. Please try again." -ForegroundColor Red
            Start-Sleep -Seconds 2
        }
    }
} while ($choice -ne "0")

