# ============================================================
# Pablitus Prompt Framework (PPF)
# Tema oficial: Pablitus Stack
#
# DISEÑO COMPLETAMENTE DIFERENTE: Apila segmentos verticalmente
# en lugar de horizontalmente. Cada segmento ocupa su propia línea.
# Ideal para pantallas anchas o cuando quieres ver mucha información
# de una vez sin que se amontone.
# ============================================================

Register-PromptTheme `
    -Name "Pablitus Stack" `
    -Palette @{
        Background   = "#0a0a0a"
        Foreground   = "#e0e0e0"
        Primary      = "#bb86fc"
        Secondary    = "#03dac6"
        Success      = "#03dac6"
        Warning      = "#cf6679"
        Error        = "#cf6679"
        Accent       = "#03dac6"
        Surface      = "#12121a"
    } `
    -Icons @{
        Session      = ""
        Path         = ""
        GitClean     = ""
        GitDirty     = ""
        Time         = ""
        Project      = ""
        PromptSymbol = "➜"
    } `
    -Segments @{
        Session = @{
            Visible        = $true
            Icon           = ""
            Foreground     = "#0f0c29"
            Background     = "#bb86fc"
            Style          = "plain"
            Template       = "{{ .UserName }}@{{ .HostName }}"
        }
        Path = @{
            Visible        = $true
            Icon           = ""
            Foreground     = "#e0e0e0"
            Background     = "#1e293b"
            Style          = "plain"
            Template       = "{{ .Path.Display }}"
        }
        Git = @{
            Visible        = $true
            Icon           = ""
            Foreground     = "#0f0c29"
            Background     = "#03dac6"
            Style          = "plain"
            Template       = "{{ if .Git.Branch }}[{{ .Git.Branch }}]{{ end }}"
        }
        Time = @{
            Visible        = $true
            Icon           = ([string][char]0xF017)
            Foreground     = "#0f0c29"
            Background     = "#cf6679"
            Style          = "plain"
            Template       = "{{ .Time }}"
        }
        Project = @{
            Visible        = $false
            Icon           = ""
            Foreground     = "#e0e0e0"
            Background     = "#1a173a"
            Style          = "plain"
        }
        PromptSymbol = @{
            Visible        = $true
            Icon           = "➜"
            Foreground     = "#bb86fc"
            Background     = "#0f0c29"
            Style          = "plain"
            Template       = "➜"
        }
    }
