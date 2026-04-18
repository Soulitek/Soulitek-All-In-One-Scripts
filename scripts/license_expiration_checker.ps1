# ============================================================
# License Expiration Checker - Professional Edition
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
# This tool monitors Microsoft 365 license expiration dates
# and sends alerts for licenses nearing expiration.
# 
# Features: License Status | Expiration Monitoring | Usage Stats
#           Alert System | Export Results
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

# Requires Microsoft Graph PowerShell SDK
#Requires -Modules Microsoft.Graph.Identity.DirectoryManagement

# Set window title
$Host.UI.RawUI.WindowTitle = "LICENSE EXPIRATION CHECKER"

# Set preferences to suppress prompts during module installation
$ProgressPreference = 'SilentlyContinue'
$WarningPreference = 'Continue'
$ErrorActionPreference = 'Continue'

# Import SouliTEK Common Functions
$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$CommonPath = Join-Path (Split-Path -Parent $ScriptRoot) "modules\SouliTEK-Common.ps1"
if (Test-Path $CommonPath) {
    . $CommonPath
} else {
    Write-Warning "SouliTEK Common Functions not found at: $CommonPath"
    Write-Warning "Some functions may not work properly."
}

# Module installation handled by centralized function from SouliTEK-Common.ps1
# Microsoft Graph modules will be installed when needed during Microsoft Graph connection

# ============================================================
# GLOBAL VARIABLES
# ============================================================

$Script:LicenseData = @()
$Script:OutputFolder = Join-Path $env:USERPROFILE "Desktop"
$Script:AlertThresholdDays = 14
$Script:WarningThresholdDays = 30
$Script:Connected = $false

# ============================================================
# HELPER FUNCTIONS
# ============================================================

# Install-RequiredModule function has been replaced by Install-SouliTEKModule from SouliTEK-Common.ps1

# Show-Header function removed - using Show-SouliTEKHeader from common module

function Get-FriendlySkuName {
    param([string]$SkuPartNumber)
    
    $skuNames = @{
        'ENTERPRISEPACK' = 'Office 365 E3'
        'ENTERPRISEPREMIUM' = 'Office 365 E5'
        'ENTERPRISEPACK_B_PILOT' = 'Office 365 E3 (Preview)'
        'EXCHANGESTANDARD' = 'Exchange Online (Plan 1)'
        'EXCHANGEENTERPRISE' = 'Exchange Online (Plan 2)'
        'SHAREPOINTENTERPRISE' = 'SharePoint Online (Plan 2)'
        'SHAREPOINTSTANDARD' = 'SharePoint Online (Plan 1)'
        'MCOSTANDARD' = 'Skype for Business Online (Plan 2)'
        'PROJECTPROFESSIONAL' = 'Project Online Professional'
        'VISIOCLIENT' = 'Visio Online Plan 2'
        'POWER_BI_STANDARD' = 'Power BI (free)'
        'POWER_BI_PRO' = 'Power BI Pro'
        'ENTERPRISEPREMIUM_NOPSTNCONF' = 'Office 365 E5 without Audio Conferencing'
        'SPE_E3' = 'Microsoft 365 E3'
        'SPE_E5' = 'Microsoft 365 E5'
        'SPB' = 'Microsoft 365 Business Premium'
        'O365_BUSINESS_ESSENTIALS' = 'Microsoft 365 Business Basic'
        'O365_BUSINESS_PREMIUM' = 'Microsoft 365 Business Standard'
        'ATP_ENTERPRISE' = 'Microsoft Defender for Office 365 (Plan 1)'
        'THREAT_INTELLIGENCE' = 'Microsoft Defender for Office 365 (Plan 2)'
        'FLOW_FREE' = 'Microsoft Power Automate Free'
        'FLOW_P1' = 'Microsoft Power Automate Plan 1'
        'FLOW_P2' = 'Microsoft Power Automate Plan 2'
        'POWERAPPS_VIRAL' = 'Microsoft PowerApps Plan 1'
        'TEAMS_COMMERCIAL_TRIAL' = 'Microsoft Teams Commercial Cloud (Trial)'
        'TEAMS_EXPLORATORY' = 'Microsoft Teams Exploratory'
        'WIN10_PRO_ENT_SUB' = 'Windows 10 Enterprise E3'
        'WIN10_VDA_E3' = 'Windows 10 Enterprise E3'
        'WIN10_VDA_E5' = 'Windows 10 Enterprise E5'
        'WINDOWS_STORE' = 'Windows Store for Business'
        'EMSPREMIUM' = 'Enterprise Mobility + Security E5'
        'EMS' = 'Enterprise Mobility + Security E3'
        'AAD_PREMIUM' = 'Azure Active Directory Premium P1'
        'AAD_PREMIUM_P2' = 'Azure Active Directory Premium P2'
        'INTUNE_A' = 'Microsoft Intune'
        'RIGHTSMANAGEMENT' = 'Azure Information Protection Premium P1'
        'DYN365_ENTERPRISE_SALES' = 'Dynamics 365 Sales'
        'DYN365_ENTERPRISE_CUSTOMER_SERVICE' = 'Dynamics 365 Customer Service'
    }
    
    if ($skuNames.ContainsKey($SkuPartNumber)) {
        return $skuNames[$SkuPartNumber]
    }
    else {
        return $SkuPartNumber
    }
}

# ============================================================
# CONNECTION FUNCTIONS
# ============================================================

