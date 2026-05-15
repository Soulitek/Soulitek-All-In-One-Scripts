# Audit — scripts/m365_exchange_online.ps1

## Inventory
| Item | Value |
|---|---|
| Path           | scripts/m365_exchange_online.ps1 |
| LOC            | 961 |
| Functions      | 13 |
| `#Requires`    | none (no `#Requires` directives at all — module dependency on `ExchangeOnlineManagement` is resolved lazily via `Install-SouliTEKModule`) |
| Admin-required | no (Exchange Online cmdlets authenticate as the signed-in user; no local admin needed). External dependency: `ExchangeOnlineManagement` module + an Exchange Administrator or Global Administrator role on the target tenant. |
| Last touched   | 8675720 — 2026-04-17 |
| Modernization grade | C |

## Summary

An interactive menu-driven Exchange Online mailbox reporter: connects to a tenant via `Connect-ExchangeOnline`, calls `Get-Mailbox -ResultSize Unlimited`, enriches each result with a per-mailbox `Get-MailboxStatistics` call, and exports the dataset as TXT / CSV / HTML. The dominant issue is (1) raw `Write-Host` is used 123 times alongside `Write-Ui` calls (so the file is already partially modernized but the mix is loud — STYLE_GUIDE.md C1 violation); the C2 legacy API is not called at all here, which is a notable positive vs. peer scripts. (2) Five `-ErrorAction SilentlyContinue` occurrences — one is a `$ProgressPreference` global (not a real C4 hit, see F2), four are real C4 occurrences split between three tag-A (legitimate probe / shutdown-path cleanup) and one tag-B (the per-mailbox `Get-MailboxStatistics` swallow at line 293, which silently degrades the report to "size 0.00 GB / Never" for any mailbox whose stats throw). (3) The mailbox enumeration is the C13 hotspot the task plan flagged: a sequential `foreach ($mailbox in $allMailboxes)` loop (line 286) issues one `Get-MailboxStatistics` round-trip per mailbox. At ~200–500 ms per call this is `O(N)` against the EXO REST endpoint and dominates wall-clock time for any tenant of meaningful size — a tenant of 500 mailboxes pays 100–250 s minimum. The `Get-Mailbox` call itself is fine (it pages internally via `-ResultSize Unlimited`), so the C13 candidacy is squarely on the *stats enrichment*, not on the mailbox listing. Auth flow is **interactive only** — `Connect-ExchangeOnline -ShowProgress $true` opens a browser; there is no `-AppId` / `-CertificateThumbprint` / `-ManagedIdentity` path, so this script cannot run unattended (RMM / SYSTEM context will hang on the auth window). Secondary concerns: no `[CmdletBinding()]` on the script or any of its 13 functions, no `#Requires` for PS version or for the ExchangeOnlineManagement module, the C11 banner block occupies lines 1–6, the C10 `Import SouliTEK Common Functions` boilerplate occupies lines 19–26, the script uses `Split-Path -Parent $MyInvocation.MyCommand.Path` instead of `$PSScriptRoot` (line 20), `Ensure-OutputFolder` uses an unapproved verb that PSScriptAnalyzer will flag (C8), and the mailbox size parser at line 336 is a fragile string-split that will break if the EXO `TotalItemSize.Value.ToString()` format ever changes. Recommended phase entry order: P1 (C1) + the F2 line-293 tag-B promotion, then P2 (rest of C4 triage), then P4 (C13 parallelisation + non-interactive auth flow).

## Findings

