# inspector.ps1 - Repository Inspector Tool for Kindware.dev GitHubScout
# Provides detailed inspection of a single GitHub repository

function Show-InspectorTool {
    <#
    .SYNOPSIS
    Main entry point for the inspector tool
    #>
    param(
        [int]$PanelX,
        [int]$PanelY,
        [int]$PanelWidth,
        [int]$PanelHeight
    )

    $c = $Global:Colors
    $state = @{
        Repo      = $null
        RepoName  = ""
        Readme    = ""
        Languages = @{}
        Mode      = "input"  # input, loading, view, readme
        Tab       = 0        # 0=overview, 1=readme, 2=stats
        Message   = ""
    }

    while ($true) {
        # Clear panel area
        Clear-InspectorPanel -X $PanelX -Y $PanelY -Width $PanelWidth -Height $PanelHeight

        # Draw panel frame
        Draw-Box -X $PanelX -Y $PanelY -Width $PanelWidth -Height $PanelHeight -Color $c.Magenta -Title "Repo Inspector"

        switch ($state.Mode) {
            "input" {
                $result = Show-InspectorInput -State $state -X $PanelX -Y $PanelY -Width $PanelWidth -Height $PanelHeight
                if ($result -eq "back") { return "back" }
                if ($result -eq "load") { $state.Mode = "loading" }
            }
            "loading" {
                Load-RepoData -State $state -X $PanelX -Y $PanelY -Width $PanelWidth
                if ($state.Repo) {
                    $state.Mode = "view"
                } else {
                    $state.Mode = "input"
                }
            }
            "view" {
                $result = Show-InspectorView -State $state -X $PanelX -Y $PanelY -Width $PanelWidth -Height $PanelHeight
                switch ($result) {
                    "back" { $state.Mode = "input"; $state.Repo = $null }
                    "readme" { $state.Mode = "readme" }
                    "export" { Export-RepoData -State $state }
                    "track" { Track-InspectedRepo -State $state }
                }
            }
            "readme" {
                $result = Show-ReadmeView -State $state -X $PanelX -Y $PanelY -Width $PanelWidth -Height $PanelHeight
                if ($result -eq "back") { $state.Mode = "view" }
            }
        }
    }
}

function Clear-InspectorPanel {
    param([int]$X, [int]$Y, [int]$Width, [int]$Height)

    for ($i = 0; $i -lt $Height; $i++) {
        Set-CursorPosition -X $X -Y ($Y + $i)
        Write-Host (' ' * $Width) -NoNewline
    }
}

function Show-InspectorInput {
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

    # Instructions
    Write-At -X $innerX -Y $innerY -Text "Inspect a GitHub Repository" -Color $c.Cyan
    Write-At -X $innerX -Y ($innerY + 2) -Text "Enter repository (owner/repo):" -Color $c.White
    Write-At -X $innerX -Y ($innerY + 3) -Text "  $($c.Dim)Examples: facebook/react, microsoft/typescript$($c.Reset)"

    # Recent inspections hint
    $lastSearch = Get-LastSearchResults
    if ($lastSearch -and $lastSearch.Results.Count -gt 0) {
        Write-At -X $innerX -Y ($innerY + 5) -Text "Recent search results available - or enter a new repo" -Color $c.Dim
    }

    # Message
    if ($State.Message) {
        Write-At -X $innerX -Y ($innerY + 7) -Text $State.Message -Color $c.Yellow
        $State.Message = ""
    }

    Write-At -X $innerX -Y ($Y + $Height - 3) -Text "[Enter] Inspect  [Esc] Back" -Color $c.Dim

    # Input
    Show-Cursor
    Set-CursorPosition -X $innerX -Y ($innerY + 9)
    Write-Host "> " -ForegroundColor Magenta -NoNewline
    $input = Read-Host
    Hide-Cursor

    if (-not $input) {
        return "back"
    }

    # Validate format
    if ($input -notmatch '^[^/]+/[^/]+$') {
        $State.Message = "Invalid format. Use: owner/repo"
        return "continue"
    }

    $State.RepoName = $input
    return "load"
}

