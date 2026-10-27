# ============================================================
# Pablitus Prompt Framework (PPF)
# Tema adicional: Solarized (Dark)
#
# Esquema de colores Solarized Dark. Distribuido en el paquete
# PablitusPrompt.Themes de PowerShell Gallery.
# ============================================================

Register-PromptTheme `
    -Name "Solarized" `
    -Palette @{
        Background = "#002b36"
        Foreground = "#839496"
        Primary    = "#268bd2"
        Secondary  = "#2aa198"
        Success    = "#859900"
        Warning    = "#b58900"
        Error      = "#dc322f"
        Surface    = "#073642"
    } `
    -Icons @{
        Session     = "☉"
        Project     = "📁"
        Path        = ""
        GitClean    = ""
        GitDirty    = ""
        Python      = ""
        Node        = ""
        PromptSymbol = "➜"
    } `
    -Segments @{
        Session = @{
            Visible    = $true
            Icon       = "☉"
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
