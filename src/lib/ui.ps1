# ui.ps1 - TUI Rendering Module for Kindware.dev GitHubScout
# Provides console rendering functions, colors, and UI components

# ============================================================================
# ANSI Color Constants
# ============================================================================
$Global:Colors = @{
    Reset       = "`e[0m"
    Bold        = "`e[1m"
    Dim         = "`e[2m"
    Italic      = "`e[3m"
    Underline   = "`e[4m"

    # Foreground
    Black       = "`e[30m"
    Red         = "`e[31m"
    Green       = "`e[32m"
    Yellow      = "`e[33m"
    Blue        = "`e[34m"
    Magenta     = "`e[35m"
    Cyan        = "`e[36m"
    White       = "`e[37m"

    # Bright Foreground
    BrightBlack   = "`e[90m"
    BrightRed     = "`e[91m"
    BrightGreen   = "`e[92m"
    BrightYellow  = "`e[93m"
    BrightBlue    = "`e[94m"
    BrightMagenta = "`e[95m"
    BrightCyan    = "`e[96m"
    BrightWhite   = "`e[97m"

    # Background
    BgBlack     = "`e[40m"
    BgRed       = "`e[41m"
    BgGreen     = "`e[42m"
    BgYellow    = "`e[43m"
    BgBlue      = "`e[44m"
    BgMagenta   = "`e[45m"
    BgCyan      = "`e[46m"
    BgWhite     = "`e[47m"
}

# ============================================================================
# Box Drawing Characters (Unicode)
# ============================================================================
$Global:BoxChars = @{
    # Single line
    TopLeft     = [char]0x250C  # ┌
    TopRight    = [char]0x2510  # ┐
    BottomLeft  = [char]0x2514  # └
    BottomRight = [char]0x2518  # ┘
    Horizontal  = [char]0x2500  # ─
    Vertical    = [char]0x2502  # │
    TeeRight    = [char]0x251C  # ├
    TeeLeft     = [char]0x2524  # ┤
    TeeDown     = [char]0x252C  # ┬
    TeeUp       = [char]0x2534  # ┴
    Cross       = [char]0x253C  # ┼

    # Double line
    DTopLeft     = [char]0x2554  # ╔
    DTopRight    = [char]0x2557  # ╗
    DBottomLeft  = [char]0x255A  # ╚
    DBottomRight = [char]0x255D  # ╝
    DHorizontal  = [char]0x2550  # ═
    DVertical    = [char]0x2551  # ║
}

# ============================================================================
# Console Functions
# ============================================================================

function Clear-Screen {
    <#
    .SYNOPSIS
    Clears the console screen
    #>
    [Console]::Clear()
    [Console]::SetCursorPosition(0, 0)
}

function Set-CursorPosition {
    <#
    .SYNOPSIS
    Sets the cursor position in the console
    #>
    param(
        [int]$X = 0,
        [int]$Y = 0
    )
    [Console]::SetCursorPosition($X, $Y)
}

function Hide-Cursor {
    Write-Host "`e[?25l" -NoNewline
}

function Show-Cursor {
    Write-Host "`e[?25h" -NoNewline
}

function Get-ConsoleSize {
    <#
    .SYNOPSIS
    Returns the current console width and height
    #>
    return @{
        Width  = [Console]::WindowWidth
        Height = [Console]::WindowHeight
    }
}

# ============================================================================
# Drawing Functions
# ============================================================================

function Draw-HorizontalLine {
    <#
    .SYNOPSIS
    Draws a horizontal line at the specified position
    #>
    param(
        [int]$X,
        [int]$Y,
        [int]$Length,
        [string]$Color = $Global:Colors.White,
        [switch]$Double
    )

    Set-CursorPosition -X $X -Y $Y
    $char = if ($Double) { $Global:BoxChars.DHorizontal } else { $Global:BoxChars.Horizontal }
    Write-Host "$Color$($char * $Length)$($Global:Colors.Reset)" -NoNewline
}

function Draw-VerticalLine {
    <#
    .SYNOPSIS
    Draws a vertical line at the specified position
    #>
    param(
        [int]$X,
        [int]$Y,
        [int]$Length,
        [string]$Color = $Global:Colors.White,
        [switch]$Double
    )

    $char = if ($Double) { $Global:BoxChars.DVertical } else { $Global:BoxChars.Vertical }
    for ($i = 0; $i -lt $Length; $i++) {
        Set-CursorPosition -X $X -Y ($Y + $i)
        Write-Host "$Color$char$($Global:Colors.Reset)" -NoNewline
    }
}

