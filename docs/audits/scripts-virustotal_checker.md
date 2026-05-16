# Audit — scripts/virustotal_checker.ps1

## Inventory
| Item | Value |
|---|---|
| Path           | scripts/virustotal_checker.ps1 |
| LOC            | 1048 |
| Functions      | 13 |
| `#Requires`    | `#Requires -Version 5.1` |
| Admin-required | no (read-only file hashing, outbound HTTPS to `api.virustotal.com`, writes to `%LOCALAPPDATA%\SouliTEK\` and Desktop only) |
| Last touched   | (unchanged in this audit pass) |
| Modernization grade | A |

## Summary

A menu-driven VirusTotal v3 client that hashes local files, queries the file/URL endpoints, batch-scans a folder, and exports results via the shared `Export-SouliTEKReport` pipeline. **This script is the security model reference for the rest of the repo.** It correctly uses the module's DPAPI helpers (`Protect-SouliTEKSecret` / `Unprotect-SouliTEKSecret`) for the 64-character VT API key — including the right pattern: prompt via `Read-Host -AsSecureString` (line 91), convert to plain text through `Marshal.SecureStringToBSTR` with `ZeroFreeBSTR` cleanup (lines 92–94), validate against the live API before persisting (lines 105–112), and gracefully fall through to re-prompt when an existing file fails to decrypt (line 67 comment: "Falls through to prompt — handles legacy plaintext files gracefully"). API key never logs, never appears in `Write-Host`, never crosses the network except as the `x-apikey` header. The mask in `Set-ApiKey` (line 984) shows only the first 8 and last 8 characters — exactly right for a 64-char secret. No `Get-WmiObject` (C3-clean), no legacy `Write-SouliTEK*` callers (C2-clean), no `Wait-SouliTEKKeyPress` issues beyond the rest of the repo, and only **2** `-ErrorAction SilentlyContinue` occurrences — both tag **A** legitimate (file enumeration that should yield an empty result on access denial, not abort). The two real issues are (1) **137 raw `Write-Host` calls** (C1) — by far the largest cleanup surface here, almost all of them inline color-formatted banner/separator strings of the form `Write-Host "===" -ForegroundColor Cyan` or `Write-Host "" `; (2) the file is **1048 LOC** (C6 candidate, just barely over the 1000-line threshold) — extract candidates are the duplicated `Show-VTFileResult` / `Show-VTUrlResult` rendering blocks which share a near-identical "threat color/level/stats table" structure. The local rate-limit handling is sensible (`Start-Sleep -Seconds 15` between batch requests on line 874, capped at `$maxFiles = 10` on line 829 to fit the free tier's 4-req/min) but has no exponential backoff or HTTP 429 awareness — see F4. Three smaller local findings: no `[CmdletBinding()]` anywhere (F5), `$MyInvocation.MyCommand.Path` instead of `$PSScriptRoot` (F6), and infinite menu loop with no non-interactive exit (F7). Recommended phase entry order: P1 (C1 sweep), then P2 (C4 — both A, comment-only). The single biggest reason this is grade **A** rather than B is that the *security-relevant* code is right; the open issues are output-style cosmetics and a missing-feature on rate-limit retry.

## Findings

### F1 — Raw `Write-Host` calls (see C1)
- **Severity:** med
- **Category:** output-style
- **Location:** scripts/virustotal_checker.ps1 — 137 raw `Write-Host` occurrences (sample lines: 75, 76, 78, 79, 83, 281, 308, 329, 330, 334–340, 375, 405, 439, 462, 467–473, 500, 533, 536, 541, 553, 581, 593, 610, 623, 635, 692, 743, 779, 890, 911, 913, 920, 978).
- **Reference:** [C1](00-cross-cutting.md#c1--raw-write-host-calls-not-migrated-to-write-uiwrite-status)
- **Current (representative — `Show-VTFileResult` stats block, lines 334–341):**
  ```powershell
  Write-Host "  |- Malicious:  " -NoNewline -ForegroundColor Gray
  Write-Host "$malicious" -ForegroundColor $(if ($malicious -gt 0) { "Red" } else { "Green" })
  Write-Host "  |- Suspicious: " -NoNewline -ForegroundColor Gray
  Write-Host "$suspicious" -ForegroundColor $(if ($suspicious -gt 0) { "Yellow" } else { "Green" })
  Write-Host "  |- Harmless:   " -NoNewline -ForegroundColor Gray
  Write-Ui -Message "$harmless" -Level "OK"
  Write-Host "  \- Undetected: " -NoNewline -ForegroundColor Gray
  Write-Ui -Message "$undetected" -Level "INFO"
  ```
- **Recommended:** Replace each `Write-Host "Label" -NoNewline` + value pair with a single `Write-Ui -Message "Label: $value" -Level "STEP"` (or `"OK"` / `"WARN"` / `"ERROR"` based on count thresholds). The conditional inline color (`-ForegroundColor $(if ($malicious -gt 0) { "Red" } else { "Green" })`) collapses to a precomputed `$level` variable:
  ```powershell
  $malLevel = if ($malicious -gt 0) { "ERROR" } else { "OK" }
  Write-Ui -Message "  |- Malicious:  $malicious" -Level $malLevel
  ```
- **Risk if changed:** Low — message text preserved verbatim; the `[LEVEL]` bracket emitted by `Write-Ui` replaces the manual color formatting. Per-category fix patterns in Local notes.
- **Local notes:** Four categories of raw `Write-Host` in this script:
  1. **Blank-line / spacer calls** — bare `Write-Host ""` used as vertical spacing (e.g. lines 75, 79, 81, 87, 89, 102, 280, 284, 289, 307, 311, 331, 342, 358, 374, 376, 404, 408, 410, 419, 438, 442, 461, 464, 475, 488, 495, 501, 537, 552, 554, 557, 560, 563, 566, 569, 572, 575, 578, 580, 582, 592, 596, 600, 607, 612, 618, 622, 634, 638, 641, 660, 670, 676, 691, 695, 697, 723, 738, 742, 745, 763, 778, 782, 785, 803, 831, 837, 839, 869, 889, 893, 916, 933, 977, 981, 986, 992). Same exception clause as F2 in `scripts-driver_integrity_scan.md` — leave as-is, or migrate to a `Show-Section` / `Write-Ui -Spacer` helper if added in P4.
  2. **Banner-rule separators** — `Write-Host "============================================================" -ForegroundColor Cyan|Yellow|Green` (lines 76, 78, 281, 283, 308, 310, 405, 407, 439, 441, 533, 536, 553, 581, 593, 595, 623, 635, 637, 692, 694, 739, 741, 779, 781, 890, 892, 920, 978, 980). These are the heaviest cluster. Strong candidate for a single `Show-SouliTEKSeparator -Color Cyan` helper added alongside the C1 sweep — would knock ~30 lines of `Write-Host` calls out by itself.
  3. **Inline-color value rendering** — the `Write-Host "Label: " -NoNewline -ForegroundColor Gray` + `Write-Host $value -ForegroundColor <conditional>` pattern (lines 329–330, 334–337, 340, 462–463, 467–470, 473, 541, 544, 911–914). These are clear C1 violations and collapse cleanly to `Write-Ui` as shown above.
  4. **Plain message lines with hyperlinks** — `Write-Host "  Get yours at: https://www.virustotal.com" -ForegroundColor Cyan` (line 610), `Write-Host "  Full Report: https://www.virustotal.com/gui/file/$($attrs.sha256)" -ForegroundColor Cyan` (line 375, 500), `Write-Host "  1. Go to https://www.virustotal.com" -ForegroundColor Gray` (line 83), `Write-Host "Enter the URL to check..."` (line 743), `Write-Host "Example: https://example.com/download.exe"` (line 744), `Write-Host "Adding https:// prefix..." -ForegroundColor Yellow` (line 759). Migrate to `Write-Ui -Level "INFO"` (or `"STEP"` for prompts, `"WARN"` for the https-prefix notice).
- **Local notes (cont.) — no `Write-SouliTEK*` callers:** zero legacy API callers in this script (C2-clean). Nothing to migrate here for the C2 deprecation step.
- **Target phase:** P1

### F2 — `-ErrorAction SilentlyContinue` triage (see C4)
- **Severity:** low
- **Category:** error-handling
- **Location:** scripts/virustotal_checker.ps1 — 2 occurrences
- **Reference:** [C4](00-cross-cutting.md#c4----erroraction-silentlycontinue-swallowing-failures)
- **Triage:**
  - Line 814: tag **A** — `Get-ChildItem -Path $folderPath -File -ErrorAction SilentlyContinue` enumerates a user-supplied folder. The folder existence is already verified at line 797 (`Test-Path $folderPath -PathType Container`), so the only failure mode here is per-file access-denied during enumeration. `$files.Count -eq 0` is then checked at line 822 with a graceful "No files found matching criteria" message. Legitimate — the script's design is to scan what's accessible, not abort on first denied file. Add `# safe: enumeration over user-supplied folder; per-file ACL denials are expected` comment in P2.
  - Line 818: tag **A** — `Get-ChildItem -Path $folderPath -Filter $ext -File -ErrorAction SilentlyContinue` — same pattern as line 814 but inside the per-extension loop. Same justification. Add `# safe: per-extension enumeration` comment.
- **Local notes:** Both occurrences are the same "scan-what's-readable, skip-what's-not" pattern. Notably **zero** uses of `-ErrorAction SilentlyContinue` on `Invoke-RestMethod`, `Remove-Item`, `New-Item`, or `Test-Path` — the script consistently uses explicit `try { ... -ErrorAction Stop } catch { Write-Ui -Level "ERROR" }` blocks for HTTP and disk I/O (e.g. lines 105–135 for the API-key validation flow, lines 183–197 / 214–234 / 251–266 for the three VT calls). This is the model of how the rest of the repo should handle C4. **Out-of-scope but worth promoting in the C4 phase plan.**
- **Target phase:** P2

### F3 — File is 1048 LOC, just over C6 threshold (see C6)
- **Severity:** med
- **Category:** structure
- **Location:** scripts/virustotal_checker.ps1 — 1048 lines total
- **Reference:** [C6](00-cross-cutting.md#c6--scripts-1000-loc-with-extractable-duplication)
- **Current:** `Show-VTFileResult` (lines 269–391, 123 LOC) and `Show-VTUrlResult` (lines 393–522, 130 LOC) duplicate the "threat-level + stats-table + analysis-date + report-URL" rendering pattern. The differences are: file shows `meaningful_name`/`type_description`/`size`/`sha256`, URL shows `last_final_url`/`categories`/encoded URL ID; otherwise the structure is identical (threat-color thresholds with different numeric breakpoints, identical 4-row stats table, identical `$Script:ScanResults += [PSCustomObject]@{...}` at the bottom).
- **Recommended:** Extract a `Show-VTStatsTable -Stats $stats` helper for the 8-line malicious/suspicious/harmless/undetected block (lines 334–341 / 467–474), and a `Get-VTThreatLevel -Malicious $m -Suspicious $s -ThresholdsType File|Url` helper for the threat-color logic (lines 313–327 / 444–458). That alone removes ~30 duplicated lines. The `$Script:ScanResults += [PSCustomObject]@{...}` blocks at lines 379–390 and 510–521 are 90% identical and can collapse to a `Add-VTScanResult -Type 'File'|'URL' -...` wrapper. Defer the actual extraction to P4 alongside the module helpers it needs.
- **Risk if changed:** Medium — the rendering pattern is what the operator sees on screen; behavior must be preserved by tests added in P5.
- **Target phase:** P4

### F4 — VT API rate-limit handling is open-loop (no HTTP 429 detection, no exponential backoff)
- **Severity:** med
- **Category:** error-handling / robustness
- **Location:** scripts/virustotal_checker.ps1 — `Invoke-VTFileCheck` (183–197), `Invoke-VTUrlCheck` (214–234), `Invoke-VTUrlScan` (251–266), batch loop (872–875).
- **Current:** The batch loop sleeps a fixed 15 seconds between calls (`Start-Sleep -Seconds 15` at line 874) to fit the documented free-tier limit of 4 requests per minute. The three `Invoke-VT*` helpers catch only one specific HTTP code (`StatusCode -eq 404`, lines 192 and 228) — every other error is surfaced as a generic `Write-Ui -Level "ERROR"` and the call returns `$null`. There is no detection of HTTP 429 ("Too Many Requests"), no `Retry-After` header parsing, no exponential backoff, and no retry loop. If the user has a higher-tier key (which permits higher RPM) and runs a batch alongside another VT client, or if the free-tier counter is already partially consumed, the first 429 silently turns into "Error checking file: Response status code does not indicate success: 429" and the result is dropped from `$Script:ScanResults`.
- **Recommended:** Add a small `Invoke-VTRequest` wrapper used by all three call sites:
  ```powershell
  function Invoke-VTRequest {
      param($Uri, $Headers, $Method = 'Get', $Body = $null, [int]$MaxRetries = 3)
      for ($i = 0; $i -lt $MaxRetries; $i++) {
          try {
              if ($Body) {
                  return Invoke-RestMethod -Uri $Uri -Headers $Headers -Method $Method -Body $Body -ErrorAction Stop
              }
              return Invoke-RestMethod -Uri $Uri -Headers $Headers -Method $Method -ErrorAction Stop
          }
          catch {
              $status = $_.Exception.Response.StatusCode.value__
              if ($status -eq 404) { throw }                          # let caller handle NotFound
              if ($status -eq 429) {
                  $retryAfter = [int]($_.Exception.Response.Headers['Retry-After'] | Select-Object -First 1)
                  if (-not $retryAfter) { $retryAfter = [Math]::Pow(2, $i + 1) * 15 }  # 30, 60, 120s
                  Write-Ui -Message "Rate limited by VirusTotal. Sleeping $retryAfter s before retry $($i + 1)/$MaxRetries..." -Level "WARN"
                  Start-Sleep -Seconds $retryAfter
                  continue
              }
              throw
          }
      }
      throw "VT request failed after $MaxRetries retries"
  }
  ```
  The three `Invoke-VTFileCheck` / `Invoke-VTUrlCheck` / `Invoke-VTUrlScan` callers then become 4-line wrappers around this. The 15-second pre-emptive sleep in the batch loop (line 874) can stay as a polite default but is no longer the only defense.
- **Risk if changed:** Low. Pure additive logic; the success path is unchanged. Hits the C4 "fail closed" principle from CLAUDE.md by surfacing rate-limit waits to the operator rather than silently dropping results.
- **Local notes:** This is the only meaningful behavioral gap in an otherwise well-built API client. Worth doing in P2 alongside the C4 triage rather than waiting for P4.
- **Target phase:** P2

### F5 — No `[CmdletBinding()]` on script or any function
- **Severity:** low
- **Category:** structure
- **Location:** scripts/virustotal_checker.ps1 — script-level (no `param()` block at all) and every one of the 13 internal functions (`Get-VTApiKey` line 48, `Get-FileHashInfo` line 138, `Invoke-VTFileCheck` line 169, `Invoke-VTUrlCheck` line 200, `Invoke-VTUrlScan` line 237, `Show-VTFileResult` line 269, `Show-VTUrlResult` line 393, `Show-Menu` line 524, `Show-Help` line 585, `Invoke-CheckFileByPath` line 628, `Invoke-CheckFileByHash` line 685, `Invoke-CheckUrl` line 732, `Invoke-BatchCheckFiles` line 772, `Show-ScanResults` line 882, `Export-ScanResults` line 926, `Set-ApiKey` line 971).
- **Local notes:** Script is interactive-only by design. Low priority. Adding `[CmdletBinding()]` to `Invoke-VTFileCheck` / `Invoke-VTUrlCheck` / `Invoke-VTUrlScan` would let them accept `-Verbose` for debugging the HTTP flow — useful when chasing F4 rate-limit issues. This is also a C5 candidate if a non-interactive entry point is ever added (`-FilePath` / `-Url` / `-Hash` parameters that bypass the menu).
- **Target phase:** P4

### F6 — `Split-Path -Parent $MyInvocation.MyCommand.Path` instead of `$PSScriptRoot`
- **Severity:** low
- **Category:** structure
- **Location:** scripts/virustotal_checker.ps1:25
- **Current:**
  ```powershell
  $Script:ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
  ```
- **Recommended:**
  ```powershell
  $Script:ScriptPath = $PSScriptRoot
  ```
- **Risk if changed:** Low. Same rationale as F5 of `scripts-driver_integrity_scan.md` — `$PSScriptRoot` is the canonical PS-3.0+ automatic variable; `$MyInvocation.MyCommand.Path` is `$null` when dot-sourced. Fold into the C10 sweep.
- **Target phase:** P4

### F7 — Infinite menu loop with no non-interactive exit + blocking `Read-Host` prompts
- **Severity:** low
- **Category:** structure (UX / RMM safety)
- **Location:** scripts/virustotal_checker.ps1:1025 (`do { ... } while ($true)`), plus `Read-Host` calls at lines 91 (`-AsSecureString`), 115, 412, 643, 699, 747, 787, 805, 994, 1027.
- **Local notes:** Same pattern as F6 in `scripts-driver_integrity_scan.md`. Under SYSTEM-context RMM, every `Read-Host` deadlocks. The `Read-Host -AsSecureString` at line 91 for the API key is the only legitimate one that *must* remain blocking — but it should be gated behind `[Environment]::UserInteractive` so the SYSTEM path takes a saved-DPAPI-key-only branch and fails closed if no saved key exists. Defer to P4.
- **Target phase:** P4

### F8 — Result-storage `$scanDate` referenced after possibly never being set in `Show-VTFileResult`
- **Severity:** low
- **Category:** correctness (note only — current behavior is benign)
- **Location:** scripts/virustotal_checker.ps1:388 (uses `$scanDate` in the `Script:ScanResults += [PSCustomObject]@{ ... ScanDate = $scanDate }` block), with `$scanDate` defined inside the `if ($attrs.last_analysis_date)` block at lines 360–362.
- **Local notes:** If `$attrs.last_analysis_date` is `$null` or `0` (a legitimate VT response state for a freshly-submitted hash not yet analyzed), `$scanDate` is never assigned and the `PSCustomObject` ends up with `ScanDate = $null`. The export pipeline (`Export-SouliTEKReport`) handles `$null` cells fine, so this is benign — but the parallel function `Show-VTUrlResult` (line 504) correctly guards this with a `$scanDateStr = if ($attrs.last_analysis_date) { ... } else { "Unknown" }` block. Mirror that pattern in `Show-VTFileResult` for consistency. Defer to F3's refactor pass.
- **Target phase:** P4

## Out-of-scope notes

- **SECURITY MODEL REFERENCE — exemplary posture.** This script is the canonical demonstration of how the SouliTEK security helpers should be used:
  - **DPAPI key storage** — `Protect-SouliTEKSecret` / `Unprotect-SouliTEKSecret` round-trip the 64-char VT API key through `ConvertFrom-SecureString` (which uses DPAPI under the user's account in PS 5.1+ when no `-Key` is supplied), storing the encrypted blob in `%LOCALAPPDATA%\SouliTEK\VTApiKey.txt`. Decrypts only in-process via `SecureStringToBSTR` → `PtrToStringAuto` → `ZeroFreeBSTR` (lines 92–94). Correct lifecycle.
  - **Graceful legacy fallback** — the comment at line 67 ("Falls through to prompt — handles legacy plaintext files gracefully") is the right migration story: if a pre-DPAPI plaintext key file exists, decryption fails inside the `try`, control falls through to the prompt, and the user re-enters the key which then gets saved DPAPI-encrypted. No data loss, no crash, no exposure.
  - **Live key validation before persist** — the key is tested against a known-good VT hash (`275a021bbfb6489e54d471899f7db9d1663fc695ec2fe2a2c4538aabf651fd0f` at line 109) BEFORE being written to disk. Invalid keys are rejected immediately rather than persisted and failing on first real use.
  - **Length validation** — `if ($key.Length -ne 64)` (line 96) rejects malformed input. Hex-only validation (`if ($hash -notmatch '^[a-fA-F0-9]+$'` at line 717) on user-supplied hashes is correct input sanitization.
  - **Privacy-by-design notice in `Show-Help`** — lines 619–621 explicitly tell the user "This tool only sends file HASHES to VirusTotal, NOT the actual files." This is a deliberate design choice: `Invoke-VTFileCheck` (line 169) takes only `$Hash`, not `$FilePath`. The `/files/$hash` GET endpoint is read-only against VT's existing corpus — no `POST /files` upload path exists in this code. Matches OWASP A02:2021 "Cryptographic Failures" guidance to minimize what crosses the network.
  - **API-key mask in `Set-ApiKey`** — `$Script:ApiKey.Substring(0, 8) + "..." + $Script:ApiKey.Substring(56)` (line 984) shows 16 of 64 characters (25%) which is the right balance for "let the operator confirm which key is loaded" without leaking enough to be useful to a shoulder-surfer.
  - **`Confirm-SouliTEKFileHash` is NOT used here**, despite being mentioned in the task brief. That's correct — VT-returned hashes are not "expected" hashes to confirm against; they're informational. `Confirm-SouliTEKFileHash` is the right tool for installer/download verification (covered in C12 for `Install-SouliTEK.ps1`), not for VT queries.
  - **No logging of secrets** — `$apiKey`, `$key`, `$decrypted`, `$Script:ApiKey` never appear in a `Write-Host` / `Write-Ui` / `Write-Verbose` call anywhere. The closest is the masked form in `Set-ApiKey`. Verified by grep over the file.

  **Recommendation:** when documenting the security baseline in P0/P6, cite this file by section: `Get-VTApiKey` (lines 48–136) is the reference implementation for "secure secret prompt + DPAPI persist + live validation"; `Set-ApiKey` (lines 971–1011) is the reference for "rotate/remove saved secret with masked display."

- **Banner block (lines 1–14)** is 13 lines — already shorter than the 25–35-line average noted in C11. Borderline; not worth a separate fix.
- **`Get-FileHashInfo` (lines 138–167)** correctly uses the built-in `Get-FileHash` cmdlet with explicit `-Algorithm` for all three hash types. No reinvented crypto. The error-swallowing `catch { return $null }` (line 164–166) is a deliberate "caller checks for `$null`" contract used at lines 664 and 846 — defensible but a `Write-Verbose "Hash failed: $_"` would help debugging.
- **Batch limit (`$maxFiles = 10` at line 829)** with a 15-second sleep gives 10 files in ~2:30, fitting comfortably under the 4-req/min × 1.5 = 6-request-budget the free tier provides over that window. Sound numbers.
- **`Invoke-VTUrlScan` (line 237)** uses `Content-Type: application/x-www-form-urlencoded` with a manually-URL-encoded body, which matches VT API v3's documented `POST /urls` contract. Correct.
- **Base64 URL-safe encoding for URL identifiers** (lines 220–221, 498–499): `ToBase64String → TrimEnd('=') → Replace('+', '-') → Replace('/', '_')` — exactly the URL-safe base64 variant VT requires for the `/urls/{id}` GET endpoint. Correct.
- **`Add-Type -AssemblyName System.Web`** at line 1022 is only needed for `[System.Web.HttpUtility]::UrlEncode` at line 257. PS 5.1 ships with this assembly available but not auto-loaded for `System.Web.HttpUtility`. Could be moved to `Invoke-VTUrlScan` for laziness, but harmless at top-level.
- **Hard-coded Desktop path** in `Export-ScanResults` (line 946, `[Environment]::GetFolderPath("Desktop")`) is the same F7-style issue as `driver_integrity_scan.md` — fails under SYSTEM context. Same `-OutputDirectory` parameter recommendation applies. Defer to P4.
- **`Show-SouliTEKExitMessage -ScriptPath $PSCommandPath`** (line 1039) is the right idiom — `$PSCommandPath` is the canonical script-path automatic variable, not the `$MyInvocation` form used at line 25. Inconsistency worth noting but the F6 fix unifies them.
