# ============================================================
# BitLocker Status Report - Professional Edition
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
# This tool provides comprehensive BitLocker encryption status
# and recovery key management for enterprise security.
# 
# Features: Status Check | Recovery Keys | Volume Report
#           Encryption Details | Security Audit | Export Results
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

# Requires elevation (Administrator)
#Requires -RunAsAdministrator

# Set window title
$Host.UI.RawUI.WindowTitle = "BITLOCKER STATUS REPORT"

# Import SouliTEK Common Functions
$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$CommonPath = Join-Path (Split-Path -Parent $ScriptRoot) "modules\SouliTEK-Common.ps1"
if (Test-Path $CommonPath) {
    Import-Module $CommonPath -Force
} else {
    Write-Warning "SouliTEK Common Functions not found at: $CommonPath"
    Write-Warning "Some functions may not work properly."
}

# ============================================================
# GLOBAL VARIABLES
# ============================================================

$Script:BitLockerData = @()
$Script:OutputFolder = Join-Path $env:USERPROFILE "Desktop"

# ============================================================
# HELPER FUNCTIONS
# ============================================================



function Show-Header {
    param([string]$Title = "BITLOCKER STATUS REPORT", [ConsoleColor]$Color = 'Cyan')
    
    Clear-Host
    Show-SouliTEKBanner
    Write-Host "============================================================" -ForegroundColor $Color
    Write-Host ""
    Write-Host "  $Title" -ForegroundColor $Color
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor $Color
    Write-Host ""
}

function Write-SouliTEKResult { param([string]$Message, [string]$Level = "INFO") Write-SouliTEKResult -Message $Message -Level $Level }



# ============================================================
# BITLOCKER CHECK FUNCTIONS
# ============================================================

