# ============================================================
# Pablitus Prompt Framework (PPF)
# Script de instalación completa
#
# Ejecuta esto para instalar PPF con todos los temas y funcionalidades
# ============================================================

$ErrorActionPreference = "Stop"

$srcRoot = Join-Path (Get-Location) "src"
$modulePath = Join-Path $env:USERPROFILE "Documents\PowerShell\Modules\PablitusPrompt"

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  Pablitus Prompt Framework - Instalación" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan

# 1. Crear directorio del módulo
if (-not (Test-Path -LiteralPath $modulePath)) {
    $null = New-Item -ItemType Directory -Path $modulePath -Force
    Write-Host "Creado: $modulePath" -ForegroundColor Green
}

# 2. Copiar TODOS los archivos de src/Core/
Write-Host ""
Write-Host "Copiando archivos del núcleo..." -ForegroundColor Cyan
Get-ChildItem -Path "$srcRoot/Core" -Recurse -File | ForEach-Object {
    $relPath = $_.FullName.Substring($srcRoot.Length + 1)
    $destPath = Join-Path $modulePath $relPath
    if (-not (Test-Path -LiteralPath (Split-Path $destPath))) {
        $null = New-Item -ItemType Directory -Path (Split-Path $destPath) -Force
    }
    Copy-Item -Path $_.FullName -Destination $destPath -Force
}

# 3. Copiar todos los temas
Write-Host ""
Write-Host "Copiando temas..." -ForegroundColor Cyan
$themesDest = Join-Path $modulePath "Themes"
if (-not (Test-Path -LiteralPath $themesDest)) {
    $null = New-Item -ItemType Directory -Path $themesDest -Force
}
Get-ChildItem -Path "$srcRoot/Themes" -Filter "*.Theme.ps1" | ForEach-Object {
    Copy-Item -Path $_.FullName -Destination $themesDest -Force
    Write-Host "  Tema: $($_.Name)" -ForegroundColor Green
}

# 4. Copiar archivos raíz del módulo
Write-Host ""
Write-Host "Copiando archivos del módulo..." -ForegroundColor Cyan
Get-ChildItem -Path "$srcRoot" -Filter "*.ps1" | ForEach-Object {
    Copy-Item -Path $_.FullName -Destination "$modulePath/" -Force
    Write-Host "  $($_.Name)" -ForegroundColor Green
}
Get-ChildItem -Path "$srcRoot/PablitusPrompt.psd1" | ForEach-Object {
    Copy-Item -Path $_.FullName -Destination "$modulePath/" -Force
    Write-Host "  $($_.Name)" -ForegroundColor Green
}

# 5. Copiar scripts de ShellInit
Write-Host ""
Write-Host "Copiando scripts de ShellInit..." -ForegroundColor Cyan
$shellInitDest = Join-Path $modulePath "ShellInit"
if (-not (Test-Path -LiteralPath $shellInitDest)) {
    $null = New-Item -ItemType Directory -Path $shellInitDest -Force
}
Get-ChildItem -Path "$srcRoot/ShellInit" -Filter "*.ps1" | ForEach-Object {
    Copy-Item -Path $_.FullName -Destination $shellInitDest -Force
    Write-Host "  $($_.Name)" -ForegroundColor Green
}

Write-Host ""
Write-Host "="*60 -ForegroundColor Cyan
Write-Host "  INSTALACIÓN COMPLETADA" -ForegroundColor Green
Write-Host "="*60 -ForegroundColor Cyan

Write-Host ""
Write-Host "Para usar PPF, agrega esto a tu '$PROFILE':" -ForegroundColor Yellow
Write-Host ""
Write-Host "  Import-Module PablitusPrompt -Force"
Write-Host "  Set-PromptTheme -Name 'Pablitus Stack'"
Write-Host "  function global:prompt {"
Write-Host "    try {"
Write-Host "      \$context = Invoke-Prompt"
Write-Host "      Get-PromptString -Context \$context -Renderer 'Plain'"
Write-Host "    } catch {"
Write-Host "      'PS ' + \$executionContext.SessionState.Path.CurrentLocation + '➜ '"
Write-Host "    }"
Write-Host "  }"
Write-Host ""
Write-Host "Temas disponibles:" -ForegroundColor Cyan
Get-ChildItem -Path "$modulePath/Themes" -Filter "*.Theme.ps1" | Select-Object Name | Sort-Object Name | ForEach-Object {
    Write-Host "  - $($_.Name.Replace('.Theme.ps1',''))" -ForegroundColor Gray
}