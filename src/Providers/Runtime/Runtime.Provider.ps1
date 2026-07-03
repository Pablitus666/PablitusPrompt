# ============================================================
# Pablitus Prompt Framework (PPF)
# Runtime.Provider.ps1
# ============================================================

function Invoke-RuntimeProvider {

    param(
        [PromptContext]$Context
    )

    $runtime = Get-RuntimeInfo

    $Context.Runtime.Python = $runtime.Python
    $Context.Runtime.Node   = $runtime.Node
    $Context.Runtime.DotNet = $runtime.DotNet

}

Register-PromptProvider `
    -Name "Runtime" `
    -Priority 500 `
    -Script ${function:Invoke-RuntimeProvider}