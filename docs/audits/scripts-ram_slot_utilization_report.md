# Audit — scripts/ram_slot_utilization_report.ps1

## Inventory
| Item | Value |
|---|---|
| Path           | scripts/ram_slot_utilization_report.ps1 |
| LOC            | 1195 |
| Functions      | 11 |
| `#Requires`    | none |
| Admin-required | no (read-only CIM queries against `Win32_PhysicalMemoryArray` / `Win32_PhysicalMemory`; the help text on line 1143 says "Administrator privileges (recommended)" but the script does not declare or check for admin) |
| Last touched   | 8675720 — 2026-04-17 |
| Modernization grade | C |

## Summary

A menu-driven RAM-slot inventory tool: enumerates `Win32_PhysicalMemoryArray` + `Win32_PhysicalMemory` via `Get-CimInstance`, computes used/empty slot counts and totals, renders a console summary, and exports TXT / CSV / HTML / "all" reports to the user's Desktop. **The C3 prediction does not apply** — there is zero `Get-WmiObject` usage in this file (lines 92-93 already use `Get-CimInstance`), so cross-cutting C3 should be edited to drop this script from its files-affected list (only `scripts/product_key_retriever.ps1` remains). **There is also zero `-ErrorAction SilentlyContinue` here** — no C4 work is needed. The dominant issues are (1) **C6: extreme duplication in the rendering layer.** The full HTML document (lines 519–697 vs. 887–1065, ~178 lines, byte-identical) and the entire TXT report body (lines 301–360 vs. 756–813, near-identical, only whitespace differs) are copy-pasted between the dedicated `Export-RAMReport*` functions and the "export all" path. The CSV summary `PSCustomObject` projection (lines 425–434) is also re-built inline in `Export-RAMReportAll` (lines 830–840). Extracting three pure data-shaping helpers (`Format-RAMReportTxt`, `Format-RAMReportCsv`, `Format-RAMReportHtml`) plus a thin `Save-RAMReport` driver would collapse `Export-RAMReportAll` from 372 LOC to ~80 and cut total script size by roughly 600 LOC. (2) **C1 in earnest** — 157 raw `Write-Host` calls (third-highest in the repo) coexist with 27 already-migrated `Write-Ui` calls and 25 `Set-SouliTEKConsoleColor` calls, producing a three-way output mix that is harder to clean than driver_integrity_scan.ps1 because the script *also* embeds `[OK]`/`[ERROR]` markers inside `Write-Ui` message strings (lines 817, 819, 842, 844, 1069, 1071) — same anti-pattern as F2 of `01-modules-SouliTEK-Common.md`. Secondary concerns: no `#Requires` / no `[CmdletBinding()]` / no `param()` block (F4); `Split-Path -Parent $MyInvocation.MyCommand.Path` instead of `$PSScriptRoot` (F5); hard-coded `$env:USERPROFILE\Desktop` output path in 5 places with no override (F6); 5 `Read-Host` prompts plus an unconditional `do { ... } while ($choice -ne "0")` loop that will hang under SYSTEM-context execution (F7); HTML title contains `[RAM] Slot Utilization Report` — a leftover ASCII-emoji-prefix that should be just `RAM Slot Utilization Report` (F8); and the banner block occupies the first 32 lines (C11). Recommended phase entry order: P4 (the C6 extraction is the headline win here — it both removes ~600 LOC *and* reduces the C1 surface because most of the duplicated lines are `Write-Host`s), then P1 (C1 sweep over what remains), then P4 (the structural F4/F5/F6/F7 cleanup folds in naturally).

## Findings

