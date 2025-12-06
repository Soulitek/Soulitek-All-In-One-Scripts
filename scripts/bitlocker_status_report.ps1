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
# analysis and recovery key management for all volumes.
# 
# Features: Status Check | Recovery Keys | Detailed Reports | Security Audit
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
$Host.UI.RawUI.WindowTitle = "BITLOCKER STATUS REPORT"

# Import SouliTEK Common Functions
$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$CommonPath = Join-Path (Split-Path -Parent $ScriptRoot) "modules\SouliTEK-Common.ps1"
if (Test-Path $CommonPath) {
    . $CommonPath
} else {
    Write-Warning "SouliTEK Common Functions not found at: $CommonPath"
    Write-Warning "Some functions may not work properly."
}

# Check if BitLocker module is available
function Test-BitLockerAvailable {
    try {
        $null = Get-Command Get-BitLockerVolume -ErrorAction Stop
        return $true
    }
    catch {
        return $false
    }
}

# Check administrator privileges
function Assert-BitLockerAdmin {
    if (-not (Test-SouliTEKAdministrator)) {
        Show-SouliTEKHeader "ADMINISTRATOR REQUIRED" "BitLocker operations require elevated privileges." -Color ([ConsoleColor]::Red)
        Write-SouliTEKWarning "Please run PowerShell as Administrator and retry."
        Write-Host ""
        Read-Host "Press Enter to exit"
        exit 1
    }
}

# Show-Disclaimer function - using Show-SouliTEKDisclaimer from common module
function Show-Disclaimer {
    Show-SouliTEKDisclaimer
}

# Function to show main menu
function Show-MainMenu {
    Clear-Host
    Show-SouliTEKBanner
    Set-SouliTEKConsoleColor "Blue"
    Write-Host "Select an option:"
    Write-Host ""
    Write-Host "  [1] Check BitLocker Status      - View encryption status for all volumes"
    Write-Host "  [2] View Recovery Keys           - Display recovery keys (sensitive)"
    Write-Host "  [3] Export Recovery Keys         - Save recovery keys to file"
    Write-Host "  [4] Detailed Volume Report        - Comprehensive volume information"
    Write-Host "  [5] Security Audit               - Compliance and security analysis"
    Write-Host "  [6] Help                         - Usage guide"
    Write-Host "  [0] Exit"
    Write-Host ""
    Write-Host "========================================"
    Set-SouliTEKConsoleColor "White"
    $choice = Read-Host "Enter your choice (0-6)"
    return $choice
}

# Function to get BitLocker volume information
function Get-BitLockerInfo {
    try {
        $volumes = Get-BitLockerVolume -ErrorAction Stop
        return $volumes
    }
    catch {
        Write-SouliTEKError "Failed to retrieve BitLocker information: $($_.Exception.Message)"
        return $null
    }
}

