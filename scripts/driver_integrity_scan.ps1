# ============================================================
# Driver Integrity Scan - Professional Edition
# ============================================================
# 
# Coded by: Soulitek.co.il
# IT Solutions for your business
# 
# (C) 2025 SouliTEK - All Rights Reserved
# Website: www.soulitek.co.il
# 
# Professional IT Solutions:
# - Computer Repair & Maintenance
# - Network Setup & Support
# - Software Solutions
# - Business IT Consulting
# 
# This tool scans for driver issues, exports driver information,
# and updates installed software using Windows Package Manager (WinGet).
# 
# Features: Driver Integrity Scan | Export Driver List | Software Updates
#           Problem Device Detection | WinGet Integration
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

#Requires -RunAsAdministrator
#Requires -Version 5.1

# Set window title
$Host.UI.RawUI.WindowTitle = "DRIVER INTEGRITY SCAN"

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

$Script:ScanResults = @()
$Script:ProblemDevices = @()
$Script:AllDrivers = @()
$Script:OutputDir = "$env:USERPROFILE\Desktop"
$Script:LastScanFile = Join-Path $env:LOCALAPPDATA "SouliTEK\LastDriverScan.json"
$Script:WinGetAvailable = $false

# Error code descriptions
$Script:ErrorCodes = @{
    0 = "Device is working properly"
    1 = "Device is not configured correctly"
    3 = "Driver is corrupted"
    10 = "Device cannot start"
    12 = "Device cannot find enough free resources"
    18 = "Device drivers must be reinstalled"
    19 = "Registry returned unknown result"
    21 = "Windows is removing the device"
    22 = "Device is disabled"
    24 = "Device is not present, not working, or does not have all drivers installed"
    28 = "Device drivers are not installed"
    29 = "Device is disabled (firmware did not provide required resources)"
    31 = "Device is not working properly"
    32 = "Windows cannot load the device driver"
    33 = "Windows cannot determine which resources are required"
    34 = "Windows cannot determine the device settings"
    35 = "Computer's firmware does not include enough information"
    36 = "Device is requesting a PCI interrupt but is configured for ISA"
    37 = "Windows cannot initialize the device driver"
    38 = "Windows cannot load device driver (previous instance still loaded)"
    39 = "Windows cannot load device driver (corrupted)"
    40 = "Windows cannot access this device (service key missing)"
    41 = "Windows successfully loaded device driver but cannot find device"
    42 = "Windows cannot load device driver (duplicate device detected)"
    43 = "Windows has stopped this device (reported problems)"
    44 = "Application or service has shut down this device"
    45 = "Device is not connected to the computer"
    46 = "Windows cannot gain access to device (shutting down)"
    47 = "Windows cannot use device (prepared for safe removal)"
    48 = "Software for this device has been blocked from starting"
    49 = "Windows cannot start new devices (registry too large)"
    52 = "Windows cannot verify digital signature"
}

# ============================================================
# HELPER FUNCTIONS
# ============================================================

# Show-Header function removed - using Show-SouliTEKHeader from common module

function Get-WinGetAvailability {
    <#
    .SYNOPSIS
        Checks if WinGet is available on the system
    #>
    try {
        $wingetPath = Get-Command winget.exe -ErrorAction SilentlyContinue
        if ($wingetPath) {
            Write-Ui -Message "WinGet is available on this system" -Level "OK"
            return $true
        } else {
            Write-Ui -Message "WinGet is not available on this system" -Level "WARN"
            Write-Host "  [!] WinGet comes pre-installed on Windows 11 and Windows 10 (version 1809+)" -ForegroundColor Yellow
            Write-Host "  [!] You can install it from: https://aka.ms/getwinget" -ForegroundColor Yellow
            return $false
        }
    }
    catch {
        Write-Ui -Message "Error checking WinGet availability: $($_.Exception.Message)" -Level "ERROR"
        return $false
    }
}

