# ============================================================
# Essential Tweaks - Windows Configuration Tool
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
# This tool provides essential Windows tweaks and configurations:
# - Default application settings
# - Keyboard layout management
# - Display language configuration
# - Taskbar customization
# - Start Menu optimization
# - System protection
# 
# Features: Quick Tweaks | Apply All | Detailed Summary
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

#Requires -Version 5.1

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
# GLOBAL VARIABLES
# ============================================================

$Script:TweakResults = @()
$Script:SuccessCount = 0
$Script:ErrorCount = 0

# ============================================================
# HELPER FUNCTIONS
# ============================================================

function Add-TweakResult {
    param(
        [string]$TweakName,
        [string]$Status,
        [string]$Details = ""
    )
    
    $Script:TweakResults += [PSCustomObject]@{
        Tweak = $TweakName
        Status = $Status
        Details = $Details
        Time = Get-Date -Format "HH:mm:ss"
    }
    
    if ($Status -eq "SUCCESS") {
        $Script:SuccessCount++
    } else {
        $Script:ErrorCount++
    }
}

function Show-Menu {
    Show-SouliTEKHeader -Title "ESSENTIAL TWEAKS" -ClearHost -ShowBanner
    
    Write-Host "  Select an option:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  [1]  Set Google Chrome as default browser" -ForegroundColor Cyan
    Write-Host "  [2]  Set Adobe Acrobat Reader as default PDF app" -ForegroundColor Cyan
    Write-Host "  [3]  Add Hebrew keyboard" -ForegroundColor Cyan
    Write-Host "  [4]  Add English (US) keyboard" -ForegroundColor Cyan
    Write-Host "  [5]  Set Hebrew as main display language" -ForegroundColor Cyan
    Write-Host "  [6]  Disable Start Menu ads & suggestions" -ForegroundColor Cyan
    Write-Host "  [7]  Pin Google Chrome to Taskbar" -ForegroundColor Cyan
    Write-Host "  [8]  Enable 'End Task' option in Taskbar" -ForegroundColor Cyan
    Write-Host "  [9]  Disable Microsoft Copilot in Taskbar" -ForegroundColor Cyan
    Write-Host "  [10] Create a System Restore Point" -ForegroundColor Cyan
    Write-Host "  [11] Apply All Tweaks" -ForegroundColor Green
    Write-Host "  [0]  Exit" -ForegroundColor Red
    Write-Host ""
    Write-Host -NoNewline "  Enter your choice: " -ForegroundColor Cyan
}

function Set-ChromeAsDefaultBrowser {
    Show-SouliTEKHeader -Title "SET CHROME AS DEFAULT BROWSER" -ClearHost -ShowBanner
    Write-SouliTEKInfo "Opening Windows Settings for default browser configuration..."
    
    try {
        # Check if Chrome is installed
        $chromePaths = @(
            "${env:ProgramFiles}\Google\Chrome\Application\chrome.exe",
            "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe",
            "$env:LOCALAPPDATA\Google\Chrome\Application\chrome.exe"
        )
        
        $chromeFound = $false
        foreach ($path in $chromePaths) {
            if (Test-Path $path) {
                $chromeFound = $true
                break
            }
        }
        
        if (-not $chromeFound) {
            Write-SouliTEKWarning "Google Chrome not found in common installation paths"
            Write-Host "  Please install Chrome first, or manually set it as default browser" -ForegroundColor Yellow
            Add-TweakResult -TweakName "Set Chrome as Default Browser" -Status "ERROR" -Details "Chrome not found"
            Start-Sleep -Seconds 3
            return $false
        }
        
        # Open Windows Settings to default apps
        Start-Process "ms-settings:defaultapps" -ErrorAction Stop
        
        Write-SouliTEKSuccess "Windows Settings opened"
        Write-Host "  Please select Google Chrome as your default browser in the settings window" -ForegroundColor Yellow
        Write-Host "  This requires manual confirmation due to Windows security requirements" -ForegroundColor Gray
        
        Add-TweakResult -TweakName "Set Chrome as Default Browser" -Status "SUCCESS" -Details "Settings opened - manual confirmation required"
        
        Start-Sleep -Seconds 3
        return $true
    } catch {
        Write-SouliTEKError "Failed to open Windows Settings: $($_.Exception.Message)"
        Add-TweakResult -TweakName "Set Chrome as Default Browser" -Status "ERROR" -Details $_.Exception.Message
        Start-Sleep -Seconds 3
        return $false
    }
}

