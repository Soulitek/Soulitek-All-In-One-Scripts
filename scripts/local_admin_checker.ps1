# ============================================================
# SouliTEK All-In-One Scripts - Local Admin Users Checker
# ============================================================
# 
# Coded by: Soulitek.co.il
# IT Solutions for your business
# 
# (C) 2025 SouliTEK - All Rights Reserved
# Website: www.soulitek.co.il
# 
# This tool identifies users with local administrator privileges
# and flags potentially unnecessary admin accounts.
# 
# ============================================================

#Requires -Version 5.1

$Script:Version = "1.0.0"
$Script:ToolName = "Local Admin Users Checker"

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

# Known standard/expected admin accounts (usually safe)
$Script:StandardAdmins = @(
    "Administrator",
    "Administrators",
    "Domain Admins",
    "Enterprise Admins",
    "BUILTIN\Administrators"
)

# Patterns that might indicate unnecessary admin accounts
$Script:SuspiciousPatterns = @(
    "test", "temp", "demo", "guest", "backup",
    "service", "support", "helpdesk", "admin",
    "user", "user1", "user2", "user3"
)

# ============================================================
# HELPER FUNCTIONS
# ============================================================

function Get-LocalAdminUsers {
    <#
    .SYNOPSIS
        Gets all users in the local Administrators group.
    #>
    
    $adminUsers = @()
    
    try {
        # Get the Administrators group
        $adminGroup = Get-LocalGroup -Name "Administrators" -ErrorAction Stop
        
        # Get all members of the Administrators group
        $members = Get-LocalGroupMember -Group "Administrators" -ErrorAction Stop
        
        foreach ($member in $members) {
            $memberType = $member.ObjectClass
            $principal = $member.Name
            
            # Handle null or empty principal
            if ([string]::IsNullOrWhiteSpace($principal)) {
                $principal = "Unknown"
            }
            
            # Parse the principal string
            $principalParts = $principal -split "\\"
            if ($principalParts.Count -eq 2) {
                $domain = $principalParts[0]
                $username = $principalParts[1]
            } else {
                $domain = $env:COMPUTERNAME
                $username = $principal
            }
            
            # Ensure username is not null
            if ([string]::IsNullOrWhiteSpace($username)) {
                $username = "Unknown"
            }
            
            # Ensure domain is not null
            if ([string]::IsNullOrWhiteSpace($domain)) {
                $domain = $env:COMPUTERNAME
            }
            
            # Get additional info for local users
            $userInfo = $null
            if ($memberType -eq "User" -and $domain -eq $env:COMPUTERNAME) {
                try {
                    $localUser = Get-LocalUser -Name $username -ErrorAction SilentlyContinue
                    if ($localUser) {
                        $userInfo = $localUser
                    }
                } catch {
                    # User might not exist locally
                }
            }
            
            $adminUsers += [PSCustomObject]@{
                Username = $username
                Domain = $domain
                FullName = $principal
                ObjectClass = $memberType
                IsLocal = ($domain -eq $env:COMPUTERNAME)
                IsStandard = ($Script:StandardAdmins -contains $username -or $Script:StandardAdmins -contains $principal)
                IsEnabled = if ($userInfo) { $userInfo.Enabled } else { $null }
                PasswordNeverExpires = if ($userInfo) { $userInfo.PasswordNeverExpires } else { $null }
                LastLogon = if ($userInfo) { $userInfo.LastLogon } else { $null }
                Description = if ($userInfo) { $userInfo.Description } else { "" }
                SID = $member.SID
            }
        }
    }
    catch {
        Write-SouliTEKError "Failed to get local administrators: $($_.Exception.Message)"
        return @()
    }
    
    return $adminUsers
}

