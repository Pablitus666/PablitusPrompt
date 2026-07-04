# ============================================================
# Pablitus Prompt Framework (PPF)
# Python.Provider.ps1
# ============================================================

function Invoke-PythonProvider {

    param(
        [PromptContext]$Context
    )

    # Scoping cache to the current path since Python versions/virtualenvs can be folder-specific
    $cacheKey = "PythonVersion_$($Context.Path.Current)"
    $cached = Get-PPFCache -Key $cacheKey
    if ($null -ne $cached) {
        $Context.Runtime.Python = $cached
    }
    else {
        $version = Get-PythonVersion
        $Context.Runtime.Python = $version
        Set-PPFCache -Key $cacheKey -Value $version -TtlSeconds 30
    }

}

Register-PromptProvider `
    -Name "Python" `
    -Priority 500 `
    -Script ${function:Invoke-PythonProvider}
