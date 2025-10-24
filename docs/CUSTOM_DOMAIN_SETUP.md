# 🌐 Custom Domain Setup for SouliTEK Installer

This guide shows you how to host the SouliTEK installer on your own domain: **soulitek.co.il**

---

## 🎯 Goal

Instead of:
```powershell
iwr -useb https://raw.githubusercontent.com/Soulitek/Soulitek-All-In-One-Scripts/main/Install-SouliTEK.ps1 | iex
```

Users will run:
```powershell
iwr -useb https://get.soulitek.co.il | iex
```

Or even simpler:
```powershell
iwr -useb soulitek.co.il/install | iex
```

Much easier to remember and share! ✨

---

## 📋 Implementation Methods

### Method 1: Direct Script Hosting (Recommended)

Host the `Install-SouliTEK.ps1` file directly on your web server.

**Setup:**

1. **Upload to your web hosting:**
   ```
   /public_html/install.ps1
   or
   /public_html/get/index.ps1
   ```

2. **Configure web server to serve .ps1 files as text:**

   **For Apache (.htaccess):**
   ```apache
   <Files "install.ps1">
       AddType text/plain .ps1
       Header set Content-Type "text/plain; charset=utf-8"
   </Files>
   ```

   **For Nginx (nginx.conf):**
   ```nginx
   location ~ \.ps1$ {
       add_header Content-Type "text/plain; charset=utf-8";
   }
   ```

   **For IIS (web.config):**
   ```xml
   <configuration>
     <system.webServer>
       <staticContent>
         <mimeMap fileExtension=".ps1" mimeType="text/plain" />
       </staticContent>
     </system.webServer>
   </configuration>
   ```

3. **Users can now run:**
   ```powershell
   iwr -useb https://soulitek.co.il/install.ps1 | iex
   ```

---

### Method 2: URL Redirect (Easiest)

Redirect a short URL to the GitHub raw file.

**Setup:**

1. **Create subdomain:** `get.soulitek.co.il`

2. **Configure redirect:**

   **Using cPanel Redirects:**
   - Go to cPanel → Domains → Redirects
   - Type: Permanent (301)
   - From: `https://get.soulitek.co.il`
   - To: `https://raw.githubusercontent.com/Soulitek/Soulitek-All-In-One-Scripts/main/Install-SouliTEK.ps1`

   **Using .htaccess:**
   ```apache
   RewriteEngine On
   RewriteRule ^$ https://raw.githubusercontent.com/Soulitek/Soulitek-All-In-One-Scripts/main/Install-SouliTEK.ps1 [L,R=301]
   ```

   **Using Nginx:**
   ```nginx
   server {
       server_name get.soulitek.co.il;
       return 301 https://raw.githubusercontent.com/Soulitek/Soulitek-All-In-One-Scripts/main/Install-SouliTEK.ps1;
   }
   ```

3. **Users can now run:**
   ```powershell
   iwr -useb https://get.soulitek.co.il | iex
   ```

---

### Method 3: Cloudflare Workers (Advanced)

Use Cloudflare to serve the script with caching and analytics.

**Setup:**

1. **Create Cloudflare Worker:**
   - Go to Cloudflare Dashboard → Workers
   - Create new worker
   - Paste this code:

```javascript
addEventListener('fetch', event => {
  event.respondWith(handleRequest(event.request))
})

async function handleRequest(request) {
  // Fetch the script from GitHub
  const githubUrl = 'https://raw.githubusercontent.com/Soulitek/Soulitek-All-In-One-Scripts/main/Install-SouliTEK.ps1'
  
  const response = await fetch(githubUrl, {
    cf: {
      cacheTtl: 300, // Cache for 5 minutes
      cacheEverything: true
    }
  })
  
  // Clone response and set correct headers
  const newResponse = new Response(response.body, response)
  newResponse.headers.set('Content-Type', 'text/plain; charset=utf-8')
  newResponse.headers.set('Access-Control-Allow-Origin', '*')
  
  // Add analytics header
  newResponse.headers.set('X-Served-By', 'SouliTEK-Cloudflare')
  
  return newResponse
}
```

