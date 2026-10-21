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

        $sessionConfig = Get-SegmentConfiguration -Name "Session"
        $text = $Context.Session.User

        if ($sessionConfig.ShowHost -and $Context.Session.Host) {
            $text = "$($Context.Session.User)@$($Context.Session.Host)"
        }

        New-PromptSegment `
            -Name "Session" `
            -Text $text

    }
