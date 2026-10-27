# ============================================================
# Pablitus Prompt Framework (PPF)
# Tema oficial: Pablitus Lambda
#
# Inspirado en el tema lambda de Oh My Posh.
# Paleta minimalista con colores azul/gris claro.
# ============================================================

Register-PromptTheme `
    -Name "Pablitus Lambda" `
    -Palette @{
        Background   = "#f8fafc"
        Foreground   = "#1e293b"
        Primary      = "#3b82f6"
        Secondary    = "#94a3b8"
        Success      = "#22c55e"
        Warning      = "#f59e0b"
        Error        = "#ef4444"
        SessionBg    = "#3b82f6"
        SessionFg    = "#f8fafc"
        PathBg       = "#e2e8f0"
        PathFg       = "#1e293b"
        GitBg        = "#ef4444"
        GitFg        = "#f8fafc"
        TimeBg       = "#22c55e"
        TimeFg       = "#1e293b"
        Accent       = "#64748b"
        Surface      = "#f1f5f9"
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
            Foreground     = "#f8fafc"
            Background     = "#3b82f6"
            Style          = "powerline"
            LeadingDiamond = ""
            TrailingDiamond= ""
        }
        Path = @{
            Visible        = $true
            Icon           = ""
            Foreground     = "#1e293b"
            Background     = "#e2e8f0"
            Style          = "powerline"
            PathStyle      = "folder"
            LeadingDiamond = ""
            TrailingDiamond= ""
        }
        Git = @{
            Visible        = $true
            Icon           = ""
            Foreground     = "#f8fafc"
            Background     = "#ef4444"
            Style          = "powerline"
            IconClean      = ""
            IconDirty      = ""
            LeadingDiamond = ""
            TrailingDiamond= ""
        }
        Time = @{
            Visible        = $true
            Icon           = ([string][char]0xF017)
            Foreground     = "#1e293b"
            Background     = "#22c55e"
            Style          = "powerline"
            Template       = "{{ .Time }}"
            LeadingDiamond = ""
            TrailingDiamond= ""
        }
        Project = @{
            Visible        = $false
            Icon           = ""
            Foreground     = "#64748b"
            Background     = "#f1f5f9"
            Style          = "plain"
        }
    }
