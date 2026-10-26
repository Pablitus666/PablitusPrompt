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

