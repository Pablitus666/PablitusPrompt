# ============================================================
# Pablitus Prompt Framework (PPF)
# Python.Segment.ps1
# ============================================================

Register-PromptSegment `
    -Name "Python" `
    -Priority 500 `
    -Script {

        param(
            [PromptContext]$Context
        )

        if (-not $Context.Runtime.Python) {
            return
        }

        New-PromptSegment `
            -Name "Python" `
            -Text $Context.Runtime.Python

    }
