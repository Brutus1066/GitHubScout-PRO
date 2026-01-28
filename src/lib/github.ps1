# github.ps1 - GitHub Integration Module for Kindware.dev GitHubScout
# Provides GitHub API access and HTML scraping fallback

# ============================================================================
# Configuration
# ============================================================================
$script:GitHubApiBase = "https://api.github.com"
$script:GitHubHeaders = @{
    "Accept"     = "application/vnd.github+json"
    "User-Agent" = "LazyFrog-GitHubScout/1.0"
}

function Set-GitHubToken {
    <#
    .SYNOPSIS
    Sets the GitHub API token for authenticated requests
    #>
    param(
        [string]$Token
    )

    if ($Token) {
        $script:GitHubHeaders["Authorization"] = "Bearer $Token"
        return $true
    } else {
        $script:GitHubHeaders.Remove("Authorization")
        return $false
    }
}

function Initialize-GitHubAuth {
    <#
    .SYNOPSIS
    Initializes GitHub authentication from config
    #>
    $config = Get-Config
    if ($config.GitHubToken) {
        Set-GitHubToken -Token $config.GitHubToken
        return $true
    }
    return $false
}

# ============================================================================
# API Helper Functions
# ============================================================================

function Invoke-GitHubApi {
    <#
    .SYNOPSIS
    Makes a request to the GitHub API with error handling
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Endpoint,

        [string]$Method = "GET",

        [hashtable]$QueryParams = @{},

        [int]$TimeoutSec = 30
    )

    # Build URL with query parameters
    $url = "$script:GitHubApiBase$Endpoint"

    if ($QueryParams.Count -gt 0) {
        $queryString = ($QueryParams.GetEnumerator() | ForEach-Object {
            "$([System.Uri]::EscapeDataString($_.Key))=$([System.Uri]::EscapeDataString($_.Value))"
        }) -join "&"
        $url = "$url`?$queryString"
    }

    try {
        $response = Invoke-RestMethod -Uri $url -Method $Method -Headers $script:GitHubHeaders -TimeoutSec $TimeoutSec

        # Check rate limit from response headers (not available via Invoke-RestMethod directly)
        return @{
            Success = $true
            Data    = $response
        }
    }
    catch {
        $statusCode = $_.Exception.Response.StatusCode.value__
        $errorMessage = $_.Exception.Message

        # Handle specific error codes
        switch ($statusCode) {
            403 {
                if ($errorMessage -match "rate limit") {
                    return @{
                        Success   = $false
                        Error     = "GitHub API rate limit exceeded. Try adding a personal access token."
                        RateLimit = $true
                    }
                }
                return @{ Success = $false; Error = "Access forbidden: $errorMessage" }
            }
            404 {
                return @{ Success = $false; Error = "Not found" }
            }
            401 {
                return @{ Success = $false; Error = "Authentication failed. Check your GitHub token." }
            }
            default {
                return @{ Success = $false; Error = "API error ($statusCode): $errorMessage" }
            }
        }
    }
}

function Get-RateLimitStatus {
    <#
    .SYNOPSIS
    Gets the current GitHub API rate limit status
    #>
    $result = Invoke-GitHubApi -Endpoint "/rate_limit"

    if ($result.Success) {
        $core = $result.Data.resources.core
        return @{
            Limit     = $core.limit
            Remaining = $core.remaining
            Reset     = [DateTimeOffset]::FromUnixTimeSeconds($core.reset).LocalDateTime
        }
    }

    return $null
}

# ============================================================================
# Search Functions
# ============================================================================

function Search-GitHub {
    <#
    .SYNOPSIS
    Searches GitHub repositories with optional filters
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Query,

        [string]$Language = "",

        [int]$MinStars = 0,

        [ValidateSet("stars", "forks", "updated", "help-wanted-issues", "best-match")]
        [string]$Sort = "best-match",

        [ValidateSet("desc", "asc")]
        [string]$Order = "desc",

        [int]$PerPage = 10,

        [int]$Page = 1
    )

    # Build search query
    $searchQuery = $Query

    if ($Language) {
        $searchQuery += " language:$Language"
    }

    if ($MinStars -gt 0) {
        $searchQuery += " stars:>=$MinStars"
    }

    $queryParams = @{
        q        = $searchQuery
        per_page = $PerPage
        page     = $Page
    }

    if ($Sort -ne "best-match") {
        $queryParams["sort"] = $Sort
        $queryParams["order"] = $Order
    }

    $result = Invoke-GitHubApi -Endpoint "/search/repositories" -QueryParams $queryParams

    if ($result.Success) {
        return @{
            Success    = $true
            TotalCount = $result.Data.total_count
            Items      = $result.Data.items
            Page       = $Page
            PerPage    = $PerPage
        }
    }

    # If rate limited, try HTML scraping fallback
    if ($result.RateLimit) {
        Write-Host "`e[33mRate limited, trying HTML fallback...`e[0m" -NoNewline
        return Search-GitHubHtml -Query $Query -Language $Language -MinStars $MinStars
    }

    return $result
}

