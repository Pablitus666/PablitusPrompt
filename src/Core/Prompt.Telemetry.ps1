# ============================================================
# Pablitus Prompt Framework (PPF)
# Prompt.Telemetry.ps1
# ============================================================

# Global Telemetry & Cache counters
if ($null -eq $global:PPF_CacheHits) { $global:PPF_CacheHits = 0 }
if ($null -eq $global:PPF_CacheMisses) { $global:PPF_CacheMisses = 0 }
if ($null -eq $global:PPF_CacheTTLExpired) { $global:PPF_CacheTTLExpired = 0 }
if ($null -eq $global:PPF_CacheRefreshes) { $global:PPF_CacheRefreshes = 0 }
if ($null -eq $global:PPF_BootstrapTimeMs) { $global:PPF_BootstrapTimeMs = 0.0 }

# Logging Levels: TRACE, DEBUG, INFO, WARN, ERROR
$script:LogLevel = "INFO"
$script:LogDir = Join-Path $env:LOCALAPPDATA "PablitusPrompt\logs"
$script:LogFile = Join-Path $script:LogDir "prompt.log"

function Set-PPFLogLevel {
    param(
        [ValidateSet("TRACE", "DEBUG", "INFO", "INFORMATION", "WARN", "WARNING", "ERROR")]
        [string]$Level
    )
    # Normalize level
    $norm = $Level.ToUpper()
    if ($norm -eq "INFORMATION") { $norm = "INFO" }
    elseif ($norm -eq "WARNING") { $norm = "WARN" }
    $script:LogLevel = $norm
}

function Write-PPFLog {
    param(
        [Parameter(Mandatory)]
        [ValidateSet("TRACE", "DEBUG", "INFO", "INFORMATION", "WARN", "WARNING", "ERROR")]
        [string]$Level,

        [Parameter(Mandatory)]
        [string]$Message
    )

    # Normalize level
    $normLevel = $Level.ToUpper()
    if ($normLevel -eq "INFORMATION") { $normLevel = "INFO" }
    elseif ($normLevel -eq "WARNING") { $normLevel = "WARN" }

    # Level weights for filtering
    $levels = @{ "TRACE" = 0; "DEBUG" = 1; "INFO" = 2; "WARN" = 3; "ERROR" = 4 }
    if ($levels[$normLevel] -lt $levels[$script:LogLevel]) {
        return
    }

    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss.fff")
    $logLine = "[$timestamp] [$normLevel] $Message"

    # Write to debug/verbose streams dynamically
    if ($normLevel -eq "ERROR") {
        Write-Error $Message -ErrorAction SilentlyContinue
    }
    elseif ($normLevel -eq "WARN") {
        Write-Warning $Message
    }
    elseif ($normLevel -eq "DEBUG" -or $normLevel -eq "TRACE") {
        Write-Debug $Message -ErrorAction SilentlyContinue
    }
    else {
        Write-Verbose $Message
    }

    # Write to Log File
    try {
        if (-not (Test-Path $script:LogDir)) {
            $null = New-Item -ItemType Directory -Path $script:LogDir -Force
        }
        $logLine | Out-File -FilePath $script:LogFile -Append -Encoding utf8
    }
    catch {
        # Fail silently to avoid breaking the prompt
    }
}

function Measure-Prompt {
    [CmdletBinding()]
    param(
        [string]$Renderer = "Plain"
    )

    Write-PPFLog -Level "INFO" -Message "Running Measure-Prompt Benchmark..."

    # Reset cache stats for cleaner run if desired (or keep them cumulative)
    $startHits = $global:PPF_CacheHits
    $startMisses = $global:PPF_CacheMisses

    # 1. Warm/Cold Start Check
    $isColdStart = $null -eq $global:PPF_LastExecutionTimeMs
    $sw = [System.Diagnostics.Stopwatch]::StartNew()

    # 2. Invoke core logic
    $context = Invoke-Prompt

    # 3. Render prompt
    $renderSw = [System.Diagnostics.Stopwatch]::StartNew()
    $promptStr = Get-PromptString -Context $context -Renderer $Renderer
    $renderSw.Stop()
    $sw.Stop()

    $totalTime = $sw.Elapsed.TotalMilliseconds
    $renderTime = $renderSw.Elapsed.TotalMilliseconds
    $global:PPF_LastExecutionTimeMs = $totalTime

    # Process Stats
    $process = Get-Process -Id $PID
    $memory = $process.WorkingSet64 / 1MB
    $cpuTime = $process.CpuPercent # may not be populated on all systems, fallback to CPU property
    if (-not $cpuTime) {
        $cpuTime = $process.CPU
    }

    # Parse metrics
    $providerTime = 0.0
    $segmentTime = 0.0
    $providerMetrics = [ordered]@{}
    $segmentMetrics = [ordered]@{}

    foreach ($key in ($context.Metrics.Keys | Sort-Object)) {
        if ($key -like "Provider_*_TimeMs" -and $key -notlike "*_ReadTimeMs" -and $key -notlike "*_UpdateTimeMs") {
            $name = $key.Replace("Provider_", "").Replace("_TimeMs", "")
            $val = $context.Metrics[$key]
            if ($null -ne $val) {
                $doubleVal = [double]$val
                $providerMetrics[$name] = $doubleVal
                $providerTime += $doubleVal
            }
        }
        elseif ($key -like "Segment_*_TimeMs") {
            $name = $key.Replace("Segment_", "").Replace("_TimeMs", "")
            $val = $context.Metrics[$key]
            if ($null -ne $val) {
                $doubleVal = [double]$val
                $segmentMetrics[$name] = $doubleVal
                $segmentTime += $doubleVal
            }
        }
    }

    $hitsThisRun = $global:PPF_CacheHits - $startHits
    $missesThisRun = $global:PPF_CacheMisses - $startMisses
    $totalRequests = $hitsThisRun + $missesThisRun
    $hitRatio = 0.0
    if ($totalRequests -gt 0) {
        $hitRatio = ($hitsThisRun / $totalRequests) * 100
    }

    $result = [pscustomobject]@{
        BootstrapTimeMs   = $global:PPF_BootstrapTimeMs
        TotalPromptTimeMs = $totalTime
        RenderingTimeMs   = $renderTime
        ProvidersTotalMs  = $providerTime
        SegmentsTotalMs   = $segmentTime
        ProviderBreakdown = $providerMetrics
        SegmentBreakdown  = $segmentMetrics
        CacheHits         = $hitsThisRun
        CacheMisses       = $missesThisRun
        CacheHitRatio     = $hitRatio
        MemoryUsageMB     = $memory
        CPUTimeSec        = $cpuTime
        IsColdStart       = $isColdStart
        ActiveTheme       = (Get-ActiveTheme).Name
        ActiveRenderer    = $Renderer
        PromptOutput      = $promptStr
     }

    # Print summary
    Write-Host "`n=== Pablitus Prompt Framework Benchmark ===" -ForegroundColor Cyan
    Write-Host "Bootstrap Time:      $([math]::Round([double]$result.BootstrapTimeMs, 2)) ms"
    Write-Host "Total Prompt Time:   $([math]::Round([double]$result.TotalPromptTimeMs, 2)) ms"
    Write-Host "Rendering Time:      $([math]::Round([double]$result.RenderingTimeMs, 2)) ms (Renderer: $($result.ActiveRenderer))"
    Write-Host "Providers Total:     $([math]::Round([double]$result.ProvidersTotalMs, 2)) ms"
    Write-Host "Segments Total:      $([math]::Round([double]$result.SegmentsTotalMs, 2)) ms"
    Write-Host "Cache Stats:         $($result.CacheHits) Hits, $($result.CacheMisses) Misses ($([math]::Round([double]$result.CacheHitRatio, 1))% Hit Ratio)"
    Write-Host "Theme Active:        $($result.ActiveTheme)"
    Write-Host "Process Memory:      $([math]::Round([double]$result.MemoryUsageMB, 2)) MB"
    Write-Host "Process CPU:         $([math]::Round([double]$result.CPUTimeSec, 2)) seconds"
    Write-Host "Start Type:          $(if ($result.IsColdStart) { 'Cold Start' } else { 'Warm Start' })"

    Write-Host "`n--- Providers Breakdown ---" -ForegroundColor Green
    foreach ($k in $result.ProviderBreakdown.Keys) {
        Write-Host "  - $k`: $([math]::Round([double]$result.ProviderBreakdown[$k], 2)) ms"
    }

    Write-Host "`n--- Segments Breakdown ---" -ForegroundColor Green
    foreach ($k in $result.SegmentBreakdown.Keys) {
        Write-Host "  - $k`: $([math]::Round([double]$result.SegmentBreakdown[$k], 2)) ms"
    }
    Write-Host "============================================`n"

    return $result
}


