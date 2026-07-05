# ============================================================
# Pablitus Prompt Framework (PPF)
# CPU.Provider.ps1
# ============================================================

function Invoke-CpuProvider {

    param(
        [PromptContext]$Context
    )

    $cacheKey = "CpuUsage"
    $cached = Get-PPFCache -Key $cacheKey
    if ($null -ne $cached) {
        $Context.Cpu.Usage = $cached
    }
    else {
        $usage = Get-CpuUsage
        $Context.Cpu.Usage = $usage
        Set-PPFCache -Key $cacheKey -Value $usage -TtlSeconds 1
    }

}

Register-PromptProvider `
    -Name "CPU" `
    -Priority 910 `
    -Script ${function:Invoke-CpuProvider}