function Get-DriverIntegrityStatus {
    <#
    .SYNOPSIS
        Scans for driver issues using WMI and PnP cmdlets
    #>
    Write-Ui -Message "Scanning for driver integrity issues" -Level "INFO"
    Write-Host ""
    
    $Script:ProblemDevices = @()
    $Script:AllDrivers = @()
    
    try {
        # Get all PnP devices
        Write-Host "  [*] Querying all hardware devices..." -ForegroundColor Cyan
        $allDevices = Get-WmiObject Win32_PnPEntity -ErrorAction Stop
        
        $totalDevices = $allDevices.Count
        $currentDevice = 0
        
        Write-Host "  [*] Found $totalDevices devices to analyze..." -ForegroundColor Cyan
        Write-Host ""
        
        foreach ($device in $allDevices) {
            $currentDevice++
            
            # Show progress every 50 devices
            if ($currentDevice % 50 -eq 0) {
                Write-Host "  [*] Progress: $currentDevice / $totalDevices devices analyzed..." -ForegroundColor Gray
            }
            
            $errorCode = if ($device.ConfigManagerErrorCode) { $device.ConfigManagerErrorCode } else { 0 }
            $errorDescription = if ($Script:ErrorCodes.ContainsKey($errorCode)) { $Script:ErrorCodes[$errorCode] } else { "Unknown error code: $errorCode" }
            
            $driverInfo = [PSCustomObject]@{
                DeviceName = if ($device.Name) { $device.Name } else { "Unknown Device" }
                Manufacturer = if ($device.Manufacturer) { $device.Manufacturer } else { "Unknown" }
                Status = if ($device.Status) { $device.Status } else { "Unknown" }
                ErrorCode = $errorCode
                ErrorDescription = $errorDescription
                DeviceID = if ($device.DeviceID) { $device.DeviceID } else { "N/A" }
                DriverVersion = if ($device.DriverVersion) { $device.DriverVersion } else { "N/A" }
                DriverDate = if ($device.DriverDate) { 
                    try { 
                        [Management.ManagementDateTimeConverter]::ToDateTime($device.DriverDate).ToString("yyyy-MM-dd") 
                    } catch { 
                        "N/A" 
                    }
                } else { "N/A" }
                Present = if ($null -ne $device.Present) { $device.Present } else { $false }
            }
            
            $Script:AllDrivers += $driverInfo
            
            # Check for problems
            if ($errorCode -ne 0 -or $device.Status -ne "OK") {
                $Script:ProblemDevices += $driverInfo
            }
        }
        
        Write-Host ""
        Write-Host "  [+] Device scan completed!" -ForegroundColor Green
        Write-Host ""
        
        # Display summary
        Write-Host "  " -NoNewline
        Write-Host "SCAN SUMMARY" -ForegroundColor Cyan -NoNewline
        Write-Host ""
        Write-Host "  ----------------------------------------" -ForegroundColor Gray
        Write-Host "  Total Devices:    " -NoNewline -ForegroundColor Gray
        Write-Host "$totalDevices" -ForegroundColor White
        Write-Host "  Problem Devices:  " -NoNewline -ForegroundColor Gray
        if ($Script:ProblemDevices.Count -gt 0) {
            Write-Host "$($Script:ProblemDevices.Count)" -ForegroundColor Red
        } else {
            Write-Host "0" -ForegroundColor Green
        }
        Write-Host "  ----------------------------------------" -ForegroundColor Gray
        Write-Host ""
        
        if ($Script:ProblemDevices.Count -gt 0) {
            Write-Host "  " -NoNewline
            Write-Host "PROBLEM DEVICES DETECTED:" -ForegroundColor Red
            Write-Host ""
            
            $problemCount = 0
            foreach ($problem in $Script:ProblemDevices) {
                $problemCount++
                if ($problemCount -le 10) {
                    Write-Host "  [$problemCount] $($problem.DeviceName)" -ForegroundColor Yellow
                    Write-Host "      Status: $($problem.Status) | Error Code: $($problem.ErrorCode)" -ForegroundColor Gray
                    Write-Host "      Issue: $($problem.ErrorDescription)" -ForegroundColor Gray
                    Write-Host ""
                }
            }
            
            if ($Script:ProblemDevices.Count -gt 10) {
                Write-Host "  [!] ... and $($Script:ProblemDevices.Count - 10) more problem devices" -ForegroundColor Yellow
                Write-Host "  [!] Export the full report to see all issues" -ForegroundColor Yellow
                Write-Host ""
            }
        } else {
            Write-Ui -Message "All devices are working properly" -Level "OK"
            Write-Host ""
        }
        
        # Save scan results
        Save-ScanResults
        
        return $true
    }
    catch {
        Write-Ui -Message "Failed to scan drivers: $($_.Exception.Message)" -Level "ERROR"
        return $false
    }
}

