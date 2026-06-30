# ============================================================
# Pablitus Prompt Framework (PPF)
# Prompt.Core.ps1
# ============================================================

function New-PromptContext {

    return [PromptContext]::new()

}

function Invoke-Prompt {

    $context = New-PromptContext

    Invoke-PromptPipeline -Context $context

    return $context

}