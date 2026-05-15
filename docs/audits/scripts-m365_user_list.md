# Audit — scripts/m365_user_list.ps1

## Inventory
| Item | Value |
|---|---|
| Path           | scripts/m365_user_list.ps1 |
| LOC            | 1297 |
| Functions      | 20 |
| `#Requires`    | none |
| Admin-required | no (Microsoft Graph delegated auth — interactive sign-in opens a browser. The Graph scopes used are all read-only: `User.Read.All`, `UserAuthenticationMethod.Read.All`, `Organization.Read.All`, `Directory.Read.All`, `Group.Read.All`, `Mail.Read`, `MailboxSettings.Read`. No local admin rights required.) |
| Last touched   | 8675720 — 2026-04-17 |
| Modernization grade | C |

## Summary

A menu-driven Microsoft 365 user inventory tool: connects to Microsoft Graph (delegated auth), enumerates all users via `Get-MgUser -All`, then enriches every user record with MFA method status, phone, licenses, roles, group memberships, and mailbox forwarding configuration. Exports in four formats (TXT, CSV, HTML, JSON) to a configurable output folder (defaults to Desktop). The dominant correctness/perf concern is **F4**: the per-user enrichment loop (`Get-AllUsers`, lines 552–633) issues 4–7 Graph round-trips for every user via `Get-UserMfaStatus`, `Get-UserLicenses`, `Get-UserRoles`, `Get-UserGroups`, `Get-UserMailboxInfo`, including a `Get-MgSubscribedSku` call **inside** `Get-UserLicenses` that re-pulls the entire SKU catalogue once per user (line 337) — for a 500-user tenant that is ~500 redundant catalogue fetches plus ~2000 enrichment calls minimum. `Get-UserRoles` (lines 358–376) is asymptotically worse: it loops every directory role and calls `Get-MgDirectoryRoleMember` per role per user (O(users × roles)), instead of inverting to "list each role's members once and build a user→roles lookup." A full enumeration on a real tenant will be dominated by this single function. Secondary issues: (1) `Write-Host` is used 127 times alongside `Write-Ui` in a three-style mix (raw colored `Write-Host`, `Write-Ui` calls with redundant inline `[+]`/`[-]` markers, and `Write-SummaryLine` formatter) — see F1; (2) 16 `-ErrorAction SilentlyContinue` / `SilentlyContinue` preference assignments, most of which are legitimate Graph "best-effort enrichment" probes but several silently mask real failures (F2); (3) HTML exporter at line 867–868 references `$user.MfaEnabled` which **does not exist** on the user object (the property is `MfaConfigured`, set at line 613) so `$mfaEnabledUsers` and `$mfaDisabledUsers` in the HTML report are always 0 — a real bug (F6); (4) TXT exporter at line 772 references `$user.MfaDefaultMethod` which is also never set anywhere in the script (F7); (5) JSON exporter at line 1056 compares `$user.PrimaryEmail -ne $user.UserPrincipalName` to decide whether to emit `PrimaryEmail`, but `Get-AllUsers` always falls back PrimaryEmail to UserPrincipalName at line 599 — so the optional emission is dead logic. No `#Requires` line, no `[CmdletBinding()]`, and a hard-coded `while ($true)` interactive loop (line 1269) mean this script is unsuitable for non-interactive/SYSTEM execution. Recommended phase entry order: P2 (C4 triage), then P1 (C1), then P4 (perf rewrite of `Get-UserRoles` and SKU caching alongside C13).

## Findings

