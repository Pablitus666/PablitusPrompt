# ============================================================
# Pablitus Prompt Framework (PPF)
# Prompt.Core.ps1
# ============================================================

function New-PromptContext {

    return [PromptContext]::new()

}

function Get-PromptContext {

    $ctx = New-PromptContext

    Invoke-PromptPipeline -Context $ctx

    return $ctx

}