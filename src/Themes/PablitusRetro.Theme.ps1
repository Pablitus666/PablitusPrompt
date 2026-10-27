# ============================================================
# Pablitus Prompt Framework (PPF)
# Tema oficial: Pablitus Retro
#
# Diseño inspirado en los años 80 con colores brillantes y neón.
# Estilo retro para usuarios que aman lo clásico.
# ============================================================

Register-PromptTheme `
    -Name "Pablitus Retro" `
    -Palette @{
        Background   = "#000000"
        Foreground   = "#00ffff"
        Primary      = "#ff00ff"
        Secondary    = "#ffff00"
        Success      = "#00ff00"
        Warning      = "#ffaa00"
        Error        = "#ff0000"
        SessionBg    = "#ff00ff"
        SessionFg    = "#000000"
        PathBg       = "#00ffff"
        PathFg       = "#000000"
        GitBg        = "#ffff00"
        GitFg        = "#000000"
        TimeBg       = "#ff0000"
        TimeFg       = "#000000"
        Accent       = "#ff00ff"
        Surface      = "#1a1a1a"
    } `
    -Icons @{
        Session      = ""
        Path         = ""
        GitClean     = ""
        GitDirty     = ""
        Time         = [string][char]0xF017
        Project      = ""
        PromptSymbol = "▶"
    } `
    -Segments @{
        Session = @{
            Visible        = $true
            Icon           = ""
            Foreground     = "#000000"
            Background     = "#ff00ff"
            Style          = "plain"
        }
        Path = @{
            Visible        = $true
            Icon           = ""
            Foreground     = "#000000"
            Background     = "#00ffff"
            Style          = "plain"
            PathStyle      = "folder"
        }
        Git = @{
            Visible        = $true
            Icon           = ""
            Foreground     = "#000000"
            Background     = "#ffff00"
            Style          = "plain"
            IconClean      = ""
            IconDirty      = ""
        }
        Time = @{
            Visible        = $true
            Icon           = ([string][char]0xF017)
            Foreground     = "#000000"
            Background     = "#ff0000"
            Style          = "plain"
            Template       = "{{ .Time }}"
        }
        Project = @{
            Visible        = $false
            Icon           = ""
            Foreground     = "#ffff00"
            Background     = "#1a1a1a"
            Style          = "plain"
        }
    }
