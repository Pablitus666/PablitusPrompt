# ============================================================
# Pablitus Prompt Framework (PPF)
# Tema oficial: Pablitus Candy
#
# Inspirado en el tema candy de Oh My Posh.
# Paleta de colores pastel, suave y amigable.
# ============================================================

Register-PromptTheme `
    -Name "Pablitus Candy" `
    -Palette @{
        Background   = "#fce7f3"
        Foreground   = "#5a2d82"
        Primary      = "#ec4899"
        Secondary    = "#f472b6"
        Success      = "#86efac"
        Warning      = "#fbbf24"
        Error        = "#fb7185"
        SessionBg    = "#ec4899"
        SessionFg    = "#fce7f3"
        PathBg       = "#fbcfe8"
        PathFg       = "#5a2d82"
        GitBg        = "#f472b6"
        GitFg        = "#5a2d82"
        TimeBg       = "#86efac"
        TimeFg       = "#5a2d82"
        Accent       = "#f472b6"
        Surface      = "#fdf2f8"
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
            Foreground     = "#fce7f3"
            Background     = "#ec4899"
            Style          = "powerline"
            LeadingDiamond = ""
            TrailingDiamond= ""
        }
        Path = @{
            Visible        = $true
            Icon           = ""
            Foreground     = "#5a2d82"
            Background     = "#fbcfe8"
            Style          = "powerline"
            PathStyle      = "folder"
            LeadingDiamond = ""
            TrailingDiamond= ""
        }
        Git = @{
            Visible        = $true
            Icon           = ""
            Foreground     = "#5a2d82"
            Background     = "#f472b6"
            Style          = "powerline"
            IconClean      = ""
            IconDirty      = ""
            LeadingDiamond = ""
            TrailingDiamond= ""
        }
        Time = @{
            Visible        = $true
            Icon           = ([string][char]0xF017)
            Foreground     = "#5a2d82"
            Background     = "#86efac"
            Style          = "powerline"
            Template       = "{{ .Time }}"
            LeadingDiamond = ""
            TrailingDiamond= ""
        }
        Project = @{
            Visible        = $false
            Icon           = ""
            Foreground     = "#c0c0c0"
            Background     = "#fdf2f8"
            Style          = "plain"
        }
    }
