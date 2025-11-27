# ============================================================
# Essential Tweaks - Professional Edition
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
# This tool provides essential Windows tweaks and configurations
# for optimal system setup and user experience.
# 
# Features: Default Apps | Keyboard Layouts | Language Settings
#           Taskbar Customization | Start Menu Optimization
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
# ============================================================

# Set window title
$Host.UI.RawUI.WindowTitle = "ESSENTIAL TWEAKS"

# Import SouliTEK Common Functions
$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$CommonPath = Join-Path (Split-Path -Parent $ScriptRoot) "modules\SouliTEK-Common.ps1"
if (Test-Path $CommonPath) {
    . $CommonPath
} else {
    Write-Warning "SouliTEK Common Functions not found at: $CommonPath"
    Write-Warning "Some functions may not work properly."
}

# ============================================================
# HELPER FUNCTIONS
# ============================================================

# Show-Header function removed - using Show-SouliTEKHeader from common module

# ============================================================
# TWEAK FUNCTIONS
# ============================================================

function Set-GoogleChromeDefault {
    <#
    .SYNOPSIS
        Sets Google Chrome as the default browser.
    #>
    
    Write-Host "[*] Setting Google Chrome as default browser..." -ForegroundColor Cyan
    
    try {
        # Check if Chrome is installed
        $chromePath = "${env:ProgramFiles}\Google\Chrome\Application\chrome.exe"
        $chromePathX86 = "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe"
        
        if (-not (Test-Path $chromePath) -and -not (Test-Path $chromePathX86)) {
            Write-Host "[!] WARNING: Google Chrome not found. Please install Chrome first." -ForegroundColor Yellow
            return $false
        }
        
        # Open Windows Settings for default apps
        Write-Host "[*] Opening Windows Settings for default apps..." -ForegroundColor Gray
        Start-Process "ms-settings:defaultapps" -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2
        
        Write-Host "[+] SUCCESS: Windows Settings opened" -ForegroundColor Green
        Write-Host "[*] Please select Google Chrome as your default browser in the Settings window" -ForegroundColor Yellow
        return $true
    }
    catch {
        Write-Host "[!] ERROR: Failed to open default apps settings: $_" -ForegroundColor Red
        return $false
    }
}

function Set-AdobeAcrobatDefault {
    <#
    .SYNOPSIS
        Sets Adobe Acrobat Reader as the default PDF application.
    #>
    
    Write-Host "[*] Setting Adobe Acrobat Reader as default PDF app..." -ForegroundColor Cyan
    
    try {
        # Check if Adobe Acrobat Reader is installed
        $acrobatPaths = @(
            "${env:ProgramFiles}\Adobe\Acrobat DC\Acrobat\Acrobat.exe",
            "${env:ProgramFiles(x86)}\Adobe\Acrobat Reader DC\Reader\AcroRd32.exe",
            "${env:ProgramFiles}\Adobe\Acrobat Reader DC\Reader\AcroRd32.exe",
            "${env:ProgramFiles(x86)}\Adobe\Acrobat Reader 2020\Reader\AcroRd32.exe"
        )
        
        $acrobatFound = $false
        foreach ($path in $acrobatPaths) {
            if (Test-Path $path) {
                $acrobatFound = $true
                break
            }
        }
        
        if (-not $acrobatFound) {
            Write-Host "[!] WARNING: Adobe Acrobat Reader not found. Please install it first." -ForegroundColor Yellow
            return $false
        }
        
        # Open Windows Settings for default apps by file type
        Write-Host "[*] Opening Windows Settings for default apps..." -ForegroundColor Gray
        Start-Process "ms-settings:defaultapps" -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2
        
        Write-Host "[+] SUCCESS: Windows Settings opened" -ForegroundColor Green
        Write-Host "[*] Please search for '.pdf' and select Adobe Acrobat Reader" -ForegroundColor Yellow
        return $true
    }
    catch {
        Write-Host "[!] ERROR: Failed to open default apps settings: $_" -ForegroundColor Red
        return $false
    }
}

