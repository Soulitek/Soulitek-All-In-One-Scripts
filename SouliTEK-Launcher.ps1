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

$Script:ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$Script:CurrentVersion = "1.0.0"

# ============================================================
# TOOL DEFINITIONS
# ============================================================

$Script:Tools = @(
    @{
        Name = "Battery Report Generator"
        Icon = "🔋"
        Description = "Generate comprehensive battery health reports for laptops"
        Script = "battery_report_generator.ps1"
        Category = "Hardware"
        Color = "#3498db"
    },
    @{
        Name = "PST Finder"
        Icon = "📧"
        Description = "Locate and analyze Outlook PST files across the system"
        Script = "FindPST.ps1"
        Category = "Data"
        Color = "#9b59b6"
    },
    @{
        Name = "Printer Spooler Fix"
        Icon = "🖨️"
        Description = "Comprehensive printer spooler troubleshooting and repair"
        Script = "printer_spooler_fix.ps1"
        Category = "Troubleshooting"
        Color = "#e74c3c"
    },
    @{
        Name = "WiFi Password Viewer"
        Icon = "📶"
        Description = "View and export saved WiFi passwords from Windows"
        Script = "wifi_password_viewer.ps1"
        Category = "Network"
        Color = "#1abc9c"
    },
    @{
        Name = "Event Log Analyzer"
        Icon = "📊"
        Description = "Analyze Windows Event Logs with statistical summaries"
        Script = "EventLogAnalyzer.ps1"
        Category = "Diagnostics"
        Color = "#f39c12"
    },
    @{
        Name = "Remote Support Toolkit"
        Icon = "🛠️"
        Description = "Comprehensive system diagnostics for remote IT support"
        Script = "remote_support_toolkit.ps1"
        Category = "Support"
        Color = "#2ecc71"
    }
)

