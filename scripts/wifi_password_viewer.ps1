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
    Show-SouliTEKHeader -Title "WIFI PASSWORD VIEWER" -ClearHost -ShowBanner
    Write-Host "      Coded by: Soulitek.co.il" -ForegroundColor Yellow
    Write-Host "      IT Solutions for your business" -ForegroundColor Yellow
    Write-Host "      www.soulitek.co.il" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "      (C) 2025 Soulitek - All Rights Reserved" -ForegroundColor Gray
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
}

# Function to view all WiFi passwords
function Show-AllPasswords {
    Show-Header
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "   ALL SAVED WiFi NETWORKS" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Scanning for saved WiFi profiles..." -ForegroundColor Yellow
    Write-Host ""
    
    $profiles = Get-WiFiProfiles
    
    if ($profiles.Count -eq 0) {
        Write-Host "No saved WiFi networks found!" -ForegroundColor Red
        Write-Host ""
        Write-Host "This could mean:" -ForegroundColor Yellow
        Write-Host "  - No WiFi networks have been connected" -ForegroundColor Gray
        Write-Host "  - WiFi adapter not present" -ForegroundColor Gray
        Write-Host "  - Running on Ethernet only" -ForegroundColor Gray
    }
    else {
        $count = 0
        foreach ($profile in $profiles) {
            $count++
            Write-Host "----------------------------------------" -ForegroundColor Gray
            Write-Host "Network #${count}: $profile" -ForegroundColor White
            Write-Host "----------------------------------------" -ForegroundColor Gray
            
            $password = Get-WiFiPassword -ProfileName $profile
            
            if ($password) {
                Write-Host "Password: $password" -ForegroundColor Green
            }
            else {
                Write-Host "Password: [Open Network - No Password]" -ForegroundColor Yellow
            }
            
            Write-Host ""
        }
        
        Write-Host "========================================" -ForegroundColor Green
        Write-Host "Total networks found: $count" -ForegroundColor Green
        Write-Host "========================================" -ForegroundColor Green
    }
    
    Write-Host ""
    Write-Host "Press any key to return to main menu..." -ForegroundColor Cyan
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# Function to view current network password
function Show-CurrentNetwork {
    Show-Header
    Write-Host "========================================" -ForegroundColor Magenta
    Write-Host "   CURRENT WiFi NETWORK" -ForegroundColor Magenta
    Write-Host "========================================" -ForegroundColor Magenta
    Write-Host ""
    
    $currentNetwork = Get-CurrentNetwork
    
    if (-not $currentNetwork) {
        Write-Host "Not connected to any WiFi network!" -ForegroundColor Red
        Write-Host ""
        Write-Host "Please connect to a WiFi network first." -ForegroundColor Yellow
    }
    else {
        Write-Host "Network Name: $currentNetwork" -ForegroundColor White
        Write-Host ""
        Write-Host "Retrieving password..." -ForegroundColor Yellow
        Write-Host ""
        
        $password = Get-WiFiPassword -ProfileName $currentNetwork
        
        if ($password) {
            Write-Host "========================================" -ForegroundColor Green
            Write-Host "Password: $password" -ForegroundColor Green
            Write-Host "========================================" -ForegroundColor Green
        }
        else {
            Write-Host "========================================" -ForegroundColor Yellow
            Write-Host "This is an OPEN network (no password)" -ForegroundColor Yellow
            Write-Host "========================================" -ForegroundColor Yellow
        }
        
        Write-Host ""
        Write-Host "Additional Information:" -ForegroundColor Cyan
        Write-Host "----------------------------------------" -ForegroundColor Gray
        
        $interfaceInfo = netsh wlan show interfaces | Select-String "State|Signal|Authentication|Cipher"
        foreach ($line in $interfaceInfo) {
            Write-Host $line -ForegroundColor Gray
        }
    }
    
    Write-Host ""
    Write-Host "Press any key to return to main menu..." -ForegroundColor Cyan
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# Function to search for specific network
function Search-Network {
    Show-Header
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "   SEARCH SPECIFIC NETWORK" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Enter the WiFi network name (SSID):" -ForegroundColor Yellow
    $searchName = Read-Host "> "
    
    if ([string]::IsNullOrWhiteSpace($searchName)) {
        Write-Host "No network name entered." -ForegroundColor Red
        Start-Sleep -Seconds 2
        return
    }
    
    Show-Header
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "   SEARCHING FOR: $searchName" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    
    $result = netsh wlan show profile name="$searchName" 2>&1
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Network `"$searchName`" not found!" -ForegroundColor Red
        Write-Host ""
        Write-Host "This network has never been connected on this PC." -ForegroundColor Yellow
    }
    else {
        Write-Host "Network found: $searchName" -ForegroundColor Green
        Write-Host ""
        
        $password = Get-WiFiPassword -ProfileName $searchName
        
        if ($password) {
            Write-Host "========================================" -ForegroundColor Green
            Write-Host "Password: $password" -ForegroundColor Green
            Write-Host "========================================" -ForegroundColor Green
        }
        else {
            Write-Host "========================================" -ForegroundColor Yellow
            Write-Host "This is an OPEN network (no password)" -ForegroundColor Yellow
            Write-Host "========================================" -ForegroundColor Yellow
        }
    }
    
    Write-Host ""
    Write-Host "Press any key to return to main menu..." -ForegroundColor Cyan
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# Function to export all passwords to text file
function Export-ToFile {
    Show-Header
    Write-Host "========================================" -ForegroundColor Yellow
    Write-Host "   EXPORT ALL PASSWORDS TO FILE" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Yellow
    Write-Host ""
    
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $fileName = "WiFi_Passwords_$timestamp.txt"
    $filePath = Join-Path -Path ([Environment]::GetFolderPath("Desktop")) -ChildPath $fileName
    
    Write-Host "Creating export file..." -ForegroundColor Yellow
    Write-Host ""
    
    $profiles = Get-WiFiProfiles
    
    if ($profiles.Count -eq 0) {
        Write-Host "========================================" -ForegroundColor Red
        Write-Host "   NO NETWORKS TO EXPORT" -ForegroundColor Red
        Write-Host "========================================" -ForegroundColor Red
        Write-Host ""
        Write-Host "No saved WiFi networks found on this PC." -ForegroundColor Yellow
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
        Write-Host "   EXPORT SUCCESSFUL" -ForegroundColor Green
        Write-Host "========================================" -ForegroundColor Green
        Write-Host ""
        Write-Host "Total networks exported: $count" -ForegroundColor Green
        Write-Host ""
        Write-Host "File saved to:" -ForegroundColor Cyan
        Write-Host $filePath -ForegroundColor White
        Write-Host ""
        Write-Host "Opening file..." -ForegroundColor Yellow
        Start-Sleep -Seconds 2
        Start-Process $filePath
    }
    
    Write-Host ""
    Write-Host "Press any key to return to main menu..." -ForegroundColor Cyan
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# Function to export to CSV
function Export-ToCSV {
    Show-Header
    Write-Host "========================================" -ForegroundColor Magenta
    Write-Host "   EXPORT TO EXCEL CSV FORMAT" -ForegroundColor Magenta
    Write-Host "========================================" -ForegroundColor Magenta
    Write-Host ""
    
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $fileName = "WiFi_Passwords_$timestamp.csv"
    $filePath = Join-Path -Path ([Environment]::GetFolderPath("Desktop")) -ChildPath $fileName
    
    Write-Host "Creating CSV file..." -ForegroundColor Yellow
    Write-Host ""
    
    $profiles = Get-WiFiProfiles
    
    if ($profiles.Count -eq 0) {
        Write-Host "========================================" -ForegroundColor Red
        Write-Host "   NO NETWORKS TO EXPORT" -ForegroundColor Red
        Write-Host "========================================" -ForegroundColor Red
        Write-Host ""
        Write-Host "No saved WiFi networks found on this PC." -ForegroundColor Yellow
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
        Write-Host "   CSV EXPORT SUCCESSFUL" -ForegroundColor Green
        Write-Host "========================================" -ForegroundColor Green
        Write-Host ""
        Write-Host "Total networks exported: $($profiles.Count)" -ForegroundColor Green
        Write-Host ""
        Write-Host "File saved to:" -ForegroundColor Cyan
        Write-Host $filePath -ForegroundColor White
        Write-Host ""
        Write-Host "This file can be opened in:" -ForegroundColor Yellow
        Write-Host "  - Microsoft Excel" -ForegroundColor Gray
        Write-Host "  - Google Sheets" -ForegroundColor Gray
        Write-Host "  - Any spreadsheet program" -ForegroundColor Gray
        Write-Host ""
        Write-Host "Opening file..." -ForegroundColor Yellow
        Start-Sleep -Seconds 2
        Start-Process $filePath
    }
    
    Write-Host ""
    Write-Host "Press any key to return to main menu..." -ForegroundColor Cyan
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# Function to quick copy password
function Copy-PasswordToClipboard {
    Show-Header
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "   QUICK COPY PASSWORD TO CLIPBOARD" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Available networks:" -ForegroundColor Yellow
    Write-Host ""
    
    $profiles = Get-WiFiProfiles
    
    if ($profiles.Count -eq 0) {
        Write-Host "No saved WiFi networks found!" -ForegroundColor Red
        Write-Host ""
        Start-Sleep -Seconds 3
        return
    }
    
    for ($i = 0; $i -lt $profiles.Count; $i++) {
        Write-Host "[$($i + 1)] $($profiles[$i])" -ForegroundColor White
    }
    
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    $selection = Read-Host "Enter network number (or 0 to cancel)"
    
    if ($selection -eq "0") {
        return
    }
    
    $index = [int]$selection - 1
    
    if ($index -lt 0 -or $index -ge $profiles.Count) {
        Write-Host "Invalid selection!" -ForegroundColor Red
        Start-Sleep -Seconds 2
        Copy-PasswordToClipboard
        return
    }
    
    $selectedNetwork = $profiles[$index]
    
    Write-Host ""
    Write-Host "Selected: $selectedNetwork" -ForegroundColor White
    Write-Host ""
    Write-Host "Retrieving password..." -ForegroundColor Yellow
    
    $password = Get-WiFiPassword -ProfileName $selectedNetwork
    
    if ($password) {
        Set-Clipboard -Value $password
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Green
        Write-Host "   PASSWORD COPIED TO CLIPBOARD!" -ForegroundColor Green
        Write-Host "========================================" -ForegroundColor Green
        Write-Host ""
        Write-Host "Network: $selectedNetwork" -ForegroundColor White
        Write-Host "Password: $password" -ForegroundColor Green
        Write-Host ""
        Write-Host "The password is now in your clipboard." -ForegroundColor Cyan
        Write-Host "You can paste it with Ctrl+V" -ForegroundColor Cyan
    }
    else {
        Write-Host "========================================" -ForegroundColor Yellow
        Write-Host "This is an OPEN network (no password)" -ForegroundColor Yellow
        Write-Host "========================================" -ForegroundColor Yellow
    }
    
    Write-Host ""
    Write-Host "Press any key to return to main menu..." -ForegroundColor Cyan
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# Function to show help
function Show-Help {
    Show-Header
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "   HELP GUIDE" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "WHEN TO USE EACH OPTION:" -ForegroundColor Yellow
    Write-Host "----------------------------------------" -ForegroundColor Gray
    Write-Host ""
    Write-Host "[1] VIEW ALL WiFi PASSWORDS" -ForegroundColor White
    Write-Host "    Use when: Need to see all saved networks" -ForegroundColor Gray
    Write-Host "    Shows: Complete list with passwords" -ForegroundColor Gray
    Write-Host "    Time: 5 seconds" -ForegroundColor Gray
    Write-Host ""
    Write-Host "[2] VIEW CURRENT NETWORK" -ForegroundColor White
    Write-Host "    Use when: Need password for connected WiFi" -ForegroundColor Gray
    Write-Host "    Shows: Currently connected network only" -ForegroundColor Gray
    Write-Host "    Time: 2 seconds" -ForegroundColor Gray
    Write-Host ""
    Write-Host "[3] SEARCH SPECIFIC NETWORK" -ForegroundColor White
    Write-Host "    Use when: Looking for one specific network" -ForegroundColor Gray
    Write-Host "    Shows: Single network by name" -ForegroundColor Gray
    Write-Host "    Time: 3 seconds" -ForegroundColor Gray
    Write-Host ""
    Write-Host "[4] EXPORT ALL TO FILE" -ForegroundColor White
    Write-Host "    Use when: Need backup before PC reset" -ForegroundColor Gray
    Write-Host "    Creates: Text file on Desktop" -ForegroundColor Gray
    Write-Host "    Time: 5 seconds" -ForegroundColor Gray
    Write-Host ""
    Write-Host "[5] EXPORT TO EXCEL CSV" -ForegroundColor White
    Write-Host "    Use when: Need organized spreadsheet" -ForegroundColor Gray
    Write-Host "    Creates: CSV file for Excel/Sheets" -ForegroundColor Gray
    Write-Host "    Time: 5 seconds" -ForegroundColor Gray
    Write-Host ""
    Write-Host "[6] QUICK COPY PASSWORD" -ForegroundColor White
    Write-Host "    Use when: Need to share password quickly" -ForegroundColor Gray
    Write-Host "    Does: Copies password to clipboard" -ForegroundColor Gray
    Write-Host "    Time: 5 seconds" -ForegroundColor Gray
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "COMMON SCENARIOS:" -ForegroundColor Yellow
    Write-Host "----------------------------------------" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Scenario: Forgot home WiFi password" -ForegroundColor White
    Write-Host "Solution: Use option [1] or [2]" -ForegroundColor Green
    Write-Host ""
    Write-Host "Scenario: Setting up new device" -ForegroundColor White
    Write-Host "Solution: Use option [6] to copy password" -ForegroundColor Green
    Write-Host ""
    Write-Host "Scenario: Reinstalling Windows" -ForegroundColor White
    Write-Host "Solution: Use option [4] to backup all" -ForegroundColor Green
    Write-Host ""
    Write-Host "Scenario: Client documentation" -ForegroundColor White
    Write-Host "Solution: Use option [5] for professional report" -ForegroundColor Green
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "SECURITY TIPS:" -ForegroundColor Yellow
    Write-Host "----------------------------------------" -ForegroundColor Gray
    Write-Host ""
    Write-Host "- Delete exported files after use" -ForegroundColor Gray
    Write-Host "- Don't share password files via email" -ForegroundColor Gray
    Write-Host "- Keep backups in secure location" -ForegroundColor Gray
    Write-Host "- Only use on authorized computers" -ForegroundColor Gray
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "TROUBLESHOOTING:" -ForegroundColor Yellow
    Write-Host "----------------------------------------" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Q: `"Network not found`" error?" -ForegroundColor White
    Write-Host "A: Network was never connected on this PC" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Q: Shows `"Open Network`"?" -ForegroundColor White
    Write-Host "A: The network has no password (public WiFi)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Q: Can't see current network?" -ForegroundColor White
    Write-Host "A: Make sure WiFi is connected" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Q: Script won't run?" -ForegroundColor White
    Write-Host "A: Run PowerShell as administrator" -ForegroundColor Gray
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Press any key to return to main menu..." -ForegroundColor Cyan
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# Function to show main menu
function Show-MainMenu {
    Show-Header
    Write-Host "Select an option:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  [1] View All WiFi Passwords     - Show all saved networks" -ForegroundColor White
    Write-Host "  [2] View Current Network        - Show connected network only" -ForegroundColor White
    Write-Host "  [3] Search Specific Network     - Find password by name" -ForegroundColor White
    Write-Host "  [4] Export All to File          - Save all passwords to Desktop" -ForegroundColor White
    Write-Host "  [5] Export to Excel CSV         - Create spreadsheet format" -ForegroundColor White
    Write-Host "  [6] Quick Copy Password         - Copy to clipboard" -ForegroundColor White
    Write-Host "  [7] Help                        - Usage guide" -ForegroundColor White
    Write-Host "  [0] Exit" -ForegroundColor White
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
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Red
    Write-Host "   ERROR: Administrator Required" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "This script must run as Administrator." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "HOW TO FIX:" -ForegroundColor White
    Write-Host "1. Right-click PowerShell" -ForegroundColor Gray
    Write-Host "2. Select `"Run as administrator`"" -ForegroundColor Gray
    Write-Host "3. Navigate to script location and run it" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Or run this command:" -ForegroundColor White
    Write-Host "Start-Process powershell -Verb RunAs -ArgumentList `"-File '$PSCommandPath'`"" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Red
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
            Write-Host "Invalid choice. Please try again." -ForegroundColor Red
            Start-Sleep -Seconds 2
        }
    }
}
