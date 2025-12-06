<#
.SYNOPSIS
    SouliTEK Softwares Installer
.DESCRIPTION
    Interactive TUI menu to select and install applications via WinGet.
    Auto-installs WinGet if missing. Installs essential business applications.
.PARAMETER Preset
    Path to JSON preset file containing package IDs to install
.EXAMPLE
    .\SouliTEK-Softwares-Installer.ps1
    Opens interactive menu
.EXAMPLE
    .\SouliTEK-Softwares-Installer.ps1 -Preset .\my-preset.json
    Installs packages from preset file
.NOTES
    Author: SouliTEK
    Requires: Windows PowerShell 5.1+, Admin rights, Windows 10 1709+ or WinGet module
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$Preset
)

# ============================================================================
# GLOBAL CONFIGURATION
# ============================================================================

# Import SouliTEK Common Functions
$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$CommonPath = Join-Path (Split-Path -Parent $ScriptRoot) "modules\SouliTEK-Common.ps1"
if (Test-Path $CommonPath) {
    . $CommonPath
}

$Script:SummaryPath = "$env:USERPROFILE\Desktop\SouliTEK-Softwares-Installer-Result.json"
$Script:PresetFolder = "$env:USERPROFILE\Desktop"
$Script:RebootRequired = $false
$Script:InstallResults = @()
$Script:WinGetVersion = ""

# Package Catalog - Business Essential Applications
$Script:PackageCatalog = @(
    @{ Id = "NAPS2.NAPS2"; Name = "NAPS2"; Category = "Utilities"; Notes = "Document scanning application" }
    @{ Id = "9WZDNCRFHWLH"; Name = "HP Smart"; Category = "Utilities"; Notes = "HP printer management and scanning" }
    @{ Id = "Adobe.Acrobat.Reader.64-bit"; Name = "Adobe Reader"; Category = "Utilities"; Notes = "PDF reader by Adobe" }
    @{ Id = "Fortinet.FortiClientVPN"; Name = "Forticlient VPN"; Category = "Security"; Notes = "Enterprise VPN client" }
    @{ Id = "Dropbox.Dropbox"; Name = "Dropbox"; Category = "Productivity"; Notes = "Cloud storage and file sync" }
    @{ Id = "Zoom.Zoom"; Name = "Zoom"; Category = "Communications"; Notes = "Video conferencing platform" }
    @{ Id = "OFFICE2024"; Name = "Microsoft Office 2024"; Category = "Productivity"; Notes = "Office suite (ProPlus Hebrew)" }
    @{ Id = "Discord.Discord"; Name = "Discord"; Category = "Communications"; Notes = "Voice, video, and text chat" }
    @{ Id = "Google.Chrome"; Name = "Google Chrome"; Category = "Browsers"; Notes = "Fast, secure browser by Google" }
    @{ Id = "Google.Drive"; Name = "Google Drive"; Category = "Productivity"; Notes = "Cloud storage and file sync by Google" }
    @{ Id = "AnyDeskSoftwareGmbH.AnyDesk"; Name = "AnyDesk"; Category = "Remote Access"; Notes = "Fast remote desktop software" }
    @{ Id = "RARLab.WinRAR"; Name = "WinRAR"; Category = "Utilities"; Notes = "File compression and archiving tool" }
    @{ Id = "WhatsApp.WhatsApp"; Name = "WhatsApp"; Category = "Communications"; Notes = "Messaging and voice/video calls" }
    @{ Id = "qBittorrent.qBittorrent"; Name = "qBittorrent"; Category = "Utilities"; Notes = "Open-source BitTorrent client" }
    @{ Id = "Telegram.TelegramDesktop"; Name = "Telegram"; Category = "Communications"; Notes = "Secure messaging platform" }
    @{ Id = "ESETCONNECTOR"; Name = "ESET Connector"; Category = "Security"; Notes = "ESET Endpoint Security connector agent" }
)

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

function Write-Banner {
    Write-Host ""
    Write-Host "  =========================================================" -ForegroundColor Cyan
    Write-Host "   _____ ____  _    _ _      _____ _______ ______ _  __" -ForegroundColor Cyan
    Write-Host "  / ____/ __ \| |  | | |    |_   _|__   __|  ____| |/ /" -ForegroundColor Cyan
    Write-Host " | (___| |  | | |  | | |      | |    | |  | |__  | ' /" -ForegroundColor Cyan
    Write-Host "  \___ \ |  | | |  | | |      | |    | |  |  __| |  <" -ForegroundColor Cyan
    Write-Host "  ____) | |__| | |__| | |____ _| |_   | |  | |____| . \" -ForegroundColor Cyan
    Write-Host " |_____/ \____/ \____/|______|_____|  |_|  |______|_|\_\" -ForegroundColor Cyan
    Write-Host "  =========================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Softwares Installer" -ForegroundColor White
    Write-Host "  =========================================================" -ForegroundColor DarkGray
    Write-Host ""
}

