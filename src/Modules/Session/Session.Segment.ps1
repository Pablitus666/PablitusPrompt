# ============================================================
# Pablitus Prompt Framework (PPF)
# Session.Segment.ps1
# ============================================================

Register-PromptSegment `
    -Name "Session" `
    -Script {

        param(
            [PromptContext]$Context
        )

        if (-not $Context.Session.User) {
            return
        }

        New-PromptSegment `
            -Name "Session" `
            -Text $Context.Session.User

    }
