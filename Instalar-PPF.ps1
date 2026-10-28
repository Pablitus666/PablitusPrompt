# ============================================================
# Pablitus Prompt Framework (PPF)
# Script de instalación completa
#
# Ejecuta esto para instalar PPF con todos los temas y funcionalidades
# ============================================================

$ErrorActionPreference = "Stop"

$repoRoot = Get-Location
$srcRoot = Join-Path $repoRoot "src"
$modulePath = Join-Path $env:USERPROFILE "Documents\PowerShell\Modules\PablitusPrompt"
$dotnetPublish = Join-Path $repoRoot "dotnet/publish"

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  Pablitus Prompt Framework - Instalación" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan

# 1. Crear directorio del módulo
if (-not (Test-Path -LiteralPath $modulePath)) {
    $null = New-Item -ItemType Directory -Path $modulePath -Force
    Write-Host "Creado: $modulePath" -ForegroundColor Green
}

# 2. Copiar TODO el contenido de src/ al módulo
Write-Host ""
Write-Host "Copiando archivos del núcleo..." -ForegroundColor Cyan
Get-ChildItem -Path "$srcRoot" -Recurse -File | ForEach-Object {
    $relPath = $_.FullName.Substring($srcRoot.Length + 1)
    $destPath = Join-Path $modulePath $relPath
    if (-not (Test-Path -LiteralPath (Split-Path $destPath))) {
        $null = New-Item -ItemType Directory -Path (Split-Path $destPath) -Force
    }
    Copy-Item -Path $_.FullName -Destination $destPath -Force
}

# 3. Copiar el núcleo .NET compilado a dotnet/publish/ dentro del módulo
Write-Host ""
Write-Host "Copiando núcleo .NET..." -ForegroundColor Cyan
$dotnetPublishDest = Join-Path $modulePath "dotnet/publish"
if (Test-Path -LiteralPath $dotnetPublish) {
    if (-not (Test-Path -LiteralPath $dotnetPublishDest)) {
        $null = New-Item -ItemType Directory -Path $dotnetPublishDest -Force
    }
    Get-ChildItem -Path "$dotnetPublish" -File | ForEach-Object {
        Copy-Item -Path $_.FullName -Destination "$dotnetPublishDest/" -Force
        Write-Host "  $($_.Name)" -ForegroundColor Green
    }
} else {
    Write-Host "ADVERTENCIA: No se encontró $dotnetPublish" -ForegroundColor Yellow
    Write-Host "   Ejecuta primero: scripts/Build-PPFDotNetCore.ps1" -ForegroundColor Yellow
}

# 4. Descargar e instalar Nerd Font (JetBrainsMono Nerd Font)
Write-Host ""
Write-Host "Instalando Nerd Font (necesaria para glifos PowerLine)..." -ForegroundColor Cyan

# Fuente primaria: nuestro release de GitHub (sin dependencia de terceros)
$nerdFontPrimaryUrl = "https://github.com/Pablitus666/PablitusPrompt/releases/latest/download/JetBrains_Mono.zip"
# Fuente de respaldo: repositorio oficial de nerd-fonts
$nerdFontFallbackUrl = "https://github.com/ryanox/nerd-fonts/releases/download/v3.2.1/JetBrainsMono.zip"

$tempFontZip = Join-Path $env:TEMP "JetBrainsMonoNerdFont.zip"
$tempFontDir = Join-Path $env:TEMP "JetBrainsMonoNerdFont"

# Determinar directorio de fuentes según el SO
$fontsDir = $null
$fontCacheCommand = $null
$isWindows = [System.OperatingSystem]::IsWindows()
$isMacOS = [System.OperatingSystem]::IsMacOS()
$isLinux = [System.OperatingSystem]::IsLinux()

