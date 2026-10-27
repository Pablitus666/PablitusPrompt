# ============================================================
# Pablitus Prompt Framework (PPF)
# Tema oficial: Pablitus GitOnly
#
# Solo muestra la rama de Git y el símbolo del prompt.
# Ideal para desarrolladores que solo necesitan saber en qué rama están.
# ============================================================

Register-PromptTheme `
    -Name "Pablitus GitOnly" `
    -Palette @{
        Background   = "#1a1a1a"
        Foreground   = "#c0c0c0"
        Primary      = "#00ff00"
        Secondary    = "#666666"
        Success      = "#00ff00"
        Warning      = "#ffff00"
        Error        = "#ff4444"
        SessionBg    = "#0066cc"
        SessionFg    = "#1a1a1a"
        PathBg       = "#333333"
        PathFg       = "#00ff00"
        GitBg        = "#ffaa00"
        GitFg        = "#1a1a1a"
        TimeBg       = "#666666"
        TimeFg       = "#1a1a1a"
        Accent       = "#888888"
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
            Visible        = $false
            Icon           = ""
            Foreground     = "#1a1a1a"
            Background     = "#0066cc"
            Style          = "plain"
        }
        Path = @{
            Visible        = $false
            Icon           = ""
            Foreground     = "#c0c0c0"
            Background     = "#333333"
            Style          = "plain"
        }
        Git = @{
            Visible        = $true
            Icon           = ""
            Foreground     = "#1a1a1a"
            Background     = "#ffaa00"
            Style          = "plain"
            IconClean      = ""
            IconDirty      = ""
        }
        Time = @{
            Visible        = $false
            Icon           = ([string][char]0xF017)
            Foreground     = "#1a1a1a"
            Background     = "#666666"
            Style          = "plain"
        }
        Project = @{
            Visible        = $false
            Icon           = ""
            Foreground     = "#c0c0c0"
            Background     = "#2a2a2a"
            Style          = "plain"
        }
        PromptSymbol = @{
            Visible        = $true
            Icon           = "➜"
            Foreground     = "#00ff00"
            Background     = "#1a1a1a"
            Style          = "plain"
            Template       = "➜"
        }
    }