function Set-AcrobatAsDefaultPDF {
    Show-SouliTEKHeader -Title "SET ACROBAT AS DEFAULT PDF APP" -ClearHost -ShowBanner
    Write-SouliTEKInfo "Opening Windows Settings for PDF app configuration..."
    
    try {
        # Check if Acrobat Reader is installed
        $acrobatPaths = @(
            "${env:ProgramFiles}\Adobe\Acrobat Reader DC\Reader\AcroRd32.exe",
            "${env:ProgramFiles(x86)}\Adobe\Acrobat Reader DC\Reader\AcroRd32.exe",
            "${env:ProgramFiles}\Adobe\Acrobat DC\Acrobat\Acrobat.exe",
            "${env:ProgramFiles(x86)}\Adobe\Acrobat DC\Acrobat\Acrobat.exe"
        )
        
        $acrobatFound = $false
        foreach ($path in $acrobatPaths) {
            if (Test-Path $path) {
                $acrobatFound = $true
                break
            }
        }
        
        if (-not $acrobatFound) {
            Write-SouliTEKWarning "Adobe Acrobat Reader not found in common installation paths"
            Write-Host "  Please install Acrobat Reader first, or manually set it as default PDF app" -ForegroundColor Yellow
            Add-TweakResult -TweakName "Set Acrobat as Default PDF" -Status "ERROR" -Details "Acrobat not found"
            Start-Sleep -Seconds 3
            return $false
        }
        
        # Open Windows Settings to default apps
        Start-Process "ms-settings:defaultapps" -ErrorAction Stop
        
        Write-SouliTEKSuccess "Windows Settings opened"
        Write-Host "  Please select Adobe Acrobat Reader as your default PDF app in the settings window" -ForegroundColor Yellow
        Write-Host "  This requires manual confirmation due to Windows security requirements" -ForegroundColor Gray
        
        Add-TweakResult -TweakName "Set Acrobat as Default PDF" -Status "SUCCESS" -Details "Settings opened - manual confirmation required"
        
        Start-Sleep -Seconds 3
        return $true
    } catch {
        Write-SouliTEKError "Failed to open Windows Settings: $($_.Exception.Message)"
        Add-TweakResult -TweakName "Set Acrobat as Default PDF" -Status "ERROR" -Details $_.Exception.Message
        Start-Sleep -Seconds 3
        return $false
    }
}

function Add-HebrewKeyboard {
    Show-SouliTEKHeader -Title "ADD HEBREW KEYBOARD" -ClearHost -ShowBanner
    Write-SouliTEKInfo "Adding Hebrew (he-IL) keyboard layout..."
    
    try {
        $languageList = Get-WinUserLanguageList
        
        # Check if Hebrew is already in the list
        if ($languageList | Where-Object { $_.LanguageTag -eq "he-IL" }) {
            Write-SouliTEKSuccess "Hebrew keyboard is already added"
            Add-TweakResult -TweakName "Add Hebrew Keyboard" -Status "SUCCESS" -Details "Already added"
            Start-Sleep -Seconds 2
            return $true
        }
        
        # Add Hebrew to the language list
        $languageList.Add("he-IL")
        Set-WinUserLanguageList $languageList -Force -ErrorAction Stop
        
        Write-SouliTEKSuccess "Hebrew keyboard added successfully"
        Write-Host "  You can switch keyboards using Windows key + Space" -ForegroundColor Gray
        
        Add-TweakResult -TweakName "Add Hebrew Keyboard" -Status "SUCCESS" -Details "Hebrew (he-IL) added"
        
        Start-Sleep -Seconds 2
        return $true
    } catch {
        Write-SouliTEKError "Failed to add Hebrew keyboard: $($_.Exception.Message)"
        Add-TweakResult -TweakName "Add Hebrew Keyboard" -Status "ERROR" -Details $_.Exception.Message
        Start-Sleep -Seconds 3
        return $false
    }
}

