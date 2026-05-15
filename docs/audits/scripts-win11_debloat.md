# Audit — scripts/win11_debloat.ps1

## Inventory
| Item | Value |
|---|---|
| Path           | scripts/win11_debloat.ps1 |
| LOC            | 287 |
| Functions      | 4 (`Show-AdminError` line 70, `Show-Warning` line 91, `Test-InternetConnection` line 130, `Invoke-Win11Debloat` line 157) |
| `#Requires`    | `#Requires -Version 5.1` (no `#Requires -RunAsAdministrator` despite admin check on line 261 via `Test-SouliTEKAdministrator`) |
| Admin-required | yes (enforced at runtime by `Test-SouliTEKAdministrator` on line 261, which triggers `Show-AdminError` + `exit 1` on failure; the underlying Win11Debloat payload writes to `HKLM` and removes provisioned AppX packages, both of which require elevation) |
| Last touched   | 8675720 — 2026-04-17 |
| Modernization grade | D |

## Summary

This script is a thin SouliTEK-branded wrapper around the third-party **Win11Debloat** project by Raphire. Its destructive surface is delegated entirely to a remote script that is fetched at runtime from `https://debloat.raphi.re/` (line 196) and executed inline via `& ([scriptblock]::Create($scriptContent))` (line 206). **None of the predicted destructive primitives — `Remove-AppxPackage`, `Set-ItemProperty`, `Set-MpPreference`, `Disable-WindowsOptionalFeature` — appear anywhere in this file.** What lives locally is: a banner, a one-time interactive warning + Y/N gate (`Show-Warning`, lines 91–128), an internet probe that pings 8.8.8.8 then 1.1.1.1 as fallback (`Test-InternetConnection`, lines 130–155), and the download-and-IEX block. The local audit signal is therefore unusual: the script is **C3-clean (0 `Get-WmiObject`), C4-clean (0 `SilentlyContinue`), and has zero direct mutation sites**, yet earns a D because (a) C5 still applies — running an arbitrary downloaded scriptblock that the operator cannot preview is itself a destructive action and the wrapper offers no `-WhatIf` / `-Confirm` / `-DryRun`, and (b) the remote-fetch-then-IEX pattern is a textbook supply-chain risk (OWASP A08:2021 Software and Data Integrity Failures) that needs a separate HIGH-severity local finding. The 61 `Write-Host` calls (C1) split 36 spacer / 12 colored / 13 plain. No `Write-SouliTEK*` legacy callers exist, so C2 has nothing to do here. Defender involvement is **no** in the local file — the wrapper never touches `Set-MpPreference`, `MsMpEng`, or any Windows Defender registry key — but the downloaded Win11Debloat payload is known upstream to offer Defender-toggling menu items, which is part of why the remote-execution finding is high-severity rather than medium. Secondary concerns: no `[CmdletBinding()]` anywhere, `Split-Path -Parent $MyInvocation.MyCommand.Path` instead of `$PSScriptRoot` (line 50), three blocking `Read-Host` calls (lines 87, 121, 286) with no `[Environment]::UserInteractive` gate, the C11 banner block (42 lines, the largest in the audit set so far), and the inline-marker anti-pattern in `Write-Ui` calls (lines 167, 169, 178, 182, 188, 195, 198, 201). Recommended phase entry order: P1 (C1), then P2 has nothing to do here, then P3 (C5 + remote-fetch hardening together).

## Findings

### F1 — Remote script download + `[scriptblock]::Create` execution (supply-chain risk)
- **Severity:** high
- **Category:** security (supply-chain / remote code execution)
- **Location:** scripts/win11_debloat.ps1:64 (URL constant), 196 (`Invoke-RestMethod`), 206 (`& ([scriptblock]::Create($scriptContent))`)
- **Current:**
  ```powershell
  # Line 64
  $Win11DebloatURL = "https://debloat.raphi.re/"
  ...
  # Lines 196, 206
  $scriptContent = Invoke-RestMethod -Uri $Win11DebloatURL -ErrorAction Stop
  & ([scriptblock]::Create($scriptContent))
  ```
