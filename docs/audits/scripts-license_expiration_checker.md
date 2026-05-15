# Audit — scripts/license_expiration_checker.ps1

## Inventory
| Item | Value |
|---|---|
| Path           | scripts/license_expiration_checker.ps1 |
| LOC            | 1385 |
| Functions      | 19 |
| `#Requires`    | `#Requires -Modules Microsoft.Graph.Identity.DirectoryManagement` |
| Admin-required | no — read-only Microsoft Graph queries (`Organization.Read.All`); no local system mutation. Note: the `Install-SouliTEKModule` path used at line 150 to install `Microsoft.Graph.Authentication` / `Microsoft.Graph.Identity.DirectoryManagement` will require admin if `-Scope AllUsers` is selected by that helper; if installed `-Scope CurrentUser` (the documented default), admin is not required. |
| Last touched   | 8675720 — 2026-04-17 |
| Modernization grade | C |

## Summary

A menu-driven Microsoft 365 license capacity / "expiration" monitor: connects to Graph (`Connect-MgGraph -Scopes "Organization.Read.All"`), enumerates `Get-MgSubscribedSku` results, maps cryptic SKU part numbers to friendly names via a hard-coded 40-entry hashtable inside `Get-FriendlySkuName`, and renders four reports (status table, detailed service-plan dump, usage stats with ASCII bars, and TXT/CSV/HTML export). The biggest issues are (1) 187 raw `Write-Host` calls plus 31 legacy `Write-SouliTEK*` wrapper calls coexisting with `Write-Ui` (C1 + C2 mixed output style — the highest raw-`Write-Host` count seen so far in the per-script audits); (2) the 1385-LOC body has 7 functions over 85 LOC each, the biggest being `Get-LicenseStatus` at 128 LOC and `Connect-ToMicrosoftGraph` at 113 LOC, both ripe for extraction into smaller render/connect helpers (C6); (3) the 40-entry SKU→friendly-name mapping table on lines 79–118 is a maintenance hazard (Microsoft adds/renames SKUs every quarter; the table must be hand-edited and re-deployed each time) — a clean follow-up is to move it to `config/license-skus.json` so the table can be refreshed without touching code. Secondary concerns: only 2 `-ErrorAction SilentlyContinue` occurrences (one is the `$ProgressPreference` preference variable on line 41 which is **not** a `-ErrorAction` parameter and shouldn't be C4-tagged; the other is a legitimate `Get-MgContext` probe on line 164 — overall a very clean C4 surface); no `[CmdletBinding()]` anywhere; `Split-Path -Parent $MyInvocation.MyCommand.Path` instead of `$PSScriptRoot` (line 46); 22 `Read-Host` prompts inside an unconditional `do { ... } while ($choice -ne "0")` main loop that will hang under SYSTEM/RMM execution; banner block occupies lines 1–32; the `Send-EmailAlert` function (line 704) advertises an email-sending feature but never actually sends mail — it only saves an HTML file and prints "use `Send-MailMessage` with proper credentials", a UX bug worth flagging. Recommended phase entry order: P1 (C1 + C2), then P4 (C6 extraction + license-SKU table externalisation).

## Findings

### F1 — Mixed `Write-Host` / `Write-Ui` / `Write-SouliTEK*` (see C1)
- **Severity:** med
- **Category:** output-style
- **Location:** scripts/license_expiration_checker.ps1 — 187 raw `Write-Host` occurrences (sample lines: 136, 137, 152, 169, 171, 173, 217, 219, 229, 231, 319, 321, 334, 335, 336, 344, 382, 384, 392, 394, 396, 400, 434, 436, 444, 462, 481, 482, 483, 494, 545, 547, 554, 556, 574, 578, 580, 597, 606, 669, 708, 710, 802, 804, 1217, 1222, 1231, 1237, 1250, 1260, 1292, 1294, 1306, 1308, 1319, 1321, 1329). Plus 31 legacy `Write-SouliTEK*` wrapper calls (lines 151, 221, 250, 254, 261, 275, 296, 303, 403, 425, 499, 516, 609, 625, 695, 724, 776, 791, 794, 814, 819, 871, 875, 888, 984, 1027, 1034, 1084, 1098, 1199 — sole user of the highest-volume C2 caller set in any single script).
- **Reference:** [C1](00-cross-cutting.md#c1--raw-write-host-calls-not-migrated-to-write-uiwrite-status)
- **Current (representative pattern — inline-color seat counter at line 334–336):**
  ```powershell
  Write-Host "  Used Seats: $consumed" -ForegroundColor $(if ($consumed -eq $enabled) { 'Red' } elseif ($consumed -ge $enabled * 0.8) { 'Yellow' } else { 'Green' })
  Write-Host "  Available: $available" -ForegroundColor $(if ($available -eq 0) { 'Red' } elseif ($available -le 5) { 'Yellow' } else { 'Green' })
  Write-Host "  Usage: $usagePercent%" -ForegroundColor $(if ($usagePercent -ge 100) { 'Red' } elseif ($usagePercent -ge 80) { 'Yellow' } else { 'Green' })
  ```
- **Recommended:**
  ```powershell
  $usedLevel  = if ($consumed -eq $enabled) { 'ERROR' } elseif ($consumed -ge $enabled * 0.8) { 'WARN' } else { 'OK' }
  $availLevel = if ($available -eq 0) { 'ERROR' } elseif ($available -le 5) { 'WARN' } else { 'OK' }
  $usageLevel = if ($usagePercent -ge 100) { 'ERROR' } elseif ($usagePercent -ge 80) { 'WARN' } else { 'OK' }
  Write-Ui -Message "  Used Seats: $consumed" -Level $usedLevel
  Write-Ui -Message "  Available: $available" -Level $availLevel
  Write-Ui -Message "  Usage: $usagePercent%" -Level $usageLevel
  ```
- **Risk if changed:** Low — message text preserved verbatim; ternary-style colour selection maps cleanly to `Level` selection. Per-category patterns enumerated in Local notes.
- **Local notes:** Four categories of raw `Write-Host`:
  1. **Blank-line / spacer calls** — bare `Write-Host ""` used as vertical spacing (sample lines: 136, 138, 141, 152, 158, 161, 169, 174, 176, 182, 187, 189, 202, 206, 211, 216, 220, 222, 228, 232, 234, 240, 262, 264, 276, 290, 292, 297, 304, 322, 329, 337, 371, 375, 379, 385, 399, 404, 411, 419, 421, 426, 437, 445, 463, 471, 491, 502, 510, 512, 517, 548, 552, 557, 575, 581, 605, 612, 620, 622, 626, 628, 634, 637, 645, 651, 658, 666, 670, 672, 677, 700, 707, 711, 714, 723, 775, 777, 783, 786, 801, 805, 809, 818, 870, 872, 876, 887, 969, 979, 981, 985, 987, 993, 995, 1001, 1037, 1083, 1097, 1198, 1214, 1216, 1218, 1228, 1234, 1238, 1240, 1249, 1261, 1266, 1271, 1276, 1281, 1286, 1291, 1295, 1300, 1305, 1309, 1312, 1315, 1318, 1322, 1328, 1330). Not C1 violations per the "visual separator" exception; noisy but acceptable.
  2. **Decorative divider lines** — `Write-Host "============================================================" -ForegroundColor Cyan` (sample lines: 137, 291, 382, 384, 400, 420, 494, 496, 511, 545, 547, 554, 556, 578, 580, 606, 621, 669, 708, 710, 802, 804, 980, 1217, 1237, 1260, 1292, 1294, 1306, 1308, 1319, 1321, 1329 — plus Green/Red/DarkCyan variants on lines 171, 173, 203, 205, 217, 219, 229, 231, 319, 321, 434, 436, 1250). Same C1 status as 01-modules-SouliTEK-Common.md: borderline allowable as section separators, but ideally replaced with a `Show-Section -Title "..."` helper in P4.
  3. **Inline-colour formatting** — typed `Write-Host "value" -ForegroundColor <Red|Yellow|Green>` for the three-state thresholds at lines 334, 335, 336, 444, 462, 482, 574, 597. Clear C1 violations — these encode a tri-state status the `Write-Ui -Level` API already represents.
  4. **Status-line concatenation** — `Write-Host "  Status: " -NoNewline` followed by `Write-Ui -Message "Active" -Level "OK"` (lines 344–346, 1222–1223, 1231–1232) — the `-NoNewline` prefix is raw `Write-Host` only to get a label printed before the `Write-Ui` line. Migrate to a single `Write-Ui -Message "  Status: Active" -Level "OK"` call.
- **Local notes (cont.) — inline marker prefixes:** 13 `Write-Ui` calls in this script already double-mark with embedded `[*]`/`[+]`/`[-]`/`[!]` prefixes inside the message (lines 159, 166, 172, 175, 195, 204, 210, 218, 230, 372, 376, 602, 644). Same anti-pattern as F2 of 01-modules-SouliTEK-Common.md and F2 of driver_integrity_scan.md — when the C1 sweep runs, strip these inline markers so the `[LEVEL]` bracket emitted by `Write-Ui` is the only marker.
- **Local notes (cont.) — legacy API callers:** 31 calls to the C2 dead API (`Write-SouliTEKResult` overwhelmingly, plus a few -Level mode variants like `-Level SUCCESS/WARNING/ERROR`). This is the **largest single block of C2 callers** in the entire per-script audit set so far. Must be migrated to `Write-Ui` before C2's "delete the five legacy functions from the module" step can land. Note the `-Level SUCCESS` argument used on `Write-SouliTEKResult` does not map to a `Write-Ui` level — `SUCCESS` should become `OK`.
- **Target phase:** P1

### F2 — `-ErrorAction SilentlyContinue` triage (see C4)
- **Severity:** low
- **Category:** error-handling
- **Location:** scripts/license_expiration_checker.ps1 — 2 occurrences (task plan predicted 2 — confirmed, but one is a preference variable, not a parameter)
- **Reference:** [C4](00-cross-cutting.md#c4----erroraction-silentlycontinue-swallowing-failures)
- **Triage:**
  - Line 41: **not a C4 finding** — `$ProgressPreference = 'SilentlyContinue'` is a preference-variable assignment used to suppress the progress bars that Microsoft Graph module installation emits. It is not a `-ErrorAction` parameter and should not be C4-tagged. Note for completeness only.
  - Line 164: tag **A** — `Get-MgContext -ErrorAction SilentlyContinue` is a probe used to detect an existing Graph session before initiating `Connect-MgGraph`; the result is immediately tested with `if ($context)` to decide whether to re-auth. Legitimate "is there an existing session?" check. Add `# safe: probe` comment in P2.
- **Local notes:** This is the cleanest C4 surface of any script audited so far — only 1 actual `-ErrorAction SilentlyContinue` parameter, and it's a defensible probe. The script otherwise uses `try { ... } catch { ... }` correctly for Graph SDK error handling (e.g. lines 191–242, 299–409, 519–610).
- **Target phase:** P2 (trivial)

### F3 — Large monolithic functions (see C6)
- **Severity:** med
- **Category:** structure
- **Location:** scripts/license_expiration_checker.ps1 — 7 functions over 85 LOC
- **Reference:** [C6](00-cross-cutting.md#c6--scripts-1000-loc-with-extractable-duplication)
- **Function sizes (sorted descending):**
  | Function | LOC | Lines | Notes |
  |---|---|---|---|
  | `Get-LicenseStatus` | 128 | 286–413 | Enumerate + per-sub render loop + summary block. Mixes data collection, output formatting, and `$Script:LicenseData` mutation. |
  | `Connect-ToMicrosoftGraph` | 113 | 132–244 | Three-step output: install modules → check context → connect. Heavy banner repetition (decorative dividers on lines 137, 171, 173, 203, 205, 217, 219, 229, 231). |
  | `Get-LicenseUsageStatistics` | 109 | 506–614 | Stats aggregation + top-5 ASCII-bar renderer (lines 561–576) + attention-needed loop. Bar-rendering block is the cleanest extraction candidate. |
  | `Export-HTMLReport` | 100 | 1103–1202 | One giant here-string with inline `foreach` interpolation. Template + data interleaved. |
  | `Send-EmailAlert` | 93 | 704–796 | Builds HTML body in a here-string, then **does not actually send** — only saves to file and prints "use Send-MailMessage". UX bug, see F4. |
  | `Export-AlertReport` | 90 | 884–973 | Another HTML here-string for the alert variant. Near-duplicate template logic with `Export-HTMLReport`. |
  | `Get-DetailedLicenseReport` | 90 | 415–504 | Per-sub render of service-plan provisioning status. |
- **Extraction candidates (in P4 order):**
  1. **HTML report template** — both `Export-HTMLReport` (lines 1109–1194) and `Export-AlertReport` (lines 894–965) build near-identical HTML with `style` blocks, header gradient, license-card sections, footer. Extract a `New-SouliTEKHtmlReport -Title -Sections -Footer` helper into the common module (P4 territory, paired with C6 helper section).
  2. **ASCII usage bar** — `Get-LicenseUsageStatistics` lines 566–574 build a `[####    ]`-style bar from a percentage. This is a generic "draw a horizontal progress bar in the console" helper — extractable as `Format-SouliTEKProgressBar -Percent N -Length N` in the module.
  3. **License-summary collection** — the `$licenseInfo = [PSCustomObject]@{...}` builder at lines 353–365 of `Get-LicenseStatus` should live in its own `New-LicenseSummary -Sku $sub` private function so `Get-DetailedLicenseReport` and `Get-LicenseUsageStatistics` can share the same data shape instead of rebuilding it ad-hoc.
  4. **Connect/disconnect Graph** — `Connect-ToMicrosoftGraph` (lines 132–244) and `Disconnect-FromMicrosoftGraph` (lines 246–257) plus `Test-GraphConnection` (lines 259–280) form a self-contained sub-API that is duplicated in spirit by `m365_user_list.ps1`, `m365_exchange_online.ps1`, `exchange_calendar_permissions_audit.ps1`, `sharepoint_site_inventory.ps1`, `onedrive_status_checker.ps1` — six scripts × ~115 LOC each is ~700 LOC of duplicated Graph-connection scaffolding. **Big P4 win:** add `Connect-SouliTEKMgGraph -Scopes <string[]>` to the common module and let all six scripts call into it. Cross-reference: this is the single highest-value module-extraction candidate in the entire audit set.
- **Target phase:** P4

### F4 — Hard-coded license SKU → friendly-name mapping table
- **Severity:** med
- **Category:** structure / maintainability
- **Location:** scripts/license_expiration_checker.ps1:79–118 (40 SKU entries inside `Get-FriendlySkuName`, lines 76–126)
- **Current:**
  ```powershell
  function Get-FriendlySkuName {
      param([string]$SkuPartNumber)

      $skuNames = @{
          'ENTERPRISEPACK' = 'Office 365 E3'
          'ENTERPRISEPREMIUM' = 'Office 365 E5'
          'ENTERPRISEPACK_B_PILOT' = 'Office 365 E3 (Preview)'
          # ... 37 more entries ...
          'DYN365_ENTERPRISE_CUSTOMER_SERVICE' = 'Dynamics 365 Customer Service'
      }

      if ($skuNames.ContainsKey($SkuPartNumber)) {
          return $skuNames[$SkuPartNumber]
      }
      else {
          return $SkuPartNumber
      }
  }
  ```
- **Recommended:** Move the table to `config/license-skus.json`:
  ```json
  {
      "ENTERPRISEPACK": "Office 365 E3",
      "ENTERPRISEPREMIUM": "Office 365 E5",
      "ENTERPRISEPACK_B_PILOT": "Office 365 E3 (Preview)",
      "_comment": "Source: https://learn.microsoft.com/azure/active-directory/enterprise-users/licensing-service-plan-reference"
  }
  ```
  And have the function load it once (cached) and fall back to the raw SKU part number if the file is missing or doesn't contain the key:
  ```powershell
  function Get-FriendlySkuName {
      param([string]$SkuPartNumber)

      if (-not $Script:SkuNameCache) {
          $configPath = Join-Path $PSScriptRoot '..\config\license-skus.json'
          if (Test-Path $configPath) {
              try {
                  $Script:SkuNameCache = Get-Content $configPath -Raw | ConvertFrom-Json -AsHashtable
              } catch {
                  Write-Ui -Message "Could not load license-skus.json: $_ — falling back to raw SKU names" -Level "WARN"
                  $Script:SkuNameCache = @{}
              }
          } else {
              $Script:SkuNameCache = @{}
          }
      }

      if ($Script:SkuNameCache.ContainsKey($SkuPartNumber)) {
          return $Script:SkuNameCache[$SkuPartNumber]
      }
      return $SkuPartNumber
  }
  ```
- **Risk if changed:** Low. Behavior preserved: same lookup semantics, same fallback to raw SKU when unknown. Benefit: Microsoft publishes the full SKU reference at https://learn.microsoft.com/azure/active-directory/enterprise-users/licensing-service-plan-reference and updates it quarterly — keeping the table in JSON lets an operator refresh it without re-deploying code. `ConvertFrom-Json -AsHashtable` is PS-6+ only; for PS 5.1 compatibility either iterate the parsed object's properties (`($json | Get-Member -MemberType NoteProperty).Name` builds the hashtable) or require PS 7.
- **Local notes:** The current 40-entry table is also incomplete (Microsoft 365 has 200+ SKU part numbers). Migrating to JSON enables shipping a reasonably complete reference file. Bonus follow-up: add a `tests/license-skus.tests.ps1` Pester test that loads the JSON and asserts the file parses + contains a set of known anchor SKUs (`ENTERPRISEPACK`, `SPE_E3`, `SPB`).
- **Target phase:** P4

### F5 — `Send-EmailAlert` advertises email sending but never sends
- **Severity:** med
- **Category:** UX / correctness
- **Location:** scripts/license_expiration_checker.ps1:704–796 (function), critical UX block lines 773–795
- **Current:** The function prompts the user for SMTP server, port, from, to addresses (lines 716–721), builds a full HTML body in a here-string (lines 727–771), and then **does not call `Send-MailMessage` or any other email-sending cmdlet**. Instead, it saves the HTML body to a file on Desktop and writes a yellow "Note: Email sending requires authentication credentials / Use `Send-MailMessage` or similar cmdlet with proper credentials" instruction (lines 783–785). The menu option `[1] Email Alert` (line 673) under `Send-ExpirationAlert` is therefore misleading — the user goes through the SMTP-input UX and ends up with a saved HTML file but no sent email.
- **Recommended:** Two options, depending on intent:
  1. **Actually send the email** — wrap the existing HTML body in `Send-MailMessage -SmtpServer $smtpServer -Port $smtpPort -From $from -To $to -Subject 'License Alert' -Body $body -BodyAsHtml -UseSsl -Credential (Get-Credential -Message 'SMTP credentials')`. Note that `Send-MailMessage` is officially deprecated in PS 7+ but still works; the recommended replacement is the third-party `Send-MailKitMessage` or direct `System.Net.Mail.SmtpClient`. For SouliTEK's "local Windows / SYSTEM RMM" deployment context, `Send-MailMessage` is the simpler short-term answer.
  2. **Honest UX rename** — change menu label from "Email Alert" to "Email Template (HTML file)" and drop the SMTP-server/port/from/to prompts; just generate the file. Existing behaviour, accurate labelling.
- **Risk if changed:** Low for option 2 (cosmetic). Medium for option 1 (introduces a credential-handling code path that must be done correctly — `Get-Credential` is fine, but never log the credential and never accept it as a plain string).
- **Local notes:** Aligns with CLAUDE.md "Always flag insecure patterns" — collecting SMTP credentials via `Read-Host` plain-text input (which is what option 1 would need if expanded inline) is itself a security concern; `Get-Credential` is the right answer because it masks input and returns a `PSCredential`. The CLAUDE.md "Logging — no logging unless I explicitly ask for it" rule supports option 1 here: don't log the SMTP server, port, or from/to addresses when sending; the current code at lines 778–782 actually does print them, which leaks the operator's mail-server topology to console output.
- **Target phase:** P3 (decision required — option 1 vs option 2)

### F6 — `Send-TeamsAlert` posts to webhook with no URL validation or domain allow-list
- **Severity:** low
- **Category:** security
- **Location:** scripts/license_expiration_checker.ps1:811–868 (URL input on line 811, POST on line 868)
- **Current:**
  ```powershell
  $webhookUrl = Read-Host "Enter Teams Webhook URL"
  if ([string]::IsNullOrWhiteSpace($webhookUrl)) { ... return }
  # ...
  Invoke-RestMethod -Method Post -Uri $webhookUrl -Body $jsonBody -ContentType 'application/json' | Out-Null
  ```
  No validation that the URL is HTTPS, points to a known Teams webhook domain (`outlook.office.com/webhook/` or `*.webhook.office.com`), or is a well-formed URI.
- **Recommended:**
  ```powershell
  $webhookUrl = Read-Host "Enter Teams Webhook URL"
  if ([string]::IsNullOrWhiteSpace($webhookUrl)) { ... return }

  $allowedHosts = @('outlook.office.com', 'webhook.office.com')
  try {
      $uri = [Uri]$webhookUrl
      if ($uri.Scheme -ne 'https') {
          Write-Ui -Message "Webhook URL must be HTTPS" -Level "ERROR"; return
      }
      if (-not ($allowedHosts | Where-Object { $uri.Host -eq $_ -or $uri.Host.EndsWith(".$_") })) {
          Write-Ui -Message "Webhook host '$($uri.Host)' is not a recognised Teams webhook endpoint" -Level "ERROR"; return
      }
  } catch {
      Write-Ui -Message "Invalid URL: $_" -Level "ERROR"; return
  }
  ```
- **Risk if changed:** Low. Aligns with CLAUDE.md "Input validation on all external data — never trust input" and OWASP SSRF prevention guidance. Without this check, a typo or paste-error could send the alert payload (which includes tenant license counts — moderate sensitivity) to an attacker-controlled host.
- **Local notes:** The license JSON payload is not catastrophic to leak (it's "we have N E3 seats, M used") but the SSRF surface is real. This is the highest-severity *security-relevant* finding in this script and the only one not already covered by a cross-cutting C-id.
- **Target phase:** P3

### F7 — No `[CmdletBinding()]` on script or any of 19 functions
- **Severity:** low
- **Category:** structure
- **Location:** scripts/license_expiration_checker.ps1 — script-level (no `param()` block) and every one of the 19 internal functions.
- **Local notes:** Confirmed via `Select-String -Pattern 'CmdletBinding'` — zero matches in the file. The script is interactive-only (menu loop, no CLI surface), so this is low severity, but the 19-function count is the highest of any audited script and the `param($CriticalLicenses, $WarningLicenses)` blocks on `Send-EmailAlert` (line 705), `Send-TeamsAlert` (line 799), `Export-AlertReport` (line 885), plus the `param($Timestamp)` on the three exporters (lines 1042, 1090, 1104) would benefit from `[CmdletBinding()]` so they can accept `-Verbose` for debugging the report-generation pipeline. Defer until the menu-loop pattern is replaced with a parameterised CLI surface (P4 follow-up).
- **Target phase:** P4

### F8 — `Split-Path -Parent $MyInvocation.MyCommand.Path` instead of `$PSScriptRoot`
- **Severity:** low
- **Category:** structure
- **Location:** scripts/license_expiration_checker.ps1:46
- **Current:**
  ```powershell
  $ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
  ```
- **Recommended:**
  ```powershell
  $ScriptRoot = $PSScriptRoot
  ```
- **Risk if changed:** Low — same justification as F5 of driver_integrity_scan.md. `$PSScriptRoot` is the canonical PS 3.0+ form; `$MyInvocation.MyCommand.Path` returns `$null` when dot-sourced.
- **Target phase:** P4 (fold into the C10 sweep)

### F9 — Infinite menu loop with no non-interactive exit + 22 blocking `Read-Host` prompts
- **Severity:** low
- **Category:** structure (UX / RMM safety)
- **Location:** scripts/license_expiration_checker.ps1:1359 (`do { ... } while ($choice -ne "0")`), plus `Read-Host` calls at lines 153, 223, 241, 265, 277, 305, 412, 503, 613, 629, 646, 679, 701, 716, 717, 720, 721, 811, 1003, 1038, 1252, 1331.
- **Local notes:** Same pattern as F6 of driver_integrity_scan.md but worse: 22 `Read-Host` calls (vs. 11 in driver_integrity_scan). Under SYSTEM-context RMM execution, every menu pivot will deadlock. No `[Environment]::UserInteractive` gate and no `-NonInteractive` switch. Defer to P4 unless an actual RMM hang report comes in; pairs naturally with the parameterised-CLI follow-up in F7 — if the script ever gains `-Action <Status|Detailed|Export|Alert>` parameters, the `Read-Host` calls in non-interactive paths should all be removed.
- **Target phase:** P4

### F10 — Hard-coded Desktop output path with no override
- **Severity:** info
- **Category:** structure
- **Location:** scripts/license_expiration_checker.ps1:63 (`$Script:OutputFolder = Join-Path $env:USERPROFILE "Desktop"`).
- **Local notes:** Same issue as F7 of driver_integrity_scan.md — the export target (used by `Export-TextReport` line 1045, `Export-CSVReport` line 1093, `Export-HTMLReport` line 1107, `Send-EmailAlert` line 789, `Export-AlertReport` line 892) is hard-coded to the current user's Desktop. Breaks under SYSTEM context where `$env:USERPROFILE` resolves to `C:\Windows\System32\config\systemprofile`. A `-OutputDirectory` parameter on `Export-LicenseReport` (and friends) would be a clean P4 follow-up alongside F7's `[CmdletBinding()]` add. Note: per CLAUDE.md "Least privilege on all file and process access", writing to Desktop is not least-privilege — `$env:LOCALAPPDATA\SouliTEK\reports\` would be a better default.
- **Target phase:** P4

## Out-of-scope notes
- Banner block (lines 1–32, 28 lines of `# === / Coded by / IMPORTANT DISCLAIMER`) matches C11 cross-cutting cleanup; covered there.
- The `$Script:AlertThresholdDays = 14` / `$Script:WarningThresholdDays = 30` constants (lines 64–65) are defined but **never read** anywhere in the script. The alert logic (lines 362–364, 587–595, 640–641) uses `$available -eq 0` and `$available -le 5` hard-coded thresholds instead. Dead code — either wire up the script variables or delete them. Low priority; P4 cleanup.
- The HTML output paths (`Export-HTMLReport`, `Export-AlertReport`) call `Start-Process $filePath` (lines 972, 1086, 1100, 1201) to auto-open the result in the user's default browser. Under SYSTEM context this will fail silently or invoke unexpected processes — same RMM-safety concern as F9 but lower-severity because the file is already written. Add a `[Environment]::UserInteractive` guard around the `Start-Process` calls when the C10 / F9 refactor lands.
- The `Disconnect-FromMicrosoftGraph` function (lines 246–257) is correctly called from `Show-ExitMessage` (line 1342) on graceful exit. If the user kills the script via Ctrl+C, the Graph session leaks until the SDK token expires. A `try { ... } finally { Disconnect-FromMicrosoftGraph }` wrap around the main menu loop (lines 1359–1381) would close the leak. Low priority; defensible to ignore because the SDK token is short-lived.
- The `Get-MgSubscribedSku -All` call (used at lines 300, 429, 520) is the **only** Graph API call made in the script. There is no actual "license expiration date" query — the `Get-MgSubscribedSku` API does not return expiration dates (a fact the script acknowledges in the comment on line 342: `# Note: Most M365 subscriptions don't have explicit expiration dates in Get-MgSubscribedSku / # This information is typically in billing/subscription APIs`). The script is therefore a **license-capacity** monitor, not a license-expiration monitor — the script name is misleading. True expiration data lives in the partner-centre / billing APIs (`Get-MgDirectorySubscription` returns `nextLifecycleDateTime` which is the closest equivalent). Worth a renaming or a feature gap to track. Note for the modernization spec but not actionable in any cross-cutting phase.
- The four reports (status / detailed / usage / export) all re-fetch `Get-MgSubscribedSku -All` independently. A small caching layer (`$Script:CachedSkus` with a 5-minute TTL) would eliminate three round-trips per menu cycle. Low-priority perf optimisation; not worth doing until the C6 extraction in F3 happens.
- The `Send-EmailAlert` / `Send-TeamsAlert` HTML body uses inline styles for everything (CSS `style` block at lines 730–740, 900–911, 1115–1132) — defensible because some email clients strip those blocks. No change recommended.
- The `Install-SouliTEKModule` calls on lines 149–156 will install the Graph modules at first run — this is correct usage of the centralized helper from `SouliTEK-Common.ps1` and is the same pattern as the other Graph-using scripts. No change needed here; the cross-cutting consolidation work is in F3 candidate #4 (`Connect-SouliTEKMgGraph` extraction).
