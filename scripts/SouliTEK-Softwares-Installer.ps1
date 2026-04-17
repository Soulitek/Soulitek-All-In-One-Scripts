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
    Write-Ui -Message "  =========================================================" -Level "INFO"
    Write-Host "   _____ ____  _    _ _      _____ _______ ______ _  __" -ForegroundColor Cyan
    Write-Host "  / ____/ __ \| |  | | |    |_   _|__   __|  ____| |/ /" -ForegroundColor Cyan
    Write-Host " | (___| |  | | |  | | |      | |    | |  | |__  | ' /" -ForegroundColor Cyan
    Write-Host "  \___ \ |  | | |  | | |      | |    | |  |  __| |  <" -ForegroundColor Cyan
    Write-Host "  ____) | |__| | |__| | |____ _| |_   | |  | |____| . \" -ForegroundColor Cyan
    Write-Host " |_____/ \____/ \____/|______|_____|  |_|  |______|_|\_\" -ForegroundColor Cyan
    Write-Ui -Message "  =========================================================" -Level "INFO"
    Write-Host ""
    Write-Ui -Message "  Softwares Installer" -Level "STEP"
    Write-Ui -Message "  =========================================================" -Level "INFO"
    Write-Host ""
}

function Ensure-Admin {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    $isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    
    if (-not $isAdmin) {
        Write-Ui -Message "[!] Administrator privileges required" -Level "WARN"
        Write-Ui -Message "[*] Relaunching with elevation..." -Level "INFO"
        
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
            Write-Ui -Message "[*] Setting execution policy for process scope..." -Level "INFO"
            Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Ui -Message "[!] Warning: Could not set execution policy: $_" -Level "WARN"
    }
}

