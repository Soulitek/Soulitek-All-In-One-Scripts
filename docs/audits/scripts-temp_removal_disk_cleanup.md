# Audit — scripts/temp_removal_disk_cleanup.ps1

## Inventory
| Item | Value |
|---|---|
| Path           | scripts/temp_removal_disk_cleanup.ps1 |
| LOC            | 1022 |
| Functions      | 14 (`Get-FolderSize`, `Format-FileSize`, `Clear-UserTemp`, `Clear-SystemTemp`, `Clear-RecycleBin`, `Clear-BrowserCache`, `Clear-WindowsUpdate`, `Invoke-DiskCleanup`, `Start-CompleteCleanup`, `Show-CleanupSummary`, `Export-CleanupReport`, `Show-Help`, `Show-ExitMessage`, `Show-MainMenu`) |
| `#Requires`    | `#Requires -Version 5.1` only (no `#Requires -RunAsAdministrator` despite the script self-checking admin via `Test-Administrator` at line 1014 — but only as a soft warning, not an exit) |
| Admin-required | recommended (declared as a soft warning at line 1014: `if (-not (Test-Administrator)) { Write-Ui ... -Level "WARN"; Start-Sleep -Seconds 2 }` — the script continues regardless). Actually required for `Clear-SystemTemp` (`C:\Windows\Temp`), `Clear-WindowsUpdate` (`C:\Windows\SoftwareDistribution\Download`, `Stop-Service wuauserv`, `Start-Service wuauserv`), `Invoke-DiskCleanup` (`cleanmgr /VERYLOWDISK` and `dism /online /cleanup-image /startcomponentcleanup /resetbase`). Without admin, those branches throw `Access Denied` errors that are then swallowed into per-file warnings or service-control failures. |
| Last touched   | 8675720 — 2026-04-17 |
| Modernization grade | D |

## Summary

