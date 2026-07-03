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

    $segment.Icon = if ($Icon) { $Icon } else { $cfg.Icon }

    $segment.Foreground = if ($Foreground) {
        $Foreground
    }
    else {
        $cfg.Foreground
    }

    $segment.Background = if ($Background) {
        $Background
    }
    else {
        $cfg.Background
    }

    $segment.Visible = $true

    return $segment

}