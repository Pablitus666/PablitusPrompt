# ============================================================
# Pablitus Prompt Framework (PPF)
# DotNet.Segment.ps1
# ============================================================

Register-PromptSegment `
    -Name "DotNet" `
    -Priority 930 `
    -Script {

        param(
            [PromptContext]$Context
        )

        if (-not $Context.Runtime.DotNet) {
            return
        }

        New-PromptSegment `
            -Name "DotNet" `
            -Text $Context.Runtime.DotNet

    }
