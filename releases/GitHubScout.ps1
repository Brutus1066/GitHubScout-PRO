#!/usr/bin/env pwsh
#Requires -Version 7.0
<#
.SYNOPSIS
    Kindware GitHubScout - Fast CLI for GitHub Repository Discovery

.DESCRIPTION
    A lightweight, menu-driven command-line tool for searching, tracking, 
    and inspecting GitHub repositories. Built for developers who live in 
    the terminal.

    Features:
    - Search GitHub by keyword, language, and star count
    - Track repositories and monitor their stats
    - Inspect repos with full details and README viewer
    - Simple menu interface - no complex TUI required

.NOTES
    Name:       GitHubScout
    Author:     LazyFrog-kz
    Company:    Kindware (kindware.dev)
    Version:    2.1.0
    License:    MIT License
    Repository: https://github.com/LazyFrog-kz/GitHubScout

.LINK
    https://kindware.dev
    https://github.com/LazyFrog-kz

.EXAMPLE
    .\GitHubScout.ps1
    Launches the interactive menu interface.

.EXAMPLE
    # Or use the launcher:
    LazyFrog-GitHubScout.bat
#>

# ============================================================================
# KINDWARE GITHUBSCOUT - Configuration
# ============================================================================
# Author:  LazyFrog-kz | kindware.dev
# License: MIT License - Free to use, modify, and distribute
# ============================================================================

$ErrorActionPreference = "Stop"
$script:AppVersion = "2.1.0"
$script:AppName = "GitHubScout"
$script:Author = "LazyFrog-kz"
$script:Company = "Kindware"
$script:Website = "kindware.dev"
$script:ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
if (-not $script:ScriptDir) { $script:ScriptDir = $PWD.Path }

$ConfigPath = Join-Path $script:ScriptDir "config.json"
$TrackedPath = Join-Path $script:ScriptDir "tracked.json"

$GitHubApi = "https://api.github.com"
$Headers = @{ "Accept" = "application/vnd.github+json"; "User-Agent" = "Kindware-GitHubScout/$script:AppVersion" }

# ============================================================================
# Config & Storage
# ============================================================================
function Get-AppConfig {
    if (Test-Path $ConfigPath) {
        try { return Get-Content $ConfigPath -Raw | ConvertFrom-Json -AsHashtable }
        catch { }
    }
    return @{ GitHubToken = "" }
}

function Get-Tracked {
    if (Test-Path $TrackedPath) {
        try { return Get-Content $TrackedPath -Raw | ConvertFrom-Json -AsHashtable }
        catch { }
    }
    return @{ Repos = @() }
}

function Save-Tracked($data) {
    $data | ConvertTo-Json -Depth 10 | Set-Content $TrackedPath -Encoding UTF8
}

# ============================================================================
# GitHub API
# ============================================================================
function Invoke-GitHub($endpoint, $params = @{}) {
    $url = "$GitHubApi$endpoint"
    if ($params.Count -gt 0) {
        $qs = ($params.GetEnumerator() | ForEach-Object { "$([Uri]::EscapeDataString($_.Key))=$([Uri]::EscapeDataString($_.Value))" }) -join "&"
        $url = "$url`?$qs"
    }
    try {
        return @{ OK = $true; Data = (Invoke-RestMethod -Uri $url -Headers $Headers -TimeoutSec 30) }
    } catch {
        $code = $_.Exception.Response.StatusCode.value__
        $msg = switch ($code) { 403 { "Rate limit - add token to config.json" } 404 { "Not found" } default { $_.Exception.Message } }
        return @{ OK = $false; Err = $msg }
    }
}

function Search-Repos($query, $lang = "", $stars = 0) {
    $q = $query
    if ($lang) { $q += " language:$lang" }
    if ($stars -gt 0) { $q += " stars:>=$stars" }
    $r = Invoke-GitHub "/search/repositories" @{ q = $q; per_page = 10 }
    if ($r.OK) { return @{ OK = $true; Total = $r.Data.total_count; Items = $r.Data.items } }
    return $r
}

