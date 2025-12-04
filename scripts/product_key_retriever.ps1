# ============================================================
# SouliTEK All-In-One Scripts - Product Key Retriever
# ============================================================
# 
# Coded by: Soulitek.co.il
# IT Solutions for your business
# 
# (C) 2025 SouliTEK - All Rights Reserved
# Website: www.soulitek.co.il
# 
# This tool retrieves product keys for Windows and Office
# installations from the system registry and WMI.
# 
# ============================================================

#Requires -Version 5.1

$Script:Version = "1.0.0"
$Script:ToolName = "Product Key Retriever"

# ============================================================
# IMPORT COMMON MODULE
# ============================================================

$Script:ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$Script:RootPath = Split-Path -Parent $Script:ScriptPath
$CommonPath = Join-Path $Script:RootPath "modules\SouliTEK-Common.ps1"

if (Test-Path $CommonPath) {
    . $CommonPath
} else {
    Write-Warning "SouliTEK Common Functions not found at: $CommonPath"
}

# ============================================================
# CONFIGURATION
# ============================================================

$Script:ProductKeys = @()

# ============================================================
# HELPER FUNCTIONS
# ============================================================

function Get-WindowsProductKey {
    <#
    .SYNOPSIS
        Retrieves Windows product key using multiple methods.
    #>
    
    $keys = @()
    
    # Method 1: WMI - SoftwareLicensingProduct
    try {
        Write-SouliTEKResult "Attempting to retrieve Windows key via WMI..." -Level INFO
        $licensing = Get-WmiObject -Class SoftwareLicensingProduct -ErrorAction SilentlyContinue | 
                     Where-Object { $_.ApplicationID -eq "55c92734-d682-4d71-983e-d6ec3f16059f" -and $_.LicenseStatus -eq 1 }
        
        if ($licensing) {
            foreach ($license in $licensing) {
                if ($license.OA3xOriginalProductKey) {
                    $keys += [PSCustomObject]@{
                        Product = "Windows"
                        Version = "Unknown"
                        Key = $license.OA3xOriginalProductKey
                        Method = "WMI (OA3xOriginalProductKey)"
                        Status = "Found"
                    }
                }
            }
        }
    }
    catch {
        Write-SouliTEKResult "WMI method failed: $_" -Level WARNING
    }
    
    # Method 2: WMI - SoftwareLicensingService
    try {
        Write-SouliTEKResult "Attempting to retrieve Windows key via SoftwareLicensingService..." -Level INFO
        $service = Get-WmiObject -Class SoftwareLicensingService -ErrorAction SilentlyContinue
        
        if ($service -and $service.OA3xOriginalProductKey) {
            $keys += [PSCustomObject]@{
                Product = "Windows"
                Version = "Unknown"
                Key = $service.OA3xOriginalProductKey
                Method = "WMI (SoftwareLicensingService)"
                Status = "Found"
            }
        }
    }
    catch {
        Write-SouliTEKResult "SoftwareLicensingService method failed: $_" -Level WARNING
    }
    
    # Method 3: Registry - DigitalProductId (requires decoding)
    try {
        Write-SouliTEKResult "Attempting to retrieve Windows key from registry..." -Level INFO
        $regPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion"
        $digitalProductId = (Get-ItemProperty -Path $regPath -Name DigitalProductId -ErrorAction SilentlyContinue).DigitalProductId
        
        if ($digitalProductId) {
            $productName = (Get-ItemProperty -Path $regPath -Name ProductName -ErrorAction SilentlyContinue).ProductName
            $displayVersion = (Get-ItemProperty -Path $regPath -Name DisplayVersion -ErrorAction SilentlyContinue).DisplayVersion
            $editionId = (Get-ItemProperty -Path $regPath -Name EditionID -ErrorAction SilentlyContinue).EditionID
            
            $version = if ($displayVersion) { "$productName $displayVersion" } else { $productName }
            if ($editionId) { $version += " ($editionId)" }
            
            # Decode DigitalProductId to product key
            $decodedKey = Convert-DigitalProductIdToKey -DigitalProductId $digitalProductId
            
            if ($decodedKey) {
                $keys += [PSCustomObject]@{
                    Product = "Windows"
                    Version = $version
                    Key = $decodedKey
                    Method = "Registry (DigitalProductId - Decoded)"
                    Status = "Found"
                }
            }
        }
    }
    catch {
        Write-SouliTEKResult "Registry method failed: $_" -Level WARNING
    }
    
    # If no keys found, try to get Windows version info anyway
    if ($keys.Count -eq 0) {
        try {
            $regPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion"
            $productName = (Get-ItemProperty -Path $regPath -Name ProductName -ErrorAction SilentlyContinue).ProductName
            $displayVersion = (Get-ItemProperty -Path $regPath -Name DisplayVersion -ErrorAction SilentlyContinue).DisplayVersion
            $editionId = (Get-ItemProperty -Path $regPath -Name EditionID -ErrorAction SilentlyContinue).EditionID
            
            $version = if ($displayVersion) { "$productName $displayVersion" } else { $productName }
            if ($editionId) { $version += " ($editionId)" }
            
            $keys += [PSCustomObject]@{
                Product = "Windows"
                Version = $version
                Key = "Not Available (Key may be stored in BIOS/UEFI or digitally activated)"
                Method = "System Information"
                Status = "Not Found"
            }
        }
        catch {
            Write-SouliTEKResult "Could not retrieve Windows information: $_" -Level ERROR
        }
    }
    
    return $keys
}