function Search-GitHubHtml {
    <#
    .SYNOPSIS
    Fallback search using GitHub HTML (when API rate limited)
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Query,

        [string]$Language = "",

        [int]$MinStars = 0
    )

    try {
        # Build search URL
        $searchUrl = "https://github.com/search?type=repositories&q=$([System.Uri]::EscapeDataString($Query))"

        if ($Language) {
            $searchUrl += "+language%3A$([System.Uri]::EscapeDataString($Language))"
        }

        if ($MinStars -gt 0) {
            $searchUrl += "+stars%3A%3E$MinStars"
        }

        $response = Invoke-WebRequest -Uri $searchUrl -UseBasicParsing -TimeoutSec 30

        # Parse HTML for repository data (basic extraction)
        $html = $response.Content
        $items = @()

        # Extract repo links and basic info using regex
        $repoMatches = [regex]::Matches($html, '<a[^>]+href="/([^/]+/[^/"]+)"[^>]*class="[^"]*Link[^"]*"[^>]*>')

        $seen = @{}
        foreach ($match in $repoMatches) {
            $fullName = $match.Groups[1].Value

            # Skip non-repo links
            if ($fullName -match '^(features|pricing|login|signup|search|trending|explore|topics|collections|events|sponsors|about|security|site|codespaces|github-copilot)' -or
                $fullName -notmatch '^[^/]+/[^/]+$' -or
                $seen.ContainsKey($fullName)) {
                continue
            }

            $seen[$fullName] = $true

            # Create minimal repo object
            $items += @{
                full_name         = $fullName
                html_url          = "https://github.com/$fullName"
                description       = "(Fetched via HTML - limited data)"
                stargazers_count  = 0
                forks_count       = 0
                language          = $Language
                updated_at        = ""
                license           = @{ name = "Unknown" }
            }

            if ($items.Count -ge 10) { break }
        }

        return @{
            Success    = $true
            TotalCount = $items.Count
            Items      = $items
            HtmlFallback = $true
        }
    }
    catch {
        return @{
            Success = $false
            Error   = "HTML fallback failed: $($_.Exception.Message)"
        }
    }
}

# ============================================================================
# Repository Functions
# ============================================================================

function Get-RepoDetails {
    <#
    .SYNOPSIS
    Gets detailed information about a specific repository
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Owner,

        [Parameter(Mandatory)]
        [string]$Repo
    )

    $result = Invoke-GitHubApi -Endpoint "/repos/$Owner/$Repo"

    if ($result.Success) {
        return @{
            Success = $true
            Repo    = $result.Data
        }
    }

    return $result
}

function Get-RepoByFullName {
    <#
    .SYNOPSIS
    Gets repository details using full_name (owner/repo)
    #>
    param(
        [Parameter(Mandatory)]
        [string]$FullName
    )

    $parts = $FullName -split '/'
    if ($parts.Count -ne 2) {
        return @{ Success = $false; Error = "Invalid repository name format. Use owner/repo" }
    }

    return Get-RepoDetails -Owner $parts[0] -Repo $parts[1]
}

function Get-RepoReadme {
    <#
    .SYNOPSIS
    Fetches the README content for a repository
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Owner,

        [Parameter(Mandatory)]
        [string]$Repo
    )

    # First, get the README metadata
    $result = Invoke-GitHubApi -Endpoint "/repos/$Owner/$Repo/readme"

    if (-not $result.Success) {
        return @{ Success = $false; Error = "No README found" }
    }

    # Decode base64 content
    try {
        $content = [System.Text.Encoding]::UTF8.GetString(
            [System.Convert]::FromBase64String($result.Data.content)
        )

        return @{
            Success  = $true
            Content  = $content
            Name     = $result.Data.name
            Path     = $result.Data.path
            Encoding = $result.Data.encoding
        }
    }
    catch {
        return @{ Success = $false; Error = "Failed to decode README: $($_.Exception.Message)" }
    }
}

