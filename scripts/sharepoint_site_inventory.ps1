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
	Write-Ui -Message "[Step 1/4] Installing/verifying Microsoft Graph modules..." -Level "INFO"
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
		} else {
			Write-Ui -Message "          No existing connection found" -Level "WARN"
		}
		
		Write-Host ""
		Write-Ui -Message "[Step 3/4] Initiating connection to Microsoft Graph..." -Level "INFO"
		Write-Ui -Message "          This will open a browser window for authentication" -Level "WARN"
		Write-Ui -Message "          Required permissions:" -Level "INFO"
		Write-Ui -Message "            - Sites.Read.All (Read all SharePoint sites)" -Level "INFO"
		Write-Ui -Message "            - Group.Read.All (Read group information)" -Level "INFO"
		Write-Ui -Message "            - Organization.Read.All (Read organization info)" -Level "INFO"
		Write-Host ""
		Write-Ui -Message "          Required roles:" -Level "INFO"
		Write-Ui -Message "            - Global Reader, SharePoint Administrator, or Global Administrator" -Level "INFO"
		Write-Host ""
		
		$scopes = @(
			"Sites.Read.All",
			"Group.Read.All",
			"Organization.Read.All"
		)
		
		Connect-MgGraph -Scopes $scopes -NoWelcome
		
		Write-Host ""
		Write-Ui -Message "[Step 4/4] Retrieving organization information..." -Level "INFO"
		
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
			$Script:SiteData = @()
			Write-Host ""
			Write-Host "============================================================" -ForegroundColor Green
			Write-Ui -Message "  [+] Disconnected Successfully" -Level "OK"
			Write-Host "============================================================" -ForegroundColor Green
			Write-Host ""
			Write-Ui -Message "Site data has been cleared." -Level "INFO"
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
		Write-Ui -Message "Not connected to Microsoft Graph. Please connect first." -Level "ERROR"
		Write-Host ""
		Write-Ui -Message "Press any key to return to menu..." -Level "INFO"
		$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
		return
	}
	
	try {
		Write-Ui -Message "Retrieving all SharePoint sites from Microsoft 365..." -Level "INFO"
		Write-Ui -Message "This may take a few moments depending on the number of sites..." -Level "INFO"
		Write-Host ""
		
		# Get all sites
		$allSites = Get-MgSite -All -Property WebUrl,DisplayName,Description,WebTemplate,GroupId,CreatedDateTime,LastModifiedDateTime -ErrorAction Stop
		
		if (-not $allSites -or $allSites.Count -eq 0) {
			Write-Ui -Message "No sites found in the tenant." -Level "WARN"
			Write-Host ""
			Write-Ui -Message "Press any key to return to menu..." -Level "INFO"
			$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
			return
		}
		
		Write-Ui -Message "Found $($allSites.Count) site(s). Processing site details..." -Level "OK"
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
		Write-Ui -Message "  [+] Successfully retrieved $($Script:SiteData.Count) sites" -Level "OK"
		Write-Host "============================================================" -ForegroundColor Green
		Write-Host ""
		
	} catch {
		Write-Host ""
		Write-Host "============================================================" -ForegroundColor Red
		Write-Ui -Message "  [-] Error retrieving sites" -Level "ERROR"
		Write-Host "============================================================" -ForegroundColor Red
		Write-Host ""
		Write-Warning "Error: $($_.Exception.Message)"
		Write-Host ""
		Write-Ui -Message "Press any key to return to menu..." -Level "INFO"
		$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
	}
}