function Ensure-Admin {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    $isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    
    if (-not $isAdmin) {
        Write-Host "[!] Administrator privileges required" -ForegroundColor Yellow
        Write-Host "[*] Relaunching with elevation..." -ForegroundColor Cyan
        
        $argList = @()
        $argList += "-NoProfile"
        $argList += "-ExecutionPolicy Bypass"
        $argList += "-File `"$PSCommandPath`""
        
        if ($Preset) { $argList += "-Preset `"$Preset`"" }
        
        Start-Process powershell.exe -ArgumentList $argList -Verb RunAs
        exit
    }
}

function Set-ExecutionPolicyIfNeeded {
    try {
        $currentPolicy = Get-ExecutionPolicy -Scope Process
        if ($currentPolicy -eq 'Restricted' -or $currentPolicy -eq 'AllSigned') {
            Write-Host "[*] Setting execution policy for process scope..." -ForegroundColor Cyan
            Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Host "[!] Warning: Could not set execution policy: $_" -ForegroundColor Yellow
    }
}

function Ensure-WinGet {
    Write-Host "[*] Checking WinGet installation..." -ForegroundColor Cyan
    
    $wingetCmd = Get-Command winget.exe -ErrorAction SilentlyContinue
    if ($wingetCmd) {
        try {
            $versionOutput = winget --version 2>$null
            $Script:WinGetVersion = $versionOutput -replace '[^0-9.]', ''
            Write-Host "[+] WinGet $Script:WinGetVersion found" -ForegroundColor Green
            return $true
        }
        catch {
            Write-Host "[!] WinGet found but version check failed" -ForegroundColor Yellow
            $Script:WinGetVersion = "Unknown"
            return $true
        }
    }
    
    Write-Host "[!] WinGet not found. Installing..." -ForegroundColor Yellow
    Write-Host "[*] Attempting to install Microsoft.WinGet.Client module..." -ForegroundColor Cyan
    
    try {
        # Check if NuGet provider is installed
        $nuget = Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue
        if (-not $nuget) {
            Write-Host "[*] Installing NuGet provider..." -ForegroundColor Cyan
            Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope CurrentUser | Out-Null
        }
        
        # Set PSGallery as trusted temporarily
        $psGallery = Get-PSRepository -Name PSGallery -ErrorAction SilentlyContinue
        if ($psGallery -and $psGallery.InstallationPolicy -ne 'Trusted') {
            Write-Host "[*] Setting PSGallery as trusted..." -ForegroundColor Cyan
            Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
        }
        
        # Install WinGet module
        Write-Host "[*] Installing Microsoft.WinGet.Client module..." -ForegroundColor Cyan
        Install-Module -Name Microsoft.WinGet.Client -Force -Scope CurrentUser -ErrorAction Stop
        
        # Import the module
        Import-Module -Name Microsoft.WinGet.Client -Force -ErrorAction Stop
        
        # Refresh PATH
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
        
        # Check again
        $wingetCmd = Get-Command winget.exe -ErrorAction SilentlyContinue
        if ($wingetCmd) {
            $versionOutput = winget --version 2>$null
            $Script:WinGetVersion = $versionOutput -replace '[^0-9.]', ''
            Write-Host "[+] WinGet $Script:WinGetVersion installed successfully" -ForegroundColor Green
            return $true
        }
        else {
            Write-Host "[X] WinGet installation failed. Please install manually." -ForegroundColor Red
            Write-Host "    Visit: https://apps.microsoft.com/detail/9NBLGGH4NNS1" -ForegroundColor Yellow
            Write-Host "    Or use: winget install Microsoft.AppInstaller" -ForegroundColor Yellow
            return $false
        }
    }
    catch {
        Write-Host "[X] Error installing WinGet: $_" -ForegroundColor Red
        Write-Host "    Please install App Installer from Microsoft Store" -ForegroundColor Yellow
        Write-Host "    Visit: https://apps.microsoft.com/detail/9NBLGGH4NNS1" -ForegroundColor Yellow
        return $false
    }
}

function Show-Menu {
    param(
        [array]$Packages,
        [hashtable]$Selected,
        [int]$CursorPosition
    )
    
    Clear-Host
    Write-Banner
    
    if ($Script:WinGetVersion) {
        Write-Host "  WinGet Version: " -NoNewline -ForegroundColor Gray
        Write-Host $Script:WinGetVersion -ForegroundColor Green
        Write-Host ""
    }
    
    $selectedCount = ($Selected.Keys | Where-Object { $Selected[$_] }).Count
    $totalCount = $Packages.Count
    
    Write-Host "  Selected: " -NoNewline -ForegroundColor Gray
    Write-Host "$selectedCount" -NoNewline -ForegroundColor Cyan
    Write-Host " / $totalCount" -ForegroundColor Gray
    
    Write-Host ""
    Write-Host "  ============================================================================" -ForegroundColor DarkGray
    Write-Host ""
    
    # Grid layout: 2 columns
    $columns = 2
    $columnWidth = 36
    
    # Display all packages in grid (no pagination needed for 7 apps)
    $totalRows = [Math]::Ceiling($Packages.Count / $columns)
    
    for ($row = 0; $row -lt $totalRows; $row++) {
        for ($col = 0; $col -lt $columns; $col++) {
            $idx = ($row * $columns) + $col
            
            if ($idx -lt $Packages.Count) {
                $pkg = $Packages[$idx]
                $isSelected = $Selected[$pkg.Id]
                $isCursor = ($idx -eq $CursorPosition)
                
                $prefix = "  "
                if ($isCursor) { $prefix = "> " }
                
                $checkbox = "[ ]"
                if ($isSelected) { $checkbox = "[X]" }
                
                # Truncate name if too long
                $displayName = $pkg.Name
                if ($displayName.Length -gt 28) {
                    $displayName = $displayName.Substring(0, 25) + "..."
                }
                
                $item = "$prefix$checkbox $displayName"
                $item = $item.PadRight($columnWidth)
                
                if ($isCursor) {
                    Write-Host $item -NoNewline -ForegroundColor Yellow -BackgroundColor DarkGray
                }
                else {
                    if ($isSelected) {
                        Write-Host $item -NoNewline -ForegroundColor Green
                    }
                    else {
                        Write-Host $item -NoNewline -ForegroundColor White
                    }
                }
            }
            else {
                # Empty space for incomplete rows
                Write-Host (" " * $columnWidth) -NoNewline
            }
        }
        Write-Host ""
    }
    
    if ($Packages.Count -eq 0) {
        Write-Host "  No applications available." -ForegroundColor Red
    }
    
    Write-Host ""
    Write-Host "  ============================================================================" -ForegroundColor DarkGray
    Write-Host ""
    
    # Package details
    if ($CursorPosition -ge 0 -and $CursorPosition -lt $Packages.Count) {
        $currentPkg = $Packages[$CursorPosition]
        Write-Host "  Package: " -NoNewline -ForegroundColor Gray
        Write-Host $currentPkg.Name -ForegroundColor Cyan
        Write-Host "  ID: " -NoNewline -ForegroundColor Gray
        Write-Host $currentPkg.Id -ForegroundColor White
        Write-Host "  Category: " -NoNewline -ForegroundColor Gray
        Write-Host $currentPkg.Category -ForegroundColor Magenta
        Write-Host "  Notes: " -NoNewline -ForegroundColor Gray
        Write-Host $currentPkg.Notes -ForegroundColor Gray
        Write-Host ""
    }
    
    Write-Host "  Controls:" -ForegroundColor DarkCyan
    Write-Host "    [Arrows] Navigate  [Space] Toggle  [A] Select All  [N] Select None" -ForegroundColor Gray
    Write-Host "    [I] Install  [Q] Quit" -ForegroundColor Gray
    Write-Host ""
}

function Show-InteractiveMenu {
    $cursorPosition = 0
    $selected = @{}
    
    foreach ($pkg in $Script:PackageCatalog) {
        $selected[$pkg.Id] = $false
    }
    
    $packages = $Script:PackageCatalog
    
    while ($true) {
        Show-Menu -Packages $packages -Selected $selected -CursorPosition $cursorPosition
        
        $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        
        switch ($key.VirtualKeyCode) {
            38 { # Up
                $columns = 2
                if ($cursorPosition -ge $columns) { 
                    $cursorPosition -= $columns 
                }
            }
            40 { # Down
                $columns = 2
                if ($cursorPosition + $columns -lt $packages.Count) { 
                    $cursorPosition += $columns 
                }
            }
            37 { # Left
                if ($cursorPosition -gt 0) { 
                    $cursorPosition-- 
                }
            }
            39 { # Right
                if ($cursorPosition -lt ($packages.Count - 1)) { 
                    $cursorPosition++ 
                }
            }
            32 { # Space
                if ($packages.Count -gt 0) {
                    $pkgId = $packages[$cursorPosition].Id
                    $selected[$pkgId] = -not $selected[$pkgId]
                }
            }
            65 { # A - Select All
                foreach ($pkg in $packages) {
                    $selected[$pkg.Id] = $true
                }
            }
            78 { # N - Select None
                foreach ($pkg in $packages) {
                    $selected[$pkg.Id] = $false
                }
            }
            73 { # I - Install
                $selectedIds = $selected.Keys | Where-Object { $selected[$_] }
                if ($selectedIds.Count -eq 0) {
                    Show-Menu -Packages $packages -Selected $selected -CursorPosition $cursorPosition
                    Write-Host "  [!] No packages selected" -ForegroundColor Red
                    Start-Sleep -Seconds 2
                }
                else {
                    return $selectedIds
                }
            }
            81 { # Q - Quit
                return $null
            }
        }
    }
}

function Load-Preset {
    param(
        [string]$PresetPath
    )
    
    try {
        if (-not (Test-Path $PresetPath)) {
            Write-Host "[X] Preset file not found: $PresetPath" -ForegroundColor Red
            Start-Sleep -Seconds 2
            return $null
        }
        
        $content = Get-Content -Path $PresetPath -Raw -Encoding UTF8
        $packageIds = $content | ConvertFrom-Json
        
        Write-Host "[+] Loaded preset from: $PresetPath" -ForegroundColor Green
        Write-Host "[*] Packages: $($packageIds -join ', ')" -ForegroundColor Cyan
        return $packageIds
    }
    catch {
        Write-Host "[X] Error loading preset: $_" -ForegroundColor Red
        Start-Sleep -Seconds 2
        return $null
    }
}

function Test-PackageInstalled {
    param(
        [string]$PackageId
    )
    
    try {
        # Special case for Office
        if ($PackageId -eq "OFFICE2024") {
            # Check if Office is installed by looking for common Office apps
            $officeApps = @(
                "C:\Program Files\Microsoft Office\root\Office16\WINWORD.EXE",
                "C:\Program Files (x86)\Microsoft Office\root\Office16\WINWORD.EXE"
            )
            foreach ($app in $officeApps) {
                if (Test-Path $app) {
                    return $true
                }
            }
            return $false
        }
        
        # Special case for ESET Connector
        if ($PackageId -eq "ESETCONNECTOR") {
            # Check if ESET Connector is installed by looking for ESET service or registry
            $esetPaths = @(
                "C:\Program Files\ESET\ESET Endpoint Security",
                "C:\Program Files (x86)\ESET\ESET Endpoint Security",
                "HKLM:\SOFTWARE\ESET"
            )
            foreach ($path in $esetPaths) {
                if (Test-Path $path) {
                    return $true
                }
            }
            # Also check for ESET service
            $esetService = Get-Service -Name "ekrn" -ErrorAction SilentlyContinue
            if ($esetService) {
                return $true
            }
            return $false
        }
        
        # For WinGet packages
        $result = winget list --id $PackageId --exact 2>$null
        if ($LASTEXITCODE -eq 0 -and $result) {
            return $true
        }
        return $false
    }
    catch {
        return $false
    }
}

function Install-Office2024 {
    Write-Host "             [0%] Starting Office 2024 download..." -ForegroundColor Cyan
    
    try {
        $officeUrl = "https://c2rsetup.officeapps.live.com/c2r/download.aspx?ProductreleaseID=ProPlus2024Retail&platform=x64&language=he-il&version=O16GA"
        $installerPath = Join-Path $env:TEMP "OfficeSetup.exe"
        
        # Download Office installer
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Write-Host "             [10%] Connecting to download server..." -ForegroundColor Cyan
        
        $webClient = New-Object System.Net.WebClient
        $webClient.DownloadFile($officeUrl, $installerPath)
        
        Write-Host "             [30%] Download complete" -ForegroundColor Cyan
        
        if (Test-Path $installerPath) {
            Write-Host "             [40%] Preparing installation..." -ForegroundColor Cyan
            Write-Host "             [50%] Installing Office 2024 (this may take 10-15 minutes)..." -ForegroundColor Cyan
            
            # Run the installer
            $process = Start-Process -FilePath $installerPath -ArgumentList "/configure" -Wait -PassThru -NoNewWindow
            
            Write-Host "             [90%] Cleaning up..." -ForegroundColor Cyan
            # Clean up
            Remove-Item -Path $installerPath -Force -ErrorAction SilentlyContinue
            
            Write-Host "             [100%] Installation process complete" -ForegroundColor Cyan
            
            if ($process.ExitCode -eq 0 -or $process.ExitCode -eq 3010) {
                Write-Host "             [OK] Office 2024 installed successfully" -ForegroundColor Green
                if ($process.ExitCode -eq 3010) {
                    $Script:RebootRequired = $true
                    Write-Host "             [!] Reboot required" -ForegroundColor Yellow
                }
                return @{
                    Success = $true
                    ExitCode = $process.ExitCode
                    Message = if ($process.ExitCode -eq 3010) { "Success - Reboot Required" } else { "Success" }
                }
            }
            else {
                Write-Host "             [FAIL] Office installation failed (Exit: $($process.ExitCode))" -ForegroundColor Red
                return @{
                    Success = $false
                    ExitCode = $process.ExitCode
                    Message = "Exit code: $($process.ExitCode)"
                }
            }
        }
        else {
            Write-Host "             [FAIL] Failed to download Office installer" -ForegroundColor Red
            return @{
                Success = $false
                ExitCode = -1
                Message = "Download failed"
            }
        }
    }
    catch {
        Write-Host "             [ERROR] $_" -ForegroundColor Red
        return @{
            Success = $false
            ExitCode = -1
            Message = $_.Exception.Message
        }
    }
}

function Install-ESETConnector {
    Write-Host "             [0%] Starting ESET Connector download..." -ForegroundColor Cyan
    
    try {
        $esetUrl = "https://download.eset.com/com/eset/apps/business/eei/agent/latest/ei_connector_nt64.msi"
        $installerPath = Join-Path $env:TEMP "ei_connector_nt64.msi"
        
        # Download ESET Connector MSI
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Write-Host "             [10%] Connecting to download server..." -ForegroundColor Cyan
        
        $webClient = New-Object System.Net.WebClient
        $webClient.DownloadFile($esetUrl, $installerPath)
        
        Write-Host "             [30%] Download complete" -ForegroundColor Cyan
        
        if (Test-Path $installerPath) {
            Write-Host "             [40%] Preparing installation..." -ForegroundColor Cyan
            Write-Host "             [50%] Installing ESET Connector (this may take a few minutes)..." -ForegroundColor Cyan
            
            # Run the MSI installer silently
            $process = Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$installerPath`" /qn /norestart" -Wait -PassThru -NoNewWindow
            
            Write-Host "             [90%] Cleaning up..." -ForegroundColor Cyan
            # Clean up
            Remove-Item -Path $installerPath -Force -ErrorAction SilentlyContinue
            
            Write-Host "             [100%] Installation process complete" -ForegroundColor Cyan
            
            if ($process.ExitCode -eq 0 -or $process.ExitCode -eq 3010) {
                Write-Host "             [OK] ESET Connector installed successfully" -ForegroundColor Green
                if ($process.ExitCode -eq 3010) {
                    $Script:RebootRequired = $true
                    Write-Host "             [!] Reboot required" -ForegroundColor Yellow
                }
                return @{
                    Success = $true
                    ExitCode = $process.ExitCode
                    Message = if ($process.ExitCode -eq 3010) { "Success - Reboot Required" } else { "Success" }
                }
            }
            else {
                Write-Host "             [FAIL] ESET Connector installation failed (Exit: $($process.ExitCode))" -ForegroundColor Red
                return @{
                    Success = $false
                    ExitCode = $process.ExitCode
                    Message = "Exit code: $($process.ExitCode)"
                }
            }
        }
        else {
            Write-Host "             [FAIL] Failed to download ESET Connector installer" -ForegroundColor Red
            return @{
                Success = $false
                ExitCode = -1
                Message = "Download failed"
            }
        }
    }
    catch {
        Write-Host "             [ERROR] $_" -ForegroundColor Red
        return @{
            Success = $false
            ExitCode = -1
            Message = $_.Exception.Message
        }
    }
}

function Install-Packages {
    param(
        [array]$PackageIds
    )
    
    Write-Host ""
    Write-Host "=============================================" -ForegroundColor DarkCyan
    Write-Host "Starting Package Installation" -ForegroundColor Cyan
    Write-Host "=============================================" -ForegroundColor DarkCyan
    Write-Host ""
    
    $totalPackages = $PackageIds.Count
    $currentPackage = 0
    
    foreach ($pkgId in $PackageIds) {
        $currentPackage++
        $pkg = $Script:PackageCatalog | Where-Object { $_.Id -eq $pkgId } | Select-Object -First 1
        $pkgName = if ($pkg) { $pkg.Name } else { $pkgId }
        
        Write-Host "[$currentPackage/$totalPackages] " -NoNewline -ForegroundColor Cyan
        Write-Host "Processing: " -NoNewline -ForegroundColor White
        Write-Host $pkgName -ForegroundColor Yellow
        Write-Host "             ID: $pkgId" -ForegroundColor Gray
        
        $startTime = Get-Date
        $status = "Unknown"
        $message = ""
        
        try {
            $isInstalled = Test-PackageInstalled -PackageId $pkgId
            
            if ($isInstalled) {
                Write-Host "             [SKIP] Already installed" -ForegroundColor Yellow
                $status = "Skipped"
                $message = "Already installed"
            }
            else {
                Write-Host "             [*] Installing..." -ForegroundColor Cyan
                
                # Special handling for Office 2024
                if ($pkgId -eq "OFFICE2024") {
                    $result = Install-Office2024
                    
                    if ($result.Success) {
                        $status = "Installed"
                        $message = $result.Message
                    }
                    else {
                        $status = "Failed"
                        $message = $result.Message
                    }
                }
                # Special handling for ESET Connector
                elseif ($pkgId -eq "ESETCONNECTOR") {
                    $result = Install-ESETConnector
                    
                    if ($result.Success) {
                        $status = "Installed"
                        $message = $result.Message
                    }
                    else {
                        $status = "Failed"
                        $message = $result.Message
                    }
                }
                else {
                    # Standard WinGet installation with silent mode and timeout handling
                    Write-Host "             [0%] Starting installation..." -ForegroundColor Cyan
                    
                    # WinGet arguments with silent mode to prevent hanging on prompts
                    $wingetArgs = @(
                        "install",
                        "-e",
                        "--id", $pkgId,
                        "--accept-package-agreements",
                        "--accept-source-agreements",
                        "--silent"
                    )
                    
                    $logFile = "$env:TEMP\winget_$pkgId.log"
                    $errFile = "$env:TEMP\winget_$pkgId.err"
                    
                    # Clean up any existing log files
                    if (Test-Path $logFile) { Remove-Item $logFile -Force -ErrorAction SilentlyContinue }
                    if (Test-Path $errFile) { Remove-Item $errFile -Force -ErrorAction SilentlyContinue }
                    
                    Write-Host "             [10%] Preparing installation..." -ForegroundColor Cyan
                    Write-Host "             [20%] Starting WinGet process..." -ForegroundColor Cyan
                    
                    # Start process with file redirection for reliable output capture
                    $proc = Start-Process -FilePath "winget" -ArgumentList $wingetArgs -NoNewWindow -PassThru -RedirectStandardOutput $logFile -RedirectStandardError $errFile
                    
                    # Set timeout (30 minutes max per package)
                    $timeout = 1800
                    $timer = [Diagnostics.Stopwatch]::StartNew()
                    $timedOut = $false
                    
                    Write-Host "             [30%] Installing package (this may take several minutes)..." -ForegroundColor Cyan
                    
                    # Wait for process with timeout check
                    $lastProgressTime = 0
                    while (-not $proc.HasExited) {
                        if ($timer.Elapsed.TotalSeconds -gt $timeout) {
                            Write-Host "             [!] Installation timeout exceeded (30 minutes)" -ForegroundColor Yellow
                            try {
                                if (-not $proc.HasExited) {
                                    $proc.Kill()
                                    $timedOut = $true
                                }
                            }
                            catch {
                                Write-Host "             [!] Could not terminate process" -ForegroundColor Yellow
                            }
                            break
                        }
                        Start-Sleep -Seconds 2
                        
                        # Update progress every 30 seconds
                        $elapsedSeconds = [int]$timer.Elapsed.TotalSeconds
                        if ($elapsedSeconds -gt $lastProgressTime + 30) {
                            $lastProgressTime = $elapsedSeconds
                            $progressPercent = [Math]::Min(90, 30 + [int]($elapsedSeconds / $timeout * 60))
                            Write-Host "             [$progressPercent%] Still installing... ($elapsedSeconds seconds elapsed)" -ForegroundColor Cyan
                        }
                    }
                    
                    $timer.Stop()
                    
                    # Wait for process to fully exit
                    if (-not $proc.HasExited) {
                        $proc.WaitForExit(5000)
                    }
                    
                    # Read log files
                    $stdOut = ""
                    $stdErr = ""
                    try {
                        if (Test-Path $logFile) {
                            $stdOut = Get-Content -Path $logFile -Raw -ErrorAction SilentlyContinue
                        }
                        if (Test-Path $errFile) {
                            $stdErr = Get-Content -Path $errFile -Raw -ErrorAction SilentlyContinue
                        }
                    }
                    catch {
                        # Ignore errors reading files
                    }
                    
                    if ($timedOut) {
                        Write-Host "             [FAIL] Installation timed out after 30 minutes" -ForegroundColor Red
                        $status = "Failed"
                        $message = "Timeout after 30 minutes"
                    }
                    else {
                        Write-Host "             [95%] Finalizing..." -ForegroundColor Cyan
                        
                        $exitCode = $proc.ExitCode
                        
                        # Check exit code
                        if ($exitCode -eq 0) {
                            Write-Host "             [100%] Installation complete" -ForegroundColor Green
                            Write-Host "             [OK] Installed successfully" -ForegroundColor Green
                            $status = "Installed"
                            $message = "Success"
                        }
                        elseif ($exitCode -eq 3010) {
                            Write-Host "             [100%] Installation complete" -ForegroundColor Green
                            Write-Host "             [OK] Installed (reboot required)" -ForegroundColor Green
                            $status = "Installed"
                            $message = "Success - Reboot Required"
                            $Script:RebootRequired = $true
                        }
                        elseif ($exitCode -eq -1978335189 -or $stdOut -like "*already installed*" -or $stdErr -like "*already installed*") {
                            Write-Host "             [SKIP] Already installed" -ForegroundColor Yellow
                            $status = "Skipped"
                            $message = "Already installed"
                        }
                        else {
                            Write-Host "             [FAIL] Installation failed (Exit: $exitCode)" -ForegroundColor Red
                            if ($stdErr) {
                                $errorLines = ($stdErr -split "`n" | Where-Object { $_.Trim() -ne "" }) | Select-Object -First 3
                                foreach ($errorLine in $errorLines) {
                                    if ($errorLine.Trim()) {
                                        Write-Host "             Error: $($errorLine.Trim())" -ForegroundColor DarkRed
                                    }
                                }
                            }
                            $status = "Failed"
                            $message = "Exit code: $exitCode"
                        }
                    }
                    
                    # Dispose of process
                    try {
                        if ($proc) {
                            $proc.Dispose()
                        }
                    }
                    catch {
                        # Ignore disposal errors
                    }
                    
                    # Clean up log files after a delay (keep for debugging if failed)
                    if ($status -eq "Installed" -or $status -eq "Skipped") {
                        Start-Sleep -Seconds 1
                        if (Test-Path $logFile) { Remove-Item $logFile -Force -ErrorAction SilentlyContinue }
                        if (Test-Path $errFile) { Remove-Item $errFile -Force -ErrorAction SilentlyContinue }
                    }
                }
            }
        }
        catch {
            Write-Host "             [ERROR] $_" -ForegroundColor Red
            $status = "Error"
            $message = $_.Exception.Message
        }
        
        $elapsed = ((Get-Date) - $startTime).TotalSeconds
        
        $Script:InstallResults += @{
            Id = $pkgId
            Name = $pkgName
            Status = $status
            Message = $message
            Elapsed = [math]::Round($elapsed, 2)
        }
        
        Write-Host ""
    }
}

