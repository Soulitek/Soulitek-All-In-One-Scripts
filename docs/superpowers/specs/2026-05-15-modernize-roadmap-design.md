# SouliTEK Modernization — Audit & Phased Roadmap (Design Spec)

| Field | Value |
|---|---|
| Date | 2026-05-15 |
| Author | Eitan (SouliTEK) + Claude |
| Status | Draft — pending user review |
| Repo | `Soulitek-All-In-One-Scripts` (main) |
| Output type | Documentation only — no source code changes in this spec's scope |

---

## 1. Goal

Produce a written modernization audit of the entire SouliTEK repo (scripts, common module, installer, hosting proxies) that:

1. Surfaces every legacy / inefficient / unsafe pattern with file:line citations and a concrete recommended replacement.
2. Groups findings into a **phased roadmap** that can be executed one phase at a time, each phase as its own implementation plan + PR.
3. Keeps the PowerShell 5.1 compatibility floor while remaining 7.x-compatible (no PS-7-only sugar in recommendations).
4. Defers all source-code changes — a downstream `writing-plans` invocation per phase will produce the implementation plan(s).

**Non-goals.** No code edits. No WPF launcher audit (user-excluded). No new tool features. No license/branding changes.

---

## 2. Deliverables

```
docs/
├── superpowers/specs/2026-05-15-modernize-roadmap-design.md   # this file
└── audits/
    ├── 00-cross-cutting.md            # findings that appear in 3+ files
    ├── 01-modules-SouliTEK-Common.md  # common module audit
    ├── 02-Install-SouliTEK.md         # installer + hosting/* proxies
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
```

**Total audit files: 38** (35 scripts + module + installer + cross-cutting index).

---

## 3. Per-Audit File Template

Every per-file audit follows the identical structure below. Consistency lets the roadmap pull individual findings up by ID (e.g. `S12-F3` = script-file 12, finding 3).

```markdown
# Audit — <relative path>

## Inventory
| Item | Value |
|---|---|
| Path           | scripts/<name>.ps1 |
| LOC            | <int> |
| Functions      | <int> |
| `#Requires`    | Version 5.1 / none |
| Admin-required | yes / no / partial |
| Last touched   | <commit short SHA> — <date> |
| Modernization grade | A / B / C / D (see grading rubric in §6) |

## Summary
One paragraph: what the script does, biggest two issues, recommended phase.

## Findings

### F1 — <short title>
- **Severity:** high | med | low
- **Category:** legacy-api | error-handling | output-style | security | perf | structure | tests | docs | naming
- **Location:** path:line(s)
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

### F2 — ...
...

