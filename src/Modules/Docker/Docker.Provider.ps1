# ============================================================
# Pablitus Prompt Framework (PPF)
# Docker.Provider.ps1
# ============================================================

function Invoke-DockerProvider {

    param(
        [PromptContext]$Context
    )

    $dockerCfg = Get-SegmentConfiguration -Name "Docker"
    $ttlSeconds = if ($dockerCfg -and $dockerCfg.ContainsKey("CacheTimeoutMs")) { [int]($dockerCfg["CacheTimeoutMs"] / 1000) } else { 15 }
    if ($ttlSeconds -le 0) { $ttlSeconds = 15 }

    $cacheKey = "DockerStatus"
    $cached = Get-PPFCache -Key $cacheKey -UseDisk
    if ($null -ne $cached) {
        $Context.Docker.Active            = $cached.Active
        $Context.Docker.RunningContainers = $cached.RunningContainers
    }
    else {
        $info = Get-DockerInfo

        $data = [pscustomobject]@{
            Active            = $info.Active
            RunningContainers = $info.Count
        }

        $Context.Docker.Active            = $info.Active
        $Context.Docker.RunningContainers = $info.Count
        Set-PPFCache -Key $cacheKey -Value $data -TtlSeconds $ttlSeconds -UseDisk
    }

}

Register-PromptProvider `
    -Name "Docker" `
    -Priority 500 `
    -Script ${function:Invoke-DockerProvider}
