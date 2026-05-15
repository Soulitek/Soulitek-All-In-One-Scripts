# Audit — scripts/EventLogAnalyzer.ps1

## Inventory
| Item | Value |
|---|---|
| Path           | scripts/EventLogAnalyzer.ps1 |
| LOC            | 2275 |
| Functions      | 27 |
| `#Requires`    | `#Requires -Version 5.1` (placed at line 216, *after* the `param()` block — see F8) |
| Admin-required | yes (declared via runtime `Test-SouliTEKAdministrator` gate at line 1771, not via `#Requires -RunAsAdministrator`; `Get-WinEvent` of Security log + `Register-ScheduledTask` under SYSTEM principal both require elevation) |
| Last touched   | 8675720 — 2026-04-17 |
| Modernization grade | D |

## Summary

The largest script in the repo (2275 LOC) and a feature-rich predefined-report harness for `Get-WinEvent`: it builds XPath/XML filter queries, supports JSON/CSV/HTML/CLIXML/Both/All export, computes statistics (mean, std-dev, error %), compares against a baseline JSON, and can register itself as a SYSTEM-context scheduled task. It is also the most *structurally healthy* of the 1000+ LOC scripts: zero `Get-WmiObject` calls (uses `Get-WinEvent` exclusively), zero legacy `Write-SouliTEK*` callers (C2 dead), 14 of 27 functions declare `[CmdletBinding()]` including 4 with `SupportsShouldProcess` and the script itself declares `[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]`, and only 3 `-ErrorAction SilentlyContinue` occurrences (all clearly tag-A). The dominant remaining issue is **C1 (Write-Host)**: 139 calls, the second-highest in the repo, but breaking down differently from `driver_integrity_scan.ps1` — ~100 of them are bare `Write-Host ""` blank-spacer calls and ~28 are `Write-Host "============…" -ForegroundColor Cyan` banner-rule lines that should consolidate behind a single `Show-Section` / `Write-Ui -Spacer` helper added in P4 rather than being migrated one-by-one; only ~11 raw `Write-Host` calls are true content-bearing C1 violations (the inline-color `+/-` delta renderer in `Show-ComparisonResults` lines 1183/1189/1195, plus the foreground-colored "Total Errors / Total Warnings" computed-color lines 1535-1536 and 1551 in `Show-AnalysisSummary`). The script already adopts `Write-Ui` heavily (205 occurrences) with no inline `[+]`/`[-]`/`[!]` double-marking. **C6 (size)** is the real story: the file is 2.13× the size of the second-largest script and contains 5 oversized functions (>100 LOC each) that are obvious extract candidates — see F3 for the full list with extraction targets. **C13 (perf)** applies to the per-log enumeration loop at `Invoke-MainAnalysis` line 1630–1646 (3 logs × `Get-WinEvent` with up to 10k events each); this is the cleanest candidate in the repo for the future `Invoke-SouliTEKParallel` helper because each iteration is fully independent. The only outright bug is an orphan `.SYNOPSIS` block at lines 245-249 (dead documentation for an admin-test function that no longer exists in the file). Recommended phase entry order: P1 (C1 — narrow scope, only ~11 true content violations + spacer/banner consolidation deferred), then P4 (C6 extract + C13 parallel helper, gated on the parallel runspace-pool helper landing first).

## Findings

