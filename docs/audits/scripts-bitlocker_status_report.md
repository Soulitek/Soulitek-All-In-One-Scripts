# Audit — scripts/bitlocker_status_report.ps1

## Inventory
| Item | Value |
|---|---|
| Path           | scripts/bitlocker_status_report.ps1 |
| LOC            | 589 |
| Functions      | 11 |
| `#Requires`    | none (no `#Requires -RunAsAdministrator`, no `#Requires -Version`; admin is enforced at runtime via `Assert-BitLockerAdmin` calling `Test-SouliTEKAdministrator`) |
| Admin-required | yes (queries `Get-BitLockerVolume`, which requires elevated privileges to read protector/recovery-password material; `Assert-BitLockerAdmin` exits with code 1 if not elevated) |
| Last touched   | 8675720 — 2026-04-17 |
| Modernization grade | B |

## Summary

A menu-driven BitLocker status / recovery-key tool: enumerates volumes with `Get-BitLockerVolume`, prints encryption status, displays recovery keys on screen, exports recovery keys and audit reports to the Desktop, and runs a basic security-coverage audit. The script is structurally cleaner than most of the repo — it already uses `Get-BitLockerVolume` (no `Get-WmiObject`, so **no C3 applies**), has **zero `-ErrorAction SilentlyContinue` occurrences** (so **no C4 triage needed**), uses `Write-Ui` consistently for level-tagged status output (40 occurrences), and wraps the main loop in a single `try { ... } catch` for fatal-error handling. The main residual issues are (1) 123 raw `Write-Host` calls — the highest count in the repo — most of which are blank-line spacers or plain unstyled text that does not need color formatting but does drift from STYLE_GUIDE.md (C1); (2) **recovery keys are printed to stdout in plaintext** by `Show-RecoveryKeys` (line 218) and `Show-DetailedReport` (line 357), with no masking option and no consent gate — this is the dominant security concern in the file and is raised as F3 below; (3) no `[CmdletBinding()]` and no `param()` block anywhere, including on `Export-RecoveryKeys` which performs a sensitive disk write (C5 candidate even though it doesn't mutate system state); (4) missing `#Requires -RunAsAdministrator` despite hard admin dependency — the runtime check via `Assert-BitLockerAdmin` works but `#Requires` is the canonical guard and fails earlier; (5) C10/C11 boilerplate at the top, same as every other script. The recovery-key handling on the **export** path (`Export-RecoveryKeys`) is reasonable — the file is written to the user's Desktop with a timestamped name and a `WARNING` header inside the file body — but it is plaintext-on-disk with no DPAPI / `Protect-SouliTEKSecret` option and no `Test-SafeFilePath` validation of the computed path. Recommended phase entry order: P1 (C1 sweep + F3 masking), then P3 (`[CmdletBinding(SupportsShouldProcess)]` on `Export-RecoveryKeys`).

## Findings

### F1 — Mixed `Write-Host` / `Write-Ui` usage (see C1)
- **Severity:** med
- **Category:** output-style
- **Location:** scripts/bitlocker_status_report.ps1 — 123 raw `Write-Host` occurrences. Sample lines: 62, 78–88 (menu block), 128, 151–154, 160, 174–177, 214, 217–219, 340, 342, 344–348, 354–357, 390, 399, 402–403, 408, 413, 419, 430, 495, 497–538 (Help block). No legacy `Write-SouliTEK*` wrapper calls — clean on C2.
- **Reference:** [C1](00-cross-cutting.md#c1--raw-write-host-calls-not-migrated-to-write-uiwrite-status)
- **Current (representative pattern — inline-color formatting at line 151–152):**
  ```powershell
  Write-Host "  Status: " -NoNewline
  Write-Host $encryptionStatus -ForegroundColor $statusColor
  ```
- **Recommended:**
  ```powershell
  $level = switch ($encryptionStatus) {
      "FullyEncrypted"       { "OK" }
      "EncryptionInProgress" { "WARN" }
      "DecryptionInProgress" { "WARN" }
      "FullyDecrypted"       { "ERROR" }
      default                { "INFO" }
  }
  Write-Ui -Message "Status: $encryptionStatus" -Level $level
  ```
- **Risk if changed:** Low. The four categories below cover the 123 occurrences. Message text preserved verbatim; the per-volume `$statusColor` switch (lines 142–148) collapses into a `$level` switch that drives `Write-Ui -Level`.
- **Local notes:** Four categories of raw `Write-Host`:
  1. **Blank-line / spacer calls** — bare `Write-Host ""` used as vertical spacing. Roughly 60 of the 123 occurrences (e.g. lines 62, 79, 87, 114, 121, 126, 129, 163, 177, 188, 192, 199, 204, 219, 229, 239, 243, 250, 311, 322, 329, 334, 343, 349, 359, 363, 376, 383, 388, 391, 404, 409, 414, 420, 431, 436, 440, 484, 493, 496, 499, 502, 506, 510, 514, 519, 524, 527, 531, 534, 538, 572, 580, 582, 585). Per the C1 "visual separator helpers" exception these are not strict violations, but they are noisy — a P4 `Show-Section` / `Write-Ui -Spacer` helper would let them collapse.
  2. **Inline-color formatting** — `Write-Host "===========" -ForegroundColor Yellow` or `-ForegroundColor Cyan` used as section dividers (lines 128, 214, 340, 342, 390, 408, 495, 501, 526, 533). Real C1 violations; replace with a `Show-Section` helper or `Write-Ui -Level "STEP"`.
  3. **Inline split-color message** — `Write-Host "  Status: " -NoNewline` + `Write-Host $encryptionStatus -ForegroundColor $statusColor` (lines 151–152, 402). Migrate to `Write-Ui -Message "Status: ..." -Level $level` per the example above.
  4. **Plain message lines** — `Write-Host "  Encryption: $encryptionPercentage%"` and similar (lines 78, 80–86, 153, 154, 160, 174–176, 217–218, 344–348, 354–357, 399, 403, 413, 419, 430, 497–538). All clear C1 violations; migrate to `Write-Ui -Message "..." -Level "INFO"` (or wrap menu/help blocks in a `Show-Menu` / `Show-Help` helper if one lands in P4).
- **Local notes (cont.) — inline marker prefixes:** Two existing `Write-Ui` calls already double-mark with embedded glyphs that duplicate the `[LEVEL]` bracket emitted by `Write-Ui`: line 412 (`Write-Ui -Message "⚠ WARNING: $unencryptedVolumes volume(s) are not encrypted." -Level "ERROR"`), line 418 (`"ℹ INFO: $encryptingVolumes volume(s)..." -Level "WARN"`), line 429 (`"⚠ WARNING: Some encrypted volumes do not have recovery keys configured." -Level "ERROR"`), line 435 (`"✓ All volumes are encrypted. Good security posture!" -Level "OK"`), and line 581 (`"[X] Fatal Error: $_" -Level "ERROR"`). Same anti-pattern as F2 of `01-modules-SouliTEK-Common.md` and the driver-scan audit — strip the inline `⚠`/`ℹ`/`✓`/`[X]` markers when the C1 sweep runs so `Write-Ui` is the sole source of level prefixes. The Unicode `⚠`/`ℹ`/`✓` glyphs are also a console-encoding hazard on non-UTF-8 hosts (cp850/cp1252) and should be removed regardless.
- **Target phase:** P1

### F2 — `-ErrorAction SilentlyContinue` triage (see C4) — none
- **Severity:** —
- **Category:** error-handling
- **Location:** scripts/bitlocker_status_report.ps1 — **0 occurrences**.
- **Reference:** [C4](00-cross-cutting.md#c4----erroraction-silentlycontinue-swallowing-failures)
- **Local notes:** The script does not use `-ErrorAction SilentlyContinue` anywhere. Both `Get-Command Get-BitLockerVolume -ErrorAction Stop` (line 49, wrapped in `try { ... } catch { return $false }` — this is the C4-tag-A probe pattern done correctly without `SilentlyContinue`) and `Get-BitLockerVolume -ErrorAction Stop` (line 97, wrapped in `try { ... } catch { Write-Ui ... -Level "ERROR"; return $null }`) follow the `try`/`catch` + `Write-Ui` pattern that C4 prescribes as the *target* state for the rest of the repo. This is exemplary and should be cited as a reference pattern when the P2 C4 sweep starts.
- **Target phase:** — (no action)

### F3 — Recovery keys printed to stdout in plaintext with no masking option
- **Severity:** high
- **Category:** security (information disclosure)
- **Location:** scripts/bitlocker_status_report.ps1:218 (`Show-RecoveryKeys`) and 357 (`Show-DetailedReport`)
- **Current (line 218):**
  ```powershell
  Write-Host "  Recovery Key: $($key.RecoveryPassword)"
  ```
- **Current (line 357):**
  ```powershell
  Write-Host "  Recovery Password: $($protector.RecoveryPassword)"
  ```
- **Recommended:** Two-part change:
  1. Print a masked form by default, gated by an explicit reveal switch:
     ```powershell
     # Show-RecoveryKeys: replace line 218
     $rk = $key.RecoveryPassword
     $display = if ($Reveal) { $rk } else { ($rk -replace '\d', 'X') }
     Write-Ui -Message "Recovery Key: $display" -Level "INFO"
     if (-not $Reveal) {
         Write-Ui -Message "(masked — use option [3] Export, or pass -Reveal to display)" -Level "WARN"
     }
     ```
     `BitLocker` recovery passwords are deterministic — `XXXXXX-XXXXXX-XXXXXX-XXXXXX-XXXXXX-XXXXXX-XXXXXX-XXXXXX` (8 groups of 6 digits separated by hyphens). Replacing every digit with `X` preserves the shape so an operator can confirm the key is present without exposing the value.
  2. Add a `[switch]$Reveal` parameter to `Show-RecoveryKeys` / `Show-DetailedReport` (requires the `[CmdletBinding()]`/`param()` work from F4) and a runtime confirmation prompt before reveal:
     ```powershell
     if ($Reveal) {
         $confirm = Read-Host "Display recovery keys in plaintext on screen? Type YES to continue"
         if ($confirm -cne 'YES') {
             Write-Ui -Message "Reveal cancelled — keys remain masked." -Level "INFO"
             $Reveal = $false
         }
     }
     ```
- **Risk if changed:** Low. The current behaviour leaks recovery material to whoever can see the console (shoulder-surf, screen-share, terminal scrollback, RMM session recording, captured stdout in a `Start-Transcript` log). The export path (`Export-RecoveryKeys`, lines 234–313) is the legitimate channel for getting the keys off the box and that path is preserved unchanged. Masking-by-default with explicit `-Reveal` and a YES-typed confirmation is a one-screen change that aligns with CLAUDE.md "fail closed — deny by default" and OWASP A09:2021 (Security Logging & Monitoring Failures) / A04:2021 (Insecure Design — sensitive data shown without explicit opt-in).
- **Local notes — additional surface to harden:**
  - **`Start-Transcript` exposure:** if the operator has `Start-Transcript` active (common on RMM hosts), the current `Write-Host "  Recovery Key: $($key.RecoveryPassword)"` writes the cleartext key into the transcript file. Masking by default removes that vector entirely.
  - **Export-path consent gate:** `Export-RecoveryKeys` (line 234) writes the keys to `$env:USERPROFILE\Desktop\BitLockerRecoveryKeys_<HOST>_<TIMESTAMP>.txt` immediately without an "Are you sure?" prompt. The destination is server-side computed (not user-controlled) so there is no path-traversal risk, but the absence of `[CmdletBinding(SupportsShouldProcess, ConfirmImpact='High')]` + `$PSCmdlet.ShouldProcess(...)` means there is no `-WhatIf` to preview and no `-Confirm` to gate. This is the C5 instance for this script (see F4). Pair the F3 reveal-gate with a `ShouldProcess` gate on the export side so both sensitive paths are explicit.
  - **DPAPI option:** consider a `-Encrypt` switch on `Export-RecoveryKeys` that calls `Protect-SouliTEKSecret` (exists in `modules/SouliTEK-Common.ps1` line 1364) instead of writing plaintext, using the machine or current-user DPAPI scope. The plaintext-Out-File path remains the default for backward compatibility, but `-Encrypt` would let the script live alongside policies that forbid plaintext key material on disk.
  - **File ACLs on the export:** the exported `.txt` file inherits Desktop ACLs (typically `Users:R` + `<owner>:F`), so any other interactive user on the box can read it. Adding a `icacls $filePath /inheritance:r /grant:r "$($env:USERNAME):(F)" /grant:r "SYSTEM:(F)" /grant:r "Administrators:(F)"` step after the `Out-File` call would lock the export to the creating user + admins. Low-priority follow-up if the masking gate lands.
- **Target phase:** P1 (paired with the C1 sweep on the same lines)

### F4 — No `[CmdletBinding()]` and no `param()` anywhere; `Export-RecoveryKeys` mutates the filesystem with no `-WhatIf` / `-Confirm` (see C5)
- **Severity:** med
- **Category:** safety / structure
- **Location:** scripts/bitlocker_status_report.ps1 — script-level (no `param()` block at all) and every one of the 11 functions (`Test-BitLockerAvailable` line 47, `Assert-BitLockerAdmin` line 58, `Show-Disclaimer` line 69, `Show-MainMenu` line 74, `Get-BitLockerInfo` line 95, `Show-BitLockerStatus` line 107, `Show-RecoveryKeys` line 183, `Export-RecoveryKeys` line 234, `Show-DetailedReport` line 316, `Show-SecurityAudit` line 370, `Show-Help` line 489).
- **Reference:** [C5](00-cross-cutting.md#c5--destructive-scripts-lack-cmdletbindingsupportsshouldprocess--whatif-confirm)
- **Local notes:** Three things this finding rolls into:
  1. **`Export-RecoveryKeys` is the C5-relevant function.** It writes recovery-key plaintext to `$env:USERPROFILE\Desktop\BitLockerRecoveryKeys_<HOST>_<TIMESTAMP>.txt` (lines 257, 298). The CLAUDE.md "fail closed — deny by default" posture and the C5 cross-cut both call for `[CmdletBinding(SupportsShouldProcess, ConfirmImpact='High')]` with `$PSCmdlet.ShouldProcess($filePath, 'Write BitLocker recovery keys to disk')` around the `Out-File` call. Same recommendation applies to the audit-report export inside `Show-SecurityAudit` (line 476) at lower impact (`ConfirmImpact='Medium'`).
  2. **`Show-RecoveryKeys` and `Show-DetailedReport` need `param([switch]$Reveal)` plus `[CmdletBinding()]`** to enable the F3 masking gate (see F3 recommendation block).
  3. **Script-level `param()`** is missing entirely. A minimal CLI surface (`param([switch]$NonInteractive, [switch]$ExportOnly, [string]$OutputDirectory)`) would let RMM call this in a one-shot "export keys to <path>" flow without the menu loop, which directly addresses the F5 RMM-hang concern below. Defer to P3/P4 alongside the broader CLI-surface work.
- **Target phase:** P3 (Export-RecoveryKeys `ShouldProcess`), P1 (the `[switch]$Reveal` param on the display functions to unlock F3)

### F5 — Infinite menu loop with blocking `Read-Host` prompts (RMM/SYSTEM-context hazard)
- **Severity:** low
- **Category:** structure (UX / RMM safety)
- **Location:** scripts/bitlocker_status_report.ps1:557 (`while ($running)`), with `Read-Host` calls at lines 63, 90, 115, 122, 179, 193, 200, 230, 244, 251, 312, 323, 330, 366, 377, 384, 441, 485, 540, 586.
- **Local notes:** 20 `Read-Host` calls, exactly the same pattern as F6 of the driver-scan audit. Under SYSTEM-context RMM execution (flagged in CLAUDE.md as a deployment scenario), `Read-Host` hangs the worker process indefinitely — there is no `[Environment]::UserInteractive` gate, no `-NonInteractive` switch, no timeout. Particularly painful here because the launcher might invoke this for an unattended "snapshot BitLocker state" capture and instead get a hung worker. Defer to P4 unless an actual RMM hang report comes in; the F4 `param([switch]$NonInteractive, [switch]$ExportOnly)` work would resolve this naturally.
- **Target phase:** P4

### F6 — `Split-Path -Parent $MyInvocation.MyCommand.Path` instead of `$PSScriptRoot`
- **Severity:** low
- **Category:** structure
- **Location:** scripts/bitlocker_status_report.ps1:37
- **Current:**
  ```powershell
  $ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
  ```
- **Recommended:**
  ```powershell
  $ScriptRoot = $PSScriptRoot
  ```
- **Risk if changed:** Low — identical to F5 of the driver-scan audit. `$PSScriptRoot` is the PS 3.0+ canonical form; `$MyInvocation.MyCommand.Path` returns `$null` when the script is dot-sourced. C10 will subsume this whole import block, but the one-line fix is free.
- **Target phase:** P4 (fold into the C10 sweep)

### F7 — Missing `#Requires -RunAsAdministrator` and `#Requires -Version 5.1`
- **Severity:** low
- **Category:** structure
- **Location:** scripts/bitlocker_status_report.ps1 — top of file (no `#Requires` directives present)
- **Current:** Admin enforcement is runtime-only via `Assert-BitLockerAdmin` (line 58) calling `Test-SouliTEKAdministrator`, after the banner and disclaimer have already printed.
- **Recommended:**
  ```powershell
  #Requires -RunAsAdministrator
  #Requires -Version 5.1
  ```
  at the very top of the file (above the banner block).
- **Risk if changed:** Low. `#Requires -RunAsAdministrator` is the canonical declarative guard and fails at parse time before the banner prints, giving the operator a cleaner error. The runtime `Assert-BitLockerAdmin` check should stay as a defence-in-depth fallback for the rare case where the script is dot-sourced or invoked through a wrapper that bypasses the directive. `#Requires -Version 5.1` matches the project's PS-5.1-floor stance from `STYLE_GUIDE.md`.
- **Target phase:** P3 (alongside the F4 `[CmdletBinding()]` work)

### F8 — `Out-File` writes recovery keys with default-encoded line endings; no `Test-SafeFilePath` check on computed path
- **Severity:** info
- **Category:** correctness / defence-in-depth
- **Location:** scripts/bitlocker_status_report.ps1:298 (recovery-keys export) and 476 (audit-report export)
- **Local notes:** Both export paths use `Out-File -FilePath $filePath -Encoding UTF8`. The `$filePath` is server-side computed (`Join-Path $env:USERPROFILE "Desktop\$fileName"` where `$fileName` is built from `Get-Date` and `$env:COMPUTERNAME`), so there is no path-traversal vector — `$env:COMPUTERNAME` cannot contain `..` or path separators on Windows. That said, defence in depth would route the path through `Test-SafeFilePath` (the module helper that has Pester coverage per commit `a76b4e7`) before writing. Low-priority because the threat surface is genuinely thin here. The UTF-8 encoding is correct for the warning header which contains no non-ASCII; if the Unicode-glyph cleanup from F1 inline-marker notes is done, the audit-report content stays ASCII-clean too.
- **Target phase:** P4

## Out-of-scope notes
- **C3 (`Get-WmiObject`) does not apply.** The script uses `Get-BitLockerVolume` (line 97) — the native PS module cmdlet, available on both PS 5.1 and PS 7+. No migration needed.
- **C4 has zero occurrences in this file.** This is exemplary: every error-prone call site (`Get-Command`, `Get-BitLockerVolume`) is wrapped in `try`/`catch` with explicit `-ErrorAction Stop`. Use this script as the **reference pattern** when the P2 C4 sweep starts converting other scripts away from `SilentlyContinue`.
- **C2 (legacy `Write-SouliTEK*` API) has zero callers in this file.** The script has fully migrated away from the dead API and only uses `Write-Ui` plus raw `Write-Host`. After F1 is done it will be C2-clean.
- Banner block (lines 1–32, 31 lines of `# === / Coded by / IMPORTANT DISCLAIMER`) matches C11 cross-cutting cleanup; covered there.
- Import boilerplate (lines 36–44, 9 lines of `$CommonPath`/`Test-Path`/`. $CommonPath`/`Write-Warning`) matches C10 cross-cutting cleanup; covered there.
- The `Show-Disclaimer` wrapper on line 69 (3-line function whose only job is to call `Show-SouliTEKDisclaimer`) is dead indirection and can be removed in the C10 sweep — call `Show-SouliTEKDisclaimer` directly from line 553.
- The hard-coded Desktop output path (`$env:USERPROFILE\Desktop\`) on lines 257 and 445 breaks under SYSTEM context (`$env:USERPROFILE` resolves to `C:\Windows\System32\config\systemprofile`). Same hazard as F7 of the driver-scan audit; pair with the F4 `param([string]$OutputDirectory)` follow-up.
- The status-color switch on lines 142–148 is a clean enum-to-color lookup; when F1 collapses the `Write-Host`/`-ForegroundColor` pair into `Write-Ui -Level`, it becomes a status-to-level switch with the same shape. Worth keeping as-is for readability rather than inlining.
- The `Show-SecurityAudit` recommendations block (lines 411–437) is well-structured — counts unencrypted volumes, counts encrypted volumes without `RecoveryPassword` protectors, and prints recommendations with appropriate severity. The Unicode `⚠`/`ℹ`/`✓` glyphs noted in F1 inline-marker notes are the only blemish.
- The `try { ... } catch` on the main execution (lines 548–588) is appropriately broad — catches a top-level fatal and prints the stack trace via `$_.ScriptStackTrace`, which is the right diagnostic surface for an interactive tool. No change needed.
- `Test-BitLockerAvailable` (lines 47–55) checks for the cmdlet's presence as a portability gate — if the host is Win 10/11 Home (no BitLocker), the script prints a clear error and returns to the menu rather than crashing. Good defensive design.
- The `KeyProtector` enumeration logic on line 157 (`Where-Object { $_.KeyProtectorType -ne "RecoveryPassword" }`) on the status screen correctly omits the recovery-password protector type from the "Key Protectors:" summary line so the type list does not implicitly disclose that a recovery key is configured. Show-RecoveryKeys (line 209) and Show-DetailedReport (line 356) are the only paths that print recovery-password material; F3 covers both.
