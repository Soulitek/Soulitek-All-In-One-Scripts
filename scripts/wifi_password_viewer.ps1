# ============================================================
# WiFi Password Viewer - Professional Tool - by Soulitek.co.il
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
# This tool allows you to view and backup WiFi passwords
# that are saved on your Windows computer.
# 
# Features: View All Networks | Search Specific Network
#           Export to File | Current Network Only
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
# LEGAL NOTICE:
# This tool should only be used on your own computer or with
# explicit permission from the computer owner. Unauthorized
# access to WiFi passwords may be illegal in your jurisdiction.
# 
# ============================================================

# Import SouliTEK Common Functions
$CommonPath = Join-Path (Split-Path -Parent $PSScriptRoot) "modules\SouliTEK-Common.ps1"
if (Test-Path $CommonPath) {
    . $CommonPath
} else {
    Write-Warning "SouliTEK Common Functions not found at: $CommonPath"
    Write-Warning "Some functions may not work properly."
}

# Function to get all WiFi profiles
function Get-WiFiProfiles {
    $output = netsh wlan show profiles

    $profiles = @(
        foreach ($line in $output) {
            if ($line -match "All User Profile\s+:\s+(.+)") {
                $matches[1].Trim()
            }
        }
    )

    return $profiles
}

# Function to get WiFi password for a specific profile
function Get-WiFiPassword {
    param([string]$ProfileName)
    
    $output = netsh wlan show profile name="$ProfileName" key=clear
    $password = $null
    
    foreach ($line in $output) {
        if ($line -match "Key Content\s+:\s+(.+)") {
            $password = $matches[1].Trim()
            break
        }
    }
    
    return $password
}

# Function to get current connected network
function Get-CurrentNetwork {
    $output = netsh wlan show interfaces
    $currentSSID = $null
    
    foreach ($line in $output) {
        if ($line -match "^\s+SSID\s+:\s+(.+)$") {
            $currentSSID = $matches[1].Trim()
            break
        }
    }
    
    return $currentSSID
}

# Function to display header - uses centralized module function
function Show-Header {
    Clear-Host
    Show-ScriptBanner -ScriptName "WiFi Password Viewer" -Purpose "View and backup WiFi passwords saved on Windows computer"
    Write-Host ""
}

