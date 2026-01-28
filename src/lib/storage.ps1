# storage.ps1 - Data Persistence Module for Kindware.dev GitHubScout
# Handles JSON and Markdown file operations

# ============================================================================
# Path Configuration
# ============================================================================
$script:DataDir = $null
$script:Paths = @{}

function Initialize-Storage {
    <#
    .SYNOPSIS
    Initializes the storage module with the data directory
    #>
    param(
        [string]$BaseDir = $PSScriptRoot
    )

    # Determine data directory (same as script directory)
    $script:DataDir = Split-Path -Parent (Split-Path -Parent $BaseDir)
    if (-not $script:DataDir) {
        $script:DataDir = $PWD.Path
    }

    # Define file paths
    $script:Paths = @{
        Config        = Join-Path $script:DataDir "config.json"
        Tracked       = Join-Path $script:DataDir "tracked.json"
        SearchResults = Join-Path $script:DataDir "search-results.json"
        SearchMd      = Join-Path $script:DataDir "search-results.md"
        ReportDir     = Join-Path $script:DataDir "reports"
    }

    # Create reports directory if needed
    if (-not (Test-Path $script:Paths.ReportDir)) {
        New-Item -ItemType Directory -Path $script:Paths.ReportDir -Force | Out-Null
    }

    return $script:Paths
}

function Get-StoragePath {
    <#
    .SYNOPSIS
    Gets the path for a specific storage file
    #>
    param(
        [ValidateSet("Config", "Tracked", "SearchResults", "SearchMd", "ReportDir")]
        [string]$Name
    )

    if (-not $script:Paths -or $script:Paths.Count -eq 0) {
        Initialize-Storage
    }

    return $script:Paths[$Name]
}

# ============================================================================
# JSON Operations
# ============================================================================

function Save-Json {
    <#
    .SYNOPSIS
    Saves an object to a JSON file
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        $Data,

        [switch]$Compress
    )

    try {
        $jsonParams = @{
            Depth = 10
        }

        if (-not $Compress) {
            # PowerShell 7 has better JSON formatting
            $json = $Data | ConvertTo-Json @jsonParams
        } else {
            $json = $Data | ConvertTo-Json @jsonParams -Compress
        }

        # Ensure directory exists
        $dir = Split-Path -Parent $Path
        if (-not (Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
        }

        # Write with UTF8 encoding (no BOM)
        [System.IO.File]::WriteAllText($Path, $json, [System.Text.UTF8Encoding]::new($false))

        return @{ Success = $true; Path = $Path }
    }
    catch {
        return @{ Success = $false; Error = $_.Exception.Message }
    }
}

function Load-Json {
    <#
    .SYNOPSIS
    Loads an object from a JSON file
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        $Default = $null
    )

    try {
        if (-not (Test-Path $Path)) {
            return $Default
        }

        $json = [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::UTF8)
        $data = $json | ConvertFrom-Json -AsHashtable

        return $data
    }
    catch {
        Write-Warning "Failed to load JSON from $Path : $($_.Exception.Message)"
        return $Default
    }
}

# ============================================================================
# Config Operations
# ============================================================================

function Get-Config {
    <#
    .SYNOPSIS
    Loads the application configuration
    #>
    $configPath = Get-StoragePath -Name "Config"
    $defaultConfig = @{
        GitHubToken    = ""
        DefaultSort    = "updated"
        ResultsPerPage = 10
        Theme          = "default"
        LastUpdated    = $null
    }

    $config = Load-Json -Path $configPath -Default $defaultConfig

    # Merge with defaults for any missing keys
    foreach ($key in $defaultConfig.Keys) {
        if (-not $config.ContainsKey($key)) {
            $config[$key] = $defaultConfig[$key]
        }
    }

    return $config
}

function Save-Config {
    <#
    .SYNOPSIS
    Saves the application configuration
    #>
    param(
        [hashtable]$Config
    )

    $Config["LastUpdated"] = (Get-Date).ToString("o")
    $configPath = Get-StoragePath -Name "Config"
    return Save-Json -Path $configPath -Data $Config
}

function Set-ConfigValue {
    <#
    .SYNOPSIS
    Sets a single configuration value
    #>
    param(
        [string]$Key,
        $Value
    )

    $config = Get-Config
    $config[$Key] = $Value
    return Save-Config -Config $config
}

# ============================================================================
# Tracked Repos Operations
# ============================================================================

function Get-TrackedRepos {
    <#
    .SYNOPSIS
    Gets the list of tracked repositories
    #>
    $trackedPath = Get-StoragePath -Name "Tracked"
    $default = @{
        Repos       = @()
        LastChecked = $null
    }

    return Load-Json -Path $trackedPath -Default $default
}

function Save-TrackedRepos {
    <#
    .SYNOPSIS
    Saves the tracked repositories list
    #>
    param(
        [hashtable]$TrackedData
    )

    $TrackedData["LastChecked"] = (Get-Date).ToString("o")
    $trackedPath = Get-StoragePath -Name "Tracked"
    return Save-Json -Path $trackedPath -Data $TrackedData
}

