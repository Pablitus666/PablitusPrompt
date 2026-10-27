# ============================================================
# Pablitus Prompt Framework (PPF)
# Tema oficial: Pablitus Sunset
#
# Paleta de naranjas y rojos inspirada en el atardecer.
# Ideal para sesiones de trabajo nocturno y desarrolladores
# que prefieren tonos cálidos.
# Demuestra: transient prompt con filler personalizado,
# tooltips con múltiples palabras clave, right prompt con
# overflow: break.
# ============================================================

Register-PromptTheme `
    -Name "Pablitus Sunset" `
    -Palette @{
        Background   = "#2d1b19"
        Foreground   = "#ffd166"
        Primary      = "#ef476f"
        Secondary    = "#118ab2"
        Success      = "#06d6a0"
        Warning      = "#ffd166"
        Error        = "#ef476f"
        SessionBg    = "#ef476f"
        SessionFg    = "#2d1b19"
        PathBg       = "#118ab2"
        PathFg       = "#2d1b19"
        GitBg        = "#06d6a0"
        GitFg        = "#2d1b19"
        TimeBg       = "#ffd166"
        TimeFg       = "#2d1b19"
        Accent       = "#118ab2"
        Surface      = "#1a0f0e"
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
            Foreground     = "#2d1b19"
            Background     = "#ef476f"
            Style          = "powerline"
            LeadingDiamond = ""
            TrailingDiamond= ""
        }
        Path = @{
            Visible        = $true
            Icon           = ""
            Foreground     = "#2d1b19"
            Background     = "#118ab2"
            Style          = "powerline"
            PathStyle      = "folder"
            LeadingDiamond = ""
            TrailingDiamond= ""
        }
        Git = @{
            Visible        = $true
            Icon           = ""
            Foreground     = "#2d1b19"
            Background     = "#06d6a0"
            Style          = "powerline"
            IconClean      = ""
            IconDirty      = ""
            LeadingDiamond = ""
            TrailingDiamond= ""
        }
        Time = @{
            Visible        = $true
            Icon           = ([string][char]0xF017)
            Foreground     = "#2d1b19"
            Background     = "#ffd166"
            Style          = "powerline"
            Template       = "{{ .Time }}"
            LeadingDiamond = ""
            TrailingDiamond= ""
        }
        Project = @{
            Visible        = $false
            Icon           = ""
            Foreground     = "#ffd166"
            Background     = "#1a0f0e"
            Style          = "plain"
        }
    }
