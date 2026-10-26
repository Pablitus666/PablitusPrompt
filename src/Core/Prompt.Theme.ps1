# ============================================================
# Pablitus Prompt Framework (PPF)
# Prompt.Theme.ps1
# ============================================================

$script:PromptThemes = @{}
$script:ActiveThemeName = "Default"
$script:ThemeBaselineSegments = $null

function Get-PPFThemeBaseline {
    # Snapshot the effective base configuration the first time a theme is
    # applied. Themes only declare overrides, so switching from a theme that
    # hid a segment (for example Kali) must restore the baseline first.
    if ($null -eq $script:ThemeBaselineSegments) {
        $baseline = @{}
        foreach ($entry in @($script:PromptSegments)) {
            $config = Get-SegmentConfiguration -Name $entry.Name
            $copy = @{}
            if ($config -is [System.Collections.IDictionary]) {
                foreach ($key in $config.Keys) {
                    $copy[$key] = $config[$key]
                }
            }
            $baseline[$entry.Name] = $copy
        }
        $script:ThemeBaselineSegments = $baseline
    }

    return $script:ThemeBaselineSegments
}

function Reset-PPFThemeSegments {
    $baseline = Get-PPFThemeBaseline
    foreach ($segmentName in $baseline.Keys) {
        $copy = @{}
        foreach ($key in $baseline[$segmentName].Keys) {
            $copy[$key] = $baseline[$segmentName][$key]
        }
        Set-SegmentConfiguration -Name $segmentName -Configuration $copy
    }
}

function Register-PromptTheme {

    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [hashtable]$Palette,

        [Parameter(Mandatory)]
        [hashtable]$Icons,

        [hashtable]$Segments = @{}
    )

    $script:PromptThemes[$Name] = [PSCustomObject]@{
        Name     = $Name
        Palette  = $Palette
        Icons    = $Icons
        Segments = $Segments
    }

}

function Import-PromptTheme {

    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias("FullName", "PSPath")]
        [string[]]$Path,

        [switch]$PassThru
    )

    begin {
        $importedThemes = [System.Collections.Generic.List[string]]::new()
        $knownThemes = @($script:PromptThemes.Keys)
    }

    process {
        foreach ($item in $Path) {
            $resolvedItems = @(Resolve-Path -Path $item -ErrorAction Stop)

            foreach ($resolvedItem in $resolvedItems) {
                $target = Get-Item -LiteralPath $resolvedItem.Path -ErrorAction Stop
                $themeFiles = if ($target.PSIsContainer) {
                    @(Get-ChildItem -LiteralPath $target.FullName -Filter "*.Theme.ps1" -File |
                        Sort-Object Name)
                }
                else {
                    @($target)
                }

                foreach ($themeFile in $themeFiles) {
                    . $themeFile.FullName
                }
            }
        }

        # A theme file may register one or more themes. Report only new names,
        # and only when the caller asks for objects, so profile startup stays quiet.
        foreach ($name in $script:PromptThemes.Keys) {
            if ($name -notin $knownThemes -and $name -notin $importedThemes) {
                $importedThemes.Add($name)
            }
        }
        $knownThemes = @($script:PromptThemes.Keys)
    }

    end {
        if ($PassThru) {
            foreach ($name in $importedThemes) {
                Get-PromptTheme -Name $name
            }
        }
    }

}

function Set-PromptTheme {

    param(
        [Parameter(Mandatory)]
        [string]$Name
    )

    if (-not $script:PromptThemes.ContainsKey($Name)) {
        throw "Theme '$Name' is not registered."
    }

    $script:ActiveThemeName = $Name

    # Restore the base segment configuration before applying the new theme so
    # visibility and icon changes do not leak between themes.
    Reset-PPFThemeSegments

    # Invalida la caché de tema/segmento para evitar fugas de estado entre
    # temas (colores, iconos y visibilidad resueltos con el tema anterior no
    # deben persistir en la caché de memoria ni en disco).
    Clear-PPFCacheByTheme

    # Actualizar la configuración activa con la del tema
    $theme = $script:PromptThemes[$Name]
    $config = Get-PromptConfiguration
    $config.Theme["Name"] = $Name

    # Mapear los segmentos del tema a la configuración de segmentos
    foreach ($segName in $theme.Segments.Keys) {
        $current = Get-SegmentConfiguration -Name $segName
        $merged = @{}
        if ($current -is [System.Collections.IDictionary]) {
            foreach ($key in $current.Keys) {
                $merged[$key] = $current[$key]
            }
        }
        $overrides = $theme.Segments[$segName]
        if ($overrides -is [System.Collections.IDictionary]) {
            foreach ($key in $overrides.Keys) {
                $merged[$key] = $overrides[$key]
            }
        }
        Set-SegmentConfiguration -Name $segName -Configuration $merged
    }

    if (Get-Command Invoke-PPFEvent -ErrorAction SilentlyContinue) {
        Invoke-PPFEvent -EventName "ThemeChanged" -EventArgs $Name
    }

}

