# ============================================================
# Pablitus Prompt Framework (PPF)
# Python.Service.ps1
# ============================================================

function Get-PythonVersion {

    if (Test-CommandExists python) {

        $version = (python --version 2>$null)
        if ($version) {
            return ($version -join "").Replace("Python ","").Trim()
        }

    }

    return $null

}
