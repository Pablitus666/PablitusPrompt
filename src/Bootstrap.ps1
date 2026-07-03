# ============================================================
# Pablitus Prompt Framework (PPF)
# Bootstrap.ps1
# ============================================================

$Root = Split-Path -Parent $MyInvocation.MyCommand.Path

# ------------------------------------------------------------
# Core
# ------------------------------------------------------------

Get-ChildItem "$Root\Core\*.ps1" |
Sort-Object Name |
ForEach-Object {
    . $_.FullName
}

# ------------------------------------------------------------
# Configuration
# ------------------------------------------------------------

Get-ChildItem "$Root\Configuration\*.ps1" |
Sort-Object Name |
ForEach-Object {
    . $_.FullName
}

# ------------------------------------------------------------
# Utils
# ------------------------------------------------------------

Get-ChildItem "$Root\Utils\*.ps1" |
Sort-Object Name |
ForEach-Object {
    . $_.FullName
}

# ------------------------------------------------------------
# Services
# ------------------------------------------------------------

Get-ChildItem "$Root\Services\*\*.ps1" |
Sort-Object FullName |
ForEach-Object {
    . $_.FullName
}

# ------------------------------------------------------------
# Providers
# ------------------------------------------------------------

Get-ChildItem "$Root\Providers\*\*.ps1" |
Sort-Object FullName |
ForEach-Object {
    . $_.FullName
}

# ------------------------------------------------------------
# Segment Registry
# ------------------------------------------------------------

Get-ChildItem "$Root\Segments\*.ps1" |
Sort-Object Name |
ForEach-Object {
    . $_.FullName
}

# ------------------------------------------------------------
# Segments
# ------------------------------------------------------------

Get-ChildItem "$Root\Segments\*\*.ps1" |
Sort-Object FullName |
ForEach-Object {
    . $_.FullName
}

# ------------------------------------------------------------
# Renderers
# ------------------------------------------------------------

Get-ChildItem "$Root\Renderers\*\*.ps1" |
Sort-Object FullName |
ForEach-Object {
    . $_.FullName
}