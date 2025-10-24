# 308 Permanent Redirect Error - SOLVED!

## ✅ **SOLUTION IMPLEMENTED - Custom Domain Now Works!**

**The problem has been solved!** You can now use:
```powershell
iwr -useb get.soulitek.co.il | iex
```

**How?** We implemented a Vercel serverless function that serves the installer directly (no redirect), avoiding PowerShell's limitation entirely.

**See:** `api/install.js` - The serverless function that makes this work.

---

## 📜 Historical Context

### ❌ The Original Problem

When users tried to run:
```powershell
iwr -useb get.soulitek.co.il | iex
```

They got this error:
```
iwr : The remote server returned an error: (308) Permanent Redirect.
At line:1 char:1
+ iwr -useb get.soulitek.co.il | iex
+ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : InvalidOperation: (System.Net.HttpWebRequest:HttpWebRequest) [Invoke-WebRequest], WebException
    + FullyQualifiedErrorId : WebCmdletWebResponseException,Microsoft.PowerShell.Commands.InvokeWebRequestCommand
```

---

## 🔍 Root Cause

**This is a PowerShell limitation, not a server configuration issue.**

PowerShell's `Invoke-WebRequest` (iwr) with the `-UseBasicParsing` (-useb) flag **cannot automatically follow HTTP 308 (Permanent Redirect) responses**. 

- HTTP 308 is a permanent redirect status code
- Vercel (and many CDNs) use 308 redirects for URL forwarding
- PowerShell 5.1's `iwr -useb` doesn't handle these redirects automatically
- Even changing to 301/302 redirects won't fix it with `-UseBasicParsing`

---

## ✅ CURRENT SOLUTION: Vercel Serverless Function (BEST)

**We've implemented a Vercel serverless function that completely eliminates the redirect issue!**

### How It Works:
```javascript
// api/install.js
export default async function handler(req, res) {
  // 1. Fetch installer from GitHub server-side
  const response = await fetch('https://raw.githubusercontent.com/...');
  const script = await response.text();
  
  // 2. Serve directly to PowerShell (no redirect!)
  res.setHeader('Content-Type', 'text/plain');
  res.status(200).send(script);
}
```

### Usage:
```powershell
# Simple command that now works perfectly!
iwr -useb get.soulitek.co.il | iex
```

### ✅ **Advantages:**
- Short, branded URL
- No redirect issues
- Always gets latest version
- Auto-deploys on git push
- Free hosting on Vercel
- Professional appearance

---

## ✅ Alternative: Direct GitHub URL

**Use the direct GitHub raw URL instead of the custom domain:**

```powershell
iwr -useb https://raw.githubusercontent.com/Soulitek/Soulitek-All-In-One-Scripts/main/Install-SouliTEK.ps1 | iex
```

**Advantages:**
- ✅ Always works (no redirects)
- ✅ Faster (direct download)
- ✅ Simpler to remember and type
- ✅ No server configuration needed
- ✅ Best for documentation

**This is the recommended command for all customers and documentation.**

---

## ✅ Solution 2: Custom Domain with Manual Redirect Handling

If you really want to use the custom domain for branding, use this script:

```powershell
$response = iwr -useb https://get.soulitek.co.il -MaximumRedirection 0 -ErrorAction SilentlyContinue
if ($response.StatusCode -eq 308) {
    $redirectUri = $response.Headers['Location']
    iwr -useb $redirectUri | iex
} else {
    $response.Content | iex
}
```

**How it works:**
1. Makes request with `-MaximumRedirection 0` (don't follow redirects)
2. Catches the 308 response
3. Extracts the redirect target from headers
4. Makes a second request to the actual URL
5. Executes the script

**Disadvantages:**
- ⚠️ More complex
- ⚠️ Harder to type
- ⚠️ Requires user to understand the script

---

## 📝 Why Not Fix It Server-Side?

**This cannot be fixed server-side.** Here's why:

1. **PowerShell Limitation**: The `-UseBasicParsing` flag is required for systems without IE installed (most modern Windows), but it doesn't support automatic redirect following for any status code when piped directly to `iex`.

2. **No Direct Hosting**: We can't host the `.ps1` file directly on Vercel because Vercel is designed for static sites and serverless functions, not raw text file serving with proper headers.

3. **Alternative Approaches All Have Issues**:
   - Using 301/302 redirects: Still doesn't work with `-UseBasicParsing`
   - Using Vercel Functions: Requires API endpoint, not a simple URL
   - Using proxy: Adds complexity and latency
   - Using iframe/meta redirect: Doesn't work for raw script downloads

---

## 🎯 Recommendation

**Use Solution 1 (Direct GitHub URL) for everything:**

- Documentation
- Customer emails
- Training materials
- Quick reference guides
- Business cards
- Website

**Why?**
- It's simpler
- It always works
- It's faster
- It's more reliable
- GitHub provides global CDN
- No dependency on custom domain DNS

---

## 📚 Updated Documentation

The following files have been updated to reflect this:

1. ✅ `workflow_state.md` - Updated with clear explanation
2. ✅ `docs/VERCEL_DEPLOYMENT.md` - Added warning at top and troubleshooting section
3. ✅ `README.md` - Already shows correct command
4. ✅ `QUICK_INSTALL_CHEATSHEET.md` - Updated with warning
5. ✅ `docs/QUICK_INSTALL.md` - Updated repository URLs
6. ✅ `docs/308_REDIRECT_ISSUE.md` - This file (new)

---

## 🚀 Action Items

1. **Update any printed materials** with the direct GitHub URL
2. **Update website** if it shows the custom domain command
3. **Train support staff** on the correct command
4. **Update customer communications** with the working command
5. **Add to FAQ** if you have one

---

## ❓ FAQ

### Can we make the URL shorter?
Yes, you could use a URL shortener like bit.ly or create your own:
- `bit.ly/soulitek` → redirects to the GitHub URL
- But users might be suspicious of shortened URLs
- The GitHub URL is already relatively short

### Can we use a different file hosting service?
Yes, you could host on:
- **GitHub Gists** (similar to raw GitHub)
- **Azure Blob Storage** (with proper CORS headers)
- **AWS S3** (with proper CORS headers)
- **Your own web server** (with proper headers)

But they all have the same issue: PowerShell's `-useb` flag limitation.

### What about PowerShell Core (7.x)?
PowerShell Core 7.x handles redirects better, but:
- Most Windows systems still use PowerShell 5.1
- You can't assume users have PowerShell 7
- Compatibility is important

---

## 📞 Support

If users still have issues with the direct GitHub URL, check:

1. **Internet connectivity**
   ```powershell
   Test-Connection github.com
   ```

2. **Firewall/proxy blocking GitHub**
   ```powershell
   iwr https://github.com
   ```

3. **Execution policy**
   ```powershell
   Get-ExecutionPolicy
   # Should be RemoteSigned or Unrestricted
   ```

4. **PowerShell version**
   ```powershell
   $PSVersionTable.PSVersion
   # Should be 5.1 or higher
   ```

---

**© 2025 SouliTEK - Made with ❤️ in Israel**

