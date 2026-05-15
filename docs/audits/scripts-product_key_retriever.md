# Audit — scripts/product_key_retriever.ps1

## Inventory
| Item | Value |
|---|---|
| Path           | scripts/product_key_retriever.ps1 |
| LOC            | 559 |
| Functions      | 8 |
| `#Requires`    | `#Requires -Version 5.1` |
| Admin-required | not declared, but practically required (reads `HKLM:\SOFTWARE\Microsoft\Office\*\Registration` subkeys which require administrator on most Windows installs, and queries the SLP/SLS WMI classes whose `OA3xOriginalProductKey` is admin-only) |
| Last touched   | 8675720 — 2026-04-17 |
| Modernization grade | D |

## Summary

A menu-driven product-key recovery tool: queries `SoftwareLicensingProduct` and `SoftwareLicensingService` via WMI for the Windows `OA3xOriginalProductKey`, falls back to decoding the `HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\DigitalProductId` binary blob, then enumerates `HKLM:\SOFTWARE\[WOW6432Node\]Microsoft\Office\{14,15,16}.0\Registration` for Office keys. Results render to console and export to TXT/CSV/HTML via `Export-SouliTEKReport`. The primary issue is C3: both WMI queries (lines 56, 80) use `Get-WmiObject`, which is removed in PowerShell 7 — replacement with `Get-CimInstance` is the single most important migration step. Secondary issue is C1: 29 raw `Write-Host` occurrences, of which 25 are blank-line spacers, 3 are `===` separator bars in `Show-Help`, and exactly one (line 324) is an actual inline-formatting violation (`"      Key: " -NoNewline -ForegroundColor Gray` adjacent to a `Write-Ui` emit on the next line). The script is in noticeably better shape than `driver_integrity_scan.ps1`: zero callers of the C2 dead API (`Write-SouliTEK*`), all 7 documented functions carry `.SYNOPSIS` blocks, no inline `[+]`/`[-]`/`[!]` markers double-mark `Write-Ui` output, and the C11 banner is only 14 lines (vs 32 in the driver script). The 11 `-ErrorAction SilentlyContinue` occurrences are all probe/optional-read patterns and all carry triage tag **A**. Predicted Write-Host count (29) and Get-WmiObject count (2) and SilentlyContinue count (11) all match exactly. The predicted "legal-disclaimer content like wifi_password_viewer — that block falls under C11 exception (keep)" is not applicable here: this script has only the standard 14-line copyright/banner block, no embedded legal disclaimer — the standard C11 collapse applies. Recommended phase entry order: P1 (C3 + the one real C1), then P2 (C4 triage).

## Findings

