# Audit — scripts/essential_tweaks.ps1

## Inventory
| Item | Value |
|---|---|
| Path           | scripts/essential_tweaks.ps1 |
| LOC            | 666 |
| Functions      | 15 (one is the `Add-TweakResult` helper; 14 user-facing) |
| `#Requires`    | `#Requires -Version 5.1` only (no `#Requires -RunAsAdministrator` despite the script self-checking admin via `Test-SouliTEKAdministrator` at line 613 and `exit 1`-ing if absent) |
| Admin-required | yes (declared at runtime by the admin self-check on line 613; mutates `HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot` at line 454, calls `Checkpoint-Computer` at line 503 and `Enable-ComputerRestore` at line 492 — all require elevation) |
| Last touched   | 8675720 — 2026-04-17 |
| Modernization grade | D |

## Summary

A menu-driven Windows-tweaks tool: applies 10 user-configurable system mutations (default-app pickers, Hebrew/English keyboard layouts, Hebrew display language, Start Menu ads off, Chrome pinned to taskbar, taskbar "End Task" on, Copilot off, system restore point). The biggest issues are (1) **destructive without any `ShouldProcess` gate** — 18 mutation sites across 8 destructive functions touch the registry (`HKCU:` x 5 paths, `HKLM:` x 1 path), call `Set-WinUserLanguageList` three times to mutate the user language profile, invoke `Checkpoint-Computer` and `Enable-ComputerRestore`, and pin Chrome to the taskbar via shell COM `InvokeVerb`, none of which surface `-WhatIf`/`-Confirm` to the operator (C5); (2) **28 raw `Write-Host` calls** mix bare-spacer `Write-Host ""`, inline-color formatting (`Write-Host -NoNewline "  Enter your choice: " -ForegroundColor Cyan` at lines 104, 573, 652, 656), and manual `[symbol]`/color rendering inside `Show-Summary` (lines 527, 530, 550–551) that should be the `Write-Ui` `[LEVEL]` bracket (C1); (3) the two `-ErrorAction SilentlyContinue` occurrences (lines 486 and 492 — both inside `New-SystemRestorePoint`) are tag-A and tag-B respectively. Secondary concerns: no `[CmdletBinding()]` anywhere; uses `Split-Path -Parent $MyInvocation.MyCommand.Path` instead of `$PSScriptRoot` (line 44); function names `Pin-ChromeToTaskbar` (line 357) and `Apply-AllTweaks` (line 562) use unapproved verbs (`Pin`, `Apply`); the main `while ($true)` loop with three `Read-Host` gates would hang under SYSTEM/RMM execution; many `Write-Ui` calls smuggle indent whitespace into the message (`"  Please install Chrome first"`) which double-indents under the `[LEVEL]` prefix; and `Get-WmiObject` is not used here so C3 is N/A. The 36-line banner block (lines 1–36) matches C11. Recommended phase entry order: P3 (C5 — the script is destructive and merits the `SupportsShouldProcess` wrap first), then P1 (C1), then P2 (C4 triage).

## Findings

