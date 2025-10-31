# ============================================================
# Full Hardware Inventory Report - Professional Edition
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
# This tool collects comprehensive hardware information including
# CPU, GPU, RAM, disk, motherboard, BIOS, and serial numbers.
# Exports JSON/CSV formats for warranty tracking.
# 
# Features: CPU Details | GPU Information | RAM Modules | Storage
#           Motherboard | BIOS Info | Serial Numbers | JSON/CSV Export
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
$Host.UI.RawUI.WindowTitle = "HARDWARE INVENTORY REPORT"

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

$Script:InventoryData = $null
$Script:OutputFolder = Join-Path $env:USERPROFILE "Desktop"

# ============================================================
# HELPER FUNCTIONS
# ============================================================

function Show-Header {
    param([string]$Title = "HARDWARE INVENTORY REPORT", [ConsoleColor]$Color = 'Cyan')
    
    Clear-Host
    Show-SouliTEKBanner
    Write-Host "============================================================" -ForegroundColor $Color
    Write-Host ""
    Write-Host "  $Title" -ForegroundColor $Color
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor $Color
    Write-Host ""
}

# ============================================================
# HARDWARE COLLECTION FUNCTIONS
# ============================================================

function Get-HardwareInventory {
    Show-Header "COLLECTING HARDWARE INVENTORY" -Color Green
    
    Write-Host "      Gathering comprehensive hardware information..." -ForegroundColor Gray
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    
    Write-SouliTEKResult "Starting hardware inventory collection..." -Level INFO
    Write-Host ""
    
    $inventory = @{
        ComputerInfo = @{}
        CPU = @()
        GPU = @()
        RAM = @()
        Storage = @()
        Motherboard = @{}
        BIOS = @{}
        NetworkAdapters = @()
        SerialNumbers = @{}
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }
    
    try {
        # Computer Information
        Write-SouliTEKResult "Gathering Computer Information..." -Level INFO
        $computerSystem = Get-CimInstance Win32_ComputerSystem -ErrorAction SilentlyContinue
        $osInfo = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue
        
        if ($computerSystem -and $osInfo) {
            $inventory.ComputerInfo = @{
                Name = $computerSystem.Name
                Manufacturer = $computerSystem.Manufacturer
                Model = $computerSystem.Model
                Domain = $computerSystem.Domain
                UserName = $computerSystem.UserName
                TotalPhysicalMemory = [math]::Round($computerSystem.TotalPhysicalMemory / 1GB, 2)
                OperatingSystem = $osInfo.Caption
                OSVersion = $osInfo.Version
                OSArchitecture = $osInfo.OSArchitecture
                SystemDirectory = $osInfo.SystemDirectory
            }
            Write-SouliTEKResult "Computer information collected" -Level SUCCESS
        }

        # CPU Information
        Write-SouliTEKResult "Gathering CPU Information..." -Level INFO
        $processors = Get-CimInstance Win32_Processor -ErrorAction SilentlyContinue
        if ($processors) {
            foreach ($cpu in $processors) {
                $inventory.CPU += @{
                    Name = $cpu.Name
                    Manufacturer = $cpu.Manufacturer
                    Description = $cpu.Description
                    Family = $cpu.Family
                    Model = $cpu.Model
                    Stepping = $cpu.Stepping
                    NumberOfCores = $cpu.NumberOfCores
                    NumberOfLogicalProcessors = $cpu.NumberOfLogicalProcessors
                    MaxClockSpeed = "$($cpu.MaxClockSpeed) MHz"
                    CurrentClockSpeed = if ($cpu.CurrentClockSpeed) { "$($cpu.CurrentClockSpeed) MHz" } else { "N/A" }
                    L2CacheSize = if ($cpu.L2CacheSize) { "$([math]::Round($cpu.L2CacheSize / 1KB, 2)) KB" } else { "N/A" }
                    L3CacheSize = if ($cpu.L3CacheSize) { "$([math]::Round($cpu.L3CacheSize / 1KB, 2)) KB" } else { "N/A" }
                    SerialNumber = $cpu.SerialNumber
                    ProcessorId = $cpu.ProcessorId
                }
            }
            Write-SouliTEKResult "CPU information collected ($($processors.Count) processor(s))" -Level SUCCESS
        }

        # GPU Information
        Write-SouliTEKResult "Gathering GPU Information..." -Level INFO
        $gpus = Get-CimInstance Win32_VideoController -ErrorAction SilentlyContinue
        if ($gpus) {
            foreach ($gpu in $gpus) {
                if ($gpu.Name -and $gpu.Name -ne "Microsoft Basic Display Driver") {
                    $inventory.GPU += @{
                        Name = $gpu.Name
                        Manufacturer = $gpu.AdapterCompatibility
                        Description = $gpu.Description
                        DriverVersion = $gpu.DriverVersion
                        DriverDate = $gpu.DriverDate
                        VideoModeDescription = $gpu.VideoModeDescription
                        CurrentHorizontalResolution = $gpu.CurrentHorizontalResolution
                        CurrentVerticalResolution = $gpu.CurrentVerticalResolution
                        AdapterRAM = if ($gpu.AdapterRAM) { "$([math]::Round($gpu.AdapterRAM / 1GB, 2)) GB" } else { "N/A" }
                        Status = $gpu.Status
                    }
                }
            }
            Write-SouliTEKResult "GPU information collected ($($inventory.GPU.Count) adapter(s))" -Level SUCCESS
        }

        # RAM Information
        Write-SouliTEKResult "Gathering RAM Information..." -Level INFO
        $memoryModules = Get-CimInstance Win32_PhysicalMemory -ErrorAction SilentlyContinue
        $totalRAM = 0
        if ($memoryModules) {
            foreach ($ram in $memoryModules) {
                $capacityGB = [math]::Round($ram.Capacity / 1GB, 2)
                $totalRAM += $capacityGB
                $inventory.RAM += @{
                    Capacity = "$capacityGB GB"
                    Speed = if ($ram.Speed) { "$($ram.Speed) MHz" } else { "N/A" }
                    Manufacturer = $ram.Manufacturer
                    PartNumber = $ram.PartNumber
                    SerialNumber = $ram.SerialNumber
                    FormFactor = switch ($ram.FormFactor) {
                        8 { "DIMM" }
                        12 { "SODIMM" }
                        default { "Unknown ($($ram.FormFactor))" }
                    }
                    MemoryType = switch ($ram.MemoryType) {
                        20 { "DDR" }
                        21 { "DDR2" }
                        24 { "DDR3" }
                        26 { "DDR4" }
                        34 { "DDR5" }
                        default { "Unknown ($($ram.MemoryType))" }
                    }
                    BankLabel = $ram.BankLabel
                    DeviceLocator = $ram.DeviceLocator
                }
            }
            $inventory.ComputerInfo.TotalRAM = "$totalRAM GB"
            $inventory.ComputerInfo.RAMModules = $memoryModules.Count
            Write-SouliTEKResult "RAM information collected ($($memoryModules.Count) module(s), $totalRAM GB total)" -Level SUCCESS
        }

        # Storage Information
        Write-SouliTEKResult "Gathering Storage Information..." -Level INFO
        $disks = Get-CimInstance Win32_DiskDrive -ErrorAction SilentlyContinue
        if ($disks) {
            foreach ($disk in $disks) {
                $sizeGB = [math]::Round($disk.Size / 1GB, 2)
                $diskInfo = @{
                    Model = $disk.Model
                    Manufacturer = $disk.Manufacturer
                    InterfaceType = $disk.InterfaceType
                    MediaType = $disk.MediaType
                    Size = "$sizeGB GB"
                    SerialNumber = $disk.SerialNumber
                    FirmwareRevision = $disk.FirmwareRevision
                    Partitions = $disk.Partitions
                    Status = $disk.Status
                    PartitionDetails = @()
                }
                
                # Get partition information
                try {
                    $diskPartitions = Get-CimInstance -Query "ASSOCIATORS OF {Win32_DiskDrive.DeviceID='$($disk.DeviceID)'} WHERE AssocClass=Win32_DiskDriveToDiskPartition" -ErrorAction SilentlyContinue
                    foreach ($partition in $diskPartitions) {
                        $logicalDisks = Get-CimInstance -Query "ASSOCIATORS OF {Win32_DiskPartition.DeviceID='$($partition.DeviceID)'} WHERE AssocClass=Win32_LogicalDiskToPartition" -ErrorAction SilentlyContinue
                        foreach ($logicalDisk in $logicalDisks) {
                            $freeSpaceGB = [math]::Round($logicalDisk.FreeSpace / 1GB, 2)
                            $sizeGB = [math]::Round($logicalDisk.Size / 1GB, 2)
                            $usedSpaceGB = [math]::Round(($logicalDisk.Size - $logicalDisk.FreeSpace) / 1GB, 2)
                            $percentFree = [math]::Round(($logicalDisk.FreeSpace / $logicalDisk.Size) * 100, 2)
                            
                            $diskInfo.PartitionDetails += @{
                                DriveLetter = $logicalDisk.DeviceID
                                VolumeName = $logicalDisk.VolumeName
                                FileSystem = $logicalDisk.FileSystem
                                TotalSize = "$sizeGB GB"
                                FreeSpace = "$freeSpaceGB GB"
                                UsedSpace = "$usedSpaceGB GB"
                                PercentFree = "$percentFree%"
                            }
                        }
                    }
                } catch {
                    # Partition info not available
                }
                
                $inventory.Storage += $diskInfo
            }
            Write-SouliTEKResult "Storage information collected ($($disks.Count) device(s))" -Level SUCCESS
        }

        # Motherboard Information
        Write-SouliTEKResult "Gathering Motherboard Information..." -Level INFO
        $motherboard = Get-CimInstance Win32_BaseBoard -ErrorAction SilentlyContinue
        if ($motherboard) {
            $inventory.Motherboard = @{
                Manufacturer = $motherboard.Manufacturer
                Product = $motherboard.Product
                Version = $motherboard.Version
                SerialNumber = $motherboard.SerialNumber
                Tag = $motherboard.Tag
            }
            Write-SouliTEKResult "Motherboard information collected" -Level SUCCESS
        }

        # BIOS Information
        Write-SouliTEKResult "Gathering BIOS Information..." -Level INFO
        $bios = Get-CimInstance Win32_BIOS -ErrorAction SilentlyContinue
        if ($bios) {
            $inventory.BIOS = @{
                Manufacturer = $bios.Manufacturer
                Name = $bios.Name
                Version = $bios.Version
                SerialNumber = $bios.SerialNumber
                ReleaseDate = $bios.ReleaseDate
                SMBIOSBIOSVersion = $bios.SMBIOSBIOSVersion
                SMBIOSMajorVersion = $bios.SMBIOSMajorVersion
                SMBIOSMinorVersion = $bios.SMBIOSMinorVersion
            }
            Write-SouliTEKResult "BIOS information collected" -Level SUCCESS
        }

        # Network Adapters
        Write-SouliTEKResult "Gathering Network Adapter Information..." -Level INFO
        $adapters = Get-CimInstance Win32_NetworkAdapter | Where-Object { $_.PhysicalAdapter -eq $true } -ErrorAction SilentlyContinue
        if ($adapters) {
            foreach ($adapter in $adapters) {
                $inventory.NetworkAdapters += @{
                    Name = $adapter.Name
                    Manufacturer = $adapter.Manufacturer
                    Description = $adapter.Description
                    MACAddress = $adapter.MACAddress
                    Status = $adapter.Status
                    Speed = if ($adapter.Speed) { "$([math]::Round($adapter.Speed / 1MB, 2)) Mbps" } else { "N/A" }
                }
            }
            Write-SouliTEKResult "Network adapter information collected ($($adapters.Count) adapter(s))" -Level SUCCESS
        }

        # Collect Serial Numbers Summary
        Write-SouliTEKResult "Compiling Serial Numbers Summary..." -Level INFO
        $inventory.SerialNumbers = @{
            Computer = if ($computerSystem) { $computerSystem.SerialNumber } else { "N/A" }
            Motherboard = if ($motherboard) { $motherboard.SerialNumber } else { "N/A" }
            BIOS = if ($bios) { $bios.SerialNumber } else { "N/A" }
            CPUs = @()
            RAM = @()
            Storage = @()
        }
        
        foreach ($cpu in $inventory.CPU) {
            if ($cpu.SerialNumber) {
                $inventory.SerialNumbers.CPUs += $cpu.SerialNumber
            } elseif ($cpu.ProcessorId) {
                $inventory.SerialNumbers.CPUs += $cpu.ProcessorId
            }
        }
        
        foreach ($ram in $inventory.RAM) {
            if ($ram.SerialNumber) {
                $inventory.SerialNumbers.RAM += $ram.SerialNumber
            }
        }
        
        foreach ($disk in $inventory.Storage) {
            if ($disk.SerialNumber) {
                $inventory.SerialNumbers.Storage += $disk.SerialNumber
            }
        }
        
        Write-SouliTEKResult "Serial numbers summary compiled" -Level SUCCESS
        
        Write-Host ""
        Write-Host "============================================================" -ForegroundColor Cyan
        Write-Host "  COLLECTION SUMMARY" -ForegroundColor Cyan
        Write-Host "============================================================" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Computer: $($inventory.ComputerInfo.Name)" -ForegroundColor White
        Write-Host "Manufacturer: $($inventory.ComputerInfo.Manufacturer)" -ForegroundColor White
        Write-Host "Model: $($inventory.ComputerInfo.Model)" -ForegroundColor White
        Write-Host ""
        Write-Host "Components Collected:" -ForegroundColor Cyan
        Write-Host "  - CPUs: $($inventory.CPU.Count)" -ForegroundColor White
        Write-Host "  - GPUs: $($inventory.GPU.Count)" -ForegroundColor White
        Write-Host "  - RAM Modules: $($inventory.RAM.Count)" -ForegroundColor White
        Write-Host "  - Storage Devices: $($inventory.Storage.Count)" -ForegroundColor White
        Write-Host "  - Network Adapters: $($inventory.NetworkAdapters.Count)" -ForegroundColor White
        Write-Host ""
        Write-Host "============================================================" -ForegroundColor Cyan
        
        $Script:InventoryData = $inventory
        
        Write-Host ""
        Write-SouliTEKResult "Hardware inventory collection completed successfully!" -Level SUCCESS
        Write-Host ""
        Read-Host "Press Enter to return to main menu"
        
    } catch {
        Write-SouliTEKResult "Error collecting hardware information: $_" -Level ERROR
        Write-Host ""
        Write-Host "Possible reasons:" -ForegroundColor Yellow
        Write-Host "  - Insufficient permissions (run as Administrator)" -ForegroundColor Gray
        Write-Host "  - WMI/CIM services unavailable" -ForegroundColor Gray
        Write-Host "  - System error" -ForegroundColor Gray
        Write-Host ""
        Read-Host "Press Enter to return to main menu"
    }
}

