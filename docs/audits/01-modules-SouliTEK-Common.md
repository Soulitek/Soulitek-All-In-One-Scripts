# Audit — modules/SouliTEK-Common.ps1

## Inventory
| Item | Value |
|---|---|
| Path           | modules/SouliTEK-Common.ps1 |
| LOC            | 1416 |
| Functions      | 31 |
| `#Requires`    | none |
| Admin-required | no (module — admin checks deferred to callers) |
| Last touched   | a76b4e7 — 2026-04-18 |
| Modernization grade | B |

## Summary

The common module is the foundation every script in the repo dot-sources, so its quality propagates everywhere. It does several things very well: `Test-SafeFilePath` is exemplary (fail-closed, traversal-rejecting, 260-char capped, with the only Pester coverage in the repo); `Protect-SouliTEKSecret` / `Unprotect-SouliTEKSecret` use DPAPI via `SecureString` and zero the BSTR after read; `Confirm-SouliTEKFileHash` deletes the file on mismatch (correct fail-closed posture); the unified output via `Write-Ui` / `Write-Status` matches STYLE_GUIDE.md; the branded `Export-SouliTEKReport` (TXT/CSV/HTML) eliminates per-script export duplication. The biggest issues are (1) the dead `Write-SouliTEKResult` + four wrappers duplicating the output API per C2 — and `Export-SouliTEKReport` itself still calls two of those wrappers internally (lines 1065 / 1075), so those internal usages must be migrated before the legacy API can be deleted; (2) every `Write-Ui` call in `Install-SouliTEKModule` (lines 878–976) embeds an inline `[*]`/`[+]`/`[-]`/`[!]` prefix inside the message, double-marking output that already carries a `[LEVEL]` bracket from `Write-Ui` itself; (3) `Set-SouliTEKConsoleColor` maps `"Blue"` → `"Cyan"` (stale alias or bug); (4) two helpers required for P4 don't exist yet — `Invoke-SouliTEKParallel` (C13) and `Import-SouliTEKCommon` (C10); (5) the file is 1416 LOC and a themed split is a reasonable P4 candidate; (6) of 31 defined functions only one (`Test-SafeFilePath`) is covered by Pester per C7. Recommended phase entry order: **P1** (delete dead API after C1 sweep + fix F2 embedded markers), then **P4** (add the two missing helpers and consider the themed split), then **P5** (add Pester coverage for the remaining 30 functions).

## Findings