function Load-RepoData {
    param(
        [hashtable]$State,
        [int]$X,
        [int]$Y,
        [int]$Width
    )

    $c = $Global:Colors
    $innerX = $X + 2
    $innerY = $Y + 4

    Write-At -X $innerX -Y $innerY -Text "Loading repository data..." -Color $c.Yellow

    $parts = $State.RepoName -split '/'

    # Fetch repo details
    Write-At -X $innerX -Y ($innerY + 1) -Text "  Fetching repository info..." -Color $c.Dim
    $repoResult = Get-RepoDetails -Owner $parts[0] -Repo $parts[1]

    if (-not $repoResult.Success) {
        $State.Message = "Error: $($repoResult.Error)"
        $State.Repo = $null
        return
    }

    $State.Repo = $repoResult.Repo

    # Fetch README
    Write-At -X $innerX -Y ($innerY + 2) -Text "  Fetching README..." -Color $c.Dim
    $readmeResult = Get-RepoReadme -Owner $parts[0] -Repo $parts[1]
    if ($readmeResult.Success) {
        $State.Readme = $readmeResult.Content
    } else {
        $State.Readme = "(No README available)"
    }

    # Fetch languages
    Write-At -X $innerX -Y ($innerY + 3) -Text "  Fetching language breakdown..." -Color $c.Dim
    $langResult = Get-RepoLanguages -Owner $parts[0] -Repo $parts[1]
    if ($langResult.Success) {
        $State.Languages = $langResult.Languages
    }

    Write-At -X $innerX -Y ($innerY + 4) -Text "  Done!" -Color $c.BrightGreen
    Start-Sleep -Milliseconds 300
}