### F1 — Legacy `Get-WmiObject` (see C3)
- **Severity:** high
- **Category:** legacy-api
- **Location:** scripts/product_key_retriever.ps1:56, 80 (2 occurrences — task plan predicted 2; matches exactly).
- **Reference:** [C3](00-cross-cutting.md#c3--get-wmiobject-removed-in-ps-7)
- **Current:**
  ```powershell
  # Line 56
  $licensing = Get-WmiObject -Class SoftwareLicensingProduct -ErrorAction SilentlyContinue |
               Where-Object { $_.ApplicationID -eq "55c92734-d682-4d71-983e-d6ec3f16059f" -and $_.LicenseStatus -eq 1 }

  # Line 80
  $service = Get-WmiObject -Class SoftwareLicensingService -ErrorAction SilentlyContinue
  ```
- **Recommended:**
  ```powershell
  # Line 56
  $licensing = Get-CimInstance -ClassName SoftwareLicensingProduct -ErrorAction SilentlyContinue |
               Where-Object { $_.ApplicationID -eq "55c92734-d682-4d71-983e-d6ec3f16059f" -and $_.LicenseStatus -eq 1 }

  # Line 80
  $service = Get-CimInstance -ClassName SoftwareLicensingService -ErrorAction SilentlyContinue
  ```
- **Risk if changed:** Low. `Get-CimInstance` returns identical property surface for both classes: `ApplicationID`, `LicenseStatus`, `OA3xOriginalProductKey`, `PartialProductKey`, `Description`, `Name` on `SoftwareLicensingProduct`; `OA3xOriginalProductKey`, `Version` on `SoftwareLicensingService`. Both classes live in the `root\cimv2` namespace which is the CIM default — no `-Namespace` argument needed. Validate on Win 10 and Win 11 with both a retail Windows install (key returned) and a digitally-activated install (key may be empty), and also against a machine with no Office installed (the OfficeRegistration enumeration uses `Get-ItemProperty` not WMI, so it is unaffected). Note: the SLP class also exists on Server SKUs; if this tool is ever run on Windows Server, behavior is identical for both APIs.
- **Target phase:** P1

### F2 — Raw `Write-Host` calls (see C1)
- **Severity:** med
- **Category:** output-style
- **Location:** scripts/product_key_retriever.ps1 — 29 raw `Write-Host` occurrences (task plan predicted 29; matches exactly). Breakdown below.
- **Reference:** [C1](00-cross-cutting.md#c1--raw-write-host-calls-not-migrated-to-write-uiwrite-status)
- **Current (the one real C1 violation — line 324):**
  ```powershell
  Write-Host "      Key: " -NoNewline -ForegroundColor Gray
  if ($keyInfo.Status -eq "Found") {
      Write-Ui -Message $keyInfo.Key -Level "OK"
  } else {
      Write-Ui -Message $keyInfo.Key -Level "WARN"
  }
  ```
- **Recommended:**
  ```powershell
  if ($keyInfo.Status -eq "Found") {
      Write-Ui -Message "      Key: $($keyInfo.Key)" -Level "OK"
  } else {
      Write-Ui -Message "      Key: $($keyInfo.Key)" -Level "WARN"
  }
  ```
- **Risk if changed:** Low — message text preserved, the "Key: " prefix moves from a gray inline-color emit to the same line as the value (which is the correct visual grouping anyway). The `[OK]` / `[WARN]` bracket from `Write-Ui` replaces the manual `-ForegroundColor Gray` styling.
- **Local notes:** Triage of all 29 occurrences:
  1. **Blank-line / spacer calls (25 occurrences, NOT C1 violations under STYLE_GUIDE.md "visual separator helpers" exception):** lines 308, 312, 316, 334, 339, 343, 356, 370, 372, 385, 447, 451, 455, 461, 466, 472, 477, 482, 497, 504, 507, 510, 513, 516, 518. Bare `Write-Host ""` used as vertical spacing. Leave as-is or migrate to a `Write-Ui -Spacer` / `Show-Section` helper if one is added in P4.
  2. **Separator-bar calls in `Show-Help` (3 occurrences):** lines 448, 450, 483 emit `"============================================================" -ForegroundColor Cyan`. These are visual section delimiters around the help banner. Two acceptable options at P1: (a) keep them as-is (separator helper exception, same as the spacer rule); (b) replace the three of them with a single `Show-Section "PRODUCT KEY RETRIEVER - HELP"` call at the top of `Show-Help` (line 449 already does that work in a `Write-Ui INFO`, so the manual ASCII bars are decorative — `Show-Section` would render the bracket-bar treatment automatically). Option (b) is the cleaner sweep target.
  3. **Real inline-format C1 violation (1 occurrence):** line 324 `Write-Host "      Key: " -NoNewline -ForegroundColor Gray` — see Current/Recommended above.
- **Local notes (cont.) — no C2 dead-API callers:** Zero calls to `Write-SouliTEKResult`/`Info`/`Success`/`Warning`/`Error` in this script. The file is already on `Write-Ui`. When the C2 deletion lands in P1, no caller changes are required here.
- **Target phase:** P1

### F3 — `-ErrorAction SilentlyContinue` triage (see C4)
- **Severity:** med
- **Category:** error-handling
- **Location:** scripts/product_key_retriever.ps1 — 11 occurrences (task plan predicted 11; matches exactly).
- **Reference:** [C4](00-cross-cutting.md#c4----erroraction-silentlycontinue-swallowing-failures)
- **Triage:**
  - Line 56: tag **A** — `Get-WmiObject -Class SoftwareLicensingProduct -ErrorAction SilentlyContinue` is wrapped in `try { ... } catch { Write-Ui -Message "WMI method failed: $_" -Level "WARN" }`. The class is empty on systems without Windows licensing service (rare but possible in stripped Win PE images) and the `if ($licensing)` check on line 59 handles `$null`. Probe semantics. Add `# safe: probe` comment in P2. NOTE: this comment becomes unnecessary after F1's `Get-CimInstance` migration if the SilentlyContinue is dropped at the same time — `Get-CimInstance` against a missing class throws a clean CIM exception that the existing `try` block already handles.
  - Line 80: tag **A** — same pattern as line 56 for `SoftwareLicensingService`. Add `# safe: probe` comment, or drop in the F1 sweep.
  - Line 100: tag **A** — `(Get-ItemProperty -Path $regPath -Name DigitalProductId -ErrorAction SilentlyContinue).DigitalProductId` reads an optional registry value; the `if ($digitalProductId)` guard on line 102 handles absence. Legitimate "may not exist" read. Add `# safe: optional registry value` comment.
  - Line 103: tag **A** — `(Get-ItemProperty -Path $regPath -Name ProductName -ErrorAction SilentlyContinue).ProductName` — same pattern; `ProductName` is non-essential metadata. Add `# safe: optional registry value` comment.
  - Line 104: tag **A** — `DisplayVersion` lookup, same pattern. Add `# safe: optional registry value`.
  - Line 105: tag **A** — `EditionID` lookup, same pattern. Add `# safe: optional registry value`.
  - Line 132: tag **A** — duplicate of line 103 inside the `if ($keys.Count -eq 0)` fallback block (used to render version info even when no key is recovered). Same triage. Add `# safe: optional registry value`.
  - Line 133: tag **A** — duplicate of line 104, same triage.
  - Line 134: tag **A** — duplicate of line 105, same triage.
  - Line 226: tag **A** — `Get-ChildItem -Path $officeVersion.Path -ErrorAction SilentlyContinue` enumerates Office registration subkeys; the surrounding `Test-Path $officeVersion.Path` on line 222 already guards the parent, but a race-condition (key removed between `Test-Path` and `Get-ChildItem`) could otherwise leak a non-terminating error. Defensive probe inside a `try`/`catch`. Add `# safe: probe` comment.
  - Line 230: tag **A** — `Get-ItemProperty -Path $regKey.PSPath -ErrorAction SilentlyContinue` reads the per-registration property bag; the value is then defensively interrogated via `$props.PSObject.Properties.Name -contains "..."` checks (lines 232, 238, 249, 262), and the whole block is inside a `try`/`catch` that emits `Write-Ui -Level "WARN"` on failure. Legitimate cautious read of an Office registration subkey whose schema varies by version. Add `# safe: optional read` comment.
- **Target phase:** P2

### F4 — No `[CmdletBinding()]` on script or any function
- **Severity:** low
- **Category:** structure
- **Location:** scripts/product_key_retriever.ps1 — script-level (top of file, no `param()` block at all) and every one of the 8 internal functions (`Get-WindowsProductKey` line 45, `Convert-DigitalProductIdToKey` line 155, `Get-OfficeProductKeys` line 203, `Show-ProductKeys` line 300, `Invoke-FullScan` line 348, `Export-ProductKeys` line 378, `Show-Help` line 440, `Show-Menu` line 488).
- **Local notes:** The script is fully interactive (no `param()` block, no CLI surface), so this is low-severity. Of the 8 functions only `Convert-DigitalProductIdToKey` already declares a `param([Parameter(Mandatory)][byte[]]$DigitalProductId)` block (line 163) and would benefit immediately from `[CmdletBinding()]` to gain `-Verbose` / `-ErrorAction` support — useful when an operator wants to debug a failing decode against a malformed `DigitalProductId` blob in the wild. The other 7 functions take no parameters and would gain nothing concrete. If `Export-ProductKeys` ever grows a non-interactive `-OutputPath` / `-Format` parameter (parallel to `driver_integrity_scan.ps1`'s F4 suggestion) it should land with `[CmdletBinding()]` from day one. This is C5 territory only if the script gets a non-interactive parameterised entry point.
- **Target phase:** P4

### F5 — `Split-Path -Parent $MyInvocation.MyCommand.Path` instead of `$PSScriptRoot`
- **Severity:** low
- **Category:** structure
- **Location:** scripts/product_key_retriever.ps1:25
- **Current:**
  ```powershell
  $Script:ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
  $Script:RootPath = Split-Path -Parent $Script:ScriptPath
  ```
- **Recommended:**
  ```powershell
  $Script:ScriptPath = $PSScriptRoot
  $Script:RootPath = Split-Path -Parent $PSScriptRoot
  ```
- **Risk if changed:** Low. `$PSScriptRoot` is the canonical PS 3.0+ automatic variable for "directory of the running script" and returns the correct path under both regular invocation and dot-sourcing. `$MyInvocation.MyCommand.Path` returns `$null` when the script is dot-sourced, so the current form is slightly more fragile. C10 will eventually replace this whole `$CommonPath` / `Test-Path` / dot-source block with `Import-SouliTEKCommon`, but until then this one-line fix is free. Same finding as F5 of scripts-driver_integrity_scan.md — fold them together in the P4 sweep.
- **Target phase:** P4 (fold into the C10 sweep)

### F6 — Infinite menu loop with no non-interactive exit + blocking `Read-Host` / `Wait-SouliTEKKeyPress`
- **Severity:** low
- **Category:** structure (UX / RMM safety)
- **Location:** scripts/product_key_retriever.ps1:530 (`do { ... } while ($true)`), `Read-Host` at line 532, plus `Wait-SouliTEKKeyPress` calls at lines 345, 387, 437, 485.
- **Local notes:** The script is interactive-only by design — the only graceful exit is menu option `[0]` which calls `exit 0` (line 541). Under SYSTEM-context RMM execution (flagged in user's CLAUDE.md as a deployment scenario), `Read-Host` and `Wait-SouliTEKKeyPress` will both hang the worker process. There is no `[Environment]::UserInteractive` gate and no `-NonInteractive` switch. Same defect as F6 of scripts-driver_integrity_scan.md; defer to P4 unless an actual RMM hang report comes in. Pairs naturally with the same recommendation against `Wait-SouliTEKKeyPress` (F10 of 01-modules-SouliTEK-Common.md).
- **Target phase:** P4

### F7 — `Show-Help` hand-rolls a banner that `Show-Section` already provides
- **Severity:** info
- **Category:** output-style
- **Location:** scripts/product_key_retriever.ps1:447–483 (the `Show-Help` body).
- **Local notes:** Lines 447–451 and 483 emit `Write-Host "===…==="` separator bars around a single `Write-Ui` title line, then the body uses paired `Write-Ui -Level "WARN"` (section header) + `Write-Ui -Level "INFO"` (bullet) blocks. The cleaner pattern is one `Show-Section "PRODUCT KEY RETRIEVER - HELP"` call at the top (which renders its own bracketed header bar per `SouliTEK-Common.ps1`'s `Show-Section`), then bullet content. This is what F2's option (b) is asking for and what the `Get-WindowsProductKey` /  `Show-ProductKeys` flows already do consistently. Fold into the P1 C1 sweep when option (b) is chosen for the three separator-bar `Write-Host` calls.
- **Target phase:** P1 (cosmetic, paired with F2 option b)

### F8 — Hard-coded Desktop output path with no override
- **Severity:** info
- **Category:** structure
- **Location:** scripts/product_key_retriever.ps1:398 (`$desktopPath = [Environment]::GetFolderPath("Desktop")`).
- **Local notes:** The export target is hard-coded to the current user's Desktop via the .NET special-folder API. This is *better* than `$env:USERPROFILE\Desktop` (which `driver_integrity_scan.ps1` uses) because `[Environment]::GetFolderPath("Desktop")` correctly returns `C:\Windows\system32\config\systemprofile\Desktop` under SYSTEM context (a path that exists by default), so the export at least won't crash. It still offers no way to redirect. Low priority because the menu-driven design assumes interactive use, but a `-OutputDirectory` parameter on `Export-ProductKeys` would be a clean follow-up alongside F4's `[CmdletBinding()]` add.
- **Target phase:** P4

### F9 — Sensitive output (product keys) written to disk without access-control consideration
- **Severity:** med
- **Category:** security
- **Location:** scripts/product_key_retriever.ps1:420–435 (`Export-ProductKeys` body — writes `Product_Keys_$timestamp.{txt,csv,html}` to Desktop via `Export-SouliTEKReport`).
- **Local notes:** Product keys are credential-grade secrets per CLAUDE.md ("Default assumption: gitignore anything that looks like a secret") and the script's own `Show-Help` text (line 474: "Product keys are sensitive information"). The export writes plaintext keys to a Desktop path that inherits default user-profile ACLs (Users group readable on many shares; `%PUBLIC%` redirection on roaming profiles). There is no warning to the operator, no opt-in confirmation, and no mention in the export of the sensitivity. Recommended changes (any combination, P4 candidates):
  1. Show a confirmation prompt before `Export-SouliTEKReport` runs (e.g. `Read-Host "Export plaintext product keys to $outputPath? [y/N]"`) — matches `Show-Help`'s line 475 "Store exported files securely" warning by giving the operator a chance to abort.
  2. Add a banner at the top of every exported file (TXT/CSV/HTML) explicitly marking it as containing recoverable Windows/Office license credentials.
  3. Restrict the new file's ACL to the current user only (`icacls $outputPath /inheritance:r /grant:r "$env:USERNAME:(R,W)"`) — defense-in-depth against the Desktop being on a roaming/redirected profile or a shared workstation.
- **Target phase:** P4

## Out-of-scope notes
- Banner block (lines 1–14, 14 lines of `# === / Coded by / (C)`) matches C11 cross-cutting cleanup; covered there. The task plan's note that this script "has legal-disclaimer content like wifi_password_viewer — that block falls under C11 exception (keep)" is **not** applicable: this script has only the standard copyright/banner block, no embedded legal-use disclaimer. The standard C11 collapse to 3 lines applies normally.
- All 7 documented functions carry `.SYNOPSIS` blocks (`Get-WindowsProductKey` line 47, `Convert-DigitalProductIdToKey` line 157 with bonus `.DESCRIPTION`, `Get-OfficeProductKeys` line 205, `Show-ProductKeys` line 302, `Invoke-FullScan` line 350, `Export-ProductKeys` line 380, `Show-Help` line 442, `Show-Menu` line 490). The task plan's flag of ".SYNOPSIS block quality on public functions" was a precautionary check; nothing to fix here.
- The `Convert-DigitalProductIdToKey` algorithm (lines 168–200) is the standard published DigitalProductId base-24 decoder, faithfully translated from the well-known C# / VBScript implementations. The byte-array mutation in place on line 184 (`$DigitalProductId[$keyStartOffset + $j] = [Math]::Floor($cur / 24)`) is intentional — the algorithm consumes the input in successive divmod-24 passes. No change needed. (Aside: the input array is mutated even though the parameter is not declared `[ref]`; PowerShell passes byte arrays by reference under the hood, so the caller's `$digitalProductId` on line 100 is also clobbered, but it is not re-used after the call so this is harmless. Worth a comment if the function ever becomes public.)
- The `Get-OfficeProductKeys` enumeration list (lines 212–219) covers Office 14.0/15.0/16.0 in both `HKLM:\SOFTWARE` and `HKLM:\SOFTWARE\WOW6432Node` flavors. Comprehensive for the supported Office generations.
- The trailing 11 blank lines at the end of the file (lines 549–559, with line 559 the EOF) are harmless but could be trimmed in any pass that touches the file. Same observation as scripts-driver_integrity_scan.md's "trailing 7 blank lines."
- The `Export-SouliTEKReport` integration on lines 432–434 (uses `-OpenAfterExport:($formats.Count -eq 1)` to suppress the auto-open behavior when exporting to ALL three formats at once) is a thoughtful UX choice — same pattern recommended for other multi-format exporters in P4. No change needed.
- No file-read I/O surface in this script: no `Get-Content`, no `[System.IO.File]::ReadAllText`, no path-traversal-prone external input. `Test-SafeFilePath` is correctly not used (would be overkill for the registry + WMI surface this script touches). The task plan's flag "check `Test-SafeFilePath` usage if it reads any files" is satisfied by inspection — there are no file reads to guard.
- The C2 audit's "verify zero remaining callers" sweep can mark this file clean: zero calls to `Write-SouliTEKResult` / `Write-SouliTEKInfo` / `Write-SouliTEKSuccess` / `Write-SouliTEKWarning` / `Write-SouliTEKError`. The file is already on the `Write-Ui` API.
