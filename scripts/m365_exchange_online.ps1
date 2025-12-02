# ============================================================
# Microsoft 365 Exchange Online - SouliTEK Edition
# ============================================================
# Coded by: Soulitek.co.il | www.soulitek.co.il | letstalk@soulitek.co.il
# (C) 2025 SouliTEK - All Rights Reserved
# ============================================================

param(
	[string]$OutputFolder = (Join-Path $env:USERPROFILE "Desktop")
)

$Host.UI.RawUI.WindowTitle = "Microsoft 365 Exchange Online"

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
$Script:MailboxData = @()
$Script:OutputFolder = $OutputFolder
$Script:Connected = $false
$Script:TenantDomain = "Unknown"
$Script:TenantName = "Unknown"

# Show-Header function - wrapper using Show-SouliTEKHeader from common module
function Show-Header {
	param([string]$Title = "Microsoft 365 Exchange Online", [ConsoleColor]$Color = 'Cyan')
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

function Connect-ToExchangeOnline {
	$connected = $false
	Show-Header "Connecting to Exchange Online"
	
	# Use centralized module installation function
	Write-Host "[Step 1/3] Installing/verifying Exchange Online Management module..." -ForegroundColor Cyan
	Write-Host ""
	
	if (-not (Install-SouliTEKModule -ModuleName "ExchangeOnlineManagement")) {
		Write-Host ""
		Write-Host "[-] Failed to install ExchangeOnlineManagement module" -ForegroundColor Red
		Write-Host ""
		Write-Host "Press any key to return to menu..." -ForegroundColor Cyan
		$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
		return $false
	}
	
	Write-Host ""
	Write-Host "[+] Exchange Online Management module ready" -ForegroundColor Green
	
	try {
		Write-Host ""
		Write-Host "[Step 2/3] Checking existing connection..." -ForegroundColor Cyan
		
		# Check if already connected by trying to get organization info
		try {
			$orgInfo = Get-OrganizationConfig -ErrorAction SilentlyContinue
			if ($orgInfo) {
				Write-Host "          [+] Already connected to Exchange Online" -ForegroundColor Green
				
				if ($Script:TenantDomain -eq "Unknown") {
					# Try to get organization name from current session
					try {
						$session = Get-PSSession | Where-Object { $_.ConfigurationName -eq "Microsoft.Exchange" } | Select-Object -First 1
						if ($session -and $session.ComputerName) {
							$Script:TenantDomain = $session.ComputerName
							$Script:TenantName = $session.ComputerName
						} else {
							# Use default if can't determine
							$Script:TenantDomain = "Connected"
							$Script:TenantName = "Connected"
						}
					} catch {
						# Use default if can't determine
						$Script:TenantDomain = "Connected"
						$Script:TenantName = "Connected"
					}
				}
				Write-Host "          Organization: $($Script:TenantName)" -ForegroundColor Gray
			
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
					Disconnect-ExchangeOnline -Confirm:$false -ErrorAction SilentlyContinue | Out-Null
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
		} catch {
			# Not connected - this is expected, continue to new connection
		}
		Write-Host "          No existing connection found" -ForegroundColor Yellow
		
		Write-Host ""
		Write-Host "[Step 3/3] Initiating connection to Exchange Online..." -ForegroundColor Cyan
		Write-Host "          This will open a browser window for authentication" -ForegroundColor Yellow
		Write-Host "          Required permissions:" -ForegroundColor Gray
		Write-Host "            - Exchange Administrator or Global Administrator role" -ForegroundColor Gray
		Write-Host "            - Mailbox.Read permission" -ForegroundColor Gray
		Write-Host ""
		Write-Host "          Opening authentication browser window..." -ForegroundColor Cyan
		
		# Connect to Exchange Online
		Connect-ExchangeOnline -ShowProgress $true -ErrorAction Stop | Out-Null
		
		Write-Host "          [+] Authentication successful!" -ForegroundColor Green
		
		# Get organization information
		try {
			$session = Get-PSSession | Where-Object { $_.ConfigurationName -eq "Microsoft.Exchange" } | Select-Object -First 1
			if ($session -and $session.ComputerName) {
				$Script:TenantDomain = $session.ComputerName
				$Script:TenantName = $session.ComputerName
				Write-Host "          Organization: $($Script:TenantName)" -ForegroundColor Gray
			}
		} catch {
			# Silent fail - not critical
		}
		
		Write-Host ""
		Write-Host "============================================================" -ForegroundColor Green
		Write-Host "  [+] Exchange Online Connected Successfully" -ForegroundColor Green
		Write-Host "============================================================" -ForegroundColor Green
		Write-Host ""
		$Script:Connected = $true
		$connected = $true
	} catch {
		Write-Host ""
		Write-Host "============================================================" -ForegroundColor Red
		Write-Host "  [-] Exchange Online Connection Failed" -ForegroundColor Red
		Write-Host "============================================================" -ForegroundColor Red
		Write-Host ""
		Write-Warning "Connection failed: $($_.Exception.Message)"
		Write-Host ""
		Write-Host "Troubleshooting steps:" -ForegroundColor Yellow
		Write-Host "  1. Check your internet connection" -ForegroundColor Gray
		Write-Host "  2. Verify you have Exchange Administrator or Global Administrator role" -ForegroundColor Gray
		Write-Host "  3. Try running the script again" -ForegroundColor Gray
		Write-Host ""
	}
	return $connected
}

function Disconnect-FromExchangeOnline {
	Show-Header "Disconnect from Exchange Online"
	
	if (-not $Script:Connected) {
		Write-Host "Not currently connected to Exchange Online." -ForegroundColor Yellow
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
	Write-Host ""
	Write-Host "------------------------------------------------------------" -ForegroundColor Yellow
	Write-Host "Are you sure you want to disconnect? (Y/N): " -NoNewline -ForegroundColor Yellow
	$confirm = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
	Write-Host $confirm.Character
	Write-Host ""
	
	if ($confirm.Character -eq 'Y' -or $confirm.Character -eq 'y') {
		try {
			Write-Host "Disconnecting from Exchange Online..." -ForegroundColor Cyan
			Disconnect-ExchangeOnline -Confirm:$false -ErrorAction Stop | Out-Null
			$Script:Connected = $false
			$Script:TenantDomain = "Unknown"
			$Script:TenantName = "Unknown"
			$Script:MailboxData = @()
			Write-Host ""
			Write-Host "============================================================" -ForegroundColor Green
			Write-Host "  [+] Disconnected Successfully" -ForegroundColor Green
			Write-Host "============================================================" -ForegroundColor Green
			Write-Host ""
			Write-Host "Mailbox data has been cleared." -ForegroundColor Gray
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

function Get-AllMailboxes {
	Show-Header "Retrieving Exchange Online Mailboxes"
	
	if (-not $Script:Connected) {
		Write-Host "Not connected to Exchange Online. Please connect first." -ForegroundColor Red
		Write-Host ""
		Write-Host "Press any key to return to menu..." -ForegroundColor Cyan
		$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
		return
	}
	
	try {
		Write-Host "Retrieving all mailboxes from Exchange Online..." -ForegroundColor Cyan
		Write-Host "This may take a few moments depending on the number of mailboxes..." -ForegroundColor Gray
		Write-Host ""
		
		# Get all mailboxes
		$allMailboxes = Get-Mailbox -ResultSize Unlimited -ErrorAction Stop
		
		if (-not $allMailboxes -or $allMailboxes.Count -eq 0) {
			Write-Host "No mailboxes found in the tenant." -ForegroundColor Yellow
			Write-Host ""
			Write-Host "Press any key to return to menu..." -ForegroundColor Cyan
			$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
			return
		}
		
		Write-Host "Found $($allMailboxes.Count) mailbox(es). Processing mailbox details..." -ForegroundColor Green
		Write-Host ""
		
		$Script:MailboxData = @()
		$processedCount = 0
		
		foreach ($mailbox in $allMailboxes) {
			$processedCount++
			Write-Progress -Activity "Processing Mailboxes" -Status "Mailbox $processedCount of $($allMailboxes.Count): $($mailbox.DisplayName)" -PercentComplete (($processedCount / $allMailboxes.Count) * 100)
			
			# Get mailbox statistics for size and item count
			$mailboxStats = $null
			try {
				$mailboxStats = Get-MailboxStatistics -Identity $mailbox.Identity -ErrorAction SilentlyContinue
			} catch {
				# Silent fail - stats may not be available
			}
			
			# Get mailbox permissions (SendOnBehalf)
			$sendOnBehalf = @()
			try {
				if ($mailbox.GrantSendOnBehalfTo) {
					foreach ($delegate in $mailbox.GrantSendOnBehalfTo) {
						$sendOnBehalf += $delegate.ToString()
					}
				}
			} catch {
				# Silent fail
			}
			
			# Determine mailbox type
			$mailboxType = "User"
			if ($mailbox.RecipientTypeDetails -like "*Shared*") {
				$mailboxType = "Shared"
			} elseif ($mailbox.RecipientTypeDetails -like "*Room*" -or $mailbox.RecipientTypeDetails -like "*Equipment*") {
				$mailboxType = "Resource"
			}
			
			# Get aliases
			$aliases = @()
			if ($mailbox.EmailAddresses) {
				foreach ($emailAddr in $mailbox.EmailAddresses) {
					if ($emailAddr -like "smtp:*" -and $emailAddr -notlike "SMTP:*") {
						$alias = $emailAddr -replace "smtp:", ""
						if ($alias -ne $mailbox.PrimarySmtpAddress) {
							$aliases += $alias
						}
					}
				}
			}
			
			# Format mailbox size
			$mailboxSizeGB = "0.00"
			$itemCount = 0
			if ($mailboxStats) {
				if ($mailboxStats.TotalItemSize) {
					$sizeBytes = [long]($mailboxStats.TotalItemSize.Value.ToString().Split("(")[1].Split(" ")[0].Replace(",", ""))
					$mailboxSizeGB = [math]::Round($sizeBytes / 1GB, 2)
				}
				if ($mailboxStats.ItemCount) {
					$itemCount = $mailboxStats.ItemCount
				}
			}
			
			# Get last activity time (LastLogonTime from stats)
			$lastActivity = "Never"
			if ($mailboxStats -and $mailboxStats.LastLogonTime) {
				$lastActivity = $mailboxStats.LastLogonTime.ToString("yyyy-MM-dd HH:mm:ss")
			}
			
			# Get last mailbox logon (LastLogonTime)
			$lastLogon = "Never"
			if ($mailboxStats -and $mailboxStats.LastLogonTime) {
				$lastLogon = $mailboxStats.LastLogonTime.ToString("yyyy-MM-dd HH:mm:ss")
			}
			
			# Get last mailbox access (LastAccessTime from stats)
			$lastAccess = "Never"
			if ($mailboxStats -and $mailboxStats.LastAccessTime) {
				$lastAccess = $mailboxStats.LastAccessTime.ToString("yyyy-MM-dd HH:mm:ss")
			}
			
			# Check license status (from mailbox properties)
			$licenseStatus = "Unknown"
			if ($mailbox.IsLicensed) {
				$licenseStatus = "Licensed"
			} else {
				$licenseStatus = "Unlicensed"
			}
			
			# Get protocol settings
			$protocols = @{
				IMAP = if ($mailbox.ImapEnabled) { "Enabled" } else { "Disabled" }
				POP = if ($mailbox.PopEnabled) { "Enabled" } else { "Disabled" }
				EWS = if ($mailbox.EwsEnabled) { "Enabled" } else { "Disabled" }
				ActiveSync = if ($mailbox.ActiveSyncEnabled) { "Enabled" } else { "Disabled" }
				SMTPAuth = if ($mailbox.SmtpClientAuthenticationDisabled) { "Disabled" } else { "Enabled" }
				MAPI = if ($mailbox.MAPIEnabled) { "Enabled" } else { "Disabled" }
			}
			
			$Script:MailboxData += [PSCustomObject]@{
				DisplayName = $mailbox.DisplayName
				PrimarySmtpAddress = $mailbox.PrimarySmtpAddress
				Aliases = $aliases -join "; "
				AliasesCount = $aliases.Count
				LicenseStatus = $licenseStatus
				IsLicensed = $mailbox.IsLicensed
				MailboxType = $mailboxType
				RecipientTypeDetails = $mailbox.RecipientTypeDetails
				IMAPEnabled = $protocols.IMAP
				POPEnabled = $protocols.POP
				EWSEnabled = $protocols.EWS
				ActiveSyncEnabled = $protocols.ActiveSync
				SMTPAuthEnabled = $protocols.SMTPAuth
				MAPIEnabled = $protocols.MAPI
				LastActivityTime = $lastActivity
				LastMailboxLogon = $lastLogon
				LastMailboxAccess = $lastAccess
				MailboxSizeGB = $mailboxSizeGB
				ItemCount = $itemCount
				SendOnBehalf = $sendOnBehalf -join "; "
				SendOnBehalfCount = $sendOnBehalf.Count
			}
		}
		
		Write-Progress -Activity "Processing Mailboxes" -Completed
		
		Write-Host "============================================================" -ForegroundColor Green
		Write-Host "  [+] Successfully retrieved $($Script:MailboxData.Count) mailboxes" -ForegroundColor Green
		Write-Host "============================================================" -ForegroundColor Green
		Write-Host ""
		
	} catch {
		Write-Host ""
		Write-Host "============================================================" -ForegroundColor Red
		Write-Host "  [-] Error retrieving mailboxes" -ForegroundColor Red
		Write-Host "============================================================" -ForegroundColor Red
		Write-Host ""
		Write-Warning "Error: $($_.Exception.Message)"
		Write-Host ""
		Write-Host "Press any key to return to menu..." -ForegroundColor Cyan
		$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
	}
}

function Show-MailboxSummary {
	Show-Header "Mailbox Summary"
	
	if ($Script:MailboxData.Count -eq 0) {
		Write-Host "No mailbox data available. Please retrieve mailboxes first." -ForegroundColor Yellow
		Write-Host ""
		Write-Host "Press any key to return to menu..." -ForegroundColor Cyan
		$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
		return
	}
	
	$userMailboxes = ($Script:MailboxData | Where-Object { $_.MailboxType -eq "User" }).Count
	$sharedMailboxes = ($Script:MailboxData | Where-Object { $_.MailboxType -eq "Shared" }).Count
	$resourceMailboxes = ($Script:MailboxData | Where-Object { $_.MailboxType -eq "Resource" }).Count
	$licensedMailboxes = ($Script:MailboxData | Where-Object { $_.IsLicensed -eq $true }).Count
	$unlicensedMailboxes = ($Script:MailboxData | Where-Object { $_.IsLicensed -eq $false }).Count
	
	$totalSizeGB = ($Script:MailboxData | ForEach-Object { [double]$_.MailboxSizeGB } | Measure-Object -Sum).Sum
	$totalItems = ($Script:MailboxData | ForEach-Object { $_.ItemCount } | Measure-Object -Sum).Sum
	
	Write-Host "SUMMARY STATISTICS" -ForegroundColor Cyan
	Write-Host "------------------------------------------------------------" -ForegroundColor Gray
	Write-Host ""
	if ($Script:TenantDomain -ne "Unknown") {
		Write-SummaryLine "Organization" $Script:TenantName "Cyan"
		Write-SummaryLine "Domain" $Script:TenantDomain "Cyan"
		Write-Host ""
	}
	Write-SummaryLine "Total Mailboxes" $Script:MailboxData.Count "White"
	Write-SummaryLine "User Mailboxes" "$userMailboxes ($([math]::Round(($userMailboxes / $Script:MailboxData.Count) * 100, 2))%)" "Green"
	Write-SummaryLine "Shared Mailboxes" "$sharedMailboxes ($([math]::Round(($sharedMailboxes / $Script:MailboxData.Count) * 100, 2))%)" "Yellow"
	Write-SummaryLine "Resource Mailboxes" "$resourceMailboxes ($([math]::Round(($resourceMailboxes / $Script:MailboxData.Count) * 100, 2))%)" "Cyan"
	Write-Host ""
	Write-SummaryLine "Licensed Mailboxes" "$licensedMailboxes ($([math]::Round(($licensedMailboxes / $Script:MailboxData.Count) * 100, 2))%)" "Green"
	Write-SummaryLine "Unlicensed Mailboxes" "$unlicensedMailboxes ($([math]::Round(($unlicensedMailboxes / $Script:MailboxData.Count) * 100, 2))%)" "Yellow"
	Write-Host ""
	Write-SummaryLine "Total Mailbox Size" "$([math]::Round($totalSizeGB, 2)) GB" "White"
	Write-SummaryLine "Total Item Count" "$totalItems items" "White"
	Write-Host ""
	Write-Host "TOP 10 MAILBOXES (by Display Name)" -ForegroundColor Cyan
	Write-Host "------------------------------------------------------------" -ForegroundColor Gray
	Write-Host ""
	
	$topMailboxes = $Script:MailboxData | Sort-Object DisplayName | Select-Object -First 10
	foreach ($mailbox in $topMailboxes) {
		$typeColor = switch ($mailbox.MailboxType) {
			"User" { "Green" }
			"Shared" { "Yellow" }
			"Resource" { "Cyan" }
			default { "White" }
		}
		
		Write-Host "  $($mailbox.DisplayName)" -ForegroundColor White
		Write-Host "    Email: $($mailbox.PrimarySmtpAddress)" -ForegroundColor Gray
		Write-Host "    Type: " -NoNewline -ForegroundColor Gray
		Write-Host "$($mailbox.MailboxType)" -ForegroundColor $typeColor
		Write-Host "    License: $($mailbox.LicenseStatus)" -ForegroundColor $(if ($mailbox.IsLicensed) { "Green" } else { "Yellow" })
		Write-Host "    Size: $($mailbox.MailboxSizeGB) GB ($($mailbox.ItemCount) items)" -ForegroundColor Gray
		if ($mailbox.AliasesCount -gt 0) {
			Write-Host "    Aliases: $($mailbox.AliasesCount) alias(es)" -ForegroundColor Cyan
		}
		if ($mailbox.SendOnBehalfCount -gt 0) {
			Write-Host "    SendOnBehalf: $($mailbox.SendOnBehalfCount) delegate(s)" -ForegroundColor Yellow
		}
		Write-Host ""
	}
	
	if ($Script:MailboxData.Count -gt 10) {
		Write-Host "  ... and $($Script:MailboxData.Count - 10) more mailboxes" -ForegroundColor Gray
		Write-Host ""
	}
	
	Write-Host "Press any key to return to menu..." -ForegroundColor Cyan
	$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Export-MailboxListTxt {
	if ($Script:MailboxData.Count -eq 0) {
		Write-Host "No mailbox data available. Please retrieve mailboxes first." -ForegroundColor Yellow
		Write-Host ""
		Write-Host "Press any key to return to menu..." -ForegroundColor Cyan
		$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
		return
	}
	
	Show-Header "Export Mailbox List - TXT Format"
	
	Ensure-OutputFolder -Path $Script:OutputFolder
	$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
	$fileName = "Exchange_Online_Mailboxes_$timestamp.txt"
	$filePath = Join-Path $Script:OutputFolder $fileName
	
	try {
		$output = @()
		$output += "============================================================"
		$output += "Microsoft 365 Exchange Online Mailbox Report"
		$output += "Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
		if ($Script:TenantDomain -ne "Unknown") {
			$output += "Organization: $($Script:TenantName)"
			$output += "Domain: $($Script:TenantDomain)"
		}
		$output += "Total Mailboxes: $($Script:MailboxData.Count)"
		$output += "============================================================"
		$output += ""
		$output += "SouliTEK - IT Solutions for your business"
		$output += "www.soulitek.co.il | letstalk@soulitek.co.il"
		$output += ""
		$output += "============================================================"
		$output += ""
		
		foreach ($mailbox in $Script:MailboxData | Sort-Object DisplayName) {
			$output += "Display Name: $($mailbox.DisplayName)"
			$output += "Primary Email: $($mailbox.PrimarySmtpAddress)"
			$output += "Aliases: $(if ($mailbox.Aliases) { $mailbox.Aliases } else { 'None' })"
			$output += "License Status: $($mailbox.LicenseStatus)"
			$output += "Mailbox Type: $($mailbox.MailboxType)"
			$output += "IMAP: $($mailbox.IMAPEnabled)"
			$output += "POP: $($mailbox.POPEnabled)"
			$output += "EWS: $($mailbox.EWSEnabled)"
			$output += "ActiveSync: $($mailbox.ActiveSyncEnabled)"
			$output += "SMTP AUTH: $($mailbox.SMTPAuthEnabled)"
			$output += "MAPI: $($mailbox.MAPIEnabled)"
			$output += "Last Activity Time: $($mailbox.LastActivityTime)"
			$output += "Last Mailbox Logon: $($mailbox.LastMailboxLogon)"
			$output += "Last Mailbox Access: $($mailbox.LastMailboxAccess)"
			$output += "Mailbox Size: $($mailbox.MailboxSizeGB) GB"
			$output += "Item Count: $($mailbox.ItemCount)"
			$output += "SendOnBehalf: $(if ($mailbox.SendOnBehalf) { $mailbox.SendOnBehalf } else { 'None' })"
			$output += "------------------------------------------------------------"
			$output += ""
		}
		
		$output | Out-File -FilePath $filePath -Encoding UTF8 -Force
		
		Write-Host "Export completed successfully!" -ForegroundColor Green
		Write-Host ""
		Write-Host "File saved to:" -ForegroundColor Cyan
		Write-Host $filePath -ForegroundColor White
		Write-Host ""
		Write-Host "Total mailboxes exported: $($Script:MailboxData.Count)" -ForegroundColor Green
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

function Export-MailboxListCsv {
	if ($Script:MailboxData.Count -eq 0) {
		Write-Host "No mailbox data available. Please retrieve mailboxes first." -ForegroundColor Yellow
		Write-Host ""
		Write-Host "Press any key to return to menu..." -ForegroundColor Cyan
		$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
		return
	}
	
	Show-Header "Export Mailbox List - CSV Format"
	
	Ensure-OutputFolder -Path $Script:OutputFolder
	$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
	$fileName = "Exchange_Online_Mailboxes_$timestamp.csv"
	$filePath = Join-Path $Script:OutputFolder $fileName
	
	try {
		$Script:MailboxData | Sort-Object DisplayName | Export-Csv -Path $filePath -NoTypeInformation -Encoding UTF8 -Force
		
		Write-Host "Export completed successfully!" -ForegroundColor Green
		Write-Host ""
		Write-Host "File saved to:" -ForegroundColor Cyan
		Write-Host $filePath -ForegroundColor White
		Write-Host ""
		Write-Host "Total mailboxes exported: $($Script:MailboxData.Count)" -ForegroundColor Green
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

function Export-MailboxListHtml {
	if ($Script:MailboxData.Count -eq 0) {
		Write-Host "No mailbox data available. Please retrieve mailboxes first." -ForegroundColor Yellow
		Write-Host ""
		Write-Host "Press any key to return to menu..." -ForegroundColor Cyan
		$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
		return
	}
	
	Show-Header "Export Mailbox List - HTML Format"
	
	Ensure-OutputFolder -Path $Script:OutputFolder
	$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
	$fileName = "Exchange_Online_Mailboxes_$timestamp.html"
	$filePath = Join-Path $Script:OutputFolder $fileName
	
	try {
		$userMailboxes = ($Script:MailboxData | Where-Object { $_.MailboxType -eq "User" }).Count
		$sharedMailboxes = ($Script:MailboxData | Where-Object { $_.MailboxType -eq "Shared" }).Count
		$resourceMailboxes = ($Script:MailboxData | Where-Object { $_.MailboxType -eq "Resource" }).Count
		$licensedMailboxes = ($Script:MailboxData | Where-Object { $_.IsLicensed -eq $true }).Count
		$totalSizeGB = ($Script:MailboxData | ForEach-Object { [double]$_.MailboxSizeGB } | Measure-Object -Sum).Sum
		
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
.badge-licensed { background: #dbeafe; color: #1e40af; }
.meta { margin: 20px 0; padding: 15px; background: #f8f9fa; border-left: 4px solid #2b6cb0; border-radius: 4px; }
.footer { margin-top: 40px; padding-top: 20px; border-top: 2px solid #e2e8f0; text-align: center; color: #718096; font-size: 12px; }
</style>
"@
		
		$statsHtml = @"
<div class="stats">
	<div class="stat-box">
		<h3>Total Mailboxes</h3>
		<p class="number">$($Script:MailboxData.Count)</p>
	</div>
	<div class="stat-box" style="background: linear-gradient(135deg, #10b981 0%, #059669 100%);">
		<h3>User Mailboxes</h3>
		<p class="number">$userMailboxes</p>
	</div>
	<div class="stat-box" style="background: linear-gradient(135deg, #f59e0b 0%, #d97706 100%);">
		<h3>Shared Mailboxes</h3>
		<p class="number">$sharedMailboxes</p>
	</div>
	<div class="stat-box" style="background: linear-gradient(135deg, #3b82f6 0%, #2563eb 100%);">
		<h3>Licensed</h3>
		<p class="number">$licensedMailboxes</p>
	</div>
	<div class="stat-box" style="background: linear-gradient(135deg, #8b5cf6 0%, #7c3aed 100%);">
		<h3>Total Size</h3>
		<p class="number">$([math]::Round($totalSizeGB, 2)) GB</p>
	</div>
</div>
"@
		
		$rows = foreach ($mailbox in $Script:MailboxData | Sort-Object DisplayName) {
			$licenseBadge = if ($mailbox.IsLicensed) { '<span class="badge badge-licensed">Licensed</span>' } else { '<span class="badge badge-disabled">Unlicensed</span>' }
			$imapBadge = if ($mailbox.IMAPEnabled -eq "Enabled") { '<span class="badge badge-enabled">Enabled</span>' } else { '<span class="badge badge-disabled">Disabled</span>' }
			$popBadge = if ($mailbox.POPEnabled -eq "Enabled") { '<span class="badge badge-enabled">Enabled</span>' } else { '<span class="badge badge-disabled">Disabled</span>' }
			$ewsBadge = if ($mailbox.EWSEnabled -eq "Enabled") { '<span class="badge badge-enabled">Enabled</span>' } else { '<span class="badge badge-disabled">Disabled</span>' }
			$activesyncBadge = if ($mailbox.ActiveSyncEnabled -eq "Enabled") { '<span class="badge badge-enabled">Enabled</span>' } else { '<span class="badge badge-disabled">Disabled</span>' }
			$smtpBadge = if ($mailbox.SMTPAuthEnabled -eq "Enabled") { '<span class="badge badge-enabled">Enabled</span>' } else { '<span class="badge badge-disabled">Disabled</span>' }
			$mapiBadge = if ($mailbox.MAPIEnabled -eq "Enabled") { '<span class="badge badge-enabled">Enabled</span>' } else { '<span class="badge badge-disabled">Disabled</span>' }
			
			@"
<tr>
	<td>$($mailbox.DisplayName)</td>
	<td>$($mailbox.PrimarySmtpAddress)</td>
	<td>$(if ($mailbox.Aliases) { $mailbox.Aliases } else { 'None' })</td>
	<td>$licenseBadge</td>
	<td>$($mailbox.MailboxType)</td>
	<td>$imapBadge</td>
	<td>$popBadge</td>
	<td>$ewsBadge</td>
	<td>$activesyncBadge</td>
	<td>$smtpBadge</td>
	<td>$mapiBadge</td>
	<td>$($mailbox.LastActivityTime)</td>
	<td>$($mailbox.LastMailboxLogon)</td>
	<td>$($mailbox.LastMailboxAccess)</td>
	<td>$($mailbox.MailboxSizeGB) GB</td>
	<td>$($mailbox.ItemCount)</td>
	<td>$(if ($mailbox.SendOnBehalf) { $mailbox.SendOnBehalf } else { 'None' })</td>
</tr>
"@
		}
		
		$html = @"
<!DOCTYPE html>
<html>
<head>
	<meta charset="utf-8">
	<title>Exchange Online Mailbox Report</title>
	$style
</head>
<body>
	<div class="container">
		<h1>Microsoft 365 Exchange Online Mailbox Report</h1>
		<div class="meta">
			<strong>Generated:</strong> $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')<br>
			$(if ($Script:TenantDomain -ne "Unknown") { "<strong>Organization:</strong> $($Script:TenantName)<br><strong>Domain:</strong> $($Script:TenantDomain)<br>" })
			<strong>Total Mailboxes:</strong> $($Script:MailboxData.Count)
		</div>
		$statsHtml
		<h2>Mailbox Details</h2>
		<table class="table">
			<thead>
				<tr>
					<th>Display Name</th>
					<th>Primary Email</th>
					<th>Aliases</th>
					<th>License Status</th>
					<th>Mailbox Type</th>
					<th>IMAP</th>
					<th>POP</th>
					<th>EWS</th>
					<th>ActiveSync</th>
					<th>SMTP AUTH</th>
					<th>MAPI</th>
					<th>Last Activity</th>
					<th>Last Logon</th>
					<th>Last Access</th>
					<th>Size (GB)</th>
					<th>Item Count</th>
					<th>SendOnBehalf</th>
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
		Write-Host "Total mailboxes exported: $($Script:MailboxData.Count)" -ForegroundColor Green
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

function Show-Help {
	Show-Header "Help & Information"
	
	Write-Host "MICROSOFT 365 EXCHANGE ONLINE TOOL" -ForegroundColor Cyan
	Write-Host "------------------------------------------------------------" -ForegroundColor Gray
	Write-Host ""
	Write-Host "This tool retrieves and lists all mailboxes in your Exchange Online tenant" -ForegroundColor White
	Write-Host "with comprehensive information including:" -ForegroundColor White
	Write-Host ""
	Write-Host "  - Display name and primary email address" -ForegroundColor Gray
	Write-Host "  - Email aliases" -ForegroundColor Gray
	Write-Host "  - License status (Licensed/Unlicensed)" -ForegroundColor Gray
	Write-Host "  - Mailbox type (User/Shared/Resource)" -ForegroundColor Gray
	Write-Host "  - Protocol settings (IMAP, POP, EWS, ActiveSync, SMTP AUTH, MAPI)" -ForegroundColor Gray
	Write-Host "  - Last activity time, last logon, and last access" -ForegroundColor Gray
	Write-Host "  - Mailbox size (GB) and item count" -ForegroundColor Gray
	Write-Host "  - SendOnBehalf permissions" -ForegroundColor Gray
	Write-Host ""
	Write-Host "REQUIREMENTS" -ForegroundColor Cyan
	Write-Host "------------------------------------------------------------" -ForegroundColor Gray
	Write-Host ""
	Write-Host "  - Exchange Online Management PowerShell module" -ForegroundColor Gray
	Write-Host "  - Exchange Administrator or Global Administrator role" -ForegroundColor Gray
	Write-Host "  - Required permissions:" -ForegroundColor Gray
	Write-Host "    * Mailbox.Read" -ForegroundColor Yellow
	Write-Host "    * Organization.Read" -ForegroundColor Yellow
	Write-Host ""
	Write-Host "USAGE" -ForegroundColor Cyan
	Write-Host "------------------------------------------------------------" -ForegroundColor Gray
	Write-Host ""
	Write-Host "  1. Connect to Exchange Online" -ForegroundColor White
	Write-Host "     - First-time users will need to authenticate via browser" -ForegroundColor Gray
	Write-Host "     - Grant permissions when prompted" -ForegroundColor Gray
	Write-Host "     - If already connected, you can keep or switch tenants" -ForegroundColor Gray
	Write-Host ""
	Write-Host "  2. Disconnect from Current Tenant" -ForegroundColor White
	Write-Host "     - Disconnects from the current Exchange Online tenant" -ForegroundColor Gray
	Write-Host "     - Clears all cached mailbox data" -ForegroundColor Gray
	Write-Host "     - Use this to switch to a different tenant" -ForegroundColor Gray
	Write-Host ""
	Write-Host "  3. Retrieve All Mailboxes" -ForegroundColor White
	Write-Host "     - Fetches all mailboxes from your Exchange Online tenant" -ForegroundColor Gray
	Write-Host "     - May take a few moments for large tenants" -ForegroundColor Gray
	Write-Host ""
	Write-Host "  4. View Summary" -ForegroundColor White
	Write-Host "     - Displays statistics and top 10 mailboxes" -ForegroundColor Gray
	Write-Host ""
	Write-Host "  5-7. Export Reports" -ForegroundColor White
	Write-Host "     - TXT: Human-readable text format" -ForegroundColor Gray
	Write-Host "     - CSV: Spreadsheet format for Excel/Google Sheets" -ForegroundColor Gray
	Write-Host "     - HTML: Professional web report with styling" -ForegroundColor Gray
	Write-Host ""
	Write-Host "SECURITY NOTES" -ForegroundColor Cyan
	Write-Host "------------------------------------------------------------" -ForegroundColor Gray
	Write-Host ""
	Write-Host "  - This tool only reads mailbox information (read-only)" -ForegroundColor Gray
	Write-Host "  - No modifications are made to mailboxes" -ForegroundColor Gray
	Write-Host "  - All data is stored locally on your computer" -ForegroundColor Gray
	Write-Host "  - Authentication tokens are managed by Exchange Online" -ForegroundColor Gray
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
	Show-Header "Microsoft 365 Exchange Online"
	
	$status = if ($Script:Connected) { "Connected" } else { "Not Connected" }
	$statusColor = if ($Script:Connected) { "Green" } else { "Red" }
	$mailboxCount = if ($Script:MailboxData.Count -gt 0) { " ($($Script:MailboxData.Count) mailboxes loaded)" } else { "" }
	
	Write-Host "Connection Status: " -NoNewline -ForegroundColor Gray
	Write-Host "$status" -ForegroundColor $statusColor
	if ($Script:Connected -and $Script:TenantDomain -ne "Unknown") {
		Write-Host "Organization: " -NoNewline -ForegroundColor Gray
		Write-Host "$($Script:TenantName)" -ForegroundColor Cyan
		Write-Host "Domain: " -NoNewline -ForegroundColor Gray
		Write-Host "$($Script:TenantDomain)" -ForegroundColor Cyan
	}
	Write-Host "Mailbox Data: " -NoNewline -ForegroundColor Gray
	Write-Host "$($Script:MailboxData.Count) mailboxes$mailboxCount" -ForegroundColor $(if ($Script:MailboxData.Count -gt 0) { "Green" } else { "Yellow" })
	Write-Host ""
	Write-Host "============================================================" -ForegroundColor Cyan
	Write-Host ""
	Write-Host "  1. Connect to Exchange Online" -ForegroundColor White
	Write-Host "  2. Disconnect from Current Tenant" -ForegroundColor White
	Write-Host "  3. Retrieve All Mailboxes" -ForegroundColor White
	Write-Host "  4. View Mailbox Summary" -ForegroundColor White
	Write-Host "  5. Export Report - TXT Format" -ForegroundColor White
	Write-Host "  6. Export Report - CSV Format" -ForegroundColor White
	Write-Host "  7. Export Report - HTML Format" -ForegroundColor White
	Write-Host "  8. Help & Information" -ForegroundColor White
	Write-Host "  0. Exit" -ForegroundColor White
	Write-Host ""
	Write-Host "============================================================" -ForegroundColor Cyan
	Write-Host ""
	Write-Host "Please select an option (0-8): " -NoNewline -ForegroundColor Yellow
}

# ============================================================
# EXIT MESSAGE
# ============================================================

# Show-ExitMessage function - using Show-SouliTEKExitMessage from common module
function Show-ExitMessage {
	# Disconnect if connected
	try {
		if ($Script:Connected) {
			Write-Host "Disconnecting from Exchange Online..." -ForegroundColor Cyan
			Disconnect-ExchangeOnline -Confirm:$false -ErrorAction SilentlyContinue | Out-Null
		}
	} catch { }
	
	Show-SouliTEKExitMessage -ScriptPath $PSCommandPath -ToolName "SouliTEK Microsoft 365 Exchange Online Tool"
}

# Main execution loop
while ($true) {
	Show-Menu
	$choice = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
	Write-Host $choice.Character
	
	switch ($choice.Character) {
		'1' { Connect-ToExchangeOnline }
		'2' { Disconnect-FromExchangeOnline }
		'3' { Get-AllMailboxes }
		'4' { Show-MailboxSummary }
		'5' { Export-MailboxListTxt }
		'6' { Export-MailboxListCsv }
		'7' { Export-MailboxListHtml }
		'8' { Show-Help }
		'0' {
			Show-ExitMessage
			exit
		}
		default {
			Write-Host ""
			Write-Host "Invalid option. Please select 0-8." -ForegroundColor Red
			Write-Host ""
			Write-Host "Press any key to continue..." -ForegroundColor Cyan
			$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
		}
	}
}