function Ensure-WinGet {
    Write-Ui -Message "[*] Checking WinGet installation..." -Level "INFO"
    
    $wingetCmd = Get-Command winget.exe -ErrorAction SilentlyContinue
    if ($wingetCmd) {
        try {
            $versionOutput = winget --version 2>$null
            $Script:WinGetVersion = $versionOutput -replace '[^0-9.]', ''
            Write-Ui -Message "[+] WinGet $Script:WinGetVersion found" -Level "OK"
            return $true
        }
        catch {
            Write-Ui -Message "[!] WinGet found but version check failed" -Level "WARN"
            $Script:WinGetVersion = "Unknown"
            return $true
        }
    }
    
    Write-Ui -Message "[!] WinGet not found. Installing..." -Level "WARN"
    Write-Ui -Message "[*] Attempting to install Microsoft.WinGet.Client module..." -Level "INFO"
    
    try {
        # Check if NuGet provider is installed
        $nuget = Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue
        if (-not $nuget) {
            Write-Ui -Message "[*] Installing NuGet provider..." -Level "INFO"
            Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope CurrentUser | Out-Null
        }
        
        # Set PSGallery as trusted temporarily
        $psGallery = Get-PSRepository -Name PSGallery -ErrorAction SilentlyContinue
        if ($psGallery -and $psGallery.InstallationPolicy -ne 'Trusted') {
            Write-Ui -Message "[*] Setting PSGallery as trusted..." -Level "INFO"
            Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
        }
        
        # Install WinGet module
        Write-Ui -Message "[*] Installing Microsoft.WinGet.Client module..." -Level "INFO"
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
            Write-Ui -Message "[+] WinGet $Script:WinGetVersion installed successfully" -Level "OK"
            return $true
        }
        else {
            Write-Ui -Message "[X] WinGet installation failed. Please install manually." -Level "ERROR"
            Write-Host "    Visit: https://apps.microsoft.com/detail/9NBLGGH4NNS1" -ForegroundColor Yellow
            Write-Ui -Message "    Or use: winget install Microsoft.AppInstaller" -Level "WARN"
            return $false
        }
    }
    catch {
        Write-Ui -Message "[X] Error installing WinGet: $_" -Level "ERROR"
        Write-Ui -Message "    Please install App Installer from Microsoft Store" -Level "WARN"
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
        Write-Ui -Message $Script:WinGetVersion -Level "OK"
        Write-Host ""
    }
    
    $selectedCount = ($Selected.Keys | Where-Object { $Selected[$_] }).Count
    $totalCount = $Packages.Count
    
    Write-Host "  Selected: " -NoNewline -ForegroundColor Gray
    Write-Host "$selectedCount" -NoNewline -ForegroundColor Cyan
    Write-Ui -Message " / $totalCount" -Level "INFO"
    
    Write-Host ""
    Write-Ui -Message "  ============================================================================" -Level "INFO"
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
        Write-Ui -Message "  No applications available." -Level "ERROR"
    }
    
    Write-Host ""
    Write-Ui -Message "  ============================================================================" -Level "INFO"
    Write-Host ""
    
    # Package details
    if ($CursorPosition -ge 0 -and $CursorPosition -lt $Packages.Count) {
        $currentPkg = $Packages[$CursorPosition]
        Write-Host "  Package: " -NoNewline -ForegroundColor Gray
        Write-Ui -Message $currentPkg.Name -Level "INFO"
        Write-Host "  ID: " -NoNewline -ForegroundColor Gray
        Write-Ui -Message $currentPkg.Id -Level "STEP"
        Write-Host "  Category: " -NoNewline -ForegroundColor Gray
        Write-Ui -Message $currentPkg.Category -Level "INFO"
        Write-Host "  Notes: " -NoNewline -ForegroundColor Gray
        Write-Ui -Message $currentPkg.Notes -Level "INFO"
        Write-Host ""
    }
    
    Write-Ui -Message "  Controls:" -Level "INFO"
    Write-Ui -Message "    [Arrows] Navigate  [Space] Toggle  [A] Select All  [N] Select None" -Level "INFO"
    Write-Ui -Message "    [I] Install  [Q] Quit" -Level "INFO"
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
                    Write-Ui -Message "  [!] No packages selected" -Level "ERROR"
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
            Write-Ui -Message "[X] Preset file not found: $PresetPath" -Level "ERROR"
            Start-Sleep -Seconds 2
            return $null
        }
        
        $content = Get-Content -Path $PresetPath -Raw -Encoding UTF8
        $packageIds = $content | ConvertFrom-Json
        
        Write-Ui -Message "[+] Loaded preset from: $PresetPath" -Level "OK"
        Write-Ui -Message "[*] Packages: $($packageIds -join ', ')" -Level "INFO"
        return $packageIds
    }
    catch {
        Write-Ui -Message "[X] Error loading preset: $_" -Level "ERROR"
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
    Write-Ui -Message "             [0%] Starting Office 2024 download..." -Level "INFO"
    
    try {
        $officeUrl = "https://c2rsetup.officeapps.live.com/c2r/download.aspx?ProductreleaseID=ProPlus2024Retail&platform=x64&language=he-il&version=O16GA"
        $installerPath = Join-Path $env:TEMP "OfficeSetup.exe"
        
        # Download Office installer
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Write-Ui -Message "             [10%] Connecting to download server..." -Level "INFO"

        Invoke-WebRequest -Uri $officeUrl -OutFile $installerPath -UseBasicParsing -ErrorAction Stop

        Write-Ui -Message "             [30%] Download complete" -Level "INFO"

        if (Test-Path $installerPath) {
            $officeSig = Get-AuthenticodeSignature -FilePath $installerPath
            if ($officeSig.Status -ne "Valid") {
                Write-Ui -Message "Office installer signature invalid ($($officeSig.Status)). Aborting." -Level "ERROR"
                Remove-Item -Path $installerPath -Force -ErrorAction SilentlyContinue
                return @{ Success = $false; ExitCode = -1; Message = "Signature verification failed" }
            }
            Write-Ui -Message "             [40%] Preparing installation..." -Level "INFO"
            Write-Ui -Message "             [50%] Installing Office 2024 (this may take 10-15 minutes)..." -Level "INFO"
            
            # Run the installer
            $process = Start-Process -FilePath $installerPath -ArgumentList "/configure" -Wait -PassThru -NoNewWindow
            
            Write-Ui -Message "             [90%] Cleaning up..." -Level "INFO"
            # Clean up
            Remove-Item -Path $installerPath -Force -ErrorAction SilentlyContinue
            
            Write-Ui -Message "             [100%] Installation process complete" -Level "INFO"
            
            if ($process.ExitCode -eq 0 -or $process.ExitCode -eq 3010) {
                Write-Ui -Message "             [OK] Office 2024 installed successfully" -Level "OK"
                if ($process.ExitCode -eq 3010) {
                    $Script:RebootRequired = $true
                    Write-Ui -Message "             [!] Reboot required" -Level "WARN"
                }
                return @{
                    Success = $true
                    ExitCode = $process.ExitCode
                    Message = if ($process.ExitCode -eq 3010) { "Success - Reboot Required" } else { "Success" }
                }
            }
            else {
                Write-Ui -Message "             [FAIL] Office installation failed (Exit: $($process.ExitCode))" -Level "ERROR"
                return @{
                    Success = $false
                    ExitCode = $process.ExitCode
                    Message = "Exit code: $($process.ExitCode)"
                }
            }
        }
        else {
            Write-Ui -Message "             [FAIL] Failed to download Office installer" -Level "ERROR"
            return @{
                Success = $false
                ExitCode = -1
                Message = "Download failed"
            }
        }
    }
    catch {
        Write-Ui -Message "             [ERROR] $_" -Level "ERROR"
        return @{
            Success = $false
            ExitCode = -1
            Message = $_.Exception.Message
        }
    }
}

