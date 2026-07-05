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

    $ansiColors = @{
        "Black"   = "30"
        "Red"     = "31"
        "Green"   = "32"
        "Yellow"  = "33"
        "Blue"    = "34"
        "Magenta" = "35"
        "Cyan"    = "36"
        "White"   = "37"
    }

    $ansiBg = @{
        "Black"   = "40"
        "Red"     = "41"
        "Green"   = "42"
        "Yellow"  = "43"
        "Blue"    = "44"
        "Magenta" = "45"
        "Cyan"    = "46"
        "White"   = "47"
    }

    $visibleSegments = @($Context.Segments | Where-Object Visible)

    if ($visibleSegments.Count -eq 0) {
        return "> "
    }

    $result = ""
    for ($i = 0; $i -lt $visibleSegments.Count; $i++) {
        $current = $visibleSegments[$i]
        $next = if ($i + 1 -lt $visibleSegments.Count) { $visibleSegments[$i+1] } else { $null }

        # Determinar color de fondo
        $currentBg = if ($current.Background) { $current.Background } else { $current.Foreground }
        if (-not $currentBg -or -not $ansiBg.ContainsKey($currentBg)) { $currentBg = "Blue" }

        # Determinar color de texto (contraste adaptativo)
        $currentFg = if ($currentBg -in @("Yellow", "Cyan", "White", "Green")) { "Black" } else { "White" }

        # Determinar color de fondo del siguiente segmento
        $nextBg = $null
        if ($null -ne $next) {
            $nextBg = if ($next.Background) { $next.Background } else { $next.Foreground }
            if (-not $nextBg -or -not $ansiBg.ContainsKey($nextBg)) { $nextBg = "Blue" }
        }

        # Construir contenido del bloque
        $text = if ($current.Icon) {
            " $($current.Icon) $($current.Text) "
        } else {
            " $($current.Text) "
        }

        $fgCode = "`e[" + $ansiColors[$currentFg] + "m"
        $bgCode = "`e[" + $ansiBg[$currentBg] + "m"
        $result += "${fgCode}${bgCode}${text}"

        # Renderizar el glifo separador triangular de PowerLine ()
        $sepSep = ""
        $sepFgCode = "`e[" + ( [int]$ansiColors[$currentBg] ) + "m" # El color de fondo actual pasa a ser foreground del glifo
        $sepBgCode = if ($null -ne $nextBg) {
            "`e[" + $ansiBg[$nextBg] + "m"
        } else {
            "`e[0m" # Reset del fondo de consola si es el final
        }

        $result += "${sepFgCode}${sepBgCode}${sepSep}"
    }

    $result += "`e[0m "
    return $result

}
