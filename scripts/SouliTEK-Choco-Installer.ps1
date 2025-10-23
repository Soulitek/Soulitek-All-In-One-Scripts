<#
.SYNOPSIS
    SouliTEK Chocolatey Package Installer - Ninite-like UX for Chocolatey
.DESCRIPTION
    Interactive TUI menu to select and install applications via Chocolatey.
    Auto-installs Chocolatey if missing. Supports presets, categories, and idempotent installs.
.PARAMETER Preset
    Path to JSON preset file containing package IDs to install
.PARAMETER Category
    Start menu filtered by specific category (Browsers, Runtimes, Utilities, etc.)
.PARAMETER Force
    Reinstall/upgrade packages even if already installed
.PARAMETER Source
    Chocolatey source URL
.PARAMETER Pre
    Allow pre-release packages
.PARAMETER WhatIf
    Simulate installs without making changes
.EXAMPLE
    .\SouliTEK-Choco-Installer.ps1
    Opens interactive menu
.EXAMPLE
    .\SouliTEK-Choco-Installer.ps1 -Preset .\my-preset.json -Force
    Installs packages from preset file, forcing reinstall
.NOTES
    Author: SouliTEK
    Requires: Windows PowerShell 5.1+, Admin rights
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$Preset,
    
    [Parameter(Mandatory=$false)]
    [string]$Category,
    
    [Parameter(Mandatory=$false)]
    [switch]$Force,
    
    [Parameter(Mandatory=$false)]
    [string]$Source,
    
    [Parameter(Mandatory=$false)]
    [switch]$Pre,
    
    [Parameter(Mandatory=$false)]
    [switch]$WhatIf
)

# ============================================================================
# GLOBAL CONFIGURATION
# ============================================================================

$Script:LogFolder = "$env:ProgramData\SouliTEK\ChocoInstaller\Logs"
$Script:SummaryPath = "$env:USERPROFILE\Desktop\SouliTEK-Choco-Installer-Result.json"
$Script:PresetFolder = "$env:USERPROFILE\Desktop"
$Script:TranscriptPath = ""
$Script:RebootRequired = $false
$Script:InstallResults = @()
$Script:ChocolateyVersion = ""

