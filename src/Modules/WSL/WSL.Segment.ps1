# ============================================================
# Pablitus Prompt Framework (PPF)
# WSL.Segment.ps1
# ============================================================

Register-PromptSegment `
    -Name "WSL" `
    -Priority 150 `
    -Script {

        param(
            [PromptContext]$Context
        )

        if (-not $Context.Wsl.IsWsl) {
            return $null
        }

        $icon = Resolve-ThemeIcon -IconKey "WSL"
        if (-not $icon) { $icon = "" }

        New-PromptSegment `
            -Name "WSL" `
            -Text $Context.Wsl.Distro `
            -Icon $icon

    }
