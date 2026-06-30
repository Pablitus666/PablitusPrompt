# ============================================================
# Pablitus Prompt Framework (PPF)
# Prompt.Pipeline.ps1
# ============================================================

function Invoke-PromptPipeline {

    param(

        [PromptContext]$Context

    )

    foreach ($provider in ($script:PromptProviders | Sort-Object Priority)) {

        try {

            & $provider.Script $Context

        }

        catch {

            Write-Verbose "[PPF] Provider '$($provider.Name)' failed."

        }

    }

}