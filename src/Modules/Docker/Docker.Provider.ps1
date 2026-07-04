# ============================================================
# Pablitus Prompt Framework (PPF)
# Docker.Provider.ps1
# ============================================================

function Invoke-DockerProvider {

    param(
        [PromptContext]$Context
    )

    $cacheKey = "DockerStatus"
    $cached = Get-PPFCache -Key $cacheKey -UseDisk
    if ($null -ne $cached) {
        $Context.Docker.Active            = $cached.Active
        $Context.Docker.RunningContainers = $cached.RunningContainers
    }
    else {
        $active = Test-DockerActive
        $containers = 0
        if ($active) {
            $containers = Get-DockerRunningContainers
        }

        $data = [pscustomobject]@{
            Active            = $active
            RunningContainers = $containers
        }

        $Context.Docker.Active            = $active
        $Context.Docker.RunningContainers = $containers
        Set-PPFCache -Key $cacheKey -Value $data -TtlSeconds 15 -UseDisk
    }

}

Register-PromptProvider `
    -Name "Docker" `
    -Priority 500 `
    -Script ${function:Invoke-DockerProvider}
