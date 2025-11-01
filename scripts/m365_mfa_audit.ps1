# ============================================================
# Microsoft 365 MFA Audit - SouliTEK Edition
# ============================================================
# Coded by: Soulitek.co.il | www.soulitek.co.il | letstalk@soulitek.co.il
# (C) 2025 SouliTEK - All Rights Reserved
# ============================================================

param(
	[switch]$EmailReport,
	[string]$To,
	[string]$From,
	[string]$SmtpServer,
	[int]$SmtpPort = 587,
	[switch]$UseSsl = $true,
	[pscredential]$Credential,
	[string]$OutputFolder = (Join-Path $env:USERPROFILE "Desktop"),
	[switch]$ScheduleWeekly,
	[ValidateSet('Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday')]
	[string]$ScheduleDay = 'Sunday',
	[string]$ScheduleTime = '06:00'
)

$Host.UI.RawUI.WindowTitle = "Microsoft 365 MFA Status"

# Set preferences to suppress prompts during module installation
$ProgressPreference = 'SilentlyContinue'
$WarningPreference = 'Continue'
$ErrorActionPreference = 'Stop'

# Import SouliTEK Common Functions
$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$CommonPath = Join-Path (Split-Path -Parent $ScriptRoot) "modules\SouliTEK-Common.ps1"
if (Test-Path $CommonPath) {
	. $CommonPath
} else {
	Write-Warning "SouliTEK Common Functions not found at: $CommonPath"
}

# Ensure NuGet provider is available (required for PowerShellGet)
$nuGetProvider = Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue
if (-not $nuGetProvider -or ($nuGetProvider.Version -lt [version]"2.8.5.201")) {
	Write-Host "Installing NuGet provider..." -ForegroundColor Cyan
	try {
		Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope CurrentUser -ErrorAction Stop | Out-Null
		Write-Host "NuGet provider installed successfully!" -ForegroundColor Green
	} catch {
		Write-Warning "Failed to install NuGet provider: $($_.Exception.Message)"
	}
}

# Ensure PowerShellGet prerequisites for module installation
if (-not (Get-Module -ListAvailable -Name PowerShellGet -ErrorAction SilentlyContinue)) {
	Write-Host "Installing PowerShellGet module..." -ForegroundColor Cyan
	try {
		Install-Module -Name PowerShellGet -Scope CurrentUser -Force -SkipPublisherCheck -ErrorAction Stop
		Write-Host "PowerShellGet installed successfully!" -ForegroundColor Green
	} catch {
		Write-Warning "Failed to install PowerShellGet: $($_.Exception.Message)"
	}
}

# Trust PSGallery for module installation
$psGallery = Get-PSRepository -Name PSGallery -ErrorAction SilentlyContinue
if ($null -eq $psGallery -or $psGallery.InstallationPolicy -ne 'Trusted') {
	Write-Host "Setting PSGallery to Trusted..." -ForegroundColor Cyan
	try {
		Set-PSRepository -Name PSGallery -InstallationPolicy Trusted -ErrorAction Stop
		Write-Host "PSGallery set to Trusted" -ForegroundColor Green
	} catch {
		Write-Warning "Failed to set PSGallery to Trusted: $($_.Exception.Message)"
	}
}

function Show-Header {
	param([string]$Title = "Microsoft 365 MFA Status", [ConsoleColor]$Color = 'Cyan')
	Clear-Host
	if (Get-Command -Name Show-SouliTEKBanner -ErrorAction SilentlyContinue) { Show-SouliTEKBanner }
	Write-Host "============================================================" -ForegroundColor $Color
	Write-Host "  $Title" -ForegroundColor $Color
	Write-Host "============================================================" -ForegroundColor $Color
	Write-Host ""
}

function Write-SummaryLine {
	param([string]$Label, [string]$Value, [ConsoleColor]$Color = 'Gray')
	$pad = 36
	Write-Host ("{0,-$pad}: {1}" -f $Label, $Value) -ForegroundColor $Color
}