function Add-HebrewKeyboard {
    <#
    .SYNOPSIS
        Adds Hebrew keyboard layout to Windows.
    #>
    
    Write-Host "[*] Adding Hebrew keyboard layout..." -ForegroundColor Cyan
    
    try {
        # Get current language list
        $langList = Get-WinUserLanguageList
        
        # Check if Hebrew already exists
        $hebrewExists = $langList | Where-Object { $_.LanguageTag -eq "he-IL" -or $_.LanguageTag -eq "he" }
        
        if ($hebrewExists) {
            Write-Host "[*] Hebrew keyboard is already installed" -ForegroundColor Yellow
            return $true
        }
        
        # Add Hebrew
        $langList.Add("he-IL")
        Set-WinUserLanguageList $langList -Force
        
        Write-Host "[+] SUCCESS: Hebrew keyboard layout added" -ForegroundColor Green
        Write-Host "[*] Use Win+Space to switch between keyboards" -ForegroundColor Yellow
        return $true
    }
    catch {
        Write-Host "[!] ERROR: Failed to add Hebrew keyboard: $_" -ForegroundColor Red
        return $false
    }
}

function Add-EnglishUSKeyboard {
    <#
    .SYNOPSIS
        Adds English (US) keyboard layout to Windows.
    #>
    
    Write-Host "[*] Adding English (US) keyboard layout..." -ForegroundColor Cyan
    
    try {
        # Get current language list
        $langList = Get-WinUserLanguageList
        
        # Check if English US already exists
        $englishExists = $langList | Where-Object { $_.LanguageTag -eq "en-US" }
        
        if ($englishExists) {
            Write-Host "[*] English (US) keyboard is already installed" -ForegroundColor Yellow
            return $true
        }
        
        # Add English US
        $langList.Add("en-US")
        Set-WinUserLanguageList $langList -Force
        
        Write-Host "[+] SUCCESS: English (US) keyboard layout added" -ForegroundColor Green
        Write-Host "[*] Use Win+Space to switch between keyboards" -ForegroundColor Yellow
        return $true
    }
    catch {
        Write-Host "[!] ERROR: Failed to add English (US) keyboard: $_" -ForegroundColor Red
        return $false
    }
}

function Set-HebrewDisplayLanguage {
    <#
    .SYNOPSIS
        Sets Hebrew as the main display language.
    #>
    
    Write-Host "[*] Setting Hebrew as main display language..." -ForegroundColor Cyan
    
    try {
        # Get current language list
        $langList = Get-WinUserLanguageList
        
        # Check if Hebrew exists
        $hebrewLang = $langList | Where-Object { $_.LanguageTag -eq "he-IL" -or $_.LanguageTag -eq "he" }
        
        if (-not $hebrewLang) {
            Write-Host "[*] Adding Hebrew language first..." -ForegroundColor Gray
            $langList.Add("he-IL")
        }
        
        # Create new list with Hebrew first
        $newLangList = New-WinUserLanguageList "he-IL"
        
        # Add other languages after Hebrew
        foreach ($lang in $langList) {
            if ($lang.LanguageTag -ne "he-IL" -and $lang.LanguageTag -ne "he") {
                $newLangList.Add($lang.LanguageTag)
            }
        }
        
        Set-WinUserLanguageList $newLangList -Force
        
        Write-Host "[+] SUCCESS: Hebrew set as main display language" -ForegroundColor Green
        Write-Host "[*] You may need to sign out and back in for changes to take full effect" -ForegroundColor Yellow
        Write-Host "[*] Windows may need to download the Hebrew language pack" -ForegroundColor Yellow
        return $true
    }
    catch {
        Write-Host "[!] ERROR: Failed to set Hebrew as display language: $_" -ForegroundColor Red
        Write-Host "[!] This may require downloading the Hebrew language pack from Windows Update" -ForegroundColor Yellow
        return $false
    }
}

