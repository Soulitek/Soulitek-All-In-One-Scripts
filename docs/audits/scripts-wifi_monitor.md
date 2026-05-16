# Audit — scripts/wifi_monitor.ps1

## Inventory
| Item | Value |
|---|---|
| Path           | scripts/wifi_monitor.ps1 |
| LOC            | 666 |
| Functions      | 11 |
| `#Requires`    | none |
| Admin-required | no (declared in source comment at line 643 — `# No admin required for this tool`; `netsh wlan show interfaces` and the `Microsoft-Windows-WLAN-AutoConfig/Operational` event-log read both work for a standard user, the latter because the WLAN-AutoConfig channel is readable by `BUILTIN\Users` by default) |
| Last touched   | 8675720 — 2026-04-17 |
| Modernization grade | B |

## Summary

A menu-driven read-only WiFi diagnostics tool: parses `netsh wlan show interfaces` output for the current connection's SSID/signal/RSSI/channel/band/authentication, reads `Microsoft-Windows-WLAN-AutoConfig/Operational` event IDs 8001/8003 for the last 30 days of connect/disconnect history (falling back to the `System` log with `Microsoft-Windows-WLAN-AutoConfig` and `e1cexpress` providers when the primary channel is empty), and exports a multi-format TXT/CSV/HTML report to Desktop via `Export-SouliTEKReport`. No `Get-WmiObject` (C3 N/A), no `Write-SouliTEK*` legacy-API callers (C2 dead in this file), and **`netsh wlan show interfaces` is the canonical and recommended approach** — there is no PS-native WLAN-interface cmdlet and C14 explicitly notes this should stay (`# keep` flag below at F3). The dominant remaining issue is **C1 (Write-Host)**: 86 calls breaking down into 39 bare `Write-Host ""` spacer calls, 17 `===…===` and 10 `---…---` banner/rule lines (per C1's "visual separator helpers" exception these are not true violations but cleanup candidates), and ~20 true content-bearing inline-color violations dominated by a single recurring pattern: `Write-Host "Label: " -NoNewline -ForegroundColor White` followed by either another colored `Write-Host` or a `Write-Ui` value emit (15 `-NoNewline` pairs at lines 283, 293, 297, 306, 316, 324, 328, 332, 336, 340, 376, 389-390, 410, 453). The `Write-Ui` API is already broadly adopted (~60 call sites) with **zero inline-marker double-marking** (the F2 anti-pattern from `01-modules-SouliTEK-Common.md` is absent here — `Select-String -Pattern 'Write-Ui.*\[(\+|-|!|\*)\]'` returns 0). **C4** is clean — 3 occurrences, all tag-A (event-log probe + 2 enumeration filters). The `Get-WinEvent -ListLog` probe-then-`-FilterHashtable`-query idiom on lines 191-204 is **shared verbatim** with `scripts/startup_boot_analyzer.ps1:268-280` and `scripts/usb_device_log.ps1:266-282` — F4 below references this 3-script duplication for the future `Get-SouliTEKEventLogEvents` module helper proposed in `scripts-startup_boot_analyzer.md` F4. Other locals: `Split-Path -Parent $PSScriptRoot` idiom on line 34 (same as F5 of driver_integrity_scan), no `[CmdletBinding()]` anywhere, an interactive `while ($running)` main loop with blocking `Read-Host` and `ReadKey` prompts that will deadlock under SYSTEM/RMM, and a hard-coded Desktop output path. No `Get-WmiObject` (C3 N/A), no `Write-SouliTEK*` callers (C2 dead). Of the script's three "data-acquisition" functions — `Get-CurrentWiFiInfo` (lines 99-182, parsing `netsh` output regex-by-regex), `Get-FrequencyBand` / `Convert-RSSIToPercentage` (lines 63-96, pure-math helpers), and `Get-WiFiDisconnectionHistory` (lines 185-263, event-log query) — the **C14 `netsh` dependency in `Get-CurrentWiFiInfo` is by-design and should not be replaced** (flagged with `# keep` in F3). The signal-strength polling loop predicted in the task plan as a C13 candidate **does not exist in the current source** — there is no `Start-Sleep`/`while`-based polling for live signal updates; the script captures the current connection once per menu-action and exits to the menu. C13 is therefore N/A for this script in its current form; if a "live monitor with refresh interval" feature is added in the future it would become a candidate. Recommended phase entry order: P1 (C1 — narrow scope, ~20 true content violations + spacer/banner consolidation deferred), then P2 (C4 triage — all 3 tag-A, trivial), then P4 (F4 event-log probe helper extraction).

