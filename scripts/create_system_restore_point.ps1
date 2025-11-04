# ============================================================
# System Restore Point Creator - Professional Edition
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
# This tool creates Windows System Restore Points
# for system recovery and rollback purposes.
# 
# Features: Quick Create | Custom Description | Status Check
#           Restore Point History | Enable/Disable Protection
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
$Host.UI.RawUI.WindowTitle = "SYSTEM RESTORE POINT CREATOR"

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

function Show-Header {
    param([string]$Title = "SYSTEM RESTORE POINT CREATOR", [ConsoleColor]$Color = 'Cyan')
    
    Clear-Host
    Show-SouliTEKBanner
    Write-Host "============================================================" -ForegroundColor $Color
    Write-Host ""
    Write-Host "  $Title" -ForegroundColor $Color
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor $Color
    Write-Host ""
}

function Test-SystemRestoreEnabled {
    <#
    .SYNOPSIS
        Checks if System Restore is enabled for the system drive.
    #>
    
    try {
        $systemDrive = $env:SystemDrive
        $protectionStatus = Get-ComputerRestorePoint -ErrorAction SilentlyContinue
        
        # Check via vssadmin if Get-ComputerRestorePoint is not available
        if (-not $protectionStatus) {
            $vssOutput = vssadmin list volumes 2>&1
            if ($LASTEXITCODE -eq 0) {
                $volumeInfo = vssadmin list volumes | Select-String -Pattern $systemDrive
                if ($volumeInfo -match "Protection: Enabled") {
                    return $true
                }
            }
        } else {
            return $true
        }
        
        # Alternative check using registry
        $restoreStatus = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore" -Name "RPSessionInterval" -ErrorAction SilentlyContinue
        return ($null -ne $restoreStatus)
    }
    catch {
        return $false
    }
}

function Get-RestorePoints {
    <#
    .SYNOPSIS
        Retrieves all available system restore points.
    #>
    
    try {
        $restorePoints = Get-ComputerRestorePoint -ErrorAction SilentlyContinue
        
        if (-not $restorePoints) {
            # Try using vssadmin as alternative
            $vssOutput = vssadmin list shadows 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Host "Restore points found via vssadmin" -ForegroundColor Green
                return @()
            }
        }
        
        return $restorePoints
    }
    catch {
        Write-Host "Error retrieving restore points: $_" -ForegroundColor Red
        return @()
    }
}

function New-SystemRestorePoint {
    <#
    .SYNOPSIS
        Creates a new system restore point.
    
    .PARAMETER Description
        Description for the restore point.
    #>
    
    param(
        [string]$Description = "SouliTEK Manual Restore Point"
    )
    
    Show-Header
    Write-Host "Creating System Restore Point..." -ForegroundColor Cyan
    Write-Host ""
    
    # Check if running as administrator
    if (-not (Test-SouliTEKAdministrator)) {
        Write-Host "[!] ERROR: Administrator privileges required!" -ForegroundColor Red
        Write-Host "[!] Please run this script as Administrator." -ForegroundColor Red
        Write-Host ""
        Read-Host "Press Enter to exit"
        return $false
    }
    
    # Check if System Restore is enabled
    if (-not (Test-SystemRestoreEnabled)) {
        Write-Host "[!] WARNING: System Restore may not be enabled for the system drive." -ForegroundColor Yellow
        Write-Host "[!] The restore point creation may fail." -ForegroundColor Yellow
        Write-Host ""
        $continue = Read-Host "Continue anyway? (Y/N)"
        if ($continue -ne "Y" -and $continue -ne "y") {
            return $false
        }
    }
    
    try {
        Write-Host "[*] Description: $Description" -ForegroundColor Gray
        Write-Host "[*] Starting restore point creation..." -ForegroundColor Gray
        Write-Host ""
        
        # Create restore point using Checkpoint-Computer
        $result = Checkpoint-Computer -Description $Description -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop
        
        if ($result) {
            Write-Host "[+] SUCCESS: System Restore Point created successfully!" -ForegroundColor Green
            Write-Host ""
            Write-Host "    Description: $Description" -ForegroundColor White
            Write-Host "    Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor White
            Write-Host ""
            return $true
        }
    }
    catch {
        Write-Host "[!] ERROR: Failed to create restore point!" -ForegroundColor Red
        Write-Host "[!] Error Details: $_" -ForegroundColor Red
        Write-Host ""
        
        # Try alternative method using vssadmin
        Write-Host "[*] Attempting alternative method (vssadmin)..." -ForegroundColor Yellow
        try {
            $vssResult = Start-Process -FilePath "vssadmin" -ArgumentList "create", "shadow", "/For=$env:SystemDrive" -Wait -NoNewWindow -PassThru -ErrorAction Stop
            
            if ($vssResult.ExitCode -eq 0) {
                Write-Host "[+] SUCCESS: System Restore Point created via vssadmin!" -ForegroundColor Green
                return $true
            } else {
                Write-Host "[!] ERROR: vssadmin method also failed (Exit Code: $($vssResult.ExitCode))" -ForegroundColor Red
            }
        }
        catch {
            Write-Host "[!] ERROR: Alternative method failed: $_" -ForegroundColor Red
        }
        
        return $false
    }
}