function Add-TrackedRepo {
    <#
    .SYNOPSIS
    Adds a repository to the tracked list
    #>
    param(
        [Parameter(Mandatory)]
        [hashtable]$Repo
    )

    $tracked = Get-TrackedRepos

    # Check if already tracked
    $existing = $tracked.Repos | Where-Object { $_.full_name -eq $Repo.full_name }
    if ($existing) {
        return @{ Success = $false; Error = "Repository already tracked" }
    }

    # Add tracking metadata
    $Repo["tracked_at"] = (Get-Date).ToString("o")
    $Repo["last_stars"] = $Repo.stargazers_count
    $Repo["last_issues"] = $Repo.open_issues_count
    $Repo["last_commit"] = $Repo.pushed_at

    $tracked.Repos += $Repo
    $result = Save-TrackedRepos -TrackedData $tracked

    if ($result.Success) {
        return @{ Success = $true; Message = "Added $($Repo.full_name) to tracker" }
    }
    return $result
}

function Remove-TrackedRepo {
    <#
    .SYNOPSIS
    Removes a repository from the tracked list
    #>
    param(
        [Parameter(Mandatory)]
        [string]$FullName
    )

    $tracked = Get-TrackedRepos
    $originalCount = $tracked.Repos.Count

    $tracked.Repos = @($tracked.Repos | Where-Object { $_.full_name -ne $FullName })

    if ($tracked.Repos.Count -eq $originalCount) {
        return @{ Success = $false; Error = "Repository not found in tracker" }
    }

    $result = Save-TrackedRepos -TrackedData $tracked

    if ($result.Success) {
        return @{ Success = $true; Message = "Removed $FullName from tracker" }
    }
    return $result
}

function Update-TrackedRepo {
    <#
    .SYNOPSIS
    Updates a tracked repository with new data and calculates deltas
    #>
    param(
        [Parameter(Mandatory)]
        [string]$FullName,

        [Parameter(Mandatory)]
        [hashtable]$NewData
    )

    $tracked = Get-TrackedRepos

    for ($i = 0; $i -lt $tracked.Repos.Count; $i++) {
        if ($tracked.Repos[$i].full_name -eq $FullName) {
            $old = $tracked.Repos[$i]

            # Calculate deltas
            $delta = @{
                stars  = $NewData.stargazers_count - ($old.last_stars ?? 0)
                issues = $NewData.open_issues_count - ($old.last_issues ?? 0)
            }

            # Update repo data
            $tracked.Repos[$i] = $NewData
            $tracked.Repos[$i]["tracked_at"] = $old.tracked_at
            $tracked.Repos[$i]["last_stars"] = $NewData.stargazers_count
            $tracked.Repos[$i]["last_issues"] = $NewData.open_issues_count
            $tracked.Repos[$i]["last_commit"] = $NewData.pushed_at
            $tracked.Repos[$i]["delta"] = $delta
            $tracked.Repos[$i]["last_checked"] = (Get-Date).ToString("o")

            Save-TrackedRepos -TrackedData $tracked
            return @{ Success = $true; Delta = $delta }
        }
    }

    return @{ Success = $false; Error = "Repository not found" }
}

# ============================================================================
# Search Results Operations
# ============================================================================

function Save-SearchResults {
    <#
    .SYNOPSIS
    Saves search results to JSON
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Query,

        [Parameter(Mandatory)]
        [array]$Results,

        [hashtable]$Filters = @{}
    )

    $data = @{
        Query      = $Query
        Filters    = $Filters
        Results    = $Results
        Count      = $Results.Count
        SearchedAt = (Get-Date).ToString("o")
    }

    $path = Get-StoragePath -Name "SearchResults"
    return Save-Json -Path $path -Data $data
}

function Get-LastSearchResults {
    <#
    .SYNOPSIS
    Gets the last search results
    #>
    $path = Get-StoragePath -Name "SearchResults"
    return Load-Json -Path $path -Default $null
}

# ============================================================================
# Markdown Export
# ============================================================================

function Save-Markdown {
    <#
    .SYNOPSIS
    Saves content as a Markdown file
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [string]$Content
    )

    try {
        $dir = Split-Path -Parent $Path
        if (-not (Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
        }

        [System.IO.File]::WriteAllText($Path, $Content, [System.Text.UTF8Encoding]::new($false))

        return @{ Success = $true; Path = $Path }
    }
    catch {
        return @{ Success = $false; Error = $_.Exception.Message }
    }
}