function Add-EnglishKeyboard {
    Show-SouliTEKHeader -Title "ADD ENGLISH (US) KEYBOARD" -ClearHost -ShowBanner
    Write-SouliTEKInfo "Adding English (US) keyboard layout..."
    
    try {
        $languageList = Get-WinUserLanguageList
        
        # Check if English (US) is already in the list
        if ($languageList | Where-Object { $_.LanguageTag -eq "en-US" }) {
            Write-SouliTEKSuccess "English (US) keyboard is already added"
            Add-TweakResult -TweakName "Add English (US) Keyboard" -Status "SUCCESS" -Details "Already added"
            Start-Sleep -Seconds 2
            return $true
        }
        
        # Add English (US) to the language list
        $languageList.Add("en-US")
        Set-WinUserLanguageList $languageList -Force -ErrorAction Stop
        
        Write-SouliTEKSuccess "English (US) keyboard added successfully"
        Write-Host "  You can switch keyboards using Windows key + Space" -ForegroundColor Gray
        
        Add-TweakResult -TweakName "Add English (US) Keyboard" -Status "SUCCESS" -Details "English (en-US) added"
        
        Start-Sleep -Seconds 2
        return $true
    } catch {
        Write-SouliTEKError "Failed to add English (US) keyboard: $($_.Exception.Message)"
        Add-TweakResult -TweakName "Add English (US) Keyboard" -Status "ERROR" -Details $_.Exception.Message
        Start-Sleep -Seconds 3
        return $false
    }
}

function Set-HebrewAsDisplayLanguage {
    Show-SouliTEKHeader -Title "SET HEBREW AS DISPLAY LANGUAGE" -ClearHost -ShowBanner
    Write-SouliTEKInfo "Setting Hebrew as main display language..."
    
    try {
        $languageList = Get-WinUserLanguageList
        
        # Check if Hebrew is already the primary language
        if ($languageList[0].LanguageTag -eq "he-IL") {
            Write-SouliTEKSuccess "Hebrew is already the main display language"
            Add-TweakResult -TweakName "Set Hebrew as Display Language" -Status "SUCCESS" -Details "Already set"
            Start-Sleep -Seconds 2
            return $true
        }
        
        # Check if Hebrew is in the list
        $hebrewLang = $languageList | Where-Object { $_.LanguageTag -eq "he-IL" }
        
        if (-not $hebrewLang) {
            # Add Hebrew if not present
            $languageList.Add("he-IL")
        }
        
        # Move Hebrew to the first position (primary language)
        $hebrewLang = $languageList | Where-Object { $_.LanguageTag -eq "he-IL" }
        $languageList.Remove($hebrewLang)
        $languageList.Insert(0, $hebrewLang)
        
        Set-WinUserLanguageList $languageList -Force -ErrorAction Stop
        
        Write-SouliTEKSuccess "Hebrew set as main display language"
        Write-Host "  NOTE: You may need to sign out and back in for changes to take full effect" -ForegroundColor Yellow
        Write-Host "  Windows may need to download the Hebrew language pack" -ForegroundColor Gray
        
        Add-TweakResult -TweakName "Set Hebrew as Display Language" -Status "SUCCESS" -Details "Hebrew set as primary - sign out required"
        
        Start-Sleep -Seconds 3
        return $true
    } catch {
        Write-SouliTEKError "Failed to set Hebrew as display language: $($_.Exception.Message)"
        Add-TweakResult -TweakName "Set Hebrew as Display Language" -Status "ERROR" -Details $_.Exception.Message
        Start-Sleep -Seconds 3
        return $false
    }
}

function Disable-StartMenuAds {
    Show-SouliTEKHeader -Title "DISABLE START MENU ADS" -ClearHost -ShowBanner
    Write-SouliTEKInfo "Disabling Start Menu ads and suggestions..."
    
    try {
        $regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
        
        # Ensure the registry path exists
        if (-not (Test-Path $regPath)) {
            New-Item -Path $regPath -Force | Out-Null
        }
        
        # Disable various ad and suggestion features
        $settings = @{
            "SystemPaneSuggestionsEnabled" = 0
            "SubscribedContent-338393Enabled" = 0
            "SubscribedContent-353694Enabled" = 0
            "SubscribedContent-353696Enabled" = 0
            "SubscribedContent-338388Enabled" = 0
            "SubscribedContentEnabled" = 0
        }
        
        foreach ($setting in $settings.GetEnumerator()) {
            Set-ItemProperty -Path $regPath -Name $setting.Key -Value $setting.Value -Type DWord -ErrorAction Stop
        }
        
        Write-SouliTEKSuccess "Start Menu ads and suggestions disabled"
        Write-Host "  You may need to restart Explorer or sign out for changes to take effect" -ForegroundColor Gray
        
        Add-TweakResult -TweakName "Disable Start Menu Ads" -Status "SUCCESS" -Details "All ad settings disabled"
        
        Start-Sleep -Seconds 2
        return $true
    } catch {
        Write-SouliTEKError "Failed to disable Start Menu ads: $($_.Exception.Message)"
        Add-TweakResult -TweakName "Disable Start Menu Ads" -Status "ERROR" -Details $_.Exception.Message
        Start-Sleep -Seconds 3
        return $false
    }
}

