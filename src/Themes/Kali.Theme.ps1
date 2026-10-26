# ============================================================
# Pablitus Prompt Framework (PPF)
# Kali.Theme.ps1
# ============================================================

# Reuse the Nerd Font glyphs registered by the Default theme. Clone the
# hashtable so adding the Time glyph does not mutate the Default theme.
$kaliIcons = @{}
$defaultIcons = (Get-PromptTheme -Name "Default").Icons
if ($defaultIcons) {
    foreach ($key in $defaultIcons.Keys) {
        $kaliIcons[$key] = $defaultIcons[$key]
    }
}
$kaliIcons["Time"] = [string][char]0xF017

Register-PromptTheme `
    -Name "Kali" `
    -Palette @{
        # Legacy colour aliases kept for ANSI themes and third-party segments.
        "Background" = "Black"
        "Foreground" = "White"
        "Primary"    = "Green"
        "Secondary"  = "Cyan"
        "Success"    = "Green"
        "Warning"    = "Yellow"
        "Error"      = "Red"

        # Truecolor PowerLine palette.
        "Text"       = "#f8f8f2"
        "DarkText"   = "#101010"
        "SessionBg"  = "#00a86b"
        "ProjectBg"  = "#4caf50"
        "PathBg"     = "#00838f"
        "GitBg"      = "#ffc107"
        "PythonBg"   = "#ff9800"
        "NodeBg"     = "#8bc34a"
        "TimeBg"     = "#9c27b0"
        "DockerBg"   = "#0288d1"
        "WslBg"      = "#7c4dff"
        "BatteryBg"  = "#8bc34a"
        "CpuBg"      = "#ff5722"
        "MemoryBg"   = "#f44336"
        "KubeBg"     = "#326ce5"
        "DotNetBg"   = "#512bd4"
    } `
    -Icons $kaliIcons `
    -Segments @{
        "Session" = @{
            Visible         = $true
            Icon            = "Session"
            Foreground      = "DarkText"
            Background      = "SessionBg"
            ShowHost        = $true
            LeadingDiamond  = ""
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
        "Time" = @{
            Visible         = $true
            Icon            = "Time"
            Foreground      = "Text"
            Background      = "TimeBg"
            TrailingDiamond = ""
            PowerlineSymbol = ""
        }
        "Project" = @{
            Visible         = $false
            Icon            = "Project"
            Foreground      = "DarkText"
            Background      = "ProjectBg"
        }
        "Node" = @{
            Visible         = $false
            Icon            = "Node"
            Foreground      = "DarkText"
            Background      = "NodeBg"
        }
        "Memory" = @{
            Visible         = $false
            Foreground      = "DarkText"
            Background      = "MemoryBg"
        }
        "CPU" = @{
            Visible         = $false
            Foreground      = "DarkText"
            Background      = "CpuBg"
        }
        "Battery" = @{
            Visible         = $false
            Foreground      = "DarkText"
            Background      = "BatteryBg"
        }
        "Docker" = @{
            Visible         = $false
            Icon            = "Docker"
            Foreground      = "Text"
            Background      = "DockerBg"
        }
        "Kubernetes" = @{
            Visible         = $false
            Foreground      = "Text"
            Background      = "KubeBg"
        }
        "DotNet" = @{
            Visible         = $false
            Icon            = "DotNet"
            Foreground      = "Text"
            Background      = "DotNetBg"
        }
        "WSL" = @{
            Visible         = $false
            Icon            = "WSL"
            Foreground      = "Text"
            Background      = "WslBg"
        }
    }
