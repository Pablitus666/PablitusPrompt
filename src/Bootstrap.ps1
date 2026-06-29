# ============================================================
# Pablitus Prompt Framework (PPF)
# Bootstrap.ps1
# ============================================================

# ------------------------------------------------------------
# Core
# ------------------------------------------------------------

Get-ChildItem "$PSScriptRoot\Core\*.ps1" |
    Sort-Object Name |
    ForEach-Object {
        . $_.FullName
    }

# ------------------------------------------------------------
# Utils
# ------------------------------------------------------------

Get-ChildItem "$PSScriptRoot\Utils\*.ps1" |
    Sort-Object Name |
    ForEach-Object {
        . $_.FullName
    }

# ------------------------------------------------------------
# Providers
# ------------------------------------------------------------

Get-ChildItem "$PSScriptRoot\Providers" -Directory |
    Sort-Object Name |
    ForEach-Object {

        Get-ChildItem $_.FullName -Filter "*.ps1" |
            Sort-Object Name |
            ForEach-Object {
                . $_.FullName
            }

    }

# ------------------------------------------------------------
# Renderers
# ------------------------------------------------------------

Get-ChildItem "$PSScriptRoot\Renderers" -Directory -ErrorAction SilentlyContinue |
    Sort-Object Name |
    ForEach-Object {

        Get-ChildItem $_.FullName -Filter "*.ps1" |
            Sort-Object Name |
            ForEach-Object {
                . $_.FullName
            }

    }