A menu-driven disk-cleanup tool: deletes user/system temp files, empties the Recycle Bin on all drives, wipes Chrome/Edge/Firefox/IE browser caches, removes Windows Update downloads (`SoftwareDistribution\Download`), and shells out to `cleanmgr.exe /VERYLOWDISK` plus `dism /online /cleanup-image /startcomponentcleanup /resetbase`. The biggest issues are (1) **the entire script is destructive with zero `ShouldProcess` plumbing** — 8 deletion / service-control / external-process mutation sites across 6 destructive functions touch the filesystem (`Remove-Item -Recurse` against `$env:TEMP`, `C:\Windows\Temp`, `C:\Windows\SoftwareDistribution\Download`, the per-drive `$Recycle.Bin` folder, four browser cache directories) and the Service Control Manager (`Stop-Service wuauserv`/`Start-Service wuauserv`) and external mutators (`cleanmgr.exe`, `dism.exe`), none of which surface `-WhatIf`/`-Confirm` to the operator (C5); (2) **a serious correctness bug — function-cmdlet name collision**: `function Clear-RecycleBin` (line 208) shadows the built-in `Clear-RecycleBin` cmdlet, and inside that function line 231 calls `Clear-RecycleBin -DriveLetter $drive.Name -Force -ErrorAction SilentlyContinue` which now resolves to the script-local function. The local function has no `param()` block, so the `-DriveLetter` parameter raises `ParameterBindingException` which is caught by the outer `try` and routes execution into the COM-`InvokeVerb("delete")` fallback every time — meaning the per-drive recycle-bin emptying advertised in the menu is in fact unreachable; (3) **39 raw `Write-Host` calls** including a 53-line `Write-Host $helpText` block at line 900 (the entire `Show-Help` body's output), banner-style `Write-Host "===" -ForegroundColor Cyan` separators (lines 495, 497, 938), and inline-colour two-part rendering (lines 499–504, 537–544) inside `Start-CompleteCleanup` and `Show-CleanupSummary` (C1); (4) **13 `-ErrorAction SilentlyContinue` occurrences** — most are tag A (cleanup or probe), but lines 438 and 442 swallow `cleanmgr.exe` and `dism.exe` failures completely (tag B), and line 231 silently masks the name-collision parameter-binding error described in F1 (tag C — the failure must be surfaced); (5) **1022 LOC** with substantial structural duplication: every `Clear-*` function repeats the `Test-Path` → `Get-FolderSize` → `Get-ChildItem | Remove-Item` pattern verbatim, and the cleanup-summary rendering in `Start-CompleteCleanup` (lines 495–512) is duplicated in `Show-CleanupSummary` (lines 535–574) (C6). Secondary concerns: no `[CmdletBinding()]` anywhere; `Split-Path -Parent $MyInvocation.MyCommand.Path` instead of `$PSScriptRoot` (line 40); the admin soft-warning at line 1014 lets the script continue without elevation and silently degrade for half its operations; the menu `do { } while ($true)` (line 1002) plus `Read-Host` (line 941) plus 11 `$Host.UI.RawUI.ReadKey` blocks would deadlock under SYSTEM/RMM execution; the export path is hard-coded to `[Environment]::GetFolderPath("Desktop")` (line 597) which under SYSTEM context resolves to `C:\Windows\System32\config\systemprofile\Desktop`; the `Get-FolderSize` helper enumerates the entire tree twice (once to count, once to delete) instead of capturing size during deletion; `Get-WmiObject` is not used so C3 is N/A. Recommended phase entry order: **P3 (C5 ShouldProcess + F1 name-collision rename — these MUST happen together since the rename touches the same call sites)**, then P1 (C1 sweep), then P2 (C4 triage), then P4 (C6 extraction).

## Findings

### F1 — Function-cmdlet name collision causes per-drive Recycle Bin emptying to fail silently
- **Severity:** high
- **Category:** correctness (also: structure / naming)
- **Location:** scripts/temp_removal_disk_cleanup.ps1:208 (`function Clear-RecycleBin`) shadows the built-in `Microsoft.PowerShell.Management\Clear-RecycleBin` cmdlet. Internal call site at line 231 (`Clear-RecycleBin -DriveLetter $drive.Name -Force -ErrorAction SilentlyContinue`) is now resolved against the local function, not the cmdlet. Also called from `Start-CompleteCleanup` line 472 and `Show-MainMenu` switch arm `"4"` at line 962 — those two call sites are correct because they want the local function; only line 231 is buggy.
- **Current (lines 208–272):**
  ```powershell
  function Clear-RecycleBin {
      # ...
      try {
          $drives = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Used -gt 0 }
          foreach ($drive in $drives) {
              $recyclePath = "$($drive.Root)`$Recycle.Bin"
              if (Test-Path $recyclePath) {
                  $fileCount = 0
                  $size = Get-FolderSize -Path $recyclePath -FileCount ([ref]$fileCount)
                  if ($size -gt 0) {
                      try {
                          Clear-RecycleBin -DriveLetter $drive.Name -Force -ErrorAction SilentlyContinue
                          # ^^^ Resolves to the LOCAL function (recursion),
                          #     not the built-in cmdlet. The local function has
                          #     no [-DriveLetter] parameter -> ParameterBindingException
                          #     is raised before any code in this try-block runs.
                          $totalSize += $size
                          $totalFiles += $fileCount
                          Write-Ui -Message "  [OK] Cleaned drive $($drive.Name): $(Format-FileSize $size)" -Level "OK"
                      }
                      catch {
                          # Fallback Get-ChildItem | Remove-Item never runs either,
                          # because the binding error bubbles to the OUTER catch
                          # (terminating error from parameter binding).
                          if (Test-Path $recyclePath) {
                              try {
                                  Get-ChildItem -Path $recyclePath -Recurse -Force -ErrorAction SilentlyContinue |
                                      Remove-Item -Force -Recurse -ErrorAction Stop
                                  ...
                              } catch { ... }
                          }
                      }
                  }
              }
          }
      }
      catch {
          # Alternative: Use COM object - THIS is the only branch that actually executes
          $shell = New-Object -ComObject Shell.Application
          $recycleBin = $shell.NameSpace(0xA)
          ...
          $recycleBin.InvokeVerb("delete")
      }
  }
  ```
- **Recommended:**
  ```powershell
  function Clear-AllRecycleBins {       # rename so it no longer shadows the cmdlet
      [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
      param()
      # ...
      foreach ($drive in $drives) {
          $recyclePath = "$($drive.Root)`$Recycle.Bin"
          if (Test-Path $recyclePath) {
              # ...
              if ($size -gt 0) {
                  $target = "Recycle Bin on drive $($drive.Name):"
                  if ($PSCmdlet.ShouldProcess($target, "Empty (delete $fileCount items, $(Format-FileSize $size))")) {
                      try {
                          Microsoft.PowerShell.Management\Clear-RecycleBin -DriveLetter $drive.Name -Force -ErrorAction Stop
                          $totalSize += $size
                          $totalFiles += $fileCount
                          Write-Ui -Message "Cleaned drive $($drive.Name): $(Format-FileSize $size)" -Level "OK"
                      } catch {
                          Write-Ui -Message "Recycle Bin clear failed on drive $($drive.Name): $($_.Exception.Message)" -Level "WARN"
                      }
                  }
              }
          }
      }
  }
  ```
  Update the two correct callers (`Start-CompleteCleanup` line 472, `Show-MainMenu` switch arm `"4"` line 962) to reference the new function name. The fully-qualified `Microsoft.PowerShell.Management\Clear-RecycleBin` call is belt-and-braces — once the local function is renamed, the unqualified `Clear-RecycleBin` resolves to the cmdlet again, but the module-qualified form is defensive against the user re-introducing the collision in a future refactor.
- **Risk if changed:** Medium. The rename is mechanical (3 call sites to update). The behavioural change is significant: today's COM-`InvokeVerb("delete")` fallback empties only the *current user's* Recycle Bin on the *system drive* — it ignores all other drives and ignores the other-user portions of `$Recycle.Bin`. After the fix, `Clear-RecycleBin -DriveLetter` empties the Recycle Bin for every user on every drive with content. That is what the menu says it does; the bug is the discrepancy. Test under elevated and non-elevated sessions on a machine with multiple drives populated.
- **Local notes:** This is also a `PSAvoidOverwritingBuiltInCmdlets` violation that PSScriptAnalyzer will flag immediately once C8 enables CI. The script literally cannot call the cmdlet by name from anywhere in its scope until the function is renamed. The author's intent (judging from line 231 passing `-DriveLetter`) was clearly to call the cmdlet — this is a typo-class bug that's been latent.
- **Target phase:** P3 (must land alongside F2 ShouldProcess)

### F2 — Mutation sites needing `ShouldProcess` (see C5)
- **Severity:** high
- **Category:** safety
- **Location:** scripts/temp_removal_disk_cleanup.ps1 — 8 mutation sites across 6 destructive functions
- **Reference:** [C5](00-cross-cutting.md#c5--destructive-scripts-lack-cmdletbindingsupportsshouldprocess--whatif-confirm)
- **Enumeration of every mutation site:**
  - **`Clear-UserTemp` (line 122):**
    - L150–151 — `Get-ChildItem -Path $tempPath -Recurse -File -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction Stop` — recursive delete of every file under `$env:TEMP`, `$env:TMP`, `$env:USERPROFILE\AppData\Local\Temp`. Looped over 3 paths. **Highest mutation volume in the script.**
  - **`Clear-SystemTemp` (line 169):**
    - L190–191 — `Get-ChildItem -Path $systemTempPath -Recurse -File -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction Stop` — recursive delete of every file under `C:\Windows\Temp` (hard-coded; ignores any non-default Windows install path).
  - **`Clear-RecycleBin` (line 208) — see F1 for the name-collision bug:**
    - L231 — `Clear-RecycleBin -DriveLetter $drive.Name -Force -ErrorAction SilentlyContinue` (currently broken — F1) — **intended** to empty Recycle Bin per drive.
    - L240–241 — `Get-ChildItem -Path $recyclePath -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction Stop` — fallback path attempting to delete the `$Recycle.Bin` folder contents directly (currently unreachable per F1, but **destructive** once F1 is fixed). Note: deleting items from `$Recycle.Bin` outside of `Clear-RecycleBin` can corrupt the bin metadata; the cmdlet is the safe path.
    - L266 — `$recycleBin.InvokeVerb("delete")` — COM-based delete of all current-user items in the Recycle Bin (system-drive only). Hard to predict per-item but always destructive.
  - **`Clear-BrowserCache` (line 282):**
    - L313–314 — `Get-ChildItem -Path $fullPath -Recurse -File -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction Stop` (wildcard branch for Firefox profile `cache2` folder).
    - L334–335 — `Get-ChildItem -Path $browser.Path -Recurse -File -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction Stop` (direct branch for Chrome/Edge/IE caches under `$env:LOCALAPPDATA`).
  - **`Clear-WindowsUpdate` (line 356):**
    - L379 — `Stop-Service -Name wuauserv -ErrorAction Stop` — graceful service stop.
    - L384 — `Stop-Service -Name wuauserv -Force -ErrorAction Stop` — force service stop on graceful fallback.
    - L396–397 — `Get-ChildItem -Path $path -Recurse -File -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction Stop` — loops over `C:\Windows\SoftwareDistribution\Download` AND `C:\Windows\Temp` (duplicate of L190 — see F5). **Stopping the WU service mid-update can corrupt pending update state.** A running WU download or install must not be interrupted.
    - L411 — `Start-Service -Name wuauserv -ErrorAction SilentlyContinue` — service restart. The `SilentlyContinue` here is a real C4 tag-B problem (see F3): if the restart fails, WU is left disabled, the user has no idea, and the next reboot doesn't recover.
  - **`Invoke-DiskCleanup` (line 426):**
    - L438 — `Start-Process -FilePath "cleanmgr.exe" -ArgumentList "/VERYLOWDISK /D C:" -Wait -NoNewWindow -ErrorAction SilentlyContinue` — runs Disk Cleanup in low-disk-space mode (deletes every category, not just the safe ones). The `/VERYLOWDISK` switch is `cleanmgr`'s most aggressive automated mode.
    - L442 — `Start-Process -FilePath "dism.exe" -ArgumentList "/online /cleanup-image /startcomponentcleanup /resetbase" -Wait -NoNewWindow -ErrorAction SilentlyContinue` — `/resetbase` is **irreversible**: it deletes all superseded Windows component versions, preventing future rollback of installed updates. This is the most destructive single line in the entire script. It must absolutely not run without `-Confirm`.
- **Current (representative — `Clear-UserTemp` lines 148–156):**
  ```powershell
  if ($size -gt 0) {
      try {
          Get-ChildItem -Path $tempPath -Recurse -File -ErrorAction SilentlyContinue |
              Remove-Item -Force -ErrorAction Stop
          Write-Ui -Message "  [OK] Cleaned: $(Format-FileSize $size)" -Level "OK"
      }
      catch {
          Write-Ui -Message "  [WARNING] Some files could not be deleted: $($_.Exception.Message)" -Level "WARN"
      }
  }
  ```
- **Recommended:**
  ```powershell
  function Clear-UserTemp {
      [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
      param()
      # ...
      if ($size -gt 0) {
          if ($PSCmdlet.ShouldProcess($tempPath, "Delete $fileCount temp files ($(Format-FileSize $size))")) {
              try {
                  Get-ChildItem -Path $tempPath -Recurse -File -ErrorAction SilentlyContinue |
                      Remove-Item -Force -ErrorAction Stop
                  Write-Ui -Message "Cleaned: $(Format-FileSize $size)" -Level "OK"
              }
              catch {
                  Write-Ui -Message "Some files could not be deleted: $($_.Exception.Message)" -Level "WARN"
              }
          }
      }
  }
  ```
  Apply the same pattern to every function listed above. The script itself should also gain `[CmdletBinding(SupportsShouldProcess, ConfirmImpact='High')]` at top + a `param()` block so `-WhatIf` and `-Confirm` propagate cleanly from the launcher (see F6). For `Invoke-DiskCleanup`'s `dism /resetbase` site at line 442, use `ConfirmImpact='High'` on that function specifically (default-confirm prompt) — the irreversibility warrants it. For temp-file deletes, `'Medium'` is correct.
- **Risk if changed:** Medium. The `[CmdletBinding(SupportsShouldProcess)]` plumbing is mechanical, but the `ShouldProcess` target / action strings need to be informative so `-WhatIf` output reads cleanly. Two cross-cutting interactions:
  1. **F1 name-collision rename must land in the same commit** — the F1 rename of `Clear-RecycleBin` → `Clear-AllRecycleBins` (or similar) needs to coincide with the `[CmdletBinding(SupportsShouldProcess)]` addition because the cleanup re-touches every call site.
  2. **The implicit-confirmation interaction with `Clear-RecycleBin` cmdlet** — once F1 unmasks the cmdlet, note that the built-in `Clear-RecycleBin -Force` already suppresses its own confirmation. Wrapping it in `$PSCmdlet.ShouldProcess(...)` from the outer function is the right layer — that's the one operators see.
- **Local notes (export-path soft mutation):** `Export-CleanupReport` (line 580) writes 3 files to `[Environment]::GetFolderPath("Desktop")` (line 597) — TXT/CSV/HTML reports. This is a *soft* mutation (creates files on Desktop, doesn't delete anything), so it's lower-severity than the cleanup mutations above and is intentionally not enumerated as a `ShouldProcess` site. But under SYSTEM context the path resolves to `C:\Windows\System32\config\systemprofile\Desktop` and may not exist — pair with F6 below.
- **Target phase:** P3

### F3 — `-ErrorAction SilentlyContinue` triage (see C4)
- **Severity:** med (per-occurrence variable)
- **Category:** error-handling
- **Location:** scripts/temp_removal_disk_cleanup.ps1 — 13 occurrences
- **Reference:** [C4](00-cross-cutting.md#c4----erroraction-silentlycontinue-swallowing-failures)
- **Triage:**
  - **Line 86** — tag **A** — `$items = Get-ChildItem -Path $Path -Recurse -File -ErrorAction SilentlyContinue` inside `Get-FolderSize`. Legitimately silent because per-file ACL denials are normal when traversing system temp folders (locked files held by running processes). The inner per-item `try/catch` (lines 88–94) also swallows the per-item size read. Both are appropriate for a size-calculation probe. Add `# safe: probe - folder enumeration tolerates per-file ACL denials` comment in P2.
  - **Line 150** — tag **B** — `Get-ChildItem -Path $tempPath -Recurse -File -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction Stop`. The `SilentlyContinue` on the *enumeration* swallows ACL/locked-file enumeration errors silently, then the `Remove-Item -ErrorAction Stop` raises on the first deletion failure. **Mixed strategy.** The enumeration silence is defensible (matches L86), but the asymmetry is confusing — and the resulting count `$totalFiles` reported in `$Script:CleanupResults.UserTemp.Files` reflects what `Get-FolderSize` saw, not what actually got deleted. The "deleted" count is a lie. Replace with a counter incremented inside the `Remove-Item` try-block per actual deletion. Tag B because the silence on enumeration covers an inaccurate-reporting bug.
  - **Line 190** — tag **B** — same pattern as L150 for `C:\Windows\Temp`. Same fix.
  - **Line 231** — tag **C** — `Clear-RecycleBin -DriveLetter $drive.Name -Force -ErrorAction SilentlyContinue` — **THIS IS THE NAME-COLLISION SITE FROM F1.** The `SilentlyContinue` here is what suppresses the visible symptom of the bug (the parameter-binding error never reaches the user). Removing `SilentlyContinue` alone would surface the `ParameterBindingException` but not fix the bug. The actual fix is F1's rename. Tag C because **the failure must halt or the function silently lies about what it did.** P2 fix: remove `SilentlyContinue` here and let F1's rename + try/catch handle it.
  - **Line 240** — tag **A** — `Get-ChildItem -Path $recyclePath -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction Stop` inside the F1 fallback branch. Same enumeration-silence rationale as L150. (Once F1 is fixed, this branch is rarely reached anyway.) Tag A.
  - **Line 303** — tag **A** — `Get-ChildItem -Path (Split-Path $browser.Path -Parent) -Directory -ErrorAction SilentlyContinue` — Firefox profile-directory enumeration probe. Returns empty if Firefox isn't installed. Legitimate. Add `# safe: probe - Firefox may not be installed` comment.
  - **Line 313** — tag **B** — same pattern as L150 for browser cache (wildcard Firefox branch). Same fix.
  - **Line 334** — tag **B** — same pattern as L150 for browser cache (Chrome/Edge/IE branch). Same fix.
  - **Line 375** — tag **A** — `$wuService = Get-Service -Name wuauserv -ErrorAction SilentlyContinue` — service-presence probe. Returns `$null` if WU service is removed (it can be on stripped-down Windows builds). The result is gated with `if ($wuService -and $wuService.Status -eq 'Running')`. Legitimate. Add `# safe: probe` comment.
  - **Line 396** — tag **B** — same pattern as L150 for Windows Update cache folders.
  - **Line 411** — tag **B** — `Start-Service -Name wuauserv -ErrorAction SilentlyContinue` — **after the cleanup we stopped WU and the restart silently fails.** If `wuauserv` doesn't restart, the user's Windows Update is now disabled and they have no idea. Replace with:
    ```powershell
    try {
        Start-Service -Name wuauserv -ErrorAction Stop
        Write-Ui -Message "Windows Update service restarted" -Level "OK"
    } catch {
        Write-Ui -Message "CRITICAL: Could not restart Windows Update service: $($_.Exception.Message). Run 'Start-Service wuauserv' manually." -Level "ERROR"
    }
    ```
    Tag B because this is the textbook "swallowing a real bug" pattern from C4. (Bordering on tag C — a failure to restart WU after we stopped it is a serious deviation that arguably warrants halting and showing the user.)
  - **Line 438** — tag **B** — `Start-Process -FilePath "cleanmgr.exe" ... -ErrorAction SilentlyContinue`. `cleanmgr` exit code is **not** observed (no `-PassThru` + `$process.ExitCode` check). If `cleanmgr` fails (e.g., admin not granted), we silently report `[OK] Disk Cleanup completed` at line 445. Tag B. Fix: capture the process with `-PassThru`, check `ExitCode`, surface failures.
  - **Line 442** — tag **B** — same as L438 for `dism.exe /online /cleanup-image /startcomponentcleanup /resetbase`. **`/resetbase` is irreversible** — silently swallowing its failure is doubly wrong. Same fix as L438 (capture `ExitCode`).
- **Counts:** 13 occurrences — 4 tag **A** (probe/cleanup), 8 tag **B** (swallows real bugs), 1 tag **C** (line 231 — the F1 collision masker).
- **Target phase:** P2

### F4 — Raw `Write-Host` calls (see C1)
- **Severity:** med
- **Category:** output-style
- **Location:** scripts/temp_removal_disk_cleanup.ps1 — 39 raw `Write-Host` occurrences (lines 166, 205, 279, 353, 423, 452, 465, 495, 497, 498, 499, 501, 503, 505, 512, 529, 536, 537, 539, 543, 547, 549, 554, 559, 564, 569, 574, 591, 602, 819, 821, 900, 901, 925, 937, 938, 939, 942, 1017)
- **Reference:** [C1](00-cross-cutting.md#c1--raw-write-host-calls-not-migrated-to-write-uiwrite-status)
- **Current (representative pattern — `Start-CompleteCleanup` lines 495–504, hand-rolled summary header):**
  ```powershell
  Write-Host "============================================================" -ForegroundColor Cyan
  Write-Ui -Message "CLEANUP SUMMARY" -Level "INFO"
  Write-Host "============================================================" -ForegroundColor Cyan
  Write-Host ""
  Write-Host "  Total Space Recovered: " -NoNewline -ForegroundColor White
  Write-Ui -Message "$(Format-FileSize $Script:CleanupResults.TotalSize)" -Level "OK"
  Write-Host "  Total Files Removed: " -NoNewline -ForegroundColor White
  Write-Ui -Message "$($Script:CleanupResults.TotalFiles)" -Level "OK"
  Write-Host "  Duration: " -NoNewline -ForegroundColor White
  Write-Ui -Message "$([math]::Round($duration.TotalMinutes, 2)) minutes" -Level "OK"
  ```
- **Recommended:**
  ```powershell
  Show-Section -Title "CLEANUP SUMMARY"      # or Write-Ui -Spacer if such a helper is added in P4
  Write-Ui -Message "Total Space Recovered: $(Format-FileSize $Script:CleanupResults.TotalSize)" -Level "OK"
  Write-Ui -Message "Total Files Removed: $($Script:CleanupResults.TotalFiles)" -Level "OK"
  Write-Ui -Message "Duration: $([math]::Round($duration.TotalMinutes, 2)) minutes" -Level "OK"
  ```
- **Risk if changed:** Low — pure replacement. Message text preserved verbatim; `[OK]` bracket emitted by `Write-Ui` replaces the manual two-colour rendering.
- **Local notes:** Five categories of raw `Write-Host` in this file:
  1. **Blank-line / spacer calls** — bare `Write-Host ""` used as vertical spacing (lines 166, 205, 279, 353, 423, 452, 465, 498, 505, 512, 529, 536, 547, 549, 554, 559, 564, 569, 574, 591, 602, 819, 821, 901, 925, 937, 939, 942, 1017). Per C1's "visual separator helpers" exception these may stay as-is, but the file would read more cleanly with a `Write-Ui -Spacer` helper added in P4 to replace all of them at once.
  2. **`===` banner separators** — `Write-Host "============================================================" -ForegroundColor Cyan` at lines 495, 497, 938. Real C1 violations: hand-rolled section dividers that should be a `Show-Section -Title "..."` helper (or whatever `Show-*` exists in the common module).
  3. **Two-part label + value inline-colour formatting** — lines 499–504 inside `Start-CompleteCleanup` and 537–544 inside `Show-CleanupSummary` (`Write-Host "  Total Space Recovered: " -NoNewline -ForegroundColor White` followed by a `Write-Ui` call). These mix the legacy and current APIs on adjacent lines for the same logical line of output. Replace with a single `Write-Ui -Message "Label: $value" -Level "OK"` per logical row. Same hand-rolled-prefix anti-pattern called out in F2 category 3 of `scripts-essential_tweaks.md`.
  4. **`Write-Host $helpText` block** — line 900: `Write-Host $helpText` renders a 53-line literal help-text body. This is technically a single `Write-Host` call but emits 53 lines of formatted content that the rest of the UI conventions don't apply to. Migrate by either (a) calling `Write-Output $helpText` (which respects host redirection and is the canonical "print plain text" call), or (b) wrapping the body in `Write-Ui -Message $line -Level "INFO"` per line via a `foreach`. Option (a) is the right answer here — the help text is intentionally plain and `Write-Ui`'s `[INFO]` prefix on every line would be noisy. **Recommend:** `Write-Output $helpText`.
  5. **`Read-Host` companion prompts** — none in this script. The `Read-Host` at line 941 (`$choice = Read-Host "Enter your choice (0-10)"`) uses the built-in prompt parameter rather than a separate `Write-Host`. Good practice. Migration to `Write-Ui -Message "..." -NoNewline` not needed here.
- **Local notes (cont.) — inline indent in `Write-Ui` messages:** Many `Write-Ui` calls embed leading `"  "` whitespace inside the message string (lines 129, 142, 152, 155, 165, 176, 192, 195, 204, 234, 245, 270, 278, 317, 320, 338, 341, 352, 363, 377, 381, 383, 402, 410, 415, 422, 433, 441, 445, 448, 463–464, 506–511, 550–573, 661, 711, 817, 926–936). Combined with the `[LEVEL]` prefix that `Write-Ui` already prepends, the output is double-indented. Strip these in the same C1 sweep.
- **Local notes (cont.) — no legacy `Write-SouliTEK*` callers:** This file does not call any of the C2 dead-API functions, so the C2 migration step is N/A here.
- **Local notes (cont.) — inline `[OK]` / `[WARNING]` / `[SKIP]` markers embedded in `Write-Ui` messages:** Many `Write-Ui` calls smuggle marker prefixes inside the message string (lines 152 `[OK]`, 155 `[WARNING]`, 192 `[OK]`, 195 `[WARNING]`, 234 `[OK]`, 245 `[WARNING]`, 270 `[WARNING]`, 317 `[OK]`, 320 `[SKIP]`, 338 `[OK]`, 341 `[SKIP]`, 381 `[OK]`, 383 `[WARNING]`, 402 `[WARNING]`, 415 `[WARNING]`, 445 `[OK]`, 448 `[WARNING]`, 661 `[OK]`, 711 `[OK]`, 817 `[OK]`). Same anti-pattern as F2 of `01-modules-SouliTEK-Common.md` — the `[LEVEL]` bracket emitted by `Write-Ui` already conveys this. Strip the inline markers.
- **Target phase:** P1

### F5 — Large LOC + per-`Clear-*` function duplication + summary-rendering duplication (see C6)
- **Severity:** med
- **Category:** structure
- **Location:** scripts/temp_removal_disk_cleanup.ps1 — 1022 LOC. Three concrete extraction opportunities:
- **Reference:** [C6](00-cross-cutting.md#c6--scripts-1000-loc-with-extractable-duplication)
- **Local notes — duplication detail:**
  1. **`Test-Path` → `Get-FolderSize` → `Get-ChildItem | Remove-Item` pattern repeated 6× verbatim** at lines 141–157 (`Clear-UserTemp`), 182–197 (`Clear-SystemTemp`), 305–323 + 327–344 (`Clear-BrowserCache` — twice, once per wildcard/direct branch), 389–404 (`Clear-WindowsUpdate`). Extract to a single `Invoke-PathCleanup -Path <path> -Label <name>` helper:
     ```powershell
     function Invoke-PathCleanup {
         [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
         param(
             [Parameter(Mandatory)][string]$Path,
             [Parameter(Mandatory)][string]$Label,
             [switch]$Recurse = $true
         )
         if (-not (Test-Path $Path)) { return @{ Size = 0; Files = 0 } }
         $fileCount = 0
         $size = Get-FolderSize -Path $Path -FileCount ([ref]$fileCount)
         if ($size -eq 0) { return @{ Size = 0; Files = 0 } }
         if (-not $PSCmdlet.ShouldProcess($Path, "Delete $fileCount items ($(Format-FileSize $size))")) {
             return @{ Size = 0; Files = 0 }
         }
         $deleted = 0
         Get-ChildItem -Path $Path -Recurse:$Recurse -File -ErrorAction SilentlyContinue | ForEach-Object {
             try { Remove-Item $_.FullName -Force -ErrorAction Stop; $deleted++ } catch { }
         }
         Write-Ui -Message "$Label : $(Format-FileSize $size) ($deleted of $fileCount files deleted)" -Level "OK"
         return @{ Size = $size; Files = $deleted }
     }
     ```
     This addresses F2 (`ShouldProcess`), F3 (`SilentlyContinue` tag-B fix — count actual deletions, not pre-deletion enumeration), and removes ~80 lines of duplication. Save for P4 *after* P3 lands the `ShouldProcess` wave.
  2. **Cleanup-summary rendering duplicated** between `Start-CompleteCleanup` lines 495–512 and `Show-CleanupSummary` lines 535–574. The two render essentially the same data with slightly different layouts. Extract a `Format-CleanupSummary -Results $Script:CleanupResults -Detailed:$true` helper used by both. ~40 lines saved.
  3. **Three full-text export blocks** (TXT lines 606–658, CSV lines 665–708, HTML lines 715–814) in `Export-CleanupReport` — total 209 lines. The CSV/TXT generation is mostly tabular data and would shrink dramatically if the per-category records were modelled as `[PSCustomObject]` once and serialised three ways. The HTML block (lines 715–814 — 99 lines) is the largest single static asset in the file and could move to a separate template file (`templates/cleanup_report.html.tmpl`) loaded via `Get-Content` + simple `-replace` substitution. The current `here-string` form is fine for now; flag as a P4 polish item.
- **Target phase:** P4

### F6 — No `[CmdletBinding()]` / no `param()` block / no non-interactive entry point
- **Severity:** med (escalates to high under the F2 ShouldProcess fix — they share a fix pass)
- **Category:** structure
- **Location:** scripts/temp_removal_disk_cleanup.ps1 — script-level (top of file, no `param()` block at all) and every one of the 14 functions: `Get-FolderSize` (line 72), `Format-FileSize` (line 105), `Clear-UserTemp` (line 122), `Clear-SystemTemp` (line 169), `Clear-RecycleBin` (line 208), `Clear-BrowserCache` (line 282), `Clear-WindowsUpdate` (line 356), `Invoke-DiskCleanup` (line 426), `Start-CompleteCleanup` (line 455), `Show-CleanupSummary` (line 518), `Export-CleanupReport` (line 580), `Show-Help` (line 837), `Show-ExitMessage` (line 911), `Show-MainMenu` (line 915).
- **Local notes:** No `[CmdletBinding()]` anywhere. The F2 ShouldProcess fix forces `[CmdletBinding(SupportsShouldProcess)]` onto every destructive function and onto the script itself — fold this finding into that pass. Non-destructive helpers (`Get-FolderSize`, `Format-FileSize`, `Show-CleanupSummary`, `Show-Help`, `Show-ExitMessage`, `Show-MainMenu`) don't strictly need `[CmdletBinding()]`, but the script-level `[CmdletBinding(SupportsShouldProcess, ConfirmImpact='High')]` plus a `param([switch]$AutoCleanup, [switch]$NonInteractive)` would let the menu loop be skipped under SYSTEM/RMM (see F7). Specifically:
  ```powershell
  [CmdletBinding(SupportsShouldProcess, ConfirmImpact='High')]
  param(
      [switch]$AutoCleanup,    # skip menu, run Start-CompleteCleanup
      [switch]$NonInteractive  # disable all Read-Host / ReadKey blocks
  )
  ```
- **Target phase:** P3 (with F2)

### F7 — Infinite menu loop with blocking `Read-Host` / `ReadKey` prompts (no non-interactive path)
- **Severity:** med
- **Category:** structure (UX / RMM safety)
- **Location:** scripts/temp_removal_disk_cleanup.ps1:1002 (`while ($true)`), plus `Read-Host` at line 941, plus 11 `$Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")` calls at lines 515, 531, 577, 593, 834, 903, 952, 958, 964, 970, 976, 982.
- **Local notes:** The only graceful exit is menu option `[0]` which calls `Show-ExitMessage` and `return` (line 994). Under SYSTEM-context RMM execution (flagged in user's `CLAUDE.md` as a deployment scenario), every `Read-Host` and `ReadKey` will hang the worker process indefinitely. There is no `[Environment]::UserInteractive` gate and no `-NonInteractive`/`-AutoCleanup` switch. Given that this script is *highly* destructive (F2 — `dism /resetbase` is irreversible), a `-WhatIf`-aware non-interactive entry point is mandatory for RMM use: `temp_removal_disk_cleanup.ps1 -AutoCleanup -NonInteractive -WhatIf` must be possible. The F2 fix and this finding are siblings — both want the script to grow a `param()` block at the top. Wrap every `ReadKey` block in `if (-not $NonInteractive)`.
- **Target phase:** P3 (with F2)

### F8 — `Split-Path -Parent $MyInvocation.MyCommand.Path` instead of `$PSScriptRoot`
- **Severity:** low
- **Category:** structure
- **Location:** scripts/temp_removal_disk_cleanup.ps1:40
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

### F9 — `Get-FolderSize` enumerates the tree twice (perf)
- **Severity:** low
- **Category:** perf
- **Location:** scripts/temp_removal_disk_cleanup.ps1:72 (`Get-FolderSize`), called immediately before every `Get-ChildItem | Remove-Item` site (lines 144, 184, 227, 308, 330, 392).
- **Local notes:** `Get-FolderSize` walks the entire tree once to sum file sizes and count files; then the very next statement walks the same tree again with `Get-ChildItem -Recurse | Remove-Item`. On a `C:\Windows\Temp` with several GB of small files this doubles the I/O cost of the cleanup. Cleaner pattern (already sketched in F5's `Invoke-PathCleanup` helper): track size and file count *during* the deletion via `ForEach-Object` and skip the pre-flight `Get-FolderSize` call entirely. This also fixes the F3 tag-B accuracy problem (the "deleted count" matches what was actually deleted, not what was discovered). Defer to P4 when F5's extraction happens.
- **Target phase:** P4 (with F5)

### F10 — Soft admin check at line 1014 lets the script continue without elevation
- **Severity:** info
- **Category:** structure (note only)
- **Location:** scripts/temp_removal_disk_cleanup.ps1:1014–1019
- **Current:**
  ```powershell
  if (-not (Test-Administrator)) {
      Write-Ui -Message "Warning: Administrator privileges recommended for full functionality" -Level "WARN"
      Write-Ui -Message "Some cleanup operations may not work without admin rights" -Level "INFO"
      Write-Host ""
      Start-Sleep -Seconds 2
  }
  ```
- **Local notes:** The admin check is a *soft warning* — the script proceeds regardless. Without admin, `Clear-SystemTemp` (line 169) fails on most files (ACL-protected), `Clear-WindowsUpdate` (line 356) cannot `Stop-Service wuauserv`, and `Invoke-DiskCleanup`'s `dism /resetbase` (line 442) silently fails. The current C4 tag-B `SilentlyContinue`s mask all of these into "Cleanup completed" success messages — see F3. Two options:
  1. **Hard-fail** — change to `#Requires -RunAsAdministrator` at line 34 + remove the soft check. The script genuinely needs admin for half its operations; running half-broken is worse than refusing to run.
  2. **Skip admin-required operations** — gate `Clear-SystemTemp`, `Clear-WindowsUpdate`, `Invoke-DiskCleanup` behind `if (Test-Administrator) { ... } else { Write-Ui -Message "Skipping <X> - requires admin" -Level "WARN" }`. More user-friendly, more code.
  Option 1 is cleaner and matches the user's `CLAUDE.md` "fail closed - deny by default" posture; option 2 is more flexible but adds branching. Discuss in P3 design.
- **Target phase:** P3 (with F2)

### F11 — `Show-Help` uses `Write-Host $helpText` for a 53-line body
- **Severity:** info
- **Category:** output-style (overlap with F4 category 4)
- **Location:** scripts/temp_removal_disk_cleanup.ps1:900
- **Current:**
  ```powershell
  $helpText = @"
  TEMP REMOVAL & DISK CLEANUP TOOL
  ...
  "@
  Write-Host $helpText
  ```
- **Recommended:**
  ```powershell
  Write-Output $helpText      # canonical "emit text to the pipeline / host"
  ```
- **Local notes:** Counted as 1 in the F4 `Write-Host` total (line 900). Splitting out because the fix is different from the other C1 violations — this is a literal plain-text print, so `Write-Output` (or even just leaving the here-string as the function's last expression) is more idiomatic than `Write-Ui` per line. Folded into F4 in the migration phase; mentioned separately so the reviewer knows the recommended replacement.
- **Target phase:** P1 (with F4)

## Out-of-scope notes
- Banner block (lines 1–32, 32 lines of `# === / Coded by / IMPORTANT DISCLAIMER`) matches C11 cross-cutting cleanup; covered there.
- Import boilerplate (lines 39–47) matches C10; will be replaced by `Import-SouliTEKCommon` in P4 along with F8.
- `Get-WmiObject` is not used in this script, so C3 is N/A here.
- No `Write-SouliTEK(Result|Info|Success|Warning|Error)` legacy-API callers in this file — C2's "verify zero callers before deleting the legacy functions" check is already satisfied for `temp_removal_disk_cleanup.ps1`.
- `Test-SafeFilePath` is **not applicable** here. All paths used in `Remove-Item` / `Clear-RecycleBin` calls are derived from trusted sources: `$env:TEMP`, `$env:TMP`, `$env:USERPROFILE`, `$env:LOCALAPPDATA`, hard-coded `C:\Windows\Temp` / `C:\Windows\SoftwareDistribution\Download`, and `Get-PSDrive -PSProvider FileSystem` results. There is no user-typed input flowing into any deletion path — the only `Read-Host` (line 941) consumes a single-character menu choice that is dispatched via `switch` and never used as a filesystem path. `Test-SafeFilePath` guards against operator-supplied filename strings, not against environment-derived deletion targets. (The hard-coded `C:\` prefix in `Clear-SystemTemp` and `Clear-WindowsUpdate` is a separate concern — see Out-of-scope note on system-drive assumption below.)
- The `Format-FileSize` helper (lines 105–120) is clean and idiomatic — no change needed. Mirror in `01-modules-SouliTEK-Common.md` as an extract candidate if it doesn't already exist in the common module.
- The `[Environment]::GetFolderPath("Desktop")` export-path choice (line 597) is the right API for getting the Desktop path under interactive context; under SYSTEM context it resolves to `C:\Windows\System32\config\systemprofile\Desktop`. A `-OutputDirectory` parameter on `Export-CleanupReport` would be a clean follow-up alongside F6's `param()` block addition. Note no risk of overwrite without prompt — the timestamp in `$baseFileName` (line 599) prevents collisions.
- The `Start-Process $txtPath / $csvPath / $htmlPath` calls at lines 825–827 in `Export-CleanupReport` are wrapped in `try/catch` (lines 824–831). The `catch` falls back to a `Write-Ui -Level "WARN"` message. Under SYSTEM context all three `Start-Process` calls will fail (no interactive desktop); the catch correctly handles that. No change needed.
- The hard-coded `C:\Windows\Temp` and `C:\Windows\SoftwareDistribution\Download` paths in `Clear-SystemTemp` (line 178) and `Clear-WindowsUpdate` (line 366) assume a system drive of `C:`. Windows installations on a non-default drive (e.g., `D:\Windows`) are rare but legal. Use `$env:SystemRoot` (`%SystemRoot%`) instead — it resolves to the actual install drive's `Windows` folder. One-line fix worth folding into the F5 `Invoke-PathCleanup` extraction.
- The `Clear-WindowsUpdate` function (line 356) has a latent bug at line 380: the variable `$serviceStopped` is set only inside an `if` block guarded by `$wuService.Status -eq 'Running'`. If WU was already stopped when the script ran, `$serviceStopped` is `$null`, and the test `if ($serviceStopped)` at line 409 is correctly false — so we don't try to restart a service we didn't stop. **Correct behavior, but the variable is undeclared before its first conditional assignment.** Under `Set-StrictMode -Version Latest` this would throw "the variable has not been set." Add `$serviceStopped = $false` at the top of the function for strict-mode compatibility. Folded into F5/F6 cleanup.
- The trailing 1 blank line at end-of-file (line 1023) is harmless.
- The `$Script:CleanupResults` global hashtable pattern (lines 53–64) is functional but couples every `Clear-*` function to the same global. A P4 refactor to return `[PSCustomObject]` results from each function and aggregate them in `Start-CompleteCleanup` would be cleaner, but that's a structural rewrite beyond the scope of this audit. Note for the modernization phase, not a finding here.