function Pin-ChromeToTaskbar {
    Show-SouliTEKHeader -Title "PIN CHROME TO TASKBAR" -ClearHost -ShowBanner
    Write-SouliTEKInfo "Pinning Google Chrome to taskbar..."
    
    try {
        # Find Chrome executable
        $chromePaths = @(
            "${env:ProgramFiles}\Google\Chrome\Application\chrome.exe",
            "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe",
            "$env:LOCALAPPDATA\Google\Chrome\Application\chrome.exe"
        )
        
        $chromePath = $null
        foreach ($path in $chromePaths) {
            if (Test-Path $path) {
                $chromePath = $path
                break
            }
        }
        
        if (-not $chromePath) {
            Write-SouliTEKWarning "Google Chrome not found"
            Write-Host "  Please install Chrome first" -ForegroundColor Yellow
            Add-TweakResult -TweakName "Pin Chrome to Taskbar" -Status "ERROR" -Details "Chrome not found"
            Start-Sleep -Seconds 3
            return $false
        }
        
        # Pin to taskbar using shell
        $shell = New-Object -ComObject Shell.Application
        $folder = $shell.Namespace((Split-Path $chromePath))
        $item = $folder.ParseName((Split-Path -Leaf $chromePath))
        $item.InvokeVerb("taskbarpin")
        
        Write-SouliTEKSuccess "Chrome pinned to taskbar successfully"
        
        Add-TweakResult -TweakName "Pin Chrome to Taskbar" -Status "SUCCESS" -Details "Chrome pinned"
        
        Start-Sleep -Seconds 2
        return $true
    } catch {
        Write-SouliTEKError "Failed to pin Chrome to taskbar: $($_.Exception.Message)"
        Add-TweakResult -TweakName "Pin Chrome to Taskbar" -Status "ERROR" -Details $_.Exception.Message
        Start-Sleep -Seconds 3
        return $false
    }
}

function Enable-TaskbarEndTask {
    Show-SouliTEKHeader -Title "ENABLE END TASK IN TASKBAR" -ClearHost -ShowBanner
    Write-SouliTEKInfo "Enabling 'End Task' option in taskbar (Windows 11)..."
    
    try {
        $regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
        
        # Ensure the registry path exists
        if (-not (Test-Path $regPath)) {
            New-Item -Path $regPath -Force | Out-Null
        }
        
        # Enable End Task in taskbar
        Set-ItemProperty -Path $regPath -Name "TaskbarEndTask" -Value 1 -Type DWord -ErrorAction Stop
        
        Write-SouliTEKSuccess "'End Task' option enabled in taskbar"
        Write-Host "  Right-click on taskbar icons to see 'End Task' option" -ForegroundColor Gray
        Write-Host "  You may need to restart Explorer for changes to take effect" -ForegroundColor Yellow
        
        Add-TweakResult -TweakName "Enable End Task in Taskbar" -Status "SUCCESS" -Details "End Task enabled"
        
        Start-Sleep -Seconds 2
        return $true
    } catch {
        Write-SouliTEKError "Failed to enable End Task: $($_.Exception.Message)"
        Add-TweakResult -TweakName "Enable End Task in Taskbar" -Status "ERROR" -Details $_.Exception.Message
        Start-Sleep -Seconds 3
        return $false
    }
}