function Get-BitLockerStatus {
    Show-Header "BITLOCKER STATUS - ALL VOLUMES" -Color Green
    
    Write-Host "      Checking BitLocker encryption status on all volumes" -ForegroundColor Gray
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    
    Write-SouliTEKResult "Scanning volumes for BitLocker status..." -Level INFO
    Write-Host ""
    
    try {
        $volumes = Get-BitLockerVolume
        
        if ($volumes.Count -eq 0) {
            Write-SouliTEKResult "No volumes found or BitLocker is not available" -Level WARNING
            Write-Host ""
            Read-Host "Press Enter to return to main menu"
            return
        }
        
        $Script:BitLockerData = @()
        
        foreach ($vol in $volumes) {
            Write-Host "============================================================" -ForegroundColor DarkCyan
            Write-Host "VOLUME: $($vol.MountPoint)" -ForegroundColor Yellow
            Write-Host "============================================================" -ForegroundColor DarkCyan
            
            # Volume Information
            Write-Host ""
            Write-Host "Volume Information:" -ForegroundColor Cyan
            Write-Host "  Mount Point       : $($vol.MountPoint)" -ForegroundColor White
            
            if ($vol.VolumeName) {
                Write-Host "  Volume Label      : $($vol.VolumeName)" -ForegroundColor White
            }
            
            # Get volume size
            try {
                $drive = Get-PSDrive -Name $vol.MountPoint.TrimEnd(':\') -ErrorAction SilentlyContinue
                if ($drive) {
                    $sizeGB = [math]::Round($drive.Used / 1GB + $drive.Free / 1GB, 2)
                    $usedGB = [math]::Round($drive.Used / 1GB, 2)
                    $freeGB = [math]::Round($drive.Free / 1GB, 2)
                    Write-Host "  Size              : $sizeGB GB" -ForegroundColor White
                    Write-Host "  Used              : $usedGB GB" -ForegroundColor White
                    Write-Host "  Free              : $freeGB GB" -ForegroundColor White
                }
            }
            catch {
                # Volume might not be mounted or accessible
            }
            
            Write-Host "  Volume Type       : $($vol.VolumeType)" -ForegroundColor White
            
            # Protection Status
            Write-Host ""
            Write-Host "Protection Status:" -ForegroundColor Cyan
            $protectionStatus = $vol.ProtectionStatus
            $statusColor = switch ($protectionStatus) {
                "On" { "Green" }
                "Off" { "Red" }
                default { "Yellow" }
            }
            Write-Host "  Status            : $protectionStatus" -ForegroundColor $statusColor
            
            # Encryption Status
            Write-Host ""
            Write-Host "Encryption Details:" -ForegroundColor Cyan
            $encryptionPercent = $vol.EncryptionPercentage
            $volumeStatus = $vol.VolumeStatus
            
            $encryptionColor = if ($encryptionPercent -eq 100) { "Green" } 
                             elseif ($encryptionPercent -gt 0) { "Yellow" } 
                             else { "Red" }
            
            Write-Host "  Encryption        : $encryptionPercent%" -ForegroundColor $encryptionColor
            Write-Host "  Volume Status     : $volumeStatus" -ForegroundColor White
            
            if ($vol.EncryptionMethod) {
                Write-Host "  Encryption Method : $($vol.EncryptionMethod)" -ForegroundColor White
            }
            
            # Key Protectors
            Write-Host ""
            Write-Host "Key Protectors:" -ForegroundColor Cyan
            
            if ($vol.KeyProtector.Count -gt 0) {
                foreach ($kp in $vol.KeyProtector) {
                    $kpType = $kp.KeyProtectorType
                    $kpId = $kp.KeyProtectorId
                    
                    $typeColor = switch ($kpType) {
                        "RecoveryPassword" { "Green" }
                        "Tpm" { "Cyan" }
                        "TpmPin" { "Cyan" }
                        "Password" { "Yellow" }
                        default { "White" }
                    }
                    
                    Write-Host "  [+] $kpType" -ForegroundColor $typeColor
                    Write-Host "      ID: $kpId" -ForegroundColor Gray
                    
                    if ($kpType -eq "RecoveryPassword" -and $kp.RecoveryPassword) {
                        Write-Host "      Recovery Key: $($kp.RecoveryPassword)" -ForegroundColor Yellow
                    }
                }
                
                Write-Host ""
                Write-Host "  Total Key Protectors: $($vol.KeyProtector.Count)" -ForegroundColor White
            }
            else {
                Write-Host "  No key protectors configured" -ForegroundColor Red
            }
            
            # Lock Status
            Write-Host ""
            Write-Host "Lock Status:" -ForegroundColor Cyan
            $lockStatus = $vol.LockStatus
            $lockColor = if ($lockStatus -eq "Unlocked") { "Green" } else { "Red" }
            Write-Host "  Status            : $lockStatus" -ForegroundColor $lockColor
            
            # Store data
            $Script:BitLockerData += [PSCustomObject]@{
                MountPoint = $vol.MountPoint
                VolumeLabel = $vol.VolumeName
                ProtectionStatus = $protectionStatus
                EncryptionPercent = $encryptionPercent
                VolumeStatus = $volumeStatus
                EncryptionMethod = $vol.EncryptionMethod
                KeyProtectorCount = $vol.KeyProtector.Count
                LockStatus = $lockStatus
                KeyProtectors = ($vol.KeyProtector.KeyProtectorType -join ", ")
            }
            
            Write-Host ""
        }
        
        Write-Host "============================================================" -ForegroundColor Cyan
        Write-Host "  SUMMARY" -ForegroundColor Cyan
        Write-Host "============================================================" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Total Volumes Scanned: $($volumes.Count)" -ForegroundColor White
        
        $protectedVolumes = ($volumes | Where-Object { $_.ProtectionStatus -eq "On" }).Count
        $encryptedVolumes = ($volumes | Where-Object { $_.EncryptionPercentage -eq 100 }).Count
        
        Write-Host "Protected Volumes: $protectedVolumes" -ForegroundColor $(if ($protectedVolumes -gt 0) { "Green" } else { "Red" })
        Write-Host "Fully Encrypted: $encryptedVolumes" -ForegroundColor $(if ($encryptedVolumes -eq $volumes.Count) { "Green" } else { "Yellow" })
        
        Write-Host ""
        Write-Host "============================================================" -ForegroundColor Cyan
    }
    catch {
        Write-SouliTEKResult "Failed to retrieve BitLocker status: $_" -Level ERROR
        Write-Host ""
        Write-Host "Possible reasons:" -ForegroundColor Yellow
        Write-Host "  - BitLocker not available on this Windows edition" -ForegroundColor Gray
        Write-Host "  - Insufficient permissions (run as Administrator)" -ForegroundColor Gray
        Write-Host "  - System error" -ForegroundColor Gray
    }
    
    Write-Host ""
    Read-Host "Press Enter to return to main menu"
}

function Get-RecoveryKeys {
    Show-Header "RECOVERY KEY REPORT" -Color Yellow
    
    Write-Host "      Display BitLocker recovery keys for all volumes" -ForegroundColor Gray
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "WARNING: Recovery keys are sensitive information!" -ForegroundColor Red
    Write-Host "Keep them secure and backed up safely." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    
    $confirm = Read-Host "Display recovery keys? (Y/N)"
    
    if ($confirm -ne 'Y' -and $confirm -ne 'y') {
        return
    }
    
    Write-Host ""
    Write-SouliTEKResult "Retrieving recovery keys..." -Level INFO
    Write-Host ""
    
    try {
        $volumes = Get-BitLockerVolume
        $foundKeys = $false
        
        foreach ($vol in $volumes) {
            $recoveryProtectors = $vol.KeyProtector | Where-Object { $_.KeyProtectorType -eq "RecoveryPassword" }
            
            if ($recoveryProtectors.Count -gt 0) {
                $foundKeys = $true
                
                Write-Host "============================================================" -ForegroundColor DarkCyan
                Write-Host "VOLUME: $($vol.MountPoint)" -ForegroundColor Yellow
                Write-Host "============================================================" -ForegroundColor DarkCyan
                Write-Host ""
                
                foreach ($rp in $recoveryProtectors) {
                    Write-Host "Recovery Key ID:" -ForegroundColor Cyan
                    Write-Host "  $($rp.KeyProtectorId)" -ForegroundColor Gray
                    Write-Host ""
                    Write-Host "Recovery Password:" -ForegroundColor Cyan
                    Write-Host "  $($rp.RecoveryPassword)" -ForegroundColor Green
                    Write-Host ""
                    Write-Host "IMPORTANT: Save this recovery key in a secure location!" -ForegroundColor Yellow
                    Write-Host ""
                }
            }
        }
        
        if (-not $foundKeys) {
            Write-SouliTEKResult "No recovery keys found on any volume" -Level WARNING
            Write-Host ""
            Write-Host "This could mean:" -ForegroundColor Yellow
            Write-Host "  - No volumes are BitLocker protected" -ForegroundColor Gray
            Write-Host "  - Recovery keys are stored in Active Directory" -ForegroundColor Gray
            Write-Host "  - Different key protector types are used" -ForegroundColor Gray
        }
        
        Write-Host ""
        Write-Host "============================================================" -ForegroundColor Cyan
    }
    catch {
        Write-SouliTEKResult "Failed to retrieve recovery keys: $_" -Level ERROR
    }
    
    Write-Host ""
    Read-Host "Press Enter to return to main menu"
}

function Get-DetailedVolumeReport {
    Show-Header "DETAILED VOLUME REPORT" -Color Magenta
    
    Write-Host "      Comprehensive BitLocker analysis for all volumes" -ForegroundColor Gray
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    
    Write-SouliTEKResult "Generating detailed report..." -Level INFO
    Write-Host ""
    
    try {
        $volumes = Get-BitLockerVolume
        
        foreach ($vol in $volumes) {
            Write-Host "============================================================" -ForegroundColor DarkCyan
            Write-Host "DETAILED ANALYSIS: $($vol.MountPoint)" -ForegroundColor Yellow
            Write-Host "============================================================" -ForegroundColor DarkCyan
            Write-Host ""
            
            # All available properties
            Write-Host "Complete Volume Information:" -ForegroundColor Cyan
            Write-Host ""
            
            $properties = @(
                @{ Name = "Mount Point"; Value = $vol.MountPoint }
                @{ Name = "Volume Type"; Value = $vol.VolumeType }
                @{ Name = "Volume Status"; Value = $vol.VolumeStatus }
                @{ Name = "Protection Status"; Value = $vol.ProtectionStatus }
                @{ Name = "Lock Status"; Value = $vol.LockStatus }
                @{ Name = "Encryption Percentage"; Value = "$($vol.EncryptionPercentage)%" }
                @{ Name = "Encryption Method"; Value = $vol.EncryptionMethod }
                @{ Name = "Auto Unlock Enabled"; Value = $vol.AutoUnlockEnabled }
                @{ Name = "Auto Unlock Key Stored"; Value = $vol.AutoUnlockKeyStored }
                @{ Name = "Metadata Version"; Value = $vol.MetadataVersion }
            )
            
            foreach ($prop in $properties) {
                if ($prop.Value) {
                    Write-Host "  $($prop.Name.PadRight(30)): $($prop.Value)" -ForegroundColor White
                }
            }
            
            Write-Host ""
            Write-Host "Key Protectors (Detailed):" -ForegroundColor Cyan
            Write-Host ""
            
            if ($vol.KeyProtector.Count -gt 0) {
                $index = 1
                foreach ($kp in $vol.KeyProtector) {
                    Write-Host "  [$index] Key Protector" -ForegroundColor Yellow
                    Write-Host "      Type: $($kp.KeyProtectorType)" -ForegroundColor White
                    Write-Host "      ID: $($kp.KeyProtectorId)" -ForegroundColor Gray
                    
                    if ($kp.RecoveryPassword) {
                        Write-Host "      Recovery Password: $($kp.RecoveryPassword)" -ForegroundColor Green
                    }
                    
                    Write-Host ""
                    $index++
                }
            }
            else {
                Write-Host "  No key protectors found" -ForegroundColor Red
            }
            
            # Security Recommendations
            Write-Host "Security Recommendations:" -ForegroundColor Cyan
            Write-Host ""
            
            $recommendations = @()
            
            if ($vol.ProtectionStatus -ne "On") {
                $recommendations += "  [!] Enable BitLocker protection for this volume"
            }
            
            if ($vol.EncryptionPercentage -lt 100 -and $vol.ProtectionStatus -eq "On") {
                $recommendations += "  [!] Encryption in progress - $($vol.EncryptionPercentage)% complete"
            }
            
            if ($vol.KeyProtector.Count -eq 0) {
                $recommendations += "  [!] No key protectors configured - add recovery key"
            }
            
            $hasRecoveryKey = $vol.KeyProtector | Where-Object { $_.KeyProtectorType -eq "RecoveryPassword" }
            if (-not $hasRecoveryKey -and $vol.ProtectionStatus -eq "On") {
                $recommendations += "  [!] No recovery password configured - highly recommended"
            }
            
            if ($recommendations.Count -gt 0) {
                foreach ($rec in $recommendations) {
                    Write-Host $rec -ForegroundColor Yellow
                }
            }
            else {
                Write-Host "  [+] Volume configuration looks good" -ForegroundColor Green
            }
            
            Write-Host ""
        }
        
        Write-Host "============================================================" -ForegroundColor Cyan
    }
    catch {
        Write-SouliTEKResult "Failed to generate detailed report: $_" -Level ERROR
    }
    
    Write-Host ""
    Read-Host "Press Enter to return to main menu"
}

function Test-BitLockerHealth {
    Show-Header "BITLOCKER HEALTH CHECK" -Color Blue
    
    Write-Host "      Quick security audit of BitLocker configuration" -ForegroundColor Gray
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    
    Write-SouliTEKResult "Running BitLocker health check..." -Level INFO
    Write-Host ""
    
    try {
        $volumes = Get-BitLockerVolume
        $issues = @()
        $warnings = @()
        $passed = @()
        
        Write-Host "Analyzing BitLocker configuration..." -ForegroundColor Cyan
        Write-Host ""
        
        # Check 1: OS Drive Protection
        Write-Host "[1/5] Checking OS drive protection..." -ForegroundColor Yellow
        $osDrive = $volumes | Where-Object { $_.VolumeType -eq "OperatingSystem" }
        if ($osDrive) {
            if ($osDrive.ProtectionStatus -eq "On") {
                Write-SouliTEKResult "OS drive is protected" -Level SUCCESS
                $passed += "OS drive encryption enabled"
            }
            else {
                Write-SouliTEKResult "OS drive is NOT protected" -Level ERROR
                $issues += "OS drive ($($osDrive.MountPoint)) is not BitLocker protected"
            }
        }
        else {
            Write-SouliTEKResult "No OS drive found" -Level WARNING
        }
        
        Write-Host ""
        
        # Check 2: Data Drive Protection
        Write-Host "[2/5] Checking data drive protection..." -ForegroundColor Yellow
        $dataVolumes = $volumes | Where-Object { $_.VolumeType -eq "Data" }
        if ($dataVolumes) {
            $unprotectedData = $dataVolumes | Where-Object { $_.ProtectionStatus -ne "On" }
            if ($unprotectedData.Count -eq 0) {
                Write-SouliTEKResult "All data drives are protected" -Level SUCCESS
                $passed += "All data drives encrypted"
            }
            else {
                Write-SouliTEKResult "$($unprotectedData.Count) data drive(s) not protected" -Level WARNING
                foreach ($vol in $unprotectedData) {
                    $warnings += "Data drive $($vol.MountPoint) is not encrypted"
                }
            }
        }
        else {
            Write-SouliTEKResult "No data drives found" -Level INFO
        }
        
        Write-Host ""
        
        # Check 3: Recovery Keys
        Write-Host "[3/5] Checking recovery key configuration..." -ForegroundColor Yellow
        $protectedVolumes = $volumes | Where-Object { $_.ProtectionStatus -eq "On" }
        if ($protectedVolumes) {
            $volumesWithoutRecovery = @()
            foreach ($vol in $protectedVolumes) {
                $hasRecoveryKey = $vol.KeyProtector | Where-Object { $_.KeyProtectorType -eq "RecoveryPassword" }
                if (-not $hasRecoveryKey) {
                    $volumesWithoutRecovery += $vol.MountPoint
                }
            }
            
            if ($volumesWithoutRecovery.Count -eq 0) {
                Write-SouliTEKResult "All protected volumes have recovery keys" -Level SUCCESS
                $passed += "Recovery keys configured"
            }
            else {
                Write-SouliTEKResult "$($volumesWithoutRecovery.Count) volume(s) missing recovery keys" -Level WARNING
                foreach ($vol in $volumesWithoutRecovery) {
                    $warnings += "Volume $vol does not have a recovery password"
                }
            }
        }
        
        Write-Host ""
        
        # Check 4: Encryption Completion
        Write-Host "[4/5] Checking encryption completion..." -ForegroundColor Yellow
        $incompleteVolumes = $volumes | Where-Object { $_.EncryptionPercentage -lt 100 -and $_.EncryptionPercentage -gt 0 }
        if ($incompleteVolumes.Count -eq 0) {
            Write-SouliTEKResult "All encryption processes completed" -Level SUCCESS
            $passed += "No pending encryption operations"
        }
        else {
            Write-SouliTEKResult "$($incompleteVolumes.Count) volume(s) still encrypting" -Level WARNING
            foreach ($vol in $incompleteVolumes) {
                $warnings += "Volume $($vol.MountPoint) encryption at $($vol.EncryptionPercentage)%"
            }
        }
        
        Write-Host ""
        
        # Check 5: Lock Status
        Write-Host "[5/5] Checking volume lock status..." -ForegroundColor Yellow
        $lockedVolumes = $volumes | Where-Object { $_.LockStatus -eq "Locked" }
        if ($lockedVolumes.Count -eq 0) {
            Write-SouliTEKResult "All volumes are unlocked" -Level SUCCESS
            $passed += "No locked volumes detected"
        }
        else {
            Write-SouliTEKResult "$($lockedVolumes.Count) volume(s) are locked" -Level WARNING
            foreach ($vol in $lockedVolumes) {
                $warnings += "Volume $($vol.MountPoint) is locked"
            }
        }
        
        Write-Host ""
        Write-Host "============================================================" -ForegroundColor Cyan
        Write-Host "  HEALTH CHECK SUMMARY" -ForegroundColor Cyan
        Write-Host "============================================================" -ForegroundColor Cyan
        Write-Host ""
        
        Write-Host "Total Volumes Checked: $($volumes.Count)" -ForegroundColor White
        Write-Host ""
        
        if ($passed.Count -gt 0) {
            Write-Host "PASSED CHECKS: $($passed.Count)" -ForegroundColor Green
            foreach ($p in $passed) {
                Write-Host "  [+] $p" -ForegroundColor Green
            }
            Write-Host ""
        }
        
        if ($warnings.Count -gt 0) {
            Write-Host "WARNINGS: $($warnings.Count)" -ForegroundColor Yellow
            foreach ($w in $warnings) {
                Write-Host "  [!] $w" -ForegroundColor Yellow
            }
            Write-Host ""
        }
        
        if ($issues.Count -gt 0) {
            Write-Host "CRITICAL ISSUES: $($issues.Count)" -ForegroundColor Red
            foreach ($i in $issues) {
                Write-Host "  [-] $i" -ForegroundColor Red
            }
            Write-Host ""
        }
        
        # Overall health score
        $totalChecks = $passed.Count + $warnings.Count + $issues.Count
        if ($totalChecks -gt 0) {
            $healthScore = [math]::Round(($passed.Count / $totalChecks) * 100, 0)
            Write-Host "Overall Health Score: $healthScore%" -ForegroundColor $(
                if ($healthScore -ge 80) { "Green" }
                elseif ($healthScore -ge 60) { "Yellow" }
                else { "Red" }
            )
        }
        
        Write-Host ""
        Write-Host "============================================================" -ForegroundColor Cyan
    }
    catch {
        Write-SouliTEKResult "Health check failed: $_" -Level ERROR
    }
    
    Write-Host ""
    Read-Host "Press Enter to return to main menu"
}

function Export-BitLockerReport {
    Show-Header "EXPORT BITLOCKER REPORT" -Color Yellow
    
    Write-Host "      Save BitLocker status to file" -ForegroundColor Gray
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    
    Write-SouliTEKResult "Collecting BitLocker data..." -Level INFO
    Write-Host ""
    
    try {
        $volumes = Get-BitLockerVolume
        
        if ($volumes.Count -eq 0) {
            Write-SouliTEKResult "No volumes found to export" -Level WARNING
            Start-Sleep -Seconds 2
            return
        }
        
        Write-Host "Select export format:" -ForegroundColor White
        Write-Host ""
        Write-Host "  [1] Text File (.txt)" -ForegroundColor Yellow
        Write-Host "  [2] CSV File (.csv)" -ForegroundColor Yellow
        Write-Host "  [3] HTML Report (.html)" -ForegroundColor Yellow
        Write-Host "  [4] All Formats" -ForegroundColor Cyan
        Write-Host "  [0] Cancel" -ForegroundColor Red
        Write-Host ""
        
        $choice = Read-Host "Enter your choice (0-4)"
        
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        
        switch ($choice) {
            "1" {
                Export-TextReport -Volumes $volumes -Timestamp $timestamp
            }
            "2" {
                Export-CSVReport -Volumes $volumes -Timestamp $timestamp
            }
            "3" {
                Export-HTMLReport -Volumes $volumes -Timestamp $timestamp
            }
            "4" {
                Export-TextReport -Volumes $volumes -Timestamp $timestamp
                Export-CSVReport -Volumes $volumes -Timestamp $timestamp
                Export-HTMLReport -Volumes $volumes -Timestamp $timestamp
            }
            "0" {
                return
            }
            default {
                Write-SouliTEKResult "Invalid choice" -Level ERROR
                Start-Sleep -Seconds 2
                return
            }
        }
    }
    catch {
        Write-SouliTEKResult "Export failed: $_" -Level ERROR
    }
    
    Write-Host ""
    Read-Host "Press Enter to return to main menu"
}

function Export-TextReport {
    param($Volumes, $Timestamp)
    
    $fileName = "BitLocker_Report_$Timestamp.txt"
    $filePath = Join-Path $Script:OutputFolder $fileName
    
    $content = @()
    $content += "============================================================"
    $content += "    BITLOCKER STATUS REPORT - by Soulitek.co.il"
    $content += "============================================================"
    $content += ""
    $content += "Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    $content += "Computer: $env:COMPUTERNAME"
    $content += "User: $env:USERNAME"
    $content += ""
    $content += "Total Volumes: $($Volumes.Count)"
    $content += ""
    $content += "============================================================"
    $content += ""
    
    foreach ($vol in $Volumes) {
        $content += "VOLUME: $($vol.MountPoint)"
        $content += "------------------------------------------------------------"
        $content += "Protection Status    : $($vol.ProtectionStatus)"
        $content += "Encryption Percentage: $($vol.EncryptionPercentage)%"
        $content += "Volume Status        : $($vol.VolumeStatus)"
        $content += "Lock Status          : $($vol.LockStatus)"
        $content += "Encryption Method    : $($vol.EncryptionMethod)"
        $content += "Volume Type          : $($vol.VolumeType)"
        $content += ""
        $content += "Key Protectors: $($vol.KeyProtector.Count)"
        foreach ($kp in $vol.KeyProtector) {
            $content += "  - $($kp.KeyProtectorType)"
            $content += "    ID: $($kp.KeyProtectorId)"
            if ($kp.RecoveryPassword) {
                $content += "    Recovery Key: $($kp.RecoveryPassword)"
            }
        }
        $content += ""
        $content += "============================================================"
        $content += ""
    }
    
    $content += ""
    $content += "END OF REPORT"
    $content += "Generated by BitLocker Status Report Tool"
    $content += "Coded by: Soulitek.co.il"
    $content += "www.soulitek.co.il"
    
    $content | Out-File -FilePath $filePath -Encoding UTF8
    
    Write-Host ""
    Write-SouliTEKResult "Text report exported to: $filePath" -Level SUCCESS
    Start-Sleep -Seconds 1
    Start-Process notepad.exe -ArgumentList $filePath
}

function Export-CSVReport {
    param($Volumes, $Timestamp)
    
    $fileName = "BitLocker_Report_$Timestamp.csv"
    $filePath = Join-Path $Script:OutputFolder $fileName
    
    $data = @()
    foreach ($vol in $Volumes) {
        $data += [PSCustomObject]@{
            MountPoint = $vol.MountPoint
            VolumeLabel = $vol.VolumeName
            VolumeType = $vol.VolumeType
            ProtectionStatus = $vol.ProtectionStatus
            EncryptionPercentage = $vol.EncryptionPercentage
            VolumeStatus = $vol.VolumeStatus
            LockStatus = $vol.LockStatus
            EncryptionMethod = $vol.EncryptionMethod
            KeyProtectorCount = $vol.KeyProtector.Count
            KeyProtectorTypes = ($vol.KeyProtector.KeyProtectorType -join "; ")
        }
    }
    
    $data | Export-Csv -Path $filePath -NoTypeInformation -Encoding UTF8
    
    Write-Host ""
    Write-SouliTEKResult "CSV report exported to: $filePath" -Level SUCCESS
    Start-Sleep -Seconds 1
    Start-Process $filePath
}

function Export-HTMLReport {
    param($Volumes, $Timestamp)
    
    $fileName = "BitLocker_Report_$Timestamp.html"
    $filePath = Join-Path $Script:OutputFolder $fileName
    
    $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>BitLocker Status Report - $env:COMPUTERNAME</title>
    <meta charset="utf-8">
    <style>
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin: 20px; background-color: #f5f5f5; }
        h1 { color: #2c3e50; border-bottom: 3px solid #3498db; padding-bottom: 10px; }
        .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; border-radius: 10px; margin-bottom: 30px; }
        .volume { background-color: white; padding: 20px; margin-bottom: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .volume-header { font-size: 20px; font-weight: bold; color: #34495e; margin-bottom: 15px; border-bottom: 2px solid #3498db; padding-bottom: 10px; }
        .info-grid { display: grid; grid-template-columns: 200px 1fr; gap: 10px; margin-top: 10px; }
        .info-label { font-weight: bold; color: #7f8c8d; }
        .status-protected { color: #27ae60; font-weight: bold; }
        .status-unprotected { color: #e74c3c; font-weight: bold; }
        .encryption-complete { color: #27ae60; font-weight: bold; }
        .encryption-incomplete { color: #f39c12; font-weight: bold; }
        .key-protector { background-color: #ecf0f1; padding: 10px; margin: 5px 0; border-radius: 5px; }
        .recovery-key { font-family: 'Courier New', monospace; color: #27ae60; font-weight: bold; }
        .footer { text-align: center; margin-top: 30px; color: #7f8c8d; font-size: 12px; }
        .summary { background-color: #3498db; color: white; padding: 20px; border-radius: 8px; margin-bottom: 20px; }
    </style>
</head>
<body>
    <div class="header">
        <h1>[SECURE] BitLocker Status Report</h1>
        <p><strong>Computer:</strong> $env:COMPUTERNAME | <strong>User:</strong> $env:USERNAME</p>
        <p><strong>Generated:</strong> $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</p>
    </div>
    
    <div class="summary">
        <h2 style="margin-top:0;">Summary</h2>
        <p><strong>Total Volumes:</strong> $($Volumes.Count)</p>
"@
    
    $protectedCount = ($Volumes | Where-Object { $_.ProtectionStatus -eq "On" }).Count
    $encryptedCount = ($Volumes | Where-Object { $_.EncryptionPercentage -eq 100 }).Count
    
    $html += @"
        <p><strong>Protected Volumes:</strong> $protectedCount</p>
        <p><strong>Fully Encrypted:</strong> $encryptedCount</p>
    </div>
"@
    
    foreach ($vol in $Volumes) {
        $protectionClass = if ($vol.ProtectionStatus -eq "On") { "status-protected" } else { "status-unprotected" }
        $encryptionClass = if ($vol.EncryptionPercentage -eq 100) { "encryption-complete" } else { "encryption-incomplete" }
        
        $html += @"
    <div class="volume">
        <div class="volume-header">Volume: $($vol.MountPoint)</div>
        <div class="info-grid">
            <div class="info-label">Volume Label:</div><div>$($vol.VolumeName)</div>
            <div class="info-label">Volume Type:</div><div>$($vol.VolumeType)</div>
            <div class="info-label">Protection Status:</div><div class="$protectionClass">$($vol.ProtectionStatus)</div>
            <div class="info-label">Encryption:</div><div class="$encryptionClass">$($vol.EncryptionPercentage)%</div>
            <div class="info-label">Volume Status:</div><div>$($vol.VolumeStatus)</div>
            <div class="info-label">Lock Status:</div><div>$($vol.LockStatus)</div>
            <div class="info-label">Encryption Method:</div><div>$($vol.EncryptionMethod)</div>
        </div>
        <h3>Key Protectors ($($vol.KeyProtector.Count))</h3>
"@
        
        if ($vol.KeyProtector.Count -gt 0) {
            foreach ($kp in $vol.KeyProtector) {
                $html += @"
        <div class="key-protector">
            <strong>Type:</strong> $($kp.KeyProtectorType)<br>
            <strong>ID:</strong> $($kp.KeyProtectorId)<br>
"@
                if ($kp.RecoveryPassword) {
                    $html += @"
            <strong>Recovery Password:</strong> <span class="recovery-key">$($kp.RecoveryPassword)</span><br>
"@
                }
                $html += "        </div>`n"
            }
        }
        else {
            $html += "        <p style='color: #e74c3c;'>No key protectors configured</p>`n"
        }
        
        $html += "    </div>`n"
    }
    
    $html += @"
    <div class="footer">
        <p>Generated by BitLocker Status Report Tool | Coded by Soulitek.co.il</p>
        <p>www.soulitek.co.il | (C) 2025 Soulitek - All Rights Reserved</p>
    </div>
</body>
</html>
"@
    
    Set-Content -Path $filePath -Value $html -Encoding UTF8
    
    Write-Host ""
    Write-SouliTEKResult "HTML report exported to: $filePath" -Level SUCCESS
    Start-Sleep -Seconds 1
    Start-Process $filePath
}

# ============================================================
# MAIN MENU
# ============================================================

function Show-MainMenu {
    Show-Header "BITLOCKER STATUS REPORT - Professional Tool" -Color Cyan
    
    Write-Host "      Coded by: Soulitek.co.il" -ForegroundColor Green
    Write-Host "      IT Solutions for your business" -ForegroundColor Green
    Write-Host "      www.soulitek.co.il" -ForegroundColor Green
    Write-Host ""
    Write-Host "      (C) 2025 Soulitek - All Rights Reserved" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Select an option:" -ForegroundColor White
    Write-Host ""
    Write-Host "  [1] BitLocker Status      - Check all volumes" -ForegroundColor Yellow
    Write-Host "  [2] Recovery Keys         - Display recovery keys" -ForegroundColor Yellow
    Write-Host "  [3] Detailed Report       - Comprehensive analysis" -ForegroundColor Yellow
    Write-Host "  [4] Health Check          - Security audit" -ForegroundColor Yellow
    Write-Host "  [5] Export Report         - Save to file" -ForegroundColor Cyan
    Write-Host "  [6] Help                  - Usage guide" -ForegroundColor White
    Write-Host "  [0] Exit" -ForegroundColor Red
    Write-Host ""
    Write-Host "========================================" -ForegroundColor DarkGray
    
    $choice = Read-Host "Enter your choice (0-6)"
    return $choice
}

function Show-Help {
    Show-Header "HELP GUIDE" -Color Cyan
    
    Write-Host "BITLOCKER STATUS REPORT - USAGE GUIDE" -ForegroundColor Yellow
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "[1] BITLOCKER STATUS" -ForegroundColor White
    Write-Host "    Shows encryption status for all volumes" -ForegroundColor Gray
    Write-Host "    Displays: Protection status, encryption percentage," -ForegroundColor Gray
    Write-Host "              encryption method, key protectors, lock status" -ForegroundColor Gray
    Write-Host ""
    Write-Host "[2] RECOVERY KEYS" -ForegroundColor White
    Write-Host "    Displays BitLocker recovery passwords" -ForegroundColor Gray
    Write-Host "    WARNING: These are sensitive! Keep them secure." -ForegroundColor Red
    Write-Host "    Use: Save recovery keys before hardware changes" -ForegroundColor Gray
    Write-Host ""
    Write-Host "[3] DETAILED REPORT" -ForegroundColor White
    Write-Host "    Comprehensive analysis of all volumes" -ForegroundColor Gray
    Write-Host "    Includes: All properties, security recommendations" -ForegroundColor Gray
    Write-Host "    Use: Full audit of BitLocker configuration" -ForegroundColor Gray
    Write-Host ""
    Write-Host "[4] HEALTH CHECK" -ForegroundColor White
    Write-Host "    Quick security audit of BitLocker setup" -ForegroundColor Gray
    Write-Host "    Checks: OS drive protection, recovery keys," -ForegroundColor Gray
    Write-Host "            encryption completion, configuration issues" -ForegroundColor Gray
    Write-Host ""
    Write-Host "[5] EXPORT REPORT" -ForegroundColor White
    Write-Host "    Save BitLocker status to file" -ForegroundColor Gray
    Write-Host "    Formats: Text (.txt), CSV (.csv), HTML (.html)" -ForegroundColor Gray
    Write-Host "    Use: Documentation, compliance, backup records" -ForegroundColor Gray
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "UNDERSTANDING BITLOCKER:" -ForegroundColor Yellow
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Protection Status:" -ForegroundColor White
    Write-Host "  On  - BitLocker is active and protecting the drive" -ForegroundColor Green
    Write-Host "  Off - Drive is not protected by BitLocker" -ForegroundColor Red
    Write-Host ""
    Write-Host "Encryption Percentage:" -ForegroundColor White
    Write-Host "  100% - Fully encrypted (secure)" -ForegroundColor Green
    Write-Host "  0-99% - Encryption in progress" -ForegroundColor Yellow
    Write-Host "  0%   - Not encrypted" -ForegroundColor Red
    Write-Host ""
    Write-Host "Key Protector Types:" -ForegroundColor White
    Write-Host "  TPM              - Trusted Platform Module (hardware)" -ForegroundColor Cyan
    Write-Host "  RecoveryPassword - 48-digit recovery key" -ForegroundColor Green
    Write-Host "  Password         - User password protection" -ForegroundColor Yellow
    Write-Host "  TpmPin           - TPM + PIN combination" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "COMMON SCENARIOS:" -ForegroundColor Yellow
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Scenario 1: Save recovery keys before hardware upgrade" -ForegroundColor White
    Write-Host "  Use option [2] to display and save recovery passwords" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Scenario 2: Check if sensitive data drive is encrypted" -ForegroundColor White
    Write-Host "  Use option [1] to verify protection status" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Scenario 3: Compliance audit documentation" -ForegroundColor White
    Write-Host "  Use option [5] to export HTML report" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Scenario 4: Troubleshoot BitLocker issues" -ForegroundColor White
    Write-Host "  Use option [4] for health check with recommendations" -ForegroundColor Gray
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "REQUIREMENTS:" -ForegroundColor Yellow
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "- Windows Pro, Enterprise, or Education edition" -ForegroundColor Gray
    Write-Host "- Administrator privileges required" -ForegroundColor Gray
    Write-Host "- TPM 1.2 or higher (recommended)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Read-Host "Press Enter to return to main menu"
}

function Show-Disclaimer {
    Clear-Host
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "                    IMPORTANT NOTICE" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  This tool is provided `"AS IS`" without warranty." -ForegroundColor White
    Write-Host ""
    Write-Host "  USE AT YOUR OWN RISK" -ForegroundColor Red
    Write-Host ""
    Write-Host "  By continuing, you acknowledge that:" -ForegroundColor White
    Write-Host "  - You are solely responsible for any outcomes" -ForegroundColor Gray
    Write-Host "  - You will protect recovery keys appropriately" -ForegroundColor Gray
    Write-Host "  - You accept full responsibility for its use" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  WARNING: Recovery keys provide full access to encrypted" -ForegroundColor Yellow
    Write-Host "  drives. Keep them secure and confidential!" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Press any key to continue or Ctrl+C to cancel..." -ForegroundColor Cyan
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
}

function Show-ExitMessage {
    Clear-Host
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "            Thank you for using" -ForegroundColor White
    Write-Host "        BITLOCKER STATUS REPORT" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "       Coded by: Soulitek.co.il" -ForegroundColor Green
    Write-Host "       IT Solutions for your business" -ForegroundColor Green
    Write-Host "       www.soulitek.co.il" -ForegroundColor Green
    Write-Host ""
    Write-Host "       (C) 2025 Soulitek - All Rights Reserved" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "   Need IT security or encryption services?" -ForegroundColor White
    Write-Host "   Contact Soulitek for professional solutions." -ForegroundColor White
    Write-Host ""
    Write-Host "   Remember: Always back up your recovery keys!" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Start-Sleep -Seconds 4
}

# ============================================================
# MAIN EXECUTION
# ============================================================

# Check for administrator privileges
if (-not (Test-SouliTEKAdministrator)) {
    Clear-Host
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Red
    Write-Host "   ERROR: Administrator Privileges Required" -ForegroundColor Red
    Write-Host "============================================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "This script must run as Administrator to access BitLocker." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "HOW TO FIX:" -ForegroundColor White
    Write-Host "1. Right-click this file" -ForegroundColor Gray
    Write-Host "2. Select `"Run with PowerShell`"" -ForegroundColor Gray
    Write-Host "3. Or open PowerShell as Admin and run:" -ForegroundColor Gray
    Write-Host "   .\bitlocker_status_report.ps1" -ForegroundColor Gray
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Red
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit 1
}

# Show disclaimer
Show-Disclaimer

# Main menu loop
do {
    $choice = Show-MainMenu
    
    switch ($choice) {
        "1" { Get-BitLockerStatus }
        "2" { Get-RecoveryKeys }
        "3" { Get-DetailedVolumeReport }
        "4" { Test-BitLockerHealth }
        "5" { Export-BitLockerReport }
        "6" { Show-Help }
        "0" {
            Show-ExitMessage
            break
        }
        default {
            Write-Host "Invalid choice. Please try again." -ForegroundColor Red
            Start-Sleep -Seconds 2
        }
    }
} while ($choice -ne "0")




