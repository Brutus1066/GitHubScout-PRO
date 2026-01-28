@echo off
setlocal EnableDelayedExpansion
title Kindware GitHubScout - Setup
cd /d "%~dp0"

:: ============================================================================
:: Kindware GitHubScout Installer Launcher
:: This batch file checks for PowerShell 7, offers to install if missing,
:: then runs the installer with pwsh.exe for proper ANSI/Unicode support.
:: ============================================================================

:: Check if PowerShell 7 is installed
where pwsh >nul 2>&1
if %errorlevel% equ 0 (
    goto :RUN_INSTALLER
)

:: PowerShell 7 not found - show message
cls
echo.
echo    ╔═══════════════════════════════════════════════════════════╗
echo    ║                                                           ║
echo    ║   ██╗  ██╗██╗███╗   ██╗██████╗ ██╗    ██╗ █████╗ ██████╗  ║
echo    ║   ██║ ██╔╝██║████╗  ██║██╔══██╗██║    ██║██╔══██╗██╔══██╗ ║
echo    ║   █████╔╝ ██║██╔██╗ ██║██║  ██║██║ █╗ ██║███████║██████╔╝ ║
echo    ║   ██╔═██╗ ██║██║╚██╗██║██║  ██║██║███╗██║██╔══██║██╔══██╗ ║
echo    ║   ██║  ██╗██║██║ ╚████║██████╔╝╚███╔███╔╝██║  ██║██║  ██║ ║
echo    ║   ╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝╚═════╝  ╚══╝╚══╝ ╚═╝  ╚═╝╚═╝  ╚═╝ ║
echo    ║                                                           ║
echo    ║              GitHubScout Installer v2.1.0                 ║
echo    ╚═══════════════════════════════════════════════════════════╝
echo.
echo    ┌───────────────────────────────────────────────────────────┐
echo    │  PowerShell 7 is required but not installed.             │
echo    │                                                           │
echo    │  GitHubScout needs PowerShell 7 for modern features      │
echo    │  like rainbow colors and Unicode support.                │
echo    └───────────────────────────────────────────────────────────┘
echo.
echo    Would you like to install PowerShell 7 now?
echo    (Requires winget - Windows Package Manager)
echo.
set /p INSTALL_PS7="    Install PowerShell 7? (Y/N): "

if /i "!INSTALL_PS7!"=="Y" (
    echo.
    echo    Installing PowerShell 7 via winget...
    echo    Please wait, this may take a few minutes...
    echo.
    winget install --id Microsoft.PowerShell --source winget --accept-package-agreements --accept-source-agreements
    
    if !errorlevel! equ 0 (
        echo.
        echo    ✔ PowerShell 7 installed successfully!
        echo.
        echo    IMPORTANT: Please close this window and run the installer again.
        echo    (The new PowerShell needs a fresh terminal to be detected)
        echo.
        pause
        exit
    ) else (
        echo.
        echo    ✖ Installation failed. Please install manually from:
        echo      https://aka.ms/powershell
        echo.
        pause
        exit
    )
) else (
    echo.
    echo    Installation cancelled.
    echo    You can download PowerShell 7 from: https://aka.ms/powershell
    echo.
    pause
    exit
)

:RUN_INSTALLER
:: PowerShell 7 is available - run the installer
pwsh -NoProfile -ExecutionPolicy Bypass -File "%~dp0GitHubScout-Setup.ps1"
exit