function Disable-Copilot {
    Show-SouliTEKHeader -Title "DISABLE MICROSOFT COPILOT" -ClearHost -ShowBanner
    Write-SouliTEKInfo "Disabling Microsoft Copilot in taskbar..."
    
    try {
        # User-level policy
        $userRegPath = "HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot"
        if (-not (Test-Path $userRegPath)) {
            New-Item -Path $userRegPath -Force | Out-Null
        }
        Set-ItemProperty -Path $userRegPath -Name "TurnOffWindowsCopilot" -Value 1 -Type DWord -ErrorAction Stop
        
        # System-level policy (requires admin)
        if (Test-SouliTEKAdministrator) {
            $systemRegPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot"
            if (-not (Test-Path $systemRegPath)) {
                New-Item -Path $systemRegPath -Force | Out-Null
            }
            Set-ItemProperty -Path $systemRegPath -Name "TurnOffWindowsCopilot" -Value 1 -Type DWord -ErrorAction Stop
        }
        
        # Also disable via Explorer Advanced settings
        $explorerPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
        if (-not (Test-Path $explorerPath)) {
            New-Item -Path $explorerPath -Force | Out-Null
        }
        Set-ItemProperty -Path $explorerPath -Name "ShowCopilotButton" -Value 0 -Type DWord -ErrorAction Stop
        
        Write-SouliTEKSuccess "Microsoft Copilot disabled"
        Write-Host "  You may need to restart Explorer or sign out for changes to take effect" -ForegroundColor Yellow
        Write-Host "  Restart Explorer: Stop-Process -Name explorer -Force" -ForegroundColor Gray
        
        Add-TweakResult -TweakName "Disable Microsoft Copilot" -Status "SUCCESS" -Details "Copilot disabled via registry"
        
        Start-Sleep -Seconds 2
        return $true
    } catch {
        Write-SouliTEKError "Failed to disable Copilot: $($_.Exception.Message)"
        Add-TweakResult -TweakName "Disable Microsoft Copilot" -Status "ERROR" -Details $_.Exception.Message
        Start-Sleep -Seconds 3
        return $false
    }
}

function New-SystemRestorePoint {
    Show-SouliTEKHeader -Title "CREATE SYSTEM RESTORE POINT" -ClearHost -ShowBanner
    Write-SouliTEKInfo "Creating system restore point..."
    
    try {
        $systemDrive = $env:SystemDrive
        $restoreEnabled = Get-ComputerRestorePoint -ErrorAction SilentlyContinue
        
        if (-not $restoreEnabled) {
            Write-SouliTEKWarning "System Restore may not be enabled"
            Write-Host "  Attempting to enable System Restore..." -ForegroundColor Yellow
            
            $enableResult = Enable-ComputerRestore -Drive "$systemDrive\" -ErrorAction SilentlyContinue
            if (-not $?) {
                Write-SouliTEKWarning "Could not enable System Restore automatically"
            } else {
                Start-Sleep -Seconds 2
            }
        }
        
        $description = "Essential Tweaks - Before Changes ($(Get-Date -Format 'yyyy-MM-dd HH:mm'))"
        Write-Host "  Creating restore point: $description" -ForegroundColor Cyan
        
        Checkpoint-Computer -Description $description -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop
        
        Write-SouliTEKSuccess "System restore point created successfully"
        Add-TweakResult -TweakName "Create System Restore Point" -Status "SUCCESS" -Details $description
        
        Start-Sleep -Seconds 2
        return $true
    } catch {
        Write-SouliTEKWarning "Could not create system restore point: $($_.Exception.Message)"
        Add-TweakResult -TweakName "Create System Restore Point" -Status "ERROR" -Details $_.Exception.Message
        
        Write-Host ""
        Write-Host "  Continuing anyway... (This is not critical)" -ForegroundColor Yellow
        
        Start-Sleep -Seconds 3
        return $false
    }
}

function Show-Summary {
    Show-SouliTEKHeader -Title "TWEAKS SUMMARY" -ClearHost -ShowBanner
    
    Write-Host "  Results Summary:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Successful: " -NoNewline -ForegroundColor Gray
    Write-Host "$Script:SuccessCount tweak(s)" -ForegroundColor Green
    
    Write-Host "  Errors: " -NoNewline -ForegroundColor Gray
    Write-Host "$Script:ErrorCount tweak(s)" -ForegroundColor Red
    
    Write-Host ""
    Write-Host "  Detailed Results:" -ForegroundColor Yellow
    Write-Host ""
    
    foreach ($result in $Script:TweakResults) {
        $statusColor = switch ($result.Status) {
            "SUCCESS" { "Green" }
            "ERROR" { "Red" }
            default { "Gray" }
        }
        
        $statusSymbol = switch ($result.Status) {
            "SUCCESS" { "[+]" }
            "ERROR" { "[-]" }
            default { "[*]" }
        }
        
        Write-Host "  [$($result.Time)] " -NoNewline -ForegroundColor Gray
        Write-Host "$statusSymbol " -NoNewline -ForegroundColor $statusColor
        Write-Host "$($result.Tweak)" -ForegroundColor White
        
        if ($result.Details) {
            Write-Host "      -> $($result.Details)" -ForegroundColor Gray
        }
    }
    
    Write-Host ""
}

