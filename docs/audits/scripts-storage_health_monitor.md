# Audit — scripts/storage_health_monitor.ps1

## Inventory
| Item | Value |
|---|---|
| Path           | scripts/storage_health_monitor.ps1 |
| LOC            | 899 |
| Functions      | 8 (`Get-BaselineData`, `Save-BaselineData`, `Get-SMARTData`, `Show-StorageHealthReport`, `Export-HealthReport`, `Show-MainMenu`, `Show-ExitMessage`, `Show-Help`) |
| `#Requires`    | `#Requires -RunAsAdministrator` only (no `#Requires -Version`) |
| Admin-required | yes (declared by `#Requires -RunAsAdministrator`; reads `MSStorageDriver_FailurePredictStatus` from `root\wmi` and calls `Get-StorageReliabilityCounter`, both of which require elevation to return data — without admin they return null/empty rather than throwing) |
| Last touched   | 8675720 — 2026-04-17 |
| Modernization grade | B |

## Summary

A menu-driven SMART/health report for physical disks: enumerates `Get-PhysicalDisk`, pulls failure-predict status from the `root\wmi` `MSStorageDriver_FailurePredictStatus` class, layers in `Get-StorageReliabilityCounter` for reallocated-sector / read-error / temperature / power-on-hours / wear counters, persists a per-disk baseline JSON to `%LOCALAPPDATA%\SouliTEK\StorageHealthBaseline.json` to detect trend deltas across runs, and exports TXT/CSV/HTML reports to Desktop. Read-only by design. Already on `Get-CimInstance` (line 161) — **no C3 violation**, which is the main reason the modernization grade lands at B rather than D. Primary issues are (1) 60 raw `Write-Host` calls intermixed with `Write-Ui` (C1) — the script is in a half-migrated state where the level/spacer/status migration was started but the manual `==========` separators and the inline-color "Reallocated Sectors:" / "Read Errors:" composite lines (lines 378–382, 395–399) were left unconverted; (2) 4 `-ErrorAction SilentlyContinue` occurrences — all tag **A** (probes/optional reads), but the double-SC on line 178 obscures whether `Get-PhysicalDisk -DeviceNumber` failure or `Get-StorageReliabilityCounter` failure is being swallowed; (3) two real correctness bugs — the `BusType` filter on line 316 is a tautology (`-ne "USB" -or -ne "Unknown"` is always true) and menu option **7. Exit** is broken (`break` in a `switch` exits the switch, not the `do/while($true)`; `Show-SouliTEKExitMessage` does not call `exit`, so option 7 redisplays the menu instead of exiting); (4) 24 `$x -ne $null` / `$x -eq $null` comparisons with `$null` on the right (PSScriptAnalyzer `PSPossibleIncorrectComparisonWithNull` — should be `$null -ne $x`). Secondary concerns are the usual structural items (C10 boilerplate, C11 banner, no `[CmdletBinding()]`, `$MyInvocation.MyCommand.Path` instead of `$PSScriptRoot`, hard-coded Desktop output path, blocking `Read-Host` gates with no `[Environment]::UserInteractive` check). Recommended phase entry order: P0 (analyzer baseline will catch the null-comparison and the tautology bug), then P1 (C1 sweep), then P2 (the four SC occurrences are all tag A so the P2 pass is mostly comment-adds).

## Findings

