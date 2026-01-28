@echo off
REM ============================================================================
REM Kindware GitHubScout - Build & Package Script
REM Creates a clean release package for distribution
REM ============================================================================
REM Author:  LazyFrog-kz
REM Company: Kindware (kindware.dev)
REM License: MIT License
REM ============================================================================

title Kindware GitHubScout - Build Package
color 0B

echo.
echo   ╔═══════════════════════════════════════════════════════╗
echo   ║        Kindware GitHubScout - Build Package           ║
echo   ║              created by LazyFrog-kz                   ║
echo   ╚═══════════════════════════════════════════════════════╝
echo.

set "SOURCE=%~dp0"
set "BUILD=%~dp0build"
set "RELEASE=%~dp0release"
set "VERSION=2.1.0"

echo   [1/5] Cleaning build folders...
if exist "%BUILD%" rmdir /s /q "%BUILD%"
if exist "%RELEASE%" rmdir /s /q "%RELEASE%"
mkdir "%BUILD%"
mkdir "%RELEASE%"

echo   [2/5] Copying release files...
copy "%SOURCE%GitHubScout.ps1" "%BUILD%\" >nul
copy "%SOURCE%LazyFrog-GitHubScout.bat" "%BUILD%\" >nul
copy "%SOURCE%Install-Shortcut.bat" "%BUILD%\" >nul
copy "%SOURCE%Install-DesktopShortcut.ps1" "%BUILD%\" >nul
copy "%SOURCE%GitHubScout.ico" "%BUILD%\" >nul
copy "%SOURCE%config.json" "%BUILD%\" >nul
copy "%SOURCE%README.md" "%BUILD%\" >nul
copy "%SOURCE%LICENSE" "%BUILD%\" >nul

echo   [3/5] Creating portable ZIP package...
cd "%BUILD%"
powershell -NoProfile -Command "Compress-Archive -Path '%BUILD%\*' -DestinationPath '%RELEASE%\GitHubScout-v%VERSION%-portable.zip' -Force"

echo   [4/5] Creating installer script...
copy "%SOURCE%installer\GitHubScout-Installer.bat" "%RELEASE%\" >nul 2>&1

echo   [5/5] Package complete!
echo.
echo   ╔═══════════════════════════════════════════════════════╗
echo   ║                    BUILD COMPLETE                     ║
echo   ╚═══════════════════════════════════════════════════════╝
echo.
echo   Output files:
echo     - release\GitHubScout-v%VERSION%-portable.zip
echo.
echo   To distribute:
echo     1. Upload the ZIP to GitHub Releases
echo     2. Users extract and run LazyFrog-GitHubScout.bat
echo.

pause
