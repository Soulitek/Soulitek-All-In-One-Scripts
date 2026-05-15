# Audit — scripts/driver_integrity_scan.ps1

## Inventory
| Item | Value |
|---|---|
| Path           | scripts/driver_integrity_scan.ps1 |
| LOC            | 746 |
| Functions      | 8 |
| `#Requires`    | `#Requires -RunAsAdministrator` and `#Requires -Version 5.1` |
| Admin-required | yes (declared by `#Requires -RunAsAdministrator`; reads/queries Win32_PnPEntity device tree and invokes `winget upgrade --all` to mutate installed software) |
| Last touched   | 8675720 — 2026-04-17 |
| Modernization grade | D |

## Summary

A menu-driven driver-and-software triage tool: scans `Win32_PnPEntity` for problem devices, exports the catalog to CSV/TXT on Desktop, persists the last scan to `%LOCALAPPDATA%\SouliTEK\LastDriverScan.json`, and shells out to `winget upgrade` for software refresh. The biggest issues are (1) the entire device enumeration depends on `Get-WmiObject` (line 140), which is removed in PowerShell 7 — replacement with `Get-CimInstance` is the single most important migration step here; (2) raw `Write-Host` is used 74 times alongside `Write-Ui`/`Write-SouliTEK*` legacy wrappers, creating a three-way output-style mix that violates STYLE_GUIDE.md (C1) and keeps the C2 legacy API alive in the caller set; (3) many `Write-Ui` calls embed inline `[*]`/`[+]`/`[-]`/`[!]` markers inside the message string, double-marking output that already carries the `[LEVEL]` bracket from `Write-Ui` itself (same anti-pattern as F2 of 01-modules-SouliTEK-Common.md). Secondary concerns: no `[CmdletBinding()]` on the script or any function despite the task plan predicting otherwise; the script uses `Split-Path -Parent $MyInvocation.MyCommand.Path` instead of `$PSScriptRoot`; the main loop is an unconditional `while ($true)` with `Read-Host` gates that would hang under SYSTEM/RMM execution; and the C11 banner block occupies the first 32 lines. The five `-ErrorAction SilentlyContinue` occurrences are all defensible cleanup/probe uses and all carry triage tag **A**. Recommended phase entry order: P1 (C3 + C1), then P2 (C4 triage).

## Findings