function Write-Summary {
    Write-Host ""
    Write-Host "=============================================" -ForegroundColor DarkCyan
    Write-Host "Installation Summary" -ForegroundColor Cyan
    Write-Host "=============================================" -ForegroundColor DarkCyan
    Write-Host ""
    
    $installed = ($Script:InstallResults | Where-Object { $_.Status -eq "Installed" }).Count
    $skipped = ($Script:InstallResults | Where-Object { $_.Status -eq "Skipped" }).Count
    $failed = ($Script:InstallResults | Where-Object { $_.Status -eq "Failed" -or $_.Status -eq "Error" }).Count
    
    Write-Host "  Total Packages: " -NoNewline -ForegroundColor Gray
    Write-Host $Script:InstallResults.Count -ForegroundColor White
    Write-Host "  Installed: " -NoNewline -ForegroundColor Gray
    Write-Host $installed -ForegroundColor Green
    Write-Host "  Skipped: " -NoNewline -ForegroundColor Gray
    Write-Host $skipped -ForegroundColor Yellow
    Write-Host "  Failed: " -NoNewline -ForegroundColor Gray
    Write-Host $failed -ForegroundColor Red
    Write-Host ""
    
    Write-Host "  Detailed Results:" -ForegroundColor Gray
    Write-Host "  " + ("-" * 75) -ForegroundColor DarkGray
    Write-Host ("  {0,-30} {1,-15} {2,-10} {3}" -f "Package", "Status", "Elapsed", "Message") -ForegroundColor DarkCyan
    Write-Host "  " + ("-" * 75) -ForegroundColor DarkGray
    
    foreach ($result in $Script:InstallResults) {
        $color = "White"
        switch ($result.Status) {
            "Installed" { $color = "Green" }
            "Skipped" { $color = "Yellow" }
            "Failed" { $color = "Red" }
            "Error" { $color = "Red" }
        }
        
        $pkgName = if ($result.Name.Length -gt 28) { $result.Name.Substring(0, 25) + "..." } else { $result.Name }
        $elapsed = "$($result.Elapsed)s"
        
        Write-Host ("  {0,-30} " -f $pkgName) -NoNewline
        Write-Host ("{0,-15} " -f $result.Status) -NoNewline -ForegroundColor $color
        Write-Host ("{0,-10} " -f $elapsed) -NoNewline -ForegroundColor Gray
        Write-Host $result.Message -ForegroundColor Gray
    }
    
    Write-Host "  " + ("-" * 75) -ForegroundColor DarkGray
    Write-Host ""
    
    if ($Script:RebootRequired) {
        Write-Host "  [!] REBOOT REQUIRED" -ForegroundColor Yellow
        Write-Host "      Some packages require a system reboot to complete installation." -ForegroundColor Gray
        Write-Host ""
    }
    
    try {
        $summaryData = @{
            ComputerName = $env:COMPUTERNAME
            User = $env:USERNAME
            Timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
            WinGetVersion = $Script:WinGetVersion
            Packages = $Script:InstallResults
            RebootRequired = $Script:RebootRequired
            TotalPackages = $Script:InstallResults.Count
            Installed = $installed
            Skipped = $skipped
            Failed = $failed
        }
        
        $summaryData | ConvertTo-Json -Depth 10 | Set-Content -Path $Script:SummaryPath -Encoding UTF8
        Write-Host "  [+] Summary saved to: $Script:SummaryPath" -ForegroundColor Green
    }
    catch {
        Write-Host "  [!] Warning: Could not save summary JSON: $_" -ForegroundColor Yellow
    }
    
    Write-Host ""
    
    if ($Script:RebootRequired) {
        Write-Host "  Reboot now? (Y/N): " -NoNewline -ForegroundColor Yellow
        $rebootChoice = Read-Host
        if ($rebootChoice -eq "Y" -or $rebootChoice -eq "y") {
            Write-Host "  [*] Rebooting in 10 seconds..." -ForegroundColor Cyan
            shutdown /r /t 10 /c "SouliTEK Softwares Installer - Reboot Required"
        }
    }
}

