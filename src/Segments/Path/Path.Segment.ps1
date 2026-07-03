# ============================================================
# Pablitus Prompt Framework (PPF)
# Path.Segment.ps1
# ============================================================

Register-PromptSegment `
    -Name "Path" `
    -Script {

        param(
            [PromptContext]$Context
        )

        if (-not $Context.Path.Friendly) {
            return
        }

        New-PromptSegment `
            -Name "Path" `
            -Text $Context.Path.Friendly

    }