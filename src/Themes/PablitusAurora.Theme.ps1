# ============================================================
# Pablitus Prompt Framework (PPF)
# Tema oficial: Pablitus Aurora
#
# Inspirado en el tema jandedobbeleer de Oh My Posh.
# Paleta de colores verde/azul aurora boreal.
# Ideal para desarrolladores que trabajan de noche con terminales oscuros.
# ============================================================

Register-PromptTheme `
    -Name "Pablitus Aurora" `
    -Palette @{
        Background   = "#0f172a"
        Foreground   = "#cbd5e1"
        Primary      = "#22d3ee"
        Secondary    = "#818cf8"
        Success      = "#4ade80"
        Warning      = "#fbbf24"
        Error        = "#f87171"
        SessionBg    = "#22d3ee"
        SessionFg    = "#0f172a"
        PathBg       = "#1e1e4e"
        PathFg       = "#cbd5e1"
        GitBg        = "#818cf8"
        GitFg        = "#0f172a"
        TimeBg       = "#4ade80"
        TimeFg       = "#0f172a"
        Accent       = "#c084fc"
        Surface      = "#1e293b"
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
            Foreground     = "#0f172a"
            Background     = "#22d3ee"
            Style          = "powerline"
            LeadingDiamond = ""
            TrailingDiamond= ""
        }
        Path = @{
            Visible        = $true
            Icon           = ""
            Foreground     = "#cbd5e1"
            Background     = "#1e1e4e"
            Style          = "powerline"
            PathStyle      = "folder"
            LeadingDiamond = ""
            TrailingDiamond= ""
        }
        Git = @{
            Visible        = $true
            Icon           = ""
            Foreground     = "#0f172a"
            Background     = "#818cf8"
            Style          = "powerline"
            IconClean      = ""
            IconDirty      = ""
            LeadingDiamond = ""
            TrailingDiamond= ""
        }
        Time = @{
            Visible        = $true
            Icon           = ([string][char]0xF017)
            Foreground     = "#0f172a"
            Background     = "#4ade80"
            Style          = "powerline"
            Template       = "{{ .Time }}"
            LeadingDiamond = ""
            TrailingDiamond= ""
        }
        Project = @{
            Visible        = $false
            Icon           = ""
            Foreground     = "#cbd5e1"
            Background     = "#1e293b"
            Style          = "plain"
        }
    }
