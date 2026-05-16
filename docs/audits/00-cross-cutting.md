# Audit — Cross-Cutting Findings (C1–C14)

This file is the canonical source for findings that repeat across the codebase. Per-file audits cite these IDs (e.g. `see C1`) and add only the local detail. Do not duplicate recommendations here in per-file audits.

## How to read

- **ID** is stable. Once published, never renumber.
- **Files affected** is the count at the time of writing; per-file audits are the source of truth for per-file occurrence lines.
- **Target phase** maps to the phased roadmap in `docs/superpowers/specs/2026-05-15-modernize-roadmap-design.md` §5.

## Findings

### C1 — Raw `Write-Host` calls not migrated to `Write-Ui`/`Write-Status`
- **Severity:** med
- **Category:** output-style
- **Files affected:** 36 scripts; ~3,580 occurrences (see per-file audits for line ranges)
- **Current pattern:**
  ```powershell
  Write-Host "Doing thing..." -ForegroundColor Cyan
  Write-Host "[+] Done" -ForegroundColor Green
  ```
- **Recommended pattern:**
  ```powershell
  Write-Ui -Message "Doing thing..." -Level "STEP"
  Write-Ui -Message "Done" -Level "OK"
  ```
- **Exceptions:** `Write-Host` is allowed *inside* `Write-Ui` / `Show-*` helpers (the implementation layer) and inside the visual separator helpers (`Show-Section` etc.). It is NOT allowed in script-level code or feature functions.
- **Risk if changed:** Low — pure replacement, no logic change. Message text preserved verbatim.
- **Target phase:** P1

### C2 — Dead duplicate output API
- **Severity:** low
- **Category:** output-style / structure
- **Files affected:** module + all scripts that still call the legacy functions
- **Current:** `Write-SouliTEKResult` and the four convenience wrappers (`Write-SouliTEKInfo`, `Write-SouliTEKSuccess`, `Write-SouliTEKWarning`, `Write-SouliTEKError`) coexist with `Write-Ui`. STYLE_GUIDE.md mandates `Write-Ui`, but the legacy API is still defined in the module and called by some scripts and by `Export-SouliTEKReport`.
- **Recommended:** After C1 migration is complete, delete the five legacy functions from the module. Verify zero remaining callers first with `Select-String -Path scripts,modules -Pattern 'Write-SouliTEK(Result|Info|Success|Warning|Error)' -Recurse`.
- **Risk if changed:** Low after C1 sweep is verified.
- **Target phase:** P1

### C3 — `Get-WmiObject` (removed in PS 7)
- **Severity:** high
- **Category:** legacy-api
- **Files affected:** `scripts/driver_integrity_scan.ps1`, `scripts/product_key_retriever.ps1`
- **Current:**
  ```powershell
  Get-WmiObject -Class Win32_PnPSignedDriver
  Get-WmiObject -Class Win32_OperatingSystem
  ```
- **Recommended:**
  ```powershell
  Get-CimInstance -ClassName Win32_PnPSignedDriver
  Get-CimInstance -ClassName Win32_OperatingSystem
  ```
- **Risk if changed:** Low. `Get-CimInstance` is available since PS 3.0. Property names match. Validate on Win 10 + Win 11 since CIM uses DCOM/WSMan rather than DCOM-only.
- **Target phase:** P1

### C4 — `-ErrorAction SilentlyContinue` swallowing failures
- **Severity:** med (per-occurrence variable — some uses are legitimate)
- **Category:** error-handling
- **Files affected:** 30 scripts; 186 occurrences total
- **Triage tags** (each per-file audit applies one tag per occurrence):
  - **A — legitimate cleanup:** "delete temp file if exists, don't care otherwise." Keep, add `# safe: cleanup` comment.
  - **B — was swallowing a real bug:** Replace with `try { ... } catch { Write-Ui -Message "..." -Level "WARN" }`.
  - **C — failure must halt:** Replace with `try { ... } catch { ... ; exit 1 }` or remove `SilentlyContinue` so the script throws.
- **Recommended:** Per-file audits enumerate occurrences with tag A/B/C. Phase P2 applies the tags.
- **Risk if changed:** Medium — by definition this changes error-surfacing behavior. Aligns with CLAUDE.md "fail closed — deny by default."
- **Target phase:** P2

