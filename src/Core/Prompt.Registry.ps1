# ============================================================
# Pablitus Prompt Framework (PPF)
# Prompt.Registry.ps1
# ============================================================

$script:PromptProviders = @()

function Register-PromptProvider {

    param(

        [Parameter(Mandatory)]
        [string]$Name,

        [int]$Priority = 100,

        [scriptblock]$Script

    )

    $script:PromptProviders += [PSCustomObject]@{

        Name = $Name
        Priority = $Priority
        Script = $Script

    }

}