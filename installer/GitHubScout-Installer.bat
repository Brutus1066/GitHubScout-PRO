@echo off
REM ============================================================================
REM Kindware GitHubScout - One-Click Installer
REM Installs GitHubScout to Program Files and creates desktop shortcut
REM ============================================================================
REM Author:  LazyFrog-kz
REM Company: Kindware (kindware.dev)
REM License: MIT License
REM ============================================================================

title Kindware GitHubScout Installer
color 0B

echo.
echo   ╔═══════════════════════════════════════════════════════╗
echo   ║         Kindware GitHubScout - Installer              ║
echo   ║              created by LazyFrog-kz                   ║
echo   ╚═══════════════════════════════════════════════════════╝
echo.

REM Check for admin rights
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo   [!] This installer requires administrator privileges.
    echo   [!] Please right-click and select "Run as administrator"
    echo.
    pause
    exit /b 1
)

set "INSTALL_DIR=%ProgramFiles%\Kindware\GitHubScout"
set "SOURCE=%~dp0"

echo   Install location: %INSTALL_DIR%
echo.
set /p CONFIRM="  Proceed with installation? (Y/N): "
if /i not "%CONFIRM%"=="Y" (
    echo   Installation cancelled.
    pause
    exit /b 0
)

echo.
echo   [1/4] Creating installation directory...
if not exist "%INSTALL_DIR%" mkdir "%INSTALL_DIR%"

echo   [2/4] Copying files...
copy "%SOURCE%GitHubScout.ps1" "%INSTALL_DIR%\" >nul
copy "%SOURCE%LazyFrog-GitHubScout.bat" "%INSTALL_DIR%\" >nul
copy "%SOURCE%Install-DesktopShortcut.ps1" "%INSTALL_DIR%\" >nul
copy "%SOURCE%GitHubScout.ico" "%INSTALL_DIR%\" >nul
copy "%SOURCE%config.json" "%INSTALL_DIR%\" >nul
copy "%SOURCE%README.md" "%INSTALL_DIR%\" >nul
copy "%SOURCE%LICENSE" "%INSTALL_DIR%\" >nul

echo   [3/4] Creating desktop shortcut...
pwsh -NoProfile -ExecutionPolicy Bypass -Command ^
  "$ws = New-Object -ComObject WScript.Shell; ^
   $s = $ws.CreateShortcut([Environment]::GetFolderPath('Desktop') + '\GitHubScout.lnk'); ^
   $s.TargetPath = '%INSTALL_DIR%\LazyFrog-GitHubScout.bat'; ^
   $s.WorkingDirectory = '%INSTALL_DIR%'; ^
   $s.IconLocation = '%INSTALL_DIR%\GitHubScout.ico,0'; ^
   $s.Description = 'Kindware GitHubScout'; ^
   $s.Save()"

echo   [4/4] Creating Start Menu shortcut...
set "STARTMENU=%ProgramData%\Microsoft\Windows\Start Menu\Programs\Kindware"
if not exist "%STARTMENU%" mkdir "%STARTMENU%"
pwsh -NoProfile -ExecutionPolicy Bypass -Command ^
  "$ws = New-Object -ComObject WScript.Shell; ^
   $s = $ws.CreateShortcut('%STARTMENU%\GitHubScout.lnk'); ^
   $s.TargetPath = '%INSTALL_DIR%\LazyFrog-GitHubScout.bat'; ^
   $s.WorkingDirectory = '%INSTALL_DIR%'; ^
   $s.IconLocation = '%INSTALL_DIR%\GitHubScout.ico,0'; ^
   $s.Description = 'Kindware GitHubScout'; ^
   $s.Save()"

echo.
echo   ╔═══════════════════════════════════════════════════════╗
echo   ║            INSTALLATION COMPLETE!                     ║
echo   ╚═══════════════════════════════════════════════════════╝
echo.
echo   GitHubScout has been installed to:
echo     %INSTALL_DIR%
echo.
echo   Shortcuts created:
echo     - Desktop: GitHubScout
echo     - Start Menu: Kindware ^> GitHubScout
echo.
echo   Double-click the desktop icon to launch!
echo.

pause
