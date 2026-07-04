# ============================================================
# Pablitus Prompt Framework (PPF)
# Battery.Provider.ps1
# ============================================================

function Invoke-BatteryProvider {

    param(
        [PromptContext]$Context
    )

    $cacheKey = "BatteryInfo"
    $cached = Get-PPFCache -Key $cacheKey
    if ($null -ne $cached) {
        $Context.Battery.Percentage = $cached.Percentage
        $Context.Battery.Status     = $cached.Status
    }
    else {
        $bat = Get-BatteryInfo
        $data = if ($bat) {
            $bat
        }
        else {
            [pscustomobject]@{
                Percentage = -1
                Status     = "Unknown"
            }
        }
        $Context.Battery.Percentage = $data.Percentage
        $Context.Battery.Status     = $data.Status
        Set-PPFCache -Key $cacheKey -Value $data -TtlSeconds 30
    }

}

Register-PromptProvider `
    -Name "Battery" `
    -Priority 900 `
    -Script ${function:Invoke-BatteryProvider}
