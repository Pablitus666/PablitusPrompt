# ============================================================
# Pablitus Prompt Framework (PPF)
# Tema oficial: Pablitus Dark
#
# Demuestra las capacidades de Fase 3C:
#   - PowerLine truecolor con diamantes
#   - Transient prompt con right_template y filler
#   - Paleta oscura optimizada para terminales con fondo negro
# ============================================================

Register-PromptTheme `
    -Name "Pablitus Dark" `
    -Palette @{
        Background   = "#0a0a0a"
        Foreground   = "#e0e0e0"
        Primary      = "#bb86fc"
        Secondary    = "#03dac6"
        Success      = "#00e676"
        Warning      = "#ffea00"
        Error        = "#ff5252"
        SessionBg    = "#bb86fc"
        SessionFg    = "#000000"
        PathBg       = "#03dac6"
        PathFg       = "#000000"
        GitBg        = "#bb86fc"
        GitFg        = "#000000"
        TimeBg       = "#ff5252"
        TimeFg       = "#ffffff"
        Accent       = "#03dac6"
        Surface      = "#121212"
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
            Foreground     = "#000000"
            Background     = "#bb86fc"
            Style          = "powerline"
            LeadingDiamond = ""
            TrailingDiamond= ""
        }
        Path = @{
            Visible        = $true
            Icon           = ""
            Foreground     = "#000000"
            Background     = "#03dac6"
            Style          = "powerline"
            PathStyle      = "folder"
            LeadingDiamond = ""
            TrailingDiamond= ""
        }
        Git = @{
            Visible        = $true
            Icon           = ""
            Foreground     = "#000000"
            Background     = "#bb86fc"
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
            Background     = "#ff5252"
            Style          = "powerline"
            Template       = "{{ .Time }}"
            LeadingDiamond = ""
            TrailingDiamond= ""
        }
        Project = @{
            Visible        = $false
            Icon           = ""
            Foreground     = "#e0e0e0"
            Background     = "#121212"
            Style          = "plain"
        }
    }
