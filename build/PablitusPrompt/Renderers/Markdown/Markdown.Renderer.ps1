# ============================================================
# Pablitus Prompt Framework (PPF)
# Markdown.Renderer.ps1
# ============================================================

Register-PromptRenderer `
    -Name "Markdown" `
    -Script {

    param(
        [PromptContext]$Context
    )

    $parts = foreach ($segment in $Context.Segments) {

        if (-not $segment.Visible) {
            continue
        }

        $text = if ($segment.Icon) {
            "$($segment.Icon) $($segment.Text)"
        }
        else {
            $segment.Text
        }

        if ($segment.Foreground) {
            "**$text**"
        }
        else {
            $text
        }

    }

    return ($parts -join " | ")

}
