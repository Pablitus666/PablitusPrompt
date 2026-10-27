# ============================================================
# Pablitus Prompt Framework (PPF)
# Tema oficial: Pablitus Neon Noir
#
# Diseño cyberpunk con colores neón sobre fondo negro profundo.
# Ideal para entornos oscuros con alto contraste.
# ============================================================

Register-PromptTheme `
    -Name "Pablitus Neon Noir" `
    -Palette @{
        Background   = "#0a0a0f"
        Foreground   = "#ff00ff"
        Primary      = "#00ffff"
        Secondary    = "#ffff00"
        Success      = "#00ff9f"
        Warning      = "#ffd700"
        Error        = "#ff0040"
        SessionBg    = "#ff00ff"
        SessionFg    = "#0a0a0f"
        PathBg       = "#00ffff"
        PathFg       = "#0a0a0f"
        GitBg        = "#ffff00"
        GitFg        = "#0a0a0f"
        TimeBg       = "#ff0040"
        TimeFg       = "#f8fafc"
        Accent       = "#8b00ff"
        Surface      = "#12121a"
    } `
    -Icons @{
        Session      = ""
        Path         = ""
        GitClean     = ""
        GitDirty     = ""
        Time         = [string][char]0xF017
        Project      = ""
        PromptSymbol = "⚡"
    } `
    -Segments @{
        Session = @{
            Visible        = $true
            Icon           = ""
            Foreground     = "#0a0a0f"
            Background     = "#ff00ff"
            Style          = "plain"
            LeadingDiamond = ""
            TrailingDiamond= ""
        }
        Path = @{
            Visible        = $true
            Icon           = ""
            Foreground     = "#0a0a0f"
            Background     = "#00ffff"
            Style          = "powerline"
            PathStyle      = "folder"
            LeadingDiamond = ""
            TrailingDiamond= ""
        }
        Git = @{
            Visible        = $true
            Icon           = ""
            Foreground     = "#0a0a0f"
            Background     = "#ffff00"
            Style          = "plain"
            IconClean      = ""
            IconDirty      = ""
        }
        Time = @{
            Visible        = $true
            Icon           = ([string][char]0xF017)
            Foreground     = "#0a0a0f"
            Background     = "#ff0040"
            Style          = "plain"
            Template       = "{{ .Time }}"
        }
        Project = @{
            Visible        = $false
            Icon           = ""
            Foreground     = "#ffff00"
            Background     = "#12121a"
            Style          = "plain"
        }
    }
