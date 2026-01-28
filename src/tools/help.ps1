# help.ps1 - Help Documentation Tool for Kindware.dev GitHubScout
# Provides help content, keybindings reference, and setup instructions

function Show-HelpTool {
    <#
    .SYNOPSIS
    Main entry point for the help tool
    #>
    param(
        [int]$PanelX,
        [int]$PanelY,
        [int]$PanelWidth,
        [int]$PanelHeight
    )

    $c = $Global:Colors
    $state = @{
        Tab = 0  # 0=overview, 1=keybindings, 2=setup, 3=about
    }

    $tabs = @("Overview", "Keybindings", "Setup", "About")

    while ($true) {
        # Clear panel area
        Clear-HelpPanel -X $PanelX -Y $PanelY -Width $PanelWidth -Height $PanelHeight

        # Draw panel frame
        Draw-Box -X $PanelX -Y $PanelY -Width $PanelWidth -Height $PanelHeight -Color $c.Cyan -Title "Help & Documentation"

        # Draw tabs
        $tabX = $PanelX + 2
        $tabY = $PanelY + 2

        for ($i = 0; $i -lt $tabs.Count; $i++) {
            if ($i -eq $state.Tab) {
                Write-At -X $tabX -Y $tabY -Text "$($c.BgCyan)$($c.Black) $($tabs[$i]) $($c.Reset)"
            } else {
                Write-At -X $tabX -Y $tabY -Text "$($c.Dim) $($tabs[$i]) $($c.Reset)"
            }
            $tabX += $tabs[$i].Length + 4
        }

        # Draw content based on selected tab
        $contentY = $tabY + 2

        switch ($state.Tab) {
            0 { Show-OverviewTab -X $PanelX -Y $contentY -Width $PanelWidth -Height ($PanelHeight - 6) }
            1 { Show-KeybindingsTab -X $PanelX -Y $contentY -Width $PanelWidth -Height ($PanelHeight - 6) }
            2 { Show-SetupTab -X $PanelX -Y $contentY -Width $PanelWidth -Height ($PanelHeight - 6) }
            3 { Show-AboutTab -X $PanelX -Y $contentY -Width $PanelWidth -Height ($PanelHeight - 6) }
        }

        # Controls
        Write-At -X ($PanelX + 2) -Y ($PanelY + $PanelHeight - 3) -Text "[Left/Right] Switch Tab  [Esc] Back" -Color $c.Dim

        # Handle input
        $key = Get-KeyPress -Wait

        switch ($key.Key) {
            "LeftArrow" {
                if ($state.Tab -gt 0) { $state.Tab-- }
            }
            "RightArrow" {
                if ($state.Tab -lt $tabs.Count - 1) { $state.Tab++ }
            }
            "Escape" {
                return "back"
            }
        }

        # Number keys for tab selection
        if ($key.Char -ge '1' -and $key.Char -le '4') {
            $state.Tab = [int]::Parse($key.Char.ToString()) - 1
        }
    }
}

function Clear-HelpPanel {
    param([int]$X, [int]$Y, [int]$Width, [int]$Height)

    for ($i = 0; $i -lt $Height; $i++) {
        Set-CursorPosition -X $X -Y ($Y + $i)
        Write-Host (' ' * $Width) -NoNewline
    }
}

