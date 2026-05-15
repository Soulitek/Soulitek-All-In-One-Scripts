# Audit — scripts/1-click_pc_install.ps1

## Inventory
| Item | Value |
|---|---|
| Path           | scripts/1-click_pc_install.ps1 |
| LOC            | 954 |
| Functions      | 17 |
| `#Requires`    | `#Requires -Version 5.1` only (no `-RunAsAdministrator`, even though the script enforces admin at runtime via `Test-SouliTEKAdministrator` on line 884) |
| Admin-required | yes (enforced at runtime; sets time zone, system locale, geo-id, system restore point, power plan via `powercfg`, removes provisioned `Appx` packages, installs software via WinGet, writes desktop shortcuts) |
| Last touched   | 8675720 — 2026-04-17 |
| Modernization grade | C |

## Summary

A one-shot PC bring-up orchestrator: time zone, regional/locale settings, system restore point, power plan, Appx bloatware removal, WinGet installs (Chrome, AnyDesk, Office), and desktop shortcuts. The script is the cleanest of the destructive-script set audited so far — almost every action is wrapped in a `try { ... } catch { Write-Ui -Level ERROR ... Add-LogEntry }` block, exit codes from WinGet are mapped to human-readable status, and a structured log is rendered at the end via `Show-InstallationSummary`. The recent commit `b79d132` ("Enhance WinGet installation process") added `Test-ApplicationInstalled`, `Get-WinGetErrorDetails`, and `Show-InstallationLog` plus the WinGet exit-code mapping at lines 575–604; that work materially raised the grade from a probable D to a C.

Primary remaining issues: (1) **C1** raw `Write-Host` is used 68 times, mostly as visual separators (`Write-Host ""` and `Write-Host "===..."`), but at least a dozen call sites do real inline-color formatting that must migrate to `Write-Ui` (lines 132, 139, 149, 507, 542, 548, 584, 600, 640, 696, 739, 806, 809, 813, 817, 820, 823, 827, 849, 850, 859, 866, 950); (2) **C4** ten `-ErrorAction SilentlyContinue` occurrences — eight are legitimate probes/cleanups (tag A), two are real bug-swallowers (tag B at lines 232 and 353 — `Enable-ComputerRestore` and `Remove-AppxPackage` swallow real failures and the subsequent `$?` test is incorrect because `SilentlyContinue` makes `$?` always `$true` for non-terminating errors); (3) **C5** the orchestrated sub-steps (`Set-TimeZone`, `Set-Culture`, `Set-WinHomeLocation`, `Set-WinSystemLocale`, `Set-WinUserLanguageList`, `Checkpoint-Computer`, `Remove-AppxPackage`, `powercfg /setactive`, `winget install`) are all destructive, but none happen through `[CmdletBinding(SupportsShouldProcess)]` — flagged in the summary per the task plan, not as a separate finding since C5 is the cross-cutting record for this class. Secondary: no `[CmdletBinding()]` anywhere (predicted count was 0, confirmed); the file uses `Split-Path -Parent $MyInvocation.MyCommand.Path` (C10 territory, line 51); `Ensure-WinGet` (line 661) uses an unapproved PowerShell verb (`Get-Verb` does not list `Ensure`); the legacy `Write-SouliTEKWarning` call at line 869 is the sole remaining C2 caller in this file; the `Add-LogEntry` function (line 76) mutates four `$Script:`-scoped counters via `switch` without locking (single-threaded so harmless, but worth a comment). Predicted counts: 954 LOC ✓, 68 `Write-Host` ✓, 10 `SilentlyContinue` ✓ — all three exact matches against the static scan. Recommended phase entry order: P1 (C1 + C2 single caller), then P2 (C4 triage — two tag-B cases need real fixes), then P3 (C5 `-WhatIf`/`-Confirm` retrofit aligned with `essential_tweaks` / `win11_debloat`).

## Findings

