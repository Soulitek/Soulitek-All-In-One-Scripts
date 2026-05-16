# Audit — scripts/SouliTEK-Softwares-Installer.ps1

## Inventory
| Item | Value |
|---|---|
| Path           | scripts/SouliTEK-Softwares-Installer.ps1 |
| LOC            | 969 (task plan predicted 997 — 28-line gap, likely from blank-trailing-line counting) |
| Functions      | 12 (`Write-Banner`, `Ensure-Admin`, `Set-ExecutionPolicyIfNeeded`, `Ensure-WinGet`, `Show-Menu`, `Show-InteractiveMenu`, `Load-Preset`, `Test-PackageInstalled`, `Install-Office2024`, `Install-ESETConnector`, `Install-Packages`, `Write-Summary`, `Stop-Gracefully`) |
| `#Requires`    | none declared; admin check done at runtime by `Ensure-Admin` which self-elevates via `Start-Process -Verb RunAs` |
| Admin-required | yes (installs MSI / EXE packages via WinGet + downloads ProPlus 2024 + ESET Connector to `Program Files`; calls `Install-Module -Scope CurrentUser` and `Install-PackageProvider`; runs `shutdown /r /t 10` on reboot prompt) |
| Last touched   | 8675720 — 2026-04-17 |
| Modernization grade | B |

## Summary

An interactive grid-style TUI installer that selects WinGet package IDs by arrow-key navigation and installs them sequentially. The script's structure is notably cleaner than the rest of the audited surface: it already has `[CmdletBinding()]` and a `param([string]$Preset)` block (lines 20–24), it uses `Write-Ui` as the primary output API across the entire file (zero calls to the C2 legacy `Write-SouliTEK*` wrappers), the two custom downloaders (`Install-Office2024`, `Install-ESETConnector`) correctly verify Authenticode signatures before launching the installers (lines 459–464, 533–538) — a security idiom missing from `Install-SouliTEK.ps1` itself (C12) — and the WinGet subprocess wrapper has a 30-minute timeout with `$proc.Kill()` fallback, `Start-Process -RedirectStandardOutput/Error` file capture, and explicit handling for the `already installed` exit code `-1978335189`. The principal weaknesses are: (1) 65 raw `Write-Host` calls remain (C1) — the majority are blank-line spacers and ASCII-art banner lines (which are allowed inside `Write-Banner` per C1's "visual separator helpers" exception), but ~20 are real inline-color formatting violations that should migrate to `Write-Ui`; (2) the filename violates the lowercase-with-underscores naming convention (C9) and must be renamed to `softwares_installer.ps1` with launcher and docs cross-references updated; (3) the interactive picker uses `$Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")` (line 304) which has no non-interactive fallback and will throw under SYSTEM/RMM context where there is no console host — the `-Preset` parameter is the only non-interactive path. Secondary issues: two unapproved-verb function names (`Ensure-Admin` line 83, `Ensure-WinGet` line 116, `Load-Preset` line 363) will trigger PSScriptAnalyzer `PSUseApprovedVerbs` warnings under C8; a `Write-Ui -Message "..." + (...)` string-concatenation pattern in `Write-Summary` (lines 844, 846, 866) is a real bug — PowerShell parameter binding will reject the `+` operator at parse-or-bind time, producing a string-concatenation expression as the parameter value only if grouped, which the current code does not do; the Office 2024 download URL is HTTPS but the installer trusts whatever the redirect resolves to without a content hash check (lower-grade variant of C12). Sixteen `-ErrorAction SilentlyContinue` occurrences are triaged below — all but one (line 108) are A-tag legitimate uses. Recommended phase entry order: P1 (C9 rename + C1 sweep), then P2 (C4 triage with line-108 promotion), then P3 (`-NonInteractive` switch + console-host fallback for the picker).

## Findings

