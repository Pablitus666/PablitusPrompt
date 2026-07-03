# ============================================================
# Pablitus Prompt Framework (PPF)
# Prompt.API.ps1
# ============================================================

function Get-Prompt {

    param(
        [PromptContext]$Context = (Invoke-Prompt)
    )

    return $Context.Segments

}