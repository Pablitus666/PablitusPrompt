# ============================================================
# Pablitus Prompt Framework (PPF)
# Tema oficial: Pablitus DevOps
#
# Diseñado para desarrolladores de DevOps con énfasis en
# Docker, Kubernetes y Git. Segmentos técnicos prominentes.
# ============================================================

Register-PromptTheme `
    -Name "Pablitus DevOps" `
    -Palette @{
        Background   = "#0f172a"
        Foreground   = "#f8fafc"
        Primary      = "#3b82f6"
        Secondary    = "#64748b"
        Success      = "#22c55e"
        Warning      = "#f59e0b"
        Error        = "#ef4444"
        SessionBg    = "#3b82f6"
        SessionFg    = "#0f172a"
        PathBg       = "#1e293b"
        PathFg       = "#cbd5e1"
        GitBg        = "#ef4444"
        GitFg        = "#f8fafc"
        TimeBg       = "#10b981"
        TimeFg       = "#0f172a"
        Accent       = "#f59e0b"
        Surface      = "#1e293b"
    } `
    -Icons @{
        Session      = ""
        Path         = ""
        GitClean     = ""
        GitDirty     = ""
        Time         = [string][char]0xF017
        Project      = ""
        Docker       = ""
        Kubernetes   = ""
        PromptSymbol = ""
    } `
    -Segments @{
        Session = @{
            Visible        = $true
            Icon           = ""
            Foreground     = "#0f172a"
            Background     = "#3b82f6"
            Style          = "powerline"
            LeadingDiamond = ""
            TrailingDiamond= ""
        }
        Path = @{
            Visible        = $true
            Icon           = ""
            Foreground     = "#f8fafc"
            Background     = "#1e293b"
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
        Docker = @{
            Visible        = $true
            Icon           = ""
            Foreground     = "#0f172a"
            Background     = "#0db9d7"
            Style          = "plain"
            Template       = "docker"
        }
        Kubernetes = @{
            Visible        = $true
            Icon           = ""
            Foreground     = "#0f172a"
            Background     = "#326ce5"
            Style          = "plain"
            Template       = "k8s"
        }
        Time = @{
            Visible        = $true
            Icon           = ([string][char]0xF017)
            Foreground     = "#0f172a"
            Background     = "#10b981"
            Style          = "plain"
            Template       = "{{ .Time }}"
        }
    }
