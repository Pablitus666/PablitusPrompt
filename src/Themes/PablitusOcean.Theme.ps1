# ============================================================
# Pablitus Prompt Framework (PPF)
# Tema oficial: Pablitus Ocean
#
# Paleta de azules profundos inspirada en el océano.
# Ideal para desarrolladores que trabajan con rutas, git y Docker.
# Demuestra: transient prompt con right_template, tooltips con tips
# específicos de Docker, right prompt con filler.
# ============================================================

Register-PromptTheme `
    -Name "Pablitus Ocean" `
    -Palette @{
        Background   = "#0a192f"
        Foreground   = "#8892b0"
        Primary      = "#64ffda"
        Secondary    = "#1d3557"
        Success      = "#52ad89"
        Warning      = "#ffd700"
        Error        = "#ff6b6b"
        SessionBg    = "#1d3557"
        SessionFg    = "#64ffda"
        PathBg       = "#112240"
        PathFg       = "#8892b0"
        GitBg        = "#64ffda"
        GitFg        = "#0a192f"
        TimeBg       = "#233554"
        TimeFg       = "#8892b0"
        Accent       = "#1d3557"
        Surface      = "#0d1b2a"
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
            Foreground     = "#64ffda"
            Background     = "#1d3557"
            Style          = "powerline"
            LeadingDiamond = ""
            TrailingDiamond= ""
        }
        Path = @{
            Visible        = $true
            Icon           = ""
            Foreground     = "#8892b0"
            Background     = "#112240"
            Style          = "powerline"
            PathStyle      = "folder"
            LeadingDiamond = ""
            TrailingDiamond= ""
        }
        Git = @{
            Visible        = $true
            Icon           = ""
            Foreground     = "#0a192f"
            Background     = "#64ffda"
            Style          = "powerline"
            IconClean      = ""
            IconDirty      = ""
            LeadingDiamond = ""
            TrailingDiamond= ""
        }
        Time = @{
            Visible        = $true
            Icon           = ([string][char]0xF017)
            Foreground     = "#8892b0"
            Background     = "#233554"
            Style          = "powerline"
            Template       = "{{ .Time }}"
            LeadingDiamond = ""
            TrailingDiamond= ""
        }
        Project = @{
            Visible        = $false
            Icon           = ""
            Foreground     = "#8892b0"
            Background     = "#0d1b2a"
            Style          = "plain"
        }
    }
