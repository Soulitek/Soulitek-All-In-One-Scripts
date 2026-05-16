# Audit — scripts/local_admin_checker.ps1

## Inventory
| Item | Value |
|---|---|
| Path           | scripts/local_admin_checker.ps1 |
| LOC            | 630 |
| Functions      | 9 |
| `#Requires`    | `#Requires -Version 5.1` |
| Admin-required | yes (de facto; `Invoke-SouliTEKAdminCheck -Required` on line 609 gates execution. Not declared via `#Requires -RunAsAdministrator` because `Get-LocalGroupMember` against the local Administrators group needs elevation under most Windows configurations, and `Get-LocalUser` also typically requires it). |
| Last touched   | 8675720 — 2026-04-17 |
| Modernization grade | B |

## Summary

A read-only menu-driven auditor that enumerates members of the local `Administrators` group via `Get-LocalGroupMember`, classifies each account against a hard-coded "standard accounts" allow-list and a "suspicious patterns" deny-list, then renders a per-user risk dossier and an optional CSV/TXT/HTML export to Desktop. Substantially cleaner than the comparable `driver_integrity_scan.ps1` baseline: only 1 `Get-WmiObject` violation (zero — the script uses `Get-LocalUser` / `Get-LocalGroup` / `Get-LocalGroupMember` throughout, so C3 does not apply), only 1 `-ErrorAction SilentlyContinue` site (line 109, tag **A**), and 1 surviving legacy `Write-SouliTEKError` call (line 134, C2). The primary issue is C1: 63 `Write-Host` calls that mix three subcategories — bare `Write-Host ""` spacers, `====` rule-separators with `-ForegroundColor`, and inline two-half color formatting (`Write-Host "Label: " -NoNewline` + `Write-Host $value -ForegroundColor X`). The two-half color pattern is structurally different from `driver_integrity_scan.ps1`'s simple inline-color violations and needs a small `Write-Ui`/`Write-KeyValue` helper or a manual rewrite per call. Secondary concerns: no `[CmdletBinding()]` on any of the 9 functions or on the script (no `param()` block at all); `Split-Path -Parent $MyInvocation.MyCommand.Path` instead of `$PSScriptRoot` (line 25); a `do { ... } while ($true)` menu loop with blocking `Read-Host` on line 614 (same C-class issue as F6 in `driver_integrity_scan.ps1`); hard-coded Desktop export path with no override (line 459); and a known correctness bug at line 109 where the script silently swallows local-user lookup failures and reports `Enabled=null` / `PasswordNeverExpires=null` to the operator rather than surfacing the error. The "suspicious patterns" list (lines 51–55) deserves a sanity-check note — `"admin"` and `"user"` are so broad they will false-positive on virtually every domain admin (`john.admin`, `svc-user-sync`). Recommended phase entry order: P1 (C1 + C2), then P2 (C4 triage — single occurrence).

## Findings

