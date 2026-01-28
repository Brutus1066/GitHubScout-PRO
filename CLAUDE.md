# GitHubScout - Project Spec

## Overview
Fast, polished CLI for GitHub repository discovery.
Menu-driven PowerShell with modern ASCII art branding.

## Branding
```
    ██╗  ██╗██╗███╗   ██╗██████╗ ██╗    ██╗ █████╗ ██████╗ ███████╗
    ██║ ██╔╝██║████╗  ██║██╔══██╗██║    ██║██╔══██╗██╔══██╗██╔════╝
    █████╔╝ ██║██╔██╗ ██║██║  ██║██║ █╗ ██║███████║██████╔╝█████╗  
    ██╔═██╗ ██║██║╚██╗██║██║  ██║██║███╗██║██╔══██║██╔══██╗██╔══╝  
    ██║  ██╗██║██║ ╚████║██████╔╝╚███╔███╔╝██║  ██║██║  ██║███████╗
    ╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝╚═════╝  ╚══╝╚══╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝

                    ◆ GitHubScout v2.1.0
              ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
               ⚡ Fast GitHub Repository Discovery
               created by LazyFrog-kz | kindware.dev
```

## Architecture

```
GitHubScout/
├── GitHubScout.ps1              # Main app (~500 lines)
├── LazyFrog-GitHubScout.bat     # Launcher (auto-installs PS7)
├── Install-Shortcut.bat         # Desktop shortcut creator
├── Generate-Icon.ps1            # Icon generator
├── GitHubScout.ico              # App icon
├── config.json                  # Settings
├── tracked.json                 # Saved repos (auto-created)
├── LICENSE                      # MIT License
└── README.md                    # Documentation
```

## Menu System

```
    ╭─────────────────────────────────╮
    │  [1] 🔍 Search GitHub           │
    │  [2] 📌 Tracked Repos           │
    │  [3] 🔎 Inspect Repo            │
    │  [4] ❓ Help                    │
    │  [Q]    Quit                    │
    ╰─────────────────────────────────╯
```

## Features

1. **Search** - Query, language filter, min stars, open/track/inspect from results
2. **Track** - Save repos, refresh stats, manage tracked list
3. **Inspect** - View details, scrollable README viewer
4. **Help** - Quick reference with commands

## Key Principles

- PowerShell 7+ with ANSI escape codes for colors
- Modern Unicode box-drawing characters
- Rainbow ASCII art logo
- Emoji icons for visual appeal
- Simple menu/function pattern
- Graceful error handling

## Files

| File | Purpose |
|------|---------|
| GitHubScout.ps1 | Main application |
| LazyFrog-GitHubScout.bat | Launcher (auto-installs PS7) |
| Install-Shortcut.bat | Desktop shortcut creator |
| Generate-Icon.ps1 | Icon generator |
| GitHubScout.ico | App icon |
| config.json | Token & settings |
| tracked.json | User's tracked repos |

## Requirements

- PowerShell 7.0+
- Windows 10/11
- Internet connection
- GitHub token (optional, recommended)

## API Rate Limits

- Without token: 60/hour
- With token: 5,000/hour

## Quality Rules

- No syntax errors
- No missing functions
- Handle API failures gracefully
- Works in Windows Terminal + cmd
- Clean exit with branding

## Code Style

- Well-commented with author info
- MIT License headers
- Professional ANSI-colored output
- Consistent branding throughout
- GitHub-ready documentation

## Author

**LazyFrog-kz** @ [Kindware](https://kindware.dev)
License: MIT
