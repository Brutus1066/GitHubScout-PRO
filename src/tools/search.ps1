# search.ps1 - GitHub Search Tool for Kindware.dev GitHubScout
# Provides interactive repository search functionality

function Show-SearchTool {
    <#
    .SYNOPSIS
    Main entry point for the search tool
    #>
    param(
        [int]$PanelX,
        [int]$PanelY,
        [int]$PanelWidth,
        [int]$PanelHeight
    )

    $c = $Global:Colors
    $state = @{
        Query       = ""
        Language    = ""
        MinStars    = 0
        Sort        = "best-match"
        Results     = @()
        TotalCount  = 0
        CurrentPage = 1
        SelectedIdx = 0
        Mode        = "input"  # input, results, detail
        Message     = ""
    }

    while ($true) {
        # Clear panel area
        Clear-Panel -X $PanelX -Y $PanelY -Width $PanelWidth -Height $PanelHeight

        # Draw panel frame
        Draw-Box -X $PanelX -Y $PanelY -Width $PanelWidth -Height $PanelHeight -Color $c.Green -Title "Search GitHub"

        switch ($state.Mode) {
            "input" {
                $result = Show-SearchInput -State $state -X $PanelX -Y $PanelY -Width $PanelWidth -Height $PanelHeight
                if ($result -eq "back") { return "back" }
                if ($result -eq "search") {
                    $state.Mode = "searching"
                }
            }
            "searching" {
                Show-SearchProgress -X $PanelX -Y $PanelY -Width $PanelWidth
                $searchResult = Perform-Search -State $state
                if ($searchResult.Success) {
                    $state.Results = $searchResult.Items
                    $state.TotalCount = $searchResult.TotalCount
                    $state.Mode = "results"
                    $state.Message = "Found $($state.TotalCount) repositories"
                } else {
                    $state.Message = "Error: $($searchResult.Error)"
                    $state.Mode = "input"
                }
            }
            "results" {
                $result = Show-SearchResults -State $state -X $PanelX -Y $PanelY -Width $PanelWidth -Height $PanelHeight
                switch ($result.Action) {
                    "back" { $state.Mode = "input" }
                    "select" {
                        $state.SelectedIdx = $result.Index
                        $state.Mode = "detail"
                    }
                    "export" { Export-CurrentResults -State $state }
                    "track" { Add-ToTracker -Repo $state.Results[$result.Index] }
                    "quit" { return "back" }
                }
            }
            "detail" {
                $result = Show-RepoDetail -Repo $state.Results[$state.SelectedIdx] -X $PanelX -Y $PanelY -Width $PanelWidth -Height $PanelHeight
                switch ($result) {
                    "back" { $state.Mode = "results" }
                    "track" {
                        Add-ToTracker -Repo $state.Results[$state.SelectedIdx]
                        $state.Mode = "results"
                    }
                }
            }
        }
    }
}

function Clear-Panel {
    param([int]$X, [int]$Y, [int]$Width, [int]$Height)

    for ($i = 0; $i -lt $Height; $i++) {
        Set-CursorPosition -X $X -Y ($Y + $i)
        Write-Host (' ' * $Width) -NoNewline
    }
}

