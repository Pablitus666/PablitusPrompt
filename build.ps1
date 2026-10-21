# ============================================================
# Pablitus Prompt Framework (PPF) - Build & Release Automation
# build.ps1
# ============================================================

$ErrorActionPreference = "Stop"

$scriptDir = $PSScriptRoot
if (-not $scriptDir) { $scriptDir = Get-Location }

$srcDir = Join-Path $scriptDir "src"
$testsDir = Join-Path $scriptDir "tests"
$buildDir = Join-Path $scriptDir "build"
$publishDir = Join-Path $buildDir "PablitusPrompt"
$manifestPath = Join-Path $srcDir "PablitusPrompt.psd1"

# 1. Load Manifest Data to get current version
Write-Host "Cargando manifiesto de módulo desde $manifestPath..." -ForegroundColor Cyan
$manifestData = Import-PowerShellDataFile -Path $manifestPath
$version = $manifestData.ModuleVersion
Write-Host "Versión detectada: $version" -ForegroundColor Green

# 2. Run Pester Tests
Write-Host "`n[1/6] Ejecutando pruebas de Pester..." -ForegroundColor Cyan
$pesterResult = Invoke-Pester -Path $testsDir -PassThru
if ($pesterResult.FailedCount -gt 0) {
    throw "¡Fallo en las pruebas unitarias/de integración! ($($pesterResult.FailedCount) pruebas fallidas)"
}
Write-Host "Pruebas unitarias completadas con éxito." -ForegroundColor Green

# 3. Code Coverage Validation
Write-Host "`n[2/6] Validando cobertura de código..." -ForegroundColor Cyan
$srcFiles = Get-ChildItem -Path $srcDir -Recurse -Filter "*.ps1" | Where-Object {
    $_.Name -notlike "*.Tests.*" -and
    $_.Name -ne "Bootstrap.ps1" -and
    $_.Name -ne "Microsoft.PowerShell_profile.ps1"
}
$ccResult = Invoke-Pester -Path $testsDir -CodeCoverage $srcFiles.FullName -PassThru

# Pester 5.8 exposes CommandsAnalyzedCount/CommandsMissedCount; older 5.x used
# NumberOfCommandsAnalyzed/NumberOfCommandsMissed. Support both.
$coverage = $ccResult.CodeCoverage
if ($coverage.PSObject.Properties['CommandsAnalyzedCount']) {
    $analyzed = [int]$coverage.CommandsAnalyzedCount
    $missed = [int]$coverage.CommandsMissedCount
}
else {
    $analyzed = [int]$coverage.NumberOfCommandsAnalyzed
    $missed = [int]$coverage.NumberOfCommandsMissed
}

if ($analyzed -le 0) {
    throw "La medición de cobertura no analizó ningún comando. Revisa la configuración de Pester/CodeCoverage."
}

$covered = $analyzed - $missed
$coveragePct = ($covered / $analyzed) * 100

Write-Host "Cobertura de código: $([math]::Round($coveragePct, 2))% ($covered de $analyzed comandos cubiertos, $missed no cubiertos)" -ForegroundColor Yellow
$minCoverage = 90.0
if ($coveragePct -lt $minCoverage) {
    throw "Cobertura insuficiente: $([math]::Round($coveragePct, 2))% < ${minCoverage}%. El build se detiene."
}
Write-Host "¡Objetivo de cobertura cumplido (>90%)!" -ForegroundColor Green

# 4. Run Benchmarks
Write-Host "`n[3/6] Ejecutando Benchmarks de rendimiento..." -ForegroundColor Cyan
# Import module to run benchmarks
Import-Module $manifestPath -Force
$benchmarksDir = Join-Path $scriptDir "benchmarks"
if (-not (Test-Path $benchmarksDir)) {
    $null = New-Item -ItemType Directory -Path $benchmarksDir -Force
}

