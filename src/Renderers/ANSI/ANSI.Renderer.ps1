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

    $reset = "`e[0m"

    $parts = foreach ($segment in $Context.Segments) {

        if (-not $segment.Visible) {
            continue
        }

        $fgCode = ConvertTo-PPFAnsiColor -Color $segment.Foreground
        $bgCode = ConvertTo-PPFAnsiColor -Color $segment.Background -Background

        $text = if ($segment.Icon) {
            "$($segment.Icon) $($segment.Text)"
        }
        else {
            $segment.Text
        }

        if ($fgCode -or $bgCode) {
            "${fgCode}${bgCode}${text}${reset}"
        }
        else {
            $text
        }

    }

    return ($parts -join "  ") + " "

}
