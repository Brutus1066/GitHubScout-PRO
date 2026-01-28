#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Kindware GitHubScout - Installer Script
    
.DESCRIPTION
    This installer extracts GitHubScout to the user's chosen location,
    creates desktop and Start Menu shortcuts with the custom icon.
    Must be run with PowerShell 7+ (via the batch launcher).

.NOTES
    Author:  LazyFrog-kz
    Company: Kindware (kindware.dev)
    Version: 2.1.0
    License: MIT License
#>

# ============================================================================
# INSTALLER CONFIGURATION
# ============================================================================
$ErrorActionPreference = "Stop"
$AppName = "GitHubScout"
$AppVersion = "2.1.0"
$Company = "Kindware"
$Author = "LazyFrog-kz"

# Get script location
$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent ([Environment]::GetCommandLineArgs()[0]) }
if (-not $ScriptDir -or $ScriptDir -eq "") { $ScriptDir = Get-Location }

# ============================================================================
# UI FUNCTIONS (PS7 with ANSI colors)
# ============================================================================

function Show-InstallerBanner {
    Clear-Host
    Write-Host ""
    Write-Host "    `e[96m╔═══════════════════════════════════════════════════════════╗`e[0m"
    Write-Host "    `e[96m║`e[0m                                                           `e[96m║`e[0m"
    Write-Host "    `e[96m║`e[0m   `e[93m██╗  ██╗██╗███╗   ██╗██████╗ ██╗    ██╗ █████╗ ██████╗ `e[0m  `e[96m║`e[0m"
    Write-Host "    `e[96m║`e[0m   `e[93m██║ ██╔╝██║████╗  ██║██╔══██╗██║    ██║██╔══██╗██╔══██╗`e[0m  `e[96m║`e[0m"
    Write-Host "    `e[96m║`e[0m   `e[93m█████╔╝ ██║██╔██╗ ██║██║  ██║██║ █╗ ██║███████║██████╔╝`e[0m  `e[96m║`e[0m"
    Write-Host "    `e[96m║`e[0m   `e[93m██╔═██╗ ██║██║╚██╗██║██║  ██║██║███╗██║██╔══██║██╔══██╗`e[0m  `e[96m║`e[0m"
    Write-Host "    `e[96m║`e[0m   `e[93m██║  ██╗██║██║ ╚████║██████╔╝╚███╔███╔╝██║  ██║██║  ██║`e[0m  `e[96m║`e[0m"
    Write-Host "    `e[96m║`e[0m   `e[93m╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝╚═════╝  ╚══╝╚══╝ ╚═╝  ╚═╝╚═╝  ╚═╝`e[0m  `e[96m║`e[0m"
    Write-Host "    `e[96m║`e[0m                                                           `e[96m║`e[0m"
    Write-Host "    `e[96m║`e[0m          `e[92m◆ GitHubScout Installer v$AppVersion`e[0m               `e[96m║`e[0m"
    Write-Host "    `e[96m║`e[0m          `e[90mcreated by $Author | kindware.dev`e[0m          `e[96m║`e[0m"
    Write-Host "    `e[96m║`e[0m                                                           `e[96m║`e[0m"
    Write-Host "    `e[96m╚═══════════════════════════════════════════════════════════╝`e[0m"
    Write-Host ""
}

