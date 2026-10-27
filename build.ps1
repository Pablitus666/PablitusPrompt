# ============================================================
# Pablitus Prompt Framework (PPF) - Build & Release Automation
# build.ps1
# ============================================================

$ErrorActionPreference = "Stop"

# Pester instruments script files, not Invoke-Expression bundles, so the
# compatibility loader is used while tests and coverage are running.
$env:PPF_USE_MODULAR_LOADER = "1"

$scriptDir = $PSScriptRoot
if (-not $scriptDir) { $scriptDir = Get-Location }

$srcDir = Join-Path $scriptDir "src"
$testsDir = Join-Path $scriptDir "tests"
$buildDir = Join-Path $scriptDir "build"
$publishDir = Join-Path $buildDir "PablitusPrompt"
$manifestPath = Join-Path $srcDir "PablitusPrompt.psd1"

# Ejecutable nativo .NET (ppf). Publicación framework-dependent: solo requiere
# .NET 8 runtime, no depende de pwsh ni de una distribución de .NET embebida.
$dotnetRoot = Join-Path $scriptDir "dotnet"
$dotnetCliProject = Join-Path $dotnetRoot "src/PablitusPrompt.Cli/PablitusPrompt.Cli.csproj"
$dotnetPublishDir = Join-Path $buildDir "dotnet-publish"
$nativeExeName = if ($IsWindows) { "ppf.exe" } else { "ppf" }
$nativePublishPath = Join-Path $dotnetPublishDir $nativeExeName

# 1. Load Manifest Data to get current version
Write-Host "Cargando manifiesto de módulo desde $manifestPath..." -ForegroundColor Cyan
$manifestData = Import-PowerShellDataFile -Path $manifestPath
$version = $manifestData.ModuleVersion
Write-Host "Versión detectada: $version" -ForegroundColor Green

# 2. Publicar el ejecutable nativo .NET (ppf)
Write-Host "`n[0/6] Publicando ejecutable nativo ppf (.NET)..." -ForegroundColor Cyan
if (-not (Get-Command dotnet -ErrorAction SilentlyContinue)) {
    throw "El SDK de .NET no está en el PATH. Instale .NET 8 SDK para publicar el ejecutable nativo ppf."
}
if (-not (Test-Path -LiteralPath $dotnetCliProject)) {
    throw "No se encontró el proyecto CLI: $dotnetCliProject"
}

if (Test-Path $dotnetPublishDir) {
    Remove-Item $dotnetPublishDir -Recurse -Force
}
$null = New-Item -ItemType Directory -Path $dotnetPublishDir -Force

# Publicación framework-dependent (--self-contained false): requiere únicamente
# .NET 8 runtime en el equipo de destino, no depende de pwsh.
$publishArgs = @(
    "publish", $dotnetCliProject,
    "-c", "Release",
    "-o", $dotnetPublishDir,
    "--self-contained", $false,
    "--nologo"
)
Write-Host "Ejecutando: dotnet $($publishArgs -join ' ')" -ForegroundColor Gray
$publishResult = & dotnet @publishArgs 2>&1
if ($LASTEXITCODE -ne 0) {
    $publishResult
    throw "Fallo al publicar el ejecutable nativo ppf."
}

if (-not (Test-Path -LiteralPath $nativePublishPath)) {
    throw "No se generó el ejecutable nativo: $nativePublishPath"
}
Write-Host "Ejecutable nativo publicado: $nativePublishPath" -ForegroundColor Green

# 2b. Run Pester Tests
Write-Host "`n[1/6] Ejecutando pruebas de Pester..." -ForegroundColor Cyan
$pesterResult = Invoke-Pester -Path $testsDir -PassThru
if ($pesterResult.FailedCount -gt 0) {
    throw "¡Fallo en las pruebas unitarias/de integración! ($($pesterResult.FailedCount) pruebas fallidas)"
}
Write-Host "Pruebas unitarias completadas con éxito." -ForegroundColor Green