- **Recommended:** Three hardening steps, in order:
  1. **Pin to a tag-locked GitHub raw URL with SHA256 verification.** Replace the friendly redirect (`debloat.raphi.re`) with a versioned raw URL of the form `https://raw.githubusercontent.com/Raphire/Win11Debloat/vMAJOR.MINOR.PATCH/Win11Debloat.ps1` (substitute the pinned semantic version), compute `Get-FileHash -Algorithm SHA256` on the downloaded content, and abort if the hash does not match a hard-coded `$ExpectedHash` constant updated whenever the pinned version is bumped. This is the same hardening pattern that C12 mandates for `Install-SouliTEK.ps1`.
  2. **Show a fingerprint and gate on explicit confirmation, not Y/Anything.** The current `Show-Warning` (lines 91–128) is a banner; it cannot tell the operator *what* will run. After the SHA256 check passes, display the hash and pinned version, then require typing the literal string `RUN` (case-sensitive) — not a one-character Y/N — before invoking the scriptblock.
  3. **Honor `-WhatIf`.** If `$PSCmdlet.ShouldProcess('Windows installation', "Execute Win11Debloat $PinnedVersion")` returns false (i.e. `-WhatIf` was passed), print the URL, hash, and version and exit 0 without running the scriptblock. This is the C5 mechanism reused as a preview switch for the remote payload.
- **Risk if changed:** Medium — the friendly redirect (`debloat.raphi.re`) is convenient but it hides what version actually ran; pinning makes upstream version bumps a deliberate maintainer action. The `RUN` confirmation token will surprise users on first encounter; document it in `Show-Warning`. Note that pinning + hash-checking does **not** prevent the upstream maintainer from publishing a malicious tagged release — it only prevents on-the-fly MITM or upstream-server compromise. Combined with the `RUN` gate and `-WhatIf`, this is defense-in-depth, not absolute protection.
- **Local notes:** The `[scriptblock]::Create($scriptContent)` invocation is functionally equivalent to `Invoke-Expression $scriptContent` — PSScriptAnalyzer rule `PSAvoidUsingInvokeExpression` will not catch it because the cmdlet name differs, but it is the same security hazard. After C8 (PSScriptAnalyzer / CI) lands, add a custom rule or a hand-rolled `Select-String 'scriptblock\]::Create'` repo-wide check to surface this pattern.
- **Local notes (cont.) — defense-in-depth gap:** `Invoke-RestMethod` (line 196) does not pass `-UseBasicParsing` (harmless on PS 5.1+, but defensive). It also does not enforce TLS 1.2/1.3 explicitly via `[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12, Tls13` before the call — on a stale PS 5.1 host with default TLS 1.0, the fetch may downgrade. Add the `SecurityProtocol` pin before line 196.
- **Target phase:** P3 (folded into C5 cycle — same `[CmdletBinding(SupportsShouldProcess)]` plumbing covers both)