function Install-GitHubScout {
    param(
        [string]$InstallPath,
        [string]$SourcePath
    )
    
    Write-Host "  `e[93m[1/4]`e[0m Creating installation directory..." -NoNewline
    if (-not (Test-Path $InstallPath)) {
        New-Item -ItemType Directory -Path $InstallPath -Force | Out-Null
    }
    Write-Host " `e[92m✔`e[0m"
    
    Write-Host "  `e[93m[2/4]`e[0m Copying files..." -NoNewline
    $files = @(
        "GitHubScout.ps1",
        "LazyFrog-GitHubScout.bat",
        "GitHubScout.ico",
        "config.json",
        "README.md",
        "LICENSE"
    )
    
    foreach ($file in $files) {
        $src = Join-Path $SourcePath $file
        if (Test-Path $src) {
            Copy-Item $src -Destination $InstallPath -Force
        }
    }
    Write-Host " `e[92m✔`e[0m"
    
    Write-Host "  `e[93m[3/4]`e[0m Creating desktop shortcut..." -NoNewline
    $DesktopPath = [Environment]::GetFolderPath("Desktop")
    $ShortcutPath = Join-Path $DesktopPath "GitHubScout.lnk"
    $TargetPath = Join-Path $InstallPath "LazyFrog-GitHubScout.bat"
    $IconPath = Join-Path $InstallPath "GitHubScout.ico"
    
    $WshShell = New-Object -ComObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut($ShortcutPath)
    $Shortcut.TargetPath = $TargetPath
    $Shortcut.WorkingDirectory = $InstallPath
    $Shortcut.Description = "Kindware GitHubScout - Fast GitHub Discovery"
    $Shortcut.IconLocation = "$IconPath,0"
    $Shortcut.Save()
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($WshShell) | Out-Null
    Write-Host " `e[92m✔`e[0m"
    
    Write-Host "  `e[93m[4/4]`e[0m Creating Start Menu shortcut..." -NoNewline
    $StartMenuPath = Join-Path ([Environment]::GetFolderPath("StartMenu")) "Programs\Kindware"
    if (-not (Test-Path $StartMenuPath)) {
        New-Item -ItemType Directory -Path $StartMenuPath -Force | Out-Null
    }
    $StartShortcut = Join-Path $StartMenuPath "GitHubScout.lnk"
    
    $WshShell2 = New-Object -ComObject WScript.Shell
    $Shortcut2 = $WshShell2.CreateShortcut($StartShortcut)
    $Shortcut2.TargetPath = $TargetPath
    $Shortcut2.WorkingDirectory = $InstallPath
    $Shortcut2.Description = "Kindware GitHubScout - Fast GitHub Discovery"
    $Shortcut2.IconLocation = "$IconPath,0"
    $Shortcut2.Save()
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($WshShell2) | Out-Null
    Write-Host " `e[92m✔`e[0m"
    
    return $true
}

# ============================================================================
# MAIN INSTALLER
# ============================================================================

Show-InstallerBanner

Write-Host "  Welcome to the GitHubScout installer!"
Write-Host ""
Write-Host "  This will install:"
Write-Host "    `e[92m•`e[0m GitHubScout application"
Write-Host "    `e[92m•`e[0m Desktop shortcut with custom icon"
Write-Host "    `e[92m•`e[0m Start Menu shortcut"
Write-Host ""

# Default install location
$DefaultPath = Join-Path $env:LOCALAPPDATA "Kindware\GitHubScout"
Write-Host "  Default location: `e[96m$DefaultPath`e[0m"
Write-Host ""

$customPath = Read-Host "  Install location (Enter for default)"
if ([string]::IsNullOrWhiteSpace($customPath)) {
    $InstallPath = $DefaultPath
} else {
    $InstallPath = $customPath
}

Write-Host ""
Write-Host "  Installing to: `e[96m$InstallPath`e[0m"
Write-Host ""

$confirm = Read-Host "  Proceed with installation? (Y/N)"
if ($confirm -notmatch '^[Yy]') {
    Write-Host ""
    Write-Host "  `e[93mInstallation cancelled.`e[0m"
    Write-Host ""
    Read-Host "  Press Enter to exit"
    exit 0
}

Write-Host ""

try {
    $result = Install-GitHubScout -InstallPath $InstallPath -SourcePath $ScriptDir
    
    Write-Host ""
    Write-Host "  `e[92m╔═══════════════════════════════════════════════════╗`e[0m"
    Write-Host "  `e[92m║         INSTALLATION COMPLETE! ✔                  ║`e[0m"
    Write-Host "  `e[92m╚═══════════════════════════════════════════════════╝`e[0m"
    Write-Host ""
    Write-Host "  GitHubScout has been installed to:"
    Write-Host "    `e[96m$InstallPath`e[0m"
    Write-Host ""
    Write-Host "  Shortcuts created:"
    Write-Host "    `e[92m•`e[0m Desktop: GitHubScout"
    Write-Host "    `e[92m•`e[0m Start Menu: Kindware > GitHubScout"
    Write-Host ""
    Write-Host "  `e[93mDouble-click the desktop icon to launch!`e[0m"
    Write-Host ""
    
    $launch = Read-Host "  Launch GitHubScout now? (Y/N)"
    if ($launch -match '^[Yy]') {
        $batPath = Join-Path $InstallPath "LazyFrog-GitHubScout.bat"
        Start-Process $batPath
    }
    
} catch {
    Write-Host ""
    Write-Host "  `e[91m✖ Installation failed: $_`e[0m"
    Write-Host ""
    Read-Host "  Press Enter to exit"
    exit 1
}

Write-Host ""
Write-Host "  Thanks for installing Kindware GitHubScout!"
Write-Host "  `e[90mcreated by $Author | kindware.dev`e[0m"
Write-Host ""