function Save-ScanResults {
    <#
    .SYNOPSIS
        Saves scan results to a JSON file for later viewing
    #>
    try {
        $resultDir = Split-Path -Parent $Script:LastScanFile
        if (-not (Test-Path $resultDir)) {
            New-Item -Path $resultDir -ItemType Directory -Force | Out-Null
        }
        
        $scanData = @{
            Timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
            TotalDevices = $Script:AllDrivers.Count
            ProblemDevices = $Script:ProblemDevices.Count
            Devices = $Script:AllDrivers
            Problems = $Script:ProblemDevices
        }
        
        $scanData | ConvertTo-Json -Depth 10 | Set-Content -Path $Script:LastScanFile -Force
    }
    catch {
        Write-Verbose "Could not save scan results: $_"
    }
}

function Export-DriverList {
    <#
    .SYNOPSIS
        Exports driver list to CSV and TXT formats
    #>
    param(
        [switch]$ProblemsOnly
    )
    
    if ($Script:AllDrivers.Count -eq 0) {
        Write-Ui -Message "No driver data available. Please run a scan first" -Level "WARN"
        return $false
    }
    
    try {
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $computerName = $env:COMPUTERNAME
        
        if ($ProblemsOnly) {
            $exportData = $Script:ProblemDevices
            $csvFile = Join-Path $Script:OutputDir "DriverProblems_${computerName}_${timestamp}.csv"
            $txtFile = Join-Path $Script:OutputDir "DriverProblems_${computerName}_${timestamp}.txt"
        } else {
            $exportData = $Script:AllDrivers
            $csvFile = Join-Path $Script:OutputDir "DriverList_${computerName}_${timestamp}.csv"
            $txtFile = Join-Path $Script:OutputDir "DriverList_${computerName}_${timestamp}.txt"
        }
        
        # Export to CSV
        Write-Ui -Message "Exporting to CSV format" -Level "INFO"
        $exportData | Select-Object DeviceName, Manufacturer, Status, DriverVersion, DriverDate, ErrorCode, ErrorDescription, DeviceID | 
            Export-Csv -Path $csvFile -NoTypeInformation -Encoding UTF8
        
        Write-Ui -Message "CSV exported: $csvFile" -Level "OK"
        
        # Export to TXT
        Write-Ui -Message "Exporting to TXT format" -Level "INFO"
        
        $txtContent = @"
============================================================
DRIVER INTEGRITY SCAN REPORT
============================================================

Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
Computer: $computerName
Report Type: $(if ($ProblemsOnly) { "Problem Devices Only" } else { "All Devices" })

============================================================
SUMMARY
============================================================

Total Devices Scanned: $($Script:AllDrivers.Count)
Problem Devices Found: $($Script:ProblemDevices.Count)
Working Devices: $($Script:AllDrivers.Count - $Script:ProblemDevices.Count)

============================================================
DEVICE DETAILS
============================================================

"@
        
        foreach ($driver in $exportData) {
            $txtContent += @"
Device: $($driver.DeviceName)
  Manufacturer:     $($driver.Manufacturer)
  Status:           $($driver.Status)
  Driver Version:   $($driver.DriverVersion)
  Driver Date:      $($driver.DriverDate)
  Error Code:       $($driver.ErrorCode)
  Error Description: $($driver.ErrorDescription)
  Device ID:        $($driver.DeviceID)
  Present:          $($driver.Present)

"@
        }
        
        $txtContent += @"
============================================================
END OF REPORT
============================================================

Generated by SouliTEK Driver Integrity Scan Tool
Website: www.soulitek.co.il
(C) 2025 SouliTEK - All Rights Reserved

"@
        
        Set-Content -Path $txtFile -Value $txtContent -Encoding UTF8
        Write-Ui -Message "TXT report exported: $txtFile" -Level "OK"
        
        Write-Host ""
        Write-Host "  [+] Export completed successfully!" -ForegroundColor Green
        Write-Host "  [*] Files saved to Desktop" -ForegroundColor Cyan
        Write-Host ""
        
        return $true
    }
    catch {
        Write-Ui -Message "Failed to export driver list: $($_.Exception.Message)" -Level "ERROR"
        return $false
    }
}

