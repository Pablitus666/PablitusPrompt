# ============================================================
# Pablitus Prompt Framework (PPF)
# Tema oficial: Pablitus Solarized
#
# Inspirado en el tema powerlevel10k de Oh My Posh.
# Paleta azul y naranja inspirada en el esquema Solarized.
# Ideal para entornos con alto contraste y buena legibilidad.
# ============================================================

Register-PromptTheme `
    -Name "Pablitus Solarized" `
    -Palette @{
        Background   = "#002b36"
        Foreground   = "#839496"
        Primary      = "#268bd2"
        Secondary    = "#cb4b16"
        Success      = "#859900"
        Warning      = "#d33682"
        Error        = "#dc322f"
        SessionBg    = "#268bd2"
        SessionFg    = "#002b36"
        PathBg       = "#073642"
        PathFg       = "#839496"
        GitBg        = "#cb4b16"
        GitFg        = "#002b36"
        TimeBg       = "#859900"
        TimeFg       = "#002b36"
        Accent       = "#d33682"
        Surface      = "#073642"
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
            Foreground     = "#002b36"
            Background     = "#268bd2"
            Style          = "powerline"
            LeadingDiamond = ""
            TrailingDiamond= ""
        }
        Path = @{
            Visible        = $true
            Icon           = ""
            Foreground     = "#839496"
            Background     = "#073642"
            Style          = "powerline"
            PathStyle      = "folder"
            LeadingDiamond = ""
            TrailingDiamond= ""
        }
        Git = @{
            Visible        = $true
            Icon           = ""
            Foreground     = "#002b36"
            Background     = "#cb4b16"
            Style          = "powerline"
            IconClean      = ""
            IconDirty      = ""
            LeadingDiamond = ""
            TrailingDiamond= ""
        }
        Time = @{
            Visible        = $true
            Icon           = ([string][char]0xF017)
            Foreground     = "#002b36"
            Background     = "#859900"
            Style          = "powerline"
            Template       = "{{ .Time }}"
            LeadingDiamond = ""
            TrailingDiamond= ""
        }
        Project = @{
            Visible        = $false
            Icon           = ""
            Foreground     = "#839496"
            Background     = "#073642"
            Style          = "plain"
        }
    }