function Show-HardwareSummary {
    Show-Header "HARDWARE INVENTORY SUMMARY" -Color Yellow
    
    if (-not $Script:InventoryData) {
        Write-SouliTEKResult "No inventory data available. Please collect hardware information first." -Level WARNING
        Write-Host ""
        Read-Host "Press Enter to return to main menu"
        return
    }
    
    $inv = $Script:InventoryData
    
    Write-Host "      Displaying comprehensive hardware summary..." -ForegroundColor Gray
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    
    # Computer Info
    Write-Host "COMPUTER INFORMATION:" -ForegroundColor Cyan
    Write-Host "  Name              : $($inv.ComputerInfo.Name)" -ForegroundColor White
    Write-Host "  Manufacturer      : $($inv.ComputerInfo.Manufacturer)" -ForegroundColor White
    Write-Host "  Model             : $($inv.ComputerInfo.Model)" -ForegroundColor White
    Write-Host "  Operating System  : $($inv.ComputerInfo.OperatingSystem)" -ForegroundColor White
    Write-Host "  Total RAM         : $($inv.ComputerInfo.TotalRAM) ($($inv.ComputerInfo.RAMModules) modules)" -ForegroundColor White
    Write-Host ""
    
    # CPU Info
    Write-Host "CPU INFORMATION ($($inv.CPU.Count) processor(s)):" -ForegroundColor Cyan
    foreach ($cpu in $inv.CPU) {
        Write-Host "  Processor: $($cpu.Name)" -ForegroundColor Yellow
        Write-Host "    Cores: $($cpu.NumberOfCores) | Threads: $($cpu.NumberOfLogicalProcessors)" -ForegroundColor White
        Write-Host "    Clock Speed: $($cpu.MaxClockSpeed)" -ForegroundColor White
        Write-Host "    Serial/ID: $(if ($cpu.SerialNumber) { $cpu.SerialNumber } else { $cpu.ProcessorId })" -ForegroundColor Gray
        Write-Host ""
    }
    
    # GPU Info
    Write-Host "GPU INFORMATION ($($inv.GPU.Count) adapter(s)):" -ForegroundColor Cyan
    foreach ($gpu in $inv.GPU) {
        Write-Host "  Adapter: $($gpu.Name)" -ForegroundColor Yellow
        Write-Host "    Manufacturer: $($gpu.Manufacturer)" -ForegroundColor White
        Write-Host "    Driver: $($gpu.DriverVersion)" -ForegroundColor White
        Write-Host "    RAM: $($gpu.AdapterRAM)" -ForegroundColor White
        Write-Host ""
    }
    
    # RAM Info
    Write-Host "RAM MODULES ($($inv.RAM.Count) module(s)):" -ForegroundColor Cyan
    foreach ($ram in $inv.RAM) {
        Write-Host "  Module: $($ram.Capacity) $($ram.MemoryType) $($ram.FormFactor)" -ForegroundColor Yellow
        Write-Host "    Speed: $($ram.Speed) | Manufacturer: $($ram.Manufacturer)" -ForegroundColor White
        Write-Host "    Part Number: $($ram.PartNumber)" -ForegroundColor White
        Write-Host "    Serial: $($ram.SerialNumber)" -ForegroundColor Gray
        Write-Host "    Location: $($ram.DeviceLocator)" -ForegroundColor Gray
        Write-Host ""
    }
    
    # Storage Info
    Write-Host "STORAGE DEVICES ($($inv.Storage.Count) device(s)):" -ForegroundColor Cyan
    foreach ($disk in $inv.Storage) {
        Write-Host "  Drive: $($disk.Model)" -ForegroundColor Yellow
        Write-Host "    Size: $($disk.Size) | Type: $($disk.InterfaceType)" -ForegroundColor White
        Write-Host "    Serial: $($disk.SerialNumber)" -ForegroundColor Gray
        Write-Host ""
    }
    
    # Motherboard
    if ($inv.Motherboard.Product) {
        Write-Host "MOTHERBOARD:" -ForegroundColor Cyan
        Write-Host "  Manufacturer: $($inv.Motherboard.Manufacturer)" -ForegroundColor White
        Write-Host "  Product: $($inv.Motherboard.Product)" -ForegroundColor White
        Write-Host "  Serial: $($inv.Motherboard.SerialNumber)" -ForegroundColor Gray
        Write-Host ""
    }
    
    # BIOS
    if ($inv.BIOS.Name) {
        Write-Host "BIOS:" -ForegroundColor Cyan
        Write-Host "  Manufacturer: $($inv.BIOS.Manufacturer)" -ForegroundColor White
        Write-Host "  Version: $($inv.BIOS.Version)" -ForegroundColor White
        Write-Host "  Serial: $($inv.BIOS.SerialNumber)" -ForegroundColor Gray
        Write-Host ""
    }
    
    # Serial Numbers Summary
    Write-Host "SERIAL NUMBERS SUMMARY:" -ForegroundColor Cyan
    Write-Host "  Computer     : $($inv.SerialNumbers.Computer)" -ForegroundColor White
    Write-Host "  Motherboard  : $($inv.SerialNumbers.Motherboard)" -ForegroundColor White
    Write-Host "  BIOS         : $($inv.SerialNumbers.BIOS)" -ForegroundColor White
    Write-Host "  CPU IDs      : $($inv.SerialNumbers.CPUs.Count)" -ForegroundColor White
    Write-Host "  RAM Serials  : $($inv.SerialNumbers.RAM.Count)" -ForegroundColor White
    Write-Host "  Disk Serials : $($inv.SerialNumbers.Storage.Count)" -ForegroundColor White
    Write-Host ""
    
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Read-Host "Press Enter to return to main menu"
}