# Function to check BitLocker status
function Show-BitLockerStatus {
    Clear-Host
    Show-SouliTEKHeader "BITLOCKER STATUS CHECK" "Encryption status for all volumes" -Color ([ConsoleColor]::Cyan)
    
    if (-not (Test-BitLockerAvailable)) {
        Write-SouliTEKError "BitLocker is not available on this system."
        Write-SouliTEKInfo "BitLocker requires Windows 10/11 Pro or Enterprise edition."
        Write-Host ""
        Read-Host "Press Enter to return to menu"
        return
    }
    
    $volumes = Get-BitLockerInfo
    if ($null -eq $volumes) {
        Write-Host ""
        Read-Host "Press Enter to return to menu"
        return
    }
    
    Write-Host ""
    Write-Host "Volume Encryption Status:" -ForegroundColor Yellow
    Write-Host "========================" -ForegroundColor Yellow
    Write-Host ""
    
    $encryptedCount = 0
    $encryptingCount = 0
    $unencryptedCount = 0
    
    foreach ($volume in $volumes) {
        $mountPoint = if ($volume.MountPoint) { $volume.MountPoint } else { "N/A" }
        $volumeType = if ($volume.VolumeType) { $volume.VolumeType } else { "Unknown" }
        $encryptionStatus = $volume.VolumeStatus
        $encryptionPercentage = $volume.EncryptionPercentage
        $protectionStatus = $volume.ProtectionStatus
        
        $statusColor = switch ($encryptionStatus) {
            "FullyEncrypted" { "Green" }
            "EncryptionInProgress" { "Yellow" }
            "DecryptionInProgress" { "Yellow" }
            "FullyDecrypted" { "Red" }
            default { "White" }
        }
        
        Write-Host "Volume: $mountPoint ($volumeType)" -ForegroundColor Cyan
        Write-Host "  Status: " -NoNewline
        Write-Host $encryptionStatus -ForegroundColor $statusColor
        Write-Host "  Encryption: $encryptionPercentage%"
        Write-Host "  Protection: $protectionStatus"
        
        # Get key protectors
        $keyProtectors = $volume.KeyProtector | Where-Object { $_.KeyProtectorType -ne "RecoveryPassword" }
        if ($keyProtectors) {
            $protectorTypes = ($keyProtectors | Select-Object -ExpandProperty KeyProtectorType -Unique) -join ", "
            Write-Host "  Key Protectors: $protectorTypes"
        }
        
        Write-Host ""
        
        # Count statuses
        switch ($encryptionStatus) {
            "FullyEncrypted" { $encryptedCount++ }
            "EncryptionInProgress" { $encryptingCount++ }
            "FullyDecrypted" { $unencryptedCount++ }
        }
    }
    
    Write-Host "Summary:" -ForegroundColor Yellow
    Write-Host "  Fully Encrypted: $encryptedCount"
    Write-Host "  Encryption In Progress: $encryptingCount"
    Write-Host "  Unencrypted: $unencryptedCount"
    Write-Host ""
    
    Read-Host "Press Enter to return to menu"
}

# Function to view recovery keys
function Show-RecoveryKeys {
    Clear-Host
    Show-SouliTEKHeader "RECOVERY KEYS" "BitLocker recovery keys (SENSITIVE INFORMATION)" -Color ([ConsoleColor]::Red)
    
    Write-SouliTEKWarning "Recovery keys are sensitive. Handle with care and store securely."
    Write-Host ""
    
    if (-not (Test-BitLockerAvailable)) {
        Write-SouliTEKError "BitLocker is not available on this system."
        Write-Host ""
        Read-Host "Press Enter to return to menu"
        return
    }
    
    $volumes = Get-BitLockerInfo
    if ($null -eq $volumes) {
        Write-Host ""
        Read-Host "Press Enter to return to menu"
        return
    }
    
    Write-Host ""
    $hasRecoveryKeys = $false
    
    foreach ($volume in $volumes) {
        $mountPoint = if ($volume.MountPoint) { $volume.MountPoint } else { "N/A" }
        $recoveryKeys = $volume.KeyProtector | Where-Object { $_.KeyProtectorType -eq "RecoveryPassword" }
        
        if ($recoveryKeys) {
            $hasRecoveryKeys = $true
            Write-Host "Volume: $mountPoint" -ForegroundColor Cyan
            Write-Host "===================" -ForegroundColor Cyan
            
            foreach ($key in $recoveryKeys) {
                Write-Host "  Key ID: $($key.KeyProtectorId)"
                Write-Host "  Recovery Key: $($key.RecoveryPassword)"
                Write-Host ""
            }
        }
    }
    
    if (-not $hasRecoveryKeys) {
        Write-SouliTEKInfo "No recovery keys found for any volumes."
        Write-SouliTEKInfo "Recovery keys are only available for encrypted volumes."
    }
    
    Write-Host ""
    Read-Host "Press Enter to return to menu"
}

