# Tools Directory

This directory contains external tools and executables used by SouliTEK scripts.

## McAfee Removal Tool (MCPR)

**File:** `MCPR.exe`

**Used by:** `scripts/mcafee_removal_tool.ps1`

**Description:** McAfee Consumer Product Removal tool for complete removal of McAfee products from Windows systems.

**How to add:**
1. Download MCPR.exe from McAfee support
2. Place the file in this directory (`tools/MCPR.exe`)
3. Run `scripts/mcafee_removal_tool.ps1` as Administrator

**Note:** This file is treated as binary in Git (see `.gitattributes`).

