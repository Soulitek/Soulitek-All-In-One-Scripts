# SouliTEK Repo Audits

This folder contains the modernization audit produced from
[`docs/superpowers/specs/2026-05-15-modernize-roadmap-design.md`](../superpowers/specs/2026-05-15-modernize-roadmap-design.md).

## Reading order

1. [`00-cross-cutting.md`](00-cross-cutting.md) — Canonical list of cross-cutting findings (C1–C14). Per-file audits cite these IDs rather than duplicating.
2. [`01-modules-SouliTEK-Common.md`](01-modules-SouliTEK-Common.md) — Common module audit.
3. [`02-Install-SouliTEK.md`](02-Install-SouliTEK.md) — Installer + hosting/api proxies audit.
4. Per-script audits below.

## Per-script audits

| Script | Audit | Predicted grade |
|---|---|---|
| `scripts/1-click_pc_install.ps1`           | [audit](scripts-1-click_pc_install.md)           | C |
| `scripts/battery_report_generator.ps1`     | [audit](scripts-battery_report_generator.md)     | B |
| `scripts/bitlocker_status_report.ps1`      | [audit](scripts-bitlocker_status_report.md)      | A |
| `scripts/browser_plugin_checker.ps1`       | [audit](scripts-browser_plugin_checker.md)       | B |
| `scripts/bsod_history_scanner.ps1`         | [audit](scripts-bsod_history_scanner.md)         | B |
| `scripts/create_system_restore_point.ps1`  | [audit](scripts-create_system_restore_point.md)  | C |
| `scripts/disk_usage_analyzer.ps1`          | [audit](scripts-disk_usage_analyzer.md)          | C |
| `scripts/domain_dns_analyzer.ps1`          | [audit](scripts-domain_dns_analyzer.md)          | C |
| `scripts/driver_integrity_scan.ps1`        | [audit](scripts-driver_integrity_scan.md)        | D |
| `scripts/essential_tweaks.ps1`             | [audit](scripts-essential_tweaks.md)             | D |
| `scripts/EventLogAnalyzer.ps1`             | [audit](scripts-EventLogAnalyzer.md)             | D |
| `scripts/exchange_calendar_permissions_audit.ps1` | [audit](scripts-exchange_calendar_permissions_audit.md) | B |
| `scripts/FindPST.ps1`                      | [audit](scripts-FindPST.md)                      | B |
| `scripts/license_expiration_checker.ps1`   | [audit](scripts-license_expiration_checker.md)   | C |
| `scripts/local_admin_checker.ps1`          | [audit](scripts-local_admin_checker.md)          | B |
| `scripts/m365_exchange_online.ps1`         | [audit](scripts-m365_exchange_online.md)         | C |
| `scripts/m365_user_list.ps1`               | [audit](scripts-m365_user_list.md)               | C |
| `scripts/mcafee_removal_tool.ps1`          | [audit](scripts-mcafee_removal_tool.md)          | D |
| `scripts/network_configuration_tool.ps1`   | [audit](scripts-network_configuration_tool.md)   | C |
| `scripts/network_test_tool.ps1`            | [audit](scripts-network_test_tool.md)            | B |
| `scripts/onedrive_status_checker.ps1`      | [audit](scripts-onedrive_status_checker.md)      | B |
| `scripts/printer_spooler_fix.ps1`          | [audit](scripts-printer_spooler_fix.md)          | D |
| `scripts/product_key_retriever.ps1`        | [audit](scripts-product_key_retriever.md)        | D |
| `scripts/ram_slot_utilization_report.ps1`  | [audit](scripts-ram_slot_utilization_report.md)  | C |
| `scripts/sharepoint_site_inventory.ps1`    | [audit](scripts-sharepoint_site_inventory.md)    | B |
| `scripts/software_updater.ps1`             | [audit](scripts-software_updater.md)             | B |
| `scripts/SouliTEK-Choco-Installer.ps1`     | [audit](scripts-SouliTEK-Choco-Installer.md)     | B |
| `scripts/SouliTEK-Softwares-Installer.ps1` | [audit](scripts-SouliTEK-Softwares-Installer.md) | B |
| `scripts/startup_boot_analyzer.ps1`        | [audit](scripts-startup_boot_analyzer.md)        | C |
| `scripts/storage_health_monitor.ps1`       | [audit](scripts-storage_health_monitor.md)       | B |
| `scripts/temp_removal_disk_cleanup.ps1`    | [audit](scripts-temp_removal_disk_cleanup.md)    | D |
| `scripts/usb_device_log.ps1`               | [audit](scripts-usb_device_log.md)               | B |
| `scripts/virustotal_checker.ps1`           | [audit](scripts-virustotal_checker.md)           | A |
| `scripts/wifi_monitor.ps1`                 | [audit](scripts-wifi_monitor.md)                 | B |
| `scripts/wifi_password_viewer.ps1`         | [audit](scripts-wifi_password_viewer.md)         | B |
| `scripts/win11_debloat.ps1`                | [audit](scripts-win11_debloat.md)                | D |

