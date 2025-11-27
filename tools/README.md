# Tools Directory

This directory contains external tools and executables used by SouliTEK scripts.

## Overview

External tools and binaries required by SouliTEK scripts are stored in this directory. These files are typically third-party utilities that are not included in the repository by default due to licensing or size constraints.

---

## McAfee Removal Tool (MCPR)

### File Information

- **File Name:** `MCPR.exe`
- **Full Path:** `tools/MCPR.exe`
- **Used By:** `scripts/mcafee_removal_tool.ps1`
- **Type:** Executable binary

### Description

The McAfee Consumer Product Removal (MCPR) tool is an official utility provided by McAfee for complete removal of all McAfee products from Windows systems. This tool ensures thorough cleanup of:

- McAfee Antivirus
- McAfee Total Protection
- McAfee LiveSafe
- All McAfee services and components
- Registry entries and leftover files

### How to Add

1. **Download MCPR.exe:**
   - Visit the official McAfee support website
   - Search for "MCPR" or "McAfee Consumer Product Removal"
   - Download the latest version of `MCPR.exe`

2. **Place the File:**
   - Copy `MCPR.exe` to this directory
   - Ensure the file is named exactly `MCPR.exe` (case-sensitive)
   - The full path should be: `tools/MCPR.exe`

3. **Verify Installation:**
   - Run `scripts/mcafee_removal_tool.ps1` as Administrator
   - The script will automatically detect if `MCPR.exe` is present
   - If missing, the script will display an error with instructions

### Usage

The tool is automatically invoked by the `mcafee_removal_tool.ps1` script:

```powershell
# Run as Administrator
.\scripts\mcafee_removal_tool.ps1
```

The script will:
1. Check for administrator privileges
2. Verify `MCPR.exe` exists in `tools/` directory
3. Display a warning about complete McAfee removal
4. Launch `MCPR.exe` and wait for completion
5. Report the removal status

### Important Notes

- **Administrator Required:** The script must be run with administrator privileges
- **Irreversible Action:** This tool completely removes all McAfee products - ensure you have a backup
- **Git Handling:** This file is treated as binary in Git (see `.gitattributes`)
- **File Size:** MCPR.exe is typically not included in the repository due to size constraints
- **Version:** Use the latest version from McAfee support for best compatibility

### Expected Directory Structure

```
Soulitek-AIO/
├── tools/
│   ├── MCPR.exe          ← Place MCPR.exe here
│   └── README.md
├── scripts/
│   └── mcafee_removal_tool.ps1
└── ...
```

### Troubleshooting

**Error: "MCPR Tool Not Found"**
- Ensure `MCPR.exe` is in the `tools/` directory
- Verify the filename is exactly `MCPR.exe` (not `mcpr.exe` or `MCPR.EXE`)
- Check that the project structure is intact

**Error: "Failed to run MCPR"**
- Ensure you're running as Administrator
- Check if antivirus is blocking execution
- Verify the file is not corrupted (re-download if needed)

---

## Adding New Tools

When adding new external tools to this directory:

1. **Document the Tool:**
   - Add a section in this README
   - Include file name, description, and usage instructions
   - Specify which script(s) use the tool

2. **Git Configuration:**
   - Ensure `.gitattributes` treats the file as binary (if applicable)
   - Add the file to `.gitignore` if it shouldn't be committed

3. **Script Integration:**
   - Update the script to check for the tool's existence
   - Provide clear error messages if the tool is missing
   - Document the expected path structure

---

## File Handling

All executable files (`.exe`, `.dll`, `.msi`) in this directory are treated as binary files in Git. See `.gitattributes` in the project root for configuration details.

**Note:** Large binary files may not be suitable for Git repositories. Consider using Git LFS or providing download instructions instead.