function Draw-Box {
    <#
    .SYNOPSIS
    Draws a box at the specified position with given dimensions
    #>
    param(
        [int]$X,
        [int]$Y,
        [int]$Width,
        [int]$Height,
        [string]$Color = $Global:Colors.White,
        [string]$Title = "",
        [switch]$Double
    )

    $bc = $Global:BoxChars

    if ($Double) {
        $tl = $bc.DTopLeft
        $tr = $bc.DTopRight
        $bl = $bc.DBottomLeft
        $br = $bc.DBottomRight
        $h = $bc.DHorizontal
        $v = $bc.DVertical
    } else {
        $tl = $bc.TopLeft
        $tr = $bc.TopRight
        $bl = $bc.BottomLeft
        $br = $bc.BottomRight
        $h = $bc.Horizontal
        $v = $bc.Vertical
    }

    # Top border
    Set-CursorPosition -X $X -Y $Y
    if ($Title) {
        $titleDisplay = " $Title "
        $leftPad = [Math]::Floor(($Width - 2 - $titleDisplay.Length) / 2)
        $rightPad = $Width - 2 - $leftPad - $titleDisplay.Length
        Write-Host "$Color$tl$($h * $leftPad)$($Global:Colors.BrightCyan)$titleDisplay$Color$($h * $rightPad)$tr$($Global:Colors.Reset)" -NoNewline
    } else {
        Write-Host "$Color$tl$($h * ($Width - 2))$tr$($Global:Colors.Reset)" -NoNewline
    }

    # Sides
    for ($i = 1; $i -lt ($Height - 1); $i++) {
        Set-CursorPosition -X $X -Y ($Y + $i)
        Write-Host "$Color$v$($Global:Colors.Reset)" -NoNewline
        Set-CursorPosition -X ($X + $Width - 1) -Y ($Y + $i)
        Write-Host "$Color$v$($Global:Colors.Reset)" -NoNewline
    }

    # Bottom border
    Set-CursorPosition -X $X -Y ($Y + $Height - 1)
    Write-Host "$Color$bl$($h * ($Width - 2))$br$($Global:Colors.Reset)" -NoNewline
}

function Draw-Panel {
    <#
    .SYNOPSIS
    Draws a panel with title and content
    #>
    param(
        [int]$X,
        [int]$Y,
        [int]$Width,
        [int]$Height,
        [string]$Title = "",
        [string[]]$Content = @(),
        [string]$BorderColor = $Global:Colors.White,
        [string]$ContentColor = $Global:Colors.White,
        [switch]$Double
    )

    # Draw the box
    Draw-Box -X $X -Y $Y -Width $Width -Height $Height -Color $BorderColor -Title $Title -Double:$Double

    # Draw content
    $contentWidth = $Width - 4
    $contentHeight = $Height - 2

    for ($i = 0; $i -lt [Math]::Min($Content.Count, $contentHeight); $i++) {
        Set-CursorPosition -X ($X + 2) -Y ($Y + 1 + $i)
        $line = $Content[$i]
        if ($line.Length -gt $contentWidth) {
            $line = $line.Substring(0, $contentWidth - 3) + "..."
        }
        Write-Host "$ContentColor$line$($Global:Colors.Reset)" -NoNewline
    }
}

function Write-At {
    <#
    .SYNOPSIS
    Writes text at a specific position with optional color
    #>
    param(
        [int]$X,
        [int]$Y,
        [string]$Text,
        [string]$Color = $Global:Colors.White
    )

    Set-CursorPosition -X $X -Y $Y
    Write-Host "$Color$Text$($Global:Colors.Reset)" -NoNewline
}

function Write-Centered {
    <#
    .SYNOPSIS
    Writes centered text at a specific Y position
    #>
    param(
        [int]$Y,
        [string]$Text,
        [string]$Color = $Global:Colors.White,
        [int]$Width = 0
    )

    if ($Width -eq 0) {
        $Width = [Console]::WindowWidth
    }

    # Strip ANSI codes for length calculation
    $plainText = $Text -replace '\e\[[0-9;]*m', ''
    $x = [Math]::Max(0, [Math]::Floor(($Width - $plainText.Length) / 2))

    Set-CursorPosition -X $x -Y $Y
    Write-Host "$Color$Text$($Global:Colors.Reset)" -NoNewline
}

# ============================================================================
# Banner and Branding
# ============================================================================

