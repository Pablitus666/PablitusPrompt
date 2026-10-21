# ============================================================
# Pablitus Prompt Framework (PPF)
# HTML.Renderer.ps1
# ============================================================

Register-PromptRenderer `
    -Name "HTML" `
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

        $escapedText = [System.Security.SecurityElement]::Escape([string]$text)

        $styles = @()

        if ($segment.Foreground) {
            $styles += "color: $($segment.Foreground);"
        }

        if ($segment.Background) {
            $styles += "background-color: $($segment.Background);"
        }

        if ($styles.Count -gt 0) {
            "<span style=""$($styles -join ' ')"">$escapedText</span>"
        }
        else {
            "<span>$escapedText</span>"
        }

    }

    return ($parts -join " ")

}
