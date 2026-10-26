# ============================================================
# Pablitus Prompt Framework (PPF)
# PowerLine.Renderer.ps1
# ============================================================

Register-PromptRenderer `
    -Name "PowerLine" `
    -Script {

    param(
        [PromptContext]$Context
    )

    $visibleSegments = [System.Collections.Generic.List[PromptSegment]]::new()
    foreach ($segment in $Context.Segments) {
        if ($segment.Visible) {
            $visibleSegments.Add($segment)
        }
    }

    if ($visibleSegments.Count -eq 0) {
        return "> "
    }

    $reset = "`e[0m"
    $powerlineGlyph = ""
    $result = [System.Text.StringBuilder]::new()

    for ($i = 0; $i -lt $visibleSegments.Count; $i++) {

        $current = $visibleSegments[$i]
        $next = if ($i + 1 -lt $visibleSegments.Count) { $visibleSegments[$i + 1] } else { $null }
        $config = Get-SegmentConfiguration -Name $current.Name

        # The segment background is explicit when available. Legacy themes
        # only set Foreground and expect it to become the block background.
        $currentBg = if ($current.Background) {
            $current.Background
        }
        elseif ($current.Foreground) {
            $current.Foreground
        }
        else {
            "Blue"
        }

        $currentFg = if ($current.Background -and $current.Foreground) {
            $current.Foreground
        }
        else {
            Get-PPFContrastColor -Color $currentBg
        }

        $nextBg = $null
        if ($null -ne $next) {
            $nextBg = if ($next.Background) {
                $next.Background
            }
            elseif ($next.Foreground) {
                $next.Foreground
            }
            else {
                "Blue"
            }
        }

        $hasConfig = $config -is [System.Collections.IDictionary]

        $leadingDiamond = if ($hasConfig -and $config.Contains("LeadingDiamond")) {
            [string]$config["LeadingDiamond"]
        }
        else {
            ""
        }

        $trailingDiamond = if ($hasConfig -and $config.Contains("TrailingDiamond")) {
            [string]$config["TrailingDiamond"]
        }
        else {
            ""
        }

        $powerlineSymbol = if ($hasConfig -and $config.Contains("PowerlineSymbol") -and
            -not [string]::IsNullOrEmpty([string]$config["PowerlineSymbol"])) {
            [string]$config["PowerlineSymbol"]
        }
        else {
            $powerlineGlyph
        }

        # A diamond opens the block without inheriting the console background.
        if ($i -eq 0 -and -not [string]::IsNullOrEmpty($leadingDiamond)) {
            $null = $result.Append((ConvertTo-PPFAnsiColor -Color $currentBg))
            $null = $result.Append($leadingDiamond)
        }

        $text = if ($current.Icon) {
            " $($current.Icon) $($current.Text) "
        }
        else {
            " $($current.Text) "
        }

        $null = $result.Append((ConvertTo-PPFAnsiColor -Color $currentFg))
        $null = $result.Append((ConvertTo-PPFAnsiColor -Color $currentBg -Background))
        $null = $result.Append($text)

        $isLast = $null -eq $next

        if ($isLast -and -not [string]::IsNullOrEmpty($trailingDiamond)) {
            # Close a diamond-shaped block with the matching half circle.
            $null = $result.Append((ConvertTo-PPFAnsiColor -Color $currentBg))
            $null = $result.Append($trailingDiamond)
            $null = $result.Append($reset)
        }
        else {
            # The separator foreground inherits the current block colour and
            # its background points at the next block (or resets at the end).
            $separatorBackground = if ($null -ne $nextBg) {
                ConvertTo-PPFAnsiColor -Color $nextBg -Background
            }
            else {
                $reset
            }

            $null = $result.Append((ConvertTo-PPFAnsiColor -Color $currentBg))
            $null = $result.Append($separatorBackground)
            $null = $result.Append($powerlineSymbol)
        }

    }

    $null = $result.Append($reset)
    $null = $result.Append(" ")

    return $result.ToString()

}

