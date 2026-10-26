# ============================================================
# Pablitus Prompt Framework (PPF)
# Tema oficial: Pablitus
#
# Demuestra las capacidades del framework:
#   - PowerLine truecolor con diamantes
#   - Segmentos Session, Path, Git, Time
#   - Glifo de reloj Nerd Font (U+F017)
# ============================================================

Register-PromptTheme `
    -Name "Pablitus" `
    -Palette @{
        Background   = "#1e1e2e"
        Foreground   = "#cdd6f4"
        Primary      = "#89b4fa"
        Secondary    = "#fab387"
        Success      = "#a6e3a1"
        Warning      = "#f9e2af"
        Error        = "#f38ba8"
        SessionBg    = "#89b4fa"
        SessionFg    = "#1e1e2e"
        PathBg       = "#a6e3a1"
        PathFg       = "#1e1e2e"
        GitBg        = "#89b4fa"
        GitFg        = "#1e1e2e"
        TimeBg       = "#f38ba8"
        TimeFg       = "#1e1e2e"
        Accent       = "#b4befe"
        Surface      = "#313244"
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
            Foreground     = "#1e1e2e"
            Background     = "#89b4fa"
            Style          = "powerline"
            LeadingDiamond = ""
            TrailingDiamond= ""
        }
        Path = @{
            Visible        = $true
            Icon           = ""
            Foreground     = "#1e1e2e"
            Background     = "#a6e3a1"
            Style          = "powerline"
            PathStyle      = "folder"
            LeadingDiamond = ""
            TrailingDiamond= ""
        }
        Git = @{
            Visible        = $true
            Icon           = ""
            Foreground     = "#1e1e2e"
            Background     = "#89b4fa"
            Style          = "powerline"
            IconClean      = ""
            IconDirty      = ""
            LeadingDiamond = ""
            TrailingDiamond= ""
        }
        Time = @{
            Visible        = $true
            Icon           = ([string][char]0xF017)
            Foreground     = "#1e1e2e"
            Background     = "#f38ba8"
            Style          = "powerline"
            Template       = "{{ .Time }}"
            LeadingDiamond = ""
            TrailingDiamond= ""
        }
        Project = @{
            Visible        = $false
            Icon           = ""
            Foreground     = "#cdd6f4"
            Background     = "#313244"
            Style          = "plain"
        }
    }
