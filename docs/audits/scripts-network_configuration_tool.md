# Audit — scripts/network_configuration_tool.ps1

## Inventory
| Item | Value |
|---|---|
| Path           | scripts/network_configuration_tool.ps1 |
| LOC            | 972 |
| Functions      | 15 (`Test-Administrator`, `Get-NetworkAdapters`, `Select-NetworkAdapter`, `Show-IPConfiguration`, `Set-StaticIP`, `Flush-DNSCache`, `Reset-NetworkAdapter`, `Export-ConfigurationReport`, `Export-TextReport`, `Export-CSVReport`, `Export-HTMLReport`, `Show-Help`, `Show-ExitMessage`, `Show-MainMenu`, `Main`) |
| `#Requires`    | **none** — no `#Requires -Version` and no `#Requires -RunAsAdministrator`, despite the script mutating IP addresses, routes, DNS server lists, and adapter state |
| Admin-required | yes (run-time only — each destructive function self-checks via `Test-Administrator` which proxies to `Test-SouliTEKAdministrator`; without admin the script falls back to read-only `Show-IPConfiguration`). `Set-NetIPAddress`/`Set-DnsClientServerAddress`/`Disable-NetAdapter`/`Enable-NetAdapter`/`Clear-DnsClientCache` all require elevation. |
| Last touched   | 8675720 — 2026-04-17 |
| Modernization grade | C |

## Summary

A menu-driven network-configuration tool: view IP config, apply static IP (with optional gateway + 2 DNS servers), flush DNS cache, disable/enable a network adapter, and export an operation log to TXT/CSV/HTML. The biggest issues are (1) **destructive without any `ShouldProcess` gate** — 9 mutation sites across 3 destructive functions tear down and re-build the IPv4 stack on a selected adapter (`Remove-NetIPAddress` + `Remove-NetRoute` + `New-NetIPAddress` + `New-NetRoute` + `Set-DnsClientServerAddress` + `Set-NetIPInterface -Dhcp Disabled` in `Set-StaticIP`; `Clear-DnsClientCache` in `Flush-DNSCache`; `Disable-NetAdapter` + `Enable-NetAdapter` in `Reset-NetworkAdapter`), none of which surface `-WhatIf`/`-Confirm` to the operator (C5); (2) **110 raw `Write-Host` calls** that mix bare-spacer `Write-Host ""`, manual `Write-Host "===...=== " -ForegroundColor Cyan` separator rendering, and inline-color status rendering (line 96 `Write-Host "    Status: $($adapter.Status)" -ForegroundColor $statusColor`, line 151 same pattern), violating STYLE_GUIDE.md (C1); (3) the 7 `-ErrorAction SilentlyContinue` occurrences split 3 tag-A (legitimate probes/optional `Start-Process` opens of the export file), 2 tag-B (the `Remove-NetIPAddress`/`Remove-NetRoute` calls at lines 395/399 silently swallow real failures during a mutation that *must* succeed for the subsequent `New-NetIPAddress` to land — see F3), and 2 tag-A on the read-only `Get-DnsClientServerAddress`/`Get-NetIPConfiguration` probes. Secondary concerns: **IP validation uses `[System.Net.IPAddress]::Parse` rather than `TryParse`** (lines 287, 325, 345) — wrapped in `try/catch` so it works, but the more idiomatic pattern is `if (-not [ipaddress]::TryParse(...))`; **the subnet-mask display at line 164 is broken** — `[System.Net.IPAddress]::HostToNetworkOrder(-1) -shl (32 - $prefixLength) -band [System.Net.IPAddress]::HostToNetworkOrder(-1)` produces a negative signed `Int32` that `IPAddress.Parse` reinterprets in little-endian byte order, producing wrong mask strings for most prefix lengths (separate correctness bug, F8); the user-input DNS servers (`$dns1`/`$dns2` from lines 357–358) are **never validated** before being passed to `Set-DnsClientServerAddress` (F7); function `Flush-DNSCache` (line 460) uses the unapproved verb `Flush` — `Clear-` is the approved equivalent (F9); no `[CmdletBinding()]` anywhere; `Split-Path -Parent $MyInvocation.MyCommand.Path` instead of `$PSScriptRoot`; the main `while ($true)` loop with 23 `Read-Host` gates would hang under SYSTEM/RMM execution. `Get-WmiObject` is not used here so C3 is N/A. No `Write-SouliTEK*` legacy-API callers so C2 is N/A here. The 38-line banner block (lines 1–37) matches C11. Recommended phase entry order: P3 (C5 — this is the most destructive script in the audit set after `essential_tweaks.ps1`, and pulling the IP out from under an SSH/RDP session is permanently destructive), then P1 (C1), then P2 (C4 triage).

