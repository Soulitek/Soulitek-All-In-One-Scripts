# Update Simple Icons - Fetch Official Brand Logo Paths
# Simple Icons: https://github.com/simple-icons/simple-icons

$ErrorActionPreference = "Continue"

$icons = @{
    "github" = "GitHub"
    "discord" = "Discord"
    "microsoft" = "Microsoft"
    "windows" = "Windows"
    "microsoft365" = "Microsoft365"
    "microsoftazure" = "MicrosoftAzure"
    "microsoftoutlook" = "MicrosoftOutlook"
    "microsoftsharepoint" = "MicrosoftSharePoint"
    "microsoftteams" = "MicrosoftTeams"
    "microsoftonedrive" = "MicrosoftOneDrive"
    "microsoftexchange" = "MicrosoftExchange"
    "virustotal" = "VirusTotal"
    "mcafee" = "McAfee"
    "chrome" = "Chrome"
    "firefox" = "Firefox"
    "microsoftedge" = "MicrosoftEdge"
}

$baseUrl = "https://raw.githubusercontent.com/simple-icons/simple-icons/develop/icons"
$results = @{}

Write-Host "Fetching official Simple Icons paths..." -ForegroundColor Cyan

foreach ($iconFile in $icons.Keys) {
    $iconKey = $icons[$iconFile]
    try {
        $url = "$baseUrl/$iconFile.svg"
        Write-Host "Fetching $iconFile..." -ForegroundColor Gray
        
        $response = Invoke-WebRequest -Uri $url -UseBasicParsing -ErrorAction Stop
        $svgContent = $response.Content
        
        # Extract path data from SVG (Simple Icons use single path with fill)
        if ($svgContent -match '<path d="([^"]+)"') {
            $pathData = $matches[1]
            $results[$iconKey] = $pathData
            Write-Host "  OK: $iconKey" -ForegroundColor Green
        }
        
        Start-Sleep -Milliseconds 200
    }
    catch {
        Write-Warning "Failed: $iconFile - $_"
    }
}

Write-Host ""
Write-Host "Fetched $($results.Count) Simple Icons" -ForegroundColor Green
Write-Host ""

# Output formatted for PowerShell hashtable
$output = @"
# Official Simple Icons Paths (Brand Logos)
`$simpleIcons = @{
"@

foreach ($key in ($results.Keys | Sort-Object)) {
    $value = $results[$key]
    $output += "`n    `"$key`" = `"$value`""
}

$output += "`n}"

Write-Host $output
$output | Out-File -FilePath "launcher\simple-icons-paths.txt" -Encoding UTF8
Write-Host ""
Write-Host "Paths saved to launcher\simple-icons-paths.txt" -ForegroundColor Yellow

