# ============================================================
# Pablitus Prompt Framework (PPF)
# Tema oficial: Pablitus Matrix
#
# Demuestra las capacidades del framework:
#   - PowerLine truecolor con diamantes sobre paleta verde matriz
#   - Segmentos Session, Path, Git, Time con diamantes /
#   - Segmentos Project y WSL ocultos (Visible = false)
#   - Paleta monocroma verde sobre fondo negro
# ============================================================

Register-PromptTheme `
    -Name "Pablitus Matrix" `
    -Palette @{
        Background   = "#000000"
        Foreground   = "#00ff00"
        Primary      = "#00ff00"
        Secondary    = "#33ff33"
        Success      = "#33ff33"
        Warning      = "#66ff66"
        Error        = "#ff3333"
        SessionBg    = "#00ff00"
        SessionFg    = "#000000"
        PathBg       = "#33ff33"
        PathFg       = "#000000"
        GitBg        = "#00ff00"
        GitFg        = "#000000"
        TimeBg       = "#33ff33"
        TimeFg       = "#000000"
        Accent       = "#33ff33"
        Surface      = "#0a0a0a"
    } `
    -Icons @{
        Session      = ""
        Path         = ""
        GitClean     = ""
        GitDirty     = ""
        Time         = [string][char]0xF017
        Project      = ""
        WSL          = ""
        PromptSymbol = ""
    } `
    -Segments @{
        Session = @{
            Visible        = $true
            Icon           = ""
            Foreground     = "#000000"
            Background     = "#00ff00"
            Style          = "powerline"
            LeadingDiamond = ""
            TrailingDiamond= ""
        }
        Path = @{
            Visible        = $true
            Icon           = ""
            Foreground     = "#000000"
            Background     = "#33ff33"
            Style          = "powerline"
            PathStyle      = "folder"
            LeadingDiamond = ""
            TrailingDiamond= ""
        }
        Git = @{
            Visible        = $true
            Icon           = ""
            Foreground     = "#000000"
            Background     = "#00ff00"
            Style          = "powerline"
            IconClean      = ""
            IconDirty      = ""
            LeadingDiamond = ""
            TrailingDiamond= ""
        }
        Time = @{
            Visible        = $true
            Icon           = ([string][char]0xF017)
            Foreground     = "#000000"
            Background     = "#33ff33"
            Style          = "powerline"
            Template       = "{{ .Time }}"
            LeadingDiamond = ""
            TrailingDiamond= ""
        }
        Project = @{
            Visible        = $false
            Icon           = ""
            Foreground     = "#00ff00"
            Background     = "#0a0a0a"
            Style          = "plain"
        }
        WSL = @{
            Visible        = $false
            Icon           = "�ubuntu"
            Foreground     = "#00ff00"
            Background     = "#0a0a0a"
            Style          = "plain"
        }
    }
