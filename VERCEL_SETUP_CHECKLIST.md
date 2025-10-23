# ✅ Vercel Setup Checklist - Quick Reference

## 🎯 Goal
Make this work: `iwr -useb get.soulitek.co.il | iex`

---

## ✅ What's Done (Automated)

- ✅ `vercel.json` created
- ✅ Documentation updated
- ✅ README.md updated with new command

---

## 📋 What YOU Need to Do

### 1. ⚡ Push to GitHub (2 minutes)

```bash
git add .
git commit -m "Add Vercel deployment configuration"
git push origin main
```

---

### 2. 🌐 Vercel Signup & Deploy (5 minutes)

1. Go to: **https://vercel.com**
2. Click: **"Sign Up"** → **"Continue with GitHub"**
3. Click: **"Add New..."** → **"Project"**
4. Find: **`Soulitek-AIO`** → Click **"Import"**
5. Click: **"Deploy"** (use all default settings)
6. Wait 30 seconds ✅

**Result:** You get a URL like `https://soulitek-installer.vercel.app`

---

### 3. 🔗 Add Custom Domain (2 minutes)

1. In Vercel project: **Settings** → **Domains**
2. Enter: `get.soulitek.co.il`
3. Click: **"Add"**

**Result:** Vercel shows DNS instructions

---

### 4. 🔧 Update DNS (5 minutes + propagation time)

**Add this CNAME record at your domain registrar:**

```
Type: CNAME
Name: get
Value: cname.vercel-dns.com
```

**Where?** Find where `soulitek.co.il` is registered:
- Namecheap? → Advanced DNS → Add Record
- GoDaddy? → DNS → Add CNAME
- Cloudflare? → DNS → Add Record (gray cloud!)

---

### 5. ⏱️ Wait for DNS (10-30 minutes)

**Check status:**
```powershell
nslookup get.soulitek.co.il
```

**Or:** Visit https://dnschecker.org

---

### 6. 🎉 Test It!

```powershell
iwr -useb get.soulitek.co.il | iex
```

**✅ Done!**

---

## 📖 Detailed Guide

See: `docs/VERCEL_DEPLOYMENT.md` for complete step-by-step instructions with screenshots.

---

## 🆘 Quick Troubleshooting

**Domain not working after 30 min?**
```powershell
nslookup get.soulitek.co.il
# Should show: cname.vercel-dns.com
```

**Still not working?**
1. Double-check DNS record (exact: `cname.vercel-dns.com`)
2. Wait 24 hours for full propagation
3. Check Vercel → Domains for status

---

## ⏰ Time Estimate

- GitHub push: 2 min
- Vercel setup: 5 min
- DNS update: 5 min
- **Waiting for DNS: 10-30 min** ⏱️
- Testing: 2 min

**Total active time: ~15 minutes**
**Total elapsed time: ~30-60 minutes**

---

**Next:** Follow `docs/VERCEL_DEPLOYMENT.md` for detailed instructions!

**© 2025 SouliTEK**

