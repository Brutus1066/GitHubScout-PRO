# tracker.ps1 - Repository Tracker Tool for Kindware.dev GitHubScout
# Manages a watch list of GitHub repositories with change tracking

function Show-TrackerTool {
    <#
    .SYNOPSIS
    Main entry point for the tracker tool
    #>
    param(
        [int]$PanelX,
        [int]$PanelY,
        [int]$PanelWidth,
        [int]$PanelHeight
    )

    $c = $Global:Colors
    $state = @{
        Repos       = @()
        SelectedIdx = 0
        Mode        = "list"  # list, add, detail
        Message     = ""
        LastChecked = $null
    }

    # Load tracked repos
    $tracked = Get-TrackedRepos
    $state.Repos = $tracked.Repos
    $state.LastChecked = $tracked.LastChecked

    while ($true) {
        # Clear panel area
        Clear-TrackerPanel -X $PanelX -Y $PanelY -Width $PanelWidth -Height $PanelHeight

        # Draw panel frame
        Draw-Box -X $PanelX -Y $PanelY -Width $PanelWidth -Height $PanelHeight -Color $c.Yellow -Title "Repo Tracker"

        switch ($state.Mode) {
            "list" {
                $result = Show-TrackerList -State $state -X $PanelX -Y $PanelY -Width $PanelWidth -Height $PanelHeight
                switch ($result.Action) {
                    "back" { return "back" }
                    "add" { $state.Mode = "add" }
                    "refresh" {
                        Refresh-AllTracked -State $state -X $PanelX -Y $PanelY -Width $PanelWidth
                    }
                    "remove" {
                        Remove-FromTracker -State $state
                    }
                    "detail" {
                        $state.Mode = "detail"
                    }
                    "open" {
                        if ($state.Repos.Count -gt 0) {
                            $repo = $state.Repos[$state.SelectedIdx]
                            Start-Process $repo.html_url
                        }
                    }
                }
            }
            "add" {
                $result = Show-AddRepoForm -State $state -X $PanelX -Y $PanelY -Width $PanelWidth -Height $PanelHeight
                if ($result -eq "back" -or $result -eq "added") {
                    # Reload repos
                    $tracked = Get-TrackedRepos
                    $state.Repos = $tracked.Repos
                    $state.Mode = "list"
                }
            }
            "detail" {
                $result = Show-TrackedRepoDetail -Repo $state.Repos[$state.SelectedIdx] -X $PanelX -Y $PanelY -Width $PanelWidth -Height $PanelHeight
                if ($result -eq "back") {
                    $state.Mode = "list"
                }
            }
        }
    }
}

function Clear-TrackerPanel {
    param([int]$X, [int]$Y, [int]$Width, [int]$Height)

    for ($i = 0; $i -lt $Height; $i++) {
        Set-CursorPosition -X $X -Y ($Y + $i)
        Write-Host (' ' * $Width) -NoNewline
    }
}

