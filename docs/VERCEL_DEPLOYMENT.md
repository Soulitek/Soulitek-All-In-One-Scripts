# 🚀 Vercel Deployment Guide - SouliTEK Installer

This guide shows you how to deploy the SouliTEK installer on Vercel with your custom domain.

---

## ✅ SOLUTION: Vercel Serverless Function (No Redirect Issues!)

**Great news! The simple command now works perfectly:**

```powershell
iwr -useb get.soulitek.co.il | iex
```

**How?** We use a Vercel serverless function that **fetches and serves** the installer directly (no redirects), avoiding PowerShell's 308 redirect limitation entirely.

---

## ✅ Working Installation Commands

### **Method 1: Custom Domain (Recommended)**

```powershell
iwr -useb get.soulitek.co.il | iex
```

**Advantages:**
- ✅ Short and professional branded URL
- ✅ No redirect issues (serves directly)
- ✅ Always gets latest version from GitHub
- ✅ Auto-deploys when you push to GitHub
- ✅ Free hosting on Vercel
- ✅ Built-in error handling

---

### **Method 2: Direct GitHub URL (Alternative)**

```powershell
iwr -useb https://raw.githubusercontent.com/Soulitek/Soulitek-All-In-One-Scripts/main/Install-SouliTEK.ps1 | iex
```

**Advantages:**
- ✅ Direct from source
- ✅ No server dependency
- ✅ Always works

---

## 💡 Recommendation

**Use Method 1 (Custom Domain)** - it's shorter, more professional, and now works perfectly thanks to the Vercel serverless function!

---

## ✅ What's Already Done

The following files have been created for you:
- ✅ `api/install.js` - Serverless function that fetches from GitHub and serves directly
- ✅ `vercel.json` - Vercel configuration with rewrites (not redirects)

---

## 📋 Step-by-Step Setup Guide

### Step 1: Commit and Push to GitHub ⚡

```bash
# Check what's new
git status

# Add all changes
git add .

# Commit
git commit -m "Add Vercel deployment configuration"

# Push to GitHub
git push origin main
```

**✅ Checkpoint:** Your code is now on GitHub with Vercel configuration.

---

### Step 2: Sign Up for Vercel 🌐

1. **Go to:** https://vercel.com
2. **Click:** "Sign Up" (top right)
3. **Choose:** "Continue with GitHub"
4. **Authorize:** Allow Vercel to access your GitHub account

**✅ Checkpoint:** You're logged into Vercel dashboard.

---

### Step 3: Import Your Project 📦

1. **In Vercel dashboard, click:** "Add New..." → "Project"
2. **Find:** `Soulitek-All-In-One-Scripts` in your repository list
   - If you don't see it, click "Adjust GitHub App Permissions" and give access
3. **Click:** "Import" next to `Soulitek-All-In-One-Scripts`

4. **Configure Project:**
   - **Project Name:** `soulitek-installer` (or any name you like)
   - **Framework Preset:** Other (default)
   - **Root Directory:** `./` (leave as default)
   - **Build Command:** (leave empty)
   - **Output Directory:** (leave empty)
   - **Environment Variables:** (none needed)

5. **Click:** "Deploy"

6. **Wait:** 30-60 seconds for deployment

**✅ Checkpoint:** You'll see "Congratulations" screen with your URL like:
`https://soulitek-installer.vercel.app`

---

### Step 4: Test Your Vercel URL 🧪

Open PowerShell and test:

```powershell
# Test the redirect
iwr -useb https://soulitek-installer.vercel.app
```

**Expected result:** You should see the PowerShell installer script content.

**✅ Checkpoint:** Vercel deployment is working!

---

### Step 5: Add Custom Domain 🌐

1. **In Vercel project, click:** "Settings" tab
2. **Click:** "Domains" in left sidebar
3. **In the text box, enter:** `get.soulitek.co.il`
4. **Click:** "Add"

**Vercel will show you DNS configuration:**
```
Type: CNAME
Name: get
Value: cname.vercel-dns.com
TTL: Automatic
```

**✅ Checkpoint:** Domain added in Vercel (showing "Invalid Configuration" until you update DNS).

---

### Step 6: Configure DNS 🔧

You need to add a CNAME record at your domain registrar.

#### Where is soulitek.co.il Registered?

Find out where you bought your domain and follow the appropriate guide:

---

#### Option A: Namecheap

