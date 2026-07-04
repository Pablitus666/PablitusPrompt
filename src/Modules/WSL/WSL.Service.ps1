# ============================================================
# Pablitus Prompt Framework (PPF)
# WSL.Service.ps1
# ============================================================

function Test-InsideWsl {

    return [bool]$env:WSL_DISTRO_NAME

}

function Get-WslDistro {

    return $env:WSL_DISTRO_NAME

}