function Ensure-OutputFolder {
	param([string]$Path)
	if (-not (Test-Path -Path $Path)) {
		[void](New-Item -ItemType Directory -Path $Path -Force)
	}
}

function Install-RequiredModule {
	param(
		[Parameter(Mandatory=$true)]
		[string]$ModuleName
	)
	
	Write-Host "$ModuleName module not installed." -ForegroundColor Yellow
	Write-Host "Attempting to install $ModuleName..." -ForegroundColor Cyan
	
	try {
		Install-Module -Name $ModuleName -Scope CurrentUser -Force -AllowClobber -ErrorAction Stop
		Write-Host "$ModuleName installed successfully!" -ForegroundColor Green
		return $true
	} catch {
		Write-Warning "Failed to install $ModuleName`: $($_.Exception.Message)"
		Write-Host "Please install manually: Install-Module $ModuleName -Scope CurrentUser" -ForegroundColor Yellow
		return $false
	}
}

function Connect-GraphIfAvailable {
	$connected = $false
	if (-not (Get-Module -ListAvailable -Name Microsoft.Graph -ErrorAction SilentlyContinue)) {
		Write-Host "Microsoft Graph module not installed." -ForegroundColor Yellow
		if (-not (Install-RequiredModule -ModuleName "Microsoft.Graph")) {
			return $false
		}
	}
	
	try {
		# Check if already connected
		$context = Get-MgContext -ErrorAction SilentlyContinue
		if ($context) {
			Write-Host "Already connected to Microsoft Graph" -ForegroundColor Green
			return $true
		}
		
		# Scopes for policy, users, and authentication methods
		$scopes = @('User.Read.All','Policy.Read.All','UserAuthenticationMethod.Read.All')
		Connect-MgGraph -Scopes $scopes -ErrorAction Stop | Out-Null
		$profile = (Get-MgContext).Scopes
		Write-Host "Connected to Microsoft Graph (scopes: $($profile -join ', '))" -ForegroundColor Green
		$connected = $true
	} catch {
		Write-Warning "Microsoft Graph connection failed: $($_.Exception.Message)"
	}
	return $connected
}

function Get-TenantPolicyMfaStatus {
	# Returns hasSecurityDefaults, hasAnyCaMfa, caPolicies
	$hasSecurityDefaults = $false
	$hasAnyCaMfa = $false
	$policies = @()
	if (Get-Command -Name Get-MgPolicyIdentitySecurityDefaultsEnforcementPolicy -ErrorAction SilentlyContinue) {
		try {
			$sd = Get-MgPolicyIdentitySecurityDefaultsEnforcementPolicy -ErrorAction Stop
			$hasSecurityDefaults = [bool]$sd.IsEnabled
		} catch { Write-Verbose $_ }
	}
	if (Get-Command -Name Get-MgIdentityConditionalAccessPolicy -ErrorAction SilentlyContinue) {
		try {
			$cap = Get-MgIdentityConditionalAccessPolicy -All -ErrorAction Stop
			foreach ($p in $cap) {
				$requiresMfa = $false
				# grantControls.builtInControls may include 'mfa'
				if ($p.GrantControls -and $p.GrantControls.BuiltInControls -and ($p.GrantControls.BuiltInControls -contains 'mfa')) {
					$requiresMfa = $true
				}
				$policies += [pscustomobject]@{ Name=$p.DisplayName; State=$p.State; RequiresMfa=$requiresMfa }
			}
			$hasAnyCaMfa = [bool]($policies | Where-Object {$_.RequiresMfa -and $_.State -eq 'enabled'})
		} catch { Write-Verbose $_ }
	}
	[pscustomobject]@{ SecurityDefaults=$hasSecurityDefaults; AnyCaMfa=$hasAnyCaMfa; Policies=$policies }
}