function Show-InspectorView {
    param(
        [hashtable]$State,
        [int]$X,
        [int]$Y,
        [int]$Width,
        [int]$Height
    )

    $c = $Global:Colors
    $repo = $State.Repo
    $innerX = $X + 2
    $innerY = $Y + 2
    $innerWidth = $Width - 4

    # Header
    Write-At -X $innerX -Y $innerY -Text "$($c.BrightMagenta)$($repo.full_name)$($c.Reset)"
    Write-At -X $innerX -Y ($innerY + 1) -Text "$($c.Dim)$($repo.html_url)$($c.Reset)"

    # Description
    $descY = $innerY + 3
    if ($repo.description) {
        $desc = $repo.description
        if ($desc.Length -gt $innerWidth) {
            $desc = $desc.Substring(0, $innerWidth - 3) + "..."
        }
        Write-At -X $innerX -Y $descY -Text $desc -Color $c.White
    } else {
        Write-At -X $innerX -Y $descY -Text "(No description)" -Color $c.Dim
    }

    # Stats box
    $statsY = $descY + 2
    Write-At -X $innerX -Y $statsY -Text "Statistics" -Color $c.Cyan
    Draw-HorizontalLine -X $innerX -Y ($statsY + 1) -Length 50 -Color $c.Dim

    $col1X = $innerX
    $col2X = $innerX + 25
    $statsDataY = $statsY + 2

    Write-At -X $col1X -Y $statsDataY -Text "Stars:    $($c.Yellow)$(Format-Number -Number $repo.stargazers_count)$($c.Reset)"
    Write-At -X $col2X -Y $statsDataY -Text "Forks:    $($c.Cyan)$(Format-Number -Number $repo.forks_count)$($c.Reset)"

    Write-At -X $col1X -Y ($statsDataY + 1) -Text "Watchers: $($c.Magenta)$(Format-Number -Number $repo.watchers_count)$($c.Reset)"
    Write-At -X $col2X -Y ($statsDataY + 1) -Text "Issues:   $($c.Red)$($repo.open_issues_count)$($c.Reset)"

    Write-At -X $col1X -Y ($statsDataY + 2) -Text "Size:     $($c.Dim)$(Format-Size -Bytes ($repo.size * 1024))$($c.Reset)"
    Write-At -X $col2X -Y ($statsDataY + 2) -Text "Default:  $($c.Dim)$($repo.default_branch)$($c.Reset)"

    # Metadata
    $metaY = $statsDataY + 4
    Write-At -X $innerX -Y $metaY -Text "Metadata" -Color $c.Cyan
    Draw-HorizontalLine -X $innerX -Y ($metaY + 1) -Length 50 -Color $c.Dim

    $metaDataY = $metaY + 2
    Write-At -X $col1X -Y $metaDataY -Text "Language: $($c.Green)$($repo.language ?? 'N/A')$($c.Reset)"

    $license = if ($repo.license) { $repo.license.name } else { "N/A" }
    Write-At -X $col2X -Y $metaDataY -Text "License:  $($c.Blue)$license$($c.Reset)"

    Write-At -X $col1X -Y ($metaDataY + 1) -Text "Created:  $($c.Dim)$($repo.created_at.Substring(0, 10))$($c.Reset)"
    Write-At -X $col2X -Y ($metaDataY + 1) -Text "Updated:  $($c.Dim)$($repo.updated_at.Substring(0, 10))$($c.Reset)"

    Write-At -X $col1X -Y ($metaDataY + 2) -Text "Pushed:   $($c.Dim)$($repo.pushed_at.Substring(0, 10))$($c.Reset)"

    $archived = if ($repo.archived) { "$($c.Red)Yes$($c.Reset)" } else { "$($c.Green)No$($c.Reset)" }
    Write-At -X $col2X -Y ($metaDataY + 2) -Text "Archived: $archived"

    # Languages breakdown
    if ($State.Languages.Count -gt 0) {
        $langY = $metaDataY + 4
        Write-At -X $innerX -Y $langY -Text "Languages" -Color $c.Cyan
        Draw-HorizontalLine -X $innerX -Y ($langY + 1) -Length 50 -Color $c.Dim

        $langDataY = $langY + 2
        $langIdx = 0
        foreach ($lang in ($State.Languages.GetEnumerator() | Sort-Object { $_.Value.Percent } -Descending | Select-Object -First 5)) {
            $barWidth = [Math]::Floor($lang.Value.Percent / 5)
            $bar = [char]0x2588 * $barWidth

            Write-At -X $innerX -Y ($langDataY + $langIdx) -Text "$($lang.Key.PadRight(12)) $($c.Cyan)$bar$($c.Reset) $($lang.Value.Percent)%"
            $langIdx++
        }
    }

    # Topics
    if ($repo.topics -and $repo.topics.Count -gt 0) {
        $topicsY = $Y + $Height - 6
        $topicsStr = ($repo.topics | Select-Object -First 8) -join ", "
        if ($topicsStr.Length -gt $innerWidth - 10) {
            $topicsStr = $topicsStr.Substring(0, $innerWidth - 13) + "..."
        }
        Write-At -X $innerX -Y $topicsY -Text "Topics: $($c.Dim)$topicsStr$($c.Reset)"
    }

    # Message
    if ($State.Message) {
        Write-At -X $innerX -Y ($Y + $Height - 5) -Text $State.Message -Color $c.BrightYellow
        $State.Message = ""
    }

    # Controls
    Write-At -X $innerX -Y ($Y + $Height - 3) -Text "[R] README  [T] Track  [E] Export  [O] Open  [Esc] Back" -Color $c.Dim

    # Handle input
    $key = Get-KeyPress -Wait

    switch ($key.Char.ToString().ToLower()) {
        'r' { return "readme" }
        't' { return "track" }
        'e' { return "export" }
        'o' {
            Start-Process $repo.html_url
            return "continue"
        }
    }

    if ($key.Key -eq "Escape") {
        return "back"
    }

    return "continue"
}

