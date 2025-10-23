# ============================================================
# SouliTEK All-In-One Scripts - GUI Launcher
# ============================================================
# 
# Coded by: Soulitek.co.il
# IT Solutions for your business
# 
# (C) 2025 Soulitek - All Rights Reserved
# Website: https://soulitek.co.il
# 
# Professional IT Solutions:
# - Computer Repair & Maintenance
# - Network Setup & Support
# - Software Solutions
# - Business IT Consulting
# 
# This launcher provides a unified GUI interface to access
# all SouliTEK PowerShell tools from one convenient location.
# 
# ============================================================

#Requires -Version 5.1

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ============================================================
# GLOBAL VARIABLES
# ============================================================

$Script:LauncherPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$Script:RootPath = Split-Path -Parent $Script:LauncherPath
$Script:ScriptPath = Join-Path $Script:RootPath "scripts"
$Script:CurrentVersion = "1.0.0"

# ============================================================
# TOOL DEFINITIONS
# ============================================================

$Script:Tools = @(
    @{
        Name = "Battery Report Generator"
        Icon = "⚡"
        Description = "Generate comprehensive battery health reports for laptops"
        Script = "battery_report_generator.ps1"
        ScriptPath = ""  # Will be set dynamically
        Category = "Hardware"
        Color = "#3498db"
    },
    @{
        Name = "PST Finder"
        Icon = "✉"
        Description = "Locate and analyze Outlook PST files across the system"
        Script = "FindPST.ps1"
        Category = "Data"
        Color = "#9b59b6"
    },
    @{
        Name = "Printer Spooler Fix"
        Icon = "⊞"
        Description = "Comprehensive printer spooler troubleshooting and repair"
        Script = "printer_spooler_fix.ps1"
        Category = "Troubleshooting"
        Color = "#e74c3c"
    },
    @{
        Name = "WiFi Password Viewer"
        Icon = "≈"
        Description = "View and export saved WiFi passwords from Windows"
        Script = "wifi_password_viewer.ps1"
        Category = "Network"
        Color = "#1abc9c"
    },
    @{
        Name = "Event Log Analyzer"
        Icon = "▤"
        Description = "Analyze Windows Event Logs with statistical summaries"
        Script = "EventLogAnalyzer.ps1"
        Category = "Diagnostics"
        Color = "#f39c12"
    },
    @{
        Name = "Remote Support Toolkit"
        Icon = "⚙"
        Description = "Comprehensive system diagnostics for remote IT support"
        Script = "remote_support_toolkit.ps1"
        Category = "Support"
        Color = "#2ecc71"
    }
)

# ============================================================
# HELPER FUNCTIONS
# ============================================================

function Set-RoundedButton {
    param($Button, $CornerRadius = 20)
    
    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $rect = New-Object System.Drawing.Rectangle(0, 0, $Button.Width, $Button.Height)
    
    # Create rounded rectangle path
    $path.AddArc($rect.X, $rect.Y, $CornerRadius, $CornerRadius, 180, 90)
    $path.AddArc($rect.Right - $CornerRadius, $rect.Y, $CornerRadius, $CornerRadius, 270, 90)
    $path.AddArc($rect.Right - $CornerRadius, $rect.Bottom - $CornerRadius, $CornerRadius, $CornerRadius, 0, 90)
    $path.AddArc($rect.X, $rect.Bottom - $CornerRadius, $CornerRadius, $CornerRadius, 90, 90)
    $path.CloseFigure()
    
    $Button.Region = New-Object System.Drawing.Region($path)
}