function Export-InventoryReport {
    Show-Header "EXPORT HARDWARE INVENTORY" -Color Yellow
    
    if (-not $Script:InventoryData) {
        Write-SouliTEKResult "No inventory data available. Please collect hardware information first." -Level WARNING
        Write-Host ""
        Read-Host "Press Enter to return to main menu"
        return
    }
    
    Write-Host "      Export hardware inventory to file" -ForegroundColor Gray
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "Select export format:" -ForegroundColor White
    Write-Host ""
    Write-Host "  [1] JSON Format (.json) - Complete nested structure" -ForegroundColor Yellow
    Write-Host "  [2] CSV Format (.csv) - Flattened for warranty tracking" -ForegroundColor Yellow
    Write-Host "  [3] Both Formats" -ForegroundColor Cyan
    Write-Host "  [0] Cancel" -ForegroundColor Red
    Write-Host ""
    
    $choice = Read-Host "Enter your choice (0-3)"
    
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $baseFileName = "HardwareInventory_$timestamp"
    
    switch ($choice) {
        "1" {
            Export-JSONReport -Inventory $Script:InventoryData -FileName $baseFileName
        }
        "2" {
            Export-CSVReport -Inventory $Script:InventoryData -FileName $baseFileName
        }
        "3" {
            Export-JSONReport -Inventory $Script:InventoryData -FileName $baseFileName
            Export-CSVReport -Inventory $Script:InventoryData -FileName $baseFileName
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
    
    Write-Host ""
    Read-Host "Press Enter to return to main menu"
}

function Export-JSONReport {
    param($Inventory, $FileName)
    
    $jsonPath = Join-Path $Script:OutputFolder "$FileName.json"
    
    try {
        $jsonContent = $Inventory | ConvertTo-Json -Depth 10
        $jsonContent | Out-File -FilePath $jsonPath -Encoding UTF8
        
        Write-Host ""
        Write-SouliTEKResult "JSON report exported to: $jsonPath" -Level SUCCESS
        Start-Sleep -Seconds 1
        Start-Process notepad.exe -ArgumentList $jsonPath
    } catch {
        Write-SouliTEKResult "Failed to export JSON report: $_" -Level ERROR
    }
}

function Export-CSVReport {
    param($Inventory, $FileName)
    
    $csvPath = Join-Path $Script:OutputFolder "$FileName.csv"
    
    try {
        # Create flattened CSV structure for warranty tracking
        $csvData = @()
        
        # Computer Info
        $csvData += [PSCustomObject]@{
            Category = "Computer"
            Item = "System"
            Manufacturer = $Inventory.ComputerInfo.Manufacturer
            Model = $Inventory.ComputerInfo.Model
            SerialNumber = $Inventory.SerialNumbers.Computer
            Details = "OS: $($Inventory.ComputerInfo.OperatingSystem)"
            Timestamp = $Inventory.Timestamp
        }
        
        # Motherboard
        if ($Inventory.Motherboard.Product) {
            $csvData += [PSCustomObject]@{
                Category = "Motherboard"
                Item = $Inventory.Motherboard.Product
                Manufacturer = $Inventory.Motherboard.Manufacturer
                Model = $Inventory.Motherboard.Version
                SerialNumber = $Inventory.Motherboard.SerialNumber
                Details = ""
                Timestamp = $Inventory.Timestamp
            }
        }
        
        # BIOS
        if ($Inventory.BIOS.Name) {
            $csvData += [PSCustomObject]@{
                Category = "BIOS"
                Item = $Inventory.BIOS.Name
                Manufacturer = $Inventory.BIOS.Manufacturer
                Model = $Inventory.BIOS.Version
                SerialNumber = $Inventory.BIOS.SerialNumber
                Details = "SMBIOS: $($Inventory.BIOS.SMBIOSBIOSVersion)"
                Timestamp = $Inventory.Timestamp
            }
        }
        
        # CPUs
        foreach ($cpu in $Inventory.CPU) {
            $csvData += [PSCustomObject]@{
                Category = "CPU"
                Item = $cpu.Name
                Manufacturer = $cpu.Manufacturer
                Model = "$($cpu.Family) / $($cpu.Model)"
                SerialNumber = if ($cpu.SerialNumber) { $cpu.SerialNumber } else { $cpu.ProcessorId }
                Details = "$($cpu.NumberOfCores) cores, $($cpu.NumberOfLogicalProcessors) threads, $($cpu.MaxClockSpeed)"
                Timestamp = $Inventory.Timestamp
            }
        }
        
        # GPUs
        foreach ($gpu in $Inventory.GPU) {
            $csvData += [PSCustomObject]@{
                Category = "GPU"
                Item = $gpu.Name
                Manufacturer = $gpu.Manufacturer
                Model = $gpu.Description
                SerialNumber = "N/A"
                Details = "$($gpu.VideoModeDescription), Driver: $($gpu.DriverVersion)"
                Timestamp = $Inventory.Timestamp
            }
        }
        
        # RAM Modules
        foreach ($ram in $Inventory.RAM) {
            $csvData += [PSCustomObject]@{
                Category = "RAM"
                Item = "$($ram.Capacity) $($ram.MemoryType)"
                Manufacturer = $ram.Manufacturer
                Model = $ram.PartNumber
                SerialNumber = $ram.SerialNumber
                Details = "$($ram.FormFactor), $($ram.Speed), Location: $($ram.DeviceLocator)"
                Timestamp = $Inventory.Timestamp
            }
        }
        
        # Storage
        foreach ($disk in $Inventory.Storage) {
            $csvData += [PSCustomObject]@{
                Category = "Storage"
                Item = $disk.Model
                Manufacturer = $disk.Manufacturer
                Model = $disk.InterfaceType
                SerialNumber = $disk.SerialNumber
                Details = "$($disk.Size), $($disk.MediaType), Partitions: $($disk.Partitions)"
                Timestamp = $Inventory.Timestamp
            }
        }
        
        # Network Adapters
        foreach ($adapter in $Inventory.NetworkAdapters) {
            $csvData += [PSCustomObject]@{
                Category = "Network"
                Item = $adapter.Name
                Manufacturer = $adapter.Manufacturer
                Model = $adapter.Description
                SerialNumber = $adapter.MACAddress
                Details = "$($adapter.Speed), Status: $($adapter.Status)"
                Timestamp = $Inventory.Timestamp
            }
        }
        
        $csvData | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
        
        Write-Host ""
        Write-SouliTEKResult "CSV report exported to: $csvPath" -Level SUCCESS
        Start-Sleep -Seconds 1
        Start-Process $csvPath
    } catch {
        Write-SouliTEKResult "Failed to export CSV report: $_" -Level ERROR
    }
}

# ============================================================
# MAIN MENU
# ============================================================

function Show-MainMenu {
    Show-Header "HARDWARE INVENTORY REPORT - Professional Tool" -Color Cyan
    
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
    Write-Host "  [1] Collect Hardware Inventory - Gather all hardware info" -ForegroundColor Yellow
    Write-Host "  [2] View Summary            - Display collected data" -ForegroundColor Yellow
    Write-Host "  [3] Export Report - JSON     - Complete nested structure" -ForegroundColor Cyan
    Write-Host "  [4] Export Report - CSV     - Flattened for warranty tracking" -ForegroundColor Cyan
    Write-Host "  [5] Help                    - Usage guide" -ForegroundColor White
    Write-Host "  [0] Exit" -ForegroundColor Red
    Write-Host ""
    Write-Host "========================================" -ForegroundColor DarkGray
    
    $choice = Read-Host "Enter your choice (0-5)"
    return $choice
}

function Show-Help {
    Show-Header "HELP GUIDE" -Color Cyan
    
    Write-Host "HARDWARE INVENTORY REPORT - USAGE GUIDE" -ForegroundColor Yellow
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "[1] COLLECT HARDWARE INVENTORY" -ForegroundColor White
    Write-Host "    Gathers comprehensive hardware information from WMI/CIM" -ForegroundColor Gray
    Write-Host "    Collects: CPU, GPU, RAM, Storage, Motherboard, BIOS, Network" -ForegroundColor Gray
    Write-Host "    Includes: Serial numbers, model numbers, specifications" -ForegroundColor Gray
    Write-Host ""
    Write-Host "[2] VIEW SUMMARY" -ForegroundColor White
    Write-Host "    Displays collected hardware information in readable format" -ForegroundColor Gray
    Write-Host "    Shows: All components with details and serial numbers" -ForegroundColor Gray
    Write-Host "    Use: Quick review of collected data before export" -ForegroundColor Gray
    Write-Host ""
    Write-Host "[3] EXPORT REPORT - JSON" -ForegroundColor White
    Write-Host "    Exports complete nested JSON structure" -ForegroundColor Gray
    Write-Host "    Contains: All hardware details in hierarchical format" -ForegroundColor Gray
    Write-Host "    Use: Programmatic access, data import, full documentation" -ForegroundColor Gray
    Write-Host ""
    Write-Host "[4] EXPORT REPORT - CSV" -ForegroundColor White
    Write-Host "    Exports flattened CSV format optimized for warranty tracking" -ForegroundColor Gray
    Write-Host "    Columns: Category, Item, Manufacturer, Model, SerialNumber, Details" -ForegroundColor Gray
    Write-Host "    Use: Spreadsheet analysis, warranty registration, inventory management" -ForegroundColor Gray
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "HARDWARE INFORMATION COLLECTED:" -ForegroundColor Yellow
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "CPU:" -ForegroundColor White
    Write-Host "  - Name, manufacturer, cores, threads, clock speeds" -ForegroundColor Gray
    Write-Host "  - Cache sizes, processor ID, serial numbers" -ForegroundColor Gray
    Write-Host ""
    Write-Host "GPU:" -ForegroundColor White
    Write-Host "  - Name, manufacturer, driver version and date" -ForegroundColor Gray
    Write-Host "  - Resolution, adapter RAM, status" -ForegroundColor Gray
    Write-Host ""
    Write-Host "RAM:" -ForegroundColor White
    Write-Host "  - Capacity, speed, manufacturer, part numbers" -ForegroundColor Gray
    Write-Host "  - Serial numbers, form factor, memory type (DDR3/DDR4/DDR5)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Storage:" -ForegroundColor White
    Write-Host "  - Model, manufacturer, interface type, size" -ForegroundColor Gray
    Write-Host "  - Serial numbers, firmware, partition details" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Motherboard:" -ForegroundColor White
    Write-Host "  - Manufacturer, product, version, serial number" -ForegroundColor Gray
    Write-Host ""
    Write-Host "BIOS:" -ForegroundColor White
    Write-Host "  - Manufacturer, version, serial number, release date" -ForegroundColor Gray
    Write-Host "  - SMBIOS version information" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Network Adapters:" -ForegroundColor White
    Write-Host "  - Name, manufacturer, MAC address, speed, status" -ForegroundColor Gray
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "USE CASES:" -ForegroundColor Yellow
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Warranty Tracking:" -ForegroundColor White
    Write-Host "  Use CSV export to register hardware with manufacturers" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Asset Management:" -ForegroundColor White
    Write-Host "  Import JSON into asset tracking systems" -ForegroundColor Gray
    Write-Host ""
    Write-Host "IT Procurement:" -ForegroundColor White
    Write-Host "  Use serial numbers and specifications for planning" -ForegroundColor Gray
    Write-Host ""
    Write-Host "System Documentation:" -ForegroundColor White
    Write-Host "  Export reports for compliance and audit requirements" -ForegroundColor Gray
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "REQUIREMENTS:" -ForegroundColor Yellow
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "- Windows PowerShell 5.1 or later" -ForegroundColor Gray
    Write-Host "- Administrator privileges recommended for complete data" -ForegroundColor Gray
    Write-Host "- WMI/CIM services must be running" -ForegroundColor Gray
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Read-Host "Press Enter to return to main menu"
}

function Show-ExitMessage {
    Clear-Host
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "            Thank you for using" -ForegroundColor White
    Write-Host "        HARDWARE INVENTORY REPORT" -ForegroundColor Cyan
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
    Write-Host "   Need IT hardware inventory solutions?" -ForegroundColor White
    Write-Host "   Contact Soulitek for professional services." -ForegroundColor White
    Write-Host ""
    Write-Host "   Remember: Export reports for warranty tracking!" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Start-Sleep -Seconds 4
}

# ============================================================
# MAIN EXECUTION
# ============================================================

# Main menu loop
do {
    $choice = Show-MainMenu
    
    switch ($choice) {
        "1" { Get-HardwareInventory }
        "2" { Show-HardwareSummary }
        "3" { 
            if (-not $Script:InventoryData) {
                Write-Host ""
                Write-SouliTEKResult "No inventory data available. Collecting hardware information first..." -Level WARNING
                Get-HardwareInventory
            }
            Export-JSONReport -Inventory $Script:InventoryData -FileName "HardwareInventory_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
            Write-Host ""
            Read-Host "Press Enter to return to main menu"
        }
        "4" { 
            if (-not $Script:InventoryData) {
                Write-Host ""
                Write-SouliTEKResult "No inventory data available. Collecting hardware information first..." -Level WARNING
                Get-HardwareInventory
            }
            Export-CSVReport -Inventory $Script:InventoryData -FileName "HardwareInventory_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
            Write-Host ""
            Read-Host "Press Enter to return to main menu"
        }
        "5" { Show-Help }
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