### F1 — Legacy `Get-WmiObject` (see C3)
- **Severity:** high
- **Category:** legacy-api
- **Location:** scripts/driver_integrity_scan.ps1:140 (1 occurrence — task plan predicted 3; only one call site exists)
- **Reference:** [C3](00-cross-cutting.md#c3--get-wmiobject-removed-in-ps-7)
- **Current:**
  ```powershell
  $allDevices = Get-WmiObject Win32_PnPEntity -ErrorAction Stop
  ```
- **Recommended:**
  ```powershell
  $allDevices = Get-CimInstance -ClassName Win32_PnPEntity -ErrorAction Stop
  ```
- **Risk if changed:** Low. `Get-CimInstance` returns identical property surface for `Win32_PnPEntity` — `Name`, `Manufacturer`, `Status`, `ConfigManagerErrorCode`, `DeviceID`, `DriverVersion`, `DriverDate`, `Present` all match. Note `DriverDate` continues to arrive as a CIM `DATETIME` string in PS 5.1 but as a `DateTime` already-converted object in PS 7+; the existing `try { [Management.ManagementDateTimeConverter]::ToDateTime(...) } catch { "N/A" }` block on lines 167–173 covers both cases because the conversion fails gracefully when the input is already a `DateTime`. Validate on both Win 10 and Win 11.
- **Target phase:** P1

### F2 — Mixed `Write-Host` / `Write-Ui` / `Write-SouliTEK*` (see C1)
- **Severity:** med
- **Category:** output-style
- **Location:** scripts/driver_integrity_scan.ps1 — 74 raw `Write-Host` occurrences (sample lines: 116, 146, 190, 191, 194, 196, 358, 423, 442, 565). Plus 12 legacy `Write-SouliTEK*` wrapper calls (lines 382, 484, 527, 532, 597, 639, 655, 677, 680, 701, 704, 729) that exercise C2's dead API.
- **Reference:** [C1](00-cross-cutting.md#c1--raw-write-host-calls-not-migrated-to-write-uiwrite-status)
- **Current (representative pattern — inline-color formatting at line 190–192):**
  ```powershell
  Write-Host "  " -NoNewline
  Write-Host "Checking driver integrity..." -ForegroundColor Cyan -NoNewline
  Write-Host ""
  ```
- **Recommended:**
  ```powershell
  Write-Ui -Message "Checking driver integrity..." -Level "STEP"
  ```
- **Risk if changed:** Low — message text preserved verbatim; the `[STEP]` bracket emitted by `Write-Ui` replaces the manual color formatting. Per-category fix patterns are enumerated below in Local notes.
- **Local notes:** Three categories of raw `Write-Host`:
  1. **Blank-line / spacer calls** — bare `Write-Host ""` used as vertical spacing (e.g. lines 132, 146, 185, 187, 203, 208, 217, 224, 228, 358, 361, 388, 400, 403, 405, 410, 423, 439, 442, 448, 451, 463, 494, 504, 509, 518, 524, 528, 544, 547, 550, 553, 556, 559, 562, 580, 596, 602, 604, 607, 612, 623, 630, 643, 646, 659, 670, 683, 694, 707, 715, 721). These should remain as-is or migrate to a `Write-Ui -Spacer` / `Show-Section` helper if one is added in P4 — they are not C1 violations per the "visual separator helpers" exception, but they are noisy.
  2. **Inline-color formatting** — `Write-Host "  " -NoNewline` followed by `Write-Host "TITLE" -ForegroundColor Cyan -NoNewline` (lines 190–192, 194, 196, 206, 401–403, 440–442, 449–451, 507–509, 564–566, 603–607). These are real C1 violations: pre-Write-Ui-era manual color formatting that should be `Write-Ui -Message "TITLE" -Level "STEP"` (or `-Level "INFO"`).
  3. **Plain message lines** — `Write-Host "  [!] You can install it from: https://aka.ms/getwinget" -ForegroundColor Yellow` (line 116) and `Write-Host "  [!] Please install WinGet from: https://aka.ms/getwinget" -ForegroundColor Yellow` (line 383), `Write-Host "  $_" -ForegroundColor Gray` lines (404, 443, 452). Clear C1 violations.
- **Local notes (cont.) — inline marker prefixes:** Many `Write-Ui` calls in this script already double-mark with embedded `[*]`/`[+]`/`[-]`/`[!]` prefixes inside the message (lines 115, 139, 145, 153, 186, 207, 214, 215, 216, 222, 223, 359, 360, 392, 408, 409, 422, 461, 462, 485, 515, 516, 517, 523, 543, 545, 546, 548, 549, 551, 552, 554, 555, 557, 558, 560, 561, 563, 640, 642, 644, 645, 668, 669, 685, 692, 693, 722). Same anti-pattern as F2 of 01-modules-SouliTEK-Common.md — when the C1 sweep is done, strip these inline markers so the `[LEVEL]` bracket emitted by `Write-Ui` is the only marker.
- **Local notes (cont.) — legacy API callers:** 12 calls to the C2 dead API (`Write-SouliTEKInfo`/`Warning`/`Error`/`Success`). These must be migrated to `Write-Ui` before C2's "delete the five legacy functions from the module" step can land.
- **Target phase:** P1

### F3 — `-ErrorAction SilentlyContinue` triage (see C4)
- **Severity:** med
- **Category:** error-handling
- **Location:** scripts/driver_integrity_scan.ps1 — 5 occurrences
- **Reference:** [C4](00-cross-cutting.md#c4----erroraction-silentlycontinue-swallowing-failures)
- **Triage:**
  - Line 109: tag **A** — `Get-Command winget.exe -ErrorAction SilentlyContinue` is a probe; the result is immediately tested with `if ($wingetPath)` to set `$Script:WinGetAvailable`. Legitimate "does this command exist?" check. Add `# safe: probe` comment in P2.
  - Line 433: tag **A** — `Get-Content "$env:TEMP\winget_upgrade_output.txt" -Raw -ErrorAction SilentlyContinue` reads the redirected stdout file after `Start-Process -RedirectStandardOutput`. The file may be empty/absent if winget produced no stdout; `$output` is then checked with `if ($output)` before use. Legitimate. Add `# safe: optional read` comment.
  - Line 434: tag **A** — `Get-Content "$env:TEMP\winget_upgrade_error.txt" -Raw -ErrorAction SilentlyContinue` — same pattern as line 433 for stderr. Legitimate. Add `# safe: optional read` comment.
  - Line 457: tag **A** — `Remove-Item "$env:TEMP\winget_upgrade_output.txt" -ErrorAction SilentlyContinue` is post-use cleanup of the temp file. Pure C4-tag-A "delete temp file if exists." Add `# safe: cleanup` comment.
  - Line 458: tag **A** — `Remove-Item "$env:TEMP\winget_upgrade_error.txt" -ErrorAction SilentlyContinue` — same as line 457. Add `# safe: cleanup` comment.
- **Target phase:** P2

### F4 — No `[CmdletBinding()]` on script or any function
- **Severity:** low
- **Category:** structure
- **Location:** scripts/driver_integrity_scan.ps1 — script-level (top of file, no `param()` block at all) and every one of the 8 internal functions (`Get-WinGetAvailability` line 103, `Get-DriverIntegrityStatus` line 126, `Save-ScanResults` line 242, `Export-DriverList` line 268, `Update-InstalledSoftware` line 371, `Show-LastScanResults` line 478, `Show-Menu` line 536, `Main` line 573).
- **Local notes:** The task plan predicted "Already has `[CmdletBinding()]` — confirm." That prediction is wrong: there is no `[CmdletBinding()]` anywhere in the script. The script is fully interactive (no `param()` block, no CLI surface), so this is low-severity, but adding `[CmdletBinding()]` to `Export-DriverList` (which already has `param([switch]$ProblemsOnly)`) and `Update-InstalledSoftware` (`param([switch]$AutoUpdate, [switch]$Interactive)`) would let those two functions accept `-Verbose` and `-ErrorAction` from callers. This is C5 territory only if the script gets a non-interactive parameterised entry point — which is a reasonable P3 follow-up given the destructive `winget upgrade --all` path on `$AutoUpdate`.
- **Target phase:** P4

### F5 — `Split-Path -Parent $MyInvocation.MyCommand.Path` instead of `$PSScriptRoot`
- **Severity:** low
- **Category:** structure
- **Location:** scripts/driver_integrity_scan.ps1:41
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
- **Location:** scripts/driver_integrity_scan.ps1:582 (`do { ... } while ($true)`), plus `Read-Host` calls at lines 584, 613, 624, 631, 648, 660, 672, 684, 696, 708, 716.
- **Local notes:** The script is interactive-only by design — the only graceful exit is menu option `[0]` which calls `exit` (line 725). Under SYSTEM-context RMM execution (flagged in user's CLAUDE.md as a deployment scenario), `Read-Host` will hang the worker process. There is no `[Environment]::UserInteractive` gate and no `-NonInteractive` switch. If this script is ever invoked by the launcher in a non-interactive flow, it will deadlock. Defer to P4 unless an actual RMM hang report comes in; pairs naturally with the same recommendation against `Wait-SouliTEKKeyPress` (F10 of 01-modules-SouliTEK-Common.md).
- **Target phase:** P4

### F7 — Hard-coded Desktop output path with no override
- **Severity:** info
- **Category:** structure
- **Location:** scripts/driver_integrity_scan.ps1:57 (`$Script:OutputDir = "$env:USERPROFILE\Desktop"`).
- **Local notes:** The CSV/TXT export target is hard-coded to the current user's Desktop. This breaks under SYSTEM context (`$env:USERPROFILE` resolves to `C:\Windows\System32\config\systemprofile` and the Desktop folder may not exist) and offers no way to redirect the export. Low priority because the menu-driven design assumes interactive use, but a `-OutputDirectory` parameter on `Export-DriverList` would be a clean follow-up alongside F4's `[CmdletBinding()]` add. Note: `$Script:LastScanFile` (line 58) uses `$env:LOCALAPPDATA` which is the right idiom and handles per-user paths correctly.
- **Target phase:** P4

### F8 — `Manufacturer` / `Status` filter logic ORs `Status -ne "OK"` with non-zero error code
- **Severity:** info
- **Category:** correctness (note only — no change recommended)
- **Location:** scripts/driver_integrity_scan.ps1:180 (`if ($errorCode -ne 0 -or $device.Status -ne "OK")`).
- **Local notes:** `Win32_PnPEntity.Status` can return values like `"OK"`, `"Error"`, `"Degraded"`, `"Unknown"`, `"Pred Fail"`, `"Starting"`, `"Stopping"`, `"Service"`, `"Stressed"`, `"NonRecover"`, `"No Contact"`, `"Lost Comm"`. Any non-`"OK"` triggers a problem-device flag, which is correct but means transient states like `"Starting"` or `"Service"` will surface as false positives. Worth a comment in the source noting the intentional broadness, but not worth a logic change — the export contains the raw `Status` field so an operator can dismiss false positives by eye.
- **Target phase:** —

## Out-of-scope notes
- Banner block (lines 1–32, 27 lines of `# === / Coded by / IMPORTANT DISCLAIMER`) matches C11 cross-cutting cleanup; covered there.
- The `Save-ScanResults` JSON-persist pattern (lines 242–266) is clean: creates the parent directory if missing, uses `ConvertTo-Json -Depth 10` to handle the nested `PSCustomObject` array, and the surrounding `try { ... } catch { Write-Verbose "Could not save scan results: $_" }` is appropriately quiet for a non-essential cache write. No change needed.
- The `$Script:ErrorCodes` hashtable (lines 62–95) is a clean lookup table for Windows Device Manager error codes 0–52. Comprehensive and well-organized — a model of how to handle this kind of enum-to-text mapping. No change needed.
- The trailing 7 blank lines at the end of the file (lines 741–747) are harmless but could be trimmed in any pass that touches the file.
- The `Start-Process winget.exe ... -RedirectStandardOutput ... -RedirectStandardError ... -Wait -PassThru` pattern (lines 425–431) on the `$AutoUpdate` path is a sensible way to capture and surface winget's output without letting it scribble onto the host console mid-banner. Note that `--disable-interactivity` is correctly included in `$wingetArgs` so the wrapped winget call won't hang on a Y/N prompt.
- The script's overall structure (top-level `Main` function called once at the bottom) follows the `Initialize-SouliTEKScript` pattern even though it doesn't actually call that module helper — a P4 standardisation candidate alongside C10.
