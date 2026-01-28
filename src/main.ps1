#!/usr/bin/env pwsh
#Requires -Version 7.0
<#
.SYNOPSIS
    Kindware.dev GitHubScout - A fast, lightweight GitHub TUI for Windows Terminal
.DESCRIPTION
    Main entry point for the GitHubScout application.
    Provides a terminal user interface for searching, tracking, and inspecting GitHub repositories.
.NOTES
    Author: Kindware.dev (created by LazyFrog)
    Version: 1.0.0
    Requires: PowerShell 7.0+
#>

[CmdletBinding()]
param(
    [switch]$NoColor
)

# ============================================================================
# Script Setup
# ============================================================================
$ErrorActionPreference = "Stop"
$script:AppVersion = "1.0.0"
$script:AppName = "Kindware.dev GitHubScout"
$script:ScriptRoot = $PSScriptRoot

# ============================================================================
# Module Loading - MUST BE FIRST
# ============================================================================
function Initialize-Modules {
    $libPath = Join-Path $script:ScriptRoot "lib"
    $toolsPath = Join-Path $script:ScriptRoot "tools"

    $modules = @(
        (Join-Path $libPath "ui.ps1"),
        (Join-Path $libPath "input.ps1"),
        (Join-Path $libPath "storage.ps1"),
        (Join-Path $libPath "github.ps1"),
        (Join-Path $toolsPath "search.ps1"),
        (Join-Path $toolsPath "tracker.ps1"),
        (Join-Path $toolsPath "inspector.ps1"),
        (Join-Path $toolsPath "help.ps1")
    )

    foreach ($modulePath in $modules) {
        if (Test-Path $modulePath) {
            . $modulePath
        } else {
            throw "Module not found: $modulePath"
        }
    }

    # Initialize storage and auth
    Initialize-Storage -BaseDir $libPath
    Initialize-GitHubAuth
}

# ============================================================================
# Main UI State
# ============================================================================
$script:AppState = @{
    Running      = $true
    CurrentTool  = 0
    Message      = ""
}

function Show-MainUI {
    $c = $Global:Colors
    $size = Get-ConsoleSize

    if ($size.Width -lt 80 -or $size.Height -lt 24) {
        Clear-Host
        Write-Host "`n  Window too small. Please resize to at least 80x24." -ForegroundColor Red
        Write-Host "  Current size: $($size.Width)x$($size.Height)" -ForegroundColor Yellow
        return $false
    }

    Clear-Screen
    Hide-Cursor

    $headerHeight = 3
    $footerHeight = 1
    $menuWidth = 16
    $mainPanelX = $menuWidth
    $mainPanelY = $headerHeight
    $mainPanelWidth = $size.Width - $menuWidth
    $mainPanelHeight = $size.Height - $headerHeight - $footerHeight

    Show-Header -Width $size.Width
    Show-Menu -X 0 -Y $headerHeight -Width $menuWidth -Height ($size.Height - $headerHeight - $footerHeight) -SelectedIndex $script:AppState.CurrentTool
    Draw-Box -X $mainPanelX -Y $mainPanelY -Width $mainPanelWidth -Height $mainPanelHeight -Color $c.White
    Show-StatusBar -Y ($size.Height - 1) -Width $size.Width -Message $script:AppState.Message

    return @{
        PanelX      = $mainPanelX + 1
        PanelY      = $mainPanelY + 1
        PanelWidth  = $mainPanelWidth - 2
        PanelHeight = $mainPanelHeight - 2
    }
}