function Connect-ToMicrosoftGraph {
    Show-SouliTEKHeader -Title "CONNECT TO MICROSOFT GRAPH" -Color Green -ClearHost -ShowBanner
    
    Write-Ui -Message "      Connect to Microsoft 365 tenant" -Level "INFO"
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Ui -Message "[Step 1/3] Installing/verifying Microsoft Graph modules..." -Level "INFO"
    Write-Host ""
    
    # Install required Microsoft Graph modules using centralized function
    $modulesToInstall = @(
        'Microsoft.Graph.Authentication',
        'Microsoft.Graph.Identity.DirectoryManagement'
    )
    
    foreach ($module in $modulesToInstall) {
        if (-not (Install-SouliTEKModule -ModuleName $module)) {
            Write-SouliTEKResult "Failed to install $module" -Level ERROR
            Write-Host ""
            Read-Host "Press Enter to return to main menu"
            return $false
        }
    }
    
    Write-Host ""
    Write-Ui -Message "[+] All Microsoft Graph modules ready" -Level "OK"
    
    Write-Host ""
    Write-Ui -Message "[Step 2/3] Checking existing connection..." -Level "INFO"
    # Check if already connected
    $context = Get-MgContext -ErrorAction SilentlyContinue
    if ($context) {
        Write-Ui -Message "          [+] Already connected to Microsoft Graph" -Level "OK"
        Write-Ui -Message "          Account: $($context.Account)" -Level "INFO"
        Write-Ui -Message "          Tenant: $($context.TenantId)" -Level "INFO"
        Write-Host ""
        $Script:Connected = $true
        Write-Host "============================================================" -ForegroundColor Green
        Write-Ui -Message "  [+] Microsoft Graph Connected Successfully" -Level "OK"
        Write-Host "============================================================" -ForegroundColor Green
        Write-Host ""
        Write-Ui -Message "[*] Returning to main menu..." -Level "INFO"
        Write-Host ""
        Start-Sleep -Seconds 2
        return $true
    }
    Write-Ui -Message "          No existing connection found" -Level "WARN"
    
    Write-Host ""
    Write-Ui -Message "[Step 3/3] Initiating connection to Microsoft Graph..." -Level "INFO"
    Write-Ui -Message "          This will open a browser window for authentication" -Level "WARN"
    Write-Ui -Message "          Required permissions:" -Level "INFO"
    Write-Ui -Message "            - Organization.Read.All (read license information)" -Level "INFO"
    Write-Host ""
    Write-Ui -Message "          Opening authentication browser window..." -Level "INFO"
    Write-Host ""
    
    try {
        # Connect with required scopes
        Connect-MgGraph -Scopes "Organization.Read.All" -ErrorAction Stop | Out-Null
        
        Write-Ui -Message "          [+] Authentication successful!" -Level "OK"
        
        $context = Get-MgContext
        
        if ($context) {
            Write-Ui -Message "          Connected as: $($context.Account)" -Level "INFO"
            Write-Ui -Message "          Tenant: $($context.TenantId)" -Level "INFO"
            Write-Host ""
            Write-Host "============================================================" -ForegroundColor Green
            Write-Ui -Message "  [+] Microsoft Graph Connected Successfully" -Level "OK"
            Write-Host "============================================================" -ForegroundColor Green
            Write-Host ""
            
            $Script:Connected = $true
            
            Write-Ui -Message "[*] Returning to main menu..." -Level "INFO"
            Write-Host ""
            Start-Sleep -Seconds 2
            return $true
        }
        else {
            Write-Host ""
            Write-Host "============================================================" -ForegroundColor Red
            Write-Ui -Message "  [-] Microsoft Graph Connection Failed" -Level "ERROR"
            Write-Host "============================================================" -ForegroundColor Red
            Write-Host ""
            Write-SouliTEKResult "Failed to establish connection" -Level ERROR
            Write-Host ""
            Read-Host "Press Enter to return to main menu"
            return $false
        }
    }
    catch {
        Write-Host ""
        Write-Host "============================================================" -ForegroundColor Red
        Write-Ui -Message "  [-] Microsoft Graph Connection Failed" -Level "ERROR"
        Write-Host "============================================================" -ForegroundColor Red
        Write-Host ""
        Write-Warning "Connection failed: $($_.Exception.Message)"
        Write-Host ""
        Write-Ui -Message "Troubleshooting steps:" -Level "WARN"
        Write-Ui -Message "  1. Check your internet connection" -Level "INFO"
        Write-Ui -Message "  2. Verify you have appropriate permissions (Global Administrator or Global Reader)" -Level "INFO"
        Write-Ui -Message "  3. Complete authentication in the browser window" -Level "INFO"
        Write-Ui -Message "  4. Try running the script again" -Level "INFO"
        Write-Host ""
        Read-Host "Press Enter to return to main menu"
        return $false
    }
}

function Disconnect-FromMicrosoftGraph {
    if ($Script:Connected) {
        try {
            Disconnect-MgGraph | Out-Null
            Write-SouliTEKResult "Disconnected from Microsoft Graph" -Level SUCCESS
            $Script:Connected = $false
        }
        catch {
            Write-SouliTEKResult "Disconnect failed: $_" -Level WARNING
        }
    }
}

function Test-GraphConnection {
    if (-not $Script:Connected) {
        Write-SouliTEKResult "Not connected to Microsoft Graph" -Level ERROR
        Write-Host ""
        Write-Ui -Message "Please connect first using option [1] from the main menu" -Level "WARN"
        Write-Host ""
        Read-Host "Press Enter to return to main menu"
        return $false
    }
    
    try {
        $null = Get-MgContext -ErrorAction Stop
        return $true
    }
    catch {
        $Script:Connected = $false
        Write-SouliTEKResult "Connection lost. Please reconnect." -Level ERROR
        Write-Host ""
        Read-Host "Press Enter to return to main menu"
        return $false
    }
}

# ============================================================
# LICENSE CHECK FUNCTIONS
# ============================================================

