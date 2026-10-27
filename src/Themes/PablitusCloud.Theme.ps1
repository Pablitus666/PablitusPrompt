# ============================================================
# Pablitus Prompt Framework (PPF)
# Tema oficial: Pablitus Cloud
#
# Inspirado en el tema cloud de Oh My Posh.
# Paleta blanca y gris clara, ideal para terminales con fondo claro.
# ============================================================

Register-PromptTheme `
    -Name "Pablitus Cloud" `
    -Palette @{
        Background   = "#f8fafc"
        Foreground   = "#1e293b"
        Primary      = "#0ea5e9"
        Secondary    = "#64748b"
        Success      = "#22c55e"
        Warning      = "#f59e0b"
        Error        = "#ef4444"
        SessionBg    = "#0ea5e9"
        SessionFg    = "#f8fafc"
        PathBg       = "#cbd5e1"
        PathFg       = "#1e293b"
        GitBg        = "#f43f5e"
        GitFg        = "#f8fafc"
        TimeBg       = "#22c55e"
        TimeFg       = "#002b36"
        Accent       = "#d97706"
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
            Background     = "#0ea5e9"
            Style          = "powerline"
            LeadingDiamond = ""
            TrailingDiamond= ""
        }
        Path = @{
            Visible        = $true
            Icon           = ""
            Foreground     = "#1e293b"
            Background     = "#cbd5e1"
            Style          = "powerline"
            PathStyle      = "folder"
            LeadingDiamond = ""
            TrailingDiamond= ""
        }
        Git = @{
            Visible        = $true
            Icon           = ""
            Foreground     = "#f8fafc"
            Background     = "#f43f5e"
            Style          = "powerline"
            IconClean      = ""
            IconDirty      = ""
            LeadingDiamond = ""
            TrailingDiamond= ""
        }
        Time = @{
            Visible        = $true
            Icon           = ([string][char]0xF017)
            Foreground     = "#002b36"
            Background     = "#22c55e"
            Style          = "powerline"
            Template       = "{{ .Time }}"
            LeadingDiamond = ""
            TrailingDiamond= ""
        }
        Project = @{
            Visible        = $false
            Icon           = ""
            Foreground     = "#839496"
            Background     = "#f1f5f9"
            Style          = "plain"
        }
    }
