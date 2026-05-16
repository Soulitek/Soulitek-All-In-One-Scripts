# Audit — scripts/wifi_password_viewer.ps1

## Inventory
| Item | Value |
|---|---|
| Path           | scripts/wifi_password_viewer.ps1 |
| LOC            | 649 |
| Functions      | 11 |
| `#Requires`    | none |
| Admin-required | yes (gated at runtime via `Test-SouliTEKAdministrator` on line 598; `netsh wlan show profile name="X" key=clear` returns blank key material under a non-elevated token) |
| Last touched   | 8675720 — 2026-04-17 |
| Modernization grade | B |

## Summary

A menu-driven WiFi-credential viewer/exporter: enumerates saved WLAN profiles via `netsh wlan show profiles`, extracts cleartext keys via `netsh wlan show profile name="X" key=clear`, and offers six menu actions (view-all, current-only, search-by-name, TXT export, CSV export, clipboard copy) plus a help screen. Already well-migrated to the `Write-Ui` / `Show-Section` / `Show-ScriptBanner` API — that's why this scores B and not D. The dominant remaining issue is raw `Write-Host` (110 occurrences) used almost exclusively for visual scaffolding: bare `Write-Host ""` spacer calls (~65) and `Write-Host "===...==="` / `Write-Host "----..."` separator banners (~45) with hard-coded `-ForegroundColor`. Per C1's "visual separator helpers" exception, the spacers themselves are not violations, but the colored ASCII bar lines are pre-`Show-Section`-era manual decorations and should collapse to repeated `Show-Section` / a new `Show-Separator` helper. Secondary concerns: zero `-ErrorAction SilentlyContinue` (clean — see F2), the script shells out to `netsh wlan` (F3 — C14 says **keep**, no PowerShell-native equivalent exists), and the legal-disclaimer block at the top (lines 25–36) is a deliberate C11 exception (F4) and must stay. Local issues: the `foreach ($profile in $profiles)` loops at lines 121, 283, 360 shadow PowerShell's automatic `$profile` variable (F5 — rename to `$profileName`); the `Copy-PasswordToClipboard` self-recursive `Invalid selection` branch (line 447) is a small DoS-by-typo (F6); the `netsh ... 2>&1` + `$LASTEXITCODE` test on line 213/215 is brittle because `netsh` writes its "profile not found" error to stdout with exit 0 in some Windows builds (F7); and the script lacks `#Requires -RunAsAdministrator` despite functionally requiring elevation (F8). Recommended phase entry order: P1 (C1 separator-bar sweep), then P4 (F5 + F6 + F8 cleanup).

## Findings

### F1 — Raw `Write-Host` for separator bars and spacing (see C1)
- **Severity:** med
- **Category:** output-style
- **Location:** scripts/wifi_password_viewer.ps1 — 110 raw `Write-Host` occurrences. Two distinct sub-patterns:
  1. **Bare spacers** (`Write-Host ""`) — ~65 calls: lines 99, 106, 108, 114, 136, 139, 143, 152, 158, 163, 165, 180, 190, 199, 211, 217, 222, 238, 249, 256, 264, 317, 319, 322, 328, 339, 346, 354, 390, 392, 395, 400, 406, 417, 419, 425, 434, 453, 455, 462, 466, 469, 479, 490, 493, 498, 503, 508, 513, 518, 523, 527, 530, 533, 536, 539, 543, 548, 552, 555, 558, 561, 564, 566, 575, 584, 601, 604, 606.
  2. **Colored ASCII separator bars** (`Write-Host "====...====" -ForegroundColor X` / `Write-Host "----...----" -ForegroundColor Gray`) — ~45 calls: lines 123, 125, 170, 172, 175, 177, 182, 227, 229, 232, 234, 246, 248, 261, 263, 314, 316, 336, 338, 351, 353, 387, 389, 414, 416, 435, 463, 465, 474, 476, 487, 489, 492, 524, 526, 540, 542, 549, 551, 565, 585.