Grades are predictions; each audit confirms or revises in its Inventory section.

---

## Audit summary

### Confirmed grade distribution

| Grade | Count | Scripts |
|---|---|---|
| **A** | 1  | `virustotal_checker` |
| **B** | 17 | `battery_report_generator`, `bitlocker_status_report`, `browser_plugin_checker`, `bsod_history_scanner`, `exchange_calendar_permissions_audit`, `FindPST`, `local_admin_checker`, `network_test_tool`, `onedrive_status_checker`, `sharepoint_site_inventory`, `software_updater`, `SouliTEK-Choco-Installer` (slated for deletion), `SouliTEK-Softwares-Installer`, `storage_health_monitor`, `usb_device_log`, `wifi_monitor`, `wifi_password_viewer` |
| **C** | 10 | `1-click_pc_install`, `create_system_restore_point`, `disk_usage_analyzer`, `domain_dns_analyzer`, `license_expiration_checker`, `m365_exchange_online`, `m365_user_list`, `network_configuration_tool`, `ram_slot_utilization_report`, `startup_boot_analyzer` |
| **D** | 8  | `driver_integrity_scan`, `essential_tweaks`, `EventLogAnalyzer`, `mcafee_removal_tool`, `printer_spooler_fix`, `product_key_retriever`, `temp_removal_disk_cleanup`, `win11_debloat` |

### Cross-cutting findings — citation counts

How many per-file audits cite each cross-cutting ID. C1 and C4 hit every script.

| ID  | Title                                                  | Files citing |
|-----|--------------------------------------------------------|---|
| C1  | Raw `Write-Host` not migrated                          | 36 |
| C2  | Dead duplicate output API                              | 10 |
| C3  | `Get-WmiObject` (removed in PS 7)                      | 2  |
| C4  | `-ErrorAction SilentlyContinue` swallowing failures    | 36 |
| C5  | Destructive scripts lack `ShouldProcess`               | 9  |
| C6  | Scripts >1000 LOC with extractable duplication         | 11 |
| C7  | Pester coverage gap                                    | 2  |
| C8  | No PSScriptAnalyzer / CI                               | 3  |
| C9  | Naming drift                                           | 2  |
| C10 | Common-module import boilerplate duplicated            | 3  |
| C11 | Banner/disclaimer block duplicated                     | 3  |
| C12 | Installer hash-verification gap                        | 4  |
| C13 | Sequential loops where parallelism would help          | 8  |
| C14 | `netsh wlan` shell-out (info only)                     | 2  |

### High-impact discoveries beyond the cross-cutting list

Real bugs and security gaps surfaced during the audit that are not covered by C1–C14:

