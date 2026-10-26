# ============================================================
# Pablitus Prompt Framework (PPF)
# Node.Segment.ps1
# ============================================================

Register-PromptSegment `
    -Name "Node" `
    -Priority 600 `
    -Script {

        param(
            [PromptContext]$Context
        )

        if (-not $Context.Runtime.Node) {
            return
        }

        New-PromptSegment `
            -Name "Node" `
            -Text $Context.Runtime.Node

    }
