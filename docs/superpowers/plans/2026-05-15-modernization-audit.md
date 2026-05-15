# Modernization Audit — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Produce 40 audit markdown files (1 README index + 1 cross-cutting + 1 module + 1 installer + 36 per-script) under `docs/audits/`, following the template defined in `docs/superpowers/specs/2026-05-15-modernize-roadmap-design.md` §3, plus a final summary linked from the roadmap.

**Architecture:** Docs-only deliverable. Each audit file is written by reading the target artifact, identifying findings (with file:line citations and code excerpts), tagging them against the cross-cutting findings list (`C1`–`C14`) or adding script-local findings (`F1+`), and committing after each file. No source code is added — validation is inline `Select-String` checks per task.

**Tech Stack:** Plain markdown. Validation via PowerShell `Select-String` / `Test-Path`. Git for commits.

**Spec:** `docs/superpowers/specs/2026-05-15-modernize-roadmap-design.md`

---

## File Structure

```
docs/audits/
├── README.md                              # Index/TOC for all 38 audits + grade table
├── 00-cross-cutting.md                    # C1–C14 findings (canonical, others reference these)
├── 01-modules-SouliTEK-Common.md          # Common module audit
├── 02-Install-SouliTEK.md                 # Installer + hosting/* + api/* proxies
├── scripts-1-click_pc_install.md
├── scripts-battery_report_generator.md
├── scripts-bitlocker_status_report.md
├── scripts-browser_plugin_checker.md
├── scripts-bsod_history_scanner.md
├── scripts-create_system_restore_point.md
├── scripts-disk_usage_analyzer.md
├── scripts-domain_dns_analyzer.md
├── scripts-driver_integrity_scan.md
├── scripts-essential_tweaks.md
├── scripts-EventLogAnalyzer.md
├── scripts-exchange_calendar_permissions_audit.md
├── scripts-FindPST.md
├── scripts-license_expiration_checker.md
├── scripts-local_admin_checker.md
├── scripts-m365_exchange_online.md
├── scripts-m365_user_list.md
├── scripts-mcafee_removal_tool.md
├── scripts-network_configuration_tool.md
├── scripts-network_test_tool.md
├── scripts-onedrive_status_checker.md
├── scripts-printer_spooler_fix.md
├── scripts-product_key_retriever.md
├── scripts-ram_slot_utilization_report.md
├── scripts-sharepoint_site_inventory.md
├── scripts-software_updater.md
├── scripts-SouliTEK-Choco-Installer.md
├── scripts-SouliTEK-Softwares-Installer.md
├── scripts-startup_boot_analyzer.md
├── scripts-storage_health_monitor.md
├── scripts-temp_removal_disk_cleanup.md
├── scripts-usb_device_log.md
├── scripts-virustotal_checker.md
├── scripts-wifi_monitor.md
├── scripts-wifi_password_viewer.md
└── scripts-win11_debloat.md

docs/superpowers/specs/
└── 2026-05-15-modernize-roadmap-design.md  # MODIFY: append §10 audit-summary table after all audits written
```

Each per-script audit file is one self-contained artifact. The cross-cutting file is canonical — script audits reference `C1`–`C14` rather than re-stating findings.

**Total files created: 40 (1 README + 39 audits). Files modified: 1 (roadmap spec, final task only).**

---

## Audit Workflow Convention

Every per-file audit follows this exact 5-step loop. Tasks 5–39 cite this section by name to keep the plan DRY without using "similar to Task N" placeholders.

### THE AUDIT LOOP (followed by every audit task)

1. **Inventory** — Run from repo root to populate the Inventory table:
   ```powershell
   $f = '<relative-path>'
   $loc = (Get-Content $f | Measure-Object -Line).Lines
   $fn  = (Select-String -Path $f -Pattern '^\s*function\s+\w' | Measure-Object).Count
   $req = (Select-String -Path $f -Pattern '^#Requires').Line
   $sha = git log -n 1 --format='%h — %ad' --date=short -- $f
   "LOC=$loc Functions=$fn Requires='$req' LastCommit='$sha'"
   ```

2. **Scan against cross-cutting list** — For each `C1`..`C14` finding in `docs/audits/00-cross-cutting.md`, decide whether it applies to this file. If yes, add a Finding entry that **references the cross-cutting ID** and adds only the local detail (line numbers, code excerpt). Do **not** restate the recommendation; the cross-cutting file owns that.

