# ============================================================
# Pablitus Prompt Framework (PPF)
# Default.Configuration.ps1
# ============================================================

$script:PromptConfiguration = [PromptConfiguration]::new()

# ------------------------------------------------------------
# Session
# ------------------------------------------------------------

$script:PromptConfiguration.Segments["Session"] = @{

    Visible = $true

    Icon = ""

    Foreground = "Cyan"

}

# ------------------------------------------------------------
# Project
# ------------------------------------------------------------

$script:PromptConfiguration.Segments["Project"] = @{

    Visible = $true

    Icon = ""

    Foreground = "Green"

}

# ------------------------------------------------------------
# Path
# ------------------------------------------------------------

$script:PromptConfiguration.Segments["Path"] = @{

    Visible = $true

    Icon = ""

    Foreground = "Blue"

}

# ------------------------------------------------------------
# Git
# ------------------------------------------------------------

$script:PromptConfiguration.Segments["Git"] = @{

    Visible = $true

    IconClean = ""

    IconDirty = ""

    Foreground = "Yellow"

}

# ------------------------------------------------------------
# Python
# ------------------------------------------------------------

$script:PromptConfiguration.Segments["Python"] = @{

    Visible = $true

    Icon = ""

    Foreground = "Magenta"

}

# ------------------------------------------------------------
# Node
# ------------------------------------------------------------

$script:PromptConfiguration.Segments["Node"] = @{

    Visible = $true

    Icon = ""

    Foreground = "Green"

}

# ------------------------------------------------------------
# Renderer
# ------------------------------------------------------------

$script:PromptConfiguration.Renderer["Default"] = "Plain"

# ------------------------------------------------------------
# Theme
# ------------------------------------------------------------

$script:PromptConfiguration.Theme["Name"] = "Default"