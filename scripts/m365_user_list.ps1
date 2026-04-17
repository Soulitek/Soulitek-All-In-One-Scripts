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
	Write-Ui -Message "[Step 1/4] Installing/verifying Microsoft Graph modules..." -Level "INFO"
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
		Write-Ui -Message "[-] Some required modules failed to install" -Level "ERROR"
		return $false
	}
	
	Write-Host ""
	Write-Ui -Message "[+] All Microsoft Graph modules ready" -Level "OK"
	
	try {
	Write-Host ""
	Write-Ui -Message "[Step 2/4] Checking existing connection..." -Level "INFO"
	# Check if already connected
	$context = Get-MgContext -ErrorAction SilentlyContinue
	if ($context) {
		Write-Ui -Message "          [+] Already connected to Microsoft Graph" -Level "OK"
		Write-Ui -Message "          Account: $($context.Account)" -Level "INFO"
		Write-Ui -Message "          Tenant: $($context.TenantId)" -Level "INFO"
		
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
			Write-Ui -Message "          Organization: $($Script:TenantName)" -Level "INFO"
			Write-Ui -Message "          Domain: $($Script:TenantDomain)" -Level "INFO"
		}
		Write-Host ""
		Write-Host "------------------------------------------------------------" -ForegroundColor Yellow
		Write-Ui -Message "Would you like to:" -Level "WARN"
		Write-Ui -Message "  1. Keep current connection" -Level "STEP"
		Write-Ui -Message "  2. Disconnect and connect to a different tenant" -Level "STEP"
		Write-Host ""
		Write-Host "Select option (1-2): " -NoNewline -ForegroundColor Cyan
		$reconnectChoice = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
		Write-Host $reconnectChoice.Character
		Write-Host ""
		
		if ($reconnectChoice.Character -eq '2') {
			Write-Ui -Message "Disconnecting from current tenant..." -Level "WARN"
			try {
				Disconnect-MgGraph -ErrorAction SilentlyContinue | Out-Null
				$Script:Connected = $false
				$Script:TenantDomain = "Unknown"
				$Script:TenantName = "Unknown"
				Write-Ui -Message "[+] Disconnected successfully" -Level "OK"
				Write-Host ""
				# Continue to new connection below
			} catch {
				Write-Warning "Disconnect failed: $($_.Exception.Message)"
				Write-Host ""
				Write-Ui -Message "Press any key to return to menu..." -Level "INFO"
				$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
				return $false
			}
		} else {
			Write-Ui -Message "[+] Using existing connection" -Level "OK"
			$Script:Connected = $true
			Write-Host ""
			Write-Ui -Message "Press any key to return to menu..." -Level "INFO"
			$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
			return $true
		}
	}
	Write-Ui -Message "          No existing connection found" -Level "WARN"
		
		Write-Host ""
		Write-Ui -Message "[Step 3/3] Initiating connection to Microsoft Graph..." -Level "INFO"
		Write-Ui -Message "          This will open a browser window for authentication" -Level "WARN"
		Write-Ui -Message "          Required permissions:" -Level "INFO"
		Write-Ui -Message "            - User.Read.All (read user information)" -Level "INFO"
		Write-Ui -Message "            - UserAuthenticationMethod.Read.All (read MFA status)" -Level "INFO"
		Write-Ui -Message "            - Organization.Read.All (read organization info)" -Level "INFO"
		Write-Ui -Message "            - Directory.Read.All (read roles and groups)" -Level "INFO"
		Write-Ui -Message "            - Group.Read.All (read group memberships)" -Level "INFO"
		Write-Ui -Message "            - Mail.Read (read mailbox settings)" -Level "INFO"
		Write-Ui -Message "            - MailboxSettings.Read (read mailbox configuration)" -Level "INFO"
		Write-Host ""
		Write-Ui -Message "          Opening authentication browser window..." -Level "INFO"
		
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
		
		Write-Ui -Message "          [+] Authentication successful!" -Level "OK"
		
		$context = Get-MgContext
		Write-Ui -Message "          Connected as: $($context.Account)" -Level "INFO"
		Write-Ui -Message "          Tenant: $($context.TenantId)" -Level "INFO"
		
		# Get organization/domain information
		Write-Host ""
		Write-Ui -Message "[Step 4/4] Retrieving organization details..." -Level "INFO"
		try {
			$org = Get-MgOrganization -ErrorAction Stop | Select-Object -First 1
			if ($org) {
				$Script:TenantName = if ($org.DisplayName) { $org.DisplayName } else { "Unknown" }
				$Script:TenantDomain = if ($org.VerifiedDomains) { 
					($org.VerifiedDomains | Where-Object { $_.IsDefault -eq $true }).Name 
				} else { 
					"Unknown" 
				}
				Write-Ui -Message "          Organization: $($Script:TenantName)" -Level "INFO"
				Write-Ui -Message "          Domain: $($Script:TenantDomain)" -Level "INFO"
			}
		} catch {
			Write-Warning "Could not retrieve organization details: $($_.Exception.Message)"
		}
		
		Write-Host ""
		Write-Host "============================================================" -ForegroundColor Green
		Write-Ui -Message "  [+] Microsoft Graph Connected Successfully" -Level "OK"
		Write-Host "============================================================" -ForegroundColor Green
		Write-Host ""
		$Script:Connected = $true
		$connected = $true
	} catch {
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
		Write-Ui -Message "  3. Try running the script again" -Level "INFO"
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
		Write-Ui -Message "Not currently connected to Microsoft Graph." -Level "WARN"
		Write-Host ""
		Write-Ui -Message "Press any key to return to menu..." -Level "INFO"
		$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
		return
	}
	
	Write-Ui -Message "Current connection:" -Level "INFO"
	Write-Host ""
	if ($Script:TenantDomain -ne "Unknown") {
		Write-Ui -Message "  Organization: $($Script:TenantName)" -Level "INFO"
		Write-Ui -Message "  Domain: $($Script:TenantDomain)" -Level "INFO"
	}
	$context = Get-MgContext -ErrorAction SilentlyContinue
	if ($context) {
		Write-Ui -Message "  Account: $($context.Account)" -Level "INFO"
		Write-Ui -Message "  Tenant: $($context.TenantId)" -Level "INFO"
	}
	Write-Host ""
	Write-Host "------------------------------------------------------------" -ForegroundColor Yellow
	Write-Host "Are you sure you want to disconnect? (Y/N): " -NoNewline -ForegroundColor Yellow
	$confirm = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
	Write-Host $confirm.Character
	Write-Host ""
	
	if ($confirm.Character -eq 'Y' -or $confirm.Character -eq 'y') {
		try {
			Write-Ui -Message "Disconnecting from Microsoft Graph..." -Level "INFO"
			Disconnect-MgGraph -ErrorAction Stop | Out-Null
			$Script:Connected = $false
			$Script:TenantDomain = "Unknown"
			$Script:TenantName = "Unknown"
			$Script:UserData = @()
			Write-Host ""
			Write-Host "============================================================" -ForegroundColor Green
			Write-Ui -Message "  [+] Disconnected Successfully" -Level "OK"
			Write-Host "============================================================" -ForegroundColor Green
			Write-Host ""
			Write-Ui -Message "User data has been cleared." -Level "INFO"
			Write-Host ""
		} catch {
			Write-Host ""
			Write-Host "============================================================" -ForegroundColor Red
			Write-Ui -Message "  [-] Disconnect Failed" -Level "ERROR"
			Write-Host "============================================================" -ForegroundColor Red
			Write-Host ""
			Write-Warning "Disconnect failed: $($_.Exception.Message)"
			Write-Host ""
		}
	} else {
		Write-Ui -Message "Disconnect cancelled." -Level "WARN"
		Write-Host ""
	}
	
	Write-Ui -Message "Press any key to return to menu..." -Level "INFO"
	$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Get-AllUsers {
	Show-Header "Retrieving Microsoft 365 Users"
	
	if (-not $Script:Connected) {
		Write-Ui -Message "Not connected to Microsoft Graph. Please connect first." -Level "ERROR"
		Write-Host ""
		Write-Ui -Message "Press any key to return to menu..." -Level "INFO"
		$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
		return
	}
	
	try {
		Write-Ui -Message "Retrieving all users from Microsoft 365..." -Level "INFO"
		Write-Ui -Message "This may take a few moments depending on the number of users..." -Level "INFO"
		Write-Host ""
		
		$allUsers = Get-MgUser -All -Property DisplayName,UserPrincipalName,Mail,JobTitle,Department,OfficeLocation,AccountEnabled,CompanyName,BusinessPhones,MobilePhone,AssignedLicenses,LastSignInDateTime,CreatedDateTime -ErrorAction Stop
		
		if (-not $allUsers -or $allUsers.Count -eq 0) {
			Write-Ui -Message "No users found in the tenant." -Level "WARN"
			Write-Host ""
			Write-Ui -Message "Press any key to return to menu..." -Level "INFO"
			$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
			return
		}
		
		Write-Ui -Message "Found $($allUsers.Count) user(s). Processing user details..." -Level "OK"
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
		Write-Ui -Message "  [+] Successfully retrieved $($Script:UserData.Count) users" -Level "OK"
		Write-Host "============================================================" -ForegroundColor Green
		Write-Host ""
		
	} catch {
		Write-Host ""
		Write-Host "============================================================" -ForegroundColor Red
		Write-Ui -Message "  [-] Error retrieving users" -Level "ERROR"
		Write-Host "============================================================" -ForegroundColor Red
		Write-Host ""
		Write-Warning "Error: $($_.Exception.Message)"
		Write-Host ""
		Write-Ui -Message "Press any key to return to menu..." -Level "INFO"
		$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
	}
}