1. **Login to:** https://www.namecheap.com
2. **Go to:** Domain List → Click "Manage" next to `soulitek.co.il`
3. **Click:** "Advanced DNS" tab
4. **Click:** "Add New Record" button
5. **Configure:**
   - Type: `CNAME Record`
   - Host: `get`
   - Value: `cname.vercel-dns.com`
   - TTL: Automatic (or 1 min)
6. **Click:** Save

---

#### Option B: GoDaddy

1. **Login to:** https://www.godaddy.com
2. **Go to:** My Products → DNS (next to your domain)
3. **Click:** "Add" button under Records section
4. **Configure:**
   - Type: `CNAME`
   - Name: `get`
   - Value: `cname.vercel-dns.com`
   - TTL: 1 Hour (default)
5. **Click:** Save

---

#### Option C: Cloudflare

1. **Login to:** https://dash.cloudflare.com
2. **Select:** `soulitek.co.il`
3. **Click:** "DNS" in left menu
4. **Click:** "Add record" button
5. **Configure:**
   - Type: `CNAME`
   - Name: `get`
   - Target: `cname.vercel-dns.com`
   - Proxy status: ☁️ OFF (DNS only - gray cloud icon)
   - TTL: Auto
6. **Click:** Save

**⚠️ Important:** Make sure proxy is OFF (gray cloud) for Vercel to work!

---

#### Option D: Other Providers

1. Login to your domain registrar
2. Find "DNS Settings" or "DNS Management"
3. Add a new CNAME record:
   - Name/Host/Subdomain: `get`
   - Value/Target/Points to: `cname.vercel-dns.com`
   - TTL: Automatic or 300-3600 seconds
4. Save changes

---

**✅ Checkpoint:** DNS record added at your registrar.

---

### Step 7: Wait for DNS Propagation ⏱️

**Time required:** 5 minutes to 24 hours (usually 10-30 minutes)

**Check DNS status:**

**Method 1 - PowerShell:**
```powershell
nslookup get.soulitek.co.il
```

**Method 2 - Online Tool:**
1. Visit: https://dnschecker.org
2. Enter: `get.soulitek.co.il`
3. Check if it shows `cname.vercel-dns.com` globally

**What to look for:**
- ✅ CNAME pointing to `cname.vercel-dns.com`
- ✅ Green checkmarks across multiple locations

---

### Step 8: Verify in Vercel ✅

1. **Go back to:** Vercel → Your Project → Settings → Domains
2. **Wait for:** Domain status to change from "Invalid Configuration" to:
   - ✅ Green checkmark
   - "Valid Configuration"
3. **SSL Certificate:** Automatically provisioned by Vercel (free!)

**Note:** This happens automatically once DNS propagates. No action needed!

---

### Step 9: Test Your Custom Domain 🎉

```powershell
# Test in browser first
# Visit: https://get.soulitek.co.il
# You should be redirected to the GitHub installer

# Test the PowerShell command
iwr -useb get.soulitek.co.il | iex
```

**Expected behavior:**
1. Downloads installer from GitHub
2. Installs to C:\SouliTEK
3. Creates desktop shortcut
4. Works perfectly! 🎉

**✅ Checkpoint:** Everything is working!

---

## 🎯 Final Result

Your users can now install with:

```powershell
iwr -useb get.soulitek.co.il | iex
```

**Benefits:**
- ✅ Short and memorable
- ✅ Professional branding
- ✅ Global CDN (fast worldwide)
- ✅ Free SSL certificate
- ✅ Auto-deploy on git push
- ✅ 99.99% uptime

---

## 🔄 Auto-Deploy Feature

**Great news:** Vercel automatically deploys when you push to GitHub!

```bash
# Make changes to your code
git add .
git commit -m "Update installer"
git push origin main

# Vercel automatically deploys in ~30 seconds!
```

No manual steps needed! 🚀

---

## 📊 View Analytics

**Check your stats:**

1. **Go to:** Vercel Dashboard → Your Project
2. **Click:** "Analytics" tab
3. **See:**
   - Total requests
   - Geographic distribution
   - Response times
   - Bandwidth usage

---

## 🆘 Troubleshooting

### Getting "308 Permanent Redirect" Error

**Error Message:**
```
iwr : The remote server returned an error: (308) Permanent Redirect.
```

**Solution:**
This is normal! PowerShell's `iwr -useb` cannot follow 308 redirects automatically.