function Disable-StartMenuAds {
    <#
    .SYNOPSIS
        Disables Start Menu ads and suggestions.
    #>
    
    Write-Host "[*] Disabling Start Menu ads & suggestions..." -ForegroundColor Cyan
    
    try {
        $cdmPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
        
        # Ensure the path exists
        if (-not (Test-Path $cdmPath)) {
            New-Item -Path $cdmPath -Force | Out-Null
        }
        
        # Disable Start Menu suggestions
        Set-ItemProperty -Path $cdmPath -Name "SystemPaneSuggestionsEnabled" -Value 0 -Type DWord -Force
        
        # Disable Start Menu ads
        Set-ItemProperty -Path $cdmPath -Name "SubscribedContent-338393Enabled" -Value 0 -Type DWord -Force
        Set-ItemProperty -Path $cdmPath -Name "SubscribedContent-353694Enabled" -Value 0 -Type DWord -Force
        Set-ItemProperty -Path $cdmPath -Name "SubscribedContent-353696Enabled" -Value 0 -Type DWord -Force
        
        # Disable suggestions in Start Menu
        Set-ItemProperty -Path $cdmPath -Name "SubscribedContent-338388Enabled" -Value 0 -Type DWord -Force
        
        # Disable cloud content
        Set-ItemProperty -Path $cdmPath -Name "SubscribedContentEnabled" -Value 0 -Type DWord -Force
        
        # Disable pre-installed apps suggestions
        Set-ItemProperty -Path $cdmPath -Name "PreInstalledAppsEnabled" -Value 0 -Type DWord -Force
        Set-ItemProperty -Path $cdmPath -Name "PreInstalledAppsEverEnabled" -Value 0 -Type DWord -Force
        Set-ItemProperty -Path $cdmPath -Name "OemPreInstalledAppsEnabled" -Value 0 -Type DWord -Force
        
        # Disable suggestions on lock screen
        Set-ItemProperty -Path $cdmPath -Name "RotatingLockScreenEnabled" -Value 0 -Type DWord -Force
        Set-ItemProperty -Path $cdmPath -Name "RotatingLockScreenOverlayEnabled" -Value 0 -Type DWord -Force
        
        # Disable tips and suggestions
        Set-ItemProperty -Path $cdmPath -Name "SoftLandingEnabled" -Value 0 -Type DWord -Force
        
        Write-Host "[+] SUCCESS: Start Menu ads & suggestions disabled" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "[!] ERROR: Failed to disable Start Menu ads: $_" -ForegroundColor Red
        return $false
    }
}

function Add-ChromeToTaskbar {
    <#
    .SYNOPSIS
        Pins Google Chrome to the Taskbar.
    #>
    
    Write-Host "[*] Pinning Google Chrome to Taskbar..." -ForegroundColor Cyan
    
    try {
        # Find Chrome executable
        $chromePath = "${env:ProgramFiles}\Google\Chrome\Application\chrome.exe"
        $chromePathX86 = "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe"
        
        if (-not (Test-Path $chromePath) -and -not (Test-Path $chromePathX86)) {
            Write-Host "[!] WARNING: Google Chrome not found. Please install Chrome first." -ForegroundColor Yellow
            return $false
        }
        
        $actualPath = if (Test-Path $chromePath) { $chromePath } else { $chromePathX86 }
        
        # Create shortcut in taskbar pins folder
        $taskbarPath = "$env:APPDATA\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar"
        
        if (-not (Test-Path $taskbarPath)) {
            New-Item -Path $taskbarPath -ItemType Directory -Force | Out-Null
        }
        
        $shortcutPath = Join-Path $taskbarPath "Google Chrome.lnk"
        
        # Create shortcut using WScript.Shell
        $WshShell = New-Object -ComObject WScript.Shell
        $Shortcut = $WshShell.CreateShortcut($shortcutPath)
        $Shortcut.TargetPath = $actualPath
        $Shortcut.Description = "Google Chrome"
        $Shortcut.Save()
        
        # Release COM object
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($WshShell) | Out-Null
        
        Write-Host "[+] SUCCESS: Google Chrome shortcut added to Taskbar" -ForegroundColor Green
        Write-Host "[*] You may need to restart Explorer or log off for changes to appear" -ForegroundColor Yellow
        return $true
    }
    catch {
        Write-Host "[!] ERROR: Failed to pin Chrome to Taskbar: $_" -ForegroundColor Red
        Write-Host "[!] You can manually pin Chrome by right-clicking it and selecting 'Pin to taskbar'" -ForegroundColor Yellow
        return $false
    }
}