### F1 — Mixed `Write-Host` (see C1)
- **Severity:** med
- **Category:** output-style
- **Location:** scripts/EventLogAnalyzer.ps1 — 139 raw `Write-Host` occurrences (representative sample lines: 1183, 1189, 1195, 1535, 1536, 1551, 1602, 1605, 1616-1620, 1773-1788). Zero legacy `Write-SouliTEK*` callers (C2 dead in this file). `Write-Ui` is already adopted with 205 call sites — this is one of the most Write-Ui-heavy scripts in the repo.
- **Reference:** [C1](00-cross-cutting.md#c1--raw-write-host-calls-not-migrated-to-write-uiwrite-status)
- **Current (representative pattern — inline computed-color delta at lines 1183/1189/1195 in `Show-ComparisonResults`):**
  ```powershell
  $color = if ($change.ErrorCountChange -gt 0) { 'Red' } else { 'Green' }
  $sign  = if ($change.ErrorCountChange -gt 0) { '+' } else { '' }
  Write-Host "    Errors: $sign$($change.ErrorCountChange)" -ForegroundColor $color
  ```
- **Recommended:**
  ```powershell
  $sign  = if ($change.ErrorCountChange -gt 0) { '+' } else { '' }
  $level = if ($change.ErrorCountChange -gt 0) { 'ERROR' } else { 'OK' }
  Write-Ui -Message "    Errors: $sign$($change.ErrorCountChange)" -Level $level
  ```
- **Risk if changed:** Low — text preserved verbatim; the `[ERROR]`/`[OK]` bracket from `Write-Ui` replaces the computed color. Operator can still distinguish "got worse" vs "got better" at a glance.
- **Local notes:** Three categories of raw `Write-Host`, each with a different migration strategy:
  1. **Blank-line spacer calls** — bare `Write-Host ""` used as vertical spacing. ~100 occurrences. Examples: 1123, 1127, 1129, 1137, 1139, 1169, 1175, 1203, 1207, 1428, 1432, 1436, 1439, 1446, 1450, 1453, 1474, 1477, 1520, 1547, 1565, 1602, 1605, 1616, 1620, 1624, 1702, 1705, 1717, 1720, 1724, 1726, 1745, 1753, 1772, 1776, 1778, 1783, 1786, 1788, 1798, 1802, 1807, 1811, 1815, 1859, 1861, 1880, 1886, 1888, 1905, 1911, 1913, 1930, 1936, 1938, 1950, 1956, 1958, 1970, 1976, 1978, 1995, 2001, 2003, 2024, 2027, 2029, 2049, 2052, 2054, 2075, 2078, 2080, 2100, 2108, 2111, 2116, 2127, 2130, 2132, 2135, 2138, 2141, 2144, 2147, 2150, 2153, 2156, 2159, 2162, 2167, 2169, 2204, 2207, 2212, 2220. These should remain as-is or migrate to a `Write-Ui -Spacer` / `Show-Section` helper if added in P4 — per C1 "visual separator helpers" exception, they are not true C1 violations but they are noise.
  2. **Banner rule lines** — `Write-Host "============================================================" -ForegroundColor Cyan/Green/Red` framing block headers. ~28 occurrences (lines 1124, 1126, 1138, 1170, 1172, 1206, 1429, 1431, 1447, 1449, 1471, 1473, 1529, 1531, 1548, 1550, 1564, 1617, 1619, 1773, 1775, 1787, 1799, 1801, 1812, 1814, 1830, 1832, 1851, 1853, 2105, 2107, 2127, 2129). These wrap titles in `===…===` rules. Migration is awkward one-by-one — better consolidated behind a `Show-Section -Title "EVENT LOG ANALYSIS SUMMARY"` helper added in P4 alongside the `Write-Ui -Spacer` work. Per C1 "visual separator helpers" exception, these are also not true violations but cleanup candidates.
  3. **Content-bearing inline-color calls — true C1 violations** — 11 occurrences. The full list with required migration:
     - Lines 1183, 1189, 1195 — `Show-ComparisonResults` delta renderer (Red/Green/Yellow/Magenta on Up/Down). Migration shown in the Current/Recommended block above. ([Pattern: computed-color])
     - Line 1535 — `Show-AnalysisSummary` total errors line with `-ForegroundColor $(if ($totalErrors -gt 0) { 'Red' } else { 'Green' })`. Same pattern. Migrate to `$level = if ($totalErrors -gt 0) { 'ERROR' } else { 'OK' }; Write-Ui -Message "  Total Errors: $totalErrors" -Level $level`.
     - Line 1536 — same for `$totalWarnings` (Yellow/Green). Map to `WARN`/`OK`.
     - Line 1551 — `Show-AnalysisSummary` error-% threshold line `Write-Host "  Error Percentage: $($stats.ErrorPercentage)%" -ForegroundColor $(if ($stats.ErrorPercentage -gt 10) { 'Red' } elseif ($stats.ErrorPercentage -gt 5) { 'Yellow' } else { 'Green' })`. Three-tier mapping → `ERROR`/`WARN`/`OK`.
- **Local notes (cont.) — no `[+]`/`[-]`/`[!]` inline-marker double-marking:** Verified — `Select-String -Pattern 'Write-Ui.*\[(\+|\-|!|\*)\]'` returns 0 matches. The 11 `[Processing]`/`[OK]`/`[SKIP]`/`[EXPORTED]`/`[Comparing]`/`[Exporting]`/`[SUCCESS]` text markers (lines 731, 742, 772, 798, 826, 847, 864, 1635, 1641, 1644, 1683, 1697, 1703, 1712, 1718) inside `Write-Ui` messages are *role markers* (which stage of the pipeline we're in), not severity markers, and they coexist cleanly with the `[LEVEL]` bracket that `Write-Ui` prepends. Worth keeping — they're informative breadcrumbs in the transcript output.
- **Target phase:** P1 (the 11 content-bearing violations); P4 (consolidating the ~128 spacer/banner calls behind a new `Show-Section` helper)

### F2 — `-ErrorAction SilentlyContinue` triage (see C4)
- **Severity:** med
- **Category:** error-handling
- **Location:** scripts/EventLogAnalyzer.ps1 — 3 occurrences (task plan predicted 3; matches exactly)
- **Reference:** [C4](00-cross-cutting.md#c4----erroraction-silentlycontinue-swallowing-failures)
- **Triage:**
  - Line 279: tag **A** — `Get-ChildItem -Path $script:LogFolder -File -ErrorAction SilentlyContinue` inside `Remove-OldLogs`. The function is wrapped in `try { … } catch { Write-Warning "Error during log cleanup: $_" }` (line 297-299) and the outer `if (-not (Test-Path $script:LogFolder)) { return }` already gates the directory existence. If the dir is present but `Get-ChildItem` fails (e.g. permissions race), continuing with an empty pipeline and zero deletions is the right call for a cache cleanup. Legitimate. Add `# safe: cleanup probe` comment in P2.
  - Line 1734: tag **A** — `Stop-Transcript -ErrorAction SilentlyContinue` inside `Invoke-MainAnalysis` finally-path. `Stop-Transcript` throws if no transcript is running; this idiom is the canonical "stop if started, no-op otherwise" pattern. Legitimate. Add `# safe: idempotent stop` comment.
  - Line 1757: tag **A** — identical pattern in the error path of `Invoke-MainAnalysis`. Same justification. Add `# safe: idempotent stop` comment.
- **Local notes:** This is the cleanest C4 profile in the repo so far — three occurrences, all tag-A, all in legitimate idempotent-cleanup positions. No tag-B or tag-C work required.
- **Target phase:** P2

### F3 — Script size (2275 LOC) + extract candidates (see C6)
- **Severity:** med
- **Category:** structure
- **Location:** scripts/EventLogAnalyzer.ps1 — entire file
- **Reference:** [C6](00-cross-cutting.md#c6--scripts-1000-loc-with-extractable-duplication)
- **Local notes — 7 largest functions and their extraction recommendations:**
  | Rank | Function | Start | End | LOC | Extract target |
  |---|---|---|---|---|---|
  | 1 | `Get-EventLogAnalysis`            |  362 |  675 | **314** | This is the lowest-hanging fruit but the trickiest payoff — the function is essentially three responsibilities glued together: (1) lines 408-417 entry-type-to-level-id mapping, (2) lines 423-485 FilterXml/XPath query builder including range/comma EventID parsing, (3) lines 553-650 event grouping/top-N statistical roll-up. Split into `ConvertTo-EventLevelIds`, `Build-WinEventFilterXml`, and `Get-EventGroupSummary` helpers in a future `modules/SouliTEK-EventLog.psm1` (or under MODERNIZATION HELPERS in the existing module). The FilterXml builder is the most reusable piece — any script that needs filtered `Get-WinEvent` calls would benefit. |
  | 2 | `Invoke-MainAnalysis`              | 1572 | 1823 | **252** | Already does too much: time-range setup, confirm-large-query prompt, per-log loop, statistics aggregation, JSON summary save, baseline comparison, automatic/interactive export branching, transcript stop/start. The per-log loop (lines 1630-1646) is the C13 candidate — see F4. Extract the export-branching logic (lines 1695-1728) to a small `Invoke-ExportPipeline` helper. |
  | 3 | `Export-AnalysisResults`           |  676 |  887 | **212** | Four parallel `if ($Format -in @('JSON','Both','All'))` / `if ($Format -in @('CSV',…))` / `if ($Format -in @('CLIXML',…))` / `if ($Format -in @('HTML',…))` blocks with near-identical export-individual-vs-combined branching. Extract a generic `Export-LogFormat -Format $name -Writer { param($obj,$path) … }` strategy. Each writer becomes ~20 LOC; the dispatcher becomes ~15 LOC. Net savings: ~80 LOC. |
  | 4 | `New-HtmlReport`                   |  888 | 1071 | **184** | A here-string concatenation builder. Single biggest win: pull the CSS `style` block (lines 902-928) and the per-log-section template (lines 957-1017) into the module so multiple scripts can produce SouliTEK-branded HTML reports (`ram_slot_utilization_report`, `bsod_history_scanner`, `disk_usage_analyzer` could all reuse this). A `New-SouliTEKHtmlReport -Title $t -Sections @(…)` helper would justify the lift. |
  | 5 | `Show-AnalysisSummary`             | 1463 | 1571 | **109** | A console renderer for the same totals structure that `New-HtmlReport` renders. Three of its `Write-Host` calls are the content-bearing C1 violations from F1. After F1, the function shrinks; further size cuts come from refactoring the per-log nested `if` ladder (lines 1483-1518) into a small `Format-LogCounts` helper. |
  | 6 | `Invoke-MainMenu`                  | 2178 | 2275 |  **98** | The 13-option dispatcher (plus the outer "no explicit params? show menu" branching at lines 2243-2261). Switch-case is fine as-is; the size mostly comes from the per-choice `& $PSCommandPath -Param X -Param Y -Force` recursion in the 10 `Invoke-*Report` helpers below — see "duplicated parameter manifest" note in F8 below. |
  | 7 | `Get-EventLogStatistics`           | 1224 | 1319 |  **96** | Compact and well-defined. The mean/std-dev block (lines 1244-1255) and the most-common-Event-ID/Provider block (lines 1268-1287) are independently reusable — could move to a `Get-EventGroupSummary` helper alongside the F3-rank-1 statistical block from `Get-EventLogAnalysis`. |
- **Local notes (cont.):** Total LOC across these 7 functions = 1,265 — 55.6% of the file. Reducing them by half (extracting ~600 LOC of helpers to the module) would drop the file from 2,275 LOC to ~1,675 LOC, still large but back inside the C6 "extractable" band. Module helpers to add in P4: `Build-WinEventFilterXml`, `ConvertTo-EventLevelIds`, `Get-EventGroupSummary`, `New-SouliTEKHtmlReport`, `Export-LogFormat` (strategy dispatcher).
- **Target phase:** P4

### F4 — Sequential per-log `Get-WinEvent` loop (see C13)
- **Severity:** low (perf)
- **Category:** perf
- **Location:** scripts/EventLogAnalyzer.ps1:1630-1646 (`Invoke-MainAnalysis` inner loop)
- **Reference:** [C13](00-cross-cutting.md#c13--sequential-foreach-over-large-datasets-where-parallelism-would-help)
- **Current:**
  ```powershell
  foreach ($logName in $LogNames) {
      $logCount++
      …
      $analysis = Get-EventLogAnalysis -LogName $logName -StartTime $StartTime -EndTime $EndTime …
      if ($analysis) { $logResults += $analysis }
  }
  ```
- **Local notes:** Default `$LogNames = @('Application', 'System', 'Security')` and default `$MaxEvents = 10000`. Each `Get-WinEvent` call is independent — no shared mutable state inside `Get-EventLogAnalysis` apart from `Write-Verbose`/`Write-Progress`. On a busy machine, the Security log alone can be the dominant cost (it's the biggest channel by far and event-log parsing in PS 5.1 is single-threaded), so parallelising the three default channels can roughly halve wall-clock time for a baseline 24h sweep. The custom-report flows (`Invoke-CrashEventsReport` at line 1865, `Invoke-MemoryIssuesReport` at 1892, etc.) recurse via `& $PSCommandPath` which routes back through this loop — so a single fix benefits all 10 predefined reports. **Do not refactor until C13's `Invoke-SouliTEKParallel` runspace-pool helper lands in the module** (P4 dependency per the cross-cutting note). Expected speedup: 1.5×–2.5× depending on Security-log size. Add a `-MaxConcurrency` cap (default 3, matching the default log count) and a cancellation token.
- **Target phase:** P4 (gated on `Invoke-SouliTEKParallel` helper)

### F5 — Orphan `.SYNOPSIS` block for a function that doesn't exist
- **Severity:** low
- **Category:** docs (dead code)
- **Location:** scripts/EventLogAnalyzer.ps1:245-249
- **Current:**
  ```powershell
  <#
  .SYNOPSIS
      Tests if the current PowerShell session has Administrator privileges.
  #>
  ```
- **Recommended:** Delete lines 245-249. The function this comment describes is no longer present in the file; admin-check is delegated to `Test-SouliTEKAdministrator` (module call at line 1771). The dangling comment is confusing.
- **Risk if changed:** None — pure deletion of detached documentation.
- **Target phase:** P4

### F6 — `Split-Path -Parent $MyInvocation.MyCommand.Path` instead of `$PSScriptRoot`
- **Severity:** low
- **Category:** structure
- **Location:** scripts/EventLogAnalyzer.ps1:222
- **Current:**
  ```powershell
  $ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
  ```
- **Recommended:**
  ```powershell
  $ScriptRoot = $PSScriptRoot
  ```
- **Risk if changed:** Low. Same rationale as F5 of `scripts-driver_integrity_scan.md` — `$PSScriptRoot` is the canonical PS 3.0+ form and survives dot-sourcing where `$MyInvocation.MyCommand.Path` returns `$null`. Folds into the C10 sweep eventually.
- **Target phase:** P4 (with C10)

### F7 — Infinite menu loop with `Read-Host` and `ReadKey` blocks under SYSTEM context
- **Severity:** low
- **Category:** structure (UX / RMM safety)
- **Location:** scripts/EventLogAnalyzer.ps1:2182 (`do { … } while ($true)`), plus interactive prompts at lines 1141 (`Read-Host "Enter your choice (0-6)"`), 1606 (`Read-Host "Continue? (Y/N)"`), 1854 (`Read-Host "Enter your choice (0-13)"`), 2118, 2171, 2215, 2222 (each `$Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')`).
- **Local notes:** Same RMM-deadlock concern as F6 of `scripts-driver_integrity_scan.md`. The script *partially* handles this — `$RegisterScheduledTask` flag (line 2232) and `$hasExplicitParams` check (lines 2243-2256) both bypass the menu, and the scheduled-task path it registers correctly uses `-AutoRun -ExportFormat All -Force` to skip the interactive export prompt at line 1606. So the SYSTEM-context register/run path is already safe by design. The risk is only when an operator (or RMM tooling) launches the script without parameters intending to drive it interactively but in a non-interactive host — the menu will deadlock on the first `Read-Host`. A `if ([Environment]::UserInteractive -and -not [Console]::IsInputRedirected) { Invoke-MainMenu } else { Invoke-MainAnalysis }` gate at line 2259 would close that gap. Defer to P4 unless a real hang report comes in.
- **Target phase:** P4

### F8 — Predefined-report functions duplicate the parameter manifest 10 times
- **Severity:** low
- **Category:** structure (DRY)
- **Location:** scripts/EventLogAnalyzer.ps1:1858-2101 — `Invoke-CrashEventsReport`, `Invoke-MemoryIssuesReport`, `Invoke-SecurityAuditReport`, `Invoke-ApplicationErrorsReport`, `Invoke-SystemWarningsReport`, `Invoke-LoginEventsReport`, `Invoke-DiskIssuesReport`, `Invoke-NetworkProblemsReport`, `Invoke-DriverFailuresReport`, `Invoke-WindowsUpdateIssuesReport`.
- **Local notes:** Each of the 10 functions is ~20-27 LOC of the same shape: set local `$StartTime`/`$EndTime`/`$LogNames`/EventIDs filter array, print a "Searching for:" preamble, then `& $PSCommandPath -LogNames … -EventIDs … -ExportFormat 'All' -Force`. A data-driven refactor would collapse these to ~10 LOC each (or to a single `Invoke-PredefinedReport -ReportId 'crash'` dispatcher fed by a `$Script:PredefinedReports` hashtable). Net savings: ~150 LOC and it removes the recursive `& $PSCommandPath` self-invocation pattern (which respawns a new PowerShell process per click — small but real overhead, and it breaks `$PSCommandPath` resolution if the script is ever invoked via `Import-Module`). Pair with F3 rank-2 cleanup.
- **Target phase:** P4

### F9 — `#Requires` placed after `param()` block (latent silent failure)
- **Severity:** low
- **Category:** structure
- **Location:** scripts/EventLogAnalyzer.ps1:216
- **Current:** `#Requires -Version 5.1` is declared on line 216, after the comment-based help block (lines 1-118) and after the `[CmdletBinding(…)]` and `param(…)` block (lines 120-214).
- **Local notes:** PowerShell's `#Requires` parser does accept the directive anywhere in the file before execution begins, *but* the convention (and what every PSScriptAnalyzer rule recommends) is to put `#Requires` lines as the first non-comment lines of a script, before any code or `param()`. Today this works; if anyone refactors the comment block in a way that confuses the parser, the requires check could silently skip. Move to before line 1 (or immediately after the `<# .SYNOPSIS … #>` help block, before `[CmdletBinding(…)]`). Also worth adding `#Requires -RunAsAdministrator` to replace the runtime `Test-SouliTEKAdministrator` gate — PowerShell will refuse to launch the script in a non-elevated session, which is a cleaner failure than the current "print 18 lines of help text then exit 1" path at lines 1771-1791.
- **Target phase:** P4

### F10 — `Show-AnalysisSummary` has no `.SYNOPSIS` body, only a stub heading
- **Severity:** info
- **Category:** docs
- **Location:** scripts/EventLogAnalyzer.ps1:1459-1462 (heading on line 1460 reads only "Displays a summary of analysis results to the console." with no `.PARAMETER` or `.DESCRIPTION`); same shape on `Show-ComparisonResults` (1159-1161), `Show-ExportMenu` (1108-1117 — has DESCRIPTION but no PARAMETER for any of its … wait, it has no params; OK), `Show-CustomAnalysisMenu` (no help), `Show-HelpMenu` (no help), `Show-ReportMenu` (no help), `Invoke-MainMenu` (no help), and all 10 `Invoke-*Report` functions (no help). The `.SYNOPSIS` story is healthy on the *data*-producing functions (`Get-EventLogAnalysis`, `Get-EventLogStatistics`, `Export-AnalysisResults`, `Export-EventLogClixml`, `Compare-AnalysisResults`, `Remove-OldLogs`, `Initialize-Transcript`, `Register-EventLogScheduledTask`, `New-HtmlReport`) but absent on the display/menu layer.
- **Local notes:** Low priority — these functions are private to the script and never called externally. If the data-producing helpers move to a module per F3, fill out their `.SYNOPSIS`/`.PARAMETER`/`.OUTPUTS` blocks then; the display layer can stay undocumented.
- **Target phase:** —

### F11 — Trailing blank lines at EOF
- **Severity:** info
- **Category:** docs
- **Location:** scripts/EventLogAnalyzer.ps1:2272-2275 (4 trailing blank lines after the final `}` on line 2271)
- **Local notes:** Cosmetic. Trim in any pass that touches the file.
- **Target phase:** —

## Out-of-scope notes
- The comment-based help block (lines 1-118) is unusually thorough — 25 parameter descriptions plus 6 worked examples. This is the kind of help-block coverage that should be the template for the rest of the repo, not pruned to a 3-line C11 standard header. The standard banner-collapse recommendation in C11 should explicitly *preserve* `<# .SYNOPSIS … .DESCRIPTION … .PARAMETER … .EXAMPLE … #>` blocks like this one — they're useful documentation, not redundant marketing copy. Worth a clarifying note in C11's text the next time it's edited.
- `[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]` on the script entry point (line 120) is the **right** declaration for this workload — the script writes JSON/CSV/HTML/CLIXML files to disk and stops a scheduled task, both of which are reversible side effects, hence `'Low'`. The 11 `$PSCmdlet.ShouldProcess(…)` call sites (lines 720, 738, 755, 779, 805, 859, 1425, 1668, plus the 3 `SupportsShouldProcess = $true` function declarations on lines 677, 1384, 1573) correctly gate every file-write and the scheduled-task registration. This is a model implementation of C5 for low-impact, no other script in the repo gets it as right. **Do not touch in P3.**
- `Get-EventLogStatistics` at line 1224 computes a sample standard deviation (`/ ($eventCounts.Count - 1)` on line 1253) rather than a population standard deviation — correct for "sample of all logs queried this run" but the docstring (`.SYNOPSIS` line 1211) doesn't say which. Not worth a finding; just worth a one-word edit ("sample") in any pass that touches the file.
- The XPath/XML filter builder at lines 473-481 of `Get-EventLogAnalysis` correctly URL-encodes the `<` / `>` comparators as `&lt;` / `&gt;` in the SystemTime predicate. This matters: Get-WinEvent's `-FilterXml` parser is strict about XML-escape. No change needed.
- The `Register-EventLogScheduledTask` function (lines 1383-1457) correctly uses `New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest` and passes `-AutoRun -Force` through the registered task's command line so the scheduled run is fully non-interactive. The `Read-Host "Continue? (Y/N)"` confirm-large-query prompt at line 1606 is guarded by `if ($estimatedLoad -gt 30000 -and -not $Force)` — and the scheduled-task path always passes `-Force`. So the SYSTEM-context registered-task flow is safe.
- The `$RunExamples` flow at lines 1797-1818 spawns two recursive `& $PSCommandPath` invocations (lines 1805 and 1809). This is fine for a demo-mode flag but it does inherit the F8 caveat that `& $PSCommandPath` is sensitive to how the script was launched.
- Zero `Get-WmiObject` calls (C3 N/A). Zero `Write-SouliTEKResult`/`Info`/`Success`/`Warning`/`Error` calls (C2 dead in this file). One of the cleanest scripts in the repo on the legacy-API axis — the audit should reflect that the **D** grade is driven entirely by *size* (C6) and the residual *spacer-heavy* C1 footprint, not by legacy-API debt. If C13's parallel helper lands in P4 alongside the C6 extraction work, this script becomes a **B-grade** candidate.
