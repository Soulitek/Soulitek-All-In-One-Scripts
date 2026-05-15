# Audit — scripts/bsod_history_scanner.ps1

## Inventory
| Item | Value |
|---|---|
| Path           | scripts/bsod_history_scanner.ps1 |
| LOC            | 550 |
| Functions      | 10 (`Show-Header`, `Get-BugCheckDescription`, `Get-MinidumpFiles`, `Get-BugCheckEvents`, `Invoke-FullScan`, `Show-BSODResults`, `Show-LastBSOD`, `Export-BSODResults`, `Show-Help`, `Show-MainMenu`) |
| `#Requires`    | `#Requires -Version 5.1` (no `-RunAsAdministrator` — comment at line 537 notes "recommended but not required" and uses `Invoke-SouliTEKAdminCheck` for a soft prompt) |
| Admin-required | no (declared); reading `$env:SystemRoot\Minidump` and `Get-WinEvent -LogName System` typically need admin in practice, but the script intentionally degrades gracefully when not elevated |
| Last touched   | 8675720 — 2026-04-17 |
| Modernization grade | B |

## Summary

A read-only triage tool that enumerates BSOD evidence from two sources: minidump files in `%SystemRoot%\Minidump` (file listing only — no actual dump parsing) and BugCheck events (Event ID 1001) from the System event log. Output is a single results table plus optional TXT/CSV/HTML export through `Export-SouliTEKReport`. Architecturally the script is in noticeably better shape than the rest of the bench: error handling is clean (zero `-ErrorAction SilentlyContinue` — F2 below is a "clean" finding), the output style is already ~80 % migrated to `Write-Ui`, and the eight remaining `Write-Host` clusters split between legitimate visual separators (the `============` divider lines and bare `Write-Host ""` spacers) and a tractable batch of "Label: " + `Write-Ui` two-call splits in `Show-LastBSOD` (lines 325–353) that should fold into single `Write-Ui` calls. The bigger structural opportunity is **F3**: the `$Script:BugCheckCodeMap` hashtable at lines 41–70 is a 29-entry kernel-bugcheck lookup table embedded in the script body. This mirrors the embedded license-SKU table in `license_expiration_checker` and should externalize to `config/bugcheck_codes.json` so the table can grow without script churn and so other diagnostic tools (e.g. a future kernel-debug helper) can reuse it. The lookup is also incomplete — Microsoft publishes ~370+ documented bugcheck codes — so externalizing first, then expanding the table, is the right order. Secondary concerns: 8 legacy `Write-SouliTEK*` calls (F4) keep the C2 dead API alive; `Split-Path -Parent $MyInvocation.MyCommand.Path` (line 25) instead of `$PSScriptRoot` (F6); infinite `do/while ($true)` menu loop with `Read-Host` (line 499) blocks SYSTEM-context execution (F7); the C11 banner block occupies lines 1–14. The `Get-BugCheckEvents` function (lines 144–214) does honest event-log XML parsing — extracting `param1` through `param5` from the Event-1001 EventData payload, normalising the bugcheck code to `0x` hex format, and pairing it with the lookup — which is the script's strongest part. Recommended phase entry order: P1 (C1 + C2 cleanup are small here), then P4 (F3 config externalization alongside the similar work on `license_expiration_checker`).

## Findings

