# Audit — scripts/sharepoint_site_inventory.ps1

## Inventory
| Item | Value |
|---|---|
| Path           | scripts/sharepoint_site_inventory.ps1 |
| LOC            | 1009 |
| Functions      | 16 |
| `#Requires`    | none — no `#Requires` directive anywhere in the file (Graph SDK modules are installed at runtime by `Install-SouliTEKModule` instead of declared) |
| Admin-required | no — read-only Microsoft Graph queries (`Sites.Read.All`, `Group.Read.All`, `Organization.Read.All`); no local system mutation beyond writing report files to a user-supplied `$OutputFolder` (defaults to `$env:USERPROFILE\Desktop`). Same admin caveat as `license_expiration_checker.ps1`: `Install-SouliTEKModule` may require admin if it falls back to `-Scope AllUsers`. |
| Last touched   | 8675720 — 2026-04-17 |
| Modernization grade | B |

## Summary

A menu-driven Microsoft 365 SharePoint inventory tool: connects to Graph (`Connect-MgGraph -Scopes Sites.Read.All,Group.Read.All,Organization.Read.All`), enumerates all sites with `Get-MgSite -All`, per-site fetches storage (`Get-MgSiteDrive` + `Get-MgDrive`), owners (`Get-MgGroupOwner` + `Get-MgUser`/`Get-MgGroup`), and last-modified timestamp, and renders four report formats (TXT, CSV, HTML, JSON) plus an in-console summary. The biggest issues are (1) 141 raw `Write-Host` calls coexisting with `Write-Ui` (C1) — most are visual separators that fall under the C1 "spacer" exception, but roughly 25 are real inline-color formatting violations (decorative `============`/`-----` dividers + `Write-SummaryLine` itself + `-NoNewline`/`-ForegroundColor` status concatenations); (2) 12 `-ErrorAction SilentlyContinue` occurrences — only one is the `$ProgressPreference` preference variable (not a C4 finding); the remaining 11 are split into a legitimate session-probe pair (lines 90, 237 — tag A) and 9 Graph-SDK-call swallows inside `Get-SiteStorage` / `Get-SiteOwners` / `Get-SiteLastActivity` (lines 287, 291, 330, 334, 341, 363, 369, 373) plus one `Disconnect-MgGraph` cleanup (line 130) — most are tag B "was swallowing a real bug" because failures here drop columns from the report silently; (3) 1009 LOC with `Connect-ToMicrosoftGraph` at 165 LOC (lines 54–218) — the largest single Graph-connect function across the audited Graph-using set (`m365_user_list` ≈ 130 LOC, `license_expiration_checker` ≈ 113 LOC) and the strongest case for the `Connect-SouliTEKMgGraph` extraction flagged as the "single highest-value module-extraction candidate" in `scripts-license_expiration_checker.md` F3 #4. Secondary concerns: no `[CmdletBinding()]` anywhere; no `#Requires` directive; `Split-Path -Parent $MyInvocation.MyCommand.Path` instead of `$PSScriptRoot` (line 20); `Ensure-OutputFolder` uses the unapproved verb `Ensure` (should be `Initialize-` or `New-`); the four export functions (`Export-ToTXT/CSV/HTML/JSON` lines 556–888) duplicate ~85 LOC of identical scaffolding (header check → folder ensure → timestamp filename → try/catch → footer); zero `Read-Host` calls during data ops but the main menu still has one at line 968 plus 14 blocking `$Host.UI.RawUI.ReadKey` "Press any key to return to menu" prompts inside an unconditional `do { ... } while ($true)` main loop that will hang under SYSTEM/RMM execution; banner block occupies lines 1–6 (notably **shorter** than the C11 template — this is a positive baseline already close to the recommended 3-line header); no `Disconnect-FromMicrosoftGraph` in the script-level `finally` block so a Ctrl+C leaks the Graph session until the SDK token expires. Recommended phase entry order: P1 (C1 + C2 — but C2 has zero callers here, so this is essentially a C1-only sweep), P2 (C4 triage — high-value, the report silently drops storage/owners/dates today), P4 (the `Connect-SouliTEKMgGraph` extraction, the export-scaffold extraction, and the Graf SDK helper consolidation across the six-script Graph-using set).

## Findings

