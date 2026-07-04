# ============================================================
# Pablitus Prompt Framework (PPF)
# WSL.Provider.ps1
# ============================================================

function Invoke-WslProvider {

    param(
        [PromptContext]$Context
    )

    $isWsl = Test-InsideWsl
    $Context.Wsl.IsWsl = $isWsl

    if ($isWsl) {
        $Context.Wsl.Distro = Get-WslDistro
    }
    else {
        $Context.Wsl.Distro = ""
    }

}

Register-PromptProvider `
    -Name "WSL" `
    -Priority 110 `
    -Script ${function:Invoke-WslProvider}
