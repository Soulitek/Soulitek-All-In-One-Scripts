# Audit — scripts/software_updater.ps1

## Inventory
| Item | Value |
|---|---|
| Path           | scripts/software_updater.ps1 |
| LOC            | 613 (file has 635 lines including a trailing blank) |
| Functions      | 9 |
| `#Requires`    | `#Requires -RunAsAdministrator` and `#Requires -Version 5.1` |
| Admin-required | yes (declared by `#Requires -RunAsAdministrator`; shells out to `winget upgrade --all` which mutates installed software system-wide) |
| Last touched   | 8675720 — 2026-04-17 |
| Modernization grade | B |

## Summary

A menu-driven WinGet wrapper: checks for available upgrades, runs `winget upgrade --all` either silently (with stdout/stderr captured to temp files) or interactively (passes the user through to the live winget TUI), persists the last 50 update sessions to `%LOCALAPPDATA%\SouliTEK\UpdateHistory.json`, and exports a plain-text update report to Desktop. The destructive surface is entirely delegated to WinGet — the script itself does not edit registry, services, or files outside its own JSON history / report — so the C5 `SupportsShouldProcess` question lands on the "no" side (justification in Out-of-scope). The main issues are stylistic and mirror the cross-cutting findings: (1) 60 raw `Write-Host` occurrences plus 22 legacy `Write-SouliTEK*` wrapper calls coexist with `Write-Ui`, producing the same three-way output mix flagged in `scripts-driver_integrity_scan.md` (C1 + C2); (2) the `Write-Ui` calls that *are* used pervasively embed inline `[*]`/`[!]` markers inside the message string, double-marking output that already carries the `[LEVEL]` bracket from `Write-Ui` itself (same anti-pattern as F2 of `01-modules-SouliTEK-Common.md`); (3) all 5 `-ErrorAction SilentlyContinue` occurrences are defensible (probe + redirected-file read + cleanup), all carry triage tag **A**. Secondary concerns: no `[CmdletBinding()]` on the script or any of its 9 functions; uses `Split-Path -Parent $MyInvocation.MyCommand.Path` rather than `$PSScriptRoot` (F4 of `scripts-driver_integrity_scan.md`); infinite `while ($true)` menu loop with 6 blocking `Read-Host` calls that would hang under SYSTEM/RMM execution; hard-coded Desktop output path; the Interactive update mode logs `ExitCode = 0` unconditionally (line 302) because `winget upgrade --all` is invoked as a console call (not `Start-Process -PassThru`), so the real exit code is never captured; and an exit-status logic bug in `Save-UpdateHistory` where `Success = ($ExitCode -eq 0 -or $ExitCode -eq -1978335189)` correctly treats `-1978335189` as success but `Update-AllSoftware`'s console output on the same code is labelled "Updates completed (some packages may have been skipped)" — internally inconsistent messaging worth one cleanup pass. Recommended phase entry order: P1 (C1 + C2 migration), then P2 (C4 tagging — trivial, all A).

## Findings