function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Start-Tool {
    param(
        [string]$ScriptName,
        [string]$ToolName
    )
    
    $scriptPath = Join-Path $Script:ScriptPath $ScriptName
    
    if (-not (Test-Path $scriptPath)) {
        [System.Windows.Forms.MessageBox]::Show(
            "Script not found: $ScriptName`n`nPlease ensure all scripts are in the same folder as the launcher.",
            "Script Not Found",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        )
        return
    }
    
    try {
        # Launch PowerShell with the script
        $psPath = "powershell.exe"
        $arguments = "-NoExit -NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""
        
        Start-Process -FilePath $psPath -ArgumentList $arguments
        
        # Show confirmation
        $script:StatusLabel.Text = "Launched: $ToolName"
        $script:StatusLabel.ForeColor = [System.Drawing.Color]::Green
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show(
            "Failed to launch $ToolName`n`nError: $_",
            "Launch Error",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        )
        
        $script:StatusLabel.Text = "Error launching tool"
        $script:StatusLabel.ForeColor = [System.Drawing.Color]::Red
    }
}

function Show-About {
    $aboutForm = New-Object System.Windows.Forms.Form
    $aboutForm.Text = "About SouliTEK Launcher"
    $aboutForm.Size = New-Object System.Drawing.Size(500, 400)
    $aboutForm.StartPosition = "CenterScreen"
    $aboutForm.FormBorderStyle = "FixedDialog"
    $aboutForm.MaximizeBox = $false
    $aboutForm.MinimizeBox = $false
    $aboutForm.BackColor = [System.Drawing.Color]::White
    
    # Header Panel
    $headerPanel = New-Object System.Windows.Forms.Panel
    $headerPanel.Size = New-Object System.Drawing.Size(500, 80)
    $headerPanel.Location = New-Object System.Drawing.Point(0, 0)
    $headerPanel.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#667eea")
    
    $headerLabel = New-Object System.Windows.Forms.Label
    $headerLabel.Text = "SouliTEK All-In-One Scripts"
    $headerLabel.Font = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
    $headerLabel.ForeColor = [System.Drawing.Color]::White
    $headerLabel.Size = New-Object System.Drawing.Size(480, 80)
    $headerLabel.Location = New-Object System.Drawing.Point(10, 0)
    $headerLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
    $headerPanel.Controls.Add($headerLabel)
    
    # Content
    $contentLabel = New-Object System.Windows.Forms.Label
    $contentLabel.Location = New-Object System.Drawing.Point(20, 100)
    $contentLabel.Size = New-Object System.Drawing.Size(460, 200)
    $contentLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $contentLabel.Text = @"
Version: $Script:CurrentVersion

Professional PowerShell Tools for IT Technicians
and Helpdesk Engineers

Total Tools: $($Script:Tools.Count)

Coded by: SouliTEK
Website: https://soulitek.co.il
Email: letstalk@soulitek.co.il

© 2025 SouliTEK - All Rights Reserved

Made with ❤️ in Israel
"@
    
    # GitHub Link
    $linkLabel = New-Object System.Windows.Forms.LinkLabel
    $linkLabel.Location = New-Object System.Drawing.Point(20, 300)
    $linkLabel.Size = New-Object System.Drawing.Size(460, 20)
    $linkLabel.Text = "GitHub: Soulitek/Soulitek-All-In-One-Scripts"
    $linkLabel.LinkColor = [System.Drawing.ColorTranslator]::FromHtml("#667eea")
    $linkLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $linkLabel.Add_LinkClicked({
        Start-Process "https://github.com/Soulitek/Soulitek-All-In-One-Scripts"
    })
    
    # Close Button
    $closeButton = New-Object System.Windows.Forms.Button
    $closeButton.Text = "Close"
    $closeButton.Location = New-Object System.Drawing.Point(200, 330)
    $closeButton.Size = New-Object System.Drawing.Size(100, 30)
    $closeButton.FlatStyle = "Flat"
    $closeButton.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#667eea")
    $closeButton.ForeColor = [System.Drawing.Color]::White
    $closeButton.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $closeButton.Add_Click({ $aboutForm.Close() })
    
    $aboutForm.Controls.Add($headerPanel)
    $aboutForm.Controls.Add($contentLabel)
    $aboutForm.Controls.Add($linkLabel)
    $aboutForm.Controls.Add($closeButton)
    
    $aboutForm.ShowDialog()
}

