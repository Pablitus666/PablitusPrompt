# ============================================================
# Pablitus Prompt Framework (PPF)
# DotNet.Provider.ps1
# ============================================================

function Invoke-DotNetProvider {

    param(
        [PromptContext]$Context
    )

    # 1. Generate local invalidation signature (fast)
    $dotnetPath = Get-CommandPath dotnet
    $globalJson = Join-Path $Context.Path.Current "global.json"
    $globalJsonTicks = 0
    if (Test-Path $globalJson) {
        $globalJsonTicks = (Get-Item $globalJson).LastWriteTime.Ticks
    }
    $sig = "Path:$dotnetPath|Local:$globalJsonTicks"

    $cacheKey = "DotNetVersion_$($Context.Path.Current)"
    $cached = Get-PPFCache -Key $cacheKey -UseDisk
    
    # 2. Check cache match
    if ($null -ne $cached -and $cached.Signature -eq $sig) {
        $Context.Runtime.DotNet = $cached.Version
    }
    else {
        # 3. Detect DotNet project presence
        $hasProjFiles = $false
        try {
            if (Test-Path $Context.Path.Current) {
                $hasProjFiles = @([System.IO.Directory]::EnumerateFiles($Context.Path.Current, "*.*proj")).Count -gt 0 -or
                                @([System.IO.Directory]::EnumerateFiles($Context.Path.Current, "*.sln")).Count -gt 0
            }
        } catch {}

        $isDotNetProj = $Context.Project.Type -eq ".NET" -or (Test-Path $globalJson) -or $hasProjFiles

        if ($isDotNetProj) {
            $version = Get-DotNetVersion
            $Context.Runtime.DotNet = $version
            $cacheData = [PSCustomObject]@{
                Signature = $sig
                Version   = $version
            }
            Set-PPFCache -Key $cacheKey -Value $cacheData -TtlSeconds 3600 -UseDisk
        }
        else {
            $Context.Runtime.DotNet = $null
        }
    }

}

Register-PromptProvider `
    -Name "DotNet" `
    -Priority 520 `
    -Script ${function:Invoke-DotNetProvider}
