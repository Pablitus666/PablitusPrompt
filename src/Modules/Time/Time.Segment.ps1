# ============================================================
# Pablitus Prompt Framework (PPF)
# Time.Segment.ps1
# ============================================================

Register-PromptSegment `
    -Name "Time" `
    -Priority 1000 `
    -Script {

        param(
            [PromptContext]$Context
        )

        if ($null -eq $Context) {
            return
        }

        $timeConfig = Get-SegmentConfiguration -Name "Time"

        $format = if ($timeConfig.ContainsKey("Format") -and $timeConfig.Format) {
            [string]$timeConfig.Format
        }
        else {
            "HH:mm"
        }

        $icon = if ($timeConfig.ContainsKey("Icon")) {
            [string]$timeConfig.Icon
        }
        else {
            ""
        }

        New-PromptSegment `
            -Name "Time" `
            -Text (Get-Date -Format $format) `
            -Icon $icon

    }