- **Reference:** [C1](00-cross-cutting.md#c1--raw-write-host-calls-not-migrated-to-write-uiwrite-status)
- **Current (representative — lines 246–248):**
  ```powershell
  Write-Host "========================================" -ForegroundColor Yellow
  Write-Ui -Message "   EXPORT ALL PASSWORDS TO FILE" -Level "WARN"
  Write-Host "========================================" -ForegroundColor Yellow
  ```
- **Recommended:**
  ```powershell
  Show-Section "EXPORT ALL PASSWORDS TO FILE"
  ```
- **Risk if changed:** Low. The script *already* uses `Show-Section` in three places (lines 105, 151, 198, 210) and `Show-ScriptBanner` everywhere else — converting the remaining seven `Write-Host "===" / Write-Ui TITLE / Write-Host "==="` triplets (in `Export-ToFile`, `Export-ToCSV`, `Copy-PasswordToClipboard`, `Show-Help`, and the success/error inner banners) to `Show-Section` is purely cosmetic and preserves message text verbatim.
- **Local notes:** The `Show-Section` helper (modules/SouliTEK-Common.ps1:284) already exists and matches this exact pattern. Per C1's "visual separator helpers" exception, the bare-spacer `Write-Host ""` calls (sub-pattern 1) are *not* violations — but if a `Write-Ui -Spacer` helper lands in P4, fold them in then for consistency. The colored `Write-Host "----...----" -ForegroundColor Gray` "thin rule" lines (123, 125, 182, 492, 526, 542, 551) under section titles are an unhandled sub-style — recommend adding a `Show-Subsection` / `Show-Rule` helper to the module in P4 rather than scattering custom `Write-Host` dashes.
- **Local notes (cont.) — success/failure inner banners:** The `Write-Host "==="-Green` + `Write-Ui "EXPORT SUCCESSFUL"-OK` + `Write-Host "==="-Green` triplets at lines 314–316, 387–389, 463–465 are essentially mini-banners announcing an outcome. These could collapse to a single `Write-Ui` with `-Level "OK"` (the level bracket already signals success) and drop the colored bars entirely; or, if the visual emphasis is wanted, add a `Show-Outcome -Level OK -Message "EXPORT SUCCESSFUL"` helper. Same pattern in red for the empty-list error branches (261–263, 351–353) and yellow for the open-network branches (170–172, 175–177, 227–229, 232–234, 463–465 [Green], 474–476 [Yellow]).
- **Target phase:** P1

### F2 — `-ErrorAction SilentlyContinue` triage (see C4)
- **Severity:** info
- **Category:** error-handling
- **Location:** scripts/wifi_password_viewer.ps1 — **0 occurrences**
- **Reference:** [C4](00-cross-cutting.md#c4----erroraction-silentlycontinue-swallowing-failures)
- **Local notes:** Clean — no `-ErrorAction SilentlyContinue` anywhere in the file. Note the script *does* swallow `netsh` failures implicitly: `Get-WiFiProfiles` (line 49) and `Get-WiFiPassword` (line 64) run `netsh` without capturing or checking `$LASTEXITCODE`, and `Search-Network` (line 213) uses `2>&1` to stream stderr into stdout before the `$LASTEXITCODE` check on line 215. The `2>&1` redirection there is the *only* error-handling primitive in the script and it's spelled out non-obviously — see F7 for the brittle `$LASTEXITCODE` check that follows.
- **Target phase:** —

### F3 — `netsh wlan` shell-out (see C14) — `// keep`
- **Severity:** info
- **Category:** legacy-api (note only — no change recommended)
- **Location:** scripts/wifi_password_viewer.ps1:50, 67, 82, 184, 213, 369 (6 occurrences)
- **Reference:** [C14](00-cross-cutting.md#c14--netsh-wlan-shelling-out)
- **Current:**
  ```powershell
  $output = netsh wlan show profiles                                     # line 50
  $output = netsh wlan show profile name="$ProfileName" key=clear        # line 67
  $output = netsh wlan show interfaces                                   # line 82
  $interfaceInfo = netsh wlan show interfaces | Select-String "..."     # line 184
  $result = netsh wlan show profile name="$searchName" 2>&1             # line 213
  $profileInfo = netsh wlan show profile name="$profile"                # line 369
  ```
- **Recommended:** **No change — `// keep`.** There is no PowerShell-native cmdlet that exposes the saved WLAN cleartext key. The `Win32_WiFi*` WMI classes do not expose `Key`/`KeyContent`. The Windows native WiFi API (`wlanapi.dll`'s `WlanGetProfile` with `WLAN_PROFILE_GET_PLAINTEXT_KEY`) would let this script avoid the parent-process spawn, but binding to it requires either `Add-Type -MemberDefinition` P/Invoke or a pre-compiled assembly — both significantly more complex than the current `netsh` regex parsing and not justified by the marginal hardening gain. `netsh wlan` is the pragmatic answer.
- **Risk if changed:** N/A — not recommended.
- **Local notes:** If a future hardening pass wants to remove the shell-out anyway, the lift is: declare a small `[DllImport]` block for `WlanOpenHandle` / `WlanGetProfileList` / `WlanGetProfile` (returns the profile XML, which contains `<keyMaterial>cleartext</keyMaterial>` when the second-to-last arg sets `WLAN_PROFILE_GET_PLAINTEXT_KEY = 4`), then `[xml]` the result. Same elevation requirement — the API enforces it the same way `netsh` does. **Defer indefinitely.**
- **Target phase:** —

### F4 — Legal-disclaimer block at top of file (see C11 exception)
- **Severity:** info
- **Category:** docs (note only — must remain)
- **Location:** scripts/wifi_password_viewer.ps1:25–36 (12 lines of `IMPORTANT DISCLAIMER` + `LEGAL NOTICE`)
- **Reference:** [C11](00-cross-cutting.md#c11--bannerdisclaimer-block-duplicated-at-top-of-every-script) (explicit exception clause)
- **Local notes:** Per C11's explicit carve-out — "The legal disclaimer for WiFi/Product-Key/USB-history-style scripts stays inline (those have legitimate legal-notice requirements)." — this block must remain. The `LEGAL NOTICE` section ("This tool should only be used on your own computer or with explicit permission... Unauthorized access to WiFi passwords may be illegal in your jurisdiction") is precisely the kind of jurisdictional warning that needs to be visible in the source file itself, not buried in a referenced `LICENSE`. **Do not collapse this block in the P4 banner cleanup.** The generic copyright/branding lines 1–23 *can* still collapse to the 3-line standard header in P4 — only lines 25–36 are protected. Likewise the runtime `Show-SouliTEKDisclaimer` invocation at line 625 must stay; if/when `Show-SouliTEKDisclaimer` is modified, ensure it still surfaces the WiFi-specific legal notice (or have this script call a variant `Show-SouliTEKDisclaimer -Topic "WiFi"`).
- **Target phase:** —

### F5 — `$profile` loop variable shadows PowerShell automatic variable
- **Severity:** med
- **Category:** correctness
- **Location:** scripts/wifi_password_viewer.ps1:121, 124, 127, 283, 286, 289, 360, 361, 369, 378 (10 occurrences across 3 functions)
- **Current:**
  ```powershell
  foreach ($profile in $profiles) {
      Write-Ui -Message "Network #${count}: $profile" -Level "STEP"
      $password = Get-WiFiPassword -ProfileName $profile
      ...
  }
  ```
- **Recommended:**
  ```powershell
  foreach ($profileName in $profiles) {
      Write-Ui -Message "Network #${count}: $profileName" -Level "STEP"
      $password = Get-WiFiPassword -ProfileName $profileName
      ...
  }
  ```
- **Risk if changed:** Low. `$profile` is a PowerShell automatic variable holding the path to the current user's PowerShell profile script (`$env:USERPROFILE\Documents\PowerShell\Microsoft.PowerShell_profile.ps1` or similar). Assigning to it inside a `foreach` loop is allowed and PS scopes the assignment to the loop, but the shadowing is a known footgun and PSScriptAnalyzer's `PSAvoidAssignmentToAutomaticVariable` flags it. PSSA flags this rule by default at warning severity — once C8 (CI + analyzer) lands, this will surface as a baseline error. Fix in P1 alongside C1 sweep, or fold into the analyzer-baseline cleanup in P0.
- **Target phase:** P1 (or P0 with the analyzer baseline)

### F6 — `Copy-PasswordToClipboard` self-recursion on invalid input (potential stack growth)
- **Severity:** low
- **Category:** correctness
- **Location:** scripts/wifi_password_viewer.ps1:444–449
- **Current:**
  ```powershell
  if ($index -lt 0 -or $index -ge $profiles.Count) {
      Write-Ui -Message "Invalid selection!" -Level "ERROR"
      Start-Sleep -Seconds 2
      Copy-PasswordToClipboard
      return
  }
  ```
- **Recommended:** Replace the self-recursive call with a `do { ... } while (-not $validSelection)` retry loop, or simply `return` to the main menu (the user can re-select option `[6]` themselves).
  ```powershell
  if ($index -lt 0 -or $index -ge $profiles.Count) {
      Write-Ui -Message "Invalid selection!" -Level "ERROR"
      Start-Sleep -Seconds 2
      return
  }
  ```
- **Risk if changed:** Low. A user who mistypes their selection 1,000 times in a row would grow the PS stack 1,000 frames deep; in practice this is not a realistic concern, but the recursion is unnecessary and the `return` after the recursive call is unreachable in the intended flow (because the recursed call eventually picks a valid index and returns, then the outer frame also returns having done nothing). A `return` is cleaner.
- **Local notes:** Also note the `Read-Host` on line 436 has no input validation other than the bounds check — a non-numeric input like `"abc"` will cause `[int]$selection` on line 442 to throw a `RuntimeException`, which propagates out of the function entirely (no `try`/`catch`), pops out of the `switch` statement on line 632, and either crashes the menu loop (if it bubbles past the switch's default) or — more likely — gets silently absorbed by the switch and the user lands back at the menu with no error. Recommend a `[int]::TryParse($selection, [ref]$index)` guard alongside the bounds check.
- **Target phase:** P4

### F7 — `$LASTEXITCODE` check on `netsh` output is unreliable
- **Severity:** low
- **Category:** correctness
- **Location:** scripts/wifi_password_viewer.ps1:213–219
- **Current:**
  ```powershell
  $result = netsh wlan show profile name="$searchName" 2>&1

  if ($LASTEXITCODE -ne 0) {
      Write-Ui -Message "Network `"$searchName`" not found" -Level "ERROR"
      ...
  ```
- **Recommended:** Match the captured `$result` against the actual "Profile ... is not found" string rather than relying on the exit code, or call `Get-WiFiProfiles` first and test set membership.
  ```powershell
  $profiles = Get-WiFiProfiles
  if ($searchName -notin $profiles) {
      Write-Ui -Message "Network `"$searchName`" not found" -Level "ERROR"
      ...
      return
  }
  ```
- **Risk if changed:** Low. `netsh wlan show profile name="<missing>"` returns exit code 1 on modern Windows 10/11 in normal cases, but on some locale-affected builds and inside certain Windows error paths the exit code is 0 with the failure message in stdout (`"Profile \"...\" is not found on interface \"...\""`). The set-membership check via `Get-WiFiProfiles` is locale-stable and avoids the second `netsh` invocation entirely — small perf win too.
- **Local notes:** Same concern (no `$LASTEXITCODE` check at all) applies to `Get-WiFiProfiles` (line 50), `Get-WiFiPassword` (line 67), `Get-CurrentNetwork` (line 82), and `Export-ToCSV`'s `$profileInfo = netsh ...` (line 369). If `netsh` fails (driver crash, WLAN AutoConfig service stopped), these functions silently return empty arrays / `$null`, which then cascade into "No saved WiFi networks found" or "Not connected" messages — misleading the operator about the actual failure mode. A small `try { netsh ... ; if ($LASTEXITCODE) { throw } } catch { Write-Ui -Message "WLAN service unavailable: $_" -Level "ERROR"; return @() }` pattern around each `netsh` invocation would fail-closed per CLAUDE.md.
- **Target phase:** P4

### F8 — Missing `#Requires -RunAsAdministrator` despite runtime admin check
- **Severity:** low
- **Category:** structure
- **Location:** scripts/wifi_password_viewer.ps1 — top of file (no `#Requires` line at all); runtime check at line 598
- **Current:** Script gates with `if (-not (Test-SouliTEKAdministrator)) { ... exit 1 }` at line 598, but has no `#Requires -RunAsAdministrator` declaration. A user double-clicking the script with a non-elevated token will see the script's friendly error and `Read-Host` prompt instead of the cleaner PS-engine refusal-to-load.
- **Recommended:** Add `#Requires -RunAsAdministrator` and `#Requires -Version 5.1` at the very top (above the banner block).
  ```powershell
  #Requires -Version 5.1
  #Requires -RunAsAdministrator

  # ============================================================
  # WiFi Password Viewer ...
  ```
- **Risk if changed:** Low. The runtime `Test-SouliTEKAdministrator` check at line 598 can stay (defensive in depth) or be removed once `#Requires` is added — they're redundant but harmless together. `#Requires` runs *before* parsing the rest of the file, so a non-elevated invocation fails fast with a clearer message. Note: `netsh wlan show profile ... key=clear` *can* run non-elevated, but it returns the profile XML *without* the `<keyMaterial>` element — so the script "works" without admin but always shows passwords as `[Open Network]`. The elevation requirement is a key-recovery requirement, not a `netsh`-invocation requirement.
- **Target phase:** P4

### F9 — Exported password files written to Desktop with no permissions / encryption
- **Severity:** med
- **Category:** security
- **Location:** scripts/wifi_password_viewer.ps1:253, 312, 343, 385
- **Current:**
  ```powershell
  $filePath = Join-Path -Path ([Environment]::GetFolderPath("Desktop")) -ChildPath $fileName
  ...
  $content | Out-File -FilePath $filePath -Encoding UTF8
  ...
  Start-Process $filePath
  ```
- **Local notes:** TXT and CSV exports drop cleartext WiFi credentials onto the user's Desktop with default ACLs (inheriting from `%USERPROFILE%\Desktop`, which on a domain-joined or shared machine may be readable by administrators and backup agents) and immediately `Start-Process` the file, opening Notepad/Excel — at which point the cleartext content may flow to the Windows clipboard, recent-files list, AutoRecover saves, and (if the user OneDrive-syncs their Desktop) into the cloud. The script's own embedded banner says "SECURITY WARNING: This file contains sensitive passwords. Keep it secure! Delete this file after use." (lines 305–307) — a good in-file warning, but it's reactive, not preventive. Possible mitigations (P4/P6 — none are clear wins, list for discussion):
  1. Prompt the user for an output directory rather than hardcoding Desktop (also fixes the SYSTEM-context-`USERPROFILE` issue noted in F7 of `driver_integrity_scan`).
  2. Apply restrictive ACLs after writing: `icacls $filePath /inheritance:r /grant:r "$env:USERNAME:F"` to remove inheritance and grant only the current user.
  3. Offer an "export to encrypted ZIP" option using `Compress-Archive` + a user-provided password (requires `7z.exe` or `Microsoft.PowerShell.Archive` doesn't support passwords natively — would need `System.IO.Compression` + a custom AES wrapper, which is a real lift).
  4. Don't auto-`Start-Process` the file (lines 325, 403); just print the path and let the user open it deliberately.
- **Risk if changed:** Low for option 4, medium for option 2 (ACL changes can be confusing), high for option 3 (custom crypto).
- **Target phase:** P6

### F10 — Infinite menu loop with blocking `Read-Host` / `ReadKey` (non-interactive hang)
- **Severity:** low
- **Category:** structure (UX / RMM safety)
- **Location:** scripts/wifi_password_viewer.ps1:629 (`while ($running)`), plus `$Host.UI.RawUI.ReadKey(...)` at lines 145, 192, 240, 330, 408, 481, 568 and `Read-Host` at lines 201, 436, 586, 607.
- **Local notes:** Same pattern as F6 of `driver_integrity_scan.ps1`. The script is interactive-only — under SYSTEM context (CLAUDE.md flags RMM deployment as a target scenario), every `Read-Host` and `ReadKey` will hang the worker. No `[Environment]::UserInteractive` gate. The graceful exit is menu option `[0]` (lines 640–643), which only fires interactively. If this script ever ends up in a non-interactive launcher path (or as an RMM payload), it will deadlock. Add an `[Environment]::UserInteractive` guard at the top of the main loop and exit immediately if false. Defer unless an actual RMM hang report comes in.
- **Target phase:** P4

## Out-of-scope notes
- The `Show-Header` function (line 96) is a four-line wrapper around `Clear-Host` + `Show-ScriptBanner` + `Write-Host ""`. Three callers (`Show-AllPasswords`, `Show-CurrentNetwork`, `Search-Network`, `Export-ToFile`, `Export-ToCSV`, `Copy-PasswordToClipboard`, `Show-Help`) — seven actually. Reasonable abstraction; no change needed.
- `Get-CurrentNetwork` (line 81) regex `^\s+SSID\s+:\s+(.+)$` will also match `BSSID` lines on some locales because the leading `\s+SSID` substring appears inside `BSSID` after a hex octet. Test: in `netsh wlan show interfaces`, the SSID line is `    SSID                   : MyNetwork` and the BSSID line is `    BSSID                  : aa:bb:cc:dd:ee:ff`. The anchor `^\s+SSID` matches the first because `^` + `\s+` + `SSID` doesn't match `    BSSID` (B is not whitespace). So this is actually safe — leave the regex as-is.
- The `netsh wlan show interfaces | Select-String "State|Signal|Authentication|Cipher"` filter on line 184 will also surface `Hosted network status` and similar lines on Windows builds that include them. Cosmetic only — the extra lines are still legitimate WLAN interface attributes worth surfacing. No change.
- `Set-Clipboard -Value $password` on line 461 puts the cleartext password onto the Windows clipboard with no auto-clear. Clipboard managers (Win+V history) will retain it indefinitely. Same security-posture concern as F9 but smaller scope; mitigation would be `Start-Job { Start-Sleep -Seconds 30; Set-Clipboard -Value '' }`. Note in passing — not raising as a finding.
- `Show-Disclaimer` (line 592) and `Show-ExitMessage` (line 616) are thin one-line wrappers around `Show-SouliTEKDisclaimer` and `Show-SouliTEKExitMessage`. They exist purely for naming continuity with the other scripts in the suite that defined these locally before the module helpers landed. Once C10 (`Import-SouliTEKCommon` boilerplate cleanup) is done in P4, drop these wrappers and call the module functions directly.
- The trailing blank line at the end of the file (line 650) is fine.
- The `$matches[1]` references at lines 55, 72, 87, 372 use the lowercase `$matches` form. PowerShell's automatic variable is canonically `$Matches` (PascalCase). Both forms work because PowerShell variable names are case-insensitive, but PSSA / style guides prefer the canonical form. Trivial cleanup during the C1 sweep.
- Banner block (lines 1–23) matches generic C11 cleanup; lines 25–36 are the protected legal-notice exception (see F4). Banner cleanup pass in P4 must split-the-difference: shrink lines 1–23 to the 3-line standard header, keep lines 25–36 verbatim.
