# Audit — scripts/startup_boot_analyzer.ps1

## Inventory
| Item | Value |
|---|---|
| Path           | scripts/startup_boot_analyzer.ps1 |
| LOC            | 1762 |
| Functions      | 18 |
| `#Requires`    | `#Requires -RunAsAdministrator` and `#Requires -Version 5.1` |
| Admin-required | yes (declared by `#Requires -RunAsAdministrator`; reads `Microsoft-Windows-Diagnostics-Performance/Operational` event log and enumerates all `Get-ScheduledTask`/`Get-Service` data, both of which require elevation to read the full SYSTEM-scope rows) |
| Last touched   | 8675720 — 2026-04-17 |
| Modernization grade | C |

## Summary

A read-only menu-driven startup-program triage tool: scans the two Windows startup folders, enumerates `Get-ScheduledTask` for logon/boot triggers, lists `Get-Service` rows with `StartType -match Automatic`, rates each item against a 35-entry `$Global:KnownPrograms` hashtable, parses `Microsoft-Windows-Diagnostics-Performance/Operational` event 100 for the last 10 boot durations, persists a 30-boot rolling history to `%APPDATA%\SouliTEK\BootTimeHistory.json`, and renders results either as a 4-section console dashboard or as a 452-LOC self-contained HTML report with inline CSS. There is **no `Get-WmiObject`** (C3 N/A — already migrated to `Get-CimInstance` on lines 227, 578, 933) and **zero legacy `Write-SouliTEK*` callers** (C2 dead in this file). The dominant remaining issue is **C1 (Write-Host)**: 147 calls, breaking down nearly identically to `EventLogAnalyzer.ps1`'s profile — 62 bare `Write-Host ""` blank-spacer calls, 23 `Write-Host "============…" -ForegroundColor Cyan` banner-rule lines, and the rest split between two patterns: (i) a "label-prefix + Write-Ui value" pattern repeated **29 times** (`Write-Host "  Average: " -NoNewline; Write-Ui -Message "$value seconds" -Level "STEP"` — see lines 579, 585, 592, 622-635, 659-685, 1537-1562) and (ii) a small set of true content-bearing inline-color calls (lines 589, 717-718, 738, 741, 756-757, 777, 780, 803-804, 850, 872-875, 1399, 1403, 1407, 1489, 1514-1518, 1540, 1544, 1549, 1587). The `Write-Ui` API is already adopted with 129 call sites and **no `[*]`/`[+]`/`[-]`/`[!]` inline-marker double-marking** (the F2 anti-pattern from `01-modules-SouliTEK-Common.md` is absent here — verified by grep). **C6 (size)** is the second-largest in the repo at 1762 LOC and 1 function dominates: `Export-ToHTML` is **452 LOC** (lines 906-1357), 25.6% of the entire file — the single biggest extract candidate in the repo by absolute LOC count, and it pairs naturally with `EventLogAnalyzer.ps1`'s F3-rank-4 `New-HtmlReport` (184 LOC) to motivate a shared `New-SouliTEKHtmlReport` module helper. **C4** is clean — 6 occurrences, all tag-A (probes and `-File` enumeration filters). The event-log probe-then-query idiom on lines 270-277 is **shared verbatim** with `scripts/wifi_monitor.ps1:194-204` and `scripts/usb_device_log.ps1:270-282` (3-script duplication — see F4); it is **not** shared with `scripts/EventLogAnalyzer.ps1`, which uses a FilterXml-builder approach (lines 473-498) and has no `Get-WinEvent -ListLog` probe. Three `$Global:*` script-scope variables (lines 66, 105, 106) are used as mutable cross-function state, which is the F6 finding. Recommended phase entry order: P1 (C1 — narrow scope, ~35 true content violations + spacer/banner consolidation deferred), then P4 (C6 extract via shared `New-SouliTEKHtmlReport` helper alongside `EventLogAnalyzer.ps1` F3).

## Findings

