# ============================================================
# Pablitus Prompt Framework (PPF)
# Measure-PPFDotNetCore.ps1
#
# Measures the .NET core with native providers and with one
# PowerShell plugin. Reports cold-start and warm prompt latency,
# optional JSON output and CI-friendly budgets.
# ============================================================

[CmdletBinding()]
param(
    [ValidateRange(1, 1000)]
    [int]$Iterations = 10,

    [ValidateRange(0, 100)]
    [int]$WarmupIterations = 2,

    [ValidateRange(1, 600000)]
    [int]$ColdBudgetMs = 15000,

    [ValidateRange(1, 600000)]
    [int]$WarmBudgetMs = 500,

    [ValidateRange(0, 600000)]
    [int]$OverheadBudgetMs = 250,

    [string]$OutputPath,

    [switch]$NoThreshold
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$manifestPath = Join-Path $repoRoot "src/PablitusPrompt.psd1"
$pluginName = "PpfBenchmarkPlugin"
$tempDirectory = Join-Path ([System.IO.Path]::GetTempPath()) ("ppf-benchmark-" + [guid]::NewGuid().ToString("N"))
$module = $null
$pluginRegistered = $false

function New-BenchmarkTheme {

    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][string]$Type,
        [string]$Template
    )

    $segment = [ordered]@{
        type       = $Type
        name       = $Name
        style      = "plain"
        foreground = "text"
    }

    if (-not [string]::IsNullOrWhiteSpace($Template)) {
        $segment.template = $Template
    }

    $document = [ordered]@{
        '$schema'  = "https://pablitus.dev/schemas/theme.schema.json"
        name       = $Name
        version    = "1.0"
        renderer   = "plain"
        finalSpace = $false
        palette    = @{
            text = "#ffffff"
        }
        blocks     = @(
            [ordered]@{
                type      = "prompt"
                alignment = "left"
                newline   = $false
                segments  = @([pscustomobject]$segment)
            }
        )
    }

    $path = Join-Path $tempDirectory "$Name.json"
    $document | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $path -Encoding utf8
    return $path
}

function Get-BenchmarkStats {

    param(
        [Parameter(Mandatory)][double[]]$Samples
    )

    $ordered = @($Samples | Sort-Object)
    $count = $ordered.Count
    $p95Index = [math]::Min($count - 1, [math]::Max(0, [math]::Ceiling($count * 0.95) - 1))

    return [pscustomobject]@{
        Count  = $count
        Min    = [math]::Round($ordered[0], 2)
        Median = [math]::Round($ordered[[math]::Floor($count / 2)], 2)
        Mean   = [math]::Round(($ordered | Measure-Object -Average).Average, 2)
        P95    = [math]::Round($ordered[$p95Index], 2)
        Max    = [math]::Round($ordered[$count - 1], 2)
    }
}

function Measure-PromptLatency {

    param(
        [Parameter(Mandatory)][int]$Count
    )

    $samples = [System.Collections.Generic.List[double]]::new()
    for ($index = 0; $index -lt $Count; $index++) {
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        $null = Get-PromptString
        $stopwatch.Stop()
        $samples.Add($stopwatch.Elapsed.TotalMilliseconds)
    }

    return $samples.ToArray()
}

if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
    throw "Module manifest not found at '$manifestPath'."
}

$null = New-Item -ItemType Directory -Path $tempDirectory -Force

