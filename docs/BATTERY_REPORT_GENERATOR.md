# Battery Report Generator

## Overview
- Generates quick and detailed battery reports, sleep study summaries, energy diagnostics, and consolidated report bundles.
- Reuses common SouliTEK helpers for consistent banners, logging, and console prompts.
- Runs without elevation for read-only tasks; escalates only when required for energy diagnostics.

## Permission Requirements
- `Quick Battery Report`, `Detailed Battery Report`, `Battery Health Check`, and `Sleep Study Report` run under standard user privileges.
- `Energy Efficiency Report` requires an elevated PowerShell session because `powercfg /energy` demands administrative rights.
- `Generate All Reports` runs every report in sequence and automatically skips the energy phase when elevation is unavailable while still producing the remaining assets.

## Error Handling
- Wraps `Get-CimInstance Win32_Battery` in structured `try`/`catch` logic to surface actionable errors when WMI queries fail.
- Centralizes all `powercfg` invocations through `Invoke-SouliTEKPowerCfg` to capture exit codes, emit detailed diagnostics, and verify that output files are created.
- Cleans up temporary artifacts (such as the XML battery snapshot) even when downstream parsing fails.

## User Experience Improvements
- Uses `Show-SouliTEKHeader` and formatted logging helpers to reduce repetitive `Write-Host` blocks while keeping the guided UI intact.
- Introduces `Wait-SouliTEKReturnToMenu` so each action returns users to the menu without duplicated prompt logic.
- Sleep Study failures now state that Modern Standby support is required instead of silently failing.

## Operational Notes
- Reports are written to the desktop (or a timestamped folder on the desktop for bundled runs).
- Successful report generation automatically opens the created file/folder; failures leave the console open with detailed diagnostics for follow-up.
- When the energy phase is skipped due to insufficient privileges, users can re-run just that feature from an elevated session without repeating the full workflow.





