# ============================================================
# Pablitus Prompt Framework (PPF)
# Kali.Theme.ps1
# ============================================================

# Reuse the Nerd Font glyphs registered by the Default theme. Keeping the
# glyphs in one place makes this file ASCII-only and avoids encoding issues.
$kaliIcons = (Get-PromptTheme -Name "Default").Icons
if (-not $kaliIcons) {
    $kaliIcons = @{}
}

Register-PromptTheme `
    -Name "Kali" `
    -Palette @{
        "Background" = "Black"
        "Foreground" = "White"
        "Primary"    = "Green"
        "Secondary"  = "Cyan"
        "Success"    = "Green"
        "Warning"    = "Yellow"
        "Error"      = "Red"
    } `
    -Icons $kaliIcons `
    -Segments @{
        "Session" = @{
            Visible    = $true
            Icon       = "Session"
            Foreground = "Green"
            ShowHost   = $true
        }
        "Path" = @{
            Visible    = $true
            Icon       = "Path"
            Foreground = "Cyan"
        }
        "Git" = @{
            Visible    = $true
            IconClean  = "GitClean"
            IconDirty  = "GitDirty"
            Foreground = "Yellow"
        }
        "Python" = @{
            Visible    = $true
            Icon       = "Python"
            Foreground = "Yellow"
        }
        "Project"    = @{ Visible = $false }
        "Node"       = @{ Visible = $false }
        "Memory"     = @{ Visible = $false }
        "CPU"        = @{ Visible = $false }
        "Battery"    = @{ Visible = $false }
        "Docker"     = @{ Visible = $false }
        "Kubernetes" = @{ Visible = $false }
        "DotNet"     = @{ Visible = $false }
        "WSL"        = @{ Visible = $false }
    }
