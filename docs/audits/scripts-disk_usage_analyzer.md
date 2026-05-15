# Audit — scripts/disk_usage_analyzer.ps1

## Inventory
| Item | Value |
|---|---|
| Path           | scripts/disk_usage_analyzer.ps1 |
| LOC            | 789 |
| Functions      | 13 |
| `#Requires`    | `#Requires -Version 5.1` |
| Admin-required | no (declared optional — `Test-SouliTEKAdministrator` is called at line 737 and only emits a "running without admin" warning; the script enumerates user-readable folders, so non-admin runs work but skip protected directories). |
| Last touched   | 8675720 — 2026-04-17 |
| Modernization grade | C |

## Summary

A menu-driven storage-cleanup triage tool: enumerates every directory under a chosen path, sums file sizes per directory via two nested `Get-ChildItem -Recurse` calls, surfaces folders above a configurable GB threshold, and exports TXT/CSV/HTML reports to the user's Desktop. The dominant issue is style/output — 84 raw `Write-Host` calls coexist with `Write-Ui` calls and one residual `Write-SouliTEKResult` call (line 579) from the C2 dead API, producing a three-way output-style mix. Inside the same `Write-Ui` calls many messages embed inline `[1]`/`[!]`/`[FOUND]` markers, double-marking the bracket emitted by `Write-Ui` (same anti-pattern as F2 of `01-modules-SouliTEK-Common.md`). The three `-ErrorAction SilentlyContinue` occurrences are all legitimate permission-denied / read-probe uses on recursive filesystem walks and carry triage tag **A**. The headline performance issue is the C13 candidate at line 135 — a sequential `foreach ($folder in $allFolders)` loop where each iteration recursively scans the folder tree under `$folder.FullName` (via `Get-FolderStats` at line 143, which itself calls `Get-ChildItem -Recurse -File` at line 80). The inner scan is independent per folder and is the highest-value parallelism target once `Invoke-SouliTEKParallel` (P4) exists. Secondary concerns: no `[CmdletBinding()]` on the script or any of the 13 functions; `Split-Path -Parent $MyInvocation.MyCommand.Path` instead of `$PSScriptRoot` at line 40; hard-coded Desktop output path with no override; infinite `do ... while` menu loop with `Read-Host` gates (RMM-unsafe); the C11 banner block occupies the first 32 lines. Recommended phase entry order: P1 (C1 + C2), then P2 (C4 triage), then P4 (C13 once the parallel helper exists).

## Findings