function Get-PPFStatistics {
    param(
        [double[]]$Values
    )
    if ($null -eq $Values -or $Values.Length -eq 0) {
        return [pscustomobject]@{ 
            Min = 0.0; Max = 0.0; Average = 0.0; Median = 0.0; 
            Q1 = 0.0; Q3 = 0.0; P95 = 0.0; P99 = 0.0; StdDev = 0.0; 
            IQR = 0.0; LowerBound = 0.0; UpperBound = 0.0; 
            Outliers = @(); OutliersCount = 0; BoxPlot = "";
            Histogram = @(); Cumulative = @() 
        }
    }
    
    $sorted = $Values | Sort-Object
    $count = $sorted.Length
    $min = $sorted[0]
    $max = $sorted[-1]
    
    $sum = 0.0
    foreach ($v in $sorted) { $sum += $v }
    $avg = $sum / $count
    
    if ($count % 2 -eq 1) {
        $median = $sorted[[math]::Floor($count / 2)]
    } else {
        $mid = $count / 2
        $median = ($sorted[$mid - 1] + $sorted[$mid]) / 2
    }
    
    $q1Index = [math]::Max(0, [math]::Min($count - 1, [math]::Round($count * 0.25) - 1))
    $q1 = $sorted[$q1Index]
    
    $q3Index = [math]::Max(0, [math]::Min($count - 1, [math]::Round($count * 0.75) - 1))
    $q3 = $sorted[$q3Index]
    
    $p95Index = [math]::Max(0, [math]::Min($count - 1, [math]::Round($count * 0.95) - 1))
    $p95 = $sorted[$p95Index]
    
    $p99Index = [math]::Max(0, [math]::Min($count - 1, [math]::Round($count * 0.99) - 1))
    $p99 = $sorted[$p99Index]
    
    $sumSq = 0.0
    foreach ($v in $sorted) { $sumSq += [math]::Pow($v - $avg, 2) }
    $stdDev = [math]::Sqrt($sumSq / $count)
    
    # Outlier Detection (using 1.5 * IQR rule)
    $iqr = $q3 - $q1
    $lowerBound = $q1 - 1.5 * $iqr
    $upperBound = $q3 + 1.5 * $iqr
    $outliers = $sorted | Where-Object { $_ -lt $lowerBound -or $_ -gt $upperBound }
    $outliersList = if ($outliers) { @($outliers) } else { @() }
    $outliersCount = $outliersList.Count

    # Text-based Box Plot generator
    $boxPlot = ""
    if ($max -gt $min) {
        $width = 30
        $range = $max - $min
        $scale = {
            param($val)
            $pct = ($val - $min) / $range
            return [math]::Max(0, [math]::Min($width - 1, [math]::Round($pct * ($width - 1))))
        }
        $minIdx = &$scale $min
        $q1Idx = &$scale $q1
        $medIdx = &$scale $median
        $q3Idx = &$scale $q3
        $maxIdx = &$scale $max

        $chars = [char[]](' ' * $width)
        for ($i = 0; $i -lt $width; $i++) {
            if ($i -ge $q1Idx -and $i -le $q3Idx) {
                $chars[$i] = '='
            } elseif ($i -ge $minIdx -and $i -le $maxIdx) {
                $chars[$i] = '-'
            }
        }
        $chars[$medIdx] = '|'
        $chars[$minIdx] = '['
        $chars[$maxIdx] = ']'
        
        # Overlay outliers with '*' if we can locate them
        foreach ($outlier in $outliersList) {
            $oIdx = &$scale $outlier
            $chars[$oIdx] = '*'
        }
        
        $boxPlot = [string]::new($chars)
    } else {
        $boxPlot = "[  |  ]"
    }

    # Generate 5-bin Histogram
    $binCount = 5
    $histogram = @()
    $range = $max - $min
    if ($range -le 0.001) {
        $histogram += [ordered]@{ Range = "$([math]::Round($min, 2)) ms"; Count = $count; Percentage = 100.0 }
    }
    else {
        $binWidth = $range / $binCount
        for ($i = 0; $i -lt $binCount; $i++) {
            $binStart = $min + ($i * $binWidth)
            $binEnd = $binStart + $binWidth
            $inBin = if ($i -eq $binCount - 1) {
                $sorted | Where-Object { $_ -ge $binStart -and $_ -le $binEnd }
            } else {
                $sorted | Where-Object { $_ -ge $binStart -and $_ -lt $binEnd }
            }
            $binCountVal = if ($inBin) { @($inBin).Length } else { 0 }
            $binPct = ($binCountVal / $count) * 100
            $histogram += [pscustomobject]@{
                Range      = "$([math]::Round($binStart, 2)) - $([math]::Round($binEnd, 2)) ms"
                Count      = $binCountVal
                Percentage = [math]::Round($binPct, 2)
            }
        }
    }

    # Cumulative distribution curve points
    $cumulative = @(
        [pscustomobject]@{ Label = "Min"; Value = $min; CumulativePercent = 0.0 }
        [pscustomobject]@{ Label = "Q1"; Value = $q1; CumulativePercent = 25.0 }
        [pscustomobject]@{ Label = "Median"; Value = $median; CumulativePercent = 50.0 }
        [pscustomobject]@{ Label = "Q3"; Value = $q3; CumulativePercent = 75.0 }
        [pscustomobject]@{ Label = "P95"; Value = $p95; CumulativePercent = 95.0 }
        [pscustomobject]@{ Label = "P99"; Value = $p99; CumulativePercent = 99.0 }
        [pscustomobject]@{ Label = "Max"; Value = $max; CumulativePercent = 100.0 }
    )
    
    return [pscustomobject]@{
        Min           = $min
        Max           = $max
        Average       = $avg
        Median        = $median
        Q1            = $q1
        Q3            = $q3
        P95           = $p95
        P99           = $p99
        StdDev        = $stdDev
        IQR           = $iqr
        LowerBound    = $lowerBound
        UpperBound    = $upperBound
        Outliers      = $outliersList
        OutliersCount = $outliersCount
        BoxPlot       = $boxPlot
        Histogram     = $histogram
        Cumulative    = $cumulative
    }
}