function Stop-Gracefully {
    Write-Host ""
    Write-Host "[!] Operation cancelled by user" -ForegroundColor Yellow
    Write-Host ""
    
    if ($Script:InstallResults.Count -gt 0) {
        Write-Summary
    }
    
    exit
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

try {
    $Host.UI.RawUI.WindowTitle = "SOULITEK SOFTWARES INSTALLER"
    
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    [Console]::InputEncoding = [System.Text.Encoding]::UTF8
    
    $ErrorActionPreference = "Stop"
    
    Ensure-Admin
    Set-ExecutionPolicyIfNeeded
    
    Clear-Host
    Write-Banner
    
    $wingetReady = Ensure-WinGet
    if (-not $wingetReady) {
        Write-Host "[X] Cannot proceed without WinGet" -ForegroundColor Red
        Write-Host ""
        Read-Host "Press Enter to exit"
        exit 1
    }
    
    Write-Host ""
    
    $packageIds = @()
    
    if ($Preset) {
        Write-Host "[*] Loading preset from: $Preset" -ForegroundColor Cyan
        $packageIds = Load-Preset -PresetPath $Preset
        
        if (-not $packageIds -or $packageIds.Count -eq 0) {
            Write-Host "[X] No packages loaded from preset" -ForegroundColor Red
            Read-Host "Press Enter to exit"
            exit 1
        }
        
        Write-Host "[+] Loaded $($packageIds.Count) packages from preset" -ForegroundColor Green
        Write-Host ""
    }
    else {
        $packageIds = Show-InteractiveMenu
        
        if (-not $packageIds -or $packageIds.Count -eq 0) {
            Write-Host ""
            Write-Host "[*] No packages selected. Exiting." -ForegroundColor Cyan
            Write-Host ""
            exit 0
        }
        
        Clear-Host
        Write-Banner
    }
    
    Install-Packages -PackageIds $packageIds
    
    Write-Summary
    
    Write-Host "Installation complete!" -ForegroundColor Green
    Write-Host ""
    
    Read-Host "Press Enter to exit"
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

