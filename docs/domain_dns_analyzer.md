# Domain & DNS Analyzer

## Overview

The **Domain & DNS Analyzer** provides comprehensive domain WHOIS lookup and DNS record analysis for IT professionals. It's designed for troubleshooting DNS issues, verifying email security configurations, and auditing domain settings.

## Purpose

Provides domain and DNS diagnostic capabilities:
- WHOIS registration lookup (via RDAP API)
- Complete DNS record analysis
- Email security verification (SPF, DKIM, DMARC)
- Export detailed reports

## Features

### 🔍 **WHOIS Lookup (RDAP)**
- Domain registration status
- Registrar information
- Creation, update, and expiration dates
- Name server listing
- DNSSEC status
- Days until expiration warning

### 📋 **DNS Record Analysis**
- **A Records** - IPv4 addresses
- **AAAA Records** - IPv6 addresses
- **MX Records** - Mail server priorities
- **TXT Records** - Text records (including SPF)
- **CNAME Records** - Domain aliases
- **NS Records** - Name servers
- **SOA Records** - Start of Authority
- **SRV Records** - Service records

### 🔐 **Email Security Check**
- **SPF Analysis** - Sender Policy Framework verification
  - Policy detection (hard fail, soft fail, neutral)
  - Mechanism parsing
- **DKIM Detection** - DomainKeys Identified Mail
  - Auto-checks common selectors (google, default, selector1, selector2, etc.)
  - Custom selector input option
- **DMARC Verification** - Domain-based Message Authentication
  - Policy detection (none, quarantine, reject)
  - Reporting configuration check
- **Security Score** - Visual security assessment

### 📊 **Export Capabilities**
- Text file reports (.txt)
- CSV data export (.csv)
- HTML formatted reports (.html)
- Branded SouliTEK reports

## Requirements

### System Requirements
- **OS:** Windows 10 or Windows 11
- **PowerShell:** Version 5.1 or higher
- **Privileges:** Standard user (no admin required)
- **Network:** Active internet connection

### Dependencies
- Uses native PowerShell `Resolve-DnsName` cmdlet
- Uses RDAP API for WHOIS (no external tools needed)
- No additional module installation required

## Usage

### Running the Script

1. **Launch from SouliTEK Launcher** (recommended)
   - Open the SouliTEK Launcher
   - Find "Domain & DNS Analyzer" in the Internet category
   - Click the tool card to launch

2. **Run directly via PowerShell:**
   ```powershell
   .\scripts\domain_dns_analyzer.ps1
   ```

### Menu Options

#### Option 1: Full Domain Analysis
Complete analysis including:
- WHOIS registration data
- All DNS record types
- Email security check (SPF, DKIM, DMARC)
- Combined results for comprehensive overview

#### Option 2: WHOIS Lookup
Query domain registration information:
- Domain status (active, expired, etc.)
- Registrar name
- Registration and expiration dates
- Name servers
- DNSSEC status
- Expiration warnings (color-coded)

#### Option 3: DNS Records
Query all DNS record types:
- A, AAAA (IP addresses)
- MX (mail servers)
- TXT (text records)
- CNAME (aliases)
- NS (name servers)
- SOA (authority)
- SRV (services)

#### Option 4: Email Security Check
Detailed email authentication analysis:
- SPF record validation and policy analysis
- DKIM detection across multiple selectors
- DMARC policy verification
- Security score calculation (0-3)
- Recommendations for improvement

#### Option 5: Export Results
Save analysis results to:
- Text file (.txt) - Human-readable report
- CSV file (.csv) - Spreadsheet format
- HTML file (.html) - Formatted web report

#### Option 6: Clear Results
Clear all stored analysis results.

#### Option 7: Help
Display usage guide and DNS record explanations.

## Technical Details

### WHOIS Implementation (RDAP)
The tool uses **RDAP (Registration Data Access Protocol)**, the modern replacement for traditional WHOIS:
- Primary endpoint: `https://rdap.org/domain/{domain}`
- Returns structured JSON data
- No rate limiting for normal usage
- Supports most TLDs

### DNS Record Types Explained