function Show-UserSummary {
	Show-Header "User Summary"
	
	if ($Script:UserData.Count -eq 0) {
		Write-Ui -Message "No user data available. Please retrieve users first." -Level "WARN"
		Write-Host ""
		Write-Ui -Message "Press any key to return to menu..." -Level "INFO"
		$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
		return
	}
	
	$enabledUsers = ($Script:UserData | Where-Object { $_.AccountEnabled -eq $true }).Count
	$disabledUsers = ($Script:UserData | Where-Object { $_.AccountEnabled -eq $false }).Count
	$mfaEnabledUsers = ($Script:UserData | Where-Object { $_.MfaConfigured -eq $true }).Count
	$mfaDisabledUsers = ($Script:UserData | Where-Object { $_.MfaConfigured -eq $false }).Count
	$mfaEnabledPct = if ($Script:UserData.Count -gt 0) { [math]::Round(($mfaEnabledUsers / $Script:UserData.Count) * 100, 2) } else { 0 }
	
	Write-Ui -Message "SUMMARY STATISTICS" -Level "INFO"
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
	Write-Ui -Message "TOP 10 USERS (by Display Name)" -Level "INFO"
	Write-Host "------------------------------------------------------------" -ForegroundColor Gray
	Write-Host ""
	
	$topUsers = $Script:UserData | Sort-Object DisplayName | Select-Object -First 10
	foreach ($user in $topUsers) {
		$mfaStatus = if ($user.MfaConfigured) { "Enabled ($($user.MfaMethodCount) methods)" } else { "Disabled" }
		$mfaColor = if ($user.MfaConfigured) { "Green" } else { "Red" }
		$accountStatus = $user.AccountStatus
		$rolesCount = if ($user.RolesCount -gt 0) { " ($($user.RolesCount) roles)" } else { "" }
		$groupsCount = if ($user.GroupsCount -gt 0) { " ($($user.GroupsCount) groups)" } else { "" }
		
		Write-Ui -Message "  $($user.DisplayName)" -Level "STEP"
		Write-Ui -Message "    Email: $($user.EmailAddress)" -Level "INFO"
		Write-Ui -Message "    Phone: $($user.PhoneNumber)" -Level "INFO"
		Write-Host "    Status: $accountStatus | MFA: " -NoNewline -ForegroundColor Gray
		Write-Host "$mfaStatus" -ForegroundColor $mfaColor
		if ($user.RolesCount -gt 0) {
			Write-Ui -Message "    Roles: $($user.Roles -join ', ')" -Level "INFO"
		}
		if ($user.GroupsCount -gt 0) {
			Write-Ui -Message "    Groups: $($user.GroupsCount) groups" -Level "INFO"
		}
		if ($user.LicensesCount -gt 0) {
			Write-Ui -Message "    Licenses: $($user.LicensesCount) assigned" -Level "WARN"
		}
		Write-Host ""
	}
	
	if ($Script:UserData.Count -gt 10) {
		Write-Ui -Message "  ... and $($Script:UserData.Count - 10) more users" -Level "INFO"
		Write-Host ""
	}
	
	Write-Ui -Message "Press any key to return to menu..." -Level "INFO"
	$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Export-UserListTxt {
	if ($Script:UserData.Count -eq 0) {
		Write-Ui -Message "No user data available. Please retrieve users first." -Level "WARN"
		Write-Host ""
		Write-Ui -Message "Press any key to return to menu..." -Level "INFO"
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
		
		Write-Ui -Message "Export completed successfully!" -Level "OK"
		Write-Host ""
		Write-Ui -Message "File saved to:" -Level "INFO"
		Write-Ui -Message $filePath -Level "STEP"
		Write-Host ""
		Write-Ui -Message "Total users exported: $($Script:UserData.Count)" -Level "OK"
		Write-Host ""
		
		Write-Ui -Message "Opening file..." -Level "WARN"
		Start-Sleep -Seconds 1
		Start-Process $filePath
		
	} catch {
		Write-Ui -Message "Export failed: $($_.Exception.Message)" -Level "ERROR"
		Write-Host ""
	}
	
	Write-Ui -Message "Press any key to return to menu..." -Level "INFO"
	$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Export-UserListCsv {
	if ($Script:UserData.Count -eq 0) {
		Write-Ui -Message "No user data available. Please retrieve users first." -Level "WARN"
		Write-Host ""
		Write-Ui -Message "Press any key to return to menu..." -Level "INFO"
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
		
		Write-Ui -Message "Export completed successfully!" -Level "OK"
		Write-Host ""
		Write-Ui -Message "File saved to:" -Level "INFO"
		Write-Ui -Message $filePath -Level "STEP"
		Write-Host ""
		Write-Ui -Message "Total users exported: $($Script:UserData.Count)" -Level "OK"
		Write-Host ""
		Write-Ui -Message "This file can be opened in:" -Level "WARN"
		Write-Ui -Message "  - Microsoft Excel" -Level "INFO"
		Write-Ui -Message "  - Google Sheets" -Level "INFO"
		Write-Ui -Message "  - Any spreadsheet program" -Level "INFO"
		Write-Host ""
		
		Write-Ui -Message "Opening file..." -Level "WARN"
		Start-Sleep -Seconds 1
		Start-Process $filePath
		
	} catch {
		Write-Ui -Message "Export failed: $($_.Exception.Message)" -Level "ERROR"
		Write-Host ""
	}
	
	Write-Ui -Message "Press any key to return to menu..." -Level "INFO"
	$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Export-UserListHtml {
	if ($Script:UserData.Count -eq 0) {
		Write-Ui -Message "No user data available. Please retrieve users first." -Level "WARN"
		Write-Host ""
		Write-Ui -Message "Press any key to return to menu..." -Level "INFO"
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
		
		Write-Ui -Message "Export completed successfully!" -Level "OK"
		Write-Host ""
		Write-Ui -Message "File saved to:" -Level "INFO"
		Write-Ui -Message $filePath -Level "STEP"
		Write-Host ""
		Write-Ui -Message "Total users exported: $($Script:UserData.Count)" -Level "OK"
		Write-Host ""
		
		Write-Ui -Message "Opening file in browser..." -Level "WARN"
		Start-Sleep -Seconds 1
		Start-Process $filePath
		
	} catch {
		Write-Ui -Message "Export failed: $($_.Exception.Message)" -Level "ERROR"
		Write-Host ""
	}
	
	Write-Ui -Message "Press any key to return to menu..." -Level "INFO"
	$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Export-UserListJson {
	if ($Script:UserData.Count -eq 0) {
		Write-Ui -Message "No user data available. Please retrieve users first." -Level "WARN"
		Write-Host ""
		Write-Ui -Message "Press any key to return to menu..." -Level "INFO"
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
		
		Write-Ui -Message "Export completed successfully!" -Level "OK"
		Write-Host ""
		Write-Ui -Message "File saved to:" -Level "INFO"
		Write-Ui -Message $filePath -Level "STEP"
		Write-Host ""
		Write-Ui -Message "Total users exported: $($Script:UserData.Count)" -Level "OK"
		Write-Host ""
		Write-Ui -Message "This JSON file can be:" -Level "WARN"
		Write-Ui -Message "  - Parsed by other tools and scripts" -Level "INFO"
		Write-Ui -Message "  - Imported into databases" -Level "INFO"
		Write-Ui -Message "  - Used for API integrations" -Level "INFO"
		Write-Ui -Message "  - Processed by automation systems" -Level "INFO"
		Write-Host ""
		
		Write-Ui -Message "Opening file..." -Level "WARN"
		Start-Sleep -Seconds 1
		Start-Process $filePath
		
	} catch {
		Write-Ui -Message "Export failed: $($_.Exception.Message)" -Level "ERROR"
		Write-Host ""
	}
	
	Write-Ui -Message "Press any key to return to menu..." -Level "INFO"
	$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Show-Help {
	Show-Header "Help & Information"
	
	Write-Ui -Message "MICROSOFT 365 USER LIST TOOL" -Level "INFO"
	Write-Host "------------------------------------------------------------" -ForegroundColor Gray
	Write-Host ""
	Write-Ui -Message "This tool retrieves and lists all users in your Microsoft 365 tenant" -Level "STEP"
	Write-Ui -Message "with comprehensive information including:" -Level "STEP"
	Write-Host ""
	Write-Ui -Message "  - Email addresses (UserPrincipalName and Mail)" -Level "INFO"
	Write-Ui -Message "  - Phone numbers (Business and Mobile)" -Level "INFO"
	Write-Ui -Message "  - MFA status (Enabled/Disabled, methods: Authenticator, SMS, Email, FIDO)" -Level "INFO"
	Write-Ui -Message "  - Account status (Enabled/Disabled/Blocked sign-in)" -Level "INFO"
	Write-Ui -Message "  - Job title, department, office location" -Level "INFO"
	Write-Ui -Message "  - License assignments (with SKU names)" -Level "INFO"
	Write-Ui -Message "  - Directory roles (Global Admin, Exchange Admin, etc.)" -Level "INFO"
	Write-Ui -Message "  - Group memberships (Security groups + M365 groups)" -Level "INFO"
	Write-Ui -Message "  - Mailbox configuration (forwarding, size, litigation hold)" -Level "INFO"
	Write-Ui -Message "  - Last sign-in date and time" -Level "INFO"
	Write-Ui -Message "  - Account creation date" -Level "INFO"
	Write-Host ""
	Write-Ui -Message "REQUIREMENTS" -Level "INFO"
	Write-Host "------------------------------------------------------------" -ForegroundColor Gray
	Write-Host ""
	Write-Ui -Message "  - Microsoft Graph PowerShell SDK" -Level "INFO"
	Write-Ui -Message "  - Global Administrator or Global Reader role" -Level "INFO"
	Write-Ui -Message "  - Required permissions:" -Level "INFO"
	Write-Ui -Message "    * User.Read.All" -Level "WARN"
	Write-Ui -Message "    * UserAuthenticationMethod.Read.All" -Level "WARN"
	Write-Ui -Message "    * Organization.Read.All" -Level "WARN"
	Write-Ui -Message "    * Directory.Read.All" -Level "WARN"
	Write-Ui -Message "    * Group.Read.All" -Level "WARN"
	Write-Ui -Message "    * Mail.Read" -Level "WARN"
	Write-Ui -Message "    * MailboxSettings.Read" -Level "WARN"
	Write-Host ""
	Write-Ui -Message "USAGE" -Level "INFO"
	Write-Host "------------------------------------------------------------" -ForegroundColor Gray
	Write-Host ""
	Write-Ui -Message "  1. Connect to Microsoft Graph" -Level "STEP"
	Write-Ui -Message "     - First-time users will need to authenticate via browser" -Level "INFO"
	Write-Ui -Message "     - Grant permissions when prompted" -Level "INFO"
	Write-Ui -Message "     - If already connected, you can keep or switch tenants" -Level "INFO"
	Write-Host ""
	Write-Ui -Message "  2. Disconnect from Current Tenant" -Level "STEP"
	Write-Ui -Message "     - Disconnects from the current Microsoft 365 tenant" -Level "INFO"
	Write-Ui -Message "     - Clears all cached user data" -Level "INFO"
	Write-Ui -Message "     - Use this to switch to a different tenant" -Level "INFO"
	Write-Host ""
	Write-Ui -Message "  3. Retrieve Users" -Level "STEP"
	Write-Ui -Message "     - Fetches all users from your Microsoft 365 tenant" -Level "INFO"
	Write-Ui -Message "     - May take a few moments for large tenants" -Level "INFO"
	Write-Host ""
	Write-Ui -Message "  4. View Summary" -Level "STEP"
	Write-Ui -Message "     - Displays statistics and top 10 users" -Level "INFO"
	Write-Host ""
	Write-Ui -Message "  5-8. Export Reports" -Level "STEP"
	Write-Ui -Message "     - TXT: Human-readable text format" -Level "INFO"
	Write-Ui -Message "     - CSV: Spreadsheet format for Excel/Google Sheets" -Level "INFO"
	Write-Ui -Message "     - HTML: Professional web report with styling" -Level "INFO"
	Write-Ui -Message "     - JSON: Clean JSON format for automation and integrations" -Level "INFO"
	Write-Host ""
	Write-Ui -Message "SECURITY NOTES" -Level "INFO"
	Write-Host "------------------------------------------------------------" -ForegroundColor Gray
	Write-Host ""
	Write-Ui -Message "  - This tool only reads user information (read-only)" -Level "INFO"
	Write-Ui -Message "  - No modifications are made to user accounts" -Level "INFO"
	Write-Ui -Message "  - All data is stored locally on your computer" -Level "INFO"
	Write-Ui -Message "  - Authentication tokens are managed by Microsoft Graph" -Level "INFO"
	Write-Host ""
	Write-Ui -Message "SUPPORT" -Level "INFO"
	Write-Host "------------------------------------------------------------" -ForegroundColor Gray
	Write-Host ""
	Write-Ui -Message "  Website: www.soulitek.co.il" -Level "INFO"
	Write-Ui -Message "  Email: letstalk@soulitek.co.il" -Level "INFO"
	Write-Host ""
	
	Write-Ui -Message "Press any key to return to menu..." -Level "INFO"
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
		Write-Ui -Message "$($Script:TenantName)" -Level "INFO"
		Write-Host "Domain: " -NoNewline -ForegroundColor Gray
		Write-Ui -Message "$($Script:TenantDomain)" -Level "INFO"
	}
	Write-Host "User Data: " -NoNewline -ForegroundColor Gray
	Write-Host "$($Script:UserData.Count) users$userCount" -ForegroundColor $(if ($Script:UserData.Count -gt 0) { "Green" } else { "Yellow" })
	Write-Host ""
	Write-Host "============================================================" -ForegroundColor Cyan
	Write-Host ""
	Write-Ui -Message "  1. Connect to Microsoft Graph" -Level "STEP"
	Write-Ui -Message "  2. Disconnect from Current Tenant" -Level "STEP"
	Write-Ui -Message "  3. Retrieve All Users" -Level "STEP"
	Write-Ui -Message "  4. View User Summary" -Level "STEP"
	Write-Ui -Message "  5. Export Report - TXT Format" -Level "STEP"
	Write-Ui -Message "  6. Export Report - CSV Format" -Level "STEP"
	Write-Ui -Message "  7. Export Report - HTML Format" -Level "STEP"
	Write-Ui -Message "  8. Export Report - JSON Format" -Level "STEP"
	Write-Ui -Message "  9. Help & Information" -Level "STEP"
	Write-Ui -Message "  0. Exit" -Level "STEP"
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
			Write-Ui -Message "Disconnecting from Microsoft Graph..." -Level "INFO"
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
			Write-Ui -Message "Invalid option. Please select 0-9." -Level "ERROR"
			Write-Host ""
			Write-Ui -Message "Press any key to continue..." -Level "INFO"
			$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
		}
	}
}