function Convert-DigitalProductIdToKey {
    <#
    .SYNOPSIS
        Converts DigitalProductId registry value to product key.
    .DESCRIPTION
        Decodes the binary DigitalProductId value from Windows registry
        into a readable product key format.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [byte[]]$DigitalProductId
    )
    
    try {
        # Product key decoding algorithm
        $keyStartOffset = 52
        $keyEndOffset = $keyStartOffset + 15
        
        if ($DigitalProductId.Length -lt ($keyEndOffset + 1)) {
            return $null
        }
        
        $decodedChars = @()
        $chars = "BCDFGHJKMPQRTVWXY2346789"
        
        for ($i = 24; $i -ge 0; $i--) {
            $cur = 0
            for ($j = 14; $j -ge 0; $j--) {
                $cur = ($cur * 256) -bxor $DigitalProductId[$keyStartOffset + $j]
                $DigitalProductId[$keyStartOffset + $j] = [Math]::Floor($cur / 24)
                $cur = $cur % 24
            }
            $decodedChars += $chars[$cur]
            
            if (($i % 5 -eq 0) -and ($i -ne 0)) {
                $decodedChars += "-"
            }
        }
        
        $key = -join ($decodedChars -join "")
        return $key
    }
    catch {
        Write-SouliTEKResult "Failed to decode DigitalProductId: $_" -Level WARNING
        return $null
    }
}

