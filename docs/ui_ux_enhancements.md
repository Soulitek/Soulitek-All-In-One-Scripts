# UI/UX Enhancements Documentation

## Overview

The SouliTEK Launcher has been enhanced with modern Material Design components, improved notifications, and theme switching capabilities.

## Features

### 1. MaterialDesignInXamlToolkit Integration

The launcher now uses MaterialDesignInXamlToolkit for a modern, polished UI with:
- Material Design components and styling
- Ripple effects on buttons
- Enhanced visual feedback
- Professional appearance

**Requirements:**
- MaterialDesignThemes.dll
- MaterialDesignColors.dll

**Installation:**
1. Run `libs/Download-MaterialDesign.ps1` to automatically download DLLs
2. Or manually download from NuGet and place DLLs in `libs/` folder
3. See `libs/README.md` for detailed instructions

**Fallback Behavior:**
If MaterialDesign DLLs are not available, the launcher will run with basic WPF controls and display warnings in the console.

### 2. Toast Notifications (Snackbars)

Replaced blocking MessageBox dialogs with non-blocking MaterialDesign snackbar notifications for better user experience.

**Severity Levels:**
- **Info** - Blue snackbar for informational messages
- **Success** - Green snackbar for successful operations
- **Warning** - Orange snackbar for warnings
- **Error** - Red snackbar for errors

**Usage:**
```powershell
Show-Snackbar -Message "Tool launched successfully" -Severity "Success" -DurationMs 3000
```

**When MessageBox is Still Used:**
- Critical confirmations (uninstall, restore point creation)
- Long informational dialogs (Help, About)
- Error dialogs that require user acknowledgment before continuing

### 3. Theme Switching

Users can toggle between Light and Dark themes with a single click.

**Features:**
- Theme preference persists across sessions
- Stored in `%APPDATA%\SouliTEK\theme-config.json`
- Theme toggle button in header (moon/sun icon)
- Smooth theme transitions

**Theme Toggle Button:**
- Located in header, between logo and minimize button
- Moon icon = switch to dark theme
- Sun icon = switch to light theme
- Tooltip: "Toggle theme"

**Configuration File:**
```json
{
    "theme": "Light",
    "lastUpdated": "2025-01-XX HH:mm:ss"
}
```

## Technical Details

### MaterialDesign DLL Loading

The launcher checks for MaterialDesign DLLs on startup:
1. Looks for DLLs in `libs/` folder
2. Loads assemblies if found
3. Falls back to basic WPF if DLLs missing
4. Shows warnings in console if MaterialDesign unavailable

### Snackbar Implementation

- Uses MaterialDesign Snackbar control
- MessageQueue for managing multiple notifications
- Non-blocking - users can continue interacting
- Auto-dismisses after duration (default: 3 seconds)

### Theme System

- MaterialDesign BundledTheme for theme switching
- Light theme: Default Material Design Light
- Dark theme: Material Design Dark
- Theme applied to entire window and all controls
- Icon updates automatically based on current theme

## User Experience Improvements

### Before
- Blocking MessageBox dialogs interrupted workflow
- Basic WPF styling
- No theme customization
- Interruptive notifications

### After
- Non-blocking snackbar notifications
- Modern Material Design styling
- Light/Dark theme support
- Smooth, professional UI
- Better visual feedback

## Troubleshooting

### MaterialDesign DLLs Not Loading

**Symptoms:**
- Console warnings about missing DLLs
- Basic WPF controls instead of MaterialDesign
- Theme switching disabled

**Solution:**
1. Ensure DLLs are in `libs/` folder
2. Check file names: `MaterialDesignThemes.dll` and `MaterialDesignColors.dll`
3. Verify DLLs are not corrupted
4. Run `libs/Download-MaterialDesign.ps1` to re-download

### Theme Not Persisting

**Symptoms:**
- Theme resets to Light on each launch

**Solution:**
1. Check `%APPDATA%\SouliTEK\theme-config.json` exists
2. Verify file permissions (should be writable)
3. Check file content is valid JSON

### Snackbar Not Showing

**Symptoms:**
- No notifications appear
- Errors in console

**Solution:**
1. Verify MaterialDesign DLLs are loaded
2. Check snackbar control is initialized
3. Review console for error messages

## Files Modified

- `launcher/MainWindow.xaml` - Added MaterialDesign namespaces, snackbar, theme resources
- `launcher/SouliTEK-Launcher-WPF.ps1` - Added DLL loading, snackbar function, theme management
- `libs/README.md` - Instructions for downloading DLLs
- `libs/Download-MaterialDesign.ps1` - Automated DLL download script

## Future Enhancements

Potential improvements:
- More theme color options
- Custom theme colors
- Notification history
- Sound effects for notifications
- Animation improvements

