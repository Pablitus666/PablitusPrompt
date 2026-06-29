# ============================================================
# Pablitus Prompt Framework (PPF)
# Prompt.Registry.ps1
# ============================================================

$script:PromptModules = @()

function Register-PromptModule {

    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [scriptblock]$Script
    )

    $script:PromptModules += [PSCustomObject]@{

        Name   = $Name
        Script = $Script

    }

}