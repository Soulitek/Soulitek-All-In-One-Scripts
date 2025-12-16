# ============================================================
# Microsoft 365 User List - SouliTEK Edition
# ============================================================
# Coded by: Soulitek.co.il | www.soulitek.co.il | letstalk@soulitek.co.il
# (C) 2025 SouliTEK - All Rights Reserved
# ============================================================

param(
	[string]$OutputFolder = (Join-Path $env:USERPROFILE "Desktop")
)

$Host.UI.RawUI.WindowTitle = "Microsoft 365 User List"

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

# Module installation handled by centralized function from SouliTEK-Common.ps1
# Microsoft Graph modules will be installed when needed during Microsoft Graph connection

# Global variables
$Script:UserData = @()
$Script:OutputFolder = $OutputFolder
$Script:Connected = $false
$Script:TenantDomain = "Unknown"
$Script:TenantName = "Unknown"

# Show-Header function - wrapper using Show-SouliTEKHeader from common module
function Show-Header {
	param([string]$Title = "Microsoft 365 User List", [ConsoleColor]$Color = 'Cyan')
	Show-SouliTEKHeader -Title $Title -Color $Color -ClearHost -ShowBanner
}

function Write-SummaryLine {
	param([string]$Label, [string]$Value, [ConsoleColor]$Color = 'Gray')
	$pad = 30
	Write-Host ("{0,-$pad}: {1}" -f $Label, $Value) -ForegroundColor $Color
}

function Ensure-OutputFolder {
	param([string]$Path)
	if (-not (Test-Path -Path $Path)) {
		[void](New-Item -ItemType Directory -Path $Path -Force)
	}
}

# Install-RequiredModule function has been replaced by Install-SouliTEKModule from SouliTEK-Common.ps1

function Connect-ToMicrosoftGraph {
	$connected = $false
	Show-Header "Connecting to Microsoft 365"
	
	# Use centralized module installation function
	Write-Host "[Step 1/4] Installing/verifying Microsoft Graph modules..." -ForegroundColor Cyan
	Write-Host ""
	
	$modulesToInstall = @(
		'Microsoft.Graph.Authentication',
		'Microsoft.Graph.Users',
		'Microsoft.Graph.Identity.SignIns',
		'Microsoft.Graph.Identity.DirectoryManagement',
		'Microsoft.Graph.Groups',
		'Microsoft.Graph.Mail'
	)
	
	$allModulesInstalled = $true
	foreach ($module in $modulesToInstall) {
		if (-not (Install-SouliTEKModule -ModuleName $module)) {
			Write-Warning "Failed to install $module"
			$allModulesInstalled = $false
		}
	}
	
	if (-not $allModulesInstalled) {
		Write-Host ""
		Write-Host "[-] Some required modules failed to install" -ForegroundColor Red
		return $false
	}
	
	Write-Host ""
	Write-Host "[+] All Microsoft Graph modules ready" -ForegroundColor Green
	
	try {
	Write-Host ""
	Write-Host "[Step 2/4] Checking existing connection..." -ForegroundColor Cyan
	# Check if already connected
	$context = Get-MgContext -ErrorAction SilentlyContinue
	if ($context) {
		Write-Host "          [+] Already connected to Microsoft Graph" -ForegroundColor Green
		Write-Host "          Account: $($context.Account)" -ForegroundColor Gray
		Write-Host "          Tenant: $($context.TenantId)" -ForegroundColor Gray
		
		# Get organization/domain information if not already set
		if ($Script:TenantDomain -eq "Unknown") {
			try {
				$org = Get-MgOrganization -ErrorAction Stop | Select-Object -First 1
				if ($org) {
					$Script:TenantName = if ($org.DisplayName) { $org.DisplayName } else { "Unknown" }
					$Script:TenantDomain = if ($org.VerifiedDomains) { 
						($org.VerifiedDomains | Where-Object { $_.IsDefault -eq $true }).Name 
					} else { 
						"Unknown" 
					}
				}
			} catch {
				# Silent fail - not critical
			}
		}
		if ($Script:TenantDomain -ne "Unknown") {
			Write-Host "          Organization: $($Script:TenantName)" -ForegroundColor Gray
			Write-Host "          Domain: $($Script:TenantDomain)" -ForegroundColor Gray
		}
		Write-Host ""
		Write-Host "------------------------------------------------------------" -ForegroundColor Yellow
		Write-Host "Would you like to:" -ForegroundColor Yellow
		Write-Host "  1. Keep current connection" -ForegroundColor White
		Write-Host "  2. Disconnect and connect to a different tenant" -ForegroundColor White
		Write-Host ""
		Write-Host "Select option (1-2): " -NoNewline -ForegroundColor Cyan
		$reconnectChoice = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
		Write-Host $reconnectChoice.Character
		Write-Host ""
		
		if ($reconnectChoice.Character -eq '2') {
			Write-Host "Disconnecting from current tenant..." -ForegroundColor Yellow
			try {
				Disconnect-MgGraph -ErrorAction SilentlyContinue | Out-Null
				$Script:Connected = $false
				$Script:TenantDomain = "Unknown"
				$Script:TenantName = "Unknown"
				Write-Host "[+] Disconnected successfully" -ForegroundColor Green
				Write-Host ""
				# Continue to new connection below
			} catch {
				Write-Warning "Disconnect failed: $($_.Exception.Message)"
				Write-Host ""
				Write-Host "Press any key to return to menu..." -ForegroundColor Cyan
				$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
				return $false
			}
		} else {
			Write-Host "[+] Using existing connection" -ForegroundColor Green
			$Script:Connected = $true
			Write-Host ""
			Write-Host "Press any key to return to menu..." -ForegroundColor Cyan
			$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
			return $true
		}
	}
	Write-Host "          No existing connection found" -ForegroundColor Yellow
		
		Write-Host ""
		Write-Host "[Step 3/3] Initiating connection to Microsoft Graph..." -ForegroundColor Cyan
		Write-Host "          This will open a browser window for authentication" -ForegroundColor Yellow
		Write-Host "          Required permissions:" -ForegroundColor Gray
		Write-Host "            - User.Read.All (read user information)" -ForegroundColor Gray
		Write-Host "            - UserAuthenticationMethod.Read.All (read MFA status)" -ForegroundColor Gray
		Write-Host "            - Organization.Read.All (read organization info)" -ForegroundColor Gray
		Write-Host "            - Directory.Read.All (read roles and groups)" -ForegroundColor Gray
		Write-Host "            - Group.Read.All (read group memberships)" -ForegroundColor Gray
		Write-Host "            - Mail.Read (read mailbox settings)" -ForegroundColor Gray
		Write-Host "            - MailboxSettings.Read (read mailbox configuration)" -ForegroundColor Gray
		Write-Host ""
		Write-Host "          Opening authentication browser window..." -ForegroundColor Cyan
		
		# Scopes for users, authentication methods, organization, roles, groups, and mail
		$scopes = @(
			'User.Read.All',
			'UserAuthenticationMethod.Read.All',
			'Organization.Read.All',
			'Directory.Read.All',
			'Group.Read.All',
			'Mail.Read',
			'MailboxSettings.Read'
		)
		Connect-MgGraph -Scopes $scopes -ErrorAction Stop | Out-Null
		
		Write-Host "          [+] Authentication successful!" -ForegroundColor Green
		
		$context = Get-MgContext
		Write-Host "          Connected as: $($context.Account)" -ForegroundColor Gray
		Write-Host "          Tenant: $($context.TenantId)" -ForegroundColor Gray
		
		# Get organization/domain information
		Write-Host ""
		Write-Host "[Step 4/4] Retrieving organization details..." -ForegroundColor Cyan
		try {
			$org = Get-MgOrganization -ErrorAction Stop | Select-Object -First 1
			if ($org) {
				$Script:TenantName = if ($org.DisplayName) { $org.DisplayName } else { "Unknown" }
				$Script:TenantDomain = if ($org.VerifiedDomains) { 
					($org.VerifiedDomains | Where-Object { $_.IsDefault -eq $true }).Name 
				} else { 
					"Unknown" 
				}
				Write-Host "          Organization: $($Script:TenantName)" -ForegroundColor Gray
				Write-Host "          Domain: $($Script:TenantDomain)" -ForegroundColor Gray
			}
		} catch {
			Write-Warning "Could not retrieve organization details: $($_.Exception.Message)"
		}
		
		Write-Host ""
		Write-Host "============================================================" -ForegroundColor Green
		Write-Host "  [+] Microsoft Graph Connected Successfully" -ForegroundColor Green
		Write-Host "============================================================" -ForegroundColor Green
		Write-Host ""
		$Script:Connected = $true
		$connected = $true
	} catch {
		Write-Host ""
		Write-Host "============================================================" -ForegroundColor Red
		Write-Host "  [-] Microsoft Graph Connection Failed" -ForegroundColor Red
		Write-Host "============================================================" -ForegroundColor Red
		Write-Host ""
		Write-Warning "Connection failed: $($_.Exception.Message)"
		Write-Host ""
		Write-Host "Troubleshooting steps:" -ForegroundColor Yellow
		Write-Host "  1. Check your internet connection" -ForegroundColor Gray
		Write-Host "  2. Verify you have appropriate permissions (Global Administrator or Global Reader)" -ForegroundColor Gray
		Write-Host "  3. Try running the script again" -ForegroundColor Gray
		Write-Host ""
	}
	return $connected
}

