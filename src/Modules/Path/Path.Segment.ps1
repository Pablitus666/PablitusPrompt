# ============================================================
# Pablitus Prompt Framework (PPF)
# Path.Segment.ps1
# ============================================================

Register-PromptSegment `
    -Name "Path" `
    -Priority 200 `
    -Script {

        param(
            [PromptContext]$Context
        )

        if (-not $Context.Path.Friendly) {
            return
        }

        $pathConfig = Get-SegmentConfiguration -Name "Path"
        $text = $Context.Path.Friendly

        if ($pathConfig.ContainsKey("PathStyle") -and $pathConfig.PathStyle -eq "Folder") {
            $leaf = Split-Path -Path $Context.Path.Current -Leaf
            if (-not [string]::IsNullOrWhiteSpace($leaf)) {
                $text = $leaf
            }
        }

        New-PromptSegment `
            -Name "Path" `
            -Text $text

    }