function Measure-PromptDetailed {
    [CmdletBinding()]
    param(
        [string]$Renderer = "Plain",
        [string]$ExportDir = "benchmarks",
        [int]$Iterations = 100
    )

    Write-PPFLog -Level "INFO" -Message "Running statistical benchmark with $Iterations iterations..."

    $totalTimes = New-Object System.Collections.Generic.List[double]
    $renderTimes = New-Object System.Collections.Generic.List[double]
    
    $providerTimes = @{} 
    $segmentTimes = @{}  
    
    $bootstrapTime = $global:PPF_BootstrapTimeMs

    # Track cache stats at beginning
    $startHits = $global:PPF_CacheHits
    $startMisses = $global:PPF_CacheMisses
    $startExpirations = $global:PPF_CacheTTLExpired
    $startRefreshes = $global:PPF_CacheRefreshes

    for ($i = 0; $i -lt $Iterations; $i++) {
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        $context = Invoke-Prompt
        
        $renderSw = [System.Diagnostics.Stopwatch]::StartNew()
        $null = Get-PromptString -Context $context -Renderer $Renderer
        $renderSw.Stop()
        $sw.Stop()
        
        $totalTimes.Add($sw.Elapsed.TotalMilliseconds)
        $renderTimes.Add($renderSw.Elapsed.TotalMilliseconds)
        
        foreach ($key in $context.Metrics.Keys) {
            if ($key -like "Provider_*") {
                $name = $key.Replace("Provider_", "").Replace("_TimeMs", "")
                if (-not $providerTimes.ContainsKey($name)) {
                    $providerTimes[$name] = New-Object System.Collections.Generic.List[double]
                }
                $providerTimes[$name].Add($context.Metrics[$key])
            }
            elseif ($key -like "Segment_*") {
                $name = $key.Replace("Segment_", "").Replace("_TimeMs", "")
                if (-not $segmentTimes.ContainsKey($name)) {
                    $segmentTimes[$name] = New-Object System.Collections.Generic.List[double]
                }
                $segmentTimes[$name].Add($context.Metrics[$key])
            }
        }
    }

    # Track cache stats at end
    $endHits = $global:PPF_CacheHits - $startHits
    $endMisses = $global:PPF_CacheMisses - $startMisses
    $endExpirations = $global:PPF_CacheTTLExpired - $startExpirations
    $endRefreshes = $global:PPF_CacheRefreshes - $startRefreshes

    # Compute Statistics
    $totalStats = Get-PPFStatistics -Values $totalTimes.ToArray()
    $renderStats = Get-PPFStatistics -Values $renderTimes.ToArray()
    
    $providerStats = [ordered]@{}
    foreach ($p in ($providerTimes.Keys | Sort-Object)) {
        $providerStats[$p] = Get-PPFStatistics -Values $providerTimes[$p].ToArray()
    }
    
    $segmentStats = [ordered]@{}
    foreach ($s in ($segmentTimes.Keys | Sort-Object)) {
        $segmentStats[$s] = Get-PPFStatistics -Values $segmentTimes[$s].ToArray()
    }

    # Format output for console
    $sb = New-Object System.Text.StringBuilder
    [void]$sb.AppendLine("PPF Detailed Performance Report ($Iterations iterations)")
    [void]$sb.AppendLine("==========================================================================")
    [void]$sb.AppendLine("Bootstrap: $([math]::Round($bootstrapTime, 2)) ms")
    [void]$sb.AppendLine("Cache: $endHits Hits, $endMisses Misses, $endExpirations Expired, $endRefreshes Refreshes")
    [void]$sb.AppendLine("--------------------------------------------------------------------------")
    [void]$sb.AppendLine(("{0,-20} | {1,8} | {2,8} | {3,8} | {4,8} | {5,8} | {6,8} | {7,8}" -f "Component", "Min(ms)", "Q1(ms)", "Avg(ms)", "Med(ms)", "Q3(ms)", "Max(ms)", "StdDev"))
    [void]$sb.AppendLine("--------------------------------------------------------------------------")
    
    # Total & Renderer
    [void]$sb.AppendLine(("{0,-20} | {1,8:F2} | {2,8:F2} | {3,8:F2} | {4,8:F2} | {5:F2} | {6:F2} | {7,8:F2}" -f "TOTAL (Prompt)", $totalStats.Min, $totalStats.Q1, $totalStats.Average, $totalStats.Median, $totalStats.Q3, $totalStats.Max, $totalStats.StdDev))
    [void]$sb.AppendLine(("{0,-20} | {1,8:F2} | {2,8:F2} | {3,8:F2} | {4,8:F2} | {5:F2} | {6:F2} | {7,8:F2}" -f "Renderer ($Renderer)", $renderStats.Min, $renderStats.Q1, $renderStats.Average, $renderStats.Median, $renderStats.Q3, $renderStats.Max, $renderStats.StdDev))
    [void]$sb.AppendLine("--------------------------------------------------------------------------")
    
    # Providers
    [void]$sb.AppendLine("Providers:")
    foreach ($p in $providerStats.Keys) {
        $st = $providerStats[$p]
        [void]$sb.AppendLine(("  {0,-18} | {1,8:F2} | {2,8:F2} | {3,8:F2} | {4,8:F2} | {5,8:F2} | {6:F2} | {7,8:F2}" -f $p, $st.Min, $st.Q1, $st.Average, $st.Median, $st.Q3, $st.Max, $st.StdDev))
    }
    
    [void]$sb.AppendLine("--------------------------------------------------------------------------")
    # Segments
    [void]$sb.AppendLine("Segments:")
    foreach ($s in $segmentStats.Keys) {
        $st = $segmentStats[$s]
        [void]$sb.AppendLine(("  {0,-18} | {1,8:F2} | {2,8:F2} | {3,8:F2} | {4,8:F2} | {5:F2} | {6:F2} | {7,8:F2}" -f $s, $st.Min, $st.Q1, $st.Average, $st.Median, $st.Q3, $st.Max, $st.StdDev))
    }
    [void]$sb.AppendLine("==========================================================================")

    # Box Plots & Outliers
    [void]$sb.AppendLine("BOX PLOTS & OUTLIERS DETECTED:")
    [void]$sb.AppendLine(("{0,-20} | {1,-30} | {2,10}" -f "Component", "Box Plot [Min ==Med== Max]", "Outliers"))
    [void]$sb.AppendLine("--------------------------------------------------------------------------")
    [void]$sb.AppendLine(("{0,-20} | {1,-30} | {2,10}" -f "TOTAL (Prompt)", $totalStats.BoxPlot, $totalStats.OutliersCount))
    [void]$sb.AppendLine(("{0,-20} | {1,-30} | {2,10}" -f "Renderer ($Renderer)", $renderStats.BoxPlot, $renderStats.OutliersCount))
    foreach ($p in $providerStats.Keys) {
        [void]$sb.AppendLine(("{0,-20} | {1,-30} | {2,10}" -f "Prov: $p", $providerStats[$p].BoxPlot, $providerStats[$p].OutliersCount))
    }
    [void]$sb.AppendLine("==========================================================================")

    # Console Histogram
    [void]$sb.AppendLine("TOTAL LATENCY HISTOGRAM:")
    foreach ($bin in $totalStats.Histogram) {
        $barWidth = [math]::Round($bin.Percentage / 4)
        $bar = if ($barWidth -gt 0) { "#" * $barWidth } else { "" }
        [void]$sb.AppendLine(("  {0,-20} | {1,5} ({2,6:F2}%) | {3}" -f $bin.Range, $bin.Count, $bin.Percentage, $bar))
    }
    [void]$sb.AppendLine("==========================================================================")

    $reportText = $sb.ToString()
    Write-Host $reportText -ForegroundColor Cyan

    # Ensure export directory exists
    $fullExportDir = $ExportDir
    if (-not [System.IO.Path]::IsPathRooted($fullExportDir)) {
        $installRoot = if ($global:PPF_InstallRoot) { $global:PPF_InstallRoot } else { Get-Location }
        $workspaceRoot = Split-Path $installRoot -Parent
        $fullExportDir = Join-Path $workspaceRoot $ExportDir
    }

    try {
        if (-not (Test-Path $fullExportDir)) {
            $null = New-Item -ItemType Directory -Path $fullExportDir -Force
        }

        # 2. Export JSON
        $jsonObj = [ordered]@{
            Timestamp      = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
            Iterations     = $Iterations
            BootstrapMs    = $bootstrapTime
            CacheStats     = [ordered]@{
                Hits        = $endHits
                Misses      = $endMisses
                Expirations = $endExpirations
                Refreshes   = $endRefreshes
            }
            TotalStats     = $totalStats
            RendererStats  = $renderStats
            RendererName   = $Renderer
            ProviderStats  = $providerStats
            SegmentStats   = $segmentStats
        }
        $jsonPath = Join-Path $fullExportDir "benchmark_report.json"
        $jsonObj | ConvertTo-Json -Depth 6 | Out-File -FilePath $jsonPath -Encoding utf8

        # 3. Export CSV
        $csvPath = Join-Path $fullExportDir "benchmark_report.csv"
        $csvRows = @()
        
        $makeRow = {
            param($cat, $comp, $st)
            [pscustomobject]@{
                Category    = $cat
                Component   = $comp
                MinMs       = $st.Min
                Q1Ms        = $st.Q1
                MedianMs    = $st.Median
                Q3Ms        = $st.Q3
                MaxMs       = $st.Max
                AverageMs   = $st.Average
                P95Ms       = $st.P95
                P99Ms       = $st.P99
                StdDevMs    = $st.StdDev
            }
        }
        
        $csvRows += &$makeRow "Total" "Prompt" $totalStats
        $csvRows += &$makeRow "Renderer" $Renderer $renderStats
        foreach ($p in $providerStats.Keys) {
            $csvRows += &$makeRow "Provider" $p $providerStats[$p]
        }
        foreach ($s in $segmentStats.Keys) {
            $csvRows += &$makeRow "Segment" $s $segmentStats[$s]
        }
        $csvRows | Export-Csv -Path $csvPath -NoTypeInformation -Encoding utf8

        # 4. Export Markdown
        $mdPath = Join-Path $fullExportDir "benchmark_report.md"
        $mdSb = New-Object System.Text.StringBuilder
        [void]$mdSb.AppendLine("# PPF Statistical Performance Report")
        [void]$mdSb.AppendLine("Generado el: $((Get-Date).ToString('yyyy-MM-dd HH:mm:ss')) | Iteraciones: $Iterations")
        [void]$mdSb.AppendLine()
        [void]$mdSb.AppendLine("## Resumen de Cache")
        [void]$mdSb.AppendLine("- **Hits**: $endHits")
        [void]$mdSb.AppendLine("- **Misses**: $endMisses")
        [void]$mdSb.AppendLine("- **Expiraciones**: $endExpirations")
        [void]$mdSb.AppendLine("- **Refrescos (Writes)**: $endRefreshes")
        [void]$mdSb.AppendLine()
        [void]$mdSb.AppendLine("## Métricas Principales")
        [void]$mdSb.AppendLine("| Categoría | Componente | Mín (ms) | Q1 (ms) | Mediana (ms) | Q3 (ms) | Máx (ms) | Promedio (ms) | P95 (ms) | P99 (ms) | Desv. Est. (ms) |")
        [void]$mdSb.AppendLine("| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |")
        [void]$mdSb.AppendLine(("| **Total** | Prompt | {0:F2} | {1:F2} | {2:F2} | {3:F2} | {4:F2} | {5:F2} | {6:F2} | {7:F2} | {8:F2} |" -f $totalStats.Min, $totalStats.Q1, $totalStats.Median, $totalStats.Q3, $totalStats.Max, $totalStats.Average, $totalStats.P95, $totalStats.P99, $totalStats.StdDev))
        [void]$mdSb.AppendLine(("| **Renderer** | $Renderer | {0:F2} | {1:F2} | {2:F2} | {3:F2} | {4:F2} | {5:F2} | {6:F2} | {7:F2} | {8:F2} |" -f $renderStats.Min, $renderStats.Q1, $renderStats.Median, $renderStats.Q3, $renderStats.Max, $renderStats.Average, $renderStats.P95, $renderStats.P99, $renderStats.StdDev))
        
        foreach ($p in $providerStats.Keys) {
            $st = $providerStats[$p]
            [void]$mdSb.AppendLine(("| Provider | $p | {0:F2} | {1:F2} | {2:F2} | {3:F2} | {4:F2} | {5:F2} | {6:F2} | {7:F2} | {8:F2} |" -f $st.Min, $st.Q1, $st.Median, $st.Q3, $st.Max, $st.Average, $st.P95, $st.P99, $st.StdDev))
        }
        foreach ($s in $segmentStats.Keys) {
            $st = $segmentStats[$s]
            [void]$mdSb.AppendLine(("| Segment | $s | {0:F2} | {1:F2} | {2:F2} | {3:F2} | {4:F2} | {5:F2} | {6:F2} | {7:F2} | {8:F2} |" -f $st.Min, $st.Q1, $st.Median, $st.Q3, $st.Max, $st.Average, $st.P95, $st.P99, $st.StdDev))
        }

        [void]$mdSb.AppendLine()
        [void]$mdSb.AppendLine("## Histograma de Latencia Total")
        [void]$mdSb.AppendLine("| Rango de Tiempo | Frecuencia | Porcentaje | Gráfico |")
        [void]$mdSb.AppendLine("| --- | --- | --- | --- |")
        foreach ($bin in $totalStats.Histogram) {
            $barWidth = [math]::Round($bin.Percentage / 4)
            $bar = if ($barWidth -gt 0) { "#" * $barWidth } else { "" }
            [void]$mdSb.AppendLine(("| {0} | {1} | {2:F2}% | {3} |" -f $bin.Range, $bin.Count, $bin.Percentage, $bar))
        }

        [void]$mdSb.AppendLine()
        [void]$mdSb.AppendLine("## Curva Acumulativa de Latencia")
        [void]$mdSb.AppendLine("| Hito | Valor Límite (ms) | Porcentaje Acumulado |")
        [void]$mdSb.AppendLine("| --- | --- | --- |")
        foreach ($pt in $totalStats.Cumulative) {
            [void]$mdSb.AppendLine(("| {0} | {1:F2} ms | {2:F1}% |" -f $pt.Label, $pt.Value, $pt.CumulativePercent))
        }
        $mdSb.ToString() | Out-File -FilePath $mdPath -Encoding utf8

        # 5. Export HTML
        $htmlPath = Join-Path $fullExportDir "benchmark_report.html"
        $htmlSb = New-Object System.Text.StringBuilder
        [void]$htmlSb.AppendLine("<html><head><style>")
        [void]$htmlSb.AppendLine("body { font-family: Arial, sans-serif; background-color: #1e1e2e; color: #cdd6f4; margin: 20px; }")
        [void]$htmlSb.AppendLine("h1, h2 { color: #f5c2e7; }")
        [void]$htmlSb.AppendLine("table { width: 100%; border-collapse: collapse; margin-top: 15px; margin-bottom: 25px; }")
        [void]$htmlSb.AppendLine("th, td { border: 1px solid #45475a; padding: 10px; text-align: left; }")
        [void]$htmlSb.AppendLine("th { background-color: #313244; color: #a6adc8; }")
        [void]$htmlSb.AppendLine("tr:nth-child(even) { background-color: #181825; }")
        [void]$htmlSb.AppendLine(".highlight { font-weight: bold; color: #a6e3a1; }")
        [void]$htmlSb.AppendLine(".bar-container { background-color: #313244; width: 100%; border-radius: 4px; overflow: hidden; }")
        [void]$htmlSb.AppendLine(".bar { background: linear-gradient(90deg, #a6e3a1, #89b4fa); height: 16px; border-radius: 4px; }")
        [void]$htmlSb.AppendLine("</style></head><body>")
        [void]$htmlSb.AppendLine("<h1>PPF Statistical Performance Report</h1>")
        [void]$htmlSb.AppendLine("<p>Generado el: $((Get-Date).ToString('yyyy-MM-dd HH:mm:ss')) | Iteraciones: $Iterations</p>")
        
        [void]$htmlSb.AppendLine("<h2>Resumen de Cache</h2>")
        [void]$htmlSb.AppendLine("<ul>")
        [void]$htmlSb.AppendLine("<li><b>Cache Hits:</b> $endHits</li>")
        [void]$htmlSb.AppendLine("<li><b>Cache Misses:</b> $endMisses</li>")
        [void]$htmlSb.AppendLine("<li><b>Expiraciones (TTL):</b> $endExpirations</li>")
        [void]$htmlSb.AppendLine("<li><b>Refrescos (Writes):</b> $endRefreshes</li>")
        [void]$htmlSb.AppendLine("</ul>")

        [void]$htmlSb.AppendLine("<h2>Métricas Principales</h2>")
        [void]$htmlSb.AppendLine("<table>")
        [void]$htmlSb.AppendLine("<tr><th>Categoría</th><th>Componente</th><th>Mín (ms)</th><th>Q1 (ms)</th><th>Mediana (ms)</th><th>Q3 (ms)</th><th>Máx (ms)</th><th>Promedio (ms)</th><th>P95 (ms)</th><th>P99 (ms)</th><th>Desv. Est. (ms)</th></tr>")
        
        [void]$htmlSb.AppendLine(("<tr class='highlight'><td>Total</td><td>Prompt</td><td>{0:F2}</td><td>{1:F2}</td><td>{2:F2}</td><td>{3:F2}</td><td>{4:F2}</td><td>{5:F2}</td><td>{6:F2}</td><td>{7:F2}</td><td>{8:F2}</td></tr>" -f $totalStats.Min, $totalStats.Q1, $totalStats.Median, $totalStats.Q3, $totalStats.Max, $totalStats.Average, $totalStats.P95, $totalStats.P99, $totalStats.StdDev))
        [void]$htmlSb.AppendLine(("<tr class='highlight'><td>Renderer</td><td>$Renderer</td><td>{0:F2}</td><td>{1:F2}</td><td>{2:F2}</td><td>{3:F2}</td><td>{4:F2}</td><td>{5:F2}</td><td>{6:F2}</td><td>{7:F2}</td><td>{8:F2}</td></tr>" -f $renderStats.Min, $renderStats.Q1, $renderStats.Median, $renderStats.Q3, $renderStats.Max, $renderStats.Average, $renderStats.P95, $renderStats.P99, $renderStats.StdDev))
        
        foreach ($p in $providerStats.Keys) {
            $st = $providerStats[$p]
            [void]$htmlSb.AppendLine(("<tr><td>Provider</td><td>$p</td><td>{0:F2}</td><td>{1:F2}</td><td>{2:F2}</td><td>{3:F2}</td><td>{4:F2}</td><td>{5:F2}</td><td>{6:F2}</td><td>{7:F2}</td><td>{8:F2}</td></tr>" -f $st.Min, $st.Q1, $st.Median, $st.Q3, $st.Max, $st.Average, $st.P95, $st.P99, $st.StdDev))
        }
        foreach ($s in $segmentStats.Keys) {
            $st = $segmentStats[$s]
            [void]$htmlSb.AppendLine(("<tr><td>Segment</td><td>$s</td><td>{0:F2}</td><td>{1:F2}</td><td>{2:F2}</td><td>{3:F2}</td><td>{4:F2}</td><td>{5:F2}</td><td>{6:F2}</td><td>{7:F2}</td><td>{8:F2}</td></tr>" -f $st.Min, $st.Q1, $st.Median, $st.Q3, $st.Max, $st.Average, $st.P95, $st.P99, $st.StdDev))
        }
        [void]$htmlSb.AppendLine("</table>")

        [void]$htmlSb.AppendLine("<h2>Histograma de Latencia Total</h2>")
        [void]$htmlSb.AppendLine("<table>")
        [void]$htmlSb.AppendLine("<tr><th>Rango de Tiempo</th><th>Frecuencia</th><th>Porcentaje</th><th>Distribución Visual</th></tr>")
        foreach ($bin in $totalStats.Histogram) {
            [void]$htmlSb.AppendLine(("<tr><td>{0}</td><td>{1}</td><td>{2:F2}%</td><td><div class='bar-container'><div class='bar' style='width: {2}%;'></div></div></td></tr>" -f $bin.Range, $bin.Count, $bin.Percentage))
        }
        [void]$htmlSb.AppendLine("</table>")

        [void]$htmlSb.AppendLine("<h2>Curva Acumulativa de Latencia</h2>")
        [void]$htmlSb.AppendLine("<table>")
        [void]$htmlSb.AppendLine("<tr><th>Punto de Control</th><th>Valor de Tiempo (ms)</th><th>Porcentaje Acumulado</th></tr>")
        foreach ($pt in $totalStats.Cumulative) {
            [void]$htmlSb.AppendLine(("<tr><td>{0}</td><td>{1:F2} ms</td><td>{2:F1}%</td></tr>" -f $pt.Label, $pt.Value, $pt.CumulativePercent))
        }
        [void]$htmlSb.AppendLine("</table>")

        [void]$htmlSb.AppendLine("</body></html>")
        $htmlSb.ToString() | Out-File -FilePath $htmlPath -Encoding utf8

        Write-Host "Reportes estadísticos detallados exportados exitosamente a '$fullExportDir'" -ForegroundColor Green
    }
    catch {
        Write-Warning "Fallo al exportar los reportes detallados: $_"
    }

    return $jsonObj
}