function Get-LicenseStatus {
    Show-SouliTEKHeader -Title "LICENSE STATUS - ALL SUBSCRIPTIONS" -Color Green -ClearHost -ShowBanner
    
    Write-Ui -Message "      Check all Microsoft 365 license subscriptions" -Level "INFO"
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    
    if (-not (Test-GraphConnection)) { return }
    
    Write-SouliTEKResult "Retrieving license subscriptions..." -Level INFO
    Write-Host ""
    
    try {
        $subscriptions = Get-MgSubscribedSku -All
        
        if ($subscriptions.Count -eq 0) {
            Write-SouliTEKResult "No subscriptions found" -Level WARNING
            Write-Host ""
            Read-Host "Press Enter to return to main menu"
            return
        }
        
        $Script:LicenseData = @()
        
        foreach ($sub in $subscriptions) {
            $skuPartNumber = $sub.SkuPartNumber
            $friendlyName = Get-FriendlySkuName -SkuPartNumber $skuPartNumber
            $enabled = $sub.PrepaidUnits.Enabled
            $consumed = $sub.ConsumedUnits
            $available = $enabled - $consumed
            $usagePercent = if ($enabled -gt 0) { [math]::Round(($consumed / $enabled) * 100, 2) } else { 0 }
            
            Write-Host "============================================================" -ForegroundColor DarkCyan
            Write-Ui -Message "LICENSE: $friendlyName" -Level "WARN"
            Write-Host "============================================================" -ForegroundColor DarkCyan
            Write-Host ""
            
            # License Information
            Write-Ui -Message "License Information:" -Level "INFO"
            Write-Ui -Message "  SKU ID: $($sub.SkuId)" -Level "INFO"
            Write-Ui -Message "  SKU Part Number: $skuPartNumber" -Level "STEP"
            Write-Ui -Message "  Friendly Name: $friendlyName" -Level "STEP"
            Write-Host ""
            
            # Seat Information
            Write-Ui -Message "Seat Allocation:" -Level "INFO"
            Write-Ui -Message "  Total Seats: $enabled" -Level "STEP"
            Write-Host "  Used Seats: $consumed" -ForegroundColor $(if ($consumed -eq $enabled) { 'Red' } elseif ($consumed -ge $enabled * 0.8) { 'Yellow' } else { 'Green' })
            Write-Host "  Available: $available" -ForegroundColor $(if ($available -eq 0) { 'Red' } elseif ($available -le 5) { 'Yellow' } else { 'Green' })
            Write-Host "  Usage: $usagePercent%" -ForegroundColor $(if ($usagePercent -ge 100) { 'Red' } elseif ($usagePercent -ge 80) { 'Yellow' } else { 'Green' })
            Write-Host ""
            
            # Expiration Status
            Write-Ui -Message "Subscription Status:" -Level "INFO"
            
            # Note: Most M365 subscriptions don't have explicit expiration dates in Get-MgSubscribedSku
            # This information is typically in billing/subscription APIs
            Write-Host "  Status: " -NoNewline
            if ($sub.CapabilityStatus -eq "Enabled") {
                Write-Ui -Message "Active" -Level "OK"
            }
            else {
                Write-Ui -Message "$($sub.CapabilityStatus)" -Level "ERROR"
            }
            
            # Store data
            $licenseInfo = [PSCustomObject]@{
                FriendlyName = $friendlyName
                SkuPartNumber = $skuPartNumber
                SkuId = $sub.SkuId
                TotalSeats = $enabled
                UsedSeats = $consumed
                AvailableSeats = $available
                UsagePercent = $usagePercent
                Status = $sub.CapabilityStatus
                AlertStatus = if ($available -eq 0) { "CRITICAL" } 
                             elseif ($available -le 5) { "WARNING" } 
                             else { "OK" }
            }
            
            $Script:LicenseData += $licenseInfo
            
            # Warnings
            if ($available -eq 0) {
                Write-Host ""
                Write-Ui -Message "  [!] WARNING: No available seats!" -Level "ERROR"
            }
            elseif ($available -le 5) {
                Write-Host ""
                Write-Ui -Message "  [!] WARNING: Low seat availability ($available remaining)" -Level "WARN"
            }
            
            Write-Host ""
        }
        
        Write-Host "============================================================" -ForegroundColor Cyan
        Write-Ui -Message "  SUMMARY" -Level "INFO"
        Write-Host "============================================================" -ForegroundColor Cyan
        Write-Host ""
        Write-Ui -Message "Total Subscriptions: $($subscriptions.Count)" -Level "STEP"
        
        $criticalLicenses = ($Script:LicenseData | Where-Object { $_.AlertStatus -eq "CRITICAL" }).Count
        $warningLicenses = ($Script:LicenseData | Where-Object { $_.AlertStatus -eq "WARNING" }).Count
        $okLicenses = ($Script:LicenseData | Where-Object { $_.AlertStatus -eq "OK" }).Count
        
        Write-Host "  Critical (No seats): " -NoNewline -ForegroundColor Red
        Write-Ui -Message $criticalLicenses -Level "ERROR"
        Write-Host "  Warning (Low seats): " -NoNewline -ForegroundColor Yellow
        Write-Ui -Message $warningLicenses -Level "WARN"
        Write-Host "  OK: " -NoNewline -ForegroundColor Green
        Write-Ui -Message $okLicenses -Level "OK"
        
        Write-Host ""
        Write-Host "============================================================" -ForegroundColor Cyan
    }
    catch {
        Write-SouliTEKResult "Failed to retrieve licenses: $_" -Level ERROR
        Write-Host ""
        Write-Ui -Message "Possible reasons:" -Level "WARN"
        Write-Ui -Message "  - Insufficient permissions (requires Organization.Read.All)" -Level "INFO"
        Write-Ui -Message "  - Connection timeout" -Level "INFO"
        Write-Ui -Message "  - API service issue" -Level "INFO"
    }
    
    Write-Host ""
    Read-Host "Press Enter to return to main menu"
}

function Get-DetailedLicenseReport {
    Show-SouliTEKHeader -Title "DETAILED LICENSE REPORT" -Color Magenta -ClearHost -ShowBanner
    
    Write-Ui -Message "      Comprehensive license analysis with service plans" -Level "INFO"
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    
    if (-not (Test-GraphConnection)) { return }
    
    Write-SouliTEKResult "Generating detailed license report..." -Level INFO
    Write-Host ""
    
    try {
        $subscriptions = Get-MgSubscribedSku -All
        
        foreach ($sub in $subscriptions) {
            $friendlyName = Get-FriendlySkuName -SkuPartNumber $sub.SkuPartNumber
            
            Write-Host "============================================================" -ForegroundColor DarkCyan
            Write-Ui -Message "DETAILED ANALYSIS: $friendlyName" -Level "WARN"
            Write-Host "============================================================" -ForegroundColor DarkCyan
            Write-Host ""
            
            # Basic Info
            Write-Ui -Message "License Details:" -Level "INFO"
            Write-Ui -Message "  Friendly Name: $friendlyName" -Level "STEP"
            Write-Ui -Message "  SKU Part Number: $($sub.SkuPartNumber)" -Level "STEP"
            Write-Ui -Message "  SKU ID: $($sub.SkuId)" -Level "INFO"
            Write-Host "  Capability Status: $($sub.CapabilityStatus)" -ForegroundColor $(if ($sub.CapabilityStatus -eq "Enabled") { 'Green' } else { 'Red' })
            Write-Host ""
            
            # Seat Details
            Write-Ui -Message "Seat Information:" -Level "INFO"
            $enabled = $sub.PrepaidUnits.Enabled
            $warning = $sub.PrepaidUnits.Warning
            $suspended = $sub.PrepaidUnits.Suspended
            $consumed = $sub.ConsumedUnits
            
            Write-Ui -Message "  Enabled: $enabled" -Level "OK"
            if ($warning -gt 0) {
                Write-Ui -Message "  Warning: $warning" -Level "WARN"
            }
            if ($suspended -gt 0) {
                Write-Ui -Message "  Suspended: $suspended" -Level "ERROR"
            }
            Write-Ui -Message "  Consumed: $consumed" -Level "STEP"
            Write-Host "  Available: $($enabled - $consumed)" -ForegroundColor $(if ($enabled - $consumed -le 0) { 'Red' } else { 'Green' })
            Write-Host ""
            
            # Service Plans
            Write-Ui -Message "Included Service Plans:" -Level "INFO"
            if ($sub.ServicePlans.Count -gt 0) {
                $enabledPlans = $sub.ServicePlans | Where-Object { $_.ProvisioningStatus -eq "Success" }
                Write-Ui -Message "  Total Plans: $($sub.ServicePlans.Count)" -Level "STEP"
                Write-Ui -Message "  Enabled: $($enabledPlans.Count)" -Level "OK"
                Write-Host ""
                
                foreach ($plan in $sub.ServicePlans | Sort-Object ServicePlanName) {
                    $statusColor = switch ($plan.ProvisioningStatus) {
                        "Success" { 'Green' }
                        "Disabled" { 'Gray' }
                        "PendingInput" { 'Yellow' }
                        default { 'Red' }
                    }
                    
                    Write-Host "  [" -NoNewline
                    Write-Host "$($plan.ProvisioningStatus.PadRight(15))" -NoNewline -ForegroundColor $statusColor
                    Write-Host "] " -NoNewline
                    Write-Ui -Message "$($plan.ServicePlanName)" -Level "STEP"
                }
            }
            else {
                Write-Ui -Message "  No service plans found" -Level "INFO"
            }
            
            Write-Host ""
        }
        
        Write-Host "============================================================" -ForegroundColor Cyan
        Write-Ui -Message "  REPORT COMPLETE" -Level "INFO"
        Write-Host "============================================================" -ForegroundColor Cyan
    }
    catch {
        Write-SouliTEKResult "Failed to generate report: $_" -Level ERROR
    }
    
    Write-Host ""
    Read-Host "Press Enter to return to main menu"
}

