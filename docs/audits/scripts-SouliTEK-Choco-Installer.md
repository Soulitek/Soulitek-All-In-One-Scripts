# Audit — scripts/SouliTEK-Choco-Installer.ps1

## Inventory
| Item | Value |
|---|---|
| Path           | scripts/SouliTEK-Choco-Installer.ps1 |
| LOC            | 790 (769 non-blank) |
| Functions      | 13 |
| `#Requires`    | none |
| Admin-required | yes (script self-elevates via `Ensure-Admin`/`Start-Process -Verb RunAs` at line 84; installs MSI/MSIX packages, mutates `HKLM:` indirectly via WinGet, and offers `shutdown /r` at line 669) |
| Last touched   | d36c587 — 2025-12-16 (re-added; previously deleted at `542ac7d` on 2025-11-22 — see F4) |
| Modernization grade | B |

## Summary

A 790-line interactive WinGet installer with a TUI menu, JSON-preset support, an Office-2024 hard-coded ProPlus-Hebrew side-channel download, and a JSON result summary written to the user's Desktop. **The filename is a lie** — the script name says "Choco" and the SYNOPSIS block at lines 2–4 still says "Chocolatey", but every code path (`Ensure-WinGet`, `Install-Packages`, the `Microsoft.WinGet.Client` module install, the `winget --version`/`winget list`/`winget install` calls) targets WinGet, not Chocolatey. Chocolatey is not referenced anywhere in the body.

The dominant issue dwarfs the C1/C4 hotspots: **the script is dead code that was deliberately deleted at commit `542ac7d` on 2025-11-22** ("Remove the outdated SouliTEK Chocolatey Installer script to streamline project resources") **and then re-added at `d36c587` on 2025-12-16** with no commit message explaining why. The launcher's `$Script:Tools` array (`launcher/SouliTEK-Launcher-WPF.ps1` lines 388–396) only references `SouliTEK-Softwares-Installer.ps1` — the live WinGet installer — not this script. The README does not list it. The two are functional duplicates that both wrap WinGet for the same business-app catalog. **This script should be deleted in P1, not renamed.** F3 (the C9 rename to `chocolatey_installer.ps1`) becomes moot under the deletion path; it is documented below as a fallback only if the deletion is rejected.

Secondary issues if the script is somehow kept: 148 raw `Write-Host` calls (C1, the largest single-file count audited so far — confirms the task plan prediction exactly), 6 `-ErrorAction SilentlyContinue` occurrences (5 of 6 are tag-A legitimate, 1 is tag-B), three calls to module helpers (`Show-ScriptBanner` line 715, `Write-Ui` line 721) that the script never dot-sources — these will throw `CommandNotFoundException` at runtime on a clean shell (F5), three approved-verb violations (`Ensure-Admin`, `Ensure-WinGet`, `Load-Preset`), a hard-coded Hebrew-language Office 2024 download URL pinned to the Microsoft `c2rsetup.officeapps.live.com` endpoint with no hash verification (F6), and the C11 absence of the standard SouliTEK banner block entirely (the script uses its own ASCII banner in `Write-Banner` instead). Recommended phase entry: P1 deletion. If kept, P1 C1 sweep + C9 rename + add the missing module dot-source, then P2 C4 triage.

## Findings