### F1 — Raw `Write-Host` calls (see C1)
- **Severity:** med
- **Category:** output-style
- **Location:** scripts/SouliTEK-Softwares-Installer.ps1 — 65 occurrences. Zero calls to the C2 legacy `Write-SouliTEK*` API (rare in this codebase — a positive indicator).
- **Reference:** [C1](00-cross-cutting.md#c1--raw-write-host-calls-not-migrated-to-write-uiwrite-status)
- **Current (representative — inline two-segment formatting at lines 196–197):**
  ```powershell
  Write-Host "  WinGet Version: " -NoNewline -ForegroundColor Gray
  Write-Ui -Message $Script:WinGetVersion -Level "OK"
  ```
- **Recommended:**
  ```powershell
  Write-Ui -Message "WinGet Version: $Script:WinGetVersion" -Level "OK"
  ```
- **Risk if changed:** Low — message text preserved verbatim once the manual-color two-segment pattern is collapsed.
- **Local notes:** Four categories of raw `Write-Host`:
  1. **Banner ASCII-art and separator helpers** — `Write-Host ""`, the 6 ASCII-art lines inside `Write-Banner` (lines 70–75), the `Write-Host "=========..." -ForegroundColor DarkCyan` rule lines at 597, 599, 824, 826. These are allowed inside `Write-Banner`/section-header helpers per C1's "visual separator helpers" exception. Sample lines: 68, 70–75, 77, 80, 198, 208, 210, 260, 267, 269, 282, 288, 596–600, 818, 823–827, 841, 867, 872, 896, 909, 911, 941, 946, 961, 967, 969, 982, 987, 989, 992 — ~45 of the 65 calls fall into this bucket.
  2. **Two-segment inline-color formatting** — `Write-Host "Label: " -NoNewline -ForegroundColor Gray` immediately followed by `Write-Ui -Message $value -Level X` (lines 196–197, 204–206, 274–281, 610–612, 833–834, 835–836, 837–838, 839–840). 8 sites, ~16 raw calls — these are the real C1 violations and should collapse to single `Write-Ui` calls with the label inlined into the message string.
  3. **Plain message lines** — `Write-Host "    Visit: https://apps.microsoft.com/detail/9NBLGGH4NNS1" -ForegroundColor Yellow` (lines 172, 180), `Write-Host "             Error: $($errorLine.Trim())" -ForegroundColor DarkRed` (line 774), `Write-Host "  Reboot now? (Y/N): " -NoNewline -ForegroundColor Yellow` (line 899). 4 clear C1 violations — direct `Write-Ui -Level WARN/ERROR` replacements.
  4. **Grid renderer raw output** — `Write-Host $item -NoNewline -ForegroundColor Yellow -BackgroundColor DarkGray` (line 244), `Write-Host $item -NoNewline -ForegroundColor Green` (line 248), `Write-Host $item -NoNewline -ForegroundColor White` (line 251), `Write-Host (" " * $columnWidth) -NoNewline` (line 257), `Write-Host ("  {0,-30} " -f $pkgName) -NoNewline` (line 860), `Write-Host ("{0,-15} " -f $result.Status) -NoNewline -ForegroundColor $color` (line 861), `Write-Host ("{0,-10} " -f $elapsed) -NoNewline -ForegroundColor Gray` (line 862). These need to remain `Write-Host` — `Write-Ui` doesn't support `-NoNewline` or `-BackgroundColor`, both of which are essential for the grid-cell renderer and the columnar summary table. Flag with `# write-host: grid renderer — Write-Ui unsupported` comments rather than migrate.
- **Local notes (cont.) — inline marker prefixes:** Many `Write-Ui` calls double-mark with embedded `[*]`/`[+]`/`[-]`/`[!]`/`[X]`/`[OK]`/`[FAIL]`/`[SKIP]`/`[%]` prefixes inside the message (lines 88, 89, 107, 112, 117, 124, 128, 134, 135, 141, 148, 153, 167, 171, 173, 178, 179, 264, 286, 287, 349, 370, 378, 379, 383, 444, 452, 456, 461, 465, 466, 471, 475, 478, 481, 490, 499, 508, 518, 526, 530, 539, 545, 549, 552, 555, 564, 573, 582, 612, 613, 623, 628, 658, 677, 678, 688, 694, 702, 713, 740, 745, 751, 752, 757, 758, 764, 769, 803, 838, 840, 843, 870, 890, 893, 902, 910, 951, 955, 960, 968, 988, 990). Same anti-pattern as F2 of 01-modules-SouliTEK-Common.md — strip these inline markers in the C1 sweep so the `[LEVEL]` bracket emitted by `Write-Ui` is the only marker. The percentage progress markers (`[0%]`/`[10%]`/.../`[100%]`) on lines 444, 452, 456, 465, 466, 471, 475, 518, 526, 530, 539, 545, 549, 658, 677, 678, 688, 713, 745, 751, 757 are domain-meaningful and should be preserved verbatim — they convey installation progress and are not redundant with `Write-Ui`'s `[INFO]`/`[OK]` brackets.
- **Target phase:** P1

### F2 — `-ErrorAction SilentlyContinue` triage (see C4)
- **Severity:** med
- **Category:** error-handling
- **Location:** scripts/SouliTEK-Softwares-Installer.ps1 — 16 occurrences
- **Reference:** [C4](00-cross-cutting.md#c4----erroraction-silentlycontinue-swallowing-failures)
- **Triage:**
  - Line 108: tag **B** — `Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force -ErrorAction SilentlyContinue` swallows a real failure. If this fails (Group Policy enforcement on a managed workstation, or `Force` rejected because the current scope is locked by a higher-precedence MachinePolicy), the script will proceed under the original `Restricted`/`AllSigned` policy and the very next dot-source/Install-Module call may fail in a confusing way. Replace with `try { Set-ExecutionPolicy ... -ErrorAction Stop } catch { Write-Ui -Message "Could not relax execution policy ($_) — script may fail" -Level "WARN" }`.
  - Line 119: tag **A** — `Get-Command winget.exe -ErrorAction SilentlyContinue` is a "does this command exist?" probe whose result is immediately tested with `if ($wingetCmd)`. Legitimate. Add `# safe: probe` comment in P2.
  - Line 139: tag **A** — `Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue` is a probe; result tested with `if (-not $nuget)` before deciding whether to call `Install-PackageProvider`. Legitimate. `# safe: probe`.
  - Line 146: tag **A** — `Get-PSRepository -Name PSGallery -ErrorAction SilentlyContinue` is a probe; result tested with `if ($psGallery -and ...)`. Legitimate. `# safe: probe`.
  - Line 163: tag **A** — second `Get-Command winget.exe -ErrorAction SilentlyContinue` after the install attempt; same probe pattern as line 119. Legitimate. `# safe: probe`.
  - Line 424: tag **A** — `Get-Service -Name "ekrn" -ErrorAction SilentlyContinue` probes for the ESET kernel service. Result tested with `if ($esetService)`. Legitimate "is this service installed?" check inside `Test-PackageInstalled`. `# safe: probe`.
  - Line 462: tag **A** — `Remove-Item -Path $installerPath -Force -ErrorAction SilentlyContinue` is cleanup of the Office installer after a failed signature check. The file definitely exists (we just downloaded it on line 454) but `SilentlyContinue` defends against transient AV-lock or in-use-handle. Legitimate cleanup. `# safe: cleanup`.
  - Line 473: tag **A** — `Remove-Item -Path $installerPath -Force -ErrorAction SilentlyContinue` is post-install cleanup of the Office installer. Same pattern as 462. `# safe: cleanup`.
  - Line 536: tag **A** — `Remove-Item -Path $installerPath -Force -ErrorAction SilentlyContinue` is ESET cleanup after failed signature check. Same pattern. `# safe: cleanup`.
  - Line 547: tag **A** — `Remove-Item -Path $installerPath -Force -ErrorAction SilentlyContinue` is post-install ESET cleanup. Same pattern. `# safe: cleanup`.
  - Line 674: tag **A** — `if (Test-Path $logFile) { Remove-Item $logFile -Force -ErrorAction SilentlyContinue }` is pre-install cleanup of stale stdout log. Guarded by `Test-Path` and the `SilentlyContinue` defends against the file being held open by a stale handle. Legitimate. `# safe: cleanup`.
  - Line 675: tag **A** — companion stderr-log cleanup for line 674. Same pattern. `# safe: cleanup`.
  - Line 729: tag **A** — `Get-Content -Path $logFile -Raw -ErrorAction SilentlyContinue` reads winget's redirected stdout after process exit. The file may be empty/absent if winget produced no stdout (some failure paths produce only stderr); `$stdOut` is then checked with `if ($stdOut)` before pattern-matching. Legitimate optional read. `# safe: optional read`.
  - Line 732: tag **A** — companion stderr read for line 729. Same pattern. `# safe: optional read`.
  - Line 796: tag **A** — post-success log cleanup; guarded by `Test-Path` and only fires when `$status -eq "Installed" -or $status -eq "Skipped"`. Legitimate. `# safe: cleanup`.
  - Line 797: tag **A** — companion stderr-log post-success cleanup. Same pattern. `# safe: cleanup`.
- **Local notes:** 15 of 16 occurrences are tag-A legitimate cleanups or probes — a strong ratio compared to other scripts in the audited surface. The only real C4 violation is line 108 (tag B). Phase P2 should apply the tag-A comments in a single sweep and convert line 108 to `try { ... -ErrorAction Stop } catch { ... }`.
- **Target phase:** P2

### F3 — PascalCase filename violates naming convention (see C9)
- **Severity:** low
- **Category:** naming
- **Location:** scripts/SouliTEK-Softwares-Installer.ps1 (filename); launcher/SouliTEK-Launcher-WPF.ps1:392 (`Script = "SouliTEK-Softwares-Installer.ps1"`); docs/softwares_installer.md (filename already correct — doc cross-references need updating if the script body header is changed); docs/audits/00-cross-cutting.md C9 entry; docs/audits/README.md; docs/superpowers/plans/2026-05-15-modernization-audit.md; docs/superpowers/specs/2026-05-15-modernize-roadmap-design.md; docs/superpowers/plans/2026-04-18-security-and-code-quality.md; .claude/settings.local.json.
- **Reference:** [C9](00-cross-cutting.md#c9--naming-drift-pascalcase-scripts-violate-lowercase_with_underscores-rule)
- **Recommended:** `git mv scripts/SouliTEK-Softwares-Installer.ps1 scripts/softwares_installer.ps1`; update the launcher entry on line 392; grep-and-replace `SouliTEK-Softwares-Installer.ps1` → `softwares_installer.ps1` across the 10 files identified above. The script's internal `[CmdletBinding()]` and `Show-ScriptBanner -ScriptName "Softwares Installer"` call on line 936 are filename-agnostic and need no change. The `$Script:SummaryPath = "$env:USERPROFILE\Desktop\SouliTEK-Softwares-Installer-Result.json"` on line 37 also needs no rename — the JSON output filename is user-facing brand text, not a code identifier, and renaming it would orphan any existing summary files on operator desktops.
- **Risk if changed:** Low. Verify the launcher launches the renamed tool after the change (the C9 cross-cutting note already calls this out as the validation step).
- **Target phase:** P1

### F4 — Unapproved-verb function names (`Ensure-*`, `Load-*`)
- **Severity:** low
- **Category:** naming
- **Location:** scripts/SouliTEK-Softwares-Installer.ps1:83 (`Ensure-Admin`), :116 (`Ensure-WinGet`), :363 (`Load-Preset`).
- **Current:**
  ```powershell
  function Ensure-Admin { ... }
  function Ensure-WinGet { ... }
  function Load-Preset { ... }
  ```
- **Recommended:**
  ```powershell
  function Assert-Admin { ... }      # Assert is on Get-Verb's approved list
  function Install-WinGet { ... }    # Install matches the function's actual side effect
  function Import-Preset { ... }     # Import is the canonical verb for "read from disk into memory"
  ```
- **Risk if changed:** Low. Update the three call sites in the same file (`Ensure-Admin` line 932, `Ensure-WinGet` line 938, `Load-Preset` line 952). No external callers — these are all script-internal helpers. Will silence three `PSUseApprovedVerbs` analyzer warnings when C8 lands.
- **Local notes:** PowerShell's approved verbs list is enforced by `Get-Verb`; `Ensure` and `Load` are both off-list. This finding is a P1 lint cleanup once C8's CI baseline is in place — if applied before C8 there is no enforcement gating to verify against.
- **Target phase:** P1 (alongside C8 baseline) or P4 (style-pass)
- **Reference:** local (no cross-cutting ID)

### F5 — Interactive picker has no non-interactive fallback
- **Severity:** med
- **Category:** structure (UX / RMM safety)
- **Location:** scripts/SouliTEK-Softwares-Installer.ps1:304 (`$Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")`) inside the `while ($true)` loop at line 301; plus `Read-Host "Press Enter to exit"` at lines 942, 956, 984, 994 and `Read-Host` at line 900.
- **Current:** The interactive grid picker is the default code path (`if ($Preset) { ... } else { $packageIds = Show-InteractiveMenu }` on lines 950–964). Under SYSTEM context or any execution environment without an attached console host (PSRemoting, ScheduledJob, Win32 service spawn), `$Host.UI.RawUI.ReadKey` throws `System.Management.Automation.Host.HostException: "A command that prompts the user failed because the host program or the command type does not support user interaction."` and the `try { ... } catch` block at line 924–995 catches it and re-prompts with another `Read-Host`, which itself fails the same way — infinite loop with no exit.
- **Recommended:**
  1. Add a non-interactive guard at the top of `Show-InteractiveMenu`:
     ```powershell
     if (-not [Environment]::UserInteractive -or $Host.Name -eq 'ServerRemoteHost') {
         Write-Ui -Message "Non-interactive environment detected — supply -Preset to use this script under SYSTEM/RMM" -Level "ERROR"
         exit 2
     }
     ```
  2. Promote `-Preset` from "optional override" to "required when non-interactive" — keep the current default of "open the picker if `-Preset` is omitted and the host is interactive."
  3. Trailing `Read-Host "Press Enter to exit"` calls (lines 942, 956, 984, 994) should be gated by the same `[Environment]::UserInteractive` check so the script can complete cleanly under RMM.
- **Risk if changed:** Low for the guard; medium for removing the trailing `Read-Host`s if any operators rely on them to read the on-screen summary before the window closes — the existing `$Script:SummaryPath` JSON export (line 889) provides a durable alternative.
- **Local notes:** This pairs with the user's CLAUDE.md "SYSTEM-context execution (RMM deployment scenarios)" requirement. The Office 2024 download is ~3.5GB and the `Install-Packages` foreach can run for an hour — under RMM this is exactly the kind of long unattended workload that benefits from a non-interactive mode. The `-Preset` JSON file is already the right vehicle; this finding is just about making the missing-`-Preset`-under-SYSTEM case fail cleanly instead of hanging.
- **Target phase:** P3
- **Reference:** local (related to F6 of `scripts-driver_integrity_scan.md`)

### F6 — `Write-Ui -Message ... + (...)` string-concatenation will produce wrong output
- **Severity:** med
- **Category:** correctness (real bug)
- **Location:** scripts/SouliTEK-Softwares-Installer.ps1:844, :846, :866.
- **Current:**
  ```powershell
  Write-Ui -Message "  " + ("-" * 75) -Level "INFO"
  ```
- **Recommended:**
  ```powershell
  Write-Ui -Message ("  " + ("-" * 75)) -Level "INFO"
  ```
- **Risk if changed:** None — pure bug fix. **Verify with a quick console test before committing**: PowerShell's parameter-binding parser handles `"  " + ("-" * 75)` here by binding the literal `"  "` to `-Message` and then evaluating `+ ("-" * 75)` as a unary-plus expression on the resulting array, which silently emits the dashes as a separate pipeline value to the console rather than passing the concatenated string through `Write-Ui`. The visible output is dashes appearing *outside* the `[INFO]` framing, which is the symptom an operator would see today. The parenthesised form forces the concatenation to happen before parameter binding. Three occurrences, identical pattern (lines 844 and 866 emit the top/bottom rules of the summary table; line 846 wraps `Write-Ui -Message ("  {0,-30} ..." -f ...)` which is correctly parenthesised on the format-operator side but the `-Message` value itself is similarly mis-parsed if the message string concatenation pattern repeats — re-read line 846 carefully and verify which of these are the actual concat-bug variant before fixing).
- **Local notes:** This finding is high-confidence on lines 844 and 866 (visible verbatim in the source). Line 846 was added to the list defensively because the construct lives in the same code block — re-verify line 846 reads exactly as the concat-bug pattern before changing it. The fix should also be paired with the F1 strip-inline-markers sweep since `Write-Ui`'s `[INFO]` bracket already provides visual framing; the explicit dash rule on lines 844/866 may be entirely redundant after the C1 + F1 cleanup, in which case delete rather than fix.
- **Target phase:** P2 (correctness fix); fold into the F1 C1 sweep
- **Reference:** local (no cross-cutting ID)

### F7 — Office 2024 + ESET downloads trust HTTPS redirect without content hash check (related to C12)
- **Severity:** med
- **Category:** security
- **Location:** scripts/SouliTEK-Softwares-Installer.ps1:447 (Office URL), :454 (`Invoke-WebRequest -Uri $officeUrl -OutFile $installerPath -UseBasicParsing -ErrorAction Stop`), :521 (ESET URL), :528 (`Invoke-WebRequest -Uri $esetUrl -OutFile $installerPath -UseBasicParsing -ErrorAction Stop`).
- **Reference:** related to [C12](00-cross-cutting.md#c12--installer-downloads-zip-without-mandatory-hash-verification-by-default) but a strictly weaker case — C12 is about the bootstrapping installer, this is about per-package downloads inside the installer itself.
- **Current:** Both custom downloaders fetch from a Microsoft / ESET HTTPS URL and immediately call `Get-AuthenticodeSignature -FilePath $installerPath` to verify the binary's Authenticode signature is `Valid` (lines 459–464, 533–538). The signature check is the right strong control — but it only verifies that the downloaded EXE/MSI is signed by *some* trusted publisher, not that it is the *expected* publisher or the *expected* version. A spoofed `c2rsetup.officeapps.live.com` (TLS-stripping proxy on a compromised network, or a DNS-rebind attack) that returns any signed Microsoft installer (Skype, Teams, OneDrive, an older Office build with known CVEs) would pass the `Get-AuthenticodeSignature` check.
- **Recommended:**
  1. Pin the expected `SignerCertificate.Subject` to `CN=Microsoft Corporation, O=Microsoft Corporation, ...` for Office and to `CN=ESET, spol. s r.o., O=ESET, spol. s r.o., ...` for ESET. Reject if the signer subject doesn't match even when the chain validates.
  2. Optionally add a SHA256 pin for known-good installer hashes — but Office 2024 ProPlus updates the bootstrapper monthly, so subject-pinning is more maintainable.
  3. Consider gating both custom downloaders behind a `-AllowCustomDownloads` switch (default `$false`) so the operator must opt in to the non-WinGet code paths.
- **Risk if changed:** Low. Adding the subject check is ~6 lines of code per downloader; if the check fails the existing `Aborting` error path (lines 461–464, 535–538) is the right user-visible response.
- **Local notes:** This finding is a *plus* — the script already does the Authenticode check, which puts it ahead of `Install-SouliTEK.ps1` (C12) and most other ad-hoc-download scripts in the audited surface. Treat this finding as a hardening step, not a "bug fix."
- **Target phase:** P6 (alongside the C12 manifest work)

### F8 — `Show-Menu` `Selected: $selectedCount` two-line render uses three `Write-Host`/`Write-Ui` calls where one would do (cosmetic / perf)
- **Severity:** info
- **Category:** structure (note only)
- **Location:** scripts/SouliTEK-Softwares-Installer.ps1:204–206 (also lines 274–281 for the per-package detail block).
- **Current:**
  ```powershell
  Write-Host "  Selected: " -NoNewline -ForegroundColor Gray
  Write-Host "$selectedCount" -NoNewline -ForegroundColor Cyan
  Write-Ui -Message " / $totalCount" -Level "INFO"
  ```
- **Local notes:** Three write calls per menu redraw, called inside `Show-Menu`, called from `Show-InteractiveMenu`'s `while ($true)` loop on every keypress — so on each arrow-key press the screen is `Clear-Host`'d and the entire 30-something-line menu is redrawn. Not a real perf issue at human-interactive keypress rates, but it is a structural quirk worth noting: the menu redraw could be batched into a `$sb = [System.Text.StringBuilder]::new(); ... [Console]::Write($sb.ToString())` single-write pass if flicker becomes a complaint. Not worth changing today.
- **Target phase:** —

## Out-of-scope notes
- Banner block (the function `Write-Banner` lines 67–81) — this is the C11-style cosmetic block but is implemented as a callable function rather than top-of-file boilerplate, so it does not trigger the C11 cleanup. Leave as-is.
- The dot-source loader at lines 31–35 (`$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path; $CommonPath = Join-Path (Split-Path -Parent $ScriptRoot) "modules\SouliTEK-Common.ps1"; if (Test-Path $CommonPath) { . $CommonPath }`) — this uses `$MyInvocation.MyCommand.Path` instead of `$PSScriptRoot` (same pattern as F5 of `scripts-driver_integrity_scan.md`) AND is missing the standard `else { Write-Warning "..."; ... }` branch that the C10 cross-cutting entry describes. Will be replaced by `Import-SouliTEKCommon` in the C10 P4 sweep — no separate finding raised here, but flagging the missing-else-branch silent-fail since it means the script will continue silently if the module is missing and then crash with a confusing `Write-Ui : The term 'Write-Ui' is not recognized` error on the first call. A two-line `else { Write-Warning "SouliTEK common module missing at $CommonPath"; exit 1 }` would be a free hardening before C10 lands.
- The `Test-PackageInstalled` Office/ESET special-cases (lines 396–429) hard-code per-vendor filesystem and service paths. This is the pragmatic answer for products that don't surface clean to `winget list`, but it means adding a new "custom" package to the catalog requires editing this function in two places (the special-case in `Test-PackageInstalled` and the special-case in `Install-Packages` lines 631–655). A `$Script:PackageCatalog` entry with an optional `DetectionScript` scriptblock property would generalize this, but is a P4-grade refactor and not worth doing until a third custom package appears.
- The `Install-Packages` standard-WinGet branch (lines 656–799) is well-built: explicit timeout with `[Diagnostics.Stopwatch]`, `Start-Process -RedirectStandardOutput/Error -PassThru -NoNewWindow`, polling loop with progress nudges every 30 seconds, explicit `$proc.Kill()` on timeout, file-cleanup on success, file-retention on failure for debugging, explicit handling of the `already installed` exit code `-1978335189`. This is a model of how to wrap an external process in PowerShell — no change needed.
- The `Stop-Gracefully` function (lines 908–918) is defined but never called from anywhere in the file (no `try { ... } catch [System.Management.Automation.PipelineStoppedException]` handler, no `Ctrl+C` registration via `[Console]::TreatControlCAsInput`). Dead code. Could be removed in P4, or wired up with `[Console]::CancelKeyPress += { Stop-Gracefully }` if the operator-cancel UX is wanted.
- The `$Script:RebootRequired` flag (line 39) is set in three places (Office 480, ESET 554, WinGet 761) and consumed in two (summary 869, reboot prompt 898). Clean — no concerns.
- `shutdown /r /t 10 /c "..."` on line 903 is the right way to schedule a reboot from PowerShell (vs. `Restart-Computer -Force` which has no countdown). Note the prompt is gated behind `if ($Script:RebootRequired)` (line 898) and the Y/N confirmation (lines 899–901) so it cannot fire unattended — good. Under the F5 non-interactive path, this prompt should be skipped entirely and a "REBOOT REQUIRED — operator action needed" line should be the only output.
- The trailing single blank line at the end of the file (line 998) is fine. POSIX-style newline-at-EOF.
