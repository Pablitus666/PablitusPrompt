# ============================================================
# Pablitus Prompt Framework (PPF)
# Docker.Segment.ps1
# ============================================================

Register-PromptSegment `
    -Name "Docker" `
    -Priority 500 `
    -Script {

        param(
            [PromptContext]$Context
        )

        if (-not $Context.Docker.Active -or $Context.Docker.RunningContainers -eq 0) {
            return $null
        }

        # Dynamic resolving for theme support
        $icon = Resolve-ThemeIcon -IconKey "Docker"
        if (-not $icon) { $icon = "" }

        New-PromptSegment `
            -Name "Docker" `
            -Text "$($Context.Docker.RunningContainers)" `
            -Icon $icon

    }