function Get-OfficeProductKeys {
    <#
    .SYNOPSIS
        Retrieves Office product keys from registry.
    #>
    
    $keys = @()
    
    # Office versions to check
    $officeVersions = @(
        @{ Path = "HKLM:\SOFTWARE\Microsoft\Office\16.0\Registration"; Version = "Office 2016/2019/2021/365" }
        @{ Path = "HKLM:\SOFTWARE\Microsoft\Office\15.0\Registration"; Version = "Office 2013" }
        @{ Path = "HKLM:\SOFTWARE\Microsoft\Office\14.0\Registration"; Version = "Office 2010" }
        @{ Path = "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Office\16.0\Registration"; Version = "Office 2016/2019/2021/365 (32-bit)" }
        @{ Path = "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Office\15.0\Registration"; Version = "Office 2013 (32-bit)" }
        @{ Path = "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Office\14.0\Registration"; Version = "Office 2010 (32-bit)" }
    )
    
    foreach ($officeVersion in $officeVersions) {
        if (Test-Path $officeVersion.Path) {
            try {
                Write-SouliTEKResult "Checking for $($officeVersion.Version)..." -Level INFO
                
                $regKeys = Get-ChildItem -Path $officeVersion.Path -ErrorAction SilentlyContinue
                
                foreach ($regKey in $regKeys) {
                    try {
                        $props = Get-ItemProperty -Path $regKey.PSPath -ErrorAction SilentlyContinue
                        
                        $productName = if ($props.PSObject.Properties.Name -contains "ProductName") { 
                            $props.ProductName 
                        } else { 
                            $officeVersion.Version 
                        }
                        
                        $productId = if ($props.PSObject.Properties.Name -contains "ProductID") { 
                            $props.ProductID 
                        } else { 
                            $null 
                        }
                        
                        # Try to get product key
                        $productKey = $null
                        $keyMethod = "Not Available"
                        
                        # Check for DigitalProductId (needs decoding)
                        if ($props.PSObject.Properties.Name -contains "DigitalProductId") {
                            $digitalProductId = $props.DigitalProductId
                            if ($digitalProductId) {
                                $decodedKey = Convert-DigitalProductIdToKey -DigitalProductId $digitalProductId
                                if ($decodedKey) {
                                    $productKey = $decodedKey
                                    $keyMethod = "Registry (DigitalProductId - Decoded)"
                                }
                            }
                        }
                        
                        # Check for other key locations
                        if (-not $productKey) {
                            if ($props.PSObject.Properties.Name -contains "ProductKey") {
                                $productKey = $props.ProductKey
                                $keyMethod = "Registry (ProductKey)"
                            }
                        }
                        
                        if (-not $productKey) {
                            $productKey = "Not Available (May be digitally activated or stored in Microsoft account)"
                            $keyMethod = "System Information"
                        }
                        
                        $keys += [PSCustomObject]@{
                            Product = $productName
                            Version = $officeVersion.Version
                            Key = $productKey
                            Method = $keyMethod
                            Status = if ($productKey -like "Not Available*") { "Not Found" } else { "Found" }
                            ProductID = $productId
                        }
                    }
                    catch {
                        Write-SouliTEKResult "Error reading Office key from $($regKey.Name): $_" -Level WARNING
                    }
                }
            }
            catch {
                Write-SouliTEKResult "Error accessing $($officeVersion.Path): $_" -Level WARNING
            }
        }
    }
    
    return $keys
}

# ============================================================
# DISPLAY FUNCTIONS
# ============================================================

function Show-ProductKeys {
    <#
    .SYNOPSIS
        Displays all retrieved product keys.
    #>
    
    Clear-Host
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "  PRODUCT KEYS RETRIEVAL RESULTS" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    
    if ($Script:ProductKeys.Count -eq 0) {
        Write-Host "  No product keys found." -ForegroundColor Yellow
        Write-Host ""
        Write-Host "  This could mean:" -ForegroundColor Gray
        Write-Host "  - Windows/Office is digitally activated" -ForegroundColor Gray
        Write-Host "  - Product key is stored in BIOS/UEFI" -ForegroundColor Gray
        Write-Host "  - Product key is linked to Microsoft account" -ForegroundColor Gray
        Write-Host ""
    } else {
        $index = 1
        foreach ($keyInfo in $Script:ProductKeys) {
            Write-Host "  [$index] $($keyInfo.Product)" -ForegroundColor Yellow
            if ($keyInfo.Version -and $keyInfo.Version -ne "Unknown") {
                Write-Host "      Version: $($keyInfo.Version)" -ForegroundColor Gray
            }
            Write-Host "      Key: " -NoNewline -ForegroundColor Gray
            if ($keyInfo.Status -eq "Found") {
                Write-Host $keyInfo.Key -ForegroundColor Green
            } else {
                Write-Host $keyInfo.Key -ForegroundColor Yellow
            }
            Write-Host "      Method: $($keyInfo.Method)" -ForegroundColor Gray
            if ($keyInfo.ProductID) {
                Write-Host "      Product ID: $($keyInfo.ProductID)" -ForegroundColor Gray
            }
            Write-Host ""
            $index++
        }
    }
    
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  IMPORTANT:" -ForegroundColor Yellow
    Write-Host "  - Save these keys in a secure location" -ForegroundColor Gray
    Write-Host "  - Product keys are sensitive information" -ForegroundColor Gray
    Write-Host "  - Some keys may not be retrievable if digitally activated" -ForegroundColor Gray
    Write-Host ""
    
    Wait-SouliTEKKeyPress
}