### F1 — Dead duplicate output API (see C2)
- **Severity:** low
- **Category:** output-style
- **Location:** modules/SouliTEK-Common.ps1:137-179 (`Write-SouliTEKResult`), 520-531 (`Write-SouliTEKInfo`), 533-544 (`Write-SouliTEKSuccess`), 546-557 (`Write-SouliTEKWarning`), 559-570 (`Write-SouliTEKError`). Internal callers: line 1065 (`Write-SouliTEKSuccess "Report exported to: $OutputPath"`) and line 1075 (`Write-SouliTEKError "Failed to export report: ..."`), both inside `Export-SouliTEKReport`.
- **Reference:** [C2](00-cross-cutting.md#c2--dead-duplicate-output-api)
- **Local notes:** All five functions forward to a legacy `[HH:mm:ss] [+]` / `[-]` / `[!]` / `[*]` format that predates the current `Write-Ui` standard (`[dd-MM-yyyy HH:mm:ss] [LEVEL]`). Before deleting the five functions, `Export-SouliTEKReport` must be migrated to call `Write-Ui -Level "OK"` / `Write-Ui -Level "ERROR"` instead. After that, run the cross-cutting `Select-String -Path scripts,modules -Pattern 'Write-SouliTEK(Result|Info|Success|Warning|Error)' -Recurse` check from C2 to confirm zero external callers remain.
- **Target phase:** P1

### F2 — Embedded marker prefixes inside Write-Ui messages
- **Severity:** med
- **Category:** output-style
- **Location:** modules/SouliTEK-Common.ps1 — 22 occurrences, all inside `Install-SouliTEKModule`:
  - line 878 — `"  [*] Checking NuGet provider..."` (INFO)
  - line 882 — `"  [*] Installing NuGet provider..."` (WARN)
  - line 885 — `"  [+] NuGet provider installed successfully"` (OK)
  - line 888 — `"  [-] Failed to install NuGet provider: ..."` (ERROR)
  - line 896 — `"  [-] PowerShellGet module not found"` (ERROR)
  - line 897 — `"  [!] Please install PowerShellGet manually"` (WARN)
  - line 902 — `"  [*] Checking for $ModuleName..."` (INFO)
  - line 910 — `"  [!] Installed version ... is older than required ..."` (WARN)
  - line 914 — `"  [!] Force flag specified, reinstalling..."` (WARN)
  - line 918 — `"  [+] $ModuleName version ... is already installed"` (OK)
  - line 922 — `"  [!] Force flag specified, reinstalling..."` (WARN)
  - line 926 — `"  [+] $ModuleName is already installed (version ...)"` (OK)
  - line 930 — `"  [!] $ModuleName not found, installing..."` (WARN)
  - line 936 — `"  [*] Installing $ModuleName..."` (INFO)
  - line 951 — `"  [+] $ModuleName installed successfully"` (OK)
  - line 954 — `"  [-] Failed to install $ModuleName"` (ERROR)
  - line 955 — `"  [-] Error: ..."` (ERROR)
  - line 957 — `"  [!] Try manual installation:"` (WARN)
  - line 964 — `"  [*] Importing $ModuleName..."` (INFO)
  - line 967 — `"  [+] $ModuleName imported successfully"` (OK)
  - line 971 — `"  [-] Failed to import ${ModuleName}: ..."` (ERROR)
  - line 976 — `"  [-] Unexpected error in Install-SouliTEKModule: ..."` (ERROR)
- **Reference:** Style violation — `STYLE_GUIDE.md` says the `[LEVEL]` bracket emitted by `Write-Ui` is the marker; inline `[*]`/`[+]`/`[-]`/`[!]` prefixes are double-marking. Also note: `Show-SouliTEKExportMenu` (lines 1342–1346) uses `[1]`/`[2]`/`[3]`/`[4]`/`[0]` — these are menu-option numbers, not level markers, and are out of scope for this finding. The `1.` / `2.` / `3.` items inside `Invoke-SouliTEKAdminCheck` (lines 802–804) are likewise legitimate enumeration.
- **Current:**
  ```powershell
  Write-Ui -Message "  [*] Checking NuGet provider..." -Level "INFO"
  Write-Ui -Message "  [+] NuGet provider installed successfully" -Level "OK"
  Write-Ui -Message "  [-] Failed to install NuGet provider: $($_.Exception.Message)" -Level "ERROR"
  ```
- **Recommended:**
  ```powershell
  Write-Ui -Message "Checking NuGet provider..." -Level "INFO"
  Write-Ui -Message "NuGet provider installed successfully" -Level "OK"
  Write-Ui -Message "Failed to install NuGet provider: $($_.Exception.Message)" -Level "ERROR"
  ```
- **Risk if changed:** Low. Cosmetic — output becomes `[15-05-2026 13:42:08] [INFO] Checking NuGet provider...` instead of `[15-05-2026 13:42:08] [INFO]   [*] Checking NuGet provider...`. No control-flow change, no API surface change.
- **Target phase:** P1

### F3 — `Set-SouliTEKConsoleColor` stale Blue→Cyan mapping
- **Severity:** low
- **Category:** structure (dead code)
- **Location:** modules/SouliTEK-Common.ps1:392-424 (function body), line 416 specifically (`"Blue" { $Host.UI.RawUI.ForegroundColor = "Cyan" }`).
- **Current:** The function accepts `"Blue"` via `ValidateSet` but the switch maps it to `"Cyan"` instead of `"Blue"`. The other six branches (Green, Red, Yellow, Magenta, White, Gray) are identity mappings, so this looks like a stale alias from an earlier color scheme rather than an intentional translation.
- **Recommended:** Run `Select-String -Path scripts,modules,launcher -Pattern 'Set-SouliTEKConsoleColor' -Recurse`. If no callers exist (likely — the function has no obvious consumer in the codebase), delete the whole function in P4. If callers exist and depend on `Blue → Cyan` behavior, leave a comment documenting the alias. If callers pass `"Blue"` expecting blue, fix the mapping to `"Blue"` and treat as P1 bug.
- **Risk if changed:** Low.
- **Target phase:** P4

### F4 — Gap: no `Invoke-SouliTEKParallel` helper (see C13)
- **Severity:** med
- **Category:** structure
- **Location:** modules/SouliTEK-Common.ps1 — end of file (helper does not exist).
- **Reference:** [C13](00-cross-cutting.md#c13--sequential-foreach-over-large-datasets-where-parallelism-would-help)
- **Local notes:** P4 needs a runspace-pool-based helper (PS 5.1-compatible — `ForEach-Object -Parallel` is PS 7 only and outside the floor). The helper must accept a script block and an input collection, expose a `-ThrottleLimit` parameter (default to `[Environment]::ProcessorCount`), wire a cancellation token (or `[CancellationTokenSource]`), and dispose the runspace pool in a `finally`. It will be called by `disk_usage_analyzer`, `domain_dns_analyzer`, `EventLogAnalyzer`, and `browser_plugin_checker` per C13's per-script audit notes.
- **Target phase:** P4

### F5 — Gap: no `Import-SouliTEKCommon` helper (see C10)
- **Severity:** low
- **Category:** structure
- **Location:** modules/SouliTEK-Common.ps1 — end of file (helper does not exist).
- **Reference:** [C10](00-cross-cutting.md#c10--import-soulitek-common-functions-boilerplate-duplicated-35x)
- **Local notes:** Each of the 35 scripts reimplements the same 5–9-line `Join-Path` + `Test-Path` + dot-source + fallback-warn block. A one-liner helper in the module would let scripts collapse the block — but there is a chicken-and-egg constraint: the helper itself must live in `SouliTEK-Common.ps1`, so scripts still need a single `. "$PSScriptRoot\..\modules\SouliTEK-Common.ps1"` line to bootstrap. Realistic outcome is a ~3-line standardised dot-source stub + a `Test-SouliTEKCommonLoaded` sanity helper. Savings are small; deferred to P4 with other structural consolidation.
- **Target phase:** P4

### F6 — Module size (1416 LOC) — themed-split candidate
- **Severity:** low
- **Category:** structure
- **Location:** modules/SouliTEK-Common.ps1 (entire file).
- **Local notes:** The module is already informally partitioned by `# ===` section banners (`CORE FUNCTIONS`, `UNIFIED OUTPUT FUNCTIONS`, `CONVENIENCE FUNCTIONS`, `UI/DISPLAY FUNCTIONS`, `MODULE MANAGEMENT FUNCTIONS`, `EXPORT/REPORT FUNCTIONS`). Candidate splits:
  - `SouliTEK-Common-Output.ps1` — `Write-Ui`, `Write-Status`, `Show-ScriptBanner`, `Show-Section`, `Show-Step`, `Show-Summary`, `Show-SouliTEKHeader`, `Show-SouliTEKBanner`
  - `SouliTEK-Common-Reports.ps1` — `Export-SouliTEKReport`, `Export-SouliTEKTextReport`, `Export-SouliTEKHtmlReport`, `Show-SouliTEKExportMenu`, `Format-SouliTEKFileSize`
  - `SouliTEK-Common-Modules.ps1` — `Install-SouliTEKModule`
  - `SouliTEK-Common-Security.ps1` — `Test-SafeFilePath`, `Protect-SouliTEKSecret`, `Unprotect-SouliTEKSecret`, `Confirm-SouliTEKFileHash`
  - `SouliTEK-Common-Core.ps1` — `$Script:SouliTEKConfig`, `Get-SouliTEKVersion`, `Test-SouliTEKAdministrator`, `Invoke-SouliTEKAdminCheck`, `Show-SouliTEKDisclaimer`, `Show-SouliTEKExitMessage`, `Wait-SouliTEKKeyPress`, `Initialize-SouliTEKScript`, `Set-SouliTEKConsoleColor`
  - The main `SouliTEK-Common.ps1` then dot-sources each part in order. Scripts continue dot-sourcing the same single entry path, so the change is internal.
- **Recommended phase:** P4
- **Target phase:** P4

### F7 — Test coverage gap (see C7)
- **Severity:** med
- **Category:** tests
- **Location:** modules/SouliTEK-Common.ps1 — every function except `Test-SafeFilePath`.
- **Reference:** [C7](00-cross-cutting.md#c7--pester-coverage-gap)
- **Local notes:** `tests/Common.Tests.ps1` currently exercises only `Test-SafeFilePath` (7 `It` cases). The remaining 30 functions have no tests. Listed by declaration order:
  1. `Show-SouliTEKBanner`
  2. `Test-SouliTEKAdministrator`
  3. `Write-SouliTEKResult`
  4. `Write-Ui`
  5. `Write-Status`
  6. `Show-ScriptBanner`
  7. `Show-Section`
  8. `Show-Step`
  9. `Show-Summary`
  10. `Set-SouliTEKConsoleColor`
  11. `Get-SouliTEKVersion`
  12. `Show-SouliTEKHeader`
  13. `Write-SouliTEKInfo`
  14. `Write-SouliTEKSuccess`
  15. `Write-SouliTEKWarning`
  16. `Write-SouliTEKError`
  17. `Format-SouliTEKFileSize`
  18. `Show-SouliTEKDisclaimer`
  19. `Show-SouliTEKExitMessage`
  20. `Wait-SouliTEKKeyPress`
  21. `Initialize-SouliTEKScript`
  22. `Invoke-SouliTEKAdminCheck`
  23. `Install-SouliTEKModule`
  24. `Export-SouliTEKReport`
  25. `Export-SouliTEKTextReport` (private)
  26. `Export-SouliTEKHtmlReport` (private)
  27. `Show-SouliTEKExportMenu`
  28. `Protect-SouliTEKSecret`
  29. `Unprotect-SouliTEKSecret`
  30. `Confirm-SouliTEKFileHash`
  Total: 30 untested functions. Priority order for P5: pure functions first (`Get-SouliTEKVersion`, `Format-SouliTEKFileSize`), then deterministic output functions (`Write-Ui` / `Write-Status` — assert on `Write-Host` mock), then security functions (`Protect-/Unprotect-SouliTEKSecret`, `Confirm-SouliTEKFileHash`), then `Export-SouliTEKReport` round-trip tests using a temp directory, then `Install-SouliTEKModule` with `Get-PackageProvider`/`Install-Module` mocked.
- **Target phase:** P5

### F8 — No functions declare `[CmdletBinding()]` — security trio is the most consequential
- **Severity:** low
- **Category:** structure
- **Location:** modules/SouliTEK-Common.ps1 (all 31 functions). Most-consequential omissions: 1364 (`Protect-SouliTEKSecret`), 1380 (`Unprotect-SouliTEKSecret`), 1396 (`Confirm-SouliTEKFileHash`), plus the private `Export-SouliTEKTextReport` (1080) / `Export-SouliTEKHtmlReport` (1138).
- **Local notes:** Every function in the module uses a `<#...#>` comment-based help block but declares only `param(...)` without `[CmdletBinding()]`. The five listed locations are the most consequential because they would most benefit from common parameters (`-Verbose`, `-ErrorAction`). Recommend adding `[CmdletBinding()]` (and `OutputType`) opportunistically when each function is touched during P4/P5, rather than a sweep.
- **Risk if changed:** Low — `[CmdletBinding()]` is additive.
- **Target phase:** P4

### F9 — `Confirm-SouliTEKFileHash` uses `-ErrorAction SilentlyContinue` on cleanup delete (see C4)
- **Severity:** low
- **Category:** error-handling
- **Location:** modules/SouliTEK-Common.ps1:1409 — `Remove-Item -Path $FilePath -Force -ErrorAction SilentlyContinue` inside the hash-mismatch branch.
- **Reference:** [C4](00-cross-cutting.md#c4----erroraction-silentlycontinue-swallowing-failures) — triage tag **A** (legitimate cleanup: "delete the bad file if we can, but the hash already failed so the function is going to return $false anyway").
- **Local notes:** Add a `# safe: cleanup` comment on the line when C4 is applied in P2. No behavior change.
- **Target phase:** P2

### F10 — `Wait-SouliTEKKeyPress` and `Show-SouliTEKDisclaimer` block on `ReadKey` with no timeout
- **Severity:** info
- **Category:** structure (UX)
- **Location:** modules/SouliTEK-Common.ps1:660 (`Show-SouliTEKDisclaimer`), 718 (`Wait-SouliTEKKeyPress`).
- **Local notes:** Both call `$Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")` and will hang indefinitely if invoked in a non-interactive context (RMM/SYSTEM/scheduled task) — the user's CLAUDE.md flags SYSTEM-context execution as a deployment scenario. Consider gating both behind an `[Environment]::UserInteractive` check, with a `-NonInteractive` switch that no-ops instead of blocking. Defer to P4 unless an actual RMM hang report comes in.
- **Target phase:** P4

## Out-of-scope notes
- `Test-SafeFilePath` (lines 38-70) is exemplary: explicit fail-closed checks on null/whitespace/length-260 in that order, regex rejects both path separators and `..`, leaf-only normalization, and a final `StartsWith($base + DirectorySeparator)` guard against the `C:\foo` vs `C:\foobar` prefix-match bug. Comprehensive Pester coverage in `tests/Common.Tests.ps1` (7 `It` cases covering plain name, spaces, traversal, absolute escape, empty, whitespace, length cap). Mention only as a model; no change needed.
- `Confirm-SouliTEKFileHash`, `Protect-SouliTEKSecret`, `Unprotect-SouliTEKSecret` are well-implemented: DPAPI via `SecureString`, BSTR zeroed via `[Marshal]::ZeroFreeBSTR` after read on the unprotect path, hash check using SHA256 with case-insensitive compare and fail-closed delete-on-mismatch. No change needed beyond F8 (CmdletBinding) and F9 (C4 tagging).
- The 14-line banner block at the top of the file (lines 1-14) is a docs-style copyright header similar to the one C11 targets in scripts. The module is explicitly excluded from C11's mass-cleanup scope, so leave it.
- `$Script:SouliTEKConfig` (lines 23-33) and the `ProjectRoot` derivation on line 36 are clean and centralised — no change needed.
