# ============================================================
# Pablitus Prompt Framework (PPF)
# ANSI.Renderer.ps1
# ============================================================

Register-PromptRenderer `
    -Name "ANSI" `
    -Script {

    param(
        [PromptContext]$Context
    )

    $ansiColors = @{
        "Black"   = "`e[30m"
        "Red"     = "`e[31m"
        "Green"   = "`e[32m"
        "Yellow"  = "`e[33m"
        "Blue"    = "`e[34m"
        "Magenta" = "`e[35m"
        "Cyan"    = "`e[36m"
        "White"   = "`e[37m"
        "Reset"   = "`e[0m"
    }

    $ansiBg = @{
        "Black"   = "`e[40m"
        "Red"     = "`e[41m"
        "Green"   = "`e[42m"
        "Yellow"  = "`e[43m"
        "Blue"    = "`e[44m"
        "Magenta" = "`e[45m"
        "Cyan"    = "`e[46m"
        "White"   = "`e[47m"
    }

    $parts = foreach ($segment in $Context.Segments) {

        if (-not $segment.Visible) {
            continue
        }

        $fgCode = if ($segment.Foreground -and $ansiColors.ContainsKey($segment.Foreground)) {
            $ansiColors[$segment.Foreground]
        } else {
            ""
        }

        $bgCode = if ($segment.Background -and $ansiBg.ContainsKey($segment.Background)) {
            $ansiBg[$segment.Background]
        } else {
            ""
        }

        $text = if ($segment.Icon) {
            "$($segment.Icon) $($segment.Text)"
        } else {
            $segment.Text
        }

        if ($fgCode -or $bgCode) {
            "${fgCode}${bgCode}${text}$($ansiColors['Reset'])"
        } else {
            $text
        }

    }

    return ($parts -join "  ") + " "

}