function Get-MfaUsersViaMsOnline {
	if (-not (Get-Module -ListAvailable -Name MSOnline -ErrorAction SilentlyContinue)) {
		Write-Host "MSOnline module not installed." -ForegroundColor Yellow
		if (-not (Install-RequiredModule -ModuleName "MSOnline")) {
			return $null
		}
	}
	
	try {
		# Import module if not already imported
		if (-not (Get-Module -Name MSOnline -ErrorAction SilentlyContinue)) {
			Import-Module MSOnline -ErrorAction Stop
		}
		
		# Check if already connected
		try {
			$null = Get-MsolDomain -ErrorAction Stop
			Write-Host "Already connected to MSOnline" -ForegroundColor Green
		} catch {
			Write-Host "Connecting to MSOnline..." -ForegroundColor Cyan
			Connect-MsolService -ErrorAction Stop
			Write-Host "Connected to MSOnline successfully" -ForegroundColor Green
		}
		
		Write-Host "Retrieving users from MSOnline..." -ForegroundColor Cyan
		$msolUsers = Get-MsolUser -All -ErrorAction Stop
		
		if ($null -eq $msolUsers -or $msolUsers.Count -eq 0) {
			Write-Warning "No users found via MSOnline"
			return $null
		}
		
		Write-Host "Processing $($msolUsers.Count) users..." -ForegroundColor Cyan
		$results = foreach ($u in $msolUsers) {
			$req = $u.StrongAuthenticationRequirements
			$methods = $u.StrongAuthenticationMethods
			$enforced = $false
			if ($req) {
				# State can be Enabled or Enforced
				$enforced = [bool](@($req | Where-Object { $_.State -in @('Enabled','Enforced') }).Count)
			}
			$mfaEnabled = $enforced -or ([bool]$methods -and @($methods).Count -gt 0)
			$defaultMethod = $null
			if ($methods) {
				$default = $methods | Where-Object { $_.IsDefault }
				if ($default) { $defaultMethod = $default.MethodType }
			}
			[pscustomobject]@{
				DisplayName = $u.DisplayName
				UserPrincipalName = $u.UserPrincipalName
				AccountEnabled = $u.IsLicensed -ne $false # proxy for active; MSOnline lacks AccountEnabled
				MfaEnabled = $mfaEnabled
				PerUserMfaEnforced = $enforced
				MethodCount = if ($methods) { @($methods).Count } else { 0 }
				DefaultMethod = $defaultMethod
			}
		}
		return ,$results
	} catch {
		Write-Warning "MSOnline retrieval failed: $($_.Exception.Message)"
		if ($_.Exception.Message -like "*authentication*" -or $_.Exception.Message -like "*credential*") {
			Write-Host "Tip: You may need to authenticate with Connect-MsolService" -ForegroundColor Yellow
		}
		return $null
	}
}

