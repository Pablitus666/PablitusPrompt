# ============================================================
# Pablitus Prompt Framework (PPF)
# Prompt.Metrics.ps1
#
# Métricas y observabilidad del prompt (Fase 3E).
#
# Diseño:
#  - Opt-in mediante $env:PPF_METRICS_ENABLED = "1" (por defecto desactivado).
#  - Sin I/O en hot path: los datos se acumulan en memoria durante los
#    renders y se persisten en disco de forma batch/asincrónica.
#  - Sin PII: nunca se escriben rutas completas, usuarios, ramas de git ni
#    información sensible. Segmentos, proveedores y temas son identificadores
#    internos del framework, no datos de usuario.
# ============================================================

# Estado de métricas en memoria (solo se activa con PPF_METRICS_ENABLED=1)
$script:PPFMetricsEnabled = $false
$script:PPFMetricsDaily = $null
$script:PPFMetricsRenderCount = 0
$script:PPFMetricsLastFlush = $null

# Umbral de flush batch (cada N renders se persiste a disco).
$script:PPFMetricsFlushThreshold = 10

function Get-PPFMetricsCacheDir {

    # Reutiliza el mismo directorio de caché que el resto del framework.
    if ($script:CacheDir) { return $script:CacheDir }
    Get-PPFCacheDirectory
}

function Get-PPFMetricsDailyPath {

    param(
        [Parameter(Mandatory)]
        [datetime]$Date
    )

    $dateStr = $Date.ToString("yyyy-MM-dd")
    $fileName = "metrics-$dateStr.json"
    Join-Path (Get-PPFMetricsCacheDir) $fileName
}

function Test-PPFMetricsEnabled {

    [bool]($env:PPF_METRICS_ENABLED -eq "1")
}

function Initialize-PPFMetrics {

    if (-not (Test-PPFMetricsEnabled)) {
        return
    }
    $script:PPFMetricsEnabled = $true
    $today = [datetime]::Today
    $script:PPFMetricsDaily = @{
        Date           = $today.ToString("yyyy-MM-dd")
        RenderCount    = 0
        ActiveTheme    = $null
        SegmentTimes   = @{}   # nombre segmento -> lista de tiempos (ms)
        ProviderTimes  = @{}   # nombre proveedor -> lista de tiempos (ms)
        CacheHits      = 0
        CacheMisses    = 0
        SlowProviders  = @()   # nombres de proveedores más lentos (promedio)
    }
    $script:PPFMetricsRenderCount = 0
    $script:PPFMetricsLastFlush = $null
}

function Ensure-PPFMetricsInitialized {

    if ($script:PPFMetricsEnabled -and $null -eq $script:PPFMetricsDaily) {
        Initialize-PPFMetrics
    }
}

# Registra un render completo en el acumulador diario (memoria, sin disco).
# Se invoca desde Invoke-Prompt / Get-PromptString fuera del camino crítico
# de I/O: solo actualiza hashtables en memoria.
function Record-PPFRenderMetrics {

    param(
        [Parameter(Mandatory)]
        [hashtable]$Metrics,        # Context.Metrics del render

        [string]$ActiveThemeName
    )

    if (-not $script:PPFMetricsEnabled) { return }
    Ensure-PPFMetricsInitialized

    $script:PPFMetricsDaily.RenderCount++
    $script:PPFMetricsRenderCount++

    if ($ActiveThemeName) {
        $script:PPFMetricsDaily.ActiveTheme = $ActiveThemeName
    }

    # Acumular tiempos de segmento
    foreach ($key in $Metrics.Keys) {
        if ($key -like "Segment_*_TimeMs") {
            $segName = $key.Replace("Segment_", "").Replace("_TimeMs", "")
            $val = if ($Metrics[$key] -is [double]) { $Metrics[$key] } else { [double]$Metrics[$key] }
            if (-not $script:PPFMetricsDaily.SegmentTimes.ContainsKey($segName)) {
                $script:PPFMetricsDaily.SegmentTimes[$segName] = New-Object System.Collections.Generic.List[double]
            }
            $null = $script:PPFMetricsDaily.SegmentTimes[$segName].Add($val)
        }
        elseif ($key -like "Provider_*_TimeMs" -and $key -notlike "*_ReadTimeMs" -and $key -notlike "*_UpdateTimeMs") {
            $provName = $key.Replace("Provider_", "").Replace("_TimeMs", "")
            $val = if ($Metrics[$key] -is [double]) { $Metrics[$key] } else { [double]$Metrics[$key] }
            if (-not $script:PPFMetricsDaily.ProviderTimes.ContainsKey($provName)) {
                $script:PPFMetricsDaily.ProviderTimes[$provName] = New-Object System.Collections.Generic.List[double]
            }
            $null = $script:PPFMetricsDaily.ProviderTimes[$provName].Add($val)
        }
    }

    # Contadores de caché (diferencia acumulada global, se lee tal cual)
    $script:PPFMetricsDaily.CacheHits   = [int]$global:PPF_CacheHits
    $script:PPFMetricsDaily.CacheMisses = [int]$global:PPF_CacheMisses

    # Flush batch cuando se alcanza el umbral (sin I/O en cada render).
    if ($script:PPFMetricsRenderCount -ge $script:PPFMetricsFlushThreshold) {
        Flush-PPFMetrics
    }
}

