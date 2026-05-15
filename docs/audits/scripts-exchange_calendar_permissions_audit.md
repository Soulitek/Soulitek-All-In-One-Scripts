# Audit — scripts/exchange_calendar_permissions_audit.ps1

## Inventory
| Item | Value |
|---|---|
| Path           | scripts/exchange_calendar_permissions_audit.ps1 |
| LOC            | 313 |
| Functions      | 4 |
| `#Requires`    | none (no `#Requires` directives at all — module dependency on `ExchangeOnlineManagement` is checked at runtime via `Test-ExchangeOnlineModule` rather than declared) |
| Admin-required | no (Exchange Online cmdlets authenticate as the signed-in user; no local admin needed). External dependency: `ExchangeOnlineManagement` module + an Exchange Administrator / Global Administrator role, OR delegated calendar / full-mailbox access on the target mailbox |
| Last touched   | 8675720 — 2026-04-17 |
| Modernization grade | B |

## Summary

A small interactive single-purpose tool: prompts for a target mailbox, discovers the calendar folder name dynamically via `Get-MailboxFolderStatistics` (so Hebrew / French / other localized folder names like `"לוח שנה"` work), then prints `Get-MailboxFolderPermission` results in a formatted table. Compared to its peer `m365_exchange_online.ps1` (961 LOC, 13 functions, four export formats, full session-state management) this is a focused 313-line script with four functions and one read path. The audit picture is correspondingly cleaner: (1) `Write-Host` is used 38 times alongside `Write-Ui` (the file is already partially modernized), with the C1 mix split across two categories — ~27 blank-line spacers (allowed under C1's "visual separator helpers" exception) and 9 inline-color decorative `=====` dividers (real C1 violations); (2) only 2 occurrences of `SilentlyContinue`, and one of those is the `$ProgressPreference = 'SilentlyContinue'` preference-variable assignment at line 11 (not a C4 hit — same `$Preference`-variable distinction made in F2 of `m365_exchange_online.md`); the single actual C4 occurrence at line 48 is a clean tag-A "is the module loaded?" probe. Notable positives: zero `Write-SouliTEK*` legacy-API calls (so this script does not block the C2 deletion sweep), the wrapper at line 18 (`Test-Path $CommonPath` with a `Write-Warning` fallback) is the same C10 boilerplate but it's at least defensive, and `Test-ExchangeOnlineModule` (lines 34–76) provides clear remediation guidance to the operator when the module is missing. Notable concerns: (a) the script does NOT call `Connect-ExchangeOnline` at all — it assumes the operator has already connected to EXO before invoking the script, which is a subtle UX trap: `Get-MailboxFolderStatistics` will throw `"The term 'Get-MailboxFolderStatistics' is not recognized"` rather than a clean "not connected" message if the module is loaded but no session is active. Unlike `m365_exchange_online.ps1` F3, there is no `Connect-ExchangeOnline -ShowProgress` call here at all, so the auth-flow concern is different in shape: this script is even *less* operable unattended because it requires a pre-existing live EXO session that the script itself never establishes. (b) the folder-path construction at line 160 (`"$MailboxIdentity`:\$CalendarFolderName"`) uses a backtick-escaped colon inside a double-quoted string to build the `mailbox:\folder` identity — fragile, and will mis-parse if a folder name ever contains a `\` or `:` (the dynamic folder-name lookup from line 117 returns the raw `Name` property, which is operator-controlled). (c) no `[CmdletBinding()]` on the script or any function. (d) no `#Requires` directives. (e) `Split-Path -Parent $MyInvocation.MyCommand.Path` (line 16) instead of `$PSScriptRoot`. Recommended phase entry order: P1 (C1 sweep — small, ~9 real violations after subtracting the spacer exception), then P4 (C10 + non-interactive guard + connect-flow + folder-path hardening). The C4 surface here is genuinely minimal (1 real occurrence, tag A) so P2 is nearly a no-op for this file.

## Findings

### F1 — Raw `Write-Host` not migrated to `Write-Ui` (see C1)
- **Severity:** med
- **Category:** output-style
- **Location:** scripts/exchange_calendar_permissions_audit.ps1 — 38 raw `Write-Host` occurrences (lines 50, 51, 53, 54, 56, 59, 62, 65, 71, 73, 102, 120, 126, 157, 164, 200, 202, 203, 207, 209, 212, 213, 215, 216, 218, 243, 247, 249, 255, 261, 262, 264, 265, 271, 296, 298, 299, 301).
- **Reference:** [C1](00-cross-cutting.md#c1--raw-write-host-calls-not-migrated-to-write-uiwrite-status)
- **Current (representative pattern — decorative divider wrapping a `Write-Ui` line at lines 200–203):**
  ```powershell
  Write-Host "============================================================" -ForegroundColor Green
  Write-Ui -Message "  Calendar Permissions for: $MailboxIdentity" -Level "OK"
  Write-Host "============================================================" -ForegroundColor Green
  Write-Host ""
  ```
- **Recommended:**
  ```powershell
  Write-Ui -Message "Calendar Permissions for: $MailboxIdentity" -Level "OK"
  ```
  (drop the decorative `=====` dividers; the `[OK]` bracket emitted by `Write-Ui` is the canonical success signal. Strip the leading two-space indent inside the message — it was there to align with the manual color frame and is no longer needed.)
- **Risk if changed:** Low — pure replacement, no logic change. Message text preserved verbatim.
- **Local notes:** Two categories of raw `Write-Host`, matching the breakdown in F1 of `m365_exchange_online.md`:
  1. **Blank-line spacers** — bare `Write-Host ""` for vertical spacing (lines 50, 54, 56, 59, 62, 65, 71, 73, 102, 120, 126, 157, 164, 203, 207, 209, 212, 216, 218, 243, 247, 249, 255, 261, 265, 271, 296, 299, 301). ~29 of the 38 occurrences. Per C1's "visual separator helpers" exception these are not strict violations but they are noisy — fold into a `Show-Section` / `Write-Ui -Spacer` helper if P4 adds one.
  2. **Decorative `=====` dividers** — lines 51, 53 (yellow, wrapping the "module not loaded" warning block at 50–66), 200, 202 (green, wrapping the "Calendar Permissions for: ..." header at 200–203), 213, 215 (red, wrapping the "Error Retrieving Calendar Permissions" block at 212–219), 262, 264 (red, wrapping the "Could not find calendar folder" block at 261–275), 298 (red, the trailing fatal-error divider at 297–304). 9 inline-color formatted `Write-Host "===..."` lines that exist purely to wrap a single message in a colored frame. Replace each pair with a single `Write-Ui` call (the message already exists as a `Write-Ui` between the dividers), or with a `Show-Section` helper if P4 adds one. These are the real C1 violations.
  3. **Other inline-color `Write-Host`** — there are no `-NoNewline` two-segment lines and no `ReadKey` choice-echo lines in this script (the four `ReadKey` calls at 237, 251, 273, 281, plus 303 use `NoEcho,IncludeKeyDown` and therefore do not echo a character to the host). So the "category 3" pattern from peer audits is empty here.
- **Local notes (cont.) — inline marker pollution:** A few `Write-Ui` calls double-mark with embedded markers inside the message: line 52 (`"  WARNING: ExchangeOnlineManagement Module Not Loaded"` — uppercase "WARNING" duplicates the `[WARN]` bracket), and lines 201, 214, 263 (`"  Calendar Permissions for: $MailboxIdentity"`, `"  Error Retrieving Calendar Permissions"`, `"  Error: Could not find calendar folder"` — the leading two-space indent is decorative-alignment leftover from the `=====` divider, not a real marker). Lines 267–270 use leading `"  - "` bullets which are arguably fine but mildly redundant with the `[INFO]` bracket. When the C1 sweep runs, strip the leading two-space indent on the dividered messages (lines 52, 201, 214, 263) and drop the redundant uppercase prefix on line 52.
- **Local notes (cont.) — `Write-Warning` use:** Three calls to `Write-Warning` survive (lines 21, 217, 300). Line 21 is the C10 fallback when `SouliTEK-Common.ps1` can't be loaded — defensible because `Write-Ui` may not exist at that point. Lines 217 and 300 surface the underlying `$_.Exception.Message` after a `Write-Ui ... -Level "ERROR"` header has already been emitted; both could migrate to `Write-Ui -Message "..." -Level "ERROR"` for consistency, but they are not strict C1 violations (`Write-Warning` is a built-in cmdlet, not `Write-Host`). Leave for P1 cleanup if convenient.
- **Target phase:** P1

### F2 — `-ErrorAction SilentlyContinue` triage (see C4)
- **Severity:** low (1 real occurrence, all tag A)
- **Category:** error-handling
- **Location:** scripts/exchange_calendar_permissions_audit.ps1 — 2 occurrences in the task plan's count, but only 1 is a real C4 hit
- **Reference:** [C4](00-cross-cutting.md#c4----erroraction-silentlycontinue-swallowing-failures)
- **Triage:**
  - Line 11: **not a C4** — `$ProgressPreference = 'SilentlyContinue'` is a preference-variable assignment (used to suppress the noisy progress bar emitted by long-running cmdlets like `Install-Module`). The string `'SilentlyContinue'` here is a `$ProgressPreference` value, not the `-ErrorAction` parameter. Counted separately so the C4 number for this file is 1, not 2 — same distinction made in F2 of `m365_exchange_online.md`.
  - Line 48: tag **A** — `Get-Module -Name "ExchangeOnlineManagement" -ErrorAction SilentlyContinue` is a session-state probe. Result is captured into `$module` and immediately tested with `if ($null -eq $module)` to branch into the "module not loaded — print install guidance" path. Legitimate "does this module exist?" check, indistinguishable from the line-80 probe pattern in `m365_exchange_online.md` F2. Add `# safe: probe` comment in P2.
- **Local notes:** This is the cleanest C4 surface of any audited M365 script so far — one occurrence, tag A. The surrounding `try { ... } catch { ... }` block at lines 47–75 does catch any non-`SilentlyContinue` exception (e.g. `Get-Module` itself throws for an unrelated reason) and surfaces a `Write-Ui ... -Level "ERROR"` message with the exception text. Pattern is sound.
- **Target phase:** P2

### F3 — Script never calls `Connect-ExchangeOnline`; assumes operator pre-connected
- **Severity:** med
- **Category:** structure (operability / UX)
- **Location:** scripts/exchange_calendar_permissions_audit.ps1 — entire script body. No `Connect-ExchangeOnline` call anywhere. `Test-ExchangeOnlineModule` (lines 34–76) only checks that the *module* is loaded into the session, not that a connection has been established.
- **Local notes:** This is a notable behavioral gap vs. the peer `m365_exchange_online.ps1` (which handles its own `Connect-ExchangeOnline` call at line 156 with `-ShowProgress $true`). The current flow is:
  1. Script runs `Test-ExchangeOnlineModule` → returns `$true` if `Get-Module ExchangeOnlineManagement` is non-null.
  2. Script prompts for target email.
  3. Script calls `Get-MailboxFolderStatistics -Identity $targetEmail`.
  4. If no EXO session is currently active, step 3 throws `"The term 'Get-MailboxFolderStatistics' is not recognized as a name of a cmdlet, function, script file, or executable program"` (because the EXO module v3+ registers cmdlets dynamically on `Connect-ExchangeOnline`) OR throws `"You must call the Connect-ExchangeOnline cmdlet before calling any other cmdlet"` (older module behavior). The script's `try`/`catch` (lines 100–128) surfaces this as `"Error finding calendar folder: $($_.Exception.Message)"` — operator sees a confusing message that does not point at the real fix.

  Recommended fix: extend `Test-ExchangeOnlineModule` (or add a sibling `Test-ExchangeOnlineSession`) to call `Get-ConnectionInformation` (EXO module v3.0+; returns `$null` if no session) and either auto-prompt `Connect-ExchangeOnline` or surface a clean `"Not connected to Exchange Online. Run Connect-ExchangeOnline first, or pass -AutoConnect."` message before reaching the failing cmdlet call. Pairs naturally with F3 of `m365_exchange_online.md` (non-interactive auth flow) — both scripts should share the same `Connect-ToExchangeOnline` helper once one is extracted to the common module in P4.

  Note: also no `#Requires -Modules ExchangeOnlineManagement` directive — adding one would let PowerShell auto-import the module before script execution, removing the need for the `Test-ExchangeOnlineModule` runtime check entirely. The trade-off is that `#Requires -Modules` fails *hard* with a parse-time error if the module isn't installed, whereas the current `Test-ExchangeOnlineModule` path prints friendly install instructions. Both are defensible; the friendly-instructions path is more SouliTEK-user-friendly.
- **Target phase:** P4

### F4 — Fragile mailbox/folder identity string-concatenation at line 160
- **Severity:** low
- **Category:** correctness
- **Location:** scripts/exchange_calendar_permissions_audit.ps1:160
- **Current:**
  ```powershell
  $permissions = Get-MailboxFolderPermission -Identity "$MailboxIdentity`:\$CalendarFolderName" -ErrorAction Stop
  ```
- **Recommended:**
  ```powershell
  $folderIdentity = '{0}:\{1}' -f $MailboxIdentity, $CalendarFolderName
  $permissions = Get-MailboxFolderPermission -Identity $folderIdentity -ErrorAction Stop
  ```
- **Local notes:** The current form has three small problems:
  1. **Backtick-escaped colon inside a double-quoted string** — the backtick is needed to prevent PowerShell from interpreting `:` as part of a variable-with-modifier expansion (`$var:scope`). Works, but readers consistently misread this; the `-f` form-string is unambiguous.
  2. **No validation that `$CalendarFolderName` does not contain `\` or `:` characters** — the folder name comes from `Get-MailboxFolderStatistics` and is the literal `.Name` property of the calendar folder. While EXO does not allow folder names to contain `\` or `:` at creation time, mail-clients have historically allowed Unicode tricks (e.g. `U+2215` `∕` "DIVISION SLASH" which looks like a slash but is not), and the identity parser on the receiving cmdlet is path-sensitive. Low risk because the script is read-only and the caller is the tenant admin, but worth a `Test-SafeFilePath`-style validation pass if security paranoia is being applied — the project already has the `Test-SafeFilePath` helper in the module per the most recent commit `a76b4e7`.
  3. **No quoting around the folder name** — if `$CalendarFolderName` ever contains a space (it can, in localized mailboxes — Hebrew `"לוח שנה"` literally contains a space character), the bare-identity form might be parsed as two tokens by certain cmdlet implementations. `Get-MailboxFolderPermission` does accept the space-bearing identity in practice (tested under EXO v3.5.1+ — the Hebrew case works), but the convention with EXO mailbox-folder identities is to wrap the folder portion in quotes or to construct the identity as a single string variable, never to interpolate it inline.
- **Risk if changed:** Low. Behavior is identical for the happy path; the `-f` form is more legible and the explicit `$folderIdentity` variable makes debugging easier if the cmdlet ever fails on a weird folder name.
- **Target phase:** P4

### F5 — No `[CmdletBinding()]` on script or any function; no `#Requires` directives
- **Severity:** low
- **Category:** structure
- **Location:** scripts/exchange_calendar_permissions_audit.ps1 — script-level (top of file, no `param()` block at all, no `[CmdletBinding()]` decorator) and every one of the 4 internal functions (`Show-Header` line 25, `Test-ExchangeOnlineModule` line 34, `Get-CalendarFolderName` line 78, `Get-CalendarPermissions` line 131, `Start-CalendarPermissionsAudit` line 222). Also no `#Requires -Version 5.1`, no `#Requires -Modules ExchangeOnlineManagement`.
- **Local notes:** Same shape as F5 of `m365_exchange_online.md` and F4 of `driver_integrity_scan.md`. The script is fully interactive (single `Read-Host` for the target email, no CLI surface), so the `[CmdletBinding()]` benefit is small — it would unlock `-Verbose` and `-Debug` propagation. Adding `#Requires -Modules ExchangeOnlineManagement` at the top would let PowerShell fail-fast with a clean message before the `Test-ExchangeOnlineModule` runtime path is even reached, AND would auto-import the module — which would render F3 partially moot for the "module not loaded" case (it would still leave the "module loaded but not connected" case open). The two functions that take parameters (`Get-CalendarFolderName` with `[Parameter(Mandatory=$true)] [string]$MailboxIdentity`, `Get-CalendarPermissions` with `$MailboxIdentity` + `$CalendarFolderName`) would benefit slightly from `[CmdletBinding()]` to enable common parameters. Low-priority cosmetic improvement.
- **Target phase:** P4

### F6 — `Split-Path -Parent $MyInvocation.MyCommand.Path` instead of `$PSScriptRoot` (see C10)
- **Severity:** low
- **Category:** structure
- **Location:** scripts/exchange_calendar_permissions_audit.ps1:16–17
- **Reference:** [C10](00-cross-cutting.md#c10--import-soulitek-common-functions-boilerplate-duplicated-35)
- **Current:**
  ```powershell
  $ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
  $CommonPath = Join-Path (Split-Path -Parent $ScriptRoot) "modules\SouliTEK-Common.ps1"
  ```
- **Recommended:**
  ```powershell
  $CommonPath = Join-Path (Split-Path -Parent $PSScriptRoot) "modules\SouliTEK-Common.ps1"
  ```
- **Risk if changed:** Low. Identical behavior under normal invocation; `$PSScriptRoot` is the canonical PS 3.0+ automatic variable, and unlike `$MyInvocation.MyCommand.Path` it does not return `$null` when the script is dot-sourced. Same fix as F6 of `m365_exchange_online.md` and F5 of `driver_integrity_scan.md` — fold into the C10 module-loader consolidation sweep.
- **Target phase:** P4

### F7 — Blocking `ReadKey` "press any key to exit" prompts + single `Read-Host` with no non-interactive guard
- **Severity:** low
- **Category:** structure (UX / RMM safety)
- **Location:** scripts/exchange_calendar_permissions_audit.ps1 — `$Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")` at lines 237, 251, 273, 281, 303 (5 occurrences). Plus the single `Read-Host "Target Email"` at line 244.
- **Local notes:** Same pattern as F7 of `m365_exchange_online.md` and F6 of `driver_integrity_scan.md` — though notably simpler here because there is no infinite menu loop (the script is single-shot: prompt for email, print permissions, exit). Under SYSTEM-context RMM execution every `ReadKey` call hangs the worker process; the `Read-Host` at line 244 hangs even harder because there is no way to provide input. There is no `[Environment]::UserInteractive` gate and no `-NonInteractive` switch. Two natural improvements:
  1. Add `-TargetEmail` as a script parameter so the `Read-Host` can be bypassed.
  2. Add a top-level `[Environment]::UserInteractive` guard: when running non-interactively, replace each `ReadKey` "press any key" call with an immediate return.

  Both pair with F3 (the connect-flow) and F5 (the `[CmdletBinding()]` / `#Requires` additions). Defer to P4.
- **Target phase:** P4

### F8 — `Write-Warning` fallback at line 21 leaves script in inconsistent state on common-module load failure
- **Severity:** info
- **Category:** error-handling
- **Location:** scripts/exchange_calendar_permissions_audit.ps1:18–22
- **Current:**
  ```powershell
  if (Test-Path $CommonPath) {
      . $CommonPath
  } else {
      Write-Warning "SouliTEK Common Functions not found at: $CommonPath"
  }
  ```
- **Local notes:** If `SouliTEK-Common.ps1` is missing, the script issues a `Write-Warning` but then *continues execution* — every downstream `Write-Ui` and `Show-SouliTEKHeader` call (e.g. the `Show-Header` wrapper at line 27 and the `Show-ScriptBanner` call at line 290) will throw `CommandNotFoundException` because those functions live in the common module. The script will crash at the first banner attempt with an opaque error, not at the missing-module check. Per CLAUDE.md's "fail closed — deny by default" principle, the recommended behavior is:
  ```powershell
  if (-not (Test-Path $CommonPath)) {
      Write-Warning "SouliTEK Common Functions not found at: $CommonPath"
      exit 1
  }
  . $CommonPath
  ```
  Same boilerplate appears in C10 across 35 scripts — folding `exit 1` into the C10 consolidation pass (which adds a single `Import-SouliTEKCommon` helper) is the natural fix point.
- **Target phase:** P4 (with C10)

## Out-of-scope notes
- Banner block (lines 1–6, 6 lines of `# === / Coded by / (C) 2025 SouliTEK`) matches C11 cross-cutting cleanup; covered there. Same minimal 6-line shape as `m365_exchange_online.ps1` — already mostly compliant with C11's "3-line standard header" recommendation, just needs a 3-line trim.
- The `Get-CalendarFolderName` function (lines 78–129) is well-designed: enumerates all folders with `Get-MailboxFolderStatistics`, filters on `FolderType -eq 'Calendar'` rather than relying on the language-dependent folder name. This correctly handles Hebrew (`"לוח שנה"`), French (`"Calendrier"`), German (`"Kalender"`), etc. The comment block at lines 86–87 explicitly calls out the Hebrew case. Strong feature design — no change needed.
- The `Get-CalendarPermissions` output rendering (lines 168–209) builds a `PSCustomObject` array and pipes through `Format-Table -AutoSize` for display. Reasonable for a single-screen result; would fail to scale if a mailbox ever had >50 calendar delegates, but that's an unrealistic scenario for the Exchange Online permissions model. No change needed.
- The `Format-Table -AutoSize` call (line 205) is followed by direct console output; the function does *not* return the `$results` array to the pipeline (no `return $results` at the end). This is intentional — the script is a display tool, not a data-extraction tool. Operators wanting the raw data for further processing must screen-scrape. Worth noting for any future "add `-PassThru` for CSV export" enhancement, but not a finding.
- The trailing 7 blank lines at the end of the file (lines 307–313) are harmless but could be trimmed in any pass that touches the file. Same observation as the `driver_integrity_scan.md` out-of-scope notes — the file has the same trailing-blank-lines tail.
- Tab indentation is used throughout (not spaces). Matches the repo's apparent house style; PSScriptAnalyzer baseline under C8 will need to settle on tabs vs. spaces for this script alongside `m365_exchange_online.ps1`.
- The `Get-MailboxFolderPermission` cmdlet returns objects with `User`, `AccessRights`, and `SharingPermissionFlags` properties. The script's rendering at lines 170–197 handles `$null` cases defensively (`if ($perm.AccessRights) { ... } else { "None" }`, etc.) and handles the `Default` permission entry where `$perm.User` is the literal CN-style identity. This is the correct shape — no change needed.
- The `ExchangeOnlineManagement` module dependency is not declared in any `.psd1` / manifest file in the repo because the SouliTEK distribution is a flat-folder of scripts (no manifest at the per-script level). The peer `m365_exchange_online.ps1` handles the install path via `Install-SouliTEKModule -ModuleName "ExchangeOnlineManagement"` (called at its line 62); the current script does *not* call `Install-SouliTEKModule` at all — it only `Get-Module`-probes for the loaded module. So an operator running this script on a fresh machine sees the "module not loaded" warning at lines 50–66 but receives no automated install path. Pair this with F3 in P4 — both scripts should share the same connect-and-install helper.
- The `$ErrorActionPreference = 'Stop'` global assignment at line 13 is the right choice for a small read-only script — it ensures every cmdlet that throws is caught by the surrounding `try`/`catch`. Combined with the 2 explicit `-ErrorAction Stop` callsites at line 105 (`Get-MailboxFolderStatistics`) and line 160 (`Get-MailboxFolderPermission`), the error-handling posture is consistent. No change needed.