### F1 — Raw `Write-Host` mixed with `Write-Ui` (see C1)
- **Severity:** med
- **Category:** output-style
- **Location:** scripts/bsod_history_scanner.ps1 — 49 raw `Write-Host` occurrences (task plan predicted 48; difference is the trailing `Write-Host ""` in the `catch` block at line 546). Lines: 225, 233, 239, 243, 248, 251, 269, 271, 272, 282, 285, 299, 314, 321, 323, 324, 325, 327, 328, 330, 331, 333, 334, 336, 339, 341, 342, 344, 345, 347, 351, 353, 358, 366, 379, 431, 445, 448, 454, 458, 465, 469, 474, 489, 496, 497, 508, 546.
- **Reference:** [C1](00-cross-cutting.md#c1--raw-write-host-calls-not-migrated-to-write-uiwrite-status)
- **Current (representative pattern — `Show-LastBSOD` label split at lines 325–326):**
  ```powershell
  Write-Host "Date/Time: " -NoNewline -ForegroundColor Yellow
  Write-Ui -Message "$($lastBSOD.Timestamp)" -Level "STEP"
  Write-Host ""
  ```
- **Recommended:**
  ```powershell
  Write-Ui -Message "Date/Time: $($lastBSOD.Timestamp)" -Level "STEP"
  ```
- **Risk if changed:** Low — message text preserved; the yellow-label/`STEP`-bracket combination becomes a single `[STEP]` line. Per-category fix patterns are enumerated below in Local notes.
- **Local notes:** Three categories of raw `Write-Host`:
  1. **Blank-line / spacer calls** — bare `Write-Host ""` for vertical spacing (lines 225, 233, 239, 243, 248, 251, 272, 282, 285, 299, 314, 324, 327, 330, 333, 336, 341, 344, 347, 353, 366, 379, 431, 445, 448, 454, 458, 465, 469, 474, 489, 496, 508, 546 — 34 of the 49 total). These are not C1 violations per the "visual separator helpers" exception, but they are noisy. If a `Write-Ui -Spacer` helper is added in P4, fold these in.
  2. **`====` divider lines** — `Write-Host "===...===" -ForegroundColor Cyan` (lines 269, 271, 321, 323) and `-ForegroundColor DarkGray` (line 497). 5 occurrences. These are legitimate section dividers; if a `Show-Section` / `Show-Divider` helper is added in P4, migrate, otherwise leave as-is.
  3. **Inline-color label splits** — the `Write-Host "Label: " -NoNewline -ForegroundColor Yellow` followed by `Write-Ui -Message "$value" -Level "STEP"` pattern in `Show-LastBSOD` (lines 325–326, 328–329, 331–332, 334–335, 339–340, 342–343, 345–346, 351–352, 358–360/362/364). 10 occurrences. These are real C1 violations and should each collapse into a single `Write-Ui -Message "Label: $value" -Level "STEP"` call.
- **Target phase:** P1

### F2 — `-ErrorAction SilentlyContinue` triage (see C4) — **clean**
- **Severity:** info
- **Category:** error-handling
- **Location:** scripts/bsod_history_scanner.ps1 — **0 occurrences**
- **Reference:** [C4](00-cross-cutting.md#c4----erroraction-silentlycontinue-swallowing-failures)
- **Local notes:** The script uses `-ErrorAction Stop` at the two external-call sites (line 115 for `Get-ChildItem` over the minidump directory, line 159 for `Get-WinEvent -FilterHashtable`) and wraps each in a `try { ... } catch { Write-Ui -Message "..." -Level "ERROR" }` block. The `Get-WinEvent` catch (lines 205–210) specifically tests for the "No events were found" exception message and downgrades it to an informational `Write-SouliTEKInfo` call rather than treating absence-of-events as an error — the right pattern. This is the cleanest error-handling posture seen in the audit so far; matches CLAUDE.md "fail closed — deny by default" without being noisy on legitimate empty states. **No action required.**
- **Target phase:** —

### F3 — Embedded `$Script:BugCheckCodeMap` lookup table → externalize to `config/bugcheck_codes.json`
- **Severity:** med
- **Category:** structure / data-config
- **Location:** scripts/bsod_history_scanner.ps1:41–70 (lines 41–70, 30 lines including the closing brace — 29 bugcheck code entries)
- **Current:**
  ```powershell
  $Script:BugCheckCodeMap = @{
      "0x0000000A" = "IRQL_NOT_LESS_OR_EQUAL"
      "0x0000001E" = "KMODE_EXCEPTION_NOT_HANDLED"
      # ... 27 more entries ...
      "0x000001F7" = "FATAL_UNHANDLED_HARD_ERROR"
  }
  ```
- **Recommended:**
  ```powershell
  # config/bugcheck_codes.json (new file at repo root config/ dir)
  {
    "0x0000000A": "IRQL_NOT_LESS_OR_EQUAL",
    "0x0000001E": "KMODE_EXCEPTION_NOT_HANDLED",
    "...": "..."
  }

  # In script:
  $configPath = Join-Path $Script:RootPath "config\bugcheck_codes.json"
  $Script:BugCheckCodeMap = Get-Content $configPath -Raw | ConvertFrom-Json -AsHashtable
  ```
- **Risk if changed:** Low — pure data extraction. Note `ConvertFrom-Json -AsHashtable` is PS-6+ only; for PS 5.1 compatibility either (a) iterate the resulting `PSCustomObject` to build a hashtable, or (b) define a small `ConvertTo-Hashtable` helper in `SouliTEK-Common.ps1`. Option (b) is preferable because `license_expiration_checker` will need the same helper when its SKU table externalizes. The `Get-BugCheckDescription` consumer (lines 83–97) doesn't need to change — it reads `$Script:BugCheckCodeMap` as a hashtable either way.
- **Local notes:**
  - The current table has 29 entries. Microsoft documents 370+ bugcheck codes (see `learn.microsoft.com/windows-hardware/drivers/debugger/bug-check-code-reference2`); the table is intentionally curated to "common" codes (per the Help screen at lines 459–464). Externalizing first lets the table grow without script churn.
  - **Duplicate values to investigate** during the migration: `"0x0000003B"` and `"0x00000161"` both map to `SYSTEM_SERVICE_EXCEPTION` (lines 44, 60); `"0x0000007E"`, `"0x0000017E"`, and `"0x000001C5"` all map to `SYSTEM_THREAD_EXCEPTION_NOT_HANDLED` (lines 46, 61, 64); `"0x000000D1"` and `"0x000001D1"` both map to `DRIVER_IRQL_NOT_LESS_OR_EQUAL` (lines 48, 65); `"0x000000F4"` and `"0x000001F4"` both map to `CRITICAL_OBJECT_TERMINATED` (lines 49, 68). These look like data-entry errors — Microsoft's bugcheck reference lists distinct names for each numeric code. Confirm against the canonical reference and correct during the JSON migration.
  - Pair this with the analogous extraction for `license_expiration_checker`'s SKU table to amortize the `ConvertTo-Hashtable` helper across both call sites.
- **Target phase:** P4

### F4 — 8 legacy `Write-SouliTEK*` API callers (see C2)
- **Severity:** low
- **Category:** output-style
- **Location:** scripts/bsod_history_scanner.ps1 — 8 occurrences of the C2 dead API: lines 162 (`Write-SouliTEKInfo`), 207 (`Write-SouliTEKInfo`), 242 (`Write-SouliTEKSuccess`), 313 (`Write-SouliTEKWarning`), 378 (`Write-SouliTEKWarning`), 432 (`Write-SouliTEKSuccess`), 507 (`Write-SouliTEKWarning`), 522 (`Write-SouliTEKWarning`).
- **Reference:** [C2](00-cross-cutting.md#c2--dead-duplicate-output-api)
- **Current:**
  ```powershell
  Write-SouliTEKInfo "No BugCheck events found in System event log"
  ```
- **Recommended:**
  ```powershell
  Write-Ui -Message "No BugCheck events found in System event log" -Level "INFO"
  ```
- **Risk if changed:** Low. Pure API rename — the `Write-SouliTEKInfo` wrapper internally calls `Write-Ui -Level "INFO"` anyway. These must be migrated before C2's "delete the five legacy functions from the module" step can land.
- **Target phase:** P1 (fold into the C1 sweep)

### F5 — Minidump files listed but never parsed; `BugCheckCode = "N/A (requires analysis)"`
- **Severity:** info
- **Category:** correctness (note only — feature gap, not a bug)
- **Location:** scripts/bsod_history_scanner.ps1:124–135 (`Get-MinidumpFiles` foreach loop)
- **Local notes:** `Get-MinidumpFiles` enumerates `*.dmp` files in `$env:SystemRoot\Minidump` but populates every record with `BugCheckCode = "N/A (requires analysis)"` (line 131) and `BugCheckDescription = "N/A"` (line 132). The actual bugcheck code is present in the minidump file header but extracting it requires either WinDbg/`cdb.exe` shelled out, or parsing the binary `_MINIDUMP_HEADER` / `_MEMORY_DUMP_HEADER` structure manually. The Help screen at lines 470–473 documents this limitation honestly. Practical consequence: the script's "Last BSOD" display picks the most-recent entry by `Timestamp`, which is the file `LastWriteTime` for minidumps vs `TimeCreated` for event log records — when both sources are present, the event-log record usually wins because it has microsecond resolution. The minidump-only path therefore shows `BugCheckCode: N/A (requires analysis)` for the last-BSOD display, which is honest but unhelpful. A P4+ enhancement opportunity is to shell out to a bundled `cdb.exe` or `dumpchk.exe` if available, or parse the dump header directly using `[System.IO.File]::ReadAllBytes()` and the documented Microsoft DBGHELP minidump format. Not a near-term priority — keep as a documented limitation.
- **Target phase:** —

### F6 — `Split-Path -Parent $MyInvocation.MyCommand.Path` instead of `$PSScriptRoot`
- **Severity:** low
- **Category:** structure
- **Location:** scripts/bsod_history_scanner.ps1:25
- **Current:**
  ```powershell
  $Script:ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
  $Script:RootPath = Split-Path -Parent $Script:ScriptPath
  ```
- **Recommended:**
  ```powershell
  $Script:ScriptPath = $PSScriptRoot
  $Script:RootPath = Split-Path -Parent $PSScriptRoot
  ```
- **Risk if changed:** Low. `$PSScriptRoot` is the canonical PS 3.0+ automatic variable for "directory of the running script." `$MyInvocation.MyCommand.Path` returns `$null` when the script is dot-sourced, so the current form is also slightly more fragile. C10 will eventually replace this whole block with `Import-SouliTEKCommon`, but until then this one-line fix is free.
- **Target phase:** P4 (fold into the C10 sweep)

### F7 — Infinite menu loop with no non-interactive exit + blocking `Read-Host`
- **Severity:** low
- **Category:** structure (UX / RMM safety)
- **Location:** scripts/bsod_history_scanner.ps1:485 (`do { ... } while ($true)`), `Read-Host` at line 499 inside the loop, plus `Read-Host "Press Enter to exit"` at line 547 in the top-level `catch` block, plus repeated `Wait-SouliTEKKeyPress` calls inside option handlers (lines 255, 315, 368, 380, 433, 476, 509, 512).
- **Local notes:** Same pattern as F6 of `scripts-driver_integrity_scan.md`. Under SYSTEM-context RMM execution (flagged in user's CLAUDE.md as a deployment scenario), `Read-Host` will hang the worker process. There is no `[Environment]::UserInteractive` gate and no `-NonInteractive` switch. The script is interactive-by-design (menu-driven), so this is low-severity, but if the launcher ever invokes this in a non-interactive flow it will deadlock. Defer to P4 unless an RMM hang report comes in; pairs with the same recommendation on `Wait-SouliTEKKeyPress` (F10 of 01-modules-SouliTEK-Common.md).
- **Target phase:** P4

### F8 — No `[CmdletBinding()]` on script or any function
- **Severity:** low
- **Category:** structure
- **Location:** scripts/bsod_history_scanner.ps1 — script-level (no `param()` block at all) and every internal function: `Show-Header` (77), `Get-BugCheckDescription` (83), `Get-MinidumpFiles` (99), `Get-BugCheckEvents` (144), `Invoke-FullScan` (216), `Show-BSODResults` (258), `Show-LastBSOD` (304), `Export-BSODResults` (371), `Show-Help` (436), `Show-MainMenu` (479).
- **Local notes:** The script is fully interactive (no `param()` block, no CLI surface). `Get-BugCheckDescription` (line 83) is the only function with an actual `param()` block (`[string]$BugCheckCode`) but lacks `[CmdletBinding()]`. Adding `[CmdletBinding()]` would be near-free here since none of these functions need `ShouldProcess` — the script is read-only. This is C5 territory only if the script gets a non-interactive parameterised entry point. Low priority.
- **Target phase:** P4

### F9 — Sort-by-`Timestamp` mixes minidump `LastWriteTime` with event-log `TimeCreated` (precision mismatch)
- **Severity:** info
- **Category:** correctness (note only — no change recommended)
- **Location:** scripts/bsod_history_scanner.ps1:275, 288, 319, 393, 408 (every `Sort-Object Timestamp` site)
- **Local notes:** `Get-MinidumpFiles` populates `Timestamp = $dumpFile.LastWriteTime` (line 129); `Get-BugCheckEvents` populates `Timestamp = $event.TimeCreated` (line 196). Both are `[DateTime]` values but minidump file timestamps round to filesystem resolution (~10 ms on NTFS, sometimes higher with FAT/network drives) whereas event-log `TimeCreated` is millisecond-precise from the event provider. For a given BSOD, both sources usually exist and will share roughly the same wall-clock time but won't be exactly equal — so `Show-LastBSOD` will pick one or the other essentially at random when they disagree by under 1 sec. Worth a `Group-By` near-duplicate dedup pass at some point (e.g., entries within 60 seconds of each other are the same BSOD), but not a near-term priority — the duplicate entries surface as `[Event Log]` + `[Minidump]` adjacent records which is actually useful for triage. Document, don't fix.
- **Target phase:** —

## Out-of-scope notes
- Banner block (lines 1–14, 13 lines of `# === / Coded by / IMPORTANT DISCLAIMER`) matches C11 cross-cutting cleanup; covered there. Lighter than the driver-integrity script's 32-line banner.
- The `Import Common Module` block (lines 21–33) is the standard 8-line boilerplate — C10 territory.
- The `Get-BugCheckEvents` XML parsing (lines 168–202) is solid: handles the `param1` BugCheckCode and `param2`–`param5` parameters cleanly, normalizes the bugcheck integer to `0x` hex via `("{0:X8}" -f [int]$bugCheckCode)`, and gracefully degrades to `"Unknown"` when `param1` is absent. The `if ($bugCheckCode -ne "Unknown" -and -not $bugCheckCode.StartsWith("0x"))` guard correctly handles both decimal-string and already-prefixed inputs. No change needed.
- The `Format-SouliTEKFileSize` call at line 130 is the correct module helper for human-readable byte sizes; reused in many scripts.
- `Export-BSODResults` (lines 371–434) delegates entirely to `Show-SouliTEKExportMenu` + `Export-SouliTEKReport` and handles the `"ALL"` format selection cleanly (lines 411–415). No change needed.
- `Show-SouliTEKDisclaimer` and `Show-ScriptBanner` are called from the entry `try` block (lines 535, 540) before `Show-MainMenu` — standard pattern matching `Initialize-SouliTEKScript` usage elsewhere.
- The `Show-Header` wrapper function at lines 77–81 is a thin pass-through to `Show-SouliTEKHeader`; harmless but redundant — could be inlined as part of any P4 cleanup pass.
- The top-level `catch` block at lines 544–549 logs the exception message via `Write-Ui -Level "ERROR"`, then blocks on `Read-Host "Press Enter to exit"` and `exit 1`. The `Read-Host` is the same RMM-hang concern as F7; the `exit 1` after `Read-Host` is the right disposition once the prompt is removed.
- The `0x` hex formatting in `Get-BugCheckEvents` produces 8-digit upper-case hex (e.g. `0x0000000A`), which matches the keys in `$Script:BugCheckCodeMap`. The map keys are upper-case `A` (line 42); ensure any external JSON normalization preserves this casing when F3 migrates.
- The trailing blank line at line 550 (the file ends with `}` then a newline) is harmless.