### C5 — Destructive scripts lack `[CmdletBinding(SupportsShouldProcess)]` + `-WhatIf`/`-Confirm`
- **Severity:** high
- **Category:** safety
- **Files affected:** `essential_tweaks.ps1`, `win11_debloat.ps1`, `temp_removal_disk_cleanup.ps1`, `mcafee_removal_tool.ps1`, `network_configuration_tool.ps1`, `create_system_restore_point.ps1`, `printer_spooler_fix.ps1` (added per its audit's F3 — Stop-Service Spooler + Remove-Item spool + Register-ScheduledTask SYSTEM)
- **Current:** Scripts mutate system state (registry, services, files, network adapters) without offering `-WhatIf` to preview or `-Confirm` to gate per-action.
- **Recommended:**
  ```powershell
  [CmdletBinding(SupportsShouldProcess, ConfirmImpact='High')]
  param( ... )
  if ($PSCmdlet.ShouldProcess('HKLM:\Software\Foo', 'Set Bar = 1')) {
      Set-ItemProperty -Path 'HKLM:\Software\Foo' -Name Bar -Value 1
  }
  ```
- **Risk if changed:** Medium — surface area is wide, but the safety win is large. Default behavior preserved when caller passes neither `-WhatIf` nor `-Confirm`.
- **Target phase:** P3

### C6 — Scripts >1000 LOC with extractable duplication
- **Severity:** med
- **Category:** structure
- **Files affected:** 10 scripts >1000 LOC: `EventLogAnalyzer` (2275), `startup_boot_analyzer` (1762), `license_expiration_checker` (1385), `m365_user_list` (1297), `ram_slot_utilization_report` (1195), `temp_removal_disk_cleanup` (1022), `onedrive_status_checker` (1029), `virustotal_checker` (1048), `usb_device_log` (1012), `sharepoint_site_inventory` (1009). (`domain_dns_analyzer` was on this list at 1721 LOC; removed from the repo in commit `3986797`.)
- **Recommended:** Each per-script audit identifies extract candidates (e.g. drive enumeration, parallel scanning, table rendering). Module gains `MODERNIZATION HELPERS` section in P4.
- **Risk if changed:** High — large surface; behavior must be preserved by tests added in P5.
- **Target phase:** P4

### C7 — Pester coverage gap
- **Severity:** med
- **Category:** tests
- **Files affected:** All. Current coverage: 1/26 module functions (`Test-SafeFilePath` only).
- **Recommended:** Per-module function tests + per-script smoke tests (dot-source cleanly, `-WhatIf` produces no side effects where applicable).
- **Risk if changed:** Low (adds files, no behavior change).
- **Target phase:** P5

### C8 — No PSScriptAnalyzer enforcement, no CI
- **Severity:** med
- **Category:** tooling
- **Files affected:** repo root (`.github/workflows/`, `PSScriptAnalyzerSettings.psd1`)
- **Current:** `CONTRIBUTING.md` mentions PSScriptAnalyzer but nothing enforces it.
- **Recommended:** `.github/workflows/ci.yml` runs `Invoke-ScriptAnalyzer` over `scripts/`, `modules/`, `launcher/`, `Install-SouliTEK.ps1` plus `Invoke-Pester` over `tests/`. Baseline existing analyzer errors in `docs/audits/ANALYZER-BASELINE.md` so CI fails only on *new* errors initially.
- **Risk if changed:** Low.
- **Target phase:** P0

### C9 — Naming drift: PascalCase scripts violate `lowercase_with_underscores` rule
- **Severity:** low
- **Category:** naming
- **Files affected:** `scripts/SouliTEK-Choco-Installer.ps1`, `scripts/SouliTEK-Softwares-Installer.ps1`, plus launcher reference (`launcher/SouliTEK-Launcher-WPF.ps1` `$Script:Tools` array)
- **Recommended:** `SouliTEK-Softwares-Installer.ps1` → `softwares_installer.ps1` (rename via `git mv` to preserve history; update launcher entries; update `docs/*.md` cross-references). `SouliTEK-Choco-Installer.ps1` → **DELETE** (per its audit: not referenced by launcher, dead code since 2025-11-22; was deleted then accidentally re-added in an unrelated commit; also calls `Show-ScriptBanner`/`Write-Ui` without dot-sourcing the common module so it would throw on a clean shell).
- **Risk if changed:** Low. Verify the launcher launches the renamed `softwares_installer.ps1` after the change. Confirm no other repo file references `SouliTEK-Choco-Installer.ps1` before deletion.
- **Target phase:** P1

### C10 — `Import SouliTEK Common Functions` boilerplate duplicated 35×
- **Severity:** low
- **Category:** structure
- **Files affected:** All 35 scripts
- **Current pattern (5–9 lines, repeated):**
  ```powershell
  $CommonPath = Join-Path (Split-Path -Parent $PSScriptRoot) "modules\SouliTEK-Common.ps1"
  if (Test-Path $CommonPath) { . $CommonPath } else { Write-Warning "..."; ... }
  ```
- **Recommended:** Add `Import-SouliTEKCommon` helper to the module (yes, a chicken-and-egg — the helper itself must be in `SouliTEK-Common.ps1`, but scripts then dot-source via a single one-liner). Realistically: leave this as a `P4` style consolidation; the savings are small.
- **Risk if changed:** Low but high churn touching every script.
- **Target phase:** P4

### C11 — Banner/disclaimer block duplicated at top of every script
- **Severity:** low
- **Category:** docs
- **Files affected:** All 35 scripts
- **Current:** ~25–35 lines of copyright/disclaimer/feature blurb at the top of each script.
- **Recommended:** Collapse to a 3-line standard header + reference to `LICENSE` and `STYLE_GUIDE.md`. The legal disclaimer for WiFi/Product-Key/USB-history-style scripts stays inline (those have legitimate legal-notice requirements).
- **Risk if changed:** Low (cosmetic).
- **Target phase:** P4

### C12 — Installer downloads ZIP without mandatory hash verification by default
- **Severity:** high
- **Category:** security
- **Files affected:** `Install-SouliTEK.ps1`, `api/install.js`, `hosting/install-proxy.php`
- **Current:** `Install-SouliTEK.ps1` accepts `-ExpectedZipHash` but defaults to empty string; if empty, the hash check is skipped and the ZIP is trusted unconditionally.
- **Recommended:** Two changes:
  1. Publish a signed manifest URL (`manifest.json` with the current release's SHA256 + version).
  2. Make the installer fetch the manifest and require the hash check; only `-Silent` + `-SkipHashCheck` (new switch) bypasses, and only with an explicit warning logged.
- **Risk if changed:** Medium — installer flow change. Test on a non-prod machine.
- **Target phase:** P6

### C13 — Sequential `foreach` over large datasets where parallelism would help
- **Severity:** low (perf)
- **Category:** perf
- **Files affected:** Candidates: `disk_usage_analyzer.ps1` (folder scan), `EventLogAnalyzer.ps1` (per-log enumeration), `browser_plugin_checker.ps1` (per-extension scan). (`domain_dns_analyzer.ps1` was on this list — script removed from the repo in commit `3986797`.)
- **Current:** Sequential loops. `ForEach-Object -Parallel` is PS-7-only and outside the floor.
- **Recommended:** Add `Invoke-SouliTEKParallel` runspace-pool helper to the common module (PS 5.1-compatible). Per-script audits identify the loop and the expected speedup. **Do not refactor until the module helper exists** (P4 dependency).
- **Risk if changed:** Medium — concurrency bugs are real. Helper must include max-thread cap + cancellation token.
- **Target phase:** P4

### C14 — `netsh wlan` shelling out
- **Severity:** info (note only — no change recommended)
- **Category:** legacy-api
- **Files affected:** `wifi_password_viewer.ps1`, `wifi_monitor.ps1`
- **Current:** `netsh wlan show profiles`, `netsh wlan show profile name="X" key=clear`.
- **Recommended:** **No change.** There is no PowerShell-native cmdlet that exposes the saved WLAN key. `netsh` remains the pragmatic answer. Per-file audits should note this with a `// keep` flag, not raise as a finding to fix.
- **Risk if changed:** N/A.
- **Target phase:** —
