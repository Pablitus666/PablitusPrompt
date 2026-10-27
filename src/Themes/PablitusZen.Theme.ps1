# ============================================================
# Pablitus Prompt Framework (PPF)
# Tema oficial: Pablitus Zen
#
# Diseño zen: minimalista, tranquilo, pocos segmentos.
# Ideal para usuarios que prefieren un prompt sutil y relajante.
# ============================================================

Register-PromptTheme `
    -Name "Pablitus Zen" `
    -Palette @{
        Background   = "#1a1a1a"
        Foreground   = "#b0b0b0"
        Primary      = "#777777"
        Secondary    = "#444444"
        Success      = "#448844"
        Warning      = "#aaaa00"
        Error        = "#aa4444"
        SessionBg    = "#777777"
        SessionFg    = "#1a1a1a"
        PathBg       = "#333333"
        PathFg       = "#777777"
        GitBg        = "#448844"
        GitFg        = "#1a1a1a"
        TimeBg       = "#666666"
        TimeFg       = "#1a1a1a"
        Accent       = "#777777"
        Surface      = "#2a2a2a"
    } `
    -Icons @{
        Session      = ""
        Path         = ""
        GitClean     = ""
        GitDirty     = ""
        Time         = [string][char]0xF017
        Project      = ""
        PromptSymbol = "›"
    } `
    -Segments @{
        Path = @{
            Visible        = $true
            Icon           = ""
            Foreground     = "#777777"
            Background     = "#1a1a1a"
            Style          = "plain"
            Template       = "{{ .Path.Display }}"
        }
        PromptSymbol = @{
            Visible        = $true
            Icon           = "›"
            Foreground     = "#777777"
            Background     = "#1a1a1a"
            Style          = "plain"
            Template       = "›"
        }
    }