# Calcula el ratio de caché (hits / total) como porcentaje.
function Get-PPFMetricsCacheRatio {

    $hits   = [int]$script:PPFMetricsDaily.CacheHits
    $misses = [int]$script:PPFMetricsDaily.CacheMisses
    $total  = $hits + $misses
    if ($total -eq 0) { return 0.0 }
    return [math]::Round(($hits / $total) * 100, 2)
}

# Calcula los proveedores más lentos por tiempo promedio acumulado.
function Get-PPFMetricsSlowProviders {

    $slow = [ordered]@{}
    foreach ($name in $script:PPFMetricsDaily.ProviderTimes.Keys) {
        $times = $script:PPFMetricsDaily.ProviderTimes[$name]
        if ($times.Count -gt 0) {
            $sum = 0.0
            foreach ($t in $times) { $sum += $t }
            $slow[$name] = [math]::Round($sum / $times.Count, 2)
        }
    }
    # Ordenar descendente por promedio y tomar los 3 más lentos
    $sorted = $slow.GetEnumerator() | Sort-Object Value -Descending
    $top = @()
    $count = 0
    foreach ($entry in $sorted) {
        if ($count -ge 3) { break }
        $top += $entry.Key
        $count++
    }
    return $top
}

# Persiste el acumulador diario a disco (escritura atómica via archivo temporal).
function Flush-PPFMetrics {

    if (-not $script:PPFMetricsEnabled) { return }
    if ($null -eq $script:PPFMetricsDaily) { return }

    try {
        $slowProviders = Get-PPFMetricsSlowProviders

        $payload = [ordered]@{
            Date           = $script:PPFMetricsDaily.Date
            RenderCount    = [int]$script:PPFMetricsDaily.RenderCount
            ActiveTheme    = $script:PPFMetricsDaily.ActiveTheme
            CacheHitRatio  = Get-PPFMetricsCacheRatio
            CacheHits      = [int]$script:PPFMetricsDaily.CacheHits
            CacheMisses    = [int]$script:PPFMetricsDaily.CacheMisses
            SegmentTimes   = [ordered]@{}
            ProviderTimes  = [ordered]@{}
            SlowProviders  = $slowProviders
            FlushedAt      = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss.fff")
        }

        foreach ($seg in ($script:PPFMetricsDaily.SegmentTimes.Keys | Sort-Object)) {
            $times = $script:PPFMetricsDaily.SegmentTimes[$seg]
            $payload.SegmentTimes[$seg] = [ordered]@{
                Count   = $times.Count
                Average = [math]::Round((($times | Measure-Object -Average).Average), 2)
                Min     = [math]::Round(($times | Measure-Object -Minimum).Minimum, 2)
                Max     = [math]::Round(($times | Measure-Object -Maximum).Maximum, 2)
            }
        }

        foreach ($prov in ($script:PPFMetricsDaily.ProviderTimes.Keys | Sort-Object)) {
            $times = $script:PPFMetricsDaily.ProviderTimes[$prov]
            $payload.ProviderTimes[$prov] = [ordered]@{
                Count   = $times.Count
                Average = [math]::Round((($times | Measure-Object -Average).Average), 2)
                Min     = [math]::Round(($times | Measure-Object -Minimum).Minimum, 2)
                Max     = [math]::Round(($times | Measure-Object -Maximum).Maximum, 2)
            }
        }

        $dir = Get-PPFMetricsCacheDir
        if (-not (Test-Path $dir)) {
            $null = New-Item -ItemType Directory -Path $dir -Force
        }
        $path = Get-PPFMetricsDailyPath -Date (Get-Date)

        $json = $payload | ConvertTo-Json -Depth 5
        $tempPath = "{0}.{1}.tmp" -f $path, [guid]::NewGuid().ToString("N")
        $json | Out-File -LiteralPath $tempPath -Encoding utf8 -ErrorAction Stop
        [System.IO.File]::Move($tempPath, $path, $true)

        $script:PPFMetricsLastFlush = [datetime]::Now
        $script:PPFMetricsRenderCount = 0
    }
    catch {
        # Fallar en silencio para no interrumpir el prompt.
        Write-Verbose "[PPF] Failed to flush metrics: $_"
    }
}

