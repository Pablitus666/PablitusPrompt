# ============================================================
# Pablitus Prompt Framework (PPF)
# Node.Service.ps1
# ============================================================

function Get-NodeVersion {

    $res = Invoke-PPFExternalCommand -Command "node" -Arguments @("--version") -TimeoutMs 1000
    if ($res.Installed -and $res.ExitCode -eq 0 -and $res.Output) {
        $val = ($res.Output -join "").Trim()
        return $val.TrimStart([char]"v").Trim()
    }

    return $null

}
