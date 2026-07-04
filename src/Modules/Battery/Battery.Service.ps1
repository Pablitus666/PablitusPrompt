# ============================================================
# Pablitus Prompt Framework (PPF)
# Battery.Service.ps1
# ============================================================

function Get-BatteryInfo {

    try {
        $bat = Get-CimInstance -ClassName Win32_Battery -ErrorAction SilentlyContinue
        if ($bat) {
            $statusMap = @{
                1 = "Discharging"
                2 = "Full"
                3 = "Charging"
                4 = "Low"
                5 = "Critical"
                6 = "Charging"
                7 = "Charging"
                8 = "Charging"
                9 = "Charging"
            }
            $status = if ($statusMap.ContainsKey($bat.BatteryStatus)) { $statusMap[$bat.BatteryStatus] } else { "Discharging" }
            return [PSCustomObject]@{
                Percentage = [int]$bat.EstimatedChargeRemaining
                Status     = $status
            }
        }
    }
    catch {}
    return $null

}