try {
    Import-Module $manifestPath -Force
    $module = Get-Module -Name PablitusPrompt | Select-Object -First 1

    if (-not (Test-PPFDotNetCoreAvailable -Refresh)) {
        throw "PablitusPrompt.Core.dll is not available. Run ./scripts/Build-PPFDotNetCore.ps1 first."
    }

    $nativeTheme = New-BenchmarkTheme -Name "BenchmarkNative" -Type "text" -Template "PPF-NATIVE"
    $pluginTheme = New-BenchmarkTheme -Name "BenchmarkPlugin" -Type $pluginName

    Register-PromptSegment -Name $pluginName -Priority 10 -Script {
        param([PromptContext]$Context)

        $null = $Context
        New-PromptSegment -Name "PpfBenchmarkPlugin" -Text "PPF-PLUGIN"
    }
    $pluginRegistered = $true

    # Cold plugin path: host compilation, provider registration, first runspace,
    # module import and first plugin invocation. This runs before any native
    # enable so the measurement includes the one-time Add-Type compilation.
    $coldStopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $null = Enable-PPFDotNetCore -ThemePath $pluginTheme
    $coldOutput = Get-PromptString
    $coldStopwatch.Stop()
    $coldMs = [math]::Round($coldStopwatch.Elapsed.TotalMilliseconds, 2)

    if ($coldOutput -notmatch "PPF-PLUGIN") {
        throw "The cold plugin prompt did not contain the expected plugin output."
    }

    for ($index = 0; $index -lt $WarmupIterations; $index++) {
        $null = Get-PromptString
    }
    $pluginStats = Get-BenchmarkStats -Samples (Measure-PromptLatency -Count $Iterations)

    # Native baseline: .NET engine + built-in text provider.
    $null = Enable-PPFDotNetCore -ThemePath $nativeTheme
    $nativeOutput = Get-PromptString
    if ($nativeOutput -notmatch "PPF-NATIVE") {
        throw "The native prompt did not contain the expected text output."
    }
    for ($index = 0; $index -lt $WarmupIterations; $index++) {
        $null = Get-PromptString
    }
    $nativeStats = Get-BenchmarkStats -Samples (Measure-PromptLatency -Count $Iterations)
    $overheadMs = [math]::Round($pluginStats.Median - $nativeStats.Median, 2)

    $coldPassed = $coldMs -le $ColdBudgetMs
    $warmPassed = $pluginStats.Median -le $WarmBudgetMs
    $overheadPassed = $overheadMs -le $OverheadBudgetMs
    $passed = $coldPassed -and $warmPassed -and $overheadPassed

    $result = [pscustomobject]@{
        PSTypeName       = "PablitusPrompt.DotNetBenchmark"
        TimestampUtc     = [datetime]::UtcNow
        Iterations       = $Iterations
        WarmupIterations = $WarmupIterations
        Native           = $nativeStats
        PluginColdMs     = $coldMs
        PluginWarm       = $pluginStats
        OverheadMs       = $overheadMs
        Budgets          = [pscustomobject]@{
            ColdMs     = $ColdBudgetMs
            WarmMs     = $WarmBudgetMs
            OverheadMs = $OverheadBudgetMs
        }
        Checks           = [pscustomobject]@{
            Cold     = $coldPassed
            Warm     = $warmPassed
            Overhead = $overheadPassed
        }
        Passed           = $passed
    }

    Write-Host ""
    Write-Host "PPF .NET benchmark | $Iterations iterations | $WarmupIterations warmup" -ForegroundColor Cyan
    Write-Host ("Native warm:  median {0} ms | p95 {1} ms" -f $nativeStats.Median, $nativeStats.P95)
    Write-Host ("Plugin cold:  {0} ms (budget {1} ms)" -f $coldMs, $ColdBudgetMs)
    Write-Host ("Plugin warm:  median {0} ms | p95 {1} ms (budget {2} ms)" -f $pluginStats.Median, $pluginStats.P95, $WarmBudgetMs)
    Write-Host ("Plugin delta: {0} ms (budget {1} ms)" -f $overheadMs, $OverheadBudgetMs)

    if ($passed) {
        Write-Host "BUDGET OK" -ForegroundColor Green
    }
    else {
        Write-Host "BUDGET EXCEEDED" -ForegroundColor Red
    }

    if (-not [string]::IsNullOrWhiteSpace($OutputPath)) {
        $resolvedOutput = [System.IO.Path]::GetFullPath($OutputPath)
        $outputDirectory = Split-Path -Parent $resolvedOutput
        if (-not [string]::IsNullOrWhiteSpace($outputDirectory)) {
            $null = New-Item -ItemType Directory -Path $outputDirectory -Force
        }
        $result | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $resolvedOutput -Encoding utf8
        Write-Host "JSON: $resolvedOutput"
    }

    if (-not $NoThreshold -and -not $passed) {
        throw "PPF .NET benchmark exceeded its latency budget."
    }

    return $result
}
finally {
    if (Get-Command Disable-PPFDotNetCore -ErrorAction SilentlyContinue) {
        $null = Disable-PPFDotNetCore
    }

    if ($pluginRegistered -and $null -ne $module) {
        & $module {
            param($name)

            $script:PromptSegments = @(
                $script:PromptSegments |
                    Where-Object Name -ne $name
            )
            $script:PromptSegmentsSorted = $null
            $script:PromptSegmentsVersion = [int]$script:PromptSegmentsVersion + 1
        } $pluginName
    }

    Remove-Item -LiteralPath $tempDirectory -Recurse -Force -ErrorAction SilentlyContinue
}
