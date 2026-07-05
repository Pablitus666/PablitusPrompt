# ============================================================
# Pablitus Prompt Framework (PPF)
# SoakRender.ps1 - Soak Test for Rendering Engine
# ============================================================

$bootstrapPath = Resolve-Path (Join-Path $PSScriptRoot "..\src\Bootstrap.ps1")
. $bootstrapPath

Write-Host "Iniciando Soak Test de Renderizado (100 000 iteraciones)..." -ForegroundColor Cyan

$TotalIterations = 100000
if ($args.Count -gt 0) {
    $TotalIterations = [int]$args[0]
}
$LogInterval = [math]::Max(1000, [int]($TotalIterations / 10))

# Warm up phase to trigger JIT compilation, load types and initialize runspaces
$WarmupCount = 50
if ($TotalIterations -le 100) {
    $WarmupCount = 10
}
Write-Host "Ejecutando fase de calentamiento ($WarmupCount iteraciones) para estabilizar memoria..." -ForegroundColor Gray
for ($w = 1; $w -le $WarmupCount; $w++) {
    $context = Invoke-Prompt
    $null = Get-PromptString -Context $context -Renderer "Plain"
}

# Force garbage collection to establish an accurate base memory usage
[System.GC]::Collect()
[System.GC]::WaitForPendingFinalizers()
[System.GC]::Collect()

$startProcess = Get-Process -Id $PID
$startMemory = $startProcess.WorkingSet64 / 1MB
$startHandles = $startProcess.HandleCount

$totalTimes = New-Object System.Collections.Generic.List[double]
$maxTime = 0.0

$lastCpuTime = $startProcess.TotalProcessorTime.TotalMilliseconds
$lastTimestamp = [TimeSpan]::Zero

$swTotal = [System.Diagnostics.Stopwatch]::StartNew()

for ($i = 1; $i -le $TotalIterations; $i++) {
    $swSingle = [System.Diagnostics.Stopwatch]::StartNew()
    
    # Perform render
    $context = Invoke-Prompt
    $prompt = Get-PromptString -Context $context -Renderer "Plain"
    
    $swSingle.Stop()
    
    $elapsed = $swSingle.Elapsed.TotalMilliseconds
    $totalTimes.Add($elapsed)
    if ($elapsed -gt $maxTime) {
        $maxTime = $elapsed
    }
    
    # Periodic log
    if ($i % $LogInterval -eq 0) {
        $proc = Get-Process -Id $PID
        $currentMemory = $proc.WorkingSet64 / 1MB
        $currentHandles = $proc.HandleCount
        
        $currentElapsed = $swTotal.Elapsed
        $timeDiff = ($currentElapsed - $lastTimestamp).TotalMilliseconds
        $cpuDiff = $proc.TotalProcessorTime.TotalMilliseconds - $lastCpuTime
        $cpuUsage = if ($timeDiff -gt 0) { [math]::Round((($cpuDiff / $timeDiff) * 100 / [Environment]::ProcessorCount), 1) } else { 0.0 }
        
        $lastCpuTime = $proc.TotalProcessorTime.TotalMilliseconds
        $lastTimestamp = $currentElapsed

        # Calculate stats for this chunk
        $recentTimes = $totalTimes.GetRange($i - $LogInterval, $LogInterval)
        $chunkAvg = $recentTimes | Measure-Object -Average | Select-Object -ExpandProperty Average
        $chunkMax = $recentTimes | Measure-Object -Maximum | Select-Object -ExpandProperty Maximum
        
        $gcMemory = [System.GC]::GetTotalMemory($false) / 1MB
        $gcTime = 0.0
        try {
            $gcTime = [System.GC]::GetGCMemoryInfo().TotalPauseDuration.TotalMilliseconds
        } catch {}

        $gcGen0 = [System.GC]::CollectionCount(0)
        $gcGen1 = [System.GC]::CollectionCount(1)
        $gcGen2 = [System.GC]::CollectionCount(2)
        
        Write-Host "Iteración $i / $TotalIterations | Memory: $([math]::Round($currentMemory, 2)) MB | Handles: $currentHandles | CPU: ${cpuUsage}%"
        Write-Host "  -> GC Mem: $([math]::Round($gcMemory, 2)) MB | Collections [Gen0/1/2]: $gcGen0/$gcGen1/$gcGen2" -ForegroundColor Gray
        Write-Host "  -> Promedio Chunk: $([math]::Round($chunkAvg, 4)) ms | Max Chunk: $([math]::Round($chunkMax, 4)) ms | GC Pauses: $([math]::Round($gcTime, 2)) ms" -ForegroundColor Gray
    }
}

$swTotal.Stop()
$totalElapsedSec = $swTotal.Elapsed.TotalSeconds

# Force GC to measure true memory leak, not lazy pool allocation
[System.GC]::Collect()
[System.GC]::WaitForPendingFinalizers()
[System.GC]::Collect()

$finalProcess = Get-Process -Id $PID
$finalMemory = $finalProcess.WorkingSet64 / 1MB
$finalHandles = $finalProcess.HandleCount

# Final statistics calculation
$avgTime = $totalTimes | Measure-Object -Average | Select-Object -ExpandProperty Average
$maxTime = $totalTimes | Measure-Object -Maximum | Select-Object -ExpandProperty Maximum

Write-Host "`n=== RESULTADOS DEL SOAK TEST ===" -ForegroundColor Green
Write-Host "Total de renderizados: $TotalIterations"
Write-Host "Tiempo total:         $([math]::Round($totalElapsedSec, 2)) segundos"
Write-Host "Tiempo promedio:      $([math]::Round($avgTime, 4)) ms"
Write-Host "Tiempo máximo:        $([math]::Round($maxTime, 4)) ms"
Write-Host "Memoria Inicial:      $([math]::Round($startMemory, 2)) MB"
Write-Host "Memoria Final:        $([math]::Round($finalMemory, 2)) MB (Diferencia: $([math]::Round($finalMemory - $startMemory, 2)) MB)"
Write-Host "Handles Iniciales:    $startHandles"
Write-Host "Handles Finales:      $finalHandles (Diferencia: $($finalHandles - $startHandles))"
Write-Host "================================" -ForegroundColor Green

# Return validation code (0 for success, 1 for leak or degradation)
$leakThresholdMB = 20
$memoryLeak = ($finalMemory - $startMemory) -gt $leakThresholdMB
if ($memoryLeak) {
    Write-Warning "¡Alerta de posible fuga de memoria detectable! El incremento supera los ${leakThresholdMB}MB."
    exit 1
} else {
    Write-Host "¡Validación de estabilidad exitosa!" -ForegroundColor Green
    exit 0
}
