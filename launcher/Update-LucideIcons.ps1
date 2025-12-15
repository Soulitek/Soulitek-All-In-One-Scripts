# Update Lucide Icons - Fetch Official SVG Paths
$ErrorActionPreference = "Continue"

$icons = @{
    "settings-2" = "Settings2"
    "network" = "Network"
    "globe" = "Globe"
    "shield-check" = "ShieldCheck"
    "life-buoy" = "LifeBuoy"
    "cloud" = "Cloud"
    "cpu" = "Cpu"
    "download-cloud" = "DownloadCloud"
    "battery-medium" = "BatteryMedium"
    "lock" = "Lock"
    "file-search" = "FileSearch"
    "wifi" = "Wifi"
    "printer" = "Printer"
    "file-text" = "FileText"
    "alert-triangle" = "AlertTriangle"
    "wrench" = "Wrench"
    "mail" = "Mail"
    "help-circle" = "HelpCircle"
    "monitor" = "Monitor"
    "users" = "Users"
    "award" = "License"
    "share-2" = "Share2"
    "hard-drive" = "HardDrive"
    "activity" = "Activity"
    "key" = "Key"
    "refresh-cw" = "RefreshCw"
    "zap" = "Zap"
    "trash-2" = "Trash2"
    "x-circle" = "XCircle"
    "arrow-up-down" = "Update"
    "dns" = "Dns"
    "shield" = "Shield"
    "search" = "Search"
    "cloud-check" = "CloudCheck"
    "package" = "Package"
    "gauge" = "Gauge"
    "database" = "Database"
    "calendar" = "Calendar"
    "check-circle-2" = "CheckCircle2"
    "info" = "Info"
    "code" = "Code"
    "message-circle" = "MessageCircle"
}

$baseUrl = "https://raw.githubusercontent.com/lucide-icons/lucide/main/icons"
$results = @{}

Write-Host "Fetching official Lucide icon paths..." -ForegroundColor Cyan

foreach ($iconFile in $icons.Keys) {
    $iconKey = $icons[$iconFile]
    try {
        $url = "$baseUrl/$iconFile.svg"
        Write-Host "Fetching $iconFile..." -ForegroundColor Gray
        
        $response = Invoke-WebRequest -Uri $url -UseBasicParsing -ErrorAction Stop
        $svgContent = $response.Content
        
        # Extract all path data (icons can have multiple paths)
        $allPaths = @()
        $matches = [regex]::Matches($svgContent, 'd="([^"]+)"')
        foreach ($match in $matches) {
            $allPaths += $match.Groups[1].Value
        }
        
        if ($allPaths.Count -gt 0) {
            # Combine all paths (WPF can handle multiple paths separated by spaces)
            $pathData = $allPaths -join ' '
            $results[$iconKey] = $pathData
            Write-Host "  OK: $iconKey ($($allPaths.Count) paths)" -ForegroundColor Green
        }
        
        Start-Sleep -Milliseconds 200
    }
    catch {
        Write-Warning "Failed: $iconFile - $_"
    }
}

Write-Host ""
Write-Host "Fetched $($results.Count) icons" -ForegroundColor Green
Write-Host ""

# Output formatted for PowerShell hashtable
$output = @"
# Official Lucide Icon Paths
`$iconPaths = @{
"@

foreach ($key in ($results.Keys | Sort-Object)) {
    $value = $results[$key]
    $output += "`n    `"$key`" = `"$value`""
}

$output += "`n}"

Write-Host $output
$output | Out-File -FilePath "launcher\lucide-paths.txt" -Encoding UTF8
Write-Host ""
Write-Host "Paths saved to launcher\lucide-paths.txt" -ForegroundColor Yellow