### F1 — Raw `Write-Host` (see C1)
- **Severity:** med
- **Category:** output-style
- **Location:** scripts/startup_boot_analyzer.ps1 — 147 raw `Write-Host` occurrences (matches task plan prediction exactly). Zero legacy `Write-SouliTEK*` callers (C2 dead in this file). `Write-Ui` is already adopted with 129 call sites.
- **Reference:** [C1](00-cross-cutting.md#c1--raw-write-host-calls-not-migrated-to-write-uiwrite-status)
- **Current (representative pattern — "label-prefix + Write-Ui value" pair at lines 622-623 in `Show-PerformanceSummary`):**
  ```powershell
  Write-Host "  Average: " -NoNewline
  Write-Ui -Message "$avgDuration seconds" -Level "STEP"
  ```
- **Recommended:**
  ```powershell
  Write-Ui -Message "  Average: $avgDuration seconds" -Level "STEP"
  ```
- **Risk if changed:** Low — text preserved verbatim; the line collapses from two emit calls (one without `[STEP]` bracket, one with) into a single `[STEP]`-prefixed line. Operator transcripts gain consistency.
- **Local notes:** Four categories of raw `Write-Host`, each with a different migration strategy:
  1. **Blank-line spacer calls** — bare `Write-Host ""` used as vertical spacing. **62 occurrences** (e.g. lines 571, 575, 605, 610, 649, 682, 697, 721, 747, 760, 786, 807, 812, 829, 845, 849, 853, 857, 861, 877, 883, 887, 894, 896, 1369, 1374, 1380, 1390, 1394, 1397, 1411, 1432, 1446, 1454, 1465, 1469, 1475, 1478, 1522, 1528, 1553, 1586, 1593, 1608, 1612, 1615, 1636, 1640, 1657, 1668, 1674, 1676, 1679, 1683, 1711, 1713, 1727, 1732, 1748, 1751, 1756). Per C1 "visual separator helpers" exception, these are not true violations but cleanup candidates — migrate to a `Show-Section -Spacer` helper if one lands in P4.
  2. **Banner rule lines** — `Write-Host "===…===" -ForegroundColor Cyan/Green/Yellow/DarkGray` framing block headers. **23 occurrences** (lines 572, 574, 716, 720, 755, 759, 800, 806, 846, 848, 858, 860, 895, 1370, 1373, 1391, 1393, 1466, 1468, 1609, 1611, 1637, 1639). Migration is awkward one-by-one — consolidate behind a `Show-Section -Title "BOOT PERFORMANCE SUMMARY"` helper added in P4. Per C1 "visual separator helpers" exception, also not true violations.
  3. **Label-prefix + Write-Ui-value pairs — true C1 violations (dominant pattern)** — **29 occurrences**. Full list of `Write-Host "Label: " -NoNewline` calls immediately followed by `Write-Ui -Message $value`: lines 579, 585, 592, 603, 622, 624, 626, 635, 659, 663, 668, 673, 678, 685, 743, 745, 782, 784, 827, 873, 1381, 1537, 1539, 1543, 1547, 1562, 1646, 1684, 1646 (Read-Host prompt). Migration shown in the Current/Recommended block above — collapse to a single `Write-Ui -Message "$label$value" -Level "$level"` per pair. Net reduction: ~58 LOC.
  4. **Content-bearing inline-color calls — true C1 violations** — ~25 occurrences. Notable patterns:
     - Line 589 — `Write-Host "$duration seconds" -ForegroundColor $color` in `Show-PerformanceSummary` where `$color = if ($duration -lt 30) { "Green" } elseif ($duration -lt 60) { "Yellow" } else { "Red" }`. Migrate to `$level = if ($duration -lt 30) { 'OK' } elseif ($duration -lt 60) { 'WARN' } else { 'ERROR' }; Write-Ui -Message "Boot Duration: $duration seconds" -Level $level` and merge with the line-585 label-prefix.
     - Lines 717-718, 756-757, 801-804 — banner-fragment `-NoNewline -ForegroundColor` triples that embed a count inside the banner title (e.g. `Write-Host "STARTUP FOLDER ITEMS (" -NoNewline -ForegroundColor Cyan; Write-Host $folderItems.Count -NoNewline -ForegroundColor White; Write-Ui -Message " found)" -Level "INFO"`). Migrate to `Show-Section -Title "STARTUP FOLDER ITEMS ($($folderItems.Count) found)"` once the helper exists in P4.
     - Lines 738, 741, 777, 780, 822, 825, 872 — `Write-Host "[$itemNumber] " -NoNewline -ForegroundColor White` then `Write-Host "$($item.Impact)" -NoNewline -ForegroundColor $impactColor` enumerator-with-colored-impact pattern. Migrate to `Write-Ui -Message "[$itemNumber] $($item.Name) — Impact: $($item.Impact)" -Level $impactLevel` where `$impactLevel = switch ($item.Impact) { 'High' { 'ERROR' } 'Medium' { 'WARN' } 'Low' { 'OK' } default { 'INFO' } }`.
     - Line 850 — `Write-Host "(OK) " -NoNewline -ForegroundColor Green` then `Write-Ui -Message ... -Level "STEP"`. Simplifies to `Write-Ui -Message "(OK) ..." -Level "OK"` — and per C1 conventions strip the inline `(OK)` since the `[OK]` bracket from Write-Ui already conveys this.
     - Lines 1399, 1403, 1407 — `Write-Host "  [*] Startup folders..." -NoNewline` then `Write-Ui -Message " Found $count" -Level "OK"`. The `[*]` is a STEP marker; collapse to `Write-Ui -Message "Startup folders: $count found" -Level "OK"`.
     - Lines 1489 — `Write-Host "-------------------------+----------+------------" -ForegroundColor DarkGray` table separator. Per C1 visual-separator exception, can stay or migrate to `Show-Section -Rule`.
     - Lines 1514-1518, 1540, 1544, 1549, 1587 — colored-by-threshold renderers inside `Show-BootTimeHistory` (same pattern as F1 lines 1183/1189/1195 of `EventLogAnalyzer.ps1`). Migrate per the threshold→level mapping above.
- **Local notes (cont.) — no inline-marker double-marking:** Verified — `Select-String -Pattern 'Write-Ui.*\[(\+|-|!|\*)\]'` returns 0 matches in this file. The 6 `(OK)` / 1 `(!)` / 1 `(X)` parenthetical text markers (lines 1438, 1442, 1659, 1660, 1661, 1665, 1666, 1712) inside `Write-Ui` messages are *legacy ASCII status badges* that should be stripped in the P1 sweep — the `[OK]`/`[WARN]`/`[ERROR]` bracket from `Write-Ui` is the canonical marker.
- **Target phase:** P1 (the ~35 content-bearing violations: 29 label-prefix pairs + ~6 inline-color and badge calls); P4 (consolidating the ~85 spacer/banner calls behind a new `Show-Section` helper)

### F2 — `-ErrorAction SilentlyContinue` triage (see C4)
- **Severity:** med
- **Category:** error-handling
- **Location:** scripts/startup_boot_analyzer.ps1 — 6 occurrences (matches task plan prediction exactly)
- **Reference:** [C4](00-cross-cutting.md#c4----erroraction-silentlycontinue-swallowing-failures)
- **Triage:**
  - Line 127: tag **A** — `Get-ChildItem -Path $folder.Path -File -ErrorAction SilentlyContinue` inside `Get-StartupFolderItems`. The outer `if (Test-Path $folder.Path)` (line 126) already gates the directory existence; if `Get-ChildItem` fails after the `Test-Path` succeeded (e.g. permissions race on the All-Users startup folder), returning an empty `$files` and continuing to the next scope is the right call. Add `# safe: probe` comment in P2.
  - Line 174: tag **A** — `Get-ScheduledTask -ErrorAction SilentlyContinue` inside `Get-TaskSchedulerStartupItems`. The cmdlet can fail with `0x80041313` ("The task does not exist") for transient scheduled-task races; the outer `try { … } catch { Write-Warning "Failed to query Task Scheduler: $_" }` (lines 173/204-206) handles real failures, so the `SilentlyContinue` here is the inner "filter out missing tasks during enumeration" use. Legitimate. Add `# safe: enumeration filter` comment.
  - Line 221: tag **A** — `Get-Service -ErrorAction SilentlyContinue` inside `Get-AutoStartServices`. The outer `try { … } catch { Write-Warning "Failed to query Windows Services: $_" }` (lines 220/252-254) catches real failures; `SilentlyContinue` here lets the `Where-Object { $_.StartType -match "Automatic" }` filter quietly drop services that vanished between enumeration and filter (very rare but legal). Add `# safe: enumeration filter` comment.
  - Line 227: tag **A** — `Get-CimInstance Win32_Service -Filter "Name='$($service.Name)'" -ErrorAction SilentlyContinue` inside the per-service inner loop. If the service vanished between the outer `Get-Service` call and this lookup, returning `$null` and skipping that service is correct. Add `# safe: per-row lookup` comment. **Note:** the `-Filter` argument embeds an interpolated service name without escaping — see F8 for the injection concern.
  - Line 270: tag **A** — `Get-WinEvent -ListLog "Microsoft-Windows-Diagnostics-Performance/Operational" -ErrorAction SilentlyContinue` inside `Get-BootPerformanceFromEventLog`. This is the canonical "does this event log exist?" probe; the result is immediately tested with `if (-not $logExists -or -not $logExists.IsEnabled)` and the function returns `$null` on miss. Legitimate. Add `# safe: probe` comment. **Cross-script note:** identical idiom in `scripts/wifi_monitor.ps1:194` and `scripts/usb_device_log.ps1:270` — see F4.
  - Line 277: tag **A** — `Get-WinEvent -LogName "Microsoft-Windows-Diagnostics-Performance/Operational" -MaxEvents 100 -ErrorAction SilentlyContinue` inside the same function. After the line-270 probe confirmed the log exists and is enabled, this can still fail if the log was disabled between the two calls or if the user lost permission — silently dropping to an empty pipeline and returning `$null` from the outer `try { … } catch { Write-Verbose "Could not read boot performance events: $_" }` (lines 268/304-306) is the right call. Legitimate. Add `# safe: enumeration filter` comment.
- **Local notes:** All 6 occurrences are tag-A — a clean C4 profile, mirroring `EventLogAnalyzer.ps1`'s F2 (all tag-A). No tag-B or tag-C work required.
- **Target phase:** P2

### F3 — Script size (1762 LOC) + extract candidates (see C6)
- **Severity:** med
- **Category:** structure
- **Location:** scripts/startup_boot_analyzer.ps1 — entire file
- **Reference:** [C6](00-cross-cutting.md#c6--scripts-1000-loc-with-extractable-duplication)
- **Local notes — 7 largest functions and their extraction recommendations:**
  | Rank | Function | Start | End | LOC | Extract target |
  |---|---|---|---|---|---|
  | 1 | `Export-ToHTML`                    |  906 | 1357 | **452** | **The single largest function in the audited corpus so far** — 25.6% of the entire file. A here-string concatenation builder with five concatenation segments (header CSS, summary card, folder-items table, task-items table, recommendations, footer). Single biggest win in the entire C6 sweep: extract the inline CSS `<style>` block (lines 944-1177, ~234 LOC) into a module-level constant `$Script:SouliTEKHtmlStyle` and the per-section template helpers (header/table/footer) into a `New-SouliTEKHtmlReport -Title -Sections @(…)` builder. Pair with `EventLogAnalyzer.ps1` F3-rank-4 `New-HtmlReport` (184 LOC) — both render SouliTEK-branded HTML reports with table + recommendation cards, both use the same `linear-gradient(135deg, #667eea 0%, #764ba2 100%)` purple header palette, both use `Segoe UI` font stack and `1200px` max-width container. After extraction this function shrinks to ~80 LOC of section-assembly logic. Net repo savings: ~600 LOC across the two scripts. |
  | 2 | `Show-PerformanceSummary`           |  560 |  698 | **139** | Console renderer for the boot-time-and-startup dashboard. Three of the F1 content-bearing C1 violations live here (lines 589, 622-635, 659-685). After F1 the function shrinks by ~20 LOC. Further cuts come from extracting the historical-trend block (lines 612-647) — it duplicates math from `Show-BootTimeHistory` (lines 1531-1591). Both should call a shared `Get-BootHistoryStatistics` helper that returns `{ Average, Min, Max, Current, Trend, TrendDirection }`. |
  | 3 | `Show-BootTimeHistory`              | 1459 | 1596 | **138** | Console renderer for the 30-boot rolling-history view. Same duplicated-statistics problem as rank-2: lines 1531-1591 compute mean/min/max/last-7-avg/sudden-increase-detection that overlap with `Show-PerformanceSummary` lines 612-647. After extracting `Get-BootHistoryStatistics` (a ~30 LOC pure function), this drops to ~80 LOC. |
  | 4 | `Show-StartupItemsByCategory`       |  700 |  835 | **136** | Three nearly identical `if ($folderItems/$taskItems/$serviceItems.Count -gt 0) { banner + foreach } ` blocks (lines 715-750, 754-790, 800-833). Each block does: print banner with count, foreach item, print `[N] Name — Impact: Level — Category — Scope` with colored impact badge. Extract a `Format-StartupItemBlock -Title $name -Items $items -StartIndex $itemNumber` helper. Reduces this function to ~30 LOC. |
  | 5 | `Get-OptimizationRecommendations`   |  437 |  554 | **118** | Four parallel "category filter then build recommendation object" blocks (high-impact / updaters / cloud-storage / gaming-launchers). The four blocks share the same shape: `$items = $userItems | Where-Object { … }; if ($items.Count -gt $threshold) { $recommendations += [PSCustomObject]@{ Priority = …; Category = …; Items = $items.Name; Guidance = …; HowToDisable = @(…) } }`. Could become a data-driven dispatcher with a `$Script:RecommendationRules` array of `{ Name, Filter, Priority, MinCount, Guidance, HowToDisable }`. Net reduction: ~50 LOC. |
  | 6 | `Invoke-ExportReport`               | 1630 | 1717 |  **88** | Menu-option handler for HTML export. The interactive `[O]pen / [C]opy / [Enter]` prompt at lines 1680-1709 is a clean candidate for a generic `Invoke-PostReportAction -ReportPath $path` module helper that could be reused by every script that produces a file-on-disk report (count: many — `driver_integrity_scan`, `disk_usage_analyzer`, `ram_slot_utilization_report`, `EventLogAnalyzer`, etc.). |
  | 7 | `Invoke-FullAnalysis`               | 1384 | 1457 |  **74** | Orchestrator: scan → enrich → boot-perf → display. Compact and well-defined. The three `Write-Host "  [*] X..." -NoNewline; $items = Get-X; Write-Ui " Found $count" -Level OK` triples (lines 1399-1409) are the F1 lines 1399/1403/1407 content-bearing violations — after F1 the function loses ~5 LOC and reads more cleanly. No structural extract needed. |
- **Local notes (cont.):** Total LOC across these 7 functions = 1,045 — 59.3% of the file. Reducing them by ~half (extracting ~500 LOC of helpers to the module) would drop the file from 1,762 LOC to ~1,260 LOC — still above the C6 1000-LOC bar but with the bulk of the size attributable to the `$Global:KnownPrograms` database (lines 66-102, 35 KB) and the CSS-template block (lines 944-1177) both moved to data. **Highest-priority extraction:** `Export-ToHTML` (rank 1) — 452 LOC of pure renderer with a near-identical sibling in `EventLogAnalyzer.ps1`. Module helpers to add in P4: `New-SouliTEKHtmlReport`, `Get-BootHistoryStatistics`, `Format-StartupItemBlock`, `Invoke-PostReportAction`.
- **Target phase:** P4

### F4 — `Get-WinEvent -ListLog` probe-then-query idiom duplicated across 3 scripts
- **Severity:** low
- **Category:** structure (DRY)
- **Location:**
  - scripts/startup_boot_analyzer.ps1:268-280 (inside `Get-BootPerformanceFromEventLog`)
  - scripts/wifi_monitor.ps1:191-204 (inside `Get-WiFiDisconnectionHistory`)
  - scripts/usb_device_log.ps1:266-282 (inside `logQueries` foreach loop)
- **Reference:** Local finding (not a C-finding)
- **Current (verbatim from `startup_boot_analyzer.ps1:268-280`):**
  ```powershell
  try {
      # Check if event log exists and is enabled
      $logExists = Get-WinEvent -ListLog "Microsoft-Windows-Diagnostics-Performance/Operational" -ErrorAction SilentlyContinue

      if (-not $logExists -or -not $logExists.IsEnabled) {
          Write-Verbose "Boot performance event log not available or not enabled"
          return $null
      }

      $events = Get-WinEvent -LogName "Microsoft-Windows-Diagnostics-Performance/Operational" -MaxEvents 100 -ErrorAction SilentlyContinue |
          Where-Object { $_.Id -eq 100 }
  ```
- **Local notes — Same shape in 3 scripts:**
  - `wifi_monitor.ps1:191-204` — `$logExists = Get-WinEvent -ListLog $logName -ErrorAction SilentlyContinue; if ($logExists) { ... Get-WinEvent -FilterHashtable $filterHash -MaxEvents 1000 -ErrorAction SilentlyContinue ... }`
  - `usb_device_log.ps1:266-282` — `$logExists = Get-WinEvent -ListLog $logName -ErrorAction SilentlyContinue; if (-not $logExists) { Write-Verbose "Event log '$logName' not available"; continue }; $logEvents = Get-WinEvent -FilterHashtable $filterHash -MaxEvents 500 -ErrorAction SilentlyContinue`
- **Recommended:** Extract a `Get-SouliTEKEventLogEvents -LogName $name -FilterHashtable $hash -MaxEvents $n` helper in the module that does the probe+query in one call:
  ```powershell
  function Get-SouliTEKEventLogEvents {
      [CmdletBinding()]
      param(
          [Parameter(Mandatory)][string]$LogName,
          [hashtable]$FilterHashtable,
          [int]$MaxEvents = 1000
      )
      $log = Get-WinEvent -ListLog $LogName -ErrorAction SilentlyContinue  # safe: probe
      if (-not $log -or -not $log.IsEnabled) {
          Write-Verbose "Event log '$LogName' not available or disabled"
          return @()
      }
      $filter = if ($FilterHashtable) { $FilterHashtable } else { @{ LogName = $LogName } }
      if (-not $filter.ContainsKey('LogName')) { $filter['LogName'] = $LogName }
      try {
          Get-WinEvent -FilterHashtable $filter -MaxEvents $MaxEvents -ErrorAction Stop
      } catch {
          if ($_.Exception.Message -match 'No events were found') { return @() }
          throw
      }
  }
  ```
- **Risk if changed:** Low — pure structural extract. The three callers each reduce by ~10-15 LOC and the probe-then-query semantics are preserved exactly. **Not a duplication with `EventLogAnalyzer.ps1`** — that script uses a FilterXml-builder approach (lines 473-498) with no `Get-WinEvent -ListLog` probe and has its own error-handling for the "No events were found" case (lines 513-515). The two patterns are conceptually similar but operate at different abstraction levels: this proposed helper is the "simple log probe + FilterHashtable" idiom, while `EventLogAnalyzer.ps1` is the "rich XPath-query builder" idiom. Both could coexist in a future `modules/SouliTEK-EventLog.psm1`.
- **Target phase:** P4

### F5 — `Split-Path -Parent $MyInvocation.MyCommand.Path` instead of `$PSScriptRoot`
- **Severity:** low
- **Category:** structure
- **Location:** scripts/startup_boot_analyzer.ps1:43
- **Current:**
  ```powershell
  $ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
  ```
- **Recommended:**
  ```powershell
  $ScriptRoot = $PSScriptRoot
  ```
- **Risk if changed:** Low. Same rationale as F5 of `scripts-driver_integrity_scan.md` and F6 of `scripts-EventLogAnalyzer.md` — `$PSScriptRoot` is the canonical PS 3.0+ automatic variable and survives dot-sourcing. Folds into the C10 sweep eventually.
- **Target phase:** P4 (with C10)

### F6 — `$Global:*` mutable state for cross-function communication
- **Severity:** low
- **Category:** structure
- **Location:** scripts/startup_boot_analyzer.ps1:66 (`$Global:KnownPrograms`), :105 (`$Global:AllStartupItems = @()`), :106 (`$Global:LastBootData = $null`); read/write sites at lines 403-406, 1415-1418, 1422-1424, 1436-1440, 1451-1452, 1607, 1622, 1643, 1661, 1664, 1671.
- **Local notes:** `$Global:*` scope leaks the variables into the user's PowerShell session and pollutes the global namespace. Three issues:
  1. **`$Global:KnownPrograms`** (line 66, 35-entry hashtable, read-only after init) — should be `$Script:KnownPrograms`. Read-only data; no reason for global scope.
  2. **`$Global:AllStartupItems`** (line 105, mutated by `Invoke-FullAnalysis` and read by `Show-OptimizationRecommendations`, `Invoke-ExportReport`) — should be `$Script:AllStartupItems`. The intent is "cache the scan results across menu actions so the user doesn't re-scan when they hit `[3]` after `[1]`," which is a legitimate cross-function-in-same-script need that `$Script:` handles correctly.
  3. **`$Global:LastBootData`** (line 106, same access pattern) — same fix.
  Migration is mechanical: `Select-String -Pattern '\$Global:(KnownPrograms|AllStartupItems|LastBootData)' -Path scripts/startup_boot_analyzer.ps1 -Recurse | …` then `replace -all` to `$Script:`. No behavior change because no other script in the repo reads these globals (verified — `Select-String 'Global:KnownPrograms' scripts/` returns only this file).
- **Risk if changed:** Low. `$Script:` is the canonical scope for "shared within this script across functions." Behavior identical inside the script; leakage into the caller session is eliminated.
- **Target phase:** P4

### F7 — Infinite menu loop with `Read-Host` and `ReadKey` blocks under SYSTEM context
- **Severity:** low
- **Category:** structure (UX / RMM safety)
- **Location:** scripts/startup_boot_analyzer.ps1:1737 (`while ($true) { Show-MainMenu; $choice = Read-Host; … }`), plus blocking prompts at lines 1456, 1480, 1595, 1617, 1627, 1647, 1684, 1686, 1715, 1734, 1739.
- **Local notes:** Same RMM-deadlock concern as F6 of `scripts-driver_integrity_scan.md` and F7 of `scripts-EventLogAnalyzer.md`. The only graceful exit is menu option `[5]` which calls `exit` (line 1753). Unlike `EventLogAnalyzer.ps1` this script has **no parameter surface** — there is no `param()` block at the top, so no way to invoke it non-interactively. Under SYSTEM-context RMM execution this will deadlock on the first `Read-Host` after the welcome banner. Defer to P4 unless an actual RMM hang report comes in; pairs with the `Wait-SouliTEKKeyPress` F10 of `01-modules-SouliTEK-Common.md` and the C5 `[CmdletBinding(SupportsShouldProcess)]` work — adding `[CmdletBinding()]` + a `param([switch]$NonInteractive, [switch]$ExportHtml)` skeleton would make this script invocable from the launcher in a "scan + export, no menu" flow.
- **Target phase:** P4

### F8 — `Get-CimInstance Win32_Service -Filter "Name='$($service.Name)'"` interpolates an unescaped service name
- **Severity:** low (correctness, theoretical injection)
- **Category:** correctness
- **Location:** scripts/startup_boot_analyzer.ps1:227
- **Current:**
  ```powershell
  $serviceDetails = Get-CimInstance Win32_Service -Filter "Name='$($service.Name)'" -ErrorAction SilentlyContinue
  ```
- **Recommended:** Use the safer indexed lookup that avoids the WQL `-Filter` string altogether:
  ```powershell
  $serviceDetails = Get-CimInstance -ClassName Win32_Service -KeyOnly:$false |
      Where-Object { $_.Name -eq $service.Name } | Select-Object -First 1
  ```
  Or if the `-Filter` form is preferred for perf, escape single quotes in `$service.Name`:
  ```powershell
  $safeName = $service.Name -replace "'", "''"
  $serviceDetails = Get-CimInstance Win32_Service -Filter "Name='$safeName'" -ErrorAction SilentlyContinue
  ```
- **Risk if changed:** Low. Windows service names can technically contain apostrophes (rare but legal — service names are largely unrestricted strings, only the *display* name is conventionally limited). If a service is ever installed with a name like `Bad'Service`, the current form would emit a malformed WQL filter and `Get-CimInstance` would either throw or return `$null`. Pure correctness fix; no observed exploit. **Note:** CLAUDE.md's "Input validation on all external data" rule applies to user-controlled input — `Win32_Service.Name` is system-controlled here, so this is theoretical hardening, not a real vulnerability.
- **Target phase:** P3 (folds into general WQL-escaping hardening sweep — verify other scripts: `Get-CimInstance.*-Filter.*\$\(` across the repo)

### F9 — No `[CmdletBinding()]` on script or any function
- **Severity:** low
- **Category:** structure
- **Location:** scripts/startup_boot_analyzer.ps1 — script-level (no `param()` block at all, top of file is just `#Requires` directives and module-import boilerplate) and every one of the 18 internal functions (lines 113, 166, 211, 259, 312, 329, 370, 382, 437, 560, 700, 837, 906, 1363, 1384, 1459, 1599, 1630).
- **Local notes:** Same pattern as F4 of `scripts-driver_integrity_scan.md`. The script is fully interactive (no `param()` block, no CLI surface), so this is low-severity, but adding `[CmdletBinding()]` to `Export-ToHTML` (which already has `param([array]$StartupItems, [array]$BootData, [array]$Recommendations)`) and `Get-AutoStartServices` (`param([switch]$ExcludeMicrosoft)`) and `Get-BootPerformanceFromEventLog` (`param([int]$MaxEvents = 10)`) and `Save-BootTimeToHistory` (already has `Mandatory=$true` on its `param()` block) would let those functions accept `-Verbose` and `-ErrorAction` from callers. Pairs with F7 — the natural next step is to add a top-level `[CmdletBinding()]` + `param([switch]$NonInteractive, [switch]$ExportHtml, [string]$OutputPath)` skeleton.
- **Target phase:** P4

### F10 — Hard-coded HTML output path to `[Environment]::GetFolderPath("MyDocuments")`
- **Severity:** info
- **Category:** structure
- **Location:** scripts/startup_boot_analyzer.ps1:922-924
- **Current:**
  ```powershell
  $documentsPath = [Environment]::GetFolderPath("MyDocuments")
  $fileName = "StartupAnalysis_${computerName}_${timestamp}.html"
  $outputPath = Join-Path $documentsPath $fileName
  ```
- **Local notes:** Like F7 of `scripts-driver_integrity_scan.md`. Hard-coded to the current user's Documents folder; breaks under SYSTEM context where `[Environment]::GetFolderPath("MyDocuments")` returns `C:\Windows\system32\config\systemprofile\Documents` (which may not be writable in restricted-token scenarios) and offers no override. Low priority because the menu-driven design assumes interactive use. A `-OutputDirectory` parameter on `Export-ToHTML` (folding into F9) would be a clean follow-up. Note: `$UserDataPath = Join-Path $env:APPDATA "SouliTEK"` (line 57) for the boot history JSON is the right idiom and handles per-user paths correctly.
- **Target phase:** P4

### F11 — `Get-ProcessCPUUsage` is a no-op stub
- **Severity:** info
- **Category:** dead code
- **Location:** scripts/startup_boot_analyzer.ps1:370-380
- **Current:**
  ```powershell
  function Get-ProcessCPUUsage {
      <#
      .SYNOPSIS
          Optional: Measure process CPU usage (not implemented in read-only version)
      #>
      param([string]$ProcessName)

      # This is a placeholder for optional CPU measurement
      # In read-only mode, we rely on known database and user ratings
      return $null
  }
  ```
- **Local notes:** Defined but never called anywhere in the file (verified — `Select-String -Pattern 'Get-ProcessCPUUsage' -Path scripts/startup_boot_analyzer.ps1` returns only the function definition). Dead code from an abandoned feature. Delete the entire function (11 LOC saved) or implement it. Cosmetic; no behavior impact.
- **Target phase:** P4

### F12 — Trailing blank lines at EOF
- **Severity:** info
- **Category:** docs
- **Location:** scripts/startup_boot_analyzer.ps1:1762-1763 (2 trailing blank lines after the closing `}` of the menu while-loop on line 1761)
- **Local notes:** Cosmetic. Trim in any pass that touches the file. Same kind of cleanup as F11 of `scripts-EventLogAnalyzer.md`.
- **Target phase:** —

## Out-of-scope notes
- Banner block (lines 1-33, 33 lines of `# === / Coded by / IMPORTANT DISCLAIMER`) matches C11 cross-cutting cleanup; covered there. Note that the C11 collapse should preserve the `#Requires` directives on lines 36-37 (which currently sit *after* the banner and *before* the `$Host.UI.RawUI.WindowTitle =` assignment on line 40 — they are positioned correctly for parser early-exit).
- The `$Global:KnownPrograms` hashtable (lines 66-102, 35 entries mapping exe-name → `{Impact, Category}`) is a clean lookup table — well-organized and immediately useful to other startup-analysis flows. **Recommendation in P4:** when the F6 `$Global:` → `$Script:` cleanup runs, also move this hashtable to a `modules/SouliTEK-KnownPrograms.psd1` data file so multiple scripts (this one plus any future startup-related tool) can share it.
- `Get-StartupFolderItems` correctly handles `.lnk` shortcut parsing via `WScript.Shell.CreateShortcut` (lines 132-143) and falls back to the file path on COM-object failure. Solid.
- `Save-BootTimeToHistory` (lines 329-368) handles the rolling-history cap (line 360 `if ($history.Count -gt 30) { $history = $history | Select-Object -Last 30 }`) correctly and de-duplicates by timestamp (line 347 `if ($history | Where-Object { $_.BootTime -eq $bootTimeStr }) { return }`). No race risk because all reads/writes go through the menu loop sequentially.
- `Show-ScriptBanner` (called once at line 1725) is the C10 module helper — good, this script does use the modern wrapper instead of an inline banner. Pairs cleanly with the F5 `$PSScriptRoot` cleanup as part of the C10 sweep.
- The Performance Diagnostics event-log channel name `"Microsoft-Windows-Diagnostics-Performance/Operational"` and event ID 100 (boot performance summary) are stable and documented in the Microsoft "Diagnostics & Tracing" reference — no change needed.
- The `Get-CimInstance Win32_OperatingSystem | Select-Object -ExpandProperty LastBootUpTime` pattern (lines 578, 933) is the canonical PS 5.1-compatible way to retrieve the OS boot time. Both call sites are duplicate — minor extract candidate but not worth a finding (line-count saved: 2).
- The `Write-Progress` call at line 1424 (inside `Invoke-FullAnalysis`'s enrichment loop) is correctly paired with `Write-Progress -Completed` on line 1430 — good. Won't deadlock under non-interactive hosts because `Write-Progress` is a no-op when there's no console attached.
- The `Start-Sleep -Seconds 2` calls scattered throughout (lines 1448, 1693, 1696, 1703, 1706, 1758) are user-experience pauses that let the user read status messages before the menu re-renders. Acceptable in an interactive flow; would become a hang point if the F7 `[Environment]::UserInteractive` gate is added, so any P4 work on F7 should also strip or guard these.
- Zero `Get-WmiObject` calls (C3 N/A). Zero `Write-SouliTEK*` callers (C2 dead in this file). Two of the four "legacy API axes" come up clean — the **C** grade is driven by *size* (C6, rank 2 in the repo) and the *Write-Host-heavy* C1 footprint, not by legacy-API debt. If `Export-ToHTML` (rank-1, 452 LOC) is extracted into the shared `New-SouliTEKHtmlReport` helper alongside `EventLogAnalyzer.ps1`'s F3-rank-4 work in P4, this script becomes a **B-grade** candidate.
