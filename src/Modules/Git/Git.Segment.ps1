# ============================================================
# Pablitus Prompt Framework (PPF)
# Git.Segment.ps1
# ============================================================

Register-PromptSegment `
    -Name "Git" `
    -Priority 400 `
    -Script {

        param(
            [PromptContext]$Context
        )

        if (-not $Context.Git.IsRepository) {
            return
        }

        $gitConfig = Get-SegmentConfiguration -Name "Git"
        $icon = if ($Context.Git.Dirty) {
            $gitConfig["IconDirty"]
        }
        else {
            $gitConfig["IconClean"]
        }

        if ([string]::IsNullOrEmpty($icon)) {
            $icon = if ($Context.Git.Dirty) { "*" } else { "git" }
        }

        New-PromptSegment `
            -Name "Git" `
            -Text $Context.Git.Branch `
            -Icon $icon

    }