function Show-OverviewTab {
    param([int]$X, [int]$Y, [int]$Width, [int]$Height)

    $c = $Global:Colors
    $innerX = $X + 2

    $content = @(
        @{ Type = "header"; Text = "Welcome to Kindware.dev GitHubScout!" }
        @{ Type = "text"; Text = "" }
        @{ Type = "text"; Text = "A fast, lightweight TUI for exploring GitHub repositories." }
        @{ Type = "text"; Text = "" }
        @{ Type = "header"; Text = "Features" }
        @{ Type = "bullet"; Text = "Search - Find GitHub repos by keyword, language, and stars" }
        @{ Type = "bullet"; Text = "Tracker - Watch repositories and track changes over time" }
        @{ Type = "bullet"; Text = "Inspector - Deep dive into any repository's details" }
        @{ Type = "bullet"; Text = "Export - Save results as JSON or Markdown" }
        @{ Type = "text"; Text = "" }
        @{ Type = "header"; Text = "Quick Start" }
        @{ Type = "text"; Text = "1. Press [1] to open the Search tool" }
        @{ Type = "text"; Text = "2. Enter a search query (e.g., 'cli tools')" }
        @{ Type = "text"; Text = "3. Browse results with arrow keys" }
        @{ Type = "text"; Text = "4. Press [T] to track interesting repos" }
        @{ Type = "text"; Text = "5. Press [2] to view your tracked repos" }
        @{ Type = "text"; Text = "" }
        @{ Type = "tip"; Text = "Tip: Add a GitHub token for higher API rate limits!" }
    )

    $lineY = $Y
    foreach ($line in $content) {
        switch ($line.Type) {
            "header" {
                Write-At -X $innerX -Y $lineY -Text $line.Text -Color $c.BrightCyan
            }
            "text" {
                Write-At -X $innerX -Y $lineY -Text $line.Text -Color $c.White
            }
            "bullet" {
                Write-At -X $innerX -Y $lineY -Text "$($c.Green)$([char]0x2022)$($c.Reset) $($line.Text)"
            }
            "tip" {
                Write-At -X $innerX -Y $lineY -Text "$($c.BrightYellow)$([char]0x1F4A1) $($line.Text)$($c.Reset)"
            }
        }
        $lineY++
    }
}

function Show-KeybindingsTab {
    param([int]$X, [int]$Y, [int]$Width, [int]$Height)

    $c = $Global:Colors
    $innerX = $X + 2

    $bindings = @(
        @{ Section = "Global" }
        @{ Key = "1-4"; Action = "Switch to tool (Search/Tracker/Inspector/Help)" }
        @{ Key = "Q"; Action = "Quit application" }
        @{ Key = "Esc"; Action = "Go back / Cancel" }
        @{ Key = "R"; Action = "Refresh current view" }
        @{ Key = "E"; Action = "Export results" }

        @{ Section = "Navigation" }
        @{ Key = "Up/Down"; Action = "Move selection" }
        @{ Key = "PgUp/PgDn"; Action = "Page through lists" }
        @{ Key = "Home/End"; Action = "Jump to start/end" }
        @{ Key = "Enter"; Action = "Select / Confirm" }

        @{ Section = "Search Tool" }
        @{ Key = "Enter"; Action = "Execute search" }
        @{ Key = "T"; Action = "Track selected repo" }
        @{ Key = "O"; Action = "Open in browser" }

        @{ Section = "Tracker Tool" }
        @{ Key = "A"; Action = "Add new repo to track" }
        @{ Key = "D"; Action = "Remove selected repo" }
        @{ Key = "R"; Action = "Refresh all tracked repos" }

        @{ Section = "Inspector Tool" }
        @{ Key = "R"; Action = "View README" }
        @{ Key = "T"; Action = "Add to tracker" }
        @{ Key = "E"; Action = "Export report" }
    )

    $lineY = $Y
    foreach ($item in $bindings) {
        if ($item.Section) {
            if ($lineY -gt $Y) { $lineY++ }
            Write-At -X $innerX -Y $lineY -Text $item.Section -Color $c.BrightCyan
            $lineY++
        } else {
            $keyDisplay = "[$($item.Key)]".PadRight(14)
            Write-At -X $innerX -Y $lineY -Text "$($c.Yellow)$keyDisplay$($c.Reset)$($item.Action)"
            $lineY++
        }
    }
}

