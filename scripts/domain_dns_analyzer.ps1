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

function Show-Header {
    param([string]$Title = "DOMAIN & DNS ANALYZER", [ConsoleColor]$Color = 'Cyan')
    
    Clear-Host
    Show-SouliTEKBanner
    Write-Host "============================================================" -ForegroundColor $Color
    Write-Host ""
    Write-Host "  $Title" -ForegroundColor $Color
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor $Color
    Write-Host ""
}

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
# WHOIS FUNCTIONS (Using Get-WHOIS Module)
# ============================================================

$Script:WhoisModuleChecked = $false

function Initialize-WhoisModule {
    <#
    .SYNOPSIS
        Ensures the Get-WHOIS module is installed and imported.
    #>
    
    if ($Script:WhoisModuleChecked) {
        return $true
    }
    
    try {
        # Check if module is already available
        $module = Get-Module -ListAvailable -Name "Get-WHOIS" | Sort-Object Version -Descending | Select-Object -First 1
        
        if (-not $module) {
            Write-Host ""
            Write-Host "  [*] Installing Get-WHOIS module..." -ForegroundColor Yellow
            Write-Host "      This is required for WHOIS lookups." -ForegroundColor Gray
            Write-Host ""
            
            # Ensure NuGet provider
            $nuget = Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue
            if (-not $nuget -or $nuget.Version -lt [version]"2.8.5.201") {
                Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope CurrentUser | Out-Null
            }
            
            # Install the module
            Install-Module -Name Get-WHOIS -Scope CurrentUser -Force -AllowClobber -ErrorAction Stop
            Write-Host "  [+] Get-WHOIS module installed successfully" -ForegroundColor Green
        }
        
        # Import the module
        Import-Module -Name Get-WHOIS -Force -ErrorAction Stop
        $Script:WhoisModuleChecked = $true
        return $true
    }
    catch {
        Write-Host "  [-] Failed to install/import Get-WHOIS module: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "  [!] Try running: Install-Module -Name Get-WHOIS -Scope CurrentUser -Force" -ForegroundColor Yellow
        return $false
    }
}

