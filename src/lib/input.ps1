# input.ps1 - Keyboard Input Handler for Kindware.dev GitHubScout
# Provides non-blocking key detection and input handling

# ============================================================================
# Key Constants
# ============================================================================
$script:Keys = @{
    Enter     = 13
    Escape    = 27
    Space     = 32
    Backspace = 8
    Tab       = 9

    # Arrow keys (when reading extended keys)
    UpArrow    = 38
    DownArrow  = 40
    LeftArrow  = 37
    RightArrow = 39

    # Page navigation
    PageUp   = 33
    PageDown = 34
    Home     = 36
    End      = 35

    # Function keys
    F1  = 112
    F2  = 113
    F3  = 114
    F4  = 115
    F5  = 116
    F10 = 121
}

# ============================================================================
# Input Functions
# ============================================================================

function Get-KeyPress {
    <#
    .SYNOPSIS
    Gets a single key press without blocking (returns $null if no key available)
    Returns a hashtable with Key, Char, and Modifiers
    #>
    param(
        [switch]$Wait,
        [int]$TimeoutMs = 0
    )

    if (-not $Wait -and -not [Console]::KeyAvailable) {
        return $null
    }

    if ($TimeoutMs -gt 0 -and -not $Wait) {
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        while (-not [Console]::KeyAvailable -and $stopwatch.ElapsedMilliseconds -lt $TimeoutMs) {
            Start-Sleep -Milliseconds 10
        }
        $stopwatch.Stop()
        if (-not [Console]::KeyAvailable) {
            return $null
        }
    }

    $keyInfo = [Console]::ReadKey($true)

    return @{
        Key       = $keyInfo.Key.ToString()
        KeyCode   = [int]$keyInfo.Key
        Char      = $keyInfo.KeyChar
        Alt       = ($keyInfo.Modifiers -band [ConsoleModifiers]::Alt) -ne 0
        Ctrl      = ($keyInfo.Modifiers -band [ConsoleModifiers]::Control) -ne 0
        Shift     = ($keyInfo.Modifiers -band [ConsoleModifiers]::Shift) -ne 0
    }
}

function Wait-ForKey {
    <#
    .SYNOPSIS
    Waits for a specific key or any key
    #>
    param(
        [string[]]$ValidKeys = @(),
        [string]$Prompt = "Press any key to continue..."
    )

    if ($Prompt) {
        Write-Host $Prompt -NoNewline
    }

    while ($true) {
        $key = Get-KeyPress -Wait
        if ($ValidKeys.Count -eq 0 -or $key.Key -in $ValidKeys -or $key.Char -in $ValidKeys) {
            return $key
        }
    }
}

function Read-Input {
    <#
    .SYNOPSIS
    Reads a line of input with optional prompt and validation
    #>
    param(
        [string]$Prompt = "",
        [string]$Default = "",
        [scriptblock]$Validator = $null,
        [int]$MaxLength = 100
    )

    if ($Prompt) {
        Write-Host $Prompt -NoNewline
    }

    $input = ""
    $cursorPos = 0

    # Show default value hint
    if ($Default) {
        Write-Host " [$Default]" -ForegroundColor DarkGray -NoNewline
        Write-Host ": " -NoNewline
    } else {
        Write-Host ": " -NoNewline
    }

    $startX = [Console]::CursorLeft
    $startY = [Console]::CursorTop

    while ($true) {
        $key = Get-KeyPress -Wait

        switch ($key.KeyCode) {
            13 {  # Enter
                Write-Host ""
                if ([string]::IsNullOrEmpty($input) -and $Default) {
                    return $Default
                }
                if ($Validator) {
                    $result = & $Validator $input
                    if ($result -ne $true) {
                        Write-Host "  Invalid input: $result" -ForegroundColor Red
                        continue
                    }
                }
                return $input
            }
            27 {  # Escape
                Write-Host ""
                return $null
            }
            8 {  # Backspace
                if ($cursorPos -gt 0) {
                    $input = $input.Substring(0, $cursorPos - 1) + $input.Substring($cursorPos)
                    $cursorPos--
                    # Redraw
                    [Console]::SetCursorPosition($startX, $startY)
                    Write-Host "$input " -NoNewline
                    [Console]::SetCursorPosition($startX + $cursorPos, $startY)
                }
            }
            37 {  # Left Arrow
                if ($cursorPos -gt 0) {
                    $cursorPos--
                    [Console]::SetCursorPosition($startX + $cursorPos, $startY)
                }
            }
            39 {  # Right Arrow
                if ($cursorPos -lt $input.Length) {
                    $cursorPos++
                    [Console]::SetCursorPosition($startX + $cursorPos, $startY)
                }
            }
            36 {  # Home
                $cursorPos = 0
                [Console]::SetCursorPosition($startX, $startY)
            }
            35 {  # End
                $cursorPos = $input.Length
                [Console]::SetCursorPosition($startX + $cursorPos, $startY)
            }
            default {
                $char = $key.Char
                if ($char -ge 32 -and $char -le 126 -and $input.Length -lt $MaxLength) {
                    $input = $input.Substring(0, $cursorPos) + $char + $input.Substring($cursorPos)
                    $cursorPos++
                    # Redraw
                    [Console]::SetCursorPosition($startX, $startY)
                    Write-Host $input -NoNewline
                    [Console]::SetCursorPosition($startX + $cursorPos, $startY)
                }
            }
        }
    }
}

