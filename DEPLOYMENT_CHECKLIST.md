# 🚀 SouliTEK Deployment Checklist

This checklist ensures the URL-based installation works correctly.

---

## ✅ Pre-Deployment Steps

### 1. Verify Repository Name

The installer is currently configured for:
- **Repository:** `Soulitek/Soulitek-AIO`
- **Branch:** `main`

**Action Required:**
- If your GitHub repo has a different name, update line 36 in `Install-SouliTEK.ps1`:
  ```powershell
  $RepoName = "Soulitek-AIO"  # Change to your actual repo name
  ```

### 2. Commit All Changes

```powershell
git add .
git commit -m "Add URL-based quick installer"
```

### 3. Push to GitHub

```powershell
git push origin main
```

**Important:** The `Install-SouliTEK.ps1` file MUST be in the root of your repository for the URL installation to work.

---

## 🧪 Testing the Installation

### Test on a Fresh Machine

1. Open PowerShell (as Administrator recommended)

2. Run the install command:
   ```powershell
   iwr -useb https://raw.githubusercontent.com/Soulitek/Soulitek-AIO/main/Install-SouliTEK.ps1 | iex
   ```

3. Verify it:
   - ✅ Downloads successfully
   - ✅ Extracts to C:\SouliTEK
   - ✅ Creates desktop shortcut
   - ✅ Launcher GUI opens
   - ✅ All tools are accessible

### Test Update Scenario

1. Modify a file in the repo
2. Commit and push to GitHub
3. Run the install command again
4. Verify it updates to the new version

---

## 📝 Repository Name Detection

**To check your actual GitHub repository name:**

```powershell
# From your project directory, run:
git remote -v
```

This will show you the URL. For example:
- `https://github.com/Soulitek/Soulitek-AIO.git` → Repo name is `Soulitek-AIO`
- `https://github.com/Soulitek/Soulitek-All-In-One-Scripts.git` → Repo name is `Soulitek-All-In-One-Scripts`

**Update the installer accordingly!**

---

## 🌐 Creating Short URLs (Optional)

Make it easier to type by creating short URLs:

### Using bit.ly

1. Go to https://bit.ly
2. Sign in or create account
3. Create new link:
   - **Long URL:** `https://raw.githubusercontent.com/Soulitek/Soulitek-AIO/main/Install-SouliTEK.ps1`
   - **Custom name:** `soulitek-install`
4. Result: `https://bit.ly/soulitek-install`

**Then users can run:**
```powershell
iwr -useb bit.ly/soulitek-install | iex
```

### Using TinyURL

1. Go to https://tinyurl.com
2. Paste the long URL
3. Customize the alias: `soulitek-install`
4. Create!

### Using Your Own Domain

If you own `soulitek.co.il`, set up a redirect:
- From: `https://get.soulitek.co.il/install`
- To: `https://raw.githubusercontent.com/Soulitek/Soulitek-AIO/main/Install-SouliTEK.ps1`

---

## 📢 Sharing with Customers

### Option 1: QR Code

1. Go to https://www.qr-code-generator.com/
2. Select "Text" or "URL"
3. Paste the install command or short URL
4. Download QR code
5. Print on business cards or show on phone

### Option 2: Documentation

Add to your:
- Internal wiki
- Customer onboarding docs
- Support ticket templates
- Email signatures

### Option 3: Bookmark

Create a browser bookmark with:
- **Name:** "SouliTEK Install Command"
- **URL:** `javascript:navigator.clipboard.writeText('iwr -useb https://raw.githubusercontent.com/Soulitek/Soulitek-AIO/main/Install-SouliTEK.ps1 | iex')`

Clicking it copies the command to clipboard!

---

## 🔒 Security Considerations

### For Customers

**Explain to customers:**
```
This command downloads and runs a script from our official GitHub repository.
You can review the script first at:
https://github.com/Soulitek/Soulitek-AIO/blob/main/Install-SouliTEK.ps1

The script will:
1. Download our latest tools
2. Install to C:\SouliTEK
3. Create a desktop shortcut
4. NOT modify system settings or install malware

It's 100% safe and open source.
```

### Code Signing (Optional - Advanced)

For enterprise customers, consider:
1. Get a code signing certificate
2. Sign `Install-SouliTEK.ps1`
3. Publish signed version to GitHub

---

## 📋 Final Checklist

Before going live, verify:

- [ ] `Install-SouliTEK.ps1` is committed to your repo
- [ ] Repository name is correct in the script
- [ ] Script is pushed to GitHub `main` branch
- [ ] Tested installation on a fresh PC
- [ ] Desktop shortcut works
- [ ] All 11 tools are accessible from GUI
- [ ] README.md shows the install command
- [ ] Documentation is up to date
- [ ] Short URL created (optional)
- [ ] QR code generated (optional)
- [ ] Team members informed of new install method

---

## 🎯 Marketing the Feature

### Social Media Post Template

```
🚀 New Feature: One-Line Installation!

Setting up a new PC? Just open PowerShell and run:
iwr -useb [short-url] | iex

That's it! All 11 tools installed and ready in seconds.

#ITTools #PowerShell #SouliTEK #TechSupport
```

### Email Signature

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Quick Install: bit.ly/soulitek-install
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## 🆘 Troubleshooting

If installation fails, check:

1. **GitHub Access:**
   - Can you access https://github.com/Soulitek/Soulitek-AIO ?
   - Is the repository public or private?
   - If private, users need authentication

2. **Firewall:**
   - Is `raw.githubusercontent.com` blocked?
   - Try from different network

3. **PowerShell Version:**
   - Run: `$PSVersionTable.PSVersion`
   - Should be 5.1 or higher

4. **Execution Policy:**
   - Run: `Get-ExecutionPolicy`
   - If Restricted, run as admin: `Set-ExecutionPolicy RemoteSigned`

---

## 📞 Support

If you need help with deployment:
- 🌐 https://soulitek.co.il
- 📧 letstalk@soulitek.co.il

---

**Ready to deploy? Let's go! 🚀**

© 2025 SouliTEK - Made with ❤️ in Israel