function Show-TrackerList {
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
    $listHeight = $Height - 7

    # Header
    $repoCount = $State.Repos.Count
    Write-At -X $innerX -Y $innerY -Text "Tracked Repositories: $($c.Yellow)$repoCount$($c.Reset)"

    if ($State.LastChecked) {
        $lastCheck = [DateTime]::Parse($State.LastChecked).ToString("yyyy-MM-dd HH:mm")
        Write-At -X ($X + $Width - 25) -Y $innerY -Text "Last: $($c.Dim)$lastCheck$($c.Reset)"
    }

    # Show message if any
    if ($State.Message) {
        Write-At -X $innerX -Y ($innerY + 1) -Text $State.Message -Color $c.BrightYellow
        $State.Message = ""
    }

    # Empty state
    if ($repoCount -eq 0) {
        Write-At -X $innerX -Y ($innerY + 4) -Text "No repositories tracked yet." -Color $c.Dim
        Write-At -X $innerX -Y ($innerY + 6) -Text "Press [A] to add a repository" -Color $c.Cyan
        Write-At -X $innerX -Y ($innerY + 7) -Text "Or use Search tool to find and track repos" -Color $c.Dim

        Write-At -X $innerX -Y ($Y + $Height - 3) -Text "[A] Add  [Esc] Back" -Color $c.Dim

        $key = Get-KeyPress -Wait
        if ($key.Key -eq "Escape") { return @{ Action = "back" } }
        if ($key.Char.ToString().ToLower() -eq 'a') { return @{ Action = "add" } }
        return @{ Action = "continue" }
    }

    # Column headers
    $headerY = $innerY + 2
    Write-At -X $innerX -Y $headerY -Text "Repository" -Color $c.Dim
    Write-At -X ($X + $Width - 35) -Y $headerY -Text "Stars" -Color $c.Dim
    Write-At -X ($X + $Width - 25) -Y $headerY -Text "Delta" -Color $c.Dim
    Write-At -X ($X + $Width - 15) -Y $headerY -Text "Updated" -Color $c.Dim

    # Repository list
    $visibleItems = [Math]::Min($repoCount, $listHeight - 3)
    $scrollOffset = 0

    if ($State.SelectedIdx -ge $visibleItems) {
        $scrollOffset = $State.SelectedIdx - $visibleItems + 1
    }

    for ($i = 0; $i -lt $visibleItems; $i++) {
        $repoIdx = $scrollOffset + $i
        if ($repoIdx -ge $repoCount) { break }

        $repo = $State.Repos[$repoIdx]
        $itemY = $headerY + 1 + $i

        # Format display values
        $displayName = $repo.full_name
        $maxNameLen = $Width - 45
        if ($displayName.Length -gt $maxNameLen) {
            $displayName = $displayName.Substring(0, $maxNameLen - 3) + "..."
        }

        $stars = Format-Number -Number $repo.stargazers_count
        $delta = ""
        $deltaColor = $c.Dim

        if ($repo.delta) {
            if ($repo.delta.stars -gt 0) {
                $delta = "+$($repo.delta.stars)"
                $deltaColor = $c.BrightGreen
            } elseif ($repo.delta.stars -lt 0) {
                $delta = "$($repo.delta.stars)"
                $deltaColor = $c.Red
            } else {
                $delta = "="
            }
        }

        $updated = ""
        if ($repo.pushed_at) {
            $updated = $repo.pushed_at.Substring(0, 10)
        }

        # Draw row
        if ($repoIdx -eq $State.SelectedIdx) {
            Write-At -X $innerX -Y $itemY -Text "$($c.BgYellow)$($c.Black) > $($displayName.PadRight($maxNameLen)) $($c.Reset)"
            Write-At -X ($X + $Width - 35) -Y $itemY -Text "$($c.BgYellow)$($c.Black)$($stars.PadLeft(6))$($c.Reset)"
            Write-At -X ($X + $Width - 25) -Y $itemY -Text "$($c.BgYellow)$($c.Black)$($delta.PadLeft(6))$($c.Reset)"
            Write-At -X ($X + $Width - 15) -Y $itemY -Text "$($c.BgYellow)$($c.Black)$updated$($c.Reset)"
        } else {
            Write-At -X $innerX -Y $itemY -Text "   $displayName"
            Write-At -X ($X + $Width - 35) -Y $itemY -Text "$($c.Yellow)$($stars.PadLeft(6))$($c.Reset)"
            Write-At -X ($X + $Width - 25) -Y $itemY -Text "$deltaColor$($delta.PadLeft(6))$($c.Reset)"
            Write-At -X ($X + $Width - 15) -Y $itemY -Text "$($c.Dim)$updated$($c.Reset)"
        }
    }

    # Scroll indicator
    if ($repoCount -gt $visibleItems) {
        $scrollPercent = [Math]::Floor(($scrollOffset / ($repoCount - $visibleItems)) * 100)
        Write-At -X ($X + $Width - 8) -Y ($Y + $Height - 4) -Text "$($c.Dim)[$scrollPercent%]$($c.Reset)"
    }

    # Controls
    Write-At -X $innerX -Y ($Y + $Height - 3) -Text "[Enter] Details  [R] Refresh  [A] Add  [D] Remove  [O] Open  [Esc] Back" -Color $c.Dim

    # Handle input
    $key = Get-KeyPress -Wait

    switch ($key.Key) {
        "UpArrow" {
            if ($State.SelectedIdx -gt 0) { $State.SelectedIdx-- }
            return @{ Action = "continue" }
        }
        "DownArrow" {
            if ($State.SelectedIdx -lt $repoCount - 1) { $State.SelectedIdx++ }
            return @{ Action = "continue" }
        }
        "Enter" {
            return @{ Action = "detail" }
        }
        "Escape" {
            return @{ Action = "back" }
        }
    }

    switch ($key.Char.ToString().ToLower()) {
        'a' { return @{ Action = "add" } }
        'r' { return @{ Action = "refresh" } }
        'd' { return @{ Action = "remove" } }
        'o' { return @{ Action = "open" } }
    }

    return @{ Action = "continue" }
}