2. **Route the worker:**
   - Add route: `get.soulitek.co.il/*`
   - Or: `soulitek.co.il/install`

3. **Benefits:**
   - Fast global CDN
   - Analytics and logging
   - Automatic caching
   - DDoS protection

---

### Method 4: Simple PHP Proxy

If your hosting supports PHP, create a simple proxy.

**Create `install.php` or `get/index.php`:**

```php
<?php
header('Content-Type: text/plain; charset=utf-8');
header('Access-Control-Allow-Origin: *');

// Fetch from GitHub
$url = 'https://raw.githubusercontent.com/Soulitek/Soulitek-All-In-One-Scripts/main/Install-SouliTEK.ps1';
$script = file_get_contents($url);

// Log download (optional)
$logFile = 'downloads.log';
$logEntry = date('Y-m-d H:i:s') . ' - ' . $_SERVER['REMOTE_ADDR'] . "\n";
file_put_contents($logFile, $logEntry, FILE_APPEND);

// Output the script
echo $script;
?>
```

**Users can run:**
```powershell
iwr -useb https://soulitek.co.il/install.php | iex
# or
iwr -useb https://soulitek.co.il/get | iex
```

---

## 🔧 Recommended Setup for soulitek.co.il

### Option A: Subdomain (Clean and Professional)

**URL:** `get.soulitek.co.il`

**Steps:**
1. Create subdomain in cPanel/hosting
2. Point to a simple redirect or host the file directly
3. Users run: `iwr -useb get.soulitek.co.il | iex`

**Benefits:**
- Clean URL
- Easy to remember
- Professional appearance

---

### Option B: Path-Based (All-in-One Domain)

**URL:** `soulitek.co.il/install`

**Steps:**
1. Create `/install` directory
2. Add `install.ps1` or `index.php` (proxy)
3. Configure to serve as text/plain
4. Users run: `iwr -useb soulitek.co.il/install | iex`

**Benefits:**
- Single domain
- Multiple paths possible (/install, /tools, etc.)

---

## 🚀 Quick Setup Guide (Recommended Path)

### Step 1: Choose Your URL

Pick one:
- `https://get.soulitek.co.il`
- `https://soulitek.co.il/install`
- `https://tools.soulitek.co.il`

### Step 2: Set Up Redirect

**Using cPanel:**
1. Login to cPanel
2. Go to "Domains" → "Redirects"
3. Add redirect:
   - From: Your chosen URL
   - To: `https://raw.githubusercontent.com/Soulitek/Soulitek-All-In-One-Scripts/main/Install-SouliTEK.ps1`
   - Type: Permanent (301)