function Test-PromptFramework {
    [CmdletBinding()]
    param(
        [switch]$RunTests
    )

    Write-Host "`n=== Pablitus Prompt Framework Diagnostic ===" -ForegroundColor Cyan
    $warnings = @()
    $checks = [ordered]@{}

    # 1. Structure
    $root = if ($global:PPF_InstallRoot) { $global:PPF_InstallRoot } else { Join-Path (Get-Location) "src" }
    $requiredFolders = @("Core", "Modules", "Renderers", "Themes", "Utils")
    $folderOk = $true
    foreach ($f in $requiredFolders) {
        if (-not (Test-Path (Join-Path $root $f))) {
            $folderOk = $false
            $warnings += "Carpeta requerida '$f' no existe en la raíz."
        }
    }
    $checks["Structure"] = if ($folderOk) { "OK" } else { "WARN" }

    # 2. Key components count
    $providers = $script:PromptProviders
    $segments = $script:PromptSegments
    $renderers = Get-PromptRenderers
    $themes = Get-PromptTheme
    
    $checks["Providers"] = if ($providers.Count -gt 0) { "OK ($($providers.Count) registrados)" } else { "WARN (Ninguno registrado)" }
    $checks["Segments"] = if ($segments.Count -gt 0) { "OK ($($segments.Count) registrados)" } else { "WARN (Ninguno registrado)" }
    $checks["Renderers"] = if ($renderers.Count -gt 0) { "OK ($($renderers.Count) registrados)" } else { "WARN (Ninguno registrado)" }
    $checks["Themes"] = if ($themes.Count -gt 0) { "OK ($($themes.Count) registrados)" } else { "WARN (Ninguno registrado)" }

    if ($providers.Count -eq 0) { $warnings += "No hay proveedores de contexto registrados." }
    if ($segments.Count -eq 0) { $warnings += "No hay segmentos visuales registrados." }
    if ($renderers.Count -eq 0) { $warnings += "No hay renderizadores registrados." }
    if ($themes.Count -eq 0) { $warnings += "No hay temas registrados." }

    # 3. Cache
    $cacheOk = Test-Path $script:CacheDir
    $checks["Cache"] = if ($cacheOk) { "OK" } else { "WARN (No inicializada)" }
    if (-not $cacheOk) { $warnings += "El directorio de caché no existe." }

    # Write permissions check on Cache and Log directories
    $testWrite = {
        param($dir)
        if (-not (Test-Path $dir)) { return $false }
        $tempFile = Join-Path $dir "perm_test_$([Guid]::NewGuid()).tmp"
        try {
            [System.IO.File]::WriteAllText($tempFile, "test")
            [System.IO.File]::Delete($tempFile)
            return $true
        } catch {
            return $false
        }
    }
    $cacheWriteOk = $false
    if ($cacheOk) {
        $cacheWriteOk = &$testWrite $script:CacheDir
    }
    $logDir = Split-Path $script:LogFile
    $logWriteOk = &$testWrite $logDir
    
    $checks["Permissions"] = if ($cacheWriteOk -and $logWriteOk) { "OK (Escritura verificada)" } else { "WARN" }
    if (-not $cacheWriteOk -and $cacheOk) { $warnings += "No se puede escribir en el directorio de caché '$script:CacheDir'." }
    if (-not $logWriteOk) { $warnings += "No se puede escribir en el directorio de logs '$logDir'." }


    # 4. Events
    $checks["Events"] = "OK"

    # 5. Configuration
    $config = Get-PromptConfiguration
    $configOk = $null -ne $config
    $checks["Configuration"] = if ($configOk) { "OK (Tema: $($config.Theme['Name']), Renderer: $($config.Renderer['Default']))" } else { "FAIL" }
    if (-not $configOk) { $warnings += "No se pudo recuperar la configuración del prompt." }

    # 6. PowerShell version & compatibility
    $psVersion = $PSVersionTable.PSVersion
    $checks["PowerShell"] = "OK (v$psVersion)"

    # 7. Dependencies
    $deps = @("git", "node", "python", "docker")
    $depStatus = @()
    foreach ($d in $deps) {
        if (Get-Command $d -ErrorAction SilentlyContinue) {
            $depStatus += "$($d): OK"
        } else {
            $depStatus += "$($d): MISSING"
        }
    }
    $checks["Dependencies"] = $depStatus -join ", "

    # 8. Bootstrap performance
    $bootTime = $global:PPF_BootstrapTimeMs
    $checks["Performance"] = "$([math]::Round($bootTime, 2)) ms (Bootstrap)"

    # 9. Logs
    $logSize = 0
    if (Test-Path $script:LogFile) {
        $logSize = (Get-Item -Force $script:LogFile).Length / 1KB
        $checks["Logs"] = "OK ($([math]::Round($logSize, 2)) KB)"
    } else {
        $checks["Logs"] = "WARN (Archivo no encontrado)"
        $warnings += "El archivo de log no existe."
    }

    # 10. Optional Pester tests execution
    if ($RunTests) {
        if ($global:PPF_InsidePester) {
            $checks["Tests"] = "SKIPPED (Prevención de recursión Pester)"
        }
        elseif (Get-Command Invoke-Pester -ErrorAction SilentlyContinue) {
            try {
                $srcParent = Split-Path $root -Parent
                $testPath = Join-Path $srcParent "tests\Prompt.Tests.ps1"
                if (Test-Path $testPath) {
                    $pesterRun = Invoke-Pester -Path $testPath -PassThru -ErrorAction SilentlyContinue
                    $checks["Tests"] = "$($pesterRun.PassedCount)/$($pesterRun.TotalCount) PASS"
                    if ($pesterRun.FailedCount -gt 0) {
                        $warnings += "$($pesterRun.FailedCount) pruebas de Pester fallaron."
                    }
                } else {
                    $checks["Tests"] = "WARN (Archivo de tests no encontrado)"
                    $warnings += "No se encontró el archivo de pruebas en '$testPath'."
                }
            }
            catch {
                $checks["Tests"] = "FAIL (Error al ejecutar)"
                $warnings += "Error ejecutando Pester: $_"
            }
        }
        else {
            $checks["Tests"] = "WARN (Pester no instalado)"
            $warnings += "Pester no está instalado en este sistema."
        }
    }
    else {
        $checks["Tests"] = "SKIPPED (Usa -RunTests para ejecutar)"
    }

    # Print check table
    foreach ($k in $checks.Keys) {
        $dots = "." * [math]::Max(2, (25 - $k.Length))
        $val = $checks[$k]
        $color = "Green"
        if ($val -like "WARN*" -or $val -like "*MISSING*" -or $val -like "*SKIPPED*") {
            $color = "Yellow"
        }
        elseif ($val -like "FAIL*" -or $val -like "0/*") {
            $color = "Red"
        }
        Write-Host "$k$dots" -NoNewline
        Write-Host " $val" -ForegroundColor $color
    }

    # Health Score Calculation
    $score = 100 - ($warnings.Count * 8)
    if ($score -lt 0) { $score = 0 }

    Write-Host "`nOverall Health Score" -ForegroundColor Cyan
    $scoreColor = "Green"
    if ($score -lt 50) { $scoreColor = "Red" }
    elseif ($score -lt 85) { $scoreColor = "Yellow" }
    Write-Host "  $score / 100" -ForegroundColor $scoreColor

    if ($warnings.Count -gt 0) {
        Write-Host "`nAdvertencias / Recomendaciones:" -ForegroundColor Yellow
        foreach ($w in $warnings) {
            Write-Host "  - $w" -ForegroundColor Yellow
        }
    } else {
        Write-Host "`n¡El framework goza de una salud perfecta!" -ForegroundColor Green
    }
    Write-Host "============================================`n"

    return [pscustomobject]@{
        HealthScore = $score
        Checks      = $checks
        Warnings    = $warnings
    }
}

