# Audit — scripts/domain_dns_analyzer.ps1

## Inventory
| Item | Value |
|---|---|
| Path           | scripts/domain_dns_analyzer.ps1 |
| LOC            | 1721 |
| Functions      | 14 |
| `#Requires`    | _(none)_ |
| Admin-required | no (DNS lookups, WHOIS via Sysinternals binary, outbound TCP/443 for SSL inspection — no privileged calls) |
| Last touched   | 8675720 — 2026-04-17 |
| Modernization grade | C |
| Vendored binary | `tools/whois.exe` — 398,712 bytes; SHA256 `EA845B43C323E35DF041B8914A520F1D9643E3689454AB3049C2103458A0142D`; last committed `692ba30 — 2025-12-02` |

## Summary

Menu-driven domain reconnaissance toolkit: WHOIS lookup (delegated to Sysinternals `whois.exe`), DNS record enumeration (`Resolve-DnsName` over the A/AAAA/MX/TXT/CNAME/NS/SOA/SRV record types), email-security analysis (SPF/DKIM/DMARC parsing with a built-in 10-selector DKIM probe list), SSL/TLS certificate inspection (raw `TcpClient` + `SslStream`), and TXT/CSV/HTML export. Structure is conventional — 14 functions, ~10 cross-cutting findings — but two issues dominate. (1) **F_supply_chain — `tools/whois.exe` is a vendored 398 KB Sysinternals binary invoked at line 251 and 941 with full user-context authority**; the script *does* contain a guarded hash-verification path (lines 182–187) but the `$whoisExpectedHash` constant on line 173 is the literal placeholder `"PASTE_SHA256_HERE"`, and the surrounding `if ($whoisExpectedHash -ne "PASTE_SHA256_HERE")` gate (line 182) means the check is silently skipped today — every run trusts whatever sits at `tools\whois.exe`. The Authenticode check on line 189 only fires after a fresh download, not on the already-present vendored copy. This is the highest-leverage failure mode in the file and the primary motivation for raising F5 to **high** severity. (2) **C1 — 216 raw `Write-Host` occurrences** (second highest in the repo after `EventLogAnalyzer`), broken down as 112 bare spacers (`Write-Host ""`), 44 `=`-bar dividers with inline `-ForegroundColor`, 51 `-NoNewline -ForegroundColor White` label-prefix calls in the WHOIS / SSL / SPF detail blocks, plus the residual plain message lines; **24 legacy `Write-SouliTEKResult` calls** (C2 dead-API) also keep the legacy output API alive. Secondary concerns: 9 `-ErrorAction SilentlyContinue` occurrences, mostly defensible (temp-file cleanup, NS-fallback probes) but the two `Resolve-DnsName -ErrorAction SilentlyContinue` calls (lines 420 + 1011) silently swallow legitimate DNS failures inside fallback paths and should be triaged as tag B; C6 — five functions are >175 LOC each (`Get-DomainWhois` 287, `Get-EmailSecurityRecords` 276, `Get-FullDomainAnalysis` 275, `Get-SSLCertificate` 195, `Export-AnalysisResults` 189) and contain duplicate WHOIS-parse / DNS-record-handle / status-table-render logic across `Get-DomainWhois`/`Get-FullDomainAnalysis` and `Get-DNSRecords`/`Get-FullDomainAnalysis`; C13 — the DKIM-selector loop (lines 705–723) makes 10 sequential `Resolve-DnsName` calls per email-security run, each of which can take 100–500 ms on a cold cache (1–5 s of latency for one operation that is trivially parallelizable). No `[CmdletBinding()]` / `param()` surface on the script or any of the 14 functions; `Split-Path -Parent $MyInvocation.MyCommand.Path` (line 38) instead of `$PSScriptRoot`; 11 blocking `Read-Host "Press Enter to return to main menu"` prompts that deadlock under RMM. Recommended phase entry order: **P0 (F5 — pin the whois.exe hash NOW; either delete the dead `if (...)` gate so the check actually runs, or replace the placeholder with the real SHA256 from the inventory above)**, then P1 (C1 + C2 sweep, 240 sites), then P2 (C4 triage — 9 sites, mostly tag A with two tag-B fallbacks), then P4 (C6 extract + C13 parallel DKIM, C10 import).

## Findings

