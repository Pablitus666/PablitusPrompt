# ============================================================
# Pablitus Prompt Framework (PPF)
# Tema adicional: Moonlight
#
# Tema oscuro con tonos azules noche y superficie profunda.
# Distribuido en el paquete PablitusPrompt.Themes de PowerShell Gallery.
# ============================================================

Register-PromptTheme `
    -Name "Moonlight" `
    -Palette @{
        Background  = "#0b0c10"
        Foreground  = "#c8d6e5"
        Primary     = "#70a5e0"
        Secondary   = "#a3b8cc"
        Success     = "#7fdbca"
        Warning     = "#ffd166"
        Error       = "#ef476f"
        Surface     = "#121620"
    } `
    -Icons @{
        Session     = "🌙"
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
            Icon       = "🌙"
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