### F1 — Mutation sites needing `ShouldProcess` (see C5)
- **Severity:** high
- **Category:** safety
- **Location:** scripts/essential_tweaks.ps1 — 18 mutation sites across 8 destructive functions
- **Reference:** [C5](00-cross-cutting.md#c5--destructive-scripts-lack-cmdletbindingsupportsshouldprocess--whatif-confirm)
- **Enumeration of every mutation site:**
  - **`Set-ChromeAsDefaultBrowser` (line 107):**
    - L136 — `Start-Process "ms-settings:defaultapps"` — launches Settings UI for manual default-browser pick (no direct mutation, but UX-altering)
  - **`Set-AcrobatAsDefaultPDF` (line 154):**
    - L184 — `Start-Process "ms-settings:defaultapps"` — same as above for PDF default
  - **`Add-HebrewKeyboard` (line 202):**
    - L219 — `Set-WinUserLanguageList $languageList -Force` — adds `he-IL` to the user's installed input languages
  - **`Add-EnglishKeyboard` (line 236):**
    - L253 — `Set-WinUserLanguageList $languageList -Force` — adds `en-US` to the user's installed input languages
  - **`Set-HebrewAsDisplayLanguage` (line 270):**
    - L298 — `Set-WinUserLanguageList $languageList -Force` — reorders the user language list to promote `he-IL` to position 0 (primary display language; sign-out required to take effect)
  - **`Disable-StartMenuAds` (line 316):**
    - L325 — `New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Force` — creates the registry key if absent
    - L339 — `Set-ItemProperty -Path $regPath -Name $setting.Key -Value $setting.Value -Type DWord` — **six DWORD writes in a foreach loop** to disable: `SystemPaneSuggestionsEnabled`, `SubscribedContent-338393Enabled`, `SubscribedContent-353694Enabled`, `SubscribedContent-353696Enabled`, `SubscribedContent-338388Enabled`, `SubscribedContentEnabled`
  - **`Pin-ChromeToTaskbar` (line 357):**
    - L389 — `$item.InvokeVerb("taskbarpin")` — shell COM call pinning Chrome to the taskbar (note: Microsoft removed the `taskbarpin` verb on Windows 10 22H2+; this silently no-ops on modern Windows and the surrounding `try/catch` will not see it because COM does not raise — the script will report SUCCESS for a non-effect)
  - **`Enable-TaskbarEndTask` (line 405):**
    - L414 — `New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Force` — creates the registry key if absent
    - L418 — `Set-ItemProperty -Path $regPath -Name "TaskbarEndTask" -Value 1 -Type DWord` — enables the Win 11 taskbar "End Task" right-click option
  - **`Disable-Copilot` (line 436):**
    - L444 — `New-Item -Path "HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot" -Force` — creates the user-policy key
    - L446 — `Set-ItemProperty -Path $userRegPath -Name "TurnOffWindowsCopilot" -Value 1 -Type DWord` — user-level Copilot kill switch
    - L452 — `New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" -Force` — creates the system-policy key (HKLM — admin required)
    - L454 — `Set-ItemProperty -Path $systemRegPath -Name "TurnOffWindowsCopilot" -Value 1 -Type DWord` — system-level Copilot kill switch (HKLM)
    - L460 — `New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Force` — creates the Explorer Advanced key if absent (idempotent with L414 but unguarded)
    - L462 — `Set-ItemProperty -Path $explorerPath -Name "ShowCopilotButton" -Value 0 -Type DWord` — hides the taskbar Copilot button
  - **`New-SystemRestorePoint` (line 480):**
    - L492 — `Enable-ComputerRestore -Drive "$systemDrive\"` — enables System Restore for the system drive (mutates `HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore` and related WMI providers; the `-ErrorAction SilentlyContinue` here is a separate finding — see F3)
    - L503 — `Checkpoint-Computer -Description $description -RestorePointType "MODIFY_SETTINGS"` — actually creates the restore point (writes to `\System Volume Information\SPP\`)
- **Current (representative — `Disable-StartMenuAds` lines 320–340):**
  ```powershell
  function Disable-StartMenuAds {
      Show-SouliTEKHeader -Title "DISABLE START MENU ADS" -ClearHost -ShowBanner
      Write-Ui -Message "Disabling Start Menu ads and suggestions..."

      try {
          $regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"

          if (-not (Test-Path $regPath)) {
              New-Item -Path $regPath -Force | Out-Null
          }

          $settings = @{
              "SystemPaneSuggestionsEnabled"      = 0
              "SubscribedContent-338393Enabled"   = 0
              "SubscribedContent-353694Enabled"   = 0
              "SubscribedContent-353696Enabled"   = 0
              "SubscribedContent-338388Enabled"   = 0
              "SubscribedContentEnabled"          = 0
          }

          foreach ($setting in $settings.GetEnumerator()) {
              Set-ItemProperty -Path $regPath -Name $setting.Key -Value $setting.Value -Type DWord -ErrorAction Stop
          }
          ...
  ```
- **Recommended:**
  ```powershell
  function Disable-StartMenuAds {
      [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
      param()

      Show-SouliTEKHeader -Title "DISABLE START MENU ADS" -ClearHost -ShowBanner
      Write-Ui -Message "Disabling Start Menu ads and suggestions..." -Level "STEP"

      try {
          $regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"

          if (-not (Test-Path $regPath)) {
              if ($PSCmdlet.ShouldProcess($regPath, 'Create registry key')) {
                  New-Item -Path $regPath -Force | Out-Null
              }
          }

          $settings = @{
              "SystemPaneSuggestionsEnabled"      = 0
              "SubscribedContent-338393Enabled"   = 0
              "SubscribedContent-353694Enabled"   = 0
              "SubscribedContent-353696Enabled"   = 0
              "SubscribedContent-338388Enabled"   = 0
              "SubscribedContentEnabled"          = 0
          }

          foreach ($setting in $settings.GetEnumerator()) {
              $target = "${regPath}\$($setting.Key)"
              $action = "Set DWord = $($setting.Value)"
              if ($PSCmdlet.ShouldProcess($target, $action)) {
                  Set-ItemProperty -Path $regPath -Name $setting.Key -Value $setting.Value -Type DWord -ErrorAction Stop
              }
          }
          ...
  ```
  Apply the same pattern to **every function listed above**. The script itself should also gain `[CmdletBinding(SupportsShouldProcess, ConfirmImpact='High')]` at top so `-WhatIf` propagates from the launcher (see F4).
- **Risk if changed:** Medium. The `[CmdletBinding(SupportsShouldProcess)]` plumbing is mechanical, but each `if ($PSCmdlet.ShouldProcess(...)) { ... }` site needs both arguments correct (`-Target` = the resource being changed, `-Action` = a verb-phrase) so that `-WhatIf` output reads cleanly. Default behavior is preserved when neither `-WhatIf` nor `-Confirm` is passed. CRITICAL: `ConfirmImpact='High'` would prompt on every run by default — `'Medium'` is the right choice for most of these tweaks (registry DWORDs); `New-SystemRestorePoint` is genuinely `'High'`. Test by running each function with `-WhatIf` and verifying zero side effects (zero new registry keys, zero language list changes, zero restore points).
- **Local notes (action verb naming under fix):** While reworking each function for ShouldProcess, fix two unapproved-verb names: `Pin-ChromeToTaskbar` (line 357) → `Set-ChromeTaskbarPin` or `Add-ChromeToTaskbar`, and `Apply-AllTweaks` (line 562) → `Invoke-AllTweaks` or `Set-AllEssentialTweaks`. PSScriptAnalyzer flags both under `PSUseApprovedVerbs`. Both are internal-only callers in the same file, so the rename is local.
- **Local notes (Pin-Chrome shell-COM no-op on modern Windows):** Lines 386–389 use `Shell.Application.InvokeVerb("taskbarpin")`. Microsoft removed the pinnable `taskbarpin` verb on Windows 10 22H2 and on all Windows 11 builds; the call silently succeeds but does nothing, and the function reports `SUCCESS`. This is a correctness bug — separate from ShouldProcess, but worth noting in the same fix pass since it's the function with the weakest signal. The modern alternative is to drop a `.lnk` into `%APPDATA%\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar` and notify the shell, but support is patchy. Recommendation: detect Windows version and either skip with `Write-Ui -Message "Taskbar pin is not supported on Windows 11; please pin manually" -Level "WARN"` or remove this option entirely. Flag for P3 design discussion.
- **Target phase:** P3

### F2 — Raw `Write-Host` calls (see C1)
- **Severity:** med
- **Category:** output-style
- **Location:** scripts/essential_tweaks.ps1 — 28 raw `Write-Host` occurrences (lines 90, 103, 104, 514, 526, 527, 530, 533, 535, 550, 551, 559, 567, 569, 572, 573, 581, 583, 600, 602, 616, 638, 640, 644, 651, 652, 655, 656)
- **Reference:** [C1](00-cross-cutting.md#c1--raw-write-host-calls-not-migrated-to-write-uiwrite-status)
- **Current (representative pattern — inline-color formatting at line 104):**
  ```powershell
  Write-Host -NoNewline "  Enter your choice: " -ForegroundColor Cyan
  ```
- **Recommended:**
  ```powershell
  Write-Ui -Message "Enter your choice:" -Level "STEP" -NoNewline
  ```
  (Or use `$choice = Read-Host -Prompt 'Enter your choice'` and drop the separate write entirely — see F6.)
- **Risk if changed:** Low — pure replacement. Message text preserved verbatim; the `[STEP]` bracket emitted by `Write-Ui` replaces the manual cyan formatting.
- **Local notes:** Three categories of raw `Write-Host` in this file:
  1. **Blank-line / spacer calls** — bare `Write-Host ""` used as vertical spacing (lines 90, 103, 514, 526, 533, 535, 559, 567, 569, 572, 581, 583, 600, 602, 616, 638, 640, 644, 651, 655). Per C1's "visual separator helpers" exception, these may stay as-is, but the file would read more cleanly with a `Write-Ui -Spacer` helper added in P4 to replace all of them at once.
  2. **Inline-color "Enter your choice:" / "Press Enter to continue..." prompts** — lines 104, 573, 652, 656. Real C1 violations: pre-`Write-Ui` cyan formatting on prompt strings. Migrate to `Write-Ui -Message "..." -Level "STEP" -NoNewline` (or eliminate by switching to `Read-Host -Prompt`).
  3. **Manual `[symbol]`-color rendering inside `Show-Summary`** — lines 527 (`Write-Host "  Successful: " -NoNewline -ForegroundColor Gray`), 530 (`Write-Host "  Errors: " -NoNewline -ForegroundColor Gray`), 550 (`Write-Host "  [$($result.Time)] " -NoNewline -ForegroundColor Gray`), 551 (`Write-Host "$statusSymbol " -NoNewline -ForegroundColor $statusColor`). These are the deepest C1 violations because they hand-roll the same `[symbol]`-coloured-prefix UI that `Write-Ui` already produces. The cleanest rework is to drop the `$statusSymbol` switch (lines 544–548) and the `$statusColor` switch (lines 538–542) entirely and let `Write-Ui -Level $level` emit both, with a small `Status -> Level` translator (`SUCCESS -> OK`, `ERROR -> ERROR`, default -> `INFO`).
- **Local notes (cont.) — inline indent in `Write-Ui` messages:** Many `Write-Ui` calls embed leading `"  "` whitespace inside the message string (lines 91–102 menu items, 177, 187, 188, 222, 256, 301, 302, 343, 379, 421, 422, 465, 466, 490, 501, 515, 525, 534, 555, 565, 566, 568, 570, 571, 582, 615, 645). Combined with the `[LEVEL]` prefix that `Write-Ui` already prepends, the output is double-indented. Strip these in the same C1 sweep.
- **Local notes (cont.) — no legacy `Write-SouliTEK*` callers:** This file does not call any of the C2 dead-API functions, so the C2 migration step is N/A here.
- **Target phase:** P1

### F3 — `-ErrorAction SilentlyContinue` triage (see C4)
- **Severity:** med
- **Category:** error-handling
- **Location:** scripts/essential_tweaks.ps1 — 2 occurrences (both inside `New-SystemRestorePoint`)
- **Reference:** [C4](00-cross-cutting.md#c4----erroraction-silentlycontinue-swallowing-failures)
- **Triage:**
  - **Line 486:** tag **A** — `$restoreEnabled = Get-ComputerRestorePoint -ErrorAction SilentlyContinue` is a probe. `Get-ComputerRestorePoint` throws when System Restore is disabled on the drive (rather than returning empty); swallowing the error and using `if (-not $restoreEnabled)` is the legitimate probe pattern. Add `# safe: probe — Get-ComputerRestorePoint throws when SR is disabled, we want a null-ish answer` comment in P2.
  - **Line 492:** tag **B** — `$enableResult = Enable-ComputerRestore -Drive "$systemDrive\" -ErrorAction SilentlyContinue` paired with `if (-not $?) { Write-Ui -Message "Could not enable System Restore automatically" }`. The `-not $?` test does catch the failure path, but the message that follows (`Write-Ui -Message "Could not enable System Restore automatically"` line 494, no `-Level` so it defaults to INFO) loses both the actual exception text and the severity. **This is exactly the C4 tag-B "swallowing a real bug" pattern.** Replace with:
    ```powershell
    try {
        Enable-ComputerRestore -Drive "$systemDrive\" -ErrorAction Stop
    } catch {
        Write-Ui -Message "Could not enable System Restore automatically: $($_.Exception.Message)" -Level "WARN"
    }
    ```
    Apply during P2.
- **Target phase:** P2

### F4 — No `[CmdletBinding()]` on script or any function
- **Severity:** low (escalates to **high** under the F1 ShouldProcess fix — they share a fix pass)
- **Category:** structure
- **Location:** scripts/essential_tweaks.ps1 — script-level (top of file, no `param()` block at all) and every one of the 14 functions: `Add-TweakResult` (line 65), `Show-Menu` (line 86), `Set-ChromeAsDefaultBrowser` (line 107), `Set-AcrobatAsDefaultPDF` (line 154), `Add-HebrewKeyboard` (line 202), `Add-EnglishKeyboard` (line 236), `Set-HebrewAsDisplayLanguage` (line 270), `Disable-StartMenuAds` (line 316), `Pin-ChromeToTaskbar` (line 357), `Enable-TaskbarEndTask` (line 405), `Disable-Copilot` (line 436), `New-SystemRestorePoint` (line 480), `Show-Summary` (line 522), `Apply-AllTweaks` (line 562), `Start-EssentialTweaks` (line 609).
- **Local notes:** No `[CmdletBinding()]` anywhere. The F1 ShouldProcess fix forces `[CmdletBinding(SupportsShouldProcess)]` onto every destructive function and onto the script itself — fold this finding into that pass. Non-destructive helpers (`Add-TweakResult`, `Show-Menu`, `Show-Summary`) and `Start-EssentialTweaks` don't strictly need `[CmdletBinding()]`, but adding it to `Start-EssentialTweaks` plus a `param([switch]$NonInteractive)` would let the menu loop be skipped under SYSTEM/RMM (see F6).
- **Target phase:** P3 (with F1)

### F5 — `Split-Path -Parent $MyInvocation.MyCommand.Path` instead of `$PSScriptRoot`
- **Severity:** low
- **Category:** structure
- **Location:** scripts/essential_tweaks.ps1:44
- **Current:**
  ```powershell
  $ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
  $CommonPath = Join-Path (Split-Path -Parent $ScriptRoot) "modules\SouliTEK-Common.ps1"
  ```
- **Recommended:**
  ```powershell
  $CommonPath = Join-Path (Split-Path -Parent $PSScriptRoot) "modules\SouliTEK-Common.ps1"
  ```
- **Risk if changed:** Low. `$PSScriptRoot` is the canonical PS 3.0+ automatic variable for "directory of the running script." `$MyInvocation.MyCommand.Path` returns `$null` when the script is dot-sourced, so the current form is slightly more fragile. C10 will eventually replace this whole block with `Import-SouliTEKCommon`, but until then the one-line fix is free.
- **Target phase:** P4 (fold into the C10 sweep)

### F6 — Infinite menu loop with blocking `Read-Host` prompts (no non-interactive path)
- **Severity:** low
- **Category:** structure (UX / RMM safety)
- **Location:** scripts/essential_tweaks.ps1:621 (`while ($true)`), plus `Read-Host` calls at lines 575, 617, 623, 653, 657.
- **Local notes:** The only graceful exit is menu option `[0]` which calls `exit 0` (line 641). Under SYSTEM-context RMM execution (flagged in user's CLAUDE.md as a deployment scenario), every `Read-Host` will hang the worker process indefinitely. There is no `[Environment]::UserInteractive` gate and no `-NonInteractive`/`-AutoApply` switch. Given that this script is destructive (F1), a `-WhatIf`-aware non-interactive entry point would be a natural P3 follow-up: `Start-EssentialTweaks -NonInteractive -ApplyAll -WhatIf` should be possible without ever calling `Read-Host`. The C5 fix and this finding are siblings — both want the script to grow a `param()` block at the top.
- **Target phase:** P3 (with F1) or P4

### F7 — Unapproved verb names: `Pin-ChromeToTaskbar`, `Apply-AllTweaks`
- **Severity:** low
- **Category:** naming
- **Location:** scripts/essential_tweaks.ps1:357 (`Pin-ChromeToTaskbar`), 562 (`Apply-AllTweaks`)
- **Current:**
  ```powershell
  function Pin-ChromeToTaskbar { ... }
  function Apply-AllTweaks    { ... }
  ```
- **Recommended:**
  ```powershell
  function Add-ChromeTaskbarPin { ... }   # or Set-ChromeTaskbarPin
  function Invoke-AllTweaks     { ... }   # or Set-AllEssentialTweaks
  ```
- **Risk if changed:** Low. Both functions are private to this script (no external callers — the launcher executes the script, not individual functions). Update the two internal call sites in `Apply-AllTweaks` (line 593) and `Start-EssentialTweaks`'s switch (lines 632 and 636) at the same time. PSScriptAnalyzer's `PSUseApprovedVerbs` rule will flag both as soon as C8 enables CI.
- **Target phase:** P1 (fold into the C1 sweep) or P3

### F8 — Mixed pattern in `Disable-Copilot`: idempotent `New-Item -Force` after `Test-Path`
- **Severity:** info
- **Category:** structure (note only — no change recommended)
- **Location:** scripts/essential_tweaks.ps1:443–462
- **Local notes:** All four `New-Item -Force` calls in this function (lines 444, 452, 460) are wrapped in `if (-not (Test-Path ...)) { ... }`. The `-Force` flag makes the `Test-Path` guard redundant — `New-Item -Force` is idempotent for registry keys (no error if the key exists, no overwrite of existing values). The pattern is also used in `Disable-StartMenuAds` (lines 324–326) and `Enable-TaskbarEndTask` (lines 413–415). Harmless, but the `Test-Path` guard is dead code. When refactoring under F1, the simpler form is `New-Item -Path $regPath -Force | Out-Null` with no `Test-Path` — and once `ShouldProcess` is in place, the gate moves to `$PSCmdlet.ShouldProcess`. Note: this is purely cosmetic; the behavior is identical. Not worth a separate change pass.
- **Target phase:** —

### F9 — Self-imposed admin check + `exit 1` without `#Requires -RunAsAdministrator`
- **Severity:** info
- **Category:** structure (note only)
- **Location:** scripts/essential_tweaks.ps1:613–619
- **Local notes:** The script self-checks admin via `if (-not (Test-SouliTEKAdministrator))` at line 613 and `exit 1`s. Declaring `#Requires -RunAsAdministrator` at the top (alongside the existing `#Requires -Version 5.1`) would let PowerShell refuse to even parse the script in a non-elevated session, which is a cleaner posture than running 612 lines and then refusing to do work. This also matches the pattern used by `scripts/driver_integrity_scan.ps1` (which declares both directives). Pair with F4 in the P3 cleanup. Note: under SYSTEM context (RMM deployment) the script is already running elevated and would pass the `#Requires` check trivially — the runtime self-check is the right behaviour for interactive launches from a non-elevated shell, but a `#Requires` directive is strictly more informative.
- **Target phase:** P4

## Out-of-scope notes
- Banner block (lines 1–36, 36 lines of `# === / Coded by / IMPORTANT DISCLAIMER`) matches C11 cross-cutting cleanup; covered there.
- Import boilerplate (lines 43–51) matches C10; will be replaced by `Import-SouliTEKCommon` in P4 along with F5.
- `Get-WmiObject` is not used in this script, so C3 is N/A here.
- No `Write-SouliTEK(Result|Info|Success|Warning|Error)` legacy-API callers in this file — C2's "verify zero callers before deleting the legacy functions" check is already satisfied for `essential_tweaks.ps1`.
- The trailing 4 blank lines at end-of-file (lines 663–666) are harmless but could be trimmed in any pass that touches the file.
- The `$Script:TweakResults` / `$Script:SuccessCount` / `$Script:ErrorCount` global pattern (lines 57–59) is functional but not great — it makes `Show-Summary` and `Add-TweakResult` mutually coupled through script-scope state instead of returning rich result objects. A P4-era refactor to return `[PSCustomObject]` results from each function and aggregate them in `Apply-AllTweaks` would be cleaner, but that's a structural rewrite beyond the scope of this audit. Note for the modernization phase, not a finding here.
- The `Add-TweakResult` helper (lines 65–84) does its job correctly: timestamps each result, increments the right counter based on `$Status -eq "SUCCESS"`. No change needed.
- `Show-Menu` (lines 86–105) uses `Write-Ui` exclusively (good) — the only `Write-Host` in this function is the trailing `Write-Host -NoNewline "  Enter your choice: "` prompt at line 104, which is a real C1 violation (covered in F2).
- `Show-Summary`'s `$statusColor` / `$statusSymbol` switch pattern (lines 538–548) is exactly the manual-rendering anti-pattern that `Write-Ui -Level` was built to replace. Fold the rework into the F2 fix pass (covered in F2 category 3).
