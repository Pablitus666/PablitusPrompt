# ============================================================
# Pablitus Prompt Framework (PPF)
# Prompt.Theme.Omp.ps1
#
# Importación de temas de Oh My Posh (.omp.json) al núcleo .NET de PPF.
# Permite importar temas desde un archivo local o una URL remota.
# ============================================================

function Import-OmpTheme {

    [CmdletBinding()]
    param(
        # Ruta al archivo .omp.json o URL remota del tema Oh My Posh
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias("FullName", "PSPath", "Url")]
        [string[]]$Path,

        # Si se activa el tema inmediatamente después de importarlo
        [switch]$Activate,

        # Si se ignoran segmentos OMP no soportados por PPF
        [switch]$IgnoreUnsupported
    )

    begin {
        $importedThemes = [System.Collections.Generic.List[string]]::new()
    }

    process {
        foreach ($item in $Path) {
            $themePath = $item
            $downloaded = $false

            # Si es una URL, descargar primero
            if ($item -match '^https?://') {
                Write-Host "Descargando tema OMP desde: $item" -ForegroundColor Cyan
                try {
                    $tempFile = Join-Path $env:TEMP "ppf-omp-theme-$([guid]::NewGuid().ToString('N')).json"
                    Invoke-WebRequest -Uri $item -OutFile $tempFile -ErrorAction Stop
                    $themePath = $tempFile
                    $downloaded = $true
                    Write-Host "Descargado en: $tempFile" -ForegroundColor Green
                }
                catch {
                    Write-Error "No se pudo descargar el tema OMP desde '$item': $($_.Exception.Message)"
                    continue
                }
            }

            # Validar que el archivo exista
            if (-not (Test-Path -LiteralPath $themePath -PathType Leaf)) {
                Write-Error "Archivo no encontrado: $themePath"
                continue
            }

            # Validar que sea un archivo JSON
            try {
                $json = Get-Content -Raw -LiteralPath $themePath -ErrorAction Stop
                $doc = $json | ConvertFrom-Json -ErrorAction Stop
                if (-not $doc -or $doc -isnot [pscustomobject]) {
                    Write-Error "Archivo no es un JSON válido: $themePath"
                    continue
                }
            }
            catch {
                Write-Error "Error al leer JSON: $themePath - $($_.Exception.Message)"
                continue
            }

            # Importar al núcleo .NET
            try {
                Import-PPFDotNetTheme -Path $themePath -IgnoreUnsupported:$IgnoreUnsupported -Activate:$Activate -ErrorAction Stop
                $importedThemes.Add($themePath)
                Write-Host "Tema OMP importado: $themePath" -ForegroundColor Green
            }
            catch {
                Write-Error "Error importando tema OMP '$themePath': $($_.Exception.Message)"
            }
            finally {
                # Limpiar archivo temporal si fue descargado
                if ($downloaded -and (Test-Path $themePath)) {
                    try { Remove-Item -LiteralPath $themePath -Force -ErrorAction SilentlyContinue } catch {}
                }
            }
        }
    }

    end {
        if ($importedThemes.Count -gt 0) {
            Write-Host "" -ForegroundColor Cyan
            Write-Host "Temas OMP importados: $($importedThemes.Count)" -ForegroundColor Green
            foreach ($t in $importedThemes) {
                Write-Host "  - $t" -ForegroundColor Green
            }
        }
    }
}
