# Audit — Install-SouliTEK.ps1 + hosting/api proxies

## Inventory
| Item | Value |
|---|---|
| Path           | Install-SouliTEK.ps1 (+ api/install.js, hosting/install-proxy.php, hosting/.htaccess-redirect) |
| LOC            | 448 (Install-SouliTEK.ps1) + 76 (api/install.js) + 91 (hosting/install-proxy.php) |
| Functions      | 7 (PS: `Write-Step`, `Write-Success`, `Write-Error-Custom`, `Write-Warning-Custom`, `Get-EssentialFilesFilter`, `Test-FileIsEssential`, `Copy-EssentialFiles`) + 1 JS handler + 1 PHP `getClientIP` |
| `#Requires`    | `#Requires -Version 5.1` |
| Admin-required | partial — installer writes to `C:\SouliTEK` by default (requires admin to write under `C:\`) but only warns rather than refusing to run; the `Read-Host` "launch now?" prompt and `Start-Process powershell.exe` step are user-context, while removal of an existing install via `Remove-Item -Recurse -Force $InstallPath` may also require admin depending on prior install ACL |
| Last touched   | 81fc4a0 — 2026-04-18 |
| Modernization grade | B (security trio + hash-check infrastructure exists but is opt-in by default — C12 keeps it from A) |

## Summary

The installer is the single entry point users execute via `iwr | iex`, so its integrity is the foundation of every other security control in the repo. Hash verification infrastructure already exists (`-ExpectedZipHash` parameter + inline `Get-FileHash`/compare logic at lines 291–299), but the default-empty string makes the check opt-in and the entire `iwr | iex` flow skips it; closing that gap is C12 and gates the whole P6 phase. The two proxies (Vercel `api/install.js` and shared-hosting `hosting/install-proxy.php`) are thin pass-throughs to the same hard-coded GitHub raw URL — neither accepts attacker-controllable input that influences which file is fetched, so traditional path-traversal / redirect-injection / response-splitting attacks aren't exploitable, but neither implements rate-limiting and the PHP variant uses `@file_get_contents` which silently swallows network errors. The installer's four custom `Write-*` helpers (lines 29–47) are NOT a C1 violation — the installer runs before `modules/SouliTEK-Common.ps1` is downloaded, so it cannot call `Write-Ui`; this constraint is documented here so future audits / the P1 sweep don't try to migrate them. Other notable gaps: zero Pester coverage (C7), the `Step` numbering in user-facing output is mis-ordered (`Step 5 → Step 4 → Step 5`) due to a copy-paste re-number, the `.htaccess-redirect` file references a wrong repo name (`Soulitek-AIO` instead of `Soulitek-All-In-One-Scripts`), and the desktop shortcut hard-codes `-ExecutionPolicy RemoteSigned` which weakens the policy on machines that ship locked down. Recommended phase entry order: **P0** (fix `.htaccess-redirect` repo name + Step numbering — both trivial), then **P6** (C12 hash-verification gap and rate-limit on proxies), then **P5** (smoke-only Pester coverage).

## Findings

### F1 — Hash verification skipped when -ExpectedZipHash is empty (see C12)
- **Severity:** high
- **Category:** security
- **Location:** Install-SouliTEK.ps1:22 (param block: `[string]$ExpectedZipHash = ""`), lines 291–299 (conditional skip: `if ($ExpectedZipHash -ne "")`).
- **Reference:** [C12](00-cross-cutting.md#c12--installer-downloads-zip-without-mandatory-hash-verification-by-default)
- **Local notes:** Current behaviour: `iwr -useb get.soulitek.co.il | iex` invokes the installer with `$ExpectedZipHash = ""` (default), so the entire `if ($ExpectedZipHash -ne "")` block at lines 291–299 is skipped and the ZIP is trusted on the basis of TLS + GitHub-account integrity alone. The mismatch branch (lines 293–297) is correctly fail-closed (deletes the ZIP and exits 1) — only the *default* is wrong. Note also the case-folding compare on line 293 (`$actualHash.ToUpper() -ne $ExpectedZipHash.ToUpper()`) is correct; no change needed there. Per C12, P6 should fetch a signed `manifest.json` from a fixed URL and require the hash, with a new `-SkipHashCheck` switch that logs a warning when bypassed.
- **Target phase:** P6

### F2 — Installer's custom output helpers (Write-Step / Write-Success / Write-Error-Custom / Write-Warning-Custom)
- **Severity:** info
- **Category:** output-style
- **Location:** Install-SouliTEK.ps1:29–47 (the four helper function definitions).
- **Local notes:** These are NOT a C1 violation. The installer runs BEFORE `modules/SouliTEK-Common.ps1` exists on disk (the module is one of the files it downloads), so it cannot call `Write-Ui`. The helpers MUST stay. Documenting the constraint here so future audits / P1 sweeps don't try to migrate them. The function-name suffix `-Custom` on `Write-Error-Custom` / `Write-Warning-Custom` is to avoid shadowing the built-in cmdlets `Write-Error` / `Write-Warning`; this is correct. No change recommended.
- **Target phase:** — (no action)

### F3 — api/install.js (Vercel proxy) — minor cleanups, no exploitable issues
- **Severity:** low
- **Category:** security / output-style
- **Location:** api/install.js (entire file, 73 lines).
- **Local notes:** The function is a thin pass-through: it `fetch`es a hard-coded `https://raw.githubusercontent.com/Soulitek/Soulitek-All-In-One-Scripts/main/Install-SouliTEK.ps1` URL (line 16) and pipes the response body back to the caller. Strengths: (1) cache headers are correct for an installer endpoint — `Cache-Control: no-cache, no-store, must-revalidate` + `Pragma: no-cache` + `Expires: 0` (lines 43–45) prevent intermediate caches from pinning an old/compromised installer; (2) `X-Content-Type-Options: nosniff` is set (line 46); (3) content-validation on line 35 (`script.includes('SouliTEK') && script.includes('PowerShell')`) gives a minimal sanity check that GitHub didn't serve garbage / a 404 page with status 200; (4) no CORS header is set (good for an installer — there's no legitimate cross-origin browser use case). Concerns: (1) on the error path (line 59 starts the `res.status(500).send(...)` heredoc; the unsafe interpolations are at lines 61, 69, 72) the function echoes `${error.message}` into a PowerShell heredoc that ends up being `iex`'d by the caller — if the error message ever contained PowerShell metacharacters (it won't in practice because the error originates from `node-fetch`, but the principle is wrong), the script would execute attacker-controllable content. Recommend HTML/PS-escaping or stripping non-alphanumeric chars before interpolation, or just emitting a generic message and logging the real error server-side. (2) `console.log` of `[${new Date().toISOString()}] Fetching installer from GitHub...` (line 18) and the byte count on line 39 is harmless but contradicts the "Privacy-focused: No user data logging" comment on line 49 — clarify the comment scope ("no client IP / no user-agent" rather than "no logging"). (3) No rate-limit / abuse mitigation at the Vercel layer (relies on Vercel platform limits). Note that since the upstream URL is hard-coded, there is no redirect-injection / SSRF surface to evaluate.
- **Target phase:** P6 (group with hosting/install-proxy.php hardening)

### F4 — hosting/install-proxy.php (PHP proxy) — silent failures + no rate-limit
- **Severity:** med
- **Category:** security / error-handling
- **Location:** hosting/install-proxy.php (entire file, 81 lines). Specific lines: 78 (`@file_get_contents` with error suppression), 31–54 (`getClientIP` function — currently unused because `$enableLogging = false`), 26 (`Access-Control-Allow-Origin: *`).
- **Local notes:** Like the Vercel proxy, this is a thin pass-through to a hard-coded GitHub raw URL (line 20). No attacker-controllable input influences the fetch URL — no path-traversal / SSRF / redirect-injection surface to evaluate. Strengths: (1) `$enableLogging = false` (line 22) is the privacy-correct default and matches the comment on line 14; (2) error path (lines 81–84) emits `http_response_code(502)` and a PowerShell-comment-formatted message, so a failed proxy won't be silently interpreted as a valid (empty) script; (3) `Content-Type: text/plain` (line 25) is correct. Concerns: (1) **silent error swallowing** — `@file_get_contents` (line 78) with the `@` operator suppresses warnings; the `$script === false` check (line 81) catches outright failure but a partial / corrupted read would pass through with a 200 status. Replace with a try/catch around `file_get_contents` with `$http_response_header` inspection, or migrate to `curl` with proper error handling. (2) **No rate-limit** — the CHANGELOG planned-items list already flags this; on shared hosting, install-endpoint abuse is a real concern. Recommend a simple IP+time bucket in APCu or a flat file (the `getClientIP` helper at lines 31–54 is already written and would be reused). (3) **CORS wide-open** — `Access-Control-Allow-Origin: *` (line 26) is unnecessary for a PowerShell-consumed endpoint; remove it (no browser legitimately needs to fetch this cross-origin). (4) `User-Agent: 'SouliTEK-Proxy/1.0'` (line 74) is OK but consider including the source domain so GitHub abuse reports are routable. (5) The `getClientIP` function (lines 31–54) correctly validates with `filter_var(..., FILTER_VALIDATE_IP)` and trusts `HTTP_CF_CONNECTING_IP` first — fine if behind Cloudflare, but if the site isn't behind Cloudflare an attacker can spoof that header to any value; add a Cloudflare-IP-range check before trusting CF headers, or move CF detection logic behind a config flag.
- **Target phase:** P6

### F5 — Zero test coverage (see C7)
- **Severity:** med
- **Category:** tests
- **Location:** Install-SouliTEK.ps1 (entire file), api/install.js (entire file), hosting/install-proxy.php (entire file).
- **Reference:** [C7](00-cross-cutting.md#c7--pester-coverage-gap)
- **Local notes:** No Pester / Jest / PHPUnit coverage exists for any of the three. End-to-end installer testing is hard (real network + filesystem side effects) and not worth automating. **Smoke-only** scope for P5: (1) load the installer with `. .\Install-SouliTEK.ps1` after extracting the `param(...)` block into a separately testable file (or use `Get-Command -CommandType ExternalScript` to inspect parameters without executing the script body), and assert that `-Silent`, `-ExpectedZipHash`, `-InstallPath`, `-RepoOwner`, `-RepoName`, `-Branch` all exist with the expected types; (2) unit-test `Test-FileIsEssential` (lines 71–145) against the patterns in `Get-EssentialFilesFilter` — this is a pure function with no I/O, so it deserves a small Pester block covering exact match, directory wildcard, file-extension wildcard, and traversal-like inputs (e.g. `..\evil.ps1` should return `$false`). (3) For the JS proxy: a Jest test that mocks `global.fetch` and asserts headers + error path. Skip the PHP proxy unless PHPUnit is already in the toolchain.
- **Target phase:** P5

### F6 — Step numbering inconsistency in user-facing output
- **Severity:** low
- **Category:** output-style
- **Location:** Install-SouliTEK.ps1 — user-visible strings: line 271 (`"Step 1: Preparing..."`), 280 (`Step 2`), 310 (`Step 3`), 332 (`Step 4`), 348 (`Step 5`), 371 (`Step 6`), 392 (`Step 7`). Source comments: lines 270 (`Step 1`), 279 (`Step 2`), 309 (`Step 3`), 323 (`Step 4: Find the extracted folder` — has NO matching user-visible string), 331 (`Step 5`), 347 (`Step 6`), 370 (`Step 7`), 391 (`Step 8`).
- **Local notes:** The mechanism: the source has 8 `# Step N:` comments labelling 8 sub-steps, but only 7 of them emit a user-visible `Write-Step "Step N:"`. The "Find the extracted folder" sub-step (comment `Step 4` at line 323) is silent to the user, so the user-visible numbering goes 1→2→3→4→5→6→7 while the source comments go 1→2→3→4→5→6→7→8 — and the comment for the *fourth* user-visible step is `Step 5`. Pure cosmetic — comments and user-visible step labels drifted apart over time. Either drop the `Step 4` source comment (renumber comments to 1..7 matching user output) or add a user-visible `Step 4: Locating extracted folder` print before line 323. Recommend the former (less churn, doesn't change the user-facing UX). 30-minute fix.
- **Target phase:** P0

### F7 — hosting/.htaccess-redirect points at wrong GitHub repo name
- **Severity:** med
- **Category:** security / correctness
- **Location:** hosting/.htaccess-redirect:20, 23 — `RewriteRule ^$ https://raw.githubusercontent.com/Soulitek/Soulitek-AIO/main/Install-SouliTEK.ps1 [L,R=301]`.
- **Local notes:** The repo name in both rewrite rules is `Soulitek-AIO`, but the actual GitHub repo is `Soulitek-All-In-One-Scripts` (confirmed by `Install-SouliTEK.ps1:19` default `$RepoName = "Soulitek-All-In-One-Scripts"` and `api/install.js:16` / `hosting/install-proxy.php:20` both using the full name). If anyone deploys this `.htaccess` as documented in `hosting/README.md` (option A), the redirect target will 404 and `iwr -useb get.soulitek.co.il | iex` will fail (best case) or — worse — if an attacker ever registered the `Soulitek-AIO` repo name on GitHub, they could serve a malicious installer to anyone using that proxy. **This is a supply-chain risk if any deployment of the `.htaccess` exists today**. Fix: update both `RewriteRule` targets to use `Soulitek-All-In-One-Scripts`. Verify no active deployment is using the old path; if there is, the deployment must be updated atomically with the file change.
- **Target phase:** P0

### F8 — Desktop shortcut forces `-ExecutionPolicy RemoteSigned`
- **Severity:** low
- **Category:** security
- **Location:** Install-SouliTEK.ps1:380 (`$Shortcut.Arguments = "-NoProfile -ExecutionPolicy RemoteSigned -File `"$launcherPath`""`), and line 417 (same for the post-install launch).
- **Local notes:** The shortcut explicitly sets `-ExecutionPolicy RemoteSigned`. On machines configured with a stricter machine-level policy (`AllSigned`, `Restricted`) via Group Policy, this argument is *not* honoured — Group Policy overrides per-invocation `-ExecutionPolicy`. But on machines where the default policy is the typical `Restricted` and the user hasn't lowered it, this argument quietly weakens the policy for this one invocation. The launcher script itself is shipped unsigned, so `AllSigned` would block it anyway — `RemoteSigned` is the minimum that works. Better long-term: sign `SouliTEK-Launcher.ps1` (and ideally the installer) with an Authenticode certificate so the shortcut can use `-ExecutionPolicy AllSigned`. Note this for P6 alongside the C12 hash-verification work.
- **Target phase:** P6

### F9 — `Read-Host "launch now?"` prompt blocks in non-interactive contexts
- **Severity:** info
- **Category:** error-handling
- **Location:** Install-SouliTEK.ps1:413 (`$launch = Read-Host "Would you like to launch SouliTEK Launcher now? (Y/N) [Y]"`), inside `if (-not $Silent)` block at 412.
- **Local notes:** Correctly gated behind `-not $Silent` (line 412), so RMM / SYSTEM-context callers that pass `-Silent` are unaffected. The prompt-default behaviour ("Y on empty input") was a deliberate fix in commit 81fc4a0. No issue here; documenting the safety gate so future modifications don't accidentally remove it.
- **Target phase:** — (no action)

### F10 — `Expand-Archive` extracts to `$env:TEMP\SouliTEK-Install` without path-traversal validation
- **Severity:** info
- **Category:** security
- **Location:** Install-SouliTEK.ps1:265 (`$tempDir = Join-Path $env:TEMP "SouliTEK-Install"`), 312 (`Expand-Archive -Path $zipFile -DestinationPath $extractPath -Force`).
- **Local notes:** `Expand-Archive` on PS 5.1+ does sanitize zip-slip-style traversal paths internally (rejects entries with `..` segments that escape the destination root), so direct exploitation via a malicious ZIP is mitigated by the cmdlet. The downstream `Copy-EssentialFiles` (lines 147–240) calculates `$relativePath = $file.FullName.Substring($SourcePath.Length + 1)` (line 178) which would be vulnerable to a symlink-based escape if `Expand-Archive` ever extracted a symlink that pointed outside `$extractPath` — but `Expand-Archive` on Windows doesn't create symlinks from ZIP entries (they're extracted as regular files). The whitelist enforcement in `Test-FileIsEssential` (lines 71–145) further limits which files are copied — even if a malicious ZIP got something extracted, it would have to match `launcher\*`, `modules\*.ps1`, `scripts\*.ps1`, or one of the explicit filenames to be copied to `$InstallPath`. Net: low residual risk. Mention only as defense-in-depth: P6 could optionally add an explicit `Test-SafeFilePath -BasePath $extractPath -Path $file.FullName` check inside the `Copy-EssentialFiles` loop using the module's existing helper (after the module exists on disk — chicken-and-egg here means the check would have to be duplicated inline in the installer).
- **Target phase:** P6 (optional defense-in-depth)

### F11 — `Unblock-File` swept across all extracted `.ps1` (see C4)
- **Severity:** info
- **Category:** error-handling
- **Location:** Install-SouliTEK.ps1:315–316 (`Get-ChildItem -Path $extractPath -Filter "*.ps1" -Recurse | ForEach-Object { Unblock-File -Path $_.FullName -ErrorAction SilentlyContinue }`).
- **Reference:** [C4](00-cross-cutting.md#c4----erroraction-silentlycontinue-swallowing-failures) — triage tag **A** (legitimate cleanup: "remove MOTW so RemoteSigned allows the scripts; don't care if Unblock-File fails on a file that wasn't blocked").
- **Local notes:** Tag A. Add a `# safe: cleanup` comment when C4 is applied in P2. No behaviour change.
- **Target phase:** P2

### F12 — Hard-coded `RepoOwner` / `RepoName` / `Branch` defaults — trust anchor analysis
- **Severity:** info
- **Category:** security
- **Location:** Install-SouliTEK.ps1:18–20 (param defaults).
- **Local notes:** The defaults (`Soulitek` / `Soulitek-All-In-One-Scripts` / `main`) ARE the trust anchor for the entire `iwr | iex` model — the installer trusts whatever GitHub serves at that path. This is intentional and correct: GitHub account control + branch protection IS the security boundary, and exposing them as parameters lets advanced users redirect to a fork for testing. The risk is not that the values are hard-coded but that anyone with write access to the `main` branch can update the installer. Mitigations already in place: GitHub branch protection (assumed — verify with `gh api repos/Soulitek/Soulitek-All-In-One-Scripts/branches/main/protection` once accessible), 2FA on the Soulitek account, and (post-C12) signed manifest. Net: no finding. Documenting here so future audits don't flag this as a hard-coded-URL smell.
- **Target phase:** — (no action)

### F13 — Cleanup-on-error block (catch handler) swallows cleanup errors silently (see C4)
- **Severity:** low
- **Category:** error-handling
- **Location:** Install-SouliTEK.ps1:437–443 — `if (Test-Path $tempDir) { try { Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue } catch { # Ignore cleanup errors } }`.
- **Reference:** [C4](00-cross-cutting.md#c4----erroraction-silentlycontinue-swallowing-failures) — triage tag **A** (legitimate cleanup: nested inside an outer `catch` that's already reporting the real error; cleanup failure is non-critical).
- **Local notes:** Tag A. Add `# safe: cleanup` comment when C4 is applied in P2. Note also lines 295 and 398 which similarly use `-ErrorAction SilentlyContinue` on `Remove-Item` cleanup — also tag A.
- **Target phase:** P2

## Out-of-scope notes
- `hosting/.htaccess-redirect` lines 36–43 (`Options -Indexes` + `<Files ".htaccess"> Deny from all`) are standard Apache hardening — correct, no findings.
- `hosting/README.md` documents the proxy setup; out of audit scope. (One minor doc bug: line 145 example log entry references `2025-10-23` but `$enableLogging = false` per the PHP file, so the log file is never written by the default config; ignore.)
- The four `Write-Step` / `Write-Success` / `Write-Error-Custom` / `Write-Warning-Custom` helpers (lines 29–47) — see F2: cannot be migrated to `Write-Ui` because the installer runs before the common module is downloaded. Constraint documented; no future migration.
- The hard-coded `RepoOwner` / `RepoName` / `Branch` defaults (lines 18–20) — see F12: this is the trust anchor by design. Not a hard-coded-URL smell.
- `Get-EssentialFilesFilter` (lines 53–69) is a clean enum-style helper — explicit whitelist, no globs that could over-match. The list is currently the source of truth for what ships to a user's machine; if a new tool is added under `tools/` (e.g. another `.exe`), the entry must be added here or it will be silently skipped. Worth mentioning in `CONTRIBUTING.md` but not a finding.
- `Test-FileIsEssential` (lines 71–145) has three fallback `elseif` branches inside `Copy-EssentialFiles` (lines 191–201) that re-check for `scripts\*.ps1` / `modules\*.ps1` / `launcher\*` after the primary pattern-match returned `$false`. This is defensive-in-depth in case the pattern matcher misses a separator variant — keep, but the dual logic makes the whitelist harder to reason about. Consolidate into the pattern matcher in P4 when the rest of the installer is touched for C12.