## Out-of-scope notes
Things observed but deliberately not flagged (e.g. style preferences, taste-level refactors).
```

The **cross-cutting** file (`00-cross-cutting.md`) is the same template but its findings group identical issues spanning 3+ files, with a "Files affected" list instead of a single location.

---

## 4. Cross-Cutting Findings — Already Identified

These will populate `docs/audits/00-cross-cutting.md`. They drive the phase boundaries below.

| ID | Category | Title | Files affected (count) | Target phase |
|---|---|---|---|---|
| C1 | output-style | Raw `Write-Host` calls not migrated to `Write-Ui`/`Write-Status` | ~36 files, 3,580 occurrences | P1 |
| C2 | output-style | Dead duplicate API: `Write-SouliTEKResult` + `Write-SouliTEK{Info,Success,Warning,Error}` coexist with `Write-Ui` | module + every script that calls them | P1 |
| C3 | legacy-api | `Get-WmiObject` (removed in PS 7) used instead of `Get-CimInstance` | `driver_integrity_scan.ps1`, `product_key_retriever.ps1` | P1 |
| C4 | error-handling | `-ErrorAction SilentlyContinue` swallowing failures (audit each occurrence — many are appropriate for cleanup, many are not) | 30 scripts, 186 occurrences | P2 |
| C5 | safety | Destructive scripts lack `[CmdletBinding(SupportsShouldProcess)]` + `-WhatIf`/`-Confirm` | `essential_tweaks`, `win11_debloat`, `temp_removal_disk_cleanup`, `mcafee_removal_tool`, `network_configuration_tool`, `create_system_restore_point` | P3 |
| C6 | structure | Scripts >1000 LOC with duplication that could move to module helpers | 8 scripts (>1000 LOC each) | P4 |
| C7 | tests | Pester suite covers 1/26 module functions; zero script-level smoke tests | all | P5 |
| C8 | tooling | No PSScriptAnalyzer enforcement, no CI workflow | repo root | P0 |
| C9 | naming | `SouliTEK-Choco-Installer.ps1` and `SouliTEK-Softwares-Installer.ps1` violate the `lowercase_with_underscores` rule in CONTRIBUTING.md; launcher must be updated when renamed | 2 scripts + launcher reference | P1 |
| C10 | structure | Per-script `Import SouliTEK Common Functions` boilerplate duplicated 35× — candidate for a 1-line dot-source via a shared header pattern | all scripts | P4 |
| C11 | docs | Banner/disclaimer block (~35 lines) duplicated at top of every script | all scripts | P4 |
| C12 | security | Installer downloads ZIP without mandatory hash verification (`$ExpectedZipHash` param exists but is empty by default) | `Install-SouliTEK.ps1`, `api/install.js`, `hosting/install-proxy.php` | P6 |
| C13 | perf | Sequential `foreach` over large data sets where `ForEach-Object -Parallel` would help — must stay 5.1-compatible, so use runspace pool helper in module instead | candidates: `disk_usage_analyzer`, `domain_dns_analyzer`, `EventLogAnalyzer` | P4 (defer until module helper exists) |
| C14 | legacy-api | `netsh wlan` shelling out — kept because there is no native cmdlet exposing saved-key contents; flag for awareness, no change recommended | `wifi_password_viewer`, `wifi_monitor` | (none) |

The cross-cutting file is the single source of truth. Per-script audits reference cross-cutting IDs (`see C1`) instead of repeating them.

---

## 5. Phased Roadmap

Each phase is one implementation plan + one PR. Phases are ordered by **risk-adjusted dependency**: earlier phases unblock later ones (e.g. CI in P0 lets every later phase prove "no regressions").

| Phase | Title | Drives | Scope size | Risk | Behavior change? |
|---|---|---|---|---|---|
| **P0** | Tooling & CI baseline | C8 | Small | Low | No |
| **P1** | Cross-cutting cleanup | C1, C2, C3, C9 | Large (file count), Low per file | Low | No |
| **P2** | Error-handling discipline | C4 | Medium | Medium | Yes (some errors now surface) |
| **P3** | Destructive-script safety: `ShouldProcess` | C5 | Medium | Medium | Yes (adds `-WhatIf`/`-Confirm`) |
| **P4** | Big-script decomposition + module helpers | C6, C10, C11, C13 | Large | High | No (behavior preserved) |
| **P5** | Test coverage | C7 | Medium | Low | No |
| **P6** | Installer + proxy hardening | C12 | Small | Medium | Yes (hash check becomes default) |

### Phase details

**P0 — Tooling & CI baseline (smallest, ships first)**
- Add `PSScriptAnalyzerSettings.psd1` at repo root with the rule set the project will actually follow.
- Add `.github/workflows/ci.yml`: runs `Invoke-ScriptAnalyzer` against `scripts/`, `modules/`, `launcher/`, and `Install-SouliTEK.ps1`; runs `Invoke-Pester` against `tests/`.
- Pre-commit hook (optional, repo-local) documented in `CONTRIBUTING.md`.
- Exit criteria: CI fails on any new analyzer error; existing analyzer errors are recorded as a `ANALYZER-BASELINE.md` snapshot, not enforced retroactively (each subsequent phase whittles the baseline down).

**P1 — Cross-cutting cleanup (highest "consistency win per LOC")**
- Finish `Write-Host` → `Write-Ui` migration in every script. Mechanical replacement; logic untouched.
- Delete `Write-SouliTEKResult` + the four `Write-SouliTEK{Info|Success|Warning|Error}` wrappers from the module after confirming no remaining callers (sweep first, remove second).
- Replace 3 occurrences of `Get-WmiObject` with `Get-CimInstance` in `driver_integrity_scan.ps1` and `product_key_retriever.ps1` and validate the output shape on a Win 10 + Win 11 box.
- Rename `SouliTEK-Choco-Installer.ps1` → `chocolatey_installer.ps1` and `SouliTEK-Softwares-Installer.ps1` → `softwares_installer.ps1` (matches CONTRIBUTING.md); update launcher's `$Script:Tools` references; update docs.
- Exit criteria: zero `Write-Host` outside `Write-Ui`/`Show-*` helpers; zero `Get-WmiObject`; zero callers of the deleted output API; launcher launches every renamed tool successfully.

**P2 — Error-handling discipline**
- For each of the 186 `-ErrorAction SilentlyContinue` occurrences, tag as: **A** = legitimate cleanup ("delete temp file if exists, don't care otherwise"), **B** = was-swallowing-bug ("now logs a warning via `Write-Ui WARN` and continues"), or **C** = needs `try/catch` because failure should halt.
- Apply the tag, replace `B` and `C` accordingly, leave `A` with a `# safe: cleanup` comment.
- Cross-reference with CLAUDE.md "fail closed — deny by default".
- Exit criteria: every `SilentlyContinue` is justified (audit table in `ANALYZER-BASELINE.md` shows tag per occurrence).

**P3 — Destructive-script safety**
- Wrap the 6 destructive scripts in `[CmdletBinding(SupportsShouldProcess, ConfirmImpact='High')]`.
- Replace direct mutations with `if ($PSCmdlet.ShouldProcess(<target>, <action>)) { … }`.
- Add `-WhatIf` / `-Confirm` examples to each `.SYNOPSIS` block.
- Launcher: pass `-Confirm:$false` or surface a checkbox; keep default interactive.
- Exit criteria: `-WhatIf` produces an action list with zero side effects on all 6 scripts.

