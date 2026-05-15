# SouliTEK Repo Audits

This folder contains the modernization audit produced from
[`docs/superpowers/specs/2026-05-15-modernize-roadmap-design.md`](../superpowers/specs/2026-05-15-modernize-roadmap-design.md).

## Reading order

1. [`00-cross-cutting.md`](00-cross-cutting.md) — Canonical list of cross-cutting findings (C1–C14). Per-file audits cite these IDs rather than duplicating.
2. [`01-modules-SouliTEK-Common.md`](01-modules-SouliTEK-Common.md) — Common module audit.
3. [`02-Install-SouliTEK.md`](02-Install-SouliTEK.md) — Installer + hosting/api proxies audit.
4. Per-script audits below.

## Per-script audits

| Script | Audit | Predicted grade |
|---|---|---|
| `scripts/1-click_pc_install.ps1`           | [audit](scripts-1-click_pc_install.md)           | C |
| `scripts/battery_report_generator.ps1`     | [audit](scripts-battery_report_generator.md)     | B |
| `scripts/bitlocker_status_report.ps1`      | [audit](scripts-bitlocker_status_report.md)      | A |
| `scripts/browser_plugin_checker.ps1`       | [audit](scripts-browser_plugin_checker.md)       | B |
| `scripts/bsod_history_scanner.ps1`         | [audit](scripts-bsod_history_scanner.md)         | B |
| `scripts/create_system_restore_point.ps1`  | [audit](scripts-create_system_restore_point.md)  | C |
| `scripts/disk_usage_analyzer.ps1`          | [audit](scripts-disk_usage_analyzer.md)          | C |
| `scripts/domain_dns_analyzer.ps1`          | [audit](scripts-domain_dns_analyzer.md)          | C |
| `scripts/driver_integrity_scan.ps1`        | [audit](scripts-driver_integrity_scan.md)        | D |
| `scripts/essential_tweaks.ps1`             | [audit](scripts-essential_tweaks.md)             | D |
| `scripts/EventLogAnalyzer.ps1`             | [audit](scripts-EventLogAnalyzer.md)             | D |
| `scripts/exchange_calendar_permissions_audit.ps1` | [audit](scripts-exchange_calendar_permissions_audit.md) | B |
| `scripts/FindPST.ps1`                      | [audit](scripts-FindPST.md)                      | B |
| `scripts/license_expiration_checker.ps1`   | [audit](scripts-license_expiration_checker.md)   | C |
| `scripts/local_admin_checker.ps1`          | [audit](scripts-local_admin_checker.md)          | B |
| `scripts/m365_exchange_online.ps1`         | [audit](scripts-m365_exchange_online.md)         | C |
| `scripts/m365_user_list.ps1`               | [audit](scripts-m365_user_list.md)               | C |
| `scripts/mcafee_removal_tool.ps1`          | [audit](scripts-mcafee_removal_tool.md)          | D |
| `scripts/network_configuration_tool.ps1`   | [audit](scripts-network_configuration_tool.md)   | C |
| `scripts/network_test_tool.ps1`            | [audit](scripts-network_test_tool.md)            | B |
| `scripts/onedrive_status_checker.ps1`      | [audit](scripts-onedrive_status_checker.md)      | B |
| `scripts/printer_spooler_fix.ps1`          | [audit](scripts-printer_spooler_fix.md)          | D |
| `scripts/product_key_retriever.ps1`        | [audit](scripts-product_key_retriever.md)        | D |
| `scripts/ram_slot_utilization_report.ps1`  | [audit](scripts-ram_slot_utilization_report.md)  | C |
| `scripts/sharepoint_site_inventory.ps1`    | [audit](scripts-sharepoint_site_inventory.md)    | B |
| `scripts/software_updater.ps1`             | [audit](scripts-software_updater.md)             | B |
| `scripts/SouliTEK-Choco-Installer.ps1`     | [audit](scripts-SouliTEK-Choco-Installer.md)     | B |
| `scripts/SouliTEK-Softwares-Installer.ps1` | [audit](scripts-SouliTEK-Softwares-Installer.md) | B |
| `scripts/startup_boot_analyzer.ps1`        | [audit](scripts-startup_boot_analyzer.md)        | C |
| `scripts/storage_health_monitor.ps1`       | [audit](scripts-storage_health_monitor.md)       | B |
| `scripts/temp_removal_disk_cleanup.ps1`    | [audit](scripts-temp_removal_disk_cleanup.md)    | D |
| `scripts/usb_device_log.ps1`               | [audit](scripts-usb_device_log.md)               | B |
| `scripts/virustotal_checker.ps1`           | [audit](scripts-virustotal_checker.md)           | A |
| `scripts/wifi_monitor.ps1`                 | [audit](scripts-wifi_monitor.md)                 | B |
| `scripts/wifi_password_viewer.ps1`         | [audit](scripts-wifi_password_viewer.md)         | B |
| `scripts/win11_debloat.ps1`                | [audit](scripts-win11_debloat.md)                | D |

Grades are predictions; each audit confirms or revises in its Inventory section.