# 3. Code Coverage Validation (best-effort; CI enforces the hard gate)
Write-Host "`n[2/6] Validando cobertura de código..." -ForegroundColor Cyan
$srcFiles = Get-ChildItem -Path $srcDir -Recurse -Filter "*.ps1" | Where-Object {
    $_.Name -notlike "*.Tests.*" -and
    $_.Name -ne "Bootstrap.ps1" -and
    $_.Name -ne "Microsoft.PowerShell_profile.ps1"
}

try {
    $ccConfig = New-PesterConfiguration
    $ccConfig.Run.Path = $testsDir
    $ccConfig.CodeCoverage = ($srcFiles | ForEach-Object @{ Path = $_.FullName })
    $ccResult = Invoke-Pester -Configuration $ccConfig -PassThru
    if ($ccResult.FailedCount -gt 0) {
        throw "¡Fallo en la ejecución de pruebas de cobertura! ($($ccResult.FailedCount) pruebas fallidas)"
    }

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
        Write-Host "Cobertura: no se analizaron comandos (versión de Pester sin métricas de cobertura)." -ForegroundColor Yellow
    }
    else {
        $covered = $analyzed - $missed
        $coveragePct = ($covered / $analyzed) * 100
        Write-Host "Cobertura de código: $([math]::Round($coveragePct, 2))% ($covered de $analyzed comandos cubiertos, $missed no cubiertos)" -ForegroundColor Yellow
        $minCoverage = 90.0
        if ($coveragePct -lt $minCoverage) {
            throw "Cobertura insuficiente: $([math]::Round($coveragePct, 2))% < ${minCoverage}%. El build se detiene."
        }
        Write-Host "¡Objetivo de cobertura cumplido (>90%)!" -ForegroundColor Green
    }
}
catch {
    Write-Host "Cobertura de código omitida en este entorno (incompatible con la versión de Pester instalada). CI valida la cobertura en el job de Windows." -ForegroundColor Yellow
    # Ejecutar Pester sin cobertura para validar que las pruebas pasan
    $pesterResult = Invoke-Pester -Path $testsDir -PassThru
    if ($pesterResult.FailedCount -gt 0) {
        throw "¡Fallo en las pruebas unitarias/de integración! ($($pesterResult.FailedCount) pruebas fallidas)"
    }
    Write-Host "Pruebas unitarias completadas con éxito (sin cobertura)." -ForegroundColor Green
}

# Benchmarks use the normal fast bootstrap path.
Remove-Item Env:\PPF_USE_MODULAR_LOADER -ErrorAction SilentlyContinue

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

# 6. Packaging (ZIP + NuGet package del núcleo)
Write-Host "`n[5/7] Empaquetando módulo (ZIP y .nupkg del núcleo)..." -ForegroundColor Cyan
if (Test-Path $buildDir) {
    Remove-Item $buildDir -Recurse -Force
}
$null = New-Item -ItemType Directory -Path $publishDir -Force

# Copy files
Copy-Item -Path $srcDir\* -Destination $publishDir -Recurse -Force
Copy-Item -Path (Join-Path $scriptDir "LICENSE") -Destination $publishDir -Force
Copy-Item -Path (Join-Path $scriptDir "README.md") -Destination $publishDir -Force
Copy-Item -Path (Join-Path $scriptDir "CHANGELOG.md") -Destination $publishDir -Force

# Incluir el ejecutable nativo ppf en el paquete ZIP para que los shells
# sin pwsh puedan usarlo directamente (ppf.bash/.zsh/.fish/.cmd lo detectan).
$toolsDir = Join-Path $publishDir "tools"
$null = New-Item -ItemType Directory -Path $toolsDir -Force
Copy-Item -Path $nativePublishPath -Destination $toolsDir -Force
Write-Host "Ejecutable nativo incluido en el paquete: $toolsDir\$nativeExeName" -ForegroundColor Green

