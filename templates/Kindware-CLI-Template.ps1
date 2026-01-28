#!/usr/bin/env pwsh
#Requires -Version 7.0
<#
╔═══════════════════════════════════════════════════════════════════════════════╗
║                                                                               ║
║   KINDWARE CLI/TUI TEMPLATE                                                   ║
║   Modern PowerShell 7 Menu Template                                           ║
║                                                                               ║
║   Author:  LazyFrog-kz                                                        ║
║   Company: Kindware (kindware.dev)                                            ║
║   License: MIT License                                                        ║
║                                                                               ║
║   USAGE:                                                                      ║
║   1. Copy this template to your project                                       ║
║   2. Replace "TOOLNAME" with your tool name                                   ║
║   3. Update the ASCII art letters                                             ║
║   4. Add your menu options and functions                                      ║
║                                                                               ║
╚═══════════════════════════════════════════════════════════════════════════════╝

.SYNOPSIS
    [Your Tool Name] - [Brief Description]

.DESCRIPTION
    [Longer description of what your tool does]

.NOTES
    Name:       [ToolName]
    Author:     LazyFrog-kz
    Company:    Kindware (kindware.dev)
    Version:    1.0.0
    License:    MIT License
    Repository: https://github.com/LazyFrog-kz/[ToolName]

.LINK
    https://kindware.dev
#>

# ============================================================================
# CONFIGURATION
# ============================================================================
$ErrorActionPreference = "Stop"
$script:AppVersion = "1.0.0"
$script:AppName = "ToolName"          # <-- CHANGE THIS
$script:AppTagline = "Your Tagline"    # <-- CHANGE THIS
$script:Author = "LazyFrog-kz"
$script:Company = "Kindware"
$script:Website = "kindware.dev"
$script:ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
if (-not $script:ScriptDir) { $script:ScriptDir = $PWD.Path }

# ============================================================================
# ASCII ART LOGO - KINDWARE (Rainbow Colors)
# ============================================================================
# Generate your own ASCII art at: https://patorjk.com/software/taag/
# Font used: ANSI Shadow
#
# Color codes (PowerShell 7 ANSI):
#   `e[91m = Red      `e[92m = Green    `e[93m = Yellow
#   `e[94m = Blue     `e[95m = Magenta  `e[96m = Cyan
#   `e[97m = White    `e[90m = Gray     `e[0m  = Reset

