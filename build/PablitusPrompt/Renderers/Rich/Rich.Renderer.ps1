# ============================================================
# Pablitus Prompt Framework (PPF)
# Rich.Renderer.ps1
# ============================================================

Register-PromptRenderer `
    -Name "Rich" `
    -Script {

    param(
        [PromptContext]$Context
    )

    $ansiColors = @{
        "Black"   = "`e[30;1m"
        "Red"     = "`e[31;1m"
        "Green"   = "`e[32;1m"
        "Yellow"  = "`e[33;1m"
        "Blue"    = "`e[34;1m"
        "Magenta" = "`e[35;1m"
        "Cyan"    = "`e[36;1m"
        "White"   = "`e[37;1m"
        "Reset"   = "`e[0m"
    }

    $parts = foreach ($segment in $Context.Segments) {

        if (-not $segment.Visible) {
            continue
        }

        $fgCode = if ($segment.Foreground -and $ansiColors.ContainsKey($segment.Foreground)) {
            $ansiColors[$segment.Foreground]
        }
        else {
            ""
        }

        $text = if ($segment.Icon) {
            "$($segment.Icon) $($segment.Text)"
        }
        else {
            $segment.Text
        }

        if ($fgCode) {
            "[$fgCode$text$($ansiColors['Reset'])]"
        }
        else {
            "[$text]"
        }

    }

    return ($parts -join " ") + " `e[32m➔`e[0m "

}