function Measure-PromptProvider {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [int]$Iterations = 100,

        [switch]$Cold
    )

    $providers = Get-PromptProviders
    $provider = $providers | Where-Object Name -eq $Name
    if (-not $provider) {
        throw "Provider '$Name' is not registered."
    }

    $times = New-Object System.Collections.Generic.List[double]
    $context = New-PromptContext

    # Warm up / check
    if ($Cold) {
        Clear-AllPPFCache
    }
    
    # Run iterations
    for ($i = 0; $i -lt $Iterations; $i++) {
        if ($Cold) {
            Clear-AllPPFCache
        }
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        try {
            & $provider.Script $context
        }
        catch {
            # Ignore errors
        }
        $sw.Stop()
        $times.Add($sw.Elapsed.TotalMilliseconds)
    }

    $stats = Get-PPFStatistics -Values $times.ToArray()
    return $stats
}

function Measure-CpuProvider {
    param([int]$Iterations = 100, [switch]$Cold)
    Measure-PromptProvider -Name "CPU" -Iterations $Iterations -Cold:$Cold
}

function Measure-MemoryProvider {
    param([int]$Iterations = 100, [switch]$Cold)
    Measure-PromptProvider -Name "Memory" -Iterations $Iterations -Cold:$Cold
}

function Measure-BatteryProvider {
    param([int]$Iterations = 100, [switch]$Cold)
    Measure-PromptProvider -Name "Battery" -Iterations $Iterations -Cold:$Cold
}

