# Audit — scripts/printer_spooler_fix.ps1

## Inventory
| Item | Value |
|---|---|
| Path           | scripts/printer_spooler_fix.ps1 |
| LOC            | 746 |
| Functions      | 16 |
| `#Requires`    | none (no `#Requires` declaration at all, despite the script needing admin) |
| Admin-required | yes (stops/starts the `Spooler` service, deletes `%SystemRoot%\System32\spool\PRINTERS\*.*`, registers a SYSTEM-context scheduled task; runtime check via `Test-SouliTEKAdministrator` at line 712 with custom `Show-AdminError` exit at line 60) |
| Last touched   | 8675720 — 2026-04-17 |
| Modernization grade | D |

## Summary

A menu-driven Print Spooler triage tool with six modes: a one-shot "basic fix" (stop spooler then wipe spool folder then start spooler), a continuous monitor loop, a read-only status view, a "PowerShell mode" sub-menu that adds Desktop log files, a scheduled-task installer that registers a daily 3 AM SYSTEM job, and a built-in help screen. The script also accepts `-AutoFixSilent` for non-interactive scheduled-task execution. **This script is materially destructive**: across `Invoke-SpoolerFix`, `Invoke-SpoolerFixWithLog`, and `Invoke-ScheduledTaskSetup` it (a) stops the Print Spooler service four times, including a `-Force` fallback that drops in-flight jobs (lines 90, 95, 159, 162); (b) deletes the contents of the spool directory twice, irreversibly destroying any queued print jobs (lines 113, 176); (c) registers a `Register-ScheduledTask -Principal SYSTEM ... -Force` that overwrites any existing same-named task (line 595). None of these mutations is gated by `ShouldProcess`, no `-WhatIf` is offered, and there is no `[CmdletBinding()]` anywhere in the script. **This brings the C5 affected-files list from 6 to 7 — see F3.** Beyond the destructive-mutation gap, the dominant issue is the volume of raw `Write-Host`: **243 occurrences, the highest count in the repo** (verified). Of those, ~73 are pure blank-line spacers (`Write-Host ""`), but the remainder are message lines that should be `Write-Ui` (the ASCII banners inside every mode function, the `[1/5]`/`[2/5]` step headers, the help screen, the disclaimer wrappers). The `Write-Ui` calls that do exist (25 occurrences) all double-mark with inline `[OK]`/`[ERROR]`/`[WARNING]`/`[INFO]` prefixes inside the message string (lines 91, 94, 96, 99, 102, 105, 114, 116, 119, 124, 129, 132, 140, 143, 366, 368, 379, 381, 383, 392, 402, 443, 551, 739), same anti-pattern as F2 of 01-modules-SouliTEK-Common.md. The 7 `-ErrorAction SilentlyContinue` occurrences are all probe/optional-read patterns and triage cleanly to tag **A**. Secondary concerns: 21 `$Host.UI.RawUI.ForegroundColor = "Color"` mutations scattered across mode functions (a pre-`Write-Ui` "set the console color, then `Write-Host`" pattern that leaks state between modes and breaks redirection); no `[CmdletBinding()]` anywhere; the C10 import block and C11 banner are both present. Recommended phase entry order: **P3 (C5 — gate mutations with `ShouldProcess`)**, then P1 (C1), then P2 (C4 triage).

## Findings

