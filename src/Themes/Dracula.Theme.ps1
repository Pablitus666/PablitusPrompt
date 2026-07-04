# ============================================================
# Pablitus Prompt Framework (PPF)
# Dracula.Theme.ps1
# ============================================================

Register-PromptTheme `
    -Name "Dracula" `
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
            Foreground = "Green"
        }
        "Project" = @{
            Visible    = $true
            Icon       = ""
            Foreground = "Green"
        }
        "Path" = @{
            Visible    = $true
            Icon       = ""
            Foreground = "Cyan"
        }
        "Git" = @{
            Visible    = $true
            Icon       = ""
            IconClean  = ""
            IconDirty  = ""
            Foreground = "Magenta"
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
