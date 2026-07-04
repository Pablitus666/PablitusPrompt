# ============================================================
# Pablitus Prompt Framework (PPF)
# Git.Provider.ps1
# ============================================================

function Invoke-GitProvider {

    param(
        [PromptContext]$Context
    )

    $sig = Get-GitStateSignature
    if ($null -eq $sig) {
        $Context.Git.IsRepository = $false
        return
    }

    $gitCfg = Get-SegmentConfiguration -Name "Git"
    $ttlMs = if ($gitCfg -and $gitCfg.ContainsKey("CacheTimeoutMs")) { [int]$gitCfg["CacheTimeoutMs"] } else { 5000 }

    $cacheKey = "GitStatusCache"
    $cached = Get-PPFCache -Key $cacheKey
    $now = [DateTime]::UtcNow

    if ($null -ne $cached -and $cached.Signature -eq $sig -and ($now - $cached.Timestamp).TotalMilliseconds -lt $ttlMs) {
        $Context.Git.IsRepository = $true
        $Context.Git.Branch = $cached.Branch
        $Context.Git.Dirty = $cached.Dirty
        return
    }

    # Cache miss or expired signature -> fetch real git status
    $gitInfo = Get-GitStatusAndBranch

    $Context.Git.IsRepository = $true
    $Context.Git.Branch = $gitInfo.Branch
    $Context.Git.Dirty = $gitInfo.Dirty

    $cacheData = [PSCustomObject]@{
        Signature = $sig
        Timestamp = $now
        Branch    = $gitInfo.Branch
        Dirty     = $gitInfo.Dirty
    }
    Set-PPFCache -Key $cacheKey -Value $cacheData -TtlSeconds ([math]::Max(1, [math]::Ceiling($ttlMs / 1000)))

}

Register-PromptProvider `
    -Name "Git" `
    -Priority 400 `
    -Script ${function:Invoke-GitProvider}
