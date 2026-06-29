# ============================================================
# Pablitus Prompt Framework (PPF)
# Prompt.Session.ps1
# ============================================================

Register-PromptModule -Name "Session" -Script {

    param(
        [PromptContext]$Context
    )

    $Context.User = $env:USERNAME
    $Context.Host = $env:COMPUTERNAME

    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]::new($identity)

    $Context.IsAdmin = $principal.IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator
    )

}