function Get-LicenseUsageStatistics {
    Show-SouliTEKHeader -Title "LICENSE USAGE STATISTICS" -Color Blue -ClearHost -ShowBanner
    
    Write-Ui -Message "      Analyze license allocation and usage patterns" -Level "INFO"
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    
    if (-not (Test-GraphConnection)) { return }
    
    Write-SouliTEKResult "Calculating license usage statistics..." -Level INFO
    Write-Host ""
    
    try {
        $subscriptions = Get-MgSubscribedSku -All
        
        $totalLicenses = 0
        $totalUsed = 0
        $totalAvailable = 0
        $stats = @()
        
        foreach ($sub in $subscriptions) {
            $enabled = $sub.PrepaidUnits.Enabled
            $consumed = $sub.ConsumedUnits
            $available = $enabled - $consumed
            
            $totalLicenses += $enabled
            $totalUsed += $consumed
            $totalAvailable += $available
            
            $stats += [PSCustomObject]@{
                License = Get-FriendlySkuName -SkuPartNumber $sub.SkuPartNumber
                Total = $enabled
                Used = $consumed
                Available = $available
                UsagePercent = if ($enabled -gt 0) { [math]::Round(($consumed / $enabled) * 100, 2) } else { 0 }
            }
        }
        
        Write-Host "============================================================" -ForegroundColor Cyan
        Write-Ui -Message "  OVERALL STATISTICS" -Level "INFO"
        Write-Host "============================================================" -ForegroundColor Cyan
        Write-Host ""
        Write-Ui -Message "Total License Count: $totalLicenses" -Level "STEP"
        Write-Ui -Message "Licenses Used: $totalUsed ($([math]::Round(($totalUsed / $totalLicenses) * 100, 2))%)" -Level "WARN"
        Write-Ui -Message "Licenses Available: $totalAvailable ($([math]::Round(($totalAvailable / $totalLicenses) * 100, 2))%)" -Level "OK"
        Write-Host ""
        
        Write-Host "============================================================" -ForegroundColor Cyan
        Write-Ui -Message "  TOP LICENSE CONSUMERS" -Level "INFO"
        Write-Host "============================================================" -ForegroundColor Cyan
        Write-Host ""
        
        $topConsumers = $stats | Sort-Object Used -Descending | Select-Object -First 5
        
        foreach ($stat in $topConsumers) {
            Write-Ui -Message "$($stat.License):" -Level "STEP"
            Write-Ui -Message "  Used: $($stat.Used) / $($stat.Total) ($($stat.UsagePercent)%)" -Level "WARN"
            
            # Draw usage bar
            $barLength = 40
            $filledLength = [math]::Round(($stat.UsagePercent / 100) * $barLength)
            $bar = "[" + ("#" * $filledLength).PadRight($barLength) + "]"
            
            $barColor = if ($stat.UsagePercent -ge 100) { 'Red' }
                       elseif ($stat.UsagePercent -ge 80) { 'Yellow' }
                       else { 'Green' }
            
            Write-Host "  $bar" -ForegroundColor $barColor
            Write-Host ""
        }
        
        Write-Host "============================================================" -ForegroundColor Cyan
        Write-Ui -Message "  LICENSES NEEDING ATTENTION" -Level "INFO"
        Write-Host "============================================================" -ForegroundColor Cyan
        Write-Host ""
        
        $needsAttention = $stats | Where-Object { $_.UsagePercent -ge 80 } | Sort-Object UsagePercent -Descending
        
        if ($needsAttention.Count -gt 0) {
            foreach ($stat in $needsAttention) {
                $alertLevel = if ($stat.Available -eq 0) { "CRITICAL" }
                             elseif ($stat.UsagePercent -ge 90) { "HIGH" }
                             else { "MEDIUM" }
                
                $color = switch ($alertLevel) {
                    "CRITICAL" { 'Red' }
                    "HIGH" { 'Yellow' }
                    default { 'Cyan' }
                }
                
                Write-Host "[$alertLevel] " -NoNewline -ForegroundColor $color
                Write-Ui -Message "$($stat.License) - $($stat.Available) seats remaining" -Level "STEP"
            }
        }
        else {
            Write-Ui -Message "[+] All licenses have sufficient capacity" -Level "OK"
        }
        
        Write-Host ""
        Write-Host "============================================================" -ForegroundColor Cyan
    }
    catch {
        Write-SouliTEKResult "Failed to calculate statistics: $_" -Level ERROR
    }
    
    Write-Host ""
    Read-Host "Press Enter to return to main menu"
}

function Send-ExpirationAlert {
    Show-SouliTEKHeader -Title "SEND EXPIRATION ALERT" -Color Yellow -ClearHost -ShowBanner
    
    Write-Ui -Message "      Configure and send license expiration alerts" -Level "INFO"
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    
    if ($Script:LicenseData.Count -eq 0) {
        Write-SouliTEKResult "No license data available" -Level WARNING
        Write-Host ""
        Write-Ui -Message "Please run 'License Status Check' first (option 2)" -Level "WARN"
        Write-Host ""
        Read-Host "Press Enter to return to main menu"
        return
    }
    
    Write-Ui -Message "Alert Configuration:" -Level "INFO"
    Write-Host ""
    Write-Ui -Message "  Current Alert Threshold: $Script:AlertThresholdDays days" -Level "STEP"
    Write-Ui -Message "  Current Warning Threshold: $Script:WarningThresholdDays days" -Level "STEP"
    Write-Host ""
    
    # Check for licenses needing alerts
    $criticalLicenses = $Script:LicenseData | Where-Object { $_.AlertStatus -eq "CRITICAL" }
    $warningLicenses = $Script:LicenseData | Where-Object { $_.AlertStatus -eq "WARNING" }
    
    if ($criticalLicenses.Count -eq 0 -and $warningLicenses.Count -eq 0) {
        Write-Ui -Message "[+] No licenses require immediate attention" -Level "OK"
        Write-Host ""
        Read-Host "Press Enter to return to main menu"
        return
    }
    
    Write-Ui -Message "Licenses Requiring Attention:" -Level "WARN"
    Write-Host ""
    
    if ($criticalLicenses.Count -gt 0) {
        Write-Ui -Message "CRITICAL (No Available Seats):" -Level "ERROR"
        foreach ($lic in $criticalLicenses) {
            Write-Ui -Message "  - $($lic.FriendlyName): $($lic.UsedSeats)/$($lic.TotalSeats) used" -Level "ERROR"
        }
        Write-Host ""
    }
    
    if ($warningLicenses.Count -gt 0) {
        Write-Ui -Message "WARNING (Low Availability):" -Level "WARN"
        foreach ($lic in $warningLicenses) {
            Write-Ui -Message "  - $($lic.FriendlyName): $($lic.AvailableSeats) seats remaining" -Level "WARN"
        }
        Write-Host ""
    }
    
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Ui -Message "Alert Methods:" -Level "STEP"
    Write-Host ""
    Write-Ui -Message "  [1] Email Alert" -Level "WARN"
    Write-Ui -Message "  [2] Teams Webhook Alert" -Level "WARN"
    Write-Ui -Message "  [3] Generate Alert Report" -Level "INFO"
    Write-Ui -Message "  [0] Cancel" -Level "ERROR"
    Write-Host ""
    
    $choice = Read-Host "Select alert method (0-3)"
    
    switch ($choice) {
        "1" {
            Send-EmailAlert -CriticalLicenses $criticalLicenses -WarningLicenses $warningLicenses
        }
        "2" {
            Send-TeamsAlert -CriticalLicenses $criticalLicenses -WarningLicenses $warningLicenses
        }
        "3" {
            Export-AlertReport -CriticalLicenses $criticalLicenses -WarningLicenses $warningLicenses
        }
        "0" {
            return
        }
        default {
            Write-SouliTEKResult "Invalid choice" -Level ERROR
            Start-Sleep -Seconds 2
        }
    }
    
    Write-Host ""
    Read-Host "Press Enter to return to main menu"
}