## Findings

### F1 — Raw `Write-Host` (see C1)
- **Severity:** med
- **Category:** output-style
- **Location:** scripts/wifi_monitor.ps1 — 86 raw `Write-Host` occurrences (matches task plan prediction exactly). Zero legacy `Write-SouliTEK*` callers (C2 dead in this file). `Write-Ui` is already adopted with ~60 call sites and zero inline-marker double-marking.
- **Reference:** [C1](00-cross-cutting.md#c1--raw-write-host-calls-not-migrated-to-write-uiwrite-status)
- **Current (representative pattern — "label-prefix + Write-Ui value" pair at lines 297-298 in `Show-CurrentWiFiStatus`):**
  ```powershell
  Write-Host "RSSI: " -NoNewline -ForegroundColor White
  Write-Ui -Message "$($wifiInfo.RSSI) dBm" -Level "INFO"
  ```
- **Recommended:**
  ```powershell
  Write-Ui -Message "RSSI: $($wifiInfo.RSSI) dBm" -Level "INFO"
  ```
- **Risk if changed:** Low — text preserved verbatim; the line collapses from two emit calls (one without `[INFO]` bracket, one with) into a single `[INFO]`-prefixed line. Operator transcripts gain consistency. Same migration shape as F1-pattern-3 of `scripts-startup_boot_analyzer.md`.
- **Local notes:** Four categories of raw `Write-Host`, each with a different migration strategy:
  1. **Blank-line spacer calls** — bare `Write-Host ""` used as vertical spacing. **39 occurrences** (lines 55, 57, 59, 271, 277, 285, 300, 319, 345, 356, 359, 365, 373, 378, 399, 416, 427, 437, 457, 476, 487, 493, 532, 534, 566, 568, 579, 582, 586, 590, 594, 598, 602, 606, 610, 613, 615, 624, 631). Per C1 "visual separator helpers" exception, these are not true violations but cleanup candidates — migrate to a `Show-Section -Spacer` helper if one lands in P4.
  2. **Banner rule lines** — `Write-Host "===…===" -ForegroundColor Cyan/Green/Yellow/Magenta/Gray` framing block headers. **17 occurrences** (lines 58, 268, 270, 353, 355, 400, 424, 426, 436, 484, 486, 576, 578, 599, 607, 614, 632). Plus 10 `Write-Host "---…---" -ForegroundColor Gray` thin-rule lines (282, 288, 303, 322, 381, 402, 459, 581, 601, 609). Per C1 "visual separator helpers" exception, also not true violations — consolidate behind a `Show-Section -Title "CURRENT WiFi CONNECTION STATUS"` helper added in P4.
  3. **Label-prefix + value pairs — true C1 violations (dominant pattern)** — **15 occurrences**. Full list of `Write-Host "Label: " -NoNewline -ForegroundColor White` (or `Cyan`, or `Gray`) calls immediately followed by either another colored `Write-Host` value or a `Write-Ui` value:
     - Lines 283-284 (`SSID: ` + `Write-Ui $wifiInfo.SSID -Level OK`)
     - Lines 293-294 (`Signal: ` + `Write-Host "$($wifiInfo.SignalPercentage)%" -ForegroundColor $signalColor`)
     - Lines 297-298 (`RSSI: ` + `Write-Ui "$($wifiInfo.RSSI) dBm" -Level INFO`)
     - Lines 306-307 (`Band: ` + `Write-Host $wifiInfo.FrequencyBand -ForegroundColor $bandColor`)
     - Lines 316-317 (`Channel: ` + `Write-Ui $wifiInfo.Channel -Level INFO`)
     - Lines 324-325 (`State: ` + `Write-Host $wifiInfo.State -ForegroundColor …`)
     - Lines 328-329 (`Authentication: ` + `Write-Ui $wifiInfo.Authentication -Level INFO`)
     - Lines 332-333 (`Cipher: ` + `Write-Ui $wifiInfo.Cipher -Level INFO`)
     - Lines 336-337 (`Connection Mode: ` + `Write-Ui $wifiInfo.ConnectionMode -Level INFO`)
     - Lines 340-341 (`Radio Type: ` + `Write-Ui $wifiInfo.RadioType -Level INFO`)
     - Lines 376-377 (`Total Disconnections: ` + `Write-Host $disconnectCount -ForegroundColor …`)
     - Lines 389-390 (`[$timeStr] ` + `Write-Host $event.Type -NoNewline -ForegroundColor $typeColor`)
     - Lines 410-411 (`  $($group.Name): ` + `Write-Ui "$($group.Count) times" -Level WARN`)
     - Lines 453-454 (`$($detail.Label): ` + `Write-Host $detail.Value -ForegroundColor $detail.Color`)
     Migration shown in the Current/Recommended block above — collapse to a single `Write-Ui -Message "$label$value" -Level "$level"` per pair. For threshold-colored values (Signal %, total disconnects, State) the migration is `$level = if ($signalPct -ge 70) { 'OK' } elseif ($signalPct -ge 40) { 'WARN' } else { 'ERROR' }; Write-Ui -Message "Signal: $signalPct%" -Level $level` — same threshold-to-level mapping pattern as F1 of `scripts-startup_boot_analyzer.md`. Net reduction: ~30 LOC.
  4. **Content-bearing inline-color "loose" calls — true C1 violations** — small set: line 294 (`Write-Host "$($wifiInfo.SignalPercentage)%" -ForegroundColor $signalColor` — already covered by pair on line 293), 307 (`Band` value already covered by pair on 306), 325 (`State` value), 377 (`disconnectCount` value), 390 (event type), 454 (detail value). All 6 fold into the migration of their respective pairs above.
- **Local notes (cont.) — no inline-marker double-marking:** Verified — `Select-String -Pattern 'Write-Ui.*\[(\+|-|!|\*)\]'` returns 0 matches in this file. One bullet-point character `•` appears in `Write-Ui` messages on lines 461, 468, 603, 604, 605, 611, 612 — these are decorative bullets in narrative help text, not status markers, and should stay as-is.
- **Target phase:** P1 (the ~15 label-prefix pairs in category 3); P4 (consolidating the ~66 spacer/banner/rule calls behind a new `Show-Section` helper).

### F2 — `-ErrorAction SilentlyContinue` triage (see C4)
- **Severity:** med
- **Category:** error-handling
- **Files affected:** scripts/wifi_monitor.ps1 — 3 occurrences (matches task plan prediction exactly)
- **Reference:** [C4](00-cross-cutting.md#c4----erroraction-silentlycontinue-swallowing-failures)
- **Triage:**
  - Line 194: tag **A** — `Get-WinEvent -ListLog "Microsoft-Windows-WLAN-AutoConfig/Operational" -ErrorAction SilentlyContinue` inside `Get-WiFiDisconnectionHistory`. This is the canonical "does this event log exist?" probe; the result is immediately tested with `if ($logExists)` and the function falls through to the System-log fallback on miss. Legitimate. Add `# safe: probe` comment in P2. **Cross-script note:** identical idiom in `scripts/startup_boot_analyzer.ps1:270` and `scripts/usb_device_log.ps1:270` — see F4.
  - Line 204: tag **A** — `Get-WinEvent -FilterHashtable $filterHash -MaxEvents 1000 -ErrorAction SilentlyContinue` inside the same function, after the line-194 probe confirmed the log exists. The outer `try { … } catch { Write-Ui -Message "Error getting disconnection history: $_" -Level "WARN" }` on lines 191/259-262 already catches real failures; `SilentlyContinue` here lets the call drop to an empty result if the log was disabled between the probe and the query, with the `if ($events)` check on line 206 gating further processing. Legitimate. Add `# safe: enumeration filter` comment.
  - Line 235: tag **A** — `Get-WinEvent -FilterHashtable $systemLogFilter -MaxEvents 500 -ErrorAction SilentlyContinue` for the System-log fallback path (when the primary WLAN-AutoConfig log returned no events). The `$systemLogFilter.ProviderName` array includes `"e1cexpress"` (Intel Centrino driver) which is not present on every machine — `SilentlyContinue` correctly handles the "provider not registered" `0x80020009` exception. The `if ($systemEvents)` check on line 237 gates further processing. Legitimate. Add `# safe: enumeration filter (optional provider)` comment.
- **Local notes:** All 3 occurrences are tag-A — a clean C4 profile, matching `scripts-startup_boot_analyzer.md` F2 (all tag-A). No tag-B or tag-C work required. The script-level error-handling discipline in this file is good — both `Get-CurrentWiFiInfo` (lines 178-181) and `Get-WiFiDisconnectionHistory` (lines 259-262) have outer `try { … } catch { Write-Ui … -Level "ERROR/WARN" }` blocks that surface failures to the operator.
- **Target phase:** P2

### F3 — `netsh wlan show interfaces` — keep (see C14)
- **Severity:** info (note only — **no change recommended**)
- **Category:** legacy-api
- **Location:** scripts/wifi_monitor.ps1:101 (`$output = netsh wlan show interfaces 2>&1`)
- **Reference:** [C14](00-cross-cutting.md#c14--netsh-wlan-shelling-out)
- **Current:**
  ```powershell
  $output = netsh wlan show interfaces 2>&1

  if ($LASTEXITCODE -ne 0) {
      return $null
  }
  ```
- **Recommended:** **No change. `# keep`** — `netsh wlan show interfaces` is the canonical Windows way to retrieve the live WLAN interface state (SSID, RSSI/signal %, BSSID, channel, authentication, cipher, radio type). There is no PowerShell-native cmdlet that exposes this data — the `MSFT_NetWlanProfile` CIM class only exposes saved profile metadata, not the live-connection telemetry. `netsh` remains the pragmatic answer here, exactly as flagged in C14 alongside `wifi_password_viewer.ps1`. The output-parsing approach in lines 121-148 (10 regex-match cases against the localized `netsh` text) is the documented pattern for this API.
- **Local notes:** Two minor hardening notes that **do not** rise to a finding to fix:
  1. The regex parsing assumes English locale (`SSID`, `Signal`, `Radio type`, `Channel`, `State`, `Authentication`, `Cipher`, `Connection mode`). `netsh wlan show interfaces` output is localized — on a machine with `Get-WinSystemLocale` returning e.g. `he-IL` or `de-DE`, the labels change and the parser silently returns an empty `$wifiInfo`. `netsh wlan show interfaces /?` does not expose a `--xml` or `--json` flag (unlike `netsh interface ip`). Alternative: invoke via `cmd /c "chcp 437 >nul & netsh wlan show interfaces"` to force English code page — but this is fragile and out of scope. Document as a known limitation in the script's header comment in P4 if convenient; not a fix.
  2. The `2>&1` stream merge captures stderr but `$LASTEXITCODE -ne 0` is the only check — the merged stderr is not inspected for error text. Acceptable because `netsh wlan show interfaces` exits non-zero on real failures (no WLAN service, no adapter) and zero on success or "not connected." The downstream `if (-not $wifiInfo -or -not $wifiInfo.SSID)` gate at line 275 handles the "exited 0 but no SSID parsed" case correctly.
- **Risk if changed:** N/A (no change recommended).
- **Target phase:** — (`# keep` per C14)

### F4 — `Get-WinEvent -ListLog` probe-then-query idiom duplicated across 3 scripts
- **Severity:** low
- **Category:** structure (DRY)
- **Location:**
  - scripts/wifi_monitor.ps1:191-204 (inside `Get-WiFiDisconnectionHistory`)
  - scripts/startup_boot_analyzer.ps1:268-280 (inside `Get-BootPerformanceFromEventLog`)
  - scripts/usb_device_log.ps1:266-282 (inside `logQueries` foreach loop)
- **Reference:** Local finding (not a C-finding) — also referenced from `scripts-startup_boot_analyzer.md` F4.
- **Current (verbatim from wifi_monitor.ps1:191-204):**
  ```powershell
  try {
      # Try Microsoft-Windows-WLAN-AutoConfig/Operational log first
      $logName = "Microsoft-Windows-WLAN-AutoConfig/Operational"
      $logExists = Get-WinEvent -ListLog $logName -ErrorAction SilentlyContinue

      if ($logExists) {
          # Event ID 8001 = Disconnected, 8003 = Connected
          $filterHash = @{
              LogName = $logName
              ID = @(8001, 8003)
              StartTime = $startTime
          }

          $events = Get-WinEvent -FilterHashtable $filterHash -MaxEvents 1000 -ErrorAction SilentlyContinue
  ```
- **Local notes — Same shape in 3 scripts:**
  - `startup_boot_analyzer.ps1:268-280` — `$logExists = Get-WinEvent -ListLog "Microsoft-Windows-Diagnostics-Performance/Operational" -ErrorAction SilentlyContinue; if (-not $logExists -or -not $logExists.IsEnabled) { return $null }; $events = Get-WinEvent -LogName … -MaxEvents 100 -ErrorAction SilentlyContinue | Where-Object { $_.Id -eq 100 }`
  - `usb_device_log.ps1:266-282` — `$logExists = Get-WinEvent -ListLog $logName -ErrorAction SilentlyContinue; if (-not $logExists) { Write-Verbose …; continue }; $logEvents = Get-WinEvent -FilterHashtable $filterHash -MaxEvents 500 -ErrorAction SilentlyContinue`
- **Recommended:** Extract a `Get-SouliTEKEventLogEvents -LogName $name -FilterHashtable $hash -MaxEvents $n` helper in the module (same proposal as F4 of `scripts-startup_boot_analyzer.md` — see that file for the full helper skeleton). The wifi_monitor.ps1 caller becomes:
  ```powershell
  $events = Get-SouliTEKEventLogEvents -LogName "Microsoft-Windows-WLAN-AutoConfig/Operational" `
                                       -FilterHashtable @{ ID = @(8001, 8003); StartTime = $startTime } `
                                       -MaxEvents 1000
  if ($events) { foreach ($event in $events) { … } }
  ```
- **Risk if changed:** Low — pure structural extract. The three callers each reduce by ~10-15 LOC and the probe-then-query semantics are preserved exactly. Note that `wifi_monitor.ps1` does **not** test `$logExists.IsEnabled` (only `if ($logExists)`) while `startup_boot_analyzer.ps1` does — the proposed helper would test `IsEnabled` and return `@()` for disabled-but-present logs, which is a stricter semantics than wifi_monitor currently uses. The behavior delta: if the WLAN-AutoConfig log exists but was disabled by a group policy or audit-config tweak, the current wifi_monitor would still try `Get-WinEvent -FilterHashtable` against it (which would throw `0x80073BBD` "The event channel is disabled" and `SilentlyContinue` would swallow it back to empty); under the helper, the disabled log would be detected earlier and the fallback to System-log lines 228-252 would trigger. **Net effect: same or better** — the fallback path is more likely to surface useful events than a thrown-and-swallowed primary query.
- **Target phase:** P4

### F5 — No `[CmdletBinding()]` on script or any function
- **Severity:** low
- **Category:** structure
- **Location:** scripts/wifi_monitor.ps1 — script-level (no `param()` block at all, top of file is just the C11 banner and the C10 module-import boilerplate) and every one of the 11 internal functions (lines 50, 63, 82, 99, 185, 266, 351, 422, 482, 574, 621).
- **Local notes:** Same pattern as F4 of `scripts-driver_integrity_scan.md` and F9 of `scripts-startup_boot_analyzer.md`. The script is fully interactive (no `param()` block, no CLI surface), so this is low-severity, but adding `[CmdletBinding()]` to `Convert-RSSIToPercentage` (`param([int]$RSSI)`), `Get-FrequencyBand` (`param([int]$Channel)`), and `Get-WiFiDisconnectionHistory` (`param([int]$Days = 30)`) would let those pure-function helpers accept `-Verbose` and `-ErrorAction` from callers. The natural P4 follow-up is a top-level `[CmdletBinding()]` + `param([switch]$NonInteractive, [switch]$ExportReport, [string]$OutputPath)` skeleton, pairing with F6 below.
- **Target phase:** P4

### F6 — Infinite menu loop with `Read-Host` and `ReadKey` blocks under SYSTEM context
- **Severity:** low
- **Category:** structure (UX / RMM safety)
- **Location:** scripts/wifi_monitor.ps1:647 (`while ($running) { $choice = Show-MainMenu; switch ($choice) { … } }`), plus blocking prompts at lines 347, 418, 478, 536, 570, 617 (six `ReadKey "NoEcho,IncludeKeyDown"` "press any key" pauses) and the `Read-Host "Enter your choice (0-5)"` on line 633.
- **Local notes:** Same RMM-deadlock concern as F6 of `scripts-driver_integrity_scan.md` and F7 of `scripts-startup_boot_analyzer.md`. The only graceful exit is menu option `[0]` which sets `$running = $false` (line 658) after calling `Show-SouliTEKExitMessage`. Unlike the other two scripts there is **no `Start-Sleep` outside the `default` menu branch** (line 662 only) — so the script is not gratuitously slow when interactive, just deadlock-prone when not. Under SYSTEM-context RMM execution this will hang on the first `Read-Host` on line 633. Defer to P4 unless an actual RMM hang report comes in; pairs with the `Wait-SouliTEKKeyPress` F10 of `01-modules-SouliTEK-Common.md` and the C5 `[CmdletBinding(SupportsShouldProcess)]` work — adding `[CmdletBinding()]` + `param([switch]$NonInteractive, [switch]$ExportReport)` at the top of the script would make it invocable from the launcher in a "report-only, no menu" flow that just runs `Export-WiFiReport` and exits.
- **Target phase:** P4

### F7 — Hard-coded Desktop output path with no override
- **Severity:** info
- **Category:** structure
- **Location:** scripts/wifi_monitor.ps1:541 (`$desktopPath = [Environment]::GetFolderPath("Desktop")`) and 561 (`$outputPath = Join-Path $desktopPath "WiFi_Monitor_Report_$timestamp.$extension"`).
- **Local notes:** Like F7 of `scripts-driver_integrity_scan.md` and F10 of `scripts-startup_boot_analyzer.md`. Hard-coded to the current user's Desktop folder; breaks under SYSTEM context where `[Environment]::GetFolderPath("Desktop")` returns `C:\Windows\system32\config\systemprofile\Desktop` (which may not be writable in restricted-token scenarios) and offers no override. Low priority because the menu-driven design assumes interactive use. A `-OutputDirectory` parameter on `Export-WiFiReport` (folding into F5's `[CmdletBinding()]` add) would be a clean follow-up.
- **Target phase:** P4

### F8 — `Split-Path -Parent $PSScriptRoot` C10 boilerplate
- **Severity:** low
- **Category:** structure
- **Location:** scripts/wifi_monitor.ps1:34 (`$CommonPath = Join-Path (Split-Path -Parent $PSScriptRoot) "modules\SouliTEK-Common.ps1"`).
- **Local notes:** This is the canonical C10 import block — already uses `$PSScriptRoot` (the modern idiom, not the older `$MyInvocation.MyCommand.Path` that F5 of `scripts-driver_integrity_scan.md` calls out). The boilerplate is correctly written; it just exists once per script instead of being collapsed into the `Import-SouliTEKCommon` helper that C10 proposes. Folds into the C10 P4 sweep.
- **Target phase:** P4 (with C10)

### F9 — Banner duplication: `Show-Header` reimplements much of `Show-ScriptBanner`
- **Severity:** info
- **Category:** structure
- **Location:** scripts/wifi_monitor.ps1:50-60 (`function Show-Header { Show-SouliTEKHeader …; Write-Ui …; Write-Ui …; … }`) and line 640 (`Show-ScriptBanner -ScriptName "WiFi Monitor" -Purpose "…"`).
- **Local notes:** The script defines a local `Show-Header` that calls `Show-SouliTEKHeader` and then emits 5 lines of credits/copyright. It also calls `Show-ScriptBanner` exactly once at line 640 (the canonical C10 module helper used by `startup_boot_analyzer.ps1` as well — see that file's out-of-scope note about `Show-ScriptBanner`). The local `Show-Header` is then re-invoked from each of the 6 "show…" functions (`Show-CurrentWiFiStatus`, `Show-DisconnectionHistory`, `Show-DetailedWiFiInfo`, `Export-WiFiReport`, `Show-Help`, `Show-MainMenu`) to repaint the screen on every menu return. The double-implementation is a minor cosmetic issue — `Show-Header` could be replaced with a single `Show-SouliTEKHeader -Title "WIFI MONITOR" -ClearHost -ShowBanner` call from each consumer, dropping the local function entirely and saving 11 LOC. Folds into the C10/C11 P4 sweep.
- **Target phase:** P4

### F10 — `$Script:WiFiData` and `$Script:DisconnectionHistory` are declared but never used
- **Severity:** info
- **Category:** dead code
- **Location:** scripts/wifi_monitor.ps1:46-47 (`$Script:WiFiData = @(); $Script:DisconnectionHistory = @()`).
- **Local notes:** Both script-scoped arrays are initialized at line 46-47 but **never read or written anywhere else in the file** (verified — `Select-String -Pattern '\$Script:(WiFiData|DisconnectionHistory)'` returns only the two declarations). Dead variables, likely from an earlier draft that intended to cache scan results across menu actions (the pattern `scripts-startup_boot_analyzer.md` F6 calls out for `$Global:AllStartupItems`). Current behavior: each menu action re-runs `Get-CurrentWiFiInfo` and `Get-WiFiDisconnectionHistory` from scratch — which is fine for `netsh wlan` (fast, <100 ms) but a 30-day event-log query in `Get-WiFiDisconnectionHistory` (which fetches up to 1000 events) is re-run from scratch each time the user selects menu `[2]` or `[4]`. Either (a) wire `$Script:DisconnectionHistory` up as a cache (5-10 LOC change), or (b) delete the unused declarations (2 LOC saved). Cosmetic; no behavior impact today.
- **Target phase:** P4

### F11 — Trailing blank line at EOF
- **Severity:** info
- **Category:** docs
- **Location:** scripts/wifi_monitor.ps1:666 (1 trailing blank line after the closing `}` of the `while ($running)` loop on line 665).
- **Local notes:** Cosmetic. Trim in any pass that touches the file. Same kind of cleanup as F12 of `scripts-startup_boot_analyzer.md`.
- **Target phase:** —

## Out-of-scope notes
- Banner block (lines 1-31, 31 lines of `# === / Coded by / IMPORTANT DISCLAIMER`) matches C11 cross-cutting cleanup; covered there. Note that the disclaimer in this file is the standard "AS IS warranty" boilerplate, **not** a WiFi-specific legal notice — `wifi_password_viewer.ps1` (which reveals saved WLAN keys) has a legitimate per-script legal notice that should stay, but `wifi_monitor.ps1` is read-only telemetry and can use the standard C11-collapsed 3-line header.
- The `Convert-RSSIToPercentage` (lines 63-79) and `Get-FrequencyBand` (lines 82-96) functions are clean, pure, side-effect-free math/lookup helpers. The RSSI→% conversion uses the standard linear formula `((RSSI + 100) / 70) * 100` clamped to `[0, 100]` — correct for the typical -100 dBm to -30 dBm RSSI range. The channel→band lookup correctly handles the 1-14 / 36+ boundary. Both are good candidates for extraction into a future `modules/SouliTEK-Wifi.psm1` if a second WLAN tool is ever written.
- The `Get-CurrentWiFiInfo` regex-parsing approach (lines 121-148) handles the 10 most important `netsh wlan show interfaces` output fields. The regex patterns correctly account for leading-whitespace variation (`^\s+SSID\s+:`) and the two known signal-formatting variants (`(\d+)%` vs `(\d+)\s+%` on lines 125-130). The "no Channel parsed, fall back to Radio type regex match" fallback on lines 166-174 is a thoughtful belt-and-braces approach for older drivers that report `802.11n 2.4GHz` without an explicit `Channel` line.
- The disconnection-history dual-log strategy (lines 191-252: try `Microsoft-Windows-WLAN-AutoConfig/Operational` first, fall back to `System` log filtered by provider names) is the right design — the Operational log is the modern Windows 10+ source, but on older or stripped Windows images the channel may be disabled and the System-log provider-filter is the canonical fallback.
- The `Export-WiFiReport` function uses the shared `Export-SouliTEKReport -Format $fmt` API (line 563) and correctly iterates over `@("TXT", "CSV", "HTML")` to produce all three formats in one run. The `-OpenAfterExport:($formats.Count -eq 1)` argument is a no-op here (always `$false` because the loop always emits 3) but the conditional is correct — would auto-open if a single-format export was ever added.
- The C14 `netsh wlan show interfaces` dependency (F3) is the script's single legacy-API tie-point and is explicitly **out of scope per cross-cutting C14** (`# keep` recommendation, no PS-native cmdlet exists for live WLAN interface state).
- The signal-strength polling loop predicted in the task plan as a C13 candidate **does not exist in this script's current source**. There is no `Start-Sleep`/`while`-based "live monitor" loop — the script captures the current connection once per menu-action invocation and returns to the menu. If a "live monitor mode with refresh interval" feature is added later it would become a candidate for C13's `Invoke-SouliTEKParallel` (though for single-WLAN-interface polling, a simple `Start-Sleep` loop is probably correct — parallelism only helps if multiple WLAN adapters are being polled).
- Two of the four "legacy API axes" come up clean: zero `Get-WmiObject` (C3 N/A) and zero `Write-SouliTEK*` callers (C2 dead). The **B** grade is driven by the C1 inline-color-pair pattern (15 true content violations) and the C10/C11 boilerplate; once F1 lands in P1 and the C10/C11/F8/F9 cleanup runs in P4, this script becomes an **A-grade** candidate.
