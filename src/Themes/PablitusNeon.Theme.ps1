# ============================================================
# Pablitus Prompt Framework (PPF)
# Tema oficial: Pablitus Neon
#
# Demuestra las capacidades del framework:
#   - PowerLine truecolor con diamantes sobre paleta neón oscura
#   - Segmentos Session, Path, Git, Time con diamantes /
#   - Glifo de reloj Nerd Font (U+F017) en segmento Time
# ============================================================

Register-PromptTheme `
    -Name "Pablitus Neon" `
    -Palette @{
        Background   = "#0a0a0a"
        Foreground   = "#ffffff"
        Primary      = "#ff00ff"
        Secondary    = "#00e5ff"
        Success      = "#00ff9f"
        Warning      = "#ffd700"
        Error        = "#ff3131"
        SessionBg    = "#ff00ff"
        SessionFg    = "#ffffff"
        PathBg       = "#00e5ff"
        PathFg       = "#000000"
        GitBg        = "#00ff9f"
        GitFg        = "#000000"
        TimeBg       = "#ff00ff"
        TimeFg       = "#ffffff"
        Accent       = "#ff00ff"
        Surface      = "#121212"
    } `
    -Icons @{
        Session      = ""
        Path         = ""
        GitClean     = ""
        GitDirty     = ""
        Time         = [string][char]0xF017
        Project      = ""
        PromptSymbol = ""
    } `
    -Segments @{
        Session = @{
            Visible        = $true
            Icon           = ""
            Foreground     = "#ffffff"
            Background     = "#ff00ff"
            Style          = "powerline"
            LeadingDiamond = ""
            TrailingDiamond= ""
        }
        Path = @{
            Visible        = $true
            Icon           = ""
            Foreground     = "#000000"
            Background     = "#00e5ff"
            Style          = "powerline"
            PathStyle      = "folder"
            LeadingDiamond = ""
            TrailingDiamond= ""
        }
        Git = @{
            Visible        = $true
            Icon           = ""
            Foreground     = "#000000"
            Background     = "#00ff9f"
            Style          = "powerline"
            IconClean      = ""
            IconDirty      = ""
            LeadingDiamond = ""
            TrailingDiamond= ""
        }
        Time = @{
            Visible        = $true
            Icon           = ([string][char]0xF017)
            Foreground     = "#ffffff"
            Background     = "#ff00ff"
            Style          = "powerline"
            Template       = "{{ .Time }}"
            LeadingDiamond = ""
            TrailingDiamond= ""
        }
        Project = @{
            Visible        = $false
            Icon           = ""
            Foreground     = "#ffffff"
            Background     = "#121212"
            Style          = "plain"
        }
    }