function Measure-GitProvider {
    param([int]$Iterations = 100, [switch]$Cold)
    Measure-PromptProvider -Name "Git" -Iterations $Iterations -Cold:$Cold
}

function Measure-DockerProvider {
    param([int]$Iterations = 100, [switch]$Cold)
    Measure-PromptProvider -Name "Docker" -Iterations $Iterations -Cold:$Cold
}

function Measure-KubernetesProvider {
    param([int]$Iterations = 100, [switch]$Cold)
    Measure-PromptProvider -Name "Kubernetes" -Iterations $Iterations -Cold:$Cold
}

function Measure-NodeProvider {
    param([int]$Iterations = 100, [switch]$Cold)
    Measure-PromptProvider -Name "Node" -Iterations $Iterations -Cold:$Cold
}

function Measure-PythonProvider {
    param([int]$Iterations = 100, [switch]$Cold)
    Measure-PromptProvider -Name "Python" -Iterations $Iterations -Cold:$Cold
}

function Measure-SessionProvider {
    param([int]$Iterations = 100, [switch]$Cold)
    Measure-PromptProvider -Name "Session" -Iterations $Iterations -Cold:$Cold
}

function Measure-ProjectProvider {
    param([int]$Iterations = 100, [switch]$Cold)
    Measure-PromptProvider -Name "Project" -Iterations $Iterations -Cold:$Cold
}