# Función pública: obtiene las métricas agrupadas.
function Get-PromptMetrics {

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [datetime]$Date,

        [Parameter(Mandatory = $false)]
        [ValidateSet("day", "week", "month")]
        [string]$Period = "day"
    )

    if (-not (Test-PPFMetricsEnabled)) {
        Write-Verbose "[PPF] Métricas desactivadas (PPF_METRICS_ENABLED != 1)."
        return [pscustomobject]@{
            Enabled   = $false
            Message   = "Métricas desactivadas. Establezca `env:PPF_METRICS_ENABLED = '1'` para habilitarlas."
            Date      = if ($Date) { $Date.ToString("yyyy-MM-dd") } else { [datetime]::Today.ToString("yyyy-MM-dd") }
            Period    = $Period
            Metrics   = @()
        }
    }

    Ensure-PPFMetricsInitialized

    # Forzar flush de los datos pendientes de esta sesión antes de leer.
    Flush-PPFMetrics

    $targetDate = if ($Date) { $Date } else { [datetime]::Today }

    switch ($Period) {
        "day"   { $dates = @($targetDate) }
        "week"  {
            $start = $targetDate.AddDays(-[int]$targetDate.DayOfWeek)
            $dates = @()
            for ($i = 0; $i -lt 7; $i++) { $dates += $start.AddDays($i) }
        }
        "month" {
            $start = [datetime]::new($targetDate.Year, $targetDate.Month, 1)
            $end   = $start.AddMonths(1).AddDays(-1)
            $dates = @()
            $d = $start
            while ($d -le $end) { $dates += $d; $d = $d.AddDays(1) }
        }
    }

    $results = @()
    foreach ($d in $dates) {
        $path = Get-PPFMetricsDailyPath -Date $d
        if (Test-Path -LiteralPath $path) {
            try {
                $json = Get-Content -Raw -LiteralPath $path -ErrorAction Stop
                $data = ConvertFrom-Json $json -AsHashtable -ErrorAction Stop
                $results += $data
            }
            catch {
                Write-Verbose "[PPF] No se pudieron leer métricas del $($d.ToString('yyyy-MM-dd')): $_"
            }
        }
    }

    if ($Period -eq "day") {
        if ($results.Count -gt 0) {
            return $results[0]
        }
        return [pscustomobject]@{
            Enabled     = $true
            Date        = $targetDate.ToString("yyyy-MM-dd")
            Period      = "day"
            RenderCount = 0
            Message     = "No hay métricas para esta fecha."
        }
    }

    # Para week/month devolver un resumen agregado
    $totalRenders = 0
    $totalHits    = 0
    $totalMisses  = 0
    $themes       = @{}
    $allSlow      = @{}

    foreach ($r in $results) {
        $totalRenders += [int]$r.RenderCount
        $totalHits    += [int]$r.CacheHits
        $totalMisses  += [int]$r.CacheMisses
        if ($r.ActiveTheme) {
            $t = $r.ActiveTheme
            if (-not $themes.ContainsKey($t)) { $themes[$t] = 0 }
            $themes[$t]++
        }
        foreach ($s in @($r.SlowProviders)) {
            if (-not $allSlow.ContainsKey($s)) { $allSlow[$s] = 0 }
            $allSlow[$s]++
        }
    }

    $total = $totalHits + $totalMisses
    $ratio = if ($total -eq 0) { 0.0 } else { [math]::Round(($totalHits / $total) * 100, 2) }

    $activeTheme = if ($themes.Count -gt 0) {
        ($themes.GetEnumerator() | Sort-Object Value -Descending)[0].Key
    } else { $null }

    return [pscustomobject]@{
        Enabled     = $true
        Period      = $Period
        StartDate   = $dates[0].ToString("yyyy-MM-dd")
        EndDate     = $dates[-1].ToString("yyyy-MM-dd")
        RenderCount = $totalRenders
        CacheHits   = $totalHits
        CacheMisses = $totalMisses
        CacheHitRatio = $ratio
        ActiveTheme = $activeTheme
        Themes      = $themes
        SlowProviders = $allSlow.Keys
        DailyDetails = $results
    }
}

# Inicializar métricas al cargar el módulo (no-op si no está habilitado por env).
Initialize-PPFMetrics