### F1 — Raw `Write-Host` calls not migrated to `Write-Ui` (see C1)
- **Severity:** med
- **Category:** output-style
- **Location:** scripts/local_admin_checker.ps1 — 63 occurrences. Sample lines: 232, 248–249, 252–253, 256–257, 270–271, 316–320, 322, 327, 329–333, 335, 347, 360–364, 376, 382, 384, 392, 403, 418–421, 424, 427, 446, 518–522, 527, 533, 535, 537, 539, 541, 547, 554–555, 569, 572–573, 579–581, 584, 587, 590, 593, 595–597.
- **Reference:** [C1](00-cross-cutting.md#c1--raw-write-host-calls-not-migrated-to-write-uiwrite-status)
- **Current (representative two-half pattern — lines 248–249):**
  ```powershell
  Write-Host "      Local Account: " -NoNewline -ForegroundColor Gray
  Write-Host $(if ($AdminUser.IsLocal) { "Yes" } else { "No" }) -ForegroundColor $(if ($AdminUser.IsLocal) { "Cyan" } else { "Yellow" })
  ```
- **Recommended:**
  ```powershell
  Write-Ui -Message "      Local Account: $(if ($AdminUser.IsLocal) { 'Yes' } else { 'No' })" -Level "INFO"
  ```
  (Or, if a `Write-KeyValue -Key 'Local Account' -Value $val -ValueColor Cyan` helper is added in P4, prefer that. The lost-detail here is the per-value color contrast — `Yes` in cyan vs `No` in yellow. `Write-Ui` will collapse both branches to the `[INFO]` level color, which is acceptable per STYLE_GUIDE.md but operators do lose the at-a-glance color cue.)
- **Risk if changed:** Low for text fidelity (message preserved verbatim). Medium for UX — the two-half color pattern is intentionally rendering per-value semantic color (green for "Enabled=Yes", red for "Enabled=No"), and `Write-Ui` does not currently support that. Either accept the regression in P1 or build the helper first in P4 and gate this finding behind it.
- **Local notes:** Three categories of raw `Write-Host`:
  1. **Bare spacer calls** — `Write-Host ""` for vertical spacing (lines 232, 316, 320, 322, 327, 335, 347, 360, 364, 376, 392, 403, 418, 424, 427, 446, 518, 522, 527, 533, 541, 547, 554, 573, 579, 581, 584, 587, 590, 593, 595, 597). Per the C1 "visual separator helpers" exception these are not strict violations, but they are noisy. Migrate to a `Show-Section` / `Write-Ui -Spacer` helper if one lands in P4.
  2. **`====` rule separators with `-ForegroundColor`** — `Write-Host "==…==" -ForegroundColor Cyan|Yellow|Magenta` (lines 317, 319, 361, 363, 382, 384, 419, 421, 519, 521, 555, 569, 572, 580, 596). These should become a single `Show-Section -Color Cyan` helper call. Per-occurrence C1 violations until the helper exists.
  3. **Two-half inline color formatting** — `Write-Host "Label: " -NoNewline` followed by `Write-Host $value -ForegroundColor X` (line pairs 248/249, 252/253, 256/257, 270/271, 329/330, 331/332, 333/334-as-Write-Ui, 535/536-as-Write-Ui, 537/538-as-Write-Ui, 539/540-as-Write-Ui). Lines 333 and 535/537/539 already have the second half as `Write-Ui` while the first half is still `Write-Host` — half-migrated and inconsistent. The clean fix is the `Write-KeyValue` helper above; the cheap fix is to merge each pair into a single `Write-Ui` call and accept the color loss.
- **Target phase:** P1 (with the caveat that two-half formatting is best addressed after the P4 helper lands)

### F2 — Legacy `Write-SouliTEKError` API call (see C2)
- **Severity:** low
- **Category:** output-style
- **Location:** scripts/local_admin_checker.ps1:134
- **Reference:** [C2](00-cross-cutting.md#c2--dead-duplicate-output-api)
- **Current:**
  ```powershell
  Write-SouliTEKError "Failed to get local administrators: $($_.Exception.Message)"
  ```
- **Recommended:**
  ```powershell
  Write-Ui -Message "Failed to get local administrators: $($_.Exception.Message)" -Level "ERROR"
  ```
- **Risk if changed:** Low — pure API swap. Single call site, isolated to the `catch` block of `Get-LocalAdminUsers`. This is one of the 12 remaining C2 callers across the codebase (per F2 of driver_integrity_scan.md) — needs to go before C2's "delete the five legacy functions" step can land.
- **Target phase:** P1

### F3 — `-ErrorAction SilentlyContinue` triage (see C4)
- **Severity:** med (per-occurrence — single site here)
- **Category:** error-handling
- **Location:** scripts/local_admin_checker.ps1 — 1 occurrence
- **Reference:** [C4](00-cross-cutting.md#c4----erroraction-silentlycontinue-swallowing-failures)
- **Triage:**
  - Line 109: tag **A** (with reservation — see Local notes). `$localUser = Get-LocalUser -Name $username -ErrorAction SilentlyContinue` inside a `try { ... } catch { }` block where the catch is empty (line 113–115, comment `# User might not exist locally`). The intent is "the principal we got from `Get-LocalGroupMember` may be a deleted local user, a SID-only orphan, or a domain user whose name happens to equal a local-user name — silently skip and leave `$userInfo` as `$null`." The downstream consumers (lines 125–128) handle `$null` correctly by writing `$null` into `IsEnabled`/`PasswordNeverExpires`/`LastLogon`/`Description`. So it is a legitimate "probe" use. Add `# safe: probe — principal may not exist as a local user` comment in P2.
- **Local notes:** The reservation: this is genuinely a tag-A "the lookup might not return anything, that's fine" pattern, but the consequence in the report rendering at line 251 (`if ($AdminUser.IsLocal -and $AdminUser.IsEnabled -ne $null)`) is that the operator silently does NOT see the `Enabled:` / `Password Never Expires:` / `Last Logon:` lines for any local admin whose `Get-LocalUser` lookup failed for a non-existence reason. A `Get-LocalUser` failure due to permissions or a corrupt SAM hive would also be swallowed and indistinguishable from "user not found." For a security-audit tool that exists to flag risky configurations, silently omitting risk-bearing fields is a soft failure mode. Consider in P2: split into two cases — `try { Get-LocalUser ... -ErrorAction Stop } catch [Microsoft.PowerShell.Commands.UserNotFoundException] { # genuinely absent } catch { Write-Ui -Message "Could not query local user '$username': $($_.Exception.Message)" -Level "WARN" }`. Marginal change; flagging for awareness.
- **Target phase:** P2

### F4 — No `[CmdletBinding()]` on script or any function
- **Severity:** low
- **Category:** structure
- **Location:** scripts/local_admin_checker.ps1 — script-level (no top-of-file `param()` block) and on all 9 functions: `Get-LocalAdminUsers` (line 61), `Test-SuspiciousAdmin` (line 141), `Show-AdminUserDetails` (line 214), `Show-ScanSummary` (line 281), `Invoke-FullScan` (line 354), `Show-SuspiciousAdmins` (line 396), `Export-ScanResults` (line 439), `Show-Help` (line 511), `Show-Menu` (line 560).
- **Local notes:** Two functions already accept structured `param()` blocks and would benefit immediately from `[CmdletBinding()]`: `Test-SuspiciousAdmin` (`param([PSCustomObject]$AdminUser)` line 146–148) and `Show-AdminUserDetails` (`param([PSCustomObject]$AdminUser, [int]$Index)` line 219–222). Adding `[CmdletBinding()]` to these two and to `Show-ScanSummary` (`param([array]$AdminUsers)` line 286–288) is free. Script-level is a different conversation: there is no CLI surface, the menu loop drives everything, and adding `[CmdletBinding()]` at the script top would require defining a `param()` block (currently absent). Reasonable P4 follow-up if/when a non-interactive entry point is added (e.g. `local_admin_checker.ps1 -ExportOnly -OutputDirectory C:\Reports`).
- **Target phase:** P4

### F5 — `Split-Path -Parent $MyInvocation.MyCommand.Path` instead of `$PSScriptRoot`
- **Severity:** low
- **Category:** structure
- **Location:** scripts/local_admin_checker.ps1:25
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
- **Risk if changed:** Low. `$PSScriptRoot` is the canonical PS 3.0+ form; `$MyInvocation.MyCommand.Path` returns `$null` under dot-source which would break the subsequent `Join-Path` on line 27. Same finding as F5 of driver_integrity_scan.md. C10 will eventually replace this block with `Import-SouliTEKCommon`.
- **Target phase:** P4 (fold into C10 sweep)

### F6 — Infinite menu loop with blocking `Read-Host` (no non-interactive exit)
- **Severity:** low
- **Category:** structure (UX / RMM safety)
- **Location:** scripts/local_admin_checker.ps1:612 (`do { ... } while ($true)`), `Read-Host` at line 614, plus `Wait-SouliTEKKeyPress` calls at lines 371, 393, 405, 436, 448, 508, 557.
- **Local notes:** Same C-class issue as F6 of driver_integrity_scan.md — fully interactive design, no `[Environment]::UserInteractive` gate, no `-NonInteractive` switch. Under SYSTEM/RMM context the `Read-Host` on line 614 will deadlock the worker. Lower-priority here than for `driver_integrity_scan.ps1` because this tool is purely read-only (no `winget upgrade --all`-style destructive path), so a hang is annoying but not data-loss-bearing. Defer to P4 unless a hang report comes in.
- **Target phase:** P4

### F7 — Hard-coded Desktop export path with no override
- **Severity:** info
- **Category:** structure
- **Location:** scripts/local_admin_checker.ps1:459 (`$desktopPath = [Environment]::GetFolderPath("Desktop")`)
- **Local notes:** `[Environment]::GetFolderPath("Desktop")` is slightly better than the `$env:USERPROFILE\Desktop` form used in `driver_integrity_scan.ps1` (F7 of that audit) — it respects redirected/OneDrive-backed Desktop folders correctly — but it still breaks under SYSTEM context (resolves to `C:\Windows\System32\config\systemprofile\Desktop` which may not exist) and offers no `-OutputDirectory` override. Pair with F4's `[CmdletBinding()]` add on `Export-ScanResults`: add `param([string]$OutputDirectory = [Environment]::GetFolderPath("Desktop"))`.
- **Target phase:** P4

### F8 — `$Script:SuspiciousPatterns` includes overly-broad tokens (`admin`, `user`)
- **Severity:** info
- **Category:** correctness (false-positive rate)
- **Location:** scripts/local_admin_checker.ps1:51–55, plus consumer at line 166 (`if ($usernameLower -like "*$pattern*")`)
- **Local notes:** The pattern list contains `"admin"` and `"user"` alongside the more specific `"test"`/`"temp"`/`"demo"`/`"guest"`/`"backup"`. Because the match is a substring wildcard (`-like "*$pattern*"`), this will tag every name containing the substring "admin" as suspicious — `Administrator` (already in `$Script:StandardAdmins` so skipped at line 154, but only the bare form; `admin.john` or `srv-admin` are NOT in the allow-list), every domain admin like `john.admin`, every service account like `svc-useradmin`, etc. Same problem for `"user"` matching `user.sync`, `useradmin`, `power-users`. The output gets noisy fast in any real AD-joined environment. Three options for P4:
  1. Tighten patterns to whole-word match: `if ($usernameLower -match "(^|[._-])($($Script:SuspiciousPatterns -join '|'))([._-]|$)")`.
  2. Remove `"admin"` and `"user"` from the list (probably correct — they overlap the very thing we're auditing).
  3. Split the list into "exact match" and "substring match" sublists.
  No urgent action; flagging for the author to decide. Note also that `"user1"`, `"user2"`, `"user3"` (line 54) are already redundant subsets of `"user"`.
- **Target phase:** —

### F9 — `$null`-comparison operand order reversed (style preference, PSScriptAnalyzer flag)
- **Severity:** info
- **Category:** style
- **Location:** scripts/local_admin_checker.ps1:251, 255 (`if ($AdminUser.IsEnabled -ne $null)`, `if ($AdminUser.PasswordNeverExpires -ne $null)`)
- **Local notes:** PSScriptAnalyzer's `PSPossibleIncorrectComparisonWithNull` rule wants `$null` on the left: `if ($null -ne $AdminUser.IsEnabled)`. The current form works correctly for scalar properties on a `PSCustomObject`, but the analyzer warning is harmless to fix and will surface when CI lands (C8). One-line edits each. Fold into the P1 C1 sweep.
- **Target phase:** P1 (incidental)

## Out-of-scope notes
- Banner block (lines 1–14, 14 lines of `# === / Coded by / IMPORTANT DISCLAIMER`) matches C11 cross-cutting cleanup; covered there. Shorter than the `driver_integrity_scan.ps1` equivalent.
- Common-module import block (lines 25–33) matches C10 cross-cutting cleanup; covered there.
- The `$Script:StandardAdmins` allow-list (lines 42–48) is a clean static lookup, no change needed. Note that `"Administrators"` (line 44) is the *group* name and would never appear as a `$AdminUser.Username` value from `Get-LocalGroupMember`, so it is dead — but harmless.
- `Get-LocalGroupMember -Group "Administrators"` (line 74) is the modern PS 5.1+ idiom; correctly chosen over WMI/CIM. No change.
- `Get-LocalUser -Name $username` (line 109) is similarly the correct modern idiom over `Get-WmiObject Win32_UserAccount`. No C3 exposure on this script at all.
- The principal-parsing block (lines 86–103) defensively handles null/empty principals, single-component names (no `\`), and missing domain — appropriately robust against the various shapes `Get-LocalGroupMember` can return (orphaned SIDs, deleted users, well-known SIDs). No change.
- `Test-SuspiciousAdmin` (lines 141–208) cleanly separates analysis from rendering — the function returns a `PSCustomObject` with `RiskLevel`/`Warnings`/`IsSuspicious` rather than printing directly. Good shape for a future P5 Pester test (`Test-SuspiciousAdmin -AdminUser $stub | Should -Be ...`).
- `Show-ScanSummary` (line 281) calls `Test-SuspiciousAdmin` once per user (line 298) and then `Show-AdminUserDetails` also calls it once per user (line 224), and then `Export-ScanResults` calls it a third time (line 463). For a typical machine with 3–10 admin accounts this is negligible, but on a domain controller with hundreds of domain-admin entries it would be wasteful. Memoize in P4 if perf complaints surface; not urgent.
- The `Export-SouliTEKReport` call (lines 503–505) cleanly delegates formatting to the module — good. The `-OpenAfterExport:($formats.Count -eq 1)` branch (line 505) intentionally suppresses auto-open when exporting all three formats at once, which is correct UX.
- The Help text (lines 511–558) is operator-facing documentation, well-structured. The double-mark inline markers (`[!]`, `[*]`, `[+]`, `! $warning`) inside `Write-Ui` messages at lines 274, 276, 338, 341, 344 are the same anti-pattern as F2 of 01-modules-SouliTEK-Common.md — strip the inline markers when doing the F1 C1 sweep so the `[LEVEL]` bracket emitted by `Write-Ui` is the only marker.
- Line 334 (`Write-Ui -Message $low -Level "OK"`) passes an integer as the `-Message` parameter; PowerShell coerces it to string but PSScriptAnalyzer may flag the type mismatch. Trivially fixed as `Write-Ui -Message "$low" -Level "OK"`.
- No trailing blank-line bloat; file ends cleanly at line 630.
