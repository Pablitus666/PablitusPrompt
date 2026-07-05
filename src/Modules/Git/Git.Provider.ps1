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
        $Context.Git.Branch = $null
        $Context.Git.Dirty = $false
        $Context.Git.Ahead = 0
        $Context.Git.Behind = 0
        $Context.Git.Detached = $false
        $Context.Git.Root = $null
        return
    }

    $gitCfg = Get-SegmentConfiguration -Name "Git"
    $ttlMs = if ($gitCfg -and $gitCfg.ContainsKey("CacheTimeoutMs")) { [int]$gitCfg["CacheTimeoutMs"] } else { 5000 }

    $gitDir = Get-GitDir
    $repoRoot = if ($gitDir) { Split-Path $gitDir -Parent } else { $null }

    if ($repoRoot) {
        Start-GitWatcher -RepoRoot $repoRoot
    }

    $cacheKey = "GitStatusCache_$repoRoot"
    $cached = Get-PPFCache -Key $cacheKey
    $now = [DateTime]::UtcNow

    $useCache = $false
    if ($null -ne $cached -and $cached.Signature -eq $sig) {
        $isWithinTtl = ($now - $cached.Timestamp).TotalMilliseconds -lt $ttlMs
        $isWatcherClean = $repoRoot -and ($global:PPF_GitWatcherDirty.Contains($repoRoot)) -and ($global:PPF_GitWatcherDirty[$repoRoot] -eq $false)
        if ($isWithinTtl -or $isWatcherClean) {
            $useCache = $true
        }
    }

    if ($useCache) {
        $Context.Git.IsRepository = $true
        $Context.Git.Branch = $cached.Branch
        $Context.Git.Dirty = $cached.Dirty
        $Context.Git.Ahead = $cached.Ahead
        $Context.Git.Behind = $cached.Behind
        $Context.Git.Detached = $cached.Detached
        $Context.Git.Root = $cached.Root
        return
    }

    # Cache miss or expired signature -> fetch real git status
    $gitInfo = Get-GitStatusAndBranch
    if ($repoRoot) {
        $global:PPF_GitWatcherDirty[$repoRoot] = $false
    }


    $Context.Git.IsRepository = $true
    $Context.Git.Branch = $gitInfo.Branch
    $Context.Git.Dirty = $gitInfo.Dirty
    $Context.Git.Ahead = $gitInfo.Ahead
    $Context.Git.Behind = $gitInfo.Behind
    $Context.Git.Detached = $gitInfo.Detached
    $Context.Git.Root = $gitInfo.Root

    $cacheData = [PSCustomObject]@{
        Signature = $sig
        Timestamp = $now
        Branch    = $gitInfo.Branch
        Dirty     = $gitInfo.Dirty
        Ahead     = $gitInfo.Ahead
        Behind    = $gitInfo.Behind
        Detached  = $gitInfo.Detached
        Root      = $gitInfo.Root
    }
    Set-PPFCache -Key $cacheKey -Value $cacheData -TtlSeconds ([math]::Max(1, [math]::Ceiling($ttlMs / 1000)))

}

Register-PromptProvider `
    -Name "Git" `
    -Priority 400 `
    -Script ${function:Invoke-GitProvider}