function Get-UserMfaStatus {
	param([string]$UserId)
	
	$mfaInfo = @{
		Configured = $false
		Methods = @()
		MethodCount = 0
		HasAuthenticatorApp = $false
		HasSMS = $false
		HasEmailMFA = $false
		HasFIDO = $false
		LastSignIn = "Never"
		EnforcedViaCA = $false
	}
	
	try {
		$authMethods = Get-MgUserAuthenticationMethod -UserId $UserId -ErrorAction SilentlyContinue
		if ($authMethods) {
			foreach ($method in $authMethods) {
				$methodType = $method.AdditionalProperties.'@odata.type'
				if ($methodType) {
					$cleanType = $methodType.Replace('#microsoft.graph.', '')
					
					if ($cleanType -like '*phoneAuthenticationMethod*' -or $cleanType -like '*microsoftAuthenticatorAuthenticationMethod*') {
						if ($cleanType -like '*microsoftAuthenticatorAuthenticationMethod*') {
							$mfaInfo.HasAuthenticatorApp = $true
							if ($mfaInfo.Methods -notcontains "Authenticator App") {
								$mfaInfo.Methods += "Authenticator App"
							}
						} else {
							$mfaInfo.HasSMS = $true
							if ($mfaInfo.Methods -notcontains "Phone") {
								$mfaInfo.Methods += "Phone"
							}
						}
					} elseif ($cleanType -like '*emailAuthenticationMethod*') {
						$mfaInfo.HasEmailMFA = $true
						if ($mfaInfo.Methods -notcontains "Email") {
							$mfaInfo.Methods += "Email"
						}
					} elseif ($cleanType -like '*fido2AuthenticationMethod*') {
						$mfaInfo.HasFIDO = $true
						if ($mfaInfo.Methods -notcontains "FIDO Key") {
							$mfaInfo.Methods += "FIDO Key"
						}
					}
				}
			}
			
			$mfaInfo.MethodCount = $mfaInfo.Methods.Count
			$mfaInfo.Configured = $mfaInfo.MethodCount -gt 0
		}
		
		# Try to get last sign-in for MFA context
		try {
			$user = Get-MgUser -UserId $UserId -Property SignInActivity -ErrorAction SilentlyContinue
			if ($user.SignInActivity -and $user.SignInActivity.LastSignInDateTime) {
				$mfaInfo.LastSignIn = $user.SignInActivity.LastSignInDateTime.ToString("yyyy-MM-dd")
			}
		} catch {
			# Silent fail
		}
		
		# Check Conditional Access enforcement (requires additional API call)
		# Note: This is a simplified check - full CA policy evaluation requires more complex logic
		try {
			$userRisk = Get-MgUserRiskDetection -Filter "userId eq '$UserId'" -Top 1 -ErrorAction SilentlyContinue
			# If we can't easily determine CA, we'll mark as unknown
			# In production, you'd query CA policies directly
		} catch {
			# Silent fail - CA enforcement detection is complex
		}
		
	} catch {
		# Silent fail - MFA status may not be available
	}
	
	return $mfaInfo
}

function Get-UserPhoneNumber {
	param([object]$User)
	
	$phone = "Not Set"
	if ($User.BusinessPhones -and $User.BusinessPhones.Count -gt 0) {
		$phone = $User.BusinessPhones[0]
	} elseif ($User.MobilePhone) {
		$phone = $User.MobilePhone
	}
	
	return $phone
}

function Get-UserLicenses {
	param([object]$User)
	
	$licenseNames = @()
	if ($User.AssignedLicenses -and $User.AssignedLicenses.Count -gt 0) {
		try {
			# Get all subscribed SKUs to map IDs to names
			$subscribedSkus = Get-MgSubscribedSku -ErrorAction SilentlyContinue
			foreach ($license in $User.AssignedLicenses) {
				$sku = $subscribedSkus | Where-Object { $_.SkuId -eq $license.SkuId } | Select-Object -First 1
				if ($sku) {
					$licenseNames += $sku.SkuPartNumber
				} else {
					$licenseNames += "Unknown ($($license.SkuId))"
				}
			}
		} catch {
			# Fallback to count if SKU lookup fails
			$licenseNames = @("$($User.AssignedLicenses.Count) license(s)")
		}
	}
	
	if ($licenseNames.Count -eq 0) {
		return @()
	}
	return $licenseNames
}

