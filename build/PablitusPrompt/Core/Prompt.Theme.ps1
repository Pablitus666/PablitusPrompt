# ============================================================
# Pablitus Prompt Framework (PPF)
# Prompt.Theme.ps1
# ============================================================

$script:PromptThemes = @{}
$script:ActiveThemeName = "Default"

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

function Set-PromptTheme {

    param(
        [Parameter(Mandatory)]
        [string]$Name
    )

    if (-not $script:PromptThemes.ContainsKey($Name)) {
        throw "Theme '$Name' is not registered."
    }

    $script:ActiveThemeName = $Name

    # Actualizar la configuración activa con la del tema
    $theme = $script:PromptThemes[$Name]
    $config = Get-PromptConfiguration
    $config.Theme["Name"] = $Name

    # Mapear los segmentos del tema a la configuración de segmentos
    foreach ($segName in $theme.Segments.Keys) {
        Set-SegmentConfiguration -Name $segName -Configuration $theme.Segments[$segName]
    }

    if (Get-Command Invoke-PPFEvent -ErrorAction SilentlyContinue) {
        Invoke-PPFEvent -EventName "ThemeChanged" -EventArgs $Name
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

    if (-not $IconKey) {
        return $null
    }

    $activeTheme = Get-ActiveTheme
    if ($activeTheme -and $activeTheme.Icons -and $activeTheme.Icons.ContainsKey($IconKey)) {
        return $activeTheme.Icons[$IconKey]
    }

    return $IconKey

}

