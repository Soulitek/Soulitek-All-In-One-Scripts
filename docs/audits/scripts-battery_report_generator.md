# Audit — scripts/battery_report_generator.ps1

## Inventory
| Item | Value |
|---|---|
| Path           | scripts/battery_report_generator.ps1 |
| LOC            | 563 |
| Functions      | 15 |
| `#Requires`    | none |
| Admin-required | partial — only `New-EnergyReport` (line 291) gates with `Assert-SouliTEKAdministrator` because `powercfg /energy` requires elevation; all other reports (`/batteryreport`, `/sleepstudy`) run as the current user |
| Last touched   | 8675720 — 2026-04-17 |
| Modernization grade | B |

## Summary

A menu-driven wrapper around `powercfg /batteryreport`, `powercfg /sleepstudy`, and `powercfg /energy` that emits HTML reports to the user's Desktop and offers a "view recent reports" browser. The script is in noticeably better shape than its sibling tools: it already uses `Get-CimInstance` (line 199, no C3 exposure), the powercfg shell-out is centralised in a single helper (`Invoke-SouliTEKPowerCfg`, lines 81–109) that surfaces non-zero exit codes as exceptions and validates expected output paths, and the new `New-SouliTEKBatteryReport` helper (lines 112–148) collapses four near-duplicate "generate, save, open" code paths into one parameterised function — exactly the kind of intra-script DRY that the rest of the codebase is missing. The primary issue is C1: 100 raw `Write-Host` calls, but two-thirds of those live in static-text functions (`Show-Help` lines 454–520 and `Show-MainMenu` lines 160–172) where the migration is mechanical, and the rest fall into the "blank-line spacer" and "section heading" categories already excepted in C1. The five `-ErrorAction SilentlyContinue` occurrences are all defensible — one cleanup and four `Get-ChildItem -Filter` probes that may legitimately return zero matches; all carry triage tag **A**. Secondary concerns: one straggling `Write-SouliTEKWarning` call (line 71) that still exercises the C2 dead API; no `[CmdletBinding()]` anywhere; the file uses `Split-Path -Parent $MyInvocation.MyCommand.Path` (line 38) instead of `$PSScriptRoot`; the main loop is unconditional `do { ... } while ($choice -ne "0")` with `Read-Host` at line 174 that would hang under SYSTEM/RMM execution; the report output path is hard-coded to `$env:USERPROFILE\Desktop`. Recommended phase entry order: P1 (C1 + C2 wrapper-call), then P2 (C4 triage). This file is a reasonable candidate for "leave alone after P1/P2" — the structural debt is light.

## Findings

