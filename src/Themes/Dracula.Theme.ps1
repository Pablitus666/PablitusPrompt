# ============================================================
# Pablitus Prompt Framework (PPF)
# Dracula.Theme.ps1
# ============================================================

# Palette based on the official Dracula colours:
# https://draculatheme.com/contribute
Register-PromptTheme `
    -Name "Dracula" `
    -Palette @{
        "Background" = "Black"
        "Foreground" = "White"
        "Primary"    = "Magenta"
        "Secondary"  = "Cyan"
        "Success"    = "Green"
        "Warning"    = "Yellow"
        "Error"      = "Red"

        "Text"      = "#f8f8f2"
        "DarkText"  = "#282a36"
        "SessionBg" = "#44475a"
        "PathBg"    = "#6272a4"
        "GitBg"     = "#ffb86c"
        "NodeBg"    = "#8be9fd"
        "PythonBg"  = "#50fa7b"
        "TimeBg"    = "#ff79c6"
    } `
    -Icons @{
        "Session"  = ""
        "Project"  = ""
        "Path"     = ""
        "GitClean" = ""
        "GitDirty" = ""
        "Python"   = ""
        "Node"     = ""
        "Time"     = [string][char]0xF017
    } `
    -Segments @{
        "Session" = @{
            Visible        = $true
            Icon           = ""
            Foreground     = "Text"
            Background     = "SessionBg"
            ShowHost       = $false
            LeadingDiamond = ""
            PowerlineSymbol = ""
        }
        "Path" = @{
            Visible         = $true
            Icon            = ""
            Foreground      = "Text"
            Background      = "PathBg"
            PathStyle       = "Folder"
            PowerlineSymbol = ""
        }
        "Git" = @{
            Visible         = $true
            IconClean       = ""
            IconDirty       = ""
            Foreground      = "DarkText"
            Background      = "GitBg"
            PowerlineSymbol = ""
        }
        "Node" = @{
            Visible         = $true
            Icon            = ""
            Foreground      = "DarkText"
            Background      = "NodeBg"
            PowerlineSymbol = ""
        }
        "Time" = @{
            Visible         = $true
            Icon            = "Time"
            Foreground      = "DarkText"
            Background      = "TimeBg"
            LeadingDiamond  = ""
            TrailingDiamond = ""
        }

        # Segments that are not part of the official Oh My Posh Dracula
        # layout stay available in the framework but hidden for this theme.
        "Project"    = @{ Visible = $false }
        "Python"     = @{ Visible = $false }
        "Docker"     = @{ Visible = $false }
        "WSL"        = @{ Visible = $false }
        "Battery"    = @{ Visible = $false }
        "CPU"        = @{ Visible = $false }
        "Memory"     = @{ Visible = $false }
        "Kubernetes" = @{ Visible = $false }
        "DotNet"     = @{ Visible = $false }
    }
