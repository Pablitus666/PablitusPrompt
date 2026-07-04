# ============================================================
# Pablitus Prompt Framework (PPF)
# Prompt.Telemetry.ps1
# ============================================================

# Global Telemetry & Cache counters
if ($null -eq $global:PPF_CacheHits) { $global:PPF_CacheHits = 0 }
if ($null -eq $global:PPF_CacheMisses) { $global:PPF_CacheMisses = 0 }
if ($null -eq $global:PPF_BootstrapTimeMs) { $global:PPF_BootstrapTimeMs = 0.0 }

# Logging Levels: TRACE, DEBUG, INFO, WARN, ERROR
$script:LogLevel = "INFO"
$script:LogDir = Join-Path $env:LOCALAPPDATA "PablitusPrompt\logs"
$script:LogFile = Join-Path $script:LogDir "prompt.log"

function Set-PPFLogLevel {
    param(
        [ValidateSet("TRACE", "DEBUG", "INFO", "WARN", "ERROR")]
        [string]$Level
    )
    $script:LogLevel = $Level
}

function Write-PPFLog {
    param(
        [Parameter(Mandatory)]
        [ValidateSet("TRACE", "DEBUG", "INFO", "WARN", "ERROR")]
        [string]$Level,

        [Parameter(Mandatory)]
        [string]$Message
    )

    # Level weights for filtering
    $levels = @{ "TRACE" = 0; "DEBUG" = 1; "INFO" = 2; "WARN" = 3; "ERROR" = 4 }
    if ($levels[$Level] -lt $levels[$script:LogLevel]) {
        return
    }

    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss.fff")
    $logLine = "[$timestamp] [$Level] $Message"

    # Write to debug/verbose streams dynamically
    if ($Level -eq "ERROR") {
        Write-Error $Message -ErrorAction SilentlyContinue
    }
    elseif ($Level -eq "WARN") {
        Write-Warning $Message
    }
    elseif ($Level -eq "DEBUG" -or $Level -eq "TRACE") {
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
        if ($key -like "Provider_*") {
            $name = $key.Replace("Provider_", "").Replace("_TimeMs", "")
            $val = $context.Metrics[$key]
            $providerMetrics[$name] = $val
            $providerTime += $val
        }
        elseif ($key -like "Segment_*") {
            $name = $key.Replace("Segment_", "").Replace("_TimeMs", "")
            $val = $context.Metrics[$key]
            $segmentMetrics[$name] = $val
            $segmentTime += $val
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
    Write-Host "Bootstrap Time:      $([math]::Round($result.BootstrapTimeMs, 2)) ms"
    Write-Host "Total Prompt Time:   $([math]::Round($result.TotalPromptTimeMs, 2)) ms"
    Write-Host "Rendering Time:      $([math]::Round($result.RenderingTimeMs, 2)) ms (Renderer: $($result.ActiveRenderer))"
    Write-Host "Providers Total:     $([math]::Round($result.ProvidersTotalMs, 2)) ms"
    Write-Host "Segments Total:      $([math]::Round($result.SegmentsTotalMs, 2)) ms"
    Write-Host "Cache Stats:         $($result.CacheHits) Hits, $($result.CacheMisses) Misses ($([math]::Round($result.CacheHitRatio, 1))% Hit Ratio)"
    Write-Host "Theme Active:        $($result.ActiveTheme)"
    Write-Host "Process Memory:      $([math]::Round($result.MemoryUsageMB, 2)) MB"
    Write-Host "Process CPU:         $([math]::Round($result.CPUTimeSec, 2)) seconds"
    Write-Host "Start Type:          $(if ($result.IsColdStart) { 'Cold Start' } else { 'Warm Start' })"

    Write-Host "`n--- Providers Breakdown ---" -ForegroundColor Green
    foreach ($k in $result.ProviderBreakdown.Keys) {
        Write-Host "  - $k`: $([math]::Round($result.ProviderBreakdown[$k], 2)) ms"
    }

    Write-Host "`n--- Segments Breakdown ---" -ForegroundColor Green
    foreach ($k in $result.SegmentBreakdown.Keys) {
        Write-Host "  - $k`: $([math]::Round($result.SegmentBreakdown[$k], 2)) ms"
    }
    Write-Host "============================================`n"

    return $result
}


function Measure-PromptDetailed {
    [CmdletBinding()]
    param(
        [string]$Renderer = "Plain",
        [string]$ExportDir = "benchmarks"
    )

    # 1. Run prompt evaluation and collect metrics
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $context = Invoke-Prompt
    $renderSw = [System.Diagnostics.Stopwatch]::StartNew()
    $promptStr = Get-PromptString -Context $context -Renderer $Renderer
    $renderSw.Stop()
    $sw.Stop()

    $totalTime = $sw.Elapsed.TotalMilliseconds
    $renderTime = $renderSw.Elapsed.TotalMilliseconds

    # Parse metrics
    $bootstrapTime = $global:PPF_BootstrapTimeMs
    $providerMetrics = [ordered]@{}
    $segmentMetrics = [ordered]@{}

    foreach ($key in ($context.Metrics.Keys | Sort-Object)) {
        if ($key -like "Provider_*") {
            $name = $key.Replace("Provider_", "").Replace("_TimeMs", "")
            $providerMetrics[$name] = $context.Metrics[$key]
        }
        elseif ($key -like "Segment_*") {
            $name = $key.Replace("Segment_", "").Replace("_TimeMs", "")
            $segmentMetrics[$name] = $context.Metrics[$key]
        }
    }

    # Format output for console
    $sb = New-Object System.Text.StringBuilder
    [void]$sb.AppendLine("PPF Performance Report")
    [void]$sb.AppendLine("==================================")
    [void]$sb.AppendLine("Bootstrap")
    [void]$sb.AppendLine("-------------------")
    [void]$sb.AppendLine("$([math]::Round($bootstrapTime, 2)) ms")
    [void]$sb.AppendLine()
    [void]$sb.AppendLine("Providers")
    [void]$sb.AppendLine("-------------------")
    foreach ($p in $providerMetrics.Keys | Sort-Object { $providerMetrics[$_] } -Descending) {
        $dots = "." * [math]::Max(2, (20 - $p.Length))
        [void]$sb.AppendLine("$p$dots$([math]::Round($providerMetrics[$p], 2)) ms")
    }
    [void]$sb.AppendLine()
    [void]$sb.AppendLine("Segments")
    [void]$sb.AppendLine("-------------------")
    foreach ($s in $segmentMetrics.Keys | Sort-Object { $segmentMetrics[$_] } -Descending) {
        $dots = "." * [math]::Max(2, (20 - $s.Length))
        [void]$sb.AppendLine("$s$dots$([math]::Round($segmentMetrics[$s], 2)) ms")
    }
    [void]$sb.AppendLine()
    [void]$sb.AppendLine("Renderer")
    [void]$sb.AppendLine("-------------------")
    $dots = "." * [math]::Max(2, (20 - $Renderer.Length))
    [void]$sb.AppendLine("$Renderer$dots$([math]::Round($renderTime, 2)) ms")
    [void]$sb.AppendLine()
    [void]$sb.AppendLine("TOTAL")
    [void]$sb.AppendLine("-------------------")
    [void]$sb.AppendLine("$([math]::Round($totalTime, 2)) ms")

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
            BootstrapMs    = $bootstrapTime
            TotalMs        = $totalTime
            RendererMs     = $renderTime
            RendererName   = $Renderer
            Providers      = $providerMetrics
            Segments       = $segmentMetrics
        }
        $jsonPath = Join-Path $fullExportDir "benchmark_report.json"
        $jsonObj | ConvertTo-Json -Depth 5 | Out-File -FilePath $jsonPath -Encoding utf8

        # 3. Export CSV
        $csvPath = Join-Path $fullExportDir "benchmark_report.csv"
        $csvRows = @()
        $csvRows += [pscustomobject]@{ Category = "Bootstrap"; Component = "Core"; TimeMs = $bootstrapTime }
        foreach ($p in $providerMetrics.Keys) {
            $csvRows += [pscustomobject]@{ Category = "Provider"; Component = $p; TimeMs = $providerMetrics[$p] }
        }
        foreach ($s in $segmentMetrics.Keys) {
            $csvRows += [pscustomobject]@{ Category = "Segment"; Component = $s; TimeMs = $segmentMetrics[$s] }
        }
        $csvRows += [pscustomobject]@{ Category = "Renderer"; Component = $Renderer; TimeMs = $renderTime }
        $csvRows += [pscustomobject]@{ Category = "Total"; Component = "All"; TimeMs = $totalTime }
        $csvRows | Export-Csv -Path $csvPath -NoTypeInformation -Encoding utf8

        # 4. Export Markdown
        $mdPath = Join-Path $fullExportDir "benchmark_report.md"
        $mdSb = New-Object System.Text.StringBuilder
        [void]$mdSb.AppendLine("# PPF Performance Report")
        [void]$mdSb.AppendLine("Generado el: $((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))")
        [void]$mdSb.AppendLine()
        [void]$mdSb.AppendLine("| Categoría | Componente | Tiempo (ms) |")
        [void]$mdSb.AppendLine("| --- | --- | --- |")
        [void]$mdSb.AppendLine("| **Bootstrap** | Core | $([math]::Round($bootstrapTime, 2)) |")
        foreach ($p in $providerMetrics.Keys | Sort-Object { $providerMetrics[$_] } -Descending) {
            [void]$mdSb.AppendLine("| Provider | $p | $([math]::Round($providerMetrics[$p], 2)) |")
        }
        foreach ($s in $segmentMetrics.Keys | Sort-Object { $segmentMetrics[$_] } -Descending) {
            [void]$mdSb.AppendLine("| Segment | $s | $([math]::Round($segmentMetrics[$s], 2)) |")
        }
        [void]$mdSb.AppendLine("| Renderer | $Renderer | $([math]::Round($renderTime, 2)) |")
        [void]$mdSb.AppendLine("| **TOTAL** | All | **$([math]::Round($totalTime, 2))** |")
        $mdSb.ToString() | Out-File -FilePath $mdPath -Encoding utf8

        # 5. Export HTML
        $htmlPath = Join-Path $fullExportDir "benchmark_report.html"
        $htmlSb = New-Object System.Text.StringBuilder
        [void]$htmlSb.AppendLine("<html><head><style>")
        [void]$htmlSb.AppendLine("body { font-family: Arial, sans-serif; background-color: #1e1e2e; color: #cdd6f4; margin: 20px; }")
        [void]$htmlSb.AppendLine("h1 { color: #f5c2e7; }")
        [void]$htmlSb.AppendLine("table { width: 100%; border-collapse: collapse; margin-top: 20px; }")
        [void]$htmlSb.AppendLine("th, td { border: 1px solid #45475a; padding: 10px; text-align: left; }")
        [void]$htmlSb.AppendLine("th { background-color: #313244; color: #a6adc8; }")
        [void]$htmlSb.AppendLine("tr:nth-child(even) { background-color: #181825; }")
        [void]$htmlSb.AppendLine(".highlight { font-weight: bold; color: #a6e3a1; }")
        [void]$htmlSb.AppendLine("</style></head><body>")
        [void]$htmlSb.AppendLine("<h1>PPF Performance Report</h1>")
        [void]$htmlSb.AppendLine("<p>Generado el: $((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))</p>")
        [void]$htmlSb.AppendLine("<table>")
        [void]$htmlSb.AppendLine("<tr><th>Categoría</th><th>Componente</th><th>Tiempo (ms)</th></tr>")
        [void]$htmlSb.AppendLine("<tr class='highlight'><td>Bootstrap</td><td>Core</td><td>$([math]::Round($bootstrapTime, 2))</td></tr>")
        foreach ($p in $providerMetrics.Keys | Sort-Object { $providerMetrics[$_] } -Descending) {
            [void]$htmlSb.AppendLine("<tr><td>Provider</td><td>$p</td><td>$([math]::Round($providerMetrics[$p], 2))</td></tr>")
        }
        foreach ($s in $segmentMetrics.Keys | Sort-Object { $segmentMetrics[$_] } -Descending) {
            [void]$htmlSb.AppendLine("<tr><td>Segment</td><td>$s</td><td>$([math]::Round($segmentMetrics[$s], 2))</td></tr>")
        }
        [void]$htmlSb.AppendLine("<tr><td>Renderer</td><td>$Renderer</td><td>$([math]::Round($renderTime, 2))</td></tr>")
        [void]$htmlSb.AppendLine("<tr class='highlight'><td>TOTAL</td><td>All</td><td>$([math]::Round($totalTime, 2))</td></tr>")
        [void]$htmlSb.AppendLine("</table></body></html>")
        $htmlSb.ToString() | Out-File -FilePath $htmlPath -Encoding utf8

        Write-Host "Reportes exportados exitosamente a '$fullExportDir'" -ForegroundColor Green
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
        if (Get-Command Invoke-Pester -ErrorAction SilentlyContinue) {
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