# Function to export recovery keys
function Export-RecoveryKeys {
    Clear-Host
    Show-SouliTEKHeader "EXPORT RECOVERY KEYS" "Save recovery keys to secure file" -Color ([ConsoleColor]::Yellow)
    
    Write-SouliTEKWarning "Recovery keys will be saved to Desktop. Protect this file!"
    Write-Host ""
    
    if (-not (Test-BitLockerAvailable)) {
        Write-SouliTEKError "BitLocker is not available on this system."
        Write-Host ""
        Read-Host "Press Enter to return to menu"
        return
    }
    
    $volumes = Get-BitLockerInfo
    if ($null -eq $volumes) {
        Write-Host ""
        Read-Host "Press Enter to return to menu"
        return
    }
    
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $fileName = "BitLockerRecoveryKeys_$($env:COMPUTERNAME)_$timestamp.txt"
    $filePath = Join-Path $env:USERPROFILE "Desktop\$fileName"
    
    try {
        $content = @()
        $content += "=========================================="
        $content += "BitLocker Recovery Keys Export"
        $content += "=========================================="
        $content += ""
        $content += "Computer Name: $($env:COMPUTERNAME)"
        $content += "Export Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        $content += ""
        $content += "WARNING: This file contains sensitive recovery keys."
        $content += "Store this file in a secure location."
        $content += ""
        $content += "=========================================="
        $content += ""
        
        $hasKeys = $false
        foreach ($volume in $volumes) {
            $mountPoint = if ($volume.MountPoint) { $volume.MountPoint } else { "N/A" }
            $recoveryKeys = $volume.KeyProtector | Where-Object { $_.KeyProtectorType -eq "RecoveryPassword" }
            
            if ($recoveryKeys) {
                $hasKeys = $true
                $content += "Volume: $mountPoint"
                $content += "Status: $($volume.VolumeStatus)"
                $content += "---"
                
                foreach ($key in $recoveryKeys) {
                    $content += "Key ID: $($key.KeyProtectorId)"
                    $content += "Recovery Key: $($key.RecoveryPassword)"
                    $content += ""
                }
                $content += ""
            }
        }
        
        if (-not $hasKeys) {
            $content += "No recovery keys found for any volumes."
        }
        
        $content | Out-File -FilePath $filePath -Encoding UTF8
        
        if ($hasKeys) {
            Write-SouliTEKSuccess "Recovery keys exported to: $filePath"
            Write-SouliTEKWarning "IMPORTANT: Secure this file immediately!"
        } else {
            Write-SouliTEKInfo "No recovery keys found. File created but empty."
        }
    }
    catch {
        Write-SouliTEKError "Failed to export recovery keys: $($_.Exception.Message)"
    }
    
    Write-Host ""
    Read-Host "Press Enter to return to menu"
}

# Function to show detailed volume report
function Show-DetailedReport {
    Clear-Host
    Show-SouliTEKHeader "DETAILED VOLUME REPORT" "Comprehensive BitLocker information" -Color ([ConsoleColor]::Magenta)
    
    if (-not (Test-BitLockerAvailable)) {
        Write-SouliTEKError "BitLocker is not available on this system."
        Write-Host ""
        Read-Host "Press Enter to return to menu"
        return
    }
    
    $volumes = Get-BitLockerInfo
    if ($null -eq $volumes) {
        Write-Host ""
        Read-Host "Press Enter to return to menu"
        return
    }
    
    Write-Host ""
    
    foreach ($volume in $volumes) {
        $mountPoint = if ($volume.MountPoint) { $volume.MountPoint } else { "N/A" }
        $volumeType = if ($volume.VolumeType) { $volume.VolumeType } else { "Unknown" }
        
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host "Volume: $mountPoint ($volumeType)" -ForegroundColor Cyan
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Encryption Status: $($volume.VolumeStatus)"
        Write-Host "Encryption Percentage: $($volume.EncryptionPercentage)%"
        Write-Host "Protection Status: $($volume.ProtectionStatus)"
        Write-Host "Encryption Method: $($volume.EncryptionMethod)"
        Write-Host "Key Protector Count: $($volume.KeyProtector.Count)"
        Write-Host ""
        
        if ($volume.KeyProtector) {
            Write-Host "Key Protectors:" -ForegroundColor Yellow
            foreach ($protector in $volume.KeyProtector) {
                Write-Host "  Type: $($protector.KeyProtectorType)"
                Write-Host "  ID: $($protector.KeyProtectorId)"
                if ($protector.KeyProtectorType -eq "RecoveryPassword") {
                    Write-Host "  Recovery Password: $($protector.RecoveryPassword)"
                }
                Write-Host ""
            }
        }
        
        Write-Host ""
    }
    
    Read-Host "Press Enter to return to menu"
}

