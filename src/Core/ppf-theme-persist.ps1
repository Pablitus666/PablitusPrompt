# ============================================================
# Pablitus Prompt Framework (PPF)
# Función de persistencia automática de tema
# ============================================================

$script:PPFThemePrefPath = Join-Path $env:USERPROFILE "ppf-theme-pref.json"

function Set-PromptThemePersist {
    <#
    .SYNOPSIS
        Cambia el tema de PPF y lo persiste para sesiones futuras.

    .DESCRIPTION
        Guarda la preferencia de tema (tema PPF nativo y/o tema de Oh My Posh vía .NET)
        en un archivo JSON en el directorio de usuario. Al iniciar PowerShell, el perfil
        carga automáticamente el último tema usado.

    .PARAMETER ThemeName
        Nombre del tema PPF nativo (por ejemplo: 'Pablitus Minimal', 'Pablitus Stack', 'Nord').

    .PARAMETER DotNetThemePath
        Ruta al archivo .omp.json de Oh My Posh (requiere .NET core habilitado).

    .EXAMPLE
        Set-PromptThemePersist -ThemeName 'Pablitus Minimal'
        # Cambia al tema Pablitus Minimal y lo guarda para la próxima sesión.

    .EXAMPLE
        Set-PromptThemePersist -DotNetThemePath 'D:\Temas\cinnamon.omp.json'
        # Activa el tema cinnamon de Oh My Posh vía .NET y lo persiste.

    .EXAMPLE
        Set-PromptThemePersist -ThemeName 'Pablitus Minimal' -DotNetThemePath 'D:\Temas\cinnamon.omp.json'
        # Guarda ambas preferencias.
    #>

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

    # Guardar preferencia
    $pref | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $script:PPFThemePrefPath -Force
    Write-Host "Preferencia guardada en $($script:PPFThemePrefPath)" -ForegroundColor Cyan
}

function Restore-PPFTHEME {
    <#
    .SYNOPSIS
        Restaura el último tema guardado (para usar en el perfil de PowerShell).
    #>

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
        Write-PPFLog -Level "DEBUG" -Message "No se pudo restaurar el tema persistente: $($_.Exception.Message)"
    }
}

# Auto-cargar al iniciar sesión (agregar esto al final de tu $PROFILE):
# Restore-PPFTHEME