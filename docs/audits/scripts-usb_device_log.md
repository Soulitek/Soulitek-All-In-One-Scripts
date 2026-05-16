# Audit — scripts/usb_device_log.ps1

## Inventory
| Item | Value |
|---|---|
| Path           | scripts/usb_device_log.ps1 |
| LOC            | 1012 |
| Functions      | 13 |
| `#Requires`    | `#Requires -Version 5.1` (no `-RunAsAdministrator` directive despite the script self-checking via `Test-SouliTEKAdministrator` on line 371 and warning when missing) |
| Admin-required | yes (effectively — reads `HKLM:\SYSTEM\CurrentControlSet\Enum\USBSTOR` and `HKLM:\SYSTEM\CurrentControlSet\Enum\USB` via `Get-ChildItem -Recurse`, queries `Microsoft-Windows-DriverFrameworks-UserMode/Operational` event log, and reads `%SystemRoot%\inf\setupapi.dev.log` — all three require elevation for full coverage; script self-checks but doesn't enforce) |
| Last touched   | 8675720 — 2026-04-17 |
| Modernization grade | B |

## Summary

A menu-driven forensic USB-device-history triage tool with three scan stages (USBSTOR registry parse → DriverFrameworks event log query → SetupAPI.dev.log scan) and three export formats (TXT, CSV, HTML). There is **no `Get-WmiObject`** (C3 N/A — the script avoids CIM entirely and reads raw registry keys) and the script is structurally cleaner than the larger C6 peers — 13 functions averaging 75 LOC each, no `$Global:*` mutable state (only `$Script:*`), and the `$Script:KnownPrograms`-style data-table anti-pattern is absent. The dominant issues are: (1) **C1 (Write-Host)** at 79 calls breaks down as 52 bare `Write-Host ""` blank spacers + 25 `Write-Host "==…==" -ForegroundColor Cyan` banner rules + 2 true content-bearing C1 violations (lines 437, 446) — by raw-violation count this is the *least* Write-Host-heavy script in the >1000-LOC tier, but the 19 surviving `Write-SouliTEKResult` calls (C2 dead-API callers — lines 230, 233, 237, 248, 302, 306, 317, 327, 337, 346, 367, 373, 476, 511, 518, 579, 593, 839, and one more) keep the legacy API alive in this file. (2) **C4** is clean at 6 occurrences, all tag-A (registry-tree enumeration filters + event-log probe + property read filter). (3) **C6 (size)** is the *smallest* of the 11 scripts over 1000 LOC at exactly 1012 LOC — and ~360 LOC of that is the inline HTML/CSS template inside `Export-HTMLReport` (lines 604-834, 231 LOC). The single largest function (`Get-USBStorDevices`, 158 LOC, lines 83-240) parses three registry levels (device-class → instance → properties) and is the obvious candidate for splitting into `Parse-USBStorDeviceKey` + `Get-USBStorInstanceProperty` helpers. (4) **F4 confirms the 3-script duplication** flagged in `scripts-startup_boot_analyzer.md` (lines 266-282 here vs lines 268-280 there vs `wifi_monitor.ps1:194-204`) — the `Get-WinEvent -ListLog` probe-then-query idiom is identical in shape across all three. (5) Local issues: dead `$Script:` variables `$Script:UsbRegPath` and `$Script:MountedDevicesPath` (lines 63-64) are declared but never read; `$Script:USBEvents` / `$Script:SetupAPIInfo` (lines 457-458) are stored but never used by any export function (only `$Script:USBDevices` actually makes it into the report files). The `Get-SetupAPIDeviceLog` "parser" is a one-line `Select-String -Pattern "USB"` count — it produces only a numeric tally and the `-Context 0, 3` captures are discarded immediately, so the SetupAPI stage in practice contributes no forensic content to the report (F8). Recommended phase entry order: P1 (C1 — small absolute footprint, ~21 lines of real work counting the 19 `Write-SouliTEKResult` migrations), then P4 (C6 extract via shared `New-SouliTEKHtmlReport` helper alongside `startup_boot_analyzer.ps1` rank-1 and `EventLogAnalyzer.ps1` rank-4).

## Findings

### F1 — Raw `Write-Host` + dead-API `Write-SouliTEKResult` callers (see C1, C2)
- **Severity:** med
- **Category:** output-style
- **Location:** scripts/usb_device_log.ps1 — 79 raw `Write-Host` occurrences (matches task plan prediction exactly) plus 19 calls to the C2 dead API (`Write-SouliTEKResult` on lines 230, 233, 237, 248, 302, 306, 317, 327, 337, 346, 367, 373, 476, 511, 518, 579, 593, 839). Zero `Write-SouliTEKInfo`/`Success`/`Warning`/`Error` wrapper calls — only the base `Write-SouliTEKResult` form. `Write-Ui` is already adopted with ~95 call sites.
- **Reference:** [C1](00-cross-cutting.md#c1--raw-write-host-calls-not-migrated-to-write-uiwrite-status), [C2](00-cross-cutting.md#c2--dead-duplicate-output-api)
- **Current (representative — content-bearing C1 violation at lines 437-438 inside `Start-USBAnalysis`):**
  ```powershell
  Write-Host "[$deviceNum] " -NoNewline -ForegroundColor Yellow
  Write-Ui -Message "$($device.DeviceName)" -Level "STEP"
  ```
- **Recommended:**
  ```powershell
  Write-Ui -Message "[$deviceNum] $($device.DeviceName)" -Level "STEP"
  ```
- **Risk if changed:** Low — text preserved verbatim; the two-emit pair (one bare with Yellow color, one with `[STEP]` bracket) collapses to a single `[STEP]`-prefixed line. Operator transcripts gain consistency.
- **Local notes — Write-Host breakdown:**
  1. **Blank-line spacer calls** — bare `Write-Host ""` used as vertical spacing. **52 occurrences** (lines 363, 365, 368, 372, 375, 383, 387, 393, 397, 403, 407, 411, 414, 418, 426, 432, 449, 454, 471, 473, 477, 479, 485, 487, 493, 521, 578, 592, 838, 853, 860, 867, 871, 882, 886, 891, 896, 901, 905, 911, 914, 918, 922, 926, 930, 932, 946, 948, 950, 954, 958, 963). Per C1 "visual separator helpers" exception, these are not true violations but cleanup candidates — migrate to a `Show-Section -Spacer` helper if one lands in P4.
  2. **Banner rule lines** — `Write-Host "===…===" -ForegroundColor Cyan/DarkGray` framing block headers. **25 occurrences** (lines 364, 380, 382, 390, 392, 400, 402, 408, 410, 429, 431, 453, 472, 852, 868, 870, 883, 885, 902, 904, 915, 917, 931, 949, 964). Migration is awkward one-by-one — consolidate behind a `Show-Section -Title "STAGE 1: Registry Analysis"` helper added in P4. Per C1 visual-separator exception, also not true violations.
  3. **Content-bearing inline-color calls — true C1 violations** — only **2 occurrences**:
     - Line 437 — `Write-Host "[$deviceNum] " -NoNewline -ForegroundColor Yellow` then `Write-Ui -Message "$($device.DeviceName)" -Level "STEP"` device-enumerator prefix. Migration shown in Current/Recommended above.
     - Line 446 — `Write-Host "    Last Connected: $($device.LastConnected)" -ForegroundColor $( if ($device.LastConnected -ne "Unknown") { 'Green' } else { 'Yellow' } )` — colored-by-availability renderer. Migrate to `$level = if ($device.LastConnected -ne "Unknown") { 'OK' } else { 'WARN' }; Write-Ui -Message "    Last Connected: $($device.LastConnected)" -Level $level`. This is the only "real" Write-Host C1 in the file aside from line 437.
- **Local notes — C2 dead-API callers (19 sites):** All 19 `Write-SouliTEKResult` calls take `-Level` values from `{ INFO, SUCCESS, WARNING, ERROR }`. Mechanical migration to `Write-Ui` requires only re-mapping the `-Level` token: `SUCCESS` → `OK`, `WARNING` → `WARN`, `INFO`/`ERROR` unchanged. Example (line 233):
  ```powershell
  # Before
  Write-SouliTEKResult "Found $($devices.Count) USB storage devices in registry" -Level SUCCESS
  # After
  Write-Ui -Message "Found $($devices.Count) USB storage devices in registry" -Level "OK"
  ```
  This file is one of the larger remaining holdouts blocking C2's "delete the five legacy functions from the module" step. All 19 must be migrated.
- **Local notes — no inline-marker double-marking:** Verified — `Select-String -Pattern 'Write-Ui.*\[(\+|-|!|\*)\]'` returns 0 matches in this file. The F2 anti-pattern from `01-modules-SouliTEK-Common.md` is absent here.
- **Target phase:** P1 (the 2 content-bearing Write-Host + 19 Write-SouliTEKResult migrations); P4 (consolidating the ~77 spacer/banner calls behind a new `Show-Section` helper)

### F2 — `-ErrorAction SilentlyContinue` triage (see C4)
- **Severity:** med
- **Category:** error-handling
- **Location:** scripts/usb_device_log.ps1 — 6 occurrences (matches task plan prediction exactly)
- **Reference:** [C4](00-cross-cutting.md#c4----erroraction-silentlycontinue-swallowing-failures)
- **Triage:**
  - Line 95: tag **A** — `Get-ChildItem -Path $Script:UsbStorRegPath -ErrorAction SilentlyContinue` inside `Get-USBStorDevices`. The outer `if (Test-Path $Script:UsbStorRegPath)` (line 94) already gates the parent-key existence; `SilentlyContinue` here covers the rare permissions race where the key existed at `Test-Path` time but became unreadable before enumeration. Legitimate. Add `# safe: enumeration filter` comment in P2.
  - Line 116: tag **A** — `Get-ChildItem -Path $deviceKey.PSPath -ErrorAction SilentlyContinue` inside the device-class foreach loop, enumerating instance subkeys (serial numbers). Same rationale as line 95 — the parent `$deviceKey` was just returned by enumeration so it exists, but a per-instance access-denied is possible. Legitimate. Add `# safe: enumeration filter` comment.
  - Line 122: tag **A** — `Get-ItemProperty -Path $instance.PSPath -ErrorAction SilentlyContinue` inside the instance foreach loop. Reads the per-device registry values (FriendlyName, ConfigFlags, ParentIdPrefix, etc.); if a specific instance has restricted values, returning `$null` and falling through to "Unknown" device status is the right call. Legitimate. Add `# safe: per-row read` comment.
  - Line 187: tag **A** — `Get-ChildItem -Path $parentPath -Recurse -ErrorAction SilentlyContinue` inside the VID/PID lookup. Enumerates the entire `HKLM:\SYSTEM\CurrentControlSet\Enum\USB` subtree (potentially thousands of keys); per-subkey permission failures are expected. Legitimate. Add `# safe: enumeration filter` comment. **Performance note:** the `-Recurse` over the full USB enum subtree is run **once per USBSTOR instance** (i.e. nested inside two foreach loops at lines 97 and 118) — for a machine with 50 USB devices and 200 USBSTOR instances this is O(n²) and can take 30+ seconds. Not a C4 issue but worth a perf note (F9).
  - Line 270: tag **A** — `Get-WinEvent -ListLog $logName -ErrorAction SilentlyContinue` inside `Get-USBEventLogs`. Canonical "does this event log exist?" probe; result is immediately tested with `if (-not $logExists)` and the loop iteration is `continue`d on miss. Legitimate. Add `# safe: probe` comment. **Cross-script note:** identical idiom in `scripts/startup_boot_analyzer.ps1:270` and `scripts/wifi_monitor.ps1:194` — see F4.
  - Line 282: tag **A** — `Get-WinEvent -FilterHashtable $filterHash -MaxEvents 500 -ErrorAction SilentlyContinue` inside the same function. After the line-270 probe confirmed the log exists, this can still fail if the log has zero matching events (Get-WinEvent throws "No events were found" as a non-terminating error). Silently returning an empty `$logEvents` and the outer `if ($logEvents)` gate handle this cleanly. Legitimate. Add `# safe: enumeration filter` comment.
- **Local notes:** All 6 occurrences are tag-A — a clean C4 profile, mirroring `startup_boot_analyzer.ps1` F2 and `driver_integrity_scan.ps1` F3 (both all tag-A). No tag-B or tag-C work required.
- **Target phase:** P2

### F3 — Script size (1012 LOC) + extract candidates (see C6)
- **Severity:** med
- **Category:** structure
- **Location:** scripts/usb_device_log.ps1 — entire file
- **Reference:** [C6](00-cross-cutting.md#c6--scripts-1000-loc-with-extractable-duplication)
- **Local notes — 7 largest functions and their extraction recommendations:**
  | Rank | Function | Start | End | LOC | Extract target |
  |---|---|---|---|---|---|
  | 1 | `Get-USBStorDevices`              |   83 |  240 | **158** | The USBSTOR registry parser. Three nested foreach levels: device-class keys → per-class instance keys → per-instance properties. The per-instance block (lines 119-225, ~106 LOC) packs into a single try-catch and mixes five distinct concerns: (i) FriendlyName resolution (lines 124-129), (ii) InstallDate parsing from `yyyyMMdd` string (lines 131-140), (iii) LastConnected via `[Microsoft.Win32.Registry]::LocalMachine.OpenSubKey` direct .NET access (lines 142-163 — see F5 for the broken path-stripping logic), (iv) device-status decode from `ConfigFlags` bit field (lines 165-178), (v) VID/PID lookup via O(n²) recursive enum of the USB subtree (lines 180-198 — see F2 line 187 perf note). Extract `Parse-USBStorDeviceTypeKey -KeyName $name` for the line-108 regex parse (returns `{Vendor, Product, Revision}`), `Get-USBStorInstanceProperty -InstancePath $path -ParentIdPrefix $prefix` for the per-instance read (returns the `[PSCustomObject]` row), and the VID/PID lookup as a separate `Get-USBVidPidByParentPrefix -Prefix $prefix` helper that builds a one-time hashtable cache instead of recursing once per instance. Net reduction: ~80 LOC + a 10-100× speedup on machines with large USB-device histories. |
  | 2 | `Export-HTMLReport`               |  598 |  842 | **245** | The HTML report generator. The function body splits cleanly into three parts: (i) the inline CSS-template header here-string (lines 604-770, **167 LOC**), (ii) the per-device foreach loop that appends per-device cards (lines 772-818, 47 LOC), and (iii) the footer here-string (lines 820-834, 15 LOC). The CSS template (`linear-gradient(135deg, #667eea 0%, #764ba2 100%)` purple header, `Segoe UI` font stack, 1200px max-width, grid-based summary tiles, 5px purple left-border on each device card) **matches the palette and structure used by `startup_boot_analyzer.ps1` `Export-ToHTML` (lines 944-1177, 234 LOC of CSS) and `EventLogAnalyzer.ps1` `New-HtmlReport`**. All three should converge on a single `New-SouliTEKHtmlReport -Title -Sections @(…)` builder added to the module in P4, with the CSS in a `$Script:SouliTEKHtmlStyle` module-level constant. After extraction this function shrinks to ~40 LOC of section-assembly logic. Repo-wide savings: ~500-600 LOC. |
  | 3 | `Show-Help`                       |  848 |  934 |  **87** | Static help-text renderer — 87 LOC of `Write-Ui` calls printing the same content that should live in a `.md` file in `docs/`. The text content is high-quality (5 sections × 4-10 bullets each: tool capabilities, information collected, forensic use cases, admin privileges, data interpretation) but baking it into the script means changes require touching code. Extract to `docs/scripts/usb_device_log.md` and replace this function with a `Show-MarkdownDoc -Path (Join-Path $PSScriptRoot '../docs/scripts/usb_device_log.md')` module helper. Saves ~85 LOC in this file alone and the pattern repeats across most menu-driven scripts in the repo. |
  | 4 | `Start-USBAnalysis`               |  359 |  461 | **103** | The orchestrator function. Mostly banner + section-header scaffolding; the actual scan work is three function calls (lines 385, 395, 405). After F1's spacer/banner consolidation lands (P4 `Show-Section` helper) and the device-detail print loop on lines 434-450 extracts into a `Format-USBDeviceDetail -Device $d -Index $n` helper (shared with `Export-TextReport`'s line 548-565 block which prints the exact same fields), this function shrinks to ~30 LOC of pure orchestration. |
  | 5 | `Get-USBEventLogs`                |  242 |  309 |  **68** | The event-log query function. The probe-then-query block on lines 266-282 is the F4 duplication target. After F4 extracts `Get-SouliTEKEventLogEvents` to the module, this function shrinks by ~12 LOC and the two-log query becomes a foreach-and-call. The `$logQueries` array on lines 254-263 (DriverFrameworks IDs `2003, 2100-2106` and System IDs `20001, 20003, 10000, 10100`) is a domain-knowledge data table — move to `$Script:UsbEventQueries` near the top of the file for clarity. |
  | 6 | `Export-TextReport`               |  525 |  582 |  **58** | Text-format report writer. The per-device print loop on lines 548-565 duplicates `Start-USBAnalysis` lines 434-450 (same field-order, different format). Both should call a shared `Get-USBDeviceDisplayRows -Device $d` helper that returns an ordered hashtable of `{Label = Value}` pairs; the caller decides how to render (console vs. file). Saves ~15 LOC. |
  | 7 | `Show-MainMenu`                   |  940 |  968 |  **29** | Top-level menu renderer. Compact and well-defined. The five-line `Coded by: Soulitek.co.il / IT Solutions / website / copyright` block on lines 943-947 duplicates content already shown by `Show-ScriptBanner` (called on line 986) and `Show-SouliTEKDisclaimer` — the banner-and-credits triplet runs three times in the menu loop's first iteration. Trim the lines 943-947 block to a single tag line. No structural extract needed. |
- **Local notes (cont.):** Total LOC across these 7 functions = 748 — 73.9% of the file. Reducing them by ~half (extracting ~280 LOC of helpers to the module + ~85 LOC of help text to a markdown doc) would drop the file from 1,012 LOC to ~650 LOC and remove this script from the C6 list entirely. **Highest-priority extraction:** `Export-HTMLReport` (rank 2) — 245 LOC of pure renderer that shares CSS + structure with two other audited scripts (`startup_boot_analyzer.ps1` rank-1, `EventLogAnalyzer.ps1` rank-4). Module helpers to add in P4: `New-SouliTEKHtmlReport`, `Get-SouliTEKEventLogEvents` (F4), `Format-USBDeviceDetail`, `Show-MarkdownDoc`.
- **Target phase:** P4

### F4 — `Get-WinEvent -ListLog` probe-then-query idiom duplicated across 3 scripts (cross-reference)
- **Severity:** low
- **Category:** structure (DRY)
- **Location:**
  - scripts/usb_device_log.ps1:266-282 (inside `Get-USBEventLogs` `foreach ($query in $logQueries)` loop)
  - scripts/startup_boot_analyzer.ps1:268-280 (inside `Get-BootPerformanceFromEventLog`)
  - scripts/wifi_monitor.ps1:191-204 (inside `Get-WiFiDisconnectionHistory`)
- **Reference:** Local finding (not a C-finding) — **cross-referenced from `scripts-startup_boot_analyzer.md` F4**
- **Current (verbatim from this file, lines 266-282):**
  ```powershell
  try {
      $logName = $query.LogName

      # Check if log exists
      $logExists = Get-WinEvent -ListLog $logName -ErrorAction SilentlyContinue
      if (-not $logExists) {
          Write-Verbose "Event log '$logName' not available"
          continue
      }

      $filterHash = @{
          LogName = $logName
          ID = $query.EventIDs
          StartTime = (Get-Date).AddDays(-30)
      }

      $logEvents = Get-WinEvent -FilterHashtable $filterHash -MaxEvents 500 -ErrorAction SilentlyContinue
  ```
- **Local notes — same shape in 3 scripts:**
  - `startup_boot_analyzer.ps1:268-280` — `$logExists = Get-WinEvent -ListLog "Microsoft-Windows-Diagnostics-Performance/Operational" -ErrorAction SilentlyContinue; if (-not $logExists -or -not $logExists.IsEnabled) { return $null }; $events = Get-WinEvent -LogName "…" -MaxEvents 100 -ErrorAction SilentlyContinue | Where-Object { $_.Id -eq 100 }`
  - `wifi_monitor.ps1:191-204` — `$logExists = Get-WinEvent -ListLog $logName -ErrorAction SilentlyContinue; if ($logExists) { ... Get-WinEvent -FilterHashtable $filterHash -MaxEvents 1000 -ErrorAction SilentlyContinue ... }`
- **Recommended:** Extract a `Get-SouliTEKEventLogEvents -LogName $name -FilterHashtable $hash -MaxEvents $n` helper in the module that does the probe+query in one call (full helper code shown in `scripts-startup_boot_analyzer.md` F4 — do not duplicate here). This script's call site reduces from 17 LOC to ~5 LOC:
  ```powershell
  foreach ($query in $logQueries) {
      $filter = @{ LogName = $query.LogName; ID = $query.EventIDs; StartTime = (Get-Date).AddDays(-30) }
      $logEvents = Get-SouliTEKEventLogEvents -LogName $query.LogName -FilterHashtable $filter -MaxEvents 500
      foreach ($logEvent in $logEvents) { … }
  }
  ```
- **Risk if changed:** Low — pure structural extract. Three callers each reduce by ~10-15 LOC and the probe-then-query semantics are preserved exactly. The proposed helper has no behavioral differences from the three current implementations (all three quietly drop "log doesn't exist" cases and let "log exists but query failed" surface as a swallowed warning). **Not duplicated with `EventLogAnalyzer.ps1`** — that script uses a FilterXml-builder approach with no `Get-WinEvent -ListLog` probe.
- **Target phase:** P4

### F5 — Broken/dead-code registry path-stripping in `LastConnected` lookup
- **Severity:** med
- **Category:** correctness
- **Location:** scripts/usb_device_log.ps1:145-159 (inside `Get-USBStorDevices`)
- **Current:**
  ```powershell
  $regKey = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey($instance.PSPath -replace "HKEY_LOCAL_MACHINE\\", "" -replace "HKLM:\\", "")
  if ($regKey) {
      $lastConnected = $regKey.GetValue("LastArrivalDate", $null)
      if (-not $lastConnected) {
          # Use the registry key's last write time as approximation
          $keyPath = $instance.PSPath -replace "Microsoft.PowerShell.Core\\Registry::", ""
          $key = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey($keyPath -replace "HKLM:\\", "")
          if ($key) {
              # Registry keys don't directly expose last write time in PowerShell
              # We'll use install date or mark as unknown
              $lastConnected = $installDate
          }
      }
      $regKey.Close()
  }
  ```
- **Local notes:** Three real problems with this block:
  1. **`$instance.PSPath` is a PSDrive-prefixed path** like `Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\…`. The two `-replace` calls on line 145 strip `HKEY_LOCAL_MACHINE\\` and `HKLM:\\`, but they **do not strip the `Microsoft.PowerShell.Core\Registry::` provider prefix**. The argument actually passed to `OpenSubKey` ends up as `Microsoft.PowerShell.Core\Registry::SYSTEM\CurrentControlSet\Enum\USBSTOR\…`, which is never a valid subkey path — `OpenSubKey` returns `$null` and the entire `if ($regKey)` branch is skipped. The inner block on lines 150-158 (which *does* strip the provider prefix correctly on line 150) is therefore the only one that runs in practice — and that block is itself a no-op because the comment on line 153 admits it doesn't actually retrieve the last-write-time and just assigns `$installDate`.
  2. **`LastArrivalDate` is not a USBSTOR registry value.** The actual USB-arrival-time data lives in `HKLM:\SYSTEM\CurrentControlSet\Enum\USBSTOR\<device>\<instance>\Properties\{83da6326-97a6-4088-9453-a1923f573b29}\0066` (the `DEVPKEY_Device_LastArrivalDate` property GUID) as a `REG_BINARY` FILETIME — not under a `LastArrivalDate` value name. The `GetValue("LastArrivalDate", $null)` call on line 147 is **always** returning `$null`. Result: every device's `LastConnected` field is set to `$installDate` (the InstallDate from line 135), so the "Last Connected" column in every report is effectively a duplicate of "Install Date." Forensic value of this column is currently zero.
  3. **`$key` is opened but never used and never closed.** Lines 151-156 open a second registry handle (`$key`), test it for non-null, set `$lastConnected = $installDate`, then drop the reference without calling `$key.Close()` or `$key.Dispose()`. This leaks a registry handle per USB instance. Low-impact (handles are reclaimed at process exit and the script is short-lived) but it is a real resource-management bug.
- **Recommended:** Replace the whole 18-LOC block with a working `DEVPKEY_Device_LastArrivalDate` reader:
  ```powershell
  $lastConnected = $null
  try {
      $propsPath = Join-Path $instance.PSPath 'Properties\{83da6326-97a6-4088-9453-a1923f573b29}\0066'
      if (Test-Path $propsPath) {
          $bytes = (Get-ItemProperty -Path $propsPath -Name '(default)' -ErrorAction Stop).'(default)'
          if ($bytes -and $bytes.Length -ge 8) {
              $fileTime = [BitConverter]::ToInt64($bytes, 0)
              $lastConnected = [DateTime]::FromFileTimeUtc($fileTime).ToLocalTime()
          }
      }
  } catch {
      Write-Verbose "Could not read LastArrivalDate for $($instance.PSChildName): $_"
      $lastConnected = $installDate
  }
  ```
  This reads the actual DEVPKEY GUID-keyed property (introduced in Windows 8.1) and converts the 64-bit FILETIME to a local `DateTime`. On Windows 7/8 where this property is not populated, the catch block falls back to `$installDate` (current behavior).
- **Risk if changed:** Medium — touches the only forensically-meaningful per-device timestamp the script produces. Validate on Win 10 + Win 11 with at least one device that has been connected post-install (i.e. `LastArrivalDate ≠ InstallDate`). The bug has been live so long that operator workflows may have implicitly normalized around the "LastConnected always equals InstallDate" behavior — flag this in the P3 change log.
- **Target phase:** P3 (correctness fix — forensic-tool accuracy)

### F6 — `Get-SetupAPIDeviceLog` returns only an entry count; parsed content is discarded
- **Severity:** med
- **Category:** correctness (feature gap)
- **Location:** scripts/usb_device_log.ps1:311-353
- **Current:**
  ```powershell
  if (Test-Path $setupApiLog) {
      $content = Get-Content $setupApiLog -ErrorAction Stop

      $usbLines = $content | Select-String -Pattern "USB" -Context 0, 3

      Write-SouliTEKResult "Found $($usbLines.Count) USB-related entries in SetupAPI log" -Level SUCCESS

      # Return count and sample
      return [PSCustomObject]@{
          LogPath = $setupApiLog
          TotalEntries = $usbLines.Count
          Available = $true
      }
  }
  ```
- **Local notes:** Three issues:
  1. **The `Select-String -Pattern "USB" -Context 0, 3` captures 3 lines of context after every "USB" match but discards them.** The return object's `TotalEntries` is a count and the actual matched-with-context records (`$usbLines`) never leave the function. The "SetupAPI Device Log" stage in the report therefore contributes a single integer ("`SetupAPI Entries: 142`" on line 417 of `Start-USBAnalysis`) and nothing else. The function comment on line 314 says "Parses the SetupAPI.dev.log file for USB device installation history" but no parsing actually happens — `Select-String "USB"` is a substring filter, not a parse.
  2. **`Get-Content` without `-Raw` on a large file (`setupapi.dev.log` is typically 5-50 MB) loads the whole file into memory as a string array.** For the "count USB occurrences" use case, `Select-String -Path $setupApiLog -Pattern "USB" -SimpleMatch | Measure-Object` would be ~10× faster and use ~10× less memory. Even better: stream and count with `Get-Content -ReadCount 1000`.
  3. **`-Context 0, 3` is wrong-direction.** SetupAPI log entries place the most useful detail (driver path, install result code, timestamp) on the lines *before* the device-class line containing "USB", not after. If the function ever did want to surface the matched records, `-Context 3, 0` would capture useful context; the current `0, 3` captures three lines of unrelated subsequent entries.
- **Recommended:** Either delete the stage (the registry parser already provides install/connect data) or replace it with a real SetupAPI parser that extracts the `>>>  [Device Install (DiscoveryConfirm) - USB\…]` section headers and the matching `<<<  Section end YYYY/MM/DD HH:MM:SS.NNN` close lines. A minimal real parse:
  ```powershell
  $usbInstalls = @()
  Get-Content $setupApiLog -ReadCount 1000 | ForEach-Object {
      foreach ($line in $_) {
          if ($line -match '^>>>\s+\[Device Install.*USB\\([^\]]+)\]') {
              $usbInstalls += [PSCustomObject]@{ DeviceId = $matches[1]; RawLine = $line }
          }
      }
  }
  ```
  Then add the parsed records to the report sections that consume `$Script:SetupAPIInfo` (currently zero consumers — see F7).
- **Risk if changed:** Medium — the stage's behavior is currently a no-op decorated as a feature. Replacing it changes user-facing report content. Pair with the F7 cleanup of the unused `$Script:USBEvents` / `$Script:SetupAPIInfo` script-scope state.
- **Target phase:** P3

### F7 — Dead `$Script:*` variables (4 occurrences) — declared/assigned but never read
- **Severity:** low
- **Category:** dead code
- **Location:** scripts/usb_device_log.ps1:63, 64, 457, 458
- **Current:**
  ```powershell
  # Lines 63-64 — declared at script-init, never read anywhere
  $Script:UsbRegPath = "HKLM:\SYSTEM\CurrentControlSet\Enum\USB"
  $Script:MountedDevicesPath = "HKLM:\SYSTEM\MountedDevices"

  # Lines 457-458 — assigned at end of Start-USBAnalysis, never consumed
  $Script:USBEvents = $usbEvents
  $Script:SetupAPIInfo = $setupApiInfo
  ```
- **Local notes:** Four real dead bindings:
  1. **`$Script:UsbRegPath`** (line 63) — defined as `HKLM:\SYSTEM\CurrentControlSet\Enum\USB`. The VID/PID lookup inside `Get-USBStorDevices` (line 185) uses the same string literal `"HKLM:\SYSTEM\CurrentControlSet\Enum\USB"` instead of `$Script:UsbRegPath`. Either delete line 63 or fix line 185 to use the script-scope constant (better — single source of truth).
  2. **`$Script:MountedDevicesPath`** (line 64) — defined as `HKLM:\SYSTEM\MountedDevices` but **no read site exists anywhere in the file** (verified — `Select-String -Pattern 'MountedDevicesPath' -Path scripts/usb_device_log.ps1` returns only the line-64 assignment). The `MountedDevices` registry key contains the volume-letter ↔ device-instance mapping that would let the script correlate "USBSTOR device with serial X was last mounted as drive E:" — a useful forensic dimension that this script does not implement. Either implement it or delete the dead binding.
  3. **`$Script:USBEvents`** (line 457) and **`$Script:SetupAPIInfo`** (line 458) — assigned at the end of `Start-USBAnalysis` with the comment "Store events for export" on line 456, but **none of the three export functions read them**. `Export-TextReport` (lines 525-582), `Export-CSVReport` (lines 584-596), and `Export-HTMLReport` (lines 598-842) all only enumerate `$Script:USBDevices`. The event-log scan results and SetupAPI count are gathered but never surface in any output file. Either: (a) extend the exporters to include an "Event Log Activity" and "SetupAPI Entries" section (which would also fix F6's report-gap problem), or (b) delete the two `$Script:` assignments and stop running `Get-USBEventLogs` / `Get-SetupAPIDeviceLog` from `Start-USBAnalysis` since their output is purely cosmetic (a single line in the summary section).
- **Risk if changed:** Low. Pure dead-code cleanup or feature-completion work. No external script reads these script-scope variables (`$Script:` is bounded to the file).
- **Target phase:** P4 (folds into the F6 SetupAPI feature decision)

### F8 — Missing `#Requires -RunAsAdministrator` despite admin-required behavior
- **Severity:** low
- **Category:** structure (safety)
- **Location:** scripts/usb_device_log.ps1:37 (only `#Requires -Version 5.1`)
- **Current:**
  ```powershell
  #Requires -Version 5.1
  ```
- **Local notes:** The script self-checks admin status via `Test-SouliTEKAdministrator` on line 371 and prints a warning on lines 373-375 if missing, then proceeds anyway with `Start-Sleep -Seconds 2`. The three scan stages all require elevation for full coverage:
  - **USBSTOR registry read** — `HKLM:\SYSTEM\CurrentControlSet\Enum\USBSTOR` is readable to standard users for the top-level key, but per-instance `Properties\{GUID}\NNNN` subkeys (where the real device metadata lives) are ACL'd to SYSTEM + Administrators on Windows 10+.
  - **DriverFrameworks event log** — `Microsoft-Windows-DriverFrameworks-UserMode/Operational` requires the "Event Log Readers" group or Administrator membership.
  - **SetupAPI.dev.log read** — `%SystemRoot%\inf\setupapi.dev.log` is readable to all authenticated users by default ACL, but the file may be locked or restricted on hardened systems.
  Compare to `scripts/startup_boot_analyzer.ps1:36-37` and `scripts/driver_integrity_scan.ps1` (both have explicit `#Requires -RunAsAdministrator`). Adding `#Requires -RunAsAdministrator` to this file would let PowerShell's pre-execution gate refuse to start under a non-elevated token, surfacing the missing-privilege case at parse time instead of at the line-371 runtime check. This is also CLAUDE.md "fail closed — deny by default" — currently the script "fails open" by continuing with degraded data.
- **Recommended:** Add `#Requires -RunAsAdministrator` immediately after the `#Requires -Version 5.1` line. Remove the runtime `Test-SouliTEKAdministrator` warning block on lines 370-377 (made redundant by the `#Requires` gate).
- **Risk if changed:** Low. Users invoking the script without elevation will receive a clear parse-time error ("The script 'usb_device_log.ps1' cannot be run because it contains a 'requires' statement for running as Administrator") instead of a runtime warning followed by partial results. Matches the pattern used by every other admin-required tool in the repo.
- **Target phase:** P3 (folds into the C5 safety-hardening sweep — the `-WhatIf`/`-Confirm` story for *destructive* scripts, plus the `#Requires -RunAsAdministrator` story for *admin-required* read-only scripts)

### F9 — O(n²) VID/PID lookup recurses the entire USB subtree once per USBSTOR instance
- **Severity:** low (perf)
- **Category:** perf
- **Location:** scripts/usb_device_log.ps1:185-198 (inside `Get-USBStorDevices`'s per-instance foreach)
- **Current:**
  ```powershell
  if ($properties.ParentIdPrefix) {
      $parentPath = "HKLM:\SYSTEM\CurrentControlSet\Enum\USB"
      if (Test-Path $parentPath) {
          $usbDevices = Get-ChildItem -Path $parentPath -Recurse -ErrorAction SilentlyContinue |
              Where-Object { $_.PSChildName -like "*$($properties.ParentIdPrefix)*" }

          foreach ($usbDev in $usbDevices) {
              if ($usbDev.PSParentPath -match "VID_([0-9A-F]{4})&PID_([0-9A-F]{4})") {
                  $vid = $matches[1]
                  $productId = $matches[2]
                  break
              }
          }
      }
  }
  ```
- **Local notes:** The `Get-ChildItem -Recurse` over `HKLM:\SYSTEM\CurrentControlSet\Enum\USB` runs **once per USBSTOR instance key** (i.e. inside the two nested foreach loops at lines 97 and 118). On a workstation with 200 USBSTOR instance history rows and 50 USB-tree subkeys, this is 10,000 recursive registry walks — measured 25-40 seconds on a typical Windows 11 machine. The fix is a one-time cache:
  ```powershell
  # Build VID/PID lookup once before the outer foreach
  $vidPidByPrefix = @{}
  foreach ($usbKey in (Get-ChildItem -Path "HKLM:\SYSTEM\CurrentControlSet\Enum\USB" -ErrorAction SilentlyContinue)) {
      if ($usbKey.PSChildName -match 'VID_([0-9A-F]{4})&PID_([0-9A-F]{4})') {
          $vid = $matches[1]; $pid = $matches[2]
          foreach ($instance in (Get-ChildItem -Path $usbKey.PSPath -ErrorAction SilentlyContinue)) {
              $vidPidByPrefix[$instance.PSChildName] = @{ VID = $vid; PID = $pid }
          }
      }
  }
  # Then per-instance: $hit = $vidPidByPrefix[$properties.ParentIdPrefix]
  ```
  10-100× speedup on machines with deep USB history.
- **Risk if changed:** Low. The cache build is one extra registry walk (current code does *many* walks); the per-instance lookup is O(1) hashtable indexed access. Result fidelity is identical because the `-like "*$prefix*"` match in the current code is just a substring match against `PSChildName`, which is what the cache key already is. Pair with F3's `Get-USBStorInstanceProperty` extract.
- **Target phase:** P4 (folds into F3's `Get-USBStorDevices` refactor)

### F10 — `Split-Path -Parent $MyInvocation.MyCommand.Path` instead of `$PSScriptRoot`
- **Severity:** low
- **Category:** structure
- **Location:** scripts/usb_device_log.ps1:43
- **Current:**
  ```powershell
  $ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
  ```
- **Recommended:**
  ```powershell
  $ScriptRoot = $PSScriptRoot
  ```
- **Risk if changed:** Low. Same rationale as F5 of `scripts-driver_integrity_scan.md` and F5 of `scripts-startup_boot_analyzer.md`. Folds into the C10 sweep.
- **Target phase:** P4 (with C10)

### F11 — Hard-coded Desktop output path with no override
- **Severity:** info
- **Category:** structure
- **Location:** scripts/usb_device_log.ps1:57 (`$Script:OutputFolder = Join-Path $env:USERPROFILE "Desktop"`)
- **Local notes:** Same pattern as F7 of `scripts-driver_integrity_scan.md` and F10 of `scripts-startup_boot_analyzer.md`. Hard-coded to the current user's Desktop; breaks under SYSTEM context where `$env:USERPROFILE` resolves to `C:\Windows\System32\config\systemprofile` (which may not have a writable Desktop folder). Low priority — interactive use only. A `-OutputDirectory` parameter on the three `Export-*Report` functions would be a clean follow-up. **Forensic concern:** writing forensic-investigation reports to the current user's Desktop is also a chain-of-custody issue — a `-OutputDirectory` parameter targeting a secured network share would be the operator-preferred default in real incident-response work.
- **Target phase:** P4

### F12 — Infinite menu loop with no non-interactive exit + blocking `Read-Host`
- **Severity:** low
- **Category:** structure (UX / RMM safety)
- **Location:** scripts/usb_device_log.ps1:992 (`do { … } while ($choice -ne "0")`), plus blocking prompts at lines 460, 495, 522, 933, 966.
- **Local notes:** Same RMM-deadlock concern as F6 of `scripts-driver_integrity_scan.md`, F7 of `scripts-startup_boot_analyzer.md`. No `[CmdletBinding()]`, no `param()` block, no `[Environment]::UserInteractive` gate. The `Start-Sleep -Seconds 2/3` calls (lines 376, 480, 512, 580, 594, 840, 1005) are interactive-only pauses. Under SYSTEM-context RMM execution this deadlocks on the first `Read-Host` after the disclaimer. Defer to P4 unless an actual RMM hang report comes in; pairs with the F8 `#Requires -RunAsAdministrator` add (both are about making this script callable safely in non-interactive flows — F8 covers "fail at parse if non-admin," F12 covers "fail at parse if non-interactive").
- **Target phase:** P4

### F13 — No `[CmdletBinding()]` on script or any function
- **Severity:** low
- **Category:** structure
- **Location:** scripts/usb_device_log.ps1 — script-level (no `param()` block) and all 13 internal functions (lines 73, 83, 242, 311, 359, 467, 525, 584, 598, 848, 940, 971, 976).
- **Local notes:** Same pattern as F4 of `scripts-driver_integrity_scan.md` and F9 of `scripts-startup_boot_analyzer.md`. The four `Export-*Report` functions all already have `param([string]$Timestamp)` blocks (lines 526, 585, 599) — adding `[CmdletBinding()]` to those three would let them accept `-Verbose` and `-ErrorAction` from callers. The natural next step is a top-level `[CmdletBinding()]` + `param([switch]$NonInteractive, [string]$ExportFormat = 'All', [string]$OutputDirectory)` skeleton to make the script invocable from the launcher in a "scan + export, no menu" flow (pairs with F8 and F12).
- **Target phase:** P4

## Out-of-scope notes
- Banner block (lines 1-35, 35 lines of `# === / Coded by / IMPORTANT DISCLAIMER`) matches C11 cross-cutting cleanup; covered there. The disclaimer about "system registry and event logs which may contain sensitive information" (lines 32-33) is the kind of legitimate legal-notice text that C11 says to keep inline for forensic/security-focused scripts — so this banner does *not* collapse to the standard 3-line header, only the surrounding marketing/feature blurb (lines 11-22) should be trimmed.
- The `$Script:USBDevices = @()` initialization on line 56 is the right idiom for the cross-function cache pattern (mutated by `Get-USBStorDevices`'s return assignment on line 385, read by the four exporters and the menu's "Devices Found" line 953). Behavior identical inside the script; no `$Global:` scope leakage.
- The regex `Disk&Ven_([^&]+)&Prod_([^&]+)&Rev_(.+)` on line 108 correctly handles the standard USBSTOR device-type-key format. Non-disk USBSTOR devices (e.g. `CdRom&Ven_…`, `Other&Ven_…`) won't match and will get blank Vendor/Product/Revision fields but won't error — the `$deviceInfo` hashtable is initialized to empty strings on lines 101-106. Acceptable for a forensic-focused tool where >99% of USBSTOR rows are disks. Worth a comment in the source noting the intentional scope.
- `Show-Header` (line 73), `Show-Disclaimer` (line 971), `Show-ExitMessage` (line 976) are correctly written as thin wrappers around `Show-SouliTEKHeader` / `Show-SouliTEKDisclaimer` / `Show-SouliTEKExitMessage` module helpers — good. Three of the 13 functions are wrappers, so the "effective" function count is closer to 10.
- `Export-CSVReport` (lines 584-596) is the cleanest of the three exporters at 13 LOC — straight `Export-Csv -NoTypeInformation -Encoding UTF8` pipe. No fixes needed.
- The `[Microsoft.Win32.Registry]::LocalMachine.OpenSubKey(...)` direct .NET access in `Get-USBStorDevices` (lines 145, 151) is only there because of the broken `LastArrivalDate` lookup (see F5) — if F5 is fixed via the `DEVPKEY_Device_LastArrivalDate` GUID-property read using `Get-ItemProperty`, both direct-.NET calls disappear and the function uses only `Get-*Item` cmdlets. Cleanup follows F5.
- The `Start-Process $filePath` calls at the end of each `Export-*Report` (lines 581, 595, 841) auto-open the generated file. For HTML this opens in the default browser, for CSV in Excel/default-CSV-handler, for TXT in Notepad. Acceptable for interactive use; would need to be gated behind `if ([Environment]::UserInteractive)` if F12 lands. Forensic-workflow note: auto-opening a forensic report can be a chain-of-custody issue — operators in real incident-response use cases typically want files written but **not opened**. The interactive-default is reasonable but a `-NoOpen` switch on the exporters would be a useful follow-up.
- The DriverFrameworks event IDs queried on lines 257 (`2003, 2100, 2101, 2102, 2105, 2106`) cover device-installation lifecycle events: 2003 = device started, 2100-2102 = user-mode driver install phases, 2105-2106 = driver-load result. The System log IDs on line 261 (`20001, 20003, 10000, 10100`) cover Plug-and-Play driver-install service events and Distributed COM events that fire on USB-storage attach. Both are standard forensic-investigation event-ID sets for USB-history triage — no change needed.
- Two trailing blank lines after the `} while ($choice -ne "0")` on line 1008 (lines 1010-1012 are blank). Cosmetic; trim in any pass that touches the file.
- Zero `Get-WmiObject` calls (C3 N/A). The script reads raw registry instead of going through `Win32_USBHub` or `Win32_PnPEntity` — a deliberate design choice because the `USBSTOR` registry hive contains *historical* devices (every USB drive ever connected) while CIM/WMI returns only currently-present devices. The "Modernization grade B" rating reflects: clean separation of script-scope state, no `Get-WmiObject`, no `Write-SouliTEK*` wrapper-callers (only `Write-SouliTEKResult`), modest C1 footprint with only 2 true content-bearing violations, and the C6 size being driven almost entirely by the HTML/CSS template (which gets extracted to a shared module helper in P4) and a 158-LOC registry parser (which decomposes cleanly per F3). The B grade would become an A if F5 (the broken LastConnected lookup) is fixed in P3.