function Test-SuspiciousAdmin {
    <#
    .SYNOPSIS
        Checks if an admin account might be unnecessary or suspicious.
    #>
    param(
        [PSCustomObject]$AdminUser
    )
    
    $warnings = @()
    $riskLevel = "Low"
    
    # Skip standard accounts
    if ($AdminUser.IsStandard) {
        return [PSCustomObject]@{
            RiskLevel = "Low"
            Warnings = @("Standard system account")
            IsSuspicious = $false
        }
    }
    
    # Check for suspicious patterns in username
    if (-not [string]::IsNullOrWhiteSpace($AdminUser.Username)) {
        $usernameLower = $AdminUser.Username.ToLower()
        foreach ($pattern in $Script:SuspiciousPatterns) {
            if ($usernameLower -like "*$pattern*") {
                $warnings += "Username contains suspicious pattern: '$pattern'"
                $riskLevel = "Medium"
            }
        }
        
        # Check for generic/test account names
        if ($usernameLower -match "^(test|temp|demo|guest|backup|service|support|helpdesk)") {
            $warnings += "Generic account name (may be unnecessary)"
            $riskLevel = "High"
        }
    }
    
    # Check if account is disabled
    if ($AdminUser.IsEnabled -eq $false) {
        $warnings += "Account is DISABLED but still in Administrators group"
        $riskLevel = "High"
    }
    
    # Check if password never expires (security risk)
    if ($AdminUser.PasswordNeverExpires -eq $true) {
        $warnings += "Password never expires (security risk)"
        if ($riskLevel -eq "Low") {
            $riskLevel = "Medium"
        }
    }
    
    # Check if it's a domain account (usually expected)
    if (-not $AdminUser.IsLocal) {
        $warnings += "Domain account (verify if needed)"
    }
    
    # Check if account has no description (might indicate lack of documentation)
    if ([string]::IsNullOrWhiteSpace($AdminUser.Description) -and $AdminUser.IsLocal) {
        $warnings += "No description (documentation missing)"
    }
    
    return [PSCustomObject]@{
        RiskLevel = $riskLevel
        Warnings = $warnings
        IsSuspicious = ($riskLevel -ne "Low" -or $warnings.Count -gt 1)
    }
}

# ============================================================
# DISPLAY FUNCTIONS
# ============================================================

function Show-AdminUserDetails {
    <#
    .SYNOPSIS
        Shows detailed information about an admin user.
    #>
    param(
        [PSCustomObject]$AdminUser,
        [int]$Index
    )
    
    $analysis = Test-SuspiciousAdmin -AdminUser $AdminUser
    
    $riskColor = switch ($analysis.RiskLevel) {
        "High" { "Red" }
        "Medium" { "Yellow" }
        default { "Green" }
    }
    
    Write-Host ""
    $displayName = if ([string]::IsNullOrWhiteSpace($AdminUser.Username)) { 
        if ([string]::IsNullOrWhiteSpace($AdminUser.FullName)) { "Unknown" } else { $AdminUser.FullName }
    } else { 
        $AdminUser.Username 
    }
    Write-Host "  [$Index] $displayName" -ForegroundColor White
    if (-not [string]::IsNullOrWhiteSpace($AdminUser.FullName) -and $AdminUser.FullName -ne $displayName) {
        Write-Host "      Full Name: $($AdminUser.FullName)" -ForegroundColor Gray
    }
    if (-not [string]::IsNullOrWhiteSpace($AdminUser.Domain)) {
        Write-Host "      Domain: $($AdminUser.Domain)" -ForegroundColor Gray
    }
    if (-not [string]::IsNullOrWhiteSpace($AdminUser.ObjectClass)) {
        Write-Host "      Type: $($AdminUser.ObjectClass)" -ForegroundColor Gray
    }
    Write-Host "      Local Account: " -NoNewline -ForegroundColor Gray
    Write-Host $(if ($AdminUser.IsLocal) { "Yes" } else { "No" }) -ForegroundColor $(if ($AdminUser.IsLocal) { "Cyan" } else { "Yellow" })
    
    if ($AdminUser.IsLocal -and $AdminUser.IsEnabled -ne $null) {
        Write-Host "      Enabled: " -NoNewline -ForegroundColor Gray
        Write-Host $(if ($AdminUser.IsEnabled) { "Yes" } else { "No" }) -ForegroundColor $(if ($AdminUser.IsEnabled) { "Green" } else { "Red" })
        
        if ($AdminUser.PasswordNeverExpires -ne $null) {
            Write-Host "      Password Never Expires: " -NoNewline -ForegroundColor Gray
            Write-Host $(if ($AdminUser.PasswordNeverExpires) { "Yes" } else { "No" }) -ForegroundColor $(if ($AdminUser.PasswordNeverExpires) { "Yellow" } else { "Green" })
        }
        
        if ($AdminUser.LastLogon) {
            $lastLogonStr = $AdminUser.LastLogon.ToString("yyyy-MM-dd HH:mm:ss")
            Write-Host "      Last Logon: $lastLogonStr" -ForegroundColor Gray
        }
        
        if (-not [string]::IsNullOrWhiteSpace($AdminUser.Description)) {
            Write-Host "      Description: $($AdminUser.Description)" -ForegroundColor Gray
        }
    }
    
    Write-Host "      Risk Level: " -NoNewline -ForegroundColor Gray
    Write-Host $analysis.RiskLevel -ForegroundColor $riskColor
    
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
        [array]$AdminUsers
    )
    
    $high = 0
    $medium = 0
    $low = 0
    $standard = 0
    $local = 0
    $domain = 0
    
    foreach ($user in $AdminUsers) {
        $analysis = Test-SuspiciousAdmin -AdminUser $user
        switch ($analysis.RiskLevel) {
            "High" { $high++ }
            "Medium" { $medium++ }
            "Low" { $low++ }
        }
        
        if ($user.IsStandard) {
            $standard++
        }
        
        if ($user.IsLocal) {
            $local++
        } else {
            $domain++
        }
    }
    
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "  SCAN SUMMARY" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Total Admin Users: $($AdminUsers.Count)" -ForegroundColor White
    Write-Host ""
    Write-Host "  Account Types:" -ForegroundColor White
    Write-Host "    - Standard Accounts: $standard" -ForegroundColor Gray
    Write-Host "    - Local Accounts: $local" -ForegroundColor Cyan
    Write-Host "    - Domain Accounts: $domain" -ForegroundColor Yellow
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
        Write-Host "  [!] WARNING: $high admin account(s) with HIGH risk detected!" -ForegroundColor Red
        Write-Host "      Review these accounts immediately and remove if unnecessary." -ForegroundColor Yellow
    } elseif ($medium -gt 0) {
        Write-Host "  [*] $medium admin account(s) with elevated risk detected." -ForegroundColor Yellow
        Write-Host "      Review to ensure they are necessary and properly secured." -ForegroundColor Gray
    } else {
        Write-Host "  [+] No high-risk admin accounts detected." -ForegroundColor Green
    }
    
    Write-Host ""
}