### F1 — Mixed `Write-Host` / `Write-Ui` (see C1)
- **Severity:** med
- **Category:** output-style
- **Location:** scripts/storage_health_monitor.ps1 — 60 raw `Write-Host` occurrences. No legacy `Write-SouliTEK*` callers (C2-clean).
- **Reference:** [C1](00-cross-cutting.md#c1--raw-write-host-calls-not-migrated-to-write-uiwrite-status)
- **Current (representative pattern — composite metric line at 378–385):**
  ```powershell
  Write-Host "  Reallocated Sectors: " -NoNewline -ForegroundColor White
  Write-Host "$($smartData.ReallocatedSectors)" -ForegroundColor $color -NoNewline
  if ($smartData.ReallocatedSectorsTrend -ne "N/A") {
      $trendColor = if ($smartData.ReallocatedSectorsTrend -like "INCREASING*") { "Red" } elseif ($smartData.ReallocatedSectorsTrend -eq "STABLE") { "Green" } else { "Yellow" }
      Write-Host " [$($smartData.ReallocatedSectorsTrend)]" -ForegroundColor $trendColor
  } else {
      Write-Host ""
  }
  ```
- **Recommended:**
  ```powershell
  $level = if ($smartData.ReallocatedSectors -gt 100) { "ERROR" } elseif ($smartData.ReallocatedSectors -gt 10) { "WARN" } else { "OK" }
  $trend = if ($smartData.ReallocatedSectorsTrend -ne "N/A") { " [$($smartData.ReallocatedSectorsTrend)]" } else { "" }
  Write-Ui -Message "  Reallocated Sectors: $($smartData.ReallocatedSectors)$trend" -Level $level
  ```
- **Risk if changed:** Low — message text preserved verbatim. The two-color composite ("white label + colored value + colored trend tag" on one line) loses the in-line color split but gains a single `[LEVEL]` bracket that signals severity directly. The same pattern applies to the Read Errors block (lines 395–401).
- **Local notes:** Four categories of raw `Write-Host`:
  1. **Blank-line spacer calls** — bare `Write-Host ""` used as vertical spacing (lines 305, 307, 312, 340, 344, 348, 384, 401, 427, 435, 444, 449, 456, 736, 739, 748, 750, 755, 758, 760, 768, 770, 786, 788, 793, 795, 801, 808, 814, 820, 826, 831, 836, 840, 857, 893). These are NOT C1 violations under the cross-cutting "visual separator helpers" exception (~36 of the 60 calls). Leave as-is or migrate to a `Show-Section` helper if one is added in P4.
  2. **Manual `==========` separators** — lines 309, 311, 432, 434, 446, 448, 752, 754, 769, 790, 792. Eleven occurrences of `Write-Host "==========================================" -ForegroundColor <Cyan|Red|Green>`. These are real C1 violations and a perfect fit for the future `Show-Section` / `Show-Divider` helper called out in C11. Until that helper exists, inline `Write-Ui -Message "==========================================" -Level "INFO"` is acceptable; the color difference (Red for warnings section, Green for clean section, Cyan for headers) becomes a `[LEVEL]` differentiation.
  3. **Composite metric lines** — lines 360, 378–384 (Reallocated Sectors row), 395–401 (Read Errors row). Six C1 violations forming two logical units. Migration pattern shown in `Recommended` above. **Important:** in the migration, the on-screen "Reallocated Sectors: N" header on line 360 (`Write-Host "  Health Status: " -NoNewline`) is followed by a `Write-Ui` on line 364/367/370 that emits the value — the `Write-Host` half of that pair is what survives the partial migration. Strip the leftover `Write-Host` and let `Write-Ui` carry the full line.
  4. **Plain prompt lines** — `Write-Host "Press Enter to return to menu..."` (lines 320, 327), `Write-Host "Press Enter to continue..."` (lines 459, 470, 740), `Write-Host "Select an option (1-7): " -NoNewline -ForegroundColor Yellow` (line 771). Six C1 violations. These should become `Write-Ui -Message "..." -Level "PROMPT"` (or `-Level "INFO"`) once the migration helper supports `-NoNewline` — or, simpler, replace the whole "Press Enter to continue" pattern with `Wait-SouliTEKKeyPress` from the common module, gated by an `[Environment]::UserInteractive` check (see F5 below).
- **Target phase:** P1

### F2 — `-ErrorAction SilentlyContinue` triage (see C4)
- **Severity:** med
- **Category:** error-handling
- **Location:** scripts/storage_health_monitor.ps1 — 4 occurrences across 3 lines (task plan predicted 3, undercount because line 178 carries two on a single line)
- **Reference:** [C4](00-cross-cutting.md#c4----erroraction-silentlycontinue-swallowing-failures)
- **Triage:**
  - Line 75: tag **A** — `Get-Content -Path $Script:BaselinePath -Raw -ErrorAction SilentlyContinue` is the baseline-load probe. The result is immediately tested with `if ($baselineJson)` before `ConvertFrom-Json`. The whole block is wrapped in `try { ... } catch { Write-Verbose "Could not load baseline: $_" }` (lines 68–84) so the SC is doubly defensive — could be dropped now that the outer `try`/`catch` exists. Add `# safe: probe — guarded by outer try/catch` comment in P2.
  - Line 161: tag **A** — `Get-CimInstance -Namespace "root\wmi" -ClassName "MSStorageDriver_FailurePredictStatus" -ErrorAction SilentlyContinue` is wrapped in its own `try { ... } catch { Write-Verbose ... }` (lines 160–173) and the result is tested with `if ($smartInfo)` before use. Some disks (USB, virtual, NVMe under certain drivers) genuinely don't expose `MSStorageDriver_FailurePredictStatus`; the SC + outer try is correct. Add `# safe: probe — class absent on some bus types` comment.
  - Line 178 (first SC, on `Get-PhysicalDisk -DeviceNumber $diskNumber`): tag **A** — re-querying the disk by device number to feed `-PhysicalDisk` parameter. Could legitimately fail if the disk vanished mid-loop (hot-unplug). Outer `try`/`catch` at lines 176–215 catches the consequent failure. However: this is also a code smell — we already have `$PhysicalDisk` in scope from the outer `foreach`; the `Get-PhysicalDisk -DeviceNumber $diskNumber` round-trip is unnecessary (could just pass `$PhysicalDisk` directly). Worth flagging as a P2 cleanup alongside the SC comment.
  - Line 178 (second SC, on `Get-StorageReliabilityCounter`): tag **A** — `Get-StorageReliabilityCounter` legitimately returns nothing for disks that don't expose reliability counters (e.g. some USB enclosures, virtual disks). Wrapped in the outer `try`/`catch`. Add `# safe: probe — counter unavailable on some disks` comment.
- **Local notes:** All four occurrences are defensible probes guarded by outer `try`/`catch` blocks that log to `Write-Verbose`. None hides a real bug. The cleanup task is comment-add only, plus the recommendation to drop the redundant `Get-PhysicalDisk -DeviceNumber` round-trip on line 178.
- **Target phase:** P2

### F3 — `BusType` filter is a tautology — USB/Unknown disks are never excluded
- **Severity:** med
- **Category:** correctness
- **Location:** scripts/storage_health_monitor.ps1:316
- **Current:**
  ```powershell
  $physicalDisks = Get-PhysicalDisk | Where-Object { $_.BusType -ne "USB" -or $_.BusType -ne "Unknown" }
  ```
- **Recommended:**
  ```powershell
  $physicalDisks = Get-PhysicalDisk | Where-Object { $_.BusType -ne "USB" -and $_.BusType -ne "Unknown" }
  ```
- **Local notes:** `$_.BusType -ne "USB" -or $_.BusType -ne "Unknown"` evaluates to `$true` for every possible value of `$_.BusType` — a `BusType` of `"USB"` is `-ne "Unknown"` (true), and a `BusType` of `"Unknown"` is `-ne "USB"` (true). The intent (per the filter's existence and the comment-free obviousness) is **De Morgan AND**: exclude disks whose bus is USB OR Unknown. The current code is dead-filtering — every disk reaches `Get-SMARTData`, including USB sticks where most SMART data will be null. This matches the audit task description ("Uses `Get-PhysicalDisk` + SMART data") and is the kind of bug PSScriptAnalyzer + a Pester smoke test (C7/C8) would catch immediately.
- **Risk if changed:** Low. The fix changes the operator from `-or` to `-and`. Any caller currently relying on USB disks showing up in the report will lose them — which is the intended behavior given the filter's existence. Consider a `-IncludeRemovable` switch on the future parameterized entry point (see F8) to preserve the override.
- **Target phase:** P0 (analyzer baseline) / P1 (one-character fix)

### F4 — Menu option 7 "Exit" does not exit
- **Severity:** med
- **Category:** correctness (UX)
- **Location:** scripts/storage_health_monitor.ps1:888–891 + 863–898 main loop, with `Show-SouliTEKExitMessage` in `modules/SouliTEK-Common.ps1:663–696`
- **Current:**
  ```powershell
  do {
      Show-MainMenu
      $choice = Read-Host
      switch ($choice) {
          ...
          "7" {
              Show-ExitMessage
              break
          }
          ...
      }
  } while ($true)
  ```
- **Recommended:**
  ```powershell
  $shouldExit = $false
  do {
      Show-MainMenu
      $choice = Read-Host
      switch ($choice) {
          ...
          "7" {
              Show-ExitMessage
              $shouldExit = $true
          }
          ...
      }
  } while (-not $shouldExit)
  ```
- **Local notes:** `break` inside a `switch` only exits the `switch` — it does **not** exit the enclosing `do/while`. `Show-ExitMessage` calls `Show-SouliTEKExitMessage` which (per `modules/SouliTEK-Common.ps1` lines 663–696) only `Clear-Host`s and writes "Thank you for using ..." then returns. It does NOT call `exit`. So the current behavior of selecting "7. Exit" is: clear screen, print thank-you, fall through, the `do { Show-MainMenu` body runs again, and the user is back at the menu. The only way out today is Ctrl+C. Either set a sentinel `$shouldExit` flag (shown above) or call `exit` / `return` in the `"7"` arm directly. The `default` arm's `Start-Sleep -Seconds 2` (line 895) also blocks under SYSTEM-context execution and pairs naturally with the F5 non-interactive gate.
- **Risk if changed:** Low. The fix preserves the visible exit-message UX but actually terminates the loop. Either `break 2` (PS-7+ only — not safe on the 5.1 floor), `exit`, `return`, or the sentinel flag approach. Sentinel flag is the recommended pattern because it leaves the main-loop control flow legible.
- **Target phase:** P1

### F5 — Blocking `Read-Host` gates with no non-interactive exit
- **Severity:** low
- **Category:** structure (UX / RMM safety)
- **Location:** scripts/storage_health_monitor.ps1 — `Read-Host` calls at lines 321, 328, 460, 471, 741, 842, 859, 865, plus the main `do { ... } while ($true)` at line 863 and `Start-Sleep -Seconds 2` on line 895.
- **Local notes:** Eight `Read-Host` prompts (six "Press Enter to continue" gates + the menu choice + the admin-warning gate). Combined with the broken exit (F4) and the unconditional `do/while($true)`, this script will deadlock the worker if launched non-interactively (e.g. by an RMM agent). User's CLAUDE.md explicitly calls out SYSTEM-context execution as a deployment scenario. There is no `[Environment]::UserInteractive` check and no `-NonInteractive` / `-Silent` switch. Wraps cleanly with the F8 `[CmdletBinding()]` add. Pairs with the cross-cutting `Wait-SouliTEKKeyPress` discussion (F10 of 01-modules-SouliTEK-Common.md).
- **Target phase:** P4

### F6 — 24 `$x -ne $null` / `$x -eq $null` comparisons with `$null` on the wrong side
- **Severity:** low
- **Category:** lint
- **Location:** scripts/storage_health_monitor.ps1 — lines 226, 228, 263, 265, 376, 386, 393, 403, 410, 414, 419, 423, 502, 506, 510, 514, 519, 523, 643, 652, 661, 670, 680, 689 (24 occurrences)
- **Current (representative):**
  ```powershell
  if ($smartData.ReallocatedSectors -ne $null) {
  ```
- **Recommended:**
  ```powershell
  if ($null -ne $smartData.ReallocatedSectors) {
  ```
- **Local notes:** PSScriptAnalyzer rule `PSPossibleIncorrectComparisonWithNull`. When the LHS is an array, `$array -ne $null` element-wise filters (returning the non-null elements as a new array, which is truthy if any are non-null) rather than asking the question "is the array variable null?" The properties tested here (`ReallocatedSectors`, `ReadErrors`, `Temperature`, etc.) come from a `[hashtable]` so should always be scalars — but the rule exists because scalar-vs-array drift is a frequent source of subtle bugs. Will surface in P0 when the PSScriptAnalyzer baseline (C8) is captured. Pure mechanical fix in P1.
- **Target phase:** P0 (baseline) / P1 (fix sweep)

### F7 — Redundant `Get-PhysicalDisk -DeviceNumber` round-trip
- **Severity:** info
- **Category:** structure (perf / clarity)
- **Location:** scripts/storage_health_monitor.ps1:178
- **Current:**
  ```powershell
  $reliabilityCounters = Get-StorageReliabilityCounter -PhysicalDisk (Get-PhysicalDisk -DeviceNumber $diskNumber -ErrorAction SilentlyContinue) -ErrorAction SilentlyContinue
  ```
- **Recommended:**
  ```powershell
  $reliabilityCounters = Get-StorageReliabilityCounter -PhysicalDisk $PhysicalDisk -ErrorAction SilentlyContinue
  ```
- **Local notes:** `$PhysicalDisk` (the parameter of `Get-SMARTData`) is already a `CimInstance` of the physical disk — there is no need to re-query by device number to get the same object back. Removes one of the four C4 SilentlyContinue occurrences as a side benefit. Trivial change, no behavior delta.
- **Target phase:** P2 (fold into the F2 cleanup pass)

### F8 — No `[CmdletBinding()]` on script or any function
- **Severity:** low
- **Category:** structure
- **Location:** scripts/storage_health_monitor.ps1 — script-level (no `param()` block) and every one of the 8 internal functions (`Get-BaselineData` line 63, `Save-BaselineData` line 89, `Get-SMARTData` line 122, `Show-StorageHealthReport` line 302, `Export-HealthReport` line 463, `Show-MainMenu` line 745, `Show-ExitMessage` line 779, `Show-Help` line 783).
- **Local notes:** Two functions already have `param()` blocks (`Save-BaselineData` line 94 takes `[array]$CurrentData`, `Export-HealthReport` line 463 takes `[string]$Format = "TXT"`, `Get-SMARTData` lines 122–126 takes `[CimInstance]$PhysicalDisk` and `[hashtable]$Baseline`). Adding `[CmdletBinding()]` to those three is free and lets them accept `-Verbose` (useful given the `Write-Verbose` calls scattered through `Get-BaselineData`, `Save-BaselineData`, and `Get-SMARTData`). The script as a whole has no `param()` block — a P4 follow-up could add `[CmdletBinding()] param([switch]$NonInteractive, [string]$OutputDirectory = "$env:USERPROFILE\Desktop", [ValidateSet('TXT','CSV','HTML','All')][string]$ExportFormat)` to provide a non-interactive entry point and pair it with F5's `[Environment]::UserInteractive` gate.
- **Target phase:** P4

### F9 — `Split-Path -Parent $MyInvocation.MyCommand.Path` instead of `$PSScriptRoot`
- **Severity:** low
- **Category:** structure
- **Location:** scripts/storage_health_monitor.ps1:41
- **Current:**
  ```powershell
  $ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
  ```
- **Recommended:**
  ```powershell
  $ScriptRoot = $PSScriptRoot
  ```
- **Risk if changed:** Low. `$PSScriptRoot` is the canonical PS-3.0+ automatic variable. `$MyInvocation.MyCommand.Path` returns `$null` when the script is dot-sourced. C10 will eventually replace this whole block with `Import-SouliTEKCommon`.
- **Target phase:** P4 (fold into the C10 sweep)

### F10 — Hard-coded Desktop output path with no override
- **Severity:** info
- **Category:** structure
- **Location:** scripts/storage_health_monitor.ps1:56 (`$Script:OutputDir = "$env:USERPROFILE\Desktop"`).
- **Local notes:** Same anti-pattern as F7 of `scripts-driver_integrity_scan.md`. The TXT/CSV/HTML export targets are hard-coded to the current user's Desktop. Breaks under SYSTEM context. `$Script:BaselinePath` (line 57) uses `$env:LOCALAPPDATA` which is the correct idiom and handles per-user paths correctly. Pairs with the F8 `[CmdletBinding()] param(-OutputDirectory)` add.
- **Target phase:** P4

## Out-of-scope notes
- Banner block (lines 1–32, 27 lines of `# === / Coded by / IMPORTANT DISCLAIMER`) matches C11 cross-cutting cleanup; covered there.
- `Import SouliTEK Common Functions` boilerplate at lines 40–48 matches C10 cross-cutting cleanup; covered there.
- The script is **C2-clean** — no calls to `Write-SouliTEKResult`, `Write-SouliTEKInfo`, `Write-SouliTEKSuccess`, `Write-SouliTEKWarning`, or `Write-SouliTEKError`. The C1 migration here is straight `Write-Host -> Write-Ui` with no legacy-API layer to peel off.
- The script is **C3-clean** — no `Get-WmiObject` calls. The `MSStorageDriver_FailurePredictStatus` query on line 161 already uses `Get-CimInstance` correctly, which is why this script lands at grade B rather than D despite the C1 burden and the two correctness bugs.
- The `Get-BaselineData` / `Save-BaselineData` JSON-persist pattern (lines 63–120) is clean: creates the parent directory if missing, uses `ConvertTo-Json -Depth 10`, and the surrounding `try { ... } catch { Write-Verbose ... }` is appropriately quiet for a non-essential cache write. No change needed beyond the F6 null-comparison sweep.
- The threshold logic in `Get-SMARTData` (lines 226–297) is well-structured: separate absolute-threshold and trend-delta checks for both reallocated sectors and read errors, with `$Script:Warnings` accumulating human-readable messages tagged `CRITICAL:` / `WARNING:` / `INFO:`. The `WarningLevel` escalation pattern (`if ($smartData.WarningLevel -eq "CRITICAL") { "CRITICAL" } else { "WARNING" }` on lines 234, 271) correctly preserves CRITICAL once set. No change needed.
- The HTML export (lines 570–731) is a clean inline-styled report card with a gradient header, info-grid layout, and color-coded status/warning sections. Self-contained (no external CSS/JS). If a future P4 pass adds a shared report template helper, this would be a natural extract target.
- The `Show-Help` function (lines 783–843) is a 60-line help screen with documented thresholds, requirements, and support contact — useful inline documentation that should survive the C1 migration intact (just `Write-Host "" -> Write-Ui -Spacer` and the manual `==========` separators -> shared helper).
- The `$Script:ReportData` and `$Script:Warnings` arrays (lines 54–55) accumulate via `+=` inside the disk-iteration loop. For a typical 1–4 physical-disk machine this is fine; if this ever needs to scale to a SAN with dozens of disks, replace with `[System.Collections.Generic.List[object]]::new()` to avoid the O(n²) reallocation cost. Not worth flagging as a finding given typical disk counts.
- The `Start-Sleep -Seconds 2` on line 895 (invalid-option arm of the menu switch) is a 2-second pause that ties the worker thread under non-interactive execution. Bundle with F5 in the P4 `[Environment]::UserInteractive` gate.