function Export-SearchResultsMd {
    <#
    .SYNOPSIS
    Exports search results to Markdown format
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Query,

        [Parameter(Mandatory)]
        [array]$Results,

        [hashtable]$Filters = @{}
    )

    $sb = [System.Text.StringBuilder]::new()

    [void]$sb.AppendLine("# GitHub Search Results")
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("**Query:** ``$Query``")
    [void]$sb.AppendLine("**Results:** $($Results.Count)")
    [void]$sb.AppendLine("**Date:** $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")

    if ($Filters.Count -gt 0) {
        [void]$sb.AppendLine("")
        [void]$sb.AppendLine("## Filters")
        foreach ($key in $Filters.Keys) {
            if ($Filters[$key]) {
                [void]$sb.AppendLine("- **$key**: $($Filters[$key])")
            }
        }
    }

    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("## Repositories")
    [void]$sb.AppendLine("")

    foreach ($repo in $Results) {
        [void]$sb.AppendLine("### [$($repo.full_name)]($($repo.html_url))")
        [void]$sb.AppendLine("")
        if ($repo.description) {
            [void]$sb.AppendLine("> $($repo.description)")
            [void]$sb.AppendLine("")
        }
        [void]$sb.AppendLine("| Stat | Value |")
        [void]$sb.AppendLine("|------|-------|")
        [void]$sb.AppendLine("| Stars | $($repo.stargazers_count) |")
        [void]$sb.AppendLine("| Forks | $($repo.forks_count) |")
        [void]$sb.AppendLine("| Language | $($repo.language ?? 'N/A') |")
        [void]$sb.AppendLine("| License | $($repo.license.name ?? 'N/A') |")
        [void]$sb.AppendLine("| Updated | $($repo.updated_at) |")
        [void]$sb.AppendLine("")
    }

    [void]$sb.AppendLine("---")
    [void]$sb.AppendLine("*Generated by Kindware.dev GitHubScout — powered by Kindware.dev*")

    $path = Get-StoragePath -Name "SearchMd"
    return Save-Markdown -Path $path -Content $sb.ToString()
}

function Export-RepoReport {
    <#
    .SYNOPSIS
    Exports a detailed repository report to Markdown
    #>
    param(
        [Parameter(Mandatory)]
        [hashtable]$Repo,

        [string]$Readme = ""
    )

    $sb = [System.Text.StringBuilder]::new()

    [void]$sb.AppendLine("# $($Repo.full_name)")
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("**URL:** $($Repo.html_url)")
    [void]$sb.AppendLine("**Report Date:** $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
    [void]$sb.AppendLine("")

    if ($Repo.description) {
        [void]$sb.AppendLine("## Description")
        [void]$sb.AppendLine("")
        [void]$sb.AppendLine($Repo.description)
        [void]$sb.AppendLine("")
    }

    [void]$sb.AppendLine("## Statistics")
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("| Metric | Value |")
    [void]$sb.AppendLine("|--------|-------|")
    [void]$sb.AppendLine("| Stars | $($Repo.stargazers_count) |")
    [void]$sb.AppendLine("| Forks | $($Repo.forks_count) |")
    [void]$sb.AppendLine("| Watchers | $($Repo.watchers_count) |")
    [void]$sb.AppendLine("| Open Issues | $($Repo.open_issues_count) |")
    [void]$sb.AppendLine("| Language | $($Repo.language ?? 'N/A') |")
    [void]$sb.AppendLine("| License | $($Repo.license.name ?? 'N/A') |")
    [void]$sb.AppendLine("| Created | $($Repo.created_at) |")
    [void]$sb.AppendLine("| Updated | $($Repo.updated_at) |")
    [void]$sb.AppendLine("| Last Push | $($Repo.pushed_at) |")
    [void]$sb.AppendLine("")

    if ($Repo.topics -and $Repo.topics.Count -gt 0) {
        [void]$sb.AppendLine("## Topics")
        [void]$sb.AppendLine("")
        [void]$sb.AppendLine(($Repo.topics | ForEach-Object { "``$_``" }) -join " ")
        [void]$sb.AppendLine("")
    }

    if ($Readme) {
        [void]$sb.AppendLine("## README Preview")
        [void]$sb.AppendLine("")
        [void]$sb.AppendLine("````")
        # Truncate README if too long
        if ($Readme.Length -gt 2000) {
            [void]$sb.AppendLine($Readme.Substring(0, 2000))
            [void]$sb.AppendLine("... [truncated]")
        } else {
            [void]$sb.AppendLine($Readme)
        }
        [void]$sb.AppendLine("````")
        [void]$sb.AppendLine("")
    }

    [void]$sb.AppendLine("---")
    [void]$sb.AppendLine("*Generated by Kindware.dev GitHubScout — powered by Kindware.dev*")

    # Generate filename
    $safeName = $Repo.full_name -replace '/', '_'
    $fileName = "$safeName-$(Get-Date -Format 'yyyyMMdd-HHmmss').md"
    $path = Join-Path (Get-StoragePath -Name "ReportDir") $fileName

    return Save-Markdown -Path $path -Content $sb.ToString()
}

# Initialize storage on module load
Initialize-Storage

# Export module members
# Functions available after dot-sourcing
