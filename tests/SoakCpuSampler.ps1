# ============================================================
# Pablitus Prompt Framework (PPF)
# SoakCpuSampler.ps1 - Soak Test for CPU Sampler Runspace
# ============================================================

$bootstrapPath = Resolve-Path (Join-Path $PSScriptRoot "..\src\Bootstrap.ps1")
. $bootstrapPath

# Target duration in seconds. Default to 10 seconds for automated test runs, but configurable.
$DurationSec = 10
if ($args.Count -gt 0) {
    $DurationSec = [int]$args[0]
}

Write-Host "Iniciando Soak Test de Sampler CPU durante $DurationSec segundos..." -ForegroundColor Cyan

# Ensure sampler is running and warm up
& (Get-Module PablitusPrompt) { Start-CpuSampler }
Write-Host "Esperando estabilización del Runspace (calentamiento)..." -ForegroundColor Gray
Start-Sleep -Seconds 5

# Force GC for cleaner baseline
[System.GC]::Collect()
[System.GC]::WaitForPendingFinalizers()
[System.GC]::Collect()

$startProcess = Get-Process -Id $PID
$startMemory = $startProcess.WorkingSet64 / 1MB
$startHandles = $startProcess.HandleCount

$sw = [System.Diagnostics.Stopwatch]::StartNew()
$lastIterations = 0
$consecutiveStatic = 0
$lockups = 0
$recreations = 0

while ($sw.Elapsed.TotalSeconds -lt $DurationSec) {
    Start-Sleep -Seconds 2
    
    # Query Shared Data
    $shared = $global:PPF_CpuSharedData
    $runspace = $global:PPF_CpuRunspace
    
    $runspaceState = if ($runspace) { $runspace.RunspaceStateInfo.State.ToString() } else { "None" }
    $iterations = if ($shared) { $shared.IterationCount } else { 0 }
    $updateMs = if ($shared) { $shared.UpdateDurationMs } else { 0.0 }
    $lastUpdate = if ($shared) { $shared.LastUpdateTime } else { "Never" }
    
    $proc = Get-Process -Id $PID
    $currentMemory = $proc.WorkingSet64 / 1MB
    
    # Lockup check: iteration count should increase if state is Opened
    # We allow up to 2 consecutive checks without change due to CIM latency (2*2s = 4s vs 2s interval)
    if ($runspaceState -eq "Opened") {
        if ($iterations -eq $lastIterations) {
            $consecutiveStatic++
            if ($consecutiveStatic -ge 3) {
                $lockups++
                Write-Warning "El sampler de CPU parece bloqueado (iteraciones no avanzan: $iterations durante 3 comprobaciones)."
            } else {
                Write-Host "Detección de posible retraso en sampler (CIM latency?)" -ForegroundColor Yellow
            }
        } else {
            $consecutiveStatic = 0
        }
    } else {
        $recreations++
        Write-Warning "Runspace de CPU en estado inusual: $runspaceState. Reintentando iniciar..."
        & (Get-Module PablitusPrompt) { Start-CpuSampler }
    }
    
    $lastIterations = $iterations
    
    Write-Host "Tiempo: $([math]::Round($sw.Elapsed.TotalSeconds, 1))s / ${DurationSec}s | Estado Runspace: $runspaceState | Iteraciones: $iterations | Last Update: $lastUpdate | Memory: $([math]::Round($currentMemory, 2)) MB"
}

$sw.Stop()

$finalProcess = Get-Process -Id $PID
$finalMemory = $finalProcess.WorkingSet64 / 1MB
$finalHandles = $finalProcess.HandleCount

# Clean up
& (Get-Module PablitusPrompt) { Stop-CpuSampler }

Write-Host "`n=== RESULTADOS DEL SOAK TEST CPU ===" -ForegroundColor Green
Write-Host "Iteraciones ejecutadas: $lastIterations"
Write-Host "Recreaciones Runspace:  $recreations"
Write-Host "Bloqueos detectados:    $lockups"
Write-Host "Memoria Inicial:        $([math]::Round($startMemory, 2)) MB"
Write-Host "Memoria Final:          $([math]::Round($finalMemory, 2)) MB (Diferencia: $([math]::Round($finalMemory - $startMemory, 2)) MB)"
Write-Host "Handles Finales:        $finalHandles"
Write-Host "=====================================" -ForegroundColor Green

if ($lockups -gt 0 -or $recreations -gt 1) {
    Write-Warning "¡El Sampler CPU ha mostrado inestabilidad durante el test!"
    exit 1
} else {
    Write-Host "¡Sampler CPU completamente estable!" -ForegroundColor Green
    exit 0
}
