# ============================================================
# Pablitus Prompt Framework (PPF)
# DotNet.Provider.ps1
# ============================================================

function Invoke-DotNetProvider {

    param(
        [PromptContext]$Context
    )

    # 1. Cheap project detection first: resolving the executable and reading
    #    file timestamps is only needed when the segment can actually appear.
    $current = $Context.Path.Current
    $globalJson = Join-Path $current "global.json"

    $isDotNetProj = $Context.Project.Type -eq ".NET" -or [System.IO.File]::Exists($globalJson)

    if (-not $isDotNetProj -and [System.IO.Directory]::Exists($current)) {
        try {
            $isDotNetProj = [System.IO.Directory]::GetFiles($current, "*.*proj").Length -gt 0 -or
                            [System.IO.Directory]::GetFiles($current, "*.sln").Length -gt 0
        }
        catch {}
    }

    if (-not $isDotNetProj) {
        $Context.Runtime.DotNet = $null
        return
    }

    # 2. Generate local invalidation signature
    $dotnetPath = Get-CommandPath dotnet
    $globalJsonTicks = 0
    if ([System.IO.File]::Exists($globalJson)) {
        $globalJsonTicks = [System.IO.File]::GetLastWriteTime($globalJson).Ticks
    }
    $sig = "Path:$dotnetPath|Local:$globalJsonTicks"

    $cacheKey = "DotNetVersion_$current"
    $cached = Get-PPFCache -Key $cacheKey -UseDisk

    # 3. Reuse the cached version when the signature still matches
    if ($null -ne $cached -and $cached.Signature -eq $sig) {
        $Context.Runtime.DotNet = $cached.Version
        return
    }

    $version = Get-DotNetVersion
    $Context.Runtime.DotNet = $version
    $cacheData = [PSCustomObject]@{
        Signature = $sig
        Version   = $version
    }
    Set-PPFCache -Key $cacheKey -Value $cacheData -TtlSeconds 3600 -UseDisk

}

Register-PromptProvider `
    -Name "DotNet" `
    -Priority 520 `
    -Script ${function:Invoke-DotNetProvider}