### F2 — Destructive script lacks `[CmdletBinding(SupportsShouldProcess)]` + `-WhatIf` / `-Confirm` (see C5)
- **Severity:** high
- **Category:** safety
- **Location:** scripts/win11_debloat.ps1 — entire script (no `param()` block, no `[CmdletBinding()]`). The single mutation site is line 206 (`& ([scriptblock]::Create($scriptContent))`), which executes the downloaded Win11Debloat payload that internally performs **all** of the predicted hotspots: `Remove-AppxPackage` against provisioned-and-installed AppX bundles, registry telemetry writes under `HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection`, `Disable-ScheduledTask` on `\Microsoft\Windows\Application Experience\*`, and similar.
- **Reference:** [C5](00-cross-cutting.md#c5--destructive-scripts-lack-cmdletbindingsupportsshouldprocess--whatif-confirm)
- **Current:** No `param()` block at all; the script is `#Requires -Version 5.1` + four functions + a flat top-level `MAIN EXECUTION` section (lines 256–286) that calls `Show-ScriptBinding`, `Show-Warning`, `Invoke-Win11Debloat`, then `Read-Host "Press Enter to exit"`. Zero gating around the destructive call.
- **Recommended:**
  ```powershell
  [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
  param(
      [switch]$DryRun,
      [string]$ExpectedHash = '<pin-on-next-bump>'  # SHA256 of pinned Win11Debloat.ps1
  )
  ...
  if ($PSCmdlet.ShouldProcess('Windows installation', "Execute Win11Debloat (pinned hash: $ExpectedHash)")) {
      & ([scriptblock]::Create($scriptContent))
  } else {
      Write-Ui -Message "Skipped execution (-WhatIf)." -Level "INFO"
  }
  ```
- **Risk if changed:** Medium. The cross-script C5 risk profile applies. Default behavior preserved when neither `-WhatIf` nor `-Confirm` is passed; `ConfirmImpact = 'High'` means `$ConfirmPreference` (default `High`) will fire an automatic prompt unless overridden — *good*, because this script's blast radius is enormous. Note that the current `Show-Warning` Y/N gate (lines 91–128) does NOT satisfy C5: it is a banner-style "press Y to continue" with no per-action gating, no `-WhatIf` preview, and no programmatic suppression for non-interactive use.
- **Local notes:** Because this script is a remote-fetch wrapper, the `ShouldProcess` target string cannot enumerate the actual AppX removals or registry writes — those live in the downloaded payload. The honest `-WhatIf` output for this wrapper is the URL + hash + pinned version, paired with a recommendation to run the upstream Win11Debloat with its own `-Silent` / `-RunDefaults` flags only after a system restore point exists.
- **Target phase:** P3

### F3 — Raw `Write-Host` calls not migrated to `Write-Ui` (see C1)
- **Severity:** med
- **Category:** output-style
- **Location:** scripts/win11_debloat.ps1 — 61 raw `Write-Host` occurrences across 4 functions + the top-level section. No `Write-SouliTEK*` legacy callers in this file (C2 has nothing to do here).
- **Reference:** [C1](00-cross-cutting.md#c1--raw-write-host-calls-not-migrated-to-write-uiwrite-status)
- **Current (representative pattern — `Show-AdminError` lines 74–86):**
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
  Write-Ui -Message "" -Level "INFO"  # or Show-Section if a separator helper is added in P4
  Write-Ui -Message "ERROR: Administrator Required" -Level "ERROR"
  Write-Ui -Message "This script must run as Administrator." -Level "ERROR"
  ```
- **Risk if changed:** Low — message text preserved verbatim; the `[LEVEL]` bracket emitted by `Write-Ui` replaces the manual color formatting and `========` separators. Per-category fix patterns are enumerated below in Local notes.
- **Local notes:** Three categories of raw `Write-Host` in this file:
  1. **Blank-line / spacer calls (36 of 61)** — bare `Write-Host ""` used as vertical spacing (lines 74, 78, 80, 85, 94, 98, 101, 107, 112, 114, 117, 119, 123, 160, 164, 170, 173, 175, 179, 186, 191, 199, 203, 208, 212, 214, 220, 225, 229, 232, 238, 246, 272, 276, 280, 284). Same exception as F2 of `scripts-driver_integrity_scan.md` — these are not C1 violations per the "visual separator helpers" exception, but they are noisy and should migrate to a `Show-Section` / `Write-Ui -Spacer` helper if one is added in P4.
  2. **Colored separator/banner calls (12 of 61)** — `Write-Host "========================================" -ForegroundColor Yellow|Cyan|Red|Green|DarkGray` (lines 95, 97, 118, 161, 163, 184, 202, 209, 211, 226, 228, 245). These are real C1 violations: pre-`Write-Ui`-era manual color formatting that should be `Show-Section` style helpers or `Write-Ui -Level "STEP"` for the inline label rows.
  3. **Plain message lines without color (13 of 61)** — `Show-AdminError` body (lines 75, 76, 77, 79, 81, 82, 83, 84, 86) plus top-level finals (lines 273, 283). Clear C1 violations: should all be `Write-Ui -Message "..." -Level "ERROR"` / `-Level "INFO"`.
- **Local notes (cont.) — inline marker prefixes:** 8 `Write-Ui` calls already double-mark with embedded `[*]` / `[ERROR]` / `[OK]` prefixes inside the message text (lines 167, 169, 178, 182, 188, 195, 198, 201). Same anti-pattern as F2 of `01-modules-SouliTEK-Common.md` and F2 of `scripts-driver_integrity_scan.md`. When the C1 sweep is done, strip the inline `[*]` / `[OK]` / `[ERROR]` so the `[LEVEL]` bracket emitted by `Write-Ui` is the only marker.
- **Target phase:** P1

### F4 — No `[CmdletBinding()]` on script or any function
- **Severity:** low
- **Category:** structure
- **Location:** scripts/win11_debloat.ps1 — script-level (no `param()` block) and every one of the 4 internal functions (`Show-AdminError` line 70, `Show-Warning` line 91, `Test-InternetConnection` line 130, `Invoke-Win11Debloat` line 157).
- **Local notes:** Folded into F2 (C5) for the script-level case — the `[CmdletBinding(SupportsShouldProcess)]` recommendation there subsumes this. The four functions individually do not need `[CmdletBinding()]` since none of them take parameters except `Test-InternetConnection` which is `param`-less. Of the four, only `Invoke-Win11Debloat` carries the destructive call (line 206) and would benefit from `[CmdletBinding(SupportsShouldProcess)]` propagating from the script level.
- **Target phase:** P3 (folded into F2)

### F5 — `Split-Path -Parent $MyInvocation.MyCommand.Path` instead of `$PSScriptRoot`
- **Severity:** low
- **Category:** structure
- **Location:** scripts/win11_debloat.ps1:50
- **Current:**
  ```powershell
  $ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
  ```
- **Recommended:**
  ```powershell
  $ScriptRoot = $PSScriptRoot
  ```
- **Risk if changed:** Low. Same reasoning as F5 of `scripts-driver_integrity_scan.md`: `$PSScriptRoot` is the canonical PS 3.0+ automatic variable; `$MyInvocation.MyCommand.Path` returns `$null` when the script is dot-sourced. C10 will eventually replace this whole block with `Import-SouliTEKCommon`, but until then this one-line fix is free.
- **Target phase:** P4 (fold into the C10 sweep)

### F6 — Blocking `Read-Host` prompts with no non-interactive exit path
- **Severity:** low
- **Category:** structure (UX / RMM safety)
- **Location:** scripts/win11_debloat.ps1 — three `Read-Host` calls at lines 87 (`Show-AdminError` "Press Enter to exit"), 121 (`Show-Warning` Y/N gate), 286 (top-level "Press Enter to exit").
- **Local notes:** Under SYSTEM-context RMM execution (flagged in user's CLAUDE.md as a deployment scenario), all three `Read-Host` calls will hang the worker process. The line-121 prompt is the most consequential because it sits before the destructive call on line 206 and there is no `[Environment]::UserInteractive` gate or `-Silent` / `-NonInteractive` switch to bypass it programmatically. Pairs naturally with the same recommendation against `Wait-SouliTEKKeyPress` (F10 of `01-modules-SouliTEK-Common.md`) and the F6 of `scripts-driver_integrity_scan.md`. If F2's `[CmdletBinding(SupportsShouldProcess)]` is added, `-Confirm:$false -WhatIf:$false` callers still hit the `Read-Host` on line 121 — wrap it in `if (-not $PSCmdlet.ShouldProcess(...)) { return } elseif ([Environment]::UserInteractive) { Read-Host ... }`.
- **Target phase:** P4

### F7 — Banner block (42 lines) — see C11
- **Severity:** low
- **Category:** docs
- **Location:** scripts/win11_debloat.ps1:1–42
- **Reference:** [C11](00-cross-cutting.md#c11--bannerdisclaimer-block-duplicated-at-top-of-every-script)
- **Local notes:** This file's banner is the largest in the audit set so far (42 lines of `# === / Coded by / IMPORTANT DISCLAIMER / WARNING`). The disclaimer language at lines 26–42 is legally substantive — it explicitly warns about app removal, telemetry disabling, registry mutation, and system-restore-point recommendations. When C11 collapses the banner to 3 lines, **keep** the destructive-action warning paragraph (lines 33–40) inline — same exception that wifi_password_viewer and product_key_retriever get for their legal notices, because this script's destructive surface (delegated though it is) genuinely warrants a runtime warning.
- **Target phase:** P4

### F8 — Banner uses `Show-SouliTEKBanner` (legacy) + `Show-ScriptBanner` mixed
- **Severity:** info
- **Category:** consistency
- **Location:** scripts/win11_debloat.ps1:93 (`Show-SouliTEKBanner` inside `Show-Warning`), 159 (`Show-SouliTEKBanner` inside `Invoke-Win11Debloat`), 258 (`Show-ScriptBanner -ScriptName "Windows 11 Debloat Tool"` at top-level main).
- **Local notes:** Same script displays the banner three times via two different helper functions — `Show-SouliTEKBanner` (parameterless, legacy) twice and `Show-ScriptBanner` (parameterised, current) once. The audits for `01-modules-SouliTEK-Common.md` should already classify `Show-SouliTEKBanner` against `Show-ScriptBanner`; the local fix is to replace lines 93 and 159 with `Show-ScriptBanner -ScriptName "Windows 11 Debloat Tool"` (matching line 258). Also, banner-on-every-function-entry is noisy UX — once the user has acknowledged `Show-Warning`, re-displaying the banner inside `Invoke-Win11Debloat` adds nothing. Consider banner-once at top-level main, then `Show-Section -Title "..."` for sub-sections.
- **Target phase:** P4

### F9 — `Test-InternetConnection` uses `Test-Connection` (ICMP) which is often firewalled
- **Severity:** info
- **Category:** correctness (note only)
- **Location:** scripts/win11_debloat.ps1:130–155
- **Local notes:** `Test-Connection -ComputerName "8.8.8.8" -Count 1` sends an ICMP echo request. Many corporate firewalls block outbound ICMP entirely (or only allow it to specific destinations), which would make this function return `$false` on a host that *does* have working outbound HTTPS — and the script would refuse to run even though `Invoke-RestMethod` on line 196 would have succeeded. A better probe given the actual dependency is `Invoke-WebRequest -Uri 'https://debloat.raphi.re/' -Method Head -UseBasicParsing -TimeoutSec 5` which tests the actual transport the script needs. No behavior change recommended right now — flagging for the P4 pass alongside the F8 banner consolidation.
- **Target phase:** —

## Out-of-scope notes
- The Win11Debloat upstream project (`https://github.com/Raphire/Win11Debloat`) is itself a mature, well-maintained debloater (BSD-style license, active issue tracker). The local file's grade-D rating is not a comment on the upstream payload's quality — it is a comment on the wrapper's lack of pinning, hashing, and confirmation discipline around fetching it. If the maintainer policy decision is "we trust raphi.re/Win11Debloat unconditionally," then F1's recommendations are over-engineered; if the policy is "every byte that runs on a customer machine must be auditable," then F1 is the minimum bar.
- `Test-Connection -Count 1` (lines 143, 148) emits noise on PS 7+ where the cmdlet's default output verbosity changed; `$null = Test-Connection ... -ErrorAction Stop` is the right idiom and is what's used here. No change.
- The `try { … 8.8.8.8 … } catch { try { … 1.1.1.1 … } catch { return $false } }` nested-try pattern (lines 142–154) is verbose but correct. A flatter alternative is `('8.8.8.8','1.1.1.1') | ForEach-Object { try { Test-Connection -ComputerName $_ -Count 1 -ErrorAction Stop; return $true } catch {} } ; return $false` — same behavior in fewer lines. P4-or-skip.
- The script has zero `-ErrorAction SilentlyContinue` occurrences — C4 has nothing to do here. Notable because it's the first script in the audit set that is fully clean on C4.
- The script has zero `Get-WmiObject` occurrences — C3 has nothing to do here.
- The script has zero direct mutation cmdlets (`Remove-AppxPackage`, `Set-ItemProperty`, `New-ItemProperty`, `Set-MpPreference`, `Disable-WindowsOptionalFeature`, `Set-Service`, `Stop-Service`, `Disable-ScheduledTask`) — they all live in the downloaded payload. The Defender-modification check (`MpPreference|Defender|MsMpEng|Windows Defender` regex) matches zero lines in this file; the wrapper does not directly touch Windows Defender. **Note:** the downloaded Win11Debloat payload may toggle Defender depending on which menu options the user selects upstream — this risk is owned by F1 (remote-fetch hardening), not by a separate Defender-specific local finding.
- The trailing blank line at line 287 is harmless.
