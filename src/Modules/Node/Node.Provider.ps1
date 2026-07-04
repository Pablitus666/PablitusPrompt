# ============================================================
# Pablitus Prompt Framework (PPF)
# Node.Provider.ps1
# ============================================================

function Invoke-NodeProvider {

    param(
        [PromptContext]$Context
    )

    # Scoping cache to the current path since Node versions can be folder-specific (.nvmrc, etc.)
    $cacheKey = "NodeVersion_$($Context.Path.Current)"
    $cached = Get-PPFCache -Key $cacheKey
    if ($null -ne $cached) {
        $Context.Runtime.Node = $cached
    }
    else {
        $version = Get-NodeVersion
        $Context.Runtime.Node = $version
        Set-PPFCache -Key $cacheKey -Value $version -TtlSeconds 30
    }

}

Register-PromptProvider `
    -Name "Node" `
    -Priority 510 `
    -Script ${function:Invoke-NodeProvider}
