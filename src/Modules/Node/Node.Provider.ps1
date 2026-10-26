# ============================================================
# Pablitus Prompt Framework (PPF)
# Node.Provider.ps1
# ============================================================

function Invoke-NodeProvider {

    param(
        [PromptContext]$Context
    )

    # 1. Cheap project detection first: resolving the executable and reading
    #    file timestamps is only needed when the segment can actually appear.
    $current = $Context.Path.Current
    $nodeVersionFile = Join-Path $current ".node-version"
    $nvmrcFile = Join-Path $current ".nvmrc"

    $isNodeProj = $Context.Project.Type -eq "Node" -or
                  [System.IO.File]::Exists((Join-Path $current "package.json")) -or
                  [System.IO.File]::Exists($nodeVersionFile) -or
                  [System.IO.File]::Exists($nvmrcFile)

    if (-not $isNodeProj) {
        $Context.Runtime.Node = $null
        return
    }

    # 2. Generate local invalidation signature
    $nodePath = Get-CommandPath node
    $nodeVersionTicks = 0
    if ([System.IO.File]::Exists($nodeVersionFile)) {
        $nodeVersionTicks = [System.IO.File]::GetLastWriteTime($nodeVersionFile).Ticks
    }
    elseif ([System.IO.File]::Exists($nvmrcFile)) {
        $nodeVersionTicks = [System.IO.File]::GetLastWriteTime($nvmrcFile).Ticks
    }
    $sig = "Path:$nodePath|Local:$nodeVersionTicks"

    $cacheKey = "NodeVersion_$current"
    $cached = Get-PPFCache -Key $cacheKey -UseDisk

    # 3. Reuse the cached version when the signature still matches
    if ($null -ne $cached -and $cached.Signature -eq $sig) {
        $Context.Runtime.Node = $cached.Version
        return
    }

    $version = Get-NodeVersion
    $Context.Runtime.Node = $version
    $cacheData = [PSCustomObject]@{
        Signature = $sig
        Version   = $version
    }
    Set-PPFCache -Key $cacheKey -Value $cacheData -TtlSeconds 3600 -UseDisk

}

Register-PromptProvider `
    -Name "Node" `
    -Priority 510 `
    -Script ${function:Invoke-NodeProvider}