function Read-Choice {
    <#
    .SYNOPSIS
    Presents a list of choices and returns the selected index
    #>
    param(
        [string[]]$Choices,
        [string]$Prompt = "Select an option",
        [int]$Default = 0
    )

    Write-Host "$Prompt`n" -ForegroundColor Cyan

    for ($i = 0; $i -lt $Choices.Count; $i++) {
        $marker = if ($i -eq $Default) { ">" } else { " " }
        Write-Host "  $marker [$($i + 1)] $($Choices[$i])"
    }

    Write-Host ""
    $selected = Read-Input -Prompt "Enter choice (1-$($Choices.Count))" -Default ($Default + 1).ToString()

    if ($null -eq $selected) {
        return -1
    }

    $index = [int]$selected - 1
    if ($index -ge 0 -and $index -lt $Choices.Count) {
        return $index
    }

    return $Default
}

function Read-YesNo {
    <#
    .SYNOPSIS
    Prompts for a yes/no response
    #>
    param(
        [string]$Prompt,
        [bool]$Default = $true
    )

    $defaultStr = if ($Default) { "Y/n" } else { "y/N" }
    Write-Host "$Prompt [$defaultStr]: " -NoNewline

    while ($true) {
        $key = Get-KeyPress -Wait

        switch ($key.Char.ToString().ToLower()) {
            'y' {
                Write-Host "Yes"
                return $true
            }
            'n' {
                Write-Host "No"
                return $false
            }
            default {
                if ($key.KeyCode -eq 13) {  # Enter
                    Write-Host $(if ($Default) { "Yes" } else { "No" })
                    return $Default
                }
            }
        }
    }
}

function Show-ListSelector {
    <#
    .SYNOPSIS
    Shows an interactive list selector with arrow key navigation
    #>
    param(
        [object[]]$Items,
        [string]$DisplayProperty = $null,
        [int]$X = 0,
        [int]$Y = 0,
        [int]$Width = 40,
        [int]$Height = 10,
        [int]$SelectedIndex = 0
    )

    $scrollOffset = 0
    $visibleItems = $Height - 2
    $currentIndex = $SelectedIndex

    while ($true) {
        # Adjust scroll offset
        if ($currentIndex -lt $scrollOffset) {
            $scrollOffset = $currentIndex
        } elseif ($currentIndex -ge $scrollOffset + $visibleItems) {
            $scrollOffset = $currentIndex - $visibleItems + 1
        }

        # Draw list
        for ($i = 0; $i -lt $visibleItems; $i++) {
            $itemIndex = $scrollOffset + $i
            [Console]::SetCursorPosition($X, $Y + $i)

            if ($itemIndex -lt $Items.Count) {
                $item = $Items[$itemIndex]
                $displayText = if ($DisplayProperty) { $item.$DisplayProperty } else { $item.ToString() }

                if ($displayText.Length -gt $Width - 4) {
                    $displayText = $displayText.Substring(0, $Width - 7) + "..."
                }

                if ($itemIndex -eq $currentIndex) {
                    Write-Host "`e[46m`e[30m > $($displayText.PadRight($Width - 4))`e[0m" -NoNewline
                } else {
                    Write-Host "   $($displayText.PadRight($Width - 4))" -NoNewline
                }
            } else {
                Write-Host (' ' * $Width) -NoNewline
            }
        }

        # Show scroll indicator
        if ($Items.Count -gt $visibleItems) {
            $scrollPercent = [Math]::Floor(($scrollOffset / [Math]::Max(1, $Items.Count - $visibleItems)) * 100)
            [Console]::SetCursorPosition($X + $Width - 10, $Y + $visibleItems)
            Write-Host "`e[90m[$scrollPercent%]`e[0m" -NoNewline
        }

        # Wait for input
        $key = Get-KeyPress -Wait

        switch ($key.Key) {
            "UpArrow" {
                if ($currentIndex -gt 0) { $currentIndex-- }
            }
            "DownArrow" {
                if ($currentIndex -lt $Items.Count - 1) { $currentIndex++ }
            }
            "PageUp" {
                $currentIndex = [Math]::Max(0, $currentIndex - $visibleItems)
            }
            "PageDown" {
                $currentIndex = [Math]::Min($Items.Count - 1, $currentIndex + $visibleItems)
            }
            "Home" {
                $currentIndex = 0
            }
            "End" {
                $currentIndex = $Items.Count - 1
            }
            "Enter" {
                return $currentIndex
            }
            "Escape" {
                return -1
            }
        }

        # Number key quick selection
        if ($key.Char -ge '1' -and $key.Char -le '9') {
            $quickIndex = [int]::Parse($key.Char.ToString()) - 1
            if ($quickIndex -lt $Items.Count) {
                return $quickIndex
            }
        }
    }
}

function Clear-InputBuffer {
    <#
    .SYNOPSIS
    Clears any pending key presses from the input buffer
    #>
    while ([Console]::KeyAvailable) {
        [Console]::ReadKey($true) | Out-Null
    }
}

# Export module members
# Functions available after dot-sourcing
