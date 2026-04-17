# ============================================================
# Exchange Online Calendar Permissions Audit - SouliTEK Edition
# ============================================================
# Coded by: Soulitek.co.il | www.soulitek.co.il | letstalk@soulitek.co.il
# (C) 2025 SouliTEK - All Rights Reserved
# ============================================================

$Host.UI.RawUI.WindowTitle = "Exchange Online Calendar Permissions Audit"

# Set preferences
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

# Show-Header function - wrapper using Show-SouliTEKHeader from common module
function Show-Header {
	param([string]$Title = "Exchange Online Calendar Permissions Audit", [ConsoleColor]$Color = 'Cyan')
	Show-SouliTEKHeader -Title $Title -Color $Color -ClearHost -ShowBanner
}

# ============================================================
# MAIN FUNCTIONS
# ============================================================

function Test-ExchangeOnlineModule {
	<#
	.SYNOPSIS
		Checks if ExchangeOnlineManagement module is loaded.
	
	.DESCRIPTION
		Verifies if the ExchangeOnlineManagement module is available.
		If not loaded, warns the user.
	
	.OUTPUTS
		[bool] True if module is loaded, False otherwise.
	#>
	
	try {
		$module = Get-Module -Name "ExchangeOnlineManagement" -ErrorAction SilentlyContinue
		if ($null -eq $module) {
			Write-Host ""
			Write-Host "============================================================" -ForegroundColor Yellow
			Write-Ui -Message "  WARNING: ExchangeOnlineManagement Module Not Loaded" -Level "WARN"
			Write-Host "============================================================" -ForegroundColor Yellow
			Write-Host ""
			Write-Ui -Message "The ExchangeOnlineManagement module is not currently loaded." -Level "WARN"
			Write-Host ""
			Write-Ui -Message "To install the module, run:" -Level "INFO"
			Write-Ui -Message "  Install-Module -Name ExchangeOnlineManagement -Scope CurrentUser" -Level "STEP"
			Write-Host ""
			Write-Ui -Message "To import the module, run:" -Level "INFO"
			Write-Ui -Message "  Import-Module ExchangeOnlineManagement" -Level "STEP"
			Write-Host ""
			Write-Ui -Message "Or connect to Exchange Online (this will auto-import the module):" -Level "INFO"
			Write-Ui -Message "  Connect-ExchangeOnline" -Level "STEP"
			Write-Host ""
			return $false
		}
		return $true
	}
	catch {
		Write-Host ""
		Write-Ui -Message "Error checking for ExchangeOnlineManagement module: $($_.Exception.Message)" -Level "ERROR"
		Write-Host ""
		return $false
	}
}

function Get-CalendarFolderName {
	<#
	.SYNOPSIS
		Dynamically finds the calendar folder name for a mailbox.
	
	.DESCRIPTION
		Uses Get-MailboxFolderStatistics to find the folder where
		FolderType equals 'Calendar' to get the correct name dynamically.
		This handles mailboxes in different languages (e.g., Hebrew "לוח שנה").
	
	.PARAMETER MailboxIdentity
		The identity of the mailbox (email address or alias).
	
	.OUTPUTS
		[string] The calendar folder name, or $null if not found.
	#>
	
	param(
		[Parameter(Mandatory=$true)]
		[string]$MailboxIdentity
	)
	
	try {
		Write-Ui -Message "Finding calendar folder for mailbox: $MailboxIdentity" -Level "INFO"
		Write-Host ""
		
		# Get all folders for the mailbox
		$folders = Get-MailboxFolderStatistics -Identity $MailboxIdentity -ErrorAction Stop
		
		# Find the folder where FolderType equals 'Calendar'
		$calendarFolder = $folders | Where-Object { $_.FolderType -eq 'Calendar' } | Select-Object -First 1
		
		if ($null -eq $calendarFolder) {
			Write-Ui -Message "Calendar folder not found for mailbox: $MailboxIdentity" -Level "ERROR"
			return $null
		}
		
		# Extract the folder name from the path
		# FolderPath format is typically: "/Calendar" or "/לוח שנה" etc.
		$folderName = $calendarFolder.Name
		
		Write-Ui -Message "Found calendar folder: '$folderName'" -Level "OK"
		Write-Host ""
		
		return $folderName
	}
	catch {
		Write-Ui -Message "Error finding calendar folder: $($_.Exception.Message)" -Level "ERROR"
		Write-Host ""
		return $null
	}
}