function Get-MfaUsersViaGraph {
	if (-not (Get-Command -Name Get-MgUser -ErrorAction SilentlyContinue)) {
		return $null
	}
	
	try {
		Write-Host "Retrieving users from Microsoft Graph..." -ForegroundColor Cyan
		$graphUsers = Get-MgUser -All -Property DisplayName,UserPrincipalName,AccountEnabled -ErrorAction Stop
		
		if ($null -eq $graphUsers -or $graphUsers.Count -eq 0) {
			Write-Warning "No users found via Microsoft Graph"
			return $null
		}
		
		Write-Host "Processing $($graphUsers.Count) users..." -ForegroundColor Cyan
		$processedCount = 0
		$results = foreach ($u in $graphUsers) {
			$processedCount++
			if ($processedCount % 10 -eq 0) {
				Write-Host "  Processed $processedCount of $($graphUsers.Count) users..." -ForegroundColor Gray
			}
			
			# Try to get authentication methods
			$mfaEnabled = $false
			$methodCount = 0
			$defaultMethod = $null
			$perUserMfaEnforced = $false
			
			try {
				# Query authentication methods endpoint for each user
				if (Get-Command -Name Get-MgUserAuthenticationMethod -ErrorAction SilentlyContinue) {
					$authMethods = Get-MgUserAuthenticationMethod -UserId $u.Id -ErrorAction SilentlyContinue
					if ($authMethods) {
						# Filter to only MFA-capable methods (phone, authenticator app, etc.)
						$mfaMethods = $authMethods | Where-Object { 
							$_.AdditionalProperties.'@odata.type' -like '*Phone*' -or
							$_.AdditionalProperties.'@odata.type' -like '*Authenticator*' -or
							$_.AdditionalProperties.'@odata.type' -like '*Fido*'
						}
						$methodCount = @($mfaMethods).Count
						$mfaEnabled = $methodCount -gt 0
						
						# Try to determine default method
						if ($mfaMethods) {
							$default = $mfaMethods | Select-Object -First 1
							$type = $default.AdditionalProperties.'@odata.type'
							if ($type) {
								$defaultMethod = $type.Replace('#microsoft.graph.', '')
							}
						}
					}
				} else {
					# Fallback: Check if user has any strong authentication requirement
					# Note: Graph doesn't expose MFA status as directly as MSOnline
					Write-Verbose "Get-MgUserAuthenticationMethod not available - MFA status may be incomplete for $($u.UserPrincipalName)"
				}
			} catch {
				# If we can't determine MFA status for this user, mark as unknown
				Write-Verbose "Could not determine MFA status for $($u.UserPrincipalName): $($_.Exception.Message)"
			}
			
			[pscustomobject]@{
				DisplayName = $u.DisplayName
				UserPrincipalName = $u.UserPrincipalName
				AccountEnabled = [bool]$u.AccountEnabled
				MfaEnabled = $mfaEnabled
				PerUserMfaEnforced = $perUserMfaEnforced
				MethodCount = $methodCount
				DefaultMethod = $defaultMethod
			}
		}
		
		Write-Host "Completed processing $processedCount users" -ForegroundColor Green
		return ,$results
	} catch {
		Write-Warning "Microsoft Graph user retrieval failed: $($_.Exception.Message)"
		return $null
	}
}