### F1 — Mixed `Write-Host` / `Write-Ui` / `Write-SouliTEK*` (see C1)
- **Severity:** med
- **Category:** output-style
- **Location:** scripts/software_updater.ps1 — 60 raw `Write-Host` occurrences (sample lines: 85, 89, 94, 95, 117, 122, 130, 135, 137, 138, 143, 168, 171, 185, 187, 210, 226, 227, 229, 238, 239, 241, 255, 274, 277, 283, 284, 286, 287, 295, 296, 297, 377, 389, 390, 394, 399, 418, 473, 491, 494, 497, 500, 503, 506, 508, 509, 510, 524, 529, 552, 563, 573, 584, 594, 602, 612, 618). Plus 22 legacy `Write-SouliTEK*` wrapper calls (lines 70, 84, 101, 112, 116, 129, 149, 164, 213, 216, 220, 259, 270, 298, 307, 366, 403, 417, 472, 478, 570, 591, 626) exercising C2's dead API.
- **Reference:** [C1](00-cross-cutting.md#c1--raw-write-host-calls-not-migrated-to-write-uiwrite-status)
- **Current (representative pattern — inline-color separator at lines 138 + 143):**
  ```powershell
  Write-Host "============================================================" -ForegroundColor Gray
  $upgradeList -split "`n" | ForEach-Object {
      if ($_ -match "^\s*$") { return }
      Write-Ui -Message "  $_" -Level "INFO"
  }
  Write-Host "============================================================" -ForegroundColor Gray
  ```
- **Recommended:** Migrate the separator bars to a `Show-Section` / `Show-SouliTEKHeader -Divider` helper (visual separator helpers are exempt per C1), and replace bare `Write-Host ""` spacers either with a `Write-Ui -Spacer` helper (if added in P4) or leave them as-is under the same separator exemption. Migrate the 22 `Write-SouliTEK*` calls to the canonical level-tagged form:
  ```powershell
  Write-Ui -Message "WinGet is available on this system" -Level "OK"
  Write-Ui -Message "WinGet is not available on this system" -Level "WARN"
  Write-Ui -Message "Error checking WinGet availability: $($_.Exception.Message)" -Level "ERROR"
  ```
- **Risk if changed:** Low — message text preserved verbatim; the `[LEVEL]` bracket emitted by `Write-Ui` replaces the manual color formatting. Per-category breakdown below.
- **Local notes:** Three categories of raw `Write-Host`:
  1. **Blank-line spacers** — bare `Write-Host ""` used as vertical spacing (lines 85, 89, 94, 96, 117, 122, 130, 137, 144, 168, 171, 185, 187, 210, 226, 229, 238, 241, 255, 274, 277, 283, 287, 295, 297, 377, 394, 399, 418, 473, 491, 494, 497, 500, 503, 506, 508, 510, 524, 529, 552, 563, 573, 584, 594, 602, 612, 618). Not C1 violations per the "visual separator helpers" exception; can stay as-is or fold into a future `Write-Ui -Spacer`.
  2. **Inline-color separators / status writes** — `Write-Host "===…===" -ForegroundColor Cyan|Gray` (lines 138, 143, 284, 286, 296, 509) and the two-part `Write-Host "  " -NoNewline` + label patterns (lines 135, 227, 239) and the status-color pair `Write-Host "      Status:   " -NoNewline -ForegroundColor Gray` + `Write-Host "$statusText" -ForegroundColor $statusColor` (lines 389–390). The separator bars are arguably C1-exempt as visual separators; the status pair is a real C1 violation — migrate to `Write-Ui -Message "      Status:   $statusText" -Level $(if ($entry.Success) { 'OK' } else { 'ERROR' })`.
  3. **Plain message lines** — only one in the whole script: `Write-Host "  [!] Or download from: https://aka.ms/getwinget" -ForegroundColor Yellow` (line 95). Clear C1 violation — migrate to `Write-Ui -Message "Or download from: https://aka.ms/getwinget" -Level "WARN"`.
- **Local notes (cont.) — inline marker prefixes:** Many `Write-Ui` calls in this script already double-mark with embedded `[*]`/`[!]` prefixes inside the message string (lines 76, 86, 87, 88, 90, 91, 92, 93, 120, 121, 169, 170, 184, 186, 214, 217, 218, 221, 275, 276, 278, 367, 376, 398, 490, 492, 493, 495, 496, 498, 499, 501, 502, 504, 505, 507, 548, 549, 560, 561, 562, 581, 582, 583, 619). Same anti-pattern as F2 of `01-modules-SouliTEK-Common.md` — when the C1 sweep runs, strip these inline markers so the `[LEVEL]` bracket emitted by `Write-Ui` is the only marker.
- **Local notes (cont.) — legacy API callers:** 22 calls to the C2 dead API (`Write-SouliTEKInfo`/`Success`/`Warning`/`Error`). These must be migrated to `Write-Ui` before C2's "delete the five legacy functions from the module" step can land.
- **Target phase:** P1

### F2 — `-ErrorAction SilentlyContinue` triage (see C4)
- **Severity:** med
- **Category:** error-handling
- **Location:** scripts/software_updater.ps1 — 5 occurrences
- **Reference:** [C4](00-cross-cutting.md#c4----erroraction-silentlycontinue-swallowing-failures)
- **Triage:**
  - Line 68: tag **A** — `Get-Command winget.exe -ErrorAction SilentlyContinue` is a probe; the result is immediately tested with `if ($wingetPath)` to set `$Script:WinGetAvailable`. Legitimate "does this command exist?" check (same pattern as line 109 of `driver_integrity_scan.ps1`). Add `# safe: probe` comment in P2.
  - Line 207: tag **A** — `Get-Content $outputFile -Raw -ErrorAction SilentlyContinue` reads the redirected stdout file after `Start-Process -RedirectStandardOutput`. The file may be empty/absent if winget produced no stdout; `$output` is then checked with `if ($output -and $output.Trim() -ne "")` before use (line 225). Legitimate. Add `# safe: optional read` comment.
  - Line 208: tag **A** — `Get-Content $errorFile -Raw -ErrorAction SilentlyContinue` — same pattern as line 207 for stderr; guarded by `if ($errors -and $errors.Trim() -ne "" …)` on line 237. Legitimate. Add `# safe: optional read` comment.
  - Line 252: tag **A** — `Remove-Item $outputFile -ErrorAction SilentlyContinue` is post-use cleanup of the temp file. Pure C4-tag-A "delete temp file if exists." Add `# safe: cleanup` comment.
  - Line 253: tag **A** — `Remove-Item $errorFile -ErrorAction SilentlyContinue` — same as line 252. Add `# safe: cleanup` comment.
