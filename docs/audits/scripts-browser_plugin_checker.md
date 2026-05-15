# Audit — scripts/browser_plugin_checker.ps1

## Inventory
| Item | Value |
|---|---|
| Path           | scripts/browser_plugin_checker.ps1 |
| LOC            | 872 |
| Functions      | 14 |
| `#Requires`    | `#Requires -Version 5.1` |
| Admin-required | no (reads user-scoped browser profile directories under `$env:LOCALAPPDATA` and `$env:APPDATA`; no registry writes, no process mutation, no admin-only paths) |
| Last touched   | 8675720 — 2026-04-17 |
| Modernization grade | B |

## Summary

A menu-driven scanner that enumerates installed Chromium-family browsers (Chrome, Edge, Brave, Opera, Vivaldi) plus Firefox, parses each extension's `manifest.json` (with `_locales` fallback for `__MSG_*__` localized names), and applies a keyword-and-permission heuristic to assign a `Low`/`Medium`/`High` risk level. The B grade is earned: the script already uses `Write-Ui` heavily, all five `-ErrorAction SilentlyContinue` occurrences are defensible `Get-ChildItem` probes, no legacy `Get-WmiObject` or `Write-SouliTEK*` callers remain, JSON parsing is wrapped in `try/catch`, and the per-browser path detection is clean. The main residual issues are (1) 66 raw `Write-Host` calls still in use for separator bars (`Write-Host "===..."`), bare spacing (`Write-Host ""`), and inline-color formatting (e.g. lines 466–467 split the "Risk Level: " label and value across two `Write-Host` calls so the colored value renders inline) — these are real C1 violations even though many would survive under the C1 "visual separator helpers" exception once `Show-Section`/`Show-Header` exist (C1); (2) the per-extension scan in `Get-ChromiumExtensions` is the C13 candidate identified in 00-cross-cutting.md — sequential I/O over every extension directory across every profile across every browser, with synchronous manifest.json + per-locale messages.json reads; (3) `Test-SuspiciousExtension` is called 2–3× per extension across `Show-ExtensionDetails`, `Show-ScanSummary`, `Invoke-FullScan`, `Show-RiskyExtensions`, and `Export-ScanResults` — the result should be cached on the extension object or memoized; (4) interactive `Read-Host` + `Wait-SouliTEKKeyPress` calls mean the script will hang under SYSTEM/RMM execution. No `[CmdletBinding()]` anywhere (script-level or function-level). The risky-permission and suspicious-keyword string lists (lines 43–62) are sensible defaults but very short — a real malware detector this is not, and the audit should not pretend otherwise.

## Findings

