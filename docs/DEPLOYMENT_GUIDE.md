# 🚀 SouliTEK Deployment Guide

Complete deployment checklist for SouliTEK All-In-One Scripts with both GitHub and Vercel options.

---

## 🎯 Deployment Options

### Option 1: GitHub Only (Simple)
- Direct GitHub URL installation
- No custom domain setup required
- Works immediately after push

### Option 2: GitHub + Vercel (Professional)
- Custom domain installation (get.soulitek.co.il)
- Professional branded URL
- Enhanced error handling and analytics

---

## ✅ Pre-Deployment Checklist

### 1. Verify Repository Configuration

**Current Configuration:**
- **Repository:** `Soulitek/Soulitek-All-In-One-Scripts`
- **Branch:** `main`

**Action Required:**
- If your GitHub repo has a different name, update line 36 in `Install-SouliTEK.ps1`:
  ```powershell
  $RepoName = "Soulitek-All-In-One-Scripts"  # Change to your actual repo name
  ```

### 2. Commit All Changes

```bash
git add .
git commit -m "Add URL-based quick installer"
```

### 3. Push to GitHub

```bash
git push origin main
```

**Important:** The `Install-SouliTEK.ps1` file MUST be in the root of your repository for URL installation to work.

---

## 🧪 Testing Installation

### Test on Fresh Machine

1. Open PowerShell (as Administrator recommended)
2. Run the install command:
   ```powershell
   iwr -useb https://raw.githubusercontent.com/Soulitek/Soulitek-All-In-One-Scripts/main/Install-SouliTEK.ps1 | iex
   ```
3. Verify:
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

## 🌐 Vercel Setup (Optional - For Custom Domain)

### Step 1: Vercel Signup & Deploy (5 minutes)

1. Go to: **https://vercel.com**
2. Sign up with GitHub account
3. Click "New Project"
4. Import your `Soulitek-All-In-One-Scripts` repository
5. Click "Deploy" (uses default settings)
6. Wait for deployment to complete (~2 minutes)

### Step 2: Custom Domain Setup (10 minutes)

1. In Vercel dashboard, go to your project
2. Click "Settings" → "Domains"
3. Add your domain: `get.soulitek.co.il`
4. Follow DNS configuration instructions
5. Wait for DNS propagation (5-30 minutes)

### Step 3: Test Custom Domain

```powershell
# Test the custom domain
iwr -useb get.soulitek.co.il | iex
```

**Expected:** Should work exactly like the GitHub URL but with your branded domain.

---

## 📊 Repository Name Detection

**To check your actual GitHub repository name:**

```bash
# From your project directory, run:
git remote -v
```

This will show you the URL. For example:
- `https://github.com/Soulitek/Soulitek-All-In-One-Scripts.git` → Repo name is `Soulitek-All-In-One-Scripts`

**Update the installer accordingly!**

---

## 🌐 Creating Short URLs (Alternative to Vercel)

### Using bit.ly

1. Go to https://bit.ly
2. Sign in or create account
3. Create new link:
   - **Long URL:** `https://raw.githubusercontent.com/Soulitek/Soulitek-All-In-One-Scripts/main/Install-SouliTEK.ps1`
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
- **URL:** `javascript:navigator.clipboard.writeText('iwr -useb https://raw.githubusercontent.com/Soulitek/Soulitek-All-In-One-Scripts/main/Install-SouliTEK.ps1 | iex')`

Clicking it copies the command to clipboard!

---

## 🔒 Security Considerations

### For Customers

**Explain to customers:**
```
This command downloads and runs a script from our official GitHub repository.
You can review the script first at:
https://github.com/Soulitek/Soulitek-All-In-One-Scripts/blob/main/Install-SouliTEK.ps1

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

### GitHub Deployment
- [ ] `Install-SouliTEK.ps1` is committed to your repo
- [ ] Repository name is correct in the script
- [ ] Script is pushed to GitHub `main` branch
- [ ] Tested installation on a fresh PC
- [ ] Desktop shortcut works
- [ ] All 11 tools are accessible from GUI
- [ ] README.md shows the install command
- [ ] Documentation is up to date

### Vercel Deployment (Optional)
- [ ] Vercel project created and deployed
- [ ] Custom domain configured
- [ ] DNS propagation complete
- [ ] Custom domain command tested
- [ ] Analytics working (optional)

### Marketing
- [ ] Short URL created (optional)
- [ ] QR code generated (optional)
- [ ] Team members informed of new install method
- [ ] Customer support guides updated

---

## 🆘 Troubleshooting

### "Cannot download from GitHub"
- Check internet connection
- Verify repository is public
- Try: `Test-NetConnection raw.githubusercontent.com -Port 443`

### "Access denied to C:\SouliTEK"
- Run PowerShell as Administrator
- Or change install path in script to user directory

### "Script not found after install"
- Verify files in: `C:\SouliTEK`
- Check if antivirus quarantined files
- Rerun installer

### "Custom domain doesn't work"
- Wait 5-10 minutes for DNS propagation
- Check Vercel deployment status
- Clear DNS cache: `ipconfig /flushdns`

---

## 📞 Support

If you need help with deployment:
- 🌐 https://soulitek.co.il
- 📧 letstalk@soulitek.co.il

---

**© 2025 SouliTEK - Made with ❤️ in Israel**

**Note:** DEPLOYMENT_CHECKLIST.md and VERCEL_SETUP_CHECKLIST.md have been merged into this comprehensive deployment guide for better organization.