function Show-Banner {
    <#
    .SYNOPSIS
    Displays the Kindware.dev GitHubScout banner
    #>
    param(
        [int]$Y = 0
    )

    $c = $Global:Colors
    $width = [Console]::WindowWidth

    $banner = @"
$($c.BrightGreen)  _                     _____
 | |    __ _ _____   _|  ___| __ ___   __ _
 | |   / _` |_  / | | | |_ | '__/ _ \ / _` |
 | |__| (_| |/ /| |_| |  _|| | | (_) | (_| |
 |_____\__,_/___|\__, |_|  |_|  \___/ \__, |
                 |___/                |___/   $($c.Reset)
"@

    $lines = $banner -split "`n"
    for ($i = 0; $i -lt $lines.Count; $i++) {
        Write-Centered -Y ($Y + $i) -Text $lines[$i]
    }

    $taglineY = $Y + $lines.Count
    Write-Centered -Y $taglineY -Text "$($c.BrightCyan)GitHubScout$($c.Reset) $($c.Dim)— powered by$($c.Reset) $($c.BrightMagenta)Kindware.dev$($c.Reset)"
}

function Show-Header {
    <#
    .SYNOPSIS
    Displays the compact header bar
    #>
    param(
        [int]$Width
    )

    $c = $Global:Colors
    $title = "  $($c.BrightGreen)Kindware.dev GitHubScout$($c.Reset) $($c.Dim)— powered by$($c.Reset) $($c.BrightMagenta)Kindware.dev$($c.Reset)  "

    Draw-Box -X 0 -Y 0 -Width $Width -Height 3 -Color $c.Green -Double
    Write-At -X 2 -Y 1 -Text $title
}

function Show-StatusBar {
    <#
    .SYNOPSIS
    Displays the status bar at the bottom
    #>
    param(
        [int]$Y,
        [int]$Width,
        [string]$Message = ""
    )

    $c = $Global:Colors

    Set-CursorPosition -X 0 -Y $Y
    Write-Host "$($c.BgBlue)$($c.White)$(' ' * $Width)$($c.Reset)" -NoNewline

    $controls = "[1-4] Tools  [Q] Quit  [R] Refresh  [E] Export"
    Write-At -X 2 -Y $Y -Text "$($c.BgBlue)$($c.BrightWhite)$controls$($c.Reset)"

    if ($Message) {
        $msgX = $Width - $Message.Length - 2
        Write-At -X $msgX -Y $Y -Text "$($c.BgBlue)$($c.BrightYellow)$Message$($c.Reset)"
    }
}

function Show-Menu {
    <#
    .SYNOPSIS
    Displays the tools menu panel
    #>
    param(
        [int]$X,
        [int]$Y,
        [int]$Width,
        [int]$Height,
        [int]$SelectedIndex = 0
    )

    $c = $Global:Colors

    Draw-Box -X $X -Y $Y -Width $Width -Height $Height -Color $c.Cyan -Title "TOOLS"

    $menuItems = @(
        @{ Key = "1"; Label = "Search"; Icon = [char]0x1F50D }
        @{ Key = "2"; Label = "Tracker"; Icon = [char]0x2B50 }
        @{ Key = "3"; Label = "Inspect"; Icon = [char]0x1F4CB }
        @{ Key = "4"; Label = "Help"; Icon = [char]0x2753 }
    )

    for ($i = 0; $i -lt $menuItems.Count; $i++) {
        $item = $menuItems[$i]
        $itemY = $Y + 2 + ($i * 2)

        if ($i -eq $SelectedIndex) {
            Write-At -X ($X + 2) -Y $itemY -Text "$($c.BgCyan)$($c.Black) [$($item.Key)] $($item.Label) $($c.Reset)"
        } else {
            Write-At -X ($X + 2) -Y $itemY -Text "$($c.Cyan)[$($item.Key)]$($c.Reset) $($c.White)$($item.Label)$($c.Reset)"
        }
    }
}

function Show-LoadingSpinner {
    <#
    .SYNOPSIS
    Shows a loading spinner animation
    #>
    param(
        [int]$X,
        [int]$Y,
        [string]$Message = "Loading..."
    )

    $spinChars = @('|', '/', '-', '\')
    $c = $Global:Colors

    for ($i = 0; $i -lt 4; $i++) {
        Set-CursorPosition -X $X -Y $Y
        Write-Host "$($c.BrightYellow)$($spinChars[$i % 4]) $Message$($c.Reset)" -NoNewline
        Start-Sleep -Milliseconds 100
    }
}

function Format-Number {
    <#
    .SYNOPSIS
    Formats large numbers with K/M suffix
    #>
    param(
        [int]$Number
    )

    if ($Number -ge 1000000) {
        return "{0:N1}M" -f ($Number / 1000000)
    } elseif ($Number -ge 1000) {
        return "{0:N1}K" -f ($Number / 1000)
    }
    return $Number.ToString()
}

function Show-ProgressBar {
    <#
    .SYNOPSIS
    Displays a progress bar
    #>
    param(
        [int]$X,
        [int]$Y,
        [int]$Width,
        [int]$Percent,
        [string]$Color = $Global:Colors.Green
    )

    $c = $Global:Colors
    $filled = [Math]::Floor(($Width - 2) * $Percent / 100)
    $empty = ($Width - 2) - $filled

    Set-CursorPosition -X $X -Y $Y
    Write-Host "[" -NoNewline
    Write-Host "$Color$([char]0x2588 * $filled)$($c.Dim)$([char]0x2591 * $empty)$($c.Reset)" -NoNewline
    Write-Host "] $Percent%" -NoNewline
}

# Export module members
# Functions available after dot-sourcing