### F1 — Raw `Write-Host` saturates every output path (see C1)
- **Severity:** med
- **Category:** output-style
- **Location:** scripts/printer_spooler_fix.ps1 — 243 raw `Write-Host` occurrences (verified — task plan predicted 243; matches). Highest count in the repo.
- **Reference:** [C1](00-cross-cutting.md#c1--raw-write-host-calls-not-migrated-to-write-uiwrite-status)
- **Current (representative pattern — `Show-AdminError` block, lines 64–76):**
  ```powershell
  Write-Host ""
  Write-Host "========================================"
  Write-Host "  ERROR: Administrator Required"
  Write-Host "========================================"
  Write-Host ""
  Write-Host "This script must run as Administrator."
  ```
- **Recommended:**
  ```powershell
  Write-Ui -Message "" -Level "INFO"
  Show-Section -Title "ERROR: Administrator Required"
  Write-Ui -Message "This script must run as Administrator." -Level "ERROR"
  ```
- **Risk if changed:** Low — message text preserved verbatim; the `[LEVEL]` bracket emitted by `Write-Ui` replaces the manual color/divider formatting. Per-category fix patterns are enumerated below in Local notes.
- **Local notes — three categories of raw `Write-Host`:**
  1. **Blank-line spacers** (~73 occurrences) — bare `Write-Host ""` used as vertical spacing. Same exception as F2 of driver_integrity_scan.md: keep as-is for now or migrate to a future `Write-Ui -Spacer` / `Show-Section` helper in P4. Not strict C1 violations.
  2. **ASCII-divider lines and section headers** — long runs of `Write-Host "========================================"` / `Write-Host "  TITLE"` blocks at the top of every mode function (e.g. `Show-AdminError` 65–76, `Show-MainMenu` 209, `Invoke-BasicFixMode` 232–248, `Invoke-AdvancedMonitorMode` 270–288, `Invoke-StatusCheckMode` 354–356, `Show-PowerShellModeMenu` 415–426, `Invoke-PSFixWithLog` 454–457, `Invoke-PSMonitorLog` 487–490, `Invoke-PSViewLogs` 531–536, `Invoke-ScheduledTaskSetup` 567–578, `Show-Help` 634–637 and 666–668 and 682). These should collapse to a single `Show-Section -Title "BASIC FIX MODE"` helper call (~3 lines per banner becomes 1 line) — by far the highest line-count win in this file.
  3. **Plain message lines** — e.g. `Write-Host "Your printer should now work normally."` (259), `Write-Host "Try printing a test page."` (260), every `[1/5]`/`[2/5]`/.../`[5/5]` step header (83, 109, 122, 126, 137), the `[$timestamp] Check #$checkCount` line (298), the `[WARNING]`/`[ACTION]`/`[OK]` status prints in `Invoke-AdvancedMonitorMode` (305, 306, 317, 318, 326, 332, 336), and the entire `Show-Help` Q-and-A body (640–680). All are clear C1 violations: should be `Write-Ui -Message "..." -Level "STEP|INFO|WARN|OK"`.
- **Local notes — companion anti-pattern, `$Host.UI.RawUI.ForegroundColor`:** 21 occurrences (lines 61, 62, 131, 206, 229, 253, 267, 294, 304, 309, 316, 325, 329, 331, 335, 351, 412, 564, 597, 613, 631) mutate console foreground/background color *globally* before each `Write-Host` block. This is the pre-`Write-Ui`-era pattern and is worse than inline `-ForegroundColor` because the color persists across function returns until the next mutation. When the C1 sweep migrates `Write-Host` to `Write-Ui` these RawUI-color mutations become dead code and should be deleted, not preserved. The single inline `-ForegroundColor Cyan` at line 209 likewise dies with the C1 sweep.
- **Local notes — double-marked `Write-Ui` calls:** All 25 existing `Write-Ui` invocations embed inline `[OK]`/`[ERROR]`/`[WARNING]`/`[INFO]` prefixes inside the message string (e.g. line 91 `Write-Ui -Message "      [OK] Stopped gracefully" -Level "OK"`). Same anti-pattern as F2 of 01-modules-SouliTEK-Common.md — strip the inline markers when the C1 sweep lands so the `[LEVEL]` bracket emitted by `Write-Ui` is the only marker. Also note line 99 has the wrong level/marker pairing (`"      [INFO] Already stopped" -Level "WARN"` — message says INFO, level is WARN). Pick one.
- **Local notes — no legacy `Write-SouliTEK*` callers:** zero occurrences (verified). This script does not contribute to C2's caller set.
- **Target phase:** P1

### F2 — `-ErrorAction SilentlyContinue` triage (see C4)
- **Severity:** med
- **Category:** error-handling
- **Location:** scripts/printer_spooler_fix.ps1 — 7 occurrences (verified — task plan predicted 7; matches)
- **Reference:** [C4](00-cross-cutting.md#c4----erroraction-silentlycontinue-swallowing-failures)
- **Triage:**
  - Line 85: tag **A** — `Get-Service -Name Spooler -ErrorAction SilentlyContinue` is followed by `if ($service)` to handle the "service not installed" edge case. Legitimate probe. Add `# safe: probe` comment in P2.
  - Line 156: tag **A** — same `Get-Service` probe pattern inside `Invoke-SpoolerFixWithLog`. Followed by `if ($service -and $service.Status -eq 'Running')`. Legitimate probe. Add `# safe: probe` comment.
  - Line 313: tag **A** — `Get-ChildItem -Path $spoolPath -File -ErrorAction SilentlyContinue | Measure-Object` is a folder-content count; piping through `Measure-Object` means an empty/missing folder cleanly returns `Count = 0`. Legitimate "may not exist or may be empty" read. Add `# safe: optional read` comment.
  - Line 322: tag **A** — identical pattern to line 313 (the second-check inside `Invoke-AdvancedMonitorMode`). Legitimate. Add `# safe: optional read`.
  - Line 375: tag **A** — identical pattern to line 313 inside `Invoke-StatusCheckMode`. Legitimate. Add `# safe: optional read`.
  - Line 399: tag **A** — `Get-EventLog -LogName System -Source 'Print' -Newest 5 -EntryType Error -ErrorAction SilentlyContinue` plus an enclosing `try/catch` (line 401). The `SilentlyContinue` here is belt-and-braces: the `try/catch` already covers terminating errors, and `Get-EventLog` returns nothing (not an error) when no matching events exist. Legitimate but redundant — the `SilentlyContinue` can be dropped since the `try/catch` already covers it. Add `# safe: belt-and-braces, redundant with try/catch` comment or remove the parameter outright. Note: `Get-EventLog` itself is a legacy cmdlet (deprecated, replaced by `Get-WinEvent`), not a strict C3 hit because it still exists in PS 7, but worth a follow-up in P4.
  - Line 538: tag **A** — `Get-ChildItem -Path "$env:USERPROFILE\Desktop\PrinterSpooler*.txt" -ErrorAction SilentlyContinue` for listing existing log files. Legitimate — Desktop may not contain any matching files. Add `# safe: optional read` comment.
- **Local notes:** All 7 occurrences are tag-A probe/optional-read patterns. No tag-B (silent-bug-swallow) or tag-C (must-halt) occurrences in this file — the destructive operations themselves all use `-ErrorAction Stop` (lines 90, 95, 113, 128, 159, 162, 176, 187) wrapped in `try/catch`, which is the right pattern.
- **Target phase:** P2

### F3 — Mutation sites needing `ShouldProcess` (see C5)
- **Severity:** high
- **Category:** safety
- **Location:** scripts/printer_spooler_fix.ps1 — three destructive operations across nine mutation sites
- **Reference:** [C5](00-cross-cutting.md#c5--destructive-scripts-lack-cmdletbindingsupportsshouldprocess--whatifconfirm)
- **Determination:** Yes — this script must be added to C5's affected-files list. The C5 entry currently lists 6 scripts (`essential_tweaks.ps1`, `win11_debloat.ps1`, `temp_removal_disk_cleanup.ps1`, `mcafee_removal_tool.ps1`, `network_configuration_tool.ps1`, `create_system_restore_point.ps1`); **add `printer_spooler_fix.ps1` as the 7th.** Justification: the script (a) stops a running OS service that may be actively printing, (b) irreversibly deletes the contents of the spool folder (silently dropping any queued jobs), and (c) registers a SYSTEM-context scheduled task that overwrites any existing same-named task and re-runs the script daily at 3 AM with `-AutoFixSilent`. Each of these is materially destructive in the same sense as `network_configuration_tool.ps1`'s adapter resets — reversible in principle (you can restart the spooler, you can delete the scheduled task), but with real-world data loss (lost print jobs) and persistent system change (the scheduled task survives reboots and the script is invoked by it).
- **Mutation sites:**
  - **Service stop — line 90:** `Stop-Service -Name Spooler -ErrorAction Stop` inside `Invoke-SpoolerFix`. Should be `if ($PSCmdlet.ShouldProcess('Spooler service', 'Stop service')) { Stop-Service ... }`.
  - **Service force-stop — line 95:** `Stop-Service -Name Spooler -Force -ErrorAction Stop` (fallback path when graceful stop fails). The `-Force` flag actively kills the service even with dependent services attached; this is the most destructive of the three service-stop sites. Same `ShouldProcess` gate.
  - **Spool folder wipe — line 113:** `Remove-Item -Path $spoolPath -Force -ErrorAction Stop` where `$spoolPath = "$env:SystemRoot\System32\spool\PRINTERS\*.*"`. This is the irreversible operation — any in-flight print job loses its `.SPL`/`.SHD` files. Should be `if ($PSCmdlet.ShouldProcess($spoolPath, 'Delete spool files')) { Remove-Item ... }`. `-WhatIf` should print the file list, not execute. C5 + safe-path note: consider also adding a `Test-SafeFilePath` check (the new helper added in commit a76b4e7) on `$spoolPath` to defend against `$env:SystemRoot` being subverted, though under admin this is mostly defence-in-depth.
  - **Service start — line 128:** `Start-Service -Name Spooler -ErrorAction Stop`. Less destructive (it's bringing a service back up), but still a service-state mutation. Same gate.
  - **Service stop — line 159:** identical to line 90 but inside `Invoke-SpoolerFixWithLog`. Same gate.
  - **Service force-stop — line 162:** identical to line 95 but inside `Invoke-SpoolerFixWithLog`. Same gate.
  - **Spool folder wipe — line 176:** identical to line 113 but inside `Invoke-SpoolerFixWithLog`. Same gate.
  - **Service start — line 187:** identical to line 128 but inside `Invoke-SpoolerFixWithLog`. Same gate.
  - **Scheduled-task registration — line 595:** `Register-ScheduledTask -TaskName "Auto Fix Printer Spooler" -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Force | Out-Null`. The `-Force` flag overwrites any existing task with the same name without prompting — this is destructive in the sense that an operator's existing same-named task would be replaced. `-Principal SYSTEM -RunLevel Highest` adds privilege-escalation surface (the script will run unattended as SYSTEM daily). Should be `if ($PSCmdlet.ShouldProcess('TaskScheduler: Auto Fix Printer Spooler', 'Register daily SYSTEM scheduled task')) { Register-ScheduledTask ... }`. Highest-impact ShouldProcess site in this file — under `-WhatIf` this should explicitly print "would register a SYSTEM-context scheduled task that runs `$PSCommandPath -AutoFixSilent` daily at 3 AM" so an operator can audit the install.
- **Current pattern (representative — line 113, the spool-folder wipe):**
  ```powershell
  $spoolPath = "$env:SystemRoot\System32\spool\PRINTERS\*.*"
  if (Test-Path $spoolPath) {
      try {
          Remove-Item -Path $spoolPath -Force -ErrorAction Stop
          Write-Ui -Message "      [OK] Queue cleared" -Level "OK"
      } catch {
          Write-Ui -Message "      [WARNING] Some files could not be deleted: $_" -Level "WARN"
      }
  }
  ```
- **Recommended:**
  ```powershell
  [CmdletBinding(SupportsShouldProcess, ConfirmImpact='High')]
  param(
      [switch]$AutoFixSilent
  )
  # ...
  $spoolPath = "$env:SystemRoot\System32\spool\PRINTERS\*.*"
  if (Test-Path $spoolPath) {
      if ($PSCmdlet.ShouldProcess($spoolPath, 'Delete queued print jobs')) {
          try {
              Remove-Item -Path $spoolPath -Force -ErrorAction Stop
              Write-Ui -Message "Queue cleared" -Level "OK"
          } catch {
              Write-Ui -Message "Some files could not be deleted: $_" -Level "WARN"
          }
      }
  }
  ```
- **Risk if changed:** Medium. `SupportsShouldProcess` on the script-level `param()` block plus per-mutation `$PSCmdlet.ShouldProcess(...)` calls is a well-understood pattern. The interactive menu mode will keep working (no `-WhatIf` passed means all `ShouldProcess` calls return `$true`). The `-AutoFixSilent` parameter path used by the scheduled task must NOT prompt — verify that `ConfirmImpact='High'` doesn't introduce a per-action prompt under SYSTEM context (the scheduled task runs with `$ConfirmPreference = 'None'` by default, so this should be safe, but test on a non-prod machine). The scheduled-task registration is the highest-leverage gate — `-WhatIf` for that operation alone would catch a wrong-name overwrite before it deploys.
- **Target phase:** P3

### F4 — No `[CmdletBinding()]` anywhere; script `param()` exists but lacks structure
- **Severity:** low (subsumed by F3's `[CmdletBinding(SupportsShouldProcess, ConfirmImpact='High')]` add)
- **Category:** structure
- **Location:** scripts/printer_spooler_fix.ps1:36 (script-level `param([switch]$AutoFixSilent)` with no `[CmdletBinding()]` attribute) and all 16 internal functions (`Show-AdminError` line 60, `Invoke-SpoolerFix` 82, `Invoke-SpoolerFixWithLog` 149, `Show-Disclaimer` 200, `Show-MainMenu` 205, `Invoke-BasicFixMode` 228, `Invoke-AdvancedMonitorMode` 266, `Invoke-StatusCheckMode` 350, `Show-PowerShellModeMenu` 411, `Invoke-PowerShellMode` 433, `Invoke-PSFixWithLog` 451, `Invoke-PSMonitorLog` 484, `Invoke-PSViewLogs` 528, `Invoke-ScheduledTaskSetup` 563, `Show-Help` 630, `Show-ExitMessage` 689).
- **Local notes:** The script has a working `param([switch]$AutoFixSilent)` block but no `[CmdletBinding()]` attribute, so the script doesn't accept `-Verbose`, `-ErrorAction`, etc. When F3 lands (`SupportsShouldProcess`), the `[CmdletBinding()]` add is mandatory anyway. Function-level `[CmdletBinding()]` adds are P4 territory and only worth doing on `Invoke-SpoolerFix` and `Invoke-SpoolerFixWithLog` (the two functions that callers — including any external caller — would benefit from passing `-WhatIf`/`-Verbose` to). The other 14 functions are interactive UI plumbing and don't benefit.
- **Target phase:** P3 (script-level, merged with F3) / P4 (function-level)

### F5 — No `#Requires -RunAsAdministrator`; admin check is runtime + custom error UI
- **Severity:** low
- **Category:** structure
- **Location:** scripts/printer_spooler_fix.ps1 — no `#Requires` declaration anywhere (verified via inventory pass). Admin verification happens at line 712 via `Test-SouliTEKAdministrator`, with the failure path going through `Show-AdminError` (line 60) which prints a custom non-admin instruction screen and `exit 1`s.
- **Local notes:** This is the same pattern other scripts use (custom UI on the non-admin path) but `#Requires -RunAsAdministrator` would short-circuit the script *before* dot-sourcing `SouliTEK-Common.ps1` and before any of the function definitions are parsed. Adding `#Requires -RunAsAdministrator` and `#Requires -Version 5.1` at the top of the file is a one-line hardening. The custom `Show-AdminError` UI can stay (it's friendlier than PowerShell's default `#Requires` message) — `#Requires` will fire first but the runtime check at line 712 then becomes belt-and-braces for the case where someone removes the `#Requires` line. Note: `-AutoFixSilent` mode (scheduled-task path) also needs admin, so the `#Requires` block doesn't change behavior — the scheduled task already runs as SYSTEM.
- **Target phase:** P4

### F6 — `Split-Path -Parent $MyInvocation.MyCommand.Path` instead of `$PSScriptRoot`
- **Severity:** low
- **Category:** structure
- **Location:** scripts/printer_spooler_fix.ps1:44
- **Current:**
  ```powershell
  $ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
  ```
- **Recommended:**
  ```powershell
  $ScriptRoot = $PSScriptRoot
  ```
- **Risk if changed:** Low. Same finding as F5 of driver_integrity_scan.md: `$PSScriptRoot` is the canonical PS 3.0+ automatic variable and `$MyInvocation.MyCommand.Path` returns `$null` when the script is dot-sourced. C10 will eventually replace this whole block with `Import-SouliTEKCommon`.
- **Target phase:** P4 (fold into the C10 sweep)

### F7 — Infinite menu loop with `Read-Host` and `ReadKey` blocks; deadlocks under SYSTEM context
- **Severity:** med (elevated above F6 of driver_integrity_scan.md because the `-AutoFixSilent` SYSTEM path exists right next to the interactive path)
- **Category:** structure (UX / RMM safety)
- **Location:** scripts/printer_spooler_fix.ps1:724 (`while ($true) { $choice = Show-MainMenu; switch ($choice) { ... } }`); also nested `while ($true)` loops at lines 293 (`Invoke-AdvancedMonitorMode`), 434 (`Invoke-PowerShellMode`), 510 (`Invoke-PSMonitorLog`). Blocking input calls: `Read-Host` at lines 77, 223, 262, 407, 428, 480, 498, 543, 559, 580, 626, 684; `$Host.UI.RawUI.ReadKey(...)` at lines 242, 281.
- **Local notes:** The script's main entry point is a top-level `while ($true)` menu loop with no graceful non-interactive exit other than `-AutoFixSilent` (which short-circuits at line 695 and never reaches the menu). That's actually OK — the silent path is well-isolated. But the three nested `while ($true)` loops inside mode functions (advanced monitor: line 293; PowerShell-mode submenu: line 434; PS monitor with logging: line 510) only exit via `Ctrl+C`, which is fine under interactive use but fragile under any wrapper. The `[Environment]::UserInteractive` check should gate the `Read-Host`/`ReadKey` calls so a wrapper invocation (e.g. via the launcher in headless mode) doesn't hang. Defer to P4 unless an actual hang report comes in; pairs with F6 of driver_integrity_scan.md and F10 of 01-modules-SouliTEK-Common.md.
- **Target phase:** P4

### F8 — `Get-EventLog` is deprecated; use `Get-WinEvent`
- **Severity:** info
- **Category:** legacy-api
- **Location:** scripts/printer_spooler_fix.ps1:399
- **Current:**
  ```powershell
  Get-EventLog -LogName System -Source 'Print' -Newest 5 -EntryType Error -ErrorAction SilentlyContinue
  ```
- **Recommended:**
  ```powershell
  Get-WinEvent -FilterHashtable @{ LogName = 'System'; ProviderName = 'Print'; Level = 2 } -MaxEvents 5 -ErrorAction Stop
  ```
- **Risk if changed:** Low-medium. `Get-EventLog` still exists in PS 7 (unlike `Get-WmiObject`) but is deprecated in favor of `Get-WinEvent` because the latter reads from the unified Windows Event Log infrastructure (covers `.evtx` channels that `Get-EventLog` cannot reach). The property surface differs: `Get-EventLog` returns `TimeGenerated`/`Message`; `Get-WinEvent` returns `TimeCreated`/`Message`. The downstream `Select-Object TimeGenerated, Message | Format-List` (line 400) would need `TimeCreated` instead. Not a strict C3 hit — flagging only because it's adjacent to the legacy-API theme. Defer to P4 unless C3 work picks it up.
- **Target phase:** P4

### F9 — Hard-coded Desktop output paths with no override (silent-mode log defect)
- **Severity:** info (but with a real bug on the SYSTEM-context path)
- **Category:** structure / correctness
- **Location:** scripts/printer_spooler_fix.ps1:460, 493, 538, 545, 697
- **Local notes:** Three Desktop log file destinations (`$env:USERPROFILE\Desktop\PrinterSpooler_Fix_$date.txt` line 460, `PrinterSpooler_Monitor_$date.txt` line 493, `PrinterSpooler_AutoFix_$date.txt` line 697) plus the log-listing path at 538 and 545. Same finding as F7 of driver_integrity_scan.md: `$env:USERPROFILE` resolves to `C:\Windows\System32\config\systemprofile` under SYSTEM context (which IS the path exercised by the scheduled task at line 595). The `Desktop` subfolder may not exist, in which case `Out-File` (lines 472, 507, 705) will throw. **This is a real defect on the `-AutoFixSilent` scheduled-task path** — the daily-3-AM SYSTEM run will fail to write its log because `C:\Windows\System32\config\systemprofile\Desktop` typically doesn't exist on a fresh install. Recommended fix: use `Join-Path $env:ProgramData 'SouliTEK\Logs'` (with `New-Item -ItemType Directory -Force` for the parent) for the silent-mode log destination, keep the Desktop path only for interactive modes. Low priority because the script doesn't observe its own log failure — the silent path runs to completion regardless — but worth fixing.
- **Target phase:** P4

### F10 — Banner and import-common-functions blocks are standard duplicated material
- **Severity:** low
- **Category:** docs / structure
- **Location:** scripts/printer_spooler_fix.ps1:1–34 (the 34-line banner/disclaimer block — C11) and lines 43–51 (the 9-line "Import SouliTEK Common Functions" block — C10).
- **Local notes:** Standard occurrences of the cross-cutting C10/C11 patterns. The script also has two empty function-comment stubs at lines 53–58 (`# Function to show ASCII banner` / `# Function to check admin privileges`) — leftovers from a refactor that moved those into the common module. Delete in the P4 banner/import-cleanup pass.
- **Target phase:** P4 (with C10/C11)

## Out-of-scope notes
- The `param([switch]$AutoFixSilent)` + early-return-at-line-695 pattern is a clean way to provide a silent-mode entry point for the scheduled task. Once F3 lands, the silent-mode path should also pass `-Confirm:$false` implicitly (which it will, given SYSTEM context's default `$ConfirmPreference = 'None'`).
- The mode functions' use of `try { ... -ErrorAction Stop } catch { Write-Ui -Message "..." -Level "ERROR" }` (lines 84–106, 127–134, 154–197) is the correct pattern for surfacing service-mutation failures. Don't touch this in P2 — the actual `SilentlyContinue` instances are all on the harmless probe paths.
- `Get-Printer | Select-Object Name, DriverName, PrinterStatus | Format-Table -AutoSize` (line 390) inside `Invoke-StatusCheckMode` is clean — `Get-Printer` is a first-class PowerShell cmdlet from `PrintManagement`, no `Get-WmiObject` legacy here. The surrounding `try/catch` (line 391) is the right pattern.
- `New-ScheduledTaskAction`/`Trigger`/`Principal`/`Settings`/`Register-ScheduledTask` pipeline (lines 590–595) is the modern cmdlet-based approach (no `schtasks.exe` shell-out). Good. The only issue is the missing `ShouldProcess` gate — covered in F3.
- The `Add-Content -Path $LogFile -Value "[$timestamp] ..."` calls in `Invoke-SpoolerFixWithLog` (lines 154, 160, 163, 166, 169, 172, 177, 179, 182, 185, 188, 190, 193, 195, 196) and `Invoke-PSMonitorLog` (lines 512, 516, 520) are appropriate for a structured log file — they should NOT be migrated to `Write-Ui` because the destination is a file, not the console. Note that the global CLAUDE.md "no logging unless explicitly asked" rule was already broken here (this is essentially the user-facing logging mode), but since logging is the explicit purpose of these modes and the user enables them by menu choice, that's fine. Keep as-is.
- The 3 trailing blank lines at the end of the file (744–746) are harmless but could be trimmed in any pass that touches the file.
- The script does not handle `Ctrl+C` cleanup — if the user `Ctrl+C`s out of `Invoke-AdvancedMonitorMode` while the spooler is mid-stop, the spool folder may be wiped but the service never re-started. Not a fix priority (operator can re-run the script), but a `try { ... } finally { Start-Service Spooler -ErrorAction SilentlyContinue }` wrap around the monitor's fix paths would be a clean P4 hardening.
