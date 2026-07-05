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
        
        $global:PPF_CurrentExecutingProvider = $provider.Name
        if (-not $global:PPF_ProviderCacheStats.Contains($provider.Name)) {
            $global:PPF_ProviderCacheStats[$provider.Name] = @{ Hits = 0; Misses = 0; Expirations = 0; Refreshes = 0 }
        }
        
        $stats = $global:PPF_ProviderCacheStats[$provider.Name]
        $beforeHits = $stats.Hits
        $beforeMisses = $stats.Misses
        $beforeExpirations = $stats.Expirations
        $beforeRefreshes = $stats.Refreshes

        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        try {
            if (Get-Command Write-PPFLog -ErrorAction SilentlyContinue) {
                Write-PPFLog -Level "DEBUG" -Message "Invoking Provider '$($provider.Name)'..."
            }
            & $provider.Script $Context
            $sw.Stop()
            
            $elapsed = $sw.Elapsed.TotalMilliseconds
            $afterHits = $stats.Hits
            $afterMisses = $stats.Misses
            $afterExpirations = $stats.Expirations
            $afterRefreshes = $stats.Refreshes

            $hasHit = $afterHits -gt $beforeHits
            $hasMiss = $afterMisses -gt $beforeMisses
            $hasExpiration = $afterExpirations -gt $beforeExpirations
            $hasRefresh = $afterRefreshes -gt $beforeRefreshes

            $Context.Metrics["Provider_$($provider.Name)_TimeMs"] = $elapsed
            $Context.Metrics["Provider_$($provider.Name)_CacheHit"] = $hasHit
            $Context.Metrics["Provider_$($provider.Name)_CacheMiss"] = $hasMiss
            $Context.Metrics["Provider_$($provider.Name)_TTLExpired"] = $hasExpiration
            $Context.Metrics["Provider_$($provider.Name)_Refresh"] = $hasRefresh
            $Context.Metrics["Provider_$($provider.Name)_ReadTimeMs"] = if ($hasHit -and -not $hasMiss) { $elapsed } else { 0.0 }
            $Context.Metrics["Provider_$($provider.Name)_UpdateTimeMs"] = if ($hasMiss -or $hasRefresh -or $hasExpiration) { $elapsed } else { 0.0 }

            if (Get-Command Write-PPFLog -ErrorAction SilentlyContinue) {
                Write-PPFLog -Level "TRACE" -Message "Provider '$($provider.Name)' took $($elapsed) ms (CacheHit: $hasHit, CacheMiss: $hasMiss, TTLExpired: $hasExpiration, Refresh: $hasRefresh)."
            }
        }
        catch {
            $sw.Stop()
            $elapsed = $sw.Elapsed.TotalMilliseconds
            
            $afterHits = $stats.Hits
            $afterMisses = $stats.Misses
            $afterExpirations = $stats.Expirations
            $afterRefreshes = $stats.Refreshes

            $hasHit = $afterHits -gt $beforeHits
            $hasMiss = $afterMisses -gt $beforeMisses
            $hasExpiration = $afterExpirations -gt $beforeExpirations
            $hasRefresh = $afterRefreshes -gt $beforeRefreshes

            $Context.Metrics["Provider_$($provider.Name)_TimeMs"] = $elapsed
            $Context.Metrics["Provider_$($provider.Name)_CacheHit"] = $hasHit
            $Context.Metrics["Provider_$($provider.Name)_CacheMiss"] = $hasMiss
            $Context.Metrics["Provider_$($provider.Name)_TTLExpired"] = $hasExpiration
            $Context.Metrics["Provider_$($provider.Name)_Refresh"] = $hasRefresh
            $Context.Metrics["Provider_$($provider.Name)_ReadTimeMs"] = if ($hasHit -and -not $hasMiss) { $elapsed } else { 0.0 }
            $Context.Metrics["Provider_$($provider.Name)_UpdateTimeMs"] = if ($hasMiss -or $hasRefresh -or $hasExpiration) { $elapsed } else { 0.0 }
            if (Get-Command Write-PPFLog -ErrorAction SilentlyContinue) {
                Write-PPFLog -Level "ERROR" -Message "Provider '$($provider.Name)' failed: $_"
            }
        }
        finally {
            $global:PPF_CurrentExecutingProvider = $null
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