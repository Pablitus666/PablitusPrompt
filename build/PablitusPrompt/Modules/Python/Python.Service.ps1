# ============================================================
# Pablitus Prompt Framework (PPF)
# Python.Service.ps1
# ============================================================

function Get-PythonVersion {

    $res = Invoke-PPFExternalCommand -Command "python" -Arguments @("--version") -TimeoutMs 1000
    if ($res.Installed -and $res.ExitCode -eq 0 -and $res.Output) {
        return ($res.Output -join "").Replace("Python ","").Trim()
    }

    return $null

}