function Enable-TaskbarEndTask {
    <#
    .SYNOPSIS
        Enables "End Task" option in the Taskbar context menu.
    #>
    
    Write-Host "[*] Enabling 'End Task' option in Taskbar..." -ForegroundColor Cyan
    
    try {
        $advancedPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
        
        # Ensure the path exists
        if (-not (Test-Path $advancedPath)) {
            New-Item -Path $advancedPath -Force | Out-Null
        }
        
        # Enable "End Task" in Taskbar (Windows 11 feature)
        Set-ItemProperty -Path $advancedPath -Name "TaskbarEndTask" -Value 1 -Type DWord -Force
        
        Write-Host "[+] SUCCESS: 'End Task' option enabled in Taskbar" -ForegroundColor Green
        Write-Host "[*] Right-click on any app in the Taskbar to see the 'End Task' option" -ForegroundColor Yellow
        Write-Host "[*] Note: This feature is available in Windows 11" -ForegroundColor Yellow
        return $true
    }
    catch {
        Write-Host "[!] ERROR: Failed to enable 'End Task' option: $_" -ForegroundColor Red
        return $false
    }
}

function Disable-MicrosoftCopilot {
    <#
    .SYNOPSIS
        Disables Microsoft Copilot in the Taskbar.
    #>
    
    Write-Host "[*] Disabling Microsoft Copilot in Taskbar..." -ForegroundColor Cyan
    
    try {
        $advancedPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
        
        # Ensure the path exists
        if (-not (Test-Path $advancedPath)) {
            New-Item -Path $advancedPath -Force | Out-Null
        }
        
        # Disable Copilot button in Taskbar (Windows 11)
        Set-ItemProperty -Path $advancedPath -Name "ShowCopilotButton" -Value 0 -Type DWord -Force
        
        # Alternative registry key
        $copilotPolicyPath = "HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot"
        if (-not (Test-Path $copilotPolicyPath)) {
            New-Item -Path $copilotPolicyPath -Force | Out-Null
        }
        Set-ItemProperty -Path $copilotPolicyPath -Name "TurnOffWindowsCopilot" -Value 1 -Type DWord -Force
        
        # Machine-level disable (requires admin)
        $copilotMachinePath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot"
        if (-not (Test-Path $copilotMachinePath)) {
            New-Item -Path $copilotMachinePath -Force -ErrorAction SilentlyContinue | Out-Null
        }
        Set-ItemProperty -Path $copilotMachinePath -Name "TurnOffWindowsCopilot" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
        
        Write-Host "[+] SUCCESS: Microsoft Copilot disabled in Taskbar" -ForegroundColor Green
        Write-Host "[*] You may need to restart Explorer or log off for changes to take effect" -ForegroundColor Yellow
        return $true
    }
    catch {
        Write-Host "[!] ERROR: Failed to disable Microsoft Copilot: $_" -ForegroundColor Red
        return $false
    }
}

function New-SystemRestorePointTweak {
    <#
    .SYNOPSIS
        Creates a System Restore Point.
    #>
    
    Write-Host "[*] Creating System Restore Point..." -ForegroundColor Cyan
    
    try {
        # Check if System Restore is enabled
        $systemDrive = $env:SystemDrive
        $restoreStatus = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore" -Name "RPSessionInterval" -ErrorAction SilentlyContinue
        
        if (-not $restoreStatus) {
            Write-Host "[!] WARNING: System Restore may not be enabled" -ForegroundColor Yellow
        }
        
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $description = "SouliTEK Essential Tweaks - $timestamp"
        
        Write-Host "[*] Description: $description" -ForegroundColor Gray
        
        Checkpoint-Computer -Description $description -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop
        
        Write-Host "[+] SUCCESS: System Restore Point created" -ForegroundColor Green
        Write-Host "    Description: $description" -ForegroundColor White
        Write-Host "    Timestamp: $timestamp" -ForegroundColor White
        return $true
    }
    catch {
        Write-Host "[!] ERROR: Failed to create restore point: $_" -ForegroundColor Red
        Write-Host "[!] System Restore may not be enabled on this system" -ForegroundColor Yellow
        return $false
    }
}