function Show-ReadmeView {
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
    $innerHeight = $Height - 5

    Clear-InspectorPanel -X $X -Y $Y -Width $Width -Height $Height
    Draw-Box -X $X -Y $Y -Width $Width -Height $Height -Color $c.Blue -Title "README: $($State.Repo.full_name)"

    $lines = $State.Readme -split "`n"
    $scrollOffset = 0
    $totalLines = $lines.Count

    while ($true) {
        # Draw content
        for ($i = 0; $i -lt $innerHeight; $i++) {
            $lineIdx = $scrollOffset + $i
            Set-CursorPosition -X $innerX -Y ($innerY + $i)

            if ($lineIdx -lt $totalLines) {
                $line = $lines[$lineIdx]
                # Strip some markdown formatting for display
                $line = $line -replace '^\s*#+\s*', ''  # Headers
                $line = $line -replace '\*\*([^*]+)\*\*', '$1'  # Bold
                $line = $line -replace '\*([^*]+)\*', '$1'  # Italic
                $line = $line -replace '`([^`]+)`', '$1'  # Code

                if ($line.Length -gt $innerWidth) {
                    $line = $line.Substring(0, $innerWidth - 3) + "..."
                }
                Write-Host $line.PadRight($innerWidth) -NoNewline
            } else {
                Write-Host (' ' * $innerWidth) -NoNewline
            }
        }

        # Scroll indicator
        if ($totalLines -gt $innerHeight) {
            $percent = [Math]::Floor(($scrollOffset / [Math]::Max(1, $totalLines - $innerHeight)) * 100)
            Write-At -X ($X + $Width - 10) -Y ($Y + $Height - 3) -Text "[$percent%]" -Color $c.Dim
        }

        Write-At -X $innerX -Y ($Y + $Height - 2) -Text "[Up/Down] Scroll  [PgUp/PgDn] Page  [Esc] Back" -Color $c.Dim

        # Handle input
        $key = Get-KeyPress -Wait

        switch ($key.Key) {
            "UpArrow" {
                if ($scrollOffset -gt 0) { $scrollOffset-- }
            }
            "DownArrow" {
                if ($scrollOffset -lt $totalLines - $innerHeight) { $scrollOffset++ }
            }
            "PageUp" {
                $scrollOffset = [Math]::Max(0, $scrollOffset - $innerHeight)
            }
            "PageDown" {
                $scrollOffset = [Math]::Min($totalLines - $innerHeight, $scrollOffset + $innerHeight)
            }
            "Home" {
                $scrollOffset = 0
            }
            "End" {
                $scrollOffset = [Math]::Max(0, $totalLines - $innerHeight)
            }
            "Escape" {
                return "back"
            }
        }
    }
}

function Export-RepoData {
    param([hashtable]$State)

    $repoHash = @{}
    foreach ($prop in $State.Repo.PSObject.Properties) {
        $repoHash[$prop.Name] = $prop.Value
    }

    $result = Export-RepoReport -Repo $repoHash -Readme $State.Readme

    if ($result.Success) {
        $State.Message = "Exported to: $($result.Path)"
    } else {
        $State.Message = "Export failed: $($result.Error)"
    }
}

function Track-InspectedRepo {
    param([hashtable]$State)

    $repoHash = @{}
    foreach ($prop in $State.Repo.PSObject.Properties) {
        $repoHash[$prop.Name] = $prop.Value
    }

    $result = Add-TrackedRepo -Repo $repoHash

    if ($result.Success) {
        $State.Message = "Added to tracker!"
    } else {
        $State.Message = $result.Error
    }
}

function Format-Size {
    param([long]$Bytes)

    if ($Bytes -ge 1GB) {
        return "{0:N1} GB" -f ($Bytes / 1GB)
    } elseif ($Bytes -ge 1MB) {
        return "{0:N1} MB" -f ($Bytes / 1MB)
    } elseif ($Bytes -ge 1KB) {
        return "{0:N1} KB" -f ($Bytes / 1KB)
    }
    return "$Bytes B"
}

# Export functions
# Functions available after dot-sourcing
