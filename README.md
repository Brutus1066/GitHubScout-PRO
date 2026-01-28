<p align="center">
  <img src="https://img.shields.io/badge/PowerShell-7.0%2B-5391FE?style=for-the-badge&logo=powershell&logoColor=white" alt="PowerShell 7+">
  <img src="https://img.shields.io/badge/CLI-Terminal-4EAA25?style=for-the-badge&logo=windowsterminal&logoColor=white" alt="CLI">
  <img src="https://img.shields.io/badge/Platform-Windows-0078D6?style=for-the-badge&logo=windows&logoColor=white" alt="Windows">
  <img src="https://img.shields.io/github/license/Brutus1066/GitHubScout-PRO?style=flat-square" alt="License">
  <img src="https://img.shields.io/github/stars/Brutus1066/GitHubScout-PRO?style=flat-square" alt="Stars">
</p>

<h1 align="center">⚡ GitHubScout</h1>

<p align="center">
  <strong>Lightning-fast CLI for GitHub Repository Discovery</strong>
</p>

<p align="center">
  <a href="#-features">Features</a> •
  <a href="#-screenshots">Screenshots</a> •
  <a href="#-installation">Installation</a> •
  <a href="#-usage">Usage</a> •
  <a href="#-commands">Commands</a>
</p>

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

---

## 💡 Why GitHubScout?

**The Problem:** You want to quickly search, track, and inspect GitHub repositories from the terminal without using clunky web interfaces.

**The Solution:** One app, instant results. Search by keyword, language, stars. Track repos over time. Read READMEs with scrolling. All from a beautiful rainbow CLI.

---

## ✨ Features

| Feature | Description |
|---------|-------------|
| 🔍 **Search** | Find repos by keyword, language, and star count |
| 📌 **Track** | Save repos and monitor their stats over time |
| 🔎 **Inspect** | View detailed repo info with scrollable README |
| ⚡ **Fast** | Lightweight menu-driven CLI - no complex TUI |
| 🌈 **Beautiful** | Rainbow KINDWARE branding with Unicode art |
| 🔌 **Offline Tracking** | Your tracked repos saved locally |

---

## 📸 Screenshots

| Main Menu | Search Results |
|-----------|----------------|
| ![Menu](screenshots/Menu.Screenshot.png) | ![Search](screenshots/SEARCHGITHUBScreenshot.png) |

| Tracked Repos | README Viewer |
|---------------|---------------|
| ![Tracked](screenshots/TrackedReposScreenshot.png) | ![README](screenshots/ReadmeBrutusScreenshot.png) |

| Help Menu | Desktop Shortcut |
|-----------|------------------|
| ![Help](screenshots/HelpMenuScreenshot.png) | ![Desktop](screenshots/DesktopScreenshot.png) |

---

## 📦 Installation

### Option 1: Pre-built Installer (Easiest)

> No setup required! Download, run, done.

1. Go to [Releases](https://github.com/Brutus1066/GitHubScout-PRO/releases)
2. Download `GitHubScout-v2.1.0-Setup.zip`
3. Extract and run `GitHubScout-Setup.exe`
4. Follow the installer prompts

| File | Size | Description |
|------|------|-------------|
| `GitHubScout-Setup.exe` | ~1 MB | Installer with auto PS7 setup |
| `GitHubScout-v2.1.0-portable.zip` | ~50 KB | Portable - just extract and run |

### Option 2: Clone & Run

```powershell
git clone https://github.com/Brutus1066/GitHubScout-PRO.git
cd GitHubScout-PRO
.\LazyFrog-GitHubScout.bat
```

> The launcher auto-installs PowerShell 7 if needed!

---

## 📋 Requirements

- **PowerShell 7.0+** (auto-installed by launcher)
- **Windows 10/11**
- Internet connection

### Installing PowerShell 7 Manually

```powershell
winget install Microsoft.PowerShell
```

Or download from [https://aka.ms/powershell](https://aka.ms/powershell)

---

## 🚀 Usage

### Main Menu
```
    ╭─────────────────────────────────╮
    │  [1] 🔍 Search GitHub           │
    │  [2] 📌 Tracked Repos           │
    │  [3] 🔎 Inspect Repo            │
    │  [4] ❓ Help                    │
    │  [Q]    Quit                    │
    ╰─────────────────────────────────╯
```

### Search Results
```
  Found 3 repos:

  [ 1] cli/cli                              47.2K*  Go
  [ 2] sharkdp/bat                          45.1K*  Rust
  [ 3] BurntSushi/ripgrep                   42.8K*  Rust

  Commands: T1=Track  O1=Open  I1=Inspect
  > O1
  Opening: https://github.com/cli/cli
  Opened in browser!
```

---

## 📋 Commands

### In Search Results

| Command | Action |
|---------|--------|
| `1`, `2`, `3`... | Inspect that repo |
| `O1`, `O2`... | Open in browser |
| `T1`, `T2`... | Track the repo |
| `Enter` | Go back |

### In README Viewer

| Key | Action |
|-----|--------|
| `↑` / `↓` | Scroll up/down |
| `PgUp` / `PgDn` | Page up/down |
| `Q` or `Enter` | Exit viewer |

---

## ⚙️ Configuration

Edit `config.json`:

```json
{
  "GitHubToken": "ghp_your_token_here",
  "DefaultSort": "updated",
  "ResultsPerPage": 10
}
```

### GitHub Token (Recommended)

| Mode | Rate Limit |
|------|-----------|
| Without token | 60 requests/hour |
| **With token** | **5,000 requests/hour** |

1. Go to [github.com/settings/tokens](https://github.com/settings/tokens)
2. Generate new token (classic)
3. Select `public_repo` scope only
4. Add to `config.json`

---

## 📁 Project Structure

```
GitHubScout/
├── GitHubScout.ps1              # Main application
├── LazyFrog-GitHubScout.bat     # Launcher (auto-installs PS7)
├── GitHubScout.ico              # App icon
├── config.json                  # Settings & token
├── tracked.json                 # Your tracked repos (auto-created)
├── LICENSE                      # MIT License
└── README.md                    # This file
```

---

## 🔧 Troubleshooting

| Issue | Solution |
|-------|----------|
| "Rate limit exceeded" | Add GitHub token to `config.json` |
| "Requires PowerShell 7+" | Run the .bat launcher - it auto-installs |
| Colors look wrong | Use Windows Terminal for best experience |
| Installer won't run | Right-click → Run as Administrator |

---

## 📊 Technical Details

| | |
|---|---|
| **Language** | PowerShell 7 |
| **UI** | ANSI colors + Unicode box drawing |
| **API** | GitHub REST API v3 |
| **Storage** | Local JSON files |
| **Network** | Only for GitHub API calls |

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit issues and pull requests.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing`)
5. Open a Pull Request

---

## 📄 License

MIT License - see [LICENSE](LICENSE) for details.

---

<p align="center">
  Made with ❤️ by <a href="https://github.com/Brutus1066">Brutus1066</a> at <a href="https://kindware.dev">LAZYFROG-kindware.dev</a>
</p>

<p align="center">
  <a href="https://github.com/Brutus1066/GitHubScout-PRO/stargazers">⭐ Star this repo</a> if you find it useful!
</p>
