# ============================================================
# SharePoint Site Collection Inventory - SouliTEK Edition
# ============================================================
# Coded by: Soulitek.co.il | www.soulitek.co.il | letstalk@soulitek.co.il
# (C) 2025 SouliTEK - All Rights Reserved
# ============================================================

param(
	[string]$OutputFolder = (Join-Path $env:USERPROFILE "Desktop")
)

$Host.UI.RawUI.WindowTitle = "SharePoint Site Collection Inventory"

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

# Global variables
$Script:SiteData = @()
$Script:OutputFolder = $OutputFolder
$Script:Connected = $false
$Script:TenantDomain = "Unknown"
$Script:TenantName = "Unknown"

# Show-Header function - wrapper using Show-SouliTEKHeader from common module
function Show-Header {
	param([string]$Title = "SharePoint Site Collection Inventory", [ConsoleColor]$Color = 'Cyan')
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

function Connect-ToMicrosoftGraph {
	$connected = $false
	Show-Header "Connecting to Microsoft 365"
	
	# Use centralized module installation function
	Write-Host "[Step 1/4] Installing/verifying Microsoft Graph modules..." -ForegroundColor Cyan
	Write-Host ""
	
	$modulesToInstall = @(
		'Microsoft.Graph.Authentication',
		'Microsoft.Graph.Sites',
		'Microsoft.Graph.Groups',
		'Microsoft.Graph.Identity.DirectoryManagement'
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
		} else {
			Write-Host "          No existing connection found" -ForegroundColor Yellow
		}
		
		Write-Host ""
		Write-Host "[Step 3/4] Initiating connection to Microsoft Graph..." -ForegroundColor Cyan
		Write-Host "          This will open a browser window for authentication" -ForegroundColor Yellow
		Write-Host "          Required permissions:" -ForegroundColor Gray
		Write-Host "            - Sites.Read.All (Read all SharePoint sites)" -ForegroundColor Gray
		Write-Host "            - Group.Read.All (Read group information)" -ForegroundColor Gray
		Write-Host "            - Organization.Read.All (Read organization info)" -ForegroundColor Gray
		Write-Host ""
		Write-Host "          Required roles:" -ForegroundColor Gray
		Write-Host "            - Global Reader, SharePoint Administrator, or Global Administrator" -ForegroundColor Gray
		Write-Host ""
		
		$scopes = @(
			"Sites.Read.All",
			"Group.Read.All",
			"Organization.Read.All"
		)
		
		Connect-MgGraph -Scopes $scopes -NoWelcome
		
		Write-Host ""
		Write-Host "[Step 4/4] Retrieving organization information..." -ForegroundColor Cyan
		
		# Get organization/domain information
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
			$Script:SiteData = @()
			Write-Host ""
			Write-Host "============================================================" -ForegroundColor Green
			Write-Host "  [+] Disconnected Successfully" -ForegroundColor Green
			Write-Host "============================================================" -ForegroundColor Green
			Write-Host ""
			Write-Host "Site data has been cleared." -ForegroundColor Gray
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

function Get-SiteStorage {
	param([string]$SiteId)
	
	$storageBytes = 0
	try {
		$drives = Get-MgSiteDrive -SiteId $SiteId -ErrorAction SilentlyContinue
		if ($drives) {
			foreach ($drive in $drives) {
				try {
					$driveInfo = Get-MgDrive -DriveId $drive.Id -ErrorAction SilentlyContinue
					if ($driveInfo -and $driveInfo.Quota) {
						$used = $driveInfo.Quota.Used
						if ($used) {
							$storageBytes += $used
						}
					}
				} catch {
					# Silent fail for individual drive
				}
			}
		}
	} catch {
		# Silent fail - storage may not be available
	}
	
	# Convert to human-readable format
	if ($storageBytes -eq 0) {
		return "0 MB"
	} elseif ($storageBytes -lt 1MB) {
		return "$([math]::Round($storageBytes / 1KB, 2)) KB"
	} elseif ($storageBytes -lt 1GB) {
		return "$([math]::Round($storageBytes / 1MB, 2)) MB"
	} elseif ($storageBytes -lt 1TB) {
		return "$([math]::Round($storageBytes / 1GB, 2)) GB"
	} else {
		return "$([math]::Round($storageBytes / 1TB, 2)) TB"
	}
}

function Get-SiteOwners {
	param([string]$GroupId)
	
	$owners = @()
	if (-not $GroupId) {
		return $owners
	}
	
	try {
		$groupOwners = Get-MgGroupOwner -GroupId $GroupId -ErrorAction SilentlyContinue
		if ($groupOwners) {
			foreach ($owner in $groupOwners) {
				try {
					$user = Get-MgUser -UserId $owner.Id -Property UserPrincipalName,DisplayName -ErrorAction SilentlyContinue
					if ($user) {
						$owners += $user.UserPrincipalName
					}
				} catch {
					# Try as group
					try {
						$group = Get-MgGroup -GroupId $owner.Id -Property DisplayName -ErrorAction SilentlyContinue
						if ($group) {
							$owners += $group.DisplayName
						}
					} catch {
						# Skip if can't retrieve
					}
				}
			}
		}
	} catch {
		# Silent fail - owners may not be available
	}
	
	return $owners
}

function Get-SiteLastActivity {
	param([string]$SiteId)
	
	$lastActivity = $null
	try {
		$site = Get-MgSite -SiteId $SiteId -Property LastModifiedDateTime -ErrorAction SilentlyContinue
		if ($site -and $site.LastModifiedDateTime) {
			$lastActivity = $site.LastModifiedDateTime
		}
		
		# Also check drives for last modified
		$drives = Get-MgSiteDrive -SiteId $SiteId -ErrorAction SilentlyContinue
		if ($drives) {
			foreach ($drive in $drives) {
				try {
					$driveInfo = Get-MgDrive -DriveId $drive.Id -Property LastModifiedDateTime -ErrorAction SilentlyContinue
					if ($driveInfo -and $driveInfo.LastModifiedDateTime) {
						if (-not $lastActivity -or $driveInfo.LastModifiedDateTime -gt $lastActivity) {
							$lastActivity = $driveInfo.LastModifiedDateTime
						}
					}
				} catch {
					# Silent fail
				}
			}
		}
	} catch {
		# Silent fail
	}
	
	if ($lastActivity) {
		return $lastActivity.ToString("yyyy-MM-dd")
	}
	return "Never"
}

function Get-AllSites {
	Show-Header "Retrieving SharePoint Sites"
	
	if (-not $Script:Connected) {
		Write-Host "Not connected to Microsoft Graph. Please connect first." -ForegroundColor Red
		Write-Host ""
		Write-Host "Press any key to return to menu..." -ForegroundColor Cyan
		$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
		return
	}
	
	try {
		Write-Host "Retrieving all SharePoint sites from Microsoft 365..." -ForegroundColor Cyan
		Write-Host "This may take a few moments depending on the number of sites..." -ForegroundColor Gray
		Write-Host ""
		
		# Get all sites
		$allSites = Get-MgSite -All -Property WebUrl,DisplayName,Description,WebTemplate,GroupId,CreatedDateTime,LastModifiedDateTime -ErrorAction Stop
		
		if (-not $allSites -or $allSites.Count -eq 0) {
			Write-Host "No sites found in the tenant." -ForegroundColor Yellow
			Write-Host ""
			Write-Host "Press any key to return to menu..." -ForegroundColor Cyan
			$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
			return
		}
		
		Write-Host "Found $($allSites.Count) site(s). Processing site details..." -ForegroundColor Green
		Write-Host ""
		
		$Script:SiteData = @()
		$processedCount = 0
		
		foreach ($site in $allSites) {
			$processedCount++
			Write-Progress -Activity "Processing Sites" -Status "Site $processedCount of $($allSites.Count): $($site.DisplayName)" -PercentComplete (($processedCount / $allSites.Count) * 100)
			
			# Determine site template
			$template = "Unknown"
			if ($site.WebTemplate) {
				switch ($site.WebTemplate) {
					"GROUP#0" { $template = "Team Site" }
					"SITEPAGEPUBLISHING#0" { $template = "Communication Site" }
					default { $template = $site.WebTemplate }
				}
			}
			
			# Determine site type
			$siteType = "Standalone Site"
			$connectedToGroup = $false
			$groupId = $null
			if ($site.GroupId) {
				$siteType = "Connected to M365 Group"
				$connectedToGroup = $true
				$groupId = $site.GroupId
			}
			
			# Get storage
			$storageUsed = Get-SiteStorage -SiteId $site.Id
			
			# Get owners
			$owners = Get-SiteOwners -GroupId $groupId
			
			# Get last activity
			$lastActivity = Get-SiteLastActivity -SiteId $site.Id
			
			# Format created date
			$createdDate = "Unknown"
			if ($site.CreatedDateTime) {
				$createdDate = $site.CreatedDateTime.ToString("yyyy-MM-dd")
			}
			
			$Script:SiteData += [PSCustomObject]@{
				SiteURL = $site.WebUrl
				DisplayName = if ($site.DisplayName) { $site.DisplayName } else { "No Name" }
				Template = $template
				SiteType = $siteType
				ConnectedToGroup = $connectedToGroup
				GroupId = if ($groupId) { $groupId } else { "N/A" }
				StorageUsed = $storageUsed
				Owners = $owners
				OwnerCount = $owners.Count
				LastActivityDate = $lastActivity
				CreatedDate = $createdDate
			}
		}
		
		Write-Progress -Activity "Processing Sites" -Completed
		
		Write-Host "============================================================" -ForegroundColor Green
		Write-Host "  [+] Successfully retrieved $($Script:SiteData.Count) sites" -ForegroundColor Green
		Write-Host "============================================================" -ForegroundColor Green
		Write-Host ""
		
	} catch {
		Write-Host ""
		Write-Host "============================================================" -ForegroundColor Red
		Write-Host "  [-] Error retrieving sites" -ForegroundColor Red
		Write-Host "============================================================" -ForegroundColor Red
		Write-Host ""
		Write-Warning "Error: $($_.Exception.Message)"
		Write-Host ""
		Write-Host "Press any key to return to menu..." -ForegroundColor Cyan
		$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
	}
}

function Show-SiteSummary {
	Show-Header "Site Summary"
	
	if ($Script:SiteData.Count -eq 0) {
		Write-Host "No site data available. Please retrieve sites first." -ForegroundColor Yellow
		Write-Host ""
		Write-Host "Press any key to return to menu..." -ForegroundColor Cyan
		$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
		return
	}
	
	$teamSites = ($Script:SiteData | Where-Object { $_.Template -eq "Team Site" }).Count
	$commSites = ($Script:SiteData | Where-Object { $_.Template -eq "Communication Site" }).Count
	$groupConnected = ($Script:SiteData | Where-Object { $_.ConnectedToGroup -eq $true }).Count
	$standalone = ($Script:SiteData | Where-Object { $_.ConnectedToGroup -eq $false }).Count
	
	Write-Host "SUMMARY STATISTICS" -ForegroundColor Cyan
	Write-Host "------------------------------------------------------------" -ForegroundColor Gray
	Write-Host ""
	if ($Script:TenantDomain -ne "Unknown") {
		Write-SummaryLine "Organization" $Script:TenantName "Cyan"
		Write-SummaryLine "Domain" $Script:TenantDomain "Cyan"
		Write-Host ""
	}
	Write-SummaryLine "Total Sites" $Script:SiteData.Count "White"
	Write-SummaryLine "Team Sites" "$teamSites ($([math]::Round(($teamSites / $Script:SiteData.Count) * 100, 2))%)" "Cyan"
	Write-SummaryLine "Communication Sites" "$commSites ($([math]::Round(($commSites / $Script:SiteData.Count) * 100, 2))%)" "Cyan"
	Write-Host ""
	Write-SummaryLine "Group Connected" "$groupConnected ($([math]::Round(($groupConnected / $Script:SiteData.Count) * 100, 2))%)" "Green"
	Write-SummaryLine "Standalone" "$standalone ($([math]::Round(($standalone / $Script:SiteData.Count) * 100, 2))%)" "Yellow"
	Write-Host ""
	Write-Host "TOP 10 SITES (by Display Name)" -ForegroundColor Cyan
	Write-Host "------------------------------------------------------------" -ForegroundColor Gray
	Write-Host ""
	
	$topSites = $Script:SiteData | Sort-Object DisplayName | Select-Object -First 10
	foreach ($site in $topSites) {
		$typeColor = if ($site.ConnectedToGroup) { "Green" } else { "Yellow" }
		$ownerInfo = if ($site.OwnerCount -gt 0) { " ($($site.OwnerCount) owners)" } else { " (No owners)" }
		
		Write-Host "  $($site.DisplayName)" -ForegroundColor White
		Write-Host "    URL: $($site.SiteURL)" -ForegroundColor Gray
		Write-Host "    Type: $($site.SiteType)" -ForegroundColor $typeColor
		Write-Host "    Template: $($site.Template)" -ForegroundColor Gray
		Write-Host "    Storage: $($site.StorageUsed)" -ForegroundColor Gray
		Write-Host "    Owners: $ownerInfo" -ForegroundColor Gray
		Write-Host ""
	}
	
	Write-Host "============================================================" -ForegroundColor DarkGray
	Write-Host ""
	Write-Host "Press any key to return to menu..." -ForegroundColor Cyan
	$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Export-ToTXT {
	Show-Header "Export to TXT Format"
	
	if ($Script:SiteData.Count -eq 0) {
		Write-Host "No site data available. Please retrieve sites first." -ForegroundColor Yellow
		Write-Host ""
		Write-Host "Press any key to return to menu..." -ForegroundColor Cyan
		$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
		return
	}
	
	try {
		Ensure-OutputFolder -Path $Script:OutputFolder
		$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
		$filename = "SharePoint_Site_Inventory_$timestamp.txt"
		$filepath = Join-Path $Script:OutputFolder $filename
		
		Write-Host "Exporting site data to TXT format..." -ForegroundColor Cyan
		Write-Host ""
		
		$content = @()
		$content += "============================================================"
		$content += "SharePoint Site Collection Inventory"
		$content += "============================================================"
		$content += ""
		$content += "Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
		if ($Script:TenantDomain -ne "Unknown") {
			$content += "Organization: $($Script:TenantName)"
			$content += "Domain: $($Script:TenantDomain)"
		}
		$content += "Total Sites: $($Script:SiteData.Count)"
		$content += ""
		$content += "============================================================"
		$content += ""
		
		$siteNumber = 1
		foreach ($site in $Script:SiteData) {
			$content += "Site #$siteNumber"
			$content += "------------------------------------------------------------"
			$content += "Site URL: $($site.SiteURL)"
			$content += "Display Name: $($site.DisplayName)"
			$content += "Template: $($site.Template)"
			$content += "Site Type: $($site.SiteType)"
			$content += "Connected to Group: $($site.ConnectedToGroup)"
			if ($site.ConnectedToGroup) {
				$content += "Group ID: $($site.GroupId)"
			}
			$content += "Storage Used: $($site.StorageUsed)"
			$content += "Owner Count: $($site.OwnerCount)"
			if ($site.Owners.Count -gt 0) {
				$content += "Owners:"
				foreach ($owner in $site.Owners) {
					$content += "  - $owner"
				}
			} else {
				$content += "Owners: Not Available"
			}
			$content += "Last Activity Date: $($site.LastActivityDate)"
			$content += "Created Date: $($site.CreatedDate)"
			$content += ""
			$siteNumber++
		}
		
		$content | Out-File -FilePath $filepath -Encoding UTF8
		
		Write-Host "============================================================" -ForegroundColor Green
		Write-Host "  [+] Export completed successfully" -ForegroundColor Green
		Write-Host "============================================================" -ForegroundColor Green
		Write-Host ""
		Write-Host "File saved to: $filepath" -ForegroundColor Cyan
		Write-Host ""
		
	} catch {
		Write-Host ""
		Write-Host "============================================================" -ForegroundColor Red
		Write-Host "  [-] Export failed" -ForegroundColor Red
		Write-Host "============================================================" -ForegroundColor Red
		Write-Host ""
		Write-Warning "Error: $($_.Exception.Message)"
		Write-Host ""
	}
	
	Write-Host "Press any key to return to menu..." -ForegroundColor Cyan
	$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Export-ToCSV {
	Show-Header "Export to CSV Format"
	
	if ($Script:SiteData.Count -eq 0) {
		Write-Host "No site data available. Please retrieve sites first." -ForegroundColor Yellow
		Write-Host ""
		Write-Host "Press any key to return to menu..." -ForegroundColor Cyan
		$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
		return
	}
	
	try {
		Ensure-OutputFolder -Path $Script:OutputFolder
		$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
		$filename = "SharePoint_Site_Inventory_$timestamp.csv"
		$filepath = Join-Path $Script:OutputFolder $filename
		
		Write-Host "Exporting site data to CSV format..." -ForegroundColor Cyan
		Write-Host ""
		
		# Prepare data for CSV export
		$csvData = $Script:SiteData | ForEach-Object {
			[PSCustomObject]@{
				SiteURL = $_.SiteURL
				DisplayName = $_.DisplayName
				Template = $_.Template
				SiteType = $_.SiteType
				ConnectedToGroup = $_.ConnectedToGroup
				GroupId = $_.GroupId
				StorageUsed = $_.StorageUsed
				OwnerCount = $_.OwnerCount
				Owners = ($_.Owners -join "; ")
				LastActivityDate = $_.LastActivityDate
				CreatedDate = $_.CreatedDate
			}
		}
		
		$csvData | Export-Csv -Path $filepath -NoTypeInformation -Encoding UTF8
		
		Write-Host "============================================================" -ForegroundColor Green
		Write-Host "  [+] Export completed successfully" -ForegroundColor Green
		Write-Host "============================================================" -ForegroundColor Green
		Write-Host ""
		Write-Host "File saved to: $filepath" -ForegroundColor Cyan
		Write-Host ""
		
	} catch {
		Write-Host ""
		Write-Host "============================================================" -ForegroundColor Red
		Write-Host "  [-] Export failed" -ForegroundColor Red
		Write-Host "============================================================" -ForegroundColor Red
		Write-Host ""
		Write-Warning "Error: $($_.Exception.Message)"
		Write-Host ""
	}
	
	Write-Host "Press any key to return to menu..." -ForegroundColor Cyan
	$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Export-ToHTML {
	Show-Header "Export to HTML Format"
	
	if ($Script:SiteData.Count -eq 0) {
		Write-Host "No site data available. Please retrieve sites first." -ForegroundColor Yellow
		Write-Host ""
		Write-Host "Press any key to return to menu..." -ForegroundColor Cyan
		$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
		return
	}
	
	try {
		Ensure-OutputFolder -Path $Script:OutputFolder
		$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
		$filename = "SharePoint_Site_Inventory_$timestamp.html"
		$filepath = Join-Path $Script:OutputFolder $filename
		
		Write-Host "Exporting site data to HTML format..." -ForegroundColor Cyan
		Write-Host ""
		
		$html = @"
<!DOCTYPE html>
<html>
<head>
	<title>SharePoint Site Collection Inventory</title>
	<style>
		body { font-family: Arial, sans-serif; margin: 20px; background-color: #f5f5f5; }
		.header { background-color: #667eea; color: white; padding: 20px; border-radius: 5px; margin-bottom: 20px; }
		.summary { background-color: white; padding: 15px; border-radius: 5px; margin-bottom: 20px; }
		table { width: 100%; border-collapse: collapse; background-color: white; }
		th { background-color: #667eea; color: white; padding: 12px; text-align: left; }
		td { padding: 10px; border-bottom: 1px solid #ddd; }
		tr:hover { background-color: #f5f5f5; }
		.connected { color: green; font-weight: bold; }
		.standalone { color: orange; font-weight: bold; }
	</style>
</head>
<body>
	<div class="header">
		<h1>SharePoint Site Collection Inventory</h1>
		<p>Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</p>
"@
		
		if ($Script:TenantDomain -ne "Unknown") {
			$html += @"
		<p>Organization: $($Script:TenantName)</p>
		<p>Domain: $($Script:TenantDomain)</p>
"@
		}
		
		$html += @"
	</div>
	<div class="summary">
		<h2>Summary</h2>
		<p><strong>Total Sites:</strong> $($Script:SiteData.Count)</p>
	</div>
	<table>
		<thead>
			<tr>
				<th>Site URL</th>
				<th>Display Name</th>
				<th>Template</th>
				<th>Site Type</th>
				<th>Storage Used</th>
				<th>Owner Count</th>
				<th>Last Activity</th>
				<th>Created Date</th>
			</tr>
		</thead>
		<tbody>
"@
		
		foreach ($site in $Script:SiteData) {
			$typeClass = if ($site.ConnectedToGroup) { "connected" } else { "standalone" }
			$ownersList = if ($site.Owners.Count -gt 0) { ($site.Owners -join ", ") } else { "Not Available" }
			
			$html += @"
			<tr>
				<td><a href="$($site.SiteURL)" target="_blank">$($site.SiteURL)</a></td>
				<td>$($site.DisplayName)</td>
				<td>$($site.Template)</td>
				<td class="$typeClass">$($site.SiteType)</td>
				<td>$($site.StorageUsed)</td>
				<td>$($site.OwnerCount)</td>
				<td>$($site.LastActivityDate)</td>
				<td>$($site.CreatedDate)</td>
			</tr>
"@
		}
		
		$html += @"
		</tbody>
	</table>
</body>
</html>
"@
		
		$html | Out-File -FilePath $filepath -Encoding UTF8
		
		Write-Host "============================================================" -ForegroundColor Green
		Write-Host "  [+] Export completed successfully" -ForegroundColor Green
		Write-Host "============================================================" -ForegroundColor Green
		Write-Host ""
		Write-Host "File saved to: $filepath" -ForegroundColor Cyan
		Write-Host ""
		
	} catch {
		Write-Host ""
		Write-Host "============================================================" -ForegroundColor Red
		Write-Host "  [-] Export failed" -ForegroundColor Red
		Write-Host "============================================================" -ForegroundColor Red
		Write-Host ""
		Write-Warning "Error: $($_.Exception.Message)"
		Write-Host ""
	}
	
	Write-Host "Press any key to return to menu..." -ForegroundColor Cyan
	$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Export-ToJSON {
	Show-Header "Export to JSON Format"
	
	if ($Script:SiteData.Count -eq 0) {
		Write-Host "No site data available. Please retrieve sites first." -ForegroundColor Yellow
		Write-Host ""
		Write-Host "Press any key to return to menu..." -ForegroundColor Cyan
		$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
		return
	}
	
	try {
		Ensure-OutputFolder -Path $Script:OutputFolder
		$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
		$filename = "SharePoint_Site_Inventory_$timestamp.json"
		$filepath = Join-Path $Script:OutputFolder $filename
		
		Write-Host "Exporting site data to JSON format..." -ForegroundColor Cyan
		Write-Host ""
		
		# Prepare JSON data
		$jsonData = @{
			Generated = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
			Organization = if ($Script:TenantDomain -ne "Unknown") { $Script:TenantName } else { "Unknown" }
			Domain = $Script:TenantDomain
			TotalSites = $Script:SiteData.Count
			Sites = @()
		}
		
		foreach ($site in $Script:SiteData) {
			$jsonData.Sites += @{
				SiteURL = $site.SiteURL
				DisplayName = $site.DisplayName
				Template = $site.Template
				SiteType = $site.SiteType
				ConnectedToGroup = $site.ConnectedToGroup
				GroupId = $site.GroupId
				StorageUsed = $site.StorageUsed
				Owners = $site.Owners
				OwnerCount = $site.OwnerCount
				LastActivityDate = $site.LastActivityDate
				CreatedDate = $site.CreatedDate
			}
		}
		
		$jsonData | ConvertTo-Json -Depth 10 | Out-File -FilePath $filepath -Encoding UTF8
		
		Write-Host "============================================================" -ForegroundColor Green
		Write-Host "  [+] Export completed successfully" -ForegroundColor Green
		Write-Host "============================================================" -ForegroundColor Green
		Write-Host ""
		Write-Host "File saved to: $filepath" -ForegroundColor Cyan
		Write-Host ""
		
	} catch {
		Write-Host ""
		Write-Host "============================================================" -ForegroundColor Red
		Write-Host "  [-] Export failed" -ForegroundColor Red
		Write-Host "============================================================" -ForegroundColor Red
		Write-Host ""
		Write-Warning "Error: $($_.Exception.Message)"
		Write-Host ""
	}
	
	Write-Host "Press any key to return to menu..." -ForegroundColor Cyan
	$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Show-Help {
	Show-Header "Help & Information"
	
	Write-Host "SHAREPOINT SITE COLLECTION INVENTORY" -ForegroundColor Cyan
	Write-Host "------------------------------------------------------------" -ForegroundColor Gray
	Write-Host ""
	Write-Host "This tool builds a complete map of your SharePoint environment" -ForegroundColor White
	Write-Host "by extracting comprehensive information about all SharePoint" -ForegroundColor White
	Write-Host "sites in your Microsoft 365 tenant." -ForegroundColor White
	Write-Host ""
	Write-Host "FEATURES:" -ForegroundColor Yellow
	Write-Host "  - Complete site collection inventory" -ForegroundColor Gray
	Write-Host "  - Site template identification (Team/Communication sites)" -ForegroundColor Gray
	Write-Host "  - M365 Group connection status" -ForegroundColor Gray
	Write-Host "  - Storage usage per site" -ForegroundColor Gray
	Write-Host "  - Site ownership information" -ForegroundColor Gray
	Write-Host "  - Last activity tracking" -ForegroundColor Gray
	Write-Host ""
	Write-Host "EXPORT FORMATS:" -ForegroundColor Yellow
	Write-Host "  - TXT: Human-readable text format" -ForegroundColor Gray
	Write-Host "  - CSV: Spreadsheet format for Excel/Google Sheets" -ForegroundColor Gray
	Write-Host "  - HTML: Professional web report with styling" -ForegroundColor Gray
	Write-Host "  - JSON: Clean JSON format for automation" -ForegroundColor Gray
	Write-Host ""
	Write-Host "REQUIRED PERMISSIONS:" -ForegroundColor Yellow
	Write-Host "  - Sites.Read.All (Read all SharePoint sites)" -ForegroundColor Gray
	Write-Host "  - Group.Read.All (Read group information)" -ForegroundColor Gray
	Write-Host "  - Organization.Read.All (Read organization info)" -ForegroundColor Gray
	Write-Host ""
	Write-Host "REQUIRED ROLES:" -ForegroundColor Yellow
	Write-Host "  - Global Reader, SharePoint Administrator, or Global Administrator" -ForegroundColor Gray
	Write-Host ""
	Write-Host "USAGE:" -ForegroundColor Yellow
	Write-Host "  1. Connect to Microsoft Graph (Option 1)" -ForegroundColor Gray
	Write-Host "  2. Retrieve all sites (Option 3)" -ForegroundColor Gray
	Write-Host "  3. View summary or export reports (Options 4-8)" -ForegroundColor Gray
	Write-Host ""
	Write-Host "For more information, visit: www.soulitek.co.il" -ForegroundColor Cyan
	Write-Host ""
	Write-Host "============================================================" -ForegroundColor DarkGray
	Write-Host ""
	Write-Host "Press any key to return to menu..." -ForegroundColor Cyan
	$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Show-MainMenu {
	do {
		Show-Header "Main Menu"
		
		$connectionStatus = if ($Script:Connected) { "Connected" } else { "Not Connected" }
		$connectionColor = if ($Script:Connected) { "Green" } else { "Red" }
		$siteCount = $Script:SiteData.Count
		
		Write-Host "Connection Status: " -NoNewline -ForegroundColor Gray
		Write-Host $connectionStatus -ForegroundColor $connectionColor
		if ($Script:Connected -and $Script:TenantDomain -ne "Unknown") {
			Write-Host "Organization: $($Script:TenantName)" -ForegroundColor Gray
			Write-Host "Domain: $($Script:TenantDomain)" -ForegroundColor Gray
		}
		Write-Host "Sites Retrieved: $siteCount" -ForegroundColor Gray
		Write-Host ""
		Write-Host "============================================================" -ForegroundColor DarkGray
		Write-Host ""
		Write-Host "Select an option:" -ForegroundColor White
		Write-Host ""
		Write-Host "  [1] Connect to Microsoft Graph" -ForegroundColor Yellow
		Write-Host "  [2] Disconnect from Current Tenant" -ForegroundColor Yellow
		Write-Host "  [3] Retrieve All Sites" -ForegroundColor Yellow
		Write-Host "  [4] View Site Summary" -ForegroundColor Yellow
		Write-Host "  [5] Export to TXT Format" -ForegroundColor Yellow
		Write-Host "  [6] Export to CSV Format" -ForegroundColor Yellow
		Write-Host "  [7] Export to HTML Format" -ForegroundColor Yellow
		Write-Host "  [8] Export to JSON Format" -ForegroundColor Yellow
		Write-Host "  [9] Help & Information" -ForegroundColor Yellow
		Write-Host "  [0] Exit" -ForegroundColor Red
		Write-Host ""
		Write-Host "============================================================" -ForegroundColor DarkGray
		
		$choice = Read-Host "Enter your choice (0-9)"
		
		switch ($choice) {
			'1' { Connect-ToMicrosoftGraph }
			'2' { Disconnect-FromMicrosoftGraph }
			'3' { Get-AllSites }
			'4' { Show-SiteSummary }
			'5' { Export-ToTXT }
			'6' { Export-ToCSV }
			'7' { Export-ToHTML }
			'8' { Export-ToJSON }
			'9' { Show-Help }
			'0' { 
				Write-Host ""
				Write-Host "Thank you for using SharePoint Site Collection Inventory!" -ForegroundColor Cyan
				Write-Host ""
				return 
			}
			default {
				Write-Host ""
				Write-Host "Invalid choice. Please try again." -ForegroundColor Red
				Start-Sleep -Seconds 2
			}
		}
	} while ($true)
}

# Main execution
try {
	Show-MainMenu
} catch {
	Write-Host ""
	Write-Host "============================================================" -ForegroundColor Red
	Write-Host "  [-] An unexpected error occurred" -ForegroundColor Red
	Write-Host "============================================================" -ForegroundColor Red
	Write-Host ""
	Write-Warning "Error: $($_.Exception.Message)"
	Write-Host ""
	Write-Host "Press any key to exit..." -ForegroundColor Cyan
	$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