function Measure-PathProvider {
    param([int]$Iterations = 100, [switch]$Cold)
    Measure-PromptProvider -Name "Path" -Iterations $Iterations -Cold:$Cold
}

function Measure-WslProvider {
    param([int]$Iterations = 100, [switch]$Cold)
    Measure-PromptProvider -Name "WSL" -Iterations $Iterations -Cold:$Cold
}

function Measure-DotNetProvider {
    param([int]$Iterations = 100, [switch]$Cold)
    Measure-PromptProvider -Name "DotNet" -Iterations $Iterations -Cold:$Cold
}


function Measure-PromptCacheComparison {
    [CmdletBinding()]
    param(
        [int]$Iterations = 50
    )

    Write-Host "`n=== Pablitus Prompt Framework Cache Benchmark Comparison ===" -ForegroundColor Cyan
    
    # 1. Cold Cache (First Run)
    Clear-AllPPFCache
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $null = Invoke-Prompt
    $sw.Stop()
    $coldFirstMs = $sw.Elapsed.TotalMilliseconds

    # 2. Hot Cache (Average of N iterations with cache populated)
    $hotTimes = New-Object System.Collections.Generic.List[double]
    for ($i = 0; $i -lt $Iterations; $i++) {
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        $null = Invoke-Prompt
        $sw.Stop()
        $hotTimes.Add($sw.Elapsed.TotalMilliseconds)
    }
    $hotStats = Get-PPFStatistics -Values $hotTimes.ToArray()

    # 3. Cold Cache Iterated (Average of N iterations, clearing cache before each run)
    $coldTimes = New-Object System.Collections.Generic.List[double]
    for ($i = 0; $i -lt $Iterations; $i++) {
        Clear-AllPPFCache
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        $null = Invoke-Prompt
        $sw.Stop()
        $coldTimes.Add($sw.Elapsed.TotalMilliseconds)
    }
    $coldStats = Get-PPFStatistics -Values $coldTimes.ToArray()

    # Speedup factor
    $speedup = 0.0
    if ($hotStats.Average -gt 0) {
        $speedup = $coldStats.Average / $hotStats.Average
    }

    Write-Host "Cold Start (First Run):  $([math]::Round($coldFirstMs, 2)) ms"
    Write-Host "Cold Cache (Average):    $([math]::Round($coldStats.Average, 2)) ms (Min: $([math]::Round($coldStats.Min, 2)) ms, Max: $([math]::Round($coldStats.Max, 2)) ms)"
    Write-Host "Hot Cache (Average):     $([math]::Round($hotStats.Average, 2)) ms (Min: $([math]::Round($hotStats.Min, 2)) ms, Max: $([math]::Round($hotStats.Max, 2)) ms)"
    Write-Host "Cache Speedup Factor:    $([math]::Round($speedup, 1))x faster with Hot Cache" -ForegroundColor Green
    Write-Host "============================================================" -ForegroundColor Cyan

    return [pscustomobject]@{
        ColdStartFirstMs = $coldFirstMs
        ColdCacheAvgMs   = $coldStats.Average
        HotCacheAvgMs    = $hotStats.Average
        SpeedupFactor    = $speedup
    }
}