- **`scripts/temp_removal_disk_cleanup.ps1` F1 (high, correctness):** Function `Clear-RecycleBin` shadows the built-in cmdlet, causing recursive self-invocation; per-drive recycle-bin emptying is **unreachable** on non-C: drives as shipped.
- **`scripts/network_configuration_tool.ps1` F1 (high, safety):** 4 of 9 mutation sites pass `-Confirm:$false`, suppressing each cmdlet built-in HIGH-impact confirmation. `Set-StaticIP` has no rollback path if `New-NetIPAddress` throws after `Remove-NetIPAddress` succeeds.
- **`scripts/domain_dns_analyzer.ps1` F5 (high, security):** `whois.exe` hash-check is gated by the placeholder `"PASTE_SHA256_HERE"` — every run today silently skips integrity verification of the vendored binary.
- **`scripts/win11_debloat.ps1` F1 (high, security):** Script downloads `https://debloat.raphi.re/` via `Invoke-RestMethod` and executes via `[scriptblock]::Create()`. No URL pinning, no hash verification.
- **`scripts/mcafee_removal_tool.ps1` F3 (high, security):** `tools/MCPR.exe` has no runtime hash verification. Pinned SHA256 captured: `D4D2266A19876BECCC95A97E1E5821EF42D98D503818C1E3F19BE75E9358B100`.
- **`scripts/domain_dns_analyzer.ps1` (high, security):** `tools/whois.exe` has no enforced hash check. Pinned SHA256 captured: `EA845B43C323E35DF041B8914A520F1D9643E3689454AB3049C2103458A0142D`.
- **`hosting/.htaccess-redirect` (Install-SouliTEK F7, med, security):** Rewrites point at `Soulitek-AIO` instead of the real `Soulitek-All-In-One-Scripts` repo. Currently 404s; if anyone squats `Soulitek-AIO` on GitHub it becomes a supply-chain attack.
- **`scripts/bitlocker_status_report.ps1` F3 (high, security):** Recovery keys printed to stdout in plaintext with no masking, no `-Reveal` switch, no confirmation prompt.
- **`scripts/wifi_password_viewer.ps1` F9 (med, security):** Cleartext password exports dropped onto Desktop with default ACLs and auto-opened in Notepad.
- **`scripts/network_test_tool.ps1` F3 (high, correctness):** `$ping.ResponseTime` is null on PS 7 (cmdlet shape changed); `$null -lt 50` is `$true` so all latencies silently grade as "Excellent".
- **`scripts/storage_health_monitor.ps1` F3 (correctness):** `BusType -ne "USB" -or BusType -ne "Unknown"` is a tautology; USB disks leak into the report. F4: menu option 7 "Exit" does not actually exit (`break` inside `switch` does not break the outer `do/while($true)`).
- **`scripts/usb_device_log.ps1` F5/F6 (correctness):** `LastArrivalDate` registry read uses wrong value name + leaks a registry handle; the `LastConnected` column has zero forensic value. `Get-SetupAPIDeviceLog` claims to parse the log but only counts substring matches.
- **`scripts/SouliTEK-Choco-Installer.ps1` (cleanup):** Dead code — was deleted at commit `542ac7d` (2025-11-22) then accidentally re-added at `77696be` in an unrelated 1-Click PC Install refactor; sat broken in `main` for ~6 months. Delete in P1, do not rename.
- **`scripts/m365_user_list.ps1` F6/F7 (correctness):** HTML stat-box references `$user.MfaEnabled` (never set; property is `MfaConfigured`) → always shows 0% MFA. TXT/HTML reference `$user.MfaDefaultMethod` which is never populated.
- **`scripts/license_expiration_checker.ps1` F5/F6 (UX/security):** `Send-EmailAlert` advertises email sending but never sends — just saves HTML and prints a use-Send-MailMessage hint. `Send-TeamsAlert` POSTs to `Read-Host`-supplied webhook URL with no HTTPS / domain allow-list (SSRF surface).
- **`scripts/software_updater.ps1` F7 (correctness):** `Update-SoftwareInteractive` records `ExitCode = 0` unconditionally — `$LASTEXITCODE` never captured after `winget upgrade --all` native call, corrupting the JSON audit trail.
- **`scripts/printer_spooler_fix.ps1` F9 (correctness):** `-AutoFixSilent` writes log to `$env:USERPROFILE\Desktop` which does not exist under SYSTEM context; scheduled task silently fails to write the log.
- **`scripts/onedrive_status_checker.ps1` F5/F7 (correctness):** 8 empty `catch {}` blocks swallow terminating exceptions on top of legitimate SilentlyContinue probes. Latent `Substring` bug at line 351 throws on indented log lines and is silently swallowed.
- **Cross-script duplication (P4 high-value extraction):** `Get-WinEvent -ListLog` probe-then-query pattern duplicated verbatim in `startup_boot_analyzer.ps1`, `wifi_monitor.ps1`, `usb_device_log.ps1`. Microsoft Graph connect/disconnect/test scaffolding (~115 LOC each) duplicated across 6 scripts (~700 LOC deletable). HTML report rendering shared CSS/structure across `EventLogAnalyzer`, `startup_boot_analyzer`, `usb_device_log`.

