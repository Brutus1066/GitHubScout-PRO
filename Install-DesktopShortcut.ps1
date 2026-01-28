#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Creates a desktop shortcut for Kindware GitHubScout with custom icon

.DESCRIPTION
    This script creates a desktop shortcut that:
    - Uses the bundled .ico file if present
    - Works after reboot (uses absolute paths)
    - Launches GitHubScout via PowerShell 7

.NOTES
    Author:  LazyFrog-kz
    Company: Kindware (kindware.dev)
    License: MIT License
#>

$ErrorActionPreference = "Stop"

# Paths
$ScriptDir = $PSScriptRoot
$DesktopPath = [Environment]::GetFolderPath("Desktop")
$ShortcutPath = Join-Path $DesktopPath "GitHubScout.lnk"
$BatPath = Join-Path $ScriptDir "LazyFrog-GitHubScout.bat"
$IcoPath = Join-Path $ScriptDir "GitHubScout.ico"

Write-Host ""
Write-Host "  ╔═══════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "  ║  Kindware GitHubScout - Shortcut Install  ║" -ForegroundColor Cyan
Write-Host "  ╚═══════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Check if icon exists
if (-not (Test-Path $IcoPath)) {
    Write-Host "  [!] Icon not found at: $IcoPath" -ForegroundColor Yellow
    Write-Host "  [i] Creating shortcut without custom icon..." -ForegroundColor DarkGray
    $IcoPath = $null
}

# Create shortcut using WScript.Shell COM object
try {
    $WshShell = New-Object -ComObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut($ShortcutPath)
    $Shortcut.TargetPath = $BatPath
    $Shortcut.WorkingDirectory = $ScriptDir
    $Shortcut.Description = "Kindware GitHubScout - Fast GitHub Repository Discovery"
    $Shortcut.WindowStyle = 1  # Normal window
    
    if ($IcoPath -and (Test-Path $IcoPath)) {
        $Shortcut.IconLocation = "$IcoPath,0"
        Write-Host "  [✓] Using custom icon: GitHubScout.ico" -ForegroundColor Green
    } else {
        # Use PowerShell icon as fallback
        $pwshPath = (Get-Command pwsh -ErrorAction SilentlyContinue).Source
        if ($pwshPath) {
            $Shortcut.IconLocation = "$pwshPath,0"
        }
    }
    
    $Shortcut.Save()
    
    Write-Host ""
    Write-Host "  [✓] Desktop shortcut created successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "  Location: $ShortcutPath" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  Double-click 'GitHubScout' on your desktop to launch!" -ForegroundColor Cyan
    Write-Host ""
    
} catch {
    Write-Host "  [✖] Failed to create shortcut: $_" -ForegroundColor Red
    exit 1
}

# Cleanup COM object
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($WshShell) | Out-Null

Write-Host "  Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
