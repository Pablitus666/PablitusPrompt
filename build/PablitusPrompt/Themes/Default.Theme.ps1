# ============================================================
# Pablitus Prompt Framework (PPF)
# Default.Theme.ps1
# ============================================================

Register-PromptTheme `
    -Name "Default" `
    -Palette @{
        "Background" = "Black"
        "Foreground" = "White"
        "Primary"    = "Cyan"
        "Secondary"  = "Blue"
        "Success"    = "Green"
        "Warning"    = "Yellow"
        "Error"      = "Red"
    } `
    -Icons @{
        "Session"  = ""
        "Project"  = "📁"
        "Path"     = ""
        "GitClean" = ""
        "GitDirty" = ""
        "Python"   = ""
        "Node"     = ""
    } `
    -Segments @{
        "Session" = @{
            Visible    = $true
            Icon       = ""
            Foreground = "Cyan"
        }
        "Project" = @{
            Visible    = $true
            Icon       = "📁"
            Foreground = "Green"
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
            IconDirty  = ""
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