### Pinned vendored-binary hashes

For the P0 / P6 work — runtime hash verification before invocation:

| Binary | Size (bytes) | SHA256 | Last updated |
|---|---|---|---|
| `tools/MCPR.exe`  | 12,647,224 | `D4D2266A19876BECCC95A97E1E5821EF42D98D503818C1E3F19BE75E9358B100` | 2025-11-18 |
| `tools/whois.exe` | 398,712    | `EA845B43C323E35DF041B8914A520F1D9643E3689454AB3049C2103458A0142D` | 2025-12-02 |

When either binary is refreshed, the audit, spec, and plan must be updated atomically with the new hash in the same commit.

### Phase entry-point summary

Each phase implementation plan should begin by reading the cross-cutting finding(s) it targets, then walking the per-script audits cited.

| Phase | Driving findings | Per-script audits to consult |
|---|---|---|
| **P0** | C8 (CI baseline), F7 of 02-Install-SouliTEK (`.htaccess-redirect` repo-name typo), F5 of `domain_dns_analyzer` (whois.exe hash placeholder), F3 of `mcafee_removal_tool` (MCPR.exe hash pinning) | repo root + 02 + scripts-domain_dns_analyzer + scripts-mcafee_removal_tool |
| **P1** | C1, C2, C3, C9 + a handful of F entries that fold in (e.g. `network_test_tool` F3 PS-7 ping bug, `local_admin_checker` F9 null-comparison) | all per-script audits with C1/C2/C3/C9 references |
| **P2** | C4 + per-script F entries with tag-B/C SilentlyContinue (notably `onedrive_status_checker` F5 empty catches, `1-click_pc_install` F2 broken `$?` checks) | all per-script audits with F entries citing C4 |
| **P3** | C5 (now 7 scripts including `printer_spooler_fix`) + per-script destructive findings | the 7 scripts listed in C5 Files affected, plus auth-mode work for `m365_exchange_online` F3 (interactive-only deadlocks under SYSTEM) |
| **P4** | C6, C10, C11, C13 + per-script extraction notes (esp. `Connect-SouliTEKMgGraph` helper for ~700-LOC Graph dedup) | the 11 scripts >1000 LOC + `01-modules-SouliTEK-Common` F4/F5 module-helper additions |
| **P5** | C7 | `01-modules-SouliTEK-Common` (28 untested functions) + per-script smoke tests |
| **P6** | C12 + F8 of `bitlocker_status_report` (recovery-key masking) + F1 of `win11_debloat` (remote-script supply chain) | `02-Install-SouliTEK`, `scripts-bitlocker_status_report`, `scripts-win11_debloat`, `scripts-mcafee_removal_tool`, `scripts-domain_dns_analyzer` |

### Validation method notes

- The plan structural validator `Select-String -Path $out -Pattern "^## Inventory$" -Quiet` was used after dropping the buggy `-SimpleMatch` flag (commit `6b7c706`). All 39 audit files pass.
- The placeholder regex `<[a-z…\.]+>` produces false positives on legitimate code samples (HTML tags like `<style>`, `<td>`, `<script>`; semver placeholders like `<X.Y.Z>`; Graph API placeholders like `<guid>` / `<tenant.onmicrosoft.com>`). Several audits worked around it by manually scanning for the actual template tokens (`<line>`, `<int>`, `<text>`, `<TBD>`, `<…>`). Consider tightening the regex in the next plan revision.