function Show-SiteSummary {
	Show-Header "Site Summary"
	
	if ($Script:SiteData.Count -eq 0) {
		Write-Ui -Message "No site data available. Please retrieve sites first." -Level "WARN"
		Write-Host ""
		Write-Ui -Message "Press any key to return to menu..." -Level "INFO"
		$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
		return
	}
	
	$teamSites = ($Script:SiteData | Where-Object { $_.Template -eq "Team Site" }).Count
	$commSites = ($Script:SiteData | Where-Object { $_.Template -eq "Communication Site" }).Count
	$groupConnected = ($Script:SiteData | Where-Object { $_.ConnectedToGroup -eq $true }).Count
	$standalone = ($Script:SiteData | Where-Object { $_.ConnectedToGroup -eq $false }).Count
	
	Write-Ui -Message "SUMMARY STATISTICS" -Level "INFO"
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
	Write-Ui -Message "TOP 10 SITES (by Display Name)" -Level "INFO"
	Write-Host "------------------------------------------------------------" -ForegroundColor Gray
	Write-Host ""
	
	$topSites = $Script:SiteData | Sort-Object DisplayName | Select-Object -First 10
	foreach ($site in $topSites) {
		$typeColor = if ($site.ConnectedToGroup) { "Green" } else { "Yellow" }
		$ownerInfo = if ($site.OwnerCount -gt 0) { " ($($site.OwnerCount) owners)" } else { " (No owners)" }
		
		Write-Ui -Message "  $($site.DisplayName)" -Level "STEP"
		Write-Ui -Message "    URL: $($site.SiteURL)" -Level "INFO"
		Write-Host "    Type: $($site.SiteType)" -ForegroundColor $typeColor
		Write-Ui -Message "    Template: $($site.Template)" -Level "INFO"
		Write-Ui -Message "    Storage: $($site.StorageUsed)" -Level "INFO"
		Write-Ui -Message "    Owners: $ownerInfo" -Level "INFO"
		Write-Host ""
	}
	
	Write-Host "============================================================" -ForegroundColor DarkGray
	Write-Host ""
	Write-Ui -Message "Press any key to return to menu..." -Level "INFO"
	$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Export-ToTXT {
	Show-Header "Export to TXT Format"
	
	if ($Script:SiteData.Count -eq 0) {
		Write-Ui -Message "No site data available. Please retrieve sites first." -Level "WARN"
		Write-Host ""
		Write-Ui -Message "Press any key to return to menu..." -Level "INFO"
		$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
		return
	}
	
	try {
		Ensure-OutputFolder -Path $Script:OutputFolder
		$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
		$filename = "SharePoint_Site_Inventory_$timestamp.txt"
		$filepath = Join-Path $Script:OutputFolder $filename
		
		Write-Ui -Message "Exporting site data to TXT format..." -Level "INFO"
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
		Write-Ui -Message "  [+] Export completed successfully" -Level "OK"
		Write-Host "============================================================" -ForegroundColor Green
		Write-Host ""
		Write-Ui -Message "File saved to: $filepath" -Level "INFO"
		Write-Host ""
		
	} catch {
		Write-Host ""
		Write-Host "============================================================" -ForegroundColor Red
		Write-Ui -Message "  [-] Export failed" -Level "ERROR"
		Write-Host "============================================================" -ForegroundColor Red
		Write-Host ""
		Write-Warning "Error: $($_.Exception.Message)"
		Write-Host ""
	}
	
	Write-Ui -Message "Press any key to return to menu..." -Level "INFO"
	$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Export-ToCSV {
	Show-Header "Export to CSV Format"
	
	if ($Script:SiteData.Count -eq 0) {
		Write-Ui -Message "No site data available. Please retrieve sites first." -Level "WARN"
		Write-Host ""
		Write-Ui -Message "Press any key to return to menu..." -Level "INFO"
		$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
		return
	}
	
	try {
		Ensure-OutputFolder -Path $Script:OutputFolder
		$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
		$filename = "SharePoint_Site_Inventory_$timestamp.csv"
		$filepath = Join-Path $Script:OutputFolder $filename
		
		Write-Ui -Message "Exporting site data to CSV format..." -Level "INFO"
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
		Write-Ui -Message "  [+] Export completed successfully" -Level "OK"
		Write-Host "============================================================" -ForegroundColor Green
		Write-Host ""
		Write-Ui -Message "File saved to: $filepath" -Level "INFO"
		Write-Host ""
		
	} catch {
		Write-Host ""
		Write-Host "============================================================" -ForegroundColor Red
		Write-Ui -Message "  [-] Export failed" -Level "ERROR"
		Write-Host "============================================================" -ForegroundColor Red
		Write-Host ""
		Write-Warning "Error: $($_.Exception.Message)"
		Write-Host ""
	}
	
	Write-Ui -Message "Press any key to return to menu..." -Level "INFO"
	$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Export-ToHTML {
	Show-Header "Export to HTML Format"
	
	if ($Script:SiteData.Count -eq 0) {
		Write-Ui -Message "No site data available. Please retrieve sites first." -Level "WARN"
		Write-Host ""
		Write-Ui -Message "Press any key to return to menu..." -Level "INFO"
		$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
		return
	}
	
	try {
		Ensure-OutputFolder -Path $Script:OutputFolder
		$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
		$filename = "SharePoint_Site_Inventory_$timestamp.html"
		$filepath = Join-Path $Script:OutputFolder $filename
		
		Write-Ui -Message "Exporting site data to HTML format..." -Level "INFO"
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
		Write-Ui -Message "  [+] Export completed successfully" -Level "OK"
		Write-Host "============================================================" -ForegroundColor Green
		Write-Host ""
		Write-Ui -Message "File saved to: $filepath" -Level "INFO"
		Write-Host ""
		
	} catch {
		Write-Host ""
		Write-Host "============================================================" -ForegroundColor Red
		Write-Ui -Message "  [-] Export failed" -Level "ERROR"
		Write-Host "============================================================" -ForegroundColor Red
		Write-Host ""
		Write-Warning "Error: $($_.Exception.Message)"
		Write-Host ""
	}
	
	Write-Ui -Message "Press any key to return to menu..." -Level "INFO"
	$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Export-ToJSON {
	Show-Header "Export to JSON Format"
	
	if ($Script:SiteData.Count -eq 0) {
		Write-Ui -Message "No site data available. Please retrieve sites first." -Level "WARN"
		Write-Host ""
		Write-Ui -Message "Press any key to return to menu..." -Level "INFO"
		$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
		return
	}
	
	try {
		Ensure-OutputFolder -Path $Script:OutputFolder
		$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
		$filename = "SharePoint_Site_Inventory_$timestamp.json"
		$filepath = Join-Path $Script:OutputFolder $filename
		
		Write-Ui -Message "Exporting site data to JSON format..." -Level "INFO"
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
		Write-Ui -Message "  [+] Export completed successfully" -Level "OK"
		Write-Host "============================================================" -ForegroundColor Green
		Write-Host ""
		Write-Ui -Message "File saved to: $filepath" -Level "INFO"
		Write-Host ""
		
	} catch {
		Write-Host ""
		Write-Host "============================================================" -ForegroundColor Red
		Write-Ui -Message "  [-] Export failed" -Level "ERROR"
		Write-Host "============================================================" -ForegroundColor Red
		Write-Host ""
		Write-Warning "Error: $($_.Exception.Message)"
		Write-Host ""
	}
	
	Write-Ui -Message "Press any key to return to menu..." -Level "INFO"
	$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Show-Help {
	Show-Header "Help & Information"
	
	Write-Ui -Message "SHAREPOINT SITE COLLECTION INVENTORY" -Level "INFO"
	Write-Host "------------------------------------------------------------" -ForegroundColor Gray
	Write-Host ""
	Write-Ui -Message "This tool builds a complete map of your SharePoint environment" -Level "STEP"
	Write-Ui -Message "by extracting comprehensive information about all SharePoint" -Level "STEP"
	Write-Ui -Message "sites in your Microsoft 365 tenant." -Level "STEP"
	Write-Host ""
	Write-Ui -Message "FEATURES:" -Level "WARN"
	Write-Ui -Message "  - Complete site collection inventory" -Level "INFO"
	Write-Ui -Message "  - Site template identification (Team/Communication sites)" -Level "INFO"
	Write-Ui -Message "  - M365 Group connection status" -Level "INFO"
	Write-Ui -Message "  - Storage usage per site" -Level "INFO"
	Write-Ui -Message "  - Site ownership information" -Level "INFO"
	Write-Ui -Message "  - Last activity tracking" -Level "INFO"
	Write-Host ""
	Write-Ui -Message "EXPORT FORMATS:" -Level "WARN"
	Write-Ui -Message "  - TXT: Human-readable text format" -Level "INFO"
	Write-Ui -Message "  - CSV: Spreadsheet format for Excel/Google Sheets" -Level "INFO"
	Write-Ui -Message "  - HTML: Professional web report with styling" -Level "INFO"
	Write-Ui -Message "  - JSON: Clean JSON format for automation" -Level "INFO"
	Write-Host ""
	Write-Ui -Message "REQUIRED PERMISSIONS:" -Level "WARN"
	Write-Ui -Message "  - Sites.Read.All (Read all SharePoint sites)" -Level "INFO"
	Write-Ui -Message "  - Group.Read.All (Read group information)" -Level "INFO"
	Write-Ui -Message "  - Organization.Read.All (Read organization info)" -Level "INFO"
	Write-Host ""
	Write-Ui -Message "REQUIRED ROLES:" -Level "WARN"
	Write-Ui -Message "  - Global Reader, SharePoint Administrator, or Global Administrator" -Level "INFO"
	Write-Host ""
	Write-Ui -Message "USAGE:" -Level "WARN"
	Write-Ui -Message "  1. Connect to Microsoft Graph (Option 1)" -Level "INFO"
	Write-Ui -Message "  2. Retrieve all sites (Option 3)" -Level "INFO"
	Write-Ui -Message "  3. View summary or export reports (Options 4-8)" -Level "INFO"
	Write-Host ""
	Write-Ui -Message "For more information, visit: www.soulitek.co.il" -Level "INFO"
	Write-Host ""
	Write-Host "============================================================" -ForegroundColor DarkGray
	Write-Host ""
	Write-Ui -Message "Press any key to return to menu..." -Level "INFO"
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
			Write-Ui -Message "Organization: $($Script:TenantName)" -Level "INFO"
			Write-Ui -Message "Domain: $($Script:TenantDomain)" -Level "INFO"
		}
		Write-Ui -Message "Sites Retrieved: $siteCount" -Level "INFO"
		Write-Host ""
		Write-Host "============================================================" -ForegroundColor DarkGray
		Write-Host ""
		Write-Ui -Message "Select an option:" -Level "STEP"
		Write-Host ""
		Write-Ui -Message "  [1] Connect to Microsoft Graph" -Level "WARN"
		Write-Ui -Message "  [2] Disconnect from Current Tenant" -Level "WARN"
		Write-Ui -Message "  [3] Retrieve All Sites" -Level "WARN"
		Write-Ui -Message "  [4] View Site Summary" -Level "WARN"
		Write-Ui -Message "  [5] Export to TXT Format" -Level "WARN"
		Write-Ui -Message "  [6] Export to CSV Format" -Level "WARN"
		Write-Ui -Message "  [7] Export to HTML Format" -Level "WARN"
		Write-Ui -Message "  [8] Export to JSON Format" -Level "WARN"
		Write-Ui -Message "  [9] Help & Information" -Level "WARN"
		Write-Ui -Message "  [0] Exit" -Level "ERROR"
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
				Write-Ui -Message "Thank you for using SharePoint Site Collection Inventory!" -Level "INFO"
				Write-Host ""
				return 
			}
			default {
				Write-Host ""
				Write-Ui -Message "Invalid choice. Please try again." -Level "ERROR"
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
	Write-Ui -Message "  [-] An unexpected error occurred" -Level "ERROR"
	Write-Host "============================================================" -ForegroundColor Red
	Write-Host ""
	Write-Warning "Error: $($_.Exception.Message)"
	Write-Host ""
	Write-Ui -Message "Press any key to exit..." -Level "INFO"
	$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

