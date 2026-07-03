# ============================================================
# Pablitus Prompt Framework (PPF)
# Prompt.Rendering.ps1
# ============================================================

$script:PromptRenderers = [ordered]@{}

function Register-PromptRenderer {

    param(

        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [scriptblock]$Script

    )

    $script:PromptRenderers[$Name] = $Script

}

function Get-PromptRenderer {

    param(
        [string]$Name = "Plain"
    )

    if (-not $script:PromptRenderers.Contains($Name)) {
        throw "Renderer '$Name' is not registered."
    }

    return $script:PromptRenderers[$Name]

}

function Get-PromptRenderers {

    return $script:PromptRenderers.Keys

}

function Invoke-PromptRenderer {

    param(

        [Parameter(Mandatory)]
        [PromptContext]$Context,

        [string]$Renderer = "Plain"

    )

    $renderer = Get-PromptRenderer -Name $Renderer

    & $renderer -Context $Context

}

function Get-PromptString {

    param(

        [PromptContext]$Context = (Invoke-Prompt),

        [string]$Renderer = "Plain"

    )

    Invoke-PromptRenderer `
        -Context $Context `
        -Renderer $Renderer

}