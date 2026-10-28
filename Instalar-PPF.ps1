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

# 1.5. Descargar el módulo si está cargado para liberar los archivos DLL
$moduleLoadAttempts = 0
while ((Get-Module PablitusPrompt -ErrorAction SilentlyContinue) -and $moduleLoadAttempts -lt 3) {
    $moduleLoadAttempts++
    Write-Host ""
    Write-Host "Descargando módulo PablitusPrompt cargado (intento $moduleLoadAttempts) para liberar archivos DLL..." -ForegroundColor Cyan
    Remove-Module PablitusPrompt -ErrorAction SilentlyContinue
    Start-Sleep -Milliseconds 500
}
if (Get-Module PablitusPrompt -ErrorAction SilentlyContinue) {
    Write-Host ""
    Write-Host "ADVERTENCIA: No se pudo descargar el módulo PablitusPrompt." -ForegroundColor Yellow
    Write-Host "   Cierre todas las sesiones de PowerShell y vuelva a ejecutar el instalador." -ForegroundColor Yellow
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
    $copyFailed = $false
    Get-ChildItem -Path "$dotnetPublish" -File | ForEach-Object {
        $fileName = $_.Name
        $sourcePath = $_.FullName
        try {
            Copy-Item -Path $sourcePath -Destination "$dotnetPublishDest/" -Force -ErrorAction Stop
            Write-Host "  $fileName" -ForegroundColor Green
        }
        catch {
            $copyFailed = $true
            Write-Host "  ERROR: No se pudo copiar '$fileName' (el archivo está en uso por otro proceso)." -ForegroundColor Red
            Write-Host "         Cierre todas las sesiones de PowerShell y ejecute nuevamente: .\Instalar-PPF.ps1" -ForegroundColor Red
        }
    }
    if ($copyFailed) {
        Write-Host ""
        Write-Host "ADVERTENCIA: Algunos archivos no se pudieron copiar porque están en uso." -ForegroundColor Yellow
        Write-Host "   Cierre todas las ventanas de PowerShell y ejecute nuevamente: .\Instalar-PPF.ps1" -ForegroundColor Yellow
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
$osIsWindows = [System.OperatingSystem]::IsWindows()
$osIsMacOS = [System.OperatingSystem]::IsMacOS()
$osIsLinux = [System.OperatingSystem]::IsLinux()

if ($osIsWindows) {
    $fontsDir = Join-Path $env:SystemRoot "Fonts"
}
elseif ($osIsMacOS) {
    $fontsDir = Join-Path (Join-Path $env:HOME "Library") "Fonts"
    if (-not (Test-Path -LiteralPath $fontsDir)) {
        $null = New-Item -ItemType Directory -Path $fontsDir -Force
    }
}
elseif ($osIsLinux) {
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

# Configurar $PROFILE automáticamente con la persistencia de tema (totalmente autocontenido)
$profilePath = $PROFILE
$profileDir = Split-Path -Parent $profilePath
if (-not (Test-Path -LiteralPath $profileDir)) {
    $null = New-Item -ItemType Directory -Path $profileDir -Force
}

# Leer el contenido de ppf-theme-persist.ps1 para incrustarlo en el perfil
$ppfPersistContent = ""
$ppfPersistSourcePath = Join-Path $repoRoot "src/Core/ppf-theme-persist.ps1"
if (Test-Path -LiteralPath $ppfPersistSourcePath) {
    $ppfPersistContent = Get-Content -LiteralPath $ppfPersistSourcePath -Raw
}

$profileContent = @"
# ============================================
# Pablitus Prompt Framework - Configuración
# ============================================
Import-Module PablitusPrompt -Force

# Función de persistencia automática de tema (incrustada)
$script:PPFThemePrefPath = Join-Path $env:USERPROFILE "ppf-theme-pref.json"

function Set-PromptThemePersist {
    [CmdletBinding()]
    param(
        [string]$ThemeName,
        [string]$DotNetThemePath
    )

    $pref = @{}

    if ($PSBoundParameters.ContainsKey('ThemeName')) {
        Set-PromptTheme -Name $ThemeName -ErrorAction Stop
        $pref.Theme = $ThemeName
        Write-Host "Tema PPF establecido: $ThemeName" -ForegroundColor Green
    }

    if ($PSBoundParameters.ContainsKey('DotNetThemePath')) {
        $fullPath = (Resolve-Path -LiteralPath $DotNetThemePath -ErrorAction Stop).Path
        $env:PPF_USE_DOTNET_CORE = "1"
        Enable-PPFDotNetCore -ThemePath $fullPath -IgnoreUnsupported -ErrorAction Stop | Out-Null
        $pref.DotNetTheme = $fullPath
        Write-Host "Tema .NET/OMP establecido: $fullPath" -ForegroundColor Green
    }

    $pref | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $script:PPFThemePrefPath -Force
    Write-Host "Preferencia guardada en $($script:PPFThemePrefPath)" -ForegroundColor Cyan
}

function Restore-PPFTHEME {
    if (-not (Test-Path -LiteralPath $script:PPFThemePrefPath -PathType Leaf)) {
        return
    }

    try {
        $pref = Get-Content -LiteralPath $script:PPFThemePrefPath -Raw | ConvertFrom-Json

        if ($pref.DotNetTheme) {
            $env:PPF_USE_DOTNET_CORE = "1"
            Enable-PPFDotNetCore -ThemePath $pref.DotNetTheme -IgnoreUnsupported -ErrorAction SilentlyContinue | Out-Null
        }

        if ($pref.Theme) {
            Set-PromptTheme -Name $pref.Theme -ErrorAction SilentlyContinue
        }
    }
    catch {
        # Silenciosamente ignorar errores de restauración
    }
}

# Restaurar el último tema guardado (si existe)
Restore-PPFTHEME -ErrorAction SilentlyContinue

# Configurar el prompt de PowerShell
function global:prompt {
    try {
        `$context = Invoke-Prompt
        Get-PromptString -Context `$context -Renderer 'PowerLine'
    }
    catch {
        'PS ' + `$executionContext.SessionState.Path.CurrentLocation + '➜ '
    }
}
"@

# Siempre escribir el perfil (forzar actualización completa)
# Primero, eliminar cualquier sección anterior de PPF del perfil
if (Test-Path -LiteralPath $profilePath) {
    $existingContent = Get-Content -LiteralPath $profilePath -Raw
    # Remover secciones anteriores de PPF (entre marcadores)
    if ($existingContent -match '# ============================================\r?\n# Pablitus Prompt Framework - Configuración.*?\r?\n# ============================================') {
        $existingContent = $existingContent -replace '# ============================================\r?\n# Pablitus Prompt Framework - Configuración.*?\r?\n# ============================================\r?\n?', ''
        $existingContent = $existingContent.TrimEnd("`r`n") + "`r`n"
        Set-Content -LiteralPath $profilePath -Value $existingContent
    }
}

# Agregar la nueva configuración al final
Add-Content -LiteralPath $profilePath -Value "`n$profileContent"
Write-Host ""
Write-Host "Perfil de PowerShell configurado automáticamente en:" -ForegroundColor Green
Write-Host "  $profilePath" -ForegroundColor Green
Write-Host ""
Write-Host "Cierra y vuelve a abrir PowerShell para aplicar los cambios." -ForegroundColor Yellow

Write-Host ""
Write-Host "Temas disponibles:" -ForegroundColor Cyan
Get-ChildItem -Path "$modulePath/Themes" -Filter "*.Theme.ps1" | Select-Object Name | Sort-Object Name | ForEach-Object {
    Write-Host "  - $($_.Name.Replace('.Theme.ps1',''))" -ForegroundColor Gray
}