function Build-HtmlReport {
	param(
		[array]$Users,
		[pscustomobject]$TenantPolicy,
		[pscustomobject]$Stats
	)
	$style = @"
	body { font-family: Segoe UI, Arial, sans-serif; margin:20px; color:#222 }
	h1 { color:#2b6cb0 }
	.table { border-collapse: collapse; width: 100%; }
	.table th, .table td { border: 1px solid #ddd; padding: 8px; }
	.table th { background: #f3f4f6; text-align: left; }
	.badge { display:inline-block; padding:2px 8px; border-radius:12px; font-size:12px }
	.ok { background:#dcfce7; color:#166534 }
	.warn { background:#fee2e2; color:#991b1b }
	.meta { margin: 8px 0 }
"@
	$policyText = "Security Defaults: " + ($(if ($TenantPolicy.SecurityDefaults) { 'Enabled' } else { 'Disabled' })) + ", CA policies requiring MFA: " + ($(if ($TenantPolicy.AnyCaMfa) { 'Yes' } else { 'No' }))
	$policiesHtml = ($TenantPolicy.Policies | ForEach-Object { "<li>$($_.Name) - State: $($_.State) - Requires MFA: $($_.RequiresMfa)</li>" }) -join ""
	$rows = foreach ($u in $Users | Sort-Object -Property UserPrincipalName) {
		$badge = if ($u.MfaEnabled) { '<span class="badge ok">Enabled</span>' } else { '<span class="badge warn">Disabled</span>' }
		"<tr><td>$($u.DisplayName)</td><td>$($u.UserPrincipalName)</td><td>$($u.AccountEnabled)</td><td>$badge</td><td>$($u.PerUserMfaEnforced)</td><td>$($u.MethodCount)</td><td>$($u.DefaultMethod)</td></tr>"
	}
	@"
<html>
<head><meta charset="utf-8"><style>$style</style>	<title>Microsoft 365 MFA Status</title></head>
<body>
	<h1>Microsoft 365 MFA Status</h1>
	<div class="meta"><strong>Generated:</strong> $(Get-Date)</div>
	<h2>Summary</h2>
	<ul>
		<li>Total Users: $($Stats.TotalUsers)</li>
		<li>MFA Enabled: $($Stats.Enabled) ($([math]::Round($Stats.EnabledPct,2))%)</li>
		<li>MFA Disabled: $($Stats.Disabled) ($([math]::Round($Stats.DisabledPct,2))%)</li>
		<li>Unknown: $($Stats.Unknown)</li>
		<li>$policyText</li>
	</ul>
	<h3>Conditional Access Policies</h3>
	<ul>$policiesHtml</ul>
	<h2>User Details</h2>
	<table class="table">
		<thead>
			<tr><th>Display Name</th><th>UPN</th><th>Enabled</th><th>MFA</th><th>Per-User Enforced</th><th>Methods</th><th>Default Method</th></tr>
		</thead>
		<tbody>
			$($rows -join "")
		</tbody>
	</table>
</body>
</html>
"@
}

function Send-ReportEmail {
	param(
		[string]$HtmlPath,
		[string]$CsvPath
	)
	if (-not $EmailReport) { return }
	if (-not $To -or -not $From -or -not $SmtpServer -or -not $Credential) {
		throw "Email parameters missing. Provide -To, -From, -SmtpServer, -Credential"
	}
	$subject = "Microsoft 365 MFA Audit Report - $(Get-Date -Format 'yyyy-MM-dd')"
	$body = Get-Content -Path $HtmlPath -Raw
	$attachments = @()
	if (Test-Path $CsvPath) { $attachments += $CsvPath }
	Send-MailMessage -To $To -From $From -Subject $subject -Body $body -BodyAsHtml -SmtpServer $SmtpServer -Port $SmtpPort -UseSsl:$UseSsl -Credential $Credential -Attachments $attachments
	Write-Host "Email report sent to $To" -ForegroundColor Green
}

function Register-WeeklySchedule {
	if (-not $ScheduleWeekly) { return }
	$scriptPath = $MyInvocation.MyCommand.Path
	$time = [DateTime]::Parse($ScheduleTime)
	$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`" -EmailReport -To `"$To`" -From `"$From`" -SmtpServer `"$SmtpServer`" -SmtpPort $SmtpPort -UseSsl:$UseSsl -OutputFolder `"$OutputFolder`""
	$trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek $ScheduleDay -At ($time.TimeOfDay)
	$taskName = "SouliTEK - M365 MFA Audit (Weekly)"
	Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Description "Sends weekly Microsoft 365 MFA audit report" -User "$env:USERNAME" -RunLevel Highest -Force | Out-Null
	Write-Host "Scheduled weekly task '$taskName' on $ScheduleDay at $($time.ToShortTimeString())" -ForegroundColor Green
}

Show-Header

try {
	Ensure-OutputFolder -Path $OutputFolder

	$mfaUsers = $null
	$graphConnected = Connect-GraphIfAvailable
	$tenantPolicy = [pscustomobject]@{ SecurityDefaults=$false; AnyCaMfa=$false; Policies=@() }
	if ($graphConnected) {
		$tenantPolicy = Get-TenantPolicyMfaStatus
	}

	# Prefer MSOnline for per-user MFA details, fallback to Graph if needed
	$mfaUsers = Get-MfaUsersViaMsOnline
	if (-not $mfaUsers -or $mfaUsers.Count -eq 0) {
		Write-Host ""
		Write-Host "Attempting to retrieve users via Microsoft Graph as fallback..." -ForegroundColor Yellow
		if ($graphConnected) {
			$mfaUsers = Get-MfaUsersViaGraph
			if (-not $mfaUsers -or $mfaUsers.Count -eq 0) {
				Write-Warning "Unable to retrieve users from either MSOnline or Microsoft Graph."
				Write-Host ""
				Write-Host "Troubleshooting:" -ForegroundColor Yellow
				Write-Host "1. Install MSOnline module: Install-Module MSOnline -Scope CurrentUser" -ForegroundColor Cyan
				Write-Host "2. Install Microsoft Graph: Install-Module Microsoft.Graph -Scope CurrentUser" -ForegroundColor Cyan
				Write-Host "3. Ensure you have appropriate permissions (Global Admin, Global Reader, or User Administrator)" -ForegroundColor Cyan
				Write-Host ""
				$mfaUsers = @()
			}
		} else {
			Write-Warning "MSOnline failed and Microsoft Graph is not connected."
			Write-Host ""
			Write-Host "To enable fallback:" -ForegroundColor Yellow
			Write-Host "1. Install Microsoft Graph: Install-Module Microsoft.Graph -Scope CurrentUser" -ForegroundColor Cyan
			Write-Host "2. Run the script again - it will attempt to connect to Graph" -ForegroundColor Cyan
			Write-Host ""
			$mfaUsers = @()
		}
	}

	$total = $mfaUsers.Count
	$enabledCount = @($mfaUsers | Where-Object { $_.MfaEnabled }).Count
	$disabledCount = @($mfaUsers | Where-Object { -not $_.MfaEnabled }).Count
	$unknownCount = 0
	$enabledPct = if ($total -gt 0) { ($enabledCount / $total) * 100 } else { 0 }
	$disabledPct = if ($total -gt 0) { ($disabledCount / $total) * 100 } else { 0 }
	$stats = [pscustomobject]@{
		TotalUsers=$total; Enabled=$enabledCount; Disabled=$disabledCount; Unknown=$unknownCount; EnabledPct=$enabledPct; DisabledPct=$disabledPct
	}

	Write-Host "Tenant Policy Status:" -ForegroundColor Yellow
	Write-SummaryLine -Label "Security Defaults" -Value ($(if ($tenantPolicy.SecurityDefaults) { 'Enabled' } else { 'Disabled' }))
	Write-SummaryLine -Label "Conditional Access requires MFA" -Value ($(if ($tenantPolicy.AnyCaMfa) { 'Yes' } else { 'No' }))
	Write-Host "" 
	Write-Host "User MFA Summary:" -ForegroundColor Yellow
	Write-SummaryLine -Label "Total Users" -Value $stats.TotalUsers
	Write-SummaryLine -Label "MFA Enabled" -Value "$($stats.Enabled) ($([math]::Round($stats.EnabledPct,2))%)" -Color Green
	Write-SummaryLine -Label "MFA Disabled" -Value "$($stats.Disabled) ($([math]::Round($stats.DisabledPct,2))%)" -Color Red

	# Export
	$timestamp = (Get-Date -Format 'yyyyMMdd-HHmmss')
	$csvPath = Join-Path $OutputFolder "M365-MFA-Users-$timestamp.csv"
	$htmlPath = Join-Path $OutputFolder "M365-MFA-Report-$timestamp.html"
	if ($mfaUsers.Count -gt 0) { $mfaUsers | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8 }
	$html = Build-HtmlReport -Users $mfaUsers -TenantPolicy $tenantPolicy -Stats $stats
	$html | Out-File -FilePath $htmlPath -Encoding UTF8
	Write-Host "Saved CSV: $csvPath" -ForegroundColor Cyan
	Write-Host "Saved HTML: $htmlPath" -ForegroundColor Cyan

	# Email (optional)
	Send-ReportEmail -HtmlPath $htmlPath -CsvPath $csvPath

	# Schedule (optional)
	Register-WeeklySchedule

	Write-Host ""
	Write-Host "Done." -ForegroundColor Green
} catch {
	Write-Error "Failed to execute MFA audit: $($_.Exception.Message)"
	throw
}


