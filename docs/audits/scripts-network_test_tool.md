# Audit — scripts/network_test_tool.ps1

## Inventory
| Item | Value |
|---|---|
| Path           | scripts/network_test_tool.ps1 |
| LOC            | 981 |
| Functions      | 12 |
| `#Requires`    | none |
| Admin-required | no (uses `Test-Connection`, `Resolve-DnsName`, `Get-NetRoute`, `Get-NetAdapter`, `Get-DnsClientServerAddress`, `tracert`; all read-only and run as the invoking user) |
| Last touched   | a76b4e7 — 2026-05-15 |
| Modernization grade | B |

## Summary

A menu-driven, interactive network triage tool with six tests (ping, traceroute, DNS lookup, continuous latency, quick-diagnostics, export to txt/csv/html). The script is already on the modern side of the codebase: it uses `Test-Connection` and `Resolve-DnsName` (not the legacy `ping.exe`/`nslookup` shell-outs or `Get-WmiObject`), and it has been partially migrated to `Write-Ui` — about 130 of its ~250 messaging calls already use `Write-Ui`. The blockers to a higher grade are (1) **155 raw `Write-Host` occurrences** — the 5th-highest count in the repo (C1), the bulk being separator strings (`"============"`) and bare `Write-Host ""` spacers but with a meaningful cluster of inline-color formatting in the latency table (lines 443–455) and quality-status lines (127, 146, 163, 170, 246, 444, 498, 505); (2) **26 surviving `Write-SouliTEKResult` calls** still using the C2 dead API that the C1 sweep is supposed to retire; and (3) a previously-unflagged **PS-7 correctness bug**: the script reads `$ping.ResponseTime` and `$ping.Address` (lines 119, 121, 419) which are `Win32_PingStatus` property names. In PS 7 `Test-Connection` returns a `PingStatus` object whose properties are `Latency` and `DisplayAddress`, so `$responseTime`/`$latency` will be `$null` and the entire ping-quality grading collapses to "Excellent" via the `-lt 50` cascade with `$null`. The two `-ErrorAction SilentlyContinue` occurrences (C4) are both `Test-Connection` probes and tag **A**. Minor structural issues: no `[CmdletBinding()]` anywhere, `Split-Path -Parent $MyInvocation.MyCommand.Path` instead of `$PSScriptRoot`, hard-coded Desktop output folder, blocking `Read-Host` "Press Enter" gates in a `do { … } while ($choice -ne "0")` loop with no `[Environment]::UserInteractive` short-circuit, and the C11 banner block at lines 1–32. The 6-line `Test-QuickDiagnostics` "Test 4" reference to `$adapters` and "Test 5" reference to `$dnsServers` re-query data that the dedicated DNS-lookup function already gathers — extract candidate for P4 only. Recommended phase entry order: P1 (C1 + C2 sweep, which also fixes F3's correctness bug as a side effect because the rewrite touches every ping-quality call), then P2 (the two C4 SilentlyContinues).

## Findings

### F1 — Raw `Write-Host` for separators, spacers, and inline-color formatting (see C1)
- **Severity:** med
- **Category:** output-style
- **Location:** scripts/network_test_tool.ps1 — 155 raw `Write-Host` occurrences (sample lines: 84, 100, 112, 127, 138, 139, 141, 143, 146, 163, 170, 193, 211, 246, 290, 326, 392, 401, 443–455, 463, 465, 498, 505, 535, 605, 821, 841, 851, 883–885, 902–904, 923–925, 933).
- **Reference:** [C1](00-cross-cutting.md#c1--raw-write-host-calls-not-migrated-to-write-uiwrite-status)
- **Current (representative — latency-table inline-color row at lines 443–448):**
  ```powershell
  Write-Host "$timestamp | " -NoNewline -ForegroundColor Gray
  Write-Host "$($latency.ToString().PadLeft(6))ms" -NoNewline -ForegroundColor $color
  Write-Host " | " -NoNewline -ForegroundColor Gray
  Write-Host "$($status.PadRight(7))" -NoNewline -ForegroundColor $color
  Write-Host " | " -NoNewline -ForegroundColor Gray
  Write-Host "${jitter}ms" -ForegroundColor $jitterColor
  ```
- **Recommended:** Either route through `Write-Ui` (loses the multi-column color split unless `Write-Ui` learns a `-NoNewline` mode — verify before deleting `Write-Host` here) or move this whole block into a new module helper `Show-LatencyRow -Timestamp -Latency -Status -Jitter`. The latter is preferable; the C1 cross-cutting exception explicitly carves out implementation-layer `Write-Host` inside `Show-*` helpers.
- **Risk if changed:** Low for the simple cases (bare spacers, separator lines, single-color status lines). **Medium** for lines 443–455 (latency table) and 498/505 (overall-quality line) where the `-NoNewline` chain breaks if naively replaced with `Write-Ui` — those calls need a real implementation-layer helper, not a one-to-one substitution.
- **Local notes:** Three categories of raw `Write-Host` in this script:
  1. **Bare spacers** (`Write-Host ""`) — ~80 occurrences, mostly vertical spacing between sections. Covered by the C1 "visual separator helpers" exception once a `Write-Ui -Spacer` (or `Show-Section`) helper exists; until then they are noisy but not violations to fix individually.
  2. **Separator banners** (`Write-Host "============================================================" -ForegroundColor Cyan`) — ~30 occurrences (every test function bookends its output with these). Folding these into a `Show-Section "TITLE"` helper would drop ~60 lines from the file and unify the visual style with `Show-SouliTEKHeader`.
  3. **Inline-color formatting** — real C1 violations: line 112 (`[$i/$count]`), 127 (`Reply from …`), 143/146 (loss percent), 163/170 (Connection Quality), 246 (Status), 401 (table separator `|---|`), 443–455 (latency table row), 451–455 (TIMEOUT row), 498/505 (Overall Quality), 821/841 (menu separators). These need the helper-based fix; bulk regex replacement will break the multi-color rows.
- **Local notes (cont.) — inline marker prefixes:** The `Write-Ui` calls in `Test-QuickDiagnostics` already embed `[1/5]`…`[5/5]` step markers (lines 542, 561, 573, 585, 595). Same anti-pattern as F2 of 01-modules-SouliTEK-Common.md — the `[STEP]` bracket emitted by `Write-Ui` makes these `[N/5]` markers redundant. Either drop the bracket markers when the C1 sweep lands, or keep them but switch to `-Level "INFO"` so the visual emphasis comes from the `[N/5]` and not from a duplicated `[STEP]`/`[WARN]` bracket.
- **Target phase:** P1

### F2 — `Write-SouliTEKResult` legacy API still in use (see C2)
- **Severity:** low
- **Category:** output-style / structure
- **Location:** scripts/network_test_tool.ps1 — 26 calls (lines 102, 180, 199, 207, 255, 274, 282, 355, 381, 394, 522, 538, 548, 551, 555, 564, 567, 576, 579, 629, 692, 703, 776, 784, 791, 803). Levels used: `INFO` (5), `ERROR` (11), `WARNING` (2), `SUCCESS` (8).
- **Reference:** [C2](00-cross-cutting.md#c2--dead-duplicate-output-api)
- **Current (representative — line 102):**
  ```powershell
  Write-SouliTEKResult "Starting ping test to $target..." -Level INFO
  ```
- **Recommended:**
  ```powershell
  Write-Ui -Message "Starting ping test to $target..." -Level "INFO"
  ```
- **Risk if changed:** Low — straight substitution. Level mapping: `INFO`→`"INFO"`, `ERROR`→`"ERROR"`, `WARNING`→`"WARN"`, `SUCCESS`→`"OK"`. Verify the `WARNING`/`WARN` and `SUCCESS`/`OK` mappings against the current `Write-Ui` `[ValidateSet]` before bulk-replacing.
- **Local notes:** This script is one of the largest remaining concentrations of the legacy API and must be migrated before C2's "delete the five legacy functions from the module" step. Almost every error path in the script (lines 180, 199, 207, 255, 274, 282, 355, 381, 394, 522, 567, 579, 629, 784, 791) flows through `Write-SouliTEKResult … -Level ERROR` — these are user-visible.
- **Target phase:** P1

### F3 — PS 7 correctness bug: `$ping.ResponseTime` / `$ping.Address` are PS-5.1-only properties
- **Severity:** high
- **Category:** correctness
- **Location:** scripts/network_test_tool.ps1:119, 121 (`Test-PingAdvanced`); scripts/network_test_tool.ps1:419 (`Test-Latency`).
- **Current:**
  ```powershell
  $ping = Test-Connection -ComputerName $target -Count 1 -ErrorAction SilentlyContinue
  if ($ping) {
      $responseTime = $ping.ResponseTime
      $ipAddress    = $ping.Address
      …
  }
  ```
- **Recommended:**
  ```powershell
  $ping = Test-Connection -ComputerName $target -Count 1 -ErrorAction SilentlyContinue
  if ($ping) {
      # PS 5.1: Win32_PingStatus → ResponseTime / Address
      # PS 7+ : PingStatus       → Latency / DisplayAddress
      $responseTime = if ($null -ne $ping.ResponseTime) { $ping.ResponseTime } else { $ping.Latency }
      $ipAddress    = if ($ping.Address) { $ping.Address } else { $ping.DisplayAddress }
      …
  }
  ```
  Or, if the codebase commits to a PS-5.1 floor (which `CLAUDE.md` does), wrap the call in a `Invoke-SouliTEKPing` module helper that normalises the property surface across versions and returns a single `PSCustomObject` with `Latency`, `Address`, `TimeToLive`.
- **Risk if changed:** Low — null-coalescing fallback. The grading cascade (`if ($responseTime -lt 50) { 'Green' } elseif ($responseTime -lt 100) …`) currently returns `'Green'` for `$null` because `$null -lt 50` is `$true` in PowerShell — so the script silently mis-reports "Excellent" quality on PS 7 today.
- **Local notes:** This bug was not in the C-list because no prior audit ran this script on PS 7. The 0-grade "Excellent" false positive is the most user-visible symptom; the `Add-TestResult` payload (line 172) also stores nonsense values (`Min: ms, Max: ms, Avg: ms` because `$null` formats as empty string). Worth fixing in the same P1 pass that does C1+C2 here, since the same `if ($ping) { … }` block has to be touched anyway.
- **Target phase:** P1

### F4 — `-ErrorAction SilentlyContinue` triage (see C4)
- **Severity:** med
- **Category:** error-handling
- **Location:** scripts/network_test_tool.ps1 — 2 occurrences
- **Reference:** [C4](00-cross-cutting.md#c4----erroraction-silentlycontinue-swallowing-failures)
- **Triage:**
  - Line 114: tag **A** — `Test-Connection -ComputerName $target -Count 1 -ErrorAction SilentlyContinue` is the ping probe inside `Test-PingAdvanced`; `$ping` is immediately tested with `if ($ping)` to branch between "Reply" and "Request timed out." Legitimate probe-and-test. Add `# safe: probe — null branch handles timeout` comment in P2.
  - Line 415: tag **A** — same pattern inside `Test-Latency`; `$ping` branches to either the success row or `TIMEOUT` row at line 451. Legitimate probe-and-test. Add `# safe: probe — null branch handles timeout` comment.
- **Target phase:** P2

### F5 — No `[CmdletBinding()]` on script or any function
- **Severity:** low
- **Category:** structure
- **Location:** scripts/network_test_tool.ps1 — script-level (no `param()` block) and on all 12 internal functions (`Add-TestResult` line 58, `Test-PingAdvanced` line 81, `Test-TraceRoute` line 188, `Test-DNSLookup` line 263, `Test-Latency` line 370, `Test-QuickDiagnostics` line 530, `Export-TestResults` line 620, `Clear-TestResults` line 798, `Show-MainMenu` line 812, `Show-Help` line 847, `Show-Disclaimer` line 939, `Show-ExitMessage` line 944).
- **Local notes:** Script is fully interactive (no CLI surface), so this is low-severity. Adding `[CmdletBinding()]` to `Add-TestResult` (which already has a `param()` block at line 59) would let it accept `-Verbose` and is a free win. The `Test-*` functions would benefit from `[CmdletBinding()]` + a `-Target` parameter so they could be dot-sourced and reused non-interactively from the launcher — but that crosses into C5 / non-interactive entry-point territory and should be a P3 follow-up if/when the launcher gains scripted-network-test buttons.
- **Target phase:** P4

### F6 — `Split-Path -Parent $MyInvocation.MyCommand.Path` instead of `$PSScriptRoot`
- **Severity:** low
- **Category:** structure
- **Location:** scripts/network_test_tool.ps1:38
- **Current:**
  ```powershell
  $ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
  ```
- **Recommended:**
  ```powershell
  $ScriptRoot = $PSScriptRoot
  ```
- **Risk if changed:** Low. Same fix as F5 of `scripts-driver_integrity_scan.md`. `$MyInvocation.MyCommand.Path` returns `$null` when the script is dot-sourced; `$PSScriptRoot` does not. Fold into the C10 sweep.
- **Target phase:** P4 (fold into the C10 sweep)

### F7 — Infinite menu loop with no non-interactive exit + blocking `Read-Host` gates
- **Severity:** low
- **Category:** structure (UX / RMM safety)
- **Location:** scripts/network_test_tool.ps1:960 (`do { … } while ($choice -ne "0")`), plus 16 `Read-Host` calls at lines 86, 95, 185, 196, 260, 271, 367, 378, 387, 527, 617, 647, 795, 800, 843, 935.
- **Local notes:** Same pattern as F6 of `scripts-driver_integrity_scan.md`. Under SYSTEM-context RMM execution (flagged in user's `CLAUDE.md` as a deployment scenario), `Read-Host` will hang the worker process indefinitely. There is no `[Environment]::UserInteractive` gate. The "Press Enter to return to main menu" gates after every test (11 of the 16 `Read-Host` calls) are particularly stubborn — a `-NonInteractive` switch on the script would let the launcher run any single test programmatically once F5's `[CmdletBinding()]` is in place. Defer to P4 unless an actual RMM hang is reported; if so, pair with the F10 of `01-modules-SouliTEK-Common.md` `Wait-SouliTEKKeyPress` migration.
- **Target phase:** P4

### F8 — Hard-coded Desktop output folder with no override
- **Severity:** info
- **Category:** structure
- **Location:** scripts/network_test_tool.ps1:52 (`$Script:OutputFolder = Join-Path $env:USERPROFILE "Desktop"`).
- **Local notes:** Same shape as F7 of `scripts-driver_integrity_scan.md`. The export-to-Desktop default breaks under SYSTEM context. A `-OutputDirectory` parameter on `Export-TestResults` paired with F5's `[CmdletBinding()]` would fix this. The fallback should be `$env:LOCALAPPDATA\SouliTEK\NetworkTests\` not `$env:TEMP` because the exported HTML report is a deliverable the user typically wants to keep.
- **Target phase:** P4

### F9 — `tracert` shell-out instead of `Test-NetConnection -TraceRoute`
- **Severity:** info
- **Category:** legacy-api (note only — see local notes)
- **Location:** scripts/network_test_tool.ps1:215 (`$traceOutput = tracert -d -h 30 $target`).
- **Local notes:** `Test-NetConnection -TraceRoute -ComputerName $target -Hops 30` returns a `TraceRoute` array of structured hop IPs that would replace the regex parsing on lines 220–234 (`if ($line -match '^\s+\d+\s+')`). The downside: `Test-NetConnection -TraceRoute` is sequential and noticeably slower than `tracert -d` in practice (it does PowerShell-side DNS work per hop), and the existing `tracert -d -h 30` is already correctly suppressing DNS resolution with `-d`. The structured-output win is real but not free. Worth noting; **not worth fixing** unless the surrounding regex parser breaks on a future Windows release. Flagged `info` only.
- **Target phase:** —

### F10 — `Test-Connection -Quiet -Count 2` in `Test-QuickDiagnostics` re-runs gateway/internet probes
- **Severity:** info
- **Category:** perf (note only — no change recommended)
- **Location:** scripts/network_test_tool.ps1:546, 562 (gateway and 8.8.8.8 quick-test probes).
- **Local notes:** `Test-QuickDiagnostics` re-runs `Test-Connection -ComputerName 8.8.8.8 -Count 2 -Quiet` (line 562) and `Test-Connection -ComputerName $gateway -Count 2 -Quiet` (line 546), each of which takes ~2 seconds when the target responds and ~5 seconds when it times out. Since this function is the "quick" diagnostic, a `-Count 1` would be faster with marginal accuracy loss; a `-TimeoutSeconds 2` is cleaner still but PS-7-only and outside the 5.1 floor. Not worth changing — the function's name is "quick" but the contract is "thorough enough to surface a clear OK/FAIL." Logged for completeness.
- **Target phase:** —

## Out-of-scope notes
- Banner block (lines 1–32, 27 lines of `# === / Coded by / IMPORTANT DISCLAIMER`) matches C11 cross-cutting cleanup; covered there.
- The `Export-TestResults` HTML template (lines 711–771) is well-structured: explicit `<style>` block with class-based status colors (`.status-excellent`, `.status-good`, `.status-fair`, `.status-poor`, `.status-error`), grid-based layout, and a `<pre>` block for the details field so multi-line traceroute output renders correctly. The only nit is the literal `[NETWORK]` text in the `<h1>` (line 734) — replace with a unicode network icon (e.g. `&#x1F310;` 🌐) or simply remove. Cosmetic.
- `Add-TestResult` (lines 58–75) is a clean append-only accumulator into `$Script:TestResults`. The `[PSCustomObject]@{ Timestamp = … }` pattern is correct and consistent with the rest of the codebase. No change needed.
- `Test-DNSLookup` (lines 263–368) only handles `A`, `AAAA`, `CNAME` record types in its `switch ($record.Type)` block (lines 297–323). `MX`, `TXT`, `NS`, `SOA`, `PTR` records returned by `Resolve-DnsName` will fall through silently because `switch` has no `default` branch. Low impact (the script is positioned as a connectivity tool, not a DNS-record inspector) but worth a one-line `default { … $details += "$($record.Type): $($record | Out-String)`n" }` if anyone touches this function. Info only.
- `Test-QuickDiagnostics` line 543 uses `(Get-NetRoute -DestinationPrefix 0.0.0.0/0 | Select-Object -First 1).NextHop`. If the route table is empty (single-NIC machine with no default gateway, e.g. fresh VM image), this returns `$null` and the `if ($gateway)` branch at line 544 handles it correctly. Defensive code is already in place. No change.
- The "Test 5" foreach over `$dnsServers` (lines 597–602) iterates `Get-DnsClientServerAddress` results without filtering for `AddressFamily IPv4` — but the upstream pipe at line 596 already filters with `-AddressFamily IPv4`, so it's correct. Reading the function flow top-to-bottom this isn't obvious; consider adding a comment.
- The `Clear-Host` at line 953 + `Show-ScriptBanner`/`Show-Disclaimer` sequence is the same boot-up pattern as `driver_integrity_scan.ps1` and most other scripts — a P4 candidate for a `Initialize-SouliTEKScript` helper call alongside C10.
- The single trailing newline at end of file (line 981 = `} while ($choice -ne "0")` followed by EOF) is correct — no blank-line cleanup needed.
- `Show-Help` (lines 847–936) is 90 lines of pure `Write-Ui` output with no actual logic; this is a natural candidate to extract into a here-string + `Write-Ui -Message $helpText -Level "INFO"` for ~80% line-count reduction. Defer to P4 cosmetic pass.
