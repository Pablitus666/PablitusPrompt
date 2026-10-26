# ============================================================
# Pablitus Prompt Framework (PPF)
# Prompt.Builder.ps1
# ============================================================

function New-PromptSegment {

    param(

        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [string]$Text,

        [string]$Icon,

        [string]$Foreground,

        [string]$Background

    )

    $cfg = Get-SegmentConfiguration $Name

    if (-not $cfg.Visible) {
        return $null
    }

    $segment = [PromptSegment]::new()

    $segment.Name = $Name
    $segment.Text = $Text

    $rawIcon = if ($Icon) { $Icon } else { $cfg.Icon }
    $segment.Icon = $rawIcon

    # Resolve only actual theme icon keys. Segment scripts already resolve
    # their own icons, so calling Resolve-ThemeIcon again on a literal glyph
    # is both wasteful and surprising (it can be mocked/overridden).
    if (-not [string]::IsNullOrWhiteSpace($rawIcon)) {
        $activeTheme = Get-ActiveTheme
        if ($activeTheme -and $activeTheme.Icons -and $activeTheme.Icons.ContainsKey($rawIcon)) {
            $segment.Icon = $activeTheme.Icons[$rawIcon]
        }
    }

    $rawForeground = if ($Foreground) { $Foreground } else { $cfg.Foreground }
    $segment.Foreground = Resolve-ThemeColor -ColorName $rawForeground

    $rawBackground = if ($Background) { $Background } else { $cfg.Background }
    $segment.Background = Resolve-ThemeColor -ColorName $rawBackground

    $segment.Visible = $true

    return $segment

}