Write-Host "Ejecutando Measure-PromptDetailed (50 iteraciones)..."
$detailedRep = Measure-PromptDetailed -Iterations 50 -ExportDir $benchmarksDir
Write-Host "Ejecutando Measure-PromptCacheComparison (50 iteraciones)..."
$compRep = Measure-PromptCacheComparison -Iterations 50

# Save benchmark summaries
$benchReportPath = Join-Path $benchmarksDir "release-benchmark-report.txt"
$detailedRep | Out-File -FilePath $benchReportPath -Encoding utf8
Write-Host "Benchmarks completados y guardados en '$benchReportPath'." -ForegroundColor Green

# 5. Dynamic Documentation Update
Write-Host "`n[4/6] Generando documentación de API dinámica..." -ForegroundColor Cyan
$docPath = Join-Path $scriptDir "docs\API.md"

# Dot-source context classes so Get-Help can resolve [PromptContext]
. (Join-Path $srcDir "Core\Prompt.Context.ps1")

$apiHeader = @"
# Pablitus Prompt Framework v$version — API Reference Guide
> **Pablitus Prompt Framework v$version API Documentation**

This document describes the official public API and core internal APIs of the Pablitus Prompt Framework (PPF).

---

## 1. Public API
These functions represent the stable public interface of PPF. They will not have breaking signature changes in any v1.x release.
"@

$sb = New-Object System.Text.StringBuilder
[void]$sb.AppendLine($apiHeader)

# List functions exported in the manifest
$functions = $manifestData.FunctionsToExport | Sort-Object
foreach ($func in $functions) {
    [void]$sb.AppendLine("`n### ``$func``")
    $help = Get-Help $func -ErrorAction SilentlyContinue
    if ($help) {
        $synopsis = $help.synopsis
        $description = $help.description
        if ($synopsis) {
            [void]$sb.AppendLine("- **Synopsis**: $synopsis")
        }
        if ($description) {
            [void]$sb.AppendLine("- **Description**: $description")
        }
    } else {
        [void]$sb.AppendLine("- **Description**: Función pública exportada en el manifiesto del módulo.")
    }
}

$sb.ToString() | Out-File -FilePath $docPath -Encoding utf8
Write-Host "Documentación de API actualizada en '$docPath'." -ForegroundColor Green

# 6. Packaging
Write-Host "`n[5/6] Empaquetando módulo..." -ForegroundColor Cyan
if (Test-Path $buildDir) {
    Remove-Item $buildDir -Recurse -Force
}
$null = New-Item -ItemType Directory -Path $publishDir -Force

# Copy files
Copy-Item -Path $srcDir\* -Destination $publishDir -Recurse -Force
Copy-Item -Path (Join-Path $scriptDir "LICENSE") -Destination $publishDir -Force
Copy-Item -Path (Join-Path $scriptDir "README.md") -Destination $publishDir -Force
Copy-Item -Path (Join-Path $scriptDir "CHANGELOG.md") -Destination $publishDir -Force

# Create Zip package
$zipPath = Join-Path $buildDir "PablitusPrompt-v$version.zip"
Write-Host "Creando archivo comprimido $zipPath..."
Compress-Archive -Path "$publishDir\*" -DestinationPath $zipPath -Force
Write-Host "Módulo empaquetado con éxito." -ForegroundColor Green

# 7. Changelog and Publish Preparation
Write-Host "`n[6/6] Preparando publicación de artefactos..." -ForegroundColor Cyan
$artifactsDir = Join-Path $scriptDir "artifacts"
if (-not (Test-Path $artifactsDir)) {
    $null = New-Item -ItemType Directory -Path $artifactsDir -Force
}
Copy-Item -Path $zipPath -Destination $artifactsDir -Force
Write-Host "Artefacto listo en: $(Join-Path $artifactsDir (Split-Path $zipPath -Leaf))" -ForegroundColor Green
Write-Host "`n=== PROCESO DE BUILD Y RELEASE COMPLETADO CON ÉXITO ===" -ForegroundColor Green