function Install-ESETConnector {
    Write-Ui -Message "             [0%] Starting ESET Connector download..." -Level "INFO"
    
    try {
        $esetUrl = "https://download.eset.com/com/eset/apps/business/eei/agent/latest/ei_connector_nt64.msi"
        $installerPath = Join-Path $env:TEMP "ei_connector_nt64.msi"
        
        # Download ESET Connector MSI
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Write-Ui -Message "             [10%] Connecting to download server..." -Level "INFO"

        Invoke-WebRequest -Uri $esetUrl -OutFile $installerPath -UseBasicParsing -ErrorAction Stop

        Write-Ui -Message "             [30%] Download complete" -Level "INFO"

        if (Test-Path $installerPath) {
            $esetSig = Get-AuthenticodeSignature -FilePath $installerPath
            if ($esetSig.Status -ne "Valid") {
                Write-Ui -Message "ESET installer signature invalid ($($esetSig.Status)). Aborting." -Level "ERROR"
                Remove-Item -Path $installerPath -Force -ErrorAction SilentlyContinue
                return @{ Success = $false; ExitCode = -1; Message = "Signature verification failed" }
            }
            Write-Ui -Message "             [40%] Preparing installation..." -Level "INFO"
            Write-Ui -Message "             [50%] Installing ESET Connector (this may take a few minutes)..." -Level "INFO"
            
            # Run the MSI installer silently
            $process = Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$installerPath`" /qn /norestart" -Wait -PassThru -NoNewWindow
            
            Write-Ui -Message "             [90%] Cleaning up..." -Level "INFO"
            # Clean up
            Remove-Item -Path $installerPath -Force -ErrorAction SilentlyContinue
            
            Write-Ui -Message "             [100%] Installation process complete" -Level "INFO"
            
            if ($process.ExitCode -eq 0 -or $process.ExitCode -eq 3010) {
                Write-Ui -Message "             [OK] ESET Connector installed successfully" -Level "OK"
                if ($process.ExitCode -eq 3010) {
                    $Script:RebootRequired = $true
                    Write-Ui -Message "             [!] Reboot required" -Level "WARN"
                }
                return @{
                    Success = $true
                    ExitCode = $process.ExitCode
                    Message = if ($process.ExitCode -eq 3010) { "Success - Reboot Required" } else { "Success" }
                }
            }
            else {
                Write-Ui -Message "             [FAIL] ESET Connector installation failed (Exit: $($process.ExitCode))" -Level "ERROR"
                return @{
                    Success = $false
                    ExitCode = $process.ExitCode
                    Message = "Exit code: $($process.ExitCode)"
                }
            }
        }
        else {
            Write-Ui -Message "             [FAIL] Failed to download ESET Connector installer" -Level "ERROR"
            return @{
                Success = $false
                ExitCode = -1
                Message = "Download failed"
            }
        }
    }
    catch {
        Write-Ui -Message "             [ERROR] $_" -Level "ERROR"
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
    Write-Ui -Message "Starting Package Installation" -Level "INFO"
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
        Write-Ui -Message $pkgName -Level "WARN"
        Write-Ui -Message "             ID: $pkgId" -Level "INFO"
        
        $startTime = Get-Date
        $status = "Unknown"
        $message = ""
        
        try {
            $isInstalled = Test-PackageInstalled -PackageId $pkgId
            
            if ($isInstalled) {
                Write-Ui -Message "             [SKIP] Already installed" -Level "WARN"
                $status = "Skipped"
                $message = "Already installed"
            }
            else {
                Write-Ui -Message "             [*] Installing..." -Level "INFO"
                
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
                    Write-Ui -Message "             [0%] Starting installation..." -Level "INFO"
                    
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
                    
                    Write-Ui -Message "             [10%] Preparing installation..." -Level "INFO"
                    Write-Ui -Message "             [20%] Starting WinGet process..." -Level "INFO"
                    
                    # Start process with file redirection for reliable output capture
                    $proc = Start-Process -FilePath "winget" -ArgumentList $wingetArgs -NoNewWindow -PassThru -RedirectStandardOutput $logFile -RedirectStandardError $errFile
                    
                    # Set timeout (30 minutes max per package)
                    $timeout = 1800
                    $timer = [Diagnostics.Stopwatch]::StartNew()
                    $timedOut = $false
                    
                    Write-Ui -Message "             [30%] Installing package (this may take several minutes)..." -Level "INFO"
                    
                    # Wait for process with timeout check
                    $lastProgressTime = 0
                    while (-not $proc.HasExited) {
                        if ($timer.Elapsed.TotalSeconds -gt $timeout) {
                            Write-Ui -Message "             [!] Installation timeout exceeded (30 minutes)" -Level "WARN"
                            try {
                                if (-not $proc.HasExited) {
                                    $proc.Kill()
                                    $timedOut = $true
                                }
                            }
                            catch {
                                Write-Ui -Message "             [!] Could not terminate process" -Level "WARN"
                            }
                            break
                        }
                        Start-Sleep -Seconds 2
                        
                        # Update progress every 30 seconds
                        $elapsedSeconds = [int]$timer.Elapsed.TotalSeconds
                        if ($elapsedSeconds -gt $lastProgressTime + 30) {
                            $lastProgressTime = $elapsedSeconds
                            $progressPercent = [Math]::Min(90, 30 + [int]($elapsedSeconds / $timeout * 60))
                            Write-Ui -Message "             [$progressPercent%] Still installing... ($elapsedSeconds seconds elapsed)" -Level "INFO"
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
                        Write-Ui -Message "             [FAIL] Installation timed out after 30 minutes" -Level "ERROR"
                        $status = "Failed"
                        $message = "Timeout after 30 minutes"
                    }
                    else {
                        Write-Ui -Message "             [95%] Finalizing..." -Level "INFO"
                        
                        $exitCode = $proc.ExitCode
                        
                        # Check exit code
                        if ($exitCode -eq 0) {
                            Write-Ui -Message "             [100%] Installation complete" -Level "OK"
                            Write-Ui -Message "             [OK] Installed successfully" -Level "OK"
                            $status = "Installed"
                            $message = "Success"
                        }
                        elseif ($exitCode -eq 3010) {
                            Write-Ui -Message "             [100%] Installation complete" -Level "OK"
                            Write-Ui -Message "             [OK] Installed (reboot required)" -Level "OK"
                            $status = "Installed"
                            $message = "Success - Reboot Required"
                            $Script:RebootRequired = $true
                        }
                        elseif ($exitCode -eq -1978335189 -or $stdOut -like "*already installed*" -or $stdErr -like "*already installed*") {
                            Write-Ui -Message "             [SKIP] Already installed" -Level "WARN"
                            $status = "Skipped"
                            $message = "Already installed"
                        }
                        else {
                            Write-Ui -Message "             [FAIL] Installation failed (Exit: $exitCode)" -Level "ERROR"
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
            Write-Ui -Message "             [ERROR] $_" -Level "ERROR"
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
    Write-Ui -Message "Installation Summary" -Level "INFO"
    Write-Host "=============================================" -ForegroundColor DarkCyan
    Write-Host ""
    
    $installed = ($Script:InstallResults | Where-Object { $_.Status -eq "Installed" }).Count
    $skipped = ($Script:InstallResults | Where-Object { $_.Status -eq "Skipped" }).Count
    $failed = ($Script:InstallResults | Where-Object { $_.Status -eq "Failed" -or $_.Status -eq "Error" }).Count
    
    Write-Host "  Total Packages: " -NoNewline -ForegroundColor Gray
    Write-Ui -Message $Script:InstallResults.Count -Level "STEP"
    Write-Host "  Installed: " -NoNewline -ForegroundColor Gray
    Write-Ui -Message $installed -Level "OK"
    Write-Host "  Skipped: " -NoNewline -ForegroundColor Gray
    Write-Ui -Message $skipped -Level "WARN"
    Write-Host "  Failed: " -NoNewline -ForegroundColor Gray
    Write-Ui -Message $failed -Level "ERROR"
    Write-Host ""
    
    Write-Ui -Message "  Detailed Results:" -Level "INFO"
    Write-Ui -Message "  " + ("-" * 75) -Level "INFO"
    Write-Ui -Message ("  {0,-30} {1,-15} {2,-10} {3}" -f "Package", "Status", "Elapsed", "Message") -Level "INFO"
    Write-Ui -Message "  " + ("-" * 75) -Level "INFO"
    
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
        Write-Ui -Message $result.Message -Level "INFO"
    }
    
    Write-Ui -Message "  " + ("-" * 75) -Level "INFO"
    Write-Host ""
    
    if ($Script:RebootRequired) {
        Write-Ui -Message "  [!] REBOOT REQUIRED" -Level "WARN"
        Write-Ui -Message "      Some packages require a system reboot to complete installation." -Level "INFO"
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
        Write-Ui -Message "  [+] Summary saved to: $Script:SummaryPath" -Level "OK"
    }
    catch {
        Write-Ui -Message "  [!] Warning: Could not save summary JSON: $_" -Level "WARN"
    }
    
    Write-Host ""
    
    if ($Script:RebootRequired) {
        Write-Host "  Reboot now? (Y/N): " -NoNewline -ForegroundColor Yellow
        $rebootChoice = Read-Host
        if ($rebootChoice -eq "Y" -or $rebootChoice -eq "y") {
            Write-Ui -Message "  [*] Rebooting in 10 seconds..." -Level "INFO"
            shutdown /r /t 10 /c "SouliTEK Softwares Installer - Reboot Required"
        }
    }
}

function Stop-Gracefully {
    Write-Host ""
    Write-Ui -Message "[!] Operation cancelled by user" -Level "WARN"
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
    Show-ScriptBanner -ScriptName "Softwares Installer" -Purpose "Install software packages using WinGet"
    
    $wingetReady = Ensure-WinGet
    if (-not $wingetReady) {
        Write-Ui -Message "Cannot proceed without WinGet" -Level "ERROR"
        Write-Host ""
        Read-Host "Press Enter to exit"
        exit 1
    }
    
    Write-Host ""
    
    $packageIds = @()
    
    if ($Preset) {
        Write-Ui -Message "[*] Loading preset from: $Preset" -Level "INFO"
        $packageIds = Load-Preset -PresetPath $Preset
        
        if (-not $packageIds -or $packageIds.Count -eq 0) {
            Write-Ui -Message "[X] No packages loaded from preset" -Level "ERROR"
            Read-Host "Press Enter to exit"
            exit 1
        }
        
        Write-Ui -Message "[+] Loaded $($packageIds.Count) packages from preset" -Level "OK"
        Write-Host ""
    }
    else {
        $packageIds = Show-InteractiveMenu
        
        if (-not $packageIds -or $packageIds.Count -eq 0) {
            Write-Host ""
            Write-Ui -Message "[*] No packages selected. Exiting." -Level "INFO"
            Write-Host ""
            exit 0
        }
        
        Clear-Host
        Write-Banner
    }
    
    Install-Packages -PackageIds $packageIds
    
    Write-Summary
    
    Write-Ui -Message "Installation complete!" -Level "OK"
    Write-Host ""
    
    Read-Host "Press Enter to exit"
}
catch {
    Write-Host ""
    Write-Ui -Message "[X] Fatal Error: $_" -Level "ERROR"
    Write-Host ""
    Write-Ui -Message "Stack Trace:" -Level "WARN"
    Write-Ui -Message $_.ScriptStackTrace -Level "INFO"
    Write-Host ""
    
    Read-Host "Press Enter to exit"
    exit 1
}