if ($isWindows) {
    $fontsDir = Join-Path $env:SystemRoot "Fonts"
}
elseif ($isMacOS) {
    $fontsDir = Join-Path (Join-Path $env:HOME "Library") "Fonts"
    if (-not (Test-Path -LiteralPath $fontsDir)) {
        $null = New-Item -ItemType Directory -Path $fontsDir -Force
    }
}
elseif ($isLinux) {
    $fontsDir = Join-Path (Join-Path $env:HOME ".local") "share/fonts"
    if (-not (Test-Path -LiteralPath $fontsDir)) {
        $null = New-Item -ItemType Directory -Path $fontsDir -Force
    }
    $fontCacheCommand = "fc-cache"
}

try {
    if (-not (Test-Path -LiteralPath $tempFontZip)) {
        Write-Host "  Descargando JetBrainsMono Nerd Font desde nuestro release de GitHub..." -ForegroundColor Cyan
        try {
            Invoke-WebRequest -Uri $nerdFontPrimaryUrl -OutFile $tempFontZip -ErrorAction Stop
            Write-Host "  Descargado desde PPF GitHub Release" -ForegroundColor Green
        }
        catch {
            Write-Host "  No se pudo descargar desde PPF Release, intentando fuente de respaldo..." -ForegroundColor Yellow
            Invoke-WebRequest -Uri $nerdFontFallbackUrl -OutFile $tempFontZip -ErrorAction Stop
            Write-Host "  Descargado desde nerd-fonts (respaldo)" -ForegroundColor Green
        }
    }

    if (-not (Test-Path -LiteralPath $tempFontDir)) {
        $null = New-Item -ItemType Directory -Path $tempFontDir -Force
    }

    Expand-Archive -Path $tempFontZip -DestinationPath $tempFontDir -Force

    $fontFiles = Get-ChildItem -Path $tempFontDir -Filter "*.ttf" -Recurse | Where-Object {
        $_.Name -like "*NerdFont*" -or $_.Name -like "*Nerd Font*" -or $_.Name -like "*Complete*"
    }

    if ($fontFiles.Count -eq 0) {
        # Fallback: tomar todos los .ttf si no encontramos los específicos
        $fontFiles = Get-ChildItem -Path $tempFontDir -Filter "*.ttf" -Recurse
    }

    $installedCount = 0
    foreach ($fontFile in $fontFiles) {
        $destFont = Join-Path $fontsDir $fontFile.Name
        if (-not (Test-Path -LiteralPath $destFont)) {
            Copy-Item -Path $fontFile.FullName -Destination $destFont -Force
            Write-Host "  Instalada: $($fontFile.Name)" -ForegroundColor Green
        }
        $installedCount++
    }

    # Ejecutar fc-cache en Linux para actualizar el caché de fuentes
    if ($fontCacheCommand -and $installedCount -gt 0) {
        try {
            & $fontCacheCommand -f $fontsDir | Out-Null
            Write-Host "  Caché de fuentes actualizado (fc-cache)" -ForegroundColor Green
        }
        catch {
            # fc-cache puede no estar disponible; no es crítico
        }
    }

    Write-Host "  Total fuentes instaladas: $installedCount" -ForegroundColor Green

    # Limpiar archivos temporales
    Remove-Item -Path $tempFontZip -Force -ErrorAction SilentlyContinue
    Remove-Item -Path $tempFontDir -Recurse -Force -ErrorAction SilentlyContinue

    Write-Host ""
    Write-Host "  NOTA: Puede que necesites reiniciar tu terminal para que la fuente surta efecto." -ForegroundColor Yellow
    Write-Host "  Luego selecciona 'JetBrainsMono Nerd Font' en la configuración de tu terminal." -ForegroundColor Yellow
}
catch {
    Write-Host "  ADVERTENCIA: No se pudo instalar la Nerd Font automáticamente." -ForegroundColor Yellow
    Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Yellow
    Write-Host "   Puedes instalarla manualmente desde: https://www.nerdfonts.com/font-downloads" -ForegroundColor Yellow
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