- **Local notes:** All 5 occurrences are tag **A** (same all-A profile as `driver_integrity_scan.ps1`). Bonus: note that the temp-file cleanup at lines 252–253 only runs on the success path of `Update-AllSoftware`; if the `try` block throws between lines 190 and 251 (e.g. `Start-Process` failure), the temp files leak. Not a C4 issue per se, but worth a `try { … } finally { Remove-Item … }` restructuring in the same pass that adds the `# safe: cleanup` comment.
- **Target phase:** P2

### F3 — No `[CmdletBinding()]` on script or any function
- **Severity:** low
- **Category:** structure
- **Location:** scripts/software_updater.ps1 — script-level (top of file, no `param()` block at all) and every one of the 9 internal functions (`Get-WinGetAvailability` line 62, `Get-AvailableUpdates` line 106, `Update-AllSoftware` line 154, `Update-SoftwareInteractive` line 264, `Save-UpdateHistory` line 312, `Show-UpdateHistory` line 360, `Export-UpdateReport` line 407, `Show-Menu` line 483, `Main` line 517).
- **Local notes:** `Update-AllSoftware` already has `param([switch]$Silent)` (line 159–161) but the `$Silent` parameter is never referenced in the function body — it's a dead parameter that pre-dates the always-silent `--silent --disable-interactivity` argument list (line 175–182). `Save-UpdateHistory` has a real `param()` block with `TimeSpan`, `int`, and `switch` (lines 317–321). Adding `[CmdletBinding()]` to `Update-AllSoftware`, `Save-UpdateHistory`, and `Show-UpdateHistory` would let those accept `-Verbose` / `-ErrorAction` from callers; the script-level entry point doesn't need one because there's no `param()` block to bind. The dead `$Silent` switch should be removed (or wired to skip the `--silent` arg if it ever needs to do something).
- **Target phase:** P4

### F4 — `Split-Path -Parent $MyInvocation.MyCommand.Path` instead of `$PSScriptRoot`
- **Severity:** low
- **Category:** structure
- **Location:** scripts/software_updater.ps1:41
- **Current:**
  ```powershell
  $ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
  ```
- **Recommended:**
  ```powershell
  $ScriptRoot = $PSScriptRoot
  ```
- **Risk if changed:** Low. Same finding as F5 of `scripts-driver_integrity_scan.md`. `$PSScriptRoot` is the canonical PS 3.0+ automatic variable for "directory of the running script." `$MyInvocation.MyCommand.Path` returns `$null` when the script is dot-sourced. C10 will eventually replace this whole block with `Import-SouliTEKCommon`, but until then this one-line fix is free.
- **Target phase:** P4 (fold into the C10 sweep)