function Show-Help {
    $helpText = @"
SOULITEK ALL-IN-ONE SCRIPTS LAUNCHER
====================================

USAGE:
------
1. Click on any tool button to launch it
2. Each tool will open in a new PowerShell window
3. Follow the on-screen instructions in each tool

TOOLS AVAILABLE:
----------------
"@
    
    foreach ($tool in $Script:Tools) {
        $helpText += "`n$($tool.Icon) $($tool.Name)`n   $($tool.Description)`n"
    }
    
    $helpText += @"

TIPS:
-----
• Run this launcher as Administrator for full functionality
• All tools can run independently
• Some tools require Administrator privileges
• Check each tool's help menu for detailed instructions

SUPPORT:
--------
Website: https://soulitek.co.il
Email: letstalk@soulitek.co.il
GitHub: https://github.com/Soulitek/Soulitek-All-In-One-Scripts

====================================
"@
    
    [System.Windows.Forms.MessageBox]::Show(
        $helpText,
        "Help - SouliTEK Launcher",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Information
    )
}

# ============================================================
# GUI CREATION
# ============================================================

function New-LauncherGUI {
    # Main Form
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "SouliTEK All-In-One Scripts Launcher"
    $form.Size = New-Object System.Drawing.Size(950, 750)
    $form.StartPosition = "CenterScreen"
    $form.FormBorderStyle = "FixedSingle"
    $form.MaximizeBox = $false
    $form.BackColor = [System.Drawing.Color]::FromArgb(240, 242, 245)
    
    # Header Panel with modern gradient
    $headerPanel = New-Object System.Windows.Forms.Panel
    $headerPanel.Size = New-Object System.Drawing.Size(950, 120)
    $headerPanel.Location = New-Object System.Drawing.Point(0, 0)
    $headerPanel.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#6366f1")
    
    # Title Label
    $titleLabel = New-Object System.Windows.Forms.Label
    $titleLabel.Text = "⚡ SouliTEK All-In-One Scripts"
    $titleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 24, [System.Drawing.FontStyle]::Bold)
    $titleLabel.ForeColor = [System.Drawing.Color]::White
    $titleLabel.Size = New-Object System.Drawing.Size(930, 60)
    $titleLabel.Location = New-Object System.Drawing.Point(10, 15)
    $titleLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
    
    # Subtitle Label
    $subtitleLabel = New-Object System.Windows.Forms.Label
    $subtitleLabel.Text = "Professional PowerShell Tools for IT Professionals"
    $subtitleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 12)
    $subtitleLabel.ForeColor = [System.Drawing.Color]::FromArgb(220, 220, 255)
    $subtitleLabel.Size = New-Object System.Drawing.Size(930, 35)
    $subtitleLabel.Location = New-Object System.Drawing.Point(10, 70)
    $subtitleLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
    
    $headerPanel.Controls.Add($titleLabel)
    $headerPanel.Controls.Add($subtitleLabel)
    
    # Tools Panel (Scrollable)
    $toolsPanel = New-Object System.Windows.Forms.Panel
    $toolsPanel.Location = New-Object System.Drawing.Point(25, 140)
    $toolsPanel.Size = New-Object System.Drawing.Size(895, 460)
    $toolsPanel.AutoScroll = $true
    $toolsPanel.BackColor = [System.Drawing.Color]::FromArgb(240, 242, 245)
    $toolsPanel.BorderStyle = "None"
    
    # Create tool cards
    $yPosition = 15
    $cardHeight = 110
    $cardSpacing = 15
    
    foreach ($tool in $Script:Tools) {
        # Tool Card Panel with rounded appearance
        $toolCard = New-Object System.Windows.Forms.Panel
        $toolCard.Size = New-Object System.Drawing.Size(850, $cardHeight)
        $toolCard.Location = New-Object System.Drawing.Point(15, $yPosition)
        $toolCard.BackColor = [System.Drawing.Color]::White
        $toolCard.BorderStyle = "None"
        
        # Add shadow effect using a darker panel behind
        $shadowPanel = New-Object System.Windows.Forms.Panel
        $shadowPanel.Size = New-Object System.Drawing.Size(850, $cardHeight)
        $shadowPanel.Location = New-Object System.Drawing.Point(18, ($yPosition + 3))
        $shadowPanel.BackColor = [System.Drawing.Color]::FromArgb(30, 0, 0, 0)
        $shadowPanel.BorderStyle = "None"
        $toolsPanel.Controls.Add($shadowPanel)
        
        # Icon Panel - circular background
        $iconPanel = New-Object System.Windows.Forms.Panel
        $iconPanel.Size = New-Object System.Drawing.Size(75, 75)
        $iconPanel.Location = New-Object System.Drawing.Point(20, 18)
        $iconPanel.BackColor = [System.Drawing.ColorTranslator]::FromHtml($tool.Color)
        
        # Icon Label
        $iconLabel = New-Object System.Windows.Forms.Label
        $iconLabel.Text = $tool.Icon
        $iconLabel.Font = New-Object System.Drawing.Font("Segoe UI", 32, [System.Drawing.FontStyle]::Bold)
        $iconLabel.Size = New-Object System.Drawing.Size(75, 75)
        $iconLabel.Location = New-Object System.Drawing.Point(0, 0)
        $iconLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
        $iconLabel.ForeColor = [System.Drawing.Color]::White
        $iconLabel.BackColor = [System.Drawing.Color]::Transparent
        $iconPanel.Controls.Add($iconLabel)
        
        # Tool Name Label
        $nameLabel = New-Object System.Windows.Forms.Label
        $nameLabel.Text = $tool.Name
        $nameLabel.Font = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
        $nameLabel.Size = New-Object System.Drawing.Size(520, 35)
        $nameLabel.Location = New-Object System.Drawing.Point(110, 20)
        $nameLabel.ForeColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
        
        # Description Label
        $descLabel = New-Object System.Windows.Forms.Label
        $descLabel.Text = $tool.Description
        $descLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10)
        $descLabel.Size = New-Object System.Drawing.Size(520, 50)
        $descLabel.Location = New-Object System.Drawing.Point(110, 50)
        $descLabel.ForeColor = [System.Drawing.Color]::FromArgb(100, 100, 100)
        
        # Launch Button - rounded style
        $launchButton = New-Object System.Windows.Forms.Button
        $launchButton.Text = "Launch"
        $launchButton.Size = New-Object System.Drawing.Size(140, 70)
        $launchButton.Location = New-Object System.Drawing.Point(685, 20)
        $launchButton.FlatStyle = "Flat"
        $launchButton.BackColor = [System.Drawing.ColorTranslator]::FromHtml($tool.Color)
        $launchButton.ForeColor = [System.Drawing.Color]::White
        $launchButton.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
        $launchButton.Cursor = [System.Windows.Forms.Cursors]::Hand
        $launchButton.FlatAppearance.BorderSize = 0
        $launchButton.FlatAppearance.MouseOverBackColor = [System.Drawing.Color]::FromArgb(220, [System.Drawing.ColorTranslator]::FromHtml($tool.Color).R, [System.Drawing.ColorTranslator]::FromHtml($tool.Color).G, [System.Drawing.ColorTranslator]::FromHtml($tool.Color).B)
        
        # Make button rounded
        Set-RoundedButton -Button $launchButton -CornerRadius 35
        
        # Make icon panel rounded (circular)
        $iconPath = New-Object System.Drawing.Drawing2D.GraphicsPath
        $iconPath.AddEllipse(0, 0, 75, 75)
        $iconPanel.Region = New-Object System.Drawing.Region($iconPath)
        
        # Store script name in tag
        $launchButton.Tag = @{
            Script = $tool.Script
            Name = $tool.Name
        }
        
        $launchButton.Add_Click({
            $toolInfo = $this.Tag
            Start-Tool -ScriptName $toolInfo.Script -ToolName $toolInfo.Name
        })
        
        # Add hover effects
        $launchButton.Add_MouseEnter({
            $this.ForeColor = [System.Drawing.Color]::FromArgb(255, 255, 255)
        })
        
        $launchButton.Add_MouseLeave({
            $this.ForeColor = [System.Drawing.Color]::White
        })
        
        # Add controls to card
        $toolCard.Controls.Add($iconPanel)
        $toolCard.Controls.Add($nameLabel)
        $toolCard.Controls.Add($descLabel)
        $toolCard.Controls.Add($launchButton)
        
        # Add card to panel
        $toolsPanel.Controls.Add($toolCard)
        $toolCard.BringToFront()
        
        $yPosition += ($cardHeight + $cardSpacing)
    }
    
    # Status Bar Panel
    $statusPanel = New-Object System.Windows.Forms.Panel
    $statusPanel.Size = New-Object System.Drawing.Size(950, 40)
    $statusPanel.Location = New-Object System.Drawing.Point(0, 610)
    $statusPanel.BackColor = [System.Drawing.Color]::FromArgb(248, 250, 252)
    
    # Status Label
    $Script:StatusLabel = New-Object System.Windows.Forms.Label
    $Script:StatusLabel.Text = "● Ready - Select a tool to launch"
    $Script:StatusLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $Script:StatusLabel.ForeColor = [System.Drawing.Color]::FromArgb(100, 100, 100)
    $Script:StatusLabel.Size = New-Object System.Drawing.Size(650, 40)
    $Script:StatusLabel.Location = New-Object System.Drawing.Point(20, 0)
    $Script:StatusLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
    
    # Admin Status Label
    $adminLabel = New-Object System.Windows.Forms.Label
    if (Test-Administrator) {
        $adminLabel.Text = "● Administrator"
        $adminLabel.ForeColor = [System.Drawing.Color]::FromArgb(34, 197, 94)
    } else {
        $adminLabel.Text = "● Not Administrator"
        $adminLabel.ForeColor = [System.Drawing.Color]::FromArgb(251, 146, 60)
    }
    $adminLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $adminLabel.Size = New-Object System.Drawing.Size(220, 40)
    $adminLabel.Location = New-Object System.Drawing.Point(710, 0)
    $adminLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleRight
    
    $statusPanel.Controls.Add($Script:StatusLabel)
    $statusPanel.Controls.Add($adminLabel)
    
    # Bottom Button Panel
    $buttonPanel = New-Object System.Windows.Forms.Panel
    $buttonPanel.Size = New-Object System.Drawing.Size(950, 60)
    $buttonPanel.Location = New-Object System.Drawing.Point(0, 650)
    $buttonPanel.BackColor = [System.Drawing.Color]::FromArgb(240, 242, 245)
    
    # Help Button - Rounded
    $helpButton = New-Object System.Windows.Forms.Button
    $helpButton.Text = "Help"
    $helpButton.Size = New-Object System.Drawing.Size(110, 40)
    $helpButton.Location = New-Object System.Drawing.Point(30, 10)
    $helpButton.FlatStyle = "Flat"
    $helpButton.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#6366f1")
    $helpButton.ForeColor = [System.Drawing.Color]::White
    $helpButton.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
    $helpButton.Cursor = [System.Windows.Forms.Cursors]::Hand
    $helpButton.FlatAppearance.BorderSize = 0
    Set-RoundedButton -Button $helpButton -CornerRadius 20
    $helpButton.Add_Click({ Show-Help })
    
    # About Button - Rounded
    $aboutButton = New-Object System.Windows.Forms.Button
    $aboutButton.Text = "About"
    $aboutButton.Size = New-Object System.Drawing.Size(110, 40)
    $aboutButton.Location = New-Object System.Drawing.Point(155, 10)
    $aboutButton.FlatStyle = "Flat"
    $aboutButton.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#8b5cf6")
    $aboutButton.ForeColor = [System.Drawing.Color]::White
    $aboutButton.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
    $aboutButton.Cursor = [System.Windows.Forms.Cursors]::Hand
    $aboutButton.FlatAppearance.BorderSize = 0
    Set-RoundedButton -Button $aboutButton -CornerRadius 20
    $aboutButton.Add_Click({ Show-About })
    
    # GitHub Button - Rounded
    $githubButton = New-Object System.Windows.Forms.Button
    $githubButton.Text = "GitHub"
    $githubButton.Size = New-Object System.Drawing.Size(110, 40)
    $githubButton.Location = New-Object System.Drawing.Point(280, 10)
    $githubButton.FlatStyle = "Flat"
    $githubButton.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
    $githubButton.ForeColor = [System.Drawing.Color]::White
    $githubButton.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
    $githubButton.Cursor = [System.Windows.Forms.Cursors]::Hand
    $githubButton.FlatAppearance.BorderSize = 0
    Set-RoundedButton -Button $githubButton -CornerRadius 20
    $githubButton.Add_Click({
        Start-Process "https://github.com/Soulitek/Soulitek-All-In-One-Scripts"
    })
    
    # Website Button - Rounded
    $websiteButton = New-Object System.Windows.Forms.Button
    $websiteButton.Text = "Website"
    $websiteButton.Size = New-Object System.Drawing.Size(110, 40)
    $websiteButton.Location = New-Object System.Drawing.Point(405, 10)
    $websiteButton.FlatStyle = "Flat"
    $websiteButton.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#14b8a6")
    $websiteButton.ForeColor = [System.Drawing.Color]::White
    $websiteButton.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
    $websiteButton.Cursor = [System.Windows.Forms.Cursors]::Hand
    $websiteButton.FlatAppearance.BorderSize = 0
    Set-RoundedButton -Button $websiteButton -CornerRadius 20
    $websiteButton.Add_Click({
        Start-Process "https://soulitek.co.il"
    })
    
    # Exit Button - Rounded
    $exitButton = New-Object System.Windows.Forms.Button
    $exitButton.Text = "Exit"
    $exitButton.Size = New-Object System.Drawing.Size(110, 40)
    $exitButton.Location = New-Object System.Drawing.Point(810, 10)
    $exitButton.FlatStyle = "Flat"
    $exitButton.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#ef4444")
    $exitButton.ForeColor = [System.Drawing.Color]::White
    $exitButton.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
    $exitButton.Cursor = [System.Windows.Forms.Cursors]::Hand
    $exitButton.FlatAppearance.BorderSize = 0
    Set-RoundedButton -Button $exitButton -CornerRadius 20
    $exitButton.Add_Click({ $form.Close() })
    
    $buttonPanel.Controls.Add($helpButton)
    $buttonPanel.Controls.Add($aboutButton)
    $buttonPanel.Controls.Add($githubButton)
    $buttonPanel.Controls.Add($websiteButton)
    $buttonPanel.Controls.Add($exitButton)
    
    # Add all panels to form
    $form.Controls.Add($headerPanel)
    $form.Controls.Add($toolsPanel)
    $form.Controls.Add($statusPanel)
    $form.Controls.Add($buttonPanel)
    
    # Show form
    $form.Add_Shown({
        $form.Activate()
        
        # Show welcome message if not admin
        if (-not (Test-Administrator)) {
            [System.Windows.Forms.MessageBox]::Show(
                "For best results, run this launcher as Administrator.`n`nSome tools require elevated privileges to function properly.",
                "Administrator Recommended",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Information
            )
        }
    })
    
    [void]$form.ShowDialog()
}

# ============================================================
# MAIN EXECUTION
# ============================================================

# Check if scripts directory exists
if (-not (Test-Path $Script:ScriptPath)) {
    [System.Windows.Forms.MessageBox]::Show(
        "Scripts directory not found!`n`nExpected location: $Script:ScriptPath`n`nPlease ensure the 'scripts' folder exists in the project root.",
        "Script Location Error",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Warning
    )
    exit
}

# Launch GUI
New-LauncherGUI

