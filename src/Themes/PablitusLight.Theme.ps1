# ============================================================
# Pablitus Prompt Framework (PPF)
# Tema oficial: Pablitus Light (Fase 3C)
#
# Demuestra las capacidades del framework:
#   - PowerLine truecolor con diamantes sobre paleta clara/neón
#   - Segmentos Session, Path, Git, Time
#   - Glifo de reloj Nerd Font (U+F017)
# ============================================================

Register-PromptTheme `
    -Name "Pablitus Light" `
    -Palette @{
        Background   = "#fafafa"
        Foreground   = "#1a1a1a"
        Primary      = "#00ff9f"
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
        TimeBg       = "#ff6b00"
        TimeFg       = "#ffffff"
        Accent       = "#d946ef"
        Surface      = "#ededed"
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
            Background     = "#ff6b00"
            Style          = "powerline"
            Template       = "{{ .Time }}"
            LeadingDiamond = ""
            TrailingDiamond= ""
        }
        Project = @{
            Visible        = $false
            Icon           = ""
            Foreground     = "#1a1a1a"
            Background     = "#ededed"
            Style          = "plain"
        }
    }