function Get-UserRoles {
	param([string]$UserId)
	
	$roles = @()
	try {
		$directoryRoles = Get-MgDirectoryRole -All -ErrorAction SilentlyContinue
		foreach ($role in $directoryRoles) {
			$members = Get-MgDirectoryRoleMember -DirectoryRoleId $role.Id -ErrorAction SilentlyContinue
			$userMember = $members | Where-Object { $_.Id -eq $UserId } | Select-Object -First 1
			if ($userMember) {
				$roles += $role.DisplayName
			}
		}
	} catch {
		# Silent fail - roles may not be available
	}
	
	return $roles
}

function Get-UserGroups {
	param([string]$UserId)
	
	$groups = @()
	try {
		$userGroups = Get-MgUserMemberOf -UserId $UserId -ErrorAction SilentlyContinue
		foreach ($groupRef in $userGroups) {
			try {
				$group = Get-MgGroup -GroupId $groupRef.Id -Property DisplayName,GroupTypes -ErrorAction SilentlyContinue
				if ($group) {
					$groups += $group.DisplayName
				}
			} catch {
				# Skip if group can't be retrieved
			}
		}
	} catch {
		# Silent fail - groups may not be available
	}
	
	return $groups
}

function Get-UserMailboxInfo {
	param([string]$UserId)
	
	$mailboxInfo = @{
		HasMailbox = $false
		ForwardingEnabled = $false
		ExternalForwarding = $false
		ForwardingAddress = "None"
		MailboxSize = "Unknown"
		MailboxQuota = "Unknown"
		LitigationHold = $false
		RetentionEnabled = $false
	}
	
	try {
		# Check if user has mailbox
		$mailbox = Get-MgUserMailboxSetting -UserId $UserId -ErrorAction SilentlyContinue
		if ($mailbox) {
			$mailboxInfo.HasMailbox = $true
			
			# Check forwarding
			if ($mailbox.ForwardingAddress) {
				$mailboxInfo.ForwardingEnabled = $true
				$mailboxInfo.ForwardingAddress = $mailbox.ForwardingAddress
				# Try to determine if external
				try {
					$forwardUser = Get-MgUser -UserId $mailbox.ForwardingAddress -ErrorAction SilentlyContinue
					if (-not $forwardUser) {
						$mailboxInfo.ExternalForwarding = $true
					}
				} catch {
					$mailboxInfo.ExternalForwarding = $true
				}
			}
		}
		
		# Get mailbox size (requires Exchange Online PowerShell or Graph API with different permissions)
		# This is a simplified version - full implementation may require Exchange Online module
		try {
			$user = Get-MgUser -UserId $UserId -Property MailboxSettings -ErrorAction SilentlyContinue
			if ($user.MailboxSettings) {
				# Mailbox settings available
			}
		} catch {
			# Silent fail
		}
		
		# Litigation hold and retention require Exchange Online or additional Graph permissions
		# These are marked as false/unknown in this implementation
		
	} catch {
		# Silent fail - mailbox info may not be available
	}
	
	return $mailboxInfo
}

