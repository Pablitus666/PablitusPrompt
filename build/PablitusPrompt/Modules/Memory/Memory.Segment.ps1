# ============================================================
# Pablitus Prompt Framework (PPF)
# Memory.Segment.ps1
# ============================================================

Register-PromptSegment `
    -Name "Memory" `
    -Priority 920 `
    -Script {

        param(
            [PromptContext]$Context
        )

        if ($Context.Memory.Usage -lt 1) {
            return $null
        }

        $icon = Resolve-ThemeIcon -IconKey "Memory"
        if (-not $icon) { $icon = "﬙" }

        New-PromptSegment `
            -Name "Memory" `
            -Text "$($Context.Memory.Usage)%" `
            -Icon $icon

    }