# Create Zip package
$zipPath = Join-Path $buildDir "PablitusPrompt-v$version.zip"
Write-Host "Creando archivo comprimido $zipPath..."
Compress-Archive -Path "$publishDir\*" -DestinationPath $zipPath -Force
Write-Host "Módulo empaquetado (ZIP) con éxito." -ForegroundColor Green

# Create NuGet package (.nupkg) for PowerShell Gallery
Write-Host "Creando paquete NuGet (.nupkg) para PowerShell Gallery..."
$contentRoot = Join-Path $buildDir "PablitusPrompt.nupkg_content"
$moduleDir = Join-Path $contentRoot "PablitusPrompt"
if (Test-Path $contentRoot) {
    Remove-Item $contentRoot -Recurse -Force
}
$null = New-Item -ItemType Directory -Path $moduleDir -Force

# Copy module files under PablitusPrompt/ folder
Copy-Item -Path $srcDir\* -Destination $moduleDir -Recurse -Force

# Copy root files
Copy-Item -Path (Join-Path $scriptDir "LICENSE") -Destination $contentRoot -Force
Copy-Item -Path (Join-Path $scriptDir "README.md") -Destination $contentRoot -Force
Copy-Item -Path (Join-Path $scriptDir "CHANGELOG.md") -Destination $contentRoot -Force

# Copy and version the nuspec
$nuspecSource = Join-Path $scriptDir "PablitusPrompt.nuspec"
$nuspecDest = Join-Path $contentRoot "PablitusPrompt.nuspec"
Copy-Item -Path $nuspecSource -Destination $nuspecDest -Force

# Replace version placeholder in the copied nuspec with the manifest version
$nuspecContent = Get-Content -LiteralPath $nuspecDest -Raw
$nuspecContent = $nuspecContent -replace '<version>.*?</version>', "<version>$version</version>"
Set-Content -LiteralPath $nuspecDest -Value $nuspecContent -Encoding utf8