# Package Catalog - Easily Extendable
$Script:PackageCatalog = @(
    # Browsers
    @{ Id = "googlechrome"; Name = "Google Chrome"; Category = "Browsers"; Notes = "Fast, secure browser by Google" }
    @{ Id = "firefox"; Name = "Mozilla Firefox"; Category = "Browsers"; Notes = "Open-source browser with privacy focus" }
    @{ Id = "microsoft-edge"; Name = "Microsoft Edge"; Category = "Browsers"; Notes = "Chromium-based Microsoft browser" }
    
    # Runtimes
    @{ Id = "dotnet-desktopruntime"; Name = ".NET Desktop Runtime"; Category = "Runtimes"; Notes = "Required for .NET applications" }
    @{ Id = "vcredist-all"; Name = "Visual C++ Redistributables"; Category = "Runtimes"; Notes = "All VC++ runtime packages" }
    
    # Utilities
    @{ Id = "7zip"; Name = "7-Zip"; Category = "Utilities"; Notes = "Free file archiver with high compression" }
    @{ Id = "notepadplusplus"; Name = "Notepad++"; Category = "Utilities"; Notes = "Advanced text and code editor" }
    @{ Id = "everything"; Name = "Everything Search"; Category = "Utilities"; Notes = "Ultra-fast file search tool" }
    @{ Id = "ccleaner"; Name = "CCleaner"; Category = "Utilities"; Notes = "System optimization and cleaning tool" }
    @{ Id = "adobereader"; Name = "Adobe Acrobat Reader"; Category = "Utilities"; Notes = "PDF reader by Adobe" }
    @{ Id = "winrar"; Name = "WinRAR"; Category = "Utilities"; Notes = "Popular file compression utility" }
    
    # Communications
    @{ Id = "zoom"; Name = "Zoom"; Category = "Communications"; Notes = "Video conferencing platform" }
    @{ Id = "microsoft-teams"; Name = "Microsoft Teams"; Category = "Communications"; Notes = "Collaboration and chat platform" }
    @{ Id = "slack"; Name = "Slack"; Category = "Communications"; Notes = "Team communication tool" }
    @{ Id = "anydesk"; Name = "AnyDesk"; Category = "Communications"; Notes = "Fast remote desktop software" }
    @{ Id = "discord"; Name = "Discord"; Category = "Communications"; Notes = "Voice, video, and text chat" }
    
    # Media
    @{ Id = "vlc"; Name = "VLC Media Player"; Category = "Media"; Notes = "Free multimedia player" }
    @{ Id = "spotify"; Name = "Spotify"; Category = "Media"; Notes = "Music streaming service" }
    @{ Id = "handbrake"; Name = "HandBrake"; Category = "Media"; Notes = "Video transcoder" }
    
    # Development
    @{ Id = "git"; Name = "Git"; Category = "Development"; Notes = "Distributed version control system" }
    @{ Id = "vscode"; Name = "Visual Studio Code"; Category = "Development"; Notes = "Lightweight code editor by Microsoft" }
    @{ Id = "nodejs-lts"; Name = "Node.js LTS"; Category = "Development"; Notes = "JavaScript runtime environment" }
    @{ Id = "python"; Name = "Python"; Category = "Development"; Notes = "Python programming language" }
    @{ Id = "postman"; Name = "Postman"; Category = "Development"; Notes = "API development and testing tool" }
    @{ Id = "sublimetext3"; Name = "Sublime Text 3"; Category = "Development"; Notes = "Sophisticated text editor" }
    @{ Id = "docker-desktop"; Name = "Docker Desktop"; Category = "Development"; Notes = "Containerization platform" }
    @{ Id = "github-desktop"; Name = "GitHub Desktop"; Category = "Development"; Notes = "Git GUI client" }
    
    # Sysadmin
    @{ Id = "sysinternals"; Name = "Sysinternals Suite"; Category = "Sysadmin"; Notes = "Advanced system utilities" }
    @{ Id = "hwinfo"; Name = "HWiNFO"; Category = "Sysadmin"; Notes = "Hardware information and diagnostics" }
    @{ Id = "wireguard"; Name = "WireGuard"; Category = "Sysadmin"; Notes = "Modern VPN solution" }
    @{ Id = "winscp"; Name = "WinSCP"; Category = "Sysadmin"; Notes = "SFTP and FTP client" }
    @{ Id = "putty"; Name = "PuTTY"; Category = "Sysadmin"; Notes = "SSH and telnet client" }
    @{ Id = "openvpn"; Name = "OpenVPN"; Category = "Sysadmin"; Notes = "Open-source VPN client" }
    @{ Id = "powershell-core"; Name = "PowerShell Core"; Category = "Sysadmin"; Notes = "Cross-platform PowerShell" }
    @{ Id = "rsat"; Name = "RSAT"; Category = "Sysadmin"; Notes = "Remote Server Administration Tools" }
    @{ Id = "teamviewer"; Name = "TeamViewer"; Category = "Sysadmin"; Notes = "Remote access and support" }
    
    # Security
    @{ Id = "keepass"; Name = "KeePass"; Category = "Security"; Notes = "Password manager" }
    @{ Id = "bitwarden"; Name = "Bitwarden"; Category = "Security"; Notes = "Cloud-based password manager" }
    @{ Id = "veracrypt"; Name = "VeraCrypt"; Category = "Security"; Notes = "Disk encryption software" }
)

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