### F1 — Mixed `Write-Host` / `Write-Ui` (see C1)
- **Severity:** med
- **Category:** output-style
- **Location:** scripts/browser_plugin_checker.ps1 — 66 raw `Write-Host` occurrences (sample lines: 418, 419, 421, 422, 434, 455, 466, 467, 503, 504, 506, 507, 509, 511–517, 529, 542–546, 594, 596, 605, 616, 623, 624, 626, 634, 645, 660, 661, 663, 666, 668, 687, 753–757, 762, 770, 772, 774, 776, 778, 785, 791, 792, 806, 809, 810, 819–840). Zero `Write-SouliTEK*` legacy-API callers (verified).
- **Reference:** [C1](00-cross-cutting.md#c1--raw-write-host-calls-not-migrated-to-write-uiwrite-status)
- **Current (representative inline-color pattern, lines 466–467):**
  ```powershell
  Write-Host "      Risk Level: " -NoNewline -ForegroundColor Gray
  Write-Host $analysis.RiskLevel -ForegroundColor $riskColor
  ```
- **Recommended:**
  ```powershell
  $level = switch ($analysis.RiskLevel) { 'High' { 'ERROR' } 'Medium' { 'WARN' } default { 'OK' } }
  Write-Ui -Message "      Risk Level: $($analysis.RiskLevel)" -Level $level
  ```
- **Risk if changed:** Low — message text preserved verbatim; `[ERROR]`/`[WARN]`/`[OK]` bracket emitted by `Write-Ui` replaces the manual color mapping. Per-category fix patterns are enumerated below.
- **Local notes:** Three categories of raw `Write-Host`:
  1. **Separator-bar calls** — `Write-Host "============================================================" -ForegroundColor Cyan` (lines 419, 421, 504, 506, 543, 545, 624, 626, 754, 756, 792, 820, 839) and Magenta/Yellow variants (lines 594, 596, 661, 663, 806, 809). 19 occurrences total. These are visual separators that fall under the C1 exception — leave as-is until a `Show-Section`/`Show-Header` helper lands, then migrate in bulk.
  2. **Blank-line / spacer calls** — bare `Write-Host ""` (lines 418, 422, 434, 455, 503, 507, 509, 517, 529, 542, 546, 605, 616, 623, 634, 645, 660, 666, 668, 687, 753, 757, 762, 770, 778, 785, 791, 810, 819, 821, 824, 827, 830, 833, 836, 838, 840). 37 occurrences. Same C1 visual-separator exception applies — they are noisy but not violations per the cross-cutting rule.
  3. **Inline-color formatting** — real C1 violations:
     - Lines 466–467 (`Risk Level:` label-then-value split across two calls).
     - Lines 511–516 (the `Risk Distribution:` block — three label+value pairs at `High Risk`, `Medium Risk`, `Low Risk` with `-ForegroundColor Gray` labels and dynamic foreground per count; line 516 mixes `Write-Ui` for the low count immediately after two `Write-Host` lines, so the formatting is already broken inside one block).
     - Lines 772, 774, 776 in `Show-Help` (`- High:   `, `- Medium: `, `- Low:    ` color-prefix lines paired with `Write-Ui` continuation on lines 773, 775, 777 — same anti-pattern as F2 in driver_integrity_scan.md).
- **Local notes (cont.) — inline marker prefixes:** Several `Write-Ui` calls already embed `[+]`, `[!]`, `[*]` markers in the message string (lines 430, 458, 461, 476, 520, 523, 526, 667), double-marking output that already carries the `[LEVEL]` bracket from `Write-Ui` itself. Same anti-pattern as F2 of driver_integrity_scan.md — strip the inline markers in the C1 sweep so the level bracket is the only marker.
- **Local notes (cont.) — `Write-Ui` with non-string argument:** Line 516 calls `Write-Ui -Message $low -Level "OK"` where `$low` is an `[int]`. Depending on the module's parameter type coercion, this works today but is fragile — `Write-Ui -Message "$low" -Level "OK"` (or formatted into the surrounding label) is safer. Worth noting alongside the F1 cleanup.
- **Target phase:** P1

### F2 — `-ErrorAction SilentlyContinue` triage (see C4)
- **Severity:** low
- **Category:** error-handling
- **Location:** scripts/browser_plugin_checker.ps1 — 5 occurrences
- **Reference:** [C4](00-cross-cutting.md#c4----erroraction-silentlycontinue-swallowing-failures)
- **Triage:**
  - Line 164: tag **A** — `Get-ChildItem -Path $UserDataPath -Directory -Filter "Profile *" -ErrorAction SilentlyContinue` in `Get-ChromiumProfiles`. Probes for `Profile 1`/`Profile 2`/... directories that may or may not exist; absence is the common case (single-profile users). Legitimate. Add `# safe: probe — profiles may not exist` comment in P2.
  - Line 190: tag **A** — `Get-ChildItem -Path $extensionsPath -Directory -ErrorAction SilentlyContinue` in `Get-ChromiumExtensions`. Top-level enumeration of the per-profile `Extensions` directory. Already guarded above by `if (-not (Test-Path $extensionsPath)) { return $extensions }` on lines 186–188, so SilentlyContinue is double-belt — could be removed entirely, but as-written it is harmless. Tag A. Add `# safe: probe` or drop the flag.
  - Line 196: tag **A** — `Get-ChildItem -Path $extDir.FullName -Directory -ErrorAction SilentlyContinue` enumerates version subdirectories under an extension folder; missing/empty is expected for the legacy `Temp` subfolder Chrome occasionally creates. Result is piped through `Sort-Object | Select-Object -First 1` and guarded with `if ($versionDirs)` before use. Legitimate. Tag A.
  - Line 235: tag **A** — `Get-ChildItem -Path $localesPath -Directory -ErrorAction SilentlyContinue` enumerates `_locales` subdirectories during the localized-name fallback. Absence is fine — the loop already iterated the preferred locales in lines 217–231 and only falls through here if none matched. Tag A.
  - Line 301: tag **A** — `Get-ChildItem -Path $ProfilesPath -Directory -ErrorAction SilentlyContinue` in `Get-FirefoxExtensions`. Top-level Firefox-profile enumeration; the caller already checked `Test-Path "$env:APPDATA\Mozilla\Firefox\Profiles"` at line 105 before adding Firefox to the browser list, so the path exists. Tag A.
- **Local notes:** All 5 occurrences are tag **A** legitimate enumeration probes. The script does no destructive operations, so there is no tag-C "must halt" candidate here. The `try { Get-Content ... | ConvertFrom-Json } catch { # Skip ... }` blocks at lines 204–282 (Chromium), 222–246 (locales nested), and 307–337 (Firefox) silently swallow JSON parse errors — see F5 below for that separate concern.
- **Target phase:** P2

### F3 — Sequential per-extension scan loop (see C13)
- **Severity:** low (perf)
- **Category:** perf
- **Location:** scripts/browser_plugin_checker.ps1 — three nested loops in `Invoke-FullScan` (lines 560–579) that drive the work:
  - Outer browser loop: lines 560–579 (`foreach ($browser in $Script:BrowsersFound)`).
  - Inner profile loop for Chromium browsers: lines 570–574 (`foreach ($profile in $profiles)` calling `Get-ChromiumExtensions`).
  - The hot inner loop with the actual I/O: **lines 192–285 in `Get-ChromiumExtensions`** (`foreach ($extDir in $extDirs)` reads `manifest.json` and, on `__MSG_*__` names, walks `_locales/<locale>/messages.json` for each of `en`/`en_US`/`en_GB`/`default`, and on miss enumerates *every* `_locales/*/messages.json` directory until one matches — see lines 217–250). Firefox parallel: lines 303–338 in `Get-FirefoxExtensions` (`foreach ($profile in $profiles)` + nested `foreach ($addon in $data.addons)` at line 311). These are the candidate loops named in C13.
- **Reference:** [C13](00-cross-cutting.md#c13--sequential-foreach-over-large-datasets-where-parallelism-would-help)
- **Local notes:** Each Chromium extension triggers 1 disk-read for `manifest.json`; localized-name extensions trigger up to 4 *additional* reads for the preferred-locale list, and on cache miss can degenerate to N more reads (one per installed `_locales` subdirectory). A user with 5 browsers × 2 profiles × 30 extensions × 1.5 avg manifest reads ≈ **450 sequential `Get-Content` calls** on cold SSD. The work is embarrassingly parallel — each extension directory is independent — and would map cleanly onto `Invoke-SouliTEKParallel` (the C13 runspace-pool helper proposed for P4) at either the per-browser or per-extension level. **Do not refactor until the module helper exists** (C13 P4 dependency). When the refactor lands, parallelise at the per-profile level inside `Invoke-FullScan` (lines 570–574) rather than inside `Get-ChromiumExtensions` — that keeps the parallel boundary at a coarse, easy-to-reason-about granularity (~10 work units) and avoids spawning hundreds of micro-jobs. Expected speedup: 3–5× on cold cache, smaller on warm.
- **Local notes (cont.) — separate perf issue, redundant heuristic recomputation:** `Test-SuspiciousExtension` is called against the same extension multiple times across `Show-ExtensionDetails` (line 447), `Show-ScanSummary` (line 495), `Invoke-FullScan` filter (line 587), `Show-RiskyExtensions` filter (line 653), and `Export-ScanResults` (line 704). After a full scan that surfaces risky extensions, every extension gets evaluated **at least 2×**, and risky ones **3×**. The heuristic itself is cheap (string `-like` matches against ~13-item lists), but for very large extension counts the duplication is wasteful and creates a correctness risk if the heuristic ever becomes stateful (currently it isn't). Suggested fix: in `Invoke-FullScan` (after line 579), augment each `$ext` in `$Script:ScanResults` with `RiskLevel`/`Warnings` properties from a single `Test-SuspiciousExtension` pass, then have downstream functions read those properties. Independent of C13.
- **Target phase:** P4

### F4 — No `[CmdletBinding()]` on script or any function
- **Severity:** low
- **Category:** structure
- **Location:** scripts/browser_plugin_checker.ps1 — script-level (no `param()` block) and every one of the 14 internal functions (`Get-InstalledBrowsers` line 68, `Get-ChromiumProfiles` line 147, `Get-ChromiumExtensions` line 172, `Get-FirefoxExtensions` line 290, `Test-SuspiciousExtension` line 348, `Show-BrowserSummary` line 409, `Show-ExtensionDetails` line 437, `Show-ScanSummary` line 481, `Invoke-FullScan` line 536, `Show-AllExtensions` line 609, `Show-RiskyExtensions` line 638, `Export-ScanResults` line 680, `Show-Help` line 746, `Show-Menu` line 797).
- **Local notes:** The script is fully interactive (no `param()` block, no CLI surface), so this is low-severity. Adding `[CmdletBinding()]` to `Get-ChromiumExtensions`, `Get-FirefoxExtensions`, and `Test-SuspiciousExtension` would let them accept `-Verbose` and `-ErrorAction` from callers — useful when the C13 parallel refactor lands and per-extension errors need to surface. The Helper functions already use `<# .SYNOPSIS #>` blocks consistently — adding `[CmdletBinding()]` between the comment and the existing `param(...)` block is a one-line change per function.
- **Target phase:** P4

### F5 — Silently swallowed JSON parse errors hide malformed extensions
- **Severity:** info
- **Category:** error-handling
- **Location:** scripts/browser_plugin_checker.ps1:280–282 (Chromium manifest), 227–229 and 245–247 (locale messages), 335–337 (Firefox `extensions.json`).
- **Current pattern:**
  ```powershell
  try {
      $manifest = Get-Content $manifestPath -Raw -ErrorAction Stop | ConvertFrom-Json
      # ...
  }
  catch {
      # Skip extensions with invalid manifests
  }
  ```
- **Local notes:** A genuinely corrupt or tampered-with `manifest.json` is a security signal worth surfacing — it could indicate a partial install, disk corruption, or (more interestingly for a security tool) a malware family that deliberately writes a syntactically-invalid manifest to evade enumeration. The current `# Skip extensions with invalid manifests` swallow drops this signal. Suggested change: emit a `Write-Verbose "Skipped $manifestPath: $_"` inside each `catch` so the failure is visible under `-Verbose` (and once F4 adds `[CmdletBinding()]` to these functions, the verbose stream propagates). Do **not** convert to a hard failure — one bad manifest must not abort the scan. The three locale-message swallow blocks (lines 227–229, 245–247) are lower-priority since they fail back to the extension ID, which is exactly the documented behavior in `Show-ExtensionDetails` lines 457–459. Address all five `catch` blocks together.
- **Target phase:** P4

### F6 — Hard-coded Desktop output path with no override
- **Severity:** info
- **Category:** structure
- **Location:** scripts/browser_plugin_checker.ps1:700 (`$desktopPath = [Environment]::GetFolderPath("Desktop")`) and 729 (`$outputPath = Join-Path $desktopPath "Browser_Extensions_$timestamp.$extension"`).
- **Local notes:** Same pattern as F7 of driver_integrity_scan.md. The CSV/TXT/HTML export target is always the current user's Desktop. Under SYSTEM-context execution `[Environment]::GetFolderPath("Desktop")` returns `C:\Windows\System32\config\systemprofile\Desktop` which may not exist. Note: `[Environment]::GetFolderPath("Desktop")` is *slightly* better than `$env:USERPROFILE\Desktop` because it honors the Known Folder redirection (OneDrive Desktop sync, etc.), but it still doesn't help under SYSTEM. A `-OutputDirectory` parameter on `Export-ScanResults` would be the clean fix, paired with F4's `[CmdletBinding()]` add. Low-priority because the menu-driven design assumes interactive use.
- **Target phase:** P4

### F7 — `Split-Path -Parent $MyInvocation.MyCommand.Path` instead of `$PSScriptRoot`
- **Severity:** low
- **Category:** structure
- **Location:** scripts/browser_plugin_checker.ps1:25
- **Current:**
  ```powershell
  $Script:ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
  ```
- **Recommended:**
  ```powershell
  $Script:ScriptPath = $PSScriptRoot
  ```
- **Risk if changed:** Low. `$PSScriptRoot` is the canonical PS 3.0+ automatic variable for "directory of the running script." `$MyInvocation.MyCommand.Path` returns `$null` when the script is dot-sourced, so the current form is slightly more fragile. C10 will eventually replace this whole block (lines 25–33) with `Import-SouliTEKCommon`, but until then this one-line fix is free.
- **Target phase:** P4 (fold into the C10 sweep)

### F8 — Infinite menu loop with no non-interactive exit + blocking `Read-Host` / `Wait-SouliTEKKeyPress`
- **Severity:** low
- **Category:** structure (UX / RMM safety)
- **Location:** scripts/browser_plugin_checker.ps1:852 (`do { ... } while ($true)`), plus `Read-Host` at line 854 and 9 `Wait-SouliTEKKeyPress` calls (lines 554, 606, 618, 635, 647, 677, 689, 743, 794).
- **Local notes:** Same RMM-hang concern as F6 of driver_integrity_scan.md. The script is interactive-only by design — the only graceful exit is menu option `[0]` (lines 862–865). There is no `[Environment]::UserInteractive` gate. If invoked by the launcher in a non-interactive flow, every `Wait-SouliTEKKeyPress` will deadlock. Defer to P4 unless an actual RMM hang report comes in; pairs naturally with the same recommendation against `Wait-SouliTEKKeyPress` (F10 of 01-modules-SouliTEK-Common.md).
- **Target phase:** P4

### F9 — `$Script:SuspiciousPatterns` and `$Script:RiskyPermissions` are reasonable but unsourced and very short
- **Severity:** info
- **Category:** correctness / docs (note only — no immediate change recommended)
- **Location:** scripts/browser_plugin_checker.ps1:43–62
- **Local notes:** The suspicious-keyword list (`coupon`, `deal`, `discount`, `shop`, `price`, `save`, `miner`, `crypto`, `bitcoin`, `coin`, `toolbar`, `search helper`, `download helper`, `free vpn`, `proxy`, `unblocker`) and risky-permission list (`all_urls`, `<all_urls>`, `webRequest`, `cookies`, `history`, `tabs`, `clipboardRead`/`Write`, `nativeMessaging`, `proxy`, `privacy`, `management`) capture the obvious cases but will (a) produce false positives — a legitimate coupon extension flagged as adware, a developer-tools extension legitimately needing `tabs`+`webRequest`+`cookies` — and (b) miss anything the operator-chosen keywords don't cover. The risky-permission list aligns reasonably well with the Chrome `permission_warnings` table but isn't sourced from it. **No code change recommended in this audit** — the script is documented as a triage aid, not a malware scanner, and the lists are a sensible starting point. A future improvement (out of P1–P5 scope) would be to pull the suspicious-keyword list out to a configurable JSON file under `config/browser_plugin_checker.json` so operators can extend it without editing the script. The matching itself uses PowerShell `-like` with `*pattern*` (line 362), which is reasonable; it is **not** subject to regex injection because `-like` uses wildcard not regex syntax. Note: line 386 *does* use `-match` for `<all_urls>` and `\*://\*/\*` — the second is regex-quoted correctly.
- **Target phase:** —

### F10 — `Get-ChromiumProfiles` does not detect the `System Profile` directory and treats `Default` specially
- **Severity:** info
- **Category:** correctness
- **Location:** scripts/browser_plugin_checker.ps1:147–170
- **Local notes:** `Get-ChromiumProfiles` returns the literal string `"Default"` if the directory exists, plus any `Profile *` directories. It does not enumerate the `System Profile` directory (used by Chromium internally) — that's correct, system profile has no user extensions. But it also does not handle the rare case where a user has renamed a profile via `--profile-directory=` to something other than `Default`/`Profile N` — those would be silently skipped. Low-priority since the renamed-profile case is rare and the consequence is "this extension didn't appear in the scan" rather than a security regression. Mention only.
- **Target phase:** —

## Out-of-scope notes
- Banner block (lines 1–14, 14 lines of `# === / Coded by / (C) 2025`) matches C11 cross-cutting cleanup; covered there. Note: this banner is shorter than most other scripts (no inline disclaimer about destructive behavior, which is appropriate since the script is read-only).
- The common-module import block (lines 21–33) is the standard 9-line C10 pattern; covered there.
- The `Get-InstalledBrowsers` function (lines 68–145) has a leftover `foreach ($path in $chromePaths)` loop on lines 82–92 that always tests the same path (`$env:LOCALAPPDATA\Google\Chrome\User Data`) regardless of which `$path` is being iterated — the `$chromePaths` array is unused. The loop should either drop the array or actually iterate it. Cosmetic dead code, low-priority cleanup.
- The `Show-ExtensionDetails` function (line 470) truncates Permissions to 80 chars with `Substring(0, [Math]::Min(80, $Extension.Permissions.Length))` and appends `...` unconditionally — so a permissions string of exactly 80 chars still shows `...`. Cosmetic. Same pattern for description in `Get-ChromiumExtensions` line 272 and `Get-FirefoxExtensions` line 320. Not worth a finding.
- `Export-SouliTEKReport` (line 738) is called via the existing module API with `-OpenAfterExport:($formats.Count -eq 1)` — sensible behavior (only auto-open when one format was selected; suppress when "all formats" was chosen to avoid three windows opening). No change needed.
- `Show-SouliTEKExportMenu` (line 693) returns the string `"CANCEL"` which is then string-compared (line 695). Standard module pattern, no change needed.
- The `-Filter "Profile *"` glob in `Get-ChromiumProfiles` line 164 is correct — `Get-ChildItem`'s `-Filter` uses Windows file-system wildcards (faster than `-Include`/`Where-Object`) and matches `Profile 1`, `Profile 2`, etc.
- The Firefox `extensions.json` parse (lines 308–333) correctly filters `$addon.type -eq "extension"` and excludes `app-system-defaults` location — appropriate for "show me what the user installed, not what Firefox bundled."
- No security-sensitive data (cookies DBs, login data, browsing history) is read by this script — it only touches `manifest.json` and `extensions.json`. Aligns with CLAUDE.md "least privilege" — request only what's needed.
- The trailing blank line at the end of the file (line 873) is harmless.