## Findings

### F1 — Mutation sites needing `ShouldProcess` (see C5)
- **Severity:** high
- **Category:** safety
- **Location:** scripts/network_configuration_tool.ps1 — 9 mutation sites across 3 destructive functions
- **Reference:** [C5](00-cross-cutting.md#c5--destructive-scripts-lack-cmdletbindingsupportsshouldprocess--whatif-confirm)
- **Enumeration of every mutation site:**
  - **`Set-StaticIP` (line 239):**
    - L395 — `Remove-NetIPAddress -InterfaceAlias $adapter.Name -Confirm:$false -ErrorAction SilentlyContinue` — removes **every** IPv4 address currently bound to the adapter. The `-Confirm:$false` actively suppresses the cmdlet's built-in confirmation prompt, and `-ErrorAction SilentlyContinue` hides a failure that would leave the adapter in a half-torn-down state (see also F3 tag-B).
    - L399 — `Remove-NetRoute -InterfaceAlias $adapter.Name -DestinationPrefix "0.0.0.0/0" -Confirm:$false -ErrorAction SilentlyContinue` — removes the existing default gateway. Same `-Confirm:$false` + `SilentlyContinue` pattern.
    - L403 — `New-NetIPAddress -InterfaceAlias $adapter.Name -IPAddress $ipAddress -PrefixLength $prefixLength -ErrorAction Stop` — assigns the new static IPv4 address with operator-supplied prefix length. If the prior `Remove-NetIPAddress` failed silently (L395 tag-B), this throws and the adapter is now in a worse state than before the run.
    - L409 — `New-NetRoute -InterfaceAlias $adapter.Name -DestinationPrefix "0.0.0.0/0" -NextHop $gateway -ErrorAction Stop | Out-Null` — installs the new default route. Only runs if `$gateway` was supplied; otherwise the adapter has no gateway and the user loses off-subnet connectivity until they re-run the tool.
    - L419 — `Set-DnsClientServerAddress -InterfaceAlias $adapter.Name -ServerAddresses $dnsServers -ErrorAction Stop` — replaces the adapter's DNS server list with the operator-supplied 1–2 servers. The supplied DNS servers are never validated as IP addresses (F7).
    - L424 — `Set-NetIPInterface -InterfaceAlias $adapter.Name -Dhcp Disabled -ErrorAction Stop` — disables DHCP on the interface. After this point the system will not auto-recover the prior dynamic configuration on next boot; a manual `Set-NetIPInterface -Dhcp Enabled` is required to undo.
  - **`Flush-DNSCache` (line 460):**
    - L494 — `Clear-DnsClientCache -ErrorAction Stop` — flushes the local DNS resolver cache. Reversible (the cache repopulates), but technically a mutation and should still gate on `ShouldProcess`.
  - **`Reset-NetworkAdapter` (line 527):**
    - L575 — `Disable-NetAdapter -Name $adapter.Name -Confirm:$false -ErrorAction Stop` — administratively disables the network adapter. Severs all traffic on that adapter immediately. The `-Confirm:$false` suppresses the cmdlet's built-in confirm prompt (which would normally trigger because `Disable-NetAdapter` has `ConfirmImpact = 'High'`).
    - L582 — `Enable-NetAdapter -Name $adapter.Name -Confirm:$false -ErrorAction Stop` — re-enables the same adapter after a 3-second sleep. If this throws (rare, but possible if Windows has not finished tearing down the adapter), the operator's connectivity is permanently broken until manual intervention. The `catch` block (lines 607–617) helpfully tells the user "You may need to manually enable the adapter" — which is exactly the failure mode that `-WhatIf` should let them avoid.
- **Current (representative — `Reset-NetworkAdapter` lines 573–584):**
  ```powershell
  try {
      Write-Ui -Message "  [1/2] Disabling adapter..." -Level "INFO"
      Disable-NetAdapter -Name $adapter.Name -Confirm:$false -ErrorAction Stop

      Write-Ui -Message "  [OK] Adapter disabled" -Level "OK"
      Write-Ui -Message "  [2/2] Waiting 3 seconds..." -Level "INFO"
      Start-Sleep -Seconds 3

      Write-Ui -Message "  [2/2] Enabling adapter..." -Level "INFO"
      Enable-NetAdapter -Name $adapter.Name -Confirm:$false -ErrorAction Stop

      Write-Ui -Message "  [OK] Adapter enabled" -Level "OK"
  ```
- **Recommended:**
  ```powershell
  function Reset-NetworkAdapter {
      [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
      param()

      # ... admin check + adapter selection ...

      try {
          if ($PSCmdlet.ShouldProcess($adapter.Name, 'Disable network adapter')) {
              Write-Ui -Message "  [1/2] Disabling adapter..." -Level "INFO"
              Disable-NetAdapter -Name $adapter.Name -Confirm:$false -ErrorAction Stop
              Write-Ui -Message "  [OK] Adapter disabled" -Level "OK"
          }

          Start-Sleep -Seconds 3

          if ($PSCmdlet.ShouldProcess($adapter.Name, 'Re-enable network adapter')) {
              Write-Ui -Message "  [2/2] Enabling adapter..." -Level "INFO"
              Enable-NetAdapter -Name $adapter.Name -Confirm:$false -ErrorAction Stop
              Write-Ui -Message "  [OK] Adapter enabled" -Level "OK"
          }
      }
      ...
  }
  ```
  Apply the same pattern to **every mutation site listed above**. `Set-StaticIP` is the critical case — its 6 mutation sites should be wrapped in a single `if ($PSCmdlet.ShouldProcess("$($adapter.Name): IPv4 $ipAddress/$prefixLength via $gateway", 'Apply static IP configuration'))` block (not per-cmdlet) so `-WhatIf` either prints the whole intended action and skips, or applies the whole thing atomically — half-applied static-IP configs are the worst possible outcome. The script itself should also gain `[CmdletBinding(SupportsShouldProcess, ConfirmImpact='High')]` at top so `-WhatIf` propagates from the launcher (see F4). `ConfirmImpact='High'` is correct here — every one of these mutations can sever the operator's connection to the box.
- **Risk if changed:** Medium. Plumbing is mechanical, but each `ShouldProcess` site needs both `-Target` and `-Action` correct so `-WhatIf` output reads cleanly. Default behaviour preserved when neither `-WhatIf` nor `-Confirm` is passed. Test on a VM where you can recover via Hyper-V console if the adapter ends up in an unrecoverable state.
- **Local notes (atomicity in `Set-StaticIP`):** The current code at lines 393–425 is a sequence of `Stop`-on-error mutations preceded by two `SilentlyContinue` removals. If `New-NetIPAddress` (L403) throws after `Remove-NetIPAddress` (L395) succeeded, the adapter is left with no IPv4 address at all and the user has no way to undo from inside the script. There is no rollback. Either (a) wrap the whole block in a `ShouldProcess` gate that previews the full intent and lets the operator abort with `-WhatIf`, or (b) capture the pre-state of `Get-NetIPConfiguration` + `Get-NetRoute` before mutating, then on `catch` attempt a best-effort restore. (a) is the P3 minimum; (b) is a P4 hardening project.
- **Local notes (`-Confirm:$false` actively suppresses safety):** Lines 395, 399, 575, 582 pass `-Confirm:$false` explicitly. This *defeats* the cmdlets' built-in `ConfirmImpact='High'` confirmation. When the script gains `SupportsShouldProcess`, these explicit `-Confirm:$false` flags should be **removed** — instead, the wrapping function's `$PSCmdlet.ShouldProcess` becomes the single gate, and the launcher controls confirmation policy via its own `-Confirm`/`-WhatIf` invocation. Leaving the explicit `-Confirm:$false` in means the inner cmdlet still runs unconditionally even when the operator passed `-Confirm` to the outer script.
- **Target phase:** P3

### F2 — Raw `Write-Host` calls (see C1)
- **Severity:** med
- **Category:** output-style
- **Location:** scripts/network_configuration_tool.ps1 — 110 raw `Write-Host` occurrences. Representative line ranges: 81, 87, 88, 96, 99, 105, 106, 137, 138, 140, 141, 148, 151, 154, 158, 172, 175, 180, 183, 190, 206, 208, 214, 228, 232, 235, 244, 247, 258, 259, 261, 262, 271, 275, 296, 340, 355, 361, 362, 364, 365, 377, 380, 390, 427, 428, 430, 431, 446, 447, 449, 450, 452, 456, 464, 465, 468, 474, 478, 479, 480, 490, 496, 497, 499, 500, 515, 516, 518, 519, 523, 532, 535, 543, 544, 546, 547, 550, 553, 558, 559, 560, 570, 586, 587, 589, 590, 593, 608, 609, 611, 612, 614, 619, 628, 630, 636, 642, 704, 706, 724, 726, 813, 815, 890, 912, 920, 921, 922, 926, 939
- **Reference:** [C1](00-cross-cutting.md#c1--raw-write-host-calls-not-migrated-to-write-uiwrite-status)
- **Current (representative pattern — separator block at lines 138–141):**
  ```powershell
  Write-Host "============================================================" -ForegroundColor Cyan
  Write-Ui -Message "  IP CONFIGURATION FOR: $($adapter.Name)" -Level "INFO"
  Write-Host "============================================================" -ForegroundColor Cyan
  Write-Host ""
  ```
- **Recommended:**
  ```powershell
  Show-Section -Title "IP CONFIGURATION FOR: $($adapter.Name)" -Color Cyan
  ```
  (Where `Show-Section` is an existing/new module helper that emits the section-rule lines around a title — STYLE_GUIDE.md's stated long-term direction.) For the simpler "status-coloured" line (`Write-Host "    Status: $($adapter.Status)" -ForegroundColor $statusColor` at L96):
  ```powershell
  $level = if ($adapter.Status -eq 'Up') { 'OK' } else { 'WARN' }
  Write-Ui -Message "    Status: $($adapter.Status)" -Level $level
  ```
- **Risk if changed:** Low — pure replacement, no logic change. Message text preserved verbatim; the `[LEVEL]` bracket emitted by `Write-Ui` replaces the manual `-ForegroundColor`.
- **Local notes:** Four categories of raw `Write-Host` in this file:
  1. **Blank-line / spacer calls** — bare `Write-Host ""` used as vertical spacing (representative lines: 81, 88, 99, 106, 137, 141, 154, 172, 175, 183, 190, 206, 214, 232, 235, 244, 247, 258, 262, 271, 275, 296, 340, 355, 361, 365, 377, 380, 390, 427, 431, 446, 450, 452, 456, 465, 468, 474, 478, 480, 490, 496, 500, 515, 519, 523, 532, 535, 543, 547, 550, 553, 558, 560, 570, 586, 590, 593, 608, 612, 614, 619, 628, 630, 636, 642, 704, 706, 724, 726, 813, 815, 912, 920, 922, 926, 939). Per C1's "visual separator helpers" exception these may stay as-is, but a `Write-Ui -Spacer` helper added in P4 would replace all of them at once.
  2. **`========` separator-rule lines** — `Write-Host "============================================================" -ForegroundColor Cyan` / `-Gray` / `-Green` / `-Red` at lines 87, 105, 138, 140, 148, 158, 180, 208, 228, 259, 261, 362, 364, 428, 430, 447, 449, 479, 497, 499, 516, 518, 544, 546, 559, 587, 589, 609, 611, 921. These are the deepest C1 violations — they hand-roll the section-rule UI that `Show-Section`/`Show-SouliTEKHeader` was built to replace. Each occurrence pair (the `=== before TITLE ===` + `TITLE` + `=== after ===` triple) is exactly one `Show-Section -Title ... -Color ...` call. Rough count: ~15 triples = ~45 lines that collapse to ~15 helper calls.
  3. **Inline-color status rendering** — `Write-Host "    Status: $($adapter.Status)" -ForegroundColor $statusColor` (lines 96, 151). The `$statusColor` switch at line 94 (`if ($adapter.Status -eq 'Up') { 'Green' } else { 'Yellow' }`) is exactly the manual-rendering anti-pattern that `Write-Ui -Level $level` was built to replace. Map `'Green' -> 'OK'`, `'Yellow' -> 'WARN'`.
  4. **Plain message lines** — none in this file. All non-separator `Write-Host` calls fall into categories 1–3.
- **Local notes (cont.) — no legacy `Write-SouliTEK*` callers:** This file does not call any of the C2 dead-API functions, so the C2 migration step is N/A here.
- **Local notes (cont.) — minor inline indent in `Write-Ui` messages:** A handful of `Write-Ui` calls embed leading `"  "` whitespace inside the message string (lines 139, 149, 150, 152, 153, 159, 160, 165, 168, 170, 174, 181, 182, 193, 196, 200, 210, 212, 260, 266, 267, 269, 363, 366, 367, 369, 372, 375, 405, 410, 420, 425, 429, 448, 498, 517, 545, 548, 549, 555–557, 588, 610, 637–641, 645, 705, 725, 814, 913–919). Combined with the `[LEVEL]` prefix that `Write-Ui` already prepends, the output is double-indented. Strip in the same C1 sweep — same pattern as F2 of `scripts-essential_tweaks.md`.
- **Target phase:** P1

### F3 — `-ErrorAction SilentlyContinue` triage (see C4)
- **Severity:** med
- **Category:** error-handling
- **Location:** scripts/network_configuration_tool.ps1 — 7 occurrences
- **Reference:** [C4](00-cross-cutting.md#c4----erroraction-silentlycontinue-swallowing-failures)
- **Triage:**
  - **Line 187:** tag **A** — `$dnsConfig = Get-DnsClientServerAddress -InterfaceAlias $adapter.Name -AddressFamily IPv4 -ErrorAction SilentlyContinue` inside `Show-IPConfiguration`. Legitimate probe — the next line guards with `if ($dnsConfig -and $dnsConfig.ServerAddresses.Count -gt 0)`. Read-only call inside a viewer function. Add `# safe: probe` comment in P2.
  - **Line 256:** tag **A** — `$currentConfig = Get-NetIPConfiguration -InterfaceAlias $adapter.Name -ErrorAction SilentlyContinue` inside `Set-StaticIP`. The result is used only to print the *current* config for the operator (lines 264–272) and to test for an existing default gateway before removing it (line 398). Both uses null-guard. Legitimate probe. Add `# safe: probe` comment.
  - **Line 395:** tag **B** — `Remove-NetIPAddress -InterfaceAlias $adapter.Name -Confirm:$false -ErrorAction SilentlyContinue`. This is **inside the destructive critical path** of `Set-StaticIP`. If this throws (e.g. the cmdlet errors because no IPv4 address was bound, or because of a transient COM/WMI failure), the script silently moves on to `New-NetIPAddress` (L403) which will then throw `IPAddressConflict` because the prior address was never actually removed. The user sees the catch-block "Error applying configuration" message with no clue that the *first* step failed. **Replace with explicit `try { ... } catch [Microsoft.Management.Infrastructure.CimException] { ... }`** that distinguishes "no IPv4 address to remove" (benign, continue) from any other CIM error (halt). Apply during P2.
  - **Line 399:** tag **B** — `Remove-NetRoute -InterfaceAlias $adapter.Name -DestinationPrefix "0.0.0.0/0" -Confirm:$false -ErrorAction SilentlyContinue`. Same pattern, same critical path. If this fails to remove the prior default route (e.g. because the route is locked by another process), the subsequent `New-NetRoute` at L409 will throw `RouteExists`. **Apply the same tag-B fix as L395.** Note: this is gated on `if ($currentConfig.IPv4DefaultGateway)` (L398), so the "no route exists" case is already handled by skipping the call entirely — the only failures left are real errors, which should not be swallowed.
  - **Line 709:** tag **A** — `Start-Process $filePath -ErrorAction SilentlyContinue` in `Export-TextReport`. Opens the exported file in the default `.txt` handler after writing it; failure to open (no associated app, SYSTEM context with no shell) is non-essential. Add `# safe: optional open` comment.
  - **Line 729:** tag **A** — same as L709 but for `.csv` in `Export-CSVReport`. Add `# safe: optional open` comment.
  - **Line 818:** tag **A** — same as L709 but for `.html` in `Export-HTMLReport`. Add `# safe: optional open` comment.
- **Target phase:** P2

### F4 — No `[CmdletBinding()]` on script or any function
- **Severity:** low (escalates to **high** under the F1 ShouldProcess fix — they share a fix pass)
- **Category:** structure
- **Location:** scripts/network_configuration_tool.ps1 — script-level (top of file, no `param()` block at all) and every one of the 15 functions: `Test-Administrator` (line 66), `Get-NetworkAdapters` (line 70), `Select-NetworkAdapter` (line 74), `Show-IPConfiguration` (line 131), `Set-StaticIP` (line 239), `Flush-DNSCache` (line 460), `Reset-NetworkAdapter` (line 527), `Export-ConfigurationReport` (line 623), `Export-TextReport` (line 666), `Export-CSVReport` (line 716), `Export-HTMLReport` (line 736), `Show-Help` (line 825), `Show-ExitMessage` (line 900), `Show-MainMenu` (line 908), `Main` (line 930).
- **Local notes:** No `[CmdletBinding()]` anywhere. The F1 ShouldProcess fix forces `[CmdletBinding(SupportsShouldProcess)]` onto the three destructive functions (`Set-StaticIP`, `Flush-DNSCache`, `Reset-NetworkAdapter`) and onto the script itself — fold this finding into that pass. Non-destructive helpers (`Show-IPConfiguration`, `Select-NetworkAdapter`, the four `Export-*` functions, `Show-Help`, `Show-MainMenu`) don't strictly need `[CmdletBinding()]`, but adding it to `Main` plus a `param([switch]$NonInteractive)` would let the menu loop be skipped under SYSTEM/RMM (see F6).
- **Target phase:** P3 (with F1)

### F5 — `Split-Path -Parent $MyInvocation.MyCommand.Path` instead of `$PSScriptRoot`
- **Severity:** low
- **Category:** structure
- **Location:** scripts/network_configuration_tool.ps1:43
- **Current:**
  ```powershell
  $ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
  $CommonPath = Join-Path (Split-Path -Parent $ScriptRoot) "modules\SouliTEK-Common.ps1"
  ```
- **Recommended:**
  ```powershell
  $CommonPath = Join-Path (Split-Path -Parent $PSScriptRoot) "modules\SouliTEK-Common.ps1"
  ```
- **Risk if changed:** Low. `$PSScriptRoot` is the canonical PS 3.0+ automatic variable. `$MyInvocation.MyCommand.Path` returns `$null` when the script is dot-sourced. C10 will eventually replace this whole block with `Import-SouliTEKCommon`, but until then the one-line fix is free.
- **Target phase:** P4 (fold into the C10 sweep)

### F6 — Infinite menu loop with blocking `Read-Host` prompts (no non-interactive path)
- **Severity:** low
- **Category:** structure (UX / RMM safety)
- **Location:** scripts/network_configuration_tool.ps1:943 (`while ($true)`), plus 23 `Read-Host` calls at lines 82, 108, 236, 248, 278, 300, 304, 323, 341, 357, 358, 382, 457, 469, 482, 524, 536, 562, 620, 631, 644, 892, 946.
- **Local notes:** The only graceful exit is menu option `[0]` which calls `exit` (line 957). Under SYSTEM-context RMM execution (flagged in user's CLAUDE.md as a deployment scenario), every `Read-Host` will hang the worker process indefinitely. There is no `[Environment]::UserInteractive` gate and no `-NonInteractive`/`-Apply` switch. Given that this script is destructive (F1), a `-WhatIf`-aware non-interactive entry point would be a natural P3 follow-up: `Main -NonInteractive -ApplyStaticIP -IPAddress 192.168.1.100 -PrefixLength 24 -Gateway 192.168.1.1 -WhatIf` should be possible without ever calling `Read-Host`. The C5 fix and this finding are siblings — both want the script to grow a `param()` block at the top. Pair with F4 in the P3 cleanup. Note: under SYSTEM context the network mutations are particularly catastrophic — losing the management IP on a remote box that has no fallback management plane means a manual on-site recovery.
- **Target phase:** P3 (with F1) or P4

### F7 — User-supplied DNS servers not validated as IP addresses
- **Severity:** med
- **Category:** input-validation
- **Location:** scripts/network_configuration_tool.ps1:357–358 (collection), 414–419 (consumption)
- **Current:**
  ```powershell
  $dns1 = Read-Host "  Primary DNS (press Enter to skip)"
  $dns2 = Read-Host "  Secondary DNS (press Enter to skip)"
  ...
  if ($dns1 -or $dns2) {
      $dnsServers = @()
      if ($dns1) { $dnsServers += $dns1 }
      if ($dns2) { $dnsServers += $dns2 }

      Set-DnsClientServerAddress -InterfaceAlias $adapter.Name -ServerAddresses $dnsServers -ErrorAction Stop
      Write-Ui -Message "  [OK] DNS servers configured" -Level "OK"
  }
  ```
- **Recommended:**
  ```powershell
  $dnsServers = @()
  foreach ($entry in @($dns1, $dns2)) {
      if (-not [string]::IsNullOrWhiteSpace($entry)) {
          $parsed = $null
          if (-not [ipaddress]::TryParse($entry, [ref]$parsed)) {
              Write-Ui -Message "Invalid DNS server format: $entry" -Level "ERROR"
              Start-Sleep -Seconds 2
              return
          }
          $dnsServers += $parsed.ToString()
      }
  }
  if ($dnsServers.Count -gt 0) {
      Set-DnsClientServerAddress -InterfaceAlias $adapter.Name -ServerAddresses $dnsServers -ErrorAction Stop
      Write-Ui -Message "  [OK] DNS servers configured" -Level "OK"
  }
  ```
- **Risk if changed:** Low. The IP address and gateway inputs already go through `[System.Net.IPAddress]::Parse` (lines 287, 345); applying the same validation pattern to the DNS inputs closes the obvious symmetry gap. The current code passes whatever the user typed straight to `Set-DnsClientServerAddress`, which *does* reject malformed input — but the error surfaces from the cmdlet as a confusing `ParameterArgumentValidationError` rather than the friendly "Invalid DNS server format" message that the IP/gateway path produces. **From a CLAUDE.md "input validation on all external data — never trust input" posture, this is the kind of finding to flag proactively.**
- **Local notes:** The fix above also normalises the DNS string by round-tripping through `[ipaddress]`, which canonicalises `"8.8.8.8 "` (trailing space) and similar formatting drift. Use `TryParse` rather than `Parse + try/catch` for the same reason listed below — branch on a boolean rather than control flow via exception.
- **Local notes (cont.) — IP and gateway validation use `Parse` not `TryParse`:** Lines 287 and 345 use `$null = [System.Net.IPAddress]::Parse($ipAddress)` inside a `try/catch`. This works, but the more idiomatic and faster pattern is:
  ```powershell
  $parsed = $null
  if (-not [ipaddress]::TryParse($ipAddress, [ref]$parsed)) {
      Write-Ui -Message "Invalid IP address format!" -Level "ERROR"
      Start-Sleep -Seconds 2
      return
  }
  ```
  `TryParse` avoids the exception-as-control-flow cost and reads cleaner. Fold into the F7 fix pass. **Bottom-line IP-validation assessment:** the IP and gateway *are* validated (lines 287 + 345), but with the older `Parse` + `try/catch` idiom rather than `TryParse`, and the DNS inputs are not validated at all. Prefix-length validation at lines 308–314 correctly bounds to `0..32`. The subnet-mask-string-to-prefix-length conversion at lines 323–330 silently accepts any 4-octet `[ipaddress]` (e.g. `255.0.255.0` is non-contiguous and not a valid mask, but the code accepts it and computes a meaningless prefix length); a more correct check would verify the mask is a contiguous run of 1-bits before computing the prefix.
- **Target phase:** P2 (close to C4 territory — it's an input-validation gap, not a missing safety gate)

### F8 — Broken subnet-mask string calculation in `Show-IPConfiguration`
- **Severity:** med
- **Category:** correctness
- **Location:** scripts/network_configuration_tool.ps1:164
- **Current:**
  ```powershell
  $prefixLength = $ipConfig.IPv4Address.PrefixLength
  $subnetMask = ([System.Net.IPAddress]::Parse(([System.Net.IPAddress]::HostToNetworkOrder(-1) -shl (32 - $prefixLength)) -band [System.Net.IPAddress]::HostToNetworkOrder(-1))).ToString()
  Write-Ui -Message "  Subnet Mask: $subnetMask" -Level "STEP"
  ```
- **Local notes:** This computation is incorrect. `[System.Net.IPAddress]::HostToNetworkOrder(-1)` returns `-1` (sign-extended 32-bit `Int32`); `(-1 -shl (32 - $prefixLength))` produces a *signed* shift on `Int32` (e.g. for `$prefixLength = 24`, the result is `0xFFFFFF00` interpreted as the signed value `-256`); `-band -1` is a no-op; `[System.Net.IPAddress]::Parse(-256)` then either throws (because `Parse` expects a string and the integer overload interprets it as a 32-bit address in little-endian byte order, producing `0.255.255.255` for `-256`) or returns a misleading address depending on the prefix length. **For most prefix lengths the value displayed at line 165 is wrong** — for `/24` the user sees `0.255.255.255` instead of `255.255.255.0`. The correct calculation is:
  ```powershell
  $prefixLength = $ipConfig.IPv4Address.PrefixLength
  $maskBytes = [byte[]]@(0,0,0,0)
  for ($i = 0; $i -lt $prefixLength; $i++) {
      $maskBytes[[int][Math]::Floor($i / 8)] = $maskBytes[[int][Math]::Floor($i / 8)] -bor (1 -shl (7 - ($i % 8)))
  }
  $subnetMask = [System.Net.IPAddress]::new($maskBytes).ToString()
  ```
- **Risk if changed:** Low — this is a display-only field. The script already prints the correct `PrefixLength` value on the prior line (L160 `"Subnet Mask: $($ipConfig.IPv4Address.PrefixLength) bits"`); the buggy decimal-form display at L165 is supplementary information. The bug has been latent because most operators read the prefix-length field and ignore the second line. Fix is safe to apply standalone in P2.
- **Local notes (cont.):** The same code does **not** appear in `Set-StaticIP`'s subnet-mask handling — there, lines 322–330 use a sane byte-by-byte bit-count to derive `$prefixLength` from a dotted-decimal mask. Only the `Show-IPConfiguration` *display* path is wrong.
- **Target phase:** P2

### F9 — Unapproved verb: `Flush-DNSCache`
- **Severity:** low
- **Category:** naming
- **Location:** scripts/network_configuration_tool.ps1:460 (function declaration), 951 (caller in `Main`)
- **Current:**
  ```powershell
  function Flush-DNSCache { ... }
  ...
  "3" { Flush-DNSCache }
  ```
- **Recommended:**
  ```powershell
  function Clear-DnsCache { ... }
  ...
  "3" { Clear-DnsCache }
  ```
- **Risk if changed:** Low. `Flush` is not on Microsoft's approved-verbs list; `Clear-` is the approved equivalent (matching the underlying `Clear-DnsClientCache` cmdlet it wraps). The function is private to this script — there is exactly one caller, in `Main`'s switch at line 951. Two-character mechanical rename. PSScriptAnalyzer's `PSUseApprovedVerbs` rule will flag this as soon as C8 enables CI. Note: `DNSCache` should also be `DnsCache` per the PowerShell community-standard PascalCase rule (acronyms are not all-caps in cmdlet names — Microsoft's own cmdlet is `Clear-DnsClientCache`, not `Clear-DNSClientCache`).
- **Target phase:** P1 (fold into the C1 sweep) or P3

### F10 — Missing `#Requires -Version 5.1` (and optional `#Requires -RunAsAdministrator`)
- **Severity:** low
- **Category:** structure
- **Location:** scripts/network_configuration_tool.ps1 — top of file (no `#Requires` block at all)
- **Current:** The script self-checks admin inside each destructive function via `Test-Administrator` (lines 242, 463, 530) and falls back to the menu if not elevated. There is no `#Requires -RunAsAdministrator` and no `#Requires -Version 5.1`.
- **Recommended:**
  ```powershell
  #Requires -Version 5.1
  ```
- **Local notes:** Pre-declaring requirements is strictly more informative than the runtime self-check. The full `#Requires -RunAsAdministrator` directive would make PowerShell refuse to even parse the script in a non-elevated session — but that would change behaviour for non-admin callers who currently get useful read-only output (`Show-IPConfiguration`, `Show-Help`, exports). **Recommendation:** keep the runtime admin check (the script offers value to non-admin callers who only need to view config), but add `#Requires -Version 5.1` unconditionally. The full `#Requires -RunAsAdministrator` directive is the right call *only* if the script is restructured so that the read-only menu items are split out into a separate viewer script. For comparison, `scripts/driver_integrity_scan.ps1` declares both directives because it has no useful non-admin path.
- **Target phase:** P4

## Out-of-scope notes
- Banner block (lines 1–37, 37 lines of `# === / Coded by / IMPORTANT DISCLAIMER`) matches C11 cross-cutting cleanup; covered there. The "WARNING: Modifying network settings can cause loss of connectivity" notice (lines 32–35) is legitimate legal/safety text and should be retained inline even under C11's collapse rule.
- Import boilerplate (lines 43–50) matches C10; will be replaced by `Import-SouliTEKCommon` in P4 along with F5.
- `Get-WmiObject` is not used in this script, so C3 is N/A here.
- No `Write-SouliTEK(Result|Info|Success|Warning|Error)` legacy-API callers in this file — C2's "verify zero callers before deleting the legacy functions" check is already satisfied for `network_configuration_tool.ps1`.
- Hard-coded export path `$Script:OutputFolder = Join-Path $env:USERPROFILE "Desktop"` at line 57 is the same idiom flagged in F7 of `scripts-driver_integrity_scan.md`. Under SYSTEM context (`$env:USERPROFILE` = `C:\Windows\System32\config\systemprofile`) the Desktop folder may not exist and the `Out-File` at lines 702/722/811 will throw. Defer until SYSTEM-context use is actually attempted; covered as a follow-up.
- The HTML export template (lines 742–809) is fine for what it is — single-page static HTML with inline CSS. The two interpolation sites (`$($result.Timestamp)`, `$($result.Operation)`, etc. at lines 786–795) are not HTML-escaped, so a hostile adapter name or IP value containing `<script>` would be reflected unencoded. Currently no realistic injection path exists (adapter names come from `Get-NetAdapter`, IPs are `[System.Net.IPAddress]::Parse`-validated, operations are string literals), but the report writer should still use `[System.Web.HttpUtility]::HtmlEncode` or equivalent on each field per OWASP "encode at every output point." Note for the P4 hardening pass, not a finding here.
- The trailing 2 blank lines at end-of-file (lines 971–972) are harmless but could be trimmed in any pass that touches the file.
- `Show-Help` (lines 825–893) is a well-structured static help-text block. No `Write-Host` violations inside it — uses a single `Write-Host $helpText` (line 890) which is the right pattern for multi-line block output. No change needed.
- `Show-IPConfiguration` correctly aggregates results into `$Script:ConfigResults` (lines 217–226) for later export. The pattern is sound; only the F2 raw-`Write-Host` cleanup and the F8 subnet-mask display bug apply.
- The `Read-Host "Apply this configuration? (yes/no)"` confirmation flow at lines 382–388 (and the matching prompts at 482 and 562) is a *partial* mitigation for the missing `ShouldProcess` gate, but it's interactive-only and cannot be driven by `-Confirm:$false`/`-WhatIf` from a non-interactive caller. The F1 ShouldProcess fix would replace this hand-rolled confirmation with the framework one.
- `Get-NetworkAdapters` (line 70) filters with `Where-Object { $_.Status -eq 'Up' -or $_.Status -eq 'Disabled' }`. This excludes `'Not Present'`, `'Disconnected'`, and `'Lower Layer Down'` adapters from the selection list, which is the intended behaviour — operators typically only want to modify adapters that are physically present and in a known state. No change needed.
