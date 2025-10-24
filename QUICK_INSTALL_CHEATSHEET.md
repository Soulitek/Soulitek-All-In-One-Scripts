# 🚀 SouliTEK Quick Install - Cheat Sheet

---

## One-Line Installation

**✅ Recommended (Direct GitHub - Always Works):**
```powershell
iwr -useb https://raw.githubusercontent.com/Soulitek/Soulitek-All-In-One-Scripts/main/Install-SouliTEK.ps1 | iex
```

<details>
<summary>📌 Alternative: Custom Domain with Redirect Handling</summary>

**⚠️ Note:** The simple command `iwr -useb get.soulitek.co.il | iex` does NOT work due to PowerShell's 308 redirect limitation.

Use this instead if you prefer the custom domain:
```powershell
$response = iwr -useb https://get.soulitek.co.il -MaximumRedirection 0 -ErrorAction SilentlyContinue
if ($response.StatusCode -eq 308) {
    $redirectUri = $response.Headers['Location']
    iwr -useb $redirectUri | iex
} else {
    $response.Content | iex
}
```
</details>

---

## What It Does

1. ✅ Downloads latest version from GitHub
2. ✅ Installs to `C:\SouliTEK`
3. ✅ Creates desktop shortcut
4. ✅ Launches GUI (optional)

---

## How to Use

### On a New PC:

1. Open PowerShell
2. Paste the command above
3. Press Enter
4. Follow the prompts
5. Done! 🎉

---

## Running as Administrator (Recommended)

1. Press `Win + X`
2. Select "Windows PowerShell (Admin)"
3. Paste the install command
4. Press Enter

---

## After Installation

**Desktop Shortcut:** `SouliTEK Launcher`

**Manual Launch:**
```powershell
C:\SouliTEK\SouliTEK-Launcher.ps1
```

---

## Updating

Simply run the install command again - it will update to the latest version automatically.

---

## Quick Links

- 🌐 Website: https://soulitek.co.il
- 📧 Email: letstalk@soulitek.co.il
- 💻 GitHub: https://github.com/Soulitek/Soulitek-All-In-One-Scripts
- 📖 Full Guide: [QUICK_INSTALL.md](docs/QUICK_INSTALL.md)

---

**© 2025 SouliTEK - Made with ❤️ in Israel**


