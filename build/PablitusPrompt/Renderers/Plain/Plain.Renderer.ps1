# ============================================================
# Pablitus Prompt Framework (PPF)
# Plain.Renderer.ps1
# ============================================================

Register-PromptRenderer `
    -Name "Plain" `
    -Script {

    param(
        [PromptContext]$Context
    )

    $parts = foreach ($segment in $Context.Segments) {

        if (-not $segment.Visible) {
            continue
        }

        if ($segment.Icon) {
            "$($segment.Icon) $($segment.Text)"
        }
        else {
            $segment.Text
        }

    }

    return ($parts -join "  ")

}