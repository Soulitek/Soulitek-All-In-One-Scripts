# Audit — scripts/mcafee_removal_tool.ps1

## Inventory
| Item | Value |
|---|---|
| Path           | scripts/mcafee_removal_tool.ps1 |
| LOC            | 263 |
| Functions      | 5 |
| `#Requires`    | `#Requires -Version 5.1` (no `#Requires -RunAsAdministrator` despite calling MCPR.exe which mutates installed software, services, and registry) |
| Admin-required | yes (enforced at runtime via `Test-SouliTEKAdministrator` + `Show-AdminError` on line 236–238; MCPR itself refuses to run without elevation) |
| Last touched   | 8675720 — 2026-04-17 |
| Modernization grade | D |
| Vendored binary | `tools/MCPR.exe` — 12,647,224 bytes; SHA256 `D4D2266A19876BECCC95A97E1E5821EF42D98D503818C1E3F19BE75E9358B100`; last committed `c80b5a4 — 2025-11-18` (initial check-in, never updated) |

## Summary

A thin PowerShell wrapper around McAfee's official Consumer Product Removal binary (`tools/MCPR.exe`). Flow is linear and short: banner → admin check → MCPR-exists check → multi-line "this is destructive, press Y to continue" prompt → `Start-Process tools\MCPR.exe -Wait` → exit-code report. Because the actual destructive work is delegated entirely to a third-party EXE, the script itself has only **one** mutation site (line 183) but that one call hands full SYSTEM-level uninstall authority to a vendored binary whose authenticity is not verified at runtime. The dominant findings are: (1) **F_supply_chain** — `tools/MCPR.exe` is a 12 MB vendored binary committed once on 2025-11-18 and never re-validated; the script does `Test-Path $MCPRPath` (existence only) but does not call `Confirm-SouliTEKFileHash` despite that helper existing in the common module (line 1396), and does not use `Test-SafeFilePath` to validate the resolved path is still under the project root before invocation. A swapped-in malicious `MCPR.exe` would inherit the script's elevated context unchallenged — this is the single most important fix for this file. (2) C5 — the entire script is destructive (uninstalls antivirus, removes services, deletes registry keys via MCPR) yet has no `param()` block, no `[CmdletBinding(SupportsShouldProcess)]`, and no `-WhatIf`/`-Confirm` surface; the only safety gate is the interactive Y/N `Read-Host` on line 147 which would deadlock under SYSTEM-context RMM execution. (3) C1 — 65 raw `Write-Host` calls, roughly split between bare spacer lines (`Write-Host ""`), `=`-bar dividers (`Write-Host "========..."` with `-ForegroundColor`), and the entire `Show-AdminError` function (lines 64–83) which is pre-`Write-Ui`-era inline-color formatting; the same function also does `$Host.UI.RawUI.BackgroundColor = "Black"` (line 65) which is a global console-state mutation with no restore on exit. Secondary concerns: every `Write-Ui` call in `Invoke-McAfeeRemoval` carries an embedded `[*]` or `[OK]` marker inside the message string (lines 165, 170, 173, 177) — the same double-marking anti-pattern as F2 of 01-modules-SouliTEK-Common.md; no `[CmdletBinding()]` on any of the 5 functions; `Split-Path -Parent $MyInvocation.MyCommand.Path` instead of `$PSScriptRoot`. Zero `-ErrorAction SilentlyContinue` occurrences (one of the cleaner scripts in the repo on this axis). Recommended phase entry order: **P0 (F_supply_chain — pin the hash NOW)**, then P1 (C1), then P3 (C5).

## Findings