### F1 — Raw `Write-Host` and double-marked `Write-Ui` (see C1)
- **Severity:** med
- **Category:** output-style
- **Location:** scripts/m365_user_list.ps1 — 127 `Write-Host` occurrences. Zero `Write-SouliTEK*` legacy-API calls (good — this script is already on `Write-Ui` for level-prefixed output).
- **Reference:** [C1](00-cross-cutting.md#c1--raw-write-host-calls-not-migrated-to-write-uiwrite-status)
- **Local notes:** Three categories of `Write-Host`:
  1. **Blank-line spacers** — `Write-Host ""` (89 occurrences). Per C1 exception these are not violations; they are pure vertical spacing. No change required, but a `Write-Ui -Spacer` helper added in P4 would clean these up uniformly.
  2. **Decorative separator bars** — `Write-Host "============================================================" -ForegroundColor Cyan|Green|Red` (14 occurrences: lines 214, 216, 222, 224, 496, 498, 504, 506, 637, 639, 644, 646, 1229, 1242) and `Write-Host "------------------------------------------------------------" -ForegroundColor Yellow|Gray` (9 occurrences: lines 124, 481, 673, 688, 1135, 1153, 1167, 1193, 1201). Per C1 these are "visual separator helpers" and stay as-is, BUT a `Show-Section` / `Show-Banner` helper would consolidate them.
  3. **Real C1 violations — inline colored text or prompts** (15 occurrences): lines 47 (`Write-SummaryLine` writes to host with `-ForegroundColor $Color`), 129, 131, 482, 484, 702 (`Write-Host "    Status: $accountStatus | MFA: " -NoNewline -ForegroundColor Gray`), 703, 1218, 1219, 1221, 1223, 1226, 1227, 1244, 1272. These are pre-`Write-Ui`-era manual color formatting that mix prompt/echo behaviour with the new `Write-Ui` API. The prompt-echo lines (131, 484, 1272 — `Write-Host $choice.Character` after a `ReadKey`) are intentional UX (echo the keypress) and are fine to keep, but should be commented.
- **Local notes (cont.) — inline marker prefixes on `Write-Ui` calls:** Many `Write-Ui` calls embed redundant `[+]` / `[-]` / `[Step N/M]` markers inside the message text (e.g. lines 64, 86, 91, 99, 141, 152, 163, 188, 215, 223, 497, 505, 638, 645). Same anti-pattern as F2 of `01-modules-SouliTEK-Common.md`: when `Write-Ui` is invoked with `-Level "OK"`/`"ERROR"`/`"INFO"`, the helper already prefixes `[OK]`/`[ERROR]`/`[INFO]`, so embedding `[+]`/`[-]` doubles the marker. The `[Step N/4]` prefix at lines 64, 95, 163, 196 is fine because it's a step counter, not a status marker — keep those.
- **Recommended:** Migrate the 15 violations in category 3 above to `Write-Ui` or to a new `Show-Prompt` / `Show-StatusLine` helper. Strip embedded `[+]` / `[-]` markers in category-1 inline calls. Keep separator bars and blank spacers as-is.
- **Risk if changed:** Low. Message text preserved verbatim; visual difference is one bracket character per affected line. `Write-SummaryLine` (line 44) needs review — its formatting is unique (`"{0,-30}: {1}"`) and not a direct `Write-Ui` substitute; either keep as a local helper or generalise to `Format-KeyValue` in the common module (P4).
- **Target phase:** P1

### F2 — `-ErrorAction SilentlyContinue` triage (see C4)
- **Severity:** med
- **Category:** error-handling
- **Location:** scripts/m365_user_list.ps1 — 16 occurrences (1 `$ProgressPreference` assignment + 15 `-ErrorAction SilentlyContinue`)
- **Reference:** [C4](00-cross-cutting.md#c4----erroraction-silentlycontinue-swallowing-failures)
- **Triage:**
  - Line 15: tag **A** — `$ProgressPreference = 'SilentlyContinue'` is a preference variable, not an error swallower; suppresses the noisy `Write-Progress` bars during `Install-Module`. Legitimate. Add `# safe: suppress install progress` comment.
  - Line 97: tag **A** — `Get-MgContext -ErrorAction SilentlyContinue` is a probe: tests whether a Graph session already exists. Result is checked with `if ($context)` immediately. Legitimate. Add `# safe: probe` comment.
  - Line 137: tag **A** — `Disconnect-MgGraph -ErrorAction SilentlyContinue | Out-Null` inside the "user chose to switch tenant" branch — disconnect from current tenant, errors don't matter because we're about to reconnect anyway. The surrounding `try { ... } catch { Write-Warning ... }` would have caught a real failure if `Stop` were used, but the explicit `Disconnect-MgGraph -ErrorAction Stop` is already used at line 490 in `Disconnect-FromMicrosoftGraph`. Tag **A**, add `# safe: best-effort disconnect before re-auth`.
  - Line 253: tag **A** — `Get-MgUserAuthenticationMethod -UserId $UserId -ErrorAction SilentlyContinue` inside `Get-UserMfaStatus`. Graph returns 403/404 for users where the caller lacks `UserAuthenticationMethod.Read.All` on that specific user (e.g. some B2B/guest accounts) — silent fail is reasonable since the outer `try { ... } catch { }` at line 252/310 would also swallow. Tag **A**, but **add a `Write-Verbose` inside the catch** so an operator running with `-Verbose` can see which users failed. Add `# safe: best-effort enrichment` comment.
  - Line 292: tag **A** — `Get-MgUser -UserId $UserId -Property SignInActivity -ErrorAction SilentlyContinue`. `SignInActivity` requires an Azure AD Premium P1/P2 license; tenants without P1 get a 403. Silent fail is acceptable. Tag **A**, add `# safe: P1-license-gated` comment.
  - Line 303: tag **A** — `Get-MgUserRiskDetection -Filter "userId eq '$UserId'" -Top 1 -ErrorAction SilentlyContinue`. Note the call result `$userRisk` is **assigned but never read** (dead code; see F8). Even ignoring the dead-code issue, this requires Azure AD P2 + `IdentityRiskEvent.Read.All` scope which the script does NOT request (the scopes block at lines 177–185 doesn't include this). Silent fail is the only thing keeping this call from breaking the whole user loop. Tag **A** for now, but the call should be **deleted** rather than silenced (F8).
  - Line 337: tag **A** — `Get-MgSubscribedSku -ErrorAction SilentlyContinue` inside `Get-UserLicenses`. The catch block at line 346–349 falls back to a count-only license summary. Tag **A**, BUT this call is the worst perf hot-spot in the script: it re-fetches the full tenant SKU catalogue **per user** (see F4). Add `# safe: best-effort catalogue lookup` for now and lift the call out of the loop in P4.
  - Line 363: tag **B** — `Get-MgDirectoryRole -All -ErrorAction SilentlyContinue` inside `Get-UserRoles`. If this call fails (e.g. token expired, throttling, transient 503), the function silently returns an empty `$roles` array and the per-user record's `Roles` field is empty — but the user *might* actually be a Global Admin. Silently dropping admin-role data is a real correctness risk for a security-adjacent report. Replace with `try { ... } catch { Write-Ui -Message "Could not retrieve directory roles: $($_.Exception.Message)" -Level "WARN"; return @() }`.
  - Line 365: tag **B** — `Get-MgDirectoryRoleMember -DirectoryRoleId $role.Id -ErrorAction SilentlyContinue` inside the same loop. Same risk profile as line 363 — silently dropping role membership is a correctness bug. Same fix.
  - Line 383: tag **B** — `Get-MgUserMemberOf -UserId $UserId -ErrorAction SilentlyContinue` inside `Get-UserGroups`. Silent fail produces a user record with `Groups = @()` indistinguishable from "user has no groups." For an inventory report this is a quiet correctness issue. Replace with the same `try/catch + Write-Verbose` pattern; promote to `WARN` if the whole loop fails.
  - Line 386: tag **A** — `Get-MgGroup -GroupId $groupRef.Id -Property DisplayName,GroupTypes -ErrorAction SilentlyContinue` inside the per-group inner loop of `Get-UserGroups`. Per-group resolve is best-effort (some directory objects returned by `Get-MgUserMemberOf` are roles/devices rather than groups and will 404 on `Get-MgGroup`). Tag **A**, add `# safe: best-effort group lookup` — the existing inline `try { ... } catch { }` (line 390) already handles this correctly.
  - Line 417: tag **A** — `Get-MgUserMailboxSetting -UserId $UserId -ErrorAction SilentlyContinue` inside `Get-UserMailboxInfo`. Users without a mailbox (e.g. guests, shared resources) return 404. Tag **A**, add `# safe: user may not have mailbox`.
  - Line 427: tag **A** — `Get-MgUser -UserId $mailbox.ForwardingAddress -ErrorAction SilentlyContinue` inside the forwarding-address external-check. Used as a probe — if the address resolves to an internal user, set `ExternalForwarding = false`; if it 404s, set `true`. Tag **A**, this is the canonical "probe" pattern. Add `# safe: probe for internal recipient`.
  - Line 440: tag **A** — `Get-MgUser -UserId $UserId -Property MailboxSettings -ErrorAction SilentlyContinue` inside the dead "mailbox size" branch (lines 437–446) where the result is checked then nothing is done with it (`# Mailbox settings available` comment at line 442 is the entire body). Tag **A**, but the call should be **deleted** entirely (see F8 — dead code).
  - Line 475: tag **A** — `Get-MgContext -ErrorAction SilentlyContinue` in `Disconnect-FromMicrosoftGraph` is a probe to display the current account/tenant in the disconnect confirmation prompt. Tag **A**, add `# safe: probe for display`.
  - Line 1257: tag **A** — `Disconnect-MgGraph -ErrorAction SilentlyContinue | Out-Null` in `Show-ExitMessage`. Best-effort cleanup on script exit — if disconnect fails the process is dying anyway. Tag **A**, add `# safe: cleanup on exit`.
- **Recommended:** Apply A/B tags above in P2. The three **B**-tagged sites (363, 365, 383) are the only ones requiring real fixes — they silently produce incorrect `Roles`/`Groups` data and should at minimum log a `WARN` via `Write-Ui`. All other A-tagged sites should get explanatory comments and stay.
- **Target phase:** P2

### F3 — Scripts >1000 LOC: largest functions (see C6)
- **Severity:** med
- **Category:** structure
- **Location:** scripts/m365_user_list.ps1 — 1297 LOC, 20 functions. Top-7 by LOC:
  1. `Connect-ToMicrosoftGraph` (lines 59–235, **177 LOC**) — module install + two-branch connect logic (existing context vs. new connect) + four `[Step N/4]` blocks + organisation-detail retrieval. Mixed concerns (install, auth, org-fetch, UX).
  2. `Export-UserListHtml` (lines 848–1014, **167 LOC**) — large inline CSS + here-string table assembly. Pure formatting; extracts cleanly into a `Format-M365UsersHtml` helper.
  3. `Get-AllUsers` (lines 520–653, **134 LOC**) — the per-user enrichment loop. Houses F4 (the perf finding) and the `[PSCustomObject]` shape definition (lines 595–632, 38 lines of property mapping).
  4. `Export-UserListJson` (lines 1016–1129, **114 LOC**) — hashtable assembly + optional-field omission + `ConvertTo-Json -Depth 10`.
  5. `Show-Help` (lines 1131–1209, **79 LOC**) — pure `Write-Ui` text dump; could move to an embedded here-string + single `Write-Host`.
  6. `Get-UserMfaStatus` (lines 237–315, **79 LOC**) — per-user MFA-method enumeration with 4 `if`/`elseif` branches matching `@odata.type` strings.
  7. `Export-UserListTxt` (lines 725–801, **77 LOC**) — fixed-format text dump per user.
- **Reference:** [C6](00-cross-cutting.md#c6--scripts-1000-loc-with-extractable-duplication)
- **Local notes:** Three obvious extract candidates:
  1. The **four exporters** (`Export-UserListTxt`/`Csv`/`Html`/`Json`) share the same skeleton: precheck empty `$Script:UserData`, `Show-Header`, `Ensure-OutputFolder`, `$timestamp = Get-Date -Format ...`, build `$fileName`, build `$filePath`, write file, `Start-Process $filePath`, "press any key" gate. The precheck (12 lines × 4 = 48 LOC) and the open-result block (4 lines × 4 = 16 LOC) are pure duplication.
  2. The **MFA-method-type matching** (lines 260–283) is a switch dressed up as nested `if`/`elseif`; a single `switch` on `$cleanType -like '*pattern*'` would halve the LOC.
  3. The **`Connect-ToMicrosoftGraph` already-connected branch** (lines 98–158, 61 LOC) and the **new-connection branch** (lines 162–219) both call `Get-MgOrganization` and update `$Script:TenantName`/`$Script:TenantDomain`. Extract `Update-TenantInfo` (lines 104–118 + 197–211 = 30 LOC saved).
- **Recommended:** P4 extract pass — gain ~120 LOC reduction (~10% of file) without touching behaviour. Defer until after F4's perf rewrite, since the per-user enrichment loop will be the bigger structural change.
- **Target phase:** P4

### F4 — Per-user Graph round-trip storm (see C13)
- **Severity:** high
- **Category:** perf / correctness
- **Location:** scripts/m365_user_list.ps1:552–633 (the `foreach ($user in $allUsers)` loop inside `Get-AllUsers`). Specifically:
  - Line 557: `Get-UserMfaStatus -UserId $user.Id` → fans out to lines 253 (`Get-MgUserAuthenticationMethod`), 292 (`Get-MgUser` for SignInActivity), 303 (`Get-MgUserRiskDetection` — dead, see F8).
  - Line 563: `Get-UserLicenses -User $user` → calls `Get-MgSubscribedSku -ErrorAction SilentlyContinue` at line 337 **per user**, re-fetching the entire tenant SKU catalogue each time.
  - Line 566: `Get-UserRoles -UserId $user.Id` → at line 363 calls `Get-MgDirectoryRole -All`, then at line 365 inside the inner loop calls `Get-MgDirectoryRoleMember -DirectoryRoleId $role.Id` for **every directory role** for **every user**. This is `O(users × roles)` Graph calls. A tenant with 500 users and 30 active directory roles = 15,000 `Get-MgDirectoryRoleMember` calls plus 500 `Get-MgDirectoryRole -All` calls. At Graph's default throttle ceiling (~120 req/sec per app) this alone will rate-limit the script.
  - Line 569: `Get-UserGroups -UserId $user.Id` → at line 383 calls `Get-MgUserMemberOf`, then at line 386 inside the inner loop calls `Get-MgGroup -GroupId $groupRef.Id` per group. `O(users × avg_groups_per_user)`.
  - Line 572: `Get-UserMailboxInfo -UserId $user.Id` → fans out to lines 417, 427, 440 (and 440 is dead code — see F8).
- **Reference:** [C13](00-cross-cutting.md#c13--sequential-foreach-over-large-datasets-where-parallelism-would-help)
- **Local notes:** Order-of-magnitude estimate for a 500-user, 30-role, ~8-groups-per-user tenant on the **current** code:
  - `Get-MgUser -All` (1 call, line 536) — fine, the `-All` does paging internally.
  - `Get-UserMfaStatus` → 2–3 calls × 500 = ~1250
  - `Get-UserLicenses` → 1 `Get-MgSubscribedSku` × 500 = 500 (redundant — should be 1 total)
  - `Get-UserRoles` → 1 + 30 calls × 500 = 15,500
  - `Get-UserGroups` → 1 + 8 calls × 500 = 4,500
  - `Get-UserMailboxInfo` → 2 calls × 500 = 1000
  - **Total: ~22,750 Graph calls** for 500 users. With ~150ms median latency that's ~57 minutes of wall-clock time, dominated by `Get-UserRoles`.
- **Recommended (P4, depends on perf-helper module work in C13):**
  1. **Cache the SKU catalogue once** before the loop: pull `Get-MgSubscribedSku -All` once into a hashtable `$Script:SkuMap = @{}; ... $Script:SkuMap[$sku.SkuId] = $sku.SkuPartNumber` and have `Get-UserLicenses` look up via the cached map. Saves 499 calls on a 500-user tenant. **Highest-ROI single change.**
  2. **Invert `Get-UserRoles`**: pull `Get-MgDirectoryRole -All` once, then for each role pull `Get-MgDirectoryRoleMember -All` once, building `$Script:UserRoleMap = @{ userId = @('Global Admin', ...) }`. Each user lookup becomes O(1) hashtable lookup. Saves ~15,000 Graph calls. **Second-highest ROI.**
  3. **Inline-expand `Get-MgUserMemberOf` group resolution**: `Get-MgUserMemberOf` already returns the group objects' `Id` + (with `-ExpandProperty` or a `Property` select) `DisplayName`; the per-group `Get-MgGroup` call at line 386 is redundant. Saves ~4000 calls.
  4. **Delete `Get-MgUserRiskDetection`** (line 303) — its result is never used (see F8). Saves 500 calls.
  5. **Parallelism** (`ForEach-Object -Parallel` on PS 7+, or `Invoke-SouliTEKParallel` runspace-pool helper from the P4 module work) is NOT the right fix here — the bulk of the work is Graph round-trips, and Graph's throttle limit caps you anyway. Caching changes (#1, #2, #3) are O(N) → O(1) wins; parallelism is at best a 5–10× speedup with throttle-collision risk. Cache first, parallelise only after caching exposes the next bottleneck.
- **Risk if changed:** Medium — the role-map inversion changes the result shape (an empty `Roles` array under the current code when `Get-MgDirectoryRoleMember` 503s could legitimately resolve to a non-empty array under the new code). Add Pester smoke test in P5 that the export CSV's `Roles` column populates for a known-Global-Admin account before and after.
- **Target phase:** P4 (cache changes #1–#4 are safe to land before the C13 parallelism helper exists; #5 deferred).

### F5 — No `#Requires`, no `[CmdletBinding()]`, no PS-version floor declared
- **Severity:** low
- **Category:** structure
- **Location:** scripts/m365_user_list.ps1 — top of file (no `#Requires` line at all); param block at lines 8–10 (`param([string]$OutputFolder = ...)`) has no `[CmdletBinding()]`; none of the 20 functions have `[CmdletBinding()]`.
- **Local notes:** Microsoft.Graph PowerShell SDK requires PS 5.1+ (PS 7+ recommended). Add `#Requires -Version 5.1` and `#Requires -Modules @{ ModuleName = 'Microsoft.Graph.Authentication'; ModuleVersion = '2.0.0' }` (etc. for the 6 modules listed at lines 67–74). Adding `[CmdletBinding()]` to the script-level param block costs 1 line and gives the script `-Verbose` / `-Debug` / `-ErrorAction` for free, which is especially useful for promoting the F2 tag-B sites from silent failures to `Write-Verbose` traces.
- **Recommended:** Add `[CmdletBinding()]` above the `param(...)` block; add `#Requires -Version 5.1` at line 1. The `#Requires -Modules` declaration is more contentious because the current code lazily installs them via `Install-SouliTEKModule` (line 78); a `#Requires -Modules` declaration would fail-fast before the lazy installer runs. Leave that out and keep the lazy install.
- **Target phase:** P4 (fold into C10 sweep)

### F6 — HTML exporter reads `$user.MfaEnabled`, which is never set
- **Severity:** med
- **Category:** correctness (real bug)
- **Location:** scripts/m365_user_list.ps1:867–868
- **Current:**
  ```powershell
  $mfaEnabledUsers = ($Script:UserData | Where-Object { $_.MfaEnabled -eq $true }).Count
  $mfaDisabledUsers = ($Script:UserData | Where-Object { $_.MfaEnabled -eq $false }).Count
  ```
- **Recommended:**
  ```powershell
  $mfaEnabledUsers = ($Script:UserData | Where-Object { $_.MfaConfigured -eq $true }).Count
  $mfaDisabledUsers = ($Script:UserData | Where-Object { $_.MfaConfigured -eq $false }).Count
  ```
- **Local notes:** `Get-AllUsers` assembles each user record's MFA flag as `MfaConfigured = $mfaStatus.Configured` at line 613. There is no `MfaEnabled` property on the `[PSCustomObject]` at lines 595–632. Result: the HTML report's "MFA Enabled" stat-box always shows `0 (0%)`, regardless of the actual tenant MFA coverage. The summary view (line 668) and CSV/JSON exporters correctly use `MfaConfigured`. The HTML rendering of individual users at line 918 also correctly uses `$user.MfaConfigured` — it's only the **summary stat-box** at the top of the HTML that is wrong.
- **Risk if changed:** Low (single-property rename). Add a Pester test in P5 asserting `$Script:UserData[0].PSObject.Properties.Name -contains 'MfaConfigured'`.
- **Target phase:** P1 (bug — fix on the next pass over this file)

### F7 — TXT exporter and HTML table reference `$user.MfaDefaultMethod`, which is never set
- **Severity:** low
- **Category:** correctness (cosmetic bug)
- **Location:** scripts/m365_user_list.ps1:772 (TXT export), 933 + 973 (HTML table cell + column header)
- **Current (line 772):**
  ```powershell
  $output += "MFA Default Method: $($user.MfaDefaultMethod)"
  ```
- **Local notes:** The `[PSCustomObject]` at lines 595–632 emits MFA fields `MfaConfigured`, `MfaMethods` (array), `MfaMethodCount`, `MfaHasAuthenticatorApp`, `MfaHasSMS`, `MfaHasEmailMFA`, `MfaHasFIDO`, `MfaEnforcedViaCA`, `MfaLastSignIn`. There is no `MfaDefaultMethod`. Result: TXT report shows `MFA Default Method: ` (blank); HTML report shows an empty cell. Two fixes possible:
  1. **Remove the references** (simplest). Drop line 772 from TXT, drop the `MfaDefaultMethod` cell (line 933) and the corresponding column header (line 973) from HTML.
  2. **Compute a default method**: pick the strongest method in `$user.MfaMethods` (e.g. priority order `FIDO Key > Authenticator App > Phone > Email`). The `microsoftAuthenticatorAuthenticationMethod` Graph object actually exposes an `IsDefault` property via `Get-MgUserAuthenticationMethod`, but the script doesn't currently extract it.
- **Recommended:** Choice (1) — remove the dead references. The "default method" concept is only meaningful in Conditional-Access / per-user-MFA legacy land; for modern Authentication Methods Policy it doesn't translate cleanly. Choice (2) is over-engineering for a cosmetic report.
- **Target phase:** P1 (bug — fix on the next pass)

### F8 — Dead code: unused result + empty branch
- **Severity:** low
- **Category:** structure (dead code)
- **Location:**
  - scripts/m365_user_list.ps1:303–308 — `$userRisk = Get-MgUserRiskDetection -Filter "userId eq '$UserId'" -Top 1 -ErrorAction SilentlyContinue` is assigned but the result is never used. The trailing comment "If we can't easily determine CA, we'll mark as unknown" hints at intent but no logic follows. The call also requires `IdentityRiskEvent.Read.All` which is **not** in the requested scope set (lines 177–185), so even when it doesn't fail-silent it can't succeed.
  - scripts/m365_user_list.ps1:437–446 — inside `Get-UserMailboxInfo`, the inner `try { $user = Get-MgUser -UserId $UserId -Property MailboxSettings -ErrorAction SilentlyContinue ... }` block has a body that just checks `if ($user.MailboxSettings) { # Mailbox settings available }` — comment in place of code. The `# Mailbox size...` comment block at lines 437–438 explains it was deferred because mailbox size requires Exchange Online cmdlets, not Graph.
- **Recommended:** Delete both blocks. They cost Graph round-trips (see F4) for zero value.
- **Risk if changed:** Low. Pure delete, no behaviour change.
- **Target phase:** P4

### F9 — `+=` array-append in tight loops (perf, low severity here)
- **Severity:** low
- **Category:** perf
- **Location:** scripts/m365_user_list.ps1 — `$Script:UserData += [PSCustomObject]@{...}` (line 595, inside the 500-iteration user loop), `$jsonData += $userObject` (line 1086, same per-user pattern), `$output += "..."` (lines 743–777, ~30 `+=` calls building the TXT report, dominated by the inner per-user loop at lines 759–778).
- **Local notes:** PowerShell's `+=` on an array allocates a new array of length n+1 and copies all n existing elements on every iteration — O(n²) total. For 500 users the inner loops accumulate ~500² / 2 = 125k unnecessary copies, but each copy is small so this is *not* the perf bottleneck (F4 is). Still worth noting because the same anti-pattern is called out in cross-cutting reviews. Idiomatic replacement is `[System.Collections.Generic.List[PSObject]]::new()` + `.Add(...)`, or letting the foreach output to the pipeline and capturing with `$Script:UserData = foreach ($user in $allUsers) { ... }`.
- **Recommended:** Defer to P4 cleanup; fold into the same pass that rewrites `Get-AllUsers` for F4. Single-pass fix:
  ```powershell
  $list = [System.Collections.Generic.List[PSObject]]::new($allUsers.Count)
  foreach ($user in $allUsers) {
      ...
      $list.Add([PSCustomObject]@{...})
  }
  $Script:UserData = $list.ToArray()
  ```
- **Target phase:** P4

### F10 — Hard-coded Desktop output path + interactive-only main loop (RMM safety)
- **Severity:** low
- **Category:** structure (UX / RMM safety)
- **Location:**
  - scripts/m365_user_list.ps1:9 — `$OutputFolder = (Join-Path $env:USERPROFILE "Desktop")` as the param default.
  - scripts/m365_user_list.ps1:1269 — `while ($true) { Show-Menu; $choice = $Host.UI.RawUI.ReadKey(...); ... }` is the only entry point; no `-NonInteractive` switch, no `[Environment]::UserInteractive` gate.
- **Local notes:** Same pattern as F6 of `scripts-driver_integrity_scan.md`. Under SYSTEM/RMM execution `$env:USERPROFILE` resolves to `C:\Windows\System32\config\systemprofile` (whose `Desktop` folder may not exist), AND `$Host.UI.RawUI.ReadKey` will hang the worker. The `-OutputFolder` param does give a CLI override for the path, but there's no CLI surface to bypass the menu. If this script is ever batched-invoked by the launcher under non-interactive flow, it deadlocks.
- **Recommended:** Defer to P4. Pairs with the same recommendation in F6 of `scripts-driver_integrity_scan.md` and F10 of `01-modules-SouliTEK-Common.md` (`Wait-SouliTEKKeyPress`). Add `[Environment]::UserInteractive` gate around the `while ($true)` loop and a `-RunOnce` CLI mode that emits a JSON export and exits.
- **Target phase:** P4

### F11 — Tabs for indentation (style drift)
- **Severity:** info
- **Category:** style
- **Location:** scripts/m365_user_list.ps1 — whole file uses hard tabs for indentation, unlike most other scripts in the repo (`driver_integrity_scan.ps1` uses spaces). Not raised as a finding to fix unless STYLE_GUIDE.md explicitly mandates one or the other.
- **Local notes:** No correctness/behaviour impact. PSScriptAnalyzer's `PSUseConsistentIndentation` rule (if enabled in C8's settings file) would flag it. Worth a `.editorconfig` decision in P0.
- **Target phase:** —

## Out-of-scope notes
- The banner block (lines 1–6, 6 lines) is unusually short for this repo — most scripts have a 25–35-line C11 banner. Probably already pre-trimmed at some point. The 5-line header block is acceptable; no C11 work needed here.
- The script does not call any C2 legacy `Write-SouliTEK*` API. It is fully on `Write-Ui`. This is a good baseline.
- The `Install-SouliTEKModule` calls (lines 77–82) correctly use the centralized common-module helper — model usage for C10 alignment in other scripts.
- The Graph scope set requested at lines 177–185 is appropriately scoped (read-only). `Mail.Read` and `MailboxSettings.Read` are over-broad for a user-list tool — they're requested to support the `Get-MgUserMailboxSetting` call at line 417, but the script only reads forwarding-address data, not message content. Trimming to `MailboxSettings.Read` only (drop `Mail.Read`) would be a least-privilege improvement, but it's not strictly broken. Note in P3 alongside C5 review.
- The `[PSCustomObject]@{...}` shape at lines 595–632 has 30 named properties. CSV export of this shape produces a 30-column spreadsheet, which is fine for the use case but worth knowing that property additions/removals to that object cascade through all four exporters (TXT lines 759–778, CSV implicitly, HTML lines 920–937, JSON lines 1043–1086) and any property name typo will silently produce empty cells (see F6 and F7 — that exact bug class).
- `$ErrorActionPreference = 'Stop'` at line 17 is set globally and **overrides** most of the `-ErrorAction SilentlyContinue` overrides only at the cmdlet level (which is the desired behavior). Worth knowing that any new code added to this file without an explicit `-ErrorAction` defaults to `Stop` and will throw rather than silently continue. This is the right default per CLAUDE.md "fail closed."
- The `ConvertTo-Json -Depth 10` at line 1099 is generous; the deepest nesting in `$finalJson` is 4 (`Users[].Mailbox.ForwardingAddress`). `-Depth 5` would suffice but `10` is harmless.
