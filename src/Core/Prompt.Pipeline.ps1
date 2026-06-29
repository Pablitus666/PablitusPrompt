# ============================================================
# Pablitus Prompt Framework (PPF)
# Prompt.Pipeline.ps1
# ============================================================

function Invoke-PromptPipeline {

    param(
        [PromptContext]$Context
    )

    foreach ($module in $script:PromptModules) {

        try {

            & $module.Script $Context

        }
        catch {

            Write-Verbose "Module '$($module.Name)' failed."

        }

    }

}