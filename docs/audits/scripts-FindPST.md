# Audit — scripts/FindPST.ps1

## Inventory
| Item | Value |
|---|---|
| Path           | scripts/FindPST.ps1 |
| LOC            | 788 |
| Functions      | 20 |
| `#Requires`    | none (no `#Requires` statements; relies on `Confirm-Administrator` runtime check at line 780) |
| Admin-required | yes (enforced at runtime via `Confirm-Administrator` line 157–173, which calls `Test-SouliTEKAdministrator` and `exit 1`s if not elevated; `Set-ScheduledTask` registers a task under `SYSTEM` with `RunLevel Highest` at line 651) |
| Last touched   | 8675720 — 2026-04-17 |
| Modernization grade | B |

## Summary

A menu-driven PST-discovery tool with a non-interactive `-AutoScan` mode designed for scheduled-task invocation. Functionality is small and well-bounded: enumerate `*.pst` files via `Get-ChildItem -Recurse` over a list of paths, sum sizes, export CSV/HTML/XLSX reports, persist a "last scan" cache in `%TEMP%\PSTFinder`, and optionally register a daily scheduled task that re-invokes the script with `-AutoScan`. The grade B reflects that the script already does several things correctly — script-level `[CmdletBinding()]` + `param([switch]$AutoScan)` (lines 43–47), single-purpose helpers (`Get-PSTFiles`, `Export-PSTReport`, `Save-Summary`), a properly gated non-interactive entry point (lines 770–773), and use of `$env:TEMP\PSTFinder` for cache instead of Desktop. The main issues are stylistic: 95 raw `Write-Host` calls coexist with `Write-Ui` calls, producing a two-way output-style mix (F1, C1). The `-ErrorAction SilentlyContinue` triage is small — 3 occurrences, all tag **A** (one scope-wide preference change in `Get-PSTFiles` at line 101 plus two denied-folder probes at lines 106 and 108), all legitimate for filesystem walks over user profiles where `WindowsApps`, `$Recycle.Bin`, junctions, and other-user profiles will deny enumeration. The C13 candidate is the sequential drive loop in `Invoke-DeepScan` at lines 293–297 (and the identical loop in `Invoke-AutoScan` at lines 753–756): each drive's recursive PST scan is independent and benefits from runspace parallelism once `Invoke-SouliTEKParallel` exists. Local concerns: the `Set-ScheduledTask` function (line 627) is *destructive structural change* (registers a SYSTEM-context task with `RunLevel Highest`) and therefore qualifies for C5 — needs `[CmdletBinding(SupportsShouldProcess, ConfirmImpact='High')]` + `ShouldProcess` gate; `Export-ToHTML` interpolates filesystem paths into HTML without encoding (line 448 — moot in practice because NTFS bars `<`/`>` in paths, but worth a noted defense); no `[CmdletBinding()]` on any of the 20 internal functions; `Split-Path -Parent $MyInvocation.MyCommand.Path` instead of `$PSScriptRoot` at line 63; the unconditional `Read-Host` and `$Host.UI.RawUI.ReadKey` gates make the interactive menu RMM-unsafe (but the `-AutoScan` path already side-steps this correctly). The C11 banner block occupies lines 1–41. Recommended phase entry order: P1 (C1), P2 (C4 triage — small), P3 (F4 — `Set-ScheduledTask` ShouldProcess gate).

## Findings

