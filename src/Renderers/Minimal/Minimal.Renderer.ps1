# ============================================================
# Pablitus Prompt Framework (PPF)
# Minimal.Renderer.ps1
# ============================================================

Register-PromptRenderer `
    -Name "Minimal" `
    -Script {

    param(
        [PromptContext]$Context
    )

    $pathSegment = $Context.Segments | Where-Object Name -eq "Path"
    $gitSegment = $Context.Segments | Where-Object Name -eq "Git"

    $parts = @()

    if ($gitSegment -and $gitSegment.Visible) {
        $parts += "[$($gitSegment.Text)]"
    }

    if ($pathSegment -and $pathSegment.Visible) {
        $parts += $pathSegment.Text
    }

    $promptChar = if ($Context.Session.IsAdmin) { "#" } else { ">" }
    $parts += $promptChar

    return ($parts -join " ")

}