function Run-CurrentTool {
    param([hashtable]$Panel)

    switch ($script:AppState.CurrentTool) {
        0 { Show-SearchTool -PanelX $Panel.PanelX -PanelY $Panel.PanelY -PanelWidth $Panel.PanelWidth -PanelHeight $Panel.PanelHeight }
        1 { Show-TrackerTool -PanelX $Panel.PanelX -PanelY $Panel.PanelY -PanelWidth $Panel.PanelWidth -PanelHeight $Panel.PanelHeight }
        2 { Show-InspectorTool -PanelX $Panel.PanelX -PanelY $Panel.PanelY -PanelWidth $Panel.PanelWidth -PanelHeight $Panel.PanelHeight }
        3 { Show-HelpTool -PanelX $Panel.PanelX -PanelY $Panel.PanelY -PanelWidth $Panel.PanelWidth -PanelHeight $Panel.PanelHeight }
    }
}

function Show-SplashScreen {
    Clear-Host
    $c = $Global:Colors

    Write-Host ""
    Write-Host "  $($c.BrightGreen)  _                     _____$($c.Reset)"
    Write-Host "  $($c.BrightGreen) | |    __ _ _____   _|  ___| __ ___   __ _$($c.Reset)"
    Write-Host "  $($c.BrightGreen) | |   / _' |_  / | | | |_ | '__/ _ \ / _' |$($c.Reset)"
    Write-Host "  $($c.BrightGreen) | |__| (_| |/ /| |_| |  _|| | | (_) | (_| |$($c.Reset)"
    Write-Host "  $($c.BrightGreen) |_____\__,_/___|\__, |_|  |_|  \___/ \__, |$($c.Reset)"
    Write-Host "  $($c.BrightGreen)                 |___/                |___/$($c.Reset)"
    Write-Host ""
    Write-Host "  $($c.BrightCyan)GitHubScout$($c.Reset) $($c.Dim)v$script:AppVersion$($c.Reset)"
    Write-Host "  $($c.Dim)powered by$($c.Reset) $($c.BrightMagenta)Kindware.dev$($c.Reset) $($c.Dim)(created by LazyFrog)$($c.Reset)"
    Write-Host ""
    Write-Host "  $($c.BrightGreen)[OK]$($c.Reset) Ready!"
    Start-Sleep -Milliseconds 800
}

function Exit-Application {
    Show-Cursor
    Clear-Host
    $c = $Global:Colors
    Write-Host ""
    Write-Host "  $($c.BrightGreen)Thanks for using Kindware.dev GitHubScout!$($c.Reset)"
    Write-Host "  $($c.Dim)created by LazyFrog$($c.Reset)"
    Write-Host ""
}

# ============================================================================
# Main Entry Point
# ============================================================================
function Main {
    # Check PowerShell version
    if ($PSVersionTable.PSVersion.Major -lt 7) {
        Write-Host "`nKindware.dev GitHubScout requires PowerShell 7 or later." -ForegroundColor Red
        Write-Host "Current version: $($PSVersionTable.PSVersion)" -ForegroundColor Yellow
        Write-Host "`nInstall from: https://aka.ms/powershell`n" -ForegroundColor Cyan
        exit 1
    }

    # LOAD MODULES FIRST - before using any colors or functions
    try {
        Initialize-Modules
    }
    catch {
        Write-Host "Failed to load modules: $_" -ForegroundColor Red
        Write-Host "Press any key to exit..."
        [Console]::ReadKey($true) | Out-Null
        exit 1
    }

    # Now show splash (colors are available)
    Show-SplashScreen

    # Main loop
    try {
        while ($script:AppState.Running) {
            $panel = Show-MainUI

            if (-not $panel) {
                Start-Sleep -Milliseconds 500
                continue
            }

            $result = Run-CurrentTool -Panel $panel

            if ($result -eq "quit" -or $result -eq "back") {
                # Back from tool returns to menu, quit exits
                if ($result -eq "quit") {
                    $script:AppState.Running = $false
                }
            }

            Clear-InputBuffer
        }
    }
    catch {
        Show-Cursor
        Write-Host "`n`nError: $_" -ForegroundColor Red
        Write-Host $_.ScriptStackTrace -ForegroundColor DarkGray
        Write-Host "`nPress any key to exit..."
        [Console]::ReadKey($true) | Out-Null
    }
    finally {
        Exit-Application
    }
}

# Run
Main
