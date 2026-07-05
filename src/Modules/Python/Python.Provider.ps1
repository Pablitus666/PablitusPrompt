# ============================================================
# Pablitus Prompt Framework (PPF)
# Python.Provider.ps1
# ============================================================

function Invoke-PythonProvider {

    param(
        [PromptContext]$Context
    )

    # 1. Generate local invalidation signature (fast)
    $pythonPath = Get-CommandPath python
    $pyvenvCfg = Join-Path $Context.Path.Current "venv\pyvenv.cfg"
    if (-not (Test-Path $pyvenvCfg)) {
        $pyvenvCfg = Join-Path $Context.Path.Current ".venv\pyvenv.cfg"
    }
    $pyvenvTicks = 0
    if (Test-Path $pyvenvCfg) {
        $pyvenvTicks = (Get-Item $pyvenvCfg).LastWriteTime.Ticks
    }
    $sig = "Path:$pythonPath|Local:$pyvenvTicks"

    $cacheKey = "PythonVersion_$($Context.Path.Current)"
    $cached = Get-PPFCache -Key $cacheKey -UseDisk
    
    # 2. Check cache match
    if ($null -ne $cached -and $cached.Signature -eq $sig) {
        $Context.Runtime.Python = $cached.Version
    }
    else {
        # 3. Detect Python project presence
        $isPythonProj = $Context.Project.Type -eq "Python" -or 
                        (Test-Path (Join-Path $Context.Path.Current "requirements.txt")) -or 
                        (Test-Path (Join-Path $Context.Path.Current "pyproject.toml")) -or 
                        (Test-Path $pyvenvCfg)

        if ($isPythonProj) {
            $version = Get-PythonVersion
            $Context.Runtime.Python = $version
            $cacheData = [PSCustomObject]@{
                Signature = $sig
                Version   = $version
            }
            Set-PPFCache -Key $cacheKey -Value $cacheData -TtlSeconds 3600 -UseDisk
        }
        else {
            $Context.Runtime.Python = $null
        }
    }

}

Register-PromptProvider `
    -Name "Python" `
    -Priority 500 `
    -Script ${function:Invoke-PythonProvider}

