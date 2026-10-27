# ============================================================
# Pablitus Prompt Framework (PPF)
# Script de instalación completa
#
# Ejecuta esto para instalar PPF con TODOS los temas
# y funcionalidades de Fase 3C y 3E
# ============================================================

$ErrorActionPreference = "Stop"

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  Pablitus Prompt Framework - Instalación" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan

$moduleRoot = Join-Path $env:USERPROFILE "Documents\PowerShell\Modules\PablitusPrompt"
$srcRoot = Join-Path (Get-Location) "src"

# 1. Crear directorio del módulo
if (-not (Test-Path -LiteralPath $modulePath)) {
    $null = New-Item -ItemType Directory -Path $modulePath -Force
    Write-Host "Creado: $modulePath" -ForegroundColor Green
}

# 2. Copiar TODO el directorio Core al módulo instalado
Write-Host ""
Write-Host "Copiando archivos del núcleo..." -ForegroundColor Cyan
Get-ChildItem -Path "$srcRoot/Core" -Recurse | ForEach-Object {
    $dest = Join-Path $modulePath $_.FullName.Substring($srcRoot.Length + 1)
    if (-not (Test-Path -LiteralPath (Split-Path $dest))) {
        $null = New-Item -ItemType Directory -Path (Split-Path $dest) -Force
    }
    Copy-Item -Path $_.FullName -Destination $dest -Force
}

# 3. Copiar todos los temas
Write-Host ""
Write-Host "Copiando temas..." -ForegroundColor Cyan
Get-ChildItem -Path "$srcRoot/Themes" -Filter "*.Theme.ps1" | ForEach-Object {
    Copy-Item -Path $_.FullName -Destination "$modulePath/Themes/" -Force
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
Get-ChildItem -Path "$srcRoot/ShellInit" -Filter "*.ps1" | ForEach-Object {
    Copy-Item -Path $_.FullName -Destination "$modulePath/ShellInit/" -Force
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
Write-Host '      $context = Invoke-Prompt'
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