function Apply-AllTweaks {
    Show-SouliTEKHeader -Title "APPLY ALL TWEAKS" -ClearHost -ShowBanner
    
    Write-Host "  This will apply all available tweaks in sequence." -ForegroundColor Yellow
    Write-Host "  Some tweaks may require manual confirmation or system restart." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Do you want to proceed?" -ForegroundColor White
    Write-Host ""
    Write-Host "  [Y] Yes - Apply all tweaks" -ForegroundColor Green
    Write-Host "  [N] No  - Cancel" -ForegroundColor Red
    Write-Host ""
    Write-Host -NoNewline "  Enter your choice: " -ForegroundColor Cyan
    
    $choice = Read-Host
    
    if ($choice -ne 'Y' -and $choice -ne 'y') {
        return
    }
    
    Write-Host ""
    Write-Host "  Applying all tweaks..." -ForegroundColor Cyan
    Write-Host ""
    Start-Sleep -Seconds 2
    
    # Apply all tweaks in sequence
    Set-ChromeAsDefaultBrowser
    Set-AcrobatAsDefaultPDF
    Add-HebrewKeyboard
    Add-EnglishKeyboard
    Set-HebrewAsDisplayLanguage
    Disable-StartMenuAds
    Pin-ChromeToTaskbar
    Enable-TaskbarEndTask
    Disable-Copilot
    New-SystemRestorePoint
    
    Show-Summary
    
    Write-Host ""
    Write-Host "  All tweaks have been applied!" -ForegroundColor Green
    Write-Host ""
}

# ============================================================
# MAIN EXECUTION
# ============================================================

function Start-EssentialTweaks {
    if (-not (Test-SouliTEKAdministrator)) {
        Show-SouliTEKHeader -Title "ERROR: ADMINISTRATOR REQUIRED" -ClearHost -ShowBanner
        Write-Host ""
        Write-Host "  This script requires administrator privileges to run." -ForegroundColor Red
        Write-Host ""
        Write-Host "  Please right-click this script and select:" -ForegroundColor Yellow
        Write-Host "  'Run with PowerShell as administrator'" -ForegroundColor Yellow
        Write-Host ""
        Read-Host "  Press Enter to exit"
        exit 1
    }
    
    while ($true) {
        Show-Menu
        $choice = Read-Host
        
        switch ($choice) {
            "1" { Set-ChromeAsDefaultBrowser }
            "2" { Set-AcrobatAsDefaultPDF }
            "3" { Add-HebrewKeyboard }
            "4" { Add-EnglishKeyboard }
            "5" { Set-HebrewAsDisplayLanguage }
            "6" { Disable-StartMenuAds }
            "7" { Pin-ChromeToTaskbar }
            "8" { Enable-TaskbarEndTask }
            "9" { Disable-Copilot }
            "10" { New-SystemRestorePoint }
            "11" { Apply-AllTweaks }
            "0" {
                Write-Host ""
                Write-Host "  Exiting..." -ForegroundColor Yellow
                Write-Host ""
                exit 0
            }
            default {
                Write-Host ""
                Write-Host "  Invalid choice. Please try again." -ForegroundColor Red
                Start-Sleep -Seconds 2
            }
        }
        
        if ($choice -ne "11" -and $choice -ne "0") {
            Write-Host ""
            Write-Host -NoNewline "  Press Enter to continue..." -ForegroundColor Cyan
            Read-Host
        } elseif ($choice -eq "11") {
            Write-Host ""
            Write-Host -NoNewline "  Press Enter to continue..." -ForegroundColor Cyan
            Read-Host
        }
    }
}

Start-EssentialTweaks