### F1 — Mixed `Write-Host` / `Write-Ui` / `Write-SouliTEKWarning` (see C1, C2)
- **Severity:** med
- **Category:** output-style
- **Location:** scripts/1-click_pc_install.ps1 — 68 raw `Write-Host` occurrences (lines 101, 104, 107, 110, 113, 116, 119, 122, 125, 128, 131, 132, 133, 138, 139, 140, 145, 148, 149, 156, 158, 366, 507, 515, 520, 524, 542, 548, 555, 584, 600, 640, 696, 714, 716, 722, 728, 736, 739, 745, 800, 806, 809, 812, 813, 814, 816, 817, 820, 823, 826, 827, 828, 830, 849, 850, 858, 859, 860, 865, 866, 867, 870, 872, 887, 898, 901, 950) plus 1 legacy `Write-SouliTEKWarning` call (line 869) that exercises C2's dead API.
- **Reference:** [C1](00-cross-cutting.md#c1--raw-write-host-calls-not-migrated-to-write-uiwrite-status), [C2](00-cross-cutting.md#c2--dead-duplicate-output-api)
- **Current (representative pattern — inline color at lines 806–810):**
  ```powershell
  Write-Host "  Installation completed at: " -NoNewline -ForegroundColor Gray
  Write-Ui -Message "$($endTime.ToString('yyyy-MM-dd HH:mm:ss'))" -Level "INFO"

  Write-Host "  Total duration: " -NoNewline -ForegroundColor Gray
  Write-Ui -Message "$([math]::Round($duration.TotalMinutes, 2)) minutes" -Level "INFO"
  ```
- **Recommended:**
  ```powershell
  Write-Ui -Message "Installation completed at: $($endTime.ToString('yyyy-MM-dd HH:mm:ss'))" -Level "INFO"
  Write-Ui -Message "Total duration: $([math]::Round($duration.TotalMinutes, 2)) minutes" -Level "INFO"
  ```
- **Risk if changed:** Low — message text preserved; the `[INFO]` bracket emitted by `Write-Ui` replaces the manual Gray-prefix-plus-Cyan-value split. Per-category fix patterns are enumerated below.
- **Local notes:** Four categories of raw `Write-Host`:
  1. **Blank-line / spacer calls** — bare `Write-Host ""` used as vertical spacing (lines 101, 104, 107, 110, 113, 116, 119, 122, 125, 128, 131, 133, 138, 140, 145, 148, 156, 158, 366, 515, 520, 524, 555, 714, 716, 722, 728, 736, 745, 800, 812, 814, 816, 826, 828, 830, 858, 860, 865, 867, 870, 872, 887, 898, 901). These are the same "visual separator" exception called out in F2 of `scripts-driver_integrity_scan.md` — they are not strict C1 violations but they are noisy; migrate to `Write-Ui -Spacer` (or `Show-Section`) in P4 once that helper exists.
  2. **Banner separator lines** — `Write-Host "============================================================" -ForegroundColor Yellow` (lines 132, 139) and the same in Cyan (lines 813, 827, 859, 866). These should call `Show-Section` (already used at lines 909, 927, 933, 939) or a new `Write-Ui -Separator` helper.
  3. **Inline-color label/value pairs** — `Write-Host "label" -NoNewline -ForegroundColor Gray` followed by `Write-Ui` for the value (lines 806–810, 817–818, 820–821, 823–824, 849–851). Pre-`Write-Ui`-era manual color formatting; collapse to a single `Write-Ui` call per row.
  4. **Plain message lines** — `Write-Host "      -> Error details: $errorDetails" -ForegroundColor DarkYellow` (lines 584, 600), `Write-Host "         $line" -ForegroundColor DarkRed` (line 640), `Write-Host "      -> Error: $testResult" -ForegroundColor DarkYellow` (line 696), `Write-Host "      https://www.office.com/setup" -ForegroundColor Cyan` (line 739), `Write-Host -NoNewline "  Enter your choice: " -ForegroundColor Cyan` (line 149), `Write-Host -NoNewline "Press Enter to exit..." -ForegroundColor Cyan` (line 950), `Write-Host "      -> Progress: " -NoNewline -ForegroundColor Gray` (line 507), `Write-Host "." -NoNewline -ForegroundColor Cyan` (line 542), `Write-Host " ($remaining min left) " -NoNewline -ForegroundColor Gray` (line 548). Clear C1 violations — but note the progress-dot pattern at lines 542/548 is functionally driven (single dot every 5 s on the same line as a poor-man's spinner); preserving the visual requires either keeping the `Write-Host -NoNewline` calls as an explicit `# allowed: progress indicator` exception or adding a `Write-Ui -Progress` helper in P4.
- **Local notes (cont.) — inline marker prefixes:** Many `Write-Ui` calls already double-mark with embedded `[*]` / `[!]` prefixes inside the message (lines 348, 458, 516, 662, 667, 731, 737, 738, 766, 776). Same anti-pattern as F2 of `01-modules-SouliTEK-Common.md` and F2 of `scripts-driver_integrity_scan.md` — strip these inline markers in P1 so the `[LEVEL]` bracket emitted by `Write-Ui` is the only marker. The `Show-InstallationSummary` switch at lines 842–846 builds a separate `$statusSymbol` from `[+]` / `[~]` / `[!]` / `[-]` / `[*]` for the log-replay table; that one is a deliberate iconography choice and should stay (it isn't doubling — it's the only marker in that line, see lines 849–851).
- **Local notes (cont.) — legacy API caller:** 1 call to the C2 dead API at line 869 (`Write-SouliTEKWarning "Error displaying installation summary: $($_.Exception.Message)"`). The surrounding block (lines 868–873) is the catch arm for `Show-InstallationSummary`'s own try; it can be migrated trivially to `Write-Ui -Level "WARN"`. Removing this single call clears one of C2's remaining external callers.
- **Target phase:** P1

### F2 — `-ErrorAction SilentlyContinue` triage (see C4)
- **Severity:** med (two real bug-swallowers)
- **Category:** error-handling
- **Location:** scripts/1-click_pc_install.ps1 — 10 occurrences
- **Reference:** [C4](00-cross-cutting.md#c4----erroraction-silentlycontinue-swallowing-failures)
- **Triage:**
  - Line 226: tag **A** — `Get-ComputerRestorePoint -ErrorAction SilentlyContinue` is a probe used immediately by `if (-not $restoreEnabled)` to decide whether to call `Enable-ComputerRestore`. On a fresh OS install where the schtask for restore points hasn't been initialized, this can throw legitimately; swallowing is correct because the script then takes the corrective branch. Add `# safe: probe — null result triggers the enable-then-checkpoint corrective path` comment.
  - Line 232: tag **B** — `Enable-ComputerRestore -Drive "$systemDrive\" -ErrorAction SilentlyContinue` swallows a real failure. The very next line tests `if (-not $?)` — but with `-ErrorAction SilentlyContinue`, non-terminating errors leave `$?` at `$true`, so the warning branch at line 234 never fires on the actual failure mode (the cmdlet emits non-terminating errors when System Restore is disabled by group policy, when the drive isn't NTFS, or when the protection is already on). Replace with `try { Enable-ComputerRestore -Drive "$systemDrive\" -ErrorAction Stop } catch { Write-Ui -Message "Could not enable System Restore: $($_.Exception.Message)" -Level "WARN" }`. The downstream `Checkpoint-Computer` on line 243 already has `-ErrorAction Stop` and a proper catch, so a missed enable here just degrades to the catch arm with the right error message.
  - Line 350: tag **A** — `Get-AppxPackage -Name $app -ErrorAction SilentlyContinue` is a probe; the result is immediately tested with `if ($package)` to decide whether to call `Remove-AppxPackage`. Most of the 27 `$bloatwareApps` aren't installed on a clean image, so non-terminating "not found" errors are expected. Add `# safe: probe — null result means app not installed` comment.
  - Line 353: tag **B** — `Remove-AppxPackage -Package $package.PackageFullName -ErrorAction SilentlyContinue` is the same broken `$?` pattern as line 232. The block at line 354 reads `if ($?) { ... } else { $failedCount++ }` but `SilentlyContinue` makes `$?` always `$true` for non-terminating errors, so the failed-count never increments and the summary always reports 0 failures even when removal hit ACLs / system-package errors. Replace with `try { Remove-AppxPackage -Package $package.PackageFullName -ErrorAction Stop; Write-Ui ... -Level "OK"; $removedCount++ } catch { Write-Ui "      -> Failed to remove: $($_.Exception.Message)" -Level "ERROR"; $failedCount++ }`. This is the highest-impact C4-tag-B fix in the file.
  - Line 417: tag **A** — `Get-Content $LogPath -ErrorAction SilentlyContinue` inside `Get-WinGetErrorDetails`. The function is already inside a `try { ... } catch { return "Could not parse log file..." }` and the very next line checks `if (-not (Test-Path $LogPath))`. Defensive but legitimate. Add `# safe: optional read inside parse helper` comment.
  - Line 532: tag **A** — `Get-Process | Where-Object { $_.Parent.Id -eq $process.Id } | Stop-Process -Force -ErrorAction SilentlyContinue` after a WinGet timeout. The whole block is wrapped in `try { ... } catch { # Process may have already exited }`, child-process kill is best-effort, and the parent kill already happened on line 528. Add `# safe: best-effort child cleanup after parent kill` comment. Note: `$_.Parent` is not actually a property of `System.Diagnostics.Process` returned by `Get-Process` — this filter is silently a no-op on every iteration. That's a separate correctness bug worth noting (see Out-of-scope notes) but the `SilentlyContinue` itself is appropriate.
  - Line 592: tag **A** — `Get-Content $logPath -Tail 30 -ErrorAction SilentlyContinue | Out-String` inside the WinGet exit-code 0-fallback branch. The log file may or may not exist depending on whether WinGet got far enough to flush; the result is then tested with the `-match` on line 593. Defensive but legitimate. Add `# safe: optional log inspection` comment.
  - Line 626: tag **A** — `Get-Content $LogPath -ErrorAction SilentlyContinue` inside `Show-InstallationLog`. Same pattern as line 417 — function already has its own `try`/`catch`. Add `# safe: optional read inside display helper` comment.
  - Line 664: tag **A** — `Get-Command winget.exe -ErrorAction SilentlyContinue` is the canonical "does this command exist?" probe; the result is tested with `if (-not $wingetCmd)` to decide whether to install WinGet. Identical to line 109 of `driver_integrity_scan.ps1`. Add `# safe: probe` comment.
  - Line 670: tag **A** — `Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue` is the same probe pattern for the NuGet provider, tested with `if (-not $nuget)`. Add `# safe: probe` comment.
- **Local notes:** Eight tag-A's are clean. The two tag-B's (lines 232, 353) both exhibit the same bug: `-ErrorAction SilentlyContinue` combined with a subsequent `if (-not $?)` / `if ($?)` check. **This pattern is broken because non-terminating errors do not flip `$?` when `SilentlyContinue` is set.** Both should migrate to `try`/`catch` with `-ErrorAction Stop`. The bloatware case (line 353) silently understates failure counts in the final summary — a real user-visible bug.
- **Target phase:** P2

### F3 — No `[CmdletBinding()]` on script or any function
- **Severity:** low
- **Category:** structure
- **Location:** scripts/1-click_pc_install.ps1 — 0 occurrences (predicted 0, confirmed). Script-level has a `param()` block on lines 39–45 (5 string/int parameters: `TimeZoneId`, `CultureCode`, `GeoId`, `SystemLocale`, `LanguageTag`) but no `[CmdletBinding()]` decorator. None of the 17 internal functions declares `[CmdletBinding()]` either.
- **Local notes:** Adding `[CmdletBinding()]` at script level would let callers pass `-Verbose` and `-ErrorAction` to influence the script's preference variables. More importantly, the script-level `param()` block is the only non-interactive surface in the file — under SYSTEM/RMM execution the script can be invoked with `-TimeZoneId "Pacific Standard Time" -CultureCode "en-US" ...` and skip the `Show-TaskList` + `Get-UserApproval` flow only if those gates are guarded by `[Environment]::UserInteractive` (currently they aren't). Pair with C5 in P3: `[CmdletBinding(SupportsShouldProcess, ConfirmImpact='High')]` on `Start-OneClickPCInstall`, then route the seven destructive sub-functions through `$PSCmdlet.ShouldProcess(...)`.
- **Target phase:** P3 (with C5) and P4 (cosmetic per-function adds)

### F4 — `Split-Path -Parent $MyInvocation.MyCommand.Path` instead of `$PSScriptRoot`
- **Severity:** low
- **Category:** structure
- **Location:** scripts/1-click_pc_install.ps1:51
- **Current:**
  ```powershell
  $ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
  ```
- **Recommended:**
  ```powershell
  $ScriptRoot = $PSScriptRoot
  ```
- **Risk if changed:** Low. `$PSScriptRoot` is the canonical PS 3.0+ automatic variable for "directory of the running script." `$MyInvocation.MyCommand.Path` returns `$null` when the script is dot-sourced, so the current form is slightly more fragile. Identical fix to F5 of `scripts-driver_integrity_scan.md`. C10 will eventually replace this whole block with `Import-SouliTEKCommon`.
- **Target phase:** P4 (fold into the C10 sweep)

### F5 — Missing `#Requires -RunAsAdministrator`
- **Severity:** low
- **Category:** structure (safety)
- **Location:** scripts/1-click_pc_install.ps1:37 (sole `#Requires` line is `#Requires -Version 5.1`).
- **Local notes:** The script enforces admin at runtime on line 884 via `if (-not (Test-SouliTEKAdministrator)) { ... Read-Host ...; exit 1 }`, so the safety net exists, but `#Requires -RunAsAdministrator` is the canonical way: the engine refuses to start the script under a non-elevated host, which is faster than waiting for the body to load. Add it to match `driver_integrity_scan.ps1` (which declares both). Touchpoint cost is 1 line.
- **Target phase:** P4

### F6 — `Ensure-WinGet` uses an unapproved PowerShell verb
- **Severity:** low
- **Category:** naming
- **Location:** scripts/1-click_pc_install.ps1:661 (function definition), 707 (only call site)
- **Local notes:** `Ensure` is not on the approved verb list (`Get-Verb` confirms — only 12 verbs starting with vowels and `Ensure` isn't among them). PSScriptAnalyzer will flag this once C8 wires up `Invoke-ScriptAnalyzer` in CI. The conventional rename is `Initialize-WinGet` (matches the `Initialize-` family of verbs already used elsewhere in the module like `Initialize-SouliTEKScript`) or `Install-WinGetIfMissing`. Rename here and at the single call site on line 707. Low-priority cosmetic.
- **Target phase:** P4

### F7 — Script-scope counters mutated by `Add-LogEntry` without docstring
- **Severity:** info
- **Category:** structure (note only — no change recommended)
- **Location:** scripts/1-click_pc_install.ps1:76 (`Add-LogEntry`) mutates `$Script:InstallLog`, `$Script:SuccessCount`, `$Script:ErrorCount`, `$Script:WarningCount` declared on lines 64–68.
- **Local notes:** The four `$Script:`-scoped counters and the `$Script:InstallLog` array are the only shared mutable state in the file, and they are mutated only from `Add-LogEntry`'s `switch` block. Single-threaded execution makes this safe; no lock needed. Worth a one-line comment above `Add-LogEntry` clarifying that this is the only intended mutation point. The variables are read once at the end inside `Show-InstallationSummary` (lines 818, 821, 824). Clean pattern overall, just under-documented.
- **Target phase:** —

## Out-of-scope notes
- Banner block (lines 1–35, 35 lines of `# === / Coded by / IMPORTANT DISCLAIMER`) matches C11 cross-cutting cleanup; covered there.
- The 27-entry `$bloatwareApps` array (lines 313–341) is reasonable but partially stale: `Microsoft.MixedReality.Portal` (line 323) was removed by Microsoft in Windows 11 22H2 / 23H2 builds and the Appx package no longer exists on those images; the script will hit the `if ($package)` false-branch and log "Not installed" — harmless but slightly noisy. Worth a comment when this script is touched again. Lower-impact: `Microsoft.Wallet`, `Microsoft.OneConnect`, `Microsoft.Print3D`, `Microsoft.3DBuilder`, `Microsoft.Microsoft3DViewer` are also legacy and largely absent from current OEM images. No change recommended in this audit pass — overlaps with `win11_debloat.ps1` review.
- The `$_.Parent.Id` filter on line 532 (inside the `Get-Process | Where-Object { $_.Parent.Id -eq $process.Id }` child-process kill) is functionally a no-op: `System.Diagnostics.Process` objects returned by `Get-Process` do not expose a `Parent` property, so the filter always returns nothing and the `Stop-Process` never fires. Correct child-process traversal needs `Get-CimInstance -ClassName Win32_Process -Filter "ParentProcessId=$($process.Id)"` (returns `Win32_Process` instances with `.ProcessId`) followed by `Stop-Process -Id ...`. This is a latent bug that becomes visible only on a WinGet install that spawns a long-running child and then times out — the timeout branch will kill the parent but leak the children. Defer to P2 (alongside the C4 tag-B fixes); not raising as F8 because the bug only matters when the WinGet timeout fires, which is rare.
- The WinGet exit-code mapping at lines 575–604 (added in `b79d132`) is good defensive work: `-1978335189` / `0x8A15000B` "no applicable update" and `-1978335212` / `0x8A150014` "install failed" are correctly distinguished, and the unknown-exit-code branch (lines 588–604) inspects the log for "successfully installed" / "already installed" / "install completed" before deciding final status. Microsoft documents these codes in the WinGet repo (`docs/Resources.md`); the magic numbers should ideally be hoisted to a `$Script:WinGetExitCodes` hashtable like `$Script:ErrorCodes` in `driver_integrity_scan.ps1` lines 62–95 — that would be a clean P4 refactor.
- The `Test-ApplicationInstalled` helper (line 386) shells out to `winget.exe list --id $WinGetId --exact ...` and checks `$LASTEXITCODE -eq 0 -and $result -match $WinGetId`. The exit-code check is correct, but the `-match` regex check against the raw stdout is sensitive to WinGet's column-formatted output and locale (the column header row contains `Id` which can spuriously match). For the three IDs currently used (`Google.Chrome`, `AnyDeskSoftwareGmbH.AnyDesk`, `Microsoft.Office`) this is fine because they are distinctive enough; for a generic helper a `--source winget --output json` parse would be sturdier. No change in this pass.
- The `Show-TaskList` function (lines 97–141) hard-codes "Israel/Hebrew" specifics into the user-facing summary (line 106: "Set regional format, location, and language to Israel/Hebrew") even though the upstream `param()` block accepts arbitrary `TimeZoneId`/`CultureCode`/`GeoId`/`SystemLocale`/`LanguageTag`. If a future user passes `-CultureCode "en-US"`, the task-list summary will lie. Low impact today (this is currently a SouliTEK-IL-internal tool), worth a comment if generalized.
- The script's overall structure (top-level `Start-OneClickPCInstall` function called once at the bottom on line 954) follows the `Initialize-SouliTEKScript` pattern even though it doesn't actually call that module helper — a P4 standardisation candidate alongside C10.
- The `powercfg /duplicatescheme 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c` call on line 278 uses the documented "High performance" scheme GUID, which is stable across Windows versions. Good.
- The `Read-Host` calls on lines 151, 888, 951 are blocking; under SYSTEM-context RMM execution (flagged in user's CLAUDE.md as a deployment scenario), they will hang the worker. There is no `[Environment]::UserInteractive` gate. Defer to P3 alongside C5's `-WhatIf`/`-Confirm` retrofit — adding `-NonInteractive` / `-Silent` switches to bypass the prompts is a natural pair with `SupportsShouldProcess`.
- The five-parameter `param()` block (lines 39–45) defaults to Israel/Hebrew settings. This means a SYSTEM-context launcher invocation without overrides will silently localize the box to Hebrew — by design for SouliTEK's customer base, but worth a comment for any future operator who reads the file cold.