3. **Local findings** — Walk the file top-to-bottom looking for issues *not* covered by cross-cutting:
   - Hard-coded paths / magic numbers
   - Duplicate logic that could move to the common module
   - Dead code / commented-out blocks
   - Help-block (`.SYNOPSIS`) gaps
   - Missing `param()` blocks, unvalidated user input
   - PS-7-only constructs (`??`, `?.`, ternary, `ForEach-Object -Parallel`) — none are allowed at the 5.1 floor
   - `Get-WmiObject` (covered by C3 — apply C3, don't re-create)
   - `netsh wlan` (covered by C14 — note only, no recommended change)

4. **Write the audit file** using the template from spec §3 (`docs/superpowers/specs/2026-05-15-modernize-roadmap-design.md` §3). The template structure is reproduced inline at the bottom of this plan in the appendix.

5. **Inline-validate, then commit**:
   ```powershell
   $out = '<docs/audits/...md>'
   $missing = @('## Inventory','## Summary','## Findings','## Out-of-scope notes') |
              Where-Object { -not (Select-String -Path $out -Pattern "^$_$" -SimpleMatch -Quiet) }
   if ($missing) { throw "Missing sections in $out: $($missing -join ', ')" }
   git add $out
   git commit -m "docs(audit): add $(Split-Path $out -Leaf)"
   ```

If the validator throws, fix the file and re-run before committing.

---

## Phase Map (informational — drives task ordering)

| Task # | Phase | What it produces |
|---|---|---|
| 1     | Scaffold | `docs/audits/README.md` index + empty per-file stubs |
| 2     | Canonical | `00-cross-cutting.md` (C1–C14 expanded) |
| 3     | Foundation | Module audit |
| 4     | Foundation | Installer + proxies audit |
| 5     | Reference | First per-script audit (full canonical task; reference for the rest) |
| 6–11  | D-grade scripts | 6 highest-risk scripts |
| 12–22 | C-grade scripts | 11 scripts |
| 23–39 | A/B-grade scripts | 17 scripts |
| 40    | Wrap-up | Audit summary table + roadmap spec update |

---

## Task 1: Scaffold `docs/audits/` with index README + empty stubs

**Files:**
- Create: `docs/audits/README.md`
- Create: 38 empty stub files (`00-cross-cutting.md`, `01-...`, `02-...`, and `scripts-*.md` for all 35 scripts)

- [ ] **Step 1: Create the index README**

Write `docs/audits/README.md`:

```markdown
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
```

- [ ] **Step 2: Create 38 empty stub files**

Run from repo root:
```powershell
$audits = @(
  '00-cross-cutting','01-modules-SouliTEK-Common','02-Install-SouliTEK',
  'scripts-1-click_pc_install','scripts-battery_report_generator','scripts-bitlocker_status_report',
  'scripts-browser_plugin_checker','scripts-bsod_history_scanner','scripts-create_system_restore_point',
  'scripts-disk_usage_analyzer','scripts-domain_dns_analyzer','scripts-driver_integrity_scan',
  'scripts-essential_tweaks','scripts-EventLogAnalyzer','scripts-exchange_calendar_permissions_audit',
  'scripts-FindPST','scripts-license_expiration_checker','scripts-local_admin_checker',
  'scripts-m365_exchange_online','scripts-m365_user_list','scripts-mcafee_removal_tool',
  'scripts-network_configuration_tool','scripts-network_test_tool','scripts-onedrive_status_checker',
  'scripts-printer_spooler_fix','scripts-product_key_retriever','scripts-ram_slot_utilization_report',
  'scripts-sharepoint_site_inventory','scripts-software_updater','scripts-SouliTEK-Choco-Installer',
  'scripts-SouliTEK-Softwares-Installer','scripts-startup_boot_analyzer','scripts-storage_health_monitor',
  'scripts-temp_removal_disk_cleanup','scripts-usb_device_log','scripts-virustotal_checker',
  'scripts-wifi_monitor','scripts-wifi_password_viewer','scripts-win11_debloat'
)
foreach ($a in $audits) {
    $p = "docs/audits/$a.md"
    if (-not (Test-Path $p)) {
        "# Audit — $a`n`n_TBD — populated by later task._" | Set-Content -Path $p -Encoding UTF8
    }
}
"Created: $((Get-ChildItem docs/audits -Filter *.md | Measure-Object).Count) files"
```

Expected output: `Created: 40 files` (39 audits + README).

- [ ] **Step 3: Commit**

```powershell
git add docs/audits/
git commit -m "docs(audit): scaffold audits/ index + 38 empty stubs"
```

---

## Task 2: Write canonical `00-cross-cutting.md`

**Files:**
- Modify: `docs/audits/00-cross-cutting.md` (replace stub)

This file is THE canonical source for C1–C14. Every per-script audit will cite these IDs. Write it before any per-script audit.

- [ ] **Step 1: Replace the stub with the canonical findings file**

Write `docs/audits/00-cross-cutting.md`:

```markdown
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
- **Files affected:** `essential_tweaks.ps1`, `win11_debloat.ps1`, `temp_removal_disk_cleanup.ps1`, `mcafee_removal_tool.ps1`, `network_configuration_tool.ps1`, `create_system_restore_point.ps1`
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
- **Files affected:** 8 scripts >1000 LOC: `EventLogAnalyzer` (2275), `startup_boot_analyzer` (1762), `domain_dns_analyzer` (1721), `license_expiration_checker` (1385), `m365_user_list` (1297), `ram_slot_utilization_report` (1195), `temp_removal_disk_cleanup` (1022), `onedrive_status_checker` (1029), `virustotal_checker` (1048), `usb_device_log` (1012), `sharepoint_site_inventory` (1009)
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
- **Recommended:** Rename to `chocolatey_installer.ps1` and `softwares_installer.ps1`. Update launcher entries. Update `docs/*.md` cross-references. Use `git mv` to preserve history.
- **Risk if changed:** Low. Verify the launcher launches the renamed tools after the change.
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
- **Files affected:** Candidates: `disk_usage_analyzer.ps1` (folder scan), `domain_dns_analyzer.ps1` (per-record DNS lookups), `EventLogAnalyzer.ps1` (per-log enumeration), `browser_plugin_checker.ps1` (per-extension scan).
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
```

- [ ] **Step 2: Validate the file has all required sections**

```powershell
$out = 'docs/audits/00-cross-cutting.md'
$expected = @('### C1','### C2','### C3','### C4','### C5','### C6','### C7','### C8','### C9','### C10','### C11','### C12','### C13','### C14')
$missing = $expected | Where-Object { -not (Select-String -Path $out -Pattern $_ -SimpleMatch -Quiet) }
if ($missing) { throw "Missing in ${out}: $($missing -join ', ')" } else { 'OK: all 14 IDs present' }
```

Expected output: `OK: all 14 IDs present`

- [ ] **Step 3: Commit**

```powershell
git add docs/audits/00-cross-cutting.md
git commit -m "docs(audit): expand cross-cutting findings (C1-C14)"
```

---

## Task 3: Audit `modules/SouliTEK-Common.ps1`

**Files:**
- Read: `modules/SouliTEK-Common.ps1` (1416 LOC)
- Modify: `docs/audits/01-modules-SouliTEK-Common.md` (replace stub)

**Known hotspots to investigate (from spec exploration):**
- `Write-SouliTEKResult` + 4 wrappers — dead duplicate API (C2)
- `Test-SafeFilePath` — well-implemented, fail-closed, has Pester tests (good example, mention in Summary)
- `Set-SouliTEKConsoleColor` — switch maps "Blue" → "Cyan" (likely a stale alias; flag as dead code)
- `Install-SouliTEKModule` — many `Write-Ui` calls embed `[*]`/`[+]`/`[-]`/`[!]` prefixes inside the message (double-marker — STYLE_GUIDE.md says level brackets only). Flag.
- No `Invoke-SouliTEKParallel` helper exists yet — flag as gap for P4 (referenced by C13)
- No `Import-SouliTEKCommon` helper exists yet — flag as gap for P4 (referenced by C10)
- 1416 LOC — possibly worth splitting into `SouliTEK-Common-Output.ps1` / `SouliTEK-Common-Reports.ps1` / `SouliTEK-Common-Modules.ps1`. Note as P4 candidate.

- [ ] **Step 1: Follow the audit loop steps 1–4** (see "THE AUDIT LOOP" above), writing the file from the template in appendix A.

  Specifically populate these sections for this file:
  - **Inventory** — LOC=1416, function count from `grep -c '^function '`, requires from line 1 (none — module dot-sourced).
  - **Summary** — One paragraph: "The common module is the foundation everything else depends on. It already implements the unified output API (`Write-Ui`), DPAPI-encrypted secret storage, branded HTML/TXT/CSV exports, SHA256 hash verification, and the fail-closed `Test-SafeFilePath` helper. Its biggest issues are the dead `Write-SouliTEKResult` duplicate API still present (C2), embedded marker prefixes in `Install-SouliTEKModule` messages, and missing helpers (`Invoke-SouliTEKParallel`, `Import-SouliTEKCommon`) that downstream phases will need."
  - **Findings:**
    - `F1` — Reference `C2` (dead Write-SouliTEKResult), point at the function definitions and the four wrappers.
    - `F2` — Local: `Install-SouliTEKModule` embeds `[*]`/`[+]`/`[-]`/`[!]` markers inside `Write-Ui` messages (double-marker). List the lines. Recommended: remove the inline markers; the `[LEVEL]` bracket from `Write-Ui` is the marker.
    - `F3` — Local: `Set-SouliTEKConsoleColor` maps `Blue → Cyan` (likely stale). Verify no callers depend on the bug; if none, remove the function (P4).
    - `F4` — Gap: no `Invoke-SouliTEKParallel` helper exists. P4 needs it for C13.
    - `F5` — Gap: no `Import-SouliTEKCommon` helper exists. P4 needs it for C10.
    - `F6` — Structure: 1416 LOC. Consider splitting into themed files. P4.
    - `F7` — Tests: Only `Test-SafeFilePath` has Pester coverage (C7). Enumerate the 25 untested functions in this audit.
  - **Out-of-scope notes** — `Test-SafeFilePath` is exemplary; `Confirm-SouliTEKFileHash` and `Protect-SouliTEKSecret`/`Unprotect-SouliTEKSecret` are well-implemented and need no change.

- [ ] **Step 2: Validate and commit (audit loop step 5)**

```powershell
$out = 'docs/audits/01-modules-SouliTEK-Common.md'
$missing = @('## Inventory','## Summary','## Findings','## Out-of-scope notes') |
           Where-Object { -not (Select-String -Path $out -Pattern "^$_$" -SimpleMatch -Quiet) }
if ($missing) { throw "Missing in ${out}: $($missing -join ', ')" } else { 'OK' }
git add $out
git commit -m "docs(audit): add 01-modules-SouliTEK-Common.md"
```

---

## Task 4: Audit `Install-SouliTEK.ps1` + `hosting/*` + `api/*`

**Files:**
- Read: `Install-SouliTEK.ps1`, `api/install.js`, `hosting/install-proxy.php`, `hosting/.htaccess-redirect`, `hosting/README.md`
- Modify: `docs/audits/02-Install-SouliTEK.md` (replace stub)

**Known hotspots:**
- `-ExpectedZipHash` defaults to `""`; hash check is skipped if empty → C12.
- Hard-coded `RepoOwner`/`RepoName`/`Branch` — flag if any concern about supply-chain swap. Probably fine because GitHub repo path is the trust anchor.
- Vercel `api/install.js` proxy — review for redirect injection, cache headers.
- PHP `hosting/install-proxy.php` — review for path traversal, response splitting, rate limit (CHANGELOG planned item).
- TLS pinning is not standard for PS web-cmdlets; flag as accepted limitation.

- [ ] **Step 1: Follow the audit loop steps 1–4**, writing `02-Install-SouliTEK.md` from appendix A template.

  Sections:
  - **Inventory** — LOC for each of the 3 files; functions; PS version (5.1).
  - **Summary** — One paragraph covering: the installer is the single entry point users execute via `iwr | iex`, so its integrity is the foundation of every other security control in the repo. Hash verification is the headline gap (C12). Proxies are thin and mostly safe but lack rate limiting.
  - **Findings:**
    - `F1` — Reference `C12`; line of the `$ExpectedZipHash = ""` default.
    - `F2` — Local: `api/install.js` — check the response stream, CORS, cache-control. List any issue with file:line refs.
    - `F3` — Local: `hosting/install-proxy.php` — check input sanitization, rate-limit, error responses don't leak server paths.
    - `F4` — Local: installer's `Write-Error-Custom` is a custom function — flag as inconsistent with rest of repo. Recommended: use `Write-Ui -Level ERROR` once the common module is available; but installer runs before the module is downloaded, so it must keep its own minimal output helpers. Note this constraint inline.
    - `F5` — Tests: zero coverage on installer. P5 should add a "smoke" Pester test that runs `Install-SouliTEK.ps1 -WhatIf` (will require adding `SupportsShouldProcess` first, P3 scope).
  - **Out-of-scope notes** — `.htaccess-redirect` is trivial; document briefly.

- [ ] **Step 2: Validate and commit**

```powershell
$out = 'docs/audits/02-Install-SouliTEK.md'
$missing = @('## Inventory','## Summary','## Findings','## Out-of-scope notes') |
           Where-Object { -not (Select-String -Path $out -Pattern "^$_$" -SimpleMatch -Quiet) }
if ($missing) { throw "Missing in ${out}: $($missing -join ', ')" } else { 'OK' }
git add $out
git commit -m "docs(audit): add 02-Install-SouliTEK.md"
```

---

## Task 5 — REFERENCE TASK: Audit `scripts/driver_integrity_scan.ps1` (D-grade)

This task is the **canonical example** of a per-script audit. Subsequent per-script tasks abbreviate; if anything is unclear in a later task, re-read this one.

**Files:**
- Read: `scripts/driver_integrity_scan.ps1` (746 LOC)
- Modify: `docs/audits/scripts-driver_integrity_scan.md` (replace stub)

**Known hotspots:**
- Uses `Get-WmiObject` — C3 applies.
- Mix of `Write-Host` and `Write-Ui` — C1 applies; enumerate.
- Has `[CmdletBinding()]` — confirm whether it does fully (it's in the "Found 4 files" Grep result from exploration).
- 5 `-ErrorAction SilentlyContinue` occurrences — C4 applies; triage each.
- 74 `Write-Host` occurrences — C1 applies.

- [ ] **Step 1: Run the inventory commands**

```powershell
$f = 'scripts/driver_integrity_scan.ps1'
$loc = (Get-Content $f | Measure-Object -Line).Lines
$fn  = (Select-String -Path $f -Pattern '^\s*function\s+\w' | Measure-Object).Count
$req = (Select-String -Path $f -Pattern '^#Requires').Line
$sha = git log -n 1 --format='%h — %ad' --date=short -- $f
"LOC=$loc Functions=$fn Requires='$req' LastCommit='$sha'"
```

Note the output for the Inventory table.

- [ ] **Step 2: Scan for cross-cutting findings**

```powershell
# Check each applicable cross-cutting ID
Select-String -Path scripts/driver_integrity_scan.ps1 -Pattern 'Get-WmiObject'         | Select-Object LineNumber,Line  # C3
Select-String -Path scripts/driver_integrity_scan.ps1 -Pattern 'Write-Host'            | Measure-Object              # C1 count
Select-String -Path scripts/driver_integrity_scan.ps1 -Pattern 'SilentlyContinue'      | Select-Object LineNumber,Line  # C4
Select-String -Path scripts/driver_integrity_scan.ps1 -Pattern 'CmdletBinding'         | Select-Object LineNumber,Line  # C5 check
```

- [ ] **Step 3: Read the script in full and identify local findings**

Look for:
- Functions >100 LOC that could split
- Hard-coded paths (`C:\...`)
- Magic numbers (timeouts, sizes)
- Dead code / commented blocks
- `.SYNOPSIS` gaps on functions
- Missing `param()` validation on user-facing inputs

- [ ] **Step 4: Write the audit file**

Write `docs/audits/scripts-driver_integrity_scan.md` following the appendix A template. Key sections:

```markdown
# Audit — scripts/driver_integrity_scan.ps1

## Inventory
| Item | Value |
|---|---|
| Path           | scripts/driver_integrity_scan.ps1 |
| LOC            | 746 |
| Functions      | <from step 1> |
| `#Requires`    | Version 5.1 |
| Admin-required | yes (driver signature query) |
| Last touched   | <from step 1> |
| Modernization grade | D |

## Summary
Driver integrity scanner using `Get-WmiObject Win32_PnPSignedDriver`. Grade D solely because of C3 (legacy WMI API that breaks on PS 7); otherwise the script is reasonably structured. C1 (Write-Host) applies broadly. Recommended phase: P1 (C3 fix) followed by P1 (C1 sweep).

## Findings

### F1 — Legacy `Get-WmiObject` (see C3)
- **Severity:** high
- **Category:** legacy-api
- **Location:** scripts/driver_integrity_scan.ps1:<line>, <line>, <line> (3 occurrences)
- **Reference:** [C3](00-cross-cutting.md#c3--get-wmiobject-removed-in-ps-7)
- **Local notes:** All three calls target Win32_PnPSignedDriver. `Get-CimInstance` returns the same property shape; spot-check `IsSigned`, `DeviceClass`, `DeviceName` post-swap.
- **Target phase:** P1

### F2 — Mixed `Write-Host` / `Write-Ui` (see C1)
- **Severity:** med
- **Category:** output-style
- **Location:** scripts/driver_integrity_scan.ps1:74 raw Write-Host occurrences
- **Reference:** [C1](00-cross-cutting.md#c1--raw-write-host-calls-not-migrated)
- **Local notes:** Most Write-Host calls are inside the report-rendering function; the message text and color mapping is straightforward.
- **Target phase:** P1

### F3 — `-ErrorAction SilentlyContinue` triage (see C4)
- **Severity:** med
- **Category:** error-handling
- **Location:** 5 occurrences — line refs from step 2
- **Reference:** [C4](00-cross-cutting.md#c4--erroraction-silentlycontinue-swallowing-failures)
- **Triage:**
  - Line <X>: tag A (cleanup of optional output file)
  - Line <Y>: tag B (swallowing WMI failure → should warn)
  - Line <Z>: tag B
  - Line <…>: tag …
- **Target phase:** P2

### F4 — (local — example: hard-coded timeout)
- **Severity:** low
- **Category:** structure
- **Location:** scripts/driver_integrity_scan.ps1:<line>
- **Current:**
  ```powershell
  $timeout = 30  # magic number
  ```
- **Recommended:**
  ```powershell
  param( [int]$TimeoutSeconds = 30 )
  ```
- **Risk if changed:** Low.
- **Target phase:** P4

## Out-of-scope notes
- Function decomposition is reasonable; no decomposition recommended.
- Banner block matches C11; covered there.
```

Fill in `<line>` placeholders from the actual `Select-String` output. Don't leave any `<…>` in the committed file.

- [ ] **Step 5: Validate and commit**

```powershell
$out = 'docs/audits/scripts-driver_integrity_scan.md'
$missing = @('## Inventory','## Summary','## Findings','## Out-of-scope notes') |
           Where-Object { -not (Select-String -Path $out -Pattern "^$_$" -SimpleMatch -Quiet) }
if ($missing) { throw "Missing in ${out}: $($missing -join ', ')" } else { 'OK' }
# Verify no leftover angle-bracket placeholders
if (Select-String -Path $out -Pattern '<[a-z…\.]+>' -Quiet) {
    throw "Unresolved placeholders in $out"
}
git add $out
git commit -m "docs(audit): add scripts-driver_integrity_scan.md"
```

---

## Tasks 6–11: D-grade scripts

Each task follows **THE AUDIT LOOP** (above). Inventory commands, scan commands, and the template (appendix A) are identical to Task 5. Per-script hotspots below are the specific things to look for.

### Task 6: `scripts/product_key_retriever.ps1`

**Predicted grade:** D
**Hotspots:** `Get-WmiObject` (C3, 2 occurrences). `Write-Host` (29 occurrences, C1). 11 `SilentlyContinue` (C4 — many likely tag A around registry probes that may be missing). Inspect: registry path access permissions on Win 11. `.SYNOPSIS` block quality on the public functions.

- [ ] Run the audit loop on `scripts/product_key_retriever.ps1` → `docs/audits/scripts-product_key_retriever.md`. Commit `docs(audit): add scripts-product_key_retriever.md`.

### Task 7: `scripts/EventLogAnalyzer.ps1`

**Predicted grade:** D
**Hotspots:** 2275 LOC — largest in repo (C6). 139 `Write-Host` (C1). 3 `SilentlyContinue` (C4). 41 functions — verify cohesion. Inspect: per-log enumeration loop (C13 candidate). Has `[CmdletBinding]` somewhere — confirm coverage. Likely candidates for extraction: HTML rendering, statistical summary generator, log-source enumerator.

- [ ] Run the audit loop → `docs/audits/scripts-EventLogAnalyzer.md`. List the largest 5 functions by LOC in the audit; flag them as P4 extract candidates. Commit `docs(audit): add scripts-EventLogAnalyzer.md`.

### Task 8: `scripts/printer_spooler_fix.ps1`

**Predicted grade:** D
**Hotspots:** 243 `Write-Host` — by far the largest mixed-output script (C1). 7 `SilentlyContinue` (C4). 746 LOC. Inspect: service-restart logic — does it use `Restart-Service` cleanly or shell out? Spool folder cleanup — destructive, but small in scope. May not need `ShouldProcess` (re-classify if it's actually destructive enough — bump to C5 list if so).

- [ ] Run the audit loop → `docs/audits/scripts-printer_spooler_fix.md`. **If the script mutates `C:\Windows\System32\spool\PRINTERS\` or stops/restarts services, add it to C5's affected-files list** in this audit's Findings (note: the cross-cutting file itself is updated in a later task, Task 40). Commit `docs(audit): add scripts-printer_spooler_fix.md`.

### Task 9: `scripts/essential_tweaks.ps1`

**Predicted grade:** D
**Hotspots:** Destructive (C5 — registry tweaks, default-app changes, keyboard/locale). 28 `Write-Host` (C1). 2 `SilentlyContinue` (C4). 666 LOC. Inspect: every `Set-ItemProperty` / `New-ItemProperty` call needs `ShouldProcess` wrapping in P3. List each mutation site in the audit.

- [ ] Run the audit loop → `docs/audits/scripts-essential_tweaks.md`. **Enumerate every mutation site** (Set-ItemProperty, New-ItemProperty, Remove-Item, Set-WinUserLanguageList, Set-Culture, Add-LocalUser, Disable-WindowsOptionalFeature, etc.) in the Findings under a single F entry titled "Mutation sites needing `ShouldProcess` (see C5)". Commit `docs(audit): add scripts-essential_tweaks.md`.

### Task 10: `scripts/win11_debloat.ps1`

**Predicted grade:** D
**Hotspots:** Destructive (C5). 61 `Write-Host` (C1). 287 LOC (smallest D candidate). Inspect: `Get-AppxPackage … | Remove-AppxPackage` is the main mutation. Telemetry-disable registry writes. Defender exclusions (potential concern? — if it modifies Defender settings, flag for security review).

- [ ] Run the audit loop → `docs/audits/scripts-win11_debloat.md`. **Enumerate every package removed and every registry value set.** If any Defender-related setting is touched, raise as a high-severity local finding (separate from C5). Commit `docs(audit): add scripts-win11_debloat.md`.

### Task 11: `scripts/mcafee_removal_tool.ps1`

**Predicted grade:** D
**Hotspots:** Destructive (C5). 65 `Write-Host` (C1). Runs `tools/MCPR.exe` — a third-party binary. 263 LOC. Inspect: MCPR.exe invocation — is the path validated with `Test-SafeFilePath`? Is the hash verified before execution? Privileged execution context. The binary is committed to the repo (`tools/MCPR.exe`) — note its origin and last-update date if discoverable from git.

- [ ] Run the audit loop → `docs/audits/scripts-mcafee_removal_tool.md`. **Add a local finding `F_supply_chain`**: tools/MCPR.exe is a vendored binary; recommend adding it to `Confirm-SouliTEKFileHash` verification on every run. Commit `docs(audit): add scripts-mcafee_removal_tool.md`.

---

## Tasks 12–22: C-grade scripts

Each task follows **THE AUDIT LOOP**. Hotspots listed per script.

### Task 12: `scripts/1-click_pc_install.ps1`

**Predicted grade:** C
**Hotspots:** 954 LOC; 68 `Write-Host` (C1); 10 `SilentlyContinue` (C4); orchestrates many destructive sub-steps (locale, timezone, WinGet installs, bloatware removal) — C5 applies in spirit but the script delegates to sub-tools that should each carry their own `ShouldProcess`. Inspect: WinGet calls — exit code handling, error parsing (recent commit `b79d132` added this). System restore creation is well-isolated.

- [ ] Run the audit loop → `docs/audits/scripts-1-click_pc_install.md`. Commit `docs(audit): add scripts-1-click_pc_install.md`.

### Task 13: `scripts/create_system_restore_point.ps1`

**Predicted grade:** C
**Hotspots:** Destructive (creates restore point — registry + system state). 34 `Write-Host` (C1). 3 `SilentlyContinue` (C4). 393 LOC. C5 borderline — creating a restore point is mostly safe but enabling restore-protection on a drive that didn't have it counts as a side-effect; flag.

- [ ] Run the audit loop → `docs/audits/scripts-create_system_restore_point.md`. Commit `docs(audit): add scripts-create_system_restore_point.md`.

### Task 14: `scripts/disk_usage_analyzer.ps1`

**Predicted grade:** C
**Hotspots:** 789 LOC; 84 `Write-Host` (C1); 3 `SilentlyContinue` (C4); folder-tree scan is sequential — C13 candidate. Inspect: `Get-ChildItem -Recurse -ErrorAction SilentlyContinue` patterns — many `SilentlyContinue` here are legitimate (denied folders) → mostly tag A.

- [ ] Run the audit loop → `docs/audits/scripts-disk_usage_analyzer.md`. Commit `docs(audit): add scripts-disk_usage_analyzer.md`.

### Task 15: `scripts/domain_dns_analyzer.ps1`

**Predicted grade:** C
**Hotspots:** 1721 LOC (second largest, C6); 216 `Write-Host` (C1, second highest); 9 `SilentlyContinue` (C4); per-record DNS lookups are sequential — C13 candidate. Uses `tools/whois.exe` — vendored binary; recommend hash verification (like MCPR). Inspect: WHOIS output parsing — regex patterns; SPF/DKIM/DMARC analysis.

- [ ] Run the audit loop → `docs/audits/scripts-domain_dns_analyzer.md`. **Add a local finding** `F_supply_chain` for tools/whois.exe (same pattern as MCPR). Commit `docs(audit): add scripts-domain_dns_analyzer.md`.

### Task 16: `scripts/license_expiration_checker.ps1`

**Predicted grade:** C
**Hotspots:** 1385 LOC (C6); 187 `Write-Host` (C1); 2 `SilentlyContinue` (C4). Microsoft Graph dependency — uses `Install-SouliTEKModule` from the common module (good). Inspect: license-name mapping table — likely a large hard-coded hashtable that could move to a JSON file under `config/`.

- [ ] Run the audit loop → `docs/audits/scripts-license_expiration_checker.md`. Commit `docs(audit): add scripts-license_expiration_checker.md`.

### Task 17: `scripts/m365_exchange_online.ps1`

**Predicted grade:** C
**Hotspots:** 961 LOC; 123 `Write-Host` (C1); 5 `SilentlyContinue` (C4). EXO PowerShell module dependency. Inspect: authentication flow — interactive vs delegated; mailbox enumeration paging.

- [ ] Run the audit loop → `docs/audits/scripts-m365_exchange_online.md`. Commit `docs(audit): add scripts-m365_exchange_online.md`.

### Task 18: `scripts/m365_user_list.ps1`

**Predicted grade:** C
**Hotspots:** 1297 LOC (C6); 127 `Write-Host` (C1); 16 `SilentlyContinue` (C4 — high count, triage carefully). Graph users + MFA status fetcher. Inspect: paging implementation; bulk MFA queries (potential C13 candidate — per-user Graph call is the bottleneck).

- [ ] Run the audit loop → `docs/audits/scripts-m365_user_list.md`. Commit `docs(audit): add scripts-m365_user_list.md`.

### Task 19: `scripts/network_configuration_tool.ps1`

**Predicted grade:** C
**Hotspots:** Destructive (C5 — static-IP, DNS-flush, adapter-reset). 110 `Write-Host` (C1). 7 `SilentlyContinue` (C4). 972 LOC. Inspect: `Set-NetIPAddress` / `Set-DnsClientServerAddress` / `Restart-NetAdapter` — each needs `ShouldProcess`. User input is parsed from menu — verify IP validation.

- [ ] Run the audit loop → `docs/audits/scripts-network_configuration_tool.md`. **Enumerate mutation sites** under a single F entry. Commit `docs(audit): add scripts-network_configuration_tool.md`.

### Task 20: `scripts/ram_slot_utilization_report.ps1`

**Predicted grade:** C
**Hotspots:** 1195 LOC (C6); 157 `Write-Host` (C1, third highest). Read-only via CIM. Inspect: result rendering is likely 60% of the code (extract candidate). Check whether it uses `Get-WmiObject` despite earlier reporting (Grep said only 2 files — confirm this one isn't on the list).

- [ ] Run the audit loop → `docs/audits/scripts-ram_slot_utilization_report.md`. Commit `docs(audit): add scripts-ram_slot_utilization_report.md`.

### Task 21: `scripts/startup_boot_analyzer.ps1`

**Predicted grade:** C
**Hotspots:** 1762 LOC (C6, second largest); 147 `Write-Host` (C1); 6 `SilentlyContinue` (C4). Inspect: event-log queries (overlap with EventLogAnalyzer? — possible code duplication, flag for shared helper); startup-program enumeration; HTML report rendering.

- [ ] Run the audit loop → `docs/audits/scripts-startup_boot_analyzer.md`. **Compare the event-log query function to `EventLogAnalyzer.ps1`** — if shared logic is present, raise a finding "duplicate event-log query helper across files" pointing at both line ranges. Commit `docs(audit): add scripts-startup_boot_analyzer.md`.

### Task 22: `scripts/temp_removal_disk_cleanup.ps1`

**Predicted grade:** D (likely; revise during audit)
**Hotspots:** Destructive (C5 — deletes temp files, clears Recycle Bin, browser caches). 39 `Write-Host` (C1). 13 `SilentlyContinue` (C4 — many tag A around per-file delete attempts). 1022 LOC. Inspect: every `Remove-Item` site needs `ShouldProcess` (P3). Browser-cache logic — paths must not allow user-controlled extension.

- [ ] Run the audit loop → `docs/audits/scripts-temp_removal_disk_cleanup.md`. **Enumerate every `Remove-Item` / `Clear-RecycleBin` / `Remove-CimInstance` site** under a single F entry. Confirm or revise the grade to D in the Inventory. Commit `docs(audit): add scripts-temp_removal_disk_cleanup.md`.

---

## Tasks 23–39: A/B-grade scripts

Each task follows **THE AUDIT LOOP**. These are predicted-lower-risk; many findings will be C1 + C4 references only with little local detail.

### Task 23: `scripts/battery_report_generator.ps1`

**Predicted grade:** B
**Hotspots:** 100 `Write-Host` (C1, 4th highest); 5 `SilentlyContinue` (C4); 563 LOC. Inspect: wraps `powercfg /batteryreport` — output parsing; HTML rendering.

- [ ] Run the audit loop → `docs/audits/scripts-battery_report_generator.md`. Commit `docs(audit): add scripts-battery_report_generator.md`.

### Task 24: `scripts/bitlocker_status_report.ps1`

**Predicted grade:** A
**Hotspots:** 123 `Write-Host` (C1); 589 LOC. Likely clean otherwise — uses `Get-BitLockerVolume` (native cmdlet). Recovery-key handling: confirm it's masked in stdout if not exported.

- [ ] Run the audit loop → `docs/audits/scripts-bitlocker_status_report.md`. Commit `docs(audit): add scripts-bitlocker_status_report.md`.

### Task 25: `scripts/browser_plugin_checker.ps1`

**Predicted grade:** B
**Hotspots:** 66 `Write-Host` (C1); 5 `SilentlyContinue` (C4); 872 LOC. Per-extension scan (C13 candidate). Inspect: extension-store JSON parsing; risk-scoring heuristics.

- [ ] Run the audit loop → `docs/audits/scripts-browser_plugin_checker.md`. Commit `docs(audit): add scripts-browser_plugin_checker.md`.

### Task 26: `scripts/bsod_history_scanner.ps1`

**Predicted grade:** B
**Hotspots:** 48 `Write-Host` (C1); 0 `SilentlyContinue` (good); 550 LOC. Inspect: minidump parsing; bugcheck-code mapping table (candidate for `config/bugcheck_codes.json`).

- [ ] Run the audit loop → `docs/audits/scripts-bsod_history_scanner.md`. Commit `docs(audit): add scripts-bsod_history_scanner.md`.

### Task 27: `scripts/exchange_calendar_permissions_audit.ps1`

**Predicted grade:** B
**Hotspots:** 38 `Write-Host` (C1); 2 `SilentlyContinue` (C4); 313 LOC. Smallest M365 script. Inspect: permission-walk logic.

- [ ] Run the audit loop → `docs/audits/scripts-exchange_calendar_permissions_audit.md`. Commit `docs(audit): add scripts-exchange_calendar_permissions_audit.md`.

### Task 28: `scripts/FindPST.ps1`

**Predicted grade:** B
**Hotspots:** 95 `Write-Host` (C1); 3 `SilentlyContinue` (C4 — likely tag A on denied folders); 788 LOC. File-system scan — sequential, C13 candidate.

- [ ] Run the audit loop → `docs/audits/scripts-FindPST.md`. Commit `docs(audit): add scripts-FindPST.md`.

### Task 29: `scripts/local_admin_checker.ps1`

**Predicted grade:** B
**Hotspots:** 63 `Write-Host` (C1); 1 `SilentlyContinue` (C4); 630 LOC. Read-only. Inspect: AD vs local enumeration; group expansion.

- [ ] Run the audit loop → `docs/audits/scripts-local_admin_checker.md`. Commit `docs(audit): add scripts-local_admin_checker.md`.

### Task 30: `scripts/network_test_tool.ps1`

**Predicted grade:** B
**Hotspots:** 155 `Write-Host` (C1, 5th highest); 2 `SilentlyContinue` (C4); 981 LOC. Ping/tracert/DNS — uses `Test-Connection` / `Resolve-DnsName`.

- [ ] Run the audit loop → `docs/audits/scripts-network_test_tool.md`. Commit `docs(audit): add scripts-network_test_tool.md`.

### Task 31: `scripts/onedrive_status_checker.ps1`

**Predicted grade:** B
**Hotspots:** 75 `Write-Host` (C1); 13 `SilentlyContinue` (C4 — triage carefully, OneDrive registry probing often legitimately silently-skips); 1029 LOC. Inspect: registry key paths (`HKCU:\Software\Microsoft\OneDrive`); sync-error log parsing.

- [ ] Run the audit loop → `docs/audits/scripts-onedrive_status_checker.md`. Commit `docs(audit): add scripts-onedrive_status_checker.md`.

### Task 32: `scripts/sharepoint_site_inventory.ps1`

**Predicted grade:** B
**Hotspots:** 141 `Write-Host` (C1); 12 `SilentlyContinue` (C4); 1009 LOC. Recent script (commit `d36c587`). Microsoft Graph dependency.

- [ ] Run the audit loop → `docs/audits/scripts-sharepoint_site_inventory.md`. Commit `docs(audit): add scripts-sharepoint_site_inventory.md`.

### Task 33: `scripts/software_updater.ps1`

**Predicted grade:** B
**Hotspots:** 60 `Write-Host` (C1); 5 `SilentlyContinue` (C4); 635 LOC. WinGet wrapper — destructive in effect but delegates to WinGet's own confirmation. Inspect: exit-code handling for WinGet codes (0 and -1978335189).

- [ ] Run the audit loop → `docs/audits/scripts-software_updater.md`. Commit `docs(audit): add scripts-software_updater.md`.

### Task 34: `scripts/SouliTEK-Choco-Installer.ps1`

**Predicted grade:** B
**Hotspots:** 148 `Write-Host` (C1); 6 `SilentlyContinue` (C4); 790 LOC. C9 applies (naming — rename to `chocolatey_installer.ps1` in P1). Note: this script may be deprecated in favor of `software_updater.ps1` / `SouliTEK-Softwares-Installer.ps1` — confirm by reading the launcher's `$Script:Tools` and the README.

- [ ] Run the audit loop → `docs/audits/scripts-SouliTEK-Choco-Installer.md`. **Add a local finding** `F_status`: is this script still referenced by the launcher? If yes, note as live; if no, note as candidate for deletion (P1, not P4). Commit `docs(audit): add scripts-SouliTEK-Choco-Installer.md`.

### Task 35: `scripts/SouliTEK-Softwares-Installer.ps1`

**Predicted grade:** B
**Hotspots:** 65 `Write-Host` (C1); 16 `SilentlyContinue` (C4 — high count, triage carefully); 997 LOC. C9 applies (rename to `softwares_installer.ps1` in P1). Interactive package picker.

- [ ] Run the audit loop → `docs/audits/scripts-SouliTEK-Softwares-Installer.md`. Commit `docs(audit): add scripts-SouliTEK-Softwares-Installer.md`.

### Task 36: `scripts/storage_health_monitor.ps1`

**Predicted grade:** B
**Hotspots:** 60 `Write-Host` (C1); 3 `SilentlyContinue` (C4); 899 LOC. Uses `Get-PhysicalDisk` + SMART data. Read-only.

- [ ] Run the audit loop → `docs/audits/scripts-storage_health_monitor.md`. Commit `docs(audit): add scripts-storage_health_monitor.md`.

### Task 37: `scripts/usb_device_log.ps1`

**Predicted grade:** B
**Hotspots:** 79 `Write-Host` (C1); 6 `SilentlyContinue` (C4); 1012 LOC. Forensic-tool reading registry + setup logs. Inspect: parsing of `setupapi.dev.log`.

- [ ] Run the audit loop → `docs/audits/scripts-usb_device_log.md`. Commit `docs(audit): add scripts-usb_device_log.md`.

### Task 38: `scripts/virustotal_checker.ps1`

**Predicted grade:** A
**Hotspots:** 137 `Write-Host` (C1); 2 `SilentlyContinue` (C4); 1048 LOC. Uses DPAPI for API-key storage (good), hash verification, falls back gracefully on legacy plaintext keys. Inspect: HTTP retry logic; rate-limit handling against VT API.

- [ ] Run the audit loop → `docs/audits/scripts-virustotal_checker.md`. Note exemplary security posture in the Summary. Commit `docs(audit): add scripts-virustotal_checker.md`.

### Task 39: `scripts/wifi_monitor.ps1` and `scripts/wifi_password_viewer.ps1`

These two are paired — both shell out to `netsh wlan` and both apply C14 (no change recommended for the netsh shell-out itself).

**Task 39a: `scripts/wifi_monitor.ps1`**
**Predicted grade:** B
**Hotspots:** 86 `Write-Host` (C1); 3 `SilentlyContinue` (C4); 666 LOC. Signal-strength polling loop (C13 candidate? — polling is inherently sequential, defer).

- [ ] Run the audit loop → `docs/audits/scripts-wifi_monitor.md`. Apply C14 in a Findings entry (`F_netsh` — flag, no-fix). Commit `docs(audit): add scripts-wifi_monitor.md`.

**Task 39b: `scripts/wifi_password_viewer.ps1`**
**Predicted grade:** B
**Hotspots:** 110 `Write-Host` (C1); 0 `SilentlyContinue` (good); 649 LOC. Already has legal-disclaimer block — keep as exception under C11.

- [ ] Run the audit loop → `docs/audits/scripts-wifi_password_viewer.md`. Apply C14 (`F_netsh`). Apply C11 exception (legal-disclaimer block — keep in P4 cleanup). Commit `docs(audit): add scripts-wifi_password_viewer.md`.

---

## Task 40: Wrap-up — summary statistics + roadmap-spec back-reference

**Files:**
- Modify: `docs/audits/README.md` (append "Audit summary" section)
- Modify: `docs/superpowers/specs/2026-05-15-modernize-roadmap-design.md` (append §10 audit-summary table)

- [ ] **Step 1: Generate the per-cross-cutting-finding count**

```powershell
$cc = @('C1','C2','C3','C4','C5','C6','C7','C8','C9','C10','C11','C12','C13','C14')
$rows = foreach ($c in $cc) {
    $count = (Select-String -Path docs/audits/scripts-*.md, docs/audits/01-*.md, docs/audits/02-*.md -Pattern "\(see $c\)|\b$c\b" |
              Select-Object -Unique Path | Measure-Object).Count
    [pscustomobject]@{ ID = $c; FilesCiting = $count }
}
$rows | Format-Table -AutoSize
```

Capture the table.

- [ ] **Step 2: Generate the per-grade distribution**

```powershell
$grades = @{}
Get-ChildItem docs/audits/scripts-*.md | ForEach-Object {
    $g = (Select-String -Path $_.FullName -Pattern 'Modernization grade \| (\w)' | Select-Object -First 1).Matches.Groups[1].Value
    if ($g) { $grades[$g] = ($grades[$g] + 1) }
}
$grades.GetEnumerator() | Sort-Object Name
```

- [ ] **Step 3: Append "Audit summary" section to `docs/audits/README.md`**

Add to the end of the file:

```markdown

---

## Audit summary

### Cross-cutting findings — citation counts

| ID | Title | Files citing |
|---|---|---|
<rows from Step 1, one per line>

### Confirmed grade distribution

| Grade | Count | Scripts |
|---|---|---|
| A | <n> | <list> |
| B | <n> | <list> |
| C | <n> | <list> |
| D | <n> | <list> |

### Phase entry-point summary

Each phase's implementation plan can begin by reading the cross-cutting finding(s) it targets, then walking the per-script audits cited by that finding.

| Phase | Driving findings | Per-script audits to consult |
|---|---|---|
| P0 | C8 | (none — repo-level) |
| P1 | C1, C2, C3, C9 | all per-script audits |
| P2 | C4 | all per-script audits with F entries citing C4 |
| P3 | C5 | the 6+ scripts identified by audits as mutating system state |
| P4 | C6, C10, C11, C13 | the 11 scripts >1000 LOC + all scripts (C10/C11) |
| P5 | C7 | module audit + all per-script audits |
| P6 | C12 | 02-Install-SouliTEK.md |
```

Fill in the `<rows>`, `<n>`, and `<list>` placeholders from the step 1+2 output.

- [ ] **Step 4: Append §10 to the roadmap spec**

Add to `docs/superpowers/specs/2026-05-15-modernize-roadmap-design.md`:

```markdown

---

## 10. Audit complete — pointers into deliverables

The 38 audit files described in §2 are now committed under `docs/audits/`. See [`docs/audits/README.md`](../../audits/README.md) for the index and the audit summary table (cross-cutting citation counts + confirmed grade distribution).

To execute a phase, invoke `superpowers:writing-plans` with input:
> Write the implementation plan for Phase <Pn> from `docs/superpowers/specs/2026-05-15-modernize-roadmap-design.md` §5, drawing findings from the per-script audits cited by the cross-cutting IDs driving that phase. See `docs/audits/README.md`'s "Phase entry-point summary" table.

Recommended starting phase: **P0** (CI baseline) — small, unblocks every later phase.
```

- [ ] **Step 5: Validate, commit, done**

```powershell
# Confirm both files received their additions
Select-String -Path docs/audits/README.md -Pattern '## Audit summary' -Quiet
Select-String -Path docs/superpowers/specs/2026-05-15-modernize-roadmap-design.md -Pattern '## 10\. Audit complete' -Quiet
git add docs/audits/README.md docs/superpowers/specs/2026-05-15-modernize-roadmap-design.md
git commit -m "docs(audit): add summary stats + roadmap §10 back-reference"
```

- [ ] **Step 6: Final integrity check**

```powershell
# Verify all 39 audit files exist and have all four required sections
$expected = Get-Content docs/superpowers/plans/2026-05-15-modernization-audit.md |
            Select-String -Pattern 'docs/audits/[\w\.-]+\.md' -AllMatches |
            ForEach-Object { $_.Matches.Value } |
            Sort-Object -Unique
$existing = Get-ChildItem docs/audits/*.md | Select-Object -ExpandProperty FullName
$missing = $expected | Where-Object { $existing -notmatch [regex]::Escape($_) }
if ($missing) { throw "Missing: $($missing -join ', ')" }

$incomplete = Get-ChildItem docs/audits/scripts-*.md, docs/audits/0*.md | Where-Object {
    $required = @('## Inventory','## Summary','## Findings','## Out-of-scope notes')
    $required | Where-Object { -not (Select-String -Path $_.FullName -Pattern "^$_$" -SimpleMatch -Quiet) }
}
if ($incomplete) { throw "Incomplete: $($incomplete.Name -join ', ')" }
'OK: 39 audit files, all complete'
```

Expected output: `OK: 39 audit files, all complete`.

---

## Appendix A — Audit File Template (canonical)

Reproduced verbatim from spec §3 for engineers reading tasks out of order.

````markdown
# Audit — <relative path>

## Inventory
| Item | Value |
|---|---|
| Path           | <relative path> |
| LOC            | <int> |
| Functions      | <int> |
| `#Requires`    | <text or "none"> |
| Admin-required | yes / no / partial |
| Last touched   | <short SHA> — <YYYY-MM-DD> |
| Modernization grade | A / B / C / D |

## Summary

<one paragraph>

## Findings

### F1 — <short title>
- **Severity:** high | med | low
- **Category:** legacy-api | error-handling | output-style | security | perf | structure | tests | docs | naming
- **Location:** path:line(s)
- **Reference:** [Cn](00-cross-cutting.md#cn--…) — if applicable
- **Current:**
  ```powershell
  <excerpt>
  ```
- **Recommended:**
  ```powershell
  <replacement>
  ```
- **Risk if changed:** <one sentence>
- **Target phase:** P0 | P1 | P2 | P3 | P4 | P5 | P6

### F2 — …

## Out-of-scope notes

<observations deliberately not flagged: style preferences, taste-level refactors, vendor-binary trust if accepted, etc.>
````

---

## Self-Review

**Spec coverage:**
- §1 Goal — Task 40 ends with summary + roadmap §10 back-ref ✓
- §2 Deliverables (38 files) — Tasks 1–39 produce them ✓
- §3 Per-audit template — Reproduced in Appendix A; each task references it ✓
- §4 Cross-cutting findings (C1–C14) — Task 2 expands them ✓
- §5 Phased roadmap — Task 40 builds the Phase entry-point summary ✓
- §6 Grading rubric — Used in Task 1's README + each Inventory table ✓
- §7 Success criteria — Task 40 step 6 validates ✓
- §8 What happens after — Task 40 step 4 writes the next-step prompt ✓

**Placeholder scan:** No "TBD", "TODO", "implement later" outside the empty stubs that Task 1 deliberately creates as placeholders for Task 2+ to fill. Task 5 explicitly says "don't leave any `<…>` in the committed file." Task 40 step 6 validates no incomplete files.

**Type/name consistency:** Cross-cutting IDs (C1–C14), Task IDs (Task 1–Task 40), output filenames are consistent across appendix, tasks, and README. The reference task uses the same template paths as later tasks.

**Audit loop reuse:** Tasks 6–39 reference "THE AUDIT LOOP" by name and Task 5 as the canonical example. Engineers reading any task in isolation can scroll up to either anchor.