**Using .htaccess (if subdomain doesn't exist):**
1. Create subdomain folder: `/public_html/get/`
2. Create `.htaccess`:
```apache
RewriteEngine On
RewriteRule ^$ https://raw.githubusercontent.com/Soulitek/Soulitek-All-In-One-Scripts/main/Install-SouliTEK.ps1 [L,R=301]
```

### Step 3: Test It

```powershell
# Test the URL in browser first
# Then test PowerShell command:
iwr -useb https://get.soulitek.co.il | iex
```

### Step 4: Update Documentation

Update all your docs with the new URL!

---

## 📝 Update Install Command Everywhere

Once set up, update these files:

### 1. README.md
```powershell
iwr -useb get.soulitek.co.il | iex
```

### 2. Install-SouliTEK.ps1 Comments
```powershell
# Run this script directly from URL:
# iwr -useb get.soulitek.co.il | iex
```

### 3. Documentation Files
- `docs/QUICK_INSTALL.md`
- `QUICK_INSTALL_CHEATSHEET.md`
- `URL_INSTALL_SUMMARY.md`

### 4. Marketing Materials
- Business cards
- Email signatures
- Social media bios
- Website footer

---

## 🎨 Marketing Your Custom URL

### Professional Touch

**Business Card:**
```
┌─────────────────────────────┐
│      SouliTEK Solutions     │
│                             │
│   Quick Install:            │
│   get.soulitek.co.il        │
│                             │
│   All IT tools in one line  │
└─────────────────────────────┘
```

**Email Signature:**
```
──────────────────────────────────
Eitan | SouliTEK IT Solutions
🚀 Quick Install: get.soulitek.co.il
📧 letstalk@soulitek.co.il
──────────────────────────────────
```

**QR Code:**
Generate QR for: `https://get.soulitek.co.il`
- Print on flyers
- Show on phone to customers
- Add to presentations

---

## 📊 Analytics (Optional)

### Track Downloads

**Using PHP:**
```php
// In your install.php
$log = [
    'timestamp' => date('c'),
    'ip' => $_SERVER['REMOTE_ADDR'],
    'user_agent' => $_SERVER['HTTP_USER_AGENT']
];
file_put_contents('stats.json', json_encode($log) . "\n", FILE_APPEND);
```

**Using Cloudflare Workers:**
- Built-in analytics dashboard
- Real-time statistics
- Geographic distribution

**Using Google Analytics:**
- Track page views
- See download locations
- Monitor trends

---

## 🔒 Security Considerations

### 1. HTTPS Required
Always use HTTPS for security:
```powershell
# Good
iwr -useb https://get.soulitek.co.il | iex

# Bad - Don't use HTTP
iwr -useb http://get.soulitek.co.il | iex
```

### 2. Content Integrity
If hosting directly:
- Keep script updated
- Regular security audits
- Monitor for unauthorized changes

### 3. Rate Limiting
Prevent abuse:
- Cloudflare protection
- Server-side rate limiting
- Monitor unusual traffic

---

## 🆘 Troubleshooting

### "Cannot resolve hostname"
- Check DNS propagation: https://dnschecker.org
- Wait 24-48 hours after DNS changes
- Try flushing DNS: `ipconfig /flushdns`

### "SSL certificate error"
- Ensure valid SSL certificate
- Use Let's Encrypt for free SSL
- Check Cloudflare SSL settings

### "Redirect loop detected"
- Check .htaccess for duplicate rules
- Verify cPanel redirect settings
- Clear browser cache

### "File not found (404)"
- Verify file exists at specified path
- Check file permissions (644)
- Review server error logs

---

## 🎯 Best Setup Recommendation

**For soulitek.co.il, I recommend:**

### Setup: Subdomain with Redirect

**URL:** `get.soulitek.co.il`

**Method:** Simple redirect to GitHub

**Why:**
- ✅ Easy to set up (5 minutes)
- ✅ No maintenance required
- ✅ Always serves latest from GitHub
- ✅ Clean, memorable URL
- ✅ Professional appearance

**How:**
1. Create subdomain: `get.soulitek.co.il`
2. Point to folder or use redirect
3. Test: `curl -L https://get.soulitek.co.il`
4. Done!

---

## 📞 Need Help?

**Domain Setup Support:**
- Check with your hosting provider (usually very helpful)
- Most hosting has live chat support
- Ask: "How do I set up a subdomain redirect?"

**Technical Questions:**
- 📧 Email: letstalk@soulitek.co.il
- 🌐 Web: https://soulitek.co.il

---

## ✅ Final Checklist

- [ ] Chosen URL structure (get.soulitek.co.il recommended)
- [ ] Created subdomain or directory
- [ ] Set up redirect or hosting
- [ ] Configured HTTPS/SSL
- [ ] Tested in browser
- [ ] Tested PowerShell command
- [ ] Updated README.md
- [ ] Updated all documentation
- [ ] Updated business cards/signatures
- [ ] Created QR code
- [ ] Informed team of new URL

---

## 🎉 Result

Your command will be:

```powershell
iwr -useb get.soulitek.co.il | iex
```

**Easy to remember. Easy to share. Professional!** 🚀

---

**© 2025 SouliTEK - Made with ❤️ in Israel**

