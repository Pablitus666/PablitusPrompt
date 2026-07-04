# ============================================================
# Pablitus Prompt Framework (PPF)
# Catppuccin.Theme.ps1
# ============================================================

Register-PromptTheme `
    -Name "Catppuccin" `
    -Palette @{
        "Background" = "Black"
        "Foreground" = "White"
        "Primary"    = "Magenta"
        "Secondary"  = "Cyan"
        "Success"    = "Green"
        "Warning"    = "Yellow"
        "Error"      = "Red"
    } `
    -Icons @{
        "Session"  = ""
        "Project"  = ""
        "Path"     = ""
        "GitClean" = ""
        "GitDirty" = ""
        "Python"   = ""
        "Node"     = ""
    } `
    -Segments @{
        "Session" = @{
            Visible    = $true
            Icon       = ""
            Foreground = "Magenta"
        }
        "Project" = @{
            Visible    = $true
            Icon       = ""
            Foreground = "Cyan"
        }
        "Path" = @{
            Visible    = $true
            Icon       = ""
            Foreground = "Magenta"
        }
        "Git" = @{
            Visible    = $true
            Icon       = ""
            IconClean  = ""
            IconDirty  = ""
            Foreground = "Yellow"
        }
        "Python" = @{
            Visible    = $true
            Icon       = ""
            Foreground = "Magenta"
        }
        "Node" = @{
            Visible    = $true
            Icon       = ""
            Foreground = "Green"
        }
    }
