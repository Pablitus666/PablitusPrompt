# ============================================================
# Pablitus Prompt Framework (PPF)
# Tema oficial: Pablitus Cyberpunk
#
# Paleta neón cyberpunk sobre fondo casi negro.
# Demuestra:
#   - PowerLine truecolor con diamantes sobre paleta neón
#   - Segmentos Session, Path, Git, Time con diamantes /
#   - Glifo de reloj Nerd Font (U+F017) en segmento Time
# ============================================================

Register-PromptTheme `
    -Name "Pablitus Cyberpunk" `
    -Palette @{
        Background   = "#0a0a0f"
        Foreground   = "#ff00ff"
        Primary      = "#00ffff"
        Secondary    = "#ff00ff"
        Success      = "#00ffff"
        Warning      = "#ffff00"
        Error        = "#ff00ff"
        SessionBg    = "#00ffff"
        SessionFg    = "#0a0a0f"
        PathBg       = "#ff00ff"
        PathFg       = "#0a0a0f"
        GitBg        = "#ffff00"
        GitFg        = "#0a0a0f"
        TimeBg       = "#00ffff"
        TimeFg       = "#0a0a0f"
        Accent       = "#ff00ff"
        Surface      = "#12121a"
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
            Foreground     = "#0a0a0f"
            Background     = "#00ffff"
            Style          = "powerline"
            LeadingDiamond = ""
            TrailingDiamond= ""
        }
        Path = @{
            Visible        = $true
            Icon           = ""
            Foreground     = "#0a0a0f"
            Background     = "#ff00ff"
            Style          = "powerline"
            PathStyle      = "folder"
            LeadingDiamond = ""
            TrailingDiamond= ""
        }
        Git = @{
            Visible        = $true
            Icon           = ""
            Foreground     = "#0a0a0f"
            Background     = "#ffff00"
            Style          = "powerline"
            IconClean      = ""
            IconDirty      = ""
            LeadingDiamond = ""
            TrailingDiamond= ""
        }
        Time = @{
            Visible        = $true
            Icon           = ([string][char]0xF017)
            Foreground     = "#0a0a0f"
            Background     = "#00ffff"
            Style          = "powerline"
            Template       = "{{ .Time }}"
            LeadingDiamond = ""
            TrailingDiamond= ""
        }
        Project = @{
            Visible        = $false
            Icon           = ""
            Foreground     = "#ff00ff"
            Background     = "#12121a"
            Style          = "plain"
        }
    }
