# ============================================================
# Pablitus Prompt Framework (PPF)
# Tema oficial: Pablitus Honukai
#
# Inspirado en el tema honukai de Oh My Posh.
# Paleta verde/azul marino, ideal para entornos de desarrollo.
# ============================================================

Register-PromptTheme `
    -Name "Pablitus Honukai" `
    -Palette @{
        Background   = "#01243a"
        Foreground   = "#e0e0e0"
        Primary      = "#1abc9c"
        Secondary    = "#2c3e50"
        Success      = "#2ecc71"
        Warning      = "#f39c12"
        Error        = "#e74c3c"
        SessionBg    = "#1abc9c"
        SessionFg    = "#01243a"
        PathBg       = "#16a085"
        PathFg       = "#e0e0e0"
        GitBg        = "#f39c12"
        GitFg        = "#01243a"
        TimeBg       = "#2ecc71"
        TimeFg       = "#01243a"
        Accent       = "#34495e"
        Surface      = "#0c1e2a"
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
            Foreground     = "#01243a"
            Background     = "#1abc9c"
            Style          = "powerline"
            LeadingDiamond = ""
            TrailingDiamond= ""
        }
        Path = @{
            Visible        = $true
            Icon           = ""
            Foreground     = "#e0e0e0"
            Background     = "#16a085"
            Style          = "powerline"
            PathStyle      = "folder"
            LeadingDiamond = ""
            TrailingDiamond= ""
        }
        Git = @{
            Visible        = $true
            Icon           = ""
            Foreground     = "#01243a"
            Background     = "#f39c12"
            Style          = "powerline"
            IconClean      = ""
            IconDirty      = ""
            LeadingDiamond = ""
            TrailingDiamond= ""
        }
        Time = @{
            Visible        = $true
            Icon           = ([string][char]0xF017)
            Foreground     = "#01243a"
            Background     = "#2ecc71"
            Style          = "powerline"
            Template       = "{{ .Time }}"
            LeadingDiamond = ""
            TrailingDiamond= ""
        }
        Project = @{
            Visible        = $false
            Icon           = ""
            Foreground     = "#e0e0e0"
            Background     = "#0c1e2a"
            Style          = "plain"
        }
    }
