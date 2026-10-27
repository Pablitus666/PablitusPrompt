# ============================================================
# Pablitus Prompt Framework (PPF)
# Tema adicional: Tokyo Night
#
# Tema oscuro inspirado en Tokio Night. Distribuido en el paquete
# PablitusPrompt.Themes de PowerShell Gallery.
# ============================================================

Register-PromptTheme `
    -Name "TokyoNight" `
    -Palette @{
        Background = "#1a1b26"
        Foreground = "#a9b1d6"
        Primary    = "#7aa2f7"
        Secondary  = "#bb9af7"
        Success    = "#9ece6a"
        Warning    = "#e0af68"
        Error      = "#f7768e"
        Surface    = "#24283b"
    } `
    -Icons @{
        Session     = "🌃"
        Project     = "📁"
        Path        = ""
        GitClean    = ""
        GitDirty    = ""
        Python      = ""
        Node        = ""
        PromptSymbol = "›"
    } `
    -Segments @{
        Session = @{
            Visible    = $true
            Icon       = "🌃"
            Foreground = "Primary"
        }
        Project = @{
            Visible    = $true
            Icon       = "📁"
            Foreground = "Success"
        }
        Path = @{
            Visible    = $true
            Icon       = ""
            Foreground = "Secondary"
        }
        Git = @{
            Visible    = $true
            Icon       = ""
            Foreground = "Primary"
        }
        Python = @{
            Visible    = $true
            Icon       = ""
            Foreground = "Success"
        }
        Node = @{
            Visible    = $true
            Icon       = ""
            Foreground = "Primary"
        }
    }
