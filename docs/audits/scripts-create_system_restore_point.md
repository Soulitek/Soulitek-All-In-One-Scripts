# Audit — scripts/create_system_restore_point.ps1

## Inventory
| Item | Value |
|---|---|
| Path           | scripts/create_system_restore_point.ps1 |
| LOC            | 393 |
| Functions      | 8 |
| `#Requires`    | none (no `#Requires -RunAsAdministrator`, no `#Requires -Version`) |
| Admin-required | yes (calls `Checkpoint-Computer` and `vssadmin create shadow`, both of which require an elevated token; the script gates entry on `Test-SouliTEKAdministrator` at line 381 and again inside `New-SystemRestorePoint` at line 129) |
| Last touched   | 8675720 — 2026-04-17 |
| Modernization grade | C |

## Summary

A menu-driven System Restore Point management tool: creates restore points via `Checkpoint-Computer` (line 154) with a `vssadmin create shadow` fallback (line 173), lists existing restore points via `Get-ComputerRestorePoint`, and reports protection status by parsing `vssadmin list volumes` output. The mutation surface is narrow but real — every successful run leaves a persistent system artifact (a restore point or VSS shadow copy on the system drive), so C5 (`SupportsShouldProcess` + `-WhatIf`/`-Confirm`) genuinely applies even though there is no registry or service mutation. Primary issues: (1) 34 raw `Write-Host` calls (C1), all of which are `Write-Host ""` blank-line spacers or `Write-Host "Press Enter to return to menu..."` prompts — i.e. C1 violations of the "plain prompt line" subtype, not the inline-color subtype seen in driver_integrity_scan; (2) the script is flagged in C5 as one of six destructive scripts lacking `SupportsShouldProcess`, and that holds — both `Checkpoint-Computer` (line 154) and the `vssadmin create shadow` fallback (line 173) execute unconditionally inside their `try` blocks with no `ShouldProcess` gate; (3) `Write-Ui -Message ("-" * 80) -Level "INFO"` and `Write-Ui -Message ("=" * 80) -Level "INFO"` (lines 220, 258) use `Write-Ui` to draw separator rules, which double-stamps each rule with an `[INFO]` bracket — should use `Show-Section` or a raw `Write-Host` spacer instead. Secondary concerns: no `[CmdletBinding()]` on the script or any function (the script has no `param()` block at all); the script uses `Split-Path -Parent $MyInvocation.MyCommand.Path` instead of `$PSScriptRoot` (line 38, same as F5 of driver_integrity_scan); the main loop is an unconditional `while ($true)` with `Read-Host` gates that would hang under SYSTEM/RMM execution; C11 banner block occupies the first 32 lines. The three `-ErrorAction SilentlyContinue` occurrences are all defensible probes and all carry triage tag **A**. No `Get-WmiObject` (C3 does not apply). No `Write-SouliTEK*` legacy API callers (C2 does not apply). Recommended phase entry order: P1 (C1), then P2 (C4 triage), then P3 (C5 — this is the priority destructive-script for `SupportsShouldProcess` because the mutation surface is small enough to wrap cleanly).

## Findings