function Invoke-FullScan {
    <#
    .SYNOPSIS
        Performs a full scan for Windows and Office product keys.
    #>
    
    Clear-Host
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "  SCANNING FOR PRODUCT KEYS..." -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    
    $Script:ProductKeys = @()
    
    # Get Windows keys
    Write-SouliTEKResult "Retrieving Windows product key..." -Level INFO
    $windowsKeys = Get-WindowsProductKey
    $Script:ProductKeys += $windowsKeys
    
    # Get Office keys
    Write-SouliTEKResult "Retrieving Office product keys..." -Level INFO
    $officeKeys = Get-OfficeProductKeys
    $Script:ProductKeys += $officeKeys
    
    Write-Host ""
    Write-SouliTEKResult "Scan complete. Found $($Script:ProductKeys.Count) product key(s)." -Level SUCCESS
    Write-Host ""
    
    Start-Sleep -Seconds 2
    Show-ProductKeys
}

function Export-ProductKeys {
    <#
    .SYNOPSIS
        Exports product keys to a file.
    #>
    
    if ($Script:ProductKeys.Count -eq 0) {
        Write-Host ""
        Write-Host "No product keys to export. Please run a full scan first." -ForegroundColor Yellow
        Wait-SouliTEKKeyPress
        return
    }
    
    $format = Show-SouliTEKExportMenu -Title "EXPORT PRODUCT KEYS REPORT"
    
    if ($format -eq "CANCEL") {
        return
    }
    
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $desktopPath = [Environment]::GetFolderPath("Desktop")
    
    $exportData = foreach ($keyInfo in $Script:ProductKeys) {
        [PSCustomObject]@{
            Product = $keyInfo.Product
            Version = if ($keyInfo.Version) { $keyInfo.Version } else { "" }
            Key = $keyInfo.Key
            Method = $keyInfo.Method
            Status = $keyInfo.Status
            ProductID = if ($keyInfo.ProductID) { $keyInfo.ProductID } else { "" }
        }
    }
    
    if ($format -eq "ALL") {
        $formats = @("TXT", "CSV", "HTML")
    } else {
        $formats = @($format)
    }
    
    $foundCount = ($exportData | Where-Object { $_.Status -eq "Found" }).Count
    $notFoundCount = ($exportData | Where-Object { $_.Status -eq "Not Found" }).Count
    
    foreach ($fmt in $formats) {
        $extension = $fmt.ToLower()
        $outputPath = Join-Path $desktopPath "Product_Keys_$timestamp.$extension"
        
        $extraInfo = @{
            "Total Products" = $Script:ProductKeys.Count
            "Keys Found" = $foundCount
            "Keys Not Found" = $notFoundCount
            "Windows Keys" = ($Script:ProductKeys | Where-Object { $_.Product -eq "Windows" }).Count
            "Office Keys" = ($Script:ProductKeys | Where-Object { $_.Product -like "Office*" }).Count
        }
        
        Export-SouliTEKReport -Data $exportData -Title "Product Keys Report" `
                             -Format $fmt -OutputPath $outputPath -ExtraInfo $extraInfo `
                             -OpenAfterExport:($formats.Count -eq 1)
    }
    
    Wait-SouliTEKKeyPress
}

