#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Build GitHubScout installer .exe with embedded icon
    
.DESCRIPTION
    Uses ps2exe to compile the installer to a standalone .exe
    with the custom icon baked in.

.NOTES
    Author:  LazyFrog-kz
    Company: Kindware (kindware.dev)
#>

$ErrorActionPreference = "Stop"
$ScriptDir = $PSScriptRoot
$ProjectRoot = Split-Path $ScriptDir -Parent
$Version = "2.1.0"

Write-Host ""
Write-Host "  ╔═══════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "  ║     Kindware GitHubScout - Build EXE Installer    ║" -ForegroundColor Cyan
Write-Host "  ║              created by LazyFrog-kz               ║" -ForegroundColor Cyan
Write-Host "  ╚═══════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Check/Install ps2exe module
Write-Host "  [1/5] Checking ps2exe module..." -NoNewline
if (-not (Get-Module -ListAvailable -Name ps2exe)) {
    Write-Host " Installing..." -ForegroundColor Yellow
    Install-Module -Name ps2exe -Scope CurrentUser -Force
    Write-Host "  [1/5] ps2exe installed!" -ForegroundColor Green
} else {
    Write-Host " OK" -ForegroundColor Green
}

# Create output directories
Write-Host "  [2/5] Creating build directories..." -NoNewline
$BuildDir = Join-Path $ProjectRoot "build\exe-installer"
$ReleaseDir = Join-Path $ProjectRoot "release"
if (Test-Path $BuildDir) { Remove-Item $BuildDir -Recurse -Force }
New-Item -ItemType Directory -Path $BuildDir -Force | Out-Null
if (-not (Test-Path $ReleaseDir)) { New-Item -ItemType Directory -Path $ReleaseDir -Force | Out-Null }
Write-Host " OK" -ForegroundColor Green

# Copy files to build directory
Write-Host "  [3/5] Copying application files..." -NoNewline
$filesToCopy = @(
    "GitHubScout.ps1",
    "LazyFrog-GitHubScout.bat",
    "GitHubScout.ico",
    "config.json",
    "README.md",
    "LICENSE"
)

foreach ($file in $filesToCopy) {
    $src = Join-Path $ProjectRoot $file
    if (Test-Path $src) {
        Copy-Item $src -Destination $BuildDir -Force
    }
}

# Copy installer script
Copy-Item (Join-Path $ScriptDir "GitHubScout-Setup.ps1") -Destination $BuildDir -Force
Write-Host " OK" -ForegroundColor Green

# Compile to EXE
Write-Host "  [4/5] Compiling to EXE with icon..." -NoNewline
$InstallerScript = Join-Path $BuildDir "GitHubScout-Setup.ps1"
$OutputExe = Join-Path $BuildDir "GitHubScout-Setup.exe"
$IconPath = Join-Path $ProjectRoot "GitHubScout.ico"

try {
    Import-Module ps2exe
    
    # Compile with icon
    Invoke-PS2EXE -InputFile $InstallerScript `
                  -OutputFile $OutputExe `
                  -IconFile $IconPath `
                  -Title "GitHubScout Setup" `
                  -Description "Kindware GitHubScout Installer" `
                  -Company "Kindware" `
                  -Product "GitHubScout" `
                  -Version $Version `
                  -Copyright "MIT License - LazyFrog-kz" `
                  -NoConsole:$false `
                  -RequireAdmin:$false
    
    Write-Host " OK" -ForegroundColor Green
} catch {
    Write-Host " FAILED" -ForegroundColor Red
    Write-Host "  Error: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "  Falling back to batch wrapper..." -ForegroundColor Yellow
    
    # Create a batch wrapper as fallback
    $batchContent = @"
@echo off
title GitHubScout Setup
cd /d "%~dp0"
pwsh -NoProfile -ExecutionPolicy Bypass -File "GitHubScout-Setup.ps1"
if errorlevel 1 pause
"@
    $batchContent | Set-Content (Join-Path $BuildDir "GitHubScout-Setup.bat") -Encoding ASCII
    Write-Host "  Created batch wrapper instead." -ForegroundColor Yellow
}

# Create final release package
Write-Host "  [5/5] Creating release package..." -NoNewline
$ZipPath = Join-Path $ReleaseDir "GitHubScout-v$Version-Setup.zip"
if (Test-Path $ZipPath) { Remove-Item $ZipPath -Force }
Compress-Archive -Path "$BuildDir\*" -DestinationPath $ZipPath -Force
Write-Host " OK" -ForegroundColor Green

Write-Host ""
Write-Host "  ╔═══════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "  ║              BUILD COMPLETE! ✔                    ║" -ForegroundColor Green
Write-Host "  ╚═══════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "  Output files:" -ForegroundColor White
Write-Host "    • build\exe-installer\GitHubScout-Setup.exe" -ForegroundColor Cyan
Write-Host "    • release\GitHubScout-v$Version-Setup.zip" -ForegroundColor Cyan
Write-Host ""
Write-Host "  The .exe has your custom icon baked in!"
Write-Host ""

# List contents
Write-Host "  Package contents:" -ForegroundColor White
Get-ChildItem $BuildDir | ForEach-Object {
    Write-Host "    • $($_.Name)" -ForegroundColor Gray
}
Write-Host ""
