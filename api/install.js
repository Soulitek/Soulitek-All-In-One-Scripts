// ============================================================
// SouliTEK Installer - Vercel Serverless Function
// ============================================================
// 
// This function fetches the latest installer from GitHub
// and serves it directly (no redirect), avoiding PowerShell's
// 308 redirect limitation.
//
// Usage: iwr -useb get.soulitek.co.il | iex
// 
// ============================================================

export default async function handler(req, res) {
  try {
    // Fetch the latest install script from GitHub
    const githubUrl = 'https://raw.githubusercontent.com/Soulitek/Soulitek-All-In-One-Scripts/main/Install-SouliTEK.ps1';
    
    console.log(`[${new Date().toISOString()}] Fetching installer from GitHub...`);
    
    const response = await fetch(githubUrl, {
      headers: {
        'User-Agent': 'Vercel-SouliTEK-Installer-Function/1.0',
        'Accept': 'text/plain'
      }
    });
    
    if (!response.ok) {
      throw new Error(`GitHub returned status ${response.status}: ${response.statusText}`);
    }
    
    // Get the script content
    const script = await response.text();
    
    // Validate we got PowerShell content
    if (!script.includes('SouliTEK') || !script.includes('PowerShell')) {
      throw new Error('Invalid script content received from GitHub');
    }
    
    console.log(`[${new Date().toISOString()}] Successfully fetched ${script.length} bytes`);
    
    // Set proper headers for PowerShell consumption
    res.setHeader('Content-Type', 'text/plain; charset=utf-8');
    res.setHeader('Cache-Control', 'no-cache, no-store, must-revalidate');
    res.setHeader('Pragma', 'no-cache');
    res.setHeader('Expires', '0');
    res.setHeader('X-Content-Type-Options', 'nosniff');
    res.setHeader('X-Served-By', 'Vercel-Function');
    
    // Optional: Log the request for analytics
    const userAgent = req.headers['user-agent'] || 'Unknown';
    const ip = req.headers['x-forwarded-for'] || req.connection?.remoteAddress || 'Unknown';
    console.log(`[${new Date().toISOString()}] Served to ${ip} | UA: ${userAgent}`);
    
    // Send the script
    res.status(200).send(script);
    
  } catch (error) {
    console.error(`[${new Date().toISOString()}] Error:`, error.message);
    
    // Return a PowerShell comment with the error
    res.setHeader('Content-Type', 'text/plain; charset=utf-8');
    res.status(500).send(`# SouliTEK Installer - Error
# Failed to fetch installer from GitHub
# Error: ${error.message}
# 
# Please try again or use the direct GitHub URL:
# iwr -useb https://raw.githubusercontent.com/Soulitek/Soulitek-All-In-One-Scripts/main/Install-SouliTEK.ps1 | iex
#
# For support: letstalk@soulitek.co.il

Write-Host "Error: Unable to fetch installer from server" -ForegroundColor Red
Write-Host "Error details: ${error.message}" -ForegroundColor Yellow
Write-Host ""
Write-Host "Please try the direct GitHub URL instead:" -ForegroundColor Cyan
Write-Host "iwr -useb https://raw.githubusercontent.com/Soulitek/Soulitek-All-In-One-Scripts/main/Install-SouliTEK.ps1 | iex" -ForegroundColor White
`);
  }
}