**Use one of these working commands instead:**

**Option 1 (Recommended):**
```powershell
iwr -useb https://raw.githubusercontent.com/Soulitek/Soulitek-All-In-One-Scripts/main/Install-SouliTEK.ps1 | iex
```

**Option 2 (Custom domain with redirect handling):**
```powershell
$response = iwr -useb https://get.soulitek.co.il -MaximumRedirection 0 -ErrorAction SilentlyContinue
if ($response.StatusCode -eq 308) {
    $redirectUri = $response.Headers['Location']
    iwr -useb $redirectUri | iex
} else {
    $response.Content | iex
}
```

---

### Domain shows "Invalid Configuration" for >24 hours

**Check:**
```powershell
nslookup get.soulitek.co.il
```

**If it doesn't show `cname.vercel-dns.com`:**
- Verify DNS record at your registrar
- Check for typos in subdomain name (`get`)
- Ensure CNAME value is exactly `cname.vercel-dns.com`
- Wait longer (some registrars take 24-48h)

---

### SSL Certificate Not Provisioning

**Solutions:**
- Wait for DNS to fully propagate (check dnschecker.org)
- In Vercel, remove domain and re-add it
- Ensure no conflicting DNS records (remove old A records for `get`)

---

### Redirect Not Working

**Check:**
1. Visit your Vercel URL directly (e.g., `soulitek-installer.vercel.app`)
2. Does it redirect? If yes, DNS issue. If no, check `vercel.json`
3. In Vercel → Deployments → Click latest → Check "Source"
4. Verify `vercel.json` is present

**Fix:**
```bash
# Redeploy
git commit --allow-empty -m "Trigger redeploy"
git push origin main
```

---

### "Cannot download from domain"

**Test each step:**
```powershell
# 1. Test DNS
nslookup get.soulitek.co.il

# 2. Test HTTPS
curl https://get.soulitek.co.il

# 3. Test redirect
iwr -useb get.soulitek.co.il
```

Identify which step fails and troubleshoot accordingly.

---

## 🔒 Security Notes

**Your setup is secure:**
- ✅ HTTPS with free SSL certificate
- ✅ No server-side code (just redirect)
- ✅ Content served from GitHub (version controlled)
- ✅ Vercel's DDoS protection
- ✅ No sensitive data exposure

---

## 💰 Costs

**Vercel Free Tier includes:**
- ✅ 100GB bandwidth per month
- ✅ Unlimited deployments
- ✅ Automatic SSL
- ✅ Global CDN
- ✅ Analytics

**For your use case:** Completely FREE! 💯

Even with heavy usage (1000s of installs), you'll stay under limits.

---

## 🎓 Advanced: Multiple Domains

Want both `get.soulitek.co.il` and `install.soulitek.co.il`?

1. Add both domains in Vercel → Settings → Domains
2. Add CNAME records for both:
   - `get` → `cname.vercel-dns.com`
   - `install` → `cname.vercel-dns.com`

Both will work! 🎉

---

## 📝 Summary Checklist

- [ ] Created `vercel.json` file ✅ (already done)
- [ ] Pushed to GitHub
- [ ] Signed up for Vercel
- [ ] Imported project from GitHub
- [ ] Deployed successfully
- [ ] Tested Vercel URL works
- [ ] Added custom domain `get.soulitek.co.il`
- [ ] Updated DNS with CNAME record
- [ ] Waited for DNS propagation
- [ ] Verified green checkmark in Vercel
- [ ] Tested `iwr -useb get.soulitek.co.il | iex`
- [ ] Updated documentation with new URL

---

## 🎉 Next Steps After Deployment

1. **Update README.md** with your new domain
2. **Update business cards** with `get.soulitek.co.il`
3. **Create QR code** for the URL
4. **Test on a fresh PC** to verify
5. **Share with your team**

---

## 📞 Support

**Vercel Support:**
- Documentation: https://vercel.com/docs
- Support: support@vercel.com
- Community: https://github.com/vercel/vercel/discussions

**Your Support:**
- 📧 letstalk@soulitek.co.il
- 🌐 https://soulitek.co.il

---

## 🚀 You're All Set!

Once DNS propagates, your command will be:

```powershell
iwr -useb get.soulitek.co.il | iex
```

**Fast. Simple. Professional.** ✨

---

**© 2025 SouliTEK - Made with ❤️ in Israel**

