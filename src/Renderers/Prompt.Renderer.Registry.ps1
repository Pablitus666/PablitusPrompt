# ============================================================
# Pablitus Prompt Framework (PPF)
# Prompt.Renderer.Registry.ps1
# ============================================================

$script:PromptRenderers = @()

function Register-PromptRenderer {

    param(

        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [scriptblock]$Script

    )

    $script:PromptRenderers += [pscustomobject]@{

        Name   = $Name
        Script = $Script

    }

}

function Invoke-PromptRenderer {

    param(

        [Parameter(Mandatory)]
        [PromptContext]$Context,

        [string]$Renderer = "Plain"

    )

    $renderer =

        $script:PromptRenderers |
        Where-Object Name -eq $Renderer |
        Select-Object -First 1

    if (-not $renderer) {

        throw "Renderer '$Renderer' no encontrado."

    }

    & $renderer.Script $Context

}