# ============================================================
# MAIN MENU
# ============================================================

function Show-MainMenu {
    Show-SouliTEKHeader -Title "ESSENTIAL TWEAKS" -ClearHost -ShowBanner
    
    Write-Host "ESSENTIAL TWEAKS MENU" -ForegroundColor Cyan
    Write-Host ("=" * 60) -ForegroundColor Gray
    Write-Host ""
    Write-Host "  1.  Set Google Chrome as default browser" -ForegroundColor White
    Write-Host "  2.  Set Adobe Acrobat Reader as default PDF app" -ForegroundColor White
    Write-Host "  3.  Add Hebrew keyboard" -ForegroundColor White
    Write-Host "  4.  Add English (US) keyboard" -ForegroundColor White
    Write-Host "  5.  Set Hebrew as main display language" -ForegroundColor White
    Write-Host "  6.  Disable Start Menu ads & suggestions" -ForegroundColor White
    Write-Host "  7.  Pin Google Chrome to Taskbar" -ForegroundColor White
    Write-Host "  8.  Enable 'End Task' option in Taskbar" -ForegroundColor White
    Write-Host "  9.  Disable Microsoft Copilot in Taskbar" -ForegroundColor White
    Write-Host "  10. Create a System Restore Point" -ForegroundColor White
    Write-Host ""
    Write-Host "  11. Apply All Tweaks" -ForegroundColor Yellow
    Write-Host "  0.  Exit" -ForegroundColor White
    Write-Host ""
    Write-Host ("=" * 60) -ForegroundColor Gray
    Write-Host ""
}

function Invoke-Tweak {
    param(
        [int]$TweakNumber
    )
    
    $success = $false
    
    switch ($TweakNumber) {
        1 { $success = Set-GoogleChromeDefault }
        2 { $success = Set-AdobeAcrobatDefault }
        3 { $success = Add-HebrewKeyboard }
        4 { $success = Add-EnglishUSKeyboard }
        5 { $success = Set-HebrewDisplayLanguage }
        6 { $success = Disable-StartMenuAds }
        7 { $success = Add-ChromeToTaskbar }
        8 { $success = Enable-TaskbarEndTask }
        9 { $success = Disable-MicrosoftCopilot }
        10 { $success = New-SystemRestorePointTweak }
        default { return $false }
    }
    
    return $success
}

