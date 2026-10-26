# ============================================================
# Pablitus Prompt Framework (PPF)
# Python.Provider.ps1
# ============================================================

function Invoke-PythonProvider {

    param(
        [PromptContext]$Context
    )

    # 1. Cheap project detection first: resolving the executable and reading
    #    file timestamps is only needed when the segment can actually appear.
    $current = $Context.Path.Current
    $venvCfg = Join-Path $current (Join-Path "venv" "pyvenv.cfg")
    $dotVenvCfg = Join-Path $current (Join-Path ".venv" "pyvenv.cfg")

    $pyvenvCfg = if ([System.IO.File]::Exists($venvCfg)) { $venvCfg } else { $dotVenvCfg }

    $isPythonProj = $Context.Project.Type -eq "Python" -or
                    [System.IO.File]::Exists((Join-Path $current "requirements.txt")) -or
                    [System.IO.File]::Exists((Join-Path $current "pyproject.toml")) -or
                    [System.IO.File]::Exists($pyvenvCfg)

    if (-not $isPythonProj) {
        $Context.Runtime.Python = $null
        return
    }

    # 2. Generate local invalidation signature
    $pythonPath = Get-CommandPath python
    $pyvenvTicks = 0
    if ([System.IO.File]::Exists($pyvenvCfg)) {
        $pyvenvTicks = [System.IO.File]::GetLastWriteTime($pyvenvCfg).Ticks
    }
    $sig = "Path:$pythonPath|Local:$pyvenvTicks"

    $cacheKey = "PythonVersion_$current"
    $cached = Get-PPFCache -Key $cacheKey -UseDisk

    # 3. Reuse the cached version when the signature still matches
    if ($null -ne $cached -and $cached.Signature -eq $sig) {
        $Context.Runtime.Python = $cached.Version
        return
    }

    $version = Get-PythonVersion
    $Context.Runtime.Python = $version
    $cacheData = [PSCustomObject]@{
        Signature = $sig
        Version   = $version
    }
    Set-PPFCache -Key $cacheKey -Value $cacheData -TtlSeconds 3600 -UseDisk

}

Register-PromptProvider `
    -Name "Python" `
    -Priority 500 `
    -Script ${function:Invoke-PythonProvider}

