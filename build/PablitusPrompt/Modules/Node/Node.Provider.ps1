# ============================================================
# Pablitus Prompt Framework (PPF)
# Node.Provider.ps1
# ============================================================

function Invoke-NodeProvider {

    param(
        [PromptContext]$Context
    )

    # 1. Generate local invalidation signature (fast)
    $nodePath = Get-CommandPath node
    $nodeVersionFile = Join-Path $Context.Path.Current ".node-version"
    $nvmrcFile = Join-Path $Context.Path.Current ".nvmrc"
    $nodeVersionTicks = 0
    if (Test-Path $nodeVersionFile) {
        $nodeVersionTicks = (Get-Item $nodeVersionFile).LastWriteTime.Ticks
    }
    elseif (Test-Path $nvmrcFile) {
        $nodeVersionTicks = (Get-Item $nvmrcFile).LastWriteTime.Ticks
    }
    $sig = "Path:$nodePath|Local:$nodeVersionTicks"

    $cacheKey = "NodeVersion_$($Context.Path.Current)"
    $cached = Get-PPFCache -Key $cacheKey -UseDisk
    
    # 2. Check cache match
    if ($null -ne $cached -and $cached.Signature -eq $sig) {
        $Context.Runtime.Node = $cached.Version
    }
    else {
        # 3. Detect Node project presence
        $isNodeProj = $Context.Project.Type -eq "Node" -or 
                      (Test-Path (Join-Path $Context.Path.Current "package.json")) -or 
                      (Test-Path $nodeVersionFile) -or 
                      (Test-Path $nvmrcFile)

        if ($isNodeProj) {
            $version = Get-NodeVersion
            $Context.Runtime.Node = $version
            $cacheData = [PSCustomObject]@{
                Signature = $sig
                Version   = $version
            }
            Set-PPFCache -Key $cacheKey -Value $cacheData -TtlSeconds 3600 -UseDisk
        }
        else {
            $Context.Runtime.Node = $null
        }
    }

}

Register-PromptProvider `
    -Name "Node" `
    -Priority 510 `
    -Script ${function:Invoke-NodeProvider}

