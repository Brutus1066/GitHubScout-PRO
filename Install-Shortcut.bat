@echo off
title Kindware GitHubScout - Desktop Shortcut Installer
color 0B
echo.
echo   Installing GitHubScout desktop shortcut...
echo.
pwsh -NoProfile -ExecutionPolicy Bypass -File "%~dp0Install-DesktopShortcut.ps1"
