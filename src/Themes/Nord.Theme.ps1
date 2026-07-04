# ============================================================
# Pablitus Prompt Framework (PPF)
# Nord.Theme.ps1
# ============================================================

Register-PromptTheme `
    -Name "Nord" `
    -Palette @{
        "Background" = "Black"
        "Foreground" = "White"
        "Primary"    = "Blue"
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
        "GitDirty" = ""
        "Python"   = ""
        "Node"     = ""
    } `
    -Segments @{
        "Session" = @{
            Visible    = $true
            Icon       = ""
            Foreground = "Blue"
        }
        "Project" = @{
            Visible    = $true
            Icon       = ""
            Foreground = "Cyan"
        }
        "Path" = @{
            Visible    = $true
            Icon       = ""
            Foreground = "Blue"
        }
        "Git" = @{
            Visible    = $true
            Icon       = ""
            IconClean  = ""
            IconDirty  = ""
            Foreground = "Cyan"
        }
        "Python" = @{
            Visible    = $true
            Icon       = ""
            Foreground = "Blue"
        }
        "Node" = @{
            Visible    = $true
            Icon       = ""
            Foreground = "Cyan"
        }
    }