function Switch-PromptTheme {

    <#
    .SYNOPSIS
        Cambia el tema activo inmediatamente, sin reiniciar PowerShell.

    .DESCRIPTION
        Switch-PromptTheme activa un tema registrado en caliente. A diferencia
        de una recarga completa del módulo, esta operación:

        1. Valida que el tema exista (esté registrado con Register-PromptTheme).
        2. Restaura la línea base de segmentos (Reset-PPFThemeSegments), de modo
           que los overrides del tema anterior (segmentos ocultos, iconos,
           colores) no persistan.
        3. Invalida la caché de segmento/tema (Clear-PPFCacheByTheme) para que
           la siguiente renderización resuelva todo con el nuevo tema.
        4. Aplica los overrides (paleta, iconos y configuración de segmentos)
           del tema entrante.
        5. Devuelve información del tema activado.

    .PARAMETER Name
        Nombre del tema a activar. Debe estar registrado previamente.

    .OUTPUTS
        [PSCustomObject] con Name, Palette, Icons, Segments, PreviousTheme y
        SwitchedAt del tema activado.

    .EXAMPLE
        Switch-PromptTheme -Name "Nord"

        Cambia al tema Nord inmediatamente y devuelve su información.

    .NOTES
        No se requiere reiniciar PowerShell. El cambio es efectivo para el
        siguiente Invoke-Prompt.
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name
    )

    # Validar que el tema exista antes de mutar cualquier estado.
    if (-not $script:PromptThemes.ContainsKey($Name)) {
        throw "El tema '$Name' no está registrado. Regístrelo con Register-PromptTheme antes de cambiar a él."
    }

    # Capturar el tema previo antes de cambiar el activo, para reportarlo en
    # el resultado (útil para auditoría y rollback manual).
    $previousThemeName = $script:ActiveThemeName

    # Cambiar el tema activo inmediatamente. Set-PromptTheme se encarga de:
    #   - Restaurar la línea base (rollback de la configuración del tema previo).
    #   - Invalidar la caché de segmentos (sin fugas de color/icono entre temas).
    #   - Aplicar los overrides del nuevo tema.
    Set-PromptTheme -Name $Name

    $theme = Get-ActiveTheme

    # Devolver información del tema activado.
    [PSCustomObject]@{
        Name          = $theme.Name
        Palette       = $theme.Palette
        Icons         = $theme.Icons
        Segments      = $theme.Segments
        PreviousTheme = $previousThemeName
        SwitchedAt    = [datetime]::Now
    }

}

function Get-PromptTheme {

    param(
        [string]$Name
    )

    if ($Name) {
        if ($script:PromptThemes.ContainsKey($Name)) {
            return $script:PromptThemes[$Name]
        }
        return $null
    }

    return $script:PromptThemes.Values

}

function Get-PromptThemes {

    return Get-PromptTheme

}

function Get-ActiveTheme {

    return $script:PromptThemes[$script:ActiveThemeName]

}

function Resolve-ThemeColor {

    param(
        [string]$ColorName
    )

    if (-not $ColorName) {
        return $null
    }

    $activeTheme = Get-ActiveTheme
    if ($activeTheme -and $activeTheme.Palette -and $activeTheme.Palette.ContainsKey($ColorName)) {
        return $activeTheme.Palette[$ColorName]
    }

    return $ColorName

}

function Resolve-ThemeIcon {

    param(
        [string]$IconKey
    )

    if ([string]::IsNullOrWhiteSpace($IconKey)) {
        return $null
    }

    $activeTheme = Get-ActiveTheme
    if ($activeTheme -and $activeTheme.Icons -and $activeTheme.Icons.ContainsKey($IconKey)) {
        return $activeTheme.Icons[$IconKey]
    }

    # Not a theme key: callers decide whether to keep the literal glyph or
    # use their own fallback.
    return $null

}

