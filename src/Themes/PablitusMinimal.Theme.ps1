# ============================================================
# Pablitus Prompt Framework (PPF)
# Tema oficial: Pablitus Minimal
#
# Diseño minimalista: solo lo esencial.
# Ideal para usuarios que quieren un prompt limpio sin distracciones.
# ============================================================

Register-PromptTheme `
    -Name "Pablitus Minimal" `
    -Palette @{
        Background   = "#1a1a1a"
        Foreground   = "#e0e0e0"
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
        PromptSymbol = "➜"
    } `
    -Segments @{
        Path = @{
            Visible        = $true
            Icon           = ""
            Foreground     = "#00ff00"
            Background     = "#1a1a1a"
            Style          = "plain"
            Template       = "{{ .Path.Display }}"
        }
        Git = @{
            Visible        = $true
            Icon           = ""
            Foreground     = "#1a1a1a"
            Background     = "#ffaa00"
            Style          = "plain"
            Template       = "{{ if .Git.Branch }}[{{ .Git.Branch }}]{{ end }}"
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
