@echo off
title LazyFrog GitHubScout
color 0A

echo.
echo   ======================================
echo    Kindware.dev GitHubScout Launcher
echo    created by LazyFrog
echo   ======================================
echo.

:: Check if PowerShell 7 (pwsh) is installed
where pwsh >nul 2>&1
if %errorlevel%==0 (
    echo   [OK] PowerShell 7 detected
    echo.
    goto :run
)

:: PowerShell 7 not found
echo   [!] PowerShell 7 is required but not installed.
echo.
set /p INSTALL="  Would you like to install PowerShell 7 now? (Y/N): "

if /i "%INSTALL%"=="Y" goto :install
if /i "%INSTALL%"=="YES" goto :install
echo.
echo   Installation cancelled. Please install PowerShell 7 manually:
echo   https://aka.ms/powershell
echo.
pause
exit

:install
echo.
echo   Installing PowerShell 7 via winget...
echo   (This may take a few minutes)
echo.

:: Check if winget is available
where winget >nul 2>&1
if %errorlevel% neq 0 (
    echo   [ERROR] winget not found. Please install PowerShell 7 manually:
    echo   https://aka.ms/powershell
    echo.
    pause
    exit
)

:: Install PowerShell 7
winget install Microsoft.PowerShell --accept-package-agreements --accept-source-agreements

if %errorlevel%==0 (
    echo.
    echo   [OK] PowerShell 7 installed successfully!
    echo.
    echo   NOTE: You may need to restart this launcher for changes to take effect.
    echo.
    pause
    
    :: Try to run with full path after install
    if exist "%ProgramFiles%\PowerShell\7\pwsh.exe" (
        "%ProgramFiles%\PowerShell\7\pwsh.exe" -NoProfile -ExecutionPolicy Bypass -File "%~dp0GitHubScout.ps1"
        exit
    )
    
    :: Retry with pwsh in case PATH was updated
    pwsh -NoProfile -ExecutionPolicy Bypass -File "%~dp0GitHubScout.ps1"
    exit
) else (
    echo.
    echo   [ERROR] Installation failed. Please install manually:
    echo   https://aka.ms/powershell
    echo.
    pause
    exit
)

:run
pwsh -NoProfile -ExecutionPolicy Bypass -File "%~dp0GitHubScout.ps1"
exit