function Update-InstalledSoftware {
    <#
    .SYNOPSIS
        Updates installed software using WinGet
    #>
    param(
        [switch]$AutoUpdate,
        [switch]$Interactive
    )
    
    if (-not $Script:WinGetAvailable) {
        Write-SouliTEKError "WinGet is not available on this system"
        Write-Host "  [!] Please install WinGet from: https://aka.ms/getwinget" -ForegroundColor Yellow
        return $false
    }
    
    Write-Ui -Message "Checking for available software updates" -Level "INFO"
    Write-Host ""
    
    try {
        # List available updates
        Write-Host "  [*] Querying WinGet for available updates..." -ForegroundColor Cyan
        $upgradeList = winget upgrade 2>&1
        
        if ($upgradeList -like "*No installed package found*" -or $upgradeList -like "*No applicable update found*") {
            Write-Ui -Message "All installed software is up to date" -Level "OK"
            return $true
        }
        
        Write-Host ""
        Write-Host "  " -NoNewline
        Write-Host "AVAILABLE UPDATES:" -ForegroundColor Cyan
        Write-Host ""
        $upgradeList | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
        Write-Host ""
        
        if ($AutoUpdate) {
            Write-Host "  [!] Starting automatic software update..." -ForegroundColor Yellow
            Write-Host "  [!] This may take several minutes..." -ForegroundColor Yellow
            Write-Host ""
            
            # Run WinGet upgrade with all necessary flags
            $wingetArgs = @(
                "upgrade"
                "--all"
                "--silent"
                "--accept-package-agreements"
                "--accept-source-agreements"
                "--disable-interactivity"
            )
            
            Write-Host "  [*] Executing: winget $($wingetArgs -join ' ')" -ForegroundColor Cyan
            Write-Host ""
            
            $upgradeProcess = Start-Process -FilePath "winget.exe" `
                -ArgumentList $wingetArgs `
                -NoNewWindow `
                -Wait `
                -PassThru `
                -RedirectStandardOutput "$env:TEMP\winget_upgrade_output.txt" `
                -RedirectStandardError "$env:TEMP\winget_upgrade_error.txt"
            
            $output = Get-Content "$env:TEMP\winget_upgrade_output.txt" -Raw -ErrorAction SilentlyContinue
            $errors = Get-Content "$env:TEMP\winget_upgrade_error.txt" -Raw -ErrorAction SilentlyContinue
            
            if ($upgradeProcess.ExitCode -eq 0) {
                Write-Ui -Message "Software updates completed successfully" -Level "OK"
                if ($output) {
                    Write-Host ""
                    Write-Host "  " -NoNewline
                    Write-Host "OUTPUT:" -ForegroundColor Cyan
                    Write-Host ""
                    $output -split "`n" | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
                }
            } else {
                Write-Ui -Message "Software update completed with warnings (Exit Code: $($upgradeProcess.ExitCode))" -Level "WARN"
                if ($errors) {
                    Write-Host ""
                    Write-Host "  " -NoNewline
                    Write-Host "ERRORS:" -ForegroundColor Red
                    Write-Host ""
                    $errors -split "`n" | ForEach-Object { Write-Host "  $_" -ForegroundColor Yellow }
                }
            }
            
            # Cleanup temp files
            Remove-Item "$env:TEMP\winget_upgrade_output.txt" -ErrorAction SilentlyContinue
            Remove-Item "$env:TEMP\winget_upgrade_error.txt" -ErrorAction SilentlyContinue
            
        } elseif ($Interactive) {
            Write-Host "  [!] Opening interactive WinGet upgrade interface..." -ForegroundColor Yellow
            Write-Host "  [!] You will be prompted to approve each update..." -ForegroundColor Yellow
            Write-Host ""
            
            Start-Process -FilePath "winget.exe" -ArgumentList "upgrade", "--all" -Wait -NoNewWindow
            
            Write-Ui -Message "Interactive update session completed" -Level "OK"
        }
        
        return $true
    }
    catch {
        Write-Ui -Message "Failed to update software: $($_.Exception.Message)" -Level "ERROR"
        return $false
    }
}

