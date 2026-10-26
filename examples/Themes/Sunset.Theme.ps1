# ============================================================
# Pablitus Prompt Framework (PPF)
# Sunset.Theme.ps1 - custom theme example
# ============================================================
# Import this theme with:
#   Import-PromptTheme -Path .\examples\Themes\Sunset.Theme.ps1
#   Set-PromptTheme -Name "Sunset"

Register-PromptTheme `
    -Name "Sunset" `
    -Palette @{
        "Background" = "Black"
        "Foreground" = "White"
        "Primary"    = "Red"
        "Secondary"  = "Yellow"
        "Success"    = "Green"
        "Warning"    = "Yellow"
        "Error"      = "Red"

        "Text"      = "#fff4e6"
        "DarkText"  = "#2b1b17"
        "SessionBg" = "#ff8a65"
        "PathBg"    = "#ffd54f"
        "GitBg"     = "#81c784"
        "TimeBg"    = "#ba68c8"
    } `
    -Icons @{
        "Session"  = ""
        "Path"     = ""
        "GitClean" = ""
        "GitDirty" = ""
        "Time"     = [string][char]0xF017
    } `
    -Segments @{
        "Session" = @{
            Visible         = $true
            Icon            = "Session"
            Foreground      = "DarkText"
            Background      = "SessionBg"
            LeadingDiamond  = ""
            PowerlineSymbol = ""
        }
        "Path" = @{
            Visible         = $true
            Icon            = "Path"
            Foreground      = "DarkText"
            Background      = "PathBg"
            PathStyle       = "Folder"
            PowerlineSymbol = ""
        }
        "Git" = @{
            Visible         = $true
            IconClean       = "GitClean"
            IconDirty       = "GitDirty"
            Foreground      = "DarkText"
            Background      = "GitBg"
            PowerlineSymbol = ""
        }
        "Time" = @{
            Visible         = $true
            Icon            = "Time"
            Foreground      = "DarkText"
            Background      = "TimeBg"
            TrailingDiamond = ""
            PowerlineSymbol = ""
        }

        # Keep the rest of the prompt out of this compact custom theme.
        "Project"    = @{ Visible = $false }
        "Python"     = @{ Visible = $false }
        "Node"       = @{ Visible = $false }
        "Docker"     = @{ Visible = $false }
        "WSL"        = @{ Visible = $false }
        "Battery"    = @{ Visible = $false }
        "CPU"        = @{ Visible = $false }
        "Memory"     = @{ Visible = $false }
        "Kubernetes" = @{ Visible = $false }
        "DotNet"     = @{ Visible = $false }
    }