function Show-Logo {
    $logo = @"

    `e[96m██╗  ██╗`e[0m`e[93m██╗`e[0m`e[96m███╗   ██╗`e[0m`e[92m██████╗ `e[0m`e[95m██╗    ██╗`e[0m`e[91m █████╗ `e[0m`e[94m██████╗ `e[0m`e[96m███████╗`e[0m
    `e[96m██║ ██╔╝`e[0m`e[93m██║`e[0m`e[96m████╗  ██║`e[0m`e[92m██╔══██╗`e[0m`e[95m██║    ██║`e[0m`e[91m██╔══██╗`e[0m`e[94m██╔══██╗`e[0m`e[96m██╔════╝`e[0m
    `e[96m█████╔╝ `e[0m`e[93m██║`e[0m`e[96m██╔██╗ ██║`e[0m`e[92m██║  ██║`e[0m`e[95m██║ █╗ ██║`e[0m`e[91m███████║`e[0m`e[94m██████╔╝`e[0m`e[96m█████╗  `e[0m
    `e[96m██╔═██╗ `e[0m`e[93m██║`e[0m`e[96m██║╚██╗██║`e[0m`e[92m██║  ██║`e[0m`e[95m██║███╗██║`e[0m`e[91m██╔══██║`e[0m`e[94m██╔══██╗`e[0m`e[96m██╔══╝  `e[0m
    `e[96m██║  ██╗`e[0m`e[93m██║`e[0m`e[96m██║ ╚████║`e[0m`e[92m██████╔╝`e[0m`e[95m╚███╔███╔╝`e[0m`e[91m██║  ██║`e[0m`e[94m██║  ██║`e[0m`e[96m███████╗`e[0m
    `e[96m╚═╝  ╚═╝`e[0m`e[93m╚═╝`e[0m`e[96m╚═╝  ╚═══╝`e[0m`e[92m╚═════╝ `e[0m`e[95m ╚══╝╚══╝ `e[0m`e[91m╚═╝  ╚═╝`e[0m`e[94m╚═╝  ╚═╝`e[0m`e[96m╚══════╝`e[0m

"@
    Write-Host $logo
}

# ============================================================================
# UI COMPONENTS
# ============================================================================

function Show-Banner {
    Clear-Host
    Show-Logo
    Write-Host "                    `e[92m◆ $script:AppName `e[90mv$script:AppVersion`e[0m" 
    Write-Host "              `e[90m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`e[0m"
    Write-Host "               `e[93m⚡`e[0m `e[37m$script:AppTagline`e[0m"
    Write-Host "               `e[90mcreated by `e[95m$script:Author`e[90m | `e[96m$script:Website`e[0m"
    Write-Host ""
}

function Show-Menu {
    Show-Banner
    
    # ╭─────────────────────────────────╮
    # │  Menu box with rounded corners  │
    # ╰─────────────────────────────────╯
    
    Write-Host "    `e[97m╭─────────────────────────────────╮`e[0m"
    Write-Host "    `e[97m│`e[0m  `e[93m[1]`e[0m `e[97m🚀 Option One`e[0m             `e[97m│`e[0m"
    Write-Host "    `e[97m│`e[0m  `e[93m[2]`e[0m `e[97m📦 Option Two`e[0m             `e[97m│`e[0m"
    Write-Host "    `e[97m│`e[0m  `e[93m[3]`e[0m `e[97m⚙️  Option Three`e[0m           `e[97m│`e[0m"
    Write-Host "    `e[97m│`e[0m  `e[93m[4]`e[0m `e[97m❓ Help`e[0m                   `e[97m│`e[0m"
    Write-Host "    `e[97m│`e[0m  `e[91m[Q]`e[0m `e[90m   Quit`e[0m                   `e[97m│`e[0m"
    Write-Host "    `e[97m╰─────────────────────────────────╯`e[0m"
    Write-Host ""
}

function Show-SectionHeader {
    param([string]$Title, [string]$Icon = "◆")
    Write-Host ""
    Write-Host "    `e[96m━━━ $Icon $Title ━━━`e[0m"
    Write-Host ""
}

function Show-Success { param([string]$Message) Write-Host "  `e[92m✔`e[0m $Message" }
function Show-Error   { param([string]$Message) Write-Host "  `e[91m✖`e[0m $Message" }
function Show-Warning { param([string]$Message) Write-Host "  `e[93m⚠`e[0m $Message" }
function Show-Info    { param([string]$Message) Write-Host "  `e[94mℹ`e[0m $Message" }

function Pause { 
    Write-Host ""
    Read-Host "  Press Enter to continue" | Out-Null 
}

# ============================================================================
# BOX DRAWING HELPERS
# ============================================================================
# Use these to create consistent boxes throughout your app

<#
Box Characters:
    ╭ ─ ╮   Rounded corners (top)
    │   │   Vertical sides
    ╰ ─ ╯   Rounded corners (bottom)
    
    ┌ ─ ┐   Square corners (top)
    │   │   Vertical sides
    └ ─ ┘   Square corners (bottom)
    
    ═══     Double horizontal
    ║       Double vertical
    
    ━━━     Heavy horizontal
    ┃       Heavy vertical
#>

function Draw-Box {
    param(
        [string]$Title,
        [string[]]$Lines,
        [int]$Width = 40,
        [string]$Color = "`e[97m"
    )
    
    $innerWidth = $Width - 2
    $titlePadded = if ($Title) { " $Title ".PadRight($innerWidth).Substring(0, $innerWidth) } else { "─" * $innerWidth }
    
    Write-Host "$Color╭$("─" * $innerWidth)╮`e[0m"
    if ($Title) {
        Write-Host "$Color│`e[93m$titlePadded`e[0m$Color│`e[0m"
        Write-Host "$Color├$("─" * $innerWidth)┤`e[0m"
    }
    foreach ($line in $Lines) {
        $paddedLine = "  $line".PadRight($innerWidth).Substring(0, $innerWidth)
        Write-Host "$Color│`e[0m$paddedLine$Color│`e[0m"
    }
    Write-Host "$Color╰$("─" * $innerWidth)╯`e[0m"
}

# ============================================================================
# YOUR FUNCTIONS GO HERE
# ============================================================================

function Do-OptionOne {
    Show-Banner
    Show-SectionHeader "OPTION ONE" "🚀"
    
    # Your code here
    Show-Info "This is option one"
    Show-Success "Operation completed"
    
    Pause
}

function Do-OptionTwo {
    Show-Banner
    Show-SectionHeader "OPTION TWO" "📦"
    
    # Your code here
    Show-Warning "This is a warning"
    
    Pause
}

function Do-OptionThree {
    Show-Banner
    Show-SectionHeader "OPTION THREE" "⚙️"
    
    # Example: Draw a box with content
    Draw-Box -Title "Settings" -Lines @(
        "Theme: Dark",
        "Language: English",
        "Auto-save: On"
    ) -Width 30
    
    Pause
}

function Show-Help {
    Show-Banner
    Show-SectionHeader "HELP" "❓"
    
    Write-Host @"
  `e[92m◆ QUICK START`e[0m
    1. Select an option from the menu
    2. Follow the prompts
    3. Press Enter to continue

  `e[93m◆ KEYBOARD`e[0m
    1-4    Select menu option
    Q      Quit application
    Enter  Confirm / Go back

  `e[90m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`e[0m
  `e[90m$script:AppName v$script:AppVersion | $script:Website`e[0m
  `e[90mCreated by $script:Author | MIT License`e[0m

"@
    Pause
}

function Exit-App {
    Clear-Host
    Show-Logo
    Write-Host "              `e[92m✔ Thanks for using $script:Company $script:AppName!`e[0m"
    Write-Host "              `e[90mcreated by $script:Author | $script:Website`e[0m"
    Write-Host ""
    exit 0
}

# ============================================================================
# MAIN ENTRY POINT
# ============================================================================

# Check PowerShell version
if ($PSVersionTable.PSVersion.Major -lt 7) {
    Write-Host "`e[91m✖ Requires PowerShell 7+`e[0m"
    Write-Host "`e[93mGet it: https://aka.ms/powershell`e[0m"
    exit 1
}

# Main loop
while ($true) {
    Show-Menu
    
    $choice = Read-Host "    `e[97m>`e[0m"
    switch ($choice.ToUpper()) {
        "1" { Do-OptionOne }
        "2" { Do-OptionTwo }
        "3" { Do-OptionThree }
        "4" { Show-Help }
        "Q" { Exit-App }
    }
}