function Get-CalendarPermissions {
	<#
	.SYNOPSIS
		Retrieves calendar permissions for a mailbox.
	
	.DESCRIPTION
		Gets calendar folder permissions using the dynamically found folder name.
		Outputs results in a formatted table showing User, AccessRights, and SharingPermissionFlags.
	
	.PARAMETER MailboxIdentity
		The identity of the mailbox (email address or alias).
	
	.PARAMETER CalendarFolderName
		The name of the calendar folder (dynamically found).
	#>
	
	param(
		[Parameter(Mandatory=$true)]
		[string]$MailboxIdentity,
		
		[Parameter(Mandatory=$true)]
		[string]$CalendarFolderName
	)
	
	try {
		Write-Ui -Message "Retrieving calendar permissions..." -Level "INFO"
		Write-Host ""
		
		# Get calendar folder permissions
		$permissions = Get-MailboxFolderPermission -Identity "$MailboxIdentity`:\$CalendarFolderName" -ErrorAction Stop
		
		if ($null -eq $permissions -or $permissions.Count -eq 0) {
			Write-Ui -Message "No calendar permissions found for mailbox: $MailboxIdentity" -Level "WARN"
			Write-Host ""
			return
		}
		
		# Prepare results for formatted output
		$results = @()
		foreach ($perm in $permissions) {
			# Format AccessRights as string
			$accessRights = if ($perm.AccessRights) {
				$perm.AccessRights -join ", "
			} else {
				"None"
			}
			
			# Format SharingPermissionFlags
			$sharingFlags = if ($perm.SharingPermissionFlags) {
				$perm.SharingPermissionFlags -join ", "
			} else {
				"None"
			}
			
			# Get user identity
			$user = if ($perm.User) {
				$perm.User.ToString()
			} else {
				"Default"
			}
			
			$results += [PSCustomObject]@{
				User = $user
				AccessRights = $accessRights
				SharingPermissionFlags = $sharingFlags
			}
		}
		
		# Display results in formatted table
		Write-Host "============================================================" -ForegroundColor Green
		Write-Ui -Message "  Calendar Permissions for: $MailboxIdentity" -Level "OK"
		Write-Host "============================================================" -ForegroundColor Green
		Write-Host ""
		
		$results | Format-Table -AutoSize -Property User, AccessRights, SharingPermissionFlags
		
		Write-Host ""
		Write-Ui -Message "Total permissions found: $($results.Count)" -Level "INFO"
		Write-Host ""
	}
	catch {
		Write-Host ""
		Write-Host "============================================================" -ForegroundColor Red
		Write-Ui -Message "  Error Retrieving Calendar Permissions" -Level "ERROR"
		Write-Host "============================================================" -ForegroundColor Red
		Write-Host ""
		Write-Warning "Error: $($_.Exception.Message)"
		Write-Host ""
	}
}

function Start-CalendarPermissionsAudit {
	<#
	.SYNOPSIS
		Main function to audit calendar permissions.
	
	.DESCRIPTION
		Prompts user for target email, finds calendar folder dynamically,
		and retrieves calendar permissions with formatted output.
	#>
	
	Show-Header "Exchange Online Calendar Permissions Audit"
	
	# Check if module is loaded
	if (-not (Test-ExchangeOnlineModule)) {
		Write-Ui -Message "Press any key to exit..." -Level "INFO"
		$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
		return
	}
	
	# Prompt for target email
	Write-Ui -Message "Enter the target email address to audit calendar permissions:" -Level "INFO"
	Write-Host ""
	$targetEmail = Read-Host "Target Email"
	
	if ([string]::IsNullOrWhiteSpace($targetEmail)) {
		Write-Host ""
		Write-Ui -Message "No email address provided. Exiting." -Level "ERROR"
		Write-Host ""
		Write-Ui -Message "Press any key to exit..." -Level "INFO"
		$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
		return
	}
	
	Write-Host ""
	
	# Try to find the calendar folder
	$calendarFolderName = Get-CalendarFolderName -MailboxIdentity $targetEmail
	
	if ([string]::IsNullOrWhiteSpace($calendarFolderName)) {
		Write-Host ""
		Write-Host "============================================================" -ForegroundColor Red
		Write-Ui -Message "  Error: Could not find calendar folder" -Level "ERROR"
		Write-Host "============================================================" -ForegroundColor Red
		Write-Host ""
		Write-Ui -Message "Possible reasons:" -Level "WARN"
		Write-Ui -Message "  - Mailbox does not exist: $targetEmail" -Level "INFO"
		Write-Ui -Message "  - Mailbox does not have a calendar folder" -Level "INFO"
		Write-Ui -Message "  - Insufficient permissions to access the mailbox" -Level "INFO"
		Write-Ui -Message "  - Not connected to Exchange Online" -Level "INFO"
		Write-Host ""
		Write-Ui -Message "Press any key to exit..." -Level "INFO"
		$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
		return
	}
	
	# Get calendar permissions
	Get-CalendarPermissions -MailboxIdentity $targetEmail -CalendarFolderName $calendarFolderName
	
	Write-Ui -Message "Press any key to exit..." -Level "INFO"
	$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# ============================================================
# MAIN EXECUTION
# ============================================================

# Show banner
Clear-Host
Show-ScriptBanner -ScriptName "Exchange Calendar Permissions Audit" -Purpose "Audit calendar permissions for Exchange Online mailboxes"

try {
	Start-CalendarPermissionsAudit
}
catch {
	Write-Host ""
	Write-Ui -Message "Fatal Error" -Level "ERROR"
	Write-Host "============================================================" -ForegroundColor Red
	Write-Host ""
	Write-Warning "An unexpected error occurred: $($_.Exception.Message)"
	Write-Host ""
	Write-Ui -Message "Press any key to exit..." -Level "INFO"
	$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
	exit 1
}