### F1 — Missing `[CmdletBinding(SupportsShouldProcess)]` on destructive entry points (see C5)
- **Severity:** high
- **Category:** safety
- **Location:** scripts/create_system_restore_point.ps1 — `New-SystemRestorePoint` declaration (lines 111–122) and `Start-MainLoop` (line 302). Both mutation call sites (`Checkpoint-Computer` line 154, `Start-Process vssadmin ... create shadow ...` line 173) execute without a `ShouldProcess` gate.
- **Reference:** [C5](00-cross-cutting.md#c5--destructive-scripts-lack-cmdletbindingsupportsshouldprocess---whatif-confirm)
- **Current (line 154, the primary mutation call):**
  ```powershell
  $result = Checkpoint-Computer -Description $Description -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop
  ```
- **Current (line 173, the fallback mutation call):**
  ```powershell
  $vssResult = Start-Process -FilePath "vssadmin" -ArgumentList "create", "shadow", "/For=$env:SystemDrive" -Wait -NoNewWindow -PassThru -ErrorAction Stop
  ```
- **Recommended:**
  ```powershell
  function New-SystemRestorePoint {
      [CmdletBinding(SupportsShouldProcess, ConfirmImpact='Medium')]
      param(
          [string]$Description = "SouliTEK Manual Restore Point"
      )
      ...
      if ($PSCmdlet.ShouldProcess($env:SystemDrive, "Create system restore point: $Description")) {
          $result = Checkpoint-Computer -Description $Description -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop
      }
      ...
      if ($PSCmdlet.ShouldProcess($env:SystemDrive, "Create VSS shadow copy (vssadmin fallback)")) {
          $vssResult = Start-Process -FilePath "vssadmin" -ArgumentList "create", "shadow", "/For=$env:SystemDrive" -Wait -NoNewWindow -PassThru -ErrorAction Stop
      }
  }
  ```
- **Local notes:** `ConfirmImpact='Medium'` rather than `'High'` because a system restore point is itself a recovery primitive — accidental creation is annoying (consumes shadow-copy space, may evict the oldest point) but never destroys data. The five other scripts in the C5 list (`essential_tweaks`, `win11_debloat`, `temp_removal_disk_cleanup`, `mcafee_removal_tool`, `network_configuration_tool`) all warrant `'High'` because they mutate registry/services/files. This script's `Medium` rating is the correct nuance.
- **Local notes (cont.) — C5 applicability judgment:** The task brief flagged this as "C5 borderline" and asked whether enabling restore-protection on a drive counts. Reading the script end-to-end, there is **no** `Enable-ComputerRestore` call and **no** `Set-ItemProperty` writing to `HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore`. The script reads `RPSessionInterval` (line 77) but never writes it. The only side effects are (a) creating a restore point and (b) creating a VSS shadow copy. Both leave persistent artifacts on the system drive that survive reboot, so C5 still applies — the artifact's persistence and disk-space consumption are the destructive surface, not protection-enablement. The cross-cutting C5 entry's `Files affected` list (00-cross-cutting.md:72) already names this script; that classification is correct.
- **Local notes (cont.) — propagation to caller:** Adding `SupportsShouldProcess` to `New-SystemRestorePoint` means `Start-MainLoop` (lines 312, 334) should also pass `-Confirm:$false` when calling from the menu, otherwise the menu will trigger the confirmation prompt on every "create" action. The interactive menu already *is* the user confirmation, so suppressing the inner prompt is correct. A future non-interactive `-Force` switch on the script wrapper (paired with `[CmdletBinding(SupportsShouldProcess)]` at script level) would let CI/RMM callers invoke the script with `-WhatIf` or `-Confirm:$false`.
- **Risk if changed:** Low for the menu path (the existing `Read-Host "Continue anyway?"` flow already gates the action). Medium for any future programmatic caller because `ShouldProcess` raises a confirmation prompt by default — must be paired with `-Confirm:$false` from the menu wrapper.
- **Target phase:** P3

### F2 — Raw `Write-Host` calls not migrated (see C1)
- **Severity:** med
- **Category:** output-style
- **Location:** scripts/create_system_restore_point.ps1 — 34 raw `Write-Host` occurrences (lines 126, 132, 141, 151, 158, 161, 168, 199, 206, 211, 224, 238, 249, 254, 273, 284, 290, 315, 316, 319, 320, 325, 337, 338, 341, 342, 348, 349, 354, 355, 363, 365, 384, 386).
- **Reference:** [C1](00-cross-cutting.md#c1--raw-write-host-calls-not-migrated-to-write-uiwrite-status)
- **Current (representative pattern — prompt lines 316, 320, 338, 342, 349, 355):**
  ```powershell
  Write-Host ""
  Write-Host "Press Enter to return to menu..."
  Read-Host | Out-Null
  ```
- **Recommended:**
  ```powershell
  Write-Ui -Message "Press Enter to return to menu..." -Level "INFO"
  Read-Host | Out-Null
  ```
- **Risk if changed:** Low — message text preserved verbatim; the `[INFO]` bracket emitted by `Write-Ui` replaces the bare line.
- **Local notes:** Two categories of raw `Write-Host`:
  1. **Blank-line / spacer calls** — bare `Write-Host ""` used as vertical spacing. 28 occurrences: lines 126, 132, 141, 151, 158, 161, 168, 199, 206, 211, 224, 238, 249, 254, 273, 284, 290, 315, 319, 325, 337, 341, 348, 354, 363, 365, 384, 386. Per the C1 "visual separator helpers" exception, these are not strict C1 violations but are noisy — fold into a `Write-Ui -Spacer` / `Show-Section` helper when added in P4.
  2. **Plain "Press Enter" prompt lines** — 6 occurrences at lines 316, 320, 338, 342, 349, 355, each immediately followed by `Read-Host | Out-Null`. Real C1 violations: should be `Write-Ui -Message "Press Enter to return to menu..." -Level "INFO"` (or absorbed into a `Wait-SouliTEKKeyPress` wrapper if/when that helper is repurposed). Note: line 316/320 and 338/342 are duplicated pairs — the `if ($success) { ... } else { ... }` branches both print the same prompt, which is dead branching that should be lifted out of the `switch` (see F7).
- **Local notes (cont.) — separator-rule misuse of `Write-Ui`:** Two `Write-Ui` calls draw separator rules with `("-" * 80)` (line 220) and `("=" * 80)` (line 258) as the message body. This produces output like `[INFO]  --------------------------------------------------------------------------------` — the `[INFO]` bracket double-stamps a visual rule. Fix in the same P1 sweep: use raw `Write-Host ("-" * 80) -ForegroundColor DarkGray` or call `Show-Section` instead.
- **Target phase:** P1

### F3 — `-ErrorAction SilentlyContinue` triage (see C4)
- **Severity:** med
- **Category:** error-handling
- **Location:** scripts/create_system_restore_point.ps1 — 3 occurrences
- **Reference:** [C4](00-cross-cutting.md#c4----erroraction-silentlycontinue-swallowing-failures)
- **Triage:**
  - Line 61: tag **A** — `$protectionStatus = Get-ComputerRestorePoint -ErrorAction SilentlyContinue` inside `Test-SystemRestoreEnabled`. The result is immediately tested with `if (-not $protectionStatus)`, which falls through to the `vssadmin list volumes` fallback. Legitimate "probe — does this command return data?" check. Add `# safe: probe` comment in P2.
  - Line 77: tag **A** — `Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore" -Name "RPSessionInterval" -ErrorAction SilentlyContinue` is a registry probe; the return is compared against `$null` (`return ($null -ne $restoreStatus)`). Legitimate "does this key exist?" check. Add `# safe: probe` comment.
  - Line 92: tag **A** — `$restorePoints = Get-ComputerRestorePoint -ErrorAction SilentlyContinue` inside `Get-RestorePoints`. Same pattern as line 61 — checked with `if (-not $restorePoints)` and falls through to `vssadmin list shadows`. Legitimate. Add `# safe: probe` comment.
- **Local notes:** All three occurrences are tag-A probes around the same `Get-ComputerRestorePoint` / registry-key resilience pattern. The script is defensive about the fact that `Get-ComputerRestorePoint` returns nothing (rather than throwing) when System Restore is disabled — this is correct Windows behavior and the `SilentlyContinue` is belt-and-braces around an already-quiet cmdlet. None of these need the C4 tag-B/C upgrade.
- **Target phase:** P2

### F4 — No `[CmdletBinding()]` on script or any function
- **Severity:** low
- **Category:** structure
- **Location:** scripts/create_system_restore_point.ps1 — script-level (top of file, no `param()` block) and all 8 internal functions (`Test-SystemRestoreEnabled` line 53, `Get-RestorePoints` line 85, `New-SystemRestorePoint` line 111, `Show-RestorePoints` line 190, `Show-SystemRestoreStatus` line 227, `Show-MainMenu` line 280, `Show-ExitMessage` line 298, `Start-MainLoop` line 302).
- **Local notes:** `New-SystemRestorePoint` already has a `param([string]$Description = "...")` block (lines 120–122), so adding `[CmdletBinding()]` to it is a free win — and once F1 is applied it gains `[CmdletBinding(SupportsShouldProcess, ConfirmImpact='Medium')]` anyway. The script-level absence is more important: a `param([switch]$Quiet, [switch]$Force)` block at the top would let the launcher invoke this script non-interactively for a "create a checkpoint before this destructive operation" workflow, which is the natural pairing with the other C5 scripts.
- **Target phase:** P4 (or P3 if folded into the F1/C5 sweep — recommended)

### F5 — `Split-Path -Parent $MyInvocation.MyCommand.Path` instead of `$PSScriptRoot`
- **Severity:** low
- **Category:** structure
- **Location:** scripts/create_system_restore_point.ps1:38
- **Current:**
  ```powershell
  $ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
  ```
- **Recommended:**
  ```powershell
  $ScriptRoot = $PSScriptRoot
  ```
- **Risk if changed:** Low. Identical to F5 of driver_integrity_scan — `$PSScriptRoot` is the canonical PS 3.0+ automatic variable; `$MyInvocation.MyCommand.Path` returns `$null` when dot-sourced. C10 will eventually replace this block.
- **Target phase:** P4 (fold into the C10 sweep)

### F6 — Infinite menu loop with no non-interactive exit + blocking `Read-Host` prompts
- **Severity:** low
- **Category:** structure (UX / RMM safety)
- **Location:** scripts/create_system_restore_point.ps1:303 (`while ($true)`), plus `Read-Host` calls at lines 133, 142, 306, 317, 321, 326, 339, 343, 350, 356, 387.
- **Local notes:** Identical concern to F6 of driver_integrity_scan: menu-driven design with no `[Environment]::UserInteractive` gate. Under SYSTEM-context RMM execution, every one of these `Read-Host` calls will hang the worker process. The script *intends* a quick "create one restore point then exit" path (menu option 1 with description auto-filled to timestamp) but still routes through the post-action "Press Enter to return to menu" prompt — there is no `-Once` / `-Quiet` switch. This pairs with F4 (script-level `param()` block adds non-interactive surface) and with C5 (a `-Force` switch on the script wrapper bypasses `Read-Host "Continue anyway? (Y/N)"` at line 142). Defer to P4 unless an RMM hang surfaces, but folding into the F1/F4 P3 sweep is the natural opportunity.
- **Target phase:** P4 (or P3 if folded into F1)

### F7 — Dead duplicate branches in `Start-MainLoop` menu choices `1` and `2`
- **Severity:** info
- **Category:** structure (correctness)
- **Location:** scripts/create_system_restore_point.ps1:314–322 (choice `1`), 336–344 (choice `2`).
- **Current:**
  ```powershell
  if ($success) {
      Write-Host ""
      Write-Host "Press Enter to return to menu..."
      Read-Host | Out-Null
  } else {
      Write-Host ""
      Write-Host "Press Enter to return to menu..."
      Read-Host | Out-Null
  }
  ```
- **Recommended:**
  ```powershell
  Write-Host ""
  Write-Host "Press Enter to return to menu..."
  Read-Host | Out-Null
  ```
- **Local notes:** Both branches of the `if ($success)` test execute identical code. The success/failure differentiation is already surfaced inside `New-SystemRestorePoint` via `Write-Ui -Level "OK"` vs `-Level "ERROR"`, so the menu-level branch was probably scaffolded with the intent to add e.g. a "View created restore point" follow-up on success — but the follow-up was never wired up. The branch should be flattened, both for readability and so the F2 C1 cleanup only has to fix the prompt once per choice rather than twice.
- **Target phase:** P4 (cosmetic)

### F8 — `Show-RestorePoints` may iterate a non-collection when `Get-ComputerRestorePoint` returns a single object
- **Severity:** info
- **Category:** correctness
- **Location:** scripts/create_system_restore_point.ps1:203, 210, 214
- **Local notes:** Line 203 reads `if ($restorePoints.Count -eq 0)`. If `Get-ComputerRestorePoint` returns exactly one restore point, PS 5.1 returns a single `ManagementObject` (not an array), and `$restorePoints.Count` returns `1` only because PS 3.0+ unified `.Count` semantics — but `$restorePoints | Sort-Object CreationTime -Descending` on a single non-array object still works, so this is benign on supported versions. Worth a `@(...)` wrap (`$restorePoints = @(Get-RestorePoints)`) for defensive normalization, especially under PS 7 where the property surface from `Get-ComputerRestorePoint` may differ slightly. Not a real bug today.
- **Target phase:** —

## Out-of-scope notes
- Banner block (lines 1–32) matches C11 cross-cutting cleanup; covered there.
- The vssadmin-fallback pattern (lines 170–184) is appropriate: it catches `Checkpoint-Computer` failure and tries `vssadmin create shadow` as a last-resort. The `try { Start-Process ... -ErrorAction Stop ; if ($vssResult.ExitCode -eq 0) ... } catch { Write-Ui "Alternative method failed" }` structure correctly distinguishes "vssadmin was unreachable" from "vssadmin ran but failed." This is one of the cleaner error-handling patterns in the script.
- The `Test-SystemRestoreEnabled` function (lines 53–83) uses three independent detection paths (`Get-ComputerRestorePoint`, `vssadmin list volumes` parsing, registry key probe). Mildly redundant but each guard covers a different failure mode (missing cmdlet, vssadmin disabled, registry key removed). Keep.
- The `-NoNewWindow` switch on `Start-Process vssadmin` (line 173) is the right call here — avoids a flicker window mid-banner.
- `Show-SouliTEKExitMessage` (line 299) is called via the module's published API. No change needed.
- The `RestorePointType "MODIFY_SETTINGS"` (line 154) is the correct enumeration value for a user-initiated checkpoint (other values: `APPLICATION_INSTALL`, `APPLICATION_UNINSTALL`, `DEVICE_DRIVER_INSTALL`, `CANCELLED_OPERATION`). `MODIFY_SETTINGS` is the right semantic choice for "user clicked 'create restore point' from a menu."
- Note that on consumer Windows 10/11, the OS imposes a 24-hour throttle on restore-point creation — a second call within the window will succeed silently but won't actually create a second point. The script does not document this; a `Write-Ui "Note: Windows throttles restore-point creation to once per 24 hours"` hint after a successful create would be a useful UX improvement but is not in scope here.
- The trailing blank line at the end of the file (line 393) is harmless.