function Show-AddRepoForm {
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

    Write-At -X $innerX -Y $innerY -Text "Add Repository to Tracker" -Color $c.Cyan
    Write-At -X $innerX -Y ($innerY + 2) -Text "Enter repository (owner/repo):" -Color $c.White
    Write-At -X $innerX -Y ($innerY + 3) -Text "  $($c.Dim)Example: microsoft/vscode$($c.Reset)"

    Write-At -X $innerX -Y ($Y + $Height - 3) -Text "[Enter] Add  [Esc] Cancel" -Color $c.Dim

    Show-Cursor
    Set-CursorPosition -X $innerX -Y ($innerY + 5)
    Write-Host "> " -ForegroundColor Yellow -NoNewline
    $repoInput = Read-Host
    Hide-Cursor

    if (-not $repoInput) {
        return "back"
    }

    # Validate format
    if ($repoInput -notmatch '^[^/]+/[^/]+$') {
        Write-At -X $innerX -Y ($innerY + 7) -Text "Invalid format. Use: owner/repo" -Color $c.Red
        Start-Sleep -Seconds 2
        return "continue"
    }

    # Fetch repo info
    Write-At -X $innerX -Y ($innerY + 7) -Text "Fetching repository info..." -Color $c.Yellow

    $result = Get-RepoByFullName -FullName $repoInput

    if (-not $result.Success) {
        Write-At -X $innerX -Y ($innerY + 7) -Text "Error: $($result.Error)           " -Color $c.Red
        Start-Sleep -Seconds 2
        return "continue"
    }

    # Add to tracker
    $repoHash = @{}
    foreach ($prop in $result.Repo.PSObject.Properties) {
        $repoHash[$prop.Name] = $prop.Value
    }

    $addResult = Add-TrackedRepo -Repo $repoHash

    if ($addResult.Success) {
        Write-At -X $innerX -Y ($innerY + 7) -Text "$($c.BrightGreen)Added: $repoInput$($c.Reset)           "
        $State.Message = "Added $repoInput to tracker"
    } else {
        Write-At -X $innerX -Y ($innerY + 7) -Text "$($c.Red)$($addResult.Error)$($c.Reset)           "
    }

    Start-Sleep -Seconds 1
    return "added"
}

function Refresh-AllTracked {
    param(
        [hashtable]$State,
        [int]$X,
        [int]$Y,
        [int]$Width
    )

    $c = $Global:Colors
    $innerX = $X + 2
    $innerY = $Y + 4

    if ($State.Repos.Count -eq 0) {
        $State.Message = "No repos to refresh"
        return
    }

    Write-At -X $innerX -Y $innerY -Text "Refreshing tracked repositories..." -Color $c.Yellow

    $updated = 0
    $errors = 0

    for ($i = 0; $i -lt $State.Repos.Count; $i++) {
        $repo = $State.Repos[$i]
        $progress = [Math]::Floor((($i + 1) / $State.Repos.Count) * 100)

        Write-At -X $innerX -Y ($innerY + 1) -Text "[$progress%] $($repo.full_name)                    " -Color $c.Dim

        $result = Get-RepoByFullName -FullName $repo.full_name

        if ($result.Success) {
            $repoHash = @{}
            foreach ($prop in $result.Repo.PSObject.Properties) {
                $repoHash[$prop.Name] = $prop.Value
            }

            Update-TrackedRepo -FullName $repo.full_name -NewData $repoHash
            $updated++
        } else {
            $errors++
        }

        Start-Sleep -Milliseconds 200  # Be nice to API
    }

    # Reload
    $tracked = Get-TrackedRepos
    $State.Repos = $tracked.Repos
    $State.LastChecked = $tracked.LastChecked

    $State.Message = "Refreshed $updated repos" + $(if ($errors -gt 0) { ", $errors errors" } else { "" })
}

