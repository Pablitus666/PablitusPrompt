# ============================================================
# Pablitus Prompt Framework (PPF)
# Prompt.Rendering.ps1
# ============================================================

$script:PromptRenderers = [ordered]@{}

function Get-ConfiguredRendererName {

    $config = Get-PromptConfiguration
    if ($config -and $config.Renderer -and $config.Renderer.ContainsKey("Default")) {
        $configured = $config.Renderer["Default"]
        if ($configured -and $script:PromptRenderers.Contains($configured)) {
            return $configured
        }
    }

    return "Plain"

}

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
        [string]$Name
    )

    if ([string]::IsNullOrWhiteSpace($Name)) {
        $Name = Get-ConfiguredRendererName
    }

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

        [string]$Renderer

    )

    $rendererScript = Get-PromptRenderer -Name $Renderer

    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    try {
        if (Get-Command Write-PPFLog -ErrorAction SilentlyContinue) {
            Write-PPFLog -Level "DEBUG" -Message "Invoking Renderer '$Renderer'..."
        }
        $result = & $rendererScript -Context $Context
        $sw.Stop()
        $Context.Metrics["Renderer_TimeMs"] = $sw.Elapsed.TotalMilliseconds
        if (Get-Command Write-PPFLog -ErrorAction SilentlyContinue) {
            Write-PPFLog -Level "TRACE" -Message "Renderer '$Renderer' took $($sw.Elapsed.TotalMilliseconds) ms."
        }
        return $result
    }
    catch {
        $sw.Stop()
        $Context.Metrics["Renderer_TimeMs"] = $sw.Elapsed.TotalMilliseconds
        if (Get-Command Write-PPFLog -ErrorAction SilentlyContinue) {
            Write-PPFLog -Level "ERROR" -Message "Renderer '$Renderer' failed: $_"
        }
        throw $_
    }

}

function Get-PromptString {

    param(

        [PromptContext]$Context = (Invoke-Prompt),

        [string]$Renderer

    )

    if ([string]::IsNullOrWhiteSpace($Renderer)) {
        $Renderer = Get-ConfiguredRendererName
    }

    Invoke-PromptRenderer `
        -Context $Context `
        -Renderer $Renderer

}
