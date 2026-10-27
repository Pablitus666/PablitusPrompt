# ============================================================
# Pablitus Prompt Framework (PPF)
# Prompt.Core.ps1
# ============================================================

function New-PromptContext {

    return [PromptContext]::new()

}

function Invoke-Prompt {

    if ($script:HotReloadEnabled) {
        Test-PromptConfigReload
    }

    $context = New-PromptContext

    # Ejecutar Providers
    Invoke-PromptProviders -Context $context

    # Ejecutar Pipeline Middleware
    Invoke-PPFPipeline -Context $context

    # Construir segmentos
    Invoke-PromptSegments -Context $context

    # Persist any disk-cache updates produced by the providers. The helper is
    # a no-op when the cache is clean, so this does not add per-prompt I/O.
    Sync-PPFDiskCache

    # Métricas de observabilidad (opt-in). Solo actualiza estructuras en
    # memoria; la persistencia a disco es batch/asincrónica (Flush-PPFMetrics).
    if (Get-Command Record-PPFRenderMetrics -ErrorAction SilentlyContinue) {
        try {
            $activeTheme = if (Get-Command Get-ActiveTheme -ErrorAction SilentlyContinue) { (Get-ActiveTheme).Name } else { $null }
            Record-PPFRenderMetrics -Metrics $context.Metrics -ActiveThemeName $activeTheme
        }
        catch {
            # No romper el prompt por un fallo en la recopilación de métricas.
        }
    }

    return $context

}