function Disconnect-FromMicrosoftGraph {
	Show-Header "Disconnect from Microsoft 365"
	
	if (-not $Script:Connected) {
		Write-Host "Not currently connected to Microsoft Graph." -ForegroundColor Yellow
		Write-Host ""
		Write-Host "Press any key to return to menu..." -ForegroundColor Cyan
		$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
		return
	}
	
	Write-Host "Current connection:" -ForegroundColor Cyan
	Write-Host ""
	if ($Script:TenantDomain -ne "Unknown") {
		Write-Host "  Organization: $($Script:TenantName)" -ForegroundColor Gray
		Write-Host "  Domain: $($Script:TenantDomain)" -ForegroundColor Gray
	}
	$context = Get-MgContext -ErrorAction SilentlyContinue
	if ($context) {
		Write-Host "  Account: $($context.Account)" -ForegroundColor Gray
		Write-Host "  Tenant: $($context.TenantId)" -ForegroundColor Gray
	}
	Write-Host ""
	Write-Host "------------------------------------------------------------" -ForegroundColor Yellow
	Write-Host "Are you sure you want to disconnect? (Y/N): " -NoNewline -ForegroundColor Yellow
	$confirm = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
	Write-Host $confirm.Character
	Write-Host ""
	
	if ($confirm.Character -eq 'Y' -or $confirm.Character -eq 'y') {
		try {
			Write-Host "Disconnecting from Microsoft Graph..." -ForegroundColor Cyan
			Disconnect-MgGraph -ErrorAction Stop | Out-Null
			$Script:Connected = $false
			$Script:TenantDomain = "Unknown"
			$Script:TenantName = "Unknown"
			$Script:UserData = @()
			Write-Host ""
			Write-Host "============================================================" -ForegroundColor Green
			Write-Host "  [+] Disconnected Successfully" -ForegroundColor Green
			Write-Host "============================================================" -ForegroundColor Green
			Write-Host ""
			Write-Host "User data has been cleared." -ForegroundColor Gray
			Write-Host ""
		} catch {
			Write-Host ""
			Write-Host "============================================================" -ForegroundColor Red
			Write-Host "  [-] Disconnect Failed" -ForegroundColor Red
			Write-Host "============================================================" -ForegroundColor Red
			Write-Host ""
			Write-Warning "Disconnect failed: $($_.Exception.Message)"
			Write-Host ""
		}
	} else {
		Write-Host "Disconnect cancelled." -ForegroundColor Yellow
		Write-Host ""
	}
	
	Write-Host "Press any key to return to menu..." -ForegroundColor Cyan
	$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Get-AllUsers {
	Show-Header "Retrieving Microsoft 365 Users"
	
	if (-not $Script:Connected) {
		Write-Host "Not connected to Microsoft Graph. Please connect first." -ForegroundColor Red
		Write-Host ""
		Write-Host "Press any key to return to menu..." -ForegroundColor Cyan
		$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
		return
	}
	
	try {
		Write-Host "Retrieving all users from Microsoft 365..." -ForegroundColor Cyan
		Write-Host "This may take a few moments depending on the number of users..." -ForegroundColor Gray
		Write-Host ""
		
		$allUsers = Get-MgUser -All -Property DisplayName,UserPrincipalName,Mail,JobTitle,Department,OfficeLocation,AccountEnabled,CompanyName,BusinessPhones,MobilePhone,AssignedLicenses,LastSignInDateTime,CreatedDateTime -ErrorAction Stop
		
		if (-not $allUsers -or $allUsers.Count -eq 0) {
			Write-Host "No users found in the tenant." -ForegroundColor Yellow
			Write-Host ""
			Write-Host "Press any key to return to menu..." -ForegroundColor Cyan
			$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
			return
		}
		
		Write-Host "Found $($allUsers.Count) user(s). Processing user details..." -ForegroundColor Green
		Write-Host ""
		
		$Script:UserData = @()
		$processedCount = 0
		
		foreach ($user in $allUsers) {
			$processedCount++
			Write-Progress -Activity "Processing Users" -Status "User $processedCount of $($allUsers.Count): $($user.DisplayName)" -PercentComplete (($processedCount / $allUsers.Count) * 100)
			
			# Get MFA status (enhanced)
			$mfaStatus = Get-UserMfaStatus -UserId $user.Id
			
			# Get phone number
			$phoneNumber = Get-UserPhoneNumber -User $user
			
			# Get licenses (array format)
			$licenses = Get-UserLicenses -User $user
			
			# Get roles
			$roles = Get-UserRoles -UserId $user.Id
			
			# Get groups
			$groups = Get-UserGroups -UserId $user.Id
			
			# Get mailbox info
			$mailboxInfo = Get-UserMailboxInfo -UserId $user.Id
			
			# Format last sign-in
			$lastSignIn = "Never"
			if ($user.LastSignInDateTime) {
				$lastSignIn = $user.LastSignInDateTime.ToString("yyyy-MM-dd HH:mm:ss")
			} elseif ($mfaStatus.LastSignIn -ne "Never") {
				$lastSignIn = $mfaStatus.LastSignIn
			}
			
			# Format created date
			$createdDate = "Unknown"
			if ($user.CreatedDateTime) {
				$createdDate = $user.CreatedDateTime.ToString("yyyy-MM-dd")
			}
			
			# Determine account status
			$accountStatus = "Enabled"
			if (-not $user.AccountEnabled) {
				$accountStatus = "Disabled"
			}
			# Check for blocked sign-in (simplified - would need additional API call for full check)
			
			$Script:UserData += [PSCustomObject]@{
				UserPrincipalName = $user.UserPrincipalName
				DisplayName = $user.DisplayName
				EmailAddress = $user.UserPrincipalName
				PrimaryEmail = if ($user.Mail) { $user.Mail } else { $user.UserPrincipalName }
				PhoneNumber = $phoneNumber
				JobTitle = if ($user.JobTitle) { $user.JobTitle } else { "Not Set" }
				Department = if ($user.Department) { $user.Department } else { "Not Set" }
				OfficeLocation = if ($user.OfficeLocation) { $user.OfficeLocation } else { "Not Set" }
				CompanyName = if ($user.CompanyName) { $user.CompanyName } else { "Not Set" }
				AccountEnabled = $user.AccountEnabled
				AccountStatus = $accountStatus
				Licenses = $licenses
				LicensesCount = $licenses.Count
				Roles = $roles
				RolesCount = $roles.Count
				Groups = $groups
				GroupsCount = $groups.Count
				MfaConfigured = $mfaStatus.Configured
				MfaMethods = $mfaStatus.Methods
				MfaMethodCount = $mfaStatus.MethodCount
				MfaHasAuthenticatorApp = $mfaStatus.HasAuthenticatorApp
				MfaHasSMS = $mfaStatus.HasSMS
				MfaHasEmailMFA = $mfaStatus.HasEmailMFA
				MfaHasFIDO = $mfaStatus.HasFIDO
				MfaEnforcedViaCA = $mfaStatus.EnforcedViaCA
				MfaLastSignIn = $mfaStatus.LastSignIn
				MailboxHasMailbox = $mailboxInfo.HasMailbox
				MailboxForwardingEnabled = $mailboxInfo.ForwardingEnabled
				MailboxExternalForwarding = $mailboxInfo.ExternalForwarding
				MailboxForwardingAddress = $mailboxInfo.ForwardingAddress
				MailboxSize = $mailboxInfo.MailboxSize
				MailboxQuota = $mailboxInfo.MailboxQuota
				MailboxLitigationHold = $mailboxInfo.LitigationHold
				MailboxRetentionEnabled = $mailboxInfo.RetentionEnabled
				LastSignIn = $lastSignIn
				CreatedDate = $createdDate
			}
		}
		
		Write-Progress -Activity "Processing Users" -Completed
		
		Write-Host "============================================================" -ForegroundColor Green
		Write-Host "  [+] Successfully retrieved $($Script:UserData.Count) users" -ForegroundColor Green
		Write-Host "============================================================" -ForegroundColor Green
		Write-Host ""
		
	} catch {
		Write-Host ""
		Write-Host "============================================================" -ForegroundColor Red
		Write-Host "  [-] Error retrieving users" -ForegroundColor Red
		Write-Host "============================================================" -ForegroundColor Red
		Write-Host ""
		Write-Warning "Error: $($_.Exception.Message)"
		Write-Host ""
		Write-Host "Press any key to return to menu..." -ForegroundColor Cyan
		$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
	}
}

function Show-UserSummary {
	Show-Header "User Summary"
	
	if ($Script:UserData.Count -eq 0) {
		Write-Host "No user data available. Please retrieve users first." -ForegroundColor Yellow
		Write-Host ""
		Write-Host "Press any key to return to menu..." -ForegroundColor Cyan
		$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
		return
	}
	
	$enabledUsers = ($Script:UserData | Where-Object { $_.AccountEnabled -eq $true }).Count
	$disabledUsers = ($Script:UserData | Where-Object { $_.AccountEnabled -eq $false }).Count
	$mfaEnabledUsers = ($Script:UserData | Where-Object { $_.MfaConfigured -eq $true }).Count
	$mfaDisabledUsers = ($Script:UserData | Where-Object { $_.MfaConfigured -eq $false }).Count
	$mfaEnabledPct = if ($Script:UserData.Count -gt 0) { [math]::Round(($mfaEnabledUsers / $Script:UserData.Count) * 100, 2) } else { 0 }
	
	Write-Host "SUMMARY STATISTICS" -ForegroundColor Cyan
	Write-Host "------------------------------------------------------------" -ForegroundColor Gray
	Write-Host ""
	if ($Script:TenantDomain -ne "Unknown") {
		Write-SummaryLine "Organization" $Script:TenantName "Cyan"
		Write-SummaryLine "Domain" $Script:TenantDomain "Cyan"
		Write-Host ""
	}
	Write-SummaryLine "Total Users" $Script:UserData.Count "White"
	Write-SummaryLine "Enabled Accounts" "$enabledUsers ($([math]::Round(($enabledUsers / $Script:UserData.Count) * 100, 2))%)" "Green"
	Write-SummaryLine "Disabled Accounts" "$disabledUsers ($([math]::Round(($disabledUsers / $Script:UserData.Count) * 100, 2))%)" "Yellow"
	Write-Host ""
	Write-SummaryLine "MFA Enabled" "$mfaEnabledUsers ($mfaEnabledPct%)" "Green"
	Write-SummaryLine "MFA Disabled" "$mfaDisabledUsers ($([math]::Round(($mfaDisabledUsers / $Script:UserData.Count) * 100, 2))%)" "Red"
	Write-Host ""
	Write-Host "TOP 10 USERS (by Display Name)" -ForegroundColor Cyan
	Write-Host "------------------------------------------------------------" -ForegroundColor Gray
	Write-Host ""
	
	$topUsers = $Script:UserData | Sort-Object DisplayName | Select-Object -First 10
	foreach ($user in $topUsers) {
		$mfaStatus = if ($user.MfaConfigured) { "Enabled ($($user.MfaMethodCount) methods)" } else { "Disabled" }
		$mfaColor = if ($user.MfaConfigured) { "Green" } else { "Red" }
		$accountStatus = $user.AccountStatus
		$rolesCount = if ($user.RolesCount -gt 0) { " ($($user.RolesCount) roles)" } else { "" }
		$groupsCount = if ($user.GroupsCount -gt 0) { " ($($user.GroupsCount) groups)" } else { "" }
		
		Write-Host "  $($user.DisplayName)" -ForegroundColor White
		Write-Host "    Email: $($user.EmailAddress)" -ForegroundColor Gray
		Write-Host "    Phone: $($user.PhoneNumber)" -ForegroundColor Gray
		Write-Host "    Status: $accountStatus | MFA: " -NoNewline -ForegroundColor Gray
		Write-Host "$mfaStatus" -ForegroundColor $mfaColor
		if ($user.RolesCount -gt 0) {
			Write-Host "    Roles: $($user.Roles -join ', ')" -ForegroundColor Cyan
		}
		if ($user.GroupsCount -gt 0) {
			Write-Host "    Groups: $($user.GroupsCount) groups" -ForegroundColor Cyan
		}
		if ($user.LicensesCount -gt 0) {
			Write-Host "    Licenses: $($user.LicensesCount) assigned" -ForegroundColor Yellow
		}
		Write-Host ""
	}
	
	if ($Script:UserData.Count -gt 10) {
		Write-Host "  ... and $($Script:UserData.Count - 10) more users" -ForegroundColor Gray
		Write-Host ""
	}
	
	Write-Host "Press any key to return to menu..." -ForegroundColor Cyan
	$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Export-UserListTxt {
	if ($Script:UserData.Count -eq 0) {
		Write-Host "No user data available. Please retrieve users first." -ForegroundColor Yellow
		Write-Host ""
		Write-Host "Press any key to return to menu..." -ForegroundColor Cyan
		$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
		return
	}
	
	Show-Header "Export User List - TXT Format"
	
	Ensure-OutputFolder -Path $Script:OutputFolder
	$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
	$fileName = "M365_User_List_$timestamp.txt"
	$filePath = Join-Path $Script:OutputFolder $fileName
	
	try {
		$output = @()
		$output += "============================================================"
		$output += "Microsoft 365 User List Report"
		$output += "Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
		if ($Script:TenantDomain -ne "Unknown") {
			$output += "Organization: $($Script:TenantName)"
			$output += "Domain: $($Script:TenantDomain)"
		}
		$output += "Total Users: $($Script:UserData.Count)"
		$output += "============================================================"
		$output += ""
		$output += "SouliTEK - IT Solutions for your business"
		$output += "www.soulitek.co.il | letstalk@soulitek.co.il"
		$output += ""
		$output += "============================================================"
		$output += ""
		
		foreach ($user in $Script:UserData | Sort-Object DisplayName) {
			$output += "Display Name: $($user.DisplayName)"
			$output += "Email Address: $($user.EmailAddress)"
			$output += "Primary Email: $($user.PrimaryEmail)"
			$output += "Phone Number: $($user.PhoneNumber)"
			$output += "Job Title: $($user.JobTitle)"
			$output += "Department: $($user.Department)"
			$output += "Office Location: $($user.OfficeLocation)"
			$output += "Company Name: $($user.CompanyName)"
			$output += "Account Enabled: $($user.AccountEnabled)"
			$output += "MFA Configured: $($user.MfaConfigured)"
			$output += "MFA Methods: $($user.MfaMethods -join ', ')"
			$output += "MFA Methods: $($user.MfaMethodCount)"
			$output += "MFA Default Method: $($user.MfaDefaultMethod)"
			$output += "Licenses: $($user.Licenses)"
			$output += "Last Sign-In: $($user.LastSignIn)"
			$output += "Created Date: $($user.CreatedDate)"
			$output += "------------------------------------------------------------"
			$output += ""
		}
		
		$output | Out-File -FilePath $filePath -Encoding UTF8 -Force
		
		Write-Host "Export completed successfully!" -ForegroundColor Green
		Write-Host ""
		Write-Host "File saved to:" -ForegroundColor Cyan
		Write-Host $filePath -ForegroundColor White
		Write-Host ""
		Write-Host "Total users exported: $($Script:UserData.Count)" -ForegroundColor Green
		Write-Host ""
		
		Write-Host "Opening file..." -ForegroundColor Yellow
		Start-Sleep -Seconds 1
		Start-Process $filePath
		
	} catch {
		Write-Host "Export failed: $($_.Exception.Message)" -ForegroundColor Red
		Write-Host ""
	}
	
	Write-Host "Press any key to return to menu..." -ForegroundColor Cyan
	$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Export-UserListCsv {
	if ($Script:UserData.Count -eq 0) {
		Write-Host "No user data available. Please retrieve users first." -ForegroundColor Yellow
		Write-Host ""
		Write-Host "Press any key to return to menu..." -ForegroundColor Cyan
		$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
		return
	}
	
	Show-Header "Export User List - CSV Format"
	
	Ensure-OutputFolder -Path $Script:OutputFolder
	$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
	$fileName = "M365_User_List_$timestamp.csv"
	$filePath = Join-Path $Script:OutputFolder $fileName
	
	try {
		$Script:UserData | Sort-Object DisplayName | Export-Csv -Path $filePath -NoTypeInformation -Encoding UTF8 -Force
		
		Write-Host "Export completed successfully!" -ForegroundColor Green
		Write-Host ""
		Write-Host "File saved to:" -ForegroundColor Cyan
		Write-Host $filePath -ForegroundColor White
		Write-Host ""
		Write-Host "Total users exported: $($Script:UserData.Count)" -ForegroundColor Green
		Write-Host ""
		Write-Host "This file can be opened in:" -ForegroundColor Yellow
		Write-Host "  - Microsoft Excel" -ForegroundColor Gray
		Write-Host "  - Google Sheets" -ForegroundColor Gray
		Write-Host "  - Any spreadsheet program" -ForegroundColor Gray
		Write-Host ""
		
		Write-Host "Opening file..." -ForegroundColor Yellow
		Start-Sleep -Seconds 1
		Start-Process $filePath
		
	} catch {
		Write-Host "Export failed: $($_.Exception.Message)" -ForegroundColor Red
		Write-Host ""
	}
	
	Write-Host "Press any key to return to menu..." -ForegroundColor Cyan
	$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Export-UserListHtml {
	if ($Script:UserData.Count -eq 0) {
		Write-Host "No user data available. Please retrieve users first." -ForegroundColor Yellow
		Write-Host ""
		Write-Host "Press any key to return to menu..." -ForegroundColor Cyan
		$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
		return
	}
	
	Show-Header "Export User List - HTML Format"
	
	Ensure-OutputFolder -Path $Script:OutputFolder
	$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
	$fileName = "M365_User_List_$timestamp.html"
	$filePath = Join-Path $Script:OutputFolder $fileName
	
	try {
		$enabledUsers = ($Script:UserData | Where-Object { $_.AccountEnabled -eq $true }).Count
		$disabledUsers = ($Script:UserData | Where-Object { $_.AccountEnabled -eq $false }).Count
		$mfaEnabledUsers = ($Script:UserData | Where-Object { $_.MfaEnabled -eq $true }).Count
		$mfaDisabledUsers = ($Script:UserData | Where-Object { $_.MfaEnabled -eq $false }).Count
		$mfaEnabledPct = if ($Script:UserData.Count -gt 0) { [math]::Round(($mfaEnabledUsers / $Script:UserData.Count) * 100, 2) } else { 0 }
		
		$style = @"
<style>
body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin: 20px; background-color: #f5f5f5; color: #222; }
.container { max-width: 1400px; margin: 0 auto; background: white; padding: 30px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
h1 { color: #2b6cb0; border-bottom: 3px solid #2b6cb0; padding-bottom: 10px; }
h2 { color: #4a5568; margin-top: 30px; }
.stats { display: flex; gap: 20px; margin: 20px 0; flex-wrap: wrap; }
.stat-box { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 20px; border-radius: 8px; flex: 1; min-width: 200px; box-shadow: 0 2px 4px rgba(0,0,0,0.2); }
.stat-box h3 { margin: 0 0 10px 0; font-size: 14px; text-transform: uppercase; opacity: 0.9; }
.stat-box .number { font-size: 36px; font-weight: bold; margin: 0; }
.table { width: 100%; border-collapse: collapse; margin-top: 20px; }
.table th { background: #2b6cb0; color: white; padding: 12px; text-align: left; font-weight: 600; }
.table td { padding: 10px 12px; border-bottom: 1px solid #e2e8f0; }
.table tr:nth-child(even) { background-color: #f8f9fa; }
.table tr:hover { background-color: #e6f3ff; }
.badge { display: inline-block; padding: 4px 12px; border-radius: 12px; font-size: 12px; font-weight: 600; }
.badge-enabled { background: #dcfce7; color: #166534; }
.badge-disabled { background: #fee2e2; color: #991b1b; }
.badge-mfa { background: #dbeafe; color: #1e40af; }
.meta { margin: 20px 0; padding: 15px; background: #f8f9fa; border-left: 4px solid #2b6cb0; border-radius: 4px; }
.footer { margin-top: 40px; padding-top: 20px; border-top: 2px solid #e2e8f0; text-align: center; color: #718096; font-size: 12px; }
</style>
"@
		
		$statsHtml = @"
<div class="stats">
	<div class="stat-box">
		<h3>Total Users</h3>
		<p class="number">$($Script:UserData.Count)</p>
	</div>
	<div class="stat-box" style="background: linear-gradient(135deg, #10b981 0%, #059669 100%);">
		<h3>Enabled Accounts</h3>
		<p class="number">$enabledUsers</p>
	</div>
	<div class="stat-box" style="background: linear-gradient(135deg, #f59e0b 0%, #d97706 100%);">
		<h3>Disabled Accounts</h3>
		<p class="number">$disabledUsers</p>
	</div>
	<div class="stat-box" style="background: linear-gradient(135deg, #3b82f6 0%, #2563eb 100%);">
		<h3>MFA Enabled</h3>
		<p class="number">$mfaEnabledUsers ($mfaEnabledPct%)</p>
	</div>
</div>
"@
		
		$rows = foreach ($user in $Script:UserData | Sort-Object DisplayName) {
			$accountBadge = if ($user.AccountEnabled) { '<span class="badge badge-enabled">Enabled</span>' } else { '<span class="badge badge-disabled">Disabled</span>' }
			$mfaBadge = if ($user.MfaConfigured) { '<span class="badge badge-mfa">Enabled</span>' } else { '<span class="badge badge-disabled">Disabled</span>' }
			
			@"
<tr>
	<td>$($user.DisplayName)</td>
	<td>$($user.EmailAddress)</td>
	<td>$($user.PrimaryEmail)</td>
	<td>$($user.PhoneNumber)</td>
	<td>$($user.JobTitle)</td>
	<td>$($user.Department)</td>
	<td>$($user.OfficeLocation)</td>
	<td>$($user.CompanyName)</td>
	<td>$accountBadge</td>
	<td>$mfaBadge</td>
	<td>$($user.MfaMethodCount)</td>
	<td>$($user.MfaDefaultMethod)</td>
	<td>$($user.Licenses)</td>
	<td>$($user.LastSignIn)</td>
	<td>$($user.CreatedDate)</td>
</tr>
"@
		}
		
		$html = @"
<!DOCTYPE html>
<html>
<head>
	<meta charset="utf-8">
	<title>Microsoft 365 User List Report</title>
	$style
</head>
<body>
	<div class="container">
		<h1>Microsoft 365 User List Report</h1>
		<div class="meta">
			<strong>Generated:</strong> $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')<br>
			$(if ($Script:TenantDomain -ne "Unknown") { "<strong>Organization:</strong> $($Script:TenantName)<br><strong>Domain:</strong> $($Script:TenantDomain)<br>" })
			<strong>Total Users:</strong> $($Script:UserData.Count)
		</div>
		$statsHtml
		<h2>User Details</h2>
		<table class="table">
			<thead>
				<tr>
					<th>Display Name</th>
					<th>Email Address</th>
					<th>Primary Email</th>
					<th>Phone Number</th>
					<th>Job Title</th>
					<th>Department</th>
					<th>Office Location</th>
					<th>Company Name</th>
					<th>Account Status</th>
					<th>MFA Status</th>
					<th>MFA Methods</th>
					<th>MFA Default Method</th>
					<th>Licenses</th>
					<th>Last Sign-In</th>
					<th>Created Date</th>
				</tr>
			</thead>
			<tbody>
				$($rows -join "`n")
			</tbody>
		</table>
		<div class="footer">
			<p>Generated by SouliTEK - IT Solutions for your business</p>
			<p>www.soulitek.co.il | letstalk@soulitek.co.il</p>
			<p>(C) 2025 SouliTEK - All Rights Reserved</p>
		</div>
	</div>
</body>
</html>
"@
		
		$html | Out-File -FilePath $filePath -Encoding UTF8 -Force
		
		Write-Host "Export completed successfully!" -ForegroundColor Green
		Write-Host ""
		Write-Host "File saved to:" -ForegroundColor Cyan
		Write-Host $filePath -ForegroundColor White
		Write-Host ""
		Write-Host "Total users exported: $($Script:UserData.Count)" -ForegroundColor Green
		Write-Host ""
		
		Write-Host "Opening file in browser..." -ForegroundColor Yellow
		Start-Sleep -Seconds 1
		Start-Process $filePath
		
	} catch {
		Write-Host "Export failed: $($_.Exception.Message)" -ForegroundColor Red
		Write-Host ""
	}
	
	Write-Host "Press any key to return to menu..." -ForegroundColor Cyan
	$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Export-UserListJson {
	if ($Script:UserData.Count -eq 0) {
		Write-Host "No user data available. Please retrieve users first." -ForegroundColor Yellow
		Write-Host ""
		Write-Host "Press any key to return to menu..." -ForegroundColor Cyan
		$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
		return
	}
	
	Show-Header "Export User List - JSON Format"
	
	Ensure-OutputFolder -Path $Script:OutputFolder
	$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
	$fileName = "M365_User_List_$timestamp.json"
	$filePath = Join-Path $Script:OutputFolder $fileName
	
	try {
		$jsonData = @()
		
		foreach ($user in $Script:UserData | Sort-Object DisplayName) {
			# Build MFA object
			$mfaObject = @{
				Configured = $user.MfaConfigured
				Methods = $user.MfaMethods
				LastSignIn = $user.MfaLastSignIn
			}
			
			# Build clean user object matching requested format
			$userObject = @{
				UserPrincipalName = $user.UserPrincipalName
				DisplayName = $user.DisplayName
				AccountEnabled = $user.AccountEnabled
				AccountStatus = $user.AccountStatus
				Licenses = $user.Licenses
				Roles = $user.Roles
				Groups = $user.Groups
				MFA = $mfaObject
			}
			
			# Add optional fields if they have values
			if ($user.PrimaryEmail -ne $user.UserPrincipalName) {
				$userObject.PrimaryEmail = $user.PrimaryEmail
			}
			if ($user.PhoneNumber -ne "Not Set") {
				$userObject.PhoneNumber = $user.PhoneNumber
			}
			if ($user.JobTitle -ne "Not Set") {
				$userObject.JobTitle = $user.JobTitle
			}
			if ($user.Department -ne "Not Set") {
				$userObject.Department = $user.Department
			}
			if ($user.MailboxHasMailbox) {
				$userObject.Mailbox = @{
					ForwardingEnabled = $user.MailboxForwardingEnabled
					ExternalForwarding = $user.MailboxExternalForwarding
					ForwardingAddress = $user.MailboxForwardingAddress
					Size = $user.MailboxSize
					Quota = $user.MailboxQuota
					LitigationHold = $user.MailboxLitigationHold
					RetentionEnabled = $user.MailboxRetentionEnabled
				}
			}
			if ($user.LastSignIn -ne "Never") {
				$userObject.LastSignIn = $user.LastSignIn
			}
			if ($user.CreatedDate -ne "Unknown") {
				$userObject.CreatedDate = $user.CreatedDate
			}
			
			$jsonData += $userObject
		}
		
		# Create final JSON structure with metadata
		$finalJson = @{
			Generated = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
			Organization = $Script:TenantName
			Domain = $Script:TenantDomain
			TotalUsers = $Script:UserData.Count
			Users = $jsonData
		}
		
		# Convert to JSON with proper formatting
		$jsonContent = $finalJson | ConvertTo-Json -Depth 10 -Compress:$false
		
		# Write to file
		$jsonContent | Out-File -FilePath $filePath -Encoding UTF8 -Force
		
		Write-Host "Export completed successfully!" -ForegroundColor Green
		Write-Host ""
		Write-Host "File saved to:" -ForegroundColor Cyan
		Write-Host $filePath -ForegroundColor White
		Write-Host ""
		Write-Host "Total users exported: $($Script:UserData.Count)" -ForegroundColor Green
		Write-Host ""
		Write-Host "This JSON file can be:" -ForegroundColor Yellow
		Write-Host "  - Parsed by other tools and scripts" -ForegroundColor Gray
		Write-Host "  - Imported into databases" -ForegroundColor Gray
		Write-Host "  - Used for API integrations" -ForegroundColor Gray
		Write-Host "  - Processed by automation systems" -ForegroundColor Gray
		Write-Host ""
		
		Write-Host "Opening file..." -ForegroundColor Yellow
		Start-Sleep -Seconds 1
		Start-Process $filePath
		
	} catch {
		Write-Host "Export failed: $($_.Exception.Message)" -ForegroundColor Red
		Write-Host ""
	}
	
	Write-Host "Press any key to return to menu..." -ForegroundColor Cyan
	$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Show-Help {
	Show-Header "Help & Information"
	
	Write-Host "MICROSOFT 365 USER LIST TOOL" -ForegroundColor Cyan
	Write-Host "------------------------------------------------------------" -ForegroundColor Gray
	Write-Host ""
	Write-Host "This tool retrieves and lists all users in your Microsoft 365 tenant" -ForegroundColor White
	Write-Host "with comprehensive information including:" -ForegroundColor White
	Write-Host ""
	Write-Host "  - Email addresses (UserPrincipalName and Mail)" -ForegroundColor Gray
	Write-Host "  - Phone numbers (Business and Mobile)" -ForegroundColor Gray
	Write-Host "  - MFA status (Enabled/Disabled, methods: Authenticator, SMS, Email, FIDO)" -ForegroundColor Gray
	Write-Host "  - Account status (Enabled/Disabled/Blocked sign-in)" -ForegroundColor Gray
	Write-Host "  - Job title, department, office location" -ForegroundColor Gray
	Write-Host "  - License assignments (with SKU names)" -ForegroundColor Gray
	Write-Host "  - Directory roles (Global Admin, Exchange Admin, etc.)" -ForegroundColor Gray
	Write-Host "  - Group memberships (Security groups + M365 groups)" -ForegroundColor Gray
	Write-Host "  - Mailbox configuration (forwarding, size, litigation hold)" -ForegroundColor Gray
	Write-Host "  - Last sign-in date and time" -ForegroundColor Gray
	Write-Host "  - Account creation date" -ForegroundColor Gray
	Write-Host ""
	Write-Host "REQUIREMENTS" -ForegroundColor Cyan
	Write-Host "------------------------------------------------------------" -ForegroundColor Gray
	Write-Host ""
	Write-Host "  - Microsoft Graph PowerShell SDK" -ForegroundColor Gray
	Write-Host "  - Global Administrator or Global Reader role" -ForegroundColor Gray
	Write-Host "  - Required permissions:" -ForegroundColor Gray
	Write-Host "    * User.Read.All" -ForegroundColor Yellow
	Write-Host "    * UserAuthenticationMethod.Read.All" -ForegroundColor Yellow
	Write-Host "    * Organization.Read.All" -ForegroundColor Yellow
	Write-Host "    * Directory.Read.All" -ForegroundColor Yellow
	Write-Host "    * Group.Read.All" -ForegroundColor Yellow
	Write-Host "    * Mail.Read" -ForegroundColor Yellow
	Write-Host "    * MailboxSettings.Read" -ForegroundColor Yellow
	Write-Host ""
	Write-Host "USAGE" -ForegroundColor Cyan
	Write-Host "------------------------------------------------------------" -ForegroundColor Gray
	Write-Host ""
	Write-Host "  1. Connect to Microsoft Graph" -ForegroundColor White
	Write-Host "     - First-time users will need to authenticate via browser" -ForegroundColor Gray
	Write-Host "     - Grant permissions when prompted" -ForegroundColor Gray
	Write-Host "     - If already connected, you can keep or switch tenants" -ForegroundColor Gray
	Write-Host ""
	Write-Host "  2. Disconnect from Current Tenant" -ForegroundColor White
	Write-Host "     - Disconnects from the current Microsoft 365 tenant" -ForegroundColor Gray
	Write-Host "     - Clears all cached user data" -ForegroundColor Gray
	Write-Host "     - Use this to switch to a different tenant" -ForegroundColor Gray
	Write-Host ""
	Write-Host "  3. Retrieve Users" -ForegroundColor White
	Write-Host "     - Fetches all users from your Microsoft 365 tenant" -ForegroundColor Gray
	Write-Host "     - May take a few moments for large tenants" -ForegroundColor Gray
	Write-Host ""
	Write-Host "  4. View Summary" -ForegroundColor White
	Write-Host "     - Displays statistics and top 10 users" -ForegroundColor Gray
	Write-Host ""
	Write-Host "  5-8. Export Reports" -ForegroundColor White
	Write-Host "     - TXT: Human-readable text format" -ForegroundColor Gray
	Write-Host "     - CSV: Spreadsheet format for Excel/Google Sheets" -ForegroundColor Gray
	Write-Host "     - HTML: Professional web report with styling" -ForegroundColor Gray
	Write-Host "     - JSON: Clean JSON format for automation and integrations" -ForegroundColor Gray
	Write-Host ""
	Write-Host "SECURITY NOTES" -ForegroundColor Cyan
	Write-Host "------------------------------------------------------------" -ForegroundColor Gray
	Write-Host ""
	Write-Host "  - This tool only reads user information (read-only)" -ForegroundColor Gray
	Write-Host "  - No modifications are made to user accounts" -ForegroundColor Gray
	Write-Host "  - All data is stored locally on your computer" -ForegroundColor Gray
	Write-Host "  - Authentication tokens are managed by Microsoft Graph" -ForegroundColor Gray
	Write-Host ""
	Write-Host "SUPPORT" -ForegroundColor Cyan
	Write-Host "------------------------------------------------------------" -ForegroundColor Gray
	Write-Host ""
	Write-Host "  Website: www.soulitek.co.il" -ForegroundColor Cyan
	Write-Host "  Email: letstalk@soulitek.co.il" -ForegroundColor Cyan
	Write-Host ""
	
	Write-Host "Press any key to return to menu..." -ForegroundColor Cyan
	$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Show-Menu {
	Show-Header "Microsoft 365 User List"
	
	$status = if ($Script:Connected) { "Connected" } else { "Not Connected" }
	$statusColor = if ($Script:Connected) { "Green" } else { "Red" }
	$userCount = if ($Script:UserData.Count -gt 0) { " ($($Script:UserData.Count) users loaded)" } else { "" }
	
	Write-Host "Connection Status: " -NoNewline -ForegroundColor Gray
	Write-Host "$status" -ForegroundColor $statusColor
	if ($Script:Connected -and $Script:TenantDomain -ne "Unknown") {
		Write-Host "Organization: " -NoNewline -ForegroundColor Gray
		Write-Host "$($Script:TenantName)" -ForegroundColor Cyan
		Write-Host "Domain: " -NoNewline -ForegroundColor Gray
		Write-Host "$($Script:TenantDomain)" -ForegroundColor Cyan
	}
	Write-Host "User Data: " -NoNewline -ForegroundColor Gray
	Write-Host "$($Script:UserData.Count) users$userCount" -ForegroundColor $(if ($Script:UserData.Count -gt 0) { "Green" } else { "Yellow" })
	Write-Host ""
	Write-Host "============================================================" -ForegroundColor Cyan
	Write-Host ""
	Write-Host "  1. Connect to Microsoft Graph" -ForegroundColor White
	Write-Host "  2. Disconnect from Current Tenant" -ForegroundColor White
	Write-Host "  3. Retrieve All Users" -ForegroundColor White
	Write-Host "  4. View User Summary" -ForegroundColor White
	Write-Host "  5. Export Report - TXT Format" -ForegroundColor White
	Write-Host "  6. Export Report - CSV Format" -ForegroundColor White
	Write-Host "  7. Export Report - HTML Format" -ForegroundColor White
	Write-Host "  8. Export Report - JSON Format" -ForegroundColor White
	Write-Host "  9. Help & Information" -ForegroundColor White
	Write-Host "  0. Exit" -ForegroundColor White
	Write-Host ""
	Write-Host "============================================================" -ForegroundColor Cyan
	Write-Host ""
	Write-Host "Please select an option (0-9): " -NoNewline -ForegroundColor Yellow
}

# ============================================================
# EXIT MESSAGE
# ============================================================

# Show-ExitMessage function - using Show-SouliTEKExitMessage from common module
function Show-ExitMessage {
	# Disconnect if connected
	try {
		if ($Script:Connected) {
			Write-Host "Disconnecting from Microsoft Graph..." -ForegroundColor Cyan
			Disconnect-MgGraph -ErrorAction SilentlyContinue | Out-Null
		}
	} catch { }
	
	Show-SouliTEKExitMessage -ScriptPath $PSCommandPath -ToolName "SouliTEK Microsoft 365 User List Tool"
}

# Show banner
Clear-Host
Show-ScriptBanner -ScriptName "Microsoft 365 User List" -Purpose "List and manage Microsoft 365 users and licenses"

# Main execution loop
while ($true) {
	Show-Menu
	$choice = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
	Write-Host $choice.Character
	
	switch ($choice.Character) {
		'1' { Connect-ToMicrosoftGraph }
		'2' { Disconnect-FromMicrosoftGraph }
		'3' { Get-AllUsers }
		'4' { Show-UserSummary }
		'5' { Export-UserListTxt }
		'6' { Export-UserListCsv }
		'7' { Export-UserListHtml }
		'8' { Export-UserListJson }
		'9' { Show-Help }
		'0' {
			Show-ExitMessage
			exit
		}
		default {
			Write-Host ""
			Write-Host "Invalid option. Please select 0-9." -ForegroundColor Red
			Write-Host ""
			Write-Host "Press any key to continue..." -ForegroundColor Cyan
			$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
		}
	}
}