function Show-RestorePoints {
    <#
    .SYNOPSIS
        Displays all available system restore points.
    #>
    
    Show-Header "RESTORE POINT HISTORY"
    
    Write-Host "Retrieving restore points..." -ForegroundColor Cyan
    Write-Host ""
    
    $restorePoints = Get-RestorePoints
    
    if ($restorePoints.Count -eq 0) {
        Write-Host "[!] No restore points found." -ForegroundColor Yellow
        Write-Host "[!] System Restore may not be enabled or no points have been created." -ForegroundColor Yellow
        Write-Host ""
        return
    }
    
    Write-Host "Found $($restorePoints.Count) restore point(s):" -ForegroundColor Green
    Write-Host ""
    Write-Host ("=" * 80) -ForegroundColor Cyan
    
    $count = 1
    foreach ($rp in $restorePoints | Sort-Object CreationTime -Descending) {
        Write-Host "Restore Point #$count" -ForegroundColor Cyan
        Write-Host "  Sequence Number: $($rp.SequenceNumber)" -ForegroundColor White
        Write-Host "  Description: $($rp.Description)" -ForegroundColor White
        Write-Host "  Creation Time: $($rp.CreationTime)" -ForegroundColor White
        Write-Host "  Type: $($rp.RestorePointType)" -ForegroundColor White
        Write-Host ("-" * 80) -ForegroundColor Gray
        $count++
    }
    
    Write-Host ""
}

function Show-SystemRestoreStatus {
    <#
    .SYNOPSIS
        Shows the current System Restore protection status.
    #>
    
    Show-Header "SYSTEM RESTORE STATUS"
    
    $systemDrive = $env:SystemDrive
    
    Write-Host "System Drive: $systemDrive" -ForegroundColor Cyan
    Write-Host ""
    
    # Check if System Restore is enabled
    $isEnabled = Test-SystemRestoreEnabled
    
    if ($isEnabled) {
        Write-Host "[+] System Restore is ENABLED" -ForegroundColor Green
    } else {
        Write-Host "[!] System Restore is DISABLED or NOT AVAILABLE" -ForegroundColor Yellow
    }
    
    Write-Host ""
    
    # Get restore points count
    $restorePoints = Get-RestorePoints
    Write-Host "Available Restore Points: $($restorePoints.Count)" -ForegroundColor Cyan
    Write-Host ""
    
    # Try to get more detailed info via vssadmin
    Write-Host "Detailed Status:" -ForegroundColor Cyan
    Write-Host ("=" * 80) -ForegroundColor Gray
    
    try {
        $vssVolumes = vssadmin list volumes 2>&1
        if ($LASTEXITCODE -eq 0) {
            $volumeInfo = vssadmin list volumes | Select-String -Pattern $systemDrive -Context 0,5
            if ($volumeInfo) {
                Write-Host $volumeInfo -ForegroundColor White
            }
        }
    }
    catch {
        Write-Host "[!] Could not retrieve detailed status via vssadmin" -ForegroundColor Yellow
    }
    
    Write-Host ""
}

# ============================================================
# MAIN MENU
# ============================================================

function Show-MainMenu {
    Show-Header
    
    Write-Host "MAIN MENU" -ForegroundColor Cyan
    Write-Host ("=" * 60) -ForegroundColor Gray
    Write-Host ""
    Write-Host "  1. Create System Restore Point (Quick)" -ForegroundColor White
    Write-Host "  2. Create System Restore Point (Custom Description)" -ForegroundColor White
    Write-Host "  3. View Restore Point History" -ForegroundColor White
    Write-Host "  4. Check System Restore Status" -ForegroundColor White
    Write-Host "  5. Exit" -ForegroundColor White
    Write-Host ""
    Write-Host ("=" * 60) -ForegroundColor Gray
    Write-Host ""
}

# ============================================================
# EXIT MESSAGE
# ============================================================

function Show-ExitMessage {
    Clear-Host
    Write-Host ""
    Write-Host "Thank you for using SouliTEK System Restore Point Creator!" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Website: www.soulitek.co.il" -ForegroundColor Yellow
    Write-Host ""
}

function Start-MainLoop {
    while ($true) {
        Show-MainMenu
        
        $choice = Read-Host "Select an option (1-5)"
        
        switch ($choice) {
            "1" {
                $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                $description = "SouliTEK Manual Restore Point - $timestamp"
                $success = New-SystemRestorePoint -Description $description
                
                if ($success) {
                    Write-Host ""
                    Write-Host "Press Enter to return to menu..."
                    Read-Host | Out-Null
                } else {
                    Write-Host ""
                    Write-Host "Press Enter to return to menu..."
                    Read-Host | Out-Null
                }
            }
            "2" {
                Write-Host ""
                $description = Read-Host "Enter description for restore point"
                
                if ([string]::IsNullOrWhiteSpace($description)) {
                    Write-Host "[!] Description cannot be empty. Using default description." -ForegroundColor Yellow
                    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                    $description = "SouliTEK Manual Restore Point - $timestamp"
                }
                
                $success = New-SystemRestorePoint -Description $description
                
                if ($success) {
                    Write-Host ""
                    Write-Host "Press Enter to return to menu..."
                    Read-Host | Out-Null
                } else {
                    Write-Host ""
                    Write-Host "Press Enter to return to menu..."
                    Read-Host | Out-Null
                }
            }
            "3" {
                Show-RestorePoints
                Write-Host ""
                Write-Host "Press Enter to return to menu..."
                Read-Host | Out-Null
            }
            "4" {
                Show-SystemRestoreStatus
                Write-Host ""
                Write-Host "Press Enter to return to menu..."
                Read-Host | Out-Null
            }
            "5" {
                Show-ExitMessage
                exit 0
            }
            default {
                Write-Host ""
                Write-Host "[!] Invalid option. Please select 1-5." -ForegroundColor Red
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
    Show-Header
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

