# ============================================================
# Pablitus Prompt Framework (PPF)
# Tema oficial: Pablitus Avit
#
# Inspirado en el tema avit de Oh My Posh.
# Paleta azul/blanco clásico para entornos profesionales.
# ============================================================

Register-PromptTheme `
    -Name "Pablitus Avit" `
    -Palette @{
        Background   = "#1a1a1a"
        Foreground   = "#c0c0c0"
        Primary      = "#0066cc"
        Secondary    = "#666666"
        Success      = "#00cc00"
        Warning      = "#ffaa00"
        Error        = "#ff4444"
        SessionBg    = "#0066cc"
        SessionFg    = "#1a1a1a"
        PathBg       = "#333333"
        PathFg       = "#c0c0c0"
        GitBg        = "#ffaa00"
        GitFg        = "#1a1a1a"
        TimeBg       = "#00cc00"
        TimeFg       = "#1a1a1a"
        Accent       = "#aaaaaa"
        Surface      = "#2a2a2a"
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
            Foreground     = "#1a1a1a"
            Background     = "#0066cc"
            Style          = "powerline"
            LeadingDiamond = ""
            TrailingDiamond= ""
        }
        Path = @{
            Visible        = $true
            Icon           = ""
            Foreground     = "#c0c0c0"
            Background     = "#333333"
            Style          = "powerline"
            PathStyle      = "folder"
            LeadingDiamond = ""
            TrailingDiamond= ""
        }
        Git = @{
            Visible        = $true
            Icon           = ""
            Foreground     = "#1a1a1a"
            Background     = "#ffaa00"
            Style          = "powerline"
            IconClean      = ""
            IconDirty      = ""
            LeadingDiamond = ""
            TrailingDiamond= ""
        }
        Time = @{
            Visible        = $true
            Icon           = ([string][char]0xF017)
            Foreground     = "#1a1a1a"
            Background     = "#00cc00"
            Style          = "powerline"
            Template       = "{{ .Time }}"
            LeadingDiamond = ""
            TrailingDiamond= ""
        }
        Project = @{
            Visible        = $false
            Icon           = ""
            Foreground     = "#c0c0c0"
            Background     = "#2a2a2a"
            Style          = "plain"
        }
    }