function Show-SetupTab {
    param([int]$X, [int]$Y, [int]$Width, [int]$Height)

    $c = $Global:Colors
    $innerX = $X + 2

    $content = @(
        @{ Type = "header"; Text = "Requirements" }
        @{ Type = "bullet"; Text = "PowerShell 7.0 or later (pwsh.exe)" }
        @{ Type = "bullet"; Text = "Windows Terminal recommended" }
        @{ Type = "bullet"; Text = "Internet connection for GitHub API" }
        @{ Type = "text"; Text = "" }

        @{ Type = "header"; Text = "GitHub Token (Optional but Recommended)" }
        @{ Type = "text"; Text = "Without a token: 60 API requests/hour" }
        @{ Type = "text"; Text = "With a token: 5,000 API requests/hour" }
        @{ Type = "text"; Text = "" }
        @{ Type = "text"; Text = "To add a token:" }
        @{ Type = "text"; Text = "1. Go to github.com/settings/tokens" }
        @{ Type = "text"; Text = "2. Generate a new token (classic)" }
        @{ Type = "text"; Text = "3. Select 'public_repo' scope only" }
        @{ Type = "text"; Text = "4. Edit config.json and add your token:" }
        @{ Type = "code"; Text = '   { "GitHubToken": "ghp_your_token_here" }' }
        @{ Type = "text"; Text = "" }

        @{ Type = "header"; Text = "Data Files" }
        @{ Type = "bullet"; Text = "config.json - Your settings and token" }
        @{ Type = "bullet"; Text = "tracked.json - Your watched repositories" }
        @{ Type = "bullet"; Text = "search-results.json - Last search results" }
        @{ Type = "bullet"; Text = "reports/ - Exported markdown reports" }
    )

    $lineY = $Y
    foreach ($line in $content) {
        switch ($line.Type) {
            "header" {
                Write-At -X $innerX -Y $lineY -Text $line.Text -Color $c.BrightCyan
            }
            "text" {
                Write-At -X $innerX -Y $lineY -Text $line.Text -Color $c.White
            }
            "bullet" {
                Write-At -X $innerX -Y $lineY -Text "$($c.Green)$([char]0x2022)$($c.Reset) $($line.Text)"
            }
            "code" {
                Write-At -X $innerX -Y $lineY -Text "$($c.BgBlack)$($c.BrightGreen)$($line.Text)$($c.Reset)"
            }
        }
        $lineY++
    }
}

function Show-AboutTab {
    param([int]$X, [int]$Y, [int]$Width, [int]$Height)

    $c = $Global:Colors
    $innerX = $X + 2
    $centerX = $X + [Math]::Floor($Width / 2) - 20

    # ASCII Art Frog
    $frog = @(
        "    .--.  .--.    "
        "   / .. \/ .. \   "
        "  ( \  ''  / )    "
        "   |`--'`--'|     "
        "   /        \     "
        "  |   ____   |    "
        "   \        /     "
        "    `------'      "
    )

    $lineY = $Y
    foreach ($line in $frog) {
        Write-At -X $centerX -Y $lineY -Text $line -Color $c.BrightGreen
        $lineY++
    }

    $lineY++
    Write-Centered -Y $lineY -Text "$($c.BrightGreen)Kindware.dev GitHubScout$($c.Reset)" -Width $Width
    $lineY++
    Write-Centered -Y $lineY -Text "$($c.Dim)Version 1.0.0$($c.Reset)" -Width $Width
    $lineY += 2

    Write-Centered -Y $lineY -Text "Powered by $($c.BrightMagenta)Kindware.dev$($c.Reset)" -Width $Width
    $lineY += 2

    $info = @(
        ""
        "A fast, lightweight GitHub explorer for Windows Terminal"
        "Built with PowerShell 7+ and love for the command line"
        ""
        "License: MIT"
        ""
        "GitHub: github.com/kindware/lazyfrog-githubscout"
    )

    foreach ($line in $info) {
        Write-At -X $innerX -Y $lineY -Text $line -Color $c.Dim
        $lineY++
    }

    $lineY++
    Write-At -X $innerX -Y $lineY -Text "Made with $($c.Red)$([char]0x2665)$($c.Reset) for developers who live in the terminal" -Color $c.Dim
}

function Write-Centered {
    param(
        [int]$Y,
        [string]$Text,
        [int]$Width
    )

    # Strip ANSI codes for length calculation
    $plainText = $Text -replace '\e\[[0-9;]*m', ''
    $x = [Math]::Max(0, [Math]::Floor(($Width - $plainText.Length) / 2))

    Set-CursorPosition -X $x -Y $Y
    Write-Host $Text -NoNewline
}

# Export functions
# Functions available after dot-sourcing
