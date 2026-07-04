# ============================================================
# Pablitus Prompt Framework (PPF)
# Battery.Segment.ps1
# ============================================================

Register-PromptSegment `
    -Name "Battery" `
    -Priority 900 `
    -Script {

        param(
            [PromptContext]$Context
        )

        if ($Context.Battery.Percentage -lt 0) {
            return $null
        }

        # Resolve icon based on charging state
        $iconKey = if ($Context.Battery.Status -eq "Charging") { "BatteryCharging" } else { "Battery" }
        $icon = Resolve-ThemeIcon -IconKey $iconKey
        if (-not $icon) {
            $icon = if ($Context.Battery.Status -eq "Charging") { "⚡" } else { "🔋" }
        }

        New-PromptSegment `
            -Name "Battery" `
            -Text "$($Context.Battery.Percentage)%" `
            -Icon $icon

    }