### F1 — Raw `Write-Host` everywhere (see C1)
- **Severity:** med
- **Category:** output-style
- **Location:** scripts/SouliTEK-Choco-Installer.ps1 — 148 raw `Write-Host` occurrences (the largest single-file count in the audit set; matches the task plan's predicted hotspot exactly). Dense clusters in `Write-Banner` (lines 54–66, 12 calls), `Show-Menu` (lines 199–291, ~40 calls), `Install-Packages` (lines 490–584, ~25 calls), and `Write-Summary` (lines 589–662, ~30 calls).
- **Reference:** [C1](00-cross-cutting.md#c1--raw-write-host-calls-not-migrated-to-write-uiwrite-status)
- **Current (representative status-line pattern, line 504–506):**
  ```powershell
  Write-Host "[$currentPackage/$totalPackages] " -NoNewline -ForegroundColor Cyan
  Write-Host "Processing: " -NoNewline -ForegroundColor White
  Write-Host $pkgName -ForegroundColor Yellow
  ```
- **Recommended:**
  ```powershell
  Write-Ui -Message "[$currentPackage/$totalPackages] Processing: $pkgName" -Level "STEP"
  ```
- **Risk if changed:** Low — pure replacement. Message text and ordering preserved.
- **Local notes:** Three categories of `Write-Host` here:
  1. **ASCII banner art** — `Write-Banner` (lines 54–66) draws an 8-line ASCII-art "SOULITEK" logo via successive `Write-Host` calls. This is the legitimate "inside visual separator helper" C1 exception (cross-cutting note: "`Write-Host` is allowed *inside* `Write-Ui` / `Show-*` helpers"). Keep — but consider replacing the whole `Write-Banner` function with a call to the module's `Show-ScriptBanner` (which is what the main block already tries to call at line 715, demonstrating the intent — see F5).
  2. **Menu rendering** — `Show-Menu` (lines 199–291) uses `Write-Host -NoNewline` with `-ForegroundColor`/`-BackgroundColor` for the cursor highlight (`Write-Host $item -NoNewline -ForegroundColor Yellow -BackgroundColor DarkGray` at line 247) and the grid layout. This is also a legitimate "visual helper" exception — `Write-Ui` cannot render a 2-column highlighted grid. Keep as-is.
  3. **Plain status messages** — the bulk of the 148 calls: `Write-Host "[+] Logging to: $..." -ForegroundColor Green` (line 181), `Write-Host "[*] Installing NuGet provider..." -ForegroundColor Cyan` (line 127), `Write-Host "[X] Preset file not found: $PresetPath" -ForegroundColor Red` (line 373), etc. **These are real C1 violations** and represent the bulk of the 148-count. All carry inline `[+]`/`[*]`/`[X]`/`[!]` markers that will double up with the `[LEVEL]` bracket emitted by `Write-Ui` — strip the inline markers during the sweep (same anti-pattern as F2 of 01-modules-SouliTEK-Common.md and F2 of scripts-driver_integrity_scan.md).
- **Local notes (cont.):** Because of F4 (deletion recommended), the C1 sweep here is **conditional** — do not invest sweep effort until the deletion question is resolved.
- **Target phase:** P1 *(skip if F4 deletion lands first)*

### F2 — `-ErrorAction SilentlyContinue` triage (see C4)
- **Severity:** med
- **Category:** error-handling
- **Location:** scripts/SouliTEK-Choco-Installer.ps1 — 6 occurrences (task plan predicted 6 — exact match)
- **Reference:** [C4](00-cross-cutting.md#c4----erroraction-silentlycontinue-swallowing-failures)
- **Triage:**
  - Line 94: tag **A** — `Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force -ErrorAction SilentlyContinue` inside `Set-ExecutionPolicyIfNeeded`. The surrounding `try { ... } catch { Write-Host "[!] Warning: Could not set execution policy: $_" }` block already handles failure, so `SilentlyContinue` is redundant *and* prevents the catch from triggering on non-terminating errors. Reclassify as tag **B**: drop `-ErrorAction SilentlyContinue` so the `try/catch` actually fires, or add `-ErrorAction Stop` to force the catch path. Also — `Bypass` for execution policy is the issue called out in `docs/superpowers/plans/2026-04-18-security-and-code-quality.md:23` ("Replace `-ExecutionPolicy Bypass` with `RemoteSigned` (same pattern)"); that's a separate finding from the existing plan, not an audit-loop F.
  - Line 105: tag **A** — `Get-Command winget.exe -ErrorAction SilentlyContinue` is a "does this command exist?" probe; result is immediately tested with `if ($wingetCmd)` on line 106. Legitimate. Add `# safe: probe` comment in P2.
  - Line 125: tag **A** — `Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue` is a "is NuGet provider installed?" probe; result tested with `if (-not $nuget)` on line 126. Legitimate. Add `# safe: probe` comment.
  - Line 132: tag **A** — `Get-PSRepository -Name PSGallery -ErrorAction SilentlyContinue` is a probe for the PSGallery repository; result tested with `if ($psGallery -and ...)` on line 133. Legitimate. Add `# safe: probe` comment.
  - Line 149: tag **A** — duplicate of line 105: `Get-Command winget.exe -ErrorAction SilentlyContinue` after the module install attempt to re-verify. Legitimate. Add `# safe: probe` comment.
  - Line 443: tag **A** — `Remove-Item -Path $installerPath -Force -ErrorAction SilentlyContinue` is cleanup of the downloaded Office 2024 installer (`$env:TEMP\OfficeSetup.exe`). Legitimate "delete temp file if exists." Add `# safe: cleanup` comment.
- **Local notes:** Net: 1× B (line 94 — convert), 5× A (keep + comment). Lighter triage than driver_integrity_scan (5×A there); the script is generally well-behaved on this axis.
- **Target phase:** P2 *(skip if F4 deletion lands first)*

### F3 — Filename violates `lowercase_with_underscores` rule (see C9)
- **Severity:** low
- **Category:** naming
- **Location:** scripts/SouliTEK-Choco-Installer.ps1 (entire path)
- **Reference:** [C9](00-cross-cutting.md#c9--naming-drift-pascalcase-scripts-violate-lowercase_with_underscores-rule)
- **Current:** `scripts/SouliTEK-Choco-Installer.ps1` — PascalCase with hyphens
- **Recommended (per C9):** Rename to `scripts/chocolatey_installer.ps1` via `git mv` (preserves history). Update the launcher (`launcher/SouliTEK-Launcher-WPF.ps1` — see F4 below: the launcher does **not** reference this script, so no launcher edit is required for *this* rename). Update `docs/choco_installer.md` lines 5, 61, 66.
- **Local notes (important):** The recommended rename in C9 is **wrong for this script** in two ways:
  1. The target name `chocolatey_installer.ps1` is itself a lie — the script is a WinGet installer, not a Chocolatey installer. If kept and renamed, the truthful target is `winget_installer.ps1` — but that name collides functionally with the launcher-referenced `SouliTEK-Softwares-Installer.ps1`, which is also a WinGet installer (and is the canonical one).
  2. Because of F4 (this script is unreferenced dead code, deleted then re-added in error), the correct action is **delete, not rename**. C9 should be amended to drop this file from the affected-files list; only `SouliTEK-Softwares-Installer.ps1 → softwares_installer.ps1` should remain.
- **Risk if changed:** Low to rename; lower still to delete.
- **Target phase:** P1 — **but as deletion, not rename** (see F4)

### F4 — Status: dead code (re-added after deletion); candidate for deletion in P1
- **Severity:** med
- **Category:** structure / dead-code
- **Location:** entire script (scripts/SouliTEK-Choco-Installer.ps1 — all 790 lines)
- **Local notes — launcher reference check:** A scan of `launcher/SouliTEK-Launcher-WPF.ps1` for `Choco`/`chocolatey` returned **zero matches**. The launcher's `$Script:Tools` array entry for the WinGet installer (lines 388–396) is:
  ```powershell
  @{
      Name = "Softwares Installer"
      Icon = "Package"
      Description = "Install essential business apps via WinGet"
      Script = "SouliTEK-Softwares-Installer.ps1"
      Category = "Setup"
      Tags = @("winget", "installer", "software", "packages", "apps", "install", "microsoft", "package manager")
      Color = "#10b981"
  }
  ```
  The launcher routes the "install business apps via WinGet" use case exclusively to `SouliTEK-Softwares-Installer.ps1`. **`SouliTEK-Choco-Installer.ps1` has no entry, no menu item, no keyboard shortcut, no fallback path.** README.md has no references to it. The only callers are documentation files (`docs/choco_installer.md`, `docs/audits/README.md` audit-grid row) and audit/plan documents.
- **Local notes — git history:** The file's full history shows the deletion intent is explicit:
  - `d36876e` 2025-10-23 — added (docs: README and workflow state update)
  - `542ac7d` 2025-11-22 — **deleted** ("Remove the outdated SouliTEK Chocolatey Installer script to streamline project resources")
  - `77696be` 2025-11-22 — **re-added** ("Refactor error handling in 1-Click PC Install script...") — the commit message does not mention this file at all; the re-add appears to be either an accidental revert or merge artifact from a feature branch that was based on a pre-deletion commit.
  - `d36c587` 2025-12-16 — modified (sharepoint inventory + output-style standardization touched it).
  So the maintainer's documented intent (per `542ac7d`) is to remove this script, and the re-add at `77696be` was not justified by its own commit message. The script has been sitting in `main` for ~6 months in this "should be deleted but isn't" state.
- **Local notes — functional duplication:** The script duplicates `SouliTEK-Softwares-Installer.ps1`'s entire job: both install business apps via WinGet from a `Script:PackageCatalog` array with a TUI menu. Maintaining two of these will inevitably cause drift (e.g. one gets an OWASP-recommended `Bypass → RemoteSigned` fix per the existing security plan, the other doesn't — the plan at `docs/superpowers/plans/2026-04-18-security-and-code-quality.md:476` explicitly tries to apply the same fix to both, which is exactly the kind of double-maintenance the C-line is meant to prevent).
- **Local notes — SYNOPSIS/filename mismatch:** As an aside, the SYNOPSIS at lines 2–4 says "Chocolatey", the filename says "Choco", but every WinGet-related line in the body uses WinGet. The filename and SYNOPSIS were never updated when the script's underlying engine was switched from Chocolatey to WinGet (presumably a long-ago refactor). This kind of stale metadata is itself a maintenance liability and supports the deletion case.
- **Recommended:** **`git rm scripts/SouliTEK-Choco-Installer.ps1`** in P1 along with `docs/choco_installer.md`. Update `docs/audits/00-cross-cutting.md` C9 to drop this file from the affected-files list. Update `docs/audits/README.md` audit-grid row to mark as deleted. The deletion commit message should reference both `542ac7d` (the original intent) and `77696be` (the accidental re-add) so future readers understand the trail.
- **Recommended (fallback, if deletion is rejected):** If the maintainer wants to keep both installers — e.g. for parallel A/B comparison — then at minimum: (1) fix the filename and SYNOPSIS to reflect that this is a WinGet installer, not a Chocolatey one; (2) carry out the C1 sweep (F1); (3) carry out the C4 triage (F2); (4) fix F5 (missing module dot-source) — the script is currently broken on a clean shell, so "keep" is not a free option.
- **Status string for cross-reference:** **Not referenced by launcher (deprecated); candidate for deletion in P1.**
- **Target phase:** P1 (delete)

### F5 — Missing `SouliTEK-Common.ps1` dot-source — calls `Show-ScriptBanner` / `Write-Ui` that are not defined
- **Severity:** high
- **Category:** correctness (runtime breakage)
- **Location:** scripts/SouliTEK-Choco-Installer.ps1:715 (`Show-ScriptBanner -ScriptName "WinGet Package Installer" -Purpose "..."`), :721 (`Write-Ui -Message "Cannot proceed without WinGet" -Level "ERROR"`)
- **Current:** The script never dot-sources `modules\SouliTEK-Common.ps1` (no `$CommonPath = Join-Path ... "modules\SouliTEK-Common.ps1"` block exists; cf. C10's documented "5–9 lines repeated 35×" pattern that this script *omits*). But the `MAIN EXECUTION` block calls `Show-ScriptBanner` at line 715 and `Write-Ui` at line 721 — both of which are defined in `SouliTEK-Common.ps1`, not locally. On a clean PowerShell session with no auto-loaded module, both calls will throw `CommandNotFoundException`.
- **Recommended (only if F4 deletion is rejected):**
  ```powershell
  $CommonPath = Join-Path (Split-Path -Parent $PSScriptRoot) "modules\SouliTEK-Common.ps1"
  if (Test-Path $CommonPath) { . $CommonPath }
  else {
      Write-Warning "SouliTEK-Common.ps1 not found at $CommonPath; falling back to local Write-Banner."
      function Show-ScriptBanner { param($ScriptName, $Purpose) Write-Banner }
      function Write-Ui { param($Message, $Level) Write-Host "[$Level] $Message" }
  }
  ```
- **Local notes:** This is direct evidence the script is unmaintained: a working installer cannot have two undefined function calls in its main path. Either someone refactored common helpers out into `SouliTEK-Common.ps1` and forgot to update this script to dot-source the module, *or* this script was never tested after `Show-ScriptBanner`/`Write-Ui` were introduced into the module. Either way, this script is unrunnable in its current state without a side-channel module pre-load. Reinforces F4.
- **Risk if changed:** Low (adds 4 lines of standard import block).
- **Target phase:** P1 *(skip if F4 deletion lands first)*

### F6 — Hard-coded Office 2024 download URL with no hash verification + no MOTW handling
- **Severity:** med
- **Category:** security
- **Location:** scripts/SouliTEK-Choco-Installer.ps1:425–483 (`Install-Office2024` function)
- **Current:**
  ```powershell
  $officeUrl = "https://c2rsetup.officeapps.live.com/c2r/download.aspx?ProductreleaseID=ProPlus2024Retail&platform=x64&language=he-il&version=O16GA"
  $installerPath = Join-Path $env:TEMP "OfficeSetup.exe"
  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
  Invoke-WebRequest -Uri $officeUrl -OutFile $installerPath -UseBasicParsing
  ...
  $process = Start-Process -FilePath $installerPath -ArgumentList "/configure" -Wait -PassThru -NoNewWindow
  ```
- **Local notes:** Three concerns, in priority order:
  1. **No hash verification.** The downloaded `OfficeSetup.exe` is executed immediately with no SHA256/Authenticode check. Same class of risk as C12 (the installer-download finding). Microsoft is a trusted publisher, but `c2rsetup.officeapps.live.com` is a redirect endpoint that returns whatever Microsoft currently serves for `ProPlus2024Retail/he-il/O16GA` — there is no version pinning, no integrity check, and no `Get-AuthenticodeSignature` validation before exec. If the URL ever 302-redirects to a hostile mirror, this script will silently install whatever comes back.
  2. **Hard-coded Hebrew (`he-il`) language.** The script is presented as a generic business-app installer in the audit context, but the Office side-channel pins the language to Hebrew. Anyone running this script in any other language locale gets a Hebrew Office install. This is a SouliTEK-specific business detail; not a bug per se, but worth documenting.
  3. **`/configure` argument used without a configuration file.** `Start-Process -FilePath $installerPath -ArgumentList "/configure"` is wrong: `/configure` expects a path to a configuration.xml. Without it, the Office C2R bootstrapper falls back to its default behavior (which happens to work for the simple "install ProPlus" case because the URL query string carries the SKU), but this is undocumented behavior. The launcher-referenced `SouliTEK-Softwares-Installer.ps1` should be checked to see whether it has the same Office side-channel — if so, it has the same three concerns and they should be fixed in *that* script, not here.
- **Recommended:** Defer to whatever the canonical `SouliTEK-Softwares-Installer.ps1` does for Office 2024. If F4 deletion lands, this finding evaporates with the file. If F4 is rejected, lift the Office handler from this script into the canonical one and apply C12-style hash verification at the point of consolidation.
- **Risk if changed:** Medium — Office install is destructive.
- **Target phase:** P1 (folded into F4 deletion) or P6 (folded into C12)

### F7 — Approved-verb violations on three functions
- **Severity:** low
- **Category:** structure / naming
- **Location:** scripts/SouliTEK-Choco-Installer.ps1:69 (`function Ensure-Admin`), :102 (`function Ensure-WinGet`), :366 (`function Load-Preset`)
- **Current:** `Ensure-*` and `Load-*` are not on PowerShell's approved-verb list (`Get-Verb`). Running `Import-Module` (if this script were ever turned into a module) would emit `WARNING: The names of some imported commands include unapproved verbs`. `PSScriptAnalyzer` rule `PSUseApprovedVerbs` will flag all three.
- **Recommended:** Rename — `Ensure-Admin → Assert-Admin` (or `Confirm-Admin`), `Ensure-WinGet → Assert-WinGet` (or `Initialize-WinGet`), `Load-Preset → Import-Preset`. Update the three call sites: line 711 (`Ensure-Admin`), 719 (`Ensure-WinGet`), 733 (`Load-Preset`).
- **Local notes:** Same anti-pattern likely appears across other scripts in the repo — recommend a cross-cutting `Cn — Unapproved-verb function names` finding be opened after a `Select-String -Path scripts -Pattern '^function (Ensure|Load|Fetch|Acquire|Cleanup)-' -Recurse` sweep. Not adding it to the audit set here because the cross-cutting pattern lives in 00-cross-cutting.md and is not in this task's scope.
- **Target phase:** P4 *(skip if F4 deletion lands first)*

### F8 — `Initialize-Logging` writes to `$env:ProgramData\SouliTEK\WinGetInstaller\Logs` but `$Script:SummaryPath` is on Desktop — split log location
- **Severity:** info
- **Category:** structure
- **Location:** scripts/SouliTEK-Choco-Installer.ps1:30–31
  ```powershell
  $Script:LogFolder   = "$env:ProgramData\SouliTEK\WinGetInstaller\Logs"
  $Script:SummaryPath = "$env:USERPROFILE\Desktop\SouliTEK-WinGet-Installer-Result.json"
  ```
- **Local notes:** Logs go to a sensible per-machine path; the summary JSON goes to the *interactive user's* Desktop. Under SYSTEM-context RMM execution, `$env:USERPROFILE` resolves to `C:\Windows\System32\config\systemprofile` and the Desktop folder may not exist, so `Set-Content -Path $Script:SummaryPath` at line 655 will throw — but the surrounding `try { ... } catch { Write-Host "[!] Warning: Could not save summary JSON: $_" }` block (lines 641–660) catches it cleanly. So this is not a bug; just inconsistent. Same observation as F7 of scripts-driver_integrity_scan.md. If F4 deletion lands, evaporates.
- **Target phase:** P4 *(skip if F4 deletion lands first)*

## Out-of-scope notes
- The script has **no C11 banner block at all** — instead of the standard `# === SouliTEK All-In-One Scripts === ...` 25–35 line legal/disclaimer block at the top, this script jumps straight from the comment-based help into `[CmdletBinding()]`. This is the *only* script in the audit set so far without the standard banner. Whether that's a feature (cleaner) or a bug (missing the legal disclaimer) depends on interpretation; the absence simply means C11 has nothing to clean up here.
- `Show-Menu` (lines 188–292) is a competent 2-column TUI grid with cursor-position highlighting, arrow-key navigation, and live package-detail rendering at the bottom. If F4 deletion lands, salvage this rendering code into a reusable `Show-PackagePicker` helper before deleting — it's better than `SouliTEK-Softwares-Installer.ps1`'s menu (worth a separate review pass to confirm). If F4 deletion is rejected, leave as-is.
- The exit-code mapping in `Install-Packages` (lines 543–564) correctly handles WinGet's `3010` (success-with-reboot) and `-1978335189` (`APPINSTALLER_CLI_ERROR_PACKAGE_ALREADY_INSTALLED`) sentinel values. That's actually well done — most scripts wrapping WinGet treat any non-zero exit as failure, which produces false-failure noise on `3010`. Worth preserving the mapping during any salvage operation.
- The `Register-EngineEvent -SourceIdentifier PowerShell.Exiting -Action { ... Stop-Transcript ... }` pattern at lines 705–709 is a clean "stop transcript on session exit" hook. The companion `try { Stop-Transcript } catch { }` blocks at lines 687, 707, 784 are intentionally silent (as documented in `docs/superpowers/plans/2026-04-18-security-and-code-quality.md:630`) — failing to stop a transcript is a genuine don't-care. Leave alone.
- `[Console]::OutputEncoding = [System.Text.Encoding]::UTF8` (line 700) and the matching `InputEncoding` line are the right idiom for a script that includes the `he-il` Hebrew Office download URL — without UTF-8 encoding, any Hebrew text echoed by WinGet's localized output would mojibake to question marks. Good.
- The `$Script:PackageCatalog` array (lines 39–47) hard-codes 7 packages including an MS-Store ID (`9WZDNCRFHWLH` for HP Smart) alongside WinGet community-repo IDs. The MS-Store ID requires WinGet's `msstore` source to be enabled, which the `--accept-source-agreements` flag at line 539 handles correctly. Good.
- Line 158 has a stale recommendation URL — `https://apps.microsoft.com/detail/9NBLGGH4NNS1` is the App Installer product page on the legacy Microsoft Store web frontend; the current canonical URL is `https://apps.microsoft.com/store/detail/app-installer/9NBLGGH4NNS1` or the shorter `ms-windows-store://pdp/?productid=9NBLGGH4NNS1`. Cosmetic; not worth a finding. Evaporates with F4 deletion.