| Record Type | Purpose | Example |
|------------|---------|---------|
| A | IPv4 address mapping | 93.184.216.34 |
| AAAA | IPv6 address mapping | 2606:2800:220:1:... |
| MX | Mail server | 10 mail.example.com |
| TXT | Text data (SPF, verification) | v=spf1 include:... |
| CNAME | Alias to another domain | www -> example.com |
| NS | Authoritative name servers | ns1.example.com |
| SOA | Zone authority info | Primary NS, serial |
| SRV | Service location | _sip._tcp.example.com |

### Email Security Records

#### SPF (Sender Policy Framework)
- Location: TXT record at domain root
- Format: `v=spf1 [mechanisms] [qualifier]all`
- Qualifiers:
  - `-all` = Hard fail (strict, recommended)
  - `~all` = Soft fail (moderate)
  - `?all` = Neutral (no policy)
  - `+all` = Pass all (INSECURE!)

#### DKIM (DomainKeys Identified Mail)
- Location: TXT record at `{selector}._domainkey.{domain}`
- Common selectors checked:
  - google, default, selector1, selector2
  - s1, s2, k1, dkim, mail, email
- Format: `v=DKIM1; k=rsa; p=[public key]`

#### DMARC (Domain-based Message Authentication)
- Location: TXT record at `_dmarc.{domain}`
- Format: `v=DMARC1; p={policy}; [options]`
- Policies:
  - `p=none` - Monitoring only
  - `p=quarantine` - Mark as spam
  - `p=reject` - Reject emails

## Output Files

### Report Locations
- **Desktop:** Reports saved to `%USERPROFILE%\Desktop`
- **Formats:** TXT, CSV, HTML
- **Filename:** `DomainAnalysis_{domain}_{timestamp}.[ext]`

### Report Contents
- Domain analyzed
- All discovered records
- Record values and status
- Timestamps
- Security analysis results

## Troubleshooting

### WHOIS Lookup Fails
**Problem:** Cannot retrieve WHOIS data

**Possible Causes:**
- Domain does not exist
- TLD not supported by RDAP
- Network connectivity issue
- RDAP service temporarily unavailable

**Solutions:**
1. Verify domain spelling
2. Check internet connection
3. Try again later
4. Some TLDs may not support RDAP

### DNS Lookup Fails
**Problem:** Cannot resolve DNS records

**Causes:**
- Domain doesn't exist
- DNS server issues
- Network problems

**Solutions:**
1. Verify domain exists
2. Check network connection
3. Try with different DNS server

### DKIM Not Found
**Problem:** DKIM shows as missing

**Note:** This may be normal if:
- DKIM uses a non-standard selector
- DKIM is not configured
- Custom selector needed

**Solution:**
Enter a custom selector when prompted, or check with domain administrator for the correct selector.

## Best Practices

### Domain Analysis
- Analyze domains before email migrations
- Regular checks for domain expiration
- Verify DNS after changes
- Document current configuration

### Email Security
- Ensure all three records exist (SPF, DKIM, DMARC)
- Use strict policies when possible
- Monitor DMARC reports
- Regular security audits

### Troubleshooting Workflow
1. Start with Full Domain Analysis
2. Check WHOIS for basic domain health
3. Verify DNS records resolve correctly
4. Check email security configuration
5. Export results for documentation

## Security Score Interpretation

| Score | Rating | Meaning |
|-------|--------|---------|
| 3/3 | Excellent | All email security records configured |
| 2/3 | Good | Most records present, minor gaps |
| 1/3 | Fair | Significant security gaps |
| 0/3 | Poor | No email security configured |

## Common Use Cases

### Pre-Migration Audit
Before migrating email or DNS:
1. Run Full Domain Analysis
2. Export results as baseline
3. Compare after migration

### Security Assessment
Verify client domain security:
1. Run Email Security Check
2. Review security score
3. Provide recommendations

### Troubleshooting Email Issues
When emails aren't delivered:
1. Check MX records
2. Verify SPF configuration
3. Check DKIM and DMARC

## Support

For assistance or to report issues:
- **Website:** www.soulitek.co.il
- **Email:** letstalk@soulitek.co.il

---

**Coded by:** SouliTEK  
*IT Solutions for your business*

(C) 2025 SouliTEK - All Rights Reserved





