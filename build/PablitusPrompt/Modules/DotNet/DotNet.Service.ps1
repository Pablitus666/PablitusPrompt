# ============================================================
# Pablitus Prompt Framework (PPF)
# DotNet.Service.ps1
# ============================================================

function Get-DotNetVersion {

    # Running 'dotnet --version' with timeout
    $res = Invoke-PPFExternalCommand -Command "dotnet" -Arguments @("--version") -TimeoutMs 500
    if ($res.Installed -and -not $res.TimedOut -and $res.ExitCode -eq 0) {
        $version = $res.Output.Trim()
        if ($version) {
            return $version
        }
    }

    return $null

}
