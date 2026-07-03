# ============================================================
# Pablitus Prompt Framework (PPF)
# Runtime.Service.ps1
# ============================================================

function Get-RuntimeInfo {

    $runtime = [ordered]@{

        Python = $null
        Node   = $null
        DotNet = $null

    }

    if (Test-Command python) {

        $runtime.Python = (
            python --version 2>$null
        ).Replace("Python ","")

    }

    if (Test-Command node) {

        $runtime.Node = (
            node --version 2>$null
        ).TrimStart("v")

    }

    if (Test-Command dotnet) {

        $runtime.DotNet = (
            dotnet --version 2>$null
        )

    }

    return [pscustomobject]$runtime

}