function Show-SearchInput {
    param(
        [hashtable]$State,
        [int]$X,
        [int]$Y,
        [int]$Width,
        [int]$Height
    )

    $c = $Global:Colors
    $innerX = $X + 2
    $innerY = $Y + 2
    $innerWidth = $Width - 4

    # Show instructions
    Write-At -X $innerX -Y $innerY -Text "Enter search criteria:" -Color $c.Cyan

    # Query input
    Write-At -X $innerX -Y ($innerY + 2) -Text "Search query:" -Color $c.White
    Write-At -X $innerX -Y ($innerY + 3) -Text "  $($c.Dim)(e.g., 'cli tools', 'react hooks')$($c.Reset)"

    # Language filter
    Write-At -X $innerX -Y ($innerY + 5) -Text "Language filter:" -Color $c.White
    Write-At -X $innerX -Y ($innerY + 6) -Text "  $($c.Dim)(e.g., 'python', 'rust', 'go')$($c.Reset)"

    # Min stars
    Write-At -X $innerX -Y ($innerY + 8) -Text "Minimum stars:" -Color $c.White
    Write-At -X $innerX -Y ($innerY + 9) -Text "  $($c.Dim)(e.g., '100', '1000')$($c.Reset)"

    # Sort option
    Write-At -X $innerX -Y ($innerY + 11) -Text "Sort by:" -Color $c.White
    Write-At -X $innerX -Y ($innerY + 12) -Text "  $($c.Dim)(stars/forks/updated/best-match)$($c.Reset)"

    # Show message if any
    if ($State.Message) {
        Write-At -X $innerX -Y ($innerY + 14) -Text $State.Message -Color $c.Yellow
        $State.Message = ""
    }

    # Controls
    Write-At -X $innerX -Y ($Y + $Height - 3) -Text "[Enter] Search  [Esc] Back" -Color $c.Dim

    # Show cursor and get input
    Show-Cursor

    # Get query
    Set-CursorPosition -X ($innerX + 14) -Y ($innerY + 2)
    Write-Host ": " -NoNewline
    if ($State.Query) { Write-Host $State.Query -ForegroundColor Yellow -NoNewline }
    $queryInput = Read-Host
    if ($queryInput) { $State.Query = $queryInput }
    if (-not $State.Query) {
        Write-At -X $innerX -Y ($innerY + 14) -Text "Query is required!" -Color $c.Red
        Start-Sleep -Milliseconds 1500
        return "continue"
    }

    # Get language
    Set-CursorPosition -X ($innerX + 17) -Y ($innerY + 5)
    Write-Host ": " -NoNewline
    if ($State.Language) { Write-Host $State.Language -ForegroundColor Yellow -NoNewline }
    $langInput = Read-Host
    if ($langInput) { $State.Language = $langInput }

    # Get min stars
    Set-CursorPosition -X ($innerX + 15) -Y ($innerY + 8)
    Write-Host ": " -NoNewline
    $starsInput = Read-Host
    if ($starsInput -match '^\d+$') { $State.MinStars = [int]$starsInput }

    # Get sort
    Set-CursorPosition -X ($innerX + 9) -Y ($innerY + 11)
    Write-Host ": " -NoNewline
    $sortInput = Read-Host
    if ($sortInput -in @("stars", "forks", "updated", "best-match")) {
        $State.Sort = $sortInput
    }

    Hide-Cursor
    return "search"
}

