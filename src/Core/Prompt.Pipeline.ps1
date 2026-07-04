# ============================================================
# Pablitus Prompt Framework (PPF)
# Prompt.Pipeline.ps1
# ============================================================

$script:PromptProviders = @()
$script:PipelineSteps = @()

function Register-PromptProvider {

    param(

        [Parameter(Mandatory)]
        [string]$Name,

        [int]$Priority = 100,

        [scriptblock]$Script

    )

    $script:PromptProviders = @(
        $script:PromptProviders | Where-Object Name -ne $Name
    )

    $script:PromptProviders += [PSCustomObject]@{
        Name     = $Name
        Priority = $Priority
        Script   = $Script
    }

}

function Get-PromptProviders {

    return $script:PromptProviders | Sort-Object Priority

}

function Invoke-PromptProviders {

    param(
        [PromptContext]$Context
    )

    foreach ($provider in ($script:PromptProviders | Sort-Object Priority)) {

        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        try {
            if (Get-Command Write-PPFLog -ErrorAction SilentlyContinue) {
                Write-PPFLog -Level "DEBUG" -Message "Invoking Provider '$($provider.Name)'..."
            }
            & $provider.Script $Context
            $sw.Stop()
            $Context.Metrics["Provider_$($provider.Name)_TimeMs"] = $sw.Elapsed.TotalMilliseconds
            if (Get-Command Write-PPFLog -ErrorAction SilentlyContinue) {
                Write-PPFLog -Level "TRACE" -Message "Provider '$($provider.Name)' took $($sw.Elapsed.TotalMilliseconds) ms."
            }
        }
        catch {
            $sw.Stop()
            $Context.Metrics["Provider_$($provider.Name)_TimeMs"] = $sw.Elapsed.TotalMilliseconds
            if (Get-Command Write-PPFLog -ErrorAction SilentlyContinue) {
                Write-PPFLog -Level "ERROR" -Message "Provider '$($provider.Name)' failed: $_"
            }
        }

    }

}

function Register-PPFPipelineStep {

    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [int]$Priority = 100,

        [Parameter(Mandatory)]
        [scriptblock]$Script
    )

    $script:PipelineSteps = @(
        $script:PipelineSteps | Where-Object Name -ne $Name
    )

    $script:PipelineSteps += [PSCustomObject]@{
        Name     = $Name
        Priority = $Priority
        Script   = $Script
    }

}

function Invoke-PPFPipeline {

    param(
        [PromptContext]$Context
    )

    foreach ($step in ($script:PipelineSteps | Sort-Object Priority)) {

        try {
            & $step.Script $Context
        }
        catch {
            Write-Verbose "[PPF] Pipeline step '$($step.Name)' failed: $_"
        }

    }

}

# Registrar paso de Profiling por defecto
Register-PPFPipelineStep -Name "Profiling" -Priority 999 -Script {
    param([PromptContext]$Context)
    $Context.Metrics["ExecutionTimeMs"] = ((Get-Date) - $Context.Timestamp).TotalMilliseconds
}