<?php
/**
 * SouliTEK Installer Proxy
 * 
 * Upload this file to your web hosting to serve the installer from your domain.
 * 
 * Usage:
 * 1. Upload to: /public_html/install.php (or /public_html/get/index.php)
 * 2. Users run: iwr -useb soulitek.co.il/install.php | iex
 * 
 * Features:
 * - Serves latest version from GitHub
 * - Logs downloads
 * - Proper headers for PowerShell
 * 
 * © 2025 SouliTEK - www.soulitek.co.il
 */

// Configuration
$githubUrl = 'https://raw.githubusercontent.com/Soulitek/Soulitek-All-In-One-Scripts/main/Install-SouliTEK.ps1';
$logFile = __DIR__ . '/install-downloads.log';
$enableLogging = true; // Set to false to disable logging

// Set proper headers for PowerShell
header('Content-Type: text/plain; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Cache-Control: no-cache, must-revalidate');
header('X-Powered-By: SouliTEK');

// Function to get client IP (handles proxies)
function getClientIP() {
    $ipHeaders = [
        'HTTP_CF_CONNECTING_IP', // Cloudflare
        'HTTP_X_FORWARDED_FOR',
        'HTTP_X_REAL_IP',
        'REMOTE_ADDR'
    ];
    
    foreach ($ipHeaders as $header) {
        if (!empty($_SERVER[$header])) {
            $ip = $_SERVER[$header];
            // Handle comma-separated IPs (proxies)
            if (strpos($ip, ',') !== false) {
                $ips = explode(',', $ip);
                $ip = trim($ips[0]);
            }
            // Basic IP validation
            if (filter_var($ip, FILTER_VALIDATE_IP)) {
                return $ip;
            }
        }
    }
    return 'UNKNOWN';
}

// Log the download
if ($enableLogging) {
    $logEntry = sprintf(
        "[%s] IP: %s | User-Agent: %s | Referer: %s\n",
        date('Y-m-d H:i:s'),
        getClientIP(),
        $_SERVER['HTTP_USER_AGENT'] ?? 'Unknown',
        $_SERVER['HTTP_REFERER'] ?? 'Direct'
    );
    
    // Write to log file (create if doesn't exist)
    @file_put_contents($logFile, $logEntry, FILE_APPEND | LOCK_EX);
}

// Fetch the script from GitHub
$context = stream_context_create([
    'http' => [
        'timeout' => 30,
        'user_agent' => 'SouliTEK-Proxy/1.0'
    ]
]);

$script = @file_get_contents($githubUrl, false, $context);

// Check if fetch was successful
if ($script === false) {
    http_response_code(502); // Bad Gateway
    die("# ERROR: Unable to fetch installer from GitHub\n# Please try again later or contact support@soulitek.co.il");
}

// Output the script
echo $script;

// For optional database tracking, see: hosting/README.md#optional-database-logging
?>