function Remove-FromTracker {
    param([hashtable]$State)

    if ($State.Repos.Count -eq 0) { return }

    $repo = $State.Repos[$State.SelectedIdx]
    $result = Remove-TrackedRepo -FullName $repo.full_name

    if ($result.Success) {
        # Reload
        $tracked = Get-TrackedRepos
        $State.Repos = $tracked.Repos

        # Adjust selection
        if ($State.SelectedIdx -ge $State.Repos.Count -and $State.SelectedIdx -gt 0) {
            $State.SelectedIdx--
        }

        $State.Message = "Removed $($repo.full_name)"
    } else {
        $State.Message = "Error: $($result.Error)"
    }
}

function Show-TrackedRepoDetail {
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

    # Header
    Write-At -X $innerX -Y $innerY -Text "$($c.BrightYellow)$($Repo.full_name)$($c.Reset)"
    Write-At -X $innerX -Y ($innerY + 1) -Text "$($c.Dim)$($Repo.html_url)$($c.Reset)"

    # Description
    if ($Repo.description) {
        $desc = $Repo.description
        if ($desc.Length -gt $Width - 6) {
            $desc = $desc.Substring(0, $Width - 9) + "..."
        }
        Write-At -X $innerX -Y ($innerY + 3) -Text $desc -Color $c.White
    }

    # Current stats
    $statsY = $innerY + 5
    Write-At -X $innerX -Y $statsY -Text "Current Statistics:" -Color $c.Cyan

    Write-At -X $innerX -Y ($statsY + 1) -Text "Stars: $($c.Yellow)$(Format-Number -Number $Repo.stargazers_count)$($c.Reset)"
    Write-At -X ($innerX + 20) -Y ($statsY + 1) -Text "Forks: $($c.Cyan)$(Format-Number -Number $Repo.forks_count)$($c.Reset)"
    Write-At -X ($innerX + 40) -Y ($statsY + 1) -Text "Issues: $($c.Red)$($Repo.open_issues_count)$($c.Reset)"

    # Changes since tracking
    if ($Repo.delta) {
        $deltaY = $statsY + 3
        Write-At -X $innerX -Y $deltaY -Text "Changes since last check:" -Color $c.Cyan

        $starDelta = $Repo.delta.stars
        $starColor = if ($starDelta -gt 0) { $c.BrightGreen } elseif ($starDelta -lt 0) { $c.Red } else { $c.Dim }
        $starSign = if ($starDelta -gt 0) { "+" } else { "" }

        Write-At -X $innerX -Y ($deltaY + 1) -Text "Stars: $starColor$starSign$starDelta$($c.Reset)"

        $issueDelta = $Repo.delta.issues
        $issueColor = if ($issueDelta -gt 0) { $c.Red } elseif ($issueDelta -lt 0) { $c.Green } else { $c.Dim }
        $issueSign = if ($issueDelta -gt 0) { "+" } else { "" }

        Write-At -X ($innerX + 20) -Y ($deltaY + 1) -Text "Issues: $issueColor$issueSign$issueDelta$($c.Reset)"
    }

    # Tracking info
    $trackY = $statsY + 6
    Write-At -X $innerX -Y $trackY -Text "Tracking Info:" -Color $c.Cyan

    if ($Repo.tracked_at) {
        $trackedDate = [DateTime]::Parse($Repo.tracked_at).ToString("yyyy-MM-dd HH:mm")
        Write-At -X $innerX -Y ($trackY + 1) -Text "Tracked since: $($c.Dim)$trackedDate$($c.Reset)"
    }

    if ($Repo.last_checked) {
        $checkedDate = [DateTime]::Parse($Repo.last_checked).ToString("yyyy-MM-dd HH:mm")
        Write-At -X $innerX -Y ($trackY + 2) -Text "Last checked: $($c.Dim)$checkedDate$($c.Reset)"
    }

    if ($Repo.pushed_at) {
        $pushDate = $Repo.pushed_at.Substring(0, 10)
        Write-At -X $innerX -Y ($trackY + 3) -Text "Last push: $($c.Dim)$pushDate$($c.Reset)"
    }

    # Controls
    Write-At -X $innerX -Y ($Y + $Height - 3) -Text "[O] Open in Browser  [Esc] Back" -Color $c.Dim

    # Handle input
    $key = Get-KeyPress -Wait

    if ($key.Char.ToString().ToLower() -eq 'o') {
        Start-Process $Repo.html_url
        return "continue"
    }

    if ($key.Key -eq "Escape") {
        return "back"
    }

    return "continue"
}

# Export functions
# Functions available after dot-sourcing