function Get-PromptHealth {
    [CmdletBinding()]
    param()

    # 1. Memory Usage
    $process = Get-Process -Id $PID
    $memory = $process.WorkingSet64 / 1MB

    # 2. Runspaces
    $runspaces = Get-Runspace
    $runspacesCount = @($runspaces).Count

    # 3. Cache
    $memoryCacheCount = if ($script:PPFMemoryCache) { $script:PPFMemoryCache.Count } else { 0 }
    $diskCache = Import-PPFDiskCache
    $diskCacheCount = if ($diskCache) { $diskCache.Count } else { 0 }

    # 4. Event Listeners
    $registeredEvents = @()
    if ($script:PPFEventListeners) {
        foreach ($key in $script:PPFEventListeners.Keys) {
            $count = $script:PPFEventListeners[$key].Count
            if ($count -gt 0) {
                $registeredEvents += "$key ($count listeners)"
            }
        }
    }

    # 5. Providers
    $providers = Get-PromptProviders
    $activeProviders = $providers | Select-Object -ExpandProperty Name

    # 6. Renderer & Theme
    $config = Get-PromptConfiguration
    $activeRenderer = if ($config) { $config.Renderer["Default"] } else { "Plain" }
    $activeTheme = if (Get-Command Get-ActiveTheme -ErrorAction SilentlyContinue) { (Get-ActiveTheme).Name } else { "Default" }

    # 7. Handles
    $handlesCount = $process.HandleCount

    $health = [pscustomobject]@{
        MemoryUsageMB       = [math]::Round($memory, 2)
        ActiveRunspaces     = $runspacesCount
        MemoryCacheEntries  = $memoryCacheCount
        DiskCacheEntries    = $diskCacheCount
        RegisteredEvents    = $registeredEvents
        ActiveProviders     = $activeProviders
        ActiveRenderer      = $activeRenderer
        ActiveTheme         = $activeTheme
        ProcessHandles      = $handlesCount
    }

    # Format output for console
    Write-Host "`n=== Pablitus Prompt Framework Health Status ===" -ForegroundColor Cyan
    Write-Host "Process Memory:      $([math]::Round($health.MemoryUsageMB, 2)) MB"
    Write-Host "Process Handles:     $($health.ProcessHandles)"
    Write-Host "Active Runspaces:    $($health.ActiveRunspaces)"
    Write-Host "Cache Stats:         $($health.MemoryCacheEntries) Memory, $($health.DiskCacheEntries) Disk"
    Write-Host "Active Theme:        $($health.ActiveTheme)"
    Write-Host "Active Renderer:     $($health.ActiveRenderer)"
    Write-Host "Active Providers:    $($health.ActiveProviders -join ', ')"
    Write-Host "Registered Events:   $(if ($health.RegisteredEvents.Count -gt 0) { $health.RegisteredEvents -join ', ' } else { 'None' })"
    Write-Host "================================================`n"

    return $health
}

function Optimize-PPFLogSize {
    param(
        [int]$MaxSizeBytes = 5MB
    )
    try {
        if (Test-Path $script:LogFile) {
            $file = Get-Item $script:LogFile
            if ($file.Length -gt $MaxSizeBytes) {
                $oldLog = Join-Path $script:LogDir "prompt.old.log"
                if (Test-Path $oldLog) {
                    Remove-Item $oldLog -Force
                }
                Rename-Item -Path $script:LogFile -NewName "prompt.old.log" -Force
            }
        }
    }
    catch {
        # Fail silently to avoid interrupting startup
    }
}

# Optimize log size once on load
Optimize-PPFLogSize