**P4 — Big-script decomposition + module helpers**
- For each of the 8 scripts >1000 LOC: extract reusable blocks into the module under a new section (e.g. `EXPORT/REPORT FUNCTIONS` already exists — extend with `Get-SouliTEKDriveInfo`, `Invoke-SouliTEKParallelTask`, etc.).
- Add a runspace-pool helper in the module to enable PS-5.1-compatible parallelism (avoids `ForEach-Object -Parallel` which is 7-only).
- Add a script-header helper that replaces the 35-line banner + dot-source boilerplate with one line: `. (Join-Path $PSScriptRoot '..\modules\SouliTEK-Common.ps1'); Initialize-SouliTEKScript -WindowTitle '...'`.
- Exit criteria: every script <800 LOC; module exposes the new helpers with passing Pester tests.

**P5 — Test coverage**
- Pester tests for every module function (target: 80%+ statement coverage on `modules/`).
- A "smoke" test per script: dot-sources cleanly, exposes expected functions, no syntax errors. Where possible: runs with `-WhatIf` and asserts no side effects.
- CI gate: tests must pass.
- Exit criteria: `Invoke-Pester` green; `Get-MarkdownTable` of coverage published to `docs/audits/`.

**P6 — Installer + proxy hardening**
- Make `Install-SouliTEK.ps1`'s `-ExpectedZipHash` mandatory in non-`-Silent` mode and pull the expected hash from a signed manifest URL.
- Audit `api/install.js` (Vercel) and `hosting/install-proxy.php` for redirect-poisoning, TLS pinning where possible, rate-limit headers.
- Exit criteria: tampered ZIP fails install with clear error; manifest URL is documented; rate-limit doc lives in `hosting/README.md`.

### Phase dependency graph

```
P0 (CI)  →  P1 (cleanup)  →  P2 (errors)  →  P3 (ShouldProcess)
                              ↘
                                P4 (decompose) →  P5 (tests)
                                                    ↘
                                                      P6 (installer)
```

P1, P2, P3, P5 are each independently shippable. P4 depends on P0+P1 because it relies on a clean baseline. P6 is gated by P5 (tests for installer).

---

## 6. Modernization Grading Rubric

Used in each per-script audit's inventory line. Coarse-grained, designed for triage.

| Grade | Criteria |
|---|---|
| **A** | Uses unified output, no legacy APIs, has `[CmdletBinding()]`, error handling deliberate, <600 LOC or cleanly factored |
| **B** | 1–3 minor findings; would pass review with small changes |
| **C** | 4–8 findings, some cross-cutting (e.g. mixed `Write-Host`/`Write-Ui`) but no safety issues |
| **D** | 9+ findings or any **high-severity** finding (security, swallowed errors on destructive paths, removed-in-PS7 API) |

Initial grade prediction (to be confirmed during audit):

| Likely D | Likely C | Likely B | Likely A |
|---|---|---|---|
| `driver_integrity_scan` (WMI), `product_key_retriever` (WMI), `EventLogAnalyzer` (size+SilentlyContinue), `printer_spooler_fix` (SilentlyContinue heavy), `essential_tweaks` (destructive no ShouldProcess), `win11_debloat` (destructive no ShouldProcess), `mcafee_removal_tool` (destructive no ShouldProcess) | most M365 scripts, `domain_dns_analyzer`, `startup_boot_analyzer`, `disk_usage_analyzer` | `wifi_password_viewer`, `network_test_tool`, `battery_report_generator` | `virustotal_checker` (uses DPAPI + hash verify), `bitlocker_status_report` |

---

## 7. Success Criteria for This Spec

This spec is "done" when:
1. The 38 audit files exist, populated, and committed to the branch.
2. The cross-cutting file references every recurring finding with a count of affected files.
3. The roadmap's phase exit-criteria are each falsifiable (i.e. a future Claude session can grep/test against them).
4. Every phase has a clear next-step prompt for `writing-plans` (so each phase can be picked up independently).

---

## 8. What Happens After This Spec Is Approved

The downstream chain:

1. **`writing-plans` (next invocation)** — pick one phase (typically P0 first) and produce its `docs/superpowers/plans/...md` plan file.
2. **`executing-plans` or `subagent-driven-development`** — implement that one phase.
3. **`requesting-code-review`** — review the phase PR.
4. Repeat per phase.

The audit deliverables (the 38 markdown files) are written as part of executing **this** spec's plan — they are the only artifacts produced before the user picks a phase.

---

## 9. Open Questions (none blocking)

- Should `docs/audits/` be a top-level folder or live under `docs/superpowers/audits/`? Defaulting to `docs/audits/` for visibility; easy to relocate.
- Should the per-script audits include a "time estimate to fix" column? Deferred — would be guessy without doing the work.

---

*End of design spec.*