### F1 — Raw `Write-Host` calls (see C1)
- **Severity:** med
- **Category:** output-style
- **Location:** scripts/battery_report_generator.ps1 — 100 raw `Write-Host` occurrences (sample lines: 52, 53, 160–172, 237, 384–390, 401, 403, 416, 419–421, 428, 430, 443, 446, 454–520).
- **Reference:** [C1](00-cross-cutting.md#c1--raw-write-host-calls-not-migrated-to-write-uiwrite-status)
- **Current (representative pattern — static menu text at lines 160–172):**
  ```powershell
  Write-Host "Select an option:"
  Write-Host ""
  Write-Host "  [1] Quick Battery Report    - Basic health overview"
  Write-Host "  [2] Detailed Battery Report - Comprehensive analysis"
  ...
  ```
- **Recommended:** Migrate static-text functions wholesale to `Write-Ui -Level "INFO"` (or a `Show-Menu`/`Show-Help` helper added in P4); keep blank-line spacers as-is per the C1 exception list. Inline color formatting at line 237 (`Write-Host "Battery Health: $healthPercent%" -ForegroundColor $healthColor`) is a real C1 violation and should become `Write-Ui -Message "Battery Health: $healthPercent%" -Level "OK"` (the dynamic color is decorative — the health-tier text on lines 239–244 already conveys the verdict in words).
- **Risk if changed:** Low — message text preserved verbatim; the `[LEVEL]` bracket emitted by `Write-Ui` replaces the section-divider equals lines visually.
- **Local notes:** Three categories of raw `Write-Host`:
  1. **Blank-line / spacer / equals-divider calls** — bare `Write-Host ""`, `Write-Host "========..."`, `Write-Host "----..."` used as vertical/horizontal separators (lines 52, 161, 171–172, 384–388, 390, 403, 419, 421, 430, 446, 454–458, 460–461, 466, 471, 476, 481, 486, 491–492, 494–495, 497, 502–503, 505–506, 509, 512, 515, 518–520). Most are not C1 violations per the "visual separator helpers" exception, but they are noisy and would benefit from a `Show-Section`/`Show-Divider` helper added in P4 alongside the other scripts.
  2. **Static-text print blocks** — the entire `Show-Help` function (lines 454–520, 67 calls) and the section headings in `Show-RecentReports` (lines 385–387, 389, 401, 416, 420, 428, 443). These are real C1 violations: the body content is plain message lines that should be `Write-Ui -Message "..." -Level "INFO"`. Bulk migration is mechanical because there is no inline `-ForegroundColor` formatting on the message lines themselves — the color is set once via `Set-SouliTEKConsoleColor "Blue"` on lines 159, 383, 453 and then inherited.
  3. **Inline-color formatting** — exactly one occurrence: line 237 (`Write-Host "Battery Health: $healthPercent%" -ForegroundColor $healthColor` with `$healthColor` computed on line 236). Clean C1 violation; migrate to `Write-Ui -Level "OK"` and drop the dynamic color.
- **Local notes (cont.) — `Set-SouliTEKConsoleColor`:** Lines 51, 159, 173, 383, 453 use `Set-SouliTEKConsoleColor` to set the console foreground globally for a block of `Write-Host` calls. This pattern leaks color state across function boundaries and is incompatible with `Write-Ui` (which manages its own per-message color). When the static-text blocks migrate to `Write-Ui`, drop the `Set-SouliTEKConsoleColor` wrapper calls — they become no-ops.
- **Target phase:** P1

### F2 — `-ErrorAction SilentlyContinue` triage (see C4)
- **Severity:** med
- **Category:** error-handling
- **Location:** scripts/battery_report_generator.ps1 — 5 occurrences
- **Reference:** [C4](00-cross-cutting.md#c4----erroraction-silentlycontinue-swallowing-failures)
- **Triage:**
  - Line 259: tag **A** — `Remove-Item -LiteralPath $tempFile -Force -ErrorAction SilentlyContinue` in the `finally { }` block of `Get-BatteryHealthCheck` cleans up the XML temp file. The preceding `if (Test-Path -LiteralPath $tempFile)` guards existence; suppressing errors here protects against permission/lock edge cases on cleanup. Add `# safe: cleanup` comment in P2.
  - Line 392: tag **A** — `Get-ChildItem "$env:USERPROFILE\Desktop" -Filter "Battery*.html" -ErrorAction SilentlyContinue` in `Show-RecentReports`. Suppresses errors when the filter matches zero files (or when Desktop is inaccessible under unusual profile setups). The result is immediately piped into a `Sort-Object` and the consolidated array is tested with `if ($reports)` on line 399. Legitimate probe. Add `# safe: optional listing` comment.
  - Line 394: tag **A** — `Get-ChildItem ... -Filter "Sleep*.html" -ErrorAction SilentlyContinue` — same pattern as line 392 for sleep-study reports. Legitimate. Add `# safe: optional listing` comment.
  - Line 396: tag **A** — `Get-ChildItem ... -Filter "Energy*.html" -ErrorAction SilentlyContinue` — same pattern as 392/394 for energy reports. Legitimate. Add `# safe: optional listing` comment.
  - Line 423: tag **A** — `Get-ChildItem ... -Directory -Filter "BatteryReports*" -ErrorAction SilentlyContinue` for the "All Reports Package" folders. Result tested with `if ($folders)` on line 426. Legitimate. Add `# safe: optional listing` comment.
- **Target phase:** P2

### F3 — One straggling `Write-SouliTEKWarning` call (see C2)
- **Severity:** low
- **Category:** output-style (legacy API caller)
- **Location:** scripts/battery_report_generator.ps1:71
- **Reference:** [C2](00-cross-cutting.md#c2--dead-duplicate-output-api)
- **Current:**
  ```powershell
  Write-SouliTEKWarning "Open PowerShell as Administrator and retry."
  ```
- **Recommended:**
  ```powershell
  Write-Ui -Message "Open PowerShell as Administrator and retry." -Level "WARN"
  ```
- **Risk if changed:** Low. This is the only legacy-API caller in the file — every other surface is already on `Write-Ui`. Migrating this one call removes the file from C2's caller set entirely.
- **Target phase:** P1

### F4 — No `[CmdletBinding()]` on script or any function
- **Severity:** low
- **Category:** structure
- **Location:** scripts/battery_report_generator.ps1 — script-level (no `param()` block at all) and every one of the 15 internal functions.
- **Local notes:** The script is fully interactive (no CLI surface), so this is low-severity, but adding `[CmdletBinding()]` to `New-SouliTEKBatteryReport` (lines 112–148, which already has a rich `param()` block with `[ValidateSet]`) and `Invoke-SouliTEKPowerCfg` (lines 81–109) would let those helpers accept `-Verbose` / `-ErrorAction` from callers. Pairs naturally with F5 (`$PSScriptRoot`) and F6 (RMM safety) as a P4 standardisation pass.
- **Target phase:** P4

### F5 — `Split-Path -Parent $MyInvocation.MyCommand.Path` instead of `$PSScriptRoot`
- **Severity:** low
- **Category:** structure
- **Location:** scripts/battery_report_generator.ps1:38
- **Current:**
  ```powershell
  $ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
  ```
- **Recommended:**
  ```powershell
  $ScriptRoot = $PSScriptRoot
  ```
- **Risk if changed:** Low. `$PSScriptRoot` is the canonical PS 3.0+ automatic variable. C10 will eventually replace this whole `Import-SouliTEKCommon` block, but until then the one-line fix is free. Same pattern as F5 of `scripts-driver_integrity_scan.md`.
- **Target phase:** P4 (fold into the C10 sweep)

### F6 — Infinite menu loop with blocking `Read-Host` prompts (RMM safety)
- **Severity:** low
- **Category:** structure (UX / RMM safety)
- **Location:** scripts/battery_report_generator.ps1:542 (`do { ... } while ($choice -ne "0")`), plus `Read-Host` calls at lines 174, 404, 431.
- **Local notes:** The script is interactive-only by design — the only graceful exit is menu option `[0]`. Under SYSTEM-context RMM execution (flagged in user's CLAUDE.md as a deployment scenario), `Read-Host` will hang the worker process. There is no `[Environment]::UserInteractive` gate. Same pattern as F6 of `scripts-driver_integrity_scan.md`; defer to P4 unless an actual hang report comes in.
- **Target phase:** P4

### F7 — Hard-coded Desktop output path with no override
- **Severity:** info
- **Category:** structure
- **Location:** scripts/battery_report_generator.ps1:181, 188, 273, 305, 329, plus the `Show-RecentReports` lookups at 392, 394, 396, 406, 423, 433.
- **Local notes:** The HTML report output target is hard-coded to `$env:USERPROFILE\Desktop` in every report-generation function. This breaks under SYSTEM context (`$env:USERPROFILE` resolves to `C:\Windows\System32\config\systemprofile`, where Desktop may not exist or be writable). The `New-SouliTEKBatteryReport` helper already accepts `-ReportFile` as a parameter, so the fix is to plumb an `-OutputDirectory` argument through `New-QuickReport`/`New-DetailedReport`/`New-SleepStudyReport`/`New-EnergyReport`/`New-AllReports` and default it to `$env:USERPROFILE\Desktop` only when interactive. Low priority because the menu-driven design assumes interactive use. Note: same issue as F7 of `scripts-driver_integrity_scan.md`.
- **Target phase:** P4

### F8 — `Show-RecentReports` `+=` pattern destroys per-file sort ordering
- **Severity:** info
- **Category:** correctness (cosmetic — user-visible)
- **Location:** scripts/battery_report_generator.ps1:392–397, 400.
- **Local notes:** The function builds the `$reports` array with three separate `Get-ChildItem | Sort-Object LastWriteTime -Descending` pipelines (lines 392–397) using `+=`. Each filter's results are sorted internally, then concatenated, producing a list grouped by *file type* rather than by date. Line 400 then does `$reports | Sort-Object LastWriteTime -Descending | Select-Object -First 10`, which re-sorts the consolidated array correctly — so the user-visible output is fine, but the per-filter `Sort-Object` calls on lines 393, 395, 397 are wasted work (`+=` on a fixed-size array is also O(n²) but the result set is tiny). Drop the three inline `Sort-Object` calls and let the final sort on line 400 do the work. Pure cleanup, no behavior change.
- **Target phase:** —

### F9 — Inline marker prefix on line 411 / 438 message
- **Severity:** info
- **Category:** output-style
- **Location:** scripts/battery_report_generator.ps1:411, 438.
- **Current:**
  ```powershell
  Write-Ui -Message "File not found." -Level "ERROR"
  Write-Ui -Message "Folder not found." -Level "ERROR"
  ```
- **Local notes:** These two calls are clean and follow the F2-of-01-modules style guide (no double-marking). Mentioning them only as positive examples — the rest of the file is on `Write-Ui` correctly. No change needed.
- **Target phase:** —

## Out-of-scope notes
- Banner block (lines 1–32, 27 lines of `# === / Coded by / IMPORTANT DISCLAIMER`) matches C11 cross-cutting cleanup; covered there.
- The `Invoke-SouliTEKPowerCfg` helper (lines 81–109) is a clean abstraction: captures `$LASTEXITCODE`, joins stderr/stdout via `2>&1`, throws typed exceptions (`InvalidOperationException`, `FileNotFoundException`) with informative messages, and optionally validates that the expected output file was produced. No change needed — this is the model for how the other scripts should wrap their native-command shell-outs.
- The `New-SouliTEKBatteryReport` helper (lines 112–148) is a similarly clean DRY abstraction collapsing four near-duplicate report flows into one parameterised function with `[ValidateSet]` on `-Color` and `[Parameter(Mandatory)]` on every input. The `-Subtitle` parameter is accepted but never used in the body — could be dropped or wired into a `Show-Section` call.
- The `New-AllReports` function (lines 322–378) uses a `$reportDefinitions` hashtable array driven by `foreach` with a `Show-Step -StepNumber -TotalSteps` progress indicator — a clean data-driven pattern. The `RequiresAdmin` flag (line 336) is correctly checked before invocation (line 345) so the loop continues past the Energy Report when not elevated, instead of failing the whole batch.
- The `Get-BatteryHealthCheck` function (lines 193–264) uses `Get-CimInstance -ClassName Win32_Battery` (line 199) — no C3 exposure, no migration needed.
- Trailing newline/whitespace: the file ends at line 563 with no excessive trailing blank lines. Clean.
- The `Show-Disclaimer` (line 151) and `Show-ExitMessage` (line 526) functions are thin wrappers around `Show-SouliTEKDisclaimer` and `Show-SouliTEKExitMessage` — small but defensible adapter layer. Could be inlined in a P4 sweep.
- The `Assert-SouliTEKAdministrator` helper (lines 58–78) is local to this script but duplicates the responsibility-of-the-module `Test-SouliTEKAdministrator` (which it already calls on line 66). The wrapper exists to add the "show header + warning + wait-for-key" UX. If a similar pattern exists in other scripts, this is an extract candidate for the module in P4.
