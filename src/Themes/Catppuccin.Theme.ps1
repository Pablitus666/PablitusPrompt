# ============================================================
# Pablitus Prompt Framework (PPF)
# Catppuccin.Theme.ps1
# ============================================================

# Palette based on Catppuccin Mocha:
# https://catppuccin.com/palette
Register-PromptTheme `
    -Name "Catppuccin" `
    -Palette @{
        # Legacy colour aliases kept for ANSI themes and third-party segments.
        "Background" = "Black"
        "Foreground" = "White"
        "Primary"    = "Magenta"
        "Secondary"  = "Cyan"
        "Success"    = "Green"
        "Warning"    = "Yellow"
        "Error"      = "Red"

        # Truecolor PowerLine palette.
        "Text"       = "#cdd6f4"
        "DarkText"   = "#1e1e2e"
        "SessionBg"  = "#cba6f7"
        "ProjectBg"  = "#89b4fa"
        "PathBg"     = "#585b70"
        "GitBg"      = "#fab387"
        "PythonBg"   = "#f9e2af"
        "NodeBg"     = "#a6e3a1"
        "TimeBg"     = "#89b4fa"
        "DockerBg"   = "#89dceb"
        "WslBg"      = "#b4befe"
        "BatteryBg"  = "#a6e3a1"
        "CpuBg"      = "#eba0ac"
        "MemoryBg"   = "#f38ba8"
        "KubeBg"     = "#74c7ec"
        "DotNetBg"   = "#cba6f7"
    } `
    -Icons @{
        "Session"         = ""
        "Project"         = ""
        "Path"            = ""
        "GitClean"        = ""
        "GitDirty"        = ""
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
            Foreground      = "DarkText"
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
            Foreground      = "DarkText"
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
            Foreground      = "DarkText"
            Background      = "MemoryBg"
            PowerlineSymbol = ""
        }
        "Kubernetes" = @{
            Visible         = $false
            Foreground      = "DarkText"
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