function Send-EmailAlert {
    param($CriticalLicenses, $WarningLicenses)
    
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Ui -Message "  EMAIL ALERT CONFIGURATION" -Level "INFO"
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Ui -Message "Note: This requires SMTP configuration" -Level "WARN"
    Write-Host ""
    
    $smtpServer = Read-Host "SMTP Server (e.g., smtp.office365.com)"
    $smtpPort = Read-Host "SMTP Port (default: 587)"
    if ([string]::IsNullOrWhiteSpace($smtpPort)) { $smtpPort = 587 }
    
    $from = Read-Host "From Email Address"
    $to = Read-Host "To Email Address"
    
    Write-Host ""
    Write-SouliTEKResult "Preparing email alert..." -Level INFO
    
    # Build email body
    $body = @"
<html>
<head>
    <style>
        body { font-family: Arial, sans-serif; }
        h1 { color: #d9534f; }
        h2 { color: #f0ad4e; }
        table { border-collapse: collapse; width: 100%; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #4CAF50; color: white; }
        .critical { background-color: #f8d7da; }
        .warning { background-color: #fff3cd; }
    </style>
</head>
<body>
    <h1>Microsoft 365 License Alert</h1>
    <p>Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</p>
    <p>Source: License Expiration Checker - Soulitek.co.il</p>
"@
    
    if ($CriticalLicenses.Count -gt 0) {
        $body += "<h2>CRITICAL: No Available Seats</h2>"
        $body += "<table><tr><th>License</th><th>Total</th><th>Used</th><th>Available</th></tr>"
        foreach ($lic in $CriticalLicenses) {
            $body += "<tr class='critical'><td>$($lic.FriendlyName)</td><td>$($lic.TotalSeats)</td><td>$($lic.UsedSeats)</td><td>$($lic.AvailableSeats)</td></tr>"
        }
        $body += "</table><br>"
    }
    
    if ($WarningLicenses.Count -gt 0) {
        $body += "<h2>WARNING: Low Seat Availability</h2>"
        $body += "<table><tr><th>License</th><th>Total</th><th>Used</th><th>Available</th></tr>"
        foreach ($lic in $WarningLicenses) {
            $body += "<tr class='warning'><td>$($lic.FriendlyName)</td><td>$($lic.TotalSeats)</td><td>$($lic.UsedSeats)</td><td>$($lic.AvailableSeats)</td></tr>"
        }
        $body += "</table><br>"
    }
    
    $body += @"
    <p><strong>Action Required:</strong> Please review license allocations and consider purchasing additional seats.</p>
    <hr>
    <p style="font-size: 12px; color: #666;">Generated by License Expiration Checker | Soulitek.co.il | www.soulitek.co.il</p>
</body>
</html>
"@
    
    try {
        # This is a placeholder - actual implementation would require credentials
        Write-Host ""
        Write-SouliTEKResult "Email alert prepared" -Level SUCCESS
        Write-Host ""
        Write-Ui -Message "SMTP Configuration:" -Level "INFO"
        Write-Ui -Message "  Server: $smtpServer" -Level "STEP"
        Write-Ui -Message "  Port: $smtpPort" -Level "STEP"
        Write-Ui -Message "  From: $from" -Level "STEP"
        Write-Ui -Message "  To: $to" -Level "STEP"
        Write-Host ""
        Write-Ui -Message "Note: Email sending requires authentication credentials" -Level "WARN"
        Write-Ui -Message "Use Send-MailMessage or similar cmdlet with proper credentials" -Level "WARN"
        Write-Host ""
        
        # Save email body for reference
        $emailFile = Join-Path $Script:OutputFolder "License_Alert_Email_$(Get-Date -Format 'yyyyMMdd_HHmmss').html"
        $body | Out-File -FilePath $emailFile -Encoding UTF8
        Write-SouliTEKResult "Email template saved: $emailFile" -Level SUCCESS
    }
    catch {
        Write-SouliTEKResult "Failed to prepare email: $_" -Level ERROR
    }
}

function Send-TeamsAlert {
    param($CriticalLicenses, $WarningLicenses)
    
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Ui -Message "  TEAMS WEBHOOK ALERT" -Level "INFO"
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Ui -Message "Note: This requires a Teams incoming webhook URL" -Level "WARN"
    Write-Ui -Message "Setup: Teams Channel > Connectors > Incoming Webhook" -Level "INFO"
    Write-Host ""
    
    $webhookUrl = Read-Host "Enter Teams Webhook URL"
    
    if ([string]::IsNullOrWhiteSpace($webhookUrl)) {
        Write-SouliTEKResult "No webhook URL provided" -Level WARNING
        return
    }
    
    Write-Host ""
    Write-SouliTEKResult "Preparing Teams notification..." -Level INFO
    
    # Build Teams message card
    $teamsMessage = @{
        "@type" = "MessageCard"
        "@context" = "https://schema.org/extensions"
        "summary" = "License Alert"
        "themeColor" = "FF0000"
        "title" = "Microsoft 365 License Alert"
        "sections" = @(
            @{
                "activityTitle" = "License Capacity Warning"
                "activitySubtitle" = "Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
                "facts" = @()
            }
        )
    }
    
    if ($CriticalLicenses.Count -gt 0) {
        $teamsMessage.sections[0].facts += @{
            "name" = "CRITICAL Licenses"
            "value" = "$($CriticalLicenses.Count) license(s) with no available seats"
        }
        
        foreach ($lic in $CriticalLicenses) {
            $teamsMessage.sections[0].facts += @{
                "name" = "[CRITICAL] $($lic.FriendlyName)"
                "value" = "$($lic.UsedSeats)/$($lic.TotalSeats) used - NO SEATS AVAILABLE"
            }
        }
    }
    
    if ($WarningLicenses.Count -gt 0) {
        $teamsMessage.sections[0].facts += @{
            "name" = "WARNING Licenses"
            "value" = "$($WarningLicenses.Count) license(s) with low availability"
        }
        
        foreach ($lic in $WarningLicenses) {
            $teamsMessage.sections[0].facts += @{
                "name" = "[WARNING] $($lic.FriendlyName)"
                "value" = "$($lic.AvailableSeats) seats remaining ($($lic.UsagePercent)% used)"
            }
        }
    }
    
    try {
        $jsonBody = $teamsMessage | ConvertTo-Json -Depth 10
        
        Invoke-RestMethod -Method Post -Uri $webhookUrl -Body $jsonBody -ContentType 'application/json' | Out-Null
        
        Write-Host ""
        Write-SouliTEKResult "Teams notification sent successfully" -Level SUCCESS
        Write-Host ""
    }
    catch {
        Write-SouliTEKResult "Failed to send Teams notification: $_" -Level ERROR
        Write-Host ""
        Write-Ui -Message "Possible reasons:" -Level "WARN"
        Write-Ui -Message "  - Invalid webhook URL" -Level "INFO"
        Write-Ui -Message "  - Webhook was removed or disabled" -Level "INFO"
        Write-Ui -Message "  - Network connectivity issue" -Level "INFO"
    }
}

function Export-AlertReport {
    param($CriticalLicenses, $WarningLicenses)
    
    Write-Host ""
    Write-SouliTEKResult "Generating alert report..." -Level INFO
    
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $fileName = "License_Alert_Report_$timestamp.html"
    $filePath = Join-Path $Script:OutputFolder $fileName
    
    $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>License Alert Report</title>
    <meta charset="utf-8">
    <style>
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin: 20px; background-color: #f5f5f5; }
        h1 { color: #d9534f; }
        .header { background: linear-gradient(135deg, #e74c3c 0%, #c0392b 100%); color: white; padding: 30px; border-radius: 10px; margin-bottom: 30px; }
        .section { background-color: white; padding: 20px; margin-bottom: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .critical { background-color: #f8d7da; border-left: 5px solid #d9534f; padding: 15px; margin: 10px 0; }
        .warning { background-color: #fff3cd; border-left: 5px solid #f0ad4e; padding: 15px; margin: 10px 0; }
        table { width: 100%; border-collapse: collapse; }
        th, td { border: 1px solid #ddd; padding: 12px; text-align: left; }
        th { background-color: #3498db; color: white; }
        .footer { text-align: center; margin-top: 30px; color: #7f8c8d; font-size: 12px; }
    </style>
</head>
<body>
    <div class="header">
        <h1>[ALERT] License Capacity Report</h1>
        <p><strong>Generated:</strong> $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</p>
        <p><strong>Status:</strong> Action Required</p>
    </div>
"@
    
    if ($CriticalLicenses.Count -gt 0) {
        $html += @"
    <div class="section">
        <h2 style="color: #d9534f;">CRITICAL: No Available Seats</h2>
        <p>The following licenses have reached maximum capacity:</p>
        <table>
            <tr><th>License</th><th>Total Seats</th><th>Used Seats</th><th>Available</th><th>Usage %</th></tr>
"@
        foreach ($lic in $CriticalLicenses) {
            $html += "<tr class='critical'><td>$($lic.FriendlyName)</td><td>$($lic.TotalSeats)</td><td>$($lic.UsedSeats)</td><td>$($lic.AvailableSeats)</td><td>$($lic.UsagePercent)%</td></tr>"
        }
        $html += "</table></div>"
    }
    
    if ($WarningLicenses.Count -gt 0) {
        $html += @"
    <div class="section">
        <h2 style="color: #f0ad4e;">WARNING: Low Seat Availability</h2>
        <p>The following licenses have limited capacity remaining:</p>
        <table>
            <tr><th>License</th><th>Total Seats</th><th>Used Seats</th><th>Available</th><th>Usage %</th></tr>
"@
        foreach ($lic in $WarningLicenses) {
            $html += "<tr class='warning'><td>$($lic.FriendlyName)</td><td>$($lic.TotalSeats)</td><td>$($lic.UsedSeats)</td><td>$($lic.AvailableSeats)</td><td>$($lic.UsagePercent)%</td></tr>"
        }
        $html += "</table></div>"
    }
    
    $html += @"
    <div class="section">
        <h2>Recommended Actions</h2>
        <ul>
            <li>Review current license assignments and remove unused licenses</li>
            <li>Purchase additional licenses for critical services</li>
            <li>Consider moving inactive users to lower-tier plans</li>
            <li>Set up automated alerts for license monitoring</li>
        </ul>
    </div>
    <div class="footer">
        <p>Generated by License Expiration Checker | Soulitek.co.il</p>
        <p>www.soulitek.co.il | (C) 2025 Soulitek - All Rights Reserved</p>
    </div>
</body>
</html>
"@
    
    Set-Content -Path $filePath -Value $html -Encoding UTF8
    
    Write-Host ""
    Write-SouliTEKResult "Alert report exported: $filePath" -Level SUCCESS
    Start-Sleep -Seconds 1
    Start-Process $filePath
}

function Export-LicenseReport {
    Show-SouliTEKHeader -Title "EXPORT LICENSE REPORT" -Color Yellow -ClearHost -ShowBanner
    
    Write-Ui -Message "      Save license information to file" -Level "INFO"
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    
    if ($Script:LicenseData.Count -eq 0) {
        Write-SouliTEKResult "No license data to export" -Level WARNING
        Write-Host ""
        Write-Ui -Message "Please run 'License Status Check' first (option 2)" -Level "WARN"
        Write-Host ""
        Start-Sleep -Seconds 3
        return
    }
    
    Write-Ui -Message "Total licenses to export: $($Script:LicenseData.Count)" -Level "INFO"
    Write-Host ""
    Write-Ui -Message "Select export format:" -Level "STEP"
    Write-Host ""
    Write-Ui -Message "  [1] Text File (.txt)" -Level "WARN"
    Write-Ui -Message "  [2] CSV File (.csv)" -Level "WARN"
    Write-Ui -Message "  [3] HTML Report (.html)" -Level "WARN"
    Write-Ui -Message "  [4] All Formats" -Level "INFO"
    Write-Ui -Message "  [0] Cancel" -Level "ERROR"
    Write-Host ""
    
    $choice = Read-Host "Enter your choice (0-4)"
    
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    
    try {
        switch ($choice) {
            "1" {
                Export-TextReport -Timestamp $timestamp
            }
            "2" {
                Export-CSVReport -Timestamp $timestamp
            }
            "3" {
                Export-HTMLReport -Timestamp $timestamp
            }
            "4" {
                Export-TextReport -Timestamp $timestamp
                Export-CSVReport -Timestamp $timestamp
                Export-HTMLReport -Timestamp $timestamp
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

function Export-TextReport {
    param($Timestamp)
    
    $fileName = "License_Report_$Timestamp.txt"
    $filePath = Join-Path $Script:OutputFolder $fileName
    
    $content = @()
    $content += "============================================================"
    $content += "    LICENSE STATUS REPORT - by Soulitek.co.il"
    $content += "============================================================"
    $content += ""
    $content += "Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    $content += "Tenant: $((Get-MgContext).TenantId)"
    $content += ""
    $content += "Total Subscriptions: $($Script:LicenseData.Count)"
    $content += ""
    $content += "============================================================"
    $content += ""
    
    foreach ($lic in $Script:LicenseData) {
        $content += "LICENSE: $($lic.FriendlyName)"
        $content += "------------------------------------------------------------"
        $content += "SKU Part Number   : $($lic.SkuPartNumber)"
        $content += "Total Seats       : $($lic.TotalSeats)"
        $content += "Used Seats        : $($lic.UsedSeats)"
        $content += "Available Seats   : $($lic.AvailableSeats)"
        $content += "Usage Percentage  : $($lic.UsagePercent)%"
        $content += "Status            : $($lic.Status)"
        $content += "Alert Level       : $($lic.AlertStatus)"
        $content += ""
        $content += "============================================================"
        $content += ""
    }
    
    $content += ""
    $content += "END OF REPORT"
    $content += "Generated by License Expiration Checker"
    $content += "Coded by: Soulitek.co.il"
    $content += "www.soulitek.co.il"
    
    $content | Out-File -FilePath $filePath -Encoding UTF8
    
    Write-Host ""
    Write-SouliTEKResult "Text report exported: $filePath" -Level SUCCESS
    Start-Sleep -Seconds 1
    Start-Process $filePath
}

function Export-CSVReport {
    param($Timestamp)
    
    $fileName = "License_Report_$Timestamp.csv"
    $filePath = Join-Path $Script:OutputFolder $fileName
    
    $Script:LicenseData | Export-Csv -Path $filePath -NoTypeInformation -Encoding UTF8
    
    Write-Host ""
    Write-SouliTEKResult "CSV report exported: $filePath" -Level SUCCESS
    Start-Sleep -Seconds 1
    Start-Process $filePath
}

function Export-HTMLReport {
    param($Timestamp)
    
    $fileName = "License_Report_$Timestamp.html"
    $filePath = Join-Path $Script:OutputFolder $fileName
    
    $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>License Status Report - $(Get-Date -Format 'yyyy-MM-dd')</title>
    <meta charset="utf-8">
    <style>
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin: 20px; background-color: #f5f5f5; }
        h1 { color: #2c3e50; border-bottom: 3px solid #3498db; padding-bottom: 10px; }
        .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; border-radius: 10px; margin-bottom: 30px; }
        .license { background-color: white; padding: 20px; margin-bottom: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .license-header { font-size: 20px; font-weight: bold; color: #34495e; margin-bottom: 15px; border-bottom: 2px solid #3498db; padding-bottom: 10px; }
        .info-grid { display: grid; grid-template-columns: 200px 1fr; gap: 10px; margin-top: 10px; }
        .info-label { font-weight: bold; color: #7f8c8d; }
        .status-ok { color: #27ae60; font-weight: bold; }
        .status-warning { color: #f39c12; font-weight: bold; }
        .status-critical { color: #e74c3c; font-weight: bold; }
        .usage-bar { width: 100%; height: 20px; background-color: #ecf0f1; border-radius: 10px; overflow: hidden; }
        .usage-fill { height: 100%; background-color: #3498db; transition: width 0.3s; }
        .usage-fill.high { background-color: #f39c12; }
        .usage-fill.critical { background-color: #e74c3c; }
        .footer { text-align: center; margin-top: 30px; color: #7f8c8d; font-size: 12px; }
        .summary { background-color: #3498db; color: white; padding: 20px; border-radius: 8px; margin-bottom: 20px; }
    </style>
</head>
<body>
    <div class="header">
        <h1>[LICENSE] Status Report</h1>
        <p><strong>Generated:</strong> $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</p>
        <p><strong>Tenant ID:</strong> $((Get-MgContext).TenantId)</p>
    </div>
    
    <div class="summary">
        <h2 style="margin-top:0;">Summary</h2>
        <p><strong>Total Subscriptions:</strong> $($Script:LicenseData.Count)</p>
"@
    
    $criticalCount = ($Script:LicenseData | Where-Object { $_.AlertStatus -eq "CRITICAL" }).Count
    $warningCount = ($Script:LicenseData | Where-Object { $_.AlertStatus -eq "WARNING" }).Count
    $okCount = ($Script:LicenseData | Where-Object { $_.AlertStatus -eq "OK" }).Count
    
    $html += @"
        <p><strong>Critical:</strong> $criticalCount | <strong>Warning:</strong> $warningCount | <strong>OK:</strong> $okCount</p>
    </div>
"@
    
    foreach ($lic in $Script:LicenseData | Sort-Object UsagePercent -Descending) {
        $statusClass = switch ($lic.AlertStatus) {
            "CRITICAL" { "status-critical" }
            "WARNING" { "status-warning" }
            default { "status-ok" }
        }
        
        $usageFillClass = if ($lic.UsagePercent -ge 100) { "critical" }
                         elseif ($lic.UsagePercent -ge 80) { "high" }
                         else { "" }
        
        $html += @"
    <div class="license">
        <div class="license-header">$($lic.FriendlyName)</div>
        <div class="info-grid">
            <div class="info-label">SKU Part Number:</div><div>$($lic.SkuPartNumber)</div>
            <div class="info-label">Total Seats:</div><div>$($lic.TotalSeats)</div>
            <div class="info-label">Used Seats:</div><div>$($lic.UsedSeats)</div>
            <div class="info-label">Available Seats:</div><div>$($lic.AvailableSeats)</div>
            <div class="info-label">Usage:</div><div>$($lic.UsagePercent)%</div>
            <div class="info-label">Alert Status:</div><div class="$statusClass">$($lic.AlertStatus)</div>
        </div>
        <div style="margin-top: 15px;">
            <div class="info-label">Usage Bar:</div>
            <div class="usage-bar">
                <div class="usage-fill $usageFillClass" style="width: $($lic.UsagePercent)%;"></div>
            </div>
        </div>
    </div>
"@
    }
    
    $html += @"
    <div class="footer">
        <p>Generated by License Expiration Checker | Coded by Soulitek.co.il</p>
        <p>www.soulitek.co.il | (C) 2025 Soulitek - All Rights Reserved</p>
    </div>
</body>
</html>
"@
    
    Set-Content -Path $filePath -Value $html -Encoding UTF8
    
    Write-Host ""
    Write-SouliTEKResult "HTML report exported: $filePath" -Level SUCCESS
    Start-Sleep -Seconds 1
    Start-Process $filePath
}

# ============================================================
# MAIN MENU
# ============================================================

function Show-MainMenu {
    Show-SouliTEKHeader -Title "LICENSE EXPIRATION CHECKER - Professional Tool" -Color Cyan -ClearHost -ShowBanner
    
    Write-Ui -Message "      Coded by: Soulitek.co.il" -Level "OK"
    Write-Ui -Message "      IT Solutions for your business" -Level "OK"
    Write-Ui -Message "      www.soulitek.co.il" -Level "OK"
    Write-Host ""
    Write-Ui -Message "      (C) 2025 Soulitek - All Rights Reserved" -Level "INFO"
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    
    # Connection Status
    if ($Script:Connected) {
        Write-Host "  Status: " -NoNewline
        Write-Ui -Message "CONNECTED" -Level "OK"
        $context = Get-MgContext
        if ($context) {
            Write-Ui -Message "  Tenant: $($context.TenantId)" -Level "INFO"
        }
        Write-Host ""
    }
    else {
        Write-Host "  Status: " -NoNewline
        Write-Ui -Message "NOT CONNECTED" -Level "ERROR"
        Write-Ui -Message "  Please connect first (option 1)" -Level "WARN"
        Write-Host ""
    }
    
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Ui -Message "Select an option:" -Level "STEP"
    Write-Host ""
    Write-Ui -Message "  [1] Connect to Microsoft Graph  - Authenticate" -Level "WARN"
    Write-Ui -Message "  [2] License Status Check        - View all licenses" -Level "WARN"
    Write-Ui -Message "  [3] Detailed License Report     - Service plans included" -Level "WARN"
    Write-Ui -Message "  [4] Usage Statistics            - Allocation analysis" -Level "WARN"
    Write-Ui -Message "  [5] Send Alerts                 - Email/Teams notifications" -Level "INFO"
    Write-Ui -Message "  [6] Export Report               - Save to file" -Level "INFO"
    Write-Ui -Message "  [7] Help                        - Usage guide" -Level "STEP"
    Write-Ui -Message "  [0] Exit" -Level "ERROR"
    Write-Host ""
    Write-Host "========================================" -ForegroundColor DarkGray
    
    $choice = Read-Host "Enter your choice (0-7)"
    return $choice
}

function Show-Help {
    Show-SouliTEKHeader -Title "HELP GUIDE" -Color Cyan -ClearHost -ShowBanner
    
    Write-Ui -Message "LICENSE EXPIRATION CHECKER - USAGE GUIDE" -Level "WARN"
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Ui -Message "[1] CONNECT TO MICROSOFT GRAPH" -Level "STEP"
    Write-Ui -Message "    Authenticate to your Microsoft 365 tenant" -Level "INFO"
    Write-Ui -Message "    Required: Global Admin or Global Reader permissions" -Level "INFO"
    Write-Ui -Message "    Opens browser for secure authentication" -Level "INFO"
    Write-Host ""
    Write-Ui -Message "[2] LICENSE STATUS CHECK" -Level "STEP"
    Write-Ui -Message "    Display all Microsoft 365 license subscriptions" -Level "INFO"
    Write-Ui -Message "    Shows: Total seats, used seats, available seats, usage %" -Level "INFO"
    Write-Ui -Message "    Color-coded alerts for low availability" -Level "INFO"
    Write-Host ""
    Write-Ui -Message "[3] DETAILED LICENSE REPORT" -Level "STEP"
    Write-Ui -Message "    Comprehensive analysis including service plans" -Level "INFO"
    Write-Ui -Message "    Shows all enabled services for each license" -Level "INFO"
    Write-Ui -Message "    Useful for understanding what's included" -Level "INFO"
    Write-Host ""
    Write-Ui -Message "[4] USAGE STATISTICS" -Level "STEP"
    Write-Ui -Message "    Analyze license allocation patterns" -Level "INFO"
    Write-Ui -Message "    Shows: Top consumers, licenses needing attention" -Level "INFO"
    Write-Ui -Message "    Visual usage bars and percentages" -Level "INFO"
    Write-Host ""
    Write-Ui -Message "[5] SEND ALERTS" -Level "STEP"
    Write-Ui -Message "    Configure notifications for critical licenses" -Level "INFO"
    Write-Ui -Message "    Options: Email, Teams webhook, Report file" -Level "INFO"
    Write-Ui -Message "    Automatically triggers for low/no availability" -Level "INFO"
    Write-Host ""
    Write-Ui -Message "[6] EXPORT REPORT" -Level "STEP"
    Write-Ui -Message "    Save license data to file" -Level "INFO"
    Write-Ui -Message "    Formats: Text (.txt), CSV (.csv), HTML (.html)" -Level "INFO"
    Write-Ui -Message "    Use for documentation and auditing" -Level "INFO"
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Ui -Message "UNDERSTANDING LICENSE STATUS:" -Level "WARN"
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Ui -Message "Alert Levels:" -Level "STEP"
    Write-Ui -Message "  CRITICAL - No available seats (immediate action required)" -Level "ERROR"
    Write-Ui -Message "  WARNING  - 5 or fewer seats remaining (plan to purchase)" -Level "WARN"
    Write-Ui -Message "  OK       - Sufficient seats available" -Level "OK"
    Write-Host ""
    Write-Ui -Message "Usage Percentage:" -Level "STEP"
    Write-Ui -Message "  < 80%    - Healthy allocation" -Level "OK"
    Write-Ui -Message "  80-99%   - Approaching capacity" -Level "WARN"
    Write-Ui -Message "  100%     - At maximum capacity" -Level "ERROR"
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Ui -Message "REQUIREMENTS:" -Level "WARN"
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Ui -Message "- Microsoft Graph PowerShell SDK" -Level "INFO"
    Write-Ui -Message "  Install-Module Microsoft.Graph -Scope CurrentUser" -Level "INFO"
    Write-Host ""
    Write-Ui -Message "- Permissions:" -Level "INFO"
    Write-Ui -Message "  Organization.Read.All (to read subscription data)" -Level "INFO"
    Write-Host ""
    Write-Ui -Message "- Role Requirements:" -Level "INFO"
    Write-Ui -Message "  Global Administrator or Global Reader" -Level "INFO"
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Ui -Message "TIPS:" -Level "WARN"
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Ui -Message "- Run regular checks (weekly) to monitor license usage" -Level "INFO"
    Write-Ui -Message "- Set up Teams webhooks for automated alerts" -Level "INFO"
    Write-Ui -Message "- Export reports for compliance documentation" -Level "INFO"
    Write-Ui -Message "- Review usage statistics to optimize license purchases" -Level "INFO"
    Write-Ui -Message "- Keep track of seasonal usage patterns" -Level "INFO"
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Read-Host "Press Enter to return to main menu"
}

# Show-Disclaimer function - using Show-SouliTEKDisclaimer from common module
function Show-Disclaimer {
    Show-SouliTEKDisclaimer
}

# Show-ExitMessage function - using Show-SouliTEKExitMessage from common module
function Show-ExitMessage {
    # Disconnect if connected
    Disconnect-FromMicrosoftGraph
    
    Show-SouliTEKExitMessage -ScriptPath $PSCommandPath -ToolName "SouliTEK License Expiration Checker"
}

# ============================================================
# MAIN EXECUTION
# ============================================================

# Show banner
Clear-Host
Show-ScriptBanner -ScriptName "License Expiration Checker" -Purpose "Check Microsoft 365 license expiration dates and usage"

# Show disclaimer
Show-Disclaimer

# Main menu loop
do {
    $choice = Show-MainMenu
    
    switch ($choice) {
        "1" { 
            $Script:Connected = Connect-ToMicrosoftGraph 
        }
        "2" { Get-LicenseStatus }
        "3" { Get-DetailedLicenseReport }
        "4" { Get-LicenseUsageStatistics }
        "5" { Send-ExpirationAlert }
        "6" { Export-LicenseReport }
        "7" { Show-Help }
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




