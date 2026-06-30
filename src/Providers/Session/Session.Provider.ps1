# ============================================================
# Pablitus Prompt Framework (PPF)
# Session.Provider.ps1
# ============================================================

function Invoke-SessionProvider {

    param(
        [PromptContext]$Context
    )

    $Context.Session.User = $env:USERNAME
    $Context.Session.Host = $env:COMPUTERNAME

    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]::new($identity)

    $Context.Session.IsAdmin = $principal.IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator
    )

}

Register-PromptProvider `
    -Name "Session" `
    -Priority 100 `
    -Script ${function:Invoke-SessionProvider}