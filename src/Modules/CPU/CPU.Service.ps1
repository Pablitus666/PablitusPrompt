# ============================================================
# Pablitus Prompt Framework (PPF)
# CPU.Service.ps1
# ============================================================

function Get-CpuUsage {

    try {
        $cpu = Get-CimInstance -ClassName Win32_Processor -ErrorAction SilentlyContinue
        if ($cpu) {
            $avg = $cpu.LoadPercentage | Measure-Object -Average | Select-Object -ExpandProperty Average
            return [int]$avg
        }
    }
    catch {}
    return 0

}
