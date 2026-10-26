# ============================================================
# Pablitus Prompt Framework (PPF)
# Project.Segment.ps1
# ============================================================

Register-PromptSegment `
    -Name "Project" `
    -Priority 300 `
    -Script {

        param(
            [PromptContext]$Context
        )

        if (-not $Context.Project.Name) {
            return
        }

        New-PromptSegment `
            -Name "Project" `
            -Text $Context.Project.Name

    }
