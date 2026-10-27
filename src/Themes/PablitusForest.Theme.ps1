# ============================================================
# Pablitus Prompt Framework (PPF)
# Tema oficial: Pablitus Forest
#
# Paleta de verdes naturales inspirada en el bosque.
# Demuestra:
#   - PowerLine truecolor con diamantes sobre paleta verde
#   - Segmentos Session, Path, Git, Time con diamantes /
#   - Glifo de reloj Nerd Font (U+F017) en segmento Time
# ============================================================

Register-PromptTheme `
    -Name "Pablitus Forest" `
    -Palette @{
        Background   = "#1b2a1b"
        Foreground   = "#d4edda"
        Primary      = "#2e8b57"
        Secondary    = "#98fb98"
        Success      = "#2e8b57"
        Warning      = "#8b4513"
        Error        = "#8b4513"
        SessionBg    = "#2e8b57"
        SessionFg    = "#1b2a1b"
        PathBg       = "#98fb98"
        PathFg       = "#1b2a1b"
        GitBg        = "#2e8b57"
        GitFg        = "#1b2a1b"
        TimeBg       = "#98fb98"
        TimeFg       = "#1b2a1b"
        Accent       = "#2e8b57"
        Surface      = "#233a23"
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
            Foreground     = "#1b2a1b"
            Background     = "#2e8b57"
            Style          = "powerline"
            LeadingDiamond = ""
            TrailingDiamond= ""
        }
        Path = @{
            Visible        = $true
            Icon           = ""
            Foreground     = "#1b2a1b"
            Background     = "#98fb98"
            Style          = "powerline"
            PathStyle      = "folder"
            LeadingDiamond = ""
            TrailingDiamond= ""
        }
        Git = @{
            Visible        = $true
            Icon           = ""
            Foreground     = "#1b2a1b"
            Background     = "#2e8b57"
            Style          = "powerline"
            IconClean      = ""
            IconDirty      = ""
            LeadingDiamond = ""
            TrailingDiamond= ""
        }
        Time = @{
            Visible        = $true
            Icon           = ([string][char]0xF017)
            Foreground     = "#1b2a1b"
            Background     = "#98fb98"
            Style          = "powerline"
            Template       = "{{ .Time }}"
            LeadingDiamond = ""
            TrailingDiamond= ""
        }
        Project = @{
            Visible        = $false
            Icon           = ""
            Foreground     = "#d4edda"
            Background     = "#233a23"
            Style          = "plain"
        }
    }
