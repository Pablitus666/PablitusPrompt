# ============================================================
# Pablitus Prompt Framework (PPF)
# Prompt.Core.ps1
# ============================================================

function New-PromptContext {

    return [PromptContext]::new()

}

function Invoke-Prompt {

    if (Get-Command Test-PromptConfigReload -ErrorAction SilentlyContinue) {
        Test-PromptConfigReload
    }

    if (Get-Command Invoke-PPFEvent -ErrorAction SilentlyContinue) {
        Invoke-PPFEvent -EventName "BeforeRender" -EventArgs $null
    }

    $context = New-PromptContext

    # Ejecutar Providers
    Invoke-PromptProviders -Context $context

    # Ejecutar Pipeline Middleware
    Invoke-PPFPipeline -Context $context

    # Construir segmentos
    Invoke-PromptSegments -Context $context

    if (Get-Command Invoke-PPFEvent -ErrorAction SilentlyContinue) {
        Invoke-PPFEvent -EventName "AfterRender" -EventArgs $context
    }

    return $context

}