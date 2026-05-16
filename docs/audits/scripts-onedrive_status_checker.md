# Audit — scripts/onedrive_status_checker.ps1

## Inventory
| Item | Value |
|---|---|
| Path           | scripts/onedrive_status_checker.ps1 |
| LOC            | 1029 |
| Functions      | 14 |
| `#Requires`    | `#Requires -Version 5.1` |
| Admin-required | no (reads `HKCU:\Software\Microsoft\OneDrive`, enumerates the current user's `OneDrive.exe` process, and reads files under `$env:LOCALAPPDATA\Microsoft\OneDrive\logs` — all per-user, no `HKLM` writes, no service control, no mutation). |
| Last touched   | 8675720 — 2026-04-17 |
| Modernization grade | B |

## Summary

A menu-driven OneDrive triage tool: probes installation (filesystem + registry), checks the `OneDrive.exe` process, enumerates accounts from `HKCU:\Software\Microsoft\OneDrive\Accounts`, infers sync state from `settings\*\global.ini`'s `syncEngineState=` line, regex-scans the last 7 days of OneDrive's text logs for a hand-built list of error patterns, and renders the results via `Write-Ui` + a thick `Write-Host` decoration layer (75 calls — the predicted hotspot). Unlike the C-grade scripts already audited, this file is already substantially migrated to `Write-Ui` — most message lines use the helper correctly. The remaining `Write-Host` use is concentrated in three legitimate-but-loud categories: (1) bare `Write-Host ""` blank-line spacers (~37 of 75 occurrences — separator-helper exception applies), (2) `==========` divider banners (lines 631, 653, 666, 714, 760, 762, 781, 819, 821, 988) which should migrate to a `Show-Section`/`Write-Ui -Spacer` helper added in P4, and (3) genuine C1 violations: inline-color label formatting like `Write-Host "  RESULT: " -NoNewline -ForegroundColor White` followed by `Write-Ui "..."` (lines 563–564, 636, 640, 644, 648, 676, 684, 692, 703, 711, 719, 722, 725, 728, 824, 827, 830, 834, 839, 938–948). The 13 `-ErrorAction SilentlyContinue` occurrences are all defensible registry/filesystem/process probes — every one is tagged **A** (see F2 triage), but eight of them are paired with empty `catch {}` blocks (lines 127, 206, 276, 307, 359, 362, 407, 437) which is a separate finding (F5) because the wrapper genuinely loses signal even though the SCSC tag itself is correct. Secondary concerns: no `[CmdletBinding()]` anywhere, no `param()` block, no `$PSScriptRoot` (uses the fragile `Split-Path $MyInvocation.MyCommand.Path` idiom), the dot-source boilerplate at lines 25–33 will be folded into C10's `Import-SouliTEKCommon` sweep, four lingering `Write-SouliTEKResult`/`Write-SouliTEKSuccess`/`Write-SouliTEKWarning` callers at lines 747, 752, 805, 866 keep the C2 dead API alive, and one latent bug at line 351 (`Substring` upper-bound computed against the pre-`Trim()` length). Recommended phase entry order: P1 (C1 + C2), then P2 (C4 — but mostly comment-only since all 13 are tag A), then P4 (folder/account extract helpers — `Invoke-FullScan` at 213 lines is the obvious extract candidate).

## Findings

### F1 — Mixed `Write-Host` / `Write-Ui` / `Write-SouliTEK*` (see C1)
- **Severity:** med
- **Category:** output-style
- **Location:** scripts/onedrive_status_checker.ps1 — 75 raw `Write-Host` occurrences and 4 legacy `Write-SouliTEK*` wrapper calls (lines 747, 752, 805, 866).
- **Reference:** [C1](00-cross-cutting.md#c1--raw-write-host-calls-not-migrated-to-write-uiwrite-status), [C2](00-cross-cutting.md#c2--dead-duplicate-output-api)
- **Current (representative C1 pattern — inline-label formatting at lines 636–637):**
  ```powershell
  Write-Host "  RESULT: " -NoNewline -ForegroundColor White
  Write-Ui -Message "OneDrive is Up To Date!" -Level "OK"
  ```
- **Recommended:**
  ```powershell
  Write-Ui -Message "RESULT: OneDrive is Up To Date!" -Level "OK"
  ```
- **Risk if changed:** Low — message text preserved verbatim; the `[OK]` bracket from `Write-Ui` replaces the manually-coloured "RESULT:" label. Per-category fix patterns enumerated in Local notes.
- **Local notes:** Three categories of raw `Write-Host` in this file:
  1. **Blank-line spacers** — bare `Write-Host ""` used as vertical spacing. ~37 occurrences (lines 454, 485, 490, 519, 549, 577, 597, 630, 632, 652, 667, 713, 715, 732, 753, 755, 763, 771, 780, 782, 789, 806, 811, 822, 846, 853, 867, 917, 931, 936, 950, 956, 960, 964, 979, 987, 1025). Covered by the "visual separator helpers" exception in C1 — not strictly violations, but should migrate to a `Write-Ui -Spacer` helper when one ships in P4.
  2. **Banner/divider lines** — `Write-Host "============================================================" -ForegroundColor Cyan/Yellow/DarkGray` (lines 631, 653, 666, 714, 760, 762, 781, 819, 821, 988). Same exception applies, but these are stronger candidates for a `Show-Section -Color Cyan` helper because the literal divider is duplicated 10× verbatim. C1 sweep should leave them alone; P4 helper extraction sweep should fold them.
  3. **Real C1 violations — inline label formatting** — `Write-Host "  LABEL: " -NoNewline -ForegroundColor White` followed by either `Write-Ui ...` or a second `Write-Host "value" -ForegroundColor X` (lines 563–564, 636, 640, 644, 648, 676, 684, 692, 703, 711, 719, 722, 725, 728, 824, 827, 830, 834, 839 and the help-screen colour-key block 938–948). These predate the `Write-Ui` adoption and should be collapsed into single `Write-Ui` calls. The colour-key in `Show-Help` (lines 938–948) is the trickiest — it intentionally shows the literal status-colour mapping as a legend, so keep the colours but move them into `Show-Help`'s text body via a small loop over `$Script:StatusCodeMap` rather than hand-coded `Write-Host` per colour.
- **Local notes (cont.) — inline marker prefixes:** Fewer than the C-grade scripts, but still present. Lines 528, 585, 608 embed `[$($account.AccountType)]` / `[$($folder.AccountType)]` / `[$($_.Timestamp...)]` brackets in messages already prefixed with `[INFO]`/`[WARN]` by `Write-Ui`. These are *data* brackets (account type, timestamp) rather than the F2-of-driver-audit-style `[*]`/`[+]`/`[-]` severity brackets, so they are not C1 anti-patterns — leave them. The menu-option labels on lines 980–986 (`  [1] Full Scan`) are the same — those numeric brackets are UX, not severity duplication.
- **Local notes (cont.) — legacy API callers:** Only 4 calls survive: `Write-SouliTEKResult` at line 747, `Write-SouliTEKSuccess` at line 752, `Write-SouliTEKWarning` at lines 805 and 866. Trivial 1:1 migration to `Write-Ui -Message ... -Level INFO/OK/WARN`. Once these four lines flip, this file is fully off the C2 dead API.
- **Target phase:** P1

### F2 — `-ErrorAction SilentlyContinue` triage (see C4)
- **Severity:** med (per-occurrence) — but every occurrence here is tag **A**
- **Category:** error-handling
- **Location:** scripts/onedrive_status_checker.ps1 — 13 occurrences
- **Reference:** [C4](00-cross-cutting.md#c4----erroraction-silentlycontinue-swallowing-failures)
- **Triage:**
  - Line 118: tag **A** — `(Get-ItemProperty $regPath -ErrorAction SilentlyContinue).OneDriveTrigger`. Optional registry value probe — the result is `$null`-tested on the next line with `if ($oneDrivePath -and (Test-Path $oneDrivePath))`. Legitimate. Add `# safe: probe` comment.
  - Line 123: tag **A** — `(Get-Item $oneDrivePath -ErrorAction SilentlyContinue).VersionInfo.ProductVersion`. The path was just `Test-Path`'d two lines above (line 119), so this is belt-and-braces; safe to keep as a probe in case of a TOCTOU race with an uninstaller. Add `# safe: probe`.
  - Line 140: tag **A** — `Get-Process -Name "OneDrive" -ErrorAction SilentlyContinue` is the canonical "is the process running?" check; the absence of any process raises a non-terminating error that is correctly suppressed and tested via `if ($processes)`. Legitimate. Add `# safe: probe`.
  - Line 173: tag **A** — `Get-ChildItem $accountsPath -ErrorAction SilentlyContinue` enumerates the OneDrive account registry subkeys; the parent key was just `Test-Path`'d on line 172, but enumeration can still fail under HKCU policy locks (e.g. mandatory profile). Legitimate. Add `# safe: probe`.
  - Line 177: tag **A** — `Get-ItemProperty $folder.PSPath -ErrorAction SilentlyContinue` reads properties from each account subkey; surrounded by `try { ... } catch { Write-Ui -Message "Failed to read account info..." -Level "WARN" }` (lines 176–213) which is the *only* `catch` in the file that actually surfaces. Per-property absence is normal (different OneDrive versions, different account types). Legitimate. Add `# safe: probe`.
  - Line 263: tag **A** — `Get-ItemProperty $regPath -ErrorAction SilentlyContinue` in `Get-OneDriveSyncStatus`. Same probe pattern as line 177. Legitimate. Add `# safe: probe`.
  - Line 289: tag **A** — `Get-Content $statusFile -Raw -ErrorAction SilentlyContinue` reads `global.ini`; the file was just `Test-Path`'d on line 287, but is held open by OneDrive itself and may transiently refuse a shared read. Surrounded by a `catch {}` (F5). Add `# safe: probe`.
  - Line 334: tag **A** — `Get-ChildItem -Path $logPath -Filter "*.txt" -ErrorAction SilentlyContinue | Where-Object { ... }`. Log directory enumeration; the directory was just `Test-Path`'d on line 331. Legitimate per-file failures (open exclusive by OneDrive's logger) suppressed. Add `# safe: probe`.
  - Line 342: tag **A** — `Get-Content $logFile.FullName -Tail 1000 -ErrorAction SilentlyContinue`. Reads the tail of an actively-written log file — exactly the case where `SilentlyContinue` is mandatory because OneDrive will sometimes hold an exclusive lock during rotation. Legitimate. Add `# safe: probe`.
  - Line 384: tag **A** — duplicate of line 173 (same `Get-ChildItem $accountsPath` enumeration in `Get-OneDriveFolderInfo`). Legitimate. Add `# safe: probe`. **Note:** lines 161–215 (`Get-OneDriveAccounts`) and lines 380–409 (`Get-OneDriveFolderInfo`) iterate the *exact same* registry tree — extraction candidate in P4 (see F8).
  - Line 388: tag **A** — duplicate of line 177 in `Get-OneDriveFolderInfo`. Legitimate. Add `# safe: probe`.
  - Line 394: tag **A** — `Get-ChildItem -Path $folderPath -Recurse -File -ErrorAction SilentlyContinue | Measure-Object`. The OneDrive folder may contain placeholders (Files-On-Demand), locked OST sidecars, and reparse points; per-item failures during recursive enumeration are expected and the `Measure-Object` consumes whatever survives. Legitimate, but note the *performance* implication: a fully-synced 100k-file OneDrive folder will take minutes to walk here. Add `# safe: probe` and a `# perf: scales O(n) with file count` comment.
  - Line 425: tag **A** — same `Get-ChildItem -Recurse -File -ErrorAction SilentlyContinue` pattern as line 394, but for the fall-back common paths (`$env:USERPROFILE\OneDrive`, etc.). Same triage. Add `# safe: probe` + perf comment.
- **Local notes:** 13/13 are tag A — there are zero tag-B or tag-C occurrences in this file. The C4 sweep on this script is *cosmetic only* (add `# safe: ...` comments). The real swallow-the-bug issue lives in the empty `catch {}` blocks paired with several of these probes — broken out as F5.
- **Target phase:** P2

### F3 — Largest functions (see C6)
- **Severity:** med
- **Category:** structure
- **Location:** scripts/onedrive_status_checker.ps1 — 1029 LOC across 14 functions, so the average function is healthy (~70 lines including blanks). The size problem is concentrated in one outlier.
- **Reference:** [C6](00-cross-cutting.md#c6--scripts-1000-loc-with-extractable-duplication)
- **Top 7 by line span:**
  1. **`Invoke-FullScan` — lines 445–656 (~213 lines).** Six numbered steps (Installation, Process, Accounts, Sync Status, Folder Info, Errors) plus banner/summary. Each step is a `Write-Ui` heading → call a `Get-*` function → push a `PSCustomObject` into `$Script:OneDriveResults`. The repetition is mechanical and 6× — prime extraction candidate. Recommended P4 refactor: one `Add-OneDriveResult -Category X -Item Y -Status Z -Details D -Path P` helper to eliminate the 6 duplicated `$Script:OneDriveResults += [PSCustomObject]@{...}` blocks (lines 469–475, 478–484, 501–507, 510–516, 530–536, 540–546, 569–575, 587–593, 611–617, 621–627), and one `Show-StepHeader -Number 3 -Title "Get accounts"` helper for the per-step banner. Net delta after extraction: ~120 lines from 213.
  2. **`Get-OneDriveSyncStatus` — lines 220–319 (~101 lines).** Two distinct concerns: (a) registry-based status (lines 254–278, reading `EnabledForUser` / `SilentBusinessConfigCompleted`) and (b) file-based status (lines 280–309, parsing `syncEngineState=` from `global.ini`). Split into `Get-OneDriveSyncStatusFromRegistry` and `Get-OneDriveSyncStatusFromIni`, merge results in the caller. Also: the `$AccountName` parameter (line 226) is referenced exactly once on line 257 — when the caller (line 553) passes nothing, the second `regPath` entry collapses to `HKCU:\...\Accounts\` which `Test-Path` then rejects silently. Either remove the unused parameter or make it actually drive per-account lookup; the current state is dead-ish code.
  3. **`Show-QuickStatus` — lines 658–735 (~79 lines).** Renders a 4-row summary table (Installation / Process / Accounts / Sync Status) by interleaving `Write-Host "label: " -NoNewline -ForegroundColor White` with a `Write-Ui` value line. Ten such row pairs. Recommended P4 refactor: a `Show-StatusRow -Label "Installation" -Value $val -Level OK` helper, OR migrate to a `Format-Table`-style column render. Net delta: ~30 lines from 79.
  4. **`Get-OneDriveFolderInfo` — lines 372–443 (~73 lines).** Two halves: (a) registry-driven account-folder enumeration (lines 380–409) and (b) env-var-driven common-path enumeration (lines 411–440). The bodies of the two `if (Test-Path ...) { Measure-Object stats; push PSCustomObject }` blocks are nearly identical — extract a `Get-FolderStatistics -Path $p -AccountType $t` private helper. Also: line 423 `if ($folderInfo.FolderPath -notcontains $path)` will throw if `$folderInfo` is `@()` on the first iteration (no `.FolderPath` member) — works only because of PowerShell's lenient property-on-array behavior. Convert to `if (-not ($folderInfo | Where-Object FolderPath -eq $path))` for clarity.
  5. **`Show-AccountDetails` — lines 794–857 (~65 lines).** Per-account rendering loop with the same inline-label `Write-Host` anti-pattern as `Show-QuickStatus`. Same `Show-StatusRow` helper would compress this.
  6. **`Export-OneDriveResults` — lines 859–920 (~63 lines).** Already calls into the shared `Export-SouliTEKReport` and `Show-SouliTEKExportMenu` helpers — this is the *model* function for how the rest of the file should look. Only nit: the `$exportData = $Script:OneDriveResults | ForEach-Object { [PSCustomObject]@{...} }` block (lines 881–889) is an identity-copy of `$Script:OneDriveResults` with the same fields in the same order. Just pass `$Script:OneDriveResults` directly to `Export-SouliTEKReport -Data` and delete lines 881–889.
  7. **`Get-OneDriveAccounts` — lines 161–218 (~59 lines).** Healthy; the only structural note is that it shares its registry-iteration scaffolding with `Get-OneDriveFolderInfo` (see point 4 above) — both walk `HKCU:\Software\Microsoft\OneDrive\Accounts`. Extract `Get-OneDriveAccountSubkeys` returning `$folder, $props` pairs to deduplicate.
- **Local notes:** Post-extraction, the file would drop to ~750 LOC and `Invoke-FullScan` would shrink to ~90 lines. None of these refactors are P1 or P2 priorities — they fold into the C6 sweep in P4 after the parallel/extraction helpers ship.
- **Target phase:** P4

### F4 — No `[CmdletBinding()]` on script or any function
- **Severity:** low
- **Category:** structure
- **Location:** scripts/onedrive_status_checker.ps1 — script-level (no `param()` block at all) and every one of the 14 internal functions.
- **Local notes:** The task plan predicted "B-grade" — confirmed, partly because the script is *almost* clean except for the missing `CmdletBinding`. The script is fully interactive (menu loop in `Show-MainMenu`), so this is low-severity. Adding `[CmdletBinding()]` is most valuable on the `Get-*` functions (`Test-OneDriveInstalled`, `Get-OneDriveProcess`, `Get-OneDriveAccounts`, `Get-OneDriveSyncStatus`, `Get-OneDriveSyncErrors`, `Get-OneDriveFolderInfo`) so an external caller — e.g. an RMM script that wants just the JSON status without the menu — can use `-Verbose` and `-ErrorAction`. C5 territory only if a non-interactive `-Format JSON` parameterised entry point lands; reasonable P3 follow-up.
- **Target phase:** P4

### F5 — Empty `catch {}` blocks paired with `SilentlyContinue` probes
- **Severity:** med
- **Category:** error-handling
- **Location:** scripts/onedrive_status_checker.ps1 — 8 occurrences: lines 127, 206, 276, 307, 359, 362, 407, 437.
- **Local notes:** Distinct from F2 (C4 triage) because the `-ErrorAction SilentlyContinue` on the inner cmdlets is correct (probe semantics), but the *outer* `try { ... } catch {}` block converts any remaining terminating exception — e.g. `MethodInvocationException` from `[DateTime]::FromFileTime($props.LastSignInTime)` on line 204 when the value is corrupt, or the `Substring` bug at line 351 (see F7) — into total silence. Per CLAUDE.md "fail closed — deny by default," these eight empty catches all violate the project standard:
  - Lines 127 & 206 (`Test-OneDriveInstalled` registry probe; `Get-OneDriveAccounts` date conversion): swallow exceptions during installation/account discovery. Should at minimum `Write-Verbose "$_"` so `-Verbose` surfaces them.
  - Lines 276 & 307 (`Get-OneDriveSyncStatus`'s registry and `global.ini` reads): same.
  - Lines 359 & 362 (`Get-OneDriveSyncErrors`'s inner per-file and outer per-directory): the inner one wraps the `Substring` bug (F7) and silently drops the entire log file when triggered. Should be `catch { Write-Verbose "Skipping log $($logFile.Name): $_" }`.
  - Lines 407 & 437 (`Get-OneDriveFolderInfo`'s two halves): swallow per-folder enumeration exceptions; user gets an empty folder list with no signal as to why. Should be `catch { Write-Verbose "Skipping folder $path: $_" }`.
- **Recommended pattern across all eight:**
  ```powershell
  } catch {
      Write-Verbose "Probe failed at <site>: $_"
  }
  ```
- **Risk if changed:** Low. `Write-Verbose` is off by default so no user-visible change without `-Verbose`. Pairs with the F4 `[CmdletBinding()]` add — once functions accept `-Verbose`, these become actually useful.
- **Target phase:** P2 (same phase as C4 — fix together since the SCSC triage already touches the same call sites)

### F6 — `Split-Path -Parent $MyInvocation.MyCommand.Path` instead of `$PSScriptRoot`
- **Severity:** low
- **Category:** structure
- **Location:** scripts/onedrive_status_checker.ps1:25
- **Current:**
  ```powershell
  $Script:ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
  $Script:RootPath = Split-Path -Parent $Script:ScriptPath
  ```
- **Recommended:**
  ```powershell
  $Script:RootPath = Split-Path -Parent $PSScriptRoot
  ```
- **Risk if changed:** Low. Identical behavior when the script is invoked normally; `$PSScriptRoot` is the canonical PS 3.0+ automatic variable and is non-null under dot-sourcing too (where `$MyInvocation.MyCommand.Path` returns `$null`). Will be subsumed by C10's `Import-SouliTEKCommon` sweep anyway, but the one-line fix is free.
- **Target phase:** P4 (fold into C10)

### F7 — Latent bug: `Substring` upper-bound computed against pre-Trim length
- **Severity:** med
- **Category:** correctness
- **Location:** scripts/onedrive_status_checker.ps1:351
- **Current:**
  ```powershell
  Message = $line.Trim().Substring(0, [Math]::Min(200, $line.Length))
  ```
- **Recommended:**
  ```powershell
  $trimmed = $line.Trim()
  Message = $trimmed.Substring(0, [Math]::Min(200, $trimmed.Length))
  ```
- **Local notes:** When a matched log line has leading whitespace (and OneDrive's logs frequently do — timestamps are prefixed with spaces during indented stack traces), `$line.Length` is larger than `$line.Trim().Length`, so `Min(200, $line.Length)` can exceed the trimmed string's length. Example: a 180-char line with 30 leading spaces → `$line.Trim().Length = 150`, `Min(200, 180) = 180`, `$line.Trim().Substring(0, 180)` throws `ArgumentOutOfRangeException`. The exception is then swallowed by the empty `catch {}` on line 359 (F5), which silently drops the *entire log file* from the scan — not just the one line. So the bug is invisible but causes false-negative error reporting whenever a log file contains an indented matched line in its tail. Worth fixing in P2 alongside the C4 + F5 cleanup since the same `try { ... }` block is being touched.
- **Risk if changed:** Low. Strict bug fix with no behavior change on well-formed input.
- **Target phase:** P2

### F8 — `$error` automatic-variable shadowing in `Show-SyncErrors`
- **Severity:** low
- **Category:** correctness (style)
- **Location:** scripts/onedrive_status_checker.ps1:766 (`foreach ($error in $Script:SyncErrors)`) — and subsequent uses at lines 767, 768, 769, 770.
- **Current:**
  ```powershell
  foreach ($error in $Script:SyncErrors) {
      Write-Ui -Message "[$index] $($error.Timestamp.ToString('yyyy-MM-dd HH:mm:ss'))" -Level "INFO"
      ...
  }
  ```
- **Recommended:**
  ```powershell
  foreach ($syncError in $Script:SyncErrors) {
      Write-Ui -Message "[$index] $($syncError.Timestamp.ToString('yyyy-MM-dd HH:mm:ss'))" -Level "INFO"
      ...
  }
  ```
- **Risk if changed:** Low. `$Error` is the PowerShell automatic variable holding the error stream collection; shadowing it inside a loop is harmless in *this* file because nothing in the loop reads `$Error`, but it is a PSScriptAnalyzer rule (`PSAvoidAssignmentToAutomaticVariable`) and is a footgun if anyone later adds error-handling logic that expects the global. Trivial rename.
- **Target phase:** P1 (cheap, paired with the F1 sweep that touches this function)

### F9 — `Write-Host` "Press Enter to exit" fallback in top-level catch is `Read-Host`
- **Severity:** info
- **Category:** structure (UX / RMM safety)
- **Location:** scripts/onedrive_status_checker.ps1:1023–1027
- **Current:**
  ```powershell
  catch {
      Write-Ui -Message "An error occurred: $($_.Exception.Message)" -Level "ERROR"
      Write-Host ""
      Read-Host "Press Enter to exit"
      exit 1
  }
  ```
- **Local notes:** The top-level catch correctly logs and exits non-zero, but the intervening `Read-Host` will deadlock under SYSTEM-context RMM execution (flagged in user's CLAUDE.md as a deployment scenario). Same `[Environment]::UserInteractive` gate recommendation as the menu loop. The two `Read-Host` calls in this file (lines 990, 1026) are the only interactive blockers; both should defer to a `Wait-SouliTEKKeyPress -NonInteractiveSafe` helper that no-ops when `-not [Environment]::UserInteractive`. Defer to P4 unless an actual RMM hang report comes in.
- **Target phase:** P4

### F10 — `Format-SouliTEKFileSize` called without explicit parameter binding
- **Severity:** info
- **Category:** style
- **Location:** scripts/onedrive_status_checker.ps1:402, 433, 499, 505
- **Current:**
  ```powershell
  TotalSizeFormatted = Format-SouliTEKFileSize ($stats.Sum)
  Write-Ui -Message "Memory: $(Format-SouliTEKFileSize $processInfo.Memory)" -Level "INFO"
  ```
- **Local notes:** When `$stats.Sum` is `$null` (empty folder, or `Measure-Object` returned no objects), positional-binding still works because the helper presumably handles `0`/`$null` gracefully — but this is a contract assumption worth surfacing. Not worth fixing standalone; flag as a note for whoever touches `Format-SouliTEKFileSize`'s signature (no recommended change here, this is informational).
- **Target phase:** —

## Out-of-scope notes
- Banner block (lines 1–14, 14 lines of `# === / Coded by / This tool checks ...`) matches C11 cross-cutting cleanup; covered there.
- The `$Script:StatusCodeMap` hashtable (lines 47–56) is a clean lookup table mapping the 8 OneDrive sync status codes to display name + color + human description. Comprehensive and well-organized — a model for this kind of enum-to-text mapping. No change needed.
- The `$Script:ErrorPatterns` array (lines 59–74) is hand-curated from observed OneDrive log patterns. Reasonable starter set; could grow over time as new failure modes are observed. The regex `"Error\s*0x"` at line 60 is intentionally broad (matches `Error 0x80004005` etc.) — note that this means any log line containing the literal substring "Error 0x" will be flagged, including informational entries that *describe* historical errors. Acceptable trade-off for surfacing actionable items.
- The `Get-OneDriveSyncErrors` log-scanning approach (lines 321–370) reads `-Tail 1000` of the last 10 log files modified in the last 7 days. That bounded approach is the right call for a log directory that can otherwise grow into hundreds of MB — the alternative (regex over `Get-Content -Raw`) would OOM on busy clients. No change needed.
- The `Show-SouliTEKExitMessage`/`Show-SouliTEKDisclaimer`/`Show-ScriptBanner`/`Wait-SouliTEKKeyPress` helper calls show this script is already aware of the common module — unlike some C-grade scripts that re-implement banners inline. Good adoption.
- Trailing single blank line at line 1030 is harmless; trim in any pass that touches the file.
- One subtle assumption worth documenting (no fix needed): `Get-OneDriveProcess` (line 134) uses `Get-Process -Name "OneDrive"` which only finds processes owned by the *current user* — under SYSTEM context this returns `$null` even if a logged-in user has OneDrive running. The whole script is fundamentally per-user (HKCU + LOCALAPPDATA + per-user OneDrive.exe), so this matches the script's design — but it means the script is **not** useful for SYSTEM-context monitoring. Worth a one-line `# Note: per-user only — does not detect other users' OneDrive` comment somewhere visible.
