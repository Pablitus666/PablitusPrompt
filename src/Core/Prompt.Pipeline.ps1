# ============================================================
# Pablitus Prompt Framework (PPF)
# Prompt.Pipeline.ps1
# ============================================================

$script:PromptProviders = @()
$script:PromptProvidersSorted = $null
$script:PipelineSteps = @()
$script:PipelineStepsSorted = $null

# The sorted views are rebuilt only when a registration changes. Sorting on
# every render costs more than the render itself for this few entries.
function Get-SortedPromptProviders {
    if ($null -eq $script:PromptProvidersSorted) {
        $script:PromptProvidersSorted = @($script:PromptProviders | Sort-Object Priority)
    }
    return $script:PromptProvidersSorted
}

function Get-SortedPipelineSteps {
    if ($null -eq $script:PipelineStepsSorted) {
        $script:PipelineStepsSorted = @($script:PipelineSteps | Sort-Object Priority)
    }
    return $script:PipelineStepsSorted
}

if ($null -eq $global:PPF_SkipHiddenProviders) {
    $global:PPF_SkipHiddenProviders = $false
}

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

    $script:PromptProvidersSorted = $null

}

function Get-PromptProviders {

    return @(Get-SortedPromptProviders)

}

function Invoke-PromptProviders {

    param(
        [PromptContext]$Context
    )

    $providersToRun = Get-SortedPromptProviders

    if ($global:PPF_SkipHiddenProviders) {

        $providerVisibility = @{}
        foreach ($candidate in $providersToRun) {
            $segmentConfig = Get-SegmentConfiguration -Name $candidate.Name
            $providerVisibility[$candidate.Name] = if ($null -ne $segmentConfig -and $segmentConfig.ContainsKey("Visible")) {
                [bool]$segmentConfig["Visible"]
            }
            else {
                $true
            }
        }

        # Providers whose data is consumed by another provider, even when
        # their own segment is hidden.
        $providerDependencies = @{
            "Python" = @("Path", "Project")
            "Node"   = @("Path", "Project")
            "DotNet" = @("Path", "Project")
        }

        $neededProviders = @{}
        $addNeededProvider = {
            param([string]$Name)

            if ($neededProviders.ContainsKey($Name)) { return }
            $neededProviders[$Name] = $true

            if ($providerDependencies.ContainsKey($Name)) {
                foreach ($dependency in $providerDependencies[$Name]) {
                    & $addNeededProvider $dependency
                }
            }
        }

        foreach ($candidate in $providersToRun) {
            if ($providerVisibility[$candidate.Name]) {
                & $addNeededProvider $candidate.Name
            }
        }

        $providersToRun = @($providersToRun | Where-Object { $neededProviders.ContainsKey($_.Name) })
    }

    foreach ($provider in $providersToRun) {
        
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
            if ($script:LogLevel -eq "DEBUG" -or $script:LogLevel -eq "TRACE") {
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

            if ($script:LogLevel -eq "TRACE") {
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
            Write-PPFLog -Level "ERROR" -Message "Provider '$($provider.Name)' failed: $_"
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

    $script:PipelineStepsSorted = $null

}

function Invoke-PPFPipeline {

    param(
        [PromptContext]$Context
    )

    foreach ($step in (Get-SortedPipelineSteps)) {

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
    $Context.Metrics["ExecutionTimeMs"] = ([datetime]::Now - $Context.Timestamp).TotalMilliseconds
}