# Function to perform security audit
function Show-SecurityAudit {
    Clear-Host
    Show-SouliTEKHeader "SECURITY AUDIT" "BitLocker compliance and security analysis" -Color ([ConsoleColor]::Green)
    
    if (-not (Test-BitLockerAvailable)) {
        Write-SouliTEKError "BitLocker is not available on this system."
        Write-Host ""
        Read-Host "Press Enter to return to menu"
        return
    }
    
    $volumes = Get-BitLockerInfo
    if ($null -eq $volumes) {
        Write-Host ""
        Read-Host "Press Enter to return to menu"
        return
    }
    
    Write-Host ""
    Write-Host "Security Analysis:" -ForegroundColor Yellow
    Write-Host "==================" -ForegroundColor Yellow
    Write-Host ""
    
    $totalVolumes = $volumes.Count
    $encryptedVolumes = ($volumes | Where-Object { $_.VolumeStatus -eq "FullyEncrypted" }).Count
    $encryptingVolumes = ($volumes | Where-Object { $_.VolumeStatus -eq "EncryptionInProgress" }).Count
    $unencryptedVolumes = ($volumes | Where-Object { $_.VolumeStatus -eq "FullyDecrypted" }).Count
    $coveragePercent = if ($totalVolumes -gt 0) { [math]::Round(($encryptedVolumes / $totalVolumes) * 100, 2) } else { 0 }
    
    Write-Host "Total Volumes: $totalVolumes"
    Write-Host "Fully Encrypted: $encryptedVolumes" -ForegroundColor Green
    Write-Host "Encryption In Progress: $encryptingVolumes" -ForegroundColor Yellow
    Write-Host "Unencrypted: $unencryptedVolumes" -ForegroundColor $(if ($unencryptedVolumes -gt 0) { "Red" } else { "Green" })
    Write-Host "Encryption Coverage: $coveragePercent%"
    Write-Host ""
    
    # Recommendations
    Write-Host "Recommendations:" -ForegroundColor Yellow
    Write-Host "================" -ForegroundColor Yellow
    Write-Host ""
    
    if ($unencryptedVolumes -gt 0) {
        Write-Host "⚠ WARNING: $unencryptedVolumes volume(s) are not encrypted." -ForegroundColor Red
        Write-Host "  Recommendation: Enable BitLocker encryption for all volumes containing sensitive data."
        Write-Host ""
    }
    
    if ($encryptingVolumes -gt 0) {
        Write-Host "ℹ INFO: $encryptingVolumes volume(s) are currently encrypting." -ForegroundColor Yellow
        Write-Host "  Recommendation: Allow encryption to complete before considering system secure."
        Write-Host ""
    }
    
    $volumesWithoutRecovery = $volumes | Where-Object { 
        ($_.VolumeStatus -eq "FullyEncrypted") -and 
        -not ($_.KeyProtector | Where-Object { $_.KeyProtectorType -eq "RecoveryPassword" })
    }
    
    if ($volumesWithoutRecovery) {
        Write-Host "⚠ WARNING: Some encrypted volumes do not have recovery keys configured." -ForegroundColor Red
        Write-Host "  Recommendation: Configure recovery keys for all encrypted volumes."
        Write-Host ""
    }
    
    if ($encryptedVolumes -eq $totalVolumes -and $unencryptedVolumes -eq 0) {
        Write-Host "✓ All volumes are encrypted. Good security posture!" -ForegroundColor Green
        Write-Host ""
    }
    
    # Export option
    Write-Host ""
    $export = Read-Host "Export audit report to Desktop? (Y/N)"
    if ($export -eq "Y" -or $export -eq "y") {
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $fileName = "BitLockerAuditReport_$($env:COMPUTERNAME)_$timestamp.txt"
        $filePath = Join-Path $env:USERPROFILE "Desktop\$fileName"
        
        try {
            $content = @()
            $content += "=========================================="
            $content += "BitLocker Security Audit Report"
            $content += "=========================================="
            $content += ""
            $content += "Computer Name: $($env:COMPUTERNAME)"
            $content += "Audit Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
            $content += ""
            $content += "Summary:"
            $content += "  Total Volumes: $totalVolumes"
            $content += "  Fully Encrypted: $encryptedVolumes"
            $content += "  Encryption In Progress: $encryptingVolumes"
            $content += "  Unencrypted: $unencryptedVolumes"
            $content += "  Encryption Coverage: $coveragePercent%"
            $content += ""
            $content += "Detailed Information:"
            $content += ""
            
            foreach ($volume in $volumes) {
                $mountPoint = if ($volume.MountPoint) { $volume.MountPoint } else { "N/A" }
                $content += "Volume: $mountPoint"
                $content += "  Status: $($volume.VolumeStatus)"
                $content += "  Encryption: $($volume.EncryptionPercentage)%"
                $content += "  Protection: $($volume.ProtectionStatus)"
                $content += "  Method: $($volume.EncryptionMethod)"
                $content += ""
            }
            
            $content | Out-File -FilePath $filePath -Encoding UTF8
            Write-SouliTEKSuccess "Audit report exported to: $filePath"
        }
        catch {
            Write-SouliTEKError "Failed to export audit report: $($_.Exception.Message)"
        }
    }
    
    Write-Host ""
    Read-Host "Press Enter to return to menu"
}