function Get-Repo($name) {
    if ($name -notmatch '^[^/]+/[^/]+$') { return @{ OK = $false; Err = "Use format: owner/repo" } }
    $r = Invoke-GitHub "/repos/$name"
    if ($r.OK) { return @{ OK = $true; Repo = $r.Data } }
    return $r
}

function Get-Readme($owner, $repo) {
    $r = Invoke-GitHub "/repos/$owner/$repo/readme"
    if (-not $r.OK) { return @{ OK = $false } }
    try { return @{ OK = $true; Text = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($r.Data.content)) } }
    catch { return @{ OK = $false } }
}

# ============================================================================
# UI Helpers
# ============================================================================
function Fmt($n) { if ($n -ge 1000000) { "{0:N1}M" -f ($n/1e6) } elseif ($n -ge 1000) { "{0:N1}K" -f ($n/1e3) } else { "$n" } }

function Show-Logo {
    $logo = @"

    `e[96m██╗  ██╗`e[0m`e[93m██╗`e[0m`e[96m███╗   ██╗`e[0m`e[92m██████╗ `e[0m`e[95m██╗    ██╗`e[0m`e[91m █████╗ `e[0m`e[94m██████╗ `e[0m`e[96m███████╗`e[0m
    `e[96m██║ ██╔╝`e[0m`e[93m██║`e[0m`e[96m████╗  ██║`e[0m`e[92m██╔══██╗`e[0m`e[95m██║    ██║`e[0m`e[91m██╔══██╗`e[0m`e[94m██╔══██╗`e[0m`e[96m██╔════╝`e[0m
    `e[96m█████╔╝ `e[0m`e[93m██║`e[0m`e[96m██╔██╗ ██║`e[0m`e[92m██║  ██║`e[0m`e[95m██║ █╗ ██║`e[0m`e[91m███████║`e[0m`e[94m██████╔╝`e[0m`e[96m█████╗  `e[0m
    `e[96m██╔═██╗ `e[0m`e[93m██║`e[0m`e[96m██║╚██╗██║`e[0m`e[92m██║  ██║`e[0m`e[95m██║███╗██║`e[0m`e[91m██╔══██║`e[0m`e[94m██╔══██╗`e[0m`e[96m██╔══╝  `e[0m
    `e[96m██║  ██╗`e[0m`e[93m██║`e[0m`e[96m██║ ╚████║`e[0m`e[92m██████╔╝`e[0m`e[95m╚███╔███╔╝`e[0m`e[91m██║  ██║`e[0m`e[94m██║  ██║`e[0m`e[96m███████╗`e[0m
    `e[96m╚═╝  ╚═╝`e[0m`e[93m╚═╝`e[0m`e[96m╚═╝  ╚═══╝`e[0m`e[92m╚═════╝ `e[0m`e[95m ╚══╝╚══╝ `e[0m`e[91m╚═╝  ╚═╝`e[0m`e[94m╚═╝  ╚═╝`e[0m`e[96m╚══════╝`e[0m

"@
    Write-Host $logo
}

function Banner {
    Clear-Host
    Show-Logo
    Write-Host "                    `e[92m◆ GitHubScout `e[90mv$script:AppVersion`e[0m" 
    Write-Host "              `e[90m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`e[0m"
    Write-Host "               `e[93m⚡`e[0m `e[37mFast GitHub Repository Discovery`e[0m"
    Write-Host "               `e[90mcreated by `e[95m$script:Author`e[90m | `e[96m$script:Website`e[0m"
    Write-Host ""
}

function Menu {
    Banner
    Write-Host "    `e[97m╭─────────────────────────────────╮`e[0m"
    Write-Host "    `e[97m│`e[0m  `e[93m[1]`e[0m `e[97m🔍 Search GitHub`e[0m          `e[97m│`e[0m"
    Write-Host "    `e[97m│`e[0m  `e[93m[2]`e[0m `e[97m📌 Tracked Repos`e[0m          `e[97m│`e[0m"
    Write-Host "    `e[97m│`e[0m  `e[93m[3]`e[0m `e[97m🔎 Inspect Repo`e[0m           `e[97m│`e[0m"
    Write-Host "    `e[97m│`e[0m  `e[93m[4]`e[0m `e[97m❓ Help`e[0m                   `e[97m│`e[0m"
    Write-Host "    `e[97m│`e[0m  `e[91m[Q]`e[0m `e[90m   Quit`e[0m                   `e[97m│`e[0m"
    Write-Host "    `e[97m╰─────────────────────────────────╯`e[0m"
    Write-Host ""
}

function Pause { Write-Host ""; Read-Host "  Press Enter" | Out-Null }

# ============================================================================
# Features - Search, Track, Inspect
# ============================================================================
function Do-Search {
    Banner
    Write-Host "    `e[96m━━━ 🔍 SEARCH GITHUB ━━━`e[0m" -ForegroundColor Cyan
    $q = Read-Host "`n  Query"
    if (-not $q) { return }
    $lang = Read-Host "  Language (optional)"
    $stars = Read-Host "  Min stars (optional)"
    $minStars = if ($stars -match '^\d+$') { [int]$stars } else { 0 }

    Write-Host "`n  Searching..." -ForegroundColor Yellow
    $r = Search-Repos $q $lang $minStars

    if (-not $r.OK) { Write-Host "  Error: $($r.Err)" -ForegroundColor Red; Pause; return }

    Write-Host "`n  Found $($r.Total) repos:`n" -ForegroundColor Green
    $i = 1
    foreach ($repo in $r.Items) {
        $name = $repo.full_name; if ($name.Length -gt 35) { $name = $name.Substring(0,32) + "..." }
        Write-Host ("  [{0,2}] {1,-35} {2,6}*  {3}" -f $i, $name, (Fmt $repo.stargazers_count), ($repo.language ?? "-"))
        $i++
    }

    # Action loop - stay in results until user goes back
    while ($true) {
        Write-Host ""
        Write-Host "  Commands: T1=Track  O1=Open  I1=Inspect  (change 1 to any #)" -ForegroundColor DarkGray
        Write-Host "  Or just type a number to inspect. Press Enter to go back." -ForegroundColor DarkGray
        $act = Read-Host "  >"

        if (-not $act -or $act -eq '') { return }

        # Just a number = inspect that repo
        if ($act -match '^\d+$') {
            $idx = [int]$act - 1
            if ($idx -ge 0 -and $idx -lt $r.Items.Count) {
                Inspect-RepoByName $r.Items[$idx].full_name
                return
            } else { Write-Host "  Invalid number (1-$($r.Items.Count))" -ForegroundColor Red }
        }
        # T1, T2, etc = Track
        elseif ($act -match '^[Tt](\d+)$') {
            $idx = [int]$Matches[1] - 1
            if ($idx -ge 0 -and $idx -lt $r.Items.Count) { Track-Repo $r.Items[$idx] }
            else { Write-Host "  Invalid number (1-$($r.Items.Count))" -ForegroundColor Red }
        }
        # O1, O2, etc = Open in browser
        elseif ($act -match '^[Oo](\d+)$') {
            $idx = [int]$Matches[1] - 1
            if ($idx -ge 0 -and $idx -lt $r.Items.Count) {
                $url = $r.Items[$idx].html_url
                Write-Host "  Opening: $url" -ForegroundColor Green
                try {
                    Start-Process $url
                    Write-Host "  Opened in browser!" -ForegroundColor Green
                } catch {
                    Write-Host "  Failed to open browser: $_" -ForegroundColor Red
                }
            } else { Write-Host "  Invalid number (1-$($r.Items.Count))" -ForegroundColor Red }
        }
        # I1, I2, etc = Inspect
        elseif ($act -match '^[Ii](\d+)$') {
            $idx = [int]$Matches[1] - 1
            if ($idx -ge 0 -and $idx -lt $r.Items.Count) {
                Inspect-RepoByName $r.Items[$idx].full_name
                return
            } else { Write-Host "  Invalid number (1-$($r.Items.Count))" -ForegroundColor Red }
        }
        else {
            Write-Host "  Try: 1, O1, T1, I1 (or Enter to go back)" -ForegroundColor Yellow
        }
    }
}

function Track-Repo($repo) {
    $t = Get-Tracked
    if ($t.Repos | Where-Object { $_.full_name -eq $repo.full_name }) {
        Write-Host "  Already tracked" -ForegroundColor Yellow; Pause; return
    }
    $t.Repos += @{
        full_name = $repo.full_name
        html_url = $repo.html_url
        description = $repo.description
        stargazers_count = $repo.stargazers_count
        language = $repo.language
    }
    Save-Tracked $t
    Write-Host "  Tracked: $($repo.full_name)" -ForegroundColor Green; Pause
}

function Show-Tracked {
    Banner
    Write-Host "  === TRACKED ===" -ForegroundColor Cyan
    $t = Get-Tracked

    if ($t.Repos.Count -eq 0) {
        Write-Host "`n  No repos tracked. Use Search to add some." -ForegroundColor DarkGray; Pause; return
    }

    Write-Host "`n  $($t.Repos.Count) repos:`n" -ForegroundColor Green
    $i = 1
    foreach ($repo in $t.Repos) {
        $name = $repo.full_name; if ($name.Length -gt 35) { $name = $name.Substring(0,32) + "..." }
        Write-Host ("  [{0,2}] {1,-35} {2,6}*  {3}" -f $i, $name, (Fmt $repo.stargazers_count), ($repo.language ?? "-"))
        $i++
    }

    Write-Host "`n  [R] Refresh  [D#] Delete  [O#] Open  [Enter] Back" -ForegroundColor DarkGray
    $act = Read-Host "  Action"

    if ($act -eq 'R' -or $act -eq 'r') { Refresh-Tracked }
    elseif ($act -match '^[Dd](\d+)$') {
        $idx = [int]$Matches[1] - 1
        if ($idx -ge 0 -and $idx -lt $t.Repos.Count) {
            $name = $t.Repos[$idx].full_name
            $t.Repos = @($t.Repos | Where-Object { $_.full_name -ne $name })
            Save-Tracked $t
            Write-Host "  Removed: $name" -ForegroundColor Yellow; Pause
        }
    } elseif ($act -match '^[Oo](\d+)$') {
        $idx = [int]$Matches[1] - 1
        if ($idx -ge 0 -and $idx -lt $t.Repos.Count) { Start-Process $t.Repos[$idx].html_url }
    }
}

function Refresh-Tracked {
    $t = Get-Tracked
    Write-Host "`n  Refreshing..." -ForegroundColor Yellow
    for ($i = 0; $i -lt $t.Repos.Count; $i++) {
        Write-Host "  [$($i+1)/$($t.Repos.Count)] $($t.Repos[$i].full_name)" -ForegroundColor DarkGray -NoNewline
        $r = Get-Repo $t.Repos[$i].full_name
        if ($r.OK) {
            $t.Repos[$i].stargazers_count = $r.Repo.stargazers_count
            Write-Host " OK" -ForegroundColor Green
        } else { Write-Host " FAIL" -ForegroundColor Red }
        Start-Sleep -Milliseconds 200
    }
    Save-Tracked $t
    Write-Host "  Done!" -ForegroundColor Green; Pause
}

function Inspect-RepoByName($name) {
    Banner
    Write-Host "  === INSPECT ===" -ForegroundColor Cyan
    Write-Host "`n  Loading $name..." -ForegroundColor Yellow
    
    $r = Get-Repo $name
    if (-not $r.OK) { Write-Host "  Error: $($r.Err)" -ForegroundColor Red; Pause; return }

    Show-RepoDetails $r.Repo $name
}

function Inspect-Repo {
    Banner
    Write-Host "  === INSPECT ===" -ForegroundColor Cyan
    $name = Read-Host "`n  Repo (owner/repo)"
    if (-not $name) { return }

    Write-Host "`n  Loading..." -ForegroundColor Yellow
    $r = Get-Repo $name
    if (-not $r.OK) { Write-Host "  Error: $($r.Err)" -ForegroundColor Red; Pause; return }

    Show-RepoDetails $r.Repo $name
}

function Show-RepoDetails($repo, $name) {
    Write-Host "`n  $($repo.full_name)" -ForegroundColor Green
    Write-Host "  $($repo.html_url)" -ForegroundColor DarkGray
    if ($repo.description) { Write-Host "`n  $($repo.description)" }

    Write-Host "`n  Stats:" -ForegroundColor Cyan
    Write-Host "    Stars: $(Fmt $repo.stargazers_count)  Forks: $(Fmt $repo.forks_count)  Issues: $($repo.open_issues_count)"
    Write-Host "    Lang: $($repo.language ?? 'N/A')  License: $(if ($repo.license) { $repo.license.name } else { 'N/A' })"
    $created = if ($repo.created_at -is [datetime]) { $repo.created_at.ToString("yyyy-MM-dd") } else { "$($repo.created_at)".Substring(0,10) }
    $updated = if ($repo.updated_at -is [datetime]) { $repo.updated_at.ToString("yyyy-MM-dd") } else { "$($repo.updated_at)".Substring(0,10) }
    Write-Host "    Created: $created  Updated: $updated"

    Write-Host "`n  [T] Track  [R] README  [O] Open  [Enter] Back" -ForegroundColor DarkGray
    $act = Read-Host "  Action"

    switch ($act.ToLower()) {
        't' { Track-Repo $repo }
        'r' { Show-Readme $repo.full_name }
        'o' { 
            Write-Host "  Opening: $($repo.html_url)" -ForegroundColor Green
            Start-Process $repo.html_url 
        }
    }
}

function Show-Readme($name) {
    $parts = $name -split '/'
    Write-Host "`n  Loading README..." -ForegroundColor Yellow
    $r = Get-Readme $parts[0] $parts[1]
    if (-not $r.OK) { Write-Host "  No README found" -ForegroundColor Red; Pause; return }

    # Clean the README content
    $text = $r.Text
    
    # Remove HTML tags
    $text = $text -replace '<[^>]+>', ''
    # Remove badge/shield image markdown
    $text = $text -replace '!\[.*?\]\([^)]+\)', ''
    # Remove link-only lines
    $text = $text -replace '\[!\[.*?\]\([^)]+\)\]\([^)]+\)', ''
    # Clean up multiple blank lines
    $text = $text -replace '(\r?\n){3,}', "`n`n"
    # Remove HTML entities
    $text = $text -replace '&nbsp;', ' '
    $text = $text -replace '&amp;', '&'
    $text = $text -replace '&lt;', '<'
    $text = $text -replace '&gt;', '>'
    # Clean alignment/style markers
    $text = $text -replace 'align="[^"]*"', ''
    
    $allLines = $text -split "`n" | Where-Object { $_.Trim() -ne '' }
    $totalLines = $allLines.Count
    $pageSize = 20
    $currentPos = 0

    while ($true) {
        Clear-Host
        Write-Host "`n  === README: $name ===" -ForegroundColor Cyan
        Write-Host "  Lines $($currentPos + 1)-$([Math]::Min($currentPos + $pageSize, $totalLines)) of $totalLines" -ForegroundColor DarkGray
        Write-Host ""

        $endPos = [Math]::Min($currentPos + $pageSize, $totalLines)
        for ($i = $currentPos; $i -lt $endPos; $i++) {
            $line = $allLines[$i]
            # Highlight headers
            if ($line -match '^#{1,3}\s') {
                $line = $line -replace '^#+\s*', ''
                Write-Host "  $line" -ForegroundColor Green
            } elseif ($line -match '^\*\*.*\*\*$') {
                Write-Host "  $line" -ForegroundColor Yellow
            } else {
                if ($line.Length -gt 76) { $line = $line.Substring(0,73) + "..." }
                Write-Host "  $line"
            }
        }

        Write-Host ""
        $nav = @()
        if ($currentPos -gt 0) { $nav += "[U] Up" }
        if ($currentPos + $pageSize -lt $totalLines) { $nav += "[D] Down" }
        $nav += "[Enter] Back"
        Write-Host "  $($nav -join '  ')" -ForegroundColor DarkGray

        $key = Read-Host "  Navigate"
        switch ($key.ToLower()) {
            'u' { if ($currentPos -gt 0) { $currentPos -= $pageSize; if ($currentPos -lt 0) { $currentPos = 0 } } }
            'd' { if ($currentPos + $pageSize -lt $totalLines) { $currentPos += $pageSize } }
            default { return }
        }
    }
}

function Show-Help {
    Banner
    Write-Host "    `e[96m━━━ ❓ HELP ━━━`e[0m"
    Write-Host @"

  `e[92m◆ QUICK START`e[0m
    1. Press [1] to search GitHub
    2. Enter a query (e.g., "cli tools")
    3. Type a number to inspect, or O1 to open in browser
    4. Type T1 to track a repo

  `e[93m◆ COMMANDS IN SEARCH RESULTS`e[0m
    1, 2, 3...  - Inspect that repo
    O1, O2...   - Open in browser
    T1, T2...   - Track the repo
    Enter       - Go back

  `e[91m◆ GITHUB TOKEN (recommended)`e[0m
    Without token: 60 requests/hour
    With token: 5,000 requests/hour

    Edit config.json:
    { "GitHubToken": "ghp_your_token" }

  `e[95m◆ FILES`e[0m
    config.json  - Settings & API token
    tracked.json - Your tracked repos

  `e[90m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`e[0m
  `e[90mKindware GitHubScout v$script:AppVersion | $script:Website`e[0m
  `e[90mCreated by $script:Author | MIT License`e[0m

"@
    Pause
}

# ============================================================================
# Main Entry Point
# ============================================================================
if ($PSVersionTable.PSVersion.Major -lt 7) {
    Write-Host "`e[91m✖ Requires PowerShell 7+`e[0m" 
    Write-Host "`e[93mGet it: https://aka.ms/powershell`e[0m"
    exit 1
}

# Load token
$cfg = Get-AppConfig
if ($cfg.GitHubToken) { $Headers["Authorization"] = "Bearer $($cfg.GitHubToken)" }

# Main loop
while ($true) {
    Menu
    if (-not $cfg.GitHubToken) { 
        Write-Host "    `e[93m💡 Tip:`e[0m `e[90mAdd GitHub token to config.json for 5000 req/hour`e[0m"
        Write-Host ""
    }

    $choice = Read-Host "    `e[97m>`e[0m"
    switch ($choice.ToUpper()) {
        "1" { Do-Search }
        "2" { Show-Tracked }
        "3" { Inspect-Repo }
        "4" { Show-Help }
        "Q" { 
            Clear-Host
            Show-Logo
            Write-Host "              `e[92m✔ Thanks for using Kindware GitHubScout!`e[0m"
            Write-Host "              `e[90mcreated by $script:Author | $script:Website`e[0m"
            Write-Host ""
            exit 0 
        }
    }
}
