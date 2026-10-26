# ============================================================
# Pablitus Prompt Framework (PPF)
# Nord.Theme.ps1
# ============================================================

# Palette based on the official Nord colours:
# https://www.nordtheme.com/docs/colors-and-palettes
Register-PromptTheme `
    -Name "Nord" `
    -Palette @{
        # Legacy colour aliases kept for ANSI themes and third-party segments.
        "Background" = "Black"
        "Foreground" = "White"
        "Primary"    = "Blue"
        "Secondary"  = "Cyan"
        "Success"    = "Green"
        "Warning"    = "Yellow"
        "Error"      = "Red"

        # Truecolor PowerLine palette.
        "Text"       = "#eceff4"
        "DarkText"   = "#2e3440"
        "SessionBg"  = "#5e81ac"
        "ProjectBg"  = "#8fbcbb"
        "PathBg"     = "#434c5e"
        "GitBg"      = "#a3be8c"
        "PythonBg"   = "#b48ead"
        "NodeBg"     = "#81a1c1"
        "TimeBg"     = "#ebcb8b"
        "DockerBg"   = "#5e81ac"
        "WslBg"      = "#b48ead"
        "BatteryBg"  = "#a3be8c"
        "CpuBg"      = "#d08770"
        "MemoryBg"   = "#bf616a"
        "KubeBg"     = "#5e81ac"
        "DotNetBg"   = "#8fbcbb"
    } `
    -Icons @{
        "Session"         = ""
        "Project"         = ""
        "Path"            = ""
        "GitClean"        = ""
        "GitDirty"        = ""
        "Python"          = ""
        "Node"            = ""
        "Time"            = [string][char]0xF017
        "Docker"          = ""
        "WSL"             = ""
        "Battery"         = "🔋"
        "BatteryCharging" = "⚡"
        "CPU"             = ""
        "Memory"          = "﬙"
        "Kubernetes"      = "⎈"
        "DotNet"          = ""
    } `
    -Segments @{
        "Session" = @{
            Visible         = $true
            Icon            = "Session"
            Foreground      = "Text"
            Background      = "SessionBg"
            LeadingDiamond  = ""
            PowerlineSymbol = ""
        }
        "Project" = @{
            Visible         = $false
            Icon            = "Project"
            Foreground      = "DarkText"
            Background      = "ProjectBg"
            PowerlineSymbol = ""
        }
        "Path" = @{
            Visible         = $true
            Icon            = "Path"
            Foreground      = "Text"
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
        "Python" = @{
            Visible         = $true
            Icon            = "Python"
            Foreground      = "DarkText"
            Background      = "PythonBg"
            PowerlineSymbol = ""
        }
        "Node" = @{
            Visible         = $true
            Icon            = "Node"
            Foreground      = "DarkText"
            Background      = "NodeBg"
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
        "Docker" = @{
            Visible         = $false
            Icon            = "Docker"
            Foreground      = "Text"
            Background      = "DockerBg"
            PowerlineSymbol = ""
        }
        "WSL" = @{
            Visible         = $false
            Icon            = "WSL"
            Foreground      = "DarkText"
            Background      = "WslBg"
            PowerlineSymbol = ""
        }
        "Battery" = @{
            Visible         = $false
            Foreground      = "DarkText"
            Background      = "BatteryBg"
            PowerlineSymbol = ""
        }
        "CPU" = @{
            Visible         = $false
            Foreground      = "DarkText"
            Background      = "CpuBg"
            PowerlineSymbol = ""
        }
        "Memory" = @{
            Visible         = $false
            Foreground      = "Text"
            Background      = "MemoryBg"
            PowerlineSymbol = ""
        }
        "Kubernetes" = @{
            Visible         = $false
            Foreground      = "Text"
            Background      = "KubeBg"
            PowerlineSymbol = ""
        }
        "DotNet" = @{
            Visible         = $false
            Icon            = "DotNet"
            Foreground      = "DarkText"
            Background      = "DotNetBg"
            PowerlineSymbol = ""
        }
    }
