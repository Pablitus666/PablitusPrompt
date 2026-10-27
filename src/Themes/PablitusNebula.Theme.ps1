# ============================================================
# Pablitus Prompt Framework (PPF)
# Tema oficial: Pablitus Nebula
#
# Inspirado en nebulosas espaciales.
# Paleta púrpura/azul oscuro, ideal para entornos oscuros.
# ============================================================

Register-PromptTheme `
    -Name "Pablitus Nebula" `
    -Palette @{
        Background   = "#0f0c29"
        Foreground   = "#e0e0e0"
        Primary      = "#bb86fc"
        Secondary    = "#03dac6"
        Success      = "#03dac6"
        Warning      = "#ff4081"
        Error        = "#cf6679"
        SessionBg    = "#bb86fc"
        SessionFg    = "#0f0c29"
        PathBg       = "#370028"
        PathFg       = "#e0e0e0"
        GitBg        = "#03dac6"
        GitFg        = "#0f0c29"
        TimeBg       = "#cf6679"
        TimeFg       = "#0f0c29"
        Accent       = "#03dac6"
        Surface      = "#1a173a"
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
            Foreground     = "#0f0c29"
            Background     = "#bb86fc"
            Style          = "powerline"
            LeadingDiamond = ""
            TrailingDiamond= ""
        }
        Path = @{
            Visible        = $true
            Icon           = ""
            Foreground     = "#e0e0e0"
            Background     = "#370028"
            Style          = "powerline"
            PathStyle      = "folder"
            LeadingDiamond = ""
            TrailingDiamond= ""
        }
        Git = @{
            Visible        = $true
            Icon           = ""
            Foreground     = "#0f0c29"
            Background     = "#03dac6"
            Style          = "powerline"
            IconClean      = ""
            IconDirty      = ""
            LeadingDiamond = ""
            TrailingDiamond= ""
        }
        Time = @{
            Visible        = $true
            Icon           = ([string][char]0xF017)
            Foreground     = "#0f0c29"
            Background     = "#cf6679"
            Style          = "powerline"
            Template       = "{{ .Time }}"
            LeadingDiamond = ""
            TrailingDiamond= ""
        }
        Project = @{
            Visible        = $false
            Icon           = ""
            Foreground     = "#e0e0e0"
            Background     = "#1a173a"
            Style          = "plain"
        }
    }