# Function to show help
function Show-Help {
    Clear-Host
    Show-SouliTEKHeader "HELP" "BitLocker Status Report - Usage Guide" -Color ([ConsoleColor]::Blue)
    
    Write-Host ""
    Write-Host "About This Tool:" -ForegroundColor Yellow
    Write-Host "================" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "The BitLocker Status Report tool provides comprehensive analysis"
    Write-Host "and management of BitLocker encryption status across all volumes."
    Write-Host ""
    Write-Host "Features:" -ForegroundColor Yellow
    Write-Host "=========" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "1. Check BitLocker Status"
    Write-Host "   - View encryption status for all volumes"
    Write-Host "   - See encryption percentage and protection status"
    Write-Host ""
    Write-Host "2. View Recovery Keys"
    Write-Host "   - Display recovery keys for encrypted volumes"
    Write-Host "   - WARNING: Keys are sensitive - handle securely"
    Write-Host ""
    Write-Host "3. Export Recovery Keys"
    Write-Host "   - Save recovery keys to Desktop"
    Write-Host "   - Timestamped filename"
    Write-Host "   - Secure storage recommended"
    Write-Host ""
    Write-Host "4. Detailed Volume Report"
    Write-Host "   - Comprehensive information per volume"
    Write-Host "   - Encryption method and key protectors"
    Write-Host ""
    Write-Host "5. Security Audit"
    Write-Host "   - Compliance checking"
    Write-Host "   - Encryption coverage analysis"
    Write-Host "   - Security recommendations"
    Write-Host ""
    Write-Host "Requirements:" -ForegroundColor Yellow
    Write-Host "=============" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "- Windows 10/11 Pro or Enterprise"
    Write-Host "- Administrator privileges"
    Write-Host "- BitLocker feature available"
    Write-Host ""
    Write-Host "Security Notes:" -ForegroundColor Yellow
    Write-Host "==============" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "- Recovery keys can unlock encrypted drives"
    Write-Host "- Store keys in secure location"
    Write-Host "- Never share keys via unsecured channels"
    Write-Host ""
    
    Read-Host "Press Enter to return to menu"
}

# Main execution
try {
    # Check for administrator privileges
    Assert-BitLockerAdmin
    
    # Show disclaimer on first run
    Show-Disclaimer
    
    # Main menu loop
    $running = $true
    while ($running) {
        $choice = Show-MainMenu
        
        switch ($choice) {
            "1" { Show-BitLockerStatus }
            "2" { Show-RecoveryKeys }
            "3" { Export-RecoveryKeys }
            "4" { Show-DetailedReport }
            "5" { Show-SecurityAudit }
            "6" { Show-Help }
            "0" { 
                Show-SouliTEKExitMessage -ToolName "BitLocker Status Report"
                $running = $false
            }
            default {
                Write-Host ""
                Write-Host "Invalid choice. Please try again." -ForegroundColor Red
                Start-Sleep -Seconds 2
            }
        }
    }
}
catch {
    Write-Host ""
    Write-Host "[X] Fatal Error: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "Stack Trace:" -ForegroundColor Yellow
    Write-Host $_.ScriptStackTrace -ForegroundColor Gray
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit 1
}

