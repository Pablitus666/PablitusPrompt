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
    $segment.Icon = Resolve-ThemeIcon -IconKey $rawIcon

    $rawForeground = if ($Foreground) { $Foreground } else { $cfg.Foreground }
    $segment.Foreground = Resolve-ThemeColor -ColorName $rawForeground

    $rawBackground = if ($Background) { $Background } else { $cfg.Background }
    $segment.Background = Resolve-ThemeColor -ColorName $rawBackground

    $segment.Visible = $true

    return $segment

}