# Function to view all WiFi passwords
function Show-AllPasswords {
    Show-Header
    Show-Section "All Saved WiFi Networks"
    Write-Host ""
    Write-Ui -Message "Scanning for saved WiFi profiles" -Level "INFO"
    Write-Host ""
    
    $profiles = Get-WiFiProfiles
    
    if ($profiles.Count -eq 0) {
        Write-Ui -Message "No saved WiFi networks found" -Level "ERROR"
        Write-Host ""
        Write-Ui -Message "This could mean: No WiFi networks have been connected" -Level "INFO"
        Write-Ui -Message "WiFi adapter not present" -Level "INFO"
        Write-Ui -Message "Running on Ethernet only" -Level "INFO"
    }
    else {
        $count = 0
        foreach ($profile in $profiles) {
            $count++
            Write-Host "----------------------------------------" -ForegroundColor Gray
            Write-Ui -Message "Network #${count}: $profile" -Level "STEP"
            Write-Host "----------------------------------------" -ForegroundColor Gray
            
            $password = Get-WiFiPassword -ProfileName $profile
            
            if ($password) {
                Write-Ui -Message "Password: $password" -Level "OK"
            }
            else {
                Write-Ui -Message "Password: [Open Network - No Password]" -Level "WARN"
            }
            
            Write-Host ""
        }
        
        Write-Host ""
        Write-Ui -Message "Total networks found: $count" -Level "OK"
    }
    
    Write-Host ""
    Write-Ui -Message "Press any key to return to main menu..." -Level "INFO"
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# Function to view current network password
function Show-CurrentNetwork {
    Show-Header
    Show-Section "Current WiFi Network"
    Write-Host ""
    
    $currentNetwork = Get-CurrentNetwork
    
    if (-not $currentNetwork) {
        Write-Ui -Message "Not connected to any WiFi network" -Level "ERROR"
        Write-Host ""
        Write-Ui -Message "Please connect to a WiFi network first" -Level "INFO"
    }
    else {
        Write-Ui -Message "Network Name: $currentNetwork" -Level "INFO"
        Write-Host ""
        Write-Ui -Message "Retrieving password" -Level "INFO"
        Write-Host ""
        
        $password = Get-WiFiPassword -ProfileName $currentNetwork
        
        if ($password) {
            Write-Host "========================================" -ForegroundColor Green
            Write-Ui -Message "Password: $password" -Level "OK"
            Write-Host "========================================" -ForegroundColor Green
        }
        else {
            Write-Host "========================================" -ForegroundColor Yellow
            Write-Ui -Message "This is an OPEN network (no password)" -Level "WARN"
            Write-Host "========================================" -ForegroundColor Yellow
        }
        
        Write-Host ""
        Write-Ui -Message "Additional Information:" -Level "INFO"
        Write-Host "----------------------------------------" -ForegroundColor Gray
        
        $interfaceInfo = netsh wlan show interfaces | Select-String "State|Signal|Authentication|Cipher"
        foreach ($line in $interfaceInfo) {
            Write-Ui -Message $line -Level "INFO"
        }
    }
    
    Write-Host ""
    Write-Ui -Message "Press any key to return to main menu..." -Level "INFO"
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# Function to search for specific network
function Search-Network {
    Show-Header
    Show-Section "Search Specific Network"
    Write-Host ""
    Write-Ui -Message "Enter the WiFi network name (SSID)" -Level "INFO"
    $searchName = Read-Host "> "
    
    if ([string]::IsNullOrWhiteSpace($searchName)) {
        Write-Ui -Message "No network name entered" -Level "ERROR"
        Start-Sleep -Seconds 2
        return
    }
    
    Show-Header
    Show-Section "Searching for: $searchName"
    Write-Host ""
    
    $result = netsh wlan show profile name="$searchName" 2>&1
    
    if ($LASTEXITCODE -ne 0) {
        Write-Ui -Message "Network `"$searchName`" not found" -Level "ERROR"
        Write-Host ""
        Write-Ui -Message "This network has never been connected on this PC" -Level "WARN"
    }
    else {
        Write-Ui -Message "Network found: $searchName" -Level "OK"
        Write-Host ""
        
        $password = Get-WiFiPassword -ProfileName $searchName
        
        if ($password) {
            Write-Host "========================================" -ForegroundColor Green
            Write-Ui -Message "Password: $password" -Level "OK"
            Write-Host "========================================" -ForegroundColor Green
        }
        else {
            Write-Host "========================================" -ForegroundColor Yellow
            Write-Ui -Message "This is an OPEN network (no password)" -Level "WARN"
            Write-Host "========================================" -ForegroundColor Yellow
        }
    }
    
    Write-Host ""
    Write-Ui -Message "Press any key to return to main menu..." -Level "INFO"
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# Function to export all passwords to text file
function Export-ToFile {
    Show-Header
    Write-Host "========================================" -ForegroundColor Yellow
    Write-Ui -Message "   EXPORT ALL PASSWORDS TO FILE" -Level "WARN"
    Write-Host "========================================" -ForegroundColor Yellow
    Write-Host ""
    
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $fileName = "WiFi_Passwords_$timestamp.txt"
    $filePath = Join-Path -Path ([Environment]::GetFolderPath("Desktop")) -ChildPath $fileName
    
    Write-Ui -Message "Creating export file..." -Level "WARN"
    Write-Host ""
    
    $profiles = Get-WiFiProfiles
    
    if ($profiles.Count -eq 0) {
        Write-Host "========================================" -ForegroundColor Red
        Write-Ui -Message "   NO NETWORKS TO EXPORT" -Level "ERROR"
        Write-Host "========================================" -ForegroundColor Red
        Write-Host ""
        Write-Ui -Message "No saved WiFi networks found on this PC." -Level "WARN"
    }
    else {
        $content = @()
        $content += "============================================================"
        $content += "       WiFi PASSWORD BACKUP - by Soulitek.co.il"
        $content += "============================================================"
        $content += ""
        $content += "Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        $content += "Computer: $env:COMPUTERNAME"
        $content += "User: $env:USERNAME"
        $content += ""
        $content += "Total Networks: $($profiles.Count)"
        $content += ""
        $content += "============================================================"
        $content += ""
        
        $count = 0
        foreach ($profile in $profiles) {
            $count++
            $content += "----------------------------------------"
            $content += "Network #${count}: $profile"
            $content += "----------------------------------------"
            
            $password = Get-WiFiPassword -ProfileName $profile
            
            if ($password) {
                $content += "Password: $password"
            }
            else {
                $content += "Password: [Open Network - No Password]"
            }
            
            $content += ""
        }
        
        $content += "============================================================"
        $content += "             END OF BACKUP FILE"
        $content += "============================================================"
        $content += ""
        $content += "SECURITY WARNING:"
        $content += "This file contains sensitive passwords. Keep it secure!"
        $content += "Delete this file after use."
        $content += ""
        $content += "Coded by: Soulitek.co.il"
        $content += "Website: www.soulitek.co.il"
        
        $content | Out-File -FilePath $filePath -Encoding UTF8
        
        Write-Host "========================================" -ForegroundColor Green
        Write-Ui -Message "   EXPORT SUCCESSFUL" -Level "OK"
        Write-Host "========================================" -ForegroundColor Green
        Write-Host ""
        Write-Ui -Message "Total networks exported: $count" -Level "OK"
        Write-Host ""
        Write-Ui -Message "File saved to:" -Level "INFO"
        Write-Ui -Message $filePath -Level "STEP"
        Write-Host ""
        Write-Ui -Message "Opening file..." -Level "WARN"
        Start-Sleep -Seconds 2
        Start-Process $filePath
    }
    
    Write-Host ""
    Write-Ui -Message "Press any key to return to main menu..." -Level "INFO"
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# Function to export to CSV
function Export-ToCSV {
    Show-Header
    Write-Host "========================================" -ForegroundColor Magenta
    Write-Ui -Message "   EXPORT TO EXCEL CSV FORMAT" -Level "INFO"
    Write-Host "========================================" -ForegroundColor Magenta
    Write-Host ""
    
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $fileName = "WiFi_Passwords_$timestamp.csv"
    $filePath = Join-Path -Path ([Environment]::GetFolderPath("Desktop")) -ChildPath $fileName
    
    Write-Ui -Message "Creating CSV file..." -Level "WARN"
    Write-Host ""
    
    $profiles = Get-WiFiProfiles
    
    if ($profiles.Count -eq 0) {
        Write-Host "========================================" -ForegroundColor Red
        Write-Ui -Message "   NO NETWORKS TO EXPORT" -Level "ERROR"
        Write-Host "========================================" -ForegroundColor Red
        Write-Host ""
        Write-Ui -Message "No saved WiFi networks found on this PC." -Level "WARN"
    }
    else {
        $csvData = @()
        
        foreach ($profile in $profiles) {
            $password = Get-WiFiPassword -ProfileName $profile
            
            if (-not $password) {
                $password = "Open Network"
            }
            
            # Get authentication type
            $authType = "Unknown"
            $profileInfo = netsh wlan show profile name="$profile"
            foreach ($line in $profileInfo) {
                if ($line -match "Authentication\s+:\s+(.+)") {
                    $authType = $matches[1].Trim()
                    break
                }
            }
            
            $csvData += [PSCustomObject]@{
                "Network Name" = $profile
                "Password" = $password
                "Security Type" = $authType
                "Generated Date" = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            }
        }
        
        $csvData | Export-Csv -Path $filePath -NoTypeInformation -Encoding UTF8
        
        Write-Host "========================================" -ForegroundColor Green
        Write-Ui -Message "   CSV EXPORT SUCCESSFUL" -Level "OK"
        Write-Host "========================================" -ForegroundColor Green
        Write-Host ""
        Write-Ui -Message "Total networks exported: $($profiles.Count)" -Level "OK"
        Write-Host ""
        Write-Ui -Message "File saved to:" -Level "INFO"
        Write-Ui -Message $filePath -Level "STEP"
        Write-Host ""
        Write-Ui -Message "This file can be opened in:" -Level "WARN"
        Write-Ui -Message "  - Microsoft Excel" -Level "INFO"
        Write-Ui -Message "  - Google Sheets" -Level "INFO"
        Write-Ui -Message "  - Any spreadsheet program" -Level "INFO"
        Write-Host ""
        Write-Ui -Message "Opening file..." -Level "WARN"
        Start-Sleep -Seconds 2
        Start-Process $filePath
    }
    
    Write-Host ""
    Write-Ui -Message "Press any key to return to main menu..." -Level "INFO"
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# Function to quick copy password
function Copy-PasswordToClipboard {
    Show-Header
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Ui -Message "   QUICK COPY PASSWORD TO CLIPBOARD" -Level "INFO"
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Ui -Message "Available networks:" -Level "WARN"
    Write-Host ""
    
    $profiles = Get-WiFiProfiles
    
    if ($profiles.Count -eq 0) {
        Write-Ui -Message "No saved WiFi networks found!" -Level "ERROR"
        Write-Host ""
        Start-Sleep -Seconds 3
        return
    }
    
    for ($i = 0; $i -lt $profiles.Count; $i++) {
        Write-Ui -Message "[$($i + 1)] $($profiles[$i])" -Level "STEP"
    }
    
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    $selection = Read-Host "Enter network number (or 0 to cancel)"
    
    if ($selection -eq "0") {
        return
    }
    
    $index = [int]$selection - 1
    
    if ($index -lt 0 -or $index -ge $profiles.Count) {
        Write-Ui -Message "Invalid selection!" -Level "ERROR"
        Start-Sleep -Seconds 2
        Copy-PasswordToClipboard
        return
    }
    
    $selectedNetwork = $profiles[$index]
    
    Write-Host ""
    Write-Ui -Message "Selected: $selectedNetwork" -Level "STEP"
    Write-Host ""
    Write-Ui -Message "Retrieving password..." -Level "WARN"
    
    $password = Get-WiFiPassword -ProfileName $selectedNetwork
    
    if ($password) {
        Set-Clipboard -Value $password
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Green
        Write-Ui -Message "   PASSWORD COPIED TO CLIPBOARD!" -Level "OK"
        Write-Host "========================================" -ForegroundColor Green
        Write-Host ""
        Write-Ui -Message "Network: $selectedNetwork" -Level "STEP"
        Write-Ui -Message "Password: $password" -Level "OK"
        Write-Host ""
        Write-Ui -Message "The password is now in your clipboard." -Level "INFO"
        Write-Ui -Message "You can paste it with Ctrl+V" -Level "INFO"
    }
    else {
        Write-Host "========================================" -ForegroundColor Yellow
        Write-Ui -Message "This is an OPEN network (no password)" -Level "WARN"
        Write-Host "========================================" -ForegroundColor Yellow
    }
    
    Write-Host ""
    Write-Ui -Message "Press any key to return to main menu..." -Level "INFO"
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# Function to show help
function Show-Help {
    Show-Header
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Ui -Message "   HELP GUIDE" -Level "INFO"
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Ui -Message "WHEN TO USE EACH OPTION:" -Level "WARN"
    Write-Host "----------------------------------------" -ForegroundColor Gray
    Write-Host ""
    Write-Ui -Message "[1] VIEW ALL WiFi PASSWORDS" -Level "STEP"
    Write-Ui -Message "    Use when: Need to see all saved networks" -Level "INFO"
    Write-Ui -Message "    Shows: Complete list with passwords" -Level "INFO"
    Write-Ui -Message "    Time: 5 seconds" -Level "INFO"
    Write-Host ""
    Write-Ui -Message "[2] VIEW CURRENT NETWORK" -Level "STEP"
    Write-Ui -Message "    Use when: Need password for connected WiFi" -Level "INFO"
    Write-Ui -Message "    Shows: Currently connected network only" -Level "INFO"
    Write-Ui -Message "    Time: 2 seconds" -Level "INFO"
    Write-Host ""
    Write-Ui -Message "[3] SEARCH SPECIFIC NETWORK" -Level "STEP"
    Write-Ui -Message "    Use when: Looking for one specific network" -Level "INFO"
    Write-Ui -Message "    Shows: Single network by name" -Level "INFO"
    Write-Ui -Message "    Time: 3 seconds" -Level "INFO"
    Write-Host ""
    Write-Ui -Message "[4] EXPORT ALL TO FILE" -Level "STEP"
    Write-Ui -Message "    Use when: Need backup before PC reset" -Level "INFO"
    Write-Ui -Message "    Creates: Text file on Desktop" -Level "INFO"
    Write-Ui -Message "    Time: 5 seconds" -Level "INFO"
    Write-Host ""
    Write-Ui -Message "[5] EXPORT TO EXCEL CSV" -Level "STEP"
    Write-Ui -Message "    Use when: Need organized spreadsheet" -Level "INFO"
    Write-Ui -Message "    Creates: CSV file for Excel/Sheets" -Level "INFO"
    Write-Ui -Message "    Time: 5 seconds" -Level "INFO"
    Write-Host ""
    Write-Ui -Message "[6] QUICK COPY PASSWORD" -Level "STEP"
    Write-Ui -Message "    Use when: Need to share password quickly" -Level "INFO"
    Write-Ui -Message "    Does: Copies password to clipboard" -Level "INFO"
    Write-Ui -Message "    Time: 5 seconds" -Level "INFO"
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Ui -Message "COMMON SCENARIOS:" -Level "WARN"
    Write-Host "----------------------------------------" -ForegroundColor Gray
    Write-Host ""
    Write-Ui -Message "Scenario: Forgot home WiFi password" -Level "STEP"
    Write-Ui -Message "Solution: Use option [1] or [2]" -Level "OK"
    Write-Host ""
    Write-Ui -Message "Scenario: Setting up new device" -Level "STEP"
    Write-Ui -Message "Solution: Use option [6] to copy password" -Level "OK"
    Write-Host ""
    Write-Ui -Message "Scenario: Reinstalling Windows" -Level "STEP"
    Write-Ui -Message "Solution: Use option [4] to backup all" -Level "OK"
    Write-Host ""
    Write-Ui -Message "Scenario: Client documentation" -Level "STEP"
    Write-Ui -Message "Solution: Use option [5] for professional report" -Level "OK"
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Ui -Message "SECURITY TIPS:" -Level "WARN"
    Write-Host "----------------------------------------" -ForegroundColor Gray
    Write-Host ""
    Write-Ui -Message "- Delete exported files after use" -Level "INFO"
    Write-Ui -Message "- Don't share password files via email" -Level "INFO"
    Write-Ui -Message "- Keep backups in secure location" -Level "INFO"
    Write-Ui -Message "- Only use on authorized computers" -Level "INFO"
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Ui -Message "TROUBLESHOOTING:" -Level "WARN"
    Write-Host "----------------------------------------" -ForegroundColor Gray
    Write-Host ""
    Write-Ui -Message "Q: `"Network not found`" error?" -Level "STEP"
    Write-Ui -Message "A: Network was never connected on this PC" -Level "INFO"
    Write-Host ""
    Write-Ui -Message "Q: Shows `"Open Network`"?" -Level "STEP"
    Write-Ui -Message "A: The network has no password (public WiFi)" -Level "INFO"
    Write-Host ""
    Write-Ui -Message "Q: Can't see current network?" -Level "STEP"
    Write-Ui -Message "A: Make sure WiFi is connected" -Level "INFO"
    Write-Host ""
    Write-Ui -Message "Q: Script won't run?" -Level "STEP"
    Write-Ui -Message "A: Run PowerShell as administrator" -Level "INFO"
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Ui -Message "Press any key to return to main menu..." -Level "INFO"
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# Function to show main menu
function Show-MainMenu {
    Show-Header
    Write-Ui -Message "Select an option:" -Level "WARN"
    Write-Host ""
    Write-Ui -Message "  [1] View All WiFi Passwords     - Show all saved networks" -Level "STEP"
    Write-Ui -Message "  [2] View Current Network        - Show connected network only" -Level "STEP"
    Write-Ui -Message "  [3] Search Specific Network     - Find password by name" -Level "STEP"
    Write-Ui -Message "  [4] Export All to File          - Save all passwords to Desktop" -Level "STEP"
    Write-Ui -Message "  [5] Export to Excel CSV         - Create spreadsheet format" -Level "STEP"
    Write-Ui -Message "  [6] Quick Copy Password         - Copy to clipboard" -Level "STEP"
    Write-Ui -Message "  [7] Help                        - Usage guide" -Level "STEP"
    Write-Ui -Message "  [0] Exit" -Level "STEP"
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    $choice = Read-Host "Enter your choice (0-7)"
    
    return $choice
}

# Show-Disclaimer function - using Show-SouliTEKDisclaimer from common module
function Show-Disclaimer {
    Show-SouliTEKDisclaimer
}

# Main script execution
# Check for administrator privileges
if (-not (Test-SouliTEKAdministrator)) {
    Clear-Host
    Show-ScriptBanner -ScriptName "WiFi Password Viewer" -Purpose "View and backup WiFi passwords saved on Windows computer"
    Write-Host ""
    Write-Ui -Message "Administrator privileges required" -Level "ERROR"
    Write-Ui -Message "This script must run as Administrator" -Level "INFO"
    Write-Host ""
    Write-Ui -Message "HOW TO FIX: Right-click PowerShell and select 'Run as administrator'" -Level "INFO"
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit 1
}

# ============================================================
# EXIT MESSAGE
# ============================================================

# Show-ExitMessage function - using Show-SouliTEKExitMessage from common module
function Show-ExitMessage {
    Show-SouliTEKExitMessage -ScriptPath $PSCommandPath -ToolName "SouliTEK WiFi Password Viewer"
}

# Show banner
Clear-Host
Show-ScriptBanner -ScriptName "WiFi Password Viewer" -Purpose "View and backup WiFi passwords saved on Windows computer"

# Show disclaimer
Show-Disclaimer

# Main program loop
$running = $true
while ($running) {
    $choice = Show-MainMenu
    
    switch ($choice) {
        "1" { Show-AllPasswords }
        "2" { Show-CurrentNetwork }
        "3" { Search-Network }
        "4" { Export-ToFile }
        "5" { Export-ToCSV }
        "6" { Copy-PasswordToClipboard }
        "7" { Show-Help }
        "0" { 
            Show-ExitMessage
            $running = $false
        }
        default {
            Write-Ui -Message "Invalid choice. Please try again" -Level "ERROR"
            Start-Sleep -Seconds 2
        }
    }
}
