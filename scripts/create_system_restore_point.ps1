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

# Show-Header function removed - using Show-SouliTEKHeader from common module

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
                Write-Ui -Message "Restore points found via vssadmin" -Level "OK"
                return @()
            }
        }
        
        return $restorePoints
    }
    catch {
        Write-Ui -Message "Error retrieving restore points: $_" -Level "ERROR"
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
    
    Show-Section "Create System Restore Point"
    Write-Ui -Message "Creating system restore point" -Level "INFO"
    Write-Host ""
    
    # Check if running as administrator
    if (-not (Test-SouliTEKAdministrator)) {
        Write-Ui -Message "Administrator privileges required" -Level "ERROR"
        Write-Ui -Message "Please run this script as Administrator" -Level "INFO"
        Write-Host ""
        Read-Host "Press Enter to exit"
        return $false
    }
    
    # Check if System Restore is enabled
    if (-not (Test-SystemRestoreEnabled)) {
        Write-Ui -Message "System Restore may not be enabled for the system drive" -Level "WARN"
        Write-Ui -Message "The restore point creation may fail" -Level "WARN"
        Write-Host ""
        $continue = Read-Host "Continue anyway? (Y/N)"
        if ($continue -ne "Y" -and $continue -ne "y") {
            return $false
        }
    }
    
    try {
        Write-Ui -Message "Description: $Description" -Level "INFO"
        Write-Ui -Message "Starting restore point creation" -Level "STEP"
        Write-Host ""
        
        # Create restore point using Checkpoint-Computer
        $result = Checkpoint-Computer -Description $Description -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop
        
        if ($result) {
            Write-Ui -Message "System Restore Point created successfully" -Level "OK"
            Write-Host ""
            Write-Ui -Message "Description: $Description" -Level "INFO"
            Write-Ui -Message "Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -Level "INFO"
            Write-Host ""
            return $true
        }
    }
    catch {
        Write-Ui -Message "Failed to create restore point" -Level "ERROR"
        Write-Ui -Message "Error Details: $_" -Level "ERROR"
        Write-Host ""
        
        # Try alternative method using vssadmin
        Write-Ui -Message "Attempting alternative method (vssadmin)" -Level "STEP"
        try {
            $vssResult = Start-Process -FilePath "vssadmin" -ArgumentList "create", "shadow", "/For=$env:SystemDrive" -Wait -NoNewWindow -PassThru -ErrorAction Stop
            
            if ($vssResult.ExitCode -eq 0) {
                Write-Ui -Message "System Restore Point created via vssadmin" -Level "OK"
                return $true
            } else {
                Write-Ui -Message "vssadmin method also failed (Exit Code: $($vssResult.ExitCode))" -Level "ERROR"
            }
        }
        catch {
            Write-Ui -Message "Alternative method failed: $_" -Level "ERROR"
        }
        
        return $false
    }
}

function Show-RestorePoints {
    <#
    .SYNOPSIS
        Displays all available system restore points.
    #>
    
    Show-Section "Restore Point History"
    
    Write-Ui -Message "Retrieving restore points" -Level "INFO"
    Write-Host ""
    
    $restorePoints = Get-RestorePoints
    
    if ($restorePoints.Count -eq 0) {
        Write-Ui -Message "No restore points found" -Level "WARN"
        Write-Ui -Message "System Restore may not be enabled or no points have been created" -Level "INFO"
        Write-Host ""
        return
    }
    
    Write-Ui -Message "Found $($restorePoints.Count) restore point(s)" -Level "OK"
    Write-Host ""
    
    $count = 1
    foreach ($rp in $restorePoints | Sort-Object CreationTime -Descending) {
        Write-Host "Restore Point #$count" -ForegroundColor Cyan
        Write-Ui -Message "Sequence Number: $($rp.SequenceNumber)" -Level "INFO"
        Write-Ui -Message "Description: $($rp.Description)" -Level "INFO"
        Write-Ui -Message "Creation Time: $($rp.CreationTime)" -Level "INFO"
        Write-Ui -Message "Type: $($rp.RestorePointType)" -Level "INFO"
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
    
    Show-Section "System Restore Status"
    
    $systemDrive = $env:SystemDrive
    
    Write-Ui -Message "System Drive: $systemDrive" -Level "INFO"
    Write-Host ""
    
    # Check if System Restore is enabled
    $isEnabled = Test-SystemRestoreEnabled
    
    if ($isEnabled) {
        Write-Ui -Message "System Restore is ENABLED" -Level "OK"
    } else {
        Write-Ui -Message "System Restore is DISABLED or NOT AVAILABLE" -Level "WARN"
    }
    
    Write-Host ""
    
    # Get restore points count
    $restorePoints = Get-RestorePoints
    Write-Ui -Message "Available Restore Points: $($restorePoints.Count)" -Level "INFO"
    Write-Host ""
    
    # Try to get more detailed info via vssadmin
    Write-Ui -Message "Detailed Status" -Level "INFO"
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
        Write-Ui -Message "Could not retrieve detailed status via vssadmin" -Level "WARN"
    }
    
    Write-Host ""
}

# ============================================================
# MAIN MENU
# ============================================================

function Show-MainMenu {
    Clear-Host
    Show-ScriptBanner -ScriptName "System Restore Point Creator" -Purpose "Create Windows System Restore Points for system recovery"
    
    Write-Host ""
    Write-Host "  1. Create System Restore Point (Quick)" -ForegroundColor White
    Write-Host "  2. Create System Restore Point (Custom Description)" -ForegroundColor White
    Write-Host "  3. View Restore Point History" -ForegroundColor White
    Write-Host "  4. Check System Restore Status" -ForegroundColor White
    Write-Host "  5. Exit" -ForegroundColor White
    Write-Host ""
}

# ============================================================
# EXIT MESSAGE
# ============================================================

# Show-ExitMessage function - using Show-SouliTEKExitMessage from common module
function Show-ExitMessage {
    Show-SouliTEKExitMessage -ScriptPath $PSCommandPath -ToolName "SouliTEK System Restore Point Creator"
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
                    Write-Ui -Message "Description cannot be empty. Using default description" -Level "WARN"
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
                Write-Ui -Message "Invalid option. Please select 1-5" -Level "ERROR"
                Write-Host ""
                Start-Sleep -Seconds 1
            }
        }
    }
}

# ============================================================
# SCRIPT EXECUTION
# ============================================================

# Show banner
Clear-Host
Show-ScriptBanner -ScriptName "System Restore Point Creator" -Purpose "Create Windows System Restore Points for system recovery"

# Check administrator privileges
if (-not (Test-SouliTEKAdministrator)) {
    Write-Ui -Message "Administrator privileges required" -Level "ERROR"
    Write-Ui -Message "Please run this script as Administrator" -Level "INFO"
    Write-Host ""
    Write-Ui -Message "The script will now exit" -Level "WARN"
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit 1
}

# Start main loop
Start-MainLoop

