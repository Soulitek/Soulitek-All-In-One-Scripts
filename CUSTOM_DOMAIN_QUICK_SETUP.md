# 🌐 Custom Domain Setup - Quick Guide

## Your Goal

Make users able to run:
```powershell
iwr -useb get.soulitek.co.il | iex
```

Instead of the long GitHub URL.

---

## ✅ Easiest Method: Simple Redirect

### Step 1: Create Subdomain

In your hosting cPanel:
1. Go to **Domains** → **Subdomains**
2. Create: `get` (will become `get.soulitek.co.il`)
3. Point to any folder (e.g., `/public_html/get/`)

### Step 2: Set Up Redirect

**Option A: Using cPanel Redirects**
1. Go to **Domains** → **Redirects**
2. Type: **Permanent (301)**
3. From: `https://get.soulitek.co.il`
4. To: `https://raw.githubusercontent.com/Soulitek/Soulitek-AIO/main/Install-SouliTEK.ps1`
5. Click "Add"

**Option B: Using .htaccess**
1. Upload `hosting/.htaccess-redirect` to `/public_html/get/`
2. Rename it to `.htaccess`

### Step 3: Test It

Wait a few minutes for DNS, then:

```powershell
# Test in browser first
https://get.soulitek.co.il

# Test PowerShell command
iwr -useb get.soulitek.co.il | iex
```

### Step 4: Update Documentation

Update these files with your new URL:
- `README.md`
- `QUICK_INSTALL_CHEATSHEET.md`
- `docs/QUICK_INSTALL.md`

---

## 📁 Files to Upload

### For Simple Redirect
- **File:** `hosting/.htaccess-redirect`
- **Upload to:** `/public_html/get/.htaccess`
- **Result:** `get.soulitek.co.il` redirects to GitHub

### For PHP Proxy (with logging)
- **File:** `hosting/install-proxy.php`
- **Upload to:** `/public_html/get/index.php`
- **Result:** `get.soulitek.co.il` serves script with download logs

### For Landing Page (optional)
- **File:** `hosting/landing-page.html`
- **Upload to:** `/public_html/get/index.html`
- **Result:** Visitors see instructions and can copy command

---

## 🎯 Recommended Structure

```
/public_html/
└── get/
    ├── .htaccess          (redirect to GitHub)
    ├── index.html         (landing page - optional)
    └── install-proxy.php  (PHP version - optional)
```

**How it works:**
- Browser visitors → See landing page
- PowerShell requests → Get redirected to installer

---

## 🔧 Testing Checklist

- [ ] Can visit https://get.soulitek.co.il in browser
- [ ] Browser shows script or redirects correctly
- [ ] PowerShell command works: `iwr -useb get.soulitek.co.il`
- [ ] Full install works: `iwr -useb get.soulitek.co.il | iex`
- [ ] SSL certificate is valid (https works)

---

## 📝 Update These Files

Once your domain is working, update:

### 1. README.md
Change the install command to:
```powershell
iwr -useb get.soulitek.co.il | iex
```

### 2. Install-SouliTEK.ps1 Comments
Update the header comment with your domain.

### 3. QUICK_INSTALL_CHEATSHEET.md
Replace GitHub URL with your domain.

### 4. Business Materials
- Business cards
- Email signatures
- Website

---

## 🆘 Quick Troubleshooting

### "Cannot resolve hostname"
- DNS not propagated yet → Wait 1-24 hours
- Check: https://dnschecker.org

### "403 Forbidden"
- File permissions wrong → Set to 644
- Folder permissions → Set to 755

### "Shows HTML instead of script"
- MIME type wrong → Add .htaccess rules
- PHP not processing → Check file extension

---

## 💡 Pro Tips

1. **Short and memorable:** `get.soulitek.co.il` is perfect!
2. **Test both HTTP and HTTPS:** Always use HTTPS in docs
3. **Mobile friendly:** Create QR code for easy sharing
4. **Analytics:** Use PHP proxy to track downloads

---

## 📞 Need Help?

**Hosting Support:**
- Most hosting providers have live chat
- Ask: "How do I redirect a subdomain to an external URL?"

**Technical Support:**
- 📧 letstalk@soulitek.co.il
- 📖 Full Guide: `docs/CUSTOM_DOMAIN_SETUP.md`

---

## 🎉 You're Done!

Once set up, your install command is:

```powershell
iwr -useb get.soulitek.co.il | iex
```

**Easy to remember. Easy to share. Professional!** 🚀

---

**© 2025 SouliTEK - Made with ❤️ in Israel**

