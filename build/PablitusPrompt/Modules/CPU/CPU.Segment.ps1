# ============================================================
# Pablitus Prompt Framework (PPF)
# CPU.Segment.ps1
# ============================================================

Register-PromptSegment `
    -Name "CPU" `
    -Priority 910 `
    -Script {

        param(
            [PromptContext]$Context
        )

        # Only show if usage is non-trivial or explicitly configured
        if ($Context.Cpu.Usage -lt 1) {
            return $null
        }

        $icon = Resolve-ThemeIcon -IconKey "CPU"
        if (-not $icon) { $icon = "" }

        New-PromptSegment `
            -Name "CPU" `
            -Text "$($Context.Cpu.Usage)%" `
            -Icon $icon

    }