function Show-Help {
    <#
    .SYNOPSIS
        Displays help information.
    #>
    
    Clear-Host
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "  PRODUCT KEY RETRIEVER - HELP" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  ABOUT:" -ForegroundColor Yellow
    Write-Host "  This tool retrieves product keys for Windows and Office" -ForegroundColor Gray
    Write-Host "  installations from the system registry and WMI." -ForegroundColor Gray
    Write-Host ""
    Write-Host "  WHAT IT DOES:" -ForegroundColor Yellow
    Write-Host "  - Retrieves Windows product keys using multiple methods" -ForegroundColor Gray
    Write-Host "  - Retrieves Office product keys (2010, 2013, 2016, 2019, 2021, 365)" -ForegroundColor Gray
    Write-Host "  - Attempts WMI queries, registry lookups, and key decoding" -ForegroundColor Gray
    Write-Host "  - Exports results to multiple formats" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  RETRIEVAL METHODS:" -ForegroundColor Yellow
    Write-Host "  - WMI (SoftwareLicensingProduct/Service)" -ForegroundColor Gray
    Write-Host "  - Registry (DigitalProductId - decoded)" -ForegroundColor Gray
    Write-Host "  - Registry (ProductKey direct)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  LIMITATIONS:" -ForegroundColor Yellow
    Write-Host "  - Digitally activated Windows/Office may not show keys" -ForegroundColor Gray
    Write-Host "  - Keys stored in BIOS/UEFI may not be retrievable" -ForegroundColor Gray
    Write-Host "  - Microsoft account-linked keys may not be accessible" -ForegroundColor Gray
    Write-Host "  - Some OEM installations may not expose keys" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  SECURITY:" -ForegroundColor Yellow
    Write-Host "  - Product keys are sensitive information" -ForegroundColor Gray
    Write-Host "  - Store exported files securely" -ForegroundColor Gray
    Write-Host "  - Do not share product keys publicly" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  RECOMMENDATIONS:" -ForegroundColor Yellow
    Write-Host "  - Export and save keys to secure location" -ForegroundColor Gray
    Write-Host "  - Keep keys with system documentation" -ForegroundColor Gray
    Write-Host "  - Use for backup/recovery purposes only" -ForegroundColor Gray
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    
    Wait-SouliTEKKeyPress
}

function Show-Menu {
    <#
    .SYNOPSIS
        Displays the main menu.
    #>
    
    Clear-Host
    Show-SouliTEKBanner
    
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host "  PRODUCT KEY RETRIEVER v$Script:Version" -ForegroundColor Magenta
    Write-Host "  Retrieve Windows and Office product keys" -ForegroundColor Gray
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host ""
    
    if ($Script:ProductKeys.Count -gt 0) {
        $foundCount = ($Script:ProductKeys | Where-Object { $_.Status -eq "Found" }).Count
        Write-Host "  Last Scan: $($Script:ProductKeys.Count) product(s) found ($foundCount key(s) retrieved)" -ForegroundColor Cyan
    }
    
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  [1] Full Scan" -ForegroundColor Yellow
    Write-Host "      Scan for Windows and Office product keys" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  [2] View Results" -ForegroundColor Yellow
    Write-Host "      Display all retrieved product keys" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  [3] Export Results" -ForegroundColor Yellow
    Write-Host "      Export product keys to file" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  [4] Help" -ForegroundColor Yellow
    Write-Host "      Show usage instructions" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  [0] Exit" -ForegroundColor Red
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
}

# ============================================================
# MAIN EXECUTION
# ============================================================

# Initialize
Initialize-SouliTEKScript -WindowTitle "SouliTEK - Product Key Retriever v$Script:Version"

# Main loop
do {
    Show-Menu
    $choice = Read-Host "Select option (0-4)"
    
    switch ($choice) {
        "1" { Invoke-FullScan }
        "2" { Show-ProductKeys }
        "3" { Export-ProductKeys }
        "4" { Show-Help }
        "0" {
            Show-SouliTEKExitMessage -ScriptPath $PSCommandPath -ToolName $Script:ToolName
            exit 0
        }
        default {
            Write-Host "Invalid option. Please try again." -ForegroundColor Red
            Start-Sleep -Seconds 1
        }
    }
} while ($true)







