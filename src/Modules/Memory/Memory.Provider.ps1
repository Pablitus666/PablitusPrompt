# ============================================================
# Pablitus Prompt Framework (PPF)
# Memory.Provider.ps1
# ============================================================

function Invoke-MemoryProvider {

    param(
        [PromptContext]$Context
    )

    $cacheKey = "MemoryUsage"
    $cached = Get-PPFCache -Key $cacheKey
    if ($null -ne $cached) {
        $Context.Memory.Usage = $cached
    }
    else {
        $usage = Get-MemoryUsage
        $Context.Memory.Usage = $usage
        Set-PPFCache -Key $cacheKey -Value $usage -TtlSeconds 15
    }

}

Register-PromptProvider `
    -Name "Memory" `
    -Priority 920 `
    -Script ${function:Invoke-MemoryProvider}