### F1 — Mixed `Write-Host` / `Write-Ui` / `Write-SouliTEKResult` (see C1, C2)
- **Severity:** med
- **Category:** output-style
- **Location:** scripts/disk_usage_analyzer.ps1 — 84 raw `Write-Host` occurrences plus 1 residual `Write-SouliTEKResult` call (line 579) that exercises C2's dead API.
- **Reference:** [C1](00-cross-cutting.md#c1--raw-write-host-calls-not-migrated-to-write-uiwrite-status), [C2](00-cross-cutting.md#c2--dead-duplicate-output-api)
- **Current (representative pattern — inline-color formatting at lines 105–106):**
  ```powershell
  Write-Host "Scanning path: " -NoNewline -ForegroundColor Cyan
  Write-Ui -Message $Path -Level "STEP"
  ```
- **Recommended:**
  ```powershell
  Write-Ui -Message "Scanning path: $Path" -Level "STEP"
  ```
- **Risk if changed:** Low — message text preserved verbatim; the `[STEP]` bracket emitted by `Write-Ui` replaces the manual color formatting. Per-category fix patterns are enumerated below in Local notes.
- **Local notes:** Four categories of raw `Write-Host`:
  1. **Blank-line / spacer calls** — bare `Write-Host ""` used as vertical spacing (lines 109, 111, 114, 132, 172, 176, 179, 184, 193, 199, 210, 216, 218, 228, 236, 239, 254, 260, 291, 344, 374, 515, 525, 531, 545, 548, 557, 563, 567, 589, 592, 601, 605, 610, 628, 630, 632, 644, 646, 648, 656, 668, 673, 678, 683, 688, 694, 698, 704, 708, 711, 714, 717, 719, 738, 741, 763 — 57 occurrences). These should remain as-is or migrate to a `Write-Ui -Spacer` / `Show-Section` helper if one is added in P4 — they are not C1 violations per the "visual separator helpers" exception, but they are noisy.
  2. **Visual separator `===` bars** — `Write-Host "===…===" -ForegroundColor Cyan` (lines 110, 173, 175, 217, 233, 235, 631, 645, 667, 695, 697, 705, 707, 718) and `"========================================" -ForegroundColor DarkGray` (line 657). These are visual-separator helpers per the C1 exception; recommendation is to consolidate via a `Show-Section` helper in P4 but they are not strict violations.
  3. **Inline-color formatting (`-NoNewline` + secondary `Write-Ui`)** — lines 105, 107, 159–160, 187–188, 539, 634, 640, 642. These are real C1 violations: pre-Write-Ui-era manual color formatting that should fold into a single `Write-Ui -Message "..." -Level "STEP"` call. Example fix block already shown above.
  4. **Plain content with manual `-ForegroundColor`** — line 178 (`Write-Host "Large folders found: $foundCount" -ForegroundColor ...`) and line 643 (`Write-Host "$($Script:FolderData.Count)" -ForegroundColor ...`) — both use a ternary-style conditional `-ForegroundColor` based on count. These are C1 violations; recommend `Write-Ui -Message "Large folders found: $foundCount" -Level $(if ($foundCount -gt 0) { 'OK' } else { 'WARN' })` so the `[OK]`/`[WARN]` bracket replaces the conditional color.
- **Local notes (cont.) — inline marker prefixes:** Many `Write-Ui` calls in this script already double-mark with embedded `[FOUND]`, `[1]`, `[2]`, `[0]`, `[!]`, `[$index]` prefixes inside the message text (lines 159 — `[FOUND]`; 187 — `[$($top10.IndexOf($folder) + 1)]`; 224 — `[$index]`; 255–259, 539, 546–547, 649–655 — bracketed menu numbers like `[1]`, `[2]`, `[0]`; 669, 674, 679, 684, 689, 709, 712, 715 — `[1] SELECT SCAN PATH`, `[2] SET MINIMUM SIZE`, etc.). These bracketed numerals are *menu-item identifiers*, not status markers, so they should remain in the message text — but the surrounding `Write-Ui -Level "WARN"` / `-Level "ERROR"` choices then double-mark with `[WARN]`/`[ERROR]` brackets on top of `[1]`/`[0]`. Recommend changing these to `-Level "INFO"` for menu items where the bracket is a menu identifier, and reserving `-Level "WARN"`/`-Level "ERROR"` for true status output. Pairs with the same anti-pattern review in F2 of `01-modules-SouliTEK-Common.md`.
- **Local notes (cont.) — legacy API caller:** 1 residual call to the C2 dead API at line 579 (`Write-SouliTEKResult "Invalid choice" -Level ERROR`). This is an inconsistency with the surrounding code in the same function (`Select-ScanPath`) which otherwise uses `Write-Ui` (e.g. line 573, 568, 558). Migrate to `Write-Ui -Message "Invalid choice" -Level "ERROR"`. Must land before C2's "delete the five legacy functions from the module" step.
- **Target phase:** P1

### F2 — `-ErrorAction SilentlyContinue` triage (see C4)
- **Severity:** med
- **Category:** error-handling
- **Location:** scripts/disk_usage_analyzer.ps1 — 3 occurrences
- **Reference:** [C4](00-cross-cutting.md#c4----erroraction-silentlycontinue-swallowing-failures)
- **Triage:**
  - Line 80: tag **A** — `Get-ChildItem -Path $FolderPath -Recurse -File -ErrorAction SilentlyContinue -Force` inside `Get-FolderStats`. Recursive file enumeration over arbitrary directories will hit folders the current user cannot read (`System Volume Information`, `$Recycle.Bin`, other users' profiles, `WindowsApps`, junctions/reparse points). The denied-folder skip is the *intended* behavior — the function is computing a best-effort size estimate. Legitimate. Add `# safe: denied-folder probe` comment in P2.
  - Line 81: tag **A** — `($items | Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum`. The pipe operates on the already-filtered output of line 80; the SC here is defensive against a `Measure-Object` error on an empty array (which `Measure-Object` does already handle correctly, so this SC is redundant — but it's not harmful and the result is null-coalesced via the `if ($null -eq $size) { 0 } else { $size }` block on line 85). Legitimate but candidate for removal. Add `# safe: defensive` comment, or drop the SC during P2 cleanup since `Measure-Object` won't throw on the inputs this function feeds it.
  - Line 129: tag **A** — `Get-ChildItem -Path $Path -Directory -ErrorAction SilentlyContinue -Force -Recurse` in `Get-LargeFolders`. Same denied-folder skip rationale as line 80, applied at the directory-enumeration level. The script's whole purpose requires this — root-level scans over `C:\` will hit denied folders that the user explicitly accepted by running without admin (warned about at lines 737–743). Legitimate. Add `# safe: denied-folder probe` comment in P2.
- **Target phase:** P2

### F3 — Sequential folder-scan loop is the main C13 parallelism target
- **Severity:** low (perf)
- **Category:** perf
- **Location:** scripts/disk_usage_analyzer.ps1 — main loop at lines 135–170 in `Get-LargeFolders`; inner per-folder scan in `Get-FolderStats` at lines 79–95 (called from line 143).
- **Reference:** [C13](00-cross-cutting.md#c13--sequential-foreach-over-large-datasets-where-parallelism-would-help)
- **Current:**
  ```powershell
  $allFolders = Get-ChildItem -Path $Path -Directory -ErrorAction SilentlyContinue -Force -Recurse
  # ...
  foreach ($folder in $allFolders) {
      # ...
      $stats = Get-FolderStats -FolderPath $folder.FullName   # recursive -File scan
      $folderSize = $stats.Size
      if ($folderSize -ge $minSizeBytes) {
          # ... emit + accumulate ...
      }
  }
  ```
- **Recommended (once `Invoke-SouliTEKParallel` lands in P4):**
  ```powershell
  $largeFolders = Invoke-SouliTEKParallel `
      -InputObject $allFolders `
      -ScriptBlock {
          param($folder, $minSizeBytes)
          $stats = Get-FolderStats -FolderPath $folder.FullName
          if ($stats.Size -ge $minSizeBytes) {
              [PSCustomObject]@{
                  Path         = $folder.FullName
                  Name         = $folder.Name
                  SizeBytes    = $stats.Size
                  SizeGB       = [math]::Round($stats.Size / 1GB, 2)
                  ParentPath   = $folder.Parent.FullName
                  LastModified = $folder.LastWriteTime
                  ItemCount    = $stats.Count
              }
          }
      } `
      -ArgumentList @($minSizeBytes) `
      -ThrottleLimit 8
  ```
- **Why this loop:** Each iteration of the outer `foreach` triggers a recursive `Get-ChildItem -Recurse -File` walk under `$folder.FullName` (via `Get-FolderStats`) — these per-folder walks are completely independent (no shared state, no ordering dependency, results only aggregate at the end). Disk I/O is the bottleneck, not CPU, so parallelism gains depend on storage type: minimal speedup on a single HDD (head contention will serialize anyway), 2-3x speedup on a SATA SSD, 4-8x speedup on NVMe. The progress reporting at lines 137–139 (`if ($progressCount % 50 -eq 0) { Write-Ui ... }`) and the inline `[FOUND]` emit at lines 159–161 would need to migrate to a thread-safe channel (e.g. a `[System.Collections.Concurrent.ConcurrentQueue]` drained by the host thread between batches) — `Invoke-SouliTEKParallel` should expose a `-ProgressCallback` for exactly this case.
- **Note (double-recursion concern):** The current implementation does redundant work: line 129 already calls `Get-ChildItem -Recurse` to enumerate *all* directories, and then for *each* directory the inner `Get-FolderStats` (line 80) does another `-Recurse -File`. This means files in deep subtrees are counted at every ancestor level — which is the *intent* (each folder's size includes its descendants), but the I/O cost is O(depth × files) instead of O(files). A more efficient alternative is a single-pass enumeration that builds parent->size aggregates from the leaf upward; the current code prioritizes simplicity over throughput. **Do not refactor as part of C13** — the parallelism approach above is the directed P4 fix; a deeper algorithmic rewrite is out of scope unless profiling shows scan times exceeding 10 minutes on a typical NVMe `C:\` drive.
- **Risk if changed:** Medium. Concurrent filesystem walks on Windows can occasionally surface different exceptions than serial walks (mostly around reparse points and junctions, which today get silently swallowed by `-ErrorAction SilentlyContinue`). The `Invoke-SouliTEKParallel` helper must include max-thread cap + cancellation token (per C13 in 00-cross-cutting). **Do not refactor until the module helper exists** (P4 dependency).
- **Target phase:** P4

### F4 — No `[CmdletBinding()]` on script or any function
- **Severity:** low
- **Category:** structure
- **Location:** scripts/disk_usage_analyzer.ps1 — script-level (top of file, no `param()` block at all) and every one of the 13 internal functions (`Format-FileSize` line 64, `Get-FolderStats` line 69, `Get-LargeFolders` line 97, `Show-LargeFolders` line 205, `Export-DiskUsageReport` line 244, `Export-TextReport` line 295, `Export-CSVReport` line 350, `Export-HTMLReport` line 380, `Select-ScanPath` line 521, `Set-MinimumSize` line 585, `Show-MainMenu` line 622, `Show-Help` line 663, `Show-ExitMessage` line 724).
- **Local notes:** The script is fully interactive (no script-level `param()` block, no CLI surface), so this is low-severity. Adding `[CmdletBinding()]` to `Get-LargeFolders` (`param([string]$Path, [double]$MinSizeGB)`), `Get-FolderStats` (`param([string]$FolderPath)`), `Format-FileSize` (`param([long]$SizeInBytes)`), and the three export functions (`param($Folders, $Timestamp)`) would let those functions accept `-Verbose` and `-ErrorAction` from callers and would also enable type validation via `[ValidateNotNullOrEmpty()]` on `$Path` — currently a non-existent path is caught at line 122 (`if (-not (Test-Path $Path))`) only after `Get-LargeFolders` has already cleared its UI banner. This is C5 territory only if the script gets a non-interactive parameterised entry point. Pairs naturally with F5 (a `param([string]$Path, [double]$MinSizeGB)` at script-top would let RMM callers invoke `disk_usage_analyzer.ps1 -Path 'C:\' -MinSizeGB 5` non-interactively).
- **Target phase:** P4

### F5 — `Split-Path -Parent $MyInvocation.MyCommand.Path` instead of `$PSScriptRoot`
- **Severity:** low
- **Category:** structure
- **Location:** scripts/disk_usage_analyzer.ps1:40
- **Current:**
  ```powershell
  $ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
  ```
- **Recommended:**
  ```powershell
  $ScriptRoot = $PSScriptRoot
  ```
- **Risk if changed:** Low. `$PSScriptRoot` is the canonical PS 3.0+ automatic variable for "directory of the running script." `$MyInvocation.MyCommand.Path` returns `$null` when the script is dot-sourced, so the current form is also slightly more fragile. C10 will eventually replace this whole block with `Import-SouliTEKCommon`, but until then this one-line fix is free.
- **Target phase:** P4 (fold into the C10 sweep)

### F6 — Infinite menu loop with no non-interactive exit + blocking `Read-Host` prompts
- **Severity:** low
- **Category:** structure (UX / RMM safety)
- **Location:** scripts/disk_usage_analyzer.ps1:746 (`do { ... } while ($choice -ne "0")`), plus `Read-Host` calls at lines 124, 200, 211, 241, 249, 262, 292, 550, 564, 594, 659, 720, 764.
- **Local notes:** The script is interactive-only by design — the only graceful exit is menu option `[0]`, which calls `Show-ExitMessage` and `break`s (lines 779–781). Under SYSTEM-context RMM execution (flagged in user's CLAUDE.md as a deployment scenario), every one of the 13 `Read-Host` prompts will hang the worker process. There is no `[Environment]::UserInteractive` gate and no `-NonInteractive` switch. Pairs naturally with F4 — adding a script-level `param([string]$Path, [double]$MinSizeGB, [string]$OutputFormat, [switch]$NonInteractive)` would let callers drive a one-shot scan→export pipeline without the menu. Defer to P4 unless an actual RMM hang report comes in; this is the same recommendation made against `Wait-SouliTEKKeyPress` (F10 of `01-modules-SouliTEK-Common.md`) and against `Read-Host` in `scripts-driver_integrity_scan.md` F6.
- **Target phase:** P4

### F7 — Hard-coded Desktop output path with no override
- **Severity:** info
- **Category:** structure
- **Location:** scripts/disk_usage_analyzer.ps1:54 (`$Script:OutputFolder = Join-Path $env:USERPROFILE "Desktop"`).
- **Local notes:** The TXT/CSV/HTML export target is hard-coded to the current user's Desktop. This breaks under SYSTEM context (`$env:USERPROFILE` resolves to `C:\Windows\System32\config\systemprofile` and the Desktop folder may not exist) and offers no way to redirect the export. Low priority because the menu-driven design assumes interactive use, but a `-OutputDirectory` parameter on the script's `param()` block (when F4/F6 add it) would clean this up — and `Export-TextReport`, `Export-CSVReport`, `Export-HTMLReport` already accept `$Folders`/`$Timestamp` so they're one parameter away from accepting an `$OutputFolder` override. Note: there is also a `Start-Process $filePath` call at the end of every exporter (lines 347, 377, 518) — these will fail under SYSTEM context because there is no associated shell. Same fix applies (gate behind `[Environment]::UserInteractive`).
- **Target phase:** P4

### F8 — `($totalSize / $Folders.Count)` divide-by-zero in HTML report when no folders found
- **Severity:** low
- **Category:** correctness
- **Location:** scripts/disk_usage_analyzer.ps1:433
- **Current:**
  ```powershell
  ...Average Folder Size:... $(Format-FileSize ($totalSize / $Folders.Count))...
  ```
- **Local notes:** `Export-HTMLReport` is called from `Export-DiskUsageReport`, which has a `$Script:FolderData.Count -eq 0` guard at line 247 — so in normal flow this is unreachable. But the guard is in the *caller* (`Export-DiskUsageReport`), not in `Export-HTMLReport` itself, and the export functions are also called directly from `Export-DiskUsageReport`'s "All Formats" branch (line 279) which has the same caller-side guard. If `Export-HTMLReport` is ever called from a future code path that bypasses the menu, `$Folders.Count` could be `0` and the expression at line 433 would throw `RuntimeException: Attempted to divide by zero`. Recommend defensive guard inside the function: `$avgSize = if ($Folders.Count -gt 0) { $totalSize / $Folders.Count } else { 0 }`. Pairs with the F4 `[CmdletBinding()]` add — once that ships, `[ValidateScript({ $_.Count -gt 0 })]` on the `$Folders` parameter handles this cleanly.
- **Target phase:** P4

### F9 — `Format-FileSize` is a thin wrapper that adds no value
- **Severity:** info
- **Category:** structure (note only — no urgent change)
- **Location:** scripts/disk_usage_analyzer.ps1:63–67
- **Current:**
  ```powershell
  function Format-FileSize {
      param([long]$SizeInBytes)
      return Format-SouliTEKFileSize -SizeInBytes $SizeInBytes
  }
  ```
- **Local notes:** The function exists purely to alias `Format-SouliTEKFileSize` from the common module. It's called 11 times in this script (lines 160, 188, 316, 328, 345, 365, 375, 432, 448, 491, 516). The aliasing is harmless but adds a layer of indirection — pure pass-through wrappers are an anti-pattern that the C10 cleanup should address by either (a) inlining all 11 callers to use `Format-SouliTEKFileSize` directly, or (b) renaming the wrapper to make its purpose clear. Recommend (a) during the C10 sweep — it's a single regex replace across the file.
- **Target phase:** P4 (fold into the C10 sweep)

## Out-of-scope notes
- Banner block (lines 1–32, 32 lines of `# === / Coded by / IMPORTANT DISCLAIMER`) matches C11 cross-cutting cleanup; covered there.
- The HTML report template (lines 390–511, three concatenated here-strings) is clean and well-styled; the CSS uses sensible color thresholds (`size-large` >=10 GB, `size-medium` >=5 GB, `size-small` else) and the chart bar is a percent-width div sized off the top-10 max. No injection risk because the only interpolated values are `$env:COMPUTERNAME`, `$env:USERNAME`, `$folder.Path`, and numeric sizes — none of which are attacker-controlled in the threat model. Note: `$folder.Path` is the only field that could carry HTML metacharacters from a hostile filename (e.g. a `script` tag injected in a folder name), but PowerShell's filesystem provider doesn't allow `<` or `>` characters in NTFS paths, so this is moot. No change needed.
- The `Get-FolderStats` "single-scan optimization" note at lines 70–76 is correct — combining size + count into one `Get-ChildItem -Recurse` is genuinely faster than two passes. Good comment.
- The `[int]$choice` coercions in `Select-ScanPath` at lines 555, 562 will throw a `RuntimeException` on non-numeric input (e.g. user types `q`); the script handles this by falling through to the `else` branch (line 578) which prints "Invalid choice." Acceptable, but a `[int]::TryParse` check at line 552 would be cleaner. Not worth a finding.
- `Show-SouliTEKHeader`, `Show-ScriptBanner`, `Format-SouliTEKFileSize`, `Show-SouliTEKExitMessage`, and `Test-SouliTEKAdministrator` are all consumed from the common module — good module integration, no per-script duplication. The C10 import boilerplate (lines 39–47) is the only structural duplication.
- `Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Used -gt 0 }` at line 528 is a clean way to enumerate mounted local drives; it correctly excludes empty/PSDrive-only mounts. No change needed.
- The script does not call `Get-WmiObject` anywhere — no C3 finding applies.
- The script does not perform any destructive mutations (no `Remove-Item`, no `Stop-Service`, no registry writes) — only reads filesystem metadata and writes report files to Desktop. No C5 `SupportsShouldProcess` finding applies.
