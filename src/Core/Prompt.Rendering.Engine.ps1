# ============================================================
# Pablitus Prompt Framework (PPF)
# Prompt.Renderer.ps1
# ============================================================

$script:PromptRenderers = @{}

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

    if (-not $script:PromptRenderers.ContainsKey($Name)) {
        throw "Renderer '$Name' is not registered."
    }

    return $script:PromptRenderers[$Name]

}

function Invoke-PromptRenderer {

    param(

        [PromptContext]$Context,

        [string]$Renderer = "Plain"

    )

    $scriptBlock = $script:PromptRenderers[$Renderer]

    if ($null -eq $scriptBlock) {
        throw "Renderer '$Renderer' is not registered."
    }

    & $scriptBlock -Context $Context

}

function Get-PromptString {

    param(
        [PromptContext]$Context = (Invoke-Prompt)
    )

    Invoke-PromptRenderer `
        -Context $Context `
        -Renderer "Plain"

}