### F1 — Raw `Write-Host` calls not migrated to `Write-Ui`/`Write-Status` (see C1)
- **Severity:** med
- **Category:** output-style
- **Location:** scripts/domain_dns_analyzer.ps1 — 216 raw `Write-Host` occurrences across all 5 high-LOC functions plus `Show-Help` and `Show-MainMenu`. Also **24** calls to the C2 dead API (`Write-SouliTEKResult` with `-Level INFO|SUCCESS|WARNING|ERROR`) at lines 93, 235, 242, 261, 467, 477, 520, 631, 907, 934, 1003, 1007, 1075, 1144, 1172, 1240, 1251, 1326, 1334, 1341, 1449, 1470, 1606, 1672.
- **Reference:** [C1](00-cross-cutting.md#c1--raw-write-host-calls-not-migrated-to-write-uiwrite-status), [C2](00-cross-cutting.md#c2--dead-duplicate-output-api)
- **Current (representative pattern — label-prefix split, lines 349–350):**
  ```powershell
  Write-Host "  Domain:      " -NoNewline -ForegroundColor White
  Write-Ui -Message $whoisData.Domain -Level "INFO"
  ```
- **Recommended:**
  ```powershell
  Write-Ui -Message "  Domain:      $($whoisData.Domain)" -Level "INFO"
  ```
- **Risk if changed:** Low — message text preserved verbatim; the `[INFO]` bracket replaces the manual `-ForegroundColor White` framing. The split-line "label + value" form (e.g. lines 349–350, 352–355, 360–361, 368–376, 381–389, 394–408, 435–440, 653–676, 681–691, 726–742, 790–805, 846–847, 1485–1492, 1509–1516, 1525–1526, 1531–1540, 1542–1543, 1569–1570, 1586–1593) consistently merges into a single `Write-Ui` with the label concatenated into the message string.
- **Local notes:** Four categories of raw `Write-Host`:
  1. **Bare spacer calls** — `Write-Host ""` used as vertical spacing, **112 occurrences** (50%+ of all `Write-Host` calls in the file). Sample lines: 157, 160, 220, 222, 234, 236, 241, 243, 343, 347, 363, 411, 434, 448, 452, 478, 484, 491, 507, 509, 519, 521, 528, 600, 604, 618, 620, 630, 632, 640, 645, 693, 695, 700, 745, 754, 774, 776, 781, 833, 835, 839, 848, 860, 878, 880, 894, 896, 906, 908, 913, 922 _(continues to 1660)_. Not strict C1 violations under the "visual separator helpers" exception, but candidates for a `Write-Ui -Spacer` / `Show-Section` migration once that helper lands in P4.
  2. **`=`-bar dividers with inline color** — `Write-Host "============================================================" -ForegroundColor (Cyan|Green|Magenta|Gray|DarkYellow)`, **44 occurrences** (lines 221, 344, 346, 449, 453, 455, 457, 508, 525, 527, 603, 619, 637, 639, 834, 879, 895, 927, 929, 1023, 1025, 1078, 1080, 1147, 1149, 1154, 1168, 1356, 1386, 1388, 1399, 1401, 1410, 1412, 1420, 1437, 1473, 1475, 1574, 1597, 1634), plus 4 short-bar dividers (`Write-Host "----...---"` lines 694, 775; `Write-Host "========================================"` line 1660; `Write-Host "------------------------------------------------------------"`). Clear C1 violations — `Show-SouliTEKSeparator` or a new `Show-Section -Title "..." -Level "..."` helper exists for exactly this.
  3. **Label-prefix splits with `-NoNewline -ForegroundColor White`** — 51 occurrences (lines 349, 352, 360, 368, 381, 394, 435, 653, 662, 666, 670, 674, 681, 688, 726, 739, 790, 797, 800, 803, 809, 813, 820, 827, 846, 856, 858, 1037, 1070, 1088, 1098, 1103, 1127, 1139, 1485, 1488, 1490, 1493, 1509, 1512, 1515, 1525, 1531, 1534, 1539, 1542, 1569, 1586, 1589). Clear C1 violations — collapse to a single `Write-Ui` per the recommendation above.
  4. **Plain message lines with inline `-ForegroundColor`** — e.g. line 208 (`Write-Host "      https://learn.microsoft.com/en-us/sysinternals/downloads/whois" -ForegroundColor Cyan`), line 402 (`Write-Host "$($expiresDate.ToString('yyyy-MM-dd')) " -NoNewline -ForegroundColor $expiryColor`), line 403, line 486 (`Write-Host "  https://who.is/whois/$Domain" -ForegroundColor Cyan`), line 994, lines 1037/1070/1088/1098/1103/1127/1139 (DNS-record `[type]` markers), line 1474, lines 1490/1491/1537. Clear C1 violations.
- **Local notes (cont.) — C2 dead-API callers:** All 24 `Write-SouliTEKResult` calls must migrate to `Write-Ui -Level "..."` before C2's "delete the five legacy functions from the module" step can land. Level mapping: `-Level INFO` → `-Level "INFO"`; `-Level SUCCESS` → `-Level "OK"`; `-Level WARNING` → `-Level "WARN"`; `-Level ERROR` → `-Level "ERROR"`. Pure mechanical replacement, no logic change. Sample (line 93): `Write-SouliTEKResult "Invalid domain format: $domain" -Level ERROR` → `Write-Ui -Message "Invalid domain format: $domain" -Level "ERROR"`.
- **Local notes (cont.) — inline marker prefixes in existing `Write-Ui` calls:** Many existing `Write-Ui` calls already double-mark with embedded `[*]`/`[+]`/`[-]`/`[!]` or `[SPF]`/`[DKIM]`/`[DMARC]`/`[type]` brackets inside the message (sample lines: 140, 158, 175, 195, 200, 205, 206, 207, 248, 415, 423, 424, 427, 430, 531, 643, 698, 779, 938, 1014). Same anti-pattern as F2 of 01-modules-SouliTEK-Common.md and F2 of scripts-driver_integrity_scan.md — when the C1 sweep is done, strip the inline `[*]`/`[+]`/`[-]` markers so the `[LEVEL]` bracket emitted by `Write-Ui` is the only marker. The `[SPF]`/`[DKIM]`/`[DMARC]`/`[A]`/`[MX]` etc. tags are semantically meaningful section headers and should stay (or move to a `Show-Section -Title "SPF" -Level "STEP"` form).
- **Target phase:** P1

### F2 — `-ErrorAction SilentlyContinue` triage (see C4)
- **Severity:** med
- **Category:** error-handling
- **Location:** scripts/domain_dns_analyzer.ps1 — 9 occurrences
- **Reference:** [C4](00-cross-cutting.md#c4----erroraction-silentlycontinue-swallowing-failures)
- **Triage:**
  - Line 192: tag **A** — `Remove-Item -Path $WhoisPath -Force -ErrorAction SilentlyContinue`; post-hash-failure cleanup of the freshly-downloaded `whois.exe` so a bad binary doesn't linger. Legitimate. Add `# safe: cleanup after failed integrity check` comment.
  - Line 254: tag **A** — `Get-Content "$env:TEMP\whois_output.txt" -Raw -ErrorAction SilentlyContinue`; reads the redirected stdout file after `Start-Process -RedirectStandardOutput`. May be empty/absent if whois.exe produced no stdout; `$whoisText` is then tested with `if ($whoisText -and $whoisText.Trim().Length -gt 0)` before use. Legitimate. Add `# safe: optional read` comment.
  - Line 255: tag **A** — `Remove-Item "$env:TEMP\whois_output.txt" -ErrorAction SilentlyContinue`; post-use temp-file cleanup. Pure C4-tag-A. Add `# safe: cleanup` comment.
  - Line 420: tag **B** — `$nsRecords = Resolve-DnsName -Name $Domain -Type NS -ErrorAction SilentlyContinue -DnsOnly`; this is the WHOIS-failed fallback "try to get nameservers from DNS instead" path. Currently swallows every failure category (NXDOMAIN, timeout, server unreachable) silently and falls through to `Write-Ui -Message "    No nameservers found"`. Should be `try { Resolve-DnsName -ErrorAction Stop ... } catch { Write-Ui -Message "    DNS lookup failed: $($_.Exception.Message)" -Level "WARN" }` so the operator sees *why* the fallback also failed.
  - Line 462: tag **A** — `Get-Content "$env:TEMP\whois_error.txt" -Raw -ErrorAction SilentlyContinue`; reads redirected stderr, same pattern as 254. Legitimate. Add `# safe: optional read` comment.
  - Line 463: tag **A** — `Remove-Item "$env:TEMP\whois_error.txt" -ErrorAction SilentlyContinue`; cleanup of the stderr temp file, same as 255. Legitimate.
  - Line 944: tag **A** — duplicate of line 254 inside `Get-FullDomainAnalysis`. Same justification, same comment.
  - Line 945: tag **A** — duplicate of line 255 inside `Get-FullDomainAnalysis`. Same justification, same comment.
  - Line 1011: tag **B** — duplicate of line 420 inside the `Get-FullDomainAnalysis` exception handler (`catch { ... try { $nsRecords = Resolve-DnsName ... -ErrorAction SilentlyContinue ... } catch { } }`). The outer `catch { }` (line 1018) is **itself** a tag-C empty catch (silently swallows the DNS fallback failure) — collapse both into a single `try { ... } catch { Write-Ui -Message "  DNS fallback failed: $($_.Exception.Message)" -Level "WARN" }`.
- **Target phase:** P2

### F3 — Five extract-candidate functions >175 LOC (see C6)
- **Severity:** med
- **Category:** structure
- **Location:** scripts/domain_dns_analyzer.ps1 — 14 functions total; the 5 largest account for 1,222 LOC (71% of the file):
  | Function | Start | LOC | Extract candidates |
  |---|---|---|---|
  | `Get-DomainWhois` | 214 | **287** | WHOIS-text regex parser (lines 277–340: 8 regex blocks for registrar/created/updated/expires/nameservers/status/DNSSEC) → extract as `ConvertFrom-WhoisText` returning a `[PSCustomObject]`. Display block (lines 343–457) → extract as `Show-WhoisRecord`. Currently duplicated in `Get-FullDomainAnalysis` (lines 952–1001 cover the same regex set in compressed form). |
  | `Get-EmailSecurityRecords` | 612 | **276** | SPF parser (lines 647–691), DKIM probe loop (lines 705–767), DMARC parser (lines 783–831), scoring + bar render (lines 837–876). Each is a self-contained block — extract as `Test-SpfRecord`, `Test-DkimRecord`, `Test-DmarcRecord`, `Get-EmailSecurityScore` (returning `[PSCustomObject]` with score + recommendations). Currently duplicated in `Get-FullDomainAnalysis` (lines 1083–1142) in compressed form. |
  | `Get-FullDomainAnalysis` | 888 | **275** | Almost entirely **duplicate** of `Get-DomainWhois` + `Get-DNSRecords` + `Get-EmailSecurityRecords`, with slightly different output formatting. After F3's extract-pattern lands, this function reduces to `~50 LOC` orchestrating the four extracted helpers. **Highest-impact extract in the file.** |
  | `Get-SSLCertificate` | 1430 | **195** | Cert-retrieval (TCP/SSL/X509) lines 1452–1468 → extract as `Get-RemoteCertificate -Domain $d -Port 443`. Cert-display block (lines 1473–1602) → extract as `Show-CertificateDetails`. SAN-parse block (lines 1549–1564) → extract as `Get-CertificateSans`. The `TcpClient`/`SslStream` block is also missing a `try`/`finally` around `Close()` (resource leak if `AuthenticateAsClient` throws) — fix during extract. |
  | `Export-AnalysisResults` | 1163 | **189** | TXT-emit (lines 1196–1242), CSV-emit (1243–1253), HTML-emit (1255–1328). Three near-identical switch branches. Extract as `Export-AnalysisResultsAsText`, `Export-AnalysisResultsAsCsv`, `Export-AnalysisResultsAsHtml` keyed by `-Format` parameter. The HTML template (lines 1259–1284 + 1289–1320) is an inline heredoc that belongs in a `templates/domain-report.html` file with `${placeholder}` interpolation. |
- **Reference:** [C6](00-cross-cutting.md#c6--scripts-1000-loc-with-extractable-duplication)
- **Local notes:** The `Initialize-WhoisTool` function (87 LOC) is borderline but does **one** thing cleanly (locate/download/verify the binary) and should not be split. `Get-DNSRecords` (111 LOC) is the cleanest function in the file and is a useful reference shape for the extract targets above. After P4's extracts, expected post-refactor LOC: ~900 (down from 1721, ~48% reduction), assuming `Get-FullDomainAnalysis` becomes a thin orchestrator over `Get-DomainWhois`/`Get-DNSRecords`/`Get-EmailSecurityRecords` rather than duplicating their bodies.
- **Target phase:** P4

### F4 — Sequential DKIM selector probe — 10 serial `Resolve-DnsName` calls per email-security run (see C13)
- **Severity:** low (perf)
- **Category:** perf
- **Location:** scripts/domain_dns_analyzer.ps1:705–723 (the `foreach ($selector in $Script:DKIMSelectors)` loop inside `Get-EmailSecurityRecords`); also duplicated in compressed form at lines 1105–1116 (4-selector fast-path inside `Get-FullDomainAnalysis`).
- **Reference:** [C13](00-cross-cutting.md#c13--sequential-foreach-over-large-datasets-where-parallelism-would-help)
- **Current:**
  ```powershell
  foreach ($selector in $Script:DKIMSelectors) {            # 10 selectors at line 56–67
      $dkimDomain = "$selector._domainkey.$Domain"
      try {
          $dkimRecord = Resolve-DnsName -Name $dkimDomain -Type TXT -ErrorAction Stop -DnsOnly
          if ($dkimRecord -and ($dkimRecord.Strings -join "") -match "v=DKIM1") {
              $foundSelectors += @{ Selector = $selector; Record = $dkimValue }
              $dkimFound = $true
          }
      }
      catch { # Selector not found, continue to next
      }
  }
  ```
- **Recommended (P4 — depends on `Invoke-SouliTEKParallel` helper in C13):**
  ```powershell
  $foundSelectors = Invoke-SouliTEKParallel -InputObject $Script:DKIMSelectors -MaxThreads 8 -ScriptBlock {
      param($selector, $Domain)
      try {
          $rec = Resolve-DnsName -Name "$selector._domainkey.$Domain" -Type TXT -ErrorAction Stop -DnsOnly
          if ($rec -and ($rec.Strings -join "") -match "v=DKIM1") {
              [PSCustomObject]@{ Selector = $selector; Record = ($rec.Strings -join "") }
          }
      } catch { }
  } -ArgumentList $Domain
  $dkimFound = ($foundSelectors.Count -gt 0)
  ```
- **Risk if changed:** Medium. DNS resolvers usually handle 8-way parallelism fine; cap at `-MaxThreads 8` to stay friendly to home routers and rate-limited resolvers. Expected speedup: 10 selectors × ~250 ms cold-cache = ~2.5 s sequential vs ~400 ms parallel (6×). **Do not refactor until the module helper exists** (P4 dependency, per C13).
- **Local notes:** The per-record-type DNS loop in `Get-DNSRecords` (lines 530–601, 8 record types A/AAAA/MX/TXT/CNAME/NS/SOA/SRV) is the **other** sequential DNS loop in this file. It is technically a parallel candidate too (8 × ~150 ms = 1.2 s vs ~250 ms parallel), but the speedup is smaller, the result rendering is interleaved with the lookups via the inline `switch ($type) { ... }` block, and extracting the lookups from the rendering adds complexity. Defer the per-record-type loop to a secondary P4 candidate; tackle the DKIM loop first. The 4-selector compressed loop at lines 1105–1116 inside `Get-FullDomainAnalysis` is the same pattern — fold it into the same helper call.
- **Target phase:** P4

### F5 — Vendored third-party binary `tools/whois.exe` shipped with a placeholder hash; runtime hash-verify gate silently skipped (F_supply_chain)
- **Severity:** **high**
- **Category:** security / supply-chain
- **Location:** scripts/domain_dns_analyzer.ps1 — `Initialize-WhoisTool` at line 127 (path resolution + integrity gate), `Get-DomainWhois` at line 251 (invocation site #1), `Get-FullDomainAnalysis` at line 941 (invocation site #2).
- **Reference:** local (`F_supply_chain` pattern shared with F3 of `scripts-mcafee_removal_tool.md`). Conceptually adjacent to [C12](00-cross-cutting.md#c12--installer-downloads-zip-without-mandatory-hash-verification-by-default).
- **Current:**
  ```powershell
  # Line 146 — path computed but never validated to be under the project's tools/ folder:
  $ScriptRoot = $PSScriptRoot
  $ProjectRoot = Split-Path -Parent $ScriptRoot
  $WhoisPath = Join-Path $ProjectRoot "tools\whois.exe"

  # Line 149 — existence-only short-circuit: vendored copy bypasses the download path
  # AND the Authenticode check below (which only fires after a fresh download):
  if (Test-Path $WhoisPath) {
      $Script:WhoisToolPath = $WhoisPath
      $Script:WhoisToolChecked = $true
      return $true
  }

  # Line 173 — placeholder constant. Hash-verify gate at line 182 is conditional on
  # this NOT being the placeholder — i.e. the hash check is silently skipped today:
  $whoisExpectedHash = "PASTE_SHA256_HERE"
  ...
  if ($whoisExpectedHash -ne "PASTE_SHA256_HERE") {     # gate is false -> check skipped
      if (-not (Confirm-SouliTEKFileHash -FilePath $WhoisPath -ExpectedHash $whoisExpectedHash)) {
          Write-Ui -Message "whois.exe hash verification failed. Binary removed for safety." -Level "ERROR"
          return $false
      }
  }

  # Line 189 — Authenticode check, but only runs after a fresh download. The vendored
  # copy is treated as trusted unconditionally:
  $sig = Get-AuthenticodeSignature -FilePath $WhoisPath
  if ($sig.Status -ne "Valid") { ... Remove-Item ...; return $false }
  ```
- **Recommended:**
  ```powershell
  # 1. Pin the canonical hash and remove the placeholder gate. The hash MUST be the
  #    real SHA256 of the currently-vendored copy (see Inventory above).
  $WhoisExpectedHash = 'EA845B43C323E35DF041B8914A520F1D9643E3689454AB3049C2103458A0142D'

  # 2. Validate the resolved path stays under the project's tools/ folder
  #    (defence against any future param surface that lets WhoisPath be overridden):
  $toolsDir = Join-Path $ProjectRoot 'tools'
  if (-not (Test-SafeFilePath -UserInput 'whois.exe' -BaseDir $toolsDir)) {
      Write-Ui -Message "whois.exe path failed safety check." -Level "ERROR"
      return $false
  }

  # 3. ALWAYS verify SHA256 — both for the vendored copy and any fresh download.
  #    Move the check above the Test-Path short-circuit so the vendored copy is
  #    no longer trusted unconditionally:
  if (Test-Path $WhoisPath) {
      if (-not (Confirm-SouliTEKFileHash -FilePath $WhoisPath -ExpectedHash $WhoisExpectedHash)) {
          Write-Ui -Message "Refusing to use whois.exe: integrity check failed." -Level "ERROR"
          return $false
      }
      # Also verify Authenticode on the vendored copy, not just on fresh downloads:
      $sig = Get-AuthenticodeSignature -FilePath $WhoisPath
      if ($sig.Status -ne 'Valid' -or $sig.SignerCertificate.Subject -notlike '*Microsoft*') {
          Write-Ui -Message "Refusing to use whois.exe: Authenticode signature not Microsoft-signed ($($sig.Status))." -Level "ERROR"
          return $false
      }
      $Script:WhoisToolPath = $WhoisPath
      $Script:WhoisToolChecked = $true
      return $true
  }
  # ... download path falls through with same hash + signature verification ...
  ```
- **Risk if changed:** Low. Both helpers already exist in `modules/SouliTEK-Common.ps1` (`Test-SafeFilePath` and `Confirm-SouliTEKFileHash`); `Confirm-SouliTEKFileHash` is fail-closed and `Remove-Item -Force`-deletes the offending file on mismatch. Cost is one `Get-FileHash` call (~3 ms for a 400 KB file) per `Initialize-WhoisTool` call, and `$Script:WhoisToolChecked` already short-circuits subsequent invocations within a single session.
- **Local notes — binary origin & security model:**
  - **Origin:** Microsoft Sysinternals Whois (`whois.exe`), distributed at `https://learn.microsoft.com/en-us/sysinternals/downloads/whois` and mirrored at `https://live.sysinternals.com/whois.exe` (used by the auto-download path in `Initialize-WhoisTool` line 169).
  - **Vendored copy:** committed in `692ba30 — 2025-12-02`. Single commit in `git log -- tools/whois.exe`; never updated since.
  - **Canonical pinned hash (SHA256, as of 2026-05-15):** `EA845B43C323E35DF041B8914A520F1D9643E3689454AB3049C2103458A0142D`. Size: 398,712 bytes. This is the canonical pinned value for the P0 hash-pin remediation. Whenever `whois.exe` is refreshed in the repo, both the vendored binary **and** this constant must be updated atomically in the same commit, and this audit must be updated to match.
  - **Security model:** `whois.exe` runs with the calling user's privileges. This script does not declare `#Requires -RunAsAdministrator`, so the EXE typically runs with standard user rights — a swapped-in malicious `whois.exe` therefore gets *user-context* execution only, not SYSTEM. This is materially lower-risk than MCPR.exe (which runs elevated) — but still high enough to warrant the P0 fix, because (a) user-context code can persist itself, exfiltrate `$env:USERPROFILE\Desktop` exports and clipboard content, and (b) the script is bundled in `Install-SouliTEK.ps1` (`tools\whois.exe` is in the manifest line 67), so a poisoned binary spreads to every machine that runs the installer.
  - **Why not just `Get-AuthenticodeSignature`?** The script *does* check Authenticode (line 189), but only on freshly-downloaded binaries — never on the vendored copy. Hash + signature combined is the right answer; the recommendation above moves the signature check above the `Test-Path` short-circuit so it applies to both the vendored and the downloaded paths. Authenticode alone is not sufficient (a swapped-in copy can pass cert validation if it's a legitimately-signed older release with known CVEs).
  - **Why not delete `tools/whois.exe` and always download fresh?** Two reasons: (1) the installer manifest (`Install-SouliTEK.ps1` line 67) ships the binary so first-run works offline; (2) `live.sysinternals.com` periodically rotates the binary without changelog publication — hash-pinning a known-good vendored copy is the higher-confidence path. The recommended fix keeps the auto-download fallback but adds the same hash check, so a stale or replaced upstream binary fails the gate.
- **Target phase:** **P0** (highest priority in this file — pin the hash and delete the placeholder-gate dead code before anything else lands)

### F6 — No `[CmdletBinding()]` on script or any function
- **Severity:** low
- **Category:** structure
- **Location:** scripts/domain_dns_analyzer.ps1 — script-level (no `param()` block at all, top of file directly jumps to `$Host.UI.RawUI.WindowTitle = ...` on line 35) and every one of the 14 internal functions (`Get-ValidDomain` line 73, `Add-AnalysisResult` line 101, `Initialize-WhoisTool` line 127, `Get-DomainWhois` line 214, `Get-DNSRecords` line 501, `Get-EmailSecurityRecords` line 612, `Get-FullDomainAnalysis` line 888, `Export-AnalysisResults` line 1163, `Show-Help` line 1352, `Get-SSLCertificate` line 1430, `Show-MainMenu` line 1625, `Clear-AnalysisResults` line 1666, `Show-Disclaimer` line 1678, `Show-ExitMessage` line 1683).
- **Local notes:** Same pattern as F4 of `scripts-driver_integrity_scan.md`. The script is fully interactive (`Read-Host` menu loop, no CLI surface), so this is low-severity. Adding `[CmdletBinding()]` to the five extract candidates listed in F3 (`Get-DomainWhois`, `Get-DNSRecords`, `Get-EmailSecurityRecords`, `Get-SSLCertificate`, `Export-AnalysisResults`) plus a `[CmdletBinding()] param([string]$Domain, [switch]$NonInteractive)` block on the script itself would unlock automated/RMM callers ("`.\domain_dns_analyzer.ps1 -Domain example.com -NonInteractive` → JSON to stdout"). Pair with the C10 sweep.
- **Target phase:** P4

### F7 — `Split-Path -Parent $MyInvocation.MyCommand.Path` instead of `$PSScriptRoot`
- **Severity:** low
- **Category:** structure
- **Location:** scripts/domain_dns_analyzer.ps1:38
- **Current:**
  ```powershell
  $ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
  ```
- **Recommended:**
  ```powershell
  $ScriptRoot = $PSScriptRoot
  ```
- **Risk if changed:** Low. Same recommendation as F5 of scripts-driver_integrity_scan.md / F5 of scripts-mcafee_removal_tool.md. **Note:** `Initialize-WhoisTool` (line 144) *already* uses `$PSScriptRoot` correctly — the inconsistency between the two import-time path resolutions is itself a small bug (script-level uses `$MyInvocation.MyCommand.Path`, the function uses `$PSScriptRoot`). C10 will eventually replace this whole import block with `Import-SouliTEKCommon`, but until then the one-line fix is free.
- **Target phase:** P4 (fold into the C10 sweep)

### F8 — 11 blocking `Read-Host` prompts with no non-interactive escape; menu loop has no automatable exit
- **Severity:** low
- **Category:** structure (UX / RMM safety)
- **Location:** scripts/domain_dns_analyzer.ps1 — `do { ... } while ($choice -ne "0")` menu loop at lines 1699–1720, plus `Read-Host` calls at lines 76 (domain entry), 237 (post-WHOIS-error), 492 (post-WHOIS), 605 (post-DNS), 746 (custom DKIM selector), 881 (post-email-security), 915 (full-analysis confirm), 1156 (post-full-analysis), 1190 (export-choice), 1345 (post-export), 1422 (post-help), 1618 (post-SSL), 1662 (menu choice), 1668 (clear-results confirm).
- **Local notes:** Same shape as F6 of scripts-driver_integrity_scan.md and F6 of scripts-mcafee_removal_tool.md — all 14 `Read-Host` calls will deadlock the worker under SYSTEM-context RMM. There is no `[Environment]::UserInteractive` gate, no `-NonInteractive` switch, and no `param()` surface that would let an automated caller pass the domain in. Most damaging: line 915 (`$confirm = Read-Host "Continue? [Y/n]"` inside `Get-FullDomainAnalysis`) — the only safety gate for the most expensive operation, with no way to bypass non-interactively. Pair with F6 in P4 to add a `[CmdletBinding()] param([string]$Domain, [switch]$NonInteractive)` block on the script: when `-NonInteractive` is set, all `Read-Host` calls become guarded `if ([Environment]::UserInteractive) { ... }` no-ops and the menu loop is replaced by a single `Get-FullDomainAnalysis -Domain $Domain` call. Defer to P4 unless an actual RMM hang report comes in.
- **Target phase:** P4

### F9 — `Get-SSLCertificate` lacks `try`/`finally` around `TcpClient`/`SslStream` resource disposal
- **Severity:** info
- **Category:** correctness / resource hygiene
- **Location:** scripts/domain_dns_analyzer.ps1:1457–1468 (resource acquisition + close), inside the outer `try { ... } catch { ... }` at lines 1452–1615.
- **Current:**
  ```powershell
  $tcpClient = New-Object System.Net.Sockets.TcpClient
  $tcpClient.Connect($Domain, $port)
  $sslStream = New-Object System.Net.Security.SslStream($tcpClient.GetStream(), $false, { $true })
  $sslStream.AuthenticateAsClient($Domain)     # <-- can throw
  ...
  $sslStream.Close()                            # <-- skipped on throw above
  $tcpClient.Close()                            # <-- skipped on throw above
  ```
- **Local notes:** If `AuthenticateAsClient` throws (handshake failure, untrusted CA, certificate name mismatch, TLS version mismatch), control jumps to the outer `catch` (line 1604) and the `TcpClient`/`SslStream` objects are never `Close()`-d. They will be GC'd eventually, but until then the TCP socket stays in `CLOSE_WAIT` and the file descriptor is held. Low-impact in a short-lived interactive run, but a real leak under any future automation that calls this in a loop. Wrap the open-handshake-close block in `try { ... } finally { if ($sslStream) { $sslStream.Dispose() }; if ($tcpClient) { $tcpClient.Dispose() } }`. The certificate-validation callback `{ $true }` on line 1460 also unconditionally trusts every cert — that's actually correct here (the whole point is to inspect even untrusted/expired certs without raising), but the callback should carry a comment noting the deliberate skip. Pair with the F3 `Get-RemoteCertificate` extract.
- **Target phase:** P4 (fold into the F3 extract)

### F10 — `cert2.PublicKey.Key.KeySize` may throw on ECDSA certificates; ECDSA-key-size threshold check is incorrect
- **Severity:** info
- **Category:** correctness (note only — confirm before changing)
- **Location:** scripts/domain_dns_analyzer.ps1:1535 (`$keySize = $cert2.PublicKey.Key.KeySize`) and the surrounding `if ($keySize -ge 2048)` colour-coding on line 1536.
- **Local notes:** `X509Certificate2.PublicKey.Key` returns an `AsymmetricAlgorithm`, but the property is **deprecated** in .NET Framework 4.6+ and removed in .NET 5+. For ECDSA-signed certs (increasingly common — most modern CAs default to ECDSA P-256), accessing `.Key` returns `$null` in some PowerShell runtimes, and `.KeySize` on `$null` will throw a `RuntimeException`. The outer `catch` (line 1604) will catch this and surface "SSL certificate check failed: ..." instead of showing the rest of the certificate details. Worth a defensive `try { $keySize = $cert2.PublicKey.Key.KeySize } catch { $keySize = 'Unknown (ECDSA?)' }` block, or migrate to the .NET-5-safe `$cert2.GetRSAPublicKey()?.KeySize ?? $cert2.GetECDsaPublicKey()?.KeySize ?? 0` form. Independently of the throw issue: the `if ($keySize -ge 2048)` "Weak key size" branch is *incorrect for ECDSA* — 256-bit ECDSA is roughly equivalent in strength to 3072-bit RSA, but the current code flags ECDSA P-256 (key size 256) as weak. Distinguish RSA vs ECDSA when applying the threshold (RSA: 2048-bit minimum; ECDSA: 256-bit minimum). Pair with the F3 extract.
- **Target phase:** P4 (fold into the F3 `Get-SSLCertificate` / `Get-CertificateSans` extract)

## Out-of-scope notes
- Banner block (lines 1–32, ~25 lines of `# === / Coded by / IMPORTANT DISCLAIMER`) matches C11 cross-cutting cleanup; covered there.
- The `Initialize-WhoisTool` function (lines 127–212) is structurally well-organised — single responsibility (locate-or-download), correct use of `$Script:WhoisToolChecked` short-circuit, TLS 1.2 forced before `Invoke-WebRequest`, Authenticode signature check on download. The two issues (placeholder hash, missing Authenticode on the vendored path) are covered in F5. After the F5 fix, this function is the model template for the future `Get-SouliTEKVendorBinary` helper if one is added in P4.
- The `$Script:DKIMSelectors` constant (lines 56–67, 10 common DKIM selector names) is a sensible default list — covers Google Workspace (`google`), generic single-selector setups (`default`, `selector1`, `selector2`, `s1`, `s2`), Mailchimp (`k1`), and generic mail-platform selectors (`dkim`, `mail`, `email`). No change needed.
- The `Add-AnalysisResult` accumulator pattern (lines 101–118) using `[System.Collections.ArrayList]::new()` at script-load (line 51) is correct PS-5.1+-compatible code. The `$null = $Script:AnalysisResults.Add(...)` form on line 110 is the idiomatic way to suppress `ArrayList.Add`'s `int` return value. No change needed.
- The WHOIS-text regex parser in `Get-DomainWhois` (lines 277–340) handles the 4 major registrar response formats (IANA-style `Registrar:`, `registrar:`, `Registrar Name:`, plus Russian-TLD `paid-till:` for `.ru` and German-TLD `changed:` for `.de`). The cascading `elseif` chain is verbose but readable and handles a real diversity of upstream WHOIS server formats. The F3 extract candidate (`ConvertFrom-WhoisText`) should preserve all of these patterns verbatim.
- The HTML report template in `Export-AnalysisResults` (lines 1259–1320) embeds CSS as a `style` block in the document head. The styles are sensible (gradient header, card-based record groups, status-class color coding) and the output renders cleanly in modern browsers. The F3 extract candidate should externalise this to `templates/domain-report.html` for maintainability but the rendered output should remain byte-identical.
- The `[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12` line (line 177) is correct for PS 5.1 on older Windows builds where TLS 1.2 is not the default. Under PS 7+ this is a no-op (TLS 1.2/1.3 is negotiated automatically). Safe to leave as-is.
- The `Resolve-DnsName -DnsOnly` switch (used at lines 420, 534, 648, 709, 751, 786, 1011, 1033, 1085, 1107, 1124) correctly bypasses the local Hosts file and LLMNR — the right choice for a domain-analysis tool that should reflect authoritative DNS, not local overrides. No change needed.
- The trailing 1 blank line at the end of the file (line 1722) is harmless.