function Get-RepoContributors {
    <#
    .SYNOPSIS
    Gets the top contributors for a repository
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Owner,

        [Parameter(Mandatory)]
        [string]$Repo,

        [int]$Limit = 10
    )

    $result = Invoke-GitHubApi -Endpoint "/repos/$Owner/$Repo/contributors" -QueryParams @{
        per_page = $Limit
    }

    if ($result.Success) {
        return @{
            Success      = $true
            Contributors = $result.Data
        }
    }

    return $result
}

function Get-RepoLanguages {
    <#
    .SYNOPSIS
    Gets the language breakdown for a repository
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Owner,

        [Parameter(Mandatory)]
        [string]$Repo
    )

    $result = Invoke-GitHubApi -Endpoint "/repos/$Owner/$Repo/languages"

    if ($result.Success) {
        # Calculate percentages
        $total = ($result.Data.PSObject.Properties.Value | Measure-Object -Sum).Sum
        $languages = @{}

        foreach ($prop in $result.Data.PSObject.Properties) {
            $languages[$prop.Name] = @{
                Bytes   = $prop.Value
                Percent = [Math]::Round(($prop.Value / $total) * 100, 1)
            }
        }

        return @{
            Success   = $true
            Languages = $languages
            Total     = $total
        }
    }

    return $result
}

function Get-RepoCommits {
    <#
    .SYNOPSIS
    Gets recent commits for a repository
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Owner,

        [Parameter(Mandatory)]
        [string]$Repo,

        [int]$Limit = 10
    )

    $result = Invoke-GitHubApi -Endpoint "/repos/$Owner/$Repo/commits" -QueryParams @{
        per_page = $Limit
    }

    if ($result.Success) {
        return @{
            Success = $true
            Commits = $result.Data
        }
    }

    return $result
}

function Get-RepoIssues {
    <#
    .SYNOPSIS
    Gets open issues for a repository
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Owner,

        [Parameter(Mandatory)]
        [string]$Repo,

        [ValidateSet("open", "closed", "all")]
        [string]$State = "open",

        [int]$Limit = 10
    )

    $result = Invoke-GitHubApi -Endpoint "/repos/$Owner/$Repo/issues" -QueryParams @{
        state    = $State
        per_page = $Limit
    }

    if ($result.Success) {
        return @{
            Success = $true
            Issues  = $result.Data
        }
    }

    return $result
}

# ============================================================================
# Trending / Discovery
# ============================================================================

function Get-TrendingRepos {
    <#
    .SYNOPSIS
    Gets trending repositories (repos created/updated recently with high stars)
    #>
    param(
        [string]$Language = "",

        [ValidateSet("daily", "weekly", "monthly")]
        [string]$Since = "weekly",

        [int]$Limit = 10
    )

    # Calculate date range
    $daysBack = switch ($Since) {
        "daily"   { 1 }
        "weekly"  { 7 }
        "monthly" { 30 }
    }

    $dateStr = (Get-Date).AddDays(-$daysBack).ToString("yyyy-MM-dd")

    $query = "created:>$dateStr"
    if ($Language) {
        $query += " language:$Language"
    }

    $result = Invoke-GitHubApi -Endpoint "/search/repositories" -QueryParams @{
        q        = $query
        sort     = "stars"
        order    = "desc"
        per_page = $Limit
    }

    if ($result.Success) {
        return @{
            Success = $true
            Items   = $result.Data.items
        }
    }

    return $result
}

# ============================================================================
# Utility Functions
# ============================================================================

function Test-RepoExists {
    <#
    .SYNOPSIS
    Tests if a repository exists
    #>
    param(
        [Parameter(Mandatory)]
        [string]$FullName
    )

    $result = Get-RepoByFullName -FullName $FullName
    return $result.Success
}

function Format-RepoForDisplay {
    <#
    .SYNOPSIS
    Formats a repository object for display
    #>
    param(
        [Parameter(Mandatory)]
        $Repo
    )

    $stars = Format-Number -Number $Repo.stargazers_count
    $forks = Format-Number -Number $Repo.forks_count
    $lang = if ($Repo.language) { $Repo.language } else { "N/A" }

    return @{
        Name        = $Repo.full_name
        Description = if ($Repo.description) { $Repo.description } else { "(No description)" }
        Stats       = "$stars | Forks: $forks | Lang: $lang"
        Url         = $Repo.html_url
        Updated     = $Repo.updated_at
    }
}

# Initialize auth on module load
Initialize-GitHubAuth

# Export module members
# Functions available after dot-sourcing
