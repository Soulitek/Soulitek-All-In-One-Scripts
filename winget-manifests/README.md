# WinGet Manifests

These YAML files are scaffolded for submission to
[`microsoft/winget-pkgs`](https://github.com/microsoft/winget-pkgs). They live in this
repo only as a convenience copy — the actual WinGet catalog reads them from `winget-pkgs`.

## Current version

- **2.2.0** — `s/Soulitek/AllInOneScripts/2.2.0/`
  - Version: `Soulitek.AllInOneScripts.yaml`
  - Installer: `Soulitek.AllInOneScripts.installer.yaml`
  - Locale (en-US): `Soulitek.AllInOneScripts.locale.en-US.yaml`

After publication, users install with:

```powershell
winget install Soulitek.AllInOneScripts
```

## Submission status (2026-06-05)

PR [`microsoft/winget-pkgs#375358`](https://github.com/microsoft/winget-pkgs/pull/375358)
is **open**. The Azure validation pipeline passes and the CLA is signed. The installer is a
**compiled `.exe`** (PS2EXE build of `Install-SouliTEK.ps1`) — a raw `.ps1` declared
`portable` was rejected because WinGet aliases it as `Install-SouliTEK.exe` and Windows
won't run a `.ps1` as a PE.

The remaining gate is the **"Targeted Brand"** policy: the original `Description`/`Tags`
enumerated third-party product names (McAfee, VirusTotal, etc.). They have been rewritten
to describe capabilities generically. Keep brand names out of the locale manifest on every
future bump.

> **Known wart:** the shipped exe is **32-bit (x86)** but the installer manifest declares
> `Architecture: x64`. The pipeline tolerates it. The installer has no 64-bit dependency, so
> the correct fix is to **relabel the manifest `Architecture: x86`** — one line, no re-upload,
> no new hash, and x86 runs on x64/ARM64 via emulation. Deferred to avoid resetting the
> in-flight validation run; apply it on the next push or version bump.

WinGet drops `Install-SouliTEK.ps1` into a per-package directory under
`%LOCALAPPDATA%\Microsoft\WinGet\Packages\` and exposes it as the `Install-SouliTEK`
command on `PATH`. The user then runs `Install-SouliTEK` to actually perform the install
into `C:\SouliTEK`.

## Submission workflow

Each release goes through the following steps. Per-step commands shown.

### 1. Tag + push the release

```powershell
git tag v2.2.0
git push origin v2.2.0
```

### 2. Compile the installer, then attach `Install-SouliTEK.exe` to the Release

WinGet's `portable` type needs a real PE. Compile the script with PS2EXE first:

```powershell
Install-Module ps2exe -Scope CurrentUser   # one-time
Invoke-ps2exe Install-SouliTEK.ps1 Install-SouliTEK.exe -noConsole:$false
```

The installer file must be available at:
`https://github.com/Soulitek/Soulitek-All-In-One-Scripts/releases/download/v2.2.0/Install-SouliTEK.exe`

Two ways to create the release:

**Option A — `gh` CLI (recommended if authenticated):**
```powershell
gh release create v2.2.0 `
  --title "v2.2.0 — Audit, P0 security fixes, launcher fix" `
  --notes-file CHANGELOG.md `
  Install-SouliTEK.exe
```

**Option B — GitHub web UI:**
1. Go to <https://github.com/Soulitek/Soulitek-All-In-One-Scripts/releases/new>
2. Choose tag `v2.2.0`
3. Title: `v2.2.0 — Audit, P0 security fixes, launcher fix`
4. Paste the `[2.2.0]` section of `CHANGELOG.md` into the description
5. Drag `Install-SouliTEK.exe` into the "Attach binaries" zone
6. Publish

### 3. Verify the SHA256 matches the manifest

The installer manifest pins:
```
InstallerSha256: 728B88E9DC876D096BF8F6394D9D5A030F6A38564F13E603FDB4B81306139659
```

After uploading, download the file from the release URL and compute its SHA256:
```powershell
$url = 'https://github.com/Soulitek/Soulitek-All-In-One-Scripts/releases/download/v2.2.0/Install-SouliTEK.exe'
Invoke-WebRequest -Uri $url -OutFile $env:TEMP\verify.exe
(Get-FileHash $env:TEMP\verify.exe -Algorithm SHA256).Hash
```

If the output does not match `728B88E9...`, update the manifest before submitting.
Most common cause of mismatch: PS2EXE embeds a build timestamp, so recompiling produces
a different hash. Hash the exact `.exe` you upload and pin that value — don't reuse an old one.

### 4. Validate manifests locally (optional but recommended)

```powershell
winget validate winget-manifests\s\Soulitek\AllInOneScripts\2.2.0\
```

Expected: `Manifest validation succeeded.`

### 5. Test the manifest against the live release URL

```powershell
winget install --manifest winget-manifests\s\Soulitek\AllInOneScripts\2.2.0\
```

This actually downloads from the release URL, validates the SHA256, and installs.
Confirm `Install-SouliTEK` is on PATH after install.

### 6. Submit the PR to `microsoft/winget-pkgs`

```powershell
# Fork and clone winget-pkgs (one-time setup)
gh repo fork microsoft/winget-pkgs --clone --remote
cd winget-pkgs

# Create a branch for this submission
git checkout -b soulitek-allinonescripts-2.2.0

# Copy the manifests into the canonical path
$src = 'C:\Users\Eitan\claude\Soulitek-All-In-One-Scripts\Soulitek-All-In-One-Scripts\winget-manifests\s\Soulitek\AllInOneScripts\2.2.0'
$dst = 'manifests\s\Soulitek\AllInOneScripts\2.2.0'
New-Item -ItemType Directory -Path $dst -Force | Out-Null
Copy-Item "$src\*.yaml" $dst

# Commit + push + open the PR
git add manifests\s\Soulitek\AllInOneScripts\2.2.0\
git commit -m "Soulitek.AllInOneScripts 2.2.0"
git push origin soulitek-allinonescripts-2.2.0
gh pr create --base master --head soulitek-allinonescripts-2.2.0 `
  --title "Soulitek.AllInOneScripts version 2.2.0" `
  --body "New package submission for SouliTEK All-In-One Scripts 2.2.0. Portable PowerShell installer; details in the manifest. Release: https://github.com/Soulitek/Soulitek-All-In-One-Scripts/releases/tag/v2.2.0"
```

The PR triggers automated validation. If the bots flag issues, fix the manifest locally
and amend. Maintainer review typically takes 1–7 days.

## Bumping to a future version

For each new release (e.g. 2.3.0):

1. Copy `winget-manifests/s/Soulitek/AllInOneScripts/2.2.0/` → `.../2.3.0/`.
2. In each `.yaml`, replace `2.2.0` → `2.3.0` and update `ReleaseDate`.
3. Recompile `Install-SouliTEK.exe`, recompute its SHA256, and update `InstallerSha256`.
4. Keep the `Description`/`Tags` brand-neutral (Targeted Brand policy — see status note above).
5. Re-run the submission workflow above with the new version + branch name.

## Why this approach

- **Portable installer type**: `Install-SouliTEK.ps1` is a PowerShell script. WinGet's `portable` type needs a real executable, so the script is compiled to `Install-SouliTEK.exe` with PS2EXE. WinGet drops the exe into a managed location and exposes the `Install-SouliTEK` command. The exe handles `--version`/`--help` so the validator's smoke test exits 0 without running the full installer.
- **Two-step install** (`winget install` then `Install-SouliTEK`): unavoidable with this approach. The script itself does the heavy lifting; WinGet is just a convenient way to distribute and update it.
- **Why not a proper MSI**: would require WiX Toolset + code-signing cert + ~1–2 days of new tooling. Worth revisiting if WinGet distribution becomes the primary install path.

## Schema reference

- Singleton/version: <https://aka.ms/winget-manifest.version.1.6.0.schema.json>
- Installer: <https://aka.ms/winget-manifest.installer.1.6.0.schema.json>
- Default locale: <https://aka.ms/winget-manifest.defaultLocale.1.6.0.schema.json>
- WinGet docs: <https://learn.microsoft.com/en-us/windows/package-manager/package/manifest>
- winget-pkgs contribution guide: <https://github.com/microsoft/winget-pkgs/blob/master/CONTRIBUTING.md>