function Show-LastScanResults {
    <#
    .SYNOPSIS
        Displays results from the last scan
    #>
    if (-not (Test-Path $Script:LastScanFile)) {
        Write-SouliTEKWarning "No previous scan results found"
        Write-Host "  [!] Please run a scan first (Option 1 or 2)" -ForegroundColor Yellow
        return
    }
    
    try {
        $scanData = Get-Content -Path $Script:LastScanFile -Raw | ConvertFrom-Json
        
        Show-SouliTEKHeader -Title "LAST SCAN RESULTS" -ClearHost -ShowBanner
        
        Write-Host "  Scan Date:        " -NoNewline -ForegroundColor Gray
        Write-Host "$($scanData.Timestamp)" -ForegroundColor Cyan
        Write-Host "  Total Devices:    " -NoNewline -ForegroundColor Gray
        Write-Host "$($scanData.TotalDevices)" -ForegroundColor White
        Write-Host "  Problem Devices:  " -NoNewline -ForegroundColor Gray
        if ($scanData.ProblemDevices -gt 0) {
            Write-Host "$($scanData.ProblemDevices)" -ForegroundColor Red
        } else {
            Write-Host "0" -ForegroundColor Green
        }
        Write-Host ""
        
        if ($scanData.ProblemDevices -gt 0) {
            Write-Host "  " -NoNewline
            Write-Host "PROBLEM DEVICES:" -ForegroundColor Red
            Write-Host ""
            
            $problemCount = 0
            foreach ($problem in $scanData.Problems) {
                $problemCount++
                if ($problemCount -le 15) {
                    Write-Host "  [$problemCount] $($problem.DeviceName)" -ForegroundColor Yellow
                    Write-Host "      Status: $($problem.Status) | Error Code: $($problem.ErrorCode)" -ForegroundColor Gray
                    Write-Host "      Issue: $($problem.ErrorDescription)" -ForegroundColor Gray
                    Write-Host ""
                }
            }
            
            if ($scanData.ProblemDevices -gt 15) {
                Write-Host "  [!] ... and $($scanData.ProblemDevices - 15) more problem devices" -ForegroundColor Yellow
                Write-Host ""
            }
        } else {
            Write-SouliTEKSuccess "All devices were working properly in last scan!"
            Write-Host ""
        }
    }
    catch {
        Write-SouliTEKError "Failed to load last scan results: $($_.Exception.Message)"
    }
}

function Show-Menu {
    <#
    .SYNOPSIS
        Displays the main menu
    #>
    Show-SouliTEKHeader -Title "DRIVER INTEGRITY SCAN" -ClearHost -ShowBanner
    
    Write-Host "  Select an option:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  [1] Run Full Scan" -ForegroundColor Cyan
    Write-Host "      -> Scan driver integrity + Check for software updates" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  [2] Driver Integrity Scan Only" -ForegroundColor Cyan
    Write-Host "      -> Scan for driver issues and export results" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  [3] Export Driver List" -ForegroundColor Cyan
    Write-Host "      -> Export current driver data to CSV and TXT" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  [4] Update All Software (Auto)" -ForegroundColor Cyan
    Write-Host "      -> Automatically update all software via WinGet" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  [5] Update Software (Interactive)" -ForegroundColor Cyan
    Write-Host "      -> Review and approve each software update" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  [6] View Last Scan Results" -ForegroundColor Cyan
    Write-Host "      -> Display results from previous scan" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  [0] Exit" -ForegroundColor Red
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
}

# ============================================================
# MAIN EXECUTION
# ============================================================

