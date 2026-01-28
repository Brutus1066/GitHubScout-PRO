#!/usr/bin/env pwsh
#Requires -Version 7.0
<#
.SYNOPSIS
    Build script for LazyFrog GitHubScout
.DESCRIPTION
    Creates an executable installer for LazyFrog GitHubScout using ps2exe.
    Also creates desktop and Start Menu shortcuts.
.NOTES
    Author: Kindware.dev
    Version: 1.0.0
#>

[CmdletBinding()]
param(
    [switch]$SkipExe,
    [switch]$CreateShortcuts,
    [string]$OutputDir = ""
)

$ErrorActionPreference = "Stop"

# ============================================================================
# Configuration
# ============================================================================
$script:Config = @{
    AppName     = "LazyFrog GitHubScout"
    Version     = "1.0.0"
    Publisher   = "Kindware.dev"
    Description = "A fast, lightweight GitHub TUI for Windows Terminal"
    RootDir     = Split-Path -Parent $PSScriptRoot
    IconPath    = ""
}

# Find icon
$possibleIconPaths = @(
    (Join-Path $script:Config.RootDir "desktop.launcher.icon.ico" "icon.ico"),
    (Join-Path $script:Config.RootDir "icon.ico"),
    (Join-Path $script:Config.RootDir "assets" "icon.ico")
)

foreach ($path in $possibleIconPaths) {
    if (Test-Path $path) {
        $script:Config.IconPath = $path
        break
    }
}

# Output directory
if (-not $OutputDir) {
    $OutputDir = Join-Path $script:Config.RootDir "build"
}

# ============================================================================
# Helper Functions
# ============================================================================
function Write-Status {
    param(
        [string]$Message,
        [ValidateSet("Info", "Success", "Warning", "Error")]
        [string]$Type = "Info"
    )

    $colors = @{
        Info    = "Cyan"
        Success = "Green"
        Warning = "Yellow"
        Error   = "Red"
    }

    $prefixes = @{
        Info    = "[*]"
        Success = "[+]"
        Warning = "[!]"
        Error   = "[-]"
    }

    Write-Host "$($prefixes[$Type]) $Message" -ForegroundColor $colors[$Type]
}

function Test-Administrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]$identity
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Test-Ps2Exe {
    try {
        $null = Get-Command ps2exe -ErrorAction Stop
        return $true
    }
    catch {
        return $false
    }
}

function Install-Ps2Exe {
    Write-Status "Installing ps2exe module..." -Type Info

    try {
        Install-Module -Name ps2exe -Scope CurrentUser -Force -AllowClobber
        Write-Status "ps2exe installed successfully" -Type Success
        return $true
    }
    catch {
        Write-Status "Failed to install ps2exe: $_" -Type Error
        return $false
    }
}

# ============================================================================
# Build Functions
# ============================================================================
function Build-Executable {
    Write-Status "Building executable..." -Type Info

    # Ensure output directory exists
    if (-not (Test-Path $OutputDir)) {
        New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
    }

    $mainScript = Join-Path $script:Config.RootDir "src" "main.ps1"
    $outputExe = Join-Path $OutputDir "LazyFrogGitHubScout.exe"

    if (-not (Test-Path $mainScript)) {
        Write-Status "Main script not found: $mainScript" -Type Error
        return $false
    }

    # Build ps2exe parameters
    $ps2exeParams = @{
        InputFile   = $mainScript
        OutputFile  = $outputExe
        NoConsole   = $false
        RequireAdmin = $false
        Title       = $script:Config.AppName
        Description = $script:Config.Description
        Company     = $script:Config.Publisher
        Version     = $script:Config.Version
        Copyright   = "Copyright (c) $(Get-Date -Format yyyy) $($script:Config.Publisher)"
    }

    if ($script:Config.IconPath -and (Test-Path $script:Config.IconPath)) {
        $ps2exeParams["IconFile"] = $script:Config.IconPath
    }

    try {
        # Note: ps2exe has issues with module imports
        # For a full build, we need to create a single-file version
        Write-Status "Creating bundled script..." -Type Info

        $bundledScript = Join-Path $OutputDir "LazyFrogGitHubScout-bundled.ps1"
        Create-BundledScript -OutputPath $bundledScript

        # Update input to bundled script
        $ps2exeParams["InputFile"] = $bundledScript

        Invoke-ps2exe @ps2exeParams

        Write-Status "Executable created: $outputExe" -Type Success
        return $true
    }
    catch {
        Write-Status "Failed to build executable: $_" -Type Error
        return $false
    }
}