function Get-DomainWhois {
    param([string]$Domain)
    
    Show-Header "WHOIS LOOKUP" -Color Yellow
    
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
    
    # Initialize WHOIS module
    if (-not (Initialize-WhoisModule)) {
        Write-Host ""
        Write-SouliTEKResult "WHOIS module not available. Cannot perform lookup." -Level ERROR
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
        
        # Use Get-WHOIS module
        $whoisResult = Get-WHOIS -Domain $Domain -ErrorAction Stop
        
        if ($whoisResult) {
            Write-SouliTEKResult "WHOIS query successful" -Level SUCCESS
            
            # Parse the WHOIS result
            $whoisData = [PSCustomObject]@{
                Domain = $Domain
                RawData = $whoisResult
                Registrar = ""
                Created = ""
                Updated = ""
                Expires = ""
                NameServers = @()
                Status = ""
                DnsSec = $false
            }
            
            # Parse raw WHOIS text for common fields
            $whoisText = $whoisResult.ToString()
            
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
            
            # Option to show raw WHOIS
            Write-Host ""
            $showRaw = Read-Host "Show raw WHOIS data? [Y/n]"
            if ($showRaw -eq '' -or $showRaw -eq 'Y' -or $showRaw -eq 'y') {
                Write-Host ""
                Write-Host "============================================================" -ForegroundColor Gray
                Write-Host "  RAW WHOIS DATA" -ForegroundColor Gray
                Write-Host "============================================================" -ForegroundColor Gray
                Write-Host $whoisText -ForegroundColor DarkGray
                Write-Host "============================================================" -ForegroundColor Gray
            }
        }
        else {
            Write-SouliTEKResult "No WHOIS data returned" -Level WARNING
            Add-AnalysisResult -Domain $Domain -RecordType "WHOIS" -Value "No data" -Status "Unknown"
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
    
    Show-Header "DNS RECORDS LOOKUP" -Color Green
    
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
    
    Show-Header "EMAIL SECURITY CHECK" -Color Magenta
    
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
    
    Show-Header "FULL DOMAIN ANALYSIS" -Color Cyan
    
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
    
    # Initialize WHOIS module
    if (-not (Initialize-WhoisModule)) {
        Write-SouliTEKResult "WHOIS module not available - skipping WHOIS lookup" -Level WARNING
    }
    else {
        try {
            Write-Host "  [*] Querying WHOIS..." -ForegroundColor Gray
            $whoisResult = Get-WHOIS -Domain $Domain -ErrorAction Stop
            
            if ($whoisResult) {
                $whoisText = $whoisResult.ToString()
                
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
    Show-Header "EXPORT RESULTS" -Color Yellow
    
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
    Show-Header "HELP GUIDE" -Color Cyan
    
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
    Write-Host "NETWORK TOOLS:" -ForegroundColor Yellow
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "[6] GEOIP LOOKUP" -ForegroundColor White
    Write-Host "    Find geographic location of IP/domain:" -ForegroundColor Gray
    Write-Host "    - Country, region, city, coordinates" -ForegroundColor Gray
    Write-Host "    - ISP and organization info" -ForegroundColor Gray
    Write-Host "    - Google Maps link" -ForegroundColor Gray
    Write-Host ""
    Write-Host "[7] MY EXTERNAL IP" -ForegroundColor White
    Write-Host "    Discover your public IP address:" -ForegroundColor Gray
    Write-Host "    - External IP address" -ForegroundColor Gray
    Write-Host "    - Your location and ISP info" -ForegroundColor Gray
    Write-Host "    - Local network IPs" -ForegroundColor Gray
    Write-Host ""
    Write-Host "[8] INTERNET SPEED TEST" -ForegroundColor White
    Write-Host "    Test connection speed (uses Ookla Speedtest):" -ForegroundColor Gray
    Write-Host "    - Download and upload speeds" -ForegroundColor Gray
    Write-Host "    - Ping latency and jitter" -ForegroundColor Gray
    Write-Host "    - Server information" -ForegroundColor Gray
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
# GEOIP LOOKUP FUNCTION
# ============================================================

function Get-GeoIPLocation {
    param([string]$Target)
    
    Show-Header "GEOIP LOOKUP" -Color Magenta
    
    Write-Host "      Find the geographic location of an IP or domain" -ForegroundColor Gray
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    
    if ([string]::IsNullOrWhiteSpace($Target)) {
        $Target = Read-Host "Enter IP address or domain name"
        
        if ([string]::IsNullOrWhiteSpace($Target)) {
            Write-SouliTEKResult "No target specified" -Level ERROR
            Start-Sleep -Seconds 2
            return
        }
    }
    
    # Clean the input
    $Target = $Target -replace '^https?://', ''
    $Target = $Target -replace '/.*$', ''
    $Target = $Target.Trim()
    
    Write-Host ""
    Write-SouliTEKResult "Looking up location for $Target..." -Level INFO
    Write-Host ""
    
    try {
        # First, resolve domain to IP if needed
        $ipAddress = $Target
        if ($Target -notmatch '^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$') {
            Write-Host "  [*] Resolving domain to IP..." -ForegroundColor Gray
            try {
                $dnsResult = Resolve-DnsName -Name $Target -Type A -ErrorAction Stop -DnsOnly
                $ipAddress = ($dnsResult | Where-Object { $_.Type -eq "A" } | Select-Object -First 1).IPAddress
                Write-Host "  [+] Resolved to: $ipAddress" -ForegroundColor Green
            }
            catch {
                Write-SouliTEKResult "Could not resolve domain to IP" -Level ERROR
                Read-Host "Press Enter to return to main menu"
                return
            }
        }
        
        Write-Host "  [*] Querying GeoIP database..." -ForegroundColor Gray
        
        $geoData = $null
        $geoSource = ""
        
        # Try ipapi.co first (more detailed info)
        try {
            Write-Host "  [*] Trying ipapi.co..." -ForegroundColor Gray
            $ipapiUrl = "https://ipapi.co/$ipAddress/json/"
            $ipapiData = Invoke-RestMethod -Uri $ipapiUrl -Method Get -TimeoutSec 10 -ErrorAction Stop
            
            if ($ipapiData -and -not $ipapiData.error) {
                $geoData = [PSCustomObject]@{
                    status = "success"
                    country = $ipapiData.country_name
                    countryCode = $ipapiData.country_code
                    region = $ipapiData.region_code
                    regionName = $ipapiData.region
                    city = $ipapiData.city
                    zip = $ipapiData.postal
                    lat = $ipapiData.latitude
                    lon = $ipapiData.longitude
                    timezone = $ipapiData.timezone
                    isp = $ipapiData.org
                    org = $ipapiData.org
                    as = $ipapiData.asn
                    currency = $ipapiData.currency
                    languages = $ipapiData.languages
                    countryCallingCode = $ipapiData.country_calling_code
                }
                $geoSource = "ipapi.co"
                Write-Host "  [+] Got response from ipapi.co" -ForegroundColor Green
            }
        }
        catch {
            Write-Host "  [!] ipapi.co failed, trying fallback..." -ForegroundColor Yellow
        }
        
        # Fallback to ip-api.com
        if (-not $geoData -or $geoData.status -ne "success") {
            try {
                $geoUrl = "http://ip-api.com/json/$ipAddress"
                $geoData = Invoke-RestMethod -Uri $geoUrl -Method Get -TimeoutSec 10 -ErrorAction Stop
                $geoSource = "ip-api.com"
                Write-Host "  [+] Got response from ip-api.com" -ForegroundColor Green
            }
            catch {
                Write-Host "  [-] ip-api.com also failed" -ForegroundColor Red
            }
        }
        
        if ($geoData -and $geoData.status -eq "success") {
            Write-Host ""
            Write-Host "============================================================" -ForegroundColor Magenta
            Write-Host "  GEOIP LOCATION RESULTS" -ForegroundColor Magenta
            Write-Host "============================================================" -ForegroundColor Magenta
            Write-Host ""
            
            Write-Host "  Target:        " -NoNewline -ForegroundColor White
            Write-Host $Target -ForegroundColor Cyan
            
            Write-Host "  IP Address:    " -NoNewline -ForegroundColor White
            Write-Host $ipAddress -ForegroundColor Cyan
            
            Write-Host ""
            Write-Host "  LOCATION:" -ForegroundColor Yellow
            
            Write-Host "  Country:       " -NoNewline -ForegroundColor White
            Write-Host "$($geoData.country) ($($geoData.countryCode))" -ForegroundColor Green
            
            Write-Host "  Region:        " -NoNewline -ForegroundColor White
            Write-Host "$($geoData.regionName) ($($geoData.region))" -ForegroundColor Gray
            
            Write-Host "  City:          " -NoNewline -ForegroundColor White
            Write-Host $geoData.city -ForegroundColor Gray
            
            Write-Host "  ZIP Code:      " -NoNewline -ForegroundColor White
            Write-Host $geoData.zip -ForegroundColor Gray
            
            Write-Host "  Coordinates:   " -NoNewline -ForegroundColor White
            Write-Host "Lat: $($geoData.lat), Lon: $($geoData.lon)" -ForegroundColor Gray
            
            Write-Host "  Timezone:      " -NoNewline -ForegroundColor White
            Write-Host $geoData.timezone -ForegroundColor Gray
            
            Write-Host ""
            Write-Host "  NETWORK:" -ForegroundColor Yellow
            
            Write-Host "  ISP:           " -NoNewline -ForegroundColor White
            Write-Host $geoData.isp -ForegroundColor Cyan
            
            Write-Host "  Organization:  " -NoNewline -ForegroundColor White
            Write-Host $geoData.org -ForegroundColor Gray
            
            Write-Host "  AS Number:     " -NoNewline -ForegroundColor White
            Write-Host $geoData.as -ForegroundColor Gray
            
            # Add to results
            Add-AnalysisResult -Domain $Target -RecordType "GeoIP" `
                -Value "$($geoData.city), $($geoData.country)" `
                -Status "Found" `
                -Details "IP: $ipAddress, ISP: $($geoData.isp), Coords: $($geoData.lat),$($geoData.lon)"
            
            Write-Host ""
            Write-Host "============================================================" -ForegroundColor Magenta
            Write-Host ""
            Write-Host "  View on map: " -NoNewline -ForegroundColor Yellow
            Write-Host "https://www.google.com/maps?q=$($geoData.lat),$($geoData.lon)" -ForegroundColor Cyan
            Write-Host ""
            Write-Host "============================================================" -ForegroundColor Cyan
        }
        else {
            Write-SouliTEKResult "GeoIP lookup failed: $($geoData.message)" -Level ERROR
        }
    }
    catch {
        Write-SouliTEKResult "GeoIP lookup failed: $($_.Exception.Message)" -Level ERROR
    }
    
    Write-Host ""
    Read-Host "Press Enter to return to main menu"
}

# ============================================================
# EXTERNAL IP FUNCTION
# ============================================================

function Get-MyExternalIP {
    Show-Header "MY EXTERNAL IP" -Color Green
    
    Write-Host "      Discover your public IP address and location" -ForegroundColor Gray
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    
    Write-SouliTEKResult "Detecting your external IP address..." -Level INFO
    Write-Host ""
    
    try {
        # Get external IP from multiple sources for reliability
        $ipSources = @(
            "https://api.ipify.org",
            "https://icanhazip.com",
            "https://ifconfig.me/ip"
        )
        
        $externalIP = $null
        
        foreach ($source in $ipSources) {
            try {
                Write-Host "  [*] Checking $source..." -ForegroundColor Gray
                $externalIP = (Invoke-WebRequest -Uri $source -TimeoutSec 10 -UseBasicParsing -ErrorAction Stop).Content.Trim()
                if ($externalIP -match '^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$') {
                    Write-Host "  [+] Got response" -ForegroundColor Green
                    break
                }
            }
            catch {
                continue
            }
        }
        
        if ($externalIP) {
            Write-Host ""
            Write-Host "============================================================" -ForegroundColor Green
            Write-Host "  YOUR EXTERNAL IP ADDRESS" -ForegroundColor Green
            Write-Host "============================================================" -ForegroundColor Green
            Write-Host ""
            
            Write-Host "  External IP:   " -NoNewline -ForegroundColor White
            Write-Host $externalIP -ForegroundColor Cyan -BackgroundColor DarkBlue
            Write-Host ""
            
            # Get GeoIP info for the external IP using ipapi.co
            Write-Host "  [*] Getting location info..." -ForegroundColor Gray
            
            try {
                # Try ipapi.co first (returns your own IP info when called without IP)
                $ipapiUrl = "https://ipapi.co/json/"
                $geoData = Invoke-RestMethod -Uri $ipapiUrl -Method Get -TimeoutSec 10 -ErrorAction Stop
                
                if ($geoData -and -not $geoData.error) {
                    Write-Host ""
                    Write-Host "  LOCATION:" -ForegroundColor Yellow
                    
                    Write-Host "  Country:       " -NoNewline -ForegroundColor White
                    Write-Host "$($geoData.country_name) ($($geoData.country_code))" -ForegroundColor Green
                    
                    Write-Host "  Region:        " -NoNewline -ForegroundColor White
                    Write-Host $geoData.region -ForegroundColor Gray
                    
                    Write-Host "  City:          " -NoNewline -ForegroundColor White
                    Write-Host $geoData.city -ForegroundColor Gray
                    
                    Write-Host "  Postal Code:   " -NoNewline -ForegroundColor White
                    Write-Host $geoData.postal -ForegroundColor Gray
                    
                    Write-Host "  Timezone:      " -NoNewline -ForegroundColor White
                    Write-Host $geoData.timezone -ForegroundColor Gray
                    
                    Write-Host ""
                    Write-Host "  NETWORK:" -ForegroundColor Yellow
                    
                    Write-Host "  ISP:           " -NoNewline -ForegroundColor White
                    Write-Host $geoData.org -ForegroundColor Cyan
                    
                    Write-Host "  ASN:           " -NoNewline -ForegroundColor White
                    Write-Host $geoData.asn -ForegroundColor Gray
                    
                    Write-Host ""
                    Write-Host "  EXTRA INFO:" -ForegroundColor Yellow
                    
                    Write-Host "  Currency:      " -NoNewline -ForegroundColor White
                    Write-Host $geoData.currency -ForegroundColor Gray
                    
                    Write-Host "  Calling Code:  " -NoNewline -ForegroundColor White
                    Write-Host $geoData.country_calling_code -ForegroundColor Gray
                    
                    Write-Host "  Languages:     " -NoNewline -ForegroundColor White
                    Write-Host $geoData.languages -ForegroundColor Gray
                    
                    Add-AnalysisResult -Domain "My External IP" -RecordType "External IP" `
                        -Value $externalIP `
                        -Status "Found" `
                        -Details "$($geoData.city), $($geoData.country_name) - $($geoData.org)"
                }
            }
            catch {
                # Fallback to ip-api.com
                try {
                    $geoUrl = "http://ip-api.com/json/$externalIP"
                    $geoData = Invoke-RestMethod -Uri $geoUrl -Method Get -TimeoutSec 10 -ErrorAction Stop
                    
                    if ($geoData.status -eq "success") {
                        Write-Host ""
                        Write-Host "  LOCATION:" -ForegroundColor Yellow
                        
                        Write-Host "  Country:       " -NoNewline -ForegroundColor White
                        Write-Host "$($geoData.country) ($($geoData.countryCode))" -ForegroundColor Green
                        
                        Write-Host "  City:          " -NoNewline -ForegroundColor White
                        Write-Host $geoData.city -ForegroundColor Gray
                        
                        Write-Host ""
                        Write-Host "  NETWORK:" -ForegroundColor Yellow
                        
                        Write-Host "  ISP:           " -NoNewline -ForegroundColor White
                        Write-Host $geoData.isp -ForegroundColor Cyan
                        
                        Add-AnalysisResult -Domain "My External IP" -RecordType "External IP" `
                            -Value $externalIP `
                            -Status "Found" `
                            -Details "$($geoData.city), $($geoData.country) - $($geoData.isp)"
                    }
                }
                catch {
                    Write-Host "  Could not get location info" -ForegroundColor Yellow
                }
            }
            
            # Also show local network info
            Write-Host ""
            Write-Host "  LOCAL NETWORK:" -ForegroundColor Yellow
            
            $localIPs = Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -notmatch '^127\.' -and $_.IPAddress -notmatch '^169\.254\.' }
            foreach ($ip in $localIPs) {
                Write-Host "  Local IP:      " -NoNewline -ForegroundColor White
                Write-Host "$($ip.IPAddress) ($($ip.InterfaceAlias))" -ForegroundColor Gray
            }
            
            Write-Host ""
            Write-Host "============================================================" -ForegroundColor Cyan
        }
        else {
            Write-SouliTEKResult "Could not determine external IP" -Level ERROR
        }
    }
    catch {
        Write-SouliTEKResult "Failed to get external IP: $($_.Exception.Message)" -Level ERROR
    }
    
    Write-Host ""
    Read-Host "Press Enter to return to main menu"
}

# ============================================================
# SPEED TEST FUNCTION
# ============================================================

function Test-InternetSpeed {
    Show-Header "INTERNET SPEED TEST" -Color Blue
    
    Write-Host "      Test your internet connection speed" -ForegroundColor Gray
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    
    Write-SouliTEKResult "Preparing speed test..." -Level INFO
    Write-Host ""
    
    # Check if speedtest CLI is installed
    $speedtestPath = $null
    
    # Try to find speedtest.exe in common locations
    
    # 1. Check if in PATH
    $cmdPath = (Get-Command speedtest.exe -ErrorAction SilentlyContinue).Source
    if ($cmdPath) {
        $speedtestPath = $cmdPath
    }
    
    # 2. Check Program Files
    if (-not $speedtestPath) {
        $progPath = "$env:ProgramFiles\Ookla\Speedtest\speedtest.exe"
        if (Test-Path $progPath) {
            $speedtestPath = $progPath
        }
    }
    
    # 3. Check WinGet packages folder
    if (-not $speedtestPath) {
        $wingetPackages = Get-ChildItem "$env:LOCALAPPDATA\Microsoft\WinGet\Packages" -Filter "Ookla.Speedtest*" -Directory -ErrorAction SilentlyContinue
        if ($wingetPackages) {
            foreach ($pkg in $wingetPackages) {
                $exePath = Get-ChildItem $pkg.FullName -Filter "speedtest.exe" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
                if ($exePath) {
                    $speedtestPath = $exePath.FullName
                    break
                }
            }
        }
    }
    
    # 4. Check Chocolatey
    if (-not $speedtestPath) {
        $chocoPath = "$env:ChocolateyInstall\bin\speedtest.exe"
        if (Test-Path $chocoPath -ErrorAction SilentlyContinue) {
            $speedtestPath = $chocoPath
        }
    }
    
    if (-not $speedtestPath) {
        Write-Host ""
        Write-Host "============================================================" -ForegroundColor Yellow
        Write-Host "  SPEEDTEST CLI NOT INSTALLED" -ForegroundColor Yellow
        Write-Host "============================================================" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "  The Ookla Speedtest CLI is required for accurate speed tests." -ForegroundColor White
        Write-Host ""
        Write-Host "  Would you like to install it now? (requires WinGet)" -ForegroundColor Cyan
        Write-Host ""
        
        $install = Read-Host "  Install Speedtest CLI? [Y/n]"
        
        if ($install -eq '' -or $install -eq 'Y' -or $install -eq 'y') {
            Write-Host ""
            Write-SouliTEKResult "Installing Speedtest CLI via WinGet..." -Level INFO
            
            try {
                $result = Start-Process -FilePath "winget" -ArgumentList "install", "Ookla.Speedtest.CLI", "--accept-source-agreements", "--accept-package-agreements", "-h" -Wait -PassThru -NoNewWindow
                
                if ($result.ExitCode -eq 0) {
                    Write-SouliTEKResult "Speedtest CLI installed successfully!" -Level SUCCESS
                    Write-Host "  Please restart this tool to use the speed test." -ForegroundColor Yellow
                }
                else {
                    Write-SouliTEKResult "Installation failed. Try manually: winget install Ookla.Speedtest.CLI" -Level ERROR
                }
            }
            catch {
                Write-SouliTEKResult "Installation failed: $($_.Exception.Message)" -Level ERROR
            }
        }
        else {
            Write-Host ""
            Write-Host "  Alternative: Run a basic download test..." -ForegroundColor Yellow
            Write-Host ""
            
            $runBasic = Read-Host "  Run basic speed test? [Y/n]"
            
            if ($runBasic -eq '' -or $runBasic -eq 'Y' -or $runBasic -eq 'y') {
                # Basic download speed test
                Write-Host ""
                Write-SouliTEKResult "Running basic download test..." -Level INFO
                Write-Host ""
                
                try {
                    $testUrl = "http://speedtest.tele2.net/10MB.zip"
                    $testSize = 10MB
                    
                    Write-Host "  [*] Downloading 10MB test file..." -ForegroundColor Gray
                    
                    $startTime = Get-Date
                    $response = Invoke-WebRequest -Uri $testUrl -UseBasicParsing -TimeoutSec 60
                    $endTime = Get-Date
                    
                    $duration = ($endTime - $startTime).TotalSeconds
                    $speedMbps = [math]::Round(($testSize * 8 / $duration / 1000000), 2)
                    
                    Write-Host ""
                    Write-Host "============================================================" -ForegroundColor Green
                    Write-Host "  BASIC SPEED TEST RESULTS" -ForegroundColor Green
                    Write-Host "============================================================" -ForegroundColor Green
                    Write-Host ""
                    Write-Host "  Download Speed: " -NoNewline -ForegroundColor White
                    Write-Host "$speedMbps Mbps" -ForegroundColor Cyan
                    Write-Host "  Test Duration:  " -NoNewline -ForegroundColor White
                    Write-Host "$([math]::Round($duration, 2)) seconds" -ForegroundColor Gray
                    Write-Host "  Data Downloaded:" -NoNewline -ForegroundColor White
                    Write-Host " 10 MB" -ForegroundColor Gray
                    Write-Host ""
                    Write-Host "  Note: This is a basic test. Install Speedtest CLI for accurate results." -ForegroundColor Yellow
                    Write-Host ""
                    Write-Host "============================================================" -ForegroundColor Cyan
                    
                    Add-AnalysisResult -Domain "Speed Test" -RecordType "Download Speed" `
                        -Value "$speedMbps Mbps" `
                        -Status "Basic Test" `
                        -Details "Duration: $([math]::Round($duration, 2))s"
                }
                catch {
                    Write-SouliTEKResult "Basic speed test failed: $($_.Exception.Message)" -Level ERROR
                }
            }
        }
        
        Write-Host ""
        Read-Host "Press Enter to return to main menu"
        return
    }
    
    # Run Speedtest CLI
    Write-Host "  [*] Found Speedtest CLI: $speedtestPath" -ForegroundColor Green
    Write-Host ""
    Write-SouliTEKResult "Running speed test (this may take 30-60 seconds)..." -Level INFO
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Blue
    Write-Host ""
    
    try {
        # Run speed test with JSON output - include all acceptance flags
        Write-Host "  [*] Connecting to test server..." -ForegroundColor Gray
        
        # Use Start-Process with timeout for better control
        $pinfo = New-Object System.Diagnostics.ProcessStartInfo
        $pinfo.FileName = $speedtestPath
        $pinfo.Arguments = "--format=json --accept-license --accept-gdpr"
        $pinfo.RedirectStandardOutput = $true
        $pinfo.RedirectStandardError = $true
        $pinfo.UseShellExecute = $false
        $pinfo.CreateNoWindow = $true
        
        $process = New-Object System.Diagnostics.Process
        $process.StartInfo = $pinfo
        $process.Start() | Out-Null
        
        # Wait up to 90 seconds
        $completed = $process.WaitForExit(90000)
        
        if (-not $completed) {
            $process.Kill()
            Write-SouliTEKResult "Speed test timed out after 90 seconds" -Level ERROR
            Write-Host ""
            Read-Host "Press Enter to return to main menu"
            return
        }
        
        $jsonResult = $process.StandardOutput.ReadToEnd()
        $errorOutput = $process.StandardError.ReadToEnd()
        
        if ($errorOutput -and $errorOutput -notmatch "License|GDPR") {
            Write-Host "  [!] $errorOutput" -ForegroundColor Yellow
        }
        
        if ($jsonResult) {
            $result = $jsonResult | ConvertFrom-Json
            
            Write-Host ""
            Write-Host "============================================================" -ForegroundColor Green
            Write-Host "  SPEED TEST RESULTS" -ForegroundColor Green
            Write-Host "============================================================" -ForegroundColor Green
            Write-Host ""
            
            # Server info
            Write-Host "  SERVER:" -ForegroundColor Yellow
            Write-Host "  Name:          " -NoNewline -ForegroundColor White
            Write-Host "$($result.server.name)" -ForegroundColor Cyan
            Write-Host "  Location:      " -NoNewline -ForegroundColor White
            Write-Host "$($result.server.location), $($result.server.country)" -ForegroundColor Gray
            Write-Host "  Host:          " -NoNewline -ForegroundColor White
            Write-Host "$($result.server.host)" -ForegroundColor Gray
            
            Write-Host ""
            Write-Host "  SPEEDS:" -ForegroundColor Yellow
            
            # Download speed (convert from bytes/s to Mbps)
            $downloadMbps = [math]::Round($result.download.bandwidth * 8 / 1000000, 2)
            Write-Host "  Download:      " -NoNewline -ForegroundColor White
            $dlColor = if ($downloadMbps -ge 100) { 'Green' } elseif ($downloadMbps -ge 25) { 'Yellow' } else { 'Red' }
            Write-Host "$downloadMbps Mbps" -ForegroundColor $dlColor
            
            # Upload speed
            $uploadMbps = [math]::Round($result.upload.bandwidth * 8 / 1000000, 2)
            Write-Host "  Upload:        " -NoNewline -ForegroundColor White
            $ulColor = if ($uploadMbps -ge 50) { 'Green' } elseif ($uploadMbps -ge 10) { 'Yellow' } else { 'Red' }
            Write-Host "$uploadMbps Mbps" -ForegroundColor $ulColor
            
            Write-Host ""
            Write-Host "  LATENCY:" -ForegroundColor Yellow
            Write-Host "  Ping:          " -NoNewline -ForegroundColor White
            $pingColor = if ($result.ping.latency -lt 20) { 'Green' } elseif ($result.ping.latency -lt 50) { 'Yellow' } else { 'Red' }
            Write-Host "$([math]::Round($result.ping.latency, 2)) ms" -ForegroundColor $pingColor
            
            Write-Host "  Jitter:        " -NoNewline -ForegroundColor White
            Write-Host "$([math]::Round($result.ping.jitter, 2)) ms" -ForegroundColor Gray
            
            Write-Host ""
            Write-Host "  CONNECTION:" -ForegroundColor Yellow
            Write-Host "  External IP:   " -NoNewline -ForegroundColor White
            Write-Host "$($result.interface.externalIp)" -ForegroundColor Cyan
            Write-Host "  Internal IP:   " -NoNewline -ForegroundColor White
            Write-Host "$($result.interface.internalIp)" -ForegroundColor Gray
            Write-Host "  ISP:           " -NoNewline -ForegroundColor White
            Write-Host "$($result.isp)" -ForegroundColor Gray
            
            Write-Host ""
            Write-Host "============================================================" -ForegroundColor Cyan
            Write-Host ""
            Write-Host "  Result URL: " -NoNewline -ForegroundColor Yellow
            Write-Host "$($result.result.url)" -ForegroundColor Cyan
            Write-Host ""
            Write-Host "============================================================" -ForegroundColor Cyan
            
            Add-AnalysisResult -Domain "Speed Test" -RecordType "Internet Speed" `
                -Value "DL: $downloadMbps Mbps, UL: $uploadMbps Mbps, Ping: $([math]::Round($result.ping.latency, 2))ms" `
                -Status "Complete" `
                -Details "Server: $($result.server.name), ISP: $($result.isp)"
        }
        else {
            Write-SouliTEKResult "Speed test returned no results" -Level ERROR
        }
    }
    catch {
        Write-SouliTEKResult "Speed test failed: $($_.Exception.Message)" -Level ERROR
    }
    
    Write-Host ""
    Read-Host "Press Enter to return to main menu"
}

# ============================================================
# SSL CERTIFICATE CHECK FUNCTION
# ============================================================

function Get-SSLCertificate {
    param([string]$Domain)
    
    Show-Header "SSL CERTIFICATE CHECK" -Color DarkYellow
    
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
    Show-Header "DOMAIN & DNS ANALYZER - Professional Edition" -Color Cyan
    
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
    Write-Host "  NETWORK TOOLS:" -ForegroundColor DarkCyan
    Write-Host "  [6] GeoIP Lookup             - Find server location" -ForegroundColor Yellow
    Write-Host "  [7] My External IP           - Your public IP & location" -ForegroundColor Yellow
    Write-Host "  [8] Internet Speed Test      - Test connection speed" -ForegroundColor Yellow
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

function Show-Disclaimer {
    Clear-Host
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "                    IMPORTANT NOTICE" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  This tool is provided `"AS IS`" without warranty." -ForegroundColor White
    Write-Host ""
    Write-Host "  USE AT YOUR OWN RISK" -ForegroundColor Red
    Write-Host ""
    Write-Host "  By continuing, you acknowledge that:" -ForegroundColor White
    Write-Host "  - You are solely responsible for any outcomes" -ForegroundColor Gray
    Write-Host "  - You will use this tool responsibly" -ForegroundColor Gray
    Write-Host "  - You accept full responsibility for its use" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  This tool queries public WHOIS and DNS data." -ForegroundColor Yellow
    Write-Host "  Only use on domains you are authorized to analyze." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Press any key to continue or Ctrl+C to cancel..." -ForegroundColor Cyan
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
}

function Show-ExitMessage {
    Clear-Host
    Write-Host ""
    Write-Host "Thank you for using SouliTEK Domain & DNS Analyzer!" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Website: www.soulitek.co.il" -ForegroundColor Yellow
    Write-Host ""
    
    # Self-destruct: Remove script file after execution
    Invoke-SouliTEKSelfDestruct -ScriptPath $PSCommandPath -Silent
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
        "6" { Get-GeoIPLocation }
        "7" { Get-MyExternalIP }
        "8" { Test-InternetSpeed }
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