### F5 — Infinite menu loop with no non-interactive exit + blocking `Read-Host` prompts
- **Severity:** low
- **Category:** structure (UX / RMM safety)
- **Location:** scripts/software_updater.ps1:536 (`do { ... } while ($true)`), plus `Read-Host` calls at lines 279, 530, 534, 538, 553, 565, 574, 586, 595, 603, 613.
- **Local notes:** Same finding profile as F6 of `scripts-driver_integrity_scan.md`. The script is interactive-only — the only graceful exit is menu option `[0]` which calls `exit` (line 622). Under SYSTEM-context RMM execution (flagged in user's CLAUDE.md as a deployment scenario), `Read-Host` will hang the worker process. There is no `[Environment]::UserInteractive` gate and no `-NonInteractive` switch. Particularly notable here because the script's purpose (run `winget upgrade --all`) is exactly the kind of thing an RMM operator would *want* to fire non-interactively — adding a `-Silent -Confirm:$false` parameterised entry point (a P3 follow-up) would make this script directly callable from RMM without rewriting the menu.
- **Target phase:** P4 (P3 if a parameterised entry point is added — see Out-of-scope C5 discussion)

### F6 — Hard-coded Desktop output path with no override
- **Severity:** info
- **Category:** structure
- **Location:** scripts/software_updater.ps1:54 (`$Script:OutputDir = "$env:USERPROFILE\Desktop"`), consumed by `Export-UpdateReport` at line 415.
- **Local notes:** Identical to F7 of `scripts-driver_integrity_scan.md`. The TXT report target is hard-coded to the current user's Desktop. Breaks under SYSTEM context (`$env:USERPROFILE` resolves to `C:\Windows\System32\config\systemprofile` and the Desktop folder may not exist) and offers no way to redirect the export. Low priority because the menu-driven design assumes interactive use, but a `-OutputDirectory` parameter on `Export-UpdateReport` would be a clean follow-up alongside F3's `[CmdletBinding()]` add. Note: `$Script:UpdateHistoryFile` (line 55) uses `$env:LOCALAPPDATA` which is the right idiom and handles per-user paths correctly.
- **Target phase:** P4

### F7 — `Update-SoftwareInteractive` records `ExitCode = 0` unconditionally
- **Severity:** med
- **Category:** correctness
- **Location:** scripts/software_updater.ps1:291 + 302
- **Current:**
  ```powershell
  $startTime = Get-Date
  winget upgrade --all
  $endTime = Get-Date
  $duration = $endTime - $startTime
  …
  Save-UpdateHistory -Duration $duration -ExitCode 0 -Interactive
  ```
- **Recommended:**
  ```powershell
  $startTime = Get-Date
  winget upgrade --all
  $exitCode = $LASTEXITCODE
  $endTime = Get-Date
  $duration = $endTime - $startTime
  …
  Save-UpdateHistory -Duration $duration -ExitCode $exitCode -Interactive
  ```
- **Risk if changed:** Low. Capturing `$LASTEXITCODE` directly after the native-command invocation is the standard PowerShell idiom for non-`Start-Process` external calls. Without it, the JSON history's `Success` field for every interactive session is permanently `true` regardless of what actually happened — silently masking real failures and corrupting the only audit trail this script keeps. The catch block on line 306–308 also won't fire on a non-zero winget exit (native commands don't throw on non-zero), so this is the only place the real outcome can be observed.
- **Local notes:** Pair this with a guard for the `Read-Host` on line 279 that gates entry — if a user types Ctrl+C during the interactive winget run, control returns to the outer `try`/`catch` cleanly, but the success message on line 298 still fires. The exit code capture above naturally fixes both.
- **Target phase:** P2

### F8 — Inconsistent messaging on WinGet exit code `-1978335189`
- **Severity:** info
- **Category:** correctness / UX
- **Location:** scripts/software_updater.ps1:215–218 + 342
- **Local notes:** `Save-UpdateHistory` records `Success = ($ExitCode -eq 0 -or $ExitCode -eq -1978335189)` (line 342) — both codes counted as success. `Update-AllSoftware` correctly handles both codes (lines 212–222) but labels the `-1978335189` branch "Updates completed (some packages may have been skipped)" with an additional `[!] Note: Exit code -1978335189 often indicates no updates or partial success` warning (line 218). The two messages disagree internally: the history file says "success" while the on-screen warning suggests partial failure. For reference, `-1978335189` is `0x8A150033` = `APPINSTALLER_CLI_ERROR_NO_APPLICABLE_UPDATE_FOUND` (a.k.a. "no updates available") per [the winget source](https://github.com/microsoft/winget-cli/blob/master/src/AppInstallerSharedLib/Public/AppInstallerErrors.h). It is unambiguously "everything you asked about is already up to date" — there's no "partial" about it. Recommend simplifying the line 215–218 branch to:
  ```powershell
  } elseif ($upgradeProcess.ExitCode -eq -1978335189) {
      Write-Ui -Message "All applicable packages are already up to date" -Level "OK"
      Write-Ui -Message "Duration: $($duration.Minutes) minutes, $($duration.Seconds) seconds" -Level "INFO"
  }
  ```
  Bundle this with the F1 / F7 / Update-AllSoftware refactor in the same pass.
- **Target phase:** P2 (alongside F7)

### F9 — Dead `[switch]$Silent` parameter on `Update-AllSoftware`
- **Severity:** info
- **Category:** structure (dead code)
- **Location:** scripts/software_updater.ps1:159–161
- **Local notes:** `Update-AllSoftware` declares `param([switch]$Silent)` but the `$Silent` variable is never referenced anywhere in the function body — the `winget` invocation always passes `--silent --disable-interactivity` (lines 175–182). Either remove the parameter or wire it (e.g. `if (-not $Silent) { … omit --silent … }`). The cleaner answer is removal, since the function name itself implies the silent mode and the contrasting `Update-SoftwareInteractive` exists separately.
- **Target phase:** P4

## Out-of-scope notes
- **C5 — `SupportsShouldProcess` applicability decision: NO (do not add).** The task plan flagged this question explicitly. The script does shell out to a destructive command (`winget upgrade --all`), but: (a) all mutation is delegated to WinGet itself, which has its own confirmation surface (`--silent` / `--disable-interactivity` are passed explicitly to opt *out* of WinGet's prompts — adding `ShouldProcess` on top would be a confirm-the-confirm pattern); (b) the script's only direct file mutations are its own JSON history (`%LOCALAPPDATA%\SouliTEK\UpdateHistory.json`) and the Desktop TXT report — neither is destructive in any meaningful sense (`Set-Content -Force` of a SouliTEK-owned artifact); (c) the script is already gated by an interactive Y/N confirm at line 565 (`$confirm = Read-Host "Continue with automatic update? (Y/N)"`) before reaching `Update-AllSoftware`. C5 targets scripts that write to *Windows*-owned state (registry, services, network adapters) without an opt-in safety net; this script writes only to its own files and delegates the system-changing call to WinGet. Recommendation: leave C5 off, but **do** consider adding a parameterised non-interactive entry point in P3 (`software_updater.ps1 -Mode AutoUpdate -Confirm:$false`) so RMM scenarios don't have to fake `Read-Host` input — that change can independently add `[CmdletBinding(SupportsShouldProcess)]` to the new entry function without modifying the existing menu path. None of this is a C5-tracked obligation.
- Banner block (lines 1–32, 26 lines of `# === / Coded by / IMPORTANT DISCLAIMER`) matches C11 cross-cutting cleanup; covered there.
- The `Save-UpdateHistory` JSON-persist pattern (lines 312–358) is clean: creates the parent directory if missing, caps to the last 50 entries, uses `ConvertTo-Json -Depth 10`, and the surrounding `try { ... } catch { Write-Verbose "Could not save update history: $_" }` is appropriately quiet for a non-essential cache write. Same shape as `Save-ScanResults` in `driver_integrity_scan.ps1` — both would benefit from a shared `Save-SouliTEKHistory` helper in the module (P4 candidate alongside C10).
- The `Start-Process winget.exe ... -RedirectStandardOutput ... -RedirectStandardError ... -Wait -PassThru` pattern (lines 195–201) on `Update-AllSoftware` is the right shape and `--disable-interactivity` is correctly included so the wrapped winget call won't hang on a Y/N prompt — same idiom as lines 425–431 of `driver_integrity_scan.ps1`. The two scripts have effectively duplicated this block; another P4 module-helper candidate (`Invoke-SouliTEKWinGet`).
- The `Get-WinGetAvailability` function (lines 62–104) is also effectively duplicated from `driver_integrity_scan.ps1`'s identically-named function. Genuinely shared behaviour — move to the common module (P4).
- The `$Host.UI.RawUI.WindowTitle = "SOFTWARE UPDATER"` on line 38 is harmless and matches the convention used by other scripts in the suite; not a finding.
- The script does not use `Get-WmiObject` (C3 does not apply here) and does not call any `netsh` (C14 does not apply).