# ============================================================
# MAIN FUNCTIONS
# ============================================================

function Invoke-FullScan {
    <#
    .SYNOPSIS
        Performs a full scan of local administrator accounts.
    #>
    
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "  SCANNING LOCAL ADMINISTRATOR ACCOUNTS" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Retrieving Administrators group members..." -ForegroundColor Cyan
    
    $Script:ScanResults = Get-LocalAdminUsers
    
    if ($Script:ScanResults.Count -eq 0) {
        Write-Host "No administrator accounts found or unable to retrieve list." -ForegroundColor Yellow
        Wait-SouliTEKKeyPress
        return
    }
    
    Write-Host "Found $($Script:ScanResults.Count) administrator account(s)" -ForegroundColor Green
    Write-Host ""
    
    # Show summary
    Show-ScanSummary -AdminUsers $Script:ScanResults
    
    # Show all admin users
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "  ALL ADMINISTRATOR ACCOUNTS" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
    
    $index = 1
    foreach ($user in $Script:ScanResults) {
        Show-AdminUserDetails -AdminUser $user -Index $index
        $index++
    }
    
    Write-Host ""
    Wait-SouliTEKKeyPress
}

function Show-SuspiciousAdmins {
    <#
    .SYNOPSIS
        Shows only suspicious/unnecessary admin accounts.
    #>
    
    if ($Script:ScanResults.Count -eq 0) {
        Write-Host ""
        Write-Host "No scan results. Please run a full scan first (Option 1)." -ForegroundColor Yellow
        Wait-SouliTEKKeyPress
        return
    }
    
    $suspiciousAdmins = @()
    foreach ($user in $Script:ScanResults) {
        $analysis = Test-SuspiciousAdmin -AdminUser $user
        if ($analysis.IsSuspicious -and -not $user.IsStandard) {
            $suspiciousAdmins += $user
        }
    }
    
    Clear-Host
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Yellow
    Write-Host "  SUSPICIOUS/UNNECESSARY ADMIN ACCOUNTS ($($suspiciousAdmins.Count))" -ForegroundColor Yellow
    Write-Host "============================================================" -ForegroundColor Yellow
    
    if ($suspiciousAdmins.Count -eq 0) {
        Write-Host ""
        Write-Host "  No suspicious admin accounts detected!" -ForegroundColor Green
        Write-Host "  All admin accounts appear to be standard or properly configured." -ForegroundColor Gray
        Write-Host ""
    } else {
        $index = 1
        foreach ($user in $suspiciousAdmins) {
            Show-AdminUserDetails -AdminUser $user -Index $index
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
    
    $format = Show-SouliTEKExportMenu -Title "EXPORT ADMIN USERS REPORT"
    
    if ($format -eq "CANCEL") {
        return
    }
    
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $desktopPath = [Environment]::GetFolderPath("Desktop")
    
    # Add risk level to export data
    $exportData = foreach ($user in $Script:ScanResults) {
        $analysis = Test-SuspiciousAdmin -AdminUser $user
        [PSCustomObject]@{
            Username = if ([string]::IsNullOrWhiteSpace($user.Username)) { "Unknown" } else { $user.Username }
            FullName = if ([string]::IsNullOrWhiteSpace($user.FullName)) { "" } else { $user.FullName }
            Domain = if ([string]::IsNullOrWhiteSpace($user.Domain)) { "" } else { $user.Domain }
            ObjectClass = if ([string]::IsNullOrWhiteSpace($user.ObjectClass)) { "" } else { $user.ObjectClass }
            IsLocal = $user.IsLocal
            IsStandard = $user.IsStandard
            IsEnabled = $user.IsEnabled
            PasswordNeverExpires = $user.PasswordNeverExpires
            LastLogon = if ($user.LastLogon) { $user.LastLogon.ToString("yyyy-MM-dd HH:mm:ss") } else { "" }
            Description = if ([string]::IsNullOrWhiteSpace($user.Description)) { "" } else { $user.Description }
            RiskLevel = $analysis.RiskLevel
            Warnings = ($analysis.Warnings -join "; ")
            SID = if ($user.SID) { $user.SID.ToString() } else { "" }
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
        $outputPath = Join-Path $desktopPath "Local_Admin_Users_$timestamp.$extension"
        
        $extraInfo = @{
            "Total Admin Users" = $Script:ScanResults.Count
            "High Risk" = $high
            "Medium Risk" = $medium
            "Local Accounts" = ($Script:ScanResults | Where-Object { $_.IsLocal }).Count
            "Domain Accounts" = ($Script:ScanResults | Where-Object { -not $_.IsLocal }).Count
        }
        
        Export-SouliTEKReport -Data $exportData -Title "Local Administrator Users Report" `
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
    Write-Host "  LOCAL ADMIN USERS CHECKER - HELP" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  ABOUT:" -ForegroundColor Yellow
    Write-Host "  This tool identifies users with local administrator privileges" -ForegroundColor Gray
    Write-Host "  and flags potentially unnecessary or suspicious admin accounts." -ForegroundColor Gray
    Write-Host "  This is a common attack vector - attackers often target admin accounts." -ForegroundColor Gray
    Write-Host ""
    Write-Host "  WHAT IT DOES:" -ForegroundColor Yellow
    Write-Host "  - Lists all members of the local Administrators group" -ForegroundColor Gray
    Write-Host "  - Analyzes each account for security risks" -ForegroundColor Gray
    Write-Host "  - Flags suspicious patterns and configurations" -ForegroundColor Gray
    Write-Host "  - Identifies potentially unnecessary admin accounts" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  RISK LEVELS:" -ForegroundColor Yellow
    Write-Host "  - High:   " -NoNewline -ForegroundColor Red
    Write-Host "Disabled accounts, generic names (test/temp/demo)" -ForegroundColor Gray
    Write-Host "  - Medium: " -NoNewline -ForegroundColor Yellow
    Write-Host "Suspicious patterns, password never expires" -ForegroundColor Gray
    Write-Host "  - Low:    " -NoNewline -ForegroundColor Green
    Write-Host "Standard accounts or properly configured" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  RED FLAGS:" -ForegroundColor Yellow
    Write-Host "  - Disabled accounts still in Administrators group" -ForegroundColor Red
    Write-Host "  - Generic account names (test, temp, demo, guest)" -ForegroundColor Red
    Write-Host "  - Accounts with password never expires" -ForegroundColor Yellow
    Write-Host "  - Accounts with no description/documentation" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  RECOMMENDATIONS:" -ForegroundColor Yellow
    Write-Host "  - Remove unnecessary admin accounts" -ForegroundColor Gray
    Write-Host "  - Use domain accounts instead of local when possible" -ForegroundColor Gray
    Write-Host "  - Document all admin accounts with descriptions" -ForegroundColor Gray
    Write-Host "  - Enable password expiration for admin accounts" -ForegroundColor Gray
    Write-Host "  - Regularly audit admin group membership" -ForegroundColor Gray
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
    Write-Host "  LOCAL ADMIN USERS CHECKER v$Script:Version" -ForegroundColor Magenta
    Write-Host "  Identify unnecessary admin accounts - Common attack vector" -ForegroundColor Gray
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host ""
    
    if ($Script:ScanResults.Count -gt 0) {
        Write-Host "  Last Scan: $($Script:ScanResults.Count) admin user(s) found" -ForegroundColor Cyan
    }
    
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  [1] Full Scan" -ForegroundColor Yellow
    Write-Host "      Scan and analyze all local administrator accounts" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  [2] View Suspicious Admins" -ForegroundColor Yellow
    Write-Host "      Show only suspicious/unnecessary admin accounts" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  [3] Export Results" -ForegroundColor Yellow
    Write-Host "      Export scan results to file" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  [4] Help" -ForegroundColor Yellow
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
Show-ScriptBanner -ScriptName "Local Admin Users Checker" -Purpose "Check and manage local administrator accounts on the system"

# Check for admin privileges
$isAdmin = Invoke-SouliTEKAdminCheck -Required -FeatureName "Local Admin Users Checker"

# Main loop
do {
    Show-Menu
    $choice = Read-Host "Select option (0-4)"
    
    switch ($choice) {
        "1" { Invoke-FullScan }
        "2" { Show-SuspiciousAdmins }
        "3" { Export-ScanResults }
        "4" { Show-Help }
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
