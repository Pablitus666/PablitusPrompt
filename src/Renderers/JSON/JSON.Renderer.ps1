# ============================================================
# Pablitus Prompt Framework (PPF)
# JSON.Renderer.ps1
# ============================================================

Register-PromptRenderer `
    -Name "JSON" `
    -Script {

    param(
        [PromptContext]$Context
    )

    return ($Context | ConvertTo-Json -Depth 5)

}