function Invoke-AllTweaks {
    <#
    .SYNOPSIS
        Applies all tweaks in sequence.
    #>
    
    Show-SouliTEKHeader -Title "APPLYING ALL TWEAKS" -ClearHost -ShowBanner
    
    Write-Host "This will apply all 10 essential tweaks." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Tweaks to be applied:" -ForegroundColor Cyan
    Write-Host "  1.  Set Google Chrome as default browser" -ForegroundColor Gray
    Write-Host "  2.  Set Adobe Acrobat Reader as default PDF app" -ForegroundColor Gray
    Write-Host "  3.  Add Hebrew keyboard" -ForegroundColor Gray
    Write-Host "  4.  Add English (US) keyboard" -ForegroundColor Gray
    Write-Host "  5.  Set Hebrew as main display language" -ForegroundColor Gray
    Write-Host "  6.  Disable Start Menu ads & suggestions" -ForegroundColor Gray
    Write-Host "  7.  Pin Google Chrome to Taskbar" -ForegroundColor Gray
    Write-Host "  8.  Enable 'End Task' option in Taskbar" -ForegroundColor Gray
    Write-Host "  9.  Disable Microsoft Copilot in Taskbar" -ForegroundColor Gray
    Write-Host "  10. Create a System Restore Point" -ForegroundColor Gray
    Write-Host ""
    
    $confirm = Read-Host "Continue? (Y/N)"
    
    if ($confirm -ne "Y" -and $confirm -ne "y") {
        Write-Host "[*] Operation cancelled" -ForegroundColor Yellow
        return
    }
    
    Write-Host ""
    Write-Host "Applying tweaks..." -ForegroundColor Cyan
    Write-Host ("=" * 60) -ForegroundColor Gray
    Write-Host ""
    
    $results = @()
    $tweakNames = @(
        "Set Google Chrome as default browser",
        "Set Adobe Acrobat Reader as default PDF app",
        "Add Hebrew keyboard",
        "Add English (US) keyboard",
        "Set Hebrew as main display language",
        "Disable Start Menu ads & suggestions",
        "Pin Google Chrome to Taskbar",
        "Enable 'End Task' option in Taskbar",
        "Disable Microsoft Copilot in Taskbar",
        "Create a System Restore Point"
    )
    
    for ($i = 1; $i -le 10; $i++) {
        Write-Host ""
        Write-Host "[$i/10] $($tweakNames[$i-1])" -ForegroundColor Cyan
        Write-Host ("-" * 40) -ForegroundColor Gray
        $success = Invoke-Tweak -TweakNumber $i
        $results += @{
            Number = $i
            Name = $tweakNames[$i-1]
            Success = $success
        }
        Start-Sleep -Milliseconds 500
    }
    
    Write-Host ""
    Write-Host ("=" * 60) -ForegroundColor Gray
    Write-Host ""
    Write-Host "SUMMARY" -ForegroundColor Cyan
    Write-Host ("=" * 60) -ForegroundColor Gray
    Write-Host ""
    
    $successCount = ($results | Where-Object { $_.Success }).Count
    $failCount = 10 - $successCount
    
    Write-Host "  Successful: $successCount" -ForegroundColor Green
    Write-Host "  Failed/Skipped: $failCount" -ForegroundColor $(if ($failCount -gt 0) { "Yellow" } else { "Gray" })
    Write-Host ""
    
    if ($failCount -gt 0) {
        Write-Host "Failed/Skipped tweaks:" -ForegroundColor Yellow
        foreach ($result in $results | Where-Object { -not $_.Success }) {
            Write-Host "  - $($result.Name)" -ForegroundColor Yellow
        }
        Write-Host ""
    }
    
    Write-Host "[*] Some changes may require a restart or re-login to take effect" -ForegroundColor Yellow
}

# Show-ExitMessage function - using Show-SouliTEKExitMessage from common module
function Show-ExitMessage {
    Show-SouliTEKExitMessage -ScriptPath $PSCommandPath -ToolName "SouliTEK Essential Tweaks"
}

function Start-MainLoop {
    while ($true) {
        Show-MainMenu
        
        $choice = Read-Host "Select an option (0-11)"
        
        switch ($choice) {
            { $_ -match "^([1-9]|10)$" } {
                $tweakNum = [int]$_
                Show-SouliTEKHeader -Title "ESSENTIAL TWEAKS" -ClearHost -ShowBanner
                $success = Invoke-Tweak -TweakNumber $tweakNum
                Write-Host ""
                Write-Host "Press Enter to return to menu..."
                Read-Host | Out-Null
            }
            "11" {
                Invoke-AllTweaks
                Write-Host ""
                Write-Host "Press Enter to return to menu..."
                Read-Host | Out-Null
            }
            "0" {
                Show-ExitMessage
                exit 0
            }
            default {
                Write-Host ""
                Write-Host "[!] Invalid option. Please select 0-11." -ForegroundColor Red
                Write-Host ""
                Start-Sleep -Seconds 1
            }
        }
    }
}

# ============================================================
# SCRIPT EXECUTION
# ============================================================

# Check administrator privileges
if (-not (Test-SouliTEKAdministrator)) {
    Show-SouliTEKHeader -Title "ESSENTIAL TWEAKS" -ClearHost -ShowBanner
    Write-Host "[!] ERROR: Administrator privileges required!" -ForegroundColor Red
    Write-Host "[!] Please run this script as Administrator." -ForegroundColor Red
    Write-Host ""
    Write-Host "The script will now exit." -ForegroundColor Yellow
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit 1
}

# Start main loop
Start-MainLoop