### F1 — Destructive script with no `SupportsShouldProcess` / `-WhatIf` / `-Confirm` (see C5)
- **Severity:** high
- **Category:** safety
- **Location:** scripts/mcafee_removal_tool.ps1 — script-level (no `param()` block at all, no `[CmdletBinding()]`); single mutation site at line 183 (`Start-Process -FilePath $MCPRPath -Wait -NoNewWindow -PassThru -ErrorAction Stop`).
- **Reference:** [C5](00-cross-cutting.md#c5--destructive-scripts-lack-cmdletbindingsupportsshouldprocess--whatif-confirm)
- **Current:**
  ```powershell
  # No param() block, no [CmdletBinding()]
  # Only safety gate: interactive Read-Host on line 147
  $response = Read-Host
  if ($response -ne 'Y' -and $response -ne 'y') { ... exit 0 }
  ...
  # Line 183 — the destructive call:
  $process = Start-Process -FilePath $MCPRPath -Wait -NoNewWindow -PassThru -ErrorAction Stop
  ```
- **Recommended:**
  ```powershell
  [CmdletBinding(SupportsShouldProcess, ConfirmImpact='High')]
  param(
      [switch]$Force,                # bypass interactive Y/N gate (still honors -Confirm)
      [string]$MCPRPath = (Join-Path (Split-Path -Parent $PSScriptRoot) 'tools\MCPR.exe'),
      [string]$ExpectedHash = 'D4D2266A19876BECCC95A97E1E5821EF42D98D503818C1E3F19BE75E9358B100'
  )
  ...
  if ($PSCmdlet.ShouldProcess('McAfee products on this system', 'Run MCPR.exe (complete McAfee removal)')) {
      $process = Start-Process -FilePath $MCPRPath -Wait -NoNewWindow -PassThru -ErrorAction Stop
  }
  ```
- **Risk if changed:** Medium. The interactive Y/N flow must still work (default `ConfirmImpact='High'` will prompt unless `-Confirm:$false` or `-Force` is passed). Default behavior under interactive use is preserved; the win is that automated/RMM callers can now drive the script with `-WhatIf` to verify the resolved MCPR path without firing, or `-Confirm:$false -Force` to run unattended. Pair with F2 (the interactive `Read-Host` becomes redundant once `ShouldProcess` is in place — collapse them to one safety gate).
- **Local notes:** Only **one** mutation site in the entire script (line 183). There is no pre-cleanup (no `Stop-Service`, no `Remove-Item` for stale McAfee files before MCPR runs) and no post-cleanup (no temp-file removal, no log archival). All destructive work happens inside MCPR.exe itself, which is why F_supply_chain (F3 below) is the higher-impact finding here.
- **Target phase:** P3

### F2 — Raw `Write-Host` calls not migrated to `Write-Ui`/`Write-Status` (see C1)
- **Severity:** med
- **Category:** output-style
- **Location:** scripts/mcafee_removal_tool.ps1 — 65 raw `Write-Host` occurrences across 5 functions plus the main execution block. Sample lines: 68–80 (entire `Show-AdminError` body), 96–116 (most of `Show-MCPRNotFound`), 124–145 (most of `Show-Warning`), 159–163, 185–189, 199–214 (most of `Invoke-McAfeeRemoval` decorative chrome), 252–260 (main-execution closing banner).
- **Reference:** [C1](00-cross-cutting.md#c1--raw-write-host-calls-not-migrated-to-write-uiwrite-status)
- **Current (representative pattern — `Show-AdminError` block, lines 65–80):**
  ```powershell
  $Host.UI.RawUI.BackgroundColor = "Black"
  $Host.UI.RawUI.ForegroundColor = "Red"
  Clear-Host
  Write-Host ""
  Write-Host "========================================"
  Write-Host "  ERROR: Administrator Required"
  Write-Host "========================================"
  Write-Host ""
  Write-Host "This script must run as Administrator."
  ...
  ```
- **Recommended:**
  ```powershell
  Show-Section -Title "ERROR: Administrator Required" -Level "ERROR"
  Write-Ui -Message "This script must run as Administrator." -Level "ERROR"
  Write-Ui -Message "HOW TO FIX:" -Level "INFO"
  Write-Ui -Message "  1. Right-click this file" -Level "INFO"
  Write-Ui -Message "  2. Select 'Run with PowerShell as administrator'" -Level "INFO"
  Write-Ui -Message "  3. Click 'Yes' on the prompt" -Level "INFO"
  ```
- **Risk if changed:** Low — pure message-text preservation, no logic change. The `Show-Section` helper from the common module replaces the manual `========` bar pattern.
- **Local notes:** Three categories of raw `Write-Host`, mirroring the categorisation in F2 of `scripts-driver_integrity_scan.md`:
  1. **Bare spacer calls** — `Write-Host ""` used as vertical spacing (lines 68, 72, 74, 79, 96, 100, 103, 108, 115, 124, 128, 131, 136, 138, 143, 145, 149, 159, 163, 171, 175, 179, 185, 190, 192, 195, 200, 203, 205, 210, 214, 217, 222, 252, 260). Not strict C1 violations under the "visual separator helpers" exception, but candidates for a `Write-Ui -Spacer` / `Show-Section` migration once that helper lands in P4.
  2. **`=`-bar dividers with inline color** — `Write-Host "========================================" -ForegroundColor Red|Yellow|Cyan|Green` (lines 97, 99, 125, 127, 144, 160, 162, 186, 189, 199, 211, 213). Clear C1 violations — these are exactly the manual-color decorative chrome that `Show-Section` exists to replace.
  3. **Plain message lines without color** — `Show-AdminError` (lines 69, 70, 71, 73, 75, 76, 77, 78, 80), `Show-MCPRNotFound` (lines 98, 105, 106, 107, 116), `Show-Warning` (line 126), main block (lines 253, 259). Clear C1 violations; trivially migrate to `Write-Ui` with appropriate `-Level`.
- **Local notes (cont.) — global console-state mutation:** `Show-AdminError` (lines 65–66) sets `$Host.UI.RawUI.BackgroundColor = "Black"` and `$Host.UI.RawUI.ForegroundColor = "Red"` immediately before `Clear-Host`, then never restores. After this function runs the entire host session has a black/red colour scheme. This is a latent UX bug independent of C1: even without an admin error, importing this script (e.g. via `. .\mcafee_removal_tool.ps1` for testing) leaves the console mutated. The C1 sweep should drop these two lines entirely — `Write-Ui -Level "ERROR"` already gives the message a red bracket without recolouring the console globally.
- **Local notes (cont.) — inline marker prefixes in `Write-Ui` calls:** Lines 101, 102, 104, 109, 110, 111, 112, 113, 114, 129, 130, 132, 133, 134, 135, 137, 139, 140, 141, 142, 146, 150, 165, 170, 173, 174, 177, 178, 188, 191, 193, 194, 198, 201, 202, 204, 212, 215, 216, 218, 219, 220, 221, 255, 257 — many of these embed `[*]`, `[OK]`, or pseudo-bullets like `  -` inside the message string while `Write-Ui` is already going to prepend its own `[LEVEL]` bracket. Strip the inline markers during the C1 sweep so the `[LEVEL]` bracket is the only marker (same anti-pattern as F2 of `01-modules-SouliTEK-Common.md` and F2 of `scripts-driver_integrity_scan.md`).
- **Target phase:** P1

### F3 — Vendored third-party binary `tools/MCPR.exe` not hash-verified before execution (F_supply_chain)
- **Severity:** **high**
- **Category:** security / supply-chain
- **Location:** scripts/mcafee_removal_tool.ps1 — path resolution at line 58 (`$MCPRPath = Join-Path $ProjectRoot "tools\MCPR.exe"`), existence-only check at line 86 (`if (Test-Path $MCPRPath)`), and the elevated invocation at line 183 (`Start-Process -FilePath $MCPRPath -Wait -NoNewWindow -PassThru -ErrorAction Stop`).
- **Reference:** local (no cross-cutting ID — this is the first F_supply_chain finding raised in the audit pass). Conceptually adjacent to [C12](00-cross-cutting.md#c12--installer-downloads-zip-without-mandatory-hash-verification-by-default).
- **Current:**
  ```powershell
  # Path computed but never validated to be inside the project root:
  $ProjectRoot = Split-Path -Parent $ScriptRoot
  $MCPRPath = Join-Path $ProjectRoot "tools\MCPR.exe"

  # Only check before execution is plain Test-Path (existence only):
  function Test-MCPRToolExists {
      if (Test-Path $MCPRPath) { return $true } else { return $false }
  }

  # Elevated invocation with no integrity check:
  $process = Start-Process -FilePath $MCPRPath -Wait -NoNewWindow -PassThru -ErrorAction Stop
  ```
- **Recommended:**
  ```powershell
  # 1. Validate path stays inside the project's tools/ folder (defence against ../ traversal
  #    if MCPRPath ever becomes a parameter):
  $toolsDir = Join-Path $ProjectRoot 'tools'
  if (-not (Test-SafeFilePath -UserInput 'MCPR.exe' -BaseDir $toolsDir)) {
      Write-Ui -Message "MCPR path failed safety check." -Level "ERROR"
      exit 1
  }

  # 2. Verify SHA256 before every run (pinned canonical hash captured 2026-05-15):
  $ExpectedMCPRHash = 'D4D2266A19876BECCC95A97E1E5821EF42D98D503818C1E3F19BE75E9358B100'
  if (-not (Confirm-SouliTEKFileHash -FilePath $MCPRPath -ExpectedHash $ExpectedMCPRHash)) {
      Write-Ui -Message "Refusing to launch MCPR.exe: integrity check failed." -Level "ERROR"
      exit 1
  }

  # 3. Then and only then invoke:
  $process = Start-Process -FilePath $MCPRPath -Wait -NoNewWindow -PassThru -ErrorAction Stop
  ```
- **Risk if changed:** Low. Both helpers already exist in `modules/SouliTEK-Common.ps1` (`Test-SafeFilePath` at line 38, `Confirm-SouliTEKFileHash` at line 1396). `Confirm-SouliTEKFileHash` is fail-closed: on hash mismatch it logs an error and `Remove-Item -Force` deletes the offending file (module line 1409), then returns `$false`. The recommendation above adds an `exit 1` so the script does not continue past a failed check. Cost is one `Get-FileHash` call (~50 ms for a 12 MB file on modern hardware) on every run.
- **Local notes — binary origin & security model:**
  - **Origin:** McAfee Consumer Product Removal (MCPR), McAfee's official uninstaller for consumer products. Distributed historically as `MCPR.exe` from `https://www.mcafee.com/support/?articleId=TS101331` (URL has shifted over the years — this is the canonical KB landing page).
  - **Vendored copy:** committed once in commit `c80b5a4 — 2025-11-18` (single commit in `git log -- tools/MCPR.exe`). Never updated since. McAfee periodically refreshes MCPR; the pinned hash below documents the **current** vendored copy, not the latest upstream release.
  - **Canonical pinned hash (SHA256, as of 2026-05-15):** `D4D2266A19876BECCC95A97E1E5821EF42D98D503818C1E3F19BE75E9358B100`. Size: 12,647,224 bytes. Spec and plan should treat this as the canonical pinned value for the P0 hash-verification add. Whenever MCPR.exe is refreshed in the repo, both the vendored file **and** this hash constant must be updated atomically in the same commit, and the audit + spec must be updated to match.
  - **Security model:** MCPR runs with the calling user's privileges. The script enforces elevation via `Test-SouliTEKAdministrator` (line 236), so MCPR effectively inherits SYSTEM/Administrator authority. A swapped-in malicious `MCPR.exe` therefore gets unconstrained elevated execution — this is the highest-leverage failure mode in the entire script and the primary motivation for raising this finding to **high** severity.
  - **Why this is not already covered by C12:** C12 is specifically about the **installer** ZIP download flow. This finding is about a binary that is already inside the repo and gets invoked at runtime — a different threat model (`git push` poisoning, dev-machine compromise, accidental binary swap during a maintenance pass) and a different mitigation (per-run hash verification, not download-time verification).
  - **Why not Authenticode/`Get-AuthenticodeSignature` instead of SHA256?** Both should ideally be checked. The repo's existing helper is hash-only (`Confirm-SouliTEKFileHash`); adding `Get-AuthenticodeSignature -FilePath $MCPRPath` and verifying `$sig.Status -eq 'Valid' -and $sig.SignerCertificate.Subject -like '*McAfee*'` is a sensible P3 follow-up but should not block the P0 hash-pin work (hash alone closes the swap-attack path; signature adds defence-in-depth against expired/revoked certs which is a separate failure mode).
- **Target phase:** **P0** (highest priority in this file — pin the hash before anything else lands)

### F4 — No `[CmdletBinding()]` on script or any function
- **Severity:** low
- **Category:** structure
- **Location:** scripts/mcafee_removal_tool.ps1 — script-level (no `param()` block) and every one of the 5 internal functions (`Show-AdminError` line 64, `Test-MCPRToolExists` line 85, `Show-MCPRNotFound` line 93, `Show-Warning` line 121, `Invoke-McAfeeRemoval` line 156).
- **Local notes:** This is partly subsumed by F1's `[CmdletBinding(SupportsShouldProcess)]` recommendation — once the script-level binding lands in P3, the only remaining functions worth annotating are `Invoke-McAfeeRemoval` (which would benefit from `[CmdletBinding()]` so `-Verbose` flows through to its internal `Start-Process`). The other four functions are pure-display (banner / prompt) and `[CmdletBinding()]` adds nothing. Defer to P4 standardisation pass.
- **Target phase:** P4

### F5 — `Split-Path -Parent $MyInvocation.MyCommand.Path` instead of `$PSScriptRoot`
- **Severity:** low
- **Category:** structure
- **Location:** scripts/mcafee_removal_tool.ps1:43
- **Current:**
  ```powershell
  $ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
  ```
- **Recommended:**
  ```powershell
  $ScriptRoot = $PSScriptRoot
  ```
- **Risk if changed:** Low. Same recommendation as F5 of `scripts-driver_integrity_scan.md` — `$PSScriptRoot` is the canonical PS 3.0+ automatic variable and returns the correct directory under dot-sourcing as well. C10 will eventually replace this whole import block with `Import-SouliTEKCommon`.
- **Target phase:** P4 (fold into the C10 sweep)

### F6 — Blocking `Read-Host` prompts with no non-interactive escape
- **Severity:** low
- **Category:** structure (UX / RMM safety)
- **Location:** scripts/mcafee_removal_tool.ps1:81 (in `Show-AdminError` — "Press Enter to exit"), :117 (in `Show-MCPRNotFound` — "Press Enter to exit"), :147 (in `Show-Warning` — the Y/N safety gate), :262 (script-end "Press Enter to exit").
- **Local notes:** Four `Read-Host` calls, all of which will deadlock the worker process under SYSTEM-context RMM execution (flagged in user's CLAUDE.md as a real deployment scenario). There is no `[Environment]::UserInteractive` gate and no `-NonInteractive` switch. The line 147 Y/N gate is the load-bearing safety prompt and is the one most damaging if missed — without it, an RMM-driven run would block forever waiting for keyboard input that will never come. F1's `SupportsShouldProcess` recommendation eliminates this concern for the Y/N gate specifically (RMM can pass `-Confirm:$false -Force`). The three "Press Enter to exit" calls are pure UX padding and should be guarded with `if ([Environment]::UserInteractive) { Read-Host ... }` in P4.
- **Target phase:** P4 (paired with the same fix recommended in F6 / F10 of the driver-integrity-scan and common-module audits)

### F7 — `Show-AdminError` mutates global console colours without restoring (info)
- **Severity:** info
- **Category:** ux / structure
- **Location:** scripts/mcafee_removal_tool.ps1:65–66
- **Current:**
  ```powershell
  $Host.UI.RawUI.BackgroundColor = "Black"
  $Host.UI.RawUI.ForegroundColor = "Red"
  Clear-Host
  ```
- **Local notes:** Already enumerated in F2's local notes as the "global console-state mutation" sub-point, but called out separately here because the fix is independent of the broader C1 sweep: just delete the two lines. `Write-Ui -Level "ERROR"` provides the red bracket that signals error context, without bleeding red onto every subsequent line of host output until the session is closed. No restore path exists (the `exit 1` on line 82 leaves the host with whatever colour scheme `Show-AdminError` set). Worst case: a user runs the script non-elevated → sees the red error → re-launches elevated → discovers their console is now black/red until they restart the host.
- **Target phase:** P1 (fold into the C1 sweep, drop the two lines)

### F8 — `#Requires -RunAsAdministrator` is missing despite the script needing admin
- **Severity:** info
- **Category:** structure / safety
- **Location:** scripts/mcafee_removal_tool.ps1:37 (only `#Requires -Version 5.1` is declared)
- **Local notes:** The script enforces elevation at runtime via `Test-SouliTEKAdministrator` + `Show-AdminError` (lines 236–238), which is fine, but `#Requires -RunAsAdministrator` would shift the check earlier (before any module dot-source or `Clear-Host` happens) and would make the intent declarative. The runtime check could then be deleted. This is a stylistic improvement only — current behaviour is correct, just slightly noisier. Pair with the C10 sweep.
- **Target phase:** P4

## Out-of-scope notes
- Banner block (lines 1–35, 33 lines of `# === / Coded by / IMPORTANT DISCLAIMER`) matches C11 cross-cutting cleanup; covered there.
- Zero `-ErrorAction SilentlyContinue` occurrences in the entire script. One of the cleaner files in the repo on the C4 axis. The single `-ErrorAction Stop` on line 183 (`Start-Process ... -ErrorAction Stop`) is correct: it ensures the `try`/`catch` block actually catches a failed launch.
- The `try`/`catch` block around the MCPR invocation (lines 181–224) is well-structured: it surfaces the exception message verbatim via `$_.Exception.Message`, distinguishes between `ExitCode -eq 0` (success) and non-zero (warning), and returns a boolean that the main block uses to print a final status line. No change needed.
- `Start-Process -Wait -NoNewWindow -PassThru -ErrorAction Stop` (line 183) is the right invocation form for a long-running console-style installer that should surface to the same window the user is watching. `-NoNewWindow` keeps the MCPR UI in-band; `-Wait` blocks until the EXE returns so the script can read `ExitCode`; `-PassThru` is required to receive the `$process` object that exposes `ExitCode`. The only thing missing from this line is the hash-verify guard recommended in F3.
- The interactive Y/N prompt in `Show-Warning` (lines 146–153) is one of the few examples in the repo of a destructive-action gate written defensively: it requires explicit `Y`/`y`, defaults to cancel for any other input including empty, and exits with `0` on cancel (not an error). Once F1's `ShouldProcess` lands, this can be collapsed — but the current form is correct on its own terms.
- The hard-coded path `tools\MCPR.exe` on line 58 has no override surface. F1's recommendation introduces `[string]$MCPRPath = ...` as a parameter, which paired with F3's `Test-SafeFilePath` guard would let an operator override the location safely (e.g. to use a non-vendored copy for testing). Without F1's `param()` block, no override is possible — but no override is needed in the default case either.
- The script does **not** delete the MCPR binary or any McAfee files itself; all destructive work is delegated to MCPR.exe. There is no need for a temp-file-cleanup pass after the run, and no `Remove-Item` calls exist in the script. This is structurally clean — the script's surface area is "validate environment → invoke vendor binary → report exit code," and it should stay that way.