### F1 — Raw `Write-Host` calls not migrated to `Write-Ui` (see C1)
- **Severity:** med
- **Category:** output-style
- **Location:** scripts/sharepoint_site_inventory.ps1 — 141 raw `Write-Host` occurrences. Zero legacy `Write-SouliTEK*` wrapper calls (this script has no C2 callers — confirmed by `Select-String -Pattern 'Write-SouliTEK(Result|Info|Success|Warning|Error)'` returning no matches).
- **Reference:** [C1](00-cross-cutting.md#c1--raw-write-host-calls-not-migrated-to-write-uiwrite-status)
- **Current (representative pattern — paired success banner at lines 197–199):**
  ```powershell
  Write-Host "============================================================" -ForegroundColor Green
  Write-Ui -Message "  [+] Microsoft Graph Connected Successfully" -Level "OK"
  Write-Host "============================================================" -ForegroundColor Green
  ```
- **Recommended:**
  ```powershell
  Show-Section -Title "Microsoft Graph Connected Successfully" -Level "OK"
  ```
  (assumes a `Show-Section` helper is added in P4 alongside C1; until then collapse to a single `Write-Ui -Level "OK"` and drop the manual dividers.)
- **Risk if changed:** Low — message text preserved verbatim; the `[OK]`/`[ERROR]` bracket emitted by `Write-Ui` replaces the manual colour band. Per-category fix patterns enumerated below.
- **Local notes:** Four categories of raw `Write-Host`:
  1. **Blank-line / spacer calls** — bare `Write-Host ""` used as vertical spacing accounts for ~75 of the 141 calls (sample lines: 60, 78, 83, 87, 116, 121, 125, 135, 139, 147, 156, 163, 166, 176, 196, 200, 204, 208, 210, 215, 225, 232, 242, 247, 257, 261, 263, 265, 269, 271, 275, 399, 408, 415, 422, 486, 489, 493, 495, 506, 519, 523, 528, 531, 534, 547, 551, 561, 574, 624, 626, 629, 633, 635, 647, 660, 684, 686, 689, 693, 695, 707, 720, 804, 806, 809, 813, 815, 827, 840, 872, 874, 877, 881, 883, 895, 899, 907, 913, 918, 921, 926, 928, 930, 950, 952, 954, 965, 981, 983, 987, 999, 1003, 1005). Not C1 violations per the "visual separator helpers" exception; noisy but acceptable.
  2. **Decorative `===` dividers** — `Write-Host "============================================================" -ForegroundColor Green|Red|Yellow|Cyan|DarkGray` (lines 197, 199, 205, 207, 258, 260, 266, 268, 483, 485, 490, 492, 550, 621, 623, 630, 632, 681, 683, 690, 692, 801, 803, 810, 812, 869, 871, 878, 880, 929, 951, 966, 1000, 1002). Same C1 status as the same pattern in `scripts-license_expiration_checker.md` F1 — borderline allowable as section separators, but the repeated `==== / [LEVEL] message / ====` three-line block (15 occurrences) is a clear extract candidate for a `Show-Section -Title -Level` helper in P4.
  3. **Decorative `---` dividers** — `Write-Host "------------------------------------------------------------" -ForegroundColor Yellow|Gray` (lines 117, 243, 518, 533, 894). Same status as #2.
  4. **Inline-colour formatting** — actual C1 violations where `Write-Host` is used in feature code rather than as a separator:
     - Line 44: `Write-Host ("{0,-$pad}: {1}" -f $Label, $Value) -ForegroundColor $Color` inside `Write-SummaryLine` — this is the body of a helper that should itself wrap `Write-Ui`. Migrate the helper to use `Write-Ui -Message ("{0,-$pad}: {1}" -f $Label, $Value) -Level "INFO"`, dropping the `[ConsoleColor]$Color` parameter (the colour is encoded in `-Level`).
     - Line 122: `Write-Host "Select option (1-2): " -NoNewline -ForegroundColor Cyan` — prompt label before a `ReadKey`. Use `Write-Ui -Message "Select option (1-2): " -Level "STEP" -NoNewline` if the `-NoNewline` switch exists on `Write-Ui` (verify); otherwise inline this prompt is defensible because `Read-Host`/`ReadKey` UX requires no trailing newline.
     - Line 124: `Write-Host $reconnectChoice.Character` — echoes the chosen character after `ReadKey`. Same `-NoNewline` rationale; acceptable.
     - Line 244, 246: `Write-Host "Are you sure you want to disconnect? (Y/N): " -NoNewline -ForegroundColor Yellow` + `Write-Host $confirm.Character` — same Y/N prompt + echo pattern. Same rationale as 122/124.
     - Line 543: `Write-Host "    Type: $($site.SiteType)" -ForegroundColor $typeColor` inside `Show-SiteSummary` — encodes a green/yellow status the `Write-Ui -Level "OK"`/`"WARN"` API already represents. Clear C1 violation: migrate to `$typeLevel = if ($site.ConnectedToGroup) { 'OK' } else { 'WARN' }; Write-Ui -Message "    Type: $($site.SiteType)" -Level $typeLevel`.
     - Line 943, 944: `Write-Host "Connection Status: " -NoNewline -ForegroundColor Gray` + `Write-Host $connectionStatus -ForegroundColor $connectionColor` inside `Show-MainMenu` — same status-line concatenation pattern as F1.4 of `scripts-license_expiration_checker.md`. Migrate to `$connectionLevel = if ($Script:Connected) { 'OK' } else { 'ERROR' }; Write-Ui -Message "Connection Status: $connectionStatus" -Level $connectionLevel`.
- **Local notes (cont.) — inline marker prefixes:** 20 `Write-Ui` calls in this script already double-mark with embedded `[+]`/`[-]` prefixes inside the message (lines 79, 84, 92, 134, 145, 198, 206, 259, 267, 484, 491, 622, 631, 682, 691, 802, 811, 870, 879, 1001). Same anti-pattern as F2 of `scripts-driver_integrity_scan.md` and F1 of `scripts-license_expiration_checker.md` — when the C1 sweep runs, strip these inline markers so the `[LEVEL]` bracket emitted by `Write-Ui` is the only marker.
- **Local notes (cont.) — no C2 callers:** This is the **first audited script with zero `Write-SouliTEK*` legacy-API calls** — task plan predicted "comparable to license_expiration_checker" but C2 is fully clean here. That means the C1 sweep on this file is a one-and-done; nothing has to wait for the "delete the five legacy functions" step in C2.
- **Target phase:** P1

### F2 — `-ErrorAction SilentlyContinue` triage (see C4)
- **Severity:** med
- **Category:** error-handling
- **Location:** scripts/sharepoint_site_inventory.ps1 — 12 occurrences (task plan predicted 12 — confirmed). One is a preference variable, two are session probes (tag A), one is a graceful cleanup (tag A), eight are Graph-SDK swallows (tags B/C).
- **Reference:** [C4](00-cross-cutting.md#c4----erroraction-silentlycontinue-swallowing-failures)
- **Triage:**
  - Line 15: **not a C4 finding** — `$ProgressPreference = 'SilentlyContinue'` is a preference-variable assignment used to suppress Graph SDK progress bars during module installation. Same status as line 41 in `scripts-license_expiration_checker.md`. Note for completeness only.
  - Line 90: tag **A** — `Get-MgContext -ErrorAction SilentlyContinue` is a probe; the result is immediately tested with `if ($context)` to decide whether to re-auth. Legitimate "is there an existing session?" check. Add `# safe: probe` comment in P2.
  - Line 130: tag **A** — `Disconnect-MgGraph -ErrorAction SilentlyContinue | Out-Null` is graceful disconnect during a re-auth flow; the surrounding `try { ... } catch { Write-Warning ... }` already handles failure on the path that matters. Legitimate cleanup. Add `# safe: cleanup` comment.
  - Line 237: tag **A** — `Get-MgContext -ErrorAction SilentlyContinue` in `Disconnect-FromMicrosoftGraph`, same probe pattern as line 90. Add `# safe: probe` comment.
  - Line 287: tag **B** — `Get-MgSiteDrive -SiteId $SiteId -ErrorAction SilentlyContinue` inside `Get-SiteStorage`. If a permission or transient Graph error occurs, the function silently returns "0 MB" with no indication to the operator that the storage column is wrong. Replace with `try { ... } catch { Write-Ui -Message "Could not query drives for $SiteId : $($_.Exception.Message)" -Level "WARN"; return "Unknown" }`. **Behavioural change:** report column shows `Unknown` instead of misleading `0 MB` when the call fails — aligns with CLAUDE.md "fail closed — deny by default."
  - Line 291: tag **B** — `Get-MgDrive -DriveId $drive.Id -ErrorAction SilentlyContinue` inside the per-drive loop of `Get-SiteStorage`. Same rationale as line 287 but per-drive. Same fix pattern. Aggregate: at minimum, count drives that failed and surface `"$used / $failed-of-$total"` in the summary, so a partially-failed query doesn't underreport storage as if every drive was zero.
  - Line 330: tag **B** — `Get-MgGroupOwner -GroupId $GroupId -ErrorAction SilentlyContinue` inside `Get-SiteOwners`. If the call fails, the function silently returns an empty owners array and the report shows "No owners" — a real-world false negative because the most common failure here is a missing `Group.Read.All` consent, not "the group genuinely has no owners." Replace with `try { ... } catch { Write-Ui -Message "Could not list owners for group $GroupId : $($_.Exception.Message)" -Level "WARN"; return @('<query failed>') }` so the failure is visible in the report itself.
  - Line 334: tag **B** — `Get-MgUser -UserId $owner.Id -Property UserPrincipalName,DisplayName -ErrorAction SilentlyContinue` inside the per-owner loop. The existing pattern is "try user, if fail try group" (lines 333–349) which uses `SilentlyContinue` as control flow — that's defensible as long as the **outer** fallback path catches it. Recommend keeping the user lookup as `SilentlyContinue` but adding `# safe: probe — fallback to Get-MgGroup below` so the intent is documented.
  - Line 341: tag **A** — same as line 334: the inner `Get-MgGroup` is the second leg of a try/try chain where silent fail is the design intent. Add `# safe: probe — accept skip if neither user nor group` comment.
  - Line 363: tag **B** — `Get-MgSite -SiteId $SiteId -Property LastModifiedDateTime -ErrorAction SilentlyContinue` inside `Get-SiteLastActivity`. If this fails, the function returns "Never" — a misleading value because the site clearly exists (it was returned by the parent `Get-MgSite -All` call on line 411). Replace with the same `try { ... } catch { Write-Ui -Level "WARN"; return "Unknown" }` pattern as line 287.
  - Line 369: tag **B** — `Get-MgSiteDrive` again inside `Get-SiteLastActivity`. Same fix pattern as line 287. **Note:** this is a duplicate call to `Get-MgSiteDrive` for the same `$SiteId` already queried at line 287 inside `Get-SiteStorage` — the two functions both walk the drive list per site, which is an N×2 Graph round-trip pattern. F3 (extract candidate) covers a refactor where one drive enumeration feeds both storage and last-activity output.
  - Line 373: tag **B** — `Get-MgDrive -DriveId $drive.Id -Property LastModifiedDateTime -ErrorAction SilentlyContinue` inside the per-drive loop. Same fix pattern as line 291.
- **Local notes:** This script has the **largest C4 surface of any Graph-using script audited so far** (12 vs 2 in `license_expiration_checker`). Five of the swallows are the same fundamental pattern — Graph SDK call inside a `try {} catch {}` block, with `-ErrorAction SilentlyContinue` *also* set on the call, which **double-suppresses errors**: the catch is unreachable for non-terminating errors because `SilentlyContinue` never throws. Either remove `-ErrorAction SilentlyContinue` and let the `try`/`catch` work as intended (recommended), or remove the `try`/`catch` and add the `# safe:` comment — but not both. The current code has the worst of both worlds: looks defended, actually swallows everything silently.
- **Target phase:** P2

### F3 — Large monolithic `Connect-ToMicrosoftGraph` + duplicated export scaffolds (see C6)
- **Severity:** med
- **Category:** structure
- **Location:** scripts/sharepoint_site_inventory.ps1 — 1009 LOC; 16 functions; 5 functions over 80 LOC
- **Reference:** [C6](00-cross-cutting.md#c6--scripts-1000-loc-with-extractable-duplication)
- **Function sizes (sorted descending):**
  | Function | LOC | Lines | Notes |
  |---|---|---|---|
  | `Connect-ToMicrosoftGraph` | 165 | 54–218 | Module install → existing-session check → re-auth Y/N prompt → fresh connect → org info fetch → success/failure banner. Heavy banner repetition (`====` dividers on lines 197, 199, 205, 207). |
  | `Get-AllSites` | 106 | 394–499 | `Get-MgSite -All` enumeration + per-site call to `Get-SiteStorage`/`Get-SiteOwners`/`Get-SiteLastActivity` + `$Script:SiteData` build. Mixes data collection with output formatting. |
  | `Export-ToHTML` | 119 | 702–820 | Single giant here-string with inline `foreach` for `<tr>` rows. Template + data interleaved. |
  | `Export-ToTXT` | 85 | 556–640 | Builds an `$content` string array, writes via `Out-File`. Same try/catch/footer scaffold as the other three exporters. |
  | `Export-ToCSV` | 59 | 642–700 | `Export-Csv -Path ... -NoTypeInformation`. Same scaffold. |
  | `Export-ToJSON` | 67 | 822–888 | Builds nested hashtable, writes via `ConvertTo-Json -Depth 10`. Same scaffold. |
  | `Disconnect-FromMicrosoftGraph` | 61 | 220–280 | Conditional disconnect with Y/N confirm. Same `===` banner pattern as the connect function. |
  | `Show-MainMenu` | 59 | 935–993 | Banner + status header + menu list + `switch` dispatch. |
  | `Show-Help` | 44 | 890–933 | Static help text via `Write-Ui` lines + footer. |
  | `Show-SiteSummary` | 54 | 501–554 | Counts + top-10 list rendering. |
- **Extraction candidates (in P4 order):**
  1. **`Connect-SouliTEKMgGraph -Scopes <string[]> -ShowOrgInfo` helper** — this is the F3 #4 candidate from `scripts-license_expiration_checker.md` and the single most valuable module extraction in the audit set. The sharepoint_site_inventory version at 165 LOC is the **largest single connect function across the Graph-using script set** (`m365_user_list` ≈ 130 LOC, `license_expiration_checker` ≈ 113 LOC). Three scripts × ~130 LOC average = ~400 LOC to delete from the script set. The helper signature should be:
     ```powershell
     function Connect-SouliTEKMgGraph {
         [CmdletBinding()]
         param(
             [Parameter(Mandatory)][string[]]$Scopes,
             [string[]]$ModulesToInstall = @('Microsoft.Graph.Authentication'),
             [switch]$ShowOrgInfo,
             [switch]$ForceReauth
         )
         # Returns a [PSCustomObject]@{ Connected = $true/$false; TenantName = ...; TenantDomain = ...; Account = ...; TenantId = ... }
     }
     ```
     Then each script's local `Connect-ToMicrosoftGraph` shrinks to ~10 lines that call the helper and copy the returned fields into `$Script:Connected` / `$Script:TenantName` / `$Script:TenantDomain`. Paired `Disconnect-SouliTEKMgGraph` is trivial (3 lines + cleanup hook).
  2. **`Format-SouliTEKByteSize -Bytes <long>` helper** — the human-readable byte conversion at lines 308–318 (KB/MB/GB/TB) is duplicated in `EventLogAnalyzer.ps1`, `temp_removal_disk_cleanup.ps1`, `usb_device_log.ps1`, and elsewhere. Extract once, delete 5 copies. Standard pattern, ~12 lines per duplicate.
  3. **Export scaffold deduplication** — the four `Export-To*` functions (lines 556–888, ~330 LOC combined) share an identical 9-step scaffold: header → `if ($Script:SiteData.Count -eq 0)` guard → `try` → `Ensure-OutputFolder` → timestamped filename → write file → success banner → catch → footer "Press any key". Extract `Invoke-SouliTEKReportExport -Format <Txt|Csv|Html|Json> -Data $Script:SiteData -OutputFolder $Script:OutputFolder` that owns the scaffold and dispatches the format-specific body to four small render functions (`Format-SiteInventoryTxt`, `-Csv`, `-Html`, `-Json`). Saves ~80 LOC and centralises the "Press any key to return to menu" prompt — which is the single biggest source of RMM-deadlock risk (see F4).
  4. **Combine `Get-SiteStorage` + `Get-SiteLastActivity`** — both functions call `Get-MgSiteDrive -SiteId $SiteId` (lines 287 + 369), doubling the Graph round-trips per site. Refactor to one `Get-SiteDriveSummary -SiteId` that returns `[PSCustomObject]@{ StorageBytes = ...; LastModified = ... }`. Halves the per-site Graph traffic; for a 500-site tenant that's 500 saved round-trips per `Get-AllSites` run.
- **Target phase:** P4

### F4 — Cross-script Graph auth duplication (local note feeding C6 #1)
- **Severity:** med
- **Category:** structure
- **Location:** scripts/sharepoint_site_inventory.ps1:54–218 (`Connect-ToMicrosoftGraph`); cross-references `scripts/license_expiration_checker.ps1:132–244` and `scripts/m365_user_list.ps1:59–~190`.
- **Local notes:** Three scripts in the audited set implement near-identical `Connect-ToMicrosoftGraph` / `Disconnect-FromMicrosoftGraph` pairs:
  - `scripts/sharepoint_site_inventory.ps1` — 165 LOC connect (this script)
  - `scripts/license_expiration_checker.ps1` — 113 LOC connect (audited; see F3 #4 of `scripts-license_expiration_checker.md`)
  - `scripts/m365_user_list.ps1` — ~130 LOC connect (unaudited at time of writing)
  - Three additional scripts not yet audited but expected to follow the same pattern per the F3 #4 cross-reference: `m365_exchange_online.ps1`, `exchange_calendar_permissions_audit.ps1`, `onedrive_status_checker.ps1`.

  Concrete diffs between the three audited copies:
  - **Module list differs per script** — sharepoint_site_inventory installs `Microsoft.Graph.{Authentication,Sites,Groups,Identity.DirectoryManagement}` (4 modules, lines 62–67); license_expiration_checker installs only `Microsoft.Graph.{Authentication,Identity.DirectoryManagement}` (2 modules); m365_user_list installs `Microsoft.Graph.{Authentication,Users,Identity.DirectoryManagement}` (3 modules). Helper must accept `-ModulesToInstall <string[]>` to preserve this per-script behaviour.
  - **Scope list differs per script** — sharepoint passes `Sites.Read.All,Group.Read.All,Organization.Read.All`; license passes `Organization.Read.All`; m365_user_list passes `User.Read.All,Organization.Read.All`. Helper must accept `-Scopes <string[]>` mandatory.
  - **Re-auth UX differs** — sharepoint_site_inventory has a "1. Keep / 2. Disconnect and connect to a different tenant" prompt (lines 117–151) that the other two scripts do not. Helper should accept `-AllowTenantSwitch` switch.
  - **Org-info fetch is identical** — all three call `Get-MgOrganization -ErrorAction Stop | Select-Object -First 1` and walk `.VerifiedDomains | Where-Object IsDefault`. Helper bakes this in behind `-ShowOrgInfo`.
- **Recommended:** Add `Connect-SouliTEKMgGraph` + `Disconnect-SouliTEKMgGraph` + `Get-SouliTEKMgGraphOrgInfo` to the common module as part of P4's `MODERNIZATION HELPERS` section (cross-cut C10 dependency). Each call site shrinks from 113–165 LOC to ~10 LOC. **This is the single largest LOC-deletion opportunity in the entire audit set so far** — conservatively 6 scripts × 115 LOC avg = ~700 LOC removed, replaced with ~300 LOC of one module helper + 6 × ~10-line call sites.
- **Risk if changed:** Medium — concurrency/state risk is low because Graph SDK already serialises auth; behavioural risk is the re-auth prompt UX (only sharepoint has it, would either be preserved by `-AllowTenantSwitch` or dropped). Must add Pester tests around the helper before the rollout (C7 dependency).
- **Target phase:** P4 (blocked on C6 helper section and C7 test fixtures)

### F5 — `Ensure-OutputFolder` uses unapproved verb `Ensure`
- **Severity:** low
- **Category:** naming / style
- **Location:** scripts/sharepoint_site_inventory.ps1:47 (definition), called from lines 568, 654, 714, 834
- **Current:**
  ```powershell
  function Ensure-OutputFolder {
      param([string]$Path)
      if (-not (Test-Path -Path $Path)) {
          [void](New-Item -ItemType Directory -Path $Path -Force)
      }
  }
  ```
- **Recommended:**
  ```powershell
  function Initialize-OutputFolder {
      param([string]$Path)
      if (-not (Test-Path -Path $Path)) {
          [void](New-Item -ItemType Directory -Path $Path -Force)
      }
  }
  ```
  And update the four call sites at lines 568, 654, 714, 834. (`Get-Verb` lists `Initialize` as approved; `Ensure` is not on the list. PSScriptAnalyzer raises `PSUseApprovedVerbs` for this.) An even better fix during the F3 #3 export-scaffold extraction is to fold this whole function into the centralised `Invoke-SouliTEKReportExport` helper so it disappears entirely.
- **Risk if changed:** Low — pure rename; 1 definition + 4 callers, all internal to this file. No public API surface.
- **Target phase:** P4 (fold into export-scaffold extraction)

### F6 — No `#Requires` directive + no `[CmdletBinding()]` anywhere
- **Severity:** low
- **Category:** structure
- **Location:** scripts/sharepoint_site_inventory.ps1 — script-level top of file (no `#Requires`) and every one of the 16 internal functions (no `[CmdletBinding()]`)
- **Local notes:** Confirmed via `Select-String -Pattern '^#Requires|CmdletBinding'` — zero matches in the file. `license_expiration_checker.ps1` declares `#Requires -Modules Microsoft.Graph.Identity.DirectoryManagement` at the top; sharepoint_site_inventory declares nothing. Recommend adding:
  ```powershell
  #Requires -Version 5.1
  #Requires -Modules Microsoft.Graph.Authentication, Microsoft.Graph.Sites, Microsoft.Graph.Groups, Microsoft.Graph.Identity.DirectoryManagement
  ```
  ...except that the `Install-SouliTEKModule` pattern on lines 70–75 is specifically designed to install these modules at runtime, which conflicts with a `#Requires -Modules` directive that fails fast if they're absent. Resolution: either (a) keep the runtime install but add `#Requires -Version 5.1` only, or (b) drop the runtime install and rely on the `#Requires -Modules` precondition. Option (a) is the safer baseline given the script is interactive and surfaces install errors in the menu UI. Defer to the F4 helper rollout — `Connect-SouliTEKMgGraph` should own the install-or-require decision uniformly across the Graph-using script set.

  `[CmdletBinding()]` would benefit the four exporters (lines 556, 642, 702, 822) which currently take no parameters but should accept `-OutputFolder` for non-interactive use. Defer to F3 #3 export-scaffold extraction.
- **Target phase:** P4

### F7 — `Split-Path -Parent $MyInvocation.MyCommand.Path` instead of `$PSScriptRoot`
- **Severity:** low
- **Category:** structure
- **Location:** scripts/sharepoint_site_inventory.ps1:20
- **Current:**
  ```powershell
  $ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
  ```
- **Recommended:**
  ```powershell
  $ScriptRoot = $PSScriptRoot
  ```
- **Risk if changed:** Low — same justification as F5 of `scripts-driver_integrity_scan.md` and F8 of `scripts-license_expiration_checker.md`. C10 sweep replaces this entire block with `Import-SouliTEKCommon`.
- **Target phase:** P4 (fold into the C10 sweep)

### F8 — Infinite menu loop with no non-interactive exit + 14 blocking key-press prompts
- **Severity:** low
- **Category:** structure (UX / RMM safety)
- **Location:** scripts/sharepoint_site_inventory.ps1:992 (`do { ... } while ($true)`), plus 1 `Read-Host` at line 968 and 14 blocking `$Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")` calls at lines 123, 141, 149, 227, 245, 279, 401, 417, 497, 508, 553, 563, 639, 649, 699, 709, 819, 829, 887, 932, 1007.
- **Local notes:** Same pattern as F6 of `scripts-driver_integrity_scan.md` and F9 of `scripts-license_expiration_checker.md`. The use of `ReadKey` (binary, no input parse) instead of `Read-Host` (string) is harmless under interactive mode but **silently fails** under SYSTEM context with no console host — `$Host.UI.RawUI` may not exist, throwing `Cannot find a constructor` or returning immediately. The single `Read-Host` at line 968 will deadlock instead. Worth a guard:
  ```powershell
  if (-not [Environment]::UserInteractive) {
      Write-Ui -Message "This script is interactive-only and cannot run under SYSTEM/non-interactive context." -Level "ERROR"
      exit 1
  }
  ```
  at the top of `Show-MainMenu` (around line 936). Defer to P4 unless an RMM hang is reported.
- **Target phase:** P4

### F9 — Graph session not disconnected on Ctrl+C or unhandled exit
- **Severity:** info
- **Category:** structure (resource leak)
- **Location:** scripts/sharepoint_site_inventory.ps1:996–1008 (script-level `try { Show-MainMenu } catch { ... }` — no `finally` block)
- **Local notes:** Same issue noted in the third out-of-scope bullet of `scripts-license_expiration_checker.md`. If the user kills the script via Ctrl+C, the Graph session leaks until the SDK token expires (~1 hour). Fix by wrapping `Show-MainMenu` in `try { ... } finally { if ($Script:Connected) { Disconnect-MgGraph -ErrorAction SilentlyContinue | Out-Null } }`. Low priority — the SDK token is short-lived and the leak is contained to one process tree. Best handled inside `Connect-SouliTEKMgGraph` (F4) so all six Graph-using scripts get the cleanup automatically.
- **Target phase:** P4 (fold into F4 helper rollout)

### F10 — `Show-Help` documents `Disconnect` as Option 2 but lists eight reasons to skip it
- **Severity:** info
- **Category:** correctness (documentation only)
- **Location:** scripts/sharepoint_site_inventory.ps1:922–925 (`USAGE:` block inside `Show-Help`)
- **Local notes:** The `USAGE:` section says "1. Connect ... 2. Retrieve all sites (Option 3) 3. View summary or export reports (Options 4-8)" — option 2 (`Disconnect from Current Tenant`) is skipped entirely in the documented flow. The numbering implies the user should use Option 3 second, which is correct, but a less confused reader would expect "Option 2 = step 2 of usage flow." Either renumber the menu so Disconnect is `[9]` and the report flow is `[2]–[8]`, or change the USAGE prose to "After connecting, choose [3] to retrieve sites, then [4]–[8] to view/export." Cosmetic, but the menu ordering also matters for muscle-memory consistency — `m365_user_list` and `license_expiration_checker` should be cross-checked for the same Disconnect-in-position-2 pattern during the F4 helper rollout.
- **Target phase:** —

## Out-of-scope notes
- Banner block (lines 1–6, only 6 lines) is **shorter than the C11 template** — this is a positive baseline. The C11 cross-cutting cleanup target is "collapse to a 3-line standard header"; this file is already close. No change needed beyond what C11 normalises across the full set.
- The `[ConsoleColor]$Color = 'Cyan'` parameter on `Show-Header` (line 37) is unused at every call site — every `Show-Header "Title"` call relies on the default. Dead parameter; drop it during the F1 sweep.
- `Write-SummaryLine` (lines 41–45) is a one-call-site helper used only inside `Show-SiteSummary` (lines 521, 522, 525, 526, 527, 529, 530). Either inline it during the F1 sweep, or migrate to `Write-Ui` and keep as a helper. Either way the `-ForegroundColor $Color` parameter should be removed (see Local notes #4 of F1).
- The `$Script:SiteData = @()` re-initialisation on line 424 inside `Get-AllSites` correctly resets the array on each retrieval — good defensive practice. No change needed.
- The `Write-Progress -Activity "Processing Sites" -Status "Site $processedCount of $($allSites.Count)" -PercentComplete (($processedCount / $allSites.Count) * 100)` pattern on line 429 is the only `Write-Progress` use in the script and is a model implementation: completes with `-Completed` on line 481, uses safe integer division, and respects the `$ProgressPreference = 'SilentlyContinue'` suppression set at line 15. No change needed.
- The HTML report's `<style>` block (lines 728–737) uses an inline gradient (`#667eea`) that matches the SouliTEK launcher theme. Per CLAUDE.md "Output encoding / sanitization — prevent injection at every output point", note that `$site.SiteURL`, `$site.DisplayName`, etc. are interpolated directly into HTML without `[System.Net.WebUtility]::HtmlEncode`. SharePoint site names *can* contain `<`/`>`/`&` characters (rare but legal); a maliciously-named site could inject HTML into the report. Recommend wrapping every `$($site.X)` inside the HTML here-strings with `$(([System.Net.WebUtility]::HtmlEncode($site.X)))` during the F3 #3 export-scaffold extraction. This is the only injection-relevant finding in the script.
- The four `Export-To*` functions all call `Out-File -FilePath $filepath -Encoding UTF8` (lines 619, 679 via `Export-Csv`, 799, 867). On PS 5.1 this is BOM-UTF-8; on PS 7+ this is BOM-less UTF-8. The CSV exporter uses `Export-Csv -Encoding UTF8` which has the same quirk. Spreadsheet tools (Excel) handle both; downstream JSON consumers strip BOMs by convention. No change needed but worth a note in the modernization spec if exact encoding parity is ever required.
- The `[PSCustomObject]@{...}` site-data builder at lines 466–478 mixes typed fields (`Owners` array, `OwnerCount` int) with string-formatted fields (`StorageUsed` "0 MB", `LastActivityDate` "2024-03-15", `CreatedDate` "2024-03-15"). The pre-formatting in `Get-SiteStorage` and `Get-SiteLastActivity` makes the JSON output less useful for automation (the script's stated audience per `Show-Help` line 912: "JSON: Clean JSON format for automation"). Recommend storing the raw bytes/dates in `$Script:SiteData` and formatting only at render time inside the export functions — clean follow-up paired with F3 #4 drive-summary refactor.
- Zero `Get-WmiObject` calls (C3 clean). Zero `netsh` calls (C14 N/A). Zero `Write-SouliTEK*` legacy API calls (C2 clean — the first audited script with zero C2 callers).
- `$Script:OutputFolder` is parameterisable via the script-level `param([string]$OutputFolder = ...)` block (lines 8–10) — that already addresses the "hard-coded Desktop path" finding raised against `scripts-driver_integrity_scan.md` F7 and `scripts-license_expiration_checker.md` F10. **This script does it right** and is the model the other two should follow.
