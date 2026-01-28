# KINDWARE CLI/TUI Style Guide

## 🎨 Visual Style for PowerShell 7 CLI/TUI Applications

This guide explains how to apply the **KINDWARE rainbow CLI look** to any PowerShell 7 terminal application. Use this to make your CLI/TUI tools match the GitHubScout aesthetic.

> **IMPORTANT FOR AI ASSISTANTS:** This guide is for **visual styling ONLY**. Do NOT modify any application logic, functionality, or behavior. Only apply colors, ASCII art, and menu formatting.

---

## 📋 Requirements

- **PowerShell 7.0+** (required for ANSI escape codes)
- Windows Terminal recommended for best color support

---

## 🌈 Color Palette (ANSI Escape Codes)

```powershell
# Rainbow colors for KINDWARE branding
$Red     = "`e[91m"   # Bright Red
$Green   = "`e[92m"   # Bright Green  
$Yellow  = "`e[93m"   # Bright Yellow
$Blue    = "`e[94m"   # Bright Blue
$Magenta = "`e[95m"   # Bright Magenta
$Cyan    = "`e[96m"   # Bright Cyan
$White   = "`e[97m"   # Bright White
$Gray    = "`e[90m"   # Dark Gray
$Reset   = "`e[0m"    # Reset to default
```

---

## 🏷️ Rainbow KINDWARE Logo

Use this exact ASCII art with rainbow colors for the logo:

```powershell
function Show-KindwareLogo {
    Write-Host ""
    Write-Host "    `e[91m██╗  ██╗`e[93m██╗`e[92m███╗   ██╗`e[96m██████╗ `e[94m██╗    ██╗`e[95m █████╗ `e[91m██████╗ `e[93m███████╗`e[0m"
    Write-Host "    `e[91m██║ ██╔╝`e[93m██║`e[92m████╗  ██║`e[96m██╔══██╗`e[94m██║    ██║`e[95m██╔══██╗`e[91m██╔══██╗`e[93m██╔════╝`e[0m"
    Write-Host "    `e[91m█████╔╝ `e[93m██║`e[92m██╔██╗ ██║`e[96m██║  ██║`e[94m██║ █╗ ██║`e[95m███████║`e[91m██████╔╝`e[93m█████╗  `e[0m"
    Write-Host "    `e[91m██╔═██╗ `e[93m██║`e[92m██║╚██╗██║`e[96m██║  ██║`e[94m██║███╗██║`e[95m██╔══██║`e[91m██╔══██╗`e[93m██╔══╝  `e[0m"
    Write-Host "    `e[91m██║  ██╗`e[93m██║`e[92m██║ ╚████║`e[96m██████╔╝`e[94m╚███╔███╔╝`e[95m██║  ██║`e[91m██║  ██║`e[93m███████╗`e[0m"
    Write-Host "    `e[91m╚═╝  ╚═╝`e[93m╚═╝`e[92m╚═╝  ╚═══╝`e[96m╚═════╝ `e[94m ╚══╝╚══╝ `e[95m╚═╝  ╚═╝`e[91m╚═╝  ╚═╝`e[93m╚══════╝`e[0m"
    Write-Host ""
}
```

---

## 📦 Box Menu with Rounded Corners

Use Unicode box-drawing characters for menus:

```powershell
function Show-Menu {
    param(
        [string]$Title,
        [array]$Options
    )
    
    $width = 35
    $TopLeft = "╭"
    $TopRight = "╮"
    $BottomLeft = "╰"
    $BottomRight = "╯"
    $Horizontal = "─"
    $Vertical = "│"
    
    # Top border
    Write-Host "    `e[96m$TopLeft$($Horizontal * $width)$TopRight`e[0m"
    
    # Menu items with emojis
    foreach ($opt in $Options) {
        $padding = $width - $opt.Length - 2
        Write-Host "    `e[96m$Vertical`e[0m  $opt$(' ' * $padding)`e[96m$Vertical`e[0m"
    }
    
    # Bottom border
    Write-Host "    `e[96m$BottomLeft$($Horizontal * $width)$BottomRight`e[0m"
}

# Example usage:
$menuItems = @(
    "`e[97m[1]`e[0m `e[93m🔍 Search`e[0m",
    "`e[97m[2]`e[0m `e[92m📌 Track`e[0m",
    "`e[97m[3]`e[0m `e[96m🔎 Inspect`e[0m",
    "`e[97m[4]`e[0m `e[95m❓ Help`e[0m",
    "`e[97m[Q]`e[0m `e[90m   Quit`e[0m"
)
Show-Menu -Title "Main Menu" -Options $menuItems
```

**Output looks like:**
```
    ╭───────────────────────────────────╮
    │  [1] 🔍 Search                    │
    │  [2] 📌 Track                     │
    │  [3] 🔎 Inspect                   │
    │  [4] ❓ Help                      │
    │  [Q]    Quit                      │
    ╰───────────────────────────────────╯
```

---

## 📝 App Title Banner

Show app name and version below the logo:

```powershell
function Show-AppBanner {
    param(
        [string]$AppName,
        [string]$Version,
        [string]$Tagline
    )
    
    Write-Host "                    `e[92m◆ $AppName v$Version`e[0m"
    Write-Host "              `e[90m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`e[0m"
    Write-Host "               `e[96m$Tagline`e[0m"
    Write-Host "               `e[90mcreated by LazyFrog-kz | kindware.dev`e[0m"
    Write-Host ""
}

# Example:
Show-AppBanner -AppName "MyApp" -Version "1.0.0" -Tagline "⚡ My Awesome Tool"
```

---

## ✅ Success/Error/Warning Messages

Use consistent colored prefixes:

```powershell
function Write-Success { param([string]$Message) Write-Host "  `e[92m✔`e[0m $Message" }
function Write-Error   { param([string]$Message) Write-Host "  `e[91m✖`e[0m $Message" }
function Write-Warning { param([string]$Message) Write-Host "  `e[93m⚠`e[0m $Message" }
function Write-Info    { param([string]$Message) Write-Host "  `e[96m◆`e[0m $Message" }
function Write-Prompt  { param([string]$Message) Write-Host "  `e[95m▶`e[0m $Message" -NoNewline }
```

---

## 📊 Status Indicators

For progress steps:

```powershell
Write-Host "  `e[93m[1/4]`e[0m Downloading..." -NoNewline
# ... do work ...
Write-Host " `e[92m✔`e[0m"

Write-Host "  `e[93m[2/4]`e[0m Installing..." -NoNewline
# ... do work ...
Write-Host " `e[92m✔`e[0m"
```

---

## 🎯 Input Prompt Style

```powershell
function Get-UserInput {
    param([string]$Prompt)
    Write-Host ""
    Write-Host "  `e[96m$Prompt`e[0m" -NoNewline
    Write-Host " `e[90m>`e[0m " -NoNewline
    return Read-Host
}

# Example:
$choice = Get-UserInput -Prompt "Enter your choice"
```

---

## 📋 Table/List Display

For search results or data lists:

```powershell
function Show-ResultsList {
    param([array]$Items)
    
    Write-Host ""
    Write-Host "  `e[92mFound $($Items.Count) items:`e[0m"
    Write-Host ""
    
    $i = 1
    foreach ($item in $Items) {
        $num = "[$($i.ToString().PadLeft(2))]"
        Write-Host "  `e[97m$num`e[0m `e[96m$($item.Name)`e[0m"
        $i++
    }
    Write-Host ""
}
```

---

## 🔄 Complete Main Loop Template

```powershell
#!/usr/bin/env pwsh

# Check PowerShell version
if ($PSVersionTable.PSVersion.Major -lt 7) {
    Write-Host "`e[91m✖ This app requires PowerShell 7+`e[0m"
    Write-Host "`e[93mDownload from: https://aka.ms/powershell`e[0m"
    Read-Host "Press Enter to exit"
    exit 1
}

# Main app function
function Start-App {
    while ($true) {
        Clear-Host
        Show-KindwareLogo
        Show-AppBanner -AppName "MyApp" -Version "1.0.0" -Tagline "⚡ Description here"
        
        # Show menu
        Write-Host "    `e[96m╭───────────────────────────────────╮`e[0m"
        Write-Host "    `e[96m│`e[0m  `e[97m[1]`e[0m `e[93m🔍 Option One`e[0m               `e[96m│`e[0m"
        Write-Host "    `e[96m│`e[0m  `e[97m[2]`e[0m `e[92m📌 Option Two`e[0m               `e[96m│`e[0m"
        Write-Host "    `e[96m│`e[0m  `e[97m[3]`e[0m `e[96m🔎 Option Three`e[0m             `e[96m│`e[0m"
        Write-Host "    `e[96m│`e[0m  `e[97m[Q]`e[0m `e[90m   Quit`e[0m                     `e[96m│`e[0m"
        Write-Host "    `e[96m╰───────────────────────────────────╯`e[0m"
        Write-Host ""
        
        $choice = Get-UserInput -Prompt "Select option"
        
        switch ($choice.ToUpper()) {
            "1" { Do-OptionOne }
            "2" { Do-OptionTwo }
            "3" { Do-OptionThree }
            "Q" { 
                Write-Host ""
                Write-Host "  `e[90mGoodbye! Thanks for using MyApp`e[0m"
                Write-Host ""
                return 
            }
            default { 
                Write-Warning "Invalid option"
                Start-Sleep -Seconds 1
            }
        }
    }
}

# Start the app
Start-App
```

---

## 🚫 What NOT to Change

When applying this style guide to an existing app:

1. ❌ **DO NOT** modify any logic or functionality
2. ❌ **DO NOT** change how features work
3. ❌ **DO NOT** alter data processing or API calls
4. ❌ **DO NOT** modify file operations or storage
5. ❌ **DO NOT** change command-line arguments

Only change:
- ✅ Colors and formatting
- ✅ ASCII art logo
- ✅ Menu borders and layout
- ✅ Message prefixes (✔, ✖, ⚠, etc.)
- ✅ Box-drawing characters

---

## 📝 Emoji Reference

| Context | Emoji | Usage |
|---------|-------|-------|
| Search | 🔍 | Search functions |
| Track/Save | 📌 | Tracking, bookmarks |
| Inspect/View | 🔎 | Detailed views |
| Help | ❓ | Help menus |
| Settings | ⚙️ | Configuration |
| Success | ✔ | Completed actions |
| Error | ✖ | Failed actions |
| Warning | ⚠ | Caution messages |
| Info | ◆ | Information |
| Prompt | ▶ | User input |
| Star | ⭐ | Favorites, ratings |
| Folder | 📁 | File operations |
| Download | ⬇️ | Downloads |

---

## 🎨 Color Cheat Sheet

| Color | Code | Use For |
|-------|------|---------|
| `e[91m` | Red | Errors, warnings |
| `e[92m` | Green | Success, confirmations |
| `e[93m` | Yellow | Highlights, caution |
| `e[94m` | Blue | Links, secondary info |
| `e[95m` | Magenta | Prompts, special |
| `e[96m` | Cyan | Borders, primary UI |
| `e[97m` | White | Text, numbers |
| `e[90m` | Gray | Subtle, disabled |
| `e[0m` | Reset | Always end with this! |

---

## 📄 License

MIT License - Use this style freely in your KINDWARE projects.

**Created by LazyFrog-kz | [kindware.dev](https://kindware.dev)**
