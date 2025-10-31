## Microsoft 365 MFA Audit Tool

This tool audits Microsoft 365 MFA (multi-factor authentication) across all users and produces a clear report:

- Who has MFA enabled
- Who does not
- Whether MFA is enforced by policy (Security Defaults / Conditional Access)
- Total counts and percentages
- Optional weekly email report

### Requirements

- PowerShell 5.1+
- One of the following:
  - MSOnline module (preferred for per-user MFA details)
  - Microsoft Graph PowerShell SDK (for tenant policy checks)
- Permissions:
  - MSOnline: Global Administrator/Privileged Role Admin/Global Reader (connect with `Connect-MsolService`)
  - Graph: consent to scopes `User.Read.All` and `Policy.Read.All`

### Installation

No installation required. The script is part of the repository:

`scripts/m365_mfa_audit.ps1`

### Usage

Basic run (outputs to Desktop):

```powershell
.\scripts\m365_mfa_audit.ps1
```

Specify output folder:

```powershell
.\scripts\m365_mfa_audit.ps1 -OutputFolder "C:\Reports"
```

Send email report (HTML + CSV) via SMTP:

```powershell
$cred = Get-Credential  # SMTP account
.\scripts\m365_mfa_audit.ps1 -EmailReport -To "admin@contoso.com" -From "reports@contoso.com" -SmtpServer "smtp.office365.com" -SmtpPort 587 -UseSsl -Credential $cred
```

Register a weekly scheduled task (runs every Sunday 06:00, emails report):

```powershell
$cred = Get-Credential
.\scripts\m365_mfa_audit.ps1 -EmailReport -To "admin@contoso.com" -From "reports@contoso.com" -SmtpServer "smtp.office365.com" -Credential $cred -ScheduleWeekly -ScheduleDay Sunday -ScheduleTime "06:00"
```

### What the Script Checks

- Per-user MFA:
  - Uses MSOnline `Get-MsolUser` to read `StrongAuthenticationRequirements` and `StrongAuthenticationMethods`.
  - Determines if MFA is enabled and whether it is per-user enforced.
- Tenant policy MFA:
  - Uses Graph (if available) to read `Security Defaults` and Conditional Access policies that require MFA.
  - Lists policy names and whether any active (enabled) CA policies require MFA.

Notes:
- Conditional Access evaluation is reported at tenant level (presence of enabled policies requiring MFA). Determining exact per-user CA enforcement across group assignments is out of scope for this script.
- If MSOnline is not installed or access is denied, the per-user MFA columns may show limited detail; install MSOnline for most accurate user results.

### Outputs

- Console summary
- CSV: `M365-MFA-Users-<timestamp>.csv`
- HTML: `M365-MFA-Report-<timestamp>.html`

### Parameters

- `-OutputFolder <path>`: Where to save CSV/HTML (default: Desktop)
- `-EmailReport`: Send HTML report (and CSV) via SMTP
- `-To <email>` / `-From <email>` / `-SmtpServer <host>` / `-SmtpPort <int>` / `-UseSsl` / `-Credential <PSCredential>`
- `-ScheduleWeekly`: Create a weekly Scheduled Task to run the report
- `-ScheduleDay <Sun..Sat>` / `-ScheduleTime "HH:mm"`

### Sample Output (Console)

```
Tenant Policy Status:
Security Defaults                    : Disabled
Conditional Access requires MFA      : Yes

User MFA Summary:
Total Users                          : 142
MFA Enabled                          : 127 (89.44%)
MFA Disabled                         : 15 (10.56%)

Saved CSV: C:\Users\<you>\Desktop\M365-MFA-Users-20251030-0630.csv
Saved HTML: C:\Users\<you>\Desktop\M365-MFA-Report-20251030-0630.html
```

### Troubleshooting

- Install MSOnline: `Install-Module MSOnline -Scope CurrentUser`
- Install Graph: `Install-Module Microsoft.Graph -Scope CurrentUser`
- Graph consent: First run prompts for consent; sign in with adequate privileges.
- SMTP fails: Ensure SMTP account allowed to send as `-From` and server allows client SMTP submission.

### Security

- Read-only queries; no changes to tenant configuration.
- Credentials are used only for SMTP sending.