### F1 — Raw `Write-Host` not migrated to `Write-Ui` (see C1)
- **Severity:** med
- **Category:** output-style
- **Location:** scripts/m365_exchange_online.ps1 — 123 raw `Write-Host` occurrences (sample lines: 44, 60, 63, 65, 71, 75, 104, 105, 110, 112, 173, 175, 181, 183, 214, 215, 229, 231, 237, 239, 407, 409, 414, 416, 446, 465, 479, 480, 481, 810, 825, 834, 859, 867, 884, 885, 887, 889, 892, 893, 895, 907, 909, 937, 953, 955).
- **Reference:** [C1](00-cross-cutting.md#c1--raw-write-host-calls-not-migrated-to-write-uiwrite-status)
- **Current (representative pattern — divider + manual color formatting at lines 173–176):**
  ```powershell
  Write-Host ""
  Write-Host "============================================================" -ForegroundColor Green
  Write-Ui -Message "  [+] Exchange Online Connected Successfully" -Level "OK"
  Write-Host "============================================================" -ForegroundColor Green
  ```
- **Recommended:**
  ```powershell
  Write-Ui -Message "Exchange Online Connected Successfully" -Level "OK"
  ```
  (the `=====` dividers above and below the message are visual noise — the `[OK]` bracket emitted by `Write-Ui` is the canonical "success" signal; drop the dividers entirely or replace with a single `Show-Section` helper call once one exists.)
- **Risk if changed:** Low — pure replacement, no logic change. Message text preserved verbatim.
- **Local notes:** Four categories of raw `Write-Host`, in roughly the proportions of `driver_integrity_scan.ps1`'s F2:
  1. **Blank-line spacers** — bare `Write-Host ""` for vertical spacing (lines 60, 63, 65, 71, 75, 104, 109, 113, 123, 127, 135, 146, 152, 172, 176, 180, 184, 186, 191, 201, 208, 213, 218, 228, 232, 234, 236, 240, 242, 246, 258, 267, 274, 281, 410, 413, 417, 419, 430, 447, 451, 457, 460, 463, 466, 489, 494, 504, 560, 563, 565, 573, 583, 600, 603, 605, 610, 618, 628, 786, 789, 791, 799, 811, 814, 823, 826, 832, 835, 840, 845, 849, 852, 857, 860, 865, 868, 871, 894, 896, 906, 908, 953, 955). ~84 of the 123 occurrences. Per C1's "visual separator helpers" exception these are not strict violations but they are noisy — fold into a `Show-Section` / `Write-Ui -Spacer` helper if P4 adds one.
  2. **Decorative `=====` / `-----` dividers** — lines 105, 173, 175, 181, 183, 214, 229, 231, 237, 239, 407, 409, 414, 416, 446, 465, 810, 825, 834, 859, 867, 895, 907. Real C1 violations: 23 inline-color formatted `Write-Host "===..."` / `"---..."` lines that exist purely to wrap a single message in a colored frame. Replace the whole pattern with a single `Write-Ui` call or a `Show-Section` helper.
  3. **Inline-color formatting with `-NoNewline`** — lines 110, 215, 479, 480, 481, 884, 885, 887, 889, 892, 893, 909. Pre-`Write-Ui`-era manual two-segment lines like `Write-Host "Connection Status: " -NoNewline -ForegroundColor Gray` followed by `Write-Host "$status" -ForegroundColor $statusColor`. Clear C1 violations — these are exactly what `Write-Ui` was meant to replace.
  4. **Choice / echo lines** — `Write-Host $reconnectChoice.Character` (112), `Write-Host $confirm.Character` (217), `Write-Host $choice.Character` (937). These echo the suppressed `ReadKey` character to the host and are required to keep menu UX behavior; they are a `Write-Host` exception ("echo a keystroke"). Leave as-is or migrate to a `Write-Choice` helper if one is added in P4.
- **Local notes (cont.) — `Write-SummaryLine` is itself a `Write-Host` wrapper:** The helper at line 41–45 (`Write-Host ("{0,-$pad}: {1}" -f $Label, $Value) -ForegroundColor $Color`) is called 10 times in `Show-MailboxSummary` (lines 449, 450, 453, 454, 455, 456, 458, 459, 461, 462). Per the C1 exception, helpers may use `Write-Host` internally, but `Write-SummaryLine` would be a much cleaner shape if it called `Write-Ui` with a `-Level "INFO"` argument and dropped the per-call color override — half of the ten callers pass `"White"` or `"Gray"` which is just the default INFO style anyway.
- **Local notes (cont.) — minimal inline marker pollution:** Unlike `driver_integrity_scan.ps1` F2, this script does *not* double-mark its `Write-Ui` messages with embedded `[+]`/`[-]`/`[!]` brackets in most places. There are a handful of exceptions: lines 64, 72, 82, 122, 133, 158, 174, 182, 230, 238, 280, 408, 415. When the C1 sweep runs, strip those inline brackets so the `[LEVEL]` token emitted by `Write-Ui` is the only marker.
- **Target phase:** P1

### F2 — `-ErrorAction SilentlyContinue` triage (see C4)
- **Severity:** med
- **Category:** error-handling
- **Location:** scripts/m365_exchange_online.ps1 — 5 occurrences (the task plan's "5 SilentlyContinue" count includes the `$ProgressPreference = 'SilentlyContinue'` global assignment at line 15, which is not a C4 hit but a `$Preference` variable; the actual C4 occurrences are 4)
- **Reference:** [C4](00-cross-cutting.md#c4----erroraction-silentlycontinue-swallowing-failures)
- **Triage:**
  - Line 15: **not a C4** — `$ProgressPreference = 'SilentlyContinue'` is a preference-variable assignment (used to suppress the noisy module-install progress bar emitted by `Install-Module`). The string `'SilentlyContinue'` here is a `$ProgressPreference` value, not the `-ErrorAction` parameter. Counted separately so the C4 number for this file is 4, not 5.
  - Line 80: tag **A** — `Get-OrganizationConfig -ErrorAction SilentlyContinue` is a "are we currently connected to Exchange Online?" probe. Result is captured into `$orgInfo` and immediately tested with `if ($orgInfo)` to branch into the "already connected" path. Legitimate session-state probe. Add `# safe: probe` comment in P2.
  - Line 118: tag **A** — `Disconnect-ExchangeOnline -Confirm:$false -ErrorAction SilentlyContinue` runs on the "user chose to switch tenants" branch. If the disconnect throws (session already torn down server-side), the next `Connect-ExchangeOnline` call will re-auth and supersede whatever state was there. The surrounding `try { ... } catch { ... }` does have a real catch (lines 125–131) that surfaces `Write-Warning "Disconnect failed: ..."` and returns `$false`, but because of the `SilentlyContinue`, that catch will never fire — the disconnect will be silently skipped. **This is actually mildly broken**: the `try`/`catch` block is dead code as long as `SilentlyContinue` is on the cmdlet. Triage as tag **A** with a code-clarity note: either remove the redundant `try`/`catch`, OR change to `-ErrorAction Stop` and let the existing catch handle it. The behavior is unchanged in the "happy path" either way. Add a comment in P2.
  - Line 293: tag **B** — `Get-MailboxStatistics -Identity $mailbox.Identity -ErrorAction SilentlyContinue` inside the per-mailbox enrichment loop. When this throws (transient EXO throttling — HTTP 429 / "the request is throttled"; mailbox-not-yet-provisioned; or "the operation couldn't be performed because object 'X' couldn't be found" for soft-deleted mailboxes that still appear in `Get-Mailbox`), the catch is empty (the inline `# Silent fail` comment at line 295 acknowledges this) and the per-mailbox `$mailboxStats` stays `$null`. The downstream rendering then silently emits `MailboxSizeGB = "0.00"`, `ItemCount = 0`, and `LastActivity / LastMailboxLogon / LastMailboxAccess = "Never"` for that row — which looks indistinguishable in the report from a genuinely-empty mailbox. **This is the F2-B that the user will see**: a tenant with throttling-affected mailboxes will produce a CSV/HTML report that misreports mailbox utilization without warning. Recommended fix: replace with `try { Get-MailboxStatistics -Identity $mailbox.Identity -ErrorAction Stop } catch { Write-Ui -Message "Stats unavailable for $($mailbox.DisplayName): $($_.Exception.Message)" -Level "WARN" }` and surface a `MailboxSizeGB = "Unknown"` (string) sentinel so the report distinguishes "throttled / unavailable" from "genuinely 0 GB." Promote tag **B** in P2.
  - Line 922: tag **A** — `Disconnect-ExchangeOnline -Confirm:$false -ErrorAction SilentlyContinue` in `Show-ExitMessage`. Cleanup on script exit; if the disconnect throws because the session was already dropped, the script is about to `exit` anyway. Pure "fire and forget on shutdown." Add `# safe: cleanup` comment.
- **Target phase:** P2 (the line-293 tag-B can land *during* P1 if it's small — see F1's "loud `Write-Host` sweep" — because the existing `try`/`catch` block already wraps the call; only the `-ErrorAction` flag needs to flip + an actual catch body needs to be added).

### F3 — Auth flow is interactive-only; no app-only / managed-identity / certificate path
- **Severity:** high (for an EXO management tool that the user's CLAUDE.md flags as a SYSTEM-context RMM deployment target)
- **Category:** structure (operability / RMM safety)
- **Location:** scripts/m365_exchange_online.ps1:156 — `Connect-ExchangeOnline -ShowProgress $true -ErrorAction Stop | Out-Null`
- **Local notes:** The current call form is interactive — it opens a browser to `https://login.microsoftonline.com/` for the operator to sign in as themselves, which means the script will deadlock if invoked under SYSTEM, under a non-interactive session, or under any RMM agent. The `ExchangeOnlineManagement` module supports four auth modes:
  1. **Interactive (current)** — `Connect-ExchangeOnline` with no extra args.
  2. **App-only with certificate** — `Connect-ExchangeOnline -AppId APPID -CertificateThumbprint THUMB -Organization TENANT.onmicrosoft.com`. Requires a registered Azure AD application with the `Exchange.ManageAsApp` role + a certificate in `Cert:\CurrentUser\My` or `Cert:\LocalMachine\My`.
  3. **App-only with certificate file** — same as #2 but `-Certificate` (an `X509Certificate2` object) or `-CertificateFilePath` + `-CertificatePassword`.
  4. **Managed Identity** — `Connect-ExchangeOnline -ManagedIdentity -Organization TENANT.onmicrosoft.com` (Azure-hosted only; not relevant for the on-prem RMM deployment target).

  Recommended P4 change: accept a `-AppId` / `-CertificateThumbprint` / `-Organization` parameter trio on the script (or a new `Connect-ToExchangeOnline -AppOnly` switch) so the same script body can run interactively for a desktop operator AND non-interactively under an RMM agent. The interactive path remains the default.

  Note: this finding is *not* a C5 (destructive-without-WhatIf) issue — the script is strictly read-only (`Get-Mailbox`, `Get-MailboxStatistics`, `Get-OrganizationConfig`, `Get-PSSession`, `Disconnect-ExchangeOnline`). No mailboxes are modified.
- **Target phase:** P4

### F4 — Sequential per-mailbox `Get-MailboxStatistics` is the wall-clock bottleneck (see C13)
- **Severity:** med (perf — directly user-visible on tenants >100 mailboxes)
- **Category:** perf
- **Location:** scripts/m365_exchange_online.ps1:286–402 — the `foreach ($mailbox in $allMailboxes)` loop body. Line 293 issues the per-mailbox `Get-MailboxStatistics` call inside the loop.
- **Reference:** [C13](00-cross-cutting.md#c13--sequential-foreach-over-large-datasets-where-parallelism-would-help)
- **Local notes:** This is the C13 candidate the task plan asked to inspect, and it's a real one. Empirically `Get-MailboxStatistics` against EXO takes 200–600 ms per mailbox over the Internet (REST endpoint, single round-trip). A 100-mailbox tenant pays 20–60 s; a 500-mailbox tenant pays 100–300 s. The mailbox listing itself (`Get-Mailbox -ResultSize Unlimited` at line 270) is *not* the bottleneck — the EXO module pages internally and that single call returns in a few seconds even for tenants of thousands of mailboxes.

  Two parallelisation strategies, in order of preference:

  1. **Use `Get-EXOMailboxStatistics`** (the REST-based v2 cmdlet). Same signature, dramatically faster per-call (often 50–150 ms instead of 200–600 ms) because it uses the REST endpoint directly instead of the deprecated remote-PowerShell session. This is a one-line drop-in replacement and yields a 2–4x speedup without any concurrency complexity. Pair with `Get-EXOMailbox` at line 270 (and remove the `-Identity` lookup pattern in favor of pipeline binding). **Strongly preferred starting point.**
  2. **Runspace-pool parallelisation** — once `Invoke-SouliTEKParallel` (C13's planned module helper) exists, run the stats enrichment 5–10 mailboxes at a time. EXO will throttle if the throttle policy is hit (HTTP 429 with a `Retry-After` header), so the helper must respect `Retry-After` and back off. Realistic improvement on top of strategy #1 is 3–5x more.

  Do strategy #1 in P1 / P2 (it's a `Get-MailboxStatistics` -> `Get-EXOMailboxStatistics` rename and pairs naturally with the F2-B fix on the same line). Defer strategy #2 to P4 alongside the rest of the C13 sweep.
- **Target phase:** P1 (strategy #1) + P4 (strategy #2)

### F5 — No `[CmdletBinding()]` on script or any function; no `#Requires` directives
- **Severity:** low
- **Category:** structure
- **Location:** scripts/m365_exchange_online.ps1 — script-level (`param([string]$OutputFolder = ...)` at lines 8–10 has a `param()` block but no `[CmdletBinding()]` decorator) and every one of the 13 internal functions (`Show-Header` line 36, `Write-SummaryLine` line 41, `Ensure-OutputFolder` line 47, `Connect-ToExchangeOnline` line 54, `Disconnect-FromExchangeOnline` line 196, `Get-AllMailboxes` line 253, `Show-MailboxSummary` line 425, `Export-MailboxListTxt` line 501, `Export-MailboxListCsv` line 580, `Export-MailboxListHtml` line 625, `Show-Help` line 806, `Show-Menu` line 877, `Show-ExitMessage` line 917). Also no `#Requires -Version 5.1`, no `#Requires -Modules ExchangeOnlineManagement`.
- **Local notes:** Adding `[CmdletBinding()]` to the script header would give the script `-Verbose` / `-Debug` / `-ErrorAction` propagation for free. Adding `#Requires -Modules ExchangeOnlineManagement` at the top would let PowerShell fail-fast with a clean message before the SouliTEK-Common dot-source attempt, instead of hitting the `Install-SouliTEKModule` runtime path. The `Install-SouliTEKModule` call is fine (it handles the install path gracefully), but a `#Requires` directive is the more idiomatic gate. The `Ensure-OutputFolder` function uses an unapproved verb (`Ensure` is not in the verified verb list `Get-Verb | Sort-Object Verb`) and will trigger a PSScriptAnalyzer `PSUseApprovedVerbs` warning under C8 — rename to `New-OutputFolder` or `Initialize-OutputFolder` when the analyzer baseline is established. Same C8 note applies to `Connect-ToExchangeOnline` (the verb is approved but the noun-phrase `ToExchangeOnline` is informal; `Connect-ExchangeOnline` is reserved by the module so `Open-ExchangeOnlineSession` or `Initialize-ExchangeOnlineSession` is the standard naming).
- **Target phase:** P4

### F6 — `Split-Path -Parent $MyInvocation.MyCommand.Path` instead of `$PSScriptRoot` (see C10)
- **Severity:** low
- **Category:** structure
- **Location:** scripts/m365_exchange_online.ps1:20
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
- **Risk if changed:** Low. Identical behavior under normal invocation; `$PSScriptRoot` is the canonical PS 3.0+ automatic variable. Same fix as F5 of `driver_integrity_scan.md` — fold into the C10 module-loader consolidation sweep.
- **Target phase:** P4

### F7 — Infinite menu loop with `ReadKey` blocking + no non-interactive guard
- **Severity:** low
- **Category:** structure (UX / RMM safety)
- **Location:** scripts/m365_exchange_online.ps1:934 (`while ($true) { ... }`), plus `$Host.UI.RawUI.ReadKey(...)` calls at lines 67, 111, 129, 137, 203, 216, 250, 260, 276, 421, 432, 498, 506, 577, 584, 621, 629, 803, 874, 936, 957.
- **Local notes:** Same pattern as F6 of `driver_integrity_scan.md`. The script is interactive-only by design — graceful exit is menu option `[0]` which calls `Show-ExitMessage` followed by `exit` (lines 949–950). Under SYSTEM-context RMM execution, every `ReadKey` call hangs the worker process. There is no `[Environment]::UserInteractive` gate, no `-NonInteractive` switch, and no top-level `try`/`finally` to guarantee `Disconnect-ExchangeOnline` runs on Ctrl-C — though the `Show-ExitMessage` function (line 917) does include a defensive disconnect-on-exit block. Defer to P4; pairs with F3's non-interactive auth flow (both are required for unattended execution).
- **Target phase:** P4

### F8 — Brittle mailbox-size parser at line 336
- **Severity:** low
- **Category:** correctness
- **Location:** scripts/m365_exchange_online.ps1:336
- **Current:**
  ```powershell
  $sizeBytes = [long]($mailboxStats.TotalItemSize.Value.ToString().Split("(")[1].Split(" ")[0].Replace(",", ""))
  ```
- **Local notes:** This parses the EXO `TotalItemSize` field by splitting the human-readable string `"1.234 GB (1,323,456,789 bytes)"` on `"("` and `" "` to extract the raw bytes count. Two failure modes: (1) `$mailboxStats.TotalItemSize.Value.ToBytes()` is the documented, format-stable accessor on the `ByteQuantifiedSize` type that EXO returns — use that instead. (2) The current parser will throw `IndexOutOfRangeException` if EXO ever emits a different stringification (no parenthesized bytes section, or a locale that uses non-`,` thousands separators), which the per-mailbox outer `try`/`catch` will not catch because the parser sits at lines 332–342 *outside* the try block at 292–296. Recommended fix:
  ```powershell
  if ($mailboxStats.TotalItemSize) {
      $sizeBytes = $mailboxStats.TotalItemSize.Value.ToBytes()
      $mailboxSizeGB = [math]::Round($sizeBytes / 1GB, 2)
  }
  ```
- **Target phase:** P2 (pairs with F2-B)

### F9 — `Write-SummaryLine` helper uses `-ForegroundColor` parameter instead of `Write-Ui` level
- **Severity:** info
- **Category:** output-style (helper-internal)
- **Location:** scripts/m365_exchange_online.ps1:41–45 (definition); called at 449, 450, 453, 454, 455, 456, 458, 459, 461, 462.
- **Local notes:** Per the C1 exception, `Write-Host` is allowed inside helpers, so the implementation is acceptable as-is. The shape of the helper, though, is locked to a `[ConsoleColor]` parameter — which means every caller specifies a per-line color (Cyan / White / Green / Yellow / Gray). This is the exact pre-`Write-Ui`-era "manual color" pattern. Recommended: change the helper signature to `param([string]$Label, [string]$Value, [string]$Level = "INFO")` and call `Write-Ui -Message ("{0,-30}: {1}" -f $Label, $Value) -Level $Level` inside. Updating the 10 callers is mechanical. No change in user-visible behavior aside from the `[LEVEL]` bracket prefix.
- **Target phase:** P1 (fold into the C1 sweep)

## Out-of-scope notes
- Banner block (lines 1–6, 6 lines of `# === / Coded by / (C) 2025 SouliTEK`) matches C11 cross-cutting cleanup; covered there. This script's banner is unusually short compared to `driver_integrity_scan.ps1`'s 32-line block — already mostly compliant with C11's "3-line standard header" recommendation.
- `Install-SouliTEKModule -ModuleName "ExchangeOnlineManagement"` (line 62) is the correct idiom for handling the module dependency — it checks for the module, installs from PSGallery if missing, and gracefully handles the "already installed" path. No change needed.
- The HTML export template (lines 648–781) is clean: uses a here-string for the CSS block, builds row strings via `foreach` into a string array, and joins with `` "`n" `` for final output. The inline STYLE block is acceptable for a self-contained report file (no external CSS dependency). However: all field values come from EXO cmdlets and are emitted in attribute-free table cells *without HTML-encoding*. A defensive `-replace '[L]', '&lt;'` / `-replace '[G]', '&gt;'` pass (where `[L]` and `[G]` are the literal less-than / greater-than characters) on user-controlled fields (`DisplayName`, `Aliases`, `SendOnBehalf`) would be a sensible hardening pass since EXO does allow Unicode display names and a malicious / mistyped display name containing a closing-cell tag followed by a script tag would currently render as live HTML. Worth flagging as a follow-up (OWASP A03:2021 — Injection) but realistically the attack surface is tiny because the tenant admin runs the script against their own tenant.
- The `$Script:MailboxData = @()` array-append pattern in the per-mailbox loop (line 380, `$Script:MailboxData += [PSCustomObject]@{ ... }`) is `O(N^2)` because `+=` on a PowerShell array reallocates the entire array on each append. For 500 mailboxes this is ~125k internal copies and adds noticeable overhead. Recommended replacement: `[System.Collections.Generic.List[object]]::new()` with `.Add(...)`. Low priority, pairs with the F4 perf sweep.
- The auth-state detection at lines 87–95 and 162–167 (`Get-PSSession | Where-Object { $_.ConfigurationName -eq "Microsoft.Exchange" }`) is the *old* PS-remoting session model and will return `$null` against the v3+ `ExchangeOnlineManagement` module which uses REST instead of WSMan. Use `Get-ConnectionInformation` (introduced in EXO module v3.0) instead — it returns the current REST-connection metadata including `Organization` (tenant primary domain) and `UserPrincipalName` (signed-in operator). This explains why `$Script:TenantDomain` / `$Script:TenantName` end up as the literal string `"Connected"` (the fallback at lines 93–94) under EXO v3+ — a user-visible UX bug masked by the fallback. Pair with the F3 auth-flow modernization in P4.
- The trailing single blank line at line 961 is fine — no cleanup needed (unlike `driver_integrity_scan.ps1`'s 7-blank-line tail).
- Tab indentation is used throughout (not spaces). Matches the repo's apparent house style; PSScriptAnalyzer will flag inconsistent indentation under C8 if any space-indented additions land later — note for whoever runs the P0 analyzer baseline.
