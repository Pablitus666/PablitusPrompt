# ============================================================
# Pablitus Prompt Framework (PPF)
# Tema oficial: Pablitus Micro
#
# El tema más mínimo posible: solo el símbolo del prompt.
# Sin path, sin git, sin tiempo, sin nada más.
# Ideal para usuarios que quieren un prompt completamente limpio.
# ============================================================

Register-PromptTheme `
    -Name "Pablitus Micro" `
    -Palette @{
        Background   = "#1a1a1a"
        Foreground   = "#c0c0c0"
        Primary      = "#00ff00"
        Secondary    = "#666666"
        Success      = "#00ff00"
        Warning      = "#ffff00"
        Error        = "#ff4444"
        Accent       = "#888888"
        Surface      = "#2a2a2a"
    } `
    -Icons @{
        PromptSymbol = "➜"
    } `
    -Segments @{
        PromptSymbol = @{
            Visible        = $true
            Icon           = "➜"
            Foreground     = "#00ff00"
            Background     = "#1a1a1a"
            Style          = "plain"
            Template       = "➜"
        }
    }
