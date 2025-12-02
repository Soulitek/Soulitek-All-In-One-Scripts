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
			Write-Host "  WARNING: ExchangeOnlineManagement Module Not Loaded" -ForegroundColor Yellow
			Write-Host "============================================================" -ForegroundColor Yellow
			Write-Host ""
			Write-Host "The ExchangeOnlineManagement module is not currently loaded." -ForegroundColor Yellow
			Write-Host ""
			Write-Host "To install the module, run:" -ForegroundColor Cyan
			Write-Host "  Install-Module -Name ExchangeOnlineManagement -Scope CurrentUser" -ForegroundColor White
			Write-Host ""
			Write-Host "To import the module, run:" -ForegroundColor Cyan
			Write-Host "  Import-Module ExchangeOnlineManagement" -ForegroundColor White
			Write-Host ""
			Write-Host "Or connect to Exchange Online (this will auto-import the module):" -ForegroundColor Cyan
			Write-Host "  Connect-ExchangeOnline" -ForegroundColor White
			Write-Host ""
			return $false
		}
		return $true
	}
	catch {
		Write-Host ""
		Write-Host "Error checking for ExchangeOnlineManagement module: $($_.Exception.Message)" -ForegroundColor Red
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
		Write-Host "Finding calendar folder for mailbox: $MailboxIdentity" -ForegroundColor Cyan
		Write-Host ""
		
		# Get all folders for the mailbox
		$folders = Get-MailboxFolderStatistics -Identity $MailboxIdentity -ErrorAction Stop
		
		# Find the folder where FolderType equals 'Calendar'
		$calendarFolder = $folders | Where-Object { $_.FolderType -eq 'Calendar' } | Select-Object -First 1
		
		if ($null -eq $calendarFolder) {
			Write-Host "Calendar folder not found for mailbox: $MailboxIdentity" -ForegroundColor Red
			return $null
		}
		
		# Extract the folder name from the path
		# FolderPath format is typically: "/Calendar" or "/לוח שנה" etc.
		$folderName = $calendarFolder.Name
		
		Write-Host "Found calendar folder: '$folderName'" -ForegroundColor Green
		Write-Host ""
		
		return $folderName
	}
	catch {
		Write-Host "Error finding calendar folder: $($_.Exception.Message)" -ForegroundColor Red
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
		Write-Host "Retrieving calendar permissions..." -ForegroundColor Cyan
		Write-Host ""
		
		# Get calendar folder permissions
		$permissions = Get-MailboxFolderPermission -Identity "$MailboxIdentity`:\$CalendarFolderName" -ErrorAction Stop
		
		if ($null -eq $permissions -or $permissions.Count -eq 0) {
			Write-Host "No calendar permissions found for mailbox: $MailboxIdentity" -ForegroundColor Yellow
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
		Write-Host "  Calendar Permissions for: $MailboxIdentity" -ForegroundColor Green
		Write-Host "============================================================" -ForegroundColor Green
		Write-Host ""
		
		$results | Format-Table -AutoSize -Property User, AccessRights, SharingPermissionFlags
		
		Write-Host ""
		Write-Host "Total permissions found: $($results.Count)" -ForegroundColor Cyan
		Write-Host ""
	}
	catch {
		Write-Host ""
		Write-Host "============================================================" -ForegroundColor Red
		Write-Host "  Error Retrieving Calendar Permissions" -ForegroundColor Red
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
		Write-Host "Press any key to exit..." -ForegroundColor Cyan
		$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
		return
	}
	
	# Prompt for target email
	Write-Host "Enter the target email address to audit calendar permissions:" -ForegroundColor Cyan
	Write-Host ""
	$targetEmail = Read-Host "Target Email"
	
	if ([string]::IsNullOrWhiteSpace($targetEmail)) {
		Write-Host ""
		Write-Host "No email address provided. Exiting." -ForegroundColor Red
		Write-Host ""
		Write-Host "Press any key to exit..." -ForegroundColor Cyan
		$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
		return
	}
	
	Write-Host ""
	
	# Try to find the calendar folder
	$calendarFolderName = Get-CalendarFolderName -MailboxIdentity $targetEmail
	
	if ([string]::IsNullOrWhiteSpace($calendarFolderName)) {
		Write-Host ""
		Write-Host "============================================================" -ForegroundColor Red
		Write-Host "  Error: Could not find calendar folder" -ForegroundColor Red
		Write-Host "============================================================" -ForegroundColor Red
		Write-Host ""
		Write-Host "Possible reasons:" -ForegroundColor Yellow
		Write-Host "  - Mailbox does not exist: $targetEmail" -ForegroundColor Gray
		Write-Host "  - Mailbox does not have a calendar folder" -ForegroundColor Gray
		Write-Host "  - Insufficient permissions to access the mailbox" -ForegroundColor Gray
		Write-Host "  - Not connected to Exchange Online" -ForegroundColor Gray
		Write-Host ""
		Write-Host "Press any key to exit..." -ForegroundColor Cyan
		$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
		return
	}
	
	# Get calendar permissions
	Get-CalendarPermissions -MailboxIdentity $targetEmail -CalendarFolderName $calendarFolderName
	
	Write-Host "Press any key to exit..." -ForegroundColor Cyan
	$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# ============================================================
# MAIN EXECUTION
# ============================================================

try {
	Start-CalendarPermissionsAudit
}
catch {
	Write-Host ""
	Write-Host "============================================================" -ForegroundColor Red
	Write-Host "  Fatal Error" -ForegroundColor Red
	Write-Host "============================================================" -ForegroundColor Red
	Write-Host ""
	Write-Warning "An unexpected error occurred: $($_.Exception.Message)"
	Write-Host ""
	Write-Host "Press any key to exit..." -ForegroundColor Cyan
	$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
	exit 1
}

