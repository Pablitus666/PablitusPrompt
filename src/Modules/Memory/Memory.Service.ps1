# ============================================================
# Pablitus Prompt Framework (PPF)
# Memory.Service.ps1
# ============================================================

function Get-MemoryUsage {

    try {
        $os = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction SilentlyContinue
        if ($os) {
            $total = $os.TotalVisibleMemorySize
            $free = $os.FreePhysicalMemory
            $used = $total - $free
            $pct = ($used / $total) * 100
            return [int]$pct
        }
    }
    catch {}
    return 0

}
