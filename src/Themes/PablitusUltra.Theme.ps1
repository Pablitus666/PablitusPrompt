# ============================================================
# Pablitus Prompt Framework (PPF)
# Tema oficial: Pablitus Ultra
#
# EL MÁS COMPLETO: Muestra TODO en una línea.
# Usuario, Host, Path, Git, Time, Docker, Kubernetes - TODO junto.
# ============================================================

Register-PromptTheme `
    -Name "Pablitus Ultra" `
    -Palette @{
        Background   = "#0a0a0a"
        Foreground   = "#ffffff"
        Primary      = "#ff00ff"
        Secondary    = "#00ffff"
        Success      = "#00ff00"
        Warning      = "#ffff00"
        Error        = "#ff0000"
        SessionBg    = "#ff00ff"
        SessionFg    = "#000000"
        PathBg       = "#00ffff"
        PathFg       = "#000000"
        GitBg        = "#ffff00"
        GitFg        = "#000000"
        TimeBg       = "#ff0000"
        TimeFg       = "#000000"
        Accent       = "#ff009f"
        Surface      = "#12121a"
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
        PromptSymbol = "⚡"
    } `
    -Segments @{
        Session = @{
            Visible        = $true
            Icon           = ""
            Foreground     = "#000000"
            Background     = "#ff00ff"
            Style          = "powerline"
            LeadingDiamond = ""
            TrailingDiamond= ""
        }
        Path = @{
            Visible        = $true
            Icon           = ""
            Foreground     = "#000000"
            Background     = "#00ffff"
            Style          = "powerline"
            PathStyle      = "folder"
            LeadingDiamond = ""
            TrailingDiamond= ""
        }
        Git = @{
            Visible        = $true
            Icon           = ""
            Foreground     = "#000000"
            Background     = "#ffff00"
            Style          = "powerline"
            IconClean      = ""
            IconDirty      = ""
            LeadingDiamond = ""
            TrailingDiamond= ""
        }
        Docker = @{
            Visible        = $true
            Icon           = ""
            Foreground     = "#000000"
            Background     = "#00ffff"
            Style          = "plain"
            Template       = "docker"
        }
        Kubernetes = @{
            Visible        = $true
            Icon           = ""
            Foreground     = "#000000"
            Background     = "#326ce5"
            Style          = "plain"
            Template       = "k8s"
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
            Foreground     = "#00ffff"
            Background     = "#12121a"
            Style          = "plain"
        }
        PromptSymbol = @{
            Visible        = $true
            Icon           = "⚡"
            Foreground     = "#ff00ff"
            Background     = "#0a0a0f"
            Style          = "plain"
            Template       = "⚡"
        }
    }