function Show-SearchProgress {
    param([int]$X, [int]$Y, [int]$Width)

    $c = $Global:Colors
    Write-At -X ($X + 2) -Y ($Y + 5) -Text "$($c.Yellow)Searching GitHub...$($c.Reset)"

    $spinChars = @('|', '/', '-', '\')
    for ($i = 0; $i -lt 8; $i++) {
        Write-At -X ($X + 22) -Y ($Y + 5) -Text $spinChars[$i % 4] -Color $c.BrightYellow
        Start-Sleep -Milliseconds 100
    }
}

function Perform-Search {
    param([hashtable]$State)

    $params = @{
        Query    = $State.Query
        PerPage  = 10
        Page     = $State.CurrentPage
    }

    if ($State.Language) { $params["Language"] = $State.Language }
    if ($State.MinStars -gt 0) { $params["MinStars"] = $State.MinStars }
    if ($State.Sort -ne "best-match") { $params["Sort"] = $State.Sort }

    $result = Search-GitHub @params

    # Save results
    if ($result.Success -and $result.Items.Count -gt 0) {
        Save-SearchResults -Query $State.Query -Results $result.Items -Filters @{
            Language = $State.Language
            MinStars = $State.MinStars
            Sort     = $State.Sort
        }
    }

    return $result
}

function Show-SearchResults {
    param(
        [hashtable]$State,
        [int]$X,
        [int]$Y,
        [int]$Width,
        [int]$Height
    )

    $c = $Global:Colors
    $innerX = $X + 2
    $innerY = $Y + 2
    $listHeight = $Height - 8

    # Header
    Write-At -X $innerX -Y $innerY -Text "Results for: $($c.Cyan)$($State.Query)$($c.Reset) ($($State.TotalCount) found)"

    # Results list
    $visibleItems = [Math]::Min($State.Results.Count, $listHeight - 2)

    for ($i = 0; $i -lt $visibleItems; $i++) {
        $repo = $State.Results[$i]
        $itemY = $innerY + 2 + $i

        $stars = Format-Number -Number $repo.stargazers_count
        $lang = if ($repo.language) { $repo.language } else { "-" }

        # Truncate name if needed
        $displayName = $repo.full_name
        $maxNameLen = $Width - 25
        if ($displayName.Length -gt $maxNameLen) {
            $displayName = $displayName.Substring(0, $maxNameLen - 3) + "..."
        }

        if ($i -eq $State.SelectedIdx) {
            Write-At -X $innerX -Y $itemY -Text "$($c.BgCyan)$($c.Black) > $displayName $($c.Reset)"
            Write-At -X ($X + $Width - 18) -Y $itemY -Text "$($c.BgCyan)$($c.Black)$stars | $lang$($c.Reset)"
        } else {
            Write-At -X $innerX -Y $itemY -Text "   $displayName"
            Write-At -X ($X + $Width - 18) -Y $itemY -Text "$($c.Dim)$stars | $lang$($c.Reset)"
        }
    }

    # Show selected repo description
    if ($State.Results.Count -gt 0 -and $State.SelectedIdx -lt $State.Results.Count) {
        $selected = $State.Results[$State.SelectedIdx]
        $desc = if ($selected.description) {
            $selected.description
        } else {
            "(No description)"
        }

        if ($desc.Length -gt $Width - 6) {
            $desc = $desc.Substring(0, $Width - 9) + "..."
        }

        Write-At -X $innerX -Y ($Y + $Height - 5) -Text "$($c.Dim)$desc$($c.Reset)"
    }

    # Controls
    Write-At -X $innerX -Y ($Y + $Height - 3) -Text "[Enter] View  [T] Track  [E] Export  [Esc] Back" -Color $c.Dim

    # Handle input
    $key = Get-KeyPress -Wait

    switch ($key.Key) {
        "UpArrow" {
            if ($State.SelectedIdx -gt 0) { $State.SelectedIdx-- }
            return @{ Action = "continue" }
        }
        "DownArrow" {
            if ($State.SelectedIdx -lt $State.Results.Count - 1) { $State.SelectedIdx++ }
            return @{ Action = "continue" }
        }
        "Enter" {
            return @{ Action = "select"; Index = $State.SelectedIdx }
        }
        "Escape" {
            return @{ Action = "back" }
        }
        default {
            switch ($key.Char.ToString().ToLower()) {
                't' { return @{ Action = "track"; Index = $State.SelectedIdx } }
                'e' { return @{ Action = "export" } }
                'q' { return @{ Action = "quit" } }
            }
        }
    }

    # Number key quick select
    if ($key.Char -ge '1' -and $key.Char -le '9') {
        $idx = [int]::Parse($key.Char.ToString()) - 1
        if ($idx -lt $State.Results.Count) {
            return @{ Action = "select"; Index = $idx }
        }
    }

    return @{ Action = "continue" }
}

function Show-RepoDetail {
    param(
        [object]$Repo,
        [int]$X,
        [int]$Y,
        [int]$Width,
        [int]$Height
    )

    $c = $Global:Colors
    $innerX = $X + 2
    $innerY = $Y + 2
    $innerWidth = $Width - 4

    # Repo name and URL
    Write-At -X $innerX -Y $innerY -Text "$($c.BrightCyan)$($Repo.full_name)$($c.Reset)"
    Write-At -X $innerX -Y ($innerY + 1) -Text "$($c.Dim)$($Repo.html_url)$($c.Reset)"

    # Description
    $descY = $innerY + 3
    Write-At -X $innerX -Y $descY -Text "Description:" -Color $c.White
    $desc = if ($Repo.description) { $Repo.description } else { "(No description)" }
    $descLines = Split-TextToLines -Text $desc -MaxWidth ($innerWidth - 2)
    for ($i = 0; $i -lt [Math]::Min($descLines.Count, 3); $i++) {
        Write-At -X $innerX -Y ($descY + 1 + $i) -Text $descLines[$i] -Color $c.Dim
    }

    # Stats
    $statsY = $descY + 5
    Write-At -X $innerX -Y $statsY -Text "Statistics:" -Color $c.White

    $stats = @(
        @{ Label = "Stars"; Value = Format-Number -Number $Repo.stargazers_count; Color = $c.Yellow }
        @{ Label = "Forks"; Value = Format-Number -Number $Repo.forks_count; Color = $c.Cyan }
        @{ Label = "Watchers"; Value = Format-Number -Number $Repo.watchers_count; Color = $c.Magenta }
        @{ Label = "Issues"; Value = $Repo.open_issues_count; Color = $c.Red }
    )

    $statX = $innerX
    foreach ($stat in $stats) {
        Write-At -X $statX -Y ($statsY + 1) -Text "$($stat.Label): $($stat.Color)$($stat.Value)$($c.Reset)"
        $statX += 16
    }

    # Language and License
    Write-At -X $innerX -Y ($statsY + 3) -Text "Language: $($c.Green)$($Repo.language ?? 'N/A')$($c.Reset)"
    $license = if ($Repo.license) { $Repo.license.name } else { "N/A" }
    Write-At -X ($innerX + 25) -Y ($statsY + 3) -Text "License: $($c.Blue)$license$($c.Reset)"

    # Dates
    Write-At -X $innerX -Y ($statsY + 5) -Text "Created: $($c.Dim)$($Repo.created_at.Substring(0, 10))$($c.Reset)"
    Write-At -X ($innerX + 25) -Y ($statsY + 5) -Text "Updated: $($c.Dim)$($Repo.updated_at.Substring(0, 10))$($c.Reset)"

    # Topics
    if ($Repo.topics -and $Repo.topics.Count -gt 0) {
        Write-At -X $innerX -Y ($statsY + 7) -Text "Topics: $($c.Dim)$(($Repo.topics | Select-Object -First 5) -join ', ')$($c.Reset)"
    }

    # Controls
    Write-At -X $innerX -Y ($Y + $Height - 3) -Text "[T] Track  [O] Open in Browser  [R] View README  [Esc] Back" -Color $c.Dim

    # Handle input
    $key = Get-KeyPress -Wait

    switch ($key.Char.ToString().ToLower()) {
        't' { return "track" }
        'o' {
            Start-Process $Repo.html_url
            return "continue"
        }
        'r' {
            Show-ReadmePreview -Repo $Repo -X $X -Y $Y -Width $Width -Height $Height
            return "continue"
        }
    }

    if ($key.Key -eq "Escape") {
        return "back"
    }

    return "continue"
}

function Show-ReadmePreview {
    param(
        [object]$Repo,
        [int]$X,
        [int]$Y,
        [int]$Width,
        [int]$Height
    )

    $c = $Global:Colors
    $parts = $Repo.full_name -split '/'

    Clear-Panel -X $X -Y $Y -Width $Width -Height $Height
    Draw-Box -X $X -Y $Y -Width $Width -Height $Height -Color $c.Blue -Title "README: $($Repo.full_name)"

    Write-At -X ($X + 2) -Y ($Y + 2) -Text "Fetching README..." -Color $c.Yellow

    $readme = Get-RepoReadme -Owner $parts[0] -Repo $parts[1]

    Clear-Panel -X ($X + 1) -Y ($Y + 1) -Width ($Width - 2) -Height ($Height - 2)
    Draw-Box -X $X -Y $Y -Width $Width -Height $Height -Color $c.Blue -Title "README: $($Repo.full_name)"

    if ($readme.Success) {
        $lines = $readme.Content -split "`n"
        $maxLines = $Height - 5
        $innerWidth = $Width - 4

        for ($i = 0; $i -lt [Math]::Min($lines.Count, $maxLines); $i++) {
            $line = $lines[$i]
            if ($line.Length -gt $innerWidth) {
                $line = $line.Substring(0, $innerWidth - 3) + "..."
            }
            Write-At -X ($X + 2) -Y ($Y + 2 + $i) -Text $line -Color $c.White
        }

        if ($lines.Count -gt $maxLines) {
            Write-At -X ($X + 2) -Y ($Y + $Height - 3) -Text "... [$(($lines.Count - $maxLines)) more lines]" -Color $c.Dim
        }
    } else {
        Write-At -X ($X + 2) -Y ($Y + 2) -Text "Could not load README: $($readme.Error)" -Color $c.Red
    }

    Write-At -X ($X + 2) -Y ($Y + $Height - 2) -Text "Press any key to continue..." -Color $c.Dim
    Get-KeyPress -Wait | Out-Null
}

function Export-CurrentResults {
    param([hashtable]$State)

    $c = $Global:Colors

    $result = Export-SearchResultsMd -Query $State.Query -Results $State.Results -Filters @{
        Language = $State.Language
        MinStars = $State.MinStars
        Sort     = $State.Sort
    }

    if ($result.Success) {
        $State.Message = "Exported to: $($result.Path)"
    } else {
        $State.Message = "Export failed: $($result.Error)"
    }
}

function Add-ToTracker {
    param([object]$Repo)

    # Convert to hashtable if needed
    $repoHash = @{}
    foreach ($prop in $Repo.PSObject.Properties) {
        $repoHash[$prop.Name] = $prop.Value
    }

    $result = Add-TrackedRepo -Repo $repoHash
    return $result
}

function Split-TextToLines {
    param(
        [string]$Text,
        [int]$MaxWidth
    )

    $words = $Text -split '\s+'
    $lines = @()
    $currentLine = ""

    foreach ($word in $words) {
        if (($currentLine.Length + $word.Length + 1) -le $MaxWidth) {
            if ($currentLine) { $currentLine += " " }
            $currentLine += $word
        } else {
            if ($currentLine) { $lines += $currentLine }
            $currentLine = $word
        }
    }

    if ($currentLine) { $lines += $currentLine }
    return $lines
}

# Export functions
# Functions available after dot-sourcing