### F1 — Raw `Write-Host` calls not migrated to `Write-Ui` (see C1)
- **Severity:** med
- **Category:** output-style
- **Location:** scripts/FindPST.ps1 — 95 raw `Write-Host` occurrences (sample lines: 161, 167, 195, 198, 210, 257, 308, 343, 394, 476, 542, 576, 609, 657, 666, 675, 687, 709, 711, 722).
- **Reference:** [C1](00-cross-cutting.md#c1--raw-write-host-calls-not-migrated-to-write-uiwrite-status)
- **Current (representative pattern — banner block at lines 257–262):**
  ```powershell
  Write-Host "========================================" -ForegroundColor Green
  Write-Ui -Message "  SUCCESS!" -Level "OK"
  Write-Host "========================================" -ForegroundColor Green
  Write-Host ""
  Write-Ui -Message "  $summary" -Level "STEP"
  ```
- **Recommended:**
  ```powershell
  Write-Ui -Message "SUCCESS!" -Level "OK"
  Write-Ui -Message $summary -Level "STEP"
  ```
- **Risk if changed:** Low — message text preserved verbatim; the `[OK]` / `[STEP]` brackets emitted by `Write-Ui` replace the manual `===` separator-bar formatting. Per-category fix patterns are enumerated below in Local notes.
- **Local notes:** Three categories of raw `Write-Host`:
  1. **Blank-line / spacer calls** — bare `Write-Host ""` used as vertical spacing (lines 161, 166, 168, 195, 197, 199, 201, 209, 241, 243, 260, 262, 269, 284, 286, 307, 311, 313, 317, 321, 339, 344, 354, 372, 393, 397, 401, 469, 475, 479, 483, 535, 541, 545, 549, 569, 575, 579, 588, 590, 595, 597, 612, 619, 632, 636, 644, 656, 660, 665, 669, 674, 688, 691, 694, 697, 700, 703, 708, 712, 715, 718, 721, 723, 734, 736, 738 — ~67 occurrences). These should remain as-is or migrate to a `Write-Ui -Spacer` / `Show-Section` helper if one is added in P4 — they are not C1 violations per the "visual separator helpers" exception, but they are noisy.
  2. **Visual separator `===` bars** — `Write-Host "========================================" -ForegroundColor Green|Cyan|Red|DarkGray` (lines 167, 198, 210, 257, 259, 308, 310, 373, 394, 396, 476, 478, 542, 544, 576, 578, 609, 611, 657, 659, 666, 668, 675, 709, 722) and the `----------------------------------------` dash separators (lines 343, 687, 711). These are visual-separator helpers per the C1 exception; recommendation is to consolidate via a `Show-Section` helper in P4 but they are not strict violations.
  3. **Inline-marker prefixes inside `Write-Ui`** — `Write-Ui -Message "  [1] Quick Scan ..." -Level "WARN"` (lines 202–208, 367–371, 689, 692, 695, 698, 701). These bracketed numerals are *menu-item identifiers*, not status markers, so they should remain in the message text — but the surrounding `Write-Ui -Level "WARN"` / `-Level "ERROR"` choices then double-mark with `[WARN]`/`[ERROR]` brackets on top of `[1]`/`[0]`. Recommend changing these to `-Level "INFO"` for menu items where the bracket is a menu identifier, and reserving `-Level "WARN"`/`-Level "ERROR"` for true status output. Same anti-pattern as F2 of `01-modules-SouliTEK-Common.md` and the inline-marker review in `scripts-disk_usage_analyzer.md` F1.
- **Local notes (cont.) — no legacy API callers:** Unlike `driver_integrity_scan.ps1` or `disk_usage_analyzer.ps1`, this script does NOT call `Write-SouliTEKResult` / `Write-SouliTEKInfo` / etc. — it is already C2-clean. Useful baseline for the eventual C2 dead-API deletion step.
- **Target phase:** P1

### F2 — `-ErrorAction SilentlyContinue` triage (see C4)
- **Severity:** low
- **Category:** error-handling
- **Location:** scripts/FindPST.ps1 — 3 occurrences (one is a function-scope preference change rather than a parameter)
- **Reference:** [C4](00-cross-cutting.md#c4----erroraction-silentlycontinue-swallowing-failures)
- **Triage:**
  - Line 101: tag **A** (with caveat) — `$ErrorActionPreference = 'SilentlyContinue'` at the top of `Get-PSTFiles`. This is *function-scope* (PowerShell scope rules — assignment to a script-local variable inside a function only affects that function's runspace), so the intent is "treat all errors inside this function as non-fatal during the recursive enumeration." Functionally equivalent to the per-call `-ErrorAction SilentlyContinue` on lines 106 and 108 (which are now redundant given the preference change). The caveat: the broader preference change *also* silences any future failure mode inside the function (e.g. `Get-ChildItem -Path $path` failing because `$path` is malformed, not because of access-denial). Recommend collapsing to *just* the per-call `-ErrorAction SilentlyContinue` on lines 106 and 108 and dropping the function-wide preference at line 101 — the narrower scope makes the intent ("skip denied folders, surface everything else") explicit. Add `# safe: denied-folder probe` comment.
  - Line 106: tag **A** — `Get-ChildItem -Path $path -Filter "*.pst" -File -Recurse -ErrorAction SilentlyContinue`. Recursive file enumeration over arbitrary directories will hit folders the current user cannot read (`System Volume Information`, `$Recycle.Bin`, `WindowsApps`, junctions/reparse points, other-user profiles). The denied-folder skip is the *intended* behavior. Legitimate. Add `# safe: denied-folder probe` comment in P2.
  - Line 108: tag **A** — same as line 106 but for the non-recursive branch. Legitimate. Add `# safe: denied-folder probe` comment.
- **Target phase:** P2

### F3 — Sequential drive-scan loop is the C13 parallelism target
- **Severity:** low (perf)
- **Category:** perf
- **Location:** scripts/FindPST.ps1:293–297 in `Invoke-DeepScan` (and the identical loop at lines 753–756 in `Invoke-AutoScan`).
- **Reference:** [C13](00-cross-cutting.md#c13--sequential-foreach-over-large-datasets-where-parallelism-would-help)
- **Current:**
  ```powershell
  $drives = Get-Volume | Where-Object { $_.DriveLetter -and $_.DriveType -eq 'Fixed' } |
            Select-Object -ExpandProperty DriveLetter

  $allFiles = @()
  foreach ($drive in $drives) {
      $drivePath = "$($drive):\"
      Write-Ui -Message "  Scanning drive $drivePath..." -Level "INFO"
      $allFiles += Get-PSTFiles -Paths @($drivePath) -Recurse
  }
  ```
- **Recommended (once `Invoke-SouliTEKParallel` lands in P4):**
  ```powershell
  $allFiles = Invoke-SouliTEKParallel `
      -InputObject $drives `
      -ScriptBlock {
          param($drive)
          $drivePath = "$($drive):\"
          Get-ChildItem -Path $drivePath -Filter "*.pst" -File -Recurse -ErrorAction SilentlyContinue
      } `
      -ThrottleLimit 4
  ```
- **Why this loop:** Each drive's recursive `Get-ChildItem -Recurse -Filter "*.pst"` walk is fully independent — no shared state, no ordering dependency, results aggregate via concatenation at the end. Most workstations have 1–2 fixed drives so the speedup ceiling is small (2x best case), but laptops with NVMe + SATA SSD pairs and servers with multi-disk configurations will benefit. The progress line at line 295 (`Write-Ui -Message "  Scanning drive $drivePath..."`) would need to migrate to a thread-safe callback channel (or be dropped — the per-drive granularity is coarse enough that `Write-Ui` from inside the runspace at start/end works fine). `Invoke-DeepScan`'s `$allFiles += Get-PSTFiles ...` accumulation pattern (line 296) is O(n^2) due to PowerShell array-reallocation on `+=`; the parallel rewrite would naturally collect into a list. Note: `Get-PSTFiles` itself ALSO has an inner `foreach ($path in $Paths)` loop at line 104 that could be parallelized for the `Invoke-QuickScan` case (3 path patterns at lines 245–249), but the gain there is negligible since the patterns are tiny and overlap a lot — not worth a separate parallelism candidate.
- **Risk if changed:** Medium. Concurrent filesystem walks on Windows can occasionally surface different exceptions than serial walks (mostly around reparse points and junctions, which today get silently swallowed by the F2 `-ErrorAction SilentlyContinue`). The `Invoke-SouliTEKParallel` helper must include max-thread cap + cancellation token (per C13 in 00-cross-cutting). **Do not refactor until the module helper exists** (P4 dependency).
- **Target phase:** P4

### F4 — `Set-ScheduledTask` is destructive but lacks `SupportsShouldProcess` (see C5)
- **Severity:** med
- **Category:** safety
- **Location:** scripts/FindPST.ps1:627–677 (`Set-ScheduledTask` function), specifically the `Register-ScheduledTask` call at line 654.
- **Reference:** [C5](00-cross-cutting.md#c5--destructive-scripts-lack-cmdletbindingsupportsshouldprocess--whatifconfirm)
- **Current:**
  ```powershell
  function Set-ScheduledTask {
      # ... menu prompts ...
      $confirm = Read-Host "Do you want to create this task? (Y/N)"
      if ($confirm -ne 'Y' -and $confirm -ne 'y') { return }
      # ...
      $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
      Register-ScheduledTask -TaskName "SouliTEK - PST Daily Scan" -Action $action `
          -Trigger $trigger -Principal $principal -Settings $settings -Force | Out-Null
  }
  ```
- **Recommended:**
  ```powershell
  function Set-ScheduledTask {
      [CmdletBinding(SupportsShouldProcess, ConfirmImpact='High')]
      param()
      # ... menu prompts ...
      if (-not $PSCmdlet.ShouldProcess('Task Scheduler', 'Register SouliTEK - PST Daily Scan (SYSTEM, RunLevel Highest)')) {
          return
      }
      # ...
      Register-ScheduledTask -TaskName "SouliTEK - PST Daily Scan" -Action $action `
          -Trigger $trigger -Principal $principal -Settings $settings -Force | Out-Null
  }
  ```
- **Local notes:** This function registers a daily scheduled task that runs the script as `SYSTEM` with `RunLevel Highest` (line 651). That is a high-impact persistent change to the machine — exactly the case C5 is designed to gate. The current `Read-Host "Do you want to create this task?"` prompt is *not* a substitute for `ShouldProcess`: it doesn't surface a `-WhatIf` preview, doesn't honor `$ConfirmPreference`, and disappears entirely when the function is called from a non-interactive context. The task name is hard-coded (`"SouliTEK - PST Daily Scan"`) and `Register-ScheduledTask -Force` will silently overwrite an existing task with the same name — also a `ShouldProcess` case. The script's overall pattern of using `[CmdletBinding()]` at script-level (line 43) is exactly the foundation needed; `Set-ScheduledTask` just needs to opt into `SupportsShouldProcess` of its own. Pairs with `essential_tweaks.ps1` and `win11_debloat.ps1` in the C5 family.
- **Target phase:** P3

### F5 — No `[CmdletBinding()]` on any internal function
- **Severity:** low
- **Category:** structure
- **Location:** scripts/FindPST.ps1 — every one of the 20 internal functions (`Test-Administrator` line 79, `Show-Header` line 86, `Get-PSTFiles` line 92, `Export-PSTReport` line 115, `Save-Summary` line 139, `Confirm-Administrator` line 157, `Show-Disclaimer` line 180, `Show-MainMenu` line 188, `Invoke-QuickScan` line 234, `Invoke-DeepScan` line 278, `Show-Summary` line 330, `Show-PowerShellMode` line 363, `Export-ToHTML` line 391, `Export-ToXLSX` line 473, `Show-PerUserStats` line 539, `Invoke-CustomPathScan` line 573, `Set-ScheduledTask` line 627, `Show-Help` line 683, `Show-Exit` line 732, `Invoke-AutoScan` line 745).
- **Local notes:** Unlike `driver_integrity_scan.ps1` and `disk_usage_analyzer.ps1`, this script *does* have `[CmdletBinding()]` at the script level (line 43) and a real `param([switch]$AutoScan)` block — the non-interactive entry point is genuine. The internal functions then drop the convention. `Get-PSTFiles` (line 92), `Export-PSTReport` (line 115), and `Save-Summary` (line 139) all have `[Parameter(Mandatory=$true)]` attribute usage on their parameters, which would compose naturally with `[CmdletBinding()]` and give them `-Verbose` / `-ErrorAction` support for free. Pairs with F4 — once `Set-ScheduledTask` gains `[CmdletBinding(SupportsShouldProcess)]`, the precedent for `[CmdletBinding()]` on the other helpers is established.
- **Target phase:** P4

### F6 — `Split-Path -Parent $MyInvocation.MyCommand.Path` instead of `$PSScriptRoot`
- **Severity:** low
- **Category:** structure
- **Location:** scripts/FindPST.ps1:63
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

### F7 — Interactive menu has blocking `Read-Host` / `ReadKey` gates (RMM-unsafe)
- **Severity:** info
- **Category:** structure (UX / RMM safety)
- **Location:** scripts/FindPST.ps1:189 (`do { ... } while ($true)` in `Show-MainMenu`), plus `Read-Host` calls at lines 212, 375, 402, 470, 484, 536, 550, 570, 581, 591, 620, 638, 676 and `$Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')` calls at lines 170, 271, 283, 323, 356, 725.
- **Local notes:** The script has a *correct* non-interactive escape hatch — the `if ($AutoScan) { Invoke-AutoScan; exit 0 }` block at lines 770–773 returns before the menu is ever shown, and `Invoke-AutoScan` (line 745) contains zero prompts. This is the right pattern and means F7 is mostly informational for this script. The only residual concern is that `Confirm-Administrator` (line 157) is called at line 780, *after* the AutoScan block returns, so the elevation check correctly applies only to the interactive path. *However*, line 170's `$Host.UI.RawUI.ReadKey` inside `Confirm-Administrator` would still hang under a non-elevated SYSTEM call to the script if Task Scheduler somehow demoted the principal — extremely unlikely with `RunLevel Highest` but theoretically possible. Low priority unless an actual RMM hang report comes in. Same recommendation as `Wait-SouliTEKKeyPress` (F10 of `01-modules-SouliTEK-Common.md`) and `Read-Host` in `scripts-driver_integrity_scan.md` F6.
- **Target phase:** P4

### F8 — `Export-ToHTML` interpolates filesystem paths into HTML without encoding
- **Severity:** info
- **Category:** correctness (note only — no urgent change)
- **Location:** scripts/FindPST.ps1:445–454 (the `foreach ($row in $data)` HTML row builder).
- **Current:**
  ```powershell
  foreach ($row in $data) {
      $html += @"
          <tr>
              <td>$($row.FullName)</td>
              <td>$($row.SizeMB)</td>
              <td>$($row.SizeGB)</td>
              <td>$($row.LastWriteTime)</td>
          </tr>
  "@
  }
  ```
- **Local notes:** `$row.FullName` is the only field that could carry HTML metacharacters from a hostile filename — but PowerShell's filesystem provider doesn't allow `<`, `>`, `"`, `|`, `?`, `*` in NTFS paths, so the only metacharacter that *can* appear in `$row.FullName` is `&` (Windows allows `&` in filenames). A path like `C:\Users\bob\foo&bar.pst` would render as `foo&bar.pst` in the HTML — not strictly valid HTML but browsers tolerate it. The `Summary` block at lines 430–435 also interpolates `$($data.Count)` and `$totalGB`, both numeric and safe. **Recommendation:** add a simple `[System.Web.HttpUtility]::HtmlEncode($row.FullName)` (or a `Format-HtmlEscape` helper in the common module) for defense-in-depth — but this is a "good hygiene" call, not a "live vulnerability." Pairs with the C10 / module-helper effort.
- **Target phase:** P4

### F9 — `Test-Administrator` is a thin alias wrapper with zero callers
- **Severity:** info
- **Category:** structure (note only — no urgent change)
- **Location:** scripts/FindPST.ps1:79
- **Current:**
  ```powershell
  function Test-Administrator { Test-SouliTEKAdministrator }
  ```
- **Local notes:** The function exists purely to alias the module helper under a shorter name, but it is never called in the file — every caller (`Confirm-Administrator` at line 158) calls `Test-SouliTEKAdministrator` directly. This is *dead wrapper code*. Same anti-pattern as `Format-FileSize` in `scripts-disk_usage_analyzer.md` F9, but worse because there's not even a call site. Recommend deletion during the C10 sweep — 1-line removal, zero callers to update.
- **Target phase:** P4 (fold into the C10 sweep)

## Out-of-scope notes
- Banner block (lines 1–41, the comment-based help block followed by the `[CmdletBinding()]` opening) matches C11 cross-cutting cleanup; covered there. Note that this is a `<#...#>` comment-based help block, not a `# ===` banner — slightly different shape from `driver_integrity_scan.ps1`/`disk_usage_analyzer.ps1`, but the C11 collapse-to-3-line-header recommendation still applies. The comment-based help with `.SYNOPSIS`/`.DESCRIPTION`/`.PARAMETER`/`.EXAMPLE` sections is actually *good* and should be preserved; only the marketing-style `IT Solutions for your business` / disclaimer paragraphs should collapse.
- The `Get-PSTFiles` helper at lines 92–113 is *clean*: takes a typed `[string[]]$Paths` array, a `[switch]$Recurse`, sums results, returns the array. Could be promoted to a module helper if any other script needs to enumerate files by extension — but the abstraction is small enough that staying local is fine.
- The non-interactive `-AutoScan` entry path (lines 770–773) calling `Invoke-AutoScan` (line 745) is *correctly designed*: no prompts, `exit 0` at the end. This is the right pattern for scheduled-task invocation.
- **But** the `Invoke-AutoScan` Desktop write at line 747 (`Join-Path $env:USERPROFILE "Desktop\PST_AutoScan_$timestamp.csv"`) WILL break under SYSTEM context because `$env:USERPROFILE` resolves to `C:\Windows\System32\config\systemprofile` and that directory has no `Desktop` subfolder by default. The `Set-ScheduledTask` function (F4) registers the task as `SYSTEM`, so this is a *real* bug — but the symptom is silent (the task runs, fails to write the file, exits 0). Worth a note in P3 alongside the F4 ShouldProcess gate: the autoscan output path should be `$Script:WorkDir` (which is `$env:TEMP\PSTFinder` — under SYSTEM that resolves to `C:\Windows\Temp\PSTFinder`, which is writable) or `$env:ProgramData\SouliTEK\Reports`. The interactive Desktop writes in `Export-ToHTML` (line 407) and `Export-ToXLSX` (line 490) are fine because they only run from the interactive menu.
- The `Export-ToXLSX` function (line 473) uses `New-Object -ComObject Excel.Application` and properly tears down the COM object via `[System.Runtime.Interopservices.Marshal]::ReleaseComObject` (line 526). The teardown is correct as far as it goes, but it does *not* release `$workbook` or `$worksheet` and does not call `[GC]::Collect()` — so under repeated XLSX exports the Excel process can linger in Task Manager. Low priority because the export is interactive-only and one-shot. Not worth a separate finding.
- The `Show-PerUserStats` regex `'^C:\\Users\\([^\\]+)'` at line 557 only matches `C:\Users\...` paths; PSTs on non-`C:` drives or in non-default user-profile locations (e.g. `D:\Profiles\bob\...`) all fall into the `"Other"` bucket. Acceptable as a simple heuristic but worth a code comment explaining the limitation.
- The script does not call `Get-WmiObject` anywhere — no C3 finding applies. (Uses `Get-Volume` at lines 289 and 749, which is the modern `Storage` module cmdlet — though note `Get-Volume` is *not* in PowerShell 5.1's default module set on Windows Server Core and may not exist there. Worth a `try { Get-Volume ... } catch { Get-CimInstance Win32_LogicalDisk ... }` fallback in P4 if Server Core support matters.)
- The script does not call any C2 dead-API function (`Write-SouliTEKResult`/`Write-SouliTEKInfo`/`Write-SouliTEKSuccess`/`Write-SouliTEKWarning`/`Write-SouliTEKError`) — already C2-clean. This is rarer than expected in the audited scripts and worth noting as a baseline.
- The trailing blank lines at the end of the file (lines 787–788) are harmless but could be trimmed in any pass that touches the file.