function Write-Banner {
    Write-Host ""
    Write-Host "  =========================================================" -ForegroundColor Cyan
    Write-Host "   _____ ____  _    _ _      _____ _______ ______ _  __  " -ForegroundColor Cyan
    Write-Host "  / ____/ __ \| |  | | |    |_   _|__   __|  ____| |/ /  " -ForegroundColor Cyan
    Write-Host " | (___| |  | | |  | | |      | |    | |  | |__  | ' /   " -ForegroundColor Cyan
    Write-Host "  \___ \ |  | | |  | | |      | |    | |  |  __| |  <    " -ForegroundColor Cyan
    Write-Host "  ____) | |__| | |__| | |____ _| |_   | |  | |____| . \   " -ForegroundColor Cyan
    Write-Host " |_____/ \____/ \____/|______|_____|  |_|  |______|_|\_\  " -ForegroundColor Cyan
    Write-Host "  =========================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Chocolatey Package Installer - Ninite-like UX" -ForegroundColor White
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
        if ($Category) { $argList += "-Category `"$Category`"" }
        if ($Force) { $argList += "-Force" }
        if ($Source) { $argList += "-Source `"$Source`"" }
        if ($Pre) { $argList += "-Pre" }
        if ($WhatIf) { $argList += "-WhatIf" }
        
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

function Ensure-Choco {
    Write-Host "[*] Checking Chocolatey installation..." -ForegroundColor Cyan
    
    $chocoCmd = Get-Command choco.exe -ErrorAction SilentlyContinue
    if ($chocoCmd) {
        $Script:ChocolateyVersion = (choco --version 2>$null)
        Write-Host "[+] Chocolatey $Script:ChocolateyVersion found" -ForegroundColor Green
        return $true
    }
    
    Write-Host "[!] Chocolatey not found. Installing..." -ForegroundColor Yellow
    
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
        
        $installScript = Invoke-WebRequest -Uri "https://community.chocolatey.org/install.ps1" -UseBasicParsing
        
        if ($WhatIf) {
            Write-Host "[WhatIf] Would install Chocolatey" -ForegroundColor Magenta
            return $false
        }
        
        Invoke-Expression $installScript.Content
        
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
        
        $chocoCmd = Get-Command choco.exe -ErrorAction SilentlyContinue
        if ($chocoCmd) {
            $Script:ChocolateyVersion = (choco --version 2>$null)
            Write-Host "[+] Chocolatey $Script:ChocolateyVersion installed successfully" -ForegroundColor Green
            return $true
        }
        else {
            Write-Host "[X] Chocolatey installation failed. Please install manually." -ForegroundColor Red
            Write-Host "    Visit: https://chocolatey.org/install" -ForegroundColor Yellow
            return $false
        }
    }
    catch {
        Write-Host "[X] Error installing Chocolatey: $_" -ForegroundColor Red
        return $false
    }
}

function Initialize-Logging {
    try {
        if (-not (Test-Path $Script:LogFolder)) {
            New-Item -ItemType Directory -Path $Script:LogFolder -Force | Out-Null
        }
        
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $Script:TranscriptPath = Join-Path $Script:LogFolder "ChocoInstaller_$timestamp.log"
        
        Start-Transcript -Path $Script:TranscriptPath -Force | Out-Null
        Write-Host "[+] Logging to: $Script:TranscriptPath" -ForegroundColor Green
    }
    catch {
        Write-Host "[!] Warning: Could not initialize logging: $_" -ForegroundColor Yellow
    }
}

function Get-Categories {
    $categories = @("All")
    $categories += ($Script:PackageCatalog | Select-Object -ExpandProperty Category -Unique | Sort-Object)
    return $categories
}

function Show-Menu {
    param(
        [array]$Packages,
        [hashtable]$Selected,
        [int]$CursorPosition,
        [string]$CurrentCategory,
        [string]$FilterText
    )
    
    Clear-Host
    Write-Banner
    
    if ($Script:ChocolateyVersion) {
        Write-Host "  Chocolatey Version: " -NoNewline -ForegroundColor Gray
        Write-Host $Script:ChocolateyVersion -ForegroundColor Green
        Write-Host ""
    }
    
    $selectedCount = ($Selected.Keys | Where-Object { $Selected[$_] }).Count
    $totalCount = $Packages.Count
    $filteredCount = $Packages.Count
    
    Write-Host "  Selected: " -NoNewline -ForegroundColor Gray
    Write-Host "$selectedCount" -NoNewline -ForegroundColor Cyan
    Write-Host " / $totalCount" -NoNewline -ForegroundColor Gray
    if ($FilterText) {
        Write-Host " (Filtered: $filteredCount)" -ForegroundColor Yellow
    }
    else {
        Write-Host ""
    }
    
    Write-Host "  Category: " -NoNewline -ForegroundColor Gray
    Write-Host $CurrentCategory -ForegroundColor Magenta
    
    if ($FilterText) {
        Write-Host "  Filter: " -NoNewline -ForegroundColor Gray
        Write-Host $FilterText -ForegroundColor Yellow
    }
    
    Write-Host ""
    Write-Host "  ============================================================================" -ForegroundColor DarkGray
    Write-Host ""
    
    # Grid layout: 2 columns
    $columns = 2
    $columnWidth = 36
    $visibleRows = 10
    
    # Calculate current row and start position
    $currentRow = [Math]::Floor($CursorPosition / $columns)
    $startRow = [Math]::Max(0, $currentRow - [Math]::Floor($visibleRows / 2))
    
    # Display packages in grid
    for ($row = $startRow; $row -lt ($startRow + $visibleRows); $row++) {
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
        Write-Host "  No packages match the current filter." -ForegroundColor Red
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
    Write-Host "    [Arrows] Navigate  [Space] Toggle  [A] All  [N] None" -ForegroundColor Gray
    Write-Host "    [F] Filter  [C] Category  [P] Save Preset  [L] Load Preset" -ForegroundColor Gray
    Write-Host "    [I] Install  [Q] Quit" -ForegroundColor Gray
    Write-Host ""
}

function Get-FilteredPackages {
    param(
        [string]$Category,
        [string]$FilterText
    )
    
    $filtered = $Script:PackageCatalog
    
    if ($Category -ne "All") {
        $filtered = $filtered | Where-Object { $_.Category -eq $Category }
    }
    
    if ($FilterText) {
        $filtered = $filtered | Where-Object { 
            $_.Name -like "*$FilterText*" -or 
            $_.Id -like "*$FilterText*" -or 
            $_.Category -like "*$FilterText*" -or
            $_.Notes -like "*$FilterText*"
        }
    }
    
    return $filtered
}

function Show-InteractiveMenu {
    $currentCategory = if ($Category) { $Category } else { "All" }
    $filterText = ""
    $cursorPosition = 0
    $selected = @{}
    
    foreach ($pkg in $Script:PackageCatalog) {
        $selected[$pkg.Id] = $false
    }
    
    $packages = Get-FilteredPackages -Category $currentCategory -FilterText $filterText
    
    while ($true) {
        Show-Menu -Packages $packages -Selected $selected -CursorPosition $cursorPosition -CurrentCategory $currentCategory -FilterText $filterText
        
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
            70 { # F - Filter
                Show-Menu -Packages $packages -Selected $selected -CursorPosition $cursorPosition -CurrentCategory $currentCategory -FilterText $filterText
                Write-Host "  Enter filter text (or press Enter to clear): " -NoNewline -ForegroundColor Yellow
                $newFilter = Read-Host
                $filterText = $newFilter
                $packages = Get-FilteredPackages -Category $currentCategory -FilterText $filterText
                $cursorPosition = 0
            }
            67 { # C - Category
                $categories = Get-Categories
                Show-Menu -Packages $packages -Selected $selected -CursorPosition $cursorPosition -CurrentCategory $currentCategory -FilterText $filterText
                Write-Host "  Available categories:" -ForegroundColor Yellow
                for ($i = 0; $i -lt $categories.Count; $i++) {
                    Write-Host "    [$i] $($categories[$i])" -ForegroundColor Cyan
                }
                Write-Host "  Select category number: " -NoNewline -ForegroundColor Yellow
                $catChoice = Read-Host
                if ($catChoice -match '^\d+$' -and [int]$catChoice -ge 0 -and [int]$catChoice -lt $categories.Count) {
                    $currentCategory = $categories[[int]$catChoice]
                    $packages = Get-FilteredPackages -Category $currentCategory -FilterText $filterText
                    $cursorPosition = 0
                }
            }
            80 { # P - Save Preset
                $selectedIds = $selected.Keys | Where-Object { $selected[$_] }
                if ($selectedIds.Count -eq 0) {
                    Show-Menu -Packages $packages -Selected $selected -CursorPosition $cursorPosition -CurrentCategory $currentCategory -FilterText $filterText
                    Write-Host "  [!] No packages selected" -ForegroundColor Red
                    Start-Sleep -Seconds 2
                }
                else {
                    Show-Menu -Packages $packages -Selected $selected -CursorPosition $cursorPosition -CurrentCategory $currentCategory -FilterText $filterText
                    Write-Host "  Enter preset filename (without .json): " -NoNewline -ForegroundColor Yellow
                    $presetName = Read-Host
                    if ($presetName) {
                        Save-Preset -PackageIds $selectedIds -PresetName $presetName
                        Write-Host "  [+] Preset saved successfully" -ForegroundColor Green
                        Start-Sleep -Seconds 2
                    }
                }
            }
            76 { # L - Load Preset
                Show-Menu -Packages $packages -Selected $selected -CursorPosition $cursorPosition -CurrentCategory $currentCategory -FilterText $filterText
                Write-Host "  Enter preset filename (without .json): " -NoNewline -ForegroundColor Yellow
                $presetName = Read-Host
                if ($presetName) {
                    $presetPath = Join-Path $Script:PresetFolder "$presetName.json"
                    $loadedIds = Load-Preset -PresetPath $presetPath
                    if ($loadedIds) {
                        foreach ($pkg in $Script:PackageCatalog) {
                            $selected[$pkg.Id] = $false
                        }
                        foreach ($id in $loadedIds) {
                            if ($selected.ContainsKey($id)) {
                                $selected[$id] = $true
                            }
                        }
                        Write-Host "  [+] Preset loaded successfully" -ForegroundColor Green
                        Start-Sleep -Seconds 2
                    }
                }
            }
            73 { # I - Install
                $selectedIds = $selected.Keys | Where-Object { $selected[$_] }
                if ($selectedIds.Count -eq 0) {
                    Show-Menu -Packages $packages -Selected $selected -CursorPosition $cursorPosition -CurrentCategory $currentCategory -FilterText $filterText
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

function Save-Preset {
    param(
        [array]$PackageIds,
        [string]$PresetName
    )
    
    try {
        $presetPath = Join-Path $Script:PresetFolder "$PresetName.json"
        $PackageIds | ConvertTo-Json | Set-Content -Path $presetPath -Encoding UTF8
        Write-Host "[+] Preset saved to: $presetPath" -ForegroundColor Green
    }
    catch {
        Write-Host "[X] Error saving preset: $_" -ForegroundColor Red
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
        $result = choco list --local-only --exact $PackageId --limit-output 2>$null
        return ($null -ne $result -and $result.Trim() -ne "")
    }
    catch {
        return $false
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
            
            if ($isInstalled -and -not $Force) {
                Write-Host "             [SKIP] Already installed" -ForegroundColor Yellow
                $status = "Skipped"
                $message = "Already installed"
            }
            else {
                if ($WhatIf) {
                    Write-Host "             [WhatIf] Would install $pkgId" -ForegroundColor Magenta
                    $status = "WhatIf"
                    $message = "Simulated install"
                }
                else {
                    $chocoArgs = @("install", $pkgId, "-y", "--no-progress", "--limit-output")
                    
                    if ($Force) { $chocoArgs += "--force" }
                    if ($Source) { $chocoArgs += "--source=$Source" }
                    if ($Pre) { $chocoArgs += "--pre" }
                    
                    Write-Host "             [*] Installing..." -ForegroundColor Cyan
                    
                    $output = & choco @chocoArgs 2>&1
                    
                    if ($LASTEXITCODE -eq 0) {
                        Write-Host "             [OK] Installed successfully" -ForegroundColor Green
                        $status = "Installed"
                        $message = "Success"
                        
                        if ($output -match "reboot") {
                            $Script:RebootRequired = $true
                            Write-Host "             [!] Reboot may be required" -ForegroundColor Yellow
                        }
                    }
                    elseif ($LASTEXITCODE -eq 3010) {
                        Write-Host "             [OK] Installed (reboot required)" -ForegroundColor Green
                        $status = "Installed"
                        $message = "Success - Reboot Required"
                        $Script:RebootRequired = $true
                    }
                    else {
                        Write-Host "             [FAIL] Installation failed (Exit: $LASTEXITCODE)" -ForegroundColor Red
                        $status = "Failed"
                        $message = "Exit code: $LASTEXITCODE"
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
    $whatif = ($Script:InstallResults | Where-Object { $_.Status -eq "WhatIf" }).Count
    
    Write-Host "  Total Packages: " -NoNewline -ForegroundColor Gray
    Write-Host $Script:InstallResults.Count -ForegroundColor White
    Write-Host "  Installed: " -NoNewline -ForegroundColor Gray
    Write-Host $installed -ForegroundColor Green
    Write-Host "  Skipped: " -NoNewline -ForegroundColor Gray
    Write-Host $skipped -ForegroundColor Yellow
    Write-Host "  Failed: " -NoNewline -ForegroundColor Gray
    Write-Host $failed -ForegroundColor Red
    if ($whatif -gt 0) {
        Write-Host "  WhatIf: " -NoNewline -ForegroundColor Gray
        Write-Host $whatif -ForegroundColor Magenta
    }
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
            "WhatIf" { $color = "Magenta" }
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
            ChocolateyVersion = $Script:ChocolateyVersion
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
    
    if ($Script:RebootRequired -and -not $WhatIf) {
        Write-Host "  Reboot now? (Y/N): " -NoNewline -ForegroundColor Yellow
        $rebootChoice = Read-Host
        if ($rebootChoice -eq "Y" -or $rebootChoice -eq "y") {
            Write-Host "  [*] Rebooting in 10 seconds..." -ForegroundColor Cyan
            shutdown /r /t 10 /c "SouliTEK Choco Installer - Reboot Required"
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
    
    if ($Script:TranscriptPath) {
        try {
            Stop-Transcript | Out-Null
        }
        catch { }
    }
    
    exit
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

try {
    $Host.UI.RawUI.WindowTitle = "SouliTEK Chocolatey Installer"
    
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    [Console]::InputEncoding = [System.Text.Encoding]::UTF8
    
    $ErrorActionPreference = "Stop"
    
    $null = Register-EngineEvent -SourceIdentifier PowerShell.Exiting -Action {
        if ($Script:TranscriptPath) {
            try { Stop-Transcript | Out-Null } catch { }
        }
    }
    
    Ensure-Admin
    Set-ExecutionPolicyIfNeeded
    
    Clear-Host
    Write-Banner
    
    Initialize-Logging
    
    $chocoReady = Ensure-Choco
    if (-not $chocoReady) {
        Write-Host "[X] Cannot proceed without Chocolatey" -ForegroundColor Red
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
            if ($Script:TranscriptPath) {
                Stop-Transcript | Out-Null
            }
            exit 0
        }
        
        Clear-Host
        Write-Banner
    }
    
    Install-Packages -PackageIds $packageIds
    
    Write-Summary
    
    if ($Script:TranscriptPath) {
        Stop-Transcript | Out-Null
        Write-Host "[+] Transcript saved to: $Script:TranscriptPath" -ForegroundColor Green
        Write-Host ""
    }
    
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
    
    if ($Script:TranscriptPath) {
        try { Stop-Transcript | Out-Null } catch { }
    }
    
    Read-Host "Press Enter to exit"
    exit 1
}