function Create-BundledScript {
    param([string]$OutputPath)

    $rootDir = $script:Config.RootDir
    $libDir = Join-Path $rootDir "src" "lib"
    $toolsDir = Join-Path $rootDir "src" "tools"

    $modules = @(
        (Join-Path $libDir "ui.ps1"),
        (Join-Path $libDir "input.ps1"),
        (Join-Path $libDir "storage.ps1"),
        (Join-Path $libDir "github.ps1"),
        (Join-Path $toolsDir "search.ps1"),
        (Join-Path $toolsDir "tracker.ps1"),
        (Join-Path $toolsDir "inspector.ps1"),
        (Join-Path $toolsDir "help.ps1")
    )

    $mainScript = Join-Path $rootDir "src" "main.ps1"

    $sb = [System.Text.StringBuilder]::new()

    [void]$sb.AppendLine("#!/usr/bin/env pwsh")
    [void]$sb.AppendLine("#Requires -Version 7.0")
    [void]$sb.AppendLine("# LazyFrog GitHubScout - Bundled Version")
    [void]$sb.AppendLine("# Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
    [void]$sb.AppendLine("")

    # Bundle modules
    foreach ($module in $modules) {
        if (Test-Path $module) {
            $content = Get-Content $module -Raw
            # Remove Export-ModuleMember lines
            $content = $content -replace 'Export-ModuleMember.*$', ''
            [void]$sb.AppendLine("# === Module: $(Split-Path -Leaf $module) ===")
            [void]$sb.AppendLine($content)
            [void]$sb.AppendLine("")
        }
    }

    # Bundle main script (excluding module loading)
    if (Test-Path $mainScript) {
        $mainContent = Get-Content $mainScript -Raw

        # Remove the Initialize-Application module loading section
        $mainContent = $mainContent -replace '(?s)function Initialize-Application \{.*?\n\}', @'
function Initialize-Application {
    # Modules are bundled inline
    $script:DataDir = $PSScriptRoot
    if (-not $script:DataDir) { $script:DataDir = $PWD.Path }

    Initialize-Storage -BaseDir $script:DataDir
    Initialize-GitHubAuth
}
'@

        [void]$sb.AppendLine("# === Main Application ===")
        [void]$sb.AppendLine($mainContent)
    }

    # Write bundled script
    [System.IO.File]::WriteAllText($OutputPath, $sb.ToString(), [System.Text.UTF8Encoding]::new($false))
    Write-Status "Bundled script created: $OutputPath" -Type Success
}

function Create-Shortcuts {
    Write-Status "Creating shortcuts..." -Type Info

    $exePath = Join-Path $OutputDir "LazyFrogGitHubScout.exe"
    $scriptPath = Join-Path $script:Config.RootDir "src" "main.ps1"

    # Use script path if exe doesn't exist
    $targetPath = if (Test-Path $exePath) { $exePath } else { $scriptPath }
    $targetArgs = if (Test-Path $exePath) { "" } else { "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`"" }

    # Desktop shortcut
    $desktopPath = [Environment]::GetFolderPath("Desktop")
    $desktopShortcut = Join-Path $desktopPath "LazyFrog GitHubScout.lnk"

    try {
        $shell = New-Object -ComObject WScript.Shell
        $shortcut = $shell.CreateShortcut($desktopShortcut)

        if (Test-Path $exePath) {
            $shortcut.TargetPath = $exePath
        } else {
            $shortcut.TargetPath = "pwsh.exe"
            $shortcut.Arguments = $targetArgs
        }

        $shortcut.WorkingDirectory = $script:Config.RootDir
        $shortcut.Description = $script:Config.Description

        if ($script:Config.IconPath -and (Test-Path $script:Config.IconPath)) {
            $shortcut.IconLocation = $script:Config.IconPath
        }

        $shortcut.Save()
        Write-Status "Desktop shortcut created" -Type Success
    }
    catch {
        Write-Status "Failed to create desktop shortcut: $_" -Type Warning
    }

    # Start Menu shortcut
    $startMenuPath = Join-Path ([Environment]::GetFolderPath("StartMenu")) "Programs"
    $startMenuShortcut = Join-Path $startMenuPath "LazyFrog GitHubScout.lnk"

    try {
        $shortcut = $shell.CreateShortcut($startMenuShortcut)

        if (Test-Path $exePath) {
            $shortcut.TargetPath = $exePath
        } else {
            $shortcut.TargetPath = "pwsh.exe"
            $shortcut.Arguments = $targetArgs
        }

        $shortcut.WorkingDirectory = $script:Config.RootDir
        $shortcut.Description = $script:Config.Description

        if ($script:Config.IconPath -and (Test-Path $script:Config.IconPath)) {
            $shortcut.IconLocation = $script:Config.IconPath
        }

        $shortcut.Save()
        Write-Status "Start Menu shortcut created" -Type Success
    }
    catch {
        Write-Status "Failed to create Start Menu shortcut: $_" -Type Warning
    }
}

function Create-LauncherBat {
    <#
    .SYNOPSIS
    Creates a simple .bat launcher for users without ps2exe
    #>

    $batPath = Join-Path $script:Config.RootDir "LazyFrog-GitHubScout.bat"
    $scriptPath = Join-Path $script:Config.RootDir "src" "main.ps1"

    $batContent = @"
@echo off
title LazyFrog GitHubScout
pwsh -NoProfile -ExecutionPolicy Bypass -File "%~dp0src\main.ps1"
if errorlevel 1 pause
"@

    [System.IO.File]::WriteAllText($batPath, $batContent)
    Write-Status "Launcher batch file created: $batPath" -Type Success
}

# ============================================================================
# Main
# ============================================================================
function Main {
    Write-Host ""
    Write-Host "  LazyFrog GitHubScout - Build Script" -ForegroundColor Cyan
    Write-Host "  ===================================" -ForegroundColor Cyan
    Write-Host ""

    # Check PowerShell version
    if ($PSVersionTable.PSVersion.Major -lt 7) {
        Write-Status "PowerShell 7+ required. Current: $($PSVersionTable.PSVersion)" -Type Error
        exit 1
    }

    # Always create the launcher batch file
    Create-LauncherBat

    # Build executable if not skipped
    if (-not $SkipExe) {
        if (-not (Test-Ps2Exe)) {
            Write-Status "ps2exe not found" -Type Warning
            $install = Read-Host "Install ps2exe module? (y/n)"
            if ($install -eq 'y') {
                if (-not (Install-Ps2Exe)) {
                    Write-Status "Skipping exe build" -Type Warning
                    $SkipExe = $true
                }
            } else {
                $SkipExe = $true
            }
        }

        if (-not $SkipExe) {
            Build-Executable
        }
    }

    # Create shortcuts
    if ($CreateShortcuts) {
        Create-Shortcuts
    }

    Write-Host ""
    Write-Status "Build complete!" -Type Success
    Write-Host ""
    Write-Host "  To run LazyFrog GitHubScout:"
    Write-Host "    pwsh src/main.ps1" -ForegroundColor Yellow
    Write-Host "  Or use the batch file:"
    Write-Host "    LazyFrog-GitHubScout.bat" -ForegroundColor Yellow
    Write-Host ""
}

Main
