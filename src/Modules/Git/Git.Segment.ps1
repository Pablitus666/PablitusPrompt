# ============================================================
# Pablitus Prompt Framework (PPF)
# Git.Segment.ps1
# ============================================================

Register-PromptSegment `
    -Name "Git" `
    -Script {

        param(
            [PromptContext]$Context
        )

        if (-not $Context.Git.IsRepository) {
            return
        }

        $icon = if ($Context.Git.Dirty) {
            ""
        }
        else {
            ""
        }

        New-PromptSegment `
            -Name "Git" `
            -Text $Context.Git.Branch `
            -Icon $icon

    }