function Main {
    # Show banner
    Clear-Host
    Show-ScriptBanner -ScriptName "Driver Integrity Scan" -Purpose "Scan driver integrity and check for software updates"
    
    # Check WinGet availability at startup
    $Script:WinGetAvailable = Get-WinGetAvailability
    Write-Host ""
    
    do {
        Show-Menu
        $choice = Read-Host "Enter your choice"
        
        switch ($choice) {
            "1" {
                # Run Full Scan
                Show-SouliTEKHeader -Title "FULL SCAN - DRIVER INTEGRITY + SOFTWARE UPDATES" -ClearHost -ShowBanner
                
                # Scan drivers
                $scanSuccess = Get-DriverIntegrityStatus
                
                if ($scanSuccess) {
                    # Export results
                    Write-Host ""
                    Write-SouliTEKInfo "Exporting scan results..."
                    Export-DriverList
                    
                    # Check for software updates
                    if ($Script:WinGetAvailable) {
                        Write-Host ""
                        Write-Host "============================================================" -ForegroundColor Cyan
                        Write-Host ""
                        Write-Host "  " -NoNewline
                        Write-Host "CHECKING FOR SOFTWARE UPDATES..." -ForegroundColor Cyan
                        Write-Host ""
                        Update-InstalledSoftware -Interactive
                    }
                }
                
                Write-Host ""
                Read-Host "Press Enter to continue"
            }
            
            "2" {
                # Driver Integrity Scan Only
                Show-SouliTEKHeader -Title "DRIVER INTEGRITY SCAN" -ClearHost -ShowBanner
                
                $scanSuccess = Get-DriverIntegrityStatus
                
                if ($scanSuccess) {
                    Write-Host ""
                    $exportChoice = Read-Host "Export results to Desktop? (Y/N)"
                    if ($exportChoice -eq "Y" -or $exportChoice -eq "y") {
                        Export-DriverList
                    }
                }
                
                Write-Host ""
                Read-Host "Press Enter to continue"
            }
            
            "3" {
                # Export Driver List
                Show-SouliTEKHeader -Title "EXPORT DRIVER LIST" -ClearHost -ShowBanner
                
                if ($Script:AllDrivers.Count -eq 0) {
                    Write-SouliTEKWarning "No driver data available"
                    Write-Host "  [!] Please run a scan first (Option 1 or 2)" -ForegroundColor Yellow
                } else {
                    Write-Host "  Choose export option:" -ForegroundColor Yellow
                    Write-Host ""
                    Write-Host "  [1] Export All Drivers" -ForegroundColor Cyan
                    Write-Host "  [2] Export Problem Devices Only" -ForegroundColor Cyan
                    Write-Host ""
                    
                    $exportChoice = Read-Host "Enter your choice"
                    
                    if ($exportChoice -eq "1") {
                        Export-DriverList
                    } elseif ($exportChoice -eq "2") {
                        Export-DriverList -ProblemsOnly
                    } else {
                        Write-SouliTEKWarning "Invalid choice"
                    }
                }
                
                Write-Host ""
                Read-Host "Press Enter to continue"
            }
            
            "4" {
                # Update All Software (Auto)
                Show-SouliTEKHeader -Title "AUTO SOFTWARE UPDATE" -ClearHost -ShowBanner
                
                if ($Script:WinGetAvailable) {
                    Write-Host "  [!] This will automatically update all software on your system" -ForegroundColor Yellow
                    Write-Host "  [!] The process may take several minutes" -ForegroundColor Yellow
                    Write-Host ""
                    
                    $confirm = Read-Host "Continue with automatic update? (Y/N)"
                    
                    if ($confirm -eq "Y" -or $confirm -eq "y") {
                        Update-InstalledSoftware -AutoUpdate
                    } else {
                        Write-SouliTEKInfo "Update cancelled by user"
                    }
                } else {
                    Write-SouliTEKError "WinGet is not available on this system"
                }
                
                Write-Host ""
                Read-Host "Press Enter to continue"
            }
            
            "5" {
                # Update Software (Interactive)
                Show-SouliTEKHeader -Title "INTERACTIVE SOFTWARE UPDATE" -ClearHost -ShowBanner
                
                if ($Script:WinGetAvailable) {
                    Write-Host "  [!] This will open an interactive update interface" -ForegroundColor Yellow
                    Write-Host "  [!] You can review and approve each update" -ForegroundColor Yellow
                    Write-Host ""
                    
                    $confirm = Read-Host "Continue with interactive update? (Y/N)"
                    
                    if ($confirm -eq "Y" -or $confirm -eq "y") {
                        Update-InstalledSoftware -Interactive
                    } else {
                        Write-SouliTEKInfo "Update cancelled by user"
                    }
                } else {
                    Write-SouliTEKError "WinGet is not available on this system"
                }
                
                Write-Host ""
                Read-Host "Press Enter to continue"
            }
            
            "6" {
                # View Last Scan Results
                Show-LastScanResults
                
                Write-Host ""
                Read-Host "Press Enter to continue"
            }
            
            "0" {
                # Exit
                Write-Host ""
                Write-Host "  Exiting..." -ForegroundColor Yellow
                
                Start-Sleep -Seconds 1
                exit
            }
            
            default {
                Write-SouliTEKWarning "Invalid choice. Please select a valid option."
                Start-Sleep -Seconds 2
            }
        }
        
    } while ($true)
}

# Run the main function
Main








