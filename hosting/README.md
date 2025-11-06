# 🌐 Hosting Files for Custom Domain

This folder contains files for hosting the SouliTEK installer on your custom domain (soulitek.co.il).

---

## 📁 Files in This Folder

### 1. `install-proxy.php`
**Purpose:** PHP proxy that fetches and serves the installer from GitHub.

**Features:**
- ✅ Serves latest version from GitHub
- ✅ Logs downloads with IP and timestamp
- ✅ Proper headers for PowerShell
- ✅ Error handling
- ✅ Works on any PHP hosting

**Setup:**
1. Upload to: `/public_html/install.php`
2. Or: `/public_html/get/index.php`
3. Make sure PHP is enabled on your hosting
4. Users run: `iwr -useb soulitek.co.il/install.php | iex`

---

### 2. `.htaccess-redirect`
**Purpose:** Simple redirect to GitHub (no PHP needed).

**Features:**
- ✅ Simplest method
- ✅ No server-side processing
- ✅ Always serves from GitHub
- ✅ Works on Apache servers

**Setup:**
1. Rename to: `.htaccess`
2. Upload to: `/public_html/get/`
3. Users run: `iwr -useb get.soulitek.co.il | iex`

---

### 3. `landing-page.html` (coming soon)
**Purpose:** Human-readable download page with instructions.

**Features:**
- Installation instructions
- Copy-paste command
- QR code
- Tool information

---

## 🚀 Quick Setup Guide

### Option A: Simple Redirect (Recommended)

**Best for:** Quick setup, no PHP needed

1. Create subdomain: `get.soulitek.co.il`
2. Upload `.htaccess-redirect` (rename to `.htaccess`)
3. Test: `curl -L https://get.soulitek.co.il`
4. Done!

**Command users will run:**
```powershell
iwr -useb get.soulitek.co.il | iex
```

---

### Option B: PHP Proxy (Advanced)

**Best for:** Want download logging and analytics

1. Create subdomain or directory
2. Upload `install-proxy.php`
3. Rename to `index.php` (optional)
4. Test: `curl www.soulitek.co.il/install-proxy.php`

**Command users will run:**
```powershell
iwr -useb soulitek.co.il/install-proxy.php | iex
```

---

### Option C: Direct Hosting

**Best for:** Full control, no external dependencies

1. Copy `Install-SouliTEK.ps1` from project root
2. Upload to: `/public_html/install.ps1`
3. Add `.htaccess` to serve as text/plain
4. Update file manually when you release new versions

**Command users will run:**
```powershell
iwr -useb soulitek.co.il/install.ps1 | iex
```

---

## 🎯 Recommended URLs

### Primary (Choose One)

- `get.soulitek.co.il` → Clean subdomain
- `soulitek.co.il/install` → Path-based
- `tools.soulitek.co.il` → Alternative subdomain
- `soulitek.co.il/get` → Short path

### Marketing Examples

**Business Card:**
```
Quick Install: get.soulitek.co.il
```

**Email Signature:**
```
🚀 Install Tools: get.soulitek.co.il
```

---

## 📊 Download Statistics

### If using install-proxy.php

Check download logs:
```bash
# View last 10 downloads
tail -n 10 install-downloads.log

# Count total downloads
wc -l install-downloads.log

# View downloads from today
grep "$(date +%Y-%m-%d)" install-downloads.log
```

### Log Format
```
[2025-10-23 14:30:15] IP: 192.168.1.100 | User-Agent: PowerShell/7.3.0 | Referer: Direct
```

---

## 🔧 Testing Your Setup

### Test in Browser
Visit your URL in a web browser:
- Should download or display the PowerShell script
- Should be plain text, not HTML

### Test with cURL
```bash
curl -L https://get.soulitek.co.il
```
Should output the PowerShell script content.

### Test with PowerShell
```powershell
# Download and check content
$content = iwr -useb https://get.soulitek.co.il
$content.Content
```

### Test Full Installation
```powershell
# Run the actual install
iwr -useb https://get.soulitek.co.il | iex
```

---

## 🔒 Security Checklist

- [ ] HTTPS enabled (SSL certificate)
- [ ] Correct MIME type (text/plain)
- [ ] No directory browsing
- [ ] File permissions set correctly (644)
- [ ] .htaccess protected
- [ ] Rate limiting enabled (optional)
- [ ] Download logs protected

---

## 🆘 Troubleshooting

### "Cannot connect to server"
- Check if subdomain DNS has propagated
- Wait 24-48 hours after DNS changes
- Test with: `nslookup get.soulitek.co.il`

### "403 Forbidden"
- Check file permissions (should be 644)
- Check folder permissions (should be 755)
- Verify .htaccess is not blocking

### "500 Internal Server Error"
- Check .htaccess syntax
- Review error logs in cPanel
- Test without .htaccess

### "Script contains HTML tags"
- PHP not processing correctly
- Check file extension (.php not .txt)
- Verify PHP is enabled on hosting

---

## 📞 Need Help?

**Hosting Support:**
- Contact your hosting provider
- They can help with subdomain setup
- Ask about .htaccess and PHP support

**Technical Support:**
- 📧 letstalk@soulitek.co.il
- 🌐 www.soulitek.co.il

---

## ✅ Next Steps

1. Choose your setup method (A, B, or C)
2. Upload the appropriate files
3. Test the URL
4. Update your documentation
5. Share the new URL!

---

**© 2025 SouliTEK - Made with ❤️ in Soulitek**

