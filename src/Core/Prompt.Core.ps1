# ============================================================
# Pablitus Prompt Framework (PPF)
# Prompt.Core.ps1
# ============================================================

function New-PromptContext {

    return [PromptContext]::new()

}

function Invoke-Prompt {

    $context = New-PromptContext

    # Ejecutar Providers
    Invoke-PromptPipeline -Context $context

    # Construir segmentos
    Invoke-PromptSegments -Context $context

    return $context

}

function Get-PromptString {

    param(

        [string]$Renderer = "Plain"

    )

    $context = Invoke-Prompt

    Invoke-PromptRenderer `
        -Context $context `
        -Renderer $Renderer

}