# ============================================================
# HELPER FUNCTIONS
# ============================================================

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
        $arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""
        
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
    $form.Size = New-Object System.Drawing.Size(900, 700)
    $form.StartPosition = "CenterScreen"
    $form.FormBorderStyle = "FixedSingle"
    $form.MaximizeBox = $false
    $form.BackColor = [System.Drawing.Color]::FromArgb(245, 245, 245)
    
    # Header Panel with Gradient
    $headerPanel = New-Object System.Windows.Forms.Panel
    $headerPanel.Size = New-Object System.Drawing.Size(900, 100)
    $headerPanel.Location = New-Object System.Drawing.Point(0, 0)
    $headerPanel.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#667eea")
    
    # Title Label
    $titleLabel = New-Object System.Windows.Forms.Label
    $titleLabel.Text = "🚀 SouliTEK All-In-One Scripts"
    $titleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 20, [System.Drawing.FontStyle]::Bold)
    $titleLabel.ForeColor = [System.Drawing.Color]::White
    $titleLabel.Size = New-Object System.Drawing.Size(880, 50)
    $titleLabel.Location = New-Object System.Drawing.Point(10, 10)
    $titleLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
    
    # Subtitle Label
    $subtitleLabel = New-Object System.Windows.Forms.Label
    $subtitleLabel.Text = "Professional PowerShell Tools for IT Professionals"
    $subtitleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 11)
    $subtitleLabel.ForeColor = [System.Drawing.Color]::White
    $subtitleLabel.Size = New-Object System.Drawing.Size(880, 30)
    $subtitleLabel.Location = New-Object System.Drawing.Point(10, 60)
    $subtitleLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
    
    $headerPanel.Controls.Add($titleLabel)
    $headerPanel.Controls.Add($subtitleLabel)
    
    # Tools Panel (Scrollable)
    $toolsPanel = New-Object System.Windows.Forms.Panel
    $toolsPanel.Location = New-Object System.Drawing.Point(20, 120)
    $toolsPanel.Size = New-Object System.Drawing.Size(850, 480)
    $toolsPanel.AutoScroll = $true
    $toolsPanel.BackColor = [System.Drawing.Color]::White
    $toolsPanel.BorderStyle = "FixedSingle"
    
    # Create tool cards
    $yPosition = 10
    $cardHeight = 100
    $cardSpacing = 10
    
    foreach ($tool in $Script:Tools) {
        # Tool Card Panel
        $toolCard = New-Object System.Windows.Forms.Panel
        $toolCard.Size = New-Object System.Drawing.Size(810, $cardHeight)
        $toolCard.Location = New-Object System.Drawing.Point(10, $yPosition)
        $toolCard.BackColor = [System.Drawing.Color]::White
        $toolCard.BorderStyle = "FixedSingle"
        
        # Icon Label
        $iconLabel = New-Object System.Windows.Forms.Label
        $iconLabel.Text = $tool.Icon
        $iconLabel.Font = New-Object System.Drawing.Font("Segoe UI", 28)
        $iconLabel.Size = New-Object System.Drawing.Size(80, 80)
        $iconLabel.Location = New-Object System.Drawing.Point(10, 10)
        $iconLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
        
        # Tool Name Label
        $nameLabel = New-Object System.Windows.Forms.Label
        $nameLabel.Text = $tool.Name
        $nameLabel.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
        $nameLabel.Size = New-Object System.Drawing.Size(500, 30)
        $nameLabel.Location = New-Object System.Drawing.Point(100, 10)
        $nameLabel.ForeColor = [System.Drawing.ColorTranslator]::FromHtml($tool.Color)
        
        # Description Label
        $descLabel = New-Object System.Windows.Forms.Label
        $descLabel.Text = $tool.Description
        $descLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
        $descLabel.Size = New-Object System.Drawing.Size(500, 40)
        $descLabel.Location = New-Object System.Drawing.Point(100, 40)
        $descLabel.ForeColor = [System.Drawing.Color]::Gray
        
        # Category Badge
        $categoryLabel = New-Object System.Windows.Forms.Label
        $categoryLabel.Text = "  $($tool.Category)  "
        $categoryLabel.Font = New-Object System.Drawing.Font("Segoe UI", 8, [System.Drawing.FontStyle]::Bold)
        $categoryLabel.Size = New-Object System.Drawing.Size(100, 20)
        $categoryLabel.Location = New-Object System.Drawing.Point(610, 15)
        $categoryLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
        $categoryLabel.BackColor = [System.Drawing.ColorTranslator]::FromHtml($tool.Color)
        $categoryLabel.ForeColor = [System.Drawing.Color]::White
        
        # Launch Button
        $launchButton = New-Object System.Windows.Forms.Button
        $launchButton.Text = "Launch"
        $launchButton.Size = New-Object System.Drawing.Size(100, 35)
        $launchButton.Location = New-Object System.Drawing.Point(690, 50)
        $launchButton.FlatStyle = "Flat"
        $launchButton.BackColor = [System.Drawing.ColorTranslator]::FromHtml($tool.Color)
        $launchButton.ForeColor = [System.Drawing.Color]::White
        $launchButton.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
        $launchButton.Cursor = [System.Windows.Forms.Cursors]::Hand
        
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
            $this.FlatAppearance.BorderSize = 2
        })
        
        $launchButton.Add_MouseLeave({
            $this.FlatAppearance.BorderSize = 1
        })
        
        # Add controls to card
        $toolCard.Controls.Add($iconLabel)
        $toolCard.Controls.Add($nameLabel)
        $toolCard.Controls.Add($descLabel)
        $toolCard.Controls.Add($categoryLabel)
        $toolCard.Controls.Add($launchButton)
        
        # Add card to panel
        $toolsPanel.Controls.Add($toolCard)
        
        $yPosition += ($cardHeight + $cardSpacing)
    }
    
    # Status Bar Panel
    $statusPanel = New-Object System.Windows.Forms.Panel
    $statusPanel.Size = New-Object System.Drawing.Size(900, 35)
    $statusPanel.Location = New-Object System.Drawing.Point(0, 610)
    $statusPanel.BackColor = [System.Drawing.Color]::FromArgb(52, 73, 94)
    
    # Status Label
    $Script:StatusLabel = New-Object System.Windows.Forms.Label
    $Script:StatusLabel.Text = "Ready - Select a tool to launch"
    $Script:StatusLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $Script:StatusLabel.ForeColor = [System.Drawing.Color]::White
    $Script:StatusLabel.Size = New-Object System.Drawing.Size(600, 35)
    $Script:StatusLabel.Location = New-Object System.Drawing.Point(10, 0)
    $Script:StatusLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
    
    # Admin Status Label
    $adminLabel = New-Object System.Windows.Forms.Label
    if (Test-Administrator) {
        $adminLabel.Text = "✓ Administrator"
        $adminLabel.ForeColor = [System.Drawing.Color]::LightGreen
    } else {
        $adminLabel.Text = "⚠ Not Administrator"
        $adminLabel.ForeColor = [System.Drawing.Color]::Yellow
    }
    $adminLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
    $adminLabel.Size = New-Object System.Drawing.Size(150, 35)
    $adminLabel.Location = New-Object System.Drawing.Point(730, 0)
    $adminLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleRight
    
    $statusPanel.Controls.Add($Script:StatusLabel)
    $statusPanel.Controls.Add($adminLabel)
    
    # Bottom Button Panel
    $buttonPanel = New-Object System.Windows.Forms.Panel
    $buttonPanel.Size = New-Object System.Drawing.Size(900, 50)
    $buttonPanel.Location = New-Object System.Drawing.Point(0, 645)
    $buttonPanel.BackColor = [System.Drawing.Color]::FromArgb(245, 245, 245)
    
    # Help Button
    $helpButton = New-Object System.Windows.Forms.Button
    $helpButton.Text = "❓ Help"
    $helpButton.Size = New-Object System.Drawing.Size(120, 35)
    $helpButton.Location = New-Object System.Drawing.Point(20, 8)
    $helpButton.FlatStyle = "Flat"
    $helpButton.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#3498db")
    $helpButton.ForeColor = [System.Drawing.Color]::White
    $helpButton.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $helpButton.Cursor = [System.Windows.Forms.Cursors]::Hand
    $helpButton.Add_Click({ Show-Help })
    
    # About Button
    $aboutButton = New-Object System.Windows.Forms.Button
    $aboutButton.Text = "ℹ️ About"
    $aboutButton.Size = New-Object System.Drawing.Size(120, 35)
    $aboutButton.Location = New-Object System.Drawing.Point(150, 8)
    $aboutButton.FlatStyle = "Flat"
    $aboutButton.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#9b59b6")
    $aboutButton.ForeColor = [System.Drawing.Color]::White
    $aboutButton.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $aboutButton.Cursor = [System.Windows.Forms.Cursors]::Hand
    $aboutButton.Add_Click({ Show-About })
    
    # GitHub Button
    $githubButton = New-Object System.Windows.Forms.Button
    $githubButton.Text = "💻 GitHub"
    $githubButton.Size = New-Object System.Drawing.Size(120, 35)
    $githubButton.Location = New-Object System.Drawing.Point(280, 8)
    $githubButton.FlatStyle = "Flat"
    $githubButton.BackColor = [System.Drawing.Color]::FromArgb(51, 51, 51)
    $githubButton.ForeColor = [System.Drawing.Color]::White
    $githubButton.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $githubButton.Cursor = [System.Windows.Forms.Cursors]::Hand
    $githubButton.Add_Click({
        Start-Process "https://github.com/Soulitek/Soulitek-All-In-One-Scripts"
    })
    
    # Website Button
    $websiteButton = New-Object System.Windows.Forms.Button
    $websiteButton.Text = "🌐 Website"
    $websiteButton.Size = New-Object System.Drawing.Size(120, 35)
    $websiteButton.Location = New-Object System.Drawing.Point(410, 8)
    $websiteButton.FlatStyle = "Flat"
    $websiteButton.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#1abc9c")
    $websiteButton.ForeColor = [System.Drawing.Color]::White
    $websiteButton.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $websiteButton.Cursor = [System.Windows.Forms.Cursors]::Hand
    $websiteButton.Add_Click({
        Start-Process "https://soulitek.co.il"
    })
    
    # Exit Button
    $exitButton = New-Object System.Windows.Forms.Button
    $exitButton.Text = "❌ Exit"
    $exitButton.Size = New-Object System.Drawing.Size(120, 35)
    $exitButton.Location = New-Object System.Drawing.Point(760, 8)
    $exitButton.FlatStyle = "Flat"
    $exitButton.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#e74c3c")
    $exitButton.ForeColor = [System.Drawing.Color]::White
    $exitButton.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $exitButton.Cursor = [System.Windows.Forms.Cursors]::Hand
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

# Check if running from correct directory
if (-not (Test-Path (Join-Path $Script:ScriptPath "battery_report_generator.ps1"))) {
    [System.Windows.Forms.MessageBox]::Show(
        "Please ensure this launcher is in the same folder as all the PowerShell scripts.`n`nCurrent folder: $Script:ScriptPath",
        "Script Location Error",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Warning
    )
}

# Launch GUI
New-LauncherGUI