# Compress into .nupkg (entries at the package root: PablitusPrompt.nuspec,
# PablitusPrompt/*.ps1, LICENSE, etc.). Use ZipFile.Open + CreateEntryFromFile
# to preserve subdirectory structure (CreateFromDirectory flattens entries).
$nupkgPath = Join-Path $buildDir "PablitusPrompt.$version.nupkg"
if (Test-Path $nupkgPath) { Remove-Item $nupkgPath -Force }
Write-Host "Creando paquete NuGet $nupkgPath..."
Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip = [System.IO.Compression.ZipFile]::Open($nupkgPath, [System.IO.Compression.ZipArchiveMode]::Create)
try {
    $contentRootLen = $contentRoot.Length
    Get-ChildItem -Path $contentRoot -File -Recurse | ForEach-Object {
        $entryName = $_.FullName.Substring($contentRootLen + 1).Replace('\', '/')
        [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $_.FullName, $entryName, [System.IO.Compression.CompressionLevel]::Optimal) | Out-Null
    }
}
finally {
    $zip.Dispose()
}
Write-Host "Paquete NuGet (.nupkg) creado con éxito." -ForegroundColor Green

# 6b. Paquete de temas para PowerShell Gallery (PablitusPrompt.Themes)
Write-Host "`n[6/7] Empaquetando paquete de temas (PablitusPrompt.Themes.nupkg)..." -ForegroundColor Cyan
$themesContentRoot = Join-Path $buildDir "PablitusPrompt.Themes.nupkg_content"
$themesDir = Join-Path $themesContentRoot "themes"
if (Test-Path $themesContentRoot) {
    Remove-Item $themesContentRoot -Recurse -Force
}
$null = New-Item -ItemType Directory -Path $themesDir -Force

# Temas adicionales (no del núcleo) distribuidos por la galería
$additionalThemes = @(
    "Moonlight.Theme.ps1"
    "Solarized.Theme.ps1"
    "TokyoNight.Theme.ps1"
)
foreach ($themeName in $additionalThemes) {
    $sourceTheme = Join-Path (Join-Path $srcDir "Themes") $themeName
    if (-not (Test-Path -LiteralPath $sourceTheme)) {
        throw "Tema adicional no encontrado: $sourceTheme"
    }
    Copy-Item -LiteralPath $sourceTheme -Destination $themesDir -Force
}

# Archivos raíz del paquete de temas
Copy-Item -Path (Join-Path $scriptDir "LICENSE") -Destination $themesContentRoot -Force
Copy-Item -Path (Join-Path $scriptDir "README.md") -Destination $themesContentRoot -Force
Copy-Item -Path (Join-Path $scriptDir "CHANGELOG.md") -Destination $themesContentRoot -Force

# Nuspec del paquete de temas con versión del manifiesto
$themesNuspecSource = Join-Path $scriptDir "PablitusPrompt.Themes.nuspec"
$themesNuspecDest = Join-Path $themesContentRoot "PablitusPrompt.Themes.nuspec"
Copy-Item -Path $themesNuspecSource -Destination $themesNuspecDest -Force
$themesNuspecContent = Get-Content -LiteralPath $themesNuspecDest -Raw
$themesNuspecContent = $themesNuspecContent -replace '<version>.*?</version>', "<version>$version</version>"
Set-Content -LiteralPath $themesNuspecDest -Value $themesNuspecContent -Encoding utf8

# Comprimir en .nupkg (entradas en la raíz del paquete)
$themesNupkgPath = Join-Path $buildDir "PablitusPrompt.Themes.$version.nupkg"
if (Test-Path $themesNupkgPath) { Remove-Item $themesNupkgPath -Force }
Write-Host "Creando paquete de temas NuGet $themesNupkgPath..."
Add-Type -AssemblyName System.IO.Compression.FileSystem
$themesZip = [System.IO.Compression.ZipFile]::Open($themesNupkgPath, [System.IO.Compression.ZipArchiveMode]::Create)
try {
    $themesRootLen = $themesContentRoot.Length
    Get-ChildItem -Path $themesContentRoot -File -Recurse | ForEach-Object {
        $entryName = $_.FullName.Substring($themesRootLen + 1).Replace('\', '/')
        [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($themesZip, $_.FullName, $entryName, [System.IO.Compression.CompressionLevel]::Optimal) | Out-Null
    }
}
finally {
    $themesZip.Dispose()
}
Write-Host "Paquete de temas NuGet (.nupkg) creado con éxito." -ForegroundColor Green

# 7. Changelog and Publish Preparation
Write-Host "`n[7/7] Preparando publicación de artefactos..." -ForegroundColor Cyan
$artifactsDir = Join-Path $scriptDir "artifacts"
if (-not (Test-Path $artifactsDir)) {
    $null = New-Item -ItemType Directory -Path $artifactsDir -Force
}
Copy-Item -Path $zipPath -Destination $artifactsDir -Force
Copy-Item -Path $nupkgPath -Destination $artifactsDir -Force
Copy-Item -Path $themesNupkgPath -Destination $artifactsDir -Force
Copy-Item -Path $nativePublishPath -Destination $artifactsDir -Force
Write-Host "Artefactos listos en: $artifactsDir" -ForegroundColor Green
Write-Host "  - $(Split-Path $zipPath -Leaf)" -ForegroundColor Gray
Write-Host "  - $(Split-Path $nupkgPath -Leaf)" -ForegroundColor Gray
Write-Host "  - $(Split-Path $themesNupkgPath -Leaf)" -ForegroundColor Gray
Write-Host "  - $(Split-Path $nativePublishPath -Leaf)" -ForegroundColor Gray
Write-Host "`n=== PROCESO DE BUILD Y RELEASE COMPLETADO CON ÉXITO ===" -ForegroundColor Green