### F1 — Mixed `Write-Host` / `Write-Ui` / `Set-SouliTEKConsoleColor` (see C1)
- **Severity:** med
- **Category:** output-style
- **Location:** scripts/ram_slot_utilization_report.ps1 — 157 raw `Write-Host` occurrences (third highest in the repo). Sample C1-violation line ranges: 56–66 (menu rendering), 214–220 (report header), 236–273 (the console summary with inline-color two-call patterns), 282–295 (TXT export header), 366–386 (TXT success block), 392–406 (CSV export header), 416–455 (CSV success block + summary path output), 462–477 (HTML export header), 705–722 (HTML success block), 730–745 (all-format export header), 1074–1094 (all-format success block + file list), 1102–1155 (the entire `Show-Help` body — 53 plain-text `Write-Host` lines). Plus 25 `Set-SouliTEKConsoleColor` calls (lines 55, 67, 213, 225, 228, 272, 281, 293, 365, 383, 392, 404, 415, 453, 462, 474, 702, 720, 729, 743, 1075, 1092, 1101, 1107, 1153) that switch the *next* `Write-Host`'s color rather than using `Write-Ui`'s level-driven coloring.
- **Reference:** [C1](00-cross-cutting.md#c1--raw-write-host-calls-not-migrated-to-write-uiwrite-status)
- **Current (representative pattern — lines 237–243, the "two-call coloring" anti-pattern):**
  ```powershell
  Write-Host "Computer Name:      " -NoNewline; Write-Host $ramInfo.ComputerName -ForegroundColor Green
  Write-Host "Total Slots:        " -NoNewline; Write-Host $ramInfo.TotalSlots -ForegroundColor Green
  Write-Host "Slots Used:         " -NoNewline; Write-Host "$($ramInfo.UsedSlots) / $($ramInfo.TotalSlots)" -ForegroundColor $(if ($ramInfo.UsedSlots -eq $ramInfo.TotalSlots) { "Yellow" } else { "Green" })
  ```
- **Recommended:**
  ```powershell
  Write-Ui -Message "Computer Name:      $($ramInfo.ComputerName)" -Level "INFO"
  Write-Ui -Message "Total Slots:        $($ramInfo.TotalSlots)" -Level "INFO"
  $usedLevel = if ($ramInfo.UsedSlots -eq $ramInfo.TotalSlots) { "WARN" } else { "OK" }
  Write-Ui -Message "Slots Used:         $($ramInfo.UsedSlots) / $($ramInfo.TotalSlots)" -Level $usedLevel
  ```
- **Risk if changed:** Low — message text preserved, single-line replacement collapses the `Write-Host "label " -NoNewline; Write-Host "value" -ForegroundColor X` pattern that appears ~30 times in the summary blocks.
- **Local notes:** Three categories of raw `Write-Host`:
  1. **Banner / heading separators** — `Write-Host "========================================"` and bare `Write-Host ""` spacer lines (e.g. lines 57, 65, 66, 215, 217, 218, 220, 244, 248–249, 262, 266, 270–271, 282–286, 392–395, 463–466, 731–734, 1074, 1076, 1078, 1079, 1084, 1091, 1151–1152). These fall under the cross-cutting C1 *exception* for visual-separator helpers, but they are noisy. Migrate to a `Show-Section -Title "EXPORT RAM REPORT - CSV FORMAT"` helper if one is added in P4 (covered by C10 once the module gains a section/box helper).
  2. **Two-call inline-color value pairs** — the `Write-Host "label" -NoNewline; Write-Host $value -ForegroundColor Green` pattern at lines 237–243, 254–260. Pure C1 violations.
  3. **Plain `Write-Host "text"` lines** — `Show-Help` body (lines 1108–1150, 41 lines), file-saved-to messages (lines 369–370, 419–420, 437–438, 706–707, 1080–1083). Pure C1 violations.
- **Local notes (cont.) — inline marker prefixes inside `Write-Ui`:** Six `Write-Ui` calls embed `[OK]` / `[ERROR]` brackets inside the message string and then re-bracket them through `-Level "OK"` / `-Level "ERROR"`:
  ```
  Line 817:  Write-Ui -Message "  [OK] TXT exported" -Level "OK"
  Line 819:  Write-Ui -Message "  [ERROR] TXT export failed: $_" -Level "ERROR"
  Line 842:  Write-Ui -Message "  [OK] CSV exported" -Level "OK"
  Line 844:  Write-Ui -Message "  [ERROR] CSV export failed: $_" -Level "ERROR"
  Line 1069: Write-Ui -Message "  [OK] HTML exported" -Level "OK"
  Line 1071: Write-Ui -Message "  [ERROR] HTML export failed: $_" -Level "ERROR"
  ```
  Strip the inline `[OK]` / `[ERROR]` markers so the `[LEVEL]` bracket emitted by `Write-Ui` is the only marker. Same anti-pattern as F2 of `01-modules-SouliTEK-Common.md`.
- **Local notes (cont.) — `Set-SouliTEKConsoleColor`:** All 25 calls become dead weight once `Write-Ui` drives coloring — they exist solely to color the *next* raw `Write-Host`. Delete every one of them during the C1 sweep.
- **Local notes (cont.) — no legacy `Write-SouliTEK*` callers:** Zero occurrences of `Write-SouliTEKInfo` / `Success` / `Warning` / `Error`. This script does not block the C2 deletion.
- **Target phase:** P1 (but defer until after the F3 extraction lands — much of the duplicated rendering code is *what gets deleted*, so doing F1 first means rewriting code that will be removed)

### F2 — `-ErrorAction SilentlyContinue` triage (see C4)
- **Severity:** info (note only — no action needed)
- **Category:** error-handling
- **Location:** scripts/ram_slot_utilization_report.ps1 — **0 occurrences**
- **Reference:** [C4](00-cross-cutting.md#c4----erroraction-silentlycontinue-swallowing-failures)
- **Local notes:** Despite the cross-cutting C4 listing "30 scripts; 186 occurrences total," this script contains none. All the `try { ... } catch { Write-Ui -Message "..." -Level "ERROR" }` blocks (lines 203/378/448/715/818/843/1070) already surface errors via `Write-Ui` — exactly what C4-tag-B prescribes. No remediation needed.
- **Target phase:** —

### F3 — C6: extractable duplication in the export layer
- **Severity:** med
- **Category:** structure (extract candidate)
- **Location:** scripts/ram_slot_utilization_report.ps1 — see breakdown below
- **Reference:** [C6](00-cross-cutting.md#c6--scripts-1000-loc-with-extractable-duplication)

**Function size breakdown (largest first):**

| Function | Lines | LOC | Notes |
|---|---|---|---|
| `Export-RAMReportAll` | 726–1097 | **372** | Re-implements TXT body (lines 757–814), CSV summary projection (lines 825–841), and full HTML document (lines 887–1065) inline. The HTML block is **byte-identical** to lines 519–697 of `Export-RAMReportHTML` (verified — 5628 chars, 178 lines). |
| `Export-RAMReportHTML` | 459–725 | **267** | ~178 of those LOC are the inline HTML+CSS document literal (lines 519–697). |
| `Get-RAMSlotInformation` | 90–209 | 120 | The sole data-collection function — clean and well-shaped; **not** an extract candidate, but the inline `FormFactor` switch (lines 131–157, 27 lines mapping integers 0–23 to text) belongs in a `Get-RAMFormFactor` helper alongside `Get-DDRType`. |
| `Export-RAMReportTXT` | 278–388 | 111 | Lines 302–360 are the TXT body literal — near-identical to lines 757–814 in `Export-RAMReportAll` (1880 vs. 1906 chars, only whitespace differs). |
| `Export-RAMReportCSV` | 389–458 | 70 | Lines 425–434 build the summary `PSCustomObject` — re-built verbatim at lines 830–840 of `Export-RAMReportAll`. |
| `Show-RAMReport` | 210–277 | 68 | Console rendering — already uses some `Write-Ui` but mixes ~32 raw `Write-Host` calls. Not strictly duplicated, but the two-call `"label" -NoNewline; "value" -ForegroundColor Green` pattern (lines 237–243, 254–260) is its own form of repetition. |
| `Show-Help` | 1098–1159 | 62 | 53 of those LOC are plain `Write-Host "..."` lines. A `Show-RAMHelp` `here-string` would collapse this to ~10 LOC. |
| `Show-ExitMessage` | 1160–1195 | 36 | Mostly delegates to `Show-SouliTEKExitMessage`. Not an extract candidate. |
| `Show-MainMenu` | 52–72 | 21 | Clean. |
| `Get-DDRType` | 73–89 | 17 | Clean. SMBIOS memory-type-int → DDR-string mapping. Pure helper. |
| `Show-Disclaimer` | 47–51 | 5 | Trivial wrapper around `Show-SouliTEKDisclaimer`. |

**The rendering layer is ~60% of the script.** Specifically: `Export-RAMReportHTML` (267) + `Export-RAMReportAll` (372) + `Export-RAMReportTXT` (111) + `Export-RAMReportCSV` (70) + `Show-RAMReport` (68) + `Show-Help` (62) = **950 LOC of 1195 (79%)**, with the HTML/TXT bodies actually duplicated in two places.

**Recommended extraction (P4):**

1. Add three pure data-shaping helpers (return strings, never write to disk or host):
   ```powershell
   function Format-RAMReportTxt  { param([Parameter(Mandatory)]$RamInfo) ... }
   function Format-RAMReportCsv  { param([Parameter(Mandatory)]$RamInfo) ... }   # returns the summary PSCustomObject
   function Format-RAMReportHtml { param([Parameter(Mandatory)]$RamInfo) ... }
   ```
2. Add a single thin driver:
   ```powershell
   function Save-RAMReport {
       [CmdletBinding(SupportsShouldProcess)]
       param(
           [ValidateSet('Txt','Csv','Html','All')] [string]$Format,
           [string]$OutputDirectory = (Join-Path $env:USERPROFILE 'Desktop'),
           $RamInfo = (Get-RAMSlotInformation)
       )
       # picks Format-RAMReport* per Format, writes file(s), returns paths
   }
   ```
3. Collapse `Export-RAMReport{TXT,CSV,HTML,All}` to ~10 LOC each — each becomes `Save-RAMReport -Format X` plus the "open file? Y/N" prompt.
4. Move `Get-DDRType` and a new `Get-RAMFormFactor` helper into the same script (or, better, into `SouliTEK-Common.ps1` under a `MODERNIZATION HELPERS` section per C6's plan).

**Risk if changed:** Medium. The HTML document is generated via a `here-string` with embedded `$($ramInfo...)` interpolation — moving it inside a function changes the variable scope from the caller's `$ramInfo` to the parameter `$RamInfo`. A Pester smoke test that compares the new `Format-RAMReportHtml` output against a frozen "golden" fixture (captured from the current script run on a real machine) is mandatory before merging. The TXT body is whitespace-tolerant. The CSV path is trivial.

- **Target phase:** P4 (this is the headline P4 win for the script — and it also unlocks the C1 sweep for free, since the duplicated lines being deleted are almost entirely `Write-Host`s)

### F4 — No `#Requires`, no `[CmdletBinding()]`, no `param()` block
- **Severity:** low
- **Category:** structure
- **Location:** scripts/ram_slot_utilization_report.ps1 — script-level (no `#Requires` directive, no `param()`) and every one of the 11 internal functions (`Show-Disclaimer` line 47, `Show-MainMenu` line 52, `Get-DDRType` line 73, `Get-RAMSlotInformation` line 90, `Show-RAMReport` line 210, `Export-RAMReportTXT` line 278, `Export-RAMReportCSV` line 389, `Export-RAMReportHTML` line 459, `Export-RAMReportAll` line 726, `Show-Help` line 1098, `Show-ExitMessage` line 1160).
- **Local notes:** The script is interactive-only by design (menu loop on lines 1175–1194, no CLI surface), so the absence of `[CmdletBinding()]` is low-severity. But: (a) add `#Requires -Version 5.1` for parity with the cross-cutting floor; (b) `Get-RAMSlotInformation` is a pure data-collection function with no side effects and is a perfect candidate for `[CmdletBinding()]` + `[OutputType([PSCustomObject])]`, which would let callers pipe it and use `-Verbose`; (c) the proposed new `Save-RAMReport` from F3 *must* have `[CmdletBinding(SupportsShouldProcess)]` because it writes to disk. The C5 high-severity pattern (`SupportsShouldProcess` on destructive scripts) does not apply — this script is read-only-plus-export, which is not "destructive" under the C5 definition.
- **Target phase:** P4 (fold into the F3 extraction sweep)

### F5 — `Split-Path -Parent $MyInvocation.MyCommand.Path` instead of `$PSScriptRoot`
- **Severity:** low
- **Category:** structure
- **Location:** scripts/ram_slot_utilization_report.ps1:37
- **Current:**
  ```powershell
  $ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
  ```
- **Recommended:**
  ```powershell
  $ScriptRoot = $PSScriptRoot
  ```
- **Risk if changed:** Low. Identical to F5 of `scripts-driver_integrity_scan.md`. `$PSScriptRoot` is the canonical PS 3.0+ automatic variable; the current form returns `$null` when the script is dot-sourced. C10 will eventually replace this whole `Import SouliTEK Common` block with a single `Import-SouliTEKCommon` call.
- **Target phase:** P4 (fold into the C10 sweep)

### F6 — Hard-coded Desktop output path with no override
- **Severity:** low
- **Category:** structure
- **Location:** scripts/ram_slot_utilization_report.ps1 — lines 300, 411, 424, 481, 750 (`$env:USERPROFILE\Desktop` and `$env:USERPROFILE\Desktop\RAM_Slot_*` literals).
- **Local notes:** Identical pattern to F7 of `scripts-driver_integrity_scan.md`. The export target is hard-coded to the current user's Desktop in five places, which breaks under SYSTEM context (`$env:USERPROFILE` resolves to `C:\Windows\System32\config\systemprofile` and Desktop may not exist there). The proposed `Save-RAMReport -OutputDirectory` parameter from F3 fixes this directly — no separate fix needed once F3 lands. Also note: the timestamp variable `$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"` is rebuilt independently in each export function (lines 299, 410, 480, 749), which means rapid successive clicks on menu options 2/3/4 produce *different* timestamps and confusingly-named files. Move it into `Save-RAMReport` so a single timestamp drives all formats per invocation.
- **Target phase:** P4 (covered by F3's `Save-RAMReport`)

### F7 — Interactive-only loop + `Read-Host` prompts hang under SYSTEM/RMM
- **Severity:** low
- **Category:** structure (UX / RMM safety)
- **Location:** scripts/ram_slot_utilization_report.ps1:1175 (`do { ... } while ($choice -ne "0")`), plus `Read-Host` calls at lines 68 (menu choice), 373, 441, 710, 1086 (all "Open file? (Y/N)" prompts after export). Plus 11 `$Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")` "press any key" pauses at lines 230, 274, 295, 385, 406, 455, 476, 722, 745, 1094, 1155.
- **Local notes:** Same posture as F6 of `scripts-driver_integrity_scan.md`. Under SYSTEM-context RMM execution (flagged in user's CLAUDE.md as a deployment scenario), `Read-Host` and `ReadKey` will hang the worker process. There is no `[Environment]::UserInteractive` gate. If the launcher is ever wired to invoke this script in a non-interactive flow (e.g. to grab the CSV summary for inventory reporting), the script will deadlock. Defer to P4 unless an RMM hang is reported; pairs naturally with the same recommendation against `Wait-SouliTEKKeyPress` (F10 of `01-modules-SouliTEK-Common.md`). A clean fix would be: add `-NonInteractive` switch to the new parameterised entry point from F3, skip the menu loop when present, default to `Export All -OutputDirectory <flag-supplied>`, and exit 0.
- **Target phase:** P4

### F8 — Decorative `[RAM]` ASCII-emoji prefix in HTML title
- **Severity:** info
- **Category:** docs (cosmetic)
- **Location:** scripts/ram_slot_utilization_report.ps1:637 and 1005 — `<h1>[RAM] Slot Utilization Report</h1>`.
- **Local notes:** The `[RAM]` prefix in the HTML `<h1>` is a leftover from the era when console output used `[+]`/`[!]`/`[*]` bracket markers. In an HTML document with its own purple gradient header and styling, the `[RAM]` is meaningless decoration that competes visually with the rest of the layout. Drop it to just `<h1>RAM Slot Utilization Report</h1>`. Trivial, one-character fix, but worth flagging because (a) it appears in the user-facing exported HTML report and (b) it appears in *both* duplicated HTML blocks (lines 637 and 1005), so it survives the F3 extraction only if you remember to delete it from one canonical source.
- **Target phase:** P4 (fold into F3 — exactly the case for extracting `Format-RAMReportHtml` so there's a single source to fix)

### F9 — Empty-slot calculation can produce negative `$emptySlots` on systems with extra DIMMs
- **Severity:** info
- **Category:** correctness (note only — defensive, no fix recommended)
- **Location:** scripts/ram_slot_utilization_report.ps1:108
- **Current:**
  ```powershell
  $emptySlots = $totalSlots - $usedSlots
  ```
- **Local notes:** Some systems report `Win32_PhysicalMemoryArray.MemoryDevices` as a low number (e.g. 2) while `Win32_PhysicalMemory` instance count is higher (e.g. 4 — happens on certain laptops with dual on-board + SODIMM configurations, and on servers with multiple memory arrays where the script's running total on lines 96–99 may still under-count). When that happens, `$emptySlots` becomes negative, and the HTML report's "Slots Empty: -2 (slot %: -50%)" reads badly. The defensive lines 102–105 fallback only kicks in when `$totalSlots -eq 0`, not when `$totalSlots -lt $usedSlots`. A one-line fix would be `$totalSlots = [math]::Max($totalSlots, $usedSlots)` after line 99. Low priority because in practice the symptom is cosmetic (negative count) rather than a crash — but worth a note in the source.
- **Target phase:** P4 (one-line defensive fix; fold into F3 since `Get-RAMSlotInformation` will be touched anyway)

### F10 — Unescaped CIM strings interpolated into HTML output
- **Severity:** info
- **Category:** security (defense-in-depth note)
- **Location:** scripts/ram_slot_utilization_report.ps1:638, 1006 (`$($ramInfo.ComputerName)` in `<p>`); 491–499, 859–867 (`$($slot.DeviceLocator)`, `$($slot.Manufacturer)`, `$($slot.PartNumber)` in `<td>` rows).
- **Local notes:** The HTML report interpolates CIM-sourced strings directly into the document via `here-string` `$(...)` substitution with no HTML-encoding. A pathological computer name or DIMM part-number containing `<`, `>`, `&`, or `"` would break the document structure; the same payload containing `<script>` would execute on open if the user double-clicks the saved HTML and a modern browser doesn't disable inline script execution from `file://`. **Practical risk is very low** — the input comes from SMBIOS/BIOS data which the user already had to install on their own hardware — but the user's CLAUDE.md explicitly says "Output encoding / sanitization — prevent injection at every output point." When `Format-RAMReportHtml` is extracted in F3, wrap each interpolated value in a tiny `Encode-Html` helper (`$s -replace '&','&amp;' -replace '<','&lt;' -replace '>','&gt;' -replace '"','&quot;'`). Aligns with OWASP A03 (Injection).
- **Target phase:** P5 (fold into F3 hardening; treat as a documentation/quality fix rather than a CVE)

## Out-of-scope notes
- Banner block (lines 1–31, 31 lines of `# === / Coded by / IMPORTANT DISCLAIMER`) matches C11 cross-cutting cleanup; covered there. Identical structure to the same block in `driver_integrity_scan.ps1`.
- The `Import SouliTEK Common Functions` block (lines 36–44) is the canonical C10 boilerplate — duplicated in 35 scripts. Covered by C10.
- The `Get-DDRType` switch (lines 73–89) is a clean, well-named lookup table for SMBIOS memory type codes — a model of how to handle enum-to-text mapping. No change needed beyond optionally moving it into `SouliTEK-Common.ps1` so other scripts can reuse it (the C6 "MODERNIZATION HELPERS" section is the right home).
- The `FormFactor` switch (lines 131–157) is its own enum mapping of integers 0–23 to DMTF SMBIOS form-factor strings. Currently inlined inside `Get-RAMSlotInformation`. Extract to `Get-RAMFormFactor` next to `Get-DDRType` for symmetry — both are pure `[int] -> [string]` converters with no side effects. Fold into F3.
- The CIM query pair on lines 92–93 (`Win32_PhysicalMemoryArray` + `Win32_PhysicalMemory`) is correct and idiomatic for PS 5.1+. No change needed.
- The `try { ... } catch { Write-Ui -Message "..." -Level "ERROR" }` blocks at lines 203, 378, 448, 715, 818, 843, 1070 are the C4-tag-B correct pattern (surface error, return / continue). The script earns zero C4 findings.
- The HTML report's CSS is self-contained, mobile-responsive (the `meta viewport` tag plus `repeat(auto-fit, minmax(200px, 1fr))` grid), and avoids external font/CDN dependencies. Good as-is; just dedupe per F3.
- The `Show-Help` body (lines 1098–1156) lists "Administrator privileges (recommended)" — but the script does not check or warn if not running elevated. CIM queries against `Win32_PhysicalMemory` actually work fine without admin on Win 10/11, so the line is misleading; drop "(recommended)" or remove the bullet entirely.
- File ends cleanly at line 1195 with `} while ($choice -ne "0")` — no trailing blank lines (unlike `driver_integrity_scan.ps1` which had 7).
- `Start-Sleep -Seconds 1` on line 444 inside the "open files" branch of `Export-RAMReportCSV` is there to stagger the two `Start-Process` calls so Excel doesn't race on file locking. Defensible but ugly — a P4 cleanup could replace it with `Start-Process -Wait` on the first call.
- **Cross-cutting C3 correction:** `docs/audits/00-cross-cutting.md` line 43 lists this script as one of two files using `Get-WmiObject`. That is wrong — this script uses `Get-CimInstance` already. Edit the C3 entry to read "Files affected: `scripts/product_key_retriever.ps1`" only.
