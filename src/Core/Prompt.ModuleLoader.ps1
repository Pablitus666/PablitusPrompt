# ============================================================
# Pablitus Prompt Framework (PPF)
# Prompt.ModuleLoader.ps1
# ============================================================

function Initialize-PPFModules {

    param(
        [string]$ModulesPath
    )

    if (-not $ModulesPath) {
        $root = if ($global:PPF_InstallRoot) { $global:PPF_InstallRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
        if (-not $root) { $root = Get-Location }
        $ModulesPath = Join-Path $root "Modules"
    }

    if (-not (Test-Path $ModulesPath)) {
        Write-Verbose "[PPF] Modules path '$ModulesPath' not found."
        return
    }

    Write-Verbose "[PPF] Discovering modules in '$ModulesPath'..."

    # 1. Discovery: Listar todas las carpetas dentro de ModulesPath
    $moduleDirs = Get-ChildItem -Path $ModulesPath -Directory

    foreach ($dir in $moduleDirs) {
        $moduleName = $dir.Name
        Write-Verbose "[PPF] Loading module '$moduleName'..."

        # 2. Importer: Cargar de manera ordenada los componentes de este módulo
        # Orden lógico:
        # A. Proveedores (Alimentación del contexto)
        # B. Servicios (Lógica del negocio, helpers)
        # C. Segmentos (Lógica visual y registro de segmentos)
        # D. Otros scripts (Comandos, eventos, configuración, etc.)

        $providerFiles = Get-ChildItem -Path $dir.FullName -Filter "*.Provider.ps1"
        $serviceFiles = Get-ChildItem -Path $dir.FullName -Filter "*.Service.ps1"
        $segmentFiles = Get-ChildItem -Path $dir.FullName -Filter "*.Segment.ps1"

        # Cargar Providers
        foreach ($file in $providerFiles) {
            Write-Verbose "[PPF]   Importing Provider: $($file.Name)"
            . $file.FullName
        }

        # Cargar Services
        foreach ($file in $serviceFiles) {
            Write-Verbose "[PPF]   Importing Service: $($file.Name)"
            . $file.FullName
        }

        # Cargar Segments
        foreach ($file in $segmentFiles) {
            Write-Verbose "[PPF]   Importing Segment: $($file.Name)"
            . $file.FullName
        }

        # Cargar otros archivos ps1 que no sean los anteriores ni tests
        $loadedFullNames = @(
            $providerFiles.FullName
            $serviceFiles.FullName
            $segmentFiles.FullName
        )

        $otherFiles = Get-ChildItem -Path $dir.FullName -Filter "*.ps1" |
            Where-Object {
                $_.FullName -notin $loadedFullNames -and $_.Name -notlike "*.Tests.ps1"
            }

        foreach ($file in $otherFiles) {
            Write-Verbose "[PPF]   Importing Other component: $($file.Name)"
            . $file.FullName
        }

        if (Get-Command Invoke-PPFEvent -ErrorAction SilentlyContinue) {
            Invoke-PPFEvent -EventName "ModuleLoaded" -EventArgs $moduleName
        }
    }

    Write-Verbose "[PPF